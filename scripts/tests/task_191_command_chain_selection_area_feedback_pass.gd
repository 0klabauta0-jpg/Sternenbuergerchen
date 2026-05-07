extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_191 Command Chain Selection Area Feedback Pass ===")
	await _test_selection_snapshot_matches_map_and_controls()
	await _test_waypoint_command_chain_uses_shared_snapshots()
	await _test_area_take_and_engage_feedback_is_consistent()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_selection_snapshot_matches_map_and_controls() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	var primary_view = scene.get_node("Primary3DView")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	await _wait_frames(4)
	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var map_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(Array(feedback.get("selected_fireteam_ids", [])).has("blue"), "#17/#18 feedback snapshot names the selected fireteam")
	_assert(String(feedback.get("selected_fireteam_label", "")).contains("Blue") or String(feedback.get("selected_fireteam_label", "")).contains("BLUE"), "#17 selected label stays human-readable")
	_assert(Array(map_snapshot.get("order_selected_fireteam_ids", [])).has("blue"), "Mission map snapshot mirrors selected fireteam")
	var buttons: Dictionary = Dictionary(feedback.get("command_buttons", {}))
	for command_id in ["move", "defend", "take"]:
		var button_state: Dictionary = Dictionary(buttons.get(command_id, {}))
		_assert(bool(button_state.get("exists", false)), "#16 Command Matrix exposes %s command control" % command_id)

	controller.call("_set_selected_fireteams", PackedStringArray(["blue", "gold"]), false)
	await _wait_frames(4)
	feedback = Dictionary(controller.call("get_command_feedback_snapshot"))
	map_snapshot = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(Array(feedback.get("selected_fireteam_ids", [])).size() == 2, "#17/#18 feedback snapshot supports multi-selection")
	_assert(Array(map_snapshot.get("order_selected_fireteam_ids", [])).has("gold"), "Mission map snapshot mirrors multi-selection")
	scene.queue_free()
	await process_frame


func _test_waypoint_command_chain_uses_shared_snapshots() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	var primary_view = scene.get_node("Primary3DView")
	var objective_position: Vector2 = _get_objective_position(scene, Vector2(448.0, 285.0))
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	var move_refs: Array = Array(controller.call("_create_waypoints_for_selected_fireteams", objective_position + Vector2(-64.0, -32.0)))
	controller.call("_set_waypoint_command_for_targets", move_refs, "move")
	var defend_refs: Array = Array(controller.call("_create_waypoints_for_selected_fireteams", objective_position + Vector2(-32.0, -9.0)))
	controller.call("_set_waypoint_command_for_targets", defend_refs, "defend")
	var take_refs: Array = Array(controller.call("_create_waypoints_for_selected_fireteams", objective_position))
	controller.call("_set_waypoint_command_for_targets", take_refs, "take")
	await _wait_frames(4)

	var plans: Array = Array(controller.call("get_order_plans_snapshot"))
	var plan: Dictionary = _find_plan(plans, "blue")
	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var map_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(move_refs.size() == 1 and defend_refs.size() == 1 and take_refs.size() == 1, "Move, Defend and Take waypoints are created through the same planning path")
	_assert(_has_waypoint_command(plan, "move") and _has_waypoint_command(plan, "defend") and _has_waypoint_command(plan, "take"), "Serialized order plan preserves Move/Defend/Take command types")
	_assert(int(feedback.get("planned_waypoint_count", 0)) >= 3, "#17/#18 feedback counts planned waypoints")
	_assert(int(feedback.get("visualized_waypoint_count", 0)) >= 3, "Visualizer snapshot exposes the same waypoint chain")
	_assert(int(map_snapshot.get("waypoint_visual_count", 0)) >= 3, "Mission map snapshot visualizes the waypoint chain")
	_assert(String(feedback.get("selected_order_text", "")).contains("WP"), "#17 selected fireteam text reports waypoint state")
	scene.queue_free()
	await process_frame


func _test_area_take_and_engage_feedback_is_consistent() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	var primary_view = scene.get_node("Primary3DView")
	var objective_position: Vector2 = _get_objective_position(scene, Vector2(960.0, 960.0))
	var take_refs: Array = Array(controller.call("create_area_order_for_fireteams_from_world_rect", PackedStringArray(["blue"]), objective_position + Vector2(-72.0, -72.0), objective_position + Vector2(72.0, 48.0), "take"))
	var engage_refs: Array = Array(controller.call("create_area_order_for_fireteams_from_world_rect", PackedStringArray(["gold"]), objective_position + Vector2(96.0, -72.0), objective_position + Vector2(224.0, 48.0), "engage"))
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	await _wait_frames(4)

	var area_orders: Array = Array(controller.call("get_area_orders_snapshot"))
	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var map_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var selected_text: String = String(feedback.get("selected_order_text", ""))
	_assert(take_refs.size() == 1 and engage_refs.size() == 1, "Take and Engage Area Orders are authored through the shared AreaOrder path")
	_assert(_has_area_command(area_orders, "take") and _has_area_command(area_orders, "engage"), "Serialized AreaOrders preserve Take and Engage command types")
	_assert(selected_text.contains("AREA TAKE"), "#17 selected fireteam names Take Area distinctly")
	_assert(selected_text.contains("Felder gesichert"), "#17 Take Area feedback exposes secured tile progress")
	_assert(int(feedback.get("planned_area_order_count", 0)) >= 1, "#18 feedback counts selected Area Orders")
	_assert(int(feedback.get("visualized_area_order_count", 0)) >= 2, "Visualizer snapshot exposes Area Orders")
	_assert(int(map_snapshot.get("area_order_count", 0)) >= 2, "Mission map snapshot visualizes Area Orders")
	_assert(int(map_snapshot.get("area_order_tile_marker_count", 0)) >= 2, "Mission map uses tile markers for Area Orders")

	controller.call("_set_selected_fireteams", PackedStringArray(["blue", "gold"]), false)
	await _wait_frames(2)
	feedback = Dictionary(controller.call("get_command_feedback_snapshot"))
	var multi_text: String = String(feedback.get("selected_order_text", ""))
	_assert(multi_text.contains("BLUE AREA TAKE") and multi_text.contains("GOLD AREA ATTACK"), "Multi-selection #17 feedback keeps Area command ownership clear")
	_assert(not multi_text.contains("Zentrum") and not multi_text.contains("Debug"), "Area feedback avoids long debug wording")
	scene.queue_free()
	await process_frame


func _load_scene() -> Node:
	var scene = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	return scene


func _get_objective_position(scene: Node, fallback: Vector2) -> Vector2:
	var simulation_root := scene.get_node_or_null("SimulationRoot")
	if simulation_root != null and simulation_root.has_method("get_objective_status"):
		var objective_status = simulation_root.call("get_objective_status")
		if objective_status != null and typeof(objective_status.get("position")) == TYPE_VECTOR2:
			return Vector2(objective_status.get("position"))
	var marker := scene.get_node_or_null("ObjectivePoint") as Node2D
	if marker != null:
		return marker.global_position
	return fallback


func _find_plan(plans: Array, fireteam_id: String) -> Dictionary:
	for plan_variant in plans:
		var plan: Dictionary = Dictionary(plan_variant)
		if String(plan.get("fireteam_id", "")).strip_edges().to_lower() == fireteam_id:
			return plan
	return {}


func _has_waypoint_command(plan: Dictionary, command_type: String) -> bool:
	for waypoint_variant in Array(plan.get("waypoints", [])):
		var waypoint: Dictionary = Dictionary(waypoint_variant)
		if String(waypoint.get("command_type", "")).strip_edges().to_lower() == command_type:
			return true
	return false


func _has_area_command(area_orders: Array, command_type: String) -> bool:
	for area_variant in area_orders:
		var area_order: Dictionary = Dictionary(area_variant)
		if String(area_order.get("command_type", "")).strip_edges().to_lower() == command_type:
			return true
	return false


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
