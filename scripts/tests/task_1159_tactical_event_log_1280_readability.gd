extends SceneTree

const PANEL_SCRIPT := preload("res://scripts/ui/tactical_event_log_panel.gd")
const POLISH_STYLE_ID := "task_889_release_first_exchange_hud_density_fire_visual_polish_v1"

var _checks := 0
var _failures: PackedStringArray = []


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	var panel := PANEL_SCRIPT.new()
	panel.collapse_when_empty = false
	panel.custom_minimum_size = Vector2(240.0, 184.0)
	root.add_child(panel)
	await _wait_frames(2)

	var entries: Array = []
	for index in range(6):
		entries.append({
			"event_id": "event_%d" % index,
			"created_msec": 1000 + index * 1000,
			"severity": "critical" if index == 5 else "tactical",
			"fireteam_id": "blue",
			"short_text": "Kontaktmeldung %d" % index,
		})
	var feedback := {
		"selected_fireteam_ids": ["blue"],
		"tactical_event_log": entries,
		"event_log_selected_only_default": false,
		"release_first_exchange_hud_density_fire_visual_polish": {
			"active": true,
			"style_id": POLISH_STYLE_ID,
			"event_log_max_visible_events": 4,
		},
	}
	panel.set_feedback_snapshot(feedback)
	await _wait_frames(2)

	var snapshot: Dictionary = panel.get_panel_snapshot()
	var rows := panel.get_node_or_null("EventLogMargin/EventLogVBox/EventLogScroll/EventLogEntries") as VBoxContainer
	var header := panel.get_node_or_null("EventLogMargin/EventLogVBox/EventLogHeader/EventLogHeaderLabel") as Label
	var filter := panel.get_node_or_null("EventLogMargin/EventLogVBox/EventLogHeader/EventLogSelectedFilterButton") as CheckButton
	_check(int(snapshot.get("max_visible_events", 0)) == 4, "First exchange keeps four readable events")
	_check(int(snapshot.get("rendered_entry_count", 0)) == 4, "Only four newest events are rendered")
	_check(float(snapshot.get("row_min_height", 0.0)) >= 32.0, "Rows keep the 1280 readability height")
	_check(int(snapshot.get("row_font_size", 0)) >= 13, "Event text uses the 1280 font floor")
	_check(header != null and header.get_theme_font_size("font_size") >= 13, "Header uses the 1280 font floor")
	_check(filter != null and filter.get_theme_font_size("font_size") >= 10, "Selection filter remains readable")
	_check(float(snapshot.get("background_alpha", 0.0)) >= 0.94, "Event text has an opaque tactical background")
	_check(rows != null and rows.get_child_count() == 4, "Row tree matches the capped event set")
	if rows != null:
		for row_variant in rows.get_children():
			var row := row_variant as HBoxContainer
			var time_label := row.get_node_or_null("TimeLabel") as Label if row != null else null
			var text_label := row.get_node_or_null("EventTextLabel") as Label if row != null else null
			var strip := row.get_node_or_null("SeverityStrip") as ColorRect if row != null else null
			_check(time_label != null and time_label.get_theme_font_size("font_size") >= 12, "%s time remains readable" % row.name)
			_check(text_label != null and text_label.get_theme_font_size("font_size") >= 13, "%s message remains readable" % row.name)
			_check(strip != null and strip.custom_minimum_size.x >= 5.0, "%s keeps severity" % row.name)

	var row_ids_before: PackedInt64Array = PackedInt64Array()
	if rows != null:
		for row in rows.get_children():
			row_ids_before.append(row.get_instance_id())
	panel.set_feedback_snapshot(feedback)
	await _wait_frames(2)
	var duplicate_snapshot: Dictionary = panel.get_panel_snapshot()
	var row_ids_after: PackedInt64Array = PackedInt64Array()
	if rows != null:
		for row in rows.get_children():
			row_ids_after.append(row.get_instance_id())
	_check(row_ids_after == row_ids_before, "Identical snapshot does not rebuild rows")
	_check(int(duplicate_snapshot.get("feedback_snapshot_skip_count", 0)) >= 1, "Identical snapshot records a cheap skip")
	_check(not bool(duplicate_snapshot.get("feedback_snapshot_sets_gameplay_truth", true)), "Panel owns no gameplay truth")

	panel.queue_free()
	await _wait_frames(2)
	if _failures.is_empty():
		print("TASK_1159 PASS (%d checks)" % _checks)
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
