class_name StationReentryFirefightReleaseCandidateHandoffPacket
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_release_candidate_handoff_packet.v1"
const EXPECTED_DELIVERY_REVIEW_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_release_candidate_delivery_review.v1"
const EXPECTED_DELIVERY_REVIEW_TASK_ID: String = "TASK_805"
const DEFAULT_DELIVERY_REVIEW_MANIFEST_PATH: String = "tmp/station_reentry_firefight_release_candidate_delivery_review.json"
const DEFAULT_HANDOFF_PACKET_MANIFEST_PATH: String = "tmp/station_reentry_firefight_release_candidate_handoff_packet.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/project_current_state_handbook_reentry_2026_07_01.html"

const REQUIRED_HANDOFF_ITEMS: Array[Dictionary] = [
	{"id": "delivery_review_ready", "label": "TASK_805 Delivery-Review ist gruen"},
	{"id": "release_dir_named", "label": "Spieleordner ist benannt"},
	{"id": "release_exe_named", "label": "Release-EXE ist benannt"},
	{"id": "release_pck_named", "label": "Release-PCK ist benannt"},
	{"id": "singleplayer_start_step_written", "label": "Einzelspieler-Startschritt ist beschrieben"},
	{"id": "host_client_start_step_written", "label": "Host/Client-Startschritt ist beschrieben"},
	{"id": "role_expectations_written", "label": "Host/Client-Rollen sind beschrieben"},
	{"id": "fresh_shortcut_warning_written", "label": "Fresh-EXE-/Shortcut-Warnung ist beschrieben"},
	{"id": "smoke_gate_summary_written", "label": "Smoke-/Review-Gates sind zusammengefasst"},
	{"id": "risk_summary_written", "label": "Restrisiken sind zusammengefasst"},
	{"id": "workbench_report_named", "label": "Workbench/Report ist benannt"},
	{"id": "next_tester_action_written", "label": "Naechste Tester-Aktion ist beschrieben"},
]

const ISSUE_TO_ACTION: Dictionary = {
	"delivery_review_missing": "TASK_805 - Station Reentry Firefight Release Candidate Delivery Review",
	"stale_handoff_package": "Refresh release export, shortcut and rerun TASK_804",
	"start_steps_unclear": "TASK_806 - complete release candidate handoff packet",
	"roles_unclear": "TASK_773 - Station Reentry Host Client Identity Cue Polish",
	"report_missing": "TASK_806 - export handoff packet notes",
	"risks_unaccepted": "TASK_805 - resolve or accept delivery risks",
	"visible_polish_needed": "TASK_807 - Station Reentry Firefight Release Candidate Tester Run",
}

const ISSUE_FLAG_IDS: Array[String] = [
	"delivery_review_missing",
	"stale_handoff_package",
	"start_steps_unclear",
	"roles_unclear",
	"report_missing",
	"risks_unaccepted",
	"visible_polish_needed",
]


static func build_snapshot(delivery_review_snapshot: Dictionary = {}, handoff_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var source_valid: bool = _source_is_valid(delivery_review_snapshot)
	var source_read_only: bool = _source_is_read_only(delivery_review_snapshot)
	var delivery_ready: bool = bool(delivery_review_snapshot.get("release_candidate_delivery_ready", false))
	var handoff_items: Array = _build_handoff_items(delivery_review_snapshot, handoff_notes)
	var missing_item_ids: Array[String] = _missing_item_ids(handoff_items)
	var issue_flags: Array = _build_issue_flags(handoff_notes)
	var findings: Array = _build_source_findings(source_valid, source_read_only, delivery_ready, delivery_review_snapshot)
	var action_items: Array = []
	var active_issue_ids: Array[String] = _add_issue_findings(findings, action_items, issue_flags)
	var handoff_done: bool = _read_bool(handoff_notes, "reentry_firefight_release_candidate_handoff_packet.handoff_packet_done")
	var handoff_reviewed: bool = _read_bool(handoff_notes, "reentry_firefight_release_candidate_handoff_packet.handoff_reviewed")
	var status: String = _build_status(source_valid, source_read_only, delivery_ready, handoff_done, handoff_reviewed, missing_item_ids, active_issue_ids)
	if status == "needs_handoff_packet":
		findings.append(_finding("handoff_packet_open", "manual", "Handoff-Packet fehlt oder ist nicht bewusst abgeschlossen.", "TASK_806 - complete handoff packet"))
	elif status == "needs_handoff_packet_completion":
		findings.append(_finding("handoff_packet_items_missing", "manual", "Handoff-Packet ist angefangen, aber Items fehlen: %s" % ", ".join(PackedStringArray(missing_item_ids)), "TASK_806 - complete missing handoff items"))

	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_806",
		"source_task_id": EXPECTED_DELIVERY_REVIEW_TASK_ID,
		"source_schema": String(delivery_review_snapshot.get("schema", "")),
		"source_status": String(delivery_review_snapshot.get("status", "")),
		"source_delivery_review_manifest_path": String(options.get("delivery_review_manifest_path", DEFAULT_DELIVERY_REVIEW_MANIFEST_PATH)),
		"runtime_authority": "read-only handoff packet over TASK_805 delivery review and optional handoff notes",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"source_valid": source_valid,
		"source_read_only": source_read_only,
		"release_candidate_delivery_ready": delivery_ready,
		"handoff_packet_required": true,
		"handoff_packet_done": handoff_done,
		"handoff_reviewed": handoff_reviewed,
		"release_dir": String(delivery_review_snapshot.get("release_dir", "")),
		"exe_path": String(delivery_review_snapshot.get("exe_path", "")),
		"pck_path": String(delivery_review_snapshot.get("pck_path", "")),
		"scenario_path": String(delivery_review_snapshot.get("scenario_path", "")),
		"workbench_path": String(delivery_review_snapshot.get("workbench_path", "")),
		"workbench_file_uri": String(delivery_review_snapshot.get("workbench_file_uri", "")),
		"expected_host_role": String(delivery_review_snapshot.get("expected_host_role", "")),
		"expected_client_role": String(delivery_review_snapshot.get("expected_client_role", "")),
		"expected_decision_line": String(delivery_review_snapshot.get("expected_decision_line", "")),
		"expected_guard_line": String(delivery_review_snapshot.get("expected_guard_line", "")),
		"commands": Dictionary(delivery_review_snapshot.get("commands", {})).duplicate(true),
		"open_risks": Array(delivery_review_snapshot.get("open_risks", [])).duplicate(true),
		"operator_instruction": String(delivery_review_snapshot.get("operator_instruction", "")),
		"delivery_notes": Dictionary(delivery_review_snapshot.get("delivery_notes", {})).duplicate(true),
		"handoff_notes": _handoff_notes(handoff_notes),
		"handoff_items": handoff_items,
		"required_handoff_items": REQUIRED_HANDOFF_ITEMS.duplicate(true),
		"handoff_item_count": handoff_items.size(),
		"completed_handoff_item_count": _count_completed_items(handoff_items),
		"missing_item_ids": missing_item_ids,
		"issue_flags": issue_flags,
		"active_issue_count": active_issue_ids.size(),
		"active_issue_ids": active_issue_ids,
		"findings": findings,
		"finding_count": findings.size(),
		"action_items": action_items,
		"action_item_count": action_items.size(),
		"status": status,
		"release_candidate_handoff_ready": status == "ready_for_release_candidate_tester_run",
		"summary": _summary(status, missing_item_ids, active_issue_ids),
		"recommended_next_task": _recommended_next_task(status, action_items, delivery_review_snapshot),
		"report_path": String(options.get("report_path", DEFAULT_REPORT_PATH)),
		"manifest_path": String(options.get("manifest_path", DEFAULT_HANDOFF_PACKET_MANIFEST_PATH)),
	}


static func write_manifest(path: String = DEFAULT_HANDOFF_PACKET_MANIFEST_PATH, delivery_review_snapshot: Dictionary = {}, handoff_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var merged_options: Dictionary = options.duplicate(true)
	merged_options["manifest_path"] = path
	var snapshot: Dictionary = build_snapshot(delivery_review_snapshot, handoff_notes, merged_options)
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
			and String(source.get("schema", "")) == EXPECTED_DELIVERY_REVIEW_SCHEMA \
			and String(source.get("task_id", "")) == EXPECTED_DELIVERY_REVIEW_TASK_ID


static func _source_is_read_only(source: Dictionary) -> bool:
	return bool(source.get("read_only", false)) \
			and not bool(source.get("ui_sets_gameplay_truth", true)) \
			and not bool(source.get("creates_navigation", true)) \
			and not bool(source.get("creates_command", true)) \
			and not bool(source.get("creates_fire_event", true)) \
			and not bool(source.get("creates_damage_event", true))


static func _build_handoff_items(source: Dictionary, notes: Dictionary) -> Array:
	var items: Array = []
	for item_def_variant in REQUIRED_HANDOFF_ITEMS:
		var item_def: Dictionary = Dictionary(item_def_variant)
		var id: String = String(item_def.get("id", ""))
		items.append({
			"id": id,
			"label": String(item_def.get("label", id)),
			"complete": _item_is_done(id, source, notes),
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return items


static func _item_is_done(id: String, source: Dictionary, notes: Dictionary) -> bool:
	if _read_bool(notes, "reentry_firefight_release_candidate_handoff_packet.%s" % id):
		return true
	match id:
		"delivery_review_ready":
			return bool(source.get("release_candidate_delivery_ready", false))
		"release_dir_named":
			return String(source.get("release_dir", "")).strip_edges() != ""
		"release_exe_named":
			return String(source.get("exe_path", "")).strip_edges().ends_with(".exe")
		"release_pck_named":
			return String(source.get("pck_path", "")).strip_edges().ends_with(".pck")
		"workbench_report_named":
			return String(source.get("workbench_path", "")).strip_edges() != "" or String(source.get("workbench_file_uri", "")).strip_edges() != ""
	return false


static func _build_issue_flags(notes: Dictionary) -> Array:
	var flags: Array = []
	for id in ISSUE_FLAG_IDS:
		flags.append({
			"id": String(id),
			"label": _issue_label(String(id)),
			"active": _read_bool(notes, "reentry_firefight_release_candidate_handoff_packet.issues.%s" % String(id)),
			"recommended_task": String(ISSUE_TO_ACTION.get(id, "")),
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return flags


static func _build_source_findings(source_valid: bool, source_read_only: bool, delivery_ready: bool, source: Dictionary) -> Array:
	var findings: Array = []
	if not source_valid:
		findings.append(_finding("invalid_task_805_delivery_review", "blocker", "TASK_805-Delivery-Review fehlt oder hat Schema/Task-Konflikt.", "TASK_805 - Station Reentry Firefight Release Candidate Delivery Review"))
	if source_valid and not source_read_only:
		findings.append(_finding("task_805_delivery_review_not_read_only", "blocker", "TASK_805-Delivery-Review verletzt read-only/UI-Truth-Grenzen.", "TASK_805 verifier rerun"))
	if source_valid and source_read_only and not delivery_ready:
		findings.append(_finding("task_805_delivery_review_not_ready", "blocker", "TASK_805 ist nicht delivery-ready.", String(source.get("recommended_next_task", "TASK_805 rerun"))))
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
		var next_task: String = String(flag.get("recommended_task", "TASK_806 - rerun handoff packet"))
		active_ids.append(id)
		findings.append(_finding("handoff_packet_issue_%s" % id, "polish", label, next_task))
		action_items.append({
			"id": id,
			"label": label,
			"recommended_task": next_task,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return active_ids


static func _build_status(source_valid: bool, source_read_only: bool, delivery_ready: bool, handoff_done: bool, handoff_reviewed: bool, missing_item_ids: Array[String], active_issue_ids: Array[String]) -> String:
	if not source_valid or not source_read_only:
		return "blocked_until_delivery_review"
	if not delivery_ready:
		return "blocked_until_delivery_review_ready"
	if not handoff_done or not handoff_reviewed:
		return "needs_handoff_packet"
	if not missing_item_ids.is_empty():
		return "needs_handoff_packet_completion"
	if not active_issue_ids.is_empty():
		return "needs_targeted_handoff_polish"
	return "ready_for_release_candidate_tester_run"


static func _handoff_notes(notes: Dictionary) -> Dictionary:
	var root: Dictionary = Dictionary(notes.get("reentry_firefight_release_candidate_handoff_packet", {}))
	return {
		"singleplayer_start_step": String(root.get("singleplayer_start_step", "")),
		"host_client_start_step": String(root.get("host_client_start_step", "")),
		"role_expectations": String(root.get("role_expectations", "")),
		"shortcut_warning": String(root.get("shortcut_warning", "")),
		"smoke_gate_summary": String(root.get("smoke_gate_summary", "")),
		"risk_summary": String(root.get("risk_summary", "")),
		"next_tester_action": String(root.get("next_tester_action", "")),
	}


static func _missing_item_ids(items: Array) -> Array[String]:
	var missing: Array[String] = []
	for item_variant in items:
		if typeof(item_variant) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = Dictionary(item_variant)
		if not bool(item.get("complete", false)):
			missing.append(String(item.get("id", "")))
	return missing


static func _count_completed_items(items: Array) -> int:
	return items.size() - _missing_item_ids(items).size()


static func _summary(status: String, missing_item_ids: Array[String], active_issue_ids: Array[String]) -> String:
	match status:
		"blocked_until_delivery_review":
			return "Handoff-Packet blockiert: TASK_805-Delivery-Review fehlt oder ist ungueltig."
		"blocked_until_delivery_review_ready":
			return "Handoff-Packet blockiert: Delivery-Review ist noch nicht ready."
		"needs_handoff_packet":
			return "Handoff-Packet ist noch offen."
		"needs_handoff_packet_completion":
			return "Handoff-Packet braucht noch Items: %s." % ", ".join(PackedStringArray(missing_item_ids))
		"needs_targeted_handoff_polish":
			return "Handoff-Packet meldet konkrete Follow-ups: %s." % ", ".join(PackedStringArray(active_issue_ids))
		"ready_for_release_candidate_tester_run":
			return "Release-Candidate-Handoff ist bereit fuer den Tester-Run."
	return "Handoff-Packet ist unvollstaendig."


static func _recommended_next_task(status: String, action_items: Array, source: Dictionary) -> String:
	match status:
		"blocked_until_delivery_review":
			return String(source.get("recommended_next_task", "TASK_805 - Station Reentry Firefight Release Candidate Delivery Review"))
		"blocked_until_delivery_review_ready":
			return String(source.get("recommended_next_task", "TASK_805 - complete release candidate delivery review"))
		"needs_handoff_packet":
			return "TASK_806 - complete release candidate handoff packet"
		"needs_handoff_packet_completion":
			return "TASK_806 - complete missing handoff items"
		"needs_targeted_handoff_polish":
			if not action_items.is_empty():
				return String(Dictionary(action_items[0]).get("recommended_task", "TASK_806 - rerun handoff packet"))
			return "TASK_806 - rerun handoff packet"
		"ready_for_release_candidate_tester_run":
			return "TASK_807 - Station Reentry Firefight Release Candidate Tester Run"
	return "TASK_806 - repair release candidate handoff packet"


static func _issue_label(id: String) -> String:
	match id:
		"delivery_review_missing":
			return "Delivery-Review fehlt oder ist nicht belastbar"
		"stale_handoff_package":
			return "Handoff-Paket oder Verknuepfung wirkt stale"
		"start_steps_unclear":
			return "Startschritte sind unklar"
		"roles_unclear":
			return "Host/Client-Rollen sind unklar"
		"report_missing":
			return "Report-/Workbench-Export fehlt"
		"risks_unaccepted":
			return "Restrisiken sind nicht akzeptiert"
		"visible_polish_needed":
			return "Sichtbarer Polish-Bedarf vor Tester-Run"
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
