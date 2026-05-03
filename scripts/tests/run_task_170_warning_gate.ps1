param(
	[string]$GodotExecutable = "godot_console.exe",
	[string]$VerifierScript = "scripts/tests/task_170_performance_warning_gate_verifier.gd"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$godotCommand = Get-Command $GodotExecutable -ErrorAction SilentlyContinue
if ($null -eq $godotCommand) {
	Write-Error "Godot executable '$GodotExecutable' was not found in PATH."
	exit 1
}

$rawOutput = & $godotCommand.Source --headless --path $projectRoot --script $VerifierScript 2>&1
$exitCode = $LASTEXITCODE
$lines = @($rawOutput | ForEach-Object { $_.ToString() })
$lines | ForEach-Object { Write-Output $_ }

$blockedPatterns = @(
	"ObjectDB instances leaked",
	"RID allocations.*leaked",
	"Resources still in use at exit",
	"Resource.*still in use at exit",
	"Leaked instance"
)

$blockedHits = New-Object System.Collections.Generic.List[string]
foreach ($line in $lines) {
	foreach ($pattern in $blockedPatterns) {
		if ($line -match $pattern) {
			$blockedHits.Add($line)
			break
		}
	}
}

$failLines = @($lines | Where-Object { $_ -match "(^|\s)FAIL(:|$)" })
if ($exitCode -ne 0 -or $blockedHits.Count -gt 0 -or $failLines.Count -gt 0) {
	if ($blockedHits.Count -gt 0) {
		Write-Output "TASK_170 warning gate blocked leak warnings:"
		$blockedHits | Select-Object -Unique | ForEach-Object { Write-Output $_ }
	}
	if ($exitCode -ne 0) {
		Write-Output "TASK_170 verifier exited with code $exitCode."
	}
	exit 1
}

Write-Output "TASK_170 warning gate passed without blocked RID/ObjectDB leak patterns."
exit 0
