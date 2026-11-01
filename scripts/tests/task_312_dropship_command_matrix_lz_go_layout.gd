extends SceneTree

const LZ_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/dropship_lz_accuracy_contract.gd")
const COMMAND_HIERARCHY_SCRIPT: GDScript = preload("res://scripts/ui/mission_command_hierarchy_contract.gd")
const MISSION_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_312 Dropship Command Matrix LZ Go Layout ===")
	var blocked: Dictionary = Dictionary(LZ_CONTRACT_SCRIPT.call("build_command_matrix_state", {"has_lz": false, "has_pilot": true, "has_boarded_team": true}))
	var ready: Dictionary = Dictionary(COMMAND_HIERARCHY_SCRIPT.call("build_dropship_command_matrix_layout_snapshot", {"has_lz": true, "has_pilot": true, "has_boarded_team": true}))
	_assert(String(blocked.get("go_button_panel_role", "")) == "#16", "Dropship Go belongs to Command Matrix #16")
	_assert(String(blocked.get("go_button_slot", "")) == "16.15", "GO is assigned to command matrix button 16.15")
	await _test_native_plan_execution_position()
	_assert(PackedStringArray(blocked.get("disabled_reasons", PackedStringArray())).has("no_lz"), "Go disabled explains missing LZ")
	_assert(bool(ready.get("go_enabled", false)), "Go enables when LZ/pilot/team are ready")
	_assert(bool(ready.get("legacy_window_17_go_removed", false)), "Large old window-17 Go slot is retired")
	_assert(PackedStringArray(ready.get("approach_style_options", PackedStringArray())).has("aggressiv"), "Approach style remains near Go flow")
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_native_plan_execution_position() -> void:
	# Stable legacy slot IDs describe transport metadata; A5's existing plan
	# execution node is now visibly to the right of Flank in the first row.
	var scene := MISSION_SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(4):
		await process_frame
	var controller := scene.get_node("TacticalController")
	var go_button := controller.get_node_or_null(String(COMMAND_HIERARCHY_SCRIPT.get("BUTTON_PATH_GO_PLAN"))) as Button
	var flank_button := controller.get_node_or_null(String(COMMAND_HIERARCHY_SCRIPT.get("BUTTON_PATH_FLANK"))) as Button
	_assert(go_button != null and flank_button != null, "Native plan execution preserves its existing hierarchy path")
	if go_button != null and flank_button != null:
		var go_rect := go_button.get_global_rect()
		var flank_rect := flank_button.get_global_rect()
		_assert(go_rect.position.x >= flank_rect.end.x and absf(go_rect.position.y - flank_rect.position.y) <= 1.0, "Plan execution is directly right of Flank in the first A5 row")
		_assert(not go_button.get_signal_connection_list("pressed").is_empty(), "Plan execution retains its existing command callback")
	scene.queue_free()
	for _frame in range(2):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
