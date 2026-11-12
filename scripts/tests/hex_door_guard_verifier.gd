extends "res://scripts/tests/hex_movement_verifier.gd"
const DRIVER=preload("res://scripts/tests/mission_combat_loop_driver.gd")

class QuietDoorDriver extends DRIVER:
	func _ready()->void:
		set_process(false)
		set_physics_process(false)

class MapCarrier extends Node:
	var _loaded_terrain_map_data:RefCounted

class ResourceCounter extends Node:
	var calls:=0
	func accept_progress(_payload:Dictionary,_complete:bool)->Dictionary:
		calls+=1
		return {"accepted":true}

func _finish()->void:
	if failed==0:_test_door_guard()
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0:print("HEX_DOOR_GUARD_PASS")
	quit(0 if failed==0 else 1)

func _test_door_guard()->void:
	var sim=SIM.new()
	_check(sim.has_method("can_block_hex_ground_cells"),"Root exposes a read-only guard for actual cell/edge/passage claims")
	sim.free()
	if failed>0:return
	var fixture=Node.new()
	root.add_child(fixture)
	var terrain=REGISTRY.new()
	terrain.name="TerrainRegistry"
	fixture.add_child(terrain)
	terrain.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	var door:=Vector2i(4,0)
	for x in range(7):terrain.register_tile(TILE.new({"tile_id":str(x),"grid_position":Vector2i(x,0),"walkable":x!=4,"blocks_los":x==4,"object_height":1 if x==4 else 0}))
	for grid in [Vector2i(6,-1),Vector2i(6,1)]:terrain.register_tile(TILE.new({"tile_id":str(grid),"grid_position":grid}))
	var units=UNITS.new()
	units.name="UnitRegistry"
	fixture.add_child(units)
	var map=MAP.create_empty("guarded_door",Vector2i(7,3),Vector2.ZERO,64,32,3,"hex_axial_v1")
	map.set_tactical_grid_rules("hex_tactical_v1")
	map.set_marker_position("door_marker",terrain.grid_to_world(door))
	var carrier=MapCarrier.new()
	carrier.name="MissionSetup"
	carrier._loaded_terrain_map_data=map
	fixture.add_child(carrier)
	var resources=ResourceCounter.new()
	resources.name="LocationResources"
	fixture.add_child(resources)
	sim=SIM.new()
	sim.name="SimulationRoot"
	sim.unit_registry_path=NodePath("../UnitRegistry")
	sim.terrain_registry_path=NodePath("../TerrainRegistry")
	fixture.add_child(sim)
	sim.configure_hex_ground_runtime(map,terrain)
	var driver=QuietDoorDriver.new()
	driver.simulation_root_path=NodePath("../SimulationRoot")
	driver.terrain_registry_path=NodePath("../TerrainRegistry")
	fixture.add_child(driver)
	driver._configure_mission_interaction_door_runtime_bindings({"interaction_points":[{"interaction_id":"door","interaction_type":"door","marker_id":"door_marker","required_order":"breach"}]})
	driver._refresh_mission_interaction_door_runtime_overrides()
	driver.update_mission_interaction_runtime_progress(_door_payload(true))
	_check(terrain.is_walkable(door) and not terrain.blocks_los_at_grid(door),"actual driver opening state publishes matching physical door without any UI")
	var actor=Actor.new()
	actor.unit_id="traveler"
	fixture.add_child(actor)
	units.register_unit("traveler",actor)
	sim.register_known_unit("traveler",actor)
	var batch:Array[Dictionary]=[{"unit_id":"traveler","grid":Vector2i.ZERO}]
	sim.admit_hex_ground_units(batch)
	sim.enqueue_command(_command("traveler",terrain.grid_to_world(Vector2i(6,0))))
	sim._physics_process(0.1)
	var snapshot:Dictionary=sim.get_hex_ground_planning_snapshot()
	var has_far_segment:=false
	for segment in snapshot.committed_segments:has_far_segment=has_far_segment or segment.to_grid==door or segment.from_grid==door
	var guard:Dictionary=sim.can_block_hex_ground_cells([door],terrain)
	_check(not has_far_segment and not guard.can_block,"complete passage grant protects door beyond the three-step segment horizon")
	var owner_path:NodePath=driver.simulation_root_path
	driver.simulation_root_path=NodePath("missing_owner")
	_check(not driver.update_mission_interaction_runtime_progress(_door_payload(false)).get("accepted",true) and terrain.is_walkable(door),"opted-in door never falls back to legacy closure when its required Root reference is missing")
	driver.simulation_root_path=owner_path
	driver.update_mission_interaction_runtime_progress(_door_payload(true))
	snapshot=sim.get_hex_ground_planning_snapshot()
	var states_before:Dictionary=driver.get_mission_interaction_runtime_states()
	var revision_before:int=terrain.get_revision()
	var resource_calls:int=resources.calls
	var rejected:Dictionary=driver.update_mission_interaction_runtime_progress(_door_payload(false))
	_check(not rejected.get("accepted",true) and driver.get_mission_interaction_runtime_states()==states_before and terrain.is_walkable(door) and terrain.get_revision()==revision_before,"actual close request is rejected before owner state and physical override change")
	_check(resources.calls==resource_calls and sim.get_hex_ground_planning_snapshot()==snapshot,"rejected closure consumes no resource gate and does not cancel or mutate movement claims")
	var occupied_checked:=false
	var edge_checked:=false
	for i in range(128):
		sim._physics_process(0.1)
		var state:Dictionary=sim.get_hex_unit_state("traveler")
		if not occupied_checked and state.grid==door:
			occupied_checked=true
			_check(not driver.update_mission_interaction_runtime_progress(_door_payload(false)).get("accepted",true),"door cannot close through current logical occupant")
		if not edge_checked and state.grid==Vector2i(5,0) and state.movement_state.get("from_grid",Vector2i.ZERO)==door:
			edge_checked=true
			_check(not driver.update_mission_interaction_runtime_progress(_door_payload(false)).get("accepted",true),"door cannot close behind post-handoff actor before its active edge finishes")
		if sim.has_hex_destination_arrived("traveler","move_traveler"):break
	_check(occupied_checked and edge_checked and sim.has_hex_destination_arrived("traveler","move_traveler"),"real reserved route crosses the protected door and reaches its ground goal")
	var free_guard:Dictionary=sim.can_block_hex_ground_cells([door],terrain)
	_check(free_guard.can_block and driver.update_mission_interaction_runtime_progress(_door_payload(false)).get("accepted",true) and not terrain.is_walkable(door) and terrain.blocks_los_at_grid(door),"actual door may close only after occupant, edge and complete passage grant are released")
	var current:Dictionary=sim.get_hex_ground_planning_snapshot()
	_check(not sim.can_block_hex_ground_cells(["invalid"],terrain).ok and not sim.can_block_hex_ground_cells([Vector2i(99,0)],terrain).ok and sim.get_hex_ground_planning_snapshot()==current,"malformed or unknown guard cells fail without gameplay mutation")
	var too_many:Array=[]
	too_many.resize(65)
	too_many.fill(door)
	_check(not sim.can_block_hex_ground_cells(too_many,terrain).ok,"claim query remains bounded to64 supplied cells even when duplicated")
	var foreign=REGISTRY.new()
	_check(not sim.can_block_hex_ground_cells([door],foreign).ok,"door guard rejects a different registry even with the same cell coordinate")
	foreign.free()
	driver.update_mission_interaction_runtime_progress(_door_payload(true))
	var wounded=Actor.new()
	wounded.unit_id="wounded"
	fixture.add_child(wounded)
	units.register_unit("wounded",wounded)
	sim.register_known_unit("wounded",wounded)
	var wounded_batch:Array[Dictionary]=[{"unit_id":"wounded","grid":door}]
	sim.admit_hex_ground_units(wounded_batch)
	sim.enqueue_effect({"effect_type":"damage","unit_id":"wounded","damage":200,"roll_override":0.0})
	sim._physics_process(0.1)
	_check(wounded.vital_state=="down" and not driver.update_mission_interaction_runtime_progress(_door_payload(false)).get("accepted",true),"downed unit's retained field still prevents a closing cut")
	map.set_tactical_grid_rules("")
	sim.configure_hex_ground_runtime(map,terrain)
	_check(driver.update_mission_interaction_runtime_progress(_door_payload(false)).get("accepted",true) and not terrain.is_walkable(door),"legacy door producer retains its previous transition rules")
	driver.update_mission_interaction_runtime_progress(_door_payload(true))
	map.set_tactical_grid_rules("hex_tactical_v1")
	_check(not driver.update_mission_interaction_runtime_progress(_door_payload(false)).get("accepted",true) and terrain.is_walkable(door),"opted-in map with inactive Ground owner cannot silently use legacy blocking transition")
	fixture.free()

func _door_payload(open:bool)->Dictionary:
	return {"interaction_id":"door","interaction_type":"door","state":"complete" if open else "interrupted","complete":open,"duration_seconds":2.0,"hold_seconds":2.0 if open else 0.0,"team_id":"blue"}
