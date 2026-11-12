extends "res://scripts/tests/campaign_five_actual_sorties_verifier.gd"
## Real commands and owners, with prior chapter progression explicitly skipped.

func _run() -> void:
	Engine.time_scale = 4.0
	START.request_start(self, "campaign", "new")
	_flow = FLOW.instantiate(); root.add_child(_flow)
	await process_frame
	_screen = _flow.get_node("HomebaseScreen"); _runtime = _flow.get("_singleplayer_runtime")
	if not await _prepare_initial_base(): await _end_route(); return
	_runtime.get("_campaign").set("_enforce_sequence", false)
	_runtime.get("_onboarding").set("_stage_index", 5)
	if not _check(_runtime.call("request_operation", "accept_job", {"job_id":"buccaneer_rescue"}).get("ok", false), "fixture unlocked rescue accepted"): await _end_route(); return
	if not _check(_runtime.call("request_operation", "select_destination", {"location_id":"distress_orbit", "job_id":"buccaneer_rescue"}).get("ok", false), "rescue destination selected"): await _end_route(); return
	if not _check(_screen.call("request_operation", "start", {"craft_id":_craft_id}).get("ok", false), "real boarded launch"): await _end_route(); return
	if not await _wait(func(): return _space().get("phase") == "orbit" and _space().get("orbit_id") == "moon_orbit", 30000, "home orbit"): await _end_route(); return
	if not _check(_runtime.call("request_operation", "space_start_quantum", {"craft_id":_craft_id, "target_orbit_id":"planet_orbit"}).get("ok", false), "outbound warp"): await _end_route(); return
	if not await _wait(func(): return _space().get("phase") == "orbit" and _space().get("orbit_id") == "planet_orbit", 15000, "distress orbit"): await _end_route(); return
	if not _check(_runtime.call("request_operation", "space_begin_approach", {"craft_id":_craft_id, "location_id":"distress_orbit"}).get("ok", false), "real encounter approach"): await _end_route(); return
	if not await _wait(func(): return _runtime.call("get_snapshot").space_encounter.get("phase") == "combat", 15000, "real encounter entry"): await _end_route(); return
	if not _check(_runtime.call("request_operation", "campaign_space_engage", {}).get("ok", false), "real attack order"): await _end_route(); return
	if not await _wait(func(): return _runtime.call("get_snapshot").space_encounter.get("phase") in ["rescue_ready", "defeat"], 30000, "combat outcome"): await _end_route(); return
	if not _check(_runtime.call("get_snapshot").space_encounter.get("phase") == "rescue_ready", "neutral survives and hostile destroyed"): await _end_route(); return
	var crew_before := Array(_flow.get("_all_team_units")).size()
	if not _check(_runtime.call("request_operation", "campaign_space_rescue", {}).get("ok", false), "rescue command"): await _end_route(); return
	if not _check(_campaign().jobs.buccaneer_rescue.status == "completed" and Array(_flow.get("_all_team_units")).size() == crew_before + 1, "mission result and rescued pilot recorded"): await _end_route(); return
	if not _check(_space().get("phase") == "orbit" and _space().get("orbit_id") == "planet_orbit", "return to local orbit"): await _end_route(); return
	if not _check(_runtime.call("request_operation", "space_start_quantum", {"craft_id":_craft_id, "target_orbit_id":"moon_orbit"}).get("ok", false), "return warp"): await _end_route(); return
	if not await _wait(func(): return _space().get("phase") == "orbit" and _space().get("orbit_id") == "moon_orbit", 15000, "homeward arrival"): await _end_route(); return
	if not _check(_runtime.call("request_operation", "space_land_homebase", {"craft_id":_craft_id}).get("ok", false), "home landing accepted"): await _end_route(); return
	await _wait(func():
		var craft: Dictionary = _craft(_flow.call("get_singleplayer_snapshot"))
		return craft.get("location_id") == "homebase" and not bool(craft.get("busy", true)), 35000, "actual craft returns home")
	await _end_route()

func _end_route() -> void:
	if is_instance_valid(_flow): _flow.queue_free()
	await process_frame
	print("CAMPAIGN_SPACE_ACTUAL_ROUTE passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
