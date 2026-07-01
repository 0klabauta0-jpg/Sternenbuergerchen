class_name StationScenarioPlaytestFindings
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_scenario_playtest_findings.v1"
const EXPECTED_NOTES_SCHEMA: String = "sternenbuergerchen.station_scenario_f6_host_client_playtest_notes.v1"
const EXPECTED_NOTES_TASK_ID: String = "TASK_727"
const DEFAULT_NOTES_MANIFEST_PATH: String = "tmp/station_scenario_f6_host_client_playtest_notes.json"
const DEFAULT_MANIFEST_PATH: String = "tmp/station_scenario_playtest_findings.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/project_current_state_handbook_2026_07_01.html"

const ISSUE_TO_ACTION: Dictionary = {
	"needs_route_readability_polish": "TASK_729 - Station Scenario Route Readability Polish",
	"needs_hud_overlap_polish": "TASK_729 - Station Scenario HUD Overlap Polish",
	"needs_performance_pass": "TASK_729 - Station Scenario Performance Pass",
	"needs_host_client_sync_fix": "TASK_729 - Station Scenario Host Client Sync Fix",
	"needs_command_feedback_polish": "TASK_729 - Station Scenario Command Feedback Polish",
	"needs_old_harness_modernization": "TASK_730 - Scenario Harness Modernization",
}


static func build_snapshot(notes_manifest: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var findings: Array = []
	var action_items: Array = []
	_add_notes_findings(findings, action_items, notes_manifest)
	var blocker_count: int = _count_findings_by_severity(findings, "blocker")
	var manual_count: int = _count_findings_by_severity(findings, "manual")
	var polish_count: int = _count_findings_by_severity(findings, "polish")
	var warning_count: int = _count_findings_by_severity(findings, "warning")
	var notes_status: String = String(notes_manifest.get("status", ""))
	var status: String = _build_status(blocker_count, manual_count, polish_count, notes_status)
	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_728",
		"runtime_authority": "read-only findings over TASK_727 playtest notes",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"source_notes_schema": String(notes_manifest.get("schema", "")),
		"source_notes_task_id": String(notes_manifest.get("task_id", "")),
		"source_notes_status": notes_status,
		"source_notes_rating": String(notes_manifest.get("rating", "")),
		"source_notes_manifest_path": String(options.get("notes_manifest_path", DEFAULT_NOTES_MANIFEST_PATH)),
		"manual_review_required": bool(notes_manifest.get("manual_review_required", true)),
		"manual_review_done": bool(notes_manifest.get("manual_review_done", false)),
		"playtest_done": bool(notes_manifest.get("playtest_done", false)),
		"completed_check_count": int(notes_manifest.get("completed_check_count", 0)),
		"required_check_count": int(notes_manifest.get("required_check_count", 0)),
		"active_issue_count": int(notes_manifest.get("active_issue_count", 0)),
		"blocking_issue_count": blocker_count,
		"manual_note_count": manual_count,
		"polish_issue_count": polish_count,
		"warning_count": warning_count,
		"findings": findings,
		"action_items": action_items,
		"action_item_count": action_items.size(),
		"status": status,
		"summary": _build_summary(status, notes_manifest, polish_count, manual_count),
		"recommended_next_task": _recommended_next_task(status, action_items),
		"report_path": String(options.get("report_path", DEFAULT_REPORT_PATH)),
		"manifest_path": String(options.get("manifest_path", DEFAULT_MANIFEST_PATH)),
	}


static func _add_notes_findings(findings: Array, action_items: Array, manifest: Dictionary) -> void:
	if manifest.is_empty():
		findings.append(_finding("missing_playtest_notes_manifest", "blocker", "TASK_727-Playtestnotizen fehlen.", "TASK_727 - Station Scenario F6/Host Client Playtest Notes"))
		return
	if String(manifest.get("schema", "")) != EXPECTED_NOTES_SCHEMA:
		findings.append(_finding("unexpected_playtest_notes_schema", "blocker", "Playtestnotizen haben ein unerwartetes Schema.", "TASK_727 verifier rerun"))
	if String(manifest.get("task_id", "")) != EXPECTED_NOTES_TASK_ID:
		findings.append(_finding("unexpected_playtest_notes_task", "blocker", "Playtestnotizen gehoeren nicht zu TASK_727.", "TASK_727 verifier rerun"))
	if not bool(manifest.get("read_only", false)) or bool(manifest.get("ui_sets_gameplay_truth", true)):
		findings.append(_finding("playtest_notes_not_readonly", "blocker", "Playtestnotizen verletzen read-only/UI-Truth-Regel.", "TASK_727 verifier rerun"))

	var source_status: String = String(manifest.get("status", ""))
	if source_status == "blocked":
		findings.append(_finding("source_playtest_notes_blocked", "blocker", "TASK_727 ist selbst blockiert.", "TASK_727 repair"))
	if source_status == "needs_visible_playtest" or not bool(manifest.get("manual_review_done", false)) or not bool(manifest.get("playtest_done", false)):
		findings.append(_finding("visible_playtest_open", "manual", "Sichtbarer F6/Host-Client-Playtest ist noch offen.", "TASK_727 - run visible F6/Host Client station playtest"))

	_add_issue_flag_findings(findings, action_items, Array(manifest.get("issue_flags", [])), source_status)


static func _add_issue_flag_findings(findings: Array, action_items: Array, issue_flags: Array, source_status: String) -> void:
	var active_issue_found: bool = false
	for flag_variant in issue_flags:
		if typeof(flag_variant) != TYPE_DICTIONARY:
			continue
		var flag: Dictionary = Dictionary(flag_variant)
		if not bool(flag.get("active", false)):
			continue
		active_issue_found = true
		var id: String = String(flag.get("id", ""))
		var label: String = String(flag.get("label", id))
		var next_task: String = String(ISSUE_TO_ACTION.get(id, "TASK_729 - Station Scenario Targeted Playtest Polish"))
		findings.append(_finding("playtest_issue_%s" % id, "polish", label, next_task))
		action_items.append({
			"id": id,
			"label": label,
			"recommended_task": next_task,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	if source_status == "needs_followup_polish" and not active_issue_found:
		findings.append(_finding("playtest_polish_without_flag", "polish", "TASK_727 meldet Follow-up-Polish ohne einzelnes Flag.", "TASK_729 - Station Scenario Targeted Playtest Polish"))
		action_items.append({
			"id": "generic_playtest_polish",
			"label": "Generischer Playtest-Polish aus TASK_727",
			"recommended_task": "TASK_729 - Station Scenario Targeted Playtest Polish",
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})


static func _build_status(blocker_count: int, manual_count: int, polish_count: int, notes_status: String) -> String:
	if blocker_count > 0:
		return "blocked"
	if manual_count > 0:
		return "needs_visible_playtest"
	if polish_count > 0 or notes_status == "needs_followup_polish":
		return "needs_targeted_polish"
	if notes_status == "ready_for_findings":
		return "ready_for_next_playable_slice"
	return "needs_visible_playtest"


static func _build_summary(status: String, notes_manifest: Dictionary, polish_count: int, manual_count: int) -> String:
	if status == "blocked":
		return "TASK_728 blockiert: Playtestnotizen fehlen oder sind ungueltig"
	if status == "needs_visible_playtest":
		return "Sichtbarer Playtest offen, %d/%d Checks gesetzt" % [int(notes_manifest.get("completed_check_count", 0)), int(notes_manifest.get("required_check_count", 0))]
	if status == "needs_targeted_polish":
		return "%d konkrete Playtest-Polish-Punkte, %d manuelle Hinweise" % [polish_count, manual_count]
	return "Stations-Playtestnotizen sind sauber genug fuer den naechsten spielbaren Slice"


static func _recommended_next_task(status: String, action_items: Array) -> String:
	if status == "blocked":
		return "TASK_727 - repair Station Scenario Playtest Notes"
	if status == "needs_visible_playtest":
		return "TASK_727 - run visible F6/Host Client station playtest"
	if status == "needs_targeted_polish":
		if not action_items.is_empty() and typeof(action_items[0]) == TYPE_DICTIONARY:
			return String(Dictionary(action_items[0]).get("recommended_task", "TASK_729 - Station Scenario Targeted Playtest Polish"))
		return "TASK_729 - Station Scenario Targeted Playtest Polish"
	return "TASK_729 - Next playable Station Scenario slice"


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
