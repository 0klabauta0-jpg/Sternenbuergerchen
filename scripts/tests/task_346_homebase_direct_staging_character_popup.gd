extends SceneTree

const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/drop_light_layout_contract.gd")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_346 Homebase Direct Staging Character Popup Verifier ===")
	await _test_direct_staging_layout_contract()
	await _test_fireteam_loadout_and_dropship_contract()
	await _test_character_popup_contract()
	_test_no_absolute_user_paths_in_runtime_files()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_346: FAILED")
		quit(1)
	else:
		print("TASK_346: ALL PASSED")
		quit(0)


func _test_direct_staging_layout_contract() -> void:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame

	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_homebase_layout")
	var info_panel := screen.get_node("Panel/Margin/VBox/ContentRow/InfoPanel") as Control
	var fireteam_panel := screen.get_node("Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel") as Control
	var loadout_panel := screen.get_node("Panel/Margin/VBox/ContentRow/HomebaseLoadoutPanel") as Control
	var aircraft_panel := screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel") as Control
	var popup := screen.get_node("CharacterSheetPopup") as Control

	_assert(not layout.has("character_sheet"), "Homebase layout no longer exposes a fixed character_sheet rect")
	_assert(_node_rect_matches_actual(fireteam_panel, layout.get("fireteams")), "Homebase shows #10 FIRETEAMS in the fixed layout")
	_assert(_node_rect_matches_actual(loadout_panel, layout.get("loadout")), "Homebase shows #13 LOADOUT in the fixed layout")
	_assert(_node_rect_matches_actual(aircraft_panel, layout.get("flightdeck")), "Homebase keeps Flightdeck as fixed staging target")
	_assert(not info_panel.visible, "Fixed right character sheet starts hidden")
	_assert(not popup.visible and bool(popup.get_meta("outside_numbered_window_grid", false)), "Character popup starts closed outside the numbered window grid")
	_assert(bool(fireteam_panel.get_meta("homebase_uses_fob_drop_panel_contract", false)), "Homebase Fireteams reuses the FOB drop panel contract")
	_assert(bool(loadout_panel.get_meta("homebase_uses_fob_drop_panel_contract", false)), "Homebase Loadout reuses the FOB drop panel contract")

	screen.queue_free()
	await process_frame


func _test_fireteam_loadout_and_dropship_contract() -> void:
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
	await process_frame
	await process_frame

	var fireteam_list := screen.get_node("Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel/FireteamMargin/FireteamVBox/FireteamScroll/FireteamList") as VBoxContainer
	var loadout_member_list := screen.get_node("Panel/Margin/VBox/ContentRow/HomebaseLoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutMemberScroll/LoadoutMemberList") as VBoxContainer
	_assert(_contains_meta(fireteam_list, "homebase_direct_fireteam_card"), "#10 renders direct fireteam cards")
	_assert(_count_nodes_with_meta(loadout_member_list, "homebase_direct_loadout_row") == 3, "#13 renders compact loadout rows for the staged fireteam")

	screen.call("_on_homebase_staging_fireteam_dropped", "ft1", "homebase_dropship")
	await process_frame
	await process_frame

	var dropship_panel := screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/DirectDropshipFireteamPanel") as Control
	var snapshot: Dictionary = Dictionary(screen.call("get_homebase_direct_staging_snapshot"))
	_assert(dropship_panel.visible and bool(dropship_panel.get_meta("homebase_uses_fob_drop_panel_contract", false)), "Flightdeck exposes a direct dropship fireteam drop target")
	_assert(bool(snapshot.get("drop_ship_staged", false)), "Homebase direct staging exports a FOB-like drop_ship_staged state")
	_assert(Array(snapshot.get("embarked_unit_ids", [])).size() == 3, "Homebase direct drop state exports embarked unit ids")

	screen.queue_free()
	await process_frame


func _test_character_popup_contract() -> void:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	screen.call("setup_roster", roster, PackedStringArray(["unit_alpha"]))
	await process_frame
	await process_frame

	var fireteam_panel := screen.get_node("Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel") as Control
	var loadout_panel := screen.get_node("Panel/Margin/VBox/ContentRow/HomebaseLoadoutPanel") as Control
	var aircraft_panel := screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel") as Control
	var fireteam_rect_before := Rect2(fireteam_panel.global_position, fireteam_panel.size)
	var loadout_rect_before := Rect2(loadout_panel.global_position, loadout_panel.size)
	var aircraft_rect_before := Rect2(aircraft_panel.global_position, aircraft_panel.size)

	screen.call("_on_compact_card_open_requested", "unit_alpha", null, "roster")
	await process_frame
	await process_frame

	var popup := screen.get_node("CharacterSheetPopup") as Control
	var info_panel := screen.get_node("Panel/Margin/VBox/ContentRow/InfoPanel") as Control
	_assert(popup.visible, "Double-click/open request shows the character sheet popup")
	_assert(not info_panel.visible, "Opening the popup does not re-enable the fixed InfoPanel")
	_assert(_rect_matches_snapshot(fireteam_panel, fireteam_rect_before), "Popup does not move #10 FIRETEAMS")
	_assert(_rect_matches_snapshot(loadout_panel, loadout_rect_before), "Popup does not move #13 LOADOUT")
	_assert(_rect_matches_snapshot(aircraft_panel, aircraft_rect_before), "Popup does not move Flightdeck")

	screen.call("_on_close_sheet_button_pressed")
	await process_frame
	_assert(not popup.visible, "Character sheet popup is closable")

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


func _node_rect_matches_actual(control: Control, rect_variant: Variant) -> bool:
	if control == null or typeof(rect_variant) != TYPE_RECT2I:
		return false
	var rect: Rect2i = rect_variant
	return _approximately_equal(control.global_position.x, float(rect.position.x)) \
		and _approximately_equal(control.global_position.y, float(rect.position.y)) \
		and _approximately_equal(control.size.x, float(rect.size.x)) \
		and _approximately_equal(control.size.y, float(rect.size.y))


func _rect_matches_snapshot(control: Control, expected_rect: Rect2) -> bool:
	return control != null \
		and _approximately_equal(control.global_position.x, expected_rect.position.x) \
		and _approximately_equal(control.global_position.y, expected_rect.position.y) \
		and _approximately_equal(control.size.x, expected_rect.size.x) \
		and _approximately_equal(control.size.y, expected_rect.size.y)


func _contains_meta(root_node: Node, meta_key: String) -> bool:
	return _count_nodes_with_meta(root_node, meta_key) > 0


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


func _read_text_file(file_path: String) -> String:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _approximately_equal(a: float, b: float) -> bool:
	return absf(a - b) <= 0.5


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		print("  FAIL: %s" % message)
