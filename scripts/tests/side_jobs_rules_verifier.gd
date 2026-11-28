extends SceneTree
## Nebenauftraege N1, Teil 1: reine Regeln (Daten, Zustand, Spielstand). Keine Szene, kein Flug, kein Einsatz.
## Echte Daten (side_jobs.json) ueber den echten Befehlsweg; eigene kleine Definitionen fuer Fristen und Ruf-Grenzen.
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const COMMAND = preload("res://scripts/mission/singleplayer_campaign_command_contract.gd")
const JOBS = preload("res://scripts/mission/singleplayer_job_contract.gd")
const INVENTORY = preload("res://scripts/mission/inventory_transfer_contract.gd")
const STANDING = preload("res://scripts/core/standing_orders_state.gd")
const SIDE_IDS: Array = ["side_relay_silence", "side_farm_night_watch", "side_lab_cold_samples", "side_templer_volunteer"]
const CAMPAIGN_IDS: Array = ["satellite_recovery", "outpost_recovery", "benit_delivery", "outpost_chip_recovery", "buccaneer_rescue", "wreck_crater_salvage"]
var passed := 0
var failed := 0
var sequence := 0

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print(("PASS " if value else "FAIL ") + label)

func _cmd(owner: RefCounted, operation: String, payload: Dictionary, context: Dictionary = {}) -> Dictionary:
	sequence += 1
	return owner.apply_command(COMMAND.build_command(operation, payload, "sidejobs:%d" % sequence), context)

func _landing(owner: RefCounted, count: int = 1) -> void:
	for i in count:
		var result: Dictionary = owner.apply_command(COMMAND.build_command("home_landing", {}, "home_landing:%d" % (int(owner.get_campaign_snapshot().home_landings) + 1)))
		if not bool(result.get("ok", false)):
			print("home_landing abgelehnt: " + str(result))

func _owner(side_jobs: Variant = null) -> RefCounted:
	var owner: RefCounted = CAMPAIGN.new()
	var result: Dictionary = owner.configure({}, {}, true, side_jobs)
	_check(bool(result.get("ok", false)), "Fixture: configure ok (%s)" % str(result.get("reason", "")))
	return owner

func _job(owner: RefCounted, id: String) -> Dictionary:
	return Dictionary(owner.get_campaign_snapshot().jobs.get(id, {}))

func _avail(owner: RefCounted, id: String) -> Dictionary:
	return Dictionary(owner.get_job_availability(true).get(id, {}))

func _status(owner: RefCounted, id: String) -> String:
	return String(_job(owner, id).get("status", ""))

func _evidence(job: Dictionary, steps: Array = []) -> Dictionary:
	return {"scenario_id": job.scenario_id, "result": "victory", "mission_scenario_runtime_gates": {"all_gates_complete": true, "completed_step_ids": (steps if not steps.is_empty() else job.required_step_ids)}}

## Annehmen, Abflug binden, aktivieren (der echte Weg bis zum aktiven Auftrag).
func _start(owner: RefCounted, id: String) -> bool:
	var job: Dictionary = _job(owner, id)
	var dep := {"craft_id": "dropship_1", "origin_location_id": "homebase", "destination_location_id": job.location_id, "landing_pad_id": "homebase_pad_01", "job_id": id}
	var ok: bool = bool(_cmd(owner, "accept_job", {"job_id": id}).get("ok", false))
	ok = ok and bool(_cmd(owner, "bind_departure", dep, {"departure_authorized": true}).get("ok", false))
	ok = ok and bool(_cmd(owner, "activate_job", {"job_id": id, "craft_id": "dropship_1"}, {"departure_authorized": true}).get("ok", false))
	return ok

func _complete(owner: RefCounted, id: String) -> Dictionary:
	var job: Dictionary = _job(owner, id)
	return _cmd(owner, "complete_job", {"job_id": id, "craft_id": "dropship_1"}, {"runtime_evidence": _evidence(job)})

## Kampagnenauftrag ganz durchspielen (wie campaign_additive_jobs_verifier).
func _finish(owner: RefCounted, id: String) -> void:
	var job: Dictionary = _job(owner, id)
	var ok: bool = _start(owner, id)
	if id == "benit_delivery":
		ok = ok and bool(_cmd(owner, "deliver_crate", {}, {"runtime_authorized": true}).get("ok", false))
	ok = ok and bool(_complete(owner, id).get("ok", false))
	if bool(job.home_upload):
		ok = ok and bool(_cmd(owner, "upload_job", {"job_id": id}, {"at_home": true}).get("ok", false))
	if id == "outpost_recovery":
		ok = ok and bool(_cmd(owner, "claim_recruit", {"kind": "outpost"}, {"runtime_authorized": true}).get("ok", false))
		ok = ok and bool(_cmd(owner, "load_crate", {}, {"runtime_authorized": true}).get("ok", false))
	_check(ok and _status(owner, id) == "completed", "Fixture: Kampagnenauftrag abgeschlossen " + id)

func _custom(extra: Dictionary) -> Dictionary:
	return {"factions": {"verwaltung": "Verwaltung", "labor": "Shady Lab"}, "jobs": extra}

func _def(id: String, over: Dictionary = {}) -> Dictionary:
	var base := {"id": id, "title": "Test " + id, "description": "", "location_id": "relay_ridge", "scenario_id": id, "required_step_ids": ["s1"], "faction": "verwaltung", "reward": {"credits": 10}}
	base.merge(over, true)
	return base

func _run() -> void:
	_case_real_chain()
	_case_definitions()
	_case_windows()
	_case_clamp_and_rep_gate()
	_case_state_roundtrip()
	_case_old_and_ghost_state()
	_case_off_switch_and_bad_data()
	_case_contracts_and_files()
	print("SIDE_JOBS_RULES passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)

# ---------- 1: echte Daten, echter Befehlsweg ----------

func _case_real_chain() -> void:
	var owner: RefCounted = _owner()
	var snapshot: Dictionary = owner.get_campaign_snapshot()
	var all_side := true
	for id in SIDE_IDS:
		all_side = all_side and snapshot.jobs.has(id) and bool(snapshot.jobs[id].get("side", false)) and String(snapshot.jobs[id].status) == "offered" and String(snapshot.jobs[id].faction) != ""
	_check(all_side, "Daten: die vier Nebenauftraege stehen als side=true, offered im Snapshot")
	var campaign_plain := true
	for id in CAMPAIGN_IDS:
		campaign_plain = campaign_plain and snapshot.jobs.has(id) and not bool(snapshot.jobs[id].get("side", false))
	_check(campaign_plain, "Daten: Kampagnenauftraege tragen kein side")
	_check(snapshot.factions.size() == 4 and String(snapshot.factions.templer) == "Templer" and int(snapshot.home_landings) == 0, "Snapshot: factions (4), home_landings 0")
	var zero := true
	for faction in snapshot.factions:
		zero = zero and int(snapshot.reputation.get(faction, -1)) == 0
	_check(zero, "Snapshot: Ruf je Fraktion startet bei 0")
	var hidden := true
	for id in SIDE_IDS:
		hidden = hidden and not bool(_avail(owner, id).get("visible", true)) and not bool(_avail(owner, id).get("can_accept", true))
	_check(hidden, "Vorgaenger offen: alle Nebenauftraege unsichtbar und nicht annehmbar")
	_check(bool(snapshot.jobs.side_relay_silence.locked), "Snapshot: locked=true solange der Vorgaenger fehlt")
	var entry: Dictionary = _avail(owner, "side_relay_silence")
	_check(entry.has("side") and entry.has("faction") and entry.has("landings_left") and entry.has("cooldown_left") and bool(entry.side) and String(entry.faction) == "verwaltung", "Verfuegbarkeit: Felder side, faction, landings_left, cooldown_left")
	var plain_entry: Dictionary = _avail(owner, "satellite_recovery")
	_check(not bool(plain_entry.get("side", true)) and int(plain_entry.get("landings_left", 0)) == -1, "Verfuegbarkeit: Kampagnenauftrag side=false, landings_left -1")
	_check(not bool(_cmd(owner, "accept_job", {"job_id": "side_relay_silence"}).get("ok", true)), "Annehmen vor dem Vorgaenger wird abgelehnt")
	_finish(owner, "satellite_recovery")
	_check(bool(_avail(owner, "side_templer_volunteer").visible) and bool(_avail(owner, "side_templer_volunteer").can_accept) and not bool(_avail(owner, "side_relay_silence").visible), "Nach satellite_recovery: nur der Freiwillige sichtbar und annehmbar")
	_finish(owner, "outpost_recovery")
	_check(bool(_avail(owner, "side_relay_silence").can_accept) and bool(_avail(owner, "side_farm_night_watch").can_accept) and not bool(_avail(owner, "side_lab_cold_samples").visible), "Nach outpost_recovery: Funkstille und Nachtwache annehmbar, Labor noch nicht")
	_check(not bool(_job(owner, "side_relay_silence").locked), "Snapshot: locked=false nach dem Vorgaenger")
	# Handel und freier Besuch bleiben bei angenommenem Nebenauftrag.
	var plain_owner: RefCounted = _owner({})
	_check(plain_owner.get_campaign_snapshot().factions.is_empty(), "Fixture: Besitzer ohne Nebenauftraege")
	_finish(plain_owner, "satellite_recovery")
	_finish(plain_owner, "outpost_recovery")
	_check(bool(_cmd(owner, "accept_job", {"job_id": "side_relay_silence"}).get("ok", false)) and _status(owner, "side_relay_silence") == "accepted", "Funkstille angenommen")
	_check(not owner.has_open_job_at("relay_ridge") and String(owner.free_visit_scenario_id("relay_ridge")) == "relay_ridge_visit" and String(owner.open_garrison_scenario_id("relay_ridge")) == "", "has_open_job_at und freier Besuch ignorieren den Nebenauftrag")
	var same := true
	for location_id in owner.get_campaign_snapshot().locations:
		same = same and bool(owner.validate_location_visit(String(location_id), true).get("ok", false)) == bool(plain_owner.validate_location_visit(String(location_id), true).get("ok", false))
	_check(same, "validate_location_visit: Nebenauftraege aendern keinen Anflug")
	_check(not bool(Dictionary(owner.trade_marker_entry("relay_ridge")).is_empty()), "Handelsmarker am Relaisgrat bleibt bei angenommenem Nebenauftrag")
	# Abschluss ueber den echten Befehlsweg.
	_check(_start(owner, "side_relay_silence") and _status(owner, "side_relay_silence") == "active", "Funkstille aktiv (annehmen, Abflug binden, aktivieren)")
	var job: Dictionary = _job(owner, "side_relay_silence")
	var partial: Array = Array(job.required_step_ids).slice(0, 2)
	_check(String(_cmd(owner, "complete_job", {"job_id": "side_relay_silence", "craft_id": "dropship_1"}, {"runtime_evidence": _evidence(job, partial)}).get("reason", "")) == "incomplete_objectives", "Abschluss mit fehlenden Schritten abgelehnt")
	var foreign := _evidence(job)
	foreign["scenario_id"] = "satellite_recovery"
	_check(String(_cmd(owner, "complete_job", {"job_id": "side_relay_silence", "craft_id": "dropship_1"}, {"runtime_evidence": foreign}).get("reason", "")) == "unverified_completion", "Abschluss mit fremdem Szenario abgelehnt")
	var done: Dictionary = _complete(owner, "side_relay_silence")
	_check(bool(done.get("ok", false)), "Funkstille abgeschlossen (%s)" % str(done.get("reason", "")))
	var receipt: Dictionary = Dictionary(done.get("completion_receipt", {}))
	_check(String(receipt.get("completion_id", "")) == "side_relay_silence:completed:1" and bool(receipt.get("side", false)) and bool(receipt.get("runtime_verified", false)), "Beleg: completion_id mit Zaehler, side=true")
	var reward: Dictionary = Dictionary(receipt.get("reward", {}))
	_check(int(reward.get("credits", -1)) == 100 and reward.has("items") and reward.has("recruits") and int(Dictionary(reward.get("reputation", {})).get("verwaltung", 0)) == 5 and reward.has("blueprint_id"), "Beleg: volle Belohnung (Credits, items, recruits, reputation, blueprint_id)")
	_check(int(owner.get_campaign_snapshot().reputation.verwaltung) == 5 and _status(owner, "side_relay_silence") == "cooldown" and int(_job(owner, "side_relay_silence").completions) == 1, "Ruf gebucht (verwaltung 5), Zustand cooldown, completions 1")
	_check(not owner.get_completion_receipt("side_relay_silence:completed:1").is_empty() and not bool(_avail(owner, "side_relay_silence").visible) and int(_avail(owner, "side_relay_silence").cooldown_left) == 2, "Beleg abrufbar; cooldown: unsichtbar, cooldown_left 2")
	_check(String(_cmd(owner, "accept_job", {"job_id": "side_relay_silence"}).get("reason", "")) == "side_offer_gone", "Annehmen im cooldown abgelehnt")
	_landing(owner)
	_check(_status(owner, "side_relay_silence") == "cooldown" and int(_avail(owner, "side_relay_silence").cooldown_left) == 1, "Nach 1 Heimlandung noch cooldown (cooldown_left 1)")
	var replay: Dictionary = owner.apply_command(COMMAND.build_command("home_landing", {}, "home_landing:1"))
	_check(bool(replay.get("replayed", false)) and int(owner.get_campaign_snapshot().home_landings) == 1, "Dieselbe request_id zaehlt nicht doppelt")
	_landing(owner)
	var again: Dictionary = _avail(owner, "side_relay_silence")
	_check(_status(owner, "side_relay_silence") == "offered" and bool(again.visible) and bool(again.can_accept) and int(again.landings_left) == 3, "Nach 2 Heimlandungen wieder angeboten (landings_left 3)")
	_check(_start(owner, "side_relay_silence") and bool(_complete(owner, "side_relay_silence").get("ok", false)), "Zweite Ausfuehrung laeuft durch")
	_check(owner.get_completion_receipt("side_relay_silence:completed:2").size() > 0 and int(owner.get_campaign_snapshot().reputation.verwaltung) == 10, "Zweite Ausfuehrung: neue completion_id :2, Ruf 10")
	# Labor: Gegenstaende im Beleg, Ruf je Fraktion, Mindestruf des Freiwilligen.
	_finish(owner, "benit_delivery")
	_check(bool(_avail(owner, "side_lab_cold_samples").can_accept), "Nach benit_delivery: Probenauftrag annehmbar")
	_check(_start(owner, "side_lab_cold_samples"), "Probenauftrag gestartet")
	var lab_done: Dictionary = _complete(owner, "side_lab_cold_samples")
	var lab_reward: Dictionary = Dictionary(Dictionary(lab_done.get("completion_receipt", {})).get("reward", {}))
	_check(bool(lab_done.get("ok", false)) and Array(lab_reward.get("items", [])).size() == 2 and int(Dictionary(lab_reward.reputation).get("templer", 0)) == -3, "Probenauftrag: zwei Gegenstaende und Ruf Templer -3 im Beleg")
	var rep: Dictionary = owner.get_campaign_snapshot().reputation
	_check(int(rep.labor) == 5 and int(rep.templer) == -3, "Ruf: Labor 5, Templer -3")
	var volunteer: Dictionary = _avail(owner, "side_templer_volunteer")
	_check(bool(volunteer.visible) and bool(volunteer.shown_as_locked) and not bool(volunteer.can_accept) and String(volunteer.reason) == "reputation_required" and String(volunteer.message) == "Braucht Ruf 0 bei Templer.", "Freiwilliger: sichtbar, gesperrt, Grund reputation_required (%s)" % str(volunteer.get("message", "")))
	_check(String(_cmd(owner, "accept_job", {"job_id": "side_templer_volunteer"}).get("reason", "")) == "reputation_required" and bool(_job(owner, "side_templer_volunteer").locked), "Annehmen ohne Mindestruf abgelehnt; Snapshot locked")

# ---------- 2: Normalisierung ----------

func _case_definitions() -> void:
	var locations := {"relay_ridge": {}}
	var factions := {"verwaltung": "Verwaltung"}
	var good: Dictionary = JOBS.normalize_side_job(_def("x", {"reward": {"credits": 5, "items": [{"item_id": "armor_light", "quantity": 2}], "recruits": 1, "reputation": {"verwaltung": -5}}}), locations, factions)
	_check(not good.is_empty() and bool(good.side) and bool(good.repeatable) and good.reward.items.size() == 1 and int(good.reward.recruits) == 1 and int(good.reward.reputation.verwaltung) == -5 and int(good.cooldown_landings) == 0, "normalize_side_job: gueltiger Eintrag mit Vorgaben")
	var bad_count := 0
	var bad_cases: Array = [
		{"reward": {"credits": -1}},
		{"reward": {"credits": 1000001}},
		{"reward": {"credits": 1, "items": [{"item_id": "a", "quantity": 11}]}},
		{"reward": {"credits": 1, "items": [{"item_id": "a", "quantity": 0}]}},
		{"reward": {"credits": 1, "items": [{"item_id": "a", "quantity": 1}, {"item_id": "b", "quantity": 1}, {"item_id": "c", "quantity": 1}, {"item_id": "d", "quantity": 1}, {"item_id": "e", "quantity": 1}]}},
		{"reward": {"credits": 1, "recruits": 3}},
		{"reward": {"credits": 1, "reputation": {"verwaltung": 51}}},
		{"reward": {"credits": 1, "reputation": {"unbekannt": 1}}},
		{"cooldown_landings": 21},
		{"offer_landings": -1},
		{"reappear_landings": 2.5},
		{"faction": "unbekannt"},
		{"faction": ""},
		{"min_reputation": {"verwaltung": 101}},
		{"prerequisite_job_ids": ["x"]},
		{"repeatable": "ja"},
		{"required_step_ids": []},
		{"location_id": "nirgendwo"},
	]
	for over: Dictionary in bad_cases:
		if JOBS.normalize_side_job(_def("x", over), locations, factions).is_empty():
			bad_count += 1
	_check(bad_count == bad_cases.size(), "normalize_side_job: alle %d Fehlformen/Grenzverletzungen werden abgelehnt (%d)" % [bad_cases.size(), bad_count])
	var edge: Dictionary = JOBS.normalize_side_job(_def("x", {"cooldown_landings": 20, "offer_landings": 0, "reward": {"credits": 1000000, "recruits": 2, "reputation": {"verwaltung": 50}, "items": [{"item_id": "a", "quantity": 10}]}}), locations, factions)
	_check(not edge.is_empty(), "normalize_side_job: Obergrenzen sind erlaubt")
	_check(JOBS.normalize_job(_def("x"), locations).is_empty() == false and not JOBS.normalize_job(_def("x"), locations).has("side"), "normalize_job bleibt unveraendert (kein side, keine neuen Felder)")

# ---------- 3: Fristen ----------

func _case_windows() -> void:
	var owner: RefCounted = _owner(_custom({"w": _def("w", {"offer_landings": 2, "reappear_landings": 1})}))
	_check(bool(_avail(owner, "w").visible) and int(_avail(owner, "w").landings_left) == 2, "Frist: ohne Vorgaenger sofort sichtbar, landings_left 2")
	_landing(owner)
	_check(_status(owner, "w") == "offered" and int(_avail(owner, "w").landings_left) == 2, "Frist: Fenster beginnt mit der ersten Heimlandung (2 uebrig)")
	_landing(owner)
	_check(_status(owner, "w") == "offered" and int(_avail(owner, "w").landings_left) == 1, "Frist: nach der zweiten Landung noch 1 uebrig")
	_landing(owner)
	var gone: Dictionary = _avail(owner, "w")
	_check(_status(owner, "w") == "expired" and not bool(gone.visible) and not bool(gone.can_accept) and int(gone.cooldown_left) == 1, "Frist: nach offer_landings abgelaufen, unsichtbar, cooldown_left 1")
	_check(String(_cmd(owner, "accept_job", {"job_id": "w"}).get("reason", "")) == "side_offer_gone", "Frist: abgelaufenes Angebot nicht annehmbar")
	_landing(owner)
	_check(_status(owner, "w") == "offered" and bool(_avail(owner, "w").can_accept) and int(_avail(owner, "w").landings_left) == 2, "Frist: nach reappear_landings wieder da")
	# Angenommene, aktive und gescheiterte laufen nicht ab.
	var accepted: RefCounted = _owner(_custom({"w": _def("w", {"offer_landings": 1})}))
	_cmd(accepted, "accept_job", {"job_id": "w"})
	_landing(accepted, 5)
	_check(_status(accepted, "w") == "accepted", "Frist: angenommener Auftrag laeuft nicht ab")
	var active: RefCounted = _owner(_custom({"w": _def("w", {"offer_landings": 1})}))
	_start(active, "w")
	_landing(active, 5)
	_check(_status(active, "w") == "active", "Frist: aktiver Auftrag laeuft nicht ab")
	var failing: RefCounted = _owner(_custom({"w": _def("w", {"cooldown_landings": 2})}))
	_start(failing, "w")
	var failed_result: Dictionary = _cmd(failing, "fail_job", {"job_id": "w"}, {"mission_aborted": true})
	_check(bool(failed_result.get("ok", false)) and bool(failed_result.get("side_cooldown", false)), "Aufgegeben: Nebenauftrag meldet Sperrzeit")
	_check(_status(failing, "w") == "cooldown" and not bool(_avail(failing, "w").can_accept) and not bool(_avail(failing, "w").visible) and bool(_avail(failing, "w").get("waiting", false)) and int(_avail(failing, "w").get("wait_landings", 0)) == 2, "Aufgegeben: Sperrzeit, grau wartend (waiting), Restzeit 2, nicht annehmbar")
	_check(String(_avail(failing, "w").get("message", "")) == "Wieder verfügbar in 2 Heimlandungen", "Aufgegeben: Text 'Wieder verfügbar in 2 Heimlandungen' (beobachtet '%s')" % String(_avail(failing, "w").get("message", "")))
	_check(not _job(failing, "w").has("craft_id") and int(_job(failing, "w").completions) == 0, "Aufgegeben: keine Schiffsbindung, kein Abschluss gezaehlt")
	_landing(failing)
	_check(_status(failing, "w") == "cooldown" and int(_avail(failing, "w").get("wait_landings", 0)) == 1 and String(_avail(failing, "w").get("message", "")) == "Wieder verfügbar in 1 Heimlandung", "Aufgegeben: nach 1 Landung noch Sperrzeit, 'in 1 Heimlandung'")
	_landing(failing)
	_check(_status(failing, "w") == "offered" and bool(_avail(failing, "w").can_accept) and bool(_avail(failing, "w").visible) and not bool(_avail(failing, "w").get("waiting", false)), "Aufgegeben: nach der normalen Sperrzeit wieder im Angebot")
	_check(bool(_cmd(failing, "accept_job", {"job_id": "w"}).get("ok", false)), "Aufgegeben: wieder annehmbar")
	# Alter Stand mit gescheitertem Nebenauftrag (status failed) laedt als Sperrzeit.
	var old_failed: Dictionary = JSON.parse_string(JSON.stringify(_owner().export_state()))
	old_failed.jobs.side_relay_silence["status"] = "failed"
	var old_loaded: RefCounted = CAMPAIGN.new()
	var old_verdict: Dictionary = old_loaded.restore_state(old_failed)
	_check(bool(old_verdict.get("ok", false)) and String(Dictionary(old_loaded.get_campaign_snapshot().jobs.side_relay_silence).status) == "cooldown", "Alter Stand mit failed-Nebenauftrag: laedt als Sperrzeit (%s)" % str(old_verdict.get("reason", "")))
	# Nicht wiederholbar.
	var once: RefCounted = _owner(_custom({"o": _def("o", {"repeatable": false})}))
	_start(once, "o")
	_complete(once, "o")
	_landing(once, 5)
	_check(_status(once, "o") == "completed" and not bool(_avail(once, "o").can_accept) and int(_job(once, "o").completions) == 1, "Nicht wiederholbar: bleibt completed")
	# Vorgaenger offen: Fenster laeuft nicht.
	var gated: RefCounted = _owner(_custom({"a": _def("a", {"offer_landings": 2, "reappear_landings": 10}), "b": _def("b", {"prerequisite_job_ids": ["a"], "offer_landings": 2})}))
	_landing(gated, 4)
	_check(_status(gated, "b") == "offered" and int(_avail(gated, "b").landings_left) == 2 and not bool(_avail(gated, "b").visible), "Frist: Fenster eines Auftrags mit offenem Vorgaenger laeuft nicht")
	_check(_status(gated, "a") == "expired", "Frist: der Vorgaenger selbst laeuft ab, wenn niemand ihn nimmt")

# ---------- 4: Ruf-Grenzen und Mindestruf ----------

func _case_clamp_and_rep_gate() -> void:
	var up: RefCounted = _owner(_custom({"u": _def("u", {"reward": {"credits": 1, "reputation": {"verwaltung": 50}}})}))
	for i in 3:
		_start(up, "u")
		_complete(up, "u")
		_landing(up)
	_check(int(up.get_campaign_snapshot().reputation.verwaltung) == 100 and int(_job(up, "u").completions) == 3, "Ruf wird bei +100 geklemmt (3 x +50)")
	var down: RefCounted = _owner(_custom({"d": _def("d", {"reward": {"credits": 1, "reputation": {"labor": -50}}})}))
	for i in 3:
		_start(down, "d")
		_complete(down, "d")
		_landing(down)
	_check(int(down.get_campaign_snapshot().reputation.labor) == -100, "Ruf wird bei -100 geklemmt (3 x -50)")
	var gate: RefCounted = _owner(_custom({"g": _def("g", {"min_reputation": {"verwaltung": 10}}), "s": _def("s", {"reward": {"credits": 1, "reputation": {"verwaltung": 10}}})}))
	var locked: Dictionary = _avail(gate, "g")
	_check(bool(locked.visible) and bool(locked.shown_as_locked) and not bool(locked.can_accept) and String(locked.message) == "Braucht Ruf 10 bei Verwaltung.", "Mindestruf: sichtbar, gesperrt, Text (%s)" % str(locked.get("message", "")))
	_start(gate, "s")
	_complete(gate, "s")
	_check(bool(_avail(gate, "g").can_accept) and not bool(_avail(gate, "g").shown_as_locked), "Mindestruf erreicht: annehmbar")

# ---------- 5: Speichern und Laden ----------

func _case_state_roundtrip() -> void:
	var owner: RefCounted = _owner()
	_finish(owner, "satellite_recovery")
	_finish(owner, "outpost_recovery")
	_start(owner, "side_relay_silence")
	_complete(owner, "side_relay_silence")
	_start(owner, "side_farm_night_watch")
	_complete(owner, "side_farm_night_watch")
	_landing(owner, 1)
	var state: Dictionary = JSON.parse_string(JSON.stringify(owner.export_state()))
	_check(state.has("home_landings") and state.has("reputation") and state.has("factions") and int(state.home_landings) == 1, "export_state: neue Schluessel home_landings, reputation, factions")
	var restored: RefCounted = CAMPAIGN.new()
	var verdict: Dictionary = restored.restore_state(state.duplicate(true))
	_check(bool(verdict.get("ok", false)), "restore_state: Stand mit Nebenauftraegen laedt (%s)" % str(verdict.get("reason", "")))
	var after: Dictionary = restored.get_campaign_snapshot()
	_check(int(after.home_landings) == 1 and int(after.reputation.verwaltung) == 5 and int(after.reputation.mueller) == 5 and int(after.reputation.templer) == 2, "Rundweg: Heimlandungen und Ruf bleiben")
	var relay_before: Dictionary = _job(owner, "side_relay_silence")
	var relay_after: Dictionary = _job(restored, "side_relay_silence")
	_check(String(relay_after.status) == String(relay_before.status) and int(relay_after.completions) == 1 and int(relay_after.window_start) == int(relay_before.window_start) and int(relay_after.cooldown_until) == int(relay_before.cooldown_until), "Rundweg: Zustand, Zaehler und Fristfelder bleiben (Funkstille)")
	_check(_status(restored, "side_farm_night_watch") == "cooldown" and int(_job(restored, "side_farm_night_watch").cooldown_until) == 2, "Rundweg: Nachtwache noch im cooldown (bis Landung 2)")
	_check(after.completion_receipts.has("side_relay_silence:completed:1") and after.completion_receipts.has("side_farm_night_watch:completed:1"), "Rundweg: Belege beider Nebenauftraege bleiben")
	_landing(restored)
	_check(_status(restored, "side_relay_silence") == "offered", "Nach dem Laden und einer weiteren Heimlandung ist die Funkstille wieder angeboten")
	_start(restored, "side_relay_silence")
	var second: Dictionary = _complete(restored, "side_relay_silence")
	_check(String(Dictionary(second.get("completion_receipt", {})).get("completion_id", "")) == "side_relay_silence:completed:2" and int(restored.get_campaign_snapshot().reputation.verwaltung) == 10, "Nach dem Laden zaehlt die naechste Ausfuehrung weiter (:completed:2)")
	var second_state: Dictionary = JSON.parse_string(JSON.stringify(restored.export_state()))
	_check(bool(CAMPAIGN.new().restore_state(second_state).get("ok", false)), "Zweiter Rundweg mit zwei Belegen desselben Auftrags laedt")
	var bad_rep: Dictionary = state.duplicate(true)
	bad_rep["reputation"] = "viel"
	_check(not bool(CAMPAIGN.new().restore_state(bad_rep).get("ok", true)), "Stand mit kaputtem Ruf wird abgelehnt")
	var odd_status: Dictionary = state.duplicate(true)
	odd_status.jobs.side_relay_silence.status = "vergessen"
	_check(not bool(CAMPAIGN.new().restore_state(odd_status).get("ok", true)), "Stand mit unbekanntem Nebenauftragsstatus wird abgelehnt")

func _case_old_and_ghost_state() -> void:
	var owner: RefCounted = _owner()
	_finish(owner, "satellite_recovery")
	var old_state: Dictionary = JSON.parse_string(JSON.stringify(owner.export_state()))
	old_state.erase("home_landings")
	old_state.erase("reputation")
	old_state.erase("factions")
	for id in SIDE_IDS:
		old_state.jobs.erase(id)
	var old_restored: RefCounted = CAMPAIGN.new()
	var verdict: Dictionary = old_restored.restore_state(old_state)
	_check(bool(verdict.get("ok", false)), "Alter Stand ohne neue Schluessel und ohne Nebenauftraege laedt (%s)" % str(verdict.get("reason", "")))
	var snapshot: Dictionary = old_restored.get_campaign_snapshot()
	var fresh_ok := int(snapshot.home_landings) == 0 and int(snapshot.reputation.get("templer", -1)) == 0
	for id in SIDE_IDS:
		fresh_ok = fresh_ok and String(snapshot.jobs[id].status) == "offered" and int(snapshot.jobs[id].completions) == 0
	_check(fresh_ok, "Alter Stand: Nebenauftraege neu (offered, 0 Ausfuehrungen), Heimlandungen 0, Ruf 0")
	_check(_status(old_restored, "satellite_recovery") == "completed" and bool(_avail(old_restored, "side_templer_volunteer").can_accept), "Alter Stand: Kampagnenstand bleibt, Freiwilliger annehmbar")
	var ghost_state: Dictionary = JSON.parse_string(JSON.stringify(owner.export_state()))
	var ghost_job: Dictionary = ghost_state.jobs.side_templer_volunteer.duplicate(true)
	ghost_job["id"] = "side_gone"
	ghost_state.jobs["side_gone"] = ghost_job
	ghost_state.completion_receipts["side_gone:completed:1"] = {"completion_id": "side_gone:completed:1", "job_id": "side_gone", "scenario_id": "side_gone", "reward": {"credits": 1}, "runtime_verified": true, "side": true}
	var ghost_restored: RefCounted = CAMPAIGN.new()
	var ghost_verdict: Dictionary = ghost_restored.restore_state(ghost_state)
	_check(bool(ghost_verdict.get("ok", false)) and not ghost_restored.get_campaign_snapshot().jobs.has("side_gone") and ghost_restored.get_campaign_snapshot().completion_receipts.has("side_gone:completed:1"), "Unbekannter Nebenauftrag wird still verworfen, sein Beleg BLEIBT (Rekrut behaelt Deckung) (%s)" % str(ghost_verdict.get("reason", "")))
	var campaign_ghost: Dictionary = JSON.parse_string(JSON.stringify(owner.export_state()))
	campaign_ghost.jobs["ghost_job"] = campaign_ghost.jobs.satellite_recovery.duplicate(true)
	_check(String(CAMPAIGN.new().restore_state(campaign_ghost).get("reason", "")) == "stale_campaign_definitions", "Unbekannter Kampagnenauftrag im Stand wird weiter abgelehnt")
	var side_flag_spoof: Dictionary = JSON.parse_string(JSON.stringify(owner.export_state()))
	side_flag_spoof.jobs.erase("outpost_recovery")
	_check(String(CAMPAIGN.new().restore_state(side_flag_spoof).get("reason", "")) == "stale_campaign_definitions", "Fehlender Kampagnenauftrag im Stand wird weiter abgelehnt")

# ---------- 6: Abschalten und schlechte Daten ----------

func _case_off_switch_and_bad_data() -> void:
	var off: RefCounted = _owner({})
	var snapshot: Dictionary = off.get_campaign_snapshot()
	var any_side := false
	for id in snapshot.jobs:
		any_side = any_side or bool(snapshot.jobs[id].get("side", false))
	_check(not any_side and snapshot.jobs.size() == CAMPAIGN_IDS.size() and snapshot.factions.is_empty() and not off.get_job_availability(true).has("side_relay_silence"), "side_jobs={}: keine Nebenauftraege, nur die Kampagnenauftraege")
	var landing: Dictionary = off.apply_command(COMMAND.build_command("home_landing", {}, "home_landing:1"))
	_check(bool(landing.get("ok", false)) and int(off.get_campaign_snapshot().home_landings) == 1, "home_landing laeuft auch ohne Nebenauftraege")
	var empty_file: RefCounted = CAMPAIGN.new()
	_check(bool(empty_file.configure({}, {}, true, {}).get("ok", false)), "configure mit {} als side_jobs ok")
	var unknown_faction: Dictionary = {"factions": {"verwaltung": "V"}, "jobs": {"z": _def("z", {"faction": "x"})}}
	_check(not bool(CAMPAIGN.new().configure({}, {}, true, unknown_faction).get("ok", true)), "Eigene Definitionen: unbekannte Fraktion wird abgelehnt")
	var unknown_prior: Dictionary = _custom({"z": _def("z", {"prerequisite_job_ids": ["gibt_es_nicht"]})})
	_check(not bool(CAMPAIGN.new().configure({}, {}, true, unknown_prior).get("ok", true)), "Eigene Definitionen: unbekannter Vorgaenger wird abgelehnt")
	var clash: Dictionary = _custom({"satellite_recovery": _def("satellite_recovery")})
	_check(not bool(CAMPAIGN.new().configure({}, {}, true, clash).get("ok", true)), "Eigene Definitionen: Kennung eines Kampagnenauftrags wird abgelehnt")
	_check(not bool(CAMPAIGN.new().configure({}, {}, true, "kaputt").get("ok", true)), "Eigene Definitionen: kein Dictionary wird abgelehnt")
	var by_id := COMMAND.build_command("home_landing", {}, "home_landing:7")
	_check(not by_id.is_empty() and COMMAND.validate_command(by_id) and COMMAND.build_command("home_landing", {}, " ").is_empty(), "Befehlsvertrag kennt home_landing (Form: leere Nutzlast, nicht leere request_id)")
	var with_payload: Dictionary = off.apply_command(COMMAND.build_command("home_landing", {"x": 1}, "home_landing:99"))
	_check(not bool(with_payload.get("ok", true)), "home_landing mit Nutzlast wird abgelehnt")
	var custom_jobs: RefCounted = CAMPAIGN.new()
	_check(bool(custom_jobs.configure({}, {"satellite_recovery": JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/jobs.json")).satellite_recovery}).get("ok", false)), "Eigene Kampagnenliste: Nebenauftraege mit fehlendem Vorgaenger fallen still weg")

# ---------- 7: Dateien ----------

func _case_contracts_and_files() -> void:
	var file: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/side_jobs.json"))
	var locations: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/locations.json"))
	var jobs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/jobs.json"))
	var good: bool = Dictionary(file.jobs).size() == SIDE_IDS.size()
	for id in file.jobs:
		var raw: Dictionary = file.jobs[id]
		good = good and String(raw.scenario_id) == String(id) and Array(raw.required_step_ids).has("return_to_ship") and locations.has(String(raw.location_id)) and file.factions.has(String(raw.faction))
		for prior in Array(raw.get("prerequisite_job_ids", [])):
			good = good and jobs.has(String(prior))
		for item: Dictionary in Array(Dictionary(raw.reward).get("items", [])):
			good = good and INVENTORY.known(String(item.item_id))
	_check(good, "side_jobs.json: Szenario = Kennung, return_to_ship, Ort, Fraktion, Vorgaenger und Gegenstaende gueltig")
	var recruits := 0
	for id in file.jobs:
		recruits += int(Dictionary(file.jobs[id].reward).get("recruits", 0))
	_check(recruits == 1 and int(file.jobs.side_templer_volunteer.reward.recruits) == 1, "side_jobs.json: genau ein Rekrut-Auftrag (Freiwilliger)")
	var standing: RefCounted = STANDING.new()
	var orders: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/standing_orders.json"))
	_check(standing.configure(orders), "standing_orders.json laedt mit den neuen Auftraegen")
	var wanted: Dictionary = {"freight:muellers_farm:heilkraeuter": "templanon", "freight:shady_lab:duenger": "muellers_farm", "freight:templanon:aufputschmittel": "shady_lab"}
	var found := 0
	for order: Dictionary in Array(orders.orders):
		if wanted.has(String(order.id)):
			var origin: String = String(order.origin)
			var dest: String = String(order.destination)
			if String(order.kind) == "freight" and String(wanted[order.id]) == dest and int(order.crates) == 4 and int(order.pay) >= 30 and int(order.pay) <= 40 and Array(locations[origin].services).has("trade") and Array(locations[dest].services).has("trade") and INVENTORY.known(String(order.item)):
				found += 1
	_check(found == 3, "Dreieck: drei Fracht-Daueraufträge (Farm->Templer, Labor->Farm, Templer->Labor), je 4 Kisten, 30-40 Cr, Haendler an beiden Orten")
	_check(standing.get_snapshot({}).size() == 9, "Dauerauftraege: jetzt neun (beobachtet %d)" % standing.get_snapshot({}).size())
