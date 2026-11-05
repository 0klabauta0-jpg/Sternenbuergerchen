extends SceneTree
## Two fresh actual TestUnits; authority commands and real physics ticks only.

const SIMULATION_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed := 0
var _failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Node.new()
	host.name = "EmptyTokenCommitRegression"
	root.add_child(host)
	var registry = REGISTRY_SCRIPT.new()
	registry.name = "UnitRegistry"
	host.add_child(registry)
	var simulation = SIMULATION_SCRIPT.new()
	simulation.name = "SimulationRoot"
	simulation.unit_registry_path = NodePath("../UnitRegistry")
	host.add_child(simulation)
	var units: Array = []
	for index in range(2):
		var unit = UNIT_SCRIPT.new()
		unit.unit_id = "fresh_hold_%d" % index
		unit.team_id = "team_alpha"
		host.add_child(unit)
		registry.call("register_unit", unit.unit_id, unit)
		units.append(unit)
		_enqueue_hold(simulation, unit)
	await _settle_physics()
	_check(is_equal_approx(Engine.time_scale, 1.0), "Fresh-hold regression uses real 1x physics")
	var committed: Dictionary = simulation.get("_committed_command_token_by_unit_id")
	var before: Dictionary = {}
	for index in range(units.size()):
		var unit: Node2D = units[index]
		var id := String(unit.call("get_unit_id"))
		var command := _command(unit)
		_check(String(command.get("command_type", "")) == "hold_position" and String(command.get("command_token", "")).is_empty(), "Fresh unit holds through SimulationRoot without a Move token: " + id)
		_check(committed.has(id) and String(committed[id]).is_empty(), "Authoritative empty-token commit is explicit: " + id)
		before[id] = unit.global_position
		_enqueue_move(simulation, unit, Vector2(320.0 if index == 0 else -320.0, 0.0), "fresh_move_%d" % index)
	await create_timer(0.35).timeout
	var all_moving := true
	for unit in units:
		var id := String(unit.call("get_unit_id"))
		var moving := String(_command(unit).get("command_type", "")) == "move_to_position"
		all_moving = all_moving and moving
		_check(moving, "Fresh tokenized Move replaces an initial untokenized hold: " + id)
		_check(unit.global_position.distance_to(Vector2(before[id])) > 2.0, "Fresh unit physically moves after its initial untokenized hold: " + id)
	_check(int(simulation.call("get_discarded_move_command_count", "stale_command_token")) == 0, "Fresh moves are not discarded as stale")
	if all_moving:
		# Normal movement has already requeued itself for the next physics tick.
		# Commit an untokenized Hold through the same owner, then observe the old
		# queued movement being rejected rather than resurrecting the old order.
		var discarded_before := int(simulation.call("get_discarded_move_command_count", "stale_command_token"))
		for unit in units:
			_enqueue_hold(simulation, unit)
		await _settle_physics()
		var hold_positions: Dictionary = {}
		for unit in units:
			hold_positions[String(unit.call("get_unit_id"))] = unit.global_position
		await create_timer(0.20).timeout
		for unit in units:
			var id := String(unit.call("get_unit_id"))
			_check(String(_command(unit).get("command_type", "")) == "hold_position", "Old queued Move cannot replace the later authoritative Hold: " + id)
			_check(unit.global_position.distance_to(Vector2(hold_positions[id])) < 0.01, "Old queued Move cannot resume physical movement after Hold: " + id)
		_check(int(simulation.call("get_discarded_move_command_count", "stale_command_token")) >= discarded_before + units.size(), "Each pre-Hold movement requeue is discarded as stale")
	host.queue_free()
	await process_frame
	await process_frame
	print("PLAYTEST_EMPTY_TOKEN_COMMIT_DONE %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _settle_physics() -> void:
	await physics_frame
	await physics_frame
	await process_frame


func _enqueue_hold(simulation: Node, unit: Node2D) -> void:
	simulation.call("enqueue_command", {"command_type": "hold_position", "priority": 11, "unit_id": unit.call("get_unit_id"), "team_id": "team_alpha", "target_position": unit.global_position, "move_speed_factor": 0.0, "source_task_type": "auto_defend", "requeue_until_target": false})


func _enqueue_move(simulation: Node, unit: Node2D, target: Vector2, token: String) -> void:
	simulation.call("enqueue_command", {"command_type": "move_to_position", "priority": 12, "unit_id": unit.call("get_unit_id"), "team_id": "team_alpha", "target_position": target, "move_speed_factor": 1.0, "command_token": token, "requeue_until_target": true})


func _command(unit: Node) -> Dictionary:
	var command: Variant = unit.call("get_current_unit_command")
	return Dictionary(command.call("to_dict")) if command is Object and command.has_method("to_dict") else {}


func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
	print("PASS: " if condition else "FAIL: ", label)
