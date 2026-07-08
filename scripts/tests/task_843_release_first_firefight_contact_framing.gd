extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_843_release_first_firefight_contact_framing.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const META_LAYER_SCRIPT_PATH := "res://scripts/meta/meta_layer_flow.gd"
const META_LAYER_SCENE_PATH := "res://scenes/meta/meta_layer_test.tscn"
const FIRST_GO_FIREFIGHT_ARG := "--release-singleplayer-first-go-firefight"
const SCHEMA := "sternenbuergerchen.release_first_firefight_contact_framing.v1"
const STYLE_ID := "task_843_release_first_firefight_contact_framing_v1"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_843 Release First Firefight Contact Framing ===")
	_test_docs_and_static_hooks()
	await _test_meta_layer_first_firefight_contact_framing()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_843_release_first_firefight_contact_framing: FAILED")
		quit(1)
		return
	print("TASK_843_release_first_firefight_contact_framing: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var meta_text: String = _read_text(META_LAYER_SCRIPT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_843 task file exists")
	_assert(task_text.contains("Release First Firefight Contact Framing"), "Task names contact framing")
	_assert(status_text.contains("TASK_843 - Release First Firefight Contact Framing"), "Implementation status tracks TASK_843")
	_assert(roadmap_text.contains("TASK_843 - Release First Firefight Contact Framing (implementiert)"), "Roadmap marks TASK_843 implemented")
	_assert(contract_text.contains("Release-First-Firefight-Contact-Framing"), "Contract documents TASK_843")
	_assert(controller_text.contains("get_release_first_firefight_contact_framing_snapshot"), "Tactical controller exposes TASK_843 snapshot")
	_assert(meta_text.contains("get_release_first_firefight_contact_framing_snapshot"), "MetaLayer exposes TASK_843 wrapper")
	_assert(controller_text.contains(STYLE_ID), "Controller exposes TASK_843 style id")
	_assert(controller_text.contains("CONTACT PRESSURE"), "Event-log fallback can frame contact pressure")
	_assert(controller_text.contains("\"creates_fire_event\": false"), "TASK_843 snapshot declares no fire-event creation")
	_assert(controller_text.contains("\"creates_damage_event\": false"), "TASK_843 snapshot declares no damage-event creation")
	_assert(controller_text.contains("\"sets_multiplayer_truth\": false"), "TASK_843 snapshot declares no multiplayer truth mutation")


func _test_meta_layer_first_firefight_contact_framing() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := _instantiate_scene(META_LAYER_SCENE_PATH)
	_assert(scene != null, "MetaLayer scene instantiates")
	if scene == null:
		return
	await _wait_frames(10)
	_assert(scene.has_method("_apply_release_first_go_firefight_deeplink"), "MetaLayer exposes first GO/firefight apply hook")
	_assert(scene.has_method("get_release_first_firefight_contact_framing_snapshot"), "MetaLayer exposes TASK_843 callable")
	if not scene.has_method("_apply_release_first_go_firefight_deeplink") or not scene.has_method("get_release_first_firefight_contact_framing_snapshot"):
		scene.queue_free()
		await _wait_frames(1)
		return

	scene.call("_apply_release_first_go_firefight_deeplink", PackedStringArray([FIRST_GO_FIREFIGHT_ARG]))
	await _wait_frames(120)

	var snapshot: Dictionary = Dictionary(scene.call("get_release_first_firefight_contact_framing_snapshot"))
	var tactical: Dictionary = Dictionary(snapshot.get("tactical_framing", {}))
	var framing_state: String = String(snapshot.get("framing_state", ""))
	var framing_line: String = String(snapshot.get("framing_line", ""))
	var event_log: Dictionary = Dictionary(tactical.get("event_log_display", {}))
	var fallback_entry: Dictionary = Dictionary(event_log.get("fallback_entry", {}))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Meta snapshot schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_843", "Meta snapshot task id is TASK_843")
	_assert(String(snapshot.get("status", "")) == "pass", "Meta TASK_843 gate passes: %s" % JSON.stringify(snapshot.get("issues", [])))
	_assert(String(tactical.get("schema", "")) == SCHEMA, "Tactical snapshot schema is stable")
	_assert(String(tactical.get("style_id", "")) == STYLE_ID, "Tactical snapshot exposes TASK_843 style id")
	_assert(String(tactical.get("gate", "")) == "pass", "Tactical TASK_843 gate passes: %s" % JSON.stringify(tactical.get("failed_checks", [])))
	_assert(framing_state == "fire_exchange" or framing_state == "contact_pressure", "First Firefight is framed as exchange or pressure")
	_assert(framing_line.contains("CONTACT FIRE") or framing_line.contains("CONTACT PRESSURE"), "Framing line names contact state")
	_assert(framing_line.contains("NEXT"), "Framing line names the next player step")
	_assert(int(tactical.get("selected_contact_count", 0)) > 0, "Framing keeps selected contact visible")
	_assert(not String(tactical.get("compact_combat_line", "")).strip_edges().is_empty(), "Framing keeps compact combat line visible")
	_assert(framing_state == "fire_exchange" or not String(tactical.get("pressure_reason", "")).strip_edges().is_empty(), "Pressure reason is visible when no shot is framed")
	if framing_state == "contact_pressure":
		_assert(bool(tactical.get("event_log_frames_pressure", false)), "No-fire event log is framed as contact pressure")
		if bool(event_log.get("fallback_active", false)):
			_assert(String(fallback_entry.get("short_text", "")).contains("CONTACT PRESSURE"), "No-fire fallback is framed as contact pressure")
	else:
		_assert(int(tactical.get("fire_event_count", 0)) > 0 or not String(tactical.get("first_fire_event_id", "")).strip_edges().is_empty(), "Fire exchange has fire-event evidence")
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
