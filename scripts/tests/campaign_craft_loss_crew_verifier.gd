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
	# LC2l L2/L3, LC2m W1: dritte Person (echte Anwerbung) im zweiten Schiff, NICHT in der Besatzung des Einsatzschiffs; k2d steht abseits, k2e steht am
	# Einsatzschiff, k2f: auch der Truppfuehrer sass im zweiten Schiff und steht am Einsatzschiff, die dritte Person abseits; l3 Sieg.
	if only.is_empty() or only in ["k2d", "trio"]: await _trio_case("left")
	if only.is_empty() or only in ["k2e", "trio"]: await _trio_case("near")
	if only.is_empty() or only in ["k2f", "trio"]: await _trio_case("pair")
	if only.is_empty() or only in ["l3", "trio"]: await _trio_case("victory")
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

## LC2l L2/L3: der echte Fall mit DREI Personen. ECHT: die dritte Person ist die angeworbene "campaign_outpost_recruit" (Befehl claim_recruit, Kader,
## Basis-Personal, Feuertrupp ft1); sie wird mit Truppfuehrer und Pilot wirklich eingeschifft, fliegt im Einsatzschiff mit, landet, steht im Einsatz
## als echte Einheit; das Einsatzende laeuft durch den echten Fluss (_on_mission_combat_resolved, der neue elif-Zweig). GESTELLT: (1) das zweite Schiff
## ist ein Kaufschiff (_inject_bought_ship) und ist nie geflogen; (2) die Basisseite fuehrt die Person als "an Bord des zweiten Schiffs" (wie _k2_prepare),
## obwohl sie physisch im Einsatzschiff mitgeflogen ist; (3) der Absturz des zweiten Schiffs ist eine von Hand angehaengte Absturzstelle (_site) und
## apply_air_crash setzt die Person dort unversehrt ab.
const RECRUIT := "campaign_outpost_recruit"
var _trio := false

func _base_crew_ready() -> bool:
	if not _trio: return super()
	var personnel: Node = _runtime.call("get_base_personnel_runtime")
	if personnel == null or not bool(personnel.call("is_pilot_aboard", _craft_id)): return false
	var people: Array = personnel.call("get_snapshot").get("units", [])
	return people.size() == 3 and people.all(func(person: Dictionary): return String(person.status) == "aboard" and String(person.craft_id) == _craft_id) and bool(_screen.call("_has_homebase_direct_launch_payload_for_craft", _craft_id))

## Wie _begin_funded_sortie, aber mit der angeworbenen dritten Person im Feuertrupp.
func _begin_trio_sortie(credits: int, tag: String) -> Dictionary:
	START.request_start(self, "campaign", "new")
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	_set_credits(credits)
	if not _save_base(tag + ": Einsatz-Aufbau"): return {}
	if not await _prepare_initial_base(): return {}
	# Anwerbung wie im Adapter (campaign_recruit, singleplayer_runtime_adapter.gd ~2600-2612), ohne das Tor "Aussenposten gesichert" (das waere ein
	# zweiter echter Einsatz): derselbe Flussbaustein register_campaign_recruit mit dem geladenen Einsatzschiff als Nutzlast, derselbe Befehl claim_recruit.
	var profile: Dictionary = Dictionary(Array(load("res://scripts/meta/campaign_start_configuration.gd").new().call("_initial_roster"))[0]).duplicate(true)
	profile.merge({"unit_id": RECRUIT, "display_name": "Robin Seidel", "fireteam_id": "ft1", "armor": "light", "armor_id": "light", "weapon_1": "pistol", "weapon_1_id": "pistol", "weapon_2": "none", "weapon_2_id": "none"}, true)
	# GESTELLT: der Auftrag outpost_recovery gilt als gewonnen (wie im Kistenpruefer), sonst lehnt claim_recruit mit recruit_not_ready ab.
	var outpost_job: Dictionary = Dictionary(Dictionary(_runtime.get("_campaign").get("_jobs"))["outpost_recovery"])
	var outpost_status_before = outpost_job.get("status")
	outpost_job["status"] = "completed"
	var registered: Dictionary = Dictionary(_flow.call("register_campaign_recruit", profile, {}, _craft_id))
	var claimed: Dictionary = Dictionary(_runtime.call("_commit", "singleplayer_campaign", "claim_recruit", {"kind": "outpost"}, "lc2l:%s:recruit" % tag, {"runtime_authorized": true, "outpost_cleared": true}))
	# Der Auftrag steht danach wieder, wie er war (sonst lehnt das Speichern die Auftragsreihenfolge ab: invalid_job_order).
	outpost_job["status"] = outpost_status_before
	if not _check(bool(registered.get("ok", false)) and bool(claimed.get("ok", false)), tag + ": Aufbau: Aussenposten-Person angeworben (%s | %s)" % [str(registered), str(claimed)]): return {}
	_trio = true
	_crew_ids = [LEADER, RECRUIT]
	_pilot_id = PILOT
	_check(_screen.call("request_operation", "accept_job", {"job_id": "satellite_recovery"}).get("ok", false), tag + ": Auftrag angenommen")
	_check(_screen.call("request_operation", "select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"}).get("ok", false), tag + ": Ziel gewaehlt")
	if not await _launch_and_land("satellite_recovery", "res://maps/satellite_crash_site.json"): return {}
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	var sortie: Dictionary = {
		"mission": mission, "controller": controller, "driver": mission.get_node("CombatLoopDriver"), "simulation": mission.get_node("SimulationRoot"),
		"leader": controller.call("_get_campaign_sortie_unit", LEADER), "pilot": controller.call("_get_campaign_sortie_unit", PILOT),
		"recruit": controller.call("_get_campaign_sortie_unit", RECRUIT), "access": controller.call("get_campaign_ground_ship_access", _craft_id)}
	if not _check(sortie.leader != null and sortie.pilot != null and sortie.recruit != null and bool(sortie.access.get("ok", false)), tag + ": drei echte Einheiten im Einsatz und der Schiffszugang ist da"): return {}
	return sortie

func _trio_case(variant: String) -> void:
	var tag := {"left": "K2d", "near": "K2e", "pair": "K2f", "victory": "L3"}[variant] as String
	var s: Dictionary = await _begin_trio_sortie(500, tag)
	if s.is_empty():
		_trio = false
		return
	var second := _inject_bought_ship()
	var states: Dictionary = _runtime.call("get_base_personnel_runtime").get("_states")
	if not _check(states.has(RECRUIT) and String(states[RECRUIT].get("craft_id", "")) == _craft_id, tag + ": Aufbau: die dritte Person ist an der Basis im Einsatzschiff eingeschifft (%s)" % str(states.get(RECRUIT, {}).get("craft_id", "-"))):
		_trio = false
		return
	states[RECRUIT]["craft_id"] = second
	states[RECRUIT]["status"] = "aboard"
	# K2f: auch der Truppfuehrer wird an der Basis als Insasse des zweiten Schiffs gefuehrt (GESTELLT wie _k2_prepare).
	var second_crew: Array = [LEADER, RECRUIT] if variant == "pair" else [RECRUIT]
	if variant == "pair": _k2_prepare(s, second)
	_site(s, second)
	var site: Dictionary = Dictionary(Array(s.simulation.get("_air_crash_sites")).back())
	s.controller.call("apply_air_crash", second, site, {RECRUIT: {"state": "unhurt"}}, [RECRUIT])
	var occupants: Array = _flow.call("_lost_craft_occupant_ids", [{"craft_id": second}])
	occupants.sort()
	var expected_occupants: Array = second_crew.duplicate()
	expected_occupants.sort()
	_check(occupants == expected_occupants, tag + ": Insassen des verlorenen Schiffs laut Basisseite (%s)" % str(occupants))
	if not _seat_crew(s):
		_trio = false
		return
	# GESTELLT: Die Besatzung des Einsatzschiffs ist die Besuchskennung des Schiffs (singleplayer_visit_identities.unit_ids) und umfasst die Personen, weil sie
	# im Einsatzschiff mitgeflogen sind; das Einsatzschiff wuerde sie als Besatzung einschiffen. Als Personen des zweiten Schiffs gehoeren sie nicht dazu:
	# sie werden in allen Faellen aus der Besatzung des Einsatzschiffs genommen (LC2m: auch in der Gegenprobe K2e).
	var visits: Dictionary = s.mission.get_meta("singleplayer_visit_identities", {})
	if not _check(visits.has(_craft_id), tag + ": Aufbau: Besuchskennung des Einsatzschiffs ist da"):
		_trio = false
		return
	var crew_ids := PackedStringArray(Dictionary(visits[_craft_id]).get("unit_ids", []))
	for person in second_crew:
		var at: int = crew_ids.find(person)
		_check(at >= 0, tag + ": Aufbau: %s gehoerte zur Besatzung des Einsatzschiffs (%s)" % [person, str(crew_ids)])
		if at >= 0: crew_ids.remove_at(at)
	Dictionary(visits[_craft_id])["unit_ids"] = crew_ids
	# Die dritte Person steht in K2e am Zugang des Einsatzschiffs, sonst drei Felder (270) davon entfernt; der Truppfuehrer steht am Zugang (_seat_crew).
	if not _place_at(s.simulation, s.access, RECRUIT, Vector2.ZERO if variant == "near" else Vector2(270.0, 0.0)):
		_trio = false
		return
	var measured: Dictionary = {}
	for raw in Array(Dictionary(_flow.call("_build_mission_result", s.mission, {})).get("team_states", [])): measured[String(Dictionary(raw).get("unit_id", ""))] = raw
	_check(bool(Dictionary(measured.get(RECRUIT, {})).get("near_ship", variant != "near")) == (variant == "near") and not bool(Dictionary(measured.get(RECRUIT, {})).get("aboard", true)), tag + ": Aufbau: die dritte Person ist %s und nicht an Bord (%s)" % ["am Einsatzschiff" if variant == "near" else "abseits", str(measured.get(RECRUIT, {}))])
	if variant == "pair": _check(bool(Dictionary(measured.get(LEADER, {})).get("near_ship", false)) and not bool(Dictionary(measured.get(LEADER, {})).get("aboard", true)), tag + ": Aufbau: der Truppfuehrer steht am Einsatzschiff, nicht an Bord")
	if variant != "victory":
		# LC2m W1: die Ansage vor dem Abheben, gebaut von der Funktion, die den EVAC-Knopf beschriftet.
		s.controller.call("_refresh_mission_evacuation_button")
		var button: Button = s.controller.call("_ensure_mission_evacuation_button")
		var away: bool = variant != "near"
		var expected_text: String = "EVAC · Notrettung 400 Cr" if away else "EVAC"
		_check(button != null and button.text == expected_text, tag + ": Knopf vor dem Abheben: \"%s\" (%s)" % [expected_text, button.text if button != null else "kein Knopf"])
		if away: _check(button != null and button.tooltip_text == "1 Person des abgeschossenen Schiffs ist nicht am Schiff. Notrettung: 400 Credits.", tag + ": Tooltip nennt 1 Person und 400 Credits (%s)" % (button.tooltip_text if button != null else "-"))
		else: _check(button != null and not button.tooltip_text.contains("Notrettung") and not button.text.contains("Notrettung"), tag + ": niemand abseits: kein Hinweis auf die Notrettung (%s)" % (button.tooltip_text if button != null else "-"))
	if variant == "victory": s.driver.call("_resolve_combat", "victory", String(s.driver.get("friendly_team_id")))
	else: s.driver.call("_resolve_combat", "aborted", "", "evacuation")
	if not await _wait_released(tag + ": Einsatz wird freigegeben"):
		_trio = false
		return
	var result: Dictionary = Dictionary(_flow.get("_last_mission_result"))
	var others: Array = Array(result.get("other_craft_losses", []))
	var fee: int = int(Dictionary(others[0]).get("rescue_fee", 0)) if not others.is_empty() else -1
	print("%s_RESULT outcome=%s result=%s total_loss=%s fee=%s credits=%d others=%s fate=%s base=%s/%s" % [tag, result.get("mission_outcome"), result.get("result"), result.get("casualty_total_loss"), fee, _credits(), str(others), _unit_fate(RECRUIT), states[RECRUIT].get("status"), states[RECRUIT].get("craft_id")])
	_check(not bool(result.get("casualty_total_loss", false)) and not result.has("craft_loss") and others.size() == 1, tag + ": Einsatzschiff heil, nur das zweite Schiff verloren, kein Totalverlust")
	var charged: bool = variant in ["left", "pair"]
	_check((fee == 400 and _credits() == 100 and _loss_lines(result) == 1) if charged else (fee == 0 and _credits() == 500 and _loss_lines(result) == 0), tag + (": Gebuehr genau einmal 400, 500 -> 100, Zeile \"Notrettung: −400 Credits\" in der Nachbesprechung (%d / %d / Zeilen %d)" if charged else ": keine Gebuehr, 500 Credits, keine Notrettungszeile (%d / %d / Zeilen %d)") % [fee, _credits(), _loss_lines(result)])
	_check(DEBRIEF_SCRIPT.build_craft_loss_text(result).contains("Schiff verloren: Zweitschiff"), tag + ": das zweite Schiff steht in der Verlustzeile der Nachbesprechung")
	_check(not _unit_is_dead(RECRUIT) and not PackedStringArray(result.get("fatality_unit_ids", PackedStringArray())).has(RECRUIT), tag + ": die dritte Person lebt (%s)" % _unit_fate(RECRUIT))
	_check(String(states[RECRUIT].get("status", "")) != "aboard" and String(states[RECRUIT].get("craft_id", "x")).is_empty() and _aboard_ids(second).is_empty(), tag + ": sie ist an der Basis, nicht an Bord eines fehlenden Schiffs (%s / %s)" % [str(states[RECRUIT].get("status")), str(states[RECRUIT].get("craft_id"))])
	if variant == "pair": _check(not _unit_is_dead(LEADER) and String(states[LEADER].get("status", "")) != "aboard" and String(states[LEADER].get("craft_id", "x")).is_empty(), tag + ": auch der Truppfuehrer lebt und ist an der Basis (%s / %s / %s)" % [_unit_fate(LEADER), str(states[LEADER].get("status")), str(states[LEADER].get("craft_id"))])
	_check(_fleet_ids() == [_craft_id] and _lost_ids() == [second], tag + ": das zweite Schiff ist geraeumt und steht im Verlustbeleg (%s / %s)" % [str(_fleet_ids()), str(_lost_ids())])
	print("%s_TEAM_STATES %s" % [tag, str(result.get("team_states"))])
	# Die Heimkehr des Einsatzschiffs (Abheben, Rueckflug) ist nicht Gegenstand dieses Pruefers (wie S1 im Zweitschiff-Pruefer): das Schiff steht
	# per frischem Reiseeigner wieder am Boden der Basis, danach darf nichts mehr "unterwegs" melden.
	var travel: RefCounted = _runtime.get("_travel")
	travel.call("unregister_craft", _craft_id)
	travel.call("register_craft", _craft_id)
	Dictionary(_flow.get("_aircraft_location_by_craft"))[_craft_id] = "homebase"
	Dictionary(_flow.get("_craft_location_runtime")).erase(_craft_id)
	# Speichern: Ein echtes Speichern geht in diesem Aufbau nicht (die von Hand angeworbene Person ohne gewonnenen Auftrag outpost_recovery ist fuer die
	# Speicherpruefung ein ungueltiger Stand: invalid_progress / invalid_job_order / invalid_job_state), das waere ein Mangel des Aufbaus, nicht des Zweigs.
	# Geprueft wird deshalb die Sperre der Basis: nichts ist mehr unterwegs, kein Schiff "an Bord eines fehlenden Schiffs" (S1-Muster), und das Speichern
	# nach Schiffsverlust ohne dritte Person ist in I2/S1 echt geprueft.
	var guard: Dictionary = _runtime.call("get_world_checkpoint_guard")
	_check(bool(guard.get("ok", false)), tag + ": keine Sperre durch den Einsatz, Basis waere speicherbar (%s)" % str(guard.get("reason", "")))
	_trio = false
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
