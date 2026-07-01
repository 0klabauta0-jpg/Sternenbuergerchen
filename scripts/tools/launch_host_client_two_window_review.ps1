param(
    [switch]$Launch,
    [string]$GodotBin = "",
    [string]$ProjectPath = "",
    [string]$Scene = "res://scenes/tests/mission_reactivity_test.tscn",
    [int]$WindowWidth = 1280,
    [int]$WindowHeight = 720,
    [int]$HostX = 40,
    [int]$ClientX = 1380,
    [int]$Y = 80,
    [string]$ScenarioPath = "",
    [switch]$DisableAutoFitLayout
)

$ErrorActionPreference = "Stop"

function Resolve-ProjectPath {
    param([string]$Candidate)
    if (-not [string]::IsNullOrWhiteSpace($Candidate)) {
        return (Resolve-Path -LiteralPath $Candidate).Path
    }
    return (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path
}

function Resolve-GodotCandidate {
    param([string]$Candidate)
    $result = [ordered]@{
        path = ""
        found = $false
        source = "fallback"
    }

    if (-not [string]::IsNullOrWhiteSpace($Candidate)) {
        if (Test-Path -LiteralPath $Candidate) {
            $result.path = (Resolve-Path -LiteralPath $Candidate).Path
            $result.found = $true
            $result.source = "argument"
            return $result
        }
        $result.path = $Candidate
        $result.source = "argument_missing"
        return $result
    }

    if (-not [string]::IsNullOrWhiteSpace($env:GODOT_BIN)) {
        if (Test-Path -LiteralPath $env:GODOT_BIN) {
            $result.path = (Resolve-Path -LiteralPath $env:GODOT_BIN).Path
            $result.found = $true
            $result.source = "GODOT_BIN"
            return $result
        }
        $result.path = $env:GODOT_BIN
        $result.source = "GODOT_BIN_missing"
        return $result
    }

    foreach ($commandName in @("godot.exe", "godot_console.exe")) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($null -ne $command) {
            $result.path = $command.Source
            $result.found = $true
            $result.source = "PATH:$commandName"
            return $result
        }
    }

    $result.path = "godot.exe"
    return $result
}

function Resolve-PrimaryScreenBounds {
    $result = [ordered]@{
        available = $false
        width = 0
        height = 0
        source = "unavailable"
    }
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
        $result.available = $true
        $result.width = [int]$bounds.Width
        $result.height = [int]$bounds.Height
        $result.source = "System.Windows.Forms.Screen.PrimaryScreen.WorkingArea"
    } catch {
        $result.source = "System.Windows.Forms_unavailable"
    }
    return $result
}

function Resolve-WindowLayout {
    param(
        [int]$RequestedWidth,
        [int]$RequestedHeight,
        [int]$RequestedHostX,
        [int]$RequestedClientX,
        [int]$RequestedY,
        [bool]$DisableAutoFit
    )
    $screen = Resolve-PrimaryScreenBounds
    $gap = 32
    $rightMargin = 40
    $minWidth = 640
    $minHeight = 420
    $effective = [ordered]@{
        width = $RequestedWidth
        height = $RequestedHeight
        y = $RequestedY
        host_x = $RequestedHostX
        client_x = $RequestedClientX
    }
    $result = [ordered]@{
        auto_fit_attempted = $false
        auto_fit_applied = $false
        auto_fit_reason = ""
        screen = $screen
        requested = [ordered]@{
            width = $RequestedWidth
            height = $RequestedHeight
            y = $RequestedY
            host_x = $RequestedHostX
            client_x = $RequestedClientX
        }
        effective = $effective
    }
    if ($DisableAutoFit -or -not [bool]$screen.available) {
        return $result
    }
    $result.auto_fit_attempted = $true
    $screenWidth = [int]$screen.width
    $screenHeight = [int]$screen.height
    $requestedRight = [Math]::Max($RequestedHostX + $RequestedWidth, $RequestedClientX + $RequestedWidth)
    $requestedBottom = $RequestedY + $RequestedHeight
    if ($requestedRight -le ($screenWidth - 8) -and $requestedBottom -le ($screenHeight - 8)) {
        return $result
    }
    $usableWidth = [Math]::Max($screenWidth - $RequestedHostX - $rightMargin - $gap, $minWidth * 2 + $gap)
    $nextWidth = [Math]::Max([Math]::Min([int][Math]::Floor($usableWidth / 2), $RequestedWidth), $minWidth)
    $nextHeight = [Math]::Max([Math]::Min($RequestedHeight, $screenHeight - $RequestedY - $rightMargin), $minHeight)
    $effective.width = $nextWidth
    $effective.height = $nextHeight
    $effective.client_x = $RequestedHostX + $nextWidth + $gap
    $result.auto_fit_applied = $true
    $result.auto_fit_reason = "requested_layout_exceeded_primary_work_area"
    return $result
}

function Build-Args {
    param(
        [string]$Role,
        [int]$PeerId,
        [string]$Team,
        [int]$X
    )
    $args = @(
        "--path", $resolvedProjectPath,
        "--resolution", ("{0}x{1}" -f $WindowWidth, $WindowHeight),
        "--position", ("{0},{1}" -f $X, $Y),
        $Scene,
        "--",
        "--review-role=$Role",
        "--peer-id=$PeerId",
        "--team=$Team",
        "--task-id=TASK_611"
    )
    if (-not [string]::IsNullOrWhiteSpace($ScenarioPath)) {
        $args += "--scenario-file=$ScenarioPath"
    }
    return $args
}

$resolvedProjectPath = Resolve-ProjectPath $ProjectPath
$godot = Resolve-GodotCandidate $GodotBin
$layout = Resolve-WindowLayout -RequestedWidth $WindowWidth -RequestedHeight $WindowHeight -RequestedHostX $HostX -RequestedClientX $ClientX -RequestedY $Y -DisableAutoFit ([bool]$DisableAutoFitLayout)
$WindowWidth = [int]$layout.effective.width
$WindowHeight = [int]$layout.effective.height
$HostX = [int]$layout.effective.host_x
$ClientX = [int]$layout.effective.client_x
$Y = [int]$layout.effective.y
$tmpDir = Join-Path $resolvedProjectPath "tmp"
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null

$hostArgs = Build-Args -Role "host" -PeerId 1 -Team "team_alpha" -X $HostX
$clientArgs = Build-Args -Role "client" -PeerId 2 -Team "team_bravo" -X $ClientX

$plan = [ordered]@{
    schema = "sternenbuergerchen.host_client_two_window_launch_helper.v1"
    task_id = "TASK_611"
    launch_requested = [bool]$Launch
    launch_mode = $(if ($Launch) { "launch" } else { "dry_run" })
    read_only = $true
    ui_sets_gameplay_truth = $false
    project_path = $resolvedProjectPath
    scene = $Scene
    scenario_path = $ScenarioPath
    scenario_arg_included = -not [string]::IsNullOrWhiteSpace($ScenarioPath)
    godot_bin = $godot.path
    godot_bin_found = $godot.found
    godot_bin_source = $godot.source
    plan_path = "tmp/host_client_two_window_launch_plan.json"
    helper_path = "scripts/tools/launch_host_client_two_window_review.ps1"
    requested_window_layout = $layout.requested
    window_layout_auto_fit = [ordered]@{
        attempted = [bool]$layout.auto_fit_attempted
        applied = [bool]$layout.auto_fit_applied
        reason = [string]$layout.auto_fit_reason
        screen = $layout.screen
        disable_auto_fit = [bool]$DisableAutoFitLayout
    }
    window_layout = [ordered]@{
        width = $WindowWidth
        height = $WindowHeight
        y = $Y
        host_x = $HostX
        client_x = $ClientX
    }
    host = [ordered]@{
        role = "host"
        peer_id = 1
        team = "team_alpha"
        command_args = $hostArgs
        window = [ordered]@{ width = $WindowWidth; height = $WindowHeight; x = $HostX; y = $Y }
    }
    client = [ordered]@{
        role = "client"
        peer_id = 2
        team = "team_bravo"
        command_args = $clientArgs
        window = [ordered]@{ width = $WindowWidth; height = $WindowHeight; x = $ClientX; y = $Y }
    }
    launch_command = $(if ([string]::IsNullOrWhiteSpace($ScenarioPath)) { "powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1 -Launch" } else { "powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1 -Launch -ScenarioPath `"$ScenarioPath`"" })
    recommended_next_task = "TASK_612 - Host Client Two Window Screenshot Review"
}

$planPath = Join-Path $tmpDir "host_client_two_window_launch_plan.json"
$plan | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $planPath -Encoding UTF8

Write-Host ("TASK_611 launch plan written: {0}" -f $planPath)
Write-Host ("Mode: {0}; Godot: {1}; found={2}" -f $plan.launch_mode, $plan.godot_bin, $plan.godot_bin_found)

if ($Launch) {
    if (-not $godot.found) {
        throw "Godot executable was not found. Set -GodotBin or GODOT_BIN before using -Launch."
    }
    Write-Host "Starting visible Host and Client windows for manual review."
    Start-Process -FilePath $godot.path -ArgumentList $hostArgs -WorkingDirectory $resolvedProjectPath
    Start-Sleep -Milliseconds 700
    Start-Process -FilePath $godot.path -ArgumentList $clientArgs -WorkingDirectory $resolvedProjectPath
} else {
    Write-Host "Dry run only. Add -Launch to start visible Host and Client windows."
}
