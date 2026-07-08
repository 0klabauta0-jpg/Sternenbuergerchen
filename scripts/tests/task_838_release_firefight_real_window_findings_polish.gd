extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_838_release_firefight_real_window_findings_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const META_LAYER_SCENE_PATH := "res://scenes/meta/meta_layer_test.tscn"
const META_LAYER_SCRIPT_PATH := "res://scripts/meta/meta_layer_flow.gd"
const CONTROLLER_SCRIPT_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const FIRST_GO_FIREFIGHT_ARG := "--release-singleplayer-first-go-firefight"
const STYLE_ID := "task_838_release_firefight_event_log_findings_v1"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_838 Release Firefight Real Window Findings Polish ===")
	_test_docs_contract_and_static_hooks()
	await _test_firefight_event_log_findings_polish()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_838_release_firefight_real_window_findings_polish: FAILED")
		quit(1)
		return
	print("TASK_838_release_firefight_real_window_findings_polish: ALL PASSED")
	quit(0)


func _test_docs_contract_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var meta_text: String = _read_text(META_LAYER_SCRIPT_PATH)
	var controller_text: String = _read_text(CONTROLLER_SCRIPT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_838 task file exists")
	_assert(task_text.contains("Release Firefight Real Window Findings Polish"), "Task names real-window findings polish")
	_assert(status_text.contains("TASK_838 - Release Firefight Real Window Findings Polish"), "Implementation status tracks TASK_838")
	_assert(roadmap_text.contains("TASK_838 - Release Firefight Real Window Findings Polish (implementiert)"), "Roadmap marks TASK_838 implemented")
	_assert(meta_text.contains("get_release_firefight_real_window_findings_polish_snapshot"), "MetaLayer exposes TASK_838 snapshot")
	_assert(controller_text.contains("get_release_firefight_real_window_findings_polish_snapshot"), "TacticalController exposes TASK_838 snapshot")
	_assert(controller_text.contains("_build_release_firefight_event_log_display_snapshot"), "Controller builds TASK_838 event-log display snapshot")
	_assert(controller_text.contains(STYLE_ID), "Controller defines the TASK_838 event-log style id")
	_assert(controller_text.contains("release_firefight_event_log_fallback"), "Controller marks fallback entries as visual-only release firefight rows")


func _test_firefight_event_log_findings_polish() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := _instantiate_scene(META_LAYER_SCENE_PATH)
	_assert(scene != null, "MetaLayer scene instantiates")
	if scene == null:
		return
	await _wait_frames(10)
	_assert(scene.has_method("_apply_release_first_go_firefight_deeplink"), "MetaLayer exposes first GO/firefight deep-link hook")
	_assert(scene.has_method("get_release_firefight_real_window_findings_polish_snapshot"), "MetaLayer exposes TASK_838 callable")
	if not scene.has_method("_apply_release_first_go_firefight_deeplink") or not scene.has_method("get_release_firefight_real_window_findings_polish_snapshot"):
		scene.queue_free()
		await _wait_frames(2)
		return

	scene.call("_apply_release_first_go_firefight_deeplink", PackedStringArray([FIRST_GO_FIREFIGHT_ARG]))
	await _wait_frames(120)

	var snapshot: Dictionary = Dictionary(scene.call("get_release_firefight_real_window_findings_polish_snapshot", {}, {}, {}))
	var tactical: Dictionary = Dictionary(snapshot.get("tactical_findings", {}))
	var display: Dictionary = Dictionary(snapshot.get("event_log_display", {}))
	var panel: Dictionary = Dictionary(snapshot.get("event_log_panel", {}))
	if String(snapshot.get("status", "")) != "pass" or String(tactical.get("gate", "")) != "pass":
		print("TASK_838 snapshot issues: %s" % [str(snapshot.get("issues", []))])
		print("TASK_838 tactical failed checks: %s" % [str(tactical.get("failed_checks", []))])
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.release_firefight_real_window_findings_polish.v1", "TASK_838 schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_838", "Snapshot task id is TASK_838")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_837", "Snapshot builds on TASK_837")
	_assert(String(snapshot.get("status", "")) == "pass", "Meta TASK_838 gate passes")
	_assert(String(tactical.get("gate", "")) == "pass", "Tactical TASK_838 gate passes")
	_assert(String(tactical.get("style_id", "")) == STYLE_ID, "Tactical snapshot exposes TASK_838 style id")
	_assert(String(display.get("style_id", "")) == STYLE_ID, "Event-log display carries TASK_838 style id")
	_assert(int(display.get("display_count", 0)) >= 1, "Event-log display has at least one row")
	_assert(int(panel.get("rendered_entry_count", 0)) >= 1, "Event-log panel renders at least one row")
	_assert(int(tactical.get("event_log_display_count", 0)) >= 1, "Tactical event-log display count is non-empty")
	_assert(_snapshot_is_read_only(snapshot), "Meta TASK_838 snapshot is read-only")
	_assert(_snapshot_is_read_only(tactical), "Tactical TASK_838 snapshot is read-only")
	_assert(_snapshot_is_read_only(display), "Event-log display fallback is read-only")
	if bool(display.get("fallback_active", false)):
		var fallback: Dictionary = Dictionary(display.get("fallback_entry", {}))
		_assert(String(fallback.get("source", "")) == "release_firefight_event_log_fallback", "Fallback source is explicit")
		_assert(bool(fallback.get("visual_only", false)), "Fallback is visual-only")
		_assert(not String(fallback.get("short_text", "")).strip_edges().is_empty(), "Fallback has visible short text")

	scene.queue_free()
	await _wait_frames(2)


func _instantiate_scene(path: String) -> Node:
	var packed_scene := ResourceLoader.load(path) as PackedScene
	if packed_scene == null:
		return null
	var node := packed_scene.instantiate()
	root.add_child(node)
	return node


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_navigation", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true)) \
		and not bool(snapshot.get("sets_multiplayer_truth", true))


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
