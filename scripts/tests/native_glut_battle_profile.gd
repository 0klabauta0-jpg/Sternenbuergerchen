extends "res://scripts/tests/campaign_five_actual_sorties_verifier.gd"
## Native 1x timings on the real B guard encounter, from the normal post-A checkpoint.
var _rows: Array[Dictionary] = []
var _capture_phase := ""
var _frame_receipts: Array[Dictionary] = []
var _profile_view: Node
var _profile_sim: Node
var _profile_base_sim: Node
var _profile_controller: Node
var _profile_rid: RID
var _previous_pre_draw_usec := 0
var _previous_post_draw_usec := 0
var _last_recorded_frame := -1
var _frame_binding_errors := 0
var _poll_timings = preload("res://scripts/core/frame_timing_accumulator.gd").new()


func _run() -> void:
	var private_root := ProjectSettings.globalize_path("res://output/native_glut_maps/").replace("\\", "/").to_lower()
	if not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(private_root):
		_check(false, "Native profile requires private APPDATA beneath output/native_glut_maps")
		quit(1)
		return
	await super._run()


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
	_profile_view = view
	_profile_sim = sim
	_profile_base_sim = _runtime.get("_simulation")
	if _profile_base_sim == sim: _profile_base_sim = null
	_profile_controller = controller
	_profile_rid = rid
	RenderingServer.viewport_set_measure_render_time(rid, true)
	view.call("set_runtime_frame_timing_debug_enabled", true)
	sim.call("set_runtime_tick_budget_debug_enabled", true)
	if _profile_base_sim != null: _profile_base_sim.call("set_runtime_tick_budget_debug_enabled", true)
	_flow.call("set_runtime_frame_timing_debug_enabled", true)
	controller.call("set_mission_visible_frame_timing_debug_enabled", true)
	RenderingServer.frame_pre_draw.connect(_on_profile_frame_pre_draw)
	RenderingServer.frame_post_draw.connect(_on_profile_frame_post_draw)
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
	var go_usec := Time.get_ticks_usec()
	controller.call("set_mission_visible_frame_timing_debug_enabled", true)
	if not _check(bool(controller.call("execute_selected_fireteam_orders")), "Regular GO starts live approach"):
		return
	var go_dispatch_ms := (Time.get_ticks_usec() - go_usec) * 0.001
	print("REGIONAL_GO_DISPATCH ", go_dispatch_ms, " ", controller.call("get_command_commit_timing_debug_snapshot"))
	_capture_phase = "go_to_contact"
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
			var poll_started := Time.get_ticks_usec()
			shot_count = maxi(shot_count, Array(driver.call("get_fire_event_snapshot")).size())
			cleared = PackedStringArray(driver.call("get_mission_scenario_runtime_gate_snapshot").get("completed_step_ids", [])).has("clear_outpost")
			_poll_timings.record_sample(Engine.get_process_frames(), Time.get_ticks_usec() - poll_started)
		_capture_phase = "combat" if shot_count > 0 else "go_to_contact"
		frame += 1
		if cleared:
			settled_frames += 1
			if settled_frames >= 60:
				break
	await RenderingServer.frame_post_draw
	_capture_phase = ""
	RenderingServer.frame_pre_draw.disconnect(_on_profile_frame_pre_draw)
	RenderingServer.frame_post_draw.disconnect(_on_profile_frame_post_draw)
	_check(_frame_binding_errors == 0 and _frame_receipts.is_empty(), "CPU receipts keep exact frame IDs and draw FIFO drains")
	_check(_rows.any(func(row: Dictionary): return row.phase == "combat" and int(row.sim.sample_count) > 1),
		"Native combat records multiple physics ticks rather than only the last one")
	_check(cleared and shot_count > 0, "Real 1x fire exchange clears B guard")
	_check(first_move_ms >= 0.0 and Engine.time_scale == 1.0 and int(registry.call("get_tile_count")) == 512 * 256,
		"First real movement observed at 1x on all 131072 cells")
	var path := "res://output/native_glut_maps/B_battle_profile.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if _check(file != null, "Profile output opens"):
		file.store_string(JSON.stringify({"engine": Engine.get_version_info().string,
			"schema":"native_combat_frame_v2", "cpu_receipt_boundary":"frame_pre_draw",
			"wall_interval":"pre_draw_to_pre_draw; includes previous render and current CPU work",
			"render_timing_binding":"latest_available; engine timestamps update after frame_post_draw",
			"nested_scopes_not_additive":true,"adapter":RenderingServer.get_video_adapter_name(),
			"render_thread_model":ProjectSettings.get_setting("rendering/driver/threads/thread_model",1),
			"private_user_path":ProjectSettings.globalize_path("user://"),
			"map_sha256":FileAccess.get_sha256(map_path),"frame_binding_errors":_frame_binding_errors,
			"renderer": RenderingServer.get_current_rendering_method(), "window": str(root.size),
			"terrain_viewport": str(viewport.size), "scale": Engine.time_scale, "shots": shot_count,
			"first_move_ms": first_move_ms, "go_dispatch_ms": go_dispatch_ms,
			"memory_static_bytes": OS.get_static_memory_usage(), "video_bytes": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED),
			"rows": _rows}))
		# Subclass completion probes read this receipt before coroutine locals retire.
		file.close()
	print("REGIONAL_BATTLE_PROFILE frames=", _rows.size(), " shots=", shot_count, " output=", path)
	RenderingServer.viewport_set_measure_render_time(rid, false)
	view.call("set_runtime_frame_timing_debug_enabled", false)
	sim.call("set_runtime_tick_budget_debug_enabled", false)
	if _profile_base_sim != null: _profile_base_sim.call("set_runtime_tick_budget_debug_enabled", false)
	_flow.call("set_runtime_frame_timing_debug_enabled", false)
	controller.call("set_mission_visible_frame_timing_debug_enabled", false)


func _sample_camera(view: Node, _sim: Node, _rid: RID, center: Vector2i, phase: String, count: int, pan: bool) -> void:
	_capture_phase = phase
	for index in range(count):
		if pan and index % 4 == 0:
			var sweep := index / 4 % 30
			var offset := 15 - absi(15 - sweep)
			view.call("focus_world_position", view.call("grid_to_world_position", center + Vector2i(offset, 0)))
		await RenderingServer.frame_post_draw
	_capture_phase = ""


func _on_profile_frame_pre_draw() -> void:
	if _capture_phase.is_empty():
		_frame_receipts.append({"skip":true,"process_frame":Engine.get_process_frames()})
		return
	var now := Time.get_ticks_usec()
	var frame_id := Engine.get_process_frames()
	var visual: Dictionary = _profile_view.call("get_runtime_frame_work_debug_snapshot", frame_id)
	var sim_frame: Dictionary = _profile_sim.call("get_runtime_frame_budget_debug_snapshot", frame_id)
	var base_frame: Dictionary = _profile_base_sim.call("get_runtime_frame_budget_debug_snapshot", frame_id) if _profile_base_sim != null else {}
	var meta_frame: Dictionary = _flow.call("get_runtime_frame_timing_debug_snapshot", frame_id)
	var binding_ok := bool(visual.enabled) and int(visual.process_frame) == frame_id and int(visual.process.process_frame) == frame_id and bool(visual.process.has_sample) and bool(sim_frame.enabled) and int(sim_frame.process_frame) == frame_id and bool(meta_frame.enabled) and int(meta_frame.process_frame) == frame_id and bool(meta_frame.has_sample)
	if not base_frame.is_empty(): binding_ok = binding_ok and bool(base_frame.enabled) and int(base_frame.process_frame) == frame_id
	if not binding_ok: _frame_binding_errors += 1
	_frame_receipts.append({"phase":_capture_phase,"process_frame":frame_id,"cpu_frame_binding_ok":binding_ok,
		"wall_ms":float(now - _previous_pre_draw_usec) * 0.001 if _previous_pre_draw_usec > 0 else null,
		"view":visual,"sim":sim_frame,"base_sim":base_frame,"meta":meta_frame,
		"test_polls":_poll_timings.get_snapshot(frame_id),
		# The legacy controller receipt has no frame stamp. Preserve it separately
		# as latest_available; never add it to same-frame totals.
		"controller_latest_available":_profile_controller.call("get_mission_visible_frame_timing_debug_snapshot"),
		"sim_script_ms":float(sim_frame.sum_usec) * 0.001,
		"sim_commands_ms":float(sim_frame.scopes_sum_usec.get("command_apply_usec",0)) * 0.001,
		"view_script_ms":float(visual.process.sum_usec) * 0.001,
		"chunks_built":int(_profile_view.get("_regional_chunk_build_count")),
		"sampler_pre_draw_usec":Time.get_ticks_usec() - now})
	_previous_pre_draw_usec = now
	if _frame_receipts.size() > 8: _frame_binding_errors += 1


func _on_profile_frame_post_draw() -> void:
	if _frame_receipts.is_empty(): return
	var started := Time.get_ticks_usec()
	var row: Dictionary = _frame_receipts.pop_front()
	if bool(row.get("skip",false)): return
	if int(row.process_frame) <= _last_recorded_frame: _frame_binding_errors += 1
	_last_recorded_frame = int(row.process_frame)
	row["post_draw_callback_process_frame"] = Engine.get_process_frames()
	row["post_draw_callback_interval_ms"] = float(started - _previous_post_draw_usec) * 0.001 if _previous_post_draw_usec > 0 else null
	row["render_cpu_ms"] = RenderingServer.viewport_get_measured_render_time_cpu(_profile_rid)
	row["render_gpu_ms"] = RenderingServer.viewport_get_measured_render_time_gpu(_profile_rid)
	row["draw_calls_latest_available"] = RenderingServer.viewport_get_render_info(_profile_rid, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE, RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)
	row["sampler_post_draw_usec"] = Time.get_ticks_usec() - started
	_previous_post_draw_usec = started
	_rows.append(row)
