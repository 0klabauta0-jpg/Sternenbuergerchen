extends SceneTree
const EDITOR = preload("res://scenes/editor/map_editor.tscn")
var passed := 0
var failed := 0
func _init() -> void: call_deferred("_run")
func _check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print("PASS: " if value else "FAIL: ", label)
func _run() -> void:
	var source := "res://maps/trade_outpost.json"
	var before := FileAccess.get_sha256(source)
	var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(source))
	var editor = EDITOR.instantiate()
	editor.map_file_path = source
	root.add_child(editor)
	await process_frame
	_check(not bool(editor.call("set_palette_type_for_authoring", "factory_building_a")), "old building cannot be selected through authoring API")
	_check(bool(editor.call("set_palette_type_for_authoring", "frontier_habitat_exterior")), "current habitat can be inspected in palette")
	_check(bool(editor.call("activate_runtime_builder_tool", "asset")), "Asset quick tool selects current model")
	_check(String(editor.get("_selected_type_id")) == "frontier_habitat_exterior", "Asset quick tool has current habitat")
	_check(bool(editor.call("activate_runtime_builder_tool", "factory")), "Factory quick tool selects current model")
	_check(String(editor.get("_selected_type_id")) == "frontier_hall_exterior", "Factory quick tool has current hall")
	var map_data = editor.get("_terrain_map_data")
	var tile = map_data.get_tiles()[0]
	var state: String = JSON.stringify(tile.to_dict())
	editor.call("_apply_brush_at_world_position", tile.world_position)
	_check(JSON.stringify(tile.to_dict()) == state, "multi-cell asset cannot be painted as a single blocking cell")
	var target := "user://editor_metadata_%d/trade_saved.json" % OS.get_process_id()
	editor.call("_on_save_as_file_selected", target)
	_check(FileAccess.file_exists(target), "real SaveAs callback writes scratch file")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(target))
	for key in ["singleplayer_site", "place_world", "place_presentation"]:
		_check(saved.get(key) == original.get(key), "real editor SaveAs preserves " + key)
	editor.call("_load_map", target)
	_check(editor.get("_terrain_map_data").get_place_presentation() == original.place_presentation, "real editor reload retains place models")
	_check(FileAccess.get_sha256(source) == before, "source map untouched by SaveAs")
	editor.call("_load_map", "res://maps/station_outpost_64x64.json")
	_check(bool(editor.call("_is_fixed_authored_layout")), "migrated multi-cell layout protected until layout tools exist")
	var view = editor.get_node("Primary3DView")
	var snapshot: Dictionary = view.call("get_render_snapshot")
	_check(bool(snapshot.get("frontier_art_enabled", false)), "migrated station uses Frontier profile")
	_check(int(snapshot.get("missing_map_asset_mapping_count", -1)) == 0, "migrated station has no missing-model boxes")
	var dressing: Node3D = view.get("_place_dressing_root")
	_check(dressing != null and dressing.get_child_count() == 2, "actual renderer installs both current building scenes")
	editor.queue_free()
	await process_frame
	print("MAP_EDITOR_METADATA passed=%d failed=%d" % [passed,failed])
	quit(1 if failed else 0)
