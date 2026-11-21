extends "res://scripts/tests/campaign_respawn_pickup_verifier.gd"
## R4e Respawn (Punkt 8, keine Sackgasse): Nach dem Tod der Nicht-Geschuetzten bleibt der Spieler nirgends haengen. Echte Meta-Szene mit
## vier Personen (A Truppfuehrer Platz 0, Pilot Platz 1, B Truppfuehrer in ft1 mit A, C Schuetze allein in ft2), echter Flug nach Polisa.
## Gebaut ist nur ein Glied: die Zustellung des Missionsergebnisses an _apply_campaign_casualties (gebaut, weil resolve_mission bei
## Totalverlust nichts verbucht und ein Einsatz mit zwei Toten, einer Verwundeten und einer Rettung nicht zuverlaessig herstellbar ist).
## Das Ergebnis selbst kommt aus den echten Regeln (resolve_mission). Echte Einsatzenden mit Zurueckgelassenem: campaign_respawn_mission_verifier M1.
## Der Ausfall laeuft ueber den echten Takt (_tick_personnel_recovery), nicht ueber ein gesetztes awaiting_pickup.
## A   Hauptfall: B und C tot, A einsatzfaehig. Reifen, Speichern, Fortsetzen (M2: weiter gesperrt), Flug nach Polisa, Abholen beider,
##     Rueckflug, Aussteigen, neuer Einsatz mit Trupp aus den Abgeholten. Speichern daheim: Messung der Rueckkehr (RDE_SAVE_PROBE)
## B   X (A) ist leicht verwundet: Trupp nur aus dem Piloten; Messung des Wegs, sonst Fluegen nach Ausheilen von A
## C   Platz 0 (A) wartet, Sanitaeter B fliegt; Kader-Reihenfolge und _campaign_roster_problems bleiben
## D   nicht zugeteilter Pilot auf Platz 1 wartet; zugeteilter Pilot D fliegt; Zuteilung abgelehnt (unit_busy), nach dem Abholen wieder moeglich
## E   (Restrisiko R1) B eingeteilt, gespeichert, fortgesetzt, dann tot: B steht in keiner Trupp-Definition (Basis und FOB)
## M1  park_pickup_person scheitert (kaputter Darsteller): Speichern daheim und spaeteres Abholen
## Abschlusszeile: CAMPAIGN_RESPAWN_NO_DEAD_END passed=%d failed=%d
## Einzeln starten: Kommandozeilenargument nach "--" (zum Beispiel "-- A").

const NODEAD_GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const NODEAD_JOB := "satellite_recovery"
const NODEAD_LOCATION := "satellite_crash"
const NODEAD_PILOT_D := "nd_pilot_d"

var _nd: Dictionary = {}
var _nd_save_log: Array = []

func _run() -> void:
	var verdict: Dictionary = NODEAD_GUARD.verdict_from_environment()
	if not bool(verdict.get("ok", false)):
		print("CAMPAIGN_RESPAWN_NO_DEAD_END refused: needs a throwaway profile (SB_REVIEW2_USER_DIR), nothing written. Reason: %s" % str(verdict.get("reason", "")))
		quit(2)
		return
	_configure_entry()
	var selected: Array = []
	for arg: String in OS.get_cmdline_user_args():
		if not arg.strip_edges().is_empty():
			selected.append(arg.strip_edges().to_upper())
	for scenario: String in ["A", "E", "C", "B", "D", "M1", "S"]:
		if not selected.is_empty() and not selected.has(scenario):
			continue
		print("--- ", scenario)
		_nd = {}
		await call("_nd_" + scenario.to_lower())
		await _end_sortie()
	print("CAMPAIGN_RESPAWN_NO_DEAD_END passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

# ---------- Hilfen ----------

func _nd_craft() -> void:
	_craft_id = String(Dictionary(Array(_flow.get("_homebase_aircraft_definitions"))[0]).get("craft_id", ""))

## Ergebnis aus den echten Regeln; fit = einsatzfaehig, down = zurueckgelassen (tot), wounded = einsatzfaehig, aber zwischendurch gelegen.
func _nd_result(vitals: Dictionary) -> Dictionary:
	var states: Array = []
	for unit_id: String in vitals:
		var vital: String = String(vitals[unit_id])
		states.append(_state(unit_id, "fit" if vital in ["fit", "wounded"] else vital, false, vital == "wounded"))
	return _ra_result(states, "aborted", 3)

func _nd_deliver(vitals: Dictionary, tag: String) -> Dictionary:
	var result: Dictionary = _nd_result(vitals)
	_check(not bool(result.get("casualty_total_loss", true)), "%s: Aufbau: kein Totalverlust (gebaut aus den echten Regeln)" % tag)
	return _flow.call("_apply_campaign_casualties", result)

## Echter Takt: je 2 s (Deckel pro Aufruf) bis alle awaiting_pickup sind.
func _nd_mature(ids: Array) -> int:
	var ticks := 0
	while ticks < 2600:
		var all_waiting := true
		for unit_id: String in ids:
			if _nd_status(unit_id) != "awaiting_pickup":
				all_waiting = false
		if all_waiting:
			break
		_flow.call("_tick_personnel_recovery", 2.0)
		ticks += 1
	return ticks

func _nd_status(unit_id: String) -> String:
	var status: Variant = _pk_roster_field(unit_id, "availability_status")
	return "" if status == null else String(status)

func _nd_team_of(unit_id: String) -> String:
	for team: Dictionary in Array(Dictionary(_screen.call("get_operations_snapshot")).get("fireteams", [])):
		if _rg_team_members(String(team.get("id", ""))).has(unit_id):
			return String(team.get("id", ""))
	return ""

## Trupp, in dem unit_id steht; sonst ein neuer Trupp mit ihr.
func _nd_ensure_team_for(unit_id: String) -> bool:
	_nd_craft()
	var existing: String = _nd_team_of(unit_id)
	if not existing.is_empty():
		_team_id = existing
		return true
	var known: Array = _rg_team_ids()
	var added: Dictionary = _screen.call("request_operation", "add_fireteam", {})
	if not _check(bool(added.get("ok", false)), "Aufbau: neuer Trupp (%s)" % [added]): return false
	for team_id: String in _rg_team_ids():
		if not known.has(team_id):
			_team_id = team_id
	var assigned: Dictionary = _screen.call("request_operation", "assign", {"unit_id": unit_id, "fireteam_id": _team_id})
	return _check(bool(assigned.get("ok", false)), "Aufbau: %s im neuen Trupp %s (%s)" % [unit_id, _team_id, assigned])

func _nd_unit_ids_aboard() -> Array:
	var ids: Array = []
	for person: Dictionary in Array(Dictionary(_t6b_base().call("get_snapshot")).get("units", [])):
		if String(person.get("status", "")) == "aboard":
			ids.append(String(person.get("unit_id", "")))
	return ids

## Speichern an der Heimatbasis ausprobieren und festhalten (Messung, keine Erwartung).
func _nd_probe_save(stage: String) -> Dictionary:
	var mission: Variant = _flow.get("_active_mission")
	var mission_valid: bool = is_instance_valid(mission)
	var flow_identity: Dictionary = Dictionary(_flow.get("_active_singleplayer_identity"))
	var mission_identity: Dictionary = Dictionary(mission.get_meta("singleplayer_mission_identity", {})) if mission_valid else {}
	var locations: Array = _flow.call("get_location_runtime_snapshot")
	var saved: Dictionary = _flow.call("request_campaign_save")
	var line: String = "RDE_SAVE_PROBE stage=%s active_mission=%s ok=%s reason=%s flow_identity_empty=%s mission_identity_empty=%s identities_equal=%s locations=%d" % [stage, mission_valid, saved.get("ok", false), saved.get("reason", ""), flow_identity.is_empty(), mission_identity.is_empty(), flow_identity == mission_identity, locations.size()]
	print(line)
	_nd_save_log.append(line)
	return saved

## Trupp mit lead_id und Pilot an die Basis-Bordwand bringen; soft: nichts als Fehlschlag werten, sondern den ersten Grund zurueckgeben.
func _nd_board_crew(tag: String, lead_id: String, pilot_id: String, soft: bool = false) -> String:
	_nd_craft()
	var personnel: Node = _t6b_base()
	var ids: Array = [lead_id, pilot_id]
	# Der Pilot darf nach einem Flug noch an Bord des Schiffs sein (Aussteigen scheitert dann an der Aufnahmekapazitaet der Basis, unabhaengig vom Respawn).
	var at_home: bool = await _pk_wait(func(): return ids.all(func(unit_id: String) -> bool: return bool(personnel.call("_unit_is_home", unit_id)) or (unit_id == pilot_id and _ra_base_status(unit_id) == "aboard")), 30000)
	if not at_home:
		if soft: return "not_at_home"
		_check(false, "%s: %s und %s stehen an der Basis" % [tag, lead_id, pilot_id])
		return "not_at_home"
	# Wie der Spieler: bei "insufficient_admission_space" (Ausgangsfeld kurz besetzt) nach einer Weile erneut versuchen, hoechstens 40 s.
	var team_board: Dictionary = {}
	var board_deadline := Time.get_ticks_msec() + 40000
	while true:
		team_board = _screen.call("request_operation", "board", {"craft_id": _craft_id, "fireteam_id": _team_id, "unit_id": lead_id})
		if bool(team_board.get("ok", false)) or String(team_board.get("reason", "")) != "insufficient_admission_space" or Time.get_ticks_msec() > board_deadline:
			break
		await _pk_wait(func(): return false, 2000)
	if not bool(team_board.get("ok", false)):
		print("RDE_BOARD_REJECT %s board=%s" % [tag, team_board])
		if not soft: _check(false, "%s: der Trupp %s wird dem Schiff zugeteilt (%s)" % [tag, _team_id, team_board])
		return "board:%s" % team_board.get("reason", "")
	var walk: Dictionary = _screen.call("request_operation", "base_board", {"craft_id": _craft_id, "fireteam_id": _team_id, "unit_id": lead_id, "whole_fireteam": true})
	if not bool(walk.get("ok", false)):
		print("RDE_BOARD_REJECT %s base_board=%s" % [tag, walk])
		if not soft: _check(false, "%s: die Besatzung geht an Bord (%s)" % [tag, walk])
		return "base_board:%s" % walk.get("reason", "")
	var sim: Node = personnel.call("get_simulation_root")
	var members: Array = _rg_team_members(_team_id)
	for tick in range(6000):
		if personnel.call("is_pilot_aboard", _craft_id) and bool(_screen.call("_has_homebase_direct_launch_payload_for_craft", _craft_id)) and members.all(func(member: String) -> bool: return _ra_base_status(member) == "aboard"):
			break
		sim.call("_physics_process", 0.05)
		_screen.call("_debug_advance_homebase_direct_boarding", 0.05)
	var ready: bool = bool(personnel.call("is_pilot_aboard", _craft_id)) and bool(_screen.call("_has_homebase_direct_launch_payload_for_craft", _craft_id)) and members.all(func(member: String) -> bool: return _ra_base_status(member) == "aboard")
	if not ready:
		if not soft: _check(false, "%s: Pilot und Nutzlast sind an Bord" % tag)
		return "not_aboard"
	var block: Dictionary = personnel.call("get_departure_block", _craft_id)
	if not block.is_empty():
		print("RDE_BOARD_REJECT %s departure_block=%s" % [tag, block])
		if not soft: _check(false, "%s: Abflugsperre ist leer (%s)" % [tag, block])
		return "departure_block:%s" % block.get("reason", "")
	if not soft: _check(true, "%s: Besatzung (%s) und Pilot an Bord, Abflugsperre leer, Nutzlast bereit" % [tag, lead_id])
	return ""

## Abflug zu Polisa bis zur Landung und Aussteigen der Besatzung. Rueckgabe: "" oder Grund.
func _nd_to_polisa(tag: String) -> String:
	var result: Dictionary = _pk_op("select_destination", {"location_id": "polisa", "job_id": ""})
	if not _check(bool(result.get("ok", false)), "%s: Polisa als Besuch ohne Auftrag gewaehlt (%s)" % [tag, result]): return "select_destination"
	result = _pk_op("start")
	if not _check(bool(result.get("ok", false)), "%s: das Schiff startet von der Basis nach Polisa (%s)" % [tag, result]): return "start:%s" % result.get("reason", "")
	result = _pk_op("space_start_quantum", {"target_orbit_id": "polisa_orbit"})
	if not _check(bool(result.get("ok", false)), "%s: Quantenflug nach Polisa (%s)" % [tag, result]): return "quantum"
	if not _check(await _pk_wait(func(): return String(_pk_space().get("orbit_id", "")) == "polisa_orbit", 20000), "%s: Ankunft im Orbit von Polisa" % tag): return "orbit"
	result = _pk_op("space_begin_approach", {"location_id": "polisa"})
	if not _check(bool(result.get("ok", false)), "%s: Anflug auf Polisa (%s)" % [tag, result]): return "approach"
	if not _check(await _pk_wait(func(): return is_instance_valid(_flow.get("_active_mission")), 60000), "%s: die Polisa-Szene laedt" % tag): return "scene"
	_flow.call("_show_mission")
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	if not _check(await _pk_wait(func(): return String(controller.call("_find_mission_dropship_card_entry", _craft_id).get("state", "")) == "waiting", 90000), "%s: das Schiff erreicht die Landeauswahl" % tag): return "landing_choice"
	var map = load("res://scripts/terrain/terrain_map_data.gd").load_from_file("res://maps/polisa_station.json")
	var view: Node = mission.get_node("Primary3DView")
	var pad: Vector2 = map.get_marker_position("polisa_pad_01")
	view.call("focus_world_position", pad)
	controller.call("_on_mission_dropship_card_set_lz_pressed", _craft_id)
	if not _check(bool(controller.call("_place_lz_from_screen_position", view.call("world_to_screen_position", pad))), "%s: Landeplatz der Station gewaehlt" % tag): return "lz"
	controller.call("_on_mission_dropship_card_drop_pressed", _craft_id)
	if not _check(await _pk_wait(func(): return bool(controller.call("_is_parked_campaign_dropship", _craft_id)), 90000), "%s: das Schiff landet auf Polisa" % tag): return "landing"
	var crew: PackedStringArray = controller.call("_campaign_craft_crew_ids", _craft_id)
	if not _check(not crew.is_empty() and await _pk_wait(func():
		var deployed: Dictionary = controller.get("_deployed_unit_ids")
		for id in crew:
			if not deployed.has(id): return false
		return true, 60000), "%s: die ganze Besatzung steigt aus (%s)" % [tag, crew]): return "crew_out"
	_nd = {"mission": mission, "controller": controller, "registry": mission.get_node("UnitRegistry"), "simulation": mission.get_node("SimulationRoot"), "crew": crew}
	return ""

## Alle Wartenden erscheinen als Bewohner, werden uebernommen, laufen zum Schiff und steigen mit der Besatzung ein.
func _nd_pickup_all(tag: String, waiting: Array) -> bool:
	var mission: Node = _nd.mission
	var controller: Node = _nd.controller
	var registry: Node = _nd.registry
	var simulation: Node = _nd.simulation
	for unit_id: String in waiting:
		_check(not PackedStringArray(_nd.crew).has(unit_id), "%s: %s gehoert nicht zur Besatzung (%s)" % [tag, unit_id, _nd.crew])
	var appeared: bool = await _pk_wait(func():
		for unit_id: String in waiting:
			if not (Dictionary(mission.get_meta("singleplayer_station_personnel", {})).has(unit_id) and registry.get_unit(unit_id) != null and not simulation.call("get_hex_unit_state", unit_id).is_empty()):
				return false
		return true, 60000)
	if not _check(appeared, "%s: alle Wartenden (%s) erscheinen als Bewohner auf Polisa (Darsteller, Bodenzustand)" % [tag, waiting]):
		print("RDE_DIAG residents=", mission.get_meta("singleplayer_station_personnel", {}), " setup=", mission.get_node("MissionSetup").call("get_runtime_selection_status"))
		return false
	for unit_id: String in waiting:
		var claim: Dictionary = _runtime.call("request_operation", "station_claim_resident", {"craft_id": _craft_id, "unit_id": unit_id})
		if not _check(bool(claim.get("ok", false)), "%s: %s wird fuer dieses Schiff uebernommen (%s)" % [tag, unit_id, claim]): return false
		_check(_nd_status(unit_id) == "awaiting_pickup" and _ra_base_status(unit_id) == "station", "%s: %s uebernommen, aber noch nicht abgeflogen: awaiting_pickup und station" % [tag, unit_id])
	var access: Dictionary = controller.call("get_campaign_ground_ship_access", _craft_id)
	if not _check(bool(access.get("ok", false)), "%s: Schiffszugang vorhanden (%s)" % [tag, access]): return false
	for index in range(waiting.size()):
		if not _check(_place_at(simulation, access, String(waiting[index]), Vector2(24.0 * index, 0.0)), "%s: %s steht am Schiff" % [tag, waiting[index]]): return false
	var boarded: Dictionary = _runtime.call("request_operation", "station_board_crew", {"craft_id": _craft_id, "service_location_id": "polisa"})
	var all_in: bool = await _pk_wait(func():
		if not bool(controller.call("get_campaign_pilot_flight_guard", _craft_id).get("ok", false)): return false
		for unit_id: String in waiting:
			if registry.get_unit(unit_id) == null or not bool(registry.get_unit(unit_id).get_meta("dropship_embarked", false)): return false
		return true, 90000)
	if not _check(all_in, "%s: die Besatzung und alle Abgeholten steigen ein (%s)" % [tag, boarded]): return false
	for unit_id: String in waiting:
		_check(_nd_status(unit_id) == "awaiting_pickup" and _ra_base_status(unit_id) == "station", "%s: %s eingestiegen, aber noch nicht abgeflogen: awaiting_pickup und station" % [tag, unit_id])
	return true

## Abflug von Polisa, Rueckflug, Landung daheim. Prueft nach dem Abflug (bestaetigt) den Zustand der Abgeholten.
func _nd_return(tag: String, waiting: Array, used: Dictionary, role_of: Dictionary) -> bool:
	var result: Dictionary = _runtime.call("request_operation", "return_homebase", {"craft_id": _craft_id, "service_location_id": "polisa"})
	if not _check(bool(result.get("ok", false)), "%s: Rueckflug beginnt (%s)" % [tag, result]): return false
	if not _check(await _pk_wait(func(): return String(_pk_space().get("phase", "")) == "orbit" and String(_pk_space().get("orbit_id", "")) == "polisa_orbit", 90000), "%s: Abflug von Polisa bis in den Orbit" % tag): return false
	for unit_id: String in waiting:
		_nd_check_picked_up(tag + " abgeholt", unit_id, int(used[unit_id]), String(role_of.get(unit_id, "operator")))
	result = _pk_op("space_start_quantum", {"target_orbit_id": "moon_orbit"})
	if not _check(bool(result.get("ok", false)), "%s: Quantenflug heim (%s)" % [tag, result]): return false
	if not _check(await _pk_wait(func(): return String(_pk_space().get("orbit_id", "")) == "moon_orbit", 20000), "%s: Ankunft im Heimatorbit" % tag): return false
	result = _pk_op("space_land_homebase")
	if not _check(bool(result.get("ok", false)), "%s: Landung an der Heimatbasis angefordert (%s)" % [tag, result]): return false
	if not _check(await _pk_wait(func():
		for craft: Dictionary in Array(Dictionary(_runtime.call("get_snapshot")).get("crafts", [])):
			if String(craft.get("craft_id", "")) == _craft_id: return String(craft.get("location_id", "")) == "homebase" and not bool(craft.get("busy", true))
		return false, 90000), "%s: das Schiff ist wieder daheim" % tag): return false
	return true

## Daheim: alle an Bord steigen aus; die Abgeholten sind danach wieder an der Basis zu sehen.
func _nd_unboard_all(tag: String, waiting: Array) -> bool:
	_nd_probe_save(tag + " 1 gelandet, vor Neuaufbau der Ansicht")
	for unit_id: String in waiting:
		_check(_ra_base_status(unit_id) == "aboard", "%s: daheim ist %s an Bord (Aussteigen ist ein eigener Befehl)" % [tag, unit_id])
	_flow.call("_show_homebase")
	await process_frame
	_flow.call("_refresh_homebase_screen")
	_nd_probe_save(tag + " 2 nach _show_homebase und Neuaufbau, vor Aussteigen")
	var aboard: Array = _nd_unit_ids_aboard()
	var order: Array = waiting.duplicate()
	for unit_id: String in aboard:
		if not order.has(unit_id):
			order.append(unit_id)
	for unit_id: String in order:
		if _ra_base_status(unit_id) != "aboard":
			continue
		var out: Dictionary = _t6b_base().call("request_operation", "base_unboard", {"craft_id": _craft_id, "unit_id": unit_id})
		var gone: bool = await _pk_wait(func(): return _ra_base_status(unit_id) == "outside", 30000)
		print("RDE_UNBOARD %s %s result=%s" % [tag, unit_id, out])
		# Nur die Abgeholten muessen aussteigen; ein Pilot kann an der Aufnahmekapazitaet der Basis haengen (insufficient_admission_space, nicht Respawn).
		if waiting.has(unit_id):
			_check(gone, "%s: %s steigt daheim aus (%s, Basis-Zustand %s)" % [tag, unit_id, out, _ra_base_status(unit_id)])
	_nd_probe_save(tag + " 3 nach dem Aussteigen")
	var base_sim: Node = _t6b_base().call("get_simulation_root")
	for waited_ms in [0, 3000, 10000]:
		await _pk_wait(func(): return false, int(waited_ms))
		for unit_id: String in order:
			var actor: Node2D = _t6b_base().call("get_actor", unit_id)
			var hex_state: Dictionary = base_sim.call("get_hex_unit_state", unit_id) if base_sim != null and base_sim.has_method("get_hex_unit_state") else {}
			print("RDE_ACTOR %s +%dms %s present=%s visible=%s in_tree=%s base=%s hex_state_empty=%s parent=%s" % [tag, waited_ms, unit_id, actor != null, actor.visible if actor != null else "-", actor.is_visible_in_tree() if actor != null else "-", _ra_base_status(unit_id), hex_state.is_empty(), actor.get_parent().name if actor != null and actor.get_parent() != null else "-"])
	for unit_id: String in waiting:
		var picked_actor: Node2D = _t6b_base().call("get_actor", unit_id)
		_check(picked_actor != null and _ra_base_status(unit_id) == "outside", "%s: %s ist als Darsteller an der Basis da (Basis-Zustand outside)" % [tag, unit_id])
		_check(picked_actor != null and picked_actor.is_visible_in_tree(), "%s: %s ist an der Basis zu sehen (Darsteller sichtbar im Baum)" % [tag, unit_id])
	return true

## Zustand einer Abgeholten: active, Grundausstattung, in keinem Trupp, nicht gesperrt.
func _nd_check_picked_up(tag: String, unit_id: String, respawns_used: int, role: String) -> void:
	var c: Dictionary = _roster_unit(unit_id)
	_check(String(c.get("availability_status", "")) == "active" and Dictionary(c.get("recovery_state", {})).is_empty() and String(c.get("status_text", "")).is_empty(), "%s: %s ist active, Ausfalldaten und Statustext leer (%s)" % [tag, unit_id, c.get("availability_status")])
	_check(int(c.get("respawns_used", -1)) == respawns_used, "%s: %s respawns_used bleibt %d (ist %s)" % [tag, unit_id, respawns_used, c.get("respawns_used")])
	_check(_ra_base_status(unit_id) in ["aboard", "outside", "moving", "idle", "sleeping"], "%s: %s Basis-Zustand ist nicht mehr station (%s)" % [tag, unit_id, _ra_base_status(unit_id)])
	var expected: Dictionary = _pk_recruit_loadout(role)
	var loadout: Dictionary = Dictionary(_rg_loadouts().get(unit_id, {}))
	if expected.is_empty():
		_check(not loadout.is_empty(), "%s: %s hat eine Grundausstattung im Loadout-Snapshot (%s; kein Angebotsprofil fuer Rolle %s)" % [tag, unit_id, loadout, role])
	else:
		_check(loadout == expected, "%s: %s Grundausstattung wie eine frisch Angeworbene (%s gegen %s)" % [tag, unit_id, loadout, expected])
	var bag: Dictionary = Dictionary(_rg_inventory().get("unit:%s:backpack" % unit_id, {}))
	_check(not bag.is_empty() and Dictionary(bag.get("items", {})).is_empty(), "%s: %s leerer Rucksack" % [tag, unit_id])
	var stray: Array = _rg_stray(unit_id, RESPAWN_KEEPS + ["supply.inventory", "loadout state", "flow._selected_unit_ids", "flow._homebase_staged_unit_ids", "craft.staged_unit_ids", "craft.member_loadouts"])
	_check(stray.is_empty(), "%s: %s steht in keinem alten Trupp und nicht als Pilot (uebrig: %s)" % [tag, unit_id, stray])
	_check(String(Dictionary(_t6b_base().get("_unavailable_unit_reasons")).get(unit_id, "")).is_empty(), "%s: keine Einsatzsperre fuer %s" % [tag, unit_id])

## Neuer Einsatz mit einem Trupp aus members: aufstellen, Auftrag, einschiffen, Start gelingt (kein launch_blocked).
func _nd_start_new_mission(tag: String, members: Array, pilot_id: String) -> bool:
	var known: Array = _rg_team_ids()
	var added: Dictionary = _screen.call("request_operation", "add_fireteam", {})
	if not _check(bool(added.get("ok", false)), "%s: neuer Trupp fuer den naechsten Einsatz (%s)" % [tag, added]): return false
	var new_team: String = ""
	for team_id: String in _rg_team_ids():
		if not known.has(team_id):
			new_team = team_id
	for unit_id: String in members:
		var assigned: Dictionary = _screen.call("request_operation", "assign", {"unit_id": unit_id, "fireteam_id": new_team})
		if not _check(bool(assigned.get("ok", false)), "%s: %s laesst sich in den neuen Trupp einteilen (%s)" % [tag, unit_id, assigned]): return false
	_team_id = new_team
	var job: Dictionary = _screen.call("request_operation", "accept_job", {"job_id": NODEAD_JOB})
	_check(bool(job.get("ok", false)), "%s: Auftrag angenommen (%s)" % [tag, job])
	var dest: Dictionary = _screen.call("request_operation", "select_destination", {"location_id": NODEAD_LOCATION, "job_id": NODEAD_JOB})
	_check(bool(dest.get("ok", false)), "%s: Ziel gewaehlt (%s)" % [tag, dest])
	var reason: String = await _nd_board_crew(tag + " (neuer Einsatz)", String(members[0]), pilot_id)
	if not reason.is_empty(): return false
	var start: Dictionary = _pk_op("start")
	return _check(bool(start.get("ok", false)) and String(start.get("reason", "")) != "launch_blocked", "%s: der Start des neuen Einsatzes gelingt, kein launch_blocked (%s)" % [tag, start])

## Speichern und Fortsetzen; danach sind Flow, Ansicht und Laufzeit neu.
func _nd_save_and_continue(tag: String) -> bool:
	var saved: Dictionary = _flow.call("request_campaign_save")
	if not _check(bool(saved.get("ok", false)), "%s: Speichern an der Basis gelingt (%s)" % [tag, saved.get("reason", "")]): return false
	await _end_sortie()
	await create_timer(0.5).timeout
	if not await _t6b_open("campaign", "continue"): return false
	_flow.set("_active_singleplayer_identity", {})
	return true

# ---------- Lage A ----------

func _nd_a() -> void:
	if not await _t6b_new_four(): return
	_flow.set("_active_singleplayer_identity", {})
	_nd_craft()
	var roster_before: Array = _t6b_roster_ids()
	var applied: Dictionary = _nd_deliver({LEAD_A: "fit", PILOT_ID: "fit", LEAD_B: "down", SHOOTER_C: "down"}, "A")
	var dead: Array = [LEAD_B, SHOOTER_C]
	var sorted_ids: Array = Array(PackedStringArray(applied.get("respawn_unit_ids", PackedStringArray())))
	sorted_ids.sort()
	var expected_ids: Array = dead.duplicate()
	expected_ids.sort()
	if not _check(sorted_ids == expected_ids and _nd_status(LEAD_B) == "respawning" and _nd_status(SHOOTER_C) == "respawning" and _nd_status(LEAD_A) in ["", "active"], "A: B und C sind gestorben (respawning), A einsatzfaehig, Pilot geschuetzt (%s)" % [sorted_ids]): return
	var used: Dictionary = {LEAD_B: int(_roster_unit(LEAD_B).get("respawns_used", -1)), SHOOTER_C: int(_roster_unit(SHOOTER_C).get("respawns_used", -1))}
	_check(used[LEAD_B] == 1 and used[SHOOTER_C] == 1 and _t6b_roster_ids() == roster_before, "A: respawns_used 1 je Person, Kader unveraendert")
	# Kein Sprung: ein einzelner Takt macht noch niemanden zum Wartenden.
	_flow.call("_tick_personnel_recovery", 2.0)
	_check(_nd_status(LEAD_B) == "respawning" and _nd_status(SHOOTER_C) == "respawning", "A: nach einem Takt weiter respawning")
	var ticks: int = _nd_mature(dead)
	print("RDE_A_TICKS ", ticks)
	if not _check(_nd_status(LEAD_B) == "awaiting_pickup" and _nd_status(SHOOTER_C) == "awaiting_pickup", "A: die Uhr laeuft ueber den echten Takt ab (%d Takte), beide awaiting_pickup" % ticks): return
	_check(_ra_base_status(LEAD_B) == "station" and _ra_base_status(SHOOTER_C) == "station", "A: beide stehen auf Polisa (station)")
	# M2: Speichern, Fortsetzen: weiter gesperrt, nicht einteilbar, nicht einschiffbar, in keiner Trupp-Definition.
	if not await _nd_save_and_continue("A (M2)"): return
	_nd_craft()
	for unit_id: String in dead:
		_check(_nd_status(unit_id) == "awaiting_pickup" and _ra_base_status(unit_id) == "station", "A (M2): nach dem Fortsetzen wartet %s weiter (%s / %s)" % [unit_id, _nd_status(unit_id), _ra_base_status(unit_id)])
		_check(_rg_definition_places(unit_id).is_empty(), "A (M2): %s steht in keiner Trupp-Definition (%s)" % [unit_id, _rg_definition_places(unit_id)])
		var reason_text: String = String(Dictionary(_t6b_base().get("_unavailable_unit_reasons")).get(unit_id, ""))
		_check(not reason_text.is_empty(), "A (M2): %s ist gesperrt (%s)" % [unit_id, reason_text])
	if not _nd_ensure_team_for(LEAD_A): return
	var to_team: Dictionary = _screen.call("request_operation", "assign", {"unit_id": LEAD_B, "fireteam_id": _team_id})
	_check(not bool(to_team.get("ok", false)), "A (M2): B laesst sich nicht in einen Trupp einteilen (%s)" % [to_team])
	var single: Dictionary = _ra_board(SHOOTER_C)
	_check(not bool(single.get("ok", false)), "A (M2): C laesst sich nicht einschiffen (%s)" % [single])
	_check(_rg_definition_places(LEAD_B).is_empty() and _rg_definition_places(SHOOTER_C).is_empty(), "A (M2): auch nach dem Versuch in keiner Trupp-Definition")
	# Flug.
	var board_reason: String = await _nd_board_crew("A", LEAD_A, PILOT_ID)
	if not board_reason.is_empty(): return
	var fail_stage: String = await _nd_to_polisa("A")
	if not fail_stage.is_empty(): return
	if not await _nd_pickup_all("A", dead): return
	if not await _nd_return("A", dead, used, {LEAD_B: "operator", SHOOTER_C: "operator"}): return
	if not await _nd_unboard_all("A", dead): return
	# Speichern daheim nach der Rueckkehr: kurze Wartezeit zulassen, dann Erwartung.
	var saved: Dictionary = {}
	var deadline := Time.get_ticks_msec() + 10000
	while not bool(saved.get("ok", false)) and Time.get_ticks_msec() < deadline:
		saved = _nd_probe_save("A 4 Wiederholung")
		if not bool(saved.get("ok", false)):
			await _pk_wait(func(): return false, 2000)
	# Speichern, erster Teil / 21.11.: Frueher war das ein BEFUND (gemessen, nicht vom Respawn): Nach JEDEM Polisa-Besuch hielt die Meta-Szene die Orts-Instanz
	# als aktiven Einsatz, Speichern ging ueber den Einsatzweg und wurde mit mission_identity_mismatch abgelehnt (job_id des Besuchs ist leer).
	# Seit dem Abschnitt "Speichern, erster Teil" gibt die Heimlandung die Ortsinstanz eines Besuchs ohne Auftrag frei (meta_layer_flow.gd
	# _release_location_for_waiting_retreat / _campaign_location_visit_idle): Speichern daheim nach dem Polisa-Besuch KLAPPT.
	_check(bool(saved.get("ok", false)), "A: Speichern an der Heimatbasis nach der Rueckkehr von Polisa klappt (Speichern, erster Teil / 21.11.; Grund: %s, ok: %s)" % [saved.get("reason", ""), saved.get("ok", false)])
	_check(_t6b_roster_ids() == roster_before, "A: Kader nach der Rueckkehr unveraendert")
	_check(_flow.call("_campaign_roster_problems", Array(_flow.get("_all_team_units"))).is_empty(), "A: Kader bleibt spielbar")
	await _nd_start_new_mission("A", [LEAD_B, SHOOTER_C], PILOT_ID)

# ---------- Lage E ----------

func _nd_e() -> void:
	if not await _t6b_new_four(): return
	_flow.set("_active_singleplayer_identity", {})
	var before: Array = _rg_definition_places(LEAD_B)
	print("RDE_E_BEFORE ", before)
	_check(before.any(func(place: String) -> bool: return place.begins_with("payload fireteam")), "E: Fixture: B steht in einem eingeteilten Trupp (%s)" % [before])
	if not await _nd_save_and_continue("E"): return
	var after_continue: Array = _rg_definition_places(LEAD_B)
	print("RDE_E_AFTER_CONTINUE ", after_continue)
	if not _check(not after_continue.is_empty(), "E: Fixture: nach Speichern und Fortsetzen steht B in einem Trupp (%s)" % [after_continue]): return
	var fob: Variant = _flow.call("_get_fob_screen")
	var fob_places: Array = after_continue.filter(func(place: String) -> bool: return place.begins_with("fob "))
	print("RDE_E_FOB present=", fob != null, " places=", fob_places)
	_check(not fob_places.is_empty(), "E: Fixture: die FOB-Ansicht fuehrt B als Mitglied (%s)" % [after_continue])
	var applied: Dictionary = _nd_deliver({LEAD_A: "fit", PILOT_ID: "fit", LEAD_B: "down", SHOOTER_C: "fit"}, "E")
	_check(PackedStringArray(applied.get("respawn_unit_ids", PackedStringArray())) == PackedStringArray([LEAD_B]) and _nd_status(LEAD_B) == "respawning", "E: B ist gestorben (respawning)")
	_nd_check_e("direkt nach dem Ende")
	_flow.call("_refresh_homebase_screen")
	_nd_check_e("nach _refresh_homebase_screen")
	var other: Dictionary = _screen.call("request_operation", "add_fireteam", {})
	var moved: Dictionary = _screen.call("request_operation", "assign", {"unit_id": LEAD_A, "fireteam_id": String(_rg_team_ids()[-1])})
	var back: Dictionary = _screen.call("request_operation", "assign", {"unit_id": LEAD_A, "fireteam_id": _nd_team_of(LEAD_A) if not _nd_team_of(LEAD_A).is_empty() else String(_rg_team_ids()[0])})
	print("RDE_E_EDIT add=", other, " assign=", moved, " back=", back)
	_check(bool(other.get("ok", false)), "E: Trupp-Bearbeitung an anderem Trupp laeuft")
	_nd_check_e("nach Trupp-Bearbeitung an anderem Trupp")
	# R4f: Speichern und Fortsetzen darf B nicht zurueckbringen (auch nicht in die FOB-Ansicht).
	if not await _nd_save_and_continue("E (nach dem Tod)"): return
	_nd_check_e("nach erneutem Speichern und Fortsetzen")
	# R4f: Nach dem Abholen ist B wieder einteilbar wie jede andere Person.
	var ticks: int = _nd_mature([LEAD_B])
	if not _check(_nd_status(LEAD_B) == "awaiting_pickup", "E: B wartet auf Abholung nach %d Takten" % ticks): return
	_nd_craft()
	var boarded: Dictionary = _t6b_base().call("mark_recruit_remote", LEAD_B, _craft_id)
	if not _check(bool(boarded.get("ok", false)), "E: Aufbau: B ist an Bord des Heimschiffs (%s)" % [boarded]): return
	var picked: Dictionary = _flow.call("complete_campaign_pickup", LEAD_B)
	if not _check(bool(picked.get("ok", false)) and _nd_status(LEAD_B) == "active", "E: B ist abgeholt und aktiv (%s)" % [picked]): return
	var out: Dictionary = _t6b_base().call("request_operation", "base_unboard", {"unit_id": LEAD_B, "craft_id": _craft_id})
	await _pk_wait(func(): return _ra_base_status(LEAD_B) == "outside", 60000)
	if not _check(bool(out.get("ok", false)) and _ra_base_status(LEAD_B) == "outside", "E: Aufbau: B steht an der Basis (%s)" % [out]): return
	var known_after: Array = _rg_team_ids()
	var added_after: Dictionary = _screen.call("request_operation", "add_fireteam", {})
	var team_after: String = ""
	for team_id: String in _rg_team_ids():
		if not known_after.has(team_id):
			team_after = team_id
	var reassigned: Dictionary = _screen.call("request_operation", "assign", {"unit_id": LEAD_B, "fireteam_id": team_after})
	_check(bool(added_after.get("ok", false)) and bool(reassigned.get("ok", false)) and _rg_team_members(team_after).has(LEAD_B), "E: B nach dem Abholen wieder einteilbar (%s / %s)" % [added_after, reassigned])

func _nd_check_e(tag: String) -> void:
	var places: Array = _rg_definition_places(LEAD_B)
	print("RDE_E ", tag, " B=", places, " loadouts_has_B=", _rg_loadouts().has(LEAD_B))
	var base_places: Array = places.filter(func(place: String) -> bool: return not place.begins_with("fob "))
	var fob_places: Array = places.filter(func(place: String) -> bool: return place.begins_with("fob "))
	_check(base_places.is_empty(), "E (%s): B steht in keiner Trupp-Definition der Basisansicht und des Kampagnenstands (%s)" % [tag, base_places])
	_check(fob_places.is_empty(), "E (%s): BEFUND R1: B steht auch nicht mehr in der FOB-Ansicht (get_fireteam_definitions); _campaign_fob_fireteam_definitions laesst Wiederkehrer durch, weil sie im Kader stehen (%s)" % [tag, fob_places])
	_check(not _rg_loadouts().has(LEAD_B), "E (%s): get_snapshot der Loadouts enthaelt B nicht" % tag)

# ---------- Lage C ----------

func _nd_c() -> void:
	if not await _t6b_new_four(): return
	_flow.set("_active_singleplayer_identity", {})
	_nd_craft()
	_ra_set(LEAD_B, {"roster_role_category": "medic"})
	var roster_before: Array = _t6b_roster_ids()
	_nd_deliver({LEAD_A: "down", PILOT_ID: "fit", LEAD_B: "fit", SHOOTER_C: "fit"}, "C")
	if not _check(_nd_status(LEAD_A) == "respawning" and _t6b_roster_ids() == roster_before and _t6b_roster_ids()[0] == LEAD_A, "C: A (Platz 0, der einzige Operator) ist gestorben, Reihenfolge unveraendert"): return
	var used: Dictionary = {LEAD_A: int(_roster_unit(LEAD_A).get("respawns_used", -1))}
	var ticks: int = _nd_mature([LEAD_A])
	if not _check(_nd_status(LEAD_A) == "awaiting_pickup", "C: A wartet auf Polisa nach %d Takten" % ticks): return
	_check(_flow.call("_campaign_roster_problems", Array(_flow.get("_all_team_units"))).is_empty(), "C: waehrend A wartet, bleibt der Kader spielbar (%s)" % [_flow.call("_campaign_roster_problems", Array(_flow.get("_all_team_units")))])
	if not _nd_ensure_team_for(LEAD_B): return
	if await _nd_board_crew("C", LEAD_B, PILOT_ID) != "": return
	if await _nd_to_polisa("C") != "": return
	if not await _nd_pickup_all("C", [LEAD_A]): return
	if not await _nd_return("C", [LEAD_A], used, {LEAD_A: "operator"}): return
	if not await _nd_unboard_all("C", [LEAD_A]): return
	_check(_t6b_roster_ids() == roster_before and _t6b_roster_ids()[0] == LEAD_A, "C: Reihenfolge im Kader nach der Abholung unveraendert, A auf Platz 0")
	_check(_flow.call("_campaign_roster_problems", Array(_flow.get("_all_team_units"))).is_empty(), "C: _campaign_roster_problems nach der Abholung leer")

# ---------- Lage B ----------

func _nd_b() -> void:
	if not await _t6b_new_four(): return
	_flow.set("_active_singleplayer_identity", {})
	_nd_craft()
	var dead: Array = [LEAD_B, SHOOTER_C]
	_nd_deliver({LEAD_A: "fit", PILOT_ID: "fit", LEAD_B: "down", SHOOTER_C: "down"}, "B")
	var used: Dictionary = {LEAD_B: int(_roster_unit(LEAD_B).get("respawns_used", -1)), SHOOTER_C: int(_roster_unit(SHOOTER_C).get("respawns_used", -1))}
	var ticks: int = _nd_mature(dead)
	if not _check(_nd_status(LEAD_B) == "awaiting_pickup" and _nd_status(SHOOTER_C) == "awaiting_pickup", "B: B und C warten (%d Takte)" % ticks): return
	# A wird in einem weiteren Einsatz leicht verwundet (A und Pilot im Einsatz, A lag, kam wieder hoch).
	_nd_deliver({LEAD_A: "wounded", PILOT_ID: "fit"}, "B")
	if not _check(_nd_status(LEAD_A) == "wounded", "B: A ist verwundet (%s)" % _nd_status(LEAD_A)): return
	# Messung: Trupp nur aus dem zugeteilten Piloten.
	var known: Array = _rg_team_ids()
	var added: Dictionary = _screen.call("request_operation", "add_fireteam", {})
	_check(bool(added.get("ok", false)), "B: neuer Trupp (%s)" % [added])
	for team_id: String in _rg_team_ids():
		if not known.has(team_id):
			_team_id = team_id
	var assigned: Dictionary = _screen.call("request_operation", "assign", {"unit_id": PILOT_ID, "fireteam_id": _team_id})
	print("RDE_B_ASSIGN_PILOT ", assigned)
	var gate: String = ""
	if not bool(assigned.get("ok", false)):
		gate = "assign:%s" % assigned.get("reason", "")
	else:
		gate = await _nd_board_crew("B", PILOT_ID, PILOT_ID, true)
	print("RDE_B_MEASURE pilot_only_gate=", gate if not gate.is_empty() else "frei")
	if gate.is_empty():
		var board_ok: bool = _check(true, "B: ein Trupp nur aus dem Piloten laesst sich bilden und einschiffen, Abflugsperre leer")
		if board_ok and await _nd_to_polisa("B (nur Pilot)") == "":
			if await _nd_pickup_all("B (nur Pilot)", dead):
				if await _nd_return("B (nur Pilot)", dead, used, {LEAD_B: "operator", SHOOTER_C: "operator"}):
					await _nd_unboard_all("B (nur Pilot)", dead)
		return
	print("RDE_B_FALLBACK reason=", gate)
	# Kein Trupp nur aus dem Piloten: nach Ablauf der Verwundung von A fliegt der Spieler wie in Lage A.
	var healed: bool = false
	for tick in range(400):
		_flow.call("_tick_personnel_recovery", 2.0)
		if _nd_status(LEAD_A) == "active":
			healed = true
			break
	if not _check(healed, "B (Rueckfall): die Verwundung von A laeuft ueber den echten Takt ab (A %s)" % _nd_status(LEAD_A)): return
	if not _nd_ensure_team_for(LEAD_A): return
	if await _nd_board_crew("B (Rueckfall)", LEAD_A, PILOT_ID) != "": return
	if await _nd_to_polisa("B (Rueckfall)") != "": return
	if not await _nd_pickup_all("B (Rueckfall)", dead): return
	if not await _nd_return("B (Rueckfall)", dead, used, {LEAD_B: "operator", SHOOTER_C: "operator"}): return
	await _nd_unboard_all("B (Rueckfall)", dead)

# ---------- Lage D ----------

func _nd_d() -> void:
	if not await _t6b_new_four(): return
	_flow.set("_active_singleplayer_identity", {})
	_nd_craft()
	# Ein zweiter Pilot D wird zugeteilt; der Pilot auf Platz 1 (campaign_pilot) ist nicht mehr zugeteilt, also nicht geschuetzt.
	var template: Dictionary = _roster_unit(PILOT_ID).duplicate(true)
	var profile: Dictionary = template.duplicate(true)
	profile["unit_id"] = NODEAD_PILOT_D
	profile["display_name"] = "Dora Dietz"
	profile["fireteam_id"] = ""
	var added: Dictionary = _flow.call("register_campaign_recruit", profile)
	if not _check(bool(added.get("ok", false)), "D: Aufbau: der zweite Pilot kommt in den Kader (%s)" % [added]): return
	var simulation: Node = _runtime.get("_simulation")
	simulation.call("request_personnel_loadout_command", "configure_roster", {"roster": [profile]})
	simulation.call("request_personnel_loadout_command", "set_loadout", {"unit_id": NODEAD_PILOT_D, "loadout": {"armor": "suit", "weapon_1": "pistol", "weapon_2": "none"}})
	_runtime.get("_supply").call("configure_inventory", [NODEAD_PILOT_D], [], true)
	var assigned: Dictionary = _pk_op("pilot", {"unit_id": NODEAD_PILOT_D})
	if not _check(bool(assigned.get("ok", false)) and not bool(_runtime.call("is_person_protected_from_death", PILOT_ID)) and bool(_runtime.call("is_person_protected_from_death", NODEAD_PILOT_D)), "D: Aufbau: D ist zugeteilter Pilot, der Pilot auf Platz 1 nicht mehr (%s)" % [assigned]): return
	var roster_before: Array = _t6b_roster_ids()
	_nd_deliver({LEAD_A: "fit", NODEAD_PILOT_D: "fit", PILOT_ID: "down", LEAD_B: "fit", SHOOTER_C: "fit"}, "D")
	if not _check(_nd_status(PILOT_ID) == "respawning" and _t6b_roster_ids() == roster_before and _t6b_roster_ids()[1] == PILOT_ID, "D: der Pilot auf Platz 1 ist gestorben (respawning), Reihenfolge unveraendert"): return
	var used: Dictionary = {PILOT_ID: int(_roster_unit(PILOT_ID).get("respawns_used", -1))}
	var ticks: int = _nd_mature([PILOT_ID])
	if not _check(_nd_status(PILOT_ID) == "awaiting_pickup", "D: der Pilot wartet auf Polisa (%d Takte)" % ticks): return
	_flow.call("_refresh_homebase_screen")
	var busy: Dictionary = _pk_op("pilot", {"unit_id": PILOT_ID})
	_check(not bool(busy.get("ok", false)) and String(busy.get("reason", "")) == "unit_busy", "D: wartend laesst sich der Pilot nicht als Pilot zuteilen, unit_busy (%s)" % [busy])
	_check(_flow.call("_campaign_roster_problems", Array(_flow.get("_all_team_units"))).is_empty(), "D: _campaign_roster_problems leer")
	if not _nd_ensure_team_for(LEAD_A): return
	if await _nd_board_crew("D", LEAD_A, NODEAD_PILOT_D) != "": return
	if await _nd_to_polisa("D") != "": return
	if not await _nd_pickup_all("D", [PILOT_ID]): return
	if not await _nd_return("D", [PILOT_ID], used, {PILOT_ID: "pilot"}): return
	if not await _nd_unboard_all("D", [PILOT_ID]): return
	_flow.call("_refresh_homebase_screen")
	var again: Dictionary = _pk_op("pilot", {"unit_id": PILOT_ID})
	_check(bool(again.get("ok", false)) and String(again.get("reason", "")) != "unit_busy", "D: nach dem Abholen laesst er sich wieder als Pilot zuteilen (%s)" % [again])
	_check(_t6b_roster_ids() == roster_before and _flow.call("_campaign_roster_problems", Array(_flow.get("_all_team_units"))).is_empty(), "D: Kader unveraendert und spielbar")

# ---------- S: Vergleichsmessung ohne Tote ----------

## Gleicher Flug nach Polisa und zurueck, aber ohne Ausfall und ohne Abholen: Speichern daheim (Vergleich zu Lage A).
func _nd_s() -> void:
	if not await _t6b_new_four(): return
	_flow.set("_active_singleplayer_identity", {})
	_nd_craft()
	if not _nd_ensure_team_for(LEAD_A): return
	if await _nd_board_crew("S", LEAD_A, PILOT_ID) != "": return
	if await _nd_to_polisa("S") != "": return
	var result: Dictionary = _runtime.call("request_operation", "return_homebase", {"craft_id": _craft_id, "service_location_id": "polisa"})
	if not _check(bool(result.get("ok", false)), "S: Rueckflug beginnt (%s)" % [result]): return
	if not _check(await _pk_wait(func(): return String(_pk_space().get("phase", "")) == "orbit" and String(_pk_space().get("orbit_id", "")) == "polisa_orbit", 90000), "S: Abflug von Polisa bis in den Orbit"): return
	result = _pk_op("space_start_quantum", {"target_orbit_id": "moon_orbit"})
	if not _check(bool(result.get("ok", false)), "S: Quantenflug heim"): return
	if not _check(await _pk_wait(func(): return String(_pk_space().get("orbit_id", "")) == "moon_orbit", 20000), "S: Ankunft im Heimatorbit"): return
	result = _pk_op("space_land_homebase")
	if not _check(bool(result.get("ok", false)), "S: Landung angefordert"): return
	if not _check(await _pk_wait(func():
		for craft: Dictionary in Array(Dictionary(_runtime.call("get_snapshot")).get("crafts", [])):
			if String(craft.get("craft_id", "")) == _craft_id: return String(craft.get("location_id", "")) == "homebase" and not bool(craft.get("busy", true))
		return false, 90000), "S: das Schiff ist wieder daheim"): return
	await _nd_unboard_all("S", [])
	var saved: Dictionary = _nd_probe_save("S 4 nach allem")
	print("RDE_S_RESULT save_ok=", saved.get("ok", false), " reason=", saved.get("reason", ""))
	# Speichern, erster Teil / 21.11.: war ein BEFUND (mission_identity_mismatch), jetzt klappt es (die Heimlandung gibt die Ortsinstanz frei).
	_check(bool(saved.get("ok", false)), "S: ohne Tote: Speichern daheim nach dem Polisa-Besuch klappt (Speichern, erster Teil / 21.11.; Grund: %s)" % [saved.get("reason", "")])

# ---------- M1 ----------

## M1 (aus der Pruefung von R4a): Schlaegt park_pickup_person fehl (nur bei kaputtem Darsteller; wie campaign_respawn_gear_verifier G6 erzwungen),
## sagt der Kader respawning, der Basis-Zustand bleibt der alte. Gemessen: Speichern an der Basis, Ablauf der Uhr, Fertigstellung der Abholung.
## Das Abholen auf Polisa selbst braucht den Basis-Zustand station (Bewohner-Weg) und ist in diesem Zustand nicht erreichbar: nur Messung.
func _nd_m1() -> void:
	if not await _t6b_new_four(): return
	_flow.set("_active_singleplayer_identity", {})
	_nd_craft()
	var base: Node = _t6b_base()
	if not _check(bool(base.call("_requires_hex_ground")), "M1: Fixture: die Basis laeuft auf dem Hex-Boden"): return
	var actor: Node = base.call("get_actor", SHOOTER_C)
	if not _check(actor != null, "M1: Fixture: C hat einen Darsteller"): return
	var base_before: String = _ra_base_status(SHOOTER_C)
	actor.queue_free()
	# Vergleich ohne Tod: ein freigegebener Darsteller allein sperrt das Speichern (Messung des Zustands vor dem Ausfall).
	var baseline: Dictionary = _flow.call("request_campaign_save")
	print("RDE_M1_BASELINE_SAVE ok=", baseline.get("ok", false), " reason=", baseline.get("reason", ""))
	_nd_deliver({LEAD_A: "fit", PILOT_ID: "fit", LEAD_B: "fit", SHOOTER_C: "down"}, "M1")
	var base_after: String = _ra_base_status(SHOOTER_C)
	print("RDE_M1_STATE roster=", _nd_status(SHOOTER_C), " base_before=", base_before, " base_after=", base_after)
	_check(_nd_status(SHOOTER_C) == "respawning" and base_after == base_before, "M1: der Kader sagt respawning, der Basis-Zustand bleibt der alte (%s gegen %s)" % [base_after, base_before])
	var saved: Dictionary = _flow.call("request_campaign_save")
	print("RDE_M1_SAVE ok=", saved.get("ok", false), " reason=", saved.get("reason", ""))
	# BEFUND-Vergleich: Speichern ist mit dem Tod nicht schlechter als ohne ihn (gleiches Ergebnis wie die Messung davor).
	_check(bool(saved.get("ok", false)) == bool(baseline.get("ok", false)) and String(saved.get("reason", "")) == String(baseline.get("reason", "")), "M1: Speichern an der Basis ist mit gescheiterter Freigabe nicht schlechter als vorher (jetzt ok=%s %s, vorher ok=%s %s)" % [saved.get("ok", false), saved.get("reason", ""), baseline.get("ok", false), baseline.get("reason", "")])
	_nd_mature([SHOOTER_C])
	_check(_nd_status(SHOOTER_C) == "awaiting_pickup", "M1: die Uhr laeuft ab, C wartet (Kader)")
	var marked: Dictionary = base.call("mark_recruit_remote", SHOOTER_C, _craft_id)
	print("RDE_M1_MARK ", marked, " base=", _ra_base_status(SHOOTER_C))
	var done: Dictionary = _flow.call("complete_campaign_pickup", SHOOTER_C)
	print("RDE_M1_COMPLETE ", done, " status=", _nd_status(SHOOTER_C))
	_check(bool(done.get("ok", false)) and _nd_status(SHOOTER_C) == "active", "M1: die Fertigstellung der Abholung gelingt auch dann (%s)" % [done])
	var saved_after: Dictionary = _flow.call("request_campaign_save")
	print("RDE_M1_SAVE_AFTER ok=", saved_after.get("ok", false), " reason=", saved_after.get("reason", ""))
	_check(bool(saved_after.get("ok", false)) == bool(baseline.get("ok", false)) and String(saved_after.get("reason", "")) == String(baseline.get("reason", "")), "M1: Speichern an der Basis nach der Abholung weiter wie vorher (jetzt ok=%s %s, vorher ok=%s %s)" % [saved_after.get("ok", false), saved_after.get("reason", ""), baseline.get("ok", false), baseline.get("reason", "")])
	# Offener Punkt (nur Messung, oben RDE_M1_MARK): mark_recruit_remote lehnt mit base_actor_unbound ab; das Abholen auf Polisa verlangt den Basis-Zustand station.
