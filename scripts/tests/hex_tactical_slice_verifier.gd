extends SceneTree
## AP8 bounded opt-in owner candidate. Real peers/native production checks are AP9.
const NETWORK_JOIN = preload("res://scripts/tests/hex_tactical_network_join.gd")
const VITAL = preload("res://scripts/npc/unit_vital_status.gd")
const ISOLATION = preload("res://scripts/tests/review2_isolated_user_guard.gd")
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
var root_checkpoint_done := false

class CapabilityNPC extends Node2D:
	var unit_id := ""
	var team_id := "blue"
	var current_command: RefCounted
	var target_position := Vector2.ZERO
	var speed := 1.0
	var vital = VITAL.new()
	func get_unit_id() -> String: return unit_id
	func get_team_id() -> String: return team_id
	func get_vital_state() -> String: return vital.state
	func get_vital_status() -> RefCounted: return vital
	func get_fireteam_id() -> String: return "red_ft" if team_id=="red" else "blue_ft"
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

class SliceRoot extends SIM:
	var refuse_authority := false
	func _should_skip_local_tick_processing() -> bool:
		return refuse_authority or super._should_skip_local_tick_processing()

class MapCarrier extends Node:
	var _loaded_terrain_map_data: RefCounted

func _init() -> void:
	if not ISOLATION.require_isolated_user_data(): return
	call_deferred("_run")
func _check(value: bool,label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print("PASS " if value else "FAIL ",label)
func _range(_a,_b) -> float: return 1000.0
func _door(open: bool) -> Dictionary:
	return {"interaction_id":"door","interaction_type":"door","state":"complete" if open else "interrupted","complete":open,"duration_seconds":2.0,"hold_seconds":2.0 if open else 0.0,"team_id":"blue"}
func _move(id: String,point: Vector2) -> Dictionary:
	return {"type":"move_to_position","unit_id":id,"team_id":"blue","target_position":point,"command_token":"slice_"+id,"requeue_until_target":true}

func _roundtrip_root_checkpoint(sim: Node,actors: Dictionary) -> bool:
	for method in ["get_hex_checkpoint_guard","export_hex_checkpoint_state","prepare_hex_checkpoint_restore","validate_prepared_hex_checkpoint_restore","commit_hex_checkpoint_restore","finalize_hex_checkpoint_restore"]:
		if not sim.has_method(method):
			_check(false,"Source composite Root checkpoint API is actually present: "+method)
			return false
	var guard: Dictionary=sim.get_hex_checkpoint_guard()
	var exported: Dictionary=sim.export_hex_checkpoint_state()
	var state: Dictionary=exported.get("state",{})
	var portable: bool=guard.get("ok",false) and exported.get("ok",false) and state.get("schema")=="hex_tactical_checkpoint.v1" and state.get("map_id")=="hex_tactical_slice" and state.get("rng_state") is String and state.get("ground",{}).get("schema")=="hex_ground_v2" and state.get("movement",{}).get("schema")=="hex_movement_v1" and not state.ground.get("active_segments",[]).is_empty() and not state.ground.get("passage_commitments",[]).is_empty()
	_check(portable,"actual Root exports the currently running passage with canonical RNG and both component states")
	if not portable:
		print("ROOT_CHECKPOINT_EXPORT_REJECT guard=",guard.get("reason","")," export=",exported.get("reason",""))
		return false
	var canonical: Variant=JSON.parse_string(JSON.stringify(state))
	if not canonical is Dictionary:
		_check(false,"actual Root checkpoint is JSON portable")
		return false
	var ground=sim.get("_hex_ground_runtime")
	var movement=sim.get("_hex_movement_runtime")
	var before_actors: Dictionary={}
	for id in actors: before_actors[id]=actors[id].global_position
	var invalid: Dictionary=canonical.duplicate(true)
	invalid.map_id="another_map"
	var rejected: Dictionary=sim.prepare_hex_checkpoint_restore(invalid)
	_check(not rejected.get("ok",true) and sim.export_hex_checkpoint_state().get("state",{})==state,"wrong-map composite candidate is rejected without changing live owners")
	var preparation: Dictionary=sim.prepare_hex_checkpoint_restore(canonical)
	var prepared: bool=preparation.get("ok",false) and preparation.get("prepared") is RefCounted
	_check(prepared and sim.export_hex_checkpoint_state().get("state",{})==state,"actual Root prepares all detached component targets before mutation")
	if not prepared:
		print("ROOT_CHECKPOINT_PREPARE_REJECT ",preparation.get("reason",""))
		return false
	var validation: Dictionary=sim.validate_prepared_hex_checkpoint_restore(preparation.prepared)
	_check(validation.get("ok",false),"actual Root validates the entire checkpoint before the first write")
	if not validation.get("ok",false): return false
	var committed: Dictionary=sim.commit_hex_checkpoint_restore(preparation.prepared,false)
	var finalized: Dictionary=sim.finalize_hex_checkpoint_restore(preparation.prepared) if committed.get("ok",false) else {"ok":false}
	var same: bool=committed.get("ok",false) and finalized.get("ok",false) and sim.get("_hex_ground_runtime")==ground and sim.get("_hex_movement_runtime")==movement and sim.export_hex_checkpoint_state().get("state",{})==state
	for id in actors: same=same and actors[id].global_position==before_actors[id]
	_check(same,"real composite commit/finalize retain existing owners, poses, original intents and whole passage commitments")
	if same: print("AP7_ROOT_CHECKPOINT_JOIN_READY")
	root_checkpoint_done=same
	return same


func _roundtrip_running_passage(sim: Node, actors: Dictionary) -> bool:
	var ground = sim.get("_hex_ground_runtime")
	var movement = sim.get("_hex_movement_runtime")
	var ground_state: Dictionary=ground.export_state()
	var movement_state: Dictionary=movement.export_state()
	var exported: bool=ground_state.get("schema")=="hex_ground_v2" and not ground_state.get("passage_commitments",[]).is_empty() and not ground_state.get("active_segments",[]).is_empty() and movement_state.get("schema")=="hex_movement_v1" and movement_state.get("accepted_intents",[]).size()==2
	_check(exported,"actual running ramp passage exports whole Ground promises and both Movement intents")
	if not exported:
		print("JOINT_EXPORT_REJECT ground=",ground_state.get("reason","")," movement=",movement_state.get("reason",""))
		for id in ["leader","follower"]:
			var order: Dictionary=movement.get("_orders").get(id,{})
			for key in order.get("command",{}):
				if typeof(key)!=TYPE_STRING or String(movement.call("_save_command_kind",String(key))).is_empty(): print("JOINT_UNSUPPORTED_COMMAND_FIELD unit=",id," key=",key," key_type=",typeof(key)," value_type=",typeof(order.command[key]))
		return false
	var actor_positions := {}
	var projections := {}
	var readouts := {}
	for id in actors:
		actor_positions[id]=actors[id].position
		projections[id]=ground.get_motion_projection(id,0.0)
	for id in ["leader","follower"]: readouts[id]=movement.get_readout(id)
	var ground_prepare: Dictionary=ground.prepare_restore_state(JSON.parse_string(JSON.stringify(ground_state)))
	var target = ground.get_prepared_restore_ground(ground_prepare.prepared) if ground_prepare.get("ok",false) else null
	var movement_prepare: Dictionary=movement.prepare_restore_state(JSON.parse_string(JSON.stringify(movement_state)),target) if target!=null else {"ok":false}
	var prepared: bool=ground_prepare.get("ok",false) and target!=null and movement_prepare.get("ok",false)
	_check(prepared and ground.export_state()==ground_state,"both real prepared handles validate a detached target without changing live Ground")
	if not prepared:
		print("JOINT_PREPARE_REJECT ground=",ground_prepare.get("reason","")," movement=",movement_prepare.get("reason",""))
		return false
	# Exercise actual policy guards only; this is not a real multiplayer peer.
	sim.refuse_authority=true
	var facing: Dictionary=sim.queue_hex_facing_intent("follower",2,"slice_refused","security_assignment")
	var stopped: Dictionary=sim.stop_hex_ground_units(PackedStringArray(["follower"]),"slice_refused")
	sim.release_hex_ground_unit("follower","slice_refused")
	sim.refuse_authority=false
	_check(facing.get("reason")=="not_authority" and stopped.get("reason")=="not_authority" and ground.export_state()==ground_state,"actual Root facing/stop/release authority gates leave running passage unchanged")
	var ground_validation: Dictionary=ground.validate_prepared_restore(ground_prepare.prepared)
	var movement_validation: Dictionary=movement.validate_prepared_restore(movement_prepare.prepared)
	var valid: bool=ground_validation.get("ok",false) and movement_validation.get("ok",false)
	_check(valid,"ALL real owner validations finish before the first restore write")
	if not valid: return false
	# No getters, callbacks or checks between the two prevalidated silent tails.
	var ground_result: Dictionary=ground._publish_prepared_restore(ground_prepare.prepared,ground_validation)
	var movement_result: Dictionary=movement._publish_prepared_restore(movement_prepare.prepared,movement_validation)
	_check(ground_result.get("ok",false) and movement_result.get("ok",false) and sim.get("_hex_ground_runtime")==ground and sim.get("_hex_movement_runtime")==movement,"Ground-first Movement-second tails retain the same actual Root component owners")
	var same: bool=ground.export_state()==ground_state
	for id in actors:
		var after: Dictionary=ground.get_motion_projection(id,0.0)
		same=same and actors[id].position==actor_positions[id] and after.get("position_world")==projections[id].get("position_world") and after.get("stand_height_logical")==projections[id].get("stand_height_logical")
	for id in ["leader","follower"]:
		var after: Dictionary=movement.get_readout(id)
		same=same and after.get("command_id")==readouts[id].get("command_id") and after.get("goal_grid")==readouts[id].get("goal_grid")
	_check(same,"roundtrip keeps motion, half-height, cohorts, original goals and actor poses without manual repositioning")
	return same and ground_result.get("ok",false) and movement_result.get("ok",false) and _roundtrip_root_checkpoint(sim,actors)

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
	var sim = SliceRoot.new()
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
	driver.name="CombatLoopDriver"
	driver.friendly_team_id="blue"
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
		npc.name = spec.id
		npc.team_id = "red" if spec.id == "target" else "blue"
		npc.speed = 0.5 if spec.id == "leader" else 1.0
		fixture.add_child(npc)
		npc.position = terrain.grid_to_world(Vector2i(spec.x,0))
		units.register_unit(spec.id,npc)
		sim.register_known_unit(spec.id,npc)
		actors[spec.id] = npc
	driver.friendly_unit_paths.assign([NodePath("../follower"),NodePath("../leader")])
	driver.enemy_unit_paths.assign([NodePath("../target")])
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
	var roundtrip_attempted := false
	var roundtrip_done := false
	for i in range(256):
		sim._physics_process(0.1)
		driver._current_tick = sim.tick_counter
		driver._advance_detection_timers()
		var state: Dictionary = sim.get_hex_ground_planning_snapshot()
		if not roundtrip_attempted and state.units_by_id.leader.grid==Vector2i(3,0) and not state.committed_corridor_grants.is_empty():
			for segment in state.committed_segments:
				if segment.unit_id=="leader" and segment.start_tick<state.current_tick and state.current_tick<segment.start_tick+segment.duration_ticks:
					roundtrip_attempted=true
					roundtrip_done=_roundtrip_running_passage(sim,actors)
					state=sim.get_hex_ground_planning_snapshot()
					break
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
	_check(roundtrip_done,"one actual in-flight passage roundtrip continued through the existing consumer chain")
	sim.queue_hex_facing_intent("follower",3,"slice_rear","security_assignment")
	sim._physics_process(0.1)
	driver._current_tick = sim.tick_counter
	driver._advance_detection_timers()
	_check(not FIRE.is_target_attackable(actors.follower,actors.target,context) and not driver._is_detection_complete("follower","target"),"post-arrival logical turn invalidates detection and shot permission immediately")
	# The same live 12-field owners now drive the network join. Root checkpoint
	# was required during their actual in-flight passage, never faked here.
	var network: Dictionary=NETWORK_JOIN.new().run(self,sim,driver,actors)
	network.root_checkpoint=root_checkpoint_done
	passed+=int(network.passed)
	failed+=int(network.failed)
	print("AP8_NETWORK_METADATA ",JSON.stringify(network))
	print("AP7_PARTIAL ground_v2_movement_v1_joint=",roundtrip_done," root_checkpoint=",network.root_checkpoint," host_publication=",network.host_publication," receiver=",network.receiver," real_peer=false")
	if network.ok: print("AP8_NETWORK_OWNER_JOIN_READY")
	if roundtrip_done and failed==0: print("AP7_JOINT_PASSAGE_ROUNDTRIP_READY")
	fixture.free()
	var bounded_ready: bool=failed==0 and roundtrip_done and root_checkpoint_done and network.get("ok",false)
	print("HEX_TACTICAL_SLICE checks=%d failures=%d ap8_bounded_ready=%s real_peer=false native_acceptance=false"%[passed+failed,failed,str(bounded_ready)])
	if bounded_ready: print("AP8_BOUNDED_CANDIDATE_READY")
	if failed == 0: print("HEX_TACTICAL_SLICE_PARTIAL_READY") # Legacy runner marker only.
	quit(0 if failed == 0 else 1)

