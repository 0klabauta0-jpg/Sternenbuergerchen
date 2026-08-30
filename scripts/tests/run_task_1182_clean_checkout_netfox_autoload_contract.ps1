param(
	[ValidateSet('PreImport', 'PostImport')]
	[string]$Phase = 'PostImport',
	[string]$GodotExecutable = 'godot_console.exe',
	[int]$SmokeSeconds = 3
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$projectFile = Join-Path $projectRoot 'project.godot'
$netfoxAutoloads = @(
	'NetworkTime',
	'NetworkTimeSynchronizer',
	'NetworkRollback',
	'NetworkEvents',
	'NetworkPerformance',
	'RollbackSimulationServer',
	'NetworkHistoryServer',
	'NetworkSynchronizationServer',
	'NetworkIdentityServer',
	'NetworkCommandServer',
	'RollbackLivenessServer'
)

if ($Phase -eq 'PreImport' -and (Test-Path -LiteralPath (Join-Path $projectRoot '.godot'))) {
	throw 'TASK_1182 PreImport requires a checkout without .godot.'
}

$autoloadValues = @{}
foreach ($line in Get-Content -LiteralPath $projectFile) {
	if ($line -match '^(?<name>[^=]+)="(?<value>[^\"]+)"$') {
		$autoloadValues[$Matches.name] = $Matches.value
	}
}

foreach ($autoloadName in $netfoxAutoloads) {
	if (-not $autoloadValues.ContainsKey($autoloadName)) {
		throw "TASK_1182 missing autoload '$autoloadName'."
	}
	$value = [string]$autoloadValues[$autoloadName]
	if ($value -notmatch '^\*res://(?<path>.+\.gd)$') {
		throw "TASK_1182 '$autoloadName' must use a stable res:// script path, got '$value'."
	}
	$relativePath = $Matches.path.Replace('/', '\\')
	$absolutePath = Join-Path $projectRoot $relativePath
	if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
		throw "TASK_1182 '$autoloadName' points to missing script '$relativePath'."
	}
	& git -C $projectRoot ls-files --error-unmatch -- $relativePath *> $null
	if ($LASTEXITCODE -ne 0) {
		throw "TASK_1182 '$autoloadName' script is not tracked: '$relativePath'."
	}
}

if ($Phase -eq 'PreImport') {
	Write-Output 'TASK_1182 PREIMPORT PASS (11 tracked Netfox autoload scripts)'
	exit 0
}

$godotCommand = Get-Command $GodotExecutable -ErrorAction SilentlyContinue
$godotPath = if ($null -ne $godotCommand) { $godotCommand.Source } elseif (Test-Path -LiteralPath $GodotExecutable) { (Resolve-Path -LiteralPath $GodotExecutable).Path } else { '' }
if ([string]::IsNullOrWhiteSpace($godotPath)) {
	throw "Godot executable '$GodotExecutable' was not found."
}

$smokeOutput = & $godotPath --headless --path $projectRoot --quit-after $SmokeSeconds 2>&1
$smokeExit = $LASTEXITCODE
$smokeText = $smokeOutput -join [Environment]::NewLine
$errorPatterns = @('Unrecognized UID', 'Failed to instantiate an autoload', 'Failed to create an autoload', 'Resource file not found: res://')
$matchedPatterns = @($errorPatterns | Where-Object { $smokeText.Contains($_) })
if ($smokeExit -ne 0 -or $matchedPatterns.Count -gt 0) {
	$details = if ($matchedPatterns.Count -gt 0) { $matchedPatterns -join ', ' } else { 'non-zero Godot exit' }
	throw "TASK_1182 PostImport smoke failed (exit=$smokeExit; $details)."
}

Write-Output 'TASK_1182 POSTIMPORT PASS (11 tracked Netfox autoload scripts; no UID/autoload smoke errors)'
exit 0
