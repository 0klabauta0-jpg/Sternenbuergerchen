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
$task726ManifestPath = Join-Path $tmpDir "station_route_one_screen_multiplayer_drill.json"
$task727ManifestPath = Join-Path $tmpDir "station_scenario_f6_host_client_playtest_notes.json"
$task728ManifestPath = Join-Path $tmpDir "station_scenario_playtest_findings.json"
$packetPath = Join-Path $tmpDir "station_scenario_visible_playtest_run_packet.json"

$task726 = Read-JsonFile $task726ManifestPath
$task727 = Read-JsonFile $task727ManifestPath
$task728 = Read-JsonFile $task728ManifestPath

$scenarioReady = (Test-Path -LiteralPath $scenarioDiskPath) -and $null -ne $task726 -and [string]$task726.status -eq "ready_for_f6_host_client_playtest"
$notesReady = $null -ne $task727 -and [string]$task727.status -eq "needs_visible_playtest"
$findingsReady = $null -ne $task728 -and [string]$task728.status -eq "needs_visible_playtest"
$status = if ($scenarioReady -and $notesReady -and $findingsReady -and (Test-Path -LiteralPath $workbenchDiskPath)) { "ready_to_run_visible_playtest" } else { "blocked" }

$launchCommand = "powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1 -Launch -ScenarioPath `"$ScenarioPath`" -WindowWidth $WindowWidth -WindowHeight $WindowHeight"
$captureCommand = "powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1 -Launch -CloseAfterCapture -WaitSeconds 10"
$workbenchUri = if (Test-Path -LiteralPath $workbenchDiskPath) { Convert-PathToFileUri $workbenchDiskPath } else { "" }
$expectedPolishedCueLine = "CUE AA: BLUE naeher ran | 3.9km"
$expectedFeedbackStyleId = "station_route_player_action_cue_v2"
$forbiddenCueFragments = @(
    "BLUE 3859m",
    "3859m",
    "CARGO blockiert"
)

$packet = [ordered]@{
    schema = "sternenbuergerchen.station_scenario_visible_playtest_run_packet.v1"
    task_id = "TASK_729"
    refresh_task_id = "TASK_737"
    latest_feedback_task_id = "TASK_736"
    read_only = $true
    ui_sets_gameplay_truth = $false
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
    task_726_manifest_path = "tmp/station_route_one_screen_multiplayer_drill.json"
    task_726_status = $(if ($null -ne $task726) { [string]$task726.status } else { "" })
    task_727_manifest_path = "tmp/station_scenario_f6_host_client_playtest_notes.json"
    task_727_status = $(if ($null -ne $task727) { [string]$task727.status } else { "" })
    task_728_manifest_path = "tmp/station_scenario_playtest_findings.json"
    task_728_status = $(if ($null -ne $task728) { [string]$task728.status } else { "" })
    required_manual_checks = @(
        "real_f6_window_reviewed",
        "host_client_two_window_reviewed",
        "aa_door_com_cargo_route_readable",
        "door_computer_cargo_cues_obvious",
        "fireteam_orders_feel_fast",
        "performance_feels_fast",
        "no_hud_overlap_blocks_map",
        "wrong_team_or_bravo_context_clear",
        "polished_aa_cue_reads_blue_naeher_ran_3_9km",
        "raw_long_meter_distance_hidden",
        "future_cargo_blocker_not_in_act_line",
        "playtest_done"
    )
    visible_feedback_expectations = [ordered]@{
        source_task_id = "TASK_736"
        cue_line_example = $expectedPolishedCueLine
        expected_feedback_style_id = $expectedFeedbackStyleId
        expected_distance_text = "3.9km"
        required_visible_fragments = @(
            "CUE AA",
            "BLUE naeher ran",
            "3.9km"
        )
        forbidden_visible_fragments = $forbiddenCueFragments
        expected_act_behavior = "ACT shows the current cue, not the future cargo blocker, while AA is still the active station step."
        manual_review_note = "This packet only names visible expectations; TASK_727 remains unfinished until the workbench JSON is exported by a human reviewer."
    }
    commands = [ordered]@{
        launch_windows = $launchCommand
        capture_windows = $captureCommand
        open_workbench = $workbenchUri
        rerun_notes_verifier = "godot_console.exe --headless --path . --script scripts/tests/task_727_station_scenario_f6_host_client_playtest_notes.gd"
        rerun_findings_verifier = "godot_console.exe --headless --path . --script scripts/tests/task_728_station_scenario_playtest_findings.gd"
        rerun_command_feedback_verifier = "godot_console.exe --headless --path . --script scripts/tests/task_736_station_scenario_command_feedback_polish.gd"
        rerun_packet_refresh_verifier = "godot_console.exe --headless --path . --script scripts/tests/task_737_station_scenario_visible_cue_run_packet_refresh.gd"
    }
    launch_windows_requested = [bool]$LaunchWindows
    open_workbench_requested = [bool]$OpenWorkbench
    manual_review_required = $true
    manual_review_done = $false
    recommended_next_task = "TASK_727 - fill visible station scenario playtest workbench"
}

$packet | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $packetPath -Encoding UTF8
Write-Host ("TASK_729 station scenario visible playtest packet written: {0}" -f $packetPath)
Write-Host ("Status: {0}; scenario arg: {1}" -f $packet.status, $packet.scenario_arg)

if ($OpenWorkbench) {
    if (-not (Test-Path -LiteralPath $workbenchDiskPath)) {
        throw "Workbench not found: $workbenchDiskPath"
    }
    Start-Process -FilePath $workbenchDiskPath
}

if ($LaunchWindows) {
    $launchScript = Join-Path $PSScriptRoot "launch_host_client_two_window_review.ps1"
    & $launchScript -Launch -ScenarioPath $ScenarioPath -WindowWidth $WindowWidth -WindowHeight $WindowHeight -ProjectPath $resolvedProjectPath
}
