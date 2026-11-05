extends "res://scripts/tests/playtest_20261105_fullscreen_performance_capture.gd"
## Normal native route and real 1x ticks. No actor, order-state or timer writes.

var _deployment_rows: Array = []


func _capture(id: String, view: Node = null, settle_frames: int = 8) -> void:
	await super._capture(id, view, settle_frames)
	if id == "05_deployed" and view != null:
		_deployment_rows = _lifecycle_rows(view.get_parent())
		_check(_deployment_rows.size() >= 2, "Lifecycle regression retains at least two normally deployed units")
		for row in _deployment_rows:
			# Post-drop security is tokenized and may still be moving/queued here.
			_check(String(row.latest_token).begins_with("post_drop_security:"), "Normal deployment owns a tokenized post-drop security command: " + String(row.id))


func _profile_normal_movement(view: Node) -> void:
	var mission := view.get_parent()
	var controller := mission.get_node_or_null("TacticalController")
	var simulation := mission.get_node_or_null("SimulationRoot")
	if not _check(controller != null and simulation != null, "Lifecycle regression uses actual normal runtime owners"):
		return
	_check(DisplayServer.get_name() != "headless", "Lifecycle regression uses a native renderer")
	_check(root.mode == Window.MODE_FULLSCREEN or root.mode == Window.MODE_EXCLUSIVE_FULLSCREEN, "Lifecycle regression uses genuine fullscreen")
	_check(DisplayServer.window_get_size() == _profile_screen_size, "Lifecycle fullscreen covers the active display resolution")
	_check(is_equal_approx(Engine.time_scale, 1.0), "Lifecycle progression remains at real 1x")
	await create_timer(1.2).timeout
	var initial_move_rows := _lifecycle_rows(mission)
	_check(_same_unit_ids(_deployment_rows, initial_move_rows), "First normal GO preserves every deployed identity")
	for row in initial_move_rows:
		_check(String(row.command.get("command_type", "")) == "move_to_position" and not String(row.command.get("command_token", "")).is_empty(), "Post-drop security accepts the first tokenized Move through GO: " + String(row.id))
		_check(_position_delta(_deployment_rows, row) > 1.0, "First normal Move produces actual displacement: " + String(row.id))
	var completed := await _wait_until("natural final Move completion and Auto DEF", func() -> bool:
		return Dictionary(controller.get("_phase_execution_by_fireteam")).is_empty() and _all_auto_defend(_lifecycle_rows(mission))
	, 60.0)
	if not completed:
		return
	# The completion command must have passed through SimulationRoot before reads.
	await physics_frame
	await process_frame
	var hold_rows := _lifecycle_rows(mission)
	_check(_same_unit_ids(initial_move_rows, hold_rows), "Natural completion preserves the same runtime units")
	_check(_all_auto_defend(hold_rows), "Final Move naturally completes into untokenized Auto DEF")
	for row in hold_rows:
		_check(String(row.vital) == "fit", "Completed Move unit remains fit: " + String(row.id))
		var previous := _row_for_id(initial_move_rows, String(row.id))
		_check(bool(simulation.call("_is_stale_tokenized_move_command", previous.get("command", {}), _runtime_unit(mission, String(row.id)))), "Old completed Move remains stale after untokenized Auto DEF: " + String(row.id))
	var discarded_before := int(simulation.call("get_discarded_move_command_count", "stale_command_token"))
	var target: Vector2 = _profile_points["lz"]
	var accepted := bool(controller.call("issue_right_click_command_for_test", target, "move", false))
	_check(accepted, "Existing Move action accepts a fresh plan after natural Auto DEF")
	var executed := bool(controller.call("execute_selected_fireteam_orders")) if accepted else false
	_check(executed, "Existing GO accepts the new Move after natural Auto DEF")
	await create_timer(1.5).timeout
	var resumed_rows := _lifecycle_rows(mission)
	_check(_same_unit_ids(hold_rows, resumed_rows), "Second GO retains the same actual actors")
	for row in resumed_rows:
		var previous := _row_for_id(initial_move_rows, String(row.id))
		_check(String(row.command.get("command_type", "")) == "move_to_position" and String(row.command.get("command_token", "")) != String(Dictionary(previous.get("command", {})).get("command_token", "")), "Second GO commits its fresh Move token: " + String(row.id))
		_check(_position_delta(hold_rows, row) > 2.0, "Second GO physically moves the same unit after Auto DEF: " + String(row.id))
		_check(bool(simulation.call("_is_stale_tokenized_move_command", previous.get("command", {}), _runtime_unit(mission, String(row.id)))), "Old Move remains stale after a later Move commits: " + String(row.id))
	_check(int(simulation.call("get_discarded_move_command_count", "stale_command_token")) == discarded_before, "Fresh post-Auto-DEF Move commands are not discarded as stale")
	_facts["move_after_auto_defend"] = {
		"initial_deployment": _deployment_rows,
		"initial_move": initial_move_rows,
		"natural_auto_defend": hold_rows,
		"resumed": resumed_rows,
		"stale_discarded_before": discarded_before,
		"stale_discarded_after": simulation.call("get_discarded_move_command_count", "stale_command_token"),
		"last_discard": simulation.call("get_last_discarded_move_command"),
		"planning": _snapshot(controller, "get_planning_state"),
		"simulation_sha256": FileAccess.get_sha256("res://scripts/core/simulation_root.gd"),
		"actor_or_timer_writes": false,
	}
	print("PLAYTEST_MOVE_AUTODEFEND_DONE")


func _runtime_unit(mission: Node, id: String) -> Node:
	return mission.get_node("UnitRegistry").call("get_unit", id)


func _lifecycle_rows(mission: Node) -> Array:
	var rows: Array = []
	var controller := mission.get_node("TacticalController")
	var simulation := mission.get_node("SimulationRoot")
	var committed: Dictionary = simulation.get("_committed_command_token_by_unit_id")
	var latest: Dictionary = simulation.get("_latest_command_token_by_unit_id")
	for id in _planning_snapshot(controller).get("deployed_unit_ids", []):
		var unit := _runtime_unit(mission, String(id)) as Node2D
		if unit == null:
			continue
		var command: Variant = unit.call("get_current_unit_command")
		var command_dict: Dictionary = Dictionary(command.call("to_dict")).duplicate(true) if command is Object and command.has_method("to_dict") else {}
		rows.append({"id": String(id), "position": unit.global_position, "vital": unit.call("get_vital_state"), "command": command_dict, "committed_has": committed.has(id), "committed_token": String(committed.get(id, "")), "latest_has": latest.has(id), "latest_token": String(latest.get(id, ""))})
	return rows


func _row_for_id(rows: Array, id: String) -> Dictionary:
	for row in rows:
		if String(row.id) == id:
			return row
	return {}


func _position_delta(before: Array, row: Dictionary) -> float:
	var previous := _row_for_id(before, String(row.id))
	return Vector2(previous.get("position", row.position)).distance_to(Vector2(row.position))


func _same_unit_ids(first: Array, second: Array) -> bool:
	if first.size() != second.size() or first.size() < 2:
		return false
	for row in first:
		if _row_for_id(second, String(row.id)).is_empty():
			return false
	return true


func _all_auto_defend(rows: Array) -> bool:
	if rows.size() < 2:
		return false
	for row in rows:
		if String(row.command.get("command_type", "")) != "hold_position" or String(row.command.get("source_task_type", "")) != "auto_defend":
			return false
	return true
