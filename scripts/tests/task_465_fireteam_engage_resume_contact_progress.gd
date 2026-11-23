extends SceneTree

const DRILL_SCENE: PackedScene = preload("res://scenes/tests/fireteam_command_drill_map.tscn")
const FIRETEAM_ORDER_PLAN_SCRIPT: GDScript = preload("res://scripts/command/fireteam_order_plan.gd")
const FIRETEAM_WAYPOINT_SCRIPT: GDScript = preload("res://scripts/command/fireteam_waypoint.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_465_fireteam_engage_resume_contact_progress.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/fireteam_behavior_modes_contract.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_465 Fireteam Engage Resume Contact Progress ===")
	await _test_engage_after_auto_defend_uses_directional_moving_security()
	await _test_engage_after_auto_defend_advances_next_bound()
	await _test_auto_defend_fires_on_close_contact()
	await _test_engage_after_auto_defend_fires_on_close_contact()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_engage_after_auto_defend_uses_directional_moving_security() -> void:
	var scene: Node = await _make_ready_scene()
	var controller: Node = scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Drill controller exists for moving security regression")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	controller.call("_set_selected_fireteams", PackedStringArray(["drill"]), false)
	_place_fireteam(controller, "drill", Vector2(760.0, 420.0), Vector2.RIGHT)
	_assert(bool(controller.call("_apply_default_fireteam_behavior", "drill", 1)), "Auto DEF 360 pre-state applies before new Engage")
	var target_position := Vector2(1320.0, 420.0)
	var plan = _make_plan("drill", 1, FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_ENGAGE, target_position)
	var plan_key: String = String(controller.call("_build_order_plan_key", "drill", 1))
	controller.set("_order_plans_by_key", {plan_key: plan})
	_assert(bool(controller.call("_activate_next_waypoint_for_plan", plan, "drill", 0)), "New Engage starts from Auto DEF pre-state")
	controller.call("refresh_fireteam_security_state")
	var movement_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", "drill"))
	var security_state: Dictionary = Dictionary(controller.call("get_fireteam_security_state", "drill"))
	_assert(String(movement_state.get("command_type", "")) == "engage", "Movement state remains Engage after issuing new command")
	_assert(not movement_state.is_empty(), "Engage keeps active movement state")
	_assert(String(security_state.get("command_type", "")) == "engage", "Security state follows new Engage command")
	_assert(String(security_state.get("security_mode", "")) != "360", "Moving Engage does not keep old DEF 360 security mode")
	_assert(bool(security_state.get("movement_security_active", false)), "Moving Engage marks security as movement-oriented")
	_assert(not bool(security_state.get("defense_ready", true)), "Moving Engage is not marked defense-ready while movement is active")
	scene.queue_free()
	await _wait_frames(2)


func _test_engage_after_auto_defend_advances_next_bound() -> void:
	var scene: Node = await _make_ready_scene()
	var controller: Node = scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Drill controller exists for bound progression regression")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	controller.call("_set_selected_fireteams", PackedStringArray(["drill"]), false)
	_place_fireteam(controller, "drill", Vector2(760.0, 520.0), Vector2.RIGHT)
	_assert(bool(controller.call("_apply_default_fireteam_behavior", "drill", 1)), "Auto DEF 360 pre-state applies before bound progression")
	var target_position := Vector2(1390.0, 520.0)
	var plan = _make_plan("drill", 1, FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_ENGAGE, target_position)
	var plan_key: String = String(controller.call("_build_order_plan_key", "drill", 1))
	controller.set("_order_plans_by_key", {plan_key: plan})
	_assert(bool(controller.call("_activate_next_waypoint_for_plan", plan, "drill", 0)), "New Engage starts bound progression")
	var before_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", "drill"))
	_assert(int(before_state.get("bound_count", 1)) >= 2, "Test Engage uses multiple bounds")
	_move_current_movers_to_targets(controller, "drill")
	controller.call("_update_active_phase_execution", 0.25)
	await _wait_frames(4)
	var after_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", "drill"))
	var units: Array = Array(controller.call("_get_fireteam_units", "drill", true))
	_assert(String(after_state.get("command_type", "")) == "engage", "Engage remains active after first moving pair reaches bound")
	_assert(int(after_state.get("stage_index", 0)) > int(before_state.get("stage_index", 0)), "Engage advances from the reached bound instead of hanging")
	_assert(not _all_units_hold_auto_defend(units), "Bound progression is not overwritten by Auto DEF")
	scene.queue_free()
	await _wait_frames(2)


func _test_auto_defend_fires_on_close_contact() -> void:
	var scene: Node = await _make_ready_scene()
	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_loop: Node = scene.get_node_or_null("CombatLoopDriver")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and combat_loop != null and simulation_root != null, "Drill scene exposes controller, combat loop and simulation for DEF fire regression")
	if controller == null or combat_loop == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	controller.call("_set_selected_fireteams", PackedStringArray(["drill"]), false)
	var friendlies: Array = Array(controller.call("_get_fireteam_units", "drill", true))
	var enemies: Array = Array(controller.call("_get_all_enemy_units", true))
	_assert(friendlies.size() >= 1 and enemies.size() >= 1, "DEF fire test has friendly and enemy units")
	if friendlies.is_empty() or enemies.is_empty():
		scene.queue_free()
		await _wait_frames(2)
		return
	var friendly := friendlies[0] as Node2D
	var enemy := enemies[0] as Node2D
	_assert(friendly != null and enemy != null, "DEF fire test has Node2D attacker and target")
	if friendly == null or enemy == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	enemy.global_position = Vector2(1280.0, 720.0)
	_place_fireteam(controller, "drill", enemy.global_position + Vector2(-64.0, 0.0), Vector2.RIGHT)
	_assert(bool(controller.call("_apply_default_fireteam_behavior", "drill", 1)), "Auto DEF 360 applies for close-contact fire test")
	friendly = Array(controller.call("_get_fireteam_units", "drill", true))[0] as Node2D
	friendly.global_position = enemy.global_position + Vector2(-56.0, 0.0)
	var friendly_id: String = String(friendly.call("get_unit_id"))
	var enemy_id: String = String(enemy.call("get_unit_id"))
	combat_loop.set("_detection_progress", {"%s:%s" % [friendly_id, enemy_id]: 0})
	combat_loop.set("_current_tick", 200)
	combat_loop.call("align_to_common_decision_step_for_test")
	combat_loop.call("_try_enqueue_attacks", simulation_root)
	var diagnostics: Dictionary = Dictionary(combat_loop.call("get_contact_decision_diagnostics_snapshot"))
	var fire_events: Array = Array(combat_loop.call("get_fire_event_snapshot"))
	_assert(String(diagnostics.get("reason", "")) == "fired", "Auto DEF 360 can fire when enemy is visible, in LOS and in range")
	_assert(not fire_events.is_empty(), "Auto DEF 360 records a fire event for muzzle/trace visuals")
	scene.queue_free()
	await _wait_frames(2)


func _test_engage_after_auto_defend_fires_on_close_contact() -> void:
	var scene: Node = await _make_ready_scene()
	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_loop: Node = scene.get_node_or_null("CombatLoopDriver")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and combat_loop != null and simulation_root != null, "Drill scene exposes controller, combat loop and simulation for fire regression")
	if controller == null or combat_loop == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	controller.call("_set_selected_fireteams", PackedStringArray(["drill"]), false)
	var friendlies: Array = Array(controller.call("_get_fireteam_units", "drill", true))
	var enemies: Array = Array(controller.call("_get_all_enemy_units", true))
	_assert(friendlies.size() >= 4 and enemies.size() >= 1, "Drill has friendlies and active enemies for close-contact fire")
	if friendlies.is_empty() or enemies.is_empty():
		scene.queue_free()
		await _wait_frames(2)
		return
	var enemy := enemies[0] as Node2D
	var attacker := friendlies[0] as Node2D
	_assert(enemy != null and attacker != null, "Close-contact fire has Node2D attacker and target")
	if enemy == null or attacker == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	enemy.global_position = Vector2(1280.0, 720.0)
	_place_fireteam(controller, "drill", enemy.global_position + Vector2(-72.0, 0.0), Vector2.RIGHT)
	_assert(bool(controller.call("_apply_default_fireteam_behavior", "drill", 1)), "Auto DEF 360 pre-state applies before close-contact Engage")
	var plan = _make_plan("drill", 1, FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_ENGAGE, enemy.global_position)
	var plan_key: String = String(controller.call("_build_order_plan_key", "drill", 1))
	controller.set("_order_plans_by_key", {plan_key: plan})
	_assert(bool(controller.call("_activate_next_waypoint_for_plan", plan, "drill", 0)), "New close-contact Engage starts from Auto DEF pre-state")
	attacker = Array(controller.call("_get_fireteam_units", "drill", true))[0] as Node2D
	attacker.global_position = enemy.global_position + Vector2(-56.0, 0.0)
	var attacker_id: String = String(attacker.call("get_unit_id"))
	var enemy_id: String = String(enemy.call("get_unit_id"))
	combat_loop.set("_detection_progress", {"%s:%s" % [attacker_id, enemy_id]: 0})
	combat_loop.set("_current_tick", 220)
	combat_loop.call("align_to_common_decision_step_for_test")
	combat_loop.call("_try_enqueue_attacks", simulation_root)
	var diagnostics: Dictionary = Dictionary(combat_loop.call("get_contact_decision_diagnostics_snapshot"))
	var fire_events: Array = Array(combat_loop.call("get_fire_event_snapshot"))
	_assert(String(diagnostics.get("reason", "")) == "fired", "Close-contact Engage after Auto DEF produces a fired diagnostic")
	_assert(not fire_events.is_empty(), "Close-contact Engage records a fire event for muzzle/trace visuals")
	scene.queue_free()
	await _wait_frames(2)


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(task_text.contains("TASK_465 - Fireteam Engage Resume Contact Progress"), "TASK_465 task file exists")
	_assert(status_text.contains("TASK_465 - Fireteam Engage Resume Contact Progress"), "Implementation status documents TASK_465")
	_assert(roadmap_text.contains("TASK_465 - Fireteam Engage Resume Contact Progress"), "Roadmap lists TASK_465")
	_assert(contract_text.contains("TASK_465 Engage-Resume/Kontaktfortschritt"), "Behavior contract documents TASK_465")


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
	plan.plan_id = "task465_%s_p%d_%s" % [fireteam_id, phase, command_type]
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
		-lateral * 42.0,
		lateral * 42.0,
		-safe_forward * 56.0 - lateral * 42.0,
		-safe_forward * 56.0 + lateral * 42.0,
	]
	for index in range(mini(units.size(), offsets.size())):
		var unit = units[index]
		if unit is Node2D:
			(unit as Node2D).global_position = center + offsets[index]


func _move_current_movers_to_targets(controller: Node, fireteam_id: String) -> void:
	var movement_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", fireteam_id))
	var targets: Dictionary = Dictionary(movement_state.get("current_target_positions", {}))
	var movers: PackedStringArray = PackedStringArray(movement_state.get("current_moving_unit_ids", PackedStringArray()))
	for unit in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		if not (unit is Node2D) or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id"))
		if not movers.has(unit_id) or not targets.has(unit_id):
			continue
		(unit as Node2D).global_position = Vector2(targets.get(unit_id))


func _all_units_hold_auto_defend(units: Array) -> bool:
	var checked_count: int = 0
	for unit in units:
		if unit == null or not unit.has_method("get_current_unit_command"):
			continue
		var command = unit.call("get_current_unit_command")
		if command == null:
			return false
		checked_count += 1
		if String(command.get("command_type")) != UNIT_COMMAND_SCRIPT.TYPE_HOLD_POSITION:
			return false
		if String(command.get("source_task_type")) != "auto_defend":
			return false
	return checked_count > 0


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _wait_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	push_error("  FAIL: %s" % message)
