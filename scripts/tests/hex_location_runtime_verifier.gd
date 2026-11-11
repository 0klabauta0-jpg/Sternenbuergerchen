extends SceneTree
const SIM=preload("res://scripts/core/simulation_root.gd")
const MAP=preload("res://scripts/terrain/terrain_map_data.gd")
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
func _run()->void:
	var owners:Array=[]
	var terrains:Array=[]
	for id in ["a","b"]:
		var sim=SIM.new()
		root.add_child(sim)
		sim.unit_minimum_spacing_enabled=false
		var terrain=REGISTRY.new()
		terrain.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
		for x in range(2):terrain.register_tile(TILE.new({"tile_id":"%s_%d"%[id,x],"grid_position":Vector2i(x,0)}))
		var map=MAP.create_empty("location_"+id,Vector2i(2,1),Vector2.ZERO,64,32,3,"hex_axial_v1")
		map.set_tactical_grid_rules("hex_tactical_v1")
		_check(sim.configure_hex_ground_runtime(map,terrain).ok,"independent nonregional location configures: "+id)
		var batch:Array[Dictionary]=[{"unit_id":id,"grid":Vector2i.ZERO}]
		sim.admit_hex_ground_units(batch)
		var request:Dictionary={"unit_id":id,"command_id":"move_"+id,"priority":0,"path_grid_points":[Vector2i.ZERO,Vector2i.RIGHT],"duration_ticks_by_step":[8]}
		var plan:Dictionary=PLANNER.build_hex_plan([request],sim.get_hex_ground_planning_snapshot(),terrain)
		_check(sim.commit_hex_ground_plan(plan,int(plan.expected_revision)).ok,"location commits its own route: "+id)
		owners.append(sim)
		terrains.append(terrain)
	var a=owners[0]
	var b=owners[1]
	_check(a.get_hex_unit_state("b").is_empty() and b.get_hex_unit_state("a").is_empty(),"same hex coordinates do not merge location occupancy or IDs")
	a._physics_process(0.0)
	b._physics_process(0.0)
	var before_a:Dictionary=a.get_hex_ground_planning_snapshot()
	var before_b:Dictionary=b.get_hex_ground_planning_snapshot()
	# This only verifies the read boundary, not MetaLayerFlow's eventual UI wiring.
	var selected=a
	selected.get_hex_motion_projection("a",0.25,0.5)
	selected=b
	selected.get_hex_motion_projection("b",0.75,0.75)
	selected=a
	selected.get_hex_motion_projection("a",0.5,0.5)
	_check(a.get_hex_ground_planning_snapshot()==before_a and b.get_hex_ground_planning_snapshot()==before_b,"changing which runtime is read resets no committed route IDs or reservations")
	a.stop_hex_ground_units(PackedStringArray(["a"]),"new_order")
	_check(b.get_hex_ground_planning_snapshot()==before_b and b.get_hex_unit_state("b").movement_state.moving,"explicit stop is scoped to its own location")
	for i in range(3):
		a._physics_process(0.0)
		b._physics_process(0.0)
	_check(a.get_hex_unit_state("a").grid==Vector2i.ZERO and b.get_hex_unit_state("b").grid==Vector2i.RIGHT and b.tick_counter==4,"unselected location still reaches its field handoff on its own tick")
	var retained_b:Dictionary=b.get_hex_ground_planning_snapshot()
	var legacy=MAP.create_empty("end_a",Vector2i(2,1),Vector2.ZERO,64,32,3,"hex_axial_v1")
	a.configure_hex_ground_runtime(legacy,terrains[0])
	_check(not a.is_hex_ground_runtime_active() and b.get_hex_ground_planning_snapshot()==retained_b,"explicit location teardown cannot clear another owner")
	for sim in owners:sim.free()
	for terrain in terrains:terrain.free()
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0:print("HEX_LOCATION_RUNTIME_PASS")
	quit(0 if failed==0 else 1)
