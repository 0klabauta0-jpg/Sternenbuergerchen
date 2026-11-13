extends "res://scripts/tests/hex_ground_lifecycle_verifier.gd"
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const ACTOR = preload("res://scripts/npc/test_unit.gd")
const SCENARIO = preload("res://scripts/mission/mission_scenario_data.gd")
class QuietSetup extends "res://scripts/tests/mission_test_setup.gd":
	func _ready() -> void: set_process(false)
func _run() -> void:
	if not GUARD.require_isolated_user_data(): return
	var rig := _admission_rig([Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0),Vector2i(3,0),Vector2i(3,1),Vector2i(2,1)])
	rig.sim.set_physics_process(false)
	var setup := QuietSetup.new(); rig.scene.add_child(setup)
	setup.simulation_root_path=setup.get_path_to(rig.sim)
	setup.team_id="blue"
	setup._hex_setup_required=true
	var alpha := Marker2D.new(); alpha.name="Alpha"; setup.add_child(alpha)
	setup.spawn_alpha_path=NodePath("Alpha")
	alpha.global_position=rig.terrain.grid_to_world(Vector2i.ZERO)
	setup._mission_scenario=SCENARIO.new({"enemy_groups":[{"enemy_ids":["enemy_a","enemy_b"],"spawn_position":rig.terrain.grid_to_world(Vector2i(3,0))}]})
	var actors:Array=[]
	for id in ["friendly","enemy_a","enemy_b"]:
		var actor:=ACTOR.new(); actor.unit_id=id; actor.team_id="blue" if id=="friendly" else "red"
		rig.scene.add_child(actor); rig.units.register_unit(id,actor); rig.sim.register_known_unit(id,actor)
		actor.global_position=rig.terrain.grid_to_world(Vector2i(1,0) if id=="friendly" else Vector2i(8,8))
		actors.append(actor)
	var before:Vector2=actors[1].global_position
	_check(setup._hex_setup_spawn_grid(actors[0],rig.terrain).grid==Vector2i(1,0),"legal requested formation offset is preserved")
	_check(setup._hex_setup_spawn_grid(actors[1],rig.terrain).grid==Vector2i(3,0) and actors[1].global_position==before,"wall-crossing pixel offset resolves only to its declared group anchor without moving the actor")
	setup._admit_hex_setup_nodes(actors)
	_check(setup.get_hex_setup_status().pending_count==0 and rig.sim.get_hex_ground_planning_snapshot().occupant_by_grid.size()==3,"actual Setup atomically admits friend and two colliding enemy formation candidates")
	_check(rig.sim.get_hex_unit_state("friendly").get("grid",Vector2i(-1,-1))==Vector2i(1,0),"correcting an enemy offset leaves valid friendly spawn unchanged")
	_check(not rig.sim.get_hex_unit_state("enemy_a").is_empty() and rig.sim.get_hex_unit_state("enemy_a").get("grid")!=rig.sim.get_hex_unit_state("enemy_b").get("grid"),"existing Root admission assigns distinct reachable group cells")
	var stamp:Dictionary=rig.sim.get_hex_ground_planning_snapshot()
	alpha.global_position=rig.terrain.grid_to_world(Vector2i(9,9))
	_check(setup._hex_setup_spawn_grid(actors[0],rig.terrain).get("reason")=="invalid_setup_spawn_anchor" and rig.sim.get_hex_ground_planning_snapshot()==stamp,"invalid authored anchor fails even when its offset is legal and never changes Ground")
	rig.scene.free()
	await process_frame
	print("REVIEW_COMPLETION_SPAWN passed=%d failed=%d" % [passed,failed])
	quit(1 if failed else 0)
