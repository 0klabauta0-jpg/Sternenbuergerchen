extends SceneTree
## Playtest 14.11.2026, L01: a recovered chip that is physically at the home base must be
## uploadable even when the mission result never reported its last step (job still active).
const C = preload("res://scripts/mission/singleplayer_campaign_command_contract.gd")
var failures := 0
var checks := 0


func check(value: bool, label: String) -> void:
	checks += 1
	if value:
		print("PASS: ", label)
	else:
		failures += 1
		printerr("FAIL: ", label)


func cmd(owner: RefCounted, op: String, payload: Dictionary, context: Dictionary = {}) -> Dictionary:
	return owner.apply_command(C.build_command(op, payload, "l01:%d" % checks), context)


func _initialize() -> void:
	var state = load("res://scripts/core/singleplayer_campaign_state.gd").new()
	check(state.configure().ok, "valid authored campaign")
	check(cmd(state, "accept_job", {"job_id": "satellite_recovery"}).ok, "accept first job")
	var departure := {"craft_id": "ship", "origin_location_id": "homebase", "destination_location_id": "satellite_crash", "landing_pad_id": "homebase_pad_01", "job_id": "satellite_recovery"}
	check(cmd(state, "bind_departure", departure, {"departure_authorized": true}).ok, "bind trip")
	check(cmd(state, "activate_job", {"job_id": "satellite_recovery", "craft_id": "ship"}, {"departure_authorized": true}).ok, "activate trip")
	check(String(state.get_campaign_snapshot().jobs.satellite_recovery.status) == "active", "job is active, no mission result yet")
	check(not cmd(state, "upload_job", {"job_id": "satellite_recovery"}, {"at_home": true}).ok, "active job without a chip at home cannot upload")
	check(not cmd(state, "upload_job", {"job_id": "satellite_recovery"}, {"at_home": false, "chip_at_home": true}).ok, "chip evidence away from home is rejected")
	var result := cmd(state, "upload_job", {"job_id": "satellite_recovery"}, {"at_home": true, "chip_at_home": true})
	check(result.has("completion_receipt"), "chip physically at home completes the still-active job")
	check(String(state.get_campaign_snapshot().jobs.satellite_recovery.status) == "completed", "job completed after upload")
	check(not cmd(state, "upload_job", {"job_id": "satellite_recovery"}, {"at_home": true, "chip_at_home": true}).has("completion_receipt"), "second upload cannot duplicate the reward")
	var late := cmd(state, "complete_job", {"job_id": "satellite_recovery", "craft_id": "ship"}, {"runtime_evidence": {"scenario_id": "satellite_recovery", "result": "victory", "mission_scenario_runtime_gates": {"all_gates_complete": true, "completed_step_ids": ["secure_satellite", "return_to_ship"]}}})
	check(not late.ok, "late mission result cannot complete the job a second time")
	check(cmd(state, "accept_job", {"job_id": "outpost_recovery"}).ok, "next mission unlocks")
	print("PLAYTEST_L01_STATE checks=%d failed=%d" % [checks, failures])
	quit(1 if failures else 0)
