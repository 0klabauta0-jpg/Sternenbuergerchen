extends "res://scripts/tests/campaign_craft_loss_second_verifier.gd"
## LC2i I2 + I3 (echter Kampagnenfluss, Muster campaign_craft_loss_second_verifier).
## I2: Das Einsatzende kommt, waehrend der Spieler NICHT in der Einsatzansicht ist (Hintergrund-Ende an der Ortsinstanz) und ein Schiff ist verloren:
##     die Instanz ist danach freigegeben (_active_mission leer) und das Speichern scheitert nicht mit away_from_checkpoint.
## I3b: Einsatzschiff verloren (Notrettung), ein zweites Schiff ist ebenfalls abgestuerzt, ein Ueberlebender liegt an dessen Absturzstelle:
##      er wird mit der Notrettung heimgeholt (lebt), die Gebuehr steht einmal, niemand steht an Bord eines verlorenen Schiffs.
## I3c: Basisseite: wer am verlorenen zweiten Schiff "an Bord" stand, steht danach draussen an der Basis; wer im Einsatzschiff steht, bleibt unberuehrt
##      (niemand wird doppelt heimgebracht).

func _run() -> void:
	_configure_entry()
	await _i3b_survivor_at_second_crash_site()
	await _i3c_base_side_second_craft()
	await _i2_background_end_releases_instance()
	print("CAMPAIGN_CRAFT_LOSS_CREW passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _i3b_survivor_at_second_crash_site() -> void:
	var s: Dictionary = await _begin_funded_sortie(500)
	if s.is_empty(): return
	var second := _inject_bought_ship()
	var third := _inject_bought_ship("2", "Drittschiff")
	_site(s, second)
	var site: Dictionary = Dictionary(Array(s.simulation.get("_air_crash_sites")).back())
	# Der Truppfuehrer sass im zweiten Schiff und liegt schwer verletzt an dessen Absturzstelle (wie nach dem echten Absturz).
	var applied: Dictionary = Dictionary(s.controller.call("apply_air_crash", second, site, {LEADER: {"state": "severe"}}, [LEADER]))
	print("I3B_APPLY ", applied, " vital=", s.leader.call("get_vital_state"))
	_site(s, _craft_id)
	s.driver.call("_resolve_combat", "aborted", "", "evacuation")
	if not await _wait_released("I3b: Einsatz wird freigegeben"): return
	var result: Dictionary = Dictionary(_flow.get("_last_mission_result"))
	var loss: Dictionary = Dictionary(result.get("craft_loss", {}))
	print("I3B_RESULT total_loss=", result.get("casualty_total_loss"), " reason=", result.get("total_loss_reason"), " fatal=", result.get("fatality_unit_ids"), " respawn=", result.get("respawn_unit_ids"), " loss=", loss, " fate=", _unit_fate(LEADER))
	_check(not bool(result.get("casualty_total_loss", false)) and int(loss.get("rescue_fee", -1)) == 400 and _credits() == 100, "I3b: Notrettung 400, einmal gebucht, kein Totalverlust (%s / %d)" % [str(loss), _credits()])
	_check(not _unit_is_dead(LEADER) and not PackedStringArray(result.get("fatality_unit_ids", PackedStringArray())).has(LEADER), "I3b: der Truppfuehrer an der Absturzstelle des zweiten Schiffs wird heimgeholt und lebt (%s)" % _unit_fate(LEADER))
	_check(not PackedStringArray(result.get("respawn_unit_ids", PackedStringArray())).has(LEADER), "I3b: er bleibt nicht als Zurueckgelassener liegen")
	_check(_fleet_ids() == [third], "I3b: beide verlorenen Schiffe sind geraeumt, die Reserve bleibt (%s)" % str(_fleet_ids()))
	_check(_aboard_ids(second).is_empty() and _aboard_ids(_craft_id).is_empty(), "I3b: niemand steht an Bord eines Schiffs, das es nicht mehr gibt")
	await _end_sortie()

func _i3c_base_side_second_craft() -> void:
	START.request_start(self, "campaign", "new")
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	await process_frame
	_runtime = _flow.get("_singleplayer_runtime")
	if not _check(_runtime != null, "I3c: Aufbau: Meta-Szene und Laufzeit"): return
	var second := _inject_bought_ship()
	var states: Dictionary = _runtime.call("get_base_personnel_runtime").get("_states")
	states[LEADER]["status"] = "aboard"
	states[LEADER]["craft_id"] = second
	states[PILOT]["status"] = "aboard"
	states[PILOT]["craft_id"] = _craft_id
	_flow.call("_retire_lost_craft", {"craft_id": second, "ship_name": "Zweitschiff", "outcome": "crash", "rescue_fee": 0})
	var rescued: Array = Array(Dictionary(_flow.get_meta("campaign_lost_craft_rescue_result", {})).get("rescued", []))
	_check(rescued == [LEADER], "I3c: nur wer am verlorenen Schiff stand, wird heimgeholt (%s)" % str(rescued))
	_check(String(states[LEADER].get("craft_id", "x")).is_empty() and String(states[LEADER].get("status", "")) != "aboard", "I3c: der Truppfuehrer steht nicht mehr an Bord des verlorenen Schiffs (%s / %s)" % [str(states[LEADER].get("status")), str(states[LEADER].get("craft_id"))])
	_check(String(states[PILOT].get("craft_id", "")) == _craft_id and String(states[PILOT].get("status", "")) == "aboard", "I3c: wer im Einsatzschiff steht, bleibt unberuehrt (kein Doppelzugriff)")
	await _close()

func _i2_background_end_releases_instance() -> void:
	var s: Dictionary = await _begin_funded_sortie(500)
	if s.is_empty(): return
	var second := _inject_bought_ship()
	_site(s, _craft_id)
	# Der Spieler schaut nicht auf den Einsatz, wenn er endet (Hintergrund-Ende der Ortsinstanz).
	_flow.set("_current_meta_view", "homebase")
	s.driver.call("_resolve_combat", "aborted", "", "evacuation")
	var released: bool = await _wait(func(): return _flow.get("_active_mission") == null, 15000, "I2: die Ortsinstanz ist nach dem Hintergrund-Ende freigegeben (_active_mission leer)")
	print("I2_STATE released=", released, " active=", _flow.get("_active_mission"), " view=", _flow.get("_current_meta_view"), " fleet=", _fleet_ids())
	_check(_fleet_ids() == [second], "I2: Aufbau: das Einsatzschiff ist verloren, das zweite bleibt (%s)" % str(_fleet_ids()))
	var saved: Dictionary = {}
	var saved_ok: bool = await _wait(func():
		saved.clear()
		saved.merge(Dictionary(_flow.call("request_campaign_save")))
		return bool(saved.get("ok", false)), 60000, "I2: Speichern gelingt nach dem Schiffsverlust (nicht away_from_checkpoint)")
	if not saved_ok: print("I2_SAVE_LAST ", saved)
	await _close()
