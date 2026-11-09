param(
    [string[]]$Scripts = @('orbit_quantum_flow_verifier.gd'),
    [string]$RunName = 'checks',
    [int]$TimeoutSeconds = 240
)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$evidenceRoot = Join-Path $projectRoot "docs/qa/orbit_quantum_20261109/raw/$RunName"
$profileRoot = Join-Path $projectRoot "output/orbit_quantum_20261109/profiles/$RunName"
New-Item -ItemType Directory -Path $evidenceRoot, $profileRoot -Force | Out-Null
$godotPath = (Get-Command godot_console.exe -ErrorAction Stop).Source
$results = @()
foreach ($scriptName in $Scripts) {
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $godotPath
    $startInfo.WorkingDirectory = $projectRoot
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.Environment['APPDATA'] = Join-Path $profileRoot ($scriptName -replace '\.gd$', '')
    New-Item -ItemType Directory -Path $startInfo.Environment['APPDATA'] -Force | Out-Null
    foreach ($argument in @('--headless', '--path', $projectRoot, '--script', "res://scripts/tests/$scriptName")) {
        $startInfo.ArgumentList.Add($argument)
    }
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    [void]$process.Start()
    try { $process.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal } catch {}
    $stdout = $process.StandardOutput.ReadToEndAsync()
    $stderr = $process.StandardError.ReadToEndAsync()
    $finished = $process.WaitForExit($TimeoutSeconds * 1000)
    if (-not $finished) { $process.Kill($true); $process.WaitForExit() }
    $log = $stdout.GetAwaiter().GetResult() + $stderr.GetAwaiter().GetResult()
    $logPath = Join-Path $evidenceRoot ($scriptName -replace '\.gd$', '.log')
    [System.IO.File]::WriteAllText($logPath, $log)
    $exitCode = if ($finished) { $process.ExitCode } else { -1 }
    $errors = [regex]::Matches($log, '(?m)^(?:SCRIPT ERROR|ERROR:|FAIL:)').Count
    $results += [pscustomobject]@{ script = $scriptName; exit_code = $exitCode; errors = $errors; log = $logPath; profile = $startInfo.Environment['APPDATA'] }
    Write-Output "$scriptName exit=$exitCode errors=$errors log=$logPath"
    $process.Dispose()
}
$results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $evidenceRoot 'results.json') -Encoding utf8
if (@($results | Where-Object { $_.exit_code -ne 0 -or $_.errors -ne 0 }).Count) { exit 1 }
