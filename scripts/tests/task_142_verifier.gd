extends SceneTree

const LIVE_MISSION_SCENE: PackedScene = preload("res://scenes/tests/mission_fireteam_dev_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_142 2.5D Live Mission Visual Bridge Verifier ===")
	await _test_live_mission_bridge_renders_same_map()
	await _test_bridge_can_toggle_2d_fallback_without_simulation_changes()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_live_mission_bridge_renders_same_map() -> void:
	var scene := LIVE_MISSION_SCENE.instantiate()
	root.add_child(scene)
	for _index in range(8):
		await process_frame

	var bridge = scene.get_node_or_null("Mission25DVisualBridge")
	var setup = scene.get_node_or_null("MissionSetup")
	var terrain_registry = scene.get_node_or_null("TerrainRegistry")
	var simulation_root = scene.get_node_or_null("SimulationRoot")
	var snapshot: Dictionary = Dictionary(bridge.call("get_bridge_snapshot")) if bridge != null else {}
	var render_result: Dictionary = Dictionary(bridge.call("get_render_result")) if bridge != null else {}
	var stats: Dictionary = Dictionary(render_result.get("stats", {}))
	_assert(bridge != null, "Live mission scene contains the 2.5D visual bridge")
	_assert(bool(snapshot.get("valid", false)), "2.5D bridge renders in the live mission scene")
	_assert(setup != null and setup.has_method("get_loaded_terrain_map_data") and setup.call("get_loaded_terrain_map_data") != null, "Mission setup exposes loaded TerrainMapData")
	_assert(terrain_registry != null and int(snapshot.get("registry_tile_count", 0)) == int(snapshot.get("map_tile_count", -1)), "TerrainRegistry and bridge map use the same tile count")
	_assert(int(snapshot.get("terrain_count", 0)) == int(snapshot.get("map_tile_count", -1)), "3D terrain count matches live map tile count")
	_assert(int(stats.get("object_count", 0)) >= 3, "3D bridge renders object instances from the live map")
	_assert(Array(snapshot.get("missing_models", [])).is_empty(), "3D bridge has no missing model mappings for the live map")
	_assert(bridge.get_node_or_null("MapRoot3D/Terrain3D") != null, "3D bridge keeps terrain in its own container")
	_assert(bridge.get_node_or_null("MapRoot3D/Object3D") != null, "3D bridge keeps objects in their own container")
	_assert(bridge.get_node_or_null("Camera3D") is Camera3D and bridge.get_node_or_null("DirectionalLight3D") is DirectionalLight3D, "3D bridge has camera and light")
	_assert(simulation_root != null and simulation_root.get("terrain_registry_path") == NodePath("../TerrainRegistry"), "SimulationRoot keeps the existing TerrainRegistry path")
	scene.queue_free()
	await process_frame


func _test_bridge_can_toggle_2d_fallback_without_simulation_changes() -> void:
	var scene := LIVE_MISSION_SCENE.instantiate()
	root.add_child(scene)
	for _index in range(8):
		await process_frame
	var bridge = scene.get_node_or_null("Mission25DVisualBridge")
	var map_root = scene.get_node_or_null("MapRoot") as CanvasItem
	var simulation_root = scene.get_node_or_null("SimulationRoot")
	var command_queue_before: int = Array(simulation_root.get("command_queue")).size() if simulation_root != null else -1
	bridge.set("hide_2d_map_when_visible", true)
	bridge.call("set_bridge_visible", true)
	_assert(map_root != null and not map_root.visible, "Bridge can hide the 2D map as an optional visual fallback toggle")
	bridge.call("set_bridge_visible", false)
	_assert(map_root != null and map_root.visible, "Bridge restores the 2D map when the 2.5D layer is hidden")
	var command_queue_after: int = Array(simulation_root.get("command_queue")).size() if simulation_root != null else -2
	_assert(command_queue_before == command_queue_after, "Bridge visibility toggle does not mutate SimulationRoot command queue")
	scene.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
