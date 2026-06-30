extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_625_host_client_visible_reject_feedback_polish.md"
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
	print("=== TASK_625 Host Client Visible Reject Feedback Polish ===")
	_test_docs_reports_and_contract()
	_test_visible_reject_feedback()
	_test_controller_visible_feedback_export()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_625: FAILED")
		quit(1)
		return
	print("TASK_625: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_625 task file exists")
	_assert(task_text.contains("Host Client Visible Reject Feedback Polish"), "TASK_625 task names visible reject feedback")
	_assert(status_text.contains("TASK_625 - Host Client Visible Reject Feedback Polish"), "Implementation status tracks TASK_625")
	_assert(roadmap_text.contains("TASK_625 - Host Client Visible Reject Feedback Polish (implementiert)"), "Roadmap marks TASK_625 implemented")
	_assert(contract_text.contains("Host-Client-Visible-Reject-Feedback-Polish"), "Mission feedback contract documents TASK_625")
	_assert(report_text.contains("TASK_625 Host Client Visible Reject Feedback Polish"), "Rolling report tracks TASK_625")
	_assert(report_text.contains('latest_completed_task: "TASK_626 - Host Client Real Click Review Evidence"'), "Rolling report advances latest completed beyond TASK_625")
	_assert(handbook_text.contains("TASK_625 - Host Client Visible Reject Feedback Polish"), "Status handbook tracks TASK_625")
	_assert(handbook_text.contains('current_task: "TASK_626 - Host Client Real Click Review Evidence"'), "Status handbook current task advances beyond TASK_625")
	_assert(presenter_text.contains("_build_visible_feedback_text"), "Presenter contains visible feedback text builder")
	_assert(controller_text.contains("authority_visible_feedback_text"), "Controller exports visible authority feedback text")
	_test_report_export_fields(report_text, handbook_text)


func _test_report_export_fields(report_text: String, handbook_text: String) -> void:
	var required_export_keys: Array[String] = [
		"host_client_visible_reject_feedback.task_id",
		"host_client_visible_reject_feedback.visible_feedback_text",
		"host_client_visible_reject_feedback.visible_feedback_ready",
		"host_client_visible_reject_feedback.attention_tone",
		"host_client_visible_reject_feedback.display_contains_visible_feedback",
		"host_client_visible_reject_feedback.command_snapshot_exports_feedback",
		"host_client_visible_reject_feedback.read_only",
		"host_client_visible_reject_feedback.recommended_next_task",
		"host_client_visible_reject_feedback.notes",
	]
	for export_key in required_export_keys:
		_assert(report_text.contains('data-export-key="%s"' % export_key), "Rolling report exports %s" % export_key)
	_assert(report_text.contains('data-note-key="notes.host_client_visible_reject_feedback"'), "Rolling report exports TASK_625 free note")
	_assert(handbook_text.contains('data-export-key="status.task_625_done"'), "Status handbook exports TASK_625 checkbox")


func _test_visible_reject_feedback() -> void:
	var presenter_script: GDScript = load(PRESENTER_PATH)
	var presenter = presenter_script.new()
	var snapshot: Dictionary = Dictionary(presenter.call("build_snapshot", _build_network_snapshot()))
	var authority_visual: Dictionary = Dictionary(snapshot.get("authority_visual", {}))
	var tooltip_text: String = String(authority_visual.get("tooltip_text", ""))
	_assert(String(authority_visual.get("schema", "")) == "sternenbuergerchen.host_client_authority_visual.v1", "Authority visual schema stays stable")
	_assert(String(authority_visual.get("task_id", "")) == "TASK_625", "Authority visual task id advances to TASK_625")
	_assert(String(authority_visual.get("compact_text", "")) == "AUTH OK1/RJ2", "Compact AUTH text stays stable")
	_assert(String(authority_visual.get("visible_feedback_text", "")) == "BLOCK P2 wrong team", "Visible feedback text is short")
	_assert(bool(authority_visual.get("visible_feedback_ready", false)), "Visible feedback is marked ready")
	_assert(String(authority_visual.get("attention_tone", "")) == "mixed", "Attention tone keeps mixed authority state")
	_assert(String(authority_visual.get("feedback_line", "")) == "AUTH BLOCKED P2: wrong team", "Detailed feedback line remains available")
	_assert(String(authority_visual.get("feedback_detail", "")).contains("cannot command"), "Detailed feedback keeps target explanation")
	_assert(tooltip_text.contains("Visible cue: BLOCK P2 wrong team"), "Tooltip includes visible cue explanation")
	_assert(tooltip_text.contains("Last reject: Peer 2 | peer_team_mismatch"), "Tooltip keeps raw reject reason")
	_assert(bool(authority_visual.get("read_only", false)), "Authority feedback remains read-only")
	_assert(not bool(authority_visual.get("ui_sets_gameplay_truth", true)), "Authority feedback does not set gameplay truth")


func _test_controller_visible_feedback_export() -> void:
	var presenter_script: GDScript = load(PRESENTER_PATH)
	var controller_script: GDScript = load(CONTROLLER_PATH)
	var presenter = presenter_script.new()
	var controller: Node = controller_script.new()
	var presenter_snapshot: Dictionary = Dictionary(presenter.call("build_snapshot", _build_network_snapshot()))
	var decorated: Dictionary = Dictionary(controller.call("_with_review_session_badge", presenter_snapshot))
	var authority_visual: Dictionary = Dictionary(decorated.get("authority_visual", {}))
	var display_text: String = String(decorated.get("display_text", ""))
	var tooltip_text: String = String(decorated.get("display_tooltip_text", ""))
	_assert(String(authority_visual.get("visible_feedback_text", "")) == "BLOCK P2 wrong team", "Decorated chip carries visible feedback text")
	_assert(String(decorated.get("authority_visible_feedback_text", "")) == "BLOCK P2 wrong team", "Decorated chip exports visible feedback text")
	_assert(display_text.contains("AUTH OK1/RJ2"), "Decorated display keeps compact AUTH status")
	_assert(display_text.contains("BLOCK P2 wrong team"), "Decorated display shows visible reject feedback")
	_assert(tooltip_text.contains("Visible cue: BLOCK P2 wrong team"), "Decorated tooltip explains visible cue")
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
			"unit_id": "task625_alpha",
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
