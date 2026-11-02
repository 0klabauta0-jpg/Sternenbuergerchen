extends SceneTree

const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Review 2026-11-02 P1 incapacitated movement ===")
	_test_downed_move_stops_and_new_order_works_after_respawn()
	_test_bleedout_rejects_continuations_and_new_engage_orders()
	_test_same_tick_damage_and_respawn_cannot_revive_old_move()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_downed_move_stops_and_new_order_works_after_respawn() -> void:
	var context: Dictionary = _make_context("downed_move")
	var simulation: Node = context["simulation"]
	var unit: Node2D = context["unit"]
	var assigned: Array = []
	unit.unit_command_assigned.connect(func(command): assigned.append(String(command.command_token)))
	simulation.enqueue_command(_move_command(unit.unit_id, "running_move"))
	simulation._physics_process(0.1)
	_assert(unit.position.x > 0.0 and simulation.command_queue.size() == 1, "Fit unit starts a real tokenized move with a continuation")
	simulation.enqueue_effect(_lethal_damage(unit.unit_id))
	simulation._physics_process(0.1)
	_assert(unit.get_vital_state() == "down", "Authoritative lethal damage downs the moving unit")
	var downed_position: Vector2 = unit.position
	var assignments_at_down: int = assigned.size()
	simulation._physics_process(0.1)
	_assert(unit.position == downed_position, "Downed unit does not move on the next command tick")
	_assert(simulation.command_queue.is_empty(), "Downed unit's pending move is discarded without requeue")
	_assert(assigned.size() == assignments_at_down, "Rejected downed continuation does not recommit runtime command status")
	for tick in range(4):
		simulation._physics_process(0.1)
	_assert(unit.position == downed_position and simulation.command_queue.is_empty(), "Downed unit stays still across further ticks")

	var spawn_position := Vector2(0.0, 64.0)
	simulation.enqueue_effect({"effect_type": "respawn", "unit_id": unit.unit_id, "spawn_position": spawn_position})
	simulation._physics_process(0.1)
	for tick in range(3):
		simulation._physics_process(0.1)
	_assert(unit.get_vital_state() == "fit" and unit.position == spawn_position, "Respawn restores a fit unit without restarting its old move")
	_assert(unit.get_current_unit_command() == null and simulation.command_queue.is_empty(), "Respawn has no old pending or committed move")
	var target := spawn_position + Vector2(32.0, 0.0)
	simulation.enqueue_command(_move_command(unit.unit_id, "after_respawn", "move_to_position", target))
	simulation._physics_process(0.1)
	_assert(unit.position.x > spawn_position.x and _command_token(unit) == "after_respawn", "New valid tokenized movement is accepted after respawn")
	for tick in range(30):
		simulation._physics_process(0.1)
	_assert(unit.position.is_equal_approx(target) and simulation.command_queue.is_empty(), "New post-respawn move reaches its target and drains")
	context["scene"].free()


func _test_bleedout_rejects_continuations_and_new_engage_orders() -> void:
	var context: Dictionary = _make_context("bleedout_engage")
	var simulation: Node = context["simulation"]
	var unit: Node2D = context["unit"]
	var assigned: Array = []
	unit.unit_command_assigned.connect(func(command): assigned.append(String(command.command_token)))
	simulation.enqueue_command(_move_command(unit.unit_id, "running_engage", "engage_area"))
	simulation._physics_process(0.1)
	_assert(unit.position.x > 0.0 and simulation.command_queue.size() == 1, "Fit unit starts a real engage-area movement")
	simulation.enqueue_effect(_lethal_damage(unit.unit_id))
	simulation.enqueue_effect({"effect_type": "bleedout", "unit_id": unit.unit_id, "priority": 10})
	simulation._physics_process(0.1)
	_assert(unit.get_vital_state() == "bleedout", "Authoritative damage then bleedout reaches the terminal pre-respawn vital state")
	var stopped_position: Vector2 = unit.position
	var assignments_at_bleedout: int = assigned.size()
	simulation._physics_process(0.1)
	_assert(unit.position == stopped_position and simulation.command_queue.is_empty(), "Bleedout discards an existing engage continuation without movement")
	simulation.enqueue_command(_move_command(unit.unit_id, "late_engage", "engage_area", Vector2(0.0, 1000.0)))
	simulation._physics_process(0.1)
	_assert(unit.position == stopped_position and simulation.command_queue.is_empty(), "Bleedout also rejects a newly queued explicit-speed engage command")
	_assert(assigned.size() == assignments_at_bleedout, "Bleedout rejection never commits a new command or target")
	context["scene"].free()


func _test_same_tick_damage_and_respawn_cannot_revive_old_move() -> void:
	var context: Dictionary = _make_context("immediate_respawn")
	var simulation: Node = context["simulation"]
	var unit: Node2D = context["unit"]
	simulation.enqueue_command(_move_command(unit.unit_id, "before_fast_respawn"))
	simulation._physics_process(0.1)
	_assert(unit.position.x > 0.0 and simulation.command_queue.size() == 1, "Immediate-respawn fixture has a running move")
	var spawn_position := Vector2(0.0, 96.0)
	simulation.enqueue_effect(_lethal_damage(unit.unit_id))
	simulation.enqueue_effect({"effect_type": "respawn", "unit_id": unit.unit_id, "spawn_position": spawn_position, "priority": 10})
	simulation._physics_process(0.1)
	_assert(unit.get_vital_state() == "fit" and unit.position == spawn_position, "Damage and respawn effects preserve their authoritative same-tick order")
	_assert(simulation.command_queue.is_empty(), "Same-tick respawn cannot retain a pre-incapacitation continuation")
	for tick in range(3):
		simulation._physics_process(0.1)
	_assert(unit.position == spawn_position and unit.get_current_unit_command() == null, "Old token does not recommit movement after immediate respawn")
	simulation.enqueue_command(_move_command(unit.unit_id, "after_fast_respawn", "move_to_position", spawn_position + Vector2(32.0, 0.0)))
	simulation._physics_process(0.1)
	_assert(unit.position.x > spawn_position.x and _command_token(unit) == "after_fast_respawn", "Immediate respawn accepts a newly issued move token")
	context["scene"].free()


func _make_context(unit_id: String) -> Dictionary:
	var scene := Node.new()
	root.add_child(scene)
	var registry = UNIT_REGISTRY_SCRIPT.new()
	registry.name = "Units"
	scene.add_child(registry)
	var simulation = SIMULATION_ROOT_SCRIPT.new()
	simulation.unit_registry_path = NodePath("../Units")
	simulation.unit_minimum_spacing_enabled = false
	scene.add_child(simulation)
	simulation.set_physics_process(false)
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.team_id = "team_alpha"
	unit.fireteam_id = "blue"
	scene.add_child(unit)
	registry.register_unit(unit_id, unit)
	return {"scene": scene, "simulation": simulation, "unit": unit}


func _move_command(unit_id: String, token: String, command_type: String = "move_to_position", target: Vector2 = Vector2(1000.0, 0.0)) -> Dictionary:
	return {
		"command_type": command_type,
		"unit_id": unit_id,
		"team_id": "team_alpha",
		"target_position": target,
		"move_speed_factor": 1.0,
		"requeue_until_target": true,
		"command_token": token,
	}


func _lethal_damage(unit_id: String) -> Dictionary:
	return {"effect_type": "damage", "unit_id": unit_id, "damage": 10000, "roll_override": 0.0, "priority": 20}


func _command_token(unit: Node) -> String:
	var command = unit.get_current_unit_command()
	return "" if command == null else String(command.command_token)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		print("FAIL: %s" % message)
