class_name StationReentryFirefightReleaseCandidateTesterRun
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_release_candidate_tester_run.v1"
const EXPECTED_HANDOFF_PACKET_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_release_candidate_handoff_packet.v1"
const EXPECTED_HANDOFF_PACKET_TASK_ID: String = "TASK_806"
const DEFAULT_HANDOFF_PACKET_MANIFEST_PATH: String = "tmp/station_reentry_firefight_release_candidate_handoff_packet.json"
const DEFAULT_TESTER_RUN_MANIFEST_PATH: String = "tmp/station_reentry_firefight_release_candidate_tester_run.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/project_current_state_handbook_reentry_2026_07_01.html"

const REQUIRED_TESTER_RUN_CHECKS: Array[Dictionary] = [
	{"id": "handoff_packet_used", "label": "TASK_806 Handoff-Packet wurde benutzt"},
	{"id": "fresh_release_exe_started", "label": "Frische Release-EXE wurde gestartet"},
	{"id": "singleplayer_homebase_actionable", "label": "Einzelspieler/Homebase ist handlungsfaehig"},
	{"id": "dropship_payload_visible", "label": "Dropship-Payload ist sichtbar und korrekt"},
	{"id": "mission_start_reachable", "label": "Missionsstart ist erreichbar"},
	{"id": "host_client_started", "label": "Host/Client-Fenster wurden gestartet"},
	{"id": "host_client_roles_readable", "label": "Host/Client-Rollen sind lesbar"},
	{"id": "first_preview_readable", "label": "Erste Preview vor GO ist lesbar"},
	{"id": "first_go_firefight_reacts", "label": "Erster GO/Firefight reagiert"},
	{"id": "exit_or_debrief_visible", "label": "Exit/Debrief-Pfad ist sichtbar"},
	{"id": "performance_feels_fast", "label": "Performance fuehlt sich schnell genug an"},
	{"id": "hud_does_not_block", "label": "HUD blockiert keine Pflichtaktion"},
	{"id": "tester_notes_exported", "label": "Tester-Run-Notizen wurden exportiert"},
]

const ISSUE_TO_ACTION: Dictionary = {
	"stale_handoff_or_exe": "Refresh release export, shortcut and rerun TASK_806",
	"singleplayer_homebase_blocked": "BUGFIX - Singleplayer Release Homebase Start Bootstrap follow-up",
	"dropship_payload_wrong": "TASK_765 - Station Reentry Dropship Boarding Bridge Polish",
	"mission_start_blocked": "TASK_766 - Station Reentry Start Permission Bridge Polish",
	"host_client_not_working": "TASK_611 - Host Client Two Window Launch Helper",
	"roles_confusing": "TASK_773 - Station Reentry Host Client Identity Cue Polish",
	"preview_unclear": "TASK_768 - Station Reentry First Mission Preview Polish",
	"firefight_not_reacting": "TASK_777 - Station Reentry Firefight Tension Feel Pass",
	"exit_or_debrief_missing": "TASK_743 - Station Scenario Debrief Handoff Cue",
	"performance_slow": "TASK_769 - Station Reentry Performance Feel Pass",
	"hud_blocks_action": "TASK_733 - Station Scenario HUD Overlap Pass",
}

const ISSUE_FLAG_IDS: Array[String] = [
	"stale_handoff_or_exe",
	"singleplayer_homebase_blocked",
	"dropship_payload_wrong",
	"mission_start_blocked",
	"host_client_not_working",
	"roles_confusing",
	"preview_unclear",
	"firefight_not_reacting",
	"exit_or_debrief_missing",
	"performance_slow",
	"hud_blocks_action",
]


static func build_snapshot(handoff_packet_snapshot: Dictionary = {}, tester_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var source_valid: bool = _source_is_valid(handoff_packet_snapshot)
	var source_read_only: bool = _source_is_read_only(handoff_packet_snapshot)
	var handoff_ready: bool = bool(handoff_packet_snapshot.get("release_candidate_handoff_ready", false))
	var checks: Array = _build_checks(tester_notes)
	var missing_check_ids: Array[String] = _missing_check_ids(checks)
	var issue_flags: Array = _build_issue_flags(tester_notes)
	var findings: Array = _build_source_findings(source_valid, source_read_only, handoff_ready, handoff_packet_snapshot)
	var action_items: Array = []
	var active_issue_ids: Array[String] = _add_issue_findings(findings, action_items, issue_flags)
	var tester_run_done: bool = _read_bool(tester_notes, "reentry_firefight_release_candidate_tester_run.tester_run_done")
	var tester_run_reviewed: bool = _read_bool(tester_notes, "reentry_firefight_release_candidate_tester_run.tester_run_reviewed")
	var release_exe_started: bool = _read_bool(tester_notes, "reentry_firefight_release_candidate_tester_run.fresh_release_exe_started")
	var status: String = _build_status(source_valid, source_read_only, handoff_ready, tester_run_done, tester_run_reviewed, release_exe_started, missing_check_ids, active_issue_ids)
	if status == "needs_release_candidate_tester_run":
		findings.append(_finding("tester_run_open", "manual", "Release-Candidate-Tester-Run fehlt oder ist nicht bewusst abgeschlossen.", "TASK_807 - run release candidate tester run"))
	elif status == "needs_tester_run_completion":
		findings.append(_finding("tester_run_checks_missing", "manual", "Tester-Run ist angefangen, aber Checks fehlen: %s" % ", ".join(PackedStringArray(missing_check_ids)), "TASK_807 - complete missing tester-run checks"))

	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_807",
		"source_task_id": EXPECTED_HANDOFF_PACKET_TASK_ID,
		"source_schema": String(handoff_packet_snapshot.get("schema", "")),
		"source_status": String(handoff_packet_snapshot.get("status", "")),
		"source_handoff_packet_manifest_path": String(options.get("handoff_packet_manifest_path", DEFAULT_HANDOFF_PACKET_MANIFEST_PATH)),
		"runtime_authority": "read-only tester run over TASK_806 handoff packet and optional tester notes",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"source_valid": source_valid,
		"source_read_only": source_read_only,
		"release_candidate_handoff_ready": handoff_ready,
		"tester_run_required": true,
		"tester_run_done": tester_run_done,
		"tester_run_reviewed": tester_run_reviewed,
		"fresh_release_exe_started": release_exe_started,
		"release_dir": String(handoff_packet_snapshot.get("release_dir", "")),
		"exe_path": String(handoff_packet_snapshot.get("exe_path", "")),
		"pck_path": String(handoff_packet_snapshot.get("pck_path", "")),
		"scenario_path": String(handoff_packet_snapshot.get("scenario_path", "")),
		"workbench_path": String(handoff_packet_snapshot.get("workbench_path", "")),
		"workbench_file_uri": String(handoff_packet_snapshot.get("workbench_file_uri", "")),
		"expected_host_role": String(handoff_packet_snapshot.get("expected_host_role", "")),
		"expected_client_role": String(handoff_packet_snapshot.get("expected_client_role", "")),
		"expected_decision_line": String(handoff_packet_snapshot.get("expected_decision_line", "")),
		"expected_guard_line": String(handoff_packet_snapshot.get("expected_guard_line", "")),
		"commands": Dictionary(handoff_packet_snapshot.get("commands", {})).duplicate(true),
		"open_risks": Array(handoff_packet_snapshot.get("open_risks", [])).duplicate(true),
		"handoff_notes": Dictionary(handoff_packet_snapshot.get("handoff_notes", {})).duplicate(true),
		"tester_notes": _tester_notes(tester_notes),
		"required_tester_run_checks": checks,
		"required_check_count": checks.size(),
		"completed_check_count": _count_completed_checks(checks),
		"missing_check_ids": missing_check_ids,
		"issue_flags": issue_flags,
		"active_issue_count": active_issue_ids.size(),
		"active_issue_ids": active_issue_ids,
		"findings": findings,
		"finding_count": findings.size(),
		"action_items": action_items,
		"action_item_count": action_items.size(),
		"status": status,
		"release_candidate_tester_run_ready": status == "ready_for_release_candidate_tester_run_acceptance",
		"summary": _summary(status, missing_check_ids, active_issue_ids),
		"recommended_next_task": _recommended_next_task(status, action_items, handoff_packet_snapshot),
		"report_path": String(options.get("report_path", DEFAULT_REPORT_PATH)),
		"manifest_path": String(options.get("manifest_path", DEFAULT_TESTER_RUN_MANIFEST_PATH)),
	}


static func write_manifest(path: String = DEFAULT_TESTER_RUN_MANIFEST_PATH, handoff_packet_snapshot: Dictionary = {}, tester_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var merged_options: Dictionary = options.duplicate(true)
	merged_options["manifest_path"] = path
	var snapshot: Dictionary = build_snapshot(handoff_packet_snapshot, tester_notes, merged_options)
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
			and String(source.get("schema", "")) == EXPECTED_HANDOFF_PACKET_SCHEMA \
			and String(source.get("task_id", "")) == EXPECTED_HANDOFF_PACKET_TASK_ID


static func _source_is_read_only(source: Dictionary) -> bool:
	return bool(source.get("read_only", false)) \
			and not bool(source.get("ui_sets_gameplay_truth", true)) \
			and not bool(source.get("creates_navigation", true)) \
			and not bool(source.get("creates_command", true)) \
			and not bool(source.get("creates_fire_event", true)) \
			and not bool(source.get("creates_damage_event", true))


static func _build_checks(notes: Dictionary) -> Array:
	var checks: Array = []
	for check_def_variant in REQUIRED_TESTER_RUN_CHECKS:
		var check_def: Dictionary = Dictionary(check_def_variant)
		var id: String = String(check_def.get("id", ""))
		checks.append({
			"id": id,
			"label": String(check_def.get("label", id)),
			"checked": _read_bool(notes, "reentry_firefight_release_candidate_tester_run.%s" % id),
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return checks


static func _build_issue_flags(notes: Dictionary) -> Array:
	var flags: Array = []
	for id in ISSUE_FLAG_IDS:
		flags.append({
			"id": String(id),
			"label": _issue_label(String(id)),
			"active": _read_bool(notes, "reentry_firefight_release_candidate_tester_run.issues.%s" % String(id)),
			"recommended_task": String(ISSUE_TO_ACTION.get(id, "")),
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return flags


static func _build_source_findings(source_valid: bool, source_read_only: bool, handoff_ready: bool, source: Dictionary) -> Array:
	var findings: Array = []
	if not source_valid:
		findings.append(_finding("invalid_task_806_handoff_packet", "blocker", "TASK_806-Handoff-Packet fehlt oder hat Schema/Task-Konflikt.", "TASK_806 - Station Reentry Firefight Release Candidate Handoff Packet"))
	if source_valid and not source_read_only:
		findings.append(_finding("task_806_handoff_packet_not_read_only", "blocker", "TASK_806-Handoff-Packet verletzt read-only/UI-Truth-Grenzen.", "TASK_806 verifier rerun"))
	if source_valid and source_read_only and not handoff_ready:
		findings.append(_finding("task_806_handoff_packet_not_ready", "blocker", "TASK_806 ist nicht handoff-ready.", String(source.get("recommended_next_task", "TASK_806 rerun"))))
	return findings


static func _add_issue_findings(findings: Array, action_items: Array, issue_flags: Array) -> Array[String]:
	var active_ids: Array[String] = []
	for flag_variant in issue_flags:
		if typeof(flag_variant) != TYPE_DICTIONARY:
			continue
		var flag: Dictionary = Dictionary(flag_variant)
		if not bool(flag.get("active", false)):
			continue
		var id: String = String(flag.get("id", ""))
		var label: String = String(flag.get("label", id))
		var next_task: String = String(flag.get("recommended_task", "TASK_807 - rerun tester run"))
		active_ids.append(id)
		findings.append(_finding("tester_run_issue_%s" % id, "polish", label, next_task))
		action_items.append({
			"id": id,
			"label": label,
			"recommended_task": next_task,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return active_ids


static func _build_status(source_valid: bool, source_read_only: bool, handoff_ready: bool, tester_done: bool, tester_reviewed: bool, exe_started: bool, missing_check_ids: Array[String], active_issue_ids: Array[String]) -> String:
	if not source_valid or not source_read_only:
		return "blocked_until_handoff_packet"
	if not handoff_ready:
		return "blocked_until_handoff_packet_ready"
	if not tester_done or not tester_reviewed or not exe_started:
		return "needs_release_candidate_tester_run"
	if not missing_check_ids.is_empty():
		return "needs_tester_run_completion"
	if not active_issue_ids.is_empty():
		return "needs_targeted_tester_run_polish"
	return "ready_for_release_candidate_tester_run_acceptance"


static func _tester_notes(notes: Dictionary) -> Dictionary:
	var root: Dictionary = Dictionary(notes.get("reentry_firefight_release_candidate_tester_run", {}))
	return {
		"tester_summary": String(root.get("tester_summary", "")),
		"singleplayer_note": String(root.get("singleplayer_note", "")),
		"host_client_note": String(root.get("host_client_note", "")),
		"mission_note": String(root.get("mission_note", "")),
		"performance_note": String(root.get("performance_note", "")),
		"next_note": String(root.get("next_note", "")),
	}


static func _missing_check_ids(checks: Array) -> Array[String]:
	var missing: Array[String] = []
	for check_variant in checks:
		if typeof(check_variant) != TYPE_DICTIONARY:
			continue
		var check: Dictionary = Dictionary(check_variant)
		if not bool(check.get("checked", false)):
			missing.append(String(check.get("id", "")))
	return missing


static func _count_completed_checks(checks: Array) -> int:
	return checks.size() - _missing_check_ids(checks).size()


static func _summary(status: String, missing_check_ids: Array[String], active_issue_ids: Array[String]) -> String:
	match status:
		"blocked_until_handoff_packet":
			return "Tester-Run blockiert: TASK_806-Handoff-Packet fehlt oder ist ungueltig."
		"blocked_until_handoff_packet_ready":
			return "Tester-Run blockiert: Handoff-Packet ist noch nicht ready."
		"needs_release_candidate_tester_run":
			return "Release-Candidate-Tester-Run ist noch offen."
		"needs_tester_run_completion":
			return "Tester-Run braucht noch Checks: %s." % ", ".join(PackedStringArray(missing_check_ids))
		"needs_targeted_tester_run_polish":
			return "Tester-Run meldet konkrete Follow-ups: %s." % ", ".join(PackedStringArray(active_issue_ids))
		"ready_for_release_candidate_tester_run_acceptance":
			return "Tester-Run ist sauber genug fuer die Acceptance."
	return "Tester-Run ist unvollstaendig."


static func _recommended_next_task(status: String, action_items: Array, source: Dictionary) -> String:
	match status:
		"blocked_until_handoff_packet":
			return String(source.get("recommended_next_task", "TASK_806 - Station Reentry Firefight Release Candidate Handoff Packet"))
		"blocked_until_handoff_packet_ready":
			return String(source.get("recommended_next_task", "TASK_806 - complete release candidate handoff packet"))
		"needs_release_candidate_tester_run":
			return "TASK_807 - run release candidate tester run"
		"needs_tester_run_completion":
			return "TASK_807 - complete missing tester-run checks"
		"needs_targeted_tester_run_polish":
			if not action_items.is_empty():
				return String(Dictionary(action_items[0]).get("recommended_task", "TASK_807 - rerun tester run"))
			return "TASK_807 - rerun tester run"
		"ready_for_release_candidate_tester_run_acceptance":
			return "TASK_808 - Station Reentry Firefight Release Candidate Tester Run Acceptance"
	return "TASK_807 - repair release candidate tester run"


static func _issue_label(id: String) -> String:
	match id:
		"stale_handoff_or_exe":
			return "Handoff oder EXE wirkt stale"
		"singleplayer_homebase_blocked":
			return "Einzelspieler/Homebase ist blockiert"
		"dropship_payload_wrong":
			return "Dropship-Payload ist falsch"
		"mission_start_blocked":
			return "Missionsstart ist blockiert"
		"host_client_not_working":
			return "Host/Client funktioniert nicht sichtbar"
		"roles_confusing":
			return "Host/Client-Rollen sind verwirrend"
		"preview_unclear":
			return "Erste Preview ist unklar"
		"firefight_not_reacting":
			return "Erster GO/Firefight reagiert nicht"
		"exit_or_debrief_missing":
			return "Exit/Debrief fehlt"
		"performance_slow":
			return "Performance fuehlt sich zu langsam an"
		"hud_blocks_action":
			return "HUD blockiert eine Pflichtaktion"
	return id


static func _read_bool(source: Dictionary, dotted_path: String) -> bool:
	var current: Variant = source
	for part in dotted_path.split("."):
		if typeof(current) != TYPE_DICTIONARY:
			return false
		var dictionary: Dictionary = Dictionary(current)
		if not dictionary.has(part):
			return false
		current = dictionary.get(part)
	return bool(current)


static func _finding(id: String, severity: String, message: String, suggested_next: String) -> Dictionary:
	return {
		"id": id,
		"severity": severity,
		"message": message,
		"suggested_next": suggested_next,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}
