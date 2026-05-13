extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_398 Mission Dropship Outbound Command Hotfix Verifier ===")
	await _test_outbound_shipcard_stays_accessible_until_exit()
	await _test_unselected_card_command_click_is_not_swallowed_by_card_select()
	await _test_approach_buttons_use_consistent_readable_font_size()
	await _test_embarked_fireteam_is_not_rendered_as_ground_card()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_398: FAILED")
		quit(1)
	else:
		print("TASK_398: ALL PASSED")
		quit(0)


func _test_outbound_shipcard_stays_accessible_until_exit() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = await _build_mission_scene_with_two_waiting_dropships()
	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Mission scene exposes controller for outbound access checks")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	controller.call("_on_mission_dropship_card_drop_pressed", "dropship_alpha")
	await _wait_until_drop_phase(controller, "outbound", 120)
	controller.call("_update_ui")
	await _wait_frames(4)
	var outbound_card_panel := _find_mission_card_panel(scene, "dropship_alpha")
	var outbound_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	var outbound_card: Dictionary = _find_card(Array(outbound_state.get("mission_drop_cards", [])), "dropship_alpha")
	_assert(String(outbound_card.get("state", "")) == "outbound", "Alpha enters visible outbound map-flight state after deboarding")
	_assert(not bool(outbound_state.get("mission_drop_return_requested", false)), "Outbound map-flight does not request meta return transit before the ship leaves the map route")
	_assert(outbound_card_panel != null and not bool(outbound_card_panel.get_meta("mission_dropship_card_inaccessible", true)), "Outbound Dropship card is not greyed/inaccessible while the ship is still on the map route")

	await _wait_until_drop_sequence_cleared(controller, 120)
	controller.call("_update_ui")
	await _wait_frames(4)
	var return_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	var returned_card: Dictionary = _find_card(Array(return_state.get("mission_drop_cards", [])), "dropship_alpha")
	var returned_panel := _find_mission_card_panel(scene, "dropship_alpha")
	_assert(String(returned_card.get("state", "")) == "to_homebase", "Homebase-direct Dropship switches to homebase transit only after leaving the map route")
	_assert(returned_panel != null and bool(returned_panel.get_meta("mission_dropship_card_inaccessible", false)), "Homebase transit card is greyed again after the visible outbound route is complete")

	scene.queue_free()
	await _wait_frames(2)


func _test_unselected_card_command_click_is_not_swallowed_by_card_select() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = await _build_mission_scene_with_two_waiting_dropships()
	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Mission scene exposes controller for direct command click checks")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var beta_panel := _find_mission_card_panel(scene, "dropship_beta")
	var beta_drop_button := _find_mission_card_command(scene, "dropship_beta", "drop")
	_assert(beta_panel != null and beta_drop_button != null and not beta_drop_button.disabled, "Unselected Beta card exposes an enabled Drop button")
	if beta_panel == null or beta_drop_button == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = beta_panel.get_global_transform_with_canvas().affine_inverse() * beta_drop_button.get_global_rect().get_center()
	controller.call("_on_mission_dropship_card_gui_input", event, "dropship_beta", beta_panel)
	await _wait_frames(2)
	_assert(String(controller.get("_mission_drop_craft_id")) == "dropship_alpha", "Card selection handler ignores direct clicks on command buttons")

	beta_drop_button.emit_signal("pressed")
	await _wait_frames(4)
	_assert(String(controller.get("_drop_sequence_craft_id")) == "dropship_beta" and String(controller.get("_drop_sequence_phase")) == "inbound", "Pressing an unselected card command selects Beta and starts its command in one action")

	scene.queue_free()
	await _wait_frames(2)


func _test_approach_buttons_use_consistent_readable_font_size() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = await _build_mission_scene_with_two_waiting_dropships()
	var alpha_grid := _find_approach_grid(scene, "dropship_alpha")
	var alpha_lz_button := _find_mission_card_command(scene, "dropship_alpha", "set_lz")
	_assert(alpha_grid != null and alpha_lz_button != null, "Approach grid and LZ button exist on the Dropship card")
	if alpha_grid == null or alpha_lz_button == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	var expected_font_size: int = alpha_lz_button.get_theme_font_size("font_size")
	var all_match: bool = true
	for child in alpha_grid.get_children():
		var button := child as Button
		if button == null:
			all_match = false
			continue
		if button.get_theme_font_size("font_size") != expected_font_size:
			all_match = false
		if button.custom_minimum_size.x < 25.0 or button.custom_minimum_size.y < 16.0:
			all_match = false
	_assert(all_match, "Approach buttons use the same readable font size and fixed minimum size")

	scene.queue_free()
	await _wait_frames(2)


func _test_embarked_fireteam_is_not_rendered_as_ground_card() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = await _build_mission_scene_with_all_units_embarked()
	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Mission scene exposes controller for embarked fireteam card visibility")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	controller.call("_update_ui")
	await _wait_frames(4)
	_assert(_count_mission_fireteam_mini_cards(scene) == 0, "Embarked Fireteams are not shown as left-side ground Fireteam cards")
	_assert(_count_selected_member_cards(scene) == 0, "Embarked operators are not duplicated as selected ground member cards")

	scene.queue_free()
	await _wait_frames(2)


func _build_mission_scene_with_two_waiting_dropships() -> Node:
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(10)
	var controller := scene.get_node_or_null("TacticalController")
	if controller == null:
		return scene
	var unit_ids: Array = _collect_friendly_unit_ids(scene)
	if unit_ids.size() < 4:
		unit_ids = ["unit_alpha", "unit_bravo", "unit_charlie", "unit_delta"]
	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	planning_state["mission_drop_source"] = "homebase_direct"
	planning_state["mission_drop_craft_id"] = "dropship_alpha"
	planning_state["mission_drop_state"] = "waiting"
	planning_state["drop_ship_staged"] = true
	planning_state["has_lz_position"] = true
	planning_state["lz_position"] = Vector2(384.0, 224.0)
	planning_state["deployed_unit_ids"] = []
	planning_state["deployed_unit_positions"] = {}
	planning_state["mission_drop_cards"] = [
		_build_waiting_mission_card("dropship_alpha", "Dropship Alpha", unit_ids.slice(0, 2), "alpha_ft", "NW", Vector2(384.0, 224.0)),
		_build_waiting_mission_card("dropship_beta", "Dropship Beta", unit_ids.slice(2, 4), "beta_ft", "SE", Vector2(672.0, 352.0)),
	]
	controller.call("set_planning_state", planning_state)
	controller.call("_update_ui")
	await _wait_frames(6)
	return scene


func _build_mission_scene_with_all_units_embarked() -> Node:
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(10)
	var controller := scene.get_node_or_null("TacticalController")
	if controller == null:
		return scene
	var unit_ids: Array = _collect_friendly_unit_ids(scene)
	var fireteam_ids: PackedStringArray = _collect_friendly_fireteam_ids(scene)
	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	planning_state["mission_drop_source"] = "homebase_direct"
	planning_state["mission_drop_craft_id"] = "dropship_alpha"
	planning_state["mission_drop_state"] = "waiting"
	planning_state["drop_ship_staged"] = true
	planning_state["has_lz_position"] = true
	planning_state["lz_position"] = Vector2(384.0, 224.0)
	planning_state["embarked_unit_ids"] = unit_ids.duplicate()
	planning_state["deployed_unit_ids"] = []
	planning_state["deployed_unit_positions"] = {}
	planning_state["selected_fireteams"] = Array(fireteam_ids)
	planning_state["mission_drop_cards"] = [
		_build_waiting_mission_card("dropship_alpha", "Dropship Alpha", unit_ids.duplicate(), fireteam_ids[0] if not fireteam_ids.is_empty() else "alpha_ft", "NW", Vector2(384.0, 224.0)),
	]
	controller.call("set_planning_state", planning_state)
	controller.call("_update_ui")
	await _wait_frames(6)
	return scene


func _build_waiting_mission_card(craft_id: String, display_name: String, unit_ids: Array, fireteam_id: String, approach_angle: String, lz_position: Vector2) -> Dictionary:
	return {
		"craft_id": craft_id,
		"display_name": display_name,
		"state": "waiting",
		"progress": 100.0,
		"embarked_unit_ids": unit_ids.duplicate(),
		"boarded_fireteam_ids": [fireteam_id],
		"queued_fireteam_ids": [fireteam_id],
		"passenger_count": unit_ids.size(),
		"has_lz_position": true,
		"lz_position": lz_position,
		"approach_angle": approach_angle,
		"drop_ship_staged": true,
		"payload_source": "homebase_direct",
	}


func _wait_until_drop_phase(controller: Node, phase: String, max_frames: int) -> void:
	for _index in range(max_frames):
		if String(controller.get("_drop_sequence_phase")) == phase:
			return
		controller.call("_update_drop_sequence", 0.18)
		await process_frame


func _wait_until_drop_sequence_cleared(controller: Node, max_frames: int) -> void:
	for _index in range(max_frames):
		if String(controller.get("_drop_sequence_phase")).is_empty():
			return
		controller.call("_update_drop_sequence", 0.18)
		await process_frame


func _find_mission_card_panel(root_node: Node, craft_id: String) -> PanelContainer:
	for node in _collect_nodes(root_node):
		var panel := node as PanelContainer
		if panel != null \
			and bool(panel.get_meta("mission_dropship_card", false)) \
			and String(panel.get_meta("mission_dropship_craft_id", "")).strip_edges() == craft_id:
			return panel
	return null


func _find_mission_card_command(root_node: Node, craft_id: String, command_id: String) -> Button:
	for node in _collect_nodes(root_node):
		var button := node as Button
		if button != null \
			and bool(button.get_meta("mission_dropship_card_command_button", false)) \
			and String(button.get_meta("mission_dropship_craft_id", "")).strip_edges() == craft_id \
			and String(button.get_meta("mission_dropship_card_command", "")).strip_edges() == command_id:
			return button
	return null


func _find_approach_grid(root_node: Node, craft_id: String) -> GridContainer:
	for node in _collect_nodes(root_node):
		var grid := node as GridContainer
		if grid != null \
			and bool(grid.get_meta("mission_dropship_card_approach_grid", false)) \
			and String(grid.get_meta("mission_dropship_craft_id", "")).strip_edges() == craft_id:
			return grid
	return null


func _find_card(cards: Array, craft_id: String) -> Dictionary:
	for card_variant in cards:
		if typeof(card_variant) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = Dictionary(card_variant)
		if String(card.get("craft_id", "")).strip_edges() == craft_id:
			return card
	return {}


func _collect_friendly_unit_ids(mission_root: Node) -> Array:
	var result: Array = []
	for node in _collect_nodes(mission_root):
		if not node.has_method("get_team_id") or not node.has_method("get_unit_id"):
			continue
		if String(node.call("get_team_id")).strip_edges() != "team_alpha":
			continue
		var unit_id: String = String(node.call("get_unit_id")).strip_edges()
		if not unit_id.is_empty():
			result.append(unit_id)
	result.sort()
	return result


func _collect_friendly_fireteam_ids(mission_root: Node) -> PackedStringArray:
	var result := PackedStringArray()
	for node in _collect_nodes(mission_root):
		if not node.has_method("get_team_id") or not node.has_method("get_fireteam_id"):
			continue
		if String(node.call("get_team_id")).strip_edges() != "team_alpha":
			continue
		var fireteam_id: String = String(node.call("get_fireteam_id")).strip_edges().to_lower()
		if fireteam_id.is_empty() or result.has(fireteam_id):
			continue
		result.append(fireteam_id)
	return result


func _count_mission_fireteam_mini_cards(root_node: Node) -> int:
	var count: int = 0
	for node in _collect_nodes(root_node):
		if node is Control and bool(node.get_meta("mission_fireteam_mini_card", false)):
			count += 1
	return count


func _count_selected_member_cards(root_node: Node) -> int:
	var count: int = 0
	for node in _collect_nodes(root_node):
		if node.has_method("get_source_context") and String(node.call("get_source_context")) == "mission_selected_fireteam_member":
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
