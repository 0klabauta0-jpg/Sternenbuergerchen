class_name StationReentryFirefightMultiplayerDecisionPlaytestFindings
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_multiplayer_decision_playtest_findings.v1"
const EXPECTED_PACKET_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_multiplayer_decision_playtest_packet.v1"
const EXPECTED_PACKET_TASK_ID: String = "TASK_794"
const DEFAULT_PACKET_MANIFEST_PATH: String = "tmp/station_reentry_firefight_multiplayer_decision_playtest_packet.json"
const DEFAULT_FINDINGS_MANIFEST_PATH: String = "tmp/station_reentry_firefight_multiplayer_decision_playtest_findings.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/project_current_state_handbook_reentry_2026_07_01.html"

const REQUIRED_CHECKS: Array[Dictionary] = [
	{"id": "host_window_open", "label": "Host-Fenster sichtbar offen"},
	{"id": "client_window_open", "label": "Client-Fenster sichtbar offen"},
	{"id": "host_decision_card_visible", "label": "Host: Decision-Card sichtbar"},
	{"id": "client_decision_card_visible", "label": "Client: Decision-Card sichtbar"},
	{"id": "host_client_same_decision_line", "label": "Host/Client: Decision-Line gleich"},
	{"id": "host_client_same_primary_action", "label": "Host/Client: Primary gleich"},
	{"id": "host_client_same_quick_actions", "label": "Host/Client: Quick-Actions gleich"},
	{"id": "host_client_same_reason_line", "label": "Host/Client: Reason-Line gleich"},
	{"id": "host_client_same_guard_line", "label": "Host/Client: Guard-Line gleich"},
	{"id": "host_client_same_confirm_control", "label": "Host/Client: Confirm-Control gleich"},
	{"id": "no_auto_command_commit_visible", "label": "No-Auto-Command-Grenze sichtbar"},
	{"id": "existing_buttons_visible", "label": "Bestehende Command-Buttons sichtbar"},
	{"id": "peer_team_context_distinct", "label": "Peer-/Team-Kontext bleibt getrennt"},
	{"id": "decision_choice_feels_actionable", "label": "Decision-Auswahl fuehlt sich handlungsfaehig an"},
	{"id": "firefight_response_stays_fast", "label": "Firefight-Reaktion bleibt schnell"},
	{"id": "screenshot_saved", "label": "Screenshot/Evidence wurde gespeichert"},
	{"id": "workbench_json_exported", "label": "Workbench-JSON wurde exportiert"},
]

const ISSUE_TO_ACTION: Dictionary = {
	"host_decision_card_missing": "TASK_787 - Station Reentry Firefight Player Decision Readability Pass",
	"client_decision_card_missing": "TASK_787 - Station Reentry Firefight Player Decision Readability Pass",
	"decision_line_mismatch": "TASK_770 - Station Reentry Host Client Next Order Sync",
	"primary_action_mismatch": "TASK_770 - Station Reentry Host Client Next Order Sync",
	"quick_actions_mismatch": "TASK_786 - Station Reentry Firefight Host Client Polished Surface Check",
	"reason_line_mismatch": "TASK_787 - Station Reentry Firefight Player Decision Readability Pass",
	"guard_line_mismatch": "TASK_783 - Station Reentry Firefight Command Surface Polish",
	"confirm_control_mismatch": "TASK_736 - Station Scenario Command Feedback Polish",
	"no_auto_command_confusing": "TASK_501 - Integrated Movement Command Lifecycle Hardening",
	"existing_buttons_missing": "TASK_736 - Station Scenario Command Feedback Polish",
	"peer_team_context_mixed": "TASK_773 - Station Reentry Host Client Identity Cue Polish",
	"decision_choice_not_actionable": "TASK_787 - Station Reentry Firefight Player Decision Readability Pass",
	"firefight_response_stutter_visible": "TASK_769 - Station Reentry Performance Feel Pass",
	"screenshot_missing": "TASK_794 - rerun visible multiplayer decision playtest packet",
	"workbench_export_missing": "TASK_794 - complete multiplayer decision playtest workbench export",
}

const ISSUE_FLAG_IDS: Array[String] = [
	"host_decision_card_missing",
	"client_decision_card_missing",
	"decision_line_mismatch",
	"primary_action_mismatch",
	"quick_actions_mismatch",
	"reason_line_mismatch",
	"guard_line_mismatch",
	"confirm_control_mismatch",
	"no_auto_command_confusing",
	"existing_buttons_missing",
	"peer_team_context_mixed",
	"decision_choice_not_actionable",
	"firefight_response_stutter_visible",
	"screenshot_missing",
	"workbench_export_missing",
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
	var manual_done: bool = _read_bool(review_notes, "reentry_firefight_multiplayer_decision_playtest_findings.manual_review_done")
	var visible_review_done: bool = _read_bool(review_notes, "reentry_firefight_multiplayer_decision_playtest_findings.visible_review_done")
	var status: String = _build_status(blocker_count, manual_done, visible_review_done, missing_check_ids, active_issue_count)
	if status == "needs_visible_multiplayer_decision_playtest_review":
		findings.append(_finding("visible_multiplayer_decision_playtest_review_open", "manual", "Sichtbarer Host/Client-Multiplayer-Decision-Playtest fehlt oder ist noch nicht bewusst abgeschlossen.", "TASK_794 - run visible multiplayer decision playtest"))
	elif status == "needs_multiplayer_decision_playtest_completion":
		findings.append(_finding("multiplayer_decision_playtest_checks_missing", "manual", "Multiplayer-Decision-Playtest ist angefangen, aber Pflichtchecks fehlen: %s" % ", ".join(PackedStringArray(missing_check_ids)), "TASK_794 - complete missing multiplayer decision playtest checks"))
	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_795",
		"source_task_id": EXPECTED_PACKET_TASK_ID,
		"runtime_authority": "read-only findings over TASK_794 multiplayer decision playtest packet and optional report notes",
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
		"target_id": String(packet_manifest.get("target_id", "station_reentry_firefight_multiplayer_decision_playtest")),
		"scenario_path": String(packet_manifest.get("scenario_path", "")),
		"workbench_path": String(packet_manifest.get("workbench_path", "")),
		"workbench_file_uri": String(packet_manifest.get("workbench_file_uri", "")),
		"acceptance_status": String(packet_manifest.get("acceptance_status", "")),
		"accepted_for_multiplayer_firefight_decision_slice": bool(packet_manifest.get("accepted_for_multiplayer_firefight_decision_slice", false)),
		"expected_decision_line": String(packet_manifest.get("expected_decision_line", "")),
		"expected_primary_action_label": String(packet_manifest.get("expected_primary_action_label", "")),
		"expected_quick_action_labels": Array(packet_manifest.get("expected_quick_action_labels", [])).duplicate(true),
		"expected_reason_line": String(packet_manifest.get("expected_reason_line", "")),
		"expected_guard_line": String(packet_manifest.get("expected_guard_line", "")),
		"expected_confirm_control": String(packet_manifest.get("expected_confirm_control", "")),
		"expected_no_auto_command_commit": bool(packet_manifest.get("expected_no_auto_command_commit", false)),
		"expected_existing_commands_only": bool(packet_manifest.get("expected_existing_commands_only", false)),
		"expected_host_client_context_visible": bool(packet_manifest.get("expected_host_client_context_visible", false)),
		"expected_host_role": String(packet_manifest.get("expected_host_role", "")),
		"expected_client_role": String(packet_manifest.get("expected_client_role", "")),
		"manual_two_window_playtest_required": bool(packet_manifest.get("manual_two_window_playtest_required", false)),
		"source_packet_claims_manual_done": bool(packet_manifest.get("manual_two_window_playtest_done", false)),
		"manual_review_required": true,
		"manual_review_done": manual_done,
		"visible_review_done": visible_review_done,
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
		findings.append(_finding("missing_task_794_packet", "blocker", "TASK_794-Multiplayer-Decision-Playtest-Paket fehlt.", "TASK_794 - rerun Station Reentry Firefight Multiplayer Decision Playtest Packet"))
		return
	if String(packet_manifest.get("schema", "")) != EXPECTED_PACKET_SCHEMA:
		findings.append(_finding("unexpected_task_794_packet_schema", "blocker", "TASK_794-Paket hat ein unerwartetes Schema.", "TASK_794 verifier rerun"))
	if String(packet_manifest.get("task_id", "")) != EXPECTED_PACKET_TASK_ID:
		findings.append(_finding("unexpected_task_794_packet_task", "blocker", "Paket gehoert nicht zu TASK_794.", "TASK_794 verifier rerun"))
	if String(packet_manifest.get("status", "")) != "ready_to_playtest_firefight_multiplayer_decision":
		findings.append(_finding("task_794_packet_not_ready", "blocker", "TASK_794-Paket ist nicht playtest-bereit.", "TASK_794 repair or rerun"))
	if not bool(packet_manifest.get("read_only", false)) \
			or bool(packet_manifest.get("ui_sets_gameplay_truth", true)) \
			or bool(packet_manifest.get("creates_command", true)) \
			or bool(packet_manifest.get("creates_navigation", true)) \
			or bool(packet_manifest.get("creates_fire_event", true)) \
			or bool(packet_manifest.get("creates_damage_event", true)):
		findings.append(_finding("task_794_packet_not_readonly", "blocker", "TASK_794-Paket verletzt read-only/UI-Truth-Regeln.", "TASK_794 verifier rerun"))
	if not bool(packet_manifest.get("accepted_for_multiplayer_firefight_decision_slice", false)):
		findings.append(_finding("task_794_missing_accepted_multiplayer_decision_slice", "blocker", "TASK_794-Paket basiert nicht auf akzeptierter TASK_793-Multiplayer-Decision.", "TASK_793 - Station Reentry Firefight Multiplayer Decision Acceptance"))
	if not bool(packet_manifest.get("expected_no_auto_command_commit", false)):
		findings.append(_finding("task_794_missing_no_auto_commit_expectation", "blocker", "TASK_794-Paket traegt keine No-Auto-Command-Erwartung.", "TASK_794 verifier rerun"))
	if not bool(packet_manifest.get("expected_existing_commands_only", false)):
		findings.append(_finding("task_794_missing_existing_command_expectation", "blocker", "TASK_794-Paket traegt keine Existing-Commands-only-Erwartung.", "TASK_794 verifier rerun"))
	if not bool(packet_manifest.get("expected_host_client_context_visible", false)):
		findings.append(_finding("task_794_missing_host_client_context_expectation", "blocker", "TASK_794-Paket traegt keine Host/Client-Kontext-Erwartung.", "TASK_794 verifier rerun"))
	if not bool(packet_manifest.get("manual_two_window_playtest_required", false)):
		findings.append(_finding("task_794_missing_manual_playtest_requirement", "blocker", "TASK_794-Paket verlangt keinen manuellen Zwei-Fenster-Playtest.", "TASK_794 verifier rerun"))
	if bool(packet_manifest.get("manual_two_window_playtest_done", false)):
		findings.append(_finding("task_794_packet_claims_manual_done", "blocker", "TASK_794-Paket darf den sichtbaren Playtest nicht selbst als erledigt markieren.", "TASK_794 verifier rerun"))


static func _build_required_checks(review_notes: Dictionary) -> Array:
	var checks: Array = []
	for check_def in REQUIRED_CHECKS:
		var id: String = String(check_def.get("id", ""))
		checks.append({
			"id": id,
			"label": String(check_def.get("label", id)),
			"checked": _read_bool(review_notes, "reentry_firefight_multiplayer_decision_playtest_findings.%s" % id) \
					or _read_bool(review_notes, "reentry_firefight_multiplayer_decision_playtest_packet.%s" % id),
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
			"active": _read_bool(review_notes, "reentry_firefight_multiplayer_decision_playtest_findings.issues.%s" % String(id)),
			"recommended_task": String(ISSUE_TO_ACTION.get(id, "")),
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return flags


static func _issue_label(id: String) -> String:
	match id:
		"host_decision_card_missing":
			return "Host zeigt die Decision-Card nicht sichtbar"
		"client_decision_card_missing":
			return "Client zeigt die Decision-Card nicht sichtbar"
		"decision_line_mismatch":
			return "Host/Client Decision-Line weicht ab"
		"primary_action_mismatch":
			return "Host/Client Primary-Action weicht ab"
		"quick_actions_mismatch":
			return "Host/Client Quick-Actions weichen ab"
		"reason_line_mismatch":
			return "Host/Client Reason-Line weicht ab"
		"guard_line_mismatch":
			return "Host/Client Guard-Line weicht ab"
		"confirm_control_mismatch":
			return "Host/Client Confirm-Control weicht ab"
		"no_auto_command_confusing":
			return "No-Auto-Command-Grenze ist im Host/Client-Blick unklar"
		"existing_buttons_missing":
			return "Bestehende Command-Buttons fehlen oder wirken ersetzt"
		"peer_team_context_mixed":
			return "Peer-/Team-Kontext vermischt Host und Client"
		"decision_choice_not_actionable":
			return "Decision-Auswahl wirkt nicht handlungsfaehig"
		"firefight_response_stutter_visible":
			return "Firefight-Response wirkt zaeh oder stottert"
		"screenshot_missing":
			return "Screenshot/Evidence fehlt"
		"workbench_export_missing":
			return "Workbench-JSON-Export fehlt"
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
		var next_task: String = String(flag.get("recommended_task", "TASK_787 - Station Reentry Firefight Player Decision Readability Pass"))
		findings.append(_finding("multiplayer_decision_playtest_issue_%s" % id, "polish", label, next_task))
		action_items.append({
			"id": id,
			"label": label,
			"recommended_task": next_task,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return count


static func _build_status(blocker_count: int, manual_done: bool, visible_review_done: bool, missing_check_ids: Array, active_issue_count: int) -> String:
	if blocker_count > 0:
		return "blocked"
	if not manual_done or not visible_review_done:
		return "needs_visible_multiplayer_decision_playtest_review"
	if not missing_check_ids.is_empty():
		return "needs_multiplayer_decision_playtest_completion"
	if active_issue_count > 0:
		return "needs_targeted_multiplayer_decision_polish"
	return "ready_for_multiplayer_decision_playtest_acceptance"


static func _build_summary(status: String, completed_check_count: int, required_check_count: int, active_issue_count: int) -> String:
	if status == "blocked":
		return "TASK_795 blockiert: TASK_794-Multiplayer-Decision-Playtest-Paket fehlt oder ist ungueltig."
	if status == "needs_visible_multiplayer_decision_playtest_review":
		return "Sichtbarer Multiplayer-Decision-Playtest offen, %d/%d Checks gesetzt." % [completed_check_count, required_check_count]
	if status == "needs_multiplayer_decision_playtest_completion":
		return "Multiplayer-Decision-Playtest unvollstaendig, %d/%d Checks gesetzt." % [completed_check_count, required_check_count]
	if status == "needs_targeted_multiplayer_decision_polish":
		return "%d konkrete Multiplayer-Decision-Playtest-Follow-up-Flag(s)." % active_issue_count
	return "Multiplayer-Decision-Playtest-Findings sind sauber genug fuer eine enge Acceptance."


static func _recommended_next_task(status: String, action_items: Array) -> String:
	if status == "blocked":
		return "TASK_794 - rerun Station Reentry Firefight Multiplayer Decision Playtest Packet"
	if status == "needs_visible_multiplayer_decision_playtest_review":
		return "TASK_794 - run visible multiplayer decision playtest"
	if status == "needs_multiplayer_decision_playtest_completion":
		return "TASK_794 - complete missing multiplayer decision playtest checks"
	if status == "needs_targeted_multiplayer_decision_polish":
		if not action_items.is_empty() and typeof(action_items[0]) == TYPE_DICTIONARY:
			return String(Dictionary(action_items[0]).get("recommended_task", "TASK_787 - Station Reentry Firefight Player Decision Readability Pass"))
		return "TASK_787 - Station Reentry Firefight Player Decision Readability Pass"
	return "TASK_796 - Station Reentry Firefight Multiplayer Decision Playtest Acceptance"


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
