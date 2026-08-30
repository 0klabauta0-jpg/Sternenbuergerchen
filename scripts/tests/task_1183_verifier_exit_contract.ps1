Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$failures = New-Object System.Collections.Generic.List[string]

Get-ChildItem -LiteralPath (Join-Path $projectRoot 'scripts\tests') -Filter '*.gd' -File | Sort-Object FullName | ForEach-Object {
	$lines = Get-Content -LiteralPath $_.FullName
	$hasFailedCounter = $lines | Where-Object { $_ -match '\b_failed\b' } | Select-Object -First 1
	$bareQuitLines = @($lines | Select-String -Pattern '^\s*quit\(\)\s*(#.*)?$')
	if ($null -ne $hasFailedCounter -and $bareQuitLines.Count -gt 0) {
		foreach ($bareQuit in $bareQuitLines) {
			$relativePath = $_.FullName.Substring($projectRoot.Length + 1).Replace('\', '/')
			$failures.Add("GDScript bare quit with _failed: ${relativePath}:$($bareQuit.LineNumber)")
		}
	}
}

Get-ChildItem -LiteralPath (Join-Path $projectRoot 'scripts\tests') -Filter 'run_task_*.ps1' -File | Sort-Object FullName | ForEach-Object {
	$lines = Get-Content -LiteralPath $_.FullName
	for ($index = 0; $index -lt $lines.Count; $index += 1) {
		if ($lines[$index] -notmatch '^\s*(?:&\s*)?(?:[A-Za-z0-9_./\\:-]*godot(?:_console)?(?:\.exe)?|\$[A-Za-z_][A-Za-z0-9_.]*godot[A-Za-z0-9_.]*)\b') {
			continue
		}
		$followingLines = ($lines | Select-Object -Skip ($index + 1) -First 4) -join "`n"
		if ($followingLines -notmatch '\$[A-Za-z_][A-Za-z0-9_]*\s*=\s*\$LASTEXITCODE') {
			$relativePath = $_.FullName.Substring($projectRoot.Length + 1).Replace('\', '/')
			$failures.Add("Runner does not capture native exit immediately: ${relativePath}:$($index + 1)")
		}
	}
}

if ($failures.Count -gt 0) {
	Write-Output "TASK_1183 EXIT CONTRACT FAILED ($($failures.Count) findings)"
	$failures | ForEach-Object { Write-Output "- $_" }
	exit 1
}

Write-Output 'TASK_1183 EXIT CONTRACT PASSED (0 findings)'
exit 0
