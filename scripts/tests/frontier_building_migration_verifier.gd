extends SceneTree
const CATALOG = preload("res://scripts/terrain/terrain_tile_catalog.gd")
var passed := 0
var failed := 0
func _init() -> void: call_deferred("_run")
func _check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print("PASS: " if value else "FAIL: ", label)
func _old(id: String) -> bool:
	return id.begins_with("factory_building_") or id.begins_with("spacekit_hangar_") or id.begins_with("gebaeude_")
func _run() -> void:
	var catalog = CATALOG.load_from_file()
	var mapping: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/terrain_3d_asset_mapping.json"))
	for entry in catalog.get_all_types():
		if _old(String(entry.type_id)):
			_check(not bool(entry.get("palette_visible", true)), "old building unavailable for new authoring: " + String(entry.type_id))
	for id in mapping.models:
		if _old(String(id)):
			_check(String(mapping.models[id].model_path).begins_with("res://scenes/terrain/frontier_"), "legacy ID resolves to current exterior: " + String(id))
	for id in ["frontier_habitat_exterior", "frontier_hall_exterior"]:
		_check(catalog.has_type(id), "current building in palette: " + id)
		var path: String = Dictionary(mapping.models.get(id, {})).get("model_path", "")
		_check(not path.is_empty() and ResourceLoader.exists(path), "current exterior scene loads: " + id)
	for name in ["station_outpost_64x64", "station_outpost_192x192"]:
		var map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://maps/%s.json" % name))
		_check(map.get("terrain_visual_theme_id") == "frontier_illustrated_v1", name + " uses current profile")
		var old_count := 0
		var new_count: int = Array(Dictionary(map.get("place_presentation",{})).get("props",[])).size()
		for tile in map.tiles:
			if _old(String(tile.get("object_type_id", ""))): old_count += 1
		_check(old_count == 0, name + " has no obsolete buildings")
		_check(new_count == (2 if name.ends_with("64x64") else 18), name + " preserves building placement count")
	var editor := FileAccess.get_file_as_string("res://scripts/editor/map_editor.gd")
	_check(editor.contains('const DEFAULT_MAP_PATH: String = "res://maps/station_outpost_64x64.json"'), "editor opens editable current station")
	for script in ["mission_map_3d_calibration", "mission_map_3d_render_spike"]:
		var source := FileAccess.get_file_as_string("res://scripts/tests/%s.gd" % script)
		_check(source.contains('"res://maps/Ground_Mission01_32x32.json"'), script + " opens current authored map")
	var importer = preload("res://scripts/editor/map_builder_scene_importer.gd").new()
	for id in ["frontier_habitat_exterior", "factory_building_a"]:
		var result: Dictionary = importer.build_map_from_authoring({"grid_size":Vector2i(8,8), "placements":[{"type_id":id,"grid_position":Vector2i(3,3)}]})
		if id == "frontier_habitat_exterior":
			_check(bool(result.get("ok", false)), "compiler accepts current building with footprint")
			_check(Array(result.map_data.get_place_presentation().get("props", [])).size() == 1, "compiler persists current building")
		else:
			_check(not bool(result.get("ok", true)), "compiler rejects retired building")
			_check(not Array(result.get("issues",[])).is_empty(), "compiler explains retired building rejection")
	var view = preload("res://scripts/terrain/terrain_map_3d_view.gd").new()
	var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/qa/map_save_building_migration_20261110/old_building_bounds.json"))
	for id in old:
		if String(id).begins_with("_current_"): continue
		var entry: Dictionary = mapping.models[id]
		var model: Node3D = load(String(entry.model_path)).instantiate()
		view.call("_normalize_asset_model_instance", model)
		var bounds: Dictionary = view.call("_get_local_visual_bounds", model)
		var size: Vector3 = (Vector3(bounds.max)-Vector3(bounds.min))*float(entry.scale)
		var baseline: Dictionary = old[id]
		var lo: Array = baseline.min
		var hi: Array = baseline.max
		var previous := Vector3(float(hi[0])-float(lo[0]),float(hi[1])-float(lo[1]),float(hi[2])-float(lo[2]))*float(baseline.scale)
		_check(size.x <= previous.x+.0001 and size.y <= previous.y+.0001 and size.z <= previous.z+.0001, "legacy alias stays inside previous model envelope: " + String(id))
		model.free()
	view.free()
	print("FRONTIER_BUILDING_MIGRATION passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)
