param(
    [switch]$LaunchWindows,
    [switch]$OpenWorkbench,
    [string]$ProjectPath = "",
    [string]$ScenarioPath = "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json",
    [string]$WorkbenchPath = "docs/reports/project_current_state_handbook_reentry_2026_07_01.html",
    [int]$WindowWidth = 1280,
    [int]$WindowHeight = 720,
    [int]$WaitSeconds = 12
)

$ErrorActionPreference = "Stop"

function Resolve-ProjectPath {
    param([string]$Candidate)
    if (-not [string]::IsNullOrWhiteSpace($Candidate)) {
        return (Resolve-Path -LiteralPath $Candidate).Path
    }
    return (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path
}

function Convert-ResPathToDiskPath {
    param(
        [string]$Root,
        [string]$Path
    )
    if ($Path.StartsWith("res://")) {
        return Join-Path $Root ($Path.Substring(6) -replace "/", [System.IO.Path]::DirectorySeparatorChar)
    }
    return Join-Path $Root ($Path -replace "/", [System.IO.Path]::DirectorySeparatorChar)
}

function Convert-PathToFileUri {
    param([string]$Path)
    return ([System.Uri](Resolve-Path -LiteralPath $Path).Path).AbsoluteUri
}

$resolvedProjectPath = Resolve-ProjectPath $ProjectPath
$tmpDir = Join-Path $resolvedProjectPath "tmp"
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null

$scenarioDiskPath = Convert-ResPathToDiskPath -Root $resolvedProjectPath -Path $ScenarioPath
$workbenchDiskPath = Convert-ResPathToDiskPath -Root $resolvedProjectPath -Path $WorkbenchPath
$packetPath = Join-Path $tmpDir "station_reentry_firefight_visual_playtest_packet.json"
$workbenchUri = if (Test-Path -LiteralPath $workbenchDiskPath) { Convert-PathToFileUri $workbenchDiskPath } else { "" }
$scenarioExists = Test-Path -LiteralPath $scenarioDiskPath
$workbenchExists = Test-Path -LiteralPath $workbenchDiskPath
$status = if ($scenarioExists -and $workbenchExists) { "ready_to_capture_station_reentry_firefight_visual" } else { "blocked" }

$requiredManualChecks = @(
    "f6_window_open",
    "firefight_triggered",
    "fire_trace_visible",
    "impact_focus_visible",
    "unit_badge_visible",
    "combat_hud_next_decision_visible",
    "combat_metrics_match_hud",
    "friendly_fire_risk_readable",
    "screenshot_saved",
    "workbench_json_exported"
)

$launchCommand = "powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1 -Launch -ScenarioPath `"$ScenarioPath`" -WindowWidth $WindowWidth -WindowHeight $WindowHeight"
$captureCommand = "powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1 -Launch -CloseAfterCapture -WaitSeconds $WaitSeconds"

$packet = [ordered]@{
    schema = "sternenbuergerchen.station_reentry_firefight_visual_playtest_packet.v1"
    task_id = "TASK_778"
    source_task_id = "TASK_777"
    target_id = "station_reentry_firefight_visual_playtest"
    read_only = $true
    ui_sets_gameplay_truth = $false
    creates_navigation = $false
    creates_command = $false
    creates_fire_event = $false
    creates_damage_event = $false
    status = $status
    project_path = $resolvedProjectPath
    scenario_path = $ScenarioPath
    scenario_disk_path = $scenarioDiskPath
    scenario_exists = $scenarioExists
    scenario_arg = "--scenario-file=$ScenarioPath"
    workbench_path = $WorkbenchPath
    workbench_disk_path = $workbenchDiskPath
    workbench_exists = $workbenchExists
    workbench_file_uri = $workbenchUri
    focus = "Station Reentry first firefight visual review"
    expected_firefight_readability = [ordered]@{
        source_task_id = "TASK_777"
        required_visible_fragments = @(
            "FIRE",
            "HIT",
            "LOS",
            "COVER",
            "next:"
        )
        required_visuals = @(
            "fire_trace",
            "impact_focus",
            "unit_status_badge"
        )
        required_metrics = @(
            "shots_fired",
            "hit_count",
            "wounded_count",
            "down_count",
            "friendly_fire_risk_count"
        )
        manual_review_note = "TASK_778 prepares the real-window review; manual_review_done remains false until screenshot and JSON export are produced."
    }
    required_manual_checks = $requiredManualChecks
    commands = [ordered]@{
        launch_windows = $launchCommand
        capture_windows = $captureCommand
        open_workbench = $workbenchUri
        rerun_firefight_tension_verifier = "godot_console.exe --headless --path . --script scripts/tests/task_777_station_reentry_firefight_tension_feel_pass.gd"
        rerun_packet_verifier = "godot_console.exe --headless --path . --script scripts/tests/task_778_station_reentry_firefight_visual_playtest_packet.gd"
    }
    launch_windows_requested = [bool]$LaunchWindows
    open_workbench_requested = [bool]$OpenWorkbench
    manual_review_required = $true
    manual_review_done = $false
    recommended_next_task = "TASK_779 - Station Reentry Firefight Visual Findings"
}

$packet | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $packetPath -Encoding UTF8
Write-Host ("TASK_778 station reentry firefight visual playtest packet written: {0}" -f $packetPath)
Write-Host ("Status: {0}; scenario arg: {1}" -f $packet.status, $packet.scenario_arg)

if ($OpenWorkbench) {
    if (-not (Test-Path -LiteralPath $workbenchDiskPath)) {
        throw "Workbench not found: $workbenchDiskPath"
    }
    Start-Process -FilePath $workbenchDiskPath -WindowStyle Hidden
}

if ($LaunchWindows) {
    $launchScript = Join-Path $PSScriptRoot "launch_host_client_two_window_review.ps1"
    & $launchScript -Launch -ScenarioPath $ScenarioPath -WindowWidth $WindowWidth -WindowHeight $WindowHeight -ProjectPath $resolvedProjectPath
}
