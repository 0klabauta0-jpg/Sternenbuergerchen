extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_830_release_start_mission_deeplink_evidence.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const MAIN_MENU_SCENE_PATH := "res://scenes/ui/main_menu.tscn"
const META_LAYER_SCENE_PATH := "res://scenes/meta/meta_layer_test.tscn"
const MAIN_MENU_SCRIPT_PATH := "res://scripts/ui/main_menu_screen.gd"
const META_LAYER_SCRIPT_PATH := "res://scripts/meta/meta_layer_flow.gd"
const SINGLEPLAYER_ROUTE := "res://scenes/meta/meta_layer_test.tscn"
const START_MISSION_ARG := "--release-singleplayer-start-mission"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_830 Release Start Mission Deep-Link Evidence ===")
	_test_docs_and_static_hooks()
	await _test_main_menu_accepts_start_mission_arg()
	await _test_meta_layer_start_mission_deeplink()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_830_release_start_mission_deeplink_evidence: FAILED")
		quit(1)
		return
	print("TASK_830_release_start_mission_deeplink_evidence: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var menu_text: String = _read_text(MAIN_MENU_SCRIPT_PATH)
	var meta_text: String = _read_text(META_LAYER_SCRIPT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_830 task file exists")
	_assert(task_text.contains("Release Start Mission Deep-Link Evidence"), "Task names start mission deep-link evidence")
	_assert(status_text.contains("TASK_830 - Release Start Mission Deep-Link Evidence"), "Implementation status tracks TASK_830")
	_assert(roadmap_text.contains("TASK_830 - Release Start Mission Deep-Link Evidence (implementiert)"), "Roadmap marks TASK_830 implemented")
	_assert(menu_text.contains("RELEASE_SINGLEPLAYER_START_MISSION_DEEPLINK_ARG"), "Main menu declares start-mission deep-link arg")
	_assert(meta_text.contains("RELEASE_SINGLEPLAYER_START_MISSION_DEEPLINK_ARG"), "MetaLayer declares start-mission deep-link arg")
	_assert(meta_text.contains("get_release_start_mission_deeplink_snapshot"), "MetaLayer exposes TASK_830 snapshot")
	_assert(meta_text.contains('homebase_screen.call("request_mission_start")'), "MetaLayer uses Homebase request_mission_start path")
	_assert(meta_text.contains("_is_singleplayer_visible_homebase_actionable"), "MetaLayer gates deep-link behind Homebase actionability")


func _test_main_menu_accepts_start_mission_arg() -> void:
	var screen := _instantiate_scene(MAIN_MENU_SCENE_PATH) as Control
	_assert(screen != null, "Main menu instantiates")
	if screen == null:
		return
	await _wait_frames(2)
	_assert(screen.has_method("get_release_singleplayer_deeplink_snapshot"), "Main menu exposes TASK_829/TASK_830 route snapshot")
	if not screen.has_method("get_release_singleplayer_deeplink_snapshot"):
		screen.queue_free()
		await _wait_frames(1)
		return
	var snapshot: Dictionary = Dictionary(screen.call("get_release_singleplayer_deeplink_snapshot", PackedStringArray([START_MISSION_ARG])))
	_assert(bool(snapshot.get("requested", false)), "Start-mission arg implies Singleplayer route")
	_assert(String(snapshot.get("would_route_to", "")) == SINGLEPLAYER_ROUTE, "Start-mission arg routes to MetaLayer")
	_assert(String(snapshot.get("start_mission_arg", "")) == START_MISSION_ARG, "Main menu snapshot exposes start-mission arg")
	screen.queue_free()
	await _wait_frames(1)


func _test_meta_layer_start_mission_deeplink() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := _instantiate_scene(META_LAYER_SCENE_PATH)
	_assert(scene != null, "MetaLayer scene instantiates")
	if scene == null:
		return
	await _wait_frames(10)
	_assert(scene.has_method("get_release_start_mission_deeplink_snapshot"), "MetaLayer exposes TASK_830 callable")
	_assert(scene.has_method("_apply_release_start_mission_deeplink"), "MetaLayer exposes deep-link apply hook")
	if not scene.has_method("get_release_start_mission_deeplink_snapshot") or not scene.has_method("_apply_release_start_mission_deeplink"):
		scene.queue_free()
		await _wait_frames(1)
		return

	var idle_snapshot: Dictionary = Dictionary(scene.call("get_release_start_mission_deeplink_snapshot", PackedStringArray()))
	_assert(String(idle_snapshot.get("schema", "")) == "sternenbuergerchen.release_start_mission_deeplink_evidence.v1", "Snapshot schema is stable")
	_assert(String(idle_snapshot.get("task_id", "")) == "TASK_830", "Snapshot task id is TASK_830")
	_assert(not bool(idle_snapshot.get("requested", true)), "Idle snapshot has no request")
	_assert(String(idle_snapshot.get("current_meta_view", "")) == "homebase", "MetaLayer starts in Homebase")

	scene.call("_apply_release_start_mission_deeplink", PackedStringArray([START_MISSION_ARG]))
	await _wait_frames(24)

	var snapshot: Dictionary = Dictionary(scene.call("get_release_start_mission_deeplink_snapshot", PackedStringArray([START_MISSION_ARG])))
	_assert(bool(snapshot.get("requested", false)), "Explicit arg requests start-mission deep-link")
	_assert(bool(snapshot.get("applied", false)), "Start-mission deep-link is applied")
	_assert(String(snapshot.get("status", "")) == "applied", "Deep-link status is applied")
	_assert(String(snapshot.get("reason", "")) == "", "Applied deep-link has no blocker reason")
	_assert(String(snapshot.get("current_meta_view", "")) == "mission", "Deep-link opens Mission view")
	_assert(bool(snapshot.get("active_mission_exists", false)), "Deep-link creates active mission through existing flow")
	_assert(String(snapshot.get("actionability_status", "")) == "pass", "Launch actionability snapshot passes")
	_assert(String(snapshot.get("insertion_gate", "")) == "pass", "Mission insertion gate passes")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot does not claim gameplay truth")

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
