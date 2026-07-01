param(
    [switch]$LaunchWindows,
    [switch]$OpenWorkbench,
    [string]$ProjectPath = "",
    [string]$ScenarioPath = "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json",
    [string]$WorkbenchPath = "docs/reports/project_current_state_handbook_reentry_2026_07_01.html",
    [string]$PolishManifestPath = "tmp/station_reentry_firefight_command_surface_polish.json",
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
$polishDiskPath = Convert-ResPathToDiskPath -Root $resolvedProjectPath -Path $PolishManifestPath
$packetPath = Join-Path $tmpDir "station_reentry_firefight_command_surface_playtest_packet_refresh.json"
$workbenchUri = if (Test-Path -LiteralPath $workbenchDiskPath) { Convert-PathToFileUri $workbenchDiskPath } else { "" }
$polishManifest = Read-JsonFile $polishDiskPath
$polishExists = $null -ne $polishManifest
$polishStatus = if ($polishExists) { [string]$polishManifest.status } else { "" }
$ready = (Test-Path -LiteralPath $scenarioDiskPath) -and (Test-Path -LiteralPath $workbenchDiskPath) -and $polishExists -and ($polishStatus -eq "ready_for_command_surface_polish_review")
$status = if ($ready) { "ready_to_capture_polished_command_surface" } else { "blocked" }

$requiredManualChecks = @(
    "f6_window_open",
    "polished_surface_visible",
    "interaction_line_visible",
    "primary_action_lane_visible",
    "quick_action_rail_visible",
    "guard_line_visible",
    "no_auto_command_commit_visible",
    "existing_buttons_visible",
    "selected_fireteam_panel_consistent",
    "host_client_same_surface_visible",
    "screenshot_saved",
    "workbench_json_exported"
)

$launchCommand = "powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1 -Launch -ScenarioPath `"$ScenarioPath`" -WindowWidth $WindowWidth -WindowHeight $WindowHeight"
$captureCommand = "powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1 -Launch -CloseAfterCapture -WaitSeconds $WaitSeconds"

$packet = [ordered]@{
    schema = "sternenbuergerchen.station_reentry_firefight_command_surface_playtest_packet_refresh.v1"
    task_id = "TASK_784"
    source_task_id = "TASK_783"
    target_id = "station_reentry_firefight_command_surface_playtest_packet_refresh"
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
    polish_manifest_path = $PolishManifestPath
    polish_manifest_disk_path = $polishDiskPath
    polish_manifest_exists = $polishExists
    polish_status = $polishStatus
    expected_command_surface_style_id = if ($polishExists) { [string]$polishManifest.command_surface_style_id } else { "" }
    expected_surface_priority_order = if ($polishExists -and $polishManifest.surface_priority_order) { @($polishManifest.surface_priority_order | ForEach-Object { [string]$_ }) } else { @() }
    expected_interaction_line = if ($polishExists) { [string]$polishManifest.interaction_line } else { "" }
    expected_primary_action_label = if ($polishExists -and $polishManifest.primary_action) { [string]$polishManifest.primary_action.label } else { "" }
    expected_quick_action_labels = if ($polishExists -and $polishManifest.quick_action_rail) { @($polishManifest.quick_action_rail | ForEach-Object { [string]$_.display_label }) } else { @() }
    expected_guard_line = if ($polishExists) { [string]$polishManifest.guard_line } else { "" }
    expected_summary_line = if ($polishExists) { [string]$polishManifest.summary_line } else { "" }
    expected_no_auto_command_commit = if ($polishExists) { [bool]$polishManifest.no_auto_command_commit } else { $false }
    expected_uses_existing_commands_only = if ($polishExists) { [bool]$polishManifest.uses_existing_commands_only } else { $false }
    focus = "Station Reentry polished firefight command surface visible playtest packet"
    required_manual_checks = $requiredManualChecks
    commands = [ordered]@{
        launch_windows = $launchCommand
        capture_windows = $captureCommand
        open_workbench = $workbenchUri
        rerun_command_surface_polish_verifier = "godot_console.exe --headless --path . --script scripts/tests/task_783_station_reentry_firefight_command_surface_polish.gd"
        rerun_playtest_packet_refresh_verifier = "godot_console.exe --headless --path . --script scripts/tests/task_784_station_reentry_firefight_command_surface_playtest_packet_refresh.gd"
    }
    launch_windows_requested = [bool]$LaunchWindows
    open_workbench_requested = [bool]$OpenWorkbench
    manual_review_required = $true
    manual_review_done = $false
    recommended_next_task = "TASK_785 - Station Reentry Firefight Command Surface Visible Findings Refresh"
}

$packet | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $packetPath -Encoding UTF8
Write-Host ("TASK_784 station reentry firefight command surface playtest packet written: {0}" -f $packetPath)
Write-Host ("Status: {0}; polish status: {1}" -f $packet.status, $packet.polish_status)

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
