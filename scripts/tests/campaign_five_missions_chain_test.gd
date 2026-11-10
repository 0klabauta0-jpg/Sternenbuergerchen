extends SceneTree
## Domain transaction/restore test; runtime-gate evidence is a deliberate fixture.
const C = preload("res://scripts/mission/singleplayer_campaign_command_contract.gd")
const S = preload("res://scripts/mission/singleplayer_supply_command_contract.gd")
var checks := 0
var failures := 0
var sequence := 0
func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures += 1; printerr("FAIL: ",label)
func call_c(owner: RefCounted, operation: String, payload: Dictionary, context: Dictionary = {}) -> Dictionary:
	sequence += 1
	return owner.apply_command(C.build_command(operation,payload,"chain:%d" % sequence),context)
func _initialize() -> void:
	var owner = load("res://scripts/core/singleplayer_campaign_state.gd").new()
	var supply = load("res://scripts/core/singleplayer_supply_state.gd").new()
	var tutorial = load("res://scripts/core/campaign_onboarding_state.gd").new()
	check(owner.configure().ok,"five job definitions normalize")
	check(supply.configure(["dropship_1"]).ok,"supply configure")
	supply.configure_inventory(["campaign_leader"],["dropship_1"])
	supply.configure_start_inventory("campaign")
	tutorial.configure()
	var observe := {"contract_category":"campaign_onboarding","operation":"observe","payload":{}}
	tutorial.apply_command(observe,{"runtime_evidence":{"base_ready":true}})
	for id in ["satellite_recovery","outpost_recovery","benit_delivery","outpost_chip_recovery","buccaneer_rescue"]:
		var job: Dictionary = owner.get_campaign_snapshot().jobs[id]
		check(call_c(owner,"accept_job",{"job_id":id}).ok,"accept "+id)
		var dep := {"craft_id":"dropship_1","origin_location_id":"homebase","destination_location_id":job.location_id,"landing_pad_id":"homebase_pad_01","job_id":id}
		check(call_c(owner,"bind_departure",dep,{"departure_authorized":true}).ok,"bind "+id)
		check(call_c(owner,"activate_job",{"job_id":id,"craft_id":"dropship_1"},{"departure_authorized":true}).ok,"activate "+id)
		if id == "benit_delivery":
			check(call_c(owner,"deliver_crate",{},{"runtime_authorized":true}).ok,"deliver real loaded crate")
			var early := call_c(owner,"complete_job",{"job_id":id,"craft_id":"dropship_1"},{"runtime_evidence":{"scenario_id":job.scenario_id,"result":"victory","mission_scenario_runtime_gates":{"all_gates_complete":true,"completed_step_ids":["deliver_benit"]}}})
			check(not early.ok,"delivery alone cannot skip physical ship return")
			check(String(owner.get_campaign_snapshot().jobs[id].status) == "active","early delivery earns no completed mission")
		var done := call_c(owner,"complete_job",{"job_id":id,"craft_id":"dropship_1"},{"runtime_evidence":{"scenario_id":job.scenario_id,"result":"victory","mission_scenario_runtime_gates":{"all_gates_complete":true,"completed_step_ids":job.required_step_ids}}})
		check(done.ok,"verified gates "+id)
		if bool(job.home_upload):
			check(not done.has("completion_receipt"),"chip cannot pay in field")
			done = call_c(owner,"upload_job",{"job_id":id},{"at_home":true})
			check(done.ok,"home upload "+id)
		var receipt: Dictionary = done.get("completion_receipt",{})
		check(supply.apply_command(S.build_command("apply_reward",{"completion_id":receipt.completion_id},"reward:"+id),{"completion_receipt":receipt}).ok,"reward "+id)
		if id == "outpost_recovery":
			check(call_c(owner,"claim_recruit",{"kind":"outpost"},{"runtime_authorized":true}).ok,"third person")
			check(call_c(owner,"load_crate",{},{"runtime_authorized":true}).ok,"crate loaded")
		if id == "buccaneer_rescue":
			check(call_c(owner,"claim_recruit",{"kind":"pilot"},{"runtime_authorized":true}).ok,"fourth person")
			check(call_c(owner,"build_pad",{},{"runtime_authorized":true,"at_home":true}).ok,"second pad")
		var evidence := {"satellite_uploaded":true,"outpost_completed":true,"outpost_recruited":true,"crate_loaded":true,"delivery_completed":true,"outpost_chip_uploaded":true,"rescue_completed":true,"pilot_recruited":true,"second_pad_built":true}
		tutorial.apply_command(observe,{"runtime_evidence":evidence})
		var fresh = load("res://scripts/core/singleplayer_campaign_state.gd").new()
		var roundtrip: Dictionary = fresh.restore_state(JSON.parse_string(JSON.stringify(owner.export_state())))
		check(bool(roundtrip.get("ok",false)),"roundtrip "+id)
	tutorial.apply_command(observe,{"runtime_evidence":{"second_pad_built":true}})
	check(tutorial.get_snapshot().completed,"seven progress stages completed")
	check(Array(supply.get_supply_snapshot().blueprints).has("mining_tool"),"mining blueprint earned")
	check(Array(supply.get_supply_snapshot().blueprints).has("assault_rifle"),"rifle blueprint earned")
	var fabricate:=S.build_command("campaign_fabricate",{"blueprint_id":"mining_tool"},"make:mining")
	check(not supply.apply_command(fabricate,{"at_home":false}).ok,"crafting requires actual base presence")
	check(supply.apply_command(fabricate,{"at_home":true}).ok,"earned mining blueprint manufactures real tool")
	check(supply.apply_command(fabricate,{"at_home":true}).get("replayed",false),"replayed manufacture does not duplicate tool")
	check(int(supply.get_supply_snapshot().inventory["base:homebase"].items.get("mining_tool",0))==1,"one manufactured tool in actual base inventory")

	var roster: Array = load("res://scripts/meta/campaign_start_configuration.gd").new()._initial_roster()
	var recruit: Dictionary = Dictionary(roster[0]).duplicate(true)
	recruit.unit_id = "campaign_outpost_recruit"
	roster.append(recruit)
	recruit = Dictionary(roster[1]).duplicate(true)
	recruit.unit_id = "campaign_rescue_pilot"
	roster.append(recruit)
	supply.register_craft("campaign_buccaneer_01")
	var saved: Dictionary = owner.export_state()
	saved.departures_by_craft_id = {}
	saved.selected_location_id = "homebase"
	saved.selected_job_id = ""
	var craft := {"definition":{"craft_id":"dropship_1","craft_type":"dropship"},"pilot_id":"campaign_pilot"}
	var checkpoint := {"schema_version":1,"roster":roster,"craft":craft,"fleet":[{"definition":craft.definition,"pilot_id":"campaign_pilot","location":"homebase"},{"definition":{"craft_id":"campaign_buccaneer_01","craft_type":"fighter"},"pilot_id":"campaign_rescue_pilot","location":"homebase"}],"campaign":saved,"supply":supply.export_state(),"onboarding":tutorial.export_state()}
	var store = load("res://scripts/meta/campaign_checkpoint_store.gd")
	var validated: Dictionary = store.validate_payload(JSON.parse_string(JSON.stringify(checkpoint)))
	if not validated.ok: printerr("CHECKPOINT: ",validated)
	check(validated.ok,"four-person two-ship final checkpoint")
	checkpoint["location_resources"] = {"fortified_outpost":{"version":1,"location_id":"fortified_outpost","sites":{}}}
	check(store.validate_payload(checkpoint).ok,"known fortified location may retain an empty resource owner")
	var unknown_resource := checkpoint.duplicate(true)
	unknown_resource.location_resources = {"unknown_planet":{"version":1,"location_id":"unknown_planet","sites":{}}}
	check(not store.validate_payload(unknown_resource).ok,"unknown resource location remains invalid even when empty")
	var bad := checkpoint.duplicate(true)
	bad.fleet[1].pilot_id = "missing"
	check(not store.validate_payload(bad).ok,"invalid fleet pilot rejected")
	print("CAMPAIGN_FIVE_CHAIN: ",checks,"/",failures)
	quit(1 if failures else 0)
