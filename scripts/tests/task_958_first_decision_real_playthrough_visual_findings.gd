extends SceneTree

const Findings := preload("res://scripts/mission/first_decision_real_playthrough_visual_findings.gd")

const TASK_PATH := "res://docs/tasks/TASK_958_first_decision_real_playthrough_visual_findings.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/first_decision_real_playthrough_visual_findings.gd"
const OUTPUT_PATH := "res://tmp/first_decision_real_playthrough_visual_findings_acceptance.json"
const SCHEMA := "sternenbuergerchen.first_decision_real_playthrough_visual_findings.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.first_decision_real_playthrough_capture.v1"
const SOURCE_MICRO_SCHEMA := "sternenbuergerchen.first_decision_micro_scenario_polish.v1"
const NEXT_POLISH_TASK := "TASK_959 - First Decision Real Playthrough Polish Followup"
const NEXT_SMOKE_TASK := "TASK_959 - First Decision Playability Smoke"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_958 First Decision Real Playthrough Visual Findings ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_good_source_needs_manual_review()
	_test_manual_issues_route_to_polish_followup()
	_test_clean_manual_review_accepts_for_first_decision_smoke()
	_test_findings_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_958_first_decision_real_playthrough_visual_findings: FAILED")
		quit(1)
		return
	print("TASK_958_first_decision_real_playthrough_visual_findings: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_958 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_958 findings analyzer exists")
	_assert(task_text.contains("TASK_958 - First Decision Real Playthrough Visual Findings"), "Task names TASK_958")
	_assert(task_text.contains(NEXT_POLISH_TASK), "Task names polish follow-up")
	_assert(task_text.contains(NEXT_SMOKE_TASK), "Task names playability smoke")
	_assert(status_text.contains("TASK_958 - First Decision Real Playthrough Visual Findings"), "Implementation status tracks TASK_958")
	_assert(roadmap_text.contains("TASK_958 - First Decision Real Playthrough Visual Findings (implementiert"), "Roadmap marks TASK_958 implemented")
	_assert(command_contract_text.contains("First Decision Real Playthrough Visual Findings (TASK_958)"), "Mission feedback contract documents TASK_958")
	_assert(clarity_contract_text.contains("First Decision Real Playthrough Visual Findings (TASK_958)"), "Decision clarity contract documents TASK_958")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes stable TASK_958 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_958\""), "Analyzer writes TASK_958 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_957\""), "Analyzer links TASK_957")
	_assert(service_text.contains("SOURCE_MICRO_TASK_ID: String = \"TASK_956\""), "Analyzer links TASK_956 micro source")
	_assert(service_text.contains("NEXT_POLISH_TASK"), "Analyzer declares polish next task")
	_assert(service_text.contains("NEXT_SMOKE_TASK"), "Analyzer declares smoke next task")
	_assert(service_text.contains("\"read_only\": true"), "Analyzer declares read-only")
	_assert(service_text.contains("\"ui_sets_gameplay_truth\": false"), "Analyzer creates no UI gameplay truth")
	_assert(service_text.contains("\"creates_command\": false"), "Analyzer creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Analyzer creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Analyzer creates no multiplayer truth")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = Findings.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_958")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_review_ready"), "Missing source reports review-ready mismatch")
	_assert(blocker_ids.has("source_micro_task_mismatch"), "Missing source reports TASK_956 mismatch")
	_assert(blocker_ids.has("source_micro_schema_mismatch"), "Missing source reports TASK_956 schema mismatch")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_good_source_needs_manual_review() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_good_source(false), {})
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_958")
	_assert(String(snapshot.get("task_id", "")) == "TASK_958", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_957", "Snapshot links TASK_957")
	_assert(String(snapshot.get("source_micro_task_id", "")) == "TASK_956", "Snapshot links TASK_956")
	_assert(String(snapshot.get("status", "")) == "needs_manual_review", "Good source without notes needs manual review")
	_assert(bool(snapshot.get("manual_review_required", false)), "Manual review remains required")
	_assert(not bool(snapshot.get("manual_review_done", true)), "Manual review is not faked")
	_assert(not bool(snapshot.get("accepted", true)), "Open review is not accepted")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_958 - First Decision Real Playthrough Visual Findings", "Open review loops on TASK_958")
	_assert(String(snapshot.get("primary_issue_id", "")) == "manual_visual_review_open", "Open review is primary issue")
	_assert(_snapshot_is_read_only(snapshot), "Manual-review snapshot remains read-only")


func _test_manual_issues_route_to_polish_followup() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_good_source(false), _issue_notes())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "ready_for_first_decision_visual_polish", "Manual issues route to polish")
	_assert(bool(snapshot.get("manual_review_done", false)), "Manual issue snapshot records completed review")
	_assert(not bool(snapshot.get("accepted", true)), "Issue snapshot is not accepted")
	_assert(issue_ids.has("next_line_not_visible"), "Issue snapshot names missing NEXT line")
	_assert(issue_ids.has("preview_boundary_unclear"), "Issue snapshot names unclear preview boundary")
	_assert(issue_ids.has("recommendation_not_obvious"), "Issue snapshot names weak recommendation")
	_assert(String(snapshot.get("primary_issue_id", "")) == "next_line_not_visible", "Primary issue is first visual finding")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_POLISH_TASK, "Issue snapshot recommends polish follow-up")
	_assert(String(snapshot.get("recommended_direction", "")) == "tighten_first_decision_window_readability_before_smoke", "Issue snapshot recommends tightening visuals")
	_assert(_snapshot_is_read_only(snapshot), "Issue snapshot remains read-only")


func _test_clean_manual_review_accepts_for_first_decision_smoke() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_good_source(true), _accepted_notes())
	_assert(String(snapshot.get("status", "")) == "accepted_for_first_decision_playability_smoke", "Clean manual review accepts for smoke")
	_assert(bool(snapshot.get("manual_review_done", false)), "Accepted snapshot records completed review")
	_assert(bool(snapshot.get("accepted", false)), "Clean snapshot is accepted")
	_assert(int(snapshot.get("issue_count", -1)) == 0, "Clean snapshot has no issues")
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Clean snapshot has no blockers")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_SMOKE_TASK, "Clean snapshot recommends playability smoke")
	_assert(String(snapshot.get("recommended_direction", "")) == "run_first_decision_playability_smoke", "Clean snapshot recommends smoke direction")
	_assert(_snapshot_is_read_only(snapshot), "Accepted snapshot remains read-only")


func _test_findings_roundtrip() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_good_source(true), _accepted_notes())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_958 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_958", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_957", "Roundtrip keeps TASK_957 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_SMOKE_TASK, "Roundtrip keeps smoke next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _good_source(accepted: bool) -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_957",
		"source_task_id": "TASK_956",
		"source_schema": SOURCE_MICRO_SCHEMA,
		"source_gate": "pass",
		"source_status": "ready_for_first_decision_micro_scenario",
		"status": "accepted" if accepted else "review_ready",
		"review_ready": true,
		"accepted": accepted,
		"branch": "task/release-first-exchange-player-readability-polish-review",
		"git_head": "test",
		"launch_argument": "--release-singleplayer-lz-drop-preview",
		"window_capture_method": "window_handle_print",
		"window_capture_trusted": true,
		"window_screenshot_written": true,
		"desktop_screenshot_written": true,
		"window_screenshot_path": "tmp/first_decision_real_playthrough_capture.png",
		"desktop_screenshot_path": "tmp/first_decision_real_playthrough_capture_desktop.png",
		"source_micro_scenario_snapshot": {
			"schema": SOURCE_MICRO_SCHEMA,
			"task_id": "TASK_956",
			"source_task_id": "TASK_955",
			"gate": "pass",
			"status": "ready_for_first_decision_micro_scenario",
			"primary_cue_line": "NEXT Gedeckt pruefen -> GO",
			"why_line": "WHY Deckung ok, 0 Feindlinie",
			"choice_row_count": 3,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"creates_command": false,
			"creates_movement": false,
			"sets_multiplayer_truth": false,
		},
		"manual_review_required": true,
		"manual_review_done": accepted,
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


func _accepted_notes() -> Dictionary:
	return {
		"manual_visual_review_done": true,
		"correct_window_content_confirmed": true,
		"next_line_visible": true,
		"why_line_visible": true,
		"choice_rows_visible": true,
		"recommendation_obvious": true,
		"preview_boundary_clear": true,
		"go_surface_usable": true,
		"no_command_before_go_confirmed": true,
		"no_new_hud_gameplay_truth": true,
		"player_readability_ok": true,
	}


func _issue_notes() -> Dictionary:
	return {
		"manual_visual_review_done": true,
		"correct_window_content_confirmed": true,
		"next_line_visible": false,
		"why_line_visible": true,
		"choice_rows_visible": true,
		"recommendation_obvious": false,
		"preview_boundary_clear": false,
		"go_surface_usable": true,
		"no_command_before_go_confirmed": true,
		"no_new_hud_gameplay_truth": true,
		"player_readability_ok": false,
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
