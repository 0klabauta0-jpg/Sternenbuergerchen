extends SceneTree

const MAP_EDITOR_SCENE_PATH: String = "res://scenes/editor/map_editor.tscn"
const LIVE_MISSION_SCENE_PATH: String = "res://scenes/tests/mission_reactivity_test.tscn"
const CALIBRATION_SCENE_PATH: String = "res://scenes/tests/mission_map_3d_calibration.tscn"
const RENDER_SPIKE_SCENE_PATH: String = "res://scenes/tests/mission_map_3d_render_spike.tscn"
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const KENNEY_DIAMOND_CENTER := Vector2(256.0, 315.0)
const MAX_3D_RENDER_DURATION_MSEC: int = 8000

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_159 2.5D Editor and Mission Primary View Verifier ===")
	await _test_editor_uses_3d_primary_view()
	await _test_authored_2_5d_visual_parity_contract()
	await _test_strict_3d_mapping_blocks_legacy_fallbacks()
	await _test_live_mission_uses_3d_primary_view()
	await _test_auxiliary_3d_map_scenes_load()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_editor_uses_3d_primary_view() -> void:
	var editor := _instantiate_scene(MAP_EDITOR_SCENE_PATH)
	_assert(editor != null, "Map editor scene instantiates")
	if editor == null:
		return
	root.add_child(editor)
	await _wait_frames(10)

	var primary_view := editor.get_node_or_null("Primary3DView")
	_assert(primary_view != null and primary_view.has_method("get_render_snapshot"), "Editor attaches Primary3DView")
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot")) if primary_view != null else {}
	_assert(int(snapshot.get("tile_count", 0)) > 0, "Editor Primary3DView renders terrain tiles")
	_assert(int(snapshot.get("ground_mesh_count", 0)) == int(snapshot.get("tile_count", 0)), "Editor Primary3DView renders calibrated 3D ground meshes")
	_assert(int(snapshot.get("asset_model_count", 0)) > 0, "Editor Primary3DView renders calibrated Kenney GLB asset models")
	_assert(int(snapshot.get("missing_asset_mapping_count", 0)) == 0, "Editor Primary3DView has no missing mapped 3D assets")
	_assert(_asset_model_nodes_have_models(primary_view), "Editor 2.5D asset nodes contain loaded 3D model meshes")
	_assert(int(snapshot.get("map_render_duration_msec", MAX_3D_RENDER_DURATION_MSEC + 1)) < MAX_3D_RENDER_DURATION_MSEC, "Editor Primary3DView map render stays below freeze threshold")

	var camera2d := editor.get_node_or_null("Camera2D") as Camera2D
	_assert(camera2d != null and not camera2d.enabled, "Editor legacy Camera2D is disabled")
	_assert(_canvas_item_hidden(editor, "Terrain") and _canvas_item_hidden(editor, "GridOverlay") and _canvas_item_hidden(editor, "SelectionOutline"), "Editor legacy 2D map containers are hidden")

	var yaw_before: float = float(primary_view.call("get_camera_yaw_degrees"))
	primary_view.call("rotate_camera", 30.0)
	var yaw_after: float = float(primary_view.call("get_camera_yaw_degrees"))
	_assert(absf(yaw_after - yaw_before) > 0.1, "Editor Camera3D can rotate")

	var known_world := Vector2(448.0, 285.0)
	var screen_position: Vector2 = primary_view.call("world_to_screen_position", known_world)
	var picked_world = primary_view.call("screen_to_world_position", screen_position)
	_assert(typeof(picked_world) == TYPE_VECTOR2 and Vector2(picked_world).distance_to(known_world) < 4.0, "Editor 3D view roundtrips screen picking to map world coordinates")

	editor.queue_free()
	await _wait_frames(2)


func _test_authored_2_5d_visual_parity_contract() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "visual_parity_3d", Vector2i(4, 4), Vector2(256.0, 128.0), 64.0, 32.0, 3)
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	_assert(map_data != null and catalog != null, "Visual parity test map and catalog instantiate")
	if map_data == null or catalog == null:
		return

	var elevated_tile = map_data.call("get_tile_at_grid", Vector2i(1, 1))
	elevated_tile.height_level = 1
	elevated_tile.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF
	elevated_tile.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK

	var wall_tile = map_data.call("get_tile_at_grid", Vector2i(2, 2))
	_assert(bool(catalog.call("apply_type_to_tile", wall_tile, "wall_straight_se")), "Visual parity map applies wall_straight_se")
	var wall_corner_tile = map_data.call("get_tile_at_grid", Vector2i(3, 1))
	_assert(bool(catalog.call("apply_type_to_tile", wall_corner_tile, "wall_corner_ne")), "Visual parity map applies wall_corner_ne")
	var satellite_tile = map_data.call("get_tile_at_grid", Vector2i(0, 2))
	_assert(bool(catalog.call("apply_type_to_tile", satellite_tile, "technik_satellite_large_se")), "Visual parity map applies large satellite object")
	var rock_tile = map_data.call("get_tile_at_grid", Vector2i(3, 3))
	_assert(bool(catalog.call("apply_type_to_tile", rock_tile, "rock_large")), "Visual parity map applies rock_large")

	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	await _wait_frames(6)

	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(snapshot.get("ground_mesh_count", 0)) == 16, "Visual parity 3D map renders every tile as calibrated ground mesh")
	_assert(int(snapshot.get("tile_texture_count", 0)) == 0 and int(snapshot.get("height_edge_texture_count", 0)) == 0, "Visual parity 3D map does not use flat Sprite3D texture cards as primary terrain")
	_assert(int(snapshot.get("asset_model_count", 0)) >= 4, "Visual parity 3D map renders wall, wall corner, rock and satellite as calibrated GLB models")
	_assert(int(snapshot.get("asset_texture_count", 0)) == 0, "Visual parity 3D map does not fall back to isometric Sprite3D asset cards for mapped assets")
	_assert(int(snapshot.get("placeholder_object_count", 0)) == 0, "Visual parity 3D map does not use block placeholders for mapped assets")
	_assert(int(snapshot.get("missing_asset_mapping_count", 0)) == 0, "Visual parity 3D map resolves all authored 3D asset mappings")

	var tile_node := _find_map_node(primary_view, "Tile_1_1")
	_assert(tile_node != null and _node_has_mesh(tile_node), "Visual parity ground tile uses the Kenney terrain GLB")
	_assert(tile_node != null and not _node_has_material_override(tile_node), "Visual parity ground tile keeps the Kenney terrain material")

	var wall_node := _find_map_node(primary_view, "Asset_wall_straight_se_2_2")
	_assert(wall_node != null and _node_has_mesh(wall_node), "Visual parity wall_straight_se loads the calibrated corridor wall model")
	_assert(wall_node != null and absf(wrapf(wall_node.rotation_degrees.y - 90.0, -180.0, 180.0)) < 0.1, "Visual parity wall_straight_se keeps calibrated SE rotation")
	var wall_corner_node := _find_map_node(primary_view, "Asset_wall_corner_ne_3_1")
	_assert(wall_corner_node != null and _node_has_mesh(wall_corner_node), "Visual parity wall_corner_ne loads the calibrated corridor corner model")
	_assert(wall_corner_node != null and absf(wrapf(wall_corner_node.rotation_degrees.y - 0.0, -180.0, 180.0)) < 0.1, "Visual parity wall_corner_ne keeps calibrated NE corner rotation")
	var satellite_node := _find_map_node(primary_view, "Asset_technik_satellite_large_se_0_2")
	_assert(satellite_node != null and _node_has_mesh(satellite_node), "Visual parity satellite loads the calibrated satelliteDish_large model")
	var rock_node := _find_map_node(primary_view, "Asset_rock_large_3_3")
	_assert(rock_node != null and _node_has_mesh(rock_node), "Visual parity rock_large loads the calibrated rock model")
	_assert(wall_node != null and satellite_node != null and satellite_node.scale.x > wall_node.scale.x, "Visual parity large satellite keeps larger calibrated 3D scale than wall")
	_assert(wall_corner_node != null and not _node_has_material_override(wall_corner_node), "Visual parity wall corner keeps model materials instead of fallback override")
	_assert(rock_node != null and not _node_has_material_override(rock_node), "Visual parity rock keeps model materials instead of fallback override")

	primary_view.queue_free()
	await _wait_frames(2)


func _test_strict_3d_mapping_blocks_legacy_fallbacks() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "missing_mapping_guard", Vector2i(1, 1), Vector2.ZERO)
	_assert(map_data != null, "Strict mapping guard map instantiates")
	if map_data == null:
		return
	var missing_tile = map_data.call("get_tile_at_grid", Vector2i.ZERO)
	missing_tile.object_type_id = "debug_missing_model_se"
	missing_tile.blocks_los = true
	missing_tile.object_height = 1

	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	await _wait_frames(6)

	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(snapshot.get("ground_mesh_count", 0)) == 1, "Strict mapping guard still renders mapped Kenney terrain ground")
	_assert(int(snapshot.get("missing_asset_mapping_count", 0)) == 1, "Strict mapping guard records the missing asset mapping")
	_assert(int(snapshot.get("asset_texture_count", 0)) == 0, "Strict mapping guard refuses Sprite3D texture fallback")
	_assert(int(snapshot.get("placeholder_object_count", 0)) == 0, "Strict mapping guard refuses block placeholder fallback")
	_assert(_find_map_node(primary_view, "MissingAsset_debug_missing_model_se_0_0") != null, "Strict mapping guard places a visible missing-asset marker")

	primary_view.queue_free()
	await _wait_frames(2)


func _test_live_mission_uses_3d_primary_view() -> void:
	var live_scene := _instantiate_scene(LIVE_MISSION_SCENE_PATH)
	_assert(live_scene != null, "Live mission scene instantiates")
	if live_scene == null:
		return
	root.add_child(live_scene)
	await _wait_frames(16)
	await _wait_physics_frames(4)

	var primary_view := live_scene.get_node_or_null("Primary3DView")
	_assert(primary_view != null and primary_view.has_method("get_render_snapshot"), "Live mission attaches Primary3DView")
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot")) if primary_view != null else {}
	_assert(int(snapshot.get("tile_count", 0)) > 0 and int(snapshot.get("unit_proxy_count", 0)) >= 2, "Live Primary3DView renders map and runtime unit proxies")
	_assert(int(snapshot.get("ground_mesh_count", 0)) == int(snapshot.get("tile_count", 0)), "Live Primary3DView renders calibrated 3D ground meshes")
	_assert(int(snapshot.get("asset_model_count", 0)) > 0, "Live Primary3DView renders calibrated Kenney asset models")
	_assert(int(snapshot.get("missing_asset_mapping_count", 0)) == 0, "Live Primary3DView has no missing mapped 3D assets")
	_assert(int(snapshot.get("unit_model_count", 0)) >= 2, "Live Primary3DView renders runtime units with Kenney astronaut GLBs")
	_assert(_asset_model_nodes_have_models(primary_view), "Live 2.5D asset nodes contain loaded 3D model meshes")
	_assert(_unit_model_nodes_have_models(primary_view), "Live 2.5D unit proxies contain loaded astronaut model meshes")
	_assert(int(snapshot.get("map_render_duration_msec", MAX_3D_RENDER_DURATION_MSEC + 1)) < MAX_3D_RENDER_DURATION_MSEC, "Live Primary3DView map render stays below freeze threshold")

	var map_root := live_scene.get_node_or_null("MapRoot") as CanvasItem
	var mission_camera := live_scene.get_node_or_null("MissionCamera") as Camera2D
	_assert(map_root != null and not map_root.visible, "Live legacy MapRoot is hidden")
	_assert(mission_camera != null and not mission_camera.enabled, "Live legacy Camera2D is disabled")

	var unit_alpha := live_scene.get_node_or_null("UnitAlpha") as CanvasItem
	var unit_alpha_visual := live_scene.get_node_or_null("UnitAlpha/Visual") as CanvasItem
	_assert(unit_alpha != null and unit_alpha.visible, "Live runtime UnitAlpha node remains visible for simulation/selection")
	_assert(unit_alpha_visual != null and not unit_alpha_visual.visible, "Live old UnitAlpha Sprite2D visual is hidden")

	var controller := live_scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Live mission TacticalController is present")
	if controller != null and primary_view != null:
		var lz_world := Vector2(448.0, 285.0)
		var lz_screen: Vector2 = primary_view.call("world_to_screen_position", lz_world)
		_assert(bool(controller.call("_place_lz_from_screen_position", lz_screen)), "TacticalController places LZ through 3D picking")
		await _wait_frames(3)
		var lz_state: Dictionary = Dictionary(controller.call("get_planning_state"))
		var post_lz_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
		var legacy_lz := live_scene.get_node_or_null("LZMarker") as CanvasItem
		_assert(bool(lz_state.get("has_lz_position", false)) and bool(post_lz_snapshot.get("has_lz", false)), "LZ is mirrored into the 3D primary view")
		_assert(legacy_lz != null and not legacy_lz.visible, "Old 2D LZ marker stays hidden")

		var available_fireteams: PackedStringArray = controller.call("_get_available_fireteam_ids")
		if not available_fireteams.is_empty():
			controller.call("_set_selected_fireteams", PackedStringArray([available_fireteams[0]]), false)
		controller.call("create_area_order_for_selected_fireteams_from_world_rect", Vector2(360.0, 150.0), Vector2(540.0, 250.0), "engage")
		await _wait_frames(3)
		var order_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
		_assert(int(order_snapshot.get("area_order_count", 0)) >= 1, "Attack Area is mirrored into the 3D primary view")

	live_scene.queue_free()
	await _wait_frames(2)


func _test_auxiliary_3d_map_scenes_load() -> void:
	await _assert_auxiliary_3d_map_scene_loads(CALIBRATION_SCENE_PATH, "Calibration")
	await _assert_auxiliary_3d_map_scene_loads(RENDER_SPIKE_SCENE_PATH, "Render spike")


func _assert_auxiliary_3d_map_scene_loads(scene_path: String, label: String) -> void:
	var scene_root := _instantiate_scene(scene_path)
	_assert(scene_root != null, "%s 3D map scene instantiates" % label)
	if scene_root == null:
		return
	root.add_child(scene_root)
	await _wait_frames(10)
	var primary_view := scene_root.get_node_or_null("Primary3DView")
	_assert(primary_view != null and primary_view.has_method("get_render_snapshot"), "%s 3D map scene attaches Primary3DView" % label)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot")) if primary_view != null else {}
	_assert(int(snapshot.get("tile_count", 0)) > 0, "%s 3D map scene renders terrain tiles" % label)
	_assert(int(snapshot.get("ground_mesh_count", 0)) == int(snapshot.get("tile_count", 0)), "%s 3D map scene renders calibrated ground meshes" % label)
	_assert(int(snapshot.get("asset_model_count", 0)) > 0, "%s 3D map scene renders calibrated asset models" % label)
	_assert(int(snapshot.get("missing_asset_mapping_count", 0)) == 0, "%s 3D map scene has no missing mapped 3D assets" % label)
	_assert(_asset_model_nodes_have_models(primary_view), "%s 3D map scene keeps loaded 3D asset meshes" % label)
	_assert(int(snapshot.get("map_render_duration_msec", MAX_3D_RENDER_DURATION_MSEC + 1)) < MAX_3D_RENDER_DURATION_MSEC, "%s 3D map scene render stays below freeze threshold" % label)
	scene_root.queue_free()
	await _wait_frames(2)


func _instantiate_scene(scene_path: String) -> Node:
	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		return null
	return packed_scene.instantiate()


func _canvas_item_hidden(root_node: Node, node_path: String) -> bool:
	var canvas_item := root_node.get_node_or_null(node_path) as CanvasItem
	return canvas_item != null and not canvas_item.visible


func _asset_model_nodes_have_models(primary_view: Node) -> bool:
	if primary_view == null:
		return false
	var map_root := primary_view.get_node_or_null("ViewportContainer/SubViewport/WorldRoot/MapRoot3D")
	if map_root == null:
		return false
	var inspected_count: int = 0
	for child in map_root.get_children():
		if child.is_queued_for_deletion():
			continue
		if not child is Node3D or not String(child.name).begins_with("Asset_"):
			continue
		if not _node_has_mesh(child):
			return false
		inspected_count += 1
	return inspected_count > 0


func _unit_model_nodes_have_models(primary_view: Node) -> bool:
	if primary_view == null:
		return false
	var unit_root := primary_view.get_node_or_null("ViewportContainer/SubViewport/WorldRoot/UnitRoot3D")
	if unit_root == null:
		return false
	var inspected_count: int = 0
	for proxy in unit_root.get_children():
		if proxy.is_queued_for_deletion() or not proxy is Node3D:
			continue
		var model_root: Node = null
		for child in proxy.get_children():
			if String(child.name).begins_with("UnitModel_"):
				model_root = child
				break
		if model_root == null or not _node_has_mesh(model_root):
			return false
		inspected_count += 1
		if absf(wrapf((proxy as Node3D).rotation_degrees.y, -180.0, 180.0)) > 0.05:
			return false
	return inspected_count > 0


func _find_map_node(primary_view: Node, relative_path: String) -> Node3D:
	if primary_view == null or relative_path.is_empty():
		return null
	var map_root := primary_view.get_node_or_null("ViewportContainer/SubViewport/WorldRoot/MapRoot3D")
	if map_root == null:
		return null
	return map_root.get_node_or_null(relative_path) as Node3D


func _find_map_mesh(primary_view: Node, relative_path: String) -> MeshInstance3D:
	return _find_map_node(primary_view, relative_path) as MeshInstance3D


func _node_has_mesh(node: Node) -> bool:
	if node == null:
		return false
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return true
	for child in node.get_children():
		if _node_has_mesh(child):
			return true
	return false


func _node_has_material_override(node: Node) -> bool:
	if node == null:
		return false
	if node is MeshInstance3D and (node as MeshInstance3D).material_override != null:
		return true
	for child in node.get_children():
		if _node_has_material_override(child):
			return true
	return false


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _wait_physics_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await physics_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
