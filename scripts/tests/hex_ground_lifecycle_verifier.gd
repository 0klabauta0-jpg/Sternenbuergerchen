extends "res://scripts/tests/hex_movement_verifier.gd"

const ADMISSION_PATH="res://scripts/mission/hex_ground_admission.gd"

func _finish()->void:
	var probe=SIM.new()
	_check(ResourceLoader.exists(ADMISSION_PATH) and probe.has_method("admit_hex_ground_actor_group"),"actual Root exposes atomic actor group admission")
	probe.free()
	if failed==0:
		_test_group_admission()
		_test_admission_ramps()
		_test_active_edge_admission()
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0:print("HEX_GROUND_LIFECYCLE_PASS")
	quit(0 if failed==0 else 1)

func _admission_rig(cells:Array)->Dictionary:
	var scene=Node.new()
	root.add_child(scene)
	var terrain=REGISTRY.new()
	terrain.name="Terrain"
	scene.add_child(terrain)
	terrain.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	for value in cells:
		var data:Dictionary=value.duplicate() if value is Dictionary else {"grid_position":value}
		data.tile_id=str(data.grid_position)
		data.explicit_hex_ramps=true
		terrain.register_tile(TILE.new(data))
	var units=UNITS.new()
	units.name="Units"
	scene.add_child(units)
	var sim=SIM.new()
	scene.add_child(sim)
	sim.unit_registry_path=sim.get_path_to(units)
	sim.terrain_registry_path=sim.get_path_to(terrain)
	var map=MAP.create_empty("admission",Vector2i(4,3),Vector2.ZERO,64,32,3,"hex_axial_v1")
	map.set_tactical_grid_rules("hex_tactical_v1")
	sim.configure_hex_ground_runtime(map,terrain)
	return {"scene":scene,"terrain":terrain,"units":units,"sim":sim,"map":map,"actors":{}}

func _add_admission_actor(rig:Dictionary,id:String)->Node2D:
	var actor=Actor.new()
	actor.unit_id=id
	rig.scene.add_child(actor)
	rig.units.register_unit(id,actor)
	rig.sim.register_known_unit(id,actor)
	rig.actors[id]=actor
	return actor

func _test_group_admission()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0),Vector2i(3,0)])
	var sim=rig.sim
	var ids:=PackedStringArray(["a","b","c","d"])
	for id in ids:_add_admission_actor(rig,id).set_meta("dropship_embarked",true)
	var helper=load(ADMISSION_PATH).new()
	var before:Dictionary=sim.get_hex_ground_planning_snapshot()
	var planned:Dictionary=helper.plan_group(ids,Vector2i.ZERO,rig.terrain,before)
	_check(planned.ok and planned.placements.size()==4 and sim.get_hex_ground_planning_snapshot()==before,"pure group planner finds four distinct cells without changing owner")
	var admitted:Dictionary=sim.admit_hex_ground_actor_group(ids,Vector2i.ZERO)
	var snapshot:Dictionary=sim.get_hex_ground_planning_snapshot()
	_check(admitted.ok and snapshot.occupant_by_grid.size()==4 and snapshot.units_by_id.size()==4,"actual Root admits complete registered group atomically")
	_check(not rig.actors.a.get_meta("dropship_embarked") and rig.actors.d.visible and rig.actors.d.global_position==rig.terrain.grid_to_world(snapshot.units_by_id.d.grid),"admitted actors publish committed logical placement")
	rig.actors.b.vital_state="down"
	sim._physics_process(0.1)
	_check(not sim.get_hex_unit_state("b").is_empty(),"downed NPC retains its ground field")
	sim.enqueue_command(_command("a",rig.terrain.grid_to_world(Vector2i(3,0))))
	sim._physics_process(0.1)
	var embarked:Dictionary=sim.embark_hex_ground_actor_group(ids)
	_check(embarked.ok and sim.get_hex_ground_planning_snapshot().occupant_by_grid.is_empty() and sim.get_hex_movement_readout("a").is_empty(),"group embark clears cells and accepted movement together")
	_check(rig.units.get_unit("a")==rig.actors.a and rig.actors.a.get_meta("dropship_embarked") and not rig.actors.a.visible,"embark retains real actor identity while removing ground presence")
	sim.admit_hex_ground_actor_group(PackedStringArray(["a"]),Vector2i.ZERO)
	sim.unregister_known_unit("a")
	var removed:Dictionary=sim.get_hex_ground_planning_snapshot()
	sim.unregister_known_unit("a")
	_check(sim.get_hex_unit_state("a").is_empty() and removed==sim.get_hex_ground_planning_snapshot(),"real unregister releases once and repeated remove is a no-op")
	var blocked:Dictionary=before.duplicate(true)
	blocked.occupant_by_grid[Vector2i(3,0)]="foreign"
	var waiting:Dictionary=helper.plan_group(ids,Vector2i.ZERO,rig.terrain,blocked)
	_check(not waiting.ok and waiting.placements.is_empty() and waiting.waiting_unit_ids==ids,"three free fields cannot partially admit four people")
	_check(not helper.plan_group(PackedStringArray(["a","a"]),Vector2i.ZERO,rig.terrain,before).ok,"duplicate group identity is rejected")
	var budget:Dictionary=helper.plan_group(ids,Vector2i.ZERO,rig.terrain,before,3)
	_check(not budget.ok and budget.reason=="admission_budget" and budget.expanded<=3,"group search obeys explicit expansion budget")
	var pure_before:Dictionary=sim.get_hex_ground_planning_snapshot()
	var actor_position:Vector2=rig.actors.b.global_position
	var invalid:Dictionary=sim.admit_hex_ground_actor_group(PackedStringArray(["b","missing"]),Vector2i.ZERO)
	_check(not invalid.ok and sim.get_hex_ground_planning_snapshot()==pure_before and rig.actors.b.global_position==actor_position,"missing actor rejects complete root transaction before writes")
	var fake=Node2D.new()
	rig.scene.add_child(fake)
	rig.units.register_unit("base_projection",fake)
	sim.register_known_unit("base_projection",fake)
	_check(not sim.admit_hex_ground_actor_group(PackedStringArray(["base_projection"]),Vector2i.ZERO).ok,"plain base projection cannot become a mission actor")
	var foreign:Dictionary=_admission_rig([Vector2i.ZERO])
	var foreign_actor:Node2D=_add_admission_actor(foreign,"b")
	_check(not sim.register_known_unit("b",foreign_actor) and sim._resolve_known_unit_for_contract("b")==rig.actors.b,"foreign actor cannot overwrite the owning root lookup")
	foreign.units.register_unit("d",rig.actors.d)
	foreign.sim.register_known_unit("d",rig.actors.d)
	_check(not foreign.sim.admit_hex_ground_actor_group(PackedStringArray(["d"]),Vector2i.ZERO).ok,"foreign root rejects same-ID shared actor outside its mission subtree")
	_check(sim.get_hex_ground_planning_snapshot()==pure_before,"failed foreign admission preserves the other location")
	foreign.scene.free()
	rig.scene.free()

func _test_admission_ramps()->void:
	var rig:Dictionary=_admission_rig([
		{"grid_position":Vector2i.ZERO,"height_level":0},
		{"grid_position":Vector2i(1,0),"height_level":0,"ramp_direction":0},
		{"grid_position":Vector2i(2,0),"height_level":1},
		{"grid_position":Vector2i(0,1),"height_level":1},
		{"grid_position":Vector2i(1,1),"height_level":0,"ramp_direction":0},
		{"grid_position":Vector2i(3,0),"height_level":8}])
	var helper=load(ADMISSION_PATH).new()
	var ids:=PackedStringArray(["r0","r1","r2","r3"])
	var result:Dictionary=helper.plan_group(ids,Vector2i.ZERO,rig.terrain,rig.sim.get_hex_ground_planning_snapshot())
	var cells:Array=[]
	for entry in result.placements:cells.append(entry.grid)
	_check(result.ok and cells.has(Vector2i(1,0)) and cells.has(Vector2i(2,0)) and cells.has(Vector2i(1,1)) and not cells.has(Vector2i(0,1)),"admission follows longitudinal ramp and matching lateral ramp, never plateau cliff")
	rig.terrain.get_tile_at_grid(Vector2i(3,0)).ramp_direction=0
	rig.terrain.notify_tile_data_changed([Vector2i(3,0)])
	_check(not helper.plan_group(PackedStringArray(["bad"]),Vector2i(3,0),rig.terrain,rig.sim.get_hex_ground_planning_snapshot()).ok,"invalid H8 ramp cannot be an admission anchor")
	var snapshot:Dictionary=rig.sim.get_hex_ground_planning_snapshot()
	snapshot.committed_corridor_grants=[{"cells":[Vector2i(1,0),Vector2i(2,0)],"unit_ids":["cohort"]}]
	_check(not helper.plan_group(PackedStringArray(["first","second"]),Vector2i.ZERO,rig.terrain,snapshot).ok,"complete corridor grant blocks admission beyond its immediate promised steps")
	rig.scene.free()

func _test_active_edge_admission()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0)])
	_add_admission_actor(rig,"moving")
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["moving"]),Vector2i.ZERO)
	rig.sim.enqueue_command(_command("moving",rig.terrain.grid_to_world(Vector2i(2,0))))
	var crossed:=false
	for i in range(24):
		rig.sim._physics_process(0.1)
		var state:Dictionary=rig.sim.get_hex_unit_state("moving")
		if state.grid==Vector2i(1,0) and bool(state.movement_state.get("moving",false)):
			crossed=true
			break
	_check(crossed,"edge fixture reaches after-handoff before segment end")
	var before:Dictionary=rig.sim.get_hex_ground_planning_snapshot()
	var direct:Array[Dictionary]=[{"unit_id":"intruder","grid":Vector2i.ZERO}]
	_check(not rig.sim.admit_hex_ground_units(direct).ok and before==rig.sim.get_hex_ground_planning_snapshot(),"admission cannot occupy vacated source while edge is still active")
	var result:Dictionary=load(ADMISSION_PATH).new().plan_group(PackedStringArray(["intruder"]),Vector2i.ZERO,rig.terrain,before)
	_check(not result.ok and result.placements.is_empty(),"group planner cannot enter an active edge from its vacated endpoint")
	rig.scene.free()
