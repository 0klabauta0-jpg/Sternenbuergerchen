extends "res://scripts/tests/campaign_casualty_apply_verifier.gd"
## Task 5c (Ausfall und Rueckzug): Abflug ohne Missionsaufloesung fuehrt durch die Verlustauswertung.
## Ende-zu-Ende mit echten Kampagneneinsaetzen. Der Rueckflug wird ueber denselben Eingang angefragt,
## den die Versorgungsoberflaeche benutzt: request_operation("return_homebase") am Laufzeit-Adapter.
## A: Vergleichsbasis ohne Ausfaelle (muss vor und nach der Aenderung gleich sein).
## B: Truppfuehrer aufgerichtet, Abflug wird als Rueckzug (aborted / departure) ausgewertet, genau einmal.
## C: Truppfuehrer liegt, Totalverlust beim Abflug, kein Rueckflug.
## D: Skirmish erreicht den Abflugweg nicht und bleibt unveraendert.
## M: Das Gate sperrt, solange ein Missionsergebnis auf Zustellung wartet (Wettlauf nach "Evakuieren"): nichts aufgeloest, kein Abheben.
## Mit der Umgebungsvariable T5C_ONLY (zum Beispiel "A") oder dem Kommandozeilenargument nach "--" (zum Beispiel "-- A") laeuft nur dieser Teil.

func _run() -> void:
	_configure_entry()
	var only: String = OS.get_environment("T5C_ONLY").strip_edges().to_upper()
	for arg: String in OS.get_cmdline_user_args():
		if only.is_empty() and arg.strip_edges().length() == 1:
			only = arg.strip_edges().to_upper()
	if only.is_empty() or only == "A":
		await _departure_a_baseline()
	if only.is_empty() or only == "B":
		await _departure_revived("B", false)
	if only.is_empty() or only == "C":
		await _departure_total_loss("C", false)
	if only.is_empty() or only == "F":
		await _departure_revived("F", true)
	if only.is_empty() or only == "G":
		await _departure_total_loss("G", true)
	if only.is_empty() or only == "J":
		await _departure_low_fuel("J", true)
	if only.is_empty() or only == "K":
		await _departure_low_fuel("K", false)
	if only.is_empty() or only == "L":
		await _departure_l_not_focused()
	if only.is_empty() or only == "H":
		await _departure_h_hud_without_casualties()
	if only.is_empty() or only == "I":
		await _departure_i_without_gate()
	if only.is_empty() or only == "D":
		await _departure_d_skirmish()
	if only.is_empty() or only == "E":
		await _departure_e_troops_stay()
	if only.is_empty() or only == "M":
		await _departure_m_result_pending()
	print("CAMPAIGN_CASUALTY_DEPARTURE passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _request_return() -> Dictionary:
	return _runtime.call("request_operation", "return_homebase", {"craft_id": _craft_id})

## HUD-Weg: so ruft die Schiffskarte ("Abheben") den Rueckflug auf; sonst der Adapter-Eingang der Versorgungsoberflaeche.
func _press_return(hud: bool, s: Dictionary) -> Dictionary:
	if hud:
		s.controller.call("_on_mission_dropship_return_pressed", _craft_id)
		return {"ok": true, "hud": true, "feedback": _card_feedback(s)}
	return _request_return()

## Karten-Rueckmeldung, die die Schiffskarte dem Spieler zeigt (leer, wenn der Controller nicht mehr da ist).
func _card_feedback(s: Dictionary) -> String:
	if not is_instance_valid(s.controller):
		return ""
	var card: Dictionary = s.controller.call("_find_mission_dropship_card_entry", _craft_id)
	return String(s.controller.call("_get_mission_dropship_card_feedback_text", card))

func _fuel() -> float:
	return float(Dictionary(_supply().get("fuel_by_craft_id", {})).get(_craft_id, -1.0))

func _craft_location() -> String:
	return String(_craft(_flow.call("get_singleplayer_snapshot")).get("location_id", ""))

func _transfer_phase() -> String:
	for entry: Dictionary in Array(_flow.get("_pending_mission_craft_transfers")):
		if String(entry.get("craft_id", "")) == _craft_id:
			return String(entry.get("phase", ""))
	return ""

func _seat_crew(s: Dictionary) -> bool:
	if not _place_at(s.simulation, s.access, "campaign_leader", Vector2.ZERO): return false
	return _place_at(s.simulation, s.access, "campaign_pilot", Vector2.ZERO)

func _job_status() -> String:
	return String(_campaign().jobs.satellite_recovery.status)

func _roster_statuses() -> Dictionary:
	var statuses: Dictionary = {}
	for unit: Dictionary in Array(_flow.get("_all_team_units")):
		var id: String = String(unit.get("unit_id", ""))
		if id in ["campaign_leader", "campaign_pilot"]:
			statuses[id] = [String(unit.get("availability_status", "")), String(unit.get("status_text", "")), Dictionary(unit.get("recovery_state", {}))]
	return statuses

## Der normale Rueckflug vom Ort endet im Orbit (Oberflaechenabflug); erst von dort geht es weiter heim.
func _wait_departure_settled(label: String) -> bool:
	return await _wait(func(): return String(_space().get("phase", "")) == "orbit", 120000, label + ": Schiff hat die Oberflaeche verlassen und ist im Orbit")

func _mission_released() -> bool:
	return _flow.get("_active_mission") == null

func _departure_a_baseline() -> void:
	var s: Dictionary = await _begin_sortie()
	if s.is_empty(): return
	if not _seat_crew(s): return
	var job_before: String = _job_status()
	var last_before: Dictionary = Dictionary(_flow.get("_last_mission_result")).duplicate(true)
	var departure: Dictionary = _request_return()
	print("DEPARTURE_A_REQUEST ", departure)
	_check(bool(departure.get("ok", false)), "A: Rueckflug ohne Ausfaelle wird angenommen")
	var started_phase: String = _transfer_phase()
	print("DEPARTURE_A_STARTED phase=", started_phase, " location=", _craft_location())
	if not await _wait_departure_settled("A"): return
	await process_frame
	var last_after: Dictionary = Dictionary(_flow.get("_last_mission_result"))
	var statuses: Dictionary = _roster_statuses()
	print("DEPARTURE_A_OBSERVED job_before=", job_before, " job_after=", _job_status(), " last_before_empty=", last_before.is_empty(), " last_after_empty=", last_after.is_empty(), " last_after=", last_after, " view=", _flow.get("_current_meta_view"), " location=", _craft_location(), " transfer=", _transfer_phase(), " released=", _mission_released(), " space_phase=", _space().get("phase"), " roster=", statuses, " retreat=", _campaign().jobs.satellite_recovery.get("retreat_count", "none"))
	_check(job_before == "active", "A: Auftrag war aktiv")
	# Regel 8 (Entscheidung des Nutzers): Jeder Abflug bei aktivem Auftrag, nach dem niemand Einsatzfaehiges am Ort bleibt, ist ein Rueckzug.
	var job_after: Dictionary = Dictionary(_campaign().jobs.satellite_recovery)
	_check(_job_status() == "failed" and bool(job_after.get("reopen_at_home", false)) and int(job_after.get("retreat_count", 0)) == 1, "A: Abflug ohne Ausfaelle zaehlt als Rueckzug: failed mit reopen_at_home true und retreat_count 1 vor der Heimkehr (%s)" % [job_after])
	_check(not _mission_released() and _craft_location() == "starmap" and String(_space().get("phase", "")) == "orbit", "A: Ort bleibt bestehen, Schiff ist auf der Sternkarte im Orbit")
	_check(String(_flow.get("_current_meta_view")) == "mission", "A: Ansicht bleibt wie bisher mission")
	_check(last_after == last_before, "A: kein Ergebnis in _last_mission_result geschrieben (unveraendert zu vorher)")
	_check(not last_after.has("casualties") and String(last_after.get("win_condition_type", "")) != "departure", "A: weder casualties noch departure im Ergebnis")
	_check(String(_flow.get("_current_meta_view")) != "debrief", "A: kein Debrief wird gezeigt")
	for id: String in statuses.keys():
		_check(String(statuses[id][0]) != "wounded", "A: %s ist nicht wounded" % id)
	await _end_sortie()

func _departure_revived(tag: String, hud: bool) -> void:
	var s: Dictionary = await _begin_sortie()
	if s.is_empty(): return
	var leader: Node2D = s.leader
	var driver: Node = s.driver
	leader.call("apply_damage", 10000)
	if not await _wait(func(): return bool(Dictionary(driver.call("get_casualty_flags")).get("campaign_leader", {}).get("was_downed", false)), 5000, tag + ": Treiber merkt sich die ausgefallene Person"): return
	_check(bool(leader.call("apply_heal", 10, {})) and String(leader.call("get_vital_state")) == "fit", tag + ": innerhalb der Frist aufgerichtet")
	if not _seat_crew(s): return
	var departure: Dictionary = _press_return(hud, s)
	print("DEPARTURE_" + tag + "_REQUEST ", departure)
	_check(bool(departure.get("ok", false)) and (not hud or String(departure.get("feedback", "")).contains("Rückzug ausgewertet")), tag + ": Rueckflug wird angenommen (HUD: Karten-Rueckmeldung nennt die Auswertung)")
	if not await _wait(func(): return _flow.get("_active_mission") == null, 120000, tag + ": Einsatz wird freigegeben"): return
	var result: Dictionary = Dictionary(_flow.get("_last_mission_result")).duplicate(true)
	var unit: Dictionary = _roster_unit("campaign_leader")
	var recovery: Dictionary = Dictionary(unit.get("recovery_state", {}))
	var entry: Dictionary = _casualty_entry(result, "campaign_leader")
	print("DEPARTURE_" + tag + "_RESULT result=", result.get("result"), " outcome=", result.get("mission_outcome"), " wc=", result.get("win_condition_type"), " casualties=", result.get("casualties"), " fatal=", result.get("fatality_unit_ids"), " total_loss=", result.get("casualty_total_loss"), " retry=", result.get("campaign_checkpoint_retry_required"), " job=", _job_status(), " retreat=", _campaign().jobs.satellite_recovery.get("retreat_count", "none"), " phase=", _transfer_phase(), " location=", _craft_location(), " view=", _flow.get("_current_meta_view"))
	_check(String(result.get("result", "")) == "aborted" and String(result.get("mission_outcome", "")) == "aborted", tag + ": Ergebnis aborted, mission_outcome aborted")
	_check(String(result.get("win_condition_type", "")) == "departure", tag + ": win_condition_type ist departure")
	_check(String(entry.get("severity", "")) == "light" and String(entry.get("outcome", "")) == "wounded" and Array(result.get("casualties", [])).size() == 1, tag + ": casualties enthaelt genau den Truppfuehrer als leicht verwundet")
	_check(not String(entry.get("display_name", "")).is_empty(), tag + ": casualties-Eintrag traegt display_name")
	_check(PackedStringArray(result.get("fatality_unit_ids", PackedStringArray(["x"]))).is_empty(), tag + ": keine Toten gemeldet")
	_check(result.has("casualty_total_loss") and not bool(result.get("casualty_total_loss", true)) and not bool(result.get("campaign_checkpoint_retry_required", false)), tag + ": kein Totalverlust, kein Checkpoint-Retry")
	var leader_state: Dictionary = {}
	for state: Dictionary in Array(result.get("team_states", [])):
		if String(state.get("unit_id", "")) == "campaign_leader":
			leader_state = state
	_check(bool(leader_state.get("was_downed", false)) and bool(leader_state.get("near_ship", false)), tag + ": team_states tragen die Messung am gelandeten Schiff (was_downed, near_ship)")
	_check(String(unit.get("availability_status", "")) == "wounded" and String(recovery.get("severity", "")) == "light" and is_equal_approx(float(recovery.get("seconds_remaining", -1.0)), 180.0), tag + ": Kader: wounded, light, 180.0 s")
	_check(String(_roster_unit("campaign_pilot").get("availability_status", "")) != "wounded", tag + ": Pilot ist nicht verwundet")
	_check(_job_status() == "failed", tag + ": Auftrag steht auf failed (ist %s)" % _job_status())
	_check(String(_flow.get("_current_meta_view")) == "debrief" or String(_flow.get("_current_meta_view")) == "star_map", tag + ": Debrief wird gezeigt (oder Sternkarte bei laufender Route)")
	_check(await _wait_departure_settled(tag), tag + ": das Schiff fliegt ab und erreicht den Orbit")
	# Genau einmal: Rueckflug erneut angefragt, Ergebnis erneut zugestellt.
	var roster_before: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	for round_index in 2:
		var again: Dictionary = _request_return()
		print("DEPARTURE_" + tag + "_AGAIN ", round_index, " ", again)
		_flow.call("_on_mission_combat_resolved", {"result": "victory", "mission_outcome": "won"})
	await process_frame
	var remaining_after: float = float(Dictionary(_roster_unit("campaign_leader").get("recovery_state", {})).get("seconds_remaining", -1.0))
	_check(remaining_after <= 180.0 and remaining_after > 150.0, tag + ": Restzeit nach Wiederholungen nicht zurueckgesetzt (%.2f)" % remaining_after)
	_check(String(Dictionary(_roster_unit("campaign_leader").get("recovery_state", {})).get("severity", "")) == "light", tag + ": Schwere bleibt light")
	_check(Array(_flow.get("_all_team_units")).size() == roster_before.size(), tag + ": Kader hat dieselbe Groesse")
	_check(Dictionary(_flow.get("_last_mission_result")) == result, tag + ": Ergebnis bleibt nach Wiederholungen unveraendert")
	await _end_sortie()

func _departure_total_loss(tag: String, hud: bool) -> void:
	var s: Dictionary = await _begin_sortie()
	if s.is_empty(): return
	var leader: Node2D = s.leader
	var driver: Node = s.driver
	leader.call("apply_damage", 10000)
	if not await _wait(func(): return bool(Dictionary(driver.call("get_casualty_flags")).get("campaign_leader", {}).get("was_downed", false)), 5000, tag + ": Treiber merkt sich die ausgefallene Person"): return
	_check(String(leader.call("get_vital_state")) != "fit", tag + ": Truppfuehrer liegt")
	if not _seat_crew(s): return
	var fuel_before: float = _fuel()
	var departure: Dictionary = _press_return(hud, s)
	print("DEPARTURE_" + tag + "_REQUEST ", departure)
	var started_phase: String = _transfer_phase()
	if not await _wait(func(): return _flow.get("_active_mission") == null, 120000, tag + ": Einsatz wird freigegeben"): return
	await process_frame
	var result: Dictionary = Dictionary(_flow.get("_last_mission_result")).duplicate(true)
	print("DEPARTURE_" + tag + "_RESULT result=", result.get("result"), " outcome=", result.get("mission_outcome"), " wc=", result.get("win_condition_type"), " reason=", result.get("total_loss_reason"), " total_loss=", result.get("casualty_total_loss"), " retry=", result.get("campaign_checkpoint_retry_required"), " started_phase=", started_phase, " phase_now=", _transfer_phase(), " location=", _craft_location(), " view=", _flow.get("_current_meta_view"), " job=", _job_status())
	_check(is_equal_approx(_fuel(), fuel_before), tag + ": Treibstoff ist nicht abgebucht (%.2f -> %.2f)" % [fuel_before, _fuel()])
	_check(started_phase != "to_homebase", tag + ": kein Rueckflug gestartet")
	_check(_transfer_phase() != "to_homebase", tag + ": auch danach kein Rueckflug unterwegs")
	_check(String(result.get("result", "")) == "defeat" and bool(result.get("campaign_checkpoint_retry_required", false)), tag + ": Ergebnis defeat mit Checkpoint-Retry")
	_check(bool(result.get("casualty_total_loss", false)) and String(result.get("total_loss_reason", "")) == "ground_team_down", tag + ": Totalverlust, Grund ground_team_down")
	_check(String(_flow.get("_current_meta_view")) == "debrief", tag + ": Debrief ist sichtbar")
	_check(String(_space().get("phase", "")) != "orbit" and _craft_location() != "starmap", tag + ": das Schiff hat den Ort nicht verlassen")
	_check(not result.has("casualties") or Array(result.get("casualties", [])).is_empty(), tag + ": keine Verwundeten gemeldet")
	for unit: Dictionary in Array(_flow.get("_all_team_units")):
		_check(String(unit.get("availability_status", "")) != "wounded", tag + ": %s ist nicht wounded" % unit.get("unit_id"))
	await _end_sortie()

func _set_fuel(value: float) -> void:
	Dictionary(_runtime.get("_supply").get("_fuel_by_craft_id"))[_craft_id] = value

## J (HUD) / K (Adapter): aufgerichteter Truppfuehrer, Treibstoff unter dem Bedarf des Rueckflugs.
## Nichts wird aufgeloest, das Schiff bleibt, der Zustand ist nach jedem Druck wie davor; mit Treibstoff laeuft es wie F.
func _departure_low_fuel(tag: String, hud: bool) -> void:
	var s: Dictionary = await _begin_sortie()
	if s.is_empty(): return
	var leader: Node2D = s.leader
	var driver: Node = s.driver
	leader.call("apply_damage", 10000)
	if not await _wait(func(): return bool(Dictionary(driver.call("get_casualty_flags")).get("campaign_leader", {}).get("was_downed", false)), 5000, tag + ": Treiber merkt sich die ausgefallene Person"): return
	_check(bool(leader.call("apply_heal", 10, {})) and String(leader.call("get_vital_state")) == "fit", tag + ": aufgerichtet")
	if not _seat_crew(s): return
	var fuel_full: float = _fuel()
	_set_fuel(1.0)
	_check(is_equal_approx(_fuel(), 1.0), tag + ": Treibstoff ist knapp gesetzt")
	var roster_before: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	var last_before: Dictionary = Dictionary(_flow.get("_last_mission_result")).duplicate(true)
	for round_index in 3:
		var reply: Dictionary = _press_return(hud, s)
		await process_frame
		print("DEPARTURE_", tag, "_PRESS ", round_index, " ", reply)
		if hud:
			_check(String(reply.get("feedback", "")).contains("Treibstoff reicht nicht für den Rückflug"), tag + ": Druck %d: Karten-Meldung nennt den Treibstoff" % (round_index + 1))
		else:
			_check(not bool(reply.get("ok", true)) and String(reply.get("reason", "")) == "leg_fuel_insufficient" and String(reply.get("message", "")) == "Treibstoff reicht nicht für den Rückflug", tag + ": Druck %d: abgelehnt mit leg_fuel_insufficient (Regel 8 / Auftrag 21.11.) und Meldung" % (round_index + 1))
		_check(_flow.get("_active_mission") == s.mission and not bool(driver.get("_combat_finished")), tag + ": Druck %d: nichts aufgeloest" % (round_index + 1))
		_check(Array(_flow.get("_all_team_units")) == roster_before and Dictionary(_flow.get("_last_mission_result")) == last_before, tag + ": Druck %d: Kader und Ergebnis unveraendert" % (round_index + 1))
		_check(_job_status() == "active" and is_equal_approx(_fuel(), 1.0), tag + ": Druck %d: Auftrag active, Treibstoff unveraendert" % (round_index + 1))
		_check(bool(s.controller.call("_is_parked_campaign_dropship", _craft_id)) and _transfer_phase().is_empty() and String(_space().get("phase", "")) != "orbit", tag + ": Druck %d: Schiff bleibt gelandet" % (round_index + 1))
	# Treibstoff aufgefuellt: Ablauf wie F.
	_set_fuel(fuel_full)
	var reply_ok: Dictionary = _press_return(hud, s)
	print("DEPARTURE_", tag, "_REFUELED ", reply_ok)
	if not await _wait(func(): return _flow.get("_active_mission") == null, 120000, tag + ": Einsatz wird freigegeben"): return
	var result: Dictionary = Dictionary(_flow.get("_last_mission_result")).duplicate(true)
	var recovery: Dictionary = Dictionary(_roster_unit("campaign_leader").get("recovery_state", {}))
	_check(String(result.get("result", "")) == "aborted" and String(result.get("win_condition_type", "")) == "departure", tag + ": mit Treibstoff aborted / departure")
	_check(Array(result.get("casualties", [])).size() == 1 and String(_casualty_entry(result, "campaign_leader").get("severity", "")) == "light", tag + ": genau eine leichte Verwundung")
	_check(String(_roster_unit("campaign_leader").get("availability_status", "")) == "wounded" and is_equal_approx(float(recovery.get("seconds_remaining", -1.0)), 180.0), tag + ": Kader wounded, 180.0 s")
	_check(_job_status() == "failed", tag + ": Auftrag failed")
	_check(await _wait_departure_settled(tag), tag + ": das Schiff fliegt ab und erreicht den Orbit")
	await _end_sortie()

## L: Ort ohne HUD-Fokus (Fixture: _active_mission entfernt), Ausfall liegt dort: Abflug gesperrt, nichts aufgeloest.
func _departure_l_not_focused() -> void:
	var s: Dictionary = await _begin_sortie()
	if s.is_empty(): return
	var leader: Node2D = s.leader
	var driver: Node = s.driver
	var mission: Node = s.mission
	_check(not String(mission.get_meta("location_id", "")).is_empty(), "L: Einsatzort ist eine Ortsinstanz (location_id %s)" % String(mission.get_meta("location_id", "")))
	if not _seat_crew(s): return
	_flow.set("_active_mission", null)
	var reachable: bool = _flow.call("get_mission_for_craft", _craft_id) == mission
	print("DEPARTURE_L_REACHABLE ", reachable)
	_check(reachable, "L: das Schiff erreicht seine Ortsinstanz auch ohne Fokus")
	# Ohne Ausfaelle an diesem Ort: nichts zu tun.
	_check(not bool(Dictionary(_flow.call("_campaign_departure_gate", _craft_id)).get("handled", true)), "L: ohne Ausfaelle handled false")
	leader.call("apply_damage", 10000)
	if not await _wait(func(): return bool(Dictionary(driver.call("get_casualty_flags")).get("campaign_leader", {}).get("was_downed", false)), 5000, "L: Treiber dieser Instanz merkt sich die ausgefallene Person"): return
	_check(bool(leader.call("apply_heal", 10, {})) and String(leader.call("get_vital_state")) == "fit", "L: aufgerichtet, war_downed bleibt")
	var roster_before: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	# Der Adapter-Abflug steigt zuerst ein (Truppe an Bord); erst dann liegt keine einsatzfaehige Person mehr am Boden.
	var reply: Dictionary = _request_return()
	print("DEPARTURE_L_REQUEST ", reply)
	_check(not bool(reply.get("ok", true)) and String(reply.get("reason", "")) == "location_not_focused", "L: gesperrt mit location_not_focused")
	_check(String(reply.get("message", "")) == "Am Einsatzort liegen Ausgefallene. Abflug nur aus der Ortsansicht.", "L: Meldung auf Deutsch")
	_check(_transfer_phase().is_empty(), "L: kein Flug gestartet")
	_check(not bool(driver.get("_combat_finished")) and Array(_flow.get("_all_team_units")) == roster_before and Dictionary(_flow.get("_last_mission_result")).is_empty(), "L: nichts aufgeloest, Kader und Ergebnis unveraendert")
	_flow.set("_active_mission", mission)
	await _end_sortie()

## M: Wartet ein Missionsergebnis auf Zustellung (nach "Evakuieren" laeuft das Einschiffen noch, der 0,25-s-Wiederholer hat das
## Ergebnis noch nicht zugestellt), sperrt das Gate den Abflug. Das echte Timing laesst sich kopflos nicht treffen: der Wartezustand
## wird hergestellt, indem das wartende Ergebnis gesetzt wird; Setzen, Pruefen und Loeschen laufen in einem Schritt ohne Frame
## dazwischen, damit der Wiederholer es nicht zustellt.
func _departure_m_result_pending() -> void:
	var s: Dictionary = await _begin_sortie()
	if s.is_empty(): return
	var leader: Node2D = s.leader
	var driver: Node = s.driver
	leader.call("apply_damage", 10000)
	if not await _wait(func(): return bool(Dictionary(driver.call("get_casualty_flags")).get("campaign_leader", {}).get("was_downed", false)), 5000, "M: Treiber merkt sich die ausgefallene Person"): return
	_check(bool(leader.call("apply_heal", 10, {})) and String(leader.call("get_vital_state")) == "fit", "M: Truppfuehrer innerhalb der Frist aufgerichtet (das Gate wuerde sonst auswerten)")
	if not _seat_crew(s): return
	var last_before: Dictionary = Dictionary(_flow.get("_last_mission_result")).duplicate(true)
	var roster_before: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	_flow.set("_pending_campaign_mission_result", {"mission_outcome": "aborted", "result": "aborted", "win_condition_type": "evacuation"})
	# Wie im echten Ablauf (_run_location_callback): das wartende Ergebnis steht auch im Kontext des Ortes, sonst holt jeder
	# Kontextwechsel (Planungsmeldung beim Einschiffen) den leeren Stand zurueck.
	_flow.call("_remember_location", s.mission)
	var blocked: Dictionary = Dictionary(_flow.call("_campaign_departure_gate", _craft_id))
	var hud: Dictionary = _press_return(true, s)
	var transfer_while_pending: String = _transfer_phase()
	var finished_while_pending: bool = bool(driver.get("_combat_finished"))
	var pending_kept: bool = not Dictionary(_flow.get("_pending_campaign_mission_result")).is_empty()
	_flow.get("_pending_campaign_mission_result").clear()
	_flow.call("_remember_location", s.mission)
	print("DEPARTURE_M_BLOCKED ", blocked, " hud=", hud, " transfer=", transfer_while_pending, " finished=", finished_while_pending)
	_check(bool(blocked.get("handled", false)) and not bool(blocked.get("ok", true)) and String(blocked.get("reason", "")) == "mission_result_pending", "M: Gate sperrt mit mission_result_pending (%s)" % [blocked])
	_check(String(blocked.get("message", "")) == "Einsatz wird gerade abgeschlossen", "M: Meldung auf Deutsch")
	_check(String(hud.get("feedback", "")).contains("Einsatz wird gerade abgeschlossen") or String(hud.get("feedback", "")).is_empty(), "M: HUD-Weg: Karten-Rueckmeldung nennt den Abschluss, falls sie angezeigt wird (%s)" % [hud.get("feedback", "")])
	_check(transfer_while_pending.is_empty() and not finished_while_pending and pending_kept, "M: kein Abheben, Driver nicht aufgeloest, das wartende Ergebnis bleibt erhalten")
	_check(Dictionary(_flow.get("_last_mission_result")) == last_before and Array(_flow.get("_all_team_units")) == roster_before and _job_status() == "active", "M: nichts aufgeloest: kein Ergebnis, Kader unveraendert, Auftrag active")
	# Ohne wartendes Ergebnis wertet dasselbe Gate wieder aus (der Fall B).
	var released: Dictionary = Dictionary(_flow.call("_campaign_departure_gate", _craft_id))
	print("DEPARTURE_M_RELEASED ", released)
	_check(bool(released.get("handled", false)) and bool(released.get("ok", false)) and bool(driver.get("_combat_finished")), "M: ohne wartendes Ergebnis wertet das Gate wieder aus (handled, ok, Driver aufgeloest)")
	await _end_sortie()

## H: HUD-Weg ohne Ausfaelle: das Schiff hebt ab wie vor der Aenderung (Vergleich mit A).
func _departure_h_hud_without_casualties() -> void:
	var s: Dictionary = await _begin_sortie()
	if s.is_empty(): return
	if not _seat_crew(s): return
	var last_before: Dictionary = Dictionary(_flow.get("_last_mission_result")).duplicate(true)
	var fuel_before: float = _fuel()
	_press_return(true, s)
	if not await _wait_departure_settled("H"): return
	await process_frame
	print("DEPARTURE_H_OBSERVED job=", _job_status(), " view=", _flow.get("_current_meta_view"), " location=", _craft_location(), " released=", _mission_released(), " last=", _flow.get("_last_mission_result"), " fuel=", fuel_before, "->", _fuel())
	_check(_job_status() == "failed", "H: Auftrag wird wie bisher als failed gebucht")
	_check(Dictionary(_flow.get("_last_mission_result")) == last_before and not Dictionary(_flow.get("_last_mission_result")).has("casualties"), "H: kein Ergebnis departure, keine casualties")
	_check(String(_flow.get("_current_meta_view")) == "mission" and not _mission_released() and _craft_location() == "starmap", "H: kein Debrief, Ort bleibt, Schiff im Orbit")
	_check(not bool(s.driver.get("_combat_finished")), "H: Driver wurde nicht aufgeloest")
	for unit: Dictionary in Array(_flow.get("_all_team_units")):
		_check(String(unit.get("availability_status", "")) != "wounded", "H: %s ist nicht wounded" % unit.get("unit_id"))
	await _end_sortie()

## I: Controller ohne gesetztes Gate verhaelt sich wie vor der Aenderung (Ausfall, aber keine Auswertung).
func _departure_i_without_gate() -> void:
	var s: Dictionary = await _begin_sortie()
	if s.is_empty(): return
	var leader: Node2D = s.leader
	var driver: Node = s.driver
	leader.call("apply_damage", 10000)
	if not await _wait(func(): return bool(Dictionary(driver.call("get_casualty_flags")).get("campaign_leader", {}).get("was_downed", false)), 5000, "I: Treiber merkt sich die ausgefallene Person"): return
	_check(bool(Callable(s.controller, "_on_mission_dropship_return_pressed").is_valid()) and Callable(s.controller.get("_campaign_departure_gate")).is_valid(), "I: das Gate ist im Kampagneneinsatz gesetzt")
	s.controller.call("set_campaign_departure_gate", Callable())
	if not _seat_crew(s): return
	var last_before: Dictionary = Dictionary(_flow.get("_last_mission_result")).duplicate(true)
	_press_return(true, s)
	if not await _wait_departure_settled("I"): return
	await process_frame
	_check(not bool(driver.get("_combat_finished")), "I: ohne Gate keine Aufloesung am Driver")
	_check(Dictionary(_flow.get("_last_mission_result")) == last_before, "I: ohne Gate kein Ergebnis (wie vor der Aenderung)")
	for unit: Dictionary in Array(_flow.get("_all_team_units")):
		_check(String(unit.get("availability_status", "")) != "wounded", "I: %s ist nicht wounded" % unit.get("unit_id"))
	await _end_sortie()

## Truppen bleiben am Ort: die Regel steht ausdruecklich in _campaign_departure_empties_location.
func _departure_e_troops_stay() -> void:
	# Direkt mit gebauten team_states.
	START.request_start(self, "campaign", "new")
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	await process_frame
	var down: Dictionary = {"unit_id": "a", "vital_state": "down", "was_downed": true, "near_ship": true, "aboard": false}
	var fit_aboard: Dictionary = {"unit_id": "b", "vital_state": "fit", "was_downed": false, "near_ship": true, "aboard": true}
	var fit_ground: Dictionary = {"unit_id": "c", "vital_state": "fit", "was_downed": false, "near_ship": false, "aboard": false}
	_check(bool(_flow.call("_campaign_departure_empties_location", [fit_aboard, down])), "E: alle Einsatzfaehigen an Bord, ein Liegender am Boden: Ort ist leer (true)")
	_check(not bool(_flow.call("_campaign_departure_empties_location", [fit_aboard, fit_ground, down])), "E: ein Einsatzfaehiger bleibt am Boden: Ort ist nicht leer (false)")
	_check(bool(_flow.call("_campaign_departure_empties_location", [fit_aboard, Dictionary(fit_aboard).merged({"unit_id": "d"})])), "E: niemand am Boden: true")
	_check(bool(_flow.call("_campaign_departure_empties_location", [])), "E: leere Liste: true")
	await _end_sortie()
	# Im echten Einsatz: ein Einsatzfaehiger bleibt weg vom Schiff, der Truppfuehrer liegt.
	var s: Dictionary = await _begin_sortie()
	if s.is_empty(): return
	var leader: Node2D = s.leader
	var driver: Node = s.driver
	leader.call("apply_damage", 10000)
	if not await _wait(func(): return bool(Dictionary(driver.call("get_casualty_flags")).get("campaign_leader", {}).get("was_downed", false)), 5000, "E: Treiber merkt sich die ausgefallene Person"): return
	if not _place_at(s.simulation, s.access, "campaign_leader", Vector2.ZERO): return
	if not _place_at(s.simulation, s.access, "campaign_pilot", Vector2(700.0, 0.0)): return
	var roster_before: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	var last_before: Dictionary = Dictionary(_flow.get("_last_mission_result")).duplicate(true)
	var attempt: Dictionary = _request_return()
	print("DEPARTURE_E_ATTEMPT ", attempt)
	_check(not bool(attempt.get("ok", true)) and not bool(attempt.get("departure_resolved", false)), "E: Einsatzfaehiger am Boden: Abflug wird abgelehnt (Sperre des Missionscontrollers)")
	_check(_flow.get("_active_mission") == s.mission and not bool(driver.get("_combat_finished")), "E: keine Aufloesung, Einsatz bleibt")
	_check(Dictionary(_flow.get("_last_mission_result")) == last_before and Array(_flow.get("_all_team_units")) == roster_before, "E: kein Ergebnis, Kader unveraendert")
	await _end_sortie()

func _departure_d_skirmish() -> void:
	START.request_start(self, "skirmish", "new")
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	await process_frame
	_flow.call("_start_mission")
	var mission: Node = _flow.get("_active_mission")
	if not _check(mission != null, "D: Skirmish-Einsatz wird gestartet"): return
	await process_frame
	var downed_id: String = ""
	var probe: Dictionary = _flow.call("_build_mission_result", mission, {})
	for state: Dictionary in Array(probe.get("team_states", [])):
		downed_id = String(state.get("unit_id", ""))
		break
	for node: Node in mission.get_children():
		if node.has_method("get_unit_id") and String(node.call("get_unit_id")) == downed_id:
			node.call("apply_damage", 10000)
	var driver: Node = mission.get_node("CombatLoopDriver")
	var roster_before: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	var last_before: Dictionary = Dictionary(_flow.get("_last_mission_result")).duplicate(true)
	# Der Abflugweg verlangt einen Kampagnenbesuch; in Skirmish gibt es keinen.
	var attempt: Dictionary = _flow.call("_request_singleplayer_return", "skirmish_craft")
	print("DEPARTURE_D_ATTEMPT ", attempt)
	_check(not bool(attempt.get("ok", true)) and String(attempt.get("reason", "")) == "no_active_visit", "D: Abflug in Skirmish ist nicht erreichbar (no_active_visit)")
	_check(_flow.get("_active_mission") == mission and not bool(driver.get("_combat_finished")), "D: Einsatz und Driver bleiben unveraendert")
	_check(Dictionary(_flow.get("_last_mission_result")) == last_before and not Dictionary(_flow.get("_last_mission_result")).has("casualties"), "D: kein Ergebnis mit casualties")
	_check(Array(_flow.get("_all_team_units")) == roster_before, "D: Kader unveraendert")
	_flow.call("_finish_singleplayer_visit_if_returned")
	_check(_flow.get("_active_mission") == mission and Dictionary(_flow.get("_last_mission_result")) == last_before, "D: auch der Heimkehr-Abschluss rührt Skirmish nicht an")
	await _end_sortie()
