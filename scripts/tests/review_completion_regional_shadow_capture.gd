extends "res://scripts/tests/review_completion_maps_capture.gd"
## Diagnostic pairs isolate actual shadow receivers/casters; not acceptance shots.
func run() -> void:
	output = OS.get_environment("SB_REVIEW_COMPLETION_CAPTURE_DIR")
	if output.is_empty() or OS.get_environment("SB_REVIEW2_USER_DIR").is_empty() or DisplayServer.get_name() == "headless":
		quit(2)
		return
	check(OS.get_user_data_dir().replace("\\", "/") == OS.get_environment("SB_REVIEW2_USER_DIR").replace("\\", "/"), "private profile")
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	var terrain = MAP.load_from_file("res://maps/fortified_outpost.json")
	var view = VIEW.new()
	root.add_child(view)
	view.configure_from_map(terrain, terrain.get_marker_position("objective_point"), 26.0)
	view.set_authoring_markers_visible(false)
	await settle_map(view)
	var caps: Array[Node] = view.get("_map_root").find_children("HexGroundBatch_*", "MultiMeshInstance3D", true, false)
	var caps_receive_only := not caps.is_empty()
	for cap: MultiMeshInstance3D in caps:
		caps_receive_only = caps_receive_only and cap.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	check(caps_receive_only, "actual regional caps receive shadows without self-shadow stripes")
	var relief: Array[Node] = view.get("_map_root").find_children("Regional*", "MeshInstance3D", true, false)
	check(not relief.is_empty(), "actual regional height relief is present")
	var relief_casts := not relief.is_empty()
	for face: MeshInstance3D in relief:
		relief_casts = relief_casts and face.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	check(relief_casts, "real cliff and ramp silhouettes retain shadow casting")
	await capture("regional_actual", {"diagnostic": "current native production route"})
	var changed := 0
	for node: MultiMeshInstance3D in view.get("_map_root").find_children("HexGroundBatch_*", "MultiMeshInstance3D", true, false):
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		changed += 1
	check(changed > 0, "actual regional caps located")
	view.call("_request_viewport_redraw", true)
	await capture("regional_caps_no_shadow", {"diagnostic": "only cap shadowcasting disabled", "changed_batches": changed})
	for node: MeshInstance3D in view.get("_map_root").find_children("Regional*", "MeshInstance3D", true, false):
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	view.call("_request_viewport_redraw", true)
	await capture("regional_all_terrain_no_shadow", {"diagnostic": "caps plus regional slope/cliff shadowcasting disabled"})
	view.queue_free()
	await frames()
	var file := FileAccess.open(output.path_join("capture_manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	print("REVIEW_REGIONAL_SHADOW_CAPTURE passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)
