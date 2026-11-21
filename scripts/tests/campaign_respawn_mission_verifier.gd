extends "res://scripts/tests/campaign_respawn_apply_verifier.gd"
## R3 Fix-Runde 1: Befunde W1/M5 (geschuetzte Personen), W3/W6/W7 (echtes Missionsende, Basiszustand, Autosave); R4a: Szenario R4.
## Wie die anderen Respawn-Tests nur im Wegwerfprofil: ohne bestaetigtes Profil Abbruch mit Code 2, nichts geschrieben.
## P1 Pilot   P2 campaign_outpost_recruit   P3 campaign_rescue_pilot   P4 Anwerber   P5 Grenze 0 (Beobachtung)
## M1 echtes Missionsende mit Wiederkehrer (W3/W6)   M2 Grenze 0 am echten Ende
## W7 BEKANNTER MANGEL (wird in einem eigenen Abschnitt behoben, dann muss dieser Fall bewusst geaendert werden): Der Einsatzstand
##    lehnt Wartende neben der Besatzung ab (home_personnel_unsupported), Fortsetzen faellt auf den Heimstand zurueck.
## R4 (R4a): Wer im Trupp stirbt, steht nicht mehr im Trupp; der Trupp mit dem Gesunden laesst sich verladen (vorher: Zwischenzustand
##    "Person im Trupp, Trupp nicht verladbar, remove/assign = unit_busy").
## Abschlusszeile: CAMPAIGN_RESPAWN_MISSION passed=%d failed=%d

const MISSION_GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const PROTECTED_KEYS := ["final", "death_number", "respawn_state"]

func _run() -> void:
	var verdict: Dictionary = MISSION_GUARD.verdict_from_environment()
	if not bool(verdict.get("ok", false)):
		print("CAMPAIGN_RESPAWN_MISSION refused: needs a throwaway profile (SB_REVIEW2_USER_DIR), nothing written. Reason: %s" % str(verdict.get("reason", "")))
		quit(2)
		return
	_configure_entry()
	var initial_limit: int = RM_SETTINGS.load_campaign_respawn_limit()
	var selected: Array = []
	for arg: String in OS.get_cmdline_user_args():
		if not arg.strip_edges().is_empty():
			selected.append(arg.strip_edges().to_upper())
	for scenario: String in ["P1", "P2", "P3", "P4", "P5", "M1", "M2", "W7", "R4"]:
		if not selected.is_empty() and not selected.has(scenario):
			continue
		print("--- ", scenario)
		await call("_rm_" + scenario.to_lower())
		await _end_sortie()
	# Genau den Anfangswert der Grenze zurueckschreiben (nicht ein festes 3).
	_rm_set_limit(initial_limit)
	_check(RM_SETTINGS.load_campaign_respawn_limit() == initial_limit, "Ende: Einstellung steht wieder auf dem Anfangswert %d" % initial_limit)
	print("CAMPAIGN_RESPAWN_MISSION passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

const RM_SETTINGS = preload("res://scripts/ui/game_settings_contract.gd")

func _rm_set_limit(limit: int) -> void:
	var settings: Dictionary = RM_SETTINGS.load_settings()
	settings["campaign_respawn_limit"] = limit
	RM_SETTINGS.save_settings(settings)

## Macht eine Person zum Anwerber des Marktes ueber den oeffentlichen Weg (open mit dem Kader-Profil), nicht ueber ein privates Feld.
func _rm_make_recruiter(unit_id: String) -> bool:
	var opened: Dictionary = _runtime.get("_polisa_market").call("open", "r4a_recruiter_batch", _roster_unit(unit_id), {})
	return _check(bool(opened.get("ok", false)), "Aufbau: %s wird ueber PolisaRecruitmentMarket.open Anwerber (%s)" % [unit_id, opened.get("reason", "")])

## Echter Einsatz mit drei Personen: Truppfuehrer A, Pilot, und B (Truppfuehrer, ungeschuetzt) im selben Trupp.
func _rm_add_b() -> bool:
	var template: Dictionary = _roster_unit(LEAD_A).duplicate(true)
	if not _check(not template.is_empty(), "Aufbau: Truppfuehrer A ist im Kader"): return false
	var profile: Dictionary = template.duplicate(true)
	profile["unit_id"] = LEAD_B
	profile["display_name"] = NAME_B
	profile["fireteam_id"] = ""
	profile["roster_role_category"] = "operator"
	profile["role_name"] = "Fireteam Leader"
	var added: Dictionary = _flow.call("register_campaign_recruit", profile)
	if not _check(bool(added.get("ok", false)), "Aufbau: B kommt in den Kader (%s)" % [added]): return false
	var simulation: Node = _runtime.get("_simulation")
	simulation.call("request_personnel_loadout_command", "configure_roster", {"roster": [profile]})
	simulation.call("request_personnel_loadout_command", "set_loadout", {"unit_id": LEAD_B, "loadout": {"armor": "suit", "weapon_1": "pistol", "weapon_2": "medictool"}})
	_runtime.get("_supply").call("configure_inventory", [LEAD_B], [], true)
	if _rm_mode == "w7":
		# B ist schon einmal gestorben und wartet respawning auf Polisa; er gehoert zu keinem Trupp und fliegt nicht mit.
		var back: Dictionary = {"mission_outcome": "aborted", "result": "aborted", "casualty_total_loss": false, "fatality_unit_ids": PackedStringArray(), "respawn_unit_ids": PackedStringArray([LEAD_B]), "respawn_limit": 3, "team_states": [], "casualties": [{"unit_id": LEAD_B, "outcome": "dead", "final": false, "death_number": 1, "respawn_state": {"state": "respawning", "death_number": 1, "seconds_total": 3600, "seconds_remaining": 3600, "pickup_location_id": "polisa", "source": "left_behind"}}]}
		_flow.call("_apply_campaign_casualties", back)
		return _check(String(_roster_unit(LEAD_B).get("availability_status", "")) == "respawning", "Aufbau W7: B ist respawning")
	# Der Starttrupp (A, Pilot) liegt schon auf dem Schiff: B bekommt einen eigenen Trupp, der ebenfalls verladen wird.
	var known: Array = []
	for team: Dictionary in Array(Dictionary(_screen.call("get_operations_snapshot")).get("fireteams", [])):
		known.append(String(team.id))
	var added_team: Dictionary = _screen.call("request_operation", "add_fireteam", {})
	if not _check(bool(added_team.get("ok", false)), "Aufbau: zweiter Trupp (%s)" % [added_team]): return false
	for team: Dictionary in Array(Dictionary(_screen.call("get_operations_snapshot")).get("fireteams", [])):
		if not known.has(String(team.id)):
			_rm_team_b = String(team.id)
	var assigned: Dictionary = _screen.call("request_operation", "assign", {"unit_id": LEAD_B, "fireteam_id": _rm_team_b})
	if not _check(not _rm_team_b.is_empty() and bool(assigned.get("ok", false)), "Aufbau: B im zweiten Trupp (%s)" % [assigned]): return false
	return true

var _rm_team_b: String = ""

func _rm_aboard(ids: Array) -> bool:
	var personnel: Node = _runtime.call("get_base_personnel_runtime")
	var found: int = 0
	for person: Dictionary in Array(personnel.call("get_snapshot").get("units", [])):
		if ids.has(String(person.get("unit_id", ""))):
			if String(person.get("status", "")) != "aboard" or String(person.get("craft_id", "")) != _craft_id:
				return false
			found += 1
	return found == ids.size()

## Erst der Starttrupp (wie im Grundablauf), danach der Trupp von B: ein Schiff nimmt immer nur einen Trupp auf einmal auf.
func _board_actual_base_crew() -> bool:
	if _base_crew_ready():
		return true
	var first: Dictionary = _screen.call("request_operation", "base_board", {"craft_id": _craft_id, "fireteam_id": _team_id, "whole_fireteam": true})
	if not _check(bool(first.get("ok", false)), "Starttrupp geht an Bord (%s)" % [first]): return false
	if not await _wait(func(): return _rm_aboard([LEAD_A, PILOT_ID]), 60000, "A und Pilot sind an Bord"): return false
	if _rm_mode == "w7":
		var ready: bool = await _wait(_base_crew_ready, 15000, "A und Pilot sind an Bord, B wartet auf Polisa, die Nutzlast ist bereit")
		if not ready:
			var personnel: Node = _runtime.call("get_base_personnel_runtime")
			print("RM_W7_NOTREADY pilot_aboard=", personnel.call("is_pilot_aboard", _craft_id), " units=", personnel.call("get_snapshot").get("units", []).map(func(p): return [p.get("unit_id"), p.get("status"), p.get("craft_id")]), " payload=", _screen.call("_has_homebase_direct_launch_payload_for_craft", _craft_id))
		return ready
	var payload: Dictionary = _screen.call("request_operation", "board", {"craft_id": _craft_id, "fireteam_id": _rm_team_b})
	if not _check(bool(payload.get("ok", false)), "Trupp von B wird dem Schiff zugeteilt (%s)" % [payload]): return false
	var second: Dictionary = _screen.call("request_operation", "base_board", {"craft_id": _craft_id, "fireteam_id": _rm_team_b, "whole_fireteam": true})
	if not _check(bool(second.get("ok", false)), "Trupp von B geht an Bord (%s)" % [second]): return false
	return await _wait(_base_crew_ready, 60000, "Alle drei Personen sind an Bord und die Nutzlast ist bereit")

func _base_crew_ready() -> bool:
	var personnel: Node = _runtime.call("get_base_personnel_runtime")
	if personnel == null or not bool(personnel.call("is_pilot_aboard", _craft_id)):
		return false
	var people: Array = personnel.call("get_snapshot").get("units", [])
	if _rm_mode == "w7":
		var waiting: bool = _ra_base_status(LEAD_B) == "station"
		return waiting and _rm_aboard([LEAD_A, PILOT_ID]) and bool(_screen.call("_has_homebase_direct_launch_payload_for_craft", _craft_id))
	return people.size() == 3 and people.all(func(person: Dictionary): return String(person.status) == "aboard" and String(person.craft_id) == _craft_id) and bool(_screen.call("_has_homebase_direct_launch_payload_for_craft", _craft_id))

func _rm_begin_sortie() -> Dictionary:
	START.request_start(self, "campaign", "new")
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	if not _rm_add_b(): return {}
	if not await _prepare_initial_base(): return {}
	if _rm_mode == "w7":
		_crew_ids = [LEAD_A]
		# Wie im Spiel liegt der Heimstand mit B als Wartendem auf der Platte (der Einsatzstand vergleicht Kader und Ausruestung mit ihm).
		var home_saved: Dictionary = _flow.call("request_campaign_save")
		if not _check(bool(home_saved.get("ok", false)), "Aufbau W7: Heimstand mit B als Wartendem gespeichert (%s)" % [home_saved.get("reason", "")]): return {}
		_rm_w7_home_remaining = float(Dictionary(_roster_unit(LEAD_B).get("recovery_state", {})).get("seconds_remaining", -1.0))
	else:
		_crew_ids = [LEAD_A, LEAD_B]
	_pilot_id = PILOT_ID
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
		"leader": controller.call("_get_campaign_sortie_unit", LEAD_A),
		"pilot": controller.call("_get_campaign_sortie_unit", PILOT_ID),
		"b": controller.call("_get_campaign_sortie_unit", LEAD_B),
		"access": controller.call("get_campaign_ground_ship_access", _craft_id),
	}
	if _rm_mode == "w7":
		if not _check(sortie.leader != null and sortie.pilot != null and bool(sortie.access.get("ok", false)), "W7: A, Pilot und der Schiffszugang sind da"): return {}
		return sortie
	if not _check(sortie.leader != null and sortie.pilot != null and sortie.b != null and bool(sortie.access.get("ok", false)), "Drei Personen und der Schiffszugang sind da"): return {}
	return sortie

var _rm_mode: String = "three"

const RM_HOME_ORBIT := "moon_orbit"

## Wie der Heimflug in campaign_retreat_reopen_at_home_verifier: Orbit des Einsatzorts, Quantensprung zum Mondorbit, Landung zu Hause.
func _rm_return_home(location_id: String) -> bool:
	var orbit := String(Dictionary(_space().get("location_orbits", {})).get(location_id, ""))
	if not await _wait(func(): return String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == orbit, 120000, "Schiff erreicht den Orbit des Einsatzorts"): return false
	var jump: Dictionary = _screen.call("request_operation", "space_start_quantum", {"craft_id": _craft_id, "target_orbit_id": RM_HOME_ORBIT})
	if not _check(jump.get("ok", false), "Quantensprung zum Heimatorbit wird angenommen"): return false
	if not await _wait(func(): return String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == RM_HOME_ORBIT, 180000, "Schiff erreicht den Heimatorbit"): return false
	var land: Dictionary = _screen.call("request_operation", "space_land_homebase", {"craft_id": _craft_id})
	if not _check(land.get("ok", false), "Landung auf der Heimatbasis wird angenommen"): return false
	return await _wait(func():
		var ship: Dictionary = _craft(_flow.call("get_singleplayer_snapshot"))
		return String(ship.get("location_id", "")) == "homebase" and not bool(ship.get("busy", true)), 120000, "das Schiff ist wirklich zu Hause gelandet")

## B faellt aus und bleibt weit vom Schiff zurueck, A und der Pilot stehen am Einstieg; echtes Ende ueber den Driver.
## Rueckgabe: das Ergebnis aus _last_mission_result.
func _rm_real_end(s: Dictionary, tag: String, outcome: String) -> Dictionary:
	var driver: Node = s.driver
	s.b.call("apply_damage", 10000)
	if not await _wait(func(): return bool(Dictionary(driver.call("get_casualty_flags")).get(LEAD_B, {}).get("was_downed", false)), 5000, tag + ": Treiber merkt sich B als ausgefallen"): return {}
	if not _place_at(s.simulation, s.access, LEAD_A, Vector2.ZERO): return {}
	if not _place_at(s.simulation, s.access, PILOT_ID, Vector2.ZERO): return {}
	var far: bool = false
	for distance: float in [1200.0, 2400.0, 4800.0]:
		if not _place_at(s.simulation, s.access, LEAD_B, Vector2(distance, 0.0)): return {}
		var probe: Dictionary = _flow.call("_build_mission_result", s.mission, {})
		for state: Dictionary in Array(probe.get("team_states", [])):
			if String(state.get("unit_id", "")) == LEAD_B:
				far = not bool(state.get("near_ship", false)) and not bool(state.get("aboard", false))
		if far:
			print("RM_FAR %s distance=%s" % [tag, distance])
			break
	if not _check(far, tag + ": B steht ausserhalb der Reichweite des Schiffs"): return {}
	if outcome == "won":
		driver.call("_resolve_combat", "victory", String(driver.get("friendly_team_id")))
	elif outcome == "button":
		# Der Knopf Evakuieren (Treiber-Weg), der ueber _resolve_combat zum echten Ende fuehrt.
		var evacuation: Dictionary = driver.call("request_mission_evacuation")
		if not _check(bool(evacuation.get("accepted", false)), tag + ": Evakuieren wird angenommen (%s)" % [evacuation]): return {}
	else:
		driver.call("_resolve_combat", "aborted", "", "evacuation")
	if not await _wait_released(tag + ": Einsatz wird freigegeben"): return {}
	return _flow.get("_last_mission_result")

func _rm_m1() -> void:
	_rm_set_limit(3)
	var s: Dictionary = await _rm_begin_sortie()
	if s.is_empty(): return
	var roster_before: Array = _t6b_roster_ids()
	var b_before: String = _ra_base_status(LEAD_B)
	var fallen_before: Array = Array(_runtime.call("get_fallen")).duplicate(true)
	_check(b_before == "aboard", "M1 (W6): B steht vor dem Missionsende an Bord (%s)" % b_before)
	var result: Dictionary = await _rm_real_end(s, "M1", "button")
	if result.is_empty(): return
	print("RM_M1_RESULT outcome=", result.get("mission_outcome"), " total_loss=", result.get("casualty_total_loss"), " respawn=", result.get("respawn_unit_ids"), " limit=", result.get("respawn_limit"), " fatal=", result.get("fatality_unit_ids"))
	_check(not bool(result.get("casualty_total_loss", true)), "M1: kein Totalverlust")
	_check(PackedStringArray(result.get("respawn_unit_ids", PackedStringArray())) == PackedStringArray([LEAD_B]) and int(result.get("respawn_limit", -1)) == 3, "M1: _last_mission_result traegt respawn_unit_ids [B] und respawn_limit 3")
	_check(PackedStringArray(result.get("fatality_unit_ids", PackedStringArray(["x"]))).is_empty(), "M1: niemand als gefallen gemeldet")
	var b: Dictionary = _roster_unit(LEAD_B)
	_check(String(b.get("availability_status", "")) == "respawning" and int(b.get("respawns_used", -1)) == 1, "M1: B ist respawning, respawns_used 1 (%s)" % b.get("availability_status", ""))
	_check(_t6b_roster_ids() == roster_before, "M1: Kader gleich gross und in gleicher Reihenfolge (%s)" % [_t6b_roster_ids()])
	_check(Array(_runtime.call("get_fallen")) == fallen_before, "M1: Gefallenenliste unveraendert")
	var problems: PackedStringArray = _flow.call("_campaign_roster_problems", Array(_flow.get("_all_team_units")))
	_check(problems.is_empty(), "M1: Kader bleibt spielbar (%s)" % [problems])
	# W6: B stand an Bord und steht jetzt unsichtbar auf Polisa; Speichern und Fortsetzen gelingen.
	var b_after: String = _ra_base_status(LEAD_B)
	var b_state: Dictionary = Dictionary(Dictionary(_t6b_base().get("_states")).get(LEAD_B, {}))
	print("RM_M1_W6 before=", b_before, " after=", b_after, " craft_id=", b_state.get("craft_id", "<fehlt>"), " state=", b_state)
	_check(b_after == "station" and String(b_state.get("craft_id", "x")).is_empty(), "M1 (W6): B steht nach dem Ende als station ohne Schiff (%s)" % b_after)
	var away_save: Dictionary = _flow.call("request_campaign_save")
	print("RM_M1_AWAY_SAVE ok=", away_save.get("ok", false), " reason=", away_save.get("reason", ""))
	if not await _rm_return_home("satellite_crash"): return
	await create_timer(1.0).timeout
	var home_state: Dictionary = Dictionary(Dictionary(_t6b_base().get("_states")).get(LEAD_B, {}))
	_check(String(home_state.get("status", "")) == "station" and String(home_state.get("craft_id", "x")).is_empty(), "M1 (W6): zu Hause steht B weiter als station ohne Schiff (%s)" % [home_state.get("status", "")])
	_check(String(_roster_unit(LEAD_B).get("availability_status", "")) == "respawning" and _t6b_roster_ids() == roster_before, "M1 (W6): zu Hause B respawning, Kader unveraendert")
	var saved: Dictionary = _flow.call("request_campaign_save")
	print("RM_M1_SAVE ok=", saved.get("ok", false), " reason=", saved.get("reason", ""))
	if not _check(bool(saved.get("ok", false)), "M1 (W6): Speichern zu Hause nach dem Missionsende gelingt (%s)" % [saved.get("reason", "")]): return
	await _end_sortie()
	await create_timer(0.5).timeout
	if not await _t6b_open("campaign", "continue"): return
	var b_cont: Dictionary = _roster_unit(LEAD_B)
	_check(String(b_cont.get("availability_status", "")) == "respawning" and _ra_base_status(LEAD_B) == "station", "M1 (W6): nach dem Fortsetzen ist B respawning und station (%s / %s)" % [b_cont.get("availability_status", ""), _ra_base_status(LEAD_B)])
	_check(_t6b_roster_ids() == roster_before, "M1 (W6): Kader nach dem Fortsetzen unveraendert")

## W7 - BEKANNTER MANGEL, wird in eigenem Abschnitt behoben (dann muessen die Erwartungen dieses Falls bewusst geaendert werden):
## B wartet respawning auf Polisa, A und Pilot fliegen einen echten Einsatz; der Einsatzstand mit Wartendem wird abgelehnt
## (home_personnel_unsupported), der Heimstand auf der Platte bleibt dabei unveraendert, Fortsetzen faellt auf den Heimstand zurueck.
var _rm_w7_home_remaining: float = -1.0

func _rm_w7() -> void:
	_rm_set_limit(3)
	_rm_mode = "w7"
	var s: Dictionary = await _rm_begin_sortie()
	_rm_mode = "three"
	if s.is_empty(): return
	var roster_before: Array = _t6b_roster_ids()
	var b_before: Dictionary = _roster_unit(LEAD_B).duplicate(true)
	_check(String(b_before.get("availability_status", "")) == "respawning", "W7: B ist im Einsatz weiter respawning")
	var remaining_before: float = float(Dictionary(b_before.get("recovery_state", {})).get("seconds_remaining", -1.0))
	var home_path: String = load("res://scripts/meta/campaign_active_checkpoint_store.gd").HOME_PATH
	var home_sha_before: String = FileAccess.get_sha256(home_path) if FileAccess.file_exists(home_path) else ""
	_check(not home_sha_before.is_empty(), "W7: der Heimstand liegt auf der Platte")
	var capture = load("res://scripts/mission/campaign_active_mission_capture.gd")
	var captured: Dictionary = capture.capture_components(_flow, _runtime)
	var stable_deadline := Time.get_ticks_msec() + 30000
	while not captured.get("ok", false) and Time.get_ticks_msec() < stable_deadline and String(captured.get("reason", "")) in ["checkpoint_pending_work", "checkpoint_clock_unsynced", "checkpoint_pending_setup", "mission_lifecycle_busy", "mission_movement_pending", "transport_transition_pending"]:
		await create_timer(0.1).timeout
		captured = capture.capture_components(_flow, _runtime)
	print("RM_W7_CAPTURE ok=", captured.get("ok", false), " reason=", captured.get("reason", ""))
	# Befund W7: Der Einsatzstand (campaign_active_mission_capture, Zeilen ~87-95) kennt nur Kader == Besatzung, alle an Bord.
	# Ein Wartender auf Polisa (wie jede nicht eingesetzte Person, auch ein Verwundeter) macht den Einsatz nicht speicherbar.
	# Gepruefte Eigenschaft hier: Die Ablehnung ist sauber (kein halber Stand, keine Aktivdatei) und das Fortsetzen
	# faellt auf den Heimstand zurueck, in dem B weiter respawning mit Restzeit steht.
	_check(not bool(captured.get("ok", true)) and String(captured.get("reason", "")) == "home_personnel_unsupported", "W7 (bekannter Mangel, wird in eigenem Abschnitt behoben): Einsatzstand mit Wartendem wird abgelehnt, Grund home_personnel_unsupported (%s)" % [captured.get("reason", "")])
	var active_path: String = load("res://scripts/meta/campaign_active_checkpoint_store.gd").DEFAULT_PATH
	var saved: Dictionary = _flow.call("request_campaign_save")
	print("RM_W7_SAVE ok=", saved.get("ok", false), " reason=", saved.get("reason", ""))
	_check(not bool(saved.get("ok", true)), "W7: Autosave im Einsatz wird abgelehnt statt einen halben Stand zu schreiben (%s)" % [saved.get("reason", "")])
	_check(not FileAccess.file_exists(active_path), "W7: es liegt keine Aktivdatei des Einsatzes auf der Platte")
	var home_sha_after: String = FileAccess.get_sha256(home_path) if FileAccess.file_exists(home_path) else ""
	_check(home_sha_after == home_sha_before, "W7: der Heimstand auf der Platte ist nach der Ablehnung unveraendert (Pruefsumme vorher %s, nachher %s)" % [home_sha_before.left(12), home_sha_after.left(12)])
	_flow.queue_free()
	await process_frame
	START.request_start(self, "campaign", "continue")
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	await create_timer(1.0).timeout
	print("RM_W7_CONTINUE mission=", _flow.get("_active_mission") != null, " restore_error=", _flow.get_meta("campaign_active_restore_error", {}))
	_check(_flow.get("_active_mission") == null, "W7: Fortsetzen faellt auf den Heimstand zurueck (kein Einsatz)")
	var b_after: Dictionary = _roster_unit(LEAD_B)
	var remaining_after: float = float(Dictionary(b_after.get("recovery_state", {})).get("seconds_remaining", -1.0))
	_check(String(b_after.get("availability_status", "")) == "respawning" and remaining_after > 0.0, "W7: B bleibt respawning mit Restzeit nach dem Fortsetzen (%s)" % [remaining_after])
	_check(_rm_w7_home_remaining > 0.0 and remaining_after >= remaining_before and remaining_after <= _rm_w7_home_remaining, "W7: die Restzeit ist die des Heimstands vor dem Abflug, hoechstens so gross wie beim Speichern (%s) und nicht kleiner als im Einsatz (%s): nachher %s; die im Einsatz vergangene Zeit zaehlt nicht" % [_rm_w7_home_remaining, remaining_before, remaining_after])
	_check(_t6b_roster_ids() == roster_before, "W7: Kader nach dem Fortsetzen unveraendert")
	_check(_ra_base_status(LEAD_B) == "station", "W7: B steht nach dem Fortsetzen weiter als station (%s)" % _ra_base_status(LEAD_B))

## R4 (R4a): B stirbt im Trupp mit A. Danach steht B in keinem Trupp, der Trupp mit A laesst sich verladen und ist nicht gesperrt.
## Der frueher gemessene Zwischenzustand (Person im Trupp, board/base_board = unit_wounded, remove/assign = unit_busy) gilt nicht mehr.
func _rm_r4() -> void:
	if not await _t6b_new_four(): return
	var members_before: Array = _t6b_where(_t6b_payload(), LEAD_B)
	_check(members_before.any(func(place: String) -> bool: return place.begins_with("fireteam ")), "R4: Fixture: B steht vor dem Tod in einem Trupp (%s)" % [members_before])
	_flow.call("_apply_campaign_casualties", _ra_result(_t6b_states({LEAD_B: "down"}), "aborted", 3))
	_check(String(_roster_unit(LEAD_B).get("availability_status", "")) == "respawning", "R4: B ist respawning")
	var places: Array = _t6b_where(_t6b_payload(), LEAD_B).filter(func(place: String) -> bool: return place.begins_with("fireteam ") or place.begins_with("flow._selected") or place.begins_with("flow._homebase_staged") or place.begins_with("craft."))
	_check(places.is_empty(), "R4: B steht in keinem Trupp, keiner Auswahl und nicht auf dem Schiff (%s)" % [places])
	_craft_id = String(Dictionary(Array(_flow.get("_homebase_aircraft_definitions"))[0]).get("craft_id", ""))
	var team_board: Dictionary = _screen.call("request_operation", "board", {"craft_id": _craft_id, "fireteam_id": _team_id})
	_check(bool(team_board.get("ok", false)), "R4: der Trupp mit A wird dem Schiff zugeteilt (%s)" % [team_board])
	var walk: Dictionary = _screen.call("request_operation", "base_board", {"craft_id": _craft_id, "fireteam_id": _team_id, "whole_fireteam": true})
	_check(bool(walk.get("ok", false)), "R4: der Trupp mit A geht an Bord (%s)" % [walk])
	_check(await _wait(func(): return _ra_base_status(LEAD_A) == "aboard", 60000, "R4: A ist an Bord"), "R4: A steht aboard")
	var block: Dictionary = _t6b_base().call("get_departure_block", _craft_id)
	_check(block.is_empty(), "R4: die Abflugsperre ist leer (%s)" % [block])
	_check(_ra_base_status(LEAD_B) == "station", "R4: B bleibt auf Polisa (station) und fliegt nicht mit")

func _rm_m2() -> void:
	_rm_set_limit(0)
	var s: Dictionary = await _rm_begin_sortie()
	if s.is_empty(): return
	var roster_before: Array = _t6b_roster_ids()
	var result: Dictionary = await _rm_real_end(s, "M2", "aborted")
	if result.is_empty(): return
	print("RM_M2_RESULT outcome=", result.get("mission_outcome"), " total_loss=", result.get("casualty_total_loss"), " fatal=", result.get("fatality_unit_ids"), " has_respawn_ids=", result.has("respawn_unit_ids"))
	_check(not bool(result.get("casualty_total_loss", true)), "M2: kein Totalverlust")
	_check(PackedStringArray(result.get("fatality_unit_ids", PackedStringArray())) == PackedStringArray([LEAD_B]), "M2: Grenze 0: fatality_unit_ids enthaelt B")
	_check(not _t6b_roster_ids().has(LEAD_B) and _t6b_roster_ids() == roster_before.filter(func(id): return id != LEAD_B), "M2: Grenze 0: B ist aus dem Kader, die anderen bleiben in Reihenfolge")
	var fallen: Dictionary = _ra_fallen(LEAD_B)
	_check(not fallen.is_empty() and not fallen.has("reason") and not fallen.has("respawns_used") and not fallen.has("respawn_limit"), "M2: Grenze 0: Eintrag in der Gefallenenliste ohne die neuen Felder (%s)" % [fallen])
	_check(not result.has("respawn_unit_ids") or PackedStringArray(result.get("respawn_unit_ids", PackedStringArray())).is_empty(), "M2: Grenze 0: niemand kommt wieder")
	_check(not _t6b_base_ids().has(LEAD_B), "M2: B ist auch aus der Basis weg")
	var m2_problems: PackedStringArray = _flow.call("_campaign_roster_problems", Array(_flow.get("_all_team_units")))
	_check(m2_problems.is_empty(), "M2: der Kader bleibt spielbar (%s)" % [m2_problems])

## Ergebnis, in dem unit_id als Wiederkehrer (Grenze 3) mit vollem casualties-Eintrag steht, wie ihn resolve_mission liefert.
func _rm_protected_result(unit_id: String, final_entry: bool) -> Dictionary:
	var result: Dictionary = _ra_result(_t6b_states({}), "aborted", 3)
	var entry: Dictionary = {"unit_id": unit_id, "outcome": "dead", "final": final_entry, "death_number": 4 if final_entry else 1, "respawn_state": {"state": "respawning", "death_number": 1, "seconds_total": 3600, "seconds_remaining": 3600, "pickup_location_id": "polisa", "source": "left_behind"}}
	result["casualties"] = [entry]
	if final_entry:
		result["fatality_unit_ids"] = PackedStringArray([unit_id])
		result["respawn_unit_ids"] = PackedStringArray()
	else:
		result["fatality_unit_ids"] = PackedStringArray()
		result["respawn_unit_ids"] = PackedStringArray([unit_id])
	return result

func _rm_check_protected(unit_id: String, label: String) -> void:
	for final_entry: bool in [false, true]:
		var applied: Dictionary = _flow.call("_apply_campaign_casualties", _rm_protected_result(unit_id, final_entry))
		var entry: Dictionary = _casualty_entry(applied, unit_id)
		var leftovers: Array = []
		for key: String in PROTECTED_KEYS:
			if entry.has(key):
				leftovers.append(key)
		var tag: String = "%s (%s)" % [label, "Grenze erreicht" if final_entry else "Wiederkehrer"]
		_check(not entry.is_empty() and bool(entry.get("protected_from_death", false)) and String(entry.get("outcome", "")) == "wounded" and String(entry.get("severity", "")) == "severe", "%s: Eintrag geschuetzt, verwundet, schwer (%s)" % [tag, entry])
		_check(leftovers.is_empty(), "%s: Eintrag traegt keinen der Schluessel final, death_number, respawn_state (uebrig: %s)" % [tag, leftovers])
		_check(PackedStringArray(applied.get("respawn_unit_ids", PackedStringArray(["x"]))).is_empty() and PackedStringArray(applied.get("fatality_unit_ids", PackedStringArray(["x"]))).is_empty(), "%s: weder Wiederkehrer noch Gefallener" % tag)

func _rm_p1() -> void:
	if not await _t6b_new_four(): return
	_check(bool(_runtime.call("is_person_protected_from_death", PILOT_ID)), "P1: Fixture: Pilot ist geschuetzt")
	_rm_check_protected(PILOT_ID, "P1 Schiffspilot")

func _rm_p2() -> void:
	if not await _t6b_new_four(): return
	_check(bool(_runtime.call("is_person_protected_from_death", "campaign_outpost_recruit")), "P2: Fixture: Fortschritts-Rekrut ist geschuetzt")
	_rm_check_protected("campaign_outpost_recruit", "P2 campaign_outpost_recruit")

func _rm_p3() -> void:
	if not await _t6b_new_four(): return
	_check(bool(_runtime.call("is_person_protected_from_death", "campaign_rescue_pilot")), "P3: Fixture: Rettungspilot ist geschuetzt")
	_rm_check_protected("campaign_rescue_pilot", "P3 campaign_rescue_pilot")

func _rm_p4() -> void:
	if not await _t6b_new_four(): return
	if not _rm_make_recruiter(LEAD_B): return
	_check(bool(_runtime.call("is_person_protected_from_death", LEAD_B)), "P4: Fixture: B ist als Anwerber geschuetzt")
	_rm_check_protected(LEAD_B, "P4 Anwerber")

## Beobachtung (keine Aenderung): Was traegt der Eintrag einer geschuetzten Person bei Grenze 0, wo final seit R1 steht?
func _rm_p5() -> void:
	if not await _t6b_new_four(): return
	if not _rm_make_recruiter(LEAD_B): return
	var states: Array = _t6b_states({LEAD_B: "down"})
	var result: Dictionary = _ra_result(states, "aborted", 0)
	var raw_entry: Dictionary = _casualty_entry(result, LEAD_B)
	var applied: Dictionary = _flow.call("_apply_campaign_casualties", result)
	var entry: Dictionary = _casualty_entry(applied, LEAD_B)
	print("RM_P5_LIMIT0 raw_keys=", raw_entry.keys(), " applied_keys=", entry.keys(), " final=", entry.get("final", "<fehlt>"))
	_check(bool(entry.get("protected_from_death", false)) and String(entry.get("outcome", "")) == "wounded", "P5: Grenze 0: Pilot als geschuetzt verwundet gebucht (%s)" % [entry])
