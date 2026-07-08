param(
	[string]$ContractPath = "",
	[string]$OutputDirectory = "",
	[int]$WaitSeconds = 52,
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
	if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
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
$fireVisualSchema = "sternenbuergerchen.release_first_exchange_fire_visual_polish.v1"
$fireVisualStyleId = "task_880_release_first_exchange_fire_visual_polish_v1"
$traceSchema = "sternenbuergerchen.release_first_exchange_exported_status_source_trace.v1"
$visibleStatusSchema = "sternenbuergerchen.release_first_exchange_visible_status_source_reconciliation.v1"
$visibleStatusStyleId = "task_876_release_first_exchange_visible_status_source_reconciliation_v1"
$focusStyleId = "task_850_release_fire_exchange_focused_visual_polish_v1"
$sourceTraceScript = Join-Path $script:repoRoot "scripts\tools\capture_release_first_exchange_exported_status_source_trace.ps1"
$sourceTraceManifestPath = Join-Path $OutputDirectory "release_first_exchange_exported_status_source_trace.json"
$sourceVisibleManifestPath = Join-Path $OutputDirectory "release_first_exchange_visible_status_recapture.json"
$taskManifestPath = Join-Path $OutputDirectory "release_first_exchange_fire_visual_recapture.json"
$taskDesktopScreenshotPath = Join-Path $OutputDirectory "release_first_exchange_fire_visual_recapture_desktop.png"
$taskWindowScreenshotPath = Join-Path $OutputDirectory "release_first_exchange_fire_visual_recapture.png"

if (-not (Test-Path -LiteralPath $sourceTraceScript -PathType Leaf)) {
	throw "Missing TASK_879 source trace capture script: $sourceTraceScript"
}

$sourceArgs = @("-ExecutionPolicy", "Bypass", "-File", $sourceTraceScript, "-OutputDirectory", $OutputDirectory, "-WaitSeconds", [string]$WaitSeconds)
if (-not [string]::IsNullOrWhiteSpace($ContractPath)) {
	$sourceArgs += @("-ContractPath", $ContractPath)
}
if ($Launch) {
	$sourceArgs += "-Launch"
}
if ($StopRunningReleaseProcess) {
	$sourceArgs += "-StopRunningReleaseProcess"
}
if ($CleanTempFiles) {
	$sourceArgs += "-CleanTempFiles"
}
if ($SkipFocusWindow) {
	$sourceArgs += "-SkipFocusWindow"
}

$sourceOutput = & powershell @sourceArgs
$sourceExitCode = $LASTEXITCODE
$sourceTraceManifest = Read-JsonFile -Path $sourceTraceManifestPath
$sourceVisibleManifest = Read-JsonFile -Path $sourceVisibleManifestPath

$sourceDesktopPath = if ($sourceVisibleManifest -ne $null) { [string]$sourceVisibleManifest.desktop_screenshot_full_path } else { "" }
$sourceWindowPath = if ($sourceVisibleManifest -ne $null) { [string]$sourceVisibleManifest.window_screenshot_full_path } else { "" }
$desktopCopied = Copy-IfExists -SourcePath $sourceDesktopPath -DestinationPath $taskDesktopScreenshotPath
$windowCopied = Copy-IfExists -SourcePath $sourceWindowPath -DestinationPath $taskWindowScreenshotPath

$hardFailures = @()
$warnings = @()
if ($sourceExitCode -ne 0) {
	$hardFailures += "source_trace_capture_failed:$sourceExitCode"
}
if ($sourceTraceManifest -eq $null) {
	$hardFailures += "source_trace_manifest_missing"
} elseif ([string]$sourceTraceManifest.gate -eq "fail") {
	$hardFailures += "source_trace_manifest_failed"
}
if ($sourceVisibleManifest -eq $null) {
	$warnings += "source_visible_status_manifest_missing"
}
if (-not $desktopCopied) {
	$warnings += "desktop_screenshot_copy_missing"
}
if (-not $windowCopied) {
	$warnings += "window_screenshot_copy_missing"
}
if ($sourceTraceManifest -ne $null -and $sourceTraceManifest.PSObject.Properties.Name -contains "runtime_trace_activation_observed" -and -not [bool]$sourceTraceManifest.runtime_trace_activation_observed) {
	$warnings += "task_876_status_source_activation_not_observed"
}
if ($sourceTraceManifest -ne $null -and $sourceTraceManifest.PSObject.Properties.Name -contains "runtime_trace_final_no_los_or_contact_pressure_observed" -and [bool]$sourceTraceManifest.runtime_trace_final_no_los_or_contact_pressure_observed) {
	$warnings += "final_visible_status_still_no_los_or_contact_pressure"
}
if ($sourceVisibleManifest -ne $null -and $sourceVisibleManifest.PSObject.Properties.Name -contains "window_capture_trusted" -and -not [bool]$sourceVisibleManifest.window_capture_trusted) {
	$warnings += "window_capture_not_trusted"
}

$gate = "review_ready"
if ($hardFailures.Count -gt 0) {
	$gate = "fail"
} elseif (-not $windowCopied) {
	$gate = "manual_open"
} elseif ($sourceVisibleManifest -ne $null -and $sourceVisibleManifest.PSObject.Properties.Name -contains "window_capture_trusted" -and -not [bool]$sourceVisibleManifest.window_capture_trusted) {
	$gate = "manual_open"
} elseif ($warnings.Count -gt 0) {
	$gate = "review"
}

$requiredChecks = @(
	"release_exe_started_with_first_go_firefight_arg",
	"task_880_fire_visual_polish_expected",
	"task_879_status_source_trace_expected",
	"task_877_window_handle_recapture_source_expected",
	"task_876_visible_status_source_expected",
	"window_handle_capture_trusted",
	"contact_fire_visible_in_selected_fireteam",
	"contact_fire_visible_in_mission_control",
	"contact_fire_visible_in_event_log",
	"fire_trace_visible",
	"impact_visible",
	"target_focus_visible",
	"short_fire_status_label_visible",
	"command_surfaces_still_usable",
	"no_stale_no_los_or_contact_pressure_only_message",
	"manual_visual_review_done"
)

$manifest = [ordered]@{
	schema = "sternenbuergerchen.release_first_exchange_fire_visual_recapture.v1"
	task_id = "TASK_881"
	source_task_id = "TASK_880"
	source_trace_task_id = "TASK_879"
	source_visible_status_task_id = "TASK_876"
	source_recapture_task_id = "TASK_877"
	source_focus_task_id = "TASK_850"
	source_exchange_task_id = "TASK_844"
	gate = $gate
	repo_root = $script:repoRoot
	branch = Get-GitValue -Arguments @("branch", "--show-current")
	git_head = Get-GitValue -Arguments @("rev-parse", "--short", "HEAD")
	launch_argument = $launchArgument
	wait_seconds = $WaitSeconds
	expected_fire_visual_schema = $fireVisualSchema
	expected_fire_visual_style_id = $fireVisualStyleId
	expected_trace_schema = $traceSchema
	expected_visible_status_schema = $visibleStatusSchema
	expected_visible_status_style_id = $visibleStatusStyleId
	expected_focus_style_id = $focusStyleId
	source_trace_manifest_path = "tmp/release_first_exchange_exported_status_source_trace.json"
	source_trace_manifest_full_path = $sourceTraceManifestPath
	source_trace_gate = if ($sourceTraceManifest -ne $null) { [string]$sourceTraceManifest.gate } else { "" }
	source_trace_output = @($sourceOutput)
	source_visible_status_manifest_path = "tmp/release_first_exchange_visible_status_recapture.json"
	source_visible_status_manifest_full_path = $sourceVisibleManifestPath
	source_visible_status_gate = if ($sourceVisibleManifest -ne $null) { [string]$sourceVisibleManifest.gate } else { "" }
	runtime_trace_written = if ($sourceTraceManifest -ne $null -and $sourceTraceManifest.PSObject.Properties.Name -contains "runtime_trace_written") { [bool]$sourceTraceManifest.runtime_trace_written } else { $false }
	runtime_trace_sample_count = if ($sourceTraceManifest -ne $null -and $sourceTraceManifest.PSObject.Properties.Name -contains "runtime_trace_sample_count") { [int]$sourceTraceManifest.runtime_trace_sample_count } else { 0 }
	runtime_trace_activation_observed = if ($sourceTraceManifest -ne $null -and $sourceTraceManifest.PSObject.Properties.Name -contains "runtime_trace_activation_observed") { [bool]$sourceTraceManifest.runtime_trace_activation_observed } else { $false }
	runtime_trace_final_no_los_or_contact_pressure_observed = if ($sourceTraceManifest -ne $null -and $sourceTraceManifest.PSObject.Properties.Name -contains "runtime_trace_final_no_los_or_contact_pressure_observed") { [bool]$sourceTraceManifest.runtime_trace_final_no_los_or_contact_pressure_observed } else { $false }
	window_capture_method = if ($sourceVisibleManifest -ne $null -and $sourceVisibleManifest.PSObject.Properties.Name -contains "window_capture_method") { [string]$sourceVisibleManifest.window_capture_method } else { "" }
	window_capture_trusted = if ($sourceVisibleManifest -ne $null -and $sourceVisibleManifest.PSObject.Properties.Name -contains "window_capture_trusted") { [bool]$sourceVisibleManifest.window_capture_trusted } else { $false }
	window_handle_capture_succeeded = if ($sourceVisibleManifest -ne $null -and $sourceVisibleManifest.PSObject.Properties.Name -contains "window_handle_capture_succeeded") { [bool]$sourceVisibleManifest.window_handle_capture_succeeded } else { $false }
	foreground_matches_selected_process = if ($sourceVisibleManifest -ne $null -and $sourceVisibleManifest.PSObject.Properties.Name -contains "foreground_matches_selected_process") { [bool]$sourceVisibleManifest.foreground_matches_selected_process } else { $false }
	selected_process_id = if ($sourceVisibleManifest -ne $null -and $sourceVisibleManifest.PSObject.Properties.Name -contains "selected_process_id") { [int]$sourceVisibleManifest.selected_process_id } else { 0 }
	window_handle_found = if ($sourceVisibleManifest -ne $null -and $sourceVisibleManifest.PSObject.Properties.Name -contains "window_handle_found") { [bool]$sourceVisibleManifest.window_handle_found } else { $false }
	desktop_screenshot_path = "tmp/release_first_exchange_fire_visual_recapture_desktop.png"
	window_screenshot_path = "tmp/release_first_exchange_fire_visual_recapture.png"
	desktop_screenshot_full_path = $taskDesktopScreenshotPath
	window_screenshot_full_path = $taskWindowScreenshotPath
	desktop_screenshot_written = $desktopCopied
	window_screenshot_written = $windowCopied
	required_checks = $requiredChecks
	expected_visible_contracts = [ordered]@{
		first_go_firefight_arg = $launchArgument
		fire_visual_schema = $fireVisualSchema
		fire_visual_style_id = $fireVisualStyleId
		status_source_trace_schema = $traceSchema
		visible_status_schema = $visibleStatusSchema
		visible_status_style_id = $visibleStatusStyleId
		readable_surfaces = @("selected_fireteam", "mission_control", "event_log", "primary3d_world")
		primary_policy = "CONTACT FIRE text, FireTrace, Impact and Target-Focus must be readable in the same real-window first-exchange moment."
	}
	manual_review_required = $true
	manual_review_done = $false
	read_only_capture = $true
	ui_sets_gameplay_truth = $false
	creates_command = $false
	creates_fire_event = $false
	creates_damage_event = $false
	creates_movement = $false
	sets_multiplayer_truth = $false
	starts_processes = [bool]$Launch
	kills_processes = [bool]$StopRunningReleaseProcess
	updates_shortcuts = $false
	warnings = @($warnings)
	hard_failures = @($hardFailures)
	recommended_next_task = "TASK_882 - Release First Exchange Fire Visual Findings"
}

$manifest | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $taskManifestPath -Encoding UTF8

Write-Host "TASK_881 Release first-exchange fire-visual recapture: $gate"
Write-Host "Manifest: $taskManifestPath"
Write-Host "Desktop screenshot: $taskDesktopScreenshotPath"
if ($windowCopied) {
	Write-Host "Window screenshot: $taskWindowScreenshotPath"
} else {
	Write-Host "Window screenshot missing; see source capture manifest."
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
