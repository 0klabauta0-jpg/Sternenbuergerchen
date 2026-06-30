extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_629_host_client_real_click_playtest_evidence_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const HANDBOOK_PATH: String = "res://docs/reports/project_status_handbook_2026_06_29.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const SOURCE_REAL_RUN_MANIFEST_PATH: String = "res://tmp/host_client_two_window_real_run_review.json"
const PACKET_PATH: String = "res://tmp/host_client_real_click_playtest_packet.json"
const EXPECTED_NEXT_TASK: String = "TASK_630 - Host Client Real Click Findings Or Mini Scenario Feel"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_629 Host Client Real Click Playtest Evidence Pass ===")
	_test_docs_reports_and_contract()
	_write_playtest_packet()
	_test_playtest_packet()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_629: FAILED")
		quit(1)
		return
	print("TASK_629: ALL PASSED")
	quit(0)


func _test_docs_reports_and_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_629 task file exists")
	_assert(task_text.contains("Host Client Real Click Playtest Evidence Pass"), "TASK_629 task names playtest evidence pass")
	_assert(status_text.contains("TASK_629 - Host Client Real Click Playtest Evidence Pass"), "Implementation status tracks TASK_629")
	_assert(roadmap_text.contains("TASK_629 - Host Client Real Click Playtest Evidence Pass (implementiert)"), "Roadmap marks TASK_629 implemented")
	_assert(contract_text.contains("Host-Client-Real-Click-Playtest-Evidence-Pass"), "Mission feedback contract documents TASK_629")
	_assert(report_text.contains("TASK_629 Host Client Real Click Playtest Evidence Pass"), "Rolling report tracks TASK_629")
	_assert(report_text.contains('latest_completed_task: "TASK_638 - Frontier Probe Debrief Handoff Feel"'), "Rolling report advances latest completed beyond TASK_629")
	_assert(handbook_text.contains("TASK_629 - Host Client Real Click Playtest Evidence Pass"), "Status handbook tracks TASK_629")
	_assert(handbook_text.contains('current_task: "TASK_638 - Frontier Probe Debrief Handoff Feel"'), "Status handbook current task advances beyond TASK_629")
	_test_report_export_fields(report_text, handbook_text)


func _test_report_export_fields(report_text: String, handbook_text: String) -> void:
	var required_export_keys: Array[String] = [
		"host_client_real_click_playtest_packet.task_id",
		"host_client_real_click_playtest_packet.packet_path",
		"host_client_real_click_playtest_packet.source_real_run_manifest_path",
		"host_client_real_click_playtest_packet.readiness_gate",
		"host_client_real_click_playtest_packet.preconditions",
		"host_client_real_click_playtest_packet.click_sequence",
		"host_client_real_click_playtest_packet.manual_observations",
		"host_client_real_click_playtest_packet.manual_review_required",
		"host_client_real_click_playtest_packet.manual_review_done",
		"host_client_real_click_playtest_packet.read_only",
		"host_client_real_click_playtest_packet.recommended_next_task",
		"host_client_real_click_playtest_packet.peer2_alpha_reject_clicked",
		"host_client_real_click_playtest_packet.block_cue_visible",
		"host_client_real_click_playtest_packet.tooltip_raw_reason_checked",
		"host_client_real_click_playtest_packet.input_latency_under_budget",
		"host_client_real_click_playtest_packet.snapshot_sync_checked",
		"host_client_real_click_playtest_packet.focus_recovered_checked",
		"host_client_real_click_playtest_packet.notes",
	]
	for export_key in required_export_keys:
		_assert(report_text.contains('data-export-key="%s"' % export_key), "Rolling report exports %s" % export_key)
	_assert(report_text.contains('data-note-key="notes.host_client_real_click_playtest_packet"'), "Rolling report exports TASK_629 free note")
	_assert(handbook_text.contains('data-export-key="status.task_629_done"'), "Status handbook exports TASK_629 checkbox")


func _write_playtest_packet() -> void:
	var source_manifest: Dictionary = _read_json(SOURCE_REAL_RUN_MANIFEST_PATH)
	var source_present: bool = not source_manifest.is_empty()
	var source_gate: String = String(source_manifest.get("visible_reject_review_gate", "manual_open"))
	var readiness_gate: String = "needs_fresh_capture"
	if source_present and source_gate in ["manual_open", "review_ready"]:
		readiness_gate = "ready_for_manual_run"
	var packet: Dictionary = {
		"schema": "sternenbuergerchen.host_client_real_click_playtest_packet.v1",
		"task_id": "TASK_629",
		"source_real_run_manifest_path": "tmp/host_client_two_window_real_run_review.json",
		"packet_path": "tmp/host_client_real_click_playtest_packet.json",
		"source_manifest_present": source_present,
		"source_visible_reject_review_gate": source_gate,
		"readiness_gate": readiness_gate,
		"preconditions": [
			{"id": "role_peer_team_badges", "source_task": "TASK_620", "expected": "HOST P1 ALPHA and CLIENT P2 BRAVO readable"},
			{"id": "host_client_crops", "source_task": "TASK_618", "expected": "separate host/client crop paths available"},
			{"id": "eventlog_not_overlapping_fireteams", "source_task": "TASK_627", "expected": "#19 EVENT LOG below fireteam mini cards"},
			{"id": "fire_rule_slots_current", "source_task": "TASK_628", "expected": "HF/RF/FW/SUP in command slots 11-14"},
			{"id": "inbound_fireteam_cards_visible", "source_task": "TASK_628", "expected": "selected dropship fireteam members visible disabled"},
		],
		"click_sequence": [
			{"step": 1, "action": "open_host_client_windows", "expect": "host and client badges remain readable"},
			{"step": 2, "action": "client_peer2_attempts_alpha_command", "expect": "server rejects with peer_team_mismatch"},
			{"step": 3, "action": "read_visible_teamchip_feedback", "expect": "BLOCK P2 wrong team visible next to AUTH OK1/RJ2"},
			{"step": 4, "action": "hover_or_inspect_teamchip", "expect": "tooltip/detail keeps raw peer_team_mismatch"},
			{"step": 5, "action": "resume_valid_bravo_context", "expect": "focus and snapshot sync remain stable"},
		],
		"expected_visible_feedback": {
			"block_text": "BLOCK P2 wrong team",
			"authority_text": "AUTH OK1/RJ2",
			"feedback_line": "AUTH BLOCKED P2: wrong team",
			"raw_reason": "peer_team_mismatch",
			"hud_path": "MissionTeamChipLabel",
		},
		"manual_observations": [
			"peer2_alpha_reject_clicked",
			"block_cue_visible",
			"tooltip_raw_reason_checked",
			"input_latency_under_budget",
			"snapshot_sync_checked",
			"focus_recovered_checked",
		],
		"manual_review_required": true,
		"manual_review_done": false,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"recommended_next_task": EXPECTED_NEXT_TASK,
	}
	var dir_path: String = ProjectSettings.globalize_path("res://tmp")
	DirAccess.make_dir_recursive_absolute(dir_path)
	var file := FileAccess.open(PACKET_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_629 packet for writing")
		return
	file.store_string(JSON.stringify(packet, "\t"))
	file.close()
	_assert(FileAccess.file_exists(PACKET_PATH), "TASK_629 packet written")


func _test_playtest_packet() -> void:
	_assert(FileAccess.file_exists(PACKET_PATH), "TASK_629 packet exists")
	var packet: Dictionary = _read_json(PACKET_PATH)
	_assert(String(packet.get("schema", "")) == "sternenbuergerchen.host_client_real_click_playtest_packet.v1", "Packet schema is stable")
	_assert(String(packet.get("task_id", "")) == "TASK_629", "Packet records TASK_629")
	_assert(String(packet.get("source_real_run_manifest_path", "")) == "tmp/host_client_two_window_real_run_review.json", "Packet records source real-run manifest")
	_assert(String(packet.get("packet_path", "")) == "tmp/host_client_real_click_playtest_packet.json", "Packet records own path")
	_assert(String(packet.get("readiness_gate", "")) in ["ready_for_manual_run", "needs_fresh_capture"], "Packet readiness gate is valid")
	_assert(Array(packet.get("preconditions", [])).size() >= 5, "Packet has playtest preconditions")
	_assert(Array(packet.get("click_sequence", [])).size() >= 5, "Packet has concrete click sequence")
	_assert(Array(packet.get("manual_observations", [])).size() >= 6, "Packet has manual observation list")
	var feedback: Dictionary = Dictionary(packet.get("expected_visible_feedback", {}))
	_assert(String(feedback.get("block_text", "")) == "BLOCK P2 wrong team", "Packet expects visible block text")
	_assert(String(feedback.get("raw_reason", "")) == "peer_team_mismatch", "Packet expects raw reject reason")
	_assert(bool(packet.get("manual_review_required", false)), "Packet requires manual review")
	_assert(not bool(packet.get("manual_review_done", true)), "Packet does not claim manual review done")
	_assert(bool(packet.get("read_only", false)), "Packet remains read-only")
	_assert(not bool(packet.get("ui_sets_gameplay_truth", true)), "Packet does not set gameplay truth")
	_assert(String(packet.get("recommended_next_task", "")) == EXPECTED_NEXT_TASK, "Packet recommends next decision task")


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
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
