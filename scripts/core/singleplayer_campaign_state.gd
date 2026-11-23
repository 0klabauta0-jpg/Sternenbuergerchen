extends RefCounted
## Persistent campaign owner. Runtime evidence is a separate trusted boundary,
## never read from command payloads supplied by UI.

const LOCATIONS: GDScript = preload("res://scripts/mission/singleplayer_location_contract.gd")
const JOBS: GDScript = preload("res://scripts/mission/singleplayer_job_contract.gd")
const COMMANDS: GDScript = preload("res://scripts/mission/singleplayer_campaign_command_contract.gd")

## Missionsende mit result "aborted" und einer dieser win_condition_type-Kennungen ist ein Rueckzug, kein Fehlschlag.
const RETREAT_WIN_CONDITIONS: Array = ["evacuation", "departure"]

var _locations: Dictionary = {}
var _jobs: Dictionary = {}
var _selected_location_id: String = "homebase"
var _selected_job_id: String = ""
var _departures_by_craft_id: Dictionary = {}
var _completion_receipts: Dictionary = {}
var _requests: Dictionary = {}
var _revision: int = 0
var _progress: Dictionary = {"recruited_outpost":false,"recruited_pilot":false,"crate_loaded":false,"crate_delivered":false,"second_pad_built":false}
var _enforce_sequence := true
# Unwired in-process preparation metadata, never campaign/save truth.
var _departure_preparation_authority: WeakRef
var _departure_preparation_epoch := 0
var _departure_preparation_seal := ""
var _prepared_departure_receipts: Dictionary = {}

func configure(locations: Dictionary = {}, jobs: Dictionary = {}, enforce_sequence: bool = true) -> Dictionary:
	_enforce_sequence = enforce_sequence
	var raw_locations: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/locations.json")) if locations.is_empty() else locations
	var raw_jobs: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/jobs.json")) if jobs.is_empty() else jobs
	if typeof(raw_locations) != TYPE_DICTIONARY or typeof(raw_jobs) != TYPE_DICTIONARY:
		return _reject("invalid_definitions", "Orts- oder Auftragsdaten fehlen")
	var normalized_locations: Dictionary = {}
	for key in raw_locations:
		if typeof(raw_locations[key]) != TYPE_DICTIONARY:
			return _reject("invalid_location", "Ortsdaten ungueltig")
		var location: Dictionary = LOCATIONS.normalize_location(raw_locations[key])
		if location.is_empty() or String(location.id) != String(key):
			return _reject("invalid_location", "Orts-ID widerspricht Daten")
		normalized_locations[String(key)] = location
	if not normalized_locations.has("homebase"):
		return _reject("missing_homebase", "Heimatbasis fehlt")
	var normalized_jobs: Dictionary = {}
	for key in raw_jobs:
		if typeof(raw_jobs[key]) != TYPE_DICTIONARY:
			return _reject("invalid_job", "Auftragsdaten ungueltig")
		var job: Dictionary = JOBS.normalize_job(raw_jobs[key], normalized_locations)
		if job.is_empty() or String(job.id) != String(key):
			return _reject("invalid_job", "Auftrag oder Zielort ungueltig")
		job["status"] = "offered"
		normalized_jobs[String(key)] = job
	_reset_departure_preparation()
	_locations = normalized_locations
	_jobs = normalized_jobs
	_selected_location_id = "homebase"
	_selected_job_id = ""
	_departures_by_craft_id.clear()
	_completion_receipts.clear()
	_requests.clear()
	_revision = 0
	_progress = {"recruited_outpost":false,"recruited_pilot":false,"crate_loaded":false,"crate_delivered":false,"second_pad_built":false}
	return {"ok": true}

func get_campaign_snapshot() -> Dictionary:
	var accepted: Array = []
	for id in _jobs:
		if String(_jobs[id].status) in ["accepted", "active"]:
			accepted.append(String(id))
	accepted.sort()
	var snapshot := {"locations": _locations.duplicate(true), "jobs": _jobs.duplicate(true), "accepted_job_ids": accepted, "selected_job_id": _selected_job_id, "selected_location_id": _selected_location_id, "departures_by_craft_id": _departures_by_craft_id.duplicate(true), "completion_receipts": _completion_receipts.duplicate(true), "progress":_progress.duplicate(true), "revision": _revision}
	for id in snapshot.jobs:
		var prior := String(snapshot.jobs[id].get("prerequisite_job_id",""))
		snapshot.jobs[id]["locked"] = _enforce_sequence and not prior.is_empty() and String(Dictionary(_jobs.get(prior,{})).get("status","")) != "completed"
	return snapshot

func get_completion_receipt(completion_id: String) -> Dictionary:
	return Dictionary(_completion_receipts.get(completion_id, {})).duplicate(true)

func apply_command(command: Dictionary, authority_context: Dictionary = {}) -> Dictionary:
	if not COMMANDS.validate_command(command) or _locations.is_empty():
		return _reject("invalid_command", "Kampagnenauftrag ungueltig")
	var request_id: String = String(command.request_id).strip_edges()
	var signature: String = JSON.stringify({"operation": command.operation, "payload": command.payload}, "", true)
	if _requests.has(request_id):
		if String(_requests[request_id].signature) != signature:
			return _reject("request_id_conflict", "Anfrage-ID bereits anders verwendet")
		var replay: Dictionary = _requests[request_id].result.duplicate(true)
		replay["replayed"] = true
		return replay
	var payload: Dictionary = command.payload
	var result: Dictionary
	match String(command.operation):
		"accept_job": result = _accept(payload)
		"select_destination": result = _select(payload)
		"bind_departure": result = _bind_departure(payload, authority_context)
		"activate_job": result = _activate(payload, authority_context)
		"complete_job": result = _complete(payload, authority_context)
		"fail_job": result = _fail(payload, authority_context)
		"retry_failed_job": result = _retry_failed(payload)
		"reopen_retreated_job": result = _reopen_retreated(payload)
		"upload_job": result = _upload(payload, authority_context)
		"claim_recruit", "load_crate", "unload_crate", "deliver_crate", "build_pad": result = _progress_action(String(command.operation),payload,authority_context)
		_: result = _reject("unknown_operation", "Aktion unbekannt")
	if bool(result.get("ok", false)):
		result["request_id"] = request_id
		result["operation"] = String(command.operation)
		_requests[request_id] = {"signature": signature, "result": result.duplicate(true)}
	return result

func _acceptance_gate(job_id: String) -> Dictionary:
	if not _jobs.has(job_id):
		return _reject("unknown_job", "Auftrag unbekannt")
	var prior := String(_jobs[job_id].get("prerequisite_job_id", ""))
	if _enforce_sequence and not prior.is_empty() and String(Dictionary(_jobs.get(prior, {})).get("status", "")) != "completed":
		return _reject("previous_job_required", "Zuerst den vorherigen Kampagnenauftrag abschließen")
	if _enforce_sequence and job_id == "benit_delivery" and not (bool(_progress.recruited_outpost) and bool(_progress.crate_loaded)):
		return _reject("outpost_preparation_required", "Zuerst die Person am Handelsposten aufnehmen und die Kiste bergen")
	if String(_jobs[job_id].status) not in ["offered", "accepted", "active"]:
		return _reject("job_closed", "Auftrag bereits abgeschlossen")
	return {"ok":true}

func get_job_availability(retry_allowed: bool = false) -> Dictionary:
	# The adapter supplies its actual Home/transit gate. This read has no requests,
	# revision changes or persisted projection fields.
	var result := {}
	for id: String in _jobs:
		var status := String(_jobs[id].status)
		var gate := _retry_gate(id) if status == "failed" else _acceptance_gate(id)
		if status == "failed" and gate.ok and not retry_allowed:
			gate = _reject("retry_requires_home", "Erst zur Basis zurückkehren, dann Auftrag erneut annehmen")
		# "shown_as_locked": gelistet (visible), aber nicht annehmbar, weil der Spieler selbst noch etwas erledigen muss
		# (Vorgaenger fertig, Person/Kiste am Handelsposten fehlen). Der Grund steht in reason/message.
		# Anfliegbar macht ihn das nicht: validate_location_visit ueberspringt gesperrt gelistete Auftraege.
		# Nicht zu verwechseln mit jobs[id].locked im Schnappschuss (dort: Vorgaenger noch offen).
		var shown_as_locked := status == "offered" and String(gate.get("reason", "")) == "outpost_preparation_required"
		result[id] = {"visible":status in ["accepted", "active", "completed", "pending_upload"] or bool(gate.ok) or shown_as_locked, "can_accept":status in ["offered", "failed"] and bool(gate.ok), "shown_as_locked":shown_as_locked, "reason":String(gate.get("reason", "")), "message":String(gate.get("message", ""))}
	return result

func validate_location_visit(location_id: String, retry_allowed: bool = false) -> Dictionary:
	if not _locations.has(location_id): return _reject("unknown_location", "Zielort unbekannt")
	if location_id == "homebase" or bool(_locations[location_id].get("free_visit", false)) or not _enforce_sequence: return {"ok":true}
	var availability := get_job_availability(retry_allowed)
	for id: String in _jobs:
		# Ein gesperrt gelisteter Auftrag oeffnet seinen Ort nicht.
		if String(_jobs[id].location_id) == location_id and bool(availability[id].visible) and not bool(availability[id].shown_as_locked): return {"ok":true}
	return _reject("tutorial_locked", "Zuerst den vorherigen Kampagnenauftrag abschließen und Chips zuhause hochladen")

func _accept(payload: Dictionary) -> Dictionary:
	var job_id := String(payload.get("job_id", ""))
	var gate := _acceptance_gate(job_id)
	if not gate.ok: return gate
	if String(_jobs[job_id].status) in ["accepted", "active"]:
		return {"ok":true, "job_id":job_id, "already_accepted":true}
	_jobs[job_id].status = "accepted"
	_revision += 1
	return {"ok":true, "job_id":job_id, "message":"Auftrag angenommen"}

func _select(payload: Dictionary) -> Dictionary:
	var location_id: String = String(payload.get("location_id", ""))
	var job_id: String = String(payload.get("job_id", ""))
	if not _locations.has(location_id):
		return _reject("unknown_location", "Zielort unbekannt")
	if not job_id.is_empty():
		if not _jobs.has(job_id) or not String(_jobs[job_id].status) in ["accepted", "active"]:
			return _reject("job_not_accepted", "Auftrag zuerst annehmen")
		if String(_jobs[job_id].location_id) != location_id:
			return _reject("job_location_mismatch", "Auftrag gehoert zu einem anderen Ort")
	_selected_location_id = location_id
	_selected_job_id = job_id
	_revision += 1
	return {"ok": true, "location_id": location_id, "job_id": job_id, "message": "Zielort ausgewaehlt"}

func _bind_departure(payload: Dictionary, context: Dictionary) -> Dictionary:
	var validation: Dictionary = validate_departure(payload, context)
	if not bool(validation.get("ok", false)):
		return validation
	var departure: Dictionary = validation.departure
	_departures_by_craft_id[String(departure.craft_id)] = departure.duplicate(true)
	_revision += 1
	return validation

func validate_departure(payload: Dictionary, authority_context: Dictionary = {}) -> Dictionary:
	# Used by the synchronous runtime transaction before either owner commits.
	var context: Dictionary = authority_context
	if not bool(context.get("departure_authorized", false)):
		return _reject("departure_not_authorized", "Abflug nicht bestaetigt")
	var craft_id: String = String(payload.get("craft_id", ""))
	var origin: String = String(payload.get("origin_location_id", ""))
	var destination: String = String(payload.get("destination_location_id", ""))
	var pad_id: String = String(payload.get("landing_pad_id", ""))
	var job_id: String = String(payload.get("job_id", ""))
	if craft_id.is_empty() or not _locations.has(origin) or not _locations.has(destination) or origin == destination:
		return _reject("invalid_departure", "Schiff oder Ortsverbindung ungueltig")
	if not Array(_locations[origin].landing_pad_ids).has(pad_id) and not (origin == "homebase" and Array(context.get("built_home_pad_ids", [])).has(pad_id)):
		return _reject("invalid_pad", "Abflugpad gehoert nicht zum Ausgangsort")
	if not job_id.is_empty():
		if not _jobs.has(job_id) or not String(_jobs[job_id].status) in ["accepted", "active"] or String(_jobs[job_id].location_id) != destination:
			return _reject("job_location_mismatch", "Auftrag passt nicht zum Abflugziel")
	return {"ok": true, "departure": {"craft_id": craft_id, "origin_location_id": origin, "destination_location_id": destination, "landing_pad_id": pad_id, "job_id": job_id}}

func _activate(payload: Dictionary, context: Dictionary) -> Dictionary:
	var job_id: String = String(payload.get("job_id", ""))
	var craft_id: String = String(payload.get("craft_id", ""))
	if not bool(context.get("departure_authorized", false)) or not _jobs.has(job_id) or not _departures_by_craft_id.has(craft_id) or String(_departures_by_craft_id[craft_id].job_id) != job_id:
		return _reject("activation_not_authorized", "Kein bestaetigter Abflug fuer diesen Auftrag")
	if String(_jobs[job_id].status) == "active":
		return {"ok": true, "job_id": job_id, "already_active": true}
	if String(_jobs[job_id].status) != "accepted":
		return _reject("job_not_accepted", "Auftrag nicht angenommen")
	_jobs[job_id].status = "active"
	_jobs[job_id]["craft_id"] = craft_id
	_revision += 1
	return {"ok": true, "job_id": job_id}

func _complete(payload: Dictionary, context: Dictionary) -> Dictionary:
	var job_id: String = String(payload.get("job_id", ""))
	if not _jobs.has(job_id) or String(_jobs[job_id].status) != "active":
		return _reject("job_not_active", "Auftrag nicht aktiv")
	var job: Dictionary = _jobs[job_id]
	var evidence: Dictionary = Dictionary(context.get("runtime_evidence", {}))
	var gates: Dictionary = Dictionary(evidence.get("mission_scenario_runtime_gates", {}))
	if String(evidence.get("scenario_id", "")) != String(job.scenario_id) or String(evidence.get("result", "")) != "victory" or not bool(gates.get("all_gates_complete", false)):
		return _reject("unverified_completion", "Runtime-Abschluss fehlt")
	var completed_steps: Array = Array(gates.get("completed_step_ids", []))
	for step in job.required_step_ids:
		if not completed_steps.has(step):
			return _reject("incomplete_objectives", "Bergung oder Rueckkehr noch offen")
	if payload.has("craft_id") and String(payload.craft_id) != String(job.get("craft_id", "")):
		return _reject("wrong_craft", "Abschluss gehoert zu anderem Schiff")
	if _enforce_sequence and String(job.id) == "benit_delivery" and not bool(_progress.crate_delivered):
		return _reject("crate_not_delivered", "Transportkiste am Handelsposten abgeben")
	if _enforce_sequence and bool(job.get("home_upload",false)):
		_jobs[job_id].status = "pending_upload"
		if _selected_job_id == job_id:
			_selected_job_id = ""
		_revision += 1
		return {"ok":true,"job_id":job_id,"pending_upload":true,"message":"Chip gesichert. Zur Basis bringen und am Terminal hochladen."}
	return _finalize(job_id)

func _finalize(job_id: String) -> Dictionary:
	var job: Dictionary = _jobs[job_id]
	var completion_id: String = job_id + ":completed"
	var receipt := {"completion_id": completion_id, "job_id": job_id, "scenario_id": String(job.scenario_id), "craft_id": String(job.get("craft_id", "")), "reward": Dictionary(job.reward).duplicate(true), "runtime_verified": true}
	_completion_receipts[completion_id] = receipt
	_jobs[job_id].status = "completed"
	if _selected_job_id == job_id:
		_selected_job_id = ""
	_revision += 1
	return {"ok": true, "job_id": job_id, "completion_receipt": receipt.duplicate(true), "message": "Auftrag abgeschlossen"}

func _upload(payload: Dictionary, context: Dictionary) -> Dictionary:
	var id := String(payload.get("job_id",""))
	if not bool(context.get("at_home",false)):
		return _reject("upload_requires_home","Chip-Upload nur am Terminal der Heimatbasis")
	var job: Dictionary = _jobs.get(id, {})
	var status := String(job.get("status", ""))
	# Playtest L01: a chip that physically reached the home base proves recovery and return,
	# even when the mission result never reported its last step and the job stayed active.
	var carried_home := status == "active" and bool(job.get("home_upload", false)) and bool(context.get("chip_at_home", false))
	if status != "pending_upload" and not carried_home:
		return _reject("no_chip","Kein geborgener Chip zum Hochladen")
	return _finalize(id)

func _progress_action(operation: String, payload: Dictionary, context: Dictionary) -> Dictionary:
	if not bool(context.get("runtime_authorized",false)):
		return _reject("runtime_required","Bestätigte Ortsinteraktion fehlt")
	var key := ""
	match operation:
		"claim_recruit":
			var rescue := String(payload.get("kind","outpost")) == "pilot"
			var job := "buccaneer_rescue" if rescue else "outpost_recovery"
			var verified_outpost := not rescue and bool(context.get("outpost_cleared",false)) and String(Dictionary(_jobs.get(job,{})).get("status","")) == "active"
			if String(Dictionary(_jobs.get(job,{})).get("status","")) != "completed" and not verified_outpost:
				return _reject("recruit_not_ready","Zuerst den zugehörigen Auftrag gewinnen")
			key = "recruited_pilot" if rescue else "recruited_outpost"
		"load_crate":
			if String(Dictionary(_jobs.get("outpost_recovery",{})).get("status","")) != "completed":
				return _reject("crate_not_ready","Zuerst den Außenposten sichern")
			key = "crate_loaded"
		"unload_crate":
			# LC2i I5: Ging das Schiff mit der Auftragsfracht verloren, steht die Kiste wieder am Ladeort bereit (Merker zurueck; kein neuer Schluessel).
			if not _progress.crate_loaded or bool(_progress.crate_delivered):
				return {"ok":true,"changed":false}
			_progress.crate_loaded = false
			_revision += 1
			return {"ok":true,"changed":true,"progress_key":"crate_loaded"}
		"deliver_crate":
			if not _progress.crate_loaded or String(Dictionary(_jobs.get("benit_delivery",{})).get("status","")) != "active":
				return _reject("crate_not_loaded","Lieferauftrag aktivieren und C-Benit-Kiste mitbringen")
			key = "crate_delivered"
		"build_pad":
			if not _progress.recruited_pilot or not bool(context.get("at_home",false)):
				return _reject("pad_not_ready","Zuerst den Buccaneer-Piloten retten und zur Basis zurückkehren")
			key = "second_pad_built"
	if bool(_progress[key]):
		return {"ok":true,"changed":false}
	_progress[key] = true
	_revision += 1
	return {"ok":true,"changed":true,"progress_key":key}

func _fail(payload: Dictionary, context: Dictionary) -> Dictionary:
	var job_id: String = String(payload.get("job_id", ""))
	if not _jobs.has(job_id) or not String(_jobs[job_id].status) in ["accepted", "active"]:
		return _reject("job_not_active", "Auftrag nicht angenommen")
	var evidence: Dictionary = Dictionary(context.get("runtime_evidence", {}))
	if not bool(context.get("mission_aborted", false)) and not String(evidence.get("result", "")) in ["defeat", "aborted", "timeout"]:
		return _reject("failure_not_authorized", "Fehlschlag nicht bestaetigt")
	_jobs[job_id].status = "failed"
	# Rueckzug: nur aus dem bestaetigten Ergebnis, nie aus dem Kontext (mission_aborted = bewusstes Aufgeben).
	var retreat: bool = String(evidence.get("result", "")) == "aborted" and RETREAT_WIN_CONDITIONS.has(String(evidence.get("win_condition_type", "")))
	if retreat:
		_jobs[job_id]["retreat_count"] = int(_jobs[job_id].get("retreat_count", 0)) + 1
		_jobs[job_id]["reopen_at_home"] = true
	if _selected_job_id == job_id:
		_selected_job_id = ""
	_revision += 1
	return {"ok": true, "job_id": job_id, "retreat": retreat, "message": "Rückzug. Auftrag bleibt offen." if retreat else "Auftrag beendet"}

func _reject(reason: String, message: String) -> Dictionary:
	return {"ok": false, "reason": reason, "message": message}

func _retry_gate(job_id: String) -> Dictionary:
	if not _jobs.has(job_id) or String(_jobs[job_id].status) != "failed" or _completion_receipts.has(job_id + ":completed"):
		return _reject("job_not_failed", "Nur fehlgeschlagene Auftraege erneut annehmen")
	return {"ok":true}

func _retry_failed(payload: Dictionary) -> Dictionary:
	var job_id := String(payload.get("job_id", ""))
	var gate := _retry_gate(job_id)
	if not gate.ok: return gate
	_reopen_job(job_id)
	return {"ok":true,"job_id":job_id,"message":"Auftrag erneut angenommen"}

func _reopen_job(job_id: String) -> void:
	_jobs[job_id].status = "accepted"
	_jobs[job_id].erase("craft_id")
	if _jobs[job_id].has("reopen_at_home"):
		_jobs[job_id]["reopen_at_home"] = false
	for craft_id in _departures_by_craft_id.keys():
		if String(_departures_by_craft_id[craft_id].get("job_id", "")) == job_id:
			_departures_by_craft_id.erase(craft_id)
	_revision += 1

func _reopen_retreated(payload: Dictionary) -> Dictionary:
	var job_id := String(payload.get("job_id", ""))
	if not _jobs.has(job_id) or String(_jobs[job_id].status) != "failed" or not bool(_jobs[job_id].get("reopen_at_home", false)) or _completion_receipts.has(job_id + ":completed"):
		return _reject("job_not_retreated", "Nur nach einem Rückzug wieder öffnen")
	_reopen_job(job_id)
	return {"ok":true,"job_id":job_id,"message":"Auftrag wieder offen"}

func export_state() -> Dictionary:
	var state := get_campaign_snapshot()
	state["schema_version"] = 1
	state["enforce_sequence"] = _enforce_sequence
	state["requests"] = _requests.duplicate(true)
	return state

func restore_state(data: Dictionary) -> Dictionary:
	# Rebuild definitions from current content, never trust persisted mission/reward definitions.
	var fresh = get_script().new()
	if typeof(data.get("enforce_sequence",true)) != TYPE_BOOL or not fresh.configure({}, {}, bool(data.get("enforce_sequence",true))).get("ok", false):
		return _reject("invalid_definitions", "Aktuelle Auftragsdaten fehlen")
	var result: Dictionary = fresh._validate_saved_state(data)
	if not result.ok:
		return result
	_reset_departure_preparation()
	_locations = fresh._locations.duplicate(true)
	_enforce_sequence = fresh._enforce_sequence
	_jobs = fresh._jobs.duplicate(true)
	for job_id in _jobs:
		_jobs[job_id].status = String(data.jobs[job_id].status)
		if data.jobs[job_id].has("craft_id"):
			_jobs[job_id]["craft_id"] = String(data.jobs[job_id].craft_id)
		# Nur die zwei Rueckzugsfelder aus dem Stand uebernehmen; fehlen sie, gelten die Standardwerte (0 / false).
		if data.jobs[job_id].has("retreat_count"):
			_jobs[job_id]["retreat_count"] = int(data.jobs[job_id].retreat_count)
		if data.jobs[job_id].has("reopen_at_home"):
			_jobs[job_id]["reopen_at_home"] = bool(data.jobs[job_id].reopen_at_home)
	_selected_location_id = String(data.selected_location_id)
	_selected_job_id = String(data.selected_job_id)
	_departures_by_craft_id = data.departures_by_craft_id.duplicate(true)
	_completion_receipts = data.completion_receipts.duplicate(true)
	_requests = data.requests.duplicate(true)
	_progress = Dictionary(data.get("progress",_progress)).duplicate(true)
	_revision = int(data.revision)
	# Orte mit anderem Kartenpfad: der Stand ist angenommen; wer einen Ortszustand traegt (Basisstand-Lader, Einsatz-Zwischenstand), entscheidet selbst.
	if result.has("relocated_location_ids"):
		return {"ok":true, "relocated_location_ids":result.relocated_location_ids}
	return {"ok":true}

func _validate_saved_state(data: Dictionary) -> Dictionary:
	if data.get("schema_version") != 1 or not _saved_integer(data.get("revision")):
		return _reject("invalid_campaign_state", "Kampagnenstand ungueltig")
	for field in ["locations", "jobs", "departures_by_craft_id", "completion_receipts", "requests"]:
		if typeof(data.get(field)) != TYPE_DICTIONARY:
			return _reject("invalid_campaign_state", "Kampagnenfelder fehlen")
	if typeof(data.get("progress")) != TYPE_DICTIONARY or data.progress.size() != _progress.size():
		return _reject("invalid_progress","Kampagnenfortschritt fehlt")
	for key in _progress:
		if typeof(data.progress.get(key)) != TYPE_BOOL: return _reject("invalid_progress","Kampagnenfortschritt ungültig")
	for pair in [["recruited_outpost","outpost_recovery"],["crate_loaded","outpost_recovery"],["crate_delivered","outpost_recovery"],["recruited_pilot","buccaneer_rescue"],["second_pad_built","buccaneer_rescue"]]:
		var allowed := ["active","completed"] if pair[0] == "recruited_outpost" else ["completed"]
		if bool(data.progress.get(pair[0],false)) and String(Dictionary(data.jobs.get(pair[1],{})).get("status","")) not in allowed: return _reject("invalid_progress","Fortschritt ohne Missionsabschluss")
	if bool(data.progress.second_pad_built) and not bool(data.progress.recruited_pilot): return _reject("invalid_progress","Pad ohne geretteten Piloten")
	var location_verdict: Dictionary = _compare_locations(data.locations)
	if not location_verdict.ok or data.jobs.size() != _jobs.size() or not _locations.has(data.get("selected_location_id", "")):
		return _reject("stale_campaign_definitions", "Ortsdaten geaendert")
	for job_id in _jobs:
		if typeof(data.jobs.get(job_id)) != TYPE_DICTIONARY:
			return _reject("invalid_job_state", "Auftrag fehlt")
		var saved: Dictionary = data.jobs[job_id].duplicate(true)
		saved.erase("locked")
		# Rueckzugsfelder sind Spielstand, keine Auftragsdefinition: getrennt auf Typ pruefen, vor dem Definitionsvergleich entfernen.
		if saved.has("retreat_count") and not _saved_integer(saved.retreat_count):
			return _reject("invalid_job_state", "Rückzugszähler ungültig")
		if saved.has("reopen_at_home") and (typeof(saved.reopen_at_home) != TYPE_BOOL or (bool(saved.reopen_at_home) and String(saved.get("status", "")) != "failed")):
			return _reject("invalid_job_state", "Rückzugsmerker ungültig")
		saved.erase("retreat_count")
		saved.erase("reopen_at_home")
		if String(saved.get("status", "")) not in ["offered", "accepted", "active", "completed", "failed", "pending_upload"]:
			return _reject("invalid_job_status", "Auftragsstatus ungueltig")
		var status := String(saved.status)
		var prior := String(_jobs[job_id].get("prerequisite_job_id",""))
		if _enforce_sequence and status != "offered" and not prior.is_empty() and String(Dictionary(data.jobs.get(prior,{})).get("status","")) != "completed": return _reject("invalid_job_order","Auftragsreihenfolge ungültig")
		if status == "pending_upload" and not bool(_jobs[job_id].get("home_upload",false)): return _reject("invalid_upload","Auftrag enthält keinen hochzuladenden Chip")
		saved["status"] = "offered"
		saved.erase("craft_id")
		if JSON.stringify(JSON.parse_string(JSON.stringify(saved)), "", true) != JSON.stringify(JSON.parse_string(JSON.stringify(_jobs[job_id])), "", true):
			return _reject("stale_job_definition", "Auftragsdefinition geaendert")
		var receipt_id := String(job_id) + ":completed"
		if (status == "completed") != data.completion_receipts.has(receipt_id):
			return _reject("invalid_completion_receipt", "Auftragsbeleg fehlt")
	for receipt_id in data.completion_receipts:
		var receipt: Variant = data.completion_receipts[receipt_id]
		if typeof(receipt) != TYPE_DICTIONARY or not _jobs.has(receipt.get("job_id", "")):
			return _reject("invalid_completion_receipt", "Auftragsbeleg ungueltig")
		var job: Dictionary = _jobs[receipt.job_id]
		if String(receipt_id) != String(receipt.job_id) + ":completed" or receipt.get("completion_id") != receipt_id or receipt.get("runtime_verified") != true or receipt.get("scenario_id") != job.scenario_id or not _saved_equal(receipt.get("reward"), job.reward):
			return _reject("invalid_completion_receipt", "Auftragsbeleg widerspricht Daten")
	for craft_id in data.departures_by_craft_id:
		var departure: Variant = data.departures_by_craft_id[craft_id]
		if typeof(departure) != TYPE_DICTIONARY or departure.get("craft_id") != craft_id or not _locations.has(departure.get("origin_location_id", "")) or not _locations.has(departure.get("destination_location_id", "")):
			return _reject("invalid_saved_departure", "Abflugstand ungueltig")
		if not Array(_locations[departure.origin_location_id].landing_pad_ids).has(departure.get("landing_pad_id", "")) or departure.origin_location_id == departure.destination_location_id:
			return _reject("invalid_saved_departure", "Abflugpad ungueltig")
		var departure_job := String(departure.get("job_id", ""))
		if not departure_job.is_empty() and (not _jobs.has(departure_job) or String(data.jobs[departure_job].location_id) != String(departure.destination_location_id)):
			return _reject("invalid_saved_departure", "Abflugstand ungueltig")
	var selected := String(data.get("selected_job_id", ""))
	if not selected.is_empty() and (not _jobs.has(selected) or String(data.jobs[selected].status) not in ["accepted", "active"] or String(data.jobs[selected].location_id) != String(data.selected_location_id)):
		return _reject("invalid_selected_job", "Auftragsauswahl ungueltig")
	for request_id in data.requests:
		var request: Variant = data.requests[request_id]
		if typeof(request_id) != TYPE_STRING or String(request_id).strip_edges().is_empty() or typeof(request) != TYPE_DICTIONARY or typeof(request.get("signature")) != TYPE_STRING or typeof(request.get("result")) != TYPE_DICTIONARY or request.result.get("ok") != true:
			return _reject("invalid_requests", "Anfragebelege ungueltig")
		var signature: Variant = JSON.parse_string(request.signature)
		if typeof(signature) != TYPE_DICTIONARY or typeof(signature.get("payload")) != TYPE_DICTIONARY or typeof(signature.get("operation")) != TYPE_STRING or not COMMANDS.validate_command(COMMANDS.build_command(signature.operation, signature.payload, request_id)) or request.result.get("request_id") != request_id or request.result.get("operation") != signature.operation:
			return _reject("invalid_requests", "Anfragebeleg widerspricht Signatur")
	if not location_verdict.relocated.is_empty():
		return {"ok":true, "relocated_location_ids":location_verdict.relocated}
	return {"ok":true}

func _saved_integer(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) >= 0 and float(value) == floor(float(value)) and float(value) <= 2147483647

func _saved_equal(a: Variant, b: Variant) -> bool:
	return JSON.stringify(JSON.parse_string(JSON.stringify(a)), "", true) == JSON.stringify(JSON.parse_string(JSON.stringify(b)), "", true)


## Ortsfelder, an denen kein gespeicherter Zustand haengt: sie werden beim Laden nicht verglichen, es gilt der heutige Wert.
## name: nur Anzeige (campaign_display_catalog.location_name); gespeichert wird er nirgends ausser im Ortsblock selbst.
## region_position: nur Sternkarte (star_map_canvas, star_map_screen); Reisekosten stehen in trade_offers.json, nicht hier.
const LOCATION_PRESENTATION_FIELDS: Array = ["name", "region_position"]
## Kartenpfad: wird angenommen, der Ort beginnt dann frisch (siehe CampaignCheckpointStore.adopt_relocated_maps).
## Alle uebrigen Felder (id, scenario_file_path, landing_pad_ids, services, free_visit) bleiben streng: an ihnen haengen
## Auftraege, Abfluege, Landeplaetze und Versorgungsdienste im Stand.
const LOCATION_MAP_FIELD := "map_file_path"

## {"ok":bool, "relocated":Array}. relocated: Orte, deren gespeicherter Kartenpfad vom heutigen abweicht (nur bei ok).
## Polisa is an additive free visit; every other location must exist exactly once, with all strict fields unchanged.
func _compare_locations(saved: Dictionary) -> Dictionary:
	var current := _locations.duplicate(true)
	if not saved.has("polisa") and bool(Dictionary(current.get("polisa", {})).get("free_visit", false)): current.erase("polisa")
	if saved.size() != current.size(): return {"ok":false}
	var relocated: Array = []
	for id in saved:
		if typeof(id) != TYPE_STRING or not current.has(id) or typeof(saved[id]) != TYPE_DICTIONARY: return {"ok":false}
		var old: Dictionary = saved[id]
		if not _saved_location_presentable(old): return {"ok":false}
		if _strict_location_signature(old) != _strict_location_signature(current[id]): return {"ok":false}
		if String(old[LOCATION_MAP_FIELD]) != String(current[id][LOCATION_MAP_FIELD]): relocated.append(String(id))
	relocated.sort()
	return {"ok":true, "relocated":relocated}

func _compatible_locations(saved: Dictionary) -> bool:
	return bool(_compare_locations(saved).ok)

## Die streng verglichenen Felder eines Ortes (alles ausser Darstellung und Kartenpfad), als stabiler Text.
func _strict_location_signature(location: Dictionary) -> String:
	var strict := location.duplicate(true)
	for field in LOCATION_PRESENTATION_FIELDS: strict.erase(field)
	strict.erase(LOCATION_MAP_FIELD)
	return JSON.stringify(strict, "", true)

## Die nicht verglichenen Felder muessen im Stand trotzdem vorhanden und brauchbar sein (wie singleplayer_location_contract).
func _saved_location_presentable(location: Dictionary) -> bool:
	if typeof(location.get("name")) != TYPE_STRING or String(location.name).strip_edges().is_empty(): return false
	var position: Variant = location.get("region_position")
	if typeof(position) != TYPE_ARRAY or position.size() != 2: return false
	for coordinate in position:
		if typeof(coordinate) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(coordinate)): return false
	var map_path: Variant = location.get(LOCATION_MAP_FIELD)
	return typeof(map_path) == TYPE_STRING and String(map_path).begins_with("res://maps/") and String(map_path).ends_with(".json")

## Fuer den Lader eines Basisstands: schreibt die heutigen Ortsdefinitionen in den gespeicherten Campaign-Block (Darstellung und
## Kartenpfad von heute) und nennt die Orte, deren Kartenpfad sich geaendert hat. Ist der Ortsblock nicht vertraeglich
## (streng geprueftes Feld, fehlender oder zusaetzlicher Ort), bleibt der Stand unveraendert und das Ergebnis leer;
## restore_state lehnt ihn dann mit stale_campaign_definitions ab.
static func adopt_current_location_definitions(campaign_state: Dictionary) -> Array:
	var saved: Variant = campaign_state.get("locations")
	if typeof(saved) != TYPE_DICTIONARY: return []
	var fresh = load("res://scripts/core/singleplayer_campaign_state.gd").new()
	if not fresh.configure().get("ok", false): return []
	var verdict: Dictionary = fresh._compare_locations(saved)
	if not verdict.ok: return []
	for id in saved.keys():
		if JSON.stringify(saved[id], "", true) != JSON.stringify(fresh._locations[id], "", true): saved[id] = fresh._locations[id].duplicate(true)
	return verdict.relocated


func _reset_departure_preparation() -> void:
	_departure_preparation_epoch += 1
	_departure_preparation_seal = str(get_instance_id()) + ":" + str(_departure_preparation_epoch) + ":" + str(Time.get_ticks_usec())
	_departure_preparation_authority = null
	_prepared_departure_receipts.clear()

func configure_departure_preparation_authority(authority: Object) -> Dictionary:
	if not is_instance_valid(authority): return _reject("departure_authority_required", "Gebundener Runtimeowner fehlt")
	if _departure_preparation_authority != null:
		return {"ok":true} if _departure_preparation_authority.get_ref() == authority else _reject("departure_authority_already_bound", "Owner ist bereits gebunden")
	_departure_preparation_authority = weakref(authority)
	return {"ok":true}

func _normalize_prepared_departure_context(context: Dictionary) -> Dictionary:
	if context.size() != 3 or _departure_preparation_authority == null or not is_instance_valid(_departure_preparation_authority.get_ref()) or context.get("authority") != _departure_preparation_authority.get_ref():
		return _reject("departure_authority_required", "Nur gebundener Inprocessowner darf vorbereiten")
	if typeof(context.get("transaction_id")) != TYPE_STRING or String(context.transaction_id).strip_edges().is_empty() or typeof(context.get("built_home_pad_ids")) != TYPE_ARRAY:
		return _reject("invalid_departure_context", "Transaktions- oder Padkontext fehlt")
	var pads: Array = []
	for pad: Variant in context.built_home_pad_ids:
		if typeof(pad) != TYPE_STRING or String(pad).is_empty(): return _reject("invalid_departure_context", "Padkontext ist ungueltig")
		if not pads.has(pad): pads.append(pad)
	pads.sort()
	return {"ok":true,"authority_instance_id":_departure_preparation_authority.get_ref().get_instance_id(),"transaction_id":String(context.transaction_id),"built_home_pad_ids":pads}

func _prepared_departure_command(command: Dictionary, operation: String) -> Dictionary:
	if not COMMANDS.validate_command(command) or String(command.operation) != operation: return {}
	var normalized := command.duplicate(true)
	normalized["request_id"] = String(command.request_id).strip_edges()
	return normalized

func _prepared_departure_signature(binding: Dictionary, activation: Dictionary, context: Dictionary) -> String:
	return JSON.stringify({"binding":binding,"activation":activation,"context":context}, "", true)

func _prepared_departure_inputs(binding: Dictionary, activation: Dictionary, context: Dictionary) -> String:
	var payload: Dictionary = binding.payload
	var craft_id := String(payload.get("craft_id", ""))
	var job_id := String(payload.get("job_id", ""))
	var bind_id := String(binding.request_id)
	var activate_id := String(activation.get("request_id", ""))
	return JSON.stringify({"revision":_revision,"selected_location_id":_selected_location_id,"selected_job_id":_selected_job_id,
		"origin":_locations.get(String(payload.get("origin_location_id", "")), {}),"destination":_locations.get(String(payload.get("destination_location_id", "")), {}),
		"job":_jobs.get(job_id, {}),"binding_present":_departures_by_craft_id.has(craft_id),"binding":_departures_by_craft_id.get(craft_id, {}),
		"pads":context.built_home_pad_ids,"bind_receipt_present":_requests.has(bind_id),"bind_receipt":_requests.get(bind_id, {}),
		"activate_receipt_present":not activate_id.is_empty() and _requests.has(activate_id),"activate_receipt":_requests.get(activate_id, {})}, "", true)

func prepare_departure(binding_command: Dictionary, activation_command_or_empty: Dictionary, trusted_context: Dictionary) -> Dictionary:
	var context := _normalize_prepared_departure_context(trusted_context)
	if not context.get("ok", false): return context
	var binding := _prepared_departure_command(binding_command, "bind_departure")
	var activation := {} if activation_command_or_empty.is_empty() else _prepared_departure_command(activation_command_or_empty, "activate_job")
	if binding.is_empty() or (not activation_command_or_empty.is_empty() and activation.is_empty()): return _reject("invalid_departure_commands", "Abflugcommands sind ungueltig")
	var payload: Dictionary = binding.payload
	var craft_id := String(payload.get("craft_id", ""))
	var job_id := String(payload.get("job_id", ""))
	if job_id.is_empty() != activation.is_empty(): return _reject("departure_activation_mismatch", "Auftrag und Aktivierung passen nicht zusammen")
	if not activation.is_empty() and (String(activation.payload.get("craft_id", "")) != craft_id or String(activation.payload.get("job_id", "")) != job_id or activation.request_id == binding.request_id):
		return _reject("departure_activation_mismatch", "Aktivierung gehoert nicht zu diesem Abflug")
	var signature := _prepared_departure_signature(binding, activation, context)
	var transaction_id := String(context.transaction_id)
	if _prepared_departure_receipts.has(transaction_id):
		var receipt: Dictionary = _prepared_departure_receipts[transaction_id]
		if String(receipt.signature) != signature: return _reject("transaction_id_conflict", "Gruppen-ID wurde anders verwendet")
		var replay := {"ok":true,"owner_instance_id":get_instance_id(),"owner_epoch":_departure_preparation_epoch,"context":context,"signature":signature,"replay":true}
		replay["seal"] = _sign_prepared_departure(replay)
		return replay
	if _requests.has(String(binding.request_id)) or (not activation.is_empty() and _requests.has(String(activation.request_id))):
		return _reject("ambiguous_partial_departure", "Alte Teilbelege beweisen keinen vollstaendigen Gruppencommit")
	if not job_id.is_empty() and _jobs.has(job_id) and String(_jobs[job_id].get("status", "")) == "active" and String(_jobs[job_id].get("craft_id", "")) != craft_id:
		return _reject("ambiguous_active_job_owner", "Aktiver Auftrag ist nicht eindeutig diesem Schiff zugeordnet")
	var gate := validate_departure(payload, {"departure_authorized":true,"built_home_pad_ids":context.built_home_pad_ids})
	if not gate.get("ok", false): return gate
	# Only inputs read by _bind_departure/_activate/apply_command are copied.
	# No configure, file I/O, save export/restore or replacement of the live owner.
	var staged = get_script().new()
	for location_id: String in [String(payload.origin_location_id),String(payload.destination_location_id)]: staged._locations[location_id] = Dictionary(_locations[location_id]).duplicate(true)
	if not job_id.is_empty(): staged._jobs[job_id] = Dictionary(_jobs[job_id]).duplicate(true)
	if _departures_by_craft_id.has(craft_id): staged._departures_by_craft_id[craft_id] = Dictionary(_departures_by_craft_id[craft_id]).duplicate(true)
	staged._revision = _revision
	var command_context := {"departure_authorized":true,"built_home_pad_ids":context.built_home_pad_ids.duplicate()}
	var bound: Dictionary = staged.apply_command(binding, command_context)
	if not bound.get("ok", false): return bound
	var activated := {}
	if not activation.is_empty():
		activated = staged.apply_command(activation, command_context)
		if not activated.get("ok", false): return activated
	var patch := {"craft_id":craft_id,"binding":Dictionary(staged._departures_by_craft_id[craft_id]).duplicate(true),"job_id":job_id,
		"revision_delta":int(staged._revision) - _revision,"receipts":{},
		"result":{"ok":true,"transaction_id":transaction_id,"departure":Dictionary(bound.departure).duplicate(true),"binding_result":bound.duplicate(true)}}
	patch.receipts[String(binding.request_id)] = Dictionary(staged._requests[String(binding.request_id)]).duplicate(true)
	if not activation.is_empty():
		patch["job_patch"] = {"status":String(staged._jobs[job_id].status),"craft_id":String(staged._jobs[job_id].get("craft_id", ""))}
		patch.receipts[String(activation.request_id)] = Dictionary(staged._requests[String(activation.request_id)]).duplicate(true)
		patch.result["activation_result"] = activated.duplicate(true)
	var candidate := {"ok":true,"owner_instance_id":get_instance_id(),"owner_epoch":_departure_preparation_epoch,"context":context,
		"signature":signature,"binding_command":binding,"activation_command":activation,
		"inputs":_prepared_departure_inputs(binding, activation, context),"patch":patch}
	candidate["seal"] = _sign_prepared_departure(candidate)
	return candidate

func _sign_prepared_departure(candidate: Dictionary) -> String:
	var content := candidate.duplicate(true)
	content.erase("seal")
	return (_departure_preparation_seal + JSON.stringify(content, "", true)).sha256_text()

func validate_prepared_departure(candidate: Dictionary, trusted_context: Dictionary) -> Dictionary:
	var context := _normalize_prepared_departure_context(trusted_context)
	if not context.get("ok", false): return context
	if not candidate.get("ok", false) or int(candidate.get("owner_instance_id", 0)) != get_instance_id() or int(candidate.get("owner_epoch", -1)) != _departure_preparation_epoch or String(candidate.get("seal", "")) != _sign_prepared_departure(candidate):
		return _reject("invalid_departure_candidate", "Vorbereitung gehoert nicht zu diesem Ownerzustand")
	if JSON.stringify(context, "", true) != JSON.stringify(candidate.get("context", {}), "", true): return _reject("departure_context_changed", "Rootkontext hat sich geaendert")
	var transaction_id := String(context.transaction_id)
	if _prepared_departure_receipts.has(transaction_id):
		var receipt: Dictionary = _prepared_departure_receipts[transaction_id]
		if String(receipt.signature) != String(candidate.signature): return _reject("transaction_id_conflict", "Gruppen-ID wurde anders verwendet")
		return {"ok":true,"replayed":true,"result":Dictionary(receipt.result).duplicate(true)}
	if String(candidate.get("inputs", "")) != _prepared_departure_inputs(candidate.binding_command, candidate.activation_command, context):
		return _reject("departure_inputs_changed", "Relevante Campaigninputs oder Teilbelege haben sich geaendert")
	return {"ok":true}

func commit_prepared_departure(candidate: Dictionary, trusted_context: Dictionary) -> Dictionary:
	var validation := validate_prepared_departure(candidate, trusted_context)
	return _publish_prepared_departure(candidate, validation) if validation.get("ok", false) else validation

func _publish_prepared_departure(candidate: Dictionary, validation: Dictionary) -> Dictionary:
	# Root-private silent tail AFTER all owners have been validated. Detach
	# caller-owned dictionaries before the first live write; no fallible callbacks.
	if validation.get("replayed", false):
		var replay: Dictionary = validation.result.duplicate(true); replay["replayed"] = true; return replay
	var patch: Dictionary = candidate.patch.duplicate(true)
	var result: Dictionary = patch.result.duplicate(true)
	var group_receipt := {"signature":String(candidate.signature),"result":result.duplicate(true)}
	_departures_by_craft_id[String(patch.craft_id)] = patch.binding
	if patch.has("job_patch"):
		_jobs[String(patch.job_id)]["status"] = String(patch.job_patch.status)
		_jobs[String(patch.job_id)]["craft_id"] = String(patch.job_patch.craft_id)
	for request_id: String in patch.receipts: _requests[request_id] = patch.receipts[request_id]
	_revision += int(patch.revision_delta)
	_prepared_departure_receipts[String(candidate.context.transaction_id)] = group_receipt
	return result
