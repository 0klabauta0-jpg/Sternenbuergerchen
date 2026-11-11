extends "res://scripts/tests/hex_deployment_phase_verifier.gd"

class Sandbox:
	extends "res://scripts/tests/mission_tactical_sandbox_controller.gd"
	var fixture_crew:Array=[]
	var fixture_lz:=Vector2.ZERO
	var fixture_map:RefCounted
	func _ready()->void:pass
	func _update_ui(_include_heavy_surfaces:bool=true,_force_heavy_surfaces:bool=true)->void:pass
	func _can_deploy_parked_campaign_crew(_craft_id:String)->bool:return true
	func _get_campaign_sortie_units()->Array:return fixture_crew
	func _find_mission_dropship_card_entry(_craft_id:String)->Dictionary:return {"approach_angle":"NW"}
	func _campaign_landed_craft_position(_craft_id:String)->Vector2:return fixture_lz
	func _store_selected_mission_dropship_plan()->void:pass
	func _emit_planning_state_changed()->void:pass
	func _refresh_world_overlays()->void:pass
	func _flush_mission_dropship_runtime_feedback(_force:bool=false,_refresh_world_when_deferred:bool=true)->bool:return false
	func _get_active_mission_terrain_map_data_for_readability():return fixture_map
	func get_local_command_team_id(_units:Array=[])->String:return "blue"

class CrewActor extends Actor:
	func get_fireteam_id()->String:return ""

func _finish()->void:
	if failed==0:
		_test_phase_bridge()
		_test_actual_controller()
		_test_parked_crew_request()
		_test_primary_sequence_handoff()
		_test_unload_cadence()
		_test_parallel_visit_retirement()
		_test_retirement_after_root_commit()
		_test_hex_owner_unavailable()
		_test_legacy_unload()
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0:print("HEX_DEPLOYMENT_CONTROLLER_PASS")
	quit(0 if failed==0 else 1)

func _test_actual_controller()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)])
	rig.sim.name="SimulationRoot"
	var controller=Sandbox.new()
	rig.scene.add_child(controller)
	controller.set_process(false)
	controller.set_physics_process(false)
	var actors:Array=[]
	for id in ["first","second"]:
		var actor:Node2D=_add_admission_actor(rig,id)
		actor.visible=false
		actor.set_meta("dropship_embarked",true)
		actors.append(actor)
		controller._embarked_unit_ids[id]=true
	var anchor:Vector2=-controller._get_unload_offset(0,"NW")
	var sequence:Dictionary={"units":actors,"unit_index":0,"embarked_unit_ids":{"first":true,"second":true},"lz_position":anchor,"approach_angle":"NW"}
	controller._deploy_next_embarked_unit_for_sequence(sequence)
	var held:bool=sequence.unit_index==0 and controller._deployed_unit_ids.is_empty() and controller._embarked_unit_ids.size()==2
	_check(held,"actual controller does not publish deployment or advance sequence on queue acceptance")
	if not held:
		rig.scene.free()
		return
	rig.sim._physics_process(0.1)
	controller._deploy_next_embarked_unit_for_sequence(sequence)
	_check(sequence.unit_index==1 and controller._deployed_unit_ids.has("first") and controller._embarked_unit_ids.has("second") and not controller._embarked_unit_ids.has("first"),"actual controller publishes only the individually committed NPC")
	controller._deploy_next_embarked_unit_for_sequence(sequence)
	_check(sequence.unit_index==1 and not controller._deployed_unit_ids.has("second"),"actual controller preserves next unload phase until its Root commit")
	rig.sim._physics_process(0.1)
	controller._deploy_next_embarked_unit_for_sequence(sequence)
	_check(sequence.unit_index==2 and controller._deployed_unit_ids.size()==2 and controller._embarked_unit_ids.is_empty(),"actual controller completes after both independent real effects")
	rig.scene.free()

func _test_primary_sequence_handoff()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)])
	rig.sim.name="SimulationRoot"
	var controller=Sandbox.new()
	rig.scene.add_child(controller)
	controller.set_process(false)
	controller.set_physics_process(false)
	controller._drop_sequence_craft_id="primary"
	controller._drop_sequence_phase=controller.DROP_SEQUENCE_UNLOADING
	controller._drop_sequence_lz_position=-controller._get_unload_offset(0,"NW")
	for id in ["first","second"]:
		var actor:Node2D=_add_admission_actor(rig,id)
		actor.visible=false
		actor.set_meta("dropship_embarked",true)
		controller._drop_sequence_units.append(actor)
		controller._embarked_unit_ids[id]=true
		controller._drop_sequence_embarked_unit_ids[id]=true
	controller._deploy_next_embarked_unit()
	var ticket:String=String(controller._drop_sequence_hex_admission.get("admission_id",""))
	_check(not ticket.is_empty() and controller._drop_sequence_unit_index==0 and rig.sim.get_hex_ground_deployment(ticket).ok,"primary sequence holds only a ticket while first effect is pending")
	var captured:Dictionary=controller._capture_active_drop_sequence()
	captured.hex_admission.pending_unit_id="foreign"
	_check(controller._drop_sequence_hex_admission.pending_unit_id=="first","capturing primary sequence detaches its receipt")
	var transferred:bool=controller._store_primary_drop_sequence_as_parallel()
	var sequence:Dictionary=controller._parallel_drop_sequences_by_craft.get("primary",{})
	_check(transferred and controller._drop_sequence_hex_admission.is_empty() and rig.sim.get_hex_ground_deployment(ticket).ok and sequence.hex_admission.admission_id==ticket,"primary-to-parallel handoff preserves the actual pending group instead of cancelling it")
	rig.sim._physics_process(0.1)
	controller._deploy_next_embarked_unit_for_sequence(sequence)
	_check(sequence.unit_index==1 and controller._deployed_unit_ids.has("first"),"transferred sequence confirms the original queued phase exactly once")
	load(PHASE_PATH).new().cancel(rig.sim,sequence,"fixture_transport_abort")
	_check(rig.sim.get_hex_ground_planning_snapshot().admission_slots_by_grid.is_empty() and not rig.sim.get_hex_unit_state("first").is_empty(),"aborting remaining transferred phase keeps its already deployed person")
	rig.scene.free()

func _test_unload_cadence()->void:
	for primary in [false,true]:
		var rig:Dictionary=_admission_rig([Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)])
		rig.sim.name="SimulationRoot"
		var controller=Sandbox.new()
		rig.scene.add_child(controller)
		controller.set_process(false)
		controller.set_physics_process(false)
		var crew:Array=[]
		for id in ["first","second"]:
			var actor:Node2D=_add_admission_actor(rig,id)
			actor.visible=false
			actor.set_meta("dropship_embarked",true)
			crew.append(actor)
			controller._embarked_unit_ids[id]=true
		var lz:Vector2=-controller._get_unload_offset(0,"NW")
		var sequence:Dictionary={"units":crew,"unit_index":0,"embarked_unit_ids":{"first":true,"second":true},"lz_position":lz,"approach_angle":"NW","timer":0.0}
		if primary:
			controller._drop_sequence_units=crew
			controller._drop_sequence_embarked_unit_ids=sequence.embarked_unit_ids
			controller._drop_sequence_lz_position=lz
			controller._advance_primary_drop_sequence_unloading(controller.DROP_UNLOAD_INTERVAL_SECONDS)
		else:controller._advance_drop_sequence_unloading_for_sequence(sequence,controller.DROP_UNLOAD_INTERVAL_SECONDS)
		rig.sim._physics_process(0.1)
		if primary:controller._advance_primary_drop_sequence_unloading(controller.DROP_UNLOAD_INTERVAL_SECONDS)
		else:controller._advance_drop_sequence_unloading_for_sequence(sequence,controller.DROP_UNLOAD_INTERVAL_SECONDS)
		var second_queued:=false
		for effect in rig.sim.effects_queue:
			if effect.get("effect_type","")=="dropship_deploy_unit" and effect.get("unit_id","")=="second":second_queued=true
		_check(second_queued,"commit confirmation preserves existing unload interval for primary=%s"%primary)
		rig.sim._physics_process(0.1)
		if primary:controller._advance_primary_drop_sequence_unloading(0.0)
		else:controller._advance_drop_sequence_unloading_for_sequence(sequence,0.0)
		var index:int=controller._drop_sequence_unit_index if primary else int(sequence.unit_index)
		_check(index==2,"committed last phase is published without waiting for another interval primary=%s"%primary)
		rig.scene.free()

func _test_parallel_visit_retirement()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO,Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)])
	rig.sim.name="SimulationRoot"
	var controller=Sandbox.new()
	rig.scene.add_child(controller)
	controller.set_process(false)
	controller.set_physics_process(false)
	var crew:Array=[]
	for id in ["first","second"]:
		var actor=CrewActor.new()
		actor.unit_id=id
		actor.visible=false
		actor.set_meta("dropship_embarked",true)
		rig.scene.add_child(actor)
		rig.units.register_unit(id,actor)
		rig.sim.register_known_unit(id,actor)
		crew.append(actor)
		controller._embarked_unit_ids[id]=true
	var sequence:Dictionary={"units":crew,"unit_index":0,"embarked_unit_ids":{"first":true,"second":true},"lz_position":-controller._get_unload_offset(0,"NW"),"approach_angle":"NW","craft_id":"retiring"}
	controller._parallel_drop_sequences_by_craft["retiring"]=sequence
	controller._deploy_next_embarked_unit_for_sequence(sequence)
	controller.retire_location_craft_visit("retiring",PackedStringArray(["first","second"]))
	_check(rig.sim.get_hex_ground_planning_snapshot().admission_slots_by_grid.is_empty() and not controller._parallel_drop_sequences_by_craft.has("retiring"),"actual parallel visit retirement cancels its pending group before removing sequence")
	rig.sim._physics_process(0.1)
	_check(rig.sim.get_hex_unit_state("first").is_empty() and not crew[0].visible and crew[0].get_meta("dropship_embarked"),"queued old deploy cannot publish after actual visit retirement")
	rig.scene.free()

func _test_retirement_after_root_commit()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO,Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)])
	rig.sim.name="SimulationRoot"
	var controller=Sandbox.new()
	rig.scene.add_child(controller)
	controller.set_process(false)
	controller.set_physics_process(false)
	var actor=CrewActor.new()
	actor.unit_id="unread_commit"
	actor.visible=false
	actor.set_meta("dropship_embarked",true)
	rig.scene.add_child(actor)
	rig.units.register_unit(actor.unit_id,actor)
	rig.sim.register_known_unit(actor.unit_id,actor)
	controller._embarked_unit_ids[actor.unit_id]=true
	var sequence:Dictionary={"units":[actor],"unit_index":0,"embarked_unit_ids":{actor.unit_id:true},"lz_position":-controller._get_unload_offset(0,"NW"),"approach_angle":"NW","craft_id":"retiring_late"}
	controller._parallel_drop_sequences_by_craft["retiring_late"]=sequence
	controller._deploy_next_embarked_unit_for_sequence(sequence)
	rig.sim._physics_process(0.1)
	_check(not rig.sim.get_hex_unit_state(actor.unit_id).is_empty() and not controller._deployed_unit_ids.has(actor.unit_id),"retirement fixture has real commit before delayed controller receipt")
	controller.retire_location_craft_visit("retiring_late",PackedStringArray([actor.unit_id]))
	rig.sim._physics_process(0.1)
	_check(rig.sim.get_hex_unit_state(actor.unit_id).is_empty() and not actor.visible and actor.get_meta("dropship_embarked"),"actual retirement reads Root presence even before deployed readout was published")
	rig.scene.free()

func _test_hex_owner_unavailable()->void:
	for missing in [false,true]:
		var rig:Dictionary=_admission_rig([Vector2i.ZERO,Vector2i(1,0)])
		rig.sim.name="OtherRoot" if missing else "SimulationRoot"
		var actor:Node2D=_add_admission_actor(rig,"waiting")
		actor.visible=false
		actor.set_meta("dropship_embarked",true)
		var controller=Sandbox.new()
		rig.scene.add_child(controller)
		controller.set_process(false)
		controller.set_physics_process(false)
		controller.fixture_map=rig.map
		controller.fixture_crew=[actor]
		controller._embarked_unit_ids["waiting"]=true
		if not missing:rig.terrain.free()
		var sequence:Dictionary={"units":[actor],"unit_index":0,"embarked_unit_ids":{"waiting":true},"lz_position":Vector2.ZERO}
		controller._deploy_next_embarked_unit_for_sequence(sequence)
		var response:Dictionary=controller.request_campaign_crew_deployment("waiting_ship")
		_check(sequence.unit_index==0 and controller._deployed_unit_ids.is_empty() and controller._embarked_unit_ids.has("waiting") and not response.ok,"loaded Hex map waits without legacy publication when owner missing=%s"%missing)
		if not missing:
			var before:Vector2=actor.global_position
			rig.sim._apply_dropship_deploy_unit_effect({"unit_id":"waiting","position":Vector2(999,999),"visible":true})
			_check(actor.global_position==before and not actor.visible and actor.get_meta("dropship_embarked"),"Root remembers Hex context and rejects direct deploy instead of legacy teleport after terrain loss")
		rig.scene.free()

func _test_legacy_unload()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO,Vector2i(1,0)])
	rig.sim.name="SimulationRoot"
	rig.map.set_tactical_grid_rules("")
	rig.sim.configure_hex_ground_runtime(rig.map,rig.terrain)
	var actor:Node2D=_add_admission_actor(rig,"legacy")
	actor.visible=false
	actor.set_meta("dropship_embarked",true)
	var controller=Sandbox.new()
	rig.scene.add_child(controller)
	controller.set_process(false)
	controller.set_physics_process(false)
	controller.fixture_map=rig.map
	controller._embarked_unit_ids["legacy"]=true
	var sequence:Dictionary={"units":[actor],"unit_index":0,"embarked_unit_ids":{"legacy":true},"lz_position":Vector2.ZERO,"approach_angle":"NW"}
	controller._deploy_next_embarked_unit_for_sequence(sequence)
	_check(sequence.unit_index==1 and controller._deployed_unit_ids.has("legacy") and not sequence.has("hex_admission"),"Hex topology without tactical rules preserves legacy unload scheduling")
	rig.sim._physics_process(0.1)
	_check(not rig.sim.is_hex_ground_runtime_active() and actor.visible and not actor.get_meta("dropship_embarked") and actor.global_position==controller._get_unload_offset(0,"NW"),"legacy deploy effect keeps its existing position and visibility behavior")
	rig.scene.free()

func _test_parked_crew_request()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)])
	rig.sim.name="SimulationRoot"
	var controller=Sandbox.new()
	rig.scene.add_child(controller)
	controller.set_process(false)
	controller.set_physics_process(false)
	controller.fixture_lz=-controller._get_unload_offset(0,"NW")
	for id in ["first","second"]:
		var actor:Node2D=_add_admission_actor(rig,id)
		actor.set_meta("dropship_embarked",true)
		actor.visible=false
		controller.fixture_crew.append(actor)
		controller._embarked_unit_ids[id]=true
	var accepted:Dictionary=controller.request_campaign_crew_deployment("ship")
	var sequence:Dictionary=controller._parallel_drop_sequences_by_craft.get("ship",{})
	var held:bool=accepted.ok and bool(accepted.get("pending",false)) and sequence.get("phase","")==controller.DROP_SEQUENCE_UNLOADING and int(sequence.get("unit_index",-1))==0 and rig.sim.effects_queue.is_empty()
	_check(held and controller._embarked_unit_ids.size()==2 and controller._deployed_unit_ids.is_empty(),"parked crew command starts persistent timed unloading instead of discarding a local pending sequence")
	if held:
		controller._advance_drop_sequence_unloading_for_sequence(sequence,controller.DROP_UNLOAD_INTERVAL_SECONDS)
		rig.sim._physics_process(0.1)
		controller._advance_drop_sequence_unloading_for_sequence(sequence,controller.DROP_UNLOAD_INTERVAL_SECONDS)
		_check(sequence.unit_index==1 and controller._embarked_unit_ids.size()==1,"parked crew sequence publishes its first committed phase through normal interval owner")
	rig.scene.free()
