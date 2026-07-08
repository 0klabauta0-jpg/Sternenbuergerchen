param(
	[string]$ContractPath = "",
	[string]$OutputDirectory = "",
	[int]$ProcessId = 0,
	[switch]$SkipFocusWindow,
	[switch]$JsonOnly
)

$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
	$scriptDirectory = Split-Path -Parent $PSCommandPath
	return (Resolve-Path (Join-Path $scriptDirectory "..\..")).Path
}

function Read-JsonFile {
	param([string]$Path)
	if (-not (Test-Path -LiteralPath $Path)) {
		throw "Missing JSON file: $Path"
	}
	return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Resolve-FullPathFromRoot {
	param(
		[string]$Root,
		[string]$PathValue
	)
	if ([System.IO.Path]::IsPathRooted($PathValue)) {
		return [System.IO.Path]::GetFullPath($PathValue)
	}
	return [System.IO.Path]::GetFullPath((Join-Path $Root $PathValue))
}

function Get-GitValue {
	param([string[]]$Arguments)
	try {
		$previousLocation = Get-Location
		Set-Location $script:repoRoot
		$value = (& git @Arguments 2>$null)
		Set-Location $previousLocation
		return [string]$value
	} catch {
		try { Set-Location $previousLocation } catch {}
		return ""
	}
}

function Get-ReleaseProcesses {
	param(
		[string]$ExePath,
		[string]$ConsoleExePath
	)
	$targets = @(
		[System.IO.Path]::GetFullPath($ExePath).ToLowerInvariant(),
		[System.IO.Path]::GetFullPath($ConsoleExePath).ToLowerInvariant()
	)
	$matches = @()
	$processes = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue
	foreach ($process in $processes) {
		if ([string]::IsNullOrWhiteSpace($process.ExecutablePath)) {
			continue
		}
		$processPath = [System.IO.Path]::GetFullPath([string]$process.ExecutablePath).ToLowerInvariant()
		if ($targets -contains $processPath) {
			$matches += [ordered]@{
				process_id = [int]$process.ProcessId
				name = [string]$process.Name
				executable_path = [string]$process.ExecutablePath
			}
		}
	}
	return @($matches)
}

function Ensure-User32Tools {
	if ("Win32.ReleaseSingleplayerWindowTools" -as [type]) {
		return
	}
	Add-Type @"
using System;
using System.Runtime.InteropServices;
namespace Win32 {
	public static class ReleaseSingleplayerWindowTools {
		[DllImport("user32.dll")]
		public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
		[DllImport("user32.dll")]
		public static extern bool SetForegroundWindow(IntPtr hWnd);
		[DllImport("user32.dll")]
		public static extern IntPtr GetForegroundWindow();
		[DllImport("user32.dll")]
		public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
		[DllImport("user32.dll")]
		public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
		[DllImport("user32.dll")]
		public static extern bool GetClientRect(IntPtr hWnd, out RECT lpRect);
		[DllImport("user32.dll")]
		public static extern bool ClientToScreen(IntPtr hWnd, ref POINT lpPoint);
		[DllImport("user32.dll")]
		public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, uint nFlags);
		public struct RECT {
			public int Left;
			public int Top;
			public int Right;
			public int Bottom;
		}
		public struct POINT {
			public int X;
			public int Y;
		}
	}
}
"@
}

function Get-WindowSnapshot {
	param(
		[int]$SelectedProcessId,
		[bool]$ShouldFocus
	)
	$result = [ordered]@{
		process_id = $SelectedProcessId
		window_handle_found = $false
		main_window_handle = 0
		focus_attempted = $false
		focus_succeeded = $false
		rect_found = $false
		rect = $null
		client_rect_found = $false
		client_rect = $null
		foreground_process_id = 0
		foreground_matches_selected_process = $false
	}
	if ($SelectedProcessId -le 0) {
		return $result
	}
	$process = Get-Process -Id $SelectedProcessId -ErrorAction SilentlyContinue
	if ($null -eq $process) {
		return $result
	}
	Ensure-User32Tools
	for ($attempt = 0; $attempt -lt 20; $attempt++) {
		$process.Refresh()
		if ($process.MainWindowHandle -ne 0) {
			break
		}
		Start-Sleep -Milliseconds 100
	}
	$handle = $process.MainWindowHandle
	$result.main_window_handle = [int64]$handle
	if ($handle -eq 0) {
		return $result
	}
	$result.window_handle_found = $true
	if ($ShouldFocus) {
		$result.focus_attempted = $true
		[Win32.ReleaseSingleplayerWindowTools]::ShowWindow($handle, 5) | Out-Null
		$result.focus_succeeded = [Win32.ReleaseSingleplayerWindowTools]::SetForegroundWindow($handle)
		Start-Sleep -Milliseconds 200
	}
	$foregroundHandle = [Win32.ReleaseSingleplayerWindowTools]::GetForegroundWindow()
	if ($foregroundHandle -ne [IntPtr]::Zero) {
		[uint32]$foregroundProcessId = 0
		[Win32.ReleaseSingleplayerWindowTools]::GetWindowThreadProcessId($foregroundHandle, [ref]$foregroundProcessId) | Out-Null
		$result.foreground_process_id = [int]$foregroundProcessId
		$result.foreground_matches_selected_process = ([int]$foregroundProcessId -eq $SelectedProcessId)
	}
	$rect = New-Object Win32.ReleaseSingleplayerWindowTools+RECT
	if ([Win32.ReleaseSingleplayerWindowTools]::GetWindowRect($handle, [ref]$rect)) {
		$width = [int]$rect.Right - [int]$rect.Left
		$height = [int]$rect.Bottom - [int]$rect.Top
		if ($width -gt 0 -and $height -gt 0) {
			$result.rect_found = $true
			$result.rect = [ordered]@{
				x = [int]$rect.Left
				y = [int]$rect.Top
				width = $width
				height = $height
			}
		}
	}
	$clientRect = New-Object Win32.ReleaseSingleplayerWindowTools+RECT
	$clientOrigin = New-Object Win32.ReleaseSingleplayerWindowTools+POINT
	if ([Win32.ReleaseSingleplayerWindowTools]::GetClientRect($handle, [ref]$clientRect) -and [Win32.ReleaseSingleplayerWindowTools]::ClientToScreen($handle, [ref]$clientOrigin)) {
		$clientWidth = [int]$clientRect.Right - [int]$clientRect.Left
		$clientHeight = [int]$clientRect.Bottom - [int]$clientRect.Top
		if ($clientWidth -gt 0 -and $clientHeight -gt 0) {
			$result.client_rect_found = $true
			$result.client_rect = [ordered]@{
				x = [int]$clientOrigin.X
				y = [int]$clientOrigin.Y
				width = $clientWidth
				height = $clientHeight
			}
		}
	}
	return $result
}

function Capture-WindowHandle {
	param(
		[object]$WindowSnapshot,
		[string]$Path
	)
	$result = [ordered]@{
		attempted = $false
		succeeded = $false
		reason = ""
		width = 0
		height = 0
	}
	if ($null -eq $WindowSnapshot -or -not [bool]$WindowSnapshot.window_handle_found) {
		$result.reason = "window_handle_missing"
		return $result
	}
	if ($null -eq $WindowSnapshot.rect) {
		$result.reason = "window_rect_missing"
		return $result
	}
	$handle = [IntPtr]([int64]$WindowSnapshot.main_window_handle)
	if ($handle -eq [IntPtr]::Zero) {
		$result.reason = "window_handle_zero"
		return $result
	}
	$width = [int]$WindowSnapshot.rect.width
	$height = [int]$WindowSnapshot.rect.height
	if ($width -le 0 -or $height -le 0) {
		$result.reason = "window_rect_invalid"
		return $result
	}
	Add-Type -AssemblyName System.Drawing
	$result.attempted = $true
	$bitmap = New-Object System.Drawing.Bitmap $width, $height
	$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
	try {
		$hdc = $graphics.GetHdc()
		try {
			$printed = [Win32.ReleaseSingleplayerWindowTools]::PrintWindow($handle, $hdc, 2)
		} finally {
			$graphics.ReleaseHdc($hdc)
		}
		if (-not $printed) {
			$result.reason = "print_window_failed"
			return $result
		}
		$bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
		$result.succeeded = Test-Path -LiteralPath $Path
		$result.width = $width
		$result.height = $height
		if (-not $result.succeeded) {
			$result.reason = "window_handle_write_failed"
		}
	} finally {
		$graphics.Dispose()
		$bitmap.Dispose()
	}
	return $result
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
		[object]$WindowRect
	)
	$result = [ordered]@{
		attempted = $false
		succeeded = $false
		reason = ""
		width = 0
		height = 0
	}
	if ($null -eq $WindowRect) {
		$result.reason = "window_rect_missing"
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
	$left = [Math]::Max(0, [int]$WindowRect.x - [int]$screenBounds.X)
	$top = [Math]::Max(0, [int]$WindowRect.y - [int]$screenBounds.Y)
	$width = [Math]::Min([int]$WindowRect.width, [int]$screenBounds.Width - $left)
	$height = [Math]::Min([int]$WindowRect.height, [int]$screenBounds.Height - $top)
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

function Test-ImageNonBlank {
	param([string]$Path)
	$result = [ordered]@{
		checked = $false
		nonblank = $false
		unique_sampled_colors = 0
		width = 0
		height = 0
	}
	if (-not (Test-Path -LiteralPath $Path)) {
		return $result
	}
	Add-Type -AssemblyName System.Drawing
	$bitmap = [System.Drawing.Bitmap]::FromFile($Path)
	try {
		$result.checked = $true
		$result.width = [int]$bitmap.Width
		$result.height = [int]$bitmap.Height
		$colors = New-Object "System.Collections.Generic.HashSet[string]"
		$xStep = [Math]::Max(1, [int]([double]$bitmap.Width / 32.0))
		$yStep = [Math]::Max(1, [int]([double]$bitmap.Height / 18.0))
		for ($y = 0; $y -lt $bitmap.Height; $y += $yStep) {
			for ($x = 0; $x -lt $bitmap.Width; $x += $xStep) {
				$color = $bitmap.GetPixel($x, $y)
				$colors.Add(("{0:X2}{1:X2}{2:X2}{3:X2}" -f $color.A, $color.R, $color.G, $color.B)) | Out-Null
			}
		}
		$result.unique_sampled_colors = [int]$colors.Count
		$result.nonblank = $colors.Count -gt 1
	} finally {
		$bitmap.Dispose()
	}
	return $result
}

$script:repoRoot = Resolve-RepoRoot
if ([string]::IsNullOrWhiteSpace($ContractPath)) {
	$ContractPath = Join-Path $script:repoRoot "data\export_runtime_package_contract.json"
}
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
	$OutputDirectory = Join-Path $script:repoRoot "tmp"
}
if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) {
	New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
}

$contract = Read-JsonFile -Path $ContractPath
$exePath = Resolve-FullPathFromRoot -Root $script:repoRoot -PathValue ([string]$contract.runtime_export_path)
$releaseDirectory = Split-Path -Parent $exePath
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($exePath)
$consoleExePath = Join-Path $releaseDirectory "$baseName.console.exe"
$runningProcesses = Get-ReleaseProcesses -ExePath $exePath -ConsoleExePath $consoleExePath

$hardFailures = @()
$warnings = @()
if (-not (Test-Path -LiteralPath $exePath -PathType Leaf)) {
	$hardFailures += "release_exe_missing"
}
if ($runningProcesses.Count -le 0) {
	$hardFailures += "release_process_not_running"
}

$selectedProcess = $null
if ($ProcessId -gt 0) {
	foreach ($process in $runningProcesses) {
		if ([int]$process.process_id -eq $ProcessId) {
			$selectedProcess = $process
			break
		}
	}
	if ($null -eq $selectedProcess) {
		$hardFailures += "requested_process_not_matching_release_path"
	}
} elseif ($runningProcesses.Count -gt 0) {
	$nonConsoleProcesses = @($runningProcesses | Where-Object { [string]$_.name -notlike "*.console.exe" })
	if ($nonConsoleProcesses.Count -gt 0) {
		$selectedProcess = $nonConsoleProcesses[0]
	} else {
		$selectedProcess = $runningProcesses[0]
	}
}

$selectedProcessId = 0
if ($null -ne $selectedProcess) {
	$selectedProcessId = [int]$selectedProcess.process_id
}

$desktopScreenshotPath = Join-Path $OutputDirectory "release_singleplayer_visible_window_desktop.png"
$windowHandleScreenshotPath = Join-Path $OutputDirectory "release_singleplayer_visible_window_handle.png"
$desktopCropScreenshotPath = Join-Path $OutputDirectory "release_singleplayer_visible_window_desktop_crop.png"
$windowScreenshotPath = Join-Path $OutputDirectory "release_singleplayer_visible_window.png"
$manifestPath = Join-Path $OutputDirectory "release_singleplayer_visible_window_findings.json"

$shouldFocusWindow = -not [bool]$SkipFocusWindow
$windowSnapshot = Get-WindowSnapshot -SelectedProcessId $selectedProcessId -ShouldFocus $shouldFocusWindow
$handleCaptureStatus = Capture-WindowHandle -WindowSnapshot $windowSnapshot -Path $windowHandleScreenshotPath
$handleCaptureNonBlank = Test-ImageNonBlank -Path $windowHandleScreenshotPath
$handleCaptureTrusted = [bool]$handleCaptureStatus.succeeded -and [bool]$handleCaptureNonBlank.nonblank
$desktopCaptureError = ""
$desktopScreenshotWritten = $false
try {
	Capture-Desktop -Path $desktopScreenshotPath
	$desktopScreenshotWritten = Test-Path -LiteralPath $desktopScreenshotPath
} catch {
	$desktopCaptureError = $_.Exception.Message
	$warnings += "desktop_capture_failed"
}

$cropStatus = [ordered]@{
	attempted = $false
	succeeded = $false
	reason = "window_rect_missing"
	width = 0
	height = 0
}
$preferredCropRect = $windowSnapshot.rect
if ([bool]$windowSnapshot.client_rect_found) {
	$preferredCropRect = $windowSnapshot.client_rect
}
if ($desktopScreenshotWritten -and $null -ne $preferredCropRect) {
	$cropStatus = Export-DesktopCrop -SourcePath $desktopScreenshotPath -DestinationPath $desktopCropScreenshotPath -WindowRect $preferredCropRect
}

$desktopNonBlank = Test-ImageNonBlank -Path $desktopScreenshotPath
$desktopCropNonBlank = Test-ImageNonBlank -Path $desktopCropScreenshotPath
if ($desktopScreenshotWritten -and -not [bool]$desktopNonBlank.nonblank) {
	$warnings += "desktop_screenshot_blank"
}
if ($desktopScreenshotWritten -and -not [bool]$windowSnapshot.window_handle_found) {
	$warnings += "main_window_handle_not_found"
}
if ($desktopScreenshotWritten -and [bool]$windowSnapshot.window_handle_found -and [bool]$shouldFocusWindow -and -not [bool]$windowSnapshot.focus_succeeded) {
	$warnings += "window_focus_failed_crop_may_show_wrong_window"
}
if ($desktopScreenshotWritten -and [bool]$windowSnapshot.window_handle_found -and [bool]$shouldFocusWindow -and -not [bool]$windowSnapshot.foreground_matches_selected_process) {
	$warnings += "foreground_window_does_not_match_selected_release_process"
}

$windowCropTrusted = [bool]$cropStatus.succeeded
if ([bool]$shouldFocusWindow -and -not [bool]$windowSnapshot.foreground_matches_selected_process) {
	$windowCropTrusted = $false
}

$windowCaptureMethod = ""
$windowScreenshotWritten = $false
if ($handleCaptureTrusted) {
	Copy-Item -LiteralPath $windowHandleScreenshotPath -Destination $windowScreenshotPath -Force
	$windowCaptureMethod = "window_handle_print"
	$windowScreenshotWritten = Test-Path -LiteralPath $windowScreenshotPath
} elseif ([bool]$cropStatus.succeeded) {
	Copy-Item -LiteralPath $desktopCropScreenshotPath -Destination $windowScreenshotPath -Force
	$windowCaptureMethod = "desktop_crop_fallback"
	$windowScreenshotWritten = Test-Path -LiteralPath $windowScreenshotPath
} else {
	$windowCaptureMethod = "none"
}
$windowNonBlank = Test-ImageNonBlank -Path $windowScreenshotPath
$windowCaptureTrusted = $handleCaptureTrusted -or ([bool]$windowCropTrusted -and [bool]$windowNonBlank.nonblank)
if (-not $handleCaptureTrusted -and [bool]$handleCaptureStatus.attempted) {
	$warnings += "window_handle_capture_not_trusted"
}

$gate = "review_ready"
if ($hardFailures.Count -gt 0) {
	$gate = "fail"
} elseif (-not $desktopScreenshotWritten) {
	$gate = "manual_open"
} elseif ($windowScreenshotWritten -and -not [bool]$windowCaptureTrusted) {
	$gate = "manual_open"
}

$manifest = [ordered]@{
	schema = "sternenbuergerchen.release_singleplayer_visible_window_findings.v1"
	task_id = "TASK_822"
	source_tasks = @(
		"TASK_818",
		"TASK_819",
		"TASK_820",
		"TASK_821",
		"BUGFIX_singleplayer_release_visible_homebase_deadend_guard"
	)
	gate = $gate
	repo_root = $script:repoRoot
	branch = Get-GitValue -Arguments @("branch", "--show-current")
	git_head = Get-GitValue -Arguments @("rev-parse", "--short", "HEAD")
	contract_path = [System.IO.Path]::GetFullPath($ContractPath)
	exe_path = $exePath
	console_exe_path = $consoleExePath
	release_directory = $releaseDirectory
	running_processes = @($runningProcesses)
	selected_process_id = $selectedProcessId
	window_handle_found = [bool]$windowSnapshot.window_handle_found
	focus_window_before_capture = [bool]$shouldFocusWindow
	window_snapshot = $windowSnapshot
	window_rect = $windowSnapshot.rect
	client_rect = $windowSnapshot.client_rect
	desktop_screenshot_path = "tmp/release_singleplayer_visible_window_desktop.png"
	window_screenshot_path = "tmp/release_singleplayer_visible_window.png"
	window_handle_screenshot_path = "tmp/release_singleplayer_visible_window_handle.png"
	desktop_crop_screenshot_path = "tmp/release_singleplayer_visible_window_desktop_crop.png"
	desktop_screenshot_full_path = $desktopScreenshotPath
	window_screenshot_full_path = $windowScreenshotPath
	window_handle_screenshot_full_path = $windowHandleScreenshotPath
	desktop_crop_screenshot_full_path = $desktopCropScreenshotPath
	desktop_screenshot_written = [bool]$desktopScreenshotWritten
	window_screenshot_written = [bool]$windowScreenshotWritten
	window_capture_method = $windowCaptureMethod
	window_capture_trusted = [bool]$windowCaptureTrusted
	window_handle_capture = $handleCaptureStatus
	window_handle_capture_nonblank = $handleCaptureNonBlank
	window_crop_trusted = [bool]$windowCropTrusted
	desktop_screenshot_nonblank = $desktopNonBlank
	window_screenshot_nonblank = $windowNonBlank
	desktop_crop_nonblank = $desktopCropNonBlank
	crop_status = $cropStatus
	desktop_crop_status = $cropStatus
	desktop_capture_error = $desktopCaptureError
	warnings = @($warnings)
	hard_failures = @($hardFailures)
	manual_review_required = $true
	manual_review_done = $false
	required_checks = @(
		"singleplayer_clicked",
		"homebase_cta_visible",
		"start_mission_visible",
		"flightdeck_payload_visible",
		"start_mission_click_opens_mission",
		"lz_drop_preview_go_visible",
		"firefight_hud_readable"
	)
	read_only = $true
	starts_processes = $false
	kills_processes = $false
	updates_shortcuts = $false
	ui_sets_gameplay_truth = $false
	next_recommended_task = "TASK_823 - Release Singleplayer Visible Findings Polish"
}

$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding UTF8

if ($JsonOnly) {
	$manifest | ConvertTo-Json -Depth 8
} else {
	Write-Host "Release singleplayer visible window findings: $gate"
	Write-Host "EXE: $exePath"
	Write-Host "Selected process id: $selectedProcessId"
	Write-Host "Manifest: $manifestPath"
	Write-Host "Desktop screenshot: $desktopScreenshotPath"
	if ([bool]$cropStatus.succeeded) {
		Write-Host "Window screenshot: $windowScreenshotPath"
	} elseif (-not [bool]$windowSnapshot.window_handle_found) {
		Write-Host "Window screenshot skipped: main window handle not found"
	} else {
		Write-Host "Window screenshot skipped: $($cropStatus.reason)"
	}
	if ($warnings.Count -gt 0) {
		Write-Host "Warnings: $($warnings -join ', ')"
	}
	if ($hardFailures.Count -gt 0) {
		Write-Host "Hard failures: $($hardFailures -join ', ')"
	}
}

if ($hardFailures.Count -gt 0) {
	exit 2
}
exit 0
