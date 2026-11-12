extends "res://scripts/tests/campaign_intro_loop_smoke.gd"
## Background probe: actual campaign route, crew, mission and card buttons.

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
	var boarded: Dictionary = controller.call("request_campaign_crew_boarding", _craft_id)
	print("AIR_PROBE_BOARD ", boarded)
	if not _check(boarded.get("ok", false) or String(boarded.get("reason", "")) == "pilot_boarding_pending", "real boarding starts"): await _finish(); return
	if not await _wait(func(): return controller.call("get_campaign_air_support_pilot_guard", _craft_id).get("ok", false), 8000, "actual pilot completes boarding"): await _finish(); return
	var before: Dictionary = _runtime.get("_travel").get_flight_state(_craft_id).get_snapshot()
	controller.call("_refresh_mission_dropship_panel")
	var details: Button = mission.get_node_or_null("TacticalUI/MissionDropshipPanel/CompactCard/Contents/Header/DetailsButton")
	if not _check(details != null and not details.disabled, "actual dropship details control is available"): await _finish(); return
	details.pressed.emit()
	await process_frame
	var start_button: Button
	for candidate in mission.find_children("*", "Button", true, false):
		if candidate.get_meta("mission_dropship_card_command", "") == "air_start" and candidate.get_meta("mission_dropship_craft_id", "") == _craft_id:
			start_button = candidate
			break
	var popup: PopupPanel = mission.get_node_or_null("TacticalUI/A5DropshipDetailsPopup")
	print("AIR_PROBE_UI button=", start_button, " popup_visible=", popup.visible if popup != null else false, " tactical_visible=", controller.get("_tactical_ui_visible"), " source=", root_owner.get("_air_support_source"))
	var panel: Node = mission.get_node_or_null("TacticalUI/A5DropshipDetailsPopup/Contents/Scroll/A5DropshipFullPanel")
	print("AIR_PROBE_UI_PANEL children=", panel.get_child_count() if panel != null else -1, " cards=", controller.call("_get_mission_dropship_card_entries"), " location=", mission.get_meta("location_id", ""))
	if not _check(start_button != null and not start_button.disabled and start_button.is_visible_in_tree(), "real air-start button is visible and enabled"): await _finish(); return
	start_button.pressed.emit()
	var airborne: bool = root_owner.call("is_air_support_craft_airborne", _craft_id)
	_check(airborne, "actual dropship card starts the fleet flight")
	print("AIR_PROBE_START airborne=", airborne, " feedback=", controller.get("_last_command_text"), " before=", before)
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
	print("AIR_PROBE_DIAGNOSTIC ", stage, " locations=", _flow.call("get_location_runtime_snapshot"), " approach=", _flow.get("_space_approaches"), " view=", _flow.get("_current_meta_view"))

func _finish() -> void:
	if is_instance_valid(_flow): _flow.queue_free()
	await process_frame
	print("CAMPAIGN_AIR_SUPPORT_REAL passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
