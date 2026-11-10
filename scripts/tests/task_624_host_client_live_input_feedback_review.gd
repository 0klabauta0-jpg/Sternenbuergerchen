extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_624_host_client_live_input_feedback_review.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const STATUS_HANDBOOK_REPORT_PATH: String = "res://docs/reports/project_status_handbook_2026_06_29.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const PRESENTER_PATH: String = "res://scripts/mission/mission_team_chip_presenter.gd"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_624 Host Client Live Input Feedback Review ===")
	_test_docs_reports_and_contract()
	_test_presenter_feedback_language()
	_test_controller_feedback_export()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_624: FAILED")
		quit(1)
		return
	print("TASK_624: ALL PASSED")
	quit(0)


func _test_docs_reports_and_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var handbook_text: String = _read_text(STATUS_HANDBOOK_REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var presenter_text: String = _read_text(PRESENTER_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var feedback_source_text: String = _read_text("res://scripts/mission/diagnostics/mission_command_feedback_diagnostics.gd")
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_624 task file exists")
	_assert(task_text.contains("Host Client Live Input Feedback Review"), "TASK_624 task names live input feedback")
	_assert(status_text.contains("TASK_624 - Host Client Live Input Feedback Review"), "Implementation status tracks TASK_624")
	_assert(roadmap_text.contains("TASK_624 - Host Client Live Input Feedback Review (implementiert)"), "Roadmap marks TASK_624 implemented")
	_assert(contract_text.contains("Host-Client-Live-Input-Feedback-Review"), "Mission feedback contract documents TASK_624")
	_assert(report_text.contains("TASK_624 Host Client Live Input Feedback Review"), "Rolling report tracks TASK_624")
	_assert(report_text.contains('latest_completed_task: "TASK_628 - Mission HUD Legacy Contract Refresh"'), "Rolling report advances latest completed beyond TASK_624")
	_assert(handbook_text.contains("TASK_624 - Host Client Live Input Feedback Review"), "Status handbook tracks TASK_624")
	_assert(handbook_text.contains('current_task: "TASK_628 - Mission HUD Legacy Contract Refresh"'), "Status handbook current task advances beyond TASK_624")
	_assert(presenter_text.contains("_build_reject_reason_label"), "Presenter contains reject reason label builder")
	_assert(feedback_source_text.contains("authority_feedback_line"), "Controller exports authority feedback line")
	_test_report_export_fields(report_text, handbook_text)


func _test_report_export_fields(report_text: String, handbook_text: String) -> void:
	var required_export_keys: Array[String] = [
		"host_client_live_input_feedback.task_id",
		"host_client_live_input_feedback.feedback_line",
		"host_client_live_input_feedback.feedback_detail",
		"host_client_live_input_feedback.last_reject_label",
		"host_client_live_input_feedback.last_reject_target",
		"host_client_live_input_feedback.raw_reason_preserved",
		"host_client_live_input_feedback.input_feedback_ready",
		"host_client_live_input_feedback.read_only",
		"host_client_live_input_feedback.recommended_next_task",
		"host_client_live_input_feedback.notes",
	]
	for export_key in required_export_keys:
		_assert(report_text.contains('data-export-key="%s"' % export_key), "Rolling report exports %s" % export_key)
	_assert(report_text.contains('data-note-key="notes.host_client_live_input_feedback"'), "Rolling report exports TASK_624 free note")
	_assert(handbook_text.contains('data-export-key="status.task_624_done"'), "Status handbook exports TASK_624 checkbox")


func _test_presenter_feedback_language() -> void:
	var presenter_script: GDScript = load(PRESENTER_PATH)
	var presenter = presenter_script.new()
	var snapshot: Dictionary = Dictionary(presenter.call("build_snapshot", _build_network_snapshot()))
	var authority_visual: Dictionary = Dictionary(snapshot.get("authority_visual", {}))
	var tooltip_text: String = String(authority_visual.get("tooltip_text", ""))
	_assert(String(authority_visual.get("schema", "")) == "sternenbuergerchen.host_client_authority_visual.v1", "Authority visual schema stays stable")
	_assert(String(authority_visual.get("task_id", "")) == "TASK_625", "Authority visual task id advances to TASK_625")
	_assert(String(authority_visual.get("compact_text", "")) == "AUTH OK1/RJ2", "TASK_623 compact AUTH text stays stable")
	_assert(String(authority_visual.get("last_reject_reason", "")) == "peer_team_mismatch", "Raw reject reason is preserved")
	_assert(String(authority_visual.get("last_reject_label", "")) == "wrong team", "Reject reason gets player-readable label")
	_assert(String(authority_visual.get("last_reject_target", "")) == "team_alpha / FT blue / task624_alpha", "Reject target names team, fireteam and unit")
	_assert(String(authority_visual.get("feedback_line", "")) == "AUTH BLOCKED P2: wrong team", "Feedback line is short and human-readable")
	_assert(String(authority_visual.get("feedback_detail", "")) == "Peer 2 cannot command team_alpha / FT blue / task624_alpha.", "Feedback detail explains the ownership boundary")
	_assert(bool(authority_visual.get("input_feedback_ready", false)), "Input feedback is marked ready")
	_assert(tooltip_text.contains("AUTH BLOCKED P2: wrong team"), "Tooltip includes feedback line")
	_assert(tooltip_text.contains("Peer 2 cannot command team_alpha / FT blue / task624_alpha."), "Tooltip includes feedback detail")
	_assert(tooltip_text.contains("Last reject: Peer 2 | peer_team_mismatch"), "Tooltip keeps raw reject reason")
	_assert(bool(authority_visual.get("read_only", false)), "Authority feedback is read-only")
	_assert(not bool(authority_visual.get("ui_sets_gameplay_truth", true)), "Authority feedback does not set gameplay truth")


func _test_controller_feedback_export() -> void:
	var presenter_script: GDScript = load(PRESENTER_PATH)
	var controller_script: GDScript = load(CONTROLLER_PATH)
	var presenter = presenter_script.new()
	var controller: Node = controller_script.new()
	var presenter_snapshot: Dictionary = Dictionary(presenter.call("build_snapshot", _build_network_snapshot()))
	var decorated: Dictionary = Dictionary(controller.call("_with_review_session_badge", presenter_snapshot))
	var authority_visual: Dictionary = Dictionary(decorated.get("authority_visual", {}))
	var tooltip_text: String = String(decorated.get("display_tooltip_text", ""))
	_assert(String(authority_visual.get("feedback_line", "")) == "AUTH BLOCKED P2: wrong team", "Decorated team chip carries feedback line")
	_assert(String(authority_visual.get("feedback_detail", "")).contains("cannot command"), "Decorated team chip carries feedback detail")
	_assert(String(decorated.get("display_text", "")).contains("AUTH OK1/RJ2"), "Decorated display keeps compact AUTH status")
	_assert(tooltip_text.contains("AUTH BLOCKED P2: wrong team"), "Decorated tooltip includes feedback line")
	_assert(tooltip_text.contains("Last reject: Peer 2 | peer_team_mismatch"), "Decorated tooltip preserves raw reason")
	_assert(bool(decorated.get("read_only", false)), "Decorated feedback remains read-only")
	_assert(not bool(decorated.get("ui_sets_gameplay_truth", true)), "Decorated feedback does not set gameplay truth")
	controller.free()


func _build_network_snapshot() -> Dictionary:
	return {
		"accepted_count": 1,
		"rejected_count": 2,
		"last_rejection": {
			"accepted": false,
			"reason": "peer_team_mismatch",
			"peer_id": 2,
			"team_id": "team_alpha",
			"fireteam_id": "blue",
			"unit_id": "task624_alpha",
		},
		"peer_teams": {
			1: "team_alpha",
			2: "team_bravo",
		},
		"peer_roles": {
			1: "host",
			2: "fireteam",
		},
		"peer_fireteams": {
			1: PackedStringArray(["blue"]),
			2: PackedStringArray(["red"]),
		},
	}


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
