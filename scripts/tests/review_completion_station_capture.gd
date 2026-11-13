extends "res://scripts/tests/review_completion_maps_capture.gd"
## Original in-room camera plus an isolated joined-module sample. No user UI.
func run() -> void:
	output = OS.get_environment("SB_REVIEW_COMPLETION_CAPTURE_DIR")
	if output.is_empty() or OS.get_environment("SB_REVIEW2_USER_DIR").is_empty() or DisplayServer.get_name() == "headless":
		quit(2)
		return
	check(OS.get_user_data_dir().replace("\\", "/") == OS.get_environment("SB_REVIEW2_USER_DIR").replace("\\", "/"), "private profile")
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	var terrain = MAP.load_from_file("res://maps/station_outpost_64x64.json")
	var view = VIEW.new()
	root.add_child(view)
	view.configure_from_map(terrain, terrain.get_marker_position("objective_point"), 26.0)
	view.set_authoring_markers_visible(false)
	await settle_map(view)
	await capture("station_outpost_64x64_objective", {"source": "maps/station_outpost_64x64.json", "camera_size": 26.0, "render": view.get_render_snapshot()})
	view.queue_free()
	await frames()
	for map_id: String in ["Ground_Mission02_128x128", "test_mission_32x32_slots8"]:
		var other = MAP.load_from_file("res://maps/" + map_id + ".json")
		view = VIEW.new()
		root.add_child(view)
		view.configure_from_map(other, other.get_marker_position("objective_point", other.get_marker_position("spawn_alpha")), 26.0)
		view.set_authoring_markers_visible(false)
		await settle_map(view)
		await capture(map_id + "_objective", {"source": "maps/" + map_id + ".json", "camera_size": 26.0, "render": view.get_render_snapshot()})
		view.queue_free()
		await frames()
	var sample = MAP.create_empty("isolated_station_modules", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 3, "hex_axial_v1")
	for x in range(1, 7):
		for y in range(1, 7):
			var tile = sample.get_tile_at_grid(Vector2i(x, y))
			tile.type_id = "station_set_floor_panel"
			if y == 1 or x == 1:
				tile.object_type_id = "station_set_wall"
				tile.object_rotation_degrees = 90.0 if x == 1 else 0.0
			if x == 1 and y == 1: tile.object_type_id = "station_set_wall_corner"
			if x == 4 and y == 1: tile.object_type_id = "station_set_wall_door"
	view = VIEW.new()
	root.add_child(view)
	view.configure_from_map(sample, sample.get_tile_at_grid(Vector2i(3, 3)).world_position, 9.0)
	view.set_authoring_markers_visible(false)
	await settle_map(view)
	await capture("station_module_join_sample", {"source": "native imported station floor/wall/corner/door", "camera_size": 9.0, "render": view.get_render_snapshot()})
	view.queue_free()
	await frames()
	var file := FileAccess.open(output.path_join("capture_manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	print("REVIEW_STATION_CAPTURE passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)
