param(
    [switch]$Launch,
    [switch]$CloseAfterCapture,
    [int]$WaitSeconds = 8,
    [string]$ProjectPath = "",
    [string]$PlanPath = "",
    [string]$ScreenshotPath = ""
)

$ErrorActionPreference = "Stop"

function Resolve-ProjectPath {
    param([string]$Candidate)
    if (-not [string]::IsNullOrWhiteSpace($Candidate)) {
        return (Resolve-Path -LiteralPath $Candidate).Path
    }
    return (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path
}

function ConvertTo-ArgumentList {
    param([object[]]$Values)
    $args = New-Object System.Collections.Generic.List[string]
    foreach ($value in $Values) {
        $args.Add([string]$value)
    }
    return $args.ToArray()
}

function Capture-Desktop {
    param([string]$Path)
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Windows.Forms
    $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bitmap = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
        $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

$resolvedProjectPath = Resolve-ProjectPath $ProjectPath
$tmpDir = Join-Path $resolvedProjectPath "tmp"
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null

if ([string]::IsNullOrWhiteSpace($PlanPath)) {
    $PlanPath = Join-Path $tmpDir "host_client_two_window_launch_plan.json"
}
if ([string]::IsNullOrWhiteSpace($ScreenshotPath)) {
    $ScreenshotPath = Join-Path $tmpDir "host_client_two_window_real_run_desktop.png"
}
$manifestPath = Join-Path $tmpDir "host_client_two_window_real_run_review.json"

if (-not (Test-Path -LiteralPath $PlanPath)) {
    throw "Launch plan not found: $PlanPath. Run scripts/tools/launch_host_client_two_window_review.ps1 first."
}

$plan = Get-Content -LiteralPath $PlanPath -Raw | ConvertFrom-Json
$hostProcess = $null
$clientProcess = $null
$captureAttempted = $false
$screenshotWritten = $false
$launchError = ""

if ($Launch) {
    if (-not [bool]$plan.godot_bin_found -or -not (Test-Path -LiteralPath ([string]$plan.godot_bin))) {
        throw "Godot executable was not found in the launch plan. Rebuild the plan with -GodotBin or GODOT_BIN."
    }
    $godotBin = [string]$plan.godot_bin
    $hostArgs = ConvertTo-ArgumentList $plan.host.command_args
    $clientArgs = ConvertTo-ArgumentList $plan.client.command_args
    Write-Host "Starting visible TASK_614 Host window."
    $hostProcess = Start-Process -FilePath $godotBin -ArgumentList $hostArgs -WorkingDirectory $resolvedProjectPath -PassThru
    Start-Sleep -Milliseconds 900
    Write-Host "Starting visible TASK_614 Client window."
    $clientProcess = Start-Process -FilePath $godotBin -ArgumentList $clientArgs -WorkingDirectory $resolvedProjectPath -PassThru
    Start-Sleep -Seconds ([Math]::Max(1, $WaitSeconds))
    try {
        Capture-Desktop -Path $ScreenshotPath
        $captureAttempted = $true
        $screenshotWritten = Test-Path -LiteralPath $ScreenshotPath
    } catch {
        $captureAttempted = $true
        $launchError = $_.Exception.Message
    }
    if ($CloseAfterCapture) {
        foreach ($process in @($clientProcess, $hostProcess)) {
            if ($null -ne $process -and -not $process.HasExited) {
                Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            }
        }
    }
} else {
    Write-Host "TASK_614 dry run only. Add -Launch to start visible Host and Client windows."
}

$manifest = [ordered]@{
    schema = "sternenbuergerchen.host_client_two_window_real_run_review.v1"
    task_id = "TASK_614"
    source_plan_task_id = [string]$plan.task_id
    source_plan_path = "tmp/host_client_two_window_launch_plan.json"
    tool_path = "scripts/tools/capture_host_client_two_window_real_run.ps1"
    manifest_path = "tmp/host_client_two_window_real_run_review.json"
    screenshot_path = "tmp/host_client_two_window_real_run_desktop.png"
    launch_requested = [bool]$Launch
    real_run_done = [bool]($Launch -and $screenshotWritten)
    capture_attempted = [bool]$captureAttempted
    screenshot_written = [bool]$screenshotWritten
    close_after_capture = [bool]$CloseAfterCapture
    wait_seconds = $WaitSeconds
    host_process_id = $(if ($null -ne $hostProcess) { $hostProcess.Id } else { $null })
    client_process_id = $(if ($null -ne $clientProcess) { $clientProcess.Id } else { $null })
    host_role = [string]$plan.host.role
    client_role = [string]$plan.client.role
    manual_review_required = $true
    manual_review_done = $false
    read_only = $true
    ui_sets_gameplay_truth = $false
    launch_error = $launchError
    review_checks = @(
        "both_windows_visible",
        "host_role_readable",
        "client_role_readable",
        "authority_feedback_readable",
        "snapshot_sync_readable",
        "f6_readability",
        "performance_feel",
        "close_processes_after_capture"
    )
    recommended_next_task = "TASK_615 - Host Client Real Run Findings"
}

$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
Write-Host ("TASK_614 manifest written: {0}" -f $manifestPath)
Write-Host ("Launch requested={0}; real_run_done={1}; screenshot_written={2}" -f $manifest.launch_requested, $manifest.real_run_done, $manifest.screenshot_written)
