param(
	[string]$ContractPath = "",
	[int]$MaxAgeHours = 48,
	[switch]$StopRunningReleaseProcess,
	[switch]$CleanTempFiles,
	[switch]$Launch,
	[string[]]$LaunchArguments = @()
)

$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
	$scriptDirectory = Split-Path -Parent $PSCommandPath
	return (Resolve-Path (Join-Path $scriptDirectory "..\..")).Path
}

function Invoke-ReleaseCheck {
	param(
		[string]$ScriptPath,
		[string]$ContractPathValue,
		[int]$AgeLimitHours
	)
	$args = @("-ExecutionPolicy", "Bypass", "-File", $ScriptPath, "-MaxAgeHours", [string]$AgeLimitHours, "-JsonOnly")
	if (-not [string]::IsNullOrWhiteSpace($ContractPathValue)) {
		$args += @("-ContractPath", $ContractPathValue)
	}
	$output = & powershell @args
	if ($LASTEXITCODE -ne 0 -and [string]::IsNullOrWhiteSpace(($output -join "").Trim())) {
		throw "Release runtime start check failed before producing JSON."
	}
	return (($output -join [Environment]::NewLine) | ConvertFrom-Json)
}

function Stop-ReleaseProcesses {
	param([array]$Processes)
	$stopped = @()
	foreach ($processInfo in $Processes) {
		$processId = [int]$processInfo.process_id
		if ($processId -le 0) {
			continue
		}
		try {
			Stop-Process -Id $processId -Force -ErrorAction Stop
			$stopped += [ordered]@{
				process_id = $processId
				name = [string]$processInfo.name
				executable_path = [string]$processInfo.executable_path
				status = "stopped"
			}
		} catch {
			$stopped += [ordered]@{
				process_id = $processId
				name = [string]$processInfo.name
				executable_path = [string]$processInfo.executable_path
				status = "failed"
				error = $_.Exception.Message
			}
		}
	}
	if ($stopped.Count -gt 0) {
		Start-Sleep -Milliseconds 500
	}
	return @($stopped)
}

function Remove-ReleaseTempFiles {
	param([array]$TempFiles)
	$removed = @()
	foreach ($tempInfo in $TempFiles) {
		$path = [string]$tempInfo.path
		if ([string]::IsNullOrWhiteSpace($path) -or -not (Test-Path -LiteralPath $path -PathType Leaf)) {
			continue
		}
		try {
			Remove-Item -LiteralPath $path -Force -ErrorAction Stop
			$removed += [ordered]@{
				path = $path
				status = "removed"
			}
		} catch {
			$removed += [ordered]@{
				path = $path
				status = "failed"
				error = $_.Exception.Message
			}
		}
	}
	return @($removed)
}

function Get-UnexpectedRunningProcesses {
	param(
		[array]$Processes,
		[object]$ExpectedProcess
	)
	$unexpected = @()
	$expectedProcessId = 0
	if ($ExpectedProcess -ne $null) {
		$expectedProcessId = [int]$ExpectedProcess.process_id
	}
	foreach ($processInfo in $Processes) {
		$processId = [int]$processInfo.process_id
		if ($expectedProcessId -gt 0 -and $processId -eq $expectedProcessId) {
			continue
		}
		$unexpected += $processInfo
	}
	return @($unexpected)
}

function Test-ExpectedLaunchRunning {
	param(
		[array]$Processes,
		[object]$ExpectedProcess
	)
	if ($ExpectedProcess -eq $null) {
		return $false
	}
	$expectedProcessId = [int]$ExpectedProcess.process_id
	foreach ($processInfo in $Processes) {
		if ([int]$processInfo.process_id -eq $expectedProcessId) {
			return $true
		}
	}
	return $false
}

function Get-ActionWarnings {
	param(
		[array]$Warnings,
		[bool]$ExpectedLaunchRunning,
		[array]$UnexpectedRunningProcesses
	)
	$remaining = @()
	foreach ($warning in $Warnings) {
		$warningText = [string]$warning
		if ($warningText -eq "release_process_already_running" -and $ExpectedLaunchRunning -and $UnexpectedRunningProcesses.Count -eq 0) {
			continue
		}
		$remaining += $warningText
	}
	return @($remaining)
}

$repoRoot = Resolve-RepoRoot
$checkScript = Join-Path $repoRoot "scripts\tools\release_runtime_start_check.ps1"
if (-not (Test-Path -LiteralPath $checkScript -PathType Leaf)) {
	throw "Missing release check script: $checkScript"
}

$precheck = Invoke-ReleaseCheck -ScriptPath $checkScript -ContractPathValue $ContractPath -AgeLimitHours $MaxAgeHours
$stoppedProcesses = @()
$removedTempFiles = @()
$launchedProcess = $null

if ($StopRunningReleaseProcess) {
	$stoppedProcesses = Stop-ReleaseProcesses -Processes @($precheck.running_processes)
}

if ($CleanTempFiles) {
	$removedTempFiles = Remove-ReleaseTempFiles -TempFiles @($precheck.temp_files)
}

$postcheck = Invoke-ReleaseCheck -ScriptPath $checkScript -ContractPathValue $ContractPath -AgeLimitHours $MaxAgeHours

if ($Launch) {
	if ([string]$postcheck.gate -eq "fail") {
		throw "Refusing to launch because release check gate is fail."
	}
	$startParams = @{
		FilePath = [string]$postcheck.exe_path
		WorkingDirectory = [string]$postcheck.release_directory
		PassThru = $true
	}
	if (@($LaunchArguments).Count -gt 0) {
		$startParams.ArgumentList = @($LaunchArguments)
	}
	$started = Start-Process @startParams
	$launchedProcess = [ordered]@{
		process_id = [int]$started.Id
		path = [string]$postcheck.exe_path
		working_directory = [string]$postcheck.release_directory
		arguments = @($LaunchArguments)
		status = "started"
	}
	Start-Sleep -Milliseconds 500
	$postcheck = Invoke-ReleaseCheck -ScriptPath $checkScript -ContractPathValue $ContractPath -AgeLimitHours $MaxAgeHours
}

$hardActionFailures = @()
foreach ($entry in $stoppedProcesses) {
	if ([string]$entry.status -eq "failed") {
		$hardActionFailures += "stop_process_failed:$($entry.process_id)"
	}
}
foreach ($entry in $removedTempFiles) {
	if ([string]$entry.status -eq "failed") {
		$hardActionFailures += "remove_temp_file_failed:$($entry.path)"
	}
}

$postcheckRunningProcesses = @($postcheck.running_processes)
$unexpectedRunningProcesses = Get-UnexpectedRunningProcesses -Processes $postcheckRunningProcesses -ExpectedProcess $launchedProcess
$expectedLaunchRunning = Test-ExpectedLaunchRunning -Processes $postcheckRunningProcesses -ExpectedProcess $launchedProcess
$actionWarnings = Get-ActionWarnings -Warnings @($postcheck.warnings) -ExpectedLaunchRunning $expectedLaunchRunning -UnexpectedRunningProcesses $unexpectedRunningProcesses

$gate = [string]$postcheck.gate
if ($hardActionFailures.Count -gt 0 -or [string]$postcheck.gate -eq "fail") {
	$gate = "fail"
} elseif ($Launch -and $expectedLaunchRunning -and $actionWarnings.Count -eq 0) {
	$gate = "pass"
} elseif ($actionWarnings.Count -gt 0) {
	$gate = "review"
}

$manifest = [ordered]@{
	schema = "sternenbuergerchen.release_runtime_checked_launcher.v1"
	task_id = "TASK_819"
	launch_acceptance_task_id = "TASK_820"
	gate = $gate
	repo_root = $repoRoot
	requested_actions = [ordered]@{
		stop_running_release_process = [bool]$StopRunningReleaseProcess
		clean_temp_files = [bool]$CleanTempFiles
		launch = [bool]$Launch
		launch_arguments = @($LaunchArguments)
	}
	precheck_gate = [string]$precheck.gate
	postcheck_gate = [string]$postcheck.gate
	exe_path = [string]$postcheck.exe_path
	release_directory = [string]$postcheck.release_directory
	stopped_processes = @($stoppedProcesses)
	removed_temp_files = @($removedTempFiles)
	launched_process = $launchedProcess
	expected_launched_process_running = $expectedLaunchRunning
	unexpected_running_processes = @($unexpectedRunningProcesses)
	action_failures = @($hardActionFailures)
	postcheck_warnings = @($postcheck.warnings)
	action_warnings = @($actionWarnings)
	read_only_default = $true
	mutates_processes_only_with_switch = $true
	updates_shortcuts = $false
}

$tmpDirectory = Join-Path $repoRoot "tmp"
if (-not (Test-Path -LiteralPath $tmpDirectory -PathType Container)) {
	New-Item -ItemType Directory -Path $tmpDirectory | Out-Null
}
$manifestPath = Join-Path $tmpDirectory "release_runtime_checked_launcher.json"
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding UTF8

Write-Host "Release checked launcher: $gate"
Write-Host "Precheck: $($manifest.precheck_gate) | Postcheck: $($manifest.postcheck_gate)"
Write-Host "EXE: $($manifest.exe_path)"
Write-Host "Manifest: $manifestPath"
if ($stoppedProcesses.Count -gt 0) {
	Write-Host "Stopped processes: $((@($stoppedProcesses) | ForEach-Object { $_.process_id }) -join ', ')"
}
if ($removedTempFiles.Count -gt 0) {
	Write-Host "Removed temp files: $($removedTempFiles.Count)"
}
if ($launchedProcess -ne $null) {
	Write-Host "Launched process id: $($launchedProcess.process_id)"
	Write-Host "Expected launch running: $expectedLaunchRunning"
} elseif (-not $Launch) {
	Write-Host "Launch skipped. Add -Launch to start the checked EXE."
}
if ($actionWarnings.Count -gt 0) {
	Write-Host "Action warnings: $($actionWarnings -join ', ')"
}

if ($gate -eq "fail") {
	exit 2
}
exit 0
