param([switch]$Capture)
$ErrorActionPreference = 'Stop'
$PreviewProject = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$PreviewGodot = (Get-Command godot_console.exe -ErrorAction SilentlyContinue).Source
if (-not $PreviewGodot) { $PreviewGodot = (Get-Command godot.exe -ErrorAction Stop).Source }
$PreviewOutput = Join-Path $PreviewProject 'output/grafik_20261101'
New-Item -ItemType Directory -Force -Path $PreviewOutput | Out-Null
$PreviewImportLog = Join-Path $PreviewOutput 'launcher_import.log'
Push-Location $PreviewProject
try {
    & $PreviewGodot --headless --editor --path $PreviewProject --import --quit *> $PreviewImportLog
    if ($LASTEXITCODE -ne 0) { throw "Godot-Import fehlgeschlagen. Log: $PreviewImportLog" }
    if (Select-String -LiteralPath $PreviewImportLog -Pattern 'SCRIPT ERROR|Parse Error|Compile Error|^ERROR:' -Quiet) {
        throw "Godot meldet einen Importfehler. Log: $PreviewImportLog"
    }
    $PreviewArguments = @('--path', $PreviewProject, '--rendering-method', 'forward_plus', '--rendering-driver', 'vulkan', '--resolution', '1600x900', 'res://scenes/tests/frontier_art_preview.tscn')
    if ($Capture) { $PreviewArguments += @('--', '--capture-frontier-art') }
    & $PreviewGodot @PreviewArguments
    if ($LASTEXITCODE -ne 0) { throw "Hex-Basis wurde mit Exitcode $LASTEXITCODE beendet." }
} finally {
    Pop-Location
}
