extends SceneTree

const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")

var _passed: int = 0
var _failed: int = 0


class UnitStub:
	extends Node2D

	var unit_id: String = ""
	var team_id: String = "team_alpha"
	var current_command: Dictionary = {}
	var target_position: Variant = null

	func get_unit_id() -> String:
		return unit_id

	func get_team_id() -> String:
		return team_id

	func get_current_unit_command():
		return current_command.duplicate(true)

	func assign_unit_command(command) -> void:
		if command != null and command.has_method("to_dict"):
			current_command = Dictionary(command.call("to_dict")).duplicate(true)
		elif typeof(command) == TYPE_DICTIONARY:
			current_command = Dictionary(command).duplicate(true)

	func set_target_position(next_target_position: Vector2) -> void:
		target_position = next_target_position

	func get_move_speed_factor() -> float:
		return 1.0

	func get_combat_speed_multiplier() -> float:
		return 1.0

	func refresh_terrain_readability() -> void:
		pass


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_501 Integrated Movement Command Lifecycle Hardening ===")
	_test_unregistered_move_command_is_discarded_once()
	_test_stale_tokenized_move_command_is_discarded_without_moving()
	_test_valid_move_command_still_executes()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("TASK_501: ALL PASSED")
		quit(0)


func _test_unregistered_move_command_is_discarded_once() -> void:
	var context: Dictionary = _make_context()
	var simulation_root: Node = context["simulation_root"]
	simulation_root.call("enqueue_command", _build_move_command("missing_unit", Vector2(64.0, 0.0), "missing_token"))
	simulation_root.call("_physics_process", 0.1)
	var discarded: Dictionary = Dictionary(simulation_root.call("get_last_discarded_move_command"))
	_assert(simulation_root.command_queue.is_empty(), "Unregistered move command is drained and not requeued")
	_assert(int(simulation_root.call("get_discarded_move_command_count", "unit_not_registered")) == 1, "Unregistered move command increments the unit_not_registered discard count")
	_assert(String(discarded.get("unit_id", "")) == "missing_unit" and String(discarded.get("reason", "")) == "unit_not_registered", "Discard snapshot identifies the missing unit")
	_assert(not bool(discarded.get("will_requeue", true)), "Discard snapshot documents that the stale command will not requeue")
	_cleanup_context(context)


func _test_stale_tokenized_move_command_is_discarded_without_moving() -> void:
	var context: Dictionary = _make_context()
	var simulation_root: Node = context["simulation_root"]
	var unit_registry: Node = context["unit_registry"]
	var unit := UnitStub.new()
	unit.name = "UnitAlpha"
	unit.unit_id = "unit_alpha"
	unit.current_command = {"command_token": "current_token"}
	context["scene"].add_child(unit)
	unit_registry.call("register_unit", unit.unit_id, unit)

	simulation_root.call("enqueue_command", _build_move_command(unit.unit_id, Vector2(96.0, 0.0), "old_token"))
	simulation_root.call("_physics_process", 0.1)
	var discarded: Dictionary = Dictionary(simulation_root.call("get_last_discarded_move_command"))
	_assert(unit.global_position == Vector2.ZERO, "Stale tokenized move command does not move the unit")
	_assert(simulation_root.command_queue.is_empty(), "Stale tokenized move command is drained and not requeued")
	_assert(int(simulation_root.call("get_discarded_move_command_count", "stale_command_token")) == 1, "Stale tokenized move command increments the stale discard count")
	_assert(String(discarded.get("command_token", "")) == "old_token", "Discard snapshot keeps the rejected command token")
	_cleanup_context(context)


func _test_valid_move_command_still_executes() -> void:
	var context: Dictionary = _make_context()
	var simulation_root: Node = context["simulation_root"]
	var unit_registry: Node = context["unit_registry"]
	var unit := UnitStub.new()
	unit.name = "UnitBravo"
	unit.unit_id = "unit_bravo"
	unit.current_command = {"command_token": "live_token"}
	context["scene"].add_child(unit)
	unit_registry.call("register_unit", unit.unit_id, unit)
	simulation_root.call("clear_discarded_move_command_debug")

	simulation_root.call("enqueue_command", _build_move_command(unit.unit_id, Vector2(32.0, 0.0), "live_token"))
	simulation_root.call("_physics_process", 1.0)
	_assert(unit.global_position.distance_to(Vector2(32.0, 0.0)) <= 0.01, "Valid move command still reaches the target")
	_assert(int(simulation_root.call("get_discarded_move_command_count")) == 0, "Valid move command does not touch discard diagnostics")
	_cleanup_context(context)


func _make_context() -> Dictionary:
	var scene := Node.new()
	scene.name = "Task501Scene"
	root.add_child(scene)
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	scene.add_child(unit_registry)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	scene.add_child(simulation_root)
	return {
		"scene": scene,
		"unit_registry": unit_registry,
		"simulation_root": simulation_root,
	}


func _build_move_command(unit_id: String, target_position: Vector2, command_token: String) -> Dictionary:
	return {
		"command_type": "move_to_position",
		"priority": 12,
		"unit_id": unit_id,
		"team_id": "team_alpha",
		"target_position": target_position,
		"move_speed_factor": 1.0,
		"command_token": command_token,
		"requeue_until_target": true,
	}


func _cleanup_context(context: Dictionary) -> void:
	var scene = context.get("scene", null)
	if scene != null:
		scene.queue_free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
