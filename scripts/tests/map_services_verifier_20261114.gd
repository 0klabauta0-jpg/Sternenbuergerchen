extends SceneTree
const MAP=preload("res://scripts/terrain/terrain_map_data.gd")
const REG=preload("res://scripts/terrain/terrain_registry.gd")
const VIEW=preload("res://scripts/terrain/terrain_map_3d_view.gd")
const LAND=preload("res://scripts/mission/field_landing_contract.gd")
const BODY=preload("res://scripts/mission/hex_ground_ship_footprint.gd")
const PROFILE=preload("res://scripts/mission/polisa_ground_body_profile.gd")
const SIM=preload("res://scripts/core/simulation_root.gd")
const ADAPTER=preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const SUPPLY=preload("res://scripts/core/singleplayer_supply_state.gd")
const CAMPAIGN=preload("res://scripts/core/singleplayer_campaign_state.gd")
const FLEET=preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
var passed:=0
var failed:=0
class Controller extends Node:
 var at:=Vector2.ZERO
 var parked:=true
 var view:Node
 func _get_primary_3d_view()->Node:return view
 func _is_parked_campaign_dropship(_id:String)->bool:return parked
 func _campaign_landed_craft_position(_id:String)->Vector2:return at
class Driver extends Node:
 func get_mission_interaction_runtime_states()->Dictionary:return {"trade_service":{"complete":true}}
class Setup extends Node:
 var _loaded_terrain_map_data
class Flow extends Node:
 var _last_mission_result:Dictionary={}
 var _aircraft_location_by_craft:Dictionary={"ship":"mission"}
 var _homebase_aircraft_definitions:Array=[{"craft_id":"ship","model_id":"cutlass","team_id":"team_alpha"}]
 var mission:Node
 func _find_homebase_aircraft_definition(id:String)->Dictionary:return _homebase_aircraft_definitions[0] if id=="ship" else {}
 func _find_pending_mission_craft_transfer(_id:String)->Dictionary:return {}
 func _find_mission_drop_card_in_planning_state(_id:String)->Dictionary:return {"state":"landed"}
 func get_mission_for_craft(_id:String)->Node:return mission
func _initialize()->void:call_deferred("run")
func check(v:bool,label:String)->void:
 if v:passed+=1
 else:failed+=1
 print(("PASS " if v else "FAIL ")+label)
func registry(map)->Node:
 var r=REG.new();root.add_child(r);r.configure_iso_grid(map.get_grid_origin(),map.get_tile_size().half_width,map.get_tile_size().half_height,map.get_grid_topology())
 for tile in map.get_tiles():r.register_tile(tile)
 return r
func request(adapter:Node,op:String,id:String,extra:Dictionary={})->Dictionary:
 var payload:Dictionary={"craft_id":"ship","request_id":id,"offer_id":"medictool_supply","quantity":1,"amount":1.0}
 payload.merge(extra,true)
 return adapter.request_operation(op,payload)
func run()->void:
 var map=MAP.load_from_file("res://maps/Ground_Mission01_32x32.json")
 var r=registry(map)
 var view=VIEW.new();root.add_child(view);view.configure_from_map(map,map.get_marker_position("objective_point"),26.0)
 var craft:Dictionary={"craft_id":"surface_probe","model_id":"buccaneer"}
 var projection:Dictionary=view.get_station_craft_body_projection(craft)
 var bound:Dictionary=PROFILE.from_projection(craft,projection)
 print("BODY_PROFILE ",projection)
 check(bound.get("ok",false),"actual imported Buccaneer provides physical body profile")
 var valid:Array=[];var body_cells:Array=[]
 var best_bad:=9999;var best:Dictionary={}
 if bound.get("ok",false):
  var body=BODY.new()
  for record:Array in map.get_place_presentation().rock_surface_cells:
   var cell:=Vector2i(int(record[0]),int(record[1]))
   var raster:Dictionary=body.cells_for_body(r,craft,r.grid_to_world(cell),bound.profile)
   if raster.get("ok",false):
    var bad:Array=[]
    for key:Vector2i in raster.blocked_cells:
     var part=r.get_tile_at_grid(key)
     if part==null or not part.walkable or part.height_level!=int(record[2]) or part.object_height>0:bad.append([key,part.height_level if part!=null else -1,part.walkable if part!=null else false])
    if bad.size()<best_bad:best_bad=bad.size();best={"center":cell,"height":record[2],"world":r.grid_to_world(cell),"footprint":raster.blocked_cells,"bad":bad}
    if LAND.validate_cells(r,raster.blocked_cells).get("ok",false):valid.append(cell);body_cells=raster.blocked_cells
 print("BODY_FOOTPRINT_DIAGNOSTIC ",best)
 check(not valid.is_empty(),"real mesa admits full existing Buccaneer footprint")
 if not valid.is_empty():
  var original=r.get_tile_at_grid(body_cells[0]).height_level
  r.get_tile_at_grid(body_cells[0]).height_level=original+1
  check(not LAND.validate_cells(r,body_cells).ok,"mixed-height physical footprint rejected")
  r.get_tile_at_grid(body_cells[0]).height_level=original
  r.get_tile_at_grid(body_cells[0]).walkable=false
  check(not LAND.validate_cells(r,body_cells).ok,"blocked edge physical footprint rejected")
  r.get_tile_at_grid(body_cells[0]).walkable=true
  check(not LAND.validate(r,valid[0],[r.grid_to_world(valid[0])]).ok,"occupied landing rejected")
 var record:Array=map.get_place_presentation().rock_surface_cells[0]
 var tile=map.get_tile_at_grid(Vector2i(int(record[0]),int(record[1])))
 check(view._has_authored_rock_surface(tile),"exact living mesh owns saved cap")
 var level:int=tile.height_level;tile.height_level+=1
 check(not view._has_authored_rock_surface(tile),"editor height change restores ordinary cap while source lives")
 tile.height_level=level
 var owner:Node=view._authored_rock_surface_owners[tile.grid_position].owner.get_ref()
 owner.free()
 check(not view._has_authored_rock_surface(tile),"freed cap owner restores normal ground fallback")
 var fallback:=Node3D.new();root.add_child(fallback)
 view._hex_ground_batch.clear();view._add_tile_visual(tile)
 check(view._hex_ground_batch.flush(fallback).tile_count==1,"freed exact mesh produces an actual replacement Hex cap")
 fallback.free()
 view.free();r.free()
 await process_frame
 await services()
 await station_rooms()
 print("MAP_SERVICES_VERIFIER passed=%d failed=%d"%[passed,failed])
 quit(0 if failed==0 else 1)
func services()->void:
 # Fixtures supply parked-pose/visit inputs; the adapter, Root, campaign,
 # supply, cargo scheduler and ship-system mutation paths are real owners.
 var flow:=Flow.new();root.add_child(flow)
 var mission:=Node.new();flow.add_child(mission);flow.mission=mission
 var controller:=Controller.new();controller.name="TacticalController";mission.add_child(controller)
 var driver:=Driver.new();driver.name="CombatLoopDriver";mission.add_child(driver)
 var setup:=Setup.new();setup.name="MissionSetup";mission.add_child(setup)
 setup._loaded_terrain_map_data=MAP.load_from_file("res://maps/trade_outpost.json")
 var terrain=registry(setup._loaded_terrain_map_data);terrain.get_parent().remove_child(terrain);terrain.name="TerrainRegistry";mission.add_child(terrain)
 controller.at=setup._loaded_terrain_map_data.get_marker_position("spawn_alpha")
 var campaign=CAMPAIGN.new();campaign.configure();campaign._departures_by_craft_id.ship={"destination_location_id":"trade_outpost"}
 var supply=SUPPLY.new();supply.configure(flow._homebase_aircraft_definitions);supply.configure_inventory([], ["ship"],true)
 var fleet=FLEET.new();fleet.configure();fleet.register_craft("ship");fleet._owners.ship._phase="surface"
 var sim=SIM.new();flow.add_child(sim);sim.set_physics_process(false);sim.configure_singleplayer_owners(campaign,supply,null,fleet);sim.set_peer_team(1,"team_alpha")
 var adapter=ADAPTER.new();flow.add_child(adapter);adapter._flow=flow;adapter._simulation=sim;adapter._campaign=campaign;adapter._supply=supply;adapter._travel=fleet;adapter._campaign_mode=true
 adapter._ship_equipment=load("res://scripts/core/singleplayer_ship_equipment_state.gd").new();adapter._ship_equipment.configure(flow._homebase_aircraft_definitions)
 adapter._cargo_transfer.configure(adapter._validate_cargo_transfer,adapter._cargo_inventory,adapter._transfer_cargo_item)
 check(sim.configure_departure_adapter(adapter).ok,"real Root binds real runtime adapter")
 var stats:Dictionary={"ok":true,"shield":{"capacity":10.0,"recharge_rate":1.0,"recovery_delay":2.0},"weapon_reserve":{"capacity":10.0,"recharge_rate":1.0},"power":{"weapon_fraction":0.5,"shield_fraction":0.5}}
 var systems=load("res://scripts/tactical/space_component_systems.gd")
 var initial:Dictionary=systems.initial(stats,100.0)
 var hit:Dictionary=systems.apply_hit(stats,initial.state,35.0)
 sim._space_combat_state._ship_systems.ship={"stats":stats,"state":hit.state,"cooldowns":{}}
 var prior:Dictionary=supply.export_state();var hull_before:Dictionary=sim._space_combat_state.get_ship_systems("ship")
 for mode:String in ["foreign","offpad"]:
  if mode=="foreign":flow._homebase_aircraft_definitions[0].team_id="team_bravo"
  else:controller.at+=Vector2(4096,4096)
  for op:String in ["buy","refuel","repair","sell"]:check(not request(adapter,op,mode+op).get("ok",false),mode+" actual adapter rejects "+op)
  check(not adapter.request_operation("cargo_transfer_all",{"source_container_id":"station:trade_outpost:lift","destination_container_id":"craft:ship","request_id":mode+"cargo"}).get("ok",false),mode+" actual adapter rejects cargo")
  flow._homebase_aircraft_definitions[0].team_id="team_alpha";controller.at=setup._loaded_terrain_map_data.get_marker_position("spawn_alpha")
 check(supply.export_state()==prior and sim._space_combat_state.get_ship_systems("ship")==hull_before,"all denied services preserve credits fuel inventory hull")
 check(not request(adapter,"refuel","spoof-location",{"service_location_id":"polisa"}).get("ok",false),"UI location cannot spoof actual service")
 var buy:Dictionary=request(adapter,"buy","valid-buy")
 check(buy.get("ok",false) and buy.get("container_id","")=="station:trade_outpost:lift","real buy delivers to persistent local lift")
 check(request(adapter,"refuel","valid-fuel").get("ok",false),"real local adapter refuels")
 var repair:Dictionary=request(adapter,"repair","valid-repair")
 check(repair.get("ok",false) and repair.get("hull_before",0)==75.0 and repair.get("hull_after",0)==100.0,"real Root repairs damaged hull through supply command")
 check(request(adapter,"repair","valid-repair").get("replayed",false),"repair receipt is idempotent")
 var cargo:Dictionary=adapter.request_operation("cargo_transfer_all",{"source_container_id":"station:trade_outpost:lift","destination_container_id":"craft:ship","request_id":"valid-cargo"})
 check(cargo.get("ok",false),"real adapter starts local cargo job")
 adapter._cargo_transfer.advance(2.0)
 check(int(supply.get_supply_snapshot().inventory["craft:ship"].items.get("medictool",0))==1,"real timed cargo commits inventory movement")
 # A bounded ore fixture is input cargo, not an asserted mining playthrough.
 supply._inventory["craft:ship"].items.b_benit=2
 var credits_before:int=int(supply.get_supply_snapshot().credits)
 var back:Dictionary=adapter.request_operation("cargo_transfer_all",{"source_container_id":"craft:ship","destination_container_id":"station:trade_outpost:lift","request_id":"return-cargo"})
 check(back.get("ok",false),"real adapter starts ship-to-lift unloading")
 adapter._cargo_transfer.advance(4.0)
 check(supply.get_supply_snapshot().inventory["craft:ship"].items.is_empty() and int(supply.get_supply_snapshot().inventory["station:trade_outpost:lift"].items.get("b_benit",0))==2,"unloading conserves quantities and empties ship")
 var sold:Dictionary=request(adapter,"sell","sell-stored",{"source_container_id":"station:trade_outpost:lift","item_id":"b_benit","quantity":1})
 check(sold.get("ok",false) and int(supply.get_supply_snapshot().credits)==credits_before+15 and int(supply.get_supply_snapshot().inventory["station:trade_outpost:lift"].items.b_benit)==1,"actual adapter sells local stored ore once with correct credits")
 var stage:=Node3D.new();root.add_child(stage)
 var built:Dictionary=load("res://scripts/terrain/place_reference_dressing.gd").build(stage,setup._loaded_terrain_map_data.get_place_presentation())
 var visual=VIEW.new();root.add_child(visual);visual._place_dressing_root=built.root;controller.view=visual
 adapter._project_ground_cargo_lifts()
 var lift:Node=built.root.get_node("trade_lift")
 check(lift.get_meta("displayed_cargo_count")==2 and lift.get_meta("displayed_transfer_phase")=="complete","real adapter projects committed lift quantity and transfer state")
 var saved_job:Dictionary=adapter._cargo_transfer._job.duplicate(true)
 adapter._cargo_transfer._job={"phase":"active","source":"station:polisa:lift","target":"craft:other","total":1,"completed":0,"request_id":"other-place","reason":""}
 adapter._project_ground_cargo_lifts()
 check(lift.get_meta("displayed_transfer_phase")=="idle" and lift.get_meta("displayed_cargo_count")==2,"Polisa job cannot animate unrelated ground lift")
 adapter._cargo_transfer._job=saved_job
 visual._place_dressing_root=null;controller.view=null;visual.free();stage.free()
 check(flow._aircraft_location_by_craft.ship=="mission" and fleet.get_snapshot("ship").phase=="surface","repair and cargo preserve physical ship location")
 var restored=SUPPLY.new();check(restored.restore_state(supply.export_state()).get("ok",false),"new cargo container and repair receipts survive ordinary restore")
 # Exercise the production recovery clock against this actual adapter and
 # its live local service context, including both accepted ground phases.
 var real_flow=load("res://scripts/meta/meta_layer_flow.gd").new()
 real_flow._singleplayer_runtime=adapter
 real_flow._aircraft_location_by_craft=flow._aircraft_location_by_craft
 var recovery=load("res://scripts/meta/air_asset_recovery_state.gd")
 for phase:String in ["surface","grounded"]:
  fleet._owners.ship._phase=phase
  real_flow._air_asset_recovery_by_craft.ship=recovery.from_air_asset_status({"asset_id":"ship","state":"damaged","integrity":50,"max_integrity":100},{"craft_id":"ship"},{"repair_seconds":2.0})
  controller.at+=Vector2(4096,4096)
  real_flow._advance_air_asset_recoveries(1.0)
  check(float(real_flow._air_asset_recovery_by_craft.ship.elapsed_seconds)==0.0,phase+" offpad real recovery clock stays stopped")
  controller.at=setup._loaded_terrain_map_data.get_marker_position("spawn_alpha")
  real_flow._advance_air_asset_recoveries(1.0)
  check(float(real_flow._air_asset_recovery_by_craft.ship.elapsed_seconds)==1.0,phase+" local service advances production recovery clock")
  real_flow._advance_air_asset_recoveries(2.0)
  check(real_flow._air_asset_recovery_by_craft.ship.meta_state=="craft_available" and flow._aircraft_location_by_craft.ship=="mission",phase+" repair completion never teleports craft home")
 campaign._departures_by_craft_id.ship.destination_location_id="polisa";fleet._owners.ship._phase="surface"
 real_flow._air_asset_recovery_by_craft.ship=recovery.from_air_asset_status({"asset_id":"ship","state":"damaged","integrity":50},{"craft_id":"ship"},{"repair_seconds":2.0})
 real_flow._advance_air_asset_recoveries(1.0)
 check(float(real_flow._air_asset_recovery_by_craft.ship.elapsed_seconds)==1.0 and flow._aircraft_location_by_craft.ship=="mission","existing Polisa surface service recovery remains usable")
 campaign._departures_by_craft_id.ship.destination_location_id="satellite_crash"
 var satellite=MAP.load_from_file("res://maps/satellite_crash_site.json")
 setup._loaded_terrain_map_data=satellite;controller.at=satellite.get_marker_position("trade_service")
 supply._inventory["craft:ship"].items.c_benit=1
 check(request(adapter,"sell","satellite-local-sell",{"item_id":"c_benit","quantity":1}).get("ok",false),"existing satellite NPC trade remains available to nearby parked ship")
 check(not request(adapter,"refuel","satellite-no-fuel-pad").get("ok",false),"satellite NPC trade does not invent refuel service")
 controller.at+=Vector2(4096,4096)
 check(not request(adapter,"sell","satellite-remote-sell",{"item_id":"c_benit","quantity":1}).get("ok",false),"satellite NPC cannot remotely sell from distant ship")
 campaign._departures_by_craft_id.ship.destination_location_id="trade_outpost"
 real_flow.free()
 await presenter_checks(supply.get_supply_snapshot())
 flow.free();await process_frame

var ui_snapshot:Dictionary={}
var ui_sent:Array=[]
func ui_read()->Dictionary:return ui_snapshot
func ui_command(op:String,payload:Dictionary)->Dictionary:
 ui_sent.append({"op":op,"payload":payload.duplicate(true)});return {"ok":true}
func presenter_checks(supply:Dictionary)->void:
 var presenter=load("res://scripts/meta/singleplayer_services_presenter.gd").new()
 presenter.configure(ui_read,ui_command)
 root.add_child(presenter)
 presenter.set_section("ship")
 ui_snapshot={"mode":"campaign","location_view":{"location_id":"trade_outpost","craft_id":"ship"},"crafts":[{"craft_id":"ship","model_id":"cutlass","location_id":"trade_outpost","busy":false}],"supply":supply,"campaign":{"jobs":{},"progress":{}},"service_contexts_by_craft_id":{"ship":{"location_id":"trade_outpost","craft_busy":false,"ground_service_verified":true,"services":["trade","cargo","refuel","repair"],"cargo_lift_container_id":"station:trade_outpost:lift"}}}
 presenter.refresh()
 check(not presenter._repair.disabled and not presenter._cargo_load.disabled and not presenter._cargo_unload.disabled,"presenter enables three authorized local service buttons")
 presenter._repair.emit_signal("pressed");presenter._cargo_load.emit_signal("pressed");presenter._cargo_unload.emit_signal("pressed")
 check(ui_sent.size()==3 and ui_sent[0].op=="repair" and ui_sent[1].payload.source_container_id=="station:trade_outpost:lift" and ui_sent[2].payload.destination_container_id=="station:trade_outpost:lift","three real button signals submit correct owner requests")
 ui_snapshot.service_contexts_by_craft_id.ship.services=["repair"];presenter.refresh()
 check(presenter._buy.disabled and presenter._refuel.disabled and presenter._cargo_load.disabled and presenter._cargo_unload.disabled and not presenter._repair.disabled,"repair-only pad cannot enable trade fuel or cargo")
 ui_snapshot.location_view.location_id="homebase";ui_snapshot.crafts[0].location_id="homebase";ui_snapshot.service_contexts_by_craft_id.ship.location_id="homebase";presenter.refresh()
 check(not presenter._cargo_load.visible and not presenter._cargo_unload.visible,"section gate keeps ground cargo buttons hidden at home")
 presenter.free();await process_frame

func station_rooms()->void:
 for id:String in ["station_outpost_64x64","station_outpost_192x192"]:
  var map=MAP.load_from_file("res://maps/"+id+".json");var r=registry(map)
  var pathfinder=load("res://scripts/terrain/terrain_pathfinder.gd").new()
  for region:Dictionary in map.get_place_presentation().station_module_layout.regions:
   var bounds:Array=region.floor_boundary;var anchor:int=int(region.row_anchor)
   var corners_ok:=true
   for q:int in [int(bounds[0]),int(bounds[2])]:
    for y:int in [int(bounds[1]),int(bounds[3])]:
     var cell:=Vector2i(q-floori(float(y-anchor)/2.0),y)
     corners_ok=corners_ok and not r.is_walkable(cell) and r.get_tile_at_grid(cell).object_type_id=="station_set_wall_corner"
   check(corners_ok,id+" "+String(region.id)+" four closed outer corners")
   var doors_ok:bool=region.single_door_cells.size()==4
   for cell:Array in region.single_door_cells:
    var tile=r.get_tile_at_grid(Vector2i(int(cell[0]),int(cell[1])))
    doors_ok=doors_ok and tile.walkable and not tile.blocks_los and tile.object_type_id=="station_set_door_single"
   check(doors_ok,id+" "+String(region.id)+" four real passable single-door cells")
   var centers:Array[Vector2i]=[]
   var cx:int=(int(bounds[0])+int(bounds[2]))/2;var cy:int=(int(bounds[1])+int(bounds[3]))/2
   for limits:Array in [[bounds[0]+1,bounds[1]+1,cx,cy],[cx+1,bounds[1]+1,bounds[2],cy],[bounds[0]+1,cy+1,cx,bounds[3]],[cx+1,cy+1,bounds[2],bounds[3]]]:
    var found:=false
    for y in range(int(limits[1]),int(limits[3])):
     for q in range(int(limits[0]),int(limits[2])):
      var cell:=Vector2i(q-floori(float(y-anchor)/2.0),y)
      if r.is_walkable(cell):centers.append(cell);found=true;break
     if found:break
   var connected:=centers.size()==4
   if connected:
    for i in range(1,4):connected=connected and not pathfinder.find_path(centers[0],centers[i],r).is_empty()
   check(connected,id+" "+String(region.id)+" four rooms connected through actual door cells")
  var offset:=64 if id.ends_with("192x192") else 0
  var binding:Dictionary={"interaction_id":"station_route_drill_door","interaction_type":"door","marker_id":"station_entry_door","required_order":"breach","radius_world":128.0,"duration_seconds":2.0,"door_cells":[{"x":39+offset,"y":31+offset},{"x":40+offset,"y":31+offset}]}
  var footprint=load("res://scripts/mission/mission_door_footprint.gd")
  check(footprint.validate_binding(binding,map).get("ok",false),id+" existing two-cell mission breach preserved")
  r.free();await process_frame
