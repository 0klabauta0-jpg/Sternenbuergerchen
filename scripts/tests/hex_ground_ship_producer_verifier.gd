extends "res://scripts/tests/hex_deployment_controller_verifier.gd"

const PROFILE_DATA=preload("res://scripts/mission/polisa_ground_body_profile.gd")
const SHIP_CATALOG=preload("res://scripts/terrain/frontier_ship_visuals.gd")

class ShipController extends Sandbox:
	var fixture_terrain:Node
	var fixture_projection:Dictionary={}
	var projection_reads:=0
	func _get_terrain_registry():return fixture_terrain
	func _should_keep_campaign_dropship_landed()->bool:return true
	func _get_units_for_drop_operation()->Array:return fixture_crew
	func _store_active_drop_sequence_card()->void:pass
	func _read_ground_ship_landing_projection(_craft:Dictionary,_position:Vector2,_approach:String)->Dictionary:
		projection_reads+=1
		return fixture_projection.duplicate(true)
	func _find_mission_dropship_card_entry(id:String)->Dictionary:
		for card in _mission_drop_cards:
			if String(card.get("craft_id",""))==id:return card.duplicate(true)
		return {}
	func _campaign_landed_craft_position(id:String)->Vector2:
		var sequence:Dictionary=_parallel_drop_sequences_by_craft.get(id,{})
		return sequence.get("lz_position",fixture_lz)

func _finish()->void:
	var probe=ShipController.new()
	_check(probe.has_method("get_ground_ship_blocked_cells"),"actual controller provides derived immutable ship masks and regular landing profiles")
	probe.free()
	if failed==0:
		_test_ship_selection_and_cache()
		_test_regular_landing_profile()
		_test_resolved_landing_claims()
		_test_actual_ship_mask_consumer()
		_test_foreign_landing_overlap()
		_test_touchdown_revalidation()
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0:print("HEX_GROUND_SHIP_PRODUCER_PASS")
	quit(0 if failed==0 else 1)

func _ship_rig(legacy:bool=false)->Dictionary:
	var cells:Array=[]
	for q in range(-1,2):
		for r in range(-1,3):cells.append(Vector2i(q,r))
	var rig:Dictionary=_admission_rig(cells)
	rig.sim.name="SimulationRoot"
	rig.scene.set_meta("location_id","polisa")
	if legacy:
		rig.map.set_tactical_grid_rules("")
		rig.sim.configure_hex_ground_runtime(rig.map,rig.terrain)
	var controller=ShipController.new()
	rig.scene.add_child(controller)
	controller.set_process(false)
	controller.set_physics_process(false)
	controller.fixture_map=rig.map
	controller.fixture_terrain=rig.terrain
	var craft:Dictionary={"craft_id":"incoming","model_id":"cutlass","craft_type":"dropship","crew_capacity":8,"state":"waiting","has_lz_position":true,"lz_position":Vector2.ZERO}
	var identity:Dictionary=SHIP_CATALOG.get_ui_identity(craft)
	controller.fixture_projection={"ok":true,"model_id":"cutlass","asset_id":identity.get("asset_id",""),"bounds":AABB(Vector3(-0.1,-0.1,-0.1),Vector3(0.2,0.2,0.2)),"model_scale":1.0,"cell_size":1.0,"yaw_degrees":0.0}
	rig.controller=controller
	rig.craft=craft
	return rig

func _test_ship_selection_and_cache()->void:
	var rig:Dictionary=_ship_rig()
	var controller=rig.controller
	var craft:Dictionary=rig.craft.duplicate(true)
	craft.craft_id="uncrewed"
	craft.state="complete"
	controller._mission_drop_cards=[craft,{"craft_id":"outbound","state":"outbound","has_lz_position":true,"lz_position":Vector2.ZERO}]
	controller._parallel_drop_sequences_by_craft["uncrewed"]={"craft_id":"uncrewed","phase":"complete","position":Vector2.ZERO,"lz_position":Vector2.ZERO,"units":[]}
	var bound:Dictionary=PROFILE_DATA.from_projection(craft,controller.fixture_projection)
	controller._field_landing_by_craft["uncrewed"]={"ground_body_profile":bound.profile}
	var first:Dictionary=controller.get_ground_ship_blocked_cells()
	_check(first.ok and first.blocked_cells.has(Vector2i.ZERO) and controller.projection_reads==0,"uncrewed accepted ship blocks actual surface without a visit or camera lookup")
	var audit:Dictionary=controller.get_ground_ship_footprint_audit()
	first.blocked_cells.clear()
	controller.fixture_projection.yaw_degrees=90.0
	controller._mission_drop_progress=99.0
	var again:Dictionary=controller.get_ground_ship_blocked_cells()
	var after:Dictionary=controller.get_ground_ship_footprint_audit()
	_check(again.ok and again.blocked_cells.has(Vector2i.ZERO) and after.raster_jobs==audit.raster_jobs and after.cache_hits>audit.cache_hits and controller.projection_reads==0,"mask copy, camera and progress updates cannot change or rebuild the accepted body")
	_check(controller.get_ground_ship_blocked_cells("uncrewed").blocked_cells.is_empty(),"actual unloading craft can be excluded without exempting other craft")
	controller._mission_drop_cards.append({"craft_id":"not_started","model_id":"cutlass","state":"waiting","has_lz_position":true,"lz_position":Vector2.ZERO})
	_check(controller.get_ground_ship_blocked_cells().ok,"selected but unaccepted waiting LZ is not an unknown physical ship")
	controller._field_landing_by_craft["uncrewed"].erase("ground_body_profile")
	_check(not controller.get_ground_ship_blocked_cells().ok and controller.projection_reads==0,"old accepted body without profile is never repaired from current view")
	rig.scene.free()

func _test_regular_landing_profile()->void:
	for legacy in [false,true]:
		var rig:Dictionary=_ship_rig(legacy)
		var controller=rig.controller
		controller._mission_drop_craft_id="incoming"
		controller._mission_drop_state="waiting"
		controller._mission_drop_cards=[rig.craft]
		controller._has_lz_position=true
		controller._lz_position=Vector2.ZERO
		var actor=CrewActor.new()
		actor.unit_id="crew"
		actor.set_meta("dropship_embarked",true)
		actor.visible=false
		rig.scene.add_child(actor)
		rig.units.register_unit(actor.unit_id,actor)
		rig.sim.register_known_unit(actor.unit_id,actor)
		controller.fixture_crew=[actor]
		controller._drop_ship_cooldown_remaining=1.0
		var denied:bool=controller._try_start_drop_sequence()
		_check(not denied and controller._field_landing_by_craft.is_empty() and controller.projection_reads==0,"rejected arrival never binds or rewrites landing profile legacy=%s"%legacy)
		controller._drop_ship_cooldown_remaining=0.0
		var accepted:bool=controller._try_start_drop_sequence()
		var landing:Dictionary=controller._field_landing_by_craft.get("incoming",{})
		_check(accepted and landing.has("ground_body_profile") and controller.projection_reads==1,"regular actual landing binds its checked profile once even legacy=%s"%legacy)
		var saved:Dictionary=landing.duplicate(true)
		controller.fixture_projection.yaw_degrees=180.0
		var repeated:bool=controller._try_start_drop_sequence()
		_check(not repeated and controller._field_landing_by_craft.get("incoming",{})==saved and controller.projection_reads==1,"live arrival cannot rebind profile from later camera legacy=%s"%legacy)
		rig.scene.free()

func _test_resolved_landing_claims()->void:
	for pending in [false,true]:
		var rig:Dictionary=_ship_rig()
		var controller=rig.controller
		controller._mission_drop_cards=[rig.craft]
		var actor:Node2D=_add_admission_actor(rig,"claimed")
		actor.set_meta("dropship_embarked",pending)
		var cell:=Vector2i(1,0)
		if pending:rig.sim.prepare_hex_ground_deployment(PackedStringArray(["claimed"]),cell)
		else:rig.sim.admit_hex_ground_actor_group(PackedStringArray(["claimed"]),cell)
		var before:Dictionary=rig.sim.get_hex_ground_planning_snapshot()
		var result:Dictionary=controller._prepare_ground_ship_landing("incoming",{"requested_lz_position":Vector2.ZERO,"resolved_lz_position":rig.terrain.grid_to_world(cell)})
		_check(not result.ok and result.reason=="ground_landing_occupied" and rig.sim.get_hex_ground_planning_snapshot()==before and controller._field_landing_by_craft.is_empty(),"resolved landing respects actual claimed cell without owner writes pending=%s"%pending)
		rig.scene.free()

func _test_actual_ship_mask_consumer()->void:
	var rig:Dictionary=_ship_rig()
	var controller=rig.controller
	for id in ["ownship","foreign"]:
		var card:Dictionary=rig.craft.duplicate(true)
		card.craft_id=id
		card.state="complete"
		controller._mission_drop_cards.append(card)
		var position:Vector2=Vector2.ZERO if id=="ownship" else rig.terrain.grid_to_world(Vector2i(1,0))
		controller._parallel_drop_sequences_by_craft[id]={"craft_id":id,"phase":"complete","lz_position":position,"units":[]}
		controller._field_landing_by_craft[id]={"ground_body_profile":PROFILE_DATA.from_projection(card,controller.fixture_projection).profile}
	var crew:Array=[]
	for id in ["first","second"]:
		var actor:Node2D=_add_admission_actor(rig,id)
		actor.set_meta("dropship_embarked",true)
		actor.visible=false
		crew.append(actor)
		controller._embarked_unit_ids[id]=true
	var sequence:Dictionary={"craft_id":"ownship","units":crew,"unit_index":0,"embarked_unit_ids":{"first":true,"second":true},"lz_position":-controller._get_unload_offset(0,"NW"),"approach_angle":"NW"}
	controller._deploy_next_embarked_unit_for_sequence(sequence)
	var snapshot:Dictionary=rig.sim.get_hex_ground_planning_snapshot()
	_check(sequence.has("hex_admission") and snapshot.admission_slots_by_grid.size()==2 and not snapshot.admission_slots_by_grid.has(Vector2i(1,0)),"actual unload consumer reserves whole group around foreign body while excluding its own craft")
	var audit:Dictionary=controller.get_ground_ship_footprint_audit()
	controller._deploy_next_embarked_unit_for_sequence(sequence)
	_check(controller.get_ground_ship_footprint_audit()==audit and sequence.unit_index==0,"pending unload poll neither rebuilds nor requeries ship geometry")
	rig.sim._physics_process(0.1)
	controller._deploy_next_embarked_unit_for_sequence(sequence)
	_check(sequence.unit_index==1 and rig.sim.get_hex_unit_state("first").grid!=Vector2i(1,0),"actual committed unload publishes only its legal Root placement")
	rig.scene.free()

func _test_foreign_landing_overlap()->void:
	var rig:Dictionary=_ship_rig()
	var controller=rig.controller
	controller.fixture_projection.bounds=AABB(Vector3(-6,0,-8),Vector3(12,1,16))
	controller.fixture_projection.model_scale=0.22
	var foreign:Dictionary=rig.craft.duplicate(true)
	foreign.craft_id="foreign"
	foreign.state="complete"
	controller._mission_drop_cards=[rig.craft,foreign]
	controller._parallel_drop_sequences_by_craft["foreign"]={"craft_id":"foreign","phase":"complete","position":Vector2(256,0),"lz_position":Vector2(256,0),"units":[]}
	controller._field_landing_by_craft["foreign"]={"ground_body_profile":PROFILE_DATA.from_projection(foreign,controller.fixture_projection).profile}
	var result:Dictionary=controller._prepare_ground_ship_landing("incoming",{"resolved_lz_position":Vector2.ZERO})
	_check(not result.ok and result.reason=="ground_landing_occupied" and not controller._field_landing_by_craft.has("incoming"),"final landing rejects overlapping accepted ship bodies beyond the old center-distance threshold")
	rig.scene.free()

func _test_touchdown_revalidation()->void:
	for primary in [false,true]:
		var rig:Dictionary=_ship_rig()
		var controller=rig.controller
		controller._mission_drop_cards=[rig.craft]
		var accepted:Dictionary=controller._prepare_ground_ship_landing("incoming",{"resolved_lz_position":Vector2.ZERO})
		controller._field_landing_by_craft["incoming"]=accepted
		var actor:Node2D=_add_admission_actor(rig,"crossing")
		rig.sim.admit_hex_ground_actor_group(PackedStringArray(["crossing"]),Vector2i(-1,0))
		rig.sim.enqueue_command(_command("crossing",Vector2.ZERO))
		for i in range(16):rig.sim._physics_process(0.1)
		_check(rig.sim.get_hex_unit_state("crossing").grid==Vector2i.ZERO,"real NPC can enter a previously accepted arrival site before touchdown primary=%s"%primary)
		var sequence:Dictionary={"craft_id":"incoming","phase":controller.DROP_SEQUENCE_INBOUND,"position":Vector2.ZERO,"lz_position":Vector2.ZERO,"timer":1.25,"units":[]}
		if primary:
			controller._drop_sequence_craft_id="incoming"
			controller._drop_sequence_phase=controller.DROP_SEQUENCE_INBOUND
			controller._drop_sequence_position=Vector2.ZERO
			controller._drop_sequence_lz_position=Vector2.ZERO
			controller._drop_sequence_timer=1.25
			controller._update_primary_drop_sequence(0.0)
		else:controller._update_drop_sequence_dict(sequence,0.0)
		var phase:String=controller._drop_sequence_phase if primary else String(sequence.phase)
		_check(phase==controller.DROP_SEQUENCE_INBOUND and controller.projection_reads==1,"actual touchdown waits for current Root claims without rebinding geometry primary=%s"%primary)
		rig.sim.embark_hex_ground_actor_group(PackedStringArray(["crossing"]))
		if primary:controller._update_primary_drop_sequence(0.0)
		else:controller._update_drop_sequence_dict(sequence,0.0)
		phase=controller._drop_sequence_phase if primary else String(sequence.phase)
		_check(phase==controller.DROP_SEQUENCE_LANDED and controller.projection_reads==1,"claim release permits actual touchdown with the same accepted profile primary=%s"%primary)
		rig.scene.free()
