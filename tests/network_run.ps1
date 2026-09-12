param([int]$Port = 27991, [switch]$Visual)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$godotPath = 'C:\Users\bjoer\AppData\Local\Programs\Godot\Godot_v4.6.2-stable_win64_console.exe'
$runRoot = Join-Path $env:TEMP ('sternenbuergerchen-network-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $runRoot | Out-Null
$hostProcess = $null
$guestProcess = $null
try {
    $baseArguments = @('--path', ('"' + $projectRoot + '"'), '--script', 'res://tests/network_probe.gd', '--', ('--port=' + $Port), ('"--output=' + $runRoot + '"'))
    if ($Visual) { $baseArguments += '--visual' } else { $baseArguments = @('--headless') + $baseArguments }
    $hostProcess = Start-Process -FilePath $godotPath -ArgumentList ($baseArguments + '--role=host') -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $runRoot 'host.log') -RedirectStandardError (Join-Path $runRoot 'host-error.log')
    $readyDeadline = [DateTime]::UtcNow.AddSeconds(25)
    while (-not (Test-Path -LiteralPath (Join-Path $runRoot 'host_stage.json'))) {
        if ($hostProcess.HasExited -or [DateTime]::UtcNow -gt $readyDeadline) { throw 'Host did not become ready.' }
        Start-Sleep -Milliseconds 100
    }
    $guestProcess = Start-Process -FilePath $godotPath -ArgumentList ($baseArguments + '--role=guest') -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $runRoot 'guest.log') -RedirectStandardError (Join-Path $runRoot 'guest-error.log')
    $deadline = [DateTime]::UtcNow.AddSeconds(60)
    while (-not ($hostProcess.HasExited -and $guestProcess.HasExited)) {
        if ([DateTime]::UtcNow -gt $deadline) { throw 'Two-process probe timed out.' }
        Start-Sleep -Milliseconds 100
    }
    foreach ($roleName in @('host', 'guest')) {
        $resultPath = Join-Path $runRoot ($roleName + '_result.json')
        if (-not (Test-Path -LiteralPath $resultPath)) { throw "Missing $roleName result." }
        $resultData = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
        if ($resultData.failed -ne 0) { throw "$roleName reported $($resultData.failed) failed checks." }
        $errorsText = Get-Content -LiteralPath (Join-Path $runRoot ($roleName + '-error.log')) -Raw
        if ($errorsText -match '(SCRIPT ERROR|ERROR:)') { throw "$roleName has engine errors." }
        if ($Visual) {
            foreach ($captureStage in @('paused', 'reconnected')) {
                $capturePath = Join-Path $runRoot ($roleName + '-' + $captureStage + '.png')
                if (-not (Test-Path -LiteralPath $capturePath) -or (Get-Item -LiteralPath $capturePath).Length -eq 0) { throw "Missing $roleName $captureStage viewport capture." }
            }
        }
        Write-Output ("{0}: checks={1} failed={2} snapshots={3}" -f $roleName, $resultData.checks.Count, $resultData.failed, $resultData.received_snapshots)
    }
    Write-Output "NETWORK_TWO_PROCESS_PASS evidence=$runRoot"
} catch {
    foreach ($roleName in @('host','guest')) {
        foreach ($suffix in @('.log','-error.log')) {
            $logPath = Join-Path $runRoot ($roleName + $suffix)
            if (Test-Path -LiteralPath $logPath) { Get-Content -LiteralPath $logPath -Tail 25 }
        }
    }
    Write-Output "NETWORK_TWO_PROCESS_FAIL evidence=$runRoot"
    throw
} finally {
    foreach ($ownedProcess in @($hostProcess,$guestProcess)) {
        if ($null -ne $ownedProcess -and -not $ownedProcess.HasExited) { Stop-Process -Id $ownedProcess.Id }
    }
}
