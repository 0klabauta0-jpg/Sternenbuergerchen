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
    @{ Id = "TASK_256"; Script = "scripts/tests/task_256_automated_playability_coverage_contract.gd"; Kind = "contract" },
    @{ Id = "TASK_257"; Script = "scripts/tests/task_257_button_reachability_and_interaction_verifier.gd"; Kind = "buttons" },
    @{ Id = "TASK_258"; Script = "scripts/tests/task_258_fixed_window_clipping_scrollbar_playability_audit.gd"; Kind = "layout" },
    @{ Id = "TASK_259"; Script = "scripts/tests/task_259_character_card_roster_switching_playability.gd"; Kind = "character" },
    @{ Id = "TASK_260"; Script = "scripts/tests/task_260_loadout_selection_decorative_weapons_weight_playability.gd"; Kind = "loadout" },
    @{ Id = "TASK_261"; Script = "scripts/tests/task_261_cross_screen_state_loss_playability_smoke.gd"; Kind = "cross_screen" }
)

$Results = @()
$Started = Get-Date

Write-Host "=== TASK_262 Playability Regression Gate ==="
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
    if ($ExitCode -ne 0) {
        Write-Host ("{0} failed with exit code {1}" -f $Task.Id, $ExitCode)
    }
}

if (-not $SkipDiffCheck) {
    Write-Host ""
    Write-Host "--- git diff --check ---"
    git -C $RepoRoot diff --check
    $DiffExitCode = $LASTEXITCODE
    $Results += [pscustomobject]@{
        Id = "git_diff_check"
        Kind = "workspace"
        Script = "git diff --check"
        ExitCode = $DiffExitCode
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
Write-Host "Playability gate passed."
exit 0
