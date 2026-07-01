param(
    [switch]$LaunchWindows,
    [switch]$OpenWorkbench,
    [string]$ProjectPath = "",
    [string]$ScenarioPath = "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json",
    [string]$WorkbenchPath = "docs/reports/project_current_state_handbook_reentry_2026_07_01.html",
    [string]$DecisionManifestPath = "tmp/station_reentry_firefight_player_decision_readability_pass.json",
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
$decisionDiskPath = Convert-ResPathToDiskPath -Root $resolvedProjectPath -Path $DecisionManifestPath
$packetPath = Join-Path $tmpDir "station_reentry_firefight_decision_evidence_packet.json"
$workbenchUri = if (Test-Path -LiteralPath $workbenchDiskPath) { Convert-PathToFileUri $workbenchDiskPath } else { "" }
$decisionManifest = Read-JsonFile $decisionDiskPath
$decisionExists = $null -ne $decisionManifest
$decisionStatus = if ($decisionExists) { [string]$decisionManifest.status } else { "" }
$decisionReady = $decisionExists -and ($decisionStatus -eq "ready_for_visible_player_decision_review") -and [bool]$decisionManifest.ready_for_visible_player_decision_review
$scenarioExists = Test-Path -LiteralPath $scenarioDiskPath
$workbenchExists = Test-Path -LiteralPath $workbenchDiskPath
$ready = $scenarioExists -and $workbenchExists -and $decisionReady
$status = if ($ready) { "ready_to_capture_firefight_decision_evidence" } else { "blocked" }

$requiredManualChecks = @(
    "f6_window_open",
    "decision_card_visible",
    "decision_line_visible",
    "primary_action_visible",
    "quick_actions_visible",
    "reason_line_visible",
    "guard_line_visible",
    "confirm_control_visible",
    "no_auto_command_commit_visible",
    "host_client_context_visible",
    "screenshot_saved",
    "workbench_json_exported"
)

$launchCommand = "powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1 -Launch -ScenarioPath `"$ScenarioPath`" -WindowWidth $WindowWidth -WindowHeight $WindowHeight"
$captureCommand = "powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1 -Launch -CloseAfterCapture -WaitSeconds $WaitSeconds"

$packet = [ordered]@{
    schema = "sternenbuergerchen.station_reentry_firefight_decision_evidence_packet.v1"
    task_id = "TASK_788"
    source_task_id = "TASK_787"
    target_id = "station_reentry_firefight_decision_evidence"
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
    decision_manifest_path = $DecisionManifestPath
    decision_manifest_disk_path = $decisionDiskPath
    decision_manifest_exists = $decisionExists
    decision_status = $decisionStatus
    decision_ready = $decisionReady
    expected_decision_line = if ($decisionExists) { [string]$decisionManifest.decision_line } else { "" }
    expected_primary_action_label = if ($decisionExists) { [string]$decisionManifest.primary_action_label } else { "" }
    expected_quick_action_labels = if ($decisionExists -and $decisionManifest.quick_action_labels) { @($decisionManifest.quick_action_labels | ForEach-Object { [string]$_ }) } else { @() }
    expected_reason_line = if ($decisionExists) { [string]$decisionManifest.reason_line } else { "" }
    expected_guard_line = if ($decisionExists) { [string]$decisionManifest.guard_line } else { "" }
    expected_confirm_control = if ($decisionExists) { [string]$decisionManifest.confirm_control } else { "" }
    expected_no_auto_command_commit = if ($decisionExists) { [bool]$decisionManifest.no_auto_command_commit } else { $false }
    expected_existing_commands_only = if ($decisionExists) { [bool]$decisionManifest.existing_commands_only } else { $false }
    expected_host_client_context_visible = if ($decisionExists) { [bool]$decisionManifest.host_client_context_visible } else { $false }
    expected_decision_card = if ($decisionExists -and $decisionManifest.decision_card) { $decisionManifest.decision_card } else { [ordered]@{} }
    focus = "Station Reentry firefight player decision evidence packet"
    required_manual_checks = $requiredManualChecks
    commands = [ordered]@{
        launch_windows = $launchCommand
        capture_windows = $captureCommand
        open_workbench = $workbenchUri
        rerun_player_decision_verifier = "godot_console.exe --headless --path . --script scripts/tests/task_787_station_reentry_firefight_player_decision_readability_pass.gd"
        rerun_decision_evidence_packet_verifier = "godot_console.exe --headless --path . --script scripts/tests/task_788_station_reentry_firefight_decision_evidence_packet.gd"
    }
    launch_windows_requested = [bool]$LaunchWindows
    open_workbench_requested = [bool]$OpenWorkbench
    manual_review_required = $true
    manual_review_done = $false
    recommended_next_task = "TASK_789 - Station Reentry Firefight Decision Evidence Findings"
}

$packet | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $packetPath -Encoding UTF8
Write-Host ("TASK_788 station reentry firefight decision evidence packet written: {0}" -f $packetPath)
Write-Host ("Status: {0}; decision status: {1}" -f $packet.status, $packet.decision_status)

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
