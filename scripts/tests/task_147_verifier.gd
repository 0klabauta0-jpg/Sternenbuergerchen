extends SceneTree

const TERRAIN_MAP_3D_RENDERER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_renderer.gd")
const CALIBRATION_SCENE: PackedScene = preload("res://scenes/tests/mission_map_3d_calibration.tscn")

const ACTIVE_ASSET_DIR: String = "res://Assets/kenney_space-kit/3d"
const NEW_MODEL_KEYS: PackedStringArray = [
	"corridor_straight",
	"corridor_corner",
	"gate_simple",
	"gate_complex",
	"technik_turret_single",
	"technik_turret_double",
	"crater_large",
	"rock_large_b",
	"rocks_small_a",
	"desk_computer",
	"fahrzeug_rover",
	"fahrzeug_cargo_b",
]
const NEW_MODEL_FILES: PackedStringArray = [
	"corridor.glb",
	"corridor_corner.glb",
	"gate_simple.glb",
	"gate_complex.glb",
	"turret_single.glb",
	"turret_double.glb",
	"craterLarge.glb",
	"rock_largeB.glb",
	"rocks_smallA.glb",
	"desk_computer.glb",
	"rover.glb",
	"craft_cargoB.glb",
]
const CALIBRATION_SAMPLE_TYPES: PackedStringArray = [
	"corridor_straight_se",
	"corridor_corner_sw",
	"gate_simple_se",
	"gate_complex_sw",
	"technik_turret_single_ne",
	"technik_turret_double_se",
	"crater_large_se",
	"rock_large_b_sw",
	"rocks_small_a_ne",
	"desk_computer_se",
	"fahrzeug_rover_se",
	"fahrzeug_cargo_b_sw",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_147 3D Asset Curation and Mapping Expansion Verifier ===")
	var renderer = TERRAIN_MAP_3D_RENDERER_SCRIPT.new()
	_test_active_asset_files()
	_test_mapping_entries(renderer)
	await _test_calibration_scene_expansion()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_active_asset_files() -> void:
	for file_name in NEW_MODEL_FILES:
		var model_path: String = ACTIVE_ASSET_DIR.path_join(file_name)
		var import_path: String = "%s.import" % model_path
		_assert(FileAccess.file_exists(model_path), "Curated GLB exists: %s" % file_name)
		_assert(FileAccess.file_exists(import_path), "Curated GLB import metadata exists: %s.import" % file_name)


func _test_mapping_entries(renderer) -> void:
	var summary: Dictionary = Dictionary(renderer.call("get_mapping_summary"))
	_assert(Array(summary.get("missing_model_paths", [])).is_empty(), "Expanded 3D mapping has no missing model paths")
	_assert(int(summary.get("existing_model_count", 0)) >= 25, "Expanded 3D mapping exposes the original and new curated model set")
	for model_key in NEW_MODEL_KEYS:
		var entry: Dictionary = Dictionary(renderer.call("get_model_entry_for_type", model_key))
		var model_path: String = String(entry.get("model_path", ""))
		_assert(not entry.is_empty(), "Mapping entry exists for %s" % model_key)
		_assert(model_path.begins_with(ACTIVE_ASSET_DIR), "Mapping entry uses active 3D asset path for %s" % model_key)
		_assert(ResourceLoader.exists(model_path), "Mapped model loads for %s" % model_key)


func _test_calibration_scene_expansion() -> void:
	var scene := CALIBRATION_SCENE.instantiate()
	root.add_child(scene)
	for _index in range(4):
		await process_frame
	var render_result: Dictionary = Dictionary(scene.get("render_result"))
	var stats: Dictionary = Dictionary(render_result.get("stats", {}))
	var snapshot: Dictionary = Dictionary(scene.call("get_calibration_snapshot"))
	var entries: Array = Array(snapshot.get("entries", []))
	_assert(int(stats.get("terrain_count", 0)) == 190, "Expanded calibration scene uses a 19x10 grid")
	_assert(int(stats.get("object_count", 0)) >= 24, "Expanded calibration scene renders original plus new curated families")
	_assert(Array(snapshot.get("missing_model_paths", [])).is_empty(), "Expanded calibration scene reports no missing model paths")
	for type_id in CALIBRATION_SAMPLE_TYPES:
		_assert(_has_calibration_entry(entries, type_id), "Calibration scene includes %s" % type_id)
	scene.queue_free()
	await process_frame


func _has_calibration_entry(entries: Array, type_id: String) -> bool:
	for raw_entry in entries:
		var entry: Dictionary = Dictionary(raw_entry)
		if String(entry.get("type_id", "")) == type_id:
			return bool(entry.get("model_exists", false))
	return false


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
