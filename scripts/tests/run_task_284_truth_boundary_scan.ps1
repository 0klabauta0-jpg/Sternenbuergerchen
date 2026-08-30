$ErrorActionPreference = "Stop"

godot_console.exe --headless --path . --script scripts/tests/task_284_gameplay_truth_architecture_boundary_audit.gd
$task284Exit = $LASTEXITCODE
if ($task284Exit -ne 0) { exit $task284Exit }
godot_console.exe --headless --path . --script scripts/tests/task_166_multiplayer_authority_command_contract_verifier.gd
$task166Exit = $LASTEXITCODE
if ($task166Exit -ne 0) { exit $task166Exit }
git diff --check
