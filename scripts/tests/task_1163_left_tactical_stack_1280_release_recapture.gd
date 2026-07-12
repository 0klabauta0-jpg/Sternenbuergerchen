extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const TASK_DOC_PATH := "res://docs/tasks/TASK_1163_left_tactical_stack_1280_release_recapture.md"

var _checks := 0
var _failures: PackedStringArray = []


func _initialize() -> void:
	print("=== TASK_1163 Left Tactical Stack 1280 Release Recapture ===")
	root.size = Vector2i(1280, 720)
	_test_task_contract()

	var scene := MISSION_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(24)

	var controller := scene.get_node_or_null("TacticalController")
	var simulation_root := scene.get_node_or_null("SimulationRoot")
	_check(controller != null, "Mission fixture exposes TacticalController")
	_check(simulation_root != null, "Mission fixture exposes SimulationRoot")
	_check(controller != null and controller.has_method("get_left_tactical_stack_1280_release_recapture_snapshot"), "Controller exposes TASK 1163 release recapture snapshot")

	if controller != null and controller.has_method("get_left_tactical_stack_1280_release_recapture_snapshot"):
		var command_count_before := Array(simulation_root.get("command_queue")).size() if simulation_root != null else -1
		var effect_count_before := Array(simulation_root.get("effects_queue")).size() if simulation_root != null else -1
		var snapshot: Dictionary = Dictionary(controller.call("get_left_tactical_stack_1280_release_recapture_snapshot"))
		_check(String(snapshot.get("schema", "")) == "sternenbuergerchen.left_tactical_stack_1280_release_recapture.v1", "Snapshot schema is stable")
		_check(String(snapshot.get("task_id", "")) == "TASK_1163", "Snapshot identifies TASK 1163")
		_check(String(snapshot.get("source_task_id", "")) == "TASK_1162", "Snapshot links TASK 1162")
		_check(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot declares no UI gameplay truth")
		_check(not bool(snapshot.get("creates_command", true)), "Snapshot creates no command")
		_check(not bool(snapshot.get("creates_effect", true)), "Snapshot creates no effect")
		if simulation_root != null:
			_check(Array(simulation_root.get("command_queue")).size() == command_count_before, "Recapture snapshot enqueues no command")
			_check(Array(simulation_root.get("effects_queue")).size() == effect_count_before, "Recapture snapshot enqueues no effect")

		var source: Dictionary = Dictionary(snapshot.get("source_readability", {}))
		_check(bool(source.get("readability_ready", false)), "TASK 1162 left stack source is readability-ready")
		_check(String(source.get("style_id", "")) == "task_1162_left_tactical_stack_1280_readability_v1", "Snapshot carries the TASK 1162 style")

		var release_capture: Dictionary = Dictionary(snapshot.get("release_capture", {}))
		_check(String(release_capture.get("script", "")).ends_with("scripts/tools/capture_release_host_client_entry_playtest.ps1"), "Snapshot points to the existing release Host/Client harness")
		_check(String(release_capture.get("mode", "")) == "-FirstContact", "Snapshot requests FirstContact mode")
		_check(String(release_capture.get("expected_resolution", "")) == "1280x720", "Snapshot fixes the 1280x720 release target")
		_check(String(release_capture.get("manifest", "")) == "tmp/release_host_client_first_contact_playtest.json", "Snapshot names the FirstContact manifest")
		_check(String(release_capture.get("host_window_artifact", "")).ends_with("host_window.png"), "Snapshot names host window artifact")
		_check(String(release_capture.get("client_window_artifact", "")).ends_with("client_window.png"), "Snapshot names client window artifact")
		_check(bool(release_capture.get("manual_visual_review_required", false)), "Snapshot keeps manual visual review explicit")

	scene.queue_free()
	await _wait_frames(2)
	if _failures.is_empty():
		print("TASK_1163 PASS (%d checks)" % _checks)
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _test_task_contract() -> void:
	_check(FileAccess.file_exists(TASK_DOC_PATH), "TASK 1163 task document exists")
	var task_text := FileAccess.get_file_as_string(TASK_DOC_PATH)
	_check(task_text.contains("TASK_1162") and task_text.contains("1280x720"), "Task document links TASK 1162 and the 1280 target")
	_check(task_text.contains("capture_release_host_client_entry_playtest.ps1") and task_text.contains("-FirstContact"), "Task document uses the existing FirstContact release harness")
	_check(task_text.contains("Keine neuen Commands") or task_text.contains("Keine neuen"), "Task document keeps gameplay scope out")


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
