param(
    [ValidateSet('Measure')][string]$Mode = 'Measure',
    [int]$ColdRuns = 3, [int]$WarmRuns = 5,
    [string]$GodotExecutable = 'godot_console.exe',
    [ValidateSet('off','shared_tick_result_contract','cache_internal_structured_reuse','contact_derived_read_model')][string]$Task1206Variant = 'off',
    [switch]$Task1206Paired, [ValidateRange(0,60)][int]$QuietWindowSeconds = 60, [switch]$Fast
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$gitSha = (git -C $projectRoot rev-parse HEAD).Trim()
$envNames = @('STERNENBUERGERCHEN_GIT_SHA','STERNENBUERGERCHEN_TASK1206_VARIANT','STERNENBUERGERCHEN_TASK1206_ENABLED','STERNENBUERGERCHEN_TASK1206_TOPOLOGY')
$saved = @{}; foreach ($name in $envNames) { $saved[$name] = [Environment]::GetEnvironmentVariable($name,'Process') }
$sequenceLiteral = 'off,on,on,off,on,off,off,on,off,on,on,off,on,off,off,on'
$sequence = @($sequenceLiteral.Split(','))
$scopePaths = [ordered]@{
    combat = @{ key='combat.total_tick_usec'; source_path='scopes."combat.total_tick_usec".p99' }
    fire_decision = @{ key='combat_scope.combat_fire_decision_usec'; source_path='scopes."combat_scope.combat_fire_decision_usec".p99' }
    pair_search = @{ key='combat_scope.fire_find_contact_pair_usec'; source_path='scopes."combat_scope.fire_find_contact_pair_usec".p99' }
    contact_tracking = @{ key='combat.contact_tracking_usec'; source_path='scopes."combat.contact_tracking_usec".p99' }
    enemy_team_tactics = @{ key='combat_scope.enemy_team_tactics_usec'; source_path='scopes."combat_scope.enemy_team_tactics_usec".p99' }
    simulation = @{ key='simulation.total_tick_usec'; source_path='scopes."simulation.total_tick_usec".p99' }
    command_queue = @{ key='simulation_scope.command_queue_usec'; source_path='scopes."simulation_scope.command_queue_usec".p99' }
}
function Invoke-MeasurementChild([string]$state,[int]$ordinal,[string]$phase) {
    $env:STERNENBUERGERCHEN_GIT_SHA=$gitSha
    $env:STERNENBUERGERCHEN_TASK1206_VARIANT = if ($state -eq 'on') {$Task1206Variant} else {'off'}
    $env:STERNENBUERGERCHEN_TASK1206_ENABLED = if ($state -eq 'on') {'1'} else {'0'}
    $env:STERNENBUERGERCHEN_TASK1206_TOPOLOGY='0'
    $arguments = @('--headless','--path',$projectRoot,'--script','scripts/tests/task_1187_tactical_map_frame_budget.gd')
    if ($Fast) { $arguments += @('--','--task1187-fast') }
    $output = @(& $GodotExecutable @arguments 2>&1)
    $exitCode = $LASTEXITCODE
    $text = $output -join [Environment]::NewLine
    $jsonLines = @($output | Where-Object { $_ -match '^TACTICAL_MAP_FRAME_BUDGET_JSON=' })
    if ($exitCode -ne 0 -or $jsonLines.Count -ne 1 -or $text -match 'SCRIPT ERROR:|ERROR:|ObjectDB|Resource[s]? still in use') { throw "TASK1206 child failed ($phase $ordinal, exit=$exitCode)" }
    $report = $jsonLines[0].Substring('TACTICAL_MAP_FRAME_BUDGET_JSON='.Length) | ConvertFrom-Json
    $meta = $report.task1206
    if ($report.schema -ne 'sternenbuergerchen.tactical_map_frame_budget.v1' -or $report.mode -ne $Mode -or -not $report.measurement_only -or $report.git_sha -ne $gitSha -or $meta.variant -ne $env:STERNENBUERGERCHEN_TASK1206_VARIANT -or [bool]$meta.enabled -ne ($state -eq 'on') -or [bool]$meta.topology_enabled) { throw 'TASK1206 child contract mismatch' }
    $p99=[ordered]@{}; foreach ($name in $scopePaths.Keys) { $value=$report.scopes.($scopePaths[$name].key).p99; try { $number=[double]$value } catch { throw "Missing or invalid p99: $name" }; if ([double]::IsNaN($number) -or [double]::IsInfinity($number) -or $number -le 0) { throw "Missing or invalid p99: $name" }; $p99[$name]=$number }
    return [ordered]@{raw_output=@($output);record=[ordered]@{phase=$phase;ordinal=$ordinal;state=$state;git_sha=$gitSha;task1206=$meta;p99=$p99}}
}
try {
    if (-not $Task1206Paired) {
        $runCount=[Math]::Max($ColdRuns,0)+[Math]::Max($WarmRuns,0); if ($runCount -le 0) { throw 'At least one cold or warm run is required.' }
        for ($run=1;$run -le $runCount;$run++) { $phase=if($run -le $ColdRuns){'cold'}else{'warm'}; $wrapper=Invoke-MeasurementChild off $run $phase; $wrapper.raw_output | ForEach-Object { Write-Output $_ }; Write-Output "TASK_1187 $phase run $run PASS" }
        Write-Output "TASK_1187 PASS ($ColdRuns cold, $WarmRuns warm; measurement-only)"; return
    }
    if ($Task1206Variant -eq 'off') { throw 'Task1206Variant=off cannot form a paired run.' }
    if ($QuietWindowSeconds -gt 0) { for($second=0;$second -lt $QuietWindowSeconds;$second++){ $existing=@(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^Godot.*\.exe$' }); if($existing.Count -gt 0){$details=$existing|ForEach-Object{"PID=$($_.ProcessId) CommandLine=$($_.CommandLine)"};throw ('TASK1206_QUIET_WINDOW_BLOCKED '+($details -join '; '))};Start-Sleep -Seconds 1 } }
    $runs=@(); $runs += (Invoke-MeasurementChild off 0 smoke).record; $runs += (Invoke-MeasurementChild on 1 smoke).record
    for($i=0;$i -lt $sequence.Count;$i++){$runs += (Invoke-MeasurementChild $sequence[$i] ($i+1) scored).record}
    if($runs.Count -ne 18){throw 'expected 18 records'};if(@($runs|Where-Object{$_.phase-eq'smoke'}).Count-ne 2 -or @($runs|Where-Object{$_.phase-eq'scored'}).Count-ne 16){throw 'phase counts mismatch'}
    $summaries=[ordered]@{}; foreach($name in $scopePaths.Keys){$pairs=@();$off=@();$on=@();for($i=0;$i -lt 8;$i++){ $left=$runs[2*$i+2];$right=$runs[2*$i+3];if($left.state -eq $right.state){throw 'paired states must differ'};$pairOff=if($left.state -eq 'off'){$left}else{$right};$pairOn=if($left.state -eq 'on'){$left}else{$right};$off+=$pairOff.p99[$name];$on+=$pairOn.p99[$name];$pairs+=[ordered]@{pair_index=$i;off=$pairOff.p99[$name];on=$pairOn.p99[$name];delta=($pairOn.p99[$name]-$pairOff.p99[$name])/$pairOff.p99[$name]}};$deltas=@($pairs|%{$_.delta});$so=$off|Sort-Object;$sn=$on|Sort-Object;$sd=$deltas|Sort-Object;$summaries[$name]=[ordered]@{source_path=$scopePaths[$name].source_path;off=[ordered]@{raw=$off;min=$so[0];max=$so[7];median=($so[3]+$so[4])/2};on=[ordered]@{raw=$on;min=$sn[0];max=$sn[7];median=($sn[3]+$sn[4])/2};pairs=$pairs;deltas=$deltas;delta_median=($sd[3]+$sd[4])/2;improved_pair_count=@($deltas|?{$_ -lt 0}).Count}}
    $summary=[ordered]@{schema='sternenbuergerchen.task1206.visibility_ab.v1';git_sha=$gitSha;variant=$Task1206Variant;smoke_run_count=2;scored_run_count=16;pair_count = 8;sequence=$sequence;runs=$runs;scopes=$summaries}; Write-Output ('TASK_1206_VISIBILITY_AB_JSON='+($summary|ConvertTo-Json -Compress -Depth 12))
} finally { foreach($name in $envNames){[Environment]::SetEnvironmentVariable($name,$saved[$name],'Process')} }
