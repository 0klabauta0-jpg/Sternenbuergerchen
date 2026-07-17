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

function Invoke-NativeLogged {
	param(
		[string]$FilePath,
		[string[]]$Arguments,
		[string]$LogName,
		[string]$WorkingDirectory
	)
	$stdoutPath = Join-Path $logRoot "$LogName.stdout.log"
	$stderrPath = Join-Path $logRoot "$LogName.stderr.log"
	$process = Start-Process -FilePath $FilePath -ArgumentList $Arguments -WorkingDirectory $WorkingDirectory -NoNewWindow -Wait -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
	$stdout = if (Test-Path -LiteralPath $stdoutPath) { Get-Content -LiteralPath $stdoutPath -Raw } else { "" }
	$stderr = if (Test-Path -LiteralPath $stderrPath) { Get-Content -LiteralPath $stderrPath -Raw } else { "" }
	Write-Host "[$LogName] exit=$($process.ExitCode)"
	if (-not [string]::IsNullOrWhiteSpace($stdout)) { Write-Output $stdout.TrimEnd() }
	if (-not [string]::IsNullOrWhiteSpace($stderr)) { Write-Output $stderr.TrimEnd() }
	return [pscustomobject]@{
		ExitCode = [int]$process.ExitCode
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
	$cloneResult = Invoke-NativeLogged -FilePath "git" -Arguments @("clone", "--no-local", "--no-hardlinks", "--branch", $tempBranch, "--no-checkout", $ProjectRoot, $cloneRoot) -LogName "01-clone" -WorkingDirectory $runRoot
	Assert-NativeSuccess -Result $cloneResult -Stage "External clone"
	& git -C $ProjectRoot update-ref -d $tempRef
	$sourceRefCreated = $false

	$checkoutResult = Invoke-NativeLogged -FilePath "git" -Arguments @("checkout", "--detach", $snapshotCommit) -LogName "02-checkout" -WorkingDirectory $cloneRoot
	Assert-NativeSuccess -Result $checkoutResult -Stage "Detached checkout"

	$versionResult = Invoke-NativeLogged -FilePath $GodotPath -Arguments @("--version") -LogName "03-godot-version" -WorkingDirectory $cloneRoot
	Assert-NativeSuccess -Result $versionResult -Stage "Godot version"
	if ($versionResult.Combined -notmatch '^4\.6\.2') {
		throw "TASK_N002 requires Godot 4.6.2, got: $($versionResult.Combined.Trim())"
	}

	$configResult = Invoke-NativeLogged -FilePath "powershell" -Arguments @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", (Join-Path $cloneRoot "scripts\tests\test_task_n002_checkout_config.ps1"), "-ProjectRoot", $cloneRoot) -LogName "04-static-contract" -WorkingDirectory $cloneRoot
	Assert-NativeSuccess -Result $configResult -Stage "Static checkout contract"

	$importResult = Invoke-NativeLogged -FilePath $GodotPath -Arguments @("--headless", "--editor", "--path", $cloneRoot, "--quit") -LogName "05-headless-import" -WorkingDirectory $cloneRoot
	Assert-NativeSuccess -Result $importResult -Stage "Headless import"
	Assert-NoGodotSetupErrors -Text $importResult.Combined -Stage "Headless import"

	$startResult = Invoke-NativeLogged -FilePath $GodotPath -Arguments @("--headless", "--path", $cloneRoot, "--quit-after", "10") -LogName "06-minimal-start" -WorkingDirectory $cloneRoot
	Assert-NativeSuccess -Result $startResult -Stage "Minimal project start"
	Assert-NoGodotSetupErrors -Text $startResult.Combined -Stage "Minimal project start"

	if (-not $SkipExport) {
		$exportResult = Invoke-NativeLogged -FilePath $GodotPath -Arguments @("--headless", "--path", $cloneRoot, "--export-release", "Windows Desktop") -LogName "07-windows-export" -WorkingDirectory $cloneRoot
		Assert-NativeSuccess -Result $exportResult -Stage "Windows release export"
		Assert-NoGodotSetupErrors -Text $exportResult.Combined -Stage "Windows release export"
		$expectedExe = Join-Path $cloneRoot "builds\Sternenbuergerchen_rel.exe"
		$expectedPck = Join-Path $cloneRoot "builds\Sternenbuergerchen_rel.pck"
		if (-not (Test-Path -LiteralPath $expectedExe -PathType Leaf) -or -not (Test-Path -LiteralPath $expectedPck -PathType Leaf)) {
			throw "Windows export returned success without expected EXE and PCK under builds/."
		}
	}

	$passed = $true
	Write-Host "TASK_N002_FRESH_CHECKOUT: PASSED commit=$snapshotCommit"
	Write-Host "Logs: $logRoot"
} catch {
	Write-Error $_
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
