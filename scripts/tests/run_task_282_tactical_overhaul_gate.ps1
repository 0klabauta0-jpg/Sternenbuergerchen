$ErrorActionPreference = "Stop"

godot_console.exe --headless --path . --script scripts/tests/task_282_tactical_overhaul_playability_performance_help_gate.gd
godot_console.exe --headless --path . --script scripts/tests/task_268_post_help_popup_playability_regression_smoke.gd
godot_console.exe --headless --path . --script scripts/tests/task_281_tactical_command_multiplayer_authority_snapshot.gd
git diff --check
