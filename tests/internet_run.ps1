param([switch]$Public, [switch]$ForceDnsFallback, [int]$Port = 28119)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$engine = 'C:\Users\bjoer\AppData\Local\Programs\Godot\Godot_v4.6.2-stable_win64_console.exe'
$runRoot = Join-Path $env:TEMP ('sternen-internet-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $runRoot | Out-Null
$hostProcess = $null
$guestProcess = $null
try {
    $env:APPDATA = Join-Path $runRoot 'appdata'
    New-Item -ItemType Directory -Path $env:APPDATA | Out-Null
    $baseArguments = @('--headless','--path',('"'+$projectRoot+'"'),'--script','res://tests/internet_process_probe.gd','--',('--port='+$Port),('"--output='+$runRoot+'"'))
    if ($Public) { $baseArguments += '--public' }
    if ($ForceDnsFallback) {
        if (-not $Public) { throw 'Forced DNS fallback requires the real public tunnel.' }
        $baseArguments += '--force-dns-fallback'
    }
    $hostProcess = Start-Process -FilePath $engine -ArgumentList ($baseArguments + '--role=host') -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $runRoot 'host.log') -RedirectStandardError (Join-Path $runRoot 'host-error.log')
    $deadline = [DateTime]::UtcNow.AddSeconds(85)
    while (-not (Test-Path -LiteralPath (Join-Path $runRoot 'invitation.json'))) {
        if ($hostProcess.HasExited -or [DateTime]::UtcNow -gt $deadline) { throw 'Host invitation not ready.' }
        Start-Sleep -Milliseconds 100
    }
    $guestProcess = Start-Process -FilePath $engine -ArgumentList ($baseArguments + '--role=guest') -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $runRoot 'guest.log') -RedirectStandardError (Join-Path $runRoot 'guest-error.log')
    $deadline = [DateTime]::UtcNow.AddSeconds(200)
    while (-not ($hostProcess.HasExited -and $guestProcess.HasExited)) {
        if ([DateTime]::UtcNow -gt $deadline) { throw 'Internet probe timed out.' }
        Start-Sleep -Milliseconds 100
    }
    foreach ($roleName in @('host','guest')) {
        $result = Get-Content -LiteralPath (Join-Path $runRoot ($roleName+'-result.json')) -Raw | ConvertFrom-Json
        if ($result.failed -ne 0) { throw "$roleName has failed checks." }
        $errorsText = Get-Content -LiteralPath (Join-Path $runRoot ($roleName+'-error.log')) -Raw
        if ($errorsText -match '(SCRIPT ERROR|ERROR:)') { throw "$roleName has engine errors." }
        Write-Output "$roleName checks=$($result.checks.Count) failed=$($result.failed)"
    }
    foreach ($pair in @(@('paused','guest-paused'),@('restored','guest-restored'),@('host-final','guest-final'))) {
        $left = Get-Content -LiteralPath (Join-Path $runRoot ($pair[0]+'.json')) -Raw | ConvertFrom-Json
        $right = Get-Content -LiteralPath (Join-Path $runRoot ($pair[1]+'.json')) -Raw | ConvertFrom-Json
        if (($left | ConvertTo-Json -Depth 100 -Compress) -ne ($right | ConvertTo-Json -Depth 100 -Compress)) { throw "Full snapshot mismatch: $($pair[0])" }
    }
    Write-Output "INTERNET_PASS public=$Public evidence=$runRoot"
} catch {
    foreach ($roleName in @('host','guest')) {
        foreach ($suffix in @('.log','-error.log')) {
            $log = Join-Path $runRoot ($roleName+$suffix)
            if (Test-Path -LiteralPath $log) { Get-Content -LiteralPath $log -Tail 18 }
        }
    }
    Write-Output "INTERNET_FAIL evidence=$runRoot"
    throw
} finally {
    if ($null -ne $hostProcess) {
        $ownedHelpers = Get-CimInstance Win32_Process -Filter "ParentProcessId=$($hostProcess.Id)" | Where-Object { $_.Name -eq 'cloudflared.exe' }
        foreach ($helper in $ownedHelpers) { Stop-Process -Id $helper.ProcessId -ErrorAction SilentlyContinue }
    }
    foreach ($owned in @($hostProcess,$guestProcess)) {
        if ($null -ne $owned -and -not $owned.HasExited) { Stop-Process -Id $owned.Id }
    }
    # The invitation contains an ephemeral secret; never retain it in test evidence.
    $invitationPath = Join-Path $runRoot 'invitation.json'
    if (Test-Path -LiteralPath $invitationPath) { Remove-Item -LiteralPath $invitationPath }
}
