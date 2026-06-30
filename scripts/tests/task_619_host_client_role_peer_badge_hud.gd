extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_619_host_client_role_peer_badge_hud.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const STATUS_HANDBOOK_REPORT_PATH: String = "res://docs/reports/project_status_handbook_2026_06_29.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_619 Host Client Role Peer Badge HUD ===")
	_test_docs_reports_and_contract()
	_test_controller_static_contract()
	_test_review_session_badge_builder()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_619: FAILED")
		quit(1)
		return
	print("TASK_619: ALL PASSED")
	quit(0)


func _test_docs_reports_and_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var handbook_text: String = _read_text(STATUS_HANDBOOK_REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_619 task file exists")
	_assert(task_text.contains("Host Client Role Peer Badge HUD"), "TASK_619 task names role/peer badge HUD")
	_assert(status_text.contains("TASK_619 - Host Client Role Peer Badge HUD"), "Implementation status tracks TASK_619")
	_assert(roadmap_text.contains("TASK_619 - Host Client Role Peer Badge HUD (implementiert)"), "Roadmap marks TASK_619 implemented")
	_assert(contract_text.contains("Host-Client-Role-Peer-Badge-HUD"), "Mission feedback contract documents TASK_619")
	_assert(report_text.contains("TASK_619 Host Client Role Peer Badge HUD"), "Rolling review workbench tracks TASK_619")
	_assert(report_text.contains("TASK_620 - Host Client Badge Re-Capture Review"), "Rolling report keeps TASK_620 history after badge HUD")
	_assert(handbook_text.contains("SternenBuergerchen Ist-Stand und Handbuch"), "New status handbook report exists")
	_assert(handbook_text.contains('data-report-schema="sternenbuergerchen.html_workbench.v1"'), "Status handbook uses HTML workbench schema")
	_assert(handbook_text.contains("JSON exportieren"), "Status handbook exposes JSON export")
	_test_report_export_fields(report_text, handbook_text)


func _test_report_export_fields(report_text: String, handbook_text: String) -> void:
	var required_export_keys: Array[String] = [
		"host_client_role_peer_badge.task_id",
		"host_client_role_peer_badge.style_id",
		"host_client_role_peer_badge.host_badge_text",
		"host_client_role_peer_badge.client_badge_text",
		"host_client_role_peer_badge.source",
		"host_client_role_peer_badge.mission_team_chip_path",
		"host_client_role_peer_badge.snapshot_fields",
		"host_client_role_peer_badge.read_only",
		"host_client_role_peer_badge.status_handbook_report",
		"host_client_role_peer_badge.recommended_next_task",
		"host_client_role_peer_badge.notes",
	]
	for export_key in required_export_keys:
		_assert(report_text.contains('data-export-key="%s"' % export_key), "Rolling report exports %s" % export_key)
	_assert(report_text.contains('data-note-key="notes.host_client_role_peer_badge"'), "Rolling report exports TASK_619 free note")
	_assert(handbook_text.contains('data-export-key="status.task_619_done"'), "Status handbook exports TASK_619 status checkbox")
	_assert(handbook_text.contains('current_task: "TASK_626 - Host Client Real Click Review Evidence"'), "Status handbook JSON metadata advances beyond TASK_619")


func _test_controller_static_contract() -> void:
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var required_terms: Array[String] = [
		"REVIEW_SESSION_BADGE_STYLE_ID",
		"host_client_role_peer_badge_v1",
		"build_review_session_identity_snapshot",
		"OS.get_cmdline_user_args",
		"--review-role=",
		"--peer-id=",
		"--team=",
		"review_session_badge_text",
		"review_session_badge_visible",
		"review_session_badge_style_id",
		"display_text",
		"display_tooltip_text",
		"MISSION_IDENTITY_HEADER_LABEL_PATH",
		"mission_identity_header_text",
		"MissionTeamChipLabel",
		"TASK_619",
	]
	for term in required_terms:
		_assert(controller_text.contains(term), "Mission controller contains %s" % term)


func _test_review_session_badge_builder() -> void:
	var script: GDScript = load(CONTROLLER_PATH)
	var controller: Node = script.new()
	var host_snapshot: Dictionary = Dictionary(controller.call("build_review_session_identity_snapshot", [
		"--review-role=host",
		"--peer-id=1",
		"--team=team_alpha",
	]))
	var client_snapshot: Dictionary = Dictionary(controller.call("build_review_session_identity_snapshot", [
		"--review-role=client",
		"--peer-id=2",
		"--team=team_bravo",
	]))
	var empty_snapshot: Dictionary = Dictionary(controller.call("build_review_session_identity_snapshot", []))
	_assert(bool(host_snapshot.get("active", false)), "Host snapshot is active")
	_assert(String(host_snapshot.get("badge_text", "")) == "HOST P1 ALPHA", "Host snapshot builds HOST P1 ALPHA")
	_assert(String(host_snapshot.get("role", "")) == "host", "Host snapshot keeps normalized role")
	_assert(int(host_snapshot.get("peer_id", 0)) == 1, "Host snapshot keeps peer id")
	_assert(String(host_snapshot.get("team_id", "")) == "team_alpha", "Host snapshot keeps team id")
	_assert(bool(client_snapshot.get("active", false)), "Client snapshot is active")
	_assert(String(client_snapshot.get("badge_text", "")) == "CLIENT P2 BRAVO", "Client snapshot builds CLIENT P2 BRAVO")
	_assert(String(client_snapshot.get("role", "")) == "client", "Client snapshot keeps normalized role")
	_assert(int(client_snapshot.get("peer_id", 0)) == 2, "Client snapshot keeps peer id")
	_assert(String(client_snapshot.get("team_id", "")) == "team_bravo", "Client snapshot keeps team id")
	_assert(not bool(host_snapshot.get("ui_sets_gameplay_truth", true)), "Host snapshot does not set gameplay truth")
	_assert(not bool(client_snapshot.get("ui_sets_gameplay_truth", true)), "Client snapshot does not set gameplay truth")
	_assert(bool(host_snapshot.get("read_only", false)) and bool(client_snapshot.get("read_only", false)), "Host/client snapshots are read-only")
	_assert(String(empty_snapshot.get("source", "")) == "OS.get_cmdline_user_args", "Empty direct args fall back to OS user args")
	controller.free()


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
