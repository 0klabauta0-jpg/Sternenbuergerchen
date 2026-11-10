extends RefCounted
## Persistent campaign owner. Runtime evidence is a separate trusted boundary,
## never read from command payloads supplied by UI.

const LOCATIONS: GDScript = preload("res://scripts/mission/singleplayer_location_contract.gd")
const JOBS: GDScript = preload("res://scripts/mission/singleplayer_job_contract.gd")
const COMMANDS: GDScript = preload("res://scripts/mission/singleplayer_campaign_command_contract.gd")

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
		"upload_job": result = _upload(payload, authority_context)
		"claim_recruit", "load_crate", "deliver_crate", "build_pad": result = _progress_action(String(command.operation),payload,authority_context)
		_: result = _reject("unknown_operation", "Aktion unbekannt")
	if bool(result.get("ok", false)):
		result["request_id"] = request_id
		result["operation"] = String(command.operation)
		_requests[request_id] = {"signature": signature, "result": result.duplicate(true)}
	return result

func _accept(payload: Dictionary) -> Dictionary:
	var job_id: String = String(payload.get("job_id", ""))
	if not _jobs.has(job_id):
		return _reject("unknown_job", "Auftrag unbekannt")
	var prior := String(_jobs[job_id].get("prerequisite_job_id",""))
	if _enforce_sequence and not prior.is_empty() and String(Dictionary(_jobs.get(prior,{})).get("status","")) != "completed":
		return _reject("previous_job_required", "Zuerst den vorherigen Kampagnenauftrag abschließen")
	if _enforce_sequence and job_id == "benit_delivery" and not (bool(_progress.recruited_outpost) and bool(_progress.crate_loaded)):
		return _reject("outpost_preparation_required","Zuerst die Person am Handelsposten aufnehmen und die Kiste bergen")
	var status: String = String(_jobs[job_id].status)
	if status in ["accepted", "active"]:
		return {"ok": true, "job_id": job_id, "already_accepted": true}
	if status != "offered":
		return _reject("job_closed", "Auftrag bereits abgeschlossen")
	_jobs[job_id].status = "accepted"
	_revision += 1
	return {"ok": true, "job_id": job_id, "message": "Auftrag angenommen"}

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
	if not Array(_locations[origin].landing_pad_ids).has(pad_id):
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
	if not _jobs.has(id) or String(_jobs[id].status) != "pending_upload":
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
	if _selected_job_id == job_id:
		_selected_job_id = ""
	_revision += 1
	return {"ok": true, "job_id": job_id, "message": "Auftrag beendet"}

func _reject(reason: String, message: String) -> Dictionary:
	return {"ok": false, "reason": reason, "message": message}

func _retry_failed(payload: Dictionary) -> Dictionary:
	var job_id := String(payload.get("job_id", ""))
	if not _jobs.has(job_id) or String(_jobs[job_id].status) != "failed" or _completion_receipts.has(job_id + ":completed"):
		return _reject("job_not_failed", "Nur fehlgeschlagene Auftraege erneut annehmen")
	_jobs[job_id].status = "accepted"
	_jobs[job_id].erase("craft_id")
	for craft_id in _departures_by_craft_id.keys():
		if String(_departures_by_craft_id[craft_id].get("job_id", "")) == job_id:
			_departures_by_craft_id.erase(craft_id)
	_revision += 1
	return {"ok":true,"job_id":job_id,"message":"Auftrag erneut angenommen"}

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
	_locations = fresh._locations.duplicate(true)
	_enforce_sequence = fresh._enforce_sequence
	_jobs = fresh._jobs.duplicate(true)
	for job_id in _jobs:
		_jobs[job_id].status = String(data.jobs[job_id].status)
		if data.jobs[job_id].has("craft_id"):
			_jobs[job_id]["craft_id"] = String(data.jobs[job_id].craft_id)
	_selected_location_id = String(data.selected_location_id)
	_selected_job_id = String(data.selected_job_id)
	_departures_by_craft_id = data.departures_by_craft_id.duplicate(true)
	_completion_receipts = data.completion_receipts.duplicate(true)
	_requests = data.requests.duplicate(true)
	_progress = Dictionary(data.get("progress",_progress)).duplicate(true)
	_revision = int(data.revision)
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
	if JSON.stringify(data.locations, "", true) != JSON.stringify(_locations, "", true) or data.jobs.size() != _jobs.size() or not _locations.has(data.get("selected_location_id", "")):
		return _reject("stale_campaign_definitions", "Ortsdaten geaendert")
	for job_id in _jobs:
		if typeof(data.jobs.get(job_id)) != TYPE_DICTIONARY:
			return _reject("invalid_job_state", "Auftrag fehlt")
		var saved: Dictionary = data.jobs[job_id].duplicate(true)
		saved.erase("locked")
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
	return {"ok":true}

func _saved_integer(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) >= 0 and float(value) == floor(float(value)) and float(value) <= 2147483647

func _saved_equal(a: Variant, b: Variant) -> bool:
	return JSON.stringify(JSON.parse_string(JSON.stringify(a)), "", true) == JSON.stringify(JSON.parse_string(JSON.stringify(b)), "", true)
