class_name StationReentryFirefightMultiplayerPlayableCandidateAcceptance
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_multiplayer_playable_candidate_acceptance.v1"
const EXPECTED_FINDINGS_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_multiplayer_playable_candidate_real_run_findings.v1"
const EXPECTED_FINDINGS_TASK_ID: String = "TASK_798"
const DEFAULT_FINDINGS_MANIFEST_PATH: String = "tmp/station_reentry_firefight_multiplayer_playable_candidate_real_run_findings.json"
const DEFAULT_ACCEPTANCE_MANIFEST_PATH: String = "tmp/station_reentry_firefight_multiplayer_playable_candidate_acceptance.json"
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
		findings.append(_finding("invalid_task_798_findings", "blocker", "TASK_798-Findings fehlen oder haben Schema/Task-Konflikt.", "TASK_798 - Station Reentry Firefight Multiplayer Playable Candidate Real Run Findings"))
	if source_valid and not source_read_only:
		findings.append(_finding("task_798_findings_not_read_only", "blocker", "TASK_798-Findings verletzen read-only/UI-Truth-Grenzen.", "TASK_798 - rerun Multiplayer Playable Candidate Findings"))

	var gates: Array = [
		_gate("findings_ready", source_status == "ready_for_multiplayer_playable_candidate_acceptance", "TASK_798 meldet bereit fuer Playable-Candidate-Acceptance"),
		_gate("manual_review_done", bool(findings_snapshot.get("manual_review_done", false)), "Manueller Playable-Candidate-Review bewusst abgeschlossen"),
		_gate("real_run_done", bool(findings_snapshot.get("real_run_done", false)), "Sichtbarer Host/Client-Real-Run wirklich ausgefuehrt"),
		_gate("no_missing_checks", source_missing_check_ids.is_empty(), "Keine TASK_798-Pflichtchecks fehlen"),
		_gate("no_active_issues", source_active_issue_count == 0, "Keine aktiven Playable-Candidate-Issues"),
		_gate("scenario_context_present", String(findings_snapshot.get("scenario_path", "")).strip_edges() != "", "Szenario-Kontext ist vorhanden"),
		_gate("workbench_context_present", _workbench_context_present(findings_snapshot), "Workbench-Kontext bleibt nachvollziehbar"),
		_gate("host_client_roles_distinct", _host_client_roles_distinct(findings_snapshot), "Host- und Client-Rollen bleiben unterscheidbar"),
		_gate("decision_context_present", _decision_context_present(findings_snapshot), "Decision-/Guard-Kontext ist vorhanden"),
		_gate("commands_present", _commands_present(findings_snapshot), "Launch-, Capture- und Runtime-Export-Kommandos sind vorhanden"),
		_gate("source_read_only", source_read_only, "Quelle bleibt read-only und mutiert keine Gameplay-Wahrheit"),
	]
	var failed_gate_ids: Array[String] = _failed_gate_ids(gates)
	var status: String = _build_status(source_valid, source_read_only, source_status, source_missing_check_ids, source_active_issue_count, failed_gate_ids)
	if status == "needs_multiplayer_playable_candidate_completion":
		findings.append(_finding("multiplayer_playable_candidate_missing_checks", "manual", "TASK_798-Pflichtchecks fehlen: %s" % ", ".join(PackedStringArray(source_missing_check_ids)), "TASK_797 - complete missing multiplayer playable candidate checks"))
	elif status == "needs_targeted_multiplayer_playable_candidate_polish":
		findings.append(_finding("multiplayer_playable_candidate_active_issues", "polish", "TASK_798 meldet aktive Playable-Candidate-Follow-ups.", _first_action_task(source_action_items)))

	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_799",
		"source_task_id": EXPECTED_FINDINGS_TASK_ID,
		"source_schema": String(findings_snapshot.get("schema", "")),
		"source_status": source_status,
		"source_findings_manifest_path": String(options.get("findings_manifest_path", DEFAULT_FINDINGS_MANIFEST_PATH)),
		"runtime_authority": "read-only acceptance over TASK_798 multiplayer playable candidate real-run findings",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"source_read_only": source_read_only,
		"source_valid": source_valid,
		"source_manual_review_done": bool(findings_snapshot.get("manual_review_done", false)),
		"source_real_run_done": bool(findings_snapshot.get("real_run_done", false)),
		"source_missing_check_ids": source_missing_check_ids,
		"source_active_issue_count": source_active_issue_count,
		"source_action_items": source_action_items,
		"candidate_ready": bool(findings_snapshot.get("candidate_ready", false)),
		"scenario_path": String(findings_snapshot.get("scenario_path", "")),
		"workbench_path": String(findings_snapshot.get("workbench_path", "")),
		"workbench_file_uri": String(findings_snapshot.get("workbench_file_uri", "")),
		"real_run_manifest_path": String(findings_snapshot.get("real_run_manifest_path", "")),
		"host_screenshot_path": String(findings_snapshot.get("host_screenshot_path", "")),
		"client_screenshot_path": String(findings_snapshot.get("client_screenshot_path", "")),
		"expected_host_role": String(findings_snapshot.get("expected_host_role", "")),
		"expected_client_role": String(findings_snapshot.get("expected_client_role", "")),
		"expected_decision_line": String(findings_snapshot.get("expected_decision_line", "")),
		"expected_guard_line": String(findings_snapshot.get("expected_guard_line", "")),
		"commands": Dictionary(findings_snapshot.get("commands", {})).duplicate(true),
		"checks": gates,
		"failed_check_ids": failed_gate_ids,
		"failed_gate_ids": failed_gate_ids,
		"findings": findings,
		"finding_count": findings.size(),
		"status": status,
		"accepted_for_multiplayer_playable_candidate": status == "accepted_for_multiplayer_playable_candidate",
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


static func _workbench_context_present(source: Dictionary) -> bool:
	return String(source.get("workbench_path", "")).strip_edges() != "" \
			and String(source.get("workbench_file_uri", "")).strip_edges().begins_with("file:///")


static func _host_client_roles_distinct(source: Dictionary) -> bool:
	var host_role: String = String(source.get("expected_host_role", "")).strip_edges()
	var client_role: String = String(source.get("expected_client_role", "")).strip_edges()
	return host_role != "" and client_role != "" and host_role != client_role


static func _decision_context_present(source: Dictionary) -> bool:
	return String(source.get("expected_decision_line", "")).strip_edges() != "" \
			and String(source.get("expected_guard_line", "")).strip_edges() != ""


static func _commands_present(source: Dictionary) -> bool:
	var commands: Dictionary = Dictionary(source.get("commands", {}))
	return String(commands.get("launch_windows", "")).strip_edges() != "" \
			and String(commands.get("capture_windows", "")).strip_edges() != "" \
			and String(commands.get("runtime_release_export", "")).strip_edges() != ""


static func _build_status(source_valid: bool, source_read_only: bool, source_status: String, missing_check_ids: Array, active_issue_count: int, failed_gate_ids: Array[String]) -> String:
	if not source_valid or not source_read_only:
		return "blocked_until_multiplayer_playable_candidate_findings"
	if source_status == "needs_visible_multiplayer_playable_candidate_real_run":
		return "needs_visible_multiplayer_playable_candidate_real_run"
	if source_status == "needs_multiplayer_playable_candidate_completion" or not missing_check_ids.is_empty():
		return "needs_multiplayer_playable_candidate_completion"
	if source_status == "needs_targeted_multiplayer_playable_candidate_polish" or active_issue_count > 0:
		return "needs_targeted_multiplayer_playable_candidate_polish"
	if source_status == "ready_for_multiplayer_playable_candidate_acceptance" and failed_gate_ids.is_empty():
		return "accepted_for_multiplayer_playable_candidate"
	return "blocked_until_multiplayer_playable_candidate_acceptance_gates_green"


static func _recommended_next_task(status: String, action_items: Array) -> String:
	match status:
		"blocked_until_multiplayer_playable_candidate_findings":
			return "TASK_798 - Station Reentry Firefight Multiplayer Playable Candidate Real Run Findings"
		"needs_visible_multiplayer_playable_candidate_real_run":
			return "TASK_797 - run Station Reentry Firefight Multiplayer Playable Slice Candidate"
		"needs_multiplayer_playable_candidate_completion":
			return "TASK_797 - complete missing multiplayer playable candidate checks"
		"needs_targeted_multiplayer_playable_candidate_polish":
			return _first_action_task(action_items)
		"accepted_for_multiplayer_playable_candidate":
			return "TASK_800 - Station Reentry Firefight Multiplayer Release Candidate Packet"
	return "TASK_799 - fix Station Reentry Firefight Multiplayer Playable Candidate Acceptance gates"


static func _first_action_task(action_items: Array) -> String:
	if not action_items.is_empty() and typeof(action_items[0]) == TYPE_DICTIONARY:
		var task: String = String(Dictionary(action_items[0]).get("recommended_task", ""))
		if task.strip_edges() != "":
			return task
	return "TASK_769 - Station Reentry Performance Feel Pass"


static func _build_summary(status: String, failed_gate_ids: Array[String], active_issue_count: int) -> String:
	match status:
		"blocked_until_multiplayer_playable_candidate_findings":
			return "Acceptance blockiert: TASK_798-Findings fehlen, sind ungueltig oder nicht read-only."
		"needs_visible_multiplayer_playable_candidate_real_run":
			return "Playable-Candidate muss im Zwei-Fenster-Lauf noch sichtbar geprueft werden."
		"needs_multiplayer_playable_candidate_completion":
			return "Playable-Candidate-Review ist noch nicht vollstaendig."
		"needs_targeted_multiplayer_playable_candidate_polish":
			return "%d Playable-Candidate-Follow-up-Flag(s) muessen gezielt poliert werden." % active_issue_count
		"accepted_for_multiplayer_playable_candidate":
			return "Multiplayer-Playable-Candidate ist eng akzeptiert; naechster Griff ist ein Release-Candidate-Paket."
	return "Playable-Candidate-Acceptance-Gates offen: %s" % ", ".join(PackedStringArray(failed_gate_ids))


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
