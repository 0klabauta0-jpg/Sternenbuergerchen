extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

const TERRAIN_MAPPING_PATH: String = "res://data/terrain_3d_asset_mapping.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Bugfix Map Editor Station Floor Structure Undo ===")
	_test_catalog_layer_contract()
	await _test_editor_palette_undo_and_bounds()
	await _test_station_floor_and_layered_station_rendering()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_catalog_layer_contract() -> void:
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	_assert(catalog != null, "Tile catalog loads")
	_assert(not bool(catalog.call("is_object_layer_type", "station_floor_panel")), "Station floor panel is not an object-layer prop")
	_assert(bool(catalog.call("preserves_hill_fields_when_applied", "station_floor_panel")), "Station floor panel behaves as a hill-preserving floor paint")
	_assert(bool(catalog.call("is_structure_layer_type", "station_wall")), "Station wall is a structure layer")
	_assert(bool(catalog.call("is_structure_layer_type", "station_wall_door")), "Station door wall is a structure layer")

	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "station_layer_contract", Vector2i(2, 1), Vector2.ZERO)
	var wall_first = map_data.call("get_tile_at_grid", Vector2i(0, 0))
	catalog.call("apply_type_to_tile", wall_first, "station_wall")
	catalog.call("apply_type_to_tile", wall_first, "station_bed_single")
	_assert(String(wall_first.type_id) == "station_wall", "Placing a station prop after a wall keeps the wall structure")
	_assert(String(wall_first.object_type_id) == "station_bed_single", "Placing a station prop after a wall stores the prop separately")
	_assert(bool(wall_first.blocks_los) and not bool(wall_first.walkable), "Layered wall and prop keep wall blocking gameplay")
	_assert(int(wall_first.object_height) == 2 and int(wall_first.cover_value) == 60, "Layered wall and prop use the stronger gameplay values")

	var object_first = map_data.call("get_tile_at_grid", Vector2i(1, 0))
	catalog.call("apply_type_to_tile", object_first, "station_bed_single")
	catalog.call("apply_type_to_tile", object_first, "station_wall")
	_assert(String(object_first.type_id) == "station_wall", "Placing a wall after a station prop stores the wall as structure")
	_assert(String(object_first.object_type_id) == "station_bed_single", "Placing a wall after a station prop preserves the prop")

	var mapping: Dictionary = _load_json(TERRAIN_MAPPING_PATH)
	var models: Dictionary = Dictionary(mapping.get("models", {}))
	var floor_entry: Dictionary = Dictionary(models.get("station_floor_panel", {}))
	_assert(String(floor_entry.get("layer", "")) == "terrain_surface", "Station floor panel 3D mapping is terrain surface")
	_assert(float(floor_entry.get("y_offset", 0.0)) <= -0.04, "Station floor panel mapping is lowered for legacy object fallback")


func _test_editor_palette_undo_and_bounds() -> void:
	var editor = await _make_editor()
	_assert(editor != null, "Map editor scene instantiates")
	if editor == null:
		return

	var catalog = editor.get("_tile_catalog")
	for group_variant in Array(catalog.call("get_palette_groups")):
		var group_id: String = String(Dictionary(group_variant).get("group_id", "")).strip_edges().to_lower()
		if group_id.is_empty():
			continue
		editor.call("_on_palette_group_button_pressed", group_id)
		await _wait_frames(1)
		var palette: Dictionary = Dictionary(Dictionary(editor.call("get_map_editor_usability_snapshot", false)).get("palette", {}))
		_assert(bool(palette.get("all_visible_items_have_preview_icons", false)), "Palette group has preview icons: %s" % group_id)
		_assert(Vector2i(palette.get("preview_icon_size", Vector2i.ZERO)) == Vector2i(16, 16), "Palette preview icons stay text-sized")

	var map_data = editor.get("_terrain_map_data")
	var first_tile = map_data.call("get_tile_at_grid", Vector2i(2, 2))
	var second_tile = map_data.call("get_tile_at_grid", Vector2i(3, 2))
	_assert(first_tile != null and second_tile != null, "Undo fixture has two editable tiles")
	if first_tile != null and second_tile != null:
		var first_original_cover: int = int(first_tile.cover_value)
		var second_original_cover: int = int(second_tile.cover_value)
		editor.call("_apply_tile_patch", first_tile, {"cover_value": (first_original_cover + 17) % 100})
		editor.call("_apply_tile_patch", second_tile, {"cover_value": (second_original_cover + 23) % 100})
		var action_contract: Dictionary = Dictionary(editor.call("get_authoring_action_contract_snapshot"))
		_assert(int(action_contract.get("undo_depth", 0)) >= 2, "Undo stack records more than one step")
		editor.call("_undo_last_change")
		_assert(int(second_tile.cover_value) == second_original_cover, "First undo restores the latest tile")
		editor.call("_undo_last_change")
		_assert(int(first_tile.cover_value) == first_original_cover, "Second undo restores the previous tile")

	var patrol_before: int = Array(map_data.call("get_patrol_path", editor.get("_patrol_spawn_id"))).size()
	editor.call("_add_patrol_waypoint", Vector2(-99999.0, -99999.0))
	var patrol_after_outside: int = Array(map_data.call("get_patrol_path", editor.get("_patrol_spawn_id"))).size()
	_assert(patrol_after_outside == patrol_before, "Patrol authoring ignores outside-map clicks")
	var inside_tile = map_data.call("get_tile_at_grid", Vector2i(4, 4))
	if inside_tile != null:
		editor.call("_add_patrol_waypoint", Vector2(inside_tile.world_position))
		var patrol_path: Array = Array(map_data.call("get_patrol_path", editor.get("_patrol_spawn_id")))
		_assert(patrol_path.size() == patrol_before + 1, "Patrol authoring still adds waypoints on map tiles")
		_assert(Vector2(patrol_path[patrol_path.size() - 1]).is_equal_approx(Vector2(inside_tile.world_position)), "Patrol waypoint snaps to the tile center")
		editor.call("_move_patrol_waypoint", patrol_path.size() - 1, Vector2(-99999.0, -99999.0))
		var moved_path: Array = Array(map_data.call("get_patrol_path", editor.get("_patrol_spawn_id")))
		_assert(Vector2(moved_path[moved_path.size() - 1]).is_equal_approx(Vector2(inside_tile.world_position)), "Patrol drag ignores outside-map positions")

	var layered_tile = map_data.call("get_tile_at_grid", Vector2i(5, 5))
	if layered_tile != null:
		catalog.call("apply_type_to_tile", layered_tile, "station_wall")
		catalog.call("apply_type_to_tile", layered_tile, "station_bed_single")
		_assert(bool(editor.call("_erase_object_layer_from_tile", layered_tile)), "Eraser clears the top object on a layered station tile")
		_assert(String(layered_tile.type_id) == "station_wall" and String(layered_tile.object_type_id) == "", "Eraser leaves the station wall when removing the prop")
		_assert(bool(layered_tile.blocks_los) and int(layered_tile.object_height) == 2, "Eraser restores station wall gameplay after prop removal")
		_assert(bool(editor.call("_erase_object_layer_from_tile", layered_tile)), "Eraser can clear the remaining station wall structure")
		_assert(String(layered_tile.type_id) == "ground_flat", "Second eraser pass resets the station wall to ground")

	editor.queue_free()
	await _wait_frames(2)


func _test_station_floor_and_layered_station_rendering() -> void:
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "station_floor_rendering", Vector2i(2, 1), Vector2.ZERO)
	var layered_tile = map_data.call("get_tile_at_grid", Vector2i(0, 0))
	var floor_tile = map_data.call("get_tile_at_grid", Vector2i(1, 0))
	catalog.call("apply_type_to_tile", layered_tile, "station_wall")
	catalog.call("apply_type_to_tile", layered_tile, "station_bed_single")
	catalog.call("apply_type_to_tile", floor_tile, "station_floor_panel")

	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	await _wait_frames(12)
	var snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	_assert(int(snapshot.get("space_station_model_count", 0)) >= 4, "3D view renders station floor, wall and prop layers")
	_assert(int(snapshot.get("missing_map_asset_mapping_count", 99)) == 0, "Layered station fixture has no missing 3D asset mappings")
	var surface_entries: Array = Array(snapshot.get("surface_visual_entries", []))
	_assert(_has_top_anchored_station_floor(surface_entries, Vector2i(1, 0)), "Station floor panel renders top-aligned as terrain")
	_assert(_has_top_anchored_station_floor(surface_entries, Vector2i(0, 0)), "Station wall tiles use the station floor panel underneath")
	view.queue_free()
	await _wait_frames(2)


func _has_top_anchored_station_floor(entries: Array, grid_position: Vector2i) -> bool:
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if Vector2i(entry.get("grid_position", Vector2i(-99, -99))) != grid_position:
			continue
		if String(entry.get("model_key", "")) != "station_floor_panel":
			continue
		return absf(float(entry.get("visual_top_y", 999.0)) - float(entry.get("surface_y", -999.0))) <= 0.015
	return false


func _make_editor():
	var editor = MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(14)
	return editor


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
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
