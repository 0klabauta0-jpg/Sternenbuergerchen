class_name StationReentryFirefightReleaseCandidateVisibleShipSmoke
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_release_candidate_visible_ship_smoke.v1"
const EXPECTED_SHIP_READINESS_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_release_candidate_ship_readiness.v1"
const EXPECTED_SHIP_READINESS_TASK_ID: String = "TASK_803"
const DEFAULT_SHIP_READINESS_MANIFEST_PATH: String = "tmp/station_reentry_firefight_release_candidate_ship_readiness.json"
const DEFAULT_VISIBLE_SHIP_SMOKE_MANIFEST_PATH: String = "tmp/station_reentry_firefight_release_candidate_visible_ship_smoke.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/project_current_state_handbook_reentry_2026_07_01.html"

const REQUIRED_VISIBLE_SHIP_SMOKE_CHECKS: Array[Dictionary] = [
	{"id": "fresh_release_folder_used", "label": "Frischer Spieleordner wird benutzt"},
	{"id": "release_exe_started", "label": "Release-EXE wurde sichtbar gestartet"},
	{"id": "singleplayer_clicked", "label": "Einzelspieler wurde geklickt"},
	{"id": "homebase_not_blocked", "label": "Homebase ist danach handlungsfaehig"},
	{"id": "dropship_payload_ready", "label": "Dropship-Payload ist bereit und nicht vermischt"},
	{"id": "mission_start_reachable", "label": "Missionsstart ist erreichbar"},
	{"id": "host_client_windows_open", "label": "Host- und Client-Fenster sind sichtbar"},
	{"id": "host_client_roles_distinct", "label": "Host/Client-Rollen sind unterscheidbar"},
	{"id": "no_stale_taskbar_link", "label": "Keine alte Taskleisten-/Shortcut-EXE verwendet"},
	{"id": "smoke_notes_exported", "label": "Workbench-/Smoke-Notizen wurden exportiert"},
]

const ISSUE_TO_ACTION: Dictionary = {
	"stale_export_or_link": "Refresh release export, taskbar shortcut and rerun visible ship smoke",
	"singleplayer_homebase_blocked": "BUGFIX - Singleplayer Release Homebase Start Bootstrap follow-up",
	"dropship_payload_missing": "TASK_765 - Station Reentry Dropship Boarding Bridge Polish",
	"mission_start_unreachable": "TASK_766 - Station Reentry Start Permission Bridge Polish",
	"host_client_not_visible": "TASK_611 - Host Client Two Window Launch Helper",
	"roles_confusing": "TASK_773 - Station Reentry Host Client Identity Cue Polish",
	"runtime_error_on_start": "TASK_524 - Export Warning Noise Cleanup",
}

const ISSUE_FLAG_IDS: Array[String] = [
	"stale_export_or_link",
	"singleplayer_homebase_blocked",
	"dropship_payload_missing",
	"mission_start_unreachable",
	"host_client_not_visible",
	"roles_confusing",
	"runtime_error_on_start",
]


static func build_snapshot(ship_readiness_snapshot: Dictionary = {}, smoke_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var source_valid: bool = _source_is_valid(ship_readiness_snapshot)
	var source_read_only: bool = _source_is_read_only(ship_readiness_snapshot)
	var ship_ready: bool = bool(ship_readiness_snapshot.get("ship_readiness_ready", false))
	var required_checks: Array = _build_required_checks(smoke_notes)
	var missing_check_ids: Array[String] = _missing_check_ids(required_checks)
	var issue_flags: Array = _build_issue_flags(smoke_notes)
	var findings: Array = _build_source_findings(source_valid, source_read_only, ship_ready, ship_readiness_snapshot)
	var action_items: Array = []
	var active_issue_ids: Array[String] = _add_issue_findings(findings, action_items, issue_flags)
	var manual_smoke_done: bool = _read_bool(smoke_notes, "reentry_firefight_release_candidate_visible_ship_smoke.manual_smoke_done")
	var visible_ship_smoke_done: bool = _read_bool(smoke_notes, "reentry_firefight_release_candidate_visible_ship_smoke.visible_ship_smoke_done")
	var release_exe_started: bool = _read_bool(smoke_notes, "reentry_firefight_release_candidate_visible_ship_smoke.release_exe_started")
	var host_client_started: bool = _read_bool(smoke_notes, "reentry_firefight_release_candidate_visible_ship_smoke.host_client_windows_open")
	var status: String = _build_status(source_valid, source_read_only, ship_ready, manual_smoke_done, visible_ship_smoke_done, release_exe_started, host_client_started, missing_check_ids, active_issue_ids)
	if status == "needs_visible_ship_smoke":
		findings.append(_finding("visible_ship_smoke_open", "manual", "Sichtbarer EXE-/Host-Client-Ship-Smoke ist offen oder nicht bewusst abgeschlossen.", "TASK_804 - run visible release ship smoke"))
	elif status == "needs_ship_smoke_completion":
		findings.append(_finding("visible_ship_smoke_checks_missing", "manual", "Sichtbarer Ship-Smoke ist angefangen, aber Pflichtchecks fehlen: %s" % ", ".join(PackedStringArray(missing_check_ids)), "TASK_804 - complete visible ship smoke checks"))

	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_804",
		"source_task_id": EXPECTED_SHIP_READINESS_TASK_ID,
		"source_schema": String(ship_readiness_snapshot.get("schema", "")),
		"source_status": String(ship_readiness_snapshot.get("status", "")),
		"source_ship_readiness_manifest_path": String(options.get("ship_readiness_manifest_path", DEFAULT_SHIP_READINESS_MANIFEST_PATH)),
		"runtime_authority": "read-only visible ship smoke over TASK_803 ship readiness and optional workbench notes",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"source_valid": source_valid,
		"source_read_only": source_read_only,
		"ship_readiness_ready": ship_ready,
		"manual_smoke_required": true,
		"manual_smoke_done": manual_smoke_done,
		"visible_ship_smoke_done": visible_ship_smoke_done,
		"release_exe_started": release_exe_started,
		"host_client_started": host_client_started,
		"release_dir": String(ship_readiness_snapshot.get("release_dir", "")),
		"exe_path": String(ship_readiness_snapshot.get("exe_path", "")),
		"pck_path": String(ship_readiness_snapshot.get("pck_path", "")),
		"scenario_path": String(ship_readiness_snapshot.get("scenario_path", "")),
		"workbench_path": String(ship_readiness_snapshot.get("workbench_path", "")),
		"workbench_file_uri": String(ship_readiness_snapshot.get("workbench_file_uri", "")),
		"expected_host_role": String(ship_readiness_snapshot.get("expected_host_role", "")),
		"expected_client_role": String(ship_readiness_snapshot.get("expected_client_role", "")),
		"expected_decision_line": String(ship_readiness_snapshot.get("expected_decision_line", "")),
		"expected_guard_line": String(ship_readiness_snapshot.get("expected_guard_line", "")),
		"commands": Dictionary(ship_readiness_snapshot.get("commands", {})).duplicate(true),
		"ship_readiness_items": Array(ship_readiness_snapshot.get("ship_readiness_items", [])).duplicate(true),
		"open_risks": Array(ship_readiness_snapshot.get("open_risks", [])).duplicate(true),
		"operator_instruction": String(ship_readiness_snapshot.get("operator_instruction", "")),
		"required_visible_ship_smoke_checks": required_checks,
		"required_check_count": required_checks.size(),
		"completed_check_count": _count_completed_checks(required_checks),
		"missing_check_ids": missing_check_ids,
		"issue_flags": issue_flags,
		"active_issue_count": active_issue_ids.size(),
		"active_issue_ids": active_issue_ids,
		"findings": findings,
		"finding_count": findings.size(),
		"action_items": action_items,
		"action_item_count": action_items.size(),
		"status": status,
		"visible_ship_smoke_ready": status == "ready_for_release_candidate_delivery_review",
		"summary": _summary(status, missing_check_ids, active_issue_ids),
		"recommended_next_task": _recommended_next_task(status, action_items, ship_readiness_snapshot),
		"report_path": String(options.get("report_path", DEFAULT_REPORT_PATH)),
		"manifest_path": String(options.get("manifest_path", DEFAULT_VISIBLE_SHIP_SMOKE_MANIFEST_PATH)),
	}


static func write_manifest(path: String = DEFAULT_VISIBLE_SHIP_SMOKE_MANIFEST_PATH, ship_readiness_snapshot: Dictionary = {}, smoke_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var merged_options: Dictionary = options.duplicate(true)
	merged_options["manifest_path"] = path
	var snapshot: Dictionary = build_snapshot(ship_readiness_snapshot, smoke_notes, merged_options)
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
			and String(source.get("schema", "")) == EXPECTED_SHIP_READINESS_SCHEMA \
			and String(source.get("task_id", "")) == EXPECTED_SHIP_READINESS_TASK_ID


static func _source_is_read_only(source: Dictionary) -> bool:
	return bool(source.get("read_only", false)) \
			and not bool(source.get("ui_sets_gameplay_truth", true)) \
			and not bool(source.get("creates_navigation", true)) \
			and not bool(source.get("creates_command", true)) \
			and not bool(source.get("creates_fire_event", true)) \
			and not bool(source.get("creates_damage_event", true))


static func _build_required_checks(notes: Dictionary) -> Array:
	var checks: Array = []
	for check_def_variant in REQUIRED_VISIBLE_SHIP_SMOKE_CHECKS:
		var check_def: Dictionary = Dictionary(check_def_variant)
		var id: String = String(check_def.get("id", ""))
		checks.append({
			"id": id,
			"label": String(check_def.get("label", id)),
			"checked": _read_bool(notes, "reentry_firefight_release_candidate_visible_ship_smoke.%s" % id),
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
			"active": _read_bool(notes, "reentry_firefight_release_candidate_visible_ship_smoke.issues.%s" % String(id)),
			"recommended_task": String(ISSUE_TO_ACTION.get(id, "")),
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return flags


static func _build_source_findings(source_valid: bool, source_read_only: bool, ship_ready: bool, source: Dictionary) -> Array:
	var findings: Array = []
	if not source_valid:
		findings.append(_finding("invalid_task_803_ship_readiness", "blocker", "TASK_803-Ship-Readiness fehlt oder hat Schema/Task-Konflikt.", "TASK_803 - Station Reentry Firefight Release Candidate Ship Readiness"))
	if source_valid and not source_read_only:
		findings.append(_finding("task_803_ship_readiness_not_read_only", "blocker", "TASK_803-Ship-Readiness verletzt read-only/UI-Truth-Grenzen.", "TASK_803 verifier rerun"))
	if source_valid and source_read_only and not ship_ready:
		findings.append(_finding("task_803_ship_readiness_not_ready", "blocker", "TASK_803 ist nicht ship-ready.", String(source.get("recommended_next_task", "TASK_803 rerun"))))
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
		var next_task: String = String(flag.get("recommended_task", "TASK_804 - rerun visible ship smoke"))
		active_ids.append(id)
		findings.append(_finding("visible_ship_smoke_issue_%s" % id, "polish", label, next_task))
		action_items.append({
			"id": id,
			"label": label,
			"recommended_task": next_task,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return active_ids


static func _build_status(source_valid: bool, source_read_only: bool, ship_ready: bool, manual_done: bool, visible_done: bool, exe_started: bool, host_client_started: bool, missing_check_ids: Array[String], active_issue_ids: Array[String]) -> String:
	if not source_valid or not source_read_only:
		return "blocked_until_ship_readiness"
	if not ship_ready:
		return "blocked_until_ship_readiness"
	if not manual_done or not visible_done or not exe_started or not host_client_started:
		return "needs_visible_ship_smoke"
	if not missing_check_ids.is_empty():
		return "needs_ship_smoke_completion"
	if not active_issue_ids.is_empty():
		return "needs_targeted_ship_smoke_polish"
	return "ready_for_release_candidate_delivery_review"


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
		"blocked_until_ship_readiness":
			return "Visible Ship-Smoke blockiert: TASK_803-Ship-Readiness fehlt, ist ungueltig oder nicht bereit."
		"needs_visible_ship_smoke":
			return "Sichtbarer EXE-/Host-Client-Ship-Smoke ist noch offen."
		"needs_ship_smoke_completion":
			return "Sichtbarer Ship-Smoke braucht noch Checks: %s." % ", ".join(PackedStringArray(missing_check_ids))
		"needs_targeted_ship_smoke_polish":
			return "Sichtbarer Ship-Smoke meldet konkrete Follow-ups: %s." % ", ".join(PackedStringArray(active_issue_ids))
		"ready_for_release_candidate_delivery_review":
			return "Sichtbarer Ship-Smoke ist sauber; naechster Schritt ist die Delivery-Review."
	return "Visible Ship-Smoke ist unvollstaendig."


static func _recommended_next_task(status: String, action_items: Array, source: Dictionary) -> String:
	match status:
		"blocked_until_ship_readiness":
			return String(source.get("recommended_next_task", "TASK_803 - Station Reentry Firefight Release Candidate Ship Readiness"))
		"needs_visible_ship_smoke":
			return "TASK_804 - run visible release ship smoke"
		"needs_ship_smoke_completion":
			return "TASK_804 - complete visible ship smoke checks"
		"needs_targeted_ship_smoke_polish":
			if not action_items.is_empty():
				return String(Dictionary(action_items[0]).get("recommended_task", "TASK_804 - rerun visible ship smoke"))
			return "TASK_804 - rerun visible ship smoke"
		"ready_for_release_candidate_delivery_review":
			return "TASK_805 - Station Reentry Firefight Release Candidate Delivery Review"
	return "TASK_804 - repair visible release ship smoke"


static func _issue_label(id: String) -> String:
	match id:
		"stale_export_or_link":
			return "Alter Export oder alte Verknuepfung wurde benutzt"
		"singleplayer_homebase_blocked":
			return "Einzelspieler/Homebase ist im Release blockiert"
		"dropship_payload_missing":
			return "Dropship-Payload fehlt oder ist nicht bereit"
		"mission_start_unreachable":
			return "Missionsstart ist aus der Homebase nicht erreichbar"
		"host_client_not_visible":
			return "Host/Client-Fenster sind nicht sichtbar"
		"roles_confusing":
			return "Host/Client- oder Fireteam-Rollen sind verwirrend"
		"runtime_error_on_start":
			return "Runtime-Start erzeugt einen Fehler"
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
