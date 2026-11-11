extends "res://scripts/tests/hex_movement_verifier.gd"

func _finish()->void:
	if failed==0:
		_test_swap_with_backoff()
		_test_clearance_before_far_goal()
		_test_staggered_navigation_budget()
		_test_invalidated_backoff_target()
		_test_removed_clearance_cell()
		_test_hold_during_backoff()
		_test_missing_passing_space()
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0:print("HEX_BACKOFF_EXECUTION_PASS")
	quit(0 if failed==0 else 1)

func _test_swap_with_backoff()->void:
	var rig:Dictionary=_backoff_rig(true)
	var sim=rig.sim
	var saw_recovery:=false
	var lower_yielded:=false
	var exclusive:=true
	var original_goals:=true
	var kept_wait_age:=true
	var early_arrival:=false
	var bounded:=true
	for i in range(128):
		sim._physics_process(0.1)
		var snapshot:Dictionary=sim.get_hex_ground_planning_snapshot()
		exclusive=exclusive and snapshot.units_by_id.a.grid!=snapshot.units_by_id.b.grid and snapshot.occupant_by_grid.size()==2
		for id in ["a","b"]:
			var readout:Dictionary=sim.get_hex_movement_readout(id)
			if not String(readout.get("recovery_phase","")).is_empty():
				saw_recovery=true
				lower_yielded=lower_yielded or id=="b"
				kept_wait_age=kept_wait_age and readout.wait_ticks>0
				if sim.has_hex_destination_arrived(id,"move_"+id):early_arrival=true
			original_goals=original_goals and readout.goal_grid==(Vector2i.RIGHT if id=="a" else Vector2i.ZERO) and rig.actors[id].get_current_unit_command().target_position==rig.terrain.grid_to_world(readout.goal_grid)
		var audit:Dictionary=sim.get_hex_movement_audit_snapshot()
		bounded=bounded and int(audit.get("backoff_routes_started",0))<=1 and int(audit.get("backoff_examined_cells",0))<=64 and audit.plan_calls<=1 and audit.reservation_requests<=16
		if sim.has_hex_destination_arrived("a","move_a") and sim.has_hex_destination_arrived("b","move_b"):break
	_check(saw_recovery and lower_yielded,"lower-priority active mover actually follows a planner-proposed passing route")
	_check(exclusive and original_goals and not early_arrival,"backoff preserves exclusive ground cells, original UnitCommands and original-goal arrival identity")
	_check(kept_wait_age,"temporary backoff movement does not erase the waiting age of the original goal")
	_check(sim.has_hex_destination_arrived("a","move_a") and sim.has_hex_destination_arrived("b","move_b"),"both opposed actual Move commands reach their original goals after passing")
	_check(bounded,"backoff uses at most one new route,64 proposal nodes and one joint planner invocation per tick")
	rig.root.free()

func _test_clearance_before_far_goal()->void:
	var rig:Dictionary=_backoff_rig(true,true)
	var saw_wait:=false
	var side_bay:=false
	var cached_wait:=true
	var resumed_before_far_goal:=false
	for i in range(128):
		rig.sim._physics_process(0.1)
		var readout:Dictionary=rig.sim.get_hex_movement_readout("b")
		if readout.get("recovery_phase","")=="moving":side_bay=side_bay or Vector2i(readout.recovery_goal_grid).y==1
		if readout.get("recovery_phase","")=="waiting_clearance":
			saw_wait=true
			cached_wait=cached_wait and readout.navigation_jobs==1
		if saw_wait and readout.get("recovery_phase","")=="" and not rig.sim.has_hex_destination_arrived("a","move_a"):resumed_before_far_goal=true
		if rig.sim.has_hex_destination_arrived("a","move_a") and rig.sim.has_hex_destination_arrived("b","move_b"):break
	_check(side_bay and rig.sim.get_hex_movement_readout("a").navigation_jobs==1,"passing bay stays off the immediate oncoming route and does not force a new route for that mover")
	_check(saw_wait and cached_wait,"stationary clearance waiting consumes no new navigation query")
	_check(resumed_before_far_goal and rig.sim.has_hex_destination_arrived("a","move_a") and rig.sim.has_hex_destination_arrived("b","move_b"),"yielding unit resumes after actual passage rather than waiting for unrelated far-goal completion")
	rig.root.free()

func _test_hold_during_backoff()->void:
	var rig:Dictionary=_backoff_rig(true)
	var sim=rig.sim
	for i in range(4):
		sim._physics_process(0.1)
		if sim.get_hex_movement_readout("b").get("recovery_phase","")=="moving" and sim.get_hex_unit_state("b").route_state.has_commitments:break
	sim.enqueue_command({"type":"hold_position","unit_id":"b","team_id":"blue","command_token":"hold_recovery"})
	sim._physics_process(0.1)
	var held:Vector2i=sim.get_hex_unit_state("b").grid
	for i in range(24):sim._physics_process(0.1)
	_check(sim.get_hex_unit_state("b").grid==held and sim.get_hex_movement_readout("b").status=="canceled" and sim.get_hex_movement_readout("b").get("recovery_phase","")=="" and not sim.has_hex_destination_arrived("b","move_b"),"actual Hold during recovery clears temporary intent and never resumes its original Move")
	rig.root.free()

func _test_staggered_navigation_budget()->void:
	var rig:Dictionary=_backoff_rig(true)
	rig.sim.set_navigation_max_new_path_queries_per_tick(1)
	var bounded:=true
	for i in range(128):
		rig.sim._physics_process(0.1)
		bounded=bounded and rig.sim.get_hex_movement_audit_snapshot().navigation_slices<=1
		if rig.sim.has_hex_destination_arrived("a","move_a") and rig.sim.has_hex_destination_arrived("b","move_b"):break
	_check(bounded and rig.sim.has_hex_destination_arrived("a","move_a") and rig.sim.has_hex_destination_arrived("b","move_b"),"different navigation-admission ticks still cooperate without increasing the one-query budget")
	rig.root.free()

func _test_invalidated_backoff_target()->void:
	var rig:Dictionary=_backoff_rig(true)
	rig.sim._physics_process(0.1)
	var readout:Dictionary=rig.sim.get_hex_movement_readout("b")
	if readout.get("recovery_goal_grid",null)==null:
		_check(false,"actual backoff proposal exists before target invalidation")
		rig.root.free()
		return
	var invalidated:Vector2i=readout.recovery_goal_grid
	rig.terrain.set_runtime_tile_overrides([{"grid_position":invalidated,"walkable_override":false}])
	var legal:=true
	for i in range(128):
		rig.sim._physics_process(0.1)
		legal=legal and rig.sim.get_hex_unit_state("b").grid!=invalidated
		if rig.sim.has_hex_destination_arrived("a","move_a") and rig.sim.has_hex_destination_arrived("b","move_b"):break
	_check(legal and rig.sim.has_hex_destination_arrived("a","move_a") and rig.sim.has_hex_destination_arrived("b","move_b"),"invalidated temporary bay never traps a private goal or admits an illegal step; original orders recover")
	rig.root.free()

func _test_missing_passing_space()->void:
	var rig:Dictionary=_backoff_rig(false)
	for i in range(12):rig.sim._physics_process(0.1)
	_check(rig.sim.get_hex_unit_state("a").grid==Vector2i.ZERO and rig.sim.get_hex_unit_state("b").grid==Vector2i.RIGHT and rig.sim.get_hex_movement_readout("b").get("recovery_phase","")=="" and not rig.sim.has_hex_destination_arrived("a","move_a"),"no passing space keeps both units pending instead of inventing an illegal retreat")
	rig.root.free()

func _test_removed_clearance_cell()->void:
	var rig:Dictionary=_backoff_rig(true,true)
	var ready:=false
	for i in range(64):
		rig.sim._physics_process(0.1)
		if rig.sim.get_hex_movement_readout("b").get("recovery_phase","")=="waiting_clearance" and rig.sim.get_hex_unit_state("a").grid==Vector2i(2,0):ready=true;break
	if not ready:
		_check(false,"clearance fixture reaches post-handoff waiting before deleting a vacated cell")
		rig.root.free()
		return
	var tiles:Array=rig.terrain.get_all_tiles()
	rig.terrain.clear_tiles()
	for tile in tiles:
		if tile.grid_position!=Vector2i.RIGHT:rig.terrain.register_tile(tile)
	for i in range(128):
		rig.sim._physics_process(0.1)
		if rig.sim.has_hex_destination_arrived("a","move_a") and rig.sim.has_hex_destination_arrived("b","move_b"):break
	_check(rig.sim.has_hex_destination_arrived("a","move_a") and rig.sim.has_hex_destination_arrived("b","move_b") and rig.sim.get_hex_movement_readout("b").get("recovery_phase","")=="","removing a vacated clearance cell invalidates the private wait instead of orphaning the original order")
	rig.root.free()

func _backoff_rig(passing_room:bool,far_goal:bool=false)->Dictionary:
	var fixture=Node.new()
	root.add_child(fixture)
	var terrain=REGISTRY.new()
	terrain.name="Terrain"
	fixture.add_child(terrain)
	terrain.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	for x in range(6 if passing_room else 2):
		for y in range(2 if passing_room else 1):terrain.register_tile(TILE.new({"tile_id":"%d_%d"%[x,y],"grid_position":Vector2i(x,y)}))
	var units=UNITS.new()
	units.name="Units"
	fixture.add_child(units)
	var sim=SIM.new()
	sim.unit_registry_path=NodePath("../Units")
	sim.terrain_registry_path=NodePath("../Terrain")
	fixture.add_child(sim)
	var map=MAP.create_empty("backoff",Vector2i(6,2),Vector2.ZERO,64,32,3,"hex_axial_v1")
	map.set_tactical_grid_rules("hex_tactical_v1")
	sim.configure_hex_ground_runtime(map,terrain)
	var actors:Dictionary={}
	for id in ["a","b"]:
		var actor=Actor.new()
		actor.unit_id=id
		fixture.add_child(actor)
		units.register_unit(id,actor)
		sim.register_known_unit(id,actor)
		actors[id]=actor
	var placements:Array[Dictionary]=[{"unit_id":"a","grid":Vector2i.ZERO},{"unit_id":"b","grid":Vector2i.RIGHT}]
	sim.admit_hex_ground_units(placements)
	for id in ["a","b"]:
		var goal:Vector2i=(Vector2i(5,0) if far_goal else Vector2i.RIGHT) if id=="a" else Vector2i.ZERO
		var command:Dictionary=_command(id,terrain.grid_to_world(goal))
		command.priority=5 if id=="a" else 0
		sim.enqueue_command(command)
	if far_goal:actors.a.profile_speed=0.5
	return {"root":fixture,"sim":sim,"terrain":terrain,"actors":actors}
