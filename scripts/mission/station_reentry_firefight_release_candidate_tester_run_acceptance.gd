class_name StationReentryFirefightReleaseCandidateTesterRunAcceptance
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_release_candidate_tester_run_acceptance.v1"
const EXPECTED_TESTER_RUN_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_release_candidate_tester_run.v1"
const EXPECTED_TESTER_RUN_TASK_ID: String = "TASK_807"
const DEFAULT_TESTER_RUN_MANIFEST_PATH: String = "tmp/station_reentry_firefight_release_candidate_tester_run.json"
const DEFAULT_ACCEPTANCE_MANIFEST_PATH: String = "tmp/station_reentry_firefight_release_candidate_tester_run_acceptance.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/project_current_state_handbook_reentry_2026_07_01.html"


static func build_snapshot(tester_run_snapshot: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var findings: Array = []
	var source_valid: bool = _source_is_valid(tester_run_snapshot)
	var source_read_only: bool = _source_is_read_only(tester_run_snapshot)
	var source_status: String = String(tester_run_snapshot.get("status", ""))
	var source_missing_check_ids: Array = Array(tester_run_snapshot.get("missing_check_ids", [])).duplicate(true)
	var source_action_items: Array = Array(tester_run_snapshot.get("action_items", [])).duplicate(true)
	var source_active_issue_count: int = int(tester_run_snapshot.get("active_issue_count", 0))

	if not source_valid:
		findings.append(_finding("invalid_task_807_tester_run", "blocker", "TASK_807-Tester-Run fehlt oder hat Schema/Task-Konflikt.", "TASK_807 - Station Reentry Firefight Release Candidate Tester Run"))
	if source_valid and not source_read_only:
		findings.append(_finding("task_807_tester_run_not_read_only", "blocker", "TASK_807-Tester-Run verletzt read-only/UI-Truth-Grenzen.", "TASK_807 verifier rerun"))

	var gates: Array = [
		_gate("tester_run_ready", source_status == "ready_for_release_candidate_tester_run_acceptance", "TASK_807 meldet bereit fuer Tester-Run-Acceptance"),
		_gate("tester_run_done", bool(tester_run_snapshot.get("tester_run_done", false)), "Tester-Run bewusst abgeschlossen"),
		_gate("tester_run_reviewed", bool(tester_run_snapshot.get("tester_run_reviewed", false)), "Tester-Run geprueft"),
		_gate("fresh_release_exe_started", bool(tester_run_snapshot.get("fresh_release_exe_started", false)), "Frische Release-EXE wurde gestartet"),
		_gate("no_missing_checks", source_missing_check_ids.is_empty(), "Keine TASK_807-Pflichtchecks fehlen"),
		_gate("no_active_issues", source_active_issue_count == 0, "Keine aktiven Tester-Run-Issues"),
		_gate("release_context_present", _release_context_present(tester_run_snapshot), "Release-Ordner, EXE und PCK bleiben nachvollziehbar"),
		_gate("host_client_roles_distinct", _host_client_roles_distinct(tester_run_snapshot), "Host- und Client-Rollen bleiben unterscheidbar"),
		_gate("commands_present", _commands_present(tester_run_snapshot), "Release-, Export- und Host/Client-Kommandos sind vorhanden"),
		_gate("source_read_only", source_read_only, "Quelle bleibt read-only und mutiert keine Gameplay-Wahrheit"),
	]
	var failed_gate_ids: Array[String] = _failed_gate_ids(gates)
	var status: String = _build_status(source_valid, source_read_only, source_status, source_missing_check_ids, source_active_issue_count, failed_gate_ids)
	if status == "needs_tester_run_completion":
		findings.append(_finding("tester_run_missing_checks", "manual", "TASK_807-Pflichtchecks fehlen: %s" % ", ".join(PackedStringArray(source_missing_check_ids)), "TASK_807 - complete missing tester-run checks"))
	elif status == "needs_targeted_tester_run_polish":
		findings.append(_finding("tester_run_active_issues", "polish", "TASK_807 meldet aktive Tester-Run-Follow-ups.", _first_action_task(source_action_items)))

	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_808",
		"source_task_id": EXPECTED_TESTER_RUN_TASK_ID,
		"source_schema": String(tester_run_snapshot.get("schema", "")),
		"source_status": source_status,
		"source_tester_run_manifest_path": String(options.get("tester_run_manifest_path", DEFAULT_TESTER_RUN_MANIFEST_PATH)),
		"runtime_authority": "read-only acceptance over TASK_807 release candidate tester run",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"source_valid": source_valid,
		"source_read_only": source_read_only,
		"source_tester_run_done": bool(tester_run_snapshot.get("tester_run_done", false)),
		"source_tester_run_reviewed": bool(tester_run_snapshot.get("tester_run_reviewed", false)),
		"source_fresh_release_exe_started": bool(tester_run_snapshot.get("fresh_release_exe_started", false)),
		"source_missing_check_ids": source_missing_check_ids,
		"source_active_issue_count": source_active_issue_count,
		"source_action_items": source_action_items,
		"release_candidate_tester_run_ready": bool(tester_run_snapshot.get("release_candidate_tester_run_ready", false)),
		"release_dir": String(tester_run_snapshot.get("release_dir", "")),
		"exe_path": String(tester_run_snapshot.get("exe_path", "")),
		"pck_path": String(tester_run_snapshot.get("pck_path", "")),
		"scenario_path": String(tester_run_snapshot.get("scenario_path", "")),
		"workbench_path": String(tester_run_snapshot.get("workbench_path", "")),
		"workbench_file_uri": String(tester_run_snapshot.get("workbench_file_uri", "")),
		"expected_host_role": String(tester_run_snapshot.get("expected_host_role", "")),
		"expected_client_role": String(tester_run_snapshot.get("expected_client_role", "")),
		"expected_decision_line": String(tester_run_snapshot.get("expected_decision_line", "")),
		"expected_guard_line": String(tester_run_snapshot.get("expected_guard_line", "")),
		"commands": Dictionary(tester_run_snapshot.get("commands", {})).duplicate(true),
		"tester_notes": Dictionary(tester_run_snapshot.get("tester_notes", {})).duplicate(true),
		"open_risks": Array(tester_run_snapshot.get("open_risks", [])).duplicate(true),
		"checks": gates,
		"failed_check_ids": failed_gate_ids,
		"failed_gate_ids": failed_gate_ids,
		"findings": findings,
		"finding_count": findings.size(),
		"status": status,
		"accepted_for_release_candidate_tester_run": status == "accepted_for_release_candidate_tester_run",
		"summary": _build_summary(status, failed_gate_ids, source_active_issue_count),
		"recommended_next_task": _recommended_next_task(status, source_action_items),
		"report_path": String(options.get("report_path", DEFAULT_REPORT_PATH)),
		"manifest_path": String(options.get("manifest_path", DEFAULT_ACCEPTANCE_MANIFEST_PATH)),
	}


static func write_manifest(path: String = DEFAULT_ACCEPTANCE_MANIFEST_PATH, tester_run_snapshot: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var merged_options: Dictionary = options.duplicate(true)
	merged_options["manifest_path"] = path
	var snapshot: Dictionary = build_snapshot(tester_run_snapshot, merged_options)
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
			and String(source.get("schema", "")) == EXPECTED_TESTER_RUN_SCHEMA \
			and String(source.get("task_id", "")) == EXPECTED_TESTER_RUN_TASK_ID


static func _source_is_read_only(source: Dictionary) -> bool:
	return bool(source.get("read_only", false)) \
			and not bool(source.get("ui_sets_gameplay_truth", true)) \
			and not bool(source.get("creates_navigation", true)) \
			and not bool(source.get("creates_command", true)) \
			and not bool(source.get("creates_fire_event", true)) \
			and not bool(source.get("creates_damage_event", true)) \
			and not bool(source.get("sets_multiplayer_truth", true))


static func _release_context_present(source: Dictionary) -> bool:
	return String(source.get("release_dir", "")).strip_edges() != "" \
			and String(source.get("exe_path", "")).strip_edges().ends_with(".exe") \
			and String(source.get("pck_path", "")).strip_edges().ends_with(".pck")


static func _host_client_roles_distinct(source: Dictionary) -> bool:
	var host_role: String = String(source.get("expected_host_role", "")).strip_edges()
	var client_role: String = String(source.get("expected_client_role", "")).strip_edges()
	return host_role != "" and client_role != "" and host_role != client_role


static func _commands_present(source: Dictionary) -> bool:
	var commands: Dictionary = Dictionary(source.get("commands", {}))
	return String(commands.get("run_release_exe", "")).strip_edges() != "" \
			and String(commands.get("runtime_release_export", "")).strip_edges() != "" \
			and String(commands.get("launch_windows", "")).strip_edges() != "" \
			and String(commands.get("capture_windows", "")).strip_edges() != ""


static func _build_status(source_valid: bool, source_read_only: bool, source_status: String, missing_check_ids: Array, active_issue_count: int, failed_gate_ids: Array[String]) -> String:
	if not source_valid or not source_read_only:
		return "blocked_until_tester_run"
	if source_status == "needs_release_candidate_tester_run":
		return "needs_release_candidate_tester_run"
	if source_status == "needs_tester_run_completion" or not missing_check_ids.is_empty():
		return "needs_tester_run_completion"
	if source_status == "needs_targeted_tester_run_polish" or active_issue_count > 0:
		return "needs_targeted_tester_run_polish"
	if source_status == "ready_for_release_candidate_tester_run_acceptance" and failed_gate_ids.is_empty():
		return "accepted_for_release_candidate_tester_run"
	return "blocked_until_tester_run_acceptance_gates_green"


static func _recommended_next_task(status: String, action_items: Array) -> String:
	match status:
		"blocked_until_tester_run":
			return "TASK_807 - Station Reentry Firefight Release Candidate Tester Run"
		"needs_release_candidate_tester_run":
			return "TASK_807 - run release candidate tester run"
		"needs_tester_run_completion":
			return "TASK_807 - complete missing tester-run checks"
		"needs_targeted_tester_run_polish":
			return _first_action_task(action_items)
		"accepted_for_release_candidate_tester_run":
			return "TASK_809 - Station Reentry Release Candidate Playability Polish Backlog"
	return "TASK_808 - fix Station Reentry Firefight Release Candidate Tester Run Acceptance gates"


static func _first_action_task(action_items: Array) -> String:
	if not action_items.is_empty() and typeof(action_items[0]) == TYPE_DICTIONARY:
		var task: String = String(Dictionary(action_items[0]).get("recommended_task", ""))
		if task.strip_edges() != "":
			return task
	return "TASK_769 - Station Reentry Performance Feel Pass"


static func _build_summary(status: String, failed_gate_ids: Array[String], active_issue_count: int) -> String:
	match status:
		"blocked_until_tester_run":
			return "Tester-Run-Acceptance blockiert: TASK_807 fehlt, ist ungueltig oder nicht read-only."
		"needs_release_candidate_tester_run":
			return "Release-Candidate-Tester-Run muss sichtbar aus dem Handoff laufen."
		"needs_tester_run_completion":
			return "Release-Candidate-Tester-Run ist noch nicht vollstaendig."
		"needs_targeted_tester_run_polish":
			return "%d Tester-Run-Follow-up-Flag(s) muessen gezielt poliert werden." % active_issue_count
		"accepted_for_release_candidate_tester_run":
			return "Tester-Run ist eng akzeptiert; naechster Griff ist spielbarer Polish/Backlog aus echtem Griff."
	return "Tester-Run-Acceptance-Gates offen: %s" % ", ".join(PackedStringArray(failed_gate_ids))


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
