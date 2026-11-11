extends SceneTree
const GROUND=preload("res://scripts/core/hex_ground_runtime.gd")
const REGISTRY=preload("res://scripts/terrain/terrain_registry.gd")
const TILE=preload("res://scripts/terrain/terrain_tile_data.gd")
const PLANNER=preload("res://scripts/tactical/bottleneck_reservation_resolver.gd")
var passed:=0
var failed:=0
func _init()->void:call_deferred("_run")
func _check(value:bool,label:String)->void:
	if value:passed+=1
	else:failed+=1
	print("PASS: " if value else "FAIL: ",label)
func _request(id:String,path:Array)->Dictionary:
	var durations:Array=[]
	for i in range(path.size()-1):durations.append(4)
	return {"unit_id":id,"command_id":"move_"+id,"priority":0,"path_grid_points":path,"duration_ticks_by_step":durations}
func _run()->void:
	var state=GROUND.new()
	_check(state.has_method("stop_units"),"owner stops coupled promises as one transaction")
	if failed>0:
		_finish()
		return
	var terrain=REGISTRY.new()
	terrain.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	for x in range(6):
		for y in range(2):terrain.register_tile(TILE.new({"tile_id":"%d_%d"%[x,y],"grid_position":Vector2i(x,y)}))
	for at_tick in [1,3]:
		state.configure(terrain,"coupled_stop",0)
		var batch:Array[Dictionary]=[{"unit_id":"a","grid":Vector2i.ZERO},{"unit_id":"b","grid":Vector2i(1,0)},{"unit_id":"c","grid":Vector2i(2,0)},{"unit_id":"d","grid":Vector2i(0,1)}]
		state.admit_units(batch)
		var requests:Array=[_request("a",[Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0),Vector2i(3,0)]),_request("b",[Vector2i(1,0),Vector2i(2,0),Vector2i(3,0),Vector2i(4,0)]),_request("c",[Vector2i(2,0),Vector2i(3,0),Vector2i(4,0),Vector2i(5,0)]),_request("d",[Vector2i(0,1),Vector2i(1,1)])]
		var plan:Dictionary=PLANNER.build_hex_plan(requests,state.build_planning_snapshot(),terrain)
		_check(plan.accepted_steps.size()==10 and state.commit_plan(plan,int(plan.expected_revision)).ok,"four real routes commit before stopping at tick%d"%at_tick)
		state.advance_tick(at_tick)
		var before:Dictionary=state.build_planning_snapshot()
		var visual:Dictionary=state.get_motion_projection("a",0.0)
		_check(not state.stop_units(PackedStringArray(["c","unknown"]),"injury").ok and state.build_planning_snapshot()==before,"invalid stop batch cannot partially cancel known units")
		var result:Dictionary=state.stop_units(PackedStringArray(["c"]),"injury")
		_check(result.ok and result.affected_unit_ids==["a","b","c"] and not result.events.is_empty(),"transitive follower dependency stops together without unrelated route")
		var after:Dictionary=state.build_planning_snapshot()
		_check(after.occupant_by_grid==before.occupant_by_grid and after.committed_segments.size()==1 and after.committed_segments[0].unit_id=="d","stop retains exclusive current fields and only cancels dependent promises")
		var pose:Dictionary=state.get_motion_projection("a",0.0)
		_check(pose.position_world.is_equal_approx(visual.position_world) and is_equal_approx(pose.stand_height_logical,visual.stand_height_logical) and state.read_unit("a").movement_state.phase=="centering","stop starts continuous centering inside owned field without teleport")
		var repeated:Dictionary=state.build_planning_snapshot()
		state.stop_units(PackedStringArray(["c"]),"injury")
		_check(state.build_planning_snapshot()==repeated,"repeated stop cannot postpone centering or alter revision")
		if at_tick==1:
			for bad_movement in ["centering",{"moving":true,"phase":"centering","start_tick":1}]:
				var bad:Dictionary=state.build_planning_snapshot()
				bad.units_by_id.a.movement_state=bad_movement
				if PLANNER._hex_valid_snapshot(bad,terrain):_check(false,"malformed centering state rejects before planner reads its deadline")
				else:_check(not PLANNER.build_hex_plan([_request("a",[Vector2i.ZERO,Vector2i(0,1)])],bad,terrain).ok,"malformed centering state rejects before planner reads its deadline")
			var resume:Dictionary=PLANNER.build_hex_plan([_request("a",[Vector2i.ZERO,Vector2i(0,1)])],state.build_planning_snapshot(),terrain)
			_check(resume.accepted_steps.size()==1 and resume.accepted_steps[0].start_tick==2,"planner waits for centering before a new traversal")
			var forged:Dictionary=resume.duplicate(true)
			forged.accepted_steps[0].start_tick=1
			forged.accepted_steps[0].handoff_tick=3
			_check(not state.commit_plan(forged,int(forged.expected_revision)).ok and state.build_planning_snapshot()==repeated,"owner independently rejects a traversal cutting through centering")
			_check(state.commit_plan(resume,int(resume.expected_revision)).ok,"legal delayed resume commits while centering owns its field")
		state.advance_tick(at_tick+1)
		var centered:Dictionary=state.get_motion_projection("b",0.0)
		_check(not centered.moving and centered.position_world.is_equal_approx(terrain.grid_to_world(state.read_unit("b").grid)),"centering finishes exactly at own center without a field event")
		_check(PLANNER.build_hex_plan([],state.build_planning_snapshot(),terrain).ok,"remaining and resumed schedules form a valid snapshot")
		state.release_unit("c","removed")
		var replacement:Array[Dictionary]=[{"unit_id":"c","grid":Vector2i(5,1)}]
		state.admit_units(replacement)
		_check(state.get_motion_projection("c",0.0).position_world==terrain.grid_to_world(Vector2i(5,1)) and not state.read_unit("c").movement_state.moving,"release and readmission cannot inherit a stale centering pose")
	state.configure(terrain,"historical_source",0)
	var moving:Array[Dictionary]=[{"unit_id":"b","grid":Vector2i.ZERO}]
	state.admit_units(moving)
	var leaving:Dictionary=PLANNER.build_hex_plan([_request("b",[Vector2i.ZERO,Vector2i(1,0)])],state.build_planning_snapshot(),terrain)
	state.commit_plan(leaving,int(leaving.expected_revision))
	state.advance_tick(3)
	var now_free:Array[Dictionary]=[{"unit_id":"a","grid":Vector2i.ZERO}]
	_check(state.admit_units(now_free).ok,"posthandoff source may be occupied by a new ground unit")
	var historical:Dictionary=state.stop_units(PackedStringArray(["a"]),"hold")
	_check(historical.affected_unit_ids==["a"] and state.build_planning_snapshot().committed_segments.size()==1 and state.read_unit("b").movement_state.moving,"past edge source cannot create a false stop dependency")
	var ramp=REGISTRY.new()
	ramp.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	ramp.register_tile(TILE.new({"tile_id":"ramp","grid_position":Vector2i.ZERO,"height_level":2,"ramp_direction":0,"explicit_hex_ramps":true}))
	ramp.register_tile(TILE.new({"tile_id":"upper","grid_position":Vector2i.RIGHT,"height_level":3,"explicit_hex_ramps":true}))
	state.configure(ramp,"revision_stop",0)
	var ramp_unit:Array[Dictionary]=[{"unit_id":"a","grid":Vector2i.ZERO}]
	state.admit_units(ramp_unit)
	var ramp_request:Dictionary=_request("a",[Vector2i.ZERO,Vector2i.RIGHT])
	ramp_request.duration_ticks_by_step=[8]
	var ramp_plan:Dictionary=PLANNER.build_hex_plan([ramp_request],state.build_planning_snapshot(),ramp)
	state.commit_plan(ramp_plan,int(ramp_plan.expected_revision))
	state.advance_tick(3)
	var old_pose:Dictionary=state.get_motion_projection("a",0.0)
	ramp.set_runtime_tile_overrides([{"grid_position":Vector2i.RIGHT,"walkable_override":false}])
	_check(state.get_motion_projection("a",0.0)==old_pose,"committed geometry remains readable for safe stop after terrain invalidation")
	state.advance_tick(4)
	var retreat:Dictionary=state.get_motion_projection("a",0.0)
	_check(state.read_unit("a").grid==Vector2i.ZERO and retreat.moving and retreat.position_world.is_equal_approx(ramp.grid_to_world(Vector2i.ZERO).lerp(ramp.grid_to_world(Vector2i.RIGHT),0.25)) and is_equal_approx(retreat.stand_height_logical,2.75),"terrain invalidation prevents handoff and centers smoothly within the owned ramp")
	state.advance_tick(6)
	_check(not state.read_unit("a").movement_state.moving and state.get_motion_projection("a",0.0).position_world==ramp.grid_to_world(Vector2i.ZERO),"invalidated ramp movement settles without entering the blocked field")
	ramp.free()
	state.configure(terrain,"metric_revision",0)
	state.admit_units(ramp_unit)
	var metric:Dictionary=PLANNER.build_hex_plan([_request("a",[Vector2i.ZERO,Vector2i.RIGHT])],state.build_planning_snapshot(),terrain)
	state.commit_plan(metric,int(metric.expected_revision))
	state.advance_tick(1)
	var revision:int=terrain.get_revision()
	terrain.configure_iso_grid(Vector2(100,50),64,32,"hex_axial_v1")
	var empty:Dictionary=PLANNER.build_hex_plan([],state.build_planning_snapshot(),terrain)
	_check(state.commit_plan(empty,int(empty.expected_revision)).ok,"empty commit may validate current terrain without consuming a pending geometry refresh")
	state.advance_tick(2)
	_check(terrain.get_revision()>revision and state.get_motion_projection("a",0.0).position_world.is_equal_approx(terrain.grid_to_world(Vector2i.ZERO).lerp(terrain.grid_to_world(Vector2i.RIGHT),0.5)),"metric changes revision and refresh legal derived movement geometry")
	state.configure(terrain,"centering_metric",0)
	state.admit_units(ramp_unit)
	var shrink_request:Dictionary=_request("a",[Vector2i.ZERO,Vector2i.RIGHT])
	shrink_request.duration_ticks_by_step=[8]
	var shrink:Dictionary=PLANNER.build_hex_plan([shrink_request],state.build_planning_snapshot(),terrain)
	state.commit_plan(shrink,int(shrink.expected_revision))
	state.advance_tick(3)
	state.stop_units(PackedStringArray(["a"]),"hold")
	state.advance_tick(4)
	terrain.configure_iso_grid(Vector2(100,50),6.4,3.2,"hex_axial_v1")
	state.advance_tick(5)
	var local_pose:Dictionary=state.get_motion_projection("a",0.0)
	_check(local_pose.position_world.is_equal_approx(terrain.grid_to_world(Vector2i.ZERO).lerp(terrain.grid_to_world(Vector2i.RIGHT),0.125)) and terrain.world_to_grid(local_pose.position_world)==Vector2i.ZERO,"centering remains in its own intrinsic hex after metric shrink")
	state.configure(terrain,"integer_centering",0)
	state.admit_units(ramp_unit)
	shrink_request.duration_ticks_by_step=[10]
	shrink=PLANNER.build_hex_plan([shrink_request],state.build_planning_snapshot(),terrain)
	state.commit_plan(shrink,int(shrink.expected_revision))
	state.advance_tick(7)
	state.stop_units(PackedStringArray(["a"]),"hold")
	var exact_duration:int=state.read_unit("a").movement_state.duration_ticks
	state.advance_tick(10)
	_check(exact_duration==3 and not state.read_unit("a").movement_state.moving,"centering duration uses exact integer rest ticks without float-ceil drift")
	state.clear()
	_check(state.get_motion_projection("a",0.0).is_empty(),"context clear removes centering and movement")
	terrain.free()
	_finish()
func _finish()->void:
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0:print("HEX_MOVEMENT_STOP_PASS")
	quit(0 if failed==0 else 1)
