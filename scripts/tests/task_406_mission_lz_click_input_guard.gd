extends SceneTree

const MISSION_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_406 Mission LZ Click Input Guard ===")
	await _test_card_armed_lz_uses_real_unhandled_map_click()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_card_armed_lz_uses_real_unhandled_map_click() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)

	var controller: Node = scene.get_node_or_null("TacticalController")
	var primary_view: Node = scene.get_node_or_null("Primary3DView")
	_assert(controller != null and primary_view != null, "Mission exposes TacticalController and Primary3DView")
	if controller == null or primary_view == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	controller.call("set_planning_state", {
		"mission_drop_source": "homebase_direct",
		"mission_drop_craft_id": "dropship_alpha",
		"mission_drop_display_name": "Dropship Alpha",
		"mission_drop_state": "waiting",
		"mission_drop_passenger_count": 2,
		"drop_ship_staged": true,
		"has_lz_position": false,
		"lz_position": Vector2.ZERO,
		"mission_drop_cards": [_build_waiting_card("dropship_alpha", "Dropship Alpha")],
	})
	await _wait_frames(8)

	var lz_button := _find_mission_card_command(scene, "dropship_alpha", "set_lz")
	_assert(lz_button != null and not lz_button.disabled, "Dropship card exposes enabled LZ command")
	if lz_button == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	_send_mouse_motion(lz_button.get_global_rect().get_center())
	await _wait_frames(2)
	controller.call("_on_mission_dropship_card_set_lz_pressed", "dropship_alpha")
	_assert(bool(controller.get("_is_lz_placement_armed")), "Card LZ command arms map placement")

	var lz_world := Vector2(384.0, 224.0)
	var lz_screen: Vector2 = primary_view.call("world_to_screen_position", lz_world)
	var grid_variant = primary_view.call("screen_to_grid_position", lz_screen)
	_assert(typeof(grid_variant) == TYPE_VECTOR2I, "Chosen LZ screen point resolves to a Primary3DView tile")
	var click_event := InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	click_event.position = lz_screen
	click_event.global_position = lz_screen
	controller.call("_unhandled_input", click_event)
	await _wait_frames(4)

	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	var card: Dictionary = _find_card(Array(planning_state.get("mission_drop_cards", [])), "dropship_alpha")
	_assert(bool(planning_state.get("has_lz_position", false)), "Unhandled map click sets scalar LZ state")
	_assert(bool(card.get("has_lz_position", false)), "Unhandled map click stores LZ on the selected dropship card")
	_assert(Vector2(card.get("lz_position", Vector2.ZERO)).distance_to(lz_world) < 96.0, "Stored card LZ is near the clicked map tile")
	_assert(not bool(controller.get("_is_lz_placement_armed")), "LZ placement disarms after successful map click")
	scene.queue_free()
	await _wait_frames(2)


func _build_waiting_card(craft_id: String, display_name: String) -> Dictionary:
	return {
		"craft_id": craft_id,
		"display_name": display_name,
		"title_text": display_name,
		"state": "waiting",
		"approach_angle": "NW",
		"has_lz_position": false,
		"lz_position": Vector2.ZERO,
		"drop_ship_staged": true,
		"has_embarked_payload": true,
		"embarked_unit_ids": PackedStringArray(["unit_alpha", "unit_bravo"]),
		"passenger_count": 2,
		"pilot_text": "Pilot ready",
		"status_line": "Waiting",
	}


func _find_mission_card_command(root_node: Node, craft_id: String, command_id: String) -> Button:
	for node in _collect_node_tree(root_node):
		var button := node as Button
		if button == null:
			continue
		if bool(button.get_meta("mission_dropship_card_command_button", false)) \
			and String(button.get_meta("mission_dropship_craft_id", "")).strip_edges() == craft_id \
			and String(button.get_meta("mission_dropship_card_command", "")).strip_edges() == command_id:
			return button
	return null


func _find_card(cards: Array, craft_id: String) -> Dictionary:
	for card_variant in cards:
		var card: Dictionary = Dictionary(card_variant)
		if String(card.get("craft_id", "")).strip_edges() == craft_id:
			return card
	return {}


func _collect_node_tree(node: Node) -> Array:
	var nodes: Array = []
	if node == null:
		return nodes
	nodes.append(node)
	for child in node.get_children():
		nodes.append_array(_collect_node_tree(child))
	return nodes


func _send_mouse_motion(position: Vector2) -> void:
	var motion_event := InputEventMouseMotion.new()
	motion_event.position = position
	motion_event.global_position = position
	Input.parse_input_event(motion_event)


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
