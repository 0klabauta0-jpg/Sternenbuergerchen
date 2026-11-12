extends SceneTree
## Small actual-owner fixture; no journey/map/renderer proof is claimed here.
const HELPER = preload("res://scripts/mission/root_receipt_checkpoint.gd")
const SIM = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")
class Adapter extends Node:
 func preview_departure(_craft: String) -> Dictionary: return {"ok":false}
 func _built_home_pad_ids() -> Array: return []
 func validate_space_launch(_craft: String, _flag: bool) -> Dictionary: return {"ok":true}
 func preview_space_warp_entry(_craft: String) -> Dictionary: return {"ok":true,"owned_crafts":["a"],"craft_pilots":{"a":"pilot"}}
var passed := 0
var failed := 0
func check(value: bool,label: String) -> bool:
 if value: passed+=1; print("PASS: ",label)
 else: failed+=1; printerr("FAIL: ",label)
 return value
func owners(sim: Node,adapter: Node) -> Dictionary:
 var b := {"fleet":FLEET.new(),"supply":SUPPLY.new(),"campaign":CAMPAIGN.new(),"equipment":EQUIPMENT.new(),"adapter":adapter}
 b.fleet.configure(); b.fleet.register_craft("a")
 b.supply.configure(); b.campaign.configure()
 b.equipment.configure([{"craft_id":"a","model_id":""}])
 b.fleet.configure_space_area_transition_authority(sim)
 b.supply.bind_route_fuel_preparation_authority(sim)
 b.campaign.configure_departure_preparation_authority(sim)
 return b
func bind(sim: Node,b: Dictionary) -> void:
 sim.configure_singleplayer_owners(b.campaign,b.supply,null,b.fleet)
 sim.configure_ship_equipment(b.equipment)
 sim.configure_departure_adapter(b.adapter)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var sim = SIM.new(); root.add_child(sim); sim.set_physics_process(false)
 var adapter = Adapter.new(); root.add_child(adapter)
 var old := owners(sim,adapter); bind(sim,old)
 var launch: Dictionary = sim.commit_singleplayer_space_launch(adapter,"a","fixture-launch")
 if not check(launch.get("ok",false),"actual Root commits launch through real Fleet/Flight owners"): sim.free(); adapter.free(); quit(1); return
 sim.publish_singleplayer_space_launch_event(adapter,"fixture-launch")
 var saved: Dictionary = HELPER.capture(sim,old)
 if not check(saved.get("schema")=="root_receipt_checkpoint.v1","actual finalized old Root launch captures"): sim.free(); adapter.free(); quit(1); return
 var fresh := owners(sim,adapter)
 var restored: Dictionary = old.fleet.prepare_checkpoint_restore(old.fleet.export_checkpoint_state(),["a"])
 if not check(restored.get("ok",false),"real Fleet restore creates fresh detached owners"): sim.free(); adapter.free(); quit(1); return
 fresh.fleet=restored.candidate; fresh.fleet.configure_space_area_transition_authority(sim)
 var wire: Dictionary=JSON.parse_string(JSON.stringify(saved,"",true,true))
 check(not HELPER.prepare(sim,wire,fresh).ok,"ordinary prepare still refuses existing committed receipts")
 var prepared: Dictionary=HELPER.prepare_prebinding(sim,wire,fresh)
 if not check(prepared.get("ok",false),"explicit world restore prepares against occupied old Root"): sim.free(); adapter.free(); quit(1); return
 check(sim._singleplayer_space_travel_owner==old.fleet and sim._singleplayer_supply_owner==old.supply and sim._launch_receipts.size()==1,"prepare preserves old live Root owners and receipts")
 check(HELPER.validate_prebinding(sim,prepared.candidate,fresh).ok,"prebinding validates detached new owners with old Root unchanged")
 check(not HELPER.validate(sim,prepared.candidate,fresh).ok,"postbinding API still refuses old Root bindings")
 var old_credits: int=old.supply._credits; old.supply._credits+=1
 check(not HELPER.validate_prebinding(sim,prepared.candidate,fresh).ok,"old Root owner content change rejects prebinding")
 old.supply._credits=old_credits
 sim.configure_ship_equipment(fresh.equipment)
 check(not HELPER.validate_prebinding(sim,prepared.candidate,fresh).ok,"old Root owner pointer change rejects prebinding")
 sim.configure_ship_equipment(old.equipment)
 sim._launch_receipts["fixture-launch"].event_published=false
 check(not HELPER.validate_prebinding(sim,prepared.candidate,fresh).ok,"old Root receipt change rejects prebinding")
 check(not HELPER.prepare_prebinding(sim,wire,fresh).ok,"explicit prepare refuses unfinished old Root receipt")
 sim._launch_receipts["fixture-launch"].event_published=true
 var new_credits: int=fresh.supply._credits; fresh.supply._credits+=1
 check(not HELPER.validate_prebinding(sim,prepared.candidate,fresh).ok,"detached new owner mutation rejects prebinding")
 fresh.supply._credits=new_credits
 var foreign=SIM.new(); root.add_child(foreign); foreign.set_physics_process(false)
 check(not HELPER.validate_prebinding(foreign,prepared.candidate,fresh).ok,"foreign target Root rejects candidate")
 foreign.free()
 check(HELPER.validate_prebinding(sim,prepared.candidate,fresh).ok,"restored exact old/new baseline validates immediately before tail")
 var before: Dictionary=HELPER._owner_stamp(fresh)
 var emitted: Array=[]
 sim.singleplayer_command_committed.connect(func(c: Dictionary,r: Dictionary): emitted.append([c,r]))
 # Global transaction tail: all fallible checks precede these operations.
 bind(sim,fresh)
 HELPER.publish(sim,prepared.candidate)
 check(not HELPER.validate_prebinding(sim,prepared.candidate,fresh).ok,"published prebinding candidate is consumed")
 var replay: Dictionary=sim.commit_singleplayer_space_launch(adapter,"a","fixture-launch")
 check(replay.get("ok",false) and replay.get("replayed",false),"same actual launch replays through fresh Root bindings")
 sim.publish_singleplayer_space_launch_event(adapter,"fixture-launch")
 check(HELPER._owner_stamp(fresh)==before and emitted.is_empty(),"publication and replay repeat no owner writes or events")
 check(HELPER.capture(sim,fresh)==saved,"new receipt maps retain exact original semantic checkpoint")
 for field in ["_air_ground_impact_receipts", "_air_support_move_receipts", "_campaign_space_return_receipts", "_campaign_space_entry_searches", "_campaign_space_entry_origins", "_piloted_air_ground_receipts", "_air_ground_fire_receipts", "_air_ground_order_receipts"]:
  sim.get(field)["unsupported-fixture"]={"ok":true}
  check(not HELPER.capture(sim,fresh).has("schema") and not HELPER.prepare_prebinding(sim,wire,fresh).ok,"unsupported air/encounter map rejects capture and prebinding: "+field)
  sim.get(field).clear()
 # Compatibility: default empty target uses the same new prebinding check.
 var empty=SIM.new(); root.add_child(empty); empty.set_physics_process(false)
 var empty_b:=owners(empty,adapter)
 var empty_state: Dictionary={"schema":"root_receipt_checkpoint.v1","value":load("res://scripts/mission/checkpoint_value_codec.gd").encode_value({"launch":{},"departure":{},"equipment":{}}).value}
 var ordinary: Dictionary=HELPER.prepare(empty,empty_state,empty_b)
 check(ordinary.get("ok",false) and HELPER.validate_prebinding(empty,ordinary.candidate,empty_b).ok,"ordinary empty target gains compatible prebinding validation")
 bind(empty,empty_b)
 check(HELPER.validate(empty,ordinary.candidate,empty_b).ok,"existing postbinding validation remains compatible")
 empty.free(); sim.free(); adapter.free()
 print("ROOT_RECEIPT_PREBINDING passed=%d failed=%d" % [passed,failed])
 if failed==0: print("ROOT_RECEIPT_PREBINDING_PASS")
 quit(0 if failed==0 else 1)
