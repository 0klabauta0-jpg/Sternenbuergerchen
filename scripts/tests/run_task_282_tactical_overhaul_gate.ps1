$ErrorActionPreference = "Stop"

godot_console.exe --headless --path . --script scripts/tests/task_282_tactical_overhaul_playability_performance_help_gate.gd
$task282Exit = $LASTEXITCODE
if ($task282Exit -ne 0) { exit $task282Exit }
godot_console.exe --headless --path . --script scripts/tests/task_268_post_help_popup_playability_regression_smoke.gd
$task268Exit = $LASTEXITCODE
if ($task268Exit -ne 0) { exit $task268Exit }
godot_console.exe --headless --path . --script scripts/tests/task_281_tactical_command_multiplayer_authority_snapshot.gd
$task281Exit = $LASTEXITCODE
if ($task281Exit -ne 0) { exit $task281Exit }
git diff --check
