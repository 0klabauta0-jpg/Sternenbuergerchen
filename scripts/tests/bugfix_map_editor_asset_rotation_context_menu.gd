extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")

const TERRAIN_MAPPING_PATH: String = "res://data/terrain_3d_asset_mapping.json"
const EXPECTED_TYPE_IDS: PackedStringArray = [
	"station_wall",
	"station_floor_panel",
	"modular_floor",
	"modular_wall",
	"modular_gate_door",
	"factory_building_a",
	"factory_chimney_large",
	"factory_detail_tank",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== BUGFIX Map Editor Asset Rotation Context Menu ===")
	_test_catalog_and_asset_resources()
	await _test_editor_rotation_controls_and_context_contract()
	_test_3d_rotation_surface_contract()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_catalog_and_asset_resources() -> void:
	var tile_catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	var mapping: Dictionary = _load_json(TERRAIN_MAPPING_PATH)
	_assert(tile_catalog != null, "Terrain tile catalog loads")
	_assert(not mapping.is_empty(), "Terrain 3D asset mapping loads")
	var group_ids: PackedStringArray = PackedStringArray()
	for group_variant in tile_catalog.call("get_palette_groups"):
		group_ids.append(String(Dictionary(group_variant).get("group_id", "")))
	_assert(group_ids.has("modular_space"), "Palette exposes Modular Space Kit group")
	_assert(group_ids.has("factory"), "Palette exposes Factory Kit group")
	var models: Dictionary = Dictionary(mapping.get("models", {}))
	for type_id in EXPECTED_TYPE_IDS:
		_assert(bool(tile_catalog.call("has_type", type_id)), "Tile catalog has %s" % type_id)
		var entry: Dictionary = Dictionary(tile_catalog.call("get_type", type_id))
		var texture_path: String = String(entry.get("texture_path", ""))
		_assert(texture_path.begins_with("res://Assets/curated/kenney/") and ResourceLoader.exists(texture_path), "Palette preview loads for %s" % type_id)
		var model_entry: Dictionary = Dictionary(models.get(type_id, {}))
		var model_path: String = String(model_entry.get("model_path", ""))
		_assert(model_path.begins_with("res://Assets/curated/kenney/") and ResourceLoader.exists(model_path), "3D model loads for %s" % type_id)


func _test_editor_rotation_controls_and_context_contract() -> void:
	var editor = MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(14)
	_assert(bool(editor.call("select_grid_for_authoring", Vector2i(1, 1))), "Editor can select fixture tile")
	var map_data = editor.get("_terrain_map_data")
	var tile_data = map_data.call("get_tile_at_grid", Vector2i(1, 1)) if map_data != null else null
	_assert(tile_data != null, "Editor fixture exposes selected tile data")
	if tile_data == null:
		editor.queue_free()
		await _wait_frames(2)
		return
	tile_data.type_id = "station_wall"
	tile_data.object_type_id = ""
	tile_data.object_rotation_degrees = 0.0
	editor.call("_refresh_property_panel")
	var selected_context: Dictionary = Dictionary(Dictionary(editor.call("get_map_editor_usability_snapshot", false)).get("selected_tile", {}))
	_assert(bool(selected_context.get("object_rotatable", false)), "Space Station wall is rotatable through editor UI contract")
	_assert(bool(editor.call("_rotate_selected_object", 90.0)), "Rotation command applies to Space Station structure")
	_assert(is_equal_approx(float(tile_data.object_rotation_degrees), 90.0), "Station structure stores tile rotation")
	tile_data.type_id = "station_floor_panel"
	tile_data.object_type_id = ""
	tile_data.object_rotation_degrees = 0.0
	editor.call("_refresh_property_panel")
	_assert(bool(editor.call("_rotate_selected_object", 90.0)), "Rotation command applies to Station floor panel")
	_assert(is_equal_approx(float(tile_data.object_rotation_degrees), 90.0), "Station floor panel stores tile rotation")
	_assert(bool(editor.call("_select_grid_area", Vector2i(1, 1), Vector2i(3, 2), false)), "Selection tool can select a dragged rectangular area")
	_assert(Array(editor.get("_selected_grids")).size() == 6, "Right-drag area selection helper selects all tiles in rectangle")
	var context_snapshot: Dictionary = Dictionary(Dictionary(editor.call("get_map_editor_usability_snapshot", false)).get("context_menu", {}))
	_assert(String(context_snapshot.get("activation", "")) == "right_mouse_release", "Context menu contract opens on right mouse release")
	_assert(bool(context_snapshot.get("area_selection_uses_right_drag", false)), "Context menu contract reserves right-drag for area selection")
	editor.queue_free()
	await _wait_frames(2)


func _test_3d_rotation_surface_contract() -> void:
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	_assert(bool(view.call("_ground_surface_supports_tile_rotation", "station_floor_panel")), "3D view rotates Station floor surface models")
	_assert(bool(view.call("_ground_surface_supports_tile_rotation", "modular_floor")), "3D view rotates Modular floor surface models")
	view.free()


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


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
