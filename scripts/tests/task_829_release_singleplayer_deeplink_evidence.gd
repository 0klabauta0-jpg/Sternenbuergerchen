extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_829_release_singleplayer_deeplink_evidence.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const MAIN_MENU_SCENE_PATH := "res://scenes/ui/main_menu.tscn"
const MAIN_MENU_SCRIPT_PATH := "res://scripts/ui/main_menu_screen.gd"
const LAUNCHER_SCRIPT_PATH := "res://scripts/tools/start_release_runtime_checked.ps1"
const SINGLEPLAYER_ROUTE := "res://scenes/meta/meta_layer_test.tscn"
const DEEPLINK_ARG := "--release-singleplayer"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_829 Release Singleplayer Deep-Link Evidence ===")
	_test_docs_and_static_hooks()
	await _test_main_menu_deeplink_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_829_release_singleplayer_deeplink_evidence: FAILED")
		quit(1)
		return
	print("TASK_829_release_singleplayer_deeplink_evidence: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var main_menu_text: String = _read_text(MAIN_MENU_SCRIPT_PATH)
	var launcher_text: String = _read_text(LAUNCHER_SCRIPT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_829 task file exists")
	_assert(task_text.contains("Release Singleplayer Deep-Link Evidence"), "Task names deep-link evidence")
	_assert(status_text.contains("TASK_829 - Release Singleplayer Deep-Link Evidence"), "Implementation status tracks TASK_829")
	_assert(roadmap_text.contains("TASK_829 - Release Singleplayer Deep-Link Evidence (implementiert)"), "Roadmap marks TASK_829 implemented")
	_assert(main_menu_text.contains("RELEASE_SINGLEPLAYER_DEEPLINK_ARG"), "Main menu has stable deep-link arg constant")
	_assert(main_menu_text.contains("get_release_singleplayer_deeplink_snapshot"), "Main menu exposes TASK_829 snapshot")
	_assert(main_menu_text.contains("_on_singleplayer_pressed()"), "Deep-link uses existing singleplayer handler")
	_assert(main_menu_text.contains("OS.get_cmdline_args()"), "Deep-link parser reads normal exported command-line args")
	_assert(main_menu_text.contains("OS.get_cmdline_user_args()"), "Deep-link parser also reads user args")
	_assert(launcher_text.contains("[string[]]$LaunchArguments"), "Checked launcher accepts launch arguments")
	_assert(launcher_text.contains("ArgumentList"), "Checked launcher forwards launch arguments")
	_assert(launcher_text.contains("launch_arguments"), "Checked launcher writes launch arguments to manifest")


func _test_main_menu_deeplink_snapshot() -> void:
	var packed_scene := ResourceLoader.load(MAIN_MENU_SCENE_PATH) as PackedScene
	_assert(packed_scene != null, "Main menu scene loads")
	if packed_scene == null:
		return
	var screen := packed_scene.instantiate() as Control
	_assert(screen != null, "Main menu instantiates")
	if screen == null:
		return
	root.add_child(screen)
	await process_frame
	await process_frame
	_assert(screen.has_method("get_release_singleplayer_deeplink_snapshot"), "Main menu has deep-link snapshot callable")
	if not screen.has_method("get_release_singleplayer_deeplink_snapshot"):
		screen.queue_free()
		await process_frame
		return

	var idle_snapshot: Dictionary = Dictionary(screen.call("get_release_singleplayer_deeplink_snapshot", PackedStringArray()))
	_assert(String(idle_snapshot.get("schema", "")) == "sternenbuergerchen.release_singleplayer_deeplink_evidence.v1", "Snapshot schema is stable")
	_assert(String(idle_snapshot.get("task_id", "")) == "TASK_829", "Snapshot task id is TASK_829")
	_assert(String(idle_snapshot.get("arg", "")) == DEEPLINK_ARG, "Snapshot exposes explicit release argument")
	_assert(not bool(idle_snapshot.get("requested", true)), "No explicit argument means no deep-link request")
	_assert(String(idle_snapshot.get("would_route_to", "")) == "", "Idle snapshot does not route")
	_assert(bool(idle_snapshot.get("read_only", false)), "Snapshot is read-only")
	_assert(not bool(idle_snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot does not claim gameplay truth")

	var deep_link_args := PackedStringArray([DEEPLINK_ARG])
	var deep_link_snapshot: Dictionary = Dictionary(screen.call("get_release_singleplayer_deeplink_snapshot", deep_link_args))
	_assert(bool(deep_link_snapshot.get("requested", false)), "Explicit argument requests deep-link")
	_assert(String(deep_link_snapshot.get("would_route_to", "")) == SINGLEPLAYER_ROUTE, "Deep-link targets existing singleplayer route")
	_assert(not bool(deep_link_snapshot.get("applied", true)), "Snapshot with injected args does not apply route")

	var route_snapshot: Dictionary = Dictionary(screen.call("get_route_snapshot"))
	_assert(String(route_snapshot.get("singleplayer", "")) == SINGLEPLAYER_ROUTE, "Normal singleplayer route remains unchanged")
	screen.queue_free()
	await process_frame


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
