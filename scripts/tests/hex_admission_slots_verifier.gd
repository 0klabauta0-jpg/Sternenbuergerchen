extends "res://scripts/tests/hex_ground_lifecycle_verifier.gd"

func _finish()->void:
	if failed==0:
		_test_group_admission()
		_test_admission_ramps()
		_test_active_edge_admission()
	var probe=SIM.new()
	_check(probe.has_method("prepare_hex_ground_deployment"),"Root offers ground-owned slots for phased deployment")
	probe.free()
	if failed==0:
		_test_phased_deployment()
		_test_staged_actor_and_terrain()
		_test_stale_lifecycle_queue()
		_test_actual_despawn()
		_test_stale_registry_entry()
		_test_pending_group_cleanup()
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0:print("HEX_ADMISSION_SLOTS_PASS")
	quit(0 if failed==0 else 1)

func _test_phased_deployment()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0),Vector2i(3,0),Vector2i(0,1),Vector2i(1,1)])
	var ids:=PackedStringArray(["one","two","three","four"])
	for id in ids:
		var actor:Node2D=_add_admission_actor(rig,id)
		actor.visible=false
		actor.set_meta("dropship_embarked",true)
	var sim=rig.sim
	var prepared:Dictionary=sim.prepare_hex_ground_deployment(ids,Vector2i.ZERO)
	var snapshot:Dictionary=sim.get_hex_ground_planning_snapshot()
	_check(prepared.ok and snapshot.units_by_id.is_empty() and snapshot.admission_slots_by_grid.size()==4,"preparation reserves all group slots without pretending aboard people are on ground")
	if not prepared.ok:
		rig.scene.free()
		return
	var ticket:String=prepared.admission_id
	_check(not sim.can_block_hex_ground_cells([Vector2i.ZERO],rig.terrain).can_block,"door mutation respects pending deployment slot")
	var intruder:Array[Dictionary]=[{"unit_id":"intruder","grid":Vector2i.ZERO}]
	_check(not sim.admit_hex_ground_units(intruder).ok and sim.get_hex_ground_planning_snapshot()==snapshot,"direct admission cannot steal a pending slot")
	sim.enqueue_effect({"effect_type":"dropship_deploy_unit","unit_id":"one","admission_id":ticket,"runtime_active":true})
	sim._physics_process(0.1)
	var state:Dictionary=sim.get_hex_unit_state("one")
	_check(not state.is_empty() and sim.get_hex_ground_planning_snapshot().units_by_id.size()==1 and sim.get_hex_ground_planning_snapshot().admission_slots_by_grid.size()==3,"one real deploy effect consumes only its owned slot")
	_check(rig.actors.one.visible and not rig.actors.one.get_meta("dropship_embarked") and not rig.actors.two.visible and rig.actors.two.get_meta("dropship_embarked"),"visual and aboard state follow individual committed unload phase")
	var after:Dictionary=sim.get_hex_ground_planning_snapshot()
	sim.enqueue_effect({"effect_type":"dropship_deploy_unit","unit_id":"two","admission_id":"wrong-ticket","runtime_active":true})
	sim._physics_process(0.1)
	_check(sim.get_hex_unit_state("two").is_empty() and rig.actors.two.get_meta("dropship_embarked") and sim.get_hex_ground_planning_snapshot().admission_slots_by_grid==after.admission_slots_by_grid,"wrong deployment ticket changes neither slots nor person presence")
	var other_grid:Vector2i=sim.get_hex_ground_planning_snapshot().admission_slots_by_grid.keys()[0]
	_add_admission_actor(rig,"walker")
	var walker:Array[Dictionary]=[{"unit_id":"walker","grid":Vector2i(1,1)}]
	sim.admit_hex_ground_units(walker)
	sim.enqueue_command(_command("walker",rig.terrain.grid_to_world(other_grid)))
	for i in range(4):sim._physics_process(0.1)
	_check(sim.get_hex_unit_state("walker").grid==Vector2i(1,1) and sim.get_hex_ground_planning_snapshot().committed_segments.is_empty(),"actual navigation cannot move a ground actor into pending deployment slots")
	var before_forgery:Dictionary=sim.get_hex_ground_planning_snapshot()
	var forged:Dictionary={"ok":true,"expected_revision":before_forgery.revision,"terrain_revision":before_forgery.terrain_revision,"corridor_grants":[],"accepted_steps":[{"unit_id":"walker","command_id":"forged","from_grid":Vector2i(1,1),"to_grid":other_grid,"start_tick":sim.tick_counter,"handoff_tick":sim.tick_counter+1,"duration_ticks":2}]}
	var rejected:Dictionary=sim.commit_hex_ground_plan(forged,before_forgery.revision)
	_check(not rejected.ok and rejected.reason=="admission_reserved" and sim.get_hex_ground_planning_snapshot()==before_forgery,"owner independently rejects forged motion across pending admission slot")
	var cancelled:Dictionary=sim.cancel_hex_ground_deployment(ticket,"transport_aborted")
	_check(cancelled.ok and sim.get_hex_ground_planning_snapshot().admission_slots_by_grid.is_empty() and not sim.get_hex_unit_state("one").is_empty() and sim.get_hex_unit_state("two").is_empty(),"abort releases only remaining aboard slots, keeps deployed ground people")
	sim.enqueue_effect({"effect_type":"dropship_embark_unit","unit_id":"one"})
	sim._physics_process(0.1)
	_check(sim.get_hex_unit_state("one").is_empty() and not rig.actors.one.visible and rig.actors.one.get_meta("dropship_embarked"),"actual embark effect releases ground through lifecycle owner")
	for i in range(16):sim._physics_process(0.1)
	_check(sim.has_hex_destination_arrived("walker","move_walker"),"cancel wakes original waiting movement after reserved slot is released")
	var unbooked:Dictionary=sim.prepare_hex_ground_deployment(PackedStringArray(["one","two"]),Vector2i.ZERO)
	_check(unbooked.ok,"cancelled slots can be planned again without losing crew")
	if unbooked.ok:
		sim.configure_hex_ground_runtime(rig.map,rig.terrain)
		_check(sim.get_hex_ground_planning_snapshot().admission_slots_by_grid.is_empty() and not sim.get_hex_ground_deployment(unbooked.admission_id).ok,"context change invalidates old deployment tickets")
	rig.scene.free()

func _test_staged_actor_and_terrain()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0)])
	var actor=Actor.new()
	actor.unit_id="staged"
	actor.visible=false
	actor.set_meta("dropship_embarked",true)
	rig.scene.add_child(actor)
	rig.sim.register_known_unit("staged",actor)
	var prepared:Dictionary=rig.sim.prepare_hex_ground_deployment(PackedStringArray(["staged"]),Vector2i.ZERO)
	_check(prepared.ok and not rig.units.has_unit("staged"),"staged real mission actor can reserve a slot before runtime registration")
	if prepared.ok:
		rig.sim.enqueue_effect({"effect_type":"dropship_deploy_unit","unit_id":"staged","admission_id":prepared.admission_id,"runtime_active":true})
		rig.sim._physics_process(0.1)
		_check(rig.units.get_unit("staged")==actor and not rig.sim.get_hex_unit_state("staged").is_empty() and actor.visible,"actual deploy activates staged actor only after its slot commits")
	rig.sim.embark_hex_ground_actor_group(PackedStringArray(["staged"]))
	var pending:Dictionary=rig.sim.prepare_hex_ground_deployment(PackedStringArray(["staged"]),Vector2i.ZERO)
	if pending.ok:
		rig.terrain.get_tile_at_grid(Vector2i.ZERO).walkable=false
		rig.terrain.notify_tile_data_changed([Vector2i.ZERO])
		rig.sim.enqueue_effect({"effect_type":"dropship_deploy_unit","unit_id":"staged","admission_id":pending.admission_id})
		rig.sim._physics_process(0.1)
		_check(rig.sim.get_hex_unit_state("staged").is_empty() and actor.get_meta("dropship_embarked") and rig.sim.get_hex_ground_planning_snapshot().admission_slots_by_grid.is_empty(),"invalidated entry cancels group slots before queued deploy can publish a person")
	rig.scene.free()

func _test_stale_lifecycle_queue()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0)])
	_add_admission_actor(rig,"person")
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["person"]),Vector2i.ZERO)
	rig.sim.enqueue_command(_command("person",rig.terrain.grid_to_world(Vector2i(2,0))))
	rig.sim.enqueue_effect({"effect_type":"dropship_embark_unit","unit_id":"person"})
	rig.sim.configure_hex_ground_runtime(rig.map,rig.terrain)
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["person"]),Vector2i.ZERO)
	rig.sim._physics_process(0.1)
	_check(not rig.sim.get_hex_unit_state("person").is_empty() and rig.sim.get_hex_unit_state("person").grid==Vector2i.ZERO and rig.sim.get_hex_movement_readout("person").is_empty() and rig.actors.person.visible,"old context queued move and embark cannot mutate a newly admitted person")
	# Same map/context can release and readmit the same actor before a queued
	# old effect executes; this needs a per-person lifecycle generation too.
	if rig.sim.get_hex_unit_state("person").is_empty():rig.sim.admit_hex_ground_actor_group(PackedStringArray(["person"]),Vector2i.ZERO)
	rig.sim.enqueue_effect({"effect_type":"dropship_embark_unit","unit_id":"person"})
	rig.sim.embark_hex_ground_actor_group(PackedStringArray(["person"]))
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["person"]),Vector2i.ZERO)
	rig.sim._physics_process(0.1)
	_check(not rig.sim.get_hex_unit_state("person").is_empty() and rig.actors.person.visible,"queued previous lifecycle embark cannot hide a readmitted actor in same context")
	rig.scene.free()

func _test_actual_despawn()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO,Vector2i(1,0)])
	var actor:Node2D=_add_admission_actor(rig,"gone")
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["gone"]),Vector2i.ZERO)
	rig.sim.enqueue_command(_command("gone",rig.terrain.grid_to_world(Vector2i(1,0))))
	actor.free()
	_check(rig.sim.get_hex_unit_state("gone").is_empty() and not rig.units.has_unit("gone"),"actual actor tree exit releases its ground and registry without polling")
	var snapshot:Dictionary=rig.sim.get_hex_ground_planning_snapshot()
	rig.sim.unregister_known_unit("gone")
	_check(snapshot==rig.sim.get_hex_ground_planning_snapshot() and rig.sim.command_queue.is_empty(),"explicit cleanup after tree exit is idempotent and has no stale move")
	rig.scene.free()

func _test_stale_registry_entry()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO])
	# A broken external owner left a key whose actor never had a Root binding.
	var old=Actor.new()
	old.unit_id="replacement"
	rig.scene.add_child(old)
	rig.units.register_unit("replacement",old)
	old.free()
	var replacement=Actor.new()
	replacement.unit_id="replacement"
	replacement.visible=false
	rig.scene.add_child(replacement)
	rig.sim.register_known_unit("replacement",replacement)
	var before:Dictionary=rig.sim.get_hex_ground_planning_snapshot()
	var prepared:Dictionary=rig.sim.prepare_hex_ground_deployment(PackedStringArray(["replacement"]),Vector2i.ZERO)
	_check(not prepared.ok and rig.sim.get_hex_ground_planning_snapshot()==before and not replacement.visible,"stale registry key rejects staged replacement before any ground write")
	rig.scene.free()

func _test_pending_group_cleanup()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO,Vector2i(1,0)])
	for id in ["gone","stays"]:
		var actor:Node2D=_add_admission_actor(rig,id)
		actor.visible=false
		actor.set_meta("dropship_embarked",true)
	var group:Dictionary=rig.sim.prepare_hex_ground_deployment(PackedStringArray(["gone","stays"]),Vector2i.ZERO)
	rig.actors.gone.free()
	_check(group.ok and rig.sim.get_hex_ground_planning_snapshot().admission_slots_by_grid.is_empty() and rig.units.has_unit("stays") and not rig.actors.stays.visible,"actual pending NPC removal cancels whole remaining group without losing aboard peer")
	var next:Dictionary=rig.sim.prepare_hex_ground_deployment(PackedStringArray(["stays"]),Vector2i.ZERO)
	rig.sim.release_hex_ground_unit("stays","")
	_check(next.ok and rig.sim.get_hex_ground_planning_snapshot().admission_slots_by_grid.is_empty(),"internal release with empty legacy reason still clears pending slots")
	rig.scene.free()
