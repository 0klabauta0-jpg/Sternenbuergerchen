extends SceneTree

const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_389 Homebase Card Wide Drop Targets Verifier ===")
	await _test_fireteam_header_drop_adds_operator_as_lead()
	await _test_fireteam_member_drop_adds_operator_to_same_fireteam()
	await _test_fireteam_member_drop_moves_existing_operator_between_fireteams()
	await _test_dropship_shipcard_wide_drop_targets_board_fireteams()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_389: FAILED")
		quit(1)
	else:
		print("TASK_389: ALL PASSED")
		quit(0)


func _test_fireteam_header_drop_adds_operator_as_lead() -> void:
	var screen: Control = await _build_homebase_screen()
	var target := _find_unit_drop_target(screen, "ft1", "lead")
	var payload := _unit_payload("unit_delta")
	_assert(target != null and bool(target.call("_can_drop_data", Vector2.ZERO, payload)), "Fireteam header exposes a valid operator drop target")

	target.call("_drop_data", Vector2.ZERO, payload)
	await process_frame
	await process_frame

	var definition: Dictionary = Dictionary(screen.call("_get_fireteam_definition", "ft1"))
	_assert(_get_unit_fireteam(screen, "unit_delta") == "ft1", "Header drop assigns the operator to that fireteam")
	_assert(String(definition.get("lead_unit_id", "")).strip_edges() == "unit_delta", "Header drop promotes the dropped operator to fireteam lead")

	screen.queue_free()
	await process_frame


func _test_fireteam_member_drop_adds_operator_to_same_fireteam() -> void:
	var screen: Control = await _build_homebase_screen()
	var target := _find_unit_drop_target(screen, "ft1", "member", "unit_alpha")
	var payload := _unit_payload("unit_delta")
	_assert(target != null and bool(target.call("_can_drop_data", Vector2.ZERO, payload)), "Fireteam member block exposes a valid operator drop target")

	target.call("_drop_data", Vector2.ZERO, payload)
	await process_frame
	await process_frame

	var selected_ids: PackedStringArray = screen.call("get_selected_unit_ids")
	var alpha_index: int = selected_ids.find("unit_alpha")
	var delta_index: int = selected_ids.find("unit_delta")
	_assert(_get_unit_fireteam(screen, "unit_delta") == "ft1", "Member drop assigns a roster operator to the member's fireteam")
	_assert(alpha_index >= 0 and delta_index == alpha_index + 1, "Member drop places the new operator next to the anchor member in the card order")

	screen.queue_free()
	await process_frame


func _test_fireteam_member_drop_moves_existing_operator_between_fireteams() -> void:
	var screen: Control = await _build_homebase_screen()
	var target := _find_unit_drop_target(screen, "ft2", "member", "unit_charlie")
	var payload := _unit_payload("unit_bravo")
	_assert(target != null and bool(target.call("_can_drop_data", Vector2.ZERO, payload)), "Target fireteam member accepts an existing selected operator")

	target.call("_drop_data", Vector2.ZERO, payload)
	await process_frame
	await process_frame

	var selected_ids: PackedStringArray = screen.call("get_selected_unit_ids")
	var charlie_index: int = selected_ids.find("unit_charlie")
	var bravo_index: int = selected_ids.find("unit_bravo")
	_assert(_get_unit_fireteam(screen, "unit_bravo") == "ft2", "Member drop moves an existing operator to the target fireteam")
	_assert(charlie_index >= 0 and bravo_index == charlie_index + 1, "Moved operator is placed next to the target member")

	screen.queue_free()
	await process_frame


func _test_dropship_shipcard_wide_drop_targets_board_fireteams() -> void:
	var screen: Control = await _build_homebase_screen()
	var alpha_pilot_target := _find_shipcard_drop_target_by_name(screen, "dropship_alpha", "ShipcardPilotPanel")
	var beta_title_target := _find_shipcard_drop_target_by_name(screen, "dropship_beta", "ShipVisualLabel")
	var ft1_payload := _fireteam_payload("ft1")
	var ft2_payload := _fireteam_payload("ft2")
	_assert(alpha_pilot_target != null and bool(alpha_pilot_target.call("_can_drop_data", Vector2.ZERO, ft1_payload)), "Dropship pilot area accepts a fireteam card drop")
	_assert(beta_title_target != null and bool(beta_title_target.call("_can_drop_data", Vector2.ZERO, ft2_payload)), "Dropship title area accepts a fireteam card drop")

	alpha_pilot_target.call("_drop_data", Vector2.ZERO, ft1_payload)
	await process_frame
	await process_frame
	beta_title_target = _find_shipcard_drop_target_by_name(screen, "dropship_beta", "ShipVisualLabel")
	beta_title_target.call("_drop_data", Vector2.ZERO, ft2_payload)
	await process_frame
	await process_frame

	var snapshot: Dictionary = Dictionary(screen.call("get_homebase_direct_staging_snapshot"))
	var payload_by_craft: Dictionary = Dictionary(snapshot.get("payload_fireteam_ids_by_craft", {}))
	_assert(Array(payload_by_craft.get("dropship_alpha", [])).has("ft1"), "Drop on pilot area boards the fireteam onto that Dropship")
	_assert(Array(payload_by_craft.get("dropship_beta", [])).has("ft2"), "Drop on title area boards the fireteam onto that Dropship")
	_assert(_find_shipcard_payload_fireteam_card(screen, "ft1", "dropship_alpha") != null and _find_shipcard_payload_fireteam_card(screen, "ft2", "dropship_beta") != null, "Both wide drops render visible payload fireteam cards")

	screen.queue_free()
	await process_frame


func _build_homebase_screen() -> Control:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	screen.call("set_mission_context", [], "res://maps/Ground_Mission01_32x32.json", "Task 389 Test", 5, "task_389")
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


func _unit_payload(unit_id: String) -> Dictionary:
	return {
		"type": "homebase_unit_card",
		"unit_id": unit_id,
		"source_context": "roster",
	}


func _fireteam_payload(fireteam_id: String) -> Dictionary:
	return {
		"type": "fob_fireteam_card",
		"fireteam_id": fireteam_id,
		"source_context": "fireteam_list",
	}


func _get_unit_fireteam(screen: Control, unit_id: String) -> String:
	var selected_ids: PackedStringArray = screen.call("get_selected_unit_ids")
	var fireteam_ids: PackedStringArray = screen.call("get_selected_fireteam_ids")
	var unit_index: int = selected_ids.find(unit_id)
	if unit_index < 0 or unit_index >= fireteam_ids.size():
		return ""
	return String(fireteam_ids[unit_index]).strip_edges()


func _find_unit_drop_target(screen: Control, fireteam_id: String, drop_zone: String, anchor_unit_id: String = "") -> Control:
	var fireteam_list := screen.get_node("Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel/FireteamMargin/FireteamVBox/FireteamScroll/FireteamList") as Control
	for node in _collect_nodes(fireteam_list):
		var control := node as Control
		if control == null or not bool(control.get_meta("homebase_unit_drop_target", false)):
			continue
		if String(control.get_meta("homebase_unit_drop_fireteam_id", "")).strip_edges() != fireteam_id:
			continue
		if String(control.get_meta("homebase_unit_drop_zone", "")).strip_edges() != drop_zone:
			continue
		if not anchor_unit_id.strip_edges().is_empty() and String(control.get_meta("homebase_unit_drop_anchor_unit_id", "")).strip_edges() != anchor_unit_id:
			continue
		return control
	return null


func _find_shipcard_drop_target_by_name(screen: Control, craft_id: String, node_name: String) -> Control:
	var aircraft_panel := screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel") as Control
	for node in _collect_nodes(aircraft_panel):
		var control := node as Control
		if control == null or control.name != node_name:
			continue
		if not bool(control.get_meta("homebase_fireteam_drop_target", false)):
			continue
		if String(control.get_meta("homebase_fireteam_drop_target_id", "")).strip_edges() == craft_id:
			return control
	return null


func _find_shipcard_payload_fireteam_card(screen: Control, fireteam_id: String, craft_id: String) -> Control:
	var aircraft_panel := screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel") as Control
	for node in _collect_nodes(aircraft_panel):
		var control := node as Control
		if control == null:
			continue
		if bool(control.get_meta("homebase_shipcard_payload_fireteam_card", false)) \
			and String(control.get_meta("fireteam_id", "")).strip_edges() == fireteam_id \
			and String(control.get_meta("craft_id", "")).strip_edges() == craft_id:
			return control
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
