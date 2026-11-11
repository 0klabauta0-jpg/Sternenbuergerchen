extends SceneTree
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const PRESENTER = preload("res://scripts/meta/singleplayer_services_presenter.gd")
const POLISA = preload("res://scripts/ui/polisa_station_screen.gd")
class Flow extends Node:
	var _homebase_aircraft_definitions: Array = [{"craft_id":"home"}, {"craft_id":"away"}]
	var _aircraft_location_by_craft := {"home":"homebase", "away":"mission"}
	var _pending_mission_craft_transfers: Array = []
	var _all_team_units: Array = []
	var pending := {}
	var view := {"view":"mission", "location_id":"polisa", "craft_id":""}
	var mission: Node
	func _find_homebase_aircraft_definition(id: String) -> Dictionary:
		for definition: Dictionary in _homebase_aircraft_definitions:
			if definition.craft_id == id: return definition
		return {}
	func _find_pending_mission_craft_transfer(id: String) -> Dictionary: return pending.get(id, {})
	func get_mission_for_craft(id: String) -> Node: return mission if String(_aircraft_location_by_craft.get(id, "")) == "mission" else null
	func get_location_view_snapshot() -> Dictionary: return view.duplicate()
class Controller extends Node:
	var parked := true
	func _is_parked_campaign_dropship(_id: String) -> bool: return parked
class Base extends Node:
	var built := true
	var units: Array = [{"unit_id":"local", "status":"outside", "craft_id":""}, {"unit_id":"remote", "status":"away", "craft_id":"away"}]
	func get_snapshot() -> Dictionary: return {"runtime_authority":"SimulationRoot", "layout":{"assets":[{"id":"freihafen_hall_01", "built":built}]}, "units":units}
class Sim extends Node:
	var _base_personnel_owner: Node
	var commits: Array = []
	func request_singleplayer_command(command: Dictionary, context: Dictionary) -> Dictionary:
		commits.append({"command":command.duplicate(true), "context":context.duplicate(true)})
		return {"ok":true, "completion_receipt":{"completion_id":"fixture"}}
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	failures += int(not ok)
	print("PASS: " if ok else "FAIL: ", label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var adapter = ADAPTER.new()
	root.add_child(adapter)
	var flow := Flow.new()
	root.add_child(flow)
	adapter._flow = flow
	adapter._campaign_mode = true
	adapter._campaign = ADAPTER.CAMPAIGN.new()
	adapter._campaign.configure()
	adapter._supply = ADAPTER.SUPPLY.new()
	adapter._supply.configure(["home", "away"])
	adapter._supply.configure_inventory(["local", "remote"], ["home", "away"], true)
	adapter._travel = ADAPTER.TRAVEL.new()
	adapter._travel.configure()
	adapter._travel.register_craft("home")
	adapter._travel.register_craft("away")
	adapter._pad_by_craft = {"home":"homebase_pad_01"}
	var sim := Sim.new()
	adapter.add_child(sim)
	adapter._simulation = sim
	var base := Base.new()
	adapter.add_child(base)
	adapter._base_personnel = base
	sim._base_personnel_owner = base
	check(adapter._home_workshop_available() and not adapter._all_at_home(), "Workshop remains local while other craft is abroad")
	check(adapter._service_context("home").location_id == "homebase", "Registered grounded home craft has its own service")
	adapter._travel.unregister_craft("home")
	check(adapter._service_context("home").is_empty(), "Unknown route never inherits default grounded service")
	adapter._travel.register_craft("home")
	flow.pending.home = {"phase":"to_mission"}
	check(adapter._service_context("home").is_empty(), "Pending transfer blocks exact home craft")
	flow.pending.clear()
	base.built = false
	check(not adapter._home_workshop_available(), "Unbuilt workshop rejects local fabrication")
	base.built = true
	sim._base_personnel_owner = null
	check(not adapter._home_workshop_available(), "Unregistered base child gives no facility authority")
	sim._base_personnel_owner = base
		# Trusted domain fixture places one chip in each location without gameplay UI.
	var contract = load("res://scripts/mission/singleplayer_supply_command_contract.gd")
	for spec: Array in [["craft:away", "satellite_chip"], ["unit:remote:backpack", "outpost_chip"]]:
		var result: Dictionary = adapter._supply.apply_command(contract.build_command("campaign_cargo", {"container_id":spec[0], "item_id":spec[1], "amount":1}, "fixture:"+spec[0]), {"campaign_authorized":true})
		check(bool(result.get("ok", false)), "Fixture stores real remote chip in " + String(spec[0]))
	adapter._campaign._jobs.satellite_recovery.status = "pending_upload"
	adapter._campaign._jobs.satellite_recovery.craft_id = "away"
	check(not adapter._request_campaign_action("campaign_upload", {"job_id":"satellite_recovery"}, "remote-upload").ok and sim.commits.is_empty(), "Upload command refuses chips still aboard remote craft")
	check(adapter._find_local_campaign_chip_container("satellite_chip").is_empty() and adapter._find_local_campaign_chip_container("outpost_chip").is_empty(), "Remote ship/person chips are not local uploads")
	check(adapter._find_campaign_chip_container("satellite_chip", "away") == "craft:away", "Global recovery dedupe finder remains unchanged")
	adapter._supply.apply_command(contract.build_command("campaign_cargo", {"container_id":"base:homebase", "item_id":"satellite_chip", "amount":1}, "fixture:base"), {"campaign_authorized":true})
	check(adapter._find_local_campaign_chip_container("satellite_chip") == "base:homebase", "Actual base chip accessible while source ship stays abroad")
	# Sim stub records exact forwarded owner commands, no alternate inventory writer.
	adapter._onboarding = load("res://scripts/core/campaign_onboarding_state.gd").new()
	adapter._onboarding.configure()
	adapter._request_campaign_action("campaign_fabricate", {"blueprint_id":"mining_tool"}, "local-fabricate")
	check(sim.commits.size() == 1 and bool(sim.commits[0].context.at_home), "Fabricate command forwards local facility proof despite fleet abroad")
	sim.commits.clear()
	adapter._supply.apply_command(contract.build_command("campaign_cargo", {"container_id":"unit:local:backpack", "item_id":"outpost_chip", "amount":1}, "fixture:local"), {"campaign_authorized":true})
	check(adapter._find_local_campaign_chip_container("outpost_chip") == "unit:local:backpack", "Real local suit data slot needs no backpack")
	var mission := Node.new()
	root.add_child(mission)
	flow.mission = mission
	var controller := Controller.new()
	controller.name = "TacticalController"
	mission.add_child(controller)
	adapter._campaign._departures_by_craft_id.away = {"destination_location_id":"polisa"}
	var contexts := {"away":adapter._service_context("away"), "home":adapter._service_context("home")}
	var snapshot := {"location_view":flow.view, "crafts":[{"craft_id":"away", "location_id":"polisa", "busy":false}], "service_contexts_by_craft_id":contexts}
	var polisa: Dictionary = adapter.get_polisa_snapshot(snapshot)
	check(polisa.craft_id == "" and not polisa.service_ready and polisa.selection_required and polisa.local_crafts.size() == 1, "Polisa never falls back to focused or first local craft")
	flow.view.craft_id = "away"
	snapshot.location_view = flow.view
	check(adapter.get_polisa_snapshot(snapshot).service_ready, "Explicit actual Polisa craft enables its own service")
	flow._aircraft_location_by_craft.home = "mission"
	adapter._campaign._departures_by_craft_id.home = {"destination_location_id":"polisa"}
	snapshot.crafts.append({"craft_id":"home", "location_id":"polisa", "busy":false})
	snapshot.service_contexts_by_craft_id.home = adapter._service_context("home")
	flow.view.craft_id = ""
	check(adapter.get_polisa_snapshot(snapshot).local_crafts.size() == 2 and adapter.get_polisa_snapshot(snapshot).craft_id == "" and not adapter.get_polisa_snapshot(snapshot).service_ready, "Two actual station craft require explicit choice")
	flow.view.craft_id = "away"
	snapshot.service_contexts_by_craft_id.erase("away")
	check(adapter.get_polisa_snapshot(snapshot).craft_id == "" and not adapter.get_polisa_snapshot(snapshot).service_ready, "Stale selected craft never reroutes to other station craft")
	snapshot.service_contexts_by_craft_id.away = adapter._service_context("away")
	flow._aircraft_location_by_craft.home = "homebase"
	flow.view.location_id = "homebase"
	check(not adapter.get_polisa_snapshot(snapshot).service_ready and adapter.get_polisa_snapshot(snapshot).craft_id == "", "Non-Polisa view has no Polisa access")
	flow.view.location_id = "polisa"
	controller.parked = false
	check(adapter._service_context("away").is_empty(), "Physical unparked actor denies service again at command time")
	controller.parked = true
	adapter._travel._owners.away._phase = "orbit"
	check(adapter._service_context("away").is_empty(), "Known orbit phase blocks stale parked actor service")
	adapter._travel._owners.away._phase = "grounded"
	flow.pending.away = {"phase":"to_homebase"}
	check(adapter._service_context("away").is_empty(), "Polisa pending departure denies its exact craft")
	flow.pending.clear()
	check(not adapter.request_operation("refuel", {"craft_id":"home", "amount":1, "service_location_id":"polisa"}).ok and sim.commits.is_empty(), "Stale Polisa intent cannot silently refuel home craft")
	adapter._campaign._jobs.outpost_recovery.status = "completed"
	adapter._campaign._jobs.outpost_recovery.craft_id = "away"
	check(not adapter._request_campaign_action("campaign_load_crate", {"craft_id":"home"}, "wrong-crate").ok and sim.commits.is_empty(), "Job crate cannot be redirected to unrelated home craft")
	check(not adapter._request_campaign_action("campaign_recruit", {"craft_id":"home"}, "wrong-recruit").ok and sim.commits.is_empty(), "Job recruit cannot use unrelated local craft")
	adapter._campaign_mode = false
	adapter._base_personnel = null
	flow._aircraft_location_by_craft.away = "homebase"
	check(adapter._home_workshop_available(), "Existing noncampaign ownerless all-home fabrication retained")
	flow._aircraft_location_by_craft.away = "mission"
	check(not adapter._home_workshop_available(), "Ownerless legacy fallback stays globally strict")
	adapter._campaign_mode = true
	check(not adapter._home_workshop_available(), "Campaign never inherits ownerless pseudo-permission")
	adapter._space_encounter = load("res://scripts/core/campaign_space_encounter.gd").new()
	adapter._space_encounter.start_encounter("away")
	adapter._space_encounter.apply_command({"contract_category":"campaign_space", "operation":"engage", "payload":{}}, {})
	for tick in range(7): adapter._space_encounter.apply_command({"contract_category":"campaign_space", "operation":"advance", "payload":{"delta_seconds":1.0}}, {"runtime_authorized":true})
	adapter._space_encounter.apply_command({"contract_category":"campaign_space", "operation":"rescue", "payload":{}}, {})
	var delivered: Dictionary = adapter._space_encounter.get_completed_result()
	check(String(delivered.get("result", "")) == "victory" and adapter._space_encounter.get_completed_result().is_empty(), "Real encounter delivery consumes completed result exactly once")
	var encounter_before := JSON.stringify(adapter._space_encounter.get_snapshot())
	check(adapter._has_verified_pilot_rescue("away") and not adapter._has_verified_pilot_rescue("home") and JSON.stringify(adapter._space_encounter.get_snapshot()) == encounter_before, "Automatic pilot rescue proof survives consumed result without another mutation")
	print("LOCAL_SERVICE_CONTEXT checks=", checks, " failures=", failures)
	adapter.free()
	flow.free()
	mission.free()
	quit(int(failures > 0))
