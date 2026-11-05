extends "res://scripts/tests/playtest_20261105_fullscreen_performance_capture.gd"
## Additional read-only 0.25-wall-second actor/order trace. Same native route.
var _motion_trace_active := false
var _motion_trace_rows: Array = []


func _profile_normal_movement(view: Node) -> void:
	_motion_trace_active = true
	_motion_trace_rows.clear()
	call_deferred("_collect_motion_trace", view)
	await super._profile_normal_movement(view)
	_motion_trace_active = false
	var path := _output.get_basename() + "_motion.json"
	if not _check(not FileAccess.file_exists(path), "Motion trace evidence target is new"):
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not _check(file != null, "Read-only motion trace evidence opens"):
		return
	file.store_string(JSON.stringify({"schema": "sternenbuergerchen.motion_order_trace.v1", "sample_policy": "at most one read per process frame, at least 250000 real microseconds between samples", "rows": _motion_trace_rows, "actor_writes": false, "order_writes": false, "time_or_budget_changes": false}))
	file.close()
	_facts["motion_trace"] = {"path": path, "samples": _motion_trace_rows.size()}
	print("PLAYTEST_MOTION_TRACE_DONE ", JSON.stringify(_facts["motion_trace"]))


func _collect_motion_trace(view: Node) -> void:
	var mission := view.get_parent()
	var registry := mission.get_node_or_null("UnitRegistry")
	var controller := mission.get_node_or_null("TacticalController")
	var simulation := mission.get_node_or_null("SimulationRoot")
	var setup := mission.get_node_or_null("MissionSetup")
	var previous_sample_usec := 0
	while _motion_trace_active and is_instance_valid(mission) and is_instance_valid(controller):
		await process_frame
		if not _motion_trace_active or not is_instance_valid(mission) or not is_instance_valid(controller):
			break
		var now_usec := Time.get_ticks_usec()
		if now_usec - previous_sample_usec < 250000:
			continue
		previous_sample_usec = now_usec
		var started_usec := Time.get_ticks_usec()
		var actors: Array = []
		if registry != null and registry.has_method("get_all_units"):
			for unit in registry.call("get_all_units"):
				if not is_instance_valid(unit) or not (unit is Node2D):
					continue
				var command: Variant = unit.call("get_current_unit_command") if unit.has_method("get_current_unit_command") else null
				var status: Variant = unit.call("get_runtime_status") if unit.has_method("get_runtime_status") else null
				actors.append({
					"id": unit.call("get_unit_id") if unit.has_method("get_unit_id") else "",
					"team": unit.call("get_team_id") if unit.has_method("get_team_id") else "",
					"fireteam": unit.call("get_fireteam_id") if unit.has_method("get_fireteam_id") else "",
					"position": {"x": unit.global_position.x, "y": unit.global_position.y},
					"vital": unit.call("get_vital_state") if unit.has_method("get_vital_state") else "",
					"visible": unit.visible,
					"visible_in_tree": unit.is_visible_in_tree(),
					"command": _trace_serializable(command.call("to_dict")) if command is Object and command.has_method("to_dict") else _trace_serializable(command),
					"status": _trace_serializable(status.call("to_dict")) if status is Object and status.has_method("to_dict") else _trace_serializable(status),
				})
		var planning := _snapshot(controller, "get_planning_state")
		var movement: Dictionary = {}
		for id in planning.get("selected_fireteams", []):
			movement[String(id)] = _trace_serializable(controller.call("get_fireteam_movement_state", String(id)))
		_motion_trace_rows.append({
			"time_usec": now_usec,
			"profile_elapsed_usec": now_usec - _profile_start_usec if _profile_start_usec > 0 else -1,
			"tick": simulation.call("get_tick") if simulation != null else -1,
			"actors": actors,
			"planning": _trace_serializable(_keep(planning, ["selected_fireteams", "selected_phase", "selected_phase_index", "active_phase_index", "phase_count", "order_plans", "area_orders", "multi_fireteam_plans", "deployed_unit_ids"])),
			"movement": movement,
			"phase_execution": _trace_serializable(controller.get("_phase_execution_by_fireteam")),
			"nav": _snapshot(simulation, "get_navigation_debug_snapshot"),
			"fog": _snapshot(setup, "get_fog_frame_timing_debug_snapshot"),
			"probe_usec": Time.get_ticks_usec() - started_usec,
		})


func _trace_serializable(value: Variant, depth: int = 0) -> Variant:
	if depth > 12:
		return "depth_limit"
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value:
			result[String(key)] = _trace_serializable(value[key], depth + 1)
		return result
	if value is Array:
		var result: Array = []
		for item in value:
			result.append(_trace_serializable(item, depth + 1))
		return result
	if value is Object:
		return _trace_serializable(value.call("to_dict"), depth + 1) if is_instance_valid(value) and value.has_method("to_dict") else str(value)
	return value
