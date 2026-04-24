extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Mission Map Camera Verifier ===")
	await _test_scene_has_active_mission_camera()
	await _test_camera_supports_zoom_and_pan()
	await _test_camera_releases_viewport_when_scene_is_hidden()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_scene_has_active_mission_camera() -> void:
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(4):
		await process_frame
	var camera := scene.get_node_or_null("MissionCamera") as Camera2D
	_assert(camera != null, "Mission scene attaches a dedicated mission camera")
	_assert(camera != null and camera.is_current(), "Mission camera becomes the active Camera2D")
	scene.queue_free()
	await process_frame


func _test_camera_supports_zoom_and_pan() -> void:
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(4):
		await process_frame
	var camera := scene.get_node_or_null("MissionCamera") as Camera2D
	if camera == null:
		_assert(false, "Mission camera exists for zoom/pan interaction checks")
		scene.queue_free()
		await process_frame
		return
	var zoom_before: Vector2 = camera.zoom
	var position_before: Vector2 = camera.position

	var wheel_up := InputEventMouseButton.new()
	wheel_up.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel_up.pressed = true
	camera._unhandled_input(wheel_up)

	var middle_down := InputEventMouseButton.new()
	middle_down.button_index = MOUSE_BUTTON_MIDDLE
	middle_down.pressed = true
	camera._unhandled_input(middle_down)

	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(32.0, -18.0)
	camera._unhandled_input(motion)

	var middle_up := InputEventMouseButton.new()
	middle_up.button_index = MOUSE_BUTTON_MIDDLE
	middle_up.pressed = false
	camera._unhandled_input(middle_up)

	_assert(camera.zoom.x > zoom_before.x, "Mission camera uses the inverted mouse wheel zoom direction")
	_assert(camera.position != position_before, "Mission camera pans with middle-mouse drag input")
	scene.queue_free()
	await process_frame


func _test_camera_releases_viewport_when_scene_is_hidden() -> void:
	var mission := MISSION_TEST_SCENE.instantiate() as Node2D
	root.add_child(mission)
	for _frame in range(4):
		await process_frame
	var camera := mission.get_node_or_null("MissionCamera") as Camera2D
	if camera == null:
		_assert(false, "Mission camera exists for visibility hand-off checks")
		mission.queue_free()
		await process_frame
		return
	_assert(camera.is_current(), "Mission camera is current while mission scene is visible")
	mission.visible = false
	for _frame in range(2):
		await process_frame
	_assert(not camera.is_current(), "Mission camera releases the viewport when the mission scene is hidden")
	mission.visible = true
	for _frame in range(2):
		await process_frame
	_assert(camera.is_current(), "Mission camera becomes current again when the mission scene is shown")
	mission.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
