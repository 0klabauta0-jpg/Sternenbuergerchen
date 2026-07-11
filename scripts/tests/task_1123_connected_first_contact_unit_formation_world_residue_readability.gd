extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1123 Connected First Contact Unit Formation World Residue Readability ===")
	root.size = Vector2i(1920, 1080)
	var mission: Node = MISSION_SCENE.instantiate()
	root.add_child(mission)
	for _frame in range(10):
		await process_frame
	var view: Node = mission.get_node_or_null("Primary3DView")
	_assert(view != null, "Product mission exposes Primary3DView")
	if view != null:
		_assert(view.has_method("get_map_visual_bounds_snapshot"), "Primary3D exposes explicit read-only map visual bounds diagnostics")
		if view.has_method("get_map_visual_bounds_snapshot"):
			var visual_snapshot: Dictionary = Dictionary(view.call("get_map_visual_bounds_snapshot"))
			var entries: Array = Array(visual_snapshot.get("entries", []))
			_assert(bool(visual_snapshot.get("read_only", false)) and not entries.is_empty(), "Visual bounds diagnostics reports rendered map geometry without mutating gameplay")
			_assert(not Array(visual_snapshot.get("height_edge_entries", [])).is_empty(), "Visual diagnostics includes CPU-side cliff placement entries")
			_assert(not Array(visual_snapshot.get("registered_screen_entries", [])).is_empty(), "Visual diagnostics projects registered surface and cliff entries into screen space")
			_assert(not Array(visual_snapshot.get("world_mesh_entries", [])).is_empty(), "Visual diagnostics identifies visible mesh paths across world layers")
			_assert(int(visual_snapshot.get("outside_map_bounds_count", -1)) == 0, "Rendered visual bounds do not escape the authored map footprint")

		var world_positions: Array[Vector2] = _readable_fireteam_positions(Vector2(120.0, 230.0))
		var screen_positions: Array[Vector2] = []
		for world_position in world_positions:
			screen_positions.append(Vector2(view.call("world_to_screen_position", world_position)))
		_assert(_minimum_pair_distance(screen_positions) >= 18.0, "First Contact fixture keeps four unit proxies visually separated under the isometric camera")
		_assert(_axis_span(screen_positions, true) >= 18.0 and _axis_span(screen_positions, false) >= 18.0, "First Contact fixture reads as a two-dimensional formation instead of a vertical depth row")

	mission.queue_free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _readable_fireteam_positions(center: Vector2) -> Array[Vector2]:
	return [
		center + Vector2(-32.0, -32.0),
		center + Vector2(32.0, -32.0),
		center + Vector2(-32.0, 32.0),
		center + Vector2(32.0, 32.0),
	]


func _minimum_pair_distance(points: Array[Vector2]) -> float:
	var minimum_distance: float = INF
	for first_index in range(points.size()):
		for second_index in range(first_index + 1, points.size()):
			minimum_distance = minf(minimum_distance, points[first_index].distance_to(points[second_index]))
	return minimum_distance


func _axis_span(points: Array[Vector2], horizontal: bool) -> float:
	var minimum_value: float = INF
	var maximum_value: float = -INF
	for point in points:
		var value: float = point.x if horizontal else point.y
		minimum_value = minf(minimum_value, value)
		maximum_value = maxf(maximum_value, value)
	return maximum_value - minimum_value


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
