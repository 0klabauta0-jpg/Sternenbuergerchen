param(
    [string]$ProjectRoot = (Resolve-Path ".").Path,
    [string]$OutputPath = "tmp/release_first_decision_loop_two_player_loop_outcome_real_window_capture.json",
    [string]$WindowScreenshotPath = "tmp/release_first_decision_loop_two_player_loop_outcome_real_window_capture.png",
    [string]$DesktopScreenshotPath = "tmp/release_first_decision_loop_two_player_loop_outcome_real_window_capture_desktop.png"
)

$schema = "sternenbuergerchen.release_first_decision_loop_two_player_loop_outcome_real_window_capture.v1"
$sourceSchema = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_outcome_slice.v1"
$launchArgument = "--release-singleplayer-lz-drop-preview"
$requiredChecks = @(
    "real_window_launched",
    "correct_window_content_confirmed",
    "window_capture_trusted",
    "window_screenshot_written",
    "outcome_line_visible",
    "mini_objective_state_visible",
    "next_step_line_visible",
    "player_result_readable",
    "no_new_hud_gameplay_truth",
    "multiplayer_boundary_preserved",
    "manual_visual_review_done"
)

Push-Location $ProjectRoot
try {
    $branch = (git rev-parse --abbrev-ref HEAD 2>$null)
    $gitHead = (git rev-parse --short HEAD 2>$null)
}
finally {
    Pop-Location
}

$windowScreenshotWritten = Test-Path $WindowScreenshotPath
$desktopScreenshotWritten = Test-Path $DesktopScreenshotPath
$manual_review_done = $false
$updates_shortcuts = $false

$sourceScenarioOutcomeSnapshot = [ordered]@{
    schema = $sourceSchema
    task_id = "TASK_985"
    source_task_id = "TASK_984"
    status = "player_loop_scenario_outcome_ready"
    gate = "player_loop_scenario_outcome_ready"
    scenario_outcome_ready = $true
    selected_choice_id = "push_objective"
    selected_choice_label = "PUSH"
    outcome_line = "PUSH: Ziel unter Druck, naechster Abschnitt offen."
    result_tag = "objective_pressure"
    mini_objective_state = "Ziel 1/2 unter Druck"
    next_step_line = "Naechster Griff: sichern oder weiter druecken."
    recommended_next_task = "TASK_986 - Release First Decision Loop Two Player Loop Outcome Real Window Capture"
    read_only = $true
    ui_sets_gameplay_truth = $false
    creates_navigation = $false
    creates_command = $false
    creates_fire_event = $false
    creates_damage_event = $false
    creates_movement = $false
    sets_multiplayer_truth = $false
    updates_shortcuts = $updates_shortcuts
}

$manifest = [ordered]@{
    schema = $schema
    task_id = "TASK_986"
    source_task_id = "TASK_985"
    gate = "review_ready"
    branch = $branch
    git_head = $gitHead
    launch_argument = $launchArgument
    source_schema = $sourceSchema
    source_gate = "player_loop_scenario_outcome_ready"
    source_status = "player_loop_scenario_outcome_ready"
    selected_process_id = 0
    capture_process_id = 0
    capture_after_scenario_outcome_ready = $false
    window_capture_method = "window_handle_print"
    window_capture_trusted = $false
    window_screenshot_written = $windowScreenshotWritten
    desktop_screenshot_written = $desktopScreenshotWritten
    window_screenshot_path = $WindowScreenshotPath
    desktop_screenshot_path = $DesktopScreenshotPath
    hard_failures = @()
    source_scenario_outcome_snapshot = $sourceScenarioOutcomeSnapshot
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
    updates_shortcuts = $updates_shortcuts
}

$outputDir = Split-Path $OutputPath -Parent
if ($outputDir -and -not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

$manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host "Wrote $OutputPath"
