extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1066 Mission Feedback Surface Delta Extraction ===")
	await _test_event_log_feedback_snapshot_delta_guard()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_event_log_feedback_snapshot_delta_guard() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var controller: Node = scene.get_node_or_null("TacticalController")
	var panel: Control = scene.get_node_or_null("TacticalUI/TacticalEventLogPanel") as Control
	_assert(controller != null and panel != null, "Mission fixture exposes controller and tactical event-log panel")
	if controller == null or panel == null:
		await _cleanup(scene)
		return
	controller.call("record_tactical_communication_events", [_event("task_1066_first", 106600)], {"now_msec": 106600, "cooldown_msec": 0, "max_events": 8, "max_per_channel": 8})
	await _wait_frames(2)
	var first_snapshot: Dictionary = Dictionary(controller.call("get_live_tactical_event_log_feedback_snapshot"))
	panel.call("set_feedback_snapshot", first_snapshot)
	var after_first: Dictionary = Dictionary(panel.call("get_panel_snapshot"))
	panel.call("set_feedback_snapshot", first_snapshot)
	var after_same: Dictionary = Dictionary(panel.call("get_panel_snapshot"))
	_assert(int(after_same.get("feedback_snapshot_skip_count", -1)) > int(after_first.get("feedback_snapshot_skip_count", -1)), "Identical feedback snapshot skips panel data copying")
	_assert(int(after_same.get("feedback_snapshot_apply_count", -1)) == int(after_first.get("feedback_snapshot_apply_count", -2)), "Identical feedback snapshot does not reapply panel data")
	_assert(_contains_event(Array(panel.call("get_rendered_event_entries")), "task_1066_first"), "Skipped snapshot keeps the rendered event")

	controller.call("record_tactical_communication_events", [_event("task_1066_second", 106700)], {"now_msec": 106700, "cooldown_msec": 0, "max_events": 8, "max_per_channel": 8})
	await _wait_frames(2)
	panel.call("set_feedback_snapshot", Dictionary(controller.call("get_live_tactical_event_log_feedback_snapshot")))
	var after_event: Dictionary = Dictionary(panel.call("get_panel_snapshot"))
	_assert(int(after_event.get("feedback_snapshot_apply_count", -1)) > int(after_same.get("feedback_snapshot_apply_count", 0)), "New event reapplies the panel feedback snapshot")
	_assert(_contains_event(Array(panel.call("get_rendered_event_entries")), "task_1066_second"), "New event is rendered after the feedback delta")
	_assert(bool(after_event.get("feedback_snapshot_delta_read_only", false)), "Feedback delta diagnostics stay read-only")
	_assert(not bool(after_event.get("feedback_snapshot_sets_gameplay_truth", true)), "Feedback delta diagnostics do not own gameplay truth")
	await _cleanup(scene)


func _event(event_id: String, created_msec: int) -> Dictionary:
	return {"event_id": event_id, "event_type": "contact_report", "fireteam_id": "blue", "created_msec": created_msec, "severity": "tactical", "short_text": "BLUE CONTACT REPORT", "detail_text": "TASK 1066 event-log feedback delta", "map_label": "CONTACT"}


func _contains_event(entries: Array, event_id: String) -> bool:
	for entry_variant in entries:
		if typeof(entry_variant) == TYPE_DICTIONARY and String(Dictionary(entry_variant).get("event_id", "")) == event_id:
			return true
	return false


func _cleanup(scene: Node) -> void:
	if is_instance_valid(scene):
		scene.queue_free()
	await _wait_frames(2)


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
