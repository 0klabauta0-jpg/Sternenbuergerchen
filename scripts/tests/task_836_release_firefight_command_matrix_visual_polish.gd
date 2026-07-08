extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_836_release_firefight_command_matrix_visual_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const META_LAYER_SCENE_PATH := "res://scenes/meta/meta_layer_test.tscn"
const META_LAYER_SCRIPT_PATH := "res://scripts/meta/meta_layer_flow.gd"
const CONTROLLER_SCRIPT_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const FIRST_GO_FIREFIGHT_ARG := "--release-singleplayer-first-go-firefight"
const STYLE_ID := "task_836_release_firefight_command_matrix_visual_v1"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_836 Release Firefight Command Matrix Visual Polish ===")
	_test_docs_contract_and_static_hooks()
	await _test_firefight_command_matrix_visual_polish()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_836_release_firefight_command_matrix_visual_polish: FAILED")
		quit(1)
		return
	print("TASK_836_release_firefight_command_matrix_visual_polish: ALL PASSED")
	quit(0)


func _test_docs_contract_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var meta_text: String = _read_text(META_LAYER_SCRIPT_PATH)
	var controller_text: String = _read_text(CONTROLLER_SCRIPT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_836 task file exists")
	_assert(task_text.contains("Release Firefight Command Matrix Visual Polish"), "Task names release firefight command-matrix visual polish")
	_assert(status_text.contains("TASK_836 - Release Firefight Command Matrix Visual Polish"), "Implementation status tracks TASK_836")
	_assert(roadmap_text.contains("TASK_836 - Release Firefight Command Matrix Visual Polish (implementiert)"), "Roadmap marks TASK_836 implemented")
	_assert(contract_text.contains("Release-Firefight-Command-Matrix-Visual-Polish"), "Mission command feedback contract documents TASK_836")
	_assert(meta_text.contains("get_release_firefight_command_matrix_visual_polish_snapshot"), "MetaLayer exposes TASK_836 snapshot")
	_assert(controller_text.contains("get_release_firefight_command_matrix_visual_polish_snapshot"), "TacticalController exposes TASK_836 snapshot")
	_assert(controller_text.contains(STYLE_ID), "Controller defines the TASK_836 command-matrix style id")


func _test_firefight_command_matrix_visual_polish() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := _instantiate_scene(META_LAYER_SCENE_PATH)
	_assert(scene != null, "MetaLayer scene instantiates")
	if scene == null:
		return
	await _wait_frames(10)
	_assert(scene.has_method("_apply_release_first_go_firefight_deeplink"), "MetaLayer exposes first GO/firefight deep-link hook")
	_assert(scene.has_method("get_release_firefight_command_matrix_visual_polish_snapshot"), "MetaLayer exposes TASK_836 callable")
	if not scene.has_method("_apply_release_first_go_firefight_deeplink") or not scene.has_method("get_release_firefight_command_matrix_visual_polish_snapshot"):
		scene.queue_free()
		await _wait_frames(2)
		return

	scene.call("_apply_release_first_go_firefight_deeplink", PackedStringArray([FIRST_GO_FIREFIGHT_ARG]))
	await _wait_frames(120)

	var snapshot: Dictionary = Dictionary(scene.call("get_release_firefight_command_matrix_visual_polish_snapshot", {}, {}, {}))
	var tactical: Dictionary = Dictionary(snapshot.get("tactical_command_matrix", {}))
	var command_matrix: Dictionary = Dictionary(snapshot.get("command_matrix", {}))
	if String(snapshot.get("status", "")) != "pass" or String(tactical.get("gate", "")) != "pass":
		print("TASK_836 snapshot issues: %s" % [str(snapshot.get("issues", []))])
		print("TASK_836 tactical failed checks: %s" % [str(tactical.get("failed_checks", []))])
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.release_firefight_command_matrix_visual_polish.v1", "TASK_836 schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_836", "Snapshot task id is TASK_836")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_835", "Snapshot builds on TASK_835")
	_assert(String(snapshot.get("status", "")) == "pass", "Meta TASK_836 gate passes")
	_assert(String(tactical.get("gate", "")) == "pass", "Tactical TASK_836 gate passes")
	_assert(String(snapshot.get("style_id", "")) == STYLE_ID, "Meta snapshot exposes TASK_836 style id")
	_assert(String(command_matrix.get("style_id", "")) == STYLE_ID, "Command Matrix carries TASK_836 style id")
	_assert(bool(command_matrix.get("active", false)), "Command Matrix visual polish is active")
	_assert(bool(command_matrix.get("go_button_prominent", false)), "GO button is prominent")
	_assert(float(command_matrix.get("go_button_visual_weight", 0.0)) >= 2.4, "GO button visual weight is raised")
	_assert(int(command_matrix.get("go_button_font_size", 0)) >= 12, "GO button font is larger")
	_assert(int(command_matrix.get("primary_button_count", 0)) >= 5, "Primary command button count is present")
	_assert(int(command_matrix.get("primary_readable_count", 0)) >= 5, "Primary command buttons are readable")
	_assert(int(command_matrix.get("active_fire_rule_count", 0)) == 1, "Exactly one fire rule is active")
	_assert(float(command_matrix.get("active_fire_rule_visual_weight", 0.0)) >= 2.0, "Active Fire-Rule visual weight is raised")
	_assert(int(command_matrix.get("quiet_placeholder_count", 0)) == int(command_matrix.get("placeholder_count", -1)), "Placeholder slots are quiet")
	_assert(_snapshot_is_read_only(snapshot), "Meta TASK_836 snapshot is read-only")
	_assert(_snapshot_is_read_only(tactical), "Tactical TASK_836 snapshot is read-only")

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
