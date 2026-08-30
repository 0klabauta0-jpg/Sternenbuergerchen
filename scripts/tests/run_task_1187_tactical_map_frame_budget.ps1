param(
	[ValidateSet('Measure')]
	[string]$Mode = 'Measure',
	[int]$ColdRuns = 3,
	[int]$WarmRuns = 5,
	[string]$GodotExecutable = 'godot_console.exe'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$gitSha = (git -C $projectRoot rev-parse HEAD).Trim()
$runCount = [Math]::Max($ColdRuns, 0) + [Math]::Max($WarmRuns, 0)
if ($runCount -le 0) {
	throw 'At least one cold or warm run is required.'
}

$env:STERNENBUERGERCHEN_GIT_SHA = $gitSha
for ($run = 1; $run -le $runCount; $run += 1) {
	$phase = if ($run -le $ColdRuns) { 'cold' } else { 'warm' }
	$output = & $GodotExecutable --headless --path $projectRoot --script scripts/tests/task_1187_tactical_map_frame_budget.gd 2>&1
	$nativeExit = $LASTEXITCODE
	$output | ForEach-Object { Write-Output $_ }
	$text = $output -join [Environment]::NewLine
	$jsonLine = @($output | Where-Object { $_ -match '^TACTICAL_MAP_FRAME_BUDGET_JSON=' } | Select-Object -Last 1)
	if ($nativeExit -ne 0 -or $jsonLine.Count -ne 1 -or $text -match 'SCRIPT ERROR:|ObjectDB instances leaked|Resources still in use at exit') {
		throw "TASK_1187 $phase run $run failed (exit=$nativeExit)."
	}
	$json = $jsonLine[0].Substring('TACTICAL_MAP_FRAME_BUDGET_JSON='.Length) | ConvertFrom-Json
	if ($json.schema -ne 'sternenbuergerchen.tactical_map_frame_budget.v1' -or $json.mode -ne $Mode -or -not $json.measurement_only) {
		throw "TASK_1187 $phase run $run emitted an invalid measurement contract."
	}
	Write-Output "TASK_1187 $phase run $run PASS"
}

Write-Output "TASK_1187 PASS ($ColdRuns cold, $WarmRuns warm; measurement-only)"
