class_name StationRouteTwoWindowVisualFindings
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_route_two_window_visual_findings.v1"
const EXPECTED_CAPTURE_SCHEMA: String = "sternenbuergerchen.host_client_two_window_real_run_review.v1"
const EXPECTED_RECHECK_SCHEMA: String = "sternenbuergerchen.station_route_post_polish_recheck.v1"
const DEFAULT_CAPTURE_MANIFEST_PATH: String = "tmp/host_client_two_window_real_run_review.json"
const DEFAULT_RECHECK_MANIFEST_PATH: String = "tmp/station_route_post_polish_recheck.json"
const DEFAULT_MANIFEST_PATH: String = "tmp/station_route_two_window_visual_findings.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/project_current_state_handbook_2026_07_01.html"

const REQUIRED_REVIEW_KEYS: Array[String] = [
	"host_role_badge_readable",
	"client_role_badge_readable",
	"host_map_visible",
	"client_map_visible",
	"door_station_route_visible",
]

const POLISH_FLAGS: Array[String] = [
	"fireteam_cards_cover_map",
	"station_labels_too_small",
	"orphan_nav_placeholder_visible",
	"door_route_labels_crowded",
]


static func build_snapshot(capture_manifest: Dictionary = {}, recheck_manifest: Dictionary = {}, visual_review: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var findings: Array = []
	_add_capture_findings(findings, capture_manifest)
	_add_recheck_findings(findings, recheck_manifest)
	_add_visual_findings(findings, visual_review)
	var blocking_count: int = _count_findings_by_severity(findings, "blocker")
	var polish_count: int = _count_findings_by_severity(findings, "polish")
	var manual_count: int = _count_findings_by_severity(findings, "manual")
	var capture_ready: bool = _capture_ready(capture_manifest)
	var recheck_ready: bool = _recheck_ready(recheck_manifest)
	var visual_review_done: bool = bool(visual_review.get("visual_review_done", false))
	var status: String = _build_status(blocking_count, polish_count, capture_ready, recheck_ready, visual_review_done)
	return {
		"schema": SNAPSHOT_SCHEMA,
		"runtime_authority": "read-only visual findings over host/client capture screenshots",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"capture_manifest_path": String(options.get("capture_manifest_path", DEFAULT_CAPTURE_MANIFEST_PATH)),
		"recheck_manifest_path": String(options.get("recheck_manifest_path", DEFAULT_RECHECK_MANIFEST_PATH)),
		"capture_schema": String(capture_manifest.get("schema", "")),
		"recheck_schema": String(recheck_manifest.get("schema", "")),
		"host_screenshot_path": String(capture_manifest.get("host_screenshot_path", "")),
		"client_screenshot_path": String(capture_manifest.get("client_screenshot_path", "")),
		"capture_ready": capture_ready,
		"post_polish_recheck_ready": recheck_ready,
		"visual_review_done": visual_review_done,
		"visual_decision": String(visual_review.get("visual_decision", "")),
		"blocking_issue_count": blocking_count,
		"visual_polish_issue_count": polish_count,
		"manual_note_count": manual_count,
		"findings": findings,
		"status": status,
		"summary": _build_summary(status, polish_count, manual_count),
		"recommended_next_task": _recommended_next_task(status),
		"report_path": DEFAULT_REPORT_PATH,
		"manifest_path": DEFAULT_MANIFEST_PATH,
	}


static func _add_capture_findings(findings: Array, manifest: Dictionary) -> void:
	if manifest.is_empty():
		findings.append(_finding("missing_capture_manifest", "blocker", "Host/Client-Capture-Manifest fehlt.", "TASK_720 capture rerun"))
		return
	if String(manifest.get("schema", "")) != EXPECTED_CAPTURE_SCHEMA:
		findings.append(_finding("unexpected_capture_schema", "blocker", "Capture-Manifest hat ein unerwartetes Schema.", "TASK_720 capture rerun"))
	if not bool(manifest.get("real_run_done", false)):
		findings.append(_finding("real_run_not_done", "blocker", "Zwei-Fenster-Run wurde nicht als real_run_done erfasst.", "TASK_720 capture rerun"))
	if not bool(manifest.get("host_screenshot_written", false)):
		findings.append(_finding("host_screenshot_missing", "blocker", "Host-Screenshot fehlt.", "TASK_720 capture rerun"))
	if not bool(manifest.get("client_screenshot_written", false)):
		findings.append(_finding("client_screenshot_missing", "blocker", "Client-Screenshot fehlt.", "TASK_720 capture rerun"))
	if not bool(manifest.get("read_only", false)) or bool(manifest.get("ui_sets_gameplay_truth", true)):
		findings.append(_finding("capture_not_readonly", "blocker", "Capture verletzt read-only/UI-Truth-Regel.", "TASK_720 capture rerun"))


static func _add_recheck_findings(findings: Array, manifest: Dictionary) -> void:
	if manifest.is_empty():
		findings.append(_finding("missing_recheck_manifest", "blocker", "TASK_719-Recheck-Manifest fehlt.", "TASK_719 rerun"))
		return
	if String(manifest.get("schema", "")) != EXPECTED_RECHECK_SCHEMA:
		findings.append(_finding("unexpected_recheck_schema", "blocker", "TASK_719-Recheck hat ein unerwartetes Schema.", "TASK_719 rerun"))
	if String(manifest.get("status", "")) != "ready_for_real_window_recheck":
		findings.append(_finding("recheck_not_ready", "blocker", "Post-Polish-Recheck ist nicht bereit fuer den echten Fensterbefund.", "TASK_719 rerun"))
	if not bool(manifest.get("capture_fresh", false)):
		findings.append(_finding("capture_not_fresh", "blocker", "Capture ist laut Recheck nicht frisch.", "TASK_719 capture refresh"))


static func _add_visual_findings(findings: Array, review: Dictionary) -> void:
	if review.is_empty() or not bool(review.get("visual_review_done", false)):
		findings.append(_finding("visual_review_open", "manual", "Host/Client-Screenshots sind technisch vorhanden, aber noch nicht als Sichtbefund bewertet.", "TASK_721 visual review"))
		return
	for key in REQUIRED_REVIEW_KEYS:
		if not bool(review.get(key, false)):
			findings.append(_finding("missing_visual_check_%s" % key, "manual", "Sichtcheck fehlt oder ist negativ: %s." % key, "TASK_721 visual review"))
	for key in POLISH_FLAGS:
		if bool(review.get(key, false)):
			findings.append(_finding("visual_polish_%s" % key, "polish", String(review.get("%s_note" % key, "Sichtbarer UI-Polish-Bedarf: %s." % key)), "TASK_722 station route HUD visual polish"))


static func _capture_ready(manifest: Dictionary) -> bool:
	return (
		not manifest.is_empty()
		and String(manifest.get("schema", "")) == EXPECTED_CAPTURE_SCHEMA
		and bool(manifest.get("real_run_done", false))
		and bool(manifest.get("host_screenshot_written", false))
		and bool(manifest.get("client_screenshot_written", false))
		and bool(manifest.get("read_only", false))
		and not bool(manifest.get("ui_sets_gameplay_truth", true))
	)


static func _recheck_ready(manifest: Dictionary) -> bool:
	return (
		not manifest.is_empty()
		and String(manifest.get("schema", "")) == EXPECTED_RECHECK_SCHEMA
		and String(manifest.get("status", "")) == "ready_for_real_window_recheck"
		and bool(manifest.get("capture_fresh", false))
		and bool(manifest.get("real_run_done", false))
		and bool(manifest.get("read_only", false))
		and not bool(manifest.get("ui_sets_gameplay_truth", true))
	)


static func _build_status(blocking_count: int, polish_count: int, capture_ready: bool, recheck_ready: bool, visual_review_done: bool) -> String:
	if blocking_count > 0:
		return "blocked"
	if not capture_ready:
		return "needs_capture_refresh"
	if not recheck_ready:
		return "needs_post_polish_recheck"
	if not visual_review_done:
		return "needs_visual_review"
	if polish_count > 0:
		return "needs_visual_polish"
	return "ready_for_acceptance_decision"


static func _build_summary(status: String, polish_count: int, manual_count: int) -> String:
	if status == "blocked":
		return "technische Evidence-Blocker verhindern den Sichtentscheid"
	if status == "needs_capture_refresh":
		return "Capture muss neu geschrieben werden"
	if status == "needs_post_polish_recheck":
		return "Post-Polish-Recheck ist nicht bereit"
	if status == "needs_visual_review":
		return "Screenshots sind bereit, aber Sichtbefund fehlt"
	if status == "needs_visual_polish":
		return "%d sichtbare Polish-Punkte, %d manuelle Hinweise" % [polish_count, manual_count]
	return "Sichtbefund ohne Polish-Blocker, bereit fuer Akzeptanzentscheidung"


static func _recommended_next_task(status: String) -> String:
	if status == "blocked" or status == "needs_capture_refresh":
		return "TASK_720 - refresh Station Route Host/Client capture"
	if status == "needs_post_polish_recheck":
		return "TASK_719 - rerun Station Route Post-Polish Recheck"
	if status == "needs_visual_review":
		return "TASK_721 - complete Station Route two-window visual review"
	if status == "needs_visual_polish":
		return "TASK_722 - Station Route HUD Visual Polish"
	return "TASK_722 - accept Station Route two-window result or polish next UX issue"


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
