extends "res://scripts/tests/campaign_casualty_roster_verifier.gd"
## R3c Respawn (Anwenden): Wer am Missionsende zurueckbleibt und unter der Grenze liegt, bleibt im Kader (respawning),
## steht unsichtbar auf Polisa und zaehlt als gesperrt; erst an der Grenze faellt er endgueltig (Gefallenenliste mit Grund).
## Echte Meta-Szene mit vier Personen (A Truppfuehrer Platz 0, Pilot Platz 1, B Truppfuehrer, C Schuetze) wie campaign_casualty_roster_verifier.
## S1 erster Tod   S2 zweiter Tod (Ausfallzeit 5400)   S3 an der Grenze endgueltig, mit Grund   S4 Grenze 0 wie bisher
## S5 geschuetzter Pilot und Anwerber   S6 doppelte Zustellung (auch nach Speichern und Laden)   S7 Befund (a) Platz 0 gestorben, Befund (b) Pilot
## Abschlusszeile: CAMPAIGN_RESPAWN_APPLY passed=%d failed=%d

func _run() -> void:
	_configure_entry()
	for scenario: String in ["S1", "S2", "S3", "S4", "S5", "S6", "S7"]:
		print("--- ", scenario)
		await call("_ra_" + scenario.to_lower())
		await _end_sortie()
	print("CAMPAIGN_RESPAWN_APPLY passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _ra_result(states: Array, outcome: String, limit: int) -> Dictionary:
	var rules: Dictionary = CASUALTY_RULES.load_rules()
	var pilot_id: String = String(Dictionary(_flow.get("_assigned_aircraft_pilot_by_craft")).values()[0])
	var ctx: Dictionary = {"respawn_limit": limit} if limit > 0 else {}
	var resolved: Dictionary = CASUALTY_RULES.resolve_mission(states, outcome, Array(_flow.get("_all_team_units")), pilot_id, rules, ctx)
	return {"mission_outcome": outcome, "result": "victory" if outcome == "won" else outcome, "team_states": states, "casualties": resolved.casualties, "fatality_unit_ids": resolved.fatality_unit_ids, "respawn_unit_ids": resolved.respawn_unit_ids, "respawn_limit": limit, "casualty_total_loss": resolved.total_loss}

func _ra_set(unit_id: String, fields: Dictionary) -> void:
	var units: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	for unit: Dictionary in units:
		if String(unit.get("unit_id", "")) == unit_id:
			for key in fields:
				unit[key] = fields[key]
	_flow.call("_replace_roster_units", units)

func _ra_base_status(unit_id: String) -> String:
	return String(Dictionary(Dictionary(_t6b_base().get("_states")).get(unit_id, {})).get("status", ""))

func _ra_fallen(unit_id: String) -> Dictionary:
	for entry: Dictionary in Array(_runtime.call("get_fallen")):
		if String(entry.get("unit_id", "")) == unit_id:
			return entry
	return {}

func _ra_board(unit_id: String) -> Dictionary:
	_craft_id = String(Dictionary(Array(_flow.get("_homebase_aircraft_definitions"))[0]).get("craft_id", ""))
	return _screen.call("request_operation", "base_board", {"craft_id": _craft_id, "unit_id": unit_id})

func _ra_s1() -> void:
	if not await _t6b_new_four(): return
	var roster_before: Array = _t6b_roster_ids()
	var base_before: Array = _t6b_base_ids()
	var applied: Dictionary = _flow.call("_apply_campaign_casualties", _ra_result(_t6b_states({SHOOTER_C: "down"}), "aborted", 3))
	var c_unit: Dictionary = _roster_unit(SHOOTER_C)
	var state: Dictionary = Dictionary(c_unit.get("recovery_state", {}))
	_check(_t6b_roster_ids() == roster_before and _t6b_base_ids() == base_before, "S1: Kader und Basis haben dieselben vier Personen")
	_check(String(c_unit.get("availability_status", "")) == "respawning" and String(c_unit.get("status_text", "")) == "respawning" and int(c_unit.get("respawns_used", -1)) == 1, "S1: C ist respawning, respawns_used 1 (%s)" % [c_unit.get("availability_status", "")])
	_check(String(state.get("state", "")) == "respawning" and int(state.get("death_number", 0)) == 1 and is_equal_approx(float(state.get("seconds_total", 0.0)), 3600.0) and is_equal_approx(float(state.get("seconds_remaining", 0.0)), 3600.0) and String(state.get("pickup_location_id", "")) == "polisa" and String(state.get("source", "")) == "left_behind", "S1: recovery_state 3600 s, erster Tod, Polisa (%s)" % [state])
	_check(Array(_runtime.call("get_fallen")).is_empty() and PackedStringArray(applied.get("fatality_unit_ids", PackedStringArray(["x"]))).is_empty(), "S1: niemand in der Gefallenenliste, kein Gefallener im Ergebnis")
	_check(PackedStringArray(applied.get("respawn_unit_ids", PackedStringArray())) == PackedStringArray([SHOOTER_C]) and int(applied.get("respawn_limit", -1)) == 3, "S1: Ergebnis nennt C als Wiederkehrer und die Grenze 3")
	var entry: Dictionary = _casualty_entry(applied, SHOOTER_C)
	_check(String(entry.get("outcome", "")) == "dead" and not bool(entry.get("final", true)) and int(entry.get("death_number", 0)) == 1 and Dictionary(entry.get("respawn_state", {})).size() == 6, "S1: casualties-Eintrag von C: tot, nicht endgueltig, erster Tod, respawn_state")
	_check(_ra_base_status(SHOOTER_C) == "station", "S1: C steht in der Basis auf station")
	var actor: Node = _t6b_base().call("get_actor", SHOOTER_C)
	_check(actor != null and not bool(actor.get("visible")), "S1: Darsteller von C ist unsichtbar")
	_check(String(_t6b_lock().get(SHOOTER_C, "")).contains("gestorben"), "S1: C steht in der Einsatzsperre mit Text gestorben (%s)" % [_t6b_lock().get(SHOOTER_C, "")])
	_check(String(_roster_unit(LEAD_A).get("availability_status", "")) in ["", "active"] and String(_roster_unit(LEAD_B).get("availability_status", "")) in ["", "active"] and String(_roster_unit(PILOT_ID).get("availability_status", "")) in ["", "active"], "S1: die anderen drei bleiben active (A=%s, Pilot=%s, B=%s)" % [_roster_unit(LEAD_A).get("availability_status", ""), _roster_unit(PILOT_ID).get("availability_status", ""), _roster_unit(LEAD_B).get("availability_status", "")])
	var payload: Dictionary = _t6b_payload()
	_check(bool(STORE_6B.validate_payload(payload).get("ok", false)), "S1: Stand besteht validate_payload")
	_check(_t6b_where(payload, SHOOTER_C).has("roster") and _t6b_where(payload, SHOOTER_C).has("base_personnel"), "S1: C steht im Stand in Kader und Basis (%s)" % [_t6b_where(payload, SHOOTER_C)])
	var board: Dictionary = _ra_board(SHOOTER_C)
	_check(not bool(board.get("ok", true)), "S1: Einschiffen von C wird abgelehnt (%s)" % [board])

func _ra_s2() -> void:
	if not await _t6b_new_four(): return
	_ra_set(SHOOTER_C, {"respawns_used": 1})
	var applied: Dictionary = _flow.call("_apply_campaign_casualties", _ra_result(_t6b_states({SHOOTER_C: "down"}), "aborted", 3))
	var c_unit: Dictionary = _roster_unit(SHOOTER_C)
	var state: Dictionary = Dictionary(c_unit.get("recovery_state", {}))
	_check(String(c_unit.get("availability_status", "")) == "respawning" and int(c_unit.get("respawns_used", -1)) == 2, "S2: zweiter Tod: respawning, respawns_used 2")
	_check(int(state.get("death_number", 0)) == 2 and is_equal_approx(float(state.get("seconds_total", 0.0)), 5400.0), "S2: zweiter Tod: 5400 s (%s)" % [state])
	_check(Array(_runtime.call("get_fallen")).is_empty() and int(_casualty_entry(applied, SHOOTER_C).get("death_number", 0)) == 2, "S2: keine Gefallenenliste, death_number 2")

func _ra_s3() -> void:
	if not await _t6b_new_four(): return
	_ra_set(SHOOTER_C, {"respawns_used": 3})
	var applied: Dictionary = _flow.call("_apply_campaign_casualties", _ra_result(_t6b_states({SHOOTER_C: "down"}), "aborted", 3))
	_check(PackedStringArray(applied.get("fatality_unit_ids", PackedStringArray())) == PackedStringArray([SHOOTER_C]) and PackedStringArray(applied.get("respawn_unit_ids", PackedStringArray(["x"]))).is_empty(), "S3: an der Grenze: C ist gefallen, niemand kommt wieder")
	_check(_t6b_roster_ids() == [LEAD_A, PILOT_ID, LEAD_B] and _t6b_where(_t6b_payload(), SHOOTER_C).is_empty(), "S3: C ist ueberall weg (%s)" % [_t6b_where(_t6b_payload(), SHOOTER_C)])
	var fallen: Dictionary = _ra_fallen(SHOOTER_C)
	_check(String(fallen.get("reason", "")) == "respawn_limit" and int(fallen.get("respawns_used", -1)) == 3 and int(fallen.get("respawn_limit", -1)) == 3, "S3: Eintrag in der Gefallenenliste mit Grund respawn_limit, 3 von 3 (%s)" % [fallen])
	_check(String(fallen.get("display_name", "")) == NAME_C and String(fallen.get("job_id", "")) == JOB_6B and String(fallen.get("location_id", "")) == LOCATION_6B, "S3: Eintrag mit Name, Auftrag und Ort")
	_check(bool(STORE_6B.validate_payload(_t6b_payload()).get("ok", false)), "S3: Stand besteht validate_payload")

func _ra_s4() -> void:
	if not await _t6b_new_four(): return
	var applied: Dictionary = _flow.call("_apply_campaign_casualties", _ra_result(_t6b_states({SHOOTER_C: "down"}), "aborted", 0))
	_check(PackedStringArray(applied.get("fatality_unit_ids", PackedStringArray())) == PackedStringArray([SHOOTER_C]) and _t6b_roster_ids() == [LEAD_A, PILOT_ID, LEAD_B], "S4: Grenze 0: C faellt sofort wie bisher")
	var fallen: Dictionary = _ra_fallen(SHOOTER_C)
	_check(not fallen.is_empty() and not fallen.has("reason") and not fallen.has("respawns_used") and not fallen.has("respawn_limit"), "S4: Grenze 0: Eintrag ohne die neuen Felder (%s)" % [fallen])
	_check(not applied.has("respawn_unit_ids") or PackedStringArray(applied.get("respawn_unit_ids", PackedStringArray())).is_empty(), "S4: Grenze 0: niemand kommt wieder")

func _ra_s5() -> void:
	if not await _t6b_new_four(): return
	# Der Pilot ist geschuetzt: auch als Wiederkehrer wird er schwer verwundet gerettet, nicht respawning.
	var result: Dictionary = _ra_result(_t6b_states({}), "aborted", 3)
	result["respawn_unit_ids"] = PackedStringArray([PILOT_ID])
	result["casualties"] = [{"unit_id": PILOT_ID, "outcome": "dead", "final": false, "death_number": 1, "respawn_state": {"state": "respawning", "death_number": 1, "seconds_total": 3600, "seconds_remaining": 3600, "pickup_location_id": "polisa", "source": "left_behind"}}]
	var roster_before: Array = _t6b_roster_ids()
	var applied: Dictionary = _flow.call("_apply_campaign_casualties", result)
	var pilot: Dictionary = _roster_unit(PILOT_ID)
	_check(String(pilot.get("availability_status", "")) == "wounded" and String(Dictionary(pilot.get("recovery_state", {})).get("severity", "")) == "severe", "S5: Pilot wird schwer verwundet statt respawning")
	_check(int(pilot.get("respawns_used", 0)) == 0 and _ra_base_status(PILOT_ID) != "station", "S5: Pilot zaehlt keinen Respawn und steht nicht auf station")
	var entry: Dictionary = _casualty_entry(applied, PILOT_ID)
	_check(bool(entry.get("protected_from_death", false)) and String(entry.get("outcome", "")) == "wounded" and not entry.has("respawn_state"), "S5: casualties-Eintrag geschuetzt, verwundet, ohne respawn_state (%s)" % [entry])
	_check(PackedStringArray(applied.get("respawn_unit_ids", PackedStringArray(["x"]))).is_empty() and PackedStringArray(applied.get("fatality_unit_ids", PackedStringArray(["x"]))).is_empty() and _t6b_roster_ids() == roster_before, "S5: kein Wiederkehrer, kein Gefallener, Kader unveraendert")

func _ra_s6() -> void:
	if not await _t6b_new_four(): return
	var states: Array = _t6b_states({SHOOTER_C: "down"})
	var first: Dictionary = _ra_result(states, "aborted", 1)
	_flow.call("_apply_campaign_casualties", first)
	var after_first: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	_check(String(_roster_unit(SHOOTER_C).get("availability_status", "")) == "respawning" and int(_roster_unit(SHOOTER_C).get("respawns_used", -1)) == 1, "S6: Grenze 1: C ist nach der ersten Zustellung respawning mit 1")
	# Dasselbe Ergebnis noch einmal.
	_flow.call("_apply_campaign_casualties", first)
	var same: bool = JSON.stringify(Array(_flow.get("_all_team_units")), "", true) == JSON.stringify(after_first, "", true)
	_check(same and Array(_runtime.call("get_fallen")).is_empty(), "S6: dasselbe Ergebnis ein zweites Mal: Kader unveraendert, niemand gefallen")
	# Frisch gerechnet: die Regeln sehen jetzt 1 von 1 und sagen endgueltig, der Flow schuetzt den Verbuchten trotzdem.
	var again: Dictionary = _ra_result(states, "aborted", 1)
	_check(PackedStringArray(again.fatality_unit_ids) == PackedStringArray([SHOOTER_C]), "S6: Fixture: frisch gerechnet waere C jetzt endgueltig gefallen")
	_flow.call("_apply_campaign_casualties", again)
	_check(_t6b_roster_ids().has(SHOOTER_C) and Array(_runtime.call("get_fallen")).is_empty() and int(_roster_unit(SHOOTER_C).get("respawns_used", -1)) == 1, "S6: frisch gerechnete zweite Zustellung entfernt C nicht und zaehlt nicht doppelt")
	# Speichern, neu aufbauen, fortsetzen, noch einmal zustellen.
	var saved: Dictionary = _flow.call("request_campaign_save")
	if not _check(bool(saved.get("ok", false)), "S6: Speichern gelingt (%s)" % [saved.get("reason", "")]): return
	await _end_sortie()
	await create_timer(0.5).timeout
	if not await _t6b_open("campaign", "continue"): return
	_check(String(_roster_unit(SHOOTER_C).get("availability_status", "")) == "respawning" and int(_roster_unit(SHOOTER_C).get("respawns_used", -1)) == 1, "S6: nach dem Fortsetzen: C respawning mit 1")
	var loaded_roster: String = JSON.stringify(Array(_flow.get("_all_team_units")), "", true)
	var third: Dictionary = _ra_result(states, "aborted", 1)
	_check(PackedStringArray(third.fatality_unit_ids) == PackedStringArray([SHOOTER_C]), "S6: Fixture nach Laden: die Regeln wuerden C endgueltig faellen")
	_flow.call("_apply_campaign_casualties", third)
	_flow.call("_apply_campaign_casualties", first)
	_check(JSON.stringify(Array(_flow.get("_all_team_units")), "", true) == loaded_roster and Array(_runtime.call("get_fallen")).is_empty(), "S6: nach Speichern und Laden zweimal zugestellt: Kader unveraendert, niemand gefallen")
	_check(bool(STORE_6B.validate_payload(_t6b_payload()).get("ok", false)) and _ra_base_status(SHOOTER_C) == "station", "S6: Stand gueltig, C steht auf station")

func _ra_s7() -> void:
	if not await _t6b_new_four(): return
	# Befund (a): Platz 0 (Truppfuehrer A) stirbt und kommt wieder. Es wird nicht umsortiert; gemessen wird, was dann geht.
	_flow.call("_apply_campaign_casualties", _ra_result(_t6b_states({LEAD_A: "down"}), "aborted", 3))
	var order: Array = _t6b_roster_ids()
	var problems: PackedStringArray = _flow.call("_campaign_roster_problems", Array(_flow.get("_all_team_units")))
	print("FINDING_A order=", order, " roster_problems=", problems, " lock=", _t6b_lock().keys())
	_check(order == [LEAD_A, PILOT_ID, LEAD_B, SHOOTER_C], "S7(a): Reihenfolge im Kader unveraendert (A bleibt Platz 0)")
	_check(String(_roster_unit(LEAD_A).get("availability_status", "")) == "respawning" and _t6b_lock().has(LEAD_A), "S7(a): A ist respawning und gesperrt")
	var board_a: Dictionary = _ra_board(LEAD_A)
	var board_b: Dictionary = _ra_board(LEAD_B)
	var board_p: Dictionary = _ra_board(PILOT_ID)
	print("FINDING_A boarding A=", board_a, " B=", board_b, " Pilot=", board_p)
	_check(not bool(board_a.get("ok", true)), "S7(a): A kann nicht einschiffen")
	_check(bool(board_b.get("ok", false)) and bool(board_p.get("ok", false)), "S7(a): B und der Pilot koennen einschiffen (Messung: B=%s, Pilot=%s)" % [board_b, board_p])
	await _end_sortie()
	# Befund (b): der Pilot (Platz 1) ist geschuetzt und wird schwer verwundet; was ist dann startbar?
	if not await _t6b_new_four(): return
	var result: Dictionary = _ra_result(_t6b_states({}), "aborted", 3)
	result["respawn_unit_ids"] = PackedStringArray([PILOT_ID])
	result["casualties"] = [{"unit_id": PILOT_ID, "outcome": "dead", "final": false, "death_number": 1}]
	_flow.call("_apply_campaign_casualties", result)
	var pilot_board: Dictionary = _ra_board(PILOT_ID)
	var a_board: Dictionary = _ra_board(LEAD_A)
	print("FINDING_B pilot_status=", _roster_unit(PILOT_ID).get("availability_status", ""), " boarding Pilot=", pilot_board, " A=", a_board, " pilot_aboard=", _t6b_base().call("is_pilot_aboard", _craft_id))
	_check(not bool(pilot_board.get("ok", true)), "S7(b): der verwundete Pilot kann nicht einschiffen (%s)" % [pilot_board])
