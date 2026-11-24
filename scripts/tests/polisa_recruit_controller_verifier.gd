extends SceneTree

class Controller extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var return_calls := 0
	func _ready() -> void: pass
	func _process(_delta: float) -> void: pass
	func _is_parked_campaign_dropship(id: String) -> bool: return id in ["craft", "shuttle"]
	func _emit_planning_state_changed() -> void: pass
	func _find_mission_dropship_card_entry(id: String) -> Dictionary: return {"craft_id":id}
	func _can_request_mission_dropship_return(_card: Dictionary) -> bool: return true
	func _apply_selected_mission_dropship_return(_id: String) -> bool: return_calls += 1; return true
	func _set_mission_dropship_card_feedback(_id: String, _text: String) -> void: pass
	func finalize_station_craft_update() -> void: pass
	func preview_station_craft_admission(_craft: Dictionary, _pad: String = "", _reentry: bool = false) -> Dictionary: return {"ok":true,"pad_id":"station_pad","position":Vector2.ZERO,"ground_body_profile":{}}

class Person extends Node2D:
	var identity := "polisa_recruit_1"
	func get_health() -> int: return 100
	func get_unit_id() -> String: return identity

class Setup extends Node:
	var actor: Node
	var sim: Node
	func get_polisa_recruit_admission(id: String) -> Dictionary:
		if id != "polisa_recruit_1" or not is_instance_valid(actor): return {"ok":false}
		return {"ok":true,"unit_id":id,"actor_id":actor.get_instance_id()}
	func retire_polisa_service_actors(ids: PackedStringArray) -> Dictionary:
		if ids.has("station_shuttle_pilot_1"): sim.pilot = null
		if ids.has("polisa_recruit_1"): sim.actor = null
		return {"ok":true}

class Simulation extends Node:
	var actor: Node
	var pilot: Node
	var effects_queue := []
	var landed := true
	func _resolve_known_unit(id: String) -> Node: return actor if id == "polisa_recruit_1" else (pilot if id == "station_shuttle_pilot_1" else null)
	func get_hex_unit_state(id: String) -> Dictionary:
		if not landed: return {}
		if id == "polisa_recruit_1" and is_instance_valid(actor): return {"grid":Vector2i(1,1)}
		if id == "station_shuttle_pilot_1" and is_instance_valid(pilot): return {"grid":Vector2i(1,1)}
		return {}
	func _discard_pending_move_commands_for_unit(_id: String) -> void: pass
	## Attrappen-Eingabe: Der Controller fragt die Radar-Projektion je Schiff ab (seit ee1ff1a8b); hier gibt es keine fremden Flugzeuge.
	func get_air_support_radar_contacts(_craft_id: String) -> Dictionary: return {"ok":false}

class ShuttleOwner extends RefCounted:
	var phase := "station_landing_required"
	func get_snapshot() -> Dictionary: return {"phase":phase,"craft_id":"shuttle","person_id":"polisa_recruit_1"}

func _pending_gate(_id: String) -> Dictionary: return {"ok":true,"handled":true,"pending":true,"message":"Shuttle wird vorbereitet"}
func _open_gate(_id: String) -> Dictionary: return {"ok":true,"handled":false}

func _init() -> void: call_deferred("_run")
func _run() -> void:
	var errors: Array[String] = []
	var place := Node.new(); root.add_child(place); place.set_meta("location_id", "polisa")
	place.set_meta("singleplayer_visit_identities", {"craft":{"craft_id":"craft","unit_ids":[],"fireteam_ids":[]}})
	var c := Controller.new(); c.name = "TacticalController"; place.add_child(c)
	c.set_polisa_service_return_gate(Callable(self,"_pending_gate"))
	c._on_mission_dropship_return_pressed("craft")
	if c.return_calls != 0: errors.append("tactical return waits for service")
	c.set_polisa_service_return_gate(Callable(self,"_open_gate"))
	c._on_mission_dropship_return_pressed("craft")
	if c.return_calls != 1: errors.append("ordinary tactical return continues")
	var setup := Setup.new(); setup.name = "MissionSetup"; place.add_child(setup)
	var sim := Simulation.new(); sim.name = "SimulationRoot"; place.add_child(sim)
	setup.sim = sim
	var person := Person.new(); place.add_child(person); setup.actor = person; sim.actor = person
	var pilot := Person.new(); pilot.identity = "station_shuttle_pilot_1"; place.add_child(pilot); sim.pilot = pilot
	if not c.has_method("register_polisa_resident"):
		errors.append("resident admission missing")
	else:
		var resident: Dictionary = c.call("register_polisa_resident", "polisa_recruit_1")
		if not resident.get("ok", false) or not c._deployed_unit_ids.has("polisa_recruit_1") or not Array(place.get_meta("singleplayer_visit_identities").craft.unit_ids).is_empty(): errors.append("resident without player visit")
		if not c.call("register_polisa_resident", "polisa_recruit_1").get("ok", false): errors.append("resident replay")
		if not c.has_method("claim_polisa_resident"):
			errors.append("resident claim missing")
		else:
			if c.call("claim_polisa_resident", "polisa_recruit_1", "wrong").get("ok", false): errors.append("resident claim rejects absent ship")
			var claimed: Dictionary = c.call("claim_polisa_resident", "polisa_recruit_1", "craft")
			if not claimed.get("ok", false) or not Array(place.get_meta("singleplayer_visit_identities").craft.unit_ids).has("polisa_recruit_1") or Dictionary(place.get_meta("singleplayer_station_personnel")).has("polisa_recruit_1") or bool(person.get_meta("dropship_embarked", false)): errors.append("resident claim keeps actor on foot")
			place.set_meta("singleplayer_visit_identities", {"craft":{"craft_id":"craft","unit_ids":[],"fireteam_ids":[]}})
		c._deployed_unit_ids.erase("polisa_recruit_1")
		c._deployed_unit_positions.erase("polisa_recruit_1")
		place.set_meta("singleplayer_station_personnel", {})
	var invalid: Dictionary = c.register_polisa_recruit_person("polisa_recruit_1", "wrong")
	if invalid.get("ok", false) or not c._deployed_unit_ids.is_empty(): errors.append("reject invalid craft")
	var result: Dictionary = c.register_polisa_recruit_person("polisa_recruit_1", "craft")
	var visits: Dictionary = place.get_meta("singleplayer_visit_identities")
	if not result.get("ok", false) or not c._deployed_unit_ids.has("polisa_recruit_1") or not Array(visits.craft.unit_ids).has("polisa_recruit_1"): errors.append("registered deployed crew")
	if bool(person.get_meta("dropship_embarked", false)): errors.append("does not fake boarding")
	var replay: Dictionary = c.register_polisa_recruit_person("polisa_recruit_1", "craft")
	if not replay.get("ok", false) or Array(place.get_meta("singleplayer_visit_identities").craft.unit_ids).count("polisa_recruit_1") != 1: errors.append("idempotency")
	var transfer: Dictionary = c.preview_polisa_service_transfer("polisa_recruit_1", "craft", "station_shuttle_pilot_1")
	if not transfer.get("ok", false): errors.append("grounded actor and pilot can prepare transfer")
	if not Array(place.get_meta("singleplayer_visit_identities").craft.unit_ids).has("polisa_recruit_1"): errors.append("preview must not mutate visit")
	c._parallel_drop_sequences_by_craft["craft"] = {"units":[person]}
	c._parallel_drop_sequences_by_craft["shuttle"] = {"units":[]}
	c._publish_polisa_service_transfer("craft", "shuttle", "polisa_recruit_1", "station_shuttle_pilot_1")
	visits = place.get_meta("singleplayer_visit_identities")
	if Array(visits.craft.unit_ids).has("polisa_recruit_1") or not Array(visits.shuttle.unit_ids).has("polisa_recruit_1"): errors.append("source-to-shuttle visit transfer")
	if Array(c._parallel_drop_sequences_by_craft.craft.units).has(person) or not Array(c._parallel_drop_sequences_by_craft.shuttle.units).has(person): errors.append("source-to-shuttle actor transfer")
	person.set_meta("dropship_embarked", true)
	if c.can_cancel_polisa_service_transfer("craft", "shuttle", "polisa_recruit_1", "station_shuttle_pilot_1").get("ok",false): errors.append("embarked actor cannot enter cancelling state")
	person.set_meta("dropship_embarked", false)
	if not c.can_cancel_polisa_service_transfer("craft", "shuttle", "polisa_recruit_1", "station_shuttle_pilot_1").get("ok",false): errors.append("grounded actor can be cancelled")
	var rolled_back: Dictionary = c.cancel_polisa_service_transfer("craft", "shuttle", "polisa_recruit_1", "station_shuttle_pilot_1")
	visits = place.get_meta("singleplayer_visit_identities")
	if not rolled_back.get("ok",false) or not Array(visits.craft.unit_ids).has("polisa_recruit_1") or visits.has("shuttle") or sim.pilot != null: errors.append("safe grounded transfer cancellation")
	sim.pilot = pilot
	c._parallel_drop_sequences_by_craft["shuttle"] = {"units":[],"phase":"complete","position":Vector2.ZERO,"lz_position":Vector2.ZERO}
	c._publish_polisa_service_transfer("craft", "shuttle", "polisa_recruit_1", "station_shuttle_pilot_1")
	var sequence := {"craft_id":"shuttle", "phase":"outbound", "lz_position":Vector2.ZERO,"approach_angle":"NW", "embarked_unit_ids":{"polisa_recruit_1":true,"station_shuttle_pilot_1":true}}
	sequence.position = c._get_drop_staging_position_for_lz(Vector2.ZERO,"NW")
	if c.record_polisa_service_departure(sequence).get("ok", false): errors.append("on-ground actors do not prove boarding")
	sim.landed = false
	person.set_meta("dropship_embarked", true); pilot.set_meta("dropship_embarked", true)
	var at_pad := sequence.duplicate(true); at_pad.position = Vector2.ZERO
	if c.record_polisa_service_departure(at_pad).get("ok", false): errors.append("takeoff must physically clear pad")
	var departure: Dictionary = c.record_polisa_service_departure(sequence)
	if not departure.get("ok", false) or not c.verify_polisa_service_departure("polisa_recruit_1", "shuttle", departure): errors.append("actor-bound departure proof")
	if c.verify_polisa_service_departure("other", "shuttle", departure): errors.append("departure proof bound to person")
	c._parallel_drop_sequences_by_craft.erase("shuttle")
	var owner := ShuttleOwner.new()
	var incoming: Dictionary = c.begin_polisa_service_return_landing("shuttle", "polisa_recruit_1", owner)
	if not incoming.get("ok", false) or c._parallel_drop_sequences_by_craft.get("shuttle", {}).get("phase") != "inbound": errors.append("return creates physical inbound sequence")
	var arrived: Dictionary = c._parallel_drop_sequences_by_craft.shuttle.duplicate(true)
	if c.record_polisa_service_landing(arrived).get("ok", false): errors.append("inbound is not touchdown")
	arrived.phase = "landed"; arrived.position = arrived.lz_position
	var landed: Dictionary = c.record_polisa_service_landing(arrived)
	if not landed.get("ok", false) or not c.verify_polisa_service_arrival("landing_polisa", "polisa_recruit_1", "shuttle", landed): errors.append("actual station touchdown proof")
	if c.record_polisa_service_disembark(arrived).get("ok", false): errors.append("boarding is not disembark")
	sim.landed=true; person.set_meta("dropship_embarked", false); pilot.set_meta("dropship_embarked", false)
	c._deployed_unit_ids["polisa_recruit_1"] = true; c._deployed_unit_ids["station_shuttle_pilot_1"] = true
	arrived.phase = "complete"
	var exited: Dictionary = c.record_polisa_service_disembark(arrived)
	if not exited.get("ok", false) or not c.verify_polisa_service_arrival("disembark_polisa", "polisa_recruit_1", "shuttle", exited): errors.append("actual station disembark proof")
	var retired: Dictionary = c.retire_polisa_service_ship("shuttle", "polisa_recruit_1", exited)
	if not retired.get("ok", false) or not c.verify_polisa_service_retirement("polisa_recruit_1", "shuttle", retired): errors.append("station service teardown proof")
	if not place.get_meta("singleplayer_station_personnel", {}).has("polisa_recruit_1") or not is_instance_valid(person) or c._parallel_drop_sequences_by_craft.has("shuttle"): errors.append("resident remains while shuttle is removed")
	for error in errors: printerr("FAIL: " + error)
	print("PASS: Polisa recruit controller ownership" if errors.is_empty() else "FAIL")
	place.free(); quit(0 if errors.is_empty() else 1)
