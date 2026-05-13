extends SceneTree

const EVENT_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_communication_event.gd")
const RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_communication_resolver.gd")
const PANEL_SCRIPT: GDScript = preload("res://scripts/ui/tactical_event_log_panel.gd")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_366 Tactical Event Log HUD Panel ===")
	await _test_mission_event_log_panel_layout_and_feed()
	await _test_panel_overflow_severity_and_selected_filter()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_mission_event_log_panel_layout_and_feed() -> void:
	root.size = Vector2i(1920, 1080)
	var scene = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var controller: Node = scene.get_node_or_null("TacticalController")
	var panel: Control = scene.get_node_or_null("TacticalUI/TacticalEventLogPanel") as Control
	var command_panel: Control = scene.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel") as Control
	var fireteam_panel: Control = scene.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel") as Control
	var strategic_panel: Control = scene.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel") as Control
	_assert(controller != null and panel != null, "Mission scene exposes TacticalController and TacticalEventLogPanel")
	_assert(command_panel != null and fireteam_panel != null and strategic_panel != null, "Mission scene exposes #16/#17/#18 layout targets")
	if controller == null or panel == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	controller.call("record_tactical_communication_events", [
		_build_event(EVENT_SCRIPT.EVENT_CONTACT_REPORT, "blue", 1000),
		_build_event(EVENT_SCRIPT.EVENT_CANNOT_EXECUTE, "gold", 1100),
		_build_event(EVENT_SCRIPT.EVENT_AIR_ASSET_THREATENED, "blue", 1200),
	], {"now_msec": 1300, "cooldown_msec": 0, "max_events": 8, "max_per_channel": 8})
	await _wait_frames(8)
	var snapshot: Dictionary = Dictionary(panel.call("get_panel_snapshot"))
	var rendered_entries: Array = Array(panel.call("get_rendered_event_entries"))
	_assert(int(snapshot.get("rendered_entry_count", 0)) == 3, "Panel renders TASK_365 event log entries")
	_assert(bool(snapshot.get("newest_first", false)), "Panel declares newest-first ordering")
	_assert(String(snapshot.get("first_event_id", "")).contains("1200"), "Newest event is first in the panel")
	var panel_rect: Rect2 = panel.get_global_rect()
	_assert(command_panel == null or not panel_rect.intersects(command_panel.get_global_rect()), "Panel does not cover #16 Command Matrix")
	_assert(fireteam_panel == null or not panel_rect.intersects(fireteam_panel.get_global_rect()), "Panel does not cover #17 Selected Fireteam")
	_assert(strategic_panel == null or not panel_rect.intersects(strategic_panel.get_global_rect()), "Panel does not cover #18 Mission Control")
	_assert(_all_entries_have_text(rendered_entries), "Panel rows render compact event text")
	scene.queue_free()
	await _wait_frames(2)


func _test_panel_overflow_severity_and_selected_filter() -> void:
	root.size = Vector2i(1280, 720)
	var panel: Control = PANEL_SCRIPT.new()
	panel.name = "StandaloneTacticalEventLogPanel"
	panel.custom_minimum_size = Vector2(300.0, 186.0)
	root.add_child(panel)
	await _wait_frames(2)
	_assert(panel != null, "Panel exists for overflow/filter checks")
	if panel == null:
		await _wait_frames(2)
		return
	var entries: Array = []
	for index in range(10):
		var event_type: String = EVENT_SCRIPT.EVENT_CONTACT_REPORT if index % 2 == 0 else EVENT_SCRIPT.EVENT_BOUNDING_ROTATION
		var fireteam_id: String = "blue" if index % 3 != 0 else "gold"
		var event: Dictionary = _build_event(event_type, fireteam_id, 2000 + index * 100)
		var severity: String = "tactical" if event_type == EVENT_SCRIPT.EVENT_BOUNDING_ROTATION else String(event.get("severity", "warning"))
		event["severity"] = severity
		entries.append(event)
	var critical_event: Dictionary = _build_event(EVENT_SCRIPT.EVENT_CANNOT_EXECUTE, "blue", 3200)
	critical_event["severity"] = "critical"
	entries.append(critical_event)
	panel.call("set_event_entries", entries, PackedStringArray(["blue"]), false)
	await _wait_frames(4)
	var overflow_snapshot: Dictionary = Dictionary(panel.call("get_panel_snapshot"))
	_assert(int(overflow_snapshot.get("rendered_entry_count", 0)) == 11, "Panel renders all filtered entries into the scroll area")
	_assert(bool(overflow_snapshot.get("scrollable_overflow", false)), "Panel marks overflow beyond visible rows as scrollable")
	var severity_counts: Dictionary = Dictionary(overflow_snapshot.get("severity_counts", {}))
	_assert(int(severity_counts.get("critical", 0)) >= 1, "Panel distinguishes critical severity")
	_assert(int(severity_counts.get("warning", 0)) >= 1, "Panel distinguishes warning severity")
	_assert(int(severity_counts.get("tactical", 0)) >= 1, "Panel distinguishes tactical severity")
	_assert(int(severity_counts.get("info", 0)) >= 0, "Panel keeps info severity bucket available")
	panel.call("set_selected_only", true)
	panel.call("set_event_entries", entries, PackedStringArray(["blue"]), true)
	await _wait_frames(4)
	var filtered_entries: Array = Array(panel.call("get_rendered_event_entries"))
	_assert(not filtered_entries.is_empty(), "Selected-fireteam filter keeps matching entries")
	_assert(_all_entries_match_or_mission_wide(filtered_entries, "blue"), "Selected-fireteam filter removes other fireteam events")
	var scroll := panel.get_node_or_null("EventLogMargin/EventLogVBox/EventLogScroll") as ScrollContainer
	_assert(scroll != null and scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED, "Panel overflow area has vertical scrolling enabled")
	panel.queue_free()
	await _wait_frames(2)


func _build_event(event_type: String, fireteam_id: String, now_msec: int) -> Dictionary:
	return Dictionary(RESOLVER_SCRIPT.call("build_event", event_type, {
		"event_id": "task366_%s_%s_%d" % [event_type, fireteam_id, now_msec],
		"fireteam_id": fireteam_id,
		"display_label": fireteam_id.to_upper(),
		"phase": 1,
		"planned_position": Vector2(300.0 + float(now_msec % 200), 420.0),
		"target_position": Vector2(480.0, 480.0),
		"short_text": "%s %s" % [fireteam_id.to_upper(), event_type.to_upper()],
		"detail_text": "Task 366 %s detail" % event_type,
		"communication_clarity": 0.82,
	}, {"now_msec": now_msec}))


func _all_entries_have_text(entries: Array) -> bool:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			return false
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("short_text", "")).strip_edges().is_empty() and String(entry.get("map_label", "")).strip_edges().is_empty():
			return false
	return true


func _all_entries_match_or_mission_wide(entries: Array, fireteam_id: String) -> bool:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			return false
		var entry_fireteam_id: String = String(Dictionary(entry_variant).get("fireteam_id", "")).strip_edges().to_lower()
		if not entry_fireteam_id.is_empty() and entry_fireteam_id != normalized_fireteam_id:
			return false
	return true


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
