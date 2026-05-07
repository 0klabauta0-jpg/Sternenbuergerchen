extends SceneTree

const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_RENDERER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_renderer.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

const HEIGHT_STEP: float = 0.25

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_185 Hill Visuals and Edge Lines Verifier ===")
	await _test_3d_hill_edges_surfaces_and_anchors()
	_test_legacy_renderer_uses_same_height_edge_rule()
	await _test_missing_3d_mapping_stays_visible_on_hilltop()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_3d_hill_edges_surfaces_and_anchors() -> void:
	var map_data = _build_hill_fixture_map()
	var center_world: Vector2 = map_data.call("get_tile_at_grid", Vector2i(2, 2)).world_position
	var slope_world: Vector2 = map_data.call("get_tile_at_grid", Vector2i(1, 2)).world_position

	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	primary_view.call("set_selected_grid_positions", [Vector2i(2, 2)])
	primary_view.call("set_mission_drop_visual_state", {
		"has_lz_position": true,
		"lz_position": slope_world,
	})
	primary_view.call("set_order_visual_payload", {
		"phase_index": 1,
		"fireteam_anchors": [{"fireteam_id": "blue", "position": slope_world}],
		"plan_dicts": [{
			"fireteam_id": "blue",
			"phase": 1,
			"waypoints": [{"target_position": center_world, "command_type": "move"}],
		}],
		"area_order_dicts": [{
			"area_order_id": "hill_area",
			"command_type": "defend",
			"tile_world_positions": [center_world],
		}],
	})
	await _wait_frames(8)

	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(snapshot.get("ground_mesh_count", 0)) == 25, "3D fixture renders every tile as ground mesh")
	_assert(int(snapshot.get("height_edge_texture_count", 0)) == 0, "Strict 3D fixture does not use height-edge texture cards")
	_assert(int(snapshot.get("height_edge_model_count", 0)) > 0, "Strict 3D fixture renders height edges as 3D models")
	_assert(int(snapshot.get("slope_edge_model_count", 0)) > 0, "Strict 3D fixture renders slope edges separately")
	_assert(int(snapshot.get("cliff_edge_model_count", 0)) > 0, "Strict 3D fixture renders cliff edges separately")
	_assert(int(snapshot.get("elevated_surface_tint_count", 0)) >= 1, "Sand/Rock/Road surface tint remains visible on elevated tiles")
	_assert(int(snapshot.get("missing_map_asset_mapping_count", 0)) == 0, "Hill fixture resolves all mapped terrain assets")
	_assert(int(snapshot.get("lz_tile_marker_count", 0)) == 1, "LZ marker snaps to a terrain tile")
	_assert(int(snapshot.get("waypoint_tile_marker_count", 0)) == 1, "Waypoint marker snaps to a terrain tile")
	_assert(int(snapshot.get("area_order_tile_marker_count", 0)) == 1, "Area marker snaps to a terrain tile")
	_assert(int(snapshot.get("selected_grid_count", 0)) == 1, "Selection state is mirrored into 3D view")

	var slope_edge := _find_map_node(primary_view, "HeightEdge_1_2_-1_0_slope_nw") as Node3D
	var cliff_edge := _find_map_node(primary_view, "HeightEdge_3_2_1_0_cliff_straight_se") as Node3D
	var surface_tint := _find_map_node(primary_view, "SurfaceTint_sand_1_2") as Node3D
	var wall_node := _find_map_node(primary_view, "Asset_wall_straight_se_2_2") as Node3D
	var rock_node := _find_map_node(primary_view, "Asset_rock_large_2_1") as Node3D
	var selection_node := _find_scene_node(primary_view, "Selection_2_2") as Node3D
	var map_marker_node := _find_scene_node(primary_view, "Marker_hill_marker") as Node3D
	var lz_node := _find_scene_node(primary_view, "LZTile_1_2") as Node3D
	var waypoint_node := _find_scene_node(primary_view, "WaypointTile_2_2") as Node3D
	var area_node := _find_scene_node(primary_view, "AreaOrderTile_hill_area_2_2") as Node3D

	_assert(slope_edge != null and _node_has_mesh(slope_edge), "Slope edge uses a 3D slope model")
	_assert(cliff_edge != null and _node_has_mesh(cliff_edge), "Cliff edge uses a 3D cliff model")
	_assert(surface_tint != null and surface_tint.position.y > _top_y(2), "Sand surface tint sits on the elevated top surface")
	_assert(_edge_nodes_for_grid(primary_view, Vector2i(2, 2)).is_empty(), "Plateau interior with edge none has no false height edge models")
	_assert(wall_node != null and wall_node.position.y >= _top_y(2), "Wall on hill is anchored on the hilltop")
	_assert(rock_node != null and rock_node.position.y >= _top_y(2), "Rock on hill is anchored on the hilltop")
	_assert(selection_node != null and selection_node.position.y > _top_y(2), "Selection marker sits above the selected hill tile")
	_assert(map_marker_node != null and map_marker_node.position.y > _top_y(2), "Map marker sits above the hill tile")
	_assert(lz_node != null and lz_node.position.y > _top_y(2), "LZ tile marker sits above the slope hill tile")
	_assert(waypoint_node != null and waypoint_node.position.y > _top_y(2), "Waypoint tile marker sits above the target hill tile")
	_assert(area_node != null and area_node.position.y > _top_y(2), "Area-order tile marker sits above the hill tile")

	primary_view.queue_free()
	await _wait_frames(2)


func _test_legacy_renderer_uses_same_height_edge_rule() -> void:
	var map_data = _build_hill_fixture_map()
	var renderer = TERRAIN_MAP_RENDERER_SCRIPT.new()
	var map_root := Node2D.new()
	root.add_child(map_root)
	var render_result: Dictionary = Dictionary(renderer.call("render_map", map_data, map_root))
	var cliff_map: Dictionary = Dictionary(render_result.get("cliffs", {}))
	var wall_map: Dictionary = Dictionary(render_result.get("walls", {}))
	var object_map: Dictionary = Dictionary(render_result.get("objects", {}))
	_assert(cliff_map.has(Vector2i(1, 2)), "Legacy renderer draws slope edge where higher slope tile meets lower neighbor")
	_assert(cliff_map.has(Vector2i(3, 2)), "Legacy renderer draws cliff edge where higher cliff tile meets lower neighbor")
	_assert(not cliff_map.has(Vector2i(2, 2)), "Legacy renderer does not draw false edge on plateau interior")
	_assert(wall_map.has(Vector2i(2, 2)) or object_map.has(Vector2i(2, 2)), "Legacy renderer keeps wall object on hill tile")
	_assert(wall_map.has(Vector2i(2, 1)) or object_map.has(Vector2i(2, 1)), "Legacy renderer keeps rock object on hill tile")
	map_root.queue_free()


func _test_missing_3d_mapping_stays_visible_on_hilltop() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "missing_hill_visual", Vector2i(1, 1), Vector2.ZERO)
	var tile_data = map_data.call("get_tile_at_grid", Vector2i.ZERO)
	tile_data.height_level = 2
	tile_data.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF
	tile_data.object_type_id = "debug_missing_hill_model"
	tile_data.object_height = 1
	tile_data.blocks_los = true

	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	await _wait_frames(6)

	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var missing_marker := _find_map_node(primary_view, "MissingAsset_debug_missing_hill_model_0_0") as Node3D
	_assert(int(snapshot.get("missing_map_asset_mapping_count", 0)) == 1, "Missing hill object mapping remains counted")
	_assert(missing_marker != null and missing_marker.position.y > _top_y(2), "Missing asset marker is visible on the hilltop")
	_assert(int(snapshot.get("asset_texture_count", 0)) == 0 and int(snapshot.get("placeholder_object_count", 0)) == 0, "Strict mapping does not fall back to wrong texture or box object")

	primary_view.queue_free()
	await _wait_frames(2)


func _build_hill_fixture_map():
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_185_hill_visual_fixture", Vector2i(5, 5), Vector2(256.0, 128.0), 64.0, 32.0, 3)
	for x in range(1, 4):
		for y in range(1, 4):
			var tile_data = map_data.call("get_tile_at_grid", Vector2i(x, y))
			tile_data.height_level = 2
			tile_data.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF
	var center = map_data.call("get_tile_at_grid", Vector2i(2, 2))
	center.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
	center.object_type_id = "wall_straight_se"
	center.object_height = 2
	center.blocks_los = true
	center.walkable = false

	var sand_slope = map_data.call("get_tile_at_grid", Vector2i(1, 2))
	sand_slope.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE
	sand_slope.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND

	var rock_tile = map_data.call("get_tile_at_grid", Vector2i(2, 1))
	rock_tile.object_type_id = "rock_large"
	rock_tile.object_height = 1
	rock_tile.blocks_los = true
	rock_tile.walkable = false

	map_data.call("set_marker_position", "hill_marker", center.world_position)
	return map_data


func _edge_nodes_for_grid(primary_view: Node, grid_position: Vector2i) -> Array:
	var result: Array = []
	var map_root = primary_view.get_node_or_null("ViewportContainer/SubViewport/WorldRoot/MapRoot3D") if primary_view != null else null
	if map_root == null:
		return result
	var grid_token: String = "_%d_%d_" % [grid_position.x, grid_position.y]
	for child in map_root.get_children():
		var child_name: String = String(child.name)
		if (child_name.begins_with("HeightEdge_") or child_name.begins_with("HeightCorner_")) and child_name.contains(grid_token):
			result.append(child)
	return result


func _find_map_node(primary_view: Node, node_name: String) -> Node:
	var map_root = primary_view.get_node_or_null("ViewportContainer/SubViewport/WorldRoot/MapRoot3D") if primary_view != null else null
	if map_root == null:
		return null
	return map_root.get_node_or_null(node_name)


func _find_scene_node(root_node: Node, node_name: String) -> Node:
	if root_node == null:
		return null
	if root_node.name == node_name:
		return root_node
	for child in root_node.get_children():
		var found = _find_scene_node(child, node_name)
		if found != null:
			return found
	return null


func _node_has_mesh(node: Node) -> bool:
	if node == null:
		return false
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return true
	for child in node.get_children():
		if _node_has_mesh(child):
			return true
	return false


func _top_y(height_level: int) -> float:
	return float(height_level) * HEIGHT_STEP


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
