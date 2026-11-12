extends SceneTree
const START=preload("res://scripts/meta/game_start_contract.gd")
const BODY=preload("res://scripts/meta/home_craft_footprint.gd")
const NAV=preload("res://scripts/meta/base_interior_navigation.gd")
var failed:=0
func _init():call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS: " if ok else "FAIL: ")+label)
	if not ok:failed+=1
func run():
	START.request_start(self,"campaign","new")
	var flow:Node=load("res://scenes/meta/meta_layer_test.tscn").instantiate();root.add_child(flow)
	await process_frame
	var adapter:Node=flow.get("_singleplayer_runtime")
	var base:Node=adapter.get_base_personnel_runtime()
	var sim:Node=base.get_simulation_root();sim.set_physics_process(false)
	var pad:Dictionary=base._find_layout("landing_pads",adapter._home_pad_for("dropship_1"))
	var craft:Dictionary=flow._find_homebase_aircraft_definition("dropship_1")
	var footprint:Dictionary=BODY.rect_for_craft(craft,pad)
	check(footprint.get("ok",false),"actual model catalog and home pad yield a finite footprint")
	var view=load("res://scripts/terrain/terrain_map_3d_view.gd").new()
	var projection:Dictionary=view.get_station_craft_body_projection(craft)
	var identity:Dictionary=load("res://scripts/terrain/frontier_ship_visuals.gd").get_ui_identity(craft)
	var bounds:Variant=projection.get("bounds")
	var source:Array=identity.get("bounds_size",[])
	check(bounds is AABB and source.size()==3 and (bounds as AABB).size.is_equal_approx(Vector3(source[0],source[1],source[2])),"catalog footprint matches actual loaded ship bounds")
	view.free()
	var center:Vector2=base._world(pad.grid)
	var rejected:Dictionary=base.request_operation("base_move",{"unit_id":"campaign_leader","target_position":center})
	check(not rejected.get("ok",false),"normal movement cannot target landed ship centre")
	var access:Vector2=base._pad_world("dropship_1")
	var p:Vector3=NAV.plane_at_grid(base._terrain.world_to_grid(access))
	check(not (footprint.rect as Rect2).has_point(Vector2(p.x,p.z)),"boarding approach lies outside ship")
	var actor:Node2D=base.get_actor("campaign_leader")
	var previous:=actor.position
	actor.position=center
	var old_save:Dictionary={"base_personnel":{"units":{"campaign_leader":{"status":"outside"}}}}
	base.reconcile_restored_ship_overlap(old_save)
	p=NAV.plane_at_grid(base._terrain.world_to_grid(actor.position))
	check(not (footprint.rect as Rect2).has_point(Vector2(p.x,p.z)),"restored idle person inside parked hull moves to safe outside position")
	actor.position=center;base._states["campaign_leader"].status="moving"
	base.reconcile_restored_ship_overlap(old_save)
	check(actor.position==center,"restore correction never relocates an active walking person")
	base._states["campaign_leader"].status="outside"
	check(not base.preview_home_craft_arrival(craft,String(pad.id)).get("ok",false),"landing refuses an occupied ship footprint")
	actor.position=previous
	var walking:Dictionary=base.request_operation("base_move",{"unit_id":"campaign_leader","target_position":access})
	check(walking.get("ok",false) and not base.preview_home_craft_arrival(craft,String(pad.id)).get("ok",false),"landing waits while an existing base path is active")
	base.request_operation("base_cancel",{"unit_id":"campaign_leader"})
	flow._aircraft_location_by_craft["dropship_1"]="mission"
	base._refresh_home_craft_blockers()
	walking=base.request_operation("base_move",{"unit_id":"campaign_leader","target_position":center})
	check(walking.get("ok",false),"vacated ship footprint is walkable again")
	sim._physics_process(.05)
	flow._aircraft_location_by_craft["dropship_1"]="homebase"
	base._refresh_home_craft_blockers()
	check(String(base._states["campaign_leader"].status)!="moving", "new ship footprint stops an existing legacy path")
	var pilot:=String(base._screen.call("_get_assigned_pilot_id","dropship_1"))
	var board:Dictionary=base.request_operation("base_board",{"unit_id":pilot,"craft_id":"dropship_1"})
	check(board.get("ok",false),"actual pilot can start boarding")
	for i in range(4000):
		sim._physics_process(.05)
		if base.is_pilot_aboard("dropship_1"):break
	check(base.is_pilot_aboard("dropship_1"),"actual pilot boards")
	var unboard:Dictionary=base.request_operation("base_unboard",{"unit_id":pilot,"craft_id":"dropship_1"})
	check(unboard.get("ok",false),"actual pilot can unboard")
	actor=base.get_actor(pilot);p=NAV.plane_at_grid(base._terrain.world_to_grid(actor.position))
	check(not (footprint.rect as Rect2).has_point(Vector2(p.x,p.z)),"unboard places pilot outside hull")
	flow._aircraft_location_by_craft["dropship_1"]="mission"
	base._refresh_home_craft_blockers()
	var reservation:Dictionary=adapter._reserve_service_home_pad("service-probe")
	check(reservation.get("ok",false),"real service owner reserves temporarily vacant home pad")
	var service_move:Dictionary=base.request_operation("base_move",{"unit_id":pilot,"target_position":center})
	check(not service_move.get("ok",false),"reserved arriving shuttle footprint blocks new ground paths")
	adapter._release_service_home_pad("service-probe",String(reservation.get("pad_id","")))
	check(base.request_operation("base_move",{"unit_id":pilot,"target_position":center}).get("ok",false),"service departure releases home navigation footprint")
	var retry:Dictionary=adapter._reserve_service_home_pad("service-probe-2")
	check(not retry.get("ok",false) and retry.get("reason","")=="home_craft_paths_active", "real service reservation waits for existing ground path")
	base.request_operation("base_cancel",{"unit_id":pilot})
	previous=actor.position;actor.position=center
	retry=adapter._reserve_service_home_pad("service-probe-2")
	check(not retry.get("ok",false) and retry.get("reason","")=="home_craft_pad_occupied", "real service reservation waits for person on pad")
	actor.position=previous
	# Persist a legacy-like idle position under the parked ship and exercise the
	# actual Continue setup, not only the reconciliation helper in isolation.
	flow._aircraft_location_by_craft["dropship_1"]="homebase"
	base.request_operation("base_cancel",{"unit_id":pilot})
	actor.position=center
	var saved:Dictionary=flow.get("_campaign_start").call("save_home_checkpoint",flow,adapter)
	check(saved.get("ok",false),"legacy-style occupied position can be checkpointed")
	flow.queue_free();await process_frame
	if saved.get("ok",false):
		START.request_start(self,"campaign","continue")
		flow=load("res://scenes/meta/meta_layer_test.tscn").instantiate();root.add_child(flow);await process_frame
		adapter=flow.get("_singleplayer_runtime");base=adapter.get_base_personnel_runtime();actor=base.get_actor(pilot)
		p=NAV.plane_at_grid(base._terrain.world_to_grid(actor.position))
		check(not (footprint.rect as Rect2).has_point(Vector2(p.x,p.z)),"actual Continue relocates legacy person outside parked hull")
		flow.queue_free();await process_frame
	if failed==0:print("HOME_PARKED_CRAFT_CLEARANCE_PASS")
	quit(0 if failed==0 else 1)
