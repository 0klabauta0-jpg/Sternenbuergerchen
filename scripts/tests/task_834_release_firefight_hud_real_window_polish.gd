extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_834_release_firefight_hud_real_window_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const META_LAYER_SCENE_PATH := "res://scenes/meta/meta_layer_test.tscn"
const META_LAYER_SCRIPT_PATH := "res://scripts/meta/meta_layer_flow.gd"
const CONTROLLER_SCRIPT_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const FIRST_GO_FIREFIGHT_ARG := "--release-singleplayer-first-go-firefight"
const STYLE_ID := "task_834_release_firefight_hud_real_window_v1"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_834 Release Firefight HUD Real Window Polish ===")
	_test_docs_contract_and_static_hooks()
	await _test_firefight_selected_fireteam_label_real_window_style()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_834_release_firefight_hud_real_window_polish: FAILED")
		quit(1)
		return
	print("TASK_834_release_firefight_hud_real_window_polish: ALL PASSED")
	quit(0)


func _test_docs_contract_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var meta_text: String = _read_text(META_LAYER_SCRIPT_PATH)
	var controller_text: String = _read_text(CONTROLLER_SCRIPT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_834 task file exists")
	_assert(task_text.contains("Release Firefight HUD Real Window Polish"), "Task names release firefight HUD real-window polish")
	_assert(status_text.contains("TASK_834 - Release Firefight HUD Real Window Polish"), "Implementation status tracks TASK_834")
	_assert(roadmap_text.contains("TASK_834 - Release Firefight HUD Real Window Polish (implementiert)"), "Roadmap marks TASK_834 implemented")
	_assert(contract_text.contains("Release-Firefight-HUD-Real-Window-Polish"), "Mission command feedback contract documents TASK_834")
	_assert(meta_text.contains("get_release_firefight_hud_real_window_polish_snapshot"), "MetaLayer exposes TASK_834 snapshot")
	_assert(controller_text.contains("get_release_firefight_hud_real_window_polish_snapshot"), "TacticalController exposes TASK_834 snapshot")
	_assert(controller_text.contains(STYLE_ID), "Controller defines the TASK_834 real-window style id")


func _test_firefight_selected_fireteam_label_real_window_style() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := _instantiate_scene(META_LAYER_SCENE_PATH)
	_assert(scene != null, "MetaLayer scene instantiates")
	if scene == null:
		return
	await _wait_frames(10)
	_assert(scene.has_method("_apply_release_first_go_firefight_deeplink"), "MetaLayer exposes first GO/firefight deep-link hook")
	_assert(scene.has_method("get_release_firefight_hud_real_window_polish_snapshot"), "MetaLayer exposes TASK_834 callable")
	if not scene.has_method("_apply_release_first_go_firefight_deeplink") or not scene.has_method("get_release_firefight_hud_real_window_polish_snapshot"):
		scene.queue_free()
		await _wait_frames(2)
		return

	scene.call("_apply_release_first_go_firefight_deeplink", PackedStringArray([FIRST_GO_FIREFIGHT_ARG]))
	await _wait_frames(120)

	var snapshot: Dictionary = Dictionary(scene.call("get_release_firefight_hud_real_window_polish_snapshot", {}, {}, {}))
	var tactical: Dictionary = Dictionary(snapshot.get("tactical_real_window", {}))
	var label_style: Dictionary = Dictionary(tactical.get("selected_fireteam_label_style", {}))
	var contact_fire_line: String = String(snapshot.get("contact_fire_line", "")).strip_edges()
	var visible_decision_line: String = String(snapshot.get("visible_decision_line", "")).strip_edges()
	var selected_text: String = String(snapshot.get("selected_fireteam_status_text", "")).strip_edges()
	if String(snapshot.get("status", "")) != "pass" or String(tactical.get("gate", "")) != "pass":
		print("TASK_834 snapshot issues: %s" % [str(snapshot.get("issues", []))])
		print("TASK_834 tactical failed checks: %s" % [str(tactical.get("failed_checks", []))])
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.release_firefight_hud_real_window_polish.v1", "TASK_834 schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_834", "Snapshot task id is TASK_834")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_833", "Snapshot builds on TASK_833")
	_assert(String(snapshot.get("status", "")) == "pass", "Meta TASK_834 gate passes")
	_assert(String(tactical.get("gate", "")) == "pass", "Tactical TASK_834 gate passes")
	_assert(String(tactical.get("style_id", "")) == STYLE_ID, "Selected Fireteam carries TASK_834 style id")
	_assert(bool(tactical.get("real_window_style_active", false)), "Selected Fireteam real-window style is active")
	_assert(int(label_style.get("font_size", 0)) >= 12, "Selected Fireteam font is larger for real window")
	_assert(int(label_style.get("outline_size", 0)) >= 3, "Selected Fireteam outline is stronger")
	_assert(bool(tactical.get("selected_fireteam_label_autowrap_enabled", false)), "Selected Fireteam label wraps")
	_assert(not bool(tactical.get("selected_fireteam_label_clip_text", true)), "Selected Fireteam label is not clipped")
	_assert(float(tactical.get("selected_fireteam_label_min_height", 0.0)) >= 62.0, "Selected Fireteam label has increased minimum height")
	_assert(contact_fire_line.begins_with("CONTACT FIRE") and selected_text.begins_with(contact_fire_line), "Contact fire remains first after style polish")
	_assert(not visible_decision_line.is_empty() and selected_text.split("\n", false).size() >= 2 and String(selected_text.split("\n", false)[1]).strip_edges() == visible_decision_line, "Visible decision remains directly below contact fire")
	_assert(_snapshot_is_read_only(snapshot), "Meta TASK_834 snapshot is read-only")
	_assert(_snapshot_is_read_only(tactical), "Tactical TASK_834 snapshot is read-only")

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
