extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1125 Connected First Contact Local Team Contact Cluster Readability ===")
	root.size = Vector2i(1920, 1080)
	var mission: Node = MISSION_SCENE.instantiate()
	root.add_child(mission)
	for _frame in range(10):
		await process_frame
	var controller: Node = mission.get_node("TacticalController")
	var view: Node = mission.get_node("Primary3DView")
	controller.set("_selected_fireteam_ids", PackedStringArray(["blue"]))
	var blue_units: Array = Array(controller.call("_get_fireteam_units", "blue", true))
	var contact_position := Vector2(228.0, 130.0)
	var contacts: Array = [{
		"fireteam_id": "blue",
		"target_id": "enemy_delta",
		"approximate_position": contact_position,
	}]
	_assert(controller.has_method("_build_connected_first_contact_frame_positions"), "Controller exposes a read-only local First Contact frame point builder")
	if controller.has_method("_build_connected_first_contact_frame_positions"):
		var positions: Array = Array(controller.call("_build_connected_first_contact_frame_positions", contacts))
		_assert(positions.size() == blue_units.size() + 1, "Frame point set includes every local BLUE member and its Contact")
		_assert(_contains_position(positions, contact_position), "Frame point set includes the local Contact position")
		for unit_variant in blue_units:
			var unit := unit_variant as Node2D
			_assert(unit != null and _contains_position(positions, unit.global_position), "Frame point set includes local member %s" % String(unit.call("get_unit_id") if unit != null and unit.has_method("get_unit_id") else "unknown"))
		var frame_result: Dictionary = Dictionary(view.call("frame_world_positions", positions, 12.0, 24.0, 32.0))
		_assert(bool(frame_result.get("framed", false)) and int(frame_result.get("point_count", 0)) == positions.size(), "Primary view frames the complete local decision set")
		var screen_positions: Array[Vector2] = []
		for position_variant in positions:
			screen_positions.append(Vector2(view.call("world_to_screen_position", Vector2(position_variant))))
		_assert(_inside_safe_viewport(screen_positions, Vector2(1920.0, 1080.0), 96.0), "Complete local decision set keeps a safe FullHD viewport margin")
	mission.queue_free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _contains_position(positions: Array, expected: Vector2) -> bool:
	for position_variant in positions:
		if typeof(position_variant) == TYPE_VECTOR2 and Vector2(position_variant).is_equal_approx(expected):
			return true
	return false


func _inside_safe_viewport(points: Array[Vector2], viewport_size: Vector2, margin: float) -> bool:
	for point in points:
		if point.x < margin or point.y < margin or point.x > viewport_size.x - margin or point.y > viewport_size.y - margin:
			return false
	return true


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
