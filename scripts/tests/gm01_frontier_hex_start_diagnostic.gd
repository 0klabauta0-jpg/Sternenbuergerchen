extends "res://scripts/tests/gm01_frontier_normal_capture.gd"
## Observation-only normal startup. Retains the existing arrival timeout and all
## real timer/actor/gameplay behavior; samples never advance or replace state.

var _hex_diag_samples: Array = []
var _hex_diag_last_msec: int = -1000
var _hex_diag_visual_calls: int = 0
var _hex_diag_visual_total_usec: int = 0
var _hex_diag_visual_max_usec: int = 0
var _hex_diag_profiled_mission: int = 0
var _hex_diag_profiled_flow: int = 0
var _hex_diag_profile_peaks: Dictionary = {}
var _hex_diag_observe_seconds: float = 0.0
var _hex_diag_mission_observed_at_msec: int = -1
var _hex_diag_stop_requested: bool = false


func _initialize() -> void:
	_facts["hex_runtime_samples"] = _hex_diag_samples
	_facts["hex_diagnostic_observation_only"] = true
	_facts["hex_hardware_context"] = _hex_diag_hardware_context()
	_hex_diag_observe_seconds = maxf(float(_argument("--hex-observe-only-seconds", "0")), 0.0)
	if _hex_diag_observe_seconds > 0.0:
		_facts["observation_only_short_probe"] = true
		_facts["observation_only_seconds_requested"] = _hex_diag_observe_seconds
		_facts["hex_runtime_diagnostic_scope"] = "Partial profiling after actual normal mission entry; no arrival/deployment/GO or normal-start acceptance is claimed."
	process_frame.connect(_hex_diag_on_process_frame)
	super._initialize()


func _hex_diag_on_process_frame() -> void:
	if _finished:
		return
	_hex_diag_arm_short_probe_stop()
	if Time.get_ticks_msec() - _hex_diag_last_msec < 1000:
		return
	_hex_diag_samples.append(_hex_diag_sample())
	_hex_diag_last_msec = Time.get_ticks_msec()


func _hex_diag_arm_short_probe_stop() -> void:
	if _hex_diag_stop_requested or _hex_diag_observe_seconds <= 0.0 or _hex_diag_mission_observed_at_msec < 0:
		return
	var observed_msec: int = Time.get_ticks_msec() - _hex_diag_mission_observed_at_msec
	if observed_msec < roundi(_hex_diag_observe_seconds * 1000.0):
		return
	_hex_diag_stop_requested = true
	_facts["observation_only_seconds_completed"] = float(observed_msec) / 1000.0
	_facts["observation_only_short_probe_completed"] = true


func _wait_until(label: String, predicate: Callable, seconds: float = 15.0) -> bool:
	if _hex_diag_observe_seconds <= 0.0:
		return await super._wait_until(label, predicate, seconds)
	var end: int = mini(_deadline, Time.get_ticks_msec() + roundi(seconds * 1000.0))
	while Time.get_ticks_msec() < end:
		_hex_diag_arm_short_probe_stop()
		if _hex_diag_stop_requested:
			# Unwind this pending predicate before the normal _run cleanup frees
			# its captured mission/controller. This is not a failed acceptance check.
			return false
		if bool(predicate.call()):
			return true
		await create_timer(0.10).timeout
	return _check(false, "Timed out waiting for " + label)


func _hex_diag_sample() -> Dictionary:
	var sample: Dictionary = {
		"wall_msec": Time.get_ticks_msec(),
		"elapsed_msec": maxi(Time.get_ticks_msec() - _started, 0),
		"process_frames": Engine.get_process_frames(),
		"physics_frames": Engine.get_physics_frames(),
		"engine_fps": Engine.get_frames_per_second(),
		"process_seconds": Performance.get_monitor(Performance.TIME_PROCESS),
		"physics_process_seconds": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS),
		"tree_paused": paused,
		"time_scale": Engine.time_scale,
	}
	var flow: Node = current_scene
	if flow == null or not is_instance_valid(flow) or not flow.has_method("get_active_mission"):
		return sample
	if _hex_diag_profiled_flow != flow.get_instance_id() and flow.has_method("set_transport_refresh_timing_debug_enabled"):
		flow.call("set_transport_refresh_timing_debug_enabled", true)
		_hex_diag_profiled_flow = flow.get_instance_id()
		_facts["hex_meta_transport_debug_flag_enabled"] = true
	if flow.has_method("get_transport_refresh_timing_debug_snapshot"):
		var timing: Dictionary = _keep(_snapshot(flow, "get_transport_refresh_timing_debug_snapshot"), ["enabled", "total_usec", "scopes_usec", "invocation_count", "completed_at_msec"])
		sample["meta_transport_refresh"] = timing
		_hex_diag_record_profile_peak("meta_transport_refresh", timing)
	sample["flow_process_mode"] = flow.process_mode
	var pending: Array = []
	var transfers: Variant = flow.get("_pending_mission_craft_transfers")
	if transfers is Array:
		for entry_variant in transfers:
			if entry_variant is Dictionary:
				pending.append(_keep(entry_variant, ["phase", "elapsed_seconds", "duration_seconds", "payload_source"]))
	sample["pending_mission_transfers"] = pending
	var timer := flow.get_node_or_null("TransportTimer") as Timer
	if timer != null:
		sample["transport_timer"] = {
			"time_left": timer.time_left, "is_stopped": timer.is_stopped(),
			"paused": timer.paused, "can_process": timer.can_process(),
			"wait_time": timer.wait_time, "process_callback": timer.process_callback,
			"process_mode": timer.process_mode,
		}
	var mission: Node = flow.call("get_active_mission")
	if mission == null or not is_instance_valid(mission):
		return sample
	if _hex_diag_mission_observed_at_msec < 0:
		_hex_diag_mission_observed_at_msec = Time.get_ticks_msec()
		_facts["observation_mission_first_seen_elapsed_msec"] = maxi(_hex_diag_mission_observed_at_msec - _started, 0)
	_hex_diag_enable_existing_profiles(mission)
	sample["mission_process_mode"] = mission.process_mode
	var controller := mission.get_node_or_null("TacticalController")
	if controller != null:
		# Keep this tiny: do not serialize names, roster or large plan dictionaries.
		sample["planning"] = _keep(_planning_snapshot(controller), ["mission_drop_state", "mission_drop_eta_seconds", "mission_drop_progress", "mission_drop_source"])
	var simulation := mission.get_node_or_null("SimulationRoot")
	if simulation != null and simulation.has_method("get_tick"):
		sample["simulation_tick"] = int(simulation.call("get_tick"))
		if simulation.has_method("get_last_tick_delta"):
			sample["simulation_last_tick_delta"] = float(simulation.call("get_last_tick_delta"))
	var timings: Dictionary = {}
	for spec in [
		["simulation", "SimulationRoot", "get_runtime_tick_budget_debug_snapshot"],
		["combat", "CombatLoopDriver", "get_combat_tick_budget_debug_snapshot"],
		["view", "Primary3DView", "get_runtime_frame_timing_debug_snapshot"],
		["controller", "TacticalController", "get_mission_visible_frame_timing_debug_snapshot"],
		["controller_ui", "TacticalController", "get_mission_ui_refresh_timing_debug_snapshot"],
		["controller_surfaces", "TacticalController", "get_mission_runtime_surface_timing_debug_snapshot"],
	]:
		var node: Node = mission.get_node_or_null(String(spec[1]))
		if node == null or not node.has_method(String(spec[2])):
			continue
		var raw: Dictionary = _snapshot(node, String(spec[2]))
		var timing: Dictionary = _keep(raw, ["enabled", "tick", "state", "total_tick_usec", "total_usec", "scopes_usec", "conditional_scopes_usec", "counters", "command_count", "effect_count", "command_type_count", "command_type_usec", "command_queue_after_tick", "effect_queue_after_tick", "friendly_unit_count", "enemy_unit_count", "active_enemy_unit_count", "included_ui_refresh"])
		if String(spec[0]) == "simulation":
			timing["navigation"] = _hex_diag_navigation_summary(Dictionary(raw.get("navigation", {})))
		timings[String(spec[0])] = timing
		_hex_diag_record_profile_peak(String(spec[0]), timing)
	var combat: Node = mission.get_node_or_null("CombatLoopDriver")
	if combat != null and combat.has_method("get_combat_hotspot_debug_snapshot"):
		var raw: Dictionary = _snapshot(combat, "get_combat_hotspot_debug_snapshot")
		var hotspots: Dictionary = _keep(raw, ["enabled", "counts", "usec"])
		hotspots["visibility_cache"] = _keep(Dictionary(raw.get("visibility_cache", {})), ["enabled", "counts", "usec"])
		timings["combat_hotspots"] = hotspots
	sample["timings"] = timings
	return sample


func _hex_diag_navigation_summary(raw: Dictionary) -> Dictionary:
	# Existing debug state only: do not enable navigation history for the paired
	# run. Empty query diagnostics are meaningful when that flag is disabled.
	var result: Dictionary = _keep(raw, ["enabled", "budget_enabled", "tick", "max_new_path_queries_per_tick", "new_path_queries_this_tick", "path_queries_this_tick", "fallback_queries_this_tick", "unreachable_queries_this_tick", "delayed_this_tick", "pending_query_count", "last_delay_reason"])
	result["most_expensive_query"] = _keep(Dictionary(raw.get("most_expensive_query", {})), ["tick", "query_kind", "route_type", "status", "from_grid", "to_grid", "duration_usec", "path_grid_count", "path_length_grid", "path_cost", "candidate_count_estimate", "expanded_node_estimate", "fallback_or_delay_reason", "unreachable", "heuristic"])
	result["last_path_metrics"] = _keep(Dictionary(raw.get("last_path_metrics", {})), ["query_kind", "route_type", "status", "path_length_grid", "exposure_sum", "cover_sum", "mean_exposure", "mean_cover", "path_cost"])
	var hpa: Dictionary = raw.get("hpa_navigation", {})
	var summary: Dictionary = _keep(hpa, ["has_graph", "cluster_size", "tile_count", "registry_revision", "build_count", "cache_hit_count"])
	summary["last_build_stats"] = _keep(Dictionary(hpa.get("last_build_stats", {})), ["built", "cluster_size", "tile_count", "cluster_count", "component_count", "portal_count", "elapsed_usec", "incremental", "dirty_grid_count", "dirty_cluster_count", "rebuilt_cluster_count", "runtime_build_count", "runtime_rebuild_mode", "registry_revision"])
	result["hpa_navigation"] = summary
	return result


func _hex_diag_hardware_context() -> Dictionary:
	return {
		"os": OS.get_name(), "os_version": OS.get_version(),
		"processor_name": OS.get_processor_name(), "processor_count": OS.get_processor_count(),
		"video_adapter": RenderingServer.get_video_adapter_name(),
		"render_method": RenderingServer.get_current_rendering_method(),
		"render_driver": RenderingServer.get_current_rendering_driver_name(),
		"display": DisplayServer.get_name(), "godot": Engine.get_version_info(),
		"godot_arguments": OS.get_cmdline_args(),
		"requested_ui_size": _argument("--ui-size", "1920x1080"),
		"logical_root_size": root.size, "content_scale_size": root.content_scale_size,
		"content_scale_mode": root.content_scale_mode,
	}


func _hex_diag_enable_existing_profiles(mission: Node) -> void:
	if _hex_diag_profiled_mission == mission.get_instance_id():
		return
	for spec in [
		["SimulationRoot", "set_runtime_tick_budget_debug_enabled"],
		["CombatLoopDriver", "set_combat_tick_budget_debug_enabled"],
		["Primary3DView", "set_runtime_frame_timing_debug_enabled"],
		["TacticalController", "set_mission_visible_frame_timing_debug_enabled"],
	]:
		var node: Node = mission.get_node_or_null(String(spec[0]))
		if node != null and node.has_method(String(spec[1])):
			node.call(String(spec[1]), true)
	_hex_diag_profiled_mission = mission.get_instance_id()
	_facts["hex_existing_debug_flags_enabled"] = true
	_facts["hex_debug_flags_change_gameplay"] = false


func _hex_diag_record_profile_peak(component: String, timing: Dictionary) -> void:
	var peak: Dictionary = _hex_diag_profile_peaks.get(component, {"samples": 0, "total_usec_max": 0, "scopes_usec_max": {}})
	peak["samples"] = int(peak["samples"]) + 1
	peak["total_usec_max"] = maxi(int(peak["total_usec_max"]), int(timing.get("total_tick_usec", timing.get("total_usec", 0))))
	var scopes: Dictionary = timing.get("scopes_usec", {})
	var peaks: Dictionary = peak["scopes_usec_max"]
	for key in scopes:
		if scopes[key] is int or scopes[key] is float:
			peaks[key] = maxi(int(peaks.get(key, 0)), int(scopes[key]))
	peak["scopes_usec_max"] = peaks
	_hex_diag_profile_peaks[component] = peak


func _visual_snapshot(view: Node) -> Dictionary:
	var started_usec: int = Time.get_ticks_usec()
	var snapshot: Dictionary = super._visual_snapshot(view)
	var duration_usec: int = Time.get_ticks_usec() - started_usec
	_hex_diag_visual_calls += 1
	_hex_diag_visual_total_usec += duration_usec
	_hex_diag_visual_max_usec = maxi(_hex_diag_visual_max_usec, duration_usec)
	_facts["hex_visual_snapshot_timing"] = {
		"calls": _hex_diag_visual_calls, "last_usec": duration_usec,
		"total_usec": _hex_diag_visual_total_usec, "max_usec": _hex_diag_visual_max_usec,
	}
	return snapshot


func _finish() -> void:
	if _finished:
		return
	_facts["hex_runtime_final"] = _hex_diag_sample()
	_facts["hex_runtime_profile_sample_peaks"] = _hex_diag_profile_peaks.duplicate(true)
	_facts["hex_hardware_context"] = _hex_diag_hardware_context()
	await super._finish()
