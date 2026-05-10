extends SceneTree

const DEBRIEF_SCENE: PackedScene = preload("res://scenes/meta/debrief_test_screen.tscn")
const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")
const START_ROSTER_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/start_roster_generator.gd")
const META_UNIT_PROFILE_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile.gd")
const CHARACTER_SHEET_VIEW_SCRIPT: GDScript = preload("res://scripts/meta/character_sheet_view.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Bugfix Debrief Background and Main Menu Team Library ===")
	await _test_debrief_uses_catalog_background()
	await _test_main_menu_lists_created_teams_and_deletes_archives()
	await _test_character_sheet_edit_controls_and_last_loadout_dropdowns()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_debrief_uses_catalog_background() -> void:
	var debrief := DEBRIEF_SCENE.instantiate() as Control
	root.add_child(debrief)
	await process_frame
	var snapshot: Dictionary = Dictionary(debrief.call("get_background_catalog_snapshot"))
	var background := debrief.get_node_or_null("Background") as TextureRect
	var shade := debrief.get_node_or_null("BackgroundShade") as ColorRect
	var panel := debrief.get_node_or_null("Panel") as PanelContainer
	_assert(String(snapshot.get("background_id", "")) == "debrief_desert_explosion_base", "Debrief exposes the catalog background ID")
	_assert(bool(snapshot.get("uses_catalog", false)), "Debrief background comes from the background catalog")
	_assert(background != null and background.texture != null, "Debrief has a textured background node")
	_assert(background != null and background.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "Debrief background uses covered crop")
	_assert(shade != null and shade.color.a >= 0.55, "Debrief applies a readable dim shade")
	_assert(float(snapshot.get("panel_alpha", 1.0)) <= 0.65, "Debrief panel is translucent enough to show the background image")
	_assert(panel != null and String(panel.get_meta("background_readability_policy", "")) == "dimmed_catalog_background", "Debrief panel documents background readability")
	_assert(debrief.find_child("SimulationRoot", true, false) == null, "Debrief background does not create gameplay simulation state")
	debrief.queue_free()
	await process_frame


func _test_main_menu_lists_created_teams_and_deletes_archives() -> void:
	var save_path: String = "user://bugfix_team_library_%d/roster_v1.json" % Time.get_ticks_msec()
	var menu := MAIN_MENU_SCENE.instantiate() as Control
	root.add_child(menu)
	await _wait_frames(3)
	menu.call("set_start_roster_store_path_for_tests", save_path, "bugfix_team_library", true)
	menu.call("ensure_start_roster_exists", "bugfix_team_library_seed", 24)
	var initial_snapshot: Dictionary = Dictionary(menu.call("get_team_library_snapshot"))
	_assert(bool(initial_snapshot.get("visible", false)), "Main menu shows the created team list")
	_assert(int(initial_snapshot.get("entry_count", 0)) == 1, "Created team list starts with the active team")
	_assert(bool(initial_snapshot.get("selected_is_active", false)), "Active team is visibly selected")
	_assert(not bool(initial_snapshot.get("delete_enabled", true)), "Delete is disabled for the active team")
	var initial_editor: Dictionary = Dictionary(menu.call("get_team_editor_snapshot"))
	_assert(bool(initial_editor.get("visible", false)), "Start screen shows the team editor")
	_assert(int(initial_editor.get("budget_max", 0)) == 30, "Team editor uses a 30 point rookie cap")
	_assert(int(initial_editor.get("budget_used", 0)) <= 30, "Team editor never exceeds the rookie cap")
	_assert(int(initial_editor.get("emblem_option_count", 0)) > 1 and bool(initial_editor.get("has_emblem_texture", false)), "Team editor exposes existing image choices")
	var blocked_plus: Dictionary = Dictionary(menu.call("adjust_team_editor_stat_for_tests", "tactics", 1))
	_assert(bool(blocked_plus.get("ok", false)) and not bool(blocked_plus.get("changed", true)), "Full rookie budget blocks extra points")
	var lowered_stat: Dictionary = Dictionary(menu.call("adjust_team_editor_stat_for_tests", "tactics", -1))
	_assert(bool(lowered_stat.get("ok", false)) and bool(lowered_stat.get("changed", false)), "Team editor minus frees a point")
	var raised_stat: Dictionary = Dictionary(menu.call("adjust_team_editor_stat_for_tests", "tactics", 1))
	_assert(bool(raised_stat.get("ok", false)) and bool(raised_stat.get("changed", false)), "Team editor plus spends a free point")

	menu.call("request_new_start_roster")
	menu.call("confirm_new_start_roster")
	var archived_snapshot: Dictionary = Dictionary(menu.call("get_team_library_snapshot"))
	var archive_path: String = _find_first_archive_path(Array(archived_snapshot.get("entries", [])))
	_assert(int(archived_snapshot.get("entry_count", 0)) >= 2, "Created team list includes archived generated teams")
	_assert(not archive_path.is_empty(), "Created team list exposes an archived team entry")
	_assert(bool(archived_snapshot.get("selected_is_active", false)), "Newest generated team remains the active selection")

	menu.call("select_team_library_entry_for_tests", archive_path)
	var selected_archive_snapshot: Dictionary = Dictionary(menu.call("get_team_library_snapshot"))
	_assert(not bool(selected_archive_snapshot.get("selected_is_active", true)), "Archived team can be selected in the list")
	_assert(bool(selected_archive_snapshot.get("activate_enabled", false)), "Archived team can be activated")
	_assert(bool(selected_archive_snapshot.get("delete_enabled", false)), "Delete is enabled for an archived team")
	var selected_archive_name: String = String(selected_archive_snapshot.get("selected_team_name", ""))
	var activate_result: Dictionary = Dictionary(menu.call("activate_selected_team_entry_for_tests"))
	var after_activate_snapshot: Dictionary = Dictionary(menu.call("get_team_library_snapshot"))
	_assert(bool(activate_result.get("ok", false)), "Archived team activation succeeds")
	_assert(String(after_activate_snapshot.get("active_team_name", "")) == selected_archive_name, "Activated archive becomes the active team")
	var delete_path: String = _find_first_archive_path(Array(after_activate_snapshot.get("entries", [])))
	menu.call("select_team_library_entry_for_tests", delete_path)
	var before_delete_snapshot: Dictionary = Dictionary(menu.call("get_team_library_snapshot"))
	var delete_result: Dictionary = Dictionary(menu.call("delete_selected_team_entry_for_tests"))
	var after_delete_snapshot: Dictionary = Dictionary(menu.call("get_team_library_snapshot"))
	_assert(bool(delete_result.get("ok", false)), "Archived team delete succeeds")
	_assert(int(after_delete_snapshot.get("entry_count", 0)) == int(before_delete_snapshot.get("entry_count", 0)) - 1, "Deleted archived team disappears from the list")
	_assert(bool(after_delete_snapshot.get("selected_is_active", false)), "Selection returns to the active team after archive deletion")
	menu.queue_free()
	await process_frame


func _test_character_sheet_edit_controls_and_last_loadout_dropdowns() -> void:
	var roster: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", "bugfix_character_overlay_edit", 24))
	var unit: Dictionary = Dictionary(Array(roster.get("units", []))[0]).duplicate(true)
	unit["armor_id"] = "heavy"
	unit["weapon_1_id"] = "rocket_launcher"
	unit["weapon_2_id"] = "none"
	var profile = META_UNIT_PROFILE_SCRIPT.new(unit)
	var host := VBoxContainer.new()
	root.add_child(host)
	CHARACTER_SHEET_VIEW_SCRIPT.call("render", host, profile)
	await process_frame
	var plus_button := host.find_child("MetricPlus_accuracy", true, false) as Button
	var value_label := host.find_child("MetricValueLabel_accuracy", true, false) as Label
	var old_accuracy: float = float(Dictionary(profile.skill_values).get("accuracy", 0.0))
	_assert(plus_button != null and value_label != null, "Character sheet renders plus/minus metric controls")
	_assert(value_label != null and value_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_LEFT, "Metric value is left aligned inside the bar")
	if plus_button != null:
		plus_button.emit_signal("pressed")
		await process_frame
	_assert(float(Dictionary(profile.skill_values).get("accuracy", 0.0)) >= old_accuracy, "Plus button updates the profile metric in-place")
	var weapon_1_select := host.find_child("Weapon1LastSelect", true, false) as OptionButton
	var weapon_1_preview := host.find_child("Weapon1LastPreview", true, false) as TextureRect
	var weapon_2_select := host.find_child("Weapon2LastSelect", true, false) as OptionButton
	_assert(weapon_1_select != null and _selected_metadata_id(weapon_1_select) == "rocket_launcher", "Last weapon dropdown selects the current primary weapon")
	_assert(weapon_1_preview != null and weapon_1_preview.texture != null, "Last weapon dropdown shows a weapon image")
	_assert(weapon_1_select != null and _has_disabled_nonselected_item(weapon_1_select), "Unavailable weapon choices are greyed out")
	_assert(weapon_2_select != null and _selected_metadata_id(weapon_2_select) == "none", "Empty last weapon slot remains explicit")
	host.queue_free()
	await process_frame


func _find_first_archive_path(entries: Array) -> String:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if bool(entry.get("archived", false)):
			return String(entry.get("path", ""))
	return ""


func _selected_metadata_id(option_button: OptionButton) -> String:
	if option_button == null:
		return ""
	var selected_index: int = option_button.selected
	if selected_index < 0 or selected_index >= option_button.item_count:
		return ""
	return String(option_button.get_item_metadata(selected_index))


func _has_disabled_nonselected_item(option_button: OptionButton) -> bool:
	if option_button == null:
		return false
	var selected_index: int = option_button.selected
	for index in range(option_button.item_count):
		if index == selected_index:
			continue
		if option_button.is_item_disabled(index):
			return true
	return false


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
