extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1134 Selected Fireteam Stance Control Consistency ===")
	root.size = Vector2i(1920, 1080)
	var mission: Node = MISSION_SCENE.instantiate()
	root.add_child(mission)
	for _frame in range(16):
		await process_frame
	var controller := mission.get_node_or_null("TacticalController")
	var panel := mission.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamInfoScroll/FireteamInfoVBox/TacticalStancePanel") as Control
	var blue_card := mission.get_node_or_null("TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox/FireteamMiniCard_Blue") as Control
	_assert(controller != null and panel != null and blue_card != null, "Mission exposes controller, selected-fireteam stance panel and BLUE mini-card")
	if controller != null and panel != null and blue_card != null:
		_test_shared_visual_contract(panel, blue_card)
		await _test_selected_state(controller, panel)
		_test_mixed_selected_state(controller, panel)
		_test_selected_fireteam_interaction(controller, panel)
		_test_panel_bounds(panel)
	mission.queue_free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_shared_visual_contract(panel: Control, mini_card: Control) -> void:
	var panel_buttons := _panel_buttons(panel)
	var mini_buttons := _mini_buttons(mini_card)
	_assert(panel_buttons.size() == 3 and mini_buttons.size() == 3, "Both stance surfaces expose three segments")
	var expected_text := ["VORS", "NORM", "OFF"]
	for index in range(mini(panel_buttons.size(), mini_buttons.size())):
		var panel_button := panel_buttons[index] as Button
		var mini_button := mini_buttons[index] as Button
		_assert(panel_button.text == expected_text[index], "Selected-fireteam segment uses %s" % expected_text[index])
		_assert(panel_button.icon != null and panel_button.icon.resource_path == mini_button.icon.resource_path, "%s uses the same stable icon on both surfaces" % expected_text[index])
		_assert(panel_button.tooltip_text == mini_button.tooltip_text and panel_button.tooltip_text.contains("Tempo"), "%s uses the same effect tooltip on both surfaces" % expected_text[index])


func _test_selected_state(controller: Node, panel: Control) -> void:
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("set_selected_fireteams_tactical_stance", "normal")
	await process_frame
	var selected_count := 0
	for button_variant in _panel_buttons(panel):
		var button := button_variant as Button
		if button.button_pressed:
			selected_count += 1
	var normal := panel.find_child("NormalButton", true, false) as Button
	var summary := panel.find_child("SummaryLabel", true, false) as Label
	_assert(selected_count == 1 and normal != null and normal.button_pressed, "Homogeneous selection exposes exactly one active segment")
	_assert(normal != null and bool(normal.get_meta("mission_selected_fireteam_stance_selected", false)), "Active segment exposes stable selected metadata")
	_assert(summary != null and summary.text.contains("HALTUNG NORMAL") and not summary.text.contains("STANCE"), "Selected-fireteam summary uses readable German game language")


func _test_selected_fireteam_interaction(controller: Node, panel: Control) -> void:
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	var cautious := panel.find_child("CautiousButton", true, false) as Button
	_assert(cautious != null and cautious.pressed.get_connections().size() > 0, "VORS keeps the selected-fireteam stance callback")
	if cautious == null:
		return
	controller.call("_on_tactical_stance_button_pressed", cautious)
	var snapshot: Dictionary = Dictionary(controller.call("get_tactical_stances_snapshot"))
	_assert(String(snapshot.get("blue", "")) == "cautious", "Selected-fireteam VORS updates BLUE through the existing stance path")
	_assert(String(snapshot.get("gold", "normal")) == "normal", "Single-selection stance input leaves GOLD unchanged")


func _test_mixed_selected_state(controller: Node, panel: Control) -> void:
	controller.call("set_fireteams_tactical_stance", PackedStringArray(["blue"]), "cautious")
	controller.call("set_fireteams_tactical_stance", PackedStringArray(["gold"]), "normal")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue", "gold"]), false)
	var selected_count := 0
	for button_variant in _panel_buttons(panel):
		if (button_variant as Button).button_pressed:
			selected_count += 1
	var summary := panel.find_child("SummaryLabel", true, false) as Label
	_assert(selected_count == 0, "Mixed multi-selection marks no stance segment as shared")
	_assert(summary != null and summary.text.contains("HALTUNG GEMISCHT"), "Mixed multi-selection is named explicitly")


func _test_panel_bounds(panel: Control) -> void:
	var row := panel.get_node_or_null("MarginContainer/VBoxContainer/HBoxContainer") as Control
	_assert(row != null and panel.get_global_rect().grow(1.0).encloses(row.get_global_rect()), "Selected-fireteam stance row stays inside its panel")


func _panel_buttons(panel: Control) -> Array:
	var result: Array = []
	for node_name in ["CautiousButton", "NormalButton", "AggressiveButton"]:
		var button := panel.find_child(node_name, true, false) as Button
		if button != null:
			result.append(button)
	return result


func _mini_buttons(card: Control) -> Array:
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
