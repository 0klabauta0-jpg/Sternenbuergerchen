extends SceneTree

const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/drop_light_layout_contract.gd")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const PLATFORM_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/platform_large_NW.png"
const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"
const CARGO_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_cargoA_NE.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_179 Homebase Drop Light Fixed FullHD Layout Verifier ===")
	await _test_homebase_fixed_window_positions()
	await _test_homebase_flightdeck_shipcards_are_primary_status_region()
	await _test_homebase_transfer_ghost_cards_remain_in_team_panel()
	_test_no_absolute_user_paths_in_runtime_files()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_179: FAILED")
		quit(1)
	else:
		print("TASK_179: ALL PASSED")
		quit(0)


func _test_homebase_fixed_window_positions() -> void:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame

	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_homebase_layout")
	var target_viewport: Vector2i = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT")
	_assert(screen.custom_minimum_size == Vector2(float(target_viewport.x), float(target_viewport.y)), "Homebase root fixes the FullHD workspace size")
	_assert(bool(screen.get_meta("drop_light_fixed_fullhd_layout", false)), "Homebase root is marked as a drop_light fixed layout")
	_assert(_node_rect_matches_actual(screen.get_node("DropLightTopbar") as Control, layout.get("topbar")), "Homebase topbar uses the fixed contract position and size")
	_assert(_node_rect_matches_actual(screen.get_node("Panel/Margin/VBox/MissionPanel") as Control, layout.get("mission_brief")), "#01 mission brief uses the fixed contract position and size")
	_assert(_node_rect_matches_actual(screen.get_node("Panel/Margin/VBox/ContentRow/RosterPanel") as Control, layout.get("roster")), "#02 roster uses the fixed contract position and size")
	_assert(_node_rect_matches_actual(screen.get_node("Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel") as Control, layout.get("fireteams")), "#10 fireteams uses the fixed contract position and size")
	var loadout_panel := screen.get_node("Panel/Margin/VBox/ContentRow/HomebaseLoadoutPanel") as Control
	_assert(not layout.has("loadout"), "Homebase fixed layout removes the retired #13 loadout window")
	_assert(not loadout_panel.visible and bool(loadout_panel.get_meta("homebase_loadout_window_retired", false)), "#13 loadout is retired because #10 owns inline loadout controls")
	_assert(_node_rect_matches_actual(screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel") as Control, layout.get("flightdeck")), "#05 flightdeck uses the fixed contract position and size")

	var info_panel := screen.get_node("Panel/Margin/VBox/ContentRow/InfoPanel") as Control
	var legacy_team_panel := screen.get_node("Panel/Margin/VBox/ContentRow/TeamPanel") as Control
	var popup := screen.get_node("CharacterSheetPopup") as Control
	_assert(not info_panel.visible and bool(info_panel.get_meta("homebase_legacy_character_sheet_window_disabled", false)), "Homebase character sheet is not visible as a fixed window")
	_assert(not legacy_team_panel.visible and bool(legacy_team_panel.get_meta("homebase_legacy_transfer_window_disabled", false)), "Homebase legacy transfer panel is disabled for direct staging")
	_assert(not popup.visible and _node_rect_matches_actual(popup, layout.get("character_popup")), "Character popup starts closed and keeps its floating rect")
	_assert(screen.get_node("Panel/Margin/VBox/ContentRow/RosterPanel/RosterMargin/RosterVBox/RosterScroll") is ScrollContainer, "Roster keeps long content in a targeted scroll area")
	_assert(screen.get_node("Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel/FireteamMargin/FireteamVBox/FireteamScroll") is ScrollContainer, "Fireteams keeps long content in a targeted scroll area")
	_assert(screen.get_node("CharacterSheetPopup/PopupPanel/PopupMargin/PopupVBox/PopupScroll") is ScrollContainer, "Character popup keeps long content in a targeted scroll area")

	screen.queue_free()
	await process_frame


func _test_homebase_flightdeck_shipcards_are_primary_status_region() -> void:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	screen.call("setup_roster", UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster"))
	screen.call(
		"set_transport_state",
		[
			{
				"craft_id": "dropship_alpha",
				"craft_type": "dropship",
				"display_name": "Dropship",
				"texture_path": DROPSHIP_TEXTURE_PATH,
				"supports_cargo": false,
				"cargo_options": [],
			},
			{
				"craft_id": "cargo_alpha",
				"craft_type": "craft_cargoB",
				"display_name": "Frachter",
				"texture_path": CARGO_TEXTURE_PATH,
				"supports_cargo": true,
				"cargo_options": [
					{"cargo_id": "", "display_name": "No Cargo"},
					{"cargo_id": "rover", "display_name": "Rover"},
				],
			},
		],
		{"dropship_alpha": "unit_alpha", "cargo_alpha": "unit_bravo"},
		[],
		[
			{
				"craft_id": "cargo_alpha",
				"pilot_unit_id": "unit_bravo",
				"duration_seconds": 12.0,
				"elapsed_seconds": 4.0,
			},
		],
		{"dropship_alpha": "homebase", "cargo_alpha": "transit"},
		{"cargo_alpha": "rover"},
		{"cargo_alpha": "rover"},
		[]
	)
	await process_frame
	await process_frame

	var stage_panel := screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/DropLightFlightdeckStage") as PanelContainer
	var pad_stage := stage_panel.get_node("Margin/PadStage") as Control
	var shipcards_scroll := screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/ShipCardsScroll") as ScrollContainer
	var shipcards_list := screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/ShipCardsScroll/ShipCardsList") as VBoxContainer
	var deck_activity_scroll := screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftTransfersScroll") as ScrollContainer
	var snapshot: Dictionary = Dictionary(screen.call("get_aircraft_panel_snapshot"))
	_assert(stage_panel != null and bool(stage_panel.get_meta("drop_light_read_only_visual_stage", false)), "Homebase keeps the legacy visual stage node for compatibility")
	_assert(stage_panel != null and not stage_panel.visible and bool(stage_panel.get_meta("homebase_compact_status_hidden", false)), "Homebase hides the old empty flightdeck stage")
	_assert(stage_panel.mouse_filter == Control.MOUSE_FILTER_IGNORE and pad_stage.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Flightdeck visual stage does not take input away from existing controls")
	_assert(shipcards_scroll.visible and bool(shipcards_scroll.get_meta("homebase_primary_status_region", false)), "Homebase shipcards are the primary flightdeck status region")
	_assert(shipcards_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED and bool(shipcards_scroll.get_meta("homebase_shipcards_fit_without_horizontal_scroll", false)), "Homebase flightdeck shipcards fit without a horizontal scrollbar")
	_assert(deck_activity_scroll != null and not deck_activity_scroll.visible, "Homebase hides the old deck activity window")
	_assert(bool(snapshot.get("shipcards_are_primary_status", false)), "Homebase snapshot declares shipcards as the status truth")
	_assert(not bool(snapshot.get("flightdeck_stage_visible", true)), "Homebase snapshot reports hidden stage")
	_assert(not bool(snapshot.get("deck_activity_visible", true)), "Homebase snapshot reports hidden deck activity")
	_assert(not _contains_button(pad_stage), "Flightdeck visual stage introduces no unbound action buttons")
	_assert(_contains_texture_path(shipcards_list, DROPSHIP_TEXTURE_PATH), "Homebase shipcards keep using project dropship assets")
	_assert(_contains_texture_path(shipcards_list, CARGO_TEXTURE_PATH), "Homebase shipcards keep using project cargo craft assets")
	_assert(_max_texture_min_size(shipcards_list, DROPSHIP_TEXTURE_PATH).x >= 248.0 and _max_texture_min_size(shipcards_list, DROPSHIP_TEXTURE_PATH).y >= 164.0, "Homebase dropship image uses a cropped top-left shipcard size")
	_assert(_shipcard_visuals_are_top_left_anchored(shipcards_list), "Homebase shipcard visuals use a shifted top-left deck anchor")
	_assert(_shipcard_actions_top_aligned(shipcards_list), "Homebase shipcard action buttons are top-aligned")
	var aircraft_selector := screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftSelectorRow/AircraftSelector") as OptionButton
	var shipcard_cargo_selector := _find_first_option_button(shipcards_list)
	_assert(aircraft_selector != null and bool(aircraft_selector.get_meta("homebase_flightdeck_dropdown_unclipped", false)), "Homebase flightdeck aircraft dropdown is marked as unclipped")
	_assert(shipcard_cargo_selector != null and bool(shipcard_cargo_selector.get_meta("homebase_flightdeck_dropdown_unclipped", false)), "Homebase shipcard cargo dropdown is marked as unclipped")
	_assert(shipcard_cargo_selector != null and shipcard_cargo_selector.get_popup() != null and bool(shipcard_cargo_selector.get_popup().get_meta("homebase_flightdeck_dropdown_unclipped", false)), "Homebase shipcard cargo popup carries the unclipped dropdown policy")

	screen.queue_free()
	await process_frame


func _test_homebase_transfer_ghost_cards_remain_in_team_panel() -> void:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	var transfer_units: Array = [Dictionary(roster[0]).duplicate(true), Dictionary(roster[1]).duplicate(true)]
	screen.call("setup_roster", [], PackedStringArray())
	screen.call(
		"set_transport_state",
		[],
		{},
		[
			{
				"transfer_id": "team_test",
				"unit_ids": PackedStringArray(["unit_alpha", "unit_bravo"]),
				"unit_profiles": transfer_units,
				"duration_seconds": 12.0,
				"elapsed_seconds": 6.0,
			},
		],
		[],
		{},
		{},
		{},
		[]
	)
	await process_frame
	await process_frame

	var selected_team_list := screen.get_node("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamDropPanel/DropMargin/DropVBox/SelectedTeamScroll/SelectedTeamList") as VBoxContainer
	var ghost_cards: Array = _collect_cards_by_source_context(selected_team_list, "transfer_ghost")
	var first_display_name: String = String(Dictionary(roster[0]).get("display_name", "")).strip_edges()
	_assert(ghost_cards.size() == 2, "Legacy transfer panel keeps transferred operators as compatibility ghost cards")
	_assert(_cards_have_visible_progress(ghost_cards, 50.0), "Legacy transfer ghost cards keep the shared transit progress")
	_assert(_cards_contain_display_name(ghost_cards, first_display_name), "Legacy transfer ghost cards keep the real operator profile snapshot")

	screen.queue_free()
	await process_frame


func _test_no_absolute_user_paths_in_runtime_files() -> void:
	for file_path in [
		"res://scripts/meta/homebase_screen.gd",
		"res://scripts/meta/meta_layer_flow.gd",
		"res://scripts/meta/drop_light_layout_contract.gd",
	]:
		var text := _read_text_file(file_path)
		_assert(not text.contains("C:" + "\\" + "Users" + "\\") and not text.contains("C:" + "/" + "Users" + "/"), "%s contains no absolute user asset path" % file_path)
	for asset_path in [PLATFORM_TEXTURE_PATH, DROPSHIP_TEXTURE_PATH, CARGO_TEXTURE_PATH]:
		_assert(ResourceLoader.exists(asset_path), "%s exists inside the project" % asset_path)


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


func _approximately_equal(a: float, b: float) -> bool:
	return absf(a - b) <= 0.5


func _contains_texture_path(root_node: Node, expected_path: String) -> bool:
	for node in _collect_nodes(root_node):
		var texture_rect := node as TextureRect
		if texture_rect == null or texture_rect.texture == null:
			continue
		if texture_rect.texture.resource_path == expected_path:
			return true
	return false


func _max_texture_min_size(root_node: Node, expected_path: String) -> Vector2:
	var max_size := Vector2.ZERO
	for node in _collect_nodes(root_node):
		var texture_rect := node as TextureRect
		if texture_rect == null or texture_rect.texture == null:
			continue
		if texture_rect.texture.resource_path != expected_path:
			continue
		if texture_rect.custom_minimum_size.x * texture_rect.custom_minimum_size.y > max_size.x * max_size.y:
			max_size = texture_rect.custom_minimum_size
	return max_size


func _shipcard_visuals_are_top_left_anchored(root_node: Node) -> bool:
	var checked_count := 0
	for node in _collect_nodes(root_node):
		var texture_rect := node as TextureRect
		if texture_rect == null or texture_rect.name != "ShipTexture":
			continue
		if String(texture_rect.get_meta("homebase_shipcard_visual_anchor", "")) != "left_top":
			return false
		if texture_rect.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_CENTERED:
			return false
		if not bool(texture_rect.get_meta("homebase_shipcard_visual_enlarged", false)):
			return false
		if not bool(texture_rect.get_meta("homebase_shipcard_visual_crop_compensates_transparency", false)):
			return false
		if texture_rect.position.x > 0.0 or texture_rect.position.y > 0.0:
			return false
		checked_count += 1
	return checked_count > 0


func _shipcard_actions_top_aligned(root_node: Node) -> bool:
	var checked_count := 0
	for node in _collect_nodes(root_node):
		var action_column := node as VBoxContainer
		if action_column == null or action_column.name != "ShipActionColumn":
			continue
		if action_column.alignment != BoxContainer.ALIGNMENT_BEGIN:
			return false
		if not bool(action_column.get_meta("homebase_actions_top_aligned", false)):
			return false
		checked_count += 1
	return checked_count > 0


func _find_first_option_button(root_node: Node) -> OptionButton:
	for node in _collect_nodes(root_node):
		var option_button := node as OptionButton
		if option_button != null:
			return option_button
	return null


func _collect_cards_by_source_context(root_node: Node, expected_context: String) -> Array:
	var cards: Array = []
	for node in _collect_nodes(root_node):
		if not node.has_method("get_source_context"):
			continue
		if String(node.call("get_source_context")) == expected_context:
			cards.append(node)
	return cards


func _cards_have_visible_progress(cards: Array, expected_value: float) -> bool:
	for card_variant in cards:
		var card := card_variant as Node
		if card == null:
			return false
		var progress_bar := card.get_node_or_null("Margin/HBox/TextVBox/ProgressBar") as ProgressBar
		if progress_bar == null or not progress_bar.visible:
			return false
		if absf(float(progress_bar.value) - expected_value) > 0.5:
			return false
	return not cards.is_empty()


func _cards_contain_display_name(cards: Array, expected_display_name: String) -> bool:
	for card_variant in cards:
		var card := card_variant as Node
		if card == null or not card.has_method("get_profile"):
			continue
		var profile = card.call("get_profile")
		if profile != null and String(profile.display_name).strip_edges() == expected_display_name:
			return true
	return false


func _contains_button(root_node: Node) -> bool:
	for node in _collect_nodes(root_node):
		if node is Button:
			return true
	return false


func _collect_nodes(root_node: Node) -> Array:
	var nodes: Array = []
	if root_node == null:
		return nodes
	nodes.append(root_node)
	for child in root_node.get_children():
		nodes.append_array(_collect_nodes(child))
	return nodes


func _read_text_file(file_path: String) -> String:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		print("  FAIL: %s" % message)
