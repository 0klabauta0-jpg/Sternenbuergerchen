param(
	[string]$ContractPath = "",
	[string]$OutputDirectory = "",
	[int]$WaitSeconds = 30,
	[switch]$Launch,
	[switch]$StopRunningReleaseProcess,
	[switch]$CleanTempFiles,
	[switch]$SkipFocusWindow
)

$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
	$scriptDirectory = Split-Path -Parent $PSCommandPath
	return (Resolve-Path (Join-Path $scriptDirectory "..\..")).Path
}

function Read-JsonFile {
	param([string]$Path)
	if (-not (Test-Path -LiteralPath $Path)) {
		return $null
	}
	return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Get-GitValue {
	param([string[]]$Arguments)
	try {
		$previousLocation = Get-Location
		Set-Location $script:repoRoot
		$value = (& git @Arguments 2>$null)
		Set-Location $previousLocation
		return [string]$value
	} catch {
		try { Set-Location $previousLocation } catch {}
		return ""
	}
}

function Copy-IfExists {
	param(
		[string]$SourcePath,
		[string]$DestinationPath
	)
	if ([string]::IsNullOrWhiteSpace($SourcePath) -or -not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
		return $false
	}
	Copy-Item -LiteralPath $SourcePath -Destination $DestinationPath -Force
	return (Test-Path -LiteralPath $DestinationPath -PathType Leaf)
}

$script:repoRoot = Resolve-RepoRoot
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
	$OutputDirectory = Join-Path $script:repoRoot "tmp"
}
if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) {
	New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
}

$launchArgument = "--release-singleplayer-first-go-firefight"
$launcherScript = Join-Path $script:repoRoot "scripts\tools\start_release_runtime_checked.ps1"
$captureScript = Join-Path $script:repoRoot "scripts\tools\capture_release_singleplayer_visible_window.ps1"
$launcherManifestPath = Join-Path $script:repoRoot "tmp\release_runtime_checked_launcher.json"
$genericCaptureManifestPath = Join-Path $OutputDirectory "release_singleplayer_visible_window_findings.json"
$taskManifestPath = Join-Path $OutputDirectory "release_first_go_firefight_real_window_review.json"
$taskDesktopScreenshotPath = Join-Path $OutputDirectory "release_first_go_firefight_real_window_desktop.png"
$taskWindowScreenshotPath = Join-Path $OutputDirectory "release_first_go_firefight_real_window.png"

if (-not (Test-Path -LiteralPath $launcherScript -PathType Leaf)) {
	throw "Missing launcher script: $launcherScript"
}
if (-not (Test-Path -LiteralPath $captureScript -PathType Leaf)) {
	throw "Missing capture script: $captureScript"
}

$launcherOutput = @()
if ($Launch) {
	$launcherArgs = @("-ExecutionPolicy", "Bypass", "-File", $launcherScript, "-Launch", "-LaunchArguments", $launchArgument)
	if (-not [string]::IsNullOrWhiteSpace($ContractPath)) {
		$launcherArgs += @("-ContractPath", $ContractPath)
	}
	if ($StopRunningReleaseProcess) {
		$launcherArgs += "-StopRunningReleaseProcess"
	}
	if ($CleanTempFiles) {
		$launcherArgs += "-CleanTempFiles"
	}
	$launcherOutput = & powershell @launcherArgs
	if ($LASTEXITCODE -ne 0) {
		throw "First-GO-Firefight release launcher failed with exit code $LASTEXITCODE."
	}
	Start-Sleep -Seconds ([Math]::Max(1, $WaitSeconds))
}

$launcherManifest = Read-JsonFile -Path $launcherManifestPath
$selectedProcessId = 0
if ($launcherManifest -ne $null -and $launcherManifest.launched_process -ne $null) {
	$selectedProcessId = [int]$launcherManifest.launched_process.process_id
}

$captureArgs = @("-ExecutionPolicy", "Bypass", "-File", $captureScript, "-OutputDirectory", $OutputDirectory)
if (-not [string]::IsNullOrWhiteSpace($ContractPath)) {
	$captureArgs += @("-ContractPath", $ContractPath)
}
if ($selectedProcessId -gt 0) {
	$captureArgs += @("-ProcessId", [string]$selectedProcessId)
}
if ($SkipFocusWindow) {
	$captureArgs += "-SkipFocusWindow"
}
$captureOutput = & powershell @captureArgs
$captureExitCode = $LASTEXITCODE
$captureManifest = Read-JsonFile -Path $genericCaptureManifestPath

$desktopSourcePath = if ($captureManifest -ne $null) { [string]$captureManifest.desktop_screenshot_full_path } else { "" }
$windowSourcePath = if ($captureManifest -ne $null) { [string]$captureManifest.window_screenshot_full_path } else { "" }
$desktopCopied = Copy-IfExists -SourcePath $desktopSourcePath -DestinationPath $taskDesktopScreenshotPath
$windowCopied = Copy-IfExists -SourcePath $windowSourcePath -DestinationPath $taskWindowScreenshotPath

$hardFailures = @()
$warnings = @()
if ($captureExitCode -ne 0) {
	$hardFailures += "capture_script_failed:$captureExitCode"
}
if ($captureManifest -eq $null) {
	$hardFailures += "capture_manifest_missing"
} elseif ([string]$captureManifest.gate -eq "fail") {
	$hardFailures += "capture_manifest_failed"
}
if ($Launch -and ($launcherManifest -eq $null -or [string]$launcherManifest.gate -eq "fail")) {
	$hardFailures += "launcher_manifest_failed"
}
if (-not $desktopCopied) {
	$warnings += "desktop_screenshot_copy_missing"
}
if (-not $windowCopied) {
	$warnings += "window_screenshot_copy_missing"
}

$gate = "review_ready"
if ($hardFailures.Count -gt 0) {
	$gate = "fail"
} elseif (-not $windowCopied) {
	$gate = "manual_open"
}

$requiredChecks = @(
	"release_exe_started_with_first_go_firefight_arg",
	"mission_view_visible",
	"first_go_executed",
	"movement_or_recent_trace_visible",
	"first_contact_visible",
	"engagement_feedback_visible",
	"selected_fireteam_next_why_visible",
	"mission_control_next_why_visible",
	"command_matrix_go_prominent",
	"active_fire_rule_visible",
	"screenshot_saved",
	"manual_visual_review_done"
)

$manifest = [ordered]@{
	schema = "sternenbuergerchen.release_first_go_firefight_real_window_review.v1"
	task_id = "TASK_837"
	source_tasks = @(
		"TASK_832",
		"TASK_833",
		"TASK_834",
		"TASK_835",
		"TASK_836",
		"TASK_822"
	)
	gate = $gate
	repo_root = $script:repoRoot
	branch = Get-GitValue -Arguments @("branch", "--show-current")
	git_head = Get-GitValue -Arguments @("rev-parse", "--short", "HEAD")
	launch_argument = $launchArgument
	wait_seconds = $WaitSeconds
	launcher_requested = [bool]$Launch
	stop_running_release_process_requested = [bool]$StopRunningReleaseProcess
	clean_temp_files_requested = [bool]$CleanTempFiles
	launcher_manifest_path = "tmp/release_runtime_checked_launcher.json"
	launcher_manifest_full_path = $launcherManifestPath
	launcher_gate = if ($launcherManifest -ne $null) { [string]$launcherManifest.gate } else { "" }
	launcher_expected_process_running = if ($launcherManifest -ne $null) { [bool]$launcherManifest.expected_launched_process_running } else { $false }
	launcher_output = @($launcherOutput)
	capture_manifest_path = "tmp/release_singleplayer_visible_window_findings.json"
	capture_manifest_full_path = $genericCaptureManifestPath
	capture_gate = if ($captureManifest -ne $null) { [string]$captureManifest.gate } else { "" }
	capture_output = @($captureOutput)
	selected_process_id = if ($captureManifest -ne $null) { [int]$captureManifest.selected_process_id } else { $selectedProcessId }
	window_handle_found = if ($captureManifest -ne $null) { [bool]$captureManifest.window_handle_found } else { $false }
	desktop_screenshot_path = "tmp/release_first_go_firefight_real_window_desktop.png"
	window_screenshot_path = "tmp/release_first_go_firefight_real_window.png"
	desktop_screenshot_full_path = $taskDesktopScreenshotPath
	window_screenshot_full_path = $taskWindowScreenshotPath
	desktop_screenshot_written = $desktopCopied
	window_screenshot_written = $windowCopied
	required_checks = $requiredChecks
	expected_visible_contracts = [ordered]@{
		first_go_firefight_arg = $launchArgument
		selected_fireteam_decision_line = "NEXT ... | WHY ..."
		mission_control_decision_line = "NEXT ... | WHY ..."
		command_matrix_style_id = "task_836_release_firefight_command_matrix_visual_v1"
		go_button_role = "go_execute"
		active_fire_rule_count = 1
	}
	manual_review_required = $true
	manual_review_done = $false
	read_only_capture = $true
	ui_sets_gameplay_truth = $false
	creates_command = $false
	creates_fire_event = $false
	creates_damage_event = $false
	sets_multiplayer_truth = $false
	starts_processes = [bool]$Launch
	kills_processes = [bool]$StopRunningReleaseProcess
	updates_shortcuts = $false
	warnings = @($warnings)
	hard_failures = @($hardFailures)
	recommended_next_task = "TASK_838 - Release Firefight Real Window Findings Polish"
}

$manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $taskManifestPath -Encoding UTF8

Write-Host "TASK_837 First-GO-Firefight real-window review: $gate"
Write-Host "Manifest: $taskManifestPath"
Write-Host "Desktop screenshot: $taskDesktopScreenshotPath"
if ($windowCopied) {
	Write-Host "Window screenshot: $taskWindowScreenshotPath"
} else {
	Write-Host "Window screenshot missing; see capture manifest."
}
if ($warnings.Count -gt 0) {
	Write-Host "Warnings: $($warnings -join ', ')"
}
if ($hardFailures.Count -gt 0) {
	Write-Host "Hard failures: $($hardFailures -join ', ')"
}

if ($hardFailures.Count -gt 0) {
	exit 2
}
exit 0
