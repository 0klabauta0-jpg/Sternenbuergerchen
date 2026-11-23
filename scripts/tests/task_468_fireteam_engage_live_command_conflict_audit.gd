extends SceneTree

const DRILL_SCENE: PackedScene = preload("res://scenes/tests/fireteam_command_drill_map.tscn")
const FIRETEAM_ORDER_PLAN_SCRIPT: GDScript = preload("res://scripts/command/fireteam_order_plan.gd")
const FIRETEAM_WAYPOINT_SCRIPT: GDScript = preload("res://scripts/command/fireteam_waypoint.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")

const FIRETEAM_ID: String = "drill"
const TASK_PATH: String = "res://docs/tasks/TASK_468_fireteam_engage_live_command_conflict_audit.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_468 Fireteam Engage Live Command Conflict Audit ===")
	await _test_contact_halt_rejects_stale_stage_requeue()
	await _test_live_engage_drill_can_emit_fire_event()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_contact_halt_rejects_stale_stage_requeue() -> void:
	var scene: Node = await _make_ready_scene()
	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_loop: Node = scene.get_node_or_null("CombatLoopDriver")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and combat_loop != null and simulation_root != null, "Drill scene exposes live controller, combat loop and simulation")
	if controller == null or combat_loop == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	_assert(String(combat_loop.get("win_condition")) == "elimination", "Drill map does not end combat via objective capture during behavior tests")
	controller.call("_set_selected_fireteams", PackedStringArray([FIRETEAM_ID]), false)
	controller.call("set_fireteams_tactical_stance", PackedStringArray([FIRETEAM_ID]), "aggressive")
	var enemies: Array = Array(controller.call("_get_all_enemy_units", true))
	var friendlies: Array = Array(controller.call("_get_fireteam_units", FIRETEAM_ID, true))
	_assert(enemies.size() >= 1 and friendlies.size() >= 4, "Drill exposes enemy contact and four friendly members")
	if enemies.is_empty() or friendlies.is_empty():
		scene.queue_free()
		await _wait_frames(2)
		return

	var enemy := enemies[0] as Node2D
	var attacker := friendlies[0] as Node2D
	_assert(enemy != null and attacker != null, "Attacker and target are Node2D units")
	if enemy == null or attacker == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	enemy.global_position = Vector2(1260.0, 720.0)
	_prepare_fireteam_for_fast_contact(controller, FIRETEAM_ID, enemy.global_position + Vector2(-128.0, 0.0), Vector2.RIGHT)
	var plan = _make_plan(FIRETEAM_ID, 1, FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_ENGAGE, enemy.global_position + Vector2(260.0, 0.0))
	var plan_key: String = String(controller.call("_build_order_plan_key", FIRETEAM_ID, 1))
	controller.set("_order_plans_by_key", {plan_key: plan})
	_assert(bool(controller.call("_activate_next_waypoint_for_plan", plan, FIRETEAM_ID, 0)), "Engage starts as live waypoint execution")

	# Activation enqueues commands; SimulationRoot owns their later physics commit.
	var stale_stage_command: Dictionary = _find_queued_stage_command(simulation_root, String(attacker.call("get_unit_id")))
	_assert(not stale_stage_command.is_empty(), "Initial Engage enqueues a tokenized stage command for authoritative processing")
	if stale_stage_command.is_empty():
		scene.queue_free()
		await _wait_frames(2)
		return
	stale_stage_command["requeue_until_target"] = true
	var stage_token: String = String(stale_stage_command.get("command_token", "")).strip_edges()
	_assert(not stage_token.is_empty() and not stage_token.contains("contact_halt"), "Stage command has a normal movement token")

	var movement_controller = controller.get("_fireteam_movement_controller")
	_assert(movement_controller != null, "Movement controller is active after Engage")
	if movement_controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var contact_context: Dictionary = _make_attackable_contact_context(attacker, enemy)
	var halt_result: Dictionary = Dictionary(movement_controller.call(
		"update_execution",
		FIRETEAM_ID,
		friendlies,
		controller.call("_resolve_fireteam_leader_for_behavior", FIRETEAM_ID),
		simulation_root,
		controller.call("_get_terrain_registry"),
		contact_context
	))
	_assert(bool(halt_result.get("contact_halt", false)), "Contact context forces Engage contact halt")
	await _wait_physics_process_pairs(2)
	var halt_command = attacker.call("get_current_unit_command")
	_assert(halt_command != null, "SimulationRoot commits the queued contact halt on a physics tick")
	if halt_command == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	var halt_token: String = String(halt_command.get("command_token")) if halt_command != null and halt_command.has_method("get") else ""
	_assert(String(halt_command.get("command_type")) == UNIT_COMMAND_SCRIPT.TYPE_HOLD_POSITION, "Contact halt switches attacker to hold")
	_assert(halt_token.contains("contact_halt") and halt_token != stage_token, "Contact halt uses a distinct token from the old movement stage")

	simulation_root.call("enqueue_command", stale_stage_command)
	await _wait_physics_process_pairs(2)
	var after_command = attacker.call("get_current_unit_command")
	_assert(String(after_command.get("command_type")) == UNIT_COMMAND_SCRIPT.TYPE_HOLD_POSITION, "Stale requeued Engage move does not override contact halt")
	_assert(String(after_command.get("source_command_type")) == FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_ENGAGE, "Contact halt remains sourced from Engage")
	_assert(String(after_command.get("fire_status")) == UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL, "Contact halt keeps fire-at-will")

	scene.queue_free()
	await _wait_frames(2)


func _find_queued_stage_command(simulation_root: Node, unit_id: String) -> Dictionary:
	var commands: Array = Array(simulation_root.get("command_queue"))
	for index in range(commands.size() - 1, -1, -1):
		var command: Dictionary = Dictionary(commands[index])
		var token: String = String(command.get("command_token", "")).strip_edges()
		if String(command.get("unit_id", "")) == unit_id and String(command.get("source_command_type", "")) == FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_ENGAGE and not token.is_empty() and not token.contains("contact_halt"):
			return command.duplicate(true)
	return {}


func _test_live_engage_drill_can_emit_fire_event() -> void:
	var scene: Node = await _make_ready_scene()
	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_loop: Node = scene.get_node_or_null("CombatLoopDriver")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and combat_loop != null and simulation_root != null, "Live fire verifier has controller, combat loop and simulation")
	if controller == null or combat_loop == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	if simulation_root.has_method("set_combat_rng_seed"):
		simulation_root.call("set_combat_rng_seed", 468)
	combat_loop.call("align_to_common_decision_step_for_test")
	controller.call("_set_selected_fireteams", PackedStringArray([FIRETEAM_ID]), false)
	controller.call("set_fireteams_tactical_stance", PackedStringArray([FIRETEAM_ID]), "aggressive")
	var enemies: Array = Array(controller.call("_get_all_enemy_units", true))
	var friendlies: Array = Array(controller.call("_get_fireteam_units", FIRETEAM_ID, true))
	_assert(enemies.size() >= 1 and friendlies.size() >= 4, "Live fire verifier has enemy and four friendlies")
	if enemies.is_empty() or friendlies.is_empty():
		scene.queue_free()
		await _wait_frames(2)
		return

	var enemy := enemies[0] as Node2D
	enemy.global_position = Vector2(1260.0, 720.0)
	_prepare_fireteam_for_fast_contact(controller, FIRETEAM_ID, enemy.global_position + Vector2(-120.0, 0.0), Vector2.RIGHT)
	var plan = _make_plan(FIRETEAM_ID, 1, FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_ENGAGE, enemy.global_position + Vector2(220.0, 0.0))
	var plan_key: String = String(controller.call("_build_order_plan_key", FIRETEAM_ID, 1))
	controller.set("_order_plans_by_key", {plan_key: plan})
	_assert(bool(controller.call("_activate_next_waypoint_for_plan", plan, FIRETEAM_ID, 0)), "Live Engage starts toward target beyond enemy")

	var fired: bool = false
	var last_diagnostics: Dictionary = {}
	for _i in range(160):
		await _wait_physics_process_pairs(1)
		last_diagnostics = Dictionary(combat_loop.call("get_contact_decision_diagnostics_snapshot")).duplicate(true)
		if String(last_diagnostics.get("reason", "")) == "fired" or not Array(combat_loop.call("get_fire_event_snapshot")).is_empty():
			fired = true
			break
	_assert(not bool(combat_loop.call("is_combat_finished")) or fired, "Drill combat stays active long enough for fire resolution")
	if not fired:
		print("TASK_468 live fire diagnostics: %s" % JSON.stringify(last_diagnostics))
	_assert(fired, "Live Engage path emits a fire event without manually forcing _try_enqueue_attacks")

	scene.queue_free()
	await _wait_frames(2)


func _prepare_fireteam_for_fast_contact(controller: Node, fireteam_id: String, center: Vector2, forward: Vector2) -> void:
	_place_fireteam(controller, fireteam_id, center, forward)
	for unit in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		if unit == null:
			continue
		unit.set("awareness", 1.0)
		unit.set("accuracy", 1.0)
		unit.set("recognition", 1.0)
		if unit.has_method("set_tactical_stance_indicator"):
			unit.call("set_tactical_stance_indicator", "aggressive", 1)


func _make_attackable_contact_context(attacker: Node2D, target: Node2D) -> Dictionary:
	var attacker_id: String = String(attacker.call("get_unit_id")) if attacker.has_method("get_unit_id") else ""
	var target_id: String = String(target.call("get_unit_id")) if target.has_method("get_unit_id") else ""
	var distance_world: float = attacker.global_position.distance_to(target.global_position)
	return {
		"should_halt": true,
		"reason": "attackable_contact",
		"fireteam_id": FIRETEAM_ID,
		"target_unit_id": target_id,
		"attacker_unit_id": attacker_id,
		"contact_state": "confirmed",
		"target_position": target.global_position,
		"readout": {
			"target_unit_id": target_id,
			"attacker_unit_id": attacker_id,
			"contact_state": "confirmed",
			"range_state": "in_range",
			"los_state": "clear",
			"distance_world": distance_world,
			"weapon_range_world": 1800.0,
			"attack_quality_label": "open",
			"combat_attackable": true,
		},
	}


func _make_ready_scene():
	root.size = Vector2i(1920, 1080)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(90)
	var setup := scene.get_node_or_null("MissionSetup")
	if setup != null and setup.has_method("set_fog_of_war_mode"):
		setup.call("set_fog_of_war_mode", "off")
	await _wait_frames(8)
	return scene


func _make_plan(fireteam_id: String, phase: int, command_type: String, target_position: Vector2):
	var plan = FIRETEAM_ORDER_PLAN_SCRIPT.new()
	plan.plan_id = "task468_%s_p%d_%s" % [fireteam_id, phase, command_type]
	plan.fireteam_id = fireteam_id
	plan.phase = phase
	plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_PENDING
	plan.active_waypoint_index = -1
	var waypoint = FIRETEAM_WAYPOINT_SCRIPT.new()
	waypoint.waypoint_id = "wp_0"
	waypoint.command_type = command_type
	waypoint.status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_PENDING
	waypoint.target_position = target_position
	plan.waypoints.append(waypoint)
	return plan


func _place_fireteam(controller: Node, fireteam_id: String, center: Vector2, forward: Vector2) -> void:
	var units: Array = Array(controller.call("_get_fireteam_units", fireteam_id, true))
	units.sort_custom(func(a, b) -> bool:
		return String(a.call("get_unit_id")) < String(b.call("get_unit_id"))
	)
	var safe_forward: Vector2 = forward.normalized() if forward.length_squared() > 0.001 else Vector2.RIGHT
	var lateral: Vector2 = safe_forward.orthogonal()
	var offsets: Array[Vector2] = [
		Vector2.ZERO,
		lateral * 52.0,
		-safe_forward * 64.0,
		-safe_forward * 64.0 + lateral * 52.0,
	]
	for index in range(mini(units.size(), offsets.size())):
		var unit = units[index]
		if unit is Node2D:
			(unit as Node2D).global_position = center + offsets[index]


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("TASK_468 - Fireteam Engage Live Command Conflict Audit"), "TASK_468 task file exists")
	_assert(status_text.contains("TASK_468 - Fireteam Engage Live Command Conflict Audit"), "Implementation status documents TASK_468")
	_assert(roadmap_text.contains("TASK_468 - Fireteam Engage Live Command Conflict Audit"), "Roadmap lists TASK_468")


func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame


func _wait_physics_process_pairs(count: int) -> void:
	for _i in range(count):
		await physics_frame
		await process_frame


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
		print("  PASS: %s" % message)
		return
	_failed += 1
	push_error("  FAIL: %s" % message)
