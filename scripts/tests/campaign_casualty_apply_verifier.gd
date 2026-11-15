extends "res://scripts/tests/campaign_casualty_boarding_verifier.gd"
## Task 5a (Ausfall und Rueckzug): Verluste am Missionsende genau einmal anwenden.
## Ende-zu-Ende mit echtem Kampagneneinsatz (A leicht verwundet, B/C Totalverlust),
## danach direkt mit einem Kader aus vier Personen, am Ende die Skirmish-Gegenprobe.
## Aufbau wie campaign_casualty_boarding_verifier / campaign_casualty_debrief_retry_test.

func _run() -> void:
	_configure_entry()
	await _sortie_a_light_wound()
	await _sortie_b_ground_team_down()
	await _sortie_c_pilot_down()
	await _direct_part()
	await _skirmish_part_apply()
	print("CAMPAIGN_CASUALTY_APPLY passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

## Kampagnenstart bis zum gelandeten Einsatz; leeres Dictionary bei Misserfolg.
func _begin_sortie() -> Dictionary:
	START.request_start(self, "campaign", "new")
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	if not await _prepare_initial_base(): return {}
	_crew_ids = ["campaign_leader"]
	_pilot_id = "campaign_pilot"
	_check(_screen.call("request_operation", "accept_job", {"job_id": "satellite_recovery"}).get("ok", false), "Accept actual job")
	_check(_screen.call("request_operation", "select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"}).get("ok", false), "Choose actual location")
	if not await _launch_and_land("satellite_recovery", "res://maps/satellite_crash_site.json"): return {}
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	var sortie: Dictionary = {
		"mission": mission,
		"controller": controller,
		"driver": mission.get_node("CombatLoopDriver"),
		"simulation": mission.get_node("SimulationRoot"),
		"leader": controller.call("_get_campaign_sortie_unit", "campaign_leader"),
		"pilot": controller.call("_get_campaign_sortie_unit", "campaign_pilot"),
		"access": controller.call("get_campaign_ground_ship_access", _craft_id),
	}
	if not _check(sortie.leader != null and sortie.pilot != null and bool(sortie.access.get("ok", false)), "Beide Personen und der Schiffszugang sind da"): return {}
	return sortie

func _end_sortie() -> void:
	if _flow != null and is_instance_valid(_flow):
		_flow.queue_free()
	await process_frame

func _roster_unit(unit_id: String) -> Dictionary:
	for unit: Dictionary in Array(_flow.get("_all_team_units")):
		if String(unit.get("unit_id", "")) == unit_id:
			return unit
	return {}

func _casualty_entry(result: Dictionary, unit_id: String) -> Dictionary:
	for entry: Dictionary in Array(result.get("casualties", [])):
		if String(entry.get("unit_id", "")) == unit_id:
			return entry
	return {}

func _wait_released(label: String) -> bool:
	return await _wait(func(): return _flow.get("_active_mission") == null, 30000, label)

func _sortie_a_light_wound() -> void:
	var s: Dictionary = await _begin_sortie()
	if s.is_empty(): return
	var leader: Node2D = s.leader
	var driver: Node = s.driver
	leader.call("apply_damage", 10000)
	if not await _wait(func(): return bool(Dictionary(driver.call("get_casualty_flags")).get("campaign_leader", {}).get("was_downed", false)), 5000, "A: Treiber merkt sich die ausgefallene Person"): return
	_check(String(leader.call("get_vital_state")) != "fit", "A: Truppfuehrer liegt")
	_check(bool(leader.call("apply_heal", 10, {})) and String(leader.call("get_vital_state")) == "fit", "A: innerhalb der Frist aufgerichtet, wieder einsatzfaehig")
	if not _place_at(s.simulation, s.access, "campaign_leader", Vector2.ZERO): return
	if not _place_at(s.simulation, s.access, "campaign_pilot", Vector2.ZERO): return
	driver.call("_resolve_combat", "aborted", "", "evacuation")
	if not await _wait_released("A: Einsatz wird freigegeben"): return
	var result: Dictionary = _flow.get("_last_mission_result")
	print("APPLY_A_RESULT outcome=", result.get("mission_outcome"), " casualties=", result.get("casualties"), " fatal=", result.get("fatality_unit_ids"), " total_loss=", result.get("casualty_total_loss"))
	_check(String(result.get("mission_outcome", "")) == "aborted", "A: Ergebnis bleibt aborted")
	_check(not bool(result.get("campaign_checkpoint_retry_required", false)), "A: kein Checkpoint-Retry")
	_check(result.has("casualty_total_loss") and not bool(result.get("casualty_total_loss", true)), "A: kein Totalverlust")
	var entry: Dictionary = _casualty_entry(result, "campaign_leader")
	_check(String(entry.get("severity", "")) == "light" and String(entry.get("outcome", "")) == "wounded", "A: Truppfuehrer steht als leicht verwundet in casualties")
	_check(not String(entry.get("display_name", "")).is_empty(), "A: casualties-Eintrag traegt display_name")
	_check(Array(result.get("casualties", [])).size() == 1, "A: genau ein casualties-Eintrag")
	_check(PackedStringArray(result.get("fatality_unit_ids", PackedStringArray(["x"]))).is_empty(), "A: keine Toten gemeldet")
	var unit: Dictionary = _roster_unit("campaign_leader")
	var recovery: Dictionary = Dictionary(unit.get("recovery_state", {}))
	_check(String(unit.get("availability_status", "")) == "wounded" and String(unit.get("status_text", "")) == "wounded", "A: Kader: availability_status und status_text sind wounded")
	_check(String(recovery.get("severity", "")) == "light" and is_equal_approx(float(recovery.get("seconds_remaining", -1.0)), 180.0), "A: Kader: recovery_state light, 180 s")
	_check(String(_roster_unit("campaign_pilot").get("availability_status", "")) != "wounded", "A: unversehrter Pilot ist nicht verwundet")
	# Einmaligkeit: dasselbe Ergebnis erneut zugestellt (wie der 0,25-s-Wiederholer).
	var roster_before: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	var last_before: Dictionary = result.duplicate(true)
	_flow.call("_on_mission_combat_resolved", {"result": "victory", "mission_outcome": "won"})
	_flow.call("_on_mission_combat_resolved", {"result": "victory", "mission_outcome": "won"})
	await process_frame
	_check(Array(_flow.get("_all_team_units")) == roster_before, "A: zweite und dritte Zustellung aendern den Kader nicht")
	_check(is_equal_approx(float(Dictionary(_roster_unit("campaign_leader").get("recovery_state", {})).get("seconds_remaining", -1.0)), 180.0), "A: seconds_remaining bleibt 180.0")
	_check(Dictionary(_flow.get("_last_mission_result")) == last_before, "A: Ergebnis fuer den Debrief bleibt unveraendert")
	# Zaehlt die Restzeit herunter, darf eine spaete Zustellung sie nicht zuruecksetzen.
	var ticked: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	for ticked_unit: Dictionary in ticked:
		if String(ticked_unit.get("unit_id", "")) == "campaign_leader":
			ticked_unit["recovery_state"]["seconds_remaining"] = 150.0
	_flow.call("_replace_roster_units", ticked)
	_flow.call("_on_mission_combat_resolved", {"result": "victory", "mission_outcome": "won"})
	await process_frame
	_check(is_equal_approx(float(Dictionary(_roster_unit("campaign_leader").get("recovery_state", {})).get("seconds_remaining", -1.0)), 150.0), "A: spaete Zustellung setzt die Restzeit nicht zurueck")
	await _end_sortie()

func _sortie_b_ground_team_down() -> void:
	var s: Dictionary = await _begin_sortie()
	if s.is_empty(): return
	var leader: Node2D = s.leader
	var driver: Node = s.driver
	leader.call("apply_damage", 10000)
	if not await _wait(func(): return bool(Dictionary(driver.call("get_casualty_flags")).get("campaign_leader", {}).get("was_downed", false)), 5000, "B: Treiber merkt sich die ausgefallene Person"): return
	if not _place_at(s.simulation, s.access, "campaign_leader", Vector2.ZERO): return
	if not _place_at(s.simulation, s.access, "campaign_pilot", Vector2.ZERO): return
	# Irrefuehrende Weltposition: near_ship muss aus dem Hex-Zustand kommen.
	leader.global_position = Vector2(s.access.position) + Vector2(5000.0, 0.0)
	var probe: Dictionary = _flow.call("_build_mission_result", s.mission, {})
	var probe_entry: Dictionary = {}
	for state: Dictionary in Array(probe.get("team_states", [])):
		if String(state.get("unit_id", "")) == "campaign_leader":
			probe_entry = state
	var hex_state: Dictionary = s.simulation.call("get_hex_unit_state", "campaign_leader")
	var access_now: Dictionary = s.controller.call("get_campaign_ground_ship_access", _craft_id)
	print("APPLY_5A hex_state_empty=", hex_state.is_empty(), " ship_access_ok=", access_now.get("ok"), " leader_vital=", leader.call("get_vital_state"), " near_ship=", probe_entry.get("near_ship"), " was_downed=", probe_entry.get("was_downed"))
	_check(not hex_state.is_empty(), "B (5a): Hex-Zustand der ausgefallenen Bodenperson bleibt erhalten")
	_check(bool(access_now.get("ok", false)), "B (5b): Schiffszugang ist am Missionsende bekannt")
	_check(bool(probe_entry.get("near_ship", false)) and bool(probe_entry.get("was_downed", false)), "B (5a/5b): near_ship und was_downed stimmen fuer die Liegende")
	driver.call("_resolve_combat", "aborted", "", "evacuation")
	if not await _wait_released("B: Einsatz wird freigegeben"): return
	var result: Dictionary = _flow.get("_last_mission_result")
	print("APPLY_B_RESULT result=", result.get("result"), " reason=", result.get("total_loss_reason"), " total_loss=", result.get("casualty_total_loss"), " retry=", result.get("campaign_checkpoint_retry_required"))
	_check(bool(result.get("casualty_total_loss", false)) and String(result.get("total_loss_reason", "")) == "ground_team_down", "B: Totalverlust, Grund ground_team_down")
	_check(String(result.get("result", "")) == "defeat" and bool(result.get("campaign_checkpoint_retry_required", false)), "B: Ergebnis defeat mit Checkpoint-Retry wie bisher")
	_check(String(_flow.get("_current_meta_view")) == "debrief", "B: Debrief ist sichtbar")
	_check(not result.has("casualties") or Array(result.get("casualties", [])).is_empty(), "B: keine Verwundeten gemeldet")
	for unit: Dictionary in Array(_flow.get("_all_team_units")):
		_check(String(unit.get("availability_status", "")) != "wounded", "B: %s ist nicht wounded" % unit.get("unit_id"))
	await _end_sortie()

func _sortie_c_pilot_down() -> void:
	var s: Dictionary = await _begin_sortie()
	if s.is_empty(): return
	var driver: Node = s.driver
	s.pilot.call("apply_damage", 10000)
	if not await _wait(func(): return bool(Dictionary(driver.call("get_casualty_flags")).get("campaign_pilot", {}).get("was_downed", false)), 5000, "C: Treiber merkt sich den ausgefallenen Piloten"): return
	driver.call("_resolve_combat", "aborted", "", "evacuation")
	if not await _wait_released("C: Einsatz wird freigegeben"): return
	var result: Dictionary = _flow.get("_last_mission_result")
	print("APPLY_C_RESULT result=", result.get("result"), " reason=", result.get("total_loss_reason"), " total_loss=", result.get("casualty_total_loss"))
	_check(bool(result.get("casualty_total_loss", false)) and String(result.get("total_loss_reason", "")) == "pilot_down", "C: Totalverlust, Grund pilot_down")
	_check(String(result.get("result", "")) == "defeat" and bool(result.get("campaign_checkpoint_retry_required", false)), "C: Ergebnis defeat mit Checkpoint-Retry")
	for unit: Dictionary in Array(_flow.get("_all_team_units")):
		_check(String(unit.get("availability_status", "")) != "wounded", "C: %s ist nicht wounded" % unit.get("unit_id"))
	await _end_sortie()

func _four_units() -> Array:
	var units: Array = []
	for spec: Array in [["t_pilot", "Pia Pilot", 0.0, 60.0], ["t_leader", "Lena Leiter", 50.0, 0.0], ["t_c", "Carl Cobalt", 0.0, 0.0], ["t_d", "Dora Dunkel", 0.0, 0.0]]:
		units.append({"unit_id": spec[0], "display_name": spec[1], "roster_role_category": "operator", "skill_leadership": spec[2], "dropship_piloting": spec[3], "availability_status": "active", "status_text": "active"})
	return units

func _state(unit_id: String, vital: String, near_ship: bool, was_downed: bool = false) -> Dictionary:
	var fit: bool = vital == "fit"
	return {"unit_id": unit_id, "display_name": unit_id, "vital_state": vital, "health_points": 50 if fit else 0, "was_downed": was_downed, "near_ship": near_ship, "aboard": false}

func _built_result(states: Array, outcome: String) -> Dictionary:
	var rules: Dictionary = CASUALTY_RULES.load_rules()
	var resolved: Dictionary = CASUALTY_RULES.resolve_mission(states, outcome, _four_units(), "t_pilot", rules)
	return {"mission_outcome": outcome, "result": "victory" if outcome == "won" else outcome, "team_states": states, "casualties": resolved.casualties, "fatality_unit_ids": resolved.fatality_unit_ids, "casualty_total_loss": resolved.total_loss}

func _set_roster() -> void:
	_flow.set("_all_team_units", _four_units())
	_flow.set("_available_team_units", _four_units())

func _direct_part() -> void:
	START.request_start(self, "campaign", "new")
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	await process_frame
	_check(bool(_flow.call("is_campaign_start")), "Direkt: Kampagnenstart ist aktiv")
	# Sieg, eine liegende Bodenperson.
	_set_roster()
	var won: Dictionary = _built_result([_state("t_pilot", "fit", false), _state("t_leader", "fit", false), _state("t_c", "down", false)], "won")
	var applied: Dictionary = _flow.call("_apply_campaign_casualties", won)
	var c_unit: Dictionary = _roster_unit("t_c")
	_check(String(c_unit.get("availability_status", "")) == "wounded" and String(c_unit.get("status_text", "")) == "wounded", "Direkt Sieg: liegende Person ist wounded")
	_check(String(Dictionary(c_unit.get("recovery_state", {})).get("severity", "")) == "medium" and is_equal_approx(float(Dictionary(c_unit.get("recovery_state", {})).get("seconds_remaining", -1.0)), 900.0), "Direkt Sieg: medium, 900 s")
	_check(String(Dictionary(c_unit.get("recovery_state", {})).get("source", "")) == "campaign_casualty", "Direkt Sieg: recovery_state-Quelle campaign_casualty")
	_check(String(_roster_unit("t_leader").get("availability_status", "")) == "active", "Direkt Sieg: Unversehrte bleibt active")
	_check(String(_casualty_entry(applied, "t_c").get("display_name", "")) == "Carl Cobalt", "Direkt Sieg: casualties-Eintrag traegt display_name aus dem Kader")
	# Kritisch und geborgen (Rueckzug nahe am Schiff).
	_set_roster()
	var saved: Dictionary = _built_result([_state("t_pilot", "fit", false), _state("t_leader", "fit", false), _state("t_c", "bleedout", true)], "aborted")
	var applied_severe: Dictionary = _flow.call("_apply_campaign_casualties", saved)
	var severe: Dictionary = Dictionary(_roster_unit("t_c").get("recovery_state", {}))
	_check(String(severe.get("severity", "")) == "severe" and is_equal_approx(float(severe.get("seconds_remaining", -1.0)), 2400.0), "Direkt Rueckzug: kritisch und geborgen ist severe, 2400 s")
	_check(PackedStringArray(applied_severe.get("fatality_unit_ids", PackedStringArray())).is_empty(), "Direkt Rueckzug geborgen: keine Toten")
	# Rueckzug mit einer liegenden Person fern vom Schiff: gemeldet, Kader unveraendert.
	_set_roster()
	var roster_before: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	var fatal: Dictionary = _built_result([_state("t_pilot", "fit", false), _state("t_leader", "fit", false), _state("t_d", "down", false)], "aborted")
	var applied_fatal: Dictionary = _flow.call("_apply_campaign_casualties", fatal)
	_check(PackedStringArray(applied_fatal.get("fatality_unit_ids", PackedStringArray())) == PackedStringArray(["t_d"]), "Direkt Rueckzug fern: fatality_unit_ids == [t_d]")
	_check(Array(_flow.get("_all_team_units")) == roster_before, "Direkt Rueckzug fern: Kadereintrag der Toten (und alle anderen) unveraendert")
	_check(String(_casualty_entry(applied_fatal, "t_d").get("display_name", "")) == "Dora Dunkel" and String(_casualty_entry(applied_fatal, "t_d").get("outcome", "")) == "dead", "Direkt Rueckzug fern: Tote steht mit display_name in casualties")
	# Mehrfach angewendet bleibt gleich.
	var again: Dictionary = _flow.call("_apply_campaign_casualties", won)
	_flow.call("_apply_campaign_casualties", won)
	_check(Dictionary(_roster_unit("t_c").get("recovery_state", {})).get("seconds_remaining") == 900.0 and again.has("casualties"), "Direkt: erneutes Anwenden desselben Siegs setzt dieselbe Stufe")
	# Totalverlust-Ergebnis: niemand wird verwundet.
	_set_roster()
	var loss: Dictionary = _built_result([_state("t_pilot", "down", false), _state("t_leader", "fit", false), _state("t_c", "down", true)], "aborted")
	_check(bool(loss.casualty_total_loss), "Direkt Totalverlust: Fixture ist ein Totalverlust")
	var roster_loss: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	_flow.call("_apply_campaign_casualties", loss)
	_check(Array(_flow.get("_all_team_units")) == roster_loss, "Direkt Totalverlust: niemand wird verwundet")
	# Ungueltige Regeln: Ergebnis und Kader unveraendert.
	_set_roster()
	_flow.set("_campaign_casualty_rules", {})
	_flow.set("_campaign_casualty_rules_loaded", true)
	var invalid_in: Dictionary = _built_result([_state("t_pilot", "fit", false), _state("t_leader", "fit", false), _state("t_c", "down", false)], "won")
	var invalid_out: Dictionary = _flow.call("_apply_campaign_casualties", invalid_in)
	_check(invalid_out == invalid_in and String(_roster_unit("t_c").get("availability_status", "")) == "active", "Direkt ungueltige Regeln: Ergebnis und Kader unveraendert")
	_flow.set("_campaign_casualty_rules_loaded", false)
	await _end_sortie()

func _skirmish_part_apply() -> void:
	START.request_start(self, "skirmish", "new")
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	await process_frame
	_flow.call("_start_mission")
	var mission: Node = _flow.get("_active_mission")
	if not _check(mission != null, "Skirmish: Einsatz wird gestartet"): return
	await process_frame
	var fake: Dictionary = {"mission_outcome": "won", "casualties": [{"unit_id": "x", "outcome": "wounded", "severity": "light"}], "team_states": []}
	_check(Dictionary(_flow.call("_apply_campaign_casualties", fake)) == fake, "Skirmish: _apply_campaign_casualties gibt das Ergebnis unveraendert zurueck")
	mission.get_node("CombatLoopDriver").call("_resolve_combat", "defeat", "enemy")
	if not await _wait_released("Skirmish: Einsatz wird freigegeben"): return
	var result: Dictionary = _flow.get("_last_mission_result")
	_check(not result.is_empty() and not result.has("casualties") and not result.has("casualty_total_loss") and not result.has("fatality_unit_ids"), "Skirmish: Ergebnis ohne Felder casualties/casualty_total_loss/fatality_unit_ids")
	for unit: Dictionary in Array(_flow.get("_all_team_units")):
		_check(String(unit.get("availability_status", "")) != "wounded", "Skirmish: %s ist nicht wounded" % unit.get("unit_id"))
	await _end_sortie()
