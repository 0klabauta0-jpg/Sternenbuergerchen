extends "res://scripts/tests/campaign_casualty_apply_verifier.gd"
## Task 8a (Ausfall und Rueckzug): Rueckzug laesst den Auftrag offen.
## Pflichtteil rein auf dem Kampagnenstand, danach Adapterteil mit echter Meta-Szene
## (Aufbau wie campaign_casualty_apply_verifier). Schlusszeile: CAMPAIGN_RETREAT passed=%d failed=%d

const STATE_SCRIPT: GDScript = preload("res://scripts/core/singleplayer_campaign_state.gd")
const COMMANDS_SCRIPT: GDScript = preload("res://scripts/mission/singleplayer_campaign_command_contract.gd")
const JOB := "satellite_recovery"
const CRAFT := "test_craft"

var _seq := 0

func _run() -> void:
	_state_part()
	await _adapter_part()
	print("CAMPAIGN_RETREAT passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

# ---------------------------------------------------------------- Kampagnenstand

func _new_state() -> RefCounted:
	var state: RefCounted = STATE_SCRIPT.new()
	if not bool(state.configure({}, {}, true).get("ok", false)):
		_check(false, "Kampagnenstand laesst sich konfigurieren")
	return state

func _cmd(state: RefCounted, operation: String, payload: Dictionary, context: Dictionary = {}) -> Dictionary:
	_seq += 1
	return state.apply_command(COMMANDS_SCRIPT.build_command(operation, payload, "t8:%d" % _seq), context)

func _job(state: RefCounted) -> Dictionary:
	return Dictionary(state.get_campaign_snapshot().jobs[JOB])

func _make_active(state: RefCounted) -> bool:
	var snap: Dictionary = state.get_campaign_snapshot()
	var location_id: String = String(snap.jobs[JOB].location_id)
	var pad_id: String = String(Array(snap.locations["homebase"].landing_pad_ids)[0])
	var ok := bool(_cmd(state, "accept_job", {"job_id": JOB}).get("ok", false))
	ok = ok and bool(_cmd(state, "select_destination", {"location_id": location_id, "job_id": JOB}).get("ok", false))
	ok = ok and bool(_cmd(state, "bind_departure", {"craft_id": CRAFT, "origin_location_id": "homebase", "destination_location_id": location_id, "landing_pad_id": pad_id, "job_id": JOB}, {"departure_authorized": true}).get("ok", false))
	ok = ok and bool(_cmd(state, "activate_job", {"job_id": JOB, "craft_id": CRAFT}, {"departure_authorized": true}).get("ok", false))
	return ok and String(_job(state).status) == "active"

func _fail(state: RefCounted, result: String, win_condition: String, mission_aborted: bool = false) -> Dictionary:
	var evidence := {"result": result}
	if win_condition != "__none__":
		evidence["win_condition_type"] = win_condition
	return _cmd(state, "fail_job", {"job_id": JOB, "craft_id": CRAFT}, {"runtime_evidence": evidence, "mission_aborted": mission_aborted})

func _departure_bound(state: RefCounted) -> bool:
	return state.get_campaign_snapshot().departures_by_craft_id.has(CRAFT)

func _state_part() -> void:
	_check(Array(STATE_SCRIPT.RETREAT_WIN_CONDITIONS) == ["evacuation", "departure"], "RETREAT_WIN_CONDITIONS steht an einer Stelle und nennt evacuation und departure")
	_check(COMMANDS_SCRIPT.OPERATIONS.has("reopen_retreated_job"), "Befehlsvertrag kennt reopen_retreated_job")
	var state: RefCounted = _new_state()
	_check(_make_active(state), "Auftrag angenommen, Abflug gebunden, aktiv")
	_check(int(_job(state).get("retreat_count", 0)) == 0 and not bool(_job(state).get("reopen_at_home", false)), "Vor dem Einsatz: retreat_count 0, reopen_at_home false")
	var not_flagged: Dictionary = _cmd(state, "reopen_retreated_job", {"job_id": JOB})
	_check(not bool(not_flagged.get("ok", true)) and String(_job(state).status) == "active", "Wiederoeffnen eines aktiven Auftrags wird abgelehnt")

	# Rueckzug (evacuation)
	var retreat: Dictionary = _fail(state, "aborted", "evacuation")
	var job: Dictionary = _job(state)
	_check(bool(retreat.get("ok", false)), "Rueckzug (evacuation) wird als Beenden angenommen")
	_check(String(job.status) == "failed" and int(job.get("retreat_count", 0)) == 1 and bool(job.get("reopen_at_home", false)), "Rueckzug: failed, retreat_count 1, reopen_at_home true")
	_check(String(retreat.get("message", "")) == "Rückzug. Auftrag bleibt offen.", "Rueckzug meldet: Rückzug. Auftrag bleibt offen.")
	_check(_departure_bound(state), "Rueckzug: Abflugbindung des Schiffs besteht noch")

	# Export mit offenem Rueckzug, spaeter wiederhergestellt
	var pending_export: Dictionary = state.export_state()

	# Wiederoeffnen
	var reopen: Dictionary = _cmd(state, "reopen_retreated_job", {"job_id": JOB})
	job = _job(state)
	_check(bool(reopen.get("ok", false)) and String(reopen.get("message", "")) == "Auftrag wieder offen", "Wiederoeffnen gelingt: Auftrag wieder offen")
	_check(String(job.status) == "accepted" and not bool(job.get("reopen_at_home", true)) and int(job.get("retreat_count", 0)) == 1, "Wiederoeffnen: accepted, reopen_at_home false, retreat_count bleibt 1")
	_check(not _departure_bound(state) and not job.has("craft_id"), "Wiederoeffnen: Abflugbindung und craft_id geloescht")
	var before: Dictionary = state.export_state()
	var again: Dictionary = _cmd(state, "reopen_retreated_job", {"job_id": JOB})
	_check(not bool(again.get("ok", true)), "Zweites Wiederoeffnen wird abgelehnt")
	_check(JSON.stringify(state.export_state(), "", true) == JSON.stringify(before, "", true), "Abgelehntes Wiederoeffnen aendert nichts")
	var unknown: Dictionary = _cmd(state, "reopen_retreated_job", {"job_id": "gibt_es_nicht"})
	_check(not bool(unknown.get("ok", true)), "Wiederoeffnen eines unbekannten Auftrags wird abgelehnt")

	# Zweiter Rueckzug ueber departure
	_check(_make_active(state), "Nach dem Wiederoeffnen wieder aktiv machen ohne Erneut annehmen")
	var second: Dictionary = _fail(state, "aborted", "departure")
	job = _job(state)
	_check(bool(second.get("ok", false)) and String(job.status) == "failed" and int(job.get("retreat_count", 0)) == 2 and bool(job.get("reopen_at_home", false)), "Rueckzug (departure) zaehlt: retreat_count 2, reopen_at_home true")
	var after_reopen_export_source: RefCounted = state
	_check(bool(_cmd(state, "reopen_retreated_job", {"job_id": JOB}).get("ok", false)), "Zweites Wiederoeffnen nach dem zweiten Rueckzug gelingt")
	var reopened_export: Dictionary = after_reopen_export_source.export_state()

	# Niederlage: wie bisher
	_check(_make_active(state), "Fuer die Niederlage wieder aktiv")
	var defeat: Dictionary = _fail(state, "defeat", "evacuation")
	job = _job(state)
	_check(bool(defeat.get("ok", false)) and String(job.status) == "failed" and int(job.get("retreat_count", 0)) == 2 and not bool(job.get("reopen_at_home", false)), "Niederlage (auch mit evacuation-Kennung): failed, retreat_count unveraendert, kein reopen_at_home")
	_check(String(defeat.get("message", "")) == "Auftrag beendet", "Niederlage meldet wie bisher: Auftrag beendet")
	_check(_departure_bound(state), "Niederlage: Abflugbindung bleibt")
	_check(not bool(_cmd(state, "reopen_retreated_job", {"job_id": JOB}).get("ok", true)), "Niederlage: Wiederoeffnen wird abgelehnt")
	_check(bool(_cmd(state, "retry_failed_job", {"job_id": JOB}).get("ok", false)) and String(_job(state).status) == "accepted" and not _departure_bound(state), "Niederlage: Erneut annehmen funktioniert wie bisher")

	# Alles andere ohne passende Kennung bleibt Fehlschlag
	for case: Array in [["aborted", ""], ["aborted", "elimination"], ["aborted", "__none__"], ["timeout", "evacuation"], ["timeout", "departure"]]:
		_check(_make_active(state), "Fuer %s/%s wieder aktiv" % case)
		var plain: Dictionary = _fail(state, String(case[0]), String(case[1]))
		job = _job(state)
		_check(bool(plain.get("ok", false)) and String(job.status) == "failed" and int(job.get("retreat_count", 0)) == 2 and not bool(job.get("reopen_at_home", false)), "%s mit win_condition_type '%s' ist ein Fehlschlag wie die Niederlage" % case)
		_check(not bool(_cmd(state, "reopen_retreated_job", {"job_id": JOB}).get("ok", true)), "%s/%s: Wiederoeffnen wird abgelehnt" % case)
		_check(bool(_cmd(state, "retry_failed_job", {"job_id": JOB}).get("ok", false)), "%s/%s: Erneut annehmen funktioniert" % case)
	# Bewusstes Aufgeben (mission_aborted aus dem Kontext, ohne Ergebnis)
	_check(_make_active(state), "Fuer das Aufgeben wieder aktiv")
	var abandon: Dictionary = _cmd(state, "fail_job", {"job_id": JOB, "craft_id": CRAFT}, {"mission_aborted": true})
	job = _job(state)
	_check(bool(abandon.get("ok", false)) and String(job.status) == "failed" and int(job.get("retreat_count", 0)) == 2 and not bool(job.get("reopen_at_home", false)), "Aufgeben (mission_aborted): failed, kein Rueckzug")
	_check(not bool(_cmd(state, "reopen_retreated_job", {"job_id": JOB}).get("ok", true)), "Aufgeben: Wiederoeffnen wird abgelehnt")
	# Nicht autorisierter Fehlschlag bleibt abgelehnt
	_check(bool(_cmd(state, "retry_failed_job", {"job_id": JOB}).get("ok", false)) and _make_active(state), "Wieder aktiv fuer die Autorisierungsprobe")
	_check(not bool(_fail(state, "victory", "evacuation").get("ok", true)), "Ergebnis victory ist kein Fehlschlag")

	_persistence_part(pending_export, reopened_export)

# ---------------------------------------------------------------- Speichern und Laden

func _roundtrip(data: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(data))

func _persistence_part(pending_export: Dictionary, reopened_export: Dictionary) -> void:
	var restored: RefCounted = _new_state()
	var result: Dictionary = restored.restore_state(_roundtrip(pending_export))
	var job: Dictionary = _job(restored)
	_check(bool(result.get("ok", false)), "Gespeicherter Stand mit offenem Rueckzug wird geladen")
	_check(String(job.status) == "failed" and int(job.get("retreat_count", 0)) == 1 and bool(job.get("reopen_at_home", false)), "Nach Laden: retreat_count 1 und reopen_at_home true erhalten")
	_check(bool(_cmd(restored, "reopen_retreated_job", {"job_id": JOB}).get("ok", false)) and String(_job(restored).status) == "accepted", "Nach Laden laesst sich der Auftrag wiederoeffnen")
	var restored_twice: RefCounted = _new_state()
	var reopened_result: Dictionary = restored_twice.restore_state(_roundtrip(reopened_export))
	_check(bool(reopened_result.get("ok", false)) and int(_job(restored_twice).get("retreat_count", 0)) == 2 and not bool(_job(restored_twice).get("reopen_at_home", true)), "Stand mit Wiederoeffnen-Beleg (requests) wird geladen, retreat_count 2")
	# Stand ohne die Felder bleibt gueltig
	var legacy: Dictionary = _roundtrip(pending_export)
	for id in legacy.jobs:
		legacy.jobs[id].erase("retreat_count")
		legacy.jobs[id].erase("reopen_at_home")
	var old_state: RefCounted = _new_state()
	var legacy_result: Dictionary = old_state.restore_state(legacy)
	_check(bool(legacy_result.get("ok", false)), "Stand ohne retreat_count und reopen_at_home wird akzeptiert")
	_check(int(_job(old_state).get("retreat_count", 0)) == 0 and not bool(_job(old_state).get("reopen_at_home", false)), "Fehlende Felder liefern 0 und false")
	# Falsche Typen werden abgelehnt
	var bad_text: Dictionary = _roundtrip(pending_export)
	bad_text.jobs[JOB]["retreat_count"] = "1"
	_check(not bool(_new_state().restore_state(bad_text).get("ok", true)), "retreat_count als Text wird abgelehnt")
	var bad_float: Dictionary = _roundtrip(pending_export)
	bad_float.jobs[JOB]["retreat_count"] = 1.5
	_check(not bool(_new_state().restore_state(bad_float).get("ok", true)), "retreat_count mit Nachkommastelle wird abgelehnt")
	var bad_negative: Dictionary = _roundtrip(pending_export)
	bad_negative.jobs[JOB]["retreat_count"] = -1
	_check(not bool(_new_state().restore_state(bad_negative).get("ok", true)), "negatives retreat_count wird abgelehnt")
	var bad_flag: Dictionary = _roundtrip(pending_export)
	bad_flag.jobs[JOB]["reopen_at_home"] = "true"
	_check(not bool(_new_state().restore_state(bad_flag).get("ok", true)), "reopen_at_home als Text wird abgelehnt")
	var bad_status: Dictionary = _roundtrip(pending_export)
	bad_status.jobs[JOB]["status"] = "accepted"
	bad_status.jobs[JOB].erase("craft_id")
	_check(not bool(_new_state().restore_state(bad_status).get("ok", true)), "reopen_at_home bei einem Auftrag, der nicht failed ist, wird abgelehnt")

# ---------------------------------------------------------------- Adapter mit echter Meta-Szene

func _adapter_part() -> void:
	var s: Dictionary = await _begin_sortie()
	if s.is_empty(): return
	var driver: Node = s.driver
	if not _place_at(s.simulation, s.access, "campaign_leader", Vector2.ZERO): return
	if not _place_at(s.simulation, s.access, "campaign_pilot", Vector2.ZERO): return
	driver.call("_resolve_combat", "aborted", "", "evacuation")
	if not await _wait_released("R: Einsatz wird nach dem Rueckzug freigegeben"): return
	var job: Dictionary = Dictionary(_runtime.call("get_snapshot").campaign.jobs[JOB])
	print("RETREAT_ADAPTER job=", job, " locations=", _flow.get("_aircraft_location_by_craft"))
	_check(String(job.status) == "failed" and int(job.get("retreat_count", 0)) == 1 and bool(job.get("reopen_at_home", false)), "R: echter Rueckzug: failed, retreat_count 1, reopen_at_home true")
	_check(bool(_runtime.call("authorize_return", _craft_id).get("ok", false)), "R: authorize_return des Schiffs ist ok")
	# Schiff ist nach dem Rückzug noch unterwegs: Ort "mission" und offener Rückflug (kein Fixture, echter Zustand).
	var locations: Dictionary = Dictionary(_flow.get("_aircraft_location_by_craft"))
	print("RETREAT_ADAPTER transfers=", _flow.get("_pending_mission_craft_transfers"))
	var away: Dictionary = _runtime.call("reopen_retreated_jobs")
	var away_job: Dictionary = Dictionary(_runtime.call("get_snapshot").campaign.jobs[JOB])
	_check(bool(away.get("ok", false)) and PackedStringArray(away.get("reopened_job_ids", PackedStringArray(["x"]))).is_empty(), "R: Schiff am Einsatzort: reopen_retreated_jobs liefert eine leere Liste")
	_check(String(away_job.status) == "failed" and bool(away_job.get("reopen_at_home", false)), "R: Schiff am Einsatzort: Auftrag bleibt failed mit gesetztem Flag")
	# Schiff zu Hause: kurz auf den echten Rückflug warten. Im Headless-Lauf bleibt die Übergabe in "surface_retirement" stehen
	# (gemessen: auch nach 120 s). Dann gilt als Fixture:
	# _pending_mission_craft_transfers leeren und _aircraft_location_by_craft[craft] = "homebase" setzen.
	var started: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < 5000 and not (Array(_flow.get("_pending_mission_craft_transfers")).is_empty() and String(Dictionary(_flow.get("_aircraft_location_by_craft")).get(_craft_id, "")) == "homebase"):
		await process_frame
	var arrived_naturally: bool = Array(_flow.get("_pending_mission_craft_transfers")).is_empty() and String(Dictionary(_flow.get("_aircraft_location_by_craft")).get(_craft_id, "")) == "homebase"
	print("RETREAT_ADAPTER arrived_naturally=", arrived_naturally, " waited_ms=", Time.get_ticks_msec() - started)
	if not arrived_naturally:
		_flow.set("_pending_mission_craft_transfers", [])
		locations = Dictionary(_flow.get("_aircraft_location_by_craft"))
		locations[_craft_id] = "homebase"
		_flow.set("_aircraft_location_by_craft", locations)
	var home: Dictionary = _runtime.call("reopen_retreated_jobs")
	var home_job: Dictionary = Dictionary(_runtime.call("get_snapshot").campaign.jobs[JOB])
	_check(bool(home.get("ok", false)) and Array(PackedStringArray(home.get("reopened_job_ids", PackedStringArray()))) == [JOB], "R: Schiff zu Hause: reopened_job_ids == [satellite_recovery]")
	_check(String(home_job.status) == "accepted" and not bool(home_job.get("reopen_at_home", true)) and int(home_job.get("retreat_count", 0)) == 1, "R: Auftrag steht auf accepted, Flag gesetzt zurueck, retreat_count 1")
	var snap: Dictionary = _runtime.call("get_snapshot").campaign
	_check(not Dictionary(snap.departures_by_craft_id).has(_craft_id) and not home_job.has("craft_id"), "R: Abflugbindung und craft_id sind geloescht")
	var second: Dictionary = _runtime.call("reopen_retreated_jobs")
	_check(bool(second.get("ok", false)) and PackedStringArray(second.get("reopened_job_ids", PackedStringArray(["x"]))).is_empty(), "R: zweiter Aufruf liefert eine leere Liste")
	_check(String(Dictionary(_runtime.call("get_snapshot").campaign.jobs[JOB]).status) == "accepted", "R: zweiter Aufruf aendert nichts")
	await _end_sortie()
