extends SceneTree

const LIVE_MISSION_SCENE: PackedScene = preload("res://scenes/tests/mission_fireteam_dev_test.tscn")
const MOVEMENT_LAYER_SCRIPT: GDScript = preload("res://scripts/core/movement_layer.gd")
const SMOKE_MAP_PATH: String = "res://maps/task_144_2_5d_smoke.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_145 2.5D Tactical Debug Overlay Verifier ===")
	await _test_overlay_exists_and_layers_are_individually_togglable()
	await _test_overlay_reads_height_cover_and_walkability_from_registry()
	await _test_overlay_reads_paths_from_simulation_root()
	await _test_overlay_reads_air_debug_from_unit_registry_and_simulation_root()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_overlay_exists_and_layers_are_individually_togglable() -> void:
	var scene := _instantiate_smoke_mission()
	root.add_child(scene)
	await _wait_frames(10)
	var overlay = _get_overlay(scene)
	_assert(overlay != null, "Live mission has a 2.5D tactical debug overlay node")
	_assert(not bool(overlay.call("is_overlay_enabled")), "Overlay starts disabled for normal playtests")
	if overlay != null:
		overlay.call("set_overlay_enabled", true)
		_assert(bool(overlay.call("is_overlay_enabled")) and bool(overlay.visible), "Overlay can be enabled at runtime")
		for layer_id in ["height_floor", "cover_los", "walkability", "path", "air"]:
			overlay.call("set_layer_enabled", layer_id, false)
			_assert(not bool(overlay.call("is_layer_enabled", layer_id)), "Layer %s can be disabled independently" % layer_id)
			overlay.call("set_layer_enabled", layer_id, true)
			_assert(bool(overlay.call("is_layer_enabled", layer_id)), "Layer %s can be enabled independently" % layer_id)
	scene.queue_free()
	await process_frame


func _test_overlay_reads_height_cover_and_walkability_from_registry() -> void:
	var scene := _instantiate_smoke_mission()
	root.add_child(scene)
	await _wait_frames(10)
	var overlay = _get_overlay(scene)
	overlay.call("set_overlay_enabled", true)
	var snapshot: Dictionary = Dictionary(overlay.call("refresh_overlay"))
	var layers: Dictionary = Dictionary(snapshot.get("layers", {}))
	var height_layer: Dictionary = Dictionary(layers.get("height_floor", {}))
	var cover_layer: Dictionary = Dictionary(layers.get("cover_los", {}))
	var walk_layer: Dictionary = Dictionary(layers.get("walkability", {}))
	var ramp_sample: Dictionary = _find_sample_by_grid(Array(height_layer.get("samples", [])), Vector2i(1, 1))
	var generator_cover: Dictionary = _find_sample_by_grid(Array(cover_layer.get("samples", [])), Vector2i(2, 0))
	var ramp_walk: Dictionary = _find_sample_by_grid(Array(walk_layer.get("samples", [])), Vector2i(1, 1))
	var blocked_walk: Dictionary = _find_sample_by_grid(Array(walk_layer.get("samples", [])), Vector2i(2, 0))
	_assert(bool(snapshot.get("valid", false)) and bool(snapshot.get("enabled", false)), "Overlay snapshot is valid when enabled")
	_assert(String(height_layer.get("source", "")) == "TerrainRegistry" and int(height_layer.get("label_count", 0)) >= 15, "Height/Floor layer reads registered mission floor tiles")
	_assert(is_equal_approx(float(ramp_sample.get("floor_height", 0.0)), 1.0), "Height/Floor layer exposes saved ramp floor height")
	_assert(String(cover_layer.get("source", "")) == "TerrainRegistry" and int(generator_cover.get("cover_value", 0)) == 55, "Cover/LOS layer exposes saved cover value from Registry")
	_assert(bool(generator_cover.get("blocks_los", false)) and is_equal_approx(float(generator_cover.get("blocks_los_height", 0.0)), 3.2), "Cover/LOS layer exposes saved LOS blocker height")
	_assert(String(walk_layer.get("source", "")) == "TerrainRegistry" and String(ramp_walk.get("height_transition_type", "")) == "ramp", "Walkability layer exposes saved ramp transition")
	_assert(not bool(blocked_walk.get("walkable", true)), "Walkability layer exposes non-walkable tiles")
	scene.queue_free()
	await process_frame


func _test_overlay_reads_paths_from_simulation_root() -> void:
	var scene := _instantiate_smoke_mission()
	root.add_child(scene)
	await _wait_frames(10)
	var terrain_registry = scene.get_node_or_null("TerrainRegistry")
	var simulation_root = scene.get_node_or_null("SimulationRoot")
	var overlay = _get_overlay(scene)
	var path_points: Array = [
		terrain_registry.call("grid_to_world", Vector2i(0, 1)),
		terrain_registry.call("grid_to_world", Vector2i(1, 1)),
		terrain_registry.call("grid_to_world", Vector2i(3, 1)),
	]
	simulation_root.set("command_queue", [{
		"command_type": "move_to_position",
		"unit_id": "unit_alpha",
		"team_id": "team_alpha",
		"target_position": terrain_registry.call("grid_to_world", Vector2i(3, 1)),
		"path": path_points,
	}])
	overlay.call("set_overlay_enabled", true)
	var snapshot: Dictionary = Dictionary(overlay.call("refresh_overlay"))
	var path_layer: Dictionary = Dictionary(Dictionary(snapshot.get("layers", {})).get("path", {}))
	_assert(String(path_layer.get("source", "")) == "SimulationRoot/FireteamOrderVisualizer", "Path layer declares SimulationRoot/preview data source")
	_assert(int(path_layer.get("command_path_count", 0)) == path_points.size(), "Path layer reads queued path points from SimulationRoot")
	_assert(int(path_layer.get("target_count", 0)) == 1, "Path layer reads queued move target from SimulationRoot")
	scene.queue_free()
	await process_frame


func _test_overlay_reads_air_debug_from_unit_registry_and_simulation_root() -> void:
	var scene := _instantiate_smoke_mission()
	root.add_child(scene)
	await _wait_frames(10)
	var unit_registry = scene.get_node_or_null("UnitRegistry")
	var simulation_root = scene.get_node_or_null("SimulationRoot")
	var overlay = _get_overlay(scene)
	var air_unit = unit_registry.call("get_unit", "unit_alpha") if unit_registry != null else null
	var attacker = unit_registry.call("get_unit", "enemy_delta") if unit_registry != null else null
	if air_unit != null:
		air_unit.call("set_runtime_status", "idle", "", 0, "fire_at_will", "", 1.0, 0.0, 0.0, -1, null, 0, MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_AIR, 3)
	if attacker != null:
		attacker.call("set_runtime_status", "idle", "", 0, "fire_at_will", "", 1.0, 0.0, 0.0, -1, null, 0, MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_GROUND, 0)
	if simulation_root != null:
		if air_unit != null:
			simulation_root.call("register_known_unit", "unit_alpha", air_unit)
		if attacker != null:
			simulation_root.call("register_known_unit", "enemy_delta", attacker)
		simulation_root.call("enqueue_effect", {
			"effect_type": "damage",
			"unit_id": "unit_alpha",
			"attacker_unit_id": "enemy_delta",
			"attacker_team_id": "team_bravo",
			"damage": 5,
			"hit_chance": 1.0,
			"roll_override": 0.0,
		})
		simulation_root.call("_physics_process", 0.1)
	overlay.call("set_overlay_enabled", true)
	var snapshot: Dictionary = Dictionary(overlay.call("refresh_overlay"))
	var air_layer: Dictionary = Dictionary(Dictionary(snapshot.get("layers", {})).get("air", {}))
	_assert(String(air_layer.get("source", "")) == "UnitRegistry/SimulationRoot", "Air layer declares UnitRegistry/SimulationRoot data source")
	_assert(int(air_layer.get("air_unit_count", 0)) >= 1 and int(air_layer.get("max_altitude_band", 0)) >= 3, "Air layer exposes air unit altitude")
	_assert(String(air_layer.get("targeting_reason", "")) == "anti_air_required", "Air layer exposes last AA gate reason from SimulationRoot")
	scene.queue_free()
	await process_frame


func _instantiate_smoke_mission() -> Node:
	var scene := LIVE_MISSION_SCENE.instantiate()
	var setup = scene.get_node_or_null("MissionSetup")
	if setup != null:
		setup.set("map_file_path", SMOKE_MAP_PATH)
	return scene


func _get_overlay(scene: Node) -> Node:
	return scene.get_node_or_null("Mission25DVisualBridge/TacticalDebugOverlay25D")


func _find_sample_by_grid(samples: Array, grid_position: Vector2i) -> Dictionary:
	for sample_variant in samples:
		if typeof(sample_variant) != TYPE_DICTIONARY:
			continue
		var sample: Dictionary = Dictionary(sample_variant)
		if Vector2i(sample.get("grid_position", Vector2i(-999, -999))) == grid_position:
			return sample
	return {}


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
