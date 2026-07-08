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
$visibleStatusSchema = "sternenbuergerchen.release_first_exchange_visible_status_source_reconciliation.v1"
$visibleStatusStyleId = "task_876_release_first_exchange_visible_status_source_reconciliation_v1"
$contactFireSchema = "sternenbuergerchen.release_first_exchange_contact_fire_readability_fix.v1"
$contactFireStyleId = "task_873_release_first_exchange_contact_fire_readability_fix_v1"
$sourceCaptureScript = Join-Path $script:repoRoot "scripts\tools\capture_release_first_exchange_contact_fire_real_window_recapture.ps1"
$sourceManifestPath = Join-Path $OutputDirectory "release_first_exchange_contact_fire_real_window_recapture.json"
$visibleWindowManifestPath = Join-Path $OutputDirectory "release_singleplayer_visible_window_findings.json"
$taskManifestPath = Join-Path $OutputDirectory "release_first_exchange_visible_status_recapture.json"
$taskDesktopScreenshotPath = Join-Path $OutputDirectory "release_first_exchange_visible_status_recapture_desktop.png"
$taskWindowScreenshotPath = Join-Path $OutputDirectory "release_first_exchange_visible_status_recapture.png"

if (-not (Test-Path -LiteralPath $sourceCaptureScript -PathType Leaf)) {
	throw "Missing TASK_874 source capture script: $sourceCaptureScript"
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
$sourceManifest = Read-JsonFile -Path $sourceManifestPath
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
if (-not $desktopCopied) {
	$warnings += "desktop_screenshot_copy_missing"
}
if (-not $windowCopied) {
	$warnings += "window_screenshot_copy_missing"
}
if ($visibleWindowManifest -eq $null) {
	$warnings += "visible_window_manifest_missing"
} else {
	if ($visibleWindowManifest.PSObject.Properties.Name -contains "window_capture_trusted" -and -not [bool]$visibleWindowManifest.window_capture_trusted) {
		$warnings += "window_capture_not_trusted"
	}
	if ($visibleWindowManifest.PSObject.Properties.Name -contains "window_snapshot" -and $visibleWindowManifest.window_snapshot -ne $null) {
		if ($visibleWindowManifest.window_snapshot.PSObject.Properties.Name -contains "foreground_matches_selected_process" -and -not [bool]$visibleWindowManifest.window_snapshot.foreground_matches_selected_process) {
			$warnings += "foreground_window_does_not_match_release_process"
		}
	}
}

$gate = "review_ready"
if ($hardFailures.Count -gt 0) {
	$gate = "fail"
} elseif (-not $windowCopied) {
	$gate = "manual_open"
} elseif ($visibleWindowManifest -ne $null -and $visibleWindowManifest.PSObject.Properties.Name -contains "window_capture_trusted" -and -not [bool]$visibleWindowManifest.window_capture_trusted) {
	$gate = "manual_open"
}

$requiredChecks = @(
	"release_exe_started_with_first_go_firefight_arg",
	"task_876_visible_status_source_expected",
	"task_874_contact_fire_real_window_recapture_source_expected",
	"task_873_contact_fire_readability_fix_expected",
	"task_869_real_window_recapture_source_expected",
	"task_844_first_exchange_expected",
	"window_handle_capture_trusted",
	"selected_fireteam_contact_fire_first_visible",
	"mission_control_contact_fire_first_visible",
	"event_log_contact_fire_visible",
	"fire_trace_or_impact_target_focus_visible",
	"no_stale_no_los_or_contact_pressure_only_message",
	"command_surfaces_still_usable",
	"manual_visual_review_done"
)

$manifest = [ordered]@{
	schema = "sternenbuergerchen.release_first_exchange_visible_status_recapture.v1"
	task_id = "TASK_877"
	source_task_id = "TASK_876"
	source_recapture_task_id = "TASK_874"
	source_readability_task_id = "TASK_873"
	source_los_recapture_task_id = "TASK_869"
	source_exchange_task_id = "TASK_844"
	source_capture_fix_task_id = "TASK_871"
	gate = $gate
	repo_root = $script:repoRoot
	branch = Get-GitValue -Arguments @("branch", "--show-current")
	git_head = Get-GitValue -Arguments @("rev-parse", "--short", "HEAD")
	launch_argument = $launchArgument
	wait_seconds = $WaitSeconds
	expected_visible_status_schema = $visibleStatusSchema
	expected_visible_status_style_id = $visibleStatusStyleId
	expected_contact_fire_readability_schema = $contactFireSchema
	expected_contact_fire_readability_style_id = $contactFireStyleId
	source_capture_manifest_path = "tmp/release_first_exchange_contact_fire_real_window_recapture.json"
	source_capture_manifest_full_path = $sourceManifestPath
	source_capture_gate = if ($sourceManifest -ne $null) { [string]$sourceManifest.gate } else { "" }
	source_capture_output = @($sourceOutput)
	visible_window_manifest_path = "tmp/release_singleplayer_visible_window_findings.json"
	visible_window_manifest_full_path = $visibleWindowManifestPath
	visible_window_gate = if ($visibleWindowManifest -ne $null) { [string]$visibleWindowManifest.gate } else { "" }
	window_capture_method = if ($visibleWindowManifest -ne $null -and $visibleWindowManifest.PSObject.Properties.Name -contains "window_capture_method") { [string]$visibleWindowManifest.window_capture_method } else { "" }
	window_capture_trusted = if ($visibleWindowManifest -ne $null -and $visibleWindowManifest.PSObject.Properties.Name -contains "window_capture_trusted") { [bool]$visibleWindowManifest.window_capture_trusted } else { $false }
	window_handle_capture_succeeded = if ($visibleWindowManifest -ne $null -and $visibleWindowManifest.PSObject.Properties.Name -contains "window_handle_capture" -and $visibleWindowManifest.window_handle_capture -ne $null -and $visibleWindowManifest.window_handle_capture.PSObject.Properties.Name -contains "succeeded") { [bool]$visibleWindowManifest.window_handle_capture.succeeded } else { $false }
	window_focus_succeeded = if ($visibleWindowManifest -ne $null -and $visibleWindowManifest.PSObject.Properties.Name -contains "window_snapshot" -and $visibleWindowManifest.window_snapshot -ne $null -and $visibleWindowManifest.window_snapshot.PSObject.Properties.Name -contains "focus_succeeded") { [bool]$visibleWindowManifest.window_snapshot.focus_succeeded } else { $false }
	foreground_process_id = if ($visibleWindowManifest -ne $null -and $visibleWindowManifest.PSObject.Properties.Name -contains "window_snapshot" -and $visibleWindowManifest.window_snapshot -ne $null -and $visibleWindowManifest.window_snapshot.PSObject.Properties.Name -contains "foreground_process_id") { [int]$visibleWindowManifest.window_snapshot.foreground_process_id } else { 0 }
	foreground_matches_selected_process = if ($visibleWindowManifest -ne $null -and $visibleWindowManifest.PSObject.Properties.Name -contains "window_snapshot" -and $visibleWindowManifest.window_snapshot -ne $null -and $visibleWindowManifest.window_snapshot.PSObject.Properties.Name -contains "foreground_matches_selected_process") { [bool]$visibleWindowManifest.window_snapshot.foreground_matches_selected_process } else { $false }
	selected_process_id = if ($sourceManifest -ne $null) { [int]$sourceManifest.selected_process_id } else { 0 }
	window_handle_found = if ($sourceManifest -ne $null) { [bool]$sourceManifest.window_handle_found } else { $false }
	desktop_screenshot_path = "tmp/release_first_exchange_visible_status_recapture_desktop.png"
	window_screenshot_path = "tmp/release_first_exchange_visible_status_recapture.png"
	desktop_screenshot_full_path = $taskDesktopScreenshotPath
	window_screenshot_full_path = $taskWindowScreenshotPath
	desktop_screenshot_written = $desktopCopied
	window_screenshot_written = $windowCopied
	required_checks = $requiredChecks
	expected_visible_contracts = [ordered]@{
		first_go_firefight_arg = $launchArgument
		visible_status_schema = $visibleStatusSchema
		visible_status_style_id = $visibleStatusStyleId
		readable_surfaces = @("selected_fireteam", "mission_control", "event_log", "primary3d_world")
		primary_policy = "CONTACT FIRE must be the first visible status read for #17, #18 and #19 after TASK_876, or the PNG must prove a clear blocker."
	}
	manual_review_required = $true
	manual_review_done = $false
	read_only_capture = $true
	ui_sets_gameplay_truth = $false
	creates_command = $false
	creates_fire_event = $false
	creates_damage_event = $false
	creates_movement = $false
	sets_multiplayer_truth = $false
	starts_processes = [bool]$Launch
	kills_processes = [bool]$StopRunningReleaseProcess
	updates_shortcuts = $false
	warnings = @($warnings)
	hard_failures = @($hardFailures)
	recommended_next_task = "TASK_878 - Release First Exchange Visible Status Visual Findings"
}

$manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $taskManifestPath -Encoding UTF8

Write-Host "TASK_877 Release first-exchange visible-status recapture: $gate"
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
