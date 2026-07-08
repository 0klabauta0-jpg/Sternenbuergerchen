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

function Wait-ForRuntimeTrace {
	param(
		[string]$Path,
		[int]$TimeoutSeconds = 45
	)
	$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
	$bestTrace = $null
	while ((Get-Date) -lt $deadline) {
		$trace = Read-JsonFile -Path $Path
		if ($trace -ne $null) {
			$bestTrace = $trace
			$sampleCount = if ($trace.PSObject.Properties.Name -contains "sample_count") { [int]$trace.sample_count } else { 0 }
			$latestStage = ""
			if ($trace.PSObject.Properties.Name -contains "latest_sample" -and $trace.latest_sample -ne $null -and $trace.latest_sample.PSObject.Properties.Name -contains "stage") {
				$latestStage = [string]$trace.latest_sample.stage
			}
			if ($latestStage -eq "deeplink_final") {
				return $trace
			}
		}
		Start-Sleep -Milliseconds 500
	}
	return $bestTrace
}

$script:repoRoot = Resolve-RepoRoot
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
	$OutputDirectory = Join-Path $script:repoRoot "tmp"
}
if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) {
	New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
}

$envName = "STERNENBUERGERCHEN_RELEASE_FIRST_EXCHANGE_TRACE_PATH"
$launchArgument = "--release-singleplayer-first-go-firefight"
$sourceCaptureScript = Join-Path $script:repoRoot "scripts\tools\capture_release_first_exchange_visible_status_recapture.ps1"
$sourceManifestPath = Join-Path $OutputDirectory "release_first_exchange_visible_status_recapture.json"
$runtimeTracePath = Join-Path $OutputDirectory "release_first_exchange_exported_status_source_trace_runtime.json"
$taskManifestPath = Join-Path $OutputDirectory "release_first_exchange_exported_status_source_trace.json"

if (-not (Test-Path -LiteralPath $sourceCaptureScript -PathType Leaf)) {
	throw "Missing TASK_877 source capture script: $sourceCaptureScript"
}
if (Test-Path -LiteralPath $runtimeTracePath -PathType Leaf) {
	Remove-Item -LiteralPath $runtimeTracePath -Force
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

$previousTracePath = [Environment]::GetEnvironmentVariable($envName, "Process")
[Environment]::SetEnvironmentVariable($envName, $runtimeTracePath, "Process")
try {
	$sourceOutput = & powershell @sourceArgs
	$sourceExitCode = $LASTEXITCODE
} finally {
	[Environment]::SetEnvironmentVariable($envName, $previousTracePath, "Process")
}

$sourceManifest = Read-JsonFile -Path $sourceManifestPath
$runtimeTrace = Wait-ForRuntimeTrace -Path $runtimeTracePath
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
if ($runtimeTrace -eq $null) {
	$hardFailures += "runtime_trace_missing"
}
if ($runtimeTrace -ne $null -and $runtimeTrace.PSObject.Properties.Name -contains "sample_count") {
	if ([int]$runtimeTrace.sample_count -lt 4) {
		$warnings += "runtime_trace_sample_count_low"
	}
}
if ($runtimeTrace -ne $null -and $runtimeTrace.PSObject.Properties.Name -contains "activation_observed" -and -not [bool]$runtimeTrace.activation_observed) {
	$warnings += "task_876_activation_not_observed"
}
if ($runtimeTrace -ne $null -and $runtimeTrace.PSObject.Properties.Name -contains "final_no_los_or_contact_pressure_observed" -and [bool]$runtimeTrace.final_no_los_or_contact_pressure_observed) {
	$warnings += "final_visible_status_still_no_los_or_contact_pressure"
}

$recommendedNextTask = "TASK_879 - Rerun Exported Status Source Trace"
if ($runtimeTrace -ne $null) {
	if ($runtimeTrace.PSObject.Properties.Name -contains "activation_observed" -and -not [bool]$runtimeTrace.activation_observed) {
		$recommendedNextTask = "TASK_880 - Release First Exchange Exported Status Source Activation Fix"
	} elseif ($runtimeTrace.PSObject.Properties.Name -contains "final_no_los_or_contact_pressure_observed" -and [bool]$runtimeTrace.final_no_los_or_contact_pressure_observed) {
		$recommendedNextTask = "TASK_880 - Release First Exchange Exported HUD Refresh Override Fix"
	} else {
		$recommendedNextTask = "TASK_880 - Release First Exchange Fire Visual Polish"
	}
}

$gate = "review_ready"
if ($hardFailures.Count -gt 0) {
	$gate = "fail"
} elseif ($warnings.Count -gt 0) {
	$gate = "review"
}

$requiredChecks = @(
	"release_exe_started_with_first_go_firefight_arg",
	"task_879_runtime_trace_written",
	"task_876_status_source_activation_sampled",
	"combat_hud_density_consumption_sampled",
	"selected_fireteam_final_reading_sampled",
	"mission_control_final_reading_sampled",
	"event_log_final_reading_sampled",
	"read_only_trace_boundaries",
	"no_gameplay_truth_mutation_from_trace"
)

$manifest = [ordered]@{
	schema = "sternenbuergerchen.release_first_exchange_exported_status_source_trace.v1"
	task_id = "TASK_879"
	source_task_id = "TASK_878"
	source_visible_status_task_id = "TASK_876"
	source_recapture_task_id = "TASK_877"
	source_readability_task_id = "TASK_873"
	gate = $gate
	repo_root = $script:repoRoot
	branch = Get-GitValue -Arguments @("branch", "--show-current")
	git_head = Get-GitValue -Arguments @("rev-parse", "--short", "HEAD")
	launch_argument = $launchArgument
	wait_seconds = $WaitSeconds
	source_capture_manifest_path = "tmp/release_first_exchange_visible_status_recapture.json"
	source_capture_manifest_full_path = $sourceManifestPath
	source_capture_gate = if ($sourceManifest -ne $null) { [string]$sourceManifest.gate } else { "" }
	source_capture_output = @($sourceOutput)
	runtime_trace_path = "tmp/release_first_exchange_exported_status_source_trace_runtime.json"
	runtime_trace_full_path = $runtimeTracePath
	runtime_trace_written = $runtimeTrace -ne $null
	runtime_trace_schema = if ($runtimeTrace -ne $null) { [string]$runtimeTrace.schema } else { "" }
	runtime_trace_sample_count = if ($runtimeTrace -ne $null -and $runtimeTrace.PSObject.Properties.Name -contains "sample_count") { [int]$runtimeTrace.sample_count } else { 0 }
	runtime_trace_activation_observed = if ($runtimeTrace -ne $null -and $runtimeTrace.PSObject.Properties.Name -contains "activation_observed") { [bool]$runtimeTrace.activation_observed } else { $false }
	runtime_trace_final_no_los_or_contact_pressure_observed = if ($runtimeTrace -ne $null -and $runtimeTrace.PSObject.Properties.Name -contains "final_no_los_or_contact_pressure_observed") { [bool]$runtimeTrace.final_no_los_or_contact_pressure_observed } else { $false }
	runtime_trace = $runtimeTrace
	required_checks = $requiredChecks
	read_only_capture = $true
	read_only_trace = $true
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
	recommended_next_task = $recommendedNextTask
}

$manifest | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $taskManifestPath -Encoding UTF8

Write-Host "TASK_879 Release first-exchange exported status source trace: $gate"
Write-Host "Manifest: $taskManifestPath"
Write-Host "Runtime trace: $runtimeTracePath"
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
