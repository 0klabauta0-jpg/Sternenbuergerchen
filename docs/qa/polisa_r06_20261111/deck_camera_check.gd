extends SceneTree
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	failures += int(not value)
	print("POLISA_R06 ", label, "=", value)
func run() -> void:
	var map = MAP.load_from_file("res://maps/polisa_station.json")
	var presentation: Dictionary = map.get_place_presentation()
	presentation.station_camera_max_size = 720.0
	presentation.space_bounds_plane = [-512.0,-208.0,512.0,235.0]
	map.set_place_presentation(presentation)
	var view = VIEW.new()
	root.add_child(view)
	await process_frame
	view.set("_terrain_map_data", map)
	view.call("_read_map_transform")
	view.call("_ensure_nodes")
	view.set("_hex_grid_visible", true)
	var tiles := {}
	for tile in map.get_tiles():
		if tile.walkable:
			tiles[tile.grid_position] = tile
			if tiles.size() == 3: break
	var dressing := Node3D.new()
	var prop := Node3D.new()
	prop.set_meta("station_deck_owns_flat_ground",true)
	dressing.add_child(prop)
	view.get("_world_root").add_child(dressing)
	view.set("_place_dressing_root",dressing)
	view.set("_place_dressing_signature",JSON.stringify(presentation))
	view.call("_sync_place_reference_dressing")
	check(bool(view.get("_orbital_deck_owns_ground")), "live_deck_owner_is_recognized")
	var many: Array = []
	many.resize(5000)
	many.fill(tiles.values()[0])
	var selected: Array = view.call("_select_tiles_for_visual_render",many)
	check(selected.size() == 5000 and not bool(view.get("_visual_streaming_active")), "whole_station_resident_without_camera_streaming")
	view.call("_build_terrain_visuals",tiles.values(),tiles.values())
	var ground: Node = view.get("_map_root")
	var grid: MeshInstance3D = ground.get_node_or_null("TileGridLines3D")
	check(grid != null and grid.mesh.get_surface_count() == 1 and ground.get_child_count() == 1, "one_grid_mesh_without_duplicate_ground_caps")
	view.call("_clear_children",ground)
	var raised = load("res://scripts/terrain/terrain_tile_data.gd").from_dict(tiles.values()[0].to_dict())
	raised.height_level = 1
	view.call("_build_terrain_visuals",[raised],[raised])
	var raised_caps := 0
	for child: Node in ground.get_children():
		if child is MultiMeshInstance3D: raised_caps += child.multimesh.instance_count
	check(raised_caps == 1, "flat_deck_owner_preserves_elevated_tile_caps")
	view.call("_clamp_focus_to_map")
	var bounds: Rect2 = view.get("_map_plane_bounds")
	check(bounds == Rect2(-512,-208,1024,443), "camera_includes_authored_empty_forefield")
	view.set("_orbital_deck_owns_ground",false)
	view.call("_select_tiles_for_visual_render",many)
	check(bool(view.get("_visual_streaming_active")), "missing_deck_owner_keeps_legacy_streaming")
	view.zoom_camera(-1000)
	check(is_equal_approx(view.get("_camera_size"), 720.0), "normal_zoom_reaches_full_station_limit")
	presentation.station_camera_max_size = 99999.0
	map.set_place_presentation(presentation)
	check(view.get_camera_zoom_limit() == 2048.0, "station_limit_is_bounded")
	presentation.station_camera_max_size = NAN
	map.set_place_presentation(presentation)
	check(view.get_camera_zoom_limit() == 280.0, "invalid_station_limit_uses_legacy_default")
	presentation.station_camera_max_size = 720.0
	map.set_place_presentation(presentation)
	view.set("_visual_streaming_active",false)
	view.set("_orbital_station_view", false)
	view.zoom_camera(-1000)
	check(is_equal_approx(view.get("_camera_size"), 120.0), "ordinary_map_limit_unchanged")
	view.queue_free()
	await process_frame
	print("POLISA_R06 failures=", failures)
	quit(0 if failures == 0 else 1)
