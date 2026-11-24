extends "res://scripts/tests/campaign_five_actual_sorties_verifier.gd"
## Pruefer (nur Beobachtung, Untersuchung "Datapad nach Heimkehr"): stellt Bjoerns Weg im ersten Kampagnenauftrag nach.
## Variante ueber die Umgebungsvariable SB_PROBE_VARIANT:
##   A (Vorgabe) Daten ganz sichern, Trupp nur per Bewegungsbefehl zum Schiff, KEIN Einsteigen, warten, dann Knopf "Rueckflug"
##   B           Daten-Stelle nur angefangen (Haltezeit nicht um), Trupp weg zum Schiff, dann Knopf "Rueckflug"
##   D           Daten ganz sichern, Rechtsklick auf das Schiff (Einsteigen = request_campaign_extraction): alle an Bord, nur der Rueckkehr-Schritt offen
##   C           Daten NICHT gesichert, Trupp laeuft zum Schiff, Knopf "Rueckflug": erster Klick fragt nur nach, zweiter Klick ist der Rueckzug
##   U           Daten ganz sichern, dann die 3-Sekunden-Benutzen-Stelle "ship_return" (wie der Kampagnenlauf): unveraendert
## Erwartung (Entscheidung des Auftraggebers): Wer mit allen an Bord abfliegt und nur noch den Rueckkehr-Schritt offen hat, hat den Auftrag erfuellt
## (A, B, D, U: Heimkehr, Hochladen, Auftrag abgeschlossen, kein Rueckzug). Ein echter Rueckzug (C) passiert nur nach Rueckfrage.
## Die Pruefungen sind aus Spielersicht formuliert; nichts wird angepasst, damit es gruen wird.
const MAP_PATH := "res://maps/satellite_crash_site.json"
var _variant := "A"

func _chip_containers() -> Array:
	var found: Array = []
	var inventory: Dictionary = Dictionary(_supply().get("inventory", {}))
	for id in inventory:
		var items: Dictionary = Dictionary(Dictionary(inventory[id]).get("items", {}))
		if int(items.get("satellite_chip", 0)) > 0:
			found.append(String(id))
	return found

func _brief(mission: Node) -> String:
	if not is_instance_valid(mission): return "mission=weg"
	var controller: Node = mission.get_node("TacticalController")
	var simulation: Node = mission.get_node("SimulationRoot")
	var driver: Node = mission.get_node("CombatLoopDriver")
	var positions: Array = []
	var ids: Array = _crew_ids.duplicate()
	for id in ids:
		var logical: Variant = simulation.call("get_hex_logical_unit_position", String(id))
		positions.append("%s=%s" % [id, str(logical) if logical is Vector2 else "an_bord/kein_Hex"])
	var card: Dictionary = Dictionary(controller.call("_find_mission_dropship_card_entry", _craft_id))
	var gates: Dictionary = driver.call("get_mission_scenario_runtime_gate_snapshot")
	return "tick=%d card=%s parked=%s steps=%s pos=[%s]" % [int(simulation.call("get_tick")), String(card.get("state", "?")), str(controller.call("_is_parked_campaign_dropship", _craft_id)), str(gates.get("completed_step_ids", [])), ", ".join(positions)]

func _obs(tag: String) -> Dictionary:
	var d: Dictionary = {"tag": tag}
	var mission: Node = _flow.call("get_mission_for_craft", _craft_id)
	d["mission_alive"] = is_instance_valid(mission)
	d["flow_active_mission_null"] = _flow.get("_active_mission") == null
	var sp: Dictionary = _space()
	d["space_phase"] = String(sp.get("phase", ""))
	d["orbit"] = String(sp.get("orbit_id", ""))
	var job: Dictionary = Dictionary(Dictionary(_campaign().get("jobs", {})).get("satellite_recovery", {}))
	d["job_status"] = String(job.get("status", ""))
	d["chip_in"] = _chip_containers()
	if is_instance_valid(mission):
		var controller: Node = mission.get_node("TacticalController")
		var driver: Node = mission.get_node("CombatLoopDriver")
		var gates: Dictionary = driver.call("get_mission_scenario_runtime_gate_snapshot")
		d["steps_done"] = gates.get("completed_step_ids", [])
		d["all_gates_complete"] = gates.get("all_gates_complete", false)
		var states: Dictionary = driver.call("get_mission_interaction_runtime_states")
		for iid in ["satellite_data", "ship_return"]:
			var s: Dictionary = Dictionary(states.get(iid, {}))
			d[iid] = {"complete": s.get("complete", false), "step": s.get("step_id", ""), "keys": s.keys()}
		var use_snapshot: Dictionary = controller.call("get_mission_interaction_runtime_use_state_snapshot")
		for iid in ["satellite_data", "ship_return"]:
			var e: Dictionary = _find_interaction(use_snapshot, iid)
			d[iid + "_use"] = {"status": e.get("runtime_use_status", ""), "progress": e.get("progress", null), "blocked": e.get("blocked", null), "dist": e.get("distance_world", null)}
		d["card"] = Dictionary(controller.call("_find_mission_dropship_card_entry", _craft_id)).get("state", "?")
		d["parked"] = controller.call("_is_parked_campaign_dropship", _craft_id)
		d["pilot_guard"] = controller.call("get_campaign_pilot_flight_guard", _craft_id)
		d["deployed"] = Dictionary(controller.get("_deployed_unit_ids")).keys()
		d["embarked"] = var_to_str(controller.get("_embarked_unit_ids"))
		d["last_cmd"] = controller.get("_last_command_text")
		d["extraction_pending"] = controller.get("_campaign_extraction_craft_id")
	print("PROBE_OBS ", var_to_str(d).replace("\n", " "))
	return d

func _people_at_base() -> Array:
	var result: Array = []
	var personnel: Node = _runtime.call("get_base_personnel_runtime")
	if personnel == null: return result
	for person: Dictionary in Array(personnel.call("get_snapshot").get("units", [])):
		result.append("%s:%s:%s" % [String(person.unit_id), String(person.status), String(person.craft_id)])
	return result

## wartet bis zu seconds Wanduhrsekunden, druckt alle 3 s eine Kurzzeile; stop liefert true zum Abbruch
func _watch(seconds: float, label: String, stop: Callable) -> bool:
	var deadline: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	var next_print := 0
	while Time.get_ticks_msec() < deadline:
		var mission: Node = _flow.call("get_mission_for_craft", _craft_id)
		if Time.get_ticks_msec() >= next_print:
			print("PROBE_WATCH ", label, " ", _brief(mission), " space=", String(_space().get("phase", "")), " active_null=", _flow.get("_active_mission") == null)
			next_print = Time.get_ticks_msec() + 3000
		if bool(stop.call()): return true
		await physics_frame
	return false

## Der echte Rueckflug-Knopf der Schiffskarte (A5-Kartenpanel), so wie der Spieler ihn sieht.
func _return_button(mission: Node) -> Button:
	var panel: Node = mission.find_child("MissionDropshipPanel", true, false) if is_instance_valid(mission) else null
	return panel.get_node_or_null("CompactCard/Contents/Actions/return") as Button if panel != null else null

func _return_feedback(mission: Node) -> Label:
	var panel: Node = mission.find_child("MissionDropshipPanel", true, false) if is_instance_valid(mission) else null
	return panel.get_node_or_null("CompactCard/Contents/MissionDropshipCardFeedbackLabel") as Label if panel != null else null

func _press_return_button(mission: Node) -> bool:
	var button: Button = _return_button(mission)
	if button == null or not button.visible or button.disabled:
		print("PROBE_RETURN_BUTTON nicht druckbar: ", "kein Knopf" if button == null else "visible=%s disabled=%s" % [str(button.visible), str(button.disabled)])
		return false
	button.pressed.emit()
	return true

func _departed() -> bool:
	return _flow.get("_active_mission") == null or String(_space().get("phase", "")) != "surface"

func _crew_near_ship(mission: Node) -> bool:
	var controller: Node = mission.get_node("TacticalController")
	var simulation: Node = mission.get_node("SimulationRoot")
	var access: Dictionary = Dictionary(controller.call("get_campaign_ground_ship_access", _craft_id))
	if not bool(access.get("ok", false)): return false
	var ship: Vector2 = access.position
	for id in _crew_ids:
		var logical: Variant = simulation.call("get_hex_logical_unit_position", String(id))
		if not logical is Vector2 or Vector2(logical).distance_to(ship) > 128.0: return false
	return not _crew_ids.is_empty()

func _send_squad_to_ship(mission: Node) -> bool:
	var controller: Node = mission.get_node("TacticalController")
	var access: Dictionary = Dictionary(controller.call("get_campaign_ground_ship_access", _craft_id))
	var target: Vector2 = Vector2(access.position) if bool(access.get("ok", false)) else Vector2(controller.call("_campaign_landed_craft_position", _craft_id))
	controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
	controller.call("_create_waypoints_for_selected_fireteams", target, true)
	return bool(controller.call("execute_selected_fireteam_orders"))

func _fly_home_and_report() -> void:
	var location_orbits: Dictionary = _space().get("location_orbits", {})
	var destination_orbit := String(location_orbits.get(String(_campaign().get("selected_location_id", "")), ""))
	var home_orbit := String(location_orbits.get("homebase", ""))
	if not await _wait(func(): return String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == destination_orbit, 60000, "Schiff ist nach dem Abheben im Orbit des Einsatzorts"):
		_obs("kein_orbit")
		return
	_obs("im_planetenorbit")
	var jump: Dictionary = _screen.call("request_operation", "space_start_quantum", {"craft_id": _craft_id, "target_orbit_id": home_orbit})
	if not _check(bool(jump.get("ok", false)), "Sprung zum Mondorbit nimmt der Spieler an"): print("PROBE_JUMP ", jump); return
	if not await _wait(func(): return String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == home_orbit, 20000, "Schiff erreicht den Mondorbit"): return
	var land: Dictionary = _screen.call("request_operation", "space_land_homebase", {"craft_id": _craft_id})
	if not _check(bool(land.get("ok", false)), "Landung an der Heimatbasis nimmt der Spieler an"): print("PROBE_LAND ", land); return
	if not await _wait(func():
		var craft: Dictionary = _craft(_flow.call("get_singleplayer_snapshot"))
		return String(craft.get("location_id", "")) == "homebase" and not bool(craft.get("busy", true)), 40000, "Schiff steht wieder an der Heimatbasis"):
		return
	_flow.call("_show_homebase")
	_runtime.call("observe_campaign_progress")
	for i in 30: await physics_frame
	_obs("zuhause")
	print("PROBE_HOME people=", str(_people_at_base()), " chip_in=", str(_chip_containers()))
	var services: Dictionary = _runtime.call("_home_services_snapshot")
	print("PROBE_HOME_SERVICES upload_job_ids=", str(services.get("upload_job_ids", [])), " upload_blocker='", String(services.get("upload_blocker", "")), "'")
	var job: Dictionary = Dictionary(Dictionary(_campaign().get("jobs", {})).get("satellite_recovery", {}))
	print("PROBE_HOME_JOB ", var_to_str(job).replace("\n", " "))
	var has_data_shown: bool = String(job.get("status", "")) == "pending_upload" or not Array(services.get("upload_job_ids", [])).is_empty() or not String(services.get("upload_blocker", "")).is_empty()
	if _variant == "C":
		# Echter Rueckzug (nach Rueckfrage bestaetigt): wie bisher Auftrag wieder offen und ein Rueckzug gezaehlt.
		_check(String(job.get("status", "")) == "accepted" and int(job.get("retreat_count", 0)) == 1, "Bestaetigter Rueckzug: Auftrag wieder offen, retreat_count=1 (Auftrag: %s)" % var_to_str(job).replace("\n", " "))
		_check(Array(services.get("upload_job_ids", [])).is_empty(), "Ohne gesicherte Daten gibt es nichts hochzuladen")
		_check(String(services.get("chip_note", "")).is_empty(), "Ohne Datenchip sagt das Datenterminal nichts ueber einen Chip")
		# Stand eines alten Spielstands: Datenchip im Besitz, Auftrag wieder offen. Das Datenterminal sagt, woran es liegt.
		var legacy: Dictionary = _runtime.call("_campaign_cargo", _craft_id, "satellite_chip", 1, "probe:legacy_chip")
		print("PROBE_LEGACY_CHIP ", var_to_str(legacy).replace("\n", " "), " chip_in=", str(_chip_containers()))
		var chip_note: String = String(Dictionary(_runtime.call("_home_services_snapshot")).get("chip_note", ""))
		print("PROBE_CHIP_NOTE ", chip_note)
		_check(chip_note.contains("Datenchip") and chip_note.contains("abgebrochen"), "Datenchip vorhanden, Auftrag abgebrochen: das Datenterminal sagt, woran es liegt (Text: '%s')" % chip_note)
		return
	_check(int(job.get("retreat_count", 0)) == 0, "Der Abflug mit allen an Bord zaehlt nicht als Rueckzug (retreat_count=%d)" % int(job.get("retreat_count", 0)))
	_check(not Array(services.get("upload_job_ids", [])).is_empty(), "Nach der Heimkehr ist das Datapad hochladbar (Knopf Hochladen ist anklickbar)")
	_check(has_data_shown, "Das Datenterminal zeigt vorhandene Missionsdaten an (Auftrag wartet auf Hochladen)")
	var up: Dictionary = _screen.call("request_operation", "campaign_upload", {"job_id": "satellite_recovery"})
	print("PROBE_UPLOAD ", var_to_str(up).replace("\n", " "))
	_check(bool(up.get("ok", false)), "Hochladen nimmt das Datapad an (Antwort: %s)" % String(up.get("reason", up.get("message", "ok"))))
	_check(String(Dictionary(Dictionary(_campaign().get("jobs", {})).get("satellite_recovery", {})).get("status", "")) == "completed", "Der erste Auftrag ist nach dem Hochladen abgeschlossen")

func _finish() -> void:
	print("FIRST_SORTIE_VARIANT ", _variant)
	if is_instance_valid(_flow):
		_flow.queue_free()
	await process_frame
	print("FIRST_SORTIE_PLAYER_PATH passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _run() -> void:
	Engine.time_scale = 4.0
	var env_variant := OS.get_environment("SB_PROBE_VARIANT")
	if env_variant in ["A", "B", "C", "D", "U"]: _variant = env_variant
	print("FIRST_SORTIE_VARIANT_START ", _variant)
	_configure_entry()
	_flow = FLOW.instantiate(); root.add_child(_flow)
	await process_frame
	_screen = _flow.get_node("HomebaseScreen"); _runtime = _flow.get("_singleplayer_runtime")
	var initial: Dictionary = _screen.call("get_operations_snapshot")
	_pilot_id = String(Dictionary(initial.get("selected_craft", {})).get("pilot_id", ""))
	if not await _prepare_initial_base(): await _finish(); return
	var operations: Dictionary = _screen.call("get_operations_snapshot")
	var craft: Dictionary = operations.selected_craft
	_craft_id = String(craft.id); _pilot_id = String(craft.pilot_id)
	_team_id = String(Array(craft.payload_fireteam_ids)[0])
	for team: Dictionary in Array(operations.fireteams):
		if String(team.id) == _team_id:
			for unit: Dictionary in Array(team.members): _crew_ids.append(String(unit.id))
	_check(_screen.call("request_operation", "accept_job", {"job_id": "satellite_recovery"}).get("ok", false), "Auftrag 1 annehmen")
	_check(_screen.call("request_operation", "select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"}).get("ok", false), "Ziel Absturzstelle waehlen")
	if not await _launch_and_land("satellite_recovery", MAP_PATH): await _finish(); return
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
	_obs("gelandet")
	# --- Daten holen ---
	if _variant == "B":
		var map = MAP.load_from_file(MAP_PATH)
		var target: Vector2 = map.get_marker_position("satellite_data")
		controller.call("_create_waypoints_for_selected_fireteams", target, true)
		_check(bool(controller.call("execute_selected_fireteam_orders")), "Trupp laeuft zur Daten-Stelle")
		if not await _wait(func(): return String(_find_interaction(controller.call("get_mission_interaction_runtime_use_state_snapshot"), "satellite_data").get("runtime_use_status", "")) == "usable", 180000, "satellite_data becomes usable after real simulated approach"): await _finish(); return
		_obs("an_der_daten_stelle_ohne_benutzen")
		var intent: Dictionary = controller.call("create_selected_mission_interaction_use_intent", "satellite_data")
		_check(bool(intent.get("accepted", false)), "Benutzen der Daten-Stelle wird angenommen")
		_check(bool(controller.call("execute_selected_fireteam_orders")), "GO fuer das Benutzen")
		var started: bool = await _watch(60.0, "daten_halten", func():
			var e: Dictionary = _find_interaction(controller.call("get_mission_interaction_runtime_use_state_snapshot"), "satellite_data")
			return float(e.get("progress", 0.0)) >= 0.3)
		_obs("daten_halten_unterbrechen_jetzt")
		_check(started, "Die Datenaufnahme laeuft sichtbar an (Fortschritt >= 30 Prozent)")
		_check(_send_squad_to_ship(mission), "Bewegungsbefehl zum Schiff vor Ende der Haltezeit")
		await _watch(25.0, "nach_abbruch", func(): return false)
		_obs("nach_abbruch_25s")
		_check(not _chip_containers().is_empty(), "Auch bei vorzeitigem Verlassen der Daten-Stelle haette der Spieler den Datenchip (Haltezeit nicht erfuellt)")
	elif _variant == "C":
		_check(_send_squad_to_ship(mission), "Spieler schickt den Trupp zum Schiff, ohne Daten gesichert zu haben")
	else:
		if not await _move_and_use(mission, "satellite_data", "secure_satellite", MAP_PATH): await _finish(); return
		_obs("daten_fertig_sofort")
		for i in 90: await physics_frame
		_obs("daten_fertig_nach_90_Frames")
		_check(not _chip_containers().is_empty(), "Nach dem Sichern der Daten traegt der Trupp den Datenchip")
		_check(_send_squad_to_ship(mission) if _variant in ["A"] else true, "Spieler schickt den Trupp zum Schiff")
	# --- Weg zum Schiff ---
	if _variant == "U":
		# Wie der Kampagnenlauf: die 3-Sekunden-Benutzen-Stelle am Schiff; der Sieg-Weg schifft ein und fliegt ab.
		if not await _move_and_use(mission, "ship_return", "return_to_ship", MAP_PATH): await _finish(); return
		_obs("nach_Benutzen_Stelle_ship_return")
	if _variant == "D":
		var ex: Dictionary = controller.call("request_campaign_extraction", _craft_id)
		print("PROBE_EXTRACTION ", var_to_str(ex).replace("\n", " "))
		_check(bool(ex.get("ok", false)), "Rechtsklick auf das Schiff (Einsteigen) wird angenommen")
		var return_step_done: bool = await _wait(func():
			var live: Node = _flow.call("get_mission_for_craft", _craft_id)
			if not is_instance_valid(live): return true
			var snapshot: Dictionary = live.get_node("CombatLoopDriver").call("get_mission_scenario_runtime_gate_snapshot")
			return Array(snapshot.get("completed_step_ids", [])).has("return_to_ship") or _departed(), 150000, "Nach dem Einsteigen (alle an Bord) ist der Rueckkehr-Schritt erledigt")
		print("PROBE_D_RETURN_STEP_DONE ", return_step_done)
	var left_alone: bool = await _watch(150.0, "weg_zum_schiff", func(): return _departed())
	mission = _flow.call("get_mission_for_craft", _craft_id)
	_obs("nach_Weg_zum_Schiff_Wartezeit")
	if is_instance_valid(mission): print("PROBE_NEAR_SHIP crew_near=", _crew_near_ship(mission))
	if _variant in ["D", "U"]:
		_check(left_alone, "Alle an Bord und der Rueckkehr-Schritt erledigt: das Schiff hebt ab")
	else:
		_check(not left_alone, "Bewegung zum Schiff allein hebt das Schiff nicht ab (Spieler hat noch nichts bestaetigt)")
	if not left_alone and is_instance_valid(mission):
		controller = mission.get_node("TacticalController")
		var card: Dictionary = Dictionary(controller.call("_find_mission_dropship_card_entry", _craft_id))
		print("PROBE_RETURN_CARD can_request=", controller.call("_can_request_mission_dropship_return", card), " guard=", var_to_str(controller.call("get_campaign_pilot_flight_guard", _craft_id)).replace("\n", " "))
		# Der echte Knopf der Schiffskarte ist gesperrt, solange der Pilot nicht an Bord ist (Truppbewegung allein genuegt nicht).
		# Der Spieler steigt dann ein (Rechtsklick auf das Schiff = request_campaign_extraction); danach ist der Knopf frei,
		# oder das Schiff hebt schon vom Einsteigen ab (nur noch der Rueckkehr-Schritt offen).
		var button_at_ship: Button = _return_button(mission)
		print("PROBE_RETURN_BUTTON_AT_SHIP exists=", button_at_ship != null, " disabled=", button_at_ship.disabled if button_at_ship != null else "-", " text=", button_at_ship.text if button_at_ship != null else "-")
		if button_at_ship != null and button_at_ship.disabled:
			var boarded: Dictionary = controller.call("request_campaign_extraction", _craft_id)
			print("PROBE_BOARD_BEFORE_BUTTON ", var_to_str(boarded).replace("\n", " "))
			await _watch(90.0, "einsteigen_vor_dem_Knopf", func():
				var b: Button = _return_button(mission)
				return _departed() or (b != null and not b.disabled and b.visible))
		if not _departed():
			if _variant == "C":
				var pre_button: Button = _return_button(mission)
				_check(pre_button != null and pre_button.text == "Abheben", "Vor dem Druck steht am echten Kartenknopf 'Abheben' (Text: %s)" % ("kein Knopf" if pre_button == null else pre_button.text))
			# Der Spieler drueckt den ECHTEN Knopf der Schiffskarte (pressed), nicht die Methode des Controllers.
			_check(_press_return_button(mission), "Der echte Knopf der Schiffskarte ist da und wird gedrueckt")
			for i in 3: await physics_frame
		print("PROBE_RETURN_PRESSED last_cmd=", controller.get("_last_command_text"))
		if _variant == "C":
			# Rueckzug nur nach Rueckfrage: der erste Klick fragt nur nach, hebt nicht ab und sagt, was offen ist.
			var first_text: String = String(controller.get("_last_command_text"))
			_check(first_text.begins_with("Rückzug?") and first_text.contains("abgebrochen"), "Erster Klick fragt nach: Rückzug? Auftrag gilt als abgebrochen (Meldung: %s)" % first_text)
			_check(first_text.contains("Satellitendaten sichern"), "Die Rueckfrage nennt den offenen Schritt")
			_check(first_text.contains("Noch einmal drücken = Rückzug."), "Die Rueckfrage sagt, was der zweite Druck bedeutet (Meldung: %s)" % first_text)
			# W1: Beschriftung und Meldung am sichtbaren Knopf der Schiffskarte.
			var armed_button: Button = _return_button(mission)
			_check(armed_button != null and armed_button.text == "Rückzug?", "W1: nach dem ersten Druck traegt der echte Kartenknopf 'Rückzug?' (Text: %s)" % ("kein Knopf" if armed_button == null else armed_button.text))
			var armed_feedback: Label = _return_feedback(mission)
			_check(armed_feedback != null and armed_feedback.visible and armed_feedback.text.contains("Offen:") and armed_feedback.text.contains("Noch einmal drücken = Rückzug."), "W1: die Kartenmeldung nennt offene Schritte und den zweiten Druck (Text: %s)" % ("keine Meldung" if armed_feedback == null else armed_feedback.text))
			_check(armed_feedback != null and armed_feedback.autowrap_mode != TextServer.AUTOWRAP_OFF and armed_feedback.max_lines_visible != 1, "W1: die Kartenmeldung ist mehrzeilig lesbar, nicht auf eine Zeile gekuerzt")
			var lifted_early: bool = await _watch(5.0, "nach_erstem_Klick", func(): return _departed())
			_check(not lifted_early, "Der erste Klick hebt nicht ab")
			var expired_button: Button = _return_button(mission)
			_check(expired_button != null and expired_button.text == "Abheben", "W1: nach Ablauf der Frist traegt der Kartenknopf wieder 'Abheben' (Text: %s)" % ("kein Knopf" if expired_button == null else expired_button.text))
			# Zweiter Klick kommt nach 5 s: die 4-Sekunden-Frist ist abgelaufen, also fragt er neu nach und fliegt noch nicht.
			_press_return_button(mission)
			_press_return_button(mission)
			var lifted_fast: bool = await _watch(0.2, "zu_schneller_Klick", func(): return _departed())
			_check(not lifted_fast, "Ein Klick unter 0,4 s nach der Rueckfrage fliegt nicht ab")
			await create_timer(0.6, true, false, true).timeout
			_press_return_button(mission)
			print("PROBE_RETURN_CONFIRMED last_cmd=", controller.get("_last_command_text"))
		var gone: bool = await _watch(60.0, "nach_Rueckflug_Knopf", func(): return _departed())
		_obs("nach_Rueckflug_Knopf")
		_check(gone, "Nach Druck auf Rueckflug hebt das Schiff ab" if _variant != "C" else "Nach der bestaetigten Rueckfrage (zweiter Klick) hebt das Schiff ab")
	var job_now: String = String(Dictionary(Dictionary(_campaign().get("jobs", {})).get("satellite_recovery", {})).get("status", ""))
	print("PROBE_JOB_AFTER_TAKEOFF status=", job_now, " chip_in=", str(_chip_containers()))
	if _variant != "C":
		_check(job_now in ["pending_upload", "completed"] or not _chip_containers().is_empty(), "Nach dem Abheben ist der Datenchip gesichert (Auftrag wartet auf Hochladen oder Chip an Bord)")
	await _fly_home_and_report()
	await _finish()
