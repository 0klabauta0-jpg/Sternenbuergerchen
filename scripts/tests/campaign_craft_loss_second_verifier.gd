extends "res://scripts/tests/campaign_craft_loss_flow_verifier.gd"
## LC2g Punkt 1 (W3): Abschuss eines Schiffs, das NICHT das Einsatzschiff ist, ueber den echten Kampagnenfluss (Meta-Szene, echter Einsatz).
## Das zweite Schiff ist ein Kaufschiff (Beleg im Versorgungsstand, Heimlandeplatz 3); sein Absturz steht in der SimulationRoot wie beim Einsatzschiff.
## S1: nur das zweite Schiff wird abgeschossen -> der Einsatz endet normal mit dem ersten (keine Notrettung, keine Gebuehr), das zweite ist aus der
##     Flotte, sein Verlustbeleg ist da, niemand ist "an Bord" eines fehlenden Schiffs, Speichern und Laden gelingen.
## S2: beide werden abgeschossen -> fuer das Einsatzschiff gilt die Notrettung (Gebuehr 400), das andere wird geraeumt; beide Belege da.

func _run() -> void:
	_configure_entry()
	await _s1_second_craft_shot_down()
	await _s2_both_shot_down()
	await _s3_both_lost_is_total_loss()
	print("CAMPAIGN_CRAFT_LOSS_SECOND passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _site(s: Dictionary, craft_id: String, outcome: String = "crash") -> void:
	var sites: Array = s.simulation.get("_air_crash_sites")
	sites.append({"craft_id": craft_id, "model_id": "cutlass", "grid": Vector2i.ZERO, "outcome": outcome})

func _lost_ids() -> Array:
	var ids: Array = []
	for entry in Array(_flow.get("_lost_craft_records")): ids.append(String(Dictionary(entry).get("craft_id", "")))
	ids.sort()
	return ids

func _aboard_ids(craft_id: String) -> Array:
	var aboard: Array = []
	var states: Dictionary = _runtime.call("get_base_personnel_runtime").get("_states")
	for id in states:
		if String(states[id].get("craft_id", "")) == craft_id: aboard.append(String(id))
	return aboard

func _s1_second_craft_shot_down() -> void:
	var s: Dictionary = await _begin_funded_sortie(500)
	if s.is_empty(): return
	var second := _inject_bought_ship()
	_check(_fleet_ids().has(second) and _fleet_ids().has(_craft_id), "S1: Aufbau: zwei Schiffe in der Flotte (%s)" % str(_fleet_ids()))
	_site(s, second)
	if not _seat_crew(s): return
	# Abbruch (Evakuieren) mit dem ersten Schiff: der Auftrag wird wieder geoeffnet (ein "Sieg" liesse ihn aktiv, Speichern gesperrt).
	s.driver.call("_resolve_combat", "aborted", "", "evacuation")
	if not await _wait_released("S1: Einsatz wird freigegeben"): return
	var result: Dictionary = Dictionary(_flow.get("_last_mission_result"))
	_check(not result.has("craft_loss") and not bool(result.get("casualty_total_loss", false)), "S1: das Einsatzschiff ist nicht verloren: keine Notrettung, kein Totalverlust")
	_check(_credits() == 500, "S1: keine Rettungsgebuehr fuer das zweite Schiff (%d)" % _credits())
	_check(_fleet_ids() == [_craft_id], "S1: das zweite Schiff ist aus der Flotte, das Einsatzschiff bleibt (%s)" % str(_fleet_ids()))
	_check(_lost_ids() == [second], "S1: Verlustbeleg fuer das zweite Schiff (%s)" % str(_lost_ids()))
	_check(not Dictionary(_flow.get("_aircraft_location_by_craft")).has(second) and not Dictionary(_runtime.get("_pad_by_craft")).has(second), "S1: kein Ort und kein Landeplatz mehr fuer das zweite Schiff")
	_check(_aboard_ids(second).is_empty(), "S1: niemand ist an Bord eines Schiffs, das es nicht mehr gibt")
	# Die Heimkehr des ersten Schiffs (Abheben, Rueckflug) ist nicht Gegenstand dieses Pruefers: hier steht es per frischem Reiseeigner wieder am
	# Boden der Basis. Danach darf NICHTS mehr "unterwegs" melden - ein haengendes zweites Schiff taete es (world_active).
	var travel: RefCounted = _runtime.get("_travel")
	travel.call("unregister_craft", _craft_id)
	travel.call("register_craft", _craft_id)
	Dictionary(_flow.get("_aircraft_location_by_craft"))[_craft_id] = "homebase"
	Dictionary(_flow.get("_craft_location_runtime")).erase(_craft_id)
	var guard: Dictionary = _runtime.call("get_world_checkpoint_guard")
	_check(bool(guard.get("ok", false)), "S1: kein dauerhaftes world_active, Basisspeicherstand schreibbar (%s)" % str(guard.get("reason", "")))
	var saved: Dictionary = {}
	var saved_ok: bool = await _wait(func():
		saved.clear()
		saved.merge(Dictionary(_flow.call("request_campaign_save")))
		return bool(saved.get("ok", false)), 60000, "S1: Speichern gelingt")
	if not saved_ok:
		print("S1_SAVE_LAST ", saved)
		return
	var disk: Dictionary = _disk()
	var disk_fleet: Array = []
	for ship in Array(disk.get("fleet", [])): disk_fleet.append(String(Dictionary(Dictionary(ship).get("definition", {})).get("craft_id", "")))
	var disk_lost: Array = []
	for entry in Array(disk.get("lost_craft", [])): disk_lost.append(String(Dictionary(entry).get("craft_id", "")))
	_check(disk_fleet == [_craft_id] and disk_lost == [second], "S1: Stand traegt das Einsatzschiff und den Beleg des zweiten (%s / %s)" % [str(disk_fleet), str(disk_lost)])
	await _close()
	if not await _open_scene("campaign", "continue_home"): return
	_check(_fleet_ids() == [_craft_id] and _lost_ids() == [second], "S1: Laden: Einsatzschiff da, zweites weg, Beleg da (%s / %s)" % [str(_fleet_ids()), str(_lost_ids())])
	_check(_aboard_ids(second).is_empty(), "S1: Laden: niemand an Bord des zweiten Schiffs")
	await _wait(func(): return bool(Dictionary(_flow.call("request_campaign_save")).get("ok", false)), 60000, "S1: nach dem Laden ist wieder Speichern moeglich")
	await _close()

func _s2_both_shot_down() -> void:
	var s: Dictionary = await _begin_funded_sortie(500)
	if s.is_empty(): return
	var second := _inject_bought_ship()
	var third := _inject_bought_ship("2", "Drittschiff") # LC2i: bleibt als Reserve; beide zu verlieren waere sonst der Totalverlust (S3)
	_site(s, _craft_id)
	_site(s, second, "explosion")
	s.driver.call("_resolve_combat", "aborted", "", "evacuation")
	if not await _wait_released("S2: Einsatz wird freigegeben"): return
	var result: Dictionary = Dictionary(_flow.get("_last_mission_result"))
	var loss: Dictionary = Dictionary(result.get("craft_loss", {}))
	_check(String(loss.get("craft_id", "")) == _craft_id and int(loss.get("rescue_fee", -1)) == 400 and _credits() == 100, "S2: Einsatzschiff: Notrettung 400, Guthaben 100 (%s / %d)" % [str(loss), _credits()])
	var expected: Array = [_craft_id, second]
	expected.sort()
	_check(_lost_ids() == expected and _fleet_ids() == [third], "S2: beide Belege da, nur die Reserve bleibt (%s / %s)" % [str(_lost_ids()), str(_fleet_ids())])
	_check(_aboard_ids(second).is_empty() and _aboard_ids(_craft_id).is_empty(), "S2: niemand an Bord eines verlorenen Schiffs")
	var saved: Dictionary = {}
	var saved_ok: bool = await _wait(func():
		saved.clear()
		saved.merge(Dictionary(_flow.call("request_campaign_save")))
		return bool(saved.get("ok", false)), 60000, "S2: Speichern gelingt")
	if not saved_ok:
		print("S2_SAVE_LAST ", saved)
		return
	var disk_lost: Array = []
	for entry in Array(_disk().get("lost_craft", [])): disk_lost.append(String(Dictionary(entry).get("craft_id", "")))
	disk_lost.sort()
	_check(disk_lost == expected and _disk_fleet_ids(_disk()) == [third], "S2: Stand traegt beide Belege und die Reserve (%s)" % str(disk_lost))
	await _close()
	if not await _open_scene("campaign", "continue_home"): return
	_check(_fleet_ids() == [third] and _lost_ids() == expected and _credits() == 100, "S2: Laden: nur die Reserve, beide Belege, Guthaben 100 (%s / %s / %d)" % [str(_fleet_ids()), str(_lost_ids()), _credits()])
	await _close()

## S3 (LC2i I1): beide Schiffe der Flotte werden abgeschossen -> das ist der Totalverlust: Stand vor dem Einsatz mit beiden Schiffen, Strafe, keine
## Notrettungsgebuehr dazu, kein Verlustbeleg, kein Pleite-Bildschirm.
func _s3_both_lost_is_total_loss() -> void:
	var s: Dictionary = await _begin_funded_sortie(500)
	if s.is_empty(): return
	var second := _inject_bought_ship()
	_site(s, _craft_id)
	_site(s, second, "explosion")
	s.driver.call("_resolve_combat", "aborted", "", "evacuation")
	if not await _wait_released("S3: Einsatz wird freigegeben"): return
	var result: Dictionary = Dictionary(_flow.get("_last_mission_result"))
	_check(bool(result.get("casualty_total_loss", false)) and String(result.get("total_loss_reason", "")) == "last_craft_lost" and not result.has("craft_loss"), "S3: Totalverlust, Grund last_craft_lost, keine Notrettungsgebuehr (%s)" % str(result.get("total_loss_reason")))
	_check(_lost_ids().is_empty() and _fleet_ids().has(_craft_id) and _fleet_ids().has(second), "S3: kein Verlustbeleg, beide Schiffe stehen noch in der Flotte (%s / %s)" % [str(_lost_ids()), str(_fleet_ids())])
	_flow.call("_check_bankruptcy")
	await process_frame
	_check(_flow.get_node_or_null("CampaignBankruptcyScreen") == null, "S3: kein Pleite-Bildschirm")
	if not await _press_continue(): return
	# Der Stand vor dem Einsatz kennt nur das Einsatzschiff (das zweite wurde erst im Einsatz hinzugelegt).
	_check(_fleet_ids() == [_craft_id] and _credits() == 100, "S3: nach dem Ruecksprung der Flottenstand vor dem Einsatz, Strafe 500 -> 100 (%s / %d)" % [str(_fleet_ids()), _credits()])
	var saved: Dictionary = {}
	await _wait(func():
		saved.clear()
		saved.merge(Dictionary(_flow.call("request_campaign_save")))
		return bool(saved.get("ok", false)), 60000, "S3: Speichern nach dem Ruecksprung gelingt")
	await _close()
