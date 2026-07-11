extends SceneTree

const DRILL_SCENE := preload("res://scenes/tests/fireteam_command_drill_map.tscn")
const HIERARCHY_SCRIPT := preload("res://scripts/ui/mission_command_hierarchy_contract.gd")
const GRID_PATH := "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid"

var _checks := 0
var _failures: PackedStringArray = []


func _initialize() -> void:
	root.size = Vector2i(1920, 1080)
	var scene = DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(20)
	var expected := {
		"MoveButton": "BW", "HoldButton": "HL", "FlankButton": "FL", "TakeButton": "NM",
		"TargetButton": "ZL", "ClearTargetButton": "Leeren", "FireRuleHoldButton": "FH",
		"FireRuleReturnButton": "AF", "FireRuleFreeButton": "FF", "FireRuleSuppressButton": "UN",
		"DeleteOrderButton": "LOE", "SortCommandMatrixButton": "ORD", "DoorBreachButton": "NUTZ",
	}
	for button_name in expected:
		var button := scene.get_node_or_null("%s/%s" % [GRID_PATH, button_name]) as Button
		_check(button != null, "%s exists" % button_name)
		if button == null:
			continue
		var label_matches: bool = button.text == String(expected[button_name]) or (button_name == "TargetButton" and button.text == "ST")
		_check(label_matches, "%s uses player-language label" % button_name)
		_check(not button.tooltip_text.strip_edges().is_empty(), "%s explains its action" % button_name)
	for button_name in ["MoveButton", "HoldButton", "FlankButton", "TakeButton", "TargetButton", "FireRuleHoldButton", "FireRuleReturnButton", "FireRuleFreeButton", "FireRuleSuppressButton"]:
		var button := scene.get_node_or_null("%s/%s" % [GRID_PATH, button_name]) as Button
		_check(button != null and button.icon != null, "%s has a tactical icon" % button_name)

	var labels_by_id: Dictionary = {}
	for action_variant in HIERARCHY_SCRIPT.get_action_catalog():
		var action: Dictionary = Dictionary(action_variant)
		labels_by_id[String(action.get("action_id", ""))] = String(action.get("label", ""))
	_check(String(labels_by_id.get("move", "")) == "Bewegen", "Hierarchy catalog uses the same Move label")
	_check(String(labels_by_id.get("defend", "")) == "Halten", "Hierarchy catalog uses the same Hold label")
	_check(String(labels_by_id.get("fire_rule_free", "")) == "FF", "Hierarchy catalog uses the same fire-rule label")

	scene.queue_free()
	await _wait_frames(2)
	if _failures.is_empty():
		print("TASK_1139 PASS (%d checks)" % _checks)
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
