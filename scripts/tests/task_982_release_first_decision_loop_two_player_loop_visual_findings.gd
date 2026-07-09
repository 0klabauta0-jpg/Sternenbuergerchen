extends SceneTree

const VisualFindings := preload("res://scripts/mission/release_first_decision_loop_two_player_loop_visual_findings.gd")

const TASK_PATH := "res://docs/tasks/TASK_982_release_first_decision_loop_two_player_loop_visual_findings.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_visual_findings.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_visual_findings_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_visual_findings.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_real_window_capture.v1"
const NEXT_POLISH_TASK := "TASK_983 - Release First Decision Loop Two Player Loop Visual Polish"
const NEXT_ACCEPTANCE_TASK := "TASK_983 - Release First Decision Loop Two Player Loop Acceptance Slice"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_982 Release First Decision Loop Two Player Loop Visual Findings ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_review_ready_without_notes_needs_manual_review()
	_test_issue_notes_route_to_polish()
	_test_clean_notes_accept_for_acceptance_slice()
	_test_visual_findings_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_982_release_first_decision_loop_two_player_loop_visual_findings: FAILED")
		quit(1)
		return
	print("TASK_982_release_first_decision_loop_two_player_loop_visual_findings: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_982 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_982 visual findings service exists")
	_assert(task_text.contains("TASK_982 - Release First Decision Loop Two Player Loop Visual Findings"), "Task names TASK_982")
	_assert(task_text.contains(NEXT_POLISH_TASK), "Task names visual polish follow-up")
	_assert(task_text.contains(NEXT_ACCEPTANCE_TASK), "Task names acceptance follow-up")
	_assert(status_text.contains("TASK_982 - Release First Decision Loop Two Player Loop Visual Findings"), "Implementation status tracks TASK_982")
	_assert(roadmap_text.contains("TASK_982 - Release First Decision Loop Two Player Loop Visual Findings (implementiert"), "Roadmap marks TASK_982 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Visual Findings (TASK_982)"), "Mission feedback contract documents TASK_982")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Visual Findings (TASK_982)"), "Decision clarity contract documents TASK_982")
	_assert(service_text.contains(SCHEMA), "Visual findings service exposes stable TASK_982 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_982\""), "Visual findings service writes TASK_982 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_981\""), "Visual findings service links TASK_981")
	_assert(service_text.contains("runtime_choice_buttons_visible"), "Visual findings service checks choice visibility")
	_assert(service_text.contains("choice_confirm_feedback_visible"), "Visual findings service checks confirm feedback")
	_assert(service_text.contains("multiplayer_boundary_preserved"), "Visual findings service checks multiplayer boundary")
	_assert(service_text.contains("\"creates_command\": false"), "Visual findings service creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Visual findings service creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Visual findings service creates no multiplayer truth")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = VisualFindings.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_982")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_review_ready"), "Missing source reports not review-ready")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_review_ready_without_notes_needs_manual_review() -> void:
	var snapshot: Dictionary = VisualFindings.build_snapshot(_review_ready_source(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "needs_manual_review", "Review-ready source without notes needs manual review")
	_assert(issue_ids.has("manual_player_loop_visual_review_open"), "Manual review issue is named")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_982 - Release First Decision Loop Two Player Loop Visual Findings", "Open review loops on TASK_982")
	_assert(String(snapshot.get("recommended_direction", "")) == "complete_manual_player_loop_window_review", "Open review recommends manual review")
	_assert(_snapshot_is_read_only(snapshot), "Needs-review snapshot remains read-only")


func _test_issue_notes_route_to_polish() -> void:
	var notes: Dictionary = _clean_review_notes()
	notes["runtime_choice_buttons_readable"] = false
	notes["choice_confirm_feedback_visible"] = false
	notes["player_readability_ok"] = false
	var snapshot: Dictionary = VisualFindings.build_snapshot(_review_ready_source(), notes)
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "ready_for_player_loop_visual_polish", "Issue notes route to polish")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_POLISH_TASK, "Issue notes recommend visual polish")
	_assert(issue_ids.has("runtime_choice_buttons_not_readable"), "Unclear choice buttons are named")
	_assert(issue_ids.has("choice_confirm_feedback_not_visible"), "Missing confirm feedback is named")
	_assert(issue_ids.has("player_readability_not_ok"), "Weak player readability is named")
	_assert(int(snapshot.get("positive_finding_count", 0)) > 0, "Mixed review keeps positive findings")
	_assert(not bool(snapshot.get("accepted", true)), "Issue notes are not accepted")
	_assert(_snapshot_is_read_only(snapshot), "Issue snapshot remains read-only")


func _test_clean_notes_accept_for_acceptance_slice() -> void:
	var snapshot: Dictionary = VisualFindings.build_snapshot(_review_ready_source(), _clean_review_notes())
	_assert(String(snapshot.get("status", "")) == "accepted_for_player_loop_acceptance_slice", "Clean notes accept TASK_982")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_ACCEPTANCE_TASK, "Clean notes recommend acceptance slice")
	_assert(bool(snapshot.get("accepted", false)), "Clean notes set accepted")
	_assert(int(snapshot.get("issue_count", -1)) == 0, "Clean notes have no issues")
	_assert(int(snapshot.get("positive_finding_count", 0)) >= 10, "Clean notes produce positive findings")
	_assert(_snapshot_is_read_only(snapshot), "Accepted snapshot remains read-only")


func _test_visual_findings_roundtrip() -> void:
	var snapshot: Dictionary = VisualFindings.build_snapshot(_review_ready_source(), _clean_review_notes())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_982 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_982", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_981", "Roundtrip keeps TASK_981 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_ACCEPTANCE_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _review_ready_source() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_981",
		"source_task_id": "TASK_980",
		"source_schema": "sternenbuergerchen.release_first_decision_loop_two_player_loop_choice_confirm_smoke.v1",
		"source_gate": "choice_confirm_smoke_passed",
		"source_status": "choice_confirm_smoke_passed",
		"source_selected_choice_id": "secure_area",
		"source_selected_button_text": "SECURE",
		"source_selected_button_slot": "CommandSlot08",
		"source_smoke_line": "CHOICE SECURE -> confirmed | GO separat",
		"source_post_confirm_feedback_line": "SECURE DEFEND -> GO",
		"source_choice_confirm_smoke_passed": true,
		"manifest_available": true,
		"launch_argument": "--release-singleplayer-lz-drop-preview",
		"window_capture_method": "window_handle_print",
		"window_capture_trusted": true,
		"window_screenshot_written": true,
		"desktop_screenshot_written": true,
		"window_screenshot_path": "tmp/release_first_decision_loop_two_player_loop_real_window_capture.png",
		"desktop_screenshot_path": "tmp/release_first_decision_loop_two_player_loop_real_window_capture_desktop.png",
		"review_ready": true,
		"accepted": false,
		"status": "review_ready",
		"gate": "real_window_capture_review_ready",
		"missing_manual_check_count": 14,
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


func _clean_review_notes() -> Dictionary:
	return {
		"manual_visual_review_done": true,
		"correct_window_content_confirmed": true,
		"runtime_choice_buttons_visible": true,
		"runtime_choice_buttons_readable": true,
		"all_four_choice_tokens_visible": true,
		"choice_confirm_observed": true,
		"choice_confirm_feedback_visible": true,
		"choice_confirm_feedback_readable": true,
		"go_button_still_separate": true,
		"no_go_before_go_confirmed": true,
		"choice_confirm_smoke_line_visible": true,
		"no_new_hud_gameplay_truth": true,
		"multiplayer_boundary_preserved": true,
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
