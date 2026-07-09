extends SceneTree

const Acceptance := preload("res://scripts/mission/release_first_decision_loop_two_acceptance_slice.gd")

const TASK_PATH := "res://docs/tasks/TASK_975_release_first_decision_loop_two_acceptance_slice.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_acceptance_slice.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_acceptance_slice_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_acceptance_slice.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_recapture_visual_findings.v1"
const NEXT_TASK := "TASK_976 - Release First Decision Loop Two Player Loop Extension"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_975 Release First Decision Loop Two Acceptance Slice ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_accepted_findings_without_trace_needs_slice_trace()
	_test_failed_trace_routes_to_visual_polish()
	_test_good_trace_accepts_loop_two_slice()
	_test_acceptance_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_975_release_first_decision_loop_two_acceptance_slice: FAILED")
		quit(1)
		return
	print("TASK_975_release_first_decision_loop_two_acceptance_slice: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_975 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_975 acceptance service exists")
	_assert(task_text.contains("TASK_975 - Release First Decision Loop Two Acceptance Slice"), "Task names TASK_975")
	_assert(task_text.contains(NEXT_TASK), "Task names player-loop follow-up")
	_assert(status_text.contains("TASK_975 - Release First Decision Loop Two Acceptance Slice"), "Implementation status tracks TASK_975")
	_assert(roadmap_text.contains("TASK_975 - Release First Decision Loop Two Acceptance Slice (implementiert"), "Roadmap marks TASK_975 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Acceptance Slice (TASK_975)"), "Mission feedback contract documents TASK_975")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Acceptance Slice (TASK_975)"), "Decision clarity contract documents TASK_975")
	_assert(service_text.contains(SCHEMA), "Acceptance service exposes stable TASK_975 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_975\""), "Acceptance service writes TASK_975 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_974\""), "Acceptance service links TASK_974")
	_assert(service_text.contains("REQUIRED_ACCEPTANCE_CHECKS"), "Acceptance service defines required checks")
	_assert(service_text.contains("\"read_only\": true"), "Acceptance service declares read-only")
	_assert(service_text.contains("\"creates_command\": false"), "Acceptance service creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Acceptance service creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Acceptance service creates no multiplayer truth")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = Acceptance.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_975")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_accepted_for_acceptance_slice"), "Missing source reports acceptance mismatch")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_accepted_findings_without_trace_needs_slice_trace() -> void:
	var snapshot: Dictionary = Acceptance.build_snapshot(_accepted_findings(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "needs_acceptance_slice_trace", "Accepted source without trace needs slice trace")
	_assert(String(snapshot.get("gate", "")) == "needs_loop_two_acceptance_slice_trace", "Missing trace gates acceptance run")
	_assert(issue_ids.has("acceptance_trace_missing"), "Missing acceptance trace issue is named")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_975 - Release First Decision Loop Two Acceptance Slice", "Missing trace loops on TASK_975")
	_assert(_snapshot_is_read_only(snapshot), "Needs-trace snapshot remains read-only")


func _test_failed_trace_routes_to_visual_polish() -> void:
	var snapshot: Dictionary = Acceptance.build_snapshot(_accepted_findings(), _failed_trace())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "loop_two_acceptance_regression_found", "Failed trace reports regression")
	_assert(String(snapshot.get("gate", "")) == "loop_two_acceptance_regression_found", "Failed trace gate names regression")
	_assert(issue_ids.has("post_go_feedback_missing"), "Failed trace names missing feedback")
	_assert(issue_ids.has("player_questions_not_answered"), "Failed trace names unanswered player questions")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_975 - Release First Decision Loop Two Recapture Visual Polish", "Failed trace routes to polish")
	_assert(_snapshot_is_read_only(snapshot), "Failed trace remains read-only")


func _test_good_trace_accepts_loop_two_slice() -> void:
	var snapshot: Dictionary = Acceptance.build_snapshot(_accepted_findings(), _good_trace())
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_975")
	_assert(String(snapshot.get("task_id", "")) == "TASK_975", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_974", "Snapshot links TASK_974")
	_assert(String(snapshot.get("source_schema", "")) == SOURCE_SCHEMA, "Snapshot records TASK_974 schema")
	_assert(String(snapshot.get("status", "")) == "loop_two_acceptance_slice_passed", "Good trace passes acceptance slice")
	_assert(String(snapshot.get("gate", "")) == "loop_two_acceptance_slice_passed", "Good trace gate passes")
	_assert(bool(snapshot.get("acceptance_slice_passed", false)), "Good trace sets pass flag")
	_assert(String(snapshot.get("acceptance_line", "")).contains("2ND"), "Acceptance line names 2ND")
	_assert(String(snapshot.get("acceptance_line", "")).contains("GO"), "Acceptance line names GO")
	_assert(int(snapshot.get("answered_player_question_count", 0)) >= 5, "Acceptance answers player questions")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Good trace recommends player-loop extension")
	_assert(_snapshot_is_read_only(snapshot), "Good trace remains read-only")


func _test_acceptance_roundtrip() -> void:
	var snapshot: Dictionary = Acceptance.build_snapshot(_accepted_findings(), _good_trace())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_975 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_975", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_974", "Roundtrip keeps TASK_974 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _accepted_findings() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_974",
		"source_task_id": "TASK_973",
		"status": "accepted_for_loop_two_acceptance_slice",
		"accepted": true,
		"manual_review_done": true,
		"positive_finding_count": 10,
		"issue_count": 0,
		"blocking_issue_count": 0,
		"source_smoke_line": "2ND -> GO -> Feedback PASS | 2ND HOLD -> Defend vorbereiten | danach GO separat",
		"source_post_go_feedback_line": "Feedback: zweiter Griff vorbereitet, GO ausgefuehrt.",
		"recommended_next_task": "TASK_975 - Release First Decision Loop Two Acceptance Slice",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
	}


func _good_trace() -> Dictionary:
	var checks: Array = [
		"homebase_to_mission_context_preserved",
		"second_decision_button_visible",
		"second_decision_confirmed",
		"go_button_still_separate",
		"go_executed_after_confirm",
		"post_go_feedback_visible",
		"loop_two_smoke_line_visible",
		"player_questions_answered",
		"no_new_hud_gameplay_truth",
		"multiplayer_boundary_preserved",
	]
	return {
		"trace_available": true,
		"completed_checks": checks,
		"homebase_to_mission_context_preserved": true,
		"second_decision_button_visible": true,
		"second_decision_confirmed": true,
		"go_button_still_separate": true,
		"go_executed_after_confirm": true,
		"post_go_feedback_visible": true,
		"loop_two_smoke_line_visible": true,
		"player_questions_answered": true,
		"answered_player_questions": [
			"what_is_the_second_grip",
			"what_does_2nd_prepare",
			"why_is_go_separate",
			"did_go_execute_after_confirm",
			"what_feedback_changed_after_go",
		],
		"no_new_hud_gameplay_truth": true,
		"multiplayer_boundary_preserved": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _failed_trace() -> Dictionary:
	var trace: Dictionary = _good_trace()
	trace["completed_checks"] = ["homebase_to_mission_context_preserved", "second_decision_button_visible", "second_decision_confirmed", "go_button_still_separate"]
	trace["post_go_feedback_visible"] = false
	trace["player_questions_answered"] = false
	trace["answered_player_questions"] = ["what_is_the_second_grip"]
	return trace


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_movement", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true)) \
		and not bool(snapshot.get("sets_multiplayer_truth", true))


func _issue_ids(issues: Array) -> Array:
	var result: Array = []
	for issue_variant in issues:
		if typeof(issue_variant) == TYPE_DICTIONARY:
			result.append(String(Dictionary(issue_variant).get("id", "")))
	return result


func _read_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		return Dictionary(parsed)
	return {}


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
