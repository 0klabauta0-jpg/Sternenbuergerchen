extends "res://scripts/tests/campaign_total_loss_penalty_verifier.gd"
## LC2c: Einsatzende nach Schiffsverlust, durch den echten Kampagnenfluss (Meta-Szene, echter Einsatz, echtes Einsatzende).
## Das Schiff ist durch Bodenbeschuss verloren (Absturzstelle in der SimulationRoot; der Luftkampf selbst ist in air_shootdown_verifier geprueft).
## K1: das Einsatzende haengt nie (hoechstens ein Eintrag in _pending_campaign_mission_result, dann leer).
## L1 Sieg: Ergebnis bleibt Sieg, Notrettung (400 Credits) gebucht, kein Totalverlust, kein Rueckfall, Belohnung/Abschluss wie gewohnt.
## L2 Abbruch (Evakuieren): dasselbe, Ergebnis bleibt abgebrochen.
## L3 beim Absturz Gestorbener: tot (Respawn-Quelle crash), die anderen leben; Stand speichern und laden besteht.
## L4 Gegenprobe: kein Schiffsverlust (Notlandung) -> kein Verlustbeleg, keine Notrettung.

func _run() -> void:
	_configure_entry()
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
