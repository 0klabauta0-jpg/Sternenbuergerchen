extends SceneTree
## Kapitel 2, Aufgabe 0a: neue Auftraege laden additiv (alte Staende bleiben ladbar), gesperrte neue Auftraege
## mit Grund sichtbar. Nur Besitzer, kein Fenster. Der Pruefeintrag wreck_crater_salvage wird hier gebaut;
## jobs.json bleibt unveraendert. Gibt es den Eintrag dort schon, laeuft zusaetzlich der echte restore_state-Weg.
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const COMMAND = preload("res://scripts/mission/singleplayer_campaign_command_contract.gd")
const JOBS = preload("res://scripts/mission/singleplayer_job_contract.gd")
const CHAPTER_ONE := ["satellite_recovery", "outpost_recovery", "benit_delivery", "outpost_chip_recovery", "buccaneer_rescue"]
const PROBE_ID := "wreck_crater_salvage"
const HINT := "Erst den Freibeuter-Piloten retten."
var passed := 0
var failed := 0
var sequence := 0
var old_jobs: Dictionary = {}
var new_jobs: Dictionary = {}
var real_file_has_probe := false

func _check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print(("PASS " if value else "FAIL ") + label)

func _cmd(owner: RefCounted, operation: String, payload: Dictionary, context: Dictionary = {}) -> Dictionary:
	sequence += 1
	return owner.apply_command(COMMAND.build_command(operation, payload, "additive:%d" % sequence), context)

func _probe(id: String = PROBE_ID) -> Dictionary:
	return {"id":id, "title":"Wrack im Krater bergen", "description":"Pruefeintrag", "location_id":"satellite_crash", "scenario_id":PROBE_ID, "prerequisite_job_id":"buccaneer_rescue", "home_upload":false, "required_step_ids":["probe_step"], "reward":{"credits":200}, "locked_hint":HINT}

func _accept_and_activate(owner: RefCounted, id: String) -> void:
	var job: Dictionary = owner.get_campaign_snapshot().jobs[id]
	var dep := {"craft_id":"dropship_1", "origin_location_id":"homebase", "destination_location_id":job.location_id, "landing_pad_id":"homebase_pad_01", "job_id":id}
	var ok := bool(_cmd(owner, "accept_job", {"job_id":id}).get("ok", false))
	ok = ok and bool(_cmd(owner, "bind_departure", dep, {"departure_authorized":true}).get("ok", false))
	ok = ok and bool(_cmd(owner, "activate_job", {"job_id":id, "craft_id":"dropship_1"}, {"departure_authorized":true}).get("ok", false))
	_check(ok, "Fixture: angenommen und aktiv " + id)

func _finish(owner: RefCounted, id: String) -> void:
	var job: Dictionary = owner.get_campaign_snapshot().jobs[id]
	_accept_and_activate(owner, id)
	if id == "benit_delivery":
		_check(bool(_cmd(owner, "deliver_crate", {}, {"runtime_authorized":true}).get("ok", false)), "Fixture: Kiste geliefert")
	var evidence := {"scenario_id":job.scenario_id, "result":"victory", "mission_scenario_runtime_gates":{"all_gates_complete":true, "completed_step_ids":job.required_step_ids}}
	var done: Dictionary = _cmd(owner, "complete_job", {"job_id":id, "craft_id":"dropship_1"}, {"runtime_evidence":evidence})
	var ok := bool(done.get("ok", false))
	if bool(job.home_upload):
		ok = ok and bool(_cmd(owner, "upload_job", {"job_id":id}, {"at_home":true}).get("ok", false))
	if id == "outpost_recovery":
		ok = ok and bool(_cmd(owner, "claim_recruit", {"kind":"outpost"}, {"runtime_authorized":true}).get("ok", false))
		ok = ok and bool(_cmd(owner, "load_crate", {}, {"runtime_authorized":true}).get("ok", false))
	if id == "buccaneer_rescue":
		ok = ok and bool(_cmd(owner, "claim_recruit", {"kind":"pilot"}, {"runtime_authorized":true}).get("ok", false))
		ok = ok and bool(_cmd(owner, "build_pad", {}, {"runtime_authorized":true, "at_home":true}).get("ok", false))
	_check(ok, "Fixture: abgeschlossen " + id)

## Frischer Besitzer mit den ersten count Auftraegen von Kapitel 1 abgeschlossen.
func _owner(jobs: Dictionary, count: int) -> RefCounted:
	var owner: RefCounted = CAMPAIGN.new()
	_check(bool(owner.configure({}, jobs).get("ok", false)), "Fixture: Besitzer konfiguriert (%d Auftraege)" % jobs.size())
	for index in range(count):
		_finish(owner, CHAPTER_ONE[index])
	return owner

func _state(owner: RefCounted) -> Dictionary:
	return JSON.parse_string(JSON.stringify(owner.export_state()))

## Pruefweg fuer einen gespeicherten Stand gegen die neuen Auftraege. restore_state liest die Definitionen aus
## jobs.json; steht der Pruefeintrag dort nicht, wird dieselbe Pruefung am konfigurierten Besitzer aufgerufen.
func _load(state: Dictionary, jobs: Dictionary) -> Dictionary:
	if real_file_has_probe:
		var target: RefCounted = CAMPAIGN.new()
		return target.restore_state(state)
	var owner: RefCounted = CAMPAIGN.new()
	owner.configure({}, jobs)
	return owner._validate_saved_state(state)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var file_jobs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/jobs.json"))
	real_file_has_probe = file_jobs.has(PROBE_ID)
	for id in CHAPTER_ONE:
		old_jobs[id] = file_jobs[id].duplicate(true)
	new_jobs = old_jobs.duplicate(true)
	new_jobs[PROBE_ID] = _probe()
	_check(old_jobs.size() == 5, "Fixture: fuenf alte Auftraege")
	_case_load()
	_case_visibility()
	_case_normalize()
	print("CAMPAIGN_ADDITIVE_JOBS passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _case_load() -> void:
	var old_owner: RefCounted = _owner(old_jobs, 5)
	var old_state: Dictionary = _state(old_owner)
	_check(not old_state.jobs.has(PROBE_ID), "Fall 1: alter Stand kennt den neuen Auftrag nicht")
	var verdict: Dictionary = _load(old_state.duplicate(true), new_jobs)
	_check(bool(verdict.get("ok", false)), "Fall 1: alter Stand laedt mit neuem Auftrag (beobachtet %s)" % str(verdict))
	if real_file_has_probe:
		var restored: RefCounted = CAMPAIGN.new()
		restored.restore_state(old_state.duplicate(true))
		var snapshot: Dictionary = restored.get_campaign_snapshot()
		_check(String(snapshot.jobs[PROBE_ID].status) == "offered", "Fall 1: neuer Auftrag steht als offered")
		var all_done := true
		for id in CHAPTER_ONE:
			all_done = all_done and String(snapshot.jobs[id].status) == "completed"
		_check(all_done, "Fall 1: alte fuenf Auftraege bleiben completed")
	else:
		var all_saved_done := true
		for id in CHAPTER_ONE:
			all_saved_done = all_saved_done and String(old_state.jobs[id].status) == "completed"
		_check(all_saved_done, "Fall 1: alte fuenf Auftraege im Stand completed (restore_state-Weg nur mit Eintrag in jobs.json)")
	var ghost: Dictionary = old_state.duplicate(true)
	ghost.jobs["ghost_job"] = ghost.jobs.satellite_recovery.duplicate(true)
	_check(String(_load(ghost, new_jobs).get("reason", "")) == "stale_campaign_definitions", "Fall 2: unbekannter Auftrag im Stand -> stale_campaign_definitions")
	var fresh_state: Dictionary = _state(_owner(old_jobs, 0))
	var missing_old: Dictionary = fresh_state.duplicate(true)
	missing_old.jobs.erase("outpost_recovery")
	_check(String(_load(missing_old, new_jobs).get("reason", "")) == "stale_campaign_definitions", "Fall 3: Stand ohne outpost_recovery -> stale_campaign_definitions")
	var odd_jobs: Dictionary = old_jobs.duplicate(true)
	odd_jobs["not_additive_job"] = _probe("not_additive_job")
	_check(String(_load(fresh_state.duplicate(true), odd_jobs).get("reason", "")) == "stale_campaign_definitions", "Fall 4: fehlender, nicht freigegebener neuer Auftrag -> stale_campaign_definitions")
	var with_probe: Dictionary = _state(_owner(new_jobs, 0))
	_check(with_probe.jobs.has(PROBE_ID) and String(with_probe.jobs[PROBE_ID].status) == "offered", "Fall 5: Stand aus neuen Auftraegen enthaelt den Auftrag als offered")
	var verdict_five: Dictionary = _load(with_probe, new_jobs)
	_check(bool(verdict_five.get("ok", false)), "Fall 5: Stand mit neuem Auftrag laedt (beobachtet %s)" % str(verdict_five))

func _case_visibility() -> void:
	var owner: RefCounted = _owner(new_jobs, 0)
	var availability: Dictionary = owner.get_job_availability(true)
	_check(not bool(availability[PROBE_ID].visible), "Fall 6: Vorgaenger offered -> neuer Auftrag unsichtbar")
	owner = _owner(new_jobs, 4)
	var plain: RefCounted = _owner(old_jobs, 4)
	_accept_and_activate(plain, "buccaneer_rescue")
	var visit_without: Dictionary = plain.validate_location_visit("satellite_crash", true)
	_check(bool(_cmd(owner, "accept_job", {"job_id":"buccaneer_rescue"}).get("ok", false)), "Fixture: buccaneer_rescue angenommen")
	availability = owner.get_job_availability(true)
	var entry: Dictionary = availability[PROBE_ID]
	_check(bool(entry.visible) and bool(entry.shown_as_locked) and not bool(entry.can_accept), "Fall 7: sichtbar, gesperrt, nicht annehmbar (beobachtet %s)" % str(entry))
	_check(String(entry.message) == HINT and String(entry.reason) == "previous_job_required", "Fall 7: Meldung ist der Sperrgrund")
	_check(not bool(_cmd(owner, "accept_job", {"job_id":PROBE_ID}).get("ok", true)), "Fall 7: Annehmen bleibt abgelehnt")
	var visit_with: Dictionary = owner.validate_location_visit("satellite_crash", true)
	_check(JSON.stringify(visit_with) == JSON.stringify(visit_without), "Fall 7: Anflug des Ortes unveraendert durch den gesperrten Auftrag (%s / %s)" % [str(visit_with), str(visit_without)])
	_accept_and_activate(owner, "buccaneer_rescue")
	_check(bool(owner.get_job_availability(true)[PROBE_ID].shown_as_locked), "Fall 7: auch bei aktivem Vorgaenger gesperrt sichtbar")
	_finish(owner, "buccaneer_rescue")
	entry = owner.get_job_availability(true)[PROBE_ID]
	_check(bool(entry.can_accept) and not bool(entry.shown_as_locked), "Fall 8: Vorgaenger fertig -> annehmbar, nicht mehr gesperrt (beobachtet %s)" % str(entry))
	var early: RefCounted = _owner(old_jobs, 0)
	_check(bool(_cmd(early, "accept_job", {"job_id":"satellite_recovery"}).get("ok", false)), "Fixture: satellite_recovery angenommen")
	var old_entry: Dictionary = early.get_job_availability(true)["outpost_recovery"]
	_check(not bool(old_entry.visible) and not bool(old_entry.shown_as_locked), "Fall 9: alter Auftrag ohne Hinweis bleibt unsichtbar")

func _case_normalize() -> void:
	var locations := {"satellite_crash":{}}
	var plain: Dictionary = _probe()
	plain.erase("locked_hint")
	_check(not JOBS.normalize_job(plain, locations).has("locked_hint"), "Fall 10: ohne locked_hint kein Schluessel")
	plain["locked_hint"] = "  "
	_check(not JOBS.normalize_job(plain, locations).has("locked_hint"), "Fall 10: leerer locked_hint ohne Schluessel")
	_check(String(JOBS.normalize_job(_probe(), locations).get("locked_hint", "")) == HINT, "Fall 10: gesetzter locked_hint bleibt erhalten")
