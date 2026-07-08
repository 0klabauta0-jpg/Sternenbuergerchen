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
$sourceDirectionScript = Join-Path $script:repoRoot "scripts\tools\capture_release_first_exchange_fire_direction_impact_real_window_recapture.ps1"
$sourceDirectionManifestPath = Join-Path $OutputDirectory "release_first_exchange_fire_direction_impact_real_window_recapture.json"
$taskManifestPath = Join-Path $OutputDirectory "release_first_exchange_world_combat_focal_real_window_recapture.json"
$taskDesktopScreenshotPath = Join-Path $OutputDirectory "release_first_exchange_world_combat_focal_real_window_recapture_desktop.png"
$taskWindowScreenshotPath = Join-Path $OutputDirectory "release_first_exchange_world_combat_focal_real_window_recapture.png"

if (-not (Test-Path -LiteralPath $sourceDirectionScript -PathType Leaf)) {
	throw "Missing TASK_893 fire-direction/impact capture script: $sourceDirectionScript"
}

$sourceArgs = @("-ExecutionPolicy", "Bypass", "-File", $sourceDirectionScript, "-OutputDirectory", $OutputDirectory, "-WaitSeconds", [string]$WaitSeconds)
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
$sourceDirectionManifest = Read-JsonFile -Path $sourceDirectionManifestPath

$sourceDesktopPath = if ($sourceDirectionManifest -ne $null -and $sourceDirectionManifest.PSObject.Properties.Name -contains "post_final_desktop_screenshot_full_path") { [string]$sourceDirectionManifest.post_final_desktop_screenshot_full_path } else { "" }
$sourceWindowPath = if ($sourceDirectionManifest -ne $null -and $sourceDirectionManifest.PSObject.Properties.Name -contains "post_final_window_screenshot_full_path") { [string]$sourceDirectionManifest.post_final_window_screenshot_full_path } else { "" }
$desktopCopied = Copy-IfExists -SourcePath $sourceDesktopPath -DestinationPath $taskDesktopScreenshotPath
$windowCopied = Copy-IfExists -SourcePath $sourceWindowPath -DestinationPath $taskWindowScreenshotPath

$hardFailures = @()
$warnings = @()
if ($sourceExitCode -ne 0) {
	$hardFailures += "source_direction_impact_capture_failed:$sourceExitCode"
}
if ($sourceDirectionManifest -eq $null) {
	$hardFailures += "source_direction_impact_manifest_missing"
}
if (-not $desktopCopied) {
	$warnings += "post_final_desktop_screenshot_copy_missing"
}
if (-not $windowCopied) {
	$warnings += "post_final_window_screenshot_copy_missing"
}

$selectedProcessId = if ($sourceDirectionManifest -ne $null -and $sourceDirectionManifest.PSObject.Properties.Name -contains "selected_process_id") { [int]$sourceDirectionManifest.selected_process_id } else { 0 }
$postFinalProcessId = if ($sourceDirectionManifest -ne $null -and $sourceDirectionManifest.PSObject.Properties.Name -contains "post_final_capture_process_id") { [int]$sourceDirectionManifest.post_final_capture_process_id } else { 0 }
$postFinalCaptureTrusted = if ($sourceDirectionManifest -ne $null -and $sourceDirectionManifest.PSObject.Properties.Name -contains "post_final_window_capture_trusted") { [bool]$sourceDirectionManifest.post_final_window_capture_trusted } else { $false }
$postFinalCaptureMethod = if ($sourceDirectionManifest -ne $null -and $sourceDirectionManifest.PSObject.Properties.Name -contains "post_final_window_capture_method") { [string]$sourceDirectionManifest.post_final_window_capture_method } else { "" }

$requiredChecks = @(
	"contact_fire_visible_in_selected_fireteam",
	"contact_fire_visible_in_mission_control",
	"event_log_contact_fire_visible_without_blocking",
	"world_combat_focal_lane_obvious",
	"source_glow_visible",
	"target_halo_visible",
	"grid_or_world_noise_not_competing",
	"source_to_target_relationship_obvious",
	"no_stale_no_fire_or_contact_pressure_first_read",
	"no_new_hud_gameplay_truth"
)

$postFinalReview = [ordered]@{
	frame_trace_method = "post_deeplink_final_window_handle_screenshot_world_combat_focal_review_required"
	rendered_texts_collected = $false
	screenshot_observed_state = "TASK_896_REVIEW_REQUIRED"
	expected_contact_fire_first = $true
	expected_world_combat_focal_lane = $true
	expected_source_glow_target_halo = $true
	expected_world_noise_dimming = $true
	manual_readback_source = "TASK_896 screenshot: tmp/release_first_exchange_world_combat_focal_real_window_recapture.png"
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
	schema = "sternenbuergerchen.release_first_exchange_world_combat_focal_real_window_recapture.v1"
	task_id = "TASK_896"
	source_task_id = "TASK_895"
	source_direction_task_id = "TASK_892"
	source_findings_task_id = "TASK_894"
	source_direction_recapture_task_id = "TASK_893"
	gate = $gate
	repo_root = $script:repoRoot
	branch = Get-GitValue -Arguments @("branch", "--show-current")
	git_head = Get-GitValue -Arguments @("rev-parse", "--short", "HEAD")
	launch_argument = $launchArgument
	wait_seconds = $WaitSeconds
	expected_focal_schema = "sternenbuergerchen.release_first_exchange_world_combat_focal_hierarchy_polish.v1"
	expected_focal_style_id = "task_895_release_first_exchange_world_combat_focal_hierarchy_v1"
	expected_direction_style_id = "task_892_release_first_exchange_fire_direction_impact_clarity_v1"
	source_direction_recapture_manifest_path = "tmp/release_first_exchange_fire_direction_impact_real_window_recapture.json"
	source_direction_recapture_manifest_full_path = $sourceDirectionManifestPath
	source_direction_recapture_schema = if ($sourceDirectionManifest -ne $null -and $sourceDirectionManifest.PSObject.Properties.Name -contains "schema") { [string]$sourceDirectionManifest.schema } else { "" }
	source_direction_recapture_gate = if ($sourceDirectionManifest -ne $null -and $sourceDirectionManifest.PSObject.Properties.Name -contains "gate") { [string]$sourceDirectionManifest.gate } else { "" }
	selected_process_id = $selectedProcessId
	post_final_capture_process_id = $postFinalProcessId
	post_final_capture_after_deeplink_final = if ($sourceDirectionManifest -ne $null -and $sourceDirectionManifest.PSObject.Properties.Name -contains "post_final_capture_after_deeplink_final") { [bool]$sourceDirectionManifest.post_final_capture_after_deeplink_final } else { $false }
	post_final_window_capture_method = $postFinalCaptureMethod
	post_final_window_capture_trusted = $postFinalCaptureTrusted
	post_final_window_handle_capture_succeeded = if ($sourceDirectionManifest -ne $null -and $sourceDirectionManifest.PSObject.Properties.Name -contains "post_final_window_handle_capture_succeeded") { [bool]$sourceDirectionManifest.post_final_window_handle_capture_succeeded } else { $false }
	post_final_desktop_screenshot_path = "tmp/release_first_exchange_world_combat_focal_real_window_recapture_desktop.png"
	post_final_window_screenshot_path = "tmp/release_first_exchange_world_combat_focal_real_window_recapture.png"
	post_final_desktop_screenshot_full_path = $taskDesktopScreenshotPath
	post_final_window_screenshot_full_path = $taskWindowScreenshotPath
	post_final_desktop_screenshot_written = $desktopCopied
	post_final_window_screenshot_written = $windowCopied
	final_source_snapshot = if ($sourceDirectionManifest -ne $null -and $sourceDirectionManifest.PSObject.Properties.Name -contains "final_source_snapshot") { $sourceDirectionManifest.final_source_snapshot } else { [ordered]@{} }
	source_direction_render_review = if ($sourceDirectionManifest -ne $null -and $sourceDirectionManifest.PSObject.Properties.Name -contains "post_final_fire_direction_impact_render_review") { $sourceDirectionManifest.post_final_fire_direction_impact_render_review } else { [ordered]@{} }
	post_final_world_combat_focal_render_review = $postFinalReview
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
	source_direction_output = @($sourceOutput)
	recommended_next_task = "TASK_897 - Release First Exchange World Combat Focal Visual Findings"
}

$manifest | ConvertTo-Json -Depth 16 | Set-Content -LiteralPath $taskManifestPath -Encoding UTF8

Write-Host "TASK_896 Release first-exchange world-combat focal real-window recapture: $gate"
Write-Host "Manifest: $taskManifestPath"
Write-Host "Desktop screenshot: $taskDesktopScreenshotPath"
if ($windowCopied) {
	Write-Host "Window screenshot: $taskWindowScreenshotPath"
} else {
	Write-Host "Window screenshot missing; see TASK_893 direction/impact manifest."
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
