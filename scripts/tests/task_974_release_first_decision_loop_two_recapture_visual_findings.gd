extends SceneTree

const Findings := preload("res://scripts/mission/release_first_decision_loop_two_recapture_visual_findings.gd")

const TASK_PATH := "res://docs/tasks/TASK_974_release_first_decision_loop_two_recapture_visual_findings.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_recapture_visual_findings.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_recapture_visual_findings_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_recapture_visual_findings.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_real_window_recapture.v1"
const NEXT_POLISH_TASK := "TASK_975 - Release First Decision Loop Two Recapture Visual Polish"
const NEXT_ACCEPTANCE_TASK := "TASK_975 - Release First Decision Loop Two Acceptance Slice"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_974 Release First Decision Loop Two Recapture Visual Findings ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_review_ready_source_without_notes_needs_manual_review()
	_test_manual_issues_route_to_polish()
	_test_clean_review_accepts_next_acceptance_slice()
	_test_findings_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_974_release_first_decision_loop_two_recapture_visual_findings: FAILED")
		quit(1)
		return
	print("TASK_974_release_first_decision_loop_two_recapture_visual_findings: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_974 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_974 findings analyzer exists")
	_assert(task_text.contains("TASK_974 - Release First Decision Loop Two Recapture Visual Findings"), "Task names TASK_974")
	_assert(task_text.contains(NEXT_POLISH_TASK), "Task names polish follow-up")
	_assert(task_text.contains(NEXT_ACCEPTANCE_TASK), "Task names acceptance follow-up")
	_assert(status_text.contains("TASK_974 - Release First Decision Loop Two Recapture Visual Findings"), "Implementation status tracks TASK_974")
	_assert(roadmap_text.contains("TASK_974 - Release First Decision Loop Two Recapture Visual Findings (implementiert"), "Roadmap marks TASK_974 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Recapture Visual Findings (TASK_974)"), "Mission feedback contract documents TASK_974")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Recapture Visual Findings (TASK_974)"), "Decision clarity contract documents TASK_974")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes stable TASK_974 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_974\""), "Analyzer writes TASK_974 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_973\""), "Analyzer links TASK_973")
	_assert(service_text.contains(NEXT_POLISH_TASK), "Analyzer declares polish next task")
	_assert(service_text.contains(NEXT_ACCEPTANCE_TASK), "Analyzer declares acceptance next task")
	_assert(service_text.contains("\"read_only\": true"), "Analyzer declares read-only")
	_assert(service_text.contains("\"creates_command\": false"), "Analyzer creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Analyzer creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Analyzer creates no multiplayer truth")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = Findings.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_974")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_review_ready"), "Missing source reports review-ready mismatch")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_review_ready_source_without_notes_needs_manual_review() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_recapture_source(false), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "needs_manual_review", "Good source without notes needs manual review")
	_assert(bool(snapshot.get("manual_review_required", false)), "Manual review remains required")
	_assert(not bool(snapshot.get("manual_review_done", true)), "Manual review is not faked")
	_assert(not bool(snapshot.get("accepted", true)), "Open review is not accepted")
	_assert(issue_ids.has("manual_loop_two_recapture_visual_review_open"), "Open review is primary issue")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_974 - Release First Decision Loop Two Recapture Visual Findings", "Open review loops on TASK_974")
	_assert(_snapshot_is_read_only(snapshot), "Manual-review snapshot remains read-only")


func _test_manual_issues_route_to_polish() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_recapture_source(false), _issue_notes())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "ready_for_loop_two_recapture_visual_polish", "Manual issues route to visual polish")
	_assert(bool(snapshot.get("manual_review_done", false)), "Issue snapshot records completed review")
	_assert(not bool(snapshot.get("accepted", true)), "Issue snapshot is not accepted")
	_assert(issue_ids.has("loop_two_smoke_line_not_visible"), "Issue snapshot names missing smoke line")
	_assert(issue_ids.has("post_go_feedback_not_visible"), "Issue snapshot names missing post-GO feedback")
	_assert(issue_ids.has("player_readability_not_ok"), "Issue snapshot names player readability")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_POLISH_TASK, "Issue snapshot recommends visual polish")
	_assert(String(snapshot.get("recommended_direction", "")) == "tighten_loop_two_recapture_readability", "Issue snapshot recommends tightening visuals")
	_assert(_snapshot_is_read_only(snapshot), "Issue snapshot remains read-only")


func _test_clean_review_accepts_next_acceptance_slice() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_recapture_source(true), _clean_notes())
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_974")
	_assert(String(snapshot.get("task_id", "")) == "TASK_974", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_973", "Snapshot links TASK_973")
	_assert(String(snapshot.get("source_schema", "")) == SOURCE_SCHEMA, "Snapshot records TASK_973 schema")
	_assert(String(snapshot.get("status", "")) == "accepted_for_loop_two_acceptance_slice", "Clean review accepts acceptance slice")
	_assert(bool(snapshot.get("accepted", false)), "Clean snapshot is accepted")
	_assert(int(snapshot.get("issue_count", -1)) == 0, "Clean snapshot has no issues")
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Clean snapshot has no blockers")
	_assert(int(snapshot.get("positive_finding_count", -1)) >= 9, "Clean snapshot records positive findings")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_ACCEPTANCE_TASK, "Clean snapshot recommends acceptance slice")
	_assert(String(snapshot.get("recommended_direction", "")) == "build_loop_two_acceptance_slice", "Clean snapshot recommends acceptance direction")
	_assert(_snapshot_is_read_only(snapshot), "Accepted snapshot remains read-only")


func _test_findings_roundtrip() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_recapture_source(true), _clean_notes())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_974 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_974", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_973", "Roundtrip keeps TASK_973 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_ACCEPTANCE_TASK, "Roundtrip keeps acceptance task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _recapture_source(accepted: bool) -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_973",
		"source_task_id": "TASK_972",
		"source_schema": "sternenbuergerchen.release_first_decision_loop_two_playability_smoke.v1",
		"source_gate": "loop_two_playability_smoke_passed",
		"source_status": "loop_two_playability_smoke_passed",
		"source_smoke_line": "2ND -> GO -> Feedback PASS | 2ND HOLD -> Defend vorbereiten | danach GO separat",
		"source_post_go_feedback_line": "Feedback: zweiter Griff vorbereitet, GO ausgefuehrt.",
		"source_playability_smoke_passed": true,
		"status": "accepted" if accepted else "review_ready",
		"gate": "real_window_recapture_accepted" if accepted else "real_window_recapture_review_ready",
		"review_ready": true,
		"accepted": accepted,
		"window_capture_trusted": true,
		"window_screenshot_written": true,
		"desktop_screenshot_written": true,
		"window_screenshot_path": "tmp/release_first_decision_loop_two_real_window_recapture.png",
		"desktop_screenshot_path": "tmp/release_first_decision_loop_two_real_window_recapture_desktop.png",
		"missing_manual_check_count": 0 if accepted else 13,
		"read_only": true,
		"read_only_capture": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
	}


func _clean_notes() -> Dictionary:
	return {
		"manual_visual_review_done": true,
		"correct_window_content_confirmed": true,
		"second_decision_button_visible": true,
		"second_decision_confirmed": true,
		"go_button_still_separate": true,
		"go_executed_after_confirm": true,
		"post_go_feedback_visible": true,
		"loop_two_smoke_line_visible": true,
		"no_new_hud_gameplay_truth": true,
		"multiplayer_boundary_preserved": true,
		"player_readability_ok": true,
	}


func _issue_notes() -> Dictionary:
	var notes: Dictionary = _clean_notes()
	notes["post_go_feedback_visible"] = false
	notes["loop_two_smoke_line_visible"] = false
	notes["player_readability_ok"] = false
	return notes


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
