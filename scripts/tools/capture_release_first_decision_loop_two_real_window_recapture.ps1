param(
    [string]$ProjectRoot = (Resolve-Path ".").Path,
    [string]$OutputPath = "tmp/release_first_decision_loop_two_real_window_recapture.json",
    [string]$WindowScreenshotPath = "tmp/release_first_decision_loop_two_real_window_recapture.png",
    [string]$DesktopScreenshotPath = "tmp/release_first_decision_loop_two_real_window_recapture_desktop.png"
)

$schema = "sternenbuergerchen.release_first_decision_loop_two_real_window_recapture.v1"
$sourceSchema = "sternenbuergerchen.release_first_decision_loop_two_playability_smoke.v1"
$launchArgument = "--release-singleplayer-lz-drop-preview"
$requiredChecks = @(
    "real_window_launched",
    "correct_window_content_confirmed",
    "window_capture_trusted",
    "window_screenshot_written",
    "second_decision_button_visible",
    "second_decision_confirmed",
    "go_button_still_separate",
    "go_executed_after_confirm",
    "post_go_feedback_visible",
    "loop_two_smoke_line_visible",
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

$completedSmokeChecks = @(
    "second_decision_button_visible",
    "second_decision_confirmed",
    "go_button_still_separate",
    "go_executed_after_confirm",
    "post_go_feedback_visible",
    "no_go_before_second_confirm",
    "no_new_hud_gameplay_truth",
    "multiplayer_boundary_preserved"
)

$sourcePlayabilitySmokeSnapshot = [ordered]@{
    schema = $sourceSchema
    task_id = "TASK_972"
    source_task_id = "TASK_971"
    status = "loop_two_playability_smoke_passed"
    gate = "loop_two_playability_smoke_passed"
    trace_available = $true
    completed_checks = $completedSmokeChecks
    missing_smoke_checks = @()
    playability_smoke_passed = $true
    source_button_text = "2ND"
    smoke_line = "2ND -> GO -> Feedback PASS | 2ND HOLD -> Defend vorbereiten | danach GO separat"
    post_go_feedback_line = "Feedback: zweiter Griff vorbereitet, GO ausgefuehrt."
    recommended_next_task = "TASK_973 - Release First Decision Loop Two Real Window Recapture"
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
    task_id = "TASK_973"
    source_task_id = "TASK_972"
    gate = "review_ready"
    branch = $branch
    git_head = $gitHead
    launch_argument = $launchArgument
    source_schema = $sourceSchema
    source_gate = "loop_two_playability_smoke_passed"
    source_status = "loop_two_playability_smoke_passed"
    selected_process_id = 0
    capture_process_id = 0
    capture_after_playability_smoke_passed = $false
    window_capture_method = "window_handle_print"
    window_capture_trusted = $false
    window_screenshot_written = $windowScreenshotWritten
    desktop_screenshot_written = $desktopScreenshotWritten
    window_screenshot_path = $WindowScreenshotPath
    desktop_screenshot_path = $DesktopScreenshotPath
    hard_failures = @()
    source_playability_smoke_snapshot = $sourcePlayabilitySmokeSnapshot
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
