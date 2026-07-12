param(
	[string]$GodotExecutable = "godot_console.exe",
	[int]$TimeoutSeconds = 180
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$godotCommand = Get-Command $GodotExecutable -ErrorAction SilentlyContinue
$godotPath = if ($null -ne $godotCommand) { $godotCommand.Source } elseif (Test-Path -LiteralPath $GodotExecutable) { (Resolve-Path -LiteralPath $GodotExecutable).Path } else { "" }
if ([string]::IsNullOrWhiteSpace($godotPath)) {
	Write-Error "Godot executable '$GodotExecutable' was not found."
	exit 1
}

$verifiers = @(
	"scripts/tests/task_096_recovery_verifier.gd",
	"scripts/tests/task_257_button_reachability_and_interaction_verifier.gd",
	"scripts/tests/task_1112_connected_parallel_dropship_command_lifecycle_recovery.gd",
	"scripts/tests/task_1115_connected_parallel_dropship_drop_deboard_return_playthrough.gd",
	"scripts/tests/task_1116_connected_post_deboard_fireteam_command_handoff.gd",
	"scripts/tests/task_1117_connected_post_deboard_first_contact_combat_handoff.gd",
	"scripts/tests/task_1118_connected_first_contact_hud_perspective_visual_evidence.gd"
)

$failed = New-Object System.Collections.Generic.List[string]
foreach ($verifier in $verifiers) {
	Write-Output "=== $verifier ==="
	$startInfo = New-Object System.Diagnostics.ProcessStartInfo
	$startInfo.FileName = $godotPath
	$startInfo.Arguments = "--headless --path `"$projectRoot`" --script `"$verifier`""
	$startInfo.UseShellExecute = $false
	$startInfo.CreateNoWindow = $true
	$startInfo.RedirectStandardOutput = $true
	$startInfo.RedirectStandardError = $true
	$process = New-Object System.Diagnostics.Process
	$process.StartInfo = $startInfo
	[void]$process.Start()
	$stdoutTask = $process.StandardOutput.ReadToEndAsync()
	$stderrTask = $process.StandardError.ReadToEndAsync()
	if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
		$process.Kill()
		$process.WaitForExit()
		$failed.Add("${verifier}: timeout after ${TimeoutSeconds}s")
	}
	$stdout = $stdoutTask.Result
	$stderr = $stderrTask.Result
	$stdout.TrimEnd() | Write-Output
	if (-not [string]::IsNullOrWhiteSpace($stderr)) {
		$stderr.TrimEnd() | Write-Output
	}
	$failureText = "$stdout`n$stderr"
	if ($process.ExitCode -ne 0 -or $failureText -match "(?m)^\s*(FAIL|ERROR:.*FAIL)(:|$)") {
		$failed.Add("${verifier}: exit=$($process.ExitCode) or FAIL output")
	}
	$process.Dispose()
}

if ($failed.Count -gt 0) {
	Write-Output "TASK_1145 player-flow gate failed:"
	$failed | Select-Object -Unique | ForEach-Object { Write-Output "- $_" }
	exit 1
}

Write-Output "TASK_1145 PLAYER-FLOW GATE PASSED ($($verifiers.Count) isolated verifiers)"
exit 0
