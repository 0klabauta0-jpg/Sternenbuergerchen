class_name StationScenarioWorkbenchExportReview
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_scenario_workbench_export_review.v1"
const EXPECTED_NOTES_SCHEMA: String = "sternenbuergerchen.station_scenario_f6_host_client_playtest_notes.v1"
const EXPECTED_FINDINGS_SCHEMA: String = "sternenbuergerchen.station_scenario_playtest_findings.v1"
const DEFAULT_NOTES_MANIFEST_PATH: String = "tmp/station_scenario_f6_host_client_playtest_notes.json"
const DEFAULT_FINDINGS_MANIFEST_PATH: String = "tmp/station_scenario_playtest_findings.json"
const DEFAULT_MANIFEST_PATH: String = "tmp/station_scenario_workbench_export_review.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html"

const ISSUE_TO_NEXT_TASK: Dictionary = {
	"needs_route_readability_polish": "TASK_732 - Station Scenario Route Cue Polish",
	"needs_hud_overlap_polish": "TASK_733 - Station Scenario HUD Overlap Pass",
	"needs_performance_pass": "TASK_734 - Station Scenario Performance Feel Pass",
	"needs_host_client_sync_fix": "TASK_735 - Station Scenario Host Client Sync Polish",
	"needs_command_feedback_polish": "TASK_736 - Station Scenario Command Feedback Polish",
	"needs_old_harness_modernization": "TASK_737 - Scenario Harness Modernization",
}


static func build_snapshot(notes_manifest: Dictionary = {}, findings_manifest: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var findings: Array = []
	var action_items: Array = []
	_add_notes_findings(findings, notes_manifest)
	_add_findings_manifest_findings(findings, findings_manifest)
	_add_action_items_from_notes(action_items, notes_manifest)
	var blocker_count: int = _count_findings_by_severity(findings, "blocker")
	var manual_count: int = _count_findings_by_severity(findings, "manual")
	var polish_count: int = action_items.size()
	var notes_status: String = String(notes_manifest.get("status", ""))
	var findings_status: String = String(findings_manifest.get("status", ""))
	var status: String = _build_status(blocker_count, manual_count, polish_count, notes_status, findings_status)
	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_731",
		"runtime_authority": "read-only review over TASK_727 workbench export and TASK_728 findings",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"source_notes_schema": String(notes_manifest.get("schema", "")),
		"source_notes_task_id": String(notes_manifest.get("task_id", "")),
		"source_notes_status": notes_status,
		"source_notes_manifest_path": String(options.get("notes_manifest_path", DEFAULT_NOTES_MANIFEST_PATH)),
		"source_findings_schema": String(findings_manifest.get("schema", "")),
		"source_findings_task_id": String(findings_manifest.get("task_id", "")),
		"source_findings_status": findings_status,
		"source_findings_manifest_path": String(options.get("findings_manifest_path", DEFAULT_FINDINGS_MANIFEST_PATH)),
		"manual_review_required": true,
		"manual_review_done": bool(notes_manifest.get("manual_review_done", false)),
		"playtest_done": bool(notes_manifest.get("playtest_done", false)),
		"completed_check_count": int(notes_manifest.get("completed_check_count", 0)),
		"required_check_count": int(notes_manifest.get("required_check_count", 0)),
		"active_issue_count": int(notes_manifest.get("active_issue_count", 0)),
		"blocking_issue_count": blocker_count,
		"manual_issue_count": manual_count,
		"action_items": action_items,
		"action_item_count": action_items.size(),
		"findings": findings,
		"status": status,
		"summary": _build_summary(status, notes_manifest, action_items),
		"recommended_next_task": _recommended_next_task(status, action_items),
		"report_path": String(options.get("report_path", DEFAULT_REPORT_PATH)),
		"manifest_path": String(options.get("manifest_path", DEFAULT_MANIFEST_PATH)),
	}


static func _add_notes_findings(findings: Array, notes_manifest: Dictionary) -> void:
	if notes_manifest.is_empty():
		findings.append(_finding("missing_workbench_export", "manual", "TASK_727-Workbench-Export fehlt.", "TASK_727 - export Station Scenario playtest notes"))
		return
	if String(notes_manifest.get("schema", "")) != EXPECTED_NOTES_SCHEMA:
		findings.append(_finding("unexpected_workbench_export_schema", "blocker", "TASK_727-Workbench-Export hat ein unerwartetes Schema.", "TASK_727 verifier/import rerun"))
	if String(notes_manifest.get("task_id", "")) != "TASK_727":
		findings.append(_finding("unexpected_workbench_export_task", "blocker", "Workbench-Export gehoert nicht zu TASK_727.", "TASK_727 verifier/import rerun"))
	if not bool(notes_manifest.get("read_only", false)) or bool(notes_manifest.get("ui_sets_gameplay_truth", true)):
		findings.append(_finding("workbench_export_not_readonly", "blocker", "Workbench-Export verletzt read-only/UI-Truth-Regel.", "TASK_727 verifier/import rerun"))
	if not bool(notes_manifest.get("manual_review_done", false)) or not bool(notes_manifest.get("playtest_done", false)):
		findings.append(_finding("workbench_export_open", "manual", "Sichtbarer Stationslauf ist noch nicht bewusst erledigt/exportiert.", "TASK_727 - run and export visible Station Scenario playtest"))


static func _add_findings_manifest_findings(findings: Array, findings_manifest: Dictionary) -> void:
	if findings_manifest.is_empty():
		findings.append(_finding("missing_task_728_findings", "manual", "TASK_728-Findingsmanifest fehlt.", "TASK_728 - Station Scenario Playtest Findings"))
		return
	if String(findings_manifest.get("schema", "")) != EXPECTED_FINDINGS_SCHEMA:
		findings.append(_finding("unexpected_task_728_schema", "blocker", "TASK_728-Findingsmanifest hat ein unerwartetes Schema.", "TASK_728 verifier rerun"))
	if String(findings_manifest.get("task_id", "")) != "TASK_728":
		findings.append(_finding("unexpected_task_728_task", "blocker", "Findingsmanifest gehoert nicht zu TASK_728.", "TASK_728 verifier rerun"))
	if not bool(findings_manifest.get("read_only", false)) or bool(findings_manifest.get("ui_sets_gameplay_truth", true)):
		findings.append(_finding("task_728_not_readonly", "blocker", "TASK_728-Findings verletzen read-only/UI-Truth-Regel.", "TASK_728 verifier rerun"))


static func _add_action_items_from_notes(action_items: Array, notes_manifest: Dictionary) -> void:
	for flag_variant in Array(notes_manifest.get("issue_flags", [])):
		if typeof(flag_variant) != TYPE_DICTIONARY:
			continue
		var flag: Dictionary = Dictionary(flag_variant)
		if not bool(flag.get("active", false)):
			continue
		var id: String = String(flag.get("id", ""))
		action_items.append({
			"id": id,
			"label": String(flag.get("label", id)),
			"recommended_task": String(ISSUE_TO_NEXT_TASK.get(id, "TASK_732 - Station Scenario Targeted Polish")),
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})


static func _build_status(blocker_count: int, manual_count: int, polish_count: int, notes_status: String, findings_status: String) -> String:
	if blocker_count > 0:
		return "blocked"
	if manual_count > 0 or notes_status == "needs_visible_playtest" or findings_status == "needs_visible_playtest":
		return "needs_workbench_export"
	if polish_count > 0 or notes_status == "needs_followup_polish" or findings_status == "needs_targeted_polish":
		return "needs_followup_task_selection"
	if notes_status == "ready_for_findings" and findings_status == "ready_for_next_playable_slice":
		return "ready_for_next_playable_slice"
	return "needs_workbench_export"


static func _build_summary(status: String, notes_manifest: Dictionary, action_items: Array) -> String:
	if status == "blocked":
		return "Workbench-Export-Review blockiert: Schema, Task-ID oder read-only-Regel stimmt nicht."
	if status == "needs_workbench_export":
		return "Echter TASK_727-Workbench-Export fehlt oder ist noch offen, %d/%d Checks gesetzt." % [int(notes_manifest.get("completed_check_count", 0)), int(notes_manifest.get("required_check_count", 0))]
	if status == "needs_followup_task_selection":
		return "%d exportierte Follow-up-Punkte brauchen jetzt konkrete Post-TASK_730-Slices." % action_items.size()
	return "Stations-Workbench-Export ist sauber genug fuer den naechsten spielbaren Slice."


static func _recommended_next_task(status: String, action_items: Array) -> String:
	if status == "blocked":
		return "TASK_731 - repair Station Scenario Workbench Export Review"
	if status == "needs_workbench_export":
		return "TASK_727 - run/export visible Station Scenario playtest"
	if status == "needs_followup_task_selection":
		if not action_items.is_empty() and typeof(action_items[0]) == TYPE_DICTIONARY:
			return String(Dictionary(action_items[0]).get("recommended_task", "TASK_732 - Station Scenario Targeted Polish"))
		return "TASK_732 - Station Scenario Targeted Polish"
	return "TASK_732 - Next playable Station Scenario slice"


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
