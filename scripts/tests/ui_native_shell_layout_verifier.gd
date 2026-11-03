extends SceneTree

const MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")
const HOMEBASE_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const ROSTER: GDScript = preload("res://scripts/meta/start_roster_generator.gd")
const STORE: GDScript = preload("res://scripts/meta/player_roster_store.gd")
const THEME: GDScript = preload("res://scripts/ui/tactical_ui_theme.gd")
const FIXTURE_PROFILE_ID := "ui_native_shell_fixture"
const LIBRARY_PATH := "MenuRail/MenuMargin/MenuVBox/MenuButtons/TeamLibraryPanel"
const SHEET_PATH := "CharacterSheetPopup/PopupPanel/PopupMargin/PopupVBox/PopupScroll/GeneratedSheetContent"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if OS.get_cmdline_user_args().has("--diagnose-old-fixture"):
		_diagnose_old_fixture()
	for viewport_size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		await _test_shell(viewport_size)
	await _test_homebase_detail_owner()
	print("RESULTS: %d passed, %d failed" % [_passed, _failed])
	if _failed == 0:
		print("PASS: native shell layout")
	quit(1 if _failed > 0 else 0)


func _test_shell(viewport_size: Vector2i) -> void:
	var viewport := _make_viewport(viewport_size)
	var menu := MENU_SCENE.instantiate() as Control
	var fixture_id := "native_shell_%d_%d_%d" % [viewport_size.x, viewport_size.y, Time.get_ticks_usec()]
	var fixture_path := "user://native_ui_shell_fixtures/%s/roster.json" % fixture_id
	var fixture: Dictionary = ROSTER.call("generate_start_roster", "native_shell_fixture", 24, FIXTURE_PROFILE_ID)
	# This tests window layout and selection with controlled legal profile data.
	# RNG/trait balance is outside this UI verifier: all eight documented
	# MetaUnitProfile.skill_values are neutral 0.5, within the store contract.
	var fixture_units: Array = Array(fixture.get("units", []))
	for unit_index in range(fixture_units.size()):
		var unit: Dictionary = Dictionary(fixture_units[unit_index]).duplicate(true)
		var skills: Dictionary = Dictionary(unit.get("skill_values", {})).duplicate(true)
		for key in ["accuracy", "speed", "toughness", "awareness", "recognition", "stealth", "discipline", "leadership"]:
			skills[key] = 0.5
		unit["skill_values"] = skills
		fixture_units[unit_index] = unit
	fixture["units"] = fixture_units
	var payload: Dictionary = STORE.call("build_save_payload", fixture, FIXTURE_PROFILE_ID)
	var fixture_validation: Dictionary = STORE.call("validate_payload", payload)
	_check(bool(fixture_validation.get("valid", false)), "%s controlled UI fixture satisfies the full store validation" % viewport_size)
	var fixture_save: Dictionary = STORE.call("save_roster", fixture, FIXTURE_PROFILE_ID, fixture_path)
	_print_save_result("FIXTURE SAVE %s" % viewport_size, fixture_save)
	_check(bool(fixture_save.get("ok", false)), "%s valid isolated roster fixture is stored before menu startup" % viewport_size)
	menu.call("set_start_roster_store_path_for_tests", fixture_path, FIXTURE_PROFILE_ID, false)
	viewport.add_child(menu)
	await _wait_frames(4)
	var bounds := Rect2(Vector2.ZERO, Vector2(viewport_size))
	var library := menu.get_node(LIBRARY_PATH) as Control
	var rail := menu.get_node("MenuRail") as Control
	var fixture_row := _find_library_row(library, fixture_path)
	_check(fixture_row != null, "%s real library contains the isolated fixture record" % viewport_size)
	if fixture_row != null:
		fixture_row.emit_signal("pressed")
	await _wait_frames(2)
	print("LIBRARY %s %s" % [viewport_size, JSON.stringify(menu.call("get_team_library_snapshot"))])
	print("GEOMETRY %s library=%s" % [viewport_size, library.get_global_rect()])
	_check(library.is_visible_in_tree(), "%s library is visible in the menu" % viewport_size)
	_check(_inside(library.get_global_rect(), bounds), "%s library stays within viewport" % viewport_size)
	_check(library.get_global_rect().position.x >= rail.get_global_rect().end.x + 8.0, "%s library is separate from left menu rail" % viewport_size)
	var selected := _find_selected_library_row(library)
	_check(selected != null, "%s fixture produces an actually selected library record" % viewport_size)
	if selected != null:
		var style := selected.get_theme_stylebox("normal") as StyleBoxFlat
		_check(style != null and style.border_color.is_equal_approx(THEME.COLOR_BORDER_SELECTED), "%s selected record has yellow frame" % viewport_size)

	menu.call("open_settings_panel")
	await _wait_frames(3)
	var settings := menu.get_node("SettingsPanel") as Control
	print("GEOMETRY %s settings=%s" % [viewport_size, settings.get_global_rect()])
	var shell := menu.get_node("SettingsPanel/SettingsMargin/SettingsVBox") as VBoxContainer
	var title := shell.get_node_or_null("SettingsTitleLabel") as Label
	var body := shell.get_node_or_null("SettingsBodyScroll") as ScrollContainer
	var footer := shell.get_node_or_null("SettingsActionRow") as HBoxContainer
	_check(settings.is_visible_in_tree() and _inside(settings.get_global_rect(), bounds), "%s settings window is bounded" % viewport_size)
	_check(title != null and title.is_visible_in_tree() and _inside(title.get_global_rect(), bounds), "%s fixed settings title is visible" % viewport_size)
	_check(body != null and body.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "%s settings body is scrollable" % viewport_size)
	_check(footer != null and footer.is_visible_in_tree(), "%s footer is separate from scroll content" % viewport_size)
	if footer != null:
		for button_name in ["SettingsApplyButton", "SettingsResetButton", "SettingsBackButton"]:
			var button := footer.get_node_or_null(NodePath(button_name)) as Button
			_check(button != null and button.is_visible_in_tree() and _inside(button.get_global_rect(), bounds), "%s %s remains reachable" % [viewport_size, button_name])
	if body != null and title != null and footer != null:
		_check(body.get_v_scroll_bar().visible, "%s long input overview exposes vertical scrolling" % viewport_size)
		var title_before := title.get_global_rect()
		var footer_before := footer.get_global_rect()
		body.scroll_vertical = int(body.get_v_scroll_bar().max_value)
		await _wait_frames(2)
		_check(body.scroll_vertical > 0, "%s body can actually scroll" % viewport_size)
		_check(title.get_global_rect().is_equal_approx(title_before), "%s scrolling leaves title fixed" % viewport_size)
		_check(footer.get_global_rect().is_equal_approx(footer_before), "%s scrolling leaves actions fixed" % viewport_size)
	menu.call("close_settings_panel")
	await _wait_frames(1)
	_check(not settings.visible and library.is_visible_in_tree(), "%s cancel/close returns to visible team library" % viewport_size)

	menu.call("open_team_editor")
	await _wait_frames(4)
	var editor := menu.get_node("TeamEditorPanel") as Control
	print("GEOMETRY %s creator=%s" % [viewport_size, editor.get_global_rect()])
	var editor_header := editor.find_child("TeamEditorHeaderRow", true, false) as HBoxContainer
	var editor_scroll := editor.find_child("TeamEditorBodyScroll", true, false) as ScrollContainer
	_check(editor.is_visible_in_tree() and _inside(editor.get_global_rect(), bounds), "%s Creator outer frame is bounded" % viewport_size)
	_check(editor_scroll != null and editor_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "%s Creator body can scroll instead of expanding the window" % viewport_size)
	for button_name in ["TeamEditorSaveButton", "TeamEditorCloseButton"]:
		var button := editor.find_child(button_name, true, false) as Button
		_check(button != null and button.is_visible_in_tree() and _inside(button.get_global_rect(), bounds), "%s %s remains reachable" % [viewport_size, button_name])
	if editor_header != null and editor_scroll != null:
		var header_before := editor_header.get_global_rect()
		editor_scroll.scroll_horizontal = int(editor_scroll.get_h_scroll_bar().max_value)
		editor_scroll.scroll_vertical = int(editor_scroll.get_v_scroll_bar().max_value)
		await _wait_frames(2)
		_check(editor_header.get_global_rect().is_equal_approx(header_before), "%s Creator scroll leaves Save/Close header fixed" % viewport_size)
	menu.call("close_team_editor")
	await _wait_frames(1)
	_check(library.is_visible_in_tree(), "%s closing Creator restores the same team library" % viewport_size)
	viewport.queue_free()
	await _wait_frames(3)
	STORE.call("delete_roster_for_tests", FIXTURE_PROFILE_ID, fixture_path)


func _test_homebase_detail_owner() -> void:
	var viewport := _make_viewport(Vector2i(1920, 1080))
	var homebase := HOMEBASE_SCENE.instantiate() as Control
	viewport.add_child(homebase)
	await _wait_frames(3)
	var generated: Dictionary = ROSTER.call("generate_start_roster", "native_shell_profile", 24)
	homebase.call("setup_roster", Array(generated.get("units", [])))
	await _wait_frames(3)
	var list := homebase.get_node("Panel/Margin/VBox/ContentRow/RosterPanel/RosterMargin/RosterVBox/RosterScroll/RosterList")
	_check(list.get_child_count() > 0, "Homebase has real compact roster cards")
	if list.get_child_count() > 0:
		var card := list.get_child(0)
		var profile = card.call("get_profile_reference_for_readonly_display")
		var before: Dictionary = profile.call("to_dict")
		var unit_id := String(card.call("get_unit_id"))
		card.emit_signal("card_open_requested", unit_id, profile, "roster")
		await _wait_frames(3)
		var popup := homebase.get_node("CharacterSheetPopup") as Control
		var host := homebase.get_node(SHEET_PATH) as VBoxContainer
		var labels := _collect_labels(host)
		_check(popup.is_visible_in_tree(), "Existing card detail signal opens the actual homebase popup")
		_check(_contains(labels, String(before.get("display_name", ""))), "Popup shows the requested person's identity")
		for required in ["STATUS / RECOVERY:", "KERNWERTE", "TEAMFIT:", "PROGRESS:"]:
			_check(_contains(labels, required), "Actual popup contains " + required)
		_check(host.find_children("*", "ProgressBar", true, false).size() >= 8, "Actual popup includes populated core-value bars")
		_check(_editable_metric_count(host) == 0, "Homebase popup remains a read-only character sheet")
		_check(profile.call("to_dict") == before, "Opening a detail sheet does not mutate the profile")
		var retired := homebase.get_node("Panel/Margin/VBox/ContentRow/InfoPanel") as Control
		_check(not retired.visible, "Retired InfoPanel is not mistaken for current character owner")
	viewport.queue_free()
	await _wait_frames(3)


func _print_save_result(label: String, result: Dictionary) -> void:
	# Payload is the full generated roster; keep every result/diagnostic field.
	var metadata := result.duplicate(true)
	metadata.erase("payload")
	print("%s %s" % [label, JSON.stringify(metadata)])


func _diagnose_old_fixture() -> void:
	# Optional reproducer for the exact formerly time-dependent generator input.
	# It is diagnostic evidence, not part of the current layout fixture.
	var old_profile := "native_shell_1280_720_3799609"
	var path := "user://native_ui_shell_fixtures/diagnostic_%d/roster.json" % Time.get_ticks_usec()
	var roster: Dictionary = ROSTER.call("generate_start_roster", "native_shell_fixture", 24, old_profile)
	var result: Dictionary = STORE.call("save_roster", roster, old_profile, path)
	_print_save_result("DIAGNOSTIC OLD FIXTURE SAVE", result)
	STORE.call("delete_roster_for_tests", old_profile, path)


func _make_viewport(viewport_size: Vector2i) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(viewport)
	return viewport


func _find_library_row(parent: Node, entry_path: String) -> Button:
	for child in parent.get_children():
		if child is Button and String(child.get_meta("roster_entry_path", "")) == entry_path:
			return child as Button
		var nested := _find_library_row(child, entry_path)
		if nested != null:
			return nested
	return null


func _find_selected_library_row(parent: Node) -> Button:
	for child in parent.get_children():
		if child is Button and bool(child.get_meta("active_roster", false)) and (child as Button).button_pressed:
			return child as Button
		var nested := _find_selected_library_row(child)
		if nested != null:
			return nested
	return null


func _collect_labels(parent: Node) -> PackedStringArray:
	var labels := PackedStringArray()
	if parent is Label:
		labels.append((parent as Label).text)
	for child in parent.get_children():
		labels.append_array(_collect_labels(child))
	return labels


func _contains(labels: PackedStringArray, fragment: String) -> bool:
	if fragment.is_empty():
		return false
	for label in labels:
		if label.contains(fragment):
			return true
	return false


func _editable_metric_count(parent: Node) -> int:
	var count := 1 if parent is HSlider or parent is SpinBox or parent is LineEdit or parent is OptionButton else 0
	for child in parent.get_children():
		count += _editable_metric_count(child)
	return count


func _inside(rect: Rect2, bounds: Rect2) -> bool:
	return rect.position.x >= bounds.position.x - 1.0 and rect.position.y >= bounds.position.y - 1.0 and rect.end.x <= bounds.end.x + 1.0 and rect.end.y <= bounds.end.y + 1.0


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _check(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
	print("%s: %s" % ["PASS" if condition else "FAIL", message])
