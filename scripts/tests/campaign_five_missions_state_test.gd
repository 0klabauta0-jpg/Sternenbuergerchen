extends SceneTree
var failures := 0
var checks := 0
const C = preload("res://scripts/mission/singleplayer_campaign_command_contract.gd")
func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ",label)
func cmd(owner: RefCounted, op: String, payload: Dictionary, context: Dictionary = {}) -> Dictionary:
	return owner.apply_command(C.build_command(op,payload,"test:%d" % checks),context)
func _initialize() -> void:
	var state = load("res://scripts/core/singleplayer_campaign_state.gd").new()
	check(state.configure().ok,"valid authored campaign")
	check(not cmd(state,"accept_job",{"job_id":"outpost_recovery"}).ok,"second mission locked")
	check(cmd(state,"accept_job",{"job_id":"satellite_recovery"}).ok,"accept first")
	var departure := {"craft_id":"ship","origin_location_id":"homebase","destination_location_id":"satellite_crash","landing_pad_id":"homebase_pad_01","job_id":"satellite_recovery"}
	check(cmd(state,"bind_departure",departure,{"departure_authorized":true}).ok,"bind trip")
	check(cmd(state,"activate_job",{"job_id":"satellite_recovery","craft_id":"ship"},{"departure_authorized":true}).ok,"activate trip")
	check(not cmd(state,"complete_job",{"job_id":"satellite_recovery"},{"runtime_evidence":{}}).ok,"fake win rejected")
	var result := cmd(state,"complete_job",{"job_id":"satellite_recovery","craft_id":"ship"},{"runtime_evidence":{"scenario_id":"satellite_recovery","result":"victory","mission_scenario_runtime_gates":{"all_gates_complete":true,"completed_step_ids":["secure_satellite","return_to_ship"]}}})
	check(result.ok,"verified collection accepted")
	check(not result.has("completion_receipt"),"no reward before home upload")
	check(state.get_campaign_snapshot().jobs.satellite_recovery.status == "pending_upload","chip awaiting home upload")
	check(not cmd(state,"upload_job",{"job_id":"satellite_recovery"},{"at_home":false}).ok,"remote upload rejected")
	check(cmd(state,"upload_job",{"job_id":"satellite_recovery"},{"at_home":true}).has("completion_receipt"),"home upload earns receipt")
	check(not cmd(state,"upload_job",{"job_id":"satellite_recovery"},{"at_home":true}).has("completion_receipt"),"new upload cannot duplicate reward")
	check(cmd(state,"accept_job",{"job_id":"outpost_recovery"}).ok,"second mission unlocks")
	var saved: Dictionary = state.export_state()
	var restored = load("res://scripts/core/singleplayer_campaign_state.gd").new()
	check(restored.restore_state(JSON.parse_string(JSON.stringify(saved))).ok,"campaign JSON roundtrip")
	var bad: Dictionary = saved.duplicate(true)
	bad.jobs.satellite_recovery.reward.credits = 99999
	check(not restored.restore_state(bad).ok,"tampered rewards rejected")
	print("CAMPAIGN_FIVE_STATE: ",checks,"/",failures)
	quit(1 if failures else 0)
