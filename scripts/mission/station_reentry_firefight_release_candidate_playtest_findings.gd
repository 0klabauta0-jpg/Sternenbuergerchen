class_name StationReentryFirefightReleaseCandidatePlaytestFindings
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_release_candidate_playtest_findings.v1"
const EXPECTED_PACKET_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_multiplayer_release_candidate_packet.v1"
const EXPECTED_PACKET_TASK_ID: String = "TASK_800"
const DEFAULT_PACKET_MANIFEST_PATH: String = "tmp/station_reentry_firefight_multiplayer_release_candidate_packet.json"
const DEFAULT_FINDINGS_MANIFEST_PATH: String = "tmp/station_reentry_firefight_release_candidate_playtest_findings.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/project_current_state_handbook_reentry_2026_07_01.html"

const FALLBACK_REQUIRED_CHECKS: Array[Dictionary] = [
	{"id": "singleplayer_homebase_not_blocked", "label": "Einzelspieler startet handlungsfaehig"},
	{"id": "host_client_windows_open", "label": "Host und Client laufen sichtbar"},
	{"id": "fireteams_visible_and_distinct", "label": "Fireteams bleiben unterscheidbar"},
	{"id": "dropship_payload_not_mixed", "label": "Dropship-Payload mischt nichts"},
	{"id": "mission_insertion_visible", "label": "Mission-Insertion ist sichtbar"},
	{"id": "move_preview_before_go", "label": "Preview ist vor GO lesbar"},
	{"id": "decision_card_actionable", "label": "Decision-Card ist handlungsfaehig"},
	{"id": "first_firefight_response_fast", "label": "Erster Feuerwechsel ist schnell genug"},
	{"id": "exit_or_debrief_path_visible", "label": "Exit/Debrief ist sichtbar"},
	{"id": "no_hud_overlap_blocker", "label": "HUD blockiert keine Aktion"},
	{"id": "runtime_export_is_fresh", "label": "Frischer Runtime-Export wird getestet"},
]

const ISSUE_TO_ACTION: Dictionary = {
	"singleplayer_homebase_blocked": "BUGFIX - Singleplayer Release Homebase Start Bootstrap follow-up",
	"fireteam_list_confusing": "TASK_773 - Station Reentry Host Client Identity Cue Polish",
	"dropship_payload_mixed": "TASK_765 - Station Reentry Dropship Boarding Bridge Polish",
	"mission_insertion_unclear": "TASK_775 - Station Reentry Mission Interaction Feel Pass",
	"preview_missing_or_unclear": "TASK_768 - Station Reentry First Mission Preview Polish",
	"decision_not_actionable": "TASK_787 - Station Reentry Firefight Player Decision Readability Pass",
	"firefight_response_stutter": "TASK_769 - Station Reentry Performance Feel Pass",
	"hud_overlap_blocks_action": "TASK_733 - Station Scenario HUD Overlap Pass",
	"exit_or_debrief_missing": "TASK_743 - Station Scenario Debrief Handoff Cue",
	"host_client_desync_visible": "TASK_770 - Station Reentry Host Client Next Order Sync",
	"stale_runtime_export_used": "TASK_800 - rerun Release Candidate Packet after fresh export",
}

const ISSUE_FLAG_IDS: Array[String] = [
	"singleplayer_homebase_blocked",
	"fireteam_list_confusing",
	"dropship_payload_mixed",
	"mission_insertion_unclear",
	"preview_missing_or_unclear",
	"decision_not_actionable",
	"firefight_response_stutter",
	"hud_overlap_blocks_action",
	"exit_or_debrief_missing",
	"host_client_desync_visible",
	"stale_runtime_export_used",
]


static func build_snapshot(packet_snapshot: Dictionary = {}, playtest_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var findings: Array = []
	var action_items: Array = []
	_add_packet_findings(findings, packet_snapshot)
	var required_checks: Array = _build_required_checks(packet_snapshot, playtest_notes)
	var issue_flags: Array = _build_issue_flags(playtest_notes)
	var completed_check_count: int = _count_completed_checks(required_checks)
	var missing_check_ids: Array[String] = _missing_check_ids(required_checks)
	var active_issue_count: int = _add_issue_flag_findings(findings, action_items, issue_flags)
	var blocker_count: int = _count_findings_by_severity(findings, "blocker")
	var manual_done: bool = _read_bool(playtest_notes, "reentry_firefight_release_candidate_findings.manual_review_done")
	var visible_playtest_done: bool = _read_bool(playtest_notes, "reentry_firefight_release_candidate_findings.visible_playtest_done")
	var release_exe_started: bool = _read_bool(playtest_notes, "reentry_firefight_release_candidate_findings.release_exe_started")
	var host_client_started: bool = _read_bool(playtest_notes, "reentry_firefight_release_candidate_findings.host_client_started")
	var status: String = _build_status(blocker_count, manual_done, visible_playtest_done, release_exe_started, host_client_started, missing_check_ids, active_issue_count)
	if status == "needs_visible_release_candidate_playtest":
		findings.append(_finding("visible_release_candidate_playtest_open", "manual", "Sichtbarer Release-Candidate-Playtest fehlt oder ist nicht bewusst abgeschlossen.", "TASK_800 - run Station Reentry Firefight Multiplayer Release Candidate Packet"))
	elif status == "needs_release_candidate_playtest_completion":
		findings.append(_finding("release_candidate_checks_missing", "manual", "Release-Candidate-Playtest ist angefangen, aber Pflichtchecks fehlen: %s" % ", ".join(PackedStringArray(missing_check_ids)), "TASK_800 - complete missing release candidate playtest checks"))
	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_801",
		"source_task_id": EXPECTED_PACKET_TASK_ID,
		"source_schema": String(packet_snapshot.get("schema", "")),
		"source_status": String(packet_snapshot.get("status", "")),
		"source_packet_manifest_path": String(options.get("packet_manifest_path", DEFAULT_PACKET_MANIFEST_PATH)),
		"runtime_authority": "read-only findings over TASK_800 release candidate packet and optional playtest notes",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"packet_ready": bool(packet_snapshot.get("release_candidate_packet_ready", false)),
		"release_dir": String(packet_snapshot.get("release_dir", "")),
		"exe_path": String(packet_snapshot.get("exe_path", "")),
		"pck_path": String(packet_snapshot.get("pck_path", "")),
		"scenario_path": String(packet_snapshot.get("scenario_path", "")),
		"workbench_path": String(packet_snapshot.get("workbench_path", "")),
		"workbench_file_uri": String(packet_snapshot.get("workbench_file_uri", "")),
		"expected_host_role": String(packet_snapshot.get("expected_host_role", "")),
		"expected_client_role": String(packet_snapshot.get("expected_client_role", "")),
		"expected_decision_line": String(packet_snapshot.get("expected_decision_line", "")),
		"expected_guard_line": String(packet_snapshot.get("expected_guard_line", "")),
		"commands": Dictionary(packet_snapshot.get("commands", {})).duplicate(true),
		"manual_review_required": true,
		"manual_review_done": manual_done,
		"visible_playtest_done": visible_playtest_done,
		"release_exe_started": release_exe_started,
		"host_client_started": host_client_started,
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


static func _add_packet_findings(findings: Array, packet: Dictionary) -> void:
	if packet.is_empty():
		findings.append(_finding("missing_task_800_packet", "blocker", "TASK_800-Release-Candidate-Paket fehlt.", "TASK_800 - Station Reentry Firefight Multiplayer Release Candidate Packet"))
		return
	if String(packet.get("schema", "")) != EXPECTED_PACKET_SCHEMA:
		findings.append(_finding("unexpected_task_800_packet_schema", "blocker", "TASK_800-Paket hat ein unerwartetes Schema.", "TASK_800 verifier rerun"))
	if String(packet.get("task_id", "")) != EXPECTED_PACKET_TASK_ID:
		findings.append(_finding("unexpected_task_800_packet_task", "blocker", "Paket gehoert nicht zu TASK_800.", "TASK_800 verifier rerun"))
	if String(packet.get("status", "")) != "ready_for_release_candidate_playtest" or not bool(packet.get("release_candidate_packet_ready", false)):
		findings.append(_finding("task_800_packet_not_ready", "blocker", "TASK_800-Paket ist nicht bereit fuer den Release-Candidate-Playtest.", "TASK_800 rerun or repair"))
	if not bool(packet.get("read_only", false)) \
			or bool(packet.get("ui_sets_gameplay_truth", true)) \
			or bool(packet.get("creates_command", true)) \
			or bool(packet.get("creates_navigation", true)) \
			or bool(packet.get("creates_fire_event", true)) \
			or bool(packet.get("creates_damage_event", true)):
		findings.append(_finding("task_800_packet_not_readonly", "blocker", "TASK_800-Paket verletzt read-only/UI-Truth-Grenzen.", "TASK_800 verifier rerun"))
	if Array(packet.get("release_playtest_checks", [])).is_empty():
		findings.append(_finding("task_800_packet_missing_checks", "blocker", "TASK_800-Paket enthaelt keine Release-Playtest-Checks.", "TASK_800 repair"))


static func _build_required_checks(packet: Dictionary, notes: Dictionary) -> Array:
	var source_checks: Array = Array(packet.get("release_playtest_checks", FALLBACK_REQUIRED_CHECKS))
	if source_checks.is_empty():
		source_checks = FALLBACK_REQUIRED_CHECKS
	var checks: Array = []
	for check_def_variant in source_checks:
		if typeof(check_def_variant) != TYPE_DICTIONARY:
			continue
		var check_def: Dictionary = Dictionary(check_def_variant)
		var id: String = String(check_def.get("id", ""))
		if id.strip_edges() == "":
			continue
		checks.append({
			"id": id,
			"label": String(check_def.get("label", id)),
			"checked": _read_bool(notes, "reentry_firefight_release_candidate_findings.%s" % id),
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
			"active": _read_bool(notes, "reentry_firefight_release_candidate_findings.issues.%s" % String(id)),
			"recommended_task": String(ISSUE_TO_ACTION.get(id, "")),
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return flags


static func _issue_label(id: String) -> String:
	match id:
		"singleplayer_homebase_blocked":
			return "Einzelspieler/Homebase ist im Release noch blockiert"
		"fireteam_list_confusing":
			return "Fireteam-Liste ist im Release unklar oder widerspruechlich"
		"dropship_payload_mixed":
			return "Dropship-Payload mischt Fireteams oder Peers"
		"mission_insertion_unclear":
			return "Mission-Insertion/Ausstieg ist unklar"
		"preview_missing_or_unclear":
			return "Move-/Decision-Preview fehlt oder ist unklar"
		"decision_not_actionable":
			return "Decision-Card fuehlt sich nicht handlungsfaehig an"
		"firefight_response_stutter":
			return "Erster Feuerwechsel stottert oder fuehlt sich zaeh an"
		"hud_overlap_blocks_action":
			return "HUD verdeckt eine zwingende Aktion"
		"exit_or_debrief_missing":
			return "Exit/Debrief- oder naechster Griff fehlt"
		"host_client_desync_visible":
			return "Host/Client wirken sichtbar desynchron"
		"stale_runtime_export_used":
			return "Es wurde nicht der frische Runtime-Export getestet"
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
		var next_task: String = String(flag.get("recommended_task", "TASK_801 - Station Reentry Firefight Release Candidate Playtest Findings"))
		findings.append(_finding("release_candidate_issue_%s" % id, "polish", label, next_task))
		action_items.append({
			"id": id,
			"label": label,
			"recommended_task": next_task,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return count


static func _build_status(blocker_count: int, manual_done: bool, visible_done: bool, exe_started: bool, host_client_started: bool, missing_check_ids: Array, active_issue_count: int) -> String:
	if blocker_count > 0:
		return "blocked"
	if not manual_done or not visible_done or not exe_started or not host_client_started:
		return "needs_visible_release_candidate_playtest"
	if not missing_check_ids.is_empty():
		return "needs_release_candidate_playtest_completion"
	if active_issue_count > 0:
		return "needs_targeted_release_candidate_polish"
	return "ready_for_release_candidate_acceptance"


static func _build_summary(status: String, completed_count: int, required_count: int, active_issue_count: int) -> String:
	match status:
		"blocked":
			return "TASK_801 blockiert: TASK_800-Release-Candidate-Paket fehlt oder ist ungueltig."
		"needs_visible_release_candidate_playtest":
			return "Sichtbarer Release-Candidate-Playtest offen, %d/%d Checks gesetzt." % [completed_count, required_count]
		"needs_release_candidate_playtest_completion":
			return "Release-Candidate-Playtest unvollstaendig, %d/%d Checks gesetzt." % [completed_count, required_count]
		"needs_targeted_release_candidate_polish":
			return "%d konkrete Release-Candidate-Follow-up-Flag(s)." % active_issue_count
	return "Release-Candidate-Findings sind sauber genug fuer Acceptance."


static func _recommended_next_task(status: String, action_items: Array) -> String:
	if status == "blocked":
		return "TASK_800 - Station Reentry Firefight Multiplayer Release Candidate Packet"
	if status == "needs_visible_release_candidate_playtest":
		return "TASK_800 - run Station Reentry Firefight Multiplayer Release Candidate Packet"
	if status == "needs_release_candidate_playtest_completion":
		return "TASK_800 - complete missing release candidate playtest checks"
	if status == "needs_targeted_release_candidate_polish":
		if not action_items.is_empty() and typeof(action_items[0]) == TYPE_DICTIONARY:
			return String(Dictionary(action_items[0]).get("recommended_task", "TASK_801 - Station Reentry Firefight Release Candidate Playtest Findings"))
		return "TASK_801 - Station Reentry Firefight Release Candidate Playtest Findings"
	return "TASK_802 - Station Reentry Firefight Release Candidate Acceptance"


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
