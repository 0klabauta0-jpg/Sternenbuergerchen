param(
    [switch]$LaunchWindows,
    [switch]$OpenWorkbench,
    [string]$ProjectPath = "",
    [string]$ScenarioPath = "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json",
    [string]$WorkbenchPath = "docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html",
    [int]$WindowWidth = 1280,
    [int]$WindowHeight = 720
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
$packetPath = Join-Path $tmpDir "station_reentry_playtest_run_packet.json"
$workbenchUri = if (Test-Path -LiteralPath $workbenchDiskPath) { Convert-PathToFileUri $workbenchDiskPath } else { "" }
$status = if ((Test-Path -LiteralPath $scenarioDiskPath) -and (Test-Path -LiteralPath $workbenchDiskPath)) { "ready_to_run_station_reentry_playtest" } else { "blocked" }

$runbookSteps = @(
    "Homebase-Return-Panel lesen",
    "Fireteam bereitstellen",
    "Loadout pruefen",
    "Dropship beladen",
    "Start freigeben",
    "erste Mission-Entscheidung mit Preview treffen"
)
$multiplayerChecks = @(
    "Host und Client sehen denselben naechsten Auftrag",
    "Fireteam-Zuordnung bleibt im Dropship konsistent",
    "Startfreigabe erzeugt keine zweite UI-Wahrheit",
    "erste Mission-Cue ist fuer beide Fenster lesbar"
)
$requiredManualChecks = @(
    "homebase_return_panel_readable",
    "fireteam_staging_readable",
    "loadout_check_readable",
    "dropship_payload_consistent",
    "start_release_visible",
    "host_client_same_next_order",
    "first_mission_preview_visible",
    "first_mission_cue_readable",
    "performance_feels_fast",
    "workbench_notes_exported"
)

$launchCommand = "powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1 -Launch -ScenarioPath `"$ScenarioPath`" -WindowWidth $WindowWidth -WindowHeight $WindowHeight"
$captureCommand = "powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1 -Launch -CloseAfterCapture -WaitSeconds 12"

$packet = [ordered]@{
    schema = "sternenbuergerchen.station_reentry_playtest_run_packet.v1"
    task_id = "TASK_760"
    source_task_id = "TASK_759"
    target_id = "station_reentry_playtest"
    target_title = "Homebase -> naechste Station-Sortie"
    read_only = $true
    ui_sets_gameplay_truth = $false
    creates_navigation = $false
    creates_command = $false
    status = $status
    project_path = $resolvedProjectPath
    scenario_path = $ScenarioPath
    scenario_disk_path = $scenarioDiskPath
    scenario_exists = Test-Path -LiteralPath $scenarioDiskPath
    scenario_arg = "--scenario-file=$ScenarioPath"
    workbench_path = $WorkbenchPath
    workbench_disk_path = $workbenchDiskPath
    workbench_exists = Test-Path -LiteralPath $workbenchDiskPath
    workbench_file_uri = $workbenchUri
    focus = "Homebase-Reentry, Fireteam/Loadout/Dropship, erster Missionsentscheid"
    runbook_steps = $runbookSteps
    multiplayer_checks = $multiplayerChecks
    required_manual_checks = $requiredManualChecks
    commands = [ordered]@{
        launch_windows = $launchCommand
        capture_windows = $captureCommand
        open_workbench = $workbenchUri
        rerun_target_verifier = "godot_console.exe --headless --path . --script scripts/tests/task_759_station_slice_next_playtest_target.gd"
        rerun_packet_verifier = "godot_console.exe --headless --path . --script scripts/tests/task_760_station_reentry_playtest_run_packet.gd"
    }
    launch_windows_requested = [bool]$LaunchWindows
    open_workbench_requested = [bool]$OpenWorkbench
    manual_review_required = $true
    manual_review_done = $false
    recommended_next_task = "TASK_761 - Station Reentry Visible Playtest Findings"
}

$packet | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $packetPath -Encoding UTF8
Write-Host ("TASK_760 station reentry playtest packet written: {0}" -f $packetPath)
Write-Host ("Status: {0}; target: {1}" -f $packet.status, $packet.target_id)

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
