extends SceneTree

var passed: int = 0
var failed: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var path := "res://scripts/core/singleplayer_campaign_state.gd"
	_check(FileAccess.file_exists(path), "Persistent campaign owner exists")
	if not FileAccess.file_exists(path):
		_finish()
		return
	var state = load(path).new()
	_check(bool(state.configure().get("ok", false)), "Definitions load and validate")
	var initial: Dictionary = state.get_campaign_snapshot()
	_check(initial.selected_location_id == "homebase", "Initial destination is homebase")
	_check(_apply(state, "accept_job", {"job_id": "satellite_recovery"}, "accept").ok, "Job accepts")
	var snapshot: Dictionary = state.get_campaign_snapshot()
	_check(snapshot.selected_location_id == "homebase" and snapshot.departures_by_craft_id.is_empty(), "Acceptance never launches or selects destination")
	_check(not _apply(state, "select_destination", {"location_id": "missing"}, "invalid").ok, "Unknown destination rejected")
	_check(not _apply(state, "select_destination", {"location_id": "trade_outpost", "job_id": "satellite_recovery"}, "mismatch").ok, "Wrong job/location rejected")
	_check(_apply(state, "select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"}, "select").ok, "Accepted job and location selected")
	_check(_apply(state, "select_destination", {"location_id": "trade_outpost"}, "trade").ok, "Trading destination needs no combat job")
	_check(state.get_campaign_snapshot().selected_job_id == "", "Switching to trade clears selected combat job")
	_check(_apply(state, "select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"}, "select2").ok, "Job selection restores")
	_check(not _apply(state, "complete_job", {"job_id": "satellite_recovery"}, "premature").ok, "Inactive job cannot complete")
	_check(_apply(state, "bind_departure", {"craft_id": "craft1", "origin_location_id": "homebase", "destination_location_id": "satellite_crash", "landing_pad_id": "homebase_pad_01", "job_id": "satellite_recovery"}, "depart", {"departure_authorized": true}).ok, "Authorized departure binds exact craft and job")
	_check(_apply(state, "activate_job", {"job_id": "satellite_recovery", "craft_id": "craft1"}, "activate", {"departure_authorized": true}).ok, "Confirmed departure activates job")
	_check(not _apply(state, "complete_job", {"job_id": "satellite_recovery", "evidence": {"result": "victory"}}, "forged").ok, "UI payload cannot forge runtime proof")
	_check(not _apply(state, "complete_job", {"job_id": "satellite_recovery"}, "wrong_scene", {"runtime_evidence": {"scenario_id": "other", "result": "victory", "mission_scenario_runtime_gates": {"all_gates_complete": true}}}).ok, "Unrelated scenario cannot complete selected job")
	var proof := {"runtime_evidence": {"scenario_id": "satellite_recovery", "result": "victory", "mission_scenario_runtime_gates": {"all_gates_complete": true, "completed_step_ids": ["secure_satellite", "return_to_ship"]}}}
	var complete: Dictionary = _apply(state, "complete_job", {"job_id": "satellite_recovery", "craft_id": "craft1"}, "complete", proof)
	_check(complete.ok and not Dictionary(complete.get("completion_receipt", {})).is_empty(), "Runtime success creates completion receipt")
	_check(_apply(state, "complete_job", {"job_id": "satellite_recovery", "craft_id": "craft1"}, "complete", proof).get("replayed", false), "Repeat request replays receipt")
	_check(not _apply(state, "complete_job", {"job_id": "satellite_recovery", "craft_id": "craft2"}, "complete", proof).ok, "Reused request with altered payload rejected")
	_check(state.get_campaign_snapshot().completion_receipts.size() == 1, "Exactly one completion exists")
	snapshot = state.get_campaign_snapshot()
	snapshot.jobs.satellite_recovery.status = "offered"
	_check(state.get_campaign_snapshot().jobs.satellite_recovery.status == "completed", "Snapshots cannot mutate owner")
	var locations: Dictionary = state.get_campaign_snapshot().locations
	var jobs: Dictionary = state.get_campaign_snapshot().jobs
	jobs.satellite_second = jobs.satellite_recovery.duplicate(true)
	jobs.satellite_second.id = "satellite_second"
	jobs.satellite_second.status = "offered"
	var second = load(path).new()
	_check(second.configure(locations, jobs).ok, "Multiple jobs may share a location")
	_check(_apply(second, "accept_job", {"job_id": "satellite_second"}, "accept2").ok, "Second co-located job accepts independently")
	_check(_apply(second, "fail_job", {"job_id": "satellite_second"}, "abort", {"mission_aborted": true}).ok, "Accepted job can be explicitly abandoned")
	_check(second.get_campaign_snapshot().completion_receipts.is_empty(), "Abandonment yields no reward receipt")
	var command_contract = load("res://scripts/mission/singleplayer_campaign_command_contract.gd")
	_check(command_contract.build_accept_job_command("satellite_recovery", "built").get("operation") == "accept_job", "Acceptance builder preserves explicit command operation")
	_check(command_contract.build_command("invented", {}, "bad").is_empty(), "Unknown command cannot be built")
	_check(command_contract.build_accept_job_command("satellite_recovery", "").is_empty(), "Missing request ID cannot be built")
	_check(not state.apply_command({"contract_category": "singleplayer_campaign", "operation": "select_destination", "payload": {"location_id": "trade_outpost"}, "request_id": ""}).ok, "Owner enforces request ID even without builder")
	var location_contract = load("res://scripts/mission/singleplayer_location_contract.gd")
	var malformed: Dictionary = locations.homebase.duplicate(true)
	malformed.region_position = [NAN, 0.5]
	_check(location_contract.normalize_location(malformed).is_empty(), "Malformed non-finite region position rejected")
	malformed = locations.homebase.duplicate(true)
	malformed.landing_pad_ids = ["duplicate", "duplicate"]
	_check(location_contract.normalize_location(malformed).is_empty(), "Duplicate landing pad IDs rejected")
	var incomplete: Dictionary = proof.duplicate(true)
	incomplete.runtime_evidence.mission_scenario_runtime_gates.completed_step_ids = ["secure_satellite"]
	var third = load(path).new()
	third.configure()
	_apply(third, "accept_job", {"job_id": "satellite_recovery"}, "accept")
	_apply(third, "bind_departure", {"craft_id": "craft1", "origin_location_id": "homebase", "destination_location_id": "satellite_crash", "landing_pad_id": "homebase_pad_01", "job_id": "satellite_recovery"}, "depart", {"departure_authorized": true})
	_apply(third, "activate_job", {"job_id": "satellite_recovery", "craft_id": "craft1"}, "activate", {"departure_authorized": true})
	_check(not _apply(third, "complete_job", {"job_id": "satellite_recovery"}, "incomplete", incomplete).ok, "Recovery without return-to-ship proof cannot complete")
	_check(third.get_campaign_snapshot().completion_receipts.is_empty(), "Incomplete objectives mint no receipt")
	_finish()

func _apply(state, operation: String, payload: Dictionary, request_id: String, context: Dictionary = {}) -> Dictionary:
	return state.apply_command({"contract_category": "singleplayer_campaign", "operation": operation, "payload": payload, "request_id": request_id}, context)

func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS: " + label)
	else:
		failed += 1
		printerr("FAIL: " + label)

func _finish() -> void:
	print("CAMPAIGN_RESULTS passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)
