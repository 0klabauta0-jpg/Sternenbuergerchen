extends "res://scripts/tests/review_completion_maps_capture.gd"
## Real station ensembles and the unchanged approved Station64 overview camera.
func run() -> void:
	output = OS.get_environment("SB_REVIEW_COMPLETION_CAPTURE_DIR")
	if output.is_empty() or OS.get_environment("SB_REVIEW2_USER_DIR").is_empty() or DisplayServer.get_name() == "headless":
		quit(2); return
	check(OS.get_user_data_dir().replace("\\", "/") == OS.get_environment("SB_REVIEW2_USER_DIR").replace("\\", "/"), "private profile")
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280,720); root.content_scale_size = root.size
	for map_id: String in ["station_outpost_64x64", "station_outpost_192x192"]:
		var terrain = MAP.load_from_file("res://maps/"+map_id+".json")
		var regions: Array = terrain.get_place_presentation().station_module_layout.regions
		for region: Dictionary in regions:
			# Three differently rotated outer source ensembles plus the center.
			if map_id.ends_with("192x192") and region.id not in ["station_0_0","station_1_0","station_1_1","station_2_2"]: continue
			var bounds: Array = region.floor_boundary
			var r: int = roundi((float(bounds[1])+float(bounds[3]))*0.5)
			var q: int = roundi((float(bounds[0])+float(bounds[2]))*0.5)-floori(float(r-int(region.row_anchor))*0.5)
			var focus: Vector2 = terrain.get_tile_at_grid(Vector2i(q,r)).world_position
			if map_id.ends_with("64x64"): focus = terrain.get_marker_position("objective_point")
			var view = VIEW.new(); root.add_child(view)
			view.configure_from_map(terrain,focus,26.0)
			view.set_authoring_markers_visible(false)
			await settle_map(view)
			await capture(map_id+"_"+String(region.id),{"source":"maps/"+map_id+".json", "region":region, "camera_size":26.0, "render":view.get_render_snapshot()})
			view.queue_free(); await frames()
	var file := FileAccess.open(output.path_join("capture_manifest.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t")); file.close()
	print("REVIEW_STATION_ENSEMBLES_CAPTURE passed=%d failed=%d" % [passed,failed])
	quit(0 if failed==0 else 1)
