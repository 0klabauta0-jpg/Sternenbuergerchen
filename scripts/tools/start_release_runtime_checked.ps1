param(
	[string]$ContractPath = "",
	[int]$MaxAgeHours = 48,
	[switch]$StopRunningReleaseProcess,
	[switch]$CleanTempFiles,
	[switch]$Launch
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
	$started = Start-Process -FilePath ([string]$postcheck.exe_path) -WorkingDirectory ([string]$postcheck.release_directory) -PassThru
	$launchedProcess = [ordered]@{
		process_id = [int]$started.Id
		path = [string]$postcheck.exe_path
		working_directory = [string]$postcheck.release_directory
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

$gate = [string]$postcheck.gate
if ($hardActionFailures.Count -gt 0) {
	$gate = "fail"
}

$manifest = [ordered]@{
	schema = "sternenbuergerchen.release_runtime_checked_launcher.v1"
	task_id = "TASK_819"
	gate = $gate
	repo_root = $repoRoot
	requested_actions = [ordered]@{
		stop_running_release_process = [bool]$StopRunningReleaseProcess
		clean_temp_files = [bool]$CleanTempFiles
		launch = [bool]$Launch
	}
	precheck_gate = [string]$precheck.gate
	postcheck_gate = [string]$postcheck.gate
	exe_path = [string]$postcheck.exe_path
	release_directory = [string]$postcheck.release_directory
	stopped_processes = @($stoppedProcesses)
	removed_temp_files = @($removedTempFiles)
	launched_process = $launchedProcess
	action_failures = @($hardActionFailures)
	postcheck_warnings = @($postcheck.warnings)
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
} elseif (-not $Launch) {
	Write-Host "Launch skipped. Add -Launch to start the checked EXE."
}

if ($gate -eq "fail") {
	exit 2
}
exit 0
