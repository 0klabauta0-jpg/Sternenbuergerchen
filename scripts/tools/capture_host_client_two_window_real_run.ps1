param(
    [switch]$Launch,
    [switch]$CloseAfterCapture,
    [int]$WaitSeconds = 8,
    [string]$ProjectPath = "",
    [string]$PlanPath = "",
    [string]$ScreenshotPath = "",
    [string]$HostScreenshotPath = "",
    [string]$ClientScreenshotPath = ""
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

function ConvertTo-TeamBadgeLabel {
    param([string]$TeamId)
    $normalized = ([string]$TeamId).Trim().ToLowerInvariant()
    switch ($normalized) {
        "team_alpha" { return "ALPHA" }
        "team_bravo" { return "BRAVO" }
        default {
            if ($normalized.StartsWith("team_")) {
                $normalized = $normalized.Substring(5)
            }
            return $normalized.ToUpperInvariant()
        }
    }
}

function Build-ExpectedReviewBadgeText {
    param([object]$Session)
    if ($null -eq $Session) {
        return ""
    }
    $tokens = New-Object System.Collections.Generic.List[string]
    $role = ([string]$Session.role).Trim()
    if (-not [string]::IsNullOrWhiteSpace($role)) {
        $tokens.Add($role.ToUpperInvariant())
    }
    $peerId = 0
    if ([int]::TryParse(([string]$Session.peer_id), [ref]$peerId) -and $peerId -gt 0) {
        $tokens.Add(("P{0}" -f $peerId))
    }
    $teamLabel = ConvertTo-TeamBadgeLabel ([string]$Session.team)
    if (-not [string]::IsNullOrWhiteSpace($teamLabel)) {
        $tokens.Add($teamLabel)
    }
    return ($tokens -join " ")
}

function Resolve-VisibleGodotBinary {
    param([string]$PlannedPath)
    $result = [ordered]@{
        path = $PlannedPath
        source = "planned"
        console_replaced = $false
        found = $false
    }
    if (-not [string]::IsNullOrWhiteSpace($PlannedPath) -and (Test-Path -LiteralPath $PlannedPath)) {
        $result.found = $true
        $fileName = [System.IO.Path]::GetFileName($PlannedPath)
        if ($fileName -ieq "godot_console.exe") {
            $sibling = Join-Path ([System.IO.Path]::GetDirectoryName($PlannedPath)) "godot.exe"
            if (Test-Path -LiteralPath $sibling) {
                $result.path = (Resolve-Path -LiteralPath $sibling).Path
                $result.source = "sibling_gui_binary"
                $result.console_replaced = $true
                return $result
            }
        }
        return $result
    }
    $guiCommand = Get-Command "godot.exe" -ErrorAction SilentlyContinue
    if ($null -ne $guiCommand) {
        $result.path = $guiCommand.Source
        $result.source = "PATH:godot.exe"
        $result.console_replaced = $true
        $result.found = $true
    }
    return $result
}

function Ensure-User32Tools {
    if ("Win32.Task615WindowTools" -as [type]) {
        return
    }
    Add-Type @"
using System;
using System.Runtime.InteropServices;
namespace Win32 {
    public static class Task615WindowTools {
        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
        [DllImport("user32.dll")]
        public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
        [DllImport("user32.dll", SetLastError=true)]
        public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, UInt32 uFlags);
    }
}
"@
}

function Focus-ReviewWindow {
    param(
        [System.Diagnostics.Process]$Process,
        [object]$Window
    )
    $result = [ordered]@{
        focus_attempted = $false
        focus_succeeded = $false
        position_attempted = $false
        position_succeeded = $false
        raise_attempted = $false
        raise_succeeded = $false
        main_window_handle = 0
    }
    if ($null -eq $Process) {
        return $result
    }
    Ensure-User32Tools
    for ($attempt = 0; $attempt -lt 30; $attempt++) {
        Start-Sleep -Milliseconds 150
        $Process.Refresh()
        if ($Process.MainWindowHandle -ne 0) {
            break
        }
    }
    $handle = $Process.MainWindowHandle
    $result.main_window_handle = [int64]$handle
    if ($handle -eq 0) {
        return $result
    }
    $result.focus_attempted = $true
    [Win32.Task615WindowTools]::ShowWindow($handle, 5) | Out-Null
    $result.focus_succeeded = [Win32.Task615WindowTools]::SetForegroundWindow($handle)
    if ($null -ne $Window) {
        $result.position_attempted = $true
        $result.position_succeeded = [Win32.Task615WindowTools]::MoveWindow(
            $handle,
            [int]$Window.x,
            [int]$Window.y,
            [int]$Window.width,
            [int]$Window.height,
            $true
        )
        $result.raise_attempted = $true
        $result.raise_succeeded = [Win32.Task615WindowTools]::SetWindowPos(
            $handle,
            [IntPtr](-1),
            [int]$Window.x,
            [int]$Window.y,
            [int]$Window.width,
            [int]$Window.height,
            [uint32]0x0040
        )
    }
    return $result
}

function Release-ReviewWindowTopmost {
    param(
        [System.Diagnostics.Process]$Process,
        [object]$Window
    )
    if ($null -eq $Process -or $null -eq $Window) {
        return
    }
    $Process.Refresh()
    $handle = $Process.MainWindowHandle
    if ($handle -eq 0) {
        return
    }
    [Win32.Task615WindowTools]::SetWindowPos(
        $handle,
        [IntPtr](-2),
        [int]$Window.x,
        [int]$Window.y,
        [int]$Window.width,
        [int]$Window.height,
        [uint32]0x0040
    ) | Out-Null
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

function Export-DesktopCrop {
    param(
        [string]$SourcePath,
        [string]$DestinationPath,
        [object]$Window
    )
    $result = [ordered]@{
        attempted = $false
        succeeded = $false
        reason = ""
        width = 0
        height = 0
    }
    if ([string]::IsNullOrWhiteSpace($SourcePath) -or [string]::IsNullOrWhiteSpace($DestinationPath) -or $null -eq $Window) {
        $result.reason = "missing_source_destination_or_window"
        return $result
    }
    if (-not (Test-Path -LiteralPath $SourcePath)) {
        $result.reason = "source_screenshot_missing"
        return $result
    }
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Windows.Forms
    $result.attempted = $true
    $screenBounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $left = [Math]::Max(0, [int]$Window.x - [int]$screenBounds.X)
    $top = [Math]::Max(0, [int]$Window.y - [int]$screenBounds.Y)
    $width = [Math]::Min([int]$Window.width, [int]$screenBounds.Width - $left)
    $height = [Math]::Min([int]$Window.height, [int]$screenBounds.Height - $top)
    if ($width -le 0 -or $height -le 0) {
        $result.reason = "window_outside_primary_screen"
        return $result
    }
    $source = [System.Drawing.Bitmap]::FromFile($SourcePath)
    $crop = $null
    try {
        $rect = New-Object System.Drawing.Rectangle $left, $top, $width, $height
        $crop = $source.Clone($rect, $source.PixelFormat)
        $crop.Save($DestinationPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $result.succeeded = Test-Path -LiteralPath $DestinationPath
        $result.width = $width
        $result.height = $height
        if (-not $result.succeeded) {
            $result.reason = "crop_write_failed"
        }
    } finally {
        if ($null -ne $crop) {
            $crop.Dispose()
        }
        $source.Dispose()
    }
    return $result
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
if ([string]::IsNullOrWhiteSpace($HostScreenshotPath)) {
    $HostScreenshotPath = Join-Path $tmpDir "host_client_two_window_host_review.png"
}
if ([string]::IsNullOrWhiteSpace($ClientScreenshotPath)) {
    $ClientScreenshotPath = Join-Path $tmpDir "host_client_two_window_client_review.png"
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
$plannedGodotBin = ""
$visibleGodotBin = ""
$visibleGodotBinSource = ""
$consoleBinaryReplaced = $false
$hostWindowStatus = [ordered]@{}
$clientWindowStatus = [ordered]@{}
$initialHostWindowStatus = [ordered]@{}
$initialClientWindowStatus = [ordered]@{}
$hostCropStatus = [ordered]@{}
$clientCropStatus = [ordered]@{}
$hostScreenshotWritten = $false
$clientScreenshotWritten = $false
$hostExpectedBadgeText = Build-ExpectedReviewBadgeText $plan.host
$clientExpectedBadgeText = Build-ExpectedReviewBadgeText $plan.client

if ($Launch) {
    if (-not [bool]$plan.godot_bin_found -or -not (Test-Path -LiteralPath ([string]$plan.godot_bin))) {
        throw "Godot executable was not found in the launch plan. Rebuild the plan with -GodotBin or GODOT_BIN."
    }
    $plannedGodotBin = [string]$plan.godot_bin
    $visibleGodot = Resolve-VisibleGodotBinary $plannedGodotBin
    if (-not [bool]$visibleGodot.found -or -not (Test-Path -LiteralPath ([string]$visibleGodot.path))) {
        throw "Visible Godot executable was not found. Planned path: $plannedGodotBin."
    }
    $godotBin = [string]$visibleGodot.path
    $visibleGodotBin = $godotBin
    $visibleGodotBinSource = [string]$visibleGodot.source
    $consoleBinaryReplaced = [bool]$visibleGodot.console_replaced
    $hostArgs = ConvertTo-ArgumentList $plan.host.command_args
    $clientArgs = ConvertTo-ArgumentList $plan.client.command_args
    Write-Host "Starting visible TASK_614 Host window."
    $hostProcess = Start-Process -FilePath $godotBin -ArgumentList $hostArgs -WorkingDirectory $resolvedProjectPath -PassThru
    $initialHostWindowStatus = Focus-ReviewWindow -Process $hostProcess -Window $plan.host.window
    Start-Sleep -Milliseconds 350
    Write-Host "Starting visible TASK_614 Client window."
    $clientProcess = Start-Process -FilePath $godotBin -ArgumentList $clientArgs -WorkingDirectory $resolvedProjectPath -PassThru
    $initialClientWindowStatus = Focus-ReviewWindow -Process $clientProcess -Window $plan.client.window
    Start-Sleep -Seconds ([Math]::Max(1, $WaitSeconds))
    $hostWindowStatus = Focus-ReviewWindow -Process $hostProcess -Window $plan.host.window
    $clientWindowStatus = Focus-ReviewWindow -Process $clientProcess -Window $plan.client.window
    Start-Sleep -Milliseconds 350
    try {
        Capture-Desktop -Path $ScreenshotPath
        $captureAttempted = $true
        $screenshotWritten = Test-Path -LiteralPath $ScreenshotPath
        if ($screenshotWritten) {
            $hostCropStatus = Export-DesktopCrop -SourcePath $ScreenshotPath -DestinationPath $HostScreenshotPath -Window $plan.host.window
            $clientCropStatus = Export-DesktopCrop -SourcePath $ScreenshotPath -DestinationPath $ClientScreenshotPath -Window $plan.client.window
            $hostScreenshotWritten = Test-Path -LiteralPath $HostScreenshotPath
            $clientScreenshotWritten = Test-Path -LiteralPath $ClientScreenshotPath
        }
    } catch {
        $captureAttempted = $true
        $launchError = $_.Exception.Message
    }
    Release-ReviewWindowTopmost -Process $clientProcess -Window $plan.client.window
    Release-ReviewWindowTopmost -Process $hostProcess -Window $plan.host.window
    if ($CloseAfterCapture) {
        foreach ($process in @($clientProcess, $hostProcess)) {
            if ($null -ne $process -and -not $process.HasExited) {
                Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            }
        }
    }
} else {
    Write-Host "TASK_614 dry run only. Add -Launch to start visible Host and Client windows."
    $plannedGodotBin = [string]$plan.godot_bin
    $visibleGodot = Resolve-VisibleGodotBinary $plannedGodotBin
    $visibleGodotBin = [string]$visibleGodot.path
    $visibleGodotBinSource = [string]$visibleGodot.source
    $consoleBinaryReplaced = [bool]$visibleGodot.console_replaced
}

$visibleRejectReviewReady = [bool]($Launch -and $screenshotWritten -and $hostScreenshotWritten -and $clientScreenshotWritten)
$decisionDrillPacketPath = Join-Path $tmpDir "host_client_decision_drill_click_evidence.json"
$decisionDrillPacketPresent = Test-Path -LiteralPath $decisionDrillPacketPath

$manifest = [ordered]@{
    schema = "sternenbuergerchen.host_client_two_window_real_run_review.v1"
    task_id = "TASK_614"
    source_plan_task_id = [string]$plan.task_id
    source_plan_path = "tmp/host_client_two_window_launch_plan.json"
    tool_path = "scripts/tools/capture_host_client_two_window_real_run.ps1"
    manifest_path = "tmp/host_client_two_window_real_run_review.json"
    screenshot_path = "tmp/host_client_two_window_real_run_desktop.png"
    host_screenshot_path = "tmp/host_client_two_window_host_review.png"
    client_screenshot_path = "tmp/host_client_two_window_client_review.png"
    launch_requested = [bool]$Launch
    real_run_done = [bool]($Launch -and $screenshotWritten)
    capture_attempted = [bool]$captureAttempted
    screenshot_written = [bool]$screenshotWritten
    host_screenshot_written = [bool]$hostScreenshotWritten
    client_screenshot_written = [bool]$clientScreenshotWritten
    host_crop_status = $hostCropStatus
    client_crop_status = $clientCropStatus
    badge_recapture_task_id = "TASK_620"
    badge_recapture_review_required = $true
    badge_recapture_review_done = [bool]($Launch -and $screenshotWritten -and $hostScreenshotWritten -and $clientScreenshotWritten)
    badge_recapture_gate = $(if ($Launch -and $screenshotWritten -and $hostScreenshotWritten -and $clientScreenshotWritten -and -not [string]::IsNullOrWhiteSpace($hostExpectedBadgeText) -and -not [string]::IsNullOrWhiteSpace($clientExpectedBadgeText)) { "review_ready" } else { "manual_open" })
    host_expected_badge_text = $hostExpectedBadgeText
    client_expected_badge_text = $clientExpectedBadgeText
    badge_expected_style_id = "host_client_role_peer_badge_v1"
    badge_expected_hud_path = "MissionIdentityHeaderLabel"
    host_badge_crop_path = "tmp/host_client_two_window_host_review.png"
    client_badge_crop_path = "tmp/host_client_two_window_client_review.png"
    real_click_review_task_id = "TASK_626"
    visible_reject_expected_text = "BLOCK P2 wrong team"
    visible_reject_expected_action_text = "USE BRAVO"
    visible_reject_expected_next_action_text = "Use BRAVO fireteam."
    visible_reject_expected_next_action_detail = "Peer 2 should command the BRAVO fireteam instead of this target."
    visible_reject_expected_authority_text = "AUTH OK1/RJ2"
    visible_reject_expected_feedback_line = "AUTH BLOCKED P2: wrong team"
    visible_reject_expected_raw_reason = "peer_team_mismatch"
    visible_reject_expected_hud_path = "MissionTeamChipLabel"
    visible_reject_review_required = $true
    visible_reject_review_done = $false
    visible_reject_review_gate = $(if ($visibleRejectReviewReady) { "review_ready" } else { "manual_open" })
    visible_reject_manual_checks = @(
        "peer2_alpha_reject_clicked",
        "block_cue_visible",
        "action_cue_visible",
        "authority_status_visible",
        "raw_reason_in_tooltip",
        "input_latency_noted",
        "snapshot_sync_after_reject",
        "host_client_focus_recovered"
    )
    decision_drill_capture_task_id = "TASK_662"
    decision_drill_source_packet_task_id = "TASK_661"
    decision_drill_source_packet_path = "tmp/host_client_decision_drill_click_evidence.json"
    decision_drill_source_packet_present = [bool]$decisionDrillPacketPresent
    decision_drill_expected_wrong_context_reason = "peer_team_mismatch"
    decision_drill_expected_block_text = "BLOCK P2 wrong team"
    decision_drill_expected_action_text = "USE BRAVO"
    decision_drill_expected_next_token = "AA"
    decision_drill_expected_recommended_plan_id = "aa_first_push"
    decision_drill_expected_correct_fireteam = "bravo"
    decision_drill_expected_confirm_control = "GO"
    decision_drill_review_required = $true
    decision_drill_review_done = $false
    decision_drill_review_gate = $(if ($visibleRejectReviewReady -and $decisionDrillPacketPresent) { "review_ready" } else { "manual_open" })
    decision_drill_manual_checks = @(
        "peer2_alpha_reject_clicked",
        "use_bravo_visible",
        "bravo_context_selected",
        "next_aa_visible_after_context_switch",
        "move_preview_readable_before_go",
        "go_feedback_visible_after_confirm"
    )
    door_real_click_manual_run_task_id = "TASK_705"
    door_real_click_source_findings_task_id = "TASK_704"
    door_real_click_source_workbench_task_id = "TASK_700"
    door_real_click_workbench_path = "docs/reports/host_client_door_real_click_workbench_2026_06_30.html"
    door_real_click_findings_manifest_path = "tmp/host_client_door_real_click_findings.json"
    door_real_click_workbench_manifest_path = "tmp/host_client_door_real_click_workbench.json"
    door_real_click_expected_button = "DoorBreachButton"
    door_real_click_expected_shortcut = "B"
    door_real_click_expected_go_control = "GO"
    door_real_click_expected_ready_line = "DOOR DOOR B->GO"
    door_real_click_expected_wrong_team_reason = "peer_team_mismatch"
    door_real_click_expected_open_line = "DOOR DOOR OPEN"
    door_real_click_expected_hud_surface = "mission_interaction_door_authority_visible_line"
    door_real_click_manual_review_required = $true
    door_real_click_manual_review_done = $false
    door_real_click_manual_run_gate = $(if ($visibleRejectReviewReady) { "review_ready" } else { "manual_open" })
    door_real_click_manual_checks = @(
        "host_window_launched",
        "client_window_launched",
        "host_door_button_visible",
        "client_door_button_visible",
        "shortcut_b_triggers_hook",
        "go_required_visible",
        "wrong_team_reject_visible",
        "door_open_visible_on_host",
        "door_open_visible_on_client",
        "hud_feedback_readable",
        "workbench_notes_exported"
    )
    station_route_host_client_acceptance_task_id = "TASK_712"
    station_route_source_visual_evidence_task_id = "TASK_708"
    station_route_source_window_notes_task_id = "TASK_709"
    station_route_source_readiness_task_id = "TASK_710"
    station_route_visual_evidence_manifest_path = "tmp/station_route_visual_evidence.json"
    station_route_window_notes_workbench_path = "docs/reports/station_route_window_playtest_notes_2026_07_01.html"
    station_route_window_notes_manifest_path = "tmp/station_route_window_playtest_notes.json"
    station_route_readiness_manifest_path = "tmp/station_route_polish_readiness_findings.json"
    station_route_expected_sequence = @(
        "door_open",
        "computer_controlled",
        "cargo_departed"
    )
    station_route_expected_door_line = "DOOR DOOR OPEN"
    station_route_expected_computer_line = "COMPUTER CONTROLLED"
    station_route_expected_cargo_line = "CARGO DEPARTED"
    station_route_expected_wrong_team_reason = "peer_team_mismatch"
    station_route_expected_snapshot_sync = "client_snapshot_apply_accepted"
    station_route_expected_hud_surfaces = @(
        "mission_interaction_door_authority_visible_line",
        "mission_interaction_objective_next_line",
        "mission_interaction_command_feedback_line"
    )
    station_route_host_client_acceptance_review_required = $true
    station_route_host_client_acceptance_review_done = $false
    station_route_host_client_acceptance_gate = $(if ($visibleRejectReviewReady) { "review_ready" } else { "manual_open" })
    station_route_host_client_manual_checks = @(
        "host_window_launched",
        "client_window_launched",
        "host_station_route_visible",
        "client_station_route_visible",
        "door_open_visible_on_host",
        "door_open_visible_on_client",
        "computer_control_visible_after_door",
        "cargo_departed_visible_after_computer",
        "wrong_team_reject_visible",
        "snapshot_sync_after_each_step",
        "hud_feedback_readable",
        "window_notes_exported"
    )
    close_after_capture = [bool]$CloseAfterCapture
    wait_seconds = $WaitSeconds
    planned_godot_bin = $plannedGodotBin
    visible_godot_bin = $visibleGodotBin
    visible_godot_bin_source = $visibleGodotBinSource
    console_binary_replaced = [bool]$consoleBinaryReplaced
    window_focus_attempted = [bool]($hostWindowStatus.focus_attempted -or $clientWindowStatus.focus_attempted)
    window_position_attempted = [bool]($hostWindowStatus.position_attempted -or $clientWindowStatus.position_attempted)
    window_raise_attempted = [bool]($hostWindowStatus.raise_attempted -or $clientWindowStatus.raise_attempted)
    initial_host_window_status = $initialHostWindowStatus
    initial_client_window_status = $initialClientWindowStatus
    host_window_status = $hostWindowStatus
    client_window_status = $clientWindowStatus
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
        "visible_reject_feedback_readable",
        "visible_reject_action_cue_readable",
        "peer2_alpha_reject_click_review",
        "decision_drill_use_bravo_visible",
        "decision_drill_bravo_context_selected",
        "decision_drill_next_aa_visible",
        "decision_drill_preview_before_go",
        "decision_drill_go_feedback_visible",
        "door_real_click_host_button_visible",
        "door_real_click_client_button_visible",
        "door_real_click_shortcut_b",
        "door_real_click_go_required",
        "door_real_click_wrong_team_reject",
        "door_real_click_open_visible_host_client",
        "door_real_click_hud_readable",
        "station_route_host_window_visible",
        "station_route_client_window_visible",
        "station_route_door_open_host_client",
        "station_route_computer_control_visible",
        "station_route_cargo_departed_visible",
        "station_route_wrong_team_reject",
        "station_route_snapshot_sync",
        "station_route_window_notes_exported",
        "input_latency_after_reject",
        "f6_readability",
        "performance_feel",
        "close_processes_after_capture"
    )
    recommended_next_task = "TASK_615 - Host Client Real Run Findings"
    recommended_next_visible_review_task = "TASK_616 - Host Client Visible UI Real Run Review"
    recommended_next_capture_task = "TASK_618 - Host Client Standard Capture Crop Review"
    recommended_next_badge_review_task = "TASK_620 - Host Client Badge Re-Capture Review"
    recommended_next_real_click_review_task = "TASK_626 - Host Client Real Click Review Evidence"
    recommended_next_decision_drill_capture_task = "TASK_663 - Host Client Decision Drill Visual Findings"
    recommended_next_door_real_click_manual_run_task = "TASK_705 - Host/Client Door Real Click Manual Run Packet"
    recommended_next_door_real_click_after_manual_task = "TASK_706 - Mission Door Layout/Visual Polish"
    recommended_next_station_route_host_client_acceptance_task = "TASK_712 - Station Route Host/Client Acceptance Packet"
    recommended_next_station_route_after_acceptance_task = "TASK_713 - Station Route Host/Client Findings"
}

$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
Write-Host ("TASK_614 manifest written: {0}" -f $manifestPath)
Write-Host ("Launch requested={0}; real_run_done={1}; screenshot_written={2}" -f $manifest.launch_requested, $manifest.real_run_done, $manifest.screenshot_written)
