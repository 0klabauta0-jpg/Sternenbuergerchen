extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1133 Fireteam Mini-Card Stance Control Readability ===")
	root.size = Vector2i(1920, 1080)
	var mission: Node = MISSION_SCENE.instantiate()
	root.add_child(mission)
	for _frame in range(16):
		await process_frame
	var controller := mission.get_node_or_null("TacticalController")
	var blue_card := mission.get_node_or_null("TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox/FireteamMiniCard_Blue") as Control
	var gold_card := mission.get_node_or_null("TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox/FireteamMiniCard_Gold") as Control
	_assert(controller != null and blue_card != null and gold_card != null, "Mission exposes controller and both Fireteam mini-cards")
	if controller != null and blue_card != null and gold_card != null:
		_test_segment_readability(blue_card)
		_test_selected_state(blue_card)
		_test_fireteam_specific_interaction(controller, blue_card)
		_test_layout_bounds(blue_card, gold_card)
	mission.queue_free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_segment_readability(card: Control) -> void:
	var buttons := _stance_buttons(card)
	_assert(buttons.size() == 3, "Mini-card exposes three stance segments")
	var expected_text := ["VORS", "NORM", "OFF"]
	for index in range(mini(buttons.size(), expected_text.size())):
		var button := buttons[index] as Button
		_assert(button.text == expected_text[index], "%s stance segment uses a readable label" % expected_text[index])
		_assert(button.icon != null and button.expand_icon and not String(button.icon.resource_path).is_empty(), "%s stance segment uses a stable icon" % expected_text[index])
		_assert(button.tooltip_text.contains("Tempo") and button.tooltip_text.contains("Sicht"), "%s tooltip explains tactical effects" % expected_text[index])


func _test_selected_state(card: Control) -> void:
	var buttons := _stance_buttons(card)
	var selected_count := 0
	for button_variant in buttons:
		var button := button_variant as Button
		if button.button_pressed:
			selected_count += 1
	_assert(selected_count == 1, "Exactly one stance segment is selected per Fireteam")
	var normal := card.find_child("StanceNButton", true, false) as Button
	_assert(normal != null and normal.button_pressed and bool(normal.get_meta("mission_fireteam_stance_selected", false)), "Default normal stance is visibly selected")


func _test_fireteam_specific_interaction(controller: Node, blue_card: Control) -> void:
	var cautious := blue_card.find_child("StanceCButton", true, false) as Button
	_assert(cautious != null, "BLUE card exposes the cautious stance action")
	if cautious == null:
		return
	_assert(cautious.pressed.get_connections().size() > 0, "VORS keeps an existing stance callback")
	controller.call("_on_fireteam_mini_stance_button_pressed", "blue", "cautious")
	var snapshot: Dictionary = Dictionary(controller.call("get_tactical_stances_snapshot"))
	_assert(String(snapshot.get("blue", "")) == "cautious", "Clicking VORS updates BLUE through the existing stance path")
	_assert(String(snapshot.get("gold", "normal")) == "normal", "Clicking BLUE leaves GOLD stance unchanged")


func _test_layout_bounds(blue_card: Control, gold_card: Control) -> void:
	for card in [blue_card, gold_card]:
		var row := card.find_child("StanceToggle", true, false) as HBoxContainer
		_assert(row != null and card.get_global_rect().encloses(row.get_global_rect()), "%s stance segments stay inside the card" % String(card.get_meta("fireteam_id", "")).to_upper())


func _stance_buttons(card: Control) -> Array:
	var result: Array = []
	for node_name in ["StanceCButton", "StanceNButton", "StanceAButton"]:
		var button := card.find_child(node_name, true, false) as Button
		if button != null:
			result.append(button)
	return result


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
