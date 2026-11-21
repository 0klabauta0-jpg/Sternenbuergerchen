extends "res://scripts/tests/campaign_respawn_pickup_verifier.gd"
## R4c Fix-Runde 2 (K1 und W2 a): Belege mit einer frueher ANGEWORBENEN (Kennung polisa_recruit_...), echter Flug, echte Operationen.
## R1 Ein Besuch ganz durch: sie stirbt (respawning); waehrend der Uhr erscheint sie nicht als Bewohnerin, ist nicht uebernehmbar
##    (Grund resident_unavailable), die Aufnahme am Setup lehnt sie ab und der echte register_polisa_resident laesst sie nicht zu. Die Uhr laeuft
##    ueber den echten Takt des Flows ab (awaiting_pickup); dann erscheint sie, wird uebernommen, steigt ein, der Abflug bindet sie (active, Ausfalldaten leer,
##    Grundausstattung, respawns_used gleich). Der Anwerbe-Abschluss (Credits, Reservierungen, Kadergroesse, Eintraege) laeuft nicht ein zweites Mal.
## R2 Flow-Schleife: Uebernommen und eingestiegen, dann steht sie beim Abflug (Zustand direkt gesetzt) wieder auf respawning: der Abflug bindet sie nicht,
##    schliesst aber ab; Basis-Zustand bleibt station.
## R3 Direkte Pruefungen je Stelle (die Zulassung am Setup deckt die anderen Stellen im Spiel ab, darum wird jede Funktion einzeln mit einer Person
##    in respawning angesprochen, die die vorgeschalteten Stellen schon passiert hat): station_claim_resident, _restore_polisa_residents,
##    register_polisa_resident des echten Controllers.
## R4 W2 (a): uebernommen und eingestiegen, der Besuch endet ohne bestaetigten Abflug (Spiel beendet, Fortsetzen); sie ist awaiting_pickup und station,
##    nichts halb gesetzt; der naechste Besuch bietet sie wieder an und holt sie ab.
## Abschlusszeile: CAMPAIGN_RESPAWN_PICKUP_RECRUIT passed=%d failed=%d
## Einzeln starten: Kommandozeilenargument nach "--" (zum Beispiel "-- R3").

const RK_GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const RK_ID := "polisa_recruit_k1_real"

func _run() -> void:
	var verdict: Dictionary = RK_GUARD.verdict_from_environment()
	if not bool(verdict.get("ok", false)):
		print("CAMPAIGN_RESPAWN_PICKUP_RECRUIT refused: needs a throwaway profile (SB_REVIEW2_USER_DIR), nothing written. Reason: %s" % str(verdict.get("reason", "")))
		quit(2)
		return
	_configure_entry()
	var selected: Array = []
	for arg: String in OS.get_cmdline_user_args():
		if not arg.strip_edges().is_empty():
			selected.append(arg.strip_edges().to_upper())
	for scenario: String in ["R1", "R2", "R3", "R4"]:
		if not selected.is_empty() and not selected.has(scenario):
			continue
		print("--- ", scenario)
		await call("_rk_" + scenario.to_lower())
		await _end_sortie()
	print("CAMPAIGN_RESPAWN_PICKUP_RECRUIT passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

## Kampagne mit vier Personen plus einer frueher Angeworbenen (Kennung) im zweiten Trupp, ueber die echte Aufnahme in den Kader.
var _rk_minimal := false

## minimal: nur A, Pilot und die Angeworbene (der Speicherpunkt verlangt ab fuenf Personen einen Kaufbeleg fuer jede weitere Person; B und C haben keinen).
func _rk_setup() -> bool:
	if _rk_minimal:
		if not await _t6b_open("campaign", "new"): return false
		_rk_find_team()
	elif not await _t6b_new_four(): return false
	var profile: Dictionary = _roster_unit(LEAD_A if _rk_minimal else SHOOTER_C).duplicate(true)
	if _rk_minimal:
		profile["roster_role_category"] = "operator"
		profile["role_name"] = "Rifleman"
		profile["skill_leadership"] = 0.0
		if typeof(profile.get("skill_values")) == TYPE_DICTIONARY:
			profile["skill_values"]["leadership"] = 0.0
	profile["unit_id"] = RK_ID
	profile["display_name"] = "Rita Reuig"
	profile["fireteam_id"] = ""
	var added: Dictionary = _flow.call("register_campaign_recruit", profile)
	if not _check(bool(added.get("ok", false)), "Aufbau: die Angeworbene kommt in den Kader (%s)" % [added]): return false
	var simulation: Node = _runtime.get("_simulation")
	simulation.call("request_personnel_loadout_command", "configure_roster", {"roster": [profile]})
	simulation.call("request_personnel_loadout_command", "set_loadout", {"unit_id": RK_ID, "loadout": {"armor": "suit", "weapon_1": "pistol", "weapon_2": "none"}})
	_runtime.get("_supply").call("configure_inventory", [RK_ID], [], true)
	# Der Kaufbeleg der Anwerbung (Abschluss), wie ihn die echte Anwerbung im Versorgungsstand hinterlaesst (Muster: campaign_casualty_roster_verifier Z17).
	var reserve_signature: String = JSON.stringify({"operation": "station_recruit_reserve", "payload": {"offer_id": "offer-k1"}}, "", true)
	Dictionary(_runtime.get("_supply").get("_requests"))["reserve-k1"] = {"signature": reserve_signature, "result": {"ok": true, "operation": "station_recruit_reserve", "state": "pending", "request_id": "reserve-k1", "unit_id": RK_ID, "offer_id": "offer-k1", "cost": 300, "location_id": "polisa", "profile": {"unit_id": RK_ID}}}
	var final_signature: String = JSON.stringify({"operation": "station_recruit_finalize", "payload": {"reservation_id": "reserve-k1"}}, "", true)
	Dictionary(_runtime.get("_supply").get("_requests"))["final-k1"] = {"signature": final_signature, "result": {"ok": true, "operation": "station_recruit_finalize", "request_id": "final-k1", "reservation_id": "reserve-k1", "offer_id": "offer-k1", "unit_id": RK_ID, "cost": 300, "location_id": "polisa"}}
	if _rk_minimal:
		var added_team: Dictionary = _screen.call("request_operation", "add_fireteam", {})
		if not _check(bool(added_team.get("ok", false)), "Aufbau: zweiter Trupp angelegt (%s)" % [added_team]): return false
	var team_two := ""
	for team: Dictionary in Array(Dictionary(_screen.call("get_operations_snapshot")).get("fireteams", [])):
		if String(team.id) != _team_id:
			team_two = String(team.id)
	var assigned: Dictionary = _screen.call("request_operation", "assign", {"unit_id": RK_ID, "fireteam_id": team_two})
	if not _check(bool(assigned.get("ok", false)), "Aufbau: die Angeworbene im zweiten Trupp (%s)" % [assigned]): return false
	_flow.call("_sync_wound_lock")
	_flow.set("_active_singleplayer_identity", {})
	return _check(_ra_base_status(RK_ID) in ["idle", "outside", "moving", "sleeping"] or not _ra_base_status(RK_ID).is_empty(), "Aufbau: die Basis kennt die Angeworbene (%s)" % _ra_base_status(RK_ID))

func _rk_die() -> void:
	var states: Array = []
	if _rk_minimal:
		for unit_id: String in [LEAD_A, PILOT_ID]:
			states.append(_state(unit_id, "fit", false))
	else:
		states = _t6b_states({})
	states.append(_state(RK_ID, "down", false))
	_flow.call("_apply_campaign_casualties", _ra_result(states, "aborted", 3))

## Die Uhr der Wartenden laeuft ueber den echten Takt des Flows ab (kurze Restzeit gesetzt, dann gewartet; kein advance() von Hand).
func _rk_let_clock_run_out(unit_id: String) -> bool:
	var recovery: Dictionary = Dictionary(_pk_roster_field(unit_id, "recovery_state")).duplicate(true)
	recovery["seconds_remaining"] = 2.0
	_ra_set(unit_id, {"recovery_state": recovery})
	return await _pk_wait(func(): return String(_pk_roster_field(unit_id, "availability_status")) == "awaiting_pickup", 30000)

func _rk_markers() -> Dictionary:
	var base_ids: Array = _t6b_base_ids()
	var count := 0
	for unit: Dictionary in Array(_flow.get("_all_team_units")):
		if String(unit.get("unit_id", "")) == RK_ID: count += 1
	var supply_state: Dictionary = Dictionary(_runtime.get("_supply").call("export_state"))
	return {"credits": int(supply_state.get("credits", -1)), "pending": Dictionary(_runtime.get("_polisa_recruit_pending")).size(),
		"roster": Array(_flow.get("_all_team_units")).size(), "entries": count, "base": base_ids.size(), "requests": Dictionary(supply_state.get("requests", {})).size()}

func _rk_find_team() -> void:
	for team: Dictionary in Array(Dictionary(_screen.call("get_operations_snapshot")).get("fireteams", [])):
		if Array(team.get("members", [])).has(LEAD_A) or Array(team.get("members", [])).any(func(member: Variant) -> bool: return typeof(member) == TYPE_DICTIONARY and String(Dictionary(member).get("id", "")) == LEAD_A):
			_team_id = String(team.id)

## Wie _pk_board_home_crew (P1), aber ohne B, wenn der Aufbau nur A, Pilot und die Angeworbene hat.
func _rk_board_home_crew() -> bool:
	if not _rk_minimal:
		return await _pk_board_home_crew()
	_craft_id = String(Dictionary(Array(_flow.get("_homebase_aircraft_definitions"))[0]).get("craft_id", ""))
	var personnel: Node = _t6b_base()
	var at_home: bool = await _pk_wait(func(): return bool(personnel.call("_unit_is_home", LEAD_A)) and bool(personnel.call("_unit_is_home", PILOT_ID)), 30000)
	if not _check(at_home, "Flug: A und der Pilot stehen an der Basis"): return false
	var team_board: Dictionary = _screen.call("request_operation", "board", {"craft_id": _craft_id, "fireteam_id": _team_id, "unit_id": LEAD_A})
	if not _check(bool(team_board.get("ok", false)), "Flug: der Trupp wird dem Schiff zugeteilt (%s)" % [team_board]): return false
	var walk: Dictionary = _screen.call("request_operation", "base_board", {"craft_id": _craft_id, "fireteam_id": _team_id, "unit_id": LEAD_A, "whole_fireteam": true})
	if not _check(bool(walk.get("ok", false)), "Flug: die Besatzung geht an Bord (%s)" % [walk]): return false
	var sim: Node = personnel.call("get_simulation_root")
	for tick in range(6000):
		if personnel.call("is_pilot_aboard", _craft_id) and bool(_screen.call("_has_homebase_direct_launch_payload_for_craft", _craft_id)):
			break
		sim.call("_physics_process", 0.05)
		_screen.call("_debug_advance_homebase_direct_boarding", 0.05)
	return _check(bool(personnel.call("is_pilot_aboard", _craft_id)) and bool(_screen.call("_has_homebase_direct_launch_payload_for_craft", _craft_id)), "Flug: Pilot und Nutzlast sind an Bord")

## Flug von der Basis nach Polisa bis zur Landung und zum Ausstieg der Besatzung (wie P1, echte Operationen).
func _rk_fly_to_polisa() -> Dictionary:
	if not await _rk_board_home_crew(): return {}
	var result: Dictionary = _pk_op("select_destination", {"location_id": "polisa", "job_id": ""})
	if not _check(bool(result.get("ok", false)), "Flug: Polisa als Besuch ohne Auftrag gewaehlt (%s)" % [result]): return {}
	result = _pk_op("start")
	if not _check(bool(result.get("ok", false)), "Flug: das Schiff startet (%s)" % [result]): return {}
	result = _pk_op("space_start_quantum", {"target_orbit_id": "polisa_orbit"})
	if not _check(bool(result.get("ok", false)), "Flug: Quantenflug nach Polisa (%s)" % [result]): return {}
	if not _check(await _pk_wait(func(): return String(_pk_space().get("orbit_id", "")) == "polisa_orbit", 20000), "Flug: Ankunft im Orbit von Polisa"): return {}
	result = _pk_op("space_begin_approach", {"location_id": "polisa"})
	if not _check(bool(result.get("ok", false)), "Flug: Anflug auf Polisa (%s)" % [result]): return {}
	if not _check(await _pk_wait(func(): return is_instance_valid(_flow.get("_active_mission")), 60000), "Flug: die Polisa-Szene laedt"): return {}
	_flow.call("_show_mission")
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	if not _check(await _pk_wait(func(): return String(controller.call("_find_mission_dropship_card_entry", _craft_id).get("state", "")) == "waiting", 90000), "Flug: das Schiff erreicht die Landeauswahl"): return {}
	var map = load("res://scripts/terrain/terrain_map_data.gd").load_from_file("res://maps/polisa_station.json")
	var view: Node = mission.get_node("Primary3DView")
	var pad: Vector2 = map.get_marker_position("polisa_pad_01")
	view.call("focus_world_position", pad)
	controller.call("_on_mission_dropship_card_set_lz_pressed", _craft_id)
	if not _check(bool(controller.call("_place_lz_from_screen_position", view.call("world_to_screen_position", pad))), "Flug: Landeplatz der Station gewaehlt"): return {}
	controller.call("_on_mission_dropship_card_drop_pressed", _craft_id)
	if not _check(await _pk_wait(func(): return bool(controller.call("_is_parked_campaign_dropship", _craft_id)), 90000), "Flug: das Schiff landet auf Polisa"): return {}
	var crew: PackedStringArray = controller.call("_campaign_craft_crew_ids", _craft_id)
	if not _check(not crew.is_empty() and await _pk_wait(func():
		var deployed: Dictionary = controller.get("_deployed_unit_ids")
		for id in crew:
			if not deployed.has(id): return false
		return true, 60000), "Flug: die ganze Besatzung steigt aus"): return {}
	_check(not crew.has(RK_ID), "Flug: die Angeworbene gehoert nicht zur Besatzung (%s)" % [crew])
	return {"mission": mission, "controller": controller, "registry": mission.get_node("UnitRegistry"), "simulation": mission.get_node("SimulationRoot")}

func _rk_is_resident(visit: Dictionary) -> bool:
	var mission: Node = visit.mission
	return Dictionary(mission.get_meta("singleplayer_station_personnel", {})).has(RK_ID) and visit.registry.get_unit(RK_ID) != null and not visit.simulation.call("get_hex_unit_state", RK_ID).is_empty()

## Uebernehmen, zum Schiff setzen (wie P1: _place_at), einsteigen. Gibt false zurueck, wenn ein Schritt scheitert.
func _rk_claim_and_board(visit: Dictionary) -> bool:
	var claim: Dictionary = _runtime.call("request_operation", "station_claim_resident", {"craft_id": _craft_id, "unit_id": RK_ID})
	if not _check(bool(claim.get("ok", false)), "Besuch: die Angeworbene wird fuer dieses Schiff uebernommen (%s)" % [claim]): return false
	_check(_ra_base_status(RK_ID) == "station" and String(_pk_roster_field(RK_ID, "availability_status")) == "awaiting_pickup", "Besuch: uebernommen, aber noch nicht abgeflogen: awaiting_pickup und station")
	var access: Dictionary = visit.controller.call("get_campaign_ground_ship_access", _craft_id)
	if not _check(bool(access.get("ok", false)) and _place_at(visit.simulation, access, RK_ID, Vector2.ZERO), "Besuch: sie steht am Schiff (Zugang %s)" % [access]): return false
	var result: Dictionary = _runtime.call("request_operation", "station_board_crew", {"craft_id": _craft_id, "service_location_id": "polisa"})
	return _check(await _pk_wait(func(): return bool(visit.controller.call("get_campaign_pilot_flight_guard", _craft_id).get("ok", false)) and bool(visit.registry.get_unit(RK_ID).get_meta("dropship_embarked", false)), 90000), "Besuch: die Besatzung und die Angeworbene steigen ein (%s)" % [result])

func _rk_depart_to_orbit() -> bool:
	var result: Dictionary = _runtime.call("request_operation", "return_homebase", {"craft_id": _craft_id, "service_location_id": "polisa"})
	if not _check(bool(result.get("ok", false)), "Abflug: der Rueckflug beginnt (%s)" % [result]): return false
	return _check(await _pk_wait(func(): return String(_pk_space().get("phase", "")) == "orbit" and String(_pk_space().get("orbit_id", "")) == "polisa_orbit", 90000), "Abflug: von Polisa bis in den Orbit (Phase %s)" % _pk_space().get("phase", ""))

## Zustand der Abgeholten (wie _pk_check_picked_up, fuer die Angeworbene).
func _rk_check_picked_up(respawns_used: int, tag: String) -> void:
	var c: Dictionary = _roster_unit(RK_ID)
	_check(String(c.get("availability_status", "")) == "active" and Dictionary(c.get("recovery_state", {})).is_empty() and String(c.get("status_text", "")).is_empty(), "%s: active, Ausfalldaten und Statustext leer (%s)" % [tag, c.get("availability_status")])
	_check(int(c.get("respawns_used", -1)) == respawns_used, "%s: respawns_used bleibt %d (ist %s)" % [tag, respawns_used, c.get("respawns_used")])
	_check(_ra_base_status(RK_ID) in ["aboard", "outside", "moving", "idle", "sleeping"], "%s: Basis-Zustand nicht mehr station (%s)" % [tag, _ra_base_status(RK_ID)])
	var expected: Dictionary = _pk_recruit_loadout("operator")
	_check(Dictionary(_rg_loadouts().get(RK_ID, {})) == expected, "%s: Grundausstattung wie bei einer frisch angeworbenen Operatorin (%s gegen %s)" % [tag, _rg_loadouts().get(RK_ID), expected])
	var bag: Dictionary = Dictionary(_rg_inventory().get("unit:%s:backpack" % RK_ID, {}))
	_check(not bag.is_empty() and Dictionary(bag.get("items", {})).is_empty(), "%s: leerer Rucksack" % tag)

func _rk_r1() -> void:
	if not await _rk_setup(): return
	await _rk_die()
	var c: Dictionary = _roster_unit(RK_ID)
	var respawns_used: int = int(c.get("respawns_used", -1))
	if not _check(String(c.get("availability_status", "")) == "respawning" and respawns_used == 1 and _ra_base_status(RK_ID) == "station", "R1: Aufbau: die Angeworbene ist respawning (respawns_used 1) und steht auf station"): return
	var visit: Dictionary = await _rk_fly_to_polisa()
	if visit.is_empty(): return
	# Teil 1: waehrend die Uhr laeuft.
	await _pk_wait(func(): return false, 4000)
	var mission: Node = visit.mission
	_check(not _rk_is_resident(visit) and not Dictionary(mission.get_meta("singleplayer_station_personnel", {})).has(RK_ID) and visit.registry.get_unit(RK_ID) == null and not Dictionary(visit.controller.get("_deployed_unit_ids")).has(RK_ID), "R1: respawning (Kennung): sie erscheint auf Polisa nicht (keine Bewohnerin, kein Darsteller, nicht eingesetzt)")
	var claim_early: Dictionary = _runtime.call("request_operation", "station_claim_resident", {"craft_id": _craft_id, "unit_id": RK_ID})
	_check(not bool(claim_early.get("ok", false)) and String(claim_early.get("reason", "")) == "resident_unavailable", "R1: respawning (Kennung): nicht uebernehmbar, Grund resident_unavailable (%s)" % [claim_early])
	var setup: Node = mission.get_node("MissionSetup")
	var spawn: Dictionary = visit.controller.call("get_polisa_resident_spawn_grid")
	var admission: Dictionary = setup.call("request_polisa_recruit_admission", _roster_unit(RK_ID), spawn.get("spawn_grid", Vector2i.ZERO))
	_check(bool(spawn.get("ok", false)) and not bool(admission.get("ok", false)) and String(admission.get("reason", "")) == "invalid_or_duplicate_recruit" and visit.registry.get_unit(RK_ID) == null, "R1: respawning (Kennung): die Aufnahme am Setup lehnt sie ab (%s)" % [admission])
	var registered: Dictionary = visit.controller.call("register_polisa_resident", RK_ID)
	_check(not bool(registered.get("ok", false)) and not Dictionary(mission.get_meta("singleplayer_station_personnel", {})).has(RK_ID) and not Dictionary(visit.controller.get("_deployed_unit_ids")).has(RK_ID), "R1: respawning (Kennung): der echte register_polisa_resident laesst sie nicht zu (%s)" % [registered])
	_check(_ra_base_status(RK_ID) == "station" and String(_pk_roster_field(RK_ID, "availability_status")) == "respawning", "R1: respawning (Kennung): Basis-Zustand bleibt station, Kader respawning")
	# Teil 2: die Uhr laeuft ueber den echten Takt ab.
	var markers_before: Dictionary = _rk_markers()
	if not _check(await _rk_let_clock_run_out(RK_ID), "R1: die Uhr laeuft ueber den echten Takt ab, sie wartet (awaiting_pickup)"): return
	_check(_ra_base_status(RK_ID) == "station" and int(_pk_roster_field(RK_ID, "respawns_used")) == respawns_used, "R1: wartend: station, respawns_used unveraendert")
	if not _check(await _pk_wait(func(): return _rk_is_resident(visit), 60000), "R1: wartend (Kennung): sie erscheint als Bewohnerin (Darsteller, Bodenzustand)"): return
	if not await _rk_claim_and_board(visit): return
	if not await _rk_depart_to_orbit(): return
	_rk_check_picked_up(respawns_used, "R1 Abgeholt")
	var markers_after: Dictionary = _rk_markers()
	_check(markers_after == markers_before, "R1: der Anwerbe-Abschluss lief nicht ein zweites Mal (Credits, Reservierungen, Kadergroesse, Eintraege, Basis: vorher %s, nachher %s)" % [markers_before, markers_after])

func _rk_r2() -> void:
	if not await _rk_setup(): return
	await _rk_die()
	var respawns_used: int = int(_pk_roster_field(RK_ID, "respawns_used"))
	var visit: Dictionary = await _rk_fly_to_polisa()
	if visit.is_empty(): return
	if not _check(await _rk_let_clock_run_out(RK_ID), "R2: die Angeworbene wartet (awaiting_pickup)"): return
	if not _check(await _pk_wait(func(): return _rk_is_resident(visit), 60000), "R2: sie erscheint als Bewohnerin"): return
	if not await _rk_claim_and_board(visit): return
	# Fixture: unmittelbar vor dem Abflug steht sie wieder auf respawning (so wie die alte Fassung "kennung ODER awaiting" sie durchgelassen haette).
	var recovery: Dictionary = {"state": "respawning", "seconds_remaining": 600.0, "pickup_location_id": "polisa"}
	_ra_set(RK_ID, {"availability_status": "respawning", "recovery_state": recovery})
	var markers_before: Dictionary = _rk_markers()
	if not await _rk_depart_to_orbit(): return
	var c: Dictionary = _roster_unit(RK_ID)
	_check(_ra_base_status(RK_ID) == "station", "R2: respawning: beim Abflug nicht gebunden, Basis-Zustand bleibt station (%s)" % _ra_base_status(RK_ID))
	_check(String(c.get("availability_status", "")) == "respawning" and not Dictionary(c.get("recovery_state", {})).is_empty() and int(c.get("respawns_used", -1)) == respawns_used, "R2: respawning: nicht abgeschlossen (Status %s, respawns_used %s)" % [c.get("availability_status"), c.get("respawns_used")])
	_check(_rk_markers() == markers_before, "R2: nichts weiter geaendert (Kader, Credits, Eintraege)")

func _rk_r3() -> void:
	if not await _rk_setup(): return
	await _rk_die()
	var visit: Dictionary = await _rk_fly_to_polisa()
	if visit.is_empty(): return
	if not _check(await _rk_let_clock_run_out(RK_ID), "R3: die Angeworbene wartet (awaiting_pickup)"): return
	if not _check(await _pk_wait(func(): return _rk_is_resident(visit), 60000), "R3: sie erscheint als Bewohnerin"): return
	var mission: Node = visit.mission
	var respawning_recovery: Dictionary = {"state": "respawning", "seconds_remaining": 600.0, "pickup_location_id": "polisa"}
	# (a) station_claim_resident: Bewohnerin und eingesetzt, aber im Kader wieder respawning -> nicht uebernehmbar, Grund resident_unavailable.
	_ra_set(RK_ID, {"availability_status": "respawning", "recovery_state": respawning_recovery})
	var claim: Dictionary = _runtime.call("request_operation", "station_claim_resident", {"craft_id": _craft_id, "unit_id": RK_ID})
	var visits: Dictionary = mission.get_meta("singleplayer_visit_identities", {})
	var in_visit := false
	for entry: Dictionary in visits.values():
		if Array(entry.get("unit_ids", [])).has(RK_ID): in_visit = true
	_check(not bool(claim.get("ok", false)) and String(claim.get("reason", "")) == "resident_unavailable" and not in_visit, "R3 (a) station_claim_resident: Bewohnerin in respawning wird nicht uebernommen, Grund resident_unavailable (%s, im Besuch %s)" % [claim, in_visit])
	# (b) _restore_polisa_residents: Darsteller da, aber nicht mehr als Bewohnerin eingetragen; im Kader respawning -> wird nicht wieder eingetragen.
	var residents: Dictionary = Dictionary(mission.get_meta("singleplayer_station_personnel", {})).duplicate()
	residents.erase(RK_ID)
	mission.set_meta("singleplayer_station_personnel", residents)
	visit.controller.get("_deployed_unit_ids").erase(RK_ID)
	_runtime.set("_polisa_resident_retry_msec", 0)
	_runtime.call("_restore_polisa_residents")
	_check(not Dictionary(mission.get_meta("singleplayer_station_personnel", {})).has(RK_ID) and not Dictionary(visit.controller.get("_deployed_unit_ids")).has(RK_ID), "R3 (b) _restore_polisa_residents: respawning (Kennung) wird nicht wieder als Bewohnerin eingetragen")
	# Gegenprobe: wartet sie wieder, traegt dieselbe Funktion sie ein (die Pruefung ist nicht blind).
	_ra_set(RK_ID, {"availability_status": "awaiting_pickup", "recovery_state": {"state": "awaiting_pickup", "pickup_location_id": "polisa"}})
	_runtime.set("_polisa_resident_retry_msec", 0)
	_runtime.call("_restore_polisa_residents")
	_check(Dictionary(mission.get_meta("singleplayer_station_personnel", {})).has(RK_ID), "R3 (b) Gegenprobe: wartend (Kennung) wird von derselben Funktion wieder eingetragen")
	# (c) register_polisa_resident des echten Controllers: zugelassene Konfiguration steht auf respawning -> invalid_station_resident.
	residents = Dictionary(mission.get_meta("singleplayer_station_personnel", {})).duplicate()
	residents.erase(RK_ID)
	mission.set_meta("singleplayer_station_personnel", residents)
	visit.controller.get("_deployed_unit_ids").erase(RK_ID)
	var configs: Array = mission.get_node("MissionSetup").get("selected_team_unit_configs")
	var flipped := false
	for config: Variant in configs:
		if config is Dictionary and String((config as Dictionary).get("unit_id", "")) == RK_ID:
			(config as Dictionary)["availability_status"] = "respawning"
			flipped = true
	_check(flipped, "R3 (c) Fixture: die zugelassene Konfiguration der Angeworbenen steht im Setup")
	var registered: Dictionary = visit.controller.call("register_polisa_resident", RK_ID)
	_check(not bool(registered.get("ok", false)) and String(registered.get("reason", "")) == "invalid_station_resident", "R3 (c) register_polisa_resident (echter Controller): Konfiguration respawning (Kennung) wird abgewiesen, Grund invalid_station_resident (%s)" % [registered])
	for config: Variant in configs:
		if config is Dictionary and String((config as Dictionary).get("unit_id", "")) == RK_ID:
			(config as Dictionary)["availability_status"] = "awaiting_pickup"
	var control: Dictionary = visit.controller.call("register_polisa_resident", RK_ID)
	_check(bool(control.get("ok", false)), "R3 (c) Gegenprobe: Konfiguration awaiting_pickup (Kennung) wird zugelassen (%s)" % [control])

func _rk_r4() -> void:
	_rk_minimal = true
	if not await _rk_setup(): return
	await _rk_die()
	var respawns_used: int = int(_pk_roster_field(RK_ID, "respawns_used"))
	if not _check(await _rk_let_clock_run_out(RK_ID), "R4: Aufbau: die Angeworbene wartet (awaiting_pickup), noch daheim"): return
	var saved: Dictionary = {}
	var deadline := Time.get_ticks_msec() + 60000
	while not bool(saved.get("ok", false)) and Time.get_ticks_msec() < deadline:
		saved = _flow.call("request_campaign_save")
		if not bool(saved.get("ok", false)):
			await _pk_wait(func(): return false, 1000)
	if not _check(bool(saved.get("ok", false)), "R4: Speichern daheim mit der Wartenden gelingt (%s)" % [saved.get("reason", "")]): return
	var visit: Dictionary = await _rk_fly_to_polisa()
	if visit.is_empty(): return
	if not _check(await _pk_wait(func(): return _rk_is_resident(visit), 60000), "R4: sie erscheint als Bewohnerin"): return
	if not await _rk_claim_and_board(visit): return
	_check(_ra_base_status(RK_ID) == "station" and String(_pk_roster_field(RK_ID, "availability_status")) == "awaiting_pickup", "R4: uebernommen und eingestiegen, Abflug nicht bestaetigt: awaiting_pickup und station")
	# Der Besuch endet ohne Abflug: Spiel beenden (kein Speichern im Besuch moeglich, W7), Fortsetzen vom Heim-Speicherpunkt.
	await _end_sortie()
	await create_timer(0.5).timeout
	if not await _t6b_open("campaign", "continue"): return
	_rk_find_team()
	var c: Dictionary = _roster_unit(RK_ID)
	_check(String(c.get("availability_status", "")) == "awaiting_pickup" and String(Dictionary(c.get("recovery_state", {})).get("state", "")) == "awaiting_pickup" and int(c.get("respawns_used", -1)) == respawns_used, "R4: nach dem Fortsetzen ist sie awaiting_pickup (respawns_used %s)" % c.get("respawns_used"))
	var base_state: Dictionary = Dictionary(Dictionary(_t6b_base().get("_states")).get(RK_ID, {}))
	_check(String(base_state.get("status", "")) == "station" and String(base_state.get("craft_id", "")).is_empty(), "R4: nach dem Fortsetzen steht sie auf station, an keinem Schiff (%s)" % [base_state])
	_check(not PackedStringArray(_flow.get("_selected_unit_ids")).has(RK_ID) and not PackedStringArray(_flow.get("_homebase_staged_unit_ids")).has(RK_ID) and Dictionary(_flow.get("_pending_surface_departures")).is_empty() and not is_instance_valid(_flow.get("_active_mission")), "R4: nichts halb gesetzt (Auswahl, Besatzung, offener Abflug, aktive Ortsinstanz)")
	_check(Dictionary(_t6b_base().get("_unavailable_unit_reasons")).has(RK_ID), "R4: sie bleibt fuer Einsaetze gesperrt")
	# Der naechste Besuch bietet sie wieder an und holt sie ab.
	_craft_id = String(Dictionary(Array(_flow.get("_homebase_aircraft_definitions"))[0]).get("craft_id", ""))
	var visit_two: Dictionary = await _rk_fly_to_polisa()
	if visit_two.is_empty(): return
	if not _check(await _pk_wait(func(): return _rk_is_resident(visit_two), 60000), "R4: im naechsten Besuch erscheint sie wieder als Bewohnerin"): return
	if not await _rk_claim_and_board(visit_two): return
	if not await _rk_depart_to_orbit(): return
	_rk_check_picked_up(respawns_used, "R4 naechster Besuch: Abgeholt")
