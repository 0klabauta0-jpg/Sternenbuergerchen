extends SceneTree

const STATE_SCRIPT: GDScript = preload("res://scripts/mission/mission_fireteam_runtime_state.gd")
const STATE_SCRIPT_PATH: String = "res://scripts/mission/mission_fireteam_runtime_state.gd"
const CONTROLLER_SCRIPT_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const TASK_DOC_PATH: String = "res://docs/tasks/TASK_512_mission_controller_boundary_slice.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"

var _passed: int = 0
var _failed: int = 0


class MissionRuntimeStateMockUnit:
	extends Node
	var unit_id: String = ""
	var fireteam_id: String = ""

	func _init(next_unit_id: String, next_fireteam_id: String) -> void:
		unit_id = next_unit_id
		fireteam_id = next_fireteam_id

	func get_unit_id() -> String:
		return unit_id

	func get_fireteam_id() -> String:
		return fireteam_id


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_512 Mission Controller Boundary Slice ===")
	_test_unit_transport_state()
	_test_displayable_fireteam_ids()
	_test_runtime_active_modes()
	_test_source_boundaries()
	_test_docs_reference_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_unit_transport_state() -> void:
	var state = STATE_SCRIPT.new()
	var blue_a := MissionRuntimeStateMockUnit.new("blue_a", "blue")
	var blue_b := MissionRuntimeStateMockUnit.new("blue_b", "blue")
	var embarked: Dictionary = {"blue_a": true}
	var deployed: Dictionary = {}
	_assert(bool(state.call("is_unit_embarked_without_deployment", blue_a, embarked, deployed)), "Embarked non-deployed unit is treated as in-transit")
	_assert(not bool(state.call("is_unit_embarked_without_deployment", blue_b, embarked, deployed)), "Ground unit is not treated as in-transit")
	var filtered: Array = Array(state.call("filter_ground_units", [blue_a, blue_b], embarked, deployed))
	_assert(filtered.size() == 1 and filtered[0] == blue_b, "Ground filter hides embarked non-deployed units")
	deployed["blue_a"] = true
	filtered = Array(state.call("filter_ground_units", [blue_a, blue_b], embarked, deployed))
	_assert(filtered.size() == 2, "Deployed units return to the ground unit set even if old embark state is present")
	_free_units([blue_a, blue_b])


func _test_displayable_fireteam_ids() -> void:
	var state = STATE_SCRIPT.new()
	var blue := MissionRuntimeStateMockUnit.new("blue_a", "blue")
	var gold := MissionRuntimeStateMockUnit.new("gold_a", "gold")
	var available := PackedStringArray(["blue", "gold"])
	var embarked: Dictionary = {"blue_a": true}
	var deployed: Dictionary = {}
	var displayable: PackedStringArray = PackedStringArray(state.call("build_displayable_fireteam_ids", available, [blue, gold], embarked, deployed))
	_assert(not displayable.has("blue") and displayable.has("gold"), "Embarked fireteam is hidden from displayable ground HUD IDs")
	deployed["blue_a"] = true
	displayable = PackedStringArray(state.call("build_displayable_fireteam_ids", available, [blue, gold], embarked, deployed))
	_assert(displayable.has("blue") and displayable.has("gold"), "Deployed fireteam returns to displayable ground HUD IDs")
	_free_units([blue, gold])


func _test_runtime_active_modes() -> void:
	var state = STATE_SCRIPT.new()
	var blue := MissionRuntimeStateMockUnit.new("blue_a", "blue")
	var deployed: Dictionary = {"blue_a": true}
	_assert(bool(state.call("is_fireteam_runtime_active", "blue", [blue], [], {}, false, false)), "Legacy visibility mode treats visible fireteam units as runtime-active")
	_assert(not bool(state.call("is_fireteam_runtime_active", "blue", [], [blue], {}, false, false)), "Legacy visibility mode does not activate hidden non-visible units")
	_assert(bool(state.call("is_fireteam_runtime_active", "blue", [], [blue], deployed, true, false)), "Deferred activation mode treats deployed units as runtime-active")
	_assert(not bool(state.call("is_fireteam_runtime_active", "blue", [blue], [blue], deployed, true, true)), "Preview mode never treats fireteams as runtime-active")
	_free_units([blue])


func _test_source_boundaries() -> void:
	var helper_source: String = _read_text(STATE_SCRIPT_PATH)
	var controller_source: String = _read_text(CONTROLLER_SCRIPT_PATH)
	_assert(helper_source.contains("class_name MissionFireteamRuntimeState"), "Mission fireteam runtime state helper exists under scripts/mission")
	_assert(not helper_source.contains("enqueue_command") and not helper_source.contains("enqueue_effect"), "Helper does not mutate SimulationRoot command or effect queues")
	_assert(not helper_source.contains("get_node_or_null") and not helper_source.contains("get_tree()"), "Helper has no SceneTree dependency")
	_assert(controller_source.contains("MISSION_FIRETEAM_RUNTIME_STATE_SCRIPT"), "Mission controller preloads the helper")
	_assert(controller_source.contains("build_displayable_fireteam_ids"), "Mission controller delegates displayable fireteam IDs to the helper")


func _test_docs_reference_task() -> void:
	var task_doc: String = _read_text(TASK_DOC_PATH)
	var roadmap: String = _read_text(ROADMAP_PATH)
	var status: String = _read_text(STATUS_PATH)
	_assert(task_doc.contains("TASK_512 - Mission Controller Boundary Slice"), "TASK_512 task file exists")
	_assert(roadmap.contains("TASK_512 - Mission Controller Boundary Slice"), "Roadmap lists TASK_512")
	_assert(status.contains("TASK_512 - Mission Controller Boundary Slice"), "Implementation status lists TASK_512")


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _free_units(units: Array) -> void:
	for unit in units:
		if unit is Object and is_instance_valid(unit):
			unit.free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
