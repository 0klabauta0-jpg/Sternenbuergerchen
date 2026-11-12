extends SceneTree

class Person extends Node2D:
	var id := ""
	func get_health() -> int: return 100
	func get_unit_id() -> String: return id

class Controller extends Node:
	var people := {}
	var cards := {}
	var admitted := 0
	var fail_admission := false
	var boarding_complete := false
	func _get_campaign_sortie_unit(id: String) -> Node: return people.get(id)
	func preview_station_craft_admission(_craft: Dictionary, _pad: String = "") -> Dictionary: return {"ok":true,"pad_id":"pad_1"}
	func admit_station_craft(craft: Dictionary, pad: String, _request: String) -> Dictionary:
		if fail_admission: return {"ok":false,"reason":"pad_changed"}
		admitted += 1
		cards[craft.craft_id] = {"craft_id":craft.craft_id,"pad_id":pad}
		return {"ok":true,"craft_id":craft.craft_id,"pad_id":pad}
	func _update_mission_dropship_card_fields(id: String, fields: Dictionary) -> void: cards[id].merge(fields,true)
	func finalize_station_craft_update() -> void: pass
	func _is_parked_campaign_dropship(id: String) -> bool: return cards.has(id)
	func _find_mission_dropship_card_entry(id: String) -> Dictionary: return cards.get(id, {})
	func get_campaign_pilot_flight_guard(_id: String) -> Dictionary: return {"ok":boarding_complete}
	func request_campaign_crew_boarding(_id: String) -> Dictionary: return {"ok":false,"reason":"pilot_boarding_pending"}
	func _campaign_landed_craft_position(_id: String) -> Vector2: return Vector2.ZERO
	func preview_polisa_service_transfer(_person: String, source: String, _pilot: String) -> Dictionary: return {"ok":source == "own_craft"}
	func _publish_polisa_service_transfer(source: String, target: String, person: String, pilot: String) -> void:
		var visits: Dictionary = get_parent().get_meta("singleplayer_visit_identities", {}).duplicate(true)
		visits[source].unit_ids.erase(person)
		visits[target] = {"craft_id":target,"origin_kind":"station_service","unit_ids":[pilot,person]}
		get_parent().set_meta("singleplayer_visit_identities", visits)
		cards[target]["pilot_unit_id"] = pilot

class Tile extends RefCounted:
	func is_valid() -> bool: return true
class Terrain extends Node:
	func get_grid_topology() -> String: return "hex_axial_v1"
	func get_revision() -> int: return 1
	func is_walkable(_grid: Vector2i) -> bool: return true
	func get_tile_at_grid(_grid: Vector2i) -> RefCounted: return Tile.new()
	func world_to_grid(p: Vector2) -> Vector2i: return Vector2i(roundi(p.x / 16), roundi(p.y / 16))
	func grid_to_world(p: Vector2i) -> Vector2: return Vector2(p) * 16
	func get_legal_hex_neighbors(p: Vector2i) -> Array: return [p + Vector2i.RIGHT, p + Vector2i.DOWN, p + Vector2i.LEFT, p + Vector2i.UP]
class Simulation extends Node:
	var terrain: Node
	var commands: Array = []
	func is_hex_ground_runtime_active() -> bool: return true
	func get_hex_ground_terrain_registry() -> Node: return terrain
	func get_hex_ground_planning_snapshot() -> Dictionary: return {"terrain_revision":1,"units_by_id":{"station_shuttle_pilot_1":{"grid":Vector2i(4,4)},"polisa_recruit_1":{"grid":Vector2i(5,4)}},"occupant_by_grid":{Vector2i(4,4):"station_shuttle_pilot_1",Vector2i(5,4):"polisa_recruit_1"}}
	func get_hex_unit_state(id: String) -> Dictionary: return get_hex_ground_planning_snapshot().units_by_id.get(id,{})
	func enqueue_command(command: Dictionary) -> void: commands.append(command)

class Setup extends Node:
	var requested := {}
	func request_polisa_recruit_admission(profile: Dictionary, grid: Vector2i) -> Dictionary:
		requested = {"profile":profile,"grid":grid}
		return {"ok":true,"unit_id":profile.unit_id,"state":"pending"}
	func get_polisa_recruit_admission(_id: String) -> Dictionary:
		return {"ok":false,"reason":"unknown_recruit"}

func _init() -> void: call_deferred("_run")
func _run() -> void:
	var errors: Array[String] = []
	var place := Node.new(); root.add_child(place); place.set_meta("location_id","polisa")
	var controller := Controller.new(); controller.name = "TacticalController"; place.add_child(controller)
	var setup := Setup.new(); setup.name = "MissionSetup"; place.add_child(setup)
	var terrain := Terrain.new(); place.add_child(terrain)
	var sim := Simulation.new(); sim.name = "SimulationRoot"; sim.terrain = terrain; place.add_child(sim)
	var bridge = load("res://scripts/mission/polisa_shuttle_station_lifecycle.gd").new()
	var profile: Dictionary = bridge.build_station_pilot_profile("service_1")
	if not String(profile.get("unit_id", "")).begins_with("station_shuttle_pilot_") or profile.get("roster_role_category") != "pilot": errors.append("separate station pilot profile")
	var pilot_request: Dictionary = bridge.request_station_pilot(place, "service_1", Vector2i(4, 5))
	if not pilot_request.get("ok", false) or setup.requested.get("grid") != Vector2i(4, 5) or setup.requested.get("profile", {}).get("unit_id") != profile.unit_id: errors.append("pilot requests actual selection admission")
	var result: Dictionary = bridge.admit(place, "service_1", "station_shuttle_pilot_1", "polisa_recruit_1")
	if result.get("ok", false) or controller.admitted != 0: errors.append("missing actors must reject")
	for id in ["station_shuttle_pilot_1", "polisa_recruit_1"]:
		var person := Person.new(); person.id = id; place.add_child(person); controller.people[id] = person
	result = bridge.admit(place, "service_1", "station_shuttle_pilot_1", "polisa_recruit_1")
	if not result.get("ok", false) or controller.admitted != 1: errors.append("real local crew admits")
	var visits: Dictionary = place.get_meta("singleplayer_visit_identities", {})
	if Array(visits.get("service_1", {}).get("unit_ids", [])) != ["station_shuttle_pilot_1", "polisa_recruit_1"]: errors.append("crew identity")
	if controller.cards.get("service_1", {}).get("pilot_unit_id", "") != "station_shuttle_pilot_1": errors.append("pilot identity")
	var walk: Dictionary = bridge.request_boarding_walk(place, "service_1")
	if not walk.get("ok", false) or sim.commands.size() != 2: errors.append("real simulation movement commands")
	if sim.commands.size() == 2 and (sim.commands[0].target_position == sim.commands[1].target_position): errors.append("distinct boarding positions")
	if bridge.request_boarding(place, "service_1").get("reason") != "pilot_boarding_pending": errors.append("boarding uses controller lifecycle")
	if bridge.verify_boarded(place, "polisa_recruit_1", "service_1"): errors.append("pending boarding rejected")
	controller.boarding_complete = true
	if not bridge.verify_boarded(place, "polisa_recruit_1", "service_1"): errors.append("confirmed boarding accepted")
	result = bridge.admit(place, "service_1", "station_shuttle_pilot_1", "polisa_recruit_1")
	if not result.get("ok", false) or not result.get("replayed", false) or controller.admitted != 1: errors.append("replay")
	place.set_meta("singleplayer_visit_identities", {})
	result = bridge.admit(place, "service_1", "station_shuttle_pilot_1", "polisa_recruit_1")
	if result.get("ok", false) or controller.admitted != 1: errors.append("stale replay must reject")
	place.set_meta("singleplayer_visit_identities", {"own_craft":{"craft_id":"own_craft","unit_ids":["polisa_recruit_1"],"fireteam_ids":[]}})
	controller.fail_admission = true
	result = bridge.admit(place, "service_2", "station_shuttle_pilot_1", "polisa_recruit_1", "own_craft")
	if result.get("ok", false) or not Array(place.get_meta("singleplayer_visit_identities").own_craft.unit_ids).has("polisa_recruit_1"): errors.append("failed pad admission preserves source")
	controller.fail_admission = false
	result = bridge.admit(place, "service_2", "station_shuttle_pilot_1", "polisa_recruit_1", "own_craft")
	var transferred: Dictionary = place.get_meta("singleplayer_visit_identities")
	if not result.get("ok", false) or Array(transferred.own_craft.unit_ids).has("polisa_recruit_1") or not Array(transferred.service_2.unit_ids).has("polisa_recruit_1"): errors.append("atomic owner transfer")
	for error in errors: printerr("FAIL: " + error)
	print("PASS: station shuttle admission" if errors.is_empty() else "FAIL")
	place.free(); quit(0 if errors.is_empty() else 1)
