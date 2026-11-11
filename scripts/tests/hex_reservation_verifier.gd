extends SceneTree

const RESOLVER = preload("res://scripts/tactical/bottleneck_reservation_resolver.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print("PASS: " if value else "FAIL: ", label)

func _run() -> void:
	_check(RESOLVER.new().has_method("build_hex_plan"), "static hex planner exists")
	if failed > 0:
		_finish()
		return
	var terrain = REGISTRY.new()
	terrain.configure_iso_grid(Vector2.ZERO,64.0,32.0,"hex_axial_v1")
	for x in range(6):
		for y in range(2):
			terrain.register_tile(TILE.new({"tile_id":"%d_%d"%[x,y], "grid_position":Vector2i(x,y),
				"height_level":0,"explicit_hex_ramps":true,"walkable":true}))
	var resolver = RESOLVER.new()
	var snap := _snapshot(terrain, {"a":Vector2i(0,0),"b":Vector2i(1,0)})
	var requests := [_request("a",[Vector2i(0,0),Vector2i(1,0),Vector2i(2,0)], [2,2]),
		_request("b",[Vector2i(1,0),Vector2i(2,0),Vector2i(3,0)], [4,4])]
	var before := snap.duplicate(true)
	var plan: Dictionary = resolver.call("build_hex_plan",requests,snap,terrain)
	_check(plan.ok and plan.accepted_steps.size()==4,"column retries follower after slower leader has a committed proposal")
	_check(snap==before and requests[0].duration_ticks_by_step==[2,2],"inputs remain unchanged")
	_check(plan.expected_revision==7 and plan.terrain_revision==terrain.get_revision(),"owner and terrain revisions preserved")
	var a_start := -1
	for step in plan.accepted_steps:
		_check(step.handoff_tick==step.start_tick+ceili(step.duration_ticks/2.0),"canonical midpoint handoff")
		if step.unit_id=="a" and step.from_grid==Vector2i(0,0): a_start=step.start_tick
	_check(a_start>=1,"slower leader delays follower")
	var opposite: Dictionary = resolver.call("build_hex_plan",[_request("a",[Vector2i(0,0),Vector2i(1,0)],[2]),
		_request("b",[Vector2i(1,0),Vector2i(0,0)],[2])],snap,terrain)
	_check(opposite.accepted_steps.is_empty() and opposite.pending_requests.size()==2,"head-on swap cannot erase stationary occupants")
	var occupied: Dictionary = resolver.call("build_hex_plan",[requests[0]],snap,terrain)
	_check(occupied.accepted_steps.is_empty(),"occupied exit never becomes a guessed departure")
	var conflict_snapshot := _snapshot(terrain,{"a":Vector2i(0,0),"b":Vector2i(1,0)})
	conflict_snapshot.committed_segments=[_segment("b",Vector2i(1,0),Vector2i(0,0),0,4)]
	var conflict: Dictionary = resolver.call("build_hex_plan",[_request("a",[Vector2i(0,0),Vector2i(1,0)],[4])],conflict_snapshot,terrain)
	_check(conflict.accepted_steps.is_empty(),"opposing committed edge blocks full traversal interval")
	var after_handoff := _snapshot(terrain,{"a":Vector2i(1,0),"b":Vector2i(0,0)})
	after_handoff.current_tick=2
	after_handoff.committed_segments=[_segment("a",Vector2i(0,0),Vector2i(1,0),0,4)]
	# b cannot occupy the source before the first segment handoff: move b aside for a valid snapshot.
	after_handoff.units_by_id.erase("b"); after_handoff.occupant_by_grid.erase(Vector2i(0,0))
	var appended: Dictionary=resolver.call("build_hex_plan",[_request("a",[Vector2i(1,0),Vector2i(2,0)],[2])],after_handoff,terrain)
	_check(appended.ok and appended.accepted_steps.size()==1 and appended.accepted_steps[0].start_tick==4,"post-handoff segment retains old edge until end before next departure")
	var fair_snap := _snapshot(terrain,{"a":Vector2i(0,0),"b":Vector2i(1,1)})
	var high_priority := _request("a",[Vector2i(0,0),Vector2i(1,0)],[2]); high_priority.priority=5
	var old := _request("b",[Vector2i(1,1),Vector2i(1,0)],[2]); old.wait_ticks=6
	var fair: Dictionary = resolver.call("build_hex_plan",[high_priority,old],fair_snap,terrain)
	_check(fair.accepted_steps.size()==1 and fair.accepted_steps[0].unit_id=="b","waiting age can overcome finite command priority")
	var many: Array=[]
	for index in range(18): many.append(_request("missing%d"%index,[Vector2i(0,0),Vector2i(1,0)],[1]))
	var bounded: Dictionary = resolver.call("build_hex_plan",many,snap,terrain)
	_check(bounded.pending_requests.size()==18 and bounded.processed_requests==16,"overflow requests remain intact beyond 16 request budget")
	var long_plan: Dictionary = resolver.call("build_hex_plan",[_request("a",[Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(3,0),Vector2i(4,0)],[1,1,1,1])],_snapshot(terrain,{"a":Vector2i(0,0)}),terrain)
	_check(long_plan.accepted_steps.size()==3 and long_plan.pending_requests.size()==1,"three-transition lookahead retains remaining route")
	var legacy := snap.duplicate(true); legacy.erase("reservation_schema_version")
	var rejected: Dictionary=resolver.call("build_hex_plan",requests,legacy,terrain)
	_check(not rejected.ok and rejected.reason=="snapshot_incompatible" and rejected.pending_requests.size()==2,"AP1 snapshot cannot silently impersonate reservation snapshot")
	var stale := snap.duplicate(true); stale.terrain_revision-=1
	_check(not resolver.call("build_hex_plan",requests,stale,terrain).ok,"stale terrain snapshot rejected")
	# Two longitudinal lanes share legal lateral H+0.5 ramp edges.
	for x in range(3):
		for y in range(2):
			terrain.register_tile(TILE.new({"tile_id":"%d_%d"%[x,y], "grid_position":Vector2i(x,y),
				"height_level":1 if x==2 else 0,"ramp_direction":0 if x==1 else -1,"explicit_hex_ramps":true,"walkable":true}))
	var band: Dictionary=resolver.call("build_hex_plan",[_request("a",[Vector2i(1,0),Vector2i(2,0)],[2]),
		_request("b",[Vector2i(2,1),Vector2i(1,1)],[2])],_snapshot(terrain,{"a":Vector2i(1,0),"b":Vector2i(2,1)}),terrain)
	_check(band.accepted_steps.size()==2,"matching H+0.5 side connections allow parallel ramp traffic")
	_check(opposite.blocked[0].reason=="backoff_required" and opposite.blocked[0].backoff_examined_cells<=64,"legal backoff is a bounded proposal and never an accepted route rewrite")
	var corridor=REGISTRY.new()
	corridor.configure_iso_grid(Vector2.ZERO,64.0,32.0,"hex_axial_v1")
	for x in range(6):
		corridor.register_tile(TILE.new({"tile_id":str(x),"grid_position":Vector2i(x,0),"height_level":0,"explicit_hex_ramps":true,"walkable":true}))
	var exit_snapshot:=_snapshot(corridor,{"a":Vector2i(0,0),"b":Vector2i(5,0)})
	var exit_request:=_request("a",[Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(3,0),Vector2i(4,0),Vector2i(5,0)],[2,2,2,2,2])
	var exit_plan:Dictionary=resolver.call("build_hex_plan",[exit_request],exit_snapshot,corridor)
	_check(exit_plan.accepted_steps.is_empty() and exit_plan.blocked[0].reason=="no_passing_space","occupied corridor exit beyond lookahead stays clear without repeated blind replanning")
	var grant_snapshot:=_snapshot(corridor,{"a":Vector2i(0,0),"b":Vector2i(2,0)})
	grant_snapshot.committed_corridor_grants=[{"cells":[Vector2i(1,0),Vector2i(2,0),Vector2i(3,0)],"unit_ids":["b"]}]
	var grant_plan:Dictionary=resolver.call("build_hex_plan",[_request("a",[Vector2i(0,0),Vector2i(1,0)],[2])],grant_snapshot,corridor)
	_check(grant_plan.accepted_steps.is_empty() and grant_plan.corridor_grants==grant_snapshot.committed_corridor_grants,"live inherited closed corridor group blocks new entrant")
	grant_snapshot.units_by_id.b.grid=Vector2i(4,0); grant_snapshot.occupant_by_grid.erase(Vector2i(2,0)); grant_snapshot.occupant_by_grid[Vector2i(4,0)]="b"
	grant_snapshot.current_tick=2; grant_snapshot.committed_segments=[_segment("b",Vector2i(3,0),Vector2i(4,0),0,4)]
	var edge_grant:Dictionary=resolver.call("build_hex_plan",[_request("a",[Vector2i(0,0),Vector2i(1,0)],[2])],grant_snapshot,corridor)
	_check(edge_grant.accepted_steps.is_empty() and edge_grant.corridor_grants.size()==1,"post-handoff edge keeps inherited corridor group live")
	grant_snapshot.current_tick=4; grant_snapshot.committed_segments=[]
	var cleared_grant:Dictionary=resolver.call("build_hex_plan",[_request("a",[Vector2i(0,0),Vector2i(1,0)],[2])],grant_snapshot,corridor)
	_check(cleared_grant.accepted_steps.size()==1,"corridor group releases only after unit and committed edge clear it")
	var clearing_snapshot:=_snapshot(corridor,{"a":Vector2i(1,0),"b":Vector2i(3,0)})
	clearing_snapshot.committed_corridor_grants=[{"cells":[Vector2i(1,0),Vector2i(2,0),Vector2i(3,0)],"unit_ids":["b"]}]
	var clearing_plan:Dictionary=resolver.call("build_hex_plan",[_request("a",[Vector2i(1,0),Vector2i(0,0)],[2])],clearing_snapshot,corridor)
	_check(clearing_plan.accepted_steps.size()==1 and clearing_plan.corridor_grants[0].unit_ids==["b"],"existing outsider clears corridor endpoint without joining inherited closed group")
	corridor.free()
	terrain.free()
	var rotated_ok:bool=true
	var hex=preload("res://scripts/terrain/hex_grid.gd")
	for direction in range(6):
		var rotated=REGISTRY.new()
		rotated.configure_iso_grid(Vector2.ZERO,64.0,32.0,"hex_axial_v1")
		var high:Vector2i=hex.DIRECTIONS[direction]
		var low:Vector2i=-high
		var corner:Vector2i=hex.DIRECTIONS[(direction+2)%6]
		for spec in [{"grid":Vector2i.ZERO,"height":0,"ramp":direction},
			{"grid":high,"height":1,"ramp":-1},{"grid":low,"height":0,"ramp":-1},
			{"grid":corner,"height":0,"ramp":(direction+1)%6}]:
			rotated.register_tile(TILE.new({"tile_id":str(spec.grid),"grid_position":spec.grid,
				"height_level":spec.height,"ramp_direction":spec.ramp,"explicit_hex_ramps":true,"walkable":true}))
		for route in [[low,Vector2i.ZERO,high],[high,Vector2i.ZERO,low],[Vector2i.ZERO,corner]]:
			var durations:Array=[]
			for unused in range(route.size()-1): durations.append(2)
			var check_plan:Dictionary=resolver.call("build_hex_plan",[_request("a",route,durations)],_snapshot(rotated,{"a":route[0]}),rotated)
			rotated_ok=rotated_ok and check_plan.ok and check_plan.accepted_steps.size()==route.size()-1
		rotated.free()
	_check(rotated_ok,"six rotated ramp axes and matching curved H+0.5 band connections")
	_finish()

func _request(id: String,path:Array,durations:Array) -> Dictionary:
	return {"unit_id":id,"command_id":"move_"+id,"priority":0,"wait_ticks":0,
		"path_grid_points":path,"duration_ticks_by_step":durations}

func _segment(id:String,from:Vector2i,to:Vector2i,start:int,duration:int)->Dictionary:
	return {"unit_id":id,"command_id":"move_"+id,"from_grid":from,"to_grid":to,
		"start_tick":start,"duration_ticks":duration,"handoff_tick":start+ceili(duration/2.0)}

func _snapshot(terrain:Node,positions:Dictionary)->Dictionary:
	var units:Dictionary={}; var occupants:Dictionary={}
	for id in positions:
		units[id]={"unit_id":id,"grid":positions[id]}; occupants[positions[id]]=id
	return {"map_id":"fixture","revision":7,"current_tick":0,"terrain_revision":terrain.get_revision(),
		"units_by_id":units,"occupant_by_grid":occupants,"reservation_schema_version":1,"committed_segments":[],"committed_corridor_grants":[]}

func _finish() -> void:
	print("HEX_RESERVATION_PASS" if failed == 0 else "HEX_RESERVATION_FAIL", " ", passed, "/", failed)
	quit(0 if failed == 0 else 1)
