extends SceneTree
## Real editor mutation/roundtrip guard for the fixed GM01 composition.
## Scratch saving never writes the regular map or scenario.
const EDITOR = preload("res://scenes/editor/map_editor.tscn")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const SOURCE := "res://maps/Ground_Mission01_32x32.json"
const SCRATCH := "user://gm01_frontier_editor_guard_roundtrip.json"
var passed := 0
var failed := 0


func _initialize() -> void:
	call_deferred("run")


func check(value: bool, label: String) -> void:
	if value:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		push_error("FAIL: " + label)


func content_fingerprint(data) -> String:
	var tiles: Array = []
	for tile in data.get_tiles():
		tiles.append(tile.to_dict())
	var markers := {}
	for id in data.get_marker_ids():
		markers[id] = data.get_marker_record(id)
	return JSON.stringify({"tiles": tiles, "markers": markers, "patrols": data.get_patrol_paths()}).sha256_text()


func run() -> void:
	var source_sha := FileAccess.get_sha256(SOURCE)
	var editor: Node = EDITOR.instantiate()
	editor.set("map_file_path", SOURCE)
	root.add_child(editor)
	await process_frame
	await process_frame
	var data = editor.get("_terrain_map_data")
	check(bool(editor.call("_is_fixed_authored_layout")), "regular GM01 loads as a protected authored layout")
	check(data.get_authored_visual_layout_id() == "gm01_frontier_outpost_v1", "editor preserves the concrete layout identity")
	var solid = null
	for tile in data.get_tiles():
		if tile.object_type_id == "frontier_scene_solid":
			solid = tile
			break
	check(solid != null, "regular map contains real persisted layout solids")
	if solid == null:
		editor.queue_free()
		await process_frame
		quit(1)
		return
	var before := content_fingerprint(data)
	check(not bool(editor.call("_erase_object_layer_from_tile", solid)), "erase refuses to make a visible building or rock walkable")
	check(not bool(editor.call("_apply_tile_patch", solid, {"walkable": true, "blocks_los": false, "height_level": 2})), "inspector patch refuses altered navigation/LOS/height facts")
	editor.call("select_grid_for_authoring", solid.grid_position)
	check(not bool(editor.call("_rotate_selected_object", 90.0)), "object rotation refuses divergence from the fixed visible geometry")
	check(not bool(editor.call("set_selected_object_scale", 2.0)), "object scale refuses divergence from the fixed visible geometry")
	check(not bool(editor.call("set_palette_type_for_authoring", "frontier_scene_solid")), "internal footprint is not a standalone paintable asset")
	editor.set("_active_palette_group_id", "all")
	editor.call("_populate_tile_palette")
	var palette: ItemList = editor.call("_get_tile_type_list")
	var internal_type_visible := false
	for index in range(palette.item_count):
		internal_type_visible = internal_type_visible or String(palette.get_item_metadata(index)) == "frontier_scene_solid"
	check(not internal_type_visible, "palette hides the internal layout footprint")
	editor.call("set_palette_type_for_authoring", "rock_small")
	var clear_tile = data.get_tile_at_grid(Vector2i(6, 11))
	editor.call("_apply_brush_at_world_position", clear_tile.world_position)
	editor.call("_apply_height_tool_at_world_position", clear_tile.world_position)
	editor.call("_apply_eraser_at_world_position", solid.world_position)
	editor.call("_apply_property_controls_to_selected_tile")
	var network_path: Array[Vector2i] = [Vector2i(6, 11), Vector2i(7, 11)]
	check(not bool(editor.call("_apply_network_path", "road", network_path)), "network drawing refuses to replace fixed terrain")
	editor.set("_selected_marker_id", "objective_point")
	check(not bool(editor.call("_move_marker_to_world_position", "objective_point", clear_tile.world_position)), "marker movement preserves the authored objective route")
	check(not bool(editor.call("_delete_selected_marker")), "marker deletion is refused")
	check(not bool(editor.call("_add_marker_of_selected_type")), "marker addition is refused")
	editor.call("_on_marker_assign_button_pressed", "objective_point")
	editor.call("_on_marker_name_text_changed", "Changed objective")
	editor.call("_on_marker_color_changed", Color.RED)
	editor.call("_on_selected_marker_type_item_selected", 0)
	editor.set("_patrol_spawn_id", "ground_patrol_route")
	editor.call("_add_patrol_waypoint", clear_tile.world_position)
	editor.call("_move_patrol_waypoint", 0, clear_tile.world_position)
	editor.call("_remove_patrol_waypoint", 0)
	editor.call("_on_clear_patrol_pressed")
	check(content_fingerprint(data) == before, "all real brush, height, object, property, marker and patrol attempts preserve facts")
	check(not bool(editor.get("_dirty")) and Array(editor.get("_undo_stack")).is_empty(), "rejected edits do not create dirty state or undo transactions")
	check(String(editor.get("_marker_feedback_text")).contains("geschützt"), "rejection explains the concrete layout restriction")
	var title := editor.get_node("UI/TopBar/Margin/HBox/TitleLabel") as Label
	check(title.text.contains("Layout geschützt") and title.tooltip_text.contains("Speichern"), "visible toolbar identifies protected layout and available saving")
	check(bool(editor.call("select_grid_for_authoring", Vector2i(6, 11))), "tile inspection and selection remain available")
	editor.set("_current_map_path", SCRATCH)
	editor.call("_save_current_map")
	check(FileAccess.file_exists(SCRATCH), "normal editor save still writes a scratch roundtrip")
	var reloaded = MAP.load_from_file(SCRATCH)
	check(reloaded.get_authored_visual_layout_id() == data.get_authored_visual_layout_id(), "editor save/load retains the layout identity")
	check(content_fingerprint(reloaded) == before, "editor save/load retains exact tile, marker and patrol facts")
	check(FileAccess.get_sha256(SOURCE) == source_sha, "editor verification preserves the actual standard-map file")
	editor.call("_create_new_map", Vector2i(4, 4))
	var ordinary = editor.get("_terrain_map_data")
	check(not bool(editor.call("_is_fixed_authored_layout")), "creating another map restores ordinary authoring")
	var ordinary_tile = ordinary.get_tile_at_grid(Vector2i(1, 1))
	check(bool(editor.call("_apply_tile_patch", ordinary_tile, {"walkable": false})) and not ordinary_tile.walkable, "ordinary maps retain their existing tile-edit behavior")
	editor.queue_free()
	await process_frame
	await process_frame
	if FileAccess.file_exists(SCRATCH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH))
	print("=== RESULTS: %d passed, %d failed ===" % [passed, failed])
	if failed == 0:
		print("GM01_FRONTIER_EDITOR_GUARD_ALL_PASS")
	quit(0 if failed == 0 else 1)
