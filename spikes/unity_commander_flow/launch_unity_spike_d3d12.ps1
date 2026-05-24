$ErrorActionPreference = "Stop"

$unityExe = "C:\Program Files\Unity\Hub\Editor\6000.4.1f1\Editor\Unity.exe"
$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $projectDir "Logs"
$logFile = Join-Path $logDir "manual_d3d12.log"

if (-not (Test-Path -LiteralPath $unityExe)) {
    Write-Host "Unity 6000.4.1f1 was not found at:"
    Write-Host $unityExe
    Read-Host "Press Enter to close"
    exit 1
}

$runningUnity = Get-Process Unity -ErrorAction SilentlyContinue
if ($runningUnity) {
    Write-Host "Unity is already running."
    Write-Host "Close the current Unity Editor window first, then run this launcher again."
    Write-Host ""
    Write-Host "Project:"
    Write-Host $projectDir
    Read-Host "Press Enter to close"
    exit 2
}

New-Item -ItemType Directory -Force -Path $logDir | Out-Null

Write-Host "Starting Unity directly, without Unity Hub project selection..."
Write-Host "Project: $projectDir"
Write-Host "Log: $logFile"

Start-Process `
    -FilePath $unityExe `
    -ArgumentList @("-projectPath", $projectDir, "-force-d3d12", "-logFile", $logFile) `
    -WorkingDirectory $projectDir
