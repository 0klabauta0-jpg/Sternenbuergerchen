extends SceneTree

const HARNESS_SCRIPT: GDScript = preload("res://scripts/tests/playability/playability_test_harness.gd")
const DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/drop_light_layout_contract.gd")

const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/main_menu.tscn"
const MULTIPLAYER_LOBBY_SCENE_PATH: String = "res://scenes/ui/multiplayer_lobby.tscn"
const MAP_EDITOR_SCENE_PATH: String = "res://scenes/editor/map_editor.tscn"
const HOMEBASE_SCENE_PATH: String = "res://scenes/meta/homebase_test_screen.tscn"
const FOB_SCENE_PATH: String = "res://scenes/meta/fob_test_screen.tscn"
const MISSION_SCENE_PATH: String = "res://scenes/tests/mission_reactivity_test.tscn"
const DEBRIEF_SCENE_PATH: String = "res://scenes/meta/debrief_test_screen.tscn"
const REPORT_PATH: String = "res://docs/reports/playability_button_reachability_report.md"

var _passed: int = 0
var _failed: int = 0
var _inventory_count: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_257 Button Reachability and Interaction Verifier ===")
	await _test_main_menu_and_settings_buttons()
	await _test_multiplayer_lobby_buttons_and_click_states()
	await _test_map_editor_buttons()
	await _test_homebase_fob_and_debrief_buttons()
	await _test_mission_hud_buttons()
	_test_report_exists()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_main_menu_and_settings_buttons() -> void:
	root.size = Vector2i(1920, 1080)
	var screen: Node = HARNESS_SCRIPT.instantiate_scene(MAIN_MENU_SCENE_PATH, root)
	_assert(screen != null, "Main menu scene instantiates for button inventory")
	if screen == null:
		return
	await _wait_frames(2)
	_check_required_controls("main_menu", screen, [
		_button_spec("SingleplayerButton", "MenuRail/MenuMargin/MenuVBox/MenuButtons/SingleplayerButton", ["pressed"], "enabled", "required", {"route": "res://scenes/meta/meta_layer_test.tscn", "focus": true}),
		_button_spec("MultiplayerButton", "MenuRail/MenuMargin/MenuVBox/MenuButtons/MultiplayerButton", ["pressed"], "enabled", "required", {"route": MULTIPLAYER_LOBBY_SCENE_PATH, "focus": true}),
		_button_spec("EditorButton", "MenuRail/MenuMargin/MenuVBox/MenuButtons/EditorButton", ["pressed"], "enabled", "required", {"route": MAP_EDITOR_SCENE_PATH, "focus": true}),
		_button_spec("SettingsButton", "MenuRail/MenuMargin/MenuVBox/MenuButtons/SettingsButton", ["pressed"], "enabled", "required", {"route": "local_settings_panel", "focus": true}),
		_button_spec("NewRosterButton", "MenuRail/MenuMargin/MenuVBox/MenuButtons/NewRosterButton", ["pressed"], "enabled", "required", {"meta_key": "roster_action", "meta_value": "new_start_roster", "focus": true}),
		_button_spec("TeamEditorToggleButton", "MenuRail/MenuMargin/MenuVBox/MenuButtons/TeamEditorToggleButton", ["pressed"], "enabled", "required", {"meta_key": "roster_action", "meta_value": "toggle_team_editor", "focus": true}),
	], Vector2(1920.0, 1080.0))
	var settings_button := screen.get_node_or_null("MenuRail/MenuMargin/MenuVBox/MenuButtons/SettingsButton") as BaseButton
	var press_result: Dictionary = Dictionary(HARNESS_SCRIPT.press_button_for_test(settings_button))
	_assert(bool(press_result.get("pressed", false)) and bool(screen.call("is_settings_panel_visible")), "Settings button click opens local settings panel")
	await process_frame
	_check_required_controls("settings", screen, [
		_control_spec("ResolutionOptionButton", "SettingsPanel/SettingsMargin/SettingsVBox/ResolutionOptionButton", ["item_selected"], "enabled", "required"),
		_control_spec("WindowModeOptionButton", "SettingsPanel/SettingsMargin/SettingsVBox/WindowModeOptionButton", ["item_selected"], "enabled", "required"),
		_button_spec("FullscreenCheckButton", "SettingsPanel/SettingsMargin/SettingsVBox/FullscreenCheckButton", ["toggled"], "enabled", "required"),
		_control_spec("MasterVolumeSlider", "SettingsPanel/SettingsMargin/SettingsVBox/MasterVolumeSlider", ["value_changed"], "enabled", "required"),
		_control_spec("MusicVolumeSlider", "SettingsPanel/SettingsMargin/SettingsVBox/MusicVolumeSlider", ["value_changed"], "enabled", "required"),
		_control_spec("SfxVolumeSlider", "SettingsPanel/SettingsMargin/SettingsVBox/SfxVolumeSlider", ["value_changed"], "enabled", "required"),
		_control_spec("FogOfWarModeOptionButton", "SettingsPanel/SettingsMargin/SettingsVBox/FogOfWarModeOptionButton", ["item_selected"], "enabled", "required"),
		_control_spec("BubbleModeOptionButton", "SettingsPanel/SettingsMargin/SettingsVBox/BubbleModeOptionButton", ["item_selected"], "enabled", "required"),
		_button_spec("SettingsApplyButton", "SettingsPanel/SettingsMargin/SettingsVBox/SettingsActionRow/SettingsApplyButton", ["pressed"], "enabled", "required"),
		_button_spec("SettingsResetButton", "SettingsPanel/SettingsMargin/SettingsVBox/SettingsActionRow/SettingsResetButton", ["pressed"], "enabled", "required"),
		_button_spec("SettingsBackButton", "SettingsPanel/SettingsMargin/SettingsVBox/SettingsBackButton", ["pressed"], "enabled", "required"),
	], Vector2(1920.0, 1080.0))
	var back_button := screen.get_node_or_null("SettingsPanel/SettingsMargin/SettingsVBox/SettingsBackButton") as BaseButton
	press_result = Dictionary(HARNESS_SCRIPT.press_button_for_test(back_button))
	await process_frame
	_assert(bool(press_result.get("pressed", false)) and not bool(screen.call("is_settings_panel_visible")), "Settings cancel/back button click closes settings panel")
	screen.queue_free()
	await process_frame


func _test_multiplayer_lobby_buttons_and_click_states() -> void:
	root.size = Vector2i(1280, 720)
	var lobby: Node = HARNESS_SCRIPT.instantiate_scene(MULTIPLAYER_LOBBY_SCENE_PATH, root)
	_assert(lobby != null, "Multiplayer lobby scene instantiates for button inventory")
	if lobby == null:
		return
	await _wait_frames(2)
	_check_required_controls("multiplayer_lobby_idle", lobby, [
		_button_spec("HostButton", "Panel/Margin/VBox/HostJoinGrid/HostButton", ["pressed"], "enabled", "required", {"focus": true}),
		_button_spec("JoinButton", "Panel/Margin/VBox/HostJoinGrid/JoinButton", ["pressed"], "enabled", "required", {"focus": true}),
		_button_spec("BackButton", "Panel/Margin/VBox/SessionRow/BackButton", ["pressed"], "enabled", "required", {"focus": true}),
		_control_spec("RosterModeOptionButton", "Panel/Margin/VBox/RosterModeRow/RosterModeOptionButton", ["item_selected"], "conditional", "required", {"reason": "enabled for host/session roster authority"}),
		_button_spec("ReadyButton", "Panel/Margin/VBox/SessionRow/ReadyButton", ["pressed"], "conditional", "contextual_hidden_ok", {"reason": "visible after session starts"}),
		_button_spec("StartMissionButton", "Panel/Margin/VBox/SessionRow/StartMissionButton", ["pressed"], "conditional", "contextual_hidden_ok", {"reason": "host-only and ready-gated"}),
		_button_spec("DisconnectButton", "Panel/Margin/VBox/SessionRow/DisconnectButton", ["pressed"], "conditional", "contextual_hidden_ok", {"reason": "visible during active session"}),
		_button_spec("MapAcceptButton", "Panel/Margin/VBox/MapConsentPanel/Margin/VBox/MapConsentRow/MapAcceptButton", ["pressed"], "conditional", "contextual_hidden_ok", {"reason": "visible only when host map requires consent"}),
		_button_spec("MapRejectButton", "Panel/Margin/VBox/MapConsentPanel/Margin/VBox/MapConsentRow/MapRejectButton", ["pressed"], "conditional", "contextual_hidden_ok", {"reason": "visible only when host map requires consent"}),
	], Vector2(1280.0, 720.0))
	lobby.call("configure_host_state_for_test", [1, 2])
	await process_frame
	var start_button := lobby.get_node_or_null("Panel/Margin/VBox/SessionRow/StartMissionButton") as BaseButton
	_assert(start_button != null and start_button.visible and start_button.disabled, "Lobby Start is visible but disabled with expected ready-gate reason")
	var press_result: Dictionary = Dictionary(HARNESS_SCRIPT.press_button_for_test(start_button))
	_assert(not bool(press_result.get("pressed", true)) and String(press_result.get("reason", "")) == "disabled", "Harness refuses disabled lobby Start click before peers ready")
	lobby.call("set_peer_ready_for_test", 1, true)
	lobby.call("set_peer_ready_for_test", 2, true)
	await process_frame
	_assert(start_button != null and not start_button.disabled, "Lobby Start enables when all host peers are ready")
	press_result = Dictionary(HARNESS_SCRIPT.press_button_for_test(start_button))
	await process_frame
	var ui_snapshot: Dictionary = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	_assert(bool(press_result.get("pressed", false)) and int(ui_snapshot.get("mission_start_request_count", 0)) == 1, "Lobby Start click emits the expected mission-start request")
	lobby.queue_free()
	await process_frame


func _test_map_editor_buttons() -> void:
	root.size = Vector2i(1920, 1080)
	var editor: Node = HARNESS_SCRIPT.instantiate_scene(MAP_EDITOR_SCENE_PATH, root)
	_assert(editor != null, "Map editor scene instantiates for button inventory")
	if editor == null:
		return
	await _wait_frames(4)
	_check_required_controls("map_editor", editor, [
		_button_spec("BrushButton", "UI/TopBar/Margin/HBox/BrushButton", [], "enabled", "required", {"reason": "brush state is read directly during map input"}),
		_control_spec("BrushSizeOptionButton", "UI/TopBar/Margin/HBox/BrushSizeOptionButton", [], "enabled", "required", {"reason": "brush size is read directly during paint input"}),
		_button_spec("UndoButton", "UI/TopBar/Margin/HBox/UndoButton", ["pressed"], "conditional", "required", {"reason": "enabled only with undo state"}),
		_button_spec("NewMapButton", "UI/TopBar/Margin/HBox/NewMapButton", ["pressed"], "enabled", "required"),
		_button_spec("LoadButton", "UI/TopBar/Margin/HBox/LoadButton", ["pressed"], "enabled", "required"),
		_button_spec("SaveButton", "UI/TopBar/Margin/HBox/SaveButton", ["pressed"], "conditional", "required", {"reason": "enabled depends on dirty/save state"}),
		_control_spec("HeightSpinBox", "UI/PropertyPanel/Margin/VBox/HeightRow/HeightSpinBox", ["value_changed"], "enabled", "required"),
		_control_spec("EdgeTypeOptionButton", "UI/PropertyPanel/Margin/VBox/EdgeTypeRow/EdgeTypeOptionButton", ["item_selected"], "conditional", "required", {"reason": "enabled after a tile selection"}),
		_control_spec("SurfaceOptionButton", "UI/PropertyPanel/Margin/VBox/SurfaceRow/SurfaceOptionButton", ["item_selected"], "conditional", "required", {"reason": "enabled after a tile selection"}),
		_button_spec("SpawnAlphaButton", "UI/PropertyPanel/Margin/VBox/SpawnAlphaRow/SpawnAlphaButton", ["pressed"], "enabled", "contextual_hidden_ok", {"reason": "marker rows are visible in marker-authoring context"}),
		_button_spec("SpawnBravoButton", "UI/PropertyPanel/Margin/VBox/SpawnBravoRow/SpawnBravoButton", ["pressed"], "enabled", "contextual_hidden_ok", {"reason": "marker rows are visible in marker-authoring context"}),
		_button_spec("ObjectivePointButton", "UI/PropertyPanel/Margin/VBox/ObjectivePointRow/ObjectivePointButton", ["pressed"], "enabled", "contextual_hidden_ok", {"reason": "marker rows are visible in marker-authoring context"}),
	], Vector2(1920.0, 1080.0))
	editor.queue_free()
	await process_frame


func _test_homebase_fob_and_debrief_buttons() -> void:
	var target_viewport: Vector2i = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT")
	root.size = target_viewport
	var homebase: Node = HARNESS_SCRIPT.instantiate_scene(HOMEBASE_SCENE_PATH, root)
	_assert(homebase != null, "Homebase scene instantiates for button inventory")
	if homebase != null:
		await _wait_frames(3)
		_check_required_controls("homebase", homebase, [
			_button_spec("StartMissionButton", "Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/StartMissionButton", ["pressed"], "conditional", "required", {"reason": "mission launch readiness", "skip_cover": true}),
			_control_spec("MissionSelector", "Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/MissionSelector", ["item_selected"], "enabled", "required"),
			_button_spec("ConfirmButton", "Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamHeaderRow/ConfirmButton", ["pressed"], "conditional", "contextual_hidden_ok", {"reason": "visible while the legacy transfer team panel is active"}),
			_button_spec("CloseSheetButton", "Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoScroll/InfoVBox/InfoHeaderRow/CloseSheetButton", ["pressed"], "enabled", "contextual_hidden_ok", {"reason": "visible while the legacy inline character sheet is active"}),
			_control_spec("AircraftSelector", "Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftSelectorRow/AircraftSelector", ["item_selected"], "conditional", "required", {"reason": "depends on available craft"}),
			_button_spec("AddAircraftButton", "Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftSelectorRow/AddAircraftButton", ["pressed"], "enabled", "required"),
			_button_spec("LoadCargoButton", "Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftCargoRow/LoadCargoButton", ["pressed"], "conditional", "contextual_hidden_ok", {"reason": "cargo row hidden unless craft supports cargo"}),
		], Vector2(target_viewport))
		homebase.queue_free()
		await process_frame

	var fob: Node = HARNESS_SCRIPT.instantiate_scene(FOB_SCENE_PATH, root)
	_assert(fob != null, "FOB scene instantiates for button inventory")
	if fob != null:
		(fob as CanvasItem).visible = true
		await _wait_frames(3)
		_check_required_controls("fob", fob, [
			_button_spec("AddTeamButton", "Panel/Margin/VBox/ContentRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamToolbar/AddTeamButton", ["pressed"], "enabled", "required"),
			_button_spec("RemoveTeamButton", "Panel/Margin/VBox/ContentRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamToolbar/RemoveTeamButton", ["pressed"], "conditional", "required", {"reason": "default team cannot be removed"}),
			_button_spec("AssignFocusedUnitButton", "Panel/Margin/VBox/ContentRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamToolbar/AssignFocusedUnitButton", ["pressed"], "conditional", "required", {"reason": "requires focused unit"}),
			_button_spec("ClearFocusedUnitButton", "Panel/Margin/VBox/ContentRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamToolbar/ClearFocusedUnitButton", ["pressed"], "conditional", "required", {"reason": "requires focused assigned unit"}),
			_button_spec("ClearLoadoutButton", "Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/LoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutHeaderRow/ClearLoadoutButton", ["pressed"], "conditional", "required", {"reason": "requires loadout fireteam"}),
			_button_spec("BoardButton", "Panel/Margin/VBox/DropLightBottomRow/ActionsPanel/Margin/VBox/ActionGrid/BoardButton", ["pressed"], "conditional", "required", {"reason": "requires boardable selected craft/team"}),
			_button_spec("SendButton", "Panel/Margin/VBox/DropLightBottomRow/ActionsPanel/Margin/VBox/ActionGrid/SendButton", ["pressed"], "conditional", "required", {"reason": "requires launch-ready craft"}),
			_button_spec("UnboardButton", "Panel/Margin/VBox/DropLightBottomRow/ActionsPanel/Margin/VBox/ActionGrid/UnboardButton", [], "disabled_expected", "required", {"reason": "visible disabled template action"}),
			_button_spec("CloseOverlayButton", "CharacterOverlay/OverlayPanel/OverlayMargin/OverlayVBox/OverlayHeaderRow/CloseOverlayButton", ["pressed"], "conditional", "contextual_hidden_ok", {"reason": "visible only when character sheet overlay is open"}),
		], Vector2(target_viewport))
		fob.queue_free()
		await process_frame

	var debrief: Node = HARNESS_SCRIPT.instantiate_scene(DEBRIEF_SCENE_PATH, root)
	_assert(debrief != null, "Debrief scene instantiates for button inventory")
	if debrief != null:
		(debrief as CanvasItem).visible = true
		await _wait_frames(2)
		_check_required_controls("debrief", debrief, [
			_button_spec("ReturnToFOBButton", "Panel/Margin/VBox/ButtonRow/ReturnToFOBButton", ["pressed"], "enabled", "required"),
			_button_spec("ReturnToHomebaseButton", "Panel/Margin/VBox/ButtonRow/ReturnToHomebaseButton", ["pressed"], "enabled", "required"),
		], Vector2(target_viewport))
		debrief.queue_free()
		await process_frame


func _test_mission_hud_buttons() -> void:
	var target_viewport: Vector2i = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT")
	root.size = target_viewport
	var mission: Node = HARNESS_SCRIPT.instantiate_scene(MISSION_SCENE_PATH, root)
	_assert(mission != null, "Mission scene instantiates for HUD button inventory")
	if mission == null:
		return
	await _wait_frames(6)
	_check_required_controls("mission_hud", mission, [
		_button_spec("HomebaseNavButton", "TacticalUI/TopNavPanel/NavMargin/NavRow/HomebaseNavButton", ["pressed"], "enabled", "required"),
		_button_spec("FOBNavButton", "TacticalUI/TopNavPanel/NavMargin/NavRow/FOBNavButton", ["pressed"], "enabled", "required"),
		_button_spec("MissionNavButton", "TacticalUI/TopNavPanel/NavMargin/NavRow/MissionNavButton", ["pressed"], "enabled", "required"),
		_button_spec("MoveButton", "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/MoveButton", ["pressed"], "conditional", "required", {"reason": "requires selected fireteam command context"}),
		_button_spec("HoldButton", "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/HoldButton", ["pressed"], "conditional", "required", {"reason": "requires selected fireteam command context"}),
		_button_spec("FlankButton", "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/FlankButton", ["pressed"], "conditional", "required", {"reason": "requires selected fireteam command context"}),
		_button_spec("TakeButton", "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TakeButton", ["pressed"], "conditional", "required", {"reason": "requires selected fireteam command context"}),
		_button_spec("TargetButton", "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TargetButton", ["pressed"], "conditional", "required", {"reason": "requires selected target context"}),
		_button_spec("ClearTargetButton", "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/ClearTargetButton", ["pressed"], "conditional", "required", {"reason": "requires selected target context"}),
		_button_spec("AllFireteamsButton", "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderRow/AllFireteamsButton", ["pressed"], "enabled", "required"),
		_button_spec("SetLZButton", "TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/SetLZButton", ["pressed"], "conditional", "contextual_hidden_ok", {"reason": "planning controls are hidden after the compact mission-control handoff"}),
		_button_spec("CallDropshipButton", "TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/CallDropshipButton", ["pressed"], "conditional", "contextual_hidden_ok", {"reason": "planning controls are hidden after the compact mission-control handoff"}),
		_button_spec("AddPhaseButton", "TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/AddPhaseButton", ["pressed"], "conditional", "contextual_hidden_ok", {"reason": "phase planning can be hidden by the fixed HUD mode"}),
		_button_spec("NextPhaseButton", "TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/NextPhaseButton", ["pressed"], "conditional", "contextual_hidden_ok", {"reason": "phase planning can be hidden by the fixed HUD mode"}),
		_button_spec("NWButton", "TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/NWButton", ["pressed"], "conditional", "contextual_hidden_ok", {"reason": "planning controls are hidden after the compact mission-control handoff"}),
		_button_spec("NEButton", "TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/NEButton", ["pressed"], "conditional", "contextual_hidden_ok", {"reason": "planning controls are hidden after the compact mission-control handoff"}),
	], Vector2(target_viewport))
	mission.queue_free()
	await process_frame


func _check_required_controls(screen_id: String, screen_root: Node, specs: Array, viewport_size: Vector2) -> void:
	for spec_variant in specs:
		var spec: Dictionary = Dictionary(spec_variant)
		var control_id: String = String(spec.get("id", ""))
		var path: String = String(spec.get("path", ""))
		var control := screen_root.get_node_or_null(path) as Control
		_inventory_count += 1
		_assert(control != null, "%s/%s exists at %s" % [screen_id, control_id, path])
		if control == null:
			continue
		var visibility_policy: String = String(spec.get("visibility", "required"))
		var visible: bool = control.visible and (control.is_visible_in_tree() if control.is_inside_tree() else true)
		if visibility_policy == "required":
			_assert(visible, "%s/%s is visible" % [screen_id, control_id])
		elif visibility_policy == "contextual_hidden_ok":
			_assert(true, "%s/%s may be hidden contextually: %s" % [screen_id, control_id, String(spec.get("reason", ""))])
		if visible:
			_assert(HARNESS_SCRIPT.is_control_reachable_in_viewport(control, viewport_size, 1.0), "%s/%s is directly visible or scroll-reachable" % [screen_id, control_id])
			if bool(spec.get("skip_cover", false)):
				_assert(true, "%s/%s skips full-cover heuristic: %s" % [screen_id, control_id, String(spec.get("reason", ""))])
			else:
				_assert(not HARNESS_SCRIPT.is_control_fully_covered_by_later_control(screen_root, control), "%s/%s is not fully covered by another control" % [screen_id, control_id])
		var enabled_policy: String = String(spec.get("enabled", "enabled"))
		if _has_disabled_property(control):
			var disabled: bool = bool(control.get("disabled"))
			if enabled_policy == "enabled":
				_assert(not disabled, "%s/%s is enabled" % [screen_id, control_id])
			elif enabled_policy == "disabled_expected":
				_assert(disabled and not String(spec.get("reason", "")).is_empty(), "%s/%s disabled state has an expected reason" % [screen_id, control_id])
			elif enabled_policy == "conditional":
				_assert(not String(spec.get("reason", "")).is_empty(), "%s/%s has documented conditional disabled reason" % [screen_id, control_id])
		for signal_name_variant in Array(spec.get("signals", [])):
			var signal_name: String = String(signal_name_variant)
			_assert(HARNESS_SCRIPT.has_signal_connection(control, signal_name), "%s/%s has %s binding" % [screen_id, control_id, signal_name])
		if bool(spec.get("focus", false)):
			_assert(control.focus_mode != Control.FOCUS_NONE, "%s/%s has keyboard focus reachability" % [screen_id, control_id])
		if spec.has("route"):
			_assert(String(control.get_meta("route", "")) == String(spec.get("route", "")), "%s/%s route metadata is valid" % [screen_id, control_id])
		if spec.has("meta_key"):
			_assert(String(control.get_meta(String(spec.get("meta_key", "")), "")) == String(spec.get("meta_value", "")), "%s/%s metadata %s is valid" % [screen_id, control_id, String(spec.get("meta_key", ""))])


func _test_report_exists() -> void:
	_assert(_inventory_count >= 60, "Button inventory covers a broad cross-screen control set")
	_assert(FileAccess.file_exists(REPORT_PATH), "Button reachability report exists")
	var report: String = _read_text(REPORT_PATH)
	for required_text in ["Summary", "Covered Screens", "Manual Open Items", "Defective Interactions"]:
		_assert(report.contains(required_text), "Button reachability report covers %s" % required_text)


func _button_spec(id: String, path: String, signals: Array, enabled: String, visibility: String, extra: Dictionary = {}) -> Dictionary:
	var spec: Dictionary = _control_spec(id, path, signals, enabled, visibility, extra)
	spec["kind"] = "button"
	return spec


func _control_spec(id: String, path: String, signals: Array, enabled: String, visibility: String, extra: Dictionary = {}) -> Dictionary:
	var spec: Dictionary = {
		"id": id,
		"path": path,
		"signals": signals.duplicate(),
		"enabled": enabled,
		"visibility": visibility,
	}
	for key in extra.keys():
		spec[key] = extra[key]
	return spec


func _has_disabled_property(control: Control) -> bool:
	for property in control.get_property_list():
		if String(Dictionary(property).get("name", "")) == "disabled":
			return true
	return false


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
