class_name MetaUISkin
extends RefCounted

const TACTICAL_UI_THEME_SCRIPT: GDScript = preload("res://scripts/ui/tactical_ui_theme.gd")
const NATIVE_UI_ICONS_SCRIPT: GDScript = preload("res://scripts/ui/native_ui_icons.gd")
const FRONTIER_STAGE_PATH := "res://Assets/curated/main_menu/frontier_outpost_main_20261101.png"
static var _frontier_stage_texture: Texture2D

const COLOR_FRAME := TACTICAL_UI_THEME_SCRIPT.COLOR_PANEL_ALT
const COLOR_FRAME_BORDER := TACTICAL_UI_THEME_SCRIPT.COLOR_BORDER
const COLOR_PANEL := TACTICAL_UI_THEME_SCRIPT.COLOR_PANEL
const COLOR_PANEL_ALT := TACTICAL_UI_THEME_SCRIPT.COLOR_PANEL_ALT
const COLOR_HEADER := TACTICAL_UI_THEME_SCRIPT.COLOR_PANEL_SELECTED
const COLOR_HEADER_BORDER := TACTICAL_UI_THEME_SCRIPT.COLOR_BORDER
# Legacy names remain available; their roles now use the shared dark skin.
const COLOR_BUTTON_LIGHT := TACTICAL_UI_THEME_SCRIPT.COLOR_PANEL_ALT
const COLOR_BUTTON_LIGHT_HOVER := Color("303a42")
const COLOR_BUTTON_PRESSED := TACTICAL_UI_THEME_SCRIPT.COLOR_PANEL_SELECTED
const COLOR_BUTTON_DARK := TACTICAL_UI_THEME_SCRIPT.COLOR_PANEL_SELECTED
const COLOR_BUTTON_DARK_HOVER := TACTICAL_UI_THEME_SCRIPT.COLOR_PANEL_ALT
const COLOR_BUTTON_BORDER := TACTICAL_UI_THEME_SCRIPT.COLOR_BORDER
const COLOR_READY := TACTICAL_UI_THEME_SCRIPT.COLOR_SUCCESS
const COLOR_WARNING := TACTICAL_UI_THEME_SCRIPT.COLOR_WARNING
const COLOR_DANGER := TACTICAL_UI_THEME_SCRIPT.COLOR_DANGER
const COLOR_ACCENT := TACTICAL_UI_THEME_SCRIPT.COLOR_ACCENT
const COLOR_MUTED := TACTICAL_UI_THEME_SCRIPT.COLOR_NEUTRAL

const TEXT_HEADER := TACTICAL_UI_THEME_SCRIPT.COLOR_TEXT
const TEXT_BODY := TACTICAL_UI_THEME_SCRIPT.COLOR_TEXT
const TEXT_MUTED := TACTICAL_UI_THEME_SCRIPT.COLOR_TEXT_MUTED
const TEXT_DISABLED := TACTICAL_UI_THEME_SCRIPT.COLOR_TEXT_MUTED
const TEXT_DARK := TACTICAL_UI_THEME_SCRIPT.COLOR_TEXT_DARK


static func apply_homebase(screen: Control) -> void:
	TACTICAL_UI_THEME_SCRIPT.apply_screen(screen)
	_apply_panel_style(screen, "Panel", "frame")
	_apply_panel_style(screen, "Panel/Margin/VBox/MissionPanel", "mission_header")
	_apply_panel_style(screen, "Panel/Margin/VBox/ContentRow/RosterPanel", "frame")
	_apply_panel_style(screen, "Panel/Margin/VBox/ContentRow/TeamPanel", "frame")
	_apply_panel_style(screen, "Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamDropPanel", "panel")
	_apply_panel_style(screen, "Panel/Margin/VBox/ContentRow/AircraftPanel", "frame")
	_apply_panel_style(screen, "Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftAssignmentFrame", "thin_frame")
	_apply_panel_style(screen, "Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftAssignmentFrame/AircraftAssignmentMargin/AircraftAssignmentRow/AircraftPilotVBox/AircraftPilotDropPanel", "panel")
	_apply_panel_style(screen, "Panel/Margin/VBox/ContentRow/InfoPanel", "frame")

	style_transfer_button(screen.get_node_or_null("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamHeaderRow/ConfirmButton"), false)
	style_transfer_button(screen.get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftAssignmentFrame/AircraftAssignmentMargin/AircraftAssignmentRow/AircraftPilotVBox/AircraftActionButtons/SendPilotButton"), false)
	style_transfer_button(screen.get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/StartMissionButton"), false)
	style_header_button(screen.get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/MissionSelector"), false)
	_apply_button_style(screen.get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftSelectorRow/AddAircraftButton"), false)
	_apply_button_style(screen.get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftSelectorRow/RemoveAircraftButton"), false)
	_apply_button_style(screen.get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftCargoRow/LoadCargoButton"), false)
	_apply_button_style(screen.get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftAssignmentFrame/AircraftAssignmentMargin/AircraftAssignmentRow/AircraftPilotVBox/AircraftActionButtons/ClearPilotButton"), false)
	_apply_button_style(screen.get_node_or_null("Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoScroll/InfoVBox/InfoHeaderRow/CloseSheetButton"), false)
	for path in [
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow/HomebaseNavButton",
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow/FOBNavButton",
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow/MissionNavButton",
	]:
		style_header_button(screen.get_node_or_null(path), false)

	for path in [
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionHeaderLabel",
		"Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamHeaderRow/TeamHeaderLabel",
		"Panel/Margin/VBox/ContentRow/RosterPanel/RosterMargin/RosterVBox/RosterHeaderLabel",
		"Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftHeaderLabel",
		"Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoScroll/InfoVBox/InfoHeaderRow/InfoHeaderLabel",
	]:
		style_header_label(screen.get_node_or_null(path), 12)

	for path in [
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/MissionNameLabel",
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/MissionTeamLimitLabel",
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/MissionTransferLabel",
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionSummaryLabel",
	]:
		style_body_label(screen.get_node_or_null(path), 10)

	for path in [
		"Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamStatusLabel",
		"Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/SelectedNamesLabel",
		"Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/ActiveTransfersHeaderLabel",
		"Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftStatusLabel",
		"Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftAssignmentFrame/AircraftAssignmentMargin/AircraftAssignmentRow/AircraftPilotVBox/AircraftPilotHeaderLabel",
		"Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftAssignmentFrame/AircraftAssignmentMargin/AircraftAssignmentRow/AircraftPilotVBox/AircraftPilotDropPanel/AircraftPilotDropMargin/AircraftPilotDropVBox/AircraftPilotHelpLabel",
		"Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftTransfersHeaderLabel",
	]:
		_apply_label_style(screen.get_node_or_null(path), "body")


static func apply_fob(screen: Control) -> void:
	TACTICAL_UI_THEME_SCRIPT.apply_screen(screen)
	_apply_panel_style(screen, "Panel", "frame")
	_apply_panel_style(screen, "Panel/Margin/VBox/MissionPanel", "mission_header")
	_apply_panel_style(screen, "Panel/Margin/VBox/ContentRow/AvailablePanel", "frame")
	_apply_panel_style(screen, "Panel/Margin/VBox/ContentRow/FireteamPanel", "frame")
	_apply_panel_style(screen, "Panel/Margin/VBox/ContentRow/StagingPanel", "frame")
	_apply_panel_style(screen, "Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/RespawnPanel", "panel")
	_apply_panel_style(screen, "Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/LoadoutPanel", "panel")
	_apply_panel_style(screen, "Panel/Margin/VBox/ContentRow/DropshipPanel", "frame")

	for path in [
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow/HomebaseNavButton",
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow/FOBNavButton",
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow/MissionNavButton",
	]:
		style_header_button(screen.get_node_or_null(path), false)

	style_primary_button(screen.get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/StartMissionButton"))
	_apply_button_style(screen.get_node_or_null("Panel/Margin/VBox/ContentRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamToolbar/AddTeamButton"), false)
	_apply_button_style(screen.get_node_or_null("Panel/Margin/VBox/ContentRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamToolbar/RemoveTeamButton"), false)
	_apply_button_style(screen.get_node_or_null("Panel/Margin/VBox/ContentRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamToolbar/AssignFocusedUnitButton"), false)
	_apply_button_style(screen.get_node_or_null("Panel/Margin/VBox/ContentRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamToolbar/ClearFocusedUnitButton"), false)
	_apply_button_style(screen.get_node_or_null("Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/RespawnPanel/RespawnMargin/RespawnVBox/RespawnButtonRow/SetRespawnButton"), false)
	_apply_button_style(screen.get_node_or_null("Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/RespawnPanel/RespawnMargin/RespawnVBox/RespawnButtonRow/ClearRespawnButton"), false)
	_apply_button_style(screen.get_node_or_null("Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/LoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutHeaderRow/ClearLoadoutButton"), false)
	_apply_button_style(screen.get_node_or_null("Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipHeaderRow/StartBoardingButton"), false)
	_apply_button_style(screen.get_node_or_null("Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipHeaderRow/RemoveDropshipFireteamButton"), false)
	_apply_button_style(screen.get_node_or_null("CharacterOverlay/OverlayPanel/OverlayMargin/OverlayVBox/OverlayHeaderRow/CloseOverlayButton"), false)
	_apply_panel_style(screen, "CharacterOverlay/OverlayPanel", "frame")

	for path in [
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionHeaderLabel",
		"Panel/Margin/VBox/ContentRow/AvailablePanel/AvailableMargin/AvailableVBox/AvailableHeaderLabel",
		"Panel/Margin/VBox/ContentRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderLabel",
		"Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/StagingHeaderLabel",
		"Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/RespawnPanel/RespawnMargin/RespawnVBox/RespawnHeaderLabel",
		"Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/LoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutHeaderRow/LoadoutHeaderLabel",
		"Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipHeaderRow/DropshipHeaderLabel",
		"CharacterOverlay/OverlayPanel/OverlayMargin/OverlayVBox/OverlayHeaderRow/OverlayHeaderLabel",
	]:
		style_header_label(screen.get_node_or_null(path), 12)

	for path in [
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/TeamStatusLabel",
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/FireteamStatusLabel",
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/DropshipStatusLabel",
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionSummaryLabel",
	]:
		style_body_label(screen.get_node_or_null(path), 10)

	for path in [
		"Panel/Margin/VBox/ContentRow/AvailablePanel/AvailableMargin/AvailableVBox/AvailableHelpLabel",
		"Panel/Margin/VBox/ContentRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamSummaryLabel",
		"Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/RespawnPanel/RespawnMargin/RespawnVBox/RespawnStatusLabel",
		"Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/RespawnPanel/RespawnMargin/RespawnVBox/RespawnHelpLabel",
		"Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/LoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutStatusLabel",
		"Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/LoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutHelpLabel",
		"Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipTopRow/DropshipInfoVBox/DropshipStatusLabel",
		"Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipTopRow/DropshipInfoVBox/DropshipEtaLabel",
		"Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipTopRow/DropshipInfoVBox/BoardingQueueLabel",
		"Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipTopRow/DropshipVisualVBox/DropshipArrivalLabel",
		"Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipHelpLabel",
	]:
		_apply_label_style(screen.get_node_or_null(path), "body")


static func apply_map(screen: Control) -> void:
	TACTICAL_UI_THEME_SCRIPT.apply_screen(screen)
	_apply_panel_style(screen, "Panel", "frame")
	_apply_panel_style(screen, "Panel/Margin/VBox/MissionPanel", "mission_header")
	_apply_panel_style(screen, "Panel/Margin/VBox/ContentRow/MapPanel", "frame")
	_apply_panel_style(screen, "Panel/Margin/VBox/ContentRow/MapPanel/MapMargin/MapVBox/MapPreviewFrame", "panel")
	_apply_panel_style(screen, "Panel/Margin/VBox/ContentRow/SummaryPanel", "frame")

	for path in [
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow/HomebaseNavButton",
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow/FOBNavButton",
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow/MissionNavButton",
	]:
		style_header_button(screen.get_node_or_null(path), false)

	for path in [
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionHeaderLabel",
		"Panel/Margin/VBox/ContentRow/MapPanel/MapMargin/MapVBox/MapHeaderRow/MapHeaderLabel",
		"Panel/Margin/VBox/ContentRow/SummaryPanel/SummaryMargin/SummaryVBox/SummaryHeaderLabel",
	]:
		style_header_label(screen.get_node_or_null(path), 12)

	for path in [
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/MapNameLabel",
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/OperatorCountLabel",
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/FireteamCountLabel",
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionSummaryLabel",
		"Panel/Margin/VBox/ContentRow/MapPanel/MapMargin/MapVBox/MapHeaderRow/MapCapacityLabel",
	]:
		style_body_label(screen.get_node_or_null(path), 10)

	for path in [
		"Panel/Margin/VBox/ContentRow/MapPanel/MapMargin/MapVBox/MarkerListLabel",
		"Panel/Margin/VBox/ContentRow/MapPanel/MapMargin/MapVBox/MapDataLabel",
		"Panel/Margin/VBox/ContentRow/MapPanel/MapMargin/MapVBox/MapHelpLabel",
		"Panel/Margin/VBox/ContentRow/SummaryPanel/SummaryMargin/SummaryVBox/FireteamOverviewLabel",
		"Panel/Margin/VBox/ContentRow/SummaryPanel/SummaryMargin/SummaryVBox/DropshipOverviewLabel",
		"Panel/Margin/VBox/ContentRow/SummaryPanel/SummaryMargin/SummaryVBox/RespawnOverviewLabel",
	]:
		_apply_label_style(screen.get_node_or_null(path), "body")


static func apply_meta_navigation(_root: Node) -> void:
	return


static func style_secondary_button(button: Button) -> void:
	_apply_button_style(button, false)


static func style_primary_button(button: Button) -> void:
	_apply_button_style(button, true)


static func style_tactical_panel(panel: PanelContainer, variant: String = "frame") -> void:
	if panel == null:
		return

	match variant:
		"header", "mission_header":
			panel.add_theme_stylebox_override("panel", TACTICAL_UI_THEME_SCRIPT.build_flat_stylebox(COLOR_HEADER, COLOR_HEADER_BORDER, 6, 1, Vector4(8, 8, 8, 8), 1.0, 3))
		"thin_frame":
			panel.add_theme_stylebox_override("panel", _build_thin_frame_stylebox())
		"panel":
			panel.add_theme_stylebox_override("panel", TACTICAL_UI_THEME_SCRIPT.build_flat_stylebox(COLOR_PANEL, COLOR_FRAME_BORDER, 6, 1, Vector4(8, 8, 8, 8), 1.0, 2))
		_:
			panel.add_theme_stylebox_override("panel", TACTICAL_UI_THEME_SCRIPT.get_theme().get_stylebox("panel", "PanelContainer"))
	TACTICAL_UI_THEME_SCRIPT.decorate_panel(panel, variant)


static func style_tactical_button(button: Button, is_active: bool = false) -> void:
	TACTICAL_UI_THEME_SCRIPT.style_command_button(button, "selected" if is_active else "neutral")


static func style_header_button(button: Button, primary: bool = false) -> void:
	_apply_button_style(button, primary)


static func style_header_label(label: Node, font_size: int = 12) -> void:
	_apply_label_style(label, "header")
	var typed_label := label as Label
	if typed_label != null:
		typed_label.add_theme_font_size_override("font_size", font_size)


static func style_preparation_heading(label: Label, font_size: int = 20, icon_id: String = "") -> void:
	if label == null:
		return
	TACTICAL_UI_THEME_SCRIPT.style_section_heading(label, font_size)
	label.set_meta("native_r4_preparation_heading", true)
	if icon_id.is_empty():
		return
	var icon := label.get_node_or_null("R4SectionIcon") as TextureRect
	if icon == null:
		icon = TextureRect.new()
		icon.name = "R4SectionIcon"
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		label.add_child(icon)
		icon.anchor_top = 0.5
		icon.anchor_bottom = 0.5
		icon.offset_left = 4.0
		icon.offset_right = 28.0
		icon.offset_top = -12.0
		icon.offset_bottom = 12.0
	icon.texture = NATIVE_UI_ICONS_SCRIPT.get_icon(icon_id)
	var heading_style := label.get_theme_stylebox("normal").duplicate() as StyleBox
	heading_style.set_content_margin(SIDE_LEFT, 36.0)
	label.add_theme_stylebox_override("normal", heading_style)


static func update_frontier_stage(screen: Control, target: Rect2i, visible_stage: bool = true) -> void:
	# A static curated Main capture fills otherwise unused space. It never reads
	# transport readiness, adds an actor, or intercepts the real cards above it.
	var panel := screen.get_node_or_null("Panel") as Control
	if panel == null:
		return
	var stage := panel.get_node_or_null("R4FrontierStage") as PanelContainer
	if stage == null:
		stage = PanelContainer.new()
		stage.name = "R4FrontierStage"
		stage.set_as_top_level(true)
		stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.clip_contents = true
		stage.set_meta("native_r4_decorative_frontier_stage", true)
		stage.set_meta("visual_only", true)
		stage.set_meta("source_resource", FRONTIER_STAGE_PATH)
		style_tactical_panel(stage, "thin_frame")
		panel.add_child(stage)
		panel.move_child(stage, 0)
		var image := TextureRect.new()
		image.name = "FrontierImage"
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		if _frontier_stage_texture == null:
			_frontier_stage_texture = load(FRONTIER_STAGE_PATH) as Texture2D
		image.texture = _frontier_stage_texture
		stage.add_child(image)
	stage.visible = visible_stage and target.size.x > 0 and target.size.y >= 80
	stage.position = Vector2(target.position)
	stage.size = Vector2(target.size)


static func style_body_label(label: Node, font_size: int = 10) -> void:
	_apply_label_style(label, "body")
	var typed_label := label as Label
	if typed_label != null:
		typed_label.add_theme_font_size_override("font_size", font_size)


static func style_danger_round_button(button: Button) -> void:
	TACTICAL_UI_THEME_SCRIPT.style_command_button(button, "danger")


static func style_transfer_button(button: Button, is_ready: bool) -> void:
	TACTICAL_UI_THEME_SCRIPT.style_command_button(button, "accent" if is_ready else "neutral")


static func _apply_panel_style(screen: Control, path: String, variant: String) -> void:
	var panel := screen.get_node_or_null(path) as PanelContainer
	if panel == null:
		return

	style_tactical_panel(panel, variant)


static func _apply_button_style(button: Button, primary: bool) -> void:
	TACTICAL_UI_THEME_SCRIPT.style_command_button(button, "accent" if primary else "neutral")


static func _apply_label_style(label: Node, tone: String) -> void:
	var typed_label := label as Label
	if typed_label == null:
		return

	match tone:
		"header":
			typed_label.add_theme_color_override("font_color", TEXT_HEADER)
		"muted":
			typed_label.add_theme_color_override("font_color", TEXT_MUTED)
		_:
			typed_label.add_theme_color_override("font_color", TEXT_BODY)


static func _build_flat_stylebox(
	fill_color: Color,
	border_color: Color,
	radius: int,
	border_width: int,
	content_margin: Vector4
) -> StyleBoxFlat:
	return TACTICAL_UI_THEME_SCRIPT.build_flat_stylebox(fill_color, border_color, radius, border_width, content_margin)


static func _build_round_flat_stylebox(fill_color: Color, border_color: Color) -> StyleBoxFlat:
	return TACTICAL_UI_THEME_SCRIPT.build_flat_stylebox(fill_color, border_color, 6, 1, Vector4(8, 8, 8, 8))


static func _build_thin_frame_stylebox() -> StyleBoxFlat:
	return TACTICAL_UI_THEME_SCRIPT.build_flat_stylebox(COLOR_PANEL_ALT, COLOR_FRAME_BORDER, 6, 1, Vector4(4, 4, 4, 4), 1.0, 2)
