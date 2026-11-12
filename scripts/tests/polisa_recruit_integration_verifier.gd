extends "res://scripts/tests/hex_runtime_selection_verifier.gd"

class FixtureLocations extends RefCounted:
	var locations := {}
	func location_ids() -> Array: return locations.keys()
	func get_location(id: String) -> Node: return locations.get(id)
class FixtureFlow extends Node:
	var _all_team_units: Array = [{"unit_id":"a","display_name":"A","skill_values":{"leadership":0.7},"communication_values":{"speech_quality":0.7}}]
	var _location_registry = FixtureLocations.new()
	var _aircraft_location_by_craft := {"ship":"mission"}
	var mission: Node
	var base_owner: Node
	func get_mission_for_craft(_craft: String) -> Node: return mission
	func register_campaign_recruit(profile: Dictionary, _craft: Dictionary = {}) -> Dictionary:
		for person: Dictionary in _all_team_units:
			if person.unit_id == profile.unit_id: return {"ok":true,"already_registered":true}
		_all_team_units.append(profile.duplicate(true))
		if base_owner != null: base_owner.sync_roster()
		return {"ok":true}
class FixtureController extends Node:
	var allow_registration := false
	var _deployed_unit_ids := {}
	var residents := {}
	func get_polisa_resident_spawn_grid() -> Dictionary: return {"ok":true,"spawn_grid":Vector2i(1,0) if residents.size() > 0 else Vector2i(2,0)}
	func register_polisa_resident(id: String) -> Dictionary:
		var actor: Node = get_parent().get_node("UnitRegistry").get_unit(id)
		if not is_instance_valid(actor) or get_parent().get_node("SimulationRoot").get_hex_unit_state(id).is_empty(): return {"ok":false}
		residents[id]=true
		get_parent().set_meta("singleplayer_station_personnel", residents.duplicate())
		return {"ok":true}
	func claim_polisa_resident(id: String, craft: String) -> Dictionary:
		if not residents.has(id) or craft != "ship": return {"ok":false,"reason":"not_resident"}
		residents.erase(id)
		get_parent().set_meta("singleplayer_station_personnel", residents.duplicate())
		var visits: Dictionary=get_parent().get_meta("singleplayer_visit_identities", {})
		var visit: Dictionary=visits.get(craft,{"unit_ids":[]})
		visit.unit_ids.append(id); visits[craft]=visit
		get_parent().set_meta("singleplayer_visit_identities",visits)
		return {"ok":true}
	func register_polisa_recruit_person(id: String, _craft: String) -> Dictionary:
		if not allow_registration: return {"ok":false,"reason":"pending_fixture"}
		var setup: Node = get_parent().get_node("MissionSetup")
		_deployed_unit_ids[id] = true
		get_parent().set_meta("singleplayer_visit_identities", {"ship":{"unit_ids":[id]}})
		return setup.get_polisa_recruit_admission(id)
	func _find_friendly_unit_by_id(id: String) -> Node: return get_parent().get_node("UnitRegistry").get_unit(id)
	func _find_mission_dropship_card_entry(_craft: String) -> Dictionary: return {}
	func _get_deployed_unit_fireteam_id(_id: String) -> String: return ""
	func _is_parked_campaign_dropship(_craft: String) -> bool: return true
	func _campaign_landed_craft_position(_craft: String) -> Vector2:
		for id in _deployed_unit_ids:
			var actor: Node2D = get_parent().get_node("UnitRegistry").get_unit(id)
			if actor != null: return actor.position
		return Vector2.ZERO
class FixtureAdapter extends "res://scripts/meta/singleplayer_runtime_adapter.gd":
	var fixture_controller: Node
	func _service_context(_craft_id: String) -> Dictionary: return {"location_id":"polisa"}
	func _polisa_recruit_context(_craft_id: String, expected: String) -> Dictionary:
		if not expected.is_empty() and expected != "a": return {"ok":false,"reason":"recruiter_changed"}
		return {"ok":true,"unit_id":"a","spawn_grid":Vector2i(3,0),"controller":fixture_controller}
func _run() -> void:
	var rig: Dictionary = _selection_rig(PackedStringArray(["a"]))
	rig.setup.name="MissionSetup"
	var controller := FixtureController.new()
	controller.name="TacticalController"
	rig.scene.add_child(controller)
	var flow := FixtureFlow.new()
	rig.scene.add_child(flow)
	var base_rig: Dictionary = _admission_rig([Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0),Vector2i(3,0)])
	var base = load("res://scripts/core/base_personnel_runtime.gd").new()
	base_rig.scene.add_child(base)
	base._flow=flow
	base._sim=base_rig.sim
	base._terrain=base_rig.terrain
	base._registry=base_rig.units
	base._layout={"beds":[]}
	base_rig.base=base
	base_rig.sim.configure_base_personnel(base)
	flow.base_owner=base
	flow.mission=rig.scene
	rig.units.name="UnitRegistry"
	rig.sim.name="SimulationRoot"
	rig.terrain.name="TerrainRegistry"
	rig.setup.simulation_root_path=rig.setup.get_path_to(rig.sim)
	rig.setup.unit_registry_path=rig.setup.get_path_to(rig.units)
	rig.setup.terrain_registry_path=rig.setup.get_path_to(rig.terrain)
	rig.sim.unit_registry_path=rig.sim.get_path_to(rig.units)
	rig.sim.terrain_registry_path=rig.sim.get_path_to(rig.terrain)
	var adapter := FixtureAdapter.new()
	rig.scene.add_child(adapter)
	adapter.fixture_controller=controller
	adapter._flow=flow
	adapter._campaign_mode=true
	adapter._simulation=base_rig.sim
	adapter._base_personnel=base_rig.base
	adapter._campaign=load("res://scripts/core/singleplayer_campaign_state.gd").new()
	adapter._campaign.configure({}, {}, true)
	adapter._supply=load("res://scripts/core/singleplayer_supply_state.gd").new()
	adapter._supply.configure()
	adapter._supply._credits=5000
	base_rig.sim.configure_singleplayer_owners(adapter._campaign,adapter._supply)
	var opened: Dictionary=adapter._open_polisa_recruitment({"craft_id":"ship","unit_id":"a"})
	_check(opened.get("ok",false) and opened.get("offers",[]).size()==4,"globally authored market opens for real recruiter profile")
	if opened.get("ok",false):
		var offer: Dictionary=opened.offers[0]
		var before:int=adapter._supply.get_supply_snapshot().credits
		var result:Dictionary=adapter._request_polisa_recruitment({"craft_id":"ship","recruiter_id":"a","offer_id":offer.id})
		_check(result.get("ok",false) and rig.units.get_unit(offer.id)!=null and not rig.sim.get_hex_unit_state(offer.id).is_empty(),"hire produces real registered station actor")
		_check(adapter._supply.get_supply_snapshot().credits==before-int(offer.price) and adapter._supply.has_pending_recruitments() and flow._all_team_units.size()==1,"admission stays pending until crew binding")
		_check(adapter.has_pending_polisa_recruit("ship") and not adapter.has_pending_polisa_recruit("other"),"pending hire blocks only its own departing ship")
		var duplicate:Dictionary=adapter._request_polisa_recruitment({"craft_id":"ship","recruiter_id":"a","offer_id":offer.id})
		_check(not duplicate.get("ok",false) and adapter._supply.get_supply_snapshot().credits==before-int(offer.price),"duplicate purchase does not debit again")
		controller.allow_registration=true
		adapter._advance_polisa_recruitment()
		_check(not adapter._supply.has_pending_recruitments() and flow._all_team_units.size()==2,"pending actor finalizes after real crew binding")
		_check(base_rig.base._states.has(offer.id) and base_rig.base._states[offer.id].status=="station" and not base_rig.base.get_actor(offer.id).visible and base_rig.sim.get_hex_unit_state(offer.id).is_empty(),"station recruit is not duplicated on home ground")
		_check(not adapter.has_pending_polisa_recruit("ship"),"completed hire releases departure guard")
		var access: Dictionary = adapter._field_inventory_context(String(offer.id), "ship")
		_check(access.get("equipment_allowed",false) and Array(access.get("accessible_containers",[])).has("craft:ship"),"actual station recruit can use local ship inventory")
		var unchanged:int=adapter._supply.get_supply_snapshot().credits
		_check(not adapter._request_polisa_recruitment({"craft_id":"ship","recruiter_id":"foreign","offer_id":offer.id}).get("ok",false) and adapter._supply.get_supply_snapshot().credits==unchanged,"changed recruiter cannot use stale offer")
		var blocked:Dictionary=opened.offers[1]
		var failed:Dictionary=adapter._request_polisa_recruitment({"craft_id":"ship","recruiter_id":"a","offer_id":blocked.id})
		_check(not failed.get("ok",false) and adapter._supply.get_supply_snapshot().credits==unchanged and not adapter._supply.has_pending_recruitments(),"no free actor slot safely refunds reservation")
		var next:Dictionary=opened.offers[2]
		var reserve_id: String="polisa-hire:"+String(next.id)
		var reserve:Dictionary=adapter._commit("singleplayer_supply","station_recruit_reserve",{"offer_id":next.id},reserve_id,{"location_id":"polisa","station_service_verified":true,"recruit_quote":Callable(adapter._polisa_market,"quote")})
		var lost := Node.new()
		adapter._polisa_recruit_pending[reserve_id]={"unit_id":next.id,"profile":next.profile,"mission":weakref(lost),"craft_id":"ship","spawn_grid":Vector2i(3,0)}
		lost.free()
		flow._all_team_units.append(next.profile.duplicate(true))
		adapter._advance_polisa_recruitment()
		_check(reserve.get("ok",false) and adapter._polisa_recruit_pending.has(reserve_id),"lost mission does not refund while roster identity exists")
		flow._all_team_units.pop_back()
		var reserved_balance:int=adapter._supply.get_supply_snapshot().credits
		adapter._advance_polisa_recruitment()
		_check(not adapter._polisa_recruit_pending.has(reserve_id) and adapter._supply.get_supply_snapshot().credits==reserved_balance+int(next.price),"lost mission refunds only after verified absence")
		if not adapter.has_method("_restore_polisa_residents"):
			_check(false,"saved station resident restores into live location")
		else:
			var spare := SelectionActor.new()
			spare.unit_id="__unused_friendly_slot_2"; spare.team_id="team_unused"; spare.fireteam_id=""
			rig.scene.add_child(spare); spare.set_process(false); spare.set_physics_process(false); spare.visible=false
			rig.setup.unit_paths.append(rig.setup.get_path_to(spare)); rig.setup._friendly_unit_slot_paths.append(rig.setup.get_path_to(spare))
			var resident := {"unit_id":"polisa_recruit_resident","display_name":"Resident","recruit_location":"polisa"}
			flow._all_team_units.append(resident); base_rig.base.sync_roster()
			flow._location_registry.locations["polisa"]=rig.scene
			adapter._restore_polisa_residents()
			adapter._polisa_resident_retry_msec=0
			adapter._restore_polisa_residents()
			_check(controller.residents.has(resident.unit_id) and rig.units.get_unit(resident.unit_id)!=null and not rig.sim.get_hex_unit_state(resident.unit_id).is_empty(),"saved station resident restores into live location")
			_check(not Array(Dictionary(rig.scene.get_meta("singleplayer_visit_identities", {})).get("ship", {}).get("unit_ids", [])).has(resident.unit_id),"restored resident is not silently assigned to player visit")
			var second_spare := SelectionActor.new()
			second_spare.unit_id="__unused_friendly_slot_3"; second_spare.team_id="team_unused"; second_spare.fireteam_id=""
			rig.scene.add_child(second_spare); second_spare.set_process(false); second_spare.set_physics_process(false); second_spare.visible=false
			rig.setup.unit_paths.append(rig.setup.get_path_to(second_spare)); rig.setup._friendly_unit_slot_paths.append(rig.setup.get_path_to(second_spare))
			var second := {"unit_id":"polisa_recruit_resident_two","display_name":"Second","recruit_location":"polisa"}
			flow._all_team_units.append(second); base_rig.base.sync_roster()
			adapter._polisa_resident_retry_msec=0
			adapter._restore_polisa_residents()
			adapter._polisa_resident_retry_msec=0
			adapter._restore_polisa_residents()
			_check(controller.residents.has(second.unit_id) and rig.units.get_unit(second.unit_id)!=null,"existing resident does not block restoring another person")
			var claimed:Dictionary=adapter.request_operation("station_claim_resident", {"craft_id":"ship","unit_id":resident.unit_id})
			_check(claimed.get("ok",false) and Array(Dictionary(rig.scene.get_meta("singleplayer_visit_identities", {})).get("ship", {}).get("unit_ids", [])).has(resident.unit_id) and not controller.residents.has(resident.unit_id),"explicit claim transfers resident to player visit")
	rig.scene.free()
	base_rig.scene.free()
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0: print("POLISA_RECRUIT_INTEGRATION_PASS")
	quit(0 if failed==0 else 1)
