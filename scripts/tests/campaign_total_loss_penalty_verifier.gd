extends "res://scripts/tests/campaign_casualty_departure_verifier.gd"
## Task 5b (Ausfall und Rueckzug): Malus bei Totalverlust (Notbergung).
## P1 echter Einsatz, Totalverlust am Missionsende: 500 -> 375 Credits, leicht verwundet (180 s), Moral -0,08, Ergebnis mit total_loss_penalty.
## P2 Neuaufbau und Fortsetzen (zweimal): Guthaben, Restzeit und Moral aendern sich nicht mehr.
## P3 mehrfache Zustellung des Ergebnisses und mehrfaches Bestaetigen des Debriefs: kein zweiter Abzug.
## P4 Grenzen: 120 -> Gebuehr 50, 30 -> 30, 0 -> 0, kein negatives Guthaben.
## P5 Totalverlust beim Abflug (HUD-Weg): derselbe Malus genau einmal (lang, siehe T5B_ONLY).
## P6 Gegenproben: gewoehnliche Niederlage, Sieg, Rueckzug, Skirmish: kein Malus.
## P7 schon schwer verwundet (2000 s): bleibt schwer mit 2000 s (nie kuerzer, nie leichter).
## P9 Zusatzdatei: veraltet -> ohne Wirkung geloescht, neue Kampagne loescht sie, Checkpoint beim Totalverlust unberuehrt.
## (Der Fall "Abbruch nach dem Speichern, vor dem Loeschen" und "Fenster" laufen im echten Einsatz von P1/P2/P3.)
## P8 Debrief: Zeile "Notbergung · <Betrag> Credits Bergungsgebuehr" nur mit total_loss_penalty.
## Einzeln starten: Umgebungsvariable T5B_ONLY (zum Beispiel "P4" oder "P1,P7") oder Kommandozeilenargument nach "--"; ohne Angabe laufen alle.

const LEADER := "campaign_leader"
const PILOT := "campaign_pilot"
const DEBRIEF_RETURN_BUTTON := "DebriefScreen/Panel/Margin/VBox/ButtonRow/ReturnToHomebaseButton"
const PENALTY_LINE_PREFIX := "Notbergung · "

func _run() -> void:
	_configure_entry()
	var selected: Array = _selected_scenarios()
	if _wants(selected, ["P4"]):
		await _p4_limits()
	if _wants(selected, ["P9"]):
		await _p9_stale_and_new_campaign()
	if _wants(selected, ["P7"]):
		await _p7_already_wounded()
	if _wants(selected, ["P8"]):
		await _p8_debrief()
	if _wants(selected, ["P6"]):
		await _p6_direct_negatives()
	if _wants(selected, ["P1", "P2", "P3"]):
		await _p1_p2_p3_real_total_loss()
	if _wants(selected, ["P6"]):
		await _p6_real_defeat()
		await _p6_real_victory()
	if _wants(selected, ["P5"]):
		await _p5_departure_total_loss()
	print("CAMPAIGN_TOTAL_LOSS_PENALTY passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _selected_scenarios() -> Array:
	var result: Array = []
	for part: String in OS.get_environment("T5B_ONLY").split(","):
		var tag: String = part.strip_edges().to_upper()
		if not tag.is_empty():
			result.append(tag)
	for arg: String in OS.get_cmdline_user_args():
		var upper: String = arg.strip_edges().to_upper()
		if upper.begins_with("P"):
			result.append(upper)
	return result

func _wants(selected: Array, tags: Array) -> bool:
	if selected.is_empty():
		return true
	for tag: String in tags:
		if selected.has(tag):
			return true
	return false

# ---------- Hilfen ----------

func _open_scene(mode: String, action: String) -> bool:
	START.request_start(self, mode, action)
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	return _check(_runtime != null, "%s/%s: Meta-Szene und Laufzeit sind da" % [mode, action])

func _close() -> void:
	if _flow != null and is_instance_valid(_flow):
		_flow.queue_free()
	await process_frame

func _credits() -> int:
	return int(_runtime.call("get_campaign_credits"))

## Nur Pruefaufbau: setzt das Guthaben am Besitzer, damit der Basisstand eine bekannte Summe traegt.
func _set_credits(amount: int) -> void:
	_runtime.get("_supply").set("_credits", amount)

func _disk() -> Dictionary:
	var loaded: Dictionary = STORE.load_checkpoint()
	return Dictionary(loaded.get("payload", {})) if bool(loaded.get("ok", false)) else {}

func _disk_credits() -> int:
	return int(Dictionary(_disk().get("supply", {})).get("credits", -1))

func _save_base(label: String) -> bool:
	var saved: Dictionary = _flow.call("request_campaign_save")
	return _check(bool(saved.get("ok", false)), "%s: Basisstand gespeichert (%s)" % [label, saved.get("reason", "")])

func _remaining(unit_id: String) -> float:
	return float(Dictionary(_roster_unit(unit_id).get("recovery_state", {})).get("seconds_remaining", -1.0))

func _recovery(unit_id: String) -> Dictionary:
	return Dictionary(_roster_unit(unit_id).get("recovery_state", {}))

func _morale(unit_id: String) -> float:
	return float(Dictionary(_roster_unit(unit_id).get("progression", {})).get("morale", 0.5))

func _disk_morale(unit_id: String) -> float:
	for unit: Dictionary in Array(_disk().get("roster", [])):
		if String(unit.get("unit_id", "")) == unit_id:
			return float(Dictionary(unit.get("progression", {})).get("morale", 0.5))
	return -1.0

func _lock() -> Dictionary:
	var base: Node = _runtime.call("get_base_personnel_runtime")
	return Dictionary(base.get("_unavailable_unit_reasons")).duplicate(true) if base != null else {}

func _loss_result() -> Dictionary:
	return {"result": "defeat", "mission_outcome": "defeat", "casualty_total_loss": true, "total_loss_reason": "ground_team_down",
		"team_states": [_state(LEADER, "down", false, true), _state(PILOT, "fit", false)]}

## Kennung aus der Zusatzdatei neben dem Checkpoint ("" ohne Datei).
func _pending_id() -> String:
	var pending: Dictionary = STORE.load_pending_total_loss()
	return String(Dictionary(pending.get("record", {})).get("loss_id", "")) if bool(pending.get("ok", false)) else ""

func _pending_exists() -> bool:
	return FileAccess.file_exists(STORE.PENDING_TOTAL_LOSS_PATH)

func _write_bytes(path: String, bytes: PackedByteArray) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()

func _campaign_job() -> Dictionary:
	return Dictionary(_campaign().jobs.get("satellite_recovery", {}))

## Drueckt den Fortsetzen-Knopf des Debriefs und wartet auf die neue Meta-Szene.
func _press_continue() -> bool:
	var old_flow: Node = _flow
	var button: Button = _flow.get_node(DEBRIEF_RETURN_BUTTON)
	# Ein Druck genuegt: der erste Aufruf tauscht die Szene aus, ein zweiter Druck im selben Bild fiele ins Leere.
	# Das mehrfache Bestaetigen wird ueber wiederholtes Laden des Standes (continue_home, continue) geprueft.
	button.pressed.emit()
	await process_frame
	await process_frame
	await process_frame
	if not _check(current_scene != null and current_scene != old_flow, "Fortsetzen: neue Meta-Szene ist da"):
		return false
	_flow = current_scene
	for i in range(30):
		if _flow.get("_singleplayer_runtime") != null:
			break
		await process_frame
	_runtime = _flow.get("_singleplayer_runtime")
	_screen = _flow.get_node("HomebaseScreen")
	await process_frame
	return _check(_runtime != null, "Fortsetzen: Laufzeit der neuen Szene ist da")

## Einsatz bis zum gelandeten Trupp, Guthaben vorher im Basisstand gesetzt.
func _begin_funded_sortie(credits: int) -> Dictionary:
	START.request_start(self, "campaign", "new")
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	_set_credits(credits)
	if not _save_base("Einsatz-Aufbau"): return {}
	if not _check(_disk_credits() == credits, "Einsatz-Aufbau: Basisstand traegt %d Credits (%d)" % [credits, _disk_credits()]): return {}
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
		"leader": controller.call("_get_campaign_sortie_unit", LEADER),
		"pilot": controller.call("_get_campaign_sortie_unit", PILOT),
		"access": controller.call("get_campaign_ground_ship_access", _craft_id),
	}
	if not _check(sortie.leader != null and sortie.pilot != null and bool(sortie.access.get("ok", false)), "Beide Personen und der Schiffszugang sind da"): return {}
	return sortie

func _down_leader(s: Dictionary, tag: String) -> bool:
	s.leader.call("apply_damage", 10000)
	return await _wait(func(): return bool(Dictionary(s.driver.call("get_casualty_flags")).get(LEADER, {}).get("was_downed", false)), 5000, tag + ": Treiber merkt sich die ausgefallene Person")

# ---------- P1 + P3 + P2: echter Totalverlust ----------

func _p1_p2_p3_real_total_loss() -> void:
	var s: Dictionary = await _begin_funded_sortie(500)
	if s.is_empty(): return
	var morale_before: Dictionary = {LEADER: _disk_morale(LEADER), PILOT: _disk_morale(PILOT)}
	var retreat_before: int = int(_campaign_job().get("retreat_count", 0))
	if not await _down_leader(s, "P1"): return
	if not _place_at(s.simulation, s.access, LEADER, Vector2.ZERO): return
	if not _place_at(s.simulation, s.access, PILOT, Vector2.ZERO): return
	var checkpoint_before: PackedByteArray = FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH)
	s.driver.call("_resolve_combat", "aborted", "", "evacuation")
	if not await _wait_released("P1: Einsatz wird freigegeben"): return
	var result: Dictionary = Dictionary(_flow.get("_last_mission_result")).duplicate(true)
	_check(FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH) == checkpoint_before and not checkpoint_before.is_empty(), "P1: die Checkpoint-Datei ist nach dem Totalverlust Byte fuer Byte dieselbe wie davor")
	var penalty: Dictionary = Dictionary(result.get("total_loss_penalty", {}))
	print("P1_RESULT total_loss=", result.get("casualty_total_loss"), " penalty=", penalty, " pending=", _pending_id(), " disk_credits=", _disk_credits())
	_check(bool(result.get("casualty_total_loss", false)) and bool(result.get("campaign_checkpoint_retry_required", false)), "P1: Totalverlust mit Checkpoint-Retry")
	_check(result.get("total_loss_penalty") is Dictionary and int(penalty.get("rescue_fee", -1)) == 125, "P1: Ergebnis traegt total_loss_penalty mit rescue_fee 125")
	_check(is_equal_approx(float(penalty.get("morale_delta", 0.0)), -0.08), "P1: morale_delta ist -0,08")
	var wounded_ids: Array = []
	for entry: Dictionary in Array(penalty.get("wounded", [])):
		wounded_ids.append(String(entry.get("unit_id", "")))
	_check(wounded_ids == [LEADER], "P1: wounded nennt genau den Truppfuehrer (%s)" % [wounded_ids])
	var morale_ids: Array = []
	for raw_id in Array(penalty.get("morale_unit_ids", [])):
		morale_ids.append(String(raw_id))
	morale_ids.sort()
	_check(morale_ids == [LEADER, PILOT], "P1: morale_unit_ids nennt beide Beteiligten (%s)" % [morale_ids])
	_check(String(_flow.get("_current_meta_view")) == "debrief", "P1: Debrief ist sichtbar")
	var job: Dictionary = _campaign_job()
	_check(String(job.get("status", "")) == "failed" and int(job.get("retreat_count", 0)) == retreat_before and not bool(job.get("reopen_at_home", false)), "P1: Auftrag failed, retreat_count unveraendert (%d), nicht wieder geoeffnet" % retreat_before)
	_check(_disk_credits() == 500 and not _pending_id().is_empty(), "P1: Die Zusatzdatei traegt schon den ausstehenden Malus (Kennung), der Basisstand noch 500 Credits")
	var loss_id: String = _pending_id()
	# P3: mehrfache Zustellung und mehrfaches Bestaetigen.
	var roster_before: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	_flow.call("_on_mission_combat_resolved", {"result": "defeat"})
	_flow.call("_on_mission_combat_resolved", result.duplicate(true))
	await process_frame
	_check(_pending_id() == loss_id and _disk_credits() == 500, "P3: erneute Zustellung aendert Kennung und Basisstand nicht")
	_check(Array(_flow.get("_all_team_units")) == roster_before and Dictionary(_flow.get("_last_mission_result")).get("total_loss_penalty") == penalty, "P3: erneute Zustellung aendert Kader und Ergebnis nicht")
	var pending_bytes: PackedByteArray = FileAccess.get_file_as_bytes(STORE.PENDING_TOTAL_LOSS_PATH)
	_check(not pending_bytes.is_empty(), "P1: Zusatzdatei vorhanden")
	if not await _press_continue(): return
	# Nach dem Ruecksprung.
	var job_after: Dictionary = _campaign_job()
	print("P1_AFTER credits=", _credits(), " leader=", _recovery(LEADER), " morale=", _morale(LEADER), "/", _morale(PILOT), " job=", job_after.get("status"), " disk_credits=", _disk_credits(), " pending=", _pending_id())
	_check(_credits() == 375, "P1: nach Ruecksprung und Malus 375 Credits (%d)" % _credits())
	_check(_disk_credits() == 375 and _pending_id().is_empty(), "P1/P3: der Malus ist sofort gespeichert (Basisstand 375, nichts mehr ausstehend)")
	var leader_recovery: Dictionary = _recovery(LEADER)
	_check(String(_roster_unit(LEADER).get("availability_status", "")) == "wounded" and String(leader_recovery.get("severity", "")) == "light", "P1: Truppfuehrer ist leicht verwundet")
	_check(float(leader_recovery.get("seconds_remaining", -1.0)) > 170.0 and float(leader_recovery.get("seconds_remaining", -1.0)) <= 180.0 and is_equal_approx(float(leader_recovery.get("seconds_total", -1.0)), 180.0), "P1: 180 s (Rest %.2f)" % float(leader_recovery.get("seconds_remaining", -1.0)))
	_check(_lock().has(LEADER), "P1: Truppfuehrer ist fuer Einsaetze gesperrt")
	_check(String(_roster_unit(PILOT).get("availability_status", "")) != "wounded", "P1: der unversehrte Pilot ist nicht verwundet")
	for id: String in [LEADER, PILOT]:
		_check(is_equal_approx(_morale(id), clampf(float(morale_before[id]) - 0.08, 0.0, 1.0)), "P1: Moral von %s ist um 0,08 gesunken (%.3f -> %.3f)" % [id, float(morale_before[id]), _morale(id)])
	# P2: Neuaufbau und Fortsetzen, zweimal.
	await create_timer(3.0).timeout
	if not _save_base("P2"): return
	var remaining_first: float = _remaining(LEADER)
	var morale_after: Dictionary = {LEADER: _morale(LEADER), PILOT: _morale(PILOT)}
	_check(remaining_first < 180.0, "P2: die Restzeit laeuft herunter (%.2f)" % remaining_first)
	for round_number in range(2):
		await _close()
		if not await _open_scene("campaign", "continue"): return
		_check(_credits() == 375, "P2 (Runde %d): Guthaben bleibt 375 (%d)" % [round_number + 1, _credits()])
		var remaining_now: float = _remaining(LEADER)
		_check(remaining_now <= remaining_first + 0.001 and remaining_now >= remaining_first - 10.0 and remaining_now < 179.0, "P2 (Runde %d): Restzeit nicht neu gesetzt (%.2f nach %.2f)" % [round_number + 1, remaining_now, remaining_first])
		_check(String(_recovery(LEADER).get("severity", "")) == "light", "P2 (Runde %d): weiter leicht verwundet" % [round_number + 1])
		for id: String in [LEADER, PILOT]:
			_check(is_equal_approx(_morale(id), float(morale_after[id])), "P2 (Runde %d): Moral von %s unveraendert (%.3f)" % [round_number + 1, id, _morale(id)])
		_check(_disk_credits() == 375 and _pending_id().is_empty(), "P2 (Runde %d): Basisstand ohne ausstehenden Malus" % [round_number + 1])
		remaining_first = remaining_now
	# Der Debrief-Knopf laedt den Stand als continue_home: auch das wiederholte Bestaetigen zieht nichts mehr ab.
	await _close()
	if not await _open_scene("campaign", "continue_home"): return
	_check(_credits() == 375 and _disk_credits() == 375 and _pending_id().is_empty(), "P3: wiederholtes Laden als continue_home zieht nicht noch einmal ab (%d)" % _credits())
	_check(_remaining(LEADER) <= remaining_first + 0.001 and String(_recovery(LEADER).get("severity", "")) == "light" and is_equal_approx(_morale(LEADER), float(morale_after[LEADER])), "P3: continue_home setzt weder Restzeit noch Moral zurueck")
	await _close()
	var checkpoint_after: PackedByteArray = FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH)
	# Fenster: Spiel nach dem Totalverlust beendet, bevor der Debrief bestaetigt wurde. Checkpoint (wie davor) und Zusatzdatei
	# werden zurueckgespielt; das Fortsetzen wendet den Malus an (nicht umgehbar), danach nie wieder.
	_check(not _pending_exists(), "Fenster: nach dem Speichern ist die Zusatzdatei geloescht")
	_write_bytes(STORE.DEFAULT_PATH, checkpoint_before)
	_write_bytes(STORE.PENDING_TOTAL_LOSS_PATH, pending_bytes)
	_check(_pending_id() == loss_id and _disk_credits() == 500, "Fenster: Zusatzdatei und alter Basisstand zurueckgespielt (500 Credits)")
	if not await _open_scene("campaign", "continue"): return
	_check(_credits() == 375 and _disk_credits() == 375 and not _pending_exists(), "Fenster: Fortsetzen ohne Debrief-Knopf wendet den Malus an (375), Zusatzdatei geloescht")
	_check(String(_recovery(LEADER).get("severity", "")) == "light" and is_equal_approx(_remaining(LEADER), 180.0) and is_equal_approx(_morale(PILOT), 0.42), "Fenster: leicht verwundet mit 180 s, Moral 0,42")
	await _close()
	if not await _open_scene("campaign", "continue"): return
	_check(_credits() == 375, "Fenster: zweites Fortsetzen zieht nicht noch einmal ab (%d)" % _credits())
	await _close()
	# Abbruch nach dem Speichern, vor dem Loeschen: die Zusatzdatei liegt wieder neben dem NEUEN Stand und ist veraltet.
	_check(FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH) != checkpoint_before and not checkpoint_after.is_empty(), "Abbruch: der gespeicherte Stand hat einen anderen Inhalt als der alte")
	_write_bytes(STORE.PENDING_TOTAL_LOSS_PATH, pending_bytes)
	if not await _open_scene("campaign", "continue"): return
	_check(_credits() == 375 and _disk_credits() == 375, "Abbruch nach Speichern, vor Loeschen: kein zweiter Abzug (%d)" % _credits())
	_check(not _pending_exists(), "Abbruch: veraltete Zusatzdatei wurde ohne Wirkung geloescht")
	_check(is_equal_approx(_morale(PILOT), 0.42), "Abbruch: Moral nicht ein zweites Mal gesenkt")
	await _close()

# ---------- P9: Zusatzdatei veraltet / neue Kampagne ----------

func _p9_stale_and_new_campaign() -> void:
	if not await _open_scene("campaign", "new"): return
	_set_credits(500)
	if not _save_base("P9"): return
	var bytes_before: PackedByteArray = FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH)
	var staged: Dictionary = _flow.call("_stage_total_loss_penalty", _loss_result())
	_check(int(staged.get("rescue_fee", -1)) == 125 and _pending_exists(), "P9: Malus ausstehend in der Zusatzdatei")
	_check(FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH) == bytes_before, "P9: die Checkpoint-Datei bleibt Byte fuer Byte unveraendert")
	var staged_again: Dictionary = _flow.call("_stage_total_loss_penalty", _loss_result())
	_check(String(staged_again.get("loss_id", "x")) == String(staged.get("loss_id", "y")), "P9: derselbe verlorene Einsatz noch einmal: gleiche Kennung")
	# Der Stand wird danach neu gespeichert (andere Pruefsumme): die Zusatzdatei ist veraltet.
	_set_credits(400)
	if not _save_base("P9 neuer Stand"): return
	_check(_pending_exists(), "P9: die veraltete Zusatzdatei liegt noch da")
	await _close()
	if not await _open_scene("campaign", "continue"): return
	_check(_credits() == 400 and String(_roster_unit(LEADER).get("availability_status", "")) != "wounded", "P9: veraltete Zusatzdatei ohne Wirkung (400 Credits, niemand verwundet)")
	_check(not _pending_exists(), "P9: veraltete Zusatzdatei wurde geloescht")
	# Neue Kampagne loescht eine vorhandene Zusatzdatei.
	var staged_new: Dictionary = _flow.call("_stage_total_loss_penalty", _loss_result())
	_check(int(staged_new.get("rescue_fee", -1)) == 100 and _pending_exists(), "P9: neuer Malus (100) ausstehend")
	await _close()
	if not await _open_scene("campaign", "new"): return
	_check(not _pending_exists(), "P9: neue Kampagne loescht die Zusatzdatei")
	await _close()

# ---------- P4: Grenzen ----------

func _p4_limits() -> void:
	if not await _open_scene("campaign", "new"): return
	for spec: Array in [[120, 50, 70], [30, 30, 0], [0, 0, 0], [500, 125, 375]]:
		var credits: int = spec[0]
		_set_credits(credits)
		if not _save_base("P4/%d" % credits): return
		var staged: Dictionary = _flow.call("_stage_total_loss_penalty", _loss_result())
		_check(int(staged.get("rescue_fee", -1)) == int(spec[1]), "P4: %d Credits -> Gebuehr %d (%d)" % [credits, int(spec[1]), int(staged.get("rescue_fee", -1))])
		await _close()
		if not await _open_scene("campaign", "continue"): return
		_check(_credits() == int(spec[2]), "P4: %d Credits -> danach %d (%d)" % [credits, int(spec[2]), _credits()])
		_check(_credits() >= 0 and _disk_credits() == int(spec[2]) and _pending_id().is_empty(), "P4 (%d): nie negativ, gespeichert, nichts mehr ausstehend" % credits)
	await _close()

# ---------- P7: schon verwundet ----------

func _p7_already_wounded() -> void:
	if not await _open_scene("campaign", "new"): return
	_set_wounded(LEADER, "severe", 2400.0, 2000.0)
	_flow.call("_sync_wound_lock")
	_set_credits(500)
	if not _save_base("P7"): return
	var staged: Dictionary = _flow.call("_stage_total_loss_penalty", _loss_result())
	_check(int(staged.get("rescue_fee", -1)) == 125, "P7: Malus ist ausstehend")
	await _close()
	if not await _open_scene("campaign", "continue"): return
	var recovery: Dictionary = _recovery(LEADER)
	print("P7_AFTER ", recovery, " credits=", _credits())
	_check(_credits() == 375, "P7: Gebuehr abgezogen (375)")
	_check(String(recovery.get("severity", "")) == "severe" and float(recovery.get("seconds_remaining", -1.0)) <= 2000.0 and float(recovery.get("seconds_remaining", -1.0)) > 1980.0 and is_equal_approx(float(recovery.get("seconds_total", -1.0)), 2400.0), "P7: bleibt schwer mit etwa 2000 s, total 2400 (nie kuerzer, nie leichter)")
	_check(String(_roster_unit(LEADER).get("availability_status", "")) == "wounded", "P7: weiter wounded")
	await _close()

# ---------- P6: Gegenproben ----------

func _p6_direct_negatives() -> void:
	if not await _open_scene("campaign", "new"): return
	_set_credits(500)
	if not _save_base("P6 direkt"): return
	var bytes_before: PackedByteArray = FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH)
	var cases: Array = []
	var plain_defeat: Dictionary = _loss_result()
	plain_defeat["casualty_total_loss"] = false
	cases.append(["gewoehnliche Niederlage", plain_defeat])
	var without_flag: Dictionary = _loss_result()
	without_flag.erase("casualty_total_loss")
	cases.append(["Niederlage ohne Merker", without_flag])
	var retreat: Dictionary = _loss_result()
	retreat["casualty_total_loss"] = false
	retreat["result"] = "aborted"
	retreat["mission_outcome"] = "aborted"
	cases.append(["Rueckzug", retreat])
	var victory: Dictionary = _loss_result()
	victory["casualty_total_loss"] = false
	victory["result"] = "victory"
	victory["mission_outcome"] = "won"
	cases.append(["Sieg", victory])
	for entry: Array in cases:
		var staged: Dictionary = _flow.call("_stage_total_loss_penalty", entry[1])
		_check(staged.is_empty(), "P6: %s: kein Malus ausstehend" % entry[0])
	_check(FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH) == bytes_before and _pending_id().is_empty(), "P6: der Basisstand bleibt Byte fuer Byte unveraendert")
	await _close()
	if not await _open_scene("campaign", "continue"): return
	_check(_credits() == 500 and String(_roster_unit(LEADER).get("availability_status", "")) != "wounded", "P6: nach Fortsetzen weiter 500 Credits, niemand verwundet")
	await _close()
	# Skirmish.
	START.request_start(self, "skirmish", "new")
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	await process_frame
	var skirmish_bytes: PackedByteArray = FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH)
	var staged_skirmish: Dictionary = _flow.call("_stage_total_loss_penalty", _loss_result())
	_check(staged_skirmish.is_empty() and FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH) == skirmish_bytes, "P6: Skirmish: kein Malus, Basisstand der Kampagne unveraendert")
	_check(not bool(_flow.call("_apply_pending_total_loss_penalty")), "P6: Skirmish: nichts auszufuehren")
	await _close()

func _p6_real_defeat() -> void:
	var s: Dictionary = await _begin_funded_sortie(500)
	if s.is_empty(): return
	if not _seat_crew(s): return
	s.driver.call("_resolve_combat", "defeat", "enemy")
	if not await _wait_released("P6 Niederlage: Einsatz wird freigegeben"): return
	var result: Dictionary = Dictionary(_flow.get("_last_mission_result"))
	print("P6_DEFEAT_RESULT result=", result.get("result"), " total_loss=", result.get("casualty_total_loss"), " penalty=", result.get("total_loss_penalty"))
	_check(not bool(result.get("casualty_total_loss", false)), "P6 Niederlage: kein Totalverlust")
	_check(not result.has("total_loss_penalty") and _pending_id().is_empty() and _credits() == 500 and _disk_credits() == 500, "P6 Niederlage: kein Malus, nichts ausstehend, Guthaben 500")
	await _end_sortie()

func _p6_real_victory() -> void:
	var s: Dictionary = await _begin_funded_sortie(500)
	if s.is_empty(): return
	if not _seat_crew(s): return
	s.driver.call("_resolve_combat", "victory", String(s.driver.get("friendly_team_id")))
	if not await _wait_released("P6 Sieg: Einsatz wird freigegeben"): return
	var result: Dictionary = Dictionary(_flow.get("_last_mission_result"))
	_check(not bool(result.get("casualty_total_loss", false)), "P6 Sieg: kein Totalverlust")
	_check(not result.has("total_loss_penalty") and _pending_id().is_empty() and _credits() == 500, "P6 Sieg: kein Malus, nichts ausstehend, Guthaben 500")
	await _end_sortie()

# ---------- P5: Totalverlust beim Abflug (lang) ----------

func _p5_departure_total_loss() -> void:
	var s: Dictionary = await _begin_funded_sortie(500)
	if s.is_empty(): return
	if not await _down_leader(s, "P5"): return
	if not _seat_crew(s): return
	_press_return(true, s)
	if not await _wait(func(): return _flow.get("_active_mission") == null, 120000, "P5: Einsatz wird freigegeben"): return
	await process_frame
	var result: Dictionary = Dictionary(_flow.get("_last_mission_result")).duplicate(true)
	_check(bool(result.get("casualty_total_loss", false)), "P5: Totalverlust beim Abflug")
	_check(int(Dictionary(result.get("total_loss_penalty", {})).get("rescue_fee", -1)) == 125, "P5: Ergebnis traegt rescue_fee 125")
	_check(not _pending_id().is_empty() and _disk_credits() == 500, "P5: Malus ausstehend im Basisstand")
	if not await _press_continue(): return
	_check(_credits() == 375 and _disk_credits() == 375 and _pending_id().is_empty(), "P5: genau einmal abgezogen (375)")
	_check(String(_recovery(LEADER).get("severity", "")) == "light", "P5: Truppfuehrer leicht verwundet")
	await _close()

# ---------- P8: Debrief ----------

func _debrief_texts(debrief: Node) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for node: Node in debrief.find_children("*", "Label", true, false):
		parts.append(String((node as Label).text))
	return "\n".join(parts)

func _p8_debrief() -> void:
	if not await _open_scene("campaign", "new"): return
	var debrief: Node = _flow.call("_get_debrief_screen")
	var loss_without: Dictionary = {"result": "defeat", "mission_outcome": "defeat", "casualty_total_loss": true, "total_loss_reason": "ground_team_down", "campaign_checkpoint_retry_required": true}
	debrief.call("set_mission_result", loss_without.duplicate(true))
	var status: Label = debrief.find_child("ConfirmedConsequencesStatus", true, false)
	var text_without: String = status.text
	var all_without: String = _debrief_texts(debrief)
	_check(not all_without.contains("Notbergung"), "P8: Totalverlust ohne Feld: keine Notbergung-Zeile")
	var loss_with: Dictionary = loss_without.duplicate(true)
	loss_with["total_loss_penalty"] = {"rescue_fee": 125, "wounded": [{"unit_id": LEADER, "severity": "light"}], "morale_delta": -0.08, "morale_unit_ids": [LEADER, PILOT]}
	debrief.call("set_mission_result", loss_with)
	var text_with: String = status.text
	var line: String = PENALTY_LINE_PREFIX + "125 Credits Bergungsgebühr"
	print("P8_TEXT ", text_with.replace("\n", " | "))
	_check(_debrief_texts(debrief).contains(line), "P8: Totalverlust mit Feld zeigt '%s'" % line)
	_check(text_with == text_without + "\n" + line, "P8: sonst Zeichen fuer Zeichen wie vorher (nur die eine Zeile mehr)")
	debrief.call("set_mission_result", loss_without.duplicate(true))
	_check(status.text == text_without and not _debrief_texts(debrief).contains("Notbergung"), "P8: ohne Feld wieder genau der alte Text")
	var victory: Dictionary = {"result": "victory", "mission_outcome": "won", "casualty_total_loss": false, "casualties": []}
	debrief.call("set_mission_result", victory.duplicate(true))
	var all_victory: String = _debrief_texts(debrief)
	_check(not all_victory.contains("Notbergung"), "P8: Sieg: keine Notbergung-Zeile")
	var victory_with: Dictionary = victory.duplicate(true)
	victory_with["total_loss_penalty"] = {"rescue_fee": 125}
	debrief.call("set_mission_result", victory_with)
	_check(not _debrief_texts(debrief).contains("Notbergung"), "P8: Sieg mit Feld (nicht vorgesehen): keine Zeile, nur bei Totalverlust")
	await _close()
