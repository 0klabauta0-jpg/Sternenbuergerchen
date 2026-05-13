extends SceneTree

const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_385 Homebase Direct Return Isolation Verifier ===")
	await _test_homebase_direct_return_routes_to_homebase_without_fob_state()
	await _test_boarding_seconds_derive_from_speed_and_discipline()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_385: FAILED")
		quit(1)
	else:
		print("TASK_385: ALL PASSED")
		quit(0)


func _test_homebase_direct_return_routes_to_homebase_without_fob_state() -> void:
	var scene: Node = await _build_meta_scene()
	var homebase_unit_ids := PackedStringArray(["unit_alpha", "unit_bravo"])
	await _stage_homebase_direct_payload(scene, homebase_unit_ids, "ft_home", "dropship_alpha")

	var homebase_screen: Control = scene.get_node("HomebaseScreen") as Control
	var fob_screen: Control = scene.get_node("FOBScreen") as Control
	homebase_screen.call("request_mission_start")
	await process_frame
	await process_frame

	var planning_state: Dictionary = Dictionary(scene.get("_mission_planning_state")).duplicate(true)
	_assert(String(planning_state.get("mission_drop_source", "")).strip_edges() == "homebase_direct", "Homebase send records a Direct mission source")
	_assert(_ids_equal(planning_state.get("embarked_unit_ids", []), homebase_unit_ids), "Homebase Direct payload reaches mission planning")

	scene.call("_refresh_fob_screen")
	await process_frame
	_assert(bool(fob_screen.get_meta("homebase_direct_bypass_active", false)), "FOB refresh is explicitly bypassed during Homebase Direct missions")
	_assert(not _contains_any_id(fob_screen.call("get_team"), homebase_unit_ids), "Homebase Direct payload does not appear in FOB #10")

	var return_state: Dictionary = planning_state.duplicate(true)
	return_state["mission_drop_cards"] = [
		{
			"craft_id": "dropship_alpha",
			"state": "to_fob",
			"passenger_count": 0,
			"embarked_unit_ids": [],
		}
	]
	return_state["mission_drop_return_requested"] = true
	return_state["mission_drop_craft_id"] = "dropship_alpha"
	return_state["mission_drop_source"] = "homebase_direct"
	return_state["mission_drop_passenger_count"] = 0
	return_state["embarked_unit_ids"] = []
	scene.call("_on_mission_planning_state_changed", return_state)
	await process_frame

	var pending_transfers: Array = Array(scene.get("_pending_mission_craft_transfers"))
	var aircraft_locations: Dictionary = Dictionary(scene.get("_aircraft_location_by_craft"))
	var craft_states: Array = Array(scene.call("_build_transport_craft_states"))
	var returning_state: Dictionary = _find_craft_state(craft_states, "dropship_alpha")
	_assert(pending_transfers.size() == 1 and String(Dictionary(pending_transfers[0]).get("phase", "")).strip_edges() == "to_homebase", "Direct return request creates a to_homebase transfer instead of to_fob")
	_assert(String(aircraft_locations.get("dropship_alpha", "")).strip_edges() == "mission", "Dropship stays mission-side while returning to Homebase")
	_assert(not bool(returning_state.get("visible_in_fob", true)) and bool(returning_state.get("mission_transit_to_homebase", false)), "Returning Direct dropship is not visible in FOB transport cards")
	_assert(not _contains_any_id(fob_screen.call("get_team"), homebase_unit_ids), "Return handling still does not inject mission fireteams into FOB #10")

	for _index in range(18):
		scene.call("_on_homebase_transport_timer_timeout")
	await process_frame
	aircraft_locations = Dictionary(scene.get("_aircraft_location_by_craft"))
	craft_states = Array(scene.call("_build_transport_craft_states"))
	var homebase_state: Dictionary = _find_craft_state(craft_states, "dropship_alpha")
	_assert(String(aircraft_locations.get("dropship_alpha", "")).strip_edges() == "homebase", "Completed Direct return parks the dropship back at Homebase")
	_assert(bool(homebase_state.get("visible_in_homebase", false)) and not bool(homebase_state.get("visible_in_fob", true)), "Returned Direct dropship is Homebase-visible and FOB-hidden")

	scene.queue_free()
	await process_frame


func _test_boarding_seconds_derive_from_speed_and_discipline() -> void:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	screen.call(
		"setup_roster",
		[
			_build_unit("unit_average", "Average", 0.5, 0.5),
			_build_unit("unit_fast", "Fast", 0.9, 0.9),
			_build_unit("unit_slow", "Slow", 0.1, 0.1),
		],
		PackedStringArray(["unit_average", "unit_fast", "unit_slow"])
	)
	await process_frame

	var average_seconds: float = float(screen.call("_debug_get_homebase_member_boarding_seconds", "unit_average"))
	var fast_seconds: float = float(screen.call("_debug_get_homebase_member_boarding_seconds", "unit_fast"))
	var slow_seconds: float = float(screen.call("_debug_get_homebase_member_boarding_seconds", "unit_slow"))
	_assert(is_equal_approx(average_seconds, 4.0), "Average Speed/Discipline boards in about four seconds")
	_assert(fast_seconds < average_seconds, "High Speed/Discipline boards faster than average")
	_assert(slow_seconds > average_seconds, "Low Speed/Discipline boards slower than average")

	screen.queue_free()
	await process_frame


func _build_meta_scene() -> Node:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame
	return scene


func _stage_homebase_direct_payload(scene: Node, unit_ids: PackedStringArray, fireteam_id: String, craft_id: String) -> void:
	var homebase_screen: Control = scene.get_node("HomebaseScreen") as Control
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	var craft_definitions: Array = [
		{
			"craft_id": craft_id,
			"craft_type": "dropship",
			"display_name": "Homebase Dropship",
			"texture_path": DROPSHIP_TEXTURE_PATH,
			"supports_cargo": false,
			"cargo_options": [],
		}
	]
	var pilot_by_craft: Dictionary = _build_single_value_dictionary(craft_id, "unit_charlie")
	var location_by_craft: Dictionary = _build_single_value_dictionary(craft_id, "homebase")
	scene.set("_homebase_aircraft_definitions", craft_definitions.duplicate(true))
	scene.set("_assigned_aircraft_pilot_by_craft", pilot_by_craft.duplicate(true))
	scene.set("_aircraft_location_by_craft", location_by_craft.duplicate(true))
	homebase_screen.call("setup_roster", roster, unit_ids)
	homebase_screen.call(
		"set_fireteam_context",
		_repeat_fireteam_ids(unit_ids.size(), fireteam_id),
		[_build_fireteam_definition(fireteam_id, unit_ids)]
	)
	homebase_screen.call(
		"set_transport_state",
		craft_definitions,
		pilot_by_craft,
		[],
		[],
		location_by_craft,
		{},
		{},
		[]
	)
	homebase_screen.call("_on_homebase_shipcard_fireteam_dropped", fireteam_id, craft_id)
	var total_seconds: float = float(homebase_screen.call("_debug_get_homebase_fireteam_boarding_total_seconds", fireteam_id))
	homebase_screen.call("_debug_advance_homebase_direct_boarding", total_seconds + 0.1)
	await process_frame
	await process_frame


func _build_fireteam_definition(fireteam_id: String, unit_ids: PackedStringArray) -> Dictionary:
	return {
		"id": fireteam_id,
		"label": fireteam_id.to_upper(),
		"lead_unit_id": String(unit_ids[0]) if not unit_ids.is_empty() else "",
		"loadout": "medium",
		"respawn_enabled": false,
	}


func _build_unit(unit_id: String, display_name: String, speed: float, discipline: float) -> Dictionary:
	return {
		"unit_id": unit_id,
		"display_name": display_name,
		"role_id": "rifleman",
		"skill_accuracy": 0.5,
		"skill_speed": speed,
		"skill_leadership": 0.5,
		"skill_toughness": 0.5,
		"discipline": discipline,
		"trait_ids": [],
	}


func _repeat_fireteam_ids(count: int, fireteam_id: String) -> PackedStringArray:
	var result: PackedStringArray = []
	for _index in range(count):
		result.append(fireteam_id)
	return result


func _build_single_value_dictionary(key: String, value: String) -> Dictionary:
	var result: Dictionary = {}
	result[key] = value
	return result


func _find_craft_state(craft_states: Array, craft_id: String) -> Dictionary:
	for state_variant in craft_states:
		if typeof(state_variant) != TYPE_DICTIONARY:
			continue
		var state: Dictionary = Dictionary(state_variant)
		if String(state.get("craft_id", "")).strip_edges() == craft_id:
			return state
	return {}


func _ids_equal(value: Variant, expected: PackedStringArray) -> bool:
	var actual := PackedStringArray(Array(value))
	if actual.size() != expected.size():
		return false
	for index in range(actual.size()):
		if String(actual[index]) != String(expected[index]):
			return false
	return true


func _contains_any_id(value: Variant, ids: PackedStringArray) -> bool:
	var actual := PackedStringArray(Array(value))
	for id_variant in ids:
		if actual.has(String(id_variant)):
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		print("  FAIL: %s" % message)
