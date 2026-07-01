param(
    [switch]$LaunchWindows,
    [switch]$OpenWorkbench,
    [string]$ProjectPath = "",
    [string]$ScenarioPath = "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json",
    [string]$WorkbenchPath = "docs/reports/project_current_state_handbook_reentry_2026_07_01.html",
    [string]$InteractionManifestPath = "tmp/station_reentry_firefight_interaction_polish.json",
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
$interactionDiskPath = Convert-ResPathToDiskPath -Root $resolvedProjectPath -Path $InteractionManifestPath
$packetPath = Join-Path $tmpDir "station_reentry_firefight_command_surface_recapture.json"
$workbenchUri = if (Test-Path -LiteralPath $workbenchDiskPath) { Convert-PathToFileUri $workbenchDiskPath } else { "" }
$interactionManifest = Read-JsonFile $interactionDiskPath
$interactionExists = $null -ne $interactionManifest
$interactionStatus = if ($interactionExists) { [string]$interactionManifest.status } else { "" }
$ready = (Test-Path -LiteralPath $scenarioDiskPath) -and (Test-Path -LiteralPath $workbenchDiskPath) -and $interactionExists -and ($interactionStatus -eq "ready_for_firefight_interaction_playtest")
$status = if ($ready) { "ready_to_capture_firefight_command_surface" } else { "blocked" }

$requiredManualChecks = @(
    "f6_window_open",
    "interaction_line_visible",
    "primary_action_visible",
    "quick_actions_visible",
    "hold_flank_sup_visible",
    "hold_fire_visible_when_ff_risk",
    "no_auto_command_commit_visible",
    "selected_fireteam_panel_consistent",
    "command_matrix_buttons_reachable",
    "host_client_same_surface_visible",
    "screenshot_saved",
    "workbench_json_exported"
)

$launchCommand = "powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1 -Launch -ScenarioPath `"$ScenarioPath`" -WindowWidth $WindowWidth -WindowHeight $WindowHeight"
$captureCommand = "powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1 -Launch -CloseAfterCapture -WaitSeconds $WaitSeconds"

$packet = [ordered]@{
    schema = "sternenbuergerchen.station_reentry_firefight_command_surface_recapture.v1"
    task_id = "TASK_781"
    source_task_id = "TASK_780"
    target_id = "station_reentry_firefight_command_surface_recapture"
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
    scenario_exists = Test-Path -LiteralPath $scenarioDiskPath
    workbench_path = $WorkbenchPath
    workbench_disk_path = $workbenchDiskPath
    workbench_exists = Test-Path -LiteralPath $workbenchDiskPath
    workbench_file_uri = $workbenchUri
    interaction_manifest_path = $InteractionManifestPath
    interaction_manifest_disk_path = $interactionDiskPath
    interaction_manifest_exists = $interactionExists
    interaction_status = $interactionStatus
    expected_interaction_line = if ($interactionExists) { [string]$interactionManifest.interaction_line } else { "" }
    expected_primary_action_label = if ($interactionExists -and $interactionManifest.primary_action) { [string]$interactionManifest.primary_action.label } else { "" }
    expected_quick_action_labels = if ($interactionExists -and $interactionManifest.quick_actions) { @($interactionManifest.quick_actions | ForEach-Object { [string]$_.label }) } else { @() }
    expected_no_auto_command_commit = if ($interactionExists) { [bool]$interactionManifest.no_auto_command_commit } else { $false }
    expected_uses_existing_commands_only = if ($interactionExists) { [bool]$interactionManifest.uses_existing_commands_only } else { $false }
    focus = "Station Reentry visible firefight command surface recapture"
    required_manual_checks = $requiredManualChecks
    commands = [ordered]@{
        launch_windows = $launchCommand
        capture_windows = $captureCommand
        open_workbench = $workbenchUri
        rerun_interaction_polish_verifier = "godot_console.exe --headless --path . --script scripts/tests/task_780_station_reentry_firefight_interaction_polish.gd"
        rerun_recapture_verifier = "godot_console.exe --headless --path . --script scripts/tests/task_781_station_reentry_firefight_command_surface_recapture.gd"
    }
    launch_windows_requested = [bool]$LaunchWindows
    open_workbench_requested = [bool]$OpenWorkbench
    manual_review_required = $true
    manual_review_done = $false
    recommended_next_task = "TASK_782 - Station Reentry Firefight Command Surface Findings"
}

$packet | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $packetPath -Encoding UTF8
Write-Host ("TASK_781 station reentry firefight command surface recapture packet written: {0}" -f $packetPath)
Write-Host ("Status: {0}; interaction status: {1}" -f $packet.status, $packet.interaction_status)

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
