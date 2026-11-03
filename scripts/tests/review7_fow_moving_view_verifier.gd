extends "res://scripts/tests/review7_fow_verifier.gd"

const REAL_VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MAP_DATA = preload("res://scripts/terrain/terrain_map_data.gd")

var _gpu_readback_available: bool = false


func _run() -> void:
	await _characterize_multimesh_readback()
	if OS.get_environment("SB_REVIEW7_REQUIRE_GPU_READBACK") == "1":
		_check(_gpu_readback_available, "Required native renderer supports actual MultiMesh color and transform readback")
	await _moving_real_view_case(128, 512)
	await _moving_real_view_case(256, 512)
	# A supported larger terrain slice publishes the first revision while the
	# actual streamed overlay is still being built. Deltas must retain its work.
	await _moving_real_view_case(128, 2048)
	await _skipped_revision_rebuild_case()
	print("REVIEW7_FOW_MOVING_VIEW_RESULT %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)


func _moving_real_view_case(side: int, work_budget: int) -> void:
	var f: Dictionary = _fixture(side)
	var view: Node = REAL_VIEW.new()
	f.holder.add_child(view)
	view.set_process(false)
	var map_data = MAP_DATA.create_empty("review7_walking_real_view_%d" % side, Vector2i(side, side), Vector2.ZERO, 64.0, 32.0, 3)
	view.call("configure_from_map", map_data)
	view.call("set_unit_nodes", Array(f.setup.get("_fog_unit_nodes")))
	f.setup.set("_terrain_3d_view", view)
	f.setup.fog_of_war_work_budget_tiles = work_budget
	# Finish ordinary deferred layout/streaming setup before measuring one fixed
	# map/camera context. Neither camera nor render caches are patched here.
	await process_frame
	await process_frame
	var label: String = "%d real moving view budget%d" % [side, work_budget]
	var rendered_tile_ids: PackedStringArray = PackedStringArray(view.get("_fow_overlay_render_tile_ids"))
	_check(bool(view.get("_visual_streaming_active")) and rendered_tile_ids.size() > 512 and rendered_tile_ids.size() < side * side, label + " uses the normal streamed map subset larger than one overlay slice")
	var full_rebuilds_before: int = int(view.get("_fow_overlay_full_rebuild_count"))
	f.setup.call("_sync_fog_of_war_visual_state", true)
	var initial_mesh_id: int = _mesh_id(view)
	_check(initial_mesh_id != 0 and bool(view.get("_fow_overlay_full_rebuild_pending")), label + " starts one actual FoW MultiMesh behind its initial safety cover")
	var mesh_stable: bool = true
	var first_commit: int = -1
	var first_commit_during_overlay: bool = false
	var first_visible_overlay: int = -1
	var max_terrain_revision: int = 0
	var frames: int = ceili(float(side * side) / float(work_budget)) + 100
	for frame in range(frames):
		f.observer.position += Vector2(80.0 / 60.0, 0.0)
		# Execute both normal consumers in normal frame order. The terrain job
		# keeps walking throughout; rendering is never replaced with VisualSink.
		f.setup.call("_process", 1.0 / 60.0)
		var terrain_revision: int = int(f.fog.build_team_state_snapshot("team_alpha").get("visibility_revision", 0))
		if first_commit == -1 and terrain_revision > 0:
			first_commit = frame
			first_commit_during_overlay = bool(view.get("_fow_overlay_full_rebuild_pending"))
		view.call("_process", 1.0 / 60.0)
		mesh_stable = mesh_stable and _mesh_id(view) == initial_mesh_id
		max_terrain_revision = maxi(max_terrain_revision, terrain_revision)
		if first_visible_overlay == -1 and terrain_revision > 0 and not bool(view.get("_fow_overlay_full_rebuild_pending")) and _safety_id(view) == 0 and int(view.get("_fow_overlay_visibility_revision")) == terrain_revision and int(view.get("_fow_visible_tile_count")) > 0:
			first_visible_overlay = frame
		await process_frame
	_check(first_commit >= 0 and max_terrain_revision > 1, label + " publishes initial and follow-up terrain revisions without stopping the observer")
	_check(first_visible_overlay >= 0, label + " completes a real visible revision and removes the safety blackout while the observer is still walking")
	_check(mesh_stable, label + " retains the exact MultiMesh instance throughout one map/mode/team/terrain context")
	_check(int(view.get("_fow_overlay_full_rebuild_count")) == full_rebuilds_before + 1, label + " performs exactly one full overlay build despite ongoing terrain revisions")
	if work_budget == 2048:
		_check(first_commit_during_overlay, label + " exercises a sequential terrain delta before the initial overlay finishes")
	# Stop by ceasing normal runtime movement, then let both real consumers
	# settle naturally. No force refresh, dirty mutation or direct tile setter.
	var settled: bool = false
	for _frame in range(180):
		f.setup.call("_process", 1.0 / 60.0)
		view.call("_process", 1.0 / 60.0)
		var latest_signature: String = f.setup.call("_build_fog_runtime_signature", "unexplored_blackout")
		if String(f.setup.get("_fog_requested_runtime_signature")).is_empty() and String(f.setup.get("_fog_runtime_signature")) == latest_signature and not bool(view.get("_fow_overlay_full_rebuild_pending")):
			settled = true
			break
		await process_frame
	_check(settled and _safety_id(view) == 0, label + " settles the latest stopped position without a remaining safety blackout")
	_check(_mesh_id(view) == initial_mesh_id and int(view.get("_fow_overlay_full_rebuild_count")) == full_rebuilds_before + 1, label + " settling also retains the original completed overlay")
	var state: Dictionary = Dictionary(f.fog.build_team_state_snapshot("team_alpha"))
	_check(int(view.get("_fow_overlay_visibility_revision")) == int(state.get("visibility_revision", 0)), label + " renders the final committed terrain revision")
	_check(_rendered_tile_states_match(view, state), label + " every rendered tile state and supported overlay readback match final authoritative FoW knowledge")
	var capture: Dictionary = await _capture_native_view(view, "walking_%d_budget%d" % [side, work_budget])
	print("REVIEW7_FOW_MOVING_VIEW_WORKLOAD ", JSON.stringify({"side": side, "work_budget": work_budget, "walking_frames": frames, "rendered_tiles": rendered_tile_ids.size(), "first_terrain_commit_frame": first_commit, "first_visible_overlay_frame": first_visible_overlay, "first_commit_during_overlay": first_commit_during_overlay, "revisions_while_walking": max_terrain_revision, "full_overlay_builds": int(view.get("_fow_overlay_full_rebuild_count")) - full_rebuilds_before, "mesh_stable": mesh_stable, "gpu_readback_available": _gpu_readback_available, "capture": capture, "headless_is_not_pixel_capture": true}))
	f.holder.free()
	await process_frame


func _skipped_revision_rebuild_case() -> void:
	var f: Dictionary = _fixture(32)
	var view: Node = REAL_VIEW.new()
	f.holder.add_child(view)
	view.set_process(false)
	view.call("configure_from_map", MAP_DATA.create_empty("review7_skipped_fow_view", Vector2i(32, 32), Vector2.ZERO, 64.0, 32.0, 3))
	f.setup.set("_terrain_3d_view", view)
	f.setup.call("_sync_fog_of_war_visual_state", true)
	_drain(f)
	for _frame in range(8):
		view.call("_process", 1.0 / 60.0)
		await process_frame
	var before_mesh: int = _mesh_id(view)
	var before_revision: int = int(view.get("_fow_overlay_visibility_revision"))
	var before_delta_applies: int = int(view.get("_fow_overlay_delta_apply_count"))
	_check(before_mesh != 0 and before_revision == 1 and not bool(view.get("_fow_overlay_full_rebuild_pending")), "Skipped-revision fixture starts from a complete real revision-one overlay")
	# Produce two genuine authoritative updates. The first removes origin-side
	# visibility; the second's last-only delta cannot describe that first loss.
	# Deliberately deliver only the second publication to the view boundary.
	f.observer.position += Vector2(192.0, 0.0)
	f.fog.update_tile_visibility_for_team("team_alpha", [f.observer], f.registry, LOS.new(), 160.0)
	f.observer.position += Vector2(192.0, 0.0)
	f.fog.update_tile_visibility_for_team("team_alpha", [f.observer], f.registry, LOS.new(), 160.0)
	var latest_state: Dictionary = Dictionary(f.fog.build_team_state_snapshot("team_alpha"))
	_check(int(latest_state.get("visibility_revision", 0)) == before_revision + 2, "Two real FoW updates create an intentionally skipped visual revision")
	view.call("set_fog_of_war_state", latest_state)
	_check(_mesh_id(view) != before_mesh and bool(view.get("_fow_overlay_full_rebuild_pending")), "A revision gap replaces the old terrain mesh through a full overlay rebuild")
	_check(int(view.get("_fow_overlay_delta_apply_count")) == before_delta_applies, "A revision gap never applies the incomplete last-only visibility delta")
	for _frame in range(8):
		view.call("_process", 1.0 / 60.0)
		await process_frame
	_check(not bool(view.get("_fow_overlay_full_rebuild_pending")) and _safety_id(view) == 0, "Revision-gap full rebuild finishes and removes its safety blackout")
	_check(_rendered_tile_states_match(view, latest_state), "Revision-gap rebuild renders all latest visible/explored tiles including the skipped delta's changes")
	var oracle = FOW.new()
	oracle.set_mode_for_team("team_alpha", "unexplored_blackout")
	oracle.update_tile_visibility_for_team("team_alpha", [f.observer], f.registry, LOS.new(), 160.0)
	_check(_visible_tiles(f.fog) == _visible_tiles(oracle), "Revision-gap final visibility equals an independent current-position full oracle")
	f.holder.free()
	await process_frame


func _mesh_id(view: Node) -> int:
	var mesh: Node = view.get("_fow_overlay_multimesh_instance") as Node
	return mesh.get_instance_id() if mesh != null and is_instance_valid(mesh) else 0


func _safety_id(view: Node) -> int:
	var safety: Node = view.get("_fow_overlay_safety_cover") as Node
	return safety.get_instance_id() if safety != null and is_instance_valid(safety) else 0


func _rendered_tile_states_match(view: Node, state: Dictionary) -> bool:
	var knowledge: Dictionary = Dictionary(state.get("terrain_knowledge", {}))
	var visible: PackedStringArray = PackedStringArray(knowledge.get("visible_tile_ids", []))
	var explored: PackedStringArray = PackedStringArray(knowledge.get("explored_tile_ids", []))
	var tile_states: Dictionary = Dictionary(view.get("_fow_overlay_tile_states_by_id"))
	var rendered_tile_ids: PackedStringArray = PackedStringArray(view.get("_fow_overlay_render_tile_ids"))
	var slots: Dictionary = Dictionary(view.get("_fow_overlay_slot_by_tile_id"))
	var mesh: MultiMesh = view.get("_fow_overlay_multimesh") as MultiMesh
	if rendered_tile_ids.is_empty() or tile_states.size() != rendered_tile_ids.size() or slots.size() != rendered_tile_ids.size() or mesh == null:
		print("REVIEW7_FOW_VIEW_TILE_MISMATCH ", JSON.stringify({"reason": "incomplete_overlay_state", "rendered_tiles": rendered_tile_ids.size(), "tile_states": tile_states.size(), "mesh_present": mesh != null, "renderer": _renderer_facts()}))
		return false
	var seen_slots: Dictionary = {}
	for tile_id in rendered_tile_ids:
		var expected: String = "visible" if visible.has(tile_id) else ("explored" if explored.has(tile_id) else "unknown")
		if String(tile_states.get(tile_id, "")) != expected:
			_report_first_tile_mismatch(tile_id, expected, String(tile_states.get(tile_id, "")), mesh, int(slots.get(tile_id, -1)), "tile_state")
			return false
		if not slots.has(tile_id):
			_report_first_tile_mismatch(tile_id, expected, String(tile_states.get(tile_id, "")), mesh, -1, "missing_slot")
			return false
		var slot: int = int(slots[tile_id])
		if slot < 0 or slot >= mesh.instance_count or seen_slots.has(slot):
			_report_first_tile_mismatch(tile_id, expected, String(tile_states.get(tile_id, "")), mesh, -1, "invalid_or_duplicate_slot")
			return false
		seen_slots[slot] = true
		# Dummy RenderingServer cannot round-trip even a standalone MultiMesh.
		# CPU tile-state and exact one-to-one slot coverage remain mandatory;
		# the same gate requires these buffer checks on a capable native backend.
		if not _gpu_readback_available:
			continue
		var color: Color = mesh.get_instance_color(int(slots[tile_id]))
		if expected == "visible" and not is_zero_approx(color.a):
			_report_first_tile_mismatch(tile_id, expected, String(tile_states.get(tile_id, "")), mesh, int(slots[tile_id]), "visible_alpha")
			return false
		if expected != "visible" and color.a <= 0.0:
			_report_first_tile_mismatch(tile_id, expected, String(tile_states.get(tile_id, "")), mesh, int(slots[tile_id]), "covered_alpha")
			return false
	return true


func _report_first_tile_mismatch(tile_id: String, expected: String, actual: String, mesh: MultiMesh, slot: int, reason: String) -> void:
	var facts: Dictionary = {"reason": reason, "tile_id": tile_id, "slot": slot, "expected_state": expected, "actual_state": actual, "renderer": _renderer_facts()}
	if slot >= 0:
		var color: Color = mesh.get_instance_color(slot)
		var transform: Transform3D = mesh.get_instance_transform(slot)
		facts["readback_color"] = [color.r, color.g, color.b, color.a]
		facts["readback_transform_origin"] = [transform.origin.x, transform.origin.y, transform.origin.z]
	print("REVIEW7_FOW_VIEW_TILE_MISMATCH ", JSON.stringify(facts))


func _characterize_multimesh_readback() -> void:
	# Characterize the current backend independently of FoW and the view. Keep
	# the product-state and alpha assertions above intact until this is known.
	var mesh := MultiMesh.new()
	mesh.transform_format = MultiMesh.TRANSFORM_3D
	mesh.use_colors = true
	mesh.mesh = BoxMesh.new()
	mesh.instance_count = 1
	var expected_color := Color(0.25, 0.5, 0.75, 0.0)
	var expected_transform := Transform3D(Basis(), Vector3(5.0, 7.0, 11.0))
	mesh.set_instance_color(0, expected_color)
	mesh.set_instance_transform(0, expected_transform)
	await process_frame
	var actual_color: Color = mesh.get_instance_color(0)
	var actual_transform: Transform3D = mesh.get_instance_transform(0)
	_gpu_readback_available = actual_color.is_equal_approx(expected_color) and actual_transform.is_equal_approx(expected_transform)
	print("REVIEW7_MULTIMESH_READBACK_CHARACTERIZATION ", JSON.stringify({"renderer": _renderer_facts(), "expected_color": [expected_color.r, expected_color.g, expected_color.b, expected_color.a], "actual_color": [actual_color.r, actual_color.g, actual_color.b, actual_color.a], "color_roundtrip_matches": actual_color.is_equal_approx(expected_color), "expected_transform_origin": [5.0, 7.0, 11.0], "actual_transform_origin": [actual_transform.origin.x, actual_transform.origin.y, actual_transform.origin.z], "transform_roundtrip_matches": actual_transform.is_equal_approx(expected_transform), "gpu_readback_available": _gpu_readback_available, "gpu_readback_required": OS.get_environment("SB_REVIEW7_REQUIRE_GPU_READBACK") == "1"}))


func _capture_native_view(view: Node, file_name: String) -> Dictionary:
	if DisplayServer.get_name().to_lower() == "headless":
		return {"captured": false, "reason": "headless_has_no_pixel_capture"}
	var viewport: SubViewport = view.get("_subviewport") as SubViewport
	if viewport == null:
		return {"captured": false, "reason": "subviewport_missing"}
	view.call("_process", 1.0 / 60.0)
	await process_frame
	await RenderingServer.frame_post_draw
	var captured_image: Image = viewport.get_texture().get_image()
	if captured_image == null or captured_image.is_empty():
		return {"captured": false, "reason": "empty_viewport_image"}
	var output_directory: String = "user://review7_rendered"
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_directory))
	if directory_error != OK:
		return {"captured": false, "reason": "capture_directory_failed", "error": directory_error}
	var output_path: String = "%s/%s.png" % [output_directory, file_name]
	var save_error: Error = captured_image.save_png(output_path)
	return {"captured": save_error == OK, "path": output_path, "absolute_path": ProjectSettings.globalize_path(output_path), "size": [captured_image.get_width(), captured_image.get_height()], "error": save_error}


func _renderer_facts() -> Dictionary:
	return {"display": DisplayServer.get_name(), "method": RenderingServer.get_current_rendering_method(), "driver": RenderingServer.get_current_rendering_driver_name(), "adapter": RenderingServer.get_video_adapter_name()}
