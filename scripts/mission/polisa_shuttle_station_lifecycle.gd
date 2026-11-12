extends RefCounted
## Admits a foreign physical station shuttle only for real existing local crew.
## Crew spawning, movement and boarding remain their respective runtime owners.
var _receipts := {}
const HEX_ADMISSION = preload("res://scripts/mission/hex_ground_admission.gd")

func build_station_pilot_profile(craft_id: String) -> Dictionary:
	if craft_id.strip_edges().is_empty(): return {}
	var id := "station_shuttle_pilot_" + craft_id.sha256_text().substr(0, 16)
	var configuration := {"role":"pilot", "experience":"trained", "armor":"suit", "weapon":"pistol"}
	var setup = load("res://scripts/meta/skirmish_start_configuration.gd").new()
	var profile: Dictionary = setup.build_points_person(configuration, id, {})
	profile["player_profile_id"] = "polisa_station_service"
	profile["fireteam_id"] = ""
	return profile

func request_station_pilot(place: Node, craft_id: String, spawn_grid: Vector2i) -> Dictionary:
	if not is_instance_valid(place) or not place.is_inside_tree() or String(place.get_meta("location_id", "")) != "polisa": return _reject("station_unavailable")
	var setup := place.get_node_or_null("MissionSetup")
	if not is_instance_valid(setup) or not setup.has_method("request_polisa_recruit_admission") or not setup.has_method("get_polisa_recruit_admission"): return _reject("station_selection_unavailable")
	var profile := build_station_pilot_profile(craft_id)
	if profile.is_empty(): return _reject("invalid_craft")
	var existing: Dictionary = setup.call("get_polisa_recruit_admission", String(profile.unit_id))
	if existing.get("ok", false):
		existing["replayed"] = true
		return existing
	if String(existing.get("reason", "")) != "unknown_recruit": return existing
	return setup.call("request_polisa_recruit_admission", profile, spawn_grid)

func admit(place: Node, craft_id: String, pilot_id: String, person_id: String, source_craft_id: String = "") -> Dictionary:
	if not is_instance_valid(place) or not place.is_inside_tree() or String(place.get_meta("location_id", "")) != "polisa": return _reject("station_unavailable")
	if craft_id.is_empty() or not pilot_id.begins_with("station_shuttle_pilot_") or not person_id.begins_with("polisa_recruit_") or pilot_id == person_id: return _reject("invalid_crew")
	var signature := JSON.stringify([place.get_instance_id(), craft_id, pilot_id, person_id, source_craft_id])
	if _receipts.has(craft_id):
		var old: Dictionary = _receipts[craft_id]
		if old.signature != signature: return _reject("request_conflict")
		var current: Dictionary = Dictionary(place.get_meta("singleplayer_visit_identities", {})).get(craft_id, {})
		if String(current.get("origin_kind", "")) != "station_service" or Array(current.get("unit_ids", [])) != [pilot_id, person_id]: return _reject("station_receipt_stale")
		var replay: Dictionary = old.result.duplicate(true)
		replay["replayed"] = true
		return replay
	var controller := place.get_node_or_null("TacticalController")
	if not is_instance_valid(controller): return _reject("station_controller_missing")
	for method in ["_get_campaign_sortie_unit", "preview_station_craft_admission", "admit_station_craft", "_update_mission_dropship_card_fields", "finalize_station_craft_update"]:
		if not controller.has_method(method): return _reject("station_capability_missing")
	for id in [pilot_id, person_id]:
		var actor: Node = controller.call("_get_campaign_sortie_unit", id)
		if not is_instance_valid(actor) or not actor.is_inside_tree() or not actor is Node2D or not actor.has_method("get_health") or int(actor.call("get_health")) <= 0 or bool(actor.get_meta("dropship_embarked", false)):
			return _reject("crew_not_present")
	var visits: Dictionary = Dictionary(place.get_meta("singleplayer_visit_identities", {})).duplicate(true)
	if visits.has(craft_id): return _reject("craft_already_present")
	for id in visits:
		var ids: Array = Array(Dictionary(visits[id]).get("unit_ids", []))
		if ids.has(pilot_id) or (ids.has(person_id) and String(id) != source_craft_id): return _reject("crew_already_assigned")
	if not source_craft_id.is_empty():
		if not controller.has_method("preview_polisa_service_transfer") or not controller.has_method("_publish_polisa_service_transfer"): return _reject("transfer_capability_missing")
		var transfer: Dictionary = controller.call("preview_polisa_service_transfer", person_id, source_craft_id, pilot_id)
		if not transfer.get("ok", false): return transfer
	var craft := {"craft_id":craft_id,"model_id":"cutlass","craft_type":"dropship","display_name":"Polisa Shuttle","crew_capacity":8,"seat_capacity":8}
	var preview: Dictionary = controller.call("preview_station_craft_admission", craft, "")
	if not preview.get("ok", false): return preview
	var pad := String(preview.get("pad_id", ""))
	if pad.is_empty(): return _reject("station_pad_missing")
	var admitted: Dictionary = controller.call("admit_station_craft", craft, pad, "service-admit:" + craft_id)
	if not admitted.get("ok", false): return admitted
	# Controller admission is the last fallible operation; publish crew ownership
	# and pilot before signals or view refresh. A click is not boarding evidence.
	if source_craft_id.is_empty():
		visits[craft_id] = {"craft_id":craft_id,"location_id":"polisa","scenario_id":"polisa_visit","job_id":"","origin_kind":"station_service","unit_ids":[pilot_id,person_id],"fireteam_ids":[]}
		place.set_meta("singleplayer_visit_identities", visits)
		controller.call("_update_mission_dropship_card_fields", craft_id, {"pilot_unit_id":pilot_id,"service_shuttle":true})
	else:
		controller.call("_publish_polisa_service_transfer", source_craft_id, craft_id, person_id, pilot_id)
	var result := {"ok":true,"craft_id":craft_id,"pilot_id":pilot_id,"person_id":person_id,"pad_id":pad}
	_receipts[craft_id] = {"signature":signature,"result":result.duplicate(true)}
	controller.call("finalize_station_craft_update")
	return result

func verify_boarded(place: Node, person_id: String, craft_id: String) -> bool:
	if not is_instance_valid(place) or not place.is_inside_tree() or String(place.get_meta("location_id", "")) != "polisa": return false
	var visit: Dictionary = Dictionary(place.get_meta("singleplayer_visit_identities", {})).get(craft_id, {})
	if String(visit.get("origin_kind", "")) != "station_service" or not Array(visit.get("unit_ids", [])).has(person_id): return false
	var controller := place.get_node_or_null("TacticalController")
	if not is_instance_valid(controller): return false
	for method in ["_is_parked_campaign_dropship", "_find_mission_dropship_card_entry", "get_campaign_pilot_flight_guard"]:
		if not controller.has_method(method): return false
	if not bool(controller.call("_is_parked_campaign_dropship", craft_id)): return false
	var card: Dictionary = controller.call("_find_mission_dropship_card_entry", craft_id)
	var pilot := String(card.get("pilot_unit_id", ""))
	if pilot.is_empty() or pilot == person_id or not Array(visit.get("unit_ids", [])).has(pilot): return false
	var evidence: Dictionary = controller.call("get_campaign_pilot_flight_guard", craft_id)
	return evidence.get("ok", false) == true

func request_boarding(place: Node, craft_id: String) -> Dictionary:
	if not is_instance_valid(place) or not place.is_inside_tree() or String(place.get_meta("location_id", "")) != "polisa": return _reject("station_unavailable")
	var visit: Dictionary = Dictionary(place.get_meta("singleplayer_visit_identities", {})).get(craft_id, {})
	if String(visit.get("origin_kind", "")) != "station_service" or Array(visit.get("unit_ids", [])).size() != 2: return _reject("service_crew_unavailable")
	var controller := place.get_node_or_null("TacticalController")
	if not is_instance_valid(controller) or not controller.has_method("request_campaign_crew_boarding"): return _reject("boarding_capability_missing")
	return controller.call("request_campaign_crew_boarding", craft_id)

## Authoritative SimulationRoot receives ordinary movement commands; completion
## is subsequently confirmed by its actual boarding guard, never by this method.
func request_boarding_walk(place: Node, craft_id: String) -> Dictionary:
	if not is_instance_valid(place) or not place.is_inside_tree() or String(place.get_meta("location_id", "")) != "polisa": return _reject("station_unavailable")
	var visit: Dictionary = Dictionary(place.get_meta("singleplayer_visit_identities", {})).get(craft_id, {})
	var crew := PackedStringArray(visit.get("unit_ids", []))
	if String(visit.get("origin_kind", "")) != "station_service" or crew.size() != 2 or crew[0] == crew[1]: return _reject("service_crew_unavailable")
	var controller := place.get_node_or_null("TacticalController")
	var simulation := place.get_node_or_null("SimulationRoot")
	if not is_instance_valid(controller) or not is_instance_valid(simulation): return _reject("station_runtime_unavailable")
	for method in ["_is_parked_campaign_dropship", "_campaign_landed_craft_position", "_get_campaign_sortie_unit"]:
		if not controller.has_method(method): return _reject("station_capability_missing")
	for method in ["is_hex_ground_runtime_active", "get_hex_ground_terrain_registry", "get_hex_ground_planning_snapshot", "get_hex_unit_state", "enqueue_command"]:
		if not simulation.has_method(method): return _reject("ground_capability_missing")
	if not bool(controller.call("_is_parked_campaign_dropship", craft_id)) or not bool(simulation.call("is_hex_ground_runtime_active")): return _reject("station_ground_unavailable")
	var position: Vector2 = controller.call("_campaign_landed_craft_position", craft_id)
	var terrain: Node = simulation.call("get_hex_ground_terrain_registry")
	if not position.is_finite() or not is_instance_valid(terrain) or not terrain.has_method("world_to_grid") or not terrain.has_method("grid_to_world"): return _reject("boarding_position_unavailable")
	var snapshot: Dictionary = simulation.call("get_hex_ground_planning_snapshot")
	if not snapshot.get("units_by_id") is Dictionary or not snapshot.get("occupant_by_grid") is Dictionary: return _reject("ground_snapshot_unavailable")
	snapshot = snapshot.duplicate(true)
	var distances := {}
	for id: String in crew:
		var actor: Node = controller.call("_get_campaign_sortie_unit", id)
		var current: Dictionary = simulation.call("get_hex_unit_state", id)
		if not is_instance_valid(actor) or not actor.is_inside_tree() or not actor.has_method("get_health") or int(actor.call("get_health")) <= 0 or bool(actor.get_meta("dropship_embarked", false)) or current.is_empty() or not current.get("grid") is Vector2i: return _reject("crew_ground_unavailable")
		var grid: Vector2i = current.grid
		distances[id] = Vector2(terrain.call("grid_to_world", grid)).distance_squared_to(position)
		snapshot.units_by_id.erase(id)
		if snapshot.occupant_by_grid.get(grid) == id: snapshot.occupant_by_grid.erase(grid)
	# Assign nearer boarding cells to the people already nearest the craft;
	# this avoids swapping their destinations through a narrow one-cell corridor.
	var ordered: Array = Array(crew)
	ordered.sort_custom(func(a, b): return float(distances[a]) < float(distances[b]))
	crew = PackedStringArray(ordered)
	var anchor: Vector2i = terrain.call("world_to_grid", position)
	var anchors: Array = [anchor]
	if terrain.has_method("get_legal_hex_neighbors"): anchors.append_array(terrain.call("get_legal_hex_neighbors", anchor))
	var chosen := {}
	for candidate: Vector2i in anchors:
		var plan: Dictionary = HEX_ADMISSION.new().plan_group(crew, candidate, terrain, snapshot, 32)
		if not plan.get("ok", false): continue
		var in_range := true
		for entry: Dictionary in plan.placements:
			var target: Vector2 = terrain.call("grid_to_world", entry.grid)
			if not target.is_finite() or target.distance_to(position) > 128.0: in_range = false
		if in_range: chosen = plan; break
	if chosen.is_empty(): return _reject("boarding_approach_unavailable")
	for entry: Dictionary in chosen.placements:
		var target: Vector2 = terrain.call("grid_to_world", entry.grid)
		simulation.call("enqueue_command", {"type":"move_to_position","unit_id":String(entry.unit_id),"target_position":target,"command_token":"station-service:%s:%s" % [craft_id, String(entry.unit_id)],"requeue_until_target":true})
	return {"ok":true,"pending":true}

func _reject(reason: String) -> Dictionary:
	return {"ok":false,"reason":reason}
