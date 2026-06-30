extends SceneTree

const EVENT_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_communication_event.gd")
const RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_communication_resolver.gd")
const PANEL_SCRIPT: GDScript = preload("res://scripts/ui/tactical_event_log_panel.gd")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_715_station_route_empty_eventlog_polish.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_refresh_2026_06_30.html"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_715 Station Route Empty Event Log Polish ===")
	_test_docs()
	await _test_empty_panel_collapses_and_expands()
	await _test_mission_initial_empty_event_log_is_collapsed()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_715: FAILED")
		quit(1)
		return
	print("TASK_715: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_715 task file exists")
	_assert(task_text.contains("Station Route Empty Event Log Polish"), "Task documents empty event log polish")
	_assert(contract_text.contains("Station Route Empty Event Log Polish"), "Interaction contract documents TASK_715")
	_assert(status_text.contains("TASK_715 - Station Route Empty Event Log Polish"), "Implementation status tracks TASK_715")
	_assert(roadmap_text.contains("TASK_715 - Station Route Empty Event Log Polish (implementiert)"), "Roadmap marks TASK_715 implemented")
	_assert(report_text.contains("TASK_715 - Station Route Empty Event Log Polish"), "Current report references TASK_715")
	_assert(report_text.contains('data-export-key="station_route_empty_eventlog_polish.empty_collapsed"'), "Current report exports TASK_715 empty-collapse flag")


func _test_empty_panel_collapses_and_expands() -> void:
	root.size = Vector2i(1280, 720)
	var panel: Control = PANEL_SCRIPT.new()
	panel.name = "Task715EventLogPanel"
	root.add_child(panel)
	await _wait_frames(3)
	var empty_snapshot: Dictionary = Dictionary(panel.call("get_panel_snapshot"))
	_assert(bool(empty_snapshot.get("empty_state_collapsed", false)), "Standalone empty event log collapses")
	_assert(not bool(empty_snapshot.get("visible", true)), "Standalone empty event log is not visible")
	_assert(int(empty_snapshot.get("mouse_filter", -1)) == Control.MOUSE_FILTER_IGNORE, "Standalone empty event log ignores mouse input")
	_assert(String(empty_snapshot.get("visibility_mode", "")) == "collapsed_empty", "Standalone empty event log reports collapsed mode")

	panel.call("set_event_entries", [_build_event("blue", 1000)], PackedStringArray(["blue"]), false)
	await _wait_frames(4)
	var filled_snapshot: Dictionary = Dictionary(panel.call("get_panel_snapshot"))
	var rendered_entries: Array = Array(panel.call("get_rendered_event_entries"))
	_assert(not bool(filled_snapshot.get("empty_state_collapsed", true)), "Panel expands when an event arrives")
	_assert(bool(filled_snapshot.get("visible", false)), "Panel becomes visible when events exist")
	_assert(int(filled_snapshot.get("mouse_filter", -1)) == Control.MOUSE_FILTER_STOP, "Filled event log captures intended input")
	_assert(int(filled_snapshot.get("rendered_entry_count", 0)) == 1, "Filled event log renders event row")
	_assert(not rendered_entries.is_empty(), "Filled event log exposes rendered entries")

	panel.call("set_event_entries", [], PackedStringArray(["blue"]), false)
	await _wait_frames(4)
	var emptied_again_snapshot: Dictionary = Dictionary(panel.call("get_panel_snapshot"))
	_assert(bool(emptied_again_snapshot.get("empty_state_collapsed", false)), "Panel collapses again after events clear")
	_assert(not bool(emptied_again_snapshot.get("visible", true)), "Panel hides again after events clear")
	panel.queue_free()
	await _wait_frames(2)


func _test_mission_initial_empty_event_log_is_collapsed() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(14)
	var panel := scene.get_node_or_null("TacticalUI/TacticalEventLogPanel") as Control
	_assert(panel != null, "Mission scene exposes event log panel")
	if panel == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	var snapshot: Dictionary = Dictionary(panel.call("get_panel_snapshot"))
	_assert(int(snapshot.get("event_count", -1)) == 0, "Mission initial event log has no events")
	_assert(bool(snapshot.get("empty_state_collapsed", false)), "Mission initial empty event log is collapsed")
	_assert(not bool(snapshot.get("visible", true)), "Mission initial empty event log is not visible")
	_assert(int(snapshot.get("mouse_filter", -1)) == Control.MOUSE_FILTER_IGNORE, "Mission initial empty event log is input-passive")
	_assert(snapshot.has("global_rect"), "Collapsed panel still exports layout rect for diagnostics")
	scene.queue_free()
	await _wait_frames(2)


func _build_event(fireteam_id: String, now_msec: int) -> Dictionary:
	return Dictionary(RESOLVER_SCRIPT.call("build_event", EVENT_SCRIPT.EVENT_CONTACT_REPORT, {
		"event_id": "task715_contact_%s_%d" % [fireteam_id, now_msec],
		"fireteam_id": fireteam_id,
		"display_label": fireteam_id.to_upper(),
		"phase": 1,
		"planned_position": Vector2(300.0, 420.0),
		"target_position": Vector2(480.0, 480.0),
		"short_text": "%s CONTACT" % fireteam_id.to_upper(),
		"detail_text": "Task 715 contact detail",
		"communication_clarity": 0.82,
	}, {"now_msec": now_msec}))


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
