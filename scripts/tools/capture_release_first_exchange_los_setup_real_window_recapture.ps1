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
$losSetupSchema = "sternenbuergerchen.release_first_exchange_los_setup_polish.v1"
$losSetupStyleId = "task_868_release_first_exchange_los_setup_polish_v1"
$exchangeSchema = "sternenbuergerchen.release_first_exchange_tension_tuning.v1"
$exchangeStyleId = "task_844_release_first_exchange_tension_tuning_v1"
$runtimeStatusSchema = "sternenbuergerchen.release_fire_exchange_runtime_text_status_recapture.v1"
$sourceCaptureScript = Join-Path $script:repoRoot "scripts\tools\capture_release_fire_exchange_runtime_text_status_recapture.ps1"
$sourceCaptureManifestPath = Join-Path $OutputDirectory "release_fire_exchange_runtime_text_status_recapture.json"
$visibleWindowManifestPath = Join-Path $OutputDirectory "release_singleplayer_visible_window_findings.json"
$taskManifestPath = Join-Path $OutputDirectory "release_first_exchange_los_setup_real_window_recapture.json"
$taskDesktopScreenshotPath = Join-Path $OutputDirectory "release_first_exchange_los_setup_real_window_recapture_desktop.png"
$taskWindowScreenshotPath = Join-Path $OutputDirectory "release_first_exchange_los_setup_real_window_recapture.png"

if (-not (Test-Path -LiteralPath $sourceCaptureScript -PathType Leaf)) {
	throw "Missing TASK_866 source capture script: $sourceCaptureScript"
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
$visibleWindowManifest = Read-JsonFile -Path $visibleWindowManifestPath

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
if ($visibleWindowManifest -eq $null) {
	$warnings += "visible_window_manifest_missing"
} else {
	if ([string]$visibleWindowManifest.gate -eq "fail") {
		$hardFailures += "visible_window_manifest_failed"
	}
	if ($visibleWindowManifest.PSObject.Properties.Name -contains "window_crop_trusted" -and -not [bool]$visibleWindowManifest.window_crop_trusted) {
		$warnings += "source_window_crop_not_trusted"
	}
	if ($visibleWindowManifest.PSObject.Properties.Name -contains "window_snapshot" -and $visibleWindowManifest.window_snapshot -ne $null) {
		if ($visibleWindowManifest.window_snapshot.PSObject.Properties.Name -contains "focus_succeeded" -and -not [bool]$visibleWindowManifest.window_snapshot.focus_succeeded) {
			$warnings += "source_window_focus_failed"
		}
		if ($visibleWindowManifest.window_snapshot.PSObject.Properties.Name -contains "foreground_matches_selected_process" -and -not [bool]$visibleWindowManifest.window_snapshot.foreground_matches_selected_process) {
			$warnings += "source_foreground_window_does_not_match_release_process"
		}
	}
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
} elseif ($visibleWindowManifest -ne $null -and $visibleWindowManifest.PSObject.Properties.Name -contains "window_crop_trusted" -and -not [bool]$visibleWindowManifest.window_crop_trusted) {
	$gate = "manual_open"
}

$requiredChecks = @(
	"release_exe_started_with_first_go_firefight_arg",
	"task_868_los_setup_expected",
	"task_844_first_exchange_expected",
	"task_866_runtime_text_status_expected",
	"validated_target_pair_context_visible",
	"selected_fireteam_contact_fire_visible",
	"mission_control_contact_fire_visible",
	"event_log_contact_fire_or_exchange_detail_visible",
	"fire_trace_or_impact_target_focus_visible",
	"source_window_crop_trusted",
	"no_stale_no_los_or_contact_pressure_only_message",
	"command_surfaces_still_usable",
	"manual_visual_review_done"
)

$manifest = [ordered]@{
	schema = "sternenbuergerchen.release_first_exchange_los_setup_real_window_recapture.v1"
	task_id = "TASK_869"
	source_task_id = "TASK_868"
	source_status_findings_task_id = "TASK_867"
	source_status_recapture_task_id = "TASK_866"
	source_exchange_task_id = "TASK_844"
	source_capture_task_id = "TASK_837"
	gate = $gate
	repo_root = $script:repoRoot
	branch = Get-GitValue -Arguments @("branch", "--show-current")
	git_head = Get-GitValue -Arguments @("rev-parse", "--short", "HEAD")
	launch_argument = $launchArgument
	wait_seconds = $WaitSeconds
	expected_los_setup_schema = $losSetupSchema
	expected_los_setup_style_id = $losSetupStyleId
	expected_exchange_schema = $exchangeSchema
	expected_exchange_style_id = $exchangeStyleId
	expected_runtime_status_schema = $runtimeStatusSchema
	source_capture_manifest_path = "tmp/release_fire_exchange_runtime_text_status_recapture.json"
	source_capture_manifest_full_path = $sourceCaptureManifestPath
	source_capture_gate = if ($sourceManifest -ne $null) { [string]$sourceManifest.gate } else { "" }
	source_capture_output = @($sourceOutput)
	visible_window_manifest_path = "tmp/release_singleplayer_visible_window_findings.json"
	visible_window_manifest_full_path = $visibleWindowManifestPath
	visible_window_gate = if ($visibleWindowManifest -ne $null) { [string]$visibleWindowManifest.gate } else { "" }
	window_crop_trusted = if ($visibleWindowManifest -ne $null -and $visibleWindowManifest.PSObject.Properties.Name -contains "window_crop_trusted") { [bool]$visibleWindowManifest.window_crop_trusted } else { $false }
	window_focus_succeeded = if ($visibleWindowManifest -ne $null -and $visibleWindowManifest.PSObject.Properties.Name -contains "window_snapshot" -and $visibleWindowManifest.window_snapshot -ne $null -and $visibleWindowManifest.window_snapshot.PSObject.Properties.Name -contains "focus_succeeded") { [bool]$visibleWindowManifest.window_snapshot.focus_succeeded } else { $false }
	foreground_process_id = if ($visibleWindowManifest -ne $null -and $visibleWindowManifest.PSObject.Properties.Name -contains "window_snapshot" -and $visibleWindowManifest.window_snapshot -ne $null -and $visibleWindowManifest.window_snapshot.PSObject.Properties.Name -contains "foreground_process_id") { [int]$visibleWindowManifest.window_snapshot.foreground_process_id } else { 0 }
	foreground_matches_selected_process = if ($visibleWindowManifest -ne $null -and $visibleWindowManifest.PSObject.Properties.Name -contains "window_snapshot" -and $visibleWindowManifest.window_snapshot -ne $null -and $visibleWindowManifest.window_snapshot.PSObject.Properties.Name -contains "foreground_matches_selected_process") { [bool]$visibleWindowManifest.window_snapshot.foreground_matches_selected_process } else { $false }
	selected_process_id = if ($sourceManifest -ne $null) { [int]$sourceManifest.selected_process_id } else { 0 }
	window_handle_found = if ($sourceManifest -ne $null) { [bool]$sourceManifest.window_handle_found } else { $false }
	desktop_screenshot_path = "tmp/release_first_exchange_los_setup_real_window_recapture_desktop.png"
	window_screenshot_path = "tmp/release_first_exchange_los_setup_real_window_recapture.png"
	desktop_screenshot_full_path = $taskDesktopScreenshotPath
	window_screenshot_full_path = $taskWindowScreenshotPath
	desktop_screenshot_written = $desktopCopied
	window_screenshot_written = $windowCopied
	required_checks = $requiredChecks
	expected_visible_contracts = [ordered]@{
		first_go_firefight_arg = $launchArgument
		los_setup_schema = $losSetupSchema
		los_setup_style_id = $losSetupStyleId
		exchange_schema = $exchangeSchema
		exchange_style_id = $exchangeStyleId
		runtime_status_schema = $runtimeStatusSchema
		readable_surfaces = @("selected_fireteam", "mission_control", "event_log", "primary3d_world")
		primary_policy = "CONTACT FIRE / Fire-Exchange must be visibly readable after TASK_868 validated target-pair setup"
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
	recommended_next_task = "TASK_870 - Release First Exchange Post-LOS Visual Findings"
}

$manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $taskManifestPath -Encoding UTF8

Write-Host "TASK_869 Release first-exchange LOS-setup real-window recapture: $gate"
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
