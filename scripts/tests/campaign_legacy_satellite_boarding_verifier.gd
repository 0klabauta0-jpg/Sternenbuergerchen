extends "res://scripts/tests/campaign_intro_loop_smoke.gd"
## Actual legacy satellite route through landing, on-foot return and boarding.

func _run() -> void:
	_configure_entry()
	_flow = FLOW.instantiate(); root.add_child(_flow)
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	if not await _prepare_initial_base(): await _finish(); return
	var craft: Dictionary = _screen.call("get_operations_snapshot").get("selected_craft", {})
	_craft_id = String(craft.get("id", "")); _pilot_id = String(craft.get("pilot_id", ""))
	var payload: Array = craft.get("payload_fireteam_ids", [])
	if not _check(not _craft_id.is_empty() and not payload.is_empty(), "actual craft and team are available"): await _finish(); return
	_team_id = String(payload[0])
	for team: Dictionary in Array(_screen.call("get_operations_snapshot").get("fireteams", [])):
		if String(team.get("id", "")) == _team_id:
			for member: Dictionary in Array(team.get("members", [])): _crew_ids.append(String(member.id))
	if not _check(_screen.call("request_operation", "accept_job", {"job_id":"satellite_recovery", "request_id":"air-probe:accept"}).get("ok", false), "regular mission accepted"): await _finish(); return
	if not _check(_screen.call("request_operation", "select_destination", {"location_id":"satellite_crash", "job_id":"satellite_recovery", "request_id":"air-probe:destination"}).get("ok", false), "regular destination selected"): await _finish(); return
	if not await _launch_and_land("satellite_recovery", "res://maps/satellite_crash_site.json"): await _finish(); return
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	var root_owner: Node = mission.get_node("SimulationRoot")
	var checkpoint: Dictionary = _flow.get("_campaign_start").call("save_home_checkpoint", _flow, _runtime)
	_check(not checkpoint.get("ok", false), "campaign checkpoint is rejected during real deployed mission")
	# Im Hex-Boden steigt die Besatzung an der Einstiegszelle ein, nicht an der Rumpfmitte.
	var boarding_access: Dictionary = controller.call("get_campaign_ground_ship_access", _craft_id)
	if not _check(boarding_access.get("ok", false), "ship boarding access is available (%s)" % [boarding_access]):
		await _finish()
		return
	var target: Vector2 = Vector2(boarding_access.position)
	var boarding_radius: float = float(controller.get("CAMPAIGN_BOARDING_RADIUS"))
	controller.call("_create_waypoints_for_selected_fireteams", target, true)
	if not _check(bool(controller.call("execute_selected_fireteam_orders")), "real crew receives ship return walk"): await _finish(); return
	if not await _wait(func():
		for id in _crew_ids:
			var person: Node2D = controller.call("_find_friendly_unit_by_id", id)
			if person == null or person.global_position.distance_to(target) > boarding_radius: return false
		return true, 45000, "real crew walks back near landed ship"): await _finish(); return
	var boarded: Dictionary = controller.call("request_campaign_crew_boarding", _craft_id)
	print("LEGACY_SATELLITE_BOARD ", boarded)
	if not _check(boarded.get("ok", false) or String(boarded.get("reason", "")) == "pilot_boarding_pending", "real boarding starts"): await _finish(); return
	if not await _wait(func(): return controller.call("get_campaign_air_support_pilot_guard", _craft_id).get("ok", false), 8000, "actual pilot completes boarding"): await _finish(); return
	await _finish()

func _wait(predicate: Callable, milliseconds: int, label: String) -> bool:
	if label.ends_with("actual mission instance exists"):
		var deadline := Time.get_ticks_msec() + maxi(milliseconds, 60000)
		while Time.get_ticks_msec() < deadline:
			var mission: Node = _flow.call("get_mission_for_craft", _craft_id)
			if is_instance_valid(mission):
				_flow.call("focus_location", String(mission.get_meta("location_id", "")))
				return _check(true, label)
			await physics_frame
		return _check(false, "TIMEOUT " + label)
	return await super._wait(predicate, milliseconds, label)

func _dump(stage: String) -> void:
	print("LEGACY_SATELLITE_DIAGNOSTIC ", stage, " locations=", _flow.call("get_location_runtime_snapshot"), " approach=", _flow.get("_space_approaches"), " view=", _flow.get("_current_meta_view"), " preparation_results=", _flow.get("_surface_preparation_results"), " travel=", _space())

func _finish() -> void:
	if is_instance_valid(_flow): _flow.queue_free()
	await process_frame
	print("CAMPAIGN_LEGACY_SATELLITE_BOARDING passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
