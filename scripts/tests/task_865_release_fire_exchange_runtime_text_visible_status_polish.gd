extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_865_release_fire_exchange_runtime_text_visible_status_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const SUMMARY_REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_2026_07_08.html"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const META_LAYER_SCENE_PATH := "res://scenes/meta/meta_layer_test.tscn"
const FIRST_GO_FIREFIGHT_ARG := "--release-singleplayer-first-go-firefight"
const NEXT_TASK := "TASK_866 - Release Fire Exchange Runtime Text Status Recapture"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_865 Release Fire Exchange Runtime Text Visible Status Polish ===")
	_test_docs_and_static_hooks()
	await _test_release_fire_exchange_snapshot_contract_surface()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_865_release_fire_exchange_runtime_text_visible_status_polish: FAILED")
		quit(1)
		return
	print("TASK_865_release_fire_exchange_runtime_text_visible_status_polish: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var summary_report_text: String = _read_text(SUMMARY_REPORT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var clock_body: String = _function_body(CONTROLLER_PATH, "func _release_fire_exchange_visibility_clock_msec")
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_865 task file exists")
	_assert(task_text.contains("Release Fire Exchange Runtime Text Visible Status Polish"), "Task names visible status polish")
	_assert(status_text.contains("TASK_865 - Release Fire Exchange Runtime Text Visible Status Polish"), "Implementation status tracks TASK_865")
	_assert(roadmap_text.contains("TASK_865 - Release Fire Exchange Runtime Text Visible Status Polish (implementiert)"), "Roadmap marks TASK_865 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_866 follow-up")
	_assert(contract_text.contains("Release-Fire-Exchange-Runtime-Text-Visible-Status-Polish"), "Contract documents TASK_865")
	_assert(summary_report_text.contains("TASK_865") and summary_report_text.contains("Time.get_ticks_msec"), "Spielstand report tracks TASK_865 real-time clock")
	_assert(controller_text.contains("RELEASE_FIRE_EXCHANGE_VISIBILITY_PERSISTENCE_MSEC: int = 45000"), "Controller keeps 45s persistence window")
	_assert(clock_body.contains("Time.get_ticks_msec()"), "Persistence clock uses real elapsed ticks")
	_assert(not clock_body.contains("Engine.get_process_frames() * 16"), "Persistence clock no longer assumes 60 FPS")
	_assert(controller_text.contains("\"creates_fire_event\": false"), "TASK_865 keeps no-fire-event read boundary in controller")
	_assert(controller_text.contains("\"creates_damage_event\": false"), "TASK_865 keeps no-damage-event read boundary in controller")
	_assert(controller_text.contains("\"sets_multiplayer_truth\": false"), "TASK_865 keeps no multiplayer truth mutation in controller")


func _test_release_fire_exchange_snapshot_contract_surface() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := _instantiate_scene(META_LAYER_SCENE_PATH)
	_assert(scene != null, "MetaLayer scene instantiates")
	if scene == null:
		return
	await _wait_frames(10)
	_assert(scene.has_method("_apply_release_first_go_firefight_deeplink"), "MetaLayer exposes first GO/firefight apply hook")
	_assert(scene.has_method("get_release_fire_exchange_visibility_persistence_snapshot"), "MetaLayer exposes visibility persistence snapshot")
	if not scene.has_method("_apply_release_first_go_firefight_deeplink") or not scene.has_method("get_release_fire_exchange_visibility_persistence_snapshot"):
		scene.queue_free()
		await _wait_frames(1)
		return

	var snapshot: Dictionary = Dictionary(scene.call("get_release_fire_exchange_visibility_persistence_snapshot"))
	var tactical: Dictionary = Dictionary(snapshot.get("tactical_persistence", {}))
	_assert(String(snapshot.get("schema", "")).contains("release_fire_exchange_visibility_persistence"), "Visibility persistence snapshot schema remains available")
	_assert(bool(snapshot.get("read_only", false)), "Meta snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Meta snapshot sets no gameplay truth")
	_assert(tactical.is_empty() or not bool(tactical.get("creates_command", false)), "Tactical snapshot creates no commands")
	_assert(tactical.is_empty() or not bool(tactical.get("creates_fire_event", false)), "Tactical snapshot creates no fire events")
	_assert(tactical.is_empty() or not bool(tactical.get("creates_damage_event", false)), "Tactical snapshot creates no damage events")
	_assert(tactical.is_empty() or not bool(tactical.get("sets_multiplayer_truth", false)), "Tactical snapshot sets no multiplayer truth")

	scene.queue_free()
	await _wait_frames(2)


func _instantiate_scene(path: String) -> Node:
	var packed_scene := ResourceLoader.load(path) as PackedScene
	if packed_scene == null:
		return null
	var node := packed_scene.instantiate()
	root.add_child(node)
	return node


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _function_body(path: String, function_name: String) -> String:
	var text: String = _read_text(path)
	var start: int = text.find(function_name)
	if start < 0:
		return ""
	var next_func: int = text.find("\nfunc ", start + function_name.length())
	return text.substr(start) if next_func < 0 else text.substr(start, next_func - start)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
