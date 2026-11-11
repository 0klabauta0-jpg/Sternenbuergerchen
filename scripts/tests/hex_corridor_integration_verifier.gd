extends SceneTree
const REGISTRY=preload("res://scripts/terrain/terrain_registry.gd")
const TILE=preload("res://scripts/terrain/terrain_tile_data.gd")
const CACHE=preload("res://scripts/terrain/hex_corridor_topology_cache.gd")
const GROUND=preload("res://scripts/core/hex_ground_runtime.gd")
const PLANNER=preload("res://scripts/tactical/bottleneck_reservation_resolver.gd")
var passed:=0
var failed:=0
class FallbackRegistry extends Node:
	var source:Node
	func is_walkable(grid):return source.is_walkable(grid)
	func get_revision():return source.get_revision()
	func get_grid_topology():return source.get_grid_topology()
	func get_tile_at_grid(grid):return source.get_tile_at_grid(grid)
func _init()->void:call_deferred("_run")
func _check(value:bool,label:String)->void:
	if value:passed+=1
	else:failed+=1
	print("PASS: " if value else "FAIL: ",label)
func _run()->void:
	var terrain=REGISTRY.new()
	_check(terrain.has_method("get_hex_corridor_topology"),"registry owns shared complete corridor topology")
	if failed>0:
		terrain.free()
		_finish()
		return
	terrain.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	var path:Array=[]
	var durations:Array=[]
	for x in range(80):
		var grid:=Vector2i(x,0)
		terrain.register_tile(TILE.new({"tile_id":str(grid),"grid_position":grid,"explicit_hex_ramps":true}))
		path.append(grid)
		if x>0:durations.append(2)
	var state=GROUND.new()
	state.configure(terrain,"long_corridor",0)
	var batch:Array[Dictionary]=[{"unit_id":"a","grid":Vector2i.ZERO}]
	state.admit_units(batch)
	var request:Dictionary={"unit_id":"a","command_id":"long","priority":0,"path_grid_points":path,"duration_ticks_by_step":durations}
	var cold:Dictionary=PLANNER.build_hex_plan([request],state.build_planning_snapshot(),terrain)
	_check(cold.ok and cold.accepted_steps.is_empty() and cold.pending_requests.size()==1 and cold.reason=="topology_pending","cold long component remains pending instead of publishing a truncated grant")
	var warm:Dictionary=PLANNER.build_hex_plan([request],state.build_planning_snapshot(),terrain)
	_check(warm.ok and warm.accepted_steps.size()==3 and warm.corridor_grants.size()==1 and warm.corridor_grants[0].cells.size()==80,"resumed planner grants the full long corridor with three-step horizon")
	var exit_blocker:Array[Dictionary]=[{"unit_id":"blocker","grid":Vector2i(79,0)}]
	state.admit_units(exit_blocker)
	var blocked:Dictionary=PLANNER.build_hex_plan([request],state.build_planning_snapshot(),terrain)
	_check(blocked.accepted_steps.is_empty() and blocked.pending_requests.size()==1 and blocked.blocked[0].reason=="no_passing_space","occupied far exit remains blocked beyond the old 64-field scan")
	state.release_unit("blocker","fixture")
	warm=PLANNER.build_hex_plan([request],state.build_planning_snapshot(),terrain)
	var before:Dictionary=state.build_planning_snapshot()
	var forged:Dictionary=warm.duplicate(true)
	forged.corridor_grants[0].cells=forged.corridor_grants[0].cells.slice(0,64)
	_check(not state.commit_plan(forged,int(forged.expected_revision)).ok and state.build_planning_snapshot()==before,"owner rejects a locally legal truncated long grant")
	_check(state.commit_plan(warm,int(warm.expected_revision)).ok,"owner independently accepts the complete cached topology")
	var proof:Dictionary=terrain.get_hex_corridor_topology([Vector2i.ZERO],0)
	_check(proof.query_complete and proof.processed_nodes==0 and proof.corridors[0].cells.size()==80,"owner proof needs no additional topology construction")
	terrain.register_tile(TILE.new({"tile_id":"extension","grid_position":Vector2i(80,0),"explicit_hex_ramps":true}))
	state.advance_tick(1)
	_check(state.build_planning_snapshot().committed_corridor_grants.size()==1,"unfinished reclassification preserves the old cohort while new commits wait")
	terrain.get_hex_corridor_topology([Vector2i.ZERO],64)
	terrain.get_hex_corridor_topology([Vector2i.ZERO],64)
	state.advance_tick(6)
	_check(state.build_planning_snapshot().committed_corridor_grants.is_empty(),"completed changed component retires even a geometrically legal shortened old grant")
	var onward:Dictionary=PLANNER.build_hex_plan([{"unit_id":"a","command_id":"onward","priority":0,"path_grid_points":[Vector2i(3,0),Vector2i(4,0)],"duration_ticks_by_step":[2]}],state.build_planning_snapshot(),terrain)
	_check(onward.accepted_steps.size()==1 and onward.corridor_grants[0].cells.size()==81 and state.commit_plan(onward,int(onward.expected_revision)).ok,"fresh complete component can be committed after reclassification")
	var stale=GROUND.new()
	stale.configure(terrain,"stale_exit",0)
	stale.admit_units(batch)
	var stale_path:Array=path.duplicate()
	stale_path.append(Vector2i(80,0))
	var stale_durations:Array=durations.duplicate()
	stale_durations.append(2)
	var stale_request:Dictionary={"unit_id":"a","command_id":"stale","priority":0,"path_grid_points":stale_path,"duration_ticks_by_step":stale_durations}
	terrain.get_tile_at_grid(Vector2i(80,0)).walkable=false
	terrain.notify_tile_data_changed([Vector2i(80,0)])
	PLANNER.build_hex_plan([stale_request],stale.build_planning_snapshot(),terrain)
	var closed_exit:Dictionary=PLANNER.build_hex_plan([stale_request],stale.build_planning_snapshot(),terrain)
	_check(closed_exit.accepted_steps.is_empty() and closed_exit.blocked[0].reason=="illegal_corridor_exit","closed far door cannot be mistaken for a free corridor exit on a stale route")
	stale_request.path_grid_points[-1]=Vector2i(81,0)
	var missing_exit:Dictionary=PLANNER.build_hex_plan([stale_request],stale.build_planning_snapshot(),terrain)
	_check(missing_exit.accepted_steps.is_empty() and missing_exit.blocked[0].reason=="illegal_corridor_exit","missing or nonadjacent tail cell cannot prove a free exit")
	stale_request.path_grid_points=path.duplicate()
	stale_request.duration_ticks_by_step=durations.duplicate()
	stale_request.path_grid_points[70]=Vector2i(79,0)
	var jump:Dictionary=PLANNER.build_hex_plan([stale_request],stale.build_planning_snapshot(),terrain)
	_check(jump.accepted_steps.is_empty() and jump.blocked[0].reason=="illegal_corridor_path","nonadjacent late path jump inside the component cannot prove a route")
	terrain.get_tile_at_grid(Vector2i(80,0)).walkable=true
	terrain.notify_tile_data_changed([Vector2i(80,0)])
	# Unrelated unfinished component must not make a warm query look unresolved.
	for x in range(80):terrain.register_tile(TILE.new({"tile_id":"other%d"%x,"grid_position":Vector2i(x,10)}))
	terrain.get_hex_corridor_topology([Vector2i.ZERO],64)
	terrain.get_hex_corridor_topology([Vector2i.ZERO],64)
	var older:Dictionary=terrain.get_hex_corridor_topology([Vector2i(0,10)],1)
	var current:Dictionary=terrain.get_hex_corridor_topology([Vector2i.ZERO],0)
	_check(not older.complete and not current.complete and current.query_complete,"unrelated pending job cannot block already resolved requested cells")
	var door=REGISTRY.new()
	door.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	door.register_tile(TILE.new({"tile_id":"floor","grid_position":Vector2i.ZERO,"explicit_hex_ramps":true}))
	door.register_tile(TILE.new({"tile_id":"door","grid_position":Vector2i.RIGHT,"explicit_hex_ramps":true,"walkable":false}))
	door.set_runtime_tile_overrides([{"grid_position":Vector2i.RIGHT,"walkable_override":true}])
	var fallback=FallbackRegistry.new()
	fallback.source=door
	var a:Dictionary=CACHE.new().query(door,[Vector2i.ZERO])
	var b:Dictionary=CACHE.new().query(fallback,[Vector2i.ZERO])
	_check(a.corridors==b.corridors and a.corridors[0].cells.size()==2,"real API and fallback agree on runtime-open door components")
	fallback.free()
	door.free()
	terrain.free()
	_finish()
func _finish()->void:
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0:print("HEX_CORRIDOR_INTEGRATION_PASS")
	quit(0 if failed==0 else 1)
