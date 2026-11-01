extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const GRID_PATH := "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid"
const TEAM_PATH := "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel"
const FIRST_ROW: PackedStringArray = ["MoveButton", "TakeButton", "HoldButton", "FlankButton", "GoCommandMatrixButton"]
const SECOND_ROW: PackedStringArray = ["TargetButton", "ClearTargetButton", "DeleteOrderButton", "SortCommandMatrixButton"]
const FIRE_RULES: PackedStringArray = ["FireRuleHoldButton", "FireRuleReturnButton", "FireRuleFreeButton", "FireRuleSuppressButton"]

var _checks := 0
var _failed: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== Native A5 Mission HUD ===")
	await _check_mission(Vector2i(1920, 1080))
	await _check_mission(Vector2i(1280, 720))
	for failure in _failed:
		push_error(failure)
	print("Native A5: %d checks, %d failures" % [_checks, _failed.size()])
	if _failed.is_empty():
		print("PASS: native A5 HUD")
	quit(0 if _failed.is_empty() else 1)


func _check_mission(window_size: Vector2i) -> void:
	root.size = window_size
	var scene: Node = MISSION_SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(16):
		await process_frame
	var prefix := "%dx%d: " % [window_size.x, window_size.y]
	var viewport_rect := scene.get_viewport().get_visible_rect()
	var controller := scene.get_node_or_null("TacticalController")
	var grid := scene.get_node_or_null(GRID_PATH) as GridContainer
	var band := scene.get_node_or_null("TacticalUI/BottomDock") as Control
	var target := scene.get_node_or_null("TacticalUI/A5TargetOrderPanel") as Control
	var team := scene.get_node_or_null(TEAM_PATH) as Control
	_check(controller != null and grid != null and band != null and team != null, prefix + "existing mission controls remain addressable")
	if controller == null or grid == null or band == null or team == null:
		scene.queue_free()
		await process_frame
		return
	var band_rect := band.get_global_rect()
	_check(is_equal_approx(band_rect.position.x, 0.0) and absf(band_rect.end.y - viewport_rect.end.y) <= 1.0, prefix + "band is flush with lower-left viewport edge")
	_check(band_rect.size.y <= 200.0, prefix + "band leaves the map the main surface")
	_check(target != null, prefix + "target/order has a separate native middle panel")
	if target != null:
		var target_rect := target.get_global_rect()
		_check(target_rect.end.x <= team.get_global_rect().position.x + 1.0, prefix + "target/order precedes selected-team parameters")
		_check(band_rect.encloses(target_rect), prefix + "target/order fits within the command band")
	var row_y := PackedFloat32Array()
	var all_buttons: Array[Button] = []
	for row_index in range(2):
		var names: PackedStringArray = FIRST_ROW if row_index == 0 else SECOND_ROW
		var previous_right := -1.0
		var current_y := -1.0
		for button_name in names:
			var button := grid.get_node_or_null(NodePath(button_name)) as Button
			_check(button != null, prefix + button_name + " preserves its original NodePath")
			if button == null:
				continue
			var rect := button.get_global_rect()
			all_buttons.append(button)
			_check(button.is_visible_in_tree(), prefix + button_name + " is visible")
			_check(absf(rect.size.x - rect.size.y) <= 1.0 and absf(rect.size.x - 64.0) <= 1.0, prefix + button_name + " has a real 64x64 action body (actual=%s, minimum=%s)" % [rect.size, button.get_combined_minimum_size()])
			_check(not button.text.strip_edges().is_empty(), prefix + button_name + " has an inside label")
			_check(not button.get_signal_connection_list("pressed").is_empty(), prefix + button_name + " retains its existing action callback")
			_check(band_rect.encloses(rect), prefix + button_name + " is not clipped outside the band")
			_check(not button.tooltip_text.strip_edges().is_empty(), prefix + button_name + " retains an explanation or disabled reason")
			if current_y < 0.0:
				current_y = rect.position.y
			_check(absf(current_y - rect.position.y) <= 1.0 and rect.position.x >= previous_right - 1.0, prefix + button_name + " follows its row without overlap")
			previous_right = rect.end.x
			if target != null:
				_check(rect.end.x <= target.get_global_rect().position.x + 1.0, prefix + button_name + " remains left of target/order")
		row_y.append(current_y)
	_check(row_y.size() == 2 and row_y[1] >= row_y[0] + 64.0, prefix + "actions occupy two actual rows")
	for first in range(all_buttons.size()):
		for second in range(first + 1, all_buttons.size()):
			_check(not all_buttons[first].get_global_rect().intersects(all_buttons[second].get_global_rect()), prefix + "primary action rectangles do not overlap")
	for panel_path in ["TacticalUI/FireteamMiniPanel", "TacticalUI/TacticalEventLogPanel"]:
		var panel := scene.get_node_or_null(NodePath(panel_path)) as Control
		_check(panel != null and panel.get_global_rect().end.y <= band_rect.position.y + 1.0, prefix + panel_path + " remains above the band")
	var event_log := scene.get_node_or_null("TacticalUI/TacticalEventLogPanel") as Control
	_check(event_log != null and event_log.get_global_rect().position.x >= viewport_rect.size.x * 0.5, prefix + "event log occupies the right side above the band")
	var mission_control := scene.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel") as Control
	_check(mission_control != null and mission_control.get_global_rect().position.y <= 144.0, prefix + "mission controls stay in the upper-right group")
	_check(mission_control != null and event_log != null and not mission_control.get_global_rect().intersects(event_log.get_global_rect()), prefix + "mission controls and protocol remain separate")
	for button_name in FIRE_RULES:
		var button := grid.get_node_or_null(NodePath(button_name)) as Button
		var selector := team.get_node_or_null("A5FireRuleSelector") as OptionButton
		_check(button != null and selector != null and selector.is_visible_in_tree() and selector.item_count == 4, prefix + button_name + " stays reachable through the four-rule selector")
		if button != null:
			_check(team.get_global_rect().encloses(button.get_global_rect()), prefix + button_name + " belongs to selected-team parameters")
			_check(selector != null and selector.z_index > team.z_index, prefix + "rule selector draws above the later team-panel background")
			_check(not button.get_signal_connection_list("pressed").is_empty(), prefix + button_name + " retains its callback")
	var identity := team.get_node_or_null("A5TeamIdentity") as Control
	var character_overlay := scene.get_node_or_null("TacticalUI/CharacterOverlay") as Control
	var mini_cards := scene.get_node_or_null("TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox")
	var highest_card_z := 0
	if mini_cards != null:
		for card in mini_cards.get_children():
			if card is CanvasItem:
				highest_card_z = maxi(highest_card_z, card.z_index)
	_check(character_overlay != null and not character_overlay.z_as_relative and character_overlay.z_index > highest_card_z, prefix + "character overlay has absolute drawing priority above actual mini cards (%d)" % highest_card_z)
	var stance := scene.get_node_or_null(TEAM_PATH + "/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamInfoScroll/FireteamInfoVBox/TacticalStancePanel") as Control
	_check(identity != null and stance != null and identity.get_global_rect().end.y <= stance.get_global_rect().position.y, prefix + "team heading and stance have separate readable lines")
	var status_readout := scene.get_node_or_null(TEAM_PATH + "/FireteamMargin/FireteamVBox/FireteamHeaderRow/FireteamStatusLabel") as Label
	var details := team.get_node_or_null("A5DetailsButton") as Button
	_check(status_readout != null and details != null and details.is_visible_in_tree(), prefix + "existing tactical feedback remains reachable through explicit details")
	if details != null and status_readout != null:
		details.pressed.emit()
		var popup := scene.get_node("TacticalUI/A5TeamDetailsPopup") as PopupPanel
		var text := popup.get_node("Margin/Box/Scroll/Text") as Label
		_check(popup.visible and text.text.contains(status_readout.text) and not paused, prefix + "details show the original status while real time continues")
		popup.hide()
	if target != null:
		var target_label := target.get_node("Contents/Target") as Label
		var order_label := target.get_node("Contents/Order") as Label
		_check(target_label.text in ["Ziel gewählt", "Ziel auswählen"] and order_label.text.begins_with("Auftrag:"), prefix + "middle block names target state and order without technical coordinates")
		_check(not target_label.get_global_rect().intersects(order_label.get_global_rect()), prefix + "target and order lines do not overlap")
	for button_name in ["DoorBreachButton", "WaypointEraseButton"]:
		var button := grid.get_node_or_null(NodePath(button_name)) as Button
		_check(button != null and not button.get_signal_connection_list("pressed").is_empty(), prefix + button_name + " remains available as an existing contextual tool")
	for child in grid.get_children():
		if child is Button and bool(child.get_meta("drop_light_command_placeholder", false)):
			if child.disabled:
				_check(not child.is_visible_in_tree(), prefix + "unused reserve slots are not shown as fake active actions")
			else:
				_check(not child.text.strip_edges().is_empty() and not child.get_signal_connection_list("pressed").is_empty(), prefix + "existing contextual slot actions remain real controls")
	var layer := scene.get_node("TacticalUI")
	var geometry_before := int(grid.get_meta("native_a5_geometry_apply_count", 0))
	var rect_writes_before := int(layer.get_meta("native_a5_rect_write_count", 0))
	_check(rect_writes_before > 0, prefix + "rectangle-write instrumentation records the initial real placement")
	_check_slot_badges_hidden(grid, prefix + "initial ")
	# Reproduce the late legacy marker refresh after cached geometry exists.
	controller.call("_apply_command_button_markers")
	for _refresh in range(3):
		controller.call("_update_ui", false, false)
	_check_slot_badges_hidden(grid, prefix + "after legacy/state refresh ")
	_check(geometry_before > 0 and int(grid.get_meta("native_a5_geometry_apply_count", 0)) == geometry_before, prefix + "unchanged light refreshes skip A5 geometry configuration")
	_check(int(layer.get_meta("native_a5_rect_write_count", 0)) == rect_writes_before, prefix + "unchanged light refreshes queue no A5 rectangle writes")
	var target_button := grid.get_node("TargetButton") as Button
	target_button.pressed.emit()
	_check(bool(target_button.get_meta("native_a5_selected", false)) == bool(controller.get("_is_target_placement_armed")), prefix + "target-armed presentation still follows the real callback when geometry is cached")
	target_button.pressed.emit()
	controller.call("_set_selected_fireteams", PackedStringArray(), false)
	await process_frame
	var hierarchy: Dictionary = controller.call("get_command_hierarchy_snapshot")
	var actions: Dictionary = hierarchy.get("actions_by_id", {})
	_check(not bool(hierarchy.get("ui_sets_gameplay_truth", true)), prefix + "layout does not become a gameplay owner")
	_check(String(Dictionary(actions.get("move", {})).get("disabled_reason", "")).contains("select"), prefix + "no-selection command gate is preserved")
	controller.call("set_tactical_ui_visible", false)
	await process_frame
	_check(target == null or not target.is_visible_in_tree(), prefix + "new middle block follows tactical UI visibility")
	for button in all_buttons:
		_check(not button.is_visible_in_tree(), prefix + String(button.name) + " does not leak from a hidden tactical UI")
	scene.queue_free()
	for _frame in range(2):
		await process_frame


func _check(passed: bool, message: String) -> void:
	_checks += 1
	if not passed:
		_failed.append(message)


func _check_slot_badges_hidden(grid: GridContainer, prefix: String) -> void:
	var visible_badges: PackedStringArray = []
	for child in grid.get_children():
		if child is Button:
			var marker := child.get_node_or_null("TinyButtonMarker") as Control
			if marker != null and marker.is_visible_in_tree():
				visible_badges.append(String(child.name))
	_check(visible_badges.is_empty(), prefix + "internal slot badges stay hidden: " + ", ".join(visible_badges))
