extends SceneTree

const AREA_ORDER_SCRIPT: GDScript = preload("res://scripts/command/area_order.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_121-125 Area Orders / Walkability Verifier ===")
	await _test_area_order_marker_roundtrip_and_visuals()
	await _test_defend_area_distribution_and_panel_feedback()
	await _test_attack_area_approach_and_target_priority()
	await _test_walkability_debug_and_blocker_path()
	_test_isometric_catalog_and_64_map()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_area_order_marker_roundtrip_and_visuals() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	var terrain_registry = scene.get_node("TerrainRegistry")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	var start_position: Vector2 = terrain_registry.call("grid_to_world", Vector2i(6, 6))
	var end_position: Vector2 = terrain_registry.call("grid_to_world", Vector2i(8, 8))
	var refs: Array = controller.call("_create_area_orders_for_selected_fireteams", AREA_ORDER_SCRIPT.COMMAND_TYPE_DEFEND, start_position, end_position)
	var area_orders: Array = controller.call("get_area_orders_snapshot")
	var visualized: Array = controller.call("get_visualized_area_orders_snapshot")
	_assert(refs.size() == 1, "TASK_121 creates one defend area order for the selected fireteam")
	_assert(area_orders.size() == 1 and int(Dictionary(area_orders[0]).get("tile_count", 0)) > 1, "TASK_121 stores multiple grid tiles in the area order")
	_assert(visualized.size() == 1 and int(Dictionary(visualized[0]).get("tile_count", 0)) > 1, "TASK_121 visualizer exposes the area order snapshot")

	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state")).duplicate(true)
	controller.call("_load_area_orders_from_state", [])
	controller.call("set_planning_state", planning_state)
	var reloaded_orders: Array = controller.call("get_area_orders_snapshot")
	_assert(reloaded_orders.size() == 1 and String(Dictionary(reloaded_orders[0]).get("command_type", "")) == AREA_ORDER_SCRIPT.COMMAND_TYPE_DEFEND, "TASK_121 planning-state roundtrip preserves area orders")
	scene.queue_free()
	await process_frame


func _test_defend_area_distribution_and_panel_feedback() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	var terrain_registry = scene.get_node("TerrainRegistry")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("_create_area_orders_for_selected_fireteams", AREA_ORDER_SCRIPT.COMMAND_TYPE_DEFEND, terrain_registry.call("grid_to_world", Vector2i(7, 7)), terrain_registry.call("grid_to_world", Vector2i(9, 9)))
	var started: bool = bool(controller.call("execute_selected_fireteam_orders"))
	var execution_snapshot: Array = controller.call("get_area_execution_snapshot")
	_assert(started and execution_snapshot.size() == 1, "TASK_122 GO starts defend-area execution")
	var execution: Dictionary = Dictionary(execution_snapshot[0])
	var assignments: Array = Array(execution.get("assignments", []))
	_assert(assignments.size() >= 2, "TASK_122 creates per-member defend assignments")
	_assert(_count_unique_assignment_targets(assignments) >= 2, "TASK_122 spreads members across different target positions")

	for assignment_variant in assignments:
		var assignment: Dictionary = Dictionary(assignment_variant)
		var unit = _find_unit(scene, String(assignment.get("unit_id", "")))
		if unit is Node2D:
			(unit as Node2D).global_position = Vector2(assignment.get("target_position", (unit as Node2D).global_position))
	controller.call("_update_area_order_execution", 0.1)
	controller.call("refresh_fireteam_security_state")
	var next_snapshot: Array = controller.call("get_area_execution_snapshot")
	var next_state: Dictionary = Dictionary(next_snapshot[0])
	var info_text: String = String(controller.call("_build_selected_waypoint_info_text"))
	var security_snapshot: Array = controller.call("get_fireteam_security_snapshot")
	_assert(bool(next_state.get("waiting_for_go", false)), "TASK_122 defend area waits for GO after the assignments are reached")
	_assert(info_text.contains("VERTEIDIGEN") and info_text.contains("Gebiet"), "TASK_124 #17 shows defend-area type and size")
	_assert(not security_snapshot.is_empty() and bool(Dictionary(security_snapshot[0]).get("is_active", false)), "TASK_122 defend area activates a security snapshot")
	scene.queue_free()
	await process_frame


func _test_attack_area_approach_and_target_priority() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	var terrain_registry = scene.get_node("TerrainRegistry")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	var center_position: Vector2 = terrain_registry.call("grid_to_world", Vector2i(15, 8))
	controller.call("_create_area_orders_for_selected_fireteams", AREA_ORDER_SCRIPT.COMMAND_TYPE_ENGAGE, terrain_registry.call("grid_to_world", Vector2i(14, 7)), terrain_registry.call("grid_to_world", Vector2i(16, 9)))
	var started: bool = bool(controller.call("execute_selected_fireteam_orders"))
	var execution_snapshot: Array = controller.call("get_area_execution_snapshot")
	var execution: Dictionary = Dictionary(execution_snapshot[0])
	var approach_position: Vector2 = Vector2(execution.get("approach_position", center_position))
	var area_center: Vector2 = Vector2(execution.get("center_position", center_position))
	_assert(started and execution_snapshot.size() == 1, "TASK_123 GO starts attack-area execution")
	_assert(approach_position.distance_to(area_center) > 20.0, "TASK_123 attack area uses an approach point instead of the area center")
	var info_text: String = String(controller.call("_build_selected_waypoint_info_text"))
	_assert(info_text.contains("ANGRIFF") and info_text.contains("Approach"), "TASK_124 #17 shows attack-area approach feedback")

	var attacker = _find_unit(scene, "unit_alpha")
	var inside_target = _find_unit(scene, "enemy_delta")
	var outside_target = _find_unit(scene, "enemy_echo")
	if inside_target is Node2D:
		(inside_target as Node2D).global_position = area_center
	if outside_target is Node2D:
		(outside_target as Node2D).global_position = area_center + Vector2(420.0, 0.0)
	var inside_score: float = float(controller.call("score_attack_area_target", attacker, inside_target))
	var outside_score: float = float(controller.call("score_attack_area_target", attacker, outside_target))
	_assert(inside_score > outside_score, "TASK_123 target priority favors enemies inside the active attack area")

	var leader = controller.call("_resolve_fireteam_leader_for_behavior", "blue")
	if leader is Node2D:
		(leader as Node2D).global_position = approach_position
	controller.call("_update_area_order_execution", 0.1)
	var secured_state: Dictionary = Dictionary(Array(controller.call("get_area_execution_snapshot"))[0])
	_assert(bool(secured_state.get("waiting_for_go", false)) and String(secured_state.get("mode", "")) == "security_hold", "TASK_123 attack area switches into security hold after approach")
	scene.queue_free()
	await process_frame


func _test_walkability_debug_and_blocker_path() -> void:
	var scene = await _load_scene()
	var terrain_registry = scene.get_node("TerrainRegistry")
	var simulation_root = scene.get_node("SimulationRoot")
	var rock_tile = _find_first_blocker_tile(terrain_registry)
	_assert(rock_tile != null, "TASK_125 test map exposes at least one blocker tile")
	if rock_tile == null:
		scene.queue_free()
		await process_frame
		return
	var rock_position: Vector2 = Vector2(rock_tile.world_position)
	var report_a: Dictionary = Dictionary(terrain_registry.call("build_walkability_debug_report", rock_position))
	var report_b: Dictionary = Dictionary(terrain_registry.call("build_walkability_debug_report", rock_position))
	_assert(not bool(report_a.get("original_walkable", true)) and String(report_a.get("reason", "")).begins_with("blocked_by_"), "TASK_125 debug report identifies the blocked original tile")
	_assert(report_a.get("replacement_grid", null) == report_b.get("replacement_grid", null), "TASK_125 replacement walkable tile is deterministic")
	var replacement_grid: Variant = report_a.get("replacement_grid", null)
	_assert(typeof(replacement_grid) == TYPE_VECTOR2I and bool(terrain_registry.call("is_walkable", replacement_grid)), "TASK_125 replacement grid is walkable")

	var start_grid: Vector2i = replacement_grid + Vector2i(-2, 0)
	if not bool(terrain_registry.call("is_walkable", start_grid)):
		start_grid = replacement_grid
	var path_points: Array = simulation_root.call("_build_path_world_points", terrain_registry.call("grid_to_world", start_grid), rock_position, terrain_registry)
	var crosses_blocker: bool = false
	for point_variant in path_points:
		if terrain_registry.call("world_to_grid", Vector2(point_variant)) == Vector2i(rock_tile.grid_position):
			crosses_blocker = true
	_assert(not path_points.is_empty(), "TASK_125 path builder returns a path toward a blocked target replacement")
	_assert(not crosses_blocker, "TASK_125 path builder does not include the blocked rock grid as a waypoint")
	scene.queue_free()
	await process_frame


func _test_isometric_catalog_and_64_map() -> void:
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	_assert(catalog.call("has_type", "city_pavement_light"), "Isometric city assets are available in the editor tile catalog")
	_assert(catalog.call("get_texture", "city_pavement_light") != null, "Isometric city catalog entry resolves its texture")
	_assert(catalog.call("has_type", "landscape_grass"), "Isometric landscape assets are available in the editor tile catalog")
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", "res://maps/area_orders_64x64_isometric.json")
	_assert(map_data != null and Vector2i(map_data.call("get_grid_size")) == Vector2i(64, 64), "Additional 64x64 isometric map loads with the requested grid size")
	_assert(_map_uses_type(map_data, "city_pavement_light") and _map_uses_type(map_data, "landscape_water_edge"), "Additional map uses the newly cataloged city and landscape assets")


func _load_scene() -> Node:
	var scene = load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
	root.add_child(scene)
	for _index in range(10):
		await process_frame
	return scene


func _find_unit(scene: Node, unit_id: String):
	for child in scene.get_children():
		if child != null and child.has_method("get_unit_id") and String(child.call("get_unit_id")) == unit_id:
			return child
	return null


func _find_first_blocker_tile(terrain_registry):
	for tile_data in Array(terrain_registry.call("get_all_tiles")):
		if tile_data != null and not bool(tile_data.walkable):
			return tile_data
	return null


func _count_unique_assignment_targets(assignments: Array) -> int:
	var unique_targets: Dictionary = {}
	for assignment_variant in assignments:
		var assignment: Dictionary = Dictionary(assignment_variant)
		var target: Vector2 = Vector2(assignment.get("target_position", Vector2.ZERO))
		unique_targets["%d:%d" % [roundi(target.x), roundi(target.y)]] = true
	return unique_targets.size()


func _map_uses_type(map_data, type_id: String) -> bool:
	if map_data == null:
		return false
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data != null and String(tile_data.type_id) == type_id:
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
