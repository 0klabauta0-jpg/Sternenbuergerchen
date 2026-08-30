extends SceneTree

const AREA_ORDER_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/area_order_resolver.gd")
const AREA_ORDER_SCRIPT: GDScript = preload("res://scripts/command/area_order.gd")
const COMBAT_FIRE_DECISION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/combat_fire_decision_resolver.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


class LosAlways:
	extends RefCounted

	func has_line_of_sight_between_nodes(_attacker, _target, _range: float, _terrain_registry = null) -> bool:
		return true


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_123 Attack Area Semantik Verifier ===")
	_test_resolver_builds_edge_approach()
	_test_resolver_skips_unreachable_occupation_tiles()
	_test_fire_resolver_prioritizes_target_area_contacts()
	await _test_mission_engage_area_enters_uncleared_area()
	await _test_mission_attack_area_execution_and_secured_state()
	await _test_single_waypoint_orders_still_work()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit(1 if _failed > 0 else 0)
func _test_resolver_builds_edge_approach() -> void:
	var units: Array = [
		_make_unit("blue_lead", "team_alpha", "blue", true, Vector2(-220.0, 96.0)),
		_make_unit("blue_a", "team_alpha", "blue", false, Vector2(-250.0, 112.0)),
		_make_unit("blue_b", "team_alpha", "blue", false, Vector2(-260.0, 80.0)),
	]
	var area_order = _make_area_order("area_attack_test", "blue", "take", Vector2(96.0, 96.0))
	var flank_area_order = _make_area_order("area_flank_test", "blue", "flank", Vector2(96.0, 96.0))
	var resolution: Dictionary = AREA_ORDER_RESOLVER_SCRIPT.call("resolve_attack_area", area_order, units, units[0], null)
	var flank_resolution: Dictionary = AREA_ORDER_RESOLVER_SCRIPT.call("resolve_attack_area", flank_area_order, units, units[0], null)
	var approach_position: Vector2 = Vector2(resolution.get("approach_position", Vector2.ZERO))
	var center_position: Vector2 = Vector2(resolution.get("center_position", Vector2.ZERO))
	var assignments: Array = Array(resolution.get("assignments", []))
	var occupy_resolution: Dictionary = AREA_ORDER_RESOLVER_SCRIPT.call("resolve_occupy_area", area_order, units, units[0], null)
	var occupy_assignments: Array = Array(occupy_resolution.get("assignments", []))
	var target_area: Dictionary = Dictionary(resolution.get("target_area", {}))
	_assert(not resolution.is_empty(), "Attack Area resolver accepts offensive Area Orders")
	_assert(not flank_resolution.is_empty(), "Attack Area resolver accepts offensive Flank Area Orders")
	_assert(approach_position.distance_to(center_position) > 48.0, "Attack Area approach is outside the target center")
	_assert(approach_position.distance_to((units[0] as Node2D).global_position) < center_position.distance_to((units[0] as Node2D).global_position), "Attack Area approach is formed on the friendly side of the area")
	_assert(assignments.size() == 3 and _count_unique_targets(assignments) == 3, "Attack Area spreads the fireteam on the approach line")
	_assert(occupy_assignments.size() == 3 and _all_assignments_inside_area(occupy_assignments, target_area), "Attack Area can derive occupation positions inside the target area")
	_cleanup_units(units)


func _test_resolver_skips_unreachable_occupation_tiles() -> void:
	var registry = _make_registry([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1)], {Vector2i(1, 0): false})
	var unit := _make_unit("blue_lead", "team_alpha", "blue", true, registry.grid_to_world(Vector2i(0, 0)))
	var unreachable_position: Vector2 = registry.grid_to_world(Vector2i(2, 0))
	var reachable_position: Vector2 = registry.grid_to_world(Vector2i(0, 1))
	var area_order = AREA_ORDER_SCRIPT.new({
		"area_order_id": "area_reachable_test",
		"fireteam_id": "blue",
		"command_type": "take",
		"tile_positions": [Vector2i(2, 0), Vector2i(0, 1)],
		"tile_world_positions": [unreachable_position, reachable_position],
		"world_polygon": PackedVector2Array([unreachable_position + Vector2(-32.0, -16.0), unreachable_position + Vector2(32.0, -16.0), reachable_position + Vector2(32.0, 16.0), reachable_position + Vector2(-32.0, 16.0)]),
		"center_position": unreachable_position,
		"created_at_order_index": 0,
		"status": "pending",
	})
	var resolution: Dictionary = AREA_ORDER_RESOLVER_SCRIPT.call("resolve_occupy_area", area_order, [unit], unit, registry)
	var assignments: Array = Array(resolution.get("assignments", []))
	var target_position: Vector2 = Vector2(Dictionary(assignments[0]).get("target_position", Vector2.ZERO)) if not assignments.is_empty() else Vector2.ZERO
	_assert(not assignments.is_empty() and target_position.distance_to(reachable_position) <= 0.5, "Area occupation skips unreachable marked tiles")
	unit.free()
	registry.free()


func _test_fire_resolver_prioritizes_target_area_contacts() -> void:
	var attacker := _make_unit("area_attacker", "team_alpha", "blue", true, Vector2.ZERO)
	var outside_target := _make_unit("outside_target", "team_bravo", "red", false, Vector2(32.0, 0.0))
	var inside_target := _make_unit("inside_target", "team_bravo", "red", false, Vector2(96.0, 96.0))
	attacker.call("set_runtime_status", "engaging", "engage_area")
	var context: Dictionary = _build_fire_context("blue", _make_area_order("priority_area", "blue", "engage", Vector2(96.0, 96.0)))
	var picked = COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("pick_target_from_units", attacker, [outside_target, inside_target], context)
	_assert(picked == inside_target, "Fire resolver prioritizes attack-area contacts over outside contacts")
	_cleanup_units([attacker, outside_target, inside_target])


func _test_mission_attack_area_execution_and_secured_state() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	var area_refs: Array = controller.call("create_area_order_for_selected_fireteams_from_world_rect", Vector2(900.0, 900.0), Vector2(1080.0, 1040.0), "take")
	_assert(area_refs.size() == 1, "Mission creates a Take Area Order")
	var visualized_area_orders: Array = controller.call("get_visualized_area_orders_snapshot")
	var area_visual: Dictionary = Dictionary(visualized_area_orders[0]) if not visualized_area_orders.is_empty() else {}
	_assert(typeof(area_visual.get("anchor_position", null)) == TYPE_VECTOR2, "Area Orders expose a route anchor for the visual path line")
	var started: bool = bool(controller.call("execute_selected_fireteam_orders"))
	_assert(started, "GO starts attack-area execution")
	var active_snapshot: Array = controller.call("get_active_area_attack_snapshot")
	_assert(active_snapshot.size() == 1, "Mission tracks active attack-area execution")
	var state: Dictionary = Dictionary(active_snapshot[0])
	var center_position: Vector2 = Vector2(state.get("center_position", Vector2.ZERO))
	var approach_position: Vector2 = Vector2(state.get("approach_position", center_position))
	_assert(approach_position.distance_to(center_position) > 48.0, "Attack Area execution exposes an approach point instead of a center rush")
	var attack_context: Dictionary = Dictionary(controller.call("get_fireteam_attack_area_context", "blue"))
	_assert(String(attack_context.get("area_order_id", "")) == String(state.get("area_order_id", "")), "Combat context is tied to the active attack Area Order")
	for assignment_variant in Array(state.get("assignments", [])):
		var assignment: Dictionary = Dictionary(assignment_variant)
		var unit = _find_unit(controller.call("_get_fireteam_units", "blue", true), String(assignment.get("unit_id", "")))
		if unit is Node2D:
			(unit as Node2D).global_position = Vector2(assignment.get("target_position", (unit as Node2D).global_position))
	controller.call("_update_area_attack_execution", 0.25)
	controller.call("refresh_fireteam_security_state")
	await process_frame
	var occupying_snapshot: Array = controller.call("get_active_area_attack_snapshot")
	var occupying_state: Dictionary = Dictionary(occupying_snapshot[0]) if not occupying_snapshot.is_empty() else {}
	_assert(String(occupying_state.get("status", "")) == "occupying", "Cleared Attack Area sends the fireteam into the marked area")
	var occupying_assignments: Array = Array(occupying_state.get("assignments", []))
	var occupying_target_area: Dictionary = Dictionary(occupying_state.get("target_area", {}))
	_assert(not occupying_assignments.is_empty() and _all_assignments_inside_area(occupying_assignments, occupying_target_area), "Attack Area occupation targets are inside the marked area")
	for assignment_variant in occupying_assignments:
		var assignment: Dictionary = Dictionary(assignment_variant)
		var unit = _find_unit(controller.call("_get_fireteam_units", "blue", true), String(assignment.get("unit_id", "")))
		if unit is Node2D:
			(unit as Node2D).global_position = Vector2(assignment.get("target_position", (unit as Node2D).global_position))
	controller.call("_update_area_attack_execution", 0.25)
	controller.call("refresh_fireteam_security_state")
	await process_frame
	var secured_snapshot: Array = controller.call("get_active_area_attack_snapshot")
	var secured_state: Dictionary = Dictionary(secured_snapshot[0]) if not secured_snapshot.is_empty() else {}
	_assert(String(secured_state.get("status", "")) == "secured", "Cleared Attack Area enters secured state")
	_assert(bool(secured_state.get("waiting_for_go", false)), "Secured Attack Area waits for GO before release")
	var waypoint_text: String = String(controller.call("_build_fireteam_waypoint_info_text", "blue"))
	_assert(waypoint_text.contains("AREA TAKE") and waypoint_text.contains("GESICHERT"), "#17 exposes Attack-Area state and target area")
	var security_state: Dictionary = Dictionary(controller.call("get_fireteam_security_state", "blue"))
	_assert(bool(security_state.get("is_active", false)) and String(security_state.get("area_order_id", "")) == String(state.get("area_order_id", "")), "Secured Attack Area switches into area security")
	var waypoint_refs: Array = controller.call("_create_waypoints_for_selected_fireteams", Vector2(360.0, 300.0))
	var moved_after_area: bool = bool(controller.call("execute_selected_fireteam_orders"))
	_assert(waypoint_refs.size() == 1 and moved_after_area, "GO after a secured Attack Area releases it and starts the next Move order")
	_assert(Array(controller.call("get_active_area_attack_snapshot")).is_empty() and _has_active_waypoint(controller.call("get_order_plans_snapshot"), "blue"), "Move order is active after Attack Area release")
	scene.queue_free()
	await process_frame


func _test_mission_engage_area_enters_uncleared_area() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	var enemy := scene.get_node_or_null("EnemyDelta") as Node2D
	if enemy != null:
		enemy.global_position = Vector2(980.0, 960.0)
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	var area_refs: Array = controller.call("create_area_order_for_selected_fireteams_from_world_rect", Vector2(900.0, 900.0), Vector2(1080.0, 1040.0), "engage")
	_assert(area_refs.size() == 1, "Mission creates an Engage Area Order")
	var started: bool = bool(controller.call("execute_selected_fireteam_orders"))
	_assert(started, "GO starts engage-area execution")
	var active_snapshot: Array = controller.call("get_active_area_attack_snapshot")
	var state: Dictionary = Dictionary(active_snapshot[0]) if not active_snapshot.is_empty() else {}
	for assignment_variant in Array(state.get("assignments", [])):
		var assignment: Dictionary = Dictionary(assignment_variant)
		var unit = _find_unit(controller.call("_get_fireteam_units", "blue", true), String(assignment.get("unit_id", "")))
		if unit is Node2D:
			(unit as Node2D).global_position = Vector2(assignment.get("target_position", (unit as Node2D).global_position))
	controller.call("_update_area_attack_execution", 0.25)
	await process_frame
	var engaging_snapshot: Array = controller.call("get_active_area_attack_snapshot")
	var engaging_state: Dictionary = Dictionary(engaging_snapshot[0]) if not engaging_snapshot.is_empty() else {}
	var target_area: Dictionary = Dictionary(engaging_state.get("target_area", {}))
	var assignments: Array = Array(engaging_state.get("assignments", []))
	_assert(String(engaging_state.get("status", "")) == "engaging", "Uncleared Engage Area switches from approach into engaging")
	_assert(not assignments.is_empty() and _all_assignments_inside_area(assignments, target_area), "Uncleared Engage Area sends all members into the marked area")
	scene.queue_free()
	await process_frame


func _test_single_waypoint_orders_still_work() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	var waypoint_refs: Array = controller.call("_create_waypoints_for_selected_fireteams", Vector2(320.0, 260.0))
	var started: bool = bool(controller.call("execute_selected_fireteam_orders"))
	_assert(waypoint_refs.size() == 1, "Existing single waypoint creation remains available")
	_assert(started and Array(controller.call("get_active_area_attack_snapshot")).is_empty(), "GO still starts regular waypoint execution when waypoints exist")
	scene.queue_free()
	await process_frame


func _make_area_order(area_order_id: String, fireteam_id: String, command_type: String, center_position: Vector2):
	return AREA_ORDER_SCRIPT.new({
		"area_order_id": area_order_id,
		"fireteam_id": fireteam_id,
		"command_type": command_type,
		"tile_positions": [Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, 2)],
		"tile_world_positions": [center_position + Vector2(-32.0, -24.0), center_position + Vector2(-32.0, 24.0), center_position + Vector2(32.0, -24.0), center_position + Vector2(32.0, 24.0)],
		"world_polygon": PackedVector2Array([center_position + Vector2(-64.0, -48.0), center_position + Vector2(64.0, -48.0), center_position + Vector2(64.0, 48.0), center_position + Vector2(-64.0, 48.0)]),
		"center_position": center_position,
		"created_at_order_index": 0,
		"status": "pending",
	})


func _build_fire_context(fireteam_id: String, area_order) -> Dictionary:
	var context_unit := _make_unit("context_unit", "team_alpha", fireteam_id, true, Vector2.ZERO)
	var resolution: Dictionary = AREA_ORDER_RESOLVER_SCRIPT.call("resolve_attack_area", area_order, [context_unit], context_unit, null)
	var target_area: Dictionary = Dictionary(resolution.get("target_area", {})).duplicate(true)
	context_unit.free()
	return {
		"friendly_team_id": "team_alpha",
		"contact_range": 9999.0,
		"los_system": LosAlways.new(),
		"terrain_registry": null,
		"get_effective_range": func(_target): return 9999.0,
		"attack_area_by_fireteam": {
			fireteam_id: target_area,
		},
	}


func _make_unit(unit_id: String, team_id: String, fireteam_id: String, is_lead: bool, position_value: Vector2) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.display_name = unit_id
	unit.team_id = team_id
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


func _make_registry(grid_positions: Array, blocked_by_grid: Dictionary):
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for grid_variant in grid_positions:
		var grid_position: Vector2i = Vector2i(grid_variant)
		var walkable: bool = bool(blocked_by_grid.get(grid_position, true))
		registry.register_tile(TERRAIN_TILE_DATA_SCRIPT.new({
			"tile_id": "%d_%d" % [grid_position.x, grid_position.y],
			"type_id": "ground_flat" if walkable else "rock_large",
			"grid_position": grid_position,
			"world_position": registry.grid_to_world(grid_position),
			"walkable": walkable,
			"surface_type": "ground" if walkable else "rock",
		}))
	return registry


func _load_scene() -> Node:
	var scene = load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
	root.add_child(scene)
	for _index in range(10):
		await process_frame
	return scene


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


func _all_assignments_inside_area(assignments: Array, area_context: Dictionary) -> bool:
	if assignments.is_empty() or area_context.is_empty():
		return false
	for assignment_variant in assignments:
		var assignment: Dictionary = Dictionary(assignment_variant)
		var target_position: Vector2 = Vector2(assignment.get("target_position", Vector2.ZERO))
		if not bool(AREA_ORDER_RESOLVER_SCRIPT.call("is_position_in_area_context", area_context, target_position)):
			return false
	return true


func _has_active_waypoint(plan_dicts: Array, fireteam_id: String) -> bool:
	for plan_variant in plan_dicts:
		var plan: Dictionary = Dictionary(plan_variant)
		if String(plan.get("fireteam_id", "")).strip_edges().to_lower() != fireteam_id:
			continue
		for waypoint_variant in Array(plan.get("waypoints", [])):
			var waypoint: Dictionary = Dictionary(waypoint_variant)
			if String(waypoint.get("status", "")) == "active":
				return true
	return false


func _cleanup_units(units: Array) -> void:
	for unit in units:
		if unit != null:
			unit.free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
