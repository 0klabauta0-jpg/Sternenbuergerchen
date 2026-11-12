extends SceneTree
const SIM=preload("res://scripts/core/simulation_root.gd")
const MAP=preload("res://scripts/terrain/terrain_map_data.gd")
const REG=preload("res://scripts/terrain/terrain_registry.gd")
const UNITS=preload("res://scripts/registries/unit_registry.gd")
const TILE=preload("res://scripts/terrain/terrain_tile_data.gd")
class Actor extends Node2D:
	var unit_id="test"
	var current_command
	var target_position:Vector2
	func get_unit_id():return unit_id
	func get_team_id():return "blue"
	func get_vital_state():return "fit"
	func get_current_unit_command():return current_command
	func assign_unit_command(c):current_command=c
	func set_target_position(p):target_position=p
	func get_target_position():return target_position
	func get_move_speed_factor():return 1.0
	func get_combat_speed_multiplier():return 1.0
class Producer extends Node:
	var registry:Node
	var blocked:Array=[]
	func get_ground_ship_blocked_cells():return {"ok":true,"registry_id":registry.get_instance_id(),"source_signature":str(blocked),"blocked_cells":blocked.duplicate()}
func _init():call_deferred("run")
func run():
	var scene=Node.new();root.add_child(scene)
	var sim=SIM.new();sim.name="SimulationRoot";scene.add_child(sim);sim.set_physics_process(false)
	var terrain=REG.new();scene.add_child(terrain);terrain.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	for x in range(6):
		for y in range(3):terrain.register_tile(TILE.new({"tile_id":"%d_%d"%[x,y],"grid_position":Vector2i(x,y)}))
	var units=UNITS.new();scene.add_child(units)
	sim.unit_registry_path=sim.get_path_to(units);sim.terrain_registry_path=sim.get_path_to(terrain)
	var map=MAP.create_empty("moving_ship_test",Vector2i(6,3),Vector2.ZERO,64,32,3,"hex_axial_v1");map.set_tactical_grid_rules("hex_tactical_v1");sim.configure_hex_ground_runtime(map,terrain)
	var producer=Producer.new();producer.name="TacticalController";producer.registry=terrain;producer.blocked=[Vector2i(2,1),Vector2i(3,1)];scene.add_child(producer)
	var actor=Actor.new();scene.add_child(actor);actor.global_position=terrain.grid_to_world(Vector2i(0,1));units.register_unit("test",actor);sim.register_known_unit("test",actor);sim.admit_hex_ground_units([{"unit_id":"test","grid":Vector2i(0,1)}])
	sim.enqueue_command({"type":"move_to_position","unit_id":"test","team_id":"blue","target_position":terrain.grid_to_world(Vector2i(5,1)),"move_speed_factor":1.0,"command_token":"ship_avoid","requeue_until_target":true})
	var safe=true
	var landing_rejected=false
	for i in range(250):
		sim._physics_process(.25)
		var snapshot:Dictionary=sim.get_hex_ground_planning_snapshot()
		for segment in snapshot.committed_segments:
			if producer.blocked.has(segment.get("to_grid")):safe=false
			var result:Dictionary=sim.can_block_hex_ground_cells([segment.to_grid],terrain)
			if result.get("ok",false) and not result.get("can_block",true):landing_rejected=true
		if producer.blocked.has(sim.get_hex_unit_state("test").grid):safe=false
		if sim.has_hex_destination_arrived("test","ship_avoid"):break
	var arrived=sim.has_hex_destination_arrived("test","ship_avoid")
	# A ship appears after the first trip, fully blocks the return corridor,
	# and departs again. A blocked order must resume without another command.
	producer.blocked=[Vector2i(2,0),Vector2i(2,1),Vector2i(2,2)]
	sim.enqueue_command({"type":"move_to_position","unit_id":"test","team_id":"blue","target_position":terrain.grid_to_world(Vector2i(0,1)),"move_speed_factor":1.0,"command_token":"ship_depart","requeue_until_target":true})
	for i in range(80):sim._physics_process(.25)
	var waited=not sim.has_hex_destination_arrived("test","ship_depart") and int(sim.get_hex_unit_state("test").grid.x)>2
	producer.blocked=[]
	for i in range(200):
		sim._physics_process(.25)
		if sim.has_hex_destination_arrived("test","ship_depart"):break
	var resumed=sim.has_hex_destination_arrived("test","ship_depart")
	print("SHIP_PATH safe=%s arrived=%s in_flight_landing_rejected=%s waited=%s resumed=%s"%[safe,arrived,landing_rejected,waited,resumed])
	scene.free()
	if safe and arrived and landing_rejected and waited and resumed:print("HEX_DYNAMIC_SHIP_MOVEMENT_PASS");quit(0)
	else:quit(1)
