extends SceneTree

const DRILL_SCENE: PackedScene = preload("res://scenes/tests/fireteam_command_drill_map.tscn")
const FIRETEAM_ORDER_PLAN_SCRIPT: GDScript = preload("res://scripts/command/fireteam_order_plan.gd")
const FIRETEAM_WAYPOINT_SCRIPT: GDScript = preload("res://scripts/command/fireteam_waypoint.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_467_fireteam_engage_contact_halt_fire.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/fireteam_behavior_modes_contract.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_467 Fireteam Engage Contact Halt Fire ===")
	await _test_engage_halts_on_attackable_contact_and_can_fire()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_engage_halts_on_attackable_contact_and_can_fire() -> void:
	var scene: Node = await _make_ready_scene()
	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_loop: Node = scene.get_node_or_null("CombatLoopDriver")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and combat_loop != null and simulation_root != null, "Drill scene exposes controller, combat loop and simulation")
	if controller == null or combat_loop == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	controller.call("_set_selected_fireteams", PackedStringArray(["drill"]), false)
	controller.call("set_fireteams_tactical_stance", PackedStringArray(["drill"]), "aggressive")
	var enemies: Array = Array(controller.call("_get_all_enemy_units", true))
	var friendlies: Array = Array(controller.call("_get_fireteam_units", "drill", true))
	_assert(enemies.size() >= 1 and friendlies.size() >= 4, "Drill has active enemy and four friendly members")
	if enemies.is_empty() or friendlies.is_empty():
		scene.queue_free()
		await _wait_frames(2)
		return

	var enemy := enemies[0] as Node2D
	_assert(enemy != null, "Enemy is a Node2D for LOS/range contact")
	if enemy == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	enemy.global_position = Vector2(1280.0, 720.0)
	_prepare_fireteam_for_fast_contact(controller, "drill", enemy.global_position + Vector2(-112.0, 0.0), Vector2.RIGHT)
	if simulation_root.has_method("set_combat_rng_seed"):
		simulation_root.call("set_combat_rng_seed", 467)
	combat_loop.set("_next_attack_tick", 0)

	var target_position: Vector2 = enemy.global_position + Vector2(240.0, 0.0)
	var plan = _make_plan("drill", 1, FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_ENGAGE, target_position)
	var plan_key: String = String(controller.call("_build_order_plan_key", "drill", 1))
	controller.set("_order_plans_by_key", {plan_key: plan})
	_assert(bool(controller.call("_activate_next_waypoint_for_plan", plan, "drill", 0)), "Aggressive Engage starts toward a target beyond the enemy")

	combat_loop.call("_update_contact_tracking")
	controller.call("_update_active_phase_execution", 0.25)
	await _wait_physics_frames(3)
	controller.call("_update_active_phase_execution", 0.25)

	var movement_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", "drill"))
	var halt_context: Dictionary = Dictionary(movement_state.get("contact_halt_context", {})).duplicate(true)
	_assert(bool(movement_state.get("contact_halt_active", false)), "Engage movement reports contact halt instead of continuing through enemy")
	_assert(String(halt_context.get("target_unit_id", "")) == String(enemy.call("get_unit_id")), "Contact halt points at the spotted enemy")
	_assert(_all_members_hold_engage_fire_at_will(controller, "drill"), "Contact halt issues hold/engage/fire-at-will/Aim commands to all members")
	_assert(_phase_execution_is_still_active(controller, "drill"), "Contact halt keeps the waypoint active and blocks immediate Auto DEF completion")

	var attacker_id: String = String(halt_context.get("attacker_unit_id", ""))
	var target_id: String = String(halt_context.get("target_unit_id", ""))
	if not attacker_id.is_empty() and not target_id.is_empty():
		combat_loop.set("_detection_progress", {"%s:%s" % [attacker_id, target_id]: 0})
	combat_loop.set("_next_attack_tick", 0)
	combat_loop.call("_try_enqueue_attacks", simulation_root)
	var diagnostics: Dictionary = Dictionary(combat_loop.call("get_contact_decision_diagnostics_snapshot"))
	var fire_events: Array = Array(combat_loop.call("get_fire_event_snapshot"))
	_assert(String(diagnostics.get("reason", "")) == "fired", "Halted Engage can produce a fired diagnostic")
	_assert(not fire_events.is_empty(), "Halted Engage records a fire event for muzzle/trace visuals")

	scene.queue_free()
	await _wait_frames(2)


func _prepare_fireteam_for_fast_contact(controller: Node, fireteam_id: String, center: Vector2, forward: Vector2) -> void:
	_place_fireteam(controller, fireteam_id, center, forward)
	for unit in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		if unit == null:
			continue
		if unit.has_method("set"):
			unit.set("awareness", 1.0)
			unit.set("accuracy", 1.0)
			unit.set("recognition", 1.0)
		if unit.has_method("set_tactical_stance_indicator"):
			unit.call("set_tactical_stance_indicator", "aggressive", 1)


func _all_members_hold_engage_fire_at_will(controller: Node, fireteam_id: String) -> bool:
	for unit in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		if unit == null or not unit.has_method("get_current_unit_command"):
			return false
		var command = unit.call("get_current_unit_command")
		if command == null or not command.has_method("get"):
			return false
		if String(command.get("command_type")) != UNIT_COMMAND_SCRIPT.TYPE_HOLD_POSITION:
			return false
		if String(command.get("source_command_type")).strip_edges().to_lower() != FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_ENGAGE:
			return false
		if String(command.get("fire_status")) != UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL:
			return false
		if String(command.get("weapon_posture")) != UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_AIMED:
			return false
	return true


func _phase_execution_is_still_active(controller: Node, fireteam_id: String) -> bool:
	var execution_by_fireteam: Dictionary = Dictionary(controller.get("_phase_execution_by_fireteam"))
	return execution_by_fireteam.has(fireteam_id.strip_edges().to_lower())


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
	plan.plan_id = "task467_%s_p%d_%s" % [fireteam_id, phase, command_type]
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
		lateral * 46.0,
		-safe_forward * 54.0,
		-safe_forward * 54.0 + lateral * 46.0,
	]
	for index in range(mini(units.size(), offsets.size())):
		var unit = units[index]
		if unit is Node2D:
			(unit as Node2D).global_position = center + offsets[index]


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(task_text.contains("TASK_467 - Fireteam Engage Contact Halt Fire"), "TASK_467 task file exists")
	_assert(status_text.contains("TASK_467 - Fireteam Engage Contact Halt Fire"), "Implementation status documents TASK_467")
	_assert(roadmap_text.contains("TASK_467 - Fireteam Engage Contact Halt Fire"), "Roadmap lists TASK_467")
	_assert(contract_text.contains("TASK_467 Engage-Kontakthalt"), "Behavior contract documents TASK_467")


func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _i in range(count):
		await physics_frame


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
