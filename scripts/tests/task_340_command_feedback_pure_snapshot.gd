extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_340_command_feedback_pure_snapshot.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTROLLER_PATH: String = "res://scripts/mission/mission_tactical_sandbox_controller.gd"
const ADAPTER_PATH: String = "res://scripts/mission/mission_command_feedback_snapshot_adapter.gd"
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const FIRETEAM_STATUS_LABEL_PATH: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderRow/FireteamStatusLabel"
const STRATEGIC_STATUS_LABEL_PATH: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicStatusLabel"
const STALE_LABEL_TEXT: String = "TASK_340_STALE_RENDERED_LABEL"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_340 Command Feedback Pure Snapshot ===")
	_test_docs_and_static_contract()
	await _test_snapshot_ignores_stale_rendered_labels()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_docs_and_static_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var adapter_text: String = _read_text(ADAPTER_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "TASK_340 task file marks implemented")
	_assert(not task_text.contains("- [ ]"), "TASK_340 checklist has no unchecked item")
	_assert(status_text.contains("### TASK_340 - Command Feedback Pure Snapshot") and status_text.contains("- Status: implementiert"), "Implementation status marks TASK_340 implemented")
	_assert(roadmap_text.contains("TASK_340 - Command Feedback Pure Snapshot (implementiert"), "Roadmap marks TASK_340 implemented")
	_assert(controller_text.contains("func _build_command_feedback_text_payload() -> Dictionary:"), "Controller exposes pure command feedback text payload builder")
	_assert(controller_text.contains("\"command_feedback_payload\": command_feedback_payload"), "Controller passes the computed payload into the snapshot context")
	_assert(not controller_text.contains("_get_label_text("), "Controller no longer reads rendered Label.text values for feedback snapshots")
	_assert(adapter_text.contains("\"command_feedback_payload\""), "Adapter preserves the pure command feedback payload defensively")


func _test_snapshot_ignores_stale_rendered_labels() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(16)

	var controller := scene.get_node_or_null("TacticalController")
	var simulation_root := scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and simulation_root != null, "Mission scene exposes controller and SimulationRoot")
	if controller == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	controller.call("_set_selected_fireteams", PackedStringArray(), false)
	controller.call("_update_ui")
	await _wait_frames(2)

	var command_label := controller.get_node_or_null(NodePath(str(controller.get("command_feedback_label_path")))) as Label
	var fireteam_status_label := controller.get_node_or_null(FIRETEAM_STATUS_LABEL_PATH) as Label
	var strategic_status_label := controller.get_node_or_null(STRATEGIC_STATUS_LABEL_PATH) as Label
	_assert(command_label != null and fireteam_status_label != null and strategic_status_label != null, "Verifier resolves rendered command feedback labels")
	if command_label == null or fireteam_status_label == null or strategic_status_label == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var expected_payload: Dictionary = Dictionary(controller.call("_build_command_feedback_text_payload"))
	command_label.text = STALE_LABEL_TEXT
	fireteam_status_label.text = STALE_LABEL_TEXT
	strategic_status_label.text = STALE_LABEL_TEXT
	controller.set("_last_target_position", Vector2(-340.0, -340.0))
	var command_count_before: int = simulation_root.command_queue.size()
	var effect_count_before: int = simulation_root.effects_queue.size()

	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var payload: Dictionary = Dictionary(feedback.get("command_feedback_payload", {}))
	_assert(String(feedback.get("command_feedback_text", "")) == String(expected_payload.get("command_feedback_text", "")), "Snapshot command feedback text is computed from state, not rendered Label.text")
	_assert(String(feedback.get("selected_fireteam_status_label_text", "")) == String(expected_payload.get("selected_fireteam_status_label_text", "")), "Snapshot selected status text ignores stale rendered label")
	_assert(String(feedback.get("mission_control_status_text", "")) == String(expected_payload.get("mission_control_status_text", "")), "Snapshot mission-control status text ignores stale rendered label")
	_assert(String(feedback.get("command_feedback_text", "")) != STALE_LABEL_TEXT, "Snapshot does not echo stale command label text")
	_assert(String(feedback.get("selected_fireteam_status_label_text", "")) != STALE_LABEL_TEXT, "Snapshot does not echo stale selected-status label text")
	_assert(String(feedback.get("mission_control_status_text", "")) != STALE_LABEL_TEXT, "Snapshot does not echo stale mission-control label text")
	_assert(String(payload.get("command_feedback_text", "")) == String(feedback.get("command_feedback_text", "")), "Adapter exposes the same pure payload used by top-level snapshot fields")
	_assert(String(payload.get("selected_status_text", "")) == String(feedback.get("selected_status_text", "")), "Pure payload and top-level selected status stay in sync")
	_assert(Vector2(controller.get("_last_target_position")) == Vector2(-340.0, -340.0), "Snapshot build leaves controller target cache untouched")
	_assert(simulation_root.command_queue.size() == command_count_before, "Pure feedback snapshot enqueues no SimulationRoot commands")
	_assert(simulation_root.effects_queue.size() == effect_count_before, "Pure feedback snapshot enqueues no SimulationRoot effects")

	controller.call("_update_ui")
	await _wait_frames(2)
	_assert(command_label.text == String(Dictionary(controller.call("_build_command_feedback_text_payload")).get("command_feedback_text", "")), "Rendered command label is fed from the same pure payload")
	_assert(fireteam_status_label.text == String(Dictionary(controller.call("_build_command_feedback_text_payload")).get("selected_fireteam_status_label_text", "")), "Rendered selected-status label is fed from the same pure payload")
	_assert(strategic_status_label.text == String(Dictionary(controller.call("_build_command_feedback_text_payload")).get("mission_control_status_text", "")), "Rendered mission-control label is fed from the same pure payload")

	var no_selection_action: Dictionary = _get_feedback_action(feedback, "move")
	_assert(String(no_selection_action.get("disabled_reason_code", "")) == "no_fireteam_selected", "Existing TASK_335 disabled reason code remains stable")
	_assert(bool(Dictionary(feedback.get("command_clarity", {})).get("visual_only", false)), "Command clarity remains visual-only")

	scene.queue_free()
	await _wait_frames(2)


func _get_feedback_action(feedback: Dictionary, action_id: String) -> Dictionary:
	var hierarchy: Dictionary = Dictionary(feedback.get("command_hierarchy", {}))
	return Dictionary(Dictionary(hierarchy.get("actions_by_id", {})).get(action_id, {}))


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("  FAIL: %s" % message)
