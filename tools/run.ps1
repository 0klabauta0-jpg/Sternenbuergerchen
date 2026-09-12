param([switch]$Editor, [switch]$Headless, [switch]$HostGame, [string]$Join = '')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$enginePath = 'C:\Users\bjoer\AppData\Local\Programs\Godot\Godot_v4.6.2-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $enginePath)) { throw "Godot 4.6.2 fehlt am dokumentierten Pfad: $enginePath" }
$engineVersion = & $enginePath --version
if ($engineVersion -notlike '4.6.2.*') { throw "Erwartet Godot 4.6.2, gefunden: $engineVersion" }
if (-not (Test-Path -LiteralPath (Join-Path $projectRoot '.godot/imported'))) {
    & $enginePath --headless --editor --path $projectRoot --import --quit
    if ($LASTEXITCODE -ne 0) { throw 'Der erste Assetimport ist fehlgeschlagen.' }
}
$engineArgs = @('--path', $projectRoot)
if ($Editor) { $engineArgs += '--editor' }
if ($Headless) { $engineArgs += '--headless' }
if ($HostGame) { $engineArgs += @('--','--host') }
if ($Join) { $engineArgs += @('--',"--join=$Join") }
& $enginePath @engineArgs
exit $LASTEXITCODE
