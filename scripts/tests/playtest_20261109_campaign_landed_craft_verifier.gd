extends SceneTree

const MISSION = preload("res://scenes/tests/mission_reactivity_test.tscn")
var passed: int = 0
var failed: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await _test_campaign_and_legacy("res://data/mission_scenarios/satellite_recovery.json", "res://maps/satellite_crash_site.json", true)
	await _test_campaign_and_legacy("res://data/mission_scenarios/ground_mission01_default.json", "res://maps/Ground_Mission01_32x32.json", false)
	print("CAMPAIGN_LANDED_CRAFT_RESULTS passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _test_campaign_and_legacy(scenario_path: String, map_path: String, should_park: bool) -> void:
	var mission: Node = MISSION.instantiate()
	var setup: Node = mission.get_node("MissionSetup")
	setup.set("map_file_path", map_path)
	setup.set("scenario_file_path", scenario_path)
	setup.set("selected_team_unit_ids", PackedStringArray(["unit_alpha", "unit_bravo"]))
	setup.set("selected_team_fireteam_ids", PackedStringArray(["ft1", "ft2"]))
	setup.set("defer_friendly_runtime_activation", true)
	root.add_child(mission)
	await process_frame
	var controller: Node = mission.get_node("TacticalController")
	controller.set_process(false)
	var teams: PackedStringArray = controller.call("_get_available_fireteam_ids")
	_check(teams.size() >= 2, "Actual scenario exposes two independent fireteams: " + str(should_park))
	if teams.size() < 2:
		mission.queue_free()
		await process_frame
		return
	var first_units: Array = controller.call("_get_fireteam_units", String(teams[0]), true)
	var second_units: Array = controller.call("_get_fireteam_units", String(teams[1]), true)
	var first_ids: Array = _unit_ids(first_units)
	var second_ids: Array = _unit_ids(second_units)
	var map = load("res://scripts/terrain/terrain_map_data.gd").load_from_file(map_path)
	var first_lz: Vector2 = map.get_marker_position("spawn_alpha")
	if not should_park: first_lz = _other_site(controller, map, first_lz)
	var second_lz: Vector2 = first_lz if should_park else _other_site(controller, map, first_lz)
	var state: Dictionary = controller.call("get_planning_state")
	state.merge({"mission_drop_source": "homebase_direct", "mission_drop_craft_id": "craft_a", "mission_drop_state": "waiting", "drop_ship_staged": true, "embarked_unit_ids": first_ids + second_ids, "deployed_unit_ids": [], "has_lz_position": true, "lz_position": first_lz, "selected_fireteams": [teams[0]], "mission_drop_cards": [_card("craft_a", String(teams[0]), first_ids, first_lz), _card_b(String(teams[1]), second_ids, second_lz, should_park)]}, true)
	controller.call("set_planning_state", state)
	controller.call("_select_mission_dropship_craft", "craft_a", false)
	controller.call("_set_selected_fireteams", PackedStringArray([teams[0]]), false)
	var started_first: bool = bool(controller.call("_try_start_drop_sequence", true))
	_check(started_first, "First real craft starts map flight: " + str(should_park))
	controller.call("_select_mission_dropship_craft", "craft_b", false)
	controller.call("_set_selected_fireteams", PackedStringArray([teams[1]]), false)
	controller.set("_lz_position", second_lz)
	controller.set("_has_lz_position", true)
	_check(bool(controller.call("_try_start_drop_sequence", true)) == not should_park, "Second craft respects actual pad capacity while legacy parallel flight remains free: " + str(should_park))
	for tick in range(7):
		controller.call("_update_drop_sequence", 30.0)
		await physics_frame
	var first: Dictionary = _find_card(controller, "craft_a")
	var second: Dictionary = _find_card(controller, "craft_b")
	var deployed_before: Array = Array(Dictionary(controller.call("get_planning_state")).get("deployed_unit_ids", []))
	if should_park:
		_check(first.get("state") == "complete" and second.get("state") == "waiting", "Campaign craft stays landed while another waits for the single authored pad")
		var first_landed: Vector2 = Vector2(first.get("dropship_position", Vector2.ZERO))
		_check(first_landed.distance_to(first_lz) < 128.0, "Parked campaign craft retains its real landing position (free landing may shift it to a safe tile)")
		_check(Array(first.get("embarked_unit_ids", [])).is_empty() and Array(second.get("embarked_unit_ids", [])) == second_ids and deployed_before.size() == first_ids.size(), "Only landed craft crew deploys; waiting payload is preserved")
		_check(bool(controller.call("_can_request_mission_dropship_return", first)), "Actually parked craft exposes explicit return")
		if String(first.get("state", "")) == "complete" and String(second.get("state", "")) == "waiting":
			_check(bool(controller.call("_apply_selected_mission_dropship_return", "craft_a")), "Parked craft explicit return accepts")
			var returning: Dictionary = _find_card(controller, "craft_a")
			_check(returning.get("state") == "outbound" and Vector2(returning.get("dropship_position", Vector2.ZERO)).is_equal_approx(first_landed), "Return begins actual outbound at pad before meta transit")
			_check(_find_card(controller, "craft_b").get("state") == "waiting", "One return leaves the other craft independently waiting")
			controller.call("_update_drop_sequence", 0.001)
			_check(_find_card(controller, "craft_a").get("state") == "outbound", "No instantaneous return to homebase before visible flight")
			controller.call("_update_drop_sequence", 30.0)
			_check(String(_find_card(controller, "craft_a").get("state", "")) == "to_homebase", "Only map-edge outbound completion requests meta return")
			controller.call("_select_mission_dropship_craft", "craft_b", false)
			controller.call("_set_selected_fireteams", PackedStringArray([teams[1]]), false)
			# Die abgesetzte Mannschaft steht noch am ersten Platz; das zweite Schiff landet daher auf einem anderen sicheren Feld.
			controller.set("_lz_position", _other_site(controller, map, first_landed))
			controller.set("_has_lz_position", true)
			_check(bool(controller.call("_try_start_drop_sequence", true)), "Waiting craft can land on a free site after first craft clears outbound")
			for tick in range(7):
				controller.call("_update_drop_sequence", 30.0)
				await physics_frame
			_check(_find_card(controller, "craft_b").get("state") == "complete", "Second independent craft lands and remains parked")
			_check(bool(controller.call("_apply_selected_mission_dropship_return", "craft_b")), "Second parked craft remains independently returnable")
			_check(_find_card(controller, "craft_b").get("state") == "outbound", "Second explicit return also uses visible outbound")
			_check(Array(Dictionary(controller.call("get_planning_state")).get("deployed_unit_ids", [])).size() == first_ids.size() + second_ids.size(), "Sequential pad visits do not duplicate or lose deployed unit IDs")
	else:
		_check(String(first.get("state", "")).begins_with("to_") and String(second.get("state", "")).begins_with("to_"), "Legacy combat primary and parallel craft still auto-return after unloading")
	mission.queue_free()
	await process_frame

func _card(id: String, team: String, units: Array, lz: Vector2) -> Dictionary:
	return {"craft_id": id, "model_id": "cutlass", "display_name": id, "payload_source": "homebase_direct", "state": "waiting", "progress": 0.0, "passenger_count": units.size(), "embarked_unit_ids": units, "boarded_fireteam_ids": [team], "has_lz_position": true, "lz_position": lz, "approach_angle": "NW"}

# Seit 45e1cb443 reserviert der gewaehlte Landeplatz eines wartenden Schiffs die Flaeche: Das zweite Schiff bekommt
# seinen Platz (= den des ersten) erst beim eigenen Start, sonst blockiert es das erste.
func _card_b(team: String, units: Array, lz: Vector2, park: bool) -> Dictionary:
	var card: Dictionary = _card("craft_b", team, units, lz)
	if park:
		card["has_lz_position"] = false
		card.erase("lz_position")
	return card

func _other_site(controller: Node, map, near: Vector2) -> Vector2:
	var registry: Node = controller.call("_get_terrain_registry")
	for tile in map.get_tiles():
		var distance: float = tile.world_position.distance_to(near)
		if distance >= 256.0 and distance <= 512.0 and bool(load("res://scripts/mission/field_landing_contract.gd").validate(registry, tile.grid_position, []).ok):
			return tile.world_position
	_check(false, "Map offers a second safe landing site")
	return near

func _find_card(controller: Node, id: String) -> Dictionary:
	for card in Array(Dictionary(controller.call("get_planning_state")).get("mission_drop_cards", [])):
		if String(card.get("craft_id", "")) == id:
			return card
	return {}

func _unit_ids(units: Array) -> Array:
	var ids: Array = []
	for unit in units:
		ids.append(String(unit.call("get_unit_id")))
	return ids

func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS: " + label)
	else:
		failed += 1
		printerr("FAIL: " + label)
