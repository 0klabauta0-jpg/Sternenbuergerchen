extends SceneTree

const START_ROSTER_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/start_roster_generator.gd")
const PERSONNEL_EVENT_MODEL_SCRIPT: GDScript = preload("res://scripts/meta/personnel_event_model.gd")
const PERSONNEL_EVENT_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/personnel_event_resolver.gd")
const PLAYER_ROSTER_STORE_SCRIPT: GDScript = preload("res://scripts/meta/player_roster_store.gd")
const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const DEBRIEF_TEST_SCENE: PackedScene = preload("res://scenes/meta/debrief_test_screen.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_238 Personnel Events Recruit Leave Dismiss Notifications ===")
	_test_personnel_event_model_stable_ids()
	_test_roster_event_triggers()
	_test_dismiss_requires_confirmation()
	_test_join_and_save_roundtrip()
	await _test_homebase_and_debrief_notifications()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_personnel_event_model_stable_ids() -> void:
	var first_event: Dictionary = Dictionary(PERSONNEL_EVENT_MODEL_SCRIPT.call("make_event",
		PERSONNEL_EVENT_MODEL_SCRIPT.EVENT_REQUESTS_CHANGE,
		"unit_01",
		"Mara",
		"Mara bittet um Versetzung aus Fireteam Blau.",
		{"trigger": "high_frustration", "frustration": 0.82},
		false
	))
	var second_event: Dictionary = Dictionary(PERSONNEL_EVENT_MODEL_SCRIPT.call("make_event",
		PERSONNEL_EVENT_MODEL_SCRIPT.EVENT_REQUESTS_CHANGE,
		"unit_01",
		"Mara",
		"Mara bittet um Versetzung aus Fireteam Blau.",
		{"trigger": "high_frustration", "frustration": 0.82},
		false
	))
	var validation: Dictionary = Dictionary(PERSONNEL_EVENT_MODEL_SCRIPT.call("validate_event", first_event))
	_assert(bool(validation.get("valid", false)), "Personnel event validates")
	_assert(String(first_event.get("event_id", "")) == String(second_event.get("event_id", "")), "Personnel event IDs are stable for same payload")
	_assert(Dictionary(first_event.get("payload", {})).has("trigger"), "Personnel event carries structured payload")


func _test_roster_event_triggers() -> void:
	var roster: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", "task238_triggers", 24))
	var units: Array = Array(roster.get("units", [])).duplicate(true)
	var first: Dictionary = Dictionary(units[0]).duplicate(true)
	var second: Dictionary = Dictionary(units[1]).duplicate(true)
	var third: Dictionary = Dictionary(units[2]).duplicate(true)
	first["progression"] = {"xp": 24, "missions_completed": 3, "morale": 0.55, "frustration": 0.10}
	second["progression"] = {"xp": 12, "missions_completed": 2, "morale": 0.16, "frustration": 0.82}
	third["availability_status"] = "recovering"
	third["recovery_state"] = {"reason": "downed", "remaining_missions": 1}
	units[0] = first
	units[1] = second
	units[2] = third
	roster["units"] = units
	var result: Dictionary = Dictionary(PERSONNEL_EVENT_RESOLVER_SCRIPT.call("evaluate_roster", roster))
	var events: Array = Array(result.get("events", []))
	_assert(_events_contain(events, PERSONNEL_EVENT_MODEL_SCRIPT.EVENT_RECRUIT_AVAILABLE), "Three completed missions can create recruit availability")
	_assert(_events_contain(events, PERSONNEL_EVENT_MODEL_SCRIPT.EVENT_REQUESTS_CHANGE), "High frustration creates personnel request")
	_assert(_events_contain(events, PERSONNEL_EVENT_MODEL_SCRIPT.EVENT_UNAVAILABLE), "Recovery status creates unavailable notification")
	_assert(Array(Dictionary(result.get("updated_roster", {})).get("personnel_events", [])).size() >= 3, "Roster stores personnel events")


func _test_dismiss_requires_confirmation() -> void:
	var roster: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", "task238_dismiss", 24))
	var units: Array = Array(roster.get("units", []))
	var dismissed_id: String = String(Dictionary(units[0]).get("unit_id", "")).strip_edges()
	var request_result: Dictionary = Dictionary(PERSONNEL_EVENT_RESOLVER_SCRIPT.call("request_dismiss", roster, dismissed_id))
	var request_event: Dictionary = Dictionary(request_result.get("event", {}))
	_assert(bool(request_result.get("ok", false)), "Dismiss request resolves")
	_assert(bool(request_event.get("requires_confirmation", false)), "Dismiss request requires confirmation")
	_assert(Array(Dictionary(request_result.get("updated_roster", {})).get("units", [])).size() == units.size(), "Dismiss request does not remove unit")
	var confirm_result: Dictionary = Dictionary(PERSONNEL_EVENT_RESOLVER_SCRIPT.call("confirm_dismiss", roster, request_event))
	var updated_roster: Dictionary = Dictionary(confirm_result.get("updated_roster", {}))
	_assert(bool(confirm_result.get("ok", false)), "Dismiss confirmation resolves")
	_assert(Array(updated_roster.get("units", [])).size() == units.size() - 1, "Dismiss confirmation removes one unit")
	_assert(_find_unit(Array(updated_roster.get("units", [])), dismissed_id).is_empty(), "Dismissed unit is absent after confirmation")
	_assert(not _fireteams_reference_unit(Array(updated_roster.get("fireteam_suggestions", [])), dismissed_id), "Fireteam suggestions drop dismissed unit")


func _test_join_and_save_roundtrip() -> void:
	var profile_id: String = "task238_personnel_roundtrip"
	var save_path: String = "user://profiles/%s/roster_v1.json" % profile_id
	PLAYER_ROSTER_STORE_SCRIPT.call("delete_roster_for_tests", profile_id, save_path)
	var roster: Dictionary = _generate_valid_roster("task238_join", 24, profile_id)
	var candidate: Dictionary = Dictionary(PERSONNEL_EVENT_RESOLVER_SCRIPT.call("build_recruit_candidate", roster, "task238_join"))
	var join_result: Dictionary = Dictionary(PERSONNEL_EVENT_RESOLVER_SCRIPT.call("apply_join", roster, candidate))
	_assert(bool(join_result.get("ok", false)), "Recruit candidate can join roster")
	var updated_roster: Dictionary = Dictionary(join_result.get("updated_roster", {}))
	var candidate_id: String = String(candidate.get("unit_id", "")).strip_edges()
	_assert(not _find_unit(Array(updated_roster.get("units", [])), candidate_id).is_empty(), "Joined candidate appears in roster")
	var save_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("save_roster", updated_roster, profile_id, save_path))
	_assert(bool(save_result.get("ok", false)), "Player roster store saves roster after join")
	var load_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("load_roster", profile_id, save_path))
	_assert(bool(load_result.get("ok", false)), "Player roster store loads roster after personnel event")
	var loaded_roster: Dictionary = Dictionary(load_result.get("roster", {}))
	_assert(not _find_unit(Array(loaded_roster.get("units", [])), candidate_id).is_empty(), "Joined candidate roundtrips through save")
	_assert(_events_contain(Array(loaded_roster.get("personnel_events", [])), PERSONNEL_EVENT_MODEL_SCRIPT.EVENT_JOINS_ROSTER), "Personnel event roundtrips through save")
	PLAYER_ROSTER_STORE_SCRIPT.call("delete_roster_for_tests", profile_id, save_path)


func _test_homebase_and_debrief_notifications() -> void:
	var event: Dictionary = Dictionary(PERSONNEL_EVENT_MODEL_SCRIPT.call("make_event",
		PERSONNEL_EVENT_MODEL_SCRIPT.EVENT_RECRUIT_AVAILABLE,
		"",
		"Anja",
		"Anja ist fuer das Roster verfuegbar.",
		{"trigger": "missions_completed_3", "candidate_display_name": "Anja"},
		false
	))
	var homebase: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(homebase)
	await process_frame
	homebase.call("set_personnel_events", [event])
	await process_frame
	var snapshot: Dictionary = Dictionary(homebase.call("get_personnel_notification_snapshot"))
	_assert(int(snapshot.get("event_count", 0)) == 1, "Homebase stores personnel notification snapshot")
	_assert(_string_array_contains(PackedStringArray(snapshot.get("messages", PackedStringArray())), "Anja ist fuer das Roster verfuegbar"), "Homebase exposes personnel notification text")
	homebase.queue_free()
	await process_frame

	var debrief: Control = DEBRIEF_TEST_SCENE.instantiate()
	root.add_child(debrief)
	await process_frame
	debrief.call("set_mission_result", {
		"mission_outcome": "success",
		"result": "success",
		"winning_team_id": "team_alpha",
		"objective_captured": true,
		"duration_seconds": 12.0,
		"team_states": [],
		"character_events": [],
		"personnel_events": [event],
	})
	await process_frame
	var labels: PackedStringArray = _collect_label_texts(debrief)
	_assert(_labels_contain(labels, "Personnel updates:"), "Debrief renders personnel update section")
	_assert(_labels_contain(labels, "Anja ist fuer das Roster verfuegbar"), "Debrief renders personnel notification text")
	debrief.queue_free()
	await process_frame


func _events_contain(events: Array, event_type: String) -> bool:
	for event_variant in events:
		if typeof(event_variant) == TYPE_DICTIONARY and String(Dictionary(event_variant).get("event_type", "")) == event_type:
			return true
	return false


func _generate_valid_roster(seed: String, roster_size: int, profile_id: String) -> Dictionary:
	for suffix in range(12):
		var candidate_seed: String = seed if suffix == 0 else "%s_%02d" % [seed, suffix]
		var roster: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", candidate_seed, roster_size, profile_id))
		var validation: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("validate_roster", roster))
		if bool(validation.get("valid", false)):
			return roster
	return Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", seed, roster_size, profile_id))


func _find_unit(units: Array, unit_id: String) -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges().to_lower()
	for unit_variant in units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(unit_variant)
		if String(unit.get("unit_id", "")).strip_edges().to_lower() == normalized_unit_id:
			return unit
	return {}


func _fireteams_reference_unit(fireteams: Array, unit_id: String) -> bool:
	var normalized_unit_id: String = unit_id.strip_edges().to_lower()
	for fireteam_variant in fireteams:
		if typeof(fireteam_variant) != TYPE_DICTIONARY:
			continue
		for member_id in PackedStringArray(Dictionary(fireteam_variant).get("unit_ids", PackedStringArray())):
			if String(member_id).strip_edges().to_lower() == normalized_unit_id:
				return true
	return false


func _collect_label_texts(root_node: Node) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for node in _collect_nodes(root_node):
		var label := node as Label
		if label != null:
			result.append(label.text)
	return result


func _collect_nodes(root_node: Node) -> Array:
	var nodes: Array = []
	if root_node == null:
		return nodes
	nodes.append(root_node)
	for child in root_node.get_children():
		nodes.append_array(_collect_nodes(child))
	return nodes


func _labels_contain(labels: PackedStringArray, fragment: String) -> bool:
	for text in labels:
		if String(text).contains(fragment):
			return true
	return false


func _string_array_contains(values: PackedStringArray, fragment: String) -> bool:
	for value in values:
		if String(value).contains(fragment):
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
