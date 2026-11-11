extends SceneTree
const GROUND=preload("res://scripts/core/hex_ground_runtime.gd")
const RESOLVER=preload("res://scripts/tactical/bottleneck_reservation_resolver.gd")
const REGISTRY=preload("res://scripts/terrain/terrain_registry.gd")
const TILE=preload("res://scripts/terrain/terrain_tile_data.gd")
var passed:=0
var failed:=0
func _init() -> void: call_deferred("_run")
func _check(value: bool,label: String) -> void:
	if value:
		passed+=1
		print("PASS: ",label)
	else:
		failed+=1
		print("FAIL: ",label)
func _segment(id: String,from: Vector2i,to: Vector2i,start: int,duration: int) -> Dictionary:
	return {"unit_id":id,"command_id":"move_"+id,"from_grid":from,"to_grid":to,
		"start_tick":start,"duration_ticks":duration,"handoff_tick":start+ceili(duration/2.0)}
func _request(id: String,path: Array,durations: Array) -> Dictionary:
	return {"unit_id":id,"command_id":"move_"+id,"priority":0,"path_grid_points":path,"duration_ticks_by_step":durations}
func _run() -> void:
	var state=GROUND.new()
	_check(state.has_method("commit_plan") and state.has_method("advance_tick"),"ground owner commits and advances reserved plans")
	if failed>0:
		_finish()
		return
	var terrain=REGISTRY.new()
	terrain.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	for x in range(6):
		for y in range(2):
			terrain.register_tile(TILE.new({"tile_id":"%d_%d"%[x,y],"grid_position":Vector2i(x,y),"walkable":true}))
	state.configure(terrain,"owner_fixture",0)
	var batch:Array[Dictionary]=[{"unit_id":"a","grid":Vector2i(0,0)},{"unit_id":"b","grid":Vector2i(1,0)}]
	state.admit_units(batch)
	var snapshot:Dictionary=state.build_planning_snapshot()
	_check(snapshot.get("reservation_schema_version")==1 and snapshot.get("committed_segments")==[] and snapshot.get("committed_corridor_grants")==[],"real owner emits explicit empty reservation schema")
	var requests:Array=[_request("a",[Vector2i(0,0),Vector2i(1,0),Vector2i(2,0)],[2,2]),_request("b",[Vector2i(1,0),Vector2i(2,0),Vector2i(3,0)],[4,4])]
	var plan:Dictionary=RESOLVER.build_hex_plan(requests,snapshot,terrain)
	_check(plan.ok and plan.accepted_steps.size()==4,"pure planner accepts real owner snapshot")
	if not bool(plan.ok):
		terrain.free()
		_finish()
		return
	_check(not state.commit_plan(plan,int(snapshot.revision)+1).ok and state.build_planning_snapshot()==snapshot,"stale owner revision rejects without partial commit")
	var forged:Dictionary=plan.duplicate(true)
	forged.terrain_revision+=1
	_check(not state.commit_plan(forged,int(snapshot.revision)).ok and state.build_planning_snapshot()==snapshot,"terrain revision mismatch preserves owner state")
	forged=plan.duplicate(true)
	forged.accepted_steps=[_segment("a",Vector2i.ZERO,Vector2i(1,0),0,2)]
	_check(not state.commit_plan(forged,int(snapshot.revision)).ok and state.build_planning_snapshot()==snapshot,"stationary occupant is not an assumed shared release")
	forged.accepted_steps=[_segment("a",Vector2i.ZERO,Vector2i(1,0),0,4),_segment("b",Vector2i(1,0),Vector2i.ZERO,0,4)]
	_check(not state.commit_plan(forged,int(snapshot.revision)).ok and state.build_planning_snapshot()==snapshot,"opposing whole-edge interval rejects an apparent atomic swap")
	forged=plan.duplicate(true)
	forged.accepted_steps=[]
	for index in range(4): forged.accepted_steps.append(_segment("b",Vector2i(index+1,0),Vector2i(index+2,0),index*2,2))
	_check(not state.commit_plan(forged,int(snapshot.revision)).ok and state.build_planning_snapshot()==snapshot,"overlong future horizon rejects without partial reservation")
	forged=plan.duplicate(true)
	forged.corridor_grants=[{"cells":[Vector2i.ZERO,Vector2i(1,0)],"unit_ids":["a"]}]
	_check(not state.commit_plan(forged,int(snapshot.revision)).ok and state.build_planning_snapshot()==snapshot,"wide junctions cannot be forged into a narrow corridor mutex")
	_check(state.commit_plan(plan,int(snapshot.revision)).ok,"whole follower and leader plan commits atomically")
	_check(state.read_unit("a").grid==Vector2i.ZERO and state.read_unit("b").grid==Vector2i(1,0),"commit does not advance logical positions")
	var committed:Dictionary=state.build_planning_snapshot()
	var spawn:Array[Dictionary]=[{"unit_id":"spawn","grid":Vector2i(2,0)}]
	_check(not state.admit_units(spawn).ok and state.build_planning_snapshot()==committed,"admission cannot steal a future reserved target field")
	_check(committed.committed_segments.size()==4 and not state.commit_plan(plan,int(snapshot.revision)).ok,"committed promises persist and reject old plan replay")
	committed.committed_segments.clear()
	_check(state.build_planning_snapshot().committed_segments.size()==4,"planning payload cannot erase live commitments")
	var first_handoff:=1000
	var last_handoff:=0
	var final_tick:=0
	for segment in plan.accepted_steps:
		first_handoff=mini(first_handoff,int(segment.handoff_tick))
		last_handoff=maxi(last_handoff,int(segment.handoff_tick))
		final_tick=maxi(final_tick,int(segment.start_tick)+int(segment.duration_ticks))
	state.advance_tick(first_handoff-1)
	_check(state.read_unit("a").grid==Vector2i.ZERO and state.read_unit("b").grid==Vector2i(1,0),"no field release before the scheduled handoff")
	var first_events:Array=state.advance_tick(first_handoff)
	_check(not first_events.is_empty() and state.build_planning_snapshot().occupant_by_grid.size()==2,"handoff emits events and preserves exclusive indices")
	_check(RESOLVER.build_hex_plan([],state.build_planning_snapshot(),terrain).ok,"post-handoff owner retains a valid live edge snapshot")
	state.advance_tick(last_handoff)
	_check(state.read_unit("a").grid==Vector2i(2,0) and state.read_unit("b").grid==Vector2i(3,0) and state.build_planning_snapshot().occupant_by_grid.size()==2,"joint handoff transfers both fields without overlap")
	_check(not state.build_planning_snapshot().committed_segments.is_empty(),"handoff is not segment completion or destination arrival")
	var end_events:Array=state.advance_tick(final_tick)
	_check(not end_events.is_empty() and state.build_planning_snapshot().committed_segments.is_empty() and not state.read_unit("a").movement_state.moving and not state.read_unit("b").movement_state.moving,"segment end expires edges and stops motion after the final handoff")
	var ended:Dictionary=state.build_planning_snapshot()
	_check(state.advance_tick(final_tick).is_empty() and state.advance_tick(final_tick-1).is_empty() and state.build_planning_snapshot()==ended,"repeat and stale ticks cannot double-apply handoffs")
	state.configure(terrain,"release_fixture",0)
	state.admit_units(batch)
	snapshot=state.build_planning_snapshot()
	plan=RESOLVER.build_hex_plan(requests,snapshot,terrain)
	state.commit_plan(plan,int(snapshot.revision))
	state.release_unit("a","removed")
	var only_b:=true
	for segment in state.build_planning_snapshot().committed_segments:
		if segment.unit_id!="b": only_b=false
	_check(only_b and state.read_unit("a").is_empty(),"release removes its own future commitments")
	state.configure(terrain,"terrain_fixture",0)
	state.admit_units(batch)
	snapshot=state.build_planning_snapshot()
	plan=RESOLVER.build_hex_plan(requests,snapshot,terrain)
	state.commit_plan(plan,int(snapshot.revision))
	terrain.get_tile_at_grid(Vector2i(2,0)).walkable=false
	terrain.notify_tile_data_changed([Vector2i(2,0)])
	var invalidated:Array=state.advance_tick(1)
	_check(not invalidated.is_empty() and state.build_planning_snapshot().committed_segments.is_empty() and state.read_unit("a").grid==Vector2i.ZERO and state.read_unit("b").grid==Vector2i(1,0),"changed terrain cancels unsafe commitments before an illegal transition")
	var corridor=REGISTRY.new()
	corridor.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	for x in range(6):corridor.register_tile(TILE.new({"tile_id":"corr_%d"%x,"grid_position":Vector2i(x,0),"walkable":true}))
	state.configure(corridor,"grant_fixture",0)
	var group:Array[Dictionary]=[{"unit_id":"a","grid":Vector2i(2,0)},{"unit_id":"c","grid":Vector2i.ZERO}]
	state.admit_units(group)
	snapshot=state.build_planning_snapshot()
	plan=RESOLVER.build_hex_plan([_request("a",[Vector2i(2,0),Vector2i(3,0)],[4])],snapshot,corridor)
	_check(state.commit_plan(plan,int(snapshot.revision)).ok,"owner can preserve a closed local corridor cohort")
	snapshot=state.build_planning_snapshot()
	forged=RESOLVER.build_hex_plan([],snapshot,corridor)
	forged.accepted_steps=[_segment("c",Vector2i.ZERO,Vector2i(1,0),0,4)]
	_check(not state.commit_plan(forged,int(snapshot.revision)).ok and state.build_planning_snapshot()==snapshot,"forged foreign entry cannot bypass an active corridor cohort")
	forged=RESOLVER.build_hex_plan([],snapshot,corridor)
	forged.corridor_grants=[]
	_check(not state.commit_plan(forged,int(snapshot.revision)).ok and state.build_planning_snapshot()==snapshot,"active corridor cohort cannot silently disappear from a proposal")
	corridor.register_tile(TILE.new({"tile_id":"side_door","grid_position":Vector2i(2,1),"walkable":false}))
	state.advance_tick(1)
	_check(state.build_planning_snapshot().committed_corridor_grants.size()==1,"unrelated blocked terrain edit preserves a valid active cohort")
	corridor.set_runtime_tile_overrides([{"grid_position":Vector2i(2,1),"walkable_override":true}])
	var reclassified:Array=state.advance_tick(2)
	_check(not reclassified.is_empty() and state.build_planning_snapshot().committed_corridor_grants.is_empty() and state.build_planning_snapshot().committed_segments.size()==1 and state.read_unit("a").grid==Vector2i(3,0),"opening a legal branch retires stale corridor topology while keeping valid movement")
	state.advance_tick(4)
	var onward:Dictionary=RESOLVER.build_hex_plan([_request("a",[Vector2i(3,0),Vector2i(4,0)],[2])],state.build_planning_snapshot(),corridor)
	_check(onward.ok and not onward.accepted_steps.is_empty() and state.commit_plan(onward,int(onward.expected_revision)).ok,"topology reclassification cannot permanently lock later commits")
	corridor.set_runtime_tile_overrides([])
	state.configure(corridor,"opposing_grant",0)
	corridor.get_hex_corridor_topology([Vector2i.ZERO],64)
	group=[{"unit_id":"a","grid":Vector2i.ZERO},{"unit_id":"c","grid":Vector2i(5,0)}]
	state.admit_units(group)
	snapshot=state.build_planning_snapshot()
	forged=RESOLVER.build_hex_plan([],snapshot,corridor)
	forged.accepted_steps=[_segment("a",Vector2i.ZERO,Vector2i(1,0),0,2),_segment("a",Vector2i(1,0),Vector2i(2,0),2,2),_segment("c",Vector2i(5,0),Vector2i(4,0),0,2),_segment("c",Vector2i(4,0),Vector2i(3,0),2,2)]
	forged.corridor_grants=[{"cells":[Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0),Vector2i(3,0),Vector2i(4,0),Vector2i(5,0)],"unit_ids":["a","c"]}]
	_check(not state.commit_plan(forged,int(snapshot.revision)).ok and state.build_planning_snapshot()==snapshot,"opposite directions cannot masquerade as one new closed corridor cohort")
	var corridor_cells:Array=forged.corridor_grants[0].cells.duplicate()
	forged.corridor_grants=[{"cells":corridor_cells,"unit_ids":["a"]},{"cells":corridor_cells,"unit_ids":["c"]}]
	_check(not state.commit_plan(forged,int(snapshot.revision)).ok and state.build_planning_snapshot()==snapshot,"split new grants cannot authorize opposite cohorts in the same corridor")
	forged.corridor_grants=[]
	_check(not state.commit_plan(forged,int(snapshot.revision)).ok and state.build_planning_snapshot()==snapshot,"omitted grants cannot bypass canonical corridor policy")
	state.configure(corridor,"clock_limit",1000000000000)
	var last:Array[Dictionary]=[{"unit_id":"a","grid":Vector2i.ZERO}]
	state.admit_units(last)
	snapshot=state.build_planning_snapshot()
	var limit_plan:Dictionary=RESOLVER.build_hex_plan([_request("a",[Vector2i.ZERO,Vector2i(1,0)],[4])],snapshot,corridor)
	_check(not state.commit_plan(limit_plan,int(snapshot.revision)).ok and state.build_planning_snapshot()==snapshot,"owner rejects segments whose end is outside its executable clock")
	var exit_terrain=REGISTRY.new()
	exit_terrain.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	for grid in [Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0),Vector2i(3,0),Vector2i(4,0),Vector2i(5,0),Vector2i(4,1)]:
		exit_terrain.register_tile(TILE.new({"tile_id":str(grid),"grid_position":grid}))
	state.configure(exit_terrain,"corridor_exit",0)
	var exiting:Array[Dictionary]=[{"unit_id":"a","grid":Vector2i(3,0)}]
	state.admit_units(exiting)
	var exit_plan:Dictionary=RESOLVER.build_hex_plan([_request("a",[Vector2i(3,0),Vector2i(4,0)],[4])],state.build_planning_snapshot(),exit_terrain)
	_check(exit_plan.corridor_grants.size()==1 and state.commit_plan(exit_plan,int(exit_plan.expected_revision)).ok,"final member receives a committed corridor exit")
	state.advance_tick(2)
	_check(state.build_planning_snapshot().committed_corridor_grants.size()==1,"exit handoff still retains the corridor through the live edge")
	state.advance_tick(4)
	_check(state.read_unit("a").grid==Vector2i(4,0) and state.build_planning_snapshot().committed_corridor_grants.is_empty(),"completed final exit releases grant with a sparse empty schedule index")
	exit_terrain.free()
	corridor.free()
	terrain.free()
	_finish()
func _finish() -> void:
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0: print("HEX_RESERVATION_OWNER_PASS")
	quit(0 if failed==0 else 1)
