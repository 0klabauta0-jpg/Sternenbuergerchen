extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Mission Multi Dropship Cards Bugfix ===")
	await _test_multiple_mission_dropships_render_as_stacked_cards()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_multiple_mission_dropships_render_as_stacked_cards() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(4)

	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Mission scene exposes the tactical controller")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	planning_state["mission_drop_craft_id"] = "dropship_1"
	planning_state["mission_drop_state"] = "to_mission"
	planning_state["mission_drop_cards"] = [
		{
			"craft_id": "dropship_1",
			"display_name": "Dropship 1",
			"title_text": "#19 Dropship 1",
			"state": "to_mission",
			"progress": 35.0,
			"eta_seconds": 11,
			"pilot_display_name": "Sena Novak",
			"passenger_count": 4,
		},
		{
			"craft_id": "dropship_2",
			"display_name": "Dropship 2",
			"title_text": "#19 Dropship 2",
			"state": "to_mission",
			"progress": 12.0,
			"eta_seconds": 17,
			"pilot_display_name": "Mara Iven",
			"passenger_count": 4,
		},
	]
	controller.call("set_planning_state", planning_state)
	await _wait_frames(4)

	var panel := scene.get_node_or_null("TacticalUI/MissionDropshipPanel") as Control
	_assert(panel != null and panel.visible, "Mission dropship panel is visible for mission_drop_cards")
	_assert(panel != null and panel.get_child_count() == 2, "Two inbound dropships render as two separate right-side cards")
	if panel != null and panel.get_child_count() >= 2:
		var first_card := panel.get_child(0) as Control
		var second_card := panel.get_child(1) as Control
		_assert(String(first_card.get_meta("mission_dropship_craft_id", "")) == "dropship_1", "First card keeps Dropship 1 identity")
		_assert(String(second_card.get_meta("mission_dropship_craft_id", "")) == "dropship_2", "Second card keeps Dropship 2 identity")
		_assert(second_card.global_position.y > first_card.global_position.y, "Dropship cards are stacked vertically")
		_assert(panel.size.y >= 216.0, "Panel reserves vertical space for both cards")

	var synced_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	_assert(Array(synced_state.get("mission_drop_cards", [])).size() == 2, "Planning state preserves both mission dropship cards")

	scene.queue_free()
	await _wait_frames(2)


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
