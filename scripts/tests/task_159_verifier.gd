extends SceneTree

const MAP_EDITOR_SCENE_PATH: String = "res://scenes/editor/map_editor.tscn"
const LIVE_MISSION_SCENE_PATH: String = "res://scenes/tests/mission_reactivity_test.tscn"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_159 2.5D Editor and Mission Primary View Verifier ===")
	await _test_editor_uses_3d_primary_view()
	await _test_live_mission_uses_3d_primary_view()
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
	_assert(int(snapshot.get("asset_model_count", 0)) > 0, "Editor Primary3DView renders Kenney 3D asset models")

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
	_assert(int(snapshot.get("asset_model_count", 0)) > 0, "Live Primary3DView renders Kenney 3D asset models")

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


func _instantiate_scene(scene_path: String) -> Node:
	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		return null
	return packed_scene.instantiate()


func _canvas_item_hidden(root_node: Node, node_path: String) -> bool:
	var canvas_item := root_node.get_node_or_null(node_path) as CanvasItem
	return canvas_item != null and not canvas_item.visible


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
