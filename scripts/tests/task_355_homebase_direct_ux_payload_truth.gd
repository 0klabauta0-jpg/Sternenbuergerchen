extends SceneTree

const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_355 Homebase Direct UX Payload Truth Verifier ===")
	await _test_fireteam_cards_distinguish_homebase_loadout_and_payload()
	await _test_start_and_flightdeck_report_true_payload_count()
	await _test_blocked_payload_keeps_blocker_and_operator_truth()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_355: FAILED")
		quit(1)
	else:
		print("TASK_355: ALL PASSED")
		quit(0)


func _test_fireteam_cards_distinguish_homebase_loadout_and_payload() -> void:
	var screen: Control = await _build_screen_with_two_fireteams(true)

	var ft2_card := _find_fireteam_card(screen, "ft2")
	_assert(ft2_card != null, "#10 renders the second fireteam card")
	_assert(String(ft2_card.get_meta("homebase_direct_payload_status", "")).strip_edges() == "homebase", "Unboarded fireteam stays marked as Homebase staged")
	_assert(_stage_text(ft2_card).contains("Staged in Homebase"), "Homebase-only card labels staged state")
	_assert(_stage_text(ft2_card).contains("not boarded"), "Homebase-only card labels that it is not payload")

	screen.call("_on_homebase_staging_fireteam_dropped", "ft2", "loadout")
	await process_frame
	await process_frame

	ft2_card = _find_fireteam_card(screen, "ft2")
	_assert(String(ft2_card.get_meta("homebase_direct_payload_status", "")).strip_edges() == "loadout_editing", "Loadout target marks the fireteam as editing only")
	_assert(_stage_text(ft2_card).contains("Loadout editing"), "Loadout fireteam card shows editing state")
	_assert(_stage_text(ft2_card).contains("not boarded"), "Loadout editing does not masquerade as launch payload")

	screen.call("_on_homebase_staging_fireteam_dropped", "ft1", "homebase_dropship")
	await process_frame
	await process_frame

	var ft1_card := _find_payload_fireteam_card(screen, "ft1")
	ft2_card = _find_fireteam_card(screen, "ft2")
	_assert(_find_fireteam_card(screen, "ft1") == null, "Boarded fireteam card leaves #10 and lives on the Flightdeck")
	_assert(String(ft1_card.get_meta("homebase_direct_payload_status", "")).strip_edges() == "boarding", "Flightdeck fireteam card starts in active boarding state")
	_assert(not bool(ft1_card.get_meta("homebase_direct_payload_boarded", true)), "Flightdeck fireteam is not fully boarded immediately")
	_assert(_stage_text(ft1_card).contains("Flight Deck"), "Flightdeck fireteam card names its current location")
	screen.call("_debug_advance_homebase_direct_boarding", 9.2)
	await process_frame
	await process_frame
	ft1_card = _find_payload_fireteam_card(screen, "ft1")
	_assert(String(ft1_card.get_meta("homebase_direct_payload_status", "")).strip_edges() == "boarded", "Completed boarding marks the Flightdeck payload")
	_assert(bool(ft1_card.get_meta("homebase_direct_payload_boarded", false)), "Completed fireteam card exposes payload truth metadata")
	_assert(String(ft2_card.get_meta("homebase_direct_payload_status", "")).strip_edges() == "loadout_editing", "Editing fireteam remains outside payload after another fireteam boards")
	_assert(not bool(ft2_card.get_meta("homebase_direct_payload_boarded", true)), "Editing fireteam metadata stays unboarded")

	screen.queue_free()
	await process_frame


func _test_start_and_flightdeck_report_true_payload_count() -> void:
	var screen: Control = await _build_screen_with_two_fireteams(true)
	screen.call("_on_homebase_staging_fireteam_dropped", "ft1", "homebase_dropship")
	await process_frame
	await process_frame
	screen.call("_debug_advance_homebase_direct_boarding", 9.2)
	await process_frame
	await process_frame

	var snapshot: Dictionary = Dictionary(screen.call("get_homebase_direct_staging_snapshot"))
	var mission_transfer_label := screen.get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/MissionTransferLabel") as Label
	var start_button := screen.get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/StartMissionButton") as Button
	var direct_status_label := _direct_status_label(screen)

	_assert(Array(snapshot.get("selected_unit_ids", [])).size() == 3, "Homebase selection still contains all staged operators")
	_assert(int(snapshot.get("payload_operator_count", 0)) == 2, "Snapshot reports only boarded operators as payload")
	_assert(Array(snapshot.get("embarked_unit_ids", [])).size() == 2, "Drop state exports only boarded operators as embarked")
	_assert(Array(snapshot.get("payload_fireteam_ids", [])).size() == 1, "Snapshot reports one payload fireteam")
	_assert(not Array(snapshot.get("payload_fireteam_ids", [])).has("ft2"), "Non-boarded fireteam is excluded from payload ids")
	_assert(int(mission_transfer_label.get_meta("homebase_direct_payload_operator_count", 0)) == 2, "Mission transfer label metadata uses true payload operator count")
	_assert(mission_transfer_label.text.contains("Payload: 2 ops / 1 FT"), "Mission transfer text names true payload count")
	_assert(int(start_button.get_meta("homebase_direct_payload_operator_count", 0)) == 2, "Start button metadata uses true payload operator count")
	_assert(bool(start_button.get_meta("homebase_direct_payload_ready", false)), "Start button metadata marks Direct payload ready")
	_assert(direct_status_label != null and direct_status_label.text.contains("2 operators / 1 fireteam"), "Flightdeck status label names the true boarded count")
	_assert(direct_status_label != null and bool(direct_status_label.get_meta("homebase_direct_craft_ready", false)), "Flightdeck status metadata keeps craft-ready truth")

	screen.queue_free()
	await process_frame


func _test_blocked_payload_keeps_blocker_and_operator_truth() -> void:
	var screen: Control = await _build_screen_with_two_fireteams(false)
	screen.call("_on_homebase_staging_fireteam_dropped", "ft1", "homebase_dropship")
	await process_frame
	await process_frame

	var snapshot: Dictionary = Dictionary(screen.call("get_homebase_direct_staging_snapshot"))
	var direct_status_label := _direct_status_label(screen)
	var ft1_card := _find_payload_fireteam_card(screen, "ft1")

	_assert(String(snapshot.get("homebase_direct_craft_block_reason", "")).strip_edges() == "no_homebase_craft", "Blocked snapshot preserves the missing-craft reason")
	_assert(not bool(snapshot.get("drop_ship_staged", true)), "Blocked Flightdeck queue is not exported as boarded payload")
	_assert(int(snapshot.get("payload_operator_count", 0)) == 2, "Blocked Flightdeck queue still shows queued operator count")
	_assert(Array(snapshot.get("embarked_unit_ids", [])).is_empty(), "Blocked Flightdeck queue has no embarked units")
	_assert(direct_status_label != null and direct_status_label.text.contains("2 operators / 1 fireteam"), "Blocked Flightdeck status keeps operator count visible")
	_assert(direct_status_label != null and direct_status_label.text.contains("Add a dropship"), "Blocked Flightdeck status keeps the blocker text visible")
	_assert(_find_fireteam_card(screen, "ft1") == null, "Blocked Flightdeck queue also removes the card from #10")
	_assert(String(ft1_card.get_meta("homebase_direct_payload_status", "")).strip_edges() == "blocked", "Blocked fireteam card does not report boarded")
	_assert(not bool(ft1_card.get_meta("homebase_direct_payload_boarded", true)), "Blocked fireteam metadata stays unboarded")
	_assert(_stage_text(ft1_card).contains("Blocked: no dropship"), "Blocked fireteam card shows the no-dropship badge")

	screen.queue_free()
	await process_frame


func _build_screen_with_two_fireteams(with_dropship: bool) -> Control:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	screen.call("setup_roster", roster, PackedStringArray(["unit_alpha", "unit_bravo", "unit_charlie"]))
	screen.call(
		"set_fireteam_context",
		PackedStringArray(["ft1", "ft1", "ft2"]),
		[
			_build_fireteam_definition("ft1", "ALPHA", "unit_alpha"),
			_build_fireteam_definition("ft2", "BRAVO", "unit_charlie"),
		]
	)
	if with_dropship:
		screen.call(
			"set_transport_state",
			[_build_dropship_definition("dropship_alpha")],
			{"dropship_alpha": "unit_delta"},
			[],
			[],
			{"dropship_alpha": "homebase"},
			{},
			{},
			[]
		)
	else:
		screen.call("set_transport_state", [], {}, [], [], {}, {}, {}, [])
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


func _build_dropship_definition(craft_id: String) -> Dictionary:
	return {
		"craft_id": craft_id,
		"craft_type": "dropship",
		"display_name": "Dropship",
		"texture_path": DROPSHIP_TEXTURE_PATH,
		"supports_cargo": false,
		"cargo_options": [],
	}


func _find_fireteam_card(screen: Control, fireteam_id: String) -> Control:
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


func _collect_nodes(root_node: Node) -> Array:
	var nodes: Array = []
	if root_node == null:
		return nodes
	nodes.append(root_node)
	for child in root_node.get_children():
		nodes.append_array(_collect_nodes(child))
	return nodes


func _stage_text(card: Control) -> String:
	if card == null:
		return ""
	var label := card.get_node_or_null("Margin/VBox/StageLabel") as Label
	return label.text if label != null else ""


func _direct_status_label(screen: Control) -> Label:
	return screen.get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/DirectDropshipFireteamPanel/DirectDropshipMargin/DirectDropshipVBox/DirectDropshipStatusLabel") as Label


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		print("  FAIL: %s" % message)
