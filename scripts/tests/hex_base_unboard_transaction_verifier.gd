extends "res://scripts/tests/hex_base_boarding_verifier.gd"

class ActualScreen extends "res://scripts/meta/homebase_screen.gd":
	var fixture_base:Node
	func _ready()->void:pass
	func _rebuild_ui()->void:pass
	func _sync_operations_visibility()->void:pass
	func get_base_personnel_runtime()->Node:return fixture_base

func _finish()->void:
	if failed==0:
		_test_actual_screen_observers(false)
		_test_actual_screen_observers(true)
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0:print("HEX_BASE_UNBOARD_TRANSACTION_PASS")
	quit(0 if failed==0 else 1)

func _test_actual_screen_observers(cancel_ticket:bool)->void:
	var rig:Dictionary=_boarding_rig()
	rig.sim.release_base_ground_people(rig.base,PackedStringArray(["base_person","other"]),"fixture_boarding_confirmed")
	for id in ["base_person","other"]:
		rig.base._states[id].status="aboard"
		rig.base._states[id].craft_id="ship"
	var third=BASE_ACTOR.new()
	third.unit_id="third"
	rig.base.add_child(third)
	rig.units.register_unit("third",third)
	rig.sim.register_known_unit("third",third)
	rig.base._states["third"]={"unit_id":"third","status":"aboard","craft_id":"ship","bed_id":"","action":{},"last_result":{},"auto_rest_enabled":false}
	var screen=ActualScreen.new()
	rig.scene.add_child(screen)
	screen.fixture_base=rig.base
	screen._selected_unit_ids=PackedStringArray(["base_person","third"])
	screen._selected_fireteam_ids=PackedStringArray(["ft1","ft1"])
	screen._fireteam_definitions=[{"id":"ft1","member_unit_ids":["base_person","third"],"lead_unit_id":"base_person"}]
	screen._aircraft_manager.set_transport_state([{"craft_id":"ship","craft_type":"dropship","crew_capacity":4}],{"ship":"other"},[],{"ship":"homebase"})
	screen._homebase_dropship_staged_fireteam_ids_by_craft={"ship":PackedStringArray(["ft1"])}
	screen._homebase_dropship_staged_fireteam_ids=PackedStringArray(["ft1"])
	screen._homebase_dropship_payload_craft_id="ship"
	rig.base._screen=screen
	var observed:Array=[]
	var base_events:Array=[]
	screen.fireteam_context_changed.connect(func(_ids,_teams):
		var snapshot:Dictionary=rig.sim.get_hex_ground_planning_snapshot()
		observed.append(snapshot.units_by_id.has("base_person") and snapshot.units_by_id.has("third") and rig.base._states.base_person.status=="outside" and rig.base._states.third.status=="outside")
		if cancel_ticket:
			var tickets:Dictionary={}
			for slot in snapshot.admission_slots_by_grid.values():tickets[slot.admission_id]=true
			for ticket in tickets:rig.sim.cancel_hex_ground_deployment(String(ticket),"fixture_reentrant_observer")
	)
	rig.base.state_changed.connect(func():
		base_events.append(rig.base._states.base_person.status=="outside" and rig.base._states.third.status=="outside")
	)
	var result:Dictionary=rig.base._unboard("base_person","ship",{})
	print("UNBOARD_OBSERVATION ",JSON.stringify({"cancel_ticket":cancel_ticket,"result":result,"screen":observed,"base":base_events}))
	_check(result.ok and observed==[true] and base_events==[true] and screen._get_homebase_direct_payload_fireteam_ids_for_craft_raw("ship").is_empty(),"actual Screen and Base observers see one complete Ground/payload/group publish cancel_ticket=%s"%cancel_ticket)
	rig.scene.free()
