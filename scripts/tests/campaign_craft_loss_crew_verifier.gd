extends "res://scripts/tests/campaign_craft_loss_second_verifier.gd"
## LC2i I2 + I3 (echter Kampagnenfluss, Muster campaign_craft_loss_second_verifier).
## I2: Das Einsatzende kommt, waehrend der Spieler NICHT in der Einsatzansicht ist (Hintergrund-Ende an der Ortsinstanz) und ein Schiff ist verloren:
##     die Instanz ist danach freigegeben (_active_mission leer) und das Speichern scheitert nicht mit away_from_checkpoint.
## I3b: Einsatzschiff verloren (Notrettung), ein zweites Schiff ist ebenfalls abgestuerzt, ein Ueberlebender liegt an dessen Absturzstelle:
##      er wird mit der Notrettung heimgeholt (lebt), die Gebuehr steht einmal, niemand steht an Bord eines verlorenen Schiffs.
## K2a-c (LC2k, Regelaenderung): Insassen eines verlorenen zweiten Schiffs: an Bord eines heimkehrenden Schiffs = heim ohne Gebuehr; an der Absturzstelle
##      geblieben (lebend) = Notrettung mit Gebuehr (einmal je Einsatz, auch bei zugleich verlorenem Einsatzschiff). Loest "kostenlos heim" aus I3 ab.
## I3c: Basisseite: wer am verlorenen zweiten Schiff "an Bord" stand, steht danach draussen an der Basis; wer im Einsatzschiff steht, bleibt unberuehrt
##      (niemand wird doppelt heimgebracht).

const DEBRIEF_SCRIPT = preload("res://scripts/meta/debrief_screen.gd")

func _run() -> void:
	_configure_entry()
	# Umgebungsvariable CREW_ONLY (z. B. "k2b") fuehrt nur diesen Teil aus (kurze Suchlaeufe); ohne sie laufen alle.
	var only := OS.get_environment("CREW_ONLY")
	if only.is_empty():
		await _i3b_survivor_at_second_crash_site()
		await _i3c_base_side_second_craft()
	if only.is_empty() or only == "k2a": await _k2a_aboard_returning_craft()
	if only.is_empty() or only == "k2b": await _k2b_left_at_crash_site()
	if only.is_empty() or only == "k2c": await _k2c_both_lost()
	if only.is_empty(): await _i2_background_end_releases_instance()
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

## LC2k K2 (Regelaenderung gegenueber LC2i I3: Insassen eines verlorenen zweiten Schiffs kommen nicht mehr kostenlos heim, wenn sie nicht an Bord
## eines heimkehrenden Schiffs sind). Echter Einsatz, echtes Einsatzende; GESTELLT ist nur die Basisseite: der Truppfuehrer wird vor dem Einsatz
## als "an Bord des zweiten Schiffs" gefuehrt (wie I3c), und in (b) liegt er per apply_air_crash schwer verletzt an dessen Absturzstelle.
func _k2_prepare(s: Dictionary, second: String) -> void:
	var states: Dictionary = _runtime.call("get_base_personnel_runtime").get("_states")
	states[LEADER]["status"] = "aboard"
	states[LEADER]["craft_id"] = second

func _outcome_of(resolution: Dictionary, unit_id: String) -> String:
	for entry in Array(resolution.get("casualties", [])):
		if String(Dictionary(entry).get("unit_id", "")) == unit_id: return String(Dictionary(entry).get("outcome", ""))
	return ""

func _loss_lines(result: Dictionary) -> int:
	return DEBRIEF_SCRIPT.build_craft_loss_text(result).count("Notrettung:")

## (a) Das zweite Schiff ist verloren, der Truppfuehrer geht an Bord des Einsatzschiffs: heim ohne Gebuehr.
func _k2a_aboard_returning_craft() -> void:
	var s: Dictionary = await _begin_funded_sortie(500)
	if s.is_empty(): return
	var second := _inject_bought_ship()
	_k2_prepare(s, second)
	_site(s, second)
	if not _seat_crew(s): return
	s.driver.call("_resolve_combat", "aborted", "", "evacuation")
	if not await _wait_released("K2a: Einsatz wird freigegeben"): return
	var result: Dictionary = Dictionary(_flow.get("_last_mission_result"))
	_check(not result.has("craft_loss") and _credits() == 500 and _loss_lines(result) == 0, "K2a: an Bord des Einsatzschiffs: keine Gebuehr (%d, Zeilen %d)" % [_credits(), _loss_lines(result)])
	_check(not _unit_is_dead(LEADER) and _aboard_ids(second).is_empty() and _fleet_ids() == [_craft_id], "K2a: der Truppfuehrer lebt, niemand an Bord des verlorenen Schiffs (%s / %s)" % [_unit_fate(LEADER), str(_fleet_ids())])
	await _end_sortie()

## (b) Das zweite Schiff ist verloren, der Truppfuehrer bleibt schwer verletzt an der Absturzstelle: die Notrettung holt ihn heim, Gebuehr einmal.
func _k2b_left_at_crash_site() -> void:
	var s: Dictionary = await _begin_funded_sortie(500)
	if s.is_empty(): return
	var second := _inject_bought_ship()
	_k2_prepare(s, second)
	# GESTELLT: Mit nur zwei Mitfliegenden (Truppfuehrer, Pilot) laesst sich "einer bleibt lebend an der Absturzstelle, das Einsatzschiff fliegt heim" im
	# echten Einsatz nicht herstellen (bleibt der Truppfuehrer liegen, ist es schon der bestehende Totalverlust "ground_team_down": kein fitter
	# Bodenmann). Darum werden hier die drei Bausteine auf dem echten Fluss (laufender Einsatz, echte Basisseite, echtes Guthaben) einzeln gefahren:
	var team_states: Array = [
		{"unit_id": PILOT, "vital_state": "fit", "health_points": 1.0, "aboard": true},
		{"unit_id": LEADER, "vital_state": "down", "health_points": 0.2, "aboard": false},
		{"unit_id": "k2_gunner", "vital_state": "fit", "health_points": 1.0, "aboard": true}]
	var occupants: Array = _flow.call("_lost_craft_occupant_ids", [{"craft_id": second}])
	_check(occupants == [LEADER], "K2b: Insassen des verlorenen Schiffs laut Basisseite (%s)" % str(occupants))
	var stranded: Array = _flow.call("_stranded_lost_craft_occupants", team_states, occupants)
	_check(stranded == [LEADER], "K2b: der liegende Truppfuehrer ist nicht an Bord eines heimkehrenden Schiffs (%s)" % str(stranded))
	var aboard_state: Array = team_states.duplicate(true)
	aboard_state[1]["aboard"] = true
	var dead_state: Array = team_states.duplicate(true)
	dead_state[1]["killed_in_crash"] = true
	_check(Array(_flow.call("_stranded_lost_craft_occupants", aboard_state, occupants)).is_empty() and Array(_flow.call("_stranded_lost_craft_occupants", dead_state, occupants)).is_empty(), "K2b: wer an Bord ist oder beim Absturz starb, zaehlt nicht")
	var rules: Dictionary = _flow.call("_get_campaign_casualty_rules")
	var roster: Array = Array(_flow.get("_all_team_units"))
	var plain: Dictionary = CASUALTY_RULES.resolve_mission(team_states, "aborted", roster, PILOT, rules, {})
	var rescued: Dictionary = CASUALTY_RULES.resolve_mission(team_states, "aborted", roster, PILOT, rules, {"rescued_unit_ids": stranded})
	print("K2B_RULES plain_total=", plain.get("total_loss"), " ", plain.get("total_loss_reason"), " rescued_total=", rescued.get("total_loss"), " ", rescued.get("total_loss_reason"), " roster=", roster.size())
	# Gegenprobe (alte Regel): ohne Notrettung bleibt der Liegende zurueck und stirbt; im Kader mit nur zwei Leuten ist das der Totalverlust (kein Anfuehrer mehr).
	_check(bool(plain.get("total_loss", false)) and String(plain.get("total_loss_reason", "")) == "no_leader_left", "K2b: ohne Notrettung bleibt der Liegende zurueck (alte Regel, Gegenprobe: %s / %s)" % [str(plain.get("total_loss")), str(plain.get("total_loss_reason"))])
	_check(not bool(rescued.get("total_loss", true)), "K2b: mit Notrettung kein Totalverlust")
	_check(_outcome_of(rescued, LEADER) == "wounded", "K2b: mit Notrettung wird der Liegende heimgeholt (verwundet, nicht tot: %s)" % _outcome_of(rescued, LEADER))
	var others: Array = [{"craft_id": second, "ship_name": "Zweitschiff", "outcome": "crash", "rescue_fee": 0}]
	_flow.call("_book_stranded_rescue_fee", {"team_states": team_states}, rules, others)
	_check(int(Dictionary(others[0]).get("rescue_fee", -1)) == 400 and _credits() == 100, "K2b: Notrettung 400 einmal gebucht, 500 -> 100 (%s / %d)" % [str(others), _credits()])
	var text: String = DEBRIEF_SCRIPT.build_craft_loss_text({"other_craft_losses": others})
	_check(text.count("Notrettung:") == 1 and text.contains("Schiff verloren: Zweitschiff\nNotrettung: −400 Credits"), "K2b: die Nachbesprechung nennt \"Notrettung: −400 Credits\" einmal (%s)" % text.replace("\n", " | "))
	await _end_sortie()

## (c) Beide Schiffe verloren (das Einsatzschiff und das zweite, ein drittes bleibt), der Truppfuehrer liegt an der zweiten Absturzstelle: Gebuehr genau einmal.
func _k2c_both_lost() -> void:
	var s: Dictionary = await _begin_funded_sortie(500)
	if s.is_empty(): return
	var second := _inject_bought_ship()
	var third := _inject_bought_ship("2", "Drittschiff")
	_k2_prepare(s, second)
	_site(s, second)
	var site: Dictionary = Dictionary(Array(s.simulation.get("_air_crash_sites")).back())
	s.controller.call("apply_air_crash", second, site, {LEADER: {"state": "severe"}}, [LEADER])
	_site(s, _craft_id)
	s.driver.call("_resolve_combat", "aborted", "", "evacuation")
	if not await _wait_released("K2c: Einsatz wird freigegeben"): return
	var result: Dictionary = Dictionary(_flow.get("_last_mission_result"))
	var loss: Dictionary = Dictionary(result.get("craft_loss", {}))
	_check(int(loss.get("rescue_fee", -1)) == 400 and _credits() == 100 and _loss_lines(result) == 1, "K2c: Gebuehr genau einmal (%s / %d / Zeilen %d)" % [str(loss), _credits(), _loss_lines(result)])
	_check(_fleet_ids() == [third] and not _unit_is_dead(LEADER), "K2c: beide Schiffe geraeumt, die Reserve bleibt, der Truppfuehrer lebt (%s)" % str(_fleet_ids()))
	await _end_sortie()

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
