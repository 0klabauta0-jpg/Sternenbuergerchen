extends SceneTree

const COORDINATION_MANAGER_SCRIPT: GDScript = preload("res://scripts/tests/fireteam_coordination_manager.gd")

var _passed: int = 0
var _failed: int = 0
var _coordination_events: Array = []
var _leader_flank_events: Array = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_104 Coordination + Leader Flank Verifier ===")
	_test_coordination_manager_prefers_higher_leadership()
	await _test_coordination_event_emitted_for_close_waypoints()
	await _test_leader_initiated_flank_signal_contract()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_coordination_manager_prefers_higher_leadership() -> void:
	var manager = COORDINATION_MANAGER_SCRIPT.new()
	var assignments: Array = manager.resolve_bounding_assignments(
		[
			{"fireteam_id": "blue", "phase": 1, "target_position": Vector2(220.0, 160.0)},
			{"fireteam_id": "gold", "phase": 1, "target_position": Vector2(238.0, 172.0)},
		],
		{"blue": 0.55, "gold": 0.81}
	)
	_assert(assignments.size() == 1, "Coordination manager creates an assignment for close waypoint targets")
	if assignments.size() == 1:
		var assignment: Dictionary = assignments[0]
		_assert(String(assignment.get("advance_fireteam_id", "")) == "gold", "Higher leadership fireteam advances first")
		_assert(String(assignment.get("cover_fireteam_id", "")) == "blue", "Other fireteam takes covering role")


func _test_coordination_event_emitted_for_close_waypoints() -> void:
	_coordination_events.clear()
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	var event_router = scene.get_node("EventRouter")
	if event_router != null and event_router.has_signal("fireteam_coordination_requested"):
		if not event_router.is_connected("fireteam_coordination_requested", Callable(self, "_on_coordination_requested")):
			event_router.connect("fireteam_coordination_requested", Callable(self, "_on_coordination_requested"))
	controller.call("_set_selected_fireteams", PackedStringArray(["blue", "gold"]), false)
	controller.call("_create_waypoints_for_selected_fireteams", Vector2(228.0, 166.0))
	var started: bool = controller.call("advance_to_next_phase")
	_assert(started, "Phase starts for coordination test")
	for _i in range(6):
		await process_frame
	_assert(_coordination_events.size() >= 1, "Close multi-fireteam waypoints trigger EventRouter coordination event")
	scene.queue_free()
	await process_frame


func _test_leader_initiated_flank_signal_contract() -> void:
	_leader_flank_events.clear()
	var scene = await _load_scene()
	var event_router = scene.get_node("EventRouter")
	var unit_alpha = scene.get_node("UnitAlpha")
	if event_router != null and event_router.has_signal("leader_initiated_flank"):
		if not event_router.is_connected("leader_initiated_flank", Callable(self, "_on_leader_initiated_flank")):
			event_router.connect("leader_initiated_flank", Callable(self, "_on_leader_initiated_flank"))
	if event_router != null and event_router.has_method("notify_leader_initiated_flank") and unit_alpha != null:
		event_router.call("notify_leader_initiated_flank", "blue", unit_alpha, {"trigger": "verifier"})
	await process_frame
	_assert(_leader_flank_events.size() == 1, "EventRouter exposes leader_initiated_flank contract")
	scene.queue_free()
	await process_frame


func _on_coordination_requested(coordination_data: Dictionary) -> void:
	_coordination_events.append(coordination_data.duplicate(true))


func _on_leader_initiated_flank(fireteam_id: String, _leader: Node, flank_data: Dictionary) -> void:
	_leader_flank_events.append({
		"fireteam_id": fireteam_id,
		"flank_data": flank_data.duplicate(true),
	})


func _load_scene() -> Node:
	var scene = load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
	root.add_child(scene)
	for _index in range(10):
		await process_frame
	return scene


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
