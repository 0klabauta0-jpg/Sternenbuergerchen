extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_833_release_firefight_hud_readability_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const META_LAYER_SCENE_PATH := "res://scenes/meta/meta_layer_test.tscn"
const META_LAYER_SCRIPT_PATH := "res://scripts/meta/meta_layer_flow.gd"
const CONTROLLER_SCRIPT_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const FIRST_GO_FIREFIGHT_ARG := "--release-singleplayer-first-go-firefight"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_833 Release Firefight HUD Readability Polish ===")
	_test_docs_contract_and_static_hooks()
	await _test_firefight_decision_line_is_first_selected_fireteam_line()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_833_release_firefight_hud_readability_polish: FAILED")
		quit(1)
		return
	print("TASK_833_release_firefight_hud_readability_polish: ALL PASSED")
	quit(0)


func _test_docs_contract_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var meta_text: String = _read_text(META_LAYER_SCRIPT_PATH)
	var controller_text: String = _read_text(CONTROLLER_SCRIPT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_833 task file exists")
	_assert(task_text.contains("Release Firefight HUD Readability Polish"), "Task names release firefight HUD readability polish")
	_assert(status_text.contains("TASK_833 - Release Firefight HUD Readability Polish"), "Implementation status tracks TASK_833")
	_assert(roadmap_text.contains("TASK_833 - Release Firefight HUD Readability Polish (implementiert)"), "Roadmap marks TASK_833 implemented")
	_assert(contract_text.contains("Release-Firefight-HUD-Readability-Polish"), "Mission command feedback contract documents TASK_833")
	_assert(meta_text.contains("get_release_firefight_hud_readability_polish_snapshot"), "MetaLayer exposes TASK_833 snapshot")
	_assert(controller_text.contains("get_release_firefight_hud_readability_polish_snapshot"), "TacticalController exposes TASK_833 snapshot")
	_assert(controller_text.contains("_compact_release_first_exchange_contact_fire_line"), "Controller exposes the compact contact-fire priority helper")


func _test_firefight_decision_line_is_first_selected_fireteam_line() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := _instantiate_scene(META_LAYER_SCENE_PATH)
	_assert(scene != null, "MetaLayer scene instantiates")
	if scene == null:
		return
	await _wait_frames(10)
	_assert(scene.has_method("_apply_release_first_go_firefight_deeplink"), "MetaLayer exposes first GO/firefight deep-link hook")
	_assert(scene.has_method("get_release_firefight_hud_readability_polish_snapshot"), "MetaLayer exposes TASK_833 callable")
	if not scene.has_method("_apply_release_first_go_firefight_deeplink") or not scene.has_method("get_release_firefight_hud_readability_polish_snapshot"):
		scene.queue_free()
		await _wait_frames(2)
		return

	scene.call("_apply_release_first_go_firefight_deeplink", PackedStringArray([FIRST_GO_FIREFIGHT_ARG]))
	await _wait_frames(120)

	var snapshot: Dictionary = Dictionary(scene.call("get_release_firefight_hud_readability_polish_snapshot", {}, {}, {}))
	var tactical: Dictionary = Dictionary(snapshot.get("tactical_readability", {}))
	var decision_line: String = String(snapshot.get("decision_line", "")).strip_edges()
	var visible_decision_line: String = String(tactical.get("visible_decision_line", "")).strip_edges()
	var selected_first_line: String = String(snapshot.get("selected_fireteam_first_line", "")).strip_edges()
	var selected_text: String = String(snapshot.get("selected_fireteam_status_text", "")).strip_edges()
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.release_firefight_hud_readability_polish.v1", "TASK_833 schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_833", "Snapshot task id is TASK_833")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_817", "Snapshot builds on TASK_817")
	_assert(String(snapshot.get("status", "")) == "pass", "Meta TASK_833 gate passes")
	_assert(String(tactical.get("gate", "")) == "pass", "Tactical TASK_833 gate passes")
	_assert(not decision_line.is_empty() and decision_line.begins_with("NEXT "), "Decision line is active")
	_assert(selected_first_line.begins_with("CONTACT FIRE"), "Selected Fireteam starts with the active contact-fire readout")
	_assert(not visible_decision_line.is_empty() and selected_text.begins_with(selected_first_line) and selected_text.contains(visible_decision_line), "Selected Fireteam keeps the decision directly below contact fire")
	_assert(bool(tactical.get("combat_line_visible", false)), "Combat readout remains visible through the contact-fire line")
	_assert(int(tactical.get("selected_fireteam_line_count", 0)) <= 2, "Selected Fireteam status stays within the two-line firefight budget")
	_assert(_snapshot_is_read_only(snapshot), "Meta TASK_833 snapshot is read-only")
	_assert(_snapshot_is_read_only(tactical), "Tactical TASK_833 snapshot is read-only")

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
