extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_844_release_first_exchange_tension_tuning.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const META_LAYER_SCRIPT_PATH := "res://scripts/meta/meta_layer_flow.gd"
const META_LAYER_SCENE_PATH := "res://scenes/meta/meta_layer_test.tscn"
const FIRST_GO_FIREFIGHT_ARG := "--release-singleplayer-first-go-firefight"
const SCHEMA := "sternenbuergerchen.release_first_exchange_tension_tuning.v1"
const STYLE_ID := "task_844_release_first_exchange_tension_tuning_v1"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_844 Release First Exchange Tension Tuning ===")
	_test_docs_and_static_hooks()
	await _test_meta_layer_first_exchange_tension_tuning()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_844_release_first_exchange_tension_tuning: FAILED")
		quit(1)
		return
	print("TASK_844_release_first_exchange_tension_tuning: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var meta_text: String = _read_text(META_LAYER_SCRIPT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_844 task file exists")
	_assert(task_text.contains("Release First Exchange Tension Tuning"), "Task names first exchange tuning")
	_assert(status_text.contains("TASK_844 - Release First Exchange Tension Tuning"), "Implementation status tracks TASK_844")
	_assert(roadmap_text.contains("TASK_844 - Release First Exchange Tension Tuning (implementiert)"), "Roadmap marks TASK_844 implemented")
	_assert(contract_text.contains("Release-First-Exchange-Tension-Tuning"), "Contract documents TASK_844")
	_assert(controller_text.contains("get_release_first_exchange_tension_tuning_snapshot"), "Tactical controller exposes TASK_844 snapshot")
	_assert(meta_text.contains("get_release_first_exchange_tension_tuning_snapshot"), "MetaLayer exposes TASK_844 wrapper")
	_assert(controller_text.contains(STYLE_ID), "Controller exposes TASK_844 style id")
	_assert(meta_text.contains("build_cover_effectiveness_readout_for_units"), "Deep-link placement uses existing combat readout")
	_assert(meta_text.contains("placement_verified_attackable"), "Deep-link placement records attackability evidence")
	_assert(controller_text.contains("\"creates_fire_event\": false"), "TASK_844 snapshot declares no fire-event creation")
	_assert(controller_text.contains("\"creates_damage_event\": false"), "TASK_844 snapshot declares no damage-event creation")
	_assert(controller_text.contains("\"sets_multiplayer_truth\": false"), "TASK_844 snapshot declares no multiplayer truth mutation")


func _test_meta_layer_first_exchange_tension_tuning() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := _instantiate_scene(META_LAYER_SCENE_PATH)
	_assert(scene != null, "MetaLayer scene instantiates")
	if scene == null:
		return
	await _wait_frames(10)
	_assert(scene.has_method("_apply_release_first_go_firefight_deeplink"), "MetaLayer exposes first GO/firefight apply hook")
	_assert(scene.has_method("get_release_first_exchange_tension_tuning_snapshot"), "MetaLayer exposes TASK_844 callable")
	if not scene.has_method("_apply_release_first_go_firefight_deeplink") or not scene.has_method("get_release_first_exchange_tension_tuning_snapshot"):
		scene.queue_free()
		await _wait_frames(1)
		return

	scene.call("_apply_release_first_go_firefight_deeplink", PackedStringArray([FIRST_GO_FIREFIGHT_ARG]))
	await _wait_frames(140)

	var snapshot: Dictionary = Dictionary(scene.call("get_release_first_exchange_tension_tuning_snapshot"))
	var tactical: Dictionary = Dictionary(snapshot.get("tactical_exchange", {}))
	var diagnostics: Dictionary = Dictionary(tactical.get("contact_decision_diagnostics", {}))
	if String(snapshot.get("status", "")) != "pass" or String(tactical.get("gate", "")) != "pass":
		print("TASK_844_DIAGNOSTIC %s" % JSON.stringify({
			"meta_issues": snapshot.get("issues", []),
			"tactical_failed_checks": tactical.get("failed_checks", []),
			"framing_state": tactical.get("framing_state", ""),
			"framing_line": tactical.get("framing_line", ""),
			"fire_event_count": tactical.get("fire_event_count", 0),
			"first_fire_event_id": tactical.get("first_fire_event_id", ""),
			"diagnostics": diagnostics,
		}))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Meta snapshot schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_844", "Meta snapshot task id is TASK_844")
	_assert(String(snapshot.get("status", "")) == "pass", "Meta TASK_844 gate passes: %s" % JSON.stringify(snapshot.get("issues", [])))
	_assert(String(tactical.get("schema", "")) == SCHEMA, "Tactical snapshot schema is stable")
	_assert(String(tactical.get("style_id", "")) == STYLE_ID, "Tactical snapshot exposes TASK_844 style id")
	_assert(String(tactical.get("gate", "")) == "pass", "Tactical TASK_844 gate passes: %s" % JSON.stringify(tactical.get("failed_checks", [])))
	_assert(bool(tactical.get("first_exchange_visible", false)), "First exchange is visibly confirmed")
	_assert(String(tactical.get("framing_state", "")) == "fire_exchange", "First contact is an actual fire exchange")
	_assert(String(tactical.get("framing_line", "")).contains("CONTACT FIRE"), "Framing line names contact fire")
	_assert(int(tactical.get("fire_event_count", 0)) > 0 or not String(tactical.get("first_fire_event_id", "")).strip_edges().is_empty(), "Fire exchange has FireEvent evidence")
	_assert(String(tactical.get("range_state", "")) == "in_range", "Exchange target is in range")
	_assert(String(tactical.get("los_state", "")).strip_edges().to_lower() != "blocked", "Exchange LOS is not blocked")
	_assert(bool(tactical.get("combat_attackable", false)), "Exchange pair is combat attackable")
	_assert(String(diagnostics.get("status", "")) == "fired", "Contact decision status fired")
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
