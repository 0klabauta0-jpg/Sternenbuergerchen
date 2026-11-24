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
	await _w7_place_to_place()
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
	_check(fuel_on_site >= 2.0, "K1: am Ort ist nach Abheben, Sprung und Anflug genug da, um den Ort verlassen zu koennen (%.1f)" % fuel_on_site)
	# Der Tank reicht nicht fuer den Ortsabflug (surface_exit 2).
	_set_fuel(1.0)
	# Auftragsschritte und Chip stehen vor der Entscheidung bereit (siehe Grenze oben: der Fahrer allein erfuellt die Schritte nicht).
	_flow.call("_remember_location", s.mission)
	var chip: Dictionary = _runtime.call("_campaign_cargo", _craft_id, "satellite_chip", 1, "chip:satellite_recovery")
	_check(bool(chip.get("ok", false)), "K1: Chip ist an Bord (%s)" % [chip])
	var credits_before: int = _credits()
	var job_before: Dictionary = _job()
	_check(String(job_before.get("status", "")) == "active", "K1: Auftrag ist aktiv")
	_resolve_with_gates(s.driver, Array(job_before.get("required_step_ids", [])))
	await _settle_frames(30)
	var pending: Dictionary = _pending()
	var gate_error: Variant = _screen.get_meta("singleplayer_departure_error", {})
	print("K1_HELD pending=", pending.get("result", "-"), " released=", _flow.get("_active_mission") == null, " job=", _job().get("status"), " retreat=", _job().get("retreat_count", 0), " credits=", _credits(), " error=", gate_error)
	_check(String(pending.get("result", "")) == "victory", "K1: das Ergebnis (Sieg) wird festgehalten, nicht verworfen")
	_check(_flow.get("_active_mission") == s.mission, "K1: der Einsatz bleibt stehen, das Schiff wird nicht freigegeben")
	_check(gate_error is Dictionary and String(Dictionary(gate_error).get("reason", "")) == "leg_fuel_insufficient", "K1: gesperrt ist nur der Abflug, Grund leg_fuel_insufficient")
	_check(is_equal_approx(_fuel(), 1.0), "K1: kein Treibstoff abgebucht (%.1f)" % _fuel())
	# Fix-Runde 2, W9: Das Ergebnis ist sofort gebucht (Auftrag nicht mehr aktiv), nur der Abflug ist gesperrt. Die Belohnung dieses Auftrags
	# kommt in jedem Fall erst mit dem Hochladen zu Hause (pending_upload), unabhaengig vom Treibstoff.
	_check(String(_job().get("status", "")) in ["pending_upload", "completed"] and int(_job().get("retreat_count", 0)) == 0, "W9: Ergebnis sofort gebucht: Auftrag %s, kein Rueckzug" % _job().get("status"))
	_check(_credits() == credits_before, "W9: Belohnung wartet auf das Hochladen zu Hause, keine Doppelbuchung (%d)" % _credits())
	# Der Spieler drueckt "Abheben": die vorhandene Meldung, kein stilles Nichts, nichts wird aufgeloest.
	var reply: Dictionary = _runtime.call("request_operation", "return_homebase", {"craft_id": _craft_id})
	await _settle_frames(5)
	print("K1_DEPART_BLOCKED ", reply)
	_check(not bool(reply.get("ok", true)), "K1: Abflug mit zu wenig Treibstoff wird abgelehnt")
	_check(_flow.get("_active_mission") == s.mission and String(_job().get("status", "")) in ["pending_upload", "completed"] and int(_job().get("retreat_count", 0)) == 0, "K1: nach dem Abflugversuch weiter: Einsatz da, Ergebnis gebucht, kein Rueckzug")
	_check(String(_pending().get("result", "")) == "victory", "K1: das Ergebnis wartet auch nach dem Abflugversuch")
	# Aufgetankt (am Ort mit Tankservice oder hier direkt gesetzt): der Abschluss laeuft durch.
	_set_fuel(fuel_on_site)
	if not await _wait_released("K1: nach dem Tanken wird der Einsatz abgeschlossen und freigegeben"): return
	await _settle_frames(10)
	var result: Dictionary = Dictionary(_flow.get("_last_mission_result"))
	var job_after: Dictionary = _job()
	var credits_after: int = _credits()
	print("K1_DONE result=", result.get("result"), " job=", job_after.get("status"), " retreat=", job_after.get("retreat_count", 0), " credits ", credits_before, " -> ", credits_after, " fuel=", _fuel(), " pending=", _pending().is_empty())
	_check(String(result.get("result", "")) == "victory", "K1: das Ergebnis des Debriefs ist der Sieg")
	_check(String(job_after.get("status", "")) not in ["active", "failed"] and int(job_after.get("retreat_count", 0)) == 0, "K1: Auftrag ist abgeschlossen (%s), kein Rueckzug" % job_after.get("status"))
	_check(credits_after == credits_before, "K1: die Belohnung kommt erst mit dem Hochladen zu Hause (%d -> %d)" % [credits_before, credits_after])
	_check(is_equal_approx(_fuel(), fuel_on_site - 2.0), "K1: der Ortsabflug hat jetzt genau seinen Anteil gebucht (%.1f - 2, ist %.1f)" % [fuel_on_site, _fuel()])
	_check(_pending().is_empty(), "K1: nichts wartet mehr")
	# Heimkehr: Orbit, Sprung, Landung, Hochladen.
	if not await _wait_homebase(): return
	await _settle_frames(30)
	var final_job: Dictionary = _job()
	print("K1_HOME job=", final_job.get("status"), " retreat=", final_job.get("retreat_count", 0), " credits=", _credits(), " receipts=", Dictionary(_campaign().get("completion_receipts", {})).size(), " fuel=", _fuel())
	_check(String(final_job.get("status", "")) == "completed" and int(final_job.get("retreat_count", 0)) == 0, "K1: Heimkehr: Auftrag abgeschlossen, kein Rueckzug (%s)" % final_job.get("status"))
	_check(_credits() == credits_before + 150, "K1: Belohnung genau einmal gebucht (%d -> %d)" % [credits_before, _credits()])
	_check(Dictionary(_campaign().get("completion_receipts", {})).size() == 1, "K1: genau ein Abschlussbeleg")
	_check(is_equal_approx(_fuel(), fuel_on_site - 12.0), "K1: Rueckweg bucht Ortsabflug 2 und Sprung 10 je einmal (%.1f - 12, ist %.1f)" % [fuel_on_site, _fuel()])
	# W6: die ganze Reise Heimat -> Absturzstelle -> Heimat summiert sich auf den alten Wert 24 (Abheben 1, Sprung 10, Anflug 1, Ortsabflug 2, Sprung 10, Landung 0).
	var start_fuel: float = float(Dictionary(JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/trade_offers.json"))).get("initial_fuel", -1.0))
	_check(is_equal_approx(fuel_on_site, start_fuel - 12.0) and is_equal_approx(_fuel(), start_fuel - 24.0), "W6: Hinweg 12 + Rueckweg 12 == 24, der Rueckweg bucht nicht doppelt (Start %.1f, am Ort %.1f, daheim %.1f)" % [start_fuel, fuel_on_site, _fuel()])
	# W6: die Belege der Etappen ueberstehen den echten Basis-Stand (Speichern, Laden): hier ist der Flow nach "Weiter" neu gebaut.
	var ids: PackedStringArray = PackedStringArray(Dictionary(_runtime.get("_supply").get("_requests")).keys())
	var launches := 0
	var jumps := 0
	var approaches := 0
	var returns := 0
	for id: String in ids:
		if id.ends_with(":leg:launch"): launches += 1
		elif id.ends_with(":leg:jump"): jumps += 1
		elif id.begins_with("return:") and id.ends_with(":fuel"): returns += 1
		elif id.begins_with("departure:") and id.ends_with(":fuel"): approaches += 1
	_check(launches == 1 and jumps == 2 and approaches == 1 and returns == 1, "W6: nach Speichern und Laden sind die Etappenbelege da (Abheben %d, Spruenge %d, Anflug %d, Ortsabflug %d)" % [launches, jumps, approaches, returns])
	await _end_sortie()

## Loest den Sieg ueber den Fahrer aus, ergaenzt die Auftragsschritte im Ergebnis (der Fahrer allein erfuellt sie nicht, siehe Grenze oben) und stellt
## das Ergebnis den echten Empfaengern des Signals zu (Flow-Wiederholer inklusive).
func _resolve_with_gates(driver: Node, step_ids: Array) -> void:
	var receivers: Array = driver.combat_resolved.get_connections()
	for connection: Dictionary in receivers:
		driver.combat_resolved.disconnect(connection.callable)
	var captured: Array = []
	var capture: Callable = func(result: Dictionary) -> void: captured.append(result)
	driver.combat_resolved.connect(capture)
	driver.call("_resolve_combat", "victory", String(driver.get("friendly_team_id")))
	driver.combat_resolved.disconnect(capture)
	for connection: Dictionary in receivers:
		driver.combat_resolved.connect(connection.callable)
	if captured.is_empty():
		_check(false, "K1: der Fahrer hat kein Ergebnis gemeldet")
		return
	var delivered: Dictionary = Dictionary(captured[0]).duplicate(true)
	delivered["mission_scenario_runtime_gates"] = {"all_gates_complete": true, "completed_step_ids": step_ids}
	for connection: Dictionary in receivers:
		(connection.callable as Callable).call(delivered)

## W7: Ort -> Ort (Absturzstelle -> Handelsposten) kostet in den echten Befehlen genau den alten Wert 10:
## Ortsabflug 7 (wie nach Hause, das Ziel ist beim Abheben vom Ort noch nicht gewaehlt), Sprung, Anflug.
func _w7_place_to_place() -> void:
	var s: Dictionary = await _begin_sortie()
	if s.is_empty(): return
	_identity_before = _identity(_screen.call("get_operations_snapshot"))
	if not _place_at(s.simulation, s.access, "campaign_leader", Vector2.ZERO): return
	if not _place_at(s.simulation, s.access, "campaign_pilot", Vector2.ZERO): return
	var fuel_on_site: float = _fuel()
	var job_before: Dictionary = _job()
	# Ergebnis erst festhalten, dann mit voller Reserve ausliefern: so laeuft der echte Ortsabflug mit erfuellten Schritten.
	_set_fuel(1.0)
	s.driver.call("_resolve_combat", "victory", String(s.driver.get("friendly_team_id")))
	await _settle_frames(30)
	var held: Dictionary = _pending()
	held["mission_scenario_runtime_gates"] = {"all_gates_complete": true, "completed_step_ids": Array(job_before.get("required_step_ids", []))}
	_flow.set("_pending_campaign_mission_result", held)
	_flow.call("_remember_location", s.mission)
	_check(bool(_runtime.call("_campaign_cargo", _craft_id, "satellite_chip", 1, "chip:satellite_recovery").get("ok", false)), "W7: Chip ist an Bord")
	_set_fuel(fuel_on_site)
	if not await _wait_released("W7: Einsatz abgeschlossen"): return
	if not await _wait(func(): return String(_space().get("phase", "")) == "orbit", 120000, "W7: Schiff im Orbit der Absturzstelle"): return
	_check(is_equal_approx(_fuel(), fuel_on_site - 2.0), "W7: der Ortsabflug bucht 2 (%.1f -> %.1f)" % [fuel_on_site, _fuel()])
	var fuel_orbit: float = _fuel()
	# Der Handelsposten ist im Kampagnenablauf noch gesperrt (tutorial_locked, erst nach der Absturzstelle). Fuer die reine Treibstoffrechnung wird die
	# Kampagnensperre nur fuer diese drei Befehle abgeschaltet; Treibstoff, Reisebesitzer und Buchungen bleiben die echten.
	_runtime.set("_campaign_mode", false)

	var trade_orbit: String = String(Dictionary(_space().get("location_orbits", {})).get("trade_outpost", ""))
	var jump: Dictionary = _screen.call("request_operation", "space_start_quantum", {"craft_id": _craft_id, "target_orbit_id": trade_orbit})
	_check(bool(jump.get("ok", false)), "W7: Sprung zum Handelsposten angenommen: %s" % [jump])
	if not await _wait(func(): return String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == trade_orbit, 60000, "W7: Schiff im Orbit des Handelspostens"): return
	var selected: Dictionary = _screen.call("request_operation", "select_destination", {"location_id": "trade_outpost", "job_id": ""})
	_check(bool(selected.get("ok", false)), "W7: im Orbit des Handelspostens wird er als Ziel gewaehlt: %s" % [selected])
	# Der Anflug am Handelsposten ist im Kampagnenablauf an einen Auftrag dort gebunden (launch_payload_invalid ohne ihn) und kann hier nicht echt befohlen werden.
	# Ort -> Ort: Ortsabflug 2 + Sprung 7 sind gebucht, Anflug 1 steht aus: Summe 2 + 7 + 1 = 10; die Summe aller Strecken mit echten Befehlen am Besitzer prueft tanker_leg_fuel_verifier.
	_runtime.set("_campaign_mode", true)
	_check(is_equal_approx(fuel_on_site - _fuel(), 9.0), "W7: bis zum Handelsposten sind genau Ortsabflug 2 und Sprung 7 gebucht (ist %.1f)" % (fuel_on_site - _fuel()))
	await _end_sortie()
