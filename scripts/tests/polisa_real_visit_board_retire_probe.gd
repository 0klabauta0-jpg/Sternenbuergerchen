extends "res://scripts/tests/hex_deployment_phase_verifier.gd"
## Run against the current integrated AP6 source in an isolated project copy.
## Actor presentation and landed-card lookup are fixture inputs; Flow, visit,
## controller boarding/retirement, Root, ground and registry are real code.
class VisitFlow extends "res://scripts/meta/meta_layer_flow.gd":
	var fixture_remembered:=0
	func _ready() -> void: pass
	func _remember_location(_instance: Node) -> void: fixture_remembered+=1
class VisitController extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var fixture_crew: Array = []
	var fixture_map:RefCounted
	var fixture_pilots:Dictionary={"visitor":"pilot"}
	var fixture_planning_callback:Callable=Callable()
	var fixture_planning_notices:=0
	func _ready() -> void: pass
	func _get_campaign_sortie_units() -> Array: return fixture_crew
	func _get_active_mission_terrain_map_data_for_readability():return fixture_map
	func _find_mission_dropship_card_entry(id: String) -> Dictionary: return {"craft_id":id,"pilot_unit_id":fixture_pilots.get(id,"pilot")}
	func _find_raw_mission_dropship_card_entry(id: String) -> Dictionary: return {"craft_id":id,"pilot_unit_id":fixture_pilots.get(id,"pilot")}
	func _is_parked_campaign_dropship(_id: String) -> bool: return true
	## Fixture-Eingabe: Das Einsteigen misst in Hex-Besuchen gegen den Zugangspunkt am Schiffsrumpf. Dessen Rumpfgeometrie
	## (gebundenes ground_body_profile je Schiff) gibt es in dieser Attrappe nicht; der Zugangspunkt liegt hier am Feld (1,0).
	func get_campaign_ground_ship_access(_id: String) -> Dictionary:
		var simulation := get_node_or_null("../SimulationRoot")
		if simulation == null or not simulation.has_method("get_hex_ground_terrain_registry"): return {"ok":false,"reason":"hex_ground_unavailable"}
		return {"ok":true,"position":simulation.get_hex_ground_terrain_registry().grid_to_world(Vector2i(1,0))}
	func _store_selected_mission_dropship_plan() -> void: pass
	func _emit_planning_state_changed() -> void:
		fixture_planning_notices+=1
		if fixture_planning_callback.is_valid():fixture_planning_callback.call()
	func _refresh_world_overlays() -> void: pass
	func get_local_command_team_id(_units: Array = []) -> String: return "blue"
class CrewActor extends Actor:
	func get_fireteam_id() -> String: return "team"
	func get_display_name()->String:return unit_id
	func get_portrait_path()->String:return ""
class SelectionInput extends Node:
	var selected_team_unit_ids:=PackedStringArray(["pilot","other"])

func _run() -> void:
	var rig: Dictionary = _admission_rig([Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0),Vector2i(0,1)])
	rig.scene.set_meta("location_id", "polisa"); rig.sim.name = "SimulationRoot"
	var controller = VisitController.new(); controller.name = "TacticalController"; rig.scene.add_child(controller)
	var actor = CrewActor.new(); actor.unit_id = "pilot"; rig.scene.add_child(actor)
	rig.units.register_unit("pilot", actor); rig.sim.register_known_unit("pilot", actor)
	assert(rig.sim.admit_hex_ground_actor_group(PackedStringArray(["pilot"]), Vector2i.ZERO).ok)
	rig.sim.enqueue_command(_command("pilot", rig.terrain.grid_to_world(Vector2i(2,0))))
	rig.sim._physics_process(0.1)
	_check(not rig.sim.get_hex_movement_readout("pilot").is_empty(), "fixture has an actual accepted ground movement intent")
	controller.fixture_crew = [actor]; controller._deployed_unit_ids["pilot"] = true
	controller._parallel_drop_sequences_by_craft["visitor"] = {"phase":controller.DROP_SEQUENCE_COMPLETE,"position":actor.global_position,"lz_position":actor.global_position,"embarked_unit_ids":{}}
	var flow = VisitFlow.new(); root.add_child(flow);flow.set_process(false);flow._location_registry.register_location("polisa", rig.scene)
	flow._craft_location_runtime["visitor"] = "polisa"; flow._aircraft_location_by_craft["visitor"] = "mission"
	flow._bind_location_visit(rig.scene, {"craft_id":"visitor","location_id":"polisa","unit_ids":["pilot"],"fireteam_ids":["team"]})
	_check(controller.get_campaign_pilot_flight_guard("visitor").get("reason") == "pilot_not_aboard", "real guard rejects deployed pilot")
	var before: Dictionary = rig.sim.get_hex_ground_planning_snapshot()
	var boarding: Dictionary = flow.board_polisa_craft_crew("visitor")
	_check(not boarding.get("ok",false) or rig.sim.get_hex_unit_state("pilot").is_empty(), "public boarding never reports success while pilot remains on ground")
	_check(rig.sim.get_hex_ground_planning_snapshot() != before or not rig.sim.effects_queue.is_empty(), "public boarding creates a committed or pending Root transition")
	# Retirement is a separate public Flow call. Do not regard queued effects as
	# successful release; current Root presence and registry identity are checked.
	flow._finish_space_surface_departure("visitor")
	_check(not rig.units.get_unit("pilot") == null, "retirement keeps known actor identity")
	_check(rig.sim.get_hex_unit_state("pilot").is_empty() or controller._deployed_unit_ids.has("pilot"), "retirement projection waits for actual Root presence release")
	rig.sim._physics_process(0.1)
	_check(rig.sim.get_hex_unit_state("pilot").is_empty() and rig.sim.get_hex_movement_readout("pilot").is_empty() and rig.units.get_unit("pilot") == actor, "Root releases ground and movement while retaining actor identity")
	flow.free(); rig.scene.free()
	_test_group_barrier()
	_test_retirement_wait_and_stale()
	_test_other_visit()
	_test_boarding_reentry()
	_test_legacy_and_missing_owner()
	_test_pending_flight_guard()
	_test_post_publication_presence()
	_test_boarding_visit_callbacks()
	_test_foreign_card_pilot()
	_test_actual_flow_waiting_repair()
	_test_logical_boarding_position()
	print("POLISA_REAL_VISIT_BOARD_RETIRE passed=", passed, " failed=", failed)
	quit(1 if failed else 0)

func _visit_rig(membership:Dictionary={"visitor":["pilot"]})->Dictionary:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0),Vector2i(3,0),Vector2i(0,1),Vector2i(1,1)])
	rig.sim.name="SimulationRoot"
	rig.scene.set_meta("location_id","polisa")
	var controller=VisitController.new()
	controller.name="TacticalController"
	controller.fixture_map=rig.map
	rig.scene.add_child(controller)
	controller.set_process(false)
	var flow=VisitFlow.new()
	root.add_child(flow)
	flow.set_process(false)
	flow._location_registry.register_location("polisa",rig.scene)
	var index:=0
	var placements:Array[Dictionary]=[]
	for craft in membership:
		var crew:Array=[]
		var teams:Array=[]
		controller.fixture_pilots[craft]=membership[craft][0]
		for id in membership[craft]:
			var actor=CrewActor.new()
			actor.unit_id=id
			rig.scene.add_child(actor)
			rig.units.register_unit(id,actor)
			rig.sim.register_known_unit(id,actor)
			rig.actors[id]=actor
			controller.fixture_crew.append(actor)
			crew.append(actor)
			teams.append("team")
			placements.append({"unit_id":id,"grid":Vector2i(index,0)})
			index+=1
			controller._deployed_unit_ids[id]=true
		controller._parallel_drop_sequences_by_craft[craft]={"craft_id":craft,"phase":controller.DROP_SEQUENCE_COMPLETE,"position":Vector2.ZERO,"lz_position":Vector2.ZERO,"units":crew,"embarked_unit_ids":{}}
		flow._craft_location_runtime[craft]="polisa"
		flow._aircraft_location_by_craft[craft]="mission"
		flow._bind_location_visit(rig.scene,{"craft_id":craft,"location_id":"polisa","unit_ids":membership[craft],"fireteam_ids":teams})
	rig.sim.admit_hex_ground_units(placements)
	rig.controller=controller
	rig.flow=flow
	return rig

func _dispose_visit(rig:Dictionary)->void:
	rig.flow.free()
	rig.scene.free()

func _test_group_barrier()->void:
	var rig:Dictionary=_visit_rig({"visitor":["pilot","member"]})
	var reads:Array=[]
	for actor in rig.actors.values():
		actor.visibility_changed.connect(func():
			if not actor.visible:
				reads.append(rig.sim.get_hex_ground_planning_snapshot().units_by_id.is_empty() and rig.controller._deployed_unit_ids.is_empty() and rig.controller._embarked_unit_ids.size()==2 and rig.controller._parallel_drop_sequences_by_craft.visitor.embarked_unit_ids.size()==2 and rig.actors.pilot.get_meta("dropship_embarked",false) and rig.actors.member.get_meta("dropship_embarked",false)))
	var result:Dictionary=rig.flow.board_polisa_craft_crew("visitor")
	_check(result.ok and reads==[true,true] and rig.controller.get_campaign_pilot_flight_guard("visitor").ok,"first boarding visibility callbacks see all Root, Controller and sequence group models committed")
	_dispose_visit(rig)

func _test_retirement_wait_and_stale()->void:
	for kind in ["repair","lifecycle","visit","context"]:
		var rig:Dictionary=_visit_rig()
		rig.sim.enqueue_command(_command("pilot",rig.terrain.grid_to_world(Vector2i(2,0))))
		rig.sim._physics_process(0.1)
		var original:NodePath=rig.sim.unit_registry_path
		var missing=Node.new()
		rig.scene.add_child(missing)
		rig.sim.unit_registry_path=rig.sim.get_path_to(missing)
		var before:Dictionary=rig.sim.get_hex_ground_planning_snapshot()
		var failed_result:Dictionary=rig.controller.retire_location_craft_visit("visitor",PackedStringArray(["pilot"]))
		_check(not failed_result.ok and failed_result.status=="waiting" and rig.controller._deployed_unit_ids.has("pilot") and rig.actors.pilot.visible and rig.sim.get_hex_ground_planning_snapshot()==before,"failed retirement retains current claims and projection before a bound retry: "+kind)
		rig.sim.unit_registry_path=original
		if kind=="lifecycle":
			rig.sim.release_hex_ground_unit("pilot","fixture_new_lifecycle")
			rig.sim.admit_hex_ground_actor_group(PackedStringArray(["pilot"]),Vector2i.ZERO)
		elif kind=="visit":
			var visits:Dictionary=rig.scene.get_meta("singleplayer_visit_identities").duplicate(true)
			visits.visitor["job_id"]="new_visit"
			rig.scene.set_meta("singleplayer_visit_identities",visits)
		elif kind=="context":rig.sim.configure_hex_ground_runtime(rig.map,rig.terrain)
		before=rig.sim.get_hex_ground_planning_snapshot()
		var result:Dictionary=rig.controller.retire_location_craft_visit("visitor",PackedStringArray(["pilot"]),failed_result.retirement_binding)
		if kind=="repair":
			_check(result.ok and result.status=="committed" and rig.sim.get_hex_unit_state("pilot").is_empty() and rig.sim.get_hex_movement_readout("pilot").is_empty() and not rig.controller._deployed_unit_ids.has("pilot") and not rig.actors.pilot.visible,"same original Root registry repair completes the bound retirement synchronously")
			var identity:Dictionary=rig.sim.call("_hex_payload_identity","pilot")
			var twice:Dictionary=rig.controller.retire_location_craft_visit("visitor",PackedStringArray(["pilot"]))
			_check(twice.ok and rig.sim.call("_hex_payload_identity","pilot")==identity,"repeated retirement does not advance already released actor lifecycle")
		else:_check(not result.ok and result.status=="stale" and rig.sim.get_hex_ground_planning_snapshot()==before and rig.controller._deployed_unit_ids.has("pilot"),"old bound retirement never targets changed lifecycle/visit/context: "+kind)
		_dispose_visit(rig)

func _test_other_visit()->void:
	var rig:Dictionary=_visit_rig({"visitor":["pilot"],"other_ship":["other"]})
	rig.controller._phase_execution_by_fireteam["team"]={"belongs":"other"}
	rig.controller._order_plans_by_key["team|move"]={"belongs":"other"}
	rig.sim.enqueue_command(_command("other",rig.terrain.grid_to_world(Vector2i(3,0))))
	rig.sim._physics_process(0.1)
	var other:Dictionary=rig.sim.get_hex_unit_state("other")
	var other_move:Dictionary=rig.sim.get_hex_movement_readout("other")
	var invalid:Dictionary=rig.controller.retire_location_craft_visit("visitor",PackedStringArray(["other"]))
	_check(not invalid.ok and invalid.reason=="foreign_visit_member" and rig.sim.get_hex_unit_state("other")==other,"retirement rejects a different visit member before Root writes")
	var result:Dictionary=rig.controller.retire_location_craft_visit("visitor",PackedStringArray(["pilot"]))
	_check(result.ok and rig.sim.get_hex_unit_state("other")==other and rig.sim.get_hex_movement_readout("other")==other_move and rig.controller._deployed_unit_ids.has("other") and rig.controller._parallel_drop_sequences_by_craft.has("other_ship") and rig.actors.other.visible,"retiring own visit preserves the other craft, actor, field and accepted movement")
	_check(rig.controller._phase_execution_by_fireteam.has("team") and rig.controller._order_plans_by_key.has("team|move"),"retiring pilot preserves a shared fireteam plan while local crew remains")
	_dispose_visit(rig)

func _test_boarding_reentry()->void:
	var rig:Dictionary=_visit_rig({"visitor":["pilot","member"]})
	var invoked:Array=[]
	rig.actors.pilot.visibility_changed.connect(func():
		if not rig.actors.pilot.visible and invoked.is_empty():
			invoked.append(true)
			rig.sim.admit_hex_ground_actor_group(PackedStringArray(["pilot"]),Vector2i.ZERO))
	var result:Dictionary=rig.flow.board_polisa_craft_crew("visitor")
	_check(not result.ok and not rig.sim.get_hex_unit_state("pilot").is_empty() and rig.actors.pilot.visible and not rig.actors.member.visible and rig.actors.member.get_meta("dropship_embarked",false),"new lifecycle in first visibility callback preserves new actor and still hides the other committed aboard member")
	_dispose_visit(rig)

func _test_legacy_and_missing_owner()->void:
	var rig:Dictionary=_visit_rig()
	rig.map.set_tactical_grid_rules("")
	rig.sim.configure_hex_ground_runtime(rig.map,rig.terrain)
	var result:Dictionary=rig.flow.board_polisa_craft_crew("visitor")
	_check(not result.ok and result.reason=="pilot_boarding_pending" and rig.sim.effects_queue.size()==1 and rig.actors.pilot.visible,"unflagged visit keeps existing queued boarding cadence")
	rig.sim._physics_process(0.1)
	_check(not rig.actors.pilot.visible and rig.controller.get_campaign_pilot_flight_guard("visitor").ok,"legacy boarding still completes through its existing Root effect")
	_dispose_visit(rig)
	rig=_visit_rig()
	rig.sim.free()
	result=rig.flow.board_polisa_craft_crew("visitor")
	_check(not result.ok and result.reason=="hex_ground_unavailable" and rig.controller._deployed_unit_ids.has("pilot") and rig.actors.pilot.visible,"declared hex visit without its concrete Root never falls back to legacy boarding")
	_dispose_visit(rig)

func _test_pending_flight_guard()->void:
	var rig:Dictionary=_visit_rig()
	rig.sim.embark_hex_ground_actor_group(PackedStringArray(["pilot"]))
	rig.controller._deployed_unit_ids.clear()
	rig.controller._embarked_unit_ids["pilot"]=true
	rig.controller._parallel_drop_sequences_by_craft.visitor.embarked_unit_ids["pilot"]=true
	var ticket:Dictionary=rig.sim.prepare_hex_ground_deployment(PackedStringArray(["pilot"]),Vector2i.ZERO)
	_check(ticket.ok and not rig.controller.get_campaign_pilot_flight_guard("visitor").ok,"a pending real unload admission blocks flight even before a deploy effect is queued")
	_dispose_visit(rig)

func _test_post_publication_presence()->void:
	var rig:Dictionary=_visit_rig()
	rig.controller.fixture_planning_callback=func():rig.sim.admit_hex_ground_actor_group(PackedStringArray(["pilot"]),Vector2i.ZERO)
	var result:Dictionary=rig.flow.board_polisa_craft_crew("visitor")
	_check(not result.ok and not rig.sim.get_hex_unit_state("pilot").is_empty() and rig.actors.pilot.visible,"post-planning observer cannot leave a current boarding success after a new ground admission")
	_dispose_visit(rig)

	rig=_visit_rig()
	var invoked:Array=[]
	rig.actors.pilot.visibility_changed.connect(func():
		if not rig.actors.pilot.visible and invoked.is_empty():
			invoked.append(true)
			rig.sim.admit_hex_ground_actor_group(PackedStringArray(["pilot"]),Vector2i.ZERO))
	result=rig.controller.retire_location_craft_visit("visitor",PackedStringArray(["pilot"]))
	_check(not result.ok and result.status=="stale" and result.historical_committed and not rig.sim.get_hex_unit_state("pilot").is_empty(),"retirement returns stale historical receipt when a callback readmits the same actor without another release")
	_dispose_visit(rig)

func _test_boarding_visit_callbacks()->void:
	for kind in ["visibility","planning","remove_controller"]:
		var rig:Dictionary=_visit_rig()
		var change:Callable=func():
			var visits:Dictionary=rig.scene.get_meta("singleplayer_visit_identities").duplicate(true)
			visits.visitor["job_id"]="new_visit"
			rig.scene.set_meta("singleplayer_visit_identities",visits)
		if kind=="visibility":
			rig.actors.pilot.visibility_changed.connect(func():
				if not rig.actors.pilot.visible:change.call())
		elif kind=="planning":rig.controller.fixture_planning_callback=change
		else:rig.controller.fixture_planning_callback=func():rig.controller.queue_free()
		var result:Dictionary=rig.flow.board_polisa_craft_crew("visitor")
		_check(not result.ok and (rig.controller.fixture_planning_notices==0 if kind=="visibility" else rig.controller.fixture_planning_notices==1),"boarding suppresses obsolete continuation after visit or owner callback: "+kind)
		_dispose_visit(rig)

func _test_foreign_card_pilot()->void:
	for kind in ["boarding","retirement","assignment"]:
		var rig:Dictionary=_visit_rig({"visitor":["pilot"],"other_ship":["other"]})
		if kind!="assignment":rig.controller.fixture_pilots.visitor="other"
		var before:Dictionary=rig.sim.get_hex_ground_planning_snapshot()
		var result:Dictionary={}
		if kind=="boarding":result=rig.flow.board_polisa_craft_crew("visitor")
		elif kind=="retirement":result=rig.controller.retire_location_craft_visit("visitor",PackedStringArray(["other"]))
		else:
			rig.scene.set_meta("campaign_ground_pilot_id","pilot")
			var selection=SelectionInput.new()
			selection.name="MissionSetup"
			rig.scene.add_child(selection)
			result=rig.controller.assign_campaign_pilot("visitor","other")
		_check(not result.ok and rig.sim.get_hex_ground_planning_snapshot()==before and rig.controller._deployed_unit_ids.size()==2,"explicit other-visit ownership rejects before any Root or card publication: "+kind)
		_dispose_visit(rig)

func _test_actual_flow_waiting_repair()->void:
	var rig:Dictionary=_visit_rig()
	rig.sim.enqueue_command(_command("pilot",rig.terrain.grid_to_world(Vector2i(2,0))))
	rig.sim._physics_process(0.1)
	var original:NodePath=rig.sim.unit_registry_path
	var missing=Node.new()
	rig.scene.add_child(missing)
	rig.sim.unit_registry_path=rig.sim.get_path_to(missing)
	var before:Dictionary=rig.sim.get_hex_ground_planning_snapshot()
	rig.flow._finish_space_surface_departure("visitor")
	_check(rig.flow._aircraft_location_by_craft.visitor=="mission" and rig.flow.fixture_remembered==0 and rig.sim.get_hex_ground_planning_snapshot()==before and rig.controller._deployed_unit_ids.has("pilot"),"actual Flow with failed actual Root retirement publishes neither location nor projection completion")
	_check(not rig.flow.get_surface_departure_retirement_guard("visitor").ok and not rig.flow._pending_mission_craft_transfers.is_empty(),"actual Flow holds existing per-craft admission/save marker during retirement wait")
	rig.sim.unit_registry_path=original
	rig.flow._retry_space_surface_departures()
	_check(rig.flow._aircraft_location_by_craft.visitor=="starmap" and rig.flow.fixture_remembered==1 and rig.flow._pending_mission_craft_transfers.is_empty() and rig.sim.get_hex_unit_state("pilot").is_empty() and rig.sim.get_hex_movement_readout("pilot").is_empty() and not rig.controller._deployed_unit_ids.has("pilot"),"actual bound Flow retry completes Root, Controller and location after original registry repair")
	_dispose_visit(rig)

func _test_logical_boarding_position()->void:
	var rig:Dictionary=_visit_rig()
	rig.actors.pilot.global_position=Vector2(10000,10000)
	var result:Dictionary=rig.flow.board_polisa_craft_crew("visitor")
	_check(result.ok and rig.sim.get_hex_unit_state("pilot").is_empty(),"hex boarding distance reads authoritative field center instead of presentation coordinates")
	_dispose_visit(rig)
