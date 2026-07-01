class_name StationRouteHostClientRecaptureReview
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_route_host_client_recapture_review.v1"
const EXPECTED_CAPTURE_SCHEMA: String = "sternenbuergerchen.host_client_two_window_real_run_review.v1"
const EXPECTED_HUD_POLISH_SCHEMA: String = "sternenbuergerchen.station_route_hud_visual_polish.v1"
const DEFAULT_CAPTURE_MANIFEST_PATH: String = "tmp/host_client_two_window_real_run_review.json"
const DEFAULT_HUD_POLISH_MANIFEST_PATH: String = "tmp/station_route_hud_visual_polish.json"
const DEFAULT_MANIFEST_PATH: String = "tmp/station_route_host_client_recapture_review.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/project_current_state_handbook_2026_07_01.html"

const REQUIRED_RECAPTURE_REVIEW_CHECKS: Array[String] = [
	"station_route_hud_polish_recapture_review",
	"station_route_fireteam_mini_map_safe_margin",
	"station_route_label_backplates_readable",
	"station_route_nav_placeholder_hidden",
]

const REQUIRED_VISUAL_REVIEW_KEYS: Array[String] = [
	"host_map_visible",
	"client_map_visible",
	"fireteam_mini_cards_no_longer_cover_map",
	"station_route_labels_backplate_readable",
	"top_nav_placeholder_hidden",
	"door_station_route_visible",
]

const FOLLOWUP_POLISH_FLAGS: Array[String] = [
	"fireteam_cards_still_cover_map",
	"labels_still_crowded",
	"nav_placeholder_still_visible",
	"route_line_still_unclear",
]


static func build_snapshot(capture_manifest: Dictionary = {}, hud_polish_manifest: Dictionary = {}, visual_review: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var findings: Array = []
	_add_hud_polish_findings(findings, hud_polish_manifest)
	_add_capture_findings(findings, capture_manifest)
	_add_visual_review_findings(findings, visual_review)
	var blocker_count: int = _count_findings_by_severity(findings, "blocker")
	var recapture_ready: bool = _recapture_ready(capture_manifest)
	var hud_polish_ready: bool = _hud_polish_ready(hud_polish_manifest)
	var visual_review_done: bool = bool(visual_review.get("visual_review_done", false))
	var followup_count: int = _count_findings_by_severity(findings, "polish")
	var manual_count: int = _count_findings_by_severity(findings, "manual")
	var status: String = _build_status(blocker_count, recapture_ready, hud_polish_ready, visual_review_done, followup_count)
	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_723",
		"runtime_authority": "read-only recapture review over TASK_722 HUD polish and host/client screenshots",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"capture_manifest_path": String(options.get("capture_manifest_path", DEFAULT_CAPTURE_MANIFEST_PATH)),
		"hud_polish_manifest_path": String(options.get("hud_polish_manifest_path", DEFAULT_HUD_POLISH_MANIFEST_PATH)),
		"capture_schema": String(capture_manifest.get("schema", "")),
		"hud_polish_schema": String(hud_polish_manifest.get("schema", "")),
		"host_screenshot_path": String(capture_manifest.get("host_screenshot_path", "")),
		"client_screenshot_path": String(capture_manifest.get("client_screenshot_path", "")),
		"hud_polish_ready": hud_polish_ready,
		"recapture_ready": recapture_ready,
		"visual_review_done": visual_review_done,
		"visual_decision": String(visual_review.get("visual_decision", "")),
		"blocking_issue_count": blocker_count,
		"manual_note_count": manual_count,
		"followup_polish_issue_count": followup_count,
		"findings": findings,
		"status": status,
		"summary": _build_summary(status, followup_count, manual_count),
		"recommended_next_task": _recommended_next_task(status),
		"report_path": DEFAULT_REPORT_PATH,
		"manifest_path": DEFAULT_MANIFEST_PATH,
	}


static func _add_hud_polish_findings(findings: Array, manifest: Dictionary) -> void:
	if manifest.is_empty():
		findings.append(_finding("missing_hud_polish_manifest", "blocker", "TASK_722-HUD-Polish-Manifest fehlt.", "TASK_722 manifest rerun"))
		return
	if String(manifest.get("schema", "")) != EXPECTED_HUD_POLISH_SCHEMA:
		findings.append(_finding("unexpected_hud_polish_schema", "blocker", "TASK_722-HUD-Polish hat ein unerwartetes Schema.", "TASK_722 verifier rerun"))
	if String(manifest.get("task_id", "")) != "TASK_722":
		findings.append(_finding("unexpected_hud_polish_task", "blocker", "HUD-Polish-Manifest gehoert nicht zu TASK_722.", "TASK_722 verifier rerun"))
	if String(manifest.get("gate", "")) != "ready_for_recapture":
		findings.append(_finding("hud_polish_not_ready_for_recapture", "blocker", "TASK_722 meldet nicht ready_for_recapture.", "TASK_722 verifier rerun"))
	if not bool(manifest.get("read_only", false)) or bool(manifest.get("ui_sets_gameplay_truth", true)):
		findings.append(_finding("hud_polish_not_readonly", "blocker", "HUD-Polish verletzt read-only/UI-Truth-Regel.", "TASK_722 verifier rerun"))


static func _add_capture_findings(findings: Array, manifest: Dictionary) -> void:
	if manifest.is_empty():
		findings.append(_finding("missing_recapture_manifest", "blocker", "Host/Client-Recapture-Manifest fehlt.", "TASK_723 capture rerun"))
		return
	if String(manifest.get("schema", "")) != EXPECTED_CAPTURE_SCHEMA:
		findings.append(_finding("unexpected_capture_schema", "blocker", "Recapture-Manifest hat ein unerwartetes Schema.", "TASK_723 capture rerun"))
	if String(manifest.get("station_route_hud_visual_polish_task_id", "")) != "TASK_722":
		findings.append(_finding("missing_task_722_recapture_link", "blocker", "Recapture referenziert TASK_722 nicht.", "TASK_723 capture rerun"))
	if String(manifest.get("station_route_host_client_recapture_review_task_id", "")) != "TASK_723":
		findings.append(_finding("missing_task_723_recapture_link", "blocker", "Recapture referenziert TASK_723 nicht.", "TASK_723 capture rerun"))
	if not bool(manifest.get("station_route_hud_polish_recapture_done", false)):
		findings.append(_finding("hud_polish_recapture_not_done", "blocker", "Nach-TASK_722-Recapture wurde nicht als erledigt markiert.", "TASK_723 capture rerun"))
	if String(manifest.get("station_route_hud_polish_recapture_gate", "")) != "review_ready":
		findings.append(_finding("hud_polish_recapture_not_review_ready", "blocker", "Nach-TASK_722-Recapture ist nicht review_ready.", "TASK_723 capture rerun"))
	if not bool(manifest.get("real_run_done", false)):
		findings.append(_finding("real_run_not_done", "blocker", "Zwei-Fenster-Run wurde nicht als real_run_done erfasst.", "TASK_723 capture rerun"))
	if not bool(manifest.get("host_screenshot_written", false)):
		findings.append(_finding("host_screenshot_missing", "blocker", "Host-Screenshot fehlt.", "TASK_723 capture rerun"))
	if not bool(manifest.get("client_screenshot_written", false)):
		findings.append(_finding("client_screenshot_missing", "blocker", "Client-Screenshot fehlt.", "TASK_723 capture rerun"))
	if not bool(manifest.get("read_only", false)) or bool(manifest.get("ui_sets_gameplay_truth", true)):
		findings.append(_finding("capture_not_readonly", "blocker", "Recapture verletzt read-only/UI-Truth-Regel.", "TASK_723 capture rerun"))
	var review_checks: Array = Array(manifest.get("review_checks", []))
	for check in REQUIRED_RECAPTURE_REVIEW_CHECKS:
		if not review_checks.has(check):
			findings.append(_finding("missing_review_check_%s" % check, "blocker", "Recapture-Manifest enthaelt Review-Check nicht: %s." % check, "TASK_723 capture script update"))


static func _add_visual_review_findings(findings: Array, review: Dictionary) -> void:
	if review.is_empty() or not bool(review.get("visual_review_done", false)):
		findings.append(_finding("visual_review_open", "manual", "Nach-TASK_722-Screenshots sind technisch bereit, aber noch nicht menschlich bewertet.", "TASK_723 visual review"))
		return
	for key in REQUIRED_VISUAL_REVIEW_KEYS:
		if not bool(review.get(key, false)):
			findings.append(_finding("missing_visual_check_%s" % key, "manual", "Sichtcheck fehlt oder ist negativ: %s." % key, "TASK_723 visual review"))
	for key in FOLLOWUP_POLISH_FLAGS:
		if bool(review.get(key, false)):
			findings.append(_finding("followup_polish_%s" % key, "polish", String(review.get("%s_note" % key, "Nach-Recapture sichtbarer Polish-Bedarf: %s." % key)), "TASK_724 station route followup polish"))


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
	if String(manifest.get("station_route_hud_visual_polish_task_id", "")) != "TASK_722":
		return false
	if String(manifest.get("station_route_host_client_recapture_review_task_id", "")) != "TASK_723":
		return false
	if not bool(manifest.get("station_route_hud_polish_recapture_done", false)):
		return false
	if String(manifest.get("station_route_hud_polish_recapture_gate", "")) != "review_ready":
		return false
	var review_checks: Array = Array(manifest.get("review_checks", []))
	for check in REQUIRED_RECAPTURE_REVIEW_CHECKS:
		if not review_checks.has(check):
			return false
	return true


static func _hud_polish_ready(manifest: Dictionary) -> bool:
	return (
		not manifest.is_empty()
		and String(manifest.get("schema", "")) == EXPECTED_HUD_POLISH_SCHEMA
		and String(manifest.get("task_id", "")) == "TASK_722"
		and String(manifest.get("gate", "")) == "ready_for_recapture"
		and bool(manifest.get("read_only", false))
		and not bool(manifest.get("ui_sets_gameplay_truth", true))
	)


static func _build_status(blocker_count: int, recapture_ready: bool, hud_polish_ready: bool, visual_review_done: bool, followup_count: int) -> String:
	if blocker_count > 0:
		return "blocked"
	if not hud_polish_ready or not recapture_ready:
		return "needs_recapture"
	if not visual_review_done:
		return "needs_visual_review"
	if followup_count > 0:
		return "needs_followup_polish"
	return "ready_for_acceptance_decision"


static func _build_summary(status: String, followup_count: int, manual_count: int) -> String:
	if status == "blocked":
		return "technische Recapture- oder HUD-Polish-Evidence fehlt"
	if status == "needs_recapture":
		return "nach TASK_722 muss der Host/Client-Recapture neu geschrieben werden"
	if status == "needs_visual_review":
		return "Recapture ist bereit, menschlicher Sichtentscheid steht aus"
	if status == "needs_followup_polish":
		return "%d sichtbare Folge-Polish-Punkte, %d manuelle Hinweise" % [followup_count, manual_count]
	return "Recapture-Sichtbefund ohne Folge-Polish-Blocker"


static func _recommended_next_task(status: String) -> String:
	if status == "blocked" or status == "needs_recapture":
		return "TASK_723 - rerun Station Route Host/Client Recapture"
	if status == "needs_visual_review":
		return "TASK_723 - complete Station Route Host/Client visual review"
	if status == "needs_followup_polish":
		return "TASK_724 - Station Route follow-up visual polish"
	return "TASK_724 - accept Station Route multiplayer slice or start next playable scenario"


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
