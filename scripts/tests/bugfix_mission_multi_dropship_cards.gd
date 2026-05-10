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
			"embarked_unit_ids": ["unit_alpha", "unit_bravo", "unit_charlie", "unit_delta"],
			"boarded_fireteam_ids": ["blue"],
			"has_lz_position": true,
			"lz_position": Vector2(224.0, 144.0),
			"approach_angle": "NW",
		},
		{
			"craft_id": "dropship_2",
			"display_name": "Dropship 2",
			"title_text": "#19 Dropship 2",
			"state": "waiting",
			"progress": 100.0,
			"eta_seconds": 0,
			"pilot_display_name": "Mara Iven",
			"passenger_count": 4,
			"embarked_unit_ids": ["unit_echo", "unit_foxtrot", "unit_golf", "unit_hotel"],
			"boarded_fireteam_ids": ["gold"],
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
		_assert(first_card.modulate.a < 1.0, "Inbound Dropship 1 remains visually in transit")
		_assert(second_card.modulate.a >= 0.99, "Waiting Dropship 2 renders at full color on the mission map")

		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		second_card.emit_signal("gui_input", click)
		await _wait_frames(4)

		var selected_state: Dictionary = Dictionary(controller.call("get_planning_state"))
		var refreshed_second_card := panel.get_child(1) as Control
		_assert(String(selected_state.get("mission_drop_craft_id", "")) == "dropship_2", "Clicking the right-side Dropship 2 card selects it for Mission Control")
		_assert(String(selected_state.get("mission_drop_state", "")) == "waiting", "Selected Dropship 2 carries its waiting state into Mission Control")
		_assert(Array(selected_state.get("embarked_unit_ids", [])) == ["unit_echo", "unit_foxtrot", "unit_golf", "unit_hotel"], "Selected Dropship 2 carries its own boarded payload")
		_assert(bool(refreshed_second_card.get_meta("mission_dropship_selected", false)), "Selected mission dropship card is marked in the #19 panel")
		var selected_stylebox := refreshed_second_card.get_theme_stylebox("panel") as StyleBoxFlat
		_assert(selected_stylebox != null and selected_stylebox.border_color.g > selected_stylebox.border_color.r and selected_stylebox.border_width_left >= 2, "Selected mission dropship card uses a clear green outline")
		_assert(not bool(selected_state.get("has_lz_position", true)), "Selecting Dropship 2 does not inherit Dropship 1 LZ")
		controller.set("_has_lz_position", true)
		controller.set("_lz_position", Vector2(640.0, 320.0))
		controller.call("_select_approach_angle", "SE")
		await _wait_frames(4)
		var planned_second_state: Dictionary = Dictionary(controller.call("get_planning_state"))
		var planned_cards: Array = Array(planned_second_state.get("mission_drop_cards", []))
		var planned_second_card: Dictionary = _find_card(planned_cards, "dropship_2")
		_assert(bool(planned_second_card.get("has_lz_position", false)) and Vector2(planned_second_card.get("lz_position", Vector2.ZERO)).is_equal_approx(Vector2(640.0, 320.0)), "Dropship 2 stores its own LZ")
		_assert(String(planned_second_card.get("approach_angle", "")) == "SE", "Dropship 2 stores its own approach")
		var summary_panel := scene.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/MissionCraftSummary") as Control
		_assert(summary_panel != null and summary_panel.visible and String(summary_panel.get_meta("mission_drop_craft_id", "")) == "dropship_2", "Mission Control shows the selected dropship summary next to Drop")
		var refreshed_first_card := panel.get_child(0) as Control
		refreshed_first_card.emit_signal("gui_input", click)
		await _wait_frames(4)
		var reselected_first_state: Dictionary = Dictionary(controller.call("get_planning_state"))
		_assert(String(reselected_first_state.get("mission_drop_craft_id", "")) == "dropship_1" and Vector2(reselected_first_state.get("lz_position", Vector2.ZERO)).is_equal_approx(Vector2(224.0, 144.0)), "Reselecting Dropship 1 restores its own LZ")
		_assert(String(reselected_first_state.get("approach_angle", "")) == "NW", "Reselecting Dropship 1 restores its own approach")

	var synced_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	_assert(Array(synced_state.get("mission_drop_cards", [])).size() == 2, "Planning state preserves both mission dropship cards")

	scene.queue_free()
	await _wait_frames(2)


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _find_card(cards: Array, craft_id: String) -> Dictionary:
	for card_variant in cards:
		if typeof(card_variant) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = Dictionary(card_variant)
		if String(card.get("craft_id", "")).strip_edges() == craft_id:
			return card
	return {}


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
