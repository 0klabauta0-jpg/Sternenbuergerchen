param(
    [switch]$LaunchWindows,
    [switch]$OpenWorkbench,
    [string]$ProjectPath = "",
    [string]$ScenarioPath = "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json",
    [string]$WorkbenchPath = "docs/reports/project_current_state_handbook_reentry_2026_07_01.html",
    [string]$AcceptanceManifestPath = "tmp/station_reentry_firefight_multiplayer_decision_acceptance.json",
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

function Read-JsonFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

$resolvedProjectPath = Resolve-ProjectPath $ProjectPath
$tmpDir = Join-Path $resolvedProjectPath "tmp"
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null

$scenarioDiskPath = Convert-ResPathToDiskPath -Root $resolvedProjectPath -Path $ScenarioPath
$workbenchDiskPath = Convert-ResPathToDiskPath -Root $resolvedProjectPath -Path $WorkbenchPath
$acceptanceDiskPath = Convert-ResPathToDiskPath -Root $resolvedProjectPath -Path $AcceptanceManifestPath
$packetPath = Join-Path $tmpDir "station_reentry_firefight_multiplayer_decision_playtest_packet.json"
$workbenchUri = if (Test-Path -LiteralPath $workbenchDiskPath) { Convert-PathToFileUri $workbenchDiskPath } else { "" }
$acceptanceManifest = Read-JsonFile $acceptanceDiskPath
$acceptanceExists = $null -ne $acceptanceManifest
$acceptanceStatus = if ($acceptanceExists) { [string]$acceptanceManifest.status } else { "" }
$acceptedForMultiplayerSlice = $acceptanceExists -and ($acceptanceStatus -eq "accepted_for_multiplayer_firefight_decision_slice") -and [bool]$acceptanceManifest.accepted_for_multiplayer_firefight_decision_slice
$scenarioExists = Test-Path -LiteralPath $scenarioDiskPath
$workbenchExists = Test-Path -LiteralPath $workbenchDiskPath
$ready = $scenarioExists -and $workbenchExists -and $acceptedForMultiplayerSlice
$status = if ($ready) { "ready_to_playtest_firefight_multiplayer_decision" } else { "blocked" }

$requiredManualChecks = @(
    "host_window_open",
    "client_window_open",
    "host_decision_card_visible",
    "client_decision_card_visible",
    "host_client_same_decision_line",
    "host_client_same_primary_action",
    "host_client_same_quick_actions",
    "host_client_same_reason_line",
    "host_client_same_guard_line",
    "host_client_same_confirm_control",
    "no_auto_command_commit_visible",
    "existing_buttons_visible",
    "peer_team_context_distinct",
    "decision_choice_feels_actionable",
    "firefight_response_stays_fast",
    "screenshot_saved",
    "workbench_json_exported"
)

$launchCommand = "powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1 -Launch -ScenarioPath `"$ScenarioPath`" -WindowWidth $WindowWidth -WindowHeight $WindowHeight"
$captureCommand = "powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1 -Launch -CloseAfterCapture -WaitSeconds $WaitSeconds"

$packet = [ordered]@{
    schema = "sternenbuergerchen.station_reentry_firefight_multiplayer_decision_playtest_packet.v1"
    task_id = "TASK_794"
    source_task_id = "TASK_793"
    target_id = "station_reentry_firefight_multiplayer_decision_playtest"
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
    workbench_path = $WorkbenchPath
    workbench_disk_path = $workbenchDiskPath
    workbench_exists = $workbenchExists
    workbench_file_uri = $workbenchUri
    acceptance_manifest_path = $AcceptanceManifestPath
    acceptance_manifest_disk_path = $acceptanceDiskPath
    acceptance_manifest_exists = $acceptanceExists
    acceptance_status = $acceptanceStatus
    accepted_for_multiplayer_firefight_decision_slice = $acceptedForMultiplayerSlice
    expected_decision_line = if ($acceptanceExists) { [string]$acceptanceManifest.expected_decision_line } else { "" }
    expected_primary_action_label = if ($acceptanceExists) { [string]$acceptanceManifest.expected_primary_action_label } else { "" }
    expected_quick_action_labels = if ($acceptanceExists -and $acceptanceManifest.expected_quick_action_labels) { @($acceptanceManifest.expected_quick_action_labels | ForEach-Object { [string]$_ }) } else { @() }
    expected_reason_line = if ($acceptanceExists) { [string]$acceptanceManifest.expected_reason_line } else { "" }
    expected_guard_line = if ($acceptanceExists) { [string]$acceptanceManifest.expected_guard_line } else { "" }
    expected_confirm_control = if ($acceptanceExists) { [string]$acceptanceManifest.expected_confirm_control } else { "" }
    expected_no_auto_command_commit = if ($acceptanceExists) { [bool]$acceptanceManifest.expected_no_auto_command_commit } else { $false }
    expected_existing_commands_only = if ($acceptanceExists) { [bool]$acceptanceManifest.expected_existing_commands_only } else { $false }
    expected_host_client_context_visible = if ($acceptanceExists) { [bool]$acceptanceManifest.expected_host_client_context_visible } else { $false }
    expected_host_role = if ($acceptanceExists) { [string]$acceptanceManifest.expected_host_role } else { "HOST P1 ALPHA" }
    expected_client_role = if ($acceptanceExists) { [string]$acceptanceManifest.expected_client_role } else { "CLIENT P2 BRAVO" }
    focus = "Station Reentry accepted multiplayer firefight decision slice playtest"
    required_manual_checks = $requiredManualChecks
    commands = [ordered]@{
        launch_windows = $launchCommand
        capture_windows = $captureCommand
        open_workbench = $workbenchUri
        rerun_multiplayer_decision_acceptance_verifier = "godot_console.exe --headless --path . --script scripts/tests/task_793_station_reentry_firefight_multiplayer_decision_acceptance.gd"
        rerun_multiplayer_decision_playtest_packet_verifier = "godot_console.exe --headless --path . --script scripts/tests/task_794_station_reentry_firefight_multiplayer_decision_playtest_packet.gd"
    }
    launch_windows_requested = [bool]$LaunchWindows
    open_workbench_requested = [bool]$OpenWorkbench
    manual_two_window_playtest_required = $true
    manual_two_window_playtest_done = $false
    recommended_next_task = "TASK_795 - Station Reentry Firefight Multiplayer Decision Playtest Findings"
}

$packet | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $packetPath -Encoding UTF8
Write-Host ("TASK_794 station reentry firefight multiplayer decision playtest packet written: {0}" -f $packetPath)
Write-Host ("Status: {0}; acceptance status: {1}" -f $packet.status, $packet.acceptance_status)

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
