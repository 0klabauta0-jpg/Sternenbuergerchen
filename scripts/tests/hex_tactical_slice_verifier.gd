extends SceneTree
## AP8 composition only. This partial marker is deliberately not the final gate.
const SIM = preload("res://scripts/core/simulation_root.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const UNITS = preload("res://scripts/registries/unit_registry.gd")
const DRIVER = preload("res://scripts/tests/mission_combat_loop_driver.gd")
const CACHE = preload("res://scripts/mission/combat_visibility_cache.gd")
const FIRE = preload("res://scripts/tactical/combat_fire_decision_resolver.gd")
var passed := 0
var failed := 0

class CapabilityNPC extends Node2D:
	var unit_id := ""
	var team_id := "blue"
	var current_command: RefCounted
	var target_position := Vector2.ZERO
	var speed := 1.0
	func get_unit_id() -> String: return unit_id
	func get_team_id() -> String: return team_id
	func get_vital_state() -> String: return "fit"
	func get_awareness() -> float: return 0.8
	func get_current_unit_command(): return current_command
	func assign_unit_command(command): current_command = command
	func set_target_position(point): target_position = point
	func get_target_position() -> Vector2: return target_position
	func get_move_speed_factor() -> float: return 1.0
	func get_combat_speed_multiplier() -> float: return speed
	func refresh_terrain_readability() -> void: pass

class SliceDriver extends DRIVER:
	func _ready() -> void:
		set_process(false)
		set_physics_process(false)

class MapCarrier extends Node:
	var _loaded_terrain_map_data: RefCounted

func _init() -> void: call_deferred("_run")
func _check(value: bool,label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print("PASS " if value else "FAIL ",label)
func _range(_a,_b) -> float: return 1000.0
func _door(open: bool) -> Dictionary:
	return {"interaction_id":"door","interaction_type":"door","state":"complete" if open else "interrupted","complete":open,"duration_seconds":2.0,"hold_seconds":2.0 if open else 0.0,"team_id":"blue"}
func _move(id: String,point: Vector2) -> Dictionary:
	return {"type":"move_to_position","unit_id":id,"team_id":"blue","target_position":point,"command_token":"slice_"+id,"requeue_until_target":true}

func _run() -> void:
	var fixture := Node.new()
	root.add_child(fixture)
	var terrain = TERRAIN.new()
	terrain.name = "TerrainRegistry"
	fixture.add_child(terrain)
	terrain.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	for x in range(10):
		terrain.register_tile(TILE.new({"tile_id":"slice_%d"%x,"grid_position":Vector2i(x,0),"height_level":1 if x>=4 else 0,"ramp_direction":0 if x==3 else -1,"explicit_hex_ramps":true,"walkable":x!=5,"blocks_los":x==5,"object_height":1 if x==5 else 0}))
	for exit_cell in [Vector2i(7,-1),Vector2i(7,1)]:
		terrain.register_tile(TILE.new({"tile_id":str(exit_cell),"grid_position":exit_cell,"height_level":1,"explicit_hex_ramps":true}))
	var map = MAP.create_empty("hex_tactical_slice",Vector2i(10,3),Vector2.ZERO,64,32,3,"hex_axial_v1")
	map.set_tactical_grid_rules("hex_tactical_v1")
	map._extension_metadata["terrain_height_rules"] = "explicit_hex_ramps_v1"
	map.set_marker_position("door_marker",terrain.grid_to_world(Vector2i(5,0)))
	var carrier := MapCarrier.new()
	carrier.name = "MissionSetup"
	carrier._loaded_terrain_map_data = map
	fixture.add_child(carrier)
	var units = UNITS.new()
	units.name = "UnitRegistry"
	fixture.add_child(units)
	var sim = SIM.new()
	sim.name = "SimulationRoot"
	sim.unit_registry_path = NodePath("../UnitRegistry")
	sim.terrain_registry_path = NodePath("../TerrainRegistry")
	fixture.add_child(sim)
	sim.set_physics_process(false)
	var configured: Dictionary = sim.configure_hex_ground_runtime(map,terrain)
	var cache = CACHE.new()
	cache.name = "VisibilityCache"
	fixture.add_child(cache)
	var driver := SliceDriver.new()
	driver.simulation_root_path = NodePath("../SimulationRoot")
	driver.terrain_registry_path = NodePath("../TerrainRegistry")
	driver.combat_visibility_cache_path = NodePath("../VisibilityCache")
	fixture.add_child(driver)
	driver._configure_mission_interaction_door_runtime_bindings({"interaction_points":[{"interaction_id":"door","interaction_type":"door","marker_id":"door_marker","required_order":"breach"}]})
	driver._refresh_mission_interaction_door_runtime_overrides()
	var actors := {}
	for spec in [{"id":"follower","x":0},{"id":"leader","x":1},{"id":"target","x":9}]:
		var npc := CapabilityNPC.new()
		npc.unit_id = spec.id
		npc.team_id = "red" if spec.id == "target" else "blue"
		npc.speed = 0.5 if spec.id == "leader" else 1.0
		fixture.add_child(npc)
		npc.position = terrain.grid_to_world(Vector2i(spec.x,0))
		units.register_unit(spec.id,npc)
		sim.register_known_unit(spec.id,npc)
		actors[spec.id] = npc
	var batch: Array[Dictionary] = [{"unit_id":"follower","grid":Vector2i.ZERO,"facing_dir":3},{"unit_id":"leader","grid":Vector2i.RIGHT,"facing_dir":3},{"unit_id":"target","grid":Vector2i(9,0),"facing_dir":3}]
	var admitted: Dictionary = sim.admit_hex_ground_units(batch)
	_check(configured.ok and admitted.ok and terrain.get_all_tiles().size() == 12,"real owner admits three actual capability NPCs on only twelve terrain hexes")
	sim.enqueue_command(_move("follower",terrain.grid_to_world(Vector2i(7,1))))
	sim.enqueue_command(_move("leader",terrain.grid_to_world(Vector2i(7,-1))))
	for i in range(4): sim._physics_process(0.1)
	var context: Dictionary = driver._build_fire_decision_context({"get_weapon_attack_range":Callable(self,"_range")})
	_check(sim.get_hex_unit_state("follower").grid == Vector2i.ZERO and sim.get_hex_unit_state("leader").grid == Vector2i.RIGHT and not FIRE.is_target_attackable(actors.follower,actors.target,context),"queued units wait before closed ramp/door route; actual shot sight blocks target")
	var opening: Dictionary = driver.update_mission_interaction_runtime_progress(_door(true))
	_check(opening.get("complete",false) and terrain.is_walkable(Vector2i(5,0)) and not driver._has_valid_los(actors.follower,actors.target),"real driver opens door; rear logical facing still hides target")
	var exclusive := true
	var passage_order: Array = []
	var ramp_seen := false
	var detected := false
	var shot_current := false
	var close_guarded := false
	var detected_grid := Vector2i(-1,-1)
	for i in range(256):
		sim._physics_process(0.1)
		driver._current_tick = sim.tick_counter
		driver._advance_detection_timers()
		var state: Dictionary = sim.get_hex_ground_planning_snapshot()
		exclusive = exclusive and state.occupant_by_grid.size() == 3 and state.units_by_id.follower.grid != state.units_by_id.leader.grid
		for id in ["leader","follower"]:
			var unit: Dictionary = state.units_by_id[id]
			if unit.grid == Vector2i(3,0): ramp_seen = ramp_seen or int(unit.stand_height_steps2) == 1
			if unit.grid == Vector2i(5,0) and not passage_order.has(id): passage_order.append(id)
		if not close_guarded and not sim.can_block_hex_ground_cells([Vector2i(5,0)],terrain).can_block:
			close_guarded = not driver.update_mission_interaction_runtime_progress(_door(false)).get("accepted",true)
		if driver._has_valid_los(actors.follower,actors.target):
			driver._start_or_continue_detection(actors.follower,"follower","target")
			if driver._is_detection_complete("follower","target"):
				detected = true
				detected_grid = state.units_by_id.follower.grid
				shot_current = FIRE.is_target_attackable(actors.follower,actors.target,context)
		if sim.has_hex_destination_arrived("follower","slice_follower") and sim.has_hex_destination_arrived("leader","slice_leader"): break
	print("SLICE_EVIDENCE passage_order=",passage_order," ramp_half_height=",ramp_seen," detected_at=",detected_grid)
	_check(exclusive and passage_order == ["leader","follower"] and ramp_seen,"reserved movement crosses half-height ramp and door in order without double occupancy")
	_check(close_guarded,"real door producer refuses closure through active passage claims")
	_check(detected and detected_grid != Vector2i.ZERO and shot_current,"logical field/facing change triggers real detection; shot resolver reads current sight")
	_check(sim.has_hex_destination_arrived("follower","slice_follower") and sim.has_hex_destination_arrived("leader","slice_leader"),"both actual movement commands report completed arrivals")
	sim.queue_hex_facing_intent("follower",3,"slice_rear","security_assignment")
	sim._physics_process(0.1)
	driver._current_tick = sim.tick_counter
	driver._advance_detection_timers()
	_check(not FIRE.is_target_attackable(actors.follower,actors.target,context) and not driver._is_detection_complete("follower","target"),"post-arrival logical turn invalidates detection and shot permission immediately")
	var ground: Object = sim.get("_hex_ground_runtime")
	print("AP7_PENDING export_state=",ground.has_method("export_state")," restore_state=",ground.has_method("restore_state")," checkpoint_peer_owner=not_verified")
	fixture.free()
	print("HEX_TACTICAL_SLICE_PARTIAL checks=%d failures=%d full_ap8=false"%[passed+failed,failed])
	if failed == 0: print("HEX_TACTICAL_SLICE_PARTIAL_READY")
	quit(0 if failed == 0 else 1)

