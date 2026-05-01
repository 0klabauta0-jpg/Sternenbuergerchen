extends SceneTree

const LIVE_MISSION_SCENE: PackedScene = preload("res://scenes/tests/mission_fireteam_dev_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_148 3D Primary Mission View Verifier ===")
	var scene := _instantiate_live_mission()
	root.add_child(scene)
	await _wait_frames(12)
	_test_live_mission_starts_3d_primary(scene)
	_test_2d_fallback_compare_path_remains_available(scene)
	await _wait_frames(2)
	_test_primary_3d_pick_can_drive_target_marker(scene)
	_test_debug_overlay_still_reads_primary_3d_sources(scene)
	scene.queue_free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_live_mission_starts_3d_primary(scene: Node) -> void:
	var bridge = scene.get_node_or_null("Mission25DVisualBridge")
	var map_root := scene.get_node_or_null("MapRoot") as CanvasItem
	var camera := bridge.get_node_or_null("Camera3D") as Camera3D if bridge != null else null
	var snapshot: Dictionary = Dictionary(bridge.call("get_bridge_snapshot")) if bridge != null else {}
	var render_result: Dictionary = Dictionary(bridge.call("get_render_result")) if bridge != null else {}
	var stats: Dictionary = Dictionary(render_result.get("stats", {}))
	_assert(bridge != null and bool(bridge.visible), "Live mission has a visible 3D bridge")
	_assert(bool(snapshot.get("valid", false)) and bool(snapshot.get("primary_3d_view_active", false)), "3D bridge is the primary active mission view")
	_assert(camera != null and camera.current, "3D bridge camera is current by default")
	_assert(map_root != null and not map_root.visible, "Legacy 2D map starts hidden behind the primary 3D view")
	_assert(bool(snapshot.get("hide_2d_map_when_visible", false)), "Bridge records that the 2D map is hidden while 3D is visible")
	_assert(int(stats.get("terrain_count", 0)) == int(snapshot.get("map_tile_count", -1)), "Primary 3D render covers the live mission map")


func _test_2d_fallback_compare_path_remains_available(scene: Node) -> void:
	var bridge = scene.get_node_or_null("Mission25DVisualBridge")
	var map_root := scene.get_node_or_null("MapRoot") as CanvasItem
	var simulation_root = scene.get_node_or_null("SimulationRoot")
	var queue_before: int = Array(simulation_root.get("command_queue")).size() if simulation_root != null else -1
	bridge.call("set_2d_fallback_visible", true)
	_assert(map_root != null and map_root.visible and bool(bridge.visible), "2D compare path can be shown while 3D remains visible")
	bridge.call("set_2d_fallback_visible", false)
	_assert(map_root != null and not map_root.visible and bool(bridge.visible), "2D compare path can be hidden again")
	bridge.call("set_bridge_visible", false)
	_assert(map_root != null and map_root.visible and not bool(bridge.visible), "Pure 2D fallback returns when the 3D bridge is hidden")
	bridge.call("set_bridge_visible", true)
	_assert(map_root != null and not map_root.visible and bool(bridge.call("is_primary_3d_view_active")), "Primary 3D view can be restored after fallback")
	var queue_after: int = Array(simulation_root.get("command_queue")).size() if simulation_root != null else -2
	_assert(queue_before == queue_after, "3D/2D fallback toggles do not mutate SimulationRoot command queue")


func _test_primary_3d_pick_can_drive_target_marker(scene: Node) -> void:
	var bridge = scene.get_node_or_null("Mission25DVisualBridge")
	var controller = scene.get_node_or_null("TacticalController")
	var target_marker := scene.get_node_or_null("TargetMarker") as Node2D
	var terrain_registry = scene.get_node_or_null("TerrainRegistry")
	var simulation_root = scene.get_node_or_null("SimulationRoot")
	var pick_case: Dictionary = _build_pick_case(bridge, terrain_registry)
	var screen_position: Vector2 = Vector2(pick_case.get("screen_position", Vector2.ZERO))
	var expected_target: Vector2 = Vector2(pick_case.get("target_position", Vector2.ZERO))
	var queue_before: int = Array(simulation_root.get("command_queue")).size() if simulation_root != null else -1
	var pick_snapshot: Dictionary = Dictionary(bridge.call("pick_screen_position", screen_position))
	var did_place: bool = bool(controller.call("try_place_target_from_screen_position", screen_position)) if controller != null else false
	_assert(bool(pick_snapshot.get("valid", false)), "Primary 3D bridge resolves a screen pick through Terrain25DPicker")
	_assert(Vector2i(pick_snapshot.get("grid_position", Vector2i.ZERO)) == Vector2i(pick_case.get("grid_position", Vector2i.ZERO)), "Primary 3D pick resolves the expected grid tile")
	_assert(did_place and target_marker != null and target_marker.global_position == expected_target, "Tactical target placement can use the primary 3D pick target")
	var queue_after: int = Array(simulation_root.get("command_queue")).size() if simulation_root != null else -2
	_assert(queue_before == queue_after, "Target placement via 3D pick does not enqueue gameplay commands by itself")


func _test_debug_overlay_still_reads_primary_3d_sources(scene: Node) -> void:
	var bridge = scene.get_node_or_null("Mission25DVisualBridge")
	var overlay = scene.get_node_or_null("Mission25DVisualBridge/TacticalDebugOverlay25D")
	overlay.call("set_overlay_enabled", true)
	var snapshot: Dictionary = Dictionary(overlay.call("refresh_overlay"))
	var layers: Dictionary = Dictionary(snapshot.get("layers", {}))
	_assert(bool(bridge.call("is_primary_3d_view_active")), "Debug overlay test runs over the primary 3D view")
	_assert(bool(snapshot.get("valid", false)) and bool(snapshot.get("enabled", false)), "Tactical debug overlay remains available over 3D")
	_assert(String(Dictionary(layers.get("height_floor", {})).get("source", "")) == "TerrainRegistry", "Debug overlay still reads Height/Floor from TerrainRegistry")
	_assert(String(Dictionary(layers.get("path", {})).get("source", "")) == "SimulationRoot/FireteamOrderVisualizer", "Debug overlay still reads path sources")


func _instantiate_live_mission() -> Node:
	return LIVE_MISSION_SCENE.instantiate()


func _build_pick_case(bridge: Node, terrain_registry: Node) -> Dictionary:
	var camera := bridge.get_node_or_null("Camera3D") as Camera3D
	var config: Dictionary = Dictionary(bridge.call("get_visual_projection_config"))
	var cell_size: float = float(config.get("cell_size", 1.0))
	var height_step: float = float(config.get("height_step", 0.25))
	var tile = _find_pickable_tile(terrain_registry)
	var grid_position: Vector2i = Vector2i(tile.grid_position)
	var floor_height: float = float(tile.floor_height)
	var world_3d := Vector3(float(grid_position.x) * cell_size, floor_height * height_step, float(grid_position.y) * cell_size)
	return {
		"grid_position": grid_position,
		"screen_position": camera.unproject_position(world_3d),
		"target_position": Vector2(terrain_registry.call("grid_to_world", grid_position)),
	}


func _find_pickable_tile(terrain_registry: Node):
	for tile in Array(terrain_registry.call("get_all_tiles")):
		if tile != null and bool(tile.walkable):
			return tile
	return Array(terrain_registry.call("get_all_tiles"))[0]


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
