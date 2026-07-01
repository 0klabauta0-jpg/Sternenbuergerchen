class_name StationReentryPlaytestFindings
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_visible_playtest_findings.v1"
const EXPECTED_PACKET_SCHEMA: String = "sternenbuergerchen.station_reentry_playtest_run_packet.v1"
const EXPECTED_PACKET_TASK_ID: String = "TASK_760"
const DEFAULT_PACKET_PATH: String = "tmp/station_reentry_playtest_run_packet.json"
const DEFAULT_MANIFEST_PATH: String = "tmp/station_reentry_visible_playtest_findings.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html"

const REQUIRED_CHECKS: Array[Dictionary] = [
	{"id": "homebase_return_panel_readable", "label": "Homebase-Return-Panel ist im Reentry-Kontext lesbar"},
	{"id": "fireteam_staging_readable", "label": "Fireteam bereitstellen ist ohne Raten verstaendlich"},
	{"id": "loadout_check_readable", "label": "Loadout-Pruefung ist sichtbar und wirkt verbindlich"},
	{"id": "dropship_payload_consistent", "label": "Fireteam bleibt im Dropship konsistent sichtbar"},
	{"id": "start_release_visible", "label": "Startfreigabe ist klar und nicht versteckt"},
	{"id": "host_client_same_next_order", "label": "Host und Client sehen denselben naechsten Auftrag"},
	{"id": "first_mission_preview_visible", "label": "Erste Missionsentscheidung zeigt Preview/Gefahr vor GO"},
	{"id": "first_mission_cue_readable", "label": "Erste Missions-Cue ist fuer beide Fenster lesbar"},
	{"id": "performance_feels_fast", "label": "Reentry fuehlt sich schnell genug an"},
	{"id": "workbench_notes_exported", "label": "Workbench-Notizen wurden exportiert"},
]

const ISSUE_TO_ACTION: Dictionary = {
	"needs_homebase_reentry_copy_polish": "TASK_762 - Station Reentry Homebase Copy Polish",
	"needs_fireteam_staging_polish": "TASK_763 - Station Reentry Fireteam Staging Polish",
	"needs_loadout_bridge_polish": "TASK_764 - Station Reentry Loadout Bridge Polish",
	"needs_dropship_payload_sync_fix": "TASK_765 - Station Reentry Dropship Payload Sync Fix",
	"needs_first_order_preview_polish": "TASK_766 - Station Reentry First Order Preview Polish",
	"needs_reentry_performance_pass": "TASK_767 - Station Reentry Performance Feel Pass",
	"needs_host_client_next_order_sync": "TASK_768 - Station Reentry Host Client Next Order Sync",
}

const ISSUE_FLAG_IDS: Array[String] = [
	"needs_homebase_reentry_copy_polish",
	"needs_fireteam_staging_polish",
	"needs_loadout_bridge_polish",
	"needs_dropship_payload_sync_fix",
	"needs_first_order_preview_polish",
	"needs_reentry_performance_pass",
	"needs_host_client_next_order_sync",
]


static func build_snapshot(packet: Dictionary = {}, existing_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var findings: Array = []
	var action_items: Array = []
	_add_packet_findings(findings, packet)
	var required_checks: Array = _build_required_checks(existing_notes)
	var issue_flags: Array = _build_issue_flags(existing_notes)
	var completed_check_count: int = _count_completed_checks(required_checks)
	var missing_check_ids: Array[String] = _missing_check_ids(required_checks)
	var active_issue_count: int = _add_issue_flag_findings(findings, action_items, issue_flags)
	var blocker_count: int = _count_findings_by_severity(findings, "blocker")
	var manual_done: bool = _read_bool(existing_notes, "station_scenario_playtest.reentry.manual_review_done")
	var playtest_done: bool = _read_bool(existing_notes, "station_scenario_playtest.reentry.playtest_done")
	var status: String = _build_status(blocker_count, manual_done, playtest_done, missing_check_ids, active_issue_count)
	if status == "needs_visible_reentry_playtest":
		findings.append(_finding("visible_reentry_playtest_open", "manual", "Station-Reentry wurde noch nicht sichtbar als eigener Lauf bewertet.", "TASK_761 - run Station Reentry visible playtest"))
	elif status == "needs_reentry_completion":
		findings.append(_finding("reentry_required_checks_missing", "manual", "Reentry-Review ist angefangen, aber Pflichtchecks fehlen: %s" % ", ".join(PackedStringArray(missing_check_ids)), "TASK_761 - complete missing Reentry checks"))
	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_761",
		"source_task_id": EXPECTED_PACKET_TASK_ID,
		"runtime_authority": "read-only findings over TASK_760 reentry run packet and optional workbench notes",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"source_packet_schema": String(packet.get("schema", "")),
		"source_packet_task_id": String(packet.get("task_id", "")),
		"source_packet_status": String(packet.get("status", "")),
		"source_packet_path": String(options.get("packet_path", DEFAULT_PACKET_PATH)),
		"target_id": String(packet.get("target_id", "station_reentry_playtest")),
		"target_title": String(packet.get("target_title", "Homebase -> naechste Station-Sortie")),
		"manual_review_required": true,
		"manual_review_done": manual_done,
		"playtest_done": playtest_done,
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
		"manifest_path": String(options.get("manifest_path", DEFAULT_MANIFEST_PATH)),
	}


static func _add_packet_findings(findings: Array, packet: Dictionary) -> void:
	if packet.is_empty():
		findings.append(_finding("missing_reentry_run_packet", "blocker", "TASK_760-Reentry-Run-Packet fehlt.", "TASK_760 - rerun Station Reentry Playtest Run Packet"))
		return
	if String(packet.get("schema", "")) != EXPECTED_PACKET_SCHEMA:
		findings.append(_finding("unexpected_reentry_packet_schema", "blocker", "Reentry-Run-Packet hat ein unerwartetes Schema.", "TASK_760 verifier rerun"))
	if String(packet.get("task_id", "")) != EXPECTED_PACKET_TASK_ID:
		findings.append(_finding("unexpected_reentry_packet_task", "blocker", "Reentry-Run-Packet gehoert nicht zu TASK_760.", "TASK_760 verifier rerun"))
	if String(packet.get("status", "")) != "ready_to_run_station_reentry_playtest":
		findings.append(_finding("reentry_packet_not_ready", "blocker", "Reentry-Run-Packet ist nicht startbereit.", "TASK_760 repair"))
	if String(packet.get("target_id", "")) != "station_reentry_playtest":
		findings.append(_finding("unexpected_reentry_target", "blocker", "Reentry-Run-Packet zeigt auf ein anderes Ziel.", "TASK_760 repair"))
	if not bool(packet.get("read_only", false)) or bool(packet.get("ui_sets_gameplay_truth", true)) or bool(packet.get("creates_command", true)):
		findings.append(_finding("reentry_packet_not_readonly", "blocker", "Reentry-Run-Packet verletzt read-only/UI-Truth-Regeln.", "TASK_760 verifier rerun"))


static func _build_required_checks(existing_notes: Dictionary) -> Array:
	var checks: Array = []
	for check_def in REQUIRED_CHECKS:
		var id: String = String(check_def.get("id", ""))
		checks.append({
			"id": id,
			"label": String(check_def.get("label", id)),
			"checked": _read_bool(existing_notes, "station_scenario_playtest.reentry.%s" % id),
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return checks


static func _build_issue_flags(existing_notes: Dictionary) -> Array:
	var flags: Array = []
	for id in ISSUE_FLAG_IDS:
		flags.append({
			"id": String(id),
			"label": _issue_label(String(id)),
			"active": _read_bool(existing_notes, "station_scenario_playtest.reentry.issues.%s" % String(id)),
			"recommended_task": String(ISSUE_TO_ACTION.get(id, "")),
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return flags


static func _issue_label(id: String) -> String:
	match id:
		"needs_homebase_reentry_copy_polish":
			return "Homebase-Reentry-Text braucht Polish"
		"needs_fireteam_staging_polish":
			return "Fireteam-Staging ist noch nicht angenehm lesbar"
		"needs_loadout_bridge_polish":
			return "Loadout-Bruecke wirkt unklar"
		"needs_dropship_payload_sync_fix":
			return "Dropship/Fireteam-Anzeige oder Sync wirkt inkonsistent"
		"needs_first_order_preview_polish":
			return "Erste Move-/Preview-Entscheidung ist noch nicht klar genug"
		"needs_reentry_performance_pass":
			return "Reentry fuehlt sich nicht schnell genug an"
		"needs_host_client_next_order_sync":
			return "Host/Client sehen den naechsten Auftrag nicht eindeutig gleich"
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
		var next_task: String = String(flag.get("recommended_task", ISSUE_TO_ACTION.get(id, "TASK_762 - Station Reentry Targeted Polish")))
		findings.append(_finding("reentry_issue_%s" % id, "polish", label, next_task))
		action_items.append({
			"id": id,
			"label": label,
			"recommended_task": next_task,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return count


static func _build_status(blocker_count: int, manual_done: bool, playtest_done: bool, missing_check_ids: Array, active_issue_count: int) -> String:
	if blocker_count > 0:
		return "blocked"
	if not manual_done or not playtest_done:
		return "needs_visible_reentry_playtest"
	if not missing_check_ids.is_empty():
		return "needs_reentry_completion"
	if active_issue_count > 0:
		return "needs_targeted_reentry_polish"
	return "ready_for_next_station_iteration"


static func _build_summary(status: String, completed_check_count: int, required_check_count: int, active_issue_count: int) -> String:
	if status == "blocked":
		return "TASK_761 blockiert: Reentry-Run-Packet fehlt oder ist ungueltig"
	if status == "needs_visible_reentry_playtest":
		return "Sichtbarer Station-Reentry-Playtest offen, %d/%d Checks gesetzt" % [completed_check_count, required_check_count]
	if status == "needs_reentry_completion":
		return "Station-Reentry-Review unvollstaendig, %d/%d Checks gesetzt" % [completed_check_count, required_check_count]
	if status == "needs_targeted_reentry_polish":
		return "%d konkrete Reentry-Follow-up-Flag(s)" % active_issue_count
	return "Station-Reentry-Review ist sauber genug fuer die naechste spielbare Iteration"


static func _recommended_next_task(status: String, action_items: Array) -> String:
	if status == "blocked":
		return "TASK_760 - rerun Station Reentry Playtest Run Packet"
	if status == "needs_visible_reentry_playtest":
		return "TASK_761 - run Station Reentry visible playtest"
	if status == "needs_reentry_completion":
		return "TASK_761 - complete missing Reentry checks"
	if status == "needs_targeted_reentry_polish":
		if not action_items.is_empty() and typeof(action_items[0]) == TYPE_DICTIONARY:
			return String(Dictionary(action_items[0]).get("recommended_task", "TASK_762 - Station Reentry Targeted Polish"))
		return "TASK_762 - Station Reentry Targeted Polish"
	return "TASK_762 - Station Reentry Next Playable Iteration"


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


static func _read_bool(notes: Dictionary, dotted_key: String) -> bool:
	var direct_value: Variant = _get_path(notes, dotted_key)
	if typeof(direct_value) == TYPE_BOOL:
		return bool(direct_value)
	var controls: Dictionary = Dictionary(notes.get("controls", {}))
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
