extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_666_host_client_decision_drill_real_click_findings.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const CURRENT_REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const RECHECK_PATH: String = "res://tmp/host_client_decision_drill_real_click_recheck.json"
const TECHNICAL_GUARD_PATH: String = "res://tmp/host_client_decision_drill_technical_click_guard.json"
const REAL_CAPTURE_PATH: String = "res://tmp/host_client_two_window_real_run_review.json"
const FINDINGS_PATH: String = "res://tmp/host_client_decision_drill_real_click_findings.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_666 Host Client Decision Drill Real Click Findings ===")
	_test_docs_report_and_contract()
	_write_findings_manifest()
	_test_findings_manifest()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_666: FAILED")
		quit(1)
		return
	print("TASK_666: ALL PASSED")
	quit(0)


func _test_docs_report_and_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(CURRENT_REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_666 task file exists")
	_assert(task_text.contains("Host Client Decision Drill Real Click Findings"), "TASK_666 task names real click findings")
	_assert(status_text.contains("TASK_666 - Host Client Decision Drill Real Click Findings"), "Implementation status tracks TASK_666")
	_assert(roadmap_text.contains("TASK_666 - Host Client Decision Drill Real Click Findings (implementiert)"), "Roadmap marks TASK_666 implemented")
	_assert(contract_text.contains("Host-Client-Decision-Drill-Real-Click-Findings"), "Mission feedback contract documents TASK_666")
	_assert(report_text.contains("TASK_666 - Host Client Decision Drill Real Click Findings"), "Current handbook report tracks TASK_666")
	_assert(report_text.contains('data-export-key="host_client_decision_drill_real_click_findings.technical_path_gate"'), "Current handbook exports TASK_666 technical gate")
	_assert(report_text.contains('data-note-key="notes.host_client_decision_drill_real_click_findings"'), "Current handbook exports TASK_666 notes")


func _write_findings_manifest() -> void:
	var recheck: Dictionary = _read_json(RECHECK_PATH)
	var technical_guard: Dictionary = _read_json(TECHNICAL_GUARD_PATH)
	var real_capture: Dictionary = _read_json(REAL_CAPTURE_PATH)
	var technical_path_gate: String = "pass" if String(technical_guard.get("technical_guard_gate", "")) == "pass" else "missing_or_failed"
	var real_capture_gate: String = String(real_capture.get("decision_drill_review_gate", "manual_open"))
	if real_capture_gate.is_empty():
		real_capture_gate = "manual_open"
	var recheck_gate: String = String(recheck.get("readiness_gate", "missing"))
	var manual_review_done: bool = bool(recheck.get("manual_review_done", false)) or bool(real_capture.get("decision_drill_review_done", false)) or bool(technical_guard.get("manual_review_done", false))
	var manual_click_findings_gate: String = "manual_done" if manual_review_done else "manual_still_open"
	var authority_path: Dictionary = Dictionary(technical_guard.get("authority_path", {}))
	var decision_drill_path: Dictionary = Dictionary(technical_guard.get("decision_drill_path", {}))
	var review_card_context: Dictionary = Dictionary(technical_guard.get("review_card_context", {}))
	var manifest := {
		"schema": "sternenbuergerchen.host_client_decision_drill_real_click_findings.v1",
		"task_id": "TASK_666",
		"source_task_ids": PackedStringArray(["TASK_662", "TASK_664", "TASK_665"]),
		"source_recheck_path": "tmp/host_client_decision_drill_real_click_recheck.json",
		"source_recheck_present": not recheck.is_empty(),
		"source_technical_guard_path": "tmp/host_client_decision_drill_technical_click_guard.json",
		"source_technical_guard_present": not technical_guard.is_empty(),
		"source_real_capture_path": "tmp/host_client_two_window_real_run_review.json",
		"source_real_capture_present": not real_capture.is_empty(),
		"technical_path_gate": technical_path_gate,
		"real_capture_gate": real_capture_gate,
		"recheck_gate": recheck_gate,
		"manual_click_findings_gate": manual_click_findings_gate,
		"manual_review_required": true,
		"manual_review_done": manual_review_done,
		"confirmed_findings": [
			"peer2_bravo_command_accepted" if bool(authority_path.get("peer2_bravo_command_accepted", false)) else "peer2_bravo_command_missing",
			"peer2_alpha_rejected_peer_team_mismatch" if bool(authority_path.get("peer2_alpha_command_rejected", false)) and String(authority_path.get("alpha_reject_reason", "")) == "peer_team_mismatch" else "peer2_alpha_reject_missing",
			"use_bravo_feedback_available" if String(authority_path.get("visible_action_text", "")) == "USE BRAVO" else "use_bravo_missing",
			"client_card_context_p2_bravo" if String(review_card_context.get("text", "")) == "P2 BRAVO" else "client_card_context_missing",
			"next_aa_preview_before_go" if String(decision_drill_path.get("next_token", "")) == "AA" and String(decision_drill_path.get("before_go_stage", "")) == "preview" else "preview_missing",
			"go_execution_after_confirm" if bool(decision_drill_path.get("go_result", false)) and String(decision_drill_path.get("after_go_stage", "")) == "execution" else "go_execution_missing",
		],
		"open_manual_findings": [
			"can_player_notice_block_p2_wrong_team_without_prompt",
			"can_player_understand_use_bravo_as_next_action",
			"can_player_find_p2_bravo_card_context_quickly",
			"can_player_read_next_aa_after_context_switch",
			"does_preview_before_go_feel_deliberate",
			"does_go_feedback_feel_immediate_enough",
		],
		"autonomous_next_candidate": "TASK_685 - Mission Interaction Progress FullHD Sight Pass",
		"manual_next_action": "Run the real two-window click drill and fill the TASK_666 report notes.",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"recommended_next_task": "TASK_685 - Mission Interaction Progress FullHD Sight Pass",
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp"))
	var file := FileAccess.open(FINDINGS_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_666 findings manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	_assert(FileAccess.file_exists(FINDINGS_PATH), "TASK_666 findings manifest written")


func _test_findings_manifest() -> void:
	_assert(FileAccess.file_exists(RECHECK_PATH), "TASK_664 recheck manifest exists")
	_assert(FileAccess.file_exists(TECHNICAL_GUARD_PATH), "TASK_665 technical guard manifest exists")
	_assert(FileAccess.file_exists(REAL_CAPTURE_PATH), "TASK_662 real capture manifest exists")
	_assert(FileAccess.file_exists(FINDINGS_PATH), "TASK_666 findings manifest exists")
	var manifest: Dictionary = _read_json(FINDINGS_PATH)
	_assert(String(manifest.get("schema", "")) == "sternenbuergerchen.host_client_decision_drill_real_click_findings.v1", "Findings schema is stable")
	_assert(String(manifest.get("task_id", "")) == "TASK_666", "Findings records TASK_666")
	_assert(bool(manifest.get("source_recheck_present", false)), "Findings sees TASK_664 recheck source")
	_assert(bool(manifest.get("source_technical_guard_present", false)), "Findings sees TASK_665 guard source")
	_assert(bool(manifest.get("source_real_capture_present", false)), "Findings sees real capture source")
	_assert(String(manifest.get("technical_path_gate", "")) == "pass", "Findings confirms technical path pass")
	_assert(String(manifest.get("real_capture_gate", "")) == "review_ready", "Findings confirms capture review-ready")
	_assert(String(manifest.get("recheck_gate", "")) == "ready_for_real_click_recheck", "Findings confirms recheck is ready")
	_assert(String(manifest.get("manual_click_findings_gate", "")) == "manual_still_open", "Findings keeps manual click review open")
	_assert(bool(manifest.get("manual_review_required", false)), "Findings requires manual review")
	_assert(not bool(manifest.get("manual_review_done", true)), "Findings does not claim manual review done")
	var confirmed_findings: Array = Array(manifest.get("confirmed_findings", []))
	_assert(confirmed_findings.has("peer2_bravo_command_accepted"), "Findings confirms Peer2 Bravo accept")
	_assert(confirmed_findings.has("peer2_alpha_rejected_peer_team_mismatch"), "Findings confirms Peer2 Alpha reject")
	_assert(confirmed_findings.has("use_bravo_feedback_available"), "Findings confirms USE BRAVO")
	_assert(confirmed_findings.has("client_card_context_p2_bravo"), "Findings confirms P2 BRAVO")
	_assert(confirmed_findings.has("next_aa_preview_before_go"), "Findings confirms NEXT AA preview")
	_assert(confirmed_findings.has("go_execution_after_confirm"), "Findings confirms GO execution")
	_assert(Array(manifest.get("open_manual_findings", [])).size() >= 6, "Findings keeps open manual observations")
	_assert(String(manifest.get("autonomous_next_candidate", "")) == "TASK_685 - Mission Interaction Progress FullHD Sight Pass", "Findings recommends autonomous next candidate")
	_assert(bool(manifest.get("read_only", false)), "Findings remains read-only")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Findings does not set gameplay truth")


func _read_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return Dictionary(parsed)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
