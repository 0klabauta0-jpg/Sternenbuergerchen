param()
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$godotPath='C:\Users\bjoer\AppData\Local\Programs\Godot\Godot_v4.6.2-stable_win64_console.exe'
$runRoot=Join-Path $env:TEMP ('sternenbuergerchen-lifecycle-n2-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $runRoot | Out-Null
$total=0
foreach($phaseName in @('initial','restore','guards','recovered')){
    $arguments=@('--path',('"'+$projectRoot+'"'),'--script','res://tests/save_lifecycle_probe.gd','--',('--phase='+$phaseName),('"--output='+$runRoot+'"'))
    $process=Start-Process -FilePath $godotPath -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $runRoot ($phaseName+'.log')) -RedirectStandardError (Join-Path $runRoot ($phaseName+'-error.log'))
    try{
        if(-not $process.WaitForExit(15000)){throw "Lifecycle phase $phaseName timed out"}
        $process.Refresh()
        if($process.ExitCode -ne 0){throw "Lifecycle phase $phaseName exited $($process.ExitCode)"}
        $log=Get-Content -LiteralPath (Join-Path $runRoot ($phaseName+'.log')) -Raw
        $errors=Get-Content -LiteralPath (Join-Path $runRoot ($phaseName+'-error.log')) -Raw
        if($errors -match 'SCRIPT ERROR|ERROR:'){throw "Lifecycle phase $phaseName has engine errors"}
        $match=[regex]::Match($log,'SAVE_LIFECYCLE_PASS phase=\w+ checks=(\d+)')
        if(-not $match.Success){throw "Lifecycle phase $phaseName lacks success evidence"}
        $total+=[int]$match.Groups[1].Value
        Write-Output $match.Value
        if($phaseName -eq 'initial'){
            # Convert the genuine first-session save into its historical v1 shape.
            # No success state or economy value is created; only later schema additions are removed.
            $path=Join-Path $runRoot 'lifecycle-roundtrip.json'
            Copy-Item -LiteralPath $path -Destination (Join-Path $runRoot 'initial-schema3.json')
            $legacy=Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
            $legacy.schema_version=1;$legacy.state.schema_version=1
            foreach($key in @('base','random_seed','discovery','encounter','ground','resources','rental')){$legacy.state.PSObject.Properties.Remove($key)}
            foreach($key in @('mode','position','target','roles','model','name')){$legacy.state.ship.PSObject.Properties.Remove($key)}
            foreach($key in @('kind','encounter_decided','encounter_roll')){$legacy.state.travel.PSObject.Properties.Remove($key)}
            foreach($item in @('helmet','armor','ore','alloy')){$legacy.state.inventory.PSObject.Properties.Remove($item);$legacy.state.cargo.PSObject.Properties.Remove($item)}
            $legacy.state.blueprints=@($legacy.state.blueprints | Where-Object {$_ -notin @('helmet','upgrade_workbench','armor')})
            foreach($crew in @('ida','jaro')){foreach($field in @('skills','equipment','health','respawn_remaining','attack_target','attack_cooldown')){$legacy.state.crew.$crew.PSObject.Properties.Remove($field)}}
            $legacy | ConvertTo-Json -Depth 100 | Set-Content -Encoding utf8 -LiteralPath $path
            Copy-Item -LiteralPath $path -Destination (Join-Path $runRoot 'legacy-input-v1.json')
        }
    }finally{
        if(-not $process.HasExited){Stop-Process -Id $process.Id}
    }
}
[pscustomobject]@{Checks=$total;Failed=0;ProductLaunches=4;LegacyMigration=$true;Evidence=$runRoot} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $runRoot 'result.json')
Write-Output "SAVE_LIFECYCLE_N2_PASS checks=$total evidence=$runRoot"
