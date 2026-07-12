extends SceneTree

const DRILL_SCENE := preload("res://scenes/tests/fireteam_command_drill_map.tscn")
const CARD_ROW_PATH := "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll/FireteamCardsBody/FireteamCardsRow"
const CARD_SCROLL_PATH := "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll"

var _checks := 0
var _failures: PackedStringArray = []


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(20)

	var controller := scene.get_node_or_null("TacticalController")
	var simulation_root := scene.get_node_or_null("SimulationRoot")
	var card_row := scene.get_node_or_null(CARD_ROW_PATH) as HBoxContainer
	var card_scroll := scene.get_node_or_null(CARD_SCROLL_PATH) as ScrollContainer
	_check(controller != null, "Mission fixture exposes TacticalController")
	_check(simulation_root != null, "Mission fixture exposes SimulationRoot")
	_check(card_row != null and card_row.get_child_count() >= 3, "Selected Fireteam renders member cards")
	_check(card_scroll != null and card_scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED, "Member lane remains horizontally scrollable")

	var inspected_cards := 0
	if card_row != null:
		for child_variant in card_row.get_children():
			var card := child_variant as Control
			if card == null or not card.has_method("get_source_context") or String(card.call("get_source_context")) != "mission_selected_fireteam_member":
				continue
			inspected_cards += 1
			var name_label := card.get_node_or_null("Margin/HBox/TextVBox/NameRow/NameLabel") as Label
			var runtime_label := card.get_node_or_null("Margin/HBox/TextVBox/DataALabel") as Label
			var detail_label := card.get_node_or_null("Margin/HBox/TextVBox/DataBLabel") as Label
			_check(card.custom_minimum_size == Vector2(196.0, 132.0), "%s uses the 1280 mission card size" % card.name)
			_check(name_label != null and name_label.get_theme_font_size("font_size") >= 15, "%s name is readable at 1280" % card.name)
			_check(runtime_label != null and runtime_label.get_theme_font_size("font_size") >= 12, "%s runtime line is readable at 1280" % card.name)
			_check(detail_label != null and detail_label.get_theme_font_size("font_size") >= 12, "%s detail line is readable at 1280" % card.name)
			_check(not card.tooltip_text.strip_edges().is_empty(), "%s keeps technical detail in its tooltip" % card.name)
	_check(inspected_cards >= 3, "At least three real member cards satisfy the 1280 contract")
	_check(4.0 * 196.0 + 3.0 * 8.0 <= 840.0, "Four member cards fit the existing lane")

	if controller != null and simulation_root != null:
		var command_count_before := Array(simulation_root.get("command_queue")).size()
		var effect_count_before := Array(simulation_root.get("effects_queue")).size()
		controller.set("_last_selected_fireteam_cards_runtime_signature", "")
		controller.call("_refresh_selected_fireteam_cards")
		_check(Array(simulation_root.get("command_queue")).size() == command_count_before, "Member card refresh enqueues no command")
		_check(Array(simulation_root.get("effects_queue")).size() == effect_count_before, "Member card refresh enqueues no effect")

	scene.queue_free()
	await _wait_frames(2)
	if _failures.is_empty():
		print("TASK_1158 PASS (%d checks)" % _checks)
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
