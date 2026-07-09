param(
	[string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path,
	[string]$OutputPath = "tmp/decision_overlay_real_window_recapture.json",
	[string]$WindowScreenshotPath = "tmp/decision_overlay_real_window_recapture.png",
	[string]$DesktopScreenshotPath = "tmp/decision_overlay_real_window_recapture_desktop.png"
)

$ErrorActionPreference = "Stop"

$schema = "sternenbuergerchen.decision_overlay_real_window_recapture.v1"
$sourceSchema = "sternenbuergerchen.decision_overlay_f6_visual_polish.v1"
$sourceStyleId = "task_952_decision_overlay_compact_badges_v1"
$launchArgument = "--release-singleplayer-first-go-firefight"

$requiredChecks = @(
	"decision_overlay_badges_visible",
	"safe_risky_suicidal_order_visible",
	"badge_colors_do_not_fight_fire_lane",
	"mission_control_line_still_readable",
	"command_surfaces_still_usable",
	"manual_visual_review_done",
	"no_new_hud_gameplay_truth"
)

$gitHead = ""
try {
	$gitHead = (git -C $ProjectRoot rev-parse --short HEAD).Trim()
} catch {
	$gitHead = "unknown"
}

$branch = ""
try {
	$branch = (git -C $ProjectRoot branch --show-current).Trim()
} catch {
	$branch = "unknown"
}

# This task records the repeatable real-window capture contract. It does not
# mark the manual sight review as done and does not mutate gameplay state.
$selectedProcessId = 0
$captureProcessId = 0
$windowScreenshotWritten = Test-Path (Join-Path $ProjectRoot $WindowScreenshotPath)
$desktopScreenshotWritten = Test-Path (Join-Path $ProjectRoot $DesktopScreenshotPath)
$manual_review_done = $false

$manifest = [ordered]@{
	schema = $schema
	task_id = "TASK_953"
	source_task_id = "TASK_952"
	gate = "review_ready"
	branch = $branch
	git_head = $gitHead
	launch_argument = $launchArgument
	source_schema = $sourceSchema
	source_style_id = $sourceStyleId
	source_gate = "pass"
	selected_process_id = $selectedProcessId
	capture_process_id = $captureProcessId
	capture_after_deeplink_final = $false
	window_capture_method = "window_handle_print"
	window_capture_trusted = $false
	window_screenshot_written = $windowScreenshotWritten
	desktop_screenshot_written = $desktopScreenshotWritten
	window_screenshot_path = $WindowScreenshotPath
	desktop_screenshot_path = $DesktopScreenshotPath
	hard_failures = @()
	source_polish_snapshot = [ordered]@{
		schema = $sourceSchema
		task_id = "TASK_952"
		style_id = $sourceStyleId
		gate = "pass"
		visual_badge_count = 3
		read_only = $true
		ui_sets_gameplay_truth = $false
		creates_command = $false
		creates_movement = $false
		sets_multiplayer_truth = $false
	}
	manual_review_required = $true
	manual_review_done = $manual_review_done
	required_checks = $requiredChecks
	completed_manual_checks = @()
	read_only = $true
	read_only_capture = $true
	ui_sets_gameplay_truth = $false
	creates_navigation = $false
	creates_command = $false
	creates_fire_event = $false
	creates_damage_event = $false
	creates_movement = $false
	sets_multiplayer_truth = $false
	updates_shortcuts = $false
}

$fullOutputPath = Join-Path $ProjectRoot $OutputPath
$outputDir = Split-Path -Parent $fullOutputPath
if (-not (Test-Path $outputDir)) {
	New-Item -ItemType Directory -Path $outputDir | Out-Null
}

$manifest | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $fullOutputPath -Encoding UTF8
Write-Host "Wrote $OutputPath"
