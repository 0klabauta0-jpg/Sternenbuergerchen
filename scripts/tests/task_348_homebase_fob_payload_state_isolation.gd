extends SceneTree

const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_348 Homebase FOB Payload State Isolation ===")
	await _test_default_sync_uses_fob_payload_when_homebase_direct_exists()
	await _test_fob_start_uses_fob_payload_when_homebase_direct_exists()
	await _test_homebase_start_uses_homebase_direct_payload()
	await _test_homebase_start_falls_back_to_fob_payload_without_direct_staging()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_348: FAILED")
		quit(1)
	else:
		print("TASK_348: ALL PASSED")
		quit(0)


func _test_default_sync_uses_fob_payload_when_homebase_direct_exists() -> void:
	var scene: Node = await _build_meta_scene()
	var homebase_unit_ids := PackedStringArray(["unit_alpha", "unit_bravo"])
	var fob_unit_ids := PackedStringArray(["unit_echo", "unit_foxtrot"])
	await _stage_homebase_direct_payload(scene, homebase_unit_ids, "ft_home")
	await _stage_fob_waiting_payload(scene, fob_unit_ids, "ft_fob", "dropship_fob")

	scene.call("_sync_fob_dropship_state_into_mission_planning", true)
	var planning_state: Dictionary = Dictionary(scene.get("_mission_planning_state"))

	_assert(String(planning_state.get("mission_drop_source", "")).strip_edges() == "fob", "Default payload sync uses FOB source")
	_assert(_ids_equal(planning_state.get("embarked_unit_ids", []), fob_unit_ids), "Default sync keeps FOB embarked units")
	_assert(not _contains_any_id(planning_state.get("embarked_unit_ids", []), homebase_unit_ids), "Default sync does not leak Homebase Direct units")
	_assert(String(planning_state.get("mission_drop_craft_id", "")).strip_edges() == "dropship_fob", "Default sync keeps the FOB craft card")

	scene.queue_free()
	await process_frame


func _test_fob_start_uses_fob_payload_when_homebase_direct_exists() -> void:
	var scene: Node = await _build_meta_scene()
	var homebase_unit_ids := PackedStringArray(["unit_alpha", "unit_bravo"])
	var fob_unit_ids := PackedStringArray(["unit_echo", "unit_foxtrot"])
	var fob_fireteam_ids := _repeat_fireteam_ids(fob_unit_ids.size(), "ft_fob")
	await _stage_homebase_direct_payload(scene, homebase_unit_ids, "ft_home")
	await _stage_fob_waiting_payload(scene, fob_unit_ids, "ft_fob", "dropship_fob")

	scene.call("_on_fob_mission_start_requested", fob_unit_ids, fob_fireteam_ids)
	await process_frame
	var planning_state: Dictionary = Dictionary(scene.get("_mission_planning_state"))

	_assert(String(planning_state.get("mission_drop_source", "")).strip_edges() == "fob", "FOB start records FOB as payload source")
	_assert(_ids_equal(planning_state.get("embarked_unit_ids", []), fob_unit_ids), "FOB start keeps FOB embarked units")
	_assert(not _contains_any_id(planning_state.get("embarked_unit_ids", []), homebase_unit_ids), "FOB start ignores stale Homebase Direct payload")
	_assert(String(planning_state.get("mission_drop_craft_id", "")).strip_edges() == "dropship_fob", "FOB start keeps the FOB dropship")

	scene.queue_free()
	await process_frame


func _test_homebase_start_uses_homebase_direct_payload() -> void:
	var scene: Node = await _build_meta_scene()
	var homebase_unit_ids := PackedStringArray(["unit_alpha", "unit_bravo"])
	await _stage_homebase_direct_payload(scene, homebase_unit_ids, "ft_home")

	var homebase_screen: Control = scene.get_node("HomebaseScreen") as Control
	homebase_screen.call("request_mission_start")
	await process_frame
	var planning_state: Dictionary = Dictionary(scene.get("_mission_planning_state"))

	_assert(String(planning_state.get("mission_drop_source", "")).strip_edges() == "homebase_direct", "Homebase start records Homebase Direct as payload source")
	_assert(_ids_equal(planning_state.get("embarked_unit_ids", []), homebase_unit_ids), "Homebase start keeps Homebase Direct embarked units")
	_assert(String(planning_state.get("mission_drop_status_line", "")).strip_edges() == "Homebase direct staging", "Homebase start keeps the direct staging status line")

	scene.queue_free()
	await process_frame


func _test_homebase_start_falls_back_to_fob_payload_without_direct_staging() -> void:
	var scene: Node = await _build_meta_scene()
	var fob_unit_ids := PackedStringArray(["unit_echo", "unit_foxtrot"])
	await _stage_fob_waiting_payload(scene, fob_unit_ids, "ft_fob", "dropship_fob")
	scene.call("_refresh_homebase_screen")
	await process_frame

	var homebase_screen: Control = scene.get_node("HomebaseScreen") as Control
	homebase_screen.call("request_mission_start")
	await process_frame
	var planning_state: Dictionary = Dictionary(scene.get("_mission_planning_state"))

	_assert(String(planning_state.get("mission_drop_source", "")).strip_edges() == "fob", "Homebase launch-ready fallback records FOB as payload source")
	_assert(_ids_equal(planning_state.get("embarked_unit_ids", []), fob_unit_ids), "Homebase fallback keeps FOB embarked units")
	_assert(_ids_equal(scene.get("_selected_unit_ids"), fob_unit_ids), "Homebase fallback starts the mission with FOB-selected units")

	scene.queue_free()
	await process_frame


func _build_meta_scene() -> Node:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame
	return scene


func _stage_homebase_direct_payload(scene: Node, unit_ids: PackedStringArray, fireteam_id: String) -> void:
	var homebase_screen: Control = scene.get_node("HomebaseScreen") as Control
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	homebase_screen.call("setup_roster", roster, unit_ids)
	homebase_screen.call(
		"set_fireteam_context",
		_repeat_fireteam_ids(unit_ids.size(), fireteam_id),
		[_build_fireteam_definition(fireteam_id, unit_ids)]
	)
	homebase_screen.call("_on_homebase_staging_fireteam_dropped", fireteam_id, "homebase_dropship")
	await process_frame
	await process_frame


func _stage_fob_waiting_payload(scene: Node, unit_ids: PackedStringArray, fireteam_id: String, craft_id: String) -> void:
	var fob_screen: Control = scene.get_node("FOBScreen") as Control
	var fireteam_ids := _repeat_fireteam_ids(unit_ids.size(), fireteam_id)
	fob_screen.call("configure_transfer", unit_ids, fireteam_ids, [_build_fireteam_definition(fireteam_id, unit_ids)])
	fob_screen.set("_dropship_transport_craft_id", craft_id)
	fob_screen.call("set_transport_craft_state", [_build_transport_craft_state(craft_id)])
	fob_screen.set("_dropship_phase", "ready")
	fob_screen.set("_dropship_staged_fireteam_ids", PackedStringArray([fireteam_id]))
	fob_screen.set("_boarded_unit_ids", unit_ids)
	fob_screen.set("_boarded_fireteam_ids", PackedStringArray([fireteam_id]))
	fob_screen.call("mark_transport_craft_launch_ready", craft_id)
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


func _build_transport_craft_state(craft_id: String) -> Dictionary:
	return {
		"craft_id": craft_id,
		"craft_type": "dropship",
		"display_name": "FOB Dropship",
		"texture_path": "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png",
		"location": "mission",
		"visible_in_homebase": false,
		"visible_in_fob": true,
		"is_in_transit": false,
		"is_boardable": false,
		"mission_phase": "waiting",
		"mission_waiting": true,
		"mission_transit_to_map": false,
		"mission_transit_to_fob": false,
		"passenger_count": 2,
		"transfer_progress": 100.0,
		"transfer_eta_seconds": 0,
	}


func _repeat_fireteam_ids(count: int, fireteam_id: String) -> PackedStringArray:
	var result: PackedStringArray = []
	for _index in range(count):
		result.append(fireteam_id)
	return result


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
