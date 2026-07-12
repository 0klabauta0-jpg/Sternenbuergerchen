param(
	[int]$Port = 28747,
	[int]$TimeoutSeconds = 35,
	[switch]$StopRunningReleaseProcesses,
	[switch]$KeepProcessesRunning
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
$hostTrace = Join-Path $tmp "release_host_client_host_trace.json"
$clientTrace = Join-Path $tmp "release_host_client_client_trace.json"
$manifestPath = Join-Path $tmp "release_host_client_entry_playtest.json"
$screenshotPath = Join-Path $tmp "release_host_client_entry_playtest.png"
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

$host = Start-Process -FilePath $exe -WorkingDirectory ([string]$check.release_directory) -ArgumentList $hostArgs -PassThru
Start-Sleep -Milliseconds 900
$client = Start-Process -FilePath $exe -WorkingDirectory ([string]$check.release_directory) -ArgumentList $clientArgs -PassThru
$startedAt = [DateTimeOffset]::UtcNow
$deadline = $startedAt.AddSeconds([Math]::Max(5, $TimeoutSeconds))
$hostState = $null
$clientState = $null
$connected = $false
do {
	Start-Sleep -Milliseconds 250
	try { if (Test-Path $hostTrace) { $hostState = Get-Content $hostTrace -Raw | ConvertFrom-Json } } catch {}
	try { if (Test-Path $clientTrace) { $clientState = Get-Content $clientTrace -Raw | ConvertFrom-Json } } catch {}
	$connected = $null -ne $hostState -and $null -ne $clientState `
		-and [string]$hostState.stage -eq "mission_started" `
		-and [string]$clientState.stage -eq "mission_started" `
		-and [bool]$hostState.active_mission -and [bool]$clientState.active_mission
} while (-not $connected -and [DateTimeOffset]::UtcNow -lt $deadline -and -not $host.HasExited -and -not $client.HasExited)

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

$manifest = [ordered]@{
	schema = "sternenbuergerchen.release_host_client_entry_playtest.v1"
	task_id = "TASK_1147"
	gate = $(if ($connected) { "pass" } else { "fail" })
	exe_path = $exe
	release_gate = [string]$check.gate
	port = $Port
	wait_msec = [int]([DateTimeOffset]::UtcNow - $startedAt).TotalMilliseconds
	host_process_id = $host.Id
	client_process_id = $client.Id
	host_trace_path = $hostTrace
	client_trace_path = $clientTrace
	host = $hostState
	client = $clientState
	mission_started = $connected
	screenshot_path = $screenshotPath
	screenshot_written = $screenshotWritten
	product_release_exe = $true
	manual_visual_review_required = $true
}
$manifest | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $manifestPath -Encoding UTF8

if (-not $KeepProcessesRunning) {
	foreach ($process in @($client, $host)) {
		if ($null -ne $process -and -not $process.HasExited) { Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue }
	}
}

Write-Host "TASK_1147 release Host/Join entry playtest: $($manifest.gate)"
Write-Host "Manifest: $manifestPath"
Write-Host "Screenshot: $screenshotPath"
if (-not $connected) { exit 2 }
exit 0
