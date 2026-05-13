extends SceneTree

const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_388 Homebase Fireteam Roster Shipcard Polish Verifier ===")
	await _test_fireteam_cards_are_clean_and_buttons_hidden()
	await _test_two_dropships_keep_independent_fireteam_payloads()
	await _test_assigned_pilot_drags_back_to_available_roster()
	await _test_roster_sorting_by_pilot_score()
	await _test_mission_slots_include_pilots_and_shipcard_send_launches()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_388: FAILED")
		quit(1)
	else:
		print("TASK_388: ALL PASSED")
		quit(0)


func _test_fireteam_cards_are_clean_and_buttons_hidden() -> void:
	var screen: Control = await _build_two_dropship_screen()
	var fireteam_list := _fireteam_list(screen)
	var assign_button := screen.get_node_or_null("Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel/FireteamMargin/FireteamVBox/FireteamActionRow/AssignFocusedUnitButton") as Button
	var clear_button := screen.get_node_or_null("Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel/FireteamMargin/FireteamVBox/FireteamActionRow/ClearFocusedUnitButton") as Button
	var forbidden_texts := ["Loadout:", "Lead:", "Members:", "Kit", "Payload", "Top Operator"]
	_assert(not _visible_text_contains_any(fireteam_list, forbidden_texts), "#10 fireteam cards hide loadout/member/debug helper text")
	_assert(assign_button != null and clear_button != null and not assign_button.is_visible_in_tree() and not clear_button.is_visible_in_tree(), "#10 Assign/Clear buttons are not visible")
	_assert(_count_nodes_with_meta(fireteam_list, "homebase_fireteam_inline_loadout_dropdown") == 12, "#10 keeps compact inline loadout dropdowns for the four operators")

	screen.queue_free()
	await process_frame


func _test_two_dropships_keep_independent_fireteam_payloads() -> void:
	var screen: Control = await _build_two_dropship_screen()
	_drop_fireteam_on_shipcard(screen, "ft1", "dropship_alpha")
	await process_frame
	await process_frame
	_drop_fireteam_on_shipcard(screen, "ft2", "dropship_beta")
	await process_frame
	await process_frame

	var alpha_panel := _find_shipcard_payload_panel(screen, "dropship_alpha")
	var beta_panel := _find_shipcard_payload_panel(screen, "dropship_beta")
	var alpha_card := _find_payload_fireteam_card(screen, "ft1", "dropship_alpha")
	var beta_card := _find_payload_fireteam_card(screen, "ft2", "dropship_beta")
	var snapshot: Dictionary = Dictionary(screen.call("get_homebase_direct_staging_snapshot"))
	var payload_by_craft: Dictionary = Dictionary(snapshot.get("payload_fireteam_ids_by_craft", {}))
	_assert(alpha_panel != null and beta_panel != null, "Both Dropship cards keep their own visible payload panel")
	_assert(alpha_card != null and beta_card != null, "Each Dropship keeps the fireteam card dropped onto it")
	_assert(_find_fireteam_panel_card(screen, "ft1") == null and _find_fireteam_panel_card(screen, "ft2") == null, "Boarded fireteam cards do not jump back to #10 when another Dropship receives a payload")
	_assert(Array(payload_by_craft.get("dropship_alpha", [])).has("ft1") and Array(payload_by_craft.get("dropship_beta", [])).has("ft2"), "Snapshot stores Direct payloads per Dropship")
	_assert(int(alpha_panel.get_meta("homebase_direct_payload_operator_count", 0)) == 2 and int(beta_panel.get_meta("homebase_direct_payload_operator_count", 0)) == 2, "Each Dropship exposes its own passenger count at a glance")

	screen.queue_free()
	await process_frame


func _test_assigned_pilot_drags_back_to_available_roster() -> void:
	var screen: Control = await _build_two_dropship_screen()
	var roster_panel := screen.get_node("Panel/Margin/VBox/ContentRow/RosterPanel") as Control
	var drag_payload := {
		"type": "homebase_unit_card",
		"unit_id": "unit_echo",
		"source_context": "aircraft_shipcard",
	}
	var events := {"cleared": 0}
	screen.aircraft_pilot_cleared.connect(func(_craft_id): events["cleared"] = int(events["cleared"]) + 1)
	_assert(_find_assigned_pilot_card(screen, "unit_echo", "dropship_alpha") != null, "Assigned Dropship pilot is rendered as a drag source")
	_assert(roster_panel.has_method("_can_drop_data") and bool(roster_panel.call("_can_drop_data", Vector2.ZERO, drag_payload)), "Available Operators accepts assigned-pilot drag payloads")

	roster_panel.call("_drop_data", Vector2.ZERO, drag_payload)
	await process_frame
	await process_frame

	_assert(int(events["cleared"]) == 1, "Dropping pilot back to Available Operators emits the pilot-cleared signal")
	_assert(_find_assigned_pilot_card(screen, "unit_echo", "dropship_alpha") == null, "Pilot card leaves the Dropship after drag-back")
	_assert(_find_roster_card(screen, "unit_echo") != null, "Pilot appears again in Available Operators after drag-back")

	screen.queue_free()
	await process_frame


func _test_roster_sorting_by_pilot_score() -> void:
	var screen: Control = await _build_two_dropship_screen()
	var selector := _find_roster_sort_selector(screen)
	var pilot_index := _find_item_index_by_metadata(selector, "pilot_desc")
	_assert(selector != null and pilot_index >= 0, "Available Operators exposes Pilot high sorting")
	screen.call("_on_roster_sort_selected", pilot_index, selector)
	await process_frame
	await process_frame

	var roster_cards: Array = _collect_roster_cards(screen)
	var first_card: Control = null
	if not roster_cards.is_empty():
		first_card = roster_cards[0] as Control
	var first_score: float = float(first_card.get_meta("homebase_roster_pilot_score", -1.0)) if first_card != null else -1.0
	var sorted := first_card != null
	for card_variant in roster_cards:
		var card := card_variant as Control
		if card != null and float(card.get_meta("homebase_roster_pilot_score", -1.0)) > first_score + 0.001:
			sorted = false
			break
	var snapshot: Dictionary = Dictionary(screen.call("get_homebase_roster_sort_snapshot"))
	_assert(String(snapshot.get("mode", "")).strip_edges() == "pilot_desc", "Roster sort snapshot records Pilot high mode")
	_assert(sorted, "Pilot high sorting places the strongest visible pilot score first")

	screen.queue_free()
	await process_frame


func _test_mission_slots_include_pilots_and_shipcard_send_launches() -> void:
	var screen: Control = await _build_single_dropship_screen_with_five_operators()
	var mission_slots := screen.get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/MissionTeamLimitLabel") as Label
	_assert(mission_slots.text.contains("6 / 5") and int(mission_slots.get_meta("mission_slot_usage_count", 0)) == 6, "Mission slots count five operators plus one assigned pilot")

	_drop_fireteam_on_shipcard(screen, "ft1", "dropship_alpha")
	await process_frame
	await process_frame
	var total_seconds: float = float(screen.call("_debug_get_homebase_fireteam_boarding_total_seconds", "ft1"))
	screen.call("_debug_advance_homebase_direct_boarding", total_seconds + 0.1)
	await process_frame
	await process_frame

	var send_button := _find_shipcard_send_button(screen, "dropship_alpha")
	var events := {"mission": 0}
	screen.mission_start_requested.connect(func(): events["mission"] = int(events["mission"]) + 1)
	_assert(send_button != null and not send_button.disabled and String(send_button.get_meta("homebase_shipcard_send_target", "")).strip_edges() == "mission", "Dropship card exposes enabled Send after boarding")
	send_button.pressed.emit()
	await process_frame
	_assert(int(events["mission"]) == 1, "Dropship Send launches the direct Mission payload")

	screen.queue_free()
	await process_frame


func _build_two_dropship_screen() -> Control:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	screen.call("set_mission_context", [], "res://maps/Ground_Mission01_32x32.json", "Task 388 Test", 5, "task_388")
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	screen.call("setup_roster", roster, PackedStringArray(["unit_alpha", "unit_bravo", "unit_charlie", "unit_delta"]))
	screen.call(
		"set_fireteam_context",
		PackedStringArray(["ft1", "ft1", "ft2", "ft2"]),
		[
			_build_fireteam_definition("ft1", "ALPHA", "unit_alpha"),
			_build_fireteam_definition("ft2", "BRAVO", "unit_charlie"),
		]
	)
	screen.call(
		"set_transport_state",
		[_build_dropship_definition("dropship_alpha", "Dropship Alpha"), _build_dropship_definition("dropship_beta", "Dropship Beta")],
		{"dropship_alpha": "unit_echo", "dropship_beta": "unit_foxtrot"},
		[],
		[],
		{"dropship_alpha": "homebase", "dropship_beta": "homebase"},
		{},
		{},
		[]
	)
	await process_frame
	await process_frame
	return screen


func _build_single_dropship_screen_with_five_operators() -> Control:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	screen.call("set_mission_context", [], "res://maps/Ground_Mission01_32x32.json", "Task 388 Slots", 5, "task_388_slots")
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	screen.call("setup_roster", roster, PackedStringArray(["unit_alpha", "unit_bravo", "unit_charlie", "unit_delta", "unit_golf"]))
	screen.call(
		"set_fireteam_context",
		PackedStringArray(["ft1", "ft1", "ft1", "ft2", "ft2"]),
		[
			_build_fireteam_definition("ft1", "ALPHA", "unit_alpha"),
			_build_fireteam_definition("ft2", "BRAVO", "unit_delta"),
		]
	)
	screen.call(
		"set_transport_state",
		[_build_dropship_definition("dropship_alpha", "Dropship Alpha")],
		{"dropship_alpha": "unit_echo"},
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


func _build_fireteam_definition(fireteam_id: String, label: String, lead_unit_id: String) -> Dictionary:
	return {
		"id": fireteam_id,
		"label": label,
		"lead_unit_id": lead_unit_id,
		"loadout": "medium",
		"respawn_enabled": false,
	}


func _build_dropship_definition(craft_id: String, display_name: String) -> Dictionary:
	return {
		"craft_id": craft_id,
		"craft_type": "dropship",
		"display_name": display_name,
		"texture_path": DROPSHIP_TEXTURE_PATH,
		"supports_cargo": false,
		"cargo_options": [],
	}


func _drop_fireteam_on_shipcard(screen: Control, fireteam_id: String, craft_id: String) -> void:
	var target := _find_shipcard_drop_target(screen, craft_id)
	if target == null:
		return
	target.call("_drop_data", Vector2.ZERO, {"type": "fob_fireteam_card", "fireteam_id": fireteam_id, "source_context": "fireteam_list"})


func _fireteam_list(screen: Control) -> VBoxContainer:
	return screen.get_node("Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel/FireteamMargin/FireteamVBox/FireteamScroll/FireteamList") as VBoxContainer


func _find_fireteam_panel_card(screen: Control, fireteam_id: String) -> Control:
	for child in _fireteam_list(screen).get_children():
		if child.has_method("get_fireteam_id") and String(child.call("get_fireteam_id")).strip_edges() == fireteam_id:
			return child as Control
	return null


func _find_payload_fireteam_card(screen: Control, fireteam_id: String, craft_id: String = "") -> Control:
	var aircraft_panel := screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel") as Control
	for node in _collect_nodes(aircraft_panel):
		if node is Control \
			and bool((node as Control).get_meta("homebase_shipcard_payload_fireteam_card", false)) \
			and String((node as Control).get_meta("fireteam_id", "")).strip_edges() == fireteam_id \
			and (craft_id.strip_edges().is_empty() or String((node as Control).get_meta("craft_id", "")).strip_edges() == craft_id):
			return node as Control
	return null


func _find_shipcard_drop_target(screen: Control, craft_id: String) -> Control:
	var aircraft_panel := screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel") as Control
	for node in _collect_nodes(aircraft_panel):
		if node is Control \
			and bool((node as Control).get_meta("homebase_fireteam_drop_target", false)) \
			and String((node as Control).get_meta("homebase_fireteam_drop_target_id", "")).strip_edges() == craft_id:
			return node as Control
	return null


func _find_shipcard_payload_panel(screen: Control, craft_id: String) -> Control:
	var aircraft_panel := screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel") as Control
	for node in _collect_nodes(aircraft_panel):
		if node is Control \
			and bool((node as Control).get_meta("homebase_shipcard_payload_panel", false)) \
			and String((node as Control).get_meta("craft_id", "")).strip_edges() == craft_id:
			return node as Control
	return null


func _find_shipcard_send_button(screen: Control, craft_id: String) -> Button:
	var aircraft_panel := screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel") as Control
	for node in _collect_nodes(aircraft_panel):
		var button := node as Button
		if button != null and button.has_meta("homebase_shipcard_send_target") and String(button.get_meta("craft_id", "")).strip_edges() == craft_id:
			return button
	return null


func _find_assigned_pilot_card(screen: Control, unit_id: String, craft_id: String) -> Control:
	var aircraft_panel := screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel") as Control
	for node in _collect_nodes(aircraft_panel):
		if node is Control \
			and bool((node as Control).get_meta("homebase_assigned_pilot_card", false)) \
			and String((node as Control).get_meta("unit_id", "")).strip_edges() == unit_id \
			and String((node as Control).get_meta("craft_id", "")).strip_edges() == craft_id:
			return node as Control
	return null


func _find_roster_card(screen: Control, unit_id: String) -> Control:
	for card_variant in _collect_roster_cards(screen):
		var card := card_variant as Control
		if card != null and String(card.get_meta("homebase_roster_pool_unit_id", "")).strip_edges() == unit_id:
			return card
	return null


func _collect_roster_cards(screen: Control) -> Array:
	var cards: Array = []
	var list := screen.get_node("Panel/Margin/VBox/ContentRow/RosterPanel/RosterMargin/RosterVBox/RosterScroll/RosterList") as VBoxContainer
	for child in list.get_children():
		if child is Control and (child as Control).has_meta("homebase_roster_pool_unit_id"):
			cards.append(child)
	return cards


func _find_roster_sort_selector(screen: Control) -> OptionButton:
	return screen.get_node_or_null("Panel/Margin/VBox/ContentRow/RosterPanel/RosterMargin/RosterVBox/RosterSortRow/RosterSortSelector") as OptionButton


func _find_item_index_by_metadata(selector: OptionButton, metadata_value: String) -> int:
	if selector == null:
		return -1
	for item_index in range(selector.item_count):
		if String(selector.get_item_metadata(item_index)).strip_edges() == metadata_value:
			return item_index
	return -1


func _find_visible_button(root_node: Node, button_text: String) -> Button:
	for node in _collect_nodes(root_node):
		var button := node as Button
		if button != null and not (button is CheckBox) and button.visible and button.text.strip_edges() == button_text:
			return button
	return null


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
