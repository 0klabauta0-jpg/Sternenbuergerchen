extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_623_host_client_authority_visual_findings.md"
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
	print("=== TASK_623 Host Client Authority Visual Findings ===")
	_test_docs_reports_and_contract()
	_test_presenter_authority_visual()
	_test_controller_display_wiring()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_623: FAILED")
		quit(1)
		return
	print("TASK_623: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_623 task file exists")
	_assert(task_text.contains("Host Client Authority Visual Findings"), "TASK_623 task names visual findings")
	_assert(status_text.contains("TASK_623 - Host Client Authority Visual Findings"), "Implementation status tracks TASK_623")
	_assert(roadmap_text.contains("TASK_623 - Host Client Authority Visual Findings (implementiert)"), "Roadmap marks TASK_623 implemented")
	_assert(contract_text.contains("Host-Client-Authority-Visual-Findings"), "Mission feedback contract documents TASK_623")
	_assert(report_text.contains("TASK_623 Host Client Authority Visual Findings"), "Rolling report tracks TASK_623")
	_assert(report_text.contains('latest_completed_task: "TASK_625 - Host Client Visible Reject Feedback Polish"'), "Rolling report advances latest completed beyond TASK_623")
	_assert(handbook_text.contains("TASK_623 - Host Client Authority Visual Findings"), "Status handbook tracks TASK_623")
	_assert(handbook_text.contains('current_task: "TASK_625 - Host Client Visible Reject Feedback Polish"'), "Status handbook current task advances to TASK_625")
	_assert(presenter_text.contains("build_authority_visual_snapshot"), "MissionTeamChipPresenter exposes authority visual builder")
	_assert(controller_text.contains("authority_visual_readable"), "Mission controller exports authority visual readability check")
	_test_report_export_fields(report_text, handbook_text)


func _test_report_export_fields(report_text: String, handbook_text: String) -> void:
	var required_export_keys: Array[String] = [
		"host_client_authority_visual.task_id",
		"host_client_authority_visual.visible_text",
		"host_client_authority_visual.accepted_count",
		"host_client_authority_visual.rejected_count",
		"host_client_authority_visual.last_reject_reason",
		"host_client_authority_visual.tooltip_contains_reject",
		"host_client_authority_visual.read_only",
		"host_client_authority_visual.recommended_next_task",
		"host_client_authority_visual.notes",
	]
	for export_key in required_export_keys:
		_assert(report_text.contains('data-export-key="%s"' % export_key), "Rolling report exports %s" % export_key)
	_assert(report_text.contains('data-note-key="notes.host_client_authority_visual"'), "Rolling report exports TASK_623 free note")
	_assert(handbook_text.contains('data-export-key="status.task_623_done"'), "Status handbook exports TASK_623 checkbox")


func _test_presenter_authority_visual() -> void:
	var presenter_script: GDScript = load(PRESENTER_PATH)
	var presenter = presenter_script.new()
	var snapshot: Dictionary = Dictionary(presenter.call("build_snapshot", _build_network_snapshot()))
	var authority_visual: Dictionary = Dictionary(snapshot.get("authority_visual", {}))
	_assert(String(authority_visual.get("schema", "")) == "sternenbuergerchen.host_client_authority_visual.v1", "Authority visual schema is stable")
	_assert(String(authority_visual.get("task_id", "")) == "TASK_625", "Authority visual task id advances to TASK_625")
	_assert(bool(authority_visual.get("visible", false)), "Authority visual becomes visible after accept/reject activity")
	_assert(int(authority_visual.get("accepted_count", 0)) == 1, "Authority visual counts accepted commands")
	_assert(int(authority_visual.get("rejected_count", 0)) == 2, "Authority visual counts rejected commands")
	_assert(String(authority_visual.get("compact_text", "")) == "AUTH OK1/RJ2", "Authority visual builds compact text")
	_assert(String(authority_visual.get("tooltip_text", "")).contains("Last reject: Peer 2 | peer_team_mismatch"), "Authority tooltip names reject reason")
	_assert(String(authority_visual.get("tone", "")) == "mixed", "Authority visual tone is mixed")
	_assert(bool(authority_visual.get("read_only", false)), "Authority visual is read-only")
	_assert(not bool(authority_visual.get("ui_sets_gameplay_truth", true)), "Authority visual does not set gameplay truth")
	_assert(bool(snapshot.get("authority_visible", false)), "Team chip snapshot mirrors authority visibility")
	_assert(String(snapshot.get("authority_compact_text", "")) == "AUTH OK1/RJ2", "Team chip snapshot mirrors compact authority text")


func _test_controller_display_wiring() -> void:
	var presenter_script: GDScript = load(PRESENTER_PATH)
	var controller_script: GDScript = load(CONTROLLER_PATH)
	var presenter = presenter_script.new()
	var controller: Node = controller_script.new()
	var presenter_snapshot: Dictionary = Dictionary(presenter.call("build_snapshot", _build_network_snapshot()))
	var decorated: Dictionary = Dictionary(controller.call("_with_review_session_badge", presenter_snapshot))
	var display_text: String = String(decorated.get("display_text", ""))
	var tooltip_text: String = String(decorated.get("display_tooltip_text", ""))
	var authority_visual: Dictionary = Dictionary(decorated.get("authority_visual", {}))
	_assert(display_text.contains("AUTH OK1/RJ2"), "Decorated team chip display includes AUTH text")
	_assert(display_text.contains("Teams:"), "Decorated team chip keeps team ownership text")
	_assert(tooltip_text.contains("Last reject: Peer 2 | peer_team_mismatch"), "Decorated team chip tooltip includes reject reason")
	_assert(bool(decorated.get("authority_visible", false)), "Decorated team chip marks authority visible")
	_assert(String(decorated.get("authority_compact_text", "")) == "AUTH OK1/RJ2", "Decorated team chip exports authority compact text")
	_assert(String(authority_visual.get("schema", "")) == "sternenbuergerchen.host_client_authority_visual.v1", "Decorated team chip carries authority visual snapshot")
	_assert(bool(decorated.get("read_only", false)), "Decorated team chip remains read-only")
	_assert(not bool(decorated.get("ui_sets_gameplay_truth", true)), "Decorated team chip does not set gameplay truth")
	controller.free()


func _build_network_snapshot() -> Dictionary:
	return {
		"accepted_count": 1,
		"rejected_count": 2,
		"last_rejection": {
			"accepted": false,
			"reason": "peer_team_mismatch",
			"peer_id": 2,
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
