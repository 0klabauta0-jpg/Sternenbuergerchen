class_name StationRouteHostClientFindings
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_route_host_client_findings.v1"
const EXPECTED_SOURCE_SCHEMA: String = "sternenbuergerchen.host_client_two_window_real_run_review.v1"
const EXPECTED_ACCEPTANCE_TASK_ID: String = "TASK_712"
const DEFAULT_SOURCE_MANIFEST_PATH: String = "tmp/host_client_two_window_real_run_review.json"
const DEFAULT_MANIFEST_PATH: String = "tmp/station_route_host_client_findings.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/project_current_state_handbook_refresh_2026_06_30.html"

const REQUIRED_SEQUENCE: Array[String] = [
	"door_open",
	"computer_controlled",
	"cargo_departed",
]

const REQUIRED_MANUAL_CHECKS: Array[String] = [
	"host_window_launched",
	"client_window_launched",
	"host_station_route_visible",
	"client_station_route_visible",
	"door_open_visible_on_host",
	"door_open_visible_on_client",
	"computer_control_visible_after_door",
	"cargo_departed_visible_after_computer",
	"wrong_team_reject_visible",
	"snapshot_sync_after_each_step",
	"hud_feedback_readable",
	"window_notes_exported",
]

const REQUIRED_REVIEW_CHECKS: Array[String] = [
	"station_route_door_open_host_client",
	"station_route_computer_control_visible",
	"station_route_cargo_departed_visible",
]


static func build_snapshot(acceptance_manifest: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var findings: Array = []
	_add_manifest_findings(findings, acceptance_manifest)
	var blocking_count: int = _count_findings_by_severity(findings, "blocker")
	var warning_count: int = _count_findings_by_severity(findings, "warning")
	var manual_count: int = _count_findings_by_severity(findings, "manual")
	var review_required: bool = bool(acceptance_manifest.get("station_route_host_client_acceptance_review_required", true))
	var review_done: bool = bool(acceptance_manifest.get("station_route_host_client_acceptance_review_done", false))
	var gate: String = String(acceptance_manifest.get("station_route_host_client_acceptance_gate", ""))
	var launch_requested: bool = bool(acceptance_manifest.get("launch_requested", false))
	var screenshots_ready: bool = (
		bool(acceptance_manifest.get("screenshot_written", false))
		and bool(acceptance_manifest.get("host_screenshot_written", false))
		and bool(acceptance_manifest.get("client_screenshot_written", false))
	)
	var technical_packet_ready: bool = blocking_count == 0
	var manual_acceptance_open: bool = technical_packet_ready and review_required and not review_done
	var host_client_findings_ready: bool = technical_packet_ready and gate == "review_ready" and (launch_requested or screenshots_ready)
	var status: String = _build_status(blocking_count, warning_count, manual_acceptance_open, host_client_findings_ready, review_done)
	return {
		"schema": SNAPSHOT_SCHEMA,
		"runtime_authority": "read-only TASK_712 host/client acceptance packet findings",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"source_schema": String(acceptance_manifest.get("schema", "")),
		"source_manifest_path": String(options.get("source_manifest_path", DEFAULT_SOURCE_MANIFEST_PATH)),
		"source_acceptance_task_id": String(acceptance_manifest.get("station_route_host_client_acceptance_task_id", "")),
		"source_visual_evidence_task_id": String(acceptance_manifest.get("station_route_source_visual_evidence_task_id", "")),
		"source_window_notes_task_id": String(acceptance_manifest.get("station_route_source_window_notes_task_id", "")),
		"source_readiness_task_id": String(acceptance_manifest.get("station_route_source_readiness_task_id", "")),
		"station_route_packet_present": not acceptance_manifest.is_empty(),
		"acceptance_packet_task_id": String(acceptance_manifest.get("station_route_host_client_acceptance_task_id", "")),
		"manual_review_required": review_required,
		"manual_review_done": review_done,
		"acceptance_gate": gate,
		"launch_requested": launch_requested,
		"real_run_done": bool(acceptance_manifest.get("real_run_done", false)),
		"screenshot_written": bool(acceptance_manifest.get("screenshot_written", false)),
		"host_screenshot_written": bool(acceptance_manifest.get("host_screenshot_written", false)),
		"client_screenshot_written": bool(acceptance_manifest.get("client_screenshot_written", false)),
		"screenshots_ready": screenshots_ready,
		"expected_sequence": Array(acceptance_manifest.get("station_route_expected_sequence", [])),
		"manual_checks": Array(acceptance_manifest.get("station_route_host_client_manual_checks", [])),
		"review_checks": Array(acceptance_manifest.get("review_checks", [])),
		"expected_wrong_team_reason": String(acceptance_manifest.get("station_route_expected_wrong_team_reason", "")),
		"expected_snapshot_sync": String(acceptance_manifest.get("station_route_expected_snapshot_sync", "")),
		"blocking_issue_count": blocking_count,
		"warning_count": warning_count,
		"manual_note_count": manual_count,
		"findings": findings,
		"technical_packet_ready": technical_packet_ready,
		"manual_acceptance_open": manual_acceptance_open,
		"host_client_findings_ready": host_client_findings_ready,
		"status": status,
		"summary": _build_summary(status, blocking_count, warning_count, manual_count),
		"recommended_next_task": _recommended_next_task(status),
		"report_path": DEFAULT_REPORT_PATH,
		"manifest_path": DEFAULT_MANIFEST_PATH,
	}


static func _add_manifest_findings(findings: Array, manifest: Dictionary) -> void:
	if manifest.is_empty():
		findings.append(_finding("missing_acceptance_packet", "blocker", "TASK_712 Host/Client-Acceptance-Manifest fehlt.", "TASK_712 - Station Route Host/Client Acceptance Packet"))
		return
	if String(manifest.get("schema", "")) != EXPECTED_SOURCE_SCHEMA:
		findings.append(_finding("unexpected_acceptance_schema", "blocker", "Host/Client-Acceptance-Manifest hat ein unerwartetes Schema.", "TASK_712 regression"))
	if String(manifest.get("station_route_host_client_acceptance_task_id", "")) != EXPECTED_ACCEPTANCE_TASK_ID:
		findings.append(_finding("wrong_acceptance_task_id", "blocker", "Station-Route-Acceptance-Paket verweist nicht auf TASK_712.", "TASK_712 regression"))
	if not bool(manifest.get("read_only", false)) or bool(manifest.get("ui_sets_gameplay_truth", true)):
		findings.append(_finding("acceptance_packet_not_readonly", "blocker", "Acceptance-Paket verletzt read-only/UI-Truth-Regel.", "TASK_712 regression"))
	_add_expected_source_task_findings(findings, manifest)
	_add_sequence_findings(findings, manifest)
	_add_check_findings(findings, manifest)
	_add_runtime_gate_findings(findings, manifest)


static func _add_expected_source_task_findings(findings: Array, manifest: Dictionary) -> void:
	var expected_sources: Dictionary = {
		"station_route_source_visual_evidence_task_id": "TASK_708",
		"station_route_source_window_notes_task_id": "TASK_709",
		"station_route_source_readiness_task_id": "TASK_710",
	}
	for key in expected_sources.keys():
		if String(manifest.get(key, "")) != String(expected_sources[key]):
			findings.append(_finding("unexpected_%s" % key, "warning", "Acceptance-Paket verweist nicht auf die erwartete Quelle %s." % expected_sources[key], "TASK_712 packet refresh"))


static func _add_sequence_findings(findings: Array, manifest: Dictionary) -> void:
	var sequence: Array = Array(manifest.get("station_route_expected_sequence", []))
	for step_id in REQUIRED_SEQUENCE:
		if not _array_contains_string(sequence, step_id):
			findings.append(_finding("missing_sequence_%s" % step_id, "blocker", "Erwartete Station-Route-Sequenz fehlt: %s." % step_id, "TASK_712 regression"))
	if String(manifest.get("station_route_expected_wrong_team_reason", "")) != "peer_team_mismatch":
		findings.append(_finding("wrong_team_reason_missing", "warning", "Wrong-Team-Reject ist nicht eindeutig als peer_team_mismatch beschrieben.", "TASK_712 packet refresh"))
	if String(manifest.get("station_route_expected_snapshot_sync", "")) != "client_snapshot_apply_accepted":
		findings.append(_finding("snapshot_sync_expectation_missing", "warning", "Snapshot-Sync-Erwartung ist nicht eindeutig beschrieben.", "TASK_712 packet refresh"))


static func _add_check_findings(findings: Array, manifest: Dictionary) -> void:
	var manual_checks: Array = Array(manifest.get("station_route_host_client_manual_checks", []))
	for check_id in REQUIRED_MANUAL_CHECKS:
		if not _array_contains_string(manual_checks, check_id):
			findings.append(_finding("missing_manual_check_%s" % check_id, "blocker", "Manual-Check fehlt: %s." % check_id, "TASK_712 regression"))
	var review_checks: Array = Array(manifest.get("review_checks", []))
	for check_id in REQUIRED_REVIEW_CHECKS:
		if not _array_contains_string(review_checks, check_id):
			findings.append(_finding("missing_review_check_%s" % check_id, "blocker", "Review-Check fehlt: %s." % check_id, "TASK_712 regression"))


static func _add_runtime_gate_findings(findings: Array, manifest: Dictionary) -> void:
	var gate: String = String(manifest.get("station_route_host_client_acceptance_gate", ""))
	var review_required: bool = bool(manifest.get("station_route_host_client_acceptance_review_required", false))
	var review_done: bool = bool(manifest.get("station_route_host_client_acceptance_review_done", false))
	if not review_required:
		findings.append(_finding("manual_review_not_required", "blocker", "Acceptance-Paket darf den echten Host/Client-Review nicht abwaehlen.", "TASK_712 regression"))
	if gate not in ["manual_open", "review_ready"]:
		findings.append(_finding("invalid_acceptance_gate", "blocker", "Acceptance-Gate ist weder manual_open noch review_ready.", "TASK_712 regression"))
	if gate == "manual_open" and not review_done:
		findings.append(_finding("manual_acceptance_open", "manual", "Echter Station-Route-Host/Client-Lauf ist noch offen.", "TASK_712 real run"))
	if gate == "review_ready" and not review_done:
		findings.append(_finding("findings_review_open", "manual", "Fensterartefakte sind bereit, aber der Findings-Entscheid ist noch offen.", "TASK_713 review"))
	if review_done:
		var real_run_done: bool = bool(manifest.get("real_run_done", false))
		var screenshots_ready: bool = (
			bool(manifest.get("screenshot_written", false))
			and bool(manifest.get("host_screenshot_written", false))
			and bool(manifest.get("client_screenshot_written", false))
		)
		if not real_run_done or not screenshots_ready:
			findings.append(_finding("review_done_without_real_run_evidence", "blocker", "Review ist erledigt markiert, aber Real-Run-/Screenshot-Evidence fehlt.", "TASK_712 real run"))


static func _finding(id: String, severity: String, message: String, suggested_next: String) -> Dictionary:
	return {
		"id": id,
		"severity": severity,
		"message": message,
		"suggested_next": suggested_next,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _array_contains_string(values: Array, needle: String) -> bool:
	for value in values:
		if String(value) == needle:
			return true
	return false


static func _count_findings_by_severity(findings: Array, severity: String) -> int:
	var count: int = 0
	for finding_variant in findings:
		if typeof(finding_variant) == TYPE_DICTIONARY and String(Dictionary(finding_variant).get("severity", "")) == severity:
			count += 1
	return count


static func _build_status(blocking_count: int, warning_count: int, manual_open: bool, findings_ready: bool, review_done: bool) -> String:
	if blocking_count > 0:
		return "blocked"
	if review_done and warning_count == 0:
		return "accepted"
	if findings_ready:
		return "ready_for_findings_review"
	if manual_open:
		return "needs_real_run"
	if warning_count > 0:
		return "needs_packet_polish"
	return "needs_real_run"


static func _build_summary(status: String, blocking_count: int, warning_count: int, manual_count: int) -> String:
	if status == "blocked":
		return "%d technische Blocker, %d Warnungen, %d manuelle Hinweise" % [blocking_count, warning_count, manual_count]
	if status == "ready_for_findings_review":
		return "technisch bereit, echter Host/Client-Befund muss bewertet werden"
	if status == "accepted":
		return "Station-Route-Host/Client-Befund akzeptiert"
	if status == "needs_packet_polish":
		return "keine Blocker, aber %d Paket-Warnungen" % warning_count
	return "echter Station-Route-Host/Client-Lauf offen"


static func _recommended_next_task(status: String) -> String:
	if status == "blocked":
		return "TASK_712 - Station Route Host/Client Acceptance Packet"
	if status == "ready_for_findings_review":
		return "TASK_713 - Station Route Host/Client Findings Review"
	if status == "accepted":
		return "TASK_714 - Station Route Multiplayer Polish/Scenario"
	if status == "needs_packet_polish":
		return "TASK_713 - Station Route Host/Client Findings Packet Polish"
	return "TASK_712 - Execute Station Route Host/Client Real Run"
