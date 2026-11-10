extends SceneTree
## Real units, terrain LOS, supply owner and resource runtime; no fabricated yields.
const UNIT = preload("res://scripts/npc/test_unit.gd")
const REGISTRY = preload("res://scripts/registries/unit_registry.gd")
const TERRAIN = preload("res://scripts/terrain/terrain_registry.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
var passed := 0
var failed := 0
class Controller extends Node:
	var _deployed_unit_ids := {}
	func get_local_command_team_id() -> String: return "team_alpha"
	var _selected_fireteam_ids := PackedStringArray(["ft1"])
	func _get_deployed_unit_fireteam_id(_id: String) -> String: return "ft1"
class Adapter extends Node:
	var supply = SUPPLY.new()
	func get_location_resource_stock(location: String) -> RefCounted: return supply.get_location_resources(location)
	func preview_resource_collection(location: String, site: String, unit: String) -> Dictionary: return supply.preview_resource_collection(location,site,unit)
	func collect_location_resource(_owner: Node, location: String, site: String, unit: String) -> Dictionary:
		return supply.apply_command(load("res://scripts/mission/singleplayer_supply_command_contract.gd").build_command("collect_resource",{"location_id":location,"site_id":site,"unit_id":unit},"world-use:"+site),{"resource_authorized":true,"unit_id":unit,"location_id":location,"use_complete":true,"within_radius":true})
	func get_snapshot() -> Dictionary: return {"supply":supply.get_supply_snapshot()}
	func grant_resource_result(owner: Node, receipt: Dictionary) -> Dictionary:
		if owner.get_pending_receipt() != receipt: return {"ok":false}
		return collect_location_resource(owner,receipt.location_id,receipt.site_id,receipt.unit_id)

func _init() -> void: call_deferred("_run")
func _check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print("PASS: " if value else "FAIL: ", label)
func _run() -> void:
	var script = load("res://scripts/core/location_resource_runtime.gd")
	if script == null: _check(false,"resource runtime exists"); quit(1); return
	var mission := Node.new()
	root.add_child(mission)
	var sim := Node.new()
	sim.name="SimulationRoot"
	mission.add_child(sim)
	var controller := Controller.new()
	controller.name="TacticalController"
	mission.add_child(controller)
	var registry = REGISTRY.new()
	registry.name="UnitRegistry"
	mission.add_child(registry)
	var terrain = TERRAIN.new()
	terrain.name="TerrainRegistry"
	mission.add_child(terrain)
	var map = MAP.load_from_file("res://maps/satellite_crash_site.json")
	terrain.configure_iso_grid(map.get_grid_origin(),64,32,"hex_axial_v1")
	for tile in map.get_tiles(): terrain.register_tile(tile)
	var unit = UNIT.new()
	unit.unit_id="miner"
	unit.team_id="team_alpha"
	mission.add_child(unit)
	registry.register_unit("miner",unit)
	var adapter := Adapter.new()
	root.add_child(adapter)
	adapter.supply.configure([])
	adapter.supply.configure_inventory(["miner"],[])
	var owner = script.new()
	sim.add_child(owner)
	_check(bool(owner.configure(mission,adapter,"satellite_crash").get("ok",false)),"real resource owner configured")
	owner.set_process(false)
	var position: Vector2 = terrain.grid_to_world(Vector2i(-8,14))
	unit.position=position
	owner.advance(.2)
	_check(Array(owner.get_snapshot().sites).is_empty(),"embarked or undeployed unit cannot discover resources")
	controller._deployed_unit_ids["miner"]=true
	unit.position=terrain.grid_to_world(Vector2i(-10,14))
	var blocker = terrain.get_tile_at_grid(Vector2i(-9,14))
	var old_blocks: bool=blocker.blocks_los
	var old_height: int=blocker.object_height
	blocker.blocks_los=true
	blocker.object_height=3
	owner.advance(.2)
	_check(Array(owner.get_snapshot().sites).is_empty(),"terrain occlusion hides a nearby resource")
	blocker.blocks_los=old_blocks
	blocker.object_height=old_height
	unit.position=position
	owner.advance(.2)
	_check(not Array(owner.get_snapshot().sites).is_empty(),"physically deployed living unit discovers nearby source")
	_check(not owner.apply_operation("start_use",{"site_id":"iron_ridge_01","unit_id":"miner"}).ok,"missing tool blocks mining")
	adapter.supply.apply_command({"contract_category":"singleplayer_supply","operation":"campaign_cargo","request_id":"tool","payload":{"container_id":"unit:miner:backpack","item_id":"mining_tool","amount":1}},{"campaign_authorized":true})
	_check(owner.apply_operation("start_use",{"site_id":"iron_ridge_01","unit_id":"miner"}).ok,"tool in real backpack enables use")
	owner.advance(2.0)
	_check(int(adapter.supply.get_supply_snapshot().inventory["unit:miner:backpack"].items.get("a_benit",0))==0,"partial duration grants no ore")
	unit.position=terrain.grid_to_world(Vector2i(7,11))
	owner.advance(3.0)
	_check(owner.get_snapshot().active_use.is_empty(),"leaving source interrupts work")
	unit.position=position
	adapter.supply.apply_command({"contract_category":"singleplayer_supply","operation":"campaign_cargo","request_id":"fill","payload":{"container_id":"unit:miner:backpack","item_id":"rifle","amount":4}},{"campaign_authorized":true})
	owner.apply_operation("start_use",{"site_id":"iron_ridge_01","unit_id":"miner"})
	owner.advance(4.0)
	_check(int(owner.export_state().sites.iron_ridge_01.remaining)==8 and int(adapter.supply.get_supply_snapshot().inventory["unit:miner:backpack"].items.get("a_benit",0))==0,"insufficient backpack capacity consumes neither ore nor site")
	adapter.supply.apply_command({"contract_category":"singleplayer_supply","operation":"campaign_cargo","request_id":"unfill","payload":{"container_id":"unit:miner:backpack","item_id":"rifle","amount":-4}},{"campaign_authorized":true})
	unit.apply_damage(1000)
	_check(not owner.apply_operation("start_use",{"site_id":"iron_ridge_01","unit_id":"miner"}).ok,"incapacitated unit cannot harvest")
	unit.apply_remote_vital_update({"vital_status":{"state":"fit","health_points":100,"bleedout_ticks":0}})
	owner.apply_operation("start_use",{"site_id":"iron_ridge_01","unit_id":"miner"})
	owner.advance(4.0)
	_check(int(adapter.supply.get_supply_snapshot().inventory["unit:miner:backpack"].items.get("a_benit",0))==8,"full nearby use yields eight finite A-Benit")
	_check(not owner.apply_operation("start_use",{"site_id":"iron_ridge_01","unit_id":"miner"}).ok,"depleted source cannot be harvested twice")
	var exported: Dictionary=owner.export_state()
	var restored = script.new()
	sim.add_child(restored)
	_check(restored.configure(mission,adapter,"satellite_crash",exported).ok,"resource checkpoint roundtrip")
	restored.set_process(false)
	_check(restored.export_state()==exported,"discovery and depletion retained across reload")
	_check(owner.get("_stock") == adapter.supply.get_location_resources("satellite_crash"),"panel and world Use share the durable Supply stock")
	adapter.supply._inventory["unit:miner:backpack"].capacity=32
	unit.position=terrain.grid_to_world(Vector2i(31,25))
	owner.advance(.2)
	var targets: Dictionary=owner.project_bindings({"bindings":[]})
	_check(Array(targets.bindings).any(func(site: Dictionary): return site.interaction_id=="b_benit_01"),"discovered Benit has an actual world Use binding")
	var use: Dictionary={"interaction_id":"b_benit_01","fireteam_id":"ft1","hold_seconds":1.0}
	_check(not owner.accept_progress(use,true).get("accepted",true),"world Use cannot finish before real duration")
	use.hold_seconds=4.0
	_check(owner.accept_progress(use,true).get("accepted",false),"completed local world Use collects through Supply")
	_check(adapter.supply.get_supply_snapshot().inventory["unit:miner:backpack"].items.get("b_benit",0)==8 and owner.export_state().sites.b_benit_01.remaining==0,"world Use yield and depletion agree with panel snapshot")
	_check(not owner.apply_operation("start_use",{"site_id":"b_benit_01","unit_id":"miner"}).ok,"panel cannot collect world-Use-depleted stock a second time")
	var supply_copy = SUPPLY.new()
	_check(supply_copy.restore_state(adapter.supply.export_state()).ok and supply_copy.get_location_resources("satellite_crash").get_site_snapshot("b_benit_01").remaining==0,"durable Supply restore retains the common depleted stock")
	mission.free()
	adapter.free()
	print("LOCATION_RESOURCE_RUNTIME passed=%d failed=%d" % [passed,failed])
	quit(1 if failed else 0)
