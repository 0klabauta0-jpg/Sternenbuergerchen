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
	"scripts/tests/task_222_performance_regression_gate_and_manual_profile_checklist.gd"
)
$leakPatterns = @(
	"^Leaked instance:",
	"^(WARNING:|ERROR:).*RID allocations.*leaked",
	"^(WARNING:|ERROR:).*RID of type.*leaked",
	"^WARNING: ObjectDB instances leaked",
	"Resources still in use at exit",
	"^ERROR:",
	"^SCRIPT ERROR:"
)
$failures = New-Object System.Collections.Generic.List[string]

foreach ($verifier in $verifiers) {
	Write-Output "=== $verifier --verbose ==="
	$startInfo = New-Object System.Diagnostics.ProcessStartInfo
	$startInfo.FileName = $godotPath
	$startInfo.Arguments = "--headless --verbose --path `"$projectRoot`" --script `"$verifier`""
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
		$failures.Add("${verifier}: timeout after ${TimeoutSeconds}s")
	}
	$verifierExit = $process.ExitCode
	$stdout = $stdoutTask.Result
	$stderr = $stderrTask.Result
	$combined = "$stdout`n$stderr"
	$stdout.TrimEnd() | Write-Output
	if (-not [string]::IsNullOrWhiteSpace($stderr)) {
		$stderr.TrimEnd() | Write-Output
	}
	if ($verifierExit -ne 0 -or $combined -match "(?m)^\s*(FAIL|ERROR:.*FAIL)(:|$)") {
		$failures.Add("${verifier}: functional exit=$verifierExit or FAIL output")
	}
	foreach ($line in ($combined -split "`r?`n")) {
		$trimmed = $line.Trim()
		foreach ($pattern in $leakPatterns) {
			if ($trimmed -match $pattern) {
				$failures.Add("${verifier}: $trimmed")
				break
			}
		}
	}
	$process.Dispose()
}

if ($failures.Count -gt 0) {
	Write-Output "TASK_1146 headless resource leak gate failed:"
	$failures | Select-Object -Unique | ForEach-Object { Write-Output "- $_" }
	exit 1
}

Write-Output "TASK_1146 HEADLESS RESOURCE LEAK GATE PASSED ($($verifiers.Count) verbose verifiers)"
exit 0
