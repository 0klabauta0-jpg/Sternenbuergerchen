param(
	[string]$ContractPath = "",
	[string]$OutputDirectory = "",
	[int]$WaitSeconds = 30,
	[switch]$Launch,
	[switch]$StopRunningReleaseProcess,
	[switch]$CleanTempFiles,
	[switch]$SkipFocusWindow
)

$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
	$scriptDirectory = Split-Path -Parent $PSCommandPath
	return (Resolve-Path (Join-Path $scriptDirectory "..\..")).Path
}

function Read-JsonFile {
	param([string]$Path)
	if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
		return $null
	}
	return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
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

function Copy-IfExists {
	param(
		[string]$SourcePath,
		[string]$DestinationPath
	)
	if ([string]::IsNullOrWhiteSpace($SourcePath) -or -not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
		return $false
	}
	Copy-Item -LiteralPath $SourcePath -Destination $DestinationPath -Force
	return (Test-Path -LiteralPath $DestinationPath -PathType Leaf)
}

$script:repoRoot = Resolve-RepoRoot
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
	$OutputDirectory = Join-Path $script:repoRoot "tmp"
}
if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) {
	New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
}

$launchArgument = "--release-singleplayer-first-go-firefight"
$densityMode = "release_firefight_declutter"
$styleId = "task_839_release_firefight_world_label_declutter_v1"
$sourceCaptureScript = Join-Path $script:repoRoot "scripts\tools\capture_release_first_go_firefight_real_window.ps1"
$sourceCaptureManifestPath = Join-Path $OutputDirectory "release_first_go_firefight_real_window_review.json"
$taskManifestPath = Join-Path $OutputDirectory "release_firefight_world_label_real_window_recapture.json"
$taskDesktopScreenshotPath = Join-Path $OutputDirectory "release_firefight_world_label_real_window_desktop.png"
$taskWindowScreenshotPath = Join-Path $OutputDirectory "release_firefight_world_label_real_window.png"

if (-not (Test-Path -LiteralPath $sourceCaptureScript -PathType Leaf)) {
	throw "Missing TASK_837 source capture script: $sourceCaptureScript"
}

$sourceArgs = @("-ExecutionPolicy", "Bypass", "-File", $sourceCaptureScript, "-OutputDirectory", $OutputDirectory, "-WaitSeconds", [string]$WaitSeconds)
if (-not [string]::IsNullOrWhiteSpace($ContractPath)) {
	$sourceArgs += @("-ContractPath", $ContractPath)
}
if ($Launch) {
	$sourceArgs += "-Launch"
}
if ($StopRunningReleaseProcess) {
	$sourceArgs += "-StopRunningReleaseProcess"
}
if ($CleanTempFiles) {
	$sourceArgs += "-CleanTempFiles"
}
if ($SkipFocusWindow) {
	$sourceArgs += "-SkipFocusWindow"
}

$sourceOutput = & powershell @sourceArgs
$sourceExitCode = $LASTEXITCODE
$sourceManifest = Read-JsonFile -Path $sourceCaptureManifestPath

$sourceDesktopPath = if ($sourceManifest -ne $null) { [string]$sourceManifest.desktop_screenshot_full_path } else { "" }
$sourceWindowPath = if ($sourceManifest -ne $null) { [string]$sourceManifest.window_screenshot_full_path } else { "" }
$desktopCopied = Copy-IfExists -SourcePath $sourceDesktopPath -DestinationPath $taskDesktopScreenshotPath
$windowCopied = Copy-IfExists -SourcePath $sourceWindowPath -DestinationPath $taskWindowScreenshotPath

$hardFailures = @()
$warnings = @()
if ($sourceExitCode -ne 0) {
	$hardFailures += "source_capture_failed:$sourceExitCode"
}
if ($sourceManifest -eq $null) {
	$hardFailures += "source_manifest_missing"
} elseif ([string]$sourceManifest.gate -eq "fail") {
	$hardFailures += "source_manifest_failed"
}
if (-not $desktopCopied) {
	$warnings += "desktop_screenshot_copy_missing"
}
if (-not $windowCopied) {
	$warnings += "window_screenshot_copy_missing"
}

$gate = "review_ready"
if ($hardFailures.Count -gt 0) {
	$gate = "fail"
} elseif (-not $windowCopied) {
	$gate = "manual_open"
}

$requiredChecks = @(
	"release_exe_started_with_first_go_firefight_arg",
	"world_label_density_mode_release_firefight_declutter",
	"world_labels_less_dense_than_task_837",
	"fire_vfx_trace_and_impact_visible",
	"friendly_fire_warning_preserved",
	"critical_unit_state_badges_preserved",
	"routine_hit_miss_fire_labels_suppressed",
	"hud_selected_fireteam_next_why_still_visible",
	"mission_control_next_why_still_visible",
	"event_log_or_fallback_still_carries_detail",
	"command_matrix_go_still_visible",
	"manual_visual_review_done"
)

$manifest = [ordered]@{
	schema = "sternenbuergerchen.release_firefight_world_label_real_window_recapture.v1"
	task_id = "TASK_840"
	source_task_id = "TASK_839"
	source_capture_task_id = "TASK_837"
	gate = $gate
	repo_root = $script:repoRoot
	branch = Get-GitValue -Arguments @("branch", "--show-current")
	git_head = Get-GitValue -Arguments @("rev-parse", "--short", "HEAD")
	launch_argument = $launchArgument
	wait_seconds = $WaitSeconds
	expected_world_label_density_mode = $densityMode
	expected_world_label_declutter_style_id = $styleId
	source_capture_manifest_path = "tmp/release_first_go_firefight_real_window_review.json"
	source_capture_manifest_full_path = $sourceCaptureManifestPath
	source_capture_gate = if ($sourceManifest -ne $null) { [string]$sourceManifest.gate } else { "" }
	source_capture_output = @($sourceOutput)
	selected_process_id = if ($sourceManifest -ne $null) { [int]$sourceManifest.selected_process_id } else { 0 }
	window_handle_found = if ($sourceManifest -ne $null) { [bool]$sourceManifest.window_handle_found } else { $false }
	desktop_screenshot_path = "tmp/release_firefight_world_label_real_window_desktop.png"
	window_screenshot_path = "tmp/release_firefight_world_label_real_window.png"
	desktop_screenshot_full_path = $taskDesktopScreenshotPath
	window_screenshot_full_path = $taskWindowScreenshotPath
	desktop_screenshot_written = $desktopCopied
	window_screenshot_written = $windowCopied
	required_checks = $requiredChecks
	expected_visual_contracts = [ordered]@{
		first_go_firefight_arg = $launchArgument
		world_label_density_mode = $densityMode
		world_label_declutter_style_id = $styleId
		suppressed_routine_labels = @("HIT", "MISS", "FIRE", "CONTACT", "MOVE", "ENGAGE", "DEF", "READY")
		preserved_critical_signals = @("friendly_fire_warning", "fire_vfx", "trace", "impact", "DOWN", "BLEEDOUT", "RESPAWN", "HP")
		hud_detail_surfaces = @("selected_fireteam", "mission_control", "event_log")
	}
	manual_review_required = $true
	manual_review_done = $false
	read_only_capture = $true
	ui_sets_gameplay_truth = $false
	creates_command = $false
	creates_fire_event = $false
	creates_damage_event = $false
	sets_multiplayer_truth = $false
	starts_processes = [bool]$Launch
	kills_processes = [bool]$StopRunningReleaseProcess
	updates_shortcuts = $false
	warnings = @($warnings)
	hard_failures = @($hardFailures)
	recommended_next_task = "TASK_841 - Release Firefight World Label Visual Findings"
}

$manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $taskManifestPath -Encoding UTF8

Write-Host "TASK_840 Release-firefight world-label real-window recapture: $gate"
Write-Host "Manifest: $taskManifestPath"
Write-Host "Desktop screenshot: $taskDesktopScreenshotPath"
if ($windowCopied) {
	Write-Host "Window screenshot: $taskWindowScreenshotPath"
} else {
	Write-Host "Window screenshot missing; see source capture manifest."
}
if ($warnings.Count -gt 0) {
	Write-Host "Warnings: $($warnings -join ', ')"
}
if ($hardFailures.Count -gt 0) {
	Write-Host "Hard failures: $($hardFailures -join ', ')"
}

if ($hardFailures.Count -gt 0) {
	exit 2
}
exit 0
