param(
	[string]$ProjectRoot = "",
	[string]$GodotPath = "godot_console.exe",
	[switch]$SkipExport,
	[switch]$KeepOnSuccess
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
	$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
} else {
	$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
}

$tempBase = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
$runName = "sternenbuergerchen-task-n002-$([Guid]::NewGuid().ToString('N'))"
$runRoot = Join-Path $tempBase $runName
$cloneRoot = Join-Path $runRoot "checkout"
$logRoot = Join-Path $runRoot "logs"
$tempBranch = "__task_n002_verifier_$([Guid]::NewGuid().ToString('N'))"
$tempRef = "refs/heads/$tempBranch"
$snapshotCommit = ""
$sourceRefCreated = $false
$passed = $false

function ConvertTo-ProcessArgument {
	param([string]$Value)
	if ($Value.Length -eq 0) {
		return '""'
	}
	if ($Value -notmatch '[\s"]') {
		return $Value
	}
	$escaped = [regex]::Replace($Value, '(\\*)"', '$1$1\\"')
	$escaped = [regex]::Replace($escaped, '(\\+)$', '$1$1')
	return '"' + $escaped + '"'
}

function Invoke-NativeLogged {
	param(
		[string]$FilePath,
		[string[]]$Arguments,
		[string]$LogName,
		[string]$WorkingDirectory,
		[int]$TimeoutSeconds = 180
	)
	if ($TimeoutSeconds -le 0) {
		throw "$LogName requires a positive TimeoutSeconds value."
	}
	$stdoutPath = Join-Path $logRoot "$LogName.stdout.log"
	$stderrPath = Join-Path $logRoot "$LogName.stderr.log"
	$startInfo = [System.Diagnostics.ProcessStartInfo]::new()
	$startInfo.FileName = $FilePath
	$startInfo.Arguments = (@($Arguments | ForEach-Object { ConvertTo-ProcessArgument -Value ([string]$_) }) -join ' ')
	$startInfo.WorkingDirectory = $WorkingDirectory
	$startInfo.UseShellExecute = $false
	$startInfo.CreateNoWindow = $true
	$startInfo.RedirectStandardOutput = $true
	$startInfo.RedirectStandardError = $true
	$stdoutWriter = [System.IO.StreamWriter]::new($stdoutPath, $false, [System.Text.UTF8Encoding]::new($false))
	$stderrWriter = [System.IO.StreamWriter]::new($stderrPath, $false, [System.Text.UTF8Encoding]::new($false))
	$process = [System.Diagnostics.Process]::new()
	$process.StartInfo = $startInfo
	$process.add_OutputDataReceived({ param($sender, $eventArgs) if ($null -ne $eventArgs.Data) { $stdoutWriter.WriteLine($eventArgs.Data) } })
	$process.add_ErrorDataReceived({ param($sender, $eventArgs) if ($null -ne $eventArgs.Data) { $stderrWriter.WriteLine($eventArgs.Data) } })
	if (-not $process.Start()) {
		$stdoutWriter.Dispose()
		$stderrWriter.Dispose()
		throw "$LogName could not start $FilePath."
	}
	$process.BeginOutputReadLine()
	$process.BeginErrorReadLine()
	if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
		# Godot's console shim can launch a GUI child. taskkill /T only receives
		# the exact process tree created for this verifier stage.
		& taskkill.exe /PID $process.Id /T /F | Out-Null
		$process.WaitForExit()
		$stdoutWriter.Dispose()
		$stderrWriter.Dispose()
		throw "$LogName timed out after $TimeoutSeconds seconds; kept partial stdout/stderr under $logRoot."
	}
	$process.WaitForExit()
	$nativeExitCode = [int]$process.ExitCode
	$stdoutWriter.Dispose()
	$stderrWriter.Dispose()
	$stdout = if (Test-Path -LiteralPath $stdoutPath) { Get-Content -LiteralPath $stdoutPath -Raw } else { "" }
	$stderr = if (Test-Path -LiteralPath $stderrPath) { Get-Content -LiteralPath $stderrPath -Raw } else { "" }
	Write-Host "[$LogName] exit=$nativeExitCode"
	if (-not [string]::IsNullOrWhiteSpace($stdout)) { Write-Output $stdout.TrimEnd() }
	if (-not [string]::IsNullOrWhiteSpace($stderr)) { Write-Output $stderr.TrimEnd() }
	return [pscustomobject]@{
		ExitCode = $nativeExitCode
		Stdout = [string]$stdout
		Stderr = [string]$stderr
		Combined = "$stdout`n$stderr"
		StdoutPath = $stdoutPath
		StderrPath = $stderrPath
	}
}

function Assert-NativeSuccess {
	param(
		[object]$Result,
		[string]$Stage
	)
	if ($Result.ExitCode -ne 0) {
		throw "$Stage failed with exit code $($Result.ExitCode)."
	}
}

function Assert-NoGodotSetupErrors {
	param(
		[string]$Text,
		[string]$Stage
	)
	$hardErrorPattern = '(?im)(ERROR:.*(UID|autoload)|Failed to load.*uid://|Cannot get class.*autoload|Could not resolve UID|Cannot open file.*uid://|Parse Error|SCRIPT ERROR|Failed to load script)'
	$match = [regex]::Match($Text, $hardErrorPattern)
	if ($match.Success) {
		throw "$Stage contains a hard Godot setup error: $($match.Value)"
	}
}

function Assert-SafeTempRoot {
	$resolvedRun = [System.IO.Path]::GetFullPath($runRoot)
	if (-not $resolvedRun.StartsWith($tempBase, [System.StringComparison]::OrdinalIgnoreCase)) {
		throw "Unsafe verifier temp root outside system temp: $resolvedRun"
	}
	if (-not ([System.IO.Path]::GetFileName($resolvedRun)).StartsWith("sternenbuergerchen-task-n002-")) {
		throw "Unsafe verifier temp root name: $resolvedRun"
	}
}

try {
	Assert-SafeTempRoot
	New-Item -ItemType Directory -Path $logRoot -Force | Out-Null

	& git -C $ProjectRoot diff --quiet
	if ($LASTEXITCODE -ne 0) {
		throw "Unstaged tracked changes are not part of the verifier snapshot. Stage or commit them first."
	}
	$untracked = @(& git -C $ProjectRoot ls-files --others --exclude-standard)
	if ($LASTEXITCODE -ne 0) {
		throw "Could not inspect untracked files."
	}
	if ($untracked.Count -gt 0) {
		throw "Untracked files are not part of the verifier snapshot: $($untracked -join ', ')"
	}

	$tree = [string](& git -C $ProjectRoot write-tree).Trim()
	if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($tree)) {
		throw "git write-tree failed."
	}
	$head = [string](& git -C $ProjectRoot rev-parse HEAD).Trim()
	$snapshotCommit = [string]("TASK_N002 staged verifier snapshot" | & git -C $ProjectRoot commit-tree $tree -p $head).Trim()
	if ($LASTEXITCODE -ne 0 -or $snapshotCommit -notmatch '^[0-9a-f]{40}$') {
		throw "git commit-tree failed."
	}
	& git -C $ProjectRoot update-ref $tempRef $snapshotCommit
	if ($LASTEXITCODE -ne 0) {
		throw "Could not create temporary local verifier ref."
	}
	$sourceRefCreated = $true

	# The clone flags are contract-significant: clone --no-local --no-hardlinks.
	$cloneResult = Invoke-NativeLogged -FilePath "git" -Arguments @("clone", "--no-local", "--no-hardlinks", "--branch", $tempBranch, "--no-checkout", $ProjectRoot, $cloneRoot) -LogName "01-clone" -WorkingDirectory $runRoot -TimeoutSeconds 300
	Assert-NativeSuccess -Result $cloneResult -Stage "External clone"
	& git -C $ProjectRoot update-ref -d $tempRef
	$sourceRefCreated = $false

	$checkoutResult = Invoke-NativeLogged -FilePath "git" -Arguments @("checkout", "--detach", $snapshotCommit) -LogName "02-checkout" -WorkingDirectory $cloneRoot -TimeoutSeconds 300
	Assert-NativeSuccess -Result $checkoutResult -Stage "Detached checkout"

	$versionResult = Invoke-NativeLogged -FilePath $GodotPath -Arguments @("--version") -LogName "03-godot-version" -WorkingDirectory $cloneRoot -TimeoutSeconds 30
	Assert-NativeSuccess -Result $versionResult -Stage "Godot version"
	if ($versionResult.Combined -notmatch '^4\.6\.2') {
		throw "TASK_N002 requires Godot 4.6.2, got: $($versionResult.Combined.Trim())"
	}

	$configResult = Invoke-NativeLogged -FilePath "powershell" -Arguments @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", (Join-Path $cloneRoot "scripts\tests\test_task_n002_checkout_config.ps1"), "-ProjectRoot", $cloneRoot) -LogName "04-static-contract" -WorkingDirectory $cloneRoot -TimeoutSeconds 60
	Assert-NativeSuccess -Result $configResult -Stage "Static checkout contract"

	$importResult = Invoke-NativeLogged -FilePath $GodotPath -Arguments @("--headless", "--editor", "--import", "--path", $cloneRoot, "--quit") -LogName "05-headless-import" -WorkingDirectory $cloneRoot -TimeoutSeconds 600
	Assert-NativeSuccess -Result $importResult -Stage "Headless import"
	Assert-NoGodotSetupErrors -Text $importResult.Combined -Stage "Headless import"

	$startResult = Invoke-NativeLogged -FilePath $GodotPath -Arguments @("--headless", "--path", $cloneRoot, "--quit-after", "10") -LogName "06-minimal-start" -WorkingDirectory $cloneRoot -TimeoutSeconds 120
	Assert-NativeSuccess -Result $startResult -Stage "Minimal project start"
	Assert-NoGodotSetupErrors -Text $startResult.Combined -Stage "Minimal project start"

	if (-not $SkipExport) {
		$expectedExe = Join-Path $cloneRoot "builds\Sternenbuergerchen_rel.exe"
		$expectedPck = Join-Path $cloneRoot "builds\Sternenbuergerchen_rel.pck"
		New-Item -ItemType Directory -Force -Path (Split-Path -Parent $expectedExe) | Out-Null
		$exportResult = Invoke-NativeLogged -FilePath $GodotPath -Arguments @("--headless", "--path", $cloneRoot, "--export-release", "Windows Desktop") -LogName "07-windows-export" -WorkingDirectory $cloneRoot -TimeoutSeconds 600
		Assert-NativeSuccess -Result $exportResult -Stage "Windows release export"
		Assert-NoGodotSetupErrors -Text $exportResult.Combined -Stage "Windows release export"
		if (-not (Test-Path -LiteralPath $expectedExe -PathType Leaf) -or -not (Test-Path -LiteralPath $expectedPck -PathType Leaf)) {
			throw "Windows export returned success without expected EXE and PCK under builds/."
		}
	}

	$passed = $true
	Write-Host "TASK_N002_FRESH_CHECKOUT: PASSED commit=$snapshotCommit"
	Write-Host "Logs: $logRoot"
} catch {
	$failurePath = Join-Path $logRoot "00-verifier.failure.log"
	$failureText = "$($_.Exception.GetType().FullName): $($_.Exception.Message)`n$($_.ScriptStackTrace)"
	[System.IO.File]::WriteAllText($failurePath, $failureText, [System.Text.UTF8Encoding]::new($false))
	Write-Error $failureText
} finally {
	if ($sourceRefCreated) {
		& git -C $ProjectRoot update-ref -d $tempRef 2>$null
	}
	if ($passed -and -not $KeepOnSuccess) {
		Assert-SafeTempRoot
		Remove-Item -LiteralPath $runRoot -Recurse -Force
		Write-Host "PASS cleanup: removed $runRoot"
	} else {
		Write-Host "KEEP verifier workspace and logs: $runRoot"
	}
}

exit $(if ($passed) { 0 } else { 1 })
