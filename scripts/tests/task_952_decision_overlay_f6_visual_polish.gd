extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_952_decision_overlay_f6_visual_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SCHEMA := "sternenbuergerchen.decision_overlay_f6_visual_polish.v1"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_952 Decision Overlay F6 Visual Polish ===")
	_test_docs_and_static_hooks()
	await _test_controller_exports_compact_decision_badge_polish()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_952_decision_overlay_f6_visual_polish: FAILED")
		quit(1)
		return
	print("TASK_952_decision_overlay_f6_visual_polish: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_952 task file exists")
	_assert(task_text.contains("TASK_952 - Decision Overlay F6 Visual Polish"), "Task names TASK_952")
	_assert(status_text.contains("TASK_952 - Decision Overlay F6 Visual Polish"), "Implementation status tracks TASK_952")
	_assert(roadmap_text.contains("TASK_952 - Decision Overlay F6 Visual Polish (implementiert"), "Roadmap marks TASK_952 implemented")
	_assert(command_contract_text.contains("Decision Overlay F6 Visual Polish (TASK_952)"), "Mission feedback contract documents TASK_952")
	_assert(clarity_contract_text.contains("Decision Overlay F6 Visual Polish (TASK_952)"), "Decision clarity contract documents TASK_952")
	_assert(controller_text.contains("get_decision_overlay_f6_visual_polish_snapshot"), "Controller exposes TASK_952 polish snapshot")
	_assert(controller_text.contains("_build_decision_overlay_f6_visual_badges"), "Controller builds compact visual badges")
	_assert(controller_text.contains("_apply_decision_overlay_f6_visual_polish_label_contract"), "Controller applies TASK_952 label contract")
	_assert(controller_text.contains("decision_overlay_f6_visual_polish"), "Command feedback exports TASK_952 polish snapshot")


func _test_controller_exports_compact_decision_badge_polish() -> void:
	var controller_script: Resource = load(CONTROLLER_PATH)
	if controller_script == null:
		_assert(false, "Controller script can be loaded")
		return
	var controller: Node = controller_script.new()
	get_root().add_child(controller)
	await process_frame
	if not controller.has_method("get_decision_overlay_f6_visual_polish_snapshot"):
		_assert(false, "Controller has TASK_952 public polish snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = Dictionary(controller.call("get_decision_overlay_f6_visual_polish_snapshot"))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "TASK_952 polish schema matches")
	_assert(String(snapshot.get("task_id", "")) == "TASK_952", "TASK_952 polish task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_951", "TASK_952 polish links TASK_951")
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_952 polish gate passes")
	_assert(String(snapshot.get("status", "")) == "ready_for_real_window_recapture", "TASK_952 is ready for real-window recapture")
	_assert(bool(snapshot.get("manual_review_required", false)), "TASK_952 still requires real visual review")
	_assert(not bool(snapshot.get("manual_review_done", true)), "TASK_952 does not fake manual visual review")
	_assert(_snapshot_is_read_only(snapshot), "TASK_952 polish remains read-only")
	var badges: Array = Array(snapshot.get("visual_badges", []))
	_assert(badges.size() == 3, "Polish exposes three compact badges")
	_assert(_badge_at(badges, 0, "safe", "green", "OK"), "First badge is safe/green")
	_assert(_badge_at(badges, 1, "risky", "yellow", "!"), "Second badge is risky/yellow")
	_assert(_badge_at(badges, 2, "suicidal", "red", "!!"), "Third badge is suicidal/red")
	for badge_variant in badges:
		var badge: Dictionary = Dictionary(badge_variant)
		_assert(not _contains_raw_choice_id(String(badge.get("label", ""))), "Badge label hides raw ids")
		_assert(not _contains_raw_choice_id(String(badge.get("microcopy", ""))), "Badge microcopy hides raw ids")
	var layout: Dictionary = Dictionary(snapshot.get("layout_contract", {}))
	_assert(String(layout.get("density", "")) == "compact", "Layout contract stays compact")
	_assert(int(layout.get("max_line_count", 0)) == 1, "Layout uses one Mission Control line")
	_assert(not bool(layout.get("rebuilds_ui_tree", true)), "Layout contract does not rebuild UI tree")
	var line: String = String(snapshot.get("mission_control_choice_line", ""))
	_assert(line.length() <= 96 and line.contains("SAFE") and line.contains("SUICIDAL"), "Polished choice line stays short and informative")
	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(String(Dictionary(feedback.get("decision_overlay_f6_visual_polish", {})).get("schema", "")) == SCHEMA, "Command feedback embeds TASK_952 polish")
	_assert(String(feedback.get("decision_overlay_f6_visual_polish_gate", "")) == "pass", "Command feedback exports TASK_952 gate")
	controller.queue_free()


func _badge_at(badges: Array, index: int, expected_risk: String, expected_color: String, expected_marker: String) -> bool:
	if index < 0 or index >= badges.size():
		return false
	var badge: Dictionary = Dictionary(badges[index])
	return String(badge.get("risk_state", "")) == expected_risk \
		and String(badge.get("color_key", "")) == expected_color \
		and String(badge.get("marker", "")) == expected_marker \
		and not String(badge.get("label", "")).strip_edges().is_empty() \
		and not String(badge.get("microcopy", "")).strip_edges().is_empty()


func _contains_raw_choice_id(text: String) -> bool:
	return text.contains("covered_push") or text.contains("exposed_crossing") or text.contains("kill_zone_dash")


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_movement", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true)) \
		and not bool(snapshot.get("sets_multiplayer_truth", true))


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
