extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_876_release_first_exchange_visible_status_source_reconciliation.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const META_LAYER_SCENE_PATH := "res://scenes/meta/meta_layer_test.tscn"
const FIRST_GO_FIREFIGHT_ARG := "--release-singleplayer-first-go-firefight"
const SCHEMA := "sternenbuergerchen.release_first_exchange_visible_status_source_reconciliation.v1"
const STYLE_ID := "task_876_release_first_exchange_visible_status_source_reconciliation_v1"
const NEXT_TASK := "TASK_877 - Release First Exchange Visible Status Recapture"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_876 Release First Exchange Visible Status Source Reconciliation ===")
	_test_docs_and_static_hooks()
	await _test_meta_layer_visible_status_source_reconciliation()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_876_release_first_exchange_visible_status_source_reconciliation: FAILED")
		quit(1)
		return
	print("TASK_876_release_first_exchange_visible_status_source_reconciliation: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_876 task file exists")
	_assert(task_text.contains("Release First Exchange Visible Status Source Reconciliation"), "Task names TASK_876")
	_assert(status_text.contains("TASK_876 - Release First Exchange Visible Status Source Reconciliation"), "Implementation status tracks TASK_876")
	_assert(roadmap_text.contains("TASK_876 - Release First Exchange Visible Status Source Reconciliation (implementiert)"), "Roadmap marks TASK_876 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_877 follow-up")
	_assert(contract_text.contains("Release-First-Exchange-Visible-Status-Source-Reconciliation (TASK_876)"), "Contract documents TASK_876")
	_assert(controller_text.contains(STYLE_ID), "Controller exposes TASK_876 style id")
	_assert(controller_text.contains("RELEASE_FIRST_EXCHANGE_VISIBLE_STATUS_SOURCE_RECONCILIATION_MSEC"), "Controller defines TASK_876 visible-window duration")
	_assert(controller_text.contains("_promote_release_first_exchange_visible_status_source_evidence"), "Controller promotes TASK_873 evidence")
	_assert(controller_text.contains("_get_release_first_exchange_visible_status_source_evidence"), "Controller reads TASK_876 status source")
	_assert(controller_text.contains("get_release_first_exchange_visible_status_source_reconciliation_snapshot"), "Controller exposes TASK_876 snapshot")
	_assert(controller_text.contains("\"creates_command\": false"), "TASK_876 source declares no command creation")
	_assert(controller_text.contains("\"creates_fire_event\": false"), "TASK_876 source declares no fire-event creation")
	_assert(controller_text.contains("\"creates_damage_event\": false"), "TASK_876 source declares no damage-event creation")
	_assert(controller_text.contains("\"sets_multiplayer_truth\": false"), "TASK_876 source declares no multiplayer truth")


func _test_meta_layer_visible_status_source_reconciliation() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := _instantiate_scene(META_LAYER_SCENE_PATH)
	_assert(scene != null, "MetaLayer scene instantiates")
	if scene == null:
		return
	await _wait_frames(10)
	_assert(scene.has_method("_apply_release_first_go_firefight_deeplink"), "MetaLayer exposes first GO/firefight apply hook")
	if not scene.has_method("_apply_release_first_go_firefight_deeplink"):
		scene.queue_free()
		await _wait_frames(1)
		return
	scene.call("_apply_release_first_go_firefight_deeplink", PackedStringArray([FIRST_GO_FIREFIGHT_ARG]))
	await _wait_frames(180)
	var active_mission = scene.call("get_active_mission") if scene.has_method("get_active_mission") else null
	_assert(active_mission != null, "Deep-link keeps active mission alive")
	if active_mission == null:
		scene.queue_free()
		await _wait_frames(1)
		return
	var controller: Node = active_mission.get_node_or_null("TacticalController")
	_assert(controller != null, "Active mission exposes TacticalController")
	if controller == null:
		scene.queue_free()
		await _wait_frames(1)
		return
	_assert(controller.has_method("get_release_first_exchange_visible_status_source_reconciliation_snapshot"), "Controller exposes TASK_876 runtime snapshot")
	if not controller.has_method("get_release_first_exchange_visible_status_source_reconciliation_snapshot"):
		scene.queue_free()
		await _wait_frames(1)
		return
	var snapshot: Dictionary = Dictionary(controller.call("get_release_first_exchange_visible_status_source_reconciliation_snapshot"))
	if String(snapshot.get("gate", "")) != "pass":
		print("TASK_876_DIAGNOSTIC %s" % JSON.stringify({
			"failed_checks": snapshot.get("failed_checks", []),
			"selected": snapshot.get("selected_fireteam_status_text", ""),
			"mission": snapshot.get("mission_control_status_text", ""),
			"event_log": snapshot.get("event_log_short_text", ""),
			"status_source": snapshot.get("status_source", {}),
			"combat_hud_density": snapshot.get("combat_hud_density", {}),
		}))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_876", "Snapshot task id is TASK_876")
	_assert(String(snapshot.get("style_id", "")) == STYLE_ID, "Snapshot exposes TASK_876 style id")
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_876 gate passes: %s" % JSON.stringify(snapshot.get("failed_checks", [])))
	_assert(bool(snapshot.get("active", false)), "TASK_876 source is active")
	_assert(bool(snapshot.get("selected_fireteam_contact_fire_first", false)), "#17 starts CONTACT FIRE")
	_assert(bool(snapshot.get("mission_control_contact_fire_first", false)), "#18 starts CONTACT FIRE")
	_assert(bool(snapshot.get("event_log_contact_fire", false)), "#19 contains CONTACT FIRE")
	_assert(not bool(snapshot.get("primary_lines_contain_debug_no_fire_before_contact_fire", true)), "NO FIRE does not appear before CONTACT FIRE")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_command", true)), "Snapshot creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Snapshot creates no damage events")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Snapshot sets no multiplayer truth")

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
