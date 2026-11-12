extends SceneTree

class Controller extends Node:
	var _deployed_unit_ids := {"polisa_recruit_1":true}
	var proof := {}
	var cancel_pending := false
	var cancel_safe := true
	func get_polisa_service_departure(_id: String) -> Dictionary: return proof
	func _apply_selected_mission_dropship_return(_id: String) -> bool: return true
	func cancel_polisa_service_transfer(_source: String, _craft: String, _person: String, _pilot: String) -> Dictionary: return {"ok":false,"reason":"service_cleanup_pending"} if cancel_pending else {"ok":true}
	func can_cancel_polisa_service_transfer(_source: String, _craft: String, _person: String, _pilot: String) -> Dictionary: return {"ok":true} if cancel_safe else {"ok":false,"reason":"service_boarding_pending"}
class Setup extends Node:
	func get_polisa_recruit_admission(_id: String) -> Dictionary: return {"ok":true}
	func retire_polisa_service_actors(_ids: PackedStringArray) -> Dictionary: return {"ok":true}
class Terrain extends Node:
	func get_legal_hex_neighbors(_grid: Vector2i) -> Array: return [Vector2i(3,4)]
	func is_walkable(_grid: Vector2i) -> bool: return true
class Simulation extends Node:
	var terrain: Node
	func get_hex_unit_state(_id: String) -> Dictionary: return {"grid":Vector2i(2,4)}
	func get_hex_ground_terrain_registry() -> Node: return terrain
	func get_hex_ground_planning_snapshot() -> Dictionary: return {"occupant_by_grid":{}}
class Flow extends Node:
	var place: Node
	var returns := 0
	func get_mission_for_craft(_id: String) -> Node: return place
	func _request_singleplayer_return(_id: String) -> Dictionary:
		returns += 1
		return {"ok":true}
class Base extends Node:
	func get_shuttle_person_status(_id: String) -> Dictionary: return {"ok":true,"has_bed":false,"has_task":false}
class Bridge extends RefCounted:
	var boarded := false
	var boarding_requests := 0
	func request_station_pilot(_place: Node, craft: String, _cell: Vector2i) -> Dictionary: return {"ok":true,"unit_id":"station_shuttle_pilot_" + craft.sha256_text().substr(0,16)}
	func admit(place: Node, _craft: String, _pilot: String, person: String, source: String) -> Dictionary:
		var visits: Dictionary = place.get_meta("singleplayer_visit_identities")
		visits[source].unit_ids.erase(person)
		return {"ok":true}
	func request_boarding_walk(_place: Node, _craft: String) -> Dictionary: return {"ok":true}
	func verify_boarded(_place: Node, _person: String, _craft: String) -> bool: return boarded
	func request_boarding(_place: Node, _craft: String) -> Dictionary: boarding_requests += 1; return {"ok":false,"reason":"pilot_boarding_pending"}
class Owner extends RefCounted:
	var started := false
	var phase := "idle"
	func configure(_verify: Callable, _status: Callable) -> Dictionary: return {"ok":true}
	func begin(_person: String, _craft: String, _receipt: Dictionary) -> Dictionary: started = true; phase = "to_home"; return {"ok":true}
	func get_snapshot() -> Dictionary: return {"phase":phase}

func _init() -> void: call_deferred("_run")
func _run() -> void:
	var errs: Array[String] = []
	var place := Node.new(); root.add_child(place); place.set_meta("location_id","polisa"); place.set_meta("singleplayer_visit_identities", {"own":{"unit_ids":["polisa_recruit_1"]}})
	var c := Controller.new(); c.name = "TacticalController"; place.add_child(c)
	var setup := Setup.new(); setup.name = "MissionSetup"; place.add_child(setup)
	var terrain := Terrain.new(); place.add_child(terrain)
	var sim := Simulation.new(); sim.name = "SimulationRoot"; sim.terrain=terrain; place.add_child(sim)
	var flow := Flow.new(); root.add_child(flow); flow.place=place
	var base := Base.new(); root.add_child(base)
	var owner := Owner.new(); var bridge := Bridge.new()
	var dispatcher = load("res://scripts/mission/polisa_shuttle_dispatcher.gd").new()
	dispatcher._bridge=bridge
	if not dispatcher.configure(flow,base,owner,Callable()).get("ok",false): errs.append("configure")
	var start: Dictionary = dispatcher.request_departure("own")
	if not start.get("pending",false) or flow.returns != 0: errs.append("departure pending")
	dispatcher.advance(1)
	dispatcher.advance(1)
	if flow.returns != 0 or owner.started: errs.append("do not depart without boarding")
	bridge.boarded=true
	dispatcher.advance(1)
	if flow.returns != 0 or owner.started: errs.append("do not depart before takeoff")
	c.proof={"ok":true,"person_id":"polisa_recruit_1"}
	dispatcher.advance(1)
	if not owner.started or flow.returns != 1: errs.append("owner starts after takeoff before player departure")
	var first_craft: String = dispatcher.get_snapshot().craft_id
	if dispatcher.rearm().get("ok",false): errs.append("cannot rearm active shuttle")
	owner.phase = "idle"
	if not dispatcher.rearm().get("ok",false) or dispatcher.get_snapshot().phase != "idle": errs.append("rearm after retired shuttle")
	place.get_meta("singleplayer_visit_identities").own.unit_ids = ["polisa_recruit_1"]
	var second: Dictionary = dispatcher.request_departure("own")
	if not second.get("pending",false) or dispatcher.get_snapshot().craft_id == first_craft: errs.append("next trip has a fresh craft identity")
	if not dispatcher.cancel_before_transfer().get("ok",false) or dispatcher.get_snapshot().phase != "cancelled": errs.append("safe pre-transfer cancellation")
	dispatcher.ack_cancelled()
	place.get_meta("singleplayer_visit_identities").own.unit_ids = ["polisa_recruit_1"]
	bridge.boarded = false
	dispatcher.request_departure("own"); dispatcher.advance(1)
	c.cancel_safe = false
	if dispatcher.cancel_before_transfer().get("ok",false) or dispatcher.get_snapshot().phase != "approaching": errs.append("unsafe cancellation leaves dispatcher advancing")
	c.cancel_safe = true
	c.cancel_pending = true
	var cancel: Dictionary = dispatcher.cancel_before_transfer()
	if dispatcher.get_snapshot().phase != "cancelling" or not cancel.get("pending", false): errs.append("grounded cancellation remains pending")
	var previous_requests: int = bridge.boarding_requests
	dispatcher.advance(1)
	if bridge.boarding_requests != previous_requests or dispatcher.get_snapshot().phase != "cancelling": errs.append("pending cancellation cannot start boarding")
	c.cancel_pending = false
	dispatcher.advance(1)
	if dispatcher.get_snapshot().phase != "cancelled": errs.append("cancellation completes only after cleanup")
	dispatcher.ack_cancelled()
	var owner2 := Owner.new(); var bridge2 := Bridge.new(); bridge2.boarded = true
	var queued = load("res://scripts/mission/polisa_shuttle_dispatcher.gd").new(); queued._bridge = bridge2
	queued.configure(flow,base,owner2,Callable())
	c._deployed_unit_ids["polisa_recruit_2"] = true
	place.get_meta("singleplayer_visit_identities").own.unit_ids = ["polisa_recruit_1","polisa_recruit_2"]
	var before: int = flow.returns
	if not queued.request_departure("own").get("pending",false): errs.append("multiple recruits queued")
	queued.advance(1); queued.advance(1)
	if queued.cancel_before_transfer().get("ok",false): errs.append("transferred crew cannot be discarded by early cancel")
	c.proof={"ok":true}
	queued.advance(1)
	if queued.get_snapshot().phase != "wait_next" or flow.returns != before: errs.append("player ship waits for remaining recruit")
	owner2.phase = "idle"
	queued.advance(1)
	if queued.get_snapshot().person_id != "polisa_recruit_2" or queued.get_snapshot().phase != "pilot_pending": errs.append("next recruit starts after safe retirement")
	var owner3 := Owner.new(); var bridge3 := Bridge.new()
	var advancing = load("res://scripts/mission/polisa_shuttle_dispatcher.gd").new(); advancing._bridge = bridge3
	advancing.configure(flow,base,owner3,Callable())
	place.get_meta("singleplayer_visit_identities").own.unit_ids = ["polisa_recruit_1"]
	advancing.request_departure("own"); advancing.advance(1)
	c.cancel_safe = false
	if advancing.cancel_before_transfer().get("ok",false): errs.append("boarding cannot be cancelled")
	bridge3.boarded = true
	advancing.advance(1)
	if advancing.get_snapshot().phase != "taking_off": errs.append("rejected cancellation allows confirmed boarding to continue")
	for e in errs: printerr("FAIL: " + e)
	print("PASS: dispatcher respects boarding and takeoff" if errs.is_empty() else "FAIL")
	flow.free(); base.free(); place.free(); quit(0 if errs.is_empty() else 1)
