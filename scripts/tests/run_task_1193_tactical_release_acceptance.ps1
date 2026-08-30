param(
	[string]$GodotExecutable = "godot_console.exe",
	[int]$ColdRuns = 3,
	[int]$WarmRuns = 5,
	[string]$ManualEvidencePath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$gitSha = (git -C $projectRoot rev-parse HEAD).Trim()
$budgetPath = Join-Path $projectRoot 'data\performance_budget_contract.json'
$budgetContract = Get-Content -Raw $budgetPath | ConvertFrom-Json
$acceptance = $budgetContract.release_acceptance
$godotCommand = Get-Command $GodotExecutable -ErrorAction SilentlyContinue
if ($null -eq $godotCommand) {
	throw "Godot executable '$GodotExecutable' was not found in PATH."
}
if ($ColdRuns -lt 0 -or $WarmRuns -lt 0 -or ($ColdRuns + $WarmRuns) -lt 1) {
	throw 'At least one tactical-map frame-budget run is required.'
}

if ([string]::IsNullOrWhiteSpace($ManualEvidencePath)) {
	$relativeManualEvidencePath = ([string]$acceptance.manual_evidence_path).Replace('res://', '').Replace('/', [System.IO.Path]::DirectorySeparatorChar)
	$ManualEvidencePath = Join-Path $projectRoot $relativeManualEvidencePath
}

$failures = New-Object System.Collections.Generic.List[string]
$enforcers = New-Object System.Collections.Generic.List[object]

function Invoke-GodotEnforcer {
	param(
		[string]$Name,
		[string]$ScriptPath
	)
	$output = & $godotCommand.Source --headless --path $projectRoot --script $ScriptPath 2>&1
	$exitCode = $LASTEXITCODE
	$output | ForEach-Object { Write-Output $_ }
	$text = $output -join [Environment]::NewLine
	$passed = $exitCode -eq 0 -and $text -notmatch '(^|\s)FAIL(:|$)' -and $text -notmatch 'SCRIPT ERROR:'
	$enforcers.Add([pscustomobject]@{name=$Name; passed=$passed; exit_code=$exitCode})
	if (-not $passed) {
		$failures.Add("$Name failed (exit=$exitCode).")
	}
}

foreach ($enforcer in @(
	@{name='TASK_1179'; script='scripts/tests/task_1179_ground_mission_objective_playthrough.gd'},
	@{name='TASK_1192'; script='scripts/tests/task_1192_release_first_exchange_fixture.gd'},
	@{name='TASK_284'; script='scripts/tests/task_284_gameplay_truth_architecture_boundary_audit.gd'},
	@{name='TASK_832'; script='scripts/tests/task_832_release_first_go_firefight_deeplink_evidence.gd'},
	@{name='TASK_868'; script='scripts/tests/task_868_release_first_exchange_los_setup_polish.gd'},
	@{name='TASK_411'; script='scripts/tests/task_411_large_map_scale_profile.gd'},
	@{name='TASK_222'; script='scripts/tests/task_222_performance_regression_gate_and_manual_profile_checklist.gd'}
)) {
	Invoke-GodotEnforcer -Name $enforcer.name -ScriptPath $enforcer.script
}

$frameBudgetScript = Join-Path $PSScriptRoot 'run_task_1187_tactical_map_frame_budget.ps1'
$frameOutput = & $frameBudgetScript -Mode Measure -ColdRuns $ColdRuns -WarmRuns $WarmRuns -GodotExecutable $godotCommand.Source 2>&1
$frameExitCode = $LASTEXITCODE
$frameOutput | ForEach-Object { Write-Output $_ }
$frameJsonLines = @($frameOutput | Where-Object { $_ -match '^TACTICAL_MAP_FRAME_BUDGET_JSON=' })
$framePassed = $frameExitCode -eq 0 -and $frameJsonLines.Count -eq ($ColdRuns + $WarmRuns)
$enforcers.Add([pscustomobject]@{name='TASK_1187'; passed=$framePassed; exit_code=$frameExitCode})
if (-not $framePassed) {
	$failures.Add("TASK_1187 measurement enforcer failed (exit=$frameExitCode, samples=$($frameJsonLines.Count)).")
}
foreach ($line in $frameJsonLines) {
	$report = $line.Substring('TACTICAL_MAP_FRAME_BUDGET_JSON='.Length) | ConvertFrom-Json
	foreach ($scope in $report.budget_status.PSObject.Properties) {
		if ([string]$scope.Value.status -ne 'pass') {
			$failures.Add("TASK_1187 budget $($scope.Name) is $($scope.Value.status).")
		}
	}
}

$manualEvidencePassed = $false
if (-not (Test-Path -LiteralPath $ManualEvidencePath)) {
	$failures.Add("Manual evidence is missing: $ManualEvidencePath")
} else {
	$manualEvidence = Get-Content -Raw -LiteralPath $ManualEvidencePath
	$requiredFields = @($acceptance.manual_evidence_required_fields)
	$missingFields = @($requiredFields | Where-Object { -not $manualEvidence.Contains([string]$_) })
	$shaExpected = "git_sha: $gitSha"
	if (-not $manualEvidence.Contains($shaExpected)) {
		$missingFields += $shaExpected
	}
	if ($manualEvidence -match 'synthetic_fixture:\s*true') {
		$missingFields += 'synthetic_fixture: false'
	}
	if ($missingFields.Count -gt 0) {
		$failures.Add("Manual evidence is incomplete or synthetic: $($missingFields -join ', ')")
	} else {
		$manualEvidencePassed = $true
	}
}

$releaseStatus = 'blocked'
if ($failures.Count -eq 0 -and $manualEvidencePassed) {
	$releaseStatus = 'approved'
}
$summary = [ordered]@{
	schema = 'sternenbuergerchen.tactical_release_acceptance.v1'
	task_id = 'TASK_1193'
	git_sha = $gitSha
	release_status = $releaseStatus
	supported_max_map_size = $acceptance.supported_max_map_size
	manual_evidence_path = $ManualEvidencePath
	manual_evidence_passed = $manualEvidencePassed
	enforcers = @($enforcers.ToArray())
	failures = @($failures | Select-Object -Unique)
}
Write-Output ('TACTICAL_RELEASE_ACCEPTANCE_JSON=' + ($summary | ConvertTo-Json -Depth 8 -Compress))
if ($releaseStatus -eq 'blocked') {
	$summary.failures | ForEach-Object { Write-Output "RELEASE BLOCKED: $_" }
	exit 1
}

Write-Output 'TASK_1193 tactical release acceptance approved.'
exit 0
