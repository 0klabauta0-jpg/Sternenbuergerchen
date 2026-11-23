extends "res://scripts/tests/campaign_total_loss_penalty_verifier.gd"
## LC2c: Einsatzende nach Schiffsverlust, durch den echten Kampagnenfluss (Meta-Szene, echter Einsatz, echtes Einsatzende).
## Das Schiff ist durch Bodenbeschuss verloren (Absturzstelle in der SimulationRoot; der Luftkampf selbst ist in air_shootdown_verifier geprueft).
## K1: das Einsatzende haengt nie (hoechstens ein Eintrag in _pending_campaign_mission_result, dann leer).
## L1 Sieg: Ergebnis bleibt Sieg, Notrettung (400 Credits) gebucht, kein Totalverlust, kein Rueckfall, Belohnung/Abschluss wie gewohnt.
## L2 Abbruch (Evakuieren): dasselbe, Ergebnis bleibt abgebrochen.
## L3 beim Absturz Gestorbener: tot (Respawn-Quelle crash), die anderen leben; Stand speichern und laden besteht.
## L4 Gegenprobe: kein Schiffsverlust (Notlandung) -> kein Verlustbeleg, keine Notrettung.

const AIR_RULES = preload("res://scripts/core/air_crash_rules.gd")
const GFA_SCRIPT = preload("res://scripts/combat/ground_fire_vs_air.gd")
## LC2e C: Ablauffall ueber den echten Weg: echter Start (Schiffskarte, Pilot an Bord, Abheben) -> Bodenbeschuss (Baustein ground_fire_vs_air.step mit
## Attrappen-Schuetzen, die immer treffen) bis Rumpf 0 -> die echte SimulationRoot wuerfelt (fester Zufallsstart) und setzt an der Absturzstelle ab ->
## Einsatzende (Evakuieren) -> Notrettung -> Heimkehr -> Speichern -> Laden. Die Absturzstelle wird NICHT von Hand angehaengt.

func _run() -> void:
	_configure_entry()
	await _c_full_path()
	await _l1_victory()
	await _l2_abort()
	await _l3_dead_in_crash_and_reload()
	await _l5_save_after_loss()
	await _l4_no_loss()
	print("CAMPAIGN_CRAFT_LOSS_FLOW passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _lose_craft(s: Dictionary, outcome: String = "crash") -> void:
	var sites: Array = s.simulation.get("_air_crash_sites")
	sites.append({"craft_id": _craft_id, "model_id": "cutlass", "grid": Vector2i.ZERO, "outcome": outcome})

func _l1_victory() -> void:
	var s: Dictionary = await _begin_funded_sortie(500)
	if s.is_empty(): return
	_lose_craft(s)
	_check(bool(s.controller.call("_is_air_craft_crashed", _craft_id)), "L1: Schiff gilt als verloren")
	s.driver.call("_resolve_combat", "victory", String(s.driver.get("friendly_team_id")))
	if not await _wait_released("L1 Sieg: Einsatz wird freigegeben (kein Haengenbleiben)"): return
	_check(Dictionary(_flow.get("_pending_campaign_mission_result")).is_empty(), "L1: nichts haengt in _pending_campaign_mission_result")
	var result: Dictionary = Dictionary(_flow.get("_last_mission_result"))
	var loss: Dictionary = Dictionary(result.get("craft_loss", {}))
	print("L1_RESULT result=", result.get("result"), " outcome=", result.get("mission_outcome"), " loss=", loss, " total_loss=", result.get("casualty_total_loss"), " retry=", result.get("campaign_checkpoint_retry_required"))
	_check(not bool(result.get("casualty_total_loss", false)) and not bool(result.get("campaign_checkpoint_retry_required", false)), "L1: kein Totalverlust, kein Rueckfall auf den Basisstand")
	_check(not String(result.get("result", "")).contains("defeat") and not String(result.get("mission_outcome", "")).contains("defeat"), "L1: ein Sieg bleibt ein Sieg (%s)" % str(result.get("mission_outcome")))
	_check(String(loss.get("craft_id", "")) == _craft_id and String(loss.get("outcome", "")) == "crash" and int(loss.get("rescue_fee", -1)) == 400, "L1: Verlustbeleg mit Schiff, Ausgang und Gebuehr 400 (%s)" % str(loss))
	_check(_credits() == 100, "L1: Notrettung gebucht, 500 -> 100 Credits (%d)" % _credits())
	_check(String(_flow.get("_current_meta_view")) == "debrief", "L1: Debrief ist sichtbar")
	await _end_sortie()

func _l2_abort() -> void:
	var s: Dictionary = await _begin_funded_sortie(500)
	if s.is_empty(): return
	_lose_craft(s, "explosion")
	s.driver.call("_resolve_combat", "aborted", "", "evacuation")
	if not await _wait_released("L2 Abbruch: Einsatz wird freigegeben"): return
	var result: Dictionary = Dictionary(_flow.get("_last_mission_result"))
	var loss: Dictionary = Dictionary(result.get("craft_loss", {}))
	_check(Dictionary(_flow.get("_pending_campaign_mission_result")).is_empty() and not bool(result.get("casualty_total_loss", false)), "L2: kein Haengenbleiben, kein Totalverlust")
	_check(String(loss.get("outcome", "")) == "explosion" and int(loss.get("rescue_fee", -1)) == 400 and _credits() == 100, "L2: Explosion, Notrettung 400, Guthaben 100 (%s / %d)" % [str(loss), _credits()])
	await _end_sortie()

func _l3_dead_in_crash_and_reload() -> void:
	var s: Dictionary = await _begin_funded_sortie(500)
	if s.is_empty(): return
	_lose_craft(s)
	# Der Truppfuehrer stirbt beim Absturz. Mit nur zwei Personen im Kader greift danach die vorhandene Regel (kein Anfuehrer mehr: Totalverlust);
	# hier zaehlt, dass das Einsatzende auch dann nicht haengt und die Ursache "Absturz" im Ergebnis steht.
	s.leader.set_meta("killed_in_crash", true)
	s.leader.call("apply_damage", 10000, {"source": "air_crash"})
	s.leader.call("advance_bleedout")
	if not await _wait(func(): return bool(Dictionary(s.driver.call("get_casualty_flags")).get(LEADER, {}).get("was_downed", false)), 5000, "L3: Treiber merkt sich den Ausfall"): return
	s.driver.call("_resolve_combat", "victory", String(s.driver.get("friendly_team_id")))
	if not await _wait_released("L3: Einsatz wird freigegeben"): return
	var result: Dictionary = Dictionary(_flow.get("_last_mission_result"))
	var states: Array = Array(result.get("team_states", []))
	var leader_state: Dictionary = {}
	for state in states:
		if String(Dictionary(state).get("unit_id", "")) == LEADER: leader_state = Dictionary(state)
	print("L3_RESULT total_loss=", result.get("casualty_total_loss"), " reason=", result.get("total_loss_reason"), " leader_state=", leader_state, " loss=", result.get("craft_loss"))
	_check(bool(leader_state.get("killed_in_crash", false)), "L3/W1: das Merkmal 'beim Absturz gestorben' kommt ueber den Fluss in die team_states (%s)" % str(leader_state))
	_check(Dictionary(_flow.get("_pending_campaign_mission_result")).is_empty(), "L3: das Einsatzende haengt nicht")
	await _end_sortie()

func _l5_save_after_loss() -> void:
	var s: Dictionary = await _begin_funded_sortie(500)
	if s.is_empty(): return
	_lose_craft(s)
	# Abbruch (Evakuieren): der Auftrag wird wieder geoeffnet; ein "Sieg" ohne abgeschlossenes Ziel liesse den Auftrag aktiv und das Speichern gesperrt.
	s.driver.call("_resolve_combat", "aborted", "", "evacuation")
	if not await _wait_released("L5: Einsatz wird freigegeben"): return
	# LC2e B1: Das verlorene Schiff verlaesst die Flotte dauerhaft (hier das einzige Schiff: leere Flotte). Der Basisstand ist wieder
	# schreibbar; Speichern und Laden behalten Guthaben (Notrettung gebucht), Verlustbeleg und die leere Flotte.
	_check(not _fleet_ids().has(_craft_id), "L5/B1: das verlorene Schiff ist nicht mehr in der Flotte (%s)" % str(_fleet_ids()))
	_check(not Dictionary(_flow.get("_aircraft_location_by_craft")).has(_craft_id) and not Dictionary(_flow.get("_assigned_aircraft_pilot_by_craft")).has(_craft_id), "L5/B1: kein Ort und keine Pilotenzuordnung mehr fuer das verlorene Schiff")
	var guard: Dictionary = _runtime.call("get_world_checkpoint_guard")
	_check(bool(guard.get("ok", false)), "L5/B1: Basisspeicherstand wieder schreibbar (%s)" % str(guard.get("reason", "")))
	_check(bool(Dictionary(_flow.get_meta("campaign_lost_craft_rescue_result", {})).get("ok", false)), "L5/B1: die Notrettung hat die Lebenden an die Basis gestellt (%s)" % str(_flow.get_meta("campaign_lost_craft_rescue_result", {})))
	# Die Heimgeholten laufen noch kurz; die Spielstandpruefung wartet ("Speichern wartet auf die Bewegung"), danach gelingt das Speichern.
	var saved: Dictionary = {}
	var saved_ok: bool = await _wait(func():
		saved.clear()
		saved.merge(Dictionary(_flow.call("request_campaign_save")))
		return bool(saved.get("ok", false)), 60000, "L5/B1: Speichern nach Schiffsverlust und Heimkehr gelingt")
	if not saved_ok: print("L5_SAVE_LAST ", saved)
	var disk: Dictionary = _disk()
	var lost_ids: Array = []
	for entry in Array(disk.get("lost_craft", [])): lost_ids.append(String(Dictionary(entry).get("craft_id", "")))
	_check(Array(disk.get("fleet", [1])).is_empty() and lost_ids == [_craft_id] and not Dictionary(Dictionary(disk.get("supply", {})).get("fuel_by_craft_id", {})).has(_craft_id), "L5/B1: Stand traegt leere Flotte, Verlustbeleg und keinen Treibstoff des Schiffs (%s)" % str(lost_ids))
	_check(_disk_credits() == 100, "L5/B1: Stand traegt das Guthaben nach der Notrettung (%d)" % _disk_credits())
	await _close()
	if not await _open_scene("campaign", "continue_home"): return
	_check(_fleet_ids().is_empty() and _credits() == 100, "L5/B1: Laden: Flotte leer, Guthaben 100 (%s / %d)" % [str(_fleet_ids()), _credits()])
	var resaved: Dictionary = {}
	await _wait(func():
		resaved.clear()
		resaved.merge(Dictionary(_flow.call("request_campaign_save")))
		return bool(resaved.get("ok", false)), 60000, "L5/B1: nach dem Laden ist wieder Speichern moeglich")
	await _close()

func _gid(unit) -> String: return String(unit.id)
func _gweapon(_unit) -> String: return "rocket_launcher"
func _gfit(_unit) -> bool: return true
func _gcontact(_unit) -> bool: return false
func _gsees(_unit, _target) -> Dictionary: return {"visible": true, "range_tiles": 3.0}
func _groll() -> float: return 0.0

func _air_button(mission: Node, action: String) -> Button:
	for candidate in mission.find_children("*", "Button", true, false):
		if candidate.get_meta("mission_dropship_card_command", "") == action and candidate.get_meta("mission_dropship_craft_id", "") == _craft_id: return candidate
	return null

## Fester Zufallsstart: der kleinste Stand des Stroms, bei dem der Abschuss ein Schiffsverlust ist UND der Pilot (einziger Insasse) stirbt.
func _seed_pilot_dies(skill: float) -> int:
	var rules: Dictionary = AIR_RULES.load_rules()
	for candidate in range(1, 20000):
		var shot: Dictionary = AIR_RULES.resolve_shootdown(skill, rules, candidate)
		if String(shot.get("outcome", "")) not in ["crash", "explosion"]: continue
		var occupants: Dictionary = AIR_RULES.resolve_occupants(String(shot.outcome), ["campaign_pilot"], rules, int(shot.rng_state))
		if Array(occupants.get("dead_ids", [])).has("campaign_pilot"): return candidate
	return -1

func _fallen_ids() -> Array:
	var ids: Array = []
	for entry in Array(_runtime.call("get_fallen")): ids.append(String(Dictionary(entry).get("unit_id", "")))
	return ids

## Schicksal einer Person nach den vorhandenen Regeln: "fallen" (Gefallenenliste), "absent" (nicht im Kader) oder ihr Verfuegbarkeitsstatus im Kader.
func _unit_fate(unit_id: String) -> String:
	if _fallen_ids().has(unit_id): return "fallen"
	var unit: Dictionary = _roster_unit(unit_id)
	return "absent" if unit.is_empty() else String(unit.get("availability_status", ""))

func _pilot_down() -> bool:
	var unit: Dictionary = _roster_unit("campaign_pilot")
	return String(unit.get("availability_status", "")) == "wounded" and String(Dictionary(unit.get("recovery_state", {})).get("severity", "")) == "severe" and float(Dictionary(unit.get("recovery_state", {})).get("seconds_remaining", 0.0)) > 0.0

func _unit_is_dead(unit_id: String) -> bool:
	return _unit_fate(unit_id) in ["fallen", "absent", "dead", "respawning", "awaiting_pickup"]

func _c_full_path() -> void:
	var s: Dictionary = await _begin_funded_sortie(500)
	if s.is_empty(): return
	var mission: Node = s.mission
	var controller: Node = s.controller
	var sim: Node = s.simulation
	controller.call("_refresh_mission_dropship_panel")
	var details: Button = mission.get_node_or_null("TacticalUI/MissionDropshipPanel/CompactCard/Contents/Header/DetailsButton")
	if not _check(details != null and not details.disabled, "C: Details-Knopf der Schiffskarte ist da"): return
	details.pressed.emit()
	await process_frame
	var pilot_button: Button = _air_button(mission, "air_pilot_board")
	if not _check(pilot_button != null and not pilot_button.disabled, "C: Knopf 'Pilot an Bord' ist da"): return
	pilot_button.pressed.emit()
	if not await _wait(func(): return controller.call("get_campaign_air_support_pilot_guard", _craft_id).get("ok", false), 8000, "C: Pilot ist an Bord"): return
	var start_button: Button = _air_button(mission, "air_start")
	if not _check(start_button != null and not start_button.disabled and start_button.is_visible_in_tree(), "C: Start-Knopf ist sichtbar und nutzbar"): return
	start_button.pressed.emit()
	if not _check(bool(sim.call("is_air_support_craft_airborne", _craft_id)), "C: das Schiff fliegt"): return
	var targets: Array = Array(sim.call("get_air_support_threat_targets"))
	if not _check(targets.size() == 1, "C: genau ein Schiff in der Luft ist Ziel (%d)" % targets.size()): return
	var skill: float = float(Dictionary(targets[0]).get("pilot_skill", 0.0)) if bool(Dictionary(targets[0]).get("pilot_known", false)) else 0.0
	var seed_value: int = _seed_pilot_dies(skill)
	if not _check(seed_value > 0, "C: fester Zufallsstart gefunden (%d)" % seed_value): return
	sim.set("_air_ground_rng_state", seed_value)
	# Bodenbeschuss: zwei Raketenwerfer treffen jedes Mal; jeder Treffer kostet Rumpf, bis er 0 erreicht (Abschuss genau einmal).
	var module = GFA_SCRIPT.new()
	var shooters: Array = [{"id": "gfa_a"}, {"id": "gfa_b"}]
	var resolved: Dictionary = {}
	var tick: int = int(sim.get("tick_counter"))
	var steps := 0
	while resolved.is_empty() and steps < 4000:
		steps += 1
		tick += 1
		var list: Array = Array(sim.call("get_air_support_threat_targets"))
		if list.is_empty(): break
		for index in range(list.size()):
			var entry: Dictionary = Dictionary(list[index])
			entry["display_name"] = String(Dictionary(controller.call("_find_mission_dropship_card_entry", String(entry.get("craft_id", "")))).get("display_name", _craft_id))
			list[index] = entry
		var out: Dictionary = module.step({"tick": tick, "targets": list, "shooters": shooters, "id_of": Callable(self, "_gid"), "weapon_of": Callable(self, "_gweapon"),
			"is_fit": Callable(self, "_gfit"), "has_ground_contact": Callable(self, "_gcontact"), "sees": Callable(self, "_gsees"), "roll": Callable(self, "_groll")})
		var down: Dictionary = {}
		for shot in Array(out.get("shootdowns", [])): down[String(Dictionary(shot).get("craft_id", ""))] = Dictionary(shot)
		for craft_id in out.updates.keys():
			var update: Dictionary = Dictionary(out.updates[craft_id])
			if down.has(craft_id):
				resolved = Dictionary(sim.call("resolve_air_shootdown", craft_id, float(Dictionary(down[craft_id]).get("pilot_skill", 0.0)), String(Dictionary(list[0]).get("display_name", _craft_id)), Dictionary(update.get("snapshot", {}))))
			elif not Dictionary(update.get("effect", {})).is_empty():
				sim.call("enqueue_effect", Dictionary(update.effect))
		await physics_frame
	print("C_SHOOTDOWN steps=", steps, " resolved=", resolved)
	if not _check(bool(resolved.get("ok", false)) and String(resolved.get("outcome", "")) in ["crash", "explosion"], "C: Bodenbeschuss bringt den Rumpf auf 0, die Root wuerfelt einen Schiffsverlust (%s)" % str(resolved.get("outcome", resolved))): return
	_check(bool(sim.call("is_air_craft_crashed", _craft_id)) and not bool(sim.call("is_air_support_craft_airborne", _craft_id)), "C: Absturzstelle steht in der Root, das Schiff ist nicht mehr in der Luft")
	var dead_ids: Array = []
	var crash_results: Dictionary = Dictionary(resolved.get("results", {}))
	for id in crash_results:
		if String(Dictionary(crash_results[id]).get("state", "")) == "dead":
			dead_ids.append(String(id))
	_check(dead_ids == ["campaign_pilot"], "C: der Pilot ist beim Absturz gestorben, der Trupp am Boden lebt (%s)" % str(dead_ids))
	s.driver.call("_resolve_combat", "aborted", "", "evacuation")
	if not await _wait_released("C: Einsatz wird freigegeben"): return
	var loss: Dictionary = Dictionary(Dictionary(_flow.get("_last_mission_result")).get("craft_loss", {}))
	_check(String(loss.get("craft_id", "")) == _craft_id and int(loss.get("rescue_fee", -1)) == 400 and _credits() == 100, "C: Notrettung 400 gebucht, Guthaben 100 (%s / %d)" % [str(loss), _credits()])
	_check(not bool(Dictionary(_flow.get("_last_mission_result")).get("casualty_total_loss", false)), "C: kein Totalverlust (der Anfuehrer lebt)")
	var c_result: Dictionary = Dictionary(_flow.get("_last_mission_result"))
	# Der beim Absturz Gestorbene kommt NICHT fit heim: Nach den bestehenden Regeln (Todesschutz beim ersten Tod) steht er als schwer verwundet in der
	# Erholung (casualties: killed_in_crash, protected_from_death), gaelte kein Schutz, waere er gefallen. Der Anfuehrer ist unversehrt.
	var casualty: Dictionary = {}
	for entry in Array(c_result.get("casualties", [])):
		if String(Dictionary(entry).get("unit_id", "")) == "campaign_pilot": casualty = Dictionary(entry)
	_check(not casualty.is_empty() and String(casualty.get("severity", "")) == "severe" and bool(casualty.get("protected_from_death", false)), "C: Pilot beim Absturz gestorben: bestehende Regel (Todesschutz) bucht ihn schwer verwundet (%s)" % str(casualty))
	_check(_pilot_down() and not _unit_is_dead("campaign_leader") and String(_roster_unit("campaign_leader").get("availability_status", "")) == "active", "C: Pilot in der Erholung, Anfuehrer einsatzbereit (%s / %s)" % [_unit_fate("campaign_pilot"), _unit_fate("campaign_leader")])
	_check(not _fleet_ids().has(_craft_id) and bool(Dictionary(_runtime.call("get_world_checkpoint_guard")).get("ok", false)), "C: Schiff nicht mehr in der Flotte, Basisspeicherstand schreibbar")
	var saved: Dictionary = {}
	await _wait(func():
		saved.clear()
		saved.merge(Dictionary(_flow.call("request_campaign_save")))
		return bool(saved.get("ok", false)), 60000, "C: Speichern nach Heimkehr gelingt")
	var disk: Dictionary = _disk()
	_check(Array(disk.get("fleet", [1])).is_empty() and Array(disk.get("lost_craft", [])).size() == 1 and _disk_credits() == 100, "C: Stand traegt leere Flotte, ein Verlustbeleg, Guthaben 100 (%d)" % _disk_credits())
	await _close()
	if not await _open_scene("campaign", "continue_home"): return
	_check(_fleet_ids().is_empty() and _credits() == 100 and _pilot_down() and String(_roster_unit("campaign_leader").get("availability_status", "")) == "active", "C: Laden: Flotte leer, Guthaben 100, Pilot weiter in der Erholung, Anfuehrer einsatzbereit (%s / %d / %s / %s)" % [str(_fleet_ids()), _credits(), _unit_fate("campaign_pilot"), _unit_fate("campaign_leader")])
	await _close()

func _fleet_ids() -> Array:
	var ids: Array = []
	for definition in Array(_flow.get("_homebase_aircraft_definitions")): ids.append(String(Dictionary(definition).get("craft_id", "")))
	return ids

func _l4_no_loss() -> void:
	var s: Dictionary = await _begin_funded_sortie(500)
	if s.is_empty(): return
	if not _seat_crew(s): return
	s.driver.call("_resolve_combat", "victory", String(s.driver.get("friendly_team_id")))
	if not await _wait_released("L4: Einsatz wird freigegeben"): return
	var result: Dictionary = Dictionary(_flow.get("_last_mission_result"))
	_check(not result.has("craft_loss") and _credits() == 500, "L4: ohne Schiffsverlust kein Verlustbeleg, keine Notrettung (%d)" % _credits())
	await _end_sortie()
