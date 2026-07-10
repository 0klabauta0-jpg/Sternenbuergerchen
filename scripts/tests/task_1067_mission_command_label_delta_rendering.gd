extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1067 Mission Command Label Delta Rendering ===")
	await _test_repeated_mission_refresh_skips_identical_labels()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_repeated_mission_refresh_skips_identical_labels() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var controller: Node = scene.get_node_or_null("TacticalController")
	var command_label := scene.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamInfoScroll/FireteamInfoVBox/CommandFeedbackLabel") as Label
	_assert(controller != null and command_label != null, "Mission fixture exposes controller and command feedback label")
	if controller == null or command_label == null:
		await _cleanup(scene)
		return
	_assert(controller.has_method("get_mission_label_delta_rendering_snapshot"), "Controller exposes read-only mission label delta diagnostics")
	if not controller.has_method("get_mission_label_delta_rendering_snapshot"):
		await _cleanup(scene)
		return
	controller.call("_update_ui")
	var before: Dictionary = Dictionary(controller.call("get_mission_label_delta_rendering_snapshot"))
	var command_label_id: int = command_label.get_instance_id()
	var command_text: String = command_label.text
	controller.call("_update_ui")
	var after_same: Dictionary = Dictionary(controller.call("get_mission_label_delta_rendering_snapshot"))
	_assert(command_label.get_instance_id() == command_label_id and command_label.text == command_text, "Repeated refresh keeps the command label instance and text")
	_assert(int(after_same.get("skip_count", -1)) > int(before.get("skip_count", -1)), "Repeated refresh skips identical label writes")

	controller.set("_last_command_text", "TASK 1067 LABEL DELTA")
	controller.call("_update_ui")
	var after_change: Dictionary = Dictionary(controller.call("get_mission_label_delta_rendering_snapshot"))
	_assert(command_label.text.contains("TASK 1067 LABEL DELTA"), "Changed command feedback reaches the visible label")
	_assert(int(after_change.get("apply_count", -1)) > int(after_same.get("apply_count", -1)), "Changed command feedback reapplies a label text")
	_assert(bool(after_change.get("read_only", false)), "Label delta diagnostics stay read-only")
	_assert(not bool(after_change.get("ui_sets_gameplay_truth", true)), "Label delta diagnostics do not own gameplay truth")
	await _cleanup(scene)


func _cleanup(scene: Node) -> void:
	if is_instance_valid(scene):
		scene.queue_free()
	await _wait_frames(2)


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
