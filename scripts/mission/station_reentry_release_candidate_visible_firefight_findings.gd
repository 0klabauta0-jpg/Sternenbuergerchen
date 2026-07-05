class_name StationReentryReleaseCandidateVisibleFirefightFindings
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_release_candidate_visible_firefight_findings.v1"
const EXPECTED_SOURCE_SCHEMA: String = "sternenbuergerchen.station_reentry_release_candidate_real_window_firefight_sight_review.v1"
const EXPECTED_SOURCE_TASK_ID: String = "TASK_815"
const DEFAULT_SOURCE_MANIFEST_PATH: String = "tmp/station_reentry_release_candidate_real_window_firefight_sight_review.json"
const DEFAULT_FINDINGS_MANIFEST_PATH: String = "tmp/station_reentry_release_candidate_visible_firefight_findings.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/project_current_state_handbook_reentry_2026_07_01.html"

const REQUIRED_TRIAGE_CHECKS: PackedStringArray = [
	"manual_findings_review_done",
	"firefight_findings_reviewed",
	"primary_issue_chosen_or_none",
	"action_items_exported",
	"no_blocker_unassigned",
]

const FINDING_FLAG_IDS: PackedStringArray = [
	"shortcut_or_export_stale",
	"homebase_or_start_blocked",
	"drop_preview_go_unclear",
	"firefight_hud_unreadable",
	"next_action_unclear",
	"panel_overlap_visible",
	"performance_stutter_visible",
	"host_client_confusing",
	"visual_polish_needed",
]

const SOURCE_ISSUE_TO_FINDING: Dictionary = {
	"stale_export_or_shortcut": "shortcut_or_export_stale",
	"homebase_blocked_after_singleplayer": "homebase_or_start_blocked",
	"mission_start_blocked": "homebase_or_start_blocked",
	"drop_or_go_confusing": "drop_preview_go_unclear",
	"firefight_hud_unreadable": "firefight_hud_unreadable",
	"performance_or_stutter": "performance_stutter_visible",
	"visual_polish_needed": "visual_polish_needed",
}

const FINDING_TO_ACTION: Dictionary = {
	"shortcut_or_export_stale": "TASK_815 - refresh release export and taskbar shortcut",
	"homebase_or_start_blocked": "BUGFIX - Singleplayer Release Homebase Start Bootstrap follow-up",
	"drop_preview_go_unclear": "TASK_812/TASK_813 - tighten LZ, Drop, Preview and GO readability",
	"firefight_hud_unreadable": "TASK_817 - Station Reentry Release Candidate Targeted Firefight Polish",
	"next_action_unclear": "TASK_817 - Station Reentry Release Candidate Targeted Firefight Polish",
	"panel_overlap_visible": "TASK_817 - Station Reentry Release Candidate Targeted Firefight Polish",
	"performance_stutter_visible": "TASK_769 - Station Reentry Performance Feel Pass follow-up",
	"host_client_confusing": "TASK_770 - Station Reentry Host Client Next Order Sync follow-up",
	"visual_polish_needed": "TASK_817 - Station Reentry Release Candidate Targeted Firefight Polish",
}


static func build_snapshot(source_snapshot: Dictionary = {}, findings_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var findings: Array = []
	var action_items: Array = []
	var source_valid: bool = _source_is_valid(source_snapshot)
	var source_read_only: bool = _source_is_read_only(source_snapshot)
	var source_status: String = String(source_snapshot.get("status", ""))
	if not source_valid:
		findings.append(_finding("invalid_task_815_real_window_review", "blocker", "TASK_815-Real-Window-Review fehlt oder hat Schema/Task-Konflikt.", "TASK_815 - Station Reentry Release Candidate Real Window Firefight Sight Review"))
	if source_valid and not source_read_only:
		findings.append(_finding("task_815_real_window_review_not_read_only", "blocker", "TASK_815-Review verletzt read-only/UI-Truth-Grenzen.", "TASK_815 verifier rerun"))
	if source_valid and source_read_only and not _source_can_feed_findings(source_status):
		findings.append(_finding("task_815_real_window_review_not_ready", "manual", "TASK_815 ist noch nicht bereit fuer Findings: %s" % source_status, _source_next_task(source_snapshot)))

	var source_issue_ids: Array[String] = _normalized_source_issue_ids(source_snapshot)
	var triage_checks: Array = _build_triage_checks(findings_notes)
	var missing_check_ids: Array[String] = _missing_check_ids(triage_checks)
	var finding_flags: Array = _build_finding_flags(source_issue_ids, findings_notes)
	var active_finding_ids: Array[String] = _active_finding_ids(finding_flags)
	_add_action_items(findings, action_items, active_finding_ids)
	var blocker_count: int = _count_findings_by_severity(findings, "blocker")
	var manual_findings_review_done: bool = _read_bool(findings_notes, "manual_findings_review_done")
	var status: String = _build_status(source_valid, source_read_only, source_status, blocker_count, manual_findings_review_done, missing_check_ids, active_finding_ids)

	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_816",
		"source_task_id": EXPECTED_SOURCE_TASK_ID,
		"source_schema": String(source_snapshot.get("schema", "")),
		"source_status": source_status,
		"source_manifest_path": String(options.get("source_manifest_path", DEFAULT_SOURCE_MANIFEST_PATH)),
		"runtime_authority": "read-only findings over TASK_815 real-window firefight sight review",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"source_valid": source_valid,
		"source_read_only": source_read_only,
		"source_active_issue_ids": Array(source_snapshot.get("active_issue_ids", [])).duplicate(true),
		"source_missing_check_ids": Array(source_snapshot.get("missing_check_ids", [])).duplicate(true),
		"source_summary": String(source_snapshot.get("summary", "")),
		"firefight_hud_readout": String(source_snapshot.get("firefight_hud_readout", "")),
		"player_next_action_line": String(source_snapshot.get("player_next_action_line", "")),
		"player_why_line": String(source_snapshot.get("player_why_line", "")),
		"manual_findings_review_done": manual_findings_review_done,
		"visible_firefight_findings_reviewed": _read_bool(findings_notes, "firefight_findings_reviewed"),
		"triage_checks": triage_checks,
		"missing_check_ids": missing_check_ids,
		"finding_flags": finding_flags,
		"active_finding_ids": active_finding_ids,
		"active_finding_count": active_finding_ids.size(),
		"findings": findings,
		"finding_count": findings.size(),
		"action_items": action_items,
		"action_item_count": action_items.size(),
		"status": status,
		"summary": _build_summary(status, missing_check_ids, active_finding_ids),
		"recommended_next_task": _recommended_next_task(status, action_items),
		"report_path": String(options.get("report_path", DEFAULT_REPORT_PATH)),
		"manifest_path": String(options.get("manifest_path", DEFAULT_FINDINGS_MANIFEST_PATH)),
	}


static func write_manifest(path: String = DEFAULT_FINDINGS_MANIFEST_PATH, source_snapshot: Dictionary = {}, findings_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var merged_options: Dictionary = options.duplicate(true)
	merged_options["manifest_path"] = path
	var snapshot: Dictionary = build_snapshot(source_snapshot, findings_notes, merged_options)
	var dir_path: String = path.get_base_dir()
	if dir_path.strip_edges() != "":
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(snapshot, "\t"))
		file.close()
	return snapshot


static func _source_is_valid(source: Dictionary) -> bool:
	return not source.is_empty() \
			and String(source.get("schema", "")) == EXPECTED_SOURCE_SCHEMA \
			and String(source.get("task_id", "")) == EXPECTED_SOURCE_TASK_ID


static func _source_is_read_only(source: Dictionary) -> bool:
	return bool(source.get("read_only", false)) \
			and not bool(source.get("ui_sets_gameplay_truth", true)) \
			and not bool(source.get("creates_navigation", true)) \
			and not bool(source.get("creates_command", true)) \
			and not bool(source.get("creates_fire_event", true)) \
			and not bool(source.get("creates_damage_event", true)) \
			and not bool(source.get("sets_multiplayer_truth", true))


static func _source_can_feed_findings(source_status: String) -> bool:
	return source_status == "ready_for_release_candidate_iteration" or source_status == "needs_visible_firefight_findings"


static func _source_next_task(source: Dictionary) -> String:
	var next_task: String = String(source.get("recommended_next_task", "")).strip_edges()
	return next_task if next_task != "" else "TASK_815 - complete real-window firefight sight review"


static func _normalized_source_issue_ids(source: Dictionary) -> Array[String]:
	var normalized: Array[String] = []
	for source_issue_variant in Array(source.get("active_issue_ids", [])):
		var source_issue: String = String(source_issue_variant)
		var finding_id: String = String(SOURCE_ISSUE_TO_FINDING.get(source_issue, source_issue))
		if not normalized.has(finding_id):
			normalized.append(finding_id)
	return normalized


static func _build_triage_checks(notes: Dictionary) -> Array:
	var checks: Array = []
	for check_id in REQUIRED_TRIAGE_CHECKS:
		checks.append(_gate(String(check_id), _read_bool(notes, String(check_id)), _triage_label(String(check_id))))
	return checks


static func _build_finding_flags(source_issue_ids: Array[String], notes: Dictionary) -> Array:
	var flags: Array = []
	for finding_id in FINDING_FLAG_IDS:
		var id: String = String(finding_id)
		var active: bool = source_issue_ids.has(id) or _read_bool(notes, "issues.%s" % id) or _read_bool(notes, id)
		flags.append({
			"id": id,
			"label": _finding_label(id),
			"active": active,
			"from_task_815": source_issue_ids.has(id),
			"from_notes": _read_bool(notes, "issues.%s" % id) or _read_bool(notes, id),
			"recommended_task": String(FINDING_TO_ACTION.get(id, "TASK_817 - Station Reentry Release Candidate Targeted Firefight Polish")),
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return flags


static func _add_action_items(findings: Array, action_items: Array, active_finding_ids: Array[String]) -> void:
	for id in active_finding_ids:
		var label: String = _finding_label(id)
		var next_task: String = String(FINDING_TO_ACTION.get(id, "TASK_817 - Station Reentry Release Candidate Targeted Firefight Polish"))
		findings.append(_finding("visible_firefight_%s" % id, "polish", label, next_task))
		action_items.append({
			"id": id,
			"label": label,
			"recommended_task": next_task,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})


static func _build_status(source_valid: bool, source_read_only: bool, source_status: String, blocker_count: int, manual_findings_review_done: bool, missing_check_ids: Array[String], active_finding_ids: Array[String]) -> String:
	if not source_valid or not source_read_only or blocker_count > 0:
		return "blocked_until_task_815"
	if not _source_can_feed_findings(source_status):
		return "needs_task_815_real_window_review"
	if not manual_findings_review_done:
		return "needs_visible_firefight_findings_review"
	if not missing_check_ids.is_empty():
		return "needs_visible_firefight_findings_completion"
	if not active_finding_ids.is_empty():
		return "needs_targeted_visible_firefight_polish"
	return "ready_for_release_candidate_acceptance"


static func _recommended_next_task(status: String, action_items: Array) -> String:
	match status:
		"blocked_until_task_815":
			return "TASK_815 - Station Reentry Release Candidate Real Window Firefight Sight Review"
		"needs_task_815_real_window_review":
			return "TASK_815 - run or complete real-window firefight sight review"
		"needs_visible_firefight_findings_review":
			return "TASK_816 - review visible firefight findings"
		"needs_visible_firefight_findings_completion":
			return "TASK_816 - complete visible firefight findings triage"
		"needs_targeted_visible_firefight_polish":
			if not action_items.is_empty() and typeof(action_items[0]) == TYPE_DICTIONARY:
				return String(Dictionary(action_items[0]).get("recommended_task", "TASK_817 - Station Reentry Release Candidate Targeted Firefight Polish"))
			return "TASK_817 - Station Reentry Release Candidate Targeted Firefight Polish"
		"ready_for_release_candidate_acceptance":
			return "TASK_817 - Station Reentry Release Candidate Playable Build Acceptance"
	return "TASK_816 - Station Reentry Release Candidate Visible Firefight Findings"


static func _build_summary(status: String, missing_check_ids: Array[String], active_finding_ids: Array[String]) -> String:
	match status:
		"blocked_until_task_815":
			return "Visible-Firefight-Findings blockiert: TASK_815 fehlt, ist ungueltig oder nicht read-only."
		"needs_task_815_real_window_review":
			return "TASK_815-Fensterlauf ist noch nicht findings-faehig."
		"needs_visible_firefight_findings_review":
			return "Sichtbare Firefight-Findings muessen bewusst reviewed werden."
		"needs_visible_firefight_findings_completion":
			return "Findings-Triage unvollstaendig: %s" % ", ".join(PackedStringArray(missing_check_ids))
		"needs_targeted_visible_firefight_polish":
			return "Sichtbarer Firefight braucht gezielten Polish: %s" % ", ".join(PackedStringArray(active_finding_ids))
		"ready_for_release_candidate_acceptance":
			return "Keine sichtbaren Firefight-Findings offen; bereit fuer Acceptance."
	return "Visible-Firefight-Findings brauchen erneute Pruefung."


static func _missing_check_ids(checks: Array) -> Array[String]:
	var missing: Array[String] = []
	for check_variant in checks:
		var check: Dictionary = Dictionary(check_variant)
		if not bool(check.get("passed", false)):
			missing.append(String(check.get("id", "")))
	return missing


static func _active_finding_ids(flags: Array) -> Array[String]:
	var active: Array[String] = []
	for flag_variant in flags:
		var flag: Dictionary = Dictionary(flag_variant)
		if bool(flag.get("active", false)):
			active.append(String(flag.get("id", "")))
	return active


static func _gate(id: String, passed: bool, label: String) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"passed": passed,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _finding(id: String, severity: String, message: String, suggested_next: String) -> Dictionary:
	return {
		"id": id,
		"severity": severity,
		"message": message,
		"suggested_next": suggested_next,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _read_bool(source: Dictionary, dotted_key: String) -> bool:
	var direct_value: Variant = _get_path(source, dotted_key)
	if typeof(direct_value) == TYPE_BOOL:
		return bool(direct_value)
	if typeof(direct_value) == TYPE_STRING:
		return _string_to_bool(String(direct_value))
	var controls: Dictionary = Dictionary(source.get("controls", {}))
	var control_value: Variant = _get_path(controls, dotted_key)
	if typeof(control_value) == TYPE_BOOL:
		return bool(control_value)
	if typeof(control_value) == TYPE_STRING:
		return _string_to_bool(String(control_value))
	return false


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


static func _string_to_bool(value: String) -> bool:
	var normalized: String = value.strip_edges().to_lower()
	return normalized == "true" or normalized == "yes" or normalized == "1" or normalized == "ok"


static func _count_findings_by_severity(findings: Array, severity: String) -> int:
	var count: int = 0
	for finding_variant in findings:
		if typeof(finding_variant) == TYPE_DICTIONARY and String(Dictionary(finding_variant).get("severity", "")) == severity:
			count += 1
	return count


static func _triage_label(id: String) -> String:
	match id:
		"manual_findings_review_done":
			return "Findings-Review bewusst abgeschlossen"
		"firefight_findings_reviewed":
			return "Firefight-Befunde gelesen und bewertet"
		"primary_issue_chosen_or_none":
			return "Primaeres Issue gewaehlt oder bewusst keines"
		"action_items_exported":
			return "Action Items exportiert"
		"no_blocker_unassigned":
			return "Kein Blocker ohne Zieltask"
	return id


static func _finding_label(id: String) -> String:
	match id:
		"shortcut_or_export_stale":
			return "Shortcut oder Release-Export ist stale"
		"homebase_or_start_blocked":
			return "Einzelspieler, Homebase oder Start Mission blockiert"
		"drop_preview_go_unclear":
			return "LZ, Drop, Preview oder GO ist unklar"
		"firefight_hud_unreadable":
			return "Erster Firefight-HUD-Blick ist unlesbar"
		"next_action_unclear":
			return "Naechster Spielergriff ist unklar"
		"panel_overlap_visible":
			return "Sichtbare Panels ueberlappen oder blockieren"
		"performance_stutter_visible":
			return "Erster Firefight stottert sichtbar"
		"host_client_confusing":
			return "Host/Client-Kontext wirkt verwirrend"
		"visual_polish_needed":
			return "Sichtbarer Polish-Bedarf im Firefight"
	return id
