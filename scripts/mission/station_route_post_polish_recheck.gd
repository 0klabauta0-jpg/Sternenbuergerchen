class_name StationRoutePostPolishRecheck
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_route_post_polish_recheck.v1"
const EXPECTED_CAPTURE_SCHEMA: String = "sternenbuergerchen.host_client_two_window_real_run_review.v1"
const EXPECTED_POLISH_SCHEMA: String = "sternenbuergerchen.station_route_door_go_reject_visual_polish.v1"
const EXPECTED_CAPTURE_TASK_ID: String = "TASK_712"
const EXPECTED_POLISH_TASK_ID: String = "TASK_718"
const EXPECTED_READY_LINE: String = "DOOR B->GO"
const EXPECTED_OPEN_LINE: String = "DOOR OPEN"
const DEFAULT_CAPTURE_MANIFEST_PATH: String = "tmp/host_client_two_window_real_run_review.json"
const DEFAULT_POLISH_MANIFEST_PATH: String = "tmp/station_route_door_go_reject_visual_polish.json"
const DEFAULT_MANIFEST_PATH: String = "tmp/station_route_post_polish_recheck.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/project_current_state_handbook_refresh_2026_06_30.html"


static func build_snapshot(capture_manifest: Dictionary = {}, polish_manifest: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var findings: Array = []
	_add_polish_findings(findings, polish_manifest)
	_add_capture_findings(findings, capture_manifest)
	var blocking_count: int = _count_findings_by_severity(findings, "blocker")
	var warning_count: int = _count_findings_by_severity(findings, "warning")
	var stale_count: int = _count_findings_by_severity(findings, "stale")
	var manual_count: int = _count_findings_by_severity(findings, "manual")
	var polish_ready: bool = _polish_ready(polish_manifest)
	var capture_present: bool = not capture_manifest.is_empty()
	var capture_fresh: bool = _capture_fresh(capture_manifest)
	var real_run_done: bool = bool(capture_manifest.get("real_run_done", false))
	var manual_review_done: bool = bool(capture_manifest.get("station_route_host_client_acceptance_review_done", false))
	if blocking_count == 0 and polish_ready and capture_fresh and real_run_done and not manual_review_done:
		findings.append(_finding("real_window_review_open", "manual", "Capture-Erwartungen sind frisch; echter Fensterbefund bleibt bewusst offen.", "TASK_719 real window recheck"))
		manual_count += 1
	var status: String = _build_status(blocking_count, stale_count, polish_ready, capture_present, capture_fresh, real_run_done, manual_review_done)
	return {
		"schema": SNAPSHOT_SCHEMA,
		"runtime_authority": "read-only capture freshness and TASK_718 polish recheck",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"capture_manifest_path": String(options.get("capture_manifest_path", DEFAULT_CAPTURE_MANIFEST_PATH)),
		"polish_manifest_path": String(options.get("polish_manifest_path", DEFAULT_POLISH_MANIFEST_PATH)),
		"capture_schema": String(capture_manifest.get("schema", "")),
		"polish_schema": String(polish_manifest.get("schema", "")),
		"capture_present": capture_present,
		"polish_present": not polish_manifest.is_empty(),
		"polish_ready": polish_ready,
		"capture_fresh": capture_fresh,
		"real_run_done": real_run_done,
		"manual_review_done": manual_review_done,
		"expected_ready_line": EXPECTED_READY_LINE,
		"expected_open_line": EXPECTED_OPEN_LINE,
		"capture_ready_line": String(capture_manifest.get("door_real_click_expected_ready_line", "")),
		"capture_open_line": String(capture_manifest.get("door_real_click_expected_open_line", "")),
		"capture_station_route_door_line": String(capture_manifest.get("station_route_expected_door_line", "")),
		"polish_compact_line": String(polish_manifest.get("compact_line", polish_manifest.get("ready_line", ""))),
		"polish_button_text": String(polish_manifest.get("button_text", "")),
		"blocking_issue_count": blocking_count,
		"warning_count": warning_count,
		"stale_count": stale_count,
		"manual_note_count": manual_count,
		"findings": findings,
		"status": status,
		"summary": _build_summary(status, stale_count, manual_count),
		"recommended_next_task": _recommended_next_task(status),
		"report_path": DEFAULT_REPORT_PATH,
		"manifest_path": DEFAULT_MANIFEST_PATH,
	}


static func _add_polish_findings(findings: Array, manifest: Dictionary) -> void:
	if manifest.is_empty():
		findings.append(_finding("missing_task_718_polish_manifest", "blocker", "TASK_718-Polish-Manifest fehlt.", "TASK_718 rerun"))
		return
	if String(manifest.get("schema", "")) != EXPECTED_POLISH_SCHEMA:
		findings.append(_finding("unexpected_polish_schema", "blocker", "TASK_718-Polish-Manifest hat ein unerwartetes Schema.", "TASK_718 regression"))
	if String(manifest.get("task_id", "")) != EXPECTED_POLISH_TASK_ID:
		findings.append(_finding("wrong_polish_task_id", "blocker", "Polish-Manifest verweist nicht auf TASK_718.", "TASK_718 regression"))
	if not bool(manifest.get("read_only", false)) or bool(manifest.get("ui_sets_gameplay_truth", true)):
		findings.append(_finding("polish_not_readonly", "blocker", "Polish-Manifest verletzt read-only/UI-Truth-Regel.", "TASK_718 regression"))
	var compact_line: String = String(manifest.get("compact_line", manifest.get("ready_line", ""))).strip_edges()
	if compact_line.contains("DOOR DOOR"):
		findings.append(_finding("polish_line_duplicates_door", "blocker", "TASK_718-Polish-Line enthaelt weiter doppelte Door-Tokens.", "TASK_718 regression"))
	if not compact_line.contains("B->GO"):
		findings.append(_finding("polish_line_missing_go_hint", "blocker", "TASK_718-Polish-Line nennt B->GO nicht.", "TASK_718 regression"))
	if String(manifest.get("button_text", "")).strip_edges() != "B->GO":
		findings.append(_finding("polish_button_not_go_hint", "warning", "TASK_718-Manifest belegt keinen B->GO-Buttontext.", "TASK_718 visual recheck"))


static func _add_capture_findings(findings: Array, manifest: Dictionary) -> void:
	if manifest.is_empty():
		findings.append(_finding("missing_capture_manifest", "stale", "Echtes Capture-Manifest fehlt fuer den Post-Polish-Recheck.", "TASK_712/TASK_719 capture refresh"))
		return
	if String(manifest.get("schema", "")) != EXPECTED_CAPTURE_SCHEMA:
		findings.append(_finding("unexpected_capture_schema", "blocker", "Capture-Manifest hat ein unerwartetes Schema.", "TASK_712 capture refresh"))
	if String(manifest.get("station_route_host_client_acceptance_task_id", "")) != EXPECTED_CAPTURE_TASK_ID:
		findings.append(_finding("wrong_capture_task_id", "blocker", "Capture-Manifest verweist nicht auf TASK_712 Station-Route-Acceptance.", "TASK_712 capture refresh"))
	if not bool(manifest.get("read_only", false)) or bool(manifest.get("ui_sets_gameplay_truth", true)):
		findings.append(_finding("capture_not_readonly", "blocker", "Capture-Manifest verletzt read-only/UI-Truth-Regel.", "TASK_712 capture refresh"))
	if String(manifest.get("door_real_click_expected_ready_line", "")) != EXPECTED_READY_LINE:
		findings.append(_finding("capture_ready_line_stale", "stale", "Capture erwartet nicht die aktuelle Ready-Line `%s`." % EXPECTED_READY_LINE, "TASK_719 capture refresh"))
	if String(manifest.get("door_real_click_expected_open_line", "")) != EXPECTED_OPEN_LINE:
		findings.append(_finding("capture_open_line_stale", "stale", "Capture erwartet nicht die aktuelle Open-Line `%s`." % EXPECTED_OPEN_LINE, "TASK_719 capture refresh"))
	if String(manifest.get("station_route_expected_door_line", "")) != EXPECTED_OPEN_LINE:
		findings.append(_finding("capture_station_route_door_line_stale", "stale", "Station-Route-Capture erwartet nicht die aktuelle Door-Line `%s`." % EXPECTED_OPEN_LINE, "TASK_719 capture refresh"))


static func _polish_ready(manifest: Dictionary) -> bool:
	if manifest.is_empty():
		return false
	var compact_line: String = String(manifest.get("compact_line", manifest.get("ready_line", ""))).strip_edges()
	return (
		String(manifest.get("schema", "")) == EXPECTED_POLISH_SCHEMA
		and String(manifest.get("task_id", "")) == EXPECTED_POLISH_TASK_ID
		and bool(manifest.get("read_only", false))
		and not bool(manifest.get("ui_sets_gameplay_truth", true))
		and compact_line.contains("B->GO")
		and not compact_line.contains("DOOR DOOR")
	)


static func _capture_fresh(manifest: Dictionary) -> bool:
	return (
		not manifest.is_empty()
		and String(manifest.get("schema", "")) == EXPECTED_CAPTURE_SCHEMA
		and String(manifest.get("door_real_click_expected_ready_line", "")) == EXPECTED_READY_LINE
		and String(manifest.get("door_real_click_expected_open_line", "")) == EXPECTED_OPEN_LINE
		and String(manifest.get("station_route_expected_door_line", "")) == EXPECTED_OPEN_LINE
		and bool(manifest.get("read_only", false))
		and not bool(manifest.get("ui_sets_gameplay_truth", true))
	)


static func _build_status(blocking_count: int, stale_count: int, polish_ready: bool, capture_present: bool, capture_fresh: bool, real_run_done: bool, manual_review_done: bool) -> String:
	if blocking_count > 0 or not polish_ready:
		return "blocked"
	if not capture_present or stale_count > 0 or not capture_fresh:
		return "needs_capture_refresh"
	if not real_run_done:
		return "needs_real_run"
	if manual_review_done:
		return "accepted"
	return "ready_for_real_window_recheck"


static func _build_summary(status: String, stale_count: int, manual_count: int) -> String:
	if status == "blocked":
		return "technische Blocker im TASK_718-Polish oder Capture-Contract"
	if status == "needs_capture_refresh":
		return "Capture-Erwartungen sind nach TASK_718 stale (%d stale Hinweise)" % stale_count
	if status == "needs_real_run":
		return "Capture ist frisch, aber echter Fensterlauf fehlt"
	if status == "accepted":
		return "Post-Polish-Fensterbefund akzeptiert"
	return "Capture ist frisch; echter Fensterbefund offen (%d manuelle Hinweise)" % manual_count


static func _recommended_next_task(status: String) -> String:
	if status == "blocked":
		return "TASK_718 - refresh Door/GO/Reject polish evidence"
	if status == "needs_capture_refresh":
		return "TASK_719 - refresh Station Route Host/Client capture"
	if status == "needs_real_run":
		return "TASK_719 - execute Station Route real window recheck"
	if status == "accepted":
		return "TASK_720 - next playable Station Route polish slice"
	return "TASK_720 - accept real window recheck or continue layout polish"


static func _finding(id: String, severity: String, message: String, suggested_next: String) -> Dictionary:
	return {
		"id": id,
		"severity": severity,
		"message": message,
		"suggested_next": suggested_next,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _count_findings_by_severity(findings: Array, severity: String) -> int:
	var count: int = 0
	for finding_variant in findings:
		if typeof(finding_variant) == TYPE_DICTIONARY and String(Dictionary(finding_variant).get("severity", "")) == severity:
			count += 1
	return count
