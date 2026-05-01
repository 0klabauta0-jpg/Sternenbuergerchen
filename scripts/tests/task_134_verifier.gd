extends SceneTree

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_RENDERER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_renderer.gd")
const CALIBRATION_SCENE: PackedScene = preload("res://scenes/tests/mission_map_3d_calibration.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_134 3D Spike Visual Calibration Verifier ===")
	var renderer = TERRAIN_MAP_3D_RENDERER_SCRIPT.new()
	_test_mapping_calibration(renderer)
	_test_debug_grid_options(renderer)
	await _test_calibration_scene()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_mapping_calibration(renderer) -> void:
	_assert(float(renderer.call("get_model_scale_for_type", "deko_barrel_se")) > 1.0, "Mapping exposes per-family prop scale")
	_assert(float(renderer.call("get_model_y_offset_for_type", "fahrzeug_speeder_b_se")) > 0.0, "Mapping exposes per-family y_offset")
	_assert(float(renderer.call("get_model_rotation_offset_degrees_for_type", "deko_barrel_se")) == 0.0, "Mapping exposes per-family rotation offset")


func _test_debug_grid_options(renderer) -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_134_grid_options", Vector2i(2, 1), Vector2.ZERO)
	var root_with_grid := Node3D.new()
	root.add_child(root_with_grid)
	var with_grid: Dictionary = Dictionary(renderer.call("render_map", map_data, root_with_grid, {"show_debug_grid": true}))
	var terrain_with_grid: Dictionary = Dictionary(with_grid.get("terrain", {}))
	var first_ground_with_grid := terrain_with_grid.get(Vector2i.ZERO, null) as MeshInstance3D
	var size_with_grid: float = first_ground_with_grid.mesh.size.x if first_ground_with_grid != null and first_ground_with_grid.mesh is BoxMesh else 0.0
	root_with_grid.queue_free()

	var root_without_grid := Node3D.new()
	root.add_child(root_without_grid)
	var without_grid: Dictionary = Dictionary(renderer.call("render_map", map_data, root_without_grid, {"show_debug_grid": false}))
	var terrain_without_grid: Dictionary = Dictionary(without_grid.get("terrain", {}))
	var first_ground_without_grid := terrain_without_grid.get(Vector2i.ZERO, null) as MeshInstance3D
	var size_without_grid: float = first_ground_without_grid.mesh.size.x if first_ground_without_grid != null and first_ground_without_grid.mesh is BoxMesh else 0.0
	root_without_grid.queue_free()

	_assert(size_with_grid > 0.0 and size_without_grid > size_with_grid, "Renderer can reduce debug-grid gaps")


func _test_calibration_scene() -> void:
	var scene := CALIBRATION_SCENE.instantiate()
	root.add_child(scene)
	for _index in range(4):
		await process_frame
	var render_result: Dictionary = Dictionary(scene.get("render_result"))
	var stats: Dictionary = Dictionary(render_result.get("stats", {}))
	_assert(int(stats.get("terrain_count", 0)) == 112, "Calibration scene renders a compact test map")
	_assert(int(stats.get("object_count", 0)) >= 8, "Calibration scene instantiates many object families")
	var start_size: float = float(scene.call("get_camera_size"))
	scene.call("zoom_camera_by_steps", -2)
	var zoomed_size: float = float(scene.call("get_camera_size"))
	_assert(zoomed_size < start_size, "Spike camera zoom API changes orthographic size")
	var start_focus: Vector3 = scene.call("get_camera_focus")
	scene.call("rotate_camera_by", 15.0)
	_assert(scene.call("get_camera_focus") == start_focus, "Spike camera rotation keeps focus stable")
	scene.call("set_debug_grid_enabled", false)
	var no_grid_result: Dictionary = Dictionary(scene.get("render_result"))
	var no_grid_stats: Dictionary = Dictionary(no_grid_result.get("stats", {}))
	_assert(int(no_grid_stats.get("terrain_count", 0)) == 112, "Calibration scene can rerender with debug grid disabled")
	scene.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
