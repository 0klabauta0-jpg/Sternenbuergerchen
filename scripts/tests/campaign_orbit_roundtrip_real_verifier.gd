extends "res://scripts/tests/campaign_air_support_real_mission_verifier.gd"
## Regular campaign controls and original people at normal speed. The single
## opt-in enables the not-yet-released orbit path; it does not alter actors.

func _run() -> void:
	_configure_entry()
	_flow = FLOW.instantiate(); root.add_child(_flow)
	await process_frame
	_screen = _flow.get_node("HomebaseScreen"); _runtime = _flow.get("_singleplayer_runtime")
	_runtime.set("_surface_orbit_path_enabled", true)
	if not await _prepare_initial_base(): await _finish(); return
	var craft: Dictionary = _screen.call("get_operations_snapshot").get("selected_craft", {})
	_craft_id = String(craft.get("id", "")); _pilot_id = String(craft.get("pilot_id", ""))
	var payload: Array = craft.get("payload_fireteam_ids", [])
	if not _check(not _craft_id.is_empty() and not payload.is_empty(), "actual ship and fireteam available"): await _finish(); return
	_team_id = String(payload[0])
	for team: Dictionary in Array(_screen.call("get_operations_snapshot").get("fireteams", [])):
		if String(team.id) == _team_id:
			for member: Dictionary in Array(team.members): _crew_ids.append(String(member.id))
	if not _check(_screen.call("request_operation", "accept_job", {"job_id":"satellite_recovery"}).get("ok", false), "actual mission accepted"): await _finish(); return
	if not _check(_screen.call("request_operation", "select_destination", {"location_id":"satellite_crash", "job_id":"satellite_recovery"}).get("ok", false), "actual destination selected"): await _finish(); return
	if not await _launch_and_land("satellite_recovery", "res://maps/satellite_crash_site.json"): await _finish(); return
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	var boarding: Dictionary = controller.call("request_campaign_crew_boarding", _craft_id)
	if not _check(boarding.get("ok", false) or boarding.get("reason") == "pilot_boarding_pending", "actual crew begins boarding for an aborted visit"): await _finish(); return
	if not await _wait(func(): return controller.call("get_campaign_pilot_flight_guard", _craft_id).get("ok", false), 12000, "actual crew boards before aborting visit"): await _finish(); return
	var departure: Dictionary = _runtime.call("request_operation", "return_homebase", {"craft_id":_craft_id})
	if not _check(departure.get("ok", false), "actual return command accepts aborted visit"): print("RETURN_RESULT ", departure); await _finish(); return
	var destination_orbit := String(Dictionary(_space().get("location_orbits", {})).get("satellite_crash", ""))
	if not await _wait(func(): return String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == destination_orbit, 45000, "actual departure returns ship to local destination orbit"): await _finish(); return
	var jump: Dictionary = _screen.call("request_operation", "space_start_quantum", {"craft_id":_craft_id, "target_orbit_id":"moon_orbit"})
	if not _check(jump.get("ok", false), "actual homeward warp command accepted"): print("HOME_WARP_RESULT ", jump); await _finish(); return
	if not await _wait(func(): return String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == "moon_orbit", 180000, "actual outbound orbit transit and homeward warp reach moon"): await _finish(); return
	var land: Dictionary = _screen.call("request_operation", "space_land_homebase", {"craft_id":_craft_id})
	if not _check(land.get("ok", false), "actual homebase landing accepted"): print("HOME_LAND_RESULT ", land); await _finish(); return
	await _wait(func():
		var current: Dictionary = _flow.call("get_singleplayer_snapshot")
		var current_craft: Dictionary = _craft(current)
		return String(current_craft.get("location_id", "")) == "homebase" and not bool(current_craft.get("busy", true)), 45000, "actual original craft returns to homebase")
	await _finish()
