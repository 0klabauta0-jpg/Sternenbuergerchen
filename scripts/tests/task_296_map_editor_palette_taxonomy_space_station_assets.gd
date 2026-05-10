extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")

const TERRAIN_MAPPING_PATH: String = "res://data/terrain_3d_asset_mapping.json"
const SPACE_CATALOG_PATH: String = "res://data/space_setpiece_catalog.json"
const INVENTORY_PATH: String = "res://docs/assets/space_station_palette_inventory.md"
const MANUAL_CHECK_PATH: String = "res://docs/manual_checks/map_editor_palette_space_station_checklist.md"

const EXPECTED_GROUP_ORDER: Array[String] = [
	"terrain",
	"nature_ground",
	"nature_props",
	"waende",
	"cliffs",
	"rampen",
	"felsen",
	"space_station",
]
const STATION_TYPE_IDS: Array[String] = [
	"station_wall",
	"station_wall_door",
	"station_computer",
	"station_table_display",
	"station_container_wide",
	"station_bed_single",
	"station_floor_panel",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_296 Map Editor Palette Taxonomy Space Station Assets ===")
	_test_catalogs_and_resources()
	await _test_editor_palette_filter()
	await _test_space_station_runtime_materials()
	_test_docs()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_catalogs_and_resources() -> void:
	var tile_catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	var mapping: Dictionary = _load_json(TERRAIN_MAPPING_PATH)
	var space_catalog: Dictionary = _load_json(SPACE_CATALOG_PATH)
	_assert(tile_catalog != null, "Terrain tile catalog loads")
	_assert(not mapping.is_empty(), "Terrain 3D mapping parses")
	_assert(not space_catalog.is_empty(), "Space setpiece catalog parses")
	var groups: Array = tile_catalog.call("get_palette_groups")
	_assert(_groups_are_in_order(groups, EXPECTED_GROUP_ORDER), "Palette group order starts with authoring taxonomy")
	var models: Dictionary = Dictionary(mapping.get("models", {}))
	for type_id in STATION_TYPE_IDS:
		_assert(bool(tile_catalog.call("has_type", type_id)), "Tile catalog has Space Station type: %s" % type_id)
		var entry: Dictionary = Dictionary(models.get(type_id, {}))
		var path: String = String(entry.get("model_path", ""))
		_assert(String(entry.get("source_id", "")) == "space_station_kit", "Mapping uses Space Station source: %s" % type_id)
		_assert(path.begins_with("res://Assets/curated/kenney/space_station/"), "Mapping path is project-local: %s" % type_id)
		_assert(not path.contains("C:/") and not path.contains("C:" + "\\"), "Mapping path has no absolute source path: %s" % type_id)
		_assert(ResourceLoader.exists(path), "Mapping resource loads: %s" % type_id)


func _test_editor_palette_filter() -> void:
	var editor = MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(14)
	editor.call("_on_palette_group_button_pressed", "space_station")
	await _wait_frames(2)
	var snapshot: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	var palette: Dictionary = Dictionary(snapshot.get("palette", {}))
	_assert(String(palette.get("active_group", "")) == "space_station", "Editor palette can filter Space Station group")
	var visible_ids: PackedStringArray = PackedStringArray(palette.get("visible_type_ids", PackedStringArray()))
	for type_id in STATION_TYPE_IDS:
		_assert(visible_ids.has(type_id), "Filtered palette exposes station type: %s" % type_id)
	editor.queue_free()
	await _wait_frames(2)


func _test_space_station_runtime_materials() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_296_space_station_materials", Vector2i(4, 2), Vector2.ZERO)
	for index in range(STATION_TYPE_IDS.size()):
		var grid := Vector2i(index % 4, int(index / 4))
		var tile_data = map_data.call("get_tile_at_grid", grid)
		if tile_data == null:
			continue
		tile_data.object_type_id = STATION_TYPE_IDS[index]
		tile_data.walkable = false
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	await _wait_frames(10)
	var snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	_assert(int(snapshot.get("space_station_model_count", 0)) >= STATION_TYPE_IDS.size(), "3D view renders Space Station models")
	_assert(int(snapshot.get("space_station_textured_surface_count", 0)) >= STATION_TYPE_IDS.size(), "3D view applies Space Station colormap texture")
	_assert(int(snapshot.get("missing_map_asset_mapping_count", 99)) == 0, "Space Station fixture has no missing 3D mappings")
	view.queue_free()
	await _wait_frames(2)


func _test_docs() -> void:
	_assert(FileAccess.file_exists(INVENTORY_PATH), "Space Station palette inventory exists")
	_assert(FileAccess.file_exists(MANUAL_CHECK_PATH), "Space Station palette checklist exists")


func _groups_are_in_order(groups: Array, expected_order: Array[String]) -> bool:
	var group_ids: PackedStringArray = PackedStringArray()
	for group_variant in groups:
		group_ids.append(String(Dictionary(group_variant).get("group_id", "")))
	for index in range(expected_order.size()):
		if index >= group_ids.size() or group_ids[index] != expected_order[index]:
			return false
	return true


func _load_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
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
