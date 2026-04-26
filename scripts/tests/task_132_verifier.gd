extends SceneTree

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_RENDERER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_renderer.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")
const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")

const ASSET_DIR: String = "res://Assets/kenney_space-kit/Isometric"
const REQUIRED_GROUPS: PackedStringArray = [
	"deko",
	"technik",
	"gebaeude",
	"plattformen",
	"pipes",
	"rails",
	"crater",
	"fahrzeuge",
]
const SAMPLE_TYPE_BY_GROUP: Dictionary = {
	"deko": "deko_barrel_se",
	"technik": "technik_generator_se",
	"gebaeude": "gebaeude_structure_closed_se",
	"plattformen": "plattform_center_se",
	"pipes": "pipe_straight_se",
	"rails": "rail_se",
	"crater": "crater_small_se",
	"fahrzeuge": "fahrzeug_speeder_b_se",
}

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_132 Kenney Isometric Asset Palette Expansion Verifier ===")
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	var audit: Dictionary = _build_asset_audit()
	_test_asset_audit(audit, catalog)
	_test_catalog_entries(catalog)
	_test_renderer_samples(catalog)
	await _test_editor_palette_groups()
	print("Asset audit summary: %s" % JSON.stringify({
		"directional_family_count": int(audit.get("directional_family_count", 0)),
		"complete_family_count": Array(audit.get("complete_families", [])).size(),
		"curated_family_count": Array(audit.get("curated_families", [])).size(),
	}))
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_asset_audit(audit: Dictionary, catalog) -> void:
	var complete_families: Array = Array(audit.get("complete_families", []))
	var curated_families: Array = Array(audit.get("curated_families", []))
	_assert(int(audit.get("directional_family_count", 0)) >= 40, "Verifier groups Kenney assets by directional family")
	_assert(complete_families.size() >= 30, "Kenney audit finds many complete NE/NW/SE/SW families")
	_assert(curated_families.size() >= 8, "Verifier marks curated asset families from the task selection")
	for family in curated_families:
		_assert(complete_families.has(family), "Curated family %s has a complete direction set" % family)
	_assert(catalog != null, "Terrain tile catalog loads for asset audit")


func _test_catalog_entries(catalog) -> void:
	var group_lookup: Dictionary = {}
	for group_variant in Array(catalog.call("get_palette_groups")):
		var group: Dictionary = Dictionary(group_variant)
		group_lookup[String(group.get("group_id", ""))] = String(group.get("display_name", ""))
	for group_id in REQUIRED_GROUPS:
		_assert(group_lookup.has(group_id), "Catalog exposes palette group %s" % group_id)
		_assert(not String(group_lookup.get(group_id, "")).is_empty(), "Palette group %s has a display name" % group_id)

	var new_asset_count: int = 0
	var missing_paths: Array = []
	for type_variant in Array(catalog.call("get_all_types")):
		var tile_type: Dictionary = Dictionary(type_variant)
		if not REQUIRED_GROUPS.has(String(tile_type.get("palette_group", ""))):
			continue
		new_asset_count += 1
		var texture_path: String = String(tile_type.get("texture_path", ""))
		if texture_path.is_empty() or not ResourceLoader.exists(texture_path):
			missing_paths.append("%s -> %s" % [tile_type.get("type_id", ""), texture_path])
	_assert(new_asset_count >= 30, "Catalog contains at least 30 new Kenney asset tile types")
	_assert(missing_paths.is_empty(), "All new Kenney asset texture paths exist")


func _test_renderer_samples(catalog) -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_132_renderer_samples", Vector2i(REQUIRED_GROUPS.size(), 1), Vector2.ZERO)
	var renderer = TERRAIN_MAP_RENDERER_SCRIPT.new(catalog)
	for index in range(REQUIRED_GROUPS.size()):
		var group_id: String = REQUIRED_GROUPS[index]
		var type_id: String = String(SAMPLE_TYPE_BY_GROUP.get(group_id, ""))
		var tile_data = map_data.call("get_tile_at_grid", Vector2i(index, 0))
		_assert(catalog.call("apply_type_to_tile", tile_data, type_id), "Catalog applies sample type %s" % type_id)
		_assert(String(tile_data.type_id) == "ground_flat", "Object-layer sample %s keeps the terrain type" % type_id)
		_assert(String(tile_data.object_type_id) == type_id, "Object-layer sample %s stores object_type_id" % type_id)
	var map_root := Node2D.new()
	root.add_child(map_root)
	var render_result: Dictionary = Dictionary(renderer.call("render_map", map_data, map_root))
	var tiles: Dictionary = Dictionary(render_result.get("tiles", {}))
	var objects: Dictionary = Dictionary(render_result.get("objects", {}))
	for index in range(REQUIRED_GROUPS.size()):
		var group_id: String = REQUIRED_GROUPS[index]
		var type_id: String = String(SAMPLE_TYPE_BY_GROUP.get(group_id, ""))
		var tile_data = map_data.call("get_tile_at_grid", Vector2i(index, 0))
		var ground_sprite := tiles.get(tile_data.grid_position, null) as Sprite2D
		var object_sprites: Array = Array(objects.get(tile_data.grid_position, []))
		var object_sprite := object_sprites[0] as Sprite2D if not object_sprites.is_empty() else null
		var expected_path: String = String(Dictionary(catalog.call("get_type", type_id)).get("texture_path", ""))
		var ground_path: String = ground_sprite.texture.resource_path if ground_sprite != null and ground_sprite.texture != null else ""
		var object_path: String = object_sprite.texture.resource_path if object_sprite != null and object_sprite.texture != null else ""
		_assert(ground_path.ends_with("terrain_SW.png"), "Renderer keeps ground under %s sample" % group_id)
		_assert(object_path == expected_path, "Renderer draws object overlay texture for %s sample" % group_id)
	map_root.queue_free()
	_test_object_layer_save_roundtrip(catalog)
	_test_legacy_object_type_rendering(catalog)


func _test_editor_palette_groups() -> void:
	var scene = MAP_EDITOR_SCENE.instantiate()
	root.add_child(scene)
	for _index in range(10):
		await process_frame
	var tile_type_list := scene.get_node("UI/PalettePanel/Margin/VBox/TileTypeList") as ItemList
	_assert(tile_type_list != null, "Map editor exposes the tile type palette list")
	for group_id in REQUIRED_GROUPS:
		var header_found: bool = false
		var sample_found: bool = false
		for index in range(tile_type_list.item_count):
			var metadata: String = String(tile_type_list.get_item_metadata(index))
			if metadata == "__group:%s" % group_id:
				header_found = true
			if metadata == String(SAMPLE_TYPE_BY_GROUP.get(group_id, "")):
				sample_found = true
		_assert(header_found, "Map editor palette shows group header %s" % group_id)
		_assert(sample_found, "Map editor palette contains sample asset for group %s" % group_id)
	scene.queue_free()
	await process_frame


func _test_object_layer_save_roundtrip(catalog) -> void:
	var temp_path: String = "user://task_132_object_layer_roundtrip.json"
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_132_object_roundtrip", Vector2i(1, 1), Vector2.ZERO)
	var tile_data = map_data.call("get_tile_at_grid", Vector2i.ZERO)
	var type_id: String = "technik_generator_se"
	_assert(catalog.call("apply_type_to_tile", tile_data, type_id), "Object-layer roundtrip applies sample object")
	var save_error: Error = map_data.call("save_to_file", temp_path)
	_assert(save_error == OK, "Object-layer map saves without error")
	var reloaded = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", temp_path)
	var reloaded_tile = reloaded.call("get_tile_at_grid", Vector2i.ZERO) if reloaded != null else null
	_assert(reloaded_tile != null and String(reloaded_tile.type_id) == "ground_flat", "Object-layer roundtrip keeps terrain type")
	_assert(reloaded_tile != null and String(reloaded_tile.object_type_id) == type_id, "Object-layer roundtrip restores object_type_id")


func _test_legacy_object_type_rendering(catalog) -> void:
	var type_id: String = "deko_barrel_se"
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_132_legacy_object", Vector2i(1, 1), Vector2.ZERO)
	var tile_data = map_data.call("get_tile_at_grid", Vector2i.ZERO)
	tile_data.type_id = type_id
	tile_data.object_type_id = ""
	var renderer = TERRAIN_MAP_RENDERER_SCRIPT.new(catalog)
	var map_root := Node2D.new()
	root.add_child(map_root)
	var render_result: Dictionary = Dictionary(renderer.call("render_map", map_data, map_root))
	var tiles: Dictionary = Dictionary(render_result.get("tiles", {}))
	var objects: Dictionary = Dictionary(render_result.get("objects", {}))
	var ground_sprite := tiles.get(Vector2i.ZERO, null) as Sprite2D
	var object_sprites: Array = Array(objects.get(Vector2i.ZERO, []))
	var object_sprite := object_sprites[0] as Sprite2D if not object_sprites.is_empty() else null
	var expected_path: String = String(Dictionary(catalog.call("get_type", type_id)).get("texture_path", ""))
	var ground_path: String = ground_sprite.texture.resource_path if ground_sprite != null and ground_sprite.texture != null else ""
	var object_path: String = object_sprite.texture.resource_path if object_sprite != null and object_sprite.texture != null else ""
	_assert(ground_path.ends_with("terrain_SW.png"), "Legacy object type_id renders a ground tile underneath")
	_assert(object_path == expected_path, "Legacy object type_id renders as object overlay")
	map_root.queue_free()


func _build_asset_audit() -> Dictionary:
	var families_by_name: Dictionary = {}
	var dir := DirAccess.open(ASSET_DIR)
	if dir == null:
		return {
			"directional_family_count": 0,
			"complete_families": [],
			"curated_families": [],
		}
	dir.list_dir_begin()
	while true:
		var file_name: String = dir.get_next()
		if file_name.is_empty():
			break
		if dir.current_is_dir() or not file_name.ends_with(".png"):
			continue
		var base_name: String = file_name.get_basename()
		var direction: String = _extract_direction_suffix(base_name)
		if direction.is_empty():
			continue
		var family: String = base_name.substr(0, base_name.length() - 3)
		var directions: Array = Array(families_by_name.get(family, []))
		if not directions.has(direction):
			directions.append(direction)
		families_by_name[family] = directions
	dir.list_dir_end()

	var complete_families: Array = []
	var curated_families: Array = []
	for family in families_by_name.keys():
		var directions: Array = Array(families_by_name.get(family, []))
		var is_complete: bool = directions.has("NE") and directions.has("NW") and directions.has("SE") and directions.has("SW")
		if is_complete:
			complete_families.append(String(family))
	complete_families.sort()
	for family in _get_curated_families():
		if families_by_name.has(family):
			curated_families.append(family)
	return {
		"directional_family_count": families_by_name.size(),
		"complete_families": complete_families,
		"curated_families": curated_families,
	}


func _extract_direction_suffix(base_name: String) -> String:
	for direction in ["NE", "NW", "SE", "SW"]:
		if base_name.ends_with("_%s" % direction):
			return direction
	return ""


func _get_curated_families() -> PackedStringArray:
	return PackedStringArray([
		"barrel",
		"barrels",
		"machine_generator",
		"satelliteDish_large",
		"structure_closed",
		"hangar_smallB",
		"platform_center",
		"pipe_straight",
		"rail",
		"crater",
		"craft_speederB",
	])


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
