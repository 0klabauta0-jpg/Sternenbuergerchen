extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Mission Multi Dropship Cards Bugfix ===")
	await _test_multiple_mission_dropships_render_as_stacked_cards()
	await _test_second_dropship_can_be_selected_and_planned_while_first_is_inbound()
	await _test_second_dropship_can_drop_after_first_hands_off_to_return()
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
	planning_state["deployed_unit_ids"] = []
	planning_state["deployed_unit_positions"] = {}
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
	_assert(panel != null and panel.get_child_count() == 2, "Two mission dropships render as two detailed passenger cards")
	var primary_view := scene.get_node_or_null("Primary3DView")
	if primary_view != null and primary_view.has_method("get_render_snapshot"):
		var render_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
		_assert(int(render_snapshot.get("dropship_visual_count", 0)) == 0, "Mission map keeps transfer and waiting dropships offscreen until a real drop run is active")
	if panel != null and panel.get_child_count() >= 2:
		var first_card := panel.get_child(0) as Control
		var second_card := panel.get_child(1) as Control
		_assert(String(first_card.get_meta("mission_dropship_craft_id", "")) == "dropship_1", "First card keeps Dropship 1 identity")
		_assert(String(second_card.get_meta("mission_dropship_craft_id", "")) == "dropship_2", "Second card keeps Dropship 2 identity")
		_assert(second_card.global_position.y > first_card.global_position.y, "Dropship cards are stacked vertically")
		_assert(panel.size.y >= 216.0, "Panel reserves vertical space for both cards")
		_assert(first_card.modulate.a < 1.0, "Inbound Dropship 1 remains visually in transit")
		_assert(second_card.modulate.a >= 0.99, "Waiting Dropship 2 card stays fully commandable while its model remains offscreen")
		var first_progress := first_card.get_node_or_null("MarginContainer/VBox/ProgressBar") as ProgressBar
		_assert(first_progress != null and first_progress.visible and absf(first_progress.value - 35.0) <= 0.1, "Inbound mission dropship card shows transfer progress while the ship itself is still off-map")
		var first_passenger_host := first_card.get_node_or_null("MarginContainer/VBox/ExtraContentHost") as VBoxContainer
		var second_passenger_host := second_card.get_node_or_null("MarginContainer/VBox/ExtraContentHost") as VBoxContainer
		_assert(first_passenger_host != null and first_passenger_host.get_child_count() > 0, "Mission Dropship 1 card embeds its passenger overview on the mission map")
		_assert(second_passenger_host != null and second_passenger_host.get_child_count() > 0, "Mission Dropship 2 card embeds its passenger overview on the mission map")

		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		controller.call("_set_selected_fireteams", PackedStringArray(), false)
		await _wait_frames(2)
		second_card = panel.get_child(1) as Control
		second_card.emit_signal("gui_input", click)
		await _wait_frames(4)

		var selected_state: Dictionary = Dictionary(controller.call("get_planning_state"))
		var refreshed_second_card := panel.get_child(1) as Control
		_assert(String(selected_state.get("mission_drop_craft_id", "")) == "dropship_2", "Clicking the right-side Dropship 2 card selects it for Mission Control")
		_assert(String(selected_state.get("mission_drop_state", "")) == "waiting", "Selected Dropship 2 carries its waiting state into Mission Control")
		_assert(Array(selected_state.get("embarked_unit_ids", [])) == ["unit_echo", "unit_foxtrot", "unit_golf", "unit_hotel"], "Selected Dropship 2 carries its own boarded payload")
		_assert(Array(controller.call("get_selected_fireteam_ids")).is_empty(), "Selecting a dropship card does not silently select its fireteam into #17")
		_assert(bool(refreshed_second_card.get_meta("mission_dropship_selected", false)), "Selected mission dropship card is marked in the #19 panel")
		var selected_stylebox := refreshed_second_card.get_theme_stylebox("panel") as StyleBoxFlat
		_assert(selected_stylebox != null and selected_stylebox.border_color.g > selected_stylebox.border_color.r and selected_stylebox.border_width_left >= 2, "Selected mission dropship card uses a clear green outline")
		var return_button := refreshed_second_card.get_node_or_null("MarginContainer/VBox/HeaderRow/PrimaryActionButton") as Button
		_assert(return_button != null and return_button.visible and not return_button.disabled and return_button.text == "FOB", "Waiting mission dropship card exposes a direct Return-to-FOB button")
		if return_button != null:
			return_button.emit_signal("pressed")
			await _wait_frames(2)
			var return_state: Dictionary = Dictionary(controller.call("get_planning_state"))
			_assert(String(return_state.get("mission_drop_state", "")) == "to_fob" and bool(return_state.get("mission_drop_return_requested", false)), "Return-to-FOB button marks the selected dropship as RTB")
			_assert(Array(return_state.get("embarked_unit_ids", [])) == ["unit_echo", "unit_foxtrot", "unit_golf", "unit_hotel"], "Manual RTB keeps the selected dropship payload until it reaches FOB")
			selected_state = return_state
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


func _test_second_dropship_can_be_selected_and_planned_while_first_is_inbound() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(4)

	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Mission scene exposes tactical controller for inbound selection handoff")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	planning_state["mission_drop_craft_id"] = "dropship_1"
	planning_state["mission_drop_state"] = "waiting"
	planning_state["has_lz_position"] = true
	planning_state["lz_position"] = Vector2(320.0, 180.0)
	planning_state["deployed_unit_ids"] = []
	planning_state["deployed_unit_positions"] = {}
	planning_state["mission_drop_cards"] = [
		{
			"craft_id": "dropship_1",
			"display_name": "Dropship 1",
			"state": "waiting",
			"progress": 100.0,
			"embarked_unit_ids": ["unit_alpha", "unit_bravo", "unit_charlie", "unit_delta"],
			"boarded_fireteam_ids": ["blue"],
			"has_lz_position": true,
			"lz_position": Vector2(320.0, 180.0),
			"approach_angle": "NW",
		},
		{
			"craft_id": "dropship_2",
			"display_name": "Dropship 2",
			"state": "waiting",
			"progress": 100.0,
			"embarked_unit_ids": ["unit_echo", "unit_foxtrot", "unit_golf", "unit_hotel"],
			"boarded_fireteam_ids": ["gold"],
			"has_lz_position": true,
			"lz_position": Vector2(576.0, 288.0),
			"approach_angle": "SE",
		},
	]
	controller.call("set_planning_state", planning_state)
	_assert(bool(controller.call("_try_start_drop_sequence")), "First dropship starts an active inbound drop run")
	_assert(String(controller.get("_drop_sequence_phase")) == "inbound", "First dropship is inbound before selecting the second craft")
	_assert(Vector2(controller.get("_drop_sequence_lz_position")).is_equal_approx(Vector2(320.0, 180.0)), "Dropship 1 snapshots LZ1 into its active drop sequence")
	var started_first_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	var started_first_card: Dictionary = _find_card(Array(started_first_state.get("mission_drop_cards", [])), "dropship_1")
	_assert(Array(started_first_card.get("boarded_fireteam_ids", [])) == ["blue"], "Dropship 1 snapshots the fireteam identity from its own payload")

	_assert(bool(controller.call("_select_mission_dropship_craft", "dropship_2", false)), "Dropship 2 can be selected while Dropship 1 is inbound")
	var selected_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	_assert(String(selected_state.get("mission_drop_craft_id", "")) == "dropship_2", "Mission Control switches to Dropship 2 during Dropship 1 inbound")
	_assert(String(controller.get("_drop_sequence_craft_id")) == "dropship_1" and String(controller.get("_drop_sequence_phase")) == "inbound", "Dropship 1 keeps owning the live inbound sequence after selection changes")
	_assert(Vector2(selected_state.get("lz_position", Vector2.ZERO)).is_equal_approx(Vector2(576.0, 288.0)), "Dropship 2 keeps its own LZ while Dropship 1 is inbound")
	controller.set("_has_lz_position", true)
	controller.set("_lz_position", Vector2(704.0, 352.0))
	controller.call("_select_approach_angle", "SE")
	await _wait_frames(2)
	var replanned_second_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	var replanned_first_card: Dictionary = _find_card(Array(replanned_second_state.get("mission_drop_cards", [])), "dropship_1")
	var replanned_second_card: Dictionary = _find_card(Array(replanned_second_state.get("mission_drop_cards", [])), "dropship_2")
	_assert(Vector2(controller.get("_drop_sequence_lz_position")).is_equal_approx(Vector2(320.0, 180.0)), "Changing Dropship 2 to LZ2 does not retarget the active Dropship 1 sequence")
	_assert(Vector2(replanned_first_card.get("lz_position", Vector2.ZERO)).is_equal_approx(Vector2(320.0, 180.0)), "Dropship 1 card keeps LZ1 after Dropship 2 is replanned")
	_assert(Vector2(replanned_second_card.get("lz_position", Vector2.ZERO)).is_equal_approx(Vector2(704.0, 352.0)), "Dropship 2 replaces its old LZ with the newly placed LZ2")
	_assert(_is_numbered_lz_label_for_craft(replanned_first_card, "LZ1", "Dropship 1") and _is_numbered_lz_label_for_craft(replanned_second_card, "LZ2", "Dropship 2"), "Planned LZ labels are numbered and named after their owning dropship")
	_assert(Array(replanned_first_card.get("boarded_fireteam_ids", [])) == ["blue"] and Array(replanned_second_card.get("boarded_fireteam_ids", [])) == ["gold"], "Dropship cards keep their own boarded fireteam identity while selection changes")

	controller.call("_on_call_dropship_pressed")
	await _wait_frames(2)
	var simultaneous_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	var simultaneous_first_card: Dictionary = _find_card(Array(simultaneous_state.get("mission_drop_cards", [])), "dropship_1")
	var simultaneous_second_card: Dictionary = _find_card(Array(simultaneous_state.get("mission_drop_cards", [])), "dropship_2")
	var parallel_sequences: Dictionary = Dictionary(controller.get("_parallel_drop_sequences_by_craft"))
	_assert(parallel_sequences.has("dropship_1"), "Dropship 1 keeps flying as a craft-bound parallel sequence while Dropship 2 starts")
	_assert(String(controller.get("_drop_sequence_craft_id")) == "dropship_2" and String(controller.get("_drop_sequence_phase")) == "inbound", "Dropship 2 starts its own live inbound sequence instead of waiting in a queue")
	_assert(String(simultaneous_first_card.get("state", "")) == "inbound" and String(simultaneous_second_card.get("state", "")) == "inbound", "Both dropships can be inbound at the same time")
	_assert(not String(controller.get("_last_command_text")).begins_with("AIR LANE BUSY"), "Drop button no longer reports a fake single-air-lane block")

	for _step in range(180):
		controller.call("_update_drop_sequence", 0.2)
		var step_state: Dictionary = Dictionary(controller.call("get_planning_state"))
		var step_first_card: Dictionary = _find_card(Array(step_state.get("mission_drop_cards", [])), "dropship_1")
		var step_second_card: Dictionary = _find_card(Array(step_state.get("mission_drop_cards", [])), "dropship_2")
		if Array(step_first_card.get("embarked_unit_ids", [])).is_empty() and Array(step_second_card.get("embarked_unit_ids", [])).is_empty():
			break
	var after_first_drop_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	var first_card: Dictionary = _find_card(Array(after_first_drop_state.get("mission_drop_cards", [])), "dropship_1")
	var second_card_after_drop: Dictionary = _find_card(Array(after_first_drop_state.get("mission_drop_cards", [])), "dropship_2")
	var deployed_unit_ids: Array = Array(after_first_drop_state.get("deployed_unit_ids", []))
	var deployed_unit_positions: Dictionary = Dictionary(after_first_drop_state.get("deployed_unit_positions", {}))
	_assert(deployed_unit_ids.has("unit_alpha") and deployed_unit_ids.has("unit_echo"), "Both craft-bound drops deploy their own payload units")
	_assert(Array(first_card.get("embarked_unit_ids", [])).is_empty(), "Dropship 1 deploys its own payload instead of consuming Dropship 2's queued payload")
	_assert(Array(second_card_after_drop.get("embarked_unit_ids", [])).is_empty(), "Dropship 2 deploys its own payload instead of reusing Dropship 1's payload")
	_assert(Vector2(first_card.get("lz_position", Vector2.ZERO)).is_equal_approx(Vector2(320.0, 180.0)), "Dropship 1 completes its drop at LZ1 even after Dropship 2 planned LZ2")
	_assert(Vector2(second_card_after_drop.get("lz_position", Vector2.ZERO)).is_equal_approx(Vector2(704.0, 352.0)), "Dropship 2 completes its own drop at LZ2")
	_assert(Vector2(deployed_unit_positions.get("unit_alpha", Vector2.ZERO)).is_equal_approx(Vector2(276.0, 198.0)), "Dropship 1 stores the deployed FT1 position from LZ1, not the later selected LZ2")
	_assert(Vector2(deployed_unit_positions.get("unit_echo", Vector2.ZERO)).is_equal_approx(Vector2(748.0, 334.0)), "Dropship 2 stores the deployed FT2 position from LZ2")

	scene.queue_free()
	await _wait_frames(2)


func _test_second_dropship_can_drop_after_first_hands_off_to_return() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(4)

	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Mission scene exposes tactical controller for sequential dropship drop")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	planning_state["mission_drop_craft_id"] = "dropship_1"
	planning_state["mission_drop_state"] = "waiting"
	planning_state["has_lz_position"] = true
	planning_state["lz_position"] = Vector2(320.0, 180.0)
	planning_state["deployed_unit_ids"] = []
	planning_state["deployed_unit_positions"] = {}
	planning_state["mission_drop_cards"] = [
		{
			"craft_id": "dropship_1",
			"display_name": "Dropship 1",
			"state": "waiting",
			"progress": 100.0,
			"embarked_unit_ids": ["unit_alpha", "unit_bravo", "unit_charlie", "unit_delta"],
			"boarded_fireteam_ids": ["blue"],
			"has_lz_position": true,
			"lz_position": Vector2(320.0, 180.0),
			"approach_angle": "NW",
		},
		{
			"craft_id": "dropship_2",
			"display_name": "Dropship 2",
			"state": "waiting",
			"progress": 100.0,
			"embarked_unit_ids": ["unit_echo", "unit_foxtrot", "unit_golf", "unit_hotel"],
			"boarded_fireteam_ids": ["gold"],
			"has_lz_position": true,
			"lz_position": Vector2(576.0, 288.0),
			"approach_angle": "SE",
		},
	]
	controller.call("set_planning_state", planning_state)
	_assert(bool(controller.call("_try_start_drop_sequence")), "First waiting dropship can start its drop sequence")
	for _step in range(180):
		controller.call("_update_drop_sequence", 0.2)
		if String(controller.get("_drop_sequence_phase")) == "outbound":
			break
	_assert(String(controller.get("_drop_sequence_phase")) == "outbound", "First dropship reaches outbound return after deploying its team")

	_assert(bool(controller.call("_select_mission_dropship_craft", "dropship_2", false)), "Selecting Dropship 2 hands off the outbound first craft instead of keeping the global drop slot blocked")
	var after_select_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	var first_card: Dictionary = _find_card(Array(after_select_state.get("mission_drop_cards", [])), "dropship_1")
	var parallel_sequences: Dictionary = Dictionary(controller.get("_parallel_drop_sequences_by_craft"))
	_assert(String(first_card.get("state", "")) == "outbound" and parallel_sequences.has("dropship_1"), "First dropship keeps flying its RTB leg as a craft-bound parallel sequence after handoff")
	controller.set("_has_lz_position", true)
	controller.set("_lz_position", Vector2(576.0, 288.0))
	_assert(bool(controller.call("_try_start_drop_sequence")), "Second waiting dropship can start its own drop after the first one is returning")
	_assert(String(controller.get("_drop_sequence_phase")) == "inbound", "Second dropship owns the next inbound sequence")

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


func _is_numbered_lz_label_for_craft(card: Dictionary, expected_prefix: String, expected_display_name: String) -> bool:
	var label: String = String(card.get("lz_label", card.get("lz_name", ""))).strip_edges()
	return label.begins_with(expected_prefix) and label.find(expected_display_name) >= 0


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
