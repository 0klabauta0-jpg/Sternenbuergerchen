extends SceneTree

const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")
const CONTEXTUAL_HELP_POPUP_SCRIPT: GDScript = preload("res://scripts/ui/contextual_help_popup.gd")

const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_381 Homebase Fireteam Loadout Flightdeck Polish Verifier ===")
	await _test_fireteam_cards_embed_compact_loadout_dropdowns()
	await _test_inline_loadout_updates_detail_loadout_and_export()
	await _test_shipcards_accept_fireteam_drag_payloads()
	await _test_character_popup_uses_two_column_sheet()
	_test_contextual_help_popup_widths_are_compact()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_381: FAILED")
		quit(1)
	else:
		print("TASK_381: ALL PASSED")
		quit(0)


func _test_fireteam_cards_embed_compact_loadout_dropdowns() -> void:
	var screen: Control = await _build_screen()
	var fireteam_list := _fireteam_list(screen)
	_assert(_count_nodes_with_meta(fireteam_list, "homebase_fireteam_inline_loadout_row") == 3, "#10 renders one inline loadout row per fireteam member")
	_assert(_count_nodes_with_meta(fireteam_list, "homebase_fireteam_inline_loadout_dropdown") == 9, "#10 exposes armor, primary and secondary dropdowns per member")
	for selector in _collect_inline_selectors(fireteam_list):
		_assert((selector as OptionButton).custom_minimum_size.x <= 70.0 and (selector as OptionButton).custom_minimum_size.y <= 20.0, "#10 inline loadout dropdown stays compact")
	screen.queue_free()
	await process_frame


func _test_inline_loadout_updates_detail_loadout_and_export() -> void:
	var screen: Control = await _build_screen()
	var fireteam_list := _fireteam_list(screen)
	var inline_primary := _find_loadout_selector(fireteam_list, "unit_alpha", "weapon_1") as OptionButton
	var sniper_index := _find_item_index_by_metadata(inline_primary, "sniper")
	_assert(inline_primary != null and sniper_index >= 0, "#10 primary dropdown can select sniper")

	screen.call("_on_homebase_loadout_option_selected", sniper_index, "unit_alpha", "weapon_1", inline_primary)
	await process_frame
	await process_frame

	screen.call("_on_homebase_staging_fireteam_dropped", "ft1", "homebase_dropship")
	await process_frame
	await process_frame
	var detail_list := screen.get_node("Panel/Margin/VBox/ContentRow/HomebaseLoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutMemberScroll/LoadoutMemberList") as VBoxContainer
	var detail_primary := _find_loadout_selector(detail_list, "unit_alpha", "weapon_1") as OptionButton
	var snapshot: Dictionary = Dictionary(screen.call("get_homebase_direct_staging_snapshot"))
	var member_loadouts: Dictionary = Dictionary(snapshot.get("member_loadouts", {}))
	var alpha_loadout: Dictionary = Dictionary(member_loadouts.get("unit_alpha", {}))
	_assert(detail_primary != null and String(detail_primary.get_item_metadata(detail_primary.selected)) == "sniper", "#13 detail loadout mirrors the #10 inline change")
	_assert(String(alpha_loadout.get("weapon_1", "")).strip_edges() == "sniper", "Homebase export uses the changed inline loadout")

	screen.queue_free()
	await process_frame


func _test_shipcards_accept_fireteam_drag_payloads() -> void:
	var screen: Control = await _build_screen()
	var target := _find_shipcard_drop_target(screen, "dropship_alpha") as Control
	var drag_payload := {
		"type": "fob_fireteam_card",
		"fireteam_id": "ft1",
		"source_context": "fireteam_list",
	}
	_assert(target != null and target.has_method("_can_drop_data") and bool(target.call("_can_drop_data", Vector2.ZERO, drag_payload)), "Flightdeck shipcard accepts fireteam drag payloads")
	target.call("_drop_data", Vector2.ZERO, drag_payload)
	await process_frame
	await process_frame

	var snapshot: Dictionary = Dictionary(screen.call("get_homebase_direct_staging_snapshot"))
	_assert(Array(snapshot.get("payload_fireteam_ids", [])).has("ft1"), "Dropping onto a shipcard boards that fireteam")
	_assert(String(snapshot.get("transport_craft_id", "")).strip_edges() == "dropship_alpha", "Shipcard drop selects the target craft for direct staging")

	screen.queue_free()
	await process_frame


func _test_character_popup_uses_two_column_sheet() -> void:
	var screen: Control = await _build_screen()
	screen.call("_on_compact_card_open_requested", "unit_alpha", null, "homebase_fireteam")
	await process_frame
	await process_frame

	var popup := screen.get_node("CharacterSheetPopup") as Control
	_assert(popup.visible, "Character popup opens from a compact card request")
	_assert(popup.find_child("CharacterSheetTwoColumnBody", true, false) != null, "Homebase character popup uses the editor-style two-column sheet")
	_assert(popup.find_child("CharacterSheetValuesColumn", true, false) != null and popup.find_child("CharacterSheetContextColumn", true, false) != null, "Character popup keeps values and context in separate columns")

	screen.queue_free()
	await process_frame


func _test_contextual_help_popup_widths_are_compact() -> void:
	var target_rect := Rect2(Vector2(320.0, 240.0), Vector2(96.0, 48.0))
	var viewport_size := Vector2(1920.0, 1080.0)
	var compact_rect: Rect2 = CONTEXTUAL_HELP_POPUP_SCRIPT.call("calculate_popup_rect", target_rect, viewport_size, false, Vector2.ZERO)
	var detail_rect: Rect2 = CONTEXTUAL_HELP_POPUP_SCRIPT.call("calculate_popup_rect", target_rect, viewport_size, true, Vector2.ZERO)
	_assert(compact_rect.size.x <= 220.0, "Compact contextual help is capped at the narrower manual-test width")
	_assert(detail_rect.size.x <= 260.0, "Detail contextual help is capped at the narrower manual-test width")


func _build_screen() -> Control:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	screen.call("setup_roster", roster, PackedStringArray(["unit_alpha", "unit_bravo", "unit_charlie"]))
	screen.call(
		"set_fireteam_context",
		PackedStringArray(["ft1", "ft1", "ft1"]),
		[
			{
				"id": "ft1",
				"label": "ALPHA",
				"lead_unit_id": "unit_alpha",
				"loadout": "medium",
				"respawn_enabled": false,
			}
		]
	)
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
			}
		],
		{"dropship_alpha": "unit_delta"},
		[],
		[],
		{"dropship_alpha": "homebase"},
		{},
		{},
		[]
	)
	await process_frame
	await process_frame
	return screen


func _fireteam_list(screen: Control) -> VBoxContainer:
	return screen.get_node("Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel/FireteamMargin/FireteamVBox/FireteamScroll/FireteamList") as VBoxContainer


func _find_loadout_selector(root_node: Node, unit_id: String, key: String) -> OptionButton:
	for node in _collect_nodes(root_node):
		if node is OptionButton \
			and String((node as OptionButton).get_meta("homebase_loadout_unit_id", "")).strip_edges() == unit_id \
			and String((node as OptionButton).get_meta("homebase_loadout_key", "")).strip_edges() == key:
			return node as OptionButton
	return null


func _collect_inline_selectors(root_node: Node) -> Array:
	var selectors: Array = []
	for node in _collect_nodes(root_node):
		if node is OptionButton and bool((node as OptionButton).get_meta("homebase_fireteam_inline_loadout_dropdown", false)):
			selectors.append(node)
	return selectors


func _find_shipcard_drop_target(screen: Control, craft_id: String) -> Control:
	var aircraft_panel := screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel") as Control
	for node in _collect_nodes(aircraft_panel):
		if node is Control \
			and bool((node as Control).get_meta("homebase_fireteam_drop_target", false)) \
			and String((node as Control).get_meta("homebase_fireteam_drop_target_id", "")).strip_edges() == craft_id:
			return node as Control
	return null


func _find_item_index_by_metadata(selector: OptionButton, metadata_value: String) -> int:
	if selector == null:
		return -1
	for item_index in range(selector.item_count):
		if String(selector.get_item_metadata(item_index)).strip_edges() == metadata_value:
			return item_index
	return -1


func _count_nodes_with_meta(root_node: Node, meta_key: String) -> int:
	var count := 0
	for node in _collect_nodes(root_node):
		if bool(node.get_meta(meta_key, false)):
			count += 1
	return count


func _collect_nodes(root_node: Node) -> Array:
	var nodes: Array = []
	if root_node == null:
		return nodes
	nodes.append(root_node)
	for child in root_node.get_children():
		nodes.append_array(_collect_nodes(child))
	return nodes


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		print("  FAIL: %s" % message)
