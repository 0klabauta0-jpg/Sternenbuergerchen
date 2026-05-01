extends SceneTree

const LIVE_MISSION_SCENE: PackedScene = preload("res://scenes/tests/mission_fireteam_dev_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== 3D Mission Controls and Dropship Bugfix Verifier ===")
	await _test_primary_3d_camera_gets_zoom_and_pan()
	await _test_3d_dropship_and_lz_replace_hidden_2d_overlays()
	await _test_runtime_labels_are_not_foreground_noise()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_primary_3d_camera_gets_zoom_and_pan() -> void:
	var scene := LIVE_MISSION_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var bridge = scene.get_node_or_null("Mission25DVisualBridge")
	var camera_2d := scene.get_node_or_null("MissionCamera") as Camera2D
	var camera_3d := bridge.get_node_or_null("Camera3D") as Camera3D if bridge != null else null
	var size_before: float = float(bridge.call("get_camera_size")) if bridge != null else -1.0
	var focus_before: Vector3 = Vector3(bridge.call("get_camera_focus")) if bridge != null else Vector3.ZERO
	var zoom_2d_before: Vector2 = camera_2d.zoom if camera_2d != null else Vector2.ZERO
	var wheel_up := InputEventMouseButton.new()
	wheel_up.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel_up.pressed = true
	bridge.call("_unhandled_input", wheel_up)
	if camera_2d != null:
		camera_2d.call("_unhandled_input", wheel_up)
	bridge.call("pan_camera_by_local", Vector2(1.0, 1.0), 1.25)
	var size_after: float = float(bridge.call("get_camera_size")) if bridge != null else -1.0
	var focus_after: Vector3 = Vector3(bridge.call("get_camera_focus")) if bridge != null else Vector3.ZERO
	_assert(bridge != null and bool(bridge.call("is_primary_3d_view_active")) and camera_3d != null and camera_3d.current, "Live mission starts with primary 3D camera")
	_assert(size_after < size_before, "Mouse-wheel zoom changes the 3D orthographic camera size")
	_assert(focus_after != focus_before, "3D camera pan changes bridge focus")
	_assert(camera_2d != null and camera_2d.zoom == zoom_2d_before, "Legacy 2D camera ignores zoom while 3D is primary")
	scene.queue_free()
	await process_frame


func _test_3d_dropship_and_lz_replace_hidden_2d_overlays() -> void:
	var scene := LIVE_MISSION_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var bridge = scene.get_node_or_null("Mission25DVisualBridge")
	var lz_marker := scene.get_node_or_null("LZMarker") as CanvasItem
	var dropship_marker := scene.get_node_or_null("DropshipPlanMarker") as CanvasItem
	if lz_marker != null:
		lz_marker.visible = true
		lz_marker.set_meta("task_150_legacy_2d_overlay_visible", true)
		(lz_marker as Node2D).global_position = Vector2(320.0, 180.0)
	if dropship_marker != null:
		dropship_marker.visible = true
		dropship_marker.set_meta("task_150_legacy_2d_overlay_visible", true)
		(dropship_marker as Node2D).global_position = Vector2(180.0, 90.0)
	var snapshot: Dictionary = Dictionary(bridge.call("sync_runtime_visuals")) if bridge != null else {}
	var strategic: Dictionary = Dictionary(snapshot.get("strategic_markers", {}))
	var lz: Dictionary = Dictionary(strategic.get("lz", {}))
	var dropship: Dictionary = Dictionary(strategic.get("dropship", {}))
	var lz_visual := bridge.get_node_or_null("RuntimeVisual3D/MarkerVisuals3D/LZ_lz_marker") as MeshInstance3D if bridge != null else null
	var dropship_visual := bridge.get_node_or_null("RuntimeVisual3D/MarkerVisuals3D/Dropship_dropship_marker") as Node3D if bridge != null else null
	var approach_visual := bridge.get_node_or_null("RuntimeVisual3D/MarkerVisuals3D/Approach_approach_line") as MeshInstance3D if bridge != null else null
	_assert(lz_marker != null and not lz_marker.visible and dropship_marker != null and not dropship_marker.visible, "Primary 3D mode still hides legacy 2D LZ and dropship overlays")
	_assert(lz_visual != null and lz_visual.visible and bool(lz.get("visible", false)), "3D LZ marker remains visible in primary view")
	_assert(dropship_visual != null and dropship_visual.visible and bool(dropship.get("visible", false)), "3D dropship marker remains visible in primary view")
	_assert(approach_visual != null and approach_visual.visible and bool(dropship.get("approach_visible", false)), "3D approach line connects dropship and LZ")
	scene.queue_free()
	await process_frame


func _test_runtime_labels_are_not_foreground_noise() -> void:
	var scene := LIVE_MISSION_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var bridge = scene.get_node_or_null("Mission25DVisualBridge")
	var snapshot: Dictionary = Dictionary(bridge.call("sync_runtime_visuals")) if bridge != null else {}
	var debug_label := bridge.get_node_or_null("RuntimeVisual3D/DebugLabelAnchors3D/Debug_enemy_delta") as Label3D if bridge != null else null
	var enemy_role_label := bridge.get_node_or_null("RuntimeVisual3D/UnitVisuals3D/Unit_enemy_delta/RoleBadge") as Label3D if bridge != null else null
	var enemy_visual := bridge.get_node_or_null("RuntimeVisual3D/UnitVisuals3D/Unit_enemy_delta") as MeshInstance3D if bridge != null else null
	_assert(bool(snapshot.get("valid", false)) and not bool(snapshot.get("runtime_debug_labels_visible", true)), "Runtime debug labels default to hidden")
	_assert(debug_label != null and not debug_label.visible, "Enemy debug label is not visible in the normal 3D view")
	_assert(enemy_role_label != null and not enemy_role_label.visible, "Enemy role text is not drawn as foreground clutter")
	_assert(enemy_visual != null and enemy_visual.visible, "Enemy still has a visible 3D body")
	scene.queue_free()
	await process_frame


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
