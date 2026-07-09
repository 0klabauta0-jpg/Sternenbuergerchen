param(
    [string]$ProjectRoot = (Resolve-Path ".").Path,
    [string]$OutputPath = "tmp/release_first_decision_loop_two_real_window_capture.json",
    [string]$WindowScreenshotPath = "tmp/release_first_decision_loop_two_real_window_capture.png",
    [string]$DesktopScreenshotPath = "tmp/release_first_decision_loop_two_real_window_capture_desktop.png"
)

$schema = "sternenbuergerchen.release_first_decision_loop_two_real_window_capture.v1"
$sourceSchema = "sternenbuergerchen.release_first_decision_loop_two_runtime_button.v1"
$launchArgument = "--release-singleplayer-lz-drop-preview"
$requiredChecks = @(
    "real_window_launched",
    "correct_window_content_confirmed",
    "window_capture_trusted",
    "window_screenshot_written",
    "second_decision_button_visible",
    "second_decision_button_readable",
    "second_decision_confirm_observed",
    "go_button_still_separate",
    "post_confirm_feedback_visible",
    "no_go_before_go_confirmed",
    "no_new_hud_gameplay_truth",
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

$sourceRuntimeButtonSnapshot = [ordered]@{
    schema = $sourceSchema
    task_id = "TASK_968"
    source_task_id = "TASK_967"
    gate = "runtime_button_ready"
    status = "ready_for_real_window_capture"
    active = $true
    selected_choice_id = "hold_angle"
    selected_command_type = "defend"
    button_text = "2ND"
    button_role = "second_decision_confirm"
    button_slot_path = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/CommandSlot07"
    button_enabled = $true
    press_action = "confirm_release_first_decision_loop_two_runtime_button"
    confirm_action = "_issue_command"
    execute_action = "execute_selected_fireteam_orders"
    separate_go_required = $true
    auto_executes_go = $false
    runtime_line = "2ND HOLD Defend | bereit | GO bleibt separat"
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
    task_id = "TASK_969"
    source_task_id = "TASK_968"
    gate = "review_ready"
    branch = $branch
    git_head = $gitHead
    launch_argument = $launchArgument
    source_schema = $sourceSchema
    source_gate = "runtime_button_ready"
    source_status = "ready_for_real_window_capture"
    selected_process_id = 0
    capture_process_id = 0
    capture_after_runtime_button_ready = $false
    window_capture_method = "window_handle_print"
    window_capture_trusted = $false
    window_screenshot_written = $windowScreenshotWritten
    desktop_screenshot_written = $desktopScreenshotWritten
    window_screenshot_path = $WindowScreenshotPath
    desktop_screenshot_path = $DesktopScreenshotPath
    hard_failures = @()
    source_runtime_button_snapshot = $sourceRuntimeButtonSnapshot
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
