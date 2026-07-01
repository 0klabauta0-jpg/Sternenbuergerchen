class_name StationRouteRealClickFindings
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_route_real_click_findings.v1"
const EXPECTED_CAPTURE_SCHEMA: String = "sternenbuergerchen.host_client_two_window_real_run_review.v1"
const EXPECTED_ROUTE_SCHEMA: String = "sternenbuergerchen.station_route_run_readout_polish.v1"
const EXPECTED_ACCEPTANCE_TASK_ID: String = "TASK_712"
const EXPECTED_ROUTE_TASK_ID: String = "TASK_716"
const DEFAULT_CAPTURE_MANIFEST_PATH: String = "tmp/host_client_two_window_real_run_review.json"
const DEFAULT_ROUTE_MANIFEST_PATH: String = "tmp/station_route_run_readout_polish.json"
const DEFAULT_MANIFEST_PATH: String = "tmp/station_route_real_click_findings.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/project_current_state_handbook_refresh_2026_06_30.html"

const REQUIRED_STATION_ROUTE_REVIEW_CHECKS: Array[String] = [
	"station_route_host_window_visible",
	"station_route_client_window_visible",
	"station_route_door_open_host_client",
	"station_route_computer_control_visible",
	"station_route_cargo_departed_visible",
	"station_route_wrong_team_reject",
	"station_route_snapshot_sync",
]

const REQUIRED_ROUTE_LINE_TOKENS: Array[String] = [
	"AA OK",
	"DOOR OPEN",
	"COM CTRL",
	"CARGO DEPARTED",
	"NEXT DONE",
]


static func build_snapshot(capture_manifest: Dictionary = {}, route_manifest: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var findings: Array = []
	_add_capture_findings(findings, capture_manifest)
	_add_route_readout_findings(findings, route_manifest)
	var blocking_count: int = _count_findings_by_severity(findings, "blocker")
	var warning_count: int = _count_findings_by_severity(findings, "warning")
	var manual_count: int = _count_findings_by_severity(findings, "manual")
	var capture_ready: bool = _capture_ready(capture_manifest)
	var route_ready: bool = _route_ready(route_manifest)
	var manual_review_done: bool = bool(capture_manifest.get("station_route_host_client_acceptance_review_done", false))
	if blocking_count == 0 and capture_ready and route_ready and not manual_review_done:
		findings.append(_finding("manual_click_findings_open", "manual", "Echter Station-Route-Host/Client-Klickbefund ist auswertbar, aber noch nicht bewusst entschieden.", "TASK_717 manual findings review"))
		manual_count += 1
	var status: String = _build_status(blocking_count, warning_count, capture_ready, route_ready, manual_review_done)
	return {
		"schema": SNAPSHOT_SCHEMA,
		"runtime_authority": "read-only host/client capture and route readout findings",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"capture_schema": String(capture_manifest.get("schema", "")),
		"route_schema": String(route_manifest.get("schema", "")),
		"capture_manifest_path": String(options.get("capture_manifest_path", DEFAULT_CAPTURE_MANIFEST_PATH)),
		"route_manifest_path": String(options.get("route_manifest_path", DEFAULT_ROUTE_MANIFEST_PATH)),
		"station_route_acceptance_task_id": String(capture_manifest.get("station_route_host_client_acceptance_task_id", "")),
		"route_readout_task_id": String(route_manifest.get("task_id", "")),
		"capture_present": not capture_manifest.is_empty(),
		"route_readout_present": not route_manifest.is_empty(),
		"capture_ready": capture_ready,
		"route_readout_ready": route_ready,
		"manual_review_required": bool(capture_manifest.get("station_route_host_client_acceptance_review_required", true)),
		"manual_review_done": manual_review_done,
		"real_run_done": bool(capture_manifest.get("real_run_done", false)),
		"screenshot_written": bool(capture_manifest.get("screenshot_written", false)),
		"host_screenshot_written": bool(capture_manifest.get("host_screenshot_written", false)),
		"client_screenshot_written": bool(capture_manifest.get("client_screenshot_written", false)),
		"acceptance_gate": String(capture_manifest.get("station_route_host_client_acceptance_gate", "")),
		"route_line": String(route_manifest.get("cargo_line", route_manifest.get("door_line", ""))).strip_edges(),
		"route_final_next_token": String(route_manifest.get("final_next_token", "")),
		"route_line_within_limit": bool(route_manifest.get("line_within_limit", false)),
		"blocking_issue_count": blocking_count,
		"warning_count": warning_count,
		"manual_note_count": manual_count,
		"findings": findings,
		"status": status,
		"summary": _build_summary(status, blocking_count, warning_count, manual_count),
		"recommended_next_task": _recommended_next_task(status),
		"report_path": DEFAULT_REPORT_PATH,
		"manifest_path": DEFAULT_MANIFEST_PATH,
	}


static func _add_capture_findings(findings: Array, manifest: Dictionary) -> void:
	if manifest.is_empty():
		findings.append(_finding("missing_capture_manifest", "blocker", "Host/Client-Capture-Manifest fehlt.", "TASK_712/TASK_614 capture rerun"))
		return
	if String(manifest.get("schema", "")) != EXPECTED_CAPTURE_SCHEMA:
		findings.append(_finding("unexpected_capture_schema", "blocker", "Host/Client-Capture hat ein unerwartetes Schema.", "Capture packet refresh"))
	if String(manifest.get("station_route_host_client_acceptance_task_id", "")) != EXPECTED_ACCEPTANCE_TASK_ID:
		findings.append(_finding("wrong_acceptance_task_id", "blocker", "Capture verweist nicht auf TASK_712 Station-Route-Acceptance.", "TASK_712 regression"))
	if not bool(manifest.get("read_only", false)) or bool(manifest.get("ui_sets_gameplay_truth", true)):
		findings.append(_finding("capture_not_readonly", "blocker", "Capture verletzt read-only/UI-Truth-Regel.", "Capture packet refresh"))
	if not bool(manifest.get("real_run_done", false)):
		findings.append(_finding("real_run_not_done", "blocker", "Echter Zwei-Fenster-Run wurde nicht als erledigt erfasst.", "TASK_712 real run"))
	if not (bool(manifest.get("screenshot_written", false)) and bool(manifest.get("host_screenshot_written", false)) and bool(manifest.get("client_screenshot_written", false))):
		findings.append(_finding("screenshots_missing", "blocker", "Host/Client-Screenshot-Evidence ist unvollstaendig.", "TASK_712 capture rerun"))
	if String(manifest.get("station_route_host_client_acceptance_gate", "")) != "review_ready":
		findings.append(_finding("acceptance_not_review_ready", "warning", "Station-Route-Acceptance-Gate ist nicht review_ready.", "TASK_712 real run"))
	for check_id in REQUIRED_STATION_ROUTE_REVIEW_CHECKS:
		if not _array_contains_string(Array(manifest.get("review_checks", [])), check_id):
			findings.append(_finding("missing_review_check_%s" % check_id, "blocker", "Review-Check fehlt: %s." % check_id, "TASK_712 packet refresh"))


static func _add_route_readout_findings(findings: Array, manifest: Dictionary) -> void:
	if manifest.is_empty():
		findings.append(_finding("missing_route_readout_manifest", "blocker", "TASK_716 Route-Readout-Manifest fehlt.", "TASK_716 rerun"))
		return
	if String(manifest.get("schema", "")) != EXPECTED_ROUTE_SCHEMA:
		findings.append(_finding("unexpected_route_schema", "blocker", "Route-Readout-Manifest hat ein unerwartetes Schema.", "TASK_716 regression"))
	if String(manifest.get("task_id", "")) != EXPECTED_ROUTE_TASK_ID:
		findings.append(_finding("wrong_route_task_id", "blocker", "Route-Readout-Manifest verweist nicht auf TASK_716.", "TASK_716 regression"))
	if not bool(manifest.get("read_only", false)) or bool(manifest.get("ui_sets_gameplay_truth", true)):
		findings.append(_finding("route_not_readonly", "blocker", "Route-Readout verletzt read-only/UI-Truth-Regel.", "TASK_716 regression"))
	var route_line: String = String(manifest.get("cargo_line", "")).strip_edges()
	if route_line.is_empty():
		route_line = String(manifest.get("door_line", "")).strip_edges()
	for token in REQUIRED_ROUTE_LINE_TOKENS:
		if not route_line.contains(token):
			findings.append(_finding("route_line_missing_%s" % token.to_lower().replace(" ", "_"), "blocker", "Route-Line fehlt Token: %s." % token, "TASK_716 regression"))
	if String(manifest.get("final_next_token", "")) != "DONE":
		findings.append(_finding("route_final_not_done", "blocker", "Route-Readout endet nicht mit NEXT DONE.", "TASK_716 regression"))
	if not bool(manifest.get("line_within_limit", false)):
		findings.append(_finding("route_line_too_long", "warning", "Route-Line ueberschreitet ihr Zeichenlimit.", "TASK_716 HUD polish"))


static func _capture_ready(manifest: Dictionary) -> bool:
	return (
		not manifest.is_empty()
		and String(manifest.get("schema", "")) == EXPECTED_CAPTURE_SCHEMA
		and bool(manifest.get("real_run_done", false))
		and bool(manifest.get("screenshot_written", false))
		and bool(manifest.get("host_screenshot_written", false))
		and bool(manifest.get("client_screenshot_written", false))
	)


static func _route_ready(manifest: Dictionary) -> bool:
	if manifest.is_empty():
		return false
	var route_line: String = String(manifest.get("cargo_line", "")).strip_edges()
	return (
		String(manifest.get("schema", "")) == EXPECTED_ROUTE_SCHEMA
		and String(manifest.get("task_id", "")) == EXPECTED_ROUTE_TASK_ID
		and bool(manifest.get("read_only", false))
		and not bool(manifest.get("ui_sets_gameplay_truth", true))
		and String(manifest.get("final_next_token", "")) == "DONE"
		and bool(manifest.get("line_within_limit", false))
		and route_line.contains("DOOR OPEN")
		and route_line.contains("COM CTRL")
		and route_line.contains("CARGO DEPARTED")
	)


static func _build_status(blocking_count: int, warning_count: int, capture_ready: bool, route_ready: bool, manual_review_done: bool) -> String:
	if blocking_count > 0:
		return "blocked"
	if not capture_ready:
		return "needs_real_run"
	if not route_ready:
		return "needs_route_readout"
	if manual_review_done and warning_count == 0:
		return "accepted"
	if warning_count > 0:
		return "ready_with_warnings"
	return "ready_for_click_findings_review"


static func _build_summary(status: String, blocking_count: int, warning_count: int, manual_count: int) -> String:
	if status == "blocked":
		return "%d technische Blocker, %d Warnungen, %d manuelle Hinweise" % [blocking_count, warning_count, manual_count]
	if status == "needs_real_run":
		return "echter Host/Client-Klicklauf fehlt"
	if status == "needs_route_readout":
		return "Route-Readout-Evidence fehlt"
	if status == "accepted":
		return "Station-Route-Klickbefund akzeptiert"
	if status == "ready_with_warnings":
		return "auswertbar mit %d Warnungen" % warning_count
	return "Capture und Route-Line sind bereit; manueller Klickbefund offen"


static func _recommended_next_task(status: String) -> String:
	if status == "blocked":
		return "TASK_712/TASK_716 - refresh Station Route evidence"
	if status == "needs_real_run":
		return "TASK_712 - execute Station Route Host/Client real run"
	if status == "needs_route_readout":
		return "TASK_716 - Station Route Run Readout Polish"
	if status == "accepted":
		return "TASK_718 - Station Route Door/GO/Reject Visual Polish"
	return "TASK_718 - Station Route Door/GO/Reject Visual Polish"


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
