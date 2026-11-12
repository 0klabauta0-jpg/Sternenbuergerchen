extends "res://scripts/tests/hex_mission_setup_verifier.gd"

const LEADER=preload("res://scripts/ftl/runtime_leader.gd")
class SelectionActor extends "res://scripts/npc/test_unit.gd":
	func _ready()->void:pass

class SelectionSetup extends Setup:
	var refreshed:PackedStringArray=PackedStringArray()
	func _apply_fob_loadout_override(unit,id:String,unit_team_id:String)->void:
		refreshed.append(id)
		super._apply_fob_loadout_override(unit,id,unit_team_id)

func _run()->void:
	_test_reordered_selection()
	_test_removed_selection()
	_test_invalid_selection()
	_test_new_selection(false)
	_test_new_selection(true)
	_test_identity_barrier()
	_test_owner_changes()
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0:print("HEX_RUNTIME_SELECTION_PASS")
	quit(0 if failed==0 else 1)

func _selection_rig(ids:PackedStringArray=PackedStringArray(["a","b"]))->Dictionary:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0),Vector2i(3,0)])
	var setup=SelectionSetup.new()
	rig.scene.add_child(setup)
	setup.set_process(false)
	setup._is_initialized=true
	setup._hex_setup_required=true
	setup._loaded_terrain_map_data=rig.map
	setup.fixture_terrain=rig.terrain
	setup.simulation_root_path=setup.get_path_to(rig.sim)
	setup.unit_registry_path=setup.get_path_to(rig.units)
	setup.terrain_registry_path=setup.get_path_to(rig.terrain)
	setup.team_id="blue"
	setup.use_2_5d_primary_view=false
	setup.defer_friendly_runtime_activation=false
	setup.selected_team_unit_ids=ids.duplicate()
	setup.selected_team_unit_configs=[{"unit_id":"a","display_name":"A"},{"unit_id":"b","display_name":"B"},{"unit_id":"c","display_name":"C"}]
	var leader=LEADER.new()
	rig.scene.add_child(leader)
	setup.runtime_leader_path=setup.get_path_to(leader)
	var ftls=load("res://scripts/registries/ftl_registry.gd").new()
	rig.scene.add_child(ftls)
	setup.ftl_registry_path=setup.get_path_to(ftls)
	var marker=Marker2D.new()
	rig.scene.add_child(marker)
	marker.position=rig.terrain.grid_to_world(Vector2i(2,0))
	setup.spawn_alpha_path=setup.get_path_to(marker)
	var live:=PackedStringArray()
	for index in range(2):
		var actor=SelectionActor.new()
		actor.unit_id=ids[index] if index<ids.size() else "__unused_friendly_slot_%d"%index
		actor.team_id="blue" if index<ids.size() else "team_unused"
		actor.fireteam_id="ft1"
		rig.scene.add_child(actor)
		actor.set_process(false)
		actor.set_physics_process(false)
		actor.set_runtime_status("idle")
		setup.unit_paths.append(setup.get_path_to(actor))
		setup._friendly_unit_slot_paths.append(setup.get_path_to(actor))
		rig.actors[actor.unit_id]=actor
		if index<ids.size():
			rig.units.register_unit(actor.unit_id,actor)
			rig.sim.register_known_unit(actor.unit_id,actor)
			leader.add_unit_member(actor)
			live.append(actor.unit_id)
		else:actor.visible=false
	rig.sim.admit_hex_ground_actor_group(live,Vector2i.ZERO)
	rig.setup=setup
	rig.leader=leader
	return rig

func _test_reordered_selection()->void:
	var rig:Dictionary=_selection_rig()
	rig.actors.a.apply_damage(31)
	rig.sim.enqueue_command(_command("a",rig.terrain.grid_to_world(Vector2i(3,0))))
	rig.sim._physics_process(0.1)
	var snapshot:Dictionary=rig.sim.get_hex_ground_planning_snapshot()
	var command=rig.actors.a.get_current_unit_command()
	var health:int=rig.actors.a.get_health()
	rig.setup.selected_team_unit_ids=PackedStringArray(["b","a"])
	rig.setup.apply_runtime_selection_contract(true)
	_check(rig.units.get_unit("a")==rig.actors.a and rig.units.get_unit("b")==rig.actors.b and rig.actors.a.unit_id=="a" and rig.actors.b.unit_id=="b","reordering selection preserves actual person-to-actor identity")
	_check(rig.sim.get_hex_ground_planning_snapshot()==snapshot and rig.actors.a.get_current_unit_command()==command and rig.actors.a.get_health()==health,"reordering preserves existing claims, health and accepted movement")
	rig.scene.free()

func _test_identity_barrier()->void:
	var rig:Dictionary=_selection_rig()
	rig.sim.enqueue_command(_command("a",rig.terrain.grid_to_world(Vector2i(3,0))))
	rig.sim._physics_process(0.1)
	var observations:Array=[]
	for actor in [rig.actors.a,rig.actors.b]:
		actor.identity_changed.connect(func():
			observations.append(rig.sim._resolve_known_unit_for_contract("c")==rig.actors.a and rig.units.get_unit("c")==rig.actors.a and rig.actors.a.get_runtime_status().unit_id=="c" and rig.actors.a.get_current_unit_command()==null and rig.actors.b.unit_id.begins_with("__unused") and rig.actors.b.get_current_unit_command()==null and not rig.units.has_unit("a") and not rig.units.has_unit("b")))
	rig.setup.selected_team_unit_ids=PackedStringArray(["c"])
	rig.setup.apply_runtime_selection_contract(true)
	_check(not observations.is_empty() and not observations.has(false),"every identity callback sees all actor models and Root/Registry bindings already committed")
	rig.scene.free()

func _test_owner_changes()->void:
	for mode in ["queued_root","registry"]:
		var rig:Dictionary=_selection_rig()
		var old_position:Vector2=rig.actors.a.global_position
		var callback_once:Array=[false]
		var replacement:Node
		if mode=="queued_root":
			replacement=SIM.new()
			rig.scene.add_child(replacement)
			replacement.unit_registry_path=replacement.get_path_to(rig.units)
			replacement.terrain_registry_path=replacement.get_path_to(rig.terrain)
			replacement.configure_hex_ground_runtime(rig.map,rig.terrain)
		else:
			replacement=UNITS.new()
			rig.scene.add_child(replacement)
		rig.actors.a.identity_changed.connect(func():
			if callback_once[0]:return
			callback_once[0]=true
			if mode=="queued_root":
				rig.setup.selected_team_unit_ids=PackedStringArray(["b"])
				rig.setup.apply_runtime_selection_contract(true)
				rig.setup.simulation_root_path=rig.setup.get_path_to(replacement)
			else:rig.sim.unit_registry_path=rig.sim.get_path_to(replacement))
		rig.setup.selected_team_unit_ids=PackedStringArray(["c"])
		rig.setup.apply_runtime_selection_contract(true)
		if mode=="queued_root":
			_check(replacement.get_hex_ground_planning_snapshot().units_by_id.is_empty() and replacement._resolve_known_unit_for_contract("b")==null and rig.actors.a.unit_id=="c","reentrant queued selection cannot cross into a replacement Root with equal numeric context")
		else:
			_check(rig.actors.a.global_position==old_position and not rig.leader.get_assigned_units().has(rig.actors.a),"registry replacement during identity publication stops cached pose and leader tails")
		rig.scene.free()

func _test_removed_selection()->void:
	var rig:Dictionary=_selection_rig()
	rig.actors.b.apply_damage(27)
	rig.sim.enqueue_command(_command("b",rig.terrain.grid_to_world(Vector2i(3,0))))
	rig.sim._physics_process(0.1)
	var a_before:Dictionary=rig.sim.get_hex_unit_state("a")
	var vital=rig.actors.b._vital_status
	var b=rig.actors.b
	rig.setup.selected_team_unit_ids=PackedStringArray(["a"])
	rig.setup.apply_runtime_selection_contract(true)
	_check(rig.sim.get_hex_unit_state("b").is_empty() and rig.sim.get_hex_movement_readout("b").is_empty() and rig.sim._resolve_known_unit_for_contract("b")==null and not rig.units.has_unit("b"),"removing a selected member retires Ground, movement and both lookup bindings")
	_check(b.get_current_unit_command()==null and b.get_runtime_status().status=="idle" and b._vital_status==vital and b.get_health()==73,"retired slot loses old command without changing its actual medical model or HP")
	_check(rig.sim.get_hex_unit_state("a")==a_before and rig.units.get_unit("a")==rig.actors.a,"removing buddy does not reset the remaining member")
	_check(not rig.leader.get_assigned_units().has(b),"retired actor also leaves existing RuntimeLeader lookup")
	rig.scene.free()

func _test_invalid_selection()->void:
	for mode in ["duplicate","foreign","capacity"]:
		var rig:Dictionary=_selection_rig()
		var before:Dictionary=rig.sim.get_hex_ground_planning_snapshot()
		if mode=="duplicate":rig.setup.selected_team_unit_ids=PackedStringArray(["a","a"])
		elif mode=="capacity":rig.setup.selected_team_unit_ids=PackedStringArray(["a","b","c"])
		else:
			var foreign=Node2D.new()
			rig.scene.add_child(foreign)
			rig.units.register_unit("c",foreign)
			rig.setup.selected_team_unit_ids=PackedStringArray(["a","c"])
		rig.setup.apply_runtime_selection_contract(true)
		_check(rig.sim.get_hex_ground_planning_snapshot()==before and rig.actors.a.unit_id=="a" and rig.actors.b.unit_id=="b" and rig.units.get_unit("b")==rig.actors.b,"invalid whole selection rejects before writes: %s"%mode)
		rig.scene.free()

func _test_new_selection(deferred:bool)->void:
	var rig:Dictionary=_selection_rig(PackedStringArray(["a"]))
	var context:int=rig.sim.get_hex_ground_context_revision()
	rig.setup.defer_friendly_runtime_activation=deferred
	rig.setup.selected_team_unit_ids=PackedStringArray(["a","c"])
	rig.setup.apply_runtime_selection_contract(true)
	var actor=rig.sim._resolve_known_unit_for_contract("c")
	if deferred:
		_check(is_instance_valid(actor) and not actor.visible and not rig.units.has_unit("c") and rig.sim.get_hex_unit_state("c").is_empty(),"new deferred person stays known and hidden without runtime admission")
	else:
		_check(is_instance_valid(actor) and rig.units.get_unit("c")==actor and not rig.sim.get_hex_unit_state("c").is_empty() and actor.visible,"new direct person becomes visible only through actual Root field admission")
	_check(rig.sim.get_hex_ground_context_revision()==context and rig.units.get_unit("a")==rig.actors.a,"selection refresh does not reconfigure the Root or replace an existing visit member")
	rig.scene.free()
