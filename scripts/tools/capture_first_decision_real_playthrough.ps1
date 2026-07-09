param(
	[string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path,
	[string]$OutputPath = "tmp/first_decision_real_playthrough_capture.json",
	[string]$WindowScreenshotPath = "tmp/first_decision_real_playthrough_capture.png",
	[string]$DesktopScreenshotPath = "tmp/first_decision_real_playthrough_capture_desktop.png"
)

$ErrorActionPreference = "Stop"

$schema = "sternenbuergerchen.first_decision_real_playthrough_capture.v1"
$sourceSchema = "sternenbuergerchen.first_decision_micro_scenario_polish.v1"
$launchArgument = "--release-singleplayer-lz-drop-preview"

$requiredChecks = @(
	"first_decision_next_line_visible",
	"why_line_visible",
	"choice_rows_visible",
	"preview_boundary_visible",
	"go_button_or_command_surface_usable",
	"no_command_before_go",
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

# This tool records the repeatable real-window playthrough-capture contract.
# It does not mark the manual sight review as done and does not mutate gameplay state.
$selectedProcessId = 0
$captureProcessId = 0
$windowScreenshotWritten = Test-Path (Join-Path $ProjectRoot $WindowScreenshotPath)
$desktopScreenshotWritten = Test-Path (Join-Path $ProjectRoot $DesktopScreenshotPath)
$manual_review_done = $false

$manifest = [ordered]@{
	schema = $schema
	task_id = "TASK_957"
	source_task_id = "TASK_956"
	gate = "review_ready"
	branch = $branch
	git_head = $gitHead
	launch_argument = $launchArgument
	source_schema = $sourceSchema
	source_gate = "pass"
	source_status = "ready_for_first_decision_micro_scenario"
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
	source_micro_scenario_snapshot = [ordered]@{
		schema = $sourceSchema
		task_id = "TASK_956"
		source_task_id = "TASK_955"
		gate = "pass"
		status = "ready_for_first_decision_micro_scenario"
		primary_cue_line = "NEXT Gedeckt pruefen -> GO"
		why_line = "WHY Deckung ok, 0 Feindlinie"
		choice_row_count = 3
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
