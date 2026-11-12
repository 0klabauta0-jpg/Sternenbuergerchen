extends "res://scripts/tests/hex_ground_lifecycle_verifier.gd"

class Waves extends "res://scripts/tests/enemy_wave_controller.gd":
	func _ready()->void:pass

class WaveActor extends "res://scripts/npc/test_unit.gd":
	func _ready()->void:pass

func _finish()->void:
	_test_waiting_wave()
	_test_wave_context()
	_test_actual_wave_reset()
	_test_wave_ship_and_binding()
	_test_wave_publication_lifetime()
	_test_wave_publication_context()
	_test_later_wave()
	_test_staging_callback()
	_test_retire_membership()
	_test_same_actor_staging_restart()
	_test_retire_from_visibility()
	_test_legacy_wave()
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0:print("HEX_MISSION_WAVE_PASS")
	quit(0 if failed==0 else 1)

func _waves(rig:Dictionary,ids:Array)->Node:
	var wave=Waves.new()
	rig.scene.add_child(wave)
	wave.set_process(false)
	wave.unit_registry_path=wave.get_path_to(rig.units)
	wave.simulation_root_path=wave.get_path_to(rig.sim)
	wave.first_wave_delay_seconds=0.0
	wave.wave_delay_seconds=45.0
	wave.units_per_wave=ids.size()
	var actors:Array=[]
	for id in ids:
		var actor=WaveActor.new()
		actor.unit_id=id
		actor.team_id="red"
		rig.scene.add_child(actor)
		actor.set_process(false)
		actor.set_physics_process(false)
		actor.global_position=rig.terrain.grid_to_world(Vector2i.ZERO)
		rig.units.register_unit(id,actor)
		rig.sim.register_known_unit(id,actor)
		rig.actors[id]=actor
		actors.append(actor)
	wave.initialize_enemy_units(actors)
	return wave

func _test_waiting_wave()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO,Vector2i(1,0)])
	_add_admission_actor(rig,"blocker")
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["blocker"]),Vector2i(1,0))
	var wave:Node=_waves(rig,["a","b"])
	_check(wave.get_current_wave_number()==0 and rig.sim.get_hex_unit_state("a").is_empty() and not rig.units.has_unit("a") and not rig.actors.a.visible,"actual blocked wave stays wholly dormant without consuming its wave number")
	var notices:Array=[]
	wave.wave_started.connect(func(number:int):notices.append({"number":number,"units":rig.sim.get_hex_ground_planning_snapshot().units_by_id.size(),"both_visible":rig.actors.a.visible and rig.actors.b.visible}))
	if not wave.has_method("get_hex_wave_status"):
		_check(false,"wave exposes bounded pending admission status")
		rig.scene.free()
		return
	var attempts:int=wave.get_hex_wave_status().attempts
	for i in range(20):
		rig.sim._physics_process(0.1)
		wave._process(0.1)
	_check(wave.get_hex_wave_status().attempts==attempts and wave.get_current_wave_number()==0,"unchanged space shortage does not rebuild wave admission plans")
	rig.sim.release_hex_ground_unit("blocker","fixture_clear")
	wave._process(0.1)
	_check(wave.get_current_wave_number()==1 and rig.sim.get_hex_unit_state("a").grid!=rig.sim.get_hex_unit_state("b").grid and rig.units.get_unit("a")==rig.actors.a,"actual claim release admits the entire wave on its short retry cadence")
	_check(notices==[{"number":1,"units":2,"both_visible":true}],"wave publication observes committed group and visible actors")
	rig.scene.free()

class ShipMask extends Node:
	var registry_id:=0
	var blocked:Array[Vector2i]=[Vector2i.ZERO]
	func get_ground_ship_blocked_cells()->Dictionary:return {"ok":true,"registry_id":registry_id,"source_signature":str(blocked),"blocked_cells":blocked.duplicate()}

func _test_wave_ship_and_binding()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO,Vector2i(1,0)])
	var ship=ShipMask.new()
	ship.name="TacticalController"
	ship.registry_id=rig.terrain.get_instance_id()
	rig.scene.add_child(ship)
	var wave:Node=_waves(rig,["enemy"])
	_check(wave.get_current_wave_number()==0 and not rig.units.has_unit("enemy"),"accepted foreign ship footprint blocks actual wave admission")
	ship.blocked.clear()
	wave._process(0.1)
	_check(wave.get_current_wave_number()==1 and rig.actors.enemy.visible,"changed ship footprint permits waiting wave without a terrain mutation")
	wave.first_wave_delay_seconds=5.0
	wave.initialize_enemy_units([rig.actors.enemy])
	rig.sim.release_hex_ground_unit("enemy","fixture_retire_lifecycle")
	wave._process(5.0)
	_check(wave.get_current_wave_number()==0 and rig.sim.get_hex_unit_state("enemy").is_empty(),"retired actor lifecycle cannot reuse a pending wave slot")
	rig.scene.free()

func _test_wave_publication_lifetime()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO])
	var wave:Node=_waves(rig,["enemy"])
	wave.first_wave_delay_seconds=5.0
	wave.initialize_enemy_units([rig.actors.enemy])
	wave.wave_started.connect(func(_number:int):wave.queue_free())
	wave._process(5.0)
	_check(wave.is_queued_for_deletion() and not rig.sim.get_hex_unit_state("enemy").is_empty(),"committed wave survives removal of its presentation controller during publication")
	rig.scene.free()

func _test_wave_publication_context()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO])
	var wave:Node=_waves(rig,["enemy"])
	wave.first_wave_delay_seconds=5.0
	wave.initialize_enemy_units([rig.actors.enemy])
	var events:Array=[]
	wave.wave_started.connect(func(number:int):events.append(number))
	rig.actors.enemy.visibility_changed.connect(func():
		if rig.actors.enemy.visible:rig.sim.configure_hex_ground_runtime(rig.map,rig.terrain))
	wave._process(5.0)
	_check(events.is_empty() and rig.sim.get_hex_unit_state("enemy").is_empty(),"context replaced by actor projection cannot publish a retired wave event")
	wave.initialize_enemy_units([])
	_check(not wave._hex_publishing_wave and wave._pending_initialization.is_empty(),"context-cancelled publication allows a subsequent explicit wave initialization")
	rig.scene.free()

func _test_later_wave()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO])
	var wave:Node=_waves(rig,["a","b"])
	wave.first_wave_delay_seconds=5.0
	wave.units_per_wave=1
	wave.wave_delay_seconds=2.0
	wave.initialize_enemy_units([rig.actors.a,rig.actors.b])
	var completions:Array=[]
	wave.all_waves_complete.connect(func():completions.append(true))
	wave._process(5.0)
	_check(wave.get_current_wave_number()==1 and rig.units.has_unit("a") and not rig.units.has_unit("b") and wave._time_until_next_wave==2.0,"first admitted wave leaves later actors dormant and retains configured interwave delay")
	wave._process(2.0)
	_check(wave.get_current_wave_number()==1 and not rig.units.has_unit("b") and completions.is_empty(),"later wave also waits for its occupied entry anchor")
	rig.sim.release_hex_ground_unit("a","fixture_first_wave_departed")
	wave._process(0.1)
	wave._process(3.0)
	_check(wave.get_current_wave_number()==2 and rig.units.has_unit("b") and completions==[true],"later wave retries its own lifecycle and publishes final completion once")
	rig.scene.free()

func _test_staging_callback()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO])
	var wave:Node=_waves(rig,["enemy"])
	wave.first_wave_delay_seconds=5.0
	var invoked:Array=[]
	rig.actors.enemy.runtime_status_changed.connect(func(_status):
		if invoked.is_empty():
			invoked.append(true)
			wave.initialize_enemy_units([]))
	wave.initialize_enemy_units([rig.actors.enemy])
	_check(invoked==[true] and wave._enemy_units.is_empty() and wave._hex_wave_slots.is_empty() and wave._spawn_positions_by_unit_id.is_empty() and wave._time_until_next_wave==5.0,"actual actor staging callback cannot append retired slots after a reinitialization")
	rig.scene.free()

func _test_retire_membership()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO,Vector2i(1,0)])
	var wave:Node=_waves(rig,["a","b"])
	wave.initialize_enemy_units([])
	_check(rig.sim.get_hex_ground_planning_snapshot().units_by_id.is_empty() and not rig.units.has_unit("a") and not rig.units.has_unit("b") and not rig.actors.a.visible and not rig.actors.b.visible,"empty wave reinitialization retires previous physical membership and both projections")
	rig.scene.free()

func _test_same_actor_staging_restart()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO])
	var wave:Node=_waves(rig,["enemy"])
	wave.first_wave_delay_seconds=5.0
	var events:Array=[]
	rig.actors.enemy.runtime_status_changed.connect(func(_status):
		if events.is_empty():
			events.append(true)
			wave.first_wave_delay_seconds=0.0
			wave.initialize_enemy_units([rig.actors.enemy]))
	wave.initialize_enemy_units([rig.actors.enemy])
	_check(events==[true] and wave.get_current_wave_number()==1 and not rig.sim.get_hex_unit_state("enemy").is_empty() and rig.units.get_unit("enemy")==rig.actors.enemy and rig.actors.enemy.visible,"same-actor restart during medical staging cannot hide a newly admitted actor")
	rig.scene.free()

func _test_retire_from_visibility()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO,Vector2i(1,0)])
	var wave:Node=_waves(rig,["a","b"])
	wave.first_wave_delay_seconds=5.0
	wave.initialize_enemy_units([rig.actors.a,rig.actors.b])
	var shown_b:Array=[]
	rig.actors.a.visibility_changed.connect(func():
		if rig.actors.a.visible:wave.initialize_enemy_units([]))
	rig.actors.b.visibility_changed.connect(func():
		if rig.actors.b.visible:shown_b.append(true))
	wave._process(5.0)
	_check(rig.sim.get_hex_ground_planning_snapshot().units_by_id.is_empty() and not rig.units.has_unit("a") and not rig.units.has_unit("b") and not rig.actors.a.visible and not rig.actors.b.visible and shown_b.is_empty(),"visibility callback retires whole old membership without showing a remaining stale actor")
	rig.scene.free()

func _test_wave_context()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO])
	_add_admission_actor(rig,"blocker")
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["blocker"]),Vector2i.ZERO)
	var wave:Node=_waves(rig,["enemy"])
	rig.sim.configure_hex_ground_runtime(rig.map,rig.terrain)
	wave._process(46.0)
	_check(wave.get_current_wave_number()==0 and rig.sim.get_hex_unit_state("enemy").is_empty() and not rig.actors.enemy.visible,"old wave intent cannot admit into a later Root context")
	rig.scene.free()

func _test_actual_wave_reset()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO,Vector2i(1,0)])
	var wave:Node=_waves(rig,["enemy"])
	_check(wave.get_current_wave_number()==1 and not rig.sim.get_hex_unit_state("enemy").is_empty(),"real wave actor enters Ground through the staged admission path")
	wave.first_wave_delay_seconds=5.0
	wave.initialize_enemy_units([rig.actors.enemy])
	_check(rig.sim.get_hex_unit_state("enemy").is_empty() and not rig.units.has_unit("enemy") and not rig.actors.enemy.visible,"actual wave reinitialization releases old field before staging the same actor")
	var completion:Array=[]
	wave.all_waves_complete.connect(func():completion.append(true))
	wave.wave_started.connect(func(_number:int):wave.initialize_enemy_units([]))
	wave._process(5.0)
	_check(completion.is_empty() and wave.get_current_wave_number()==0 and wave._time_until_next_wave==5.0,"wave callback reinitialization preserves new timer and suppresses retired completion")
	rig.scene.free()

func _test_legacy_wave()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO])
	rig.map.set_tactical_grid_rules("")
	rig.sim.configure_hex_ground_runtime(rig.map,rig.terrain)
	var wave:Node=_waves(rig,["a","b"])
	_check(wave.get_current_wave_number()==1 and rig.units.has_unit("a") and rig.actors.a.visible and rig.sim.get_hex_ground_planning_snapshot().is_empty(),"unflagged actual wave retains legacy direct activation")
	rig.scene.free()
