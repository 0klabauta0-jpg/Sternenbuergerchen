extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

const TASK_DOC_PATH: String = "res://docs/tasks/TASK_485_map_editor_saveas_modular_scale_fix.md"
const WORKFLOW_CONTRACT_PATH: String = "res://docs/dev/map_editor_asset_workflow_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

const MODULAR_EXPECTED_BOUNDS: Dictionary = {
	"modular_floor": Vector3(1.05, 0.05, 1.05),
	"modular_floor_big": Vector3(2.05, 1.10, 2.05),
	"modular_floor_raised": Vector3(1.10, 0.90, 1.10),
	"modular_wall": Vector3(1.05, 1.10, 0.35),
	"modular_wall_corner": Vector3(0.35, 1.05, 0.35),
	"modular_gate": Vector3(1.10, 1.20, 0.40),
	"modular_gate_door": Vector3(1.10, 1.20, 0.40),
	"modular_corridor_wide": Vector3(2.05, 1.10, 2.05),
	"modular_corridor_wide_corner": Vector3(2.05, 1.10, 2.05),
	"modular_room_wide": Vector3(5.05, 1.10, 3.05),
}

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_485 Map Editor Save As and Modular Scale Fix ===")
	_test_docs()
	await _test_save_as_dialog_configuration()
	_test_modular_space_scales()
	_test_road_and_water_surface_catalog_rules()
	await _test_road_and_water_surface_rendering()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_docs() -> void:
	_assert(FileAccess.file_exists(TASK_DOC_PATH), "TASK_485 task file exists")
	_assert(_read_text(WORKFLOW_CONTRACT_PATH).contains("Save As"), "Workflow contract documents Save As")
	_assert(_read_text(WORKFLOW_CONTRACT_PATH).contains("Modular Space Kit"), "Workflow contract documents Modular Space Kit scale")
	_assert(_read_text(WORKFLOW_CONTRACT_PATH).contains("Street and water plates"), "Workflow contract documents street and water plate layering")
	_assert(_read_text(STATUS_PATH).contains("TASK_485 - Map Editor Save As and Modular Scale Fix"), "Implementation status tracks TASK_485")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_485 - Map Editor Save As and Modular Scale Fix"), "Roadmap lists TASK_485")


func _test_save_as_dialog_configuration() -> void:
	var editor = MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(12)
	editor.call("_open_save_as_dialog")
	await _wait_frames(1)
	var dialog := editor.get_node_or_null("UI/SaveAsDialog") as FileDialog
	_assert(dialog != null, "Map editor has a Save As dialog")
	if dialog == null:
		editor.queue_free()
		await _wait_frames(2)
		return
	_assert(int(dialog.file_mode) == int(FileDialog.FILE_MODE_SAVE_FILE), "Save As dialog saves a file instead of opening a directory")
	_assert(int(dialog.access) == int(FileDialog.ACCESS_RESOURCES), "Save As dialog starts in project resources")
	_assert(String(dialog.current_dir) == "res://maps", "Save As starts in res://maps")
	_assert(String(dialog.current_file).ends_with(".json"), "Save As suggests a JSON file")
	_assert(String(dialog.root_subfolder).is_empty(), "Save As is not locked to a root subfolder")
	_assert(PackedStringArray(dialog.filters).has("*.json ; JSON terrain map"), "Save As keeps the JSON filter")
	_assert(String(editor.call("_normalize_map_save_path", "res://maps/task_485_saveas")).ends_with("task_485_saveas.json"), "Save As adds the json extension")
	var project_absolute_without_extension: String = ProjectSettings.globalize_path("res://maps/task_485_project_absolute")
	_assert(String(editor.call("_normalize_map_save_path", project_absolute_without_extension)) == "res://maps/task_485_project_absolute.json", "Project-absolute Save As paths are localized to res://")
	editor.queue_free()
	await _wait_frames(2)


func _test_modular_space_scales() -> void:
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	var ids: Array = MODULAR_EXPECTED_BOUNDS.keys()
	ids.sort()
	for id_variant in ids:
		var type_id: String = String(id_variant)
		var scale: float = float(view.call("_get_asset_model_scale", type_id))
		_assert(absf(scale - 0.25) <= 0.001, "%s uses the calibrated 4x-source scale" % type_id)
		var scene := view.call("_get_asset_model_scene", type_id) as PackedScene
		_assert(scene != null, "%s model scene loads" % type_id)
		if scene == null:
			continue
		var instance := scene.instantiate() as Node3D
		view.call("_normalize_asset_model_instance", instance)
		var bounds: Dictionary = Dictionary(view.call("_get_local_visual_bounds", instance))
		var raw_size: Vector3 = Vector3(bounds.get("max", Vector3.ZERO)) - Vector3(bounds.get("min", Vector3.ZERO))
		var scaled_size: Vector3 = raw_size * scale
		var expected: Vector3 = Vector3(MODULAR_EXPECTED_BOUNDS.get(type_id, Vector3.ONE))
		_assert(scaled_size.x <= expected.x and scaled_size.y <= expected.y and scaled_size.z <= expected.z, "%s stays within expected modular tile footprint" % type_id)
		instance.free()
	view.queue_free()


func _test_road_and_water_surface_catalog_rules() -> void:
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	_assert(catalog != null, "Terrain tile catalog loads for road/water rules")
	if catalog == null:
		return
	for road_type in [
		"spacekit_terrain_road_corner",
		"spacekit_terrain_road_cross",
		"spacekit_terrain_road_end",
		"spacekit_terrain_road_split",
		"spacekit_terrain_road_straight",
	]:
		var entry: Dictionary = Dictionary(catalog.call("get_type", road_type))
		_assert(String(entry.get("placement_layer", "")) == "terrain", "%s is a terrain surface plate" % road_type)
		_assert(String(entry.get("surface_type", "")) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD, "%s writes road surface truth" % road_type)
		_assert(bool(entry.get("visual_surface_variant", false)), "%s preserves existing tile layers as a visual surface variant" % road_type)

	var layered_tile = TERRAIN_TILE_DATA_SCRIPT.new({
		"tile_id": "layered_road",
		"type_id": "ground_flat",
		"object_type_id": "",
		"grid_position": Vector2i.ZERO,
		"height_level": 1,
		"edge_type": TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE,
		"surface_type": TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND,
	})
	_assert(bool(catalog.call("apply_type_to_tile", layered_tile, "factory_building_a")), "Object layer fixture applies before road")
	_assert(String(layered_tile.object_type_id) == "factory_building_a", "Factory building is stored on the object layer")
	_assert(bool(catalog.call("apply_type_to_tile", layered_tile, "spacekit_terrain_road_straight")), "Road plate applies under an existing object")
	_assert(String(layered_tile.type_id) == "spacekit_terrain_road_straight", "Road plate keeps the base surface type_id")
	_assert(String(layered_tile.object_type_id) == "factory_building_a", "Road plate preserves existing object layer")
	_assert(String(layered_tile.surface_type) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD, "Road plate no longer resets to ground surface")
	_assert(int(layered_tile.height_level) == 1 and String(layered_tile.edge_type) == TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE, "Road plate preserves height and edge authoring")

	var water_tile = TERRAIN_TILE_DATA_SCRIPT.new({
		"tile_id": "harbor_water",
		"type_id": "ground_flat",
		"grid_position": Vector2i(1, 0),
		"surface_type": TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND,
	})
	_assert(bool(catalog.call("apply_type_to_tile", water_tile, "nature_ground_dirt_river_tile")), "Water/river plate applies from the asset palette")
	_assert(String(water_tile.surface_type) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_WATER, "Water/river plate writes water surface truth")
	_assert(bool(catalog.call("apply_type_to_tile", water_tile, "factory_building_a")), "Object placement can be layered over water")
	_assert(String(water_tile.surface_type) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_WATER, "Object placement preserves water surface truth")
	_assert(TERRAIN_TILE_DATA_SCRIPT.get_surface_path_cost(TERRAIN_TILE_DATA_SCRIPT.SURFACE_WATER) > TERRAIN_TILE_DATA_SCRIPT.get_surface_path_cost(TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND), "Water has a higher path cost than ground")


func _test_road_and_water_surface_rendering() -> void:
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_485_road_water_surface_rendering", Vector2i(3, 1), Vector2.ZERO)
	_assert(catalog != null and map_data != null, "Road/water render fixture instantiates")
	if catalog == null or map_data == null:
		return
	var ground_tile = map_data.call("get_tile_at_grid", Vector2i(0, 0))
	var road_tile = map_data.call("get_tile_at_grid", Vector2i(1, 0))
	var water_tile = map_data.call("get_tile_at_grid", Vector2i(2, 0))
	catalog.call("apply_type_to_tile", road_tile, "spacekit_terrain_road_straight")
	catalog.call("apply_type_to_tile", water_tile, "nature_ground_dirt_river_tile")
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	await _wait_frames(12)
	var snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("surface_visual_entries", []))
	_assert(_has_top_anchored_surface(entries, Vector2i(0, 0), "ground_flat"), "Default ground plate renders top-anchored")
	_assert(_has_top_anchored_surface(entries, Vector2i(1, 0), "spacekit_terrain_road_straight"), "Road plate renders as a top-anchored terrain surface")
	_assert(_has_top_anchored_surface(entries, Vector2i(2, 0), "nature_ground_dirt_river_tile"), "Water/river plate renders as a top-anchored terrain surface")
	_assert(_surface_tops_match(entries, Vector2i(0, 0), Vector2i(1, 0)), "Road plate top height matches regular ground")
	_assert(_surface_tops_match(entries, Vector2i(0, 0), Vector2i(2, 0)), "Water/river plate top height matches regular ground")
	view.queue_free()
	await _wait_frames(2)


func _has_top_anchored_surface(entries: Array, grid_position: Vector2i, model_key: String) -> bool:
	var entry: Dictionary = _get_surface_entry(entries, grid_position)
	if entry.is_empty() or String(entry.get("model_key", "")) != model_key:
		return false
	var surface_y: float = float(entry.get("surface_y", -999.0))
	var surface_top_y_offset: float = float(entry.get("surface_top_y_offset", 0.0))
	var visual_top_y: float = float(entry.get("visual_top_y", 999.0))
	return absf(visual_top_y - (surface_y + surface_top_y_offset)) <= 0.015


func _surface_tops_match(entries: Array, first_grid_position: Vector2i, second_grid_position: Vector2i) -> bool:
	var first_entry: Dictionary = _get_surface_entry(entries, first_grid_position)
	var second_entry: Dictionary = _get_surface_entry(entries, second_grid_position)
	if first_entry.is_empty() or second_entry.is_empty():
		return false
	return absf(float(first_entry.get("visual_top_y", INF)) - float(second_entry.get("visual_top_y", -INF))) <= 0.015


func _get_surface_entry(entries: Array, grid_position: Vector2i) -> Dictionary:
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if Vector2i(entry.get("grid_position", Vector2i(-99, -99))) == grid_position:
			return entry
	return {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
