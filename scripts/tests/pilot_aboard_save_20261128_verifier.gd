extends "res://scripts/tests/pilot_stays_aboard_20261127_verifier.gd"
## Paket I (c), 28.11.2026: Speichern im Einsatz mit Pilot an Bord des gelandeten Schiffs.
## Echte Erstlandung, Pilot bleibt an Bord, Trupp draussen. Speichern -> Szene weg -> Fortsetzen: der Pilot ist wieder an Bord (eingeschifft, unsichtbar,
## nicht unter den abgesetzten), der Trupp steht wieder draussen; ein zweites Speichern nach dem Fortsetzen klappt ebenfalls.
## Schlusszeile: PILOT_ABOARD_SAVE passed=N failed=M

func _run() -> void:
	if OS.get_environment("POLISA_TEST_PROFILE").is_empty():
		printerr("isolated test profile required")
		quit(1)
		return
	Engine.time_scale = 4.0
	_configure_entry()
	START.request_start(self, "campaign", "new")
	_flow = FLOW.instantiate(); root.add_child(_flow)
	current_scene = _flow
	await process_frame
	_screen = _flow.get_node("HomebaseScreen"); _runtime = _flow.get("_singleplayer_runtime")
	if not await _prepare_initial_base(): await _end(); return
	var craft: Dictionary = _screen.call("get_operations_snapshot").selected_craft
	_craft_id = String(craft.id); _pilot_id = String(craft.pilot_id)
	_team_id = String(Array(craft.payload_fireteam_ids)[0])
	for team: Dictionary in Array(_screen.call("get_operations_snapshot").fireteams):
		if String(team.id) == _team_id:
			for unit: Dictionary in Array(team.members): _crew_ids.append(String(unit.id))
	_check(_screen.call("request_operation", "accept_job", {"job_id": "satellite_recovery"}).get("ok", false), "Auftrag angenommen")
	_check(_screen.call("request_operation", "select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"}).get("ok", false), "Ziel gewaehlt")
	if not await _launch_and_land("satellite_recovery", "res://maps/satellite_crash_site.json"): await _end(); return
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	_check(not controller.get("_deployed_unit_ids").has(_pilot_id) and controller.get("_embarked_unit_ids").has(_pilot_id), "Vor dem Speichern: Pilot an Bord, nicht abgesetzt")
	# Paket I (a): nach der Landung steht ein vorhandener Anflug-Vorsatz auf "arrived" (Handflug und Automatik gleich).
	var intents: Dictionary = _runtime.get("_surface_orbit_intents")
	_check(intents.is_empty() or String(Dictionary(intents.get(_craft_id, {})).get("status", "arrived")) == "arrived", "Anflug-Vorsatz nach der Landung ist arrived (%s)" % str(intents))
	var units: Node = mission.get_node("UnitRegistry")
	var before := {}
	for id: String in _crew_ids:
		var person: Node2D = controller.call("_get_campaign_sortie_unit", id)
		if person != null: before[id] = {"position": person.global_position, "health": person.get_health(), "visible": person.visible}
	_check(before.size() == _crew_ids.size(), "alle Besatzungsmitglieder gefunden (%d)" % before.size())
	var capture = load("res://scripts/mission/campaign_active_mission_capture.gd")
	var captured: Dictionary = capture.capture_components(_flow, _runtime)
	var deadline := Time.get_ticks_msec() + 30000
	while not captured.get("ok", false) and Time.get_ticks_msec() < deadline and String(captured.get("reason", "")) in ["checkpoint_pending_work", "checkpoint_clock_unsynced", "checkpoint_pending_setup", "mission_lifecycle_busy", "mission_movement_pending", "transport_transition_pending"]:
		await create_timer(0.1).timeout
		captured = capture.capture_components(_flow, _runtime)
	if not _check(captured.get("ok", false), "Erfassen mit Pilot an Bord klappt (%s)" % str(captured.get("reason", ""))):
		print("CAPTURE_FAILURE ", captured); await _end(); return
	_check(Array(captured.components.active_ids).has(_pilot_id) and Array(captured.components.active_ids).size() == _crew_ids.size(), "Erfasste Kennungen enthalten den Piloten (%s)" % str(captured.components.active_ids))
	var menu: Node = root.get_node("GlobalEscapeMenu")
	var saved: Dictionary = menu.call("save_current_mission_slot")
	if not _check(saved.get("ok", false), "Speichern im Einsatz mit Pilot an Bord"): print("SAVE_FAILURE ", saved); await _end(); return
	_flow.queue_free()
	await process_frame
	START.request_start(self, "campaign", "continue")
	_flow = FLOW.instantiate(); root.add_child(_flow)
	current_scene = _flow
	await process_frame
	_screen = _flow.get_node("HomebaseScreen"); _runtime = _flow.get("_singleplayer_runtime")
	if not await _wait(func(): return bool(_flow.get_meta("campaign_active_restore_complete", false)) or _flow.has_meta("campaign_active_restore_error"), 60000, "Wiederherstellung kommt zu einer Entscheidung"): await _end(); return
	if not _check(bool(_flow.get_meta("campaign_active_restore_complete", false)) and is_instance_valid(_flow.get("_active_mission")), "Einsatz mit Pilot an Bord wird wiederhergestellt"):
		print("RESTORE_FAILURE ", _flow.get_meta("campaign_active_restore_error", {})); await _end(); return
	var restored: Node = _flow.get("_active_mission")
	var rc: Node = restored.get_node("TacticalController")
	_check(not rc.get("_deployed_unit_ids").has(_pilot_id) and rc.get("_embarked_unit_ids").has(_pilot_id), "Nach dem Fortsetzen: Pilot an Bord, nicht abgesetzt")
	var pilot: Node = rc.call("_get_campaign_sortie_unit", _pilot_id)
	_check(pilot != null and bool(pilot.get_meta("dropship_embarked", false)) and not pilot.visible, "Nach dem Fortsetzen: Pilot ist eingeschifft und unsichtbar")
	_check(bool(rc.call("get_campaign_pilot_flight_guard", _craft_id, false).get("ok", false)), "Nach dem Fortsetzen: der Flugwaechter sieht den Piloten an Bord")
	for id: String in _crew_ids:
		if id == _pilot_id: continue
		var person: Node2D = rc.call("_get_campaign_sortie_unit", id)
		_check(person != null and rc.get("_deployed_unit_ids").has(id) and person.global_position.distance_to(before[id].position) < 0.1 and person.get_health() == before[id].health, "Nach dem Fortsetzen: %s steht wieder an seinem Platz" % id)
	var occ: Dictionary = rc.call("get_campaign_craft_occupancy", _craft_id)
	_check(int(occ.get("pilot_aboard", -1)) == 1, "Nach dem Fortsetzen: Belegung zeigt Pilot 1 an Bord (%s)" % str(occ))
	# Zweites Speichern nach dem Fortsetzen.
	var again: Dictionary = capture.capture_components(_flow, _runtime)
	deadline = Time.get_ticks_msec() + 30000
	while not again.get("ok", false) and Time.get_ticks_msec() < deadline and String(again.get("reason", "")) in ["checkpoint_pending_work", "checkpoint_clock_unsynced", "checkpoint_pending_setup", "mission_lifecycle_busy", "mission_movement_pending", "transport_transition_pending"]:
		await create_timer(0.1).timeout
		again = capture.capture_components(_flow, _runtime)
	_check(again.get("ok", false), "Zweites Erfassen nach dem Fortsetzen klappt (%s)" % str(again.get("reason", "")))
	await _end()

func _end() -> void:
	print("PILOT_ABOARD_SAVE passed=%d failed=%d" % [_passed, _failed])
	await _finish()
