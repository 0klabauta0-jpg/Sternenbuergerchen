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
$sourceEleganceScript = Join-Path $script:repoRoot "scripts\tools\capture_release_first_exchange_combat_focal_elegance_real_window_recapture.ps1"
$sourceEleganceManifestPath = Join-Path $OutputDirectory "release_first_exchange_combat_focal_elegance_real_window_recapture.json"
$taskManifestPath = Join-Path $OutputDirectory "release_first_exchange_combat_marker_scale_real_window_recapture.json"
$taskDesktopScreenshotPath = Join-Path $OutputDirectory "release_first_exchange_combat_marker_scale_real_window_recapture_desktop.png"
$taskWindowScreenshotPath = Join-Path $OutputDirectory "release_first_exchange_combat_marker_scale_real_window_recapture.png"

if (-not (Test-Path -LiteralPath $sourceEleganceScript -PathType Leaf)) {
	throw "Missing TASK_899 combat focal elegance capture script: $sourceEleganceScript"
}

$sourceArgs = @("-ExecutionPolicy", "Bypass", "-File", $sourceEleganceScript, "-OutputDirectory", $OutputDirectory, "-WaitSeconds", [string]$WaitSeconds)
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
$sourceEleganceManifest = Read-JsonFile -Path $sourceEleganceManifestPath

$sourceDesktopPath = if ($sourceEleganceManifest -ne $null -and $sourceEleganceManifest.PSObject.Properties.Name -contains "post_final_desktop_screenshot_full_path") { [string]$sourceEleganceManifest.post_final_desktop_screenshot_full_path } else { "" }
$sourceWindowPath = if ($sourceEleganceManifest -ne $null -and $sourceEleganceManifest.PSObject.Properties.Name -contains "post_final_window_screenshot_full_path") { [string]$sourceEleganceManifest.post_final_window_screenshot_full_path } else { "" }
$desktopCopied = Copy-IfExists -SourcePath $sourceDesktopPath -DestinationPath $taskDesktopScreenshotPath
$windowCopied = Copy-IfExists -SourcePath $sourceWindowPath -DestinationPath $taskWindowScreenshotPath

$hardFailures = @()
$warnings = @()
if ($sourceExitCode -ne 0) {
	$hardFailures += "source_combat_focal_elegance_capture_failed:$sourceExitCode"
}
if ($sourceEleganceManifest -eq $null) {
	$hardFailures += "source_combat_focal_elegance_manifest_missing"
}
if (-not $desktopCopied) {
	$warnings += "post_final_desktop_screenshot_copy_missing"
}
if (-not $windowCopied) {
	$warnings += "post_final_window_screenshot_copy_missing"
}

$selectedProcessId = if ($sourceEleganceManifest -ne $null -and $sourceEleganceManifest.PSObject.Properties.Name -contains "selected_process_id") { [int]$sourceEleganceManifest.selected_process_id } else { 0 }
$postFinalProcessId = if ($sourceEleganceManifest -ne $null -and $sourceEleganceManifest.PSObject.Properties.Name -contains "post_final_capture_process_id") { [int]$sourceEleganceManifest.post_final_capture_process_id } else { 0 }
$postFinalCaptureTrusted = if ($sourceEleganceManifest -ne $null -and $sourceEleganceManifest.PSObject.Properties.Name -contains "post_final_window_capture_trusted") { [bool]$sourceEleganceManifest.post_final_window_capture_trusted } else { $false }
$postFinalCaptureMethod = if ($sourceEleganceManifest -ne $null -and $sourceEleganceManifest.PSObject.Properties.Name -contains "post_final_window_capture_method") { [string]$sourceEleganceManifest.post_final_window_capture_method } else { "" }

$requiredChecks = @(
	"contact_fire_visible_in_selected_fireteam",
	"contact_fire_visible_in_mission_control",
	"event_log_contact_fire_visible_without_blocking",
	"smaller_target_halo_less_marker_disc",
	"grid_world_noise_quieter",
	"source_to_target_lane_still_readable",
	"source_glow_subtle",
	"command_surfaces_still_usable",
	"no_stale_no_fire_or_contact_pressure_first_read",
	"no_new_hud_gameplay_truth"
)

$postFinalReview = [ordered]@{
	frame_trace_method = "post_deeplink_final_window_handle_screenshot_combat_marker_scale_review_required"
	rendered_texts_collected = $false
	screenshot_observed_state = "TASK_902_REVIEW_REQUIRED"
	expected_contact_fire_first = $true
	expected_marker_scale_schema = "sternenbuergerchen.release_first_exchange_combat_marker_scale_world_noise_polish.v1"
	expected_marker_scale_style_id = "task_901_release_first_exchange_combat_marker_scale_world_noise_v1"
	expected_target_halo_smaller_than_task_898 = $true
	expected_grid_world_noise_quieter_than_task_899 = $true
	expected_source_to_target_lane_readable = $true
	expected_source_glow_subtle = $true
	manual_readback_source = "TASK_902 screenshot: tmp/release_first_exchange_combat_marker_scale_real_window_recapture.png"
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
	schema = "sternenbuergerchen.release_first_exchange_combat_marker_scale_real_window_recapture.v1"
	task_id = "TASK_902"
	source_task_id = "TASK_901"
	source_findings_task_id = "TASK_900"
	source_elegance_task_id = "TASK_898"
	source_elegance_recapture_task_id = "TASK_899"
	gate = $gate
	repo_root = $script:repoRoot
	branch = Get-GitValue -Arguments @("branch", "--show-current")
	git_head = Get-GitValue -Arguments @("rev-parse", "--short", "HEAD")
	launch_argument = $launchArgument
	wait_seconds = $WaitSeconds
	expected_marker_scale_schema = "sternenbuergerchen.release_first_exchange_combat_marker_scale_world_noise_polish.v1"
	expected_marker_scale_style_id = "task_901_release_first_exchange_combat_marker_scale_world_noise_v1"
	expected_elegance_style_id = "task_898_release_first_exchange_combat_focal_elegance_v1"
	source_elegance_recapture_manifest_path = "tmp/release_first_exchange_combat_focal_elegance_real_window_recapture.json"
	source_elegance_recapture_manifest_full_path = $sourceEleganceManifestPath
	source_elegance_recapture_schema = if ($sourceEleganceManifest -ne $null -and $sourceEleganceManifest.PSObject.Properties.Name -contains "schema") { [string]$sourceEleganceManifest.schema } else { "" }
	source_elegance_recapture_gate = if ($sourceEleganceManifest -ne $null -and $sourceEleganceManifest.PSObject.Properties.Name -contains "gate") { [string]$sourceEleganceManifest.gate } else { "" }
	selected_process_id = $selectedProcessId
	post_final_capture_process_id = $postFinalProcessId
	post_final_capture_after_deeplink_final = if ($sourceEleganceManifest -ne $null -and $sourceEleganceManifest.PSObject.Properties.Name -contains "post_final_capture_after_deeplink_final") { [bool]$sourceEleganceManifest.post_final_capture_after_deeplink_final } else { $false }
	post_final_window_capture_method = $postFinalCaptureMethod
	post_final_window_capture_trusted = $postFinalCaptureTrusted
	post_final_window_handle_capture_succeeded = if ($sourceEleganceManifest -ne $null -and $sourceEleganceManifest.PSObject.Properties.Name -contains "post_final_window_handle_capture_succeeded") { [bool]$sourceEleganceManifest.post_final_window_handle_capture_succeeded } else { $false }
	post_final_desktop_screenshot_path = "tmp/release_first_exchange_combat_marker_scale_real_window_recapture_desktop.png"
	post_final_window_screenshot_path = "tmp/release_first_exchange_combat_marker_scale_real_window_recapture.png"
	post_final_desktop_screenshot_full_path = $taskDesktopScreenshotPath
	post_final_window_screenshot_full_path = $taskWindowScreenshotPath
	post_final_desktop_screenshot_written = $desktopCopied
	post_final_window_screenshot_written = $windowCopied
	final_source_snapshot = if ($sourceEleganceManifest -ne $null -and $sourceEleganceManifest.PSObject.Properties.Name -contains "final_source_snapshot") { $sourceEleganceManifest.final_source_snapshot } else { [ordered]@{} }
	source_combat_focal_elegance_render_review = if ($sourceEleganceManifest -ne $null -and $sourceEleganceManifest.PSObject.Properties.Name -contains "post_final_combat_focal_elegance_render_review") { $sourceEleganceManifest.post_final_combat_focal_elegance_render_review } else { [ordered]@{} }
	post_final_combat_marker_scale_render_review = $postFinalReview
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
	source_elegance_output = @($sourceOutput)
	recommended_next_task = "TASK_903 - Release First Exchange Combat Marker Scale Visual Findings"
}

$manifest | ConvertTo-Json -Depth 16 | Set-Content -LiteralPath $taskManifestPath -Encoding UTF8

Write-Host "TASK_902 Release first-exchange combat marker-scale real-window recapture: $gate"
Write-Host "Manifest: $taskManifestPath"
Write-Host "Desktop screenshot: $taskDesktopScreenshotPath"
if ($windowCopied) {
	Write-Host "Window screenshot: $taskWindowScreenshotPath"
} else {
	Write-Host "Window screenshot missing; see TASK_899 combat focal elegance manifest."
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
