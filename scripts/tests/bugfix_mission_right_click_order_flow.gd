extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const FIRETEAM_WAYPOINT_SCRIPT: GDScript = preload("res://scripts/command/fireteam_waypoint.gd")
const AREA_ORDER_SCRIPT: GDScript = preload("res://scripts/command/area_order.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Bugfix Mission Right Click Order Flow ===")
	await _test_right_click_replaces_next_waypoint_unless_shift_appends()
	await _test_right_drag_area_replaces_next_order_unless_shift_appends()
	await _test_completed_waypoints_are_hidden_from_primary_3d_visuals()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_right_click_replaces_next_waypoint_unless_shift_appends() -> void:
	var scene := MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(8)
	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Mission scene exposes TacticalController")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	_assert(bool(controller.call("issue_right_click_command_for_test", Vector2(280.0, 180.0), FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_MOVE, false)), "Initial RMB command creates the next waypoint")
	_assert(bool(controller.call("issue_right_click_command_for_test", Vector2(420.0, 260.0), FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_TAKE, false)), "Second RMB command replaces the old next waypoint")
	var plans: Array = Array(controller.call("get_order_plans_snapshot"))
	var blue_plan: Dictionary = _find_plan(plans, "blue")
	var waypoints: Array = Array(blue_plan.get("waypoints", []))
	_assert(waypoints.size() == 1, "Non-shift RMB keeps exactly one pending next waypoint")
	_assert(Vector2(Dictionary(waypoints[0]).get("target_position", Vector2.ZERO)).distance_to(Vector2(420.0, 260.0)) <= 1.0, "Replacement waypoint uses the second RMB tile")
	_assert(String(Dictionary(waypoints[0]).get("command_type", "")) == FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_TAKE, "Replacement keeps the command selected in the context menu")

	_assert(bool(controller.call("issue_right_click_command_for_test", Vector2(520.0, 300.0), FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_MOVE, true)), "Shift+RMB appends a follow-up waypoint")
	plans = Array(controller.call("get_order_plans_snapshot"))
	blue_plan = _find_plan(plans, "blue")
	waypoints = Array(blue_plan.get("waypoints", []))
	_assert(waypoints.size() == 2, "Shift append preserves the existing next waypoint and adds a follow-up")
	_assert(Vector2(Dictionary(waypoints[1]).get("target_position", Vector2.ZERO)).distance_to(Vector2(520.0, 300.0)) <= 1.0, "Appended waypoint records the Shift target")
	scene.queue_free()
	await _wait_frames(2)


func _test_right_drag_area_replaces_next_order_unless_shift_appends() -> void:
	var scene := MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(8)
	var controller := scene.get_node_or_null("TacticalController")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)

	_assert(bool(controller.call("issue_right_click_command_for_test", Vector2(280.0, 180.0), FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_MOVE, false)), "Waypoint exists before area replacement")
	_assert(bool(controller.call("issue_right_drag_area_command_for_test", Vector2(320.0, 220.0), Vector2(460.0, 320.0), AREA_ORDER_SCRIPT.COMMAND_TYPE_ENGAGE, false)), "RMB drag creates an area command")
	var area_orders: Array = Array(controller.call("get_area_orders_snapshot"))
	var plans: Array = Array(controller.call("get_order_plans_snapshot"))
	_assert(area_orders.size() == 1, "Non-shift RMB drag creates one replacement area order")
	_assert(String(Dictionary(area_orders[0]).get("command_type", "")) == AREA_ORDER_SCRIPT.COMMAND_TYPE_ENGAGE, "Area context menu command is applied")
	_assert(_pending_waypoint_count(plans, "blue") == 0, "Area replacement removes the previous pending waypoint")

	_assert(bool(controller.call("issue_right_click_command_for_test", Vector2(560.0, 340.0), FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_MOVE, true)), "Shift+RMB appends a waypoint after the area")
	area_orders = Array(controller.call("get_area_orders_snapshot"))
	plans = Array(controller.call("get_order_plans_snapshot"))
	_assert(area_orders.size() == 1 and _pending_waypoint_count(plans, "blue") == 1, "Shift append keeps the area order while adding a follow-up waypoint")

	_assert(bool(controller.call("issue_right_click_command_for_test", Vector2(620.0, 380.0), FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_FLANK, false)), "Plain RMB replaces the queued area and waypoint again")
	area_orders = Array(controller.call("get_area_orders_snapshot"))
	plans = Array(controller.call("get_order_plans_snapshot"))
	_assert(area_orders.is_empty(), "Plain RMB replacement clears queued area orders for the fireteam")
	_assert(_pending_waypoint_count(plans, "blue") == 1, "Plain RMB leaves only the new next waypoint")
	scene.queue_free()
	await _wait_frames(2)


func _test_completed_waypoints_are_hidden_from_primary_3d_visuals() -> void:
	var scene := MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(8)
	var controller := scene.get_node_or_null("TacticalController")
	var primary_view := scene.get_node_or_null("Primary3DView")
	if controller == null or primary_view == null:
		_assert(false, "Mission scene exposes controller and Primary3DView for waypoint visual check")
		scene.queue_free()
		await _wait_frames(2)
		return
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("issue_right_click_command_for_test", Vector2(360.0, 220.0), FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_MOVE, false)
	await _wait_frames(4)
	var before_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(before_snapshot.get("waypoint_visual_count", 0)) >= 1, "Pending waypoint is visible in the primary 3D order layer")

	var plan_key: String = "blue|1"
	var plans_by_key: Dictionary = Dictionary(controller.get("_order_plans_by_key"))
	var plan = plans_by_key.get(plan_key, null)
	if plan != null and not plan.waypoints.is_empty():
		plan.waypoints[0].status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_COMPLETED
	controller.call("_refresh_order_visuals")
	await _wait_frames(4)
	var after_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(after_snapshot.get("waypoint_visual_count", 99)) == 0, "Completed waypoints disappear from the primary 3D order layer")
	scene.queue_free()
	await _wait_frames(2)


func _find_plan(plans: Array, fireteam_id: String) -> Dictionary:
	for plan_variant in plans:
		if typeof(plan_variant) != TYPE_DICTIONARY:
			continue
		var plan: Dictionary = Dictionary(plan_variant)
		if String(plan.get("fireteam_id", "")).strip_edges().to_lower() == fireteam_id:
			return plan
	return {}


func _pending_waypoint_count(plans: Array, fireteam_id: String) -> int:
	var plan: Dictionary = _find_plan(plans, fireteam_id)
	var count: int = 0
	for waypoint_variant in Array(plan.get("waypoints", [])):
		if typeof(waypoint_variant) != TYPE_DICTIONARY:
			continue
		var status: String = String(Dictionary(waypoint_variant).get("status", "")).strip_edges().to_lower()
		if status == FIRETEAM_WAYPOINT_SCRIPT.STATUS_PENDING or status == FIRETEAM_WAYPOINT_SCRIPT.STATUS_INTERRUPTED:
			count += 1
	return count


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
