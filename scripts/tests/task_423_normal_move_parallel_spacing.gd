extends SceneTree

const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const FIRETEAM_BEHAVIOR_PROFILE_SCRIPT: GDScript = preload("res://scripts/command/fireteam_behavior_profile.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_423_normal_move_parallel_spacing.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const MOVEMENT_CONTROLLER_PATH: String = "res://scripts/tactical/fireteam_movement_controller.gd"
const MIN_EXPECTED_TARGET_SPACING: float = 36.0

var _passed: int = 0
var _failed: int = 0


class SimulationStub:
	extends RefCounted
	var commands: Array = []

	func enqueue_command(command_dict: Dictionary) -> void:
		commands.append(command_dict.duplicate(true))


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_423 Normal Move Parallel Spacing ===")
	_test_normal_move_issues_all_members_with_spaced_targets()
	_test_runtime_progresses_all_normal_move_members()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_normal_move_issues_all_members_with_spaced_targets() -> void:
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var units: Array = _make_units_for_spacing("spacing")
	var leader = units[0]
	var profile = _make_normal_move_profile("spacing")
	var result: Dictionary = controller.start_execution("spacing", "move", 1, Vector2(260.0, 0.0), profile, units, leader, simulation)
	var movement_state: Dictionary = Dictionary(result.get("movement_state", {}))
	var moving_ids: PackedStringArray = PackedStringArray(movement_state.get("current_moving_unit_ids", PackedStringArray()))

	_assert(bool(result.get("started", false)), "Normal Move execution starts")
	_assert(simulation.commands.size() == units.size(), "Normal Move issues one command per fit member")
	_assert(moving_ids.size() == units.size(), "Normal Move marks all members as moving in the same stage")
	_assert(_all_commands_are_same_stage_move(simulation.commands), "Normal Move commands share one parallel stage")
	_assert(_minimum_target_distance(simulation.commands) >= MIN_EXPECTED_TARGET_SPACING - 0.001, "Normal Move target slots respect runtime spacing")
	_cleanup_units(units)


func _test_runtime_progresses_all_normal_move_members() -> void:
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	simulation_root.name = "SimulationRoot"
	get_root().add_child(unit_registry)
	get_root().add_child(simulation_root)
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	simulation_root.unit_minimum_spacing_enabled = true
	simulation_root.unit_minimum_spacing_distance = 36.0

	var units: Array = _make_units_for_spacing("runtime")
	for unit in units:
		get_root().add_child(unit)
		unit_registry.call("register_unit", String(unit.call("get_unit_id")), unit)

	var leader = units[0]
	var profile = _make_normal_move_profile("runtime")
	controller.start_execution("runtime", "move", 1, Vector2(240.0, 0.0), profile, units, leader, simulation_root)
	var initial_position_by_unit_id: Dictionary = _positions_by_unit_id(units)

	simulation_root._physics_process(0.1)
	_assert(_all_positions_changed(initial_position_by_unit_id, _positions_by_unit_id(units)), "All normal Move members move during the first runtime tick")

	var finished: bool = false
	for _tick in range(80):
		var update_result: Dictionary = controller.update_execution("runtime", units, leader, simulation_root)
		if bool(update_result.get("finished", false)):
			finished = true
			break
		simulation_root._physics_process(0.1)
	_assert(finished, "Parallel normal Move can complete with minimum spacing enabled")

	_cleanup_units(units)
	simulation_root.queue_free()
	unit_registry.queue_free()


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var controller_text: String = _read_text(MOVEMENT_CONTROLLER_PATH)
	_assert(task_text.contains("TASK_423 - Normal Move Parallel Spacing"), "TASK_423 task file exists")
	_assert(status_text.contains("TASK_423 - Normal Move Parallel Spacing"), "Implementation status documents TASK_423")
	_assert(roadmap_text.contains("TASK_423 - Normal Move Parallel Spacing"), "Roadmap lists TASK_423")
	_assert(controller_text.contains("MOVE_TRAVEL_MIN_TARGET_SPACING"), "Movement controller documents normal Move target spacing")
	_assert(controller_text.contains("_apply_parallel_travel_spacing"), "Movement controller applies parallel travel spacing")


func _make_normal_move_profile(fireteam_id: String):
	var profile = FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.new()
	profile.fireteam_id = fireteam_id
	profile.advance_style = FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_RUSH
	profile.tactical_stance = FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL
	profile.cover_priority = 0.4
	profile.cohesion_threshold = 96.0
	profile.order_fidelity = 1.0
	profile.execution_cohesion = 0.65
	profile.initiative = 0.5
	return profile


func _make_units_for_spacing(fireteam_id: String) -> Array:
	return [
		_make_unit("%s_lead" % fireteam_id, fireteam_id, true, Vector2(0.0, 0.0)),
		_make_unit("%s_a" % fireteam_id, fireteam_id, false, Vector2(-12.0, 2.0)),
		_make_unit("%s_b" % fireteam_id, fireteam_id, false, Vector2(10.0, -2.0)),
		_make_unit("%s_c" % fireteam_id, fireteam_id, false, Vector2(0.0, 12.0)),
	]


func _make_unit(unit_id: String, fireteam_id: String, is_lead: bool, position_value: Vector2) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.name = unit_id
	unit.unit_id = unit_id
	unit.team_id = "team_alpha"
	unit.fireteam_id = fireteam_id
	unit.display_name = unit_id
	unit.is_fireteam_lead = is_lead
	unit.global_position = position_value
	unit.skill_speed = 0.5
	unit.skill_toughness = 0.5
	unit.skill_accuracy = 0.5
	unit.weapon_1_id = "rifle"
	unit._ready()
	return unit


func _all_commands_are_same_stage_move(commands: Array) -> bool:
	if commands.is_empty():
		return false
	for command_variant in commands:
		var command: Dictionary = Dictionary(command_variant)
		if String(command.get("command_type", "")) != "move_to_position":
			return false
		if String(command.get("source_command_type", "")) != "move":
			return false
		if not String(command.get("command_token", "")).contains(":1:move:0:"):
			return false
	return true


func _minimum_target_distance(commands: Array) -> float:
	var targets: Array = []
	for command_variant in commands:
		var command: Dictionary = Dictionary(command_variant)
		if typeof(command.get("target_position", null)) == TYPE_VECTOR2:
			targets.append(Vector2(command.get("target_position")))
	if targets.size() < 2:
		return INF
	var minimum_distance: float = INF
	for index_a in range(targets.size()):
		for index_b in range(index_a + 1, targets.size()):
			minimum_distance = minf(minimum_distance, Vector2(targets[index_a]).distance_to(Vector2(targets[index_b])))
	return minimum_distance


func _positions_by_unit_id(units: Array) -> Dictionary:
	var result: Dictionary = {}
	for unit in units:
		var unit_id: String = String(unit.call("get_unit_id"))
		result[unit_id] = (unit as Node2D).global_position
	return result


func _all_positions_changed(before: Dictionary, after: Dictionary) -> bool:
	for unit_id_variant in before.keys():
		var unit_id: String = String(unit_id_variant)
		if not after.has(unit_id):
			return false
		if Vector2(after.get(unit_id)).distance_to(Vector2(before.get(unit_id))) <= 0.1:
			return false
	return true


func _cleanup_units(units: Array) -> void:
	for unit in units:
		if unit != null:
			unit.queue_free()


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
