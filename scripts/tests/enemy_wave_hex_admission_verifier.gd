extends "res://scripts/tests/hex_ground_lifecycle_verifier.gd"

# Verzoegerte Gegnerwellen muessen beim Start der Welle in die Hex-Simulation aufgenommen werden.

class WaveSetup extends "res://scripts/tests/mission_test_setup.gd":
	var fixture_terrain:Node
	func _ready()->void:pass
	func _setup_terrain_registry():return fixture_terrain
	func _build_unit_loadout_modifiers()->void:pass
	func _get_friendly_spawn_offset(_index:int)->Vector2:return Vector2.ZERO
	func _get_enemy_spawn_offset(index:int)->Vector2:return Vector2(0.0,32.0*index)
	func _setup_objective_status(_sim:Node,_marker:Marker2D)->void:pass
	func _setup_respawn_manager(_alpha:Marker2D,_bravo:Marker2D)->void:pass
	func _apply_scenario_timer_to_combat_driver()->void:pass
	func _ensure_primary_3d_view(_units:Array)->void:pass
	func _initialize_fog_of_war(_units:Array,_terrain)->void:pass

class WaveActor extends Actor:
	var fixture_team:="blue"
	func get_team_id():return fixture_team
	func apply_identity_config(values:Dictionary)->void:
		unit_id=String(values.get("unit_id",unit_id))
		fixture_team=String(values.get("team_id",fixture_team))

class Leader extends Node:
	var members:Array=[]
	func add_unit_member(unit:Node)->void:
		if not members.has(unit):members.append(unit)
	func assign(_unit:Node)->void:pass

func _finish()->void:
	_test_delayed_wave(0.0)
	_test_delayed_wave(0.5)
	print("ENEMY_WAVE_HEX_ADMISSION passed=%d failed=%d"%[passed,failed])
	quit(0 if failed==0 else 1)

# first_delay 0: e0 startet beim Aufbau, e1 als zweite Welle verzoegert; sonst beide verzoegert.
func _test_delayed_wave(first_delay:float)->void:
	var tag:="first_delay=%s"%first_delay
	var cells:Array=[]
	for q in range(4):
		for r in range(2):cells.append(Vector2i(q,r))
	var rig:Dictionary=_admission_rig(cells)
	var setup=WaveSetup.new()
	rig.scene.add_child(setup)
	setup.set_process(false)
	setup.fixture_terrain=rig.terrain
	setup._loaded_terrain_map_data=rig.map
	setup.simulation_root_path=setup.get_path_to(rig.sim)
	setup.unit_registry_path=setup.get_path_to(rig.units)
	setup.terrain_registry_path=setup.get_path_to(rig.terrain)
	setup.team_id="blue"
	setup.use_2_5d_primary_view=false
	var waves=load("res://scripts/tests/enemy_wave_controller.gd").new()
	rig.scene.add_child(waves)
	waves.set_process(false)
	waves.unit_registry_path=waves.get_path_to(rig.units)
	waves.simulation_root_path=waves.get_path_to(rig.sim)
	waves.wave_count=2
	waves.units_per_wave=1
	waves.first_wave_delay_seconds=first_delay
	waves.wave_delay_seconds=1.0
	setup.enemy_wave_controller_path=setup.get_path_to(waves)
	var leader=Leader.new()
	rig.scene.add_child(leader)
	var ftls=load("res://scripts/registries/ftl_registry.gd").new()
	rig.scene.add_child(ftls)
	var alpha=Marker2D.new()
	rig.scene.add_child(alpha)
	var bravo=Marker2D.new()
	rig.scene.add_child(bravo)
	bravo.position=rig.terrain.grid_to_world(Vector2i(3,0))
	setup.spawn_alpha_path=setup.get_path_to(alpha)
	setup.spawn_bravo_path=setup.get_path_to(bravo)
	for id in ["a","e0","e1"]:
		var actor=WaveActor.new()
		actor.unit_id=id
		actor.fixture_team="blue" if id=="a" else "red"
		rig.scene.add_child(actor)
		actor.position=rig.terrain.grid_to_world({"a":Vector2i(0,0),"e0":Vector2i(3,0),"e1":Vector2i(3,1)}[id])
		setup.unit_paths.append(setup.get_path_to(actor))
		rig.actors[id]=actor
	setup._finish_ready_after_scenario_loaded(leader,rig.units,ftls,rig.sim)
	var sim=rig.sim
	_check(setup._is_initialized and setup._hex_setup_error.is_empty(),"setup initialised without error %s"%tag)
	var e0_now:bool=first_delay<=0.0
	_check(rig.units.has_unit("e0")==e0_now and (not sim.get_hex_unit_state("e0").is_empty())==e0_now,"wave 1 state at setup e0_active=%s %s"%[e0_now,tag])
	_check(not rig.units.has_unit("e1") and sim.get_hex_unit_state("e1").is_empty(),"delayed e1 is not yet active %s"%tag)
	var e0_grid:Vector2i=sim.get_hex_unit_state("e0").get("grid",Vector2i(-9,-9)) if e0_now else Vector2i(-9,-9)
	waves._process(first_delay+0.1)
	if not e0_now:
		setup._process(0.1)
		_check(rig.units.has_unit("e0") and not sim.get_hex_unit_state("e0").is_empty(),"e0 admitted when its wave starts %s"%tag)
		e0_grid=sim.get_hex_unit_state("e0").get("grid",Vector2i(-9,-9))
		waves._process(1.1)
	else:
		waves._process(1.1)
	setup._process(0.1)
	_check(rig.units.has_unit("e1") and not sim.get_hex_unit_state("e1").is_empty(),"delayed wave unit is registered and has a hex state %s"%tag)
	_check(sim.get_hex_unit_state("e0").get("grid",Vector2i(-8,-8))==e0_grid and sim.get_hex_ground_planning_snapshot().units_by_id.size()==2,"earlier units are not admitted twice %s"%tag)
	_check(setup._hex_setup_error.is_empty() and setup.get_hex_setup_status().pending_count==0,"no setup error and nothing pending %s"%tag)
	rig.scene.free()
