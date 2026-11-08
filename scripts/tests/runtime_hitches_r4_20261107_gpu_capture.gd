extends "res://scripts/tests/runtime_hitches_r4_20261107_native_capture.gd"
## Separate diagnostic instrumentation; never a fair unchanged FPS baseline.
## The inherited normal route, product, renderer quality and gameplay stay intact.

class GpuFrameProbe extends Node:
	const MAX_ROWS: int = 16384
	const MONITOR_NAMES: PackedStringArray = [
		"PIPELINE_COMPILATIONS_CANVAS", "PIPELINE_COMPILATIONS_MESH",
		"PIPELINE_COMPILATIONS_SURFACE", "PIPELINE_COMPILATIONS_DRAW",
		"PIPELINE_COMPILATIONS_SPECIALIZATION",
		"RENDER_TOTAL_DRAW_CALLS_IN_FRAME", "RENDER_TOTAL_OBJECTS_IN_FRAME",
		"RENDER_TOTAL_PRIMITIVES_IN_FRAME", "RENDER_VIDEO_MEM_USED",
		"RENDER_TEXTURE_MEM_USED", "RENDER_BUFFER_MEM_USED",
	]
	const TIMING_METHODS: PackedStringArray = [
		"viewport_set_measure_render_time", "viewport_get_measured_render_time_cpu",
		"viewport_get_measured_render_time_gpu",
	]
	var _gpu_running: bool = false
	var _gpu_rows: Array[Dictionary] = []
	var _gpu_row_cursor: int = 0
	var _gpu_callback_count: int = 0
	var _gpu_overwritten_rows: int = 0
	var _gpu_viewports: Array[Dictionary] = []
	var _gpu_monitor_ids: Dictionary = {}
	var _gpu_metadata: Dictionary = {}


	func start(root_viewport: Viewport, game_viewport: Viewport) -> void:
		var methods: Dictionary = {}
		var timing_methods_available: bool = true
		for method_name in TIMING_METHODS:
			var available: bool = RenderingServer.has_method(String(method_name))
			methods[String(method_name)] = available
			timing_methods_available = timing_methods_available and available
		var native_renderer: bool = DisplayServer.get_name() != "headless"
		var signal_available: bool = RenderingServer.has_signal("frame_post_draw")
		_gpu_metadata = {
			"observer_started_usec": Time.get_ticks_usec(),
			"engine": Engine.get_version_info(),
			"display": DisplayServer.get_name(),
			"rendering_method": RenderingServer.get_current_rendering_method(),
			"rendering_driver": RenderingServer.get_current_rendering_driver_name(),
			"native_renderer": native_renderer,
			"timing_methods": methods,
			"frame_post_draw_available": signal_available,
			"frame_setup_cpu_available": RenderingServer.has_method("get_frame_setup_time_cpu"),
			"monitor_availability": {},
			"timer_request_before_inherited_warmup": true,
		}
		for monitor_name in MONITOR_NAMES:
			var available: bool = ClassDB.class_has_integer_constant("Performance", String(monitor_name))
			_gpu_metadata["monitor_availability"][String(monitor_name)] = available
			if available:
				_gpu_monitor_ids[String(monitor_name)] = ClassDB.class_get_integer_constant("Performance", String(monitor_name))
		var can_measure: bool = native_renderer and timing_methods_available and signal_available
		_prepare_viewport("root", root_viewport, can_measure)
		_prepare_viewport("game", game_viewport, can_measure)
		if not can_measure:
			return
		_gpu_running = true
		RenderingServer.frame_post_draw.connect(_on_frame_post_draw)


	func _prepare_viewport(role: String, viewport: Viewport, can_measure: bool) -> void:
		var record: Dictionary = {
			"role": role, "node": null, "rid": RID(), "path": "", "size": "",
			"enabled_by_probe": false, "timer_owned": false,
			"disabled_on_stop": false, "disable_skipped_dead_or_changed_rid": false,
			"invalid_observations": 0,
		}
		if is_instance_valid(viewport) and viewport.is_inside_tree():
			record["node"] = weakref(viewport)
			record["rid"] = viewport.get_viewport_rid()
			record["path"] = String(viewport.get_path())
			record["size"] = str(viewport.get_visible_rect().size)
			var already_owned: bool = false
			for existing in _gpu_viewports:
				already_owned = already_owned or (existing["rid"] == record["rid"] and bool(existing["enabled_by_probe"]))
			var viewport_rid: RID = record["rid"]
			if can_measure and viewport_rid.is_valid() and not already_owned:
				RenderingServer.call("viewport_set_measure_render_time", record["rid"], true)
				record["enabled_by_probe"] = true
				record["timer_owned"] = true
		_gpu_viewports.append(record)


	func _live_viewport(record: Dictionary, require_tree: bool = true) -> Viewport:
		var reference: WeakRef = record.get("node") as WeakRef
		var viewport: Viewport = reference.get_ref() as Viewport if reference != null else null
		if not is_instance_valid(viewport):
			return null
		if require_tree and not viewport.is_inside_tree():
			return null
		var viewport_rid: RID = record["rid"]
		if not viewport_rid.is_valid() or viewport.get_viewport_rid() != viewport_rid:
			return null
		return viewport


	func _timing_value(value: float) -> Variant:
		return value if is_finite(value) and value >= 0.0 else null


	func _on_frame_post_draw() -> void:
		if not _gpu_running:
			return
		var started_usec: int = Time.get_ticks_usec()
		_gpu_callback_count += 1
		var row: Dictionary = {
			"observed_usec": started_usec,
			"engine_frame": Engine.get_process_frames(),
			"viewports": {}, "monitors": {}, "frame_setup_cpu_ms": null,
		}
		for record in _gpu_viewports:
			var live: bool = _live_viewport(record) != null
			var enabled: bool = bool(record["timer_owned"])
			var sample: Dictionary = {"node_and_rid_alive": live, "timer_enabled_by_probe": enabled, "cpu_ms": null, "gpu_ms": null}
			if live and enabled:
				sample["cpu_ms"] = _timing_value(float(RenderingServer.call("viewport_get_measured_render_time_cpu", record["rid"])))
				sample["gpu_ms"] = _timing_value(float(RenderingServer.call("viewport_get_measured_render_time_gpu", record["rid"])))
			else:
				record["invalid_observations"] = int(record["invalid_observations"]) + 1
			row["viewports"][String(record["role"])] = sample
		if bool(_gpu_metadata.get("frame_setup_cpu_available", false)):
			row["frame_setup_cpu_ms"] = _timing_value(float(RenderingServer.call("get_frame_setup_time_cpu")))
		for monitor_name in _gpu_monitor_ids:
			row["monitors"][String(monitor_name)] = float(Performance.get_monitor(int(_gpu_monitor_ids[monitor_name])))
		if _gpu_rows.size() < MAX_ROWS:
			_gpu_rows.append(row)
		else:
			_gpu_rows[_gpu_row_cursor] = row
			_gpu_row_cursor = (_gpu_row_cursor + 1) % MAX_ROWS
			_gpu_overwritten_rows += 1
		# Include row construction and bounded storage in the observed probe cost.
		row["probe_usec"] = Time.get_ticks_usec() - started_usec


	func stop() -> void:
		_gpu_running = false
		if RenderingServer.frame_post_draw.is_connected(_on_frame_post_draw):
			RenderingServer.frame_post_draw.disconnect(_on_frame_post_draw)
		for record in _gpu_viewports:
			if not bool(record["timer_owned"]):
				continue
			# An exiting/detached but still live owner can retain its valid RID.
			# Disable our timer there too; sampling itself requires tree membership.
			if _live_viewport(record, false) != null:
				RenderingServer.call("viewport_set_measure_render_time", record["rid"], false)
				record["disabled_on_stop"] = true
			else:
				record["disable_skipped_dead_or_changed_rid"] = true
			record["timer_owned"] = false
		_gpu_metadata["observer_stopped_usec"] = Time.get_ticks_usec()


	func _exit_tree() -> void:
		stop()


	func build_report(start_usec: int, duration_usec: int, exact_window: bool, window_source: String) -> Dictionary:
		var ordered: Array = _gpu_rows.slice(_gpu_row_cursor)
		if _gpu_row_cursor > 0:
			ordered.append_array(_gpu_rows.slice(0, _gpu_row_cursor))
		var window_rows: Array = []
		var before_window: int = 0
		var after_window: int = 0
		var valid_window: bool = start_usec > 0 and duration_usec > 0
		var end_usec: int = start_usec + duration_usec
		var nonzero_seen: Dictionary = {"root_cpu": false, "root_gpu": false, "game_cpu": false, "game_gpu": false, "frame_setup_cpu": false}
		for row in ordered:
			var observed_usec: int = int(row["observed_usec"])
			if not valid_window or observed_usec < start_usec:
				before_window += 1
				continue
			if observed_usec > end_usec:
				after_window += 1
				continue
			row["profile_elapsed_usec"] = observed_usec - start_usec
			window_rows.append(row)
			for role in ["root", "game"]:
				var sample: Dictionary = row["viewports"].get(role, {})
				for metric in ["cpu", "gpu"]:
					var value: Variant = sample.get(metric + "_ms")
					if value != null and float(value) > 0.0:
						nonzero_seen[role + "_" + metric] = true
			var setup: Variant = row.get("frame_setup_cpu_ms")
			if setup != null and float(setup) > 0.0:
				nonzero_seen["frame_setup_cpu"] = true
		var viewport_facts: Array = []
		for record in _gpu_viewports:
			var facts: Dictionary = record.duplicate()
			facts.erase("node")
			facts.erase("rid")
			viewport_facts.append(facts)
		return {
			"schema": "sternenbuergerchen.runtime_hitches_r4.gpu_diagnostic.v1",
			"metadata": _gpu_metadata.duplicate(true), "viewports": viewport_facts,
			"window": {"start_usec": start_usec, "duration_usec": duration_usec, "end_usec": end_usec, "valid": valid_window, "exact": exact_window, "source": window_source, "filter": "start_usec <= observed_usec <= end_usec; warmup and later observations excluded"},
			"capacity": {"row_limit": MAX_ROWS, "callbacks_observed": _gpu_callback_count, "retained_before_filter": ordered.size(), "overwritten_rows": _gpu_overwritten_rows, "window_may_be_truncated": _gpu_overwritten_rows > 0, "discarded_before_window": before_window, "discarded_after_window": after_window},
			"window_row_count": window_rows.size(), "nonzero_seen_in_window": nonzero_seen,
			"any_gpu_nonzero_seen_in_window": bool(nonzero_seen["root_gpu"]) or bool(nonzero_seen["game_gpu"]),
			"rows": window_rows,
			"scope": {"diagnostic_only": true, "fair_fps_baseline": false, "performance_gain_claim": false, "timing_unit": "milliseconds", "probe_unit": "microseconds", "viewport_values_are_last_frame_measurements": true, "observation_frame_is_not_a_guaranteed_gpu_frame_id": true, "root_and_game_values_may_overlap_do_not_sum": true, "cpu_render_time_excludes_script_cpu": true, "zero_is_not_proof_of_zero_gpu_work": true, "pipeline_monitors_are_counters_not_durations": true, "actor_writes": false, "authority_writes": false, "quality_changes": false, "forced_draw_or_readback": false},
		}


func _profile_normal_movement(view: Node) -> void:
	var probe := GpuFrameProbe.new()
	probe.name = "R4GpuFrameDiagnosticProbe"
	root.add_child(probe)
	var game_viewport: Viewport = view.get("_subviewport") as Viewport if is_instance_valid(view) else null
	probe.start(root, game_viewport)
	# Only the diagnostic timers/callback are new. Super owns every normal
	# command, warmup, sample window and subsequent ordinary capture action.
	await super._profile_normal_movement(view)
	probe.stop()
	var summary: Dictionary = Dictionary(_facts.get("fullscreen_performance", {})).get("summary", {})
	var duration_usec: int = int(summary.get("duration_usec", 0))
	var exact_window: bool = _profile_start_usec > 0 and duration_usec > 0
	var window_source: String = "inherited _profile_start_usec + fullscreen_performance.summary.duration_usec"
	if duration_usec <= 0:
		duration_usec = roundi(clampf(float(_argument("--profile-seconds", "90")), 5.0, 180.0) * 1000000.0)
		window_source = "INEXACT argument duration fallback; inherited summary duration unavailable"
	var evidence: Dictionary = probe.build_report(_profile_start_usec, duration_usec, exact_window, window_source)
	evidence["base_performance_path"] = Dictionary(_facts.get("fullscreen_performance", {})).get("path", "")
	evidence["official_api_reference"] = "https://docs.godotengine.org/en/4.6/classes/class_renderingserver.html#class-renderingserver-method-viewport-get-measured-render-time-gpu"
	probe.queue_free()
	var path: String = _output.get_basename() + "_gpu.json"
	if not _check(not FileAccess.file_exists(path), "Separate GPU diagnostic evidence target is new"):
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not _check(file != null, "Separate GPU diagnostic evidence opens after timing"):
		return
	file.store_string(JSON.stringify(evidence))
	file.close()
	_facts["r4_gpu_diagnostics"] = {"path": path, "diagnostic_only": true, "fair_fps_baseline": false, "window": evidence["window"], "window_row_count": evidence["window_row_count"], "nonzero_seen_in_window": evidence["nonzero_seen_in_window"], "capacity": evidence["capacity"]}
	print("R4_GPU_DIAGNOSTIC_DONE ", JSON.stringify(_facts["r4_gpu_diagnostics"]))
