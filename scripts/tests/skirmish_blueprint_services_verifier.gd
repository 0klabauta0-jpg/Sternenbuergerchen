extends SceneTree
## Actual adapter/SimulationRoot transactions with explicit domain gate fixtures.
class FlowFixture:
	extends Node
	var _homebase_aircraft_definitions := [{"craft_id":"testship","craft_type":"dropship"}]
	var _aircraft_location_by_craft := {"testship":"homebase"}
	var _pending_mission_craft_transfers: Array = []
	var _selected_mission_id := "satellite_recovery"
	var _last_mission_result: Dictionary = {}
var checks := 0
var failures := 0
var sequence := 0
func check(value: bool,label: String) -> void:
	checks += 1
	if not value: failures += 1; printerr("FAIL: ",label)
func commit(sim: Node, operation: String, payload: Dictionary, context: Dictionary = {}) -> Dictionary:
	sequence += 1
	return sim.call("request_singleplayer_command",{"contract_category":"singleplayer_campaign","operation":operation,"payload":payload,"request_id":"sandbox:%d" % sequence},context)
func _initialize() -> void:
	var owner = load("res://scripts/core/singleplayer_campaign_state.gd").new()
	owner.configure({}, {}, false)
	var supply = load("res://scripts/core/singleplayer_supply_state.gd").new()
	supply.configure(["testship"])
	supply.configure_inventory(["person"],["testship"])
	var travel = load("res://scripts/core/singleplayer_fleet_travel_state.gd").new()
	travel.configure()
	travel.register_craft("testship")
	var sim: Node = load("res://scripts/core/simulation_root.gd").new()
	root.add_child(sim)
	sim.set_physics_process(false)
	sim.call("configure_singleplayer_owners",owner,supply,null,travel)
	var flow := FlowFixture.new()
	root.add_child(flow)
	var adapter: Node = load("res://scripts/meta/singleplayer_runtime_adapter.gd").new()
	root.add_child(adapter)
	adapter.set("_flow",flow)
	adapter.set("_simulation",sim)
	adapter.set("_campaign",owner)
	adapter.set("_supply",supply)
	adapter.set("_travel",travel)
	adapter.set("_campaign_mode",false)
	check(commit(sim,"accept_job",{"job_id":"outpost_chip_recovery"}).ok,"sandbox accepts later job without campaign prerequisites")
	check(commit(sim,"accept_job",{"job_id":"satellite_recovery"}).ok,"sandbox accepts satellite job")
	check(commit(sim,"bind_departure",{"craft_id":"testship","origin_location_id":"homebase","destination_location_id":"satellite_crash","landing_pad_id":"homebase_pad_01","job_id":"satellite_recovery"},{"departure_authorized":true}).ok,"sandbox route binds through simulation")
	check(commit(sim,"activate_job",{"job_id":"satellite_recovery","craft_id":"testship"},{"departure_authorized":true}).ok,"sandbox activates normal job")
	var completed := commit(sim,"complete_job",{"job_id":"satellite_recovery","craft_id":"testship"},{"runtime_evidence":{"scenario_id":"satellite_recovery","result":"victory","mission_scenario_runtime_gates":{"all_gates_complete":true,"completed_step_ids":["secure_satellite","return_to_ship"]}}})
	check(completed.has("completion_receipt") and String(owner.get_campaign_snapshot().jobs.satellite_recovery.status) == "completed","sequence-free sandbox has no inaccessible pending-upload state")
	var reward: Dictionary = sim.call("request_singleplayer_command",{"contract_category":"singleplayer_supply","operation":"apply_reward","payload":{"completion_id":completed.completion_receipt.completion_id},"request_id":"sandbox-reward"},{"completion_receipt":completed.completion_receipt})
	check(reward.ok,"sandbox earns blueprint through normal reward owner")
	var before: Dictionary = supply.get_supply_snapshot()
	var made: Dictionary = adapter.call("request_operation","campaign_fabricate",{"blueprint_id":"light_armor","craft_id":"testship"})
	check(made.get("ok",false),"actual Skirmish adapter permits earned blueprint fabrication at home")
	check(int(supply.get_supply_snapshot().credits) == int(before.credits)-20,"fabrication charges exact recipe cost")
	check(int(supply.get_supply_snapshot().item_quantities.get("armor_light",0)) == int(before.item_quantities.get("armor_light",0))+1,"fabrication yields a real base inventory item")
	check(not adapter.call("request_operation","campaign_build_pad",{}).get("ok",true),"sandbox cannot claim campaign plot pad")
	check(not adapter.call("request_operation","campaign_recruit",{}).get("ok",true),"sandbox cannot claim campaign plot recruit")
	var panel: Control = load("res://scripts/meta/singleplayer_services_presenter.gd").new()
	root.add_child(panel)
	panel.call("_build")
	panel.call("refresh",{"mode":"skirmish","campaign":owner.get_campaign_snapshot(),"supply":supply.get_supply_snapshot(),"crafts":[{"craft_id":"testship","location_id":"homebase","busy":false}],"service_contexts_by_craft_id":{"testship":{"location_id":"homebase","craft_busy":false}}})
	var actions: Dictionary = panel.get("_campaign_buttons")
	check(actions["campaign_fabricatelight_armor"].button.visible,"sandbox exposes unlocked fabrication action")
	panel.free()
	adapter.free()
	flow.free()
	sim.free()
	print("SKIRMISH_BLUEPRINT_SERVICES checks=",checks," failures=",failures)
	quit(1 if failures else 0)
