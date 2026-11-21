extends "res://scripts/tests/campaign_respawn_gear_verifier.gd"
## R4c Respawn (Abholen auf Polisa): Eine Person, die nach dem Ausfall auf Polisa wartet (awaiting_pickup), wird dort aufgenommen
## und ist danach wieder einsatzfaehig. Echte Meta-Szene mit vier Personen (A Truppfuehrer, Pilot, B Truppfuehrer in ft1 mit A, C Schuetze allein in ft2).
## P1 echter Flug: C stirbt (respawning), Flug mit ft1 und Pilot nach Polisa, echte Landung. C ist waehrend des Ausfalls nicht sichtbar und nicht
##    uebernehmbar; nach Ablauf der Uhr erscheint sie als Bewohnerin, wird uebernommen, steigt mit der Besatzung ein und wird beim bestaetigten
##    Abflug gebunden (aboard, active, Ausfalldaten leer, respawns_used gleich, Grundausstattung). Rueckflug, Aussteigen daheim.
## P2 Grundausstattung: die EINE Stelle (grant_pickup_starting_equipment) gibt wie bei einer frisch Angeworbenen derselben Rolle
##    (Operator, Sanitaeter) leeren Rucksack, suit, pistol, medictool nur bei Sanitaet; nichts vom Vorherigen; im Loadout-Snapshot, nicht nur get_loadout.
## P3 complete_campaign_pickup ohne Wartende (active, respawning) aendert nichts.
## P4 Heimatbasis nach der Abholung (Punkt 10): Speichern und Fortsetzen mit der Abgeholten (active, Grundausstattung, in keinem alten Trupp).
## Hinweis: Speichern im Einsatz mit Wartenden wird abgelehnt (bekannter Mangel W7); kein Test hier stuetzt sich darauf.
## Abschlusszeile: CAMPAIGN_RESPAWN_PICKUP passed=%d failed=%d
## Einzeln starten: Kommandozeilenargument nach "--" (zum Beispiel "-- P2").

const PICKUP_GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const PICKUP_OFFERS = preload("res://scripts/meta/polisa_recruit_offers.gd")
const PICKUP_RECOVERY = preload("res://scripts/core/personnel_recovery_runtime.gd")

func _run() -> void:
	var verdict: Dictionary = PICKUP_GUARD.verdict_from_environment()
	if not bool(verdict.get("ok", false)):
		print("CAMPAIGN_RESPAWN_PICKUP refused: needs a throwaway profile (SB_REVIEW2_USER_DIR), nothing written. Reason: %s" % str(verdict.get("reason", "")))
		quit(2)
		return
	_configure_entry()
	var selected: Array = []
	for arg: String in OS.get_cmdline_user_args():
		if not arg.strip_edges().is_empty():
			selected.append(arg.strip_edges().to_upper())
	for scenario: String in ["P1", "P2", "P3", "P4"]:
		if not selected.is_empty() and not selected.has(scenario):
			continue
		print("--- ", scenario)
		await call("_pk_" + scenario.to_lower())
		await _end_sortie()
	print("CAMPAIGN_RESPAWN_PICKUP passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _pk_op(operation: String, payload: Dictionary = {}) -> Dictionary:
	var data := payload.duplicate(true)
	data["craft_id"] = _craft_id
	return _screen.call("request_operation", operation, data)

func _pk_space() -> Dictionary:
	return Dictionary(Dictionary(_runtime.call("get_snapshot")).get("space_travel", {}))

func _pk_wait(predicate: Callable, milliseconds: int) -> bool:
	var deadline := Time.get_ticks_msec() + milliseconds
	while Time.get_ticks_msec() < deadline:
		if predicate.call():
			return true
		await process_frame
	return false

## Die Wartende wird ueber die echte Reifung der Ausfallzeit zu awaiting_pickup (nicht per Hand gesetzt).
func _pk_mature(unit_id: String) -> void:
	var advanced: Dictionary = PICKUP_RECOVERY.advance(Array(_flow.get("_all_team_units")), 1000000.0)
	_flow.call("_replace_roster_units", Array(advanced.get("units", [])))
	_flow.call("_sync_wound_lock")

func _pk_roster_field(unit_id: String, field: String) -> Variant:
	return _roster_unit(unit_id).get(field)

## Erwartete Grundausstattung nach dem Angebotsprofil einer frisch Angeworbenen dieser Rolle (so bekommt sie sie auf Polisa).
func _pk_recruit_loadout(role: String) -> Dictionary:
	for offer: Dictionary in PICKUP_OFFERS.build_offers("r4c_pickup_batch", _roster_unit(LEAD_A), {}):
		var profile: Dictionary = offer.profile
		if String(profile.get("roster_role_category", "")) == role:
			return {"armor": String(profile.get("armor", "")), "weapon_1": String(profile.get("weapon_1", "")), "weapon_2": String(profile.get("weapon_2", ""))}
	return {}

func _pk_p2() -> void:
	if not await _t6b_new_four(): return
	var operator_loadout: Dictionary = _pk_recruit_loadout("operator")
	var medic_loadout: Dictionary = _pk_recruit_loadout("medic")
	_check(not operator_loadout.is_empty() and not medic_loadout.is_empty() and String(medic_loadout.weapon_2) == "medictool" and String(operator_loadout.weapon_2) == "none", "P2: Fixture: Angebotsprofile einer frisch Angeworbenen (Operator %s, Sanitaeter %s)" % [operator_loadout, medic_loadout])
	_flow.call("_apply_campaign_casualties", _ra_result(_t6b_states({SHOOTER_C: "down", LEAD_B: "down"}), "aborted", 3))
	_ra_set(LEAD_B, {"roster_role_category": "medic"})
	# Etwas vom frueheren Besitz liegt noch am Eintrag (so wie nach Speichern und Fortsetzen ein Standard aus den Profilfeldern zurueckkommt).
	_check(not _rg_loadouts().has(SHOOTER_C) and not _rg_loadouts().has(LEAD_B), "P2: Fixture: beide haben kein eigenes Loadout (get_snapshot)")
	var granted_operator: Dictionary = _runtime.call("grant_pickup_starting_equipment", SHOOTER_C)
	var granted_medic: Dictionary = _runtime.call("grant_pickup_starting_equipment", LEAD_B)
	_check(bool(granted_operator.get("ok", false)) and bool(granted_medic.get("ok", false)), "P2: die Grundausstattung wird vergeben (%s / %s)" % [granted_operator, granted_medic])
	_check(Dictionary(_rg_loadouts().get(SHOOTER_C, {})) == operator_loadout, "P2: Operator: Loadout im Snapshot wie bei einer frisch angeworbenen Operatorin (%s gegen %s)" % [_rg_loadouts().get(SHOOTER_C), operator_loadout])
	_check(Dictionary(_rg_loadouts().get(LEAD_B, {})) == medic_loadout, "P2: Sanitaet: Loadout im Snapshot wie bei einer frisch angeworbenen Sanitaeterin, mit medictool (%s gegen %s)" % [_rg_loadouts().get(LEAD_B), medic_loadout])
	for unit_id: String in [SHOOTER_C, LEAD_B]:
		var bag: Dictionary = Dictionary(_rg_inventory().get("unit:%s:backpack" % unit_id, {}))
		_check(not bag.is_empty() and Dictionary(bag.get("items", {})).is_empty(), "P2: %s hat einen leeren Rucksack (%s)" % [unit_id, bag])
	# Gegenprobe: Etwas, das die Person vorher im Rucksack oder im Loadout hatte, kommt nicht zurueck.
	var supply: RefCounted = _runtime.get("_supply")
	Dictionary(Dictionary(Dictionary(supply.get("_inventory"))["unit:%s:backpack" % SHOOTER_C])["items"])["mining_tool"] = 1
	_runtime.get("_simulation").call("request_personnel_loadout_command", "set_loadout", {"unit_id": SHOOTER_C, "loadout": {"armor": "heavy", "weapon_1": "rifle", "weapon_2": "medictool"}})
	_runtime.call("grant_pickup_starting_equipment", SHOOTER_C)
	_check(Dictionary(_rg_loadouts().get(SHOOTER_C, {})) == operator_loadout and Dictionary(Dictionary(_rg_inventory().get("unit:%s:backpack" % SHOOTER_C, {})).get("items", {})).is_empty(), "P2: was die Person zuvor trug oder im Rucksack hatte, ist weg (ausdruecklich gesetzt)")
	var unknown: Dictionary = _runtime.call("grant_pickup_starting_equipment", "kein_kader_eintrag")
	_check(not bool(unknown.get("ok", false)) and not _rg_loadouts().has("kein_kader_eintrag"), "P2: eine Person ohne Kader-Eintrag bekommt nichts (%s)" % [unknown])

func _pk_p3() -> void:
	if not await _t6b_new_four(): return
	var before: String = JSON.stringify(_roster_unit(LEAD_B), "", true)
	var on_active: Dictionary = _flow.call("complete_campaign_pickup", LEAD_B)
	_check(not bool(on_active.get("ok", false)) and JSON.stringify(_roster_unit(LEAD_B), "", true) == before, "P3: eine aktive Person wird nicht angefasst (%s)" % [on_active])
	_flow.call("_apply_campaign_casualties", _ra_result(_t6b_states({SHOOTER_C: "down"}), "aborted", 3))
	var down_before: String = JSON.stringify(_roster_unit(SHOOTER_C), "", true)
	var loadouts_before: Dictionary = _rg_loadouts()
	var on_down: Dictionary = _flow.call("complete_campaign_pickup", SHOOTER_C)
	_check(not bool(on_down.get("ok", false)) and JSON.stringify(_roster_unit(SHOOTER_C), "", true) == down_before and String(_pk_roster_field(SHOOTER_C, "availability_status")) == "respawning", "P3: wer noch ausfaellt (respawning) wird nicht abgeholt (%s)" % [on_down])
	_check(_rg_loadouts() == loadouts_before and _ra_base_status(SHOOTER_C) == "station", "P3: dabei entsteht keine Ausruestung, die Basis-Person bleibt auf station")
	var unknown: Dictionary = _flow.call("complete_campaign_pickup", "kein_kader_eintrag")
	_check(not bool(unknown.get("ok", false)), "P3: unbekannte Person: abgelehnt (%s)" % [unknown])

func _pk_board_home_crew() -> bool:
	_craft_id = String(Dictionary(Array(_flow.get("_homebase_aircraft_definitions"))[0]).get("craft_id", ""))
	var personnel: Node = _t6b_base()
	# Die neu aufgenommenen Personen stehen erst nach der Aufnahme auf dem Bodenraster der Basis.
	var at_home: bool = await _pk_wait(func(): return bool(personnel.call("_unit_is_home", LEAD_A)) and bool(personnel.call("_unit_is_home", LEAD_B)) and bool(personnel.call("_unit_is_home", PILOT_ID)), 30000)
	_check(at_home, "P1: A, B und der Pilot stehen an der Basis (A %s, B %s, Pilot %s)" % [personnel.call("_unit_is_home", LEAD_A), personnel.call("_unit_is_home", LEAD_B), personnel.call("_unit_is_home", PILOT_ID)])
	# Der Screen nimmt ohne unit_id die zuletzt fokussierte Person (hier womoeglich C, die ausgefallen ist): eine Person des Trupps nennen.
	var team_board: Dictionary = _screen.call("request_operation", "board", {"craft_id": _craft_id, "fireteam_id": _team_id, "unit_id": LEAD_A})
	if not _check(bool(team_board.get("ok", false)), "P1: ft1 wird dem Schiff zugeteilt (%s)" % [team_board]): return false
	var walk: Dictionary = _screen.call("request_operation", "base_board", {"craft_id": _craft_id, "fireteam_id": _team_id, "unit_id": LEAD_A, "whole_fireteam": true})
	if not _check(bool(walk.get("ok", false)), "P1: die Besatzung (ft1 und Pilot) geht an Bord (%s)" % [walk]): return false
	var sim: Node = personnel.call("get_simulation_root")
	for tick in range(6000):
		if personnel.call("is_pilot_aboard", _craft_id) and bool(_screen.call("_has_homebase_direct_launch_payload_for_craft", _craft_id)):
			break
		sim.call("_physics_process", 0.05)
		_screen.call("_debug_advance_homebase_direct_boarding", 0.05)
	return _check(bool(personnel.call("is_pilot_aboard", _craft_id)) and bool(_screen.call("_has_homebase_direct_launch_payload_for_craft", _craft_id)), "P1: Pilot und Nutzlast sind an Bord")

func _pk_p1() -> void:
	if not await _t6b_new_four(): return
	_flow.set("_active_singleplayer_identity", {})
	_flow.call("_apply_campaign_casualties", _ra_result(_t6b_states({SHOOTER_C: "down"}), "aborted", 3))
	var c: Dictionary = _roster_unit(SHOOTER_C)
	var respawns_used: int = int(c.get("respawns_used", -1))
	_check(String(c.get("availability_status", "")) == "respawning" and respawns_used == 1 and _ra_base_status(SHOOTER_C) == "station", "P1: Aufbau: C ist respawning (respawns_used 1) und steht auf station")
	if not await _pk_board_home_crew(): return
	var result: Dictionary = _pk_op("select_destination", {"location_id": "polisa", "job_id": ""})
	if not _check(bool(result.get("ok", false)), "P1: Polisa als Besuch ohne Auftrag gewaehlt (%s)" % [result]): return
	result = _pk_op("start")
	if not _check(bool(result.get("ok", false)), "P1: das Schiff startet von der Basis (%s)" % [result]): return
	result = _pk_op("space_start_quantum", {"target_orbit_id": "polisa_orbit"})
	if not _check(bool(result.get("ok", false)), "P1: Quantenflug nach Polisa (%s)" % [result]): return
	if not _check(await _pk_wait(func(): return String(_pk_space().get("orbit_id", "")) == "polisa_orbit", 20000), "P1: Ankunft im Orbit von Polisa"): return
	result = _pk_op("space_begin_approach", {"location_id": "polisa"})
	if not _check(bool(result.get("ok", false)), "P1: Anflug auf Polisa (%s)" % [result]): return
	if not _check(await _pk_wait(func(): return is_instance_valid(_flow.get("_active_mission")), 60000), "P1: die Polisa-Szene laedt"): return
	_flow.call("_show_mission")
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	if not _check(await _pk_wait(func(): return String(controller.call("_find_mission_dropship_card_entry", _craft_id).get("state", "")) == "waiting", 90000), "P1: das Schiff erreicht die Landeauswahl"): return
	var map = load("res://scripts/terrain/terrain_map_data.gd").load_from_file("res://maps/polisa_station.json")
	var view: Node = mission.get_node("Primary3DView")
	var pad: Vector2 = map.get_marker_position("polisa_pad_01")
	view.call("focus_world_position", pad)
	controller.call("_on_mission_dropship_card_set_lz_pressed", _craft_id)
	if not _check(bool(controller.call("_place_lz_from_screen_position", view.call("world_to_screen_position", pad))), "P1: Landeplatz der Station gewaehlt"): return
	controller.call("_on_mission_dropship_card_drop_pressed", _craft_id)
	if not _check(await _pk_wait(func(): return bool(controller.call("_is_parked_campaign_dropship", _craft_id)), 90000), "P1: das Schiff landet auf Polisa"): return
	var crew: PackedStringArray = controller.call("_campaign_craft_crew_ids", _craft_id)
	if not _check(not crew.is_empty() and await _pk_wait(func():
		var deployed: Dictionary = controller.get("_deployed_unit_ids")
		for id in crew:
			if not deployed.has(id): return false
		return true, 60000), "P1: die ganze Besatzung steigt aus"): return
	_check(not crew.has(SHOOTER_C), "P1: C gehoert nicht zur Besatzung (%s)" % [crew])
	var registry: Node = mission.get_node("UnitRegistry")
	var simulation: Node = mission.get_node("SimulationRoot")
	# Waehrend des Ausfalls: nicht zu sehen, nicht uebernehmbar.
	await _pk_wait(func(): return false, 4000)
	var residents: Dictionary = mission.get_meta("singleplayer_station_personnel", {})
	_check(not residents.has(SHOOTER_C) and registry.get_unit(SHOOTER_C) == null and not Dictionary(controller.get("_deployed_unit_ids")).has(SHOOTER_C), "P1: waehrend des Ausfalls (respawning) ist C auf Polisa weder Bewohnerin noch als Darsteller da")
	var early_claim: Dictionary = _runtime.call("request_operation", "station_claim_resident", {"craft_id": _craft_id, "unit_id": SHOOTER_C})
	_check(not bool(early_claim.get("ok", false)), "P1: waehrend des Ausfalls ist C nicht uebernehmbar (%s)" % [early_claim])
	# Die Uhr laeuft ab (echte Reifung), C wartet.
	_pk_mature(SHOOTER_C)
	_check(String(_pk_roster_field(SHOOTER_C, "availability_status")) == "awaiting_pickup" and _ra_base_status(SHOOTER_C) == "station", "P1: nach Ablauf der Uhr wartet C (awaiting_pickup) und steht auf station")
	if not _check(await _pk_wait(func():
		return Dictionary(mission.get_meta("singleplayer_station_personnel", {})).has(SHOOTER_C) and registry.get_unit(SHOOTER_C) != null and not simulation.call("get_hex_unit_state", SHOOTER_C).is_empty(), 60000), "P1: C erscheint als Bewohnerin auf Polisa (Darsteller, Bodenzustand)"):
		print("P1_DIAG residents=", mission.get_meta("singleplayer_station_personnel", {}), " unit=", registry.get_unit(SHOOTER_C), " base=", _ra_base_status(SHOOTER_C), " setup=", mission.get_node("MissionSetup").call("get_runtime_selection_status"))
		return
	var claim: Dictionary = _runtime.call("request_operation", "station_claim_resident", {"craft_id": _craft_id, "unit_id": SHOOTER_C})
	_check(bool(claim.get("ok", false)), "P1: C wird fuer dieses Schiff uebernommen (%s)" % [claim])
	_check(_ra_base_status(SHOOTER_C) == "station" and String(_pk_roster_field(SHOOTER_C, "availability_status")) == "awaiting_pickup", "P1: uebernommen, aber noch nicht abgeflogen: C bleibt awaiting_pickup und station")
	# Der Spieler laeuft C zum Schiff (der Befehl dafuer ist eine Einsatzansicht-Eingabe); hier setzt der Test sie wie campaign_casualty_boarding_verifier
	# ueber _place_at an den Zugang des Schiffs (schreibt in den Bodenzustand, kein oeffentlicher Weg fuer einen Laufbefehl in diesem Aufbau).
	var access: Dictionary = controller.call("get_campaign_ground_ship_access", _craft_id)
	if not _check(bool(access.get("ok", false)) and _place_at(simulation, access, SHOOTER_C, Vector2.ZERO), "P1: C steht am Schiff (Zugang %s)" % [access]): return
	result = _runtime.call("request_operation", "station_board_crew", {"craft_id": _craft_id, "service_location_id": "polisa"})
	if not _check(await _pk_wait(func(): return bool(controller.call("get_campaign_pilot_flight_guard", _craft_id).get("ok", false)) and bool(registry.get_unit(SHOOTER_C).get_meta("dropship_embarked", false)), 90000), "P1: die Besatzung und C steigen ein (%s)" % [result]):
		print("P1_DIAG guard=", controller.call("get_campaign_pilot_flight_guard", _craft_id), " embarked=", registry.get_unit(SHOOTER_C).get_meta("dropship_embarked", false))
		return
	_check(_ra_base_status(SHOOTER_C) == "station" and String(_pk_roster_field(SHOOTER_C, "availability_status")) == "awaiting_pickup", "P1: eingestiegen, aber noch nicht abgeflogen: C bleibt awaiting_pickup und station")
	result = _runtime.call("request_operation", "return_homebase", {"craft_id": _craft_id, "service_location_id": "polisa"})
	if not _check(bool(result.get("ok", false)), "P1: Rueckflug beginnt (%s)" % [result]): return
	if not _check(await _pk_wait(func(): return String(_pk_space().get("phase", "")) == "orbit" and String(_pk_space().get("orbit_id", "")) == "polisa_orbit", 90000), "P1: Abflug von Polisa bis in den Orbit"): return
	_pk_check_picked_up(respawns_used)
	result = _pk_op("space_start_quantum", {"target_orbit_id": "moon_orbit"})
	if not _check(bool(result.get("ok", false)), "P1: Quantenflug heim (%s)" % [result]): return
	if not _check(await _pk_wait(func(): return String(_pk_space().get("orbit_id", "")) == "moon_orbit", 20000), "P1: Ankunft im Heimatorbit"): return
	result = _pk_op("space_land_homebase")
	if not _check(bool(result.get("ok", false)), "P1: Landung an der Heimatbasis angefordert (%s)" % [result]): return
	if not _check(await _pk_wait(func():
		for craft: Dictionary in Array(Dictionary(_runtime.call("get_snapshot")).get("crafts", [])):
			if String(craft.get("craft_id", "")) == _craft_id: return String(craft.get("location_id", "")) == "homebase" and not bool(craft.get("busy", true))
		return false, 90000), "P1: das Schiff ist wieder daheim"): return
	_check(_ra_base_status(SHOOTER_C) == "aboard", "P1: daheim ist C an Bord (Aussteigen ist ein eigener Befehl)")
	# Die Basisansicht liest den Ort des Schiffs aus ihrem Zwischenspeicher: wie beim Wechsel zurueck zur Basis auffrischen.
	_flow.call("_show_homebase")
	await process_frame
	_flow.call("_refresh_homebase_screen")
	var unboard: Dictionary = _t6b_base().call("request_operation", "base_unboard", {"craft_id": _craft_id, "unit_id": SHOOTER_C})
	await _pk_wait(func(): return _ra_base_status(SHOOTER_C) == "outside", 30000)
	_check(bool(unboard.get("ok", false)) and _ra_base_status(SHOOTER_C) == "outside", "P1: beim Aussteigen daheim steht C wieder an der Basis (%s, Basis-Zustand %s)" % [unboard, _ra_base_status(SHOOTER_C)])
	_pk_check_picked_up(respawns_used)

## Punkt 10: Speichern an der Heimatbasis und Fortsetzen mit einer Abgeholten. Der Flug ist hier nicht gefahren (nach einem Polisa-Besuch haelt die
## Meta-Szene die Orts-Instanz als aktiven Einsatz, dann geht das Speichern ueber den Einsatzweg, bekannter Mangel W7); dafuer wie
## campaign_recruit_checkpoint_verifier: Abholung ueber den Besitzer-Aufruf mark_recruit_remote, Fertigstellung ueber die echte Flow-Funktion.
func _pk_p4() -> void:
	if not await _t6b_new_four(): return
	_craft_id = String(Dictionary(Array(_flow.get("_homebase_aircraft_definitions"))[0]).get("craft_id", ""))
	_flow.call("_apply_campaign_casualties", _ra_result(_t6b_states({SHOOTER_C: "down"}), "aborted", 3))
	var respawns_used: int = int(_roster_unit(SHOOTER_C).get("respawns_used", -1))
	_pk_mature(SHOOTER_C)
	if not _check(String(_pk_roster_field(SHOOTER_C, "availability_status")) == "awaiting_pickup" and _ra_base_status(SHOOTER_C) == "station", "P4: Aufbau: C wartet auf Abholung (station)"): return
	var boarded: Dictionary = _t6b_base().call("mark_recruit_remote", SHOOTER_C, _craft_id)
	if not _check(bool(boarded.get("ok", false)) and _ra_base_status(SHOOTER_C) == "aboard", "P4: Aufbau: C ist an Bord des Heimschiffs (%s)" % [boarded]): return
	var done: Dictionary = _flow.call("complete_campaign_pickup", SHOOTER_C)
	_check(bool(done.get("ok", false)), "P4: die Fertigstellung der Abholung gelingt (%s)" % [done])
	var out: Dictionary = _t6b_base().call("request_operation", "base_unboard", {"unit_id": SHOOTER_C, "craft_id": _craft_id})
	await _pk_wait(func(): return _ra_base_status(SHOOTER_C) == "outside", 60000)
	_check(bool(out.get("ok", false)) and _ra_base_status(SHOOTER_C) == "outside", "P4: C steigt an der Heimatbasis aus (%s, %s)" % [out, _ra_base_status(SHOOTER_C)])
	_pk_check_picked_up(respawns_used)
	var saved: Dictionary = {}
	var save_deadline := Time.get_ticks_msec() + 60000
	while not bool(saved.get("ok", false)) and Time.get_ticks_msec() < save_deadline:
		saved = _flow.call("request_campaign_save")
		if not bool(saved.get("ok", false)):
			await _pk_wait(func(): return false, 1000)
	if not _check(bool(saved.get("ok", false)), "P4: Speichern an der Basis gelingt mit der Abgeholten (%s)" % [saved.get("reason", "")]): return
	var payload: Dictionary = _t6b_payload()
	_check(bool(STORE_6B.validate_payload(payload).get("ok", false)), "P4: der gespeicherte Stand ist gueltig")
	await _end_sortie()
	await create_timer(0.5).timeout
	if not await _t6b_open("campaign", "continue"): return
	_pk_check_picked_up(respawns_used, true)
	_check(_ra_base_status(SHOOTER_C) in ["outside", "idle", "moving", "sleeping"], "P4: nach dem Fortsetzen steht C an der Basis (%s)" % _ra_base_status(SHOOTER_C))

## Zustand der Abgeholten: wieder einsatzfaehig, mit Grundausstattung, ohne alten Platz.
func _pk_check_picked_up(respawns_used: int, resumed: bool = false) -> void:
	var tag: String = "nach Fortsetzen" if resumed else "Abgeholt"
	var c: Dictionary = _roster_unit(SHOOTER_C)
	_check(String(c.get("availability_status", "")) == "active" and Dictionary(c.get("recovery_state", {})).is_empty() and String(c.get("status_text", "")).is_empty(), "%s: C ist active, Ausfalldaten und Statustext sind leer (%s)" % [tag, c.get("availability_status")])
	_check(int(c.get("respawns_used", -1)) == respawns_used, "%s: respawns_used bleibt %d (ist %s)" % [tag, respawns_used, c.get("respawns_used")])
	if not resumed:
		_check(_ra_base_status(SHOOTER_C) in ["aboard", "outside", "moving", "idle", "sleeping"], "%s: Basis-Zustand ist nicht mehr station (%s)" % [tag, _ra_base_status(SHOOTER_C)])
	var expected: Dictionary = _pk_recruit_loadout("operator")
	_check(Dictionary(_rg_loadouts().get(SHOOTER_C, {})) == expected, "%s: Grundausstattung wie bei einer frisch angeworbenen Operatorin im Loadout-Snapshot (%s gegen %s)" % [tag, _rg_loadouts().get(SHOOTER_C), expected])
	var bag: Dictionary = Dictionary(_rg_inventory().get("unit:%s:backpack" % SHOOTER_C, {}))
	_check(not bag.is_empty() and Dictionary(bag.get("items", {})).is_empty(), "%s: leerer Rucksack" % tag)
	# Als Besatzung des Schiffs steht C in der Einsatzauswahl und der Schiffsbelegung wie jede Mitreisende; in einem Trupp oder als Pilot nicht.
	var stray: Array = _rg_stray(SHOOTER_C, RESPAWN_KEEPS + ["supply.inventory", "loadout state", "flow._selected_unit_ids", "flow._homebase_staged_unit_ids", "craft.staged_unit_ids", "craft.member_loadouts"])
	_check(stray.is_empty(), "%s: C steht in keinem alten Trupp und nicht als Pilot (uebrig: %s)" % [tag, stray])
	_check(String(Dictionary(_t6b_base().get("_unavailable_unit_reasons")).get(SHOOTER_C, "")).is_empty(), "%s: keine Einsatzsperre fuer C" % tag)
