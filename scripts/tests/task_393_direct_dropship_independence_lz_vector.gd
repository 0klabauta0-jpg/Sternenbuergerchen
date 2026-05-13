extends SceneTree

const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_393 Direct Dropship Independence LZ Vector Verifier ===")
	await _test_operator_drop_updates_fireteam_card_inside_dropship()
	await _test_second_direct_send_keeps_first_mission_card_and_eta_alive()
	await _test_lz_marker_and_approach_vector_hide_after_touchdown()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_393: FAILED")
		quit(1)
	else:
		print("TASK_393: ALL PASSED")
		quit(0)


func _test_operator_drop_updates_fireteam_card_inside_dropship() -> void:
	var screen: Control = await _build_homebase_screen_for_payload_member_drop()
	_drop_fireteam_on_shipcard(screen, "ft1", "dropship_alpha")
	await _wait_frames(2)

	var payload_card := _find_homebase_payload_fireteam_card(screen, "ft1", "dropship_alpha")
	_assert(payload_card != null, "Fireteam card is visible inside the Dropship payload before member drop")
	if payload_card != null:
		payload_card.call("_drop_data", Vector2.ZERO, {"type": "homebase_unit_card", "unit_id": "unit_charlie", "source_context": "roster"})
	await _wait_frames(3)

	payload_card = _find_homebase_payload_fireteam_card(screen, "ft1", "dropship_alpha")
	var drop_state: Dictionary = Dictionary(screen.call("build_homebase_direct_drop_state_for_craft", "dropship_alpha"))
	_assert(payload_card != null and int(payload_card.get_meta("homebase_direct_payload_operator_count", 0)) == 3, "Dropship Fireteam card shows the newly dropped operator")
	_assert(_count_nodes_with_meta(payload_card, "homebase_shipcard_payload_member_row") == 3, "Dropship Fireteam card renders three payload member rows")
	_assert(Array(drop_state.get("queued_unit_ids", [])).has("unit_charlie"), "Per-craft Direct drop state includes the added operator")
	_assert(_find_homebase_fireteam_panel_card(screen, "ft1") == null, "Payload Fireteam remains single-owner on the Dropship after adding an operator")

	screen.queue_free()
	await _wait_frames(2)


func _test_second_direct_send_keeps_first_mission_card_and_eta_alive() -> void:
	var scene: Node = await _build_two_dropship_meta_scene()
	var homebase_screen := scene.get_node("HomebaseScreen") as Control

	_drop_fireteam_on_shipcard(homebase_screen, "ft1", "dropship_alpha")
	await _finish_boarding(homebase_screen, "ft1")
	homebase_screen.call("_on_send_pilot_button_pressed", "dropship_alpha")
	await _wait_frames(6)
	var first_mission: Node = scene.call("get_active_mission")
	var first_controller: Node = first_mission.get_node_or_null("TacticalController") if first_mission != null else null
	for _step in range(4):
		scene.call("_on_homebase_transport_timer_timeout")
	await _wait_frames(2)
	var first_progress_state: Dictionary = Dictionary(first_controller.call("get_planning_state")) if first_controller != null else {}
	var alpha_before: Dictionary = _find_mission_drop_card(Array(first_progress_state.get("mission_drop_cards", [])), "dropship_alpha")
	var alpha_progress_before: float = float(alpha_before.get("progress", 0.0))

	_drop_fireteam_on_shipcard(homebase_screen, "ft2", "dropship_beta")
	await _finish_boarding(homebase_screen, "ft2")
	homebase_screen.call("_on_send_pilot_button_pressed", "dropship_beta")
	await _wait_frames(6)
	var second_mission: Node = scene.call("get_active_mission")
	var second_controller: Node = second_mission.get_node_or_null("TacticalController") if second_mission != null else null
	for _step in range(4):
		scene.call("_on_homebase_transport_timer_timeout")
	await _wait_frames(4)

	var planning_state: Dictionary = Dictionary(second_controller.call("get_planning_state")) if second_controller != null else {}
	var cards: Array = Array(planning_state.get("mission_drop_cards", []))
	var alpha_card: Dictionary = _find_mission_drop_card(cards, "dropship_alpha")
	var beta_card: Dictionary = _find_mission_drop_card(cards, "dropship_beta")
	_assert(first_mission == second_mission, "Second Direct Send updates the active mission instead of replacing it")
	_assert(not alpha_card.is_empty() and not beta_card.is_empty(), "Mission keeps separate Dropship cards for Alpha and Beta")
	_assert(String(alpha_card.get("state", "")).strip_edges() == "to_mission" and String(beta_card.get("state", "")).strip_edges() == "to_mission", "Both Direct Dropships keep their own to_mission state")
	_assert(float(alpha_card.get("progress", 0.0)) > alpha_progress_before, "First Dropship ETA/progress keeps advancing after the second Dropship launches")
	_assert(_find_mission_dropship_card(second_mission, "dropship_alpha") != null and _find_mission_dropship_card(second_mission, "dropship_beta") != null, "Mission HUD renders both Direct Dropship cards at the same time")

	scene.queue_free()
	await _wait_frames(2)


func _test_lz_marker_and_approach_vector_hide_after_touchdown() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(10)
	var controller := scene.get_node_or_null("TacticalController")
	var primary_view := scene.get_node_or_null("Primary3DView")
	_assert(controller != null and primary_view != null, "Mission scene exposes controller and Primary3DView for LZ visual checks")
	if controller == null or primary_view == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var drop_unit_ids: Array = _collect_friendly_unit_ids(scene).slice(0, 2)
	var drop_fireteam_id: String = _get_first_friendly_fireteam_id(scene)
	if drop_fireteam_id.is_empty():
		drop_fireteam_id = "blue"
	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	planning_state["mission_drop_craft_id"] = "dropship_alpha"
	planning_state["mission_drop_state"] = "waiting"
	planning_state["drop_ship_staged"] = true
	planning_state["has_lz_position"] = true
	planning_state["lz_position"] = Vector2(448.0, 256.0)
	planning_state["approach_angle"] = "NW"
	planning_state["embarked_unit_ids"] = drop_unit_ids
	planning_state["deployed_unit_ids"] = []
	planning_state["deployed_unit_positions"] = {}
	planning_state["mission_drop_cards"] = [
		{
			"craft_id": "dropship_alpha",
			"display_name": "Dropship Alpha",
			"state": "waiting",
			"progress": 100.0,
			"embarked_unit_ids": drop_unit_ids,
			"boarded_fireteam_ids": [drop_fireteam_id],
			"queued_fireteam_ids": [drop_fireteam_id],
			"passenger_count": drop_unit_ids.size(),
			"has_lz_position": true,
			"lz_position": Vector2(448.0, 256.0),
			"approach_angle": "NW",
		},
	]
	controller.call("set_planning_state", planning_state)
	await _wait_frames(8)

	var entries_before: Array = Array(controller.call("_build_mission_dropship_visual_entries", false, Vector2.ZERO))
	var alpha_before: Dictionary = _find_visual_entry(entries_before, "dropship_alpha")
	var snapshot_before: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(bool(alpha_before.get("show_lz_marker", false)), "Waiting Dropship exposes its planned LZ marker")
	_assert(Vector2(alpha_before.get("approach_vector_origin_position", Vector2.ZERO)).distance_to(Vector2(alpha_before.get("dropship_position", Vector2.ZERO))) < 0.01, "Approach vector starts at the current Dropship position")
	_assert(int(snapshot_before.get("requested_lz_marker_count", 0)) >= 1 and float(snapshot_before.get("dropship_lz_marker_fill", 0.0)) > 1.0, "Planned LZ marker is visible and larger than one compact marker")
	_assert(int(snapshot_before.get("dropship_approach_line_count", 0)) >= 1 and float(snapshot_before.get("dropship_approach_line_width_factor", 0.0)) >= 0.2, "Approach vector is rendered as a wide translucent line")

	controller.call("_on_call_dropship_pressed")
	for _step in range(520):
		controller.call("_update_drop_sequence", 0.2)
		if String(controller.get("_drop_sequence_phase")) == "unloading":
			break
	await _wait_frames(6)

	var entries_after: Array = Array(controller.call("_build_mission_dropship_visual_entries", true, Vector2(controller.get("_drop_sequence_position"))))
	var alpha_after: Dictionary = _find_visual_entry(entries_after, "dropship_alpha")
	var snapshot_after: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(String(controller.get("_drop_sequence_phase")) == "unloading", "Dropship reaches Touchdown/Deboarding during the LZ visual test")
	_assert(not bool(alpha_after.get("show_lz_marker", true)), "Used LZ marker is hidden after Touchdown")
	_assert(int(snapshot_after.get("requested_lz_marker_count", 0)) == 0 and int(snapshot_after.get("lz_tile_marker_count", 0)) == 0, "Primary3DView removes the used LZ marker after Touchdown")
	_assert(int(snapshot_after.get("dropship_approach_line_count", 0)) == 0, "Approach vector disappears with the used LZ marker after Touchdown")

	scene.queue_free()
	await _wait_frames(2)


func _build_homebase_screen_for_payload_member_drop() -> Control:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await _wait_frames(2)
	screen.call("set_mission_context", [], "res://maps/Ground_Mission01_32x32.json", "Task 393 Payload", 5, "task_393_payload")
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	screen.call("setup_roster", roster, PackedStringArray(["unit_alpha", "unit_bravo"]))
	screen.call(
		"set_fireteam_context",
		PackedStringArray(["ft1", "ft1"]),
		[_build_fireteam_definition("ft1", "ALPHA", PackedStringArray(["unit_alpha", "unit_bravo"]))]
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
	await _wait_frames(2)
	return screen


func _build_two_dropship_meta_scene() -> Node:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(4)
	var homebase_screen := scene.get_node("HomebaseScreen") as Control
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	var craft_definitions: Array = [_build_dropship_definition("dropship_alpha", "Dropship Alpha"), _build_dropship_definition("dropship_beta", "Dropship Beta")]
	var pilot_by_craft := {"dropship_alpha": "unit_echo", "dropship_beta": "unit_foxtrot"}
	var location_by_craft := {"dropship_alpha": "homebase", "dropship_beta": "homebase"}
	scene.set("_available_team_units", roster.duplicate(true))
	scene.set("_all_team_units", roster.duplicate(true))
	scene.set("_homebase_aircraft_definitions", craft_definitions.duplicate(true))
	scene.set("_assigned_aircraft_pilot_by_craft", pilot_by_craft.duplicate(true))
	scene.set("_aircraft_location_by_craft", location_by_craft.duplicate(true))
	homebase_screen.call("setup_roster", roster, PackedStringArray(["unit_alpha", "unit_bravo", "unit_charlie", "unit_delta"]))
	homebase_screen.call(
		"set_fireteam_context",
		PackedStringArray(["ft1", "ft1", "ft2", "ft2"]),
		[
			_build_fireteam_definition("ft1", "ALPHA", PackedStringArray(["unit_alpha", "unit_bravo"])),
			_build_fireteam_definition("ft2", "BRAVO", PackedStringArray(["unit_charlie", "unit_delta"])),
		]
	)
	homebase_screen.call("set_transport_state", craft_definitions, pilot_by_craft, [], [], location_by_craft, {}, {}, [])
	await _wait_frames(3)
	return scene


func _finish_boarding(screen: Control, fireteam_id: String) -> void:
	var total_seconds: float = float(screen.call("_debug_get_homebase_fireteam_boarding_total_seconds", fireteam_id))
	screen.call("_debug_advance_homebase_direct_boarding", total_seconds + 0.2)
	await _wait_frames(3)


func _build_fireteam_definition(fireteam_id: String, label: String, unit_ids: PackedStringArray) -> Dictionary:
	return {
		"id": fireteam_id,
		"label": label,
		"lead_unit_id": String(unit_ids[0]) if not unit_ids.is_empty() else "",
		"loadout": "medium",
		"respawn_enabled": false,
		"member_unit_ids": unit_ids.duplicate(),
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


func _find_shipcard_drop_target(screen: Control, craft_id: String) -> Control:
	var aircraft_panel := screen.get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel") as Control
	if aircraft_panel == null:
		return null
	for node in _collect_nodes(aircraft_panel):
		var control := node as Control
		if control != null \
			and bool(control.get_meta("homebase_fireteam_drop_target", false)) \
			and bool(control.get_meta("homebase_fireteam_drop_enabled", false)) \
			and String(control.get_meta("homebase_fireteam_drop_target_id", "")).strip_edges() == craft_id:
			return control
	return null


func _find_homebase_payload_fireteam_card(screen: Control, fireteam_id: String, craft_id: String = "") -> Control:
	var aircraft_panel := screen.get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel") as Control
	if aircraft_panel == null:
		return null
	for node in _collect_nodes(aircraft_panel):
		var control := node as Control
		if control != null \
			and bool(control.get_meta("homebase_shipcard_payload_fireteam_card", false)) \
			and String(control.get_meta("fireteam_id", "")).strip_edges() == fireteam_id \
			and (craft_id.strip_edges().is_empty() or String(control.get_meta("craft_id", "")).strip_edges() == craft_id):
			return control
	return null


func _find_homebase_fireteam_panel_card(screen: Control, fireteam_id: String) -> Control:
	var fireteam_list := screen.get_node_or_null("Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel/FireteamMargin/FireteamVBox/FireteamScroll/FireteamList") as Control
	if fireteam_list == null:
		return null
	for child in fireteam_list.get_children():
		if child.has_method("get_fireteam_id") and String(child.call("get_fireteam_id")).strip_edges() == fireteam_id:
			return child as Control
	return null


func _find_mission_dropship_card(mission_instance: Node, craft_id: String) -> PanelContainer:
	if mission_instance == null:
		return null
	var panel := mission_instance.get_node_or_null("TacticalUI/MissionDropshipPanel") as Control
	if panel == null:
		return null
	for child in panel.get_children():
		var card := child as PanelContainer
		if card != null and bool(card.get_meta("mission_dropship_card", false)) and String(card.get_meta("mission_dropship_craft_id", "")).strip_edges() == craft_id:
			return card
	return null


func _find_mission_drop_card(cards: Array, craft_id: String) -> Dictionary:
	for card_variant in cards:
		if typeof(card_variant) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = Dictionary(card_variant)
		if String(card.get("craft_id", "")).strip_edges() == craft_id:
			return card
	return {}


func _find_visual_entry(entries: Array, craft_id: String) -> Dictionary:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("craft_id", "")).strip_edges() == craft_id:
			return entry
	return {}


func _collect_friendly_unit_ids(mission_root: Node) -> Array:
	var result: Array = []
	if mission_root == null:
		return result
	for node in _collect_nodes(mission_root):
		if not node.has_method("get_team_id") or not node.has_method("get_unit_id"):
			continue
		if String(node.call("get_team_id")).strip_edges() != "team_alpha":
			continue
		var unit_id: String = String(node.call("get_unit_id")).strip_edges()
		if not unit_id.is_empty():
			result.append(unit_id)
	return result


func _get_first_friendly_fireteam_id(mission_root: Node) -> String:
	if mission_root == null:
		return ""
	for node in _collect_nodes(mission_root):
		if not node.has_method("get_team_id") or not node.has_method("get_fireteam_id"):
			continue
		if String(node.call("get_team_id")).strip_edges() != "team_alpha":
			continue
		var fireteam_id: String = String(node.call("get_fireteam_id")).strip_edges().to_lower()
		if not fireteam_id.is_empty():
			return fireteam_id
	return ""


func _count_nodes_with_meta(root_node: Node, meta_key: String) -> int:
	var count := 0
	for node in _collect_nodes(root_node):
		if node is Node and (node as Node).has_meta(meta_key):
			count += 1
	return count


func _collect_nodes(root_node: Node) -> Array:
	var result: Array = []
	if root_node == null:
		return result
	result.append(root_node)
	for child in root_node.get_children():
		result.append_array(_collect_nodes(child))
	return result


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
