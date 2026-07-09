extends SceneTree

const Smoke := preload("res://scripts/mission/first_decision_playability_smoke.gd")

const TASK_PATH := "res://docs/tasks/TASK_959_first_decision_playability_smoke.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/first_decision_playability_smoke.gd"
const OUTPUT_PATH := "res://tmp/first_decision_playability_smoke_acceptance.json"
const SCHEMA := "sternenbuergerchen.first_decision_playability_smoke.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.first_decision_real_playthrough_visual_findings.v1"
const NEXT_TASK := "TASK_960 - First Decision Release Playable Slice"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_959 First Decision Playability Smoke ===")
	_test_docs_and_static_hooks()
	_test_missing_findings_blocks()
	_test_unaccepted_findings_blocks_smoke()
	_test_accepted_findings_without_trace_needs_smoke_run()
	_test_complete_trace_passes_first_decision_smoke()
	_test_regression_flags_route_to_playable_slice()
	_test_smoke_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_959_first_decision_playability_smoke: FAILED")
		quit(1)
		return
	print("TASK_959_first_decision_playability_smoke: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_959 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_959 smoke service exists")
	_assert(task_text.contains("TASK_959 - First Decision Playability Smoke"), "Task names TASK_959")
	_assert(task_text.contains(NEXT_TASK), "Task names TASK_960 follow-up")
	_assert(status_text.contains("TASK_959 - First Decision Playability Smoke"), "Implementation status tracks TASK_959")
	_assert(roadmap_text.contains("TASK_959 - First Decision Playability Smoke (implementiert"), "Roadmap marks TASK_959 implemented")
	_assert(command_contract_text.contains("First Decision Playability Smoke (TASK_959)"), "Mission feedback contract documents TASK_959")
	_assert(clarity_contract_text.contains("First Decision Playability Smoke (TASK_959)"), "Decision clarity contract documents TASK_959")
	_assert(service_text.contains(SCHEMA), "Smoke service exposes stable TASK_959 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_959\""), "Smoke service writes TASK_959 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_958\""), "Smoke service links TASK_958")
	_assert(service_text.contains("REQUIRED_SMOKE_CHECKS"), "Smoke service declares required checks")
	_assert(service_text.contains("\"read_only\": true"), "Smoke service declares read-only")
	_assert(service_text.contains("\"ui_sets_gameplay_truth\": false"), "Smoke service creates no UI gameplay truth")
	_assert(service_text.contains("\"creates_command\": false"), "Smoke service creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Smoke service creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Smoke service creates no multiplayer truth")


func _test_missing_findings_blocks() -> void:
	var snapshot: Dictionary = Smoke.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("gate", "")) == "blocked", "Missing findings blocks smoke")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_accepted_for_smoke"), "Missing source reports not accepted")
	_assert(_snapshot_is_read_only(snapshot), "Blocked smoke snapshot remains read-only")


func _test_unaccepted_findings_blocks_smoke() -> void:
	var source: Dictionary = _accepted_findings()
	source["status"] = "ready_for_first_decision_visual_polish"
	source["accepted"] = false
	var snapshot: Dictionary = Smoke.build_snapshot(source, _passing_trace())
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("gate", "")) == "blocked", "Unaccepted findings block smoke")
	_assert(blocker_ids.has("source_not_accepted_for_smoke"), "Unaccepted source reports smoke acceptance blocker")
	_assert(not bool(snapshot.get("smoke_passed", true)), "Blocked smoke does not pass")


func _test_accepted_findings_without_trace_needs_smoke_run() -> void:
	var snapshot: Dictionary = Smoke.build_snapshot(_accepted_findings(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("gate", "")) == "needs_smoke_run", "Accepted findings without trace needs smoke run")
	_assert(issue_ids.has("smoke_trace_missing"), "Missing trace is named")
	_assert(int(snapshot.get("missing_smoke_check_count", -1)) == Smoke.REQUIRED_SMOKE_CHECKS.size(), "All smoke checks remain missing")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_959 - First Decision Playability Smoke", "Missing trace loops on TASK_959")
	_assert(_snapshot_is_read_only(snapshot), "Needs-run smoke snapshot remains read-only")


func _test_complete_trace_passes_first_decision_smoke() -> void:
	var snapshot: Dictionary = Smoke.build_snapshot(_accepted_findings(), _passing_trace())
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Smoke snapshot schema matches")
	_assert(String(snapshot.get("task_id", "")) == "TASK_959", "Smoke snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_958", "Smoke snapshot links TASK_958")
	_assert(String(snapshot.get("gate", "")) == "smoke_passed", "Complete trace passes smoke")
	_assert(bool(snapshot.get("smoke_passed", false)), "Smoke passed flag is set")
	_assert(int(snapshot.get("missing_smoke_check_count", -1)) == 0, "No smoke checks missing")
	_assert(int(snapshot.get("issue_count", -1)) == 0, "Passing smoke has no issues")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Passing smoke recommends TASK_960")
	_assert(String(snapshot.get("recommended_direction", "")) == "stitch_first_decision_into_release_playable_slice", "Passing smoke recommends playable slice")
	_assert(_answered_questions_complete(Array(snapshot.get("answered_player_questions", []))), "Passing smoke answers player questions")
	_assert(_snapshot_is_read_only(snapshot), "Passing smoke snapshot remains read-only")


func _test_regression_flags_route_to_playable_slice() -> void:
	var trace: Dictionary = _passing_trace()
	trace["preview_boundary_clear"] = false
	trace["post_go_feedback_visible"] = false
	var snapshot: Dictionary = Smoke.build_snapshot(_accepted_findings(), trace)
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("gate", "")) == "smoke_regression_found", "Trace regressions fail smoke")
	_assert(issue_ids.has("preview_boundary_unclear"), "Smoke names preview boundary regression")
	_assert(issue_ids.has("post_go_feedback_missing"), "Smoke names missing post-GO feedback")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Regressions still recommend TASK_960")
	_assert(not bool(snapshot.get("smoke_passed", true)), "Regression smoke does not pass")


func _test_smoke_roundtrip() -> void:
	var snapshot: Dictionary = Smoke.build_snapshot(_accepted_findings(), _passing_trace())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_959 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_959", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_958", "Roundtrip keeps TASK_958 link")
	_assert(String(roundtrip.get("gate", "")) == "smoke_passed", "Roundtrip keeps smoke gate")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _accepted_findings() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_958",
		"source_task_id": "TASK_957",
		"source_micro_task_id": "TASK_956",
		"source_status": "accepted",
		"manual_review_required": true,
		"manual_review_done": true,
		"accepted": true,
		"status": "accepted_for_first_decision_playability_smoke",
		"recommended_next_task": "TASK_959 - First Decision Playability Smoke",
		"window_screenshot_path": "tmp/first_decision_real_playthrough_capture.png",
		"positive_findings": [
			{"id": "next_line_visible"},
			{"id": "why_line_visible"},
			{"id": "choice_rows_visible"},
			{"id": "preview_boundary_clear"},
			{"id": "go_surface_usable"},
			{"id": "player_readability_ok"},
		],
		"issues": [],
		"blocking_issues": [],
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


func _passing_trace() -> Dictionary:
	return {
		"trace_available": true,
		"decision_surface": "release_singleplayer_mission_hud",
		"fireteam_id": "FT1",
		"choice_count": 3,
		"recommended_choice_id": "covered_push",
		"next_line_visible": true,
		"why_line_visible": true,
		"choice_rows_visible": true,
		"recommendation_obvious": true,
		"destination_preview_visible": true,
		"path_preview_visible": true,
		"risk_levels_visible": true,
		"line_of_fire_reasons_visible": true,
		"preview_boundary_clear": true,
		"no_command_before_go": true,
		"go_surface_usable": true,
		"go_can_be_confirmed": true,
		"post_go_feedback_visible": true,
		"performance_hotpath_ok": true,
		"no_new_hud_gameplay_truth": true,
	}


func _answered_questions_complete(questions: Array) -> bool:
	return questions.has("what_should_i_do_next") \
		and questions.has("why_is_that_choice_good") \
		and questions.has("where_will_the_fireteam_go") \
		and questions.has("what_changes_only_after_go")


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
