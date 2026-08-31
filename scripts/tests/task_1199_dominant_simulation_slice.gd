extends SceneTree

const SIMULATION_SOURCE := "res://scripts/core/simulation_root.gd"
const SIMULATION_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
var _passed := 0
var _failed := 0
var _trace: Array = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var source := FileAccess.get_file_as_string(SIMULATION_SOURCE)
	var movement_start := source.find("func _apply_move_command")
	var movement_end := source.find("func _store_unit_facing_from_positions")
	var movement := source.substr(movement_start, movement_end - movement_start)
	var enqueue_start := source.find("func enqueue_command")
	var enqueue := source.substr(enqueue_start, source.find("func enqueue_effect") - enqueue_start)
	_assert(movement.count("enqueue_command(cmd)") == 3 and movement.count("enqueue_command(cmd.duplicate(true))") == 0, "oracle 0: movement requeues pass cmd directly")
	_assert(enqueue.count("var queued_command: Dictionary = cmd.duplicate(true)") == 1 and enqueue.contains("command_queue.append(queued_command)"), "oracle 0: enqueue copies once before storage")

	var scene := Node.new()
	root.add_child(scene)
	var registry = REGISTRY_SCRIPT.new()
	registry.name = "UnitRegistry"
	scene.add_child(registry)
	var simulation = SIMULATION_SCRIPT.new()
	simulation.unit_registry_path = NodePath("../UnitRegistry")
	scene.add_child(simulation)
	var unit = UNIT_SCRIPT.new()
	unit.unit_id = "task1199-unit"
	unit.team_id = "team_alpha"
	unit.position = Vector2.ZERO
	scene.add_child(unit)
	registry.register_unit(unit.unit_id, unit)
	var start: Vector2 = Vector2(unit.position)
	var target: Vector2 = start + Vector2(24, 0)
	var combat_speed_multiplier: float = float(unit.get_combat_speed_multiplier())
	var normalized_move_speed_factor: float = 1.0 / combat_speed_multiplier
	simulation.fire_rule_committed.connect(func(state): _trace.append(String(state.get("fire_rule", ""))))
	unit.unit_command_assigned.connect(func(command): _trace.append(String(command.get("command_type"))))
	simulation.enqueue_command({"command_type":"set_fire_rule", "fireteam_id":"blue", "team_id":"team_alpha", "fire_rule":"hold", "priority":20})
	simulation.enqueue_command({"command_type":"set_fire_rule", "fireteam_id":"blue", "team_id":"team_alpha", "fire_rule":"free", "priority":10})
	simulation.enqueue_command({"command_type":"move_to_position", "unit_id":unit.unit_id, "team_id":"team_alpha", "target_position":target, "move_speed_factor":normalized_move_speed_factor, "priority":0, "requeue_until_target":true, "command_id":"task1199-move", "command_token":"task1199-token"})
	var before: Dictionary = Dictionary(simulation.build_multiplayer_snapshot())
	simulation._physics_process(0.1)
	_assert(_trace == ["hold", "free", "move_to_position"], "oracle 1: mixed-priority order")
	_assert(unit.position == start + Vector2(8, 0), "oracle 2: tick 1 exact position")
	_assert(simulation.command_queue.size() == 1, "oracle 4: one continuation after tick 1")
	var queued: Dictionary = simulation.command_queue[0]
	_assert(String(queued.get("command_id", "")) == "task1199-move" and String(queued.get("command_token", "")) == "task1199-token" and queued.get("target_position", null) == target, "oracle 4: continuation identity and target")
	var status: Dictionary = Dictionary(unit.get_runtime_status().call("to_dict"))
	var current_command = unit.get_current_unit_command()
	if current_command != null and current_command.has_method("to_dict"):
		status.merge(Dictionary(current_command.call("to_dict")), true)
	_assert(String(status.get("status", "")) == "pending_move" and String(status.get("active_command_type", "")) == "move_to_position" and String(status.get("unit_id", "")) == unit.unit_id and status.get("target_position", null) == target, "oracle 3: exact movement status")
	var tick1: Dictionary = Dictionary(simulation.build_multiplayer_snapshot())
	simulation._physics_process(0.1)
	var tick2_queued: Dictionary = simulation.command_queue[0]
	_assert(unit.position == start + Vector2(16, 0) and simulation.command_queue.size() == 1 and String(tick2_queued.get("command_token", "")) == "task1199-token" and String(tick2_queued.get("command_id", "")) == "task1199-move" and tick2_queued.get("target_position") == target, "oracle 2/4: tick 2 and exact requeue")
	simulation._physics_process(0.1)
	_assert(unit.position == target and simulation.command_queue.size() == 1, "oracle 2/4: tick 3 reaches target with the existing final continuation")
	var reached: Dictionary = Dictionary(simulation.build_multiplayer_snapshot())
	simulation._physics_process(0.1)
	_assert(unit.position == target and simulation.command_queue.is_empty(), "oracle 2/4: tick 4 drains the final continuation without movement")
	var arrival: Dictionary = Dictionary(simulation.build_multiplayer_snapshot())
	_assert(_has_state_snapshot_contract(before) and _has_state_snapshot_contract(tick1) and _has_state_snapshot_contract(reached) and _has_state_snapshot_contract(arrival) and int(before.get("tick", -1)) == 0 and int(tick1.get("tick", -1)) == 1 and int(reached.get("tick", -1)) == 3 and int(arrival.get("tick", -1)) == 4, "oracle 6: snapshots schema, transport and ticks")
	var before_unit := _find_snapshot_unit(before, unit.unit_id)
	var snap_unit := _find_snapshot_unit(tick1, unit.unit_id)
	var reached_unit := _find_snapshot_unit(reached, unit.unit_id)
	var arrival_unit := _find_snapshot_unit(arrival, unit.unit_id)
	_assert(String(before_unit.get("unit_id", "")) == unit.unit_id and String(before_unit.get("team_id", "")) == "team_alpha" and before_unit.get("position", null) == start and String(before_unit.get("runtime_state", "")) == "idle", "oracle 6: before snapshot unit state")
	_assert(String(snap_unit.get("unit_id", "")) == unit.unit_id and String(snap_unit.get("team_id", "")) == "team_alpha" and snap_unit.get("position", null) == start + Vector2(8, 0) and String(snap_unit.get("runtime_state", "")) == "pending_move" and String(snap_unit.get("active_command_type", "")) == "move_to_position", "oracle 6: tick 1 snapshot unit state")
	_assert(String(reached_unit.get("unit_id", "")) == unit.unit_id and reached_unit.get("position", null) == target and String(reached_unit.get("active_command_type", "")) == "move_to_position", "oracle 6: reached-target snapshot unit state")
	_assert(String(arrival_unit.get("unit_id", "")) == unit.unit_id and String(arrival_unit.get("team_id", "")) == "team_alpha" and arrival_unit.get("position", null) == target and String(arrival_unit.get("runtime_state", "")) == "pending_move" and String(arrival_unit.get("active_command_type", "")) == "move_to_position", "oracle 6: settled arrival snapshot unit state")
	var tactical := _find_tactical_rule(tick1)
	_assert(String(tactical.get("runtime_authority", "")) == "SimulationRoot" and bool(tactical.get("read_only", false)) and not bool(tactical.get("ui_sets_gameplay_truth", true)), "oracle 6: authoritative tactical rule")
	var isolated_scene := Node.new()
	root.add_child(isolated_scene)
	var isolated_registry = REGISTRY_SCRIPT.new()
	isolated_registry.name = "UnitRegistry"
	isolated_scene.add_child(isolated_registry)
	var isolated_simulation = SIMULATION_SCRIPT.new()
	isolated_simulation.unit_registry_path = NodePath("../UnitRegistry")
	isolated_scene.add_child(isolated_simulation)
	var isolated_unit = UNIT_SCRIPT.new()
	isolated_unit.unit_id = "task1199-isolated"
	isolated_scene.add_child(isolated_unit)
	isolated_registry.register_unit(isolated_unit.unit_id, isolated_unit)
	var nested_path: Array = [{"waypoint": Vector2(8, 0)}]
	var direct_cmd := {"command_type":"move_to_position", "unit_id":isolated_unit.unit_id, "target_position":Vector2(24, 0), "requeue_until_target":true, "command_id":"isolation", "command_token":"isolation-token", "path":nested_path}
	isolated_simulation.call("_apply_move_command", direct_cmd, 0.1)
	direct_cmd["target_position"] = Vector2(999, 999)
	nested_path[0]["waypoint"] = Vector2(999, 999)
	var isolated_queued: Dictionary = isolated_simulation.command_queue[0]
	_assert(isolated_queued.get("target_position") == Vector2(24, 0) and Dictionary(Array(isolated_queued.get("path"))[0]).get("waypoint") == Vector2(8, 0) and _payload_clean(isolated_queued), "oracle 5: direct requeue copy isolation and payload safety")
	isolated_scene.free()
	_assert(not unit.has_meta("ui_truth"), "oracle 7: UI is not gameplay truth")
	scene.free()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		print("FAIL: %s" % message)

func _find_snapshot_unit(snapshot: Dictionary, id: String) -> Dictionary:
	for entry in Array(snapshot.get("units", [])):
		if String(Dictionary(entry).get("unit_id", "")) == id:
			return Dictionary(entry)
	return {}

func _find_tactical_rule(snapshot: Dictionary) -> Dictionary:
	for entry in Array(snapshot.get("tactical_rules", [])):
		if String(Dictionary(entry).get("runtime_authority", "")) == "SimulationRoot":
			return Dictionary(entry)
	return {}


func _has_state_snapshot_contract(snapshot: Dictionary) -> bool:
	return (
		int(snapshot.get("schema_version", 0)) == 1
		and String(snapshot.get("snapshot_type", "")) == "state"
		and String(snapshot.get("transfer_mode", "")) == "unreliable"
	)


func _payload_clean(value: Variant) -> bool:
	if value is Object:
		return false
	if value is Dictionary:
		for key in value:
			if String(key).to_lower().contains("cache") or not _payload_clean(value[key]):
				return false
	elif value is Array:
		for item in value:
			if not _payload_clean(item):
				return false
	return true
