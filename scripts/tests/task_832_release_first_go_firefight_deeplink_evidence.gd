extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_832_release_first_go_firefight_deeplink_evidence.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const MAIN_MENU_SCENE_PATH := "res://scenes/ui/main_menu.tscn"
const META_LAYER_SCENE_PATH := "res://scenes/meta/meta_layer_test.tscn"
const MAIN_MENU_SCRIPT_PATH := "res://scripts/ui/main_menu_screen.gd"
const META_LAYER_SCRIPT_PATH := "res://scripts/meta/meta_layer_flow.gd"
const FIXTURE_SCRIPT_PATH := "res://scripts/tests/release_first_exchange_fixture.gd"
const SINGLEPLAYER_ROUTE := "res://scenes/meta/meta_layer_test.tscn"
const FIRST_GO_FIREFIGHT_ARG := "--release-singleplayer-first-go-firefight"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_832 Release First GO Firefight Deep-Link Evidence ===")
	_test_docs_and_static_hooks()
	await _test_main_menu_accepts_first_go_firefight_arg()
	await _test_meta_layer_first_go_firefight_deeplink()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_832_release_first_go_firefight_deeplink_evidence: FAILED")
		quit(1)
		return
	print("TASK_832_release_first_go_firefight_deeplink_evidence: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var menu_text: String = _read_text(MAIN_MENU_SCRIPT_PATH)
	var meta_text: String = _read_text(META_LAYER_SCRIPT_PATH)
	var fixture_text: String = _read_text(FIXTURE_SCRIPT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_832 task file exists")
	_assert(task_text.contains("Release First GO Firefight Deep-Link Evidence"), "Task names first GO/firefight deep-link evidence")
	_assert(status_text.contains("TASK_832 - Release First GO Firefight Deep-Link Evidence"), "Implementation status tracks TASK_832")
	_assert(roadmap_text.contains("TASK_832 - Release First GO Firefight Deep-Link Evidence (implementiert)"), "Roadmap marks TASK_832 implemented")
	_assert(menu_text.contains("RELEASE_SINGLEPLAYER_FIRST_GO_FIREFIGHT_DEEPLINK_ARG"), "Main menu declares first GO/firefight deep-link arg")
	_assert(meta_text.contains("RELEASE_SINGLEPLAYER_FIRST_GO_FIREFIGHT_DEEPLINK_ARG"), "MetaLayer declares first GO/firefight deep-link arg")
	_assert(meta_text.contains("get_release_first_go_firefight_deeplink_snapshot"), "MetaLayer exposes TASK_832 snapshot")
	_assert(meta_text.contains("execute_selected_fireteam_orders"), "Deep-link uses existing GO execution path")
	_assert(FileAccess.file_exists(FIXTURE_SCRIPT_PATH), "Synthetic release fixture exists explicitly")
	_assert(meta_text.contains("release_first_exchange_fixture.gd"), "Deep-link delegates synthetic setup to fixture")
	_assert(fixture_text.contains("_try_enqueue_attacks"), "Fixture retains the existing combat driver engagement setup")


func _test_main_menu_accepts_first_go_firefight_arg() -> void:
	var screen := _instantiate_scene(MAIN_MENU_SCENE_PATH) as Control
	_assert(screen != null, "Main menu instantiates")
	if screen == null:
		return
	await _wait_frames(2)
	_assert(screen.has_method("get_release_singleplayer_deeplink_snapshot"), "Main menu exposes route snapshot")
	if not screen.has_method("get_release_singleplayer_deeplink_snapshot"):
		screen.queue_free()
		await _wait_frames(1)
		return
	var snapshot: Dictionary = Dictionary(screen.call("get_release_singleplayer_deeplink_snapshot", PackedStringArray([FIRST_GO_FIREFIGHT_ARG])))
	_assert(bool(snapshot.get("requested", false)), "First GO/firefight arg implies Singleplayer route")
	_assert(String(snapshot.get("would_route_to", "")) == SINGLEPLAYER_ROUTE, "First GO/firefight arg routes to MetaLayer")
	_assert(String(snapshot.get("first_go_firefight_arg", "")) == FIRST_GO_FIREFIGHT_ARG, "Main menu snapshot exposes first GO/firefight arg")
	screen.queue_free()
	await _wait_frames(1)


func _test_meta_layer_first_go_firefight_deeplink() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := _instantiate_scene(META_LAYER_SCENE_PATH)
	_assert(scene != null, "MetaLayer scene instantiates")
	if scene == null:
		return
	await _wait_frames(10)
	_assert(scene.has_method("get_release_first_go_firefight_deeplink_snapshot"), "MetaLayer exposes TASK_832 callable")
	_assert(scene.has_method("_apply_release_first_go_firefight_deeplink"), "MetaLayer exposes first GO/firefight apply hook")
	if not scene.has_method("get_release_first_go_firefight_deeplink_snapshot") or not scene.has_method("_apply_release_first_go_firefight_deeplink"):
		scene.queue_free()
		await _wait_frames(1)
		return

	var idle_snapshot: Dictionary = Dictionary(scene.call("get_release_first_go_firefight_deeplink_snapshot", PackedStringArray()))
	_assert(String(idle_snapshot.get("schema", "")) == "sternenbuergerchen.release_first_go_firefight_deeplink_evidence.v1", "Snapshot schema is stable")
	_assert(String(idle_snapshot.get("task_id", "")) == "TASK_832", "Snapshot task id is TASK_832")
	_assert(not bool(idle_snapshot.get("requested", true)), "Idle snapshot has no request")

	scene.call("_apply_release_first_go_firefight_deeplink", PackedStringArray([FIRST_GO_FIREFIGHT_ARG]))
	await _wait_frames(110)

	var snapshot: Dictionary = Dictionary(scene.call("get_release_first_go_firefight_deeplink_snapshot", PackedStringArray([FIRST_GO_FIREFIGHT_ARG])))
	_assert(bool(snapshot.get("requested", false)), "Explicit arg requests first GO/firefight deep-link")
	_assert(bool(snapshot.get("synthetic_fixture", false)), "Explicit deep-link evidence labels the synthetic fixture")
	_assert(bool(snapshot.get("applied", false)), "First GO/firefight deep-link is applied")
	_assert(String(snapshot.get("status", "")) == "applied", "Deep-link status is applied")
	_assert(String(snapshot.get("reason", "")) == "", "Applied deep-link has no blocker reason")
	_assert(String(snapshot.get("current_meta_view", "")) == "mission", "Deep-link remains in Mission view")
	_assert(bool(snapshot.get("active_mission_exists", false)), "Deep-link keeps an active mission")
	_assert(String(snapshot.get("firefight_status", "")) == "pass", "First GO/firefight actionability snapshot passes")
	_assert(bool(snapshot.get("pre_go_was_actionable", false)), "Pre-GO chain passed before GO execution")
	_assert(String(snapshot.get("execution_gate", "")) == "pass", "Execution gate passes")
	_assert(String(snapshot.get("contact_gate", "")) == "pass", "Contact gate passes")
	_assert(String(snapshot.get("engagement_gate", "")) == "pass", "Engagement gate passes")
	_assert(bool(snapshot.get("go_executed", false)), "GO execution is visible")
	_assert(int(snapshot.get("movement_state_count", 0)) > 0, "Movement state is visible")
	_assert(int(snapshot.get("selected_contact_count", 0)) > 0, "First contact is visible")
	_assert(not String(snapshot.get("engagement_status", "")).strip_edges().is_empty(), "Engagement status is visible")
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
