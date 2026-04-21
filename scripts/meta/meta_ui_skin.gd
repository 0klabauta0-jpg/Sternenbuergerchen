class_name MetaUISkin
extends RefCounted

const FRAME_TEXTURE: Texture2D = preload("res://Assets/kenney_ui-pack/PNG/Grey/Default/button_rectangle_depth_border.png")
const PANEL_TEXTURE: Texture2D = preload("res://Assets/kenney_ui-pack/PNG/Grey/Default/button_rectangle_depth_gradient.png")
const BUTTON_TEXTURE: Texture2D = preload("res://Assets/kenney_ui-pack/PNG/Grey/Default/button_rectangle_gloss.png")
const BUTTON_DISABLED_TEXTURE: Texture2D = preload("res://Assets/kenney_ui-pack/PNG/Grey/Default/button_rectangle_flat.png")
const HEADER_TEXTURE: Texture2D = preload("res://Assets/kenney_ui-pack-space-expansion/PNG/Grey/Default/button_square_header_large_rectangle.png")
const MISSION_HEADER_TEXTURE: Texture2D = preload("res://Assets/kenney_ui-pack-space-expansion/PNG/Grey/Default/button_square_header_blade_rectangle_screws.png")
const TACTICAL_FRAME_TEXTURE: Texture2D = preload("res://Assets/kenney_ui-pack-space-expansion/PNG/Grey/Default/bar_square_large.png")
const TACTICAL_PANEL_TEXTURE: Texture2D = preload("res://Assets/kenney_ui-pack-space-expansion/PNG/Grey/Default/bar_square_gloss_large.png")
const TACTICAL_BUTTON_TEXTURE: Texture2D = preload("res://Assets/kenney_ui-pack-space-expansion/PNG/Grey/Default/button_square_header_small_rectangle_screws.png")
const TACTICAL_BUTTON_ACTIVE_TEXTURE: Texture2D = preload("res://Assets/kenney_ui-pack-space-expansion/PNG/Grey/Default/button_square_header_notch_rectangle_screws.png")
const TRANSFER_READY_TEXTURE: Texture2D = preload("res://Assets/kenney_ui-pack-space-expansion/PNG/Green/Default/button_square_header_blade_rectangle_screws.png")
const TRANSFER_PRESSED_TEXTURE: Texture2D = preload("res://Assets/kenney_ui-pack-space-expansion/PNG/Yellow/Default/button_square_header_blade_rectangle_screws.png")

const TEXT_HEADER := Color(0.17, 0.19, 0.24, 1.0)
const TEXT_BODY := Color(0.24, 0.27, 0.33, 1.0)
const TEXT_MUTED := Color(0.34, 0.37, 0.43, 1.0)
const TEXT_DISABLED := Color(0.47, 0.49, 0.53, 1.0)


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
		"Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoScroll/InfoVBox/SheetNameLabel",
		"Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoScroll/InfoVBox/SheetIdentityLabel",
		"Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoScroll/InfoVBox/SheetRoleLabel",
		"Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoScroll/InfoVBox/SheetStatusLabel",
		"Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoScroll/InfoVBox/SheetSkillLabel",
		"Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoScroll/InfoVBox/SheetTraitLabel",
		"Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoScroll/InfoVBox/SheetLoadoutLabel",
		"Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoScroll/InfoVBox/SheetBioLabel",
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
		"CharacterOverlay/OverlayPanel/OverlayMargin/OverlayVBox/OverlayScroll/OverlayContentVBox/OverlayNameLabel",
		"CharacterOverlay/OverlayPanel/OverlayMargin/OverlayVBox/OverlayScroll/OverlayContentVBox/OverlayIdentityLabel",
		"CharacterOverlay/OverlayPanel/OverlayMargin/OverlayVBox/OverlayScroll/OverlayContentVBox/OverlayRoleLabel",
		"CharacterOverlay/OverlayPanel/OverlayMargin/OverlayVBox/OverlayScroll/OverlayContentVBox/OverlayStatusLabel",
		"CharacterOverlay/OverlayPanel/OverlayMargin/OverlayVBox/OverlayScroll/OverlayContentVBox/OverlaySkillLabel",
		"CharacterOverlay/OverlayPanel/OverlayMargin/OverlayVBox/OverlayScroll/OverlayContentVBox/OverlayTraitLabel",
		"CharacterOverlay/OverlayPanel/OverlayMargin/OverlayVBox/OverlayScroll/OverlayContentVBox/OverlayLoadoutLabel",
		"CharacterOverlay/OverlayPanel/OverlayMargin/OverlayVBox/OverlayScroll/OverlayContentVBox/OverlayBioLabel",
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
			panel.add_theme_stylebox_override("panel", _build_stylebox(MISSION_HEADER_TEXTURE, 14, 14, 12, 12))
		"panel":
			panel.add_theme_stylebox_override("panel", _build_stylebox(TACTICAL_PANEL_TEXTURE, 16, 16, 14, 14))
		_:
			panel.add_theme_stylebox_override("panel", _build_stylebox(TACTICAL_FRAME_TEXTURE, 16, 16, 14, 14))


static func style_tactical_button(button: Button, is_active: bool = false) -> void:
	if button == null:
		return

	button.add_theme_stylebox_override("normal", _build_stylebox(TACTICAL_BUTTON_ACTIVE_TEXTURE if is_active else TACTICAL_BUTTON_TEXTURE, 12, 12, 10, 10))
	button.add_theme_stylebox_override("hover", _build_stylebox(TACTICAL_BUTTON_ACTIVE_TEXTURE, 12, 12, 10, 10))
	button.add_theme_stylebox_override("pressed", _build_stylebox(TACTICAL_FRAME_TEXTURE, 14, 14, 12, 12))
	button.add_theme_stylebox_override("disabled", _build_stylebox(BUTTON_DISABLED_TEXTURE, 10, 10, 10, 10))
	button.add_theme_color_override("font_color", TEXT_HEADER)
	button.add_theme_color_override("font_hover_color", TEXT_HEADER)
	button.add_theme_color_override("font_pressed_color", TEXT_HEADER)
	button.add_theme_color_override("font_focus_color", TEXT_HEADER)
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

	var normal := _build_round_flat_stylebox(Color(0.76, 0.15, 0.15, 1.0), Color(0.98, 0.82, 0.82, 1.0))
	var hover := _build_round_flat_stylebox(Color(0.87, 0.22, 0.22, 1.0), Color(1.0, 0.90, 0.90, 1.0))
	var pressed := _build_round_flat_stylebox(Color(0.58, 0.08, 0.08, 1.0), Color(0.90, 0.72, 0.72, 1.0))
	var disabled := _build_round_flat_stylebox(Color(0.33, 0.18, 0.18, 1.0), Color(0.50, 0.34, 0.34, 1.0))
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

	button.add_theme_stylebox_override("normal", _build_stylebox(TRANSFER_READY_TEXTURE if is_ready else MISSION_HEADER_TEXTURE, 14, 14, 12, 12))
	button.add_theme_stylebox_override("hover", _build_stylebox(TRANSFER_READY_TEXTURE if is_ready else BUTTON_TEXTURE, 14, 14, 12, 12))
	button.add_theme_stylebox_override("pressed", _build_stylebox(TRANSFER_PRESSED_TEXTURE, 14, 14, 12, 12))
	button.add_theme_stylebox_override("disabled", _build_stylebox(BUTTON_DISABLED_TEXTURE, 10, 10, 10, 10))
	button.add_theme_color_override("font_color", TEXT_HEADER)
	button.add_theme_color_override("font_hover_color", TEXT_HEADER)
	button.add_theme_color_override("font_pressed_color", TEXT_HEADER)
	button.add_theme_color_override("font_focus_color", TEXT_HEADER)
	button.add_theme_color_override("font_disabled_color", TEXT_DISABLED)


static func _apply_panel_style(screen: Control, path: String, variant: String) -> void:
	var panel := screen.get_node_or_null(path) as PanelContainer
	if panel == null:
		return

	match variant:
		"header":
			panel.add_theme_stylebox_override("panel", _build_stylebox(HEADER_TEXTURE, 12, 12, 10, 10))
		"mission_header":
			panel.add_theme_stylebox_override("panel", _build_stylebox(MISSION_HEADER_TEXTURE, 14, 14, 12, 12))
		"thin_frame":
			panel.add_theme_stylebox_override("panel", _build_thin_frame_stylebox())
		"panel":
			panel.add_theme_stylebox_override("panel", _build_stylebox(PANEL_TEXTURE, 10, 10, 10, 10))
		_:
			panel.add_theme_stylebox_override("panel", _build_stylebox(FRAME_TEXTURE, 10, 10, 10, 10))


static func _apply_button_style(button: Button, primary: bool) -> void:
	if button == null:
		return

	button.add_theme_stylebox_override("normal", _build_stylebox(HEADER_TEXTURE if primary else PANEL_TEXTURE, 12, 12, 10, 10))
	button.add_theme_stylebox_override("hover", _build_stylebox(BUTTON_TEXTURE, 10, 10, 10, 10))
	button.add_theme_stylebox_override("pressed", _build_stylebox(FRAME_TEXTURE, 10, 10, 10, 10))
	button.add_theme_stylebox_override("disabled", _build_stylebox(BUTTON_DISABLED_TEXTURE, 10, 10, 10, 10))
	button.add_theme_color_override("font_color", TEXT_HEADER)
	button.add_theme_color_override("font_hover_color", TEXT_HEADER)
	button.add_theme_color_override("font_pressed_color", TEXT_HEADER)
	button.add_theme_color_override("font_focus_color", TEXT_HEADER)
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


static func _build_stylebox(
	texture: Texture2D,
	margin_left: float,
	margin_right: float,
	margin_top: float,
	margin_bottom: float
) -> StyleBoxTexture:
	var stylebox := StyleBoxTexture.new()
	stylebox.texture = texture
	stylebox.texture_margin_left = margin_left
	stylebox.texture_margin_right = margin_right
	stylebox.texture_margin_top = margin_top
	stylebox.texture_margin_bottom = margin_bottom
	stylebox.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	stylebox.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
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
	stylebox.bg_color = Color(0.11, 0.14, 0.16, 1.0)
	stylebox.border_color = Color(0.33, 0.39, 0.45, 1.0)
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