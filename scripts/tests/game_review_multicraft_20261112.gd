extends SceneTree
## Real flow/controls and owner restore. Requires an isolated APPDATA from runner.
const START = preload("res://scripts/meta/game_start_contract.gd")
const STORE = preload("res://scripts/meta/campaign_checkpoint_store.gd")
const C = preload("res://scripts/mission/singleplayer_campaign_command_contract.gd")
const S = preload("res://scripts/mission/singleplayer_supply_command_contract.gd")
var failed := 0
var checks := 0
var sequence := 0
func _initialize() -> void:
	call_deferred("_run")
func _check(value: bool, label: String) -> void:
	checks += 1
	if not value: failed += 1
	print("PASS: " if value else "FAIL: ", label)
func _command(owner: RefCounted, operation: String, payload: Dictionary, context: Dictionary = {}) -> Dictionary:
	sequence += 1
	return owner.apply_command(C.build_command(operation,payload,"multicraft:%d" % sequence),context)
func _fixture(flow: Node) -> Dictionary:
	var campaign = load("res://scripts/core/singleplayer_campaign_state.gd").new()
	var supply = load("res://scripts/core/singleplayer_supply_state.gd").new()
	var onboarding = load("res://scripts/core/campaign_onboarding_state.gd").new()
	_check(campaign.configure().ok,"configure actual campaign owner")
	_check(supply.configure(["dropship_1"]).ok,"configure actual supply owner")
	supply.configure_inventory(["campaign_leader","campaign_pilot","campaign_outpost_recruit","campaign_rescue_pilot"],["dropship_1","campaign_buccaneer_01"])
	supply.configure_start_inventory("campaign")
	onboarding.configure()
	for id in ["satellite_recovery","outpost_recovery","benit_delivery","outpost_chip_recovery","buccaneer_rescue"]:
		var job: Dictionary = campaign.get_campaign_snapshot().jobs[id]
		_check(_command(campaign,"accept_job",{"job_id":id}).ok,"fixture accepts "+id)
		_check(_command(campaign,"bind_departure",{"craft_id":"dropship_1","origin_location_id":"homebase","destination_location_id":job.location_id,"landing_pad_id":"homebase_pad_01","job_id":id},{"departure_authorized":true}).ok,"fixture departure "+id)
		_check(_command(campaign,"activate_job",{"job_id":id,"craft_id":"dropship_1"},{"departure_authorized":true}).ok,"fixture activates "+id)
		if id == "benit_delivery": _check(_command(campaign,"deliver_crate",{},{"runtime_authorized":true}).ok,"fixture delivers crate")
		var done := _command(campaign,"complete_job",{"job_id":id,"craft_id":"dropship_1"},{"runtime_evidence":{"scenario_id":job.scenario_id,"result":"victory","mission_scenario_runtime_gates":{"all_gates_complete":true,"completed_step_ids":job.required_step_ids}}})
		_check(done.ok,"fixture completes "+id)
		if bool(job.home_upload): done = _command(campaign,"upload_job",{"job_id":id},{"at_home":true})
		var receipt: Dictionary = done.get("completion_receipt",{})
		_check(supply.apply_command(S.build_command("apply_reward",{"completion_id":receipt.completion_id},"reward:"+id),{"completion_receipt":receipt}).ok,"fixture rewards "+id)
		if id == "outpost_recovery":
			_check(_command(campaign,"claim_recruit",{"kind":"outpost"},{"runtime_authorized":true}).ok,"fixture third person")
			_check(_command(campaign,"load_crate",{},{"runtime_authorized":true}).ok,"fixture loads crate")
		if id == "buccaneer_rescue":
			_check(_command(campaign,"claim_recruit",{"kind":"pilot"},{"runtime_authorized":true}).ok,"fixture fourth person")
			_check(_command(campaign,"build_pad",{},{"runtime_authorized":true,"at_home":true}).ok,"fixture second pad")
	onboarding.apply_command({"contract_category":"campaign_onboarding","operation":"observe","payload":{}},{"runtime_evidence":{"base_ready":true,"satellite_uploaded":true,"outpost_completed":true,"outpost_recruited":true,"crate_loaded":true,"delivery_completed":true,"outpost_chip_uploaded":true,"rescue_completed":true,"pilot_recruited":true,"second_pad_built":true}})
	var roster: Array = flow.get("_all_team_units").duplicate(true)
	for index in 2:
		var person: Dictionary = roster[index].duplicate(true)
		person.unit_id = "campaign_outpost_recruit" if index == 0 else "campaign_rescue_pilot"
		person.fireteam_id = "ft2" if index == 0 else ""
		roster.append(person)
	var first: Dictionary = flow.call("_build_homebase_aircraft_definition","dropship",1)
	var second: Dictionary = flow.call("_build_homebase_aircraft_definition","fighter",1)
	second.merge({"craft_id":"campaign_buccaneer_01","display_name":"Buccaneer","model_id":"buccaneer"},true)
	supply.register_craft(second.craft_id)
	var state: Dictionary = campaign.export_state()
	state.departures_by_craft_id = {}; state.selected_location_id = "homebase"; state.selected_job_id = ""
	var craft := {"definition":first,"pilot_id":"campaign_pilot","staged_unit_ids":["campaign_leader","campaign_outpost_recruit"],"staged_fireteam_ids":["ft1","ft2"],"fireteam_definitions":[{"id":"ft1","lead_unit_id":"campaign_leader","member_unit_ids":["campaign_leader"]},{"id":"ft2","lead_unit_id":"campaign_outpost_recruit","member_unit_ids":["campaign_outpost_recruit"]}]}
	return {"schema_version":1,"roster":roster,"craft":craft,"fleet":[{"definition":first,"pilot_id":"campaign_pilot","location":"homebase"},{"definition":second,"pilot_id":"campaign_rescue_pilot","location":"homebase"}],"campaign":state,"supply":supply.export_state(),"onboarding":onboarding.export_state()}
func _open(action: String) -> Node:
	START.request_start(self,"campaign",action)
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	return flow
func _save_presence(fixture: Dictionary, statuses: Dictionary) -> void:
	var payload := fixture.duplicate(true)
	payload.base_personnel = {"version":1,"units":{}}
	for person: Dictionary in payload.roster:
		var craft := String(statuses.get(person.unit_id,""))
		payload.base_personnel.units[person.unit_id] = {"position":[0,0],"status":"outside" if craft.is_empty() else "aboard","craft_id":craft,"bed_id":""}
	var saved := STORE.save_checkpoint(payload)
	_check(saved.get("ok",false),"valid isolated checkpoint with requested crew presence")
	if not saved.get("ok",false): print(saved)
func _run() -> void:
	if not OS.get_environment("APPDATA").contains("game_review_20261112"):
		printerr("Isolated APPDATA required; no player save touched")
		quit(1); return
	var flow := _open("new")
	await process_frame
	flow.set_process(false)
	var fixture := _fixture(flow)
	_check(STORE.validate_payload(fixture).ok,"four-person two-ship checkpoint validates")
	# A second transport is an explicit supported checkpoint fixture. The earned
	# Buccaneer remains a fighter and its existing non-transport gate is tested below.
	fixture.fleet[1].definition.craft_type = "dropship"
	flow.queue_free(); await process_frame
	var aboard := {"campaign_leader":"dropship_1","campaign_pilot":"dropship_1","campaign_outpost_recruit":"campaign_buccaneer_01","campaign_rescue_pilot":"campaign_buccaneer_01"}
	_save_presence(fixture,aboard)
	flow = _open("continue"); await process_frame
	flow.set_process(false)
	var screen: Node = flow.get_node("HomebaseScreen")
	var adapter: Node = flow.get("_singleplayer_runtime")
	var owner: Node = adapter.call("get_base_personnel_runtime")
	owner.call("get_simulation_root").set_physics_process(false)
	_check(screen.call("_has_homebase_direct_launch_payload_for_craft","dropship_1"),"first ship completed payload survives Continue")
	_check(screen.call("_has_homebase_direct_launch_payload_for_craft","campaign_buccaneer_01"),"second ship completed payload survives Continue")
	_check(adapter.call("validate_space_launch","dropship_1",false).ok,"first ship launch readiness restored")
	_check(adapter.call("validate_space_launch","campaign_buccaneer_01",false).ok,"second ship launch readiness restored")
	_check(adapter.call("launch_to_moon_orbit","campaign_buccaneer_01").ok,"restored second transport actually launches through authoritative travel owner")
	_check(String(adapter.call("get_space_travel_snapshot","campaign_buccaneer_01").phase) == "orbit","real second-ship route reaches moon orbit")
	_check(adapter.call("request_operation","space_land_homebase",{"craft_id":"campaign_buccaneer_01"}).ok,"second transport actually lands home before world exit checks")
	screen.call("request_operation","navigate",{"mode":"base"}); await process_frame
	var base: Node = screen.get("_operations_presenter").get("_base")
	_check(base.call("_select_person","campaign_rescue_pilot"),"select actual second-ship pilot in world panel")
	var result: Dictionary = base.call("_personnel_action","base_unboard",{"craft_id":"dropship_1"})
	_check(not result.ok and String(result.get("reason","")) == "craft_mismatch","explicit mismatching craft remains honored")
	var buttons: Dictionary = base.get("_person_buttons")
	(buttons.base_unboard as Button).pressed.emit()
	_check(not owner.call("is_pilot_aboard","campaign_buccaneer_01"),"world Aussteigen button exits actual second ship")
	_check(owner.call("is_pilot_aboard","dropship_1"),"second-ship action leaves first pilot unchanged")
	base.call("_select_person","campaign_pilot")
	result = base.call("_personnel_action","base_unboard",{"craft_id":"dropship_1"})
	_check(result.ok and not owner.call("is_pilot_aboard","dropship_1"),"explicit matching craft still exits first ship")
	flow.queue_free(); await process_frame
	# A split team is not a boarded payload on either craft; unrelated complete team survives.
	aboard.campaign_leader = ""
	aboard.campaign_pilot = "dropship_1"
	_save_presence(fixture,aboard)
	flow = _open("continue"); await process_frame
	flow.set_process(false)
	screen = flow.get_node("HomebaseScreen"); adapter = flow.get("_singleplayer_runtime")
	_check(String(screen.call("_operations_payload_craft_for_team","ft1")).is_empty(),"partial first team is never falsely restored as boarded")
	_check(String(screen.call("_operations_payload_craft_for_team","ft2")) == "campaign_buccaneer_01","unrelated complete second-ship team survives partial-team restore")
	_check(not adapter.call("validate_space_launch","dropship_1",false).ok,"partial first team cannot launch")
	flow.queue_free(); await process_frame
	aboard.campaign_leader = "dropship_1"
	aboard.campaign_outpost_recruit = ""
	_save_presence(fixture,aboard)
	flow = _open("continue"); await process_frame
	flow.set_process(false)
	screen = flow.get_node("HomebaseScreen")
	_check(String(screen.call("_operations_payload_craft_for_team","ft2")).is_empty(),"outside second-team member is not invented aboard")
	flow.queue_free(); await process_frame
	# Split a multi-person team between actual ships: no per-ship subset may seed it.
	fixture.craft.fireteam_definitions = [{"id":"ft1","lead_unit_id":"campaign_leader","member_unit_ids":["campaign_leader","campaign_outpost_recruit"]}]
	fixture.craft.staged_fireteam_ids = ["ft1","ft1"]
	aboard.campaign_outpost_recruit = "campaign_buccaneer_01"
	_save_presence(fixture,aboard)
	flow = _open("continue"); await process_frame
	flow.set_process(false)
	screen = flow.get_node("HomebaseScreen")
	_check(String(screen.call("_operations_payload_craft_for_team","ft1")).is_empty(),"team split between two actual ships has no invented complete payload")
	flow.queue_free(); await process_frame
	fixture.fleet[1].definition.craft_type = "fighter"
	_save_presence(fixture,aboard)
	flow = _open("continue"); await process_frame
	flow.set_process(false)
	screen = flow.get_node("HomebaseScreen"); adapter = flow.get("_singleplayer_runtime")
	owner = adapter.call("get_base_personnel_runtime")
	_check(not adapter.call("validate_space_launch","campaign_buccaneer_01",false).ok,"natural Buccaneer fighter retains existing non-transport launch gate")
	screen.call("request_operation","navigate",{"mode":"base"}); await process_frame
	base = screen.get("_operations_presenter").get("_base")
	base.call("_select_person","campaign_rescue_pilot")
	result = base.call("_personnel_action","base_unboard")
	_check(result.ok and not owner.call("is_pilot_aboard","campaign_buccaneer_01"),"actual Buccaneer pilot exits via implicit world action")
	flow.queue_free(); await process_frame
	print("GAME_REVIEW_MULTICRAFT checks=%d failed=%d" % [checks,failed])
	quit(1 if failed else 0)
