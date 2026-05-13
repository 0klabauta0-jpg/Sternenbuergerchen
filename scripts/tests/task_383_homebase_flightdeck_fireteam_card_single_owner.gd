extends SceneTree

const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_383 Homebase Flightdeck Fireteam Card Single Owner Verifier ===")
	await _test_fireteam_card_moves_from_fireteam_panel_to_dropship()
	await _test_removing_payload_returns_card_to_fireteam_panel()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_383: FAILED")
		quit(1)
	else:
		print("TASK_383: ALL PASSED")
		quit(0)


func _test_fireteam_card_moves_from_fireteam_panel_to_dropship() -> void:
	var screen: Control = await _build_screen()
	_assert(_find_fireteam_panel_card(screen, "ft1") != null, "#10 initially owns the ALPHA fireteam card")
	_assert(_find_payload_fireteam_card(screen, "ft1") == null, "Flightdeck initially has no ALPHA payload card")

	_drop_fireteam_on_shipcard(screen, "ft1", "dropship_alpha")
	await process_frame
	await process_frame

	var payload_card := _find_payload_fireteam_card(screen, "ft1")
	_assert(_find_fireteam_panel_card(screen, "ft1") == null, "Boarded fireteam card is removed from #10")
	_assert(_find_fireteam_panel_card(screen, "ft2") != null, "Non-boarded fireteam remains visible in #10")
	_assert(payload_card != null, "Dropship renders the moved fireteam card")
	_assert(payload_card != null and String(payload_card.get_meta("homebase_fireteam_single_visual_owner", "")).strip_edges() == "flightdeck", "Moved fireteam card declares Flightdeck as visual owner")
	_assert(payload_card != null and float(payload_card.get_meta("homebase_direct_payload_boarding_progress", 0.0)) >= 100.0, "Dropship fireteam card exposes completed boarding progress")
	_assert(_count_payload_member_rows(payload_card) == 2, "Dropship fireteam card keeps one progress row per member")
	_assert(_all_payload_member_progress_complete(payload_card), "Dropship member progress bars show boarded state")

	screen.queue_free()
	await process_frame


func _test_removing_payload_returns_card_to_fireteam_panel() -> void:
	var screen: Control = await _build_screen()
	_drop_fireteam_on_shipcard(screen, "ft1", "dropship_alpha")
	await process_frame
	await process_frame
	screen.call("_on_homebase_dropship_fireteam_remove_pressed", "ft1")
	await process_frame
	await process_frame

	_assert(_find_payload_fireteam_card(screen, "ft1") == null, "Removing payload clears the Flightdeck fireteam card")
	_assert(_find_fireteam_panel_card(screen, "ft1") != null, "Removing payload returns the fireteam card to #10")

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
		PackedStringArray(["ft1", "ft1", "ft2"]),
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


func _find_fireteam_panel_card(screen: Control, fireteam_id: String) -> Control:
	var list := screen.get_node_or_null("Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel/FireteamMargin/FireteamVBox/FireteamScroll/FireteamList") as VBoxContainer
	if list == null:
		return null
	for child in list.get_children():
		if child.has_method("get_fireteam_id") and String(child.call("get_fireteam_id")).strip_edges() == fireteam_id:
			return child as Control
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


func _find_shipcard_drop_target(screen: Control, craft_id: String) -> Control:
	var aircraft_panel := screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel") as Control
	for node in _collect_nodes(aircraft_panel):
		if node is Control \
			and bool((node as Control).get_meta("homebase_fireteam_drop_target", false)) \
			and String((node as Control).get_meta("homebase_fireteam_drop_target_id", "")).strip_edges() == craft_id:
			return node as Control
	return null


func _count_payload_member_rows(payload_card: Control) -> int:
	var count := 0
	for node in _collect_nodes(payload_card):
		if bool(node.get_meta("homebase_shipcard_payload_member_row", false)):
			count += 1
	return count


func _all_payload_member_progress_complete(payload_card: Control) -> bool:
	var progress_bar_count := 0
	for node in _collect_nodes(payload_card):
		if node is ProgressBar and bool((node as ProgressBar).get_meta("homebase_shipcard_payload_member_progress", false)):
			progress_bar_count += 1
			if float((node as ProgressBar).get_meta("homebase_direct_payload_boarding_progress", 0.0)) < 100.0:
				return false
	return progress_bar_count > 0


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
