class_name StationReentryHostClientExportFindings
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_host_client_export_findings.v1"
const EXPECTED_EXPORT_SCHEMA: String = "sternenbuergerchen.station_reentry_visible_host_client_playtest_export.v1"
const EXPECTED_EXPORT_TASK_ID: String = "TASK_771"
const DEFAULT_EXPORT_MANIFEST_PATH: String = "tmp/station_reentry_visible_host_client_playtest_export.json"
const DEFAULT_FINDINGS_MANIFEST_PATH: String = "tmp/station_reentry_host_client_export_findings.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/project_current_state_handbook_reentry_2026_07_01.html"

const REQUIRED_CHECKS: Array[Dictionary] = [
	{"id": "host_window_open", "label": "Host-Fenster sichtbar geoeffnet"},
	{"id": "client_window_open", "label": "Client-Fenster sichtbar geoeffnet"},
	{"id": "host_client_same_next_order_visible", "label": "Host und Client zeigen denselben naechsten Auftrag"},
	{"id": "host_client_route_cue_same_visible", "label": "Host und Client zeigen dieselbe Route und Cue"},
	{"id": "peer_team_context_distinct_visible", "label": "Peer-/Team-Kontext bleibt unterscheidbar"},
	{"id": "first_mission_preview_visible_before_go", "label": "Erste Mission-Preview ist vor GO sichtbar"},
	{"id": "export_json_saved", "label": "HTML-/Workbench-Export wurde gespeichert"},
]

const ISSUE_TO_ACTION: Dictionary = {
	"host_client_next_order_mismatch": "TASK_770 - Station Reentry Host Client Next Order Sync",
	"host_client_route_cue_mismatch": "TASK_770 - Station Reentry Host Client Next Order Sync",
	"peer_team_context_confusing": "TASK_773 - Station Reentry Host Client Identity Cue Polish",
	"first_preview_unclear": "TASK_768 - Station Reentry First Mission Preview Polish",
	"visible_export_performance_stutter": "TASK_769 - Station Reentry Performance Feel Pass",
}

const ISSUE_FLAG_IDS: Array[String] = [
	"host_client_next_order_mismatch",
	"host_client_route_cue_mismatch",
	"peer_team_context_confusing",
	"first_preview_unclear",
	"visible_export_performance_stutter",
]


static func build_snapshot(export_manifest: Dictionary = {}, review_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var findings: Array = []
	var action_items: Array = []
	_add_export_findings(findings, export_manifest)
	var required_checks: Array = _build_required_checks(review_notes)
	var issue_flags: Array = _build_issue_flags(review_notes)
	var completed_check_count: int = _count_completed_checks(required_checks)
	var missing_check_ids: Array[String] = _missing_check_ids(required_checks)
	var active_issue_count: int = _add_issue_flag_findings(findings, action_items, issue_flags)
	var blocker_count: int = _count_findings_by_severity(findings, "blocker")
	var manual_count: int = _count_findings_by_severity(findings, "manual")
	var manual_done: bool = _read_bool(review_notes, "reentry_host_client_findings.manual_review_done")
	var visible_export_done: bool = _read_bool(review_notes, "reentry_host_client_findings.visible_export_done")
	var status: String = _build_status(blocker_count, manual_count, manual_done, visible_export_done, missing_check_ids, active_issue_count)
	if status == "needs_visible_host_client_export":
		findings.append(_finding("visible_host_client_export_open", "manual", "Sichtbarer Host/Client-Reentry-Export fehlt oder ist noch nicht bewusst abgeschlossen.", "TASK_771 - run/export visible Host Client Reentry playtest"))
	elif status == "needs_export_completion":
		findings.append(_finding("visible_host_client_export_checks_missing", "manual", "Host/Client-Reentry-Export ist angefangen, aber Pflichtchecks fehlen: %s" % ", ".join(PackedStringArray(missing_check_ids)), "TASK_771 - complete missing visible export checks"))
	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_772",
		"source_task_id": EXPECTED_EXPORT_TASK_ID,
		"runtime_authority": "read-only findings over TASK_771 export packet and optional report notes",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"source_export_schema": String(export_manifest.get("schema", "")),
		"source_export_task_id": String(export_manifest.get("task_id", "")),
		"source_export_status": String(export_manifest.get("status", "")),
		"source_export_manifest_path": String(options.get("export_manifest_path", DEFAULT_EXPORT_MANIFEST_PATH)),
		"sync_gate": String(export_manifest.get("sync_gate", "")),
		"expected_host_next_order_text": String(export_manifest.get("expected_host_next_order_text", "")),
		"expected_client_next_order_text": String(export_manifest.get("expected_client_next_order_text", "")),
		"expected_station_route_line": String(export_manifest.get("expected_station_route_line", "")),
		"expected_station_cue_line": String(export_manifest.get("expected_station_cue_line", "")),
		"manual_review_required": true,
		"manual_review_done": manual_done,
		"visible_export_done": visible_export_done,
		"required_checks": required_checks,
		"required_check_count": required_checks.size(),
		"completed_check_count": completed_check_count,
		"missing_check_ids": missing_check_ids,
		"issue_flags": issue_flags,
		"active_issue_count": active_issue_count,
		"blocking_issue_count": blocker_count,
		"manual_issue_count": manual_count,
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


static func _add_export_findings(findings: Array, export_manifest: Dictionary) -> void:
	if export_manifest.is_empty():
		findings.append(_finding("missing_task_771_export", "blocker", "TASK_771-Exportpaket fehlt.", "TASK_771 - rerun Station Reentry Visible Host Client Playtest Export"))
		return
	if String(export_manifest.get("schema", "")) != EXPECTED_EXPORT_SCHEMA:
		findings.append(_finding("unexpected_task_771_export_schema", "blocker", "TASK_771-Exportpaket hat ein unerwartetes Schema.", "TASK_771 verifier rerun"))
	if String(export_manifest.get("task_id", "")) != EXPECTED_EXPORT_TASK_ID:
		findings.append(_finding("unexpected_task_771_export_task", "blocker", "Exportpaket gehoert nicht zu TASK_771.", "TASK_771 verifier rerun"))
	if String(export_manifest.get("status", "")) != "ready_to_capture_station_reentry_host_client":
		findings.append(_finding("task_771_export_not_ready", "blocker", "Exportpaket ist nicht capture-bereit.", "TASK_771 repair or rerun"))
	if String(export_manifest.get("sync_gate", "")) != "pass":
		findings.append(_finding("task_770_sync_gate_not_green", "blocker", "TASK_770-Sync-Gate ist nicht gruen.", "TASK_770 - Station Reentry Host Client Next Order Sync"))
	if not bool(export_manifest.get("read_only", false)) or bool(export_manifest.get("ui_sets_gameplay_truth", true)) or bool(export_manifest.get("creates_command", true)):
		findings.append(_finding("task_771_export_not_readonly", "blocker", "TASK_771-Exportpaket verletzt read-only/UI-Truth-Regeln.", "TASK_771 verifier rerun"))


static func _build_required_checks(review_notes: Dictionary) -> Array:
	var checks: Array = []
	for check_def in REQUIRED_CHECKS:
		var id: String = String(check_def.get("id", ""))
		checks.append({
			"id": id,
			"label": String(check_def.get("label", id)),
			"checked": _read_bool(review_notes, "reentry_host_client_findings.%s" % id),
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
			"active": _read_bool(review_notes, "reentry_host_client_findings.issues.%s" % String(id)),
			"recommended_task": String(ISSUE_TO_ACTION.get(id, "")),
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return flags


static func _issue_label(id: String) -> String:
	match id:
		"host_client_next_order_mismatch":
			return "Host/Client-Next-Order weicht sichtbar ab"
		"host_client_route_cue_mismatch":
			return "Host/Client-Route oder Cue weicht sichtbar ab"
		"peer_team_context_confusing":
			return "Peer-/Team-Kontext ist im Fenster nicht klar genug"
		"first_preview_unclear":
			return "Erste Preview ist im sichtbaren Lauf unklar"
		"visible_export_performance_stutter":
			return "Sichtbarer Reentry wirkt im Zwei-Fenster-Lauf zu zaeh"
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
		var next_task: String = String(flag.get("recommended_task", "TASK_773 - Station Reentry Host Client Visual Polish"))
		findings.append(_finding("reentry_host_client_issue_%s" % id, "polish", label, next_task))
		action_items.append({
			"id": id,
			"label": label,
			"recommended_task": next_task,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return count


static func _build_status(blocker_count: int, manual_count: int, manual_done: bool, visible_export_done: bool, missing_check_ids: Array, active_issue_count: int) -> String:
	if blocker_count > 0:
		return "blocked"
	if manual_count > 0 or not manual_done or not visible_export_done:
		return "needs_visible_host_client_export"
	if not missing_check_ids.is_empty():
		return "needs_export_completion"
	if active_issue_count > 0:
		return "needs_targeted_reentry_host_client_polish"
	return "ready_for_next_station_iteration"


static func _build_summary(status: String, completed_check_count: int, required_check_count: int, active_issue_count: int) -> String:
	if status == "blocked":
		return "TASK_772 blockiert: TASK_771-Exportpaket fehlt oder ist ungueltig."
	if status == "needs_visible_host_client_export":
		return "Sichtbarer Host/Client-Reentry-Export offen, %d/%d Checks gesetzt." % [completed_check_count, required_check_count]
	if status == "needs_export_completion":
		return "Host/Client-Reentry-Export unvollstaendig, %d/%d Checks gesetzt." % [completed_check_count, required_check_count]
	if status == "needs_targeted_reentry_host_client_polish":
		return "%d konkrete Host/Client-Reentry-Follow-up-Flag(s)." % active_issue_count
	return "Host/Client-Reentry-Export ist sauber genug fuer die naechste spielbare Iteration."


static func _recommended_next_task(status: String, action_items: Array) -> String:
	if status == "blocked":
		return "TASK_771 - rerun Station Reentry Visible Host Client Playtest Export"
	if status == "needs_visible_host_client_export":
		return "TASK_771 - run/export visible Host Client Reentry playtest"
	if status == "needs_export_completion":
		return "TASK_771 - complete visible Host Client Reentry export checks"
	if status == "needs_targeted_reentry_host_client_polish":
		if not action_items.is_empty() and typeof(action_items[0]) == TYPE_DICTIONARY:
			return String(Dictionary(action_items[0]).get("recommended_task", "TASK_773 - Station Reentry Host Client Visual Polish"))
		return "TASK_773 - Station Reentry Host Client Visual Polish"
	return "TASK_774 - Station Reentry Next Playable Slice Acceptance"


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
