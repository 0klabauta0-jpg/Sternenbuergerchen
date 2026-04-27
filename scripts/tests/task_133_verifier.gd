extends SceneTree

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_RENDERER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_renderer.gd")
const TERRAIN_3D_MAPPING_PATH: String = "res://data/terrain_3d_asset_mapping.json"
const SPIKE_SCENE: PackedScene = preload("res://scenes/tests/mission_map_3d_render_spike.tscn")

const SAMPLE_TYPE_IDS: PackedStringArray = [
	"deko_barrel_se",
	"deko_barrels_nw",
	"technik_generator_nw",
	"technik_satellite_large_se",
	"gebaeude_structure_closed_se",
	"gebaeude_hangar_small_b_sw",
	"plattform_center_se",
	"pipe_straight_ne",
	"rail_sw",
	"crater_small_se",
	"fahrzeug_speeder_b_se",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_133 3D Asset Mapping Spike Verifier ===")
	var renderer = TERRAIN_MAP_3D_RENDERER_SCRIPT.new()
	var mapping: Dictionary = TERRAIN_MAP_3D_RENDERER_SCRIPT.call("load_mapping", TERRAIN_3D_MAPPING_PATH)
	_test_mapping(mapping, renderer)
	_test_source_audit(mapping)
	_test_renderer_samples(renderer)
	await _test_spike_scene()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_mapping(mapping: Dictionary, renderer) -> void:
	_assert(not mapping.is_empty(), "3D asset mapping loads")
	var summary: Dictionary = Dictionary(renderer.call("get_mapping_summary"))
	_assert(int(summary.get("model_count", 0)) >= 8, "3D mapping contains at least 8 model entries")
	_assert(int(summary.get("existing_model_count", 0)) >= 8, "At least 8 mapped GLB files exist in the project")
	_assert(Array(summary.get("missing_model_paths", [])).is_empty(), "All mapped project GLB files exist")

	var resolved_count: int = 0
	for type_id in SAMPLE_TYPE_IDS:
		var entry: Dictionary = Dictionary(renderer.call("get_model_entry_for_type", type_id))
		var model_path: String = String(entry.get("model_path", ""))
		if not model_path.is_empty() and ResourceLoader.exists(model_path):
			resolved_count += 1
	_assert(resolved_count >= 6, "At least 6 existing TASK_132 asset types resolve to 3D models")
	_assert(float(renderer.call("get_rotation_degrees_for_type", "deko_barrel_se")) == 90.0, "3D renderer derives SE rotation from type suffix")
	_assert(float(renderer.call("get_rotation_degrees_for_type", "deko_barrel_nw")) == 270.0, "3D renderer derives NW rotation from type suffix")
	_assert(float(renderer.call("get_model_scale_for_type", "deko_barrel_se")) > 1.0, "3D mapping can upscale small prop models")


func _test_source_audit(mapping: Dictionary) -> void:
	var source: Dictionary = Dictionary(mapping.get("source", {}))
	var source_path: String = String(source.get("local_path", ""))
	var glb_count: int = _count_source_glb_files(source_path)
	_assert(glb_count >= 150, "Local 3D asset source folder exposes the expected GLB set")
	_assert(int(source.get("audited_glb_count", 0)) == glb_count, "3D mapping documents the audited GLB count")
	print("3D asset audit summary: %s" % JSON.stringify({
		"source_path": source_path,
		"glb_count": glb_count,
		"preferred_format": String(source.get("preferred_format", "")),
	}))


func _test_renderer_samples(renderer) -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_133_renderer_samples", Vector2i(3, 1), Vector2.ZERO)
	var sample_ids: PackedStringArray = ["deko_barrel_se", "technik_generator_nw", "fahrzeug_speeder_b_sw"]
	for index in range(sample_ids.size()):
		var tile_data = map_data.call("get_tile_at_grid", Vector2i(index, 0))
		tile_data.object_type_id = sample_ids[index]
		tile_data.walkable = false
		tile_data.blocks_los = index > 0
		tile_data.cover_value = 25
	var map_root := Node3D.new()
	root.add_child(map_root)
	var result: Dictionary = Dictionary(renderer.call("render_map", map_data, map_root))
	var terrain: Dictionary = Dictionary(result.get("terrain", {}))
	var objects: Dictionary = Dictionary(result.get("objects", {}))
	var stats: Dictionary = Dictionary(result.get("stats", {}))
	_assert(int(stats.get("terrain_count", 0)) == 3, "3D renderer creates one ground node per map tile")
	_assert(int(stats.get("object_count", 0)) == 3, "3D renderer creates object instances from object_type_id")
	_assert(terrain.has(Vector2i.ZERO), "3D renderer keeps terrain layer separate")
	_assert(objects.has(Vector2i.ZERO), "3D renderer keeps object layer separate")
	var first_object := objects.get(Vector2i.ZERO, null) as Node3D
	_assert(first_object != null and absf(rad_to_deg(first_object.rotation.y) - 90.0) < 0.01, "3D object instance receives suffix rotation")
	_assert(Array(stats.get("missing_models", [])).is_empty(), "3D renderer reports no missing sample models")
	map_root.queue_free()


func _test_spike_scene() -> void:
	var scene := SPIKE_SCENE.instantiate()
	root.add_child(scene)
	for _index in range(4):
		await process_frame
	var render_result: Dictionary = Dictionary(scene.get("render_result"))
	var stats: Dictionary = Dictionary(render_result.get("stats", {}))
	_assert(int(stats.get("terrain_count", 0)) == 1024, "3D spike scene renders the 32x32 test map terrain")
	_assert(int(stats.get("object_count", 0)) >= 3, "3D spike scene renders object-layer instances from the test map")
	var camera := scene.get_node_or_null("Camera3D") as Camera3D
	_assert(camera != null, "3D spike scene has a camera")
	_assert(camera != null and camera.size <= 14.0, "3D spike scene camera focuses the object cluster")
	_assert(scene.get_node_or_null("DirectionalLight3D") is DirectionalLight3D, "3D spike scene has a light")
	scene.queue_free()
	await process_frame


func _count_source_glb_files(source_path: String) -> int:
	if source_path.is_empty():
		return 0
	var gltf_path: String = source_path.path_join("Models").path_join("GLTF format")
	var dir := DirAccess.open(gltf_path)
	if dir == null:
		return 0
	var count: int = 0
	dir.list_dir_begin()
	while true:
		var file_name: String = dir.get_next()
		if file_name.is_empty():
			break
		if not dir.current_is_dir() and file_name.ends_with(".glb"):
			count += 1
	dir.list_dir_end()
	return count


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
