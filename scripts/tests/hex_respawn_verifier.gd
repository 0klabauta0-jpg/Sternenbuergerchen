extends "res://scripts/tests/hex_ground_lifecycle_verifier.gd"

const RESPAWN=preload("res://scripts/core/respawn_manager.gd")
class MedicalActor extends "res://scripts/npc/test_unit.gd":
	func _ready()->void:pass

func _finish()->void:
	_test_fit_rejected()
	var probe=SIM.new()
	_check(probe.has_method("begin_hex_respawn") and probe.has_method("enqueue_hex_respawn") and probe.has_method("get_hex_respawn_receipt"),"actual Root owns begin ticket, enqueue and historical respawn receipt")
	probe.free()
	if failed==0:
		_test_blocked_and_commit()
		_test_stale_timer()
		_test_reentrant_commit()
		_test_missing_root()
		_test_pending_admission()
		_test_future_claim_and_cohort()
		_test_retired_context_and_actor()
		_test_ramp_and_old_commands()
		_test_lifecycle_only_callback()
		_test_begin_barrier_and_eligibility()
		_test_intervening_medical_and_manager()
		_test_respawn_ship_mask()
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0:print("HEX_RESPAWN_PASS")
	quit(0 if failed==0 else 1)

func _medical_rig()->Dictionary:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0)])
	var manager=RESPAWN.new()
	rig.scene.add_child(manager)
	manager.set_physics_process(false)
	manager.simulation_root_path=manager.get_path_to(rig.sim)
	manager.unit_registry_path=manager.get_path_to(rig.units)
	manager.set_spawn_position("blue",rig.terrain.grid_to_world(Vector2i(2,0)))
	rig.manager=manager
	var actor=MedicalActor.new()
	actor.unit_id="a"
	actor.team_id="blue"
	rig.scene.add_child(actor)
	actor.set_process(false)
	actor.set_physics_process(false)
	actor.set_respawn_manager(manager)
	actor.set_terrain_registry(rig.terrain)
	rig.units.register_unit("a",actor)
	rig.sim.register_known_unit("a",actor)
	rig.actors.a=actor
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["a"]),Vector2i.ZERO)
	return rig

func _test_fit_rejected()->void:
	var rig:Dictionary=_medical_rig()
	_check(not rig.manager.request_respawn("a","blue") and not rig.manager.has_pending_respawn("a") and rig.actors.a.get_vital_state()=="fit","actual manager rejects medically ineligible fit actor before creating a timer")
	rig.scene.free()

func _test_blocked_and_commit()->void:
	var rig:Dictionary=_medical_rig()
	_add_admission_actor(rig,"blocker")
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["blocker"]),Vector2i(2,0))
	rig.actors.a.apply_damage(1000)
	var started:Array=[]
	var complete:Array=[]
	rig.manager.unit_respawn_started.connect(func(id:String,_seconds:float):started.append(id))
	rig.manager.unit_respawn_completed.connect(func(id:String):complete.append(id))
	_check(rig.manager.request_respawn("a","blue") and started==["a"] and rig.actors.a.get_vital_state()=="respawning","actual Root begin commits medical model and timer before start publication")
	var ticket:String=rig.manager._pending_respawns.a.hex_ticket
	rig.manager._physics_process(30.0)
	_check(complete.is_empty() and rig.manager.has_pending_respawn("a") and rig.actors.a.get_vital_state()=="respawning","elapsed timer queues one attempt without announcing completion")
	rig.sim._physics_process(0.1)
	rig.manager._physics_process(0.1)
	_check(rig.sim.get_hex_respawn_receipt(ticket).status=="blocked" and rig.sim.get_hex_unit_state("a").grid==Vector2i.ZERO and complete.is_empty() and rig.manager.get_remaining_time("a")==0.0,"occupied respawn target leaves old field, medical state and timer pending at zero")
	var count:int=rig.sim.effects_queue.size()
	for i in range(5):rig.manager._physics_process(0.1)
	_check(rig.sim.effects_queue.size()==count,"unchanged blocked respawn does not queue repeated work")
	rig.sim.release_hex_ground_unit("blocker","fixture_spawn_clear")
	rig.manager._physics_process(0.1)
	rig.sim._physics_process(0.1)
	rig.manager._physics_process(0.1)
	_check(rig.sim.get_hex_respawn_receipt(ticket).status=="committed" and not rig.manager.has_pending_respawn("a") and complete==["a"],"actual commit receipt acknowledges completion exactly once after lifecycle advances")
	_check(rig.sim.get_hex_unit_state("a").grid==Vector2i(2,0) and rig.actors.a.global_position==rig.terrain.grid_to_world(Vector2i(2,0)) and rig.actors.a.get_vital_state()=="fit" and rig.actors.a.get_current_unit_command()==null and rig.sim.get_hex_movement_readout("a").is_empty(),"respawn publishes matching canonical world pose, field, Fit/Idle and cleared old order")
	rig.scene.free()

func _test_stale_timer()->void:
	var rig:Dictionary=_medical_rig()
	rig.actors.a.apply_damage(1000)
	rig.manager.request_respawn("a","blue")
	rig.sim.release_hex_ground_unit("a","fixture_old_lifecycle")
	var events:Array=[]
	rig.manager.unit_respawn_completed.connect(func(id:String):events.append(id))
	rig.manager._physics_process(30.0)
	rig.sim._physics_process(0.1)
	_check(events.is_empty() and not rig.manager.has_pending_respawn("a") and rig.sim.get_hex_unit_state("a").is_empty() and rig.actors.a.get_vital_state()=="respawning","retired timer cannot re-admit an actor from a later lifecycle")
	rig.scene.free()

func _test_reentrant_commit()->void:
	var rig:Dictionary=_medical_rig()
	rig.actors.a.apply_damage(1000)
	rig.manager.request_respawn("a","blue")
	var observations:Array=[]
	rig.actors.a.vital_status_changed.connect(func(_value):
		if rig.actors.a.get_vital_state()=="fit":
			observations.append(rig.sim.get_hex_unit_state("a").grid==Vector2i(2,0) and not rig.manager.has_pending_respawn("a") and rig.actors.a.get_current_unit_command()==null)
			observations.append(not rig.manager.request_respawn("a","blue")))
	rig.manager._physics_process(30.0)
	rig.sim._physics_process(0.1)
	_check(observations==[true,true],"first medical callback sees all owners committed and cannot create a duplicate respawn")
	rig.scene.free()

func _test_missing_root()->void:
	var rig:Dictionary=_medical_rig()
	rig.actors.a.apply_damage(1000)
	rig.manager.request_respawn("a","blue")
	rig.sim.free()
	rig.manager._physics_process(30.0)
	_check(not rig.manager.has_pending_respawn("a") and rig.actors.a.get_vital_state()=="respawning","removed concrete Root retires its old timer even when its node path is empty")
	rig.scene.free()

func _test_pending_admission()->void:
	var rig:Dictionary=_medical_rig()
	_add_admission_actor(rig,"aboard").set_meta("dropship_embarked",true)
	var reserved:Dictionary=rig.sim.prepare_hex_ground_deployment(PackedStringArray(["aboard"]),Vector2i(2,0))
	rig.actors.a.apply_damage(1000)
	rig.manager.request_respawn("a","blue")
	var ticket:String=rig.manager._pending_respawns.a.hex_ticket
	rig.manager._physics_process(30.0)
	rig.sim._physics_process(0.1)
	_check(reserved.ok and rig.sim.get_hex_respawn_receipt(ticket).status=="blocked" and rig.sim.get_hex_unit_state("a").grid==Vector2i.ZERO and rig.sim.get_hex_ground_planning_snapshot().admission_slots_by_grid.size()==1,"real pending deployment slot blocks respawn without consuming either claim")
	rig.sim.cancel_hex_ground_deployment(reserved.admission_id,"fixture_transport_abort")
	rig.manager._physics_process(0.1)
	rig.sim._physics_process(0.1)
	_check(rig.sim.get_hex_respawn_receipt(ticket).status=="committed","actual admission cancellation wakes the pending respawn")
	rig.scene.free()

func _move_request(id:String,path:Array)->Dictionary:
	return {"unit_id":id,"command_id":"claim_"+id,"priority":0,"path_grid_points":path,"duration_ticks_by_step":[100]}

func _test_future_claim_and_cohort()->void:
	for target in [Vector2i.ZERO,Vector2i(4,1)]:
		var cells:Array=[]
		for q in range(6):cells.append(Vector2i(q,0))
		cells.append(Vector2i(4,1))
		var rig:Dictionary=_admission_rig(cells)
		for id in ["a","b"]:_add_admission_actor(rig,id)
		var placements:Array[Dictionary]=[{"unit_id":"a","grid":Vector2i.ZERO},{"unit_id":"b","grid":Vector2i(1,0)}]
		rig.sim.admit_hex_ground_units(placements)
		var state=rig.sim._hex_ground_runtime
		var resolver=load("res://scripts/tactical/bottleneck_reservation_resolver.gd")
		var snapshot:Dictionary=state.build_planning_snapshot()
		var plan:Dictionary=resolver.build_hex_plan([_move_request("a",[Vector2i.ZERO,Vector2i(1,0)]),_move_request("b",[Vector2i(1,0),Vector2i(2,0)])],snapshot,rig.terrain)
		var committed:Dictionary=state.commit_plan(plan,snapshot.revision)
		snapshot=state.build_planning_snapshot()
		_check(committed.ok and snapshot.committed_corridor_grants.size()==1 and snapshot.committed_corridor_grants[0].unit_ids.size()==2,"pure respawn claim fixture has a real committed shared corridor cohort")
		_check(not state.relocate_unit("a",Vector2i(2,0),snapshot.revision).ok and state.build_planning_snapshot()==snapshot,"foreign future edge and cohort target reject relocation without partial mutation")
		var other:Array=[]
		for segment in snapshot.committed_segments:
			if segment.unit_id=="b":other.append(segment)
		var moved:Dictionary=state.relocate_unit("a",target,snapshot.revision)
		var after:Dictionary=state.build_planning_snapshot()
		_check(moved.ok and after.committed_segments==other and after.units_by_id.b==snapshot.units_by_id.b and after.committed_corridor_grants.size()==1 and after.committed_corridor_grants[0].unit_ids==["b"] and after.committed_corridor_grants[0].cells==snapshot.committed_corridor_grants[0].cells,"relocation preserves foreign commitments including own unchanged field: "+str(target))
		rig.scene.free()

func _test_retired_context_and_actor()->void:
	for kind in ["context","actor","queued_embark"]:
		var rig:Dictionary=_medical_rig()
		rig.actors.a.apply_damage(1000)
		rig.manager.request_respawn("a","blue")
		var events:Array=[]
		rig.manager.unit_respawn_completed.connect(func(id:String):events.append(id))
		if kind=="context":rig.sim.configure_hex_ground_runtime(rig.map,rig.terrain)
		elif kind=="actor":
			rig.sim.unregister_known_unit("a")
			rig.units.unregister_unit("a")
			rig.actors.a.free()
			var replacement=MedicalActor.new()
			replacement.unit_id="a"
			replacement.team_id="blue"
			rig.scene.add_child(replacement)
			replacement.set_physics_process(false)
			replacement.set_process(false)
			replacement.set_respawn_manager(rig.manager)
			rig.actors.a=replacement
			rig.units.register_unit("a",replacement)
			rig.sim.register_known_unit("a",replacement)
			rig.sim.admit_hex_ground_actor_group(PackedStringArray(["a"]),Vector2i.ZERO)
		else:
			rig.manager._physics_process(30.0)
			rig.sim.embark_hex_ground_actor_group(PackedStringArray(["a"]))
		rig.manager._physics_process(30.0)
		rig.sim._physics_process(0.1)
		_check(events.is_empty() and not rig.manager.has_pending_respawn("a") and (rig.actors.a.get_vital_state()=="fit" if kind=="actor" else rig.sim.get_hex_unit_state("a").is_empty()),"retired context, actor or queued embark cannot reuse old timer: "+kind)
		rig.scene.free()

func _test_ramp_and_old_commands()->void:
	var rig:Dictionary=_medical_rig()
	rig.terrain.get_tile_at_grid(Vector2i(2,0)).ramp_direction=0
	rig.terrain.notify_tile_data_changed([Vector2i(2,0)])
	var old_identity:Dictionary=rig.sim.call("_hex_payload_identity","a")
	rig.sim.enqueue_command(_command("a",rig.terrain.grid_to_world(Vector2i(1,0))))
	rig.actors.a.apply_damage(1000)
	rig.manager.request_respawn("a","blue")
	rig.manager._physics_process(30.0)
	rig.sim._physics_process(0.1)
	rig.sim.enqueue_command({"type":"hold_position","unit_id":"a","team_id":"blue","_hex_lifecycle":old_identity})
	rig.sim.enqueue_effect({"effect_type":"respawn","unit_id":"a","spawn_position":Vector2.ZERO})
	rig.sim._physics_process(0.1)
	_check(rig.sim.get_hex_unit_state("a").grid==Vector2i(2,0) and rig.sim.get_hex_unit_state("a").stand_height_steps2==1 and rig.actors.a.get_current_unit_command()==null and rig.sim.get_hex_movement_readout("a").is_empty(),"canonical half-height ramp respawn rejects old command generation and unticketed free respawn bypass")
	rig.scene.free()

func _test_lifecycle_only_callback()->void:
	var rig:Dictionary=_medical_rig()
	rig.actors.a.apply_damage(1000)
	rig.manager.request_respawn("a","blue")
	var runtime_signals:Array=[]
	var completed:Array=[]
	rig.actors.a.runtime_status_changed.connect(func(_status):runtime_signals.append(true))
	rig.manager.unit_respawn_completed.connect(func(id:String):completed.append(id))
	rig.actors.a.vital_status_changed.connect(func(_status):
		if rig.actors.a.get_vital_state()=="fit":
			rig.sim.release_hex_ground_unit("a","fixture_new_lifecycle")
			rig.sim.admit_hex_ground_actor_group(PackedStringArray(["a"]),Vector2i(1,0)))
	rig.manager._physics_process(30.0)
	rig.sim._physics_process(0.1)
	_check(runtime_signals.is_empty() and completed.is_empty() and rig.sim.get_hex_unit_state("a").grid==Vector2i(1,0),"same-context lifecycle replacement in first Vital callback stops stale Runtime/completion publication")
	rig.scene.free()

class ClientRoot extends SIM:
	var fixture_readonly:=false
	func _should_skip_local_tick_processing()->bool:return fixture_readonly

func _test_begin_barrier_and_eligibility()->void:
	var rig:Dictionary=_medical_rig()
	rig.actors.a.apply_damage(1000)
	var reads:Array=[]
	rig.actors.a.runtime_status_changed.connect(func(_status):
		var entry:Dictionary=rig.manager._pending_respawns.get("a",{})
		reads.append(not entry.is_empty() and rig.sim.get_hex_respawn_receipt(entry.hex_ticket).status=="pending" and rig.actors.a.get_vital_state()=="respawning" and rig.actors.a.get_current_unit_command()==null and rig.sim.get_hex_unit_state("a").grid==Vector2i.ZERO))
	_check(rig.manager.request_respawn("a","blue") and reads==[true],"first BEGIN Actor callback already sees Root ticket, medical reset, old field and Manager timer")
	rig.scene.free()
	for kind in ["team","aboard","authority"]:
		rig=_medical_rig()
		rig.actors.a.apply_damage(1000)
		if kind=="aboard":rig.sim.embark_hex_ground_actor_group(PackedStringArray(["a"]))
		if kind=="authority":
			rig.sim.set_script(ClientRoot)
			rig.sim.unit_registry_path=rig.sim.get_path_to(rig.units)
			rig.sim.terrain_registry_path=rig.sim.get_path_to(rig.terrain)
			rig.sim.configure_hex_ground_runtime(rig.map,rig.terrain)
			rig.sim.register_known_unit("a",rig.actors.a)
			rig.sim.admit_hex_ground_actor_group(PackedStringArray(["a"]),Vector2i.ZERO)
			rig.sim.fixture_readonly=true
		var before:Dictionary=rig.sim.get_hex_ground_planning_snapshot()
		_check(not rig.manager.request_respawn("a","red" if kind=="team" else "blue") and not rig.manager.has_pending_respawn("a") and rig.actors.a.get_vital_state()=="down" and rig.sim.get_hex_ground_planning_snapshot()==before,"medical eligibility rejects before any owner mutation: "+kind)
		rig.scene.free()

func _test_intervening_medical_and_manager()->void:
	for kind in ["damage","root_binding","registry_binding"]:
		var rig:Dictionary=_medical_rig()
		rig.actors.a.apply_damage(1000)
		rig.manager.request_respawn("a","blue")
		var events:Array=[]
		rig.manager.unit_respawn_completed.connect(func(id:String):events.append(id))
		var foreign=Node.new()
		rig.scene.add_child(foreign)
		rig.actors.a.vital_status_changed.connect(func(_status):
			if rig.actors.a.get_vital_state()=="fit":
				if kind=="damage":rig.actors.a.apply_damage(1000)
				elif kind=="root_binding":rig.manager.simulation_root_path=rig.manager.get_path_to(foreign)
				else:rig.manager.unit_registry_path=rig.manager.get_path_to(foreign))
		rig.manager._physics_process(30.0)
		rig.sim._physics_process(0.1)
		_check(events.is_empty() and not rig.manager.has_pending_respawn("a") and rig.sim.get_hex_unit_state("a").grid==Vector2i(2,0),"committed respawn suppresses stale Ready after callback intervention: "+kind)
		rig.scene.free()
	var rig:Dictionary=_medical_rig()
	rig.actors.a.apply_damage(1000)
	var invoked:Array=[]
	var started:Array=[]
	rig.manager.unit_respawn_started.connect(func(id:String,_seconds:float):started.append(id))
	rig.actors.a.runtime_status_changed.connect(func(_status):
		if invoked.is_empty():
			invoked.append(true)
			rig.actors.a.set_target_position(Vector2(11,12)))
	rig.manager.request_respawn("a","blue")
	_check(invoked==[true] and started.is_empty() and rig.manager.has_pending_respawn("a"),"intervening BEGIN runtime replacement suppresses obsolete Started publication")
	rig.scene.free()

class RespawnShipMask extends Node:
	var registry_id:=0
	var blocked:Array[Vector2i]=[]
	func get_ground_ship_blocked_cells()->Dictionary:return {"ok":true,"registry_id":registry_id,"source_signature":str(blocked),"blocked_cells":blocked.duplicate()}

func _test_respawn_ship_mask()->void:
	var rig:Dictionary=_medical_rig()
	var ship=RespawnShipMask.new()
	ship.name="TacticalController"
	ship.registry_id=rig.terrain.get_instance_id()
	rig.scene.add_child(ship)
	rig.actors.a.apply_damage(1000)
	rig.manager.request_respawn("a","blue")
	var ticket:String=rig.manager._pending_respawns.a.hex_ticket
	var completed:Array=[]
	rig.manager.unit_respawn_completed.connect(func(id:String):completed.append(id))
	rig.manager._physics_process(30.0)
	ship.blocked.append(Vector2i(2,0))
	rig.sim._physics_process(0.1)
	rig.manager._physics_process(0.1)
	_check(rig.sim.get_hex_respawn_receipt(ticket).status=="blocked" and rig.sim.get_hex_unit_state("a").grid==Vector2i.ZERO and completed.is_empty() and rig.sim.effects_queue.is_empty(),"accepted foreign ship body appearing after enqueue blocks respawn without repeated unchanged work")
	ship.blocked.clear()
	rig.manager._physics_process(0.1)
	rig.sim._physics_process(0.1)
	_check(rig.sim.get_hex_respawn_receipt(ticket).status=="committed" and completed==["a"],"ship footprint change alone wakes the blocked respawn")
	rig.scene.free()
