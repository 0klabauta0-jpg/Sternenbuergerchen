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
$sourceRenderSyncScript = Join-Path $script:repoRoot "scripts\tools\capture_release_first_exchange_hud_render_frame_sync_fix.ps1"
$sourceRenderSyncManifestPath = Join-Path $OutputDirectory "release_first_exchange_hud_render_frame_sync_fix.json"
$taskManifestPath = Join-Path $OutputDirectory "release_first_exchange_hud_density_real_window_recapture.json"
$taskDesktopScreenshotPath = Join-Path $OutputDirectory "release_first_exchange_hud_density_real_window_recapture_desktop.png"
$taskWindowScreenshotPath = Join-Path $OutputDirectory "release_first_exchange_hud_density_real_window_recapture.png"

if (-not (Test-Path -LiteralPath $sourceRenderSyncScript -PathType Leaf)) {
	throw "Missing TASK_887 render-sync capture script: $sourceRenderSyncScript"
}

$sourceArgs = @("-ExecutionPolicy", "Bypass", "-File", $sourceRenderSyncScript, "-OutputDirectory", $OutputDirectory, "-WaitSeconds", [string]$WaitSeconds)
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
$sourceRenderSyncManifest = Read-JsonFile -Path $sourceRenderSyncManifestPath

$sourceDesktopPath = if ($sourceRenderSyncManifest -ne $null -and $sourceRenderSyncManifest.PSObject.Properties.Name -contains "post_final_desktop_screenshot_full_path") { [string]$sourceRenderSyncManifest.post_final_desktop_screenshot_full_path } else { "" }
$sourceWindowPath = if ($sourceRenderSyncManifest -ne $null -and $sourceRenderSyncManifest.PSObject.Properties.Name -contains "post_final_window_screenshot_full_path") { [string]$sourceRenderSyncManifest.post_final_window_screenshot_full_path } else { "" }
$desktopCopied = Copy-IfExists -SourcePath $sourceDesktopPath -DestinationPath $taskDesktopScreenshotPath
$windowCopied = Copy-IfExists -SourcePath $sourceWindowPath -DestinationPath $taskWindowScreenshotPath

$hardFailures = @()
$warnings = @()
if ($sourceExitCode -ne 0) {
	$hardFailures += "source_render_sync_capture_failed:$sourceExitCode"
}
if ($sourceRenderSyncManifest -eq $null) {
	$hardFailures += "source_render_sync_manifest_missing"
}
if (-not $desktopCopied) {
	$warnings += "post_final_desktop_screenshot_copy_missing"
}
if (-not $windowCopied) {
	$warnings += "post_final_window_screenshot_copy_missing"
}

$selectedProcessId = if ($sourceRenderSyncManifest -ne $null -and $sourceRenderSyncManifest.PSObject.Properties.Name -contains "selected_process_id") { [int]$sourceRenderSyncManifest.selected_process_id } else { 0 }
$postFinalProcessId = if ($sourceRenderSyncManifest -ne $null -and $sourceRenderSyncManifest.PSObject.Properties.Name -contains "post_final_capture_process_id") { [int]$sourceRenderSyncManifest.post_final_capture_process_id } else { 0 }
$postFinalCaptureTrusted = if ($sourceRenderSyncManifest -ne $null -and $sourceRenderSyncManifest.PSObject.Properties.Name -contains "post_final_window_capture_trusted") { [bool]$sourceRenderSyncManifest.post_final_window_capture_trusted } else { $false }
$postFinalCaptureMethod = if ($sourceRenderSyncManifest -ne $null -and $sourceRenderSyncManifest.PSObject.Properties.Name -contains "post_final_window_capture_method") { [string]$sourceRenderSyncManifest.post_final_window_capture_method } else { "" }

$requiredChecks = @(
	"contact_fire_visible_in_selected_fireteam",
	"contact_fire_visible_in_mission_control",
	"event_log_contact_fire_visible_without_blocking",
	"bottom_hud_density_reduced",
	"fire_trace_direction_obvious",
	"impact_or_hit_marker_obvious",
	"target_focus_obvious",
	"no_stale_no_fire_or_contact_pressure_first_read",
	"no_new_hud_gameplay_truth"
)

$postFinalReview = [ordered]@{
	frame_trace_method = "post_deeplink_final_window_handle_screenshot_density_review_required"
	rendered_texts_collected = $false
	screenshot_observed_state = "TASK_890_REVIEW_REQUIRED"
	expected_contact_fire_first = $true
	expected_event_log_density_reduced = $true
	expected_fire_trace_impact_target_focus = $true
	manual_readback_source = "TASK_890 screenshot: tmp/release_first_exchange_hud_density_real_window_recapture.png"
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
	schema = "sternenbuergerchen.release_first_exchange_hud_density_real_window_recapture.v1"
	task_id = "TASK_890"
	source_task_id = "TASK_889"
	source_render_sync_task_id = "TASK_887"
	source_trace_task_id = "TASK_879"
	source_hud_sync_task_id = "TASK_883"
	source_fire_visual_task_id = "TASK_880"
	source_visible_status_task_id = "TASK_876"
	gate = $gate
	repo_root = $script:repoRoot
	branch = Get-GitValue -Arguments @("branch", "--show-current")
	git_head = Get-GitValue -Arguments @("rev-parse", "--short", "HEAD")
	launch_argument = $launchArgument
	wait_seconds = $WaitSeconds
	expected_hud_density_schema = "sternenbuergerchen.release_first_exchange_hud_density_fire_visual_polish.v1"
	expected_hud_density_style_id = "task_889_release_first_exchange_hud_density_fire_visual_polish_v1"
	source_render_sync_manifest_path = "tmp/release_first_exchange_hud_render_frame_sync_fix.json"
	source_render_sync_manifest_full_path = $sourceRenderSyncManifestPath
	source_render_sync_schema = if ($sourceRenderSyncManifest -ne $null -and $sourceRenderSyncManifest.PSObject.Properties.Name -contains "schema") { [string]$sourceRenderSyncManifest.schema } else { "" }
	source_render_sync_gate = if ($sourceRenderSyncManifest -ne $null -and $sourceRenderSyncManifest.PSObject.Properties.Name -contains "gate") { [string]$sourceRenderSyncManifest.gate } else { "" }
	selected_process_id = $selectedProcessId
	post_final_capture_process_id = $postFinalProcessId
	post_final_capture_after_deeplink_final = if ($sourceRenderSyncManifest -ne $null -and $sourceRenderSyncManifest.PSObject.Properties.Name -contains "post_final_capture_after_deeplink_final") { [bool]$sourceRenderSyncManifest.post_final_capture_after_deeplink_final } else { $false }
	post_final_window_capture_method = $postFinalCaptureMethod
	post_final_window_capture_trusted = $postFinalCaptureTrusted
	post_final_window_handle_capture_succeeded = if ($sourceRenderSyncManifest -ne $null -and $sourceRenderSyncManifest.PSObject.Properties.Name -contains "post_final_window_handle_capture_succeeded") { [bool]$sourceRenderSyncManifest.post_final_window_handle_capture_succeeded } else { $false }
	post_final_desktop_screenshot_path = "tmp/release_first_exchange_hud_density_real_window_recapture_desktop.png"
	post_final_window_screenshot_path = "tmp/release_first_exchange_hud_density_real_window_recapture.png"
	post_final_desktop_screenshot_full_path = $taskDesktopScreenshotPath
	post_final_window_screenshot_full_path = $taskWindowScreenshotPath
	post_final_desktop_screenshot_written = $desktopCopied
	post_final_window_screenshot_written = $windowCopied
	final_source_snapshot = if ($sourceRenderSyncManifest -ne $null -and $sourceRenderSyncManifest.PSObject.Properties.Name -contains "final_source_snapshot") { $sourceRenderSyncManifest.final_source_snapshot } else { [ordered]@{} }
	source_post_final_render_frame_review = if ($sourceRenderSyncManifest -ne $null -and $sourceRenderSyncManifest.PSObject.Properties.Name -contains "post_final_render_frame_review") { $sourceRenderSyncManifest.post_final_render_frame_review } else { [ordered]@{} }
	post_final_hud_density_render_review = $postFinalReview
	required_checks = $requiredChecks
	completed_manual_checks = @()
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
	source_render_sync_output = @($sourceOutput)
	recommended_next_task = "TASK_891 - Release First Exchange HUD Density Visual Findings"
}

$manifest | ConvertTo-Json -Depth 16 | Set-Content -LiteralPath $taskManifestPath -Encoding UTF8

Write-Host "TASK_890 Release first-exchange HUD density real-window recapture: $gate"
Write-Host "Manifest: $taskManifestPath"
Write-Host "Desktop screenshot: $taskDesktopScreenshotPath"
if ($windowCopied) {
	Write-Host "Window screenshot: $taskWindowScreenshotPath"
} else {
	Write-Host "Window screenshot missing; see TASK_887 render-sync manifest."
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
