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
$sourceRecaptureScript = Join-Path $script:repoRoot "scripts\tools\capture_release_first_exchange_followup_fix_player_polish_final_tuning_followup_recapture.ps1"
$sourceRecaptureManifestPath = Join-Path $OutputDirectory "release_first_exchange_followup_fix_player_polish_final_tuning_followup_recapture.json"
$taskManifestPath = Join-Path $OutputDirectory "release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture.json"
$taskDesktopScreenshotPath = Join-Path $OutputDirectory "release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture_desktop.png"
$taskWindowScreenshotPath = Join-Path $OutputDirectory "release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture.png"

if (-not (Test-Path -LiteralPath $sourceRecaptureScript -PathType Leaf)) {
	throw "Missing TASK_943 followup recapture script: $sourceRecaptureScript"
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

$sourceDesktopPath = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "followup_desktop_screenshot_full_path") { [string]$sourceRecaptureManifest.followup_desktop_screenshot_full_path } else { "" }
$sourceWindowPath = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "followup_window_screenshot_full_path") { [string]$sourceRecaptureManifest.followup_window_screenshot_full_path } else { "" }
$desktopCopied = Copy-IfExists -SourcePath $sourceDesktopPath -DestinationPath $taskDesktopScreenshotPath
$windowCopied = Copy-IfExists -SourcePath $sourceWindowPath -DestinationPath $taskWindowScreenshotPath

$hardFailures = @()
$warnings = @()
if ($sourceExitCode -ne 0) {
	$hardFailures += "source_followup_recapture_failed:$sourceExitCode"
}
if ($sourceRecaptureManifest -eq $null) {
	$hardFailures += "source_followup_recapture_manifest_missing"
}
if (-not $desktopCopied) {
	$warnings += "second_desktop_screenshot_copy_missing"
}
if (-not $windowCopied) {
	$warnings += "second_window_screenshot_copy_missing"
}

$selectedProcessId = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "selected_process_id") { [int]$sourceRecaptureManifest.selected_process_id } else { 0 }
$sourceProcessId = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "followup_capture_process_id") { [int]$sourceRecaptureManifest.followup_capture_process_id } else { 0 }
$sourceCaptureTrusted = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "followup_window_capture_trusted") { [bool]$sourceRecaptureManifest.followup_window_capture_trusted } else { $false }
$sourceCaptureMethod = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "followup_window_capture_method") { [string]$sourceRecaptureManifest.followup_window_capture_method } else { "" }

$requiredChecks = @(
	"contact_fire_visible_in_selected_fireteam",
	"contact_fire_visible_in_mission_control",
	"event_log_contact_fire_visible_without_blocking",
	"second_fire_lane_is_first_world_movement",
	"second_source_target_anchors_carry_direction",
	"second_anchors_do_not_read_as_discs",
	"second_world_fire_label_stays_behind_lane",
	"second_target_halo_stays_behind_lane",
	"second_grid_world_noise_not_competing",
	"second_lane_reads_before_fire_contact_text",
	"command_surfaces_still_usable",
	"no_new_hud_gameplay_truth"
)

$secondReview = [ordered]@{
	frame_trace_method = "post_deeplink_final_window_handle_screenshot_second_review_required"
	rendered_texts_collected = $false
	screenshot_observed_state = "TASK_946_REVIEW_REQUIRED"
	expected_contact_fire_first = $true
	expected_second_fix_schema = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_fix.v1"
	expected_second_fix_style_id = "task_945_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_fix_v1"
	expected_findings_schema = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_visual_findings.v1"
	expected_followup_fix_schema = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix.v1"
	expected_followup_fix_style_id = "task_942_release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix_v1"
	expected_fire_lane_is_first_world_movement = $true
	expected_source_target_anchors_carry_direction = $true
	expected_anchors_do_not_read_as_discs = $true
	expected_world_fire_label_stays_behind_lane = $true
	expected_target_halo_stays_behind_lane = $true
	expected_fire_lane_reads_before_fire_contact_text = $true
	manual_readback_source = "TASK_946 screenshot: tmp/release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture.png"
}

$gate = "review_ready"
if ($hardFailures.Count -gt 0) {
	$gate = "fail"
} elseif (-not $windowCopied -or -not $sourceCaptureTrusted) {
	$gate = "manual_open"
} elseif ($warnings.Count -gt 0) {
	$gate = "review"
}

$manifest = [ordered]@{
	schema = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture.v1"
	task_id = "TASK_946"
	source_task_id = "TASK_945"
	source_findings_task_id = "TASK_944"
	source_followup_fix_task_id = "TASK_942"
	source_recapture_task_id = "TASK_943"
	gate = $gate
	repo_root = $script:repoRoot
	branch = Get-GitValue -Arguments @("branch", "--show-current")
	git_head = Get-GitValue -Arguments @("rev-parse", "--short", "HEAD")
	launch_argument = $launchArgument
	wait_seconds = $WaitSeconds
	expected_second_fix_schema = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_fix.v1"
	expected_second_fix_style_id = "task_945_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_fix_v1"
	expected_findings_schema = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_visual_findings.v1"
	expected_followup_fix_schema = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix.v1"
	expected_followup_fix_style_id = "task_942_release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix_v1"
	source_recapture_manifest_path = "tmp/release_first_exchange_followup_fix_player_polish_final_tuning_followup_recapture.json"
	source_recapture_manifest_full_path = $sourceRecaptureManifestPath
	source_recapture_schema = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "schema") { [string]$sourceRecaptureManifest.schema } else { "" }
	source_recapture_gate = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "gate") { [string]$sourceRecaptureManifest.gate } else { "" }
	selected_process_id = $selectedProcessId
	second_capture_process_id = $sourceProcessId
	second_capture_after_deeplink_final = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "followup_capture_after_deeplink_final") { [bool]$sourceRecaptureManifest.followup_capture_after_deeplink_final } else { $false }
	second_window_capture_method = $sourceCaptureMethod
	second_window_capture_trusted = $sourceCaptureTrusted
	second_window_handle_capture_succeeded = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "followup_window_handle_capture_succeeded") { [bool]$sourceRecaptureManifest.followup_window_handle_capture_succeeded } else { $false }
	second_desktop_screenshot_path = "tmp/release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture_desktop.png"
	second_window_screenshot_path = "tmp/release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture.png"
	second_desktop_screenshot_full_path = $taskDesktopScreenshotPath
	second_window_screenshot_full_path = $taskWindowScreenshotPath
	second_desktop_screenshot_written = $desktopCopied
	second_window_screenshot_written = $windowCopied
	final_source_snapshot = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "final_source_snapshot") { $sourceRecaptureManifest.final_source_snapshot } else { [ordered]@{} }
	source_second_fix_snapshot = [ordered]@{
		schema = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_fix.v1"
		task_id = "TASK_945"
		style_id = "task_945_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_fix_v1"
		source_findings_task_id = "TASK_944"
		source_followup_fix_task_id = "TASK_942"
	}
	source_findings_snapshot = [ordered]@{
		schema = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_visual_findings.v1"
		task_id = "TASK_944"
		status = "ready_for_followup_fix_player_polish_final_tuning_followup_second_fix"
	}
	source_followup_fix_snapshot = [ordered]@{
		schema = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix.v1"
		task_id = "TASK_942"
		style_id = "task_942_release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix_v1"
	}
	source_recapture_review = if ($sourceRecaptureManifest -ne $null -and $sourceRecaptureManifest.PSObject.Properties.Name -contains "followup_world_read_render_review") { $sourceRecaptureManifest.followup_world_read_render_review } else { [ordered]@{} }
	second_world_read_render_review = $secondReview
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
	recommended_next_task = "TASK_947 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Second Visual Findings"
}

$manifest | ConvertTo-Json -Depth 16 | Set-Content -LiteralPath $taskManifestPath -Encoding UTF8

Write-Host "TASK_946 Release first-exchange second recapture: $gate"
Write-Host "Manifest: $taskManifestPath"
Write-Host "Desktop screenshot: $taskDesktopScreenshotPath"
if ($windowCopied) {
	Write-Host "Window screenshot: $taskWindowScreenshotPath"
} else {
	Write-Host "Window screenshot missing; see TASK_943 followup recapture manifest."
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
