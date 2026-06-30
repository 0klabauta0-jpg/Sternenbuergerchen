extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_664_host_client_decision_drill_real_click_recheck.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const CURRENT_REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const SOURCE_CLICK_PACKET_PATH: String = "res://tmp/host_client_decision_drill_click_evidence.json"
const SOURCE_CAPTURE_MANIFEST_PATH: String = "res://tmp/host_client_two_window_real_run_review.json"
const RECHECK_PATH: String = "res://tmp/host_client_decision_drill_real_click_recheck.json"
const EXPECTED_STYLE_ID: String = "host_client_fireteam_context_badge_v1"
const EXPECTED_NEXT_TASK: String = "TASK_665 - Host Client Decision Drill Technical Click Guard"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_664 Host Client Decision Drill Real Click Recheck ===")
	_test_docs_report_and_contract()
	_write_recheck_manifest()
	_test_recheck_manifest()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_664: FAILED")
		quit(1)
		return
	print("TASK_664: ALL PASSED")
	quit(0)


func _test_docs_report_and_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(CURRENT_REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_664 task file exists")
	_assert(task_text.contains("Host Client Decision Drill Real Click Recheck"), "TASK_664 task names real click recheck")
	_assert(status_text.contains("TASK_664 - Host Client Decision Drill Real Click Recheck"), "Implementation status tracks TASK_664")
	_assert(roadmap_text.contains("TASK_664 - Host Client Decision Drill Real Click Recheck (implementiert)"), "Roadmap marks TASK_664 implemented")
	_assert(roadmap_text.contains("TASK_665 - Host Client Decision Drill Technical Click Guard (implementiert)"), "Roadmap tracks TASK_665 follow-up")
	_assert(contract_text.contains("Host-Client-Decision-Drill-Real-Click-Recheck"), "Mission feedback contract documents TASK_664")
	_assert(report_text.contains("TASK_664 - Host Client Decision Drill Real Click Recheck"), "Current handbook report tracks TASK_664")
	_assert(report_text.contains("latest_completed_task:"), "Current handbook exports a latest completed task")
	_assert(report_text.contains("TASK_664 - Host Client Decision Drill Real Click Recheck"), "Current handbook preserves TASK_664 context after later tasks")
	_assert(report_text.contains('data-export-key="host_client_decision_drill_real_click_recheck.ready"'), "Current handbook exports TASK_664 ready check")
	_assert(report_text.contains('data-note-key="notes.host_client_decision_drill_real_click_recheck"'), "Current handbook exports TASK_664 notes")
	_assert(report_text.contains(EXPECTED_NEXT_TASK), "Current handbook recommends TASK_665")


func _write_recheck_manifest() -> void:
	var click_packet: Dictionary = _read_json(SOURCE_CLICK_PACKET_PATH)
	var capture_manifest: Dictionary = _read_json(SOURCE_CAPTURE_MANIFEST_PATH)
	var wrong_context_feedback: Dictionary = Dictionary(click_packet.get("wrong_context_feedback", {}))
	var decision_drill_context: Dictionary = Dictionary(click_packet.get("decision_drill_context", {}))
	var manifest := {
		"schema": "sternenbuergerchen.host_client_decision_drill_real_click_recheck.v1",
		"task_id": "TASK_664",
		"source_task_ids": PackedStringArray(["TASK_661", "TASK_662", "TASK_663"]),
		"source_click_packet_path": "tmp/host_client_decision_drill_click_evidence.json",
		"source_click_packet_present": not click_packet.is_empty(),
		"source_capture_manifest_path": "tmp/host_client_two_window_real_run_review.json",
		"source_capture_manifest_present": not capture_manifest.is_empty(),
		"source_client_capture_path": String(capture_manifest.get("client_screenshot_path", "tmp/host_client_two_window_client_review.png")),
		"source_host_capture_path": String(capture_manifest.get("host_screenshot_path", "tmp/host_client_two_window_host_review.png")),
		"launch_requested": bool(capture_manifest.get("launch_requested", false)),
		"real_run_done": bool(capture_manifest.get("real_run_done", false)),
		"screenshot_written": bool(capture_manifest.get("screenshot_written", false)),
		"host_screenshot_written": bool(capture_manifest.get("host_screenshot_written", false)),
		"client_screenshot_written": bool(capture_manifest.get("client_screenshot_written", false)),
		"host_expected_badge_text": String(capture_manifest.get("host_expected_badge_text", "HOST P1 ALPHA")),
		"client_expected_badge_text": String(capture_manifest.get("client_expected_badge_text", "CLIENT P2 BRAVO")),
		"host_fireteam_card_context_text": "P1 ALPHA",
		"client_fireteam_card_context_text": "P2 BRAVO",
		"fireteam_card_context_style_id": EXPECTED_STYLE_ID,
		"expected_visible_feedback": {
			"raw_reason": String(wrong_context_feedback.get("raw_reason", "peer_team_mismatch")),
			"block_text": String(wrong_context_feedback.get("block_text", "BLOCK P2 wrong team")),
			"action_text": String(wrong_context_feedback.get("action_text", "USE BRAVO")),
			"next_action_text": String(wrong_context_feedback.get("next_action_text", "Use BRAVO fireteam.")),
		},
		"decision_drill_context": {
			"next_token": String(decision_drill_context.get("next_token", "AA")),
			"recommended_plan_id": String(decision_drill_context.get("recommended_plan_id", "aa_first_push")),
			"correct_fireteam": String(decision_drill_context.get("correct_fireteam", "bravo")),
			"confirm_control": String(decision_drill_context.get("confirm_control", "GO")),
		},
		"recheck_sequence": [
			{"step": 1, "action": "open_host_client_windows", "expect": "host P1 ALPHA and client P2 BRAVO are visible"},
			{"step": 2, "action": "confirm_client_fireteam_card_context_badge", "expect": "client fireteam mini-card shows P2 BRAVO"},
			{"step": 3, "action": "client_peer2_attempts_alpha_command", "expect": "BLOCK P2 wrong team"},
			{"step": 4, "action": "read_use_bravo_and_select_bravo_context", "expect": "USE BRAVO leads back to Bravo context"},
			{"step": 5, "action": "read_next_aa_and_preview_before_go", "expect": "NEXT AA and move preview are readable before GO"},
			{"step": 6, "action": "confirm_go_after_preview", "expect": "GO feedback appears only after deliberate confirm"},
		],
		"manual_observations": [
			"client_card_context_badge_visible",
			"peer2_alpha_reject_clicked",
			"use_bravo_visible",
			"bravo_context_selected",
			"next_aa_visible_after_context_switch",
			"move_preview_readable_before_go",
			"go_feedback_visible_after_confirm",
			"no_gameplay_state_changed_by_recheck_packet",
		],
		"readiness_gate": "ready_for_real_click_recheck",
		"manual_review_required": true,
		"manual_review_done": false,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"recommended_next_task": EXPECTED_NEXT_TASK,
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp"))
	var file := FileAccess.open(RECHECK_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_664 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	_assert(FileAccess.file_exists(RECHECK_PATH), "TASK_664 recheck manifest written")


func _test_recheck_manifest() -> void:
	_assert(FileAccess.file_exists(SOURCE_CLICK_PACKET_PATH), "TASK_661 source click packet exists")
	_assert(FileAccess.file_exists(SOURCE_CAPTURE_MANIFEST_PATH), "TASK_662/TASK_663 real capture manifest exists")
	_assert(FileAccess.file_exists(RECHECK_PATH), "TASK_664 recheck manifest exists")
	var manifest: Dictionary = _read_json(RECHECK_PATH)
	_assert(String(manifest.get("schema", "")) == "sternenbuergerchen.host_client_decision_drill_real_click_recheck.v1", "Manifest schema is stable")
	_assert(String(manifest.get("task_id", "")) == "TASK_664", "Manifest records TASK_664")
	_assert(bool(manifest.get("source_click_packet_present", false)), "Manifest sees TASK_661 source packet")
	_assert(bool(manifest.get("source_capture_manifest_present", false)), "Manifest sees real capture source")
	_assert(bool(manifest.get("launch_requested", false)), "Manifest is based on launched window capture")
	_assert(bool(manifest.get("screenshot_written", false)), "Manifest records screenshot source")
	_assert(bool(manifest.get("host_screenshot_written", false)), "Manifest records host screenshot source")
	_assert(bool(manifest.get("client_screenshot_written", false)), "Manifest records client screenshot source")
	_assert(String(manifest.get("host_expected_badge_text", "")) == "HOST P1 ALPHA", "Manifest expects host Alpha header")
	_assert(String(manifest.get("client_expected_badge_text", "")) == "CLIENT P2 BRAVO", "Manifest expects client Bravo header")
	_assert(String(manifest.get("host_fireteam_card_context_text", "")) == "P1 ALPHA", "Manifest expects host fireteam card context")
	_assert(String(manifest.get("client_fireteam_card_context_text", "")) == "P2 BRAVO", "Manifest expects client fireteam card context")
	_assert(String(manifest.get("fireteam_card_context_style_id", "")) == EXPECTED_STYLE_ID, "Manifest records TASK_663 card style id")
	var feedback: Dictionary = Dictionary(manifest.get("expected_visible_feedback", {}))
	_assert(String(feedback.get("raw_reason", "")) == "peer_team_mismatch", "Manifest keeps peer-team mismatch reason")
	_assert(String(feedback.get("block_text", "")) == "BLOCK P2 wrong team", "Manifest keeps block text")
	_assert(String(feedback.get("action_text", "")) == "USE BRAVO", "Manifest keeps USE BRAVO action")
	var drill: Dictionary = Dictionary(manifest.get("decision_drill_context", {}))
	_assert(String(drill.get("next_token", "")) == "AA", "Manifest keeps NEXT AA")
	_assert(String(drill.get("correct_fireteam", "")) == "bravo", "Manifest keeps Bravo as correct context")
	_assert(String(drill.get("confirm_control", "")) == "GO", "Manifest keeps GO confirm")
	_assert(Array(manifest.get("recheck_sequence", [])).size() >= 6, "Manifest contains full recheck sequence")
	_assert(_array_contains(manifest.get("manual_observations", []), "client_card_context_badge_visible"), "Manual observations include client card badge")
	_assert(_array_contains(manifest.get("manual_observations", []), "use_bravo_visible"), "Manual observations include USE BRAVO")
	_assert(_array_contains(manifest.get("manual_observations", []), "next_aa_visible_after_context_switch"), "Manual observations include NEXT AA")
	_assert(_array_contains(manifest.get("manual_observations", []), "move_preview_readable_before_go"), "Manual observations include preview before GO")
	_assert(String(manifest.get("readiness_gate", "")) == "ready_for_real_click_recheck", "Manifest is ready for real click recheck")
	_assert(bool(manifest.get("manual_review_required", false)), "Manifest requires manual review")
	_assert(not bool(manifest.get("manual_review_done", true)), "Manifest does not claim manual review done")
	_assert(bool(manifest.get("read_only", false)), "Manifest remains read-only")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Manifest does not set gameplay truth")
	_assert(String(manifest.get("recommended_next_task", "")) == EXPECTED_NEXT_TASK, "Manifest recommends TASK_665 technical guard")


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


func _array_contains(value: Variant, needle: String) -> bool:
	if typeof(value) != TYPE_ARRAY:
		return false
	for item in Array(value):
		if String(item) == needle:
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
