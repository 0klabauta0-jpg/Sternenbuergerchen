class_name StationReentryFirefightMultiplayerPlayableCandidateRealRunFindings
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_multiplayer_playable_candidate_real_run_findings.v1"
const EXPECTED_CANDIDATE_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_multiplayer_playable_slice_candidate.v1"
const EXPECTED_CANDIDATE_TASK_ID: String = "TASK_797"
const DEFAULT_CANDIDATE_MANIFEST_PATH: String = "tmp/station_reentry_firefight_multiplayer_playable_slice_candidate.json"
const DEFAULT_FINDINGS_MANIFEST_PATH: String = "tmp/station_reentry_firefight_multiplayer_playable_candidate_real_run_findings.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const DEFAULT_REAL_RUN_MANIFEST_PATH: String = "tmp/host_client_two_window_real_run_review.json"
const DEFAULT_HOST_SCREENSHOT_PATH: String = "tmp/host_client_two_window_host_review.png"
const DEFAULT_CLIENT_SCREENSHOT_PATH: String = "tmp/host_client_two_window_client_review.png"

const REQUIRED_CHECKS: Array[Dictionary] = [
	{"id": "singleplayer_homebase_not_blocked", "label": "Einzelspieler/Homebase startet nicht blockiert"},
	{"id": "host_client_windows_open", "label": "Host und Client laufen sichtbar nebeneinander"},
	{"id": "fireteams_visible_and_distinct", "label": "Fireteams bleiben sichtbar und unterscheidbar"},
	{"id": "dropship_payload_not_mixed", "label": "Dropship-Payload mischt keine Fireteams/Peers"},
	{"id": "mission_insertion_visible", "label": "Mission, Drop und Ausstieg sind nachvollziehbar"},
	{"id": "move_preview_before_go", "label": "Move/Decision-Preview ist vor GO lesbar"},
	{"id": "decision_card_actionable", "label": "Decision-Card ist handlungsfaehig"},
	{"id": "first_firefight_response_fast", "label": "Erster Feuerwechsel reagiert schnell genug"},
	{"id": "no_auto_command_commit", "label": "Preview/Decision committed keine Commands automatisch"},
	{"id": "exit_or_debrief_path_visible", "label": "Exit/Debrief- oder naechster Griff bleibt sichtbar"},
	{"id": "no_hud_overlap_blocker", "label": "HUD verdeckt keine zwingende Aktion"},
	{"id": "screenshots_saved", "label": "Host/Client-Screenshots wurden gespeichert"},
	{"id": "workbench_json_exported", "label": "Workbench-JSON wurde exportiert"},
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
]


static func build_snapshot(candidate_snapshot: Dictionary = {}, review_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var findings: Array = []
	var action_items: Array = []
	_add_candidate_findings(findings, candidate_snapshot)
	var required_checks: Array = _build_required_checks(review_notes)
	var issue_flags: Array = _build_issue_flags(review_notes)
	var completed_check_count: int = _count_completed_checks(required_checks)
	var missing_check_ids: Array[String] = _missing_check_ids(required_checks)
	var active_issue_count: int = _add_issue_flag_findings(findings, action_items, issue_flags)
	var blocker_count: int = _count_findings_by_severity(findings, "blocker")
	var manual_done: bool = _read_bool(review_notes, "reentry_firefight_multiplayer_playable_candidate_findings.manual_review_done")
	var real_run_done: bool = _read_bool(review_notes, "reentry_firefight_multiplayer_playable_candidate_findings.real_run_done")
	var status: String = _build_status(blocker_count, manual_done, real_run_done, missing_check_ids, active_issue_count)
	if status == "needs_visible_multiplayer_playable_candidate_real_run":
		findings.append(_finding("visible_multiplayer_playable_candidate_real_run_open", "manual", "Sichtbarer Host/Client-Real-Run des Playable-Candidates fehlt oder ist noch nicht bewusst abgeschlossen.", "TASK_797 - run Station Reentry Firefight Multiplayer Playable Slice Candidate"))
	elif status == "needs_multiplayer_playable_candidate_completion":
		findings.append(_finding("multiplayer_playable_candidate_checks_missing", "manual", "Playable-Candidate-Review ist angefangen, aber Pflichtchecks fehlen: %s" % ", ".join(PackedStringArray(missing_check_ids)), "TASK_797 - complete missing playable candidate checks"))
	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_798",
		"source_task_id": EXPECTED_CANDIDATE_TASK_ID,
		"source_schema": String(candidate_snapshot.get("schema", "")),
		"source_status": String(candidate_snapshot.get("status", "")),
		"source_candidate_manifest_path": String(options.get("candidate_manifest_path", DEFAULT_CANDIDATE_MANIFEST_PATH)),
		"runtime_authority": "read-only findings over TASK_797 multiplayer playable slice candidate and optional real-run notes",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"candidate_ready": bool(candidate_snapshot.get("candidate_ready", false)),
		"scenario_path": String(candidate_snapshot.get("scenario_path", "")),
		"workbench_path": String(candidate_snapshot.get("workbench_path", "")),
		"workbench_file_uri": String(candidate_snapshot.get("workbench_file_uri", "")),
		"real_run_manifest_path": String(options.get("real_run_manifest_path", DEFAULT_REAL_RUN_MANIFEST_PATH)),
		"host_screenshot_path": String(options.get("host_screenshot_path", DEFAULT_HOST_SCREENSHOT_PATH)),
		"client_screenshot_path": String(options.get("client_screenshot_path", DEFAULT_CLIENT_SCREENSHOT_PATH)),
		"expected_host_role": String(candidate_snapshot.get("expected_host_role", "")),
		"expected_client_role": String(candidate_snapshot.get("expected_client_role", "")),
		"expected_decision_line": String(candidate_snapshot.get("expected_decision_line", "")),
		"expected_guard_line": String(candidate_snapshot.get("expected_guard_line", "")),
		"commands": Dictionary(candidate_snapshot.get("commands", {})).duplicate(true),
		"manual_review_required": true,
		"manual_review_done": manual_done,
		"real_run_done": real_run_done,
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


static func _add_candidate_findings(findings: Array, candidate: Dictionary) -> void:
	if candidate.is_empty():
		findings.append(_finding("missing_task_797_candidate", "blocker", "TASK_797-Playable-Candidate fehlt.", "TASK_797 - Station Reentry Firefight Multiplayer Playable Slice Candidate"))
		return
	if String(candidate.get("schema", "")) != EXPECTED_CANDIDATE_SCHEMA:
		findings.append(_finding("unexpected_task_797_candidate_schema", "blocker", "TASK_797-Candidate hat ein unerwartetes Schema.", "TASK_797 verifier rerun"))
	if String(candidate.get("task_id", "")) != EXPECTED_CANDIDATE_TASK_ID:
		findings.append(_finding("unexpected_task_797_candidate_task", "blocker", "Candidate gehoert nicht zu TASK_797.", "TASK_797 verifier rerun"))
	if String(candidate.get("status", "")) != "ready_for_multiplayer_playable_slice_candidate" or not bool(candidate.get("candidate_ready", false)):
		findings.append(_finding("task_797_candidate_not_ready", "blocker", "TASK_797-Candidate ist nicht spielbereit.", "TASK_797 rerun or repair"))
	if not bool(candidate.get("read_only", false)) \
			or bool(candidate.get("ui_sets_gameplay_truth", true)) \
			or bool(candidate.get("creates_command", true)) \
			or bool(candidate.get("creates_navigation", true)) \
			or bool(candidate.get("creates_fire_event", true)) \
			or bool(candidate.get("creates_damage_event", true)):
		findings.append(_finding("task_797_candidate_not_readonly", "blocker", "TASK_797-Candidate verletzt read-only/UI-Truth-Grenzen.", "TASK_797 verifier rerun"))
	if Array(candidate.get("player_flow_checkpoints", [])).is_empty():
		findings.append(_finding("task_797_candidate_missing_player_checkpoints", "blocker", "TASK_797-Candidate enthaelt keine Spieler-Checkpoints.", "TASK_797 repair"))


static func _build_required_checks(review_notes: Dictionary) -> Array:
	var checks: Array = []
	for check_def in REQUIRED_CHECKS:
		var id: String = String(check_def.get("id", ""))
		checks.append({
			"id": id,
			"label": String(check_def.get("label", id)),
			"checked": _read_bool(review_notes, "reentry_firefight_multiplayer_playable_candidate_findings.%s" % id),
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
			"active": _read_bool(review_notes, "reentry_firefight_multiplayer_playable_candidate_findings.issues.%s" % String(id)),
			"recommended_task": String(ISSUE_TO_ACTION.get(id, "")),
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return flags


static func _issue_label(id: String) -> String:
	match id:
		"singleplayer_homebase_blocked":
			return "Einzelspieler/Homebase ist noch blockiert"
		"fireteam_list_confusing":
			return "Fireteam-Liste ist unklar oder widerspruechlich"
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
		var next_task: String = String(flag.get("recommended_task", "TASK_799 - Station Reentry Firefight Multiplayer Playable Candidate Acceptance"))
		findings.append(_finding("multiplayer_playable_candidate_issue_%s" % id, "polish", label, next_task))
		action_items.append({
			"id": id,
			"label": label,
			"recommended_task": next_task,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return count


static func _build_status(blocker_count: int, manual_done: bool, real_run_done: bool, missing_check_ids: Array, active_issue_count: int) -> String:
	if blocker_count > 0:
		return "blocked"
	if not manual_done or not real_run_done:
		return "needs_visible_multiplayer_playable_candidate_real_run"
	if not missing_check_ids.is_empty():
		return "needs_multiplayer_playable_candidate_completion"
	if active_issue_count > 0:
		return "needs_targeted_multiplayer_playable_candidate_polish"
	return "ready_for_multiplayer_playable_candidate_acceptance"


static func _build_summary(status: String, completed_check_count: int, required_check_count: int, active_issue_count: int) -> String:
	if status == "blocked":
		return "TASK_798 blockiert: TASK_797-Candidate fehlt oder ist ungueltig."
	if status == "needs_visible_multiplayer_playable_candidate_real_run":
		return "Sichtbarer Multiplayer-Playable-Candidate-Real-Run offen, %d/%d Checks gesetzt." % [completed_check_count, required_check_count]
	if status == "needs_multiplayer_playable_candidate_completion":
		return "Multiplayer-Playable-Candidate-Review unvollstaendig, %d/%d Checks gesetzt." % [completed_check_count, required_check_count]
	if status == "needs_targeted_multiplayer_playable_candidate_polish":
		return "%d konkrete Multiplayer-Playable-Candidate-Follow-up-Flag(s)." % active_issue_count
	return "Multiplayer-Playable-Candidate-Findings sind sauber genug fuer Acceptance."


static func _recommended_next_task(status: String, action_items: Array) -> String:
	if status == "blocked":
		return "TASK_797 - Station Reentry Firefight Multiplayer Playable Slice Candidate"
	if status == "needs_visible_multiplayer_playable_candidate_real_run":
		return "TASK_797 - run Station Reentry Firefight Multiplayer Playable Slice Candidate"
	if status == "needs_multiplayer_playable_candidate_completion":
		return "TASK_797 - complete missing multiplayer playable candidate checks"
	if status == "needs_targeted_multiplayer_playable_candidate_polish":
		if not action_items.is_empty() and typeof(action_items[0]) == TYPE_DICTIONARY:
			return String(Dictionary(action_items[0]).get("recommended_task", "TASK_799 - Station Reentry Firefight Multiplayer Playable Candidate Acceptance"))
		return "TASK_799 - Station Reentry Firefight Multiplayer Playable Candidate Acceptance"
	return "TASK_799 - Station Reentry Firefight Multiplayer Playable Candidate Acceptance"


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
