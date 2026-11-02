extends SceneTree

const DEBRIEF := preload("res://scenes/meta/debrief_test_screen.tscn")
const MENU := preload("res://scenes/ui/main_menu.tscn")
const ROSTER := preload("res://scripts/meta/start_roster_generator.gd")
const STORE := preload("res://scripts/meta/player_roster_store.gd")
const SETTINGS := preload("res://scripts/ui/game_settings_contract.gd")
const LIBRARY := "MenuRail/MenuMargin/MenuVBox/MenuButtons/TeamLibraryPanel"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		await _test_debrief(size)
	await _test_shell()
	print("RESULTS: %d passed, %d failed" % [_passed, _failed])
	if _failed == 0:
		print("PASS: native R2 debrief and shell")
	quit(1 if _failed > 0 else 0)


func _test_debrief(size: Vector2i) -> void:
	var viewport := _viewport(size)
	var screen := DEBRIEF.instantiate() as Control
	screen.visible = true
	viewport.add_child(screen)
	var result := _result()
	screen.call("set_mission_result", result)
	await _wait(6)
	var bounds := Rect2(Vector2.ZERO, Vector2(size))
	for card_name in ["ResultCard", "PeopleCard", "FeedbackCard", "EventsCard", "ProgressCard", "ReturnCard"]:
		var card := screen.find_child(card_name, true, false) as PanelContainer
		_check(card != null, "%s Debrief has native %s" % [size, card_name])
		if card != null and card_name in ["ResultCard", "PeopleCard", "ReturnCard"]:
			_check(_inside(card.get_global_rect(), bounds), "%s %s stays inside logical viewport" % [size, card_name])
	var people := screen.find_child("DebriefPeopleList", true, false) as VBoxContainer
	_check(people != null, "%s actual person-card list exists" % size)
	if people != null:
		var members := _member_cards(people)
		_check(members.size() == 6, "%s all six supplied people remain represented" % size)
		if not members.is_empty():
			var health := members[0].get_node_or_null("Contents/HealthLabel") as Label
			_check(health != null and health.text.contains("unbekannt") and not health.text.contains("-1"), "%s missing health remains explicitly unknown" % size)
	var returns := {"fob": 0, "home": 0}
	screen.connect("return_to_fob_requested", func(): returns.fob += 1)
	screen.connect("return_to_homebase_requested", func(): returns.home += 1)
	for button_name in ["ReturnToFOBButton", "ReturnToHomebaseButton"]:
		var button := screen.get_node("Panel/Margin/VBox/ButtonRow/" + button_name) as Button
		print("R2 DEBRIEF GEOMETRY %s %s rect=%s row=%s slot=%s" % [size, button_name, button.get_global_rect(), button.get_parent().get_global_rect(), screen.find_child("ButtonRowSlot", true, false).get_global_rect()])
		print("R2 DEBRIEF LEAF %s %s top_level=%s assigned_slot=%s passes=%s" % [size, button_name, button.get_parent().is_set_as_top_level(), button.get_parent().get_meta("native_debrief_card_slot", "missing"), screen.get_meta("native_debrief_layout_passes", 0)])
		_check(button.is_visible_in_tree() and _inside(button.get_global_rect(), bounds), "%s existing %s stays reachable" % [size, button_name])
		button.emit_signal("pressed")
	_check(returns.fob == 1 and returns.home == 1, "%s original return callbacks each emit once" % size)
	_check(screen.call("get_mission_result") == result, "%s presentation preserves the complete mission result" % size)
	var award := screen.get_node("Panel/Margin/VBox/SkillAwardSummaryLabel") as Label
	_check(not award.visible, "%s absent awards are not invented" % size)
	var events := screen.find_child("EventsCard", true, false) as Control
	var event_label := screen.get_node("Panel/Margin/VBox/CharacterEventsLabel") as Label
	print("R2 DEBRIEF GEOMETRY %s events=%s label=%s slot=%s" % [size, events.get_global_rect() if events != null else Rect2(), event_label.get_global_rect(), screen.find_child("CharacterEventsLabelSlot", true, false).get_global_rect() if events != null else Rect2()])
	print("R2 DEBRIEF LEAF %s events top_level=%s assigned_slot=%s" % [size, event_label.is_set_as_top_level(), event_label.get_meta("native_debrief_card_slot", "missing")])
	var original := screen.find_child("DebriefOriginalText", true, false) as TextEdit
	_check(events != null and event_label.text.contains("Personenmeldungen") and events.get_global_rect().encloses(event_label.get_global_rect()) and original != null and original.text.contains("Nur gemeldetes Ereignis"), "%s current event summary retains the supplied original report without a fabricated timeline" % size)
	var passes := int(screen.get_meta("native_debrief_layout_passes", 0))
	await _wait(3)
	_check(int(screen.get_meta("native_debrief_layout_passes", 0)) == passes, "%s idle frames do not poll or rebuild the card layout" % size)
	screen.call("set_mission_result", {})
	await _wait(4)
	people = screen.find_child("DebriefPeopleList", true, false) as VBoxContainer
	_check(people != null and _member_cards(people).is_empty() and _text(people).contains("Keine Personendaten"), "%s empty result has an honest person-data empty state" % size)
	viewport.queue_free()
	await _wait(2)


func _test_shell() -> void:
	var viewport := _viewport(Vector2i(1280, 720))
	var profile := "native_r2_shell_fixture"
	var fixture_path := "user://native_ui_r2/%d/roster.json" % Time.get_ticks_usec()
	var settings_path := "user://native_ui_r2/%d/settings.cfg" % Time.get_ticks_usec()
	var fixture: Dictionary = ROSTER.generate_start_roster("native_r2_controlled", 6, profile)
	var save: Dictionary = STORE.save_roster(fixture, profile, fixture_path)
	_check(bool(save.get("ok", false)), "R2 disposable UI fixture saves through the real store")
	var menu := MENU.instantiate() as Control
	menu.call("set_start_roster_store_path_for_tests", fixture_path, profile, false)
	viewport.add_child(menu)
	menu.call("set_settings_path_for_tests", settings_path)
	await _wait(4)
	var library := menu.get_node(LIBRARY)
	var rows := library.find_children("TeamLibraryEntryButton", "Button", true, false)
	_check(not rows.is_empty(), "Library presents a real saved record")
	if not rows.is_empty():
		var row := rows[0] as Button
		row.grab_focus()
		row.emit_signal("pressed")
		await _wait(2)
		var focused := viewport.gui_get_focus_owner() as Button
		_check(focused != null and String(focused.get_meta("roster_entry_path", "")) == String(row.get_meta("roster_entry_path", "")) if is_instance_valid(row) else false, "Library selection preserves a usable keyboard focus owner")
	menu.call("open_settings_panel")
	menu.call("set_draft_audio_settings", 53.0, 41.0, 29.0)
	await _wait(2)
	for item in [["MasterVolumeCaption", "Gesamt", "53"], ["MusicVolumeCaption", "Musik", "41"], ["SfxVolumeCaption", "Effekte", "29"]]:
		var caption := menu.find_child(item[0], true, false) as Label
		_check(caption != null and caption.text.contains(item[1]) and caption.text.contains(item[2]) and caption.text.contains("%"), "Audio exposes channel and current draft value: %s" % item[0])
	var before: Dictionary = SETTINGS.load_settings(settings_path)
	menu.call("cancel_settings_changes")
	_check(SETTINGS.load_settings(settings_path) == before, "Audio cancel does not persist draft settings")
	viewport.queue_free()
	await _wait(2)
	STORE.delete_roster_for_tests(profile, fixture_path)


func _result() -> Dictionary:
	var people: Array = []
	for index in range(6):
		people.append({"unit_id": "r2_unit_%d" % index, "display_name": "Person %d" % index, "fireteam_id": "alpha", "vital_state": "wounded" if index == 0 else "fit", "health_points": -1 if index == 0 else 80 + index})
	return {"result": "victory", "mission_outcome": "completed", "winning_team_id": "team_alpha", "duration_seconds": 65.0, "objective_captured": true, "win_condition_type": "objective_capture", "team_states": people, "character_events": [{"summary_text": "Nur gemeldetes Ereignis"}]}


func _member_cards(parent: Node) -> Array:
	return parent.get_children().filter(func(child): return child.has_meta("debrief_member_id"))


func _text(node: Node) -> String:
	var text: String = node.text if node is Label else ""
	for child in node.get_children():
		text += "\n" + _text(child)
	return text


func _viewport(size: Vector2i) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = size
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(viewport)
	return viewport


func _inside(rect: Rect2, bounds: Rect2) -> bool:
	return rect.position.x >= -0.5 and rect.position.y >= -0.5 and rect.end.x <= bounds.end.x + 0.5 and rect.end.y <= bounds.end.y + 0.5


func _wait(count: int) -> void:
	for _frame in range(count):
		await process_frame


func _check(ok: bool, message: String) -> void:
	if ok:
		_passed += 1
		print("PASS: " + message)
	else:
		_failed += 1
		push_error("FAIL: " + message)
