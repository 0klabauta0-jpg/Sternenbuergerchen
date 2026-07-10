extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const CONTROLLER_SOURCE_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1043 Mission HUD Hotpath Event Log Guard ===")
	_test_recurring_event_log_refresh_uses_live_snapshot()
	await _test_live_snapshot_keeps_event_log_read_only_and_renderable()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_recurring_event_log_refresh_uses_live_snapshot() -> void:
	var controller_text: String = FileAccess.get_file_as_string(CONTROLLER_SOURCE_PATH)
	var refresh_body: String = _function_body(controller_text, "_refresh_tactical_event_log_panel")
	_assert(controller_text.contains("func get_live_tactical_event_log_feedback_snapshot() -> Dictionary:"), "Controller exposes a narrow live event-log feedback snapshot")
	_assert(refresh_body.contains("get_live_tactical_event_log_feedback_snapshot()"), "Recurring event-log refresh uses the narrow live snapshot")
	_assert(not refresh_body.contains("get_command_feedback_snapshot()"), "Recurring event-log refresh does not build the full command-feedback snapshot")


func _test_live_snapshot_keeps_event_log_read_only_and_renderable() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var controller: Node = scene.get_node_or_null("TacticalController")
	var panel: Control = scene.get_node_or_null("TacticalUI/TacticalEventLogPanel") as Control
	_assert(controller != null and panel != null, "Mission fixture exposes controller and tactical event-log panel")
	if controller == null or panel == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	_assert(controller.has_method("get_live_tactical_event_log_feedback_snapshot"), "Mission controller exposes the live event-log snapshot at runtime")
	if not controller.has_method("get_live_tactical_event_log_feedback_snapshot"):
		scene.queue_free()
		await _wait_frames(2)
		return
	controller.call("record_tactical_communication_events", [_build_event()], {"now_msec": 104300, "cooldown_msec": 0, "max_events": 8, "max_per_channel": 8})
	await _wait_frames(2)
	var live_snapshot: Dictionary = Dictionary(controller.call("get_live_tactical_event_log_feedback_snapshot"))
	_assert(live_snapshot.has("selected_fireteam_ids"), "Live snapshot keeps selected-fireteam filtering data")
	_assert(live_snapshot.has("tactical_event_log"), "Live snapshot keeps display event entries")
	_assert(live_snapshot.has("release_firefight_event_log_display"), "Live snapshot keeps existing firefight event-log display data")
	_assert(not live_snapshot.has("release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest"), "Live snapshot excludes unrelated integrated-playtest report payload")
	_assert(bool(live_snapshot.get("read_only", false)), "Live snapshot is read-only")
	_assert(not bool(live_snapshot.get("ui_sets_gameplay_truth", true)), "Live snapshot does not own gameplay truth")
	_assert(not bool(live_snapshot.get("creates_command", true)), "Live snapshot creates no commands")
	panel.call("set_feedback_snapshot", live_snapshot)
	await _wait_frames(2)
	var rendered_entries: Array = Array(panel.call("get_rendered_event_entries"))
	_assert(not rendered_entries.is_empty(), "Panel renders entries from the live snapshot")
	_assert(_contains_event_id(rendered_entries, "task_1043_event"), "Panel keeps the recorded tactical event in the live snapshot path")
	scene.queue_free()
	await _wait_frames(2)


func _build_event() -> Dictionary:
	return {
		"event_id": "task_1043_event",
		"event_type": "contact_report",
		"fireteam_id": "blue",
		"created_msec": 104300,
		"severity": "tactical",
		"short_text": "BLUE CONTACT REPORT",
		"detail_text": "TASK 1043 event-log hotpath fixture",
		"map_label": "CONTACT",
	}


func _contains_event_id(entries: Array, event_id: String) -> bool:
	for entry_variant in entries:
		if typeof(entry_variant) == TYPE_DICTIONARY and String(Dictionary(entry_variant).get("event_id", "")) == event_id:
			return true
	return false


func _function_body(source_text: String, function_name: String) -> String:
	var start_token: String = "func %s(" % function_name
	var start_index: int = source_text.find(start_token)
	if start_index < 0:
		return ""
	var end_index: int = source_text.find("\n\nfunc ", start_index + start_token.length())
	return source_text.substr(start_index) if end_index < 0 else source_text.substr(start_index, end_index - start_index)


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
