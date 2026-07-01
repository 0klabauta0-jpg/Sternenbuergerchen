class_name StationReentryFirefightDecisionEvidenceFindings
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_decision_evidence_findings.v1"
const EXPECTED_PACKET_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_decision_evidence_packet.v1"
const EXPECTED_PACKET_TASK_ID: String = "TASK_788"
const DEFAULT_PACKET_MANIFEST_PATH: String = "tmp/station_reentry_firefight_decision_evidence_packet.json"
const DEFAULT_FINDINGS_MANIFEST_PATH: String = "tmp/station_reentry_firefight_decision_evidence_findings.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/project_current_state_handbook_reentry_2026_07_01.html"

const REQUIRED_CHECKS: Array[Dictionary] = [
	{"id": "f6_window_open", "label": "F6-Fenster ist fuer die Decision-Card sichtbar offen"},
	{"id": "decision_card_visible", "label": "Decision-Card ist sichtbar"},
	{"id": "decision_line_visible", "label": "Decision-Line ist sichtbar"},
	{"id": "primary_action_visible", "label": "Primaerer Griff ist sichtbar"},
	{"id": "quick_actions_visible", "label": "Quick-Actions sind sichtbar"},
	{"id": "reason_line_visible", "label": "Warum-Zeile ist sichtbar"},
	{"id": "guard_line_visible", "label": "Guard-Line ist sichtbar"},
	{"id": "confirm_control_visible", "label": "GO/Confirm-Control ist sichtbar"},
	{"id": "no_auto_command_commit_visible", "label": "No-Auto-Command-Grenze ist sichtbar"},
	{"id": "host_client_context_visible", "label": "Host/Client-Kontext bleibt sichtbar"},
	{"id": "screenshot_saved", "label": "Screenshot/Evidence wurde gespeichert"},
	{"id": "workbench_json_exported", "label": "Workbench-JSON wurde exportiert"},
]

const ISSUE_TO_ACTION: Dictionary = {
	"decision_card_missing": "TASK_787 - Station Reentry Firefight Player Decision Readability Pass",
	"decision_line_unclear": "TASK_787 - Station Reentry Firefight Player Decision Readability Pass",
	"primary_action_unclear": "TASK_787 - Station Reentry Firefight Player Decision Readability Pass",
	"quick_actions_hidden": "TASK_787 - Station Reentry Firefight Player Decision Readability Pass",
	"reason_line_missing": "TASK_787 - Station Reentry Firefight Player Decision Readability Pass",
	"guard_line_missing": "TASK_783 - Station Reentry Firefight Command Surface Polish",
	"confirm_control_unclear": "TASK_736 - Station Scenario Command Feedback Polish",
	"auto_command_commit_confusing": "TASK_501 - Integrated Movement Command Lifecycle Hardening",
	"host_client_context_mismatch": "TASK_770 - Station Reentry Host Client Next Order Sync",
	"performance_stutter_visible": "TASK_769 - Station Reentry Performance Feel Pass",
}

const ISSUE_FLAG_IDS: Array[String] = [
	"decision_card_missing",
	"decision_line_unclear",
	"primary_action_unclear",
	"quick_actions_hidden",
	"reason_line_missing",
	"guard_line_missing",
	"confirm_control_unclear",
	"auto_command_commit_confusing",
	"host_client_context_mismatch",
	"performance_stutter_visible",
]


static func build_snapshot(packet_manifest: Dictionary = {}, review_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var findings: Array = []
	var action_items: Array = []
	_add_packet_findings(findings, packet_manifest)
	var required_checks: Array = _build_required_checks(review_notes)
	var issue_flags: Array = _build_issue_flags(review_notes)
	var completed_check_count: int = _count_completed_checks(required_checks)
	var missing_check_ids: Array[String] = _missing_check_ids(required_checks)
	var active_issue_count: int = _add_issue_flag_findings(findings, action_items, issue_flags)
	var blocker_count: int = _count_findings_by_severity(findings, "blocker")
	var manual_done: bool = _read_bool(review_notes, "reentry_firefight_decision_evidence_findings.manual_review_done")
	var visible_review_done: bool = _read_bool(review_notes, "reentry_firefight_decision_evidence_findings.visible_review_done")
	var status: String = _build_status(blocker_count, manual_done, visible_review_done, missing_check_ids, active_issue_count)
	if status == "needs_visible_decision_evidence_review":
		findings.append(_finding("visible_decision_evidence_review_open", "manual", "Sichtbarer Decision-Card-Review fehlt oder ist noch nicht bewusst abgeschlossen.", "TASK_788 - run Firefight Decision Evidence Packet"))
	elif status == "needs_decision_evidence_review_completion":
		findings.append(_finding("decision_evidence_checks_missing", "manual", "Decision-Evidence-Review ist angefangen, aber Pflichtchecks fehlen: %s" % ", ".join(PackedStringArray(missing_check_ids)), "TASK_788 - complete missing Decision-Evidence checks"))
	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_789",
		"source_task_id": EXPECTED_PACKET_TASK_ID,
		"runtime_authority": "read-only findings over TASK_788 decision evidence packet and optional report notes",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"source_packet_schema": String(packet_manifest.get("schema", "")),
		"source_packet_task_id": String(packet_manifest.get("task_id", "")),
		"source_packet_status": String(packet_manifest.get("status", "")),
		"source_packet_manifest_path": String(options.get("packet_manifest_path", DEFAULT_PACKET_MANIFEST_PATH)),
		"target_id": String(packet_manifest.get("target_id", "station_reentry_firefight_decision_evidence")),
		"expected_decision_line": String(packet_manifest.get("expected_decision_line", "")),
		"expected_primary_action_label": String(packet_manifest.get("expected_primary_action_label", "")),
		"expected_quick_action_labels": Array(packet_manifest.get("expected_quick_action_labels", [])).duplicate(true),
		"expected_reason_line": String(packet_manifest.get("expected_reason_line", "")),
		"expected_guard_line": String(packet_manifest.get("expected_guard_line", "")),
		"expected_confirm_control": String(packet_manifest.get("expected_confirm_control", "")),
		"expected_no_auto_command_commit": bool(packet_manifest.get("expected_no_auto_command_commit", false)),
		"expected_existing_commands_only": bool(packet_manifest.get("expected_existing_commands_only", false)),
		"expected_host_client_context_visible": bool(packet_manifest.get("expected_host_client_context_visible", false)),
		"manual_review_required": true,
		"manual_review_done": manual_done,
		"visible_review_done": visible_review_done,
		"required_checks": required_checks,
		"required_check_count": required_checks.size(),
		"completed_check_count": completed_check_count,
		"missing_check_ids": missing_check_ids,
		"issue_flags": issue_flags,
		"active_issue_count": active_issue_count,
		"blocking_issue_count": blocker_count,
		"finding_count": findings.size(),
		"findings": findings,
		"action_items": action_items,
		"action_item_count": action_items.size(),
		"status": status,
		"summary": _build_summary(status, completed_check_count, required_checks.size(), active_issue_count),
		"recommended_next_task": _recommended_next_task(status, action_items),
		"report_path": String(options.get("report_path", DEFAULT_REPORT_PATH)),
		"manifest_path": String(options.get("manifest_path", DEFAULT_FINDINGS_MANIFEST_PATH)),
	}


static func _add_packet_findings(findings: Array, packet_manifest: Dictionary) -> void:
	if packet_manifest.is_empty():
		findings.append(_finding("missing_task_788_packet", "blocker", "TASK_788-Decision-Evidence-Paket fehlt.", "TASK_788 - rerun Station Reentry Firefight Decision Evidence Packet"))
		return
	if String(packet_manifest.get("schema", "")) != EXPECTED_PACKET_SCHEMA:
		findings.append(_finding("unexpected_task_788_packet_schema", "blocker", "TASK_788-Paket hat ein unerwartetes Schema.", "TASK_788 verifier rerun"))
	if String(packet_manifest.get("task_id", "")) != EXPECTED_PACKET_TASK_ID:
		findings.append(_finding("unexpected_task_788_packet_task", "blocker", "Paket gehoert nicht zu TASK_788.", "TASK_788 verifier rerun"))
	if String(packet_manifest.get("status", "")) != "ready_to_capture_firefight_decision_evidence":
		findings.append(_finding("task_788_packet_not_ready", "blocker", "TASK_788-Paket ist nicht capture-bereit.", "TASK_788 repair or rerun"))
	if not bool(packet_manifest.get("read_only", false)) \
			or bool(packet_manifest.get("ui_sets_gameplay_truth", true)) \
			or bool(packet_manifest.get("creates_command", true)) \
			or bool(packet_manifest.get("creates_fire_event", true)) \
			or bool(packet_manifest.get("creates_damage_event", true)):
		findings.append(_finding("task_788_packet_not_readonly", "blocker", "TASK_788-Paket verletzt read-only/UI-Truth-Regeln.", "TASK_788 verifier rerun"))
	if not bool(packet_manifest.get("expected_no_auto_command_commit", false)):
		findings.append(_finding("task_788_missing_no_auto_commit_expectation", "blocker", "TASK_788-Paket traegt keine No-Auto-Command-Erwartung.", "TASK_788 verifier rerun"))
	if not bool(packet_manifest.get("expected_existing_commands_only", false)):
		findings.append(_finding("task_788_missing_existing_command_expectation", "blocker", "TASK_788-Paket traegt keine Existing-Commands-only-Erwartung.", "TASK_788 verifier rerun"))
	if not bool(packet_manifest.get("expected_host_client_context_visible", false)):
		findings.append(_finding("task_788_missing_host_client_context_expectation", "blocker", "TASK_788-Paket traegt keine Host/Client-Kontext-Erwartung.", "TASK_788 verifier rerun"))


static func _build_required_checks(review_notes: Dictionary) -> Array:
	var checks: Array = []
	for check_def in REQUIRED_CHECKS:
		var id: String = String(check_def.get("id", ""))
		checks.append({
			"id": id,
			"label": String(check_def.get("label", id)),
			"checked": _read_bool(review_notes, "reentry_firefight_decision_evidence_findings.%s" % id) \
					or _read_bool(review_notes, "reentry_firefight_decision_evidence.%s" % id),
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return checks


static func _build_issue_flags(review_notes: Dictionary) -> Array:
	var flags: Array = []
	for id in ISSUE_FLAG_IDS:
		flags.append({
			"id": String(id),
			"label": _issue_label(String(id)),
			"active": _read_bool(review_notes, "reentry_firefight_decision_evidence_findings.issues.%s" % String(id)),
			"recommended_task": String(ISSUE_TO_ACTION.get(id, "")),
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return flags


static func _issue_label(id: String) -> String:
	match id:
		"decision_card_missing":
			return "Decision-Card fehlt oder ist nicht am erwarteten Ort sichtbar"
		"decision_line_unclear":
			return "Decision-Line ist unklar oder zu lang"
		"primary_action_unclear":
			return "Primaerer Griff ist unklar oder nicht hervorgehoben"
		"quick_actions_hidden":
			return "Quick-Actions sind versteckt oder zu schwer auffindbar"
		"reason_line_missing":
			return "Warum-Zeile fehlt oder erklaert die Lage nicht"
		"guard_line_missing":
			return "Guard-Line fehlt oder benennt No-Auto-Command nicht klar"
		"confirm_control_unclear":
			return "GO/Confirm-Control ist unklar oder wirkt wie Auto-Commit"
		"auto_command_commit_confusing":
			return "Anzeige wirkt so, als wuerde sie automatisch Befehle ausfuehren"
		"host_client_context_mismatch":
			return "Host/Client-Kontext oder Peer-Team-Zuordnung widerspricht der Decision-Card"
		"performance_stutter_visible":
			return "Decision-Card wirkt zaeh oder stottert"
	return id


static func _add_issue_flag_findings(findings: Array, action_items: Array, issue_flags: Array) -> int:
	var count: int = 0
	for flag_variant in issue_flags:
		if typeof(flag_variant) != TYPE_DICTIONARY:
			continue
		var flag: Dictionary = Dictionary(flag_variant)
		if not bool(flag.get("active", false)):
			continue
		count += 1
		var id: String = String(flag.get("id", ""))
		var label: String = String(flag.get("label", id))
		var next_task: String = String(flag.get("recommended_task", "TASK_787 - Station Reentry Firefight Player Decision Readability Pass"))
		findings.append(_finding("decision_evidence_issue_%s" % id, "polish", label, next_task))
		action_items.append({
			"id": id,
			"label": label,
			"recommended_task": next_task,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return count


static func _build_status(blocker_count: int, manual_done: bool, visible_review_done: bool, missing_check_ids: Array, active_issue_count: int) -> String:
	if blocker_count > 0:
		return "blocked"
	if not manual_done or not visible_review_done:
		return "needs_visible_decision_evidence_review"
	if not missing_check_ids.is_empty():
		return "needs_decision_evidence_review_completion"
	if active_issue_count > 0:
		return "needs_targeted_decision_evidence_polish"
	return "ready_for_firefight_decision_polish_acceptance"


static func _build_summary(status: String, completed_check_count: int, required_check_count: int, active_issue_count: int) -> String:
	if status == "blocked":
		return "TASK_789 blockiert: TASK_788-Decision-Evidence-Paket fehlt oder ist ungueltig."
	if status == "needs_visible_decision_evidence_review":
		return "Sichtbarer Decision-Card-Review offen, %d/%d Checks gesetzt." % [completed_check_count, required_check_count]
	if status == "needs_decision_evidence_review_completion":
		return "Decision-Evidence-Review unvollstaendig, %d/%d Checks gesetzt." % [completed_check_count, required_check_count]
	if status == "needs_targeted_decision_evidence_polish":
		return "%d konkrete Decision-Evidence-Follow-up-Flag(s)." % active_issue_count
	return "Decision-Card-Evidence ist sauber genug fuer eine kleine Acceptance-/Polish-Entscheidung."


static func _recommended_next_task(status: String, action_items: Array) -> String:
	if status == "blocked":
		return "TASK_788 - rerun Station Reentry Firefight Decision Evidence Packet"
	if status == "needs_visible_decision_evidence_review":
		return "TASK_788 - run visible Firefight Decision Evidence Packet"
	if status == "needs_decision_evidence_review_completion":
		return "TASK_788 - complete missing Decision-Evidence checks"
	if status == "needs_targeted_decision_evidence_polish":
		if not action_items.is_empty() and typeof(action_items[0]) == TYPE_DICTIONARY:
			return String(Dictionary(action_items[0]).get("recommended_task", "TASK_787 - Station Reentry Firefight Player Decision Readability Pass"))
		return "TASK_787 - Station Reentry Firefight Player Decision Readability Pass"
	return "TASK_790 - Station Reentry Firefight Decision Polish Acceptance"


static func _missing_check_ids(required_checks: Array) -> Array[String]:
	var missing: Array[String] = []
	for check_variant in required_checks:
		if typeof(check_variant) != TYPE_DICTIONARY:
			continue
		var check: Dictionary = Dictionary(check_variant)
		if not bool(check.get("checked", false)):
			missing.append(String(check.get("id", "")))
	return missing


static func _count_completed_checks(required_checks: Array) -> int:
	var count: int = 0
	for check_variant in required_checks:
		if typeof(check_variant) == TYPE_DICTIONARY and bool(Dictionary(check_variant).get("checked", false)):
			count += 1
	return count


static func _read_bool(source: Dictionary, dotted_key: String) -> bool:
	var direct_value: Variant = _get_path(source, dotted_key)
	if typeof(direct_value) == TYPE_BOOL:
		return bool(direct_value)
	var controls: Dictionary = Dictionary(source.get("controls", {}))
	var control_value: Variant = _get_path(controls, dotted_key)
	return bool(control_value) if typeof(control_value) == TYPE_BOOL else false


static func _get_path(source: Dictionary, dotted_key: String) -> Variant:
	var cursor: Variant = source
	for part in dotted_key.split("."):
		if typeof(cursor) != TYPE_DICTIONARY:
			return null
		var dict: Dictionary = Dictionary(cursor)
		if not dict.has(part):
			return null
		cursor = dict.get(part)
	return cursor


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
