param(
	[int]$Port = 28747,
	[int]$TimeoutSeconds = 35,
	[switch]$StopRunningReleaseProcesses,
	[switch]$KeepProcessesRunning,
	[switch]$DropDecision
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$tmp = Join-Path $repoRoot "tmp"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$checkScript = Join-Path $repoRoot "scripts\tools\release_runtime_start_check.ps1"
$checkOutput = & powershell -ExecutionPolicy Bypass -File $checkScript -JsonOnly
$check = (($checkOutput -join [Environment]::NewLine) | ConvertFrom-Json)
if ([string]$check.gate -eq "fail") { throw "Release provenance check failed." }

if ($StopRunningReleaseProcesses) {
	foreach ($entry in @($check.running_processes)) {
		$pidToStop = [int]$entry.process_id
		if ($pidToStop -gt 0) { Stop-Process -Id $pidToStop -Force -ErrorAction SilentlyContinue }
	}
	Start-Sleep -Milliseconds 500
}

$exe = [string]$check.exe_path
if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) { throw "Missing Sternenbuergerchen_rel.exe: $exe" }
$artifactPrefix = if ($DropDecision) { "release_host_client_drop_decision" } else { "release_host_client" }
$hostTrace = Join-Path $tmp ("{0}_host_trace.json" -f $artifactPrefix)
$clientTrace = Join-Path $tmp ("{0}_client_trace.json" -f $artifactPrefix)
$manifestPath = Join-Path $tmp $(if ($DropDecision) { "release_host_client_drop_decision_playtest.json" } else { "release_host_client_entry_playtest.json" })
$screenshotPath = Join-Path $tmp $(if ($DropDecision) { "release_host_client_drop_decision_playtest.png" } else { "release_host_client_entry_playtest.png" })
$hostWindowPath = Join-Path $tmp $(if ($DropDecision) { "release_host_client_drop_decision_host_window.png" } else { "release_host_client_host_window.png" })
$clientWindowPath = Join-Path $tmp $(if ($DropDecision) { "release_host_client_drop_decision_client_window.png" } else { "release_host_client_client_window.png" })
Remove-Item -LiteralPath $hostTrace,$clientTrace -Force -ErrorAction SilentlyContinue

$hostArgs = @(
	"--resolution", "900x700", "--position", "20,80", "--",
	"--release-multiplayer-host", "--release-multiplayer-port=$Port",
	"--release-multiplayer-auto-start", "--release-multiplayer-trace=$hostTrace"
)
$clientArgs = @(
	"--resolution", "900x700", "--position", "960,80", "--",
	"--release-multiplayer-join", "--release-multiplayer-address=127.0.0.1",
	"--release-multiplayer-port=$Port", "--release-multiplayer-trace=$clientTrace"
)
if ($DropDecision) {
	$hostArgs += "--release-multiplayer-drop-decision"
	$clientArgs += "--release-multiplayer-drop-decision"
}

$hostProcess = Start-Process -FilePath $exe -WorkingDirectory ([string]$check.release_directory) -ArgumentList $hostArgs -PassThru
Start-Sleep -Milliseconds 900
$clientProcess = Start-Process -FilePath $exe -WorkingDirectory ([string]$check.release_directory) -ArgumentList $clientArgs -PassThru
$startedAt = [DateTimeOffset]::UtcNow
$effectiveTimeoutSeconds = if ($DropDecision) { [Math]::Max(90, $TimeoutSeconds) } else { [Math]::Max(5, $TimeoutSeconds) }
$deadline = $startedAt.AddSeconds($effectiveTimeoutSeconds)
$hostState = $null
$clientState = $null
$connected = $false
$deploymentConverged = $false
do {
	Start-Sleep -Milliseconds 250
	try { if (Test-Path $hostTrace) { $hostState = Get-Content $hostTrace -Raw | ConvertFrom-Json } } catch {}
	try { if (Test-Path $clientTrace) { $clientState = Get-Content $clientTrace -Raw | ConvertFrom-Json } } catch {}
	$baseReady = $null -ne $hostState -and $null -ne $clientState `
		-and [bool]$hostState.active_mission -and [bool]$clientState.active_mission
	if ($DropDecision) {
		$hostDeployed = @($hostState.drop_decision.deployed_unit_ids)
		$clientDeployed = @($clientState.drop_decision.deployed_unit_ids)
		$hostEmbarked = @($hostState.drop_decision.embarked_unit_ids)
		$clientEmbarked = @($clientState.drop_decision.embarked_unit_ids)
		$deploymentConverged = $hostDeployed.Count -gt 0 `
			-and $hostDeployed.Count -eq $clientDeployed.Count `
			-and $hostEmbarked.Count -eq 0 `
			-and $clientEmbarked.Count -eq 0
		$connected = $baseReady `
			-and [string]$hostState.drop_decision.stage -eq "first_decision_accepted" `
			-and [string]$clientState.drop_decision.stage -eq "first_decision_accepted" `
			-and $deploymentConverged
	} else {
		$connected = $baseReady `
			-and [string]$hostState.stage -eq "mission_started" `
			-and [string]$clientState.stage -eq "mission_started"
	}
} while (-not $connected -and [DateTimeOffset]::UtcNow -lt $deadline -and -not $hostProcess.HasExited -and -not $clientProcess.HasExited)

$screenshotWritten = $false
try {
	Add-Type -AssemblyName System.Drawing
	Add-Type -AssemblyName System.Windows.Forms
	$bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
	$bitmap = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
	$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
	try {
		$graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
		$bitmap.Save($screenshotPath, [System.Drawing.Imaging.ImageFormat]::Png)
		$screenshotWritten = Test-Path -LiteralPath $screenshotPath
	} finally { $graphics.Dispose(); $bitmap.Dispose() }
} catch {}

$windowCaptureScript = Join-Path $repoRoot "scripts\tools\capture_release_singleplayer_visible_window.ps1"
$windowCaptures = @{}
foreach ($entry in @(
	@{ name = "host"; process = $hostProcess; path = $hostWindowPath },
	@{ name = "client"; process = $clientProcess; path = $clientWindowPath }
)) {
	$captureDirPattern = if ($DropDecision) { "task_1148_{0}_capture" } else { "task_1147_{0}_capture" }
	$captureDirName = $captureDirPattern -f $entry.name
	$captureDir = Join-Path $tmp $captureDirName
	New-Item -ItemType Directory -Force -Path $captureDir | Out-Null
	& powershell -ExecutionPolicy Bypass -File $windowCaptureScript -OutputDirectory $captureDir -ProcessId $entry.process.Id -SkipFocusWindow -JsonOnly | Out-Null
	$captureManifestPath = Join-Path $captureDir "release_singleplayer_visible_window_findings.json"
	$written = $false
	if (Test-Path -LiteralPath $captureManifestPath) {
		$captureManifest = Get-Content -LiteralPath $captureManifestPath -Raw | ConvertFrom-Json
		$sourceWindow = [string]$captureManifest.window_screenshot_full_path
		if (Test-Path -LiteralPath $sourceWindow) {
			Copy-Item -LiteralPath $sourceWindow -Destination $entry.path -Force
			$written = Test-Path -LiteralPath $entry.path
		}
	}
	$windowCaptures[$entry.name] = [ordered]@{ path = $entry.path; written = $written }
}

$manifest = [ordered]@{
	schema = $(if ($DropDecision) { "sternenbuergerchen.release_host_client_drop_decision_playtest.v1" } else { "sternenbuergerchen.release_host_client_entry_playtest.v1" })
	task_id = $(if ($DropDecision) { "TASK_1148" } else { "TASK_1147" })
	gate = $(if ($connected) { "pass" } else { "fail" })
	exe_path = $exe
	release_gate = [string]$check.gate
	port = $Port
	wait_msec = [int]([DateTimeOffset]::UtcNow - $startedAt).TotalMilliseconds
	host_process_id = $hostProcess.Id
	client_process_id = $clientProcess.Id
	host_trace_path = $hostTrace
	client_trace_path = $clientTrace
	host = $hostState
	client = $clientState
	mission_started = $connected
	drop_decision_requested = [bool]$DropDecision
	first_decision_accepted = $connected -and [bool]$DropDecision
	deployment_converged = $deploymentConverged
	screenshot_path = $screenshotPath
	screenshot_written = $screenshotWritten
	host_window = $windowCaptures.host
	client_window = $windowCaptures.client
	product_release_exe = $true
	manual_visual_review_required = $true
}
$manifest | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $manifestPath -Encoding UTF8

if (-not $KeepProcessesRunning) {
	foreach ($process in @($clientProcess, $hostProcess)) {
		if ($null -ne $process -and -not $process.HasExited) { Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue }
	}
}

Write-Host "$($manifest.task_id) release Host/Join playtest: $($manifest.gate)"
Write-Host "Manifest: $manifestPath"
Write-Host "Screenshot: $screenshotPath"
if (-not $connected) { exit 2 }
exit 0
