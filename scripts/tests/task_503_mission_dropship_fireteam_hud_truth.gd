extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_503 Mission Dropship Fireteam HUD Truth ===")
	await _test_embarked_fireteam_stays_out_of_left_ground_hud()
	await _test_deployed_fireteam_returns_to_left_ground_hud()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_embarked_fireteam_stays_out_of_left_ground_hud() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(4)

	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Mission scene exposes tactical controller")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var blue_unit_ids: Array = _unit_ids(Array(controller.call("_get_fireteam_units", "blue", true)))
	var gold_unit_ids: Array = _unit_ids(Array(controller.call("_get_fireteam_units", "gold", true)))
	var planning_state: Dictionary = _build_two_dropship_planning_state(controller, "dropship_1", true, blue_unit_ids, gold_unit_ids)
	planning_state["selected_fireteams"] = ["blue"]
	controller.call("set_planning_state", planning_state)
	await _wait_frames(8)

	var displayable_fireteams: PackedStringArray = PackedStringArray(controller.call("_get_displayable_fireteam_ids"))
	var mini_card_ids: Array = _get_mini_card_fireteam_ids(scene)
	_assert(not displayable_fireteams.has("blue"), "Embarked FT1 is not displayable as a ground fireteam")
	_assert(not mini_card_ids.has("blue"), "Left FireteamMiniPanel hides embarked FT1")
	_assert(mini_card_ids.has("gold"), "Left FireteamMiniPanel still shows ground FT2")
	_assert(_selected_fireteam_panel_shows_embarked_hint(scene), "Selected embarked FT1 shows only the Dropship hint in #17")
	_assert(_count_selected_member_cards(scene) == 0, "Selected embarked FT1 does not render member cards as ground operators")

	scene.queue_free()
	await _wait_frames(2)


func _test_deployed_fireteam_returns_to_left_ground_hud() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(4)

	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Mission scene exposes tactical controller for deployed HUD check")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var blue_unit_ids: Array = _unit_ids(Array(controller.call("_get_fireteam_units", "blue", true)))
	var gold_unit_ids: Array = _unit_ids(Array(controller.call("_get_fireteam_units", "gold", true)))
	var planning_state: Dictionary = _build_two_dropship_planning_state(controller, "dropship_1", false, blue_unit_ids, gold_unit_ids)
	planning_state["embarked_unit_ids"] = []
	planning_state["deployed_unit_ids"] = blue_unit_ids.duplicate()
	planning_state["deployed_unit_positions"] = _build_deployed_positions(blue_unit_ids, Vector2(320.0, 180.0))
	planning_state["selected_fireteams"] = ["blue"]
	planning_state["mission_drop_cards"][0]["state"] = "outbound"
	planning_state["mission_drop_cards"][0]["progress"] = 100.0
	planning_state["mission_drop_cards"][0]["embarked_unit_ids"] = []
	planning_state["mission_drop_cards"][0]["card_feedback_text"] = "Trupp ab"
	controller.call("set_planning_state", planning_state)
	await _wait_frames(12)

	var displayable_fireteams: PackedStringArray = PackedStringArray(controller.call("_get_displayable_fireteam_ids"))
	var mini_card_ids: Array = _get_mini_card_fireteam_ids(scene)
	_assert(displayable_fireteams.has("blue"), "Deployed FT1 is displayable as a ground fireteam")
	_assert(mini_card_ids.has("blue"), "Left FireteamMiniPanel shows deployed FT1")
	_assert(_count_selected_member_cards(scene) >= blue_unit_ids.size(), "Selected deployed FT1 renders member cards in #17")

	scene.queue_free()
	await _wait_frames(2)


func _build_two_dropship_planning_state(controller, selected_craft_id: String, blue_embarked: bool, blue_unit_ids: Array, gold_unit_ids: Array) -> Dictionary:
	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	planning_state["mission_drop_craft_id"] = selected_craft_id
	planning_state["mission_drop_state"] = "waiting"
	planning_state["has_lz_position"] = true
	planning_state["lz_position"] = Vector2(320.0, 180.0)
	planning_state["deployed_unit_ids"] = []
	planning_state["deployed_unit_positions"] = {}
	planning_state["embarked_unit_ids"] = blue_unit_ids.duplicate() if blue_embarked else []
	planning_state["mission_drop_cards"] = [
		{
			"craft_id": "dropship_1",
			"display_name": "Dropship 1",
			"title_text": "#19 Dropship 1",
			"state": "waiting",
			"progress": 100.0,
			"passenger_count": blue_unit_ids.size() if blue_embarked else 0,
			"embarked_unit_ids": blue_unit_ids.duplicate() if blue_embarked else [],
			"boarded_fireteam_ids": ["blue"],
			"has_lz_position": true,
			"lz_position": Vector2(320.0, 180.0),
			"approach_angle": "NW",
		},
		{
			"craft_id": "dropship_2",
			"display_name": "Dropship 2",
			"title_text": "#19 Dropship 2",
			"state": "waiting",
			"progress": 100.0,
			"passenger_count": 0,
			"embarked_unit_ids": [],
			"boarded_fireteam_ids": ["gold"],
			"has_lz_position": true,
			"lz_position": Vector2(576.0, 288.0),
			"approach_angle": "SE",
		},
	]
	return planning_state


func _build_deployed_positions(unit_ids: Array, origin: Vector2) -> Dictionary:
	var result: Dictionary = {}
	for index in range(unit_ids.size()):
		result[String(unit_ids[index])] = origin + Vector2(float(index) * 20.0, float(index) * 10.0)
	return result


func _unit_ids(units: Array) -> Array:
	var result: Array = []
	for unit in units:
		if unit != null and unit.has_method("get_unit_id"):
			result.append(String(unit.call("get_unit_id")))
	return result


func _get_mini_card_fireteam_ids(scene: Node) -> Array:
	var result: Array = []
	var host := scene.get_node_or_null("TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox") as VBoxContainer
	if host == null:
		return result
	for child in host.get_children():
		var fireteam_id: String = String(child.get_meta("fireteam_id", "")).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		result.append(fireteam_id)
	result.sort()
	return result


func _selected_fireteam_panel_shows_embarked_hint(scene: Node) -> bool:
	var card_row := scene.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll/FireteamCardsBody/FireteamCardsRow") as HBoxContainer
	if card_row == null:
		return false
	for child in card_row.get_children():
		var label := child as Label
		if label != null and label.text.find("Fireteam im Dropship") >= 0:
			return true
	return false


func _count_selected_member_cards(scene: Node) -> int:
	var card_row := scene.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll/FireteamCardsBody/FireteamCardsRow") as HBoxContainer
	if card_row == null:
		return 0
	var count: int = 0
	for child in card_row.get_children():
		if child is Label:
			continue
		count += 1
	return count


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
