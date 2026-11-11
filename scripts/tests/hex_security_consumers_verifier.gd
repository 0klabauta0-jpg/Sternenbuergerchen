extends SceneTree
const SIM=preload("res://scripts/core/simulation_root.gd")
const MAP=preload("res://scripts/terrain/terrain_map_data.gd")
const REGISTRY=preload("res://scripts/terrain/terrain_registry.gd")
const TILE=preload("res://scripts/terrain/terrain_tile_data.gd")
const CACHE=preload("res://scripts/mission/combat_visibility_cache.gd")
const ADAPTER=preload("res://scripts/core/hex_sight_runtime_adapter.gd")
const SECURITY=preload("res://scripts/tactical/fireteam_security_controller.gd")
const OVERWATCH=preload("res://scripts/tactical/overwatch_controller.gd")
const FLANK=preload("res://scripts/tactical/flank_vulnerability_resolver.gd")
const COMMAND=preload("res://scripts/npc/unit_command.gd")
const HEX=preload("res://scripts/terrain/hex_grid.gd")
var passed:=0
var failed:=0
class Actor extends Node2D:
	var id:=""
	var is_fireteam_lead:=false
	var command=COMMAND.new({"command_type":"hold_position"})
	func get_unit_id() -> String: return id
	func get_team_id() -> String: return "alpha" if id=="a" else "bravo"
	func get_vital_state() -> String: return "fit"
	func get_current_unit_command(): return command
	func get_active_weapon_id() -> String: return "rifle"
func _init() -> void: call_deferred("_run")
func _check(value: bool,label: String) -> void:
	if value:
		passed+=1
		print("PASS: ",label)
	else:
		failed+=1
		print("FAIL: ",label)
func _run() -> void:
	var adapter=ADAPTER.new()
	_check(adapter.has_method("apply_security_assignments"),"security assignments pass the shared authoritative facing bridge")
	if failed>0:
		_finish()
		return
	var sim=SIM.new()
	root.add_child(sim)
	sim.set_physics_process(false)
	var terrain=REGISTRY.new()
	terrain.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	for x in range(-1,3):
		terrain.register_tile(TILE.new({"tile_id":"tile_%d"%x,"grid_position":Vector2i(x,0),"world_position":terrain.grid_to_world(Vector2i(x,0)),"walkable":true}))
	var map=MAP.create_empty("security_fixture",Vector2i(4,1),Vector2.ZERO,64,32,3,"hex_axial_v1")
	map.set_tactical_grid_rules("hex_tactical_v1")
	sim.configure_hex_ground_runtime(map,terrain)
	var batch:Array[Dictionary]=[{"unit_id":"a","grid":Vector2i.ZERO,"facing_dir":0},{"unit_id":"b","grid":Vector2i(1,0),"facing_dir":3}]
	sim.admit_hex_ground_units(batch)
	var a:=Actor.new()
	a.id="a"
	a.position=Vector2(999,999)
	root.add_child(a)
	var b:=Actor.new()
	b.id="b"
	b.position=Vector2(999,999)
	root.add_child(b)
	sim.register_known_unit("a",a)
	sim.register_known_unit("b",b)
	var cache=CACHE.new()
	adapter.configure(sim,cache,120)
	for direction in range(6):
		var angle:float=(terrain.grid_to_world(HEX.DIRECTIONS[direction])-terrain.grid_to_world(Vector2i.ZERO)).angle()
		_check(adapter.world_angle_to_facing(angle)==direction,"projected bearing maps to canonical hex facing %d"%direction)
	var rear:float=adapter.facing_to_world_angle(3)
	var assignments:Array=adapter.apply_security_assignments([{"unit_id":"a","center_angle":rear,"arc_width":TAU}],"security1")
	_check(sim.get_hex_unit_state("a").facing_dir==0 and int(assignments[0].facing_dir)==0,"security projection reads committed facing while turn is pending")
	_check(is_equal_approx(float(assignments[0].arc_width),deg_to_rad(120)),"one 360 guard retains one individual sight cone")
	sim.tick_counter=1
	sim._commit_hex_facing_intents()
	_check(sim.get_hex_unit_state("a").facing_dir==3,"security intent commits through simulation")
	var security=SECURITY.new()
	var state:Dictionary=security.update_fireteam_state("alpha",[a],a,{"security_mode":"360"},{},{},{},[],{"hex_sight_adapter":adapter})
	_check(Vector2(state.anchor_position).is_equal_approx(terrain.grid_to_world(Vector2i.ZERO)),"friendly security anchor reads logical cell center")
	_check(bool(state.get("hex_tactical",false)) and float(state.member_assignments[0].arc_width)<=deg_to_rad(120)+0.001,"friendly security publishes individual committed cones")
	var edge_security=SECURITY.new()
	var edge_context:Dictionary={"hex_sight_adapter":adapter,"security_mode":"directional","security_direction_angle":adapter.facing_to_world_angle(0)}
	edge_security.update_fireteam_state("edge",[a],a,{}, {},{}, {},[],edge_context)
	var edge_position:Vector2=terrain.grid_to_world(HEX.DIRECTIONS[5])
	var edge_state:Dictionary=edge_security.update_fireteam_state("edge",[a],a,{}, {},{}, {},[{"unit_id":"hint","detection_state":"spotted","last_known_position":edge_position}],edge_context)
	_check(absf(wrapf(float(edge_state.direction_angle)-edge_position.angle(),-PI,PI))<0.000001,"canonical cone edge avoids a false projected-angle leadership delay")
	adapter.apply_security_assignments([{"unit_id":"a","center_angle":adapter.facing_to_world_angle(0),"arc_width":TAU}],"same_tick")
	adapter.apply_security_assignments([{"unit_id":"a","center_angle":adapter.facing_to_world_angle(3),"arc_width":TAU}],"same_tick")
	_check(int(sim._hex_facing_pending.a.direction)==3,"changed security intent in the same tick replaces the earlier desire")
	sim.queue_hex_facing_intent("a",0,"front","security_assignment")
	sim.tick_counter=2
	sim._commit_hex_facing_intents()
	var overwatch=OVERWATCH.new()
	overwatch.configure_hex_sight_adapter(adapter)
	overwatch._prime_enemy_positions([b])
	b.position=Vector2(-999,-999)
	var assignment:Dictionary={"center_angle":adapter.facing_to_world_angle(0),"arc_width":TAU}
	_check(overwatch._try_build_overwatch_shot(a,b,assignment,Vector2.ZERO,terrain,1000).is_empty(),"render motion alone cannot trigger overwatch")
	sim.release_hex_ground_unit("b","fixture")
	var far:Array[Dictionary]=[{"unit_id":"b","grid":Vector2i(2,0),"facing_dir":3}]
	sim.admit_hex_ground_units(far)
	_check(not overwatch._try_build_overwatch_shot(a,b,assignment,Vector2.ZERO,terrain,1000).is_empty(),"logical field change can trigger shared-visibility overwatch")
	sim.release_hex_ground_unit("b","fixture")
	far[0].grid=Vector2i(-1,0)
	sim.admit_hex_ground_units(far)
	_check(overwatch._try_build_overwatch_shot(a,b,assignment,Vector2.ZERO,terrain,1000).is_empty(),"overwatch cannot bypass the current individual sight cone")
	var flank=FLANK.new()
	flank.configure_hex_sight_adapter(adapter)
	var defense:Dictionary={"is_active":true,"security_mode":"360","hex_tactical":true,"anchor_position":Vector2.ZERO,"direction_angle":adapter.facing_to_world_angle(0),"member_assignments":[{"unit_id":"a","center_angle":adapter.facing_to_world_angle(0),"arc_width":deg_to_rad(120)}]}
	_check(bool(flank.preview_attack("alpha",b,a,defense,2).get("is_flank",false)),"one guard's 360 assignment does not grant all-direction flank immunity")
	sim.queue_hex_facing_intent("a",3,"rear_committed","security_assignment")
	sim.tick_counter=3
	sim._commit_hex_facing_intents()
	sim.release_hex_ground_unit("b","fixture")
	far[0].grid=Vector2i(1,0)
	sim.admit_hex_ground_units(far)
	_check(bool(flank.preview_attack("alpha",b,a,defense,3).get("is_flank",false)),"stale cached member heading cannot protect a guard after the actual turn")
	defense.member_assignments[0].center_angle=adapter.facing_to_world_angle(3)
	var pending_flank:Dictionary=flank.preview_attack("alpha",b,a,defense,3)
	_check(bool(pending_flank.get("is_flank",false)),"desired group heading grants no flank immunity before the turn commits")
	_check(String(pending_flank.get("direction_label",""))=="rear","flank direction label uses the committed defender heading too")
	sim.release_hex_ground_unit("b","fixture")
	far[0].grid=Vector2i(-1,0)
	sim.admit_hex_ground_units(far)
	var ramp=terrain.get_tile_at_grid(Vector2i.ZERO)
	ramp.explicit_hex_ramps=true
	ramp.height_level=2
	ramp.ramp_direction=0
	var covered=terrain.get_tile_at_grid(Vector2i(-1,0))
	covered.height_level=2
	covered.cover_value=70
	terrain.notify_tile_data_changed([Vector2i.ZERO,Vector2i(-1,0)])
	_check(is_equal_approx(sim._extract_terrain_cover_score(b),70),"authoritative damage cover reads the logical target tile")
	_check(is_equal_approx(sim._extract_height_accuracy_modifier(a,b),0.05),"damage height retains the ramp's half-step advantage")
	_check(sim._get_unit_world_position_for_damage_resolution(b).is_equal_approx(terrain.grid_to_world(Vector2i(-1,0))),"damage event projection reads the logical cell center")
	var c:=Actor.new()
	c.id="c"
	root.add_child(c)
	sim.register_known_unit("c",c)
	var third:Array[Dictionary]=[{"unit_id":"c","grid":Vector2i(2,0),"facing_dir":0}]
	sim.admit_hex_ground_units(third)
	var ring_security=SECURITY.new()
	ring_security.update_fireteam_state("ring",[a,b,c],a,{}, {},{}, {},[],{"hex_sight_adapter":adapter,"security_mode":"360","security_direction_angle":0.0})
	sim.tick_counter+=1
	sim._commit_hex_facing_intents()
	var directions:Array=[]
	for id in ["a","b","c"]: directions.append(int(sim.get_hex_unit_state(id).facing_dir))
	directions.sort()
	var max_gap:=maxi(maxi(int(directions[1])-int(directions[0]),int(directions[2])-int(directions[1])),int(directions[0])+6-int(directions[2]))
	_check(max_gap<=2,"three 120-degree guards can cover 360 without projection-induced blind sectors")
	for edge in range(6):
		ring_security.reset_all()
		var world_angle:float=adapter.plane_angle_to_world(deg_to_rad(30.0+60.0*edge))
		ring_security.update_fireteam_state("ring",[a,b,c],a,{}, {},{}, {},[],{"hex_sight_adapter":adapter,"security_mode":"360","security_direction_angle":world_angle})
		sim.tick_counter+=1
		sim._commit_hex_facing_intents()
		directions.clear()
		for id in ["a","b","c"]: directions.append(int(sim.get_hex_unit_state(id).facing_dir))
		directions.sort()
		max_gap=maxi(maxi(int(directions[1])-int(directions[0]),int(directions[2])-int(directions[1])),int(directions[0])+6-int(directions[2]))
		_check(max_gap<=2,"three guards stay evenly distributed at canonical half-sector %d"%edge)
	sim.release_hex_ground_unit("c","fixture")
	sim.unregister_known_unit("c")
	c.free()
	sim.configure_hex_ground_runtime(map,terrain)
	sim.admit_hex_ground_units(batch)
	var reset_state:Dictionary=edge_security.update_fireteam_state("edge",[a],a,{}, {},{}, {},[],{"hex_sight_adapter":adapter,"security_mode":"directional"})
	_check(is_zero_approx(float(reset_state.direction_angle)),"new owner context discards old security direction and pending shift")
	map.set_tactical_grid_rules("")
	sim.configure_hex_ground_runtime(map,terrain)
	var legacy=SECURITY.new()
	var legacy_state:Dictionary=legacy.update_fireteam_state("alpha",[a],a,{}, {},{}, {},[],{"security_mode":"directional"})
	_check(not legacy_state.has("hex_tactical") and is_equal_approx(float(legacy_state.member_assignments[0].arc_width),SECURITY.DIRECTIONAL_ARC_WIDTH),"legacy security payload and directional arc stay compatible")
	flank.configure_hex_sight_adapter(adapter)
	_check(flank.preview_attack("alpha",b,a,defense,2).is_empty(),"legacy 360 flank semantics stay unchanged")
	cache.free()
	a.free()
	b.free()
	terrain.free()
	sim.free()
	_finish()
func _finish() -> void:
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0: print("HEX_SECURITY_CONSUMERS_PASS")
	quit(0 if failed==0 else 1)
