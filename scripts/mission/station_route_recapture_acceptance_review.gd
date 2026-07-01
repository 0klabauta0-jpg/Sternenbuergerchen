class_name StationRouteRecaptureAcceptanceReview
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_route_recapture_acceptance_review.v1"
const EXPECTED_CAPTURE_SCHEMA: String = "sternenbuergerchen.host_client_two_window_real_run_review.v1"
const EXPECTED_FOLLOWUP_SCHEMA: String = "sternenbuergerchen.station_route_recapture_visual_followup.v1"
const DEFAULT_CAPTURE_MANIFEST_PATH: String = "tmp/host_client_two_window_real_run_review.json"
const DEFAULT_FOLLOWUP_MANIFEST_PATH: String = "tmp/station_route_recapture_visual_followup.json"
const DEFAULT_MANIFEST_PATH: String = "tmp/station_route_recapture_acceptance_review.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/project_current_state_handbook_2026_07_01.html"

const REQUIRED_RECAPTURE_CHECKS: Array[String] = [
	"station_route_visual_followup_acceptance_review",
	"station_route_top_nav_narrower",
	"station_route_fireteam_mini_lower",
	"station_route_labels_more_spaced",
	"station_route_small_multiplayer_slice_acceptance",
]

const REQUIRED_VISUAL_REVIEW_KEYS: Array[String] = [
	"host_map_visible",
	"client_map_visible",
	"top_nav_no_longer_blocks_read",
	"fireteam_mini_no_longer_blocks_primary_route",
	"station_route_labels_readable_enough",
	"door_station_route_visible",
]

const FOLLOWUP_POLISH_FLAGS: Array[String] = [
	"needs_more_hud_polish",
	"needs_more_label_polish",
	"needs_route_camera_reframe",
]


static func build_snapshot(capture_manifest: Dictionary = {}, followup_manifest: Dictionary = {}, visual_review: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var findings: Array = []
	_add_followup_findings(findings, followup_manifest)
	_add_capture_findings(findings, capture_manifest)
	_add_visual_review_findings(findings, visual_review)

	var blocker_count: int = _count_findings_by_severity(findings, "blocker")
	var polish_count: int = _count_findings_by_severity(findings, "polish")
	var manual_count: int = _count_findings_by_severity(findings, "manual")
	var followup_ready: bool = _followup_ready(followup_manifest)
	var recapture_ready: bool = _recapture_ready(capture_manifest)
	var visual_review_done: bool = bool(visual_review.get("visual_review_done", false))
	var status: String = _build_status(blocker_count, followup_ready, recapture_ready, visual_review_done, polish_count, visual_review)

	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_725",
		"runtime_authority": "read-only acceptance review over TASK_724 visual followup and host/client recapture",
		"scope": "station route small multiplayer slice",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"capture_manifest_path": String(options.get("capture_manifest_path", DEFAULT_CAPTURE_MANIFEST_PATH)),
		"followup_manifest_path": String(options.get("followup_manifest_path", DEFAULT_FOLLOWUP_MANIFEST_PATH)),
		"capture_schema": String(capture_manifest.get("schema", "")),
		"followup_schema": String(followup_manifest.get("schema", "")),
		"host_screenshot_path": String(capture_manifest.get("host_screenshot_path", "")),
		"client_screenshot_path": String(capture_manifest.get("client_screenshot_path", "")),
		"followup_ready": followup_ready,
		"recapture_ready": recapture_ready,
		"visual_review_done": visual_review_done,
		"acceptance_decision": String(visual_review.get("acceptance_decision", "")),
		"blocking_issue_count": blocker_count,
		"manual_note_count": manual_count,
		"followup_polish_issue_count": polish_count,
		"findings": findings,
		"status": status,
		"summary": _build_summary(status, polish_count, manual_count),
		"recommended_next_task": _recommended_next_task(status),
		"report_path": DEFAULT_REPORT_PATH,
		"manifest_path": DEFAULT_MANIFEST_PATH,
	}


static func _add_followup_findings(findings: Array, manifest: Dictionary) -> void:
	if manifest.is_empty():
		findings.append(_finding("missing_followup_manifest", "blocker", "TASK_724-Followup-Manifest fehlt.", "TASK_724 verifier rerun"))
		return
	if String(manifest.get("schema", "")) != EXPECTED_FOLLOWUP_SCHEMA:
		findings.append(_finding("unexpected_followup_schema", "blocker", "TASK_724-Followup hat ein unerwartetes Schema.", "TASK_724 verifier rerun"))
	if String(manifest.get("task_id", "")) != "TASK_724":
		findings.append(_finding("unexpected_followup_task", "blocker", "Followup-Manifest gehoert nicht zu TASK_724.", "TASK_724 verifier rerun"))
	if String(manifest.get("gate", "")) != "ready_for_recapture":
		findings.append(_finding("followup_not_ready_for_recapture", "blocker", "TASK_724 meldet nicht ready_for_recapture.", "TASK_724 verifier rerun"))
	if not bool(manifest.get("read_only", false)) or bool(manifest.get("ui_sets_gameplay_truth", true)):
		findings.append(_finding("followup_not_readonly", "blocker", "TASK_724 verletzt read-only/UI-Truth-Regel.", "TASK_724 verifier rerun"))


static func _add_capture_findings(findings: Array, manifest: Dictionary) -> void:
	if manifest.is_empty():
		findings.append(_finding("missing_recapture_manifest", "blocker", "Nach-TASK_724-Host/Client-Recapture fehlt.", "TASK_725 capture rerun"))
		return
	if String(manifest.get("schema", "")) != EXPECTED_CAPTURE_SCHEMA:
		findings.append(_finding("unexpected_capture_schema", "blocker", "Recapture-Manifest hat ein unerwartetes Schema.", "TASK_725 capture rerun"))
	if String(manifest.get("station_route_recapture_visual_followup_task_id", "")) != "TASK_724":
		findings.append(_finding("missing_task_724_recapture_link", "blocker", "Recapture referenziert TASK_724 nicht.", "TASK_725 capture rerun"))
	if String(manifest.get("station_route_recapture_acceptance_review_task_id", "")) != "TASK_725":
		findings.append(_finding("missing_task_725_recapture_link", "blocker", "Recapture referenziert TASK_725 nicht.", "TASK_725 capture script update"))
	if not bool(manifest.get("station_route_visual_followup_recapture_done", false)):
		findings.append(_finding("visual_followup_recapture_not_done", "blocker", "Nach-TASK_724-Recapture wurde nicht als erledigt markiert.", "TASK_725 capture rerun"))
	if String(manifest.get("station_route_visual_followup_recapture_gate", "")) != "review_ready":
		findings.append(_finding("visual_followup_recapture_not_review_ready", "blocker", "Nach-TASK_724-Recapture ist nicht review_ready.", "TASK_725 capture rerun"))
	if not bool(manifest.get("real_run_done", false)):
		findings.append(_finding("real_run_not_done", "blocker", "Zwei-Fenster-Run wurde nicht als real_run_done erfasst.", "TASK_725 capture rerun"))
	if not bool(manifest.get("host_screenshot_written", false)):
		findings.append(_finding("host_screenshot_missing", "blocker", "Host-Screenshot fehlt.", "TASK_725 capture rerun"))
	if not bool(manifest.get("client_screenshot_written", false)):
		findings.append(_finding("client_screenshot_missing", "blocker", "Client-Screenshot fehlt.", "TASK_725 capture rerun"))
	if not bool(manifest.get("read_only", false)) or bool(manifest.get("ui_sets_gameplay_truth", true)):
		findings.append(_finding("capture_not_readonly", "blocker", "Recapture verletzt read-only/UI-Truth-Regel.", "TASK_725 capture rerun"))
	var review_checks: Array = Array(manifest.get("review_checks", []))
	for check in REQUIRED_RECAPTURE_CHECKS:
		if not review_checks.has(check):
			findings.append(_finding("missing_review_check_%s" % check, "blocker", "Recapture-Manifest enthaelt Review-Check nicht: %s." % check, "TASK_725 capture script update"))


static func _add_visual_review_findings(findings: Array, review: Dictionary) -> void:
	if review.is_empty() or not bool(review.get("visual_review_done", false)):
		findings.append(_finding("visual_review_open", "manual", "Nach-TASK_724-Screenshots sind technisch bereit, aber noch nicht menschlich bewertet.", "TASK_725 visual review"))
		return
	for key in REQUIRED_VISUAL_REVIEW_KEYS:
		if not bool(review.get(key, false)):
			findings.append(_finding("missing_visual_check_%s" % key, "manual", "Sichtcheck fehlt oder ist negativ: %s." % key, "TASK_725 visual review"))
	for key in FOLLOWUP_POLISH_FLAGS:
		if bool(review.get(key, false)):
			findings.append(_finding("followup_polish_%s" % key, "polish", String(review.get("%s_note" % key, "Nach-Recapture sichtbarer Polish-Bedarf: %s." % key)), "TASK_726 station route followup polish"))


static func _recapture_ready(manifest: Dictionary) -> bool:
	if manifest.is_empty():
		return false
	if String(manifest.get("schema", "")) != EXPECTED_CAPTURE_SCHEMA:
		return false
	if not bool(manifest.get("real_run_done", false)):
		return false
	if not bool(manifest.get("host_screenshot_written", false)) or not bool(manifest.get("client_screenshot_written", false)):
		return false
	if not bool(manifest.get("read_only", false)) or bool(manifest.get("ui_sets_gameplay_truth", true)):
		return false
	if String(manifest.get("station_route_recapture_visual_followup_task_id", "")) != "TASK_724":
		return false
	if String(manifest.get("station_route_recapture_acceptance_review_task_id", "")) != "TASK_725":
		return false
	if not bool(manifest.get("station_route_visual_followup_recapture_done", false)):
		return false
	if String(manifest.get("station_route_visual_followup_recapture_gate", "")) != "review_ready":
		return false
	var review_checks: Array = Array(manifest.get("review_checks", []))
	for check in REQUIRED_RECAPTURE_CHECKS:
		if not review_checks.has(check):
			return false
	return true


static func _followup_ready(manifest: Dictionary) -> bool:
	return (
		not manifest.is_empty()
		and String(manifest.get("schema", "")) == EXPECTED_FOLLOWUP_SCHEMA
		and String(manifest.get("task_id", "")) == "TASK_724"
		and String(manifest.get("gate", "")) == "ready_for_recapture"
		and bool(manifest.get("read_only", false))
		and not bool(manifest.get("ui_sets_gameplay_truth", true))
	)


static func _build_status(blocker_count: int, followup_ready: bool, recapture_ready: bool, visual_review_done: bool, polish_count: int, review: Dictionary) -> String:
	if blocker_count > 0:
		return "blocked"
	if not followup_ready or not recapture_ready:
		return "needs_recapture"
	if not visual_review_done:
		return "needs_visual_review"
	if polish_count > 0:
		return "needs_followup_polish"
	if String(review.get("acceptance_decision", "")) == "accepted_for_next_slice":
		return "accepted_for_next_slice"
	return "ready_for_acceptance_decision"


static func _build_summary(status: String, polish_count: int, manual_count: int) -> String:
	if status == "blocked":
		return "technische Recapture- oder Followup-Evidence fehlt"
	if status == "needs_recapture":
		return "nach TASK_724 muss der Host/Client-Recapture neu geschrieben werden"
	if status == "needs_visual_review":
		return "Recapture ist bereit, menschlicher Sichtentscheid steht aus"
	if status == "needs_followup_polish":
		return "%d sichtbare Folge-Polish-Punkte, %d manuelle Hinweise" % [polish_count, manual_count]
	if status == "accepted_for_next_slice":
		return "kleiner Station-Route-Multiplayer-Slice ist gut genug fuer den naechsten Spieltest-Slice"
	return "Recapture-Sichtbefund ist sauber, Akzeptanzentscheidung fehlt noch"


static func _recommended_next_task(status: String) -> String:
	if status == "blocked" or status == "needs_recapture":
		return "TASK_725 - rerun Station Route Host/Client Recapture"
	if status == "needs_visual_review":
		return "TASK_725 - complete Station Route Host/Client visual acceptance review"
	if status == "needs_followup_polish":
		return "TASK_726 - Station Route follow-up visual polish"
	if status == "accepted_for_next_slice":
		return "TASK_726 - One-Screen Multiplayer Station Scenario Drill"
	return "TASK_725 - decide accepted_for_next_slice or follow-up polish"


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
