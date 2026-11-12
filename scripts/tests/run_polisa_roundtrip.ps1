param([int]$TimeoutSeconds = 240)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$gitRoot = (& git -C $projectRoot rev-parse --show-toplevel).Trim()
if ($LASTEXITCODE -ne 0 -or (Resolve-Path $gitRoot).Path -ne $projectRoot) { throw 'Unexpected project source root' }
$sourcePaths = @('scripts/meta/meta_layer_flow.gd', 'scripts/meta/singleplayer_runtime_adapter.gd', 'scripts/tests/mission_tactical_sandbox_controller.gd', 'scripts/tests/polisa_real_roundtrip_verifier.gd', 'scripts/core/simulation_root.gd', 'scripts/core/singleplayer_ship_equipment_state.gd', 'scripts/core/singleplayer_supply_state.gd', 'scripts/mission/space_component_catalog.gd', 'scripts/mission/inventory_transfer_contract.gd', 'data/singleplayer/trade_offers.json', 'data/space/ship_components.json')
$before = @{}
foreach ($path in $sourcePaths) { $before[$path] = (Get-FileHash -LiteralPath (Join-Path $projectRoot $path) -Algorithm SHA256).Hash }
$profile = Join-Path ([IO.Path]::GetTempPath()) ('codex-polisa-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $profile | Out-Null
$startInfo = [Diagnostics.ProcessStartInfo]::new()
$startInfo.FileName = (Get-Command godot_console.exe -ErrorAction Stop).Source
$startInfo.WorkingDirectory = $projectRoot
$startInfo.UseShellExecute = $false
$startInfo.CreateNoWindow = $true
$startInfo.RedirectStandardOutput = $true
$startInfo.RedirectStandardError = $true
$startInfo.Environment['APPDATA'] = $profile
$startInfo.Environment['POLISA_TEST_PROFILE'] = $profile
foreach ($argument in @('--headless', '--path', $projectRoot, '--script', 'res://scripts/tests/polisa_real_roundtrip_verifier.gd')) { $startInfo.ArgumentList.Add($argument) }
$process = [Diagnostics.Process]::new()
$process.StartInfo = $startInfo
[void]$process.Start()
$stdout = $process.StandardOutput.ReadToEndAsync()
$stderr = $process.StandardError.ReadToEndAsync()
$finished = $process.WaitForExit($TimeoutSeconds * 1000)
if (-not $finished) { $process.Kill($true); $process.WaitForExit() }
$log = $stdout.GetAwaiter().GetResult() + $stderr.GetAwaiter().GetResult()
$logPath = Join-Path $profile 'polisa-roundtrip.log'
[IO.File]::WriteAllText($logPath, $log)
$exitCode = if ($finished) { $process.ExitCode } else { -1 }
$errors = [regex]::Matches($log, '(?m)^(?:SCRIPT ERROR|ERROR:|FAIL:)').Count
$sourceChanged = @($sourcePaths | Where-Object { (Get-FileHash -LiteralPath (Join-Path $projectRoot $_) -Algorithm SHA256).Hash -ne $before[$_] })
$result = [pscustomobject]@{ source_commit = (& git -C $projectRoot rev-parse HEAD).Trim(); source_files_sha256 = $before; changed_sources = $sourceChanged; profile = $profile; exit_code = $exitCode; errors = $errors; log = $logPath }
$result | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $profile 'result.json') -Encoding utf8
Write-Output ($result | ConvertTo-Json -Depth 5)
$process.Dispose()
if ($exitCode -ne 0 -or $errors -ne 0 -or $sourceChanged.Count -ne 0 -or $log -notmatch 'ORBIT_QUANTUM_FLOW passed=25 failed=0') { exit 1 }
