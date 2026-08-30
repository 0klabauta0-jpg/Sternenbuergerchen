param(
	[string]$GodotExecutable = 'godot_console.exe',
	[int]$Runs = 3
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

for ($run = 1; $run -le $Runs; $run += 1) {
	$output = & $GodotExecutable --headless --path $projectRoot --script scripts/tests/task_1179_ground_mission_objective_playthrough.gd 2>&1
	$verifierExit = $LASTEXITCODE
	$output | ForEach-Object { Write-Output $_ }
	$text = $output -join [Environment]::NewLine
	if ($verifierExit -ne 0 -or $text -notmatch '=== RESULTS: 22 passed, 0 failed ===' -or $text -match 'previously freed instance|SCRIPT ERROR:|ObjectDB instances leaked') {
		throw "TASK_1179 run $run failed (exit=$verifierExit)."
	}
}

Write-Output "TASK_1179 PASS ($Runs serial runs, 22 assertions each)"
