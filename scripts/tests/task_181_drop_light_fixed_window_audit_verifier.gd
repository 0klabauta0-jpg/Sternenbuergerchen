extends SceneTree

const FOB_TEST_SCENE: PackedScene = preload("res://scenes/meta/fob_test_screen.tscn")
const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/drop_light_layout_contract.gd")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_181 Drop Light Fixed Window Audit Verifier ===")
	await _test_fob_windows_are_actual_fixed_rects()
	await _test_homebase_windows_are_actual_fixed_rects()
	await _test_mission_hud_windows_are_actual_fixed_rects()
	_test_no_new_ui_gameplay_truth_paths()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_181: FAILED")
		quit(1)
	else:
		print("TASK_181: ALL PASSED")
		quit(0)


func _test_fob_windows_are_actual_fixed_rects() -> void:
	root.size = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT")
	var screen: Control = FOB_TEST_SCENE.instantiate()
	screen.visible = true
	root.add_child(screen)
	await _wait_frames(4)

	# Preparation screens now own responsive R2 rectangles; mission keeps its
	# shared HUD contract. Retain strict actual geometry and function checks.
	var layout: Dictionary = screen.call("get_native_r2_layout_snapshot")
	_assert_fixed_windows(
		screen,
		layout,
		{
			"topbar": "Panel/Margin/VBox/MissionPanel",
			"unassigned_pool": "Panel/Margin/VBox/ContentRow/AvailablePanel",
			"fireteams": "Panel/Margin/VBox/ContentRow/FireteamPanel",
			"loadout": "Panel/Margin/VBox/ContentRow/StagingPanel",
			"flightdeck": "Panel/Margin/VBox/ContentRow/DropshipPanel",
			"boarding_status": "Panel/Margin/VBox/DropLightBottomRow/BoardingStatusPanel",
			"actions": "Panel/Margin/VBox/DropLightBottomRow/ActionsPanel",
		},
		"FOB"
	)
	_assert_inside(screen, "Panel/Margin/VBox/ContentRow/AvailablePanel", "Panel/Margin/VBox/ContentRow/AvailablePanel/AvailableMargin/AvailableVBox/AvailableScroll", "FOB NPC pool scroll stays inside the fixed #09 window")
	_assert_inside(screen, "Panel/Margin/VBox/ContentRow/FireteamPanel", "Panel/Margin/VBox/ContentRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamScroll", "FOB Fireteam scroll stays inside the fixed #10 window")
	_assert_inside(screen, "Panel/Margin/VBox/ContentRow/StagingPanel", "Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin", "FOB full staging scroll stays inside the bounded #13 window")
	var loadout_scroll := screen.get_node_or_null("Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/LoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutMemberScroll") as ScrollContainer
	_assert(loadout_scroll != null and loadout_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "FOB per-member loadout retains native vertical scrolling")
	_assert_inside(screen, "Panel/Margin/VBox/ContentRow/DropshipPanel", "Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipQueueScroll", "FOB Flightdeck ship list stays inside the fixed #14 window")
	_assert_fob_bottom_actions_do_not_expose_fake_active_buttons(screen)

	screen.queue_free()
	await _wait_frames(2)


func _test_homebase_windows_are_actual_fixed_rects() -> void:
	root.size = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT")
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	screen.visible = true
	root.add_child(screen)
	screen.call("setup_roster", UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster"))
	await _wait_frames(4)

	var layout: Dictionary = screen.call("get_native_r2_layout_snapshot")
	_assert_fixed_windows(
		screen,
		layout,
		{
			"topbar": "DropLightTopbar",
			"mission_brief": "Panel/Margin/VBox/MissionPanel",
			"roster": "Panel/Margin/VBox/ContentRow/RosterPanel",
			"fireteams": "Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel",
			"flightdeck": "Panel/Margin/VBox/ContentRow/AircraftPanel",
			"character_popup": "CharacterSheetPopup",
		},
		"Homebase"
	)
	_assert_inside(screen, "Panel/Margin/VBox/ContentRow/RosterPanel", "Panel/Margin/VBox/ContentRow/RosterPanel/RosterMargin/RosterVBox/RosterScroll", "Homebase roster scroll stays inside the fixed #02 window")
	_assert_inside(screen, "Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel", "Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel/FireteamMargin/FireteamVBox/FireteamScroll", "Homebase fireteam scroll stays inside the active fixed window")
	_assert_inside(screen, "Panel/Margin/VBox/ContentRow/AircraftPanel", "Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/ShipCardsScroll", "Homebase flightdeck shipcards stay inside the fixed #05 window")
	var legacy_team_panel := screen.get_node_or_null("Panel/Margin/VBox/ContentRow/TeamPanel") as Control
	var legacy_info_panel := screen.get_node_or_null("Panel/Margin/VBox/ContentRow/InfoPanel") as Control
	var popup := screen.get_node_or_null("CharacterSheetPopup") as Control
	_assert(legacy_team_panel != null and not legacy_team_panel.visible and bool(legacy_team_panel.get_meta("homebase_legacy_transfer_window_disabled", false)), "Homebase retired transfer window stays disabled")
	_assert(legacy_info_panel != null and not legacy_info_panel.visible and bool(legacy_info_panel.get_meta("homebase_legacy_character_sheet_window_disabled", false)), "Homebase retired character-sheet window stays disabled")
	_assert(popup != null and not popup.visible, "Homebase character popup starts closed")

	# Use the existing card-open path and allow visible containers to lay out
	# before checking the current sheet scroll, rather than hidden legacy nodes.
	screen.call("_on_compact_card_open_requested", "unit_alpha", null, "roster")
	await _wait_frames(3)
	var popup_scroll := screen.get_node_or_null("CharacterSheetPopup/PopupPanel/PopupMargin/PopupVBox/CharacterDetailsColumns/PopupScroll") as ScrollContainer
	_assert(popup != null and popup.is_visible_in_tree() and popup_scroll != null and popup_scroll.is_visible_in_tree(), "Homebase card-open request shows the actual character popup and scroll")
	_assert_inside(screen, "CharacterSheetPopup", "CharacterSheetPopup/PopupPanel/PopupMargin/PopupVBox/CharacterDetailsColumns/PopupScroll", "Homebase visible character scroll stays inside the current popup")
	screen.call("_on_close_sheet_button_pressed")
	await _wait_frames(2)
	_assert(popup != null and not popup.visible, "Homebase character popup closes through its existing callback")

	screen.queue_free()
	await _wait_frames(2)


func _test_mission_hud_windows_are_actual_fixed_rects() -> void:
	root.size = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT")
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(4)

	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_mission_hud_layout")
	_assert_fixed_windows(
		scene,
		layout,
		{
			"mission_identity": "TacticalUI/MissionIdentityPanel",
			"top_nav": "TacticalUI/TopNavPanel",
			"fireteam_mini": "TacticalUI/FireteamMiniPanel",
			"command_matrix": "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel",
			"selected_fireteam": "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel",
			"mission_control": "TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel",
		},
		"Mission HUD"
	)
	_assert_inside(scene, "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel", "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll", "Mission command scroll stays inside the fixed #16 window")
	_assert_inside(scene, "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel", "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamInfoScroll", "Mission fireteam status scroll stays inside the fixed #17 window")
	var members := scene.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll") as Control
	var band := scene.get_node_or_null("TacticalUI/BottomDock") as Control
	_assert(members != null and band != null and members.get_global_rect().end.y <= band.get_global_rect().position.y, "Mission member cards remain above the compact A5 band")
	_assert_inside(scene, "TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel", "TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll", "Mission control scroll stays inside the fixed #18 window")

	var phase_panel := scene.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel") as Control
	_assert(phase_panel != null and not phase_panel.visible, "Mission HUD keeps disabled phase-template controls hidden")

	scene.queue_free()
	await _wait_frames(2)


func _test_no_new_ui_gameplay_truth_paths() -> void:
	for file_path in [
		"res://scripts/meta/fob_screen.gd",
		"res://scripts/meta/homebase_screen.gd",
	]:
		var text := _read_text_file(file_path)
		_assert(not text.contains("SimulationRoot") and not text.contains("enqueue_command") and not text.contains("enqueue_effect"), "%s does not introduce UI-owned SimulationRoot truth" % file_path)
	for file_path in [
		"res://scripts/terrain/terrain_map_3d_view.gd",
		"res://scripts/core/simulation_root.gd",
		"res://scripts/terrain/terrain_pathfinder.gd",
		"res://scripts/terrain/hpa_pathfinder.gd",
	]:
		var text := _read_text_file(file_path)
		_assert(not text.contains("drop_light") and not text.contains("DropLight"), "%s remains outside the drop_light fixed-window audit patch" % file_path)


func _assert_fixed_windows(root_node: Node, layout: Dictionary, path_by_key: Dictionary, screen_name: String) -> void:
	for key_variant in path_by_key.keys():
		var key := String(key_variant)
		var path := String(path_by_key[key_variant])
		var control := root_node.get_node_or_null(path) as Control
		_assert(_node_rect_matches_actual(control, layout.get(key)), "%s %s uses actual fixed position and size" % [screen_name, key])


func _assert_inside(root_node: Node, parent_path: String, child_path: String, message: String) -> void:
	var parent := root_node.get_node_or_null(parent_path) as Control
	var child := root_node.get_node_or_null(child_path) as Control
	_assert(_control_inside(child, parent), message)


func _assert_fob_bottom_actions_do_not_expose_fake_active_buttons(screen: Control) -> void:
	var action_grid := screen.get_node_or_null("Panel/Margin/VBox/DropLightBottomRow/ActionsPanel/Margin/VBox/ActionGrid") as GridContainer
	_assert(action_grid != null, "FOB bottom action grid exists for fake-action audit")
	if action_grid == null:
		return
	for fake_name in ["UnboardButton", "HoldButton", "CargoButton", "MedbayLaterButton"]:
		var button := action_grid.get_node_or_null(fake_name) as Button
		_assert(button != null and button.visible and button.disabled, "FOB %s is visible only as a disabled template action" % fake_name)
	for real_name in ["BoardButton", "SendButton"]:
		var button := action_grid.get_node_or_null(real_name) as Button
		_assert(button != null and button.pressed.get_connections().size() > 0, "FOB %s keeps an existing callback path" % real_name)


func _node_rect_matches_actual(control: Control, rect_variant: Variant) -> bool:
	if control == null or typeof(rect_variant) != TYPE_RECT2I:
		return false
	var rect: Rect2i = rect_variant
	var matches := _approximately_equal(control.global_position.x, float(rect.position.x)) \
		and _approximately_equal(control.global_position.y, float(rect.position.y)) \
		and _approximately_equal(control.size.x, float(rect.size.x)) \
		and _approximately_equal(control.size.y, float(rect.size.y))
	if not matches:
		print("  RECT MISMATCH %s actual pos=%s size=%s expected pos=%s size=%s" % [
			control.name,
			control.global_position,
			control.size,
			rect.position,
			rect.size,
		])
	return matches


func _control_inside(child: Control, parent: Control) -> bool:
	if child == null or parent == null:
		return false
	var parent_rect := Rect2(parent.global_position, parent.size)
	var child_rect := Rect2(child.global_position, child.size)
	var tolerance := 0.5
	var inside := child_rect.position.x >= parent_rect.position.x - tolerance \
		and child_rect.position.y >= parent_rect.position.y - tolerance \
		and child_rect.end.x <= parent_rect.end.x + tolerance \
		and child_rect.end.y <= parent_rect.end.y + tolerance
	if not inside:
		print("  INNER RECT MISMATCH child=%s pos=%s size=%s parent=%s pos=%s size=%s" % [
			child.name,
			child.global_position,
			child.size,
			parent.name,
			parent.global_position,
			parent.size,
		])
	return inside


func _approximately_equal(a: float, b: float) -> bool:
	return absf(a - b) <= 0.5


func _read_text_file(file_path: String) -> String:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		print("  FAIL: %s" % message)
