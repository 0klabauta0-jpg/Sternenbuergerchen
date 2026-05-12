extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_331_mission_tactical_controller_adapter_split_first_slice.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/mission_tactical_controller_adapter_split_first_slice.md"
const CONTROLLER_PATH: String = "res://scripts/mission/mission_tactical_sandbox_controller.gd"
const ADAPTER_PATH: String = "res://scripts/mission/mission_command_feedback_snapshot_adapter.gd"

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const ADAPTER_SCRIPT: GDScript = preload("res://scripts/mission/mission_command_feedback_snapshot_adapter.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_331 Mission Tactical Controller Adapter Split First Slice ===")
	_test_docs_status_and_report()
	_test_static_adapter_boundary()
	_test_adapter_count_contract()
	await _test_live_feedback_snapshot_uses_single_selection_truth()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_docs_status_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "TASK_331 task file marks implemented")
	_assert(not task_text.contains("- [ ]"), "TASK_331 checklist is complete")
	_assert(status_text.contains("### TASK_331 - Mission Tactical Controller Adapter Split First Slice") and status_text.contains("- Status: implementiert"), "Implementation status marks TASK_331 implemented")
	_assert(roadmap_text.contains("TASK_331 - Mission Tactical Controller Adapter Split First Slice (implementiert"), "Roadmap marks TASK_331 implemented")
	for token in ["Adapter", "Snapshot", "Selection", "Disabled-Reasons", "keine Gameplay-Wahrheit"]:
		_assert(report_text.to_lower().contains(token.to_lower()), "Report documents %s" % token)


func _test_static_adapter_boundary() -> void:
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var adapter_text: String = _read_text(ADAPTER_PATH)
	_assert(controller_text.contains("MISSION_COMMAND_FEEDBACK_SNAPSHOT_ADAPTER_SCRIPT"), "Controller preloads the feedback snapshot adapter")
	_assert(controller_text.contains("_command_feedback_adapter"), "Controller owns a feedback adapter instance")
	_assert(controller_text.contains("_build_command_feedback_snapshot_context"), "Controller exposes a read-only feedback context builder")
	_assert(controller_text.contains("_command_feedback_adapter.call(\"build_snapshot\""), "get_command_feedback_snapshot delegates snapshot assembly")
	_assert(adapter_text.contains("extends RefCounted"), "Adapter is a lightweight RefCounted helper")
	_assert(adapter_text.contains("func build_snapshot(context: Dictionary) -> Dictionary:"), "Adapter exposes build_snapshot")
	for token in ["enqueue_command", "enqueue_effect", "set_runtime_status", "apply_damage(", "take_damage("]:
		_assert(not adapter_text.contains(token), "Adapter contains no authoritative mutation token %s" % token)


func _test_adapter_count_contract() -> void:
	var adapter = ADAPTER_SCRIPT.new()
	var snapshot: Dictionary = Dictionary(adapter.call("build_snapshot", {
		"selected_fireteam_ids": PackedStringArray(["blue", "gold"]),
		"fireteamleader_feedback_bubbles": [{"bubble_id": "one"}, {"bubble_id": "two"}],
		"tactical_communication_events": [{"event_id": "one"}],
		"tactical_breakouts": [],
		"fireteam_coordination": [{"coordination_id": "one"}],
		"air_asset_threats": [{"threat_id": "one"}, {"threat_id": "two"}, {"threat_id": "three"}],
		"npc_thought_bubbles": [{"bubble_id": "npc"}],
	}))
	_assert(_same_string_set(Array(snapshot.get("selected_fireteam_ids", [])), ["blue", "gold"]), "Adapter normalizes selected fireteams to an Array")
	_assert(int(snapshot.get("fireteamleader_feedback_bubble_count", -1)) == 2, "Adapter derives FTL feedback bubble count")
	_assert(int(snapshot.get("tactical_communication_event_count", -1)) == 1, "Adapter derives tactical communication count")
	_assert(int(snapshot.get("fireteam_coordination_count", -1)) == 1, "Adapter derives fireteam coordination count")
	_assert(int(snapshot.get("air_asset_threat_count", -1)) == 3, "Adapter derives air asset threat count")
	_assert(int(snapshot.get("npc_thought_bubble_count", -1)) == 1, "Adapter derives NPC thought bubble count")


func _test_live_feedback_snapshot_uses_single_selection_truth() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(24)

	var controller := scene.get_node_or_null("TacticalController")
	var primary_view := scene.get_node_or_null("Primary3DView")
	var simulation_root := scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and primary_view != null and simulation_root != null, "Mission scene exposes controller, Primary3DView and SimulationRoot")
	if controller == null or primary_view == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var command_count_before: int = simulation_root.command_queue.size()
	var effect_count_before: int = simulation_root.effects_queue.size()
	controller.call("_set_selected_fireteams", PackedStringArray(["blue", "gold"]), false)
	await _wait_frames(6)

	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var hierarchy: Dictionary = Dictionary(feedback.get("command_hierarchy", {}))
	var map_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(_same_string_set(Array(feedback.get("selected_fireteam_ids", [])), ["blue", "gold"]), "Feedback snapshot mirrors selected fireteams")
	_assert(_same_string_set(Array(map_snapshot.get("order_selected_fireteam_ids", [])), Array(feedback.get("selected_fireteam_ids", []))), "Primary3DView mirrors the same selected fireteams")
	_assert(bool(hierarchy.get("visual_only", false)), "Command hierarchy remains visual-only")
	_assert(not bool(hierarchy.get("ui_sets_gameplay_truth", true)), "Command hierarchy confirms UI is not gameplay truth")
	_assert(int(feedback.get("fireteamleader_feedback_bubble_count", -1)) == Array(feedback.get("fireteamleader_feedback_bubbles", [])).size(), "FTL bubble count matches payload array")
	_assert(int(feedback.get("tactical_communication_event_count", -1)) == Array(feedback.get("tactical_communication_events", [])).size(), "Communication count matches payload array")
	_assert(int(feedback.get("air_asset_threat_count", -1)) == Array(feedback.get("air_asset_threats", [])).size(), "Air asset threat count matches payload array")
	_assert(simulation_root.command_queue.size() == command_count_before, "Feedback snapshot enqueues no SimulationRoot commands")
	_assert(simulation_root.effects_queue.size() == effect_count_before, "Feedback snapshot enqueues no SimulationRoot effects")

	controller.call("_set_selected_fireteams", PackedStringArray(), false)
	await _wait_frames(4)
	var empty_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var move_action: Dictionary = Dictionary(Dictionary(Dictionary(empty_feedback.get("command_hierarchy", {})).get("actions_by_id", {})).get("move", {}))
	_assert(String(move_action.get("disabled_reason", "")).to_lower().contains("select"), "No-selection Move keeps a specific disabled reason")

	scene.queue_free()
	await _wait_frames(2)


func _same_string_set(actual: Array, expected: Array) -> bool:
	var normalized_actual: PackedStringArray = PackedStringArray()
	for value in actual:
		var text: String = String(value).strip_edges().to_lower()
		if not text.is_empty():
			normalized_actual.append(text)
	var normalized_expected: PackedStringArray = PackedStringArray()
	for value in expected:
		var text: String = String(value).strip_edges().to_lower()
		if not text.is_empty():
			normalized_expected.append(text)
	normalized_actual.sort()
	normalized_expected.sort()
	return Array(normalized_actual) == Array(normalized_expected)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
