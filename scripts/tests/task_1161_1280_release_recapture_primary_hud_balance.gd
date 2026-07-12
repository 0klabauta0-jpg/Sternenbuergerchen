extends SceneTree

const DRILL_SCENE := preload("res://scenes/tests/fireteam_command_drill_map.tscn")
const TASK_DOC_PATH := "res://docs/tasks/TASK_1161_1280_release_recapture_primary_hud_balance.md"

var _checks := 0
var _failures: PackedStringArray = []


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	_test_task_contract()

	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(20)

	var controller := scene.get_node_or_null("TacticalController")
	var simulation_root := scene.get_node_or_null("SimulationRoot")
	_check(controller != null, "Mission fixture exposes TacticalController")
	_check(simulation_root != null, "Mission fixture exposes SimulationRoot")
	_check(controller != null and controller.has_method("get_primary_hud_1280_balance_snapshot"), "Controller exposes TASK 1161 primary HUD balance snapshot")

	if controller != null and controller.has_method("get_primary_hud_1280_balance_snapshot"):
		var command_count_before := Array(simulation_root.get("command_queue")).size() if simulation_root != null else -1
		var effect_count_before := Array(simulation_root.get("effects_queue")).size() if simulation_root != null else -1
		var snapshot: Dictionary = Dictionary(controller.call("get_primary_hud_1280_balance_snapshot"))
		_check(String(snapshot.get("schema", "")) == "sternenbuergerchen.primary_hud_1280_balance.v1", "Snapshot schema is stable")
		_check(String(snapshot.get("task_id", "")) == "TASK_1161", "Snapshot identifies TASK 1161")
		_check(String(snapshot.get("style_id", "")) == "task_1161_1280_release_primary_hud_balance_v1", "Snapshot style id is stable")
		_check(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot declares no UI gameplay truth")
		_check(not bool(snapshot.get("creates_command", true)), "Snapshot creates no command")
		_check(not bool(snapshot.get("creates_effect", true)), "Snapshot creates no effect")
		if simulation_root != null:
			_check(Array(simulation_root.get("command_queue")).size() == command_count_before, "Balance snapshot enqueues no command")
			_check(Array(simulation_root.get("effects_queue")).size() == effect_count_before, "Balance snapshot enqueues no effect")

		var surfaces: Dictionary = Dictionary(snapshot.get("surfaces", {}))
		for key in ["command_matrix", "selected_fireteam_members", "tactical_event_log", "mission_control"]:
			_check(surfaces.has(key), "Snapshot includes %s surface" % key)
			var surface: Dictionary = Dictionary(surfaces.get(key, {}))
			_check(bool(surface.get("readability_ready", false)), "%s is readability-ready: %s" % [key, JSON.stringify(surface)])
			_check(not bool(surface.get("ui_sets_gameplay_truth", true)), "%s owns no gameplay truth" % key)
			_check(not String(surface.get("source_task_id", "")).strip_edges().is_empty(), "%s references its source task" % key)

		var balance: Dictionary = Dictionary(snapshot.get("balance", {}))
		_check(int(balance.get("primary_surface_count", 0)) == 4, "Balance counts the four primary HUD surfaces")
		_check(bool(balance.get("all_surfaces_readable", false)), "All primary surfaces satisfy their 1280 contracts")
		_check(bool(balance.get("no_gameplay_truth_claim", false)), "Combined balance keeps read-only truth boundary")
		_check(String(balance.get("recommended_next_task", "")).begins_with("TASK_1162"), "Snapshot proposes a concrete next visual/flow task")

		var release_capture: Dictionary = Dictionary(snapshot.get("release_capture", {}))
		_check(String(release_capture.get("script", "")).ends_with("scripts/tools/capture_release_host_client_entry_playtest.ps1"), "Snapshot points to the existing Host/Client release harness")
		_check(String(release_capture.get("mode", "")) == "-FirstContact", "Snapshot requests FirstContact recapture mode")
		_check(String(release_capture.get("expected_resolution", "")) == "1280x720", "Snapshot anchors the 1280x720 release resolution")
		_check(bool(release_capture.get("manual_visual_review_required", false)), "Release capture still requires a human visual readback")

	scene.queue_free()
	await _wait_frames(2)
	if _failures.is_empty():
		print("TASK_1161 PASS (%d checks)" % _checks)
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _test_task_contract() -> void:
	_check(FileAccess.file_exists(TASK_DOC_PATH), "TASK 1161 task document exists")
	var task_text := FileAccess.get_file_as_string(TASK_DOC_PATH)
	_check(task_text.contains("TASK_1157") and task_text.contains("TASK_1158") and task_text.contains("TASK_1159") and task_text.contains("TASK_1160"), "Task document ties together the four 1280 HUD polish tasks")
	_check(task_text.contains("capture_release_host_client_entry_playtest.ps1") and task_text.contains("-FirstContact"), "Task document uses the existing FirstContact release harness")
	_check(task_text.contains("1280x720"), "Task document fixes the target release resolution")


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
