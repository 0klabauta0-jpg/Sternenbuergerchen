extends SceneTree

const FOB_TEST_SCENE: PackedScene = preload("res://scenes/meta/fob_test_screen.tscn")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")
const UI_BLOCK_LABELS_SCRIPT: GDScript = preload("res://scripts/meta/ui_block_labels.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_096 Recovery Verifier ===")
	await _test_live_mission_block_labels_use_shared_ids()
	await _test_fob_transit_card_is_disabled_and_shows_progress()
	await _test_character_sheet_layout_uses_german_sections_and_core_bars()
	await _test_transport_craft_cards_do_not_expose_tracked_button()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_live_mission_block_labels_use_shared_ids() -> void:
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var mission_identity_label := scene.get_node("TacticalUI/MissionIdentityPanel/MissionIdentityMargin/MissionIdentityVBox/MissionIdentityHeaderLabel") as Label
	var command_label := scene.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandHeaderLabel") as Label
	var fireteam_label := scene.get_node("TacticalUI/FireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderRow/FireteamHeaderLabel") as Label
	var strategic_label := scene.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicHeaderLabel") as Label
	var command_grid := scene.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid") as GridContainer
	var legacy_team_button_missing: bool = scene.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/BlueButton") == null and scene.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/GoldButton") == null and scene.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/AllButton") == null

	_assert(mission_identity_label != null and mission_identity_label.text == UI_BLOCK_LABELS_SCRIPT.MISSION_LIVE_TACTICAL_GRID, "Mission HUD shows the shared #15 live tactical label")
	_assert(command_label != null and command_label.text == UI_BLOCK_LABELS_SCRIPT.MISSION_COMMAND_MATRIX, "Mission HUD shows the shared #16 command label")
	_assert(fireteam_label != null and fireteam_label.text == UI_BLOCK_LABELS_SCRIPT.MISSION_SELECTED_FIRETEAM, "Mission HUD shows the shared #17 selected-fireteam label")
	_assert(strategic_label != null and strategic_label.text == UI_BLOCK_LABELS_SCRIPT.MISSION_CONTROL, "Mission HUD shows the shared #18 mission-control label")
	_assert(command_grid != null and command_grid.columns == 3 and legacy_team_button_missing, "Mission command panel keeps #16 command-only and no longer shows old team-selection buttons")

	scene.queue_free()
	await process_frame


func _test_fob_transit_card_is_disabled_and_shows_progress() -> void:
	var screen: Control = FOB_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	var transit_unit: Dictionary = _build_homebase_unit("unit_alpha")
	transit_unit["is_transit_to_fob"] = true
	transit_unit["transfer_progress"] = 42.0
	transit_unit["transfer_eta_seconds"] = 11
	screen.call("set_available_units", [transit_unit])
	await process_frame

	var operator_list := screen.get_node("Panel/Margin/VBox/ContentRow/AvailablePanel/AvailableMargin/AvailableVBox/AvailableScroll/AvailableList") as VBoxContainer
	var transit_card := operator_list.get_child(0) as PanelContainer if operator_list != null and operator_list.get_child_count() > 0 else null
	var progress_bar := transit_card.get_node("Margin/HBox/TextVBox/ProgressBar") as ProgressBar if transit_card != null else null
	var secondary_label := transit_card.get_node("Margin/HBox/TextVBox/DataBLabel") as Label if transit_card != null else null

	_assert(transit_card != null, "FOB renders a compact operator card for an inbound transit unit")
	_assert(progress_bar != null and progress_bar.visible and is_equal_approx(progress_bar.value, 42.0), "Inbound FOB transit card shows its progress bar and progress value")
	_assert(secondary_label != null and secondary_label.text.contains("ETA 11s") and secondary_label.text.contains("Progress 42%"), "Inbound FOB transit card shows ETA and progress text")
	_assert(transit_card != null and transit_card.mouse_default_cursor_shape == Control.CURSOR_ARROW, "Inbound FOB transit card is visibly disabled while the operator is still in transit")

	screen.queue_free()
	await process_frame


func _test_character_sheet_layout_uses_german_sections_and_core_bars() -> void:
	var screen: Control = FOB_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	screen.call("set_available_units", UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster"))
	await process_frame
	screen.call("_open_character_overlay", "unit_delta")
	await process_frame

	var overlay := screen.get_node("CharacterOverlay") as Control
	var overlay_header := screen.get_node("CharacterOverlay/OverlayPanel/OverlayMargin/OverlayVBox/OverlayHeaderRow/OverlayHeaderLabel") as Label
	var content_host := screen.get_node("CharacterOverlay/OverlayPanel/OverlayMargin/OverlayVBox/OverlayScroll/OverlayContentVBox/GeneratedOverlayContent") as VBoxContainer
	var sheet_root := content_host.get_node_or_null("SheetRoot") as VBoxContainer if content_host != null else null
	var section_headers: Array = _collect_section_headers(sheet_root)
	var core_rows := sheet_root.get_child(6) as VBoxContainer if sheet_root != null and sheet_root.get_child_count() > 6 else null
	var core_row_labels: Array = []
	var core_bar_count: int = 0
	if core_rows != null:
		for row_variant in core_rows.get_children():
			var row := row_variant as HBoxContainer
			if row == null or row.get_child_count() < 3:
				continue
			var label := row.get_child(0) as Label
			var progress_bar := row.get_child(1) as ProgressBar
			if label != null:
				core_row_labels.append(label.text)
			if progress_bar != null:
				core_bar_count += 1

	_assert(overlay != null and overlay.visible, "FOB character overlay opens as a visible sheet")
	_assert(overlay_header != null and overlay_header.text == UI_BLOCK_LABELS_SCRIPT.CHARACTER_OVERLAY, "Character overlay uses the shared #20 block label")
	_assert(section_headers == [
		"TRAIT:",
		"KURZBESCHREIBUNG:",
		"KERNWERTE (0,00 - 1,00):",
		"KOMMUNIKATION:",
		"ABGELEITET:",
		"VERHALTENSPROFIL:",
	], "Character sheet keeps the German section order from TASK_096")
	_assert(core_row_labels == [
		"Accuracy:",
		"Speed:",
		"Toughness:",
		"Awareness:",
		"Recognition:",
		"Stealth:",
		"Discipline:",
		"Leadership:",
	], "Character sheet core-values block keeps the expected stat order")
	_assert(core_bar_count == 8, "Character sheet renders one progress bar for each core value")

	screen.queue_free()
	await process_frame


func _test_transport_craft_cards_do_not_expose_tracked_button() -> void:
	var screen: Control = FOB_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	var craft_card := screen.call(
		"_build_transport_craft_card",
		{
			"craft_id": "dropship_test",
			"display_name": "Dropship Test",
			"visible_in_fob": true,
			"is_boardable": true,
			"craft_type": "dropship",
		}
	) as Control
	var button_texts: Array = _collect_button_texts(craft_card)

	_assert(craft_card != null, "FOB can still build a shared dropship card for verification")
	_assert(button_texts.has("Board"), "Dropship card keeps the boarding action")
	_assert(button_texts.has("Send"), "Dropship card keeps the mission-send action")
	_assert(not _array_contains_case_insensitive(button_texts, "tracked"), "Dropship card no longer exposes a legacy tracked button")

	if craft_card != null:
		craft_card.free()
	screen.queue_free()
	await process_frame


func _build_homebase_unit(unit_id: String) -> Dictionary:
	for unit_variant in UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster"):
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit_data: Dictionary = Dictionary(unit_variant).duplicate(true)
		if String(unit_data.get("unit_id", "")).strip_edges() == unit_id:
			return unit_data
	return {}


func _collect_section_headers(host: Node) -> Array:
	var label_texts: Array = []
	var expected_headers: Array = [
		"TRAIT:",
		"KURZBESCHREIBUNG:",
		"KERNWERTE (0,00 - 1,00):",
		"KOMMUNIKATION:",
		"ABGELEITET:",
		"VERHALTENSPROFIL:",
	]
	if host == null:
		return label_texts
	for child in host.get_children():
		var label := child as Label
		if label == null:
			continue
		if expected_headers.has(label.text):
			label_texts.append(label.text)
	return label_texts


func _collect_button_texts(host: Node) -> Array:
	var button_texts: Array = []
	if host == null:
		return button_texts
	var button := host as Button
	if button != null:
		var button_text: String = button.text.strip_edges()
		if not button_text.is_empty():
			button_texts.append(button_text)
	for child in host.get_children():
		button_texts.append_array(_collect_button_texts(child))
	return button_texts


func _array_contains_case_insensitive(values: Array, needle: String) -> bool:
	var normalized_needle: String = needle.strip_edges().to_lower()
	for value_variant in values:
		if String(value_variant).strip_edges().to_lower().contains(normalized_needle):
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
