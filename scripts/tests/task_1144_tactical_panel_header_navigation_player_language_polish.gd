extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")

var _checks := 0
var _failures: PackedStringArray = []


func _initialize() -> void:
	var scene := MISSION_SCENE.instantiate()
	root.add_child(scene)

	_check_label(scene, "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandHeaderLabel", "#16 BEFEHLE")
	_check_label(scene, "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderRow/FireteamHeaderLabel", "#17 AUSGEWAEHLTES FIRETEAM")
	_check_label(scene, "TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicHeaderLabel", "#18 EINSATZKONTROLLE")
	_check_button(scene, "TacticalUI/TopNavPanel/NavMargin/NavRow/HomebaseNavButton", "Homebase")
	_check_button(scene, "TacticalUI/TopNavPanel/NavMargin/NavRow/FOBNavButton", "FOB")
	_check_button(scene, "TacticalUI/TopNavPanel/NavMargin/NavRow/MissionNavButton", "Einsatz")

	_check(scene.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandHeaderLabel") != null, "CommandHeaderLabel identity stays stable")
	_check(scene.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderRow/FireteamHeaderLabel") != null, "FireteamHeaderLabel identity stays stable")
	_check(scene.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicHeaderLabel") != null, "StrategicHeaderLabel identity stays stable")
	_check(scene.get_node_or_null("TacticalUI/TopNavPanel/NavMargin/NavRow/MissionNavButton") != null, "MissionNavButton identity stays stable")

	scene.queue_free()
	await process_frame
	_finish()


func _check_label(scene: Node, path: String, expected: String) -> void:
	var label := scene.get_node_or_null(path) as Label
	_check(label != null, "%s exists" % path.get_file())
	if label != null:
		_check(label.text == expected, "%s uses '%s'" % [label.name, expected])


func _check_button(scene: Node, path: String, expected: String) -> void:
	var button := scene.get_node_or_null(path) as Button
	_check(button != null, "%s exists" % path.get_file())
	if button != null:
		_check(button.text == expected, "%s uses '%s'" % [button.name, expected])


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("TASK_1144 PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error("TASK_1144 FAIL: %s" % failure)
	quit(1)
