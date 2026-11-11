extends "res://scripts/tests/hex_movement_verifier.gd"
const VIEW=preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MOVEMENT=preload("res://scripts/tactical/fireteam_movement_controller.gd")

func _finish()->void:
	if failed==0:_test_movement_consumers()
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0:print("HEX_MOVEMENT_CONSUMERS_PASS")
	quit(0 if failed==0 else 1)

func _test_movement_consumers()->void:
	var sim=SIM.new()
	_check(sim.has_method("has_hex_position_arrived"),"Root offers identity and target-matched logical arrival for consumers")
	var view=VIEW.new()
	_check(view.has_method("_get_hex_unit_motion_visual"),"actual 3D view reads derived hex motion height and phase")
	view.free()
	sim.free()
	_test_group_arrival()
	_test_formations()
	_test_view_motion()

func _test_group_arrival()->void:
	var rig:Dictionary=_consumer_rig(false)
	var sim=rig.sim
	var actor=rig.actor
	var terrain=rig.terrain
	var movement=MOVEMENT.new()
	var goal:Vector2=terrain.grid_to_world(Vector2i.RIGHT)
	var result:Dictionary=movement.start_execution("ft1","move",0,goal,null,[actor],actor,sim,terrain)
	_check(result.get("started",false),"actual Fireteam controller issues a stage into the actual Root queue")
	actor.global_position=goal
	var early:Dictionary=movement.update_execution("ft1",[actor],actor,sim,terrain)
	_check(not early.get("finished",false) and movement.has_active_execution("ft1"),"render position at goal cannot finish an unaccepted hex stage")
	if not movement.has_active_execution("ft1"):
		_free_consumer_rig(rig)
		return
	var command_id:String=""
	var checked_handoff:=false
	for i in range(32):
		sim._physics_process(0.25)
		var readout:Dictionary=sim.get_hex_movement_readout("consumer")
		command_id=readout.source_command_id
		var state:Dictionary=sim.get_hex_unit_state("consumer")
		if not checked_handoff and state.grid==Vector2i.RIGHT and state.movement_state.moving:
			actor.global_position=goal
			var during:Dictionary=movement.update_execution("ft1",[actor],actor,sim,terrain)
			_check(not during.get("finished",false) and movement.has_active_execution("ft1"),"final field handoff does not finish the group before edge completion")
			checked_handoff=true
		if sim.has_hex_destination_arrived("consumer",command_id):break
	_check(checked_handoff and sim.has_hex_position_arrived("consumer",goal+Vector2(1,0),command_id),"target-matched arrival accepts another point in the same requested hex")
	_check(not sim.has_hex_position_arrived("consumer",terrain.grid_to_world(Vector2i(2,0)),command_id) and not sim.has_hex_position_arrived("consumer",goal,"stale") and not sim.has_hex_position_arrived("consumer",Vector2(NAN,0),command_id),"arrival rejects different goal hex, stale identity and nonfinite target")
	actor.global_position=terrain.grid_to_world(Vector2i(-1,0))
	var finished:Dictionary=movement.update_execution("ft1",[actor],actor,sim,terrain)
	_check(finished.get("finished",false) and not movement.has_active_execution("ft1"),"actual group finishes from Ground arrival despite stale rendered position")
	var records:Array=[{"unit_id":"consumer","unit":actor}]
	_check(movement.call("_build_current_positions",records,sim).consumer==goal,"stage planning reads its owner's logical cell instead of render position")
	sim.enqueue_command({"type":"hold_position","unit_id":"consumer","team_id":"blue","target_position":goal,"command_token":"cover_stage"})
	sim._physics_process(0.25)
	_check(sim.has_hex_position_arrived("consumer",goal,"cover_stage") and not sim.has_hex_destination_arrived("consumer",command_id),"explicit stationary covering Hold completes only its own stage identity")
	sim.enqueue_command({"type":"hold_position","unit_id":"consumer","team_id":"blue","command_token":"generic_hold"})
	sim._physics_process(0.25)
	_check(not sim.has_hex_position_arrived("consumer",goal,"generic_hold"),"valid generic Hold without a target is safely rejected by position-arrival reader")
	_check(not movement._are_hex_targets_reached({},records,PackedStringArray(["missing"]),{"missing":goal},sim) and sim.get_hex_logical_unit_position("missing")==null,"missing ground member cannot become implicit group arrival")
	var unadmitted=Actor.new()
	unadmitted.unit_id="ghost"
	root.add_child(unadmitted)
	_check(not movement.start_execution("ghost_team","move",0,goal,null,[unadmitted],unadmitted,sim,terrain).get("started",false),"unadmitted member is rejected before group stage construction")
	unadmitted.free()
	var legacy=SIM.new()
	actor.global_position=goal
	var legacy_state:Dictionary={"current_moving_unit_ids":PackedStringArray(["consumer"]),"current_target_positions":{"consumer":goal}}
	_check(movement._are_current_targets_reached(legacy_state,records,legacy),"legacy group arrival retains its existing pixel-radius branch")
	legacy.free()
	_free_consumer_rig(rig)

func _test_formations()->void:
	var rig:Dictionary=_consumer_rig(false)
	for x in range(-1,3):
		for y in [-1,1]:rig.terrain.register_tile(TILE.new({"tile_id":"%d_%d"%[x,y],"grid_position":Vector2i(x,y)}))
	var buddy=Actor.new()
	buddy.unit_id="buddy"
	root.add_child(buddy)
	rig.registry.register_unit("buddy",buddy)
	rig.sim.register_known_unit("buddy",buddy)
	var batch:Array[Dictionary]=[{"unit_id":"buddy","grid":Vector2i(0,1)}]
	rig.sim.admit_hex_ground_units(batch)
	var movement=MOVEMENT.new()
	var goal:Vector2=rig.terrain.grid_to_world(Vector2i.RIGHT)
	movement.start_execution("pair","move",0,goal,null,[rig.actor,buddy],rig.actor,rig.sim,rig.terrain)
	var first:Dictionary=movement.get_fireteam_state("pair").current_target_positions
	rig.actor.global_position=goal+Vector2(320,-160)
	buddy.global_position=Vector2(-200,200)
	movement.start_execution("pair","move",0,goal,null,[rig.actor,buddy],rig.actor,rig.sim,rig.terrain)
	_check(movement.get_fireteam_state("pair").current_target_positions==first,"multi-member stage targets are invariant under changed leader and buddy render positions")
	buddy.free()
	_free_consumer_rig(rig)

func _test_view_motion()->void:
	var rig:Dictionary=_consumer_rig(true)
	var sim=rig.sim
	var actor=rig.actor
	var terrain=rig.terrain
	var view=VIEW.new()
	view._active_grid_topology="hex_axial_v1"
	view._half_tile_width=64.0
	view._half_tile_height=32.0
	view._terrain_3d_mapping={"grid":{"height_step":0.5,"cell_size":2.0}}
	sim.enqueue_command(_command("consumer",terrain.grid_to_world(Vector2i.RIGHT)))
	sim._physics_process(0.25)
	sim._project_hex_ground_actors(0.5)
	var before:Dictionary=sim.get_hex_ground_planning_snapshot()
	var expected:Dictionary=sim.get_hex_motion_projection("consumer",0.5,0.5)
	var visual:Dictionary=view._get_hex_unit_motion_visual(actor)
	_check(visual.position.is_equal_approx(view._world_to_3d_position(actor.global_position,expected.stand_height_world+0.06)) and visual.moving==expected.moving,"actual view reader uses continuous ramp pose with mapped height step0.5")
	view._regional_height_step=0.75
	var regional:Dictionary=view._get_hex_unit_motion_visual(actor)
	_check(is_equal_approx(regional.position.y,expected.stand_height_logical*0.75+0.06),"same root pose uses existing regional height step0.75 without runtime reconfiguration")
	var proxy=Node3D.new()
	actor.set_meta("security_facing_active",true)
	actor.set_meta("security_facing_angle",PI)
	var fire_event:Dictionary={"target_position":actor.global_position-Vector2(64,32)}
	var expected_yaw:float=view._get_unit_world_direction_yaw(actor.global_position,actor.global_position+Vector2.RIGHT.rotated(float(actor.get_meta("facing_angle"))))
	_check(is_equal_approx(view._get_unit_proxy_rotation_y(proxy,actor,actor.global_position,fire_event),expected_yaw),"hex body facing stays committed despite fire target and stale security metadata")
	view._half_tile_width=256.0
	view._half_tile_height=128.0
	_check(is_equal_approx(view._get_unit_proxy_rotation_y(proxy,actor,actor.global_position,fire_event),180.0),"committed direction0 remains visible at allowed large256x128 projection metrics")
	_check(sim.get_hex_ground_planning_snapshot()==before,"view motion and facing reads do not mutate Ground")
	view._half_tile_width=64.0
	view._half_tile_height=32.0
	sim.enqueue_effect({"effect_type":"set_unit_combat_posture","unit_id":"consumer","facing_angle":PI})
	sim._physics_process(0.25)
	_check(sim.get_hex_unit_state("consumer").facing_dir==0 and is_equal_approx(view._get_unit_proxy_rotation_y(proxy,actor,actor.global_position),180.0),"actual cosmetic combat-posture facing write cannot override committed hex body direction")
	sim.release_hex_ground_unit("consumer","consumer_fixture")
	_check(view._get_hex_unit_motion_visual(actor).is_empty(),"release removes derived hex visual phase and restores legacy consumer branch")
	var legacy_yaw:float=view._get_unit_world_direction_yaw(actor.global_position,Vector2(fire_event.target_position))
	_check(is_equal_approx(view._get_unit_proxy_rotation_y(proxy,actor,actor.global_position,fire_event),legacy_yaw),"released actor keeps existing legacy fire-event body direction")
	proxy.free()
	view.free()
	_free_consumer_rig(rig)

func _consumer_rig(ramp:bool)->Dictionary:
	var terrain=REGISTRY.new()
	root.add_child(terrain)
	terrain.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	for x in range(-1,3):terrain.register_tile(TILE.new({"tile_id":str(x),"grid_position":Vector2i(x,0),"height_level":1 if ramp and x>0 else 0,"explicit_hex_ramps":ramp,"ramp_direction":0 if ramp and x==0 else -1}))
	var registry=UNITS.new()
	root.add_child(registry)
	var sim=SIM.new()
	root.add_child(sim)
	sim.unit_registry_path=sim.get_path_to(registry)
	sim.terrain_registry_path=sim.get_path_to(terrain)
	var map=MAP.create_empty("consumer",Vector2i(4,1),Vector2.ZERO,64,32,3,"hex_axial_v1")
	map.set_tactical_grid_rules("hex_tactical_v1")
	sim.configure_hex_ground_runtime(map,terrain)
	var actor=Actor.new()
	actor.unit_id="consumer"
	root.add_child(actor)
	registry.register_unit("consumer",actor)
	sim.register_known_unit("consumer",actor)
	var batch:Array[Dictionary]=[{"unit_id":"consumer","grid":Vector2i.ZERO}]
	sim.admit_hex_ground_units(batch)
	return {"sim":sim,"actor":actor,"terrain":terrain,"registry":registry}

func _free_consumer_rig(rig:Dictionary)->void:
	rig.actor.free()
	rig.sim.free()
	rig.registry.free()
	rig.terrain.free()
