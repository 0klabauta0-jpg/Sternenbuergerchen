param([switch]$WebSocket)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$probeFolder=Join-Path $env:TEMP ('sternen-team16-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $probeFolder | Out-Null
$engine='C:\Users\bjoer\AppData\Local\Programs\Godot\Godot_v4.6.2-stable_win64_console.exe'
$processes=@()
try {
    $arguments=@('--headless','--path',('"'+$projectRoot+'"'),'--script','tests/team_network_probe.gd','--',('"--probe-out='+$probeFolder+'"'))
    if($WebSocket){$arguments+='--websocket'}
    $hostProcess=Start-Process -WindowStyle Hidden -FilePath $engine -ArgumentList ($arguments+@('--team-host','--index=0')) -RedirectStandardOutput "$probeFolder/host.log" -RedirectStandardError "$probeFolder/host.err" -PassThru
    $processes+=$hostProcess
    $deadline=[DateTime]::UtcNow.AddSeconds(30)
    while(-not (Test-Path -LiteralPath "$probeFolder/ready.json")) {
        if($hostProcess.HasExited -or [DateTime]::UtcNow -gt $deadline){throw 'Host did not become ready'}
        Start-Sleep -Milliseconds 100
    }
    foreach($i in 1..15) {
        $processes+=Start-Process -WindowStyle Hidden -FilePath $engine -ArgumentList ($arguments+"--index=$i") -RedirectStandardOutput "$probeFolder/client-$i.log" -RedirectStandardError "$probeFolder/client-$i.err" -PassThru
    }
    if(-not $hostProcess.WaitForExit(85000)){throw 'Team network timed out'}
    $result=Get-Content -LiteralPath "$probeFolder/host.json" -Raw | ConvertFrom-Json
    if(-not $result.ok){throw $result.reason}
    $teams=@(0,0)
    foreach($i in 1..15){
        $client=Get-Content -LiteralPath "$probeFolder/client-$i.json" -Raw | ConvertFrom-Json
        if(-not $client.ok -or $client.members -ne 16){throw "Client $i failed"}
        $teams[[int]$client.team]++
    }
    if($teams[0] -ne 7 -or $teams[1] -ne 8){throw 'Incorrect team capacity'}
    foreach($file in Get-ChildItem -LiteralPath $probeFolder -Filter '*.err') {
        if((Get-Content -LiteralPath $file.FullName -Raw) -match 'SCRIPT ERROR|ERROR:'){throw "Engine error: $($file.Name)"}
    }
    Write-Output "TEAM16_PASS websocket=$WebSocket evidence=$probeFolder"
} finally {
    foreach($process in $processes){if(-not $process.HasExited){Stop-Process -Id $process.Id}}
}
