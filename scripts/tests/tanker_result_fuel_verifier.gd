extends "res://scripts/tests/campaign_casualty_apply_verifier.gd"
## T1 Fix-Runde 1, K1: Das Ergebnis eines Einsatzes haengt nie am Treibstoff (Regel 8 / Auftrag 21.11.).
## Ende-zu-Ende mit echtem Kampagneneinsatz (satellite_recovery am Absturzort): Das Schiff steht am Ort, der Tank reicht nicht fuer den
## Ortsabflug (surface_exit 7). Der Sieg wird aufgeloest. Erwartung: Ergebnis wird festgehalten (_pending_campaign_mission_result),
## nichts wird gebucht und nichts geht verloren, nur der Abflug ist gesperrt (Meldung "Treibstoff reicht nicht fuer den Rueckflug").
## Nach dem Tanken laeuft der Abschluss durch: Sieg, Auftrag abgeschlossen, Belohnung genau einmal, kein Rueckzug.
## Grenze (wie in campaign_casualty_apply_verifier D): am Driver aufgeloest erfuellt der Einsatz die Auftragsschritte nicht von selbst.
## Die erfuellten Schritte werden deshalb in das gehaltene Ergebnis gelegt und der Chip ins Schiff gebucht; alles andere ist der echte Ablauf.

func _run() -> void:
	_configure_entry()
	await _k1_result_survives_missing_fuel()
	print("TANKER_RESULT_FUEL passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _fuel() -> float:
	return float(Dictionary(_supply().get("fuel_by_craft_id", {})).get(_craft_id, -1.0))

func _set_fuel(value: float) -> void:
	Dictionary(_runtime.get("_supply").get("_fuel_by_craft_id"))[_craft_id] = value

func _credits() -> int:
	return int(_supply().get("credits", -1))

func _job() -> Dictionary:
	return Dictionary(_campaign().jobs.satellite_recovery)

## Das wartende Ergebnis, wo der Ablauf es ablegt: im Flow (fokussierte Instanz) oder im Kontext des Ortes.
func _pending() -> Dictionary:
	var pending: Dictionary = Dictionary(_flow.get("_pending_campaign_mission_result"))
	if not pending.is_empty():
		return pending
	for context: Dictionary in Dictionary(_flow.get("_location_contexts")).values():
		if not Dictionary(context.get("pending", {})).is_empty():
			return Dictionary(context.get("pending", {}))
	return {}

func _settle_frames(count: int) -> void:
	for i in count:
		await process_frame

func _k1_result_survives_missing_fuel() -> void:
	var s: Dictionary = await _begin_sortie()
	if s.is_empty(): return
	_identity_before = _identity(_screen.call("get_operations_snapshot"))
	if not _place_at(s.simulation, s.access, "campaign_leader", Vector2.ZERO): return
	if not _place_at(s.simulation, s.access, "campaign_pilot", Vector2.ZERO): return
	var fuel_on_site: float = _fuel()
	_check(fuel_on_site >= 7.0, "K1: am Ort ist nach Abheben, Sprung und Anflug genug da, um den Ort verlassen zu koennen (%.1f)" % fuel_on_site)
	# Der Tank reicht nicht fuer den Ortsabflug (surface_exit 7).
	_set_fuel(1.0)
	var credits_before: int = _credits()
	var job_before: Dictionary = _job()
	_check(String(job_before.get("status", "")) == "active", "K1: Auftrag ist aktiv")
	s.driver.call("_resolve_combat", "victory", String(s.driver.get("friendly_team_id")))
	await _settle_frames(30)
	var pending: Dictionary = _pending()
	var gate_error: Variant = _screen.get_meta("singleplayer_departure_error", {})
	print("K1_HELD pending=", pending.get("result", "-"), " released=", _flow.get("_active_mission") == null, " job=", _job().get("status"), " retreat=", _job().get("retreat_count", 0), " credits=", _credits(), " error=", gate_error)
	_check(String(pending.get("result", "")) == "victory", "K1: das Ergebnis (Sieg) wird festgehalten, nicht verworfen")
	_check(_flow.get("_active_mission") == s.mission, "K1: der Einsatz bleibt stehen, das Schiff wird nicht freigegeben")
	_check(gate_error is Dictionary and String(Dictionary(gate_error).get("reason", "")) == "leg_fuel_insufficient", "K1: gesperrt ist nur der Abflug, Grund leg_fuel_insufficient")
	_check(is_equal_approx(_fuel(), 1.0), "K1: kein Treibstoff abgebucht (%.1f)" % _fuel())
	_check(String(_job().get("status", "")) == "active" and int(_job().get("retreat_count", 0)) == 0, "K1: Auftrag bleibt aktiv, kein Rueckzug gebucht")
	_check(_credits() == credits_before, "K1: noch keine Belohnung gebucht")
	# Der Spieler drueckt "Abheben": die vorhandene Meldung, kein stilles Nichts, nichts wird aufgeloest.
	var reply: Dictionary = _runtime.call("request_operation", "return_homebase", {"craft_id": _craft_id})
	await _settle_frames(5)
	print("K1_DEPART_BLOCKED ", reply)
	_check(not bool(reply.get("ok", true)), "K1: Abflug mit zu wenig Treibstoff wird abgelehnt")
	_check(_flow.get("_active_mission") == s.mission and String(_job().get("status", "")) == "active" and int(_job().get("retreat_count", 0)) == 0, "K1: nach dem Abflugversuch weiter: Einsatz da, Auftrag aktiv, kein Rueckzug")
	_check(String(_pending().get("result", "")) == "victory", "K1: das Ergebnis wartet auch nach dem Abflugversuch")
	# Die Auftragsschritte gelten als erfuellt (siehe Grenze oben), der Chip ist an Bord.
	var held: Dictionary = _pending()
	held["mission_scenario_runtime_gates"] = {"all_gates_complete": true, "completed_step_ids": Array(job_before.get("required_step_ids", []))}
	_flow.set("_pending_campaign_mission_result", held)
	_flow.call("_remember_location", s.mission)
	var chip: Dictionary = _runtime.call("_campaign_cargo", _craft_id, "satellite_chip", 1, "chip:satellite_recovery")
	_check(bool(chip.get("ok", false)), "K1: Chip ist an Bord (%s)" % [chip])
	# Aufgetankt (am Ort mit Tankservice oder hier direkt gesetzt): der Abschluss laeuft durch.
	_set_fuel(20.0)
	if not await _wait_released("K1: nach dem Tanken wird der Einsatz abgeschlossen und freigegeben"): return
	await _settle_frames(10)
	var result: Dictionary = Dictionary(_flow.get("_last_mission_result"))
	var job_after: Dictionary = _job()
	var credits_after: int = _credits()
	print("K1_DONE result=", result.get("result"), " job=", job_after.get("status"), " retreat=", job_after.get("retreat_count", 0), " credits ", credits_before, " -> ", credits_after, " fuel=", _fuel(), " pending=", _pending().is_empty())
	_check(String(result.get("result", "")) == "victory", "K1: das Ergebnis des Debriefs ist der Sieg")
	_check(String(job_after.get("status", "")) not in ["active", "failed"] and int(job_after.get("retreat_count", 0)) == 0, "K1: Auftrag ist abgeschlossen (%s), kein Rueckzug" % job_after.get("status"))
	_check(credits_after == credits_before, "K1: die Belohnung kommt erst mit dem Hochladen zu Hause (%d -> %d)" % [credits_before, credits_after])
	_check(is_equal_approx(_fuel(), 13.0), "K1: der Ortsabflug hat jetzt genau seinen Anteil gebucht (20 - 7 = 13, ist %.1f)" % _fuel())
	_check(_pending().is_empty(), "K1: nichts wartet mehr")
	# Heimkehr: Orbit, Sprung, Landung, Hochladen.
	if not await _wait_homebase(): return
	await _settle_frames(30)
	var final_job: Dictionary = _job()
	print("K1_HOME job=", final_job.get("status"), " retreat=", final_job.get("retreat_count", 0), " credits=", _credits(), " receipts=", Dictionary(_campaign().get("completion_receipts", {})).size(), " fuel=", _fuel())
	_check(String(final_job.get("status", "")) == "completed" and int(final_job.get("retreat_count", 0)) == 0, "K1: Heimkehr: Auftrag abgeschlossen, kein Rueckzug (%s)" % final_job.get("status"))
	_check(_credits() == credits_before + 150, "K1: Belohnung genau einmal gebucht (%d -> %d)" % [credits_before, _credits()])
	_check(Dictionary(_campaign().get("completion_receipts", {})).size() == 1, "K1: genau ein Abschlussbeleg")
	_check(is_equal_approx(_fuel(), 8.0), "K1: Rueckweg bucht Ortsabflug 7 und Sprung 5 je einmal (20 - 12 = 8, ist %.1f)" % _fuel())
	await _end_sortie()
