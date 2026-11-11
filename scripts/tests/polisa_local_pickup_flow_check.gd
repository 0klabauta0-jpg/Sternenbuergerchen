extends SceneTree
## Real Flow + BasePersonnel binding, small local controller/actor doubles.
class Flow extends "res://scripts/meta/meta_layer_flow.gd":
	func _ready() -> void: pass
	func _process(_delta: float) -> void: pass
	func _refresh_singleplayer_services() -> void: pass
	func is_campaign_start() -> bool: return true
	func _get_fob_screen(): return null
	func _apply_planning_state_to_mission(_instance: Node) -> void: pass
	func _ensure_transport_timer_state() -> void: pass
class Person extends Node2D:
	var id := ""
	func get_health() -> int: return 100
	func get_fireteam_id() -> String: return "ft1"
	func get_display_name() -> String: return id
class Setup extends Node:
	var selected_team_unit_ids := PackedStringArray(["operator","pilot"])
	var selected_team_fireteam_ids := PackedStringArray(["ft1","ft1"])
	var map_file_path := "fixture"
class Controller extends Node:
	var cards := {"source":{"pilot_unit_id":"pilot"}}
	var people := {}
	var fail_admission := false
	var fail_handoff := false
	var commits := 0
	var updates := 0
	func get_planning_state() -> Dictionary: return {"mission_drop_cards":cards.values()}
	func _find_mission_dropship_card_entry(id: String) -> Dictionary: return cards.get(id,{})
	func _get_campaign_sortie_unit(id: String) -> Node: return people.get(id)
	func _is_parked_campaign_dropship(id: String) -> bool: return cards.has(id)
	func preview_station_craft_admission(_craft: Dictionary,_pad: String="") -> Dictionary:
		return {"ok":true,"pad_id":"polisa_pad_05","position":Vector2(2,3)}
	func admit_station_craft(craft: Dictionary,_pad: String,_request: String) -> Dictionary:
		if fail_admission: return {"ok":false,"reason":"pad_changed"}
		cards[String(craft.craft_id)]={"craft_id":craft.craft_id,"pilot_unit_id":""}
		return {"ok":true,"position":Vector2(2,3)}
	func preview_station_crew_handoff(source: String,target: String,ids: PackedStringArray,pilot: String,membership: Dictionary) -> Dictionary:
		if fail_handoff: return {"ok":false,"reason":"person_unavailable"}
		if source==target or ids!=PackedStringArray(["pilot"]) or pilot!="pilot" or not membership.get(source,[]).has(pilot) or membership.has("historic"):
			return {"ok":false,"reason":"bad_membership"}
		return {"ok":true}
	func commit_station_crew_handoff(source: String,target: String,ids: PackedStringArray,pilot: String,membership: Dictionary,_request: String) -> Dictionary:
		var result:=preview_station_crew_handoff(source,target,ids,pilot,membership)
		if not result.ok: return result
		commits+=1; cards[source].pilot_unit_id=""; cards[target].pilot_unit_id=pilot
		return {"ok":true}
	func finalize_station_craft_update() -> void: updates+=1
	func request_campaign_crew_deployment(_id: String) -> Dictionary: return {"ok":true}
	func request_campaign_crew_boarding(_id: String) -> Dictionary: return {"ok":false,"reason":"crew_not_at_ship"}
class Runtime extends Node:
	var base: Node
	func get_base_personnel_runtime() -> Node: return base
var count:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	count+=1
	if not ok: failures+=1; print("FAIL: ",label)
func fingerprint(flow,place,controller,base) -> String:
	return JSON.stringify([flow._craft_location_runtime,flow._assigned_aircraft_pilot_by_craft,place.get_meta("singleplayer_visit_identities"),controller.cards,base._states],"",true)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var flow:=Flow.new(); root.add_child(flow)
	check(not flow.get_polisa_local_ship_purchase_capability().get("available", false),"ownerless runtime cannot advertise local pickup")
	var place:=Node.new(); flow.add_child(place); place.set_meta("location_id","polisa")
	var source:={"craft_id":"source","job_id":"original_job","unit_ids":["operator"],"fireteam_ids":["ft1"]}
	place.set_meta("singleplayer_mission_identity",source.duplicate(true))
	place.set_meta("singleplayer_visit_identities",{"source":source.duplicate(true),"historic":{"craft_id":"historic","unit_ids":["pilot"],"fireteam_ids":["ft1"]}})
	var controller:=Controller.new(); controller.name="TacticalController"; place.add_child(controller)
	var setup:=Setup.new(); setup.name="MissionSetup"; place.add_child(setup)
	for id in ["pilot","operator"]:
		var actor:=Person.new(); actor.id=id; place.add_child(actor); controller.people[id]=actor
	flow._location_registry.register_location("polisa",place)
	flow._homebase_aircraft_definitions=[{"craft_id":"source"},{"craft_id":"historic"}]
	flow._aircraft_location_by_craft={"source":"mission","historic":"homebase"}
	flow._craft_location_runtime={"source":"polisa","historic":"polisa"}
	flow._assigned_aircraft_pilot_by_craft={"source":"pilot"}
	var runtime:=Runtime.new(); flow.add_child(runtime); flow._singleplayer_runtime=runtime
	var base=load("res://scripts/core/base_personnel_runtime.gd").new(); runtime.add_child(base); runtime.base=base; base._flow=flow
	base._states={"pilot":{"status":"aboard","craft_id":"source"},"operator":{"status":"aboard","craft_id":"source"}}
	var other:=Node.new(); flow.add_child(other); flow._active_mission=other; flow._current_meta_view="homebase"; flow._active_singleplayer_identity={"craft_id":"elsewhere"}
	var draft:={"craft_id":"new","model_id":"buccaneer","craft_type":"fighter","crew_capacity":99}
	var before:=fingerprint(flow,place,controller,base)
	var prepared:=flow.prepare_polisa_local_ship_purchase(draft,"buy-new")
	check(prepared.ok and prepared.craft_definition.crew_capacity==1,"normalize real fighter capacity")
	check(before==fingerprint(flow,place,controller,base),"prepare has no lifecycle mutation")
	var forged:Dictionary=prepared.duplicate(true); forged.craft_definition.crew_capacity=99
	check(not flow.commit_polisa_local_ship_purchase(forged).ok and before==fingerprint(flow,place,controller,base),"forged preparation rejects before mutation")
	controller.fail_admission=true
	check(not flow.commit_polisa_local_ship_purchase(prepared).ok and before==fingerprint(flow,place,controller,base),"changed pad leaves all bindings intact")
	controller.fail_admission=false
	check(flow.commit_polisa_local_ship_purchase(prepared).ok,"empty local craft admitted")
	check(flow._homebase_aircraft_definitions.size()==2 and setup.selected_team_unit_ids.size()==2,"Flow never adds fleet definition or actors behind adapter")
	check(place.get_meta("singleplayer_visit_identities").new.job_id=="" and place.get_meta("singleplayer_mission_identity")==source,"new craft never adopts source job or primary identity")
	check(flow._active_mission==other and flow._current_meta_view=="homebase" and flow._active_singleplayer_identity.craft_id=="elsewhere","purchase preserves unrelated view/context")
	flow._homebase_aircraft_definitions.append(prepared.craft_definition); flow._aircraft_location_by_craft.new="mission"
	flow.finalize_polisa_local_ship_purchase("new")
	check(controller.updates==1,"signal projection explicitly finalized after publication")
	check(flow.get_polisa_crew_handoff_snapshot("new").sources.size()==1,"only active local source offered, historical visit ignored")
	controller.fail_handoff=true; before=fingerprint(flow,place,controller,base)
	check(not flow.handoff_polisa_station_crew("source","new",PackedStringArray(["pilot"]),"pilot","blocked").ok and before==fingerprint(flow,place,controller,base),"failed handoff mutates no owner")
	controller.fail_handoff=false
	flow._assigned_aircraft_pilot_by_craft.foreign="pilot"
	check(not flow.handoff_polisa_station_crew("source","new",PackedStringArray(["pilot"]),"pilot","foreign").ok,"global duplicate pilot rejected")
	flow._assigned_aircraft_pilot_by_craft.erase("foreign")
	var moved:=flow.handoff_polisa_station_crew("source","new",PackedStringArray(["pilot"]),"pilot","move-pilot")
	check(moved.ok and controller.commits==1,"real base binding and controller handoff commit once")
	var visits:Dictionary=place.get_meta("singleplayer_visit_identities")
	check(visits.source.unit_ids==["operator"] and visits.source.fireteam_ids==["ft1"] and visits.new.unit_ids==["pilot"] and visits.new.fireteam_ids==["ft1"],"source/target unit and parallel team membership exact")
	check(base._states.pilot.craft_id=="new" and base._states.operator.craft_id=="source","base owner tracks actual return ship without affecting remaining crew")
	check(not flow._assigned_aircraft_pilot_by_craft.has("source") and flow._assigned_aircraft_pilot_by_craft.new=="pilot","global pilot assignment unique")
	check(place.get_meta("singleplayer_mission_identity").craft_id=="source" and place.get_meta("singleplayer_mission_identity").job_id=="original_job","handoff preserves job ownership")
	check(flow.handoff_polisa_station_crew("source","new",PackedStringArray(["pilot"]),"pilot","move-pilot").get("replayed",false) and controller.commits==1,"successful retry never repeats membership mutation")
	check(not flow.handoff_polisa_station_crew("source","new",PackedStringArray(["operator"]),"operator","move-pilot").ok,"conflicting request rejected")
	check(flow.board_polisa_craft_crew("new").get("reason")=="crew_not_at_ship","menu boarding keeps real distance gate")
	check(flow._active_mission==other and flow._current_meta_view=="homebase","handoff preserves unrelated view")
	flow._active_mission=place
	flow._on_mission_planning_state_changed({"mission_drop_cards":[{"craft_id":"new","pilot_unit_id":"pilot","state":"complete"},{"craft_id":"historic","pilot_unit_id":"pilot","state":"ready"}]})
	check(not flow._assigned_aircraft_pilot_by_craft.has("historic") and flow._assigned_aircraft_pilot_by_craft.new=="pilot","real planning callback never resurrects historical home craft pilot")
	flow.free()
	print("POLISA_PICKUP_FLOW checks=",count," failures=",failures)
	quit(int(failures>0))
