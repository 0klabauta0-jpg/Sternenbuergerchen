extends "res://scripts/tests/campaign_casualty_departure_verifier.gd"
## R3d Respawn (Vorschau und Totalverlust): Die Vorschau des Abflugs rechnet mit derselben Grenze wie das echte Ende,
## und ein Totalverlust bleibt ein Totalverlust (niemand stirbt, niemand kommt wieder, der Kader bleibt wie er ist).
## Echter Einsatz mit Truppfuehrer und Pilot (wie Szenario C des Departure-Verifiers), einmal mit Grenze 3 (Vorgabe), einmal mit Grenze 0.
## Die Grenze wird in den Einstellungen des Wegwerfprofils gesetzt und am Ende auf den Anfangswert zurueckgestellt.
## Abschlusszeile: CAMPAIGN_RESPAWN_DEPARTURE passed=%d failed=%d

const SETTINGS = preload("res://scripts/ui/game_settings_contract.gd")

const R3_GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")

func _run() -> void:
	var verdict: Dictionary = R3_GUARD.verdict_from_environment()
	if not bool(verdict.get("ok", false)):
		print("CAMPAIGN_RESPAWN_DEPARTURE refused: needs a throwaway profile (SB_REVIEW2_USER_DIR), nothing written. Reason: %s" % str(verdict.get("reason", "")))
		quit(2)
		return
	# Den Anfangswert merken und genau ihn zurueckschreiben (nicht ein festes 3).
	var initial_limit: int = SETTINGS.load_campaign_respawn_limit()
	_configure_entry()
	await _preview_case(3)
	await _preview_case(0)
	_set_limit(initial_limit)
	_check(SETTINGS.load_campaign_respawn_limit() == initial_limit, "Ende: Einstellung steht wieder auf dem Anfangswert %d" % initial_limit)
	print("CAMPAIGN_RESPAWN_DEPARTURE passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _set_limit(limit: int) -> void:
	var settings: Dictionary = SETTINGS.load_settings()
	settings["campaign_respawn_limit"] = limit
	SETTINGS.save_settings(settings)

func _preview_case(limit: int) -> void:
	var tag: String = "R%d" % limit
	_set_limit(limit)
	_check(SETTINGS.load_campaign_respawn_limit() == limit, tag + ": Einstellung steht auf %d" % limit)
	var s: Dictionary = await _begin_sortie()
	if s.is_empty(): return
	var leader: Node2D = s.leader
	var driver: Node = s.driver
	leader.call("apply_damage", 10000)
	if not await _wait(func(): return bool(Dictionary(driver.call("get_casualty_flags")).get("campaign_leader", {}).get("was_downed", false)), 5000, tag + ": Treiber merkt sich die ausgefallene Person"): return
	if not _seat_crew(s): return
	var rules: Dictionary = _flow.call("_get_campaign_casualty_rules")
	var preview: Dictionary = _flow.call("_resolve_campaign_casualties", {"mission_outcome": "aborted"}, rules)
	var preview_again: Dictionary = _flow.call("_resolve_campaign_casualties", {"mission_outcome": "aborted"}, rules)
	print("RESPAWN_DEPARTURE_PREVIEW limit=", limit, " total_loss=", preview.get("total_loss"), " reason=", preview.get("total_loss_reason"), " respawn_limit=", preview.get("respawn_limit"))
	_check(int(preview.get("respawn_limit", -1)) == limit, tag + ": Vorschau rechnet mit Grenze %d" % limit)
	_check(preview == preview_again, tag + ": Vorschau ist wiederholbar und aendert nichts")
	var roster_before: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	var departure: Dictionary = _request_return()
	print("RESPAWN_DEPARTURE_REQUEST ", departure)
	if not await _wait(func(): return _flow.get("_active_mission") == null, 120000, tag + ": Einsatz wird freigegeben"): return
	await process_frame
	var result: Dictionary = Dictionary(_flow.get("_last_mission_result")).duplicate(true)
	_check(bool(result.get("casualty_total_loss", false)) == bool(preview.get("total_loss", false)) and String(result.get("total_loss_reason", "")) == String(preview.get("total_loss_reason", "x")), tag + ": das echte Ende hat dasselbe Totalverlust-Ergebnis wie die Vorschau (%s / %s)" % [result.get("total_loss_reason", ""), preview.get("total_loss_reason", "")])
	_check(bool(result.get("casualty_total_loss", false)) and String(result.get("total_loss_reason", "")) == "ground_team_down", tag + ": Totalverlust, Grund ground_team_down, mit jeder Grenze")
	_check(PackedStringArray(result.get("respawn_unit_ids", PackedStringArray())).is_empty() and PackedStringArray(result.get("fatality_unit_ids", PackedStringArray())).is_empty(), tag + ": im Totalverlust kommt niemand wieder und niemand faellt")
	var changed: bool = false
	for unit: Dictionary in Array(_flow.get("_all_team_units")):
		if String(unit.get("availability_status", "")) in ["respawning", "awaiting_pickup"] or int(unit.get("respawns_used", 0)) != 0:
			changed = true
	_check(not changed and Array(_flow.get("_all_team_units")).size() == roster_before.size() and Array(_runtime.call("get_fallen")).is_empty(), tag + ": Kader gleich gross, niemand respawning, Gefallenenliste leer")
	await _end_sortie()
