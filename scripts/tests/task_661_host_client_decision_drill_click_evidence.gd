extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_661_host_client_decision_drill_click_evidence.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const CURRENT_REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const PACKET_PATH: String = "res://tmp/host_client_decision_drill_click_evidence.json"
const SOURCE_CLICK_PACKET_PATH: String = "res://tmp/host_client_real_click_playtest_packet.json"
const SOURCE_DECISION_BUDGET_PATH: String = "res://tmp/decision_drill_snapshot_performance_budget.json"
const EXPECTED_NEXT_TASK: String = "TASK_662 - Host Client Decision Drill Real Window Capture"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_661 Host Client Decision Drill Click Evidence ===")
	_test_docs_and_report()
	_write_click_evidence_packet()
	_test_click_evidence_packet()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_661: FAILED")
		quit(1)
		return
	print("TASK_661: ALL PASSED")
	quit(0)


func _test_docs_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(CURRENT_REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_661 task file exists")
	_assert(task_text.contains("Host Client Decision Drill Click Evidence"), "TASK_661 task names host/client decision drill")
	_assert(status_text.contains("TASK_661 - Host Client Decision Drill Click Evidence"), "Implementation status tracks TASK_661")
	_assert(roadmap_text.contains("TASK_661 - Host Client Decision Drill Click Evidence (implementiert)"), "Roadmap marks TASK_661 implemented")
	_assert(contract_text.contains("Host-Client-Decision-Drill-Click-Evidence"), "Mission feedback contract documents TASK_661")
	_assert(report_text.contains("TASK_661 - Host Client Decision Drill Click Evidence"), "Current handbook report tracks TASK_661")
	_assert(report_text.contains("latest_completed_task:"), "Current handbook exports a latest completed task")
	_assert(report_text.contains("recommended_next_task:"), "Current handbook exports a recommended next task")
	_assert(report_text.contains("TASK_662 - Host Client Decision Drill Real Window Capture"), "Current handbook tracks the TASK_661 follow-up")
	_assert(report_text.contains('data-export-key="status.task_661_done"'), "Current handbook exports TASK_661 done status")
	_assert(report_text.contains('data-export-key="host_client_decision_drill.use_bravo_visible"'), "Current handbook exports USE BRAVO check")
	_assert(report_text.contains('data-note-key="notes.host_client_decision_drill"'), "Current handbook exports TASK_661 notes")


func _write_click_evidence_packet() -> void:
	var source_click_packet: Dictionary = _read_json(SOURCE_CLICK_PACKET_PATH)
	var decision_budget: Dictionary = _read_json(SOURCE_DECISION_BUDGET_PATH)
	var expected_feedback: Dictionary = Dictionary(source_click_packet.get("expected_visible_feedback", {}))
	if expected_feedback.is_empty():
		expected_feedback = _default_expected_feedback()
	var packet := {
		"schema": "sternenbuergerchen.host_client_decision_drill_click_evidence.v1",
		"task_id": "TASK_661",
		"source_task_ids": PackedStringArray(["TASK_629", "TASK_650", "TASK_651", "TASK_658", "TASK_659", "TASK_660"]),
		"packet_path": "tmp/host_client_decision_drill_click_evidence.json",
		"source_click_packet_path": "tmp/host_client_real_click_playtest_packet.json",
		"source_click_packet_present": not source_click_packet.is_empty(),
		"source_decision_budget_path": "tmp/decision_drill_snapshot_performance_budget.json",
		"source_decision_budget_present": not decision_budget.is_empty(),
		"decision_budget_fast_gate": String(decision_budget.get("fast_gate", "unknown")),
		"host_client_context": {
			"host_peer_id": 1,
			"host_team": "team_alpha",
			"client_peer_id": 2,
			"client_team": "team_bravo",
			"wrong_fireteam": "blue",
			"correct_fireteam": "bravo",
		},
		"wrong_context_feedback": {
			"raw_reason": "peer_team_mismatch",
			"block_text": String(expected_feedback.get("block_text", "BLOCK P2 wrong team")),
			"action_text": String(expected_feedback.get("action_text", "USE BRAVO")),
			"next_action_text": String(expected_feedback.get("next_action_text", "Use BRAVO fireteam.")),
			"next_action_detail": String(expected_feedback.get("next_action_detail", "Peer 2 should command the BRAVO fireteam instead of this target.")),
			"authority_text": String(expected_feedback.get("authority_text", "AUTH OK1/RJ2")),
			"hud_path": String(expected_feedback.get("hud_path", "MissionTeamChipLabel")),
		},
		"decision_drill_context": {
			"route_id": "frontier_probe_aa_computer_cargo",
			"next_token": "AA",
			"recommended_plan_id": "aa_first_push",
			"correct_fireteam": "bravo",
			"confirm_control": "GO",
			"expected_stage_order": PackedStringArray(["blocked_alpha_context", "use_bravo", "preview_next_aa", "confirm_go"]),
		},
		"click_sequence": [
			{"step": 1, "action": "client_peer2_attempts_alpha_command", "expect": "server rejects with peer_team_mismatch"},
			{"step": 2, "action": "read_teamchip_feedback", "expect": "BLOCK P2 wrong team and USE BRAVO are visible"},
			{"step": 3, "action": "switch_to_bravo_context", "expect": "client peer 2 is back on its valid fireteam"},
			{"step": 4, "action": "read_frontier_probe_next", "expect": "NEXT AA remains the immediate tactical decision"},
			{"step": 5, "action": "preview_bravo_move_to_aa", "expect": "path/risk/GO can be read before confirmation"},
			{"step": 6, "action": "confirm_go_only_after_preview", "expect": "GO is a deliberate command, not automatic after reject"},
		],
		"manual_observations": [
			"peer2_alpha_reject_clicked",
			"block_cue_visible",
			"use_bravo_visible",
			"bravo_context_selected",
			"next_aa_visible_after_context_switch",
			"move_preview_readable_before_go",
			"go_feedback_visible_after_confirm",
			"no_gameplay_state_changed_by_packet",
		],
		"readiness_gate": "ready_for_manual_two_window_run",
		"manual_review_required": true,
		"manual_review_done": false,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"recommended_next_task": EXPECTED_NEXT_TASK,
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp"))
	var file := FileAccess.open(PACKET_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_661 packet for writing")
		return
	file.store_string(JSON.stringify(packet, "\t"))
	file.close()
	_assert(FileAccess.file_exists(PACKET_PATH), "TASK_661 packet written")


func _test_click_evidence_packet() -> void:
	_assert(FileAccess.file_exists(PACKET_PATH), "TASK_661 packet exists")
	var packet: Dictionary = _read_json(PACKET_PATH)
	_assert(String(packet.get("schema", "")) == "sternenbuergerchen.host_client_decision_drill_click_evidence.v1", "Packet schema is stable")
	_assert(String(packet.get("task_id", "")) == "TASK_661", "Packet records TASK_661")
	_assert(String(packet.get("readiness_gate", "")) == "ready_for_manual_two_window_run", "Packet is ready for manual two-window run")
	var feedback: Dictionary = Dictionary(packet.get("wrong_context_feedback", {}))
	_assert(String(feedback.get("raw_reason", "")) == "peer_team_mismatch", "Packet records peer-team mismatch")
	_assert(String(feedback.get("block_text", "")) == "BLOCK P2 wrong team", "Packet records visible block text")
	_assert(String(feedback.get("action_text", "")) == "USE BRAVO", "Packet records USE BRAVO action")
	_assert(String(feedback.get("next_action_text", "")) == "Use BRAVO fireteam.", "Packet records next action text")
	var drill: Dictionary = Dictionary(packet.get("decision_drill_context", {}))
	_assert(String(drill.get("next_token", "")) == "AA", "Packet keeps NEXT AA decision")
	_assert(String(drill.get("recommended_plan_id", "")) == "aa_first_push", "Packet keeps AA-first plan")
	_assert(String(drill.get("correct_fireteam", "")) == "bravo", "Packet routes Peer 2 to Bravo context")
	_assert(String(drill.get("confirm_control", "")) == "GO", "Packet keeps GO as deliberate confirm")
	_assert(Array(packet.get("click_sequence", [])).size() >= 6, "Packet has concrete click sequence")
	_assert(_array_contains(packet.get("manual_observations", []), "use_bravo_visible"), "Manual observations include USE BRAVO")
	_assert(_array_contains(packet.get("manual_observations", []), "next_aa_visible_after_context_switch"), "Manual observations include NEXT AA after context switch")
	_assert(_array_contains(packet.get("manual_observations", []), "move_preview_readable_before_go"), "Manual observations include preview before GO")
	_assert(bool(packet.get("manual_review_required", false)), "Packet requires manual review")
	_assert(not bool(packet.get("manual_review_done", true)), "Packet does not claim manual review done")
	_assert(bool(packet.get("read_only", false)), "Packet remains read-only")
	_assert(not bool(packet.get("ui_sets_gameplay_truth", true)), "Packet does not set gameplay truth")
	_assert(String(packet.get("recommended_next_task", "")) == EXPECTED_NEXT_TASK, "Packet recommends real window capture")


func _default_expected_feedback() -> Dictionary:
	return {
		"block_text": "BLOCK P2 wrong team",
		"action_text": "USE BRAVO",
		"next_action_text": "Use BRAVO fireteam.",
		"next_action_detail": "Peer 2 should command the BRAVO fireteam instead of this target.",
		"authority_text": "AUTH OK1/RJ2",
		"hud_path": "MissionTeamChipLabel",
	}


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
