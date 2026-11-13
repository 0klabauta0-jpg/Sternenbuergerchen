extends SceneTree
const SIM=preload("res://scripts/core/simulation_root.gd")
const MAP=preload("res://scripts/terrain/terrain_map_data.gd")
const REGISTRY=preload("res://scripts/terrain/terrain_registry.gd")
const UNITS=preload("res://scripts/registries/unit_registry.gd")
const TILE=preload("res://scripts/terrain/terrain_tile_data.gd")
const COMMAND=preload("res://scripts/npc/unit_command.gd")
const OBJECTIVE=preload("res://scripts/core/objective_status.gd")
const HEX=preload("res://scripts/terrain/hex_grid.gd")
var passed:=0
var failed:=0
class Actor extends Node2D:
	var unit_id:String
	var current_command:RefCounted
	var target_position:Vector2
	var vital_state:="fit"
	var profile_speed:=1.0
	var readability_refreshes:=0
	var health:=100
	func get_unit_id():return unit_id
	func get_team_id():return "blue"
	func get_vital_state():return vital_state
	func get_current_unit_command():return current_command
	func assign_unit_command(value):current_command=value
	func set_target_position(value):target_position=value
	func get_target_position():return target_position
	func get_move_speed_factor():return 1.0
	func get_combat_speed_multiplier():return profile_speed
	func refresh_terrain_readability():readability_refreshes+=1
	func get_health():return health
	func apply_damage(amount:int,_context:Dictionary={}):
		health=maxi(0,health-amount)
		if health==0:vital_state="down"
		return true
func _init()->void:call_deferred("_run")
func _check(value:bool,label:String)->void:
	if value:passed+=1
	else:failed+=1
	print("PASS: " if value else "FAIL: ",label)
func _command(id:String,target:Vector2,speed:float=1.0)->Dictionary:
	return {"type":"move_to_position","unit_id":id,"team_id":"blue","target_position":target,"move_speed_factor":speed,"command_token":"move_"+id,"requeue_until_target":true}
func _run()->void:
	var sim=SIM.new()
	root.add_child(sim)
	_check(sim.has_method("has_hex_destination_arrived") and sim.has_method("get_hex_movement_readout"),"real Root exposes actual hex movement and arrival contract")
	if failed>0:
		sim.free()
		_finish()
		return
	var terrain=REGISTRY.new()
	terrain.name="MovementTerrain"
	root.add_child(terrain)
	terrain.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	for x in range(6):
		for y in range(2):terrain.register_tile(TILE.new({"tile_id":"%d_%d"%[x,y],"grid_position":Vector2i(x,y)}))
	var registry=UNITS.new()
	registry.name="MovementUnits"
	root.add_child(registry)
	sim.unit_registry_path=sim.get_path_to(registry)
	sim.terrain_registry_path=sim.get_path_to(terrain)
	sim.local_avoidance_enabled=true
	sim.unit_minimum_spacing_enabled=true
	sim.bottleneck_reservation_enabled=true
	var map=MAP.create_empty("actual_movement",Vector2i(6,2),Vector2.ZERO,64,32,3,"hex_axial_v1")
	map.set_tactical_grid_rules("hex_tactical_v1")
	sim.configure_hex_ground_runtime(map,terrain)
	var actors:Dictionary={}
	for record in [{"id":"a","grid":Vector2i.ZERO},{"id":"b","grid":Vector2i(1,0)},{"id":"unadmitted","grid":Vector2i(5,1)}]:
		var actor=Actor.new()
		actor.unit_id=record.id
		root.add_child(actor)
		actor.global_position=terrain.grid_to_world(record.grid)
		registry.register_unit(record.id,actor)
		sim.register_known_unit(record.id,actor)
		actors[record.id]=actor
	var batch:Array[Dictionary]=[{"unit_id":"a","grid":Vector2i.ZERO},{"unit_id":"b","grid":Vector2i(1,0)}]
	sim.admit_hex_ground_units(batch)
	sim.enqueue_command(_command("a",terrain.grid_to_world(Vector2i(3,0))))
	sim.enqueue_command(_command("b",terrain.grid_to_world(Vector2i(5,0)),0.5))
	var missing_origin:Vector2=actors.unadmitted.global_position
	sim.enqueue_command(_command("unadmitted",terrain.grid_to_world(Vector2i(4,1))))
	sim._physics_process(0.25)
	_check(not sim.get_hex_ground_planning_snapshot().committed_segments.is_empty(),"actual queued commands commit hex segments instead of free movement")
	_check(actors.unadmitted.global_position==missing_origin and sim.get_hex_unit_state("unadmitted").is_empty(),"unadmitted actor never falls back to legacy movement")
	var render_snapshot:Dictionary=sim.get_hex_ground_planning_snapshot()
	var rng_before:int=sim._combat_rng.state
	sim._project_hex_ground_actors(0.5)
	_check(actors.b.global_position.is_equal_approx(sim.get_hex_motion_projection("b",0.5).position_world) and sim.get_hex_ground_planning_snapshot()==render_snapshot and sim._combat_rng.state==rng_before,"fractional actor projection changes neither gameplay state nor combat RNG")
	sim._project_hex_ground_actors(0.0)
	var ghost_objective=OBJECTIVE.new()
	ghost_objective.position=missing_origin
	ghost_objective.capture_radius=0.0
	_check(sim._get_objective_team_ids_in_radius(ghost_objective).is_empty(),"unadmitted presentation actor cannot capture a hex objective")
	if actors.a.get_current_unit_command()==null:
		_check(false,"hex type alias must commit the actual UnitCommand before moving")
		for actor in actors.values():actor.free()
		sim.free()
		registry.free()
		terrain.free()
		_finish()
		return
	var accepted_command:Dictionary=actors.a.get_current_unit_command().to_dict()
	var invalid:Dictionary=_command("a",Vector2(NAN,0))
	invalid.command_token="invalid_a"
	sim.enqueue_command(invalid)
	sim._physics_process(0.25)
	_check(actors.a.get_current_unit_command().command_token==accepted_command.command_token and actors.a.get_current_unit_command().target_position==accepted_command.target_position and sim.get_hex_movement_readout("a").source_command_id=="move_a","rejected nonfinite target cannot replace the accepted actor command or token")
	var exclusive:=true
	var projected:=true
	var early_arrival:=false
	var warmed_timing:=true
	var objective_checked:=false
	var budget_bounded:=true
	for tick in range(128):
		var snapshot:Dictionary=sim.get_hex_ground_planning_snapshot()
		var audit:Dictionary=sim.get_hex_movement_audit_snapshot()
		budget_bounded=budget_bounded and audit.navigation_slices<=4 and audit.navigation_expansions<=96 and audit.reservation_requests<=16 and audit.accepted_steps<=48
		if audit.navigation_jobs_created==0 and audit.timing_edge_reads>0:warmed_timing=false
		if not objective_checked and snapshot.units_by_id.b.grid!=Vector2i(1,0) and snapshot.units_by_id.b.movement_state.moving:
			var objective=OBJECTIVE.new()
			objective.position=terrain.grid_to_world(snapshot.units_by_id.b.grid)
			objective.capture_radius=0.0
			_check(sim._get_objective_team_ids_in_radius(objective).has("blue"),"objective capture reads committed hex at handoff instead of render position")
			objective_checked=true
		exclusive=exclusive and snapshot.occupant_by_grid.size()==2 and snapshot.units_by_id.a.grid!=snapshot.units_by_id.b.grid
		for id in ["a","b"]:
			projected=projected and actors[id].global_position.is_equal_approx(sim.get_hex_motion_projection(id,0.0).position_world)
			if sim.get_hex_unit_state(id).movement_state.moving and sim.has_hex_destination_arrived(id,"move_"+id):early_arrival=true
		if sim.has_hex_destination_arrived("a","move_a") and sim.has_hex_destination_arrived("b","move_b"):break
		sim._physics_process(0.25)
	_check(exclusive,"logical fields remain exclusive throughout a faster follower and slower leader")
	_check(projected,"actor positions always follow the owner despite enabled legacy avoidance and spacing")
	_check(not early_arrival,"handoff to destination is not premature arrival before edge completion")
	_check(sim.has_hex_destination_arrived("a","move_a") and sim.has_hex_destination_arrived("b","move_b"),"both real commands finish at their requested ground goals")
	_check(actors.a.global_position==terrain.grid_to_world(Vector2i(3,0)) and actors.b.global_position==terrain.grid_to_world(Vector2i(5,0)),"finished actors stand at authoritative goal centers")
	_check(sim.get_hex_movement_readout("a").navigation_jobs==1 and sim.get_hex_movement_readout("b").navigation_jobs==1,"waiting behind another unit does not rebuild unchanged routes")
	_check(warmed_timing,"warm reservation attempts reuse terrain timing profiles instead of rereading whole routes")
	_check(budget_bounded and objective_checked,"actual movement keeps bounded navigation and reservation work")
	_check(not sim.has_hex_destination_arrived("a","stale") and sim.get_hex_movement_readout("missing").is_empty(),"arrival reads reject stale command identity and missing units")
	sim.queue_hex_facing_intent("a",3,"stationary_face","security_assignment")
	sim._physics_process(0.25)
	_check(sim.get_hex_unit_state("a").facing_dir==3 and is_equal_approx(float(actors.a.get_meta("facing_angle")),float(sim.get_hex_motion_projection("a",0.0).facing_angle)),"stationary facing commit refreshes actor projection after movement ends")
	_test_hold_damage_and_detour(sim,terrain,actors)
	_test_legacy(sim,terrain,actors)
	for actor in actors.values():actor.free()
	sim.free()
	registry.free()
	terrain.free()
	_test_six_directions()
	_test_ramp_commands()
	_test_two_location_commands()
	_test_occupied_goal()
	_test_pending_cancel()
	_finish()

func _test_occupied_goal()->void:
	var terrain=REGISTRY.new()
	root.add_child(terrain)
	terrain.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	for x in range(2):terrain.register_tile(TILE.new({"tile_id":str(x),"grid_position":Vector2i(x,0)}))
	var registry=UNITS.new()
	root.add_child(registry)
	var sim=SIM.new()
	root.add_child(sim)
	sim.unit_registry_path=sim.get_path_to(registry)
	sim.terrain_registry_path=sim.get_path_to(terrain)
	var map=MAP.create_empty("occupied_goal",Vector2i(2,1),Vector2.ZERO,64,32,3,"hex_axial_v1")
	map.set_tactical_grid_rules("hex_tactical_v1")
	sim.configure_hex_ground_runtime(map,terrain)
	var actors:Array=[]
	for id in ["a","b"]:
		var actor=Actor.new()
		actor.unit_id=id
		root.add_child(actor)
		registry.register_unit(id,actor)
		sim.register_known_unit(id,actor)
		actors.append(actor)
	var batch:Array[Dictionary]=[{"unit_id":"a","grid":Vector2i.ZERO},{"unit_id":"b","grid":Vector2i.RIGHT}]
	sim.admit_hex_ground_units(batch)
	sim.enqueue_command(_command("a",terrain.grid_to_world(Vector2i.RIGHT)))
	for tick in range(12):sim._physics_process(0.25)
	var readout:Dictionary=sim.get_hex_movement_readout("a")
	_check(readout.status=="waiting_reservation" and readout.reason=="target_occupied" and readout.navigation_jobs==0 and not readout.navigation_pending,"stationary occupied goal waits without starting impossible navigation")
	_check(readout.source_command_id=="move_a" and sim.get_hex_unit_state("a").grid==Vector2i.ZERO and sim.get_hex_unit_state("b").grid==Vector2i.RIGHT,"occupied goal preserves accepted token and distinct actor cells")
	var movement=sim.get("_hex_movement_runtime")
	var saved:Dictionary=movement.export_state()
	var prepared:Dictionary=movement.prepare_restore_state(JSON.parse_string(JSON.stringify(saved)))
	_check(saved.get("schema","")=="hex_movement_v1" and prepared.get("ok",false) and movement.publish_prepared_restore(prepared.prepared).get("ok",false),"occupied accepted intent survives real movement export and restore")
	_check(sim.get_hex_movement_readout("a").source_command_id=="move_a" and sim.get_hex_movement_readout("a").reason=="target_occupied","restored occupied intent retains token and wait reason")
	sim.release_hex_ground_unit("b","test_blocker_release")
	for tick in range(32):sim._physics_process(0.25)
	_check(sim.has_hex_destination_arrived("a","move_a") and sim.get_hex_unit_state("a").grid==Vector2i.RIGHT,"same accepted intent replans and actually arrives after blocker release")
	for actor in actors:actor.free()
	sim.free()
	registry.free()
	terrain.free()

func _test_pending_cancel()->void:
	var terrain=REGISTRY.new()
	root.add_child(terrain)
	terrain.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	for x in range(2):terrain.register_tile(TILE.new({"tile_id":str(x),"grid_position":Vector2i(x,0)}))
	var registry=UNITS.new()
	root.add_child(registry)
	var sim=SIM.new()
	root.add_child(sim)
	sim.unit_registry_path=sim.get_path_to(registry)
	sim.terrain_registry_path=sim.get_path_to(terrain)
	var map=MAP.create_empty("pending_cancel",Vector2i(2,1),Vector2.ZERO,64,32,3,"hex_axial_v1")
	map.set_tactical_grid_rules("hex_tactical_v1")
	sim.configure_hex_ground_runtime(map,terrain)
	var actors:Array=[]
	for id in ["a","b"]:
		var actor=Actor.new()
		actor.unit_id=id
		root.add_child(actor)
		registry.register_unit(id,actor)
		sim.register_known_unit(id,actor)
		actors.append(actor)
	var batch:Array[Dictionary]=[{"unit_id":"a","grid":Vector2i.ZERO},{"unit_id":"b","grid":Vector2i.RIGHT}]
	sim.admit_hex_ground_units(batch)
	sim.enqueue_command(_command("a",terrain.grid_to_world(Vector2i.RIGHT)))
	sim.enqueue_command(_command("b",terrain.grid_to_world(Vector2i.ZERO),0.0))
	sim._physics_process(0.25)
	_check(sim.get_hex_movement_readout("a").cached_route_nodes>0 and not sim.get_hex_unit_state("a").route_state.has_commitments,"blocked follower has a cached route before its first accepted promise")
	sim.enqueue_command({"type":"hold_position","unit_id":"a","team_id":"blue","command_token":"early_hold_a"})
	sim._physics_process(0.25)
	_check(sim.get_hex_movement_readout("a").status=="canceled" and sim.get_hex_movement_readout("a").cached_route_nodes==0 and not sim.get_hex_movement_readout("a").navigation_pending,"Hold before first ground commit releases navigation and timing caches")
	for actor in actors:actor.free()
	sim.free()
	registry.free()
	terrain.free()

func _test_hold_damage_and_detour(sim:Node,terrain:Node,actors:Dictionary)->void:
	sim.set_navigation_max_new_path_queries_per_tick(0)
	var reverse:Dictionary=_command("a",terrain.grid_to_world(Vector2i.ZERO))
	reverse.command_token="reverse_a"
	var standing:Vector2i=sim.get_hex_unit_state("a").grid
	sim.enqueue_command(reverse)
	sim._physics_process(0.25)
	_check(sim.get_hex_unit_state("a").grid==standing and sim.get_hex_movement_audit_snapshot().navigation_jobs_created==0 and sim.get_hex_movement_readout("a").reason=="navigation_budget","zero navigation admission keeps the goal pending without free movement")
	sim.set_navigation_max_new_path_queries_per_tick(4)
	sim._physics_process(0.25)
	sim._physics_process(0.25)
	sim.enqueue_command({"type":"hold_position","unit_id":"a","team_id":"blue","command_token":"hold_a"})
	sim._physics_process(0.25)
	var held:Vector2i=sim.get_hex_unit_state("a").grid
	for i in range(8):sim._physics_process(0.25)
	_check(sim.get_hex_unit_state("a").grid==held and not sim.get_hex_unit_state("a").movement_state.moving and sim.get_hex_movement_readout("a").status=="canceled" and actors.a.get_current_unit_command().command_type=="hold_position","real Hold cancels the accepted goal and never resumes its old continuation")
	var onward:Dictionary=_command("a",terrain.grid_to_world(Vector2i(4,0)))
	onward.command_token="injury_a"
	sim.enqueue_command(onward)
	sim._physics_process(0.25)
	sim._physics_process(0.25)
	sim.enqueue_effect({"effect_type":"damage","unit_id":"a","damage":200,"hit_chance":1.0,"roll_override":0.0})
	sim._physics_process(0.25)
	var wounded:Vector2i=sim.get_hex_unit_state("a").grid
	for i in range(8):sim._physics_process(0.25)
	_check(actors.a.get_vital_state()=="down" and sim.get_hex_unit_state("a").grid==wounded and not sim.get_hex_unit_state("a").movement_state.moving and not sim.get_hex_unit_state("a").route_state.has_commitments,"real damage producer stops motion and future promises while wounded unit keeps its hex")
	var around:Dictionary=_command("b",terrain.grid_to_world(Vector2i.ZERO))
	around.command_token="around_b"
	sim.enqueue_command(around)
	var avoided:=true
	for i in range(128):
		sim._physics_process(0.25)
		avoided=avoided and sim.get_hex_unit_state("b").grid!=wounded
		if sim.has_hex_destination_arrived("b","around_b"):break
	_check(avoided and sim.has_hex_destination_arrived("b","around_b"),"another real goal routes around a downed ground occupant in available space")

func _test_legacy(sim:Node,terrain:Node,actors:Dictionary)->void:
	var map=MAP.create_empty("legacy_move",Vector2i(6,2),Vector2.ZERO,64,32,3,"hex_axial_v1")
	sim.configure_hex_ground_runtime(map,terrain)
	var before:Vector2=actors.b.global_position
	var command:Dictionary=_command("b",terrain.grid_to_world(Vector2i.RIGHT))
	command.command_token="legacy_b"
	sim.enqueue_command(command)
	sim._physics_process(0.25)
	_check(not sim.is_hex_ground_runtime_active() and sim.get_hex_unit_state("b").is_empty() and actors.b.global_position!=before and not actors.b.has_meta("hex_ground_moving"),"unflagged legacy context retains its old continuous move path")

func _test_six_directions()->void:
	var durations:Array=[]
	for direction in range(6):
		var terrain=REGISTRY.new()
		root.add_child(terrain)
		terrain.configure_iso_grid(Vector2.ZERO,200,12,"hex_axial_v1")
		var target:Vector2i=HEX.DIRECTIONS[direction]
		for grid in [Vector2i.ZERO,target]:terrain.register_tile(TILE.new({"tile_id":str(grid),"grid_position":grid}))
		var registry=UNITS.new()
		root.add_child(registry)
		var sim=SIM.new()
		root.add_child(sim)
		sim.unit_registry_path=sim.get_path_to(registry)
		sim.terrain_registry_path=sim.get_path_to(terrain)
		var map=MAP.create_empty("direction",Vector2i(2,2),Vector2.ZERO,200,12,3,"hex_axial_v1")
		map.set_tactical_grid_rules("hex_tactical_v1")
		sim.configure_hex_ground_runtime(map,terrain)
		var actor=Actor.new()
		actor.unit_id="rot"
		root.add_child(actor)
		registry.register_unit("rot",actor)
		sim.register_known_unit("rot",actor)
		var batch:Array[Dictionary]=[{"unit_id":"rot","grid":Vector2i.ZERO}]
		sim.admit_hex_ground_units(batch)
		sim.enqueue_command(_command("rot",terrain.grid_to_world(target)))
		sim._physics_process(0.1)
		var segments:Array=sim.get_hex_ground_planning_snapshot().committed_segments
		var valid:bool=segments.size()==1
		if valid:durations.append(segments[0].duration_ticks)
		_check(valid and sim.get_hex_unit_state("rot").facing_dir==direction,"real projected movement starts with canonical facing in direction%d"%direction)
		for i in range(32):
			if sim.has_hex_destination_arrived("rot","move_rot"):break
			sim._physics_process(0.1)
		_check(sim.has_hex_destination_arrived("rot","move_rot") and actor.global_position.is_equal_approx(terrain.grid_to_world(target)),"real direction%d reaches its actual ground center"%direction)
		actor.free()
		sim.free()
		registry.free()
		terrain.free()
	var equal:bool=durations.size()==6
	for duration in durations:equal=equal and duration==durations[0]
	_check(equal,"all six projected directions use equal physical step durations")

func _test_ramp_commands()->void:
	var terrain=REGISTRY.new()
	root.add_child(terrain)
	terrain.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	for spec in [{"grid":Vector2i(-1,0),"height":0,"ramp":-1},{"grid":Vector2i.ZERO,"height":0,"ramp":0},{"grid":Vector2i.RIGHT,"height":1,"ramp":-1},{"grid":Vector2i(0,1),"height":0,"ramp":-1}]:
		terrain.register_tile(TILE.new({"tile_id":str(spec.grid),"grid_position":spec.grid,"height_level":spec.height,"ramp_direction":spec.ramp,"explicit_hex_ramps":true}))
	var registry=UNITS.new()
	root.add_child(registry)
	var sim=SIM.new()
	root.add_child(sim)
	sim.unit_registry_path=sim.get_path_to(registry)
	sim.terrain_registry_path=sim.get_path_to(terrain)
	var map=MAP.create_empty("ramp_commands",Vector2i(3,2),Vector2.ZERO,64,32,3,"hex_axial_v1")
	map.set_tactical_grid_rules("hex_tactical_v1")
	sim.configure_hex_ground_runtime(map,terrain)
	var actor=Actor.new()
	actor.unit_id="r"
	root.add_child(actor)
	registry.register_unit("r",actor)
	sim.register_known_unit("r",actor)
	var batch:Array[Dictionary]=[{"unit_id":"r","grid":Vector2i(-1,0)}]
	sim.admit_hex_ground_units(batch)
	for goal in [Vector2i.RIGHT,Vector2i(-1,0)]:
		var command:Dictionary=_command("r",terrain.grid_to_world(goal))
		command.command_token="ramp_%s"%str(goal)
		sim.enqueue_command(command)
		for i in range(32):
			sim._physics_process(0.25)
			if sim.has_hex_destination_arrived("r",command.command_token):break
		_check(sim.has_hex_destination_arrived("r",command.command_token) and sim.get_hex_unit_state("r").grid==goal,"actual ramp goal completes bidirectionally: "+str(goal))
	var side:Dictionary=_command("r",terrain.grid_to_world(Vector2i(0,1)))
	side.command_token="ramp_cliff"
	sim.enqueue_command(side)
	for i in range(16):sim._physics_process(0.25)
	_check(sim.get_hex_unit_state("r").grid==Vector2i(-1,0) and not sim.has_hex_destination_arrived("r","ramp_cliff") and sim.get_hex_movement_readout("r").status=="blocked" and sim.get_hex_movement_readout("r").navigation_jobs==1,"ramp cliff cannot become a render-position shortcut or repeated blind route search")
	actor.free()
	sim.free()
	registry.free()
	terrain.free()

func _test_two_location_commands()->void:
	var rigs:Array=[]
	for n in range(2):
		var terrain=REGISTRY.new()
		root.add_child(terrain)
		var origin:=Vector2(1000,1000)*n
		terrain.configure_iso_grid(origin,64,32,"hex_axial_v1")
		for x in range(2):terrain.register_tile(TILE.new({"tile_id":str(x),"grid_position":Vector2i(x,0)}))
		var registry=UNITS.new()
		root.add_child(registry)
		var sim=SIM.new()
		root.add_child(sim)
		sim.unit_registry_path=sim.get_path_to(registry)
		sim.terrain_registry_path=sim.get_path_to(terrain)
		var map=MAP.create_empty("location_%d"%n,Vector2i(2,1),origin,64,32,3,"hex_axial_v1")
		map.set_tactical_grid_rules("hex_tactical_v1")
		sim.configure_hex_ground_runtime(map,terrain)
		var actor=Actor.new()
		actor.unit_id="local"
		root.add_child(actor)
		actor.visible=n==0
		registry.register_unit("local",actor)
		sim.register_known_unit("local",actor)
		var batch:Array[Dictionary]=[{"unit_id":"local","grid":Vector2i.ZERO}]
		sim.admit_hex_ground_units(batch)
		sim.enqueue_command(_command("local",terrain.grid_to_world(Vector2i.RIGHT)))
		sim._physics_process(0.25)
		rigs.append({"sim":sim,"terrain":terrain,"registry":registry,"actor":actor})
	rigs[0].sim.enqueue_command({"type":"hold_position","unit_id":"local","team_id":"blue","command_token":"local_hold"})
	for i in range(8):
		for rig in rigs:rig.sim._physics_process(0.25)
	_check(not rigs[0].sim.has_hex_destination_arrived("local","move_local") and rigs[1].sim.has_hex_destination_arrived("local","move_local") and not rigs[1].actor.visible,"hidden location executes its own real goal while another location holds the same local ID")
	_check(rigs[0].sim.get_hex_unit_state("local").grid==Vector2i.ZERO and rigs[1].actor.global_position==rigs[1].terrain.grid_to_world(Vector2i.RIGHT),"actual command and actor projections stay scoped to their owning registry")
	for rig in rigs:
		rig.actor.free()
		rig.sim.free()
		rig.registry.free()
		rig.terrain.free()
func _finish()->void:
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0:print("HEX_MOVEMENT_PASS")
	quit(0 if failed==0 else 1)
