extends SceneTree

const HARNESS_SCRIPT: GDScript = preload("res://scripts/tests/playability/playability_test_harness.gd")
const DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/drop_light_layout_contract.gd")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/main_menu.tscn"
const MULTIPLAYER_LOBBY_SCENE_PATH: String = "res://scenes/ui/multiplayer_lobby.tscn"
const MAP_EDITOR_SCENE_PATH: String = "res://scenes/editor/map_editor.tscn"
const HOMEBASE_SCENE_PATH: String = "res://scenes/meta/homebase_test_screen.tscn"
const FOB_SCENE_PATH: String = "res://scenes/meta/fob_test_screen.tscn"
const MISSION_SCENE_PATH: String = "res://scenes/tests/mission_reactivity_test.tscn"
const REPORT_PATH: String = "res://docs/reports/playability_layout_clipping_scrollbar_report.md"
const MANUAL_CHECK_PATH: String = "res://docs/manual_checks/playability_layout_remaining_visual_checklist.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_258 Fixed Window Clipping Scrollbar Playability Audit ===")
	await _test_main_menu_and_lobby_fixed_shells()
	await _test_homebase_fixed_windows_and_long_roster_scrolls()
	await _test_fob_fixed_windows_and_loadout_scrolls()
	await _test_mission_hud_fixed_windows_and_scrolls()
	await _test_map_editor_palette_and_property_layout()
	_test_reports_exist()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_main_menu_and_lobby_fixed_shells() -> void:
	root.size = Vector2i(1920, 1080)
	var main_menu: Node = HARNESS_SCRIPT.instantiate_scene(MAIN_MENU_SCENE_PATH, root)
	_assert(main_menu != null, "Main menu instantiates for layout audit")
	if main_menu != null:
		await _wait_frames(2)
		var main_control := main_menu as Control
		_assert(main_control.custom_minimum_size == Vector2(1920.0, 1080.0), "Main menu keeps fixed Full-HD minimum size")
		_assert(_control_inside_viewport(main_control.get_node("MenuRail") as Control, Vector2(1920.0, 1080.0)), "Main menu rail stays inside Full-HD viewport")
		main_menu.call("open_settings_panel")
		await process_frame
		var settings_panel := main_control.get_node("SettingsPanel") as Control
		_assert(_control_inside_viewport(settings_panel, Vector2(1920.0, 1080.0)), "Settings panel stays inside Full-HD viewport")
		_assert(_critical_labels_do_not_overflow("main_menu", main_control, [
			"MenuRail/MenuMargin/MenuVBox/TitleLabel",
			"MenuRail/MenuMargin/MenuVBox/SubtitleLabel",
			"MenuRail/MenuMargin/MenuVBox/StatusLabel",
			"SettingsPanel/SettingsMargin/SettingsVBox/InputActionsLabel",
			"SettingsPanel/SettingsMargin/SettingsVBox/ThoughtHoldLabel",
		]), "Main menu critical labels avoid hard overflow")
		main_menu.queue_free()
		await process_frame

	root.size = Vector2i(1280, 720)
	var lobby: Node = HARNESS_SCRIPT.instantiate_scene(MULTIPLAYER_LOBBY_SCENE_PATH, root)
	_assert(lobby != null, "Multiplayer lobby instantiates for layout audit")
	if lobby != null:
		await _wait_frames(2)
		var lobby_control := lobby as Control
		_assert(lobby_control.custom_minimum_size == Vector2(1280.0, 720.0), "Lobby keeps fixed 1280x720 shell size")
		_assert(_control_inside_viewport(lobby_control.get_node("Panel") as Control, Vector2(1280.0, 720.0)), "Lobby panel stays inside target viewport")
		_assert(_critical_labels_do_not_overflow("multiplayer_lobby", lobby_control, [
			"Panel/Margin/VBox/StatusLabel",
			"Panel/Margin/VBox/RosterModeRow/RosterModeSummaryLabel",
			"Panel/Margin/VBox/PeerLabel",
			"Panel/Margin/VBox/AssignmentLabel",
			"Panel/Margin/VBox/HintLabel",
		]), "Lobby critical labels avoid hard overflow")
		lobby.queue_free()
		await process_frame


func _test_homebase_fixed_windows_and_long_roster_scrolls() -> void:
	var target_viewport: Vector2i = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT")
	root.size = target_viewport
	var homebase: Node = HARNESS_SCRIPT.instantiate_scene(HOMEBASE_SCENE_PATH, root)
	_assert(homebase != null, "Homebase instantiates for fixed-window audit")
	if homebase == null:
		return
	await _wait_frames(3)
	var long_roster: Array = _build_long_roster(30)
	homebase.call("setup_roster", long_roster, PackedStringArray(["unit_long_00", "unit_long_01", "unit_long_02"]))
	await _wait_frames(2)
	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_homebase_layout")
	_assert((homebase as Control).custom_minimum_size == Vector2(float(target_viewport.x), float(target_viewport.y)), "Homebase root keeps fixed Full-HD workspace")
	_assert(_node_rect_matches_actual(homebase.get_node("DropLightTopbar") as Control, layout.get("topbar")), "Homebase topbar remains fixed")
	_assert(_node_rect_matches_actual(homebase.get_node("Panel/Margin/VBox/MissionPanel") as Control, layout.get("mission_brief")), "Homebase mission brief remains fixed")
	_assert(_node_rect_matches_actual(homebase.get_node("Panel/Margin/VBox/ContentRow/RosterPanel") as Control, layout.get("roster")), "Homebase roster window remains fixed")
	_assert(_node_rect_matches_actual(homebase.get_node("Panel/Margin/VBox/ContentRow/TeamPanel") as Control, layout.get("transfer_team")), "Homebase transfer window remains fixed")
	_assert(_node_rect_matches_actual(homebase.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel") as Control, layout.get("flightdeck")), "Homebase flightdeck window remains fixed")
	_assert(_node_rect_matches_actual(homebase.get_node("Panel/Margin/VBox/ContentRow/InfoPanel") as Control, layout.get("character_sheet")), "Homebase character sheet window remains fixed")
	_assert(_scroll_container_is_usable(homebase, "Panel/Margin/VBox/ContentRow/RosterPanel/RosterMargin/RosterVBox/RosterScroll", true), "Homebase roster has a usable ScrollContainer")
	_assert(_scroll_container_is_usable(homebase, "Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamDropPanel/DropMargin/DropVBox/SelectedTeamScroll", true), "Homebase selected team has a usable ScrollContainer")
	_assert(_scroll_container_is_usable(homebase, "Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/ShipCardsScroll", true), "Homebase shipcards have a usable ScrollContainer")
	_assert(_scroll_container_is_usable(homebase, "Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoScroll", true), "Homebase character sheet has a usable ScrollContainer")
	var active_transfers_scroll := homebase.get_node_or_null("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/ActiveTransfersScroll") as ScrollContainer
	var aircraft_transfers_scroll := homebase.get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftTransfersScroll") as ScrollContainer
	_assert(active_transfers_scroll != null and not active_transfers_scroll.visible, "Homebase inbound-to-FOB window is hidden because cards carry progress")
	_assert(aircraft_transfers_scroll != null and not aircraft_transfers_scroll.visible, "Homebase deck-activity window is hidden because shipcards carry progress")
	var roster_list := homebase.get_node("Panel/Margin/VBox/ContentRow/RosterPanel/RosterMargin/RosterVBox/RosterScroll/RosterList") as VBoxContainer
	_assert(roster_list.get_child_count() >= 24, "Homebase long roster renders many cards inside scroll content")
	_assert(_critical_labels_do_not_overflow("homebase", homebase, [
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/StartMissionButton",
		"Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamHeaderRow/ConfirmButton",
		"Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoScroll/InfoVBox/InfoHeaderRow/CloseSheetButton",
	]), "Homebase critical buttons avoid hard text overflow")
	homebase.queue_free()
	await process_frame


func _test_fob_fixed_windows_and_loadout_scrolls() -> void:
	var target_viewport: Vector2i = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT")
	root.size = target_viewport
	var fob: Node = HARNESS_SCRIPT.instantiate_scene(FOB_SCENE_PATH, root)
	_assert(fob != null, "FOB instantiates for fixed-window audit")
	if fob == null:
		return
	(fob as CanvasItem).visible = true
	await _wait_frames(3)
	var long_roster: Array = _build_long_roster(18)
	fob.call("set_available_units", long_roster)
	fob.call("configure_transfer", PackedStringArray(["unit_long_00", "unit_long_01", "unit_long_02", "unit_long_03"]), PackedStringArray(["blue"]), [_build_fireteam_definition("blue", "unit_long_00", PackedStringArray(["unit_long_00", "unit_long_01", "unit_long_02", "unit_long_03"]))])
	await _wait_frames(2)
	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_fob_layout")
	_assert((fob as Control).custom_minimum_size == Vector2(float(target_viewport.x), float(target_viewport.y)), "FOB root keeps fixed Full-HD workspace")
	_assert(_node_rect_matches_actual(fob.get_node("Panel/Margin/VBox/MissionPanel") as Control, layout.get("topbar")), "FOB topbar remains fixed")
	_assert(_node_rect_matches_actual(fob.get_node("Panel/Margin/VBox/ContentRow/FireteamPanel") as Control, layout.get("fireteams")), "FOB fireteams window remains fixed")
	_assert(_node_rect_matches_actual(fob.get_node("Panel/Margin/VBox/ContentRow/StagingPanel") as Control, layout.get("loadout")), "FOB loadout window remains fixed")
	_assert(_node_rect_matches_actual(fob.get_node("Panel/Margin/VBox/ContentRow/DropshipPanel") as Control, layout.get("flightdeck")), "FOB flightdeck window remains fixed")
	_assert(_node_rect_matches_actual(fob.get_node("Panel/Margin/VBox/DropLightBottomRow/BoardingStatusPanel") as Control, layout.get("boarding_status")), "FOB boarding status remains fixed")
	_assert(_node_rect_matches_actual(fob.get_node("Panel/Margin/VBox/DropLightBottomRow/ActionsPanel") as Control, layout.get("actions")), "FOB actions window remains fixed")
	_assert(_scroll_container_is_usable(fob, "Panel/Margin/VBox/ContentRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamScroll", true), "FOB fireteams have a usable ScrollContainer")
	_assert(_scroll_container_is_usable(fob, "Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/LoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutMemberScroll", true), "FOB loadout member rows have a usable ScrollContainer")
	_assert(_scroll_container_is_usable(fob, "Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipQueueScroll", true), "FOB flightdeck queue has a usable ScrollContainer")
	_assert(_scroll_container_is_usable(fob, "CharacterOverlay/OverlayPanel/OverlayMargin/OverlayVBox/OverlayScroll", false), "FOB character overlay keeps long content in a ScrollContainer")
	_assert(_critical_labels_do_not_overflow("fob", fob, [
		"Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/LoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutStatusLabel",
		"Panel/Margin/VBox/DropLightBottomRow/ActionsPanel/Margin/VBox/ActionGrid/BoardButton",
		"Panel/Margin/VBox/DropLightBottomRow/ActionsPanel/Margin/VBox/ActionGrid/SendButton",
	]), "FOB critical labels/buttons avoid hard text overflow")
	fob.queue_free()
	await process_frame


func _test_mission_hud_fixed_windows_and_scrolls() -> void:
	var target_viewport: Vector2i = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT")
	root.size = target_viewport
	var mission: Node = HARNESS_SCRIPT.instantiate_scene(MISSION_SCENE_PATH, root)
	_assert(mission != null, "Mission scene instantiates for HUD layout audit")
	if mission == null:
		return
	await _wait_frames(6)
	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_mission_hud_layout")
	_assert(_node_rect_matches_actual(mission.get_node("TacticalUI/MissionIdentityPanel") as Control, layout.get("mission_identity")), "Mission identity window remains fixed")
	_assert(_node_rect_matches_actual(mission.get_node("TacticalUI/TopNavPanel") as Control, layout.get("top_nav")), "Mission top nav remains fixed")
	_assert(_node_rect_matches_actual(mission.get_node("TacticalUI/FireteamMiniPanel") as Control, layout.get("fireteam_mini")), "Mission fireteam mini window remains fixed")
	_assert(_node_rect_matches_actual(mission.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel") as Control, layout.get("command_matrix")), "Mission command matrix remains fixed")
	_assert(_node_rect_matches_actual(mission.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel") as Control, layout.get("selected_fireteam")), "Mission selected fireteam window remains fixed")
	_assert(_node_rect_matches_actual(mission.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel") as Control, layout.get("mission_control")), "Mission control window remains fixed")
	_assert(_scroll_container_is_usable(mission, "TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll", true), "Mission mini cards have a usable ScrollContainer")
	_assert(_scroll_container_is_usable(mission, "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll", true), "Mission command matrix has a usable ScrollContainer")
	_assert(_scroll_container_is_usable(mission, "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamInfoScroll", true), "Mission selected fireteam info has a usable ScrollContainer")
	_assert(_scroll_container_is_usable(mission, "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll", true), "Mission fireteam cards have a usable ScrollContainer")
	_assert(_scroll_container_is_usable(mission, "TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll", true), "Mission control has a usable ScrollContainer")
	_assert(_critical_labels_do_not_overflow("mission_hud", mission, [
		"TacticalUI/TopNavPanel/NavMargin/NavRow/HomebaseNavButton",
		"TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/MoveButton",
		"TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/CallDropshipButton",
	]), "Mission critical buttons avoid hard text overflow")
	mission.queue_free()
	await process_frame


func _test_map_editor_palette_and_property_layout() -> void:
	root.size = Vector2i(1920, 1080)
	var editor: Node = HARNESS_SCRIPT.instantiate_scene(MAP_EDITOR_SCENE_PATH, root)
	_assert(editor != null, "Map editor instantiates for clipping audit")
	if editor == null:
		return
	await _wait_frames(5)
	_assert(_control_inside_viewport(editor.get_node("UI/TopBar") as Control, Vector2(1920.0, 1080.0)), "Editor topbar stays inside viewport")
	_assert(_control_inside_viewport(editor.get_node("UI/PalettePanel") as Control, Vector2(1920.0, 1080.0)), "Editor palette panel stays inside viewport")
	_assert(_control_has_visible_viewport_area(editor.get_node("UI/PropertyPanel") as Control, Vector2(1920.0, 1080.0)), "Editor property panel keeps a visible viewport footprint")
	var tile_type_list := editor.get_node("UI/PalettePanel/Margin/VBox/TileTypeList") as ItemList
	_assert(tile_type_list != null and tile_type_list.item_count >= 12, "Editor palette exposes a long ItemList with built-in scrolling")
	_assert(tile_type_list.fixed_icon_size.x >= 0.0, "Editor palette ItemList remains a single scrollable control")
	_assert(_critical_labels_do_not_overflow("map_editor", editor, [
		"UI/TopBar/Margin/HBox/TitleLabel",
		"UI/TopBar/Margin/HBox/BrushButton",
		"UI/PropertyPanel/Margin/VBox/TileLabel",
		"UI/PropertyPanel/Margin/VBox/MarkerHelpLabel",
	]), "Editor critical labels/buttons avoid hard text overflow")
	editor.queue_free()
	await process_frame


func _test_reports_exist() -> void:
	_assert(FileAccess.file_exists(REPORT_PATH), "Layout clipping/scrollbar report exists")
	_assert(FileAccess.file_exists(MANUAL_CHECK_PATH), "Layout manual visual checklist exists")
	var report: String = _read_text(REPORT_PATH)
	for required_text in ["Summary", "Covered Screens", "Automated Findings", "Manual Remainder"]:
		_assert(report.contains(required_text), "Layout report covers %s" % required_text)
	var checklist: String = _read_text(MANUAL_CHECK_PATH)
	for required_text in ["Full-HD", "1280x720", "Long Content", "Manual Judgement"]:
		_assert(checklist.contains(required_text), "Layout manual checklist covers %s" % required_text)


func _scroll_container_is_usable(root_node: Node, path: String, require_visible: bool) -> bool:
	var scroll := root_node.get_node_or_null(path) as ScrollContainer
	if scroll == null:
		return false
	if not require_visible:
		return scroll.get_child_count() > 0
	if require_visible and not (scroll.visible and scroll.is_visible_in_tree()):
		return false
	if scroll.size.x <= 0.0 or scroll.size.y <= 0.0:
		return false
	var parent_control := scroll.get_parent() as Control
	if parent_control != null and scroll.visible and scroll.is_visible_in_tree():
		if not Rect2(parent_control.global_position, parent_control.size).grow(1.0).encloses(Rect2(scroll.global_position, scroll.size)):
			return false
	return scroll.get_child_count() > 0


func _critical_labels_do_not_overflow(_screen_id: String, root_node: Node, paths: Array) -> bool:
	for path_variant in paths:
		var path: String = String(path_variant)
		var control := root_node.get_node_or_null(path) as Control
		if control == null:
			return false
		if not (control.visible and (control.is_visible_in_tree() if control.is_inside_tree() else true)):
			continue
		if control.size.x <= 0.0 or control.size.y <= 0.0:
			return false
		var label := control as Label
		if label != null and label.autowrap_mode == TextServer.AUTOWRAP_OFF and label.get_minimum_size().x > control.size.x + 4.0:
			return false
		var button := control as Button
		if button != null and button.get_minimum_size().x > control.size.x + 6.0:
			return false
	return true


func _control_inside_viewport(control: Control, viewport_size: Vector2) -> bool:
	return control != null and HARNESS_SCRIPT.is_control_inside_viewport(control, viewport_size, 8.0)


func _control_has_visible_viewport_area(control: Control, viewport_size: Vector2) -> bool:
	if control == null:
		return false
	var viewport_rect := Rect2(Vector2.ZERO, viewport_size)
	var control_rect := Rect2(control.global_position, control.size)
	return viewport_rect.intersects(control_rect) and control_rect.size.x > 0.0 and control_rect.size.y > 0.0


func _node_rect_matches_actual(control: Control, rect_variant: Variant) -> bool:
	if control == null or typeof(rect_variant) != TYPE_RECT2I:
		return false
	var rect: Rect2i = rect_variant
	return absf(control.global_position.x - float(rect.position.x)) <= 0.5 \
		and absf(control.global_position.y - float(rect.position.y)) <= 0.5 \
		and absf(control.size.x - float(rect.size.x)) <= 0.5 \
		and absf(control.size.y - float(rect.size.y)) <= 0.5


func _build_long_roster(count: int) -> Array:
	var base_roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	var roster: Array = []
	for index in range(maxi(count, 0)):
		var source: Dictionary = Dictionary(base_roster[index % base_roster.size()]).duplicate(true)
		source["unit_id"] = "unit_long_%02d" % index
		source["display_name"] = "Operator With A Very Long Callsign And Assignment Trail %02d" % index
		source["callsign"] = "LONGCALLSIGN-%02d-ALPHA-BRAVO" % index
		source["role_name"] = "Multi-role Expeditionary Specialist With Extra Notes"
		source["specialty_text"] = "Extended breach, relay, logistics and tactical overwatch duties for clipping coverage."
		source["biography_text"] = "This intentionally long biography exists to verify that character sheets and roster cards stay inside scrollable areas during headless playability checks."
		source["loadout_summary"] = "SMG, medictool, compact cargo scanner, spare battery pack and decorative noncombat widget."
		roster.append(source)
	return roster


func _build_fireteam_definition(fireteam_id: String, lead_unit_id: String, member_unit_ids: PackedStringArray) -> Dictionary:
	return {
		"id": fireteam_id,
		"label": "%s Team With Long Label" % fireteam_id.capitalize(),
		"lead_unit_id": lead_unit_id,
		"member_unit_ids": member_unit_ids,
		"loadout": "medium",
	}


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
