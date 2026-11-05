extends "res://scripts/tests/ui_zielbild_normal_capture.gd"
## Actual fullscreen normal route; diagnostic reads and ordinary Move/GO only.

var _profile_points: Dictionary = {}
var _profile_ran := false
var _profile_screen_size := Vector2i.ZERO
var _profile_simulation: Node
var _profile_combat: Node
var _profile_start_usec := 0
var _profile_physics_rows: Array = []
var _profile_last_physics_tick := -1


func _initialize() -> void:
	# The inherited exact QA namespace guard runs before any scene is loaded.
	_profile_screen_size = DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
	if DisplayServer.get_name() != "headless":
		root.mode = Window.MODE_FULLSCREEN
		root.content_scale_size = _profile_screen_size
	super._initialize()


func _argument(key: String, fallback: String = "") -> String:
	if key == "--ui-size" and _profile_screen_size != Vector2i.ZERO:
		return "%dx%d" % [_profile_screen_size.x, _profile_screen_size.y]
	return super._argument(key, fallback)


func _authored_mission_points(map_path: String, mission: Node) -> Dictionary:
	_profile_points = super._authored_mission_points(map_path, mission)
	return _profile_points


func _capture(id: String, view: Node = null, settle_frames: int = 8) -> void:
	if DisplayServer.get_name() != "headless":
		root.mode = Window.MODE_FULLSCREEN
	if id == "06_go_movement" and not _profile_ran and view != null:
		_profile_ran = true
		await _profile_normal_movement(view)
	# Parent captures retain their usual camera route, after the measured window.
	await super._capture(id, view, settle_frames)


func _display_facts() -> Dictionary:
	var screen := DisplayServer.window_get_current_screen()
	return {
		"window_mode": root.mode,
		"display_server_window_mode": DisplayServer.window_get_mode(),
		"screen_index": screen,
		"screen_size": str(DisplayServer.screen_get_size(screen)),
		"screen_usable_rect": str(DisplayServer.screen_get_usable_rect(screen)),
		"screen_refresh_rate": DisplayServer.screen_get_refresh_rate(screen),
		"window_size": str(DisplayServer.window_get_size()),
		"root_size": str(root.size),
		"viewport_size": str(root.get_visible_rect().size),
		"content_scale_size": str(root.content_scale_size),
		"window_has_focus": root.has_focus(),
		"time_scale": Engine.time_scale,
		"physics_ticks_per_second": Engine.physics_ticks_per_second,
		"max_physics_steps_per_frame": Engine.max_physics_steps_per_frame,
		"vsync_mode": DisplayServer.window_get_vsync_mode(),
		"display": DisplayServer.get_name(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"rendering_driver": RenderingServer.get_current_rendering_driver_name(),
		"cpu": OS.get_processor_name(),
		"gpu": RenderingServer.get_video_adapter_name(),
	}


func _profile_normal_movement(view: Node) -> void:
	var mission := view.get_parent()
	var controller := mission.get_node_or_null("TacticalController")
	var simulation := mission.get_node_or_null("SimulationRoot")
	var combat := mission.get_node_or_null("CombatLoopDriver")
	var setup := mission.get_node_or_null("MissionSetup")
	if not _check(DisplayServer.get_name() != "headless", "Performance measurement uses a native renderer"):
		return
	if not _check(controller != null and simulation != null and combat != null, "Performance diagnostics use the normal runtime owners"):
		return
	_check(root.mode == Window.MODE_FULLSCREEN or root.mode == Window.MODE_EXCLUSIVE_FULLSCREEN, "Measured window is genuinely fullscreen")
	_check(DisplayServer.window_get_size() == _profile_screen_size, "Fullscreen covers the active display resolution")
	_check(is_equal_approx(Engine.time_scale, 1.0), "Measured normal gameplay remains at 1x")
	view.call("set_runtime_frame_timing_debug_enabled", true)
	controller.call("set_mission_visible_frame_timing_debug_enabled", true)
	simulation.call("set_runtime_tick_budget_debug_enabled", true)
	simulation.call("set_navigation_debug_enabled", true)
	combat.call("set_combat_tick_budget_debug_enabled", true)
	if setup != null and setup.has_method("set_fog_frame_timing_debug_enabled"):
		setup.call("set_fog_frame_timing_debug_enabled", true)
	if current_scene != null and current_scene.has_method("set_transport_refresh_timing_debug_enabled"):
		current_scene.call("set_transport_refresh_timing_debug_enabled", true)
	var warmup_end := Time.get_ticks_usec() + 3000000
	while Time.get_ticks_usec() < warmup_end:
		await process_frame
	var duration_seconds := clampf(float(_argument("--profile-seconds", "90")), 5.0, 180.0)
	var start_usec := Time.get_ticks_usec()
	var previous_usec := start_usec
	var next_command_usec := start_usec + 12000000
	var next_progress_usec := start_usec + 10000000
	var destination_index := 0
	var rows: Array = []
	var actions: Array = []
	var display_samples: Array = [_display_facts()]
	var before_positions := _positions(mission, Array(_planning_snapshot(controller).get("deployed_unit_ids", [])))
	var start_tick := int(simulation.call("get_tick"))
	var previous_tick := start_tick
	var before_camera := _camera_facts(view)
	_profile_simulation = simulation
	_profile_combat = combat
	_profile_start_usec = start_usec
	_profile_physics_rows.clear()
	_profile_last_physics_tick = -1
	physics_frame.connect(_sample_completed_physics_tick)
	print("PLAYTEST_PERF_START ", JSON.stringify({"seconds": duration_seconds, "display": display_samples[0], "tick": start_tick}))
	while Time.get_ticks_usec() - start_usec < roundi(duration_seconds * 1000000.0):
		await process_frame
		var now_usec := Time.get_ticks_usec()
		var probe_started_usec := now_usec
		var sim := _snapshot(simulation, "get_runtime_tick_budget_debug_snapshot")
		var terrain := _snapshot(view, "get_runtime_frame_timing_debug_snapshot")
		var hud := _snapshot(controller, "get_mission_visible_frame_timing_debug_snapshot")
		var combat_state := _snapshot(combat, "get_combat_tick_budget_debug_snapshot")
		var current_tick := int(sim.get("tick", previous_tick))
		var navigation: Dictionary = sim.get("navigation", {})
		rows.append({
			"elapsed_usec": now_usec - start_usec,
			"frame_usec": now_usec - previous_usec,
			"tick": current_tick,
			"ticks_since_previous_frame": current_tick - previous_tick,
			"simulation_usec": sim.get("total_tick_usec", 0),
			"simulation_scopes_usec": sim.get("scopes_usec", {}),
			"command_count": sim.get("command_count", 0),
			"command_queue": sim.get("command_queue_after_tick", 0),
			"effect_queue": sim.get("effect_queue_after_tick", 0),
			"unit_count": sim.get("registered_unit_count", 0),
			"command_type_usec": sim.get("command_type_usec", {}),
			"nav_pending": navigation.get("pending_query_count", 0),
			"nav_delayed": navigation.get("delayed_this_tick", 0),
			"nav_new_queries": navigation.get("new_path_queries_this_tick", 0),
			"nav_last_queries": navigation.get("last_queries", []),
			"terrain_usec": terrain.get("total_usec", 0),
			"terrain_scopes_usec": terrain.get("scopes_usec", {}),
			"terrain_conditional_scopes_usec": terrain.get("conditional_scopes_usec", {}),
			"terrain_counters": terrain.get("counters", {}),
			"controller_usec": hud.get("total_usec", 0),
			"controller_scopes_usec": hud.get("scopes_usec", {}),
			"hud_included_ui_refresh": hud.get("included_ui_refresh", false),
			"ui_refresh": _snapshot(controller, "get_mission_ui_refresh_timing_debug_snapshot"),
			"runtime_surface": _snapshot(controller, "get_mission_runtime_surface_timing_debug_snapshot"),
			"security_refresh": _snapshot(controller, "get_fireteam_security_refresh_timing_debug_snapshot"),
			"fog_owner": _snapshot(setup, "get_fog_frame_timing_debug_snapshot"),
			"meta_transport": _snapshot(current_scene, "get_transport_refresh_timing_debug_snapshot"),
			"combat_usec": combat_state.get("total_tick_usec", 0),
			"combat_scopes_usec": combat_state.get("scopes_usec", {}),
			"engine_process_usec": roundi(Performance.get_monitor(Performance.TIME_PROCESS) * 1000000.0),
			"engine_physics_usec": roundi(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000000.0),
			"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"probe_usec": Time.get_ticks_usec() - probe_started_usec,
		})
		previous_usec = now_usec
		previous_tick = current_tick
		if now_usec >= next_command_usec and not _profile_points.is_empty():
			var target: Vector2 = _profile_points["lz" if destination_index % 2 == 0 else "move"]
			var move_started_usec := Time.get_ticks_usec()
			var accepted := bool(controller.call("issue_right_click_command_for_test", target, "move", false))
			var move_usec := Time.get_ticks_usec() - move_started_usec
			var move_ui := _snapshot(controller, "get_mission_ui_refresh_timing_debug_snapshot")
			var move_surfaces := _snapshot(controller, "get_mission_runtime_surface_timing_debug_snapshot")
			var go_started_usec := Time.get_ticks_usec()
			var executed := bool(controller.call("execute_selected_fireteam_orders")) if accepted else false
			var go_usec := Time.get_ticks_usec() - go_started_usec
			actions.append({"elapsed_usec": now_usec - start_usec, "target": str(target), "move_accepted": accepted, "go_accepted": executed, "move_usec": move_usec, "go_usec": go_usec, "move_ui": move_ui, "move_surfaces": move_surfaces, "go_ui": _snapshot(controller, "get_mission_ui_refresh_timing_debug_snapshot"), "go_surfaces": _snapshot(controller, "get_mission_runtime_surface_timing_debug_snapshot"), "meta_presentation": _snapshot(current_scene, "get_meta_presentation_debug_snapshot")})
			destination_index += 1
			next_command_usec += 12000000
		if now_usec >= next_progress_usec:
			display_samples.append(_display_facts())
			print("PLAYTEST_PERF_PROGRESS ", JSON.stringify({"elapsed_seconds": float(now_usec - start_usec) / 1000000.0, "frames": rows.size(), "tick": current_tick, "nav_pending": navigation.get("pending_query_count", 0), "fog_owner": _snapshot(setup, "get_fog_frame_timing_debug_snapshot"), "meta_transport": _snapshot(current_scene, "get_transport_refresh_timing_debug_snapshot")}))
			next_progress_usec += 10000000
	var elapsed_usec := Time.get_ticks_usec() - start_usec
	_sample_completed_physics_tick()
	physics_frame.disconnect(_sample_completed_physics_tick)
	_profile_simulation = null
	_profile_combat = null
	var summary := _profile_summary(rows)
	summary["duration_usec"] = elapsed_usec
	summary["simulation_ticks"] = int(simulation.call("get_tick")) - start_tick
	summary["simulation_seconds_per_wall_second"] = float(summary["simulation_ticks"]) / float(Engine.physics_ticks_per_second) / (float(elapsed_usec) / 1000000.0)
	var report := {
		"schema": "sternenbuergerchen.fullscreen_normal_performance.v1",
		"engine": Engine.get_version_info(),
		"display_samples": display_samples,
		"summary": summary,
		"frames": rows,
		"physics_ticks": _profile_physics_rows,
		"actions": actions,
		"combat_hotspots": _snapshot(combat, "get_combat_hotspot_debug_snapshot"),
		"security_hotspots": _snapshot(controller, "get_fireteam_security_refresh_timing_debug_snapshot"),
		"unit_proxy_diagnostics": _snapshot(view, "get_unit_proxy_sync_diagnostics"),
		"meta_presentation": _snapshot(current_scene, "get_meta_presentation_debug_snapshot"),
		"sources_sha256": _facts.get("sources_sha256", {}),
		"default_map": _facts.get("default_map", {}),
		"camera_before": before_camera,
		"camera_after": _camera_facts(view),
		"positions_before": before_positions,
		"positions_after": _positions(mission, Array(_planning_snapshot(controller).get("deployed_unit_ids", []))),
		"scope": {"synthetic_fixture": false, "time_acceleration": false, "forced_arrival": false, "forced_unloading": false, "private_simulation_state_writes": false, "gpu_frame_time": "unavailable", "warmup_seconds": 3, "route": "normal Move+GO every 12 wall seconds, alternating authored insertion and validated short path"},
	}
	var performance_path := _output.get_basename() + "_performance.json"
	if not _check(not FileAccess.file_exists(performance_path), "Performance evidence target is new"):
		return
	var file := FileAccess.open(performance_path, FileAccess.WRITE)
	if not _check(file != null, "Performance raw evidence opens"):
		return
	file.store_string(JSON.stringify(report))
	file.close()
	_facts["fullscreen_performance"] = {"path": performance_path, "summary": summary, "display": display_samples[0]}
	_check(is_equal_approx(Engine.time_scale, 1.0), "Performance measurement completed at normal 1x")
	_check(_camera_facts(view) == before_camera, "Measured camera remained unchanged")
	print("PLAYTEST_PERF_DONE ", JSON.stringify({"path": performance_path, "summary": summary}))


func _sample_completed_physics_tick() -> void:
	# SceneTree.physics_frame is emitted BEFORE the next physics update. Reading
	# here captures the prior completed tick, including costly catch-up ticks that
	# a once-per-render-frame snapshot could otherwise overwrite with a cheap tick.
	if _profile_simulation == null or not is_instance_valid(_profile_simulation):
		return
	var probe_start_usec := Time.get_ticks_usec()
	var simulation := _snapshot(_profile_simulation, "get_runtime_tick_budget_debug_snapshot")
	var tick := int(simulation.get("tick", -1))
	if tick == _profile_last_physics_tick:
		return
	_profile_last_physics_tick = tick
	_profile_physics_rows.append({
		"elapsed_usec": probe_start_usec - _profile_start_usec,
		"simulation": simulation,
		"combat": _snapshot(_profile_combat, "get_combat_tick_budget_debug_snapshot"),
		"probe_usec": Time.get_ticks_usec() - probe_start_usec,
	})


func _camera_facts(view: Node) -> Dictionary:
	var camera := view.get_node_or_null("ViewportContainer/SubViewport/WorldRoot/Camera3D") as Camera3D
	if camera == null:
		return {}
	return {"transform": str(camera.global_transform), "size": camera.size, "projection": camera.projection}


func _profile_summary(rows: Array) -> Dictionary:
	var frame_values: Array = []
	var probes: Array = []
	var hitches: Array = []
	var counts := {"over_33ms": 0, "over_50ms": 0, "over_100ms": 0, "over_250ms": 0}
	var previous_hitch_usec := -1
	for row in rows:
		var frame_usec := int(row["frame_usec"])
		frame_values.append(frame_usec)
		probes.append(int(row["probe_usec"]))
		for threshold in [33, 50, 100, 250]:
			if frame_usec > int(threshold) * 1000:
				counts["over_%dms" % threshold] += 1
		if frame_usec > 50000:
			hitches.append({"elapsed_usec": row["elapsed_usec"], "frame_usec": frame_usec, "since_previous_hitch_usec": int(row["elapsed_usec"]) - previous_hitch_usec if previous_hitch_usec >= 0 else null})
			previous_hitch_usec = int(row["elapsed_usec"])
	return {"frames": rows.size(), "frametime_usec": _distribution(frame_values), "probe_usec": _distribution(probes), "hitch_counts": counts, "hitches_over_50ms": hitches}


func _distribution(values: Array) -> Dictionary:
	if values.is_empty():
		return {}
	var sorted := values.duplicate()
	sorted.sort()
	var result := {"count": sorted.size(), "max": sorted[-1]}
	var total := 0.0
	for value in sorted:
		total += float(value)
	result["mean"] = total / float(sorted.size())
	for percentile in [50, 90, 95, 99]:
		result["p%d" % percentile] = sorted[mini(ceili(float(sorted.size()) * float(percentile) / 100.0) - 1, sorted.size() - 1)]
	return result
