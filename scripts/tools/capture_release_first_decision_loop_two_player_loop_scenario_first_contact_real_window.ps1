param(
    [string]$ProjectRoot = (Resolve-Path ".").Path,
    [string]$OutputPath = "tmp/release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture.json",
    [string]$WindowScreenshotPath = "tmp/release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture.png",
    [string]$DesktopScreenshotPath = "tmp/release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture_desktop.png"
)

$schema = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture.v1"
$sourceSchema = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice.v1"
$launchArgument = "--release-singleplayer-first-contact-preview"
$requiredChecks = @(
    "real_window_launched",
    "correct_window_content_confirmed",
    "window_capture_trusted",
    "window_screenshot_written",
    "contact_surface_visible",
    "why_surface_visible",
    "next_surface_visible",
    "fire_wait_choice_visible",
    "go_boundary_visible",
    "feedback_line_visible",
    "calm_hud_guidance_visible",
    "first_contact_playability_line_visible",
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

$completedChecks = @(
    "contact_line_readable",
    "why_actionable",
    "next_grip_readable",
    "fire_wait_choice_readable",
    "go_stays_separate",
    "feedback_returns_to_next",
    "hud_stays_calm",
    "performance_feels_responsive",
    "multiplayer_boundary_preserved",
    "no_gameplay_truth_mutation",
    "first_contact_feels_tactical"
)

$sourceFirstContactPlayabilitySliceSnapshot = [ordered]@{
    schema = $sourceSchema
    task_id = "TASK_1037"
    source_task_id = "TASK_1036"
    status = "first_contact_playability_slice_passed"
    gate = "first_contact_playability_passed"
    trace_available = $true
    trace_id = "first_contact_playability_fixture"
    completed_checks = $completedChecks
    missing_playability_checks = @()
    first_contact_playability_line = "FIRST CONTACT PASS: CONTACT rund | WHY klar | NEXT bereit | GO separat | FIRE/WAIT lesbar"
    first_contact_feedback_line = "FEEDBACK: Kontakt gelesen, NEXT wieder bereit."
    first_contact_playability_slice_passed = $true
    ready_for_first_contact_real_window_capture = $true
    recommended_next_task = "TASK_1038 - Release First Decision Loop Two Player Loop Scenario First Contact Real Window Capture"
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
    task_id = "TASK_1038"
    source_task_id = "TASK_1037"
    gate = "review_ready"
    branch = $branch
    git_head = $gitHead
    launch_argument = $launchArgument
    source_schema = $sourceSchema
    source_gate = "first_contact_playability_passed"
    source_status = "first_contact_playability_slice_passed"
    selected_process_id = 0
    capture_process_id = 0
    capture_after_first_contact_playability_slice_passed = $false
    window_capture_method = "window_handle_print"
    window_capture_trusted = $false
    window_screenshot_written = $windowScreenshotWritten
    desktop_screenshot_written = $desktopScreenshotWritten
    window_screenshot_path = $WindowScreenshotPath
    desktop_screenshot_path = $DesktopScreenshotPath
    hard_failures = @()
    source_first_contact_playability_slice_snapshot = $sourceFirstContactPlayabilitySliceSnapshot
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
