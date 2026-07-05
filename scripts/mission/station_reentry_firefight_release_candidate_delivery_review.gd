class_name StationReentryFirefightReleaseCandidateDeliveryReview
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_release_candidate_delivery_review.v1"
const EXPECTED_VISIBLE_SMOKE_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_release_candidate_visible_ship_smoke.v1"
const EXPECTED_VISIBLE_SMOKE_TASK_ID: String = "TASK_804"
const DEFAULT_VISIBLE_SMOKE_MANIFEST_PATH: String = "tmp/station_reentry_firefight_release_candidate_visible_ship_smoke.json"
const DEFAULT_DELIVERY_REVIEW_MANIFEST_PATH: String = "tmp/station_reentry_firefight_release_candidate_delivery_review.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/project_current_state_handbook_reentry_2026_07_01.html"

const REQUIRED_DELIVERY_CHECKS: Array[Dictionary] = [
	{"id": "visible_ship_smoke_ready", "label": "TASK_804 sichtbarer Ship-Smoke ist gruen"},
	{"id": "release_files_named", "label": "EXE/PCK/Spieleordner sind im Review benannt"},
	{"id": "start_instruction_written", "label": "Spielstart-Hinweis ist geschrieben"},
	{"id": "host_client_instruction_written", "label": "Host/Client-Hinweis ist geschrieben"},
	{"id": "known_risks_reviewed", "label": "Bekannte Restrisiken sind gelesen"},
	{"id": "known_risks_accepted", "label": "Restrisiken sind fuer diesen Handoff akzeptiert"},
	{"id": "report_export_saved", "label": "Report-/Workbench-Export ist gesichert"},
	{"id": "shortcut_warning_written", "label": "Stale-Link-/Taskleisten-Hinweis ist sichtbar"},
	{"id": "next_handoff_task_chosen", "label": "Naechster Handoff-Schritt ist benannt"},
]

const ISSUE_TO_ACTION: Dictionary = {
	"stale_delivery_package": "Refresh release export, shortcut and rerun TASK_804",
	"release_files_missing": "TASK_803 - Station Reentry Firefight Release Candidate Ship Readiness",
	"start_instruction_unclear": "TASK_806 - Station Reentry Firefight Release Candidate Handoff Packet",
	"host_client_instruction_unclear": "TASK_773 - Station Reentry Host Client Identity Cue Polish",
	"risks_not_accepted": "TASK_805 - resolve or accept delivery risks",
	"report_export_missing": "TASK_805 - export delivery review notes",
	"visible_polish_needed": "TASK_806 - Station Reentry Firefight Release Candidate Handoff Packet",
}

const ISSUE_FLAG_IDS: Array[String] = [
	"stale_delivery_package",
	"release_files_missing",
	"start_instruction_unclear",
	"host_client_instruction_unclear",
	"risks_not_accepted",
	"report_export_missing",
	"visible_polish_needed",
]


static func build_snapshot(visible_smoke_snapshot: Dictionary = {}, review_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var source_valid: bool = _source_is_valid(visible_smoke_snapshot)
	var source_read_only: bool = _source_is_read_only(visible_smoke_snapshot)
	var visible_smoke_ready: bool = bool(visible_smoke_snapshot.get("visible_ship_smoke_ready", false))
	var required_checks: Array = _build_required_checks(visible_smoke_snapshot, review_notes)
	var missing_check_ids: Array[String] = _missing_check_ids(required_checks)
	var issue_flags: Array = _build_issue_flags(review_notes)
	var findings: Array = _build_source_findings(source_valid, source_read_only, visible_smoke_ready, visible_smoke_snapshot)
	var action_items: Array = []
	var active_issue_ids: Array[String] = _add_issue_findings(findings, action_items, issue_flags)
	var review_done: bool = _read_bool(review_notes, "reentry_firefight_release_candidate_delivery_review.delivery_review_done")
	var delivery_reviewed: bool = _read_bool(review_notes, "reentry_firefight_release_candidate_delivery_review.delivery_reviewed")
	var status: String = _build_status(source_valid, source_read_only, visible_smoke_ready, review_done, delivery_reviewed, missing_check_ids, active_issue_ids)
	if status == "needs_delivery_review":
		findings.append(_finding("delivery_review_open", "manual", "Delivery-Review fehlt oder ist nicht bewusst abgeschlossen.", "TASK_805 - complete delivery review"))
	elif status == "needs_delivery_review_completion":
		findings.append(_finding("delivery_review_checks_missing", "manual", "Delivery-Review ist angefangen, aber Pflichtchecks fehlen: %s" % ", ".join(PackedStringArray(missing_check_ids)), "TASK_805 - complete missing delivery checks"))

	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_805",
		"source_task_id": EXPECTED_VISIBLE_SMOKE_TASK_ID,
		"source_schema": String(visible_smoke_snapshot.get("schema", "")),
		"source_status": String(visible_smoke_snapshot.get("status", "")),
		"source_visible_smoke_manifest_path": String(options.get("visible_smoke_manifest_path", DEFAULT_VISIBLE_SMOKE_MANIFEST_PATH)),
		"runtime_authority": "read-only delivery review over TASK_804 visible ship smoke and optional review notes",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"source_valid": source_valid,
		"source_read_only": source_read_only,
		"visible_ship_smoke_ready": visible_smoke_ready,
		"delivery_review_required": true,
		"delivery_review_done": review_done,
		"delivery_reviewed": delivery_reviewed,
		"release_dir": String(visible_smoke_snapshot.get("release_dir", "")),
		"exe_path": String(visible_smoke_snapshot.get("exe_path", "")),
		"pck_path": String(visible_smoke_snapshot.get("pck_path", "")),
		"scenario_path": String(visible_smoke_snapshot.get("scenario_path", "")),
		"workbench_path": String(visible_smoke_snapshot.get("workbench_path", "")),
		"workbench_file_uri": String(visible_smoke_snapshot.get("workbench_file_uri", "")),
		"expected_host_role": String(visible_smoke_snapshot.get("expected_host_role", "")),
		"expected_client_role": String(visible_smoke_snapshot.get("expected_client_role", "")),
		"expected_decision_line": String(visible_smoke_snapshot.get("expected_decision_line", "")),
		"expected_guard_line": String(visible_smoke_snapshot.get("expected_guard_line", "")),
		"commands": Dictionary(visible_smoke_snapshot.get("commands", {})).duplicate(true),
		"open_risks": Array(visible_smoke_snapshot.get("open_risks", [])).duplicate(true),
		"operator_instruction": String(visible_smoke_snapshot.get("operator_instruction", "")),
		"delivery_notes": _delivery_notes(review_notes),
		"required_delivery_checks": required_checks,
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
		"release_candidate_delivery_ready": status == "ready_for_release_candidate_handoff_packet",
		"summary": _summary(status, missing_check_ids, active_issue_ids),
		"recommended_next_task": _recommended_next_task(status, action_items, visible_smoke_snapshot),
		"report_path": String(options.get("report_path", DEFAULT_REPORT_PATH)),
		"manifest_path": String(options.get("manifest_path", DEFAULT_DELIVERY_REVIEW_MANIFEST_PATH)),
	}


static func write_manifest(path: String = DEFAULT_DELIVERY_REVIEW_MANIFEST_PATH, visible_smoke_snapshot: Dictionary = {}, review_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var merged_options: Dictionary = options.duplicate(true)
	merged_options["manifest_path"] = path
	var snapshot: Dictionary = build_snapshot(visible_smoke_snapshot, review_notes, merged_options)
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
			and String(source.get("schema", "")) == EXPECTED_VISIBLE_SMOKE_SCHEMA \
			and String(source.get("task_id", "")) == EXPECTED_VISIBLE_SMOKE_TASK_ID


static func _source_is_read_only(source: Dictionary) -> bool:
	return bool(source.get("read_only", false)) \
			and not bool(source.get("ui_sets_gameplay_truth", true)) \
			and not bool(source.get("creates_navigation", true)) \
			and not bool(source.get("creates_command", true)) \
			and not bool(source.get("creates_fire_event", true)) \
			and not bool(source.get("creates_damage_event", true))


static func _build_required_checks(source: Dictionary, notes: Dictionary) -> Array:
	var checks: Array = []
	for check_def_variant in REQUIRED_DELIVERY_CHECKS:
		var check_def: Dictionary = Dictionary(check_def_variant)
		var id: String = String(check_def.get("id", ""))
		checks.append({
			"id": id,
			"label": String(check_def.get("label", id)),
			"checked": _check_is_done(id, source, notes),
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return checks


static func _check_is_done(id: String, source: Dictionary, notes: Dictionary) -> bool:
	if _read_bool(notes, "reentry_firefight_release_candidate_delivery_review.%s" % id):
		return true
	match id:
		"visible_ship_smoke_ready":
			return bool(source.get("visible_ship_smoke_ready", false))
		"release_files_named":
			return String(source.get("exe_path", "")).strip_edges().ends_with(".exe") and String(source.get("pck_path", "")).strip_edges().ends_with(".pck")
	return false


static func _build_issue_flags(notes: Dictionary) -> Array:
	var flags: Array = []
	for id in ISSUE_FLAG_IDS:
		flags.append({
			"id": String(id),
			"label": _issue_label(String(id)),
			"active": _read_bool(notes, "reentry_firefight_release_candidate_delivery_review.issues.%s" % String(id)),
			"recommended_task": String(ISSUE_TO_ACTION.get(id, "")),
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return flags


static func _build_source_findings(source_valid: bool, source_read_only: bool, visible_ready: bool, source: Dictionary) -> Array:
	var findings: Array = []
	if not source_valid:
		findings.append(_finding("invalid_task_804_visible_smoke", "blocker", "TASK_804-Visible-Ship-Smoke fehlt oder hat Schema/Task-Konflikt.", "TASK_804 - Station Reentry Firefight Release Candidate Visible Ship Smoke"))
	if source_valid and not source_read_only:
		findings.append(_finding("task_804_visible_smoke_not_read_only", "blocker", "TASK_804-Visible-Ship-Smoke verletzt read-only/UI-Truth-Grenzen.", "TASK_804 verifier rerun"))
	if source_valid and source_read_only and not visible_ready:
		findings.append(_finding("task_804_visible_smoke_not_ready", "blocker", "TASK_804 ist nicht sichtbar ship-smoke-ready.", String(source.get("recommended_next_task", "TASK_804 rerun"))))
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
		var next_task: String = String(flag.get("recommended_task", "TASK_805 - rerun delivery review"))
		active_ids.append(id)
		findings.append(_finding("delivery_review_issue_%s" % id, "polish", label, next_task))
		action_items.append({
			"id": id,
			"label": label,
			"recommended_task": next_task,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return active_ids


static func _build_status(source_valid: bool, source_read_only: bool, visible_ready: bool, review_done: bool, delivery_reviewed: bool, missing_check_ids: Array[String], active_issue_ids: Array[String]) -> String:
	if not source_valid or not source_read_only:
		return "blocked_until_visible_ship_smoke"
	if not visible_ready:
		return "blocked_until_visible_ship_smoke_ready"
	if not review_done or not delivery_reviewed:
		return "needs_delivery_review"
	if not missing_check_ids.is_empty():
		return "needs_delivery_review_completion"
	if not active_issue_ids.is_empty():
		return "needs_targeted_delivery_polish"
	return "ready_for_release_candidate_handoff_packet"


static func _delivery_notes(notes: Dictionary) -> Dictionary:
	var root: Dictionary = Dictionary(notes.get("reentry_firefight_release_candidate_delivery_review", {}))
	return {
		"start_instruction": String(root.get("start_instruction", "")),
		"host_client_instruction": String(root.get("host_client_instruction", "")),
		"shortcut_warning": String(root.get("shortcut_warning", "")),
		"risk_note": String(root.get("risk_note", "")),
		"handoff_note": String(root.get("handoff_note", "")),
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
		"blocked_until_visible_ship_smoke":
			return "Delivery-Review blockiert: TASK_804-Visible-Ship-Smoke fehlt oder ist ungueltig."
		"blocked_until_visible_ship_smoke_ready":
			return "Delivery-Review blockiert: sichtbarer Ship-Smoke ist noch nicht ready."
		"needs_delivery_review":
			return "Delivery-Review ist noch offen."
		"needs_delivery_review_completion":
			return "Delivery-Review braucht noch Checks: %s." % ", ".join(PackedStringArray(missing_check_ids))
		"needs_targeted_delivery_polish":
			return "Delivery-Review meldet konkrete Follow-ups: %s." % ", ".join(PackedStringArray(active_issue_ids))
		"ready_for_release_candidate_handoff_packet":
			return "Release-Candidate ist delivery-ready fuer das Handoff-Packet."
	return "Delivery-Review ist unvollstaendig."


static func _recommended_next_task(status: String, action_items: Array, source: Dictionary) -> String:
	match status:
		"blocked_until_visible_ship_smoke":
			return String(source.get("recommended_next_task", "TASK_804 - Station Reentry Firefight Release Candidate Visible Ship Smoke"))
		"blocked_until_visible_ship_smoke_ready":
			return String(source.get("recommended_next_task", "TASK_804 - run visible release ship smoke"))
		"needs_delivery_review":
			return "TASK_805 - complete release candidate delivery review"
		"needs_delivery_review_completion":
			return "TASK_805 - complete missing delivery checks"
		"needs_targeted_delivery_polish":
			if not action_items.is_empty():
				return String(Dictionary(action_items[0]).get("recommended_task", "TASK_805 - rerun delivery review"))
			return "TASK_805 - rerun delivery review"
		"ready_for_release_candidate_handoff_packet":
			return "TASK_806 - Station Reentry Firefight Release Candidate Handoff Packet"
	return "TASK_805 - repair release candidate delivery review"


static func _issue_label(id: String) -> String:
	match id:
		"stale_delivery_package":
			return "Delivery-Paket oder Verknuepfung wirkt stale"
		"release_files_missing":
			return "Release-Dateien sind nicht klar vorhanden"
		"start_instruction_unclear":
			return "Spielstart-Hinweis ist unklar"
		"host_client_instruction_unclear":
			return "Host/Client-Hinweis oder Rollen sind unklar"
		"risks_not_accepted":
			return "Bekannte Restrisiken sind nicht akzeptiert"
		"report_export_missing":
			return "Report-/Workbench-Export fehlt"
		"visible_polish_needed":
			return "Sichtbarer Polish-Bedarf vor Handoff"
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
