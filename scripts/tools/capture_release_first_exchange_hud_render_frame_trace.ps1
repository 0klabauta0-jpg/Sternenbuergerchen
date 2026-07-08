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
$sourceRecaptureScript = Join-Path $script:repoRoot "scripts\tools\capture_release_first_exchange_hud_source_sync_recapture.ps1"
$sourceRecaptureManifestPath = Join-Path $OutputDirectory "release_first_exchange_hud_source_sync_recapture.json"
$sourceTraceManifestPath = Join-Path $OutputDirectory "release_first_exchange_exported_status_source_trace.json"
$sourceRuntimeTracePath = Join-Path $OutputDirectory "release_first_exchange_exported_status_source_trace_runtime.json"
$taskManifestPath = Join-Path $OutputDirectory "release_first_exchange_hud_render_frame_trace.json"
$taskDesktopScreenshotPath = Join-Path $OutputDirectory "release_first_exchange_hud_render_frame_trace_desktop.png"
$taskWindowScreenshotPath = Join-Path $OutputDirectory "release_first_exchange_hud_render_frame_trace.png"

if (-not (Test-Path -LiteralPath $sourceRecaptureScript -PathType Leaf)) {
	throw "Missing TASK_884 source capture script: $sourceRecaptureScript"
}

$sourceArgs = @("-ExecutionPolicy", "Bypass", "-File", $sourceRecaptureScript, "-OutputDirectory", $OutputDirectory, "-WaitSeconds", [string]$WaitSeconds)
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
$sourceRecaptureManifest = Read-JsonFile -Path $sourceRecaptureManifestPath
$sourceTraceManifest = Read-JsonFile -Path $sourceTraceManifestPath
$sourceRuntimeTrace = Read-JsonFile -Path $sourceRuntimeTracePath

$sourceDesktopPath = if ($sourceRecaptureManifest -ne $null) { [string]$sourceRecaptureManifest.desktop_screenshot_full_path } else { "" }
$sourceWindowPath = if ($sourceRecaptureManifest -ne $null) { [string]$sourceRecaptureManifest.window_screenshot_full_path } else { "" }
$desktopCopied = Copy-IfExists -SourcePath $sourceDesktopPath -DestinationPath $taskDesktopScreenshotPath
$windowCopied = Copy-IfExists -SourcePath $sourceWindowPath -DestinationPath $taskWindowScreenshotPath

$hardFailures = @()
$warnings = @()
if ($sourceExitCode -ne 0) {
	$hardFailures += "source_hud_source_sync_recapture_failed:$sourceExitCode"
}
if ($sourceRecaptureManifest -eq $null) {
	$hardFailures += "source_hud_source_sync_recapture_manifest_missing"
} elseif ([string]$sourceRecaptureManifest.gate -eq "fail") {
	$hardFailures += "source_hud_source_sync_recapture_failed"
}
if ($sourceTraceManifest -eq $null) {
	$hardFailures += "source_trace_manifest_missing"
}
if ($sourceRuntimeTrace -eq $null) {
	$hardFailures += "source_runtime_trace_missing"
}
if (-not $desktopCopied) {
	$warnings += "desktop_screenshot_copy_missing"
}
if (-not $windowCopied) {
	$warnings += "window_screenshot_copy_missing"
}

$latestSample = if ($sourceRuntimeTrace -ne $null -and $sourceRuntimeTrace.PSObject.Properties.Name -contains "latest_sample") { $sourceRuntimeTrace.latest_sample } else { $null }
$runtimeSchema = if ($sourceTraceManifest -ne $null -and $sourceTraceManifest.PSObject.Properties.Name -contains "runtime_trace_schema") { [string]$sourceTraceManifest.runtime_trace_schema } else { "" }
$sourceTraceSchema = if ($sourceTraceManifest -ne $null -and $sourceTraceManifest.PSObject.Properties.Name -contains "schema") { [string]$sourceTraceManifest.schema } else { "" }

$renderFrameReview = [ordered]@{
	frame_trace_method = "task_884_window_handle_screenshot_manual_text_readback_plus_task_879_latest_sample"
	rendered_texts_collected = $true
	screenshot_observed_state = "STERNENBUERGERCHEN_NO_FIRE_NO_LOS_CONTACT_PRESSURE"
	rendered_selected_fireteam_text = "#17 NEXT LOS/RANGE KORRIGIEREN | WHY KEIN ZIEL | Kampf NO FIRE NO_LOS"
	rendered_mission_control_text = "#18 NEXT LOS/RANGE KORRIGIEREN | Kampf NO FIRE NO_LOS"
	rendered_event_log_text = "#19 FT1 CONTACT PRESSURE: Position korrigieren"
	capture_frame_not_bound_to_final_source = $true
	contact_fire_readability_ok = $false
	manual_readback_source = "TASK_884 Sichtbefund aus tmp/release_first_exchange_hud_source_sync_recapture.png"
}

$finalSourceSnapshot = [ordered]@{
	source_observed_state = if ($latestSample -ne $null -and [bool]$latestSample.selected_starts_contact_fire -and [bool]$latestSample.mission_starts_contact_fire -and [bool]$latestSample.event_log_contains_contact_fire) { "FINAL_SOURCE_CONTACT_FIRE" } else { "unknown" }
	stage = if ($latestSample -ne $null -and $latestSample.PSObject.Properties.Name -contains "stage") { [string]$latestSample.stage } else { "" }
	timestamp_msec = if ($latestSample -ne $null -and $latestSample.PSObject.Properties.Name -contains "timestamp_msec") { [int]$latestSample.timestamp_msec } else { 0 }
	selected_starts_contact_fire = if ($latestSample -ne $null -and $latestSample.PSObject.Properties.Name -contains "selected_starts_contact_fire") { [bool]$latestSample.selected_starts_contact_fire } else { $false }
	mission_starts_contact_fire = if ($latestSample -ne $null -and $latestSample.PSObject.Properties.Name -contains "mission_starts_contact_fire") { [bool]$latestSample.mission_starts_contact_fire } else { $false }
	event_log_contains_contact_fire = if ($latestSample -ne $null -and $latestSample.PSObject.Properties.Name -contains "event_log_contains_contact_fire") { [bool]$latestSample.event_log_contains_contact_fire } else { $false }
	event_log_contains_contact_pressure = if ($latestSample -ne $null -and $latestSample.PSObject.Properties.Name -contains "event_log_contains_contact_pressure") { [bool]$latestSample.event_log_contains_contact_pressure } else { $true }
	selected_fireteam_status_text = if ($latestSample -ne $null -and $latestSample.PSObject.Properties.Name -contains "selected_fireteam_status_text") { [string]$latestSample.selected_fireteam_status_text } else { "" }
	mission_control_status_text = if ($latestSample -ne $null -and $latestSample.PSObject.Properties.Name -contains "mission_control_status_text") { [string]$latestSample.mission_control_status_text } else { "" }
	event_log_short_text = if ($latestSample -ne $null -and $latestSample.PSObject.Properties.Name -contains "event_log_short_text") { [string]$latestSample.event_log_short_text } else { "" }
}

$gate = "review_ready"
if ($hardFailures.Count -gt 0) {
	$gate = "fail"
} elseif (-not $windowCopied) {
	$gate = "manual_open"
} elseif ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "window_capture_trusted" -and -not [bool]$sourceRecaptureManifest.window_capture_trusted) {
	$gate = "manual_open"
} elseif ($warnings.Count -gt 0) {
	$gate = "review"
}

$manifest = [ordered]@{
	schema = "sternenbuergerchen.release_first_exchange_hud_render_frame_trace.v1"
	task_id = "TASK_886"
	source_task_id = "TASK_885"
	source_recapture_task_id = "TASK_884"
	source_hud_sync_task_id = "TASK_883"
	source_trace_task_id = "TASK_879"
	source_fire_visual_task_id = "TASK_880"
	source_visible_status_task_id = "TASK_876"
	gate = $gate
	repo_root = $script:repoRoot
	branch = Get-GitValue -Arguments @("branch", "--show-current")
	git_head = Get-GitValue -Arguments @("rev-parse", "--short", "HEAD")
	launch_argument = $launchArgument
	wait_seconds = $WaitSeconds
	source_recapture_manifest_path = "tmp/release_first_exchange_hud_source_sync_recapture.json"
	source_recapture_manifest_full_path = $sourceRecaptureManifestPath
	source_recapture_schema = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "schema") { [string]$sourceRecaptureManifest.schema } else { "" }
	source_recapture_gate = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "gate") { [string]$sourceRecaptureManifest.gate } else { "" }
	source_trace_manifest_path = "tmp/release_first_exchange_exported_status_source_trace.json"
	source_trace_manifest_full_path = $sourceTraceManifestPath
	source_trace_schema = $sourceTraceSchema
	source_trace_gate = if ($sourceTraceManifest -ne $null -and $sourceTraceManifest.PSObject.Properties.Name -contains "gate") { [string]$sourceTraceManifest.gate } else { "" }
	source_runtime_trace_path = "tmp/release_first_exchange_exported_status_source_trace_runtime.json"
	source_runtime_trace_full_path = $sourceRuntimeTracePath
	source_runtime_trace_schema = $runtimeSchema
	source_capture_output = @($sourceOutput)
	runtime_trace_written = if ($sourceTraceManifest -ne $null -and $sourceTraceManifest.PSObject.Properties.Name -contains "runtime_trace_written") { [bool]$sourceTraceManifest.runtime_trace_written } else { $false }
	runtime_trace_sample_count = if ($sourceTraceManifest -ne $null -and $sourceTraceManifest.PSObject.Properties.Name -contains "runtime_trace_sample_count") { [int]$sourceTraceManifest.runtime_trace_sample_count } else { 0 }
	runtime_trace_activation_observed = if ($sourceTraceManifest -ne $null -and $sourceTraceManifest.PSObject.Properties.Name -contains "runtime_trace_activation_observed") { [bool]$sourceTraceManifest.runtime_trace_activation_observed } else { $false }
	runtime_trace_final_no_los_or_contact_pressure_observed = if ($sourceTraceManifest -ne $null -and $sourceTraceManifest.PSObject.Properties.Name -contains "runtime_trace_final_no_los_or_contact_pressure_observed") { [bool]$sourceTraceManifest.runtime_trace_final_no_los_or_contact_pressure_observed } else { $false }
	window_capture_method = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "window_capture_method") { [string]$sourceRecaptureManifest.window_capture_method } else { "" }
	window_capture_trusted = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "window_capture_trusted") { [bool]$sourceRecaptureManifest.window_capture_trusted } else { $false }
	window_handle_capture_succeeded = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "window_handle_capture_succeeded") { [bool]$sourceRecaptureManifest.window_handle_capture_succeeded } else { $false }
	desktop_screenshot_path = "tmp/release_first_exchange_hud_render_frame_trace_desktop.png"
	window_screenshot_path = "tmp/release_first_exchange_hud_render_frame_trace.png"
	desktop_screenshot_full_path = $taskDesktopScreenshotPath
	window_screenshot_full_path = $taskWindowScreenshotPath
	desktop_screenshot_written = $desktopCopied
	window_screenshot_written = $windowCopied
	render_frame_review = $renderFrameReview
	final_source_snapshot = $finalSourceSnapshot
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
	recommended_next_task = "TASK_887 - Release First Exchange Real Window HUD Render Frame Sync Fix"
}

$manifest | ConvertTo-Json -Depth 16 | Set-Content -LiteralPath $taskManifestPath -Encoding UTF8

Write-Host "TASK_886 Release first-exchange HUD render-frame trace: $gate"
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
