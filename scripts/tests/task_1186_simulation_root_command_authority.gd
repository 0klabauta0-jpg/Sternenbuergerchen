extends SceneTree

const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")
const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1186 SimulationRoot Command Authority ===")
	await _test_producer_enqueues_without_pre_tick_mutation()
	await _test_stale_command_never_becomes_visible()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_producer_enqueues_without_pre_tick_mutation() -> void:
	var context: Dictionary = await _make_context()
	var simulation_root: Node = context["simulation_root"]
	var unit: Node = context["unit"]
	var producer = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var issued: bool = bool(producer.call(
		"_enqueue_unit_command",
		simulation_root,
		"team_alpha",
		"unit_alpha",
		"move_to_position",
		Vector2(32.0, 0.0),
		1.0,
		0.0,
		0.0,
		"move",
		0,
		unit,
		"task1186:accepted",
		"tactical",
		"ready",
		"task1186",
		1.0,
		{},
		{},
		{}
	))
	_assert(issued, "Producer accepts a valid command payload")
	_assert(unit.call("get_current_unit_command") == null, "Producer does not mutate the unit before the root tick")
	_assert(simulation_root.command_queue.size() == 1, "Producer enqueues the command on SimulationRoot")
	simulation_root.call("_physics_process", 0.1)
	var committed = unit.call("get_current_unit_command")
	_assert(committed != null, "SimulationRoot commits the accepted command")
	_assert(_command_token(committed) == "task1186:accepted", "Committed command keeps its token")
	_cleanup_context(context)


func _test_stale_command_never_becomes_visible() -> void:
	var context: Dictionary = await _make_context()
	var simulation_root: Node = context["simulation_root"]
	var unit: Node = context["unit"]
	var current_command = _build_command("task1186:current")
	unit.call("assign_unit_command", current_command)
	simulation_root.call("enqueue_command", _build_command("task1186:stale").to_dict())
	simulation_root.call("_physics_process", 0.1)
	_assert(_command_token(unit.call("get_current_unit_command")) == "task1186:current", "Rejected stale command never changes the unit")
	_assert(simulation_root.command_queue.is_empty(), "Rejected stale command is drained and not requeued")
	_assert(int(simulation_root.call("get_discarded_move_command_count", "stale_command_token")) == 1, "Root records the stale-token rejection")
	_cleanup_context(context)


func _make_context() -> Dictionary:
	var scene := Node.new()
	scene.name = "Task1186CommandAuthority"
	root.add_child(scene)
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	scene.add_child(unit_registry)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	scene.add_child(simulation_root)
	var unit: Node = TEST_UNIT_SCRIPT.new()
	unit.name = "UnitAlpha"
	unit.unit_id = "unit_alpha"
	unit.team_id = "team_alpha"
	scene.add_child(unit)
	unit_registry.call("register_unit", "unit_alpha", unit)
	simulation_root.call("register_known_unit", "unit_alpha", unit)
	await process_frame
	return {"scene": scene, "simulation_root": simulation_root, "unit": unit}


func _build_command(command_token: String):
	var command = UNIT_COMMAND_SCRIPT.new()
	command.command_type = UNIT_COMMAND_SCRIPT.TYPE_MOVE_TO_POSITION
	command.priority = 12
	command.unit_id = "unit_alpha"
	command.team_id = "team_alpha"
	command.target_position = Vector2(32.0, 0.0)
	command.move_speed_factor = 1.0
	command.source_command_type = "move"
	command.command_token = command_token
	return command


func _command_token(command) -> String:
	if command == null:
		return ""
	if typeof(command) == TYPE_DICTIONARY:
		return String(Dictionary(command).get("command_token", ""))
	return String(command.get("command_token"))


func _cleanup_context(context: Dictionary) -> void:
	var scene: Node = context.get("scene", null)
	if scene != null:
		scene.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
