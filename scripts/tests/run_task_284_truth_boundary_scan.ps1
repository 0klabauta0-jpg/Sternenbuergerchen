$ErrorActionPreference = "Stop"

godot_console.exe --headless --path . --script scripts/tests/task_284_gameplay_truth_architecture_boundary_audit.gd
godot_console.exe --headless --path . --script scripts/tests/task_166_multiplayer_authority_command_contract_verifier.gd
git diff --check
