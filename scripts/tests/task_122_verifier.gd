extends SceneTree

const AREA_ORDER_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/area_order_resolver.gd")
const AREA_ORDER_SCRIPT: GDScript = preload("res://scripts/command/area_order.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_122 Defend Area Semantik Verifier ===")
	_test_resolver_spreads_members_and_keeps_leader()
	await _test_mission_defend_area_execution_status_and_security()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_resolver_spreads_members_and_keeps_leader() -> void:
	var units: Array = [
		_make_unit("blue_lead", "blue", true, Vector2.ZERO),
		_make_unit("blue_a", "blue", false, Vector2(-16.0, 8.0)),
		_make_unit("blue_b", "blue", false, Vector2(16.0, 8.0)),
	]
	var area_order = AREA_ORDER_SCRIPT.new({
		"area_order_id": "area_test",
		"fireteam_id": "blue",
		"command_type": "defend",
		"tile_positions": [Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, 2)],
		"tile_world_positions": [Vector2(96.0, 64.0), Vector2(64.0, 96.0), Vector2(128.0, 96.0), Vector2(96.0, 128.0)],
		"world_polygon": PackedVector2Array([Vector2(48.0, 48.0), Vector2(144.0, 48.0), Vector2(144.0, 144.0), Vector2(48.0, 144.0)]),
		"center_position": Vector2(96.0, 96.0),
		"created_at_order_index": 0,
		"status": "pending",
	})
	var resolution: Dictionary = AREA_ORDER_RESOLVER_SCRIPT.call("resolve_defend_area", area_order, units, units[0], null)
	var assignments: Array = Array(resolution.get("assignments", []))
	_assert(assignments.size() == 3, "Resolver creates one defend-area assignment per fit member")
	_assert(_count_unique_targets(assignments) == 3, "Resolver avoids duplicate target positions when enough area tiles exist")
	var leader_assignment: Dictionary = _find_assignment(assignments, "blue_lead")
	_assert(not leader_assignment.is_empty(), "FTL remains part of the defend-area formation")
	_assert(Vector2(leader_assignment.get("target_position", Vector2.ZERO)).distance_to(Vector2(96.0, 96.0)) <= 48.0, "FTL is placed near the area center")
	_cleanup_units(units)


func _test_mission_defend_area_execution_status_and_security() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	var units: Array = controller.call("_get_fireteam_units", "blue", true)
	var leader = controller.call("get_current_fireteam_lead_unit", "blue")
	var leader_start_position: Vector2 = (leader as Node2D).global_position if leader is Node2D else Vector2.ZERO
	var area_refs: Array = controller.call("create_area_order_for_selected_fireteams_from_world_rect", Vector2(120.0, 120.0), Vector2(420.0, 300.0), "defend")
	_assert(area_refs.size() == 1, "Mission creates a defend Area Order for execution")
	var started: bool = bool(controller.call("execute_selected_fireteam_orders"))
	_assert(started, "GO starts defend-area execution")
	var active_snapshot: Array = controller.call("get_active_area_defense_snapshot")
	_assert(active_snapshot.size() == 1, "Mission tracks active defend-area execution")
	var state: Dictionary = Dictionary(active_snapshot[0])
	var assignments: Array = Array(state.get("assignments", []))
	_assert(assignments.size() >= 2, "Defend Area distributes at least 2 fireteam members")
	_assert(_count_unique_targets(assignments) >= mini(assignments.size(), 3), "Defend Area does not collapse the fireteam onto the center")
	var leader_assignment: Dictionary = _find_assignment(assignments, String(leader.call("get_unit_id")) if leader != null and leader.has_method("get_unit_id") else "")
	_assert(not leader_assignment.is_empty() and Vector2(leader_assignment.get("target_position", leader_start_position)).distance_to(leader_start_position) > 8.0, "FTL receives a real defend-area target")
	for assignment_variant in assignments:
		var assignment: Dictionary = Dictionary(assignment_variant)
		var unit = _find_unit(units, String(assignment.get("unit_id", "")))
		if unit is Node2D:
			(unit as Node2D).global_position = Vector2(assignment.get("target_position", (unit as Node2D).global_position))
	controller.call("_update_area_defense_execution", 0.25)
	controller.call("refresh_fireteam_security_state")
	await process_frame
	var updated_snapshot: Array = controller.call("get_active_area_defense_snapshot")
	var updated_state: Dictionary = Dictionary(updated_snapshot[0]) if not updated_snapshot.is_empty() else {}
	_assert(bool(updated_state.get("waiting_for_go", false)), "Defend Area enters waiting-for-GO after positions are reached")
	var waypoint_text: String = String(controller.call("_build_fireteam_waypoint_info_text", "blue"))
	_assert(waypoint_text.contains("HALTET GEBIET") and waypoint_text.contains("WARTET AUF GO"), "#17 exposes a clear defend-area hold status")
	var security_state: Dictionary = Dictionary(controller.call("get_fireteam_security_state", "blue"))
	_assert(bool(security_state.get("is_active", false)), "Defend Area activates fireteam security")
	_assert(String(security_state.get("area_order_id", "")) == String(state.get("area_order_id", "")), "Security snapshot is tied to the active Area Order")
	_assert(Vector2(security_state.get("anchor_position", Vector2.ZERO)).distance_to(Vector2(state.get("center_position", Vector2.ZERO))) <= 1.0, "Security anchor is area-centered")
	scene.queue_free()
	await process_frame


func _make_unit(unit_id: String, fireteam_id: String, is_lead: bool, position_value: Vector2) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.display_name = unit_id
	unit.team_id = "team_alpha"
	unit.fireteam_id = fireteam_id
	unit.is_fireteam_lead = is_lead
	unit.skill_accuracy = 0.7
	unit.skill_speed = 0.7
	unit.skill_leadership = 0.8 if is_lead else 0.3
	unit.skill_toughness = 0.65
	unit.discipline = 0.7
	unit.recognition = 0.7
	unit.global_position = position_value
	unit._ready()
	return unit


func _load_scene() -> Node:
	var scene = load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
	root.add_child(scene)
	for _index in range(10):
		await process_frame
	return scene


func _find_assignment(assignments: Array, unit_id: String) -> Dictionary:
	for assignment_variant in assignments:
		var assignment: Dictionary = Dictionary(assignment_variant)
		if String(assignment.get("unit_id", "")) == unit_id:
			return assignment
	return {}


func _find_unit(units: Array, unit_id: String):
	for unit in units:
		if unit != null and unit.has_method("get_unit_id") and String(unit.call("get_unit_id")) == unit_id:
			return unit
	return null


func _count_unique_targets(assignments: Array) -> int:
	var seen: Dictionary = {}
	for assignment_variant in assignments:
		var assignment: Dictionary = Dictionary(assignment_variant)
		var target_position: Vector2 = Vector2(assignment.get("target_position", Vector2.ZERO))
		seen["%d,%d" % [roundi(target_position.x), roundi(target_position.y)]] = true
	return seen.size()


func _cleanup_units(units: Array) -> void:
	for unit in units:
		if unit != null:
			unit.queue_free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
