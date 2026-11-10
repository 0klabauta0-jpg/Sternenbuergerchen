extends SceneTree
var failed := 0
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var mission: Node = load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
	root.add_child(mission)
	await process_frame
	await process_frame
	var controller: Node = mission.get_node("TacticalController")
	_check(controller.has_method("set_planning_enabled"), "Controller exposes explicit planning mode")
	if controller.has_method("set_planning_enabled"):
		_check(bool(controller.call("is_planning_enabled")), "Existing preview-and-GO remains default")
		var before: Dictionary = controller.call("get_planning_state")
		controller.call("set_planning_enabled", false)
		_check(not bool(controller.call("is_planning_enabled")), "Immediate mode is explicit")
		controller.call("set_planning_enabled", true)
		_check(controller.call("get_planning_state") == before, "Switching does not execute or discard existing plans")
		controller.call("set_planning_enabled", false)
		controller.call("_set_selected_fireteams", PackedStringArray(), false)
		_check(not bool(controller.call("request_immediate_move_from_screen", Vector2(500,300))), "Immediate command without selected fireteam is rejected")
		var go: Node = mission.find_child("GoCommandMatrixButton", true, false)
		_check(go != null and go.has_node("PlanModeSwitch"), "GO has a separate plan-mode switch hit area")
	mission.queue_free()
	await process_frame
	print("PLAN_MODE failed=", failed)
	quit(1 if failed else 0)
func _check(value: bool, label: String) -> void:
	if not value: failed += 1
	print("PASS: " if value else "FAIL: ", label)
