extends SceneTree

const DRILL_SCENE: PackedScene = preload("res://scenes/tests/fireteam_command_drill_map.tscn")
const FIRETEAM_ORDER_PLAN_SCRIPT: GDScript = preload("res://scripts/command/fireteam_order_plan.gd")
const FIRETEAM_WAYPOINT_SCRIPT: GDScript = preload("res://scripts/command/fireteam_waypoint.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_463_fireteam_auto_defend_guard_enemy_model_visibility.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/fireteam_behavior_modes_contract.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_463 Fireteam Auto Defend Guard And Enemy Model Visibility ===")
	await _test_soft_completion_does_not_override_fresh_movement()
	await _test_default_def_360_faces_outward_without_repositioning()
	await _test_drill_enemies_have_readable_animated_models()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_soft_completion_does_not_override_fresh_movement() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(36)

	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Drill scene exposes controller for fresh movement guard")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	controller.call("_set_selected_fireteams", PackedStringArray(["drill"]), false)
	var leader = controller.call("_resolve_fireteam_leader_for_behavior", "drill")
	_assert(leader is Node2D, "Fresh movement guard has a leader")
	if not (leader is Node2D):
		scene.queue_free()
		await _wait_frames(2)
		return

	var target_position: Vector2 = (leader as Node2D).global_position + Vector2(180.0, -64.0)
	var plan = _make_plan("drill", 1, [target_position])
	var plan_key: String = String(controller.call("_build_order_plan_key", "drill", 1))
	controller.set("_order_plans_by_key", {plan_key: plan})
	_assert(bool(controller.call("_activate_next_waypoint_for_plan", plan, "drill", 0)), "Fresh Move waypoint starts movement")

	_move_units_near_current_targets(controller, "drill", 24.0)
	controller.call("_update_active_phase_execution", 0.25)

	var stored_plans: Dictionary = Dictionary(controller.get("_order_plans_by_key"))
	var phase_execution: Dictionary = Dictionary(controller.get("_phase_execution_by_fireteam"))
	var units: Array = Array(controller.call("_get_fireteam_units", "drill", true))
	_assert(stored_plans.has(plan_key), "Fresh movement is not removed by soft completion")
	_assert(phase_execution.has("drill"), "Fresh movement keeps active phase execution")
	_assert(not _all_units_hold_auto_defend(units), "Fresh movement is not overwritten by auto_defend")

	var state: Dictionary = Dictionary(phase_execution.get("drill", {})).duplicate(true)
	state["started_msec"] = Time.get_ticks_msec() - 3000
	phase_execution["drill"] = state
	controller.set("_phase_execution_by_fireteam", phase_execution)
	controller.call("_update_active_phase_execution", 0.25)
	await _wait_frames(4)

	stored_plans = Dictionary(controller.get("_order_plans_by_key"))
	phase_execution = Dictionary(controller.get("_phase_execution_by_fireteam"))
	units = Array(controller.call("_get_fireteam_units", "drill", true))
	_assert(not stored_plans.has(plan_key), "Aged soft-reached movement can still complete")
	_assert(not phase_execution.has("drill"), "Aged completion clears active execution")
	_assert(_all_units_hold_auto_defend(units), "Aged final waypoint enters auto_defend")
	scene.queue_free()
	await _wait_frames(2)


func _test_default_def_360_faces_outward_without_repositioning() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(36)

	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Drill scene exposes controller for DEF 360 facing")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	controller.call("_set_selected_fireteams", PackedStringArray(["drill"]), false)
	var units: Array = Array(controller.call("_get_fireteam_units", "drill", true))
	units.sort_custom(func(a, b) -> bool:
		return String(a.call("get_unit_id")) < String(b.call("get_unit_id"))
	)
	var center := Vector2(420.0, 180.0)
	var offsets: Array[Vector2] = [Vector2(-42.0, 0.0), Vector2(42.0, 0.0), Vector2(0.0, -42.0), Vector2(0.0, 42.0)]
	var before_positions: Dictionary = {}
	for index in range(mini(units.size(), offsets.size())):
		var unit = units[index]
		if unit is Node2D:
			(unit as Node2D).global_position = center + offsets[index]
			before_positions[String(unit.call("get_unit_id"))] = (unit as Node2D).global_position

	_assert(bool(controller.call("_apply_default_fireteam_behavior", "drill", 1)), "Default DEF 360 applies after completed order")
	await _wait_frames(4)
	_assert(_positions_match(units, before_positions), "Default DEF 360 holds current positions instead of crossing units")
	_assert(_facing_points_outward(units, center), "Default DEF 360 visible facing points outward from team center")
	scene.queue_free()
	await _wait_frames(2)


func _test_drill_enemies_have_readable_animated_models() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(90)

	var setup := scene.get_node_or_null("MissionSetup")
	var primary_view := scene.get_node_or_null("Primary3DView")
	_assert(setup != null and primary_view != null, "Drill scene exposes setup and primary view for enemy model audit")
	if setup == null or primary_view == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	if setup.has_method("set_fog_of_war_mode"):
		setup.call("set_fog_of_war_mode", "off")
	await _wait_frames(8)
	var presence: Dictionary = Dictionary(setup.call("get_expected_unit_presence_snapshot"))
	var enemy_ids: Array = Array(presence.get("enemy_unit_ids", []))
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var visible_ids: Array = Array(snapshot.get("visible_unit_proxy_ids", []))
	var state_by_id: Dictionary = Dictionary(snapshot.get("unit_proxy_state_by_id", {}))
	_assert(enemy_ids.size() == 4, "Drill scenario exposes four enemy IDs")
	_assert(_contains_all(visible_ids, enemy_ids), "All four enemy proxies are visible in the 3D view")
	_assert(_all_enemy_models_are_readable(state_by_id, enemy_ids), "All four enemy proxies use readable animated character models")
	scene.queue_free()
	await _wait_frames(2)


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(task_text.contains("TASK_463 - Fireteam Auto Defend Guard And Enemy Model Visibility"), "TASK_463 task file exists")
	_assert(status_text.contains("TASK_463 - Fireteam Auto Defend Guard And Enemy Model Visibility"), "Implementation status documents TASK_463")
	_assert(roadmap_text.contains("TASK_463 - Fireteam Auto Defend Guard And Enemy Model Visibility"), "Roadmap lists TASK_463")
	_assert(contract_text.contains("TASK_463 Auto-Defend Guard/Enemy-Modelle"), "Behavior contract documents TASK_463")


func _make_plan(fireteam_id: String, phase: int, targets: Array):
	var plan = FIRETEAM_ORDER_PLAN_SCRIPT.new()
	plan.plan_id = "task463_%s_p%d" % [fireteam_id, phase]
	plan.fireteam_id = fireteam_id
	plan.phase = phase
	plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_PENDING
	plan.active_waypoint_index = -1
	for index in range(targets.size()):
		var waypoint = FIRETEAM_WAYPOINT_SCRIPT.new()
		waypoint.waypoint_id = "wp_%d" % index
		waypoint.command_type = FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_MOVE
		waypoint.status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_PENDING
		waypoint.target_position = Vector2(targets[index])
		plan.waypoints.append(waypoint)
	return plan


func _move_units_near_current_targets(controller: Node, fireteam_id: String, offset: float) -> void:
	var movement_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", fireteam_id))
	var targets: Dictionary = Dictionary(movement_state.get("current_target_positions", {}))
	for unit in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		if not (unit is Node2D) or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id"))
		if not targets.has(unit_id):
			continue
		(unit as Node2D).global_position = Vector2(targets.get(unit_id)) + Vector2(offset, 0.0)


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


func _positions_match(units: Array, expected_positions: Dictionary) -> bool:
	for unit in units:
		if not (unit is Node2D) or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id"))
		if not expected_positions.has(unit_id):
			continue
		if (unit as Node2D).global_position.distance_to(Vector2(expected_positions.get(unit_id))) > 0.01:
			return false
	return true


func _facing_points_outward(units: Array, center: Vector2) -> bool:
	var checked_count: int = 0
	for unit in units:
		if not (unit is Node2D) or not (unit as Node).has_meta("map_facing_angle"):
			continue
		var outward: Vector2 = ((unit as Node2D).global_position - center).normalized()
		if outward.length_squared() <= 0.0001:
			continue
		var facing: Vector2 = Vector2.RIGHT.rotated(float((unit as Node).get_meta("map_facing_angle", 0.0))).normalized()
		checked_count += 1
		if facing.dot(outward) < 0.92:
			return false
	return checked_count >= 4


func _contains_all(values: Array, expected_values: Array) -> bool:
	for expected in expected_values:
		if not values.has(expected):
			return false
	return true


func _all_enemy_models_are_readable(state_by_id: Dictionary, enemy_ids: Array) -> bool:
	for enemy_id_variant in enemy_ids:
		var enemy_id: String = String(enemy_id_variant)
		var state: Dictionary = Dictionary(state_by_id.get(enemy_id, {}))
		if state.is_empty():
			return false
		if not bool(state.get("visible", false)):
			return false
		if not bool(state.get("uses_animated_character_model", false)):
			return false
		if String(state.get("unit_body_visual_kind", "")) != "animated_model":
			return false
		if float(state.get("unit_model_scale", 0.0)) < 0.26:
			return false
		if bool(state.get("missing_unit_model", false)) or bool(state.get("unit_visual_error", false)):
			return false
	return true


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
