extends SceneTree

const SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const HUD := preload("res://scripts/ui/mission_a5_hud_layout.gd")
const GRID := "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid"
const TEAM := "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel"
const INFO := TEAM + "/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamInfoScroll/FireteamInfoVBox"
const RULES: PackedStringArray = ["hold", "return", "free", "suppress"]
var _checks := 0
var _failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _check_scene(Vector2i(1920, 1080))
	await _check_scene(Vector2i(1280, 720))
	for failure in _failures:
		push_error(failure)
	print("Mission R2: %d checks, %d failures" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("PASS: native mission R2")
	quit(0 if _failures.is_empty() else 1)


func _check_scene(size: Vector2i) -> void:
	root.content_scale_size = Vector2i.ZERO
	root.size = size
	var scene := SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(16):
		await process_frame
	var prefix := "%dx%d: " % [size.x, size.y]
	_check(scene.get_viewport().get_visible_rect().size.is_equal_approx(Vector2(size)), prefix + "tests a real logical viewport at this size")
	var controller := scene.get_node("TacticalController")
	var team := scene.get_node(TEAM) as Control
	var band := scene.get_node("TacticalUI/BottomDock") as Control
	_check(team.get_global_rect().size.x <= 560.0, prefix + "team parameters form a bounded compact group")
	_check(band.get_global_rect().size.y <= 160.0, prefix + "band uses only the height needed by two readable action rows")
	var members := scene.get_node(TEAM + "/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll") as Control
	_check(not members.is_visible_in_tree(), prefix + "A5 team portraits replace the duplicate separate NPC strip")
	var details := team.get_node_or_null("A5DetailsButton") as Button
	_check(details != null and not details.get_signal_connection_list("pressed").is_empty(), prefix + "full technical information remains explicitly reachable")
	for name in ["Cautious", "Normal", "Aggressive"]:
		var button := scene.get_node(INFO + "/TacticalStancePanel/MarginContainer/VBoxContainer/HBoxContainer/" + name + "Button") as Button
		_check(button.text in ["Vorsichtig", "Normal", "Offensiv"], prefix + name + " uses a readable full stance label")
	var selector := team.get_node_or_null("A5FireRuleSelector") as OptionButton
	_check(selector != null, prefix + "fire rule has a native readable selector")
	if selector != null:
		_check(selector.item_count == 4, prefix + "all four existing rules remain available")
		for rule in RULES:
			_check(_rule_index(selector, rule) >= 0, prefix + rule + " maps to its original rule value")
		_check(team.get_global_rect().encloses(selector.get_global_rect()), prefix + "selector remains inside its team group")
		var heading := team.get_node("A5FireRuleHeading") as Label
		_check(heading.is_visible_in_tree() and heading.get_visible_line_count() >= 1 and heading.get_theme_font_size("font_size") >= 12, prefix + "fire-rule heading has an actually drawable readable line")
		_check(not heading.get_global_rect().intersects(selector.get_global_rect()), prefix + "rule heading stays above the selector without overlap")
		await _check_states(scene, controller, selector, prefix)
	var layer := scene.get_node("TacticalUI")
	var grid := scene.get_node(GRID)
	var before := int(layer.get_meta("native_a5_rect_write_count", 0))
	var geometry := int(grid.get_meta("native_a5_geometry_apply_count", 0))
	for _refresh in range(3):
		controller.call("_update_ui", false, false)
	_check(int(layer.get_meta("native_a5_rect_write_count", 0)) == before and int(grid.get_meta("native_a5_geometry_apply_count", 0)) == geometry, prefix + "unchanged refreshes keep compact geometry intact")
	if details != null:
		details.pressed.emit()
		var popup := scene.get_node("TacticalUI/A5TeamDetailsPopup") as PopupPanel
		_check(popup.visible and not paused, prefix + "technical details are accessible without pausing gameplay")
		controller.call("set_tactical_ui_visible", false)
		_check(not popup.visible, prefix + "leaving the tactical UI closes its details window")
		controller.call("set_tactical_ui_visible", true)
		details.pressed.emit()
	var details_window := scene.get_node_or_null("TacticalUI/A5TeamDetailsPopup")
	scene.queue_free()
	for _frame in range(2):
		await process_frame
	_check(details_window == null or not is_instance_valid(details_window), prefix + "scene teardown releases its details window even if it was open")


func _check_states(scene: Node, controller: Node, selector: OptionButton, prefix: String) -> void:
	var ids := PackedStringArray(controller.call("_get_available_fireteam_ids"))
	_check(ids.size() >= 2, prefix + "fixture contains actual teams for mixed-selection checks")
	if ids.size() < 2:
		return
	controller.call("_set_selected_fireteams", PackedStringArray([ids[0]]), false)
	controller.call("set_fireteams_fire_rule", PackedStringArray([ids[0]]), "free")
	controller.call("_refresh_button_state")
	controller.call("_apply_native_a5_hud_layout")
	_check(not selector.disabled and _selected_rule(selector) == "free", prefix + "selected rule reflects the confirmed owner")
	selector.item_selected.emit(_rule_index(selector, "hold"))
	_check(String(controller.call("get_fireteam_fire_rule", ids[0])) == "hold" and _selected_rule(selector) == "hold", prefix + "selector invokes the original callback and resynchronizes confirmed state")
	controller.call("set_fireteams_fire_rule", PackedStringArray([ids[0]]), "free")
	# A presenter-only pending regression: native OptionButton provisionally
	# selects an item, while the authoritative owner still confirms free fire.
	selector.select(_rule_index(selector, "hold"))
	HUD.refresh(controller, {"fire_rule": "free", "fire_rule_enabled": true, "feedback": "FIRE HOLD REQUEST (1)", "visible": true})
	_check(_selected_rule(selector) == "free" and String(controller.call("get_fireteam_fire_rule", ids[0])) == "free", prefix + "pending display never turns a provisional UI selection into confirmed state")
	var heading := scene.get_node(TEAM + "/A5FireRuleHeading") as Label
	var pending_feedback := scene.get_node("TacticalUI/A5TargetOrderPanel/Contents/Feedback") as Label
	_check(heading.text == "Angefragt" and heading.get_visible_line_count() >= 1 and pending_feedback.is_visible_in_tree() and pending_feedback.text == "Anfrage wird geprüft", prefix + "compact pending heading and visible full feedback retain the request state")
	_check(heading.get_theme_font("font").get_string_size(heading.text, HORIZONTAL_ALIGNMENT_LEFT, -1, heading.get_theme_font_size("font_size")).x <= heading.size.x, prefix + "complete pending heading fits the real content width")
	controller.call("set_fireteams_fire_rule", PackedStringArray([ids[1]]), "hold")
	controller.call("_set_selected_fireteams", PackedStringArray([ids[0], ids[1]]), false)
	controller.call("_refresh_button_state")
	controller.call("_apply_native_a5_hud_layout")
	_check(selector.selected == -1 and selector.text.contains("Gemischte"), prefix + "mixed rules do not claim one confirmed common value")
	var title := scene.get_node(TEAM + "/A5TeamIdentity") as Label
	_check(title.text.contains("Alle") or title.text.contains("Fireteams"), prefix + "multiple selection has an explicit plural header")
	controller.call("_set_selected_fireteams", PackedStringArray([ids[0]]), false)
	var refs: Array = controller.call("_create_waypoints_for_selected_fireteams", controller.call("_get_target_position"))
	_check(not refs.is_empty(), prefix + "existing planner supplies an actual order reference")
	if not refs.is_empty():
		# UI focus fixture references the existing plan; no unit/runtime patch.
		controller.set("_focused_waypoint_ref", Dictionary(refs[0]))
		controller.call("_refresh_button_state")
		controller.call("_apply_native_a5_hud_layout")
		var delete := scene.get_node(GRID + "/DeleteOrderButton") as Button
		_check(not delete.disabled and bool(delete.get_meta("native_a5_selected", false)), prefix + "focused delete action retains its real highlight")
		var sort := scene.get_node(GRID + "/SortCommandMatrixButton") as Button
		_check(bool(sort.get_meta("native_a5_selected", false)), prefix + "available team arrangement preserves the source affordance")
		var feedback := scene.get_node("TacticalUI/A5TargetOrderPanel/Contents/Feedback") as Label
		for raw in ["FIRE HOLD REQUEST (1)", "FIRE HOLD REJECT (1)", "FIRE HOLD TIMEOUT (1)"]:
			HUD.refresh(controller, {"fire_rule": "free", "fire_rule_enabled": true, "feedback": raw, "visible": true})
			_check(feedback.is_visible_in_tree() and not feedback.text.is_empty(), prefix + "editable plan keeps visible command feedback: " + raw)
			for tool_name in ["DoorBreachButton", "WaypointEraseButton"]:
				var tool := scene.get_node(GRID + "/" + tool_name) as Button
				_check(not tool.is_visible_in_tree() or not tool.get_global_rect().intersects(feedback.get_global_rect()), prefix + tool_name + " does not cover pending/rejected command feedback")
	controller.call("_set_selected_fireteams", PackedStringArray(), false)
	controller.call("_refresh_button_state")
	controller.call("_apply_native_a5_hud_layout")
	_check(selector.disabled, prefix + "no-selection gate disables the selector")
	var rule_before := String(controller.call("get_fireteam_fire_rule", ids[0]))
	selector.item_selected.emit(_rule_index(selector, "hold"))
	_check(String(controller.call("get_fireteam_fire_rule", ids[0])) == rule_before, prefix + "disabled selector callback cannot bypass the original command gate")


func _selected_rule(selector: OptionButton) -> String:
	return String(selector.get_item_metadata(selector.selected)) if selector.selected >= 0 else ""


func _rule_index(selector: OptionButton, rule: String) -> int:
	for index in range(selector.item_count):
		if String(selector.get_item_metadata(index)) == rule:
			return index
	return -1


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
