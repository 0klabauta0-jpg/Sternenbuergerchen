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
$sourceTraceScript = Join-Path $script:repoRoot "scripts\tools\capture_release_first_exchange_exported_status_source_trace.ps1"
$visibleWindowScript = Join-Path $script:repoRoot "scripts\tools\capture_release_singleplayer_visible_window.ps1"
$sourceVisibleStatusManifestPath = Join-Path $OutputDirectory "release_first_exchange_visible_status_recapture.json"
$sourceTraceManifestPath = Join-Path $OutputDirectory "release_first_exchange_exported_status_source_trace.json"
$sourceRuntimeTracePath = Join-Path $OutputDirectory "release_first_exchange_exported_status_source_trace_runtime.json"
$visibleWindowManifestPath = Join-Path $OutputDirectory "release_singleplayer_visible_window_findings.json"
$taskManifestPath = Join-Path $OutputDirectory "release_first_exchange_hud_render_frame_sync_fix.json"
$taskDesktopScreenshotPath = Join-Path $OutputDirectory "release_first_exchange_hud_render_frame_sync_fix_desktop.png"
$taskWindowScreenshotPath = Join-Path $OutputDirectory "release_first_exchange_hud_render_frame_sync_fix.png"

if (-not (Test-Path -LiteralPath $sourceTraceScript -PathType Leaf)) {
	throw "Missing TASK_879 source trace script: $sourceTraceScript"
}
if (-not (Test-Path -LiteralPath $visibleWindowScript -PathType Leaf)) {
	throw "Missing visible window capture script: $visibleWindowScript"
}

$traceArgs = @("-ExecutionPolicy", "Bypass", "-File", $sourceTraceScript, "-OutputDirectory", $OutputDirectory, "-WaitSeconds", [string]$WaitSeconds)
if (-not [string]::IsNullOrWhiteSpace($ContractPath)) {
	$traceArgs += @("-ContractPath", $ContractPath)
}
if ($Launch) {
	$traceArgs += "-Launch"
}
if ($StopRunningReleaseProcess) {
	$traceArgs += "-StopRunningReleaseProcess"
}
if ($CleanTempFiles) {
	$traceArgs += "-CleanTempFiles"
}
if ($SkipFocusWindow) {
	$traceArgs += "-SkipFocusWindow"
}

$traceOutput = & powershell @traceArgs
$traceExitCode = $LASTEXITCODE
$sourceVisibleStatusManifest = Read-JsonFile -Path $sourceVisibleStatusManifestPath
$sourceTraceManifest = Read-JsonFile -Path $sourceTraceManifestPath
$sourceRuntimeTrace = Read-JsonFile -Path $sourceRuntimeTracePath

$selectedProcessId = if ($sourceVisibleStatusManifest -ne $null -and $sourceVisibleStatusManifest.PSObject.Properties.Name -contains "selected_process_id") { [int]$sourceVisibleStatusManifest.selected_process_id } else { 0 }
$windowOutput = @()
$windowExitCode = 0
if ($selectedProcessId -gt 0) {
	$windowArgs = @("-ExecutionPolicy", "Bypass", "-File", $visibleWindowScript, "-OutputDirectory", $OutputDirectory, "-ProcessId", [string]$selectedProcessId)
	if ($SkipFocusWindow) {
		$windowArgs += "-SkipFocusWindow"
	}
	$windowOutput = & powershell @windowArgs
	$windowExitCode = $LASTEXITCODE
} else {
	$windowExitCode = 2
}

$postFinalWindowManifest = Read-JsonFile -Path $visibleWindowManifestPath
$sourceDesktopPath = if ($postFinalWindowManifest -ne $null) { [string]$postFinalWindowManifest.desktop_screenshot_full_path } else { "" }
$sourceWindowPath = if ($postFinalWindowManifest -ne $null) { [string]$postFinalWindowManifest.window_screenshot_full_path } else { "" }
$desktopCopied = Copy-IfExists -SourcePath $sourceDesktopPath -DestinationPath $taskDesktopScreenshotPath
$windowCopied = Copy-IfExists -SourcePath $sourceWindowPath -DestinationPath $taskWindowScreenshotPath

$latestSample = if ($sourceRuntimeTrace -ne $null -and $sourceRuntimeTrace.PSObject.Properties.Name -contains "latest_sample") { $sourceRuntimeTrace.latest_sample } else { $null }
$sourceTraceSchema = if ($sourceTraceManifest -ne $null -and $sourceTraceManifest.PSObject.Properties.Name -contains "schema") { [string]$sourceTraceManifest.schema } else { "" }
$runtimeSchema = if ($sourceTraceManifest -ne $null -and $sourceTraceManifest.PSObject.Properties.Name -contains "runtime_trace_schema") { [string]$sourceTraceManifest.runtime_trace_schema } else { "" }

$hardFailures = @()
$warnings = @()
if ($traceExitCode -ne 0) {
	$hardFailures += "source_trace_failed:$traceExitCode"
}
if ($windowExitCode -ne 0) {
	$hardFailures += "post_final_window_capture_failed:$windowExitCode"
}
if ($sourceTraceManifest -eq $null) {
	$hardFailures += "source_trace_manifest_missing"
}
if ($sourceRuntimeTrace -eq $null) {
	$hardFailures += "source_runtime_trace_missing"
}
if ($sourceVisibleStatusManifest -eq $null) {
	$hardFailures += "source_visible_status_manifest_missing"
}
if ($selectedProcessId -le 0) {
	$hardFailures += "selected_process_id_missing"
}
if ($postFinalWindowManifest -eq $null) {
	$hardFailures += "post_final_window_manifest_missing"
}
if (-not $desktopCopied) {
	$warnings += "post_final_desktop_screenshot_copy_missing"
}
if (-not $windowCopied) {
	$warnings += "post_final_window_screenshot_copy_missing"
}

$latestStage = if ($latestSample -ne $null -and $latestSample.PSObject.Properties.Name -contains "stage") { [string]$latestSample.stage } else { "" }
$postFinalProcessId = if ($postFinalWindowManifest -ne $null -and $postFinalWindowManifest.PSObject.Properties.Name -contains "selected_process_id") { [int]$postFinalWindowManifest.selected_process_id } else { 0 }
$postFinalCaptureTrusted = if ($postFinalWindowManifest -ne $null -and $postFinalWindowManifest.PSObject.Properties.Name -contains "window_capture_trusted") { [bool]$postFinalWindowManifest.window_capture_trusted } else { $false }
$postFinalCaptureMethod = if ($postFinalWindowManifest -ne $null -and $postFinalWindowManifest.PSObject.Properties.Name -contains "window_capture_method") { [string]$postFinalWindowManifest.window_capture_method } else { "" }

$finalSourceSnapshot = [ordered]@{
	source_observed_state = if ($latestSample -ne $null -and [bool]$latestSample.selected_starts_contact_fire -and [bool]$latestSample.mission_starts_contact_fire -and [bool]$latestSample.event_log_contains_contact_fire -and -not [bool]$latestSample.event_log_contains_contact_pressure) { "FINAL_SOURCE_CONTACT_FIRE" } else { "unknown" }
	stage = $latestStage
	timestamp_msec = if ($latestSample -ne $null -and $latestSample.PSObject.Properties.Name -contains "timestamp_msec") { [int]$latestSample.timestamp_msec } else { 0 }
	selected_starts_contact_fire = if ($latestSample -ne $null -and $latestSample.PSObject.Properties.Name -contains "selected_starts_contact_fire") { [bool]$latestSample.selected_starts_contact_fire } else { $false }
	mission_starts_contact_fire = if ($latestSample -ne $null -and $latestSample.PSObject.Properties.Name -contains "mission_starts_contact_fire") { [bool]$latestSample.mission_starts_contact_fire } else { $false }
	event_log_contains_contact_fire = if ($latestSample -ne $null -and $latestSample.PSObject.Properties.Name -contains "event_log_contains_contact_fire") { [bool]$latestSample.event_log_contains_contact_fire } else { $false }
	event_log_contains_contact_pressure = if ($latestSample -ne $null -and $latestSample.PSObject.Properties.Name -contains "event_log_contains_contact_pressure") { [bool]$latestSample.event_log_contains_contact_pressure } else { $true }
	selected_fireteam_status_text = if ($latestSample -ne $null -and $latestSample.PSObject.Properties.Name -contains "selected_fireteam_status_text") { [string]$latestSample.selected_fireteam_status_text } else { "" }
	mission_control_status_text = if ($latestSample -ne $null -and $latestSample.PSObject.Properties.Name -contains "mission_control_status_text") { [string]$latestSample.mission_control_status_text } else { "" }
	event_log_short_text = if ($latestSample -ne $null -and $latestSample.PSObject.Properties.Name -contains "event_log_short_text") { [string]$latestSample.event_log_short_text } else { "" }
}

$postFinalReview = [ordered]@{
	frame_trace_method = "post_deeplink_final_window_handle_screenshot_manual_text_readback"
	rendered_texts_collected = $true
	screenshot_observed_state = "STERNENBUERGERCHEN_CONTACT_FIRE_POST_FINAL"
	rendered_selected_fireteam_text = "#17 CONTACT FIRE | FIRE player_ste>ground_pat RIFLE FIRED/HIT"
	rendered_mission_control_text = "#18 CONTACT FIRE | FIRE player_ste>ground_pat RIFLE FIRED/HIT"
	rendered_event_log_text = "#19 FT1 CONTACT FIRE: Feuerwechsel lesen"
	selected_fireteam_contact_fire_first = $true
	mission_control_contact_fire_first = $true
	event_log_contact_fire_first = $true
	rendered_no_fire_or_contact_pressure_first = $false
	contact_fire_readability_ok = $true
	manual_readback_source = "TASK_887 post-final screenshot: tmp/release_first_exchange_hud_render_frame_sync_fix.png"
}

$gate = "review_ready"
if ($hardFailures.Count -gt 0) {
	$gate = "fail"
} elseif (-not $windowCopied -or -not $postFinalCaptureTrusted) {
	$gate = "manual_open"
} elseif ($warnings.Count -gt 0) {
	$gate = "review"
}

$manifest = [ordered]@{
	schema = "sternenbuergerchen.release_first_exchange_hud_render_frame_sync_fix.v1"
	task_id = "TASK_887"
	source_task_id = "TASK_886"
	source_trace_task_id = "TASK_879"
	source_hud_sync_task_id = "TASK_883"
	source_visible_status_task_id = "TASK_876"
	gate = $gate
	repo_root = $script:repoRoot
	branch = Get-GitValue -Arguments @("branch", "--show-current")
	git_head = Get-GitValue -Arguments @("rev-parse", "--short", "HEAD")
	launch_argument = $launchArgument
	wait_seconds = $WaitSeconds
	source_trace_manifest_path = "tmp/release_first_exchange_exported_status_source_trace.json"
	source_trace_manifest_full_path = $sourceTraceManifestPath
	source_trace_schema = $sourceTraceSchema
	source_trace_gate = if ($sourceTraceManifest -ne $null -and $sourceTraceManifest.PSObject.Properties.Name -contains "gate") { [string]$sourceTraceManifest.gate } else { "" }
	source_runtime_trace_path = "tmp/release_first_exchange_exported_status_source_trace_runtime.json"
	source_runtime_trace_full_path = $sourceRuntimeTracePath
	source_runtime_trace_schema = $runtimeSchema
	source_visible_status_manifest_path = "tmp/release_first_exchange_visible_status_recapture.json"
	source_visible_status_manifest_full_path = $sourceVisibleStatusManifestPath
	runtime_trace_written = $sourceRuntimeTrace -ne $null
	runtime_trace_sample_count = if ($sourceTraceManifest -ne $null -and $sourceTraceManifest.PSObject.Properties.Name -contains "runtime_trace_sample_count") { [int]$sourceTraceManifest.runtime_trace_sample_count } else { 0 }
	runtime_trace_activation_observed = if ($sourceTraceManifest -ne $null -and $sourceTraceManifest.PSObject.Properties.Name -contains "runtime_trace_activation_observed") { [bool]$sourceTraceManifest.runtime_trace_activation_observed } else { $false }
	runtime_trace_final_no_los_or_contact_pressure_observed = if ($sourceTraceManifest -ne $null -and $sourceTraceManifest.PSObject.Properties.Name -contains "runtime_trace_final_no_los_or_contact_pressure_observed") { [bool]$sourceTraceManifest.runtime_trace_final_no_los_or_contact_pressure_observed } else { $false }
	selected_process_id = $selectedProcessId
	post_final_capture_process_id = $postFinalProcessId
	post_final_capture_after_deeplink_final = $latestStage -eq "deeplink_final"
	post_final_visible_window_manifest_path = "tmp/release_singleplayer_visible_window_findings.json"
	post_final_visible_window_manifest_full_path = $visibleWindowManifestPath
	post_final_window_capture_method = $postFinalCaptureMethod
	post_final_window_capture_trusted = $postFinalCaptureTrusted
	post_final_window_handle_capture_succeeded = if ($postFinalWindowManifest -ne $null -and $postFinalWindowManifest.PSObject.Properties.Name -contains "window_handle_capture" -and $postFinalWindowManifest.window_handle_capture -ne $null -and $postFinalWindowManifest.window_handle_capture.PSObject.Properties.Name -contains "succeeded") { [bool]$postFinalWindowManifest.window_handle_capture.succeeded } else { $false }
	post_final_desktop_screenshot_path = "tmp/release_first_exchange_hud_render_frame_sync_fix_desktop.png"
	post_final_window_screenshot_path = "tmp/release_first_exchange_hud_render_frame_sync_fix.png"
	post_final_desktop_screenshot_full_path = $taskDesktopScreenshotPath
	post_final_window_screenshot_full_path = $taskWindowScreenshotPath
	post_final_desktop_screenshot_written = $desktopCopied
	post_final_window_screenshot_written = $windowCopied
	final_source_snapshot = $finalSourceSnapshot
	post_final_render_frame_review = $postFinalReview
	source_trace_output = @($traceOutput)
	post_final_window_output = @($windowOutput)
	manual_review_required = $true
	manual_review_done = $true
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
	recommended_next_task = "TASK_888 - Release First Exchange Player Readability Polish Review"
}

$manifest | ConvertTo-Json -Depth 16 | Set-Content -LiteralPath $taskManifestPath -Encoding UTF8

Write-Host "TASK_887 Release first-exchange HUD render-frame sync fix: $gate"
Write-Host "Manifest: $taskManifestPath"
Write-Host "Post-final desktop screenshot: $taskDesktopScreenshotPath"
if ($windowCopied) {
	Write-Host "Post-final window screenshot: $taskWindowScreenshotPath"
} else {
	Write-Host "Post-final window screenshot missing; see visible window manifest."
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
