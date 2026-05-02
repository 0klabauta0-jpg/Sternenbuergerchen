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
	_assert(int(snapshot.get("tile_texture_count", 0)) == int(snapshot.get("tile_count", 0)), "Editor Primary3DView renders authored terrain textures")
	_assert(int(snapshot.get("asset_texture_count", 0)) > 0, "Editor Primary3DView renders authored Kenney asset textures")
	_assert(_asset_texture_cards_have_textures(primary_view), "Editor 2.5D asset cards keep non-empty isometric textures")
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
	var satellite_tile = map_data.call("get_tile_at_grid", Vector2i(0, 2))
	_assert(bool(catalog.call("apply_type_to_tile", satellite_tile, "technik_satellite_large_se")), "Visual parity map applies large satellite object")

	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	await _wait_frames(6)

	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(snapshot.get("tile_texture_count", 0)) == 16, "Visual parity 3D map renders every tile as a terrain texture")
	_assert(int(snapshot.get("height_edge_texture_count", 0)) > 0, "Visual parity 3D map renders automatic cliff/slope edge textures")
	_assert(int(snapshot.get("asset_texture_count", 0)) >= 2, "Visual parity 3D map renders wall and satellite as authored texture cards")
	_assert(int(snapshot.get("asset_model_count", 0)) == 0, "Visual parity 3D map does not use GLB models for known authored texture assets")
	_assert(int(snapshot.get("placeholder_object_count", 0)) == 0, "Visual parity 3D map does not use block placeholders for known authored texture assets")

	var tile_sprite := _find_map_sprite(primary_view, "Tile_1_1")
	_assert(tile_sprite != null and _sprite_uses_texture(tile_sprite, "terrain_SW.png"), "Visual parity ground tile uses terrain_SW texture")
	_assert(tile_sprite != null and tile_sprite.offset.distance_to(_expected_kenney_anchor_offset(tile_sprite.texture)) < 0.05, "Visual parity ground tile keeps the Kenney diamond anchor")
	_assert(tile_sprite != null and tile_sprite.pixel_size >= 0.014, "Visual parity ground tile is scaled to fill the 2.5D grid spacing")
	_assert(_sprite_uses_fixed_map_card_orientation(tile_sprite), "Visual parity ground tile keeps fixed map orientation instead of camera billboarding")

	var wall_sprite := _find_map_sprite(primary_view, "AssetTexture_wall_straight_se_2_2/Texture")
	_assert(wall_sprite != null and _sprite_uses_texture(wall_sprite, "corridor_wall_NE.png"), "Visual parity wall_straight_se keeps authored corridor_wall_NE mapping")
	var satellite_sprite := _find_map_sprite(primary_view, "AssetTexture_technik_satellite_large_se_0_2/Texture")
	_assert(satellite_sprite != null and _sprite_uses_texture(satellite_sprite, "satelliteDish_large_SE.png"), "Visual parity satellite uses authored satelliteDish_large_SE texture")
	_assert(wall_sprite != null and satellite_sprite != null and satellite_sprite.pixel_size > wall_sprite.pixel_size, "Visual parity large satellite keeps larger 2.5D scale than wall card")
	_assert(_sprite_uses_fixed_map_card_orientation(wall_sprite) and _sprite_uses_fixed_map_card_orientation(satellite_sprite), "Visual parity authored assets keep fixed map orientation instead of camera billboarding")

	var height_sprite := _find_first_map_sprite_with_prefix(primary_view, "Height")
	_assert(height_sprite != null and String(height_sprite.texture.resource_path).get_file().begins_with("terrain_side"), "Visual parity elevated terrain renders Kenney side/cliff texture")
	_assert(_sprite_uses_fixed_map_card_orientation(height_sprite), "Visual parity elevated terrain keeps fixed map orientation instead of camera billboarding")

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
	_assert(int(snapshot.get("asset_texture_count", 0)) > 0, "Live Primary3DView renders authored Kenney asset textures")
	_assert(int(snapshot.get("unit_texture_count", 0)) >= 2, "Live Primary3DView renders runtime units with authored isometric sprites")
	_assert(_asset_texture_cards_have_textures(primary_view), "Live 2.5D asset cards keep non-empty isometric textures")
	_assert(_unit_texture_cards_have_textures(primary_view), "Live 2.5D unit proxies keep authored unit textures")
	_assert(_unit_texture_cards_keep_fixed_orientation(primary_view), "Live 2.5D unit proxies keep fixed map orientation instead of camera billboarding")
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
	_assert(int(snapshot.get("asset_texture_count", 0)) > 0, "%s 3D map scene renders authored asset textures" % label)
	_assert(_asset_texture_cards_have_textures(primary_view), "%s 3D map scene keeps textured asset cards" % label)
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


func _asset_texture_cards_have_textures(primary_view: Node) -> bool:
	if primary_view == null:
		return false
	var map_root := primary_view.get_node_or_null("ViewportContainer/SubViewport/WorldRoot/MapRoot3D")
	if map_root == null:
		return false
	var inspected_count: int = 0
	for child in map_root.get_children():
		if child.is_queued_for_deletion():
			continue
		if not child is Node3D or child.get_child_count() < 1 or not String(child.name).begins_with("AssetTexture_"):
			continue
		var sprite := child.get_child(0) as Sprite3D
		if sprite == null or sprite.is_queued_for_deletion() or sprite.texture == null:
			return false
		inspected_count += 1
		var texture_path: String = String(sprite.texture.resource_path).strip_edges()
		if texture_path.is_empty() or not texture_path.begins_with("res://Assets/kenney_space-kit/Isometric/"):
			return false
	return inspected_count > 0


func _unit_texture_cards_have_textures(primary_view: Node) -> bool:
	if primary_view == null:
		return false
	var unit_root := primary_view.get_node_or_null("ViewportContainer/SubViewport/WorldRoot/UnitRoot3D")
	if unit_root == null:
		return false
	var inspected_count: int = 0
	for proxy in unit_root.get_children():
		if proxy.is_queued_for_deletion() or not proxy is Node3D:
			continue
		var sprite := proxy.get_node_or_null("UnitTexture") as Sprite3D
		if sprite == null or sprite.texture == null:
			return false
		inspected_count += 1
		var texture_file: String = String(sprite.texture.resource_path).get_file()
		if not texture_file.begins_with("astronautA_") and not texture_file.begins_with("astronautB_"):
			return false
	return inspected_count > 0


func _unit_texture_cards_keep_fixed_orientation(primary_view: Node) -> bool:
	if primary_view == null:
		return false
	var unit_root := primary_view.get_node_or_null("ViewportContainer/SubViewport/WorldRoot/UnitRoot3D")
	if unit_root == null:
		return false
	var inspected_count: int = 0
	for proxy in unit_root.get_children():
		if proxy.is_queued_for_deletion() or not proxy is Node3D:
			continue
		var sprite := proxy.get_node_or_null("UnitTexture") as Sprite3D
		if sprite == null:
			return false
		inspected_count += 1
		if not _sprite_uses_fixed_map_card_orientation(sprite):
			return false
		if absf(wrapf((proxy as Node3D).rotation_degrees.y, -180.0, 180.0)) > 0.05:
			return false
	return inspected_count > 0


func _find_map_sprite(primary_view: Node, relative_path: String) -> Sprite3D:
	if primary_view == null or relative_path.is_empty():
		return null
	var map_root := primary_view.get_node_or_null("ViewportContainer/SubViewport/WorldRoot/MapRoot3D")
	if map_root == null:
		return null
	return map_root.get_node_or_null(relative_path) as Sprite3D


func _find_first_map_sprite_with_prefix(primary_view: Node, name_prefix: String) -> Sprite3D:
	if primary_view == null:
		return null
	var map_root := primary_view.get_node_or_null("ViewportContainer/SubViewport/WorldRoot/MapRoot3D")
	if map_root == null:
		return null
	for child in map_root.get_children():
		if child is Sprite3D and String(child.name).begins_with(name_prefix):
			return child as Sprite3D
	return null


func _sprite_uses_texture(sprite: Sprite3D, expected_file: String) -> bool:
	return sprite != null and sprite.texture != null and String(sprite.texture.resource_path).get_file() == expected_file


func _sprite_uses_fixed_map_card_orientation(sprite: Sprite3D) -> bool:
	return sprite != null and sprite.billboard == BaseMaterial3D.BILLBOARD_DISABLED and absf(sprite.rotation_degrees.y - 45.0) < 0.1


func _expected_kenney_anchor_offset(texture: Texture2D) -> Vector2:
	if texture == null:
		return Vector2.ZERO
	return (texture.get_size() * 0.5) - KENNEY_DIAMOND_CENTER


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
