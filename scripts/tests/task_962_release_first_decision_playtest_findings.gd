extends SceneTree

const Findings := preload("res://scripts/mission/release_first_decision_playtest_findings.gd")

const TASK_PATH := "res://docs/tasks/TASK_962_release_first_decision_playtest_findings.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_playtest_findings.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_playtest_findings_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_playtest_findings.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_integrated_playtest.v1"
const NEXT_POLISH_TASK := "TASK_963 - Release First Decision Integrated Polish Followup"
const NEXT_LOOP_TASK := "TASK_963 - Release First Decision Next Playable Loop"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_962 Release First Decision Playtest Findings ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_passed_source_needs_manual_review()
	_test_source_regression_routes_to_polish_followup()
	_test_clean_manual_review_accepts_next_loop()
	_test_findings_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_962_release_first_decision_playtest_findings: FAILED")
		quit(1)
		return
	print("TASK_962_release_first_decision_playtest_findings: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_962 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_962 findings analyzer exists")
	_assert(task_text.contains("TASK_962 - Release First Decision Playtest Findings"), "Task names TASK_962")
	_assert(task_text.contains(NEXT_POLISH_TASK), "Task names polish follow-up")
	_assert(task_text.contains(NEXT_LOOP_TASK), "Task names next playable loop")
	_assert(status_text.contains("TASK_962 - Release First Decision Playtest Findings"), "Implementation status tracks TASK_962")
	_assert(roadmap_text.contains("TASK_962 - Release First Decision Playtest Findings (implementiert"), "Roadmap marks TASK_962 implemented")
	_assert(command_contract_text.contains("Release First Decision Playtest Findings (TASK_962)"), "Mission feedback contract documents TASK_962")
	_assert(clarity_contract_text.contains("Release First Decision Playtest Findings (TASK_962)"), "Decision clarity contract documents TASK_962")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes stable TASK_962 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_962\""), "Analyzer writes TASK_962 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_961\""), "Analyzer links TASK_961")
	_assert(service_text.contains("NEXT_POLISH_TASK"), "Analyzer declares polish next task")
	_assert(service_text.contains("NEXT_LOOP_TASK"), "Analyzer declares loop next task")
	_assert(service_text.contains("\"read_only\": true"), "Analyzer declares read-only")
	_assert(service_text.contains("\"ui_sets_gameplay_truth\": false"), "Analyzer creates no UI gameplay truth")
	_assert(service_text.contains("\"creates_command\": false"), "Analyzer creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Analyzer creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Analyzer creates no multiplayer truth")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = Findings.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_962")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_playtest_not_reviewable"), "Missing source reports reviewable mismatch")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_passed_source_needs_manual_review() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_passed_source(), {})
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_962")
	_assert(String(snapshot.get("task_id", "")) == "TASK_962", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_961", "Snapshot links TASK_961")
	_assert(String(snapshot.get("status", "")) == "needs_manual_review", "Passed source without notes needs manual review")
	_assert(bool(snapshot.get("manual_review_required", false)), "Manual review remains required")
	_assert(not bool(snapshot.get("manual_review_done", true)), "Manual review is not faked")
	_assert(not bool(snapshot.get("accepted", true)), "Open review is not accepted")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_962 - Release First Decision Playtest Findings", "Open review loops on TASK_962")
	_assert(String(snapshot.get("primary_issue_id", "")) == "manual_playtest_review_open", "Open review is primary issue")
	_assert(_snapshot_is_read_only(snapshot), "Manual-review snapshot remains read-only")


func _test_source_regression_routes_to_polish_followup() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_regression_source(), _accepted_notes())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "ready_for_release_first_decision_polish", "Source regression routes to polish")
	_assert(bool(snapshot.get("manual_review_done", false)), "Regression findings record completed review")
	_assert(not bool(snapshot.get("accepted", true)), "Regression findings are not accepted")
	_assert(issue_ids.has("source_integrated_playtest_regression"), "Findings keep source regression visible")
	_assert(issue_ids.has("post_go_feedback_missing"), "Findings preserve source issue ids")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_POLISH_TASK, "Regression recommends polish follow-up")
	_assert(String(snapshot.get("recommended_direction", "")) == "tighten_release_first_decision_integrated_playtest", "Regression recommends targeted polish")
	_assert(_snapshot_is_read_only(snapshot), "Regression findings remain read-only")


func _test_clean_manual_review_accepts_next_loop() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_passed_source(), _accepted_notes())
	_assert(String(snapshot.get("status", "")) == "accepted_for_release_first_decision_next_loop", "Clean review accepts next loop")
	_assert(bool(snapshot.get("manual_review_done", false)), "Accepted snapshot records completed review")
	_assert(bool(snapshot.get("accepted", false)), "Clean snapshot is accepted")
	_assert(int(snapshot.get("issue_count", -1)) == 0, "Clean snapshot has no issues")
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Clean snapshot has no blockers")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_LOOP_TASK, "Clean snapshot recommends next playable loop")
	_assert(String(snapshot.get("recommended_direction", "")) == "build_next_small_playable_loop", "Clean snapshot recommends next loop direction")
	_assert(_snapshot_is_read_only(snapshot), "Accepted snapshot remains read-only")


func _test_findings_roundtrip() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_passed_source(), _accepted_notes())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_962 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_962", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_961", "Roundtrip keeps TASK_961 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_LOOP_TASK, "Roundtrip keeps next-loop task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _passed_source() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_961",
		"source_task_id": "TASK_960",
		"source_gate": "release_slice_playable",
		"gate": "integrated_playtest_passed",
		"integrated_playtest_passed": true,
		"manifest_available": true,
		"missing_playtest_check_count": 0,
		"issue_count": 0,
		"observed_release_stages": [
			"release_launch",
			"homebase_to_mission",
			"dropship_lz_drop",
			"first_decision_preview",
			"go_and_post_go_feedback",
		],
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


func _regression_source() -> Dictionary:
	var source: Dictionary = _passed_source()
	source["gate"] = "integrated_playtest_regression_found"
	source["integrated_playtest_passed"] = false
	source["issue_count"] = 1
	source["issues"] = [
		{"id": "post_go_feedback_missing", "text": "Post-GO-Feedback wurde nicht beobachtet."},
	]
	return source


func _accepted_notes() -> Dictionary:
	return {
		"manual_playtest_review_done": true,
		"correct_window_content_confirmed": true,
		"homebase_to_mission_readable": true,
		"dropship_lz_drop_readable": true,
		"first_decision_preview_readable": true,
		"go_and_post_go_feedback_readable": true,
		"performance_ok": true,
		"no_new_hud_gameplay_truth": true,
		"multiplayer_boundary_ok": true,
		"player_readability_ok": true,
	}


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
