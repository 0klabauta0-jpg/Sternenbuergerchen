extends SceneTree

const LZ_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/dropship_lz_accuracy_contract.gd")
const COMMAND_HIERARCHY_SCRIPT: GDScript = preload("res://scripts/ui/mission_command_hierarchy_contract.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_312 Dropship Command Matrix LZ Go Layout ===")
	var blocked: Dictionary = Dictionary(LZ_CONTRACT_SCRIPT.call("build_command_matrix_state", {"has_lz": false, "has_pilot": true, "has_boarded_team": true}))
	var ready: Dictionary = Dictionary(COMMAND_HIERARCHY_SCRIPT.call("build_dropship_command_matrix_layout_snapshot", {"has_lz": true, "has_pilot": true, "has_boarded_team": true}))
	_assert(String(blocked.get("go_button_panel_role", "")) == "#16", "Dropship Go belongs to Command Matrix #16")
	_assert(PackedStringArray(blocked.get("disabled_reasons", PackedStringArray())).has("no_lz"), "Go disabled explains missing LZ")
	_assert(bool(ready.get("go_enabled", false)), "Go enables when LZ/pilot/team are ready")
	_assert(bool(ready.get("legacy_window_17_go_removed", false)), "Large old window-17 Go slot is retired")
	_assert(PackedStringArray(ready.get("approach_style_options", PackedStringArray())).has("aggressiv"), "Approach style remains near Go flow")
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
