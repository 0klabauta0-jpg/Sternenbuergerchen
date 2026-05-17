extends SceneTree

const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const FIRETEAM_BEHAVIOR_PROFILE_SCRIPT: GDScript = preload("res://scripts/command/fireteam_behavior_profile.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_460_fireteam_movement_avoidance_stability.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/fireteam_behavior_modes_contract.md"
const MOVEMENT_CONTROLLER_PATH: String = "res://scripts/tactical/fireteam_movement_controller.gd"
const SIMULATION_ROOT_PATH: String = "res://scripts/core/simulation_root.gd"

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
	print("=== TASK_460 Fireteam Movement Avoidance Stability ===")
	_test_fireteam_move_commands_request_local_avoidance()
	_test_fireteam_bounding_only_movers_request_local_avoidance()
	_test_command_local_avoidance_runs_without_global_root_switch()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_fireteam_move_commands_request_local_avoidance() -> void:
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var units: Array = _make_fireteam_units("move_avoid")
	var result: Dictionary = Dictionary(controller.call("start_execution", "drill", "move", 1, Vector2(420.0, 0.0), _make_profile(FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL), units, units[0], simulation))
	var state: Dictionary = Dictionary(result.get("movement_state", {}))

	_assert(bool(result.get("started", false)), "Move execution starts")
	_assert(bool(state.get("local_avoidance_command_opt_in", false)), "Movement state exposes fireteam local-avoidance opt-in")
	_assert(simulation.commands.size() == 4, "Move issues four member commands")
	_assert(_all_moving_commands_have_local_avoidance(simulation.commands), "Every Move member command requests local avoidance")
	_cleanup_units(units)


func _test_fireteam_bounding_only_movers_request_local_avoidance() -> void:
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var units: Array = _make_fireteam_units("engage_avoid")
	var result: Dictionary = Dictionary(controller.call("start_execution", "drill", "engage", 1, Vector2(420.0, 0.0), _make_profile(FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS), units, units[0], simulation))
	var move_count: int = 0
	var hold_count: int = 0

	_assert(bool(result.get("started", false)), "Cautious Engage execution starts")
	for command_variant in simulation.commands:
		var command: Dictionary = Dictionary(command_variant)
		var command_type: String = String(command.get("command_type", ""))
		if command_type == UNIT_COMMAND_SCRIPT.TYPE_HOLD_POSITION:
			hold_count += 1
			_assert(not bool(command.get("local_avoidance_enabled", false)), "Covering hold command does not request movement avoidance")
		else:
			move_count += 1
			_assert(bool(command.get("local_avoidance_enabled", false)), "Moving Engage command requests local avoidance")
			_assert(String(command.get("local_avoidance_source", "")) == "fireteam_movement_controller", "Moving Engage command exposes avoidance source")

	_assert(move_count > 0 and hold_count > 0, "Cautious Engage has moving and covering commands")
	_cleanup_units(units)


func _test_command_local_avoidance_runs_without_global_root_switch() -> void:
	var scene := Node.new()
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	simulation_root.name = "SimulationRoot"
	scene.add_child(unit_registry)
	scene.add_child(simulation_root)
	get_root().add_child(scene)
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	simulation_root.unit_minimum_spacing_enabled = false
	simulation_root.local_avoidance_enabled = false
	simulation_root.local_avoidance_debug_enabled = true
	simulation_root.local_avoidance_agent_radius = 24.0
	simulation_root.local_avoidance_neighbor_radius = 160.0

	var alpha := _make_unit("alpha", "drill", true, Vector2(-36.0, 0.0))
	var bravo := _make_unit("bravo", "drill", false, Vector2(36.0, 0.0))
	scene.add_child(alpha)
	scene.add_child(bravo)
	unit_registry.call("register_unit", alpha.get_unit_id(), alpha)
	unit_registry.call("register_unit", bravo.get_unit_id(), bravo)

	simulation_root.call("enqueue_command", _build_runtime_move_command("alpha", Vector2(80.0, 0.0), true))
	simulation_root.call("enqueue_command", _build_runtime_move_command("bravo", Vector2(-80.0, 0.0), true))
	simulation_root.call("_physics_process", 0.1)

	var snapshot: Dictionary = Dictionary(simulation_root.call("get_local_avoidance_debug_snapshot", "alpha"))
	_assert(int(snapshot.get("neighbor_count", 0)) > 0, "Command-local avoidance builds a neighbor set while global root switch is off")
	_assert(bool(snapshot.get("command_local_avoidance_enabled", false)), "Avoidance debug marks command-local opt-in")
	_assert(Vector2(snapshot.get("correction_velocity", Vector2.ZERO)).length() > 0.01, "Command-local avoidance computes a correction velocity")

	scene.queue_free()


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var movement_text: String = _read_text(MOVEMENT_CONTROLLER_PATH)
	var simulation_text: String = _read_text(SIMULATION_ROOT_PATH)
	_assert(task_text.contains("TASK_460 - Fireteam Movement Avoidance Stability"), "TASK_460 task file exists")
	_assert(status_text.contains("TASK_460 - Fireteam Movement Avoidance Stability"), "Implementation status documents TASK_460")
	_assert(roadmap_text.contains("TASK_460 - Fireteam Movement Avoidance Stability"), "Roadmap lists TASK_460")
	_assert(contract_text.contains("TASK_460 Movement-/Avoidance-Stabilitaet"), "Behavior contract documents TASK_460")
	_assert(movement_text.contains("FIRETEAM_LOCAL_AVOIDANCE_SOURCE_ID"), "Movement controller exposes fireteam avoidance source")
	_assert(simulation_text.contains("command_local_avoidance_enabled"), "SimulationRoot debug exposes command-local avoidance")


func _make_profile(tactical_stance: String) -> Dictionary:
	return {
		"advance_style": FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_RUSH,
		"tactical_stance": tactical_stance,
		"cover_priority": 0.55,
		"cohesion_threshold": 120.0,
		"order_fidelity": 1.0,
		"execution_cohesion": 0.65,
		"initiative": 0.5,
	}


func _make_fireteam_units(fireteam_id: String) -> Array:
	return [
		_make_unit("%s_lead" % fireteam_id, fireteam_id, true, Vector2(0.0, 0.0)),
		_make_unit("%s_a" % fireteam_id, fireteam_id, false, Vector2(-18.0, 4.0)),
		_make_unit("%s_b" % fireteam_id, fireteam_id, false, Vector2(16.0, -4.0)),
		_make_unit("%s_c" % fireteam_id, fireteam_id, false, Vector2(0.0, 18.0)),
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


func _build_runtime_move_command(unit_id: String, target_position: Vector2, local_avoidance: bool) -> Dictionary:
	return {
		"command_type": UNIT_COMMAND_SCRIPT.TYPE_MOVE_TO_POSITION,
		"unit_id": unit_id,
		"team_id": "team_alpha",
		"target_position": target_position,
		"move_speed_factor": 1.0,
		"local_avoidance_enabled": local_avoidance,
		"requeue_until_target": true,
	}


func _all_moving_commands_have_local_avoidance(commands: Array) -> bool:
	if commands.is_empty():
		return false
	for command_variant in commands:
		var command: Dictionary = Dictionary(command_variant)
		var command_type: String = String(command.get("command_type", ""))
		if command_type == UNIT_COMMAND_SCRIPT.TYPE_HOLD_POSITION:
			continue
		if not bool(command.get("local_avoidance_enabled", false)):
			return false
		if String(command.get("local_avoidance_source", "")) != "fireteam_movement_controller":
			return false
	return true


func _cleanup_units(units: Array) -> void:
	for unit in units:
		if unit is Node:
			(unit as Node).queue_free()


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
