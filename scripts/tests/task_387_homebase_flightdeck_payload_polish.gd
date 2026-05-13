extends SceneTree

const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_387 Homebase Flightdeck Payload Polish Verifier ===")
	await _test_final_boarding_refreshes_last_operator()
	await _test_payload_card_drags_back_to_fireteam_panel()
	await _test_inline_loadout_dropdowns_have_bounded_weapon_icons()
	await _test_shipcard_payload_is_clean_and_staging_is_folded()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_387: FAILED")
		quit(1)
	else:
		print("TASK_387: ALL PASSED")
		quit(0)


func _test_final_boarding_refreshes_last_operator() -> void:
	var screen: Control = await _build_screen()
	_drop_fireteam_on_shipcard(screen, "ft1", "dropship_alpha")
	await process_frame
	await process_frame

	var total_seconds: float = float(screen.call("_debug_get_homebase_fireteam_boarding_total_seconds", "ft1"))
	screen.call("_advance_homebase_direct_boarding", total_seconds)
	await process_frame
	await process_frame

	var payload_panel := _find_shipcard_payload_panel(screen, "dropship_alpha")
	var payload_card := _find_payload_fireteam_card(screen, "ft1")
	var drop_state: Dictionary = Dictionary(screen.call("build_homebase_direct_drop_state"))
	_assert(payload_panel != null and int(payload_panel.get_meta("homebase_direct_boarded_operator_count", -1)) == 3, "Final process refresh shows all three operators boarded")
	_assert(payload_card != null and float(payload_card.get_meta("homebase_direct_payload_boarding_progress", 0.0)) >= 100.0, "Payload card reaches 100 percent after exact final interval")
	_assert(_member_progress(payload_card, "unit_charlie") >= 100.0, "Last operator row reaches 100 percent")
	_assert(bool(drop_state.get("drop_ship_staged", false)), "Direct drop state is launch-ready after the last operator boards")

	screen.queue_free()
	await process_frame


func _test_payload_card_drags_back_to_fireteam_panel() -> void:
	var screen: Control = await _build_screen()
	_drop_fireteam_on_shipcard(screen, "ft1", "dropship_alpha")
	await process_frame
	await process_frame

	var payload_card := _find_payload_fireteam_card(screen, "ft1")
	var fireteam_panel := screen.get_node("Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel") as Control
	var drag_payload: Dictionary = {
		"type": "fob_fireteam_card",
		"fireteam_id": "ft1",
		"source_context": "dropship_wait",
	}
	_assert(payload_card != null and _find_fireteam_panel_card(screen, "ft1") == null, "Payload fireteam has a single visual owner in the Dropship before drag-out")
	_assert(payload_card != null and payload_card.has_method("_get_drag_data"), "Payload fireteam card remains a fireteam drag source")
	_assert(fireteam_panel.has_method("_can_drop_data") and bool(fireteam_panel.call("_can_drop_data", Vector2.ZERO, drag_payload)), "#10 FIRETEAMS accepts the Dropship fireteam drag payload")

	fireteam_panel.call("_drop_data", Vector2.ZERO, drag_payload)
	await process_frame
	await process_frame

	_assert(_find_payload_fireteam_card(screen, "ft1") == null, "Dropping the payload card on #10 removes it from the Dropship")
	_assert(_find_fireteam_panel_card(screen, "ft1") != null, "Dropping the payload card on #10 returns the fireteam card to FIRETEAMS")

	screen.queue_free()
	await process_frame


func _test_inline_loadout_dropdowns_have_bounded_weapon_icons() -> void:
	var screen: Control = await _build_screen()
	var fireteam_list := _fireteam_list(screen)
	var selector := _find_loadout_selector(fireteam_list, "unit_alpha", "weapon_1") as OptionButton
	var smg_index := _find_item_index_by_metadata(selector, "smg")
	_assert(selector != null and selector.custom_minimum_size.x <= 70.0 and selector.custom_minimum_size.y <= 20.0, "Inline loadout dropdown keeps its compact size")
	_assert(selector != null and int(selector.get_meta("homebase_loadout_preview_icon_count", 0)) > 0, "Inline weapon dropdown has preview icons")
	_assert(selector != null and int(selector.get_meta("homebase_loadout_preview_icon_max_width", 999)) <= 18 and int(selector.get_meta("homebase_loadout_preview_icon_max_height", 999)) <= 14, "Inline weapon preview icons are bounded to the dropdown")
	_assert(selector != null and smg_index >= 0 and selector.get_item_icon(smg_index) != null, "SMG option carries a preview icon")

	screen.queue_free()
	await process_frame


func _test_shipcard_payload_is_clean_and_staging_is_folded() -> void:
	var screen: Control = await _build_screen()
	_drop_fireteam_on_shipcard(screen, "ft1", "dropship_alpha")
	await process_frame
	await process_frame

	var shipcard := _find_shipcard(screen, "dropship_alpha")
	var payload_card := _find_payload_fireteam_card(screen, "ft1")
	var direct_panel := screen.get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/DirectDropshipFireteamPanel") as Control
	var forbidden_texts := [
		"Lead:",
		"Members:",
		"Loadout:",
		"Loadout editing",
		"Not Boarded",
		"not boarded",
		"Kit Editor Only",
		"Kit edits only",
		"Launch Payload",
		"launch payload",
		"Top Operator Cards",
	]
	_assert(payload_card != null and not _visible_text_contains_any(payload_card, forbidden_texts), "Dropship payload card hides editor/debug labels")
	_assert(shipcard != null and _button_with_text(shipcard, "Mission") == null and _button_with_text(shipcard, "FOB") == null, "Dropship shipcard has no local Send button")
	_assert(shipcard != null and _button_with_text(shipcard, "Clear") == null, "Dropship shipcard has no local Clear button")
	_assert(direct_panel != null and not direct_panel.visible and bool(direct_panel.get_meta("homebase_direct_staging_folded_into_shipcards", false)), "Separate Direct Dropship Staging panel is folded into shipcards")
	_assert(_find_shipcard_payload_panel(screen, "dropship_alpha") != null, "Dropship card owns the Direct payload panel")

	screen.queue_free()
	await process_frame


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


func _drop_fireteam_on_shipcard(screen: Control, fireteam_id: String, craft_id: String) -> void:
	var target := _find_shipcard_drop_target(screen, craft_id)
	if target == null:
		return
	target.call("_drop_data", Vector2.ZERO, {"type": "fob_fireteam_card", "fireteam_id": fireteam_id})


func _fireteam_list(screen: Control) -> VBoxContainer:
	return screen.get_node("Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel/FireteamMargin/FireteamVBox/FireteamScroll/FireteamList") as VBoxContainer


func _find_loadout_selector(root_node: Node, unit_id: String, key: String) -> OptionButton:
	for node in _collect_nodes(root_node):
		if node is OptionButton \
			and String((node as OptionButton).get_meta("homebase_loadout_unit_id", "")).strip_edges() == unit_id \
			and String((node as OptionButton).get_meta("homebase_loadout_key", "")).strip_edges() == key:
			return node as OptionButton
	return null


func _find_item_index_by_metadata(selector: OptionButton, metadata_value: String) -> int:
	if selector == null:
		return -1
	for item_index in range(selector.item_count):
		if String(selector.get_item_metadata(item_index)).strip_edges() == metadata_value:
			return item_index
	return -1


func _find_shipcard_drop_target(screen: Control, craft_id: String) -> Control:
	var aircraft_panel := screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel") as Control
	for node in _collect_nodes(aircraft_panel):
		if node is Control \
			and bool((node as Control).get_meta("homebase_fireteam_drop_target", false)) \
			and String((node as Control).get_meta("homebase_fireteam_drop_target_id", "")).strip_edges() == craft_id:
			return node as Control
	return null


func _find_shipcard(screen: Control, craft_id: String) -> Control:
	var aircraft_panel := screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel") as Control
	for node in _collect_nodes(aircraft_panel):
		if node is PanelContainer \
			and bool((node as Control).get_meta("homebase_shipcard_half_width", false)) \
			and String((node as Control).get_meta("homebase_fireteam_drop_target_id", "")).strip_edges() == craft_id:
			return node as Control
	return null


func _find_shipcard_payload_panel(screen: Control, craft_id: String) -> Control:
	var aircraft_panel := screen.get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel") as Control
	if aircraft_panel == null:
		return null
	for node in _collect_nodes(aircraft_panel):
		if node is Control \
			and bool((node as Control).get_meta("homebase_shipcard_payload_panel", false)) \
			and String((node as Control).get_meta("craft_id", "")).strip_edges() == craft_id:
			return node as Control
	return null


func _find_payload_fireteam_card(screen: Control, fireteam_id: String) -> Control:
	var aircraft_panel := screen.get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel") as Control
	if aircraft_panel == null:
		return null
	for node in _collect_nodes(aircraft_panel):
		if node is Control \
			and bool((node as Control).get_meta("homebase_shipcard_payload_fireteam_card", false)) \
			and String((node as Control).get_meta("fireteam_id", "")).strip_edges() == fireteam_id:
			return node as Control
	return null


func _find_fireteam_panel_card(screen: Control, fireteam_id: String) -> Control:
	var list := _fireteam_list(screen)
	for child in list.get_children():
		if child.has_method("get_fireteam_id") and String(child.call("get_fireteam_id")).strip_edges() == fireteam_id:
			return child as Control
	return null


func _member_progress(payload_card: Control, unit_id: String) -> float:
	if payload_card == null:
		return -1.0
	for node in _collect_nodes(payload_card):
		var progress_bar := node as ProgressBar
		if progress_bar == null:
			continue
		if not bool(progress_bar.get_meta("homebase_shipcard_payload_member_progress", false)):
			continue
		if String(progress_bar.get_meta("unit_id", "")).strip_edges() == unit_id:
			return float(progress_bar.get_meta("homebase_direct_payload_boarding_progress", progress_bar.value))
	return -1.0


func _visible_text_contains_any(root_node: Node, snippets: Array) -> bool:
	for node in _collect_nodes(root_node):
		if node is Label and (node as Label).visible:
			for snippet_variant in snippets:
				if (node as Label).text.contains(String(snippet_variant)):
					return true
		elif node is LineEdit and (node as LineEdit).visible:
			for snippet_variant in snippets:
				if (node as LineEdit).text.contains(String(snippet_variant)):
					return true
	return false


func _button_with_text(root_node: Node, button_text: String) -> Button:
	for node in _collect_nodes(root_node):
		var button := node as Button
		if button != null and not (button is CheckBox) and button.visible and button.text.strip_edges() == button_text:
			return button
	return null


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
