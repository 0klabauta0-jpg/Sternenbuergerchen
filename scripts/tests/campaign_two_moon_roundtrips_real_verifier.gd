extends "res://scripts/tests/campaign_air_support_real_mission_verifier.gd"
## Actual campaign progression, original actors and normal simulation speed.
## Orbit opt-in is explicit; no mission result, health, pose or unlock is edited.

func _run() -> void:
	_configure_entry()
	_flow = FLOW.instantiate(); root.add_child(_flow)
	await process_frame
	_screen = _flow.get_node("HomebaseScreen"); _runtime = _flow.get("_singleplayer_runtime")
	_runtime.set("_surface_orbit_path_enabled", true)
	if not await _prepare_initial_base(): await _finish(); return
	var operations: Dictionary = _screen.call("get_operations_snapshot")
	var craft: Dictionary = operations.get("selected_craft", {})
	_craft_id = String(craft.get("id", "")); _pilot_id = String(craft.get("pilot_id", ""))
	var payload: Array = craft.get("payload_fireteam_ids", [])
	if not _check(not _craft_id.is_empty() and not payload.is_empty(), "original ship and team available"): await _finish(); return
	_team_id = String(payload[0])
	for team: Dictionary in Array(operations.get("fireteams", [])):
		if String(team.id) == _team_id:
			for member: Dictionary in Array(team.members): _crew_ids.append(String(member.id))
	if not _check(_screen.call("request_operation", "accept_job", {"job_id":"satellite_recovery"}).get("ok", false), "accept actual satellite job"): await _finish(); return
	if not _check(_screen.call("request_operation", "select_destination", {"location_id":"satellite_crash", "job_id":"satellite_recovery"}).get("ok", false), "select actual Glut 1a destination"): await _finish(); return
	if not _check(_check_large_map("res://maps/satellite_crash_site.json"), "satellite uses actual 512x256 map"): await _finish(); return
	if not await _launch_and_land("satellite_recovery", "res://maps/satellite_crash_site.json"): await _finish(); return
	var mission: Node = _flow.get("_active_mission")
	mission.get_node("TacticalController").call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
	if not await _move_and_use(mission, "satellite_data", "secure_satellite", "res://maps/satellite_crash_site.json"): await _finish(); return
	if not await _move_and_use(mission, "ship_return", "return_to_ship", "res://maps/satellite_crash_site.json"): await _finish(); return
	if not await _return_to_home("satellite_crash"): await _finish(); return
	_flow.call("_show_homebase")
	var uploaded: Dictionary = _runtime.call("request_operation", "campaign_upload", {"job_id":"satellite_recovery"})
	if not _check(uploaded.get("ok", false) and String(_campaign().jobs.satellite_recovery.status) == "completed", "real recovered chip uploaded at home"): print("UPLOAD_RESULT ", uploaded); await _finish(); return
	var checkpoint: Dictionary = _flow.get("_campaign_start").call("save_home_checkpoint", _flow, _runtime, true)
	print("REAL_UPLOAD_CHECKPOINT ", checkpoint)
	if checkpoint.get("ok", false):
		var loaded: Dictionary = STORE.load_checkpoint()
		var loaded_campaign: Dictionary = Dictionary(loaded.get("payload", {})).get("campaign", {})
		var loaded_jobs: Dictionary = loaded_campaign.get("jobs", {})
		_check(loaded.get("ok", false) and String(Dictionary(loaded_jobs.get("satellite_recovery", {})).get("status", "")) == "completed", "real home checkpoint retains completed satellite job")
	var fuel: float = float(_supply().fuel_by_craft_id[_craft_id])
	if fuel < 100.0 and not _check(_runtime.call("request_operation", "refuel", {"craft_id":_craft_id, "amount":100.0-fuel}).get("ok", false), "actual ship refueled"): await _finish(); return
	if not await _prepare_sortie_base(): await _finish(); return
	if not _check(_screen.call("request_operation", "accept_job", {"job_id":"outpost_recovery"}).get("ok", false), "accept legitimately unlocked outpost job"): await _finish(); return
	if not _check(_screen.call("request_operation", "select_destination", {"location_id":"trade_outpost", "job_id":"outpost_recovery"}).get("ok", false), "select actual Glut 1b destination"): await _finish(); return
	if not _check(_check_large_map("res://maps/trade_outpost.json"), "trade outpost uses actual 512x256 map"): await _finish(); return
	if not await _launch_and_land("outpost_recovery", "res://maps/trade_outpost.json"): await _finish(); return
	mission = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	var board: Dictionary = controller.call("request_campaign_crew_boarding", _craft_id)
	if not _check(board.get("ok", false) or board.get("reason") == "pilot_boarding_pending", "actual crew begins boarding at outpost"): await _finish(); return
	if not await _wait(func(): return controller.call("get_campaign_pilot_flight_guard", _craft_id).get("ok", false), 30000, "actual crew boards at outpost"): await _finish(); return
	var leave: Dictionary = _runtime.call("request_operation", "return_homebase", {"craft_id":_craft_id})
	if not _check(leave.get("ok", false), "actual return command aborts outpost visit"): print("OUTPOST_RETURN ", leave); await _finish(); return
	await _return_to_home("trade_outpost")
	await _finish()

func _check_large_map(path: String) -> bool:
	var map = MAP.load_from_file(path)
	return map != null and map.get_grid_size() == Vector2i(512, 256) and map.get_tiles().size() == 131072

func _return_to_home(location_id: String) -> bool:
	var orbit := String(Dictionary(_space().get("location_orbits", {})).get(location_id, ""))
	if not await _wait(func(): return String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == orbit, 60000, "actual ship reaches departure orbit"): return false
	var jump: Dictionary = _screen.call("request_operation", "space_start_quantum", {"craft_id":_craft_id, "target_orbit_id":"moon_orbit"})
	if not _check(jump.get("ok", false), "actual home warp command accepted"): print("HOME_WARP ", jump); return false
	if not await _wait(func(): return String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == "moon_orbit", 180000, "actual outbound transit and warp reach home orbit"): return false
	var land: Dictionary = _screen.call("request_operation", "space_land_homebase", {"craft_id":_craft_id})
	if not _check(land.get("ok", false), "actual home landing accepted"): print("HOME_LAND ", land); return false
	return await _wait(func():
		var state: Dictionary = _flow.call("get_singleplayer_snapshot")
		var ship: Dictionary = _craft(state)
		return String(ship.get("location_id", "")) == "homebase" and not bool(ship.get("busy", true)), 60000, "original ship physically returns home")

func _move_and_use(mission: Node, interaction: String, step: String, map_path: String) -> bool:
	var controller: Node = mission.get_node("TacticalController")
	var driver: Node = mission.get_node("CombatLoopDriver")
	var map = MAP.load_from_file(map_path)
	var target: Vector2 = map.get_marker_position(interaction)
	if interaction == "ship_return": target = controller.call("_campaign_landed_craft_position", _craft_id)
	controller.call("_create_waypoints_for_selected_fireteams", target, true)
	if not _check(controller.call("execute_selected_fireteam_orders"), interaction + " real movement command accepted"): return false
	if not await _wait(func():
		if not is_instance_valid(controller): return false
		return String(_find_interaction(controller.call("get_mission_interaction_runtime_use_state_snapshot"), interaction).get("runtime_use_status", "")) == "usable", 180000, interaction + " becomes usable after actual walk"): return false
	var use: Dictionary = controller.call("create_selected_mission_interaction_use_intent", interaction)
	if not _check(use.get("accepted", false) and controller.call("execute_selected_fireteam_orders"), interaction + " actual timed use ordered"): return false
	return await _wait(func():
		if is_instance_valid(driver):
			return PackedStringArray(driver.call("get_mission_scenario_runtime_gate_snapshot").get("completed_step_ids", [])).has(step) or bool(Dictionary(driver.call("get_mission_interaction_runtime_states").get(interaction, {})).get("complete", false))
		return step == "return_to_ship" and String(Dictionary(_campaign().get("jobs", {})).get("satellite_recovery", {}).get("status", "")) in ["pending_upload", "completed"], 90000, interaction + " actual timed use completes")

func _finish() -> void:
	if is_instance_valid(_flow): _flow.queue_free()
	await process_frame
	print("CAMPAIGN_TWO_MOON_ROUNDTRIPS passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
