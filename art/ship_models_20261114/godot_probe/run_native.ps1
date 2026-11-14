param(
    [string]$Ships = 'prospector,vulture,gladius,hornet,caterpillar',
    [string]$Godot = 'C:/Users/bjoer/AppData/Local/Programs/Godot/Godot_v4.6.2-stable_win64_console.exe'
)
$ErrorActionPreference = 'Stop'
$runStamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmss')
$logFolder = Join-Path $PSScriptRoot ('native_logs/' + $runStamp)
New-Item -ItemType Directory -Force -Path $logFolder | Out-Null
$stdout = Join-Path $logFolder 'stdout.log'
$stderr = Join-Path $logFolder 'stderr.log'
$argv = @('--path', ('"' + $PSScriptRoot + '"'), '--rendering-method', 'gl_compatibility', '--windowed', '--resolution', '960x720', '--script', 'probe.gd', '--', '--render', ('--ships=' + $Ships))
$process = Start-Process -FilePath $Godot -ArgumentList $argv -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr
$null = $process.Handle
$finished = $process.WaitForExit(90000)
if (-not $finished) {
    $process.Kill()
    throw 'Owned native probe exceeded 90 seconds.'
}
$process.Refresh()
$outputText = (Get-Content -LiteralPath $stdout -Raw) + (Get-Content -LiteralPath $stderr -Raw)
$hasErrors = $outputText -match '(?m)^\s*(ERROR:|SCRIPT ERROR:)|Parse Error|Compile Error|ObjectDB instances leaked|resources still in use at exit'
$passed = $process.ExitCode -eq 0 -and $outputText.Contains('PASS: ship_asset_import') -and -not $hasErrors
$result = @{ passed = $passed; exit_code = $process.ExitCode; stdout = $stdout; stderr = $stderr; argv = $argv; bounded_seconds = 90; ships = $Ships }
$result | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $logFolder 'result.json') -Encoding utf8
Write-Output $outputText
Write-Output ('Native evidence: ' + $logFolder)
if (-not $passed) { exit 1 }
