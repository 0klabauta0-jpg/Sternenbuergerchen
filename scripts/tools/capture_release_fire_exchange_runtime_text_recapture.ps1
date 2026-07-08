param(
	[string]$ContractPath = "",
	[string]$OutputDirectory = "",
	[int]$WaitSeconds = 38,
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
$runtimeTextSchema = "sternenbuergerchen.release_fire_exchange_real_window_primary_hud_runtime_text_polish.v1"
$runtimeTextStyleId = "task_862_release_fire_exchange_real_window_primary_hud_runtime_text_v1"
$sourceBindingStyleId = "task_859_release_fire_exchange_real_window_primary_hud_source_binding_v1"
$primaryHudStyleId = "task_856_release_fire_exchange_contact_fire_primary_hud_polish_v1"
$readabilityStyleId = "task_853_release_fire_exchange_engagement_readability_v1"
$focusStyleId = "task_850_release_fire_exchange_focused_visual_polish_v1"
$expectedPersistenceMsec = 45000
$sourceCaptureScript = Join-Path $script:repoRoot "scripts\tools\capture_release_fire_exchange_real_window_contact_fire_recapture.ps1"
$sourceCaptureManifestPath = Join-Path $OutputDirectory "release_fire_exchange_real_window_contact_fire_recapture.json"
$taskManifestPath = Join-Path $OutputDirectory "release_fire_exchange_runtime_text_recapture.json"
$taskDesktopScreenshotPath = Join-Path $OutputDirectory "release_fire_exchange_runtime_text_recapture_desktop.png"
$taskWindowScreenshotPath = Join-Path $OutputDirectory "release_fire_exchange_runtime_text_recapture.png"

if (-not (Test-Path -LiteralPath $sourceCaptureScript -PathType Leaf)) {
	throw "Missing TASK_860 source capture script: $sourceCaptureScript"
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
	"task_862_runtime_text_expected",
	"task_859_source_binding_expected",
	"task_856_primary_hud_expected",
	"contact_fire_first_reading_visible_in_selected_fireteam",
	"contact_fire_first_reading_visible_in_mission_control",
	"primary_hud_no_debug_no_fire_before_contact_fire",
	"event_log_contact_fire_visible",
	"fire_trace_or_impact_target_focus_visible",
	"command_surfaces_still_usable",
	"manual_visual_review_done"
)

$manifest = [ordered]@{
	schema = "sternenbuergerchen.release_fire_exchange_runtime_text_recapture.v1"
	task_id = "TASK_863"
	source_task_id = "TASK_862"
	source_recapture_task_id = "TASK_860"
	source_binding_task_id = "TASK_859"
	source_primary_hud_task_id = "TASK_856"
	source_readability_task_id = "TASK_853"
	source_focus_task_id = "TASK_850"
	source_visibility_task_id = "TASK_847"
	source_exchange_task_id = "TASK_844"
	source_capture_task_id = "TASK_837"
	gate = $gate
	repo_root = $script:repoRoot
	branch = Get-GitValue -Arguments @("branch", "--show-current")
	git_head = Get-GitValue -Arguments @("rev-parse", "--short", "HEAD")
	launch_argument = $launchArgument
	wait_seconds = $WaitSeconds
	expected_runtime_text_schema = $runtimeTextSchema
	expected_runtime_text_style_id = $runtimeTextStyleId
	expected_source_binding_style_id = $sourceBindingStyleId
	expected_primary_hud_style_id = $primaryHudStyleId
	expected_readability_style_id = $readabilityStyleId
	expected_focus_style_id = $focusStyleId
	expected_persistence_duration_msec = $expectedPersistenceMsec
	source_capture_manifest_path = "tmp/release_fire_exchange_real_window_contact_fire_recapture.json"
	source_capture_manifest_full_path = $sourceCaptureManifestPath
	source_capture_gate = if ($sourceManifest -ne $null) { [string]$sourceManifest.gate } else { "" }
	source_capture_output = @($sourceOutput)
	selected_process_id = if ($sourceManifest -ne $null) { [int]$sourceManifest.selected_process_id } else { 0 }
	window_handle_found = if ($sourceManifest -ne $null) { [bool]$sourceManifest.window_handle_found } else { $false }
	desktop_screenshot_path = "tmp/release_fire_exchange_runtime_text_recapture_desktop.png"
	window_screenshot_path = "tmp/release_fire_exchange_runtime_text_recapture.png"
	desktop_screenshot_full_path = $taskDesktopScreenshotPath
	window_screenshot_full_path = $taskWindowScreenshotPath
	desktop_screenshot_written = $desktopCopied
	window_screenshot_written = $windowCopied
	required_checks = $requiredChecks
	expected_visible_contracts = [ordered]@{
		first_go_firefight_arg = $launchArgument
		runtime_text_schema = $runtimeTextSchema
		runtime_text_style_id = $runtimeTextStyleId
		source_binding_style_id = $sourceBindingStyleId
		primary_hud_style_id = $primaryHudStyleId
		readability_style_id = $readabilityStyleId
		focus_style_id = $focusStyleId
		persistence_duration_msec = $expectedPersistenceMsec
		readable_surfaces = @("selected_fireteam", "mission_control", "event_log", "primary3d_world")
		primary_policy = "CONTACT FIRE is the first #17/#18 runtime text reading after TASK_862"
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
	recommended_next_task = "TASK_864 - Release Fire Exchange Runtime Text Visual Findings"
}

$manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $taskManifestPath -Encoding UTF8

Write-Host "TASK_863 Release fire-exchange runtime-text recapture: $gate"
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
