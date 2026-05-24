$ErrorActionPreference = "Stop"

$unityExe = "C:\Program Files\Unity\Hub\Editor\6000.4.1f1\Editor\Unity.exe"
$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $projectDir "Logs"
$logFile = Join-Path $logDir "player_build_windows.log"
$playerExe = Join-Path $projectDir "Builds\Windows\SternenBuergerchenUnitySpike.exe"

if (-not (Test-Path -LiteralPath $unityExe)) {
    Write-Host "Unity 6000.4.1f1 was not found at:"
    Write-Host $unityExe
    exit 1
}

$runningUnity = Get-Process Unity -ErrorAction SilentlyContinue
if ($runningUnity) {
    Write-Host "Unity is already running."
    Write-Host "Close the current Unity Editor window first, then run this builder again."
    exit 2
}

New-Item -ItemType Directory -Force -Path $logDir | Out-Null

Write-Host "Building Unity spike Windows player..."
Write-Host "Project: $projectDir"
Write-Host "Log: $logFile"

& $unityExe `
    -quit `
    -batchmode `
    -projectPath $projectDir `
    -executeMethod SternenBuergerUnitySpike.Editor.SpikePlayerBuilder.BuildWindows `
    -logFile $logFile

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host "Built player:"
Write-Host $playerExe
