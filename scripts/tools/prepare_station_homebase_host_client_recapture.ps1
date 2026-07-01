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

function Read-JsonFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }
    $text = Get-Content -LiteralPath $Path -Raw
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $null
    }
    return $text | ConvertFrom-Json
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
$task749ManifestPath = Join-Path $tmpDir "station_homebase_followup_microcopy_polish.json"
$task747ManifestPath = Join-Path $tmpDir "station_scenario_homebase_visible_readiness_review.json"
$task755ManifestPath = Join-Path $tmpDir "station_homebase_return_panel_polish.json"
$packetPath = Join-Path $tmpDir "station_homebase_host_client_recapture_packet.json"

$task749 = Read-JsonFile $task749ManifestPath
$task747 = Read-JsonFile $task747ManifestPath
$task755 = Read-JsonFile $task755ManifestPath
$expectedHomebaseLine = "Naechste Sortie: Fireteam bereitstellen | danach: Loadout pruefen, Dropship beladen, Start freigeben"
$expectedSummaryFragment = "Station Drill"
$expectedReturnPanelStyleId = "task_755_station_homebase_return_panel_v1"
$expectedReturnPanelTitle = "Rueckkehr abgeschlossen"
$expectedReturnPanelAction = "Naechster Auftrag: Fireteam bereitstellen"
$expectedReturnPanelChipCount = 5
$expectedReturnPanelStepLabels = @(
    "Auswertung ansehen",
    "Fireteam bereitstellen",
    "Loadout pruefen",
    "Dropship beladen",
    "Start freigeben"
)
$task749Ready = $null -ne $task749 -and [string]$task749.readiness_line -eq $expectedHomebaseLine -and [bool]$task749.old_debug_markers_removed
$task747Ready = $null -ne $task747 -and [string]$task747.gate -eq "pass"
$task755Ready = $null -ne $task755 -and [string]$task755.gate -eq "pass" -and [string]$task755.return_panel_style_id -eq $expectedReturnPanelStyleId -and [string]$task755.return_panel_title_text -eq $expectedReturnPanelTitle -and [string]$task755.return_panel_action_text -eq $expectedReturnPanelAction -and [int]$task755.return_panel_chip_count -ge $expectedReturnPanelChipCount
$status = if ((Test-Path -LiteralPath $scenarioDiskPath) -and (Test-Path -LiteralPath $workbenchDiskPath) -and $task749Ready -and $task747Ready -and $task755Ready) { "ready_to_run_homebase_recapture" } else { "blocked" }

$launchCommand = "powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1 -Launch -ScenarioPath `"$ScenarioPath`" -WindowWidth $WindowWidth -WindowHeight $WindowHeight"
$captureCommand = "powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1 -Launch -CloseAfterCapture -WaitSeconds 12"
$workbenchUri = if (Test-Path -LiteralPath $workbenchDiskPath) { Convert-PathToFileUri $workbenchDiskPath } else { "" }

$packet = [ordered]@{
    schema = "sternenbuergerchen.station_homebase_host_client_recapture_packet.v1"
    task_id = "TASK_750"
    refresh_task_id = "TASK_756"
    source_task_id = "TASK_755"
    source_microcopy_task_id = "TASK_749"
    source_visible_review_task_id = "TASK_747"
    read_only = $true
    ui_sets_gameplay_truth = $false
    creates_navigation = $false
    creates_command = $false
    status = $status
    project_path = $resolvedProjectPath
    scenario_path = $ScenarioPath
    scenario_disk_path = $scenarioDiskPath
    scenario_exists = Test-Path -LiteralPath $scenarioDiskPath
    workbench_path = $WorkbenchPath
    workbench_disk_path = $workbenchDiskPath
    workbench_exists = Test-Path -LiteralPath $workbenchDiskPath
    workbench_file_uri = $workbenchUri
    task_749_manifest_path = "tmp/station_homebase_followup_microcopy_polish.json"
    task_749_ready = [bool]$task749Ready
    task_747_manifest_path = "tmp/station_scenario_homebase_visible_readiness_review.json"
    task_747_gate = $(if ($null -ne $task747) { [string]$task747.gate } else { "" })
    task_755_manifest_path = "tmp/station_homebase_return_panel_polish.json"
    task_755_ready = [bool]$task755Ready
    expected_homebase_summary_fragment = $expectedSummaryFragment
    expected_homebase_readiness_line = $expectedHomebaseLine
    expected_homebase_return_panel_style_id = $expectedReturnPanelStyleId
    expected_homebase_return_panel_title = $expectedReturnPanelTitle
    expected_homebase_return_panel_action = $expectedReturnPanelAction
    expected_homebase_return_panel_chip_count = $expectedReturnPanelChipCount
    expected_homebase_return_panel_step_labels = $expectedReturnPanelStepLabels
    expected_old_debug_markers_absent = @(
        "Next sortie",
        "Review gains",
        "Stage fireteam",
        "Assign loadout",
        "Load dropship",
        "Start next sortie"
    )
    required_manual_checks = @(
        "host_window_launched",
        "client_window_launched",
        "cargo_end_reached",
        "debrief_visible_after_cargo",
        "return_homebase_clicked",
        "homebase_summary_mentions_station_drill",
        "homebase_return_panel_title_visible",
        "homebase_return_panel_action_visible",
        "homebase_return_panel_chips_visible",
        "homebase_return_panel_matches_task_755",
        "homebase_next_sortie_line_visible",
        "homebase_next_sortie_line_matches_task_749",
        "old_debug_next_sortie_markers_absent",
        "host_client_context_still_readable",
        "hud_does_not_block_homebase_followup",
        "performance_feels_fast",
        "workbench_notes_exported"
    )
    commands = [ordered]@{
        launch_windows = $launchCommand
        capture_windows = $captureCommand
        open_workbench = $workbenchUri
        rerun_task_747 = "godot_console.exe --headless --path . --script scripts/tests/task_747_station_scenario_homebase_visible_readiness_review.gd"
        rerun_task_749 = "godot_console.exe --headless --path . --script scripts/tests/task_749_station_homebase_followup_microcopy_polish.gd"
        rerun_task_755 = "godot_console.exe --headless --path . --script scripts/tests/task_755_station_homebase_return_panel_polish.gd"
        rerun_task_750 = "godot_console.exe --headless --path . --script scripts/tests/task_750_station_homebase_host_client_recapture_packet.gd"
    }
    launch_windows_requested = [bool]$LaunchWindows
    open_workbench_requested = [bool]$OpenWorkbench
    manual_review_required = $true
    manual_review_done = $false
    recommended_next_task = "TASK_756 - Station Homebase Real Window Recapture"
}

$packet | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $packetPath -Encoding UTF8
Write-Host ("TASK_750 station homebase recapture packet written: {0}" -f $packetPath)
Write-Host ("Status: {0}; expected line: {1}" -f $packet.status, $packet.expected_homebase_readiness_line)

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
