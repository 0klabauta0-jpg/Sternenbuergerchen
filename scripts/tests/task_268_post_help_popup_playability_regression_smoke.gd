extends SceneTree

const HARNESS_SCRIPT: GDScript = preload("res://scripts/tests/playability/playability_test_harness.gd")
const DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/drop_light_layout_contract.gd")
const SERVICE_SCRIPT: GDScript = preload("res://scripts/ui/contextual_help_service.gd")
const POPUP_SCRIPT: GDScript = preload("res://scripts/ui/contextual_help_popup.gd")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/main_menu.tscn"
const MULTIPLAYER_LOBBY_SCENE_PATH: String = "res://scenes/ui/multiplayer_lobby.tscn"
const MAP_EDITOR_SCENE_PATH: String = "res://scenes/editor/map_editor.tscn"
const HOMEBASE_SCENE_PATH: String = "res://scenes/meta/homebase_test_screen.tscn"
const FOB_SCENE_PATH: String = "res://scenes/meta/fob_test_screen.tscn"
const MISSION_SCENE_PATH: String = "res://scenes/tests/mission_reactivity_test.tscn"
const DEBRIEF_SCENE_PATH: String = "res://scenes/meta/debrief_test_screen.tscn"

const CATALOG_PATH: String = "res://data/contextual_help_catalog.json"
const REPORT_PATH: String = "res://docs/reports/post_help_popup_playability_regression_report.md"
const MANUAL_CHECKLIST_PATH: String = "res://docs/manual_checks/post_help_popup_manual_readability_checklist.md"
const TASK_PATH: String = "res://docs/tasks/TASK_268_post_help_popup_playability_regression_smoke.md"
const MATRIX_PATH: String = "res://docs/qa/playability_coverage_matrix.md"

const HELP_MODES: Array = ["off", "compact", "expanded"]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_268 Post Help Popup Playability Regression Smoke ===")
	_test_static_gate_links()
	await _test_main_menu_settings_modes()
	await _test_cross_screen_controls_with_help_modes()
	await _test_fixed_windows_do_not_move_with_popup()
	_test_reports_and_task_status()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_static_gate_links() -> void:
	_assert(FileAccess.file_exists("res://scripts/tests/task_262_playability_regression_gate_and_manual_open_items.gd"), "TASK_262 gate script exists")
	_assert(FileAccess.file_exists("res://scripts/tests/task_267_contextual_help_coverage_layout_verifier.gd"), "TASK_267 help gate script exists")
	_assert(FileAccess.file_exists("res://docs/reports/playability_regression_gate_report.md"), "TASK_262 playability report exists")
	_assert(FileAccess.file_exists("res://docs/reports/contextual_help_coverage_layout_report.md"), "TASK_267 help coverage report exists")


func _test_main_menu_settings_modes() -> void:
	root.size = Vector2i(1920, 1080)
	for mode_variant in HELP_MODES:
		var mode: String = String(mode_variant)
		var menu: Node = HARNESS_SCRIPT.instantiate_scene(MAIN_MENU_SCENE_PATH, root)
		_assert(menu != null, "Main menu instantiates with help mode %s" % mode)
		if menu == null:
			continue
		await _wait_frames(2)
		menu.call("set_contextual_help_mode", mode)
		await process_frame
		var snapshot: Dictionary = Dictionary(menu.call("get_contextual_help_snapshot"))
		var service_snapshot: Dictionary = Dictionary(snapshot.get("service", {}))
		_assert(String(service_snapshot.get("help_mode", "")) == mode, "Main menu service applies %s help mode" % mode)
		var global_button := menu.get_node_or_null("GlobalHelpButton") as Button
		var settings_button := menu.get_node_or_null("MenuRail/MenuMargin/MenuVBox/MenuButtons/SettingsButton") as BaseButton
		_assert(global_button != null and global_button.visible, "Global help button remains visible in %s mode" % mode)
		_assert(settings_button != null and settings_button.visible and not settings_button.disabled, "Settings button remains clickable in %s mode" % mode)
		if global_button != null:
			global_button.pressed.emit()
			await process_frame
			snapshot = Dictionary(menu.call("get_contextual_help_snapshot"))
			var popup_snapshot: Dictionary = Dictionary(snapshot.get("popup", {}))
			if mode == SERVICE_SCRIPT.MODE_OFF:
				_assert(not bool(popup_snapshot.get("visible", false)), "Off mode keeps global popup hidden")
			else:
				_assert(bool(popup_snapshot.get("visible", false)), "%s mode opens global help popup" % mode)
				_assert(String(popup_snapshot.get("help_id", "")) == "shell.global_help_button", "%s mode global popup uses shell ID" % mode)
		var press_result: Dictionary = Dictionary(HARNESS_SCRIPT.press_button_for_test(settings_button))
		await process_frame
		_assert(bool(press_result.get("pressed", false)) and bool(menu.call("is_settings_panel_visible")), "Settings opens while help is %s" % mode)
		_assert(_visible_control_not_blocked(menu, "SettingsPanel/SettingsMargin/SettingsVBox/SettingsActionRow/SettingsApplyButton", Vector2(1920.0, 1080.0)), "Settings Apply remains reachable in %s mode" % mode)
		var back_button := menu.get_node_or_null("SettingsPanel/SettingsMargin/SettingsVBox/SettingsBackButton") as BaseButton
		press_result = Dictionary(HARNESS_SCRIPT.press_button_for_test(back_button))
		await process_frame
		_assert(bool(press_result.get("pressed", false)) and not bool(menu.call("is_settings_panel_visible")), "Settings Back works while help is %s" % mode)
		menu.queue_free()
		await process_frame


func _test_cross_screen_controls_with_help_modes() -> void:
	for mode_variant in HELP_MODES:
		var mode: String = String(mode_variant)
		await _smoke_lobby_controls(mode)
		await _smoke_editor_controls(mode)
		await _smoke_homebase_controls(mode)
		await _smoke_fob_controls(mode)
		await _smoke_mission_controls(mode)
		await _smoke_debrief_controls(mode)


func _smoke_lobby_controls(mode: String) -> void:
	root.size = Vector2i(1280, 720)
	var lobby: Node = HARNESS_SCRIPT.instantiate_scene(MULTIPLAYER_LOBBY_SCENE_PATH, root)
	_assert(lobby != null, "Lobby instantiates with help %s" % mode)
	if lobby == null:
		return
	await _wait_frames(2)
	var host_button := lobby.get_node_or_null("Panel/Margin/VBox/HostJoinGrid/HostButton") as BaseButton
	await _show_help_for_control(lobby, host_button, "multiplayer.host", mode, Vector2(1280.0, 720.0))
	_assert(_button_has_callback_and_reachable(lobby, host_button, Vector2(1280.0, 720.0)), "Lobby Host remains reachable with help %s" % mode)
	var join_button := lobby.get_node_or_null("Panel/Margin/VBox/HostJoinGrid/JoinButton") as BaseButton
	_assert(_button_has_callback_and_reachable(lobby, join_button, Vector2(1280.0, 720.0)), "Lobby Join remains reachable with help %s" % mode)
	lobby.queue_free()
	await process_frame


func _smoke_editor_controls(mode: String) -> void:
	root.size = Vector2i(1920, 1080)
	var editor: Node = HARNESS_SCRIPT.instantiate_scene(MAP_EDITOR_SCENE_PATH, root)
	_assert(editor != null, "Editor instantiates with help %s" % mode)
	if editor == null:
		return
	await _wait_frames(5)
	var brush_button := editor.get_node_or_null("UI/TopBar/Margin/HBox/BrushButton") as BaseButton
	await _show_help_for_control(editor, brush_button, "editor.tile_palette", mode, Vector2(1920.0, 1080.0))
	_assert(_visible_control_not_blocked(editor, "UI/TopBar/Margin/HBox/BrushButton", Vector2(1920.0, 1080.0)), "Editor brush remains reachable with help %s" % mode)
	var height_button := editor.get_node_or_null("UI/TopBar/Margin/HBox/HeightButton") as BaseButton
	_assert(height_button != null and height_button.visible, "Editor height button remains visible with help %s" % mode)
	editor.queue_free()
	await process_frame


func _smoke_homebase_controls(mode: String) -> void:
	var target_viewport: Vector2i = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT")
	root.size = target_viewport
	var homebase: Node = HARNESS_SCRIPT.instantiate_scene(HOMEBASE_SCENE_PATH, root)
	_assert(homebase != null, "Homebase instantiates with help %s" % mode)
	if homebase == null:
		return
	await _wait_frames(4)
	var close_button := homebase.get_node_or_null("Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoScroll/InfoVBox/InfoHeaderRow/CloseSheetButton") as BaseButton
	await _show_help_for_control(homebase, close_button, "character_sheet.core_values", mode, Vector2(target_viewport))
	_assert(_button_has_callback_and_reachable(homebase, close_button, Vector2(target_viewport)), "Homebase character sheet close remains reachable with help %s" % mode)
	var roster_panel := homebase.get_node_or_null("Panel/Margin/VBox/ContentRow/RosterPanel") as Control
	_assert(roster_panel != null and String(roster_panel.get_meta("help_id", "")) == "homebase.roster", "Homebase roster keeps help_id in %s smoke" % mode)
	homebase.queue_free()
	await process_frame


func _smoke_fob_controls(mode: String) -> void:
	var target_viewport: Vector2i = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT")
	root.size = target_viewport
	var fob: Node = HARNESS_SCRIPT.instantiate_scene(FOB_SCENE_PATH, root)
	_assert(fob != null, "FOB instantiates with help %s" % mode)
	if fob == null:
		return
	(fob as CanvasItem).visible = true
	await _wait_frames(3)
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	fob.call("set_available_units", roster)
	fob.call("configure_transfer", PackedStringArray(["unit_alpha", "unit_bravo"]), PackedStringArray(["ft1", "ft1"]), [])
	fob.call("_on_staging_fireteam_dropped", "ft1", "loadout")
	await _wait_frames(3)
	var add_team_button := fob.get_node_or_null("Panel/Margin/VBox/ContentRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamToolbar/AddTeamButton") as BaseButton
	await _show_help_for_control(fob, add_team_button, "fob.fireteams", mode, Vector2(target_viewport))
	_assert(_button_has_callback_and_reachable(fob, add_team_button, Vector2(target_viewport)), "FOB Add Team remains reachable with help %s" % mode)
	_assert(_visible_control_not_blocked(fob, "Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/LoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutStatusLabel", Vector2(target_viewport)), "FOB loadout weight remains readable with help %s" % mode)
	fob.queue_free()
	await process_frame


func _smoke_mission_controls(mode: String) -> void:
	var target_viewport: Vector2i = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT")
	root.size = target_viewport
	var mission: Node = HARNESS_SCRIPT.instantiate_scene(MISSION_SCENE_PATH, root)
	_assert(mission != null, "Mission instantiates with help %s" % mode)
	if mission == null:
		return
	await _wait_frames(6)
	var all_button := mission.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderRow/AllFireteamsButton") as BaseButton
	await _show_help_for_control(mission, all_button, "mission.selected_fireteam", mode, Vector2(target_viewport))
	_assert(_button_has_callback_and_reachable(mission, all_button, Vector2(target_viewport)), "Mission All Fireteams remains reachable with help %s" % mode)
	_assert(_visible_control_not_blocked(mission, "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/MoveButton", Vector2(target_viewport)), "Mission command button remains reachable with help %s" % mode)
	mission.queue_free()
	await process_frame


func _smoke_debrief_controls(mode: String) -> void:
	var target_viewport: Vector2i = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT")
	root.size = target_viewport
	var debrief: Node = HARNESS_SCRIPT.instantiate_scene(DEBRIEF_SCENE_PATH, root)
	_assert(debrief != null, "Debrief instantiates with help %s" % mode)
	if debrief == null:
		return
	(debrief as CanvasItem).visible = true
	await _wait_frames(2)
	debrief.call("set_mission_result", {
		"result": "victory",
		"mission_outcome": "success",
		"winning_team_id": "team_alpha",
		"character_events": [{"summary_text": "Anja gained XP."}],
	})
	await process_frame
	var character_events := debrief.get_node_or_null("Panel/Margin/VBox/CharacterEventsLabel") as Control
	await _show_help_for_control(debrief, character_events, "debrief.character_updates", mode, Vector2(target_viewport))
	_assert(character_events != null and String(character_events.get_meta("help_id", "")) == "debrief.character_updates", "Debrief character updates keep help_id with help %s" % mode)
	_assert(_button_has_callback_and_reachable(debrief, debrief.get_node_or_null("Panel/Margin/VBox/ButtonRow/ReturnToFOBButton") as BaseButton, Vector2(target_viewport)), "Debrief return button remains reachable with help %s" % mode)
	debrief.queue_free()
	await process_frame


func _test_fixed_windows_do_not_move_with_popup() -> void:
	var target_viewport: Vector2i = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT")
	root.size = target_viewport
	await _assert_fixed_screen_stable_with_popup(HOMEBASE_SCENE_PATH, [
		"DropLightTopbar",
		"Panel/Margin/VBox/MissionPanel",
		"Panel/Margin/VBox/ContentRow/RosterPanel",
		"Panel/Margin/VBox/ContentRow/TeamPanel",
		"Panel/Margin/VBox/ContentRow/AircraftPanel",
		"Panel/Margin/VBox/ContentRow/InfoPanel",
	], "homebase.roster")
	await _assert_fixed_screen_stable_with_popup(FOB_SCENE_PATH, [
		"Panel/Margin/VBox/MissionPanel",
		"Panel/Margin/VBox/ContentRow/FireteamPanel",
		"Panel/Margin/VBox/ContentRow/StagingPanel",
		"Panel/Margin/VBox/ContentRow/DropshipPanel",
		"Panel/Margin/VBox/DropLightBottomRow/BoardingStatusPanel",
		"Panel/Margin/VBox/DropLightBottomRow/ActionsPanel",
	], "fob.flightdeck")
	await _assert_fixed_screen_stable_with_popup(MISSION_SCENE_PATH, [
		"TacticalUI/MissionIdentityPanel",
		"TacticalUI/TopNavPanel",
		"TacticalUI/FireteamMiniPanel",
		"TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel",
		"TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel",
		"TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel",
	], "mission.command_matrix")


func _assert_fixed_screen_stable_with_popup(scene_path: String, paths: Array, help_id: String) -> void:
	var screen: Node = HARNESS_SCRIPT.instantiate_scene(scene_path, root)
	_assert(screen != null, "%s instantiates for fixed-window help smoke" % scene_path)
	if screen == null:
		return
	await _wait_frames(6)
	var before: Dictionary = _snapshot_rects(screen, paths)
	var popup: Control = POPUP_SCRIPT.new()
	root.add_child(popup)
	await process_frame
	_assert(popup.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Help popup ignores mouse input for %s" % scene_path)
	var service = SERVICE_SCRIPT.new()
	service.call("load_catalog", CATALOG_PATH)
	service.call("set_help_mode", SERVICE_SCRIPT.MODE_EXPANDED)
	var payload: Dictionary = Dictionary(service.call("request_help", help_id, 4.0, false))
	popup.call("show_help", payload, Rect2(880.0, 520.0, 120.0, 48.0), Vector2(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT")), true)
	await process_frame
	var after: Dictionary = _snapshot_rects(screen, paths)
	_assert(_rect_snapshots_match(before, after), "%s fixed windows do not move while help popup is visible" % scene_path)
	popup.queue_free()
	screen.queue_free()
	await process_frame


func _show_help_for_control(screen: Node, control: Control, help_id: String, mode: String, viewport_size: Vector2) -> void:
	if control == null:
		return
	var popup: Control = POPUP_SCRIPT.new()
	screen.add_child(popup)
	var service = SERVICE_SCRIPT.new()
	service.call("load_catalog", CATALOG_PATH)
	service.call("set_help_mode", mode)
	await process_frame
	var hover_seconds: float = 4.0 if mode == SERVICE_SCRIPT.MODE_EXPANDED else 1.0
	var payload: Dictionary = Dictionary(service.call("request_help", help_id, hover_seconds, false))
	if String(payload.get("level", SERVICE_SCRIPT.LEVEL_NONE)) == SERVICE_SCRIPT.LEVEL_NONE:
		popup.call("hide_help")
		_assert(mode == SERVICE_SCRIPT.MODE_OFF and not popup.visible, "Help popup stays hidden for off mode on %s" % help_id)
		return
	popup.call("show_help", payload, Rect2(control.global_position, control.size), viewport_size, mode == SERVICE_SCRIPT.MODE_EXPANDED)
	var popup_rect := Rect2(popup.position, popup.size)
	_assert(popup.visible, "Help popup appears for %s in %s mode" % [help_id, mode])
	_assert(_rect_inside_viewport(popup_rect, viewport_size), "Help popup for %s stays inside viewport" % help_id)
	_assert(popup.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Help popup cannot intercept input for %s" % help_id)


func _button_has_callback_and_reachable(root_node: Node, button: BaseButton, viewport_size: Vector2) -> bool:
	if button == null or not button.visible or (button.is_inside_tree() and not button.is_visible_in_tree()):
		return false
	if button.disabled:
		return false
	return HARNESS_SCRIPT.has_pressed_callback(button) \
		and HARNESS_SCRIPT.is_control_inside_viewport(button, viewport_size, 1.0) \
		and not HARNESS_SCRIPT.is_control_fully_covered_by_later_control(root_node, button)


func _visible_control_not_blocked(root_node: Node, path: String, viewport_size: Vector2) -> bool:
	var control := root_node.get_node_or_null(path) as Control
	if control == null or not control.visible or (control.is_inside_tree() and not control.is_visible_in_tree()):
		return false
	return HARNESS_SCRIPT.is_control_inside_viewport(control, viewport_size, 1.0) \
		and not HARNESS_SCRIPT.is_control_fully_covered_by_later_control(root_node, control)


func _snapshot_rects(root_node: Node, paths: Array) -> Dictionary:
	var result: Dictionary = {}
	for path_variant in paths:
		var path: String = String(path_variant)
		var control := root_node.get_node_or_null(path) as Control
		if control != null:
			result[path] = Rect2(control.global_position, control.size)
	return result


func _rect_snapshots_match(before: Dictionary, after: Dictionary) -> bool:
	if before.size() != after.size():
		return false
	for path in before.keys():
		if not after.has(path):
			return false
		var a: Rect2 = before.get(path)
		var b: Rect2 = after.get(path)
		if a.position.distance_to(b.position) > 0.5 or a.size.distance_to(b.size) > 0.5:
			return false
	return true


func _rect_inside_viewport(rect: Rect2, viewport_size: Vector2) -> bool:
	return rect.position.x >= 0.0 and rect.position.y >= 0.0 and rect.end.x <= viewport_size.x and rect.end.y <= viewport_size.y


func _test_reports_and_task_status() -> void:
	var report: String = _read_text(REPORT_PATH)
	_assert(not report.is_empty(), "TASK_268 post-help playability report exists")
	for token in ["Summary", "Gate Links", "Help Mode Smoke", "Covered Flows", "Manual Remainder"]:
		_assert(report.contains(token), "Post-help report covers %s" % token)
	var checklist: String = _read_text(MANUAL_CHECKLIST_PATH)
	_assert(not checklist.is_empty(), "TASK_268 manual readability checklist exists")
	for token in ["Popup Readability", "Copy Tone", "Real Monitor Scale", "Not Repeated Here"]:
		_assert(checklist.contains(token), "Manual checklist covers %s" % token)
	_assert(checklist.split("\n").size() <= 60, "Manual checklist stays short")
	var matrix: String = _read_text(MATRIX_PATH)
	_assert(matrix.contains("TASK_268"), "Coverage matrix references TASK_268")
	var task_text: String = _read_text(TASK_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "TASK_268 is marked implemented")
	_assert(not task_text.contains("- [ ]"), "TASK_268 checklist is complete")


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
