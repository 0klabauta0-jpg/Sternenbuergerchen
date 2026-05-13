extends SceneTree

const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_384 Homebase Flightdeck Boarding Hotfix Verifier ===")
	await _test_compact_shipcards_and_sequential_boarding()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_384: FAILED")
		quit(1)
	else:
		print("TASK_384: ALL PASSED")
		quit(0)


func _test_compact_shipcards_and_sequential_boarding() -> void:
	var screen: Control = await _build_screen()
	var shipcards_list := screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/ShipCardsScroll/ShipCardsList") as VBoxContainer
	var first_row := _find_first_shipcard_row(shipcards_list)
	_assert(bool(shipcards_list.get_meta("homebase_shipcards_two_column_layout", false)), "Flightdeck shipcards declare the compact two-column layout")
	_assert(first_row != null and _count_half_width_shipcards(first_row) == 2, "Two dropship cards fit next to each other in one Flightdeck row")

	_drop_fireteam_on_shipcard(screen, "ft1", "dropship_alpha")
	await process_frame
	await process_frame

	var send_button := _find_shipcard_send_button(screen, "dropship_alpha")
	var payload_panel := _find_shipcard_payload_panel(screen, "dropship_alpha")
	var payload_card := _find_payload_fireteam_card(screen, "ft1")
	var header := _find_payload_header(payload_panel)
	var drop_state_before: Dictionary = Dictionary(screen.call("build_homebase_direct_drop_state"))
	_assert(send_button != null and send_button.disabled, "Mission Send stays disabled while the fireteam is still boarding")
	_assert(not bool(drop_state_before.get("drop_ship_staged", true)), "Direct drop state stays blocked until boarding completes")
	_assert(payload_panel != null and int(payload_panel.get_meta("homebase_direct_boarded_operator_count", -1)) == 0, "Payload panel starts at 0 boarded operators")
	_assert(header != null and String(header.text).contains("0/2 NPC"), "Dropship payload header shows boarded count on the shipcard")
	_assert(payload_card != null and _count_payload_mini_portraits(payload_card) == 2, "Dropship fireteam card shows a mini portrait for each operator")
	_assert(payload_card != null and not _card_contains_loadout_editor(payload_card), "Dropship fireteam card omits loadout editing UI and loadout text")
	_assert(_find_fireteam_panel_card(screen, "ft1") == null, "The moved fireteam card no longer remains in #10 during boarding")

	screen.call("_debug_advance_homebase_direct_boarding", 4.6)
	await process_frame
	await process_frame

	payload_panel = _find_shipcard_payload_panel(screen, "dropship_alpha")
	payload_card = _find_payload_fireteam_card(screen, "ft1")
	send_button = _find_shipcard_send_button(screen, "dropship_alpha")
	_assert(payload_panel != null and int(payload_panel.get_meta("homebase_direct_boarded_operator_count", -1)) == 1, "After one boarding interval exactly one operator is boarded")
	_assert(_member_progress(payload_card, "unit_alpha") >= 100.0, "First operator progress completes after the first interval")
	_assert(_member_progress(payload_card, "unit_bravo") < 100.0, "Second operator is still queued/boarding after the first interval")
	_assert(send_button != null and send_button.disabled, "Mission Send stays disabled until the last operator is boarded")

	screen.call("_debug_advance_homebase_direct_boarding", 4.6)
	await process_frame
	await process_frame

	payload_panel = _find_shipcard_payload_panel(screen, "dropship_alpha")
	payload_card = _find_payload_fireteam_card(screen, "ft1")
	send_button = _find_shipcard_send_button(screen, "dropship_alpha")
	var drop_state_after: Dictionary = Dictionary(screen.call("build_homebase_direct_drop_state"))
	_assert(payload_panel != null and int(payload_panel.get_meta("homebase_direct_boarded_operator_count", -1)) == 2, "After the second interval both operators are boarded")
	_assert(payload_card != null and float(payload_card.get_meta("homebase_direct_payload_boarding_progress", 0.0)) >= 100.0, "Dropship fireteam card exposes completed boarding progress")
	_assert(send_button != null and not send_button.disabled, "Mission Send enables after sequential boarding completes")
	_assert(bool(drop_state_after.get("drop_ship_staged", false)), "Direct drop state becomes launch-ready after boarding completes")
	_assert(Array(drop_state_after.get("embarked_unit_ids", [])).size() == 2, "Completed Direct drop exports the boarded operator ids")

	screen.queue_free()
	await process_frame


func _build_screen() -> Control:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	screen.call("setup_roster", roster, PackedStringArray(["unit_alpha", "unit_bravo", "unit_charlie", "unit_delta"]))
	screen.call(
		"set_fireteam_context",
		PackedStringArray(["ft1", "ft1", "ft2", "ft2"]),
		[
			{
				"id": "ft1",
				"label": "ALPHA",
				"lead_unit_id": "unit_alpha",
				"loadout": "medium",
				"respawn_enabled": false,
			},
			{
				"id": "ft2",
				"label": "BRAVO",
				"lead_unit_id": "unit_charlie",
				"loadout": "medium",
				"respawn_enabled": false,
			},
		]
	)
	screen.call(
		"set_transport_state",
		[
			_build_dropship_definition("dropship_alpha", "Dropship Alpha"),
			_build_dropship_definition("dropship_beta", "Dropship Beta"),
		],
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
	target.call("_drop_data", Vector2.ZERO, {"type": "fob_fireteam_card", "fireteam_id": fireteam_id})


func _find_first_shipcard_row(shipcards_list: Node) -> HBoxContainer:
	if shipcards_list == null:
		return null
	for child in shipcards_list.get_children():
		var row := child as HBoxContainer
		if row != null and bool(row.get_meta("homebase_shipcard_row", false)):
			return row
	return null


func _count_half_width_shipcards(root_node: Node) -> int:
	var count := 0
	for node in _collect_nodes(root_node):
		if node is Control and bool((node as Control).get_meta("homebase_shipcard_half_width", false)):
			count += 1
	return count


func _find_payload_header(payload_panel: Control) -> Label:
	if payload_panel == null:
		return null
	for node in _collect_nodes(payload_panel):
		var label := node as Label
		if label != null and bool(label.get_meta("homebase_shipcard_payload_header", false)):
			return label
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
	var list := screen.get_node_or_null("Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel/FireteamMargin/FireteamVBox/FireteamScroll/FireteamList") as VBoxContainer
	if list == null:
		return null
	for child in list.get_children():
		if child.has_method("get_fireteam_id") and String(child.call("get_fireteam_id")).strip_edges() == fireteam_id:
			return child as Control
	return null


func _find_shipcard_send_button(screen: Control, craft_id: String) -> Button:
	var aircraft_panel := screen.get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel") as Control
	if aircraft_panel == null:
		return null
	for node in _collect_nodes(aircraft_panel):
		var button := node as Button
		if button != null \
			and button.has_meta("homebase_shipcard_send_target") \
			and String(button.get_meta("craft_id", craft_id)).strip_edges() == craft_id:
			return button
	return null


func _find_shipcard_drop_target(screen: Control, craft_id: String) -> Control:
	var aircraft_panel := screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel") as Control
	for node in _collect_nodes(aircraft_panel):
		if node is Control \
			and bool((node as Control).get_meta("homebase_fireteam_drop_target", false)) \
			and String((node as Control).get_meta("homebase_fireteam_drop_target_id", "")).strip_edges() == craft_id:
			return node as Control
	return null


func _count_payload_mini_portraits(payload_card: Control) -> int:
	var count := 0
	for node in _collect_nodes(payload_card):
		if node is TextureRect and bool((node as TextureRect).get_meta("homebase_shipcard_payload_mini_portrait", false)):
			count += 1
	return count


func _card_contains_loadout_editor(payload_card: Control) -> bool:
	for node in _collect_nodes(payload_card):
		if node is Control and bool((node as Control).get_meta("homebase_fireteam_inline_loadout_row", false)):
			return true
		var label := node as Label
		if label != null and label.text.contains("Loadout"):
			return true
	return false


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
