extends "res://scripts/tests/review_completion_maps_capture.gd"
## Same scene/camera: isolate H1 full-column cap acne from real side shadows.
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
	var parent: Node = view.get("_map_root")
	var visible_columns: Array[Node] = parent.find_children("HexGroundBatch_*", "MultiMeshInstance3D", true, false)
	var side_hulls: Array[Node] = parent.find_children("HexGroundSideShadow_*", "MultiMeshInstance3D", true, false)
	check(not visible_columns.is_empty() and not side_hulls.is_empty(), "actual station has visible columns and real raised side casters")
	var valid := true
	for node: MultiMeshInstance3D in visible_columns: valid = valid and node.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for node: MultiMeshInstance3D in side_hulls: valid = valid and node.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY and not node.multimesh.mesh.cap_top and not node.multimesh.mesh.cap_bottom
	check(valid, "current product separates top receivers from actual side-only shadow hulls")
	await capture("station_current_side_shadow", {"diagnostic":"current native production route", "camera_size":26.0})
	for node: MultiMeshInstance3D in side_hulls: node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for node: MultiMeshInstance3D in visible_columns:
		if node.multimesh.mesh.height > 0.2: node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	view.call("_request_viewport_redraw", true)
	await capture("station_previous_full_column_shadow", {"diagnostic":"old raised full-column caster, same current map and camera"})
	for node: MultiMeshInstance3D in visible_columns: node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	view.call("_request_viewport_redraw", true)
	await capture("station_no_column_shadow_control", {"diagnostic":"control only: all column casters disabled, not product behavior"})
	# Restore production side hulls, then reproduce only the prior floor caster.
	# Walls, buildings, rocks, ramps and actual cliff faces keep their shadows.
	for node: MultiMeshInstance3D in side_hulls: node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	var floors := restore_previous_floor_casters(parent, terrain)
	check(floors > 0, "floor-only control restores the previous caster on actual imported floors")
	view.call("_request_viewport_redraw", true)
	await capture("station_previous_floor_shadow_control", {"diagnostic":"control only: previous imported floor casters ON; production side hulls, real cliffs, ramps, walls and buildings retained", "floor_meshes":floors})
	view.queue_free()
	await frames()
	var file := FileAccess.open(output.path_join("capture_manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	print("REVIEW_STATION_SHADOW_CAPTURE passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)

func restore_previous_floor_casters(node: Node, terrain: RefCounted, floor_parent: bool = false) -> int:
	var label := String(node.name)
	var floor := floor_parent or label.begins_with("Asset_station_set_floor") or label.begins_with("GroundBatch_station_set_floor") or label.begins_with("GroundBatch_station_floor_panel")
	if label.begins_with("Tile_"):
		var fields: PackedStringArray = label.split("_")
		if fields.size() == 3 and fields[1].is_valid_int() and fields[2].is_valid_int():
			var tile = terrain.get_tile_at_grid(Vector2i(int(fields[1]), int(fields[2])))
			floor = tile != null and String(tile.type_id).begins_with("station_set_floor")
	var count := 0
	if floor and node is GeometryInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		count += 1
	for child: Node in node.get_children(): count += restore_previous_floor_casters(child, terrain, floor)
	return count
