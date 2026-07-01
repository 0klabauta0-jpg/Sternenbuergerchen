param(
    [switch]$LaunchWindows,
    [switch]$OpenWorkbench,
    [string]$ProjectPath = "",
    [string]$ScenarioPath = "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json",
    [string]$WorkbenchPath = "docs/reports/project_current_state_handbook_reentry_2026_07_01.html",
    [string]$SyncManifestPath = "tmp/station_reentry_host_client_next_order_sync.json",
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
$syncManifestDiskPath = Convert-ResPathToDiskPath -Root $resolvedProjectPath -Path $SyncManifestPath
$exportPath = Join-Path $tmpDir "station_reentry_visible_host_client_playtest_export.json"
$workbenchUri = if (Test-Path -LiteralPath $workbenchDiskPath) { Convert-PathToFileUri $workbenchDiskPath } else { "" }
$syncManifest = Read-JsonFile $syncManifestDiskPath
$syncManifestExists = $null -ne $syncManifest
$syncGate = if ($syncManifestExists) { [string]$syncManifest.sync_gate } else { "" }
$ready = (Test-Path -LiteralPath $scenarioDiskPath) -and (Test-Path -LiteralPath $workbenchDiskPath) -and $syncManifestExists -and ($syncGate -eq "pass")
$status = if ($ready) { "ready_to_capture_station_reentry_host_client" } else { "blocked" }

$requiredManualChecks = @(
    "host_window_open",
    "client_window_open",
    "host_client_same_next_order_visible",
    "host_client_route_cue_same_visible",
    "peer_team_context_distinct_visible",
    "first_mission_preview_visible_before_go",
    "export_json_saved"
)

$launchCommand = "powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1 -Launch -ScenarioPath `"$ScenarioPath`" -WindowWidth $WindowWidth -WindowHeight $WindowHeight"
$captureCommand = "powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1 -Launch -CloseAfterCapture -WaitSeconds $WaitSeconds"

$packet = [ordered]@{
    schema = "sternenbuergerchen.station_reentry_visible_host_client_playtest_export.v1"
    task_id = "TASK_771"
    source_task_id = "TASK_770"
    target_id = "station_reentry_host_client_visible_export"
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
    sync_manifest_path = $SyncManifestPath
    sync_manifest_disk_path = $syncManifestDiskPath
    sync_manifest_exists = $syncManifestExists
    sync_gate = $syncGate
    expected_host_next_order_text = if ($syncManifestExists) { [string]$syncManifest.host_next_order_text } else { "" }
    expected_client_next_order_text = if ($syncManifestExists) { [string]$syncManifest.client_next_order_text } else { "" }
    expected_station_route_line = if ($syncManifestExists) { [string]$syncManifest.station_route_line } else { "" }
    expected_station_cue_line = if ($syncManifestExists) { [string]$syncManifest.station_cue_line } else { "" }
    expected_same_next_order = if ($syncManifestExists) { [bool]$syncManifest.same_next_order } else { $false }
    expected_same_route_line = if ($syncManifestExists) { [bool]$syncManifest.same_route_line } else { $false }
    expected_same_cue_line = if ($syncManifestExists) { [bool]$syncManifest.same_cue_line } else { $false }
    expected_peer_context_distinct = if ($syncManifestExists) { [bool]$syncManifest.peer_context_distinct } else { $false }
    required_manual_checks = $requiredManualChecks
    commands = [ordered]@{
        launch_windows = $launchCommand
        capture_windows = $captureCommand
        open_workbench = $workbenchUri
        rerun_sync_verifier = "godot_console.exe --headless --path . --script scripts/tests/task_770_station_reentry_host_client_next_order_sync.gd"
        rerun_export_verifier = "godot_console.exe --headless --path . --script scripts/tests/task_771_station_reentry_visible_host_client_playtest_export.gd"
    }
    launch_windows_requested = [bool]$LaunchWindows
    open_workbench_requested = [bool]$OpenWorkbench
    manual_review_required = $true
    manual_review_done = $false
    recommended_next_task = "TASK_772 - Station Reentry Host Client Export Findings"
}

$packet | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $exportPath -Encoding UTF8
Write-Host ("TASK_771 station reentry host/client export packet written: {0}" -f $exportPath)
Write-Host ("Status: {0}; sync gate: {1}" -f $packet.status, $packet.sync_gate)

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
