extends SceneTree

const AREA_ORDER_SCRIPT: GDScript = preload("res://scripts/command/area_order.gd")
const FIRETEAM_ORDER_VISUALIZER_SCRIPT: GDScript = preload("res://scripts/tactical/visuals/fireteam_order_visualizer.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_121 Area Order Marker Verifier ===")
	_test_area_order_data_roundtrip()
	_test_visualizer_area_snapshot()
	await _test_mission_area_order_planning_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_area_order_data_roundtrip() -> void:
	var area_order = AREA_ORDER_SCRIPT.new({
		"area_order_id": "area_0001",
		"fireteam_id": "blue",
		"command_type": "defend",
		"tile_positions": [Vector2i(1, 2), Vector2i(1, 3), Vector2i(2, 2)],
		"tile_world_positions": [Vector2(64.0, 96.0), Vector2(0.0, 128.0), Vector2(128.0, 128.0)],
		"world_polygon": PackedVector2Array([Vector2(0.0, 80.0), Vector2(144.0, 80.0), Vector2(144.0, 144.0), Vector2(0.0, 144.0)]),
		"center_position": Vector2(64.0, 112.0),
		"created_at_order_index": 2,
		"status": "pending",
	})
	_assert(area_order.is_valid(), "AreaOrder accepts the TASK_121 data contract")
	var reloaded = AREA_ORDER_SCRIPT.call("from_dict", area_order.to_dict())
	_assert(reloaded != null and reloaded.is_valid(), "AreaOrder survives dictionary roundtrip")
	_assert(String(reloaded.command_type) == "defend" and Array(reloaded.tile_positions).size() == 3, "AreaOrder preserves command type and tile positions")


func _test_visualizer_area_snapshot() -> void:
	var visualizer = FIRETEAM_ORDER_VISUALIZER_SCRIPT.new()
	root.add_child(visualizer)
	visualizer.call("set_selected_fireteam_ids", PackedStringArray(["blue"]))
	visualizer.call("set_area_order_dicts", [
		{
			"area_order_id": "area_0002",
			"fireteam_id": "blue",
			"command_type": "engage",
			"tile_positions": [Vector2i(2, 2), Vector2i(2, 3)],
			"world_polygon": PackedVector2Array([Vector2(10.0, 10.0), Vector2(90.0, 10.0), Vector2(90.0, 70.0), Vector2(10.0, 70.0)]),
			"center_position": Vector2(50.0, 40.0),
			"created_at_order_index": 0,
			"status": "pending",
		}
	])
	var visible_area_orders: Array = visualizer.call("get_visible_area_orders")
	_assert(visible_area_orders.size() == 1, "FireteamOrderVisualizer exposes visible area orders separately from waypoints")
	var snapshot: Dictionary = Dictionary(visible_area_orders[0])
	_assert(String(snapshot.get("command_type", "")) == "engage", "Visualizer snapshot keeps the area command classification")
	visualizer.queue_free()


func _test_mission_area_order_planning_roundtrip() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	var waypoint_refs: Array = controller.call("_create_waypoints_for_selected_fireteams", Vector2(287.0, 243.0))
	var area_refs: Array = controller.call("create_area_order_for_selected_fireteams_from_world_rect", Vector2(120.0, 120.0), Vector2(420.0, 300.0), "defend")
	_assert(waypoint_refs.size() == 1, "Existing single-waypoint creation still works with area orders present")
	_assert(area_refs.size() == 1, "Mission controller creates an area order for the selected fireteam")
	controller.call("_set_area_order_command_for_targets", area_refs, "take")
	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	var area_orders: Array = Array(planning_state.get("area_orders", []))
	_assert(area_orders.size() == 1, "Planning state serializes area orders")
	var saved_area_order: Dictionary = Dictionary(area_orders[0])
	_assert(String(saved_area_order.get("command_type", "")) == "take", "Area orders can be classified as take")
	_assert(Array(saved_area_order.get("tile_positions", [])).size() > 1 or PackedVector2Array(saved_area_order.get("world_polygon", PackedVector2Array())).size() >= 3, "Area order stores a multi-tile or polygon area")
	var visualized_area_orders: Array = controller.call("get_visualized_area_orders_snapshot")
	_assert(visualized_area_orders.size() == 1, "Mission visualizer shows created area orders")

	var reloaded_scene = await _load_scene()
	var reloaded_controller = reloaded_scene.get_node("TacticalController")
	reloaded_controller.call("set_planning_state", planning_state)
	await process_frame
	var reloaded_state: Dictionary = Dictionary(reloaded_controller.call("get_planning_state"))
	var reloaded_area_orders: Array = Array(reloaded_state.get("area_orders", []))
	_assert(reloaded_area_orders.size() == 1 and String(Dictionary(reloaded_area_orders[0]).get("command_type", "")) == "take", "Planning-state load preserves area orders")
	scene.queue_free()
	reloaded_scene.queue_free()
	await process_frame


func _load_scene() -> Node:
	var scene = load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
	root.add_child(scene)
	for _index in range(10):
		await process_frame
	return scene


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
