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
$sourceRecaptureScript = Join-Path $script:repoRoot "scripts\tools\capture_release_first_exchange_fire_lane_world_read_acceptance_recapture.ps1"
$sourceRecaptureManifestPath = Join-Path $OutputDirectory "release_first_exchange_fire_lane_world_read_acceptance_recapture.json"
$taskManifestPath = Join-Path $OutputDirectory "release_first_exchange_final_world_read_recapture.json"
$taskDesktopScreenshotPath = Join-Path $OutputDirectory "release_first_exchange_final_world_read_recapture_desktop.png"
$taskWindowScreenshotPath = Join-Path $OutputDirectory "release_first_exchange_final_world_read_recapture.png"

if (-not (Test-Path -LiteralPath $sourceRecaptureScript -PathType Leaf)) {
	throw "Missing TASK_914 acceptance recapture script: $sourceRecaptureScript"
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

$sourceDesktopPath = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "post_final_desktop_screenshot_full_path") { [string]$sourceRecaptureManifest.post_final_desktop_screenshot_full_path } else { "" }
$sourceWindowPath = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "post_final_window_screenshot_full_path") { [string]$sourceRecaptureManifest.post_final_window_screenshot_full_path } else { "" }
$desktopCopied = Copy-IfExists -SourcePath $sourceDesktopPath -DestinationPath $taskDesktopScreenshotPath
$windowCopied = Copy-IfExists -SourcePath $sourceWindowPath -DestinationPath $taskWindowScreenshotPath

$hardFailures = @()
$warnings = @()
if ($sourceExitCode -ne 0) {
	$hardFailures += "source_acceptance_recapture_failed:$sourceExitCode"
}
if ($sourceRecaptureManifest -eq $null) {
	$hardFailures += "source_acceptance_recapture_manifest_missing"
}
if (-not $desktopCopied) {
	$warnings += "post_final_desktop_screenshot_copy_missing"
}
if (-not $windowCopied) {
	$warnings += "post_final_window_screenshot_copy_missing"
}

$selectedProcessId = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "selected_process_id") { [int]$sourceRecaptureManifest.selected_process_id } else { 0 }
$postFinalProcessId = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "post_final_capture_process_id") { [int]$sourceRecaptureManifest.post_final_capture_process_id } else { 0 }
$postFinalCaptureTrusted = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "post_final_window_capture_trusted") { [bool]$sourceRecaptureManifest.post_final_window_capture_trusted } else { $false }
$postFinalCaptureMethod = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "post_final_window_capture_method") { [string]$sourceRecaptureManifest.post_final_window_capture_method } else { "" }

$requiredChecks = @(
	"contact_fire_visible_in_selected_fireteam",
	"contact_fire_visible_in_mission_control",
	"event_log_contact_fire_visible_without_blocking",
	"final_fire_lane_is_first_world_movement",
	"final_source_target_anchors_carry_direction",
	"final_world_fire_label_stays_behind_lane",
	"final_target_halo_stays_behind_lane",
	"final_grid_world_noise_not_competing",
	"command_surfaces_still_usable",
	"no_new_hud_gameplay_truth"
)

$postFinalReview = [ordered]@{
	frame_trace_method = "post_deeplink_final_window_handle_screenshot_final_world_read_review_required"
	rendered_texts_collected = $false
	screenshot_observed_state = "TASK_917_REVIEW_REQUIRED"
	expected_contact_fire_first = $true
	expected_final_schema = "sternenbuergerchen.release_first_exchange_fire_lane_world_read_final_polish.v1"
	expected_final_style_id = "task_916_release_first_exchange_fire_lane_world_read_final_v1"
	expected_acceptance_schema = "sternenbuergerchen.release_first_exchange_fire_lane_world_read_acceptance_polish.v1"
	expected_acceptance_style_id = "task_913_release_first_exchange_fire_lane_world_read_acceptance_v1"
	expected_fire_lane_is_first_world_movement = $true
	expected_source_target_anchors_carry_direction = $true
	expected_world_fire_label_stays_behind_lane = $true
	expected_target_halo_stays_behind_lane = $true
	manual_readback_source = "TASK_917 screenshot: tmp/release_first_exchange_final_world_read_recapture.png"
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
	schema = "sternenbuergerchen.release_first_exchange_final_world_read_recapture.v1"
	task_id = "TASK_917"
	source_task_id = "TASK_916"
	source_recapture_task_id = "TASK_914"
	source_findings_task_id = "TASK_915"
	source_acceptance_task_id = "TASK_913"
	gate = $gate
	repo_root = $script:repoRoot
	branch = Get-GitValue -Arguments @("branch", "--show-current")
	git_head = Get-GitValue -Arguments @("rev-parse", "--short", "HEAD")
	launch_argument = $launchArgument
	wait_seconds = $WaitSeconds
	expected_final_schema = "sternenbuergerchen.release_first_exchange_fire_lane_world_read_final_polish.v1"
	expected_final_style_id = "task_916_release_first_exchange_fire_lane_world_read_final_v1"
	expected_acceptance_schema = "sternenbuergerchen.release_first_exchange_fire_lane_world_read_acceptance_polish.v1"
	expected_acceptance_style_id = "task_913_release_first_exchange_fire_lane_world_read_acceptance_v1"
	source_recapture_manifest_path = "tmp/release_first_exchange_fire_lane_world_read_acceptance_recapture.json"
	source_recapture_manifest_full_path = $sourceRecaptureManifestPath
	source_recapture_schema = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "schema") { [string]$sourceRecaptureManifest.schema } else { "" }
	source_recapture_gate = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "gate") { [string]$sourceRecaptureManifest.gate } else { "" }
	selected_process_id = $selectedProcessId
	post_final_capture_process_id = $postFinalProcessId
	post_final_capture_after_deeplink_final = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "post_final_capture_after_deeplink_final") { [bool]$sourceRecaptureManifest.post_final_capture_after_deeplink_final } else { $false }
	post_final_window_capture_method = $postFinalCaptureMethod
	post_final_window_capture_trusted = $postFinalCaptureTrusted
	post_final_window_handle_capture_succeeded = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "post_final_window_handle_capture_succeeded") { [bool]$sourceRecaptureManifest.post_final_window_handle_capture_succeeded } else { $false }
	post_final_desktop_screenshot_path = "tmp/release_first_exchange_final_world_read_recapture_desktop.png"
	post_final_window_screenshot_path = "tmp/release_first_exchange_final_world_read_recapture.png"
	post_final_desktop_screenshot_full_path = $taskDesktopScreenshotPath
	post_final_window_screenshot_full_path = $taskWindowScreenshotPath
	post_final_desktop_screenshot_written = $desktopCopied
	post_final_window_screenshot_written = $windowCopied
	final_source_snapshot = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "final_source_snapshot") { $sourceRecaptureManifest.final_source_snapshot } else { [ordered]@{} }
	source_acceptance_render_review = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "post_final_fire_lane_world_read_acceptance_render_review") { $sourceRecaptureManifest.post_final_fire_lane_world_read_acceptance_render_review } else { [ordered]@{} }
	post_final_fire_lane_world_read_final_render_review = $postFinalReview
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
	source_recapture_output = @($sourceOutput)
	recommended_next_task = "TASK_918 - Release First Exchange Final World Read Visual Findings"
}

$manifest | ConvertTo-Json -Depth 16 | Set-Content -LiteralPath $taskManifestPath -Encoding UTF8

Write-Host "TASK_917 Release first-exchange final world-read recapture: $gate"
Write-Host "Manifest: $taskManifestPath"
Write-Host "Desktop screenshot: $taskDesktopScreenshotPath"
if ($windowCopied) {
	Write-Host "Window screenshot: $taskWindowScreenshotPath"
} else {
	Write-Host "Window screenshot missing; see TASK_914 acceptance manifest."
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
