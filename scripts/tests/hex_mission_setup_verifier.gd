extends "res://scripts/tests/hex_ground_lifecycle_verifier.gd"

class Setup extends "res://scripts/tests/mission_test_setup.gd":
	var fixture_terrain:Node
	var fixture_terrain_enabled:=true
	var fog_initializations:=0
	var hardcode_fallbacks:=0
	func _ready()->void:pass
	func _setup_terrain_registry():return fixture_terrain if fixture_terrain_enabled else super._setup_terrain_registry()
	func _build_unit_loadout_modifiers()->void:pass
	func _get_friendly_spawn_offset(_index:int)->Vector2:return Vector2.ZERO
	func _get_enemy_spawn_offset(_index:int)->Vector2:return Vector2.ZERO
	func _setup_objective_status(_sim:Node,_marker:Marker2D)->void:pass
	func _setup_respawn_manager(_alpha:Marker2D,_bravo:Marker2D)->void:pass
	func _setup_enemy_waves(_units:Array)->void:pass
	func _apply_scenario_timer_to_combat_driver()->void:pass
	func _ensure_primary_3d_view(_units:Array)->void:pass
	func _initialize_fog_of_war(_units:Array,_terrain)->void:fog_initializations+=1
	func _setup_terrain_from_hardcode(terrain)->void:
		hardcode_fallbacks+=1
		super._setup_terrain_from_hardcode(terrain)

class SetupActor extends Actor:
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

class ProjectionRoot extends SIM:
	func _should_skip_local_tick_processing()->bool:return true

func _finish()->void:
	var probe=SIM.new()
	_check(probe.has_method("admit_hex_ground_setup_actors"),"actual setup can admit complete registered initial actors through Root")
	probe.free()
	if failed==0:
		_test_actual_setup(false,false)
		_test_actual_setup(true,false)
		_test_actual_setup(false,true)
		_test_actual_setup(false,false,true)
		_test_actual_setup(false,true,true)
		_test_pending_setup()
		_test_invalid_map_preserves_context()
		_test_replacement_root()
		_test_additional_invalid_map_contexts()
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0:print("HEX_MISSION_SETUP_PASS")
	quit(0 if failed==0 else 1)

func _test_actual_setup(deferred:bool,legacy:bool,presentation:bool=false)->void:
	var cells:Array=[]
	for q in range(4):
		for r in range(2):cells.append(Vector2i(q,r))
	var rig:Dictionary=_admission_rig(cells)
	if presentation:
		rig.sim.set_script(ProjectionRoot)
		rig.sim.unit_registry_path=rig.sim.get_path_to(rig.units)
		rig.sim.terrain_registry_path=rig.sim.get_path_to(rig.terrain)
	if legacy:rig.map.set_tactical_grid_rules("")
	var setup=Setup.new()
	rig.scene.add_child(setup)
	setup.set_process(false)
	setup.fixture_terrain=rig.terrain
	setup._loaded_terrain_map_data=rig.map
	setup.simulation_root_path=setup.get_path_to(rig.sim)
	setup.unit_registry_path=setup.get_path_to(rig.units)
	setup.terrain_registry_path=setup.get_path_to(rig.terrain)
	setup.team_id="blue"
	setup.defer_friendly_runtime_activation=deferred
	setup.use_2_5d_primary_view=false
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
	for id in ["a","b","enemy"]:
		var actor=SetupActor.new()
		actor.unit_id=id
		actor.fixture_team="red" if id=="enemy" else "blue"
		rig.scene.add_child(actor)
		setup.unit_paths.append(setup.get_path_to(actor))
		rig.actors[id]=actor
	var before:int=rig.sim.get_hex_ground_context_revision()
	setup._finish_ready_after_scenario_loaded(leader,rig.units,ftls,rig.sim)
	if presentation:
		_check(setup._is_initialized and setup.get_hex_setup_status().presentation_only!=legacy and not rig.sim.is_hex_ground_runtime_active() and rig.units.get_all_units().size()==3,"non-authority setup binds declared presentation mode and lookups legacy=%s"%legacy)
		if legacy:_check(rig.actors.a.visible and rig.actors.enemy.visible and setup.fog_initializations==1,"legacy non-authority setup retains its existing visible actors and fog initialization")
		else:_check(not rig.actors.a.visible and not rig.actors.b.visible and not rig.actors.enemy.visible and setup.fog_initializations==0,"non-authority initial hex actors stay hidden without local fog detection publishing them")
		rig.scene.free()
		return
	_check(setup._is_initialized and rig.sim.get_hex_ground_context_revision()>before and rig.sim.is_hex_ground_runtime_active()!=legacy,"actual setup binds declared Root map mode deferred=%s legacy=%s"%[deferred,legacy])
	if legacy:
		_check(rig.sim.get_hex_ground_planning_snapshot().is_empty() and rig.actors.a.position==rig.actors.b.position,"unflagged setup preserves legacy presentation placement")
	else:
		var units:Dictionary=rig.sim.get_hex_ground_planning_snapshot().units_by_id
		if deferred:
			_check(units.size()==1 and units.has("enemy") and not rig.units.has_unit("a") and not rig.actors.a.visible,"deferred actual friendly actors stay staged without Ground fields")
		else:
			_check(units.size()==3 and units.a.grid!=units.b.grid and units.enemy.grid==Vector2i(3,0),"actual setup atomically separates colliding spawn actors while preserving enemy anchor")
	rig.scene.free()

func _test_replacement_root()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO])
	rig.sim.name="SimulationRoot"
	var setup=Setup.new()
	rig.scene.add_child(setup)
	setup.set_process(false)
	setup.simulation_root_path=setup.get_path_to(rig.sim)
	setup._hex_setup_required=true
	var pending:Node2D=_add_admission_actor(rig,"pending")
	_add_admission_actor(rig,"blocker")
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["blocker"]),Vector2i.ZERO)
	setup._admit_hex_setup_nodes([pending])
	var old_context:int=rig.sim.get_hex_ground_context_revision()
	var old_identity:Dictionary=rig.sim.call("_hex_payload_identity","pending")
	rig.sim.free()
	var replacement=SIM.new()
	replacement.name="SimulationRoot"
	rig.scene.add_child(replacement)
	replacement.unit_registry_path=replacement.get_path_to(rig.units)
	replacement.terrain_registry_path=replacement.get_path_to(rig.terrain)
	replacement.configure_hex_ground_runtime(rig.map,rig.terrain)
	for id in ["pending","blocker"]:replacement.register_known_unit(id,rig.actors[id])
	setup._process(0.1)
	_check(replacement.get_hex_ground_context_revision()==old_context and replacement.call("_is_current_hex_payload",{"unit_id":"pending","_hex_lifecycle":old_identity}) and setup.get_hex_setup_status().pending_count==0 and replacement.get_hex_unit_state("pending").is_empty(),"replacement Root with equal numeric context cannot inherit an old initial placement intent")
	rig.scene.free()

func _test_additional_invalid_map_contexts()->void:
	for kind in ["zero_size","empty_hex"]:
		var rig:Dictionary=_admission_rig([Vector2i.ZERO])
		if kind=="empty_hex":
			rig.map.set_tactical_grid_rules("")
			rig.sim.configure_hex_ground_runtime(rig.map,rig.terrain)
		var setup=Setup.new()
		rig.scene.add_child(setup)
		setup.set_process(false)
		setup.fixture_terrain_enabled=false
		setup.terrain_registry_path=setup.get_path_to(rig.terrain)
		setup.simulation_root_path=setup.get_path_to(rig.sim)
		setup.map_file_path="user://invalid_setup_%s.json"%kind
		var candidate=MAP.create_empty("candidate",Vector2i.ONE,Vector2.ZERO,64,32,3,"hex_axial_v1")
		candidate.set_tactical_grid_rules("hex_tactical_v1")
		candidate.save_to_file(setup.map_file_path)
		var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(setup.map_file_path))
		if kind=="zero_size":data.grid_size={"x":0,"y":0}
		else:data.tiles=[]
		var file=FileAccess.open(setup.map_file_path,FileAccess.WRITE)
		file.store_string(JSON.stringify(data))
		file.close()
		var parsed=MAP.load_from_file(setup.map_file_path)
		var before:Dictionary=rig.sim.get_hex_ground_planning_snapshot()
		var terrain_revision:int=rig.terrain.get_revision()
		setup._finish_ready_after_scenario_loaded(rig.scene,rig.units,rig.scene,rig.sim)
		_check(not parsed.has_load_issue() and not setup._is_initialized and setup.hardcode_fallbacks==0 and rig.terrain.get_revision()==terrain_revision and rig.sim.get_hex_ground_planning_snapshot()==before,"additional invalid declared map is rejected before registry mutation or legacy fallback kind=%s"%kind)
		rig.scene.free()

func _test_pending_setup()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0)])
	var setup=Setup.new()
	rig.scene.add_child(setup)
	setup.set_process(false)
	setup.fixture_terrain=rig.terrain
	setup.simulation_root_path=setup.get_path_to(rig.sim)
	setup._hex_setup_required=true
	var actors:Array=[]
	for id in ["a","b"]:actors.append(_add_admission_actor(rig,id))
	_add_admission_actor(rig,"blocker")
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["blocker"]),Vector2i.ZERO)
	setup._admit_hex_setup_nodes(actors)
	var state:Dictionary=setup.get_hex_setup_status()
	_check(state.pending_count==2 and not rig.actors.a.visible and rig.sim.get_hex_unit_state("a").is_empty(),"full initial group waits without partial placement or visible phantom actors")
	for i in range(20):setup._process(0.1)
	_check(setup.get_hex_setup_status().attempts==state.attempts,"unchanged pending setup reuses its admission version instead of rebuilding plans")
	rig.sim.release_hex_ground_unit("blocker","fixture_exit_clear")
	setup._process(0.1)
	_check(setup.get_hex_setup_status().pending_count==0 and rig.actors.a.visible and rig.sim.get_hex_unit_state("a").grid!=rig.sim.get_hex_unit_state("b").grid,"actual claim release admits the complete waiting initial group")
	rig.scene.free()
	rig=_admission_rig([Vector2i.ZERO])
	setup=Setup.new()
	rig.scene.add_child(setup)
	setup.set_process(false)
	setup.fixture_terrain=rig.terrain
	setup.simulation_root_path=setup.get_path_to(rig.sim)
	setup._hex_setup_required=true
	var pending:Node2D=_add_admission_actor(rig,"pending")
	_add_admission_actor(rig,"blocker")
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["blocker"]),Vector2i.ZERO)
	setup._admit_hex_setup_nodes([pending])
	rig.sim.release_hex_ground_unit("pending","fixture_person_embarked")
	pending.set_meta("dropship_embarked",true)
	rig.sim.release_hex_ground_unit("blocker","fixture_exit_clear")
	setup._process(0.1)
	_check(setup.get_hex_setup_status().pending_count==0 and rig.sim.get_hex_unit_state("pending").is_empty() and not pending.visible,"retired pending lifecycle never reappears through an old setup intent")
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["pending"]),Vector2i.ZERO)
	setup._admit_hex_setup_nodes([rig.actors.blocker])
	var was_pending:bool=setup.get_hex_setup_status().pending_count==1
	rig.map.set_tactical_grid_rules("")
	rig.sim.configure_hex_ground_runtime(rig.map,rig.terrain)
	setup._process(0.1)
	_check(was_pending and setup.get_hex_setup_status().pending_count==0,"explicit Root context change retires pending setup even when the new mode is legacy")
	rig.scene.free()

func _test_invalid_map_preserves_context()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO])
	var setup=Setup.new()
	rig.scene.add_child(setup)
	setup.set_process(false)
	setup.fixture_terrain_enabled=false
	setup.terrain_registry_path=setup.get_path_to(rig.terrain)
	setup.simulation_root_path=setup.get_path_to(rig.sim)
	setup.map_file_path="user://invalid_hex_setup.json"
	var file=FileAccess.open(setup.map_file_path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"map_name":"invalid_setup","grid_size":[2,2],"grid_topology":"hex_axial_v1","tactical_grid_rules":"unsupported","tiles":[]}))
	file.close()
	var before:Dictionary=rig.sim.get_hex_ground_planning_snapshot()
	setup._finish_ready_after_scenario_loaded(rig.scene,rig.units,rig.scene,rig.sim)
	_check(not setup._is_initialized and setup.get_hex_setup_status().error.get("reason")=="map_load_issue" and rig.sim.get_hex_ground_planning_snapshot()==before,"invalid real map load preserves previous terrain and Root context without hardcode fallback")
	rig.scene.free()
