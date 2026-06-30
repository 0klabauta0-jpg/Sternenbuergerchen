class_name StationRoutePolishReadinessFindings
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_route_polish_readiness_findings.v1"
const EXPECTED_EVIDENCE_SCHEMA: String = "sternenbuergerchen.station_route_visual_evidence.v1"
const EXPECTED_NOTES_SCHEMA: String = "sternenbuergerchen.station_route_window_playtest_notes.v1"
const DEFAULT_OBJECT_REACTION_VISUAL_MINIMUM: int = 4
const DEFAULT_REPORT_PATH: String = "docs/reports/project_current_state_handbook_refresh_2026_06_30.html"
const DEFAULT_MANIFEST_PATH: String = "tmp/station_route_polish_readiness_findings.json"


static func build_snapshot(evidence_manifest: Dictionary = {}, window_notes: Dictionary = {}, limits: Dictionary = {}) -> Dictionary:
	var object_reaction_visual_minimum: int = maxi(1, int(limits.get("object_reaction_visual_minimum", DEFAULT_OBJECT_REACTION_VISUAL_MINIMUM)))
	var findings: Array = []
	var manual_done: bool = _manual_review_done(evidence_manifest, window_notes)
	_add_evidence_findings(findings, evidence_manifest, object_reaction_visual_minimum, manual_done)
	_add_notes_findings(findings, window_notes)
	var blocking_count: int = _count_findings_by_severity(findings, "blocker")
	var warning_count: int = _count_findings_by_severity(findings, "warning")
	var manual_count: int = _count_findings_by_severity(findings, "manual")
	var rating: String = _extract_rating(window_notes)
	var visual_polish_ready: bool = blocking_count == 0
	var host_client_acceptance_ready: bool = visual_polish_ready and manual_done and warning_count == 0 and rating != "needs_polish" and rating != "blocked"
	var status: String = _build_status(blocking_count, warning_count, manual_count, manual_done, rating)
	return {
		"schema": SNAPSHOT_SCHEMA,
		"runtime_authority": "read-only station route evidence and manual notes",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"source_evidence_schema": String(evidence_manifest.get("schema", "")),
		"source_notes_schema": String(window_notes.get("schema", "")),
		"source_evidence_manifest_path": String(evidence_manifest.get("manifest_path", "tmp/station_route_visual_evidence.json")),
		"source_notes_manifest_path": String(window_notes.get("manifest_path", "tmp/station_route_window_playtest_notes.json")),
		"source_evidence_png_path": String(evidence_manifest.get("png_path", "tmp/station_route_visual_evidence.png")),
		"door_runtime_visual_state": String(evidence_manifest.get("door_runtime_visual_state", "")),
		"door_layout_tone": String(evidence_manifest.get("door_layout_tone", "")),
		"all_gates_complete": bool(evidence_manifest.get("all_gates_complete", false)),
		"generated_evidence_board": bool(evidence_manifest.get("generated_evidence_board", false)),
		"viewport_readback_available": bool(evidence_manifest.get("viewport_readback_available", false)),
		"manual_window_review_required": bool(evidence_manifest.get("manual_window_review_required", true)),
		"manual_window_review_done": manual_done,
		"completed_check_count": int(window_notes.get("completed_check_count", 0)),
		"required_check_count": int(window_notes.get("required_check_count", 0)),
		"rating": rating,
		"object_reaction_visual_count": int(evidence_manifest.get("render_object_reaction_visual_count", 0)),
		"object_reaction_visual_minimum": object_reaction_visual_minimum,
		"blocking_issue_count": blocking_count,
		"warning_count": warning_count,
		"manual_note_count": manual_count,
		"findings": findings,
		"visual_polish_ready": visual_polish_ready,
		"host_client_acceptance_ready": host_client_acceptance_ready,
		"status": status,
		"summary": _build_summary(status, blocking_count, warning_count, manual_count),
		"recommended_next_task": _recommended_next_task(status),
		"report_path": DEFAULT_REPORT_PATH,
		"manifest_path": DEFAULT_MANIFEST_PATH,
	}


static func _add_evidence_findings(findings: Array, evidence_manifest: Dictionary, object_reaction_visual_minimum: int, manual_done: bool) -> void:
	if evidence_manifest.is_empty():
		findings.append(_finding("missing_station_route_evidence", "blocker", "TASK_708-Evidence-Manifest fehlt.", "TASK_708 - Station Route Visual Evidence"))
		return
	if String(evidence_manifest.get("schema", "")) != EXPECTED_EVIDENCE_SCHEMA:
		findings.append(_finding("unexpected_evidence_schema", "blocker", "Station-Route-Evidence hat ein unerwartetes Schema.", "TASK_708 - Station Route Visual Evidence"))
	if not bool(evidence_manifest.get("read_only", false)) or bool(evidence_manifest.get("ui_sets_gameplay_truth", true)):
		findings.append(_finding("evidence_not_readonly", "blocker", "Evidence verletzt read-only/UI-Truth-Regel.", "TASK_708 regression"))
	if not bool(evidence_manifest.get("all_gates_complete", false)):
		findings.append(_finding("station_route_gates_incomplete", "blocker", "Door -> Computer -> Cargo ist im Objective-Snapshot nicht vollstaendig.", "TASK_707 regression"))
	if String(evidence_manifest.get("door_runtime_visual_state", "")) != "open":
		findings.append(_finding("door_not_visually_open", "blocker", "Door ist in der Evidence nicht als open sichtbar.", "TASK_706/TASK_708 regression"))
	if String(evidence_manifest.get("door_layout_tone", "")) != "success":
		findings.append(_finding("door_layout_tone_not_success", "warning", "Door-Layout-Ton ist nicht success; Lesbarkeit kann leiden.", "TASK_711 - Station Route Visual Polish"))
	var visual_count: int = int(evidence_manifest.get("render_object_reaction_visual_count", 0))
	if visual_count < object_reaction_visual_minimum:
		findings.append(_finding("low_object_reaction_visual_count", "warning", "Wenige Object-Reaction-Visuals koennen Door/Computer/Cargo zu leise machen.", "TASK_711 - Station Route Visual Polish"))
	if bool(evidence_manifest.get("generated_evidence_board", false)) and not manual_done:
		findings.append(_finding("generated_board_only", "manual", "Evidence ist ein generiertes Review-Board statt echter Fensterpixel.", "TASK_709 - Station Route Window Playtest Notes"))
	if not bool(evidence_manifest.get("viewport_readback_available", false)) and not manual_done:
		findings.append(_finding("viewport_readback_missing", "manual", "Headless-Lauf hatte keinen echten Viewport-Readback.", "TASK_709 - Station Route Window Playtest Notes"))
	if bool(evidence_manifest.get("manual_window_review_required", true)) and not manual_done:
		findings.append(_finding("manual_window_review_open", "manual", "Echter Station-Route-Fenster-Sichtentscheid ist offen.", "TASK_709 - Station Route Window Playtest Notes"))


static func _add_notes_findings(findings: Array, window_notes: Dictionary) -> void:
	if window_notes.is_empty():
		findings.append(_finding("missing_window_notes", "manual", "TASK_709-Fensternotizen fehlen noch.", "TASK_709 - Station Route Window Playtest Notes"))
		return
	if String(window_notes.get("schema", "")) != EXPECTED_NOTES_SCHEMA:
		findings.append(_finding("unexpected_notes_schema", "warning", "Fensternotizen haben ein unerwartetes Schema.", "TASK_710 - Station Route Polish Readiness Findings"))
	if not bool(window_notes.get("read_only", false)) or bool(window_notes.get("ui_sets_gameplay_truth", true)):
		findings.append(_finding("notes_not_readonly", "blocker", "Fensternotizen verletzen read-only/UI-Truth-Regel.", "TASK_709 regression"))
	var required_count: int = int(window_notes.get("required_check_count", 0))
	var completed_count: int = int(window_notes.get("completed_check_count", 0))
	if required_count > 0 and completed_count < required_count:
		findings.append(_finding("window_checks_incomplete", "manual", "Fenster-Checks sind noch nicht vollstaendig ausgefuellt.", "TASK_709 - Station Route Window Playtest Notes"))
	var rating: String = _extract_rating(window_notes)
	if rating == "needs_polish":
		findings.append(_finding("manual_rating_needs_polish", "warning", "Fensterbefund fordert Visual-Polish.", "TASK_711 - Station Route Visual Polish"))
	elif rating == "blocked":
		findings.append(_finding("manual_rating_blocked", "blocker", "Fensterbefund blockiert Akzeptanz.", "TASK_711 - Station Route Visual Polish"))
	if _has_negative_note(window_notes):
		findings.append(_finding("negative_window_note", "warning", "Fensternotizen nennen konkrete Lesbarkeits- oder Performance-Reibung.", "TASK_711 - Station Route Visual Polish"))


static func _finding(id: String, severity: String, message: String, suggested_next: String) -> Dictionary:
	return {
		"id": id,
		"severity": severity,
		"message": message,
		"suggested_next": suggested_next,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _manual_review_done(evidence_manifest: Dictionary, window_notes: Dictionary) -> bool:
	if bool(window_notes.get("manual_window_review_done", false)) or bool(window_notes.get("manual_review_done", false)):
		return true
	return bool(evidence_manifest.get("manual_window_review_done", false))


static func _extract_rating(window_notes: Dictionary) -> String:
	var rating: String = String(window_notes.get("rating", ""))
	if rating.is_empty():
		rating = String(window_notes.get("manual_rating", ""))
	if rating.is_empty():
		rating = "open"
	return rating


static func _has_negative_note(window_notes: Dictionary) -> bool:
	var note_fields: Array = Array(window_notes.get("note_fields", []))
	for field_variant in note_fields:
		if typeof(field_variant) != TYPE_DICTIONARY:
			continue
		var text: String = String(Dictionary(field_variant).get("value", "")).to_lower()
		if text.contains("zu klein") or text.contains("verdeckt") or text.contains("unklar") or text.contains("ruckelt") or text.contains("blockiert"):
			return true
	var notes: Dictionary = Dictionary(window_notes.get("notes", {}))
	for value in notes.values():
		var text_value: String = String(value).to_lower()
		if text_value.contains("zu klein") or text_value.contains("verdeckt") or text_value.contains("unklar") or text_value.contains("ruckelt") or text_value.contains("blockiert"):
			return true
	return false


static func _count_findings_by_severity(findings: Array, severity: String) -> int:
	var count: int = 0
	for finding_variant in findings:
		if typeof(finding_variant) == TYPE_DICTIONARY and String(Dictionary(finding_variant).get("severity", "")) == severity:
			count += 1
	return count


static func _build_status(blocking_count: int, warning_count: int, manual_count: int, manual_done: bool, rating: String) -> String:
	if blocking_count > 0:
		return "blocked"
	if not manual_done or manual_count > 0 or rating == "open":
		return "needs_window_review"
	if warning_count > 0 or rating == "needs_polish":
		return "needs_visual_polish"
	return "ready_for_host_client_acceptance"


static func _build_summary(status: String, blocking_count: int, warning_count: int, manual_count: int) -> String:
	if status == "blocked":
		return "%d technische Blocker, %d Warnungen, %d manuelle Hinweise" % [blocking_count, warning_count, manual_count]
	if status == "needs_window_review":
		return "technisch auswertbar, Fensterbefund offen, %d manuelle Hinweise" % manual_count
	if status == "needs_visual_polish":
		return "Fensterbefund liegt vor, %d Polish-Warnungen" % warning_count
	return "bereit fuer Host/Client-Akzeptanz"


static func _recommended_next_task(status: String) -> String:
	if status == "blocked":
		return "TASK_710 - Station Route Technical Evidence Fix"
	if status == "needs_window_review":
		return "TASK_709 - Station Route Window Playtest Notes"
	if status == "needs_visual_polish":
		return "TASK_711 - Station Route Visual Polish"
	return "TASK_711 - Host/Client Station Route Acceptance"
