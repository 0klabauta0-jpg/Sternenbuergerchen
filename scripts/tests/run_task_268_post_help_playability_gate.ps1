param(
    [string]$Godot = "godot_console.exe",
    [switch]$SkipDiffCheck
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$GodotCommand = Get-Command $Godot -ErrorAction SilentlyContinue
if ($null -eq $GodotCommand) {
    Write-Error "Godot executable '$Godot' was not found in PATH."
    exit 1
}

$Tasks = @(
    @{ Id = "TASK_262"; Script = "scripts/tests/task_262_playability_regression_gate_and_manual_open_items.gd"; Kind = "playability_gate" },
    @{ Id = "TASK_267"; Script = "scripts/tests/task_267_contextual_help_coverage_layout_verifier.gd"; Kind = "help_gate" },
    @{ Id = "TASK_268"; Script = "scripts/tests/task_268_post_help_popup_playability_regression_smoke.gd"; Kind = "post_help_smoke" }
)

$Results = @()
$Started = Get-Date

Write-Host "=== TASK_268 Post Help Playability Gate ==="
Write-Host "Repo: $RepoRoot"

foreach ($Task in $Tasks) {
    $TaskStarted = Get-Date
    Write-Host ""
    Write-Host ("--- {0} [{1}] ---" -f $Task.Id, $Task.Kind)
    & $GodotCommand.Source --headless --path $RepoRoot --script $Task.Script
    $ExitCode = $LASTEXITCODE
    $Duration = [math]::Round(((Get-Date) - $TaskStarted).TotalSeconds, 2)
    $Results += [pscustomobject]@{
        Id = $Task.Id
        Kind = $Task.Kind
        Script = $Task.Script
        ExitCode = $ExitCode
        DurationSeconds = $Duration
    }
}

if (-not $SkipDiffCheck) {
    Write-Host ""
    Write-Host "--- git diff --check ---"
    git -C $RepoRoot diff --check
    $Results += [pscustomobject]@{
        Id = "git_diff_check"
        Kind = "workspace"
        Script = "git diff --check"
        ExitCode = $LASTEXITCODE
        DurationSeconds = 0
    }
}

$Failed = @($Results | Where-Object { $_.ExitCode -ne 0 })
$TotalSeconds = [math]::Round(((Get-Date) - $Started).TotalSeconds, 2)

Write-Host ""
Write-Host "=== Gate Summary ==="
foreach ($Result in $Results) {
    $Status = if ($Result.ExitCode -eq 0) { "PASS" } else { "FAIL" }
    Write-Host ("{0,-14} {1,-5} {2,6}s  {3}" -f $Result.Id, $Status, $Result.DurationSeconds, $Result.Script)
}
Write-Host ("Total: {0}s" -f $TotalSeconds)

if ($Failed.Count -gt 0) {
    Write-Host ""
    Write-Host "Hard failures:"
    foreach ($Result in $Failed) {
        Write-Host ("- {0}: exit {1}" -f $Result.Id, $Result.ExitCode)
    }
    exit 1
}

Write-Host ""
Write-Host "Post-help playability gate passed."
exit 0
