extends SceneTree

const DEBRIEF := preload("res://scenes/meta/debrief_test_screen.tscn")
const PROGRESSION := preload("res://scripts/meta/mission_progression_resolver.gd")
var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		for variant in ["empty", "sparse", "rich", "partial"]:
			await _test_report(size, variant)
		await _test_layout_changes(size)
	print("RESULTS: %d passed, %d failed" % [_passed, _failed])
	if _failed == 0:
		print("PASS: native R3 debrief")
	quit(1 if _failed > 0 else 0)


func _test_report(size: Vector2i, variant: String) -> void:
	var viewport := SubViewport.new()
	viewport.size = size
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(viewport)
	var screen := DEBRIEF.instantiate() as Control
	screen.visible = true
	viewport.add_child(screen)
	var report := build_fixture(variant)
	screen.call("set_mission_result", report)
	await _wait(8)
	var prefix := "%s %s: " % [size, variant]
	var panel := screen.get_node("Panel") as Control
	var rect := panel.get_global_rect()
	var bounds := Rect2(Vector2.ZERO, Vector2(size))
	print("R3 DEBRIEF %s panel=%s" % [prefix, rect])
	_check(bounds.encloses(rect), prefix + "actual result window stays in the logical viewport")
	_check(rect.get_center().distance_to(bounds.get_center()) <= 2.0, prefix + "result window is centered")
	if variant == "empty":
		_check(rect.size.x <= 980 and rect.size.y <= 380, prefix + "empty report is at most 980x380")
	elif variant in ["sparse", "partial"]:
		_check(rect.size.x <= 1360 and rect.size.y <= (640 if size.x >= 1920 else 624), prefix + "sparse report has a bounded content-sized window")
		if size.x >= 1920:
			_check(rect.get_area() <= bounds.get_area() * 0.55, prefix + "sparse window uses at most 55 percent of Full HD")
		for name in ["AARCard", "EventsCard", "FeedbackCard"]:
			var card := screen.find_child(name, true, false) as Control
			_check(card != null and (not card.is_visible_in_tree() or card.size.y <= (132 if name == "FeedbackCard" else 76)), prefix + name + " does not stretch absent or brief data")
	var primary := _visible_text(screen)
	for token in ["Skill Preview:", "Skill Awards:", "Winner team_", "Character updates:", "Personnel updates:", "FTL feedback:", "WIN TEAM_", "COND ", "Air asset:"]:
		_check(not primary.contains(token), prefix + "primary UI avoids diagnostic token " + token)
	if variant != "empty":
		_check(primary.contains("Vorschau") and primary.to_lower().contains("bestätigt"), prefix + "preview and confirmation are explicitly distinguished")
	if variant != "rich":
		_check(not primary.contains("XP +") and not primary.contains("EP +"), prefix + "no missing awards are fabricated")
	else:
		_check_aar_chip_values(screen, report, prefix)
		var people := screen.find_child("PeopleScroll", true, false) as ScrollContainer
		var aar := screen.find_child("DebriefAARRowsScroll", true, false) as ScrollContainer
		_check(people != null and people.get_v_scroll_bar().visible, prefix + "many real people have a native scroll")
		_check(aar != null and aar.get_v_scroll_bar().visible, prefix + "all supplied AAR rows have a native scroll")
		if aar != null:
			_check(aar.get_node("Rows").get_child_count() == 24, prefix + "all twenty-four supplied AAR records remain present")
			aar.scroll_vertical = int(aar.get_v_scroll_bar().max_value)
			await _wait(2)
			_check(aar.scroll_vertical > 0, prefix + "rich AAR can actually scroll to later records")
	if variant == "partial":
		_check(primary.contains("Dauer: unbekannt") and primary.contains("Ziel: nicht angegeben"), prefix + "missing outcome fields never become zero duration or a false objective state")
		_check(not primary.contains("Einsatz abgeschlossen") and not primary.contains("999"), prefix + "incomplete report and unapplied award are not presented as confirmed")
	var returns := {"fob": 0, "home": 0}
	screen.connect("return_to_fob_requested", func(): returns.fob += 1)
	screen.connect("return_to_homebase_requested", func(): returns.home += 1)
	for name in ["ReturnToFOBButton", "ReturnToHomebaseButton"]:
		var button := screen.get_node("Panel/Margin/VBox/ButtonRow/" + name) as Button
		_check(_reachable(button, bounds), prefix + name + " remains reachable")
	_check_return_row_geometry(screen, prefix)
	_check(screen.call("get_mission_result") == report, prefix + "presentation preserves the supplied result exactly")
	var details_button := screen.find_child("DebriefDetailsButton", true, false) as Button
	_check(details_button != null and _reachable(details_button, bounds), prefix + "original-report action is explicitly reachable")
	if details_button != null:
		details_button.emit_signal("pressed")
		await _wait(3)
		var overlay := screen.find_child("DebriefDetailsOverlay", true, false) as Control
		var text := screen.find_child("DebriefOriginalText", true, false) as TextEdit
		_check(overlay != null and overlay.is_visible_in_tree() and overlay.mouse_filter == Control.MOUSE_FILTER_STOP, prefix + "details establish an input-blocking native overlay")
		_check(text != null and not text.editable and JSON.parse_string(text.text) == JSON.parse_string(JSON.stringify(report)), prefix + "read-only original report retains every raw field")
		_check(not paused, prefix + "opening details does not pause simulation")
		var close := screen.find_child("CloseDebriefDetailsButton", true, false) as Button
		if text != null and close != null:
			text.grab_focus()
			await _key(viewport, KEY_TAB)
			_check(viewport.gui_get_focus_owner() == close, prefix + "real Tab moves from original text to the modal close action")
			await _key(viewport, KEY_TAB)
			_check(viewport.gui_get_focus_owner() == text, prefix + "real Tab wraps inside the original-report controls")
			await _key(viewport, KEY_TAB, true)
			_check(viewport.gui_get_focus_owner() == close, prefix + "real Shift-Tab wraps inside the original-report controls")
			await _key(viewport, KEY_TAB, true)
			_check(viewport.gui_get_focus_owner() == text, prefix + "reverse traversal returns to the original text")
			var original_text := text.text
			await _key(viewport, KEY_ENTER)
			_check(overlay.visible and returns.fob == 0 and returns.home == 0 and text.text == original_text, prefix + "Enter in read-only text does not route behind the modal or modify the report")
			await _key(viewport, KEY_TAB)
			await _key(viewport, KEY_ENTER)
			_check(not overlay.visible and returns.fob == 0 and returns.home == 0, prefix + "Enter on modal close dismisses details without invoking a return action")
			details_button.emit_signal("pressed")
			await _wait(2)
		var fob := screen.get_node("Panel/Margin/VBox/ButtonRow/ReturnToFOBButton") as Button
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		click.position = fob.get_global_rect().get_center()
		viewport.push_input(click, true)
		var release := click.duplicate() as InputEventMouseButton
		release.pressed = false
		viewport.push_input(release, true)
		await _wait(2)
		_check(returns.fob == 0, prefix + "details prevent a click through to the return action")
		screen.hide()
		await _wait(2)
		_check(overlay != null and not overlay.visible, prefix + "screen hide closes details rather than leaving a detached popup")
		screen.show()
		details_button.emit_signal("pressed")
		await _wait(2)
		fob.emit_signal("pressed")
		_check(returns.fob == 1 and overlay != null and not overlay.visible, prefix + "original return callback closes details and emits once")
	var passes := int(screen.get_meta("native_debrief_layout_passes", 0))
	await _wait(3)
	_check(int(screen.get_meta("native_debrief_layout_passes", 0)) == passes, prefix + "idle frames do not poll the layout")
	viewport.queue_free()
	await _wait(2)


func _test_layout_changes(initial_size: Vector2i) -> void:
	var viewport := SubViewport.new()
	viewport.size = initial_size
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(viewport)
	var screen := DEBRIEF.instantiate() as Control
	screen.visible = true
	viewport.add_child(screen)
	screen.call("set_mission_result", build_fixture("rich"))
	await _wait(8)
	var prefix := "%s layout changes: " % initial_size
	_check_return_row_geometry(screen, prefix + "initial rich ")
	# A centered window can move without changing any slot's local rectangle.
	# This is the native ancestor-translation case that previously left the
	# preserved top-level button row at its earlier canvas position.
	var panel := screen.get_node("Panel") as Control
	panel.position += Vector2(0, 21)
	await _wait(4)
	_check_return_row_geometry(screen, prefix + "ancestor translation ")
	screen.call("set_mission_result", build_fixture("sparse"))
	await _wait(8)
	_check_return_row_geometry(screen, prefix + "rich to sparse ")
	viewport.size = Vector2i(1280, 720) if initial_size.x == 1920 else Vector2i(1920, 1080)
	await _wait(8)
	_check_return_row_geometry(screen, prefix + "logical viewport resize ")
	screen.call("set_mission_result", build_fixture("rich"))
	await _wait(8)
	_check_return_row_geometry(screen, prefix + "sparse to rich ")
	viewport.size = initial_size
	await _wait(8)
	_check_return_row_geometry(screen, prefix + "logical viewport restored ")
	screen.call("set_mission_result", build_fixture("empty"))
	await _wait(8)
	_check_return_row_geometry(screen, prefix + "rich to empty ")
	var passes := int(screen.get_meta("native_debrief_layout_passes", 0))
	await _wait(3)
	_check(int(screen.get_meta("native_debrief_layout_passes", 0)) == passes, prefix + "settled layout remains idle without polling")
	viewport.queue_free()
	await _wait(2)


func _check_return_row_geometry(screen: Control, prefix: String) -> void:
	var row := screen.get_node("Panel/Margin/VBox/ButtonRow") as Control
	var slot := screen.get_node("Panel/Margin/VBox/NativeReviewLayout/ReturnCard/Contents/ButtonRowSlot") as Control
	var card := slot.get_parent().get_parent() as Control
	var actual := row.get_global_rect()
	var expected := slot.get_global_rect()
	print("R3 RETURN GEOMETRY %s row=%s slot=%s card=%s" % [prefix, actual, expected, card.get_global_rect()])
	_check(actual.position.distance_to(expected.position) <= 0.5 and actual.size.distance_to(expected.size) <= 0.5, prefix + "actual return row matches its settled native slot")
	_check(card.get_global_rect().encloses(actual), prefix + "return card encloses the actual return actions")


static func build_fixture(variant: String) -> Dictionary:
	if variant == "empty":
		return {}
	if variant == "partial":
		return {"team_states": [{"unit_id": "known_person", "display_name": "Person ohne vollständigen Bericht"}], "progression_award_summary": {"schema": "sternenbuergerchen.skill_progress_award_summary.v1", "authority": "MissionProgressionResolver", "source": "progression_unit_updates", "award_applied": false, "read_only": true, "ui_sets_gameplay_truth": false, "total_xp_delta": 999}}
	var rich := variant == "rich"
	var states: Array = []
	var updates: Array = []
	for index in range(12 if rich else 3):
		var id := "r3_person_%02d" % index
		states.append({"unit_id": id, "display_name": "Person %02d" % index, "fireteam_id": "alpha", "vital_state": "wounded" if index == 2 else "fit", "health_points": 42 if index == 2 else 88})
		updates.append({"unit_id": id, "display_name": "Person %02d" % index, "fireteam_id": "alpha", "xp_delta": 20, "skill_gains": {"accuracy": 0.004}, "ftl_tactical_gain": 0.003 if index == 0 else 0.0})
	var result := {"mission_id": "r3_explicit_test_fixture", "result": "victory", "mission_outcome": "completed", "winning_team_id": "team_alpha", "duration_seconds": 185.0, "objective_captured": true, "win_condition_type": "objective_capture", "team_states": states, "fireteam_tactical_debrief": [{"fireteam_id": "alpha", "reaction_delay_seconds": 0.42, "plan_quality": 0.76, "tempo_modifier": 1.08, "contact_report_count": 3, "contact_report_quality": 0.72, "morale": 0.68, "frustration": 0.22}]}
	if rich:
		var rows: Array = []
		for index in range(24):
			rows.append({"id": "fixture_metric_%02d" % index, "label": "Protokollwert %02d" % index, "value_text": str(index + 1), "read_only": true})
		result["mini_aar_debrief"] = {"schema": "sternenbuergerchen.mini_aar_debrief_screen_stub.v1", "source_schema": "sternenbuergerchen.mini_aar_combat_metrics.v1", "read_only": true, "ui_sets_gameplay_truth": false, "summary_text": "AAR | FIRE 12 | HIT 7 | FF 1/2 | SUP 3", "rows": rows, "chips": [{"id": "shots", "label": "FIRE", "value_text": "12", "style_key": "neutral", "read_only": true}, {"id": "hits", "label": "HIT", "value_text": "7", "style_key": "good", "read_only": true}, {"id": "ff", "label": "FF", "value_text": "1/2", "style_key": "warn", "read_only": true}, {"id": "sup", "label": "SUP", "value_text": "3", "style_key": "accent", "read_only": true}, {"id": "extracted", "label": "EXT", "value_text": "2", "style_key": "neutral", "read_only": true}], "limit_text": "Keine XP, keine Ammo, keine echte Suppression - nur Debrief-Vorschau aus vorhandenen Metriken.", "gate": "pass"}
		result["character_events"] = [{"summary_text": "Erste gemeldete Folge"}, {"summary_text": "Weitere Folge"}, {"summary_text": "Weitere Folge"}, {"summary_text": "Weitere Folge"}, {"summary_text": "Weitere Folge"}, {"summary_text": "Letzte Rich-Meldung – Größe ß"}]
		result["progression_unit_updates"] = updates
		result["progression_award_summary"] = PROGRESSION.build_award_summary(updates, {"mission_id": result.mission_id, "mission_outcome": result.mission_outcome})
	return result


func _check_aar_chip_values(screen: Control, report: Dictionary, prefix: String) -> void:
	var strip := screen.get_node("Panel/Margin/VBox/AARChipStrip") as HBoxContainer
	var chips: Array = Dictionary(report.get("mini_aar_debrief", {})).get("chips", [])
	for index in range(mini(chips.size(), strip.get_child_count())):
		var source: Dictionary = chips[index]
		var label := strip.get_child(index) as Label
		var value := String(source.get("value_text", ""))
		var font := label.get_theme_font("font")
		var font_size := label.get_theme_font_size("font_size")
		var padding := label.get_theme_stylebox("normal").get_minimum_size()
		var available := label.size.x - padding.x
		var required := font.get_string_size(value + " · ...", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		print("R3 AAR VALUE %s %s available=%.2f required=%.2f text=%s" % [prefix, source.get("id", ""), available, required, label.text])
		_check(label.is_visible_in_tree() and label.text.begins_with(value + " · ") and available >= required, prefix + "%s keeps its complete value before any ellipsis within actual content width" % source.get("id", ""))
		_check(font_size == 11 and label.size.y - padding.y >= font.get_height(font_size), prefix + "%s retains the existing readable type size and line height" % source.get("id", ""))
		_check(label.mouse_filter != Control.MOUSE_FILTER_IGNORE and label.tooltip_text.contains(value) and label.tooltip_text.contains(String(source.get("label", ""))), prefix + "%s exposes full metric/value context through an enabled tooltip" % source.get("id", ""))


func _visible_text(node: Node) -> String:
	var text: String = node.text if node is Label and node.is_visible_in_tree() else ""
	for child in node.get_children():
		text += "\n" + _visible_text(child)
	return text


func _reachable(control: Control, bounds: Rect2) -> bool:
	if control == null or not control.is_visible_in_tree() or not bounds.encloses(control.get_global_rect()):
		return false
	var parent := control.get_parent()
	while parent != null:
		if parent is Control and parent.clip_contents and not parent.get_global_rect().encloses(control.get_global_rect()):
			return false
		parent = parent.get_parent()
	return true


func _wait(count: int) -> void:
	for _frame in range(count):
		await process_frame


func _key(viewport: Viewport, key: Key, shift: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.shift_pressed = shift
	event.pressed = true
	viewport.push_input(event, true)
	var release := event.duplicate() as InputEventKey
	release.pressed = false
	viewport.push_input(release, true)
	await _wait(2)


func _check(ok: bool, message: String) -> void:
	if ok:
		_passed += 1
		print("PASS: " + message)
	else:
		_failed += 1
		push_error("FAIL: " + message)
