extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_364 Mission Fireteam Orientation Indicators ===")
	await _test_fireteam_orientation_snapshot_and_visuals()
	await _test_invalid_heading_is_filtered()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_fireteam_orientation_snapshot_and_visuals() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var controller := scene.get_node_or_null("TacticalController")
	var primary_view := scene.get_node_or_null("Primary3DView")
	var simulation_root := scene.get_node_or_null("SimulationRoot")
	var visualizer := scene.get_node_or_null("FireteamOrderVisualizer")
	_assert(controller != null and primary_view != null and simulation_root != null, "Mission scene exposes controller, Primary3DView and SimulationRoot")
	_assert(visualizer != null, "Mission scene attaches FireteamOrderVisualizer")
	if controller == null or primary_view == null or simulation_root == null or visualizer == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var command_count_before: int = simulation_root.command_queue.size()
	var effect_count_before: int = simulation_root.effects_queue.size()
	_assert(_set_first_fireteam_unit_facing(controller, "blue", 0.0), "Blue fireteam gets an explicit facing angle")
	_assert(_set_first_fireteam_unit_facing(controller, "gold", PI * 0.5), "Gold fireteam gets a different facing angle")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue", "gold"]), false)
	controller.call("_refresh_order_visuals")
	await _wait_frames(8)

	var orientation_entries: Array = Array(controller.call("get_fireteam_orientation_snapshot"))
	var blue_entry: Dictionary = _find_orientation_entry(orientation_entries, "blue")
	var gold_entry: Dictionary = _find_orientation_entry(orientation_entries, "gold")
	_assert(orientation_entries.size() >= 2, "Controller exposes at least two fireteam orientation entries")
	_assert(not blue_entry.is_empty() and Vector2(blue_entry.get("heading_direction", Vector2.ZERO)).dot(Vector2.RIGHT) > 0.995, "Blue orientation points east from facing metadata")
	_assert(not gold_entry.is_empty() and Vector2(gold_entry.get("heading_direction", Vector2.ZERO)).dot(Vector2.DOWN) > 0.995, "Gold orientation points south from facing metadata")

	var visualizer_entries: Array = Array(visualizer.call("get_fireteam_orientation_entries"))
	_assert(_find_orientation_entry(visualizer_entries, "blue").has("heading_direction"), "2D order visualizer receives Blue orientation")
	_assert(_find_orientation_entry(visualizer_entries, "gold").has("heading_direction"), "2D order visualizer receives Gold orientation")

	var render_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(render_snapshot.get("fireteam_orientation_visual_count", 0)) >= 2, "Primary3DView renders fireteam orientation visuals")
	_assert(Array(render_snapshot.get("fireteam_orientation_entries", [])).size() >= 2, "Primary3DView exposes orientation render entries")
	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(int(feedback.get("fireteam_orientation_count", 0)) >= 2, "Command feedback snapshot includes orientation count")
	_assert(simulation_root.command_queue.size() == command_count_before, "Orientation refresh enqueues no SimulationRoot commands")
	_assert(simulation_root.effects_queue.size() == effect_count_before, "Orientation refresh enqueues no SimulationRoot effects")
	scene.queue_free()
	await _wait_frames(2)


func _test_invalid_heading_is_filtered() -> void:
	root.size = Vector2i(1280, 720)
	var scene := MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var primary_view := scene.get_node_or_null("Primary3DView")
	var visualizer := scene.get_node_or_null("FireteamOrderVisualizer")
	_assert(primary_view != null and visualizer != null, "Mission scene exposes visual targets for invalid-heading checks")
	if primary_view == null or visualizer == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	var invalid_anchors: Array = [
		{"fireteam_id": "blue", "position": Vector2(128.0, 128.0), "heading_direction": Vector2.ZERO},
		{"fireteam_id": "gold", "position": Vector2(192.0, 128.0)},
	]
	visualizer.call("set_fireteam_anchor_dicts", invalid_anchors)
	var visualizer_entries: Array = Array(visualizer.call("get_fireteam_orientation_entries"))
	_assert(visualizer_entries.is_empty(), "2D visualizer filters zero and missing heading directions")
	primary_view.call("set_order_visual_payload", {"phase_index": 1, "fireteam_anchors": invalid_anchors})
	await _wait_frames(4)
	var render_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(render_snapshot.get("fireteam_orientation_visual_count", 0)) == 0, "Primary3DView filters zero and missing heading directions")
	scene.queue_free()
	await _wait_frames(2)


func _set_first_fireteam_unit_facing(controller: Node, fireteam_id: String, facing_angle: float) -> bool:
	var units: Array = Array(controller.call("_get_fireteam_units", fireteam_id, true))
	for unit_variant in units:
		if unit_variant is Node:
			(unit_variant as Node).set_meta("facing_angle", facing_angle)
			return true
	return false


func _find_orientation_entry(entries: Array, fireteam_id: String) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("fireteam_id", "")).strip_edges().to_lower() == normalized_fireteam_id:
			return entry
	return {}


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
