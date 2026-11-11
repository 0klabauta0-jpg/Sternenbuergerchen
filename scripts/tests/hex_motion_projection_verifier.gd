extends SceneTree
const GROUND=preload("res://scripts/core/hex_ground_runtime.gd")
const REGISTRY=preload("res://scripts/terrain/terrain_registry.gd")
const TILE=preload("res://scripts/terrain/terrain_tile_data.gd")
const PLANNER=preload("res://scripts/tactical/bottleneck_reservation_resolver.gd")
const HEX=preload("res://scripts/terrain/hex_grid.gd")
var passed:=0
var failed:=0
func _init()->void:call_deferred("_run")
func _check(value:bool,label:String)->void:
	if value:passed+=1
	else:failed+=1
	print("PASS: " if value else "FAIL: ",label)
func _run()->void:
	var state=GROUND.new()
	_check(state.has_method("get_motion_projection"),"ground exposes read-only continuous motion projection")
	if failed>0:
		_finish()
		return
	for direction in range(6):
		var terrain=REGISTRY.new()
		terrain.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
		var axis:Vector2i=HEX.DIRECTIONS[direction]
		for data in [{"tile_id":"low","grid_position":-axis,"height_level":2},
			{"tile_id":"ramp","grid_position":Vector2i.ZERO,"height_level":2,"ramp_direction":direction},
			{"tile_id":"high","grid_position":axis,"height_level":3}]:
			data.explicit_hex_ramps=true
			terrain.register_tile(TILE.new(data))
		if direction==0:
			terrain.get_tile_at_grid(Vector2i.ZERO).walkable=false
			terrain.notify_tile_data_changed([Vector2i.ZERO])
			terrain.set_runtime_tile_overrides([{"grid_position":Vector2i.ZERO,"walkable_override":true}])
		state.configure(terrain,"projection_%d"%direction,0)
		var batch:Array[Dictionary]=[{"unit_id":"a","grid":-axis,"facing_dir":direction}]
		state.admit_units(batch)
		var request:Dictionary={"unit_id":"a","command_id":"move","priority":0,"path_grid_points":[-axis,Vector2i.ZERO,axis],"duration_ticks_by_step":[4,4]}
		var plan:Dictionary=PLANNER.build_hex_plan([request],state.build_planning_snapshot(),terrain)
		_check(state.commit_plan(plan,int(plan.expected_revision)).ok,"projection fixture commits canonical ramp route %d"%direction)
		var before:Dictionary=state.build_planning_snapshot()
		var quarter:Dictionary=state.get_motion_projection("a",0.5,0.75)
		_check(quarter.position_world.is_equal_approx(terrain.grid_to_world(-axis).lerp(terrain.grid_to_world(Vector2i.ZERO),0.125)) and is_equal_approx(quarter.stand_height_world,1.5) and state.build_planning_snapshot()==before,"fractional frame moves visual only and keeps low plateau flat %d"%direction)
		state.advance_tick(2)
		var midpoint:Dictionary=state.get_motion_projection("a",0.0,0.75)
		_check(state.read_unit("a").grid==Vector2i.ZERO and midpoint.position_world.is_equal_approx(terrain.grid_to_world(-axis).lerp(terrain.grid_to_world(Vector2i.ZERO),0.5)) and is_equal_approx(midpoint.stand_height_world,1.5),"logical handoff occurs at shared edge without a height jump %d"%direction)
		state.advance_tick(3)
		_check(is_equal_approx(state.get_motion_projection("a",0.0,0.75).stand_height_world,2.25*0.75),"height rises only within ramp half %d"%direction)
		state.advance_tick(4)
		var seam:Dictionary=state.get_motion_projection("a",0.0,0.75)
		_check(seam.moving and seam.position_world.is_equal_approx(terrain.grid_to_world(Vector2i.ZERO)) and is_equal_approx(seam.stand_height_world,2.5*0.75),"consecutive segments meet continuously at ramp center %d"%direction)
		state.advance_tick(6)
		_check(is_equal_approx(state.get_motion_projection("a",0.0,0.75).stand_height_world,3.0*0.75),"upper shared edge reaches plateau height %d"%direction)
		state.advance_tick(8)
		var final:Dictionary=state.get_motion_projection("a",0.75,0.75)
		_check(not final.moving and final.position_world.is_equal_approx(terrain.grid_to_world(axis)) and is_equal_approx(final.stand_height_world,2.25),"finished movement stays at committed destination %d"%direction)
		_check(state.get_motion_projection("missing",0.0).is_empty() and state.get_motion_projection("a",NAN,0.75).is_empty(),"missing unit and nonfinite frame input cannot create projection %d"%direction)
		state.configure(terrain,"down_%d"%direction,0)
		batch=[{"unit_id":"a","grid":axis,"facing_dir":(direction+3)%6}]
		state.admit_units(batch)
		request.path_grid_points=[axis,Vector2i.ZERO,-axis]
		plan=PLANNER.build_hex_plan([request],state.build_planning_snapshot(),terrain)
		var accepted:bool=state.commit_plan(plan,int(plan.expected_revision)).ok
		state.advance_tick(1)
		var flat:float=state.get_motion_projection("a",0.0,0.75).stand_height_world
		state.advance_tick(4)
		var center:float=state.get_motion_projection("a",0.0,0.75).stand_height_world
		state.advance_tick(6)
		var lower:float=state.get_motion_projection("a",0.0,0.75).stand_height_world
		_check(accepted and is_equal_approx(flat,2.25) and is_equal_approx(center,1.875) and is_equal_approx(lower,1.5),"descending route keeps upper plateau flat and shares exact lower edge %d"%direction)
		terrain.free()
	var band=REGISTRY.new()
	band.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	band.register_tile(TILE.new({"tile_id":"a","grid_position":Vector2i.ZERO,"height_level":2,"ramp_direction":0,"explicit_hex_ramps":true}))
	band.register_tile(TILE.new({"tile_id":"b","grid_position":Vector2i(0,1),"height_level":2,"ramp_direction":1,"explicit_hex_ramps":true}))
	state.configure(band,"turned_band",0)
	var placed:Array[Dictionary]=[{"unit_id":"a","grid":Vector2i.ZERO}]
	state.admit_units(placed)
	var turn:Dictionary=PLANNER.build_hex_plan([{"unit_id":"a","command_id":"turn","priority":0,"path_grid_points":[Vector2i.ZERO,Vector2i(0,1)],"duration_ticks_by_step":[4]}],state.build_planning_snapshot(),band)
	var turn_ok:bool=state.commit_plan(turn,int(turn.expected_revision)).ok
	state.advance_tick(2)
	_check(turn_ok and is_equal_approx(state.get_motion_projection("a",0.5,0.75).stand_height_world,1.875),"turned matching ramp band uses shared half-height seam")
	band.free()
	_finish()
func _finish()->void:
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0:print("HEX_MOTION_PROJECTION_PASS")
	quit(0 if failed==0 else 1)
