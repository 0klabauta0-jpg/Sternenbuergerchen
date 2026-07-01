class_name StationReentryFirefightMultiplayerDecisionAcceptance
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_multiplayer_decision_acceptance.v1"
const EXPECTED_FINDINGS_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_decision_host_client_findings.v1"
const EXPECTED_FINDINGS_TASK_ID: String = "TASK_792"
const DEFAULT_FINDINGS_MANIFEST_PATH: String = "tmp/station_reentry_firefight_decision_host_client_findings.json"
const DEFAULT_ACCEPTANCE_MANIFEST_PATH: String = "tmp/station_reentry_firefight_multiplayer_decision_acceptance.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/project_current_state_handbook_reentry_2026_07_01.html"


static func build_snapshot(findings_snapshot: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var findings: Array = []
	var source_valid: bool = _source_is_valid(findings_snapshot)
	var source_read_only: bool = _source_is_read_only(findings_snapshot)
	var source_status: String = String(findings_snapshot.get("status", ""))
	var source_missing_check_ids: Array = Array(findings_snapshot.get("missing_check_ids", [])).duplicate(true)
	var source_action_items: Array = Array(findings_snapshot.get("action_items", [])).duplicate(true)
	var source_active_issue_count: int = int(findings_snapshot.get("active_issue_count", 0))

	if not source_valid:
		findings.append(_finding("invalid_task_792_findings", "blocker", "TASK_792-Findings fehlen oder haben Schema/Task-Konflikt.", "TASK_792 - Station Reentry Firefight Decision Host Client Findings"))
	if source_valid and not source_read_only:
		findings.append(_finding("task_792_findings_not_read_only", "blocker", "TASK_792-Findings verletzen read-only/UI-Truth-Grenzen.", "TASK_792 - rerun Decision Host/Client Findings"))

	var gates: Array = [
		_gate("findings_ready", source_status == "ready_for_firefight_multiplayer_decision_acceptance", "TASK_792 meldet bereit fuer Multiplayer-Decision-Acceptance"),
		_gate("manual_review_done", bool(findings_snapshot.get("manual_review_done", false)), "Manueller Host/Client-Review bewusst abgeschlossen"),
		_gate("visible_review_done", bool(findings_snapshot.get("visible_review_done", false)), "Sichtbarer Zwei-Fenster-Review wirklich ausgefuehrt"),
		_gate("no_missing_checks", source_missing_check_ids.is_empty(), "Keine TASK_792-Pflichtchecks fehlen"),
		_gate("no_active_issues", source_active_issue_count == 0, "Keine aktiven Host/Client-Decision-Issues"),
		_gate("decision_core_synced", _decision_core_synced(findings_snapshot), "Decision-Line, Primary, Quick-Actions, Reason, Guard und Confirm sind synchron vorhanden"),
		_gate("host_client_roles_distinct", _host_client_roles_distinct(findings_snapshot), "Host- und Client-Rollen bleiben unterscheidbar"),
		_gate("no_auto_command_guard", bool(findings_snapshot.get("expected_no_auto_command_commit", false)) and bool(findings_snapshot.get("expected_existing_commands_only", false)), "Decision-Surface fuehrt keine Commands automatisch aus und nutzt bestehende Controls"),
		_gate("host_client_context_kept", bool(findings_snapshot.get("expected_host_client_context_visible", false)), "Host/Client-Kontext bleibt sichtbar"),
		_gate("source_read_only", source_read_only, "Quelle bleibt read-only und mutiert keine Gameplay-Wahrheit"),
	]
	var failed_gate_ids: Array[String] = _failed_gate_ids(gates)
	var status: String = _build_status(source_valid, source_read_only, source_status, source_missing_check_ids, source_active_issue_count, failed_gate_ids)
	if status == "needs_decision_host_client_review_completion":
		findings.append(_finding("multiplayer_decision_missing_checks", "manual", "TASK_792-Pflichtchecks fehlen: %s" % ", ".join(PackedStringArray(source_missing_check_ids)), "TASK_791 - complete missing Host/Client Decision checks"))
	elif status == "needs_targeted_decision_host_client_polish":
		findings.append(_finding("multiplayer_decision_active_issues", "polish", "TASK_792 meldet aktive Host/Client-Decision-Follow-ups.", _first_action_task(source_action_items)))

	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_793",
		"source_task_id": EXPECTED_FINDINGS_TASK_ID,
		"source_schema": String(findings_snapshot.get("schema", "")),
		"source_status": source_status,
		"source_findings_manifest_path": String(options.get("findings_manifest_path", DEFAULT_FINDINGS_MANIFEST_PATH)),
		"runtime_authority": "read-only acceptance over TASK_792 decision host/client findings",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"source_read_only": source_read_only,
		"source_valid": source_valid,
		"source_manual_review_done": bool(findings_snapshot.get("manual_review_done", false)),
		"source_visible_review_done": bool(findings_snapshot.get("visible_review_done", false)),
		"source_missing_check_ids": source_missing_check_ids,
		"source_active_issue_count": source_active_issue_count,
		"source_action_items": source_action_items,
		"expected_decision_line": String(findings_snapshot.get("expected_decision_line", "")),
		"expected_primary_action_label": String(findings_snapshot.get("expected_primary_action_label", "")),
		"expected_quick_action_labels": Array(findings_snapshot.get("expected_quick_action_labels", [])).duplicate(true),
		"expected_reason_line": String(findings_snapshot.get("expected_reason_line", "")),
		"expected_guard_line": String(findings_snapshot.get("expected_guard_line", "")),
		"expected_confirm_control": String(findings_snapshot.get("expected_confirm_control", "")),
		"expected_no_auto_command_commit": bool(findings_snapshot.get("expected_no_auto_command_commit", false)),
		"expected_existing_commands_only": bool(findings_snapshot.get("expected_existing_commands_only", false)),
		"expected_host_client_context_visible": bool(findings_snapshot.get("expected_host_client_context_visible", false)),
		"expected_host_role": String(findings_snapshot.get("expected_host_role", "")),
		"expected_client_role": String(findings_snapshot.get("expected_client_role", "")),
		"checks": gates,
		"failed_check_ids": failed_gate_ids,
		"failed_gate_ids": failed_gate_ids,
		"findings": findings,
		"finding_count": findings.size(),
		"status": status,
		"accepted_for_multiplayer_firefight_decision_slice": status == "accepted_for_multiplayer_firefight_decision_slice",
		"summary": _build_summary(status, failed_gate_ids, source_active_issue_count),
		"recommended_next_task": _recommended_next_task(status, source_action_items),
		"report_path": String(options.get("report_path", DEFAULT_REPORT_PATH)),
		"manifest_path": String(options.get("manifest_path", DEFAULT_ACCEPTANCE_MANIFEST_PATH)),
	}


static func _source_is_valid(source: Dictionary) -> bool:
	return not source.is_empty() \
			and String(source.get("schema", "")) == EXPECTED_FINDINGS_SCHEMA \
			and String(source.get("task_id", "")) == EXPECTED_FINDINGS_TASK_ID


static func _source_is_read_only(source: Dictionary) -> bool:
	return bool(source.get("read_only", false)) \
			and not bool(source.get("ui_sets_gameplay_truth", true)) \
			and not bool(source.get("creates_navigation", true)) \
			and not bool(source.get("creates_command", true)) \
			and not bool(source.get("creates_fire_event", true)) \
			and not bool(source.get("creates_damage_event", true))


static func _decision_core_synced(source: Dictionary) -> bool:
	return String(source.get("expected_decision_line", "")).strip_edges() != "" \
			and String(source.get("expected_primary_action_label", "")).strip_edges() != "" \
			and not Array(source.get("expected_quick_action_labels", [])).is_empty() \
			and String(source.get("expected_reason_line", "")).strip_edges() != "" \
			and String(source.get("expected_guard_line", "")).strip_edges() != "" \
			and String(source.get("expected_confirm_control", "")).strip_edges() != ""


static func _host_client_roles_distinct(source: Dictionary) -> bool:
	var host_role: String = String(source.get("expected_host_role", "")).strip_edges()
	var client_role: String = String(source.get("expected_client_role", "")).strip_edges()
	return host_role != "" and client_role != "" and host_role != client_role


static func _build_status(source_valid: bool, source_read_only: bool, source_status: String, missing_check_ids: Array, active_issue_count: int, failed_gate_ids: Array[String]) -> String:
	if not source_valid or not source_read_only:
		return "blocked_until_decision_host_client_findings"
	if source_status == "needs_visible_decision_host_client_review":
		return "needs_visible_decision_host_client_review"
	if source_status == "needs_decision_host_client_review_completion" or not missing_check_ids.is_empty():
		return "needs_decision_host_client_review_completion"
	if source_status == "needs_targeted_decision_host_client_polish" or active_issue_count > 0:
		return "needs_targeted_decision_host_client_polish"
	if source_status == "ready_for_firefight_multiplayer_decision_acceptance" and failed_gate_ids.is_empty():
		return "accepted_for_multiplayer_firefight_decision_slice"
	return "blocked_until_multiplayer_decision_acceptance_gates_green"


static func _recommended_next_task(status: String, action_items: Array) -> String:
	match status:
		"blocked_until_decision_host_client_findings":
			return "TASK_792 - Station Reentry Firefight Decision Host Client Findings"
		"needs_visible_decision_host_client_review":
			return "TASK_791 - run visible Station Reentry Firefight Decision Host Client Recapture"
		"needs_decision_host_client_review_completion":
			return "TASK_791 - complete missing Host/Client Decision checks"
		"needs_targeted_decision_host_client_polish":
			return _first_action_task(action_items)
		"accepted_for_multiplayer_firefight_decision_slice":
			return "TASK_794 - Station Reentry Firefight Multiplayer Decision Playtest Packet"
	return "TASK_793 - fix Station Reentry Firefight Multiplayer Decision Acceptance gates"


static func _first_action_task(action_items: Array) -> String:
	if not action_items.is_empty() and typeof(action_items[0]) == TYPE_DICTIONARY:
		var task: String = String(Dictionary(action_items[0]).get("recommended_task", ""))
		if task.strip_edges() != "":
			return task
	return "TASK_787 - Station Reentry Firefight Player Decision Readability Pass"


static func _build_summary(status: String, failed_gate_ids: Array[String], active_issue_count: int) -> String:
	match status:
		"blocked_until_decision_host_client_findings":
			return "Acceptance blockiert: TASK_792-Findings fehlen, sind ungueltig oder nicht read-only."
		"needs_visible_decision_host_client_review":
			return "Host/Client-Decision muss im Zwei-Fenster-Lauf noch sichtbar geprueft werden."
		"needs_decision_host_client_review_completion":
			return "Host/Client-Decision-Review ist noch nicht vollstaendig."
		"needs_targeted_decision_host_client_polish":
			return "%d Host/Client-Decision-Follow-up-Flag(s) muessen gezielt poliert werden." % active_issue_count
		"accepted_for_multiplayer_firefight_decision_slice":
			return "Multiplayer-Decision-Slice ist eng akzeptiert; naechster Griff ist ein Playtest-Paket."
	return "Multiplayer-Decision-Acceptance-Gates offen: %s" % ", ".join(PackedStringArray(failed_gate_ids))


static func _gate(id: String, passed: bool, label: String) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"passed": passed,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _failed_gate_ids(gates: Array) -> Array[String]:
	var failed: Array[String] = []
	for gate_variant in gates:
		if typeof(gate_variant) != TYPE_DICTIONARY:
			continue
		var gate: Dictionary = Dictionary(gate_variant)
		if not bool(gate.get("passed", false)):
			failed.append(String(gate.get("id", "")))
	return failed


static func _finding(id: String, severity: String, message: String, suggested_next: String) -> Dictionary:
	return {
		"id": id,
		"severity": severity,
		"message": message,
		"suggested_next": suggested_next,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}
