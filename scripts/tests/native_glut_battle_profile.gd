extends "res://scripts/tests/campaign_five_actual_sorties_verifier.gd"
## Native 1x timings on the real B guard encounter, from the normal post-A checkpoint.
var _rows: Array[Dictionary] = []


func _remaining_missions() -> void:
	if not _check(DisplayServer.get_name() != "headless", "Native renderer is active"):
		return
	var fuel: float = float(_supply().fuel_by_craft_id[_craft_id])
	if fuel < 100.0:
		var refuel: Dictionary = _runtime.call("request_operation", "refuel", {"craft_id": _craft_id, "amount": 100.0 - fuel})
		if not _check(bool(refuel.get("ok", false)), "Actual ship refuels at home"):
			return
	for request in [["accept_job", {"job_id": "outpost_recovery"}],
			["select_destination", {"location_id": "trade_outpost", "job_id": "outpost_recovery"}]]:
		var result: Dictionary = _runtime.call("request_operation", request[0], request[1])
		if not _check(bool(result.get("ok", false)), "Regular " + String(request[0])):
			return
	var map_path := "res://maps/trade_outpost.json"
	if not await _launch_and_land("outpost_recovery", map_path):
		return
	Engine.time_scale = 1.0
	var mission: Node = _flow.get("_active_mission")
	var view: Node = mission.get_node("Primary3DView")
	var sim: Node = mission.get_node("SimulationRoot")
	var driver: Node = mission.get_node("CombatLoopDriver")
	var controller: Node = mission.get_node("TacticalController")
	var viewport: SubViewport = view.get("_subviewport")
	var rid := viewport.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	view.call("set_runtime_frame_timing_debug_enabled", true)
	sim.call("set_runtime_tick_budget_debug_enabled", true)
	view.call("_request_viewport_redraw", true, 120000)
	var registry: Node = mission.get_node("TerrainRegistry")
	var map = MAP.load_from_file(map_path)
	var goal: Vector2 = map.get_marker_position("spawn_enemy_defense")
	var center: Vector2i = registry.call("world_to_grid", goal)
	view.call("focus_world_position", goal)
	for index in range(180):
		await process_frame
		if index >= 12 and view.get("_regional_pending_chunks").is_empty() and not view.get("_visual_streaming_refresh_queued"):
			break
	await _sample_camera(view, sim, rid, center, "still", 120, false)
	await _sample_camera(view, sim, rid, center, "pan_1", 240, true)
	await _sample_camera(view, sim, rid, center, "pan_2", 240, true)
	view.call("focus_world_position", goal)
	controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
	controller.call("set_selected_fireteams_tactical_stance", "aggressive")
	controller.call("set_selected_fireteams_fire_rule", "free")
	controller.call("_create_waypoints_for_selected_fireteams", goal, true)
	var lead = mission.get_node("UnitRegistry").call("get_unit", _crew_ids[0])
	var initial_position: Vector2 = lead.global_position
	var previous := Time.get_ticks_usec()
	var go_usec := previous
	controller.call("set_mission_visible_frame_timing_debug_enabled", true)
	if not _check(bool(controller.call("execute_selected_fireteam_orders")), "Regular GO starts live approach"):
		return
	var go_dispatch_ms := (Time.get_ticks_usec() - go_usec) * 0.001
	print("REGIONAL_GO_DISPATCH ", go_dispatch_ms, " ", controller.call("get_command_commit_timing_debug_snapshot"))
	controller.call("set_mission_visible_frame_timing_debug_enabled", false)
	var first_move_ms := -1.0
	var trace_navigation := OS.get_cmdline_user_args().has("regional-nav-trace")
	var shot_count := 0
	var frame := 0
	var settled_frames := 0
	var deadline := Time.get_ticks_msec() + 140000
	var cleared := false
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if first_move_ms < 0.0 and lead.global_position.distance_to(initial_position) > 1.0:
			first_move_ms = (Time.get_ticks_usec() - go_usec) * 0.001
			print("REGIONAL_FIRST_GO_MOVEMENT_MS ", first_move_ms)
		if trace_navigation and frame % 90 == 0:
			var queued: Array = []
			for command: Dictionary in sim.command_queue:
				var search: Variant = command.get("_regional_navigation_search")
				queued.append([command.get("unit_id"), command.get("command_token"), command.get("target_position"),
					search.expanded_count if search != null else -1, Array(command.get("path", [])).size()])
			print("REGIONAL_NAV_TRACE ", frame, " ", lead.global_position, " goal=", goal, " ", queued)
		if frame % 5 == 0:
			shot_count = maxi(shot_count, Array(driver.call("get_fire_event_snapshot")).size())
			cleared = PackedStringArray(driver.call("get_mission_scenario_runtime_gate_snapshot").get("completed_step_ids", [])).has("clear_outpost")
		var phase := "combat" if shot_count > 0 else "go_to_contact"
		previous = _record_frame(view, sim, rid, phase, previous)
		frame += 1
		if cleared:
			settled_frames += 1
			if settled_frames >= 60:
				break
	_check(cleared and shot_count > 0, "Real 1x fire exchange clears B guard")
	_check(first_move_ms >= 0.0 and Engine.time_scale == 1.0 and int(registry.call("get_tile_count")) == 512 * 256,
		"First real movement observed at 1x on all 131072 cells")
	var path := "res://output/native_glut_maps/B_battle_profile.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if _check(file != null, "Profile output opens"):
		file.store_string(JSON.stringify({"engine": Engine.get_version_info().string,
			"renderer": RenderingServer.get_current_rendering_method(), "window": str(root.size),
			"terrain_viewport": str(viewport.size), "scale": Engine.time_scale, "shots": shot_count,
			"first_move_ms": first_move_ms, "go_dispatch_ms": go_dispatch_ms,
			"memory_static_bytes": OS.get_static_memory_usage(), "video_bytes": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED),
			"rows": _rows}))
	print("REGIONAL_BATTLE_PROFILE frames=", _rows.size(), " shots=", shot_count, " output=", path)
	RenderingServer.viewport_set_measure_render_time(rid, false)
	view.call("set_runtime_frame_timing_debug_enabled", false)
	sim.call("set_runtime_tick_budget_debug_enabled", false)


func _sample_camera(view: Node, sim: Node, rid: RID, center: Vector2i, phase: String, count: int, pan: bool) -> void:
	var previous := Time.get_ticks_usec()
	for index in range(count):
		if pan and index % 4 == 0:
			var sweep := index / 4 % 30
			var offset := 15 - absi(15 - sweep)
			view.call("focus_world_position", view.call("grid_to_world_position", center + Vector2i(offset, 0)))
		await process_frame
		previous = _record_frame(view, sim, rid, phase, previous)


func _record_frame(view: Node, sim: Node, rid: RID, phase: String, previous: int) -> int:
	var now := Time.get_ticks_usec()
	var visual: Dictionary = view.call("get_runtime_frame_timing_debug_snapshot")
	var tick: Dictionary = sim.call("get_runtime_tick_budget_debug_snapshot")
	var scopes: Dictionary = tick.get("scopes_usec", {})
	_rows.append({"phase": phase, "wall_ms": float(now - previous) * 0.001,
		"render_cpu_ms": RenderingServer.viewport_get_measured_render_time_cpu(rid),
		"render_gpu_ms": RenderingServer.viewport_get_measured_render_time_gpu(rid),
		"draw_calls": RenderingServer.viewport_get_render_info(rid, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE, RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME),
		"view_script_ms": float(visual.get("total_usec", 0)) * 0.001,
		"sim_tick": int(tick.get("tick", 0)), "sim_script_ms": float(tick.get("total_tick_usec", 0)) * 0.001,
		"sim_commands_ms": float(scopes.get("command_apply_usec", 0)) * 0.001,
		"actors": int(tick.get("registered_unit_count", 0)), "chunks_built": int(view.get("_regional_chunk_build_count"))})
	return now
