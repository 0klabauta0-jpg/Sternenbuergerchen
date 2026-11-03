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
	quit(1 if _failed > 0 else 0)


func _test_live_mission_block_labels_use_shared_ids() -> void:
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var mission_identity_label := scene.get_node("TacticalUI/MissionIdentityPanel/MissionIdentityMargin/MissionIdentityVBox/MissionIdentityHeaderLabel") as Label
	var command_label := scene.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandHeaderLabel") as Label
	var fireteam_label := scene.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderRow/FireteamHeaderLabel") as Label
	var strategic_label := scene.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicHeaderLabel") as Label
	var command_grid := scene.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid") as GridContainer
	var legacy_team_button_missing: bool = scene.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/BlueButton") == null and scene.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/GoldButton") == null and scene.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/AllButton") == null

	_assert(mission_identity_label != null and mission_identity_label.text == UI_BLOCK_LABELS_SCRIPT.MISSION_LIVE_TACTICAL_GRID, "Mission HUD shows the shared #15 live tactical label")
	_assert(command_label != null and command_label.text == UI_BLOCK_LABELS_SCRIPT.MISSION_COMMAND_MATRIX, "Mission HUD shows the shared #16 command label")
	_assert(fireteam_label != null and fireteam_label.text == UI_BLOCK_LABELS_SCRIPT.MISSION_SELECTED_FIRETEAM, "Mission HUD shows the shared #17 selected-fireteam label")
	_assert(strategic_label != null and strategic_label.text == UI_BLOCK_LABELS_SCRIPT.MISSION_CONTROL, "Mission HUD shows the shared #18 mission-control label")
	var command_grid_uses_current_contract: bool = command_grid != null and command_grid.columns == 5
	_assert(command_grid_uses_current_contract and legacy_team_button_missing, "Mission command panel keeps #16 command-only and no longer shows old team-selection buttons")

	scene.queue_free()
	await _wait_cleanup_frames()


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
	await _wait_cleanup_frames()


func _test_character_sheet_layout_uses_german_sections_and_core_bars() -> void:
	var screen: Control = FOB_TEST_SCENE.instantiate()
	root.add_child(screen)
	screen.show()
	await process_frame

	screen.call("set_available_units", UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster"))
	await process_frame
	var roster: Array = Array(UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster"))
	var inspected_unit_id := String(Dictionary(roster[0]).get("unit_id", "")) if not roster.is_empty() else ""
	screen.call("_open_character_overlay", inspected_unit_id)
	await process_frame

	var overlay := screen.get_node("CharacterOverlay") as Control
	var overlay_header := screen.get_node("CharacterOverlay/OverlayPanel/OverlayMargin/OverlayVBox/OverlayHeaderRow/OverlayHeaderLabel") as Label
	var content_host := screen.get_node("CharacterOverlay/OverlayPanel/OverlayMargin/OverlayVBox/OverlayScroll/OverlayContentVBox/GeneratedOverlayContent") as VBoxContainer
	var sheet_root := content_host.get_node_or_null("SheetRoot") as VBoxContainer if content_host != null else null
	var values_column := sheet_root.get_node_or_null("CharacterSheetTwoColumnBody/CharacterSheetValuesColumn") if sheet_root != null else null
	var context_column := sheet_root.get_node_or_null("CharacterSheetTwoColumnBody/CharacterSheetContextColumn") if sheet_root != null else null
	var values_section_headers: Array = _collect_section_headers(values_column)
	var context_section_headers: Array = _collect_section_headers(context_column)
	var core_row_labels: Array = []
	var core_bar_count: int = 0
	for core_id in ["accuracy", "speed", "toughness", "awareness", "recognition", "stealth", "discipline", "leadership"]:
		var row := _find_descendant_by_name(values_column, "ReadOnlyMetricRow_%s" % core_id) as HBoxContainer
		var label := row.get_node_or_null("ReadOnlyMetricLabel_%s" % core_id) as Label if row != null else null
		var progress_bar := row.get_node_or_null("ReadOnlyMetricBar_%s" % core_id) as ProgressBar if row != null else null
		if label != null:
			core_row_labels.append(label.text)
		if progress_bar != null:
			core_bar_count += 1

	_assert(overlay != null and overlay.visible, "FOB character overlay opens as a visible sheet")
	_assert(overlay_header != null and overlay_header.is_visible_in_tree() and overlay_header.text == "Charakterbogen", "FOB character overlay shows its localized A5 heading")
	_assert(values_section_headers == [
		"KERNWERTE (0,00 - 1,00):",
		"KOMMUNIKATION:",
		"VERHALTENSPROFIL:",
	], "Character sheet values column keeps the current section order")
	_assert(context_section_headers == [
		"TRAIT:",
		"KURZBESCHREIBUNG:",
		"ABGELEITET:",
	], "Character sheet context column keeps the current section order")
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
	await _wait_cleanup_frames()


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
	var board := craft_card.get_node_or_null("MarginContainer/VBox/HeaderRow/PrimaryActionButton") as Button if craft_card != null else null
	var release := craft_card.get_node_or_null("MarginContainer/VBox/HeaderRow/SecondaryActionButton") as Button if craft_card != null else null
	_assert(board != null and board.text == "Einschiffen" and board.pressed.is_connected(Callable(screen, "_on_transport_craft_boarding_requested").bind("dropship_test")), "Dropship card keeps its localized boarding action")
	_assert(release != null and release.text == "Freigeben" and release.pressed.is_connected(Callable(screen, "_on_transport_craft_mission_stage_requested").bind("dropship_test")), "Dropship card keeps its localized mission staging action")
	_assert(not _array_contains_case_insensitive(button_texts, "tracked"), "Dropship card no longer exposes a legacy tracked button")

	if craft_card != null:
		craft_card.free()
	screen.queue_free()
	await _wait_cleanup_frames()


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
	_collect_section_headers_recursive(host, expected_headers, label_texts)
	return label_texts


func _collect_section_headers_recursive(host: Node, expected_headers: Array, result: Array) -> void:
	for child in host.get_children():
		var label := child as Label
		if label != null and expected_headers.has(label.text):
			result.append(label.text)
		_collect_section_headers_recursive(child, expected_headers, result)


func _find_descendant_by_name(host: Node, target_name: String) -> Node:
	if host == null:
		return null
	if host.name == target_name:
		return host
	for child in host.get_children():
		var match_node := _find_descendant_by_name(child, target_name)
		if match_node != null:
			return match_node
	return null


func _wait_cleanup_frames(frame_count: int = 6) -> void:
	for _frame in range(frame_count):
		await process_frame


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
