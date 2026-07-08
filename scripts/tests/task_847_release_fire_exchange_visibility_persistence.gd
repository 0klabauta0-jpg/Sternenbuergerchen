extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_847_release_fire_exchange_visibility_persistence.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const META_LAYER_SCRIPT_PATH := "res://scripts/meta/meta_layer_flow.gd"
const META_LAYER_SCENE_PATH := "res://scenes/meta/meta_layer_test.tscn"
const FIRST_GO_FIREFIGHT_ARG := "--release-singleplayer-first-go-firefight"
const SCHEMA := "sternenbuergerchen.release_fire_exchange_visibility_persistence.v1"
const STYLE_ID := "task_847_release_fire_exchange_visibility_persistence_v1"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_847 Release Fire Exchange Visibility Persistence ===")
	_test_docs_and_static_hooks()
	await _test_meta_layer_fire_exchange_visibility_persistence()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_847_release_fire_exchange_visibility_persistence: FAILED")
		quit(1)
		return
	print("TASK_847_release_fire_exchange_visibility_persistence: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var meta_text: String = _read_text(META_LAYER_SCRIPT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_847 task file exists")
	_assert(task_text.contains("Release Fire Exchange Visibility Persistence"), "Task names visibility persistence")
	_assert(status_text.contains("TASK_847 - Release Fire Exchange Visibility Persistence"), "Implementation status tracks TASK_847")
	_assert(roadmap_text.contains("TASK_847 - Release Fire Exchange Visibility Persistence (implementiert)"), "Roadmap marks TASK_847 implemented")
	_assert(roadmap_text.contains("TASK_848 - Release First Exchange Recapture Acceptance"), "Roadmap names TASK_848 follow-up")
	_assert(contract_text.contains("Release-Fire-Exchange-Visibility-Persistence"), "Contract documents TASK_847")
	_assert(report_text.contains("TASK_847") and report_text.contains("Sichtbarkeits-Fix"), "Interim report tracks TASK_847")
	_assert(controller_text.contains("get_release_fire_exchange_visibility_persistence_snapshot"), "Tactical controller exposes TASK_847 snapshot")
	_assert(meta_text.contains("get_release_fire_exchange_visibility_persistence_snapshot"), "MetaLayer exposes TASK_847 wrapper")
	_assert(controller_text.contains(STYLE_ID), "Controller exposes TASK_847 style id")
	_assert(controller_text.contains("RELEASE_FIRE_EXCHANGE_VISIBILITY_PERSISTENCE_MSEC"), "Controller uses a bounded persistence window")
	_assert(controller_text.contains("\"CONTACT FIRE: Feuerwechsel lesen\""), "Controller event-log fallback can frame contact fire")
	_assert(controller_text.contains("\"creates_fire_event\": false"), "TASK_847 declares no fire-event creation")
	_assert(controller_text.contains("\"creates_damage_event\": false"), "TASK_847 declares no damage-event creation")
	_assert(controller_text.contains("\"sets_multiplayer_truth\": false"), "TASK_847 declares no multiplayer truth mutation")


func _test_meta_layer_fire_exchange_visibility_persistence() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := _instantiate_scene(META_LAYER_SCENE_PATH)
	_assert(scene != null, "MetaLayer scene instantiates")
	if scene == null:
		return
	await _wait_frames(10)
	_assert(scene.has_method("_apply_release_first_go_firefight_deeplink"), "MetaLayer exposes first GO/firefight apply hook")
	_assert(scene.has_method("get_release_fire_exchange_visibility_persistence_snapshot"), "MetaLayer exposes TASK_847 callable")
	if not scene.has_method("_apply_release_first_go_firefight_deeplink") or not scene.has_method("get_release_fire_exchange_visibility_persistence_snapshot"):
		scene.queue_free()
		await _wait_frames(1)
		return

	scene.call("_apply_release_first_go_firefight_deeplink", PackedStringArray([FIRST_GO_FIREFIGHT_ARG]))
	await _wait_frames(155)

	var snapshot: Dictionary = Dictionary(scene.call("get_release_fire_exchange_visibility_persistence_snapshot"))
	var tactical: Dictionary = Dictionary(snapshot.get("tactical_persistence", {}))
	var compact_line: String = String(tactical.get("compact_line", "")).strip_edges()
	var decision_line: String = String(tactical.get("decision_line", "")).strip_edges()
	var event_log_short_text: String = String(tactical.get("event_log_short_text", "")).strip_edges()
	if String(snapshot.get("status", "")) != "pass" or String(tactical.get("gate", "")) != "pass":
		print("TASK_847_DIAGNOSTIC %s" % JSON.stringify({
			"meta_issues": snapshot.get("issues", []),
			"tactical_failed_checks": tactical.get("failed_checks", []),
			"compact_line": compact_line,
			"decision_line": decision_line,
			"event_log_short_text": event_log_short_text,
			"visibility_persistence_active": tactical.get("visibility_persistence_active", false),
			"combat_hud_density": tactical.get("combat_hud_density", {}),
		}))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Meta snapshot schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_847", "Meta snapshot task id is TASK_847")
	_assert(String(snapshot.get("status", "")) == "pass", "Meta TASK_847 gate passes: %s" % JSON.stringify(snapshot.get("issues", [])))
	_assert(String(tactical.get("schema", "")) == SCHEMA, "Tactical snapshot schema is stable")
	_assert(String(tactical.get("style_id", "")) == STYLE_ID, "Tactical snapshot exposes TASK_847 style id")
	_assert(String(tactical.get("gate", "")) == "pass", "Tactical TASK_847 gate passes: %s" % JSON.stringify(tactical.get("failed_checks", [])))
	_assert(bool(tactical.get("visibility_persistence_active", false)), "Visibility persistence is active")
	_assert(compact_line.to_upper().begins_with("FIRE"), "Compact line starts with FIRE")
	_assert(not compact_line.to_upper().begins_with("NO FIRE"), "Compact line does not regress to NO FIRE")
	_assert(decision_line.contains("NEXT HIT LESEN / DEFEND"), "Decision line tells the player to read hit/defend")
	_assert(decision_line.contains("WHY FEUER"), "Decision line explains why as fire")
	_assert(event_log_short_text.contains("CONTACT FIRE"), "Event log fallback names CONTACT FIRE")
	_assert(not String(tactical.get("fire_event_id", "")).strip_edges().is_empty(), "Persisted visibility references a FireEvent id")
	_assert(int(tactical.get("remaining_msec", 0)) > 0, "Persistence window has remaining time")
	_assert(bool(snapshot.get("read_only", false)), "Meta snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Meta snapshot does not set gameplay truth")
	_assert(not bool(tactical.get("creates_command", true)), "Tactical snapshot creates no commands")
	_assert(not bool(tactical.get("creates_fire_event", true)), "Tactical snapshot creates no fire events")
	_assert(not bool(tactical.get("creates_damage_event", true)), "Tactical snapshot creates no damage events")
	_assert(not bool(tactical.get("sets_multiplayer_truth", true)), "Tactical snapshot sets no multiplayer truth")

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
