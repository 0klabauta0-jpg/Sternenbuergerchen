class_name StationReentryFirefightReleaseCandidateShipReadiness
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_release_candidate_ship_readiness.v1"
const EXPECTED_ACCEPTANCE_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_release_candidate_acceptance.v1"
const EXPECTED_ACCEPTANCE_TASK_ID: String = "TASK_802"
const DEFAULT_ACCEPTANCE_MANIFEST_PATH: String = "tmp/station_reentry_firefight_release_candidate_acceptance.json"
const DEFAULT_SHIP_READINESS_MANIFEST_PATH: String = "tmp/station_reentry_firefight_release_candidate_ship_readiness.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/project_current_state_handbook_reentry_2026_07_01.html"

const REQUIRED_SHIP_READINESS_ITEMS: Array[Dictionary] = [
	{"id": "release_exe_present", "label": "Release-EXE liegt im Spieleordner"},
	{"id": "release_pck_present", "label": "Release-PCK liegt neben der EXE"},
	{"id": "runtime_dlls_present", "label": "Native Runtime-DLLs liegen neben der EXE"},
	{"id": "launch_command_available", "label": "Startkommando fuer die Release-EXE ist vorhanden"},
	{"id": "export_command_available", "label": "Export-/Refresh-Kommando ist vorhanden"},
	{"id": "workbench_report_available", "label": "HTML-Workbench ist als Review-Handbuch erreichbar"},
	{"id": "playtest_findings_manifest_available", "label": "TASK_801-Findings-Manifest ist referenziert"},
	{"id": "acceptance_manifest_available", "label": "TASK_802-Acceptance-Manifest ist referenziert"},
	{"id": "known_open_risks_listed", "label": "Bekannte Restrisiken sind im Snapshot sichtbar"},
	{"id": "next_operator_instruction_present", "label": "Naechster sichtbarer Bedien-Smoke ist benannt"},
]

const DEFAULT_OPEN_RISKS: Array[String] = [
	"Kein automatischer Screenshot-Entscheid.",
	"Kein Netzwerk-Lasttest; Host/Client bleibt sichtbarer Smoke.",
	"Build-Ordner koennen lokal stale werden, wenn eine alte Verknuepfung gestartet wird.",
]


static func build_snapshot(acceptance_snapshot: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var source_valid: bool = _source_is_valid(acceptance_snapshot)
	var source_read_only: bool = _source_is_read_only(acceptance_snapshot)
	var accepted: bool = bool(acceptance_snapshot.get("accepted_for_release_candidate", false))
	var commands: Dictionary = _commands(acceptance_snapshot, options)
	var open_risks: Array = Array(options.get("open_risks", DEFAULT_OPEN_RISKS)).duplicate(true)
	var readiness_items: Array = _build_readiness_items(acceptance_snapshot, options, commands, open_risks)
	var missing_item_ids: Array[String] = _missing_item_ids(readiness_items)
	var findings: Array = _build_findings(source_valid, source_read_only, accepted, missing_item_ids, acceptance_snapshot)
	var status: String = _build_status(source_valid, source_read_only, accepted, missing_item_ids)

	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_803",
		"source_task_id": EXPECTED_ACCEPTANCE_TASK_ID,
		"source_schema": String(acceptance_snapshot.get("schema", "")),
		"source_status": String(acceptance_snapshot.get("status", "")),
		"source_acceptance_manifest_path": String(options.get("acceptance_manifest_path", DEFAULT_ACCEPTANCE_MANIFEST_PATH)),
		"runtime_authority": "read-only ship readiness over TASK_802 release candidate acceptance",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"acceptance_valid": source_valid,
		"acceptance_read_only": source_read_only,
		"accepted_for_release_candidate": accepted,
		"release_dir": String(options.get("release_dir", acceptance_snapshot.get("release_dir", ""))),
		"exe_path": String(options.get("exe_path", acceptance_snapshot.get("exe_path", ""))),
		"pck_path": String(options.get("pck_path", acceptance_snapshot.get("pck_path", ""))),
		"scenario_path": String(acceptance_snapshot.get("scenario_path", "")),
		"workbench_path": String(acceptance_snapshot.get("workbench_path", "")),
		"workbench_file_uri": String(acceptance_snapshot.get("workbench_file_uri", "")),
		"expected_host_role": String(acceptance_snapshot.get("expected_host_role", "")),
		"expected_client_role": String(acceptance_snapshot.get("expected_client_role", "")),
		"expected_decision_line": String(acceptance_snapshot.get("expected_decision_line", "")),
		"expected_guard_line": String(acceptance_snapshot.get("expected_guard_line", "")),
		"commands": commands,
		"required_ship_readiness_items": REQUIRED_SHIP_READINESS_ITEMS.duplicate(true),
		"ship_readiness_items": readiness_items,
		"ship_readiness_item_count": readiness_items.size(),
		"completed_ship_readiness_item_count": _completed_item_count(readiness_items),
		"missing_item_ids": missing_item_ids,
		"open_risks": open_risks,
		"known_open_risk_count": open_risks.size(),
		"operator_instruction": String(options.get("operator_instruction", "Start the fresh Release EXE, click Einzelspieler, then run the visible Host/Client ship smoke.")),
		"findings": findings,
		"finding_count": findings.size(),
		"status": status,
		"ship_readiness_ready": status == "ready_for_ship_readiness_review",
		"summary": _summary(status, missing_item_ids),
		"recommended_next_task": _recommended_next_task(status, acceptance_snapshot),
		"report_path": String(options.get("report_path", DEFAULT_REPORT_PATH)),
		"manifest_path": String(options.get("manifest_path", DEFAULT_SHIP_READINESS_MANIFEST_PATH)),
	}


static func _source_is_valid(source: Dictionary) -> bool:
	return not source.is_empty() \
			and String(source.get("schema", "")) == EXPECTED_ACCEPTANCE_SCHEMA \
			and String(source.get("task_id", "")) == EXPECTED_ACCEPTANCE_TASK_ID


static func _source_is_read_only(source: Dictionary) -> bool:
	return bool(source.get("read_only", false)) \
			and not bool(source.get("ui_sets_gameplay_truth", true)) \
			and not bool(source.get("creates_navigation", true)) \
			and not bool(source.get("creates_command", true)) \
			and not bool(source.get("creates_fire_event", true)) \
			and not bool(source.get("creates_damage_event", true))


static func _commands(source: Dictionary, options: Dictionary) -> Dictionary:
	var source_commands: Dictionary = Dictionary(source.get("commands", {}))
	var exe_path: String = String(options.get("exe_path", source.get("exe_path", "")))
	return {
		"run_release_exe": String(options.get("run_release_exe", source_commands.get("run_release_exe", "\"%s\"" % exe_path))),
		"runtime_release_export": String(source_commands.get("runtime_release_export", "powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1")),
		"launch_windows": String(source_commands.get("launch_windows", "powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1 -Launch")),
		"capture_windows": String(source_commands.get("capture_windows", "powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1 -Launch -CloseAfterCapture -WaitSeconds 14")),
		"open_workbench": String(source.get("workbench_file_uri", "")),
		"rerun_ship_readiness_verifier": "godot_console.exe --headless --path . --script scripts/tests/task_803_station_reentry_firefight_release_candidate_ship_readiness.gd",
		"rerun_acceptance_verifier": "godot_console.exe --headless --path . --script scripts/tests/task_802_station_reentry_firefight_release_candidate_acceptance.gd",
	}


static func _build_readiness_items(source: Dictionary, options: Dictionary, commands: Dictionary, open_risks: Array) -> Array:
	var explicit_status: Dictionary = Dictionary(options.get("item_statuses", {}))
	var item_states: Dictionary = {
		"release_exe_present": String(options.get("exe_path", source.get("exe_path", ""))).strip_edges().ends_with(".exe"),
		"release_pck_present": String(options.get("pck_path", source.get("pck_path", ""))).strip_edges().ends_with(".pck"),
		"runtime_dlls_present": false,
		"launch_command_available": String(commands.get("run_release_exe", "")).strip_edges() != "",
		"export_command_available": String(commands.get("runtime_release_export", "")).strip_edges() != "",
		"workbench_report_available": String(source.get("workbench_path", "")).strip_edges() != "" or String(source.get("workbench_file_uri", "")).strip_edges() != "",
		"playtest_findings_manifest_available": String(source.get("source_findings_manifest_path", "")).strip_edges() != "",
		"acceptance_manifest_available": String(options.get("acceptance_manifest_path", DEFAULT_ACCEPTANCE_MANIFEST_PATH)).strip_edges() != "",
		"known_open_risks_listed": not open_risks.is_empty(),
		"next_operator_instruction_present": String(options.get("operator_instruction", "Start the fresh Release EXE")).strip_edges() != "",
	}
	for key in explicit_status.keys():
		item_states[String(key)] = bool(explicit_status.get(key))

	var result: Array = []
	for item_variant in REQUIRED_SHIP_READINESS_ITEMS:
		var item: Dictionary = Dictionary(item_variant).duplicate(true)
		var item_id: String = String(item.get("id", ""))
		item["complete"] = bool(item_states.get(item_id, false))
		item["read_only"] = true
		item["ui_sets_gameplay_truth"] = false
		result.append(item)
	return result


static func _missing_item_ids(items: Array) -> Array[String]:
	var missing: Array[String] = []
	for item_variant in items:
		if typeof(item_variant) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = Dictionary(item_variant)
		if not bool(item.get("complete", false)):
			missing.append(String(item.get("id", "")))
	return missing


static func _completed_item_count(items: Array) -> int:
	return items.size() - _missing_item_ids(items).size()


static func _build_findings(source_valid: bool, source_read_only: bool, accepted: bool, missing_item_ids: Array[String], source: Dictionary) -> Array:
	var findings: Array = []
	if not source_valid:
		findings.append(_finding("invalid_task_802_acceptance", "blocker", "TASK_802-Acceptance fehlt oder hat Schema/Task-Konflikt.", "TASK_802 - Station Reentry Firefight Release Candidate Acceptance"))
	if source_valid and not source_read_only:
		findings.append(_finding("task_802_acceptance_not_read_only", "blocker", "TASK_802-Acceptance verletzt read-only/UI-Truth-Grenzen.", "TASK_802 rerun"))
	if source_valid and source_read_only and not accepted:
		findings.append(_finding("release_candidate_not_accepted", "blocker", "TASK_802 hat den Release-Candidate nicht akzeptiert.", String(source.get("recommended_next_task", "TASK_802 rerun"))))
	if not missing_item_ids.is_empty():
		findings.append(_finding("ship_readiness_items_missing", "manual", "Ship-Readiness-Items fehlen: %s" % ", ".join(PackedStringArray(missing_item_ids)), "TASK_803 - complete release candidate ship readiness items"))
	return findings


static func _build_status(source_valid: bool, source_read_only: bool, accepted: bool, missing_item_ids: Array[String]) -> String:
	if not source_valid or not source_read_only:
		return "blocked_until_release_candidate_acceptance"
	if not accepted:
		return "blocked_until_release_candidate_accepted"
	if not missing_item_ids.is_empty():
		return "needs_ship_readiness_completion"
	return "ready_for_ship_readiness_review"


static func _recommended_next_task(status: String, source: Dictionary) -> String:
	match status:
		"blocked_until_release_candidate_acceptance":
			return "TASK_802 - Station Reentry Firefight Release Candidate Acceptance"
		"blocked_until_release_candidate_accepted":
			return String(source.get("recommended_next_task", "TASK_802 - accept Station Reentry Firefight Release Candidate"))
		"needs_ship_readiness_completion":
			return "TASK_803 - complete release candidate ship readiness items"
		"ready_for_ship_readiness_review":
			return "TASK_804 - Station Reentry Firefight Release Candidate Visible Ship Smoke"
	return "TASK_803 - repair Station Reentry Firefight Release Candidate Ship Readiness"


static func _summary(status: String, missing_item_ids: Array[String]) -> String:
	match status:
		"blocked_until_release_candidate_acceptance":
			return "Ship-Readiness blockiert: TASK_802-Acceptance fehlt oder ist nicht read-only."
		"blocked_until_release_candidate_accepted":
			return "Ship-Readiness blockiert: Release-Candidate ist noch nicht akzeptiert."
		"needs_ship_readiness_completion":
			return "Ship-Readiness braucht noch Items: %s." % ", ".join(PackedStringArray(missing_item_ids))
		"ready_for_ship_readiness_review":
			return "Ship-Readiness ist bereit; naechster Schritt ist der sichtbare EXE-/Host-Client-Smoke."
	return "Ship-Readiness ist unvollstaendig."


static func _finding(id: String, severity: String, message: String, suggested_next: String) -> Dictionary:
	return {
		"id": id,
		"severity": severity,
		"message": message,
		"suggested_next": suggested_next,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}
