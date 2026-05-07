class_name MetaUISkin
extends RefCounted

const COLOR_FRAME := Color("252d33")
const COLOR_FRAME_BORDER := Color("4d5a63")
const COLOR_PANEL := Color("151c21")
const COLOR_PANEL_ALT := Color("20282e")
const COLOR_HEADER := Color("0d1216")
const COLOR_HEADER_BORDER := Color("38434b")
const COLOR_BUTTON_LIGHT := Color("d9dee7")
const COLOR_BUTTON_LIGHT_HOVER := Color("edf3f6")
const COLOR_BUTTON_PRESSED := Color("bcc7d0")
const COLOR_BUTTON_DARK := Color("12181d")
const COLOR_BUTTON_DARK_HOVER := Color("182027")
const COLOR_BUTTON_BORDER := Color("78848d")
const COLOR_READY := Color("69c391")
const COLOR_WARNING := Color("d89b31")
const COLOR_DANGER := Color("d66c66")
const COLOR_ACCENT := Color("63d1d2")
const COLOR_MUTED := Color("8e9aa3")

const TEXT_HEADER := Color("edf3f6")
const TEXT_BODY := Color("a9b4bc")
const TEXT_MUTED := Color("8e9aa3")
const TEXT_DISABLED := Color("626b73")
const TEXT_DARK := Color("1e252a")


static func apply_homebase(screen: Control) -> void:
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

	style_danger_round_button(screen.get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/StartMissionButton"))
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
		"header":
			panel.add_theme_stylebox_override("panel", _build_flat_stylebox(COLOR_HEADER, COLOR_HEADER_BORDER, 6, 1, Vector4(12.0, 10.0, 12.0, 10.0)))
		"panel":
			panel.add_theme_stylebox_override("panel", _build_flat_stylebox(COLOR_PANEL_ALT, COLOR_FRAME_BORDER, 6, 1, Vector4(14.0, 12.0, 14.0, 12.0)))
		_:
			panel.add_theme_stylebox_override("panel", _build_flat_stylebox(COLOR_FRAME, COLOR_FRAME_BORDER, 6, 1, Vector4(14.0, 12.0, 14.0, 12.0)))


static func style_tactical_button(button: Button, is_active: bool = false) -> void:
	if button == null:
		return

	button.add_theme_stylebox_override("normal", _build_flat_stylebox(COLOR_BUTTON_DARK if is_active else COLOR_BUTTON_LIGHT, COLOR_BUTTON_BORDER, 6, 1, Vector4(10.0, 8.0, 10.0, 8.0)))
	button.add_theme_stylebox_override("hover", _build_flat_stylebox(COLOR_BUTTON_DARK_HOVER if is_active else COLOR_BUTTON_LIGHT_HOVER, COLOR_BUTTON_BORDER, 6, 1, Vector4(10.0, 8.0, 10.0, 8.0)))
	button.add_theme_stylebox_override("pressed", _build_flat_stylebox(COLOR_BUTTON_DARK.darkened(0.08) if is_active else COLOR_BUTTON_PRESSED, COLOR_BUTTON_BORDER, 6, 1, Vector4(10.0, 8.0, 10.0, 8.0)))
	button.add_theme_stylebox_override("disabled", _build_flat_stylebox(COLOR_MUTED.darkened(0.25), COLOR_FRAME_BORDER, 6, 1, Vector4(10.0, 8.0, 10.0, 8.0)))
	button.add_theme_color_override("font_color", TEXT_HEADER if is_active else TEXT_DARK)
	button.add_theme_color_override("font_hover_color", TEXT_HEADER if is_active else TEXT_DARK)
	button.add_theme_color_override("font_pressed_color", TEXT_HEADER if is_active else TEXT_DARK)
	button.add_theme_color_override("font_focus_color", TEXT_HEADER if is_active else TEXT_DARK)
	button.add_theme_color_override("font_disabled_color", TEXT_DISABLED)
	button.add_theme_font_size_override("font_size", 9)


static func style_header_button(button: Button, primary: bool = false) -> void:
	_apply_button_style(button, primary)
	if button != null:
		button.add_theme_font_size_override("font_size", 9)


static func style_header_label(label: Node, font_size: int = 12) -> void:
	_apply_label_style(label, "header")
	var typed_label := label as Label
	if typed_label != null:
		typed_label.add_theme_font_size_override("font_size", font_size)


static func style_body_label(label: Node, font_size: int = 10) -> void:
	_apply_label_style(label, "body")
	var typed_label := label as Label
	if typed_label != null:
		typed_label.add_theme_font_size_override("font_size", font_size)


static func style_danger_round_button(button: Button) -> void:
	if button == null:
		return

	var normal := _build_round_flat_stylebox(COLOR_DANGER, Color("f4c1c1"))
	var hover := _build_round_flat_stylebox(COLOR_DANGER.lightened(0.08), Color("fee3e3"))
	var pressed := _build_round_flat_stylebox(COLOR_DANGER.darkened(0.24), Color("d89595"))
	var disabled := _build_round_flat_stylebox(Color("6e5555"), Color("897171"))
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color(1.0, 0.97, 0.97, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.97, 0.97, 1.0))
	button.add_theme_color_override("font_focus_color", Color(1.0, 1.0, 1.0, 1.0))
	button.add_theme_color_override("font_disabled_color", TEXT_DISABLED)


static func style_transfer_button(button: Button, is_ready: bool) -> void:
	if button == null:
		return

	var normal_fill := COLOR_READY if is_ready else COLOR_BUTTON_LIGHT
	var hover_fill := COLOR_READY.lightened(0.08) if is_ready else COLOR_BUTTON_LIGHT_HOVER
	var pressed_fill := COLOR_WARNING if is_ready else COLOR_BUTTON_PRESSED
	var font_color := TEXT_DARK
	button.add_theme_stylebox_override("normal", _build_flat_stylebox(normal_fill, COLOR_BUTTON_BORDER, 6, 1, Vector4(12.0, 10.0, 12.0, 10.0)))
	button.add_theme_stylebox_override("hover", _build_flat_stylebox(hover_fill, COLOR_BUTTON_BORDER, 6, 1, Vector4(12.0, 10.0, 12.0, 10.0)))
	button.add_theme_stylebox_override("pressed", _build_flat_stylebox(pressed_fill, COLOR_BUTTON_BORDER, 6, 1, Vector4(12.0, 10.0, 12.0, 10.0)))
	button.add_theme_stylebox_override("disabled", _build_flat_stylebox(COLOR_MUTED.darkened(0.25), COLOR_FRAME_BORDER, 6, 1, Vector4(12.0, 10.0, 12.0, 10.0)))
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_focus_color", font_color)
	button.add_theme_color_override("font_disabled_color", TEXT_DISABLED)


static func _apply_panel_style(screen: Control, path: String, variant: String) -> void:
	var panel := screen.get_node_or_null(path) as PanelContainer
	if panel == null:
		return

	match variant:
		"header":
			panel.add_theme_stylebox_override("panel", _build_flat_stylebox(COLOR_HEADER, COLOR_HEADER_BORDER, 6, 1, Vector4(10.0, 8.0, 10.0, 8.0)))
		"mission_header":
			panel.add_theme_stylebox_override("panel", _build_flat_stylebox(COLOR_HEADER, COLOR_HEADER_BORDER, 6, 1, Vector4(12.0, 10.0, 12.0, 10.0)))
		"thin_frame":
			panel.add_theme_stylebox_override("panel", _build_thin_frame_stylebox())
		"panel":
			panel.add_theme_stylebox_override("panel", _build_flat_stylebox(COLOR_PANEL, COLOR_FRAME_BORDER, 6, 1, Vector4(10.0, 8.0, 10.0, 8.0)))
		_:
			panel.add_theme_stylebox_override("panel", _build_flat_stylebox(COLOR_FRAME, COLOR_FRAME_BORDER, 6, 1, Vector4(10.0, 8.0, 10.0, 8.0)))


static func _apply_button_style(button: Button, primary: bool) -> void:
	if button == null:
		return

	var fill := COLOR_READY if primary else COLOR_BUTTON_LIGHT
	var hover_fill := COLOR_READY.lightened(0.08) if primary else COLOR_BUTTON_LIGHT_HOVER
	var pressed_fill := COLOR_WARNING if primary else COLOR_BUTTON_PRESSED
	button.add_theme_stylebox_override("normal", _build_flat_stylebox(fill, COLOR_BUTTON_BORDER, 6, 1, Vector4(10.0, 8.0, 10.0, 8.0)))
	button.add_theme_stylebox_override("hover", _build_flat_stylebox(hover_fill, COLOR_BUTTON_BORDER, 6, 1, Vector4(10.0, 8.0, 10.0, 8.0)))
	button.add_theme_stylebox_override("pressed", _build_flat_stylebox(pressed_fill, COLOR_BUTTON_BORDER, 6, 1, Vector4(10.0, 8.0, 10.0, 8.0)))
	button.add_theme_stylebox_override("disabled", _build_flat_stylebox(COLOR_MUTED.darkened(0.25), COLOR_FRAME_BORDER, 6, 1, Vector4(10.0, 8.0, 10.0, 8.0)))
	button.add_theme_color_override("font_color", TEXT_DARK)
	button.add_theme_color_override("font_hover_color", TEXT_DARK)
	button.add_theme_color_override("font_pressed_color", TEXT_DARK)
	button.add_theme_color_override("font_focus_color", TEXT_DARK)
	button.add_theme_color_override("font_disabled_color", TEXT_DISABLED)


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
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = fill_color
	stylebox.border_color = border_color
	stylebox.border_width_left = border_width
	stylebox.border_width_top = border_width
	stylebox.border_width_right = border_width
	stylebox.border_width_bottom = border_width
	stylebox.corner_radius_top_left = radius
	stylebox.corner_radius_top_right = radius
	stylebox.corner_radius_bottom_left = radius
	stylebox.corner_radius_bottom_right = radius
	stylebox.content_margin_left = content_margin.x
	stylebox.content_margin_top = content_margin.y
	stylebox.content_margin_right = content_margin.z
	stylebox.content_margin_bottom = content_margin.w
	return stylebox


static func _build_round_flat_stylebox(fill_color: Color, border_color: Color) -> StyleBoxFlat:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = fill_color
	stylebox.border_color = border_color
	stylebox.border_width_left = 3
	stylebox.border_width_top = 3
	stylebox.border_width_right = 3
	stylebox.border_width_bottom = 3
	stylebox.corner_radius_top_left = 28
	stylebox.corner_radius_top_right = 28
	stylebox.corner_radius_bottom_left = 28
	stylebox.corner_radius_bottom_right = 28
	stylebox.content_margin_left = 12
	stylebox.content_margin_right = 12
	stylebox.content_margin_top = 12
	stylebox.content_margin_bottom = 12
	return stylebox


static func _build_thin_frame_stylebox() -> StyleBoxFlat:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = COLOR_PANEL_ALT
	stylebox.border_color = COLOR_FRAME_BORDER
	stylebox.border_width_left = 1
	stylebox.border_width_top = 1
	stylebox.border_width_right = 1
	stylebox.border_width_bottom = 1
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.corner_radius_bottom_right = 8
	stylebox.content_margin_left = 4
	stylebox.content_margin_right = 4
	stylebox.content_margin_top = 4
	stylebox.content_margin_bottom = 4
	return stylebox
