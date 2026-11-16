extends "res://scripts/tests/hex_base_personnel_owner_verifier.gd"

class Scope extends Node:
	var _polisa_shuttle: RefCounted
	func _home_pad_for(_craft:String)->String:return "pad"
	func get_space_travel_snapshot(_craft:String)->Dictionary:return {"phase":"grounded"}

class FakeShuttle extends RefCounted:
	var published := false
	var validation_allowed := true
	func prepare_home_disembark(receipt: Dictionary) -> Dictionary:
		if receipt.get("verified") != true: return {"ok":false,"reason":"unverified"}
		return {"ok":true,"person_id":"polisa_recruit_station"}
	func validate_prepared_home_disembark(_handle: Dictionary) -> Dictionary: return {"ok":validation_allowed}
	func _publish_prepared_home_disembark(_handle: Dictionary, _validation: Dictionary) -> Dictionary:
		published = true
		return {"ok":true}

class RecruitFlow extends Flow:
	func _find_homebase_aircraft_definition(craft:String)->Dictionary:return {"craft_id":craft} if craft=="away_ship" else {}

class Screen extends Node:
	var payload_craft:=""
	var boarding_ready:=false
	var reject_board:=false
	var reject_unboard:=false
	var board_requests:=0
	var unboard_requests:=0
	var members:=PackedStringArray(["base_person"])
	var pilot_id:="other"
	var prepared_unboard:Dictionary={}
	func _operations_craft_busy(_craft:String)->bool:return false
	func _operations_payload_craft_for_team(_team:String)->String:return payload_craft
	func _get_member_unit_ids_for_fireteam(_team:String)->PackedStringArray:return members.duplicate()
	func _get_assigned_pilot_id(_craft:String)->String:return pilot_id
	func _get_fireteam_id_for_unit(id:String)->String:return "ft1" if members.has(id) else ""
	func _request_operation_from_base(operation:String,_payload:Dictionary)->Dictionary:
		if operation=="board":
			board_requests+=1
			if reject_board:return {"ok":false,"reason":"fixture_board_denied"}
			payload_craft="ship"
		if operation=="unboard":
			unboard_requests+=1
			if reject_unboard:return {"ok":false,"reason":"fixture_unboard_denied"}
			payload_craft=""
		return {"ok":true}
	func _are_homebase_payload_fireteams_boarded(_teams:PackedStringArray)->bool:return boarding_ready
	func prepare_base_unboard(craft:String,team:String)->Dictionary:
		unboard_requests+=1
		if reject_unboard:return {"ok":false,"reason":"fixture_unboard_denied"}
		var handle=RefCounted.new()
		prepared_unboard={"handle":handle,"before":payload_craft,"craft_id":craft,"fireteam_id":team}
		return {"ok":true,"prepared":handle,"craft_id":craft,"fireteam_id":team}
	func validate_prepared_base_unboard(handle:RefCounted)->Dictionary:
		return {"ok":prepared_unboard.get("handle")==handle and payload_craft==prepared_unboard.get("before"),"prepared_id":handle.get_instance_id()}
	func _publish_prepared_base_unboard(_handle:RefCounted,_validation:Dictionary)->Dictionary:
		payload_craft=""
		return {"ok":true}
	func finalize_base_unboard(_handle:RefCounted)->Dictionary:
		prepared_unboard={}
		return {"ok":true}

func _finish()->void:
	if failed==0:
		_test_actual_boarding()
		_test_remote_binding_release()
		_test_pilot_member_unboard()
		_test_station_roster_identity()
		_test_station_shuttle_home_admission()
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0:print("HEX_BASE_BOARDING_PASS")
	quit(0 if failed==0 else 1)

func _test_station_roster_identity()->void:
	var rig:Dictionary=_base_rig()
	rig.base._navigation_graph=null
	rig.base._flow._all_team_units.append({"unit_id":"polisa_recruit_station","display_name":"Recruit","recruit_location":"polisa"})
	rig.base.sync_roster()
	var actor:Node=rig.base.get_actor("polisa_recruit_station")
	_check(is_instance_valid(actor) and not actor.visible and rig.base._states.polisa_recruit_station.status=="station" and not rig.base._unit_is_home("polisa_recruit_station") and rig.sim.get_hex_unit_state("polisa_recruit_station").is_empty(),"station recruit has no physical base presence")
	_check(rig.base.has_method("has_station_recruits") and rig.base.has_station_recruits(),"base reports a recruit resident on the station (has_station_recruits)")
	rig.scene.free()

func _test_station_shuttle_home_admission()->void:
	var rig: Dictionary = _base_rig()
	rig.scene.set_script(Scope)
	var shuttle := FakeShuttle.new()
	rig.scene._polisa_shuttle = shuttle
	rig.base._navigation_graph = null
	rig.base._flow._all_team_units.append({"unit_id":"polisa_recruit_station","display_name":"Recruit","recruit_location":"polisa"})
	rig.base.sync_roster()
	rig.base._navigation_graph = Navigation.new()
	rig.base._navigation_graph.terrain = rig.terrain
	if not rig.base.has_method("admit_polisa_shuttle_home"):
		_check(false,"base supports prepared shuttle arrival")
		rig.scene.free()
		return
	var denied: Dictionary = rig.base.admit_polisa_shuttle_home("polisa_recruit_station", {"verified":false}, Vector2i(1,0))
	_check(not denied.ok and rig.sim.get_hex_unit_state("polisa_recruit_station").is_empty() and not shuttle.published,"unverified arrival leaves person remote")
	shuttle.validation_allowed = false
	var stale: Dictionary = rig.base.admit_polisa_shuttle_home("polisa_recruit_station", {"verified":true}, Vector2i(2,1))
	_check(not stale.ok and rig.sim.get_hex_unit_state("polisa_recruit_station").is_empty() and rig.sim.get_hex_ground_planning_snapshot().admission_slots_by_grid.is_empty() and not shuttle.published,"stale shuttle proof releases reserved ground without changing person")
	shuttle.validation_allowed = true
	var accepted: Dictionary = rig.base.admit_polisa_shuttle_home("polisa_recruit_station", {"verified":true}, Vector2i(1,0))
	if not accepted.ok: print("SHUTTLE_HOME_DIAGNOSTIC: ", accepted)
	_check(accepted.ok and shuttle.published and rig.base._states.polisa_recruit_station.status=="outside" and not rig.sim.get_hex_unit_state("polisa_recruit_station").is_empty(),"verified arrival commits shuttle and base ground together")
	rig.base._source_layout = {"beds":[]}
	rig.base.advance_automatic_rest(120.0)
	_check(Dictionary(rig.base._states.polisa_recruit_station.action).is_empty(), "station recruit does not use an automatically invented field bed")
	var sleep: Dictionary = rig.base.request_operation("base_sleep", {"unit_id":"polisa_recruit_station", "bed_id":"bed"})
	_check(not sleep.ok, "station recruit cannot manually use an unbuilt bed")
	rig.scene.free()

func _boarding_rig()->Dictionary:
	var rig:Dictionary=_base_rig()
	rig.scene.set_script(Scope)
	var screen=Screen.new()
	rig.scene.add_child(screen)
	rig.screen=screen
	rig.base._screen=screen
	rig.base._flow._aircraft_location_by_craft["ship"]="homebase"
	rig.base._layout.landing_pads=[{"id":"pad","grid":[2,0],"interaction_grid":[2,0]}]
	var placements:Array[Dictionary]=[{"unit_id":"base_person","grid":Vector2i.ZERO},{"unit_id":"other","grid":Vector2i(0,1)}]
	rig.sim.admit_base_ground_people(rig.base,placements)
	return rig

func _test_actual_boarding()->void:
	var rig:Dictionary=_boarding_rig()
	var accepted:Dictionary=rig.base._board_team("ship",{"fireteam_id":"ft1"})
	var first:Dictionary=rig.base._states.base_person.action
	var other:Dictionary=rig.base._states.other.action
	var distinct:bool=accepted.ok and first.has("target") and other.has("target") and first.target!=other.target
	_check(distinct and first.has("target") and other.has("target"),"actual boarding group receives distinct legal physical approach goals")
	if not distinct:
		rig.scene.free()
		return
	for i in range(80):rig.sim._physics_process(0.1)
	_check(rig.screen.board_requests==1 and rig.base._states.base_person.status=="boarding" and rig.base._states.other.status=="boarding" and rig.sim.get_hex_ground_planning_snapshot().units_by_id.size()==2,"actual arrivals retain Ground until existing transport owner confirms boarding")
	rig.screen.boarding_ready=true
	for i in range(3):rig.sim._physics_process(0.1)
	_check(rig.base._states.base_person.status=="aboard" and rig.base._states.other.status=="aboard" and rig.sim.get_hex_ground_planning_snapshot().units_by_id.is_empty(),"existing transport confirmation releases both physical claims exactly once")
	var third=BASE_ACTOR.new()
	third.unit_id="third"
	rig.base.add_child(third)
	rig.units.register_unit("third",third)
	rig.sim.register_known_unit("third",third)
	rig.base._states["third"]={"unit_id":"third","status":"aboard","craft_id":"ship","bed_id":"","action":{},"last_result":{},"auto_rest_enabled":false}
	rig.screen.members.append("third")
	var blockers:=PackedStringArray()
	var blocked_placements:Array[Dictionary]=[]
	for tile in rig.terrain.get_all_tiles():
		if tile.grid_position==Vector2i(2,0):continue
		var id:String="block_%s"%tile.grid_position
		_add_admission_actor(rig,id)
		blockers.append(id)
		blocked_placements.append({"unit_id":id,"grid":tile.grid_position})
	rig.sim.admit_hex_ground_units(blocked_placements)
	var denied:Dictionary=rig.base._unboard("base_person","ship",{})
	_check(not denied.ok and rig.screen.unboard_requests==0 and rig.base._states.base_person.status=="aboard" and rig.base._states.third.status=="aboard" and rig.sim.get_hex_ground_planning_snapshot().admission_slots_by_grid.is_empty(),"one free ground field keeps the full two-person crew aboard before any transport change")
	for id in blockers:
		rig.units.unregister_unit(id)
		rig.sim.unregister_known_unit(id)
	rig.screen.reject_unboard=true
	denied=rig.base._unboard("base_person","ship",{})
	_check(not denied.ok and rig.screen.unboard_requests==1 and rig.base._states.base_person.status=="aboard" and rig.screen.payload_craft=="ship" and rig.sim.get_hex_ground_planning_snapshot().admission_slots_by_grid.is_empty(),"rejected existing transport unboard cancels the prepared Ground group")
	rig.screen.reject_unboard=false
	var unboarded:Dictionary=rig.base._unboard("base_person","ship",{})
	_check(unboarded.ok and rig.base._states.base_person.status=="outside" and rig.base._states.third.status=="outside" and rig.sim.get_hex_unit_state("third").grid!=rig.sim.get_hex_unit_state("base_person").grid and rig.sim.get_hex_unit_state("other").is_empty(),"actual successful unboard publishes the whole crew on distinct reserved fields while pilot stays aboard")
	denied=rig.base._unboard("other","ship",{})
	_check(not denied.ok and rig.base._states.other.status=="aboard" and rig.sim.get_hex_unit_state("other").is_empty(),"occupied physical exit keeps pilot aboard instead of stacking on first person")
	rig.base.request_operation("base_move",{"unit_id":"base_person","target_position":Vector2.ZERO})
	rig.base.request_operation("base_move",{"unit_id":"third","target_position":rig.terrain.grid_to_world(Vector2i(0,1))})
	for i in range(60):rig.sim._physics_process(0.1)
	var pilot:Dictionary=rig.base._unboard("other","ship",{})
	_check(pilot.ok and rig.base._states.other.status=="outside" and rig.sim.get_hex_unit_state("other").grid!=rig.sim.get_hex_unit_state("base_person").grid,"cleared actual exit admits the same pilot on a distinct physical field")
	rig.scene.free()

func _test_remote_binding_release()->void:
	var rig:Dictionary=_boarding_rig()
	rig.base._flow.set_script(RecruitFlow)
	var result:Dictionary=rig.base.mark_recruit_remote("base_person","away_ship")
	_check(result.ok and rig.base._states.base_person.status=="aboard" and rig.base._states.base_person.craft_id=="away_ship" and rig.sim.get_hex_unit_state("base_person").is_empty() and not rig.sim.get_hex_unit_state("other").is_empty(),"actual remote recruitment binding releases only its own old base Ground claim")
	rig.scene.free()

func _test_pilot_member_unboard()->void:
	for whole in [false,true]:
		var rig:Dictionary=_boarding_rig()
		rig.screen.members=PackedStringArray(["base_person","other"])
		rig.screen.pilot_id="base_person"
		rig.base._board_team("ship",{"fireteam_id":"ft1"})
		for i in range(80):rig.sim._physics_process(0.1)
		rig.screen.boarding_ready=true
		for i in range(3):rig.sim._physics_process(0.1)
		var result:Dictionary
		if whole:result=rig.base.request_operation("base_unboard",{"craft_id":"ship","fireteam_id":"ft1","whole_fireteam":true})
		else:
			rig.base._unboard("base_person","ship",{})
			rig.base.request_operation("base_move",{"unit_id":"base_person","target_position":Vector2.ZERO})
			for i in range(30):rig.sim._physics_process(0.1)
			result=rig.base._unboard("other","ship",{})
		_check(result.ok and rig.base._states.base_person.status=="outside" and rig.base._states.other.status=="outside" and rig.sim.get_hex_unit_state("base_person").grid!=rig.sim.get_hex_unit_state("other").grid and rig.screen.unboard_requests==1,"actual team with pilot member unboards coherently whole=%s"%whole)
		rig.scene.free()
