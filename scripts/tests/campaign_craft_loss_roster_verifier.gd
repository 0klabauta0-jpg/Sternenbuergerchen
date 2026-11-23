extends "res://scripts/tests/campaign_craft_loss_flow_verifier.gd"
## LC2f W1: Schiffsverlust und Kaderform. Wuerde das Entfernen der Toten den Kader unspielbar machen (kein Anfuehrer, kein Pilot, weniger als zwei),
## gilt fuer diesen Einsatz der bestehende Totalverlust (Ruecksprung auf den Stand vor dem Einsatz mit der Strafe) - nie "Tote bleiben im Kader".
## W1a (Fluss): der Anfuehrer stirbt beim Absturz endgueltig -> Totalverlust, Ruecksprung, Speichern und Laden gelingen, das Schiff ist wieder da.
## W1b (Hilfe): stirbt ein einfaches Mitglied (Kader bleibt spielbar), ist es KEIN Totalverlust.

func _run() -> void:
	_configure_entry()
	_w1b_playable_roster_is_not_total_loss()
	await _w1a_last_leader_dies_in_crash()
	print("CAMPAIGN_CRAFT_LOSS_ROSTER passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _w1b_playable_roster_is_not_total_loss() -> void:
	var flow: Node = FLOW.instantiate()
	root.add_child(flow)
	var roster: Array = Array(flow.get("_all_team_units")).duplicate(true)
	var extra: Dictionary = Dictionary(roster[0]).duplicate(true)
	extra["unit_id"] = "lc2f_simple_member"
	extra["roster_role_category"] = "infantry"
	roster.append(extra)
	flow.set("_all_team_units", roster)
	var simple: Dictionary = {"fatality_unit_ids": PackedStringArray(["lc2f_simple_member"])}
	var leader: Dictionary = {"fatality_unit_ids": PackedStringArray([String(Dictionary(roster[0]).get("unit_id", ""))])}
	_check(String(flow.call("_craft_loss_roster_problem", simple)) == "", "W1b: stirbt ein einfaches Mitglied, bleibt der Kader spielbar (kein Totalverlust)")
	_check(String(flow.call("_craft_loss_roster_problem", leader)) != "", "W1b: stirbt der einzige Anfuehrer, wird der Kader unspielbar (%s)" % String(flow.call("_craft_loss_roster_problem", leader)))
	flow.queue_free()
	await process_frame

func _w1a_last_leader_dies_in_crash() -> void:
	var s: Dictionary = await _begin_funded_sortie(500)
	if s.is_empty(): return
	_lose_craft(s)
	# Der Anfuehrer hat alle Respawns verbraucht: sein Tod ist endgueltig (sonst wartet er auf Abholung und bleibt im Kader).
	for unit in Array(_flow.get("_all_team_units")):
		if String(Dictionary(unit).get("unit_id", "")) == LEADER: Dictionary(unit)["respawns_used"] = int(Dictionary(_flow.call("_get_campaign_casualty_rules")).get("respawn_limit", 3))
	s.leader.set_meta("killed_in_crash", true)
	s.leader.call("apply_damage", 10000, {"source": "air_crash"})
	s.leader.call("advance_bleedout")
	if not await _wait(func(): return bool(Dictionary(s.driver.call("get_casualty_flags")).get(LEADER, {}).get("was_downed", false)), 5000, "W1a: Treiber merkt sich den Ausfall"): return
	s.driver.call("_resolve_combat", "aborted", "", "evacuation")
	if not await _wait_released("W1a: Einsatz wird freigegeben"): return
	var result: Dictionary = Dictionary(_flow.get("_last_mission_result")).duplicate(true)
	print("W1A_RESULT total_loss=", result.get("casualty_total_loss"), " reason=", result.get("total_loss_reason"), " retry=", result.get("campaign_checkpoint_retry_required"), " loss=", result.get("craft_loss"), " roster=", Array(_flow.get("_all_team_units")).size(), " fleet=", _fleet_ids(), " fatal=", result.get("fatality_unit_ids"), " respawn=", result.get("respawn_unit_ids"), " limit=", result.get("respawn_limit"), " casualties=", result.get("casualties"))
	_check(bool(result.get("casualty_total_loss", false)) and bool(result.get("campaign_checkpoint_retry_required", false)), "W1a: Totalverlust mit Ruecksprung statt halb bereinigtem Kader")
	_check(not result.has("craft_loss"), "W1a: kein Schiffsverlust gebucht (Rueckfall auf den Stand vor dem Einsatz)")
	_check(not _roster_unit(LEADER).is_empty() and not _roster_unit(PILOT).is_empty(), "W1a: Anfuehrer und Pilot stehen weiter im Kader")
	if not await _press_continue(): return
	_check(_fleet_ids() == [_craft_id], "W1a: nach dem Ruecksprung ist das Schiff wieder da (%s)" % str(_fleet_ids()))
	_check(_credits() == 100, "W1a: Strafe wie beim Totalverlust, 500 -> 100 Credits (%d)" % _credits())
	var saved: Dictionary = {}
	await _wait(func():
		saved.clear()
		saved.merge(Dictionary(_flow.call("request_campaign_save")))
		return bool(saved.get("ok", false)), 60000, "W1a: Speichern nach dem Ruecksprung gelingt")
	await _close()
	if not await _open_scene("campaign", "continue_home"): return
	_check(_fleet_ids() == [_craft_id] and _credits() == 100 and not _roster_unit(LEADER).is_empty(), "W1a: Laden: Schiff, 100 Credits und Anfuehrer sind da (%s / %d)" % [str(_fleet_ids()), _credits()])
	await _close()
