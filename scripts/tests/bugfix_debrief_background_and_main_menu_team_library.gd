extends SceneTree

const DEBRIEF_SCENE: PackedScene = preload("res://scenes/meta/debrief_test_screen.tscn")
const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Bugfix Debrief Background and Main Menu Team Library ===")
	await _test_debrief_uses_catalog_background()
	await _test_main_menu_lists_created_teams_and_deletes_archives()
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
	_assert(bool(selected_archive_snapshot.get("delete_enabled", false)), "Delete is enabled for an archived team")
	var delete_result: Dictionary = Dictionary(menu.call("delete_selected_team_entry_for_tests"))
	var after_delete_snapshot: Dictionary = Dictionary(menu.call("get_team_library_snapshot"))
	_assert(bool(delete_result.get("ok", false)), "Archived team delete succeeds")
	_assert(int(after_delete_snapshot.get("entry_count", 0)) == int(archived_snapshot.get("entry_count", 0)) - 1, "Deleted archived team disappears from the list")
	_assert(bool(after_delete_snapshot.get("selected_is_active", false)), "Selection returns to the active team after archive deletion")
	menu.queue_free()
	await process_frame


func _find_first_archive_path(entries: Array) -> String:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if bool(entry.get("archived", false)):
			return String(entry.get("path", ""))
	return ""


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
