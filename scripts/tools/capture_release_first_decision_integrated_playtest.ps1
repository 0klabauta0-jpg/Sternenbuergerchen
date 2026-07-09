param(
    [string]$ProjectRoot = (Resolve-Path ".").Path,
    [string]$OutputPath = "tmp/release_first_decision_integrated_playtest.json",
    [string]$WindowScreenshotPath = "tmp/release_first_decision_integrated_playtest.png",
    [string]$DesktopScreenshotPath = "tmp/release_first_decision_integrated_playtest_desktop.png"
)

$schema = "sternenbuergerchen.release_first_decision_integrated_playtest.v1"
$launchArgument = "--release-singleplayer-lz-drop-preview"
$requiredChecks = @(
    "release_exe_launched",
    "correct_window_content_confirmed",
    "window_capture_trusted",
    "window_screenshot_written",
    "homebase_to_mission_observed",
    "dropship_lz_drop_observed",
    "first_decision_preview_observed",
    "go_executed",
    "post_go_feedback_observed",
    "no_command_before_go_confirmed",
    "performance_ok",
    "no_new_hud_gameplay_truth",
    "multiplayer_snapshot_boundary_preserved",
    "manual_playtest_done"
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
$manual_playtest_done = $false
$updates_shortcuts = $false

$manifest = [ordered]@{
    schema = $schema
    task_id = "TASK_961"
    source_task_id = "TASK_960"
    manifest_available = $true
    branch = $branch
    git_head = $gitHead
    launch_argument = $launchArgument
    selected_process_id = 0
    capture_process_id = 0
    release_exe_launched = $false
    correct_window_content_confirmed = $false
    window_capture_trusted = $false
    window_screenshot_written = $windowScreenshotWritten
    desktop_screenshot_written = $desktopScreenshotWritten
    window_screenshot_path = $WindowScreenshotPath
    desktop_screenshot_path = $DesktopScreenshotPath
    homebase_to_mission_observed = $false
    dropship_lz_drop_observed = $false
    first_decision_preview_observed = $false
    go_executed = $false
    post_go_feedback_observed = $false
    no_command_before_go_confirmed = $false
    performance_ok = $false
    no_new_hud_gameplay_truth = $false
    multiplayer_snapshot_boundary_preserved = $false
    manual_playtest_done = $manual_playtest_done
    required_checks = $requiredChecks
    updates_shortcuts = $updates_shortcuts
    read_only_capture = $true
    ui_sets_gameplay_truth = $false
    creates_command = $false
    creates_fire_event = $false
    creates_damage_event = $false
    creates_movement = $false
    sets_multiplayer_truth = $false
}

$outputDir = Split-Path $OutputPath -Parent
if ($outputDir -and -not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

$manifest | ConvertTo-Json -Depth 8 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host "Wrote $OutputPath"
