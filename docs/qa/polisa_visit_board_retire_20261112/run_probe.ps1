param(
    [Parameter(Mandatory=$true)][string]$PrivateProject,
    [Parameter(Mandatory=$true)][string]$EvidenceDirectory,
    [string]$Baseline = '2bfebc601'
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$project = (Resolve-Path $PrivateProject).Path
New-Item -ItemType Directory -Force -Path $EvidenceDirectory | Out-Null
$evidence = (Resolve-Path $EvidenceDirectory).Path
$profile = Join-Path $evidence 'private-profile'
New-Item -ItemType Directory -Force -Path $profile | Out-Null
$paths = @('scripts/meta/meta_layer_flow.gd', 'scripts/tests/mission_tactical_sandbox_controller.gd', 'scripts/core/simulation_root.gd', 'scripts/core/hex_ground_runtime.gd', 'scripts/registries/unit_registry.gd')
$before = @{}
$baselineMatches = @{}
foreach ($path in $paths) {
    $file = Join-Path $project $path
    $before[$path] = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
    $baselineBlob = (& git -C $root rev-parse "${Baseline}:$path").Trim()
    $privateBlob = (& git -C $root hash-object "--path=$path" $file).Trim()
    $baselineMatches[$path] = $baselineBlob -eq $privateBlob
}
$testFile = Join-Path $project 'scripts/tests/polisa_real_visit_board_retire_probe.gd'
$testBefore = (Get-FileHash -LiteralPath $testFile -Algorithm SHA256).Hash
$process = [System.Diagnostics.Process]::new()
$info = [System.Diagnostics.ProcessStartInfo]::new()
$info.FileName = (Get-Command godot_console.exe -ErrorAction Stop).Source
$info.WorkingDirectory = $project
$info.UseShellExecute = $false
$info.CreateNoWindow = $true
$info.RedirectStandardOutput = $true
$info.RedirectStandardError = $true
$info.Environment['APPDATA'] = $profile
foreach ($arg in @('--headless','--path',$project,'--script','res://scripts/tests/polisa_real_visit_board_retire_probe.gd')) { $info.ArgumentList.Add($arg) }
$process.StartInfo = $info
[void]$process.Start()
$stdout = $process.StandardOutput.ReadToEndAsync()
$stderr = $process.StandardError.ReadToEndAsync()
if (-not $process.WaitForExit(30000)) { $process.Kill($true); $process.WaitForExit(); throw 'Probe timed out' }
$log = $stdout.GetAwaiter().GetResult() + $stderr.GetAwaiter().GetResult()
[IO.File]::WriteAllText((Join-Path $evidence 'output.log'), $log)
$after = @{}
foreach ($path in $paths) { $after[$path] = (Get-FileHash -LiteralPath (Join-Path $project $path) -Algorithm SHA256).Hash }
$unchanged = @($paths | Where-Object { $before[$_] -ne $after[$_] }).Count -eq 0
$testUnchanged = $testBefore -eq (Get-FileHash -LiteralPath $testFile -Algorithm SHA256).Hash
$report = [ordered]@{
    baseline = $Baseline; baseline_blob_matches = $baselineMatches
    private_source_sha256_before = $before; private_source_sha256_after = $after
    private_sources_unchanged = $unchanged; test_sha256 = $testBefore; test_unchanged = $testUnchanged
    private_project = $project; private_appdata = $profile; real_profile_hash_measured = $false
    exit_code = $process.ExitCode; expected_red = $true
    note = 'RED is intentional until AP6 boarding and retirement owners are fixed; actor and view/card inputs are fixtures.'
}
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $evidence 'report.json') -Encoding utf8
Write-Output $log
Write-Output "Exit=$($process.ExitCode); private sources unchanged=$unchanged; test unchanged=$testUnchanged"
$process.Dispose()
if ($report.exit_code -ne 1 -or -not $unchanged -or -not $testUnchanged -or @($baselineMatches.Values | Where-Object { -not $_ }).Count -ne 0) { exit 1 }
