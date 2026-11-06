extends SceneTree
## Controlled native visual diagnostic, not a physical gameplay/mission proof.
## Real MapData + actual TerrainMap3DView + both installed MultiMesh resources.
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const VIEW: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const HELPER: GDScript = preload("res://scripts/terrain/frontier_reference_dressing.gd")
var passed := 0
var failed := 0
var output_dir := ""
var samples: Array = []


func _initialize() -> void:
	call_deferred("run")


func check(value: bool, label: String) -> void:
	if value:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		push_error("FAIL: " + label)


func run() -> void:
	check(DisplayServer.get_name() != "headless", "GPU gate requires a real native display backend")
	if DisplayServer.get_name() == "headless":
		_finish()
		return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output-dir="):
			output_dir = argument.trim_prefix("--output-dir=")
	check(not output_dir.is_empty(), "Fresh evidence directory is supplied explicitly by Root")
	if output_dir.is_empty():
		_finish()
		return
	check(DirAccess.make_dir_recursive_absolute(output_dir) == OK, "Native evidence directory is available")
	root.mode = Window.MODE_FULLSCREEN
	await process_frame
	await process_frame
	check(root.mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN], "Native checks run in full screen")
	var map_before := FileAccess.get_sha256("res://maps/Ground_Mission01_32x32.json")
	var data = MAP.load_from_file("res://maps/Ground_Mission01_32x32.json")
	var view = VIEW.new()
	root.add_child(view)
	view.configure_from_map(data)
	var facts: Dictionary = view.get("_authored_visual_layout_facts")
	var layer := facts.get("reference_dressing_layer") as Node3D
	check(is_instance_valid(layer), "Actual native GM01 installs the new local visual layer")
	if not is_instance_valid(layer):
		view.free()
		_finish()
		return
	var cache: Dictionary = layer.get_meta(HELPER.CACHE_KEY)
	var slots: Array = cache.get("slots", [])
	var both_kinds := {}
	var visible_ids: Array = []
	var explored_ids: Array = []
	var used_cells := {}
	for kind in ["agave", "gravel"]:
		for slot in slots:
			if String(slot["kind"]) != kind or used_cells.has(slot["tile_id"]):
				continue
			used_cells[slot["tile_id"]] = true
			if not both_kinds.has(kind):
				visible_ids.append(slot["tile_id"])
				both_kinds[kind] = 1
			elif int(both_kinds[kind]) == 1:
				explored_ids.append(slot["tile_id"])
				both_kinds[kind] = 2
				break
	check(int(both_kinds.get("agave", 0)) == 2 and int(both_kinds.get("gravel", 0)) == 2 and slots.size() > 4, "Both actual batches have mixed current/explored/unknown source cells")
	var positions: Array = []
	for id in visible_ids:
		for slot in slots:
			if slot["tile_id"] == id:
				positions.append(data.call("_grid_to_world", slot["grid_position"]))
				break
	view.frame_world_positions(positions, 6.0, 22.0, 22.0)
	var yaw: float = view.get_camera_yaw_degrees()
	for angle_index in range(2):
		view.rotate_camera((yaw + float(angle_index) * 52.0) - view.get_camera_yaw_degrees())
		for stage in ["off", "blackout_unknown", "blackout_mixed", "known_terrain"]:
			var mode: String = "unexplored_blackout" if stage.begins_with("blackout") else stage
			var current: Array = visible_ids if stage == "blackout_mixed" else []
			var explored: Array = explored_ids if stage == "blackout_mixed" else []
			view.set_fog_of_war_state({"mode": mode, "team_id": "controlled_visual_diagnostic", "visibility_revision": angle_index * 10 + samples.size() + 1,
				"terrain_knowledge": {"visible_tile_ids": current, "explored_tile_ids": explored}, "current_visibility": {"visible_target_ids": [], "visible_event_ids": []}})
			if stage == "blackout_unknown":
				check(int(view.get_reference_dressing_snapshot().get("visible_count", -1)) == 0, "Mode switch fails closed before the first rebuild frame")
			await _settle_fog(view)
			await RenderingServer.frame_post_draw
			_assert_actual_slots(view, layer, mode, current, explored, "%d/%s" % [angle_index, stage])
			var filename := "%02d_angle%d_%s.png" % [samples.size(), angle_index, stage]
			var image: Image = root.get_texture().get_image()
			check(image != null and image.get_width() == root.size.x and image.get_height() == root.size.y, "Capture has the actual full-screen viewport dimensions")
			if image != null:
				check(image.save_png(output_dir.path_join(filename)) == OK, "Saved actual native " + filename)
			var receipt: Dictionary = view.get_reference_dressing_snapshot()
			samples.append({"stage": stage, "angle_index": angle_index, "yaw": view.get_camera_yaw_degrees(), "camera_size": view.get_camera_size(),
				"capture": filename, "capture_sha256": FileAccess.get_sha256(output_dir.path_join(filename)), "receipt": receipt})
	check(FileAccess.get_sha256("res://maps/Ground_Mission01_32x32.json") == map_before, "Native diagnostic preserves the saved map bytes")
	var report := {"diagnostic_only": true, "physical_gameplay_proof": false, "backend": DisplayServer.get_name(), "fullscreen": true,
		"viewport": [root.size.x, root.size.y], "passed": passed, "failed": failed, "samples": samples,
		"pins": {"map": map_before, "helper": FileAccess.get_sha256(HELPER.resource_path), "view": FileAccess.get_sha256(VIEW.resource_path),
			"layout": FileAccess.get_sha256("res://scripts/terrain/frontier_gm01_layout.gd"), "verifier": FileAccess.get_sha256(get_script().resource_path)}}
	var file := FileAccess.open(output_dir.path_join("native_world_gpu.json"), FileAccess.WRITE)
	check(file != null, "Native GPU manifest opens")
	if file != null:
		file.store_string(JSON.stringify(report, "\t"))
	view.free()
	await process_frame
	_finish()


func _settle_fog(view) -> void:
	for frame in range(64):
		await process_frame
		if not bool(view.get("_fow_overlay_full_rebuild_pending")):
			break
	check(not bool(view.get("_fow_overlay_full_rebuild_pending")), "Actual bounded FoW rebuild completes")
	await process_frame


func _assert_actual_slots(view, layer: Node3D, mode: String, current: Array, explored: Array, label: String) -> void:
	var cache: Dictionary = layer.get_meta(HELPER.CACHE_KEY)
	var actual_counts := {"agave": {"shown": 0, "hidden": 0}, "gravel": {"shown": 0, "hidden": 0}}
	var matches := true
	for slot in cache.get("slots", []):
		var admitted := mode != "unexplored_blackout" or current.has(slot["tile_id"]) or explored.has(slot["tile_id"])
		var batch: MultiMeshInstance3D = slot["batch"]
		# Real RenderingServer-backed MultiMesh readback, only in native mode.
		var actual: Transform3D = batch.multimesh.get_instance_transform(int(slot["index"]))
		var expected: Transform3D = slot["base_transform"]
		matches = matches and (actual.is_equal_approx(expected) if admitted else actual.basis.x.length() < 0.00001 and actual.basis.y.length() < 0.00001 and actual.basis.z.length() < 0.00001)
		actual_counts[slot["kind"]]["shown" if admitted else "hidden"] += 1
	check(matches, label + ": every GPU-backed slot transform matches its independent source-cell admission")
	if mode == "unexplored_blackout":
		check(int(actual_counts["agave"]["hidden"]) > 0 and int(actual_counts["gravel"]["hidden"]) > 0, label + ": neither large batch AABB admits unknown slots")
		if not current.is_empty():
			check(int(actual_counts["agave"]["shown"]) > 0 and int(actual_counts["gravel"]["shown"]) > 0, label + ": current/explored slots remain shown in both mixed batches")
	var receipt: Dictionary = view.get_reference_dressing_snapshot()
	check(int(receipt.get("last_cell_lookups", 99999)) <= 480 and int(receipt.get("last_transform_writes", 99999)) <= 480, label + ": real consumer retains its bounded update budget")


func _finish() -> void:
	print("R3_WORLD_NATIVE_GPU_RESULTS %d passed, %d failed; controlled diagnostic only" % [passed, failed])
	print("REFERENCE_R3_WORLD_GPU_PASS" if failed == 0 else "REFERENCE_R3_WORLD_GPU_FAILED")
	quit(0 if failed == 0 else 1)
