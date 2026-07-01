class_name StationReentryFirefightCommandSurfaceFindings
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_command_surface_findings.v1"
const EXPECTED_PACKET_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_command_surface_recapture.v1"
const EXPECTED_PACKET_TASK_ID: String = "TASK_781"
const DEFAULT_PACKET_MANIFEST_PATH: String = "tmp/station_reentry_firefight_command_surface_recapture.json"
const DEFAULT_FINDINGS_MANIFEST_PATH: String = "tmp/station_reentry_firefight_command_surface_findings.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/project_current_state_handbook_reentry_2026_07_01.html"

const REQUIRED_CHECKS: Array[Dictionary] = [
	{"id": "f6_window_open", "label": "F6-Fenster ist fuer die Command-Surface sichtbar offen"},
	{"id": "interaction_line_visible", "label": "Firefight-Folgezeile ist im HUD sichtbar"},
	{"id": "primary_action_visible", "label": "Primaerer Folgegriff ist sichtbar"},
	{"id": "quick_actions_visible", "label": "Quick-Actions sind sichtbar"},
	{"id": "hold_flank_sup_visible", "label": "HOLD, FLANK und SUP sind auffindbar"},
	{"id": "hold_fire_visible_when_ff_risk", "label": "HOLD FIRE ist bei Friendly-Fire-Risiko auffindbar"},
	{"id": "no_auto_command_commit_visible", "label": "No-Auto-Command-Grenze ist erkennbar"},
	{"id": "selected_fireteam_panel_consistent", "label": "Selected-Fireteam-Panel bleibt zum ausgewaehlten Fireteam konsistent"},
	{"id": "command_matrix_buttons_reachable", "label": "Command-Matrix-Buttons sind erreichbar"},
	{"id": "host_client_same_surface_visible", "label": "Host und Client sehen dieselbe Command-Surface"},
	{"id": "screenshot_saved", "label": "Screenshot/Evidence wurde gespeichert"},
	{"id": "workbench_json_exported", "label": "Workbench-JSON wurde exportiert"},
]

const ISSUE_TO_ACTION: Dictionary = {
	"interaction_line_missing": "TASK_780 - Station Reentry Firefight Interaction Polish",
	"primary_action_unclear": "TASK_780 - Station Reentry Firefight Interaction Polish",
	"quick_actions_hidden": "TASK_780 - Station Reentry Firefight Interaction Polish",
	"hold_fire_missing": "TASK_570 - Hold-Fire-Discipline-Mission-Bridge",
	"auto_command_commit_confusing": "TASK_501 - Integrated Movement Command Lifecycle Hardening",
	"selected_fireteam_panel_mismatch": "TASK_547 - Multi-Fireteam Combat HUD Consistency Smoke",
	"command_matrix_unreachable": "TASK_736 - Station Scenario Command Feedback Polish",
	"host_client_surface_mismatch": "TASK_770 - Station Reentry Host Client Next Order Sync",
	"surface_too_dense": "TASK_780 - Station Reentry Firefight Interaction Polish",
	"performance_stutter_visible": "TASK_769 - Station Reentry Performance Feel Pass",
}

const ISSUE_FLAG_IDS: Array[String] = [
	"interaction_line_missing",
	"primary_action_unclear",
	"quick_actions_hidden",
	"hold_fire_missing",
	"auto_command_commit_confusing",
	"selected_fireteam_panel_mismatch",
	"command_matrix_unreachable",
	"host_client_surface_mismatch",
	"surface_too_dense",
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
	var manual_done: bool = _read_bool(review_notes, "reentry_firefight_command_surface_findings.manual_review_done")
	var visible_recapture_done: bool = _read_bool(review_notes, "reentry_firefight_command_surface_findings.visible_recapture_done")
	var status: String = _build_status(blocker_count, manual_done, visible_recapture_done, missing_check_ids, active_issue_count)
	if status == "needs_visible_command_surface_review":
		findings.append(_finding("visible_command_surface_review_open", "manual", "Sichtbarer Command-Surface-Fensterblick fehlt oder ist noch nicht bewusst abgeschlossen.", "TASK_781 - run visible Firefight Command Surface Recapture"))
	elif status == "needs_command_surface_review_completion":
		findings.append(_finding("command_surface_checks_missing", "manual", "Command-Surface-Review ist angefangen, aber Pflichtchecks fehlen: %s" % ", ".join(PackedStringArray(missing_check_ids)), "TASK_781 - complete missing visible Command-Surface checks"))
	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_782",
		"source_task_id": EXPECTED_PACKET_TASK_ID,
		"runtime_authority": "read-only findings over TASK_781 command surface recapture packet and optional report notes",
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
		"target_id": String(packet_manifest.get("target_id", "station_reentry_firefight_command_surface_recapture")),
		"expected_interaction_line": String(packet_manifest.get("expected_interaction_line", "")),
		"expected_primary_action_label": String(packet_manifest.get("expected_primary_action_label", "")),
		"expected_quick_action_labels": Array(packet_manifest.get("expected_quick_action_labels", [])).duplicate(true),
		"expected_no_auto_command_commit": bool(packet_manifest.get("expected_no_auto_command_commit", false)),
		"expected_uses_existing_commands_only": bool(packet_manifest.get("expected_uses_existing_commands_only", false)),
		"manual_review_required": true,
		"manual_review_done": manual_done,
		"visible_recapture_done": visible_recapture_done,
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
		findings.append(_finding("missing_task_781_packet", "blocker", "TASK_781-Command-Surface-Recapture-Paket fehlt.", "TASK_781 - rerun Station Reentry Firefight Command Surface Recapture"))
		return
	if String(packet_manifest.get("schema", "")) != EXPECTED_PACKET_SCHEMA:
		findings.append(_finding("unexpected_task_781_packet_schema", "blocker", "TASK_781-Paket hat ein unerwartetes Schema.", "TASK_781 verifier rerun"))
	if String(packet_manifest.get("task_id", "")) != EXPECTED_PACKET_TASK_ID:
		findings.append(_finding("unexpected_task_781_packet_task", "blocker", "Paket gehoert nicht zu TASK_781.", "TASK_781 verifier rerun"))
	if String(packet_manifest.get("status", "")) != "ready_to_capture_firefight_command_surface":
		findings.append(_finding("task_781_packet_not_ready", "blocker", "TASK_781-Paket ist nicht capture-bereit.", "TASK_781 repair or rerun"))
	if not bool(packet_manifest.get("read_only", false)) \
			or bool(packet_manifest.get("ui_sets_gameplay_truth", true)) \
			or bool(packet_manifest.get("creates_command", true)) \
			or bool(packet_manifest.get("creates_fire_event", true)) \
			or bool(packet_manifest.get("creates_damage_event", true)):
		findings.append(_finding("task_781_packet_not_readonly", "blocker", "TASK_781-Paket verletzt read-only/UI-Truth-Regeln.", "TASK_781 verifier rerun"))
	if not bool(packet_manifest.get("expected_no_auto_command_commit", false)):
		findings.append(_finding("task_781_missing_no_auto_commit_expectation", "blocker", "TASK_781-Paket traegt keine No-Auto-Command-Erwartung.", "TASK_781 verifier rerun"))
	if not bool(packet_manifest.get("expected_uses_existing_commands_only", false)):
		findings.append(_finding("task_781_missing_existing_command_expectation", "blocker", "TASK_781-Paket traegt keine Existing-Commands-only-Erwartung.", "TASK_781 verifier rerun"))


static func _build_required_checks(review_notes: Dictionary) -> Array:
	var checks: Array = []
	for check_def in REQUIRED_CHECKS:
		var id: String = String(check_def.get("id", ""))
		checks.append({
			"id": id,
			"label": String(check_def.get("label", id)),
			"checked": _read_bool(review_notes, "reentry_firefight_command_surface_findings.%s" % id) \
					or _read_bool(review_notes, "reentry_firefight_command_surface.%s" % id),
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
			"active": _read_bool(review_notes, "reentry_firefight_command_surface_findings.issues.%s" % String(id)),
			"recommended_task": String(ISSUE_TO_ACTION.get(id, "")),
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return flags


static func _issue_label(id: String) -> String:
	match id:
		"interaction_line_missing":
			return "Firefight-Folgezeile fehlt oder ist nicht am erwarteten Ort sichtbar"
		"primary_action_unclear":
			return "Primaerer Folgegriff ist unklar oder nicht hervorgehoben"
		"quick_actions_hidden":
			return "Quick-Actions sind versteckt oder zu schwer auffindbar"
		"hold_fire_missing":
			return "HOLD FIRE ist bei Friendly-Fire-Risiko nicht auffindbar"
		"auto_command_commit_confusing":
			return "Anzeige wirkt so, als wuerde sie automatisch Befehle ausfuehren"
		"selected_fireteam_panel_mismatch":
			return "Selected-Fireteam-Panel widerspricht Auswahl oder Dropship-/Fireteam-Kontext"
		"command_matrix_unreachable":
			return "Command-Matrix-Buttons sind im Feuerwechsel nicht erreichbar"
		"host_client_surface_mismatch":
			return "Host und Client sehen unterschiedliche Command-Surface-Informationen"
		"surface_too_dense":
			return "Command-Surface ist zu dicht, der naechste Griff geht unter"
		"performance_stutter_visible":
			return "Command-Surface-Recapture wirkt zaeh oder stottert"
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
		var next_task: String = String(flag.get("recommended_task", "TASK_780 - Station Reentry Firefight Interaction Polish"))
		findings.append(_finding("command_surface_issue_%s" % id, "polish", label, next_task))
		action_items.append({
			"id": id,
			"label": label,
			"recommended_task": next_task,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return count


static func _build_status(blocker_count: int, manual_done: bool, visible_recapture_done: bool, missing_check_ids: Array, active_issue_count: int) -> String:
	if blocker_count > 0:
		return "blocked"
	if not manual_done or not visible_recapture_done:
		return "needs_visible_command_surface_review"
	if not missing_check_ids.is_empty():
		return "needs_command_surface_review_completion"
	if active_issue_count > 0:
		return "needs_targeted_command_surface_polish"
	return "ready_for_next_station_firefight_iteration"


static func _build_summary(status: String, completed_check_count: int, required_check_count: int, active_issue_count: int) -> String:
	if status == "blocked":
		return "TASK_782 blockiert: TASK_781-Command-Surface-Recapture-Paket fehlt oder ist ungueltig."
	if status == "needs_visible_command_surface_review":
		return "Sichtbarer Command-Surface-Review offen, %d/%d Checks gesetzt." % [completed_check_count, required_check_count]
	if status == "needs_command_surface_review_completion":
		return "Command-Surface-Review unvollstaendig, %d/%d Checks gesetzt." % [completed_check_count, required_check_count]
	if status == "needs_targeted_command_surface_polish":
		return "%d konkrete Command-Surface-Follow-up-Flag(s)." % active_issue_count
	return "Command-Surface-Review ist sauber genug fuer die naechste Station-Firefight-Iteration."


static func _recommended_next_task(status: String, action_items: Array) -> String:
	if status == "blocked":
		return "TASK_781 - rerun Station Reentry Firefight Command Surface Recapture"
	if status == "needs_visible_command_surface_review":
		return "TASK_781 - run visible Firefight Command Surface Recapture"
	if status == "needs_command_surface_review_completion":
		return "TASK_781 - complete missing visible Command-Surface checks"
	if status == "needs_targeted_command_surface_polish":
		if not action_items.is_empty() and typeof(action_items[0]) == TYPE_DICTIONARY:
			return String(Dictionary(action_items[0]).get("recommended_task", "TASK_780 - Station Reentry Firefight Interaction Polish"))
		return "TASK_780 - Station Reentry Firefight Interaction Polish"
	return "TASK_783 - Station Reentry Firefight Command Surface Polish"


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
