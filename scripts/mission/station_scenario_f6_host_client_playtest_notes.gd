class_name StationScenarioF6HostClientPlaytestNotes
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_scenario_f6_host_client_playtest_notes.v1"
const EXPECTED_DRILL_SCHEMA: String = "sternenbuergerchen.station_route_one_screen_scenario_drill.v1"
const DEFAULT_DRILL_MANIFEST_PATH: String = "tmp/station_route_one_screen_multiplayer_drill.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html"
const DEFAULT_MANIFEST_PATH: String = "tmp/station_scenario_f6_host_client_playtest_notes.json"

const REQUIRED_CHECK_IDS: Array[String] = [
	"playtest_done",
	"real_f6_window_reviewed",
	"host_client_two_window_reviewed",
	"aa_door_com_cargo_route_readable",
	"door_computer_cargo_cues_obvious",
	"fireteam_orders_feel_fast",
	"performance_feels_fast",
	"no_hud_overlap_blocks_map",
	"wrong_team_or_bravo_context_clear",
]

const ISSUE_FLAG_IDS: Array[String] = [
	"needs_route_readability_polish",
	"needs_hud_overlap_polish",
	"needs_performance_pass",
	"needs_host_client_sync_fix",
	"needs_command_feedback_polish",
	"needs_old_harness_modernization",
]


static func build_snapshot(drill_manifest: Dictionary = {}, existing_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var findings: Array = []
	_add_drill_findings(findings, drill_manifest)
	var required_checks: Array = _build_required_checks(existing_notes)
	var issue_flags: Array = _build_issue_flags(existing_notes)
	var completed_check_count: int = _count_completed_checks(required_checks)
	var active_issue_count: int = _count_active_flags(issue_flags)
	var playtest_done: bool = _read_bool(existing_notes, "station_scenario_playtest.playtest_done")
	var rating: String = _read_choice(existing_notes, "station_scenario_playtest.rating", "open")
	var blocker_count: int = _count_findings_by_severity(findings, "blocker")
	var status: String = _build_status(blocker_count, playtest_done, active_issue_count, rating)
	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_727",
		"runtime_authority": "manual playtest notes over TASK_726 station scenario drill",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"manual_review_required": true,
		"manual_review_done": playtest_done,
		"playtest_done": playtest_done,
		"status": status,
		"rating": rating,
		"source_drill_schema": String(drill_manifest.get("schema", "")),
		"source_drill_status": String(drill_manifest.get("status", "")),
		"source_drill_task_id": String(drill_manifest.get("task_id", "")),
		"source_drill_scenario_path": String(drill_manifest.get("scenario_path", "data/mission_scenarios/station_route_one_screen_multiplayer_drill.json")),
		"source_drill_manifest_path": String(options.get("drill_manifest_path", DEFAULT_DRILL_MANIFEST_PATH)),
		"report_path": String(options.get("report_path", DEFAULT_REPORT_PATH)),
		"manifest_path": String(options.get("manifest_path", DEFAULT_MANIFEST_PATH)),
		"required_checks": required_checks,
		"required_check_count": required_checks.size(),
		"completed_check_count": completed_check_count,
		"issue_flags": issue_flags,
		"active_issue_count": active_issue_count,
		"findings": findings,
		"blocking_issue_count": blocker_count,
		"summary": _build_summary(status, completed_check_count, required_checks.size(), active_issue_count),
		"recommended_next_task": _recommended_next_task(status),
	}


static func _add_drill_findings(findings: Array, drill_manifest: Dictionary) -> void:
	if drill_manifest.is_empty():
		findings.append(_finding("missing_task_726_manifest", "blocker", "TASK_726-Drillmanifest fehlt.", "TASK_726 verifier rerun"))
		return
	if String(drill_manifest.get("schema", "")) != EXPECTED_DRILL_SCHEMA:
		findings.append(_finding("unexpected_task_726_schema", "blocker", "TASK_726-Manifest hat ein unerwartetes Schema.", "TASK_726 verifier rerun"))
	if String(drill_manifest.get("task_id", "")) != "TASK_726":
		findings.append(_finding("unexpected_task_id", "blocker", "Drillmanifest gehoert nicht zu TASK_726.", "TASK_726 verifier rerun"))
	if String(drill_manifest.get("status", "")) != "ready_for_f6_host_client_playtest":
		findings.append(_finding("drill_not_ready_for_visible_playtest", "blocker", "Station-Szenario ist nicht bereit fuer sichtbaren F6/Host-Client-Playtest.", "TASK_726 repair"))
	if not bool(drill_manifest.get("read_only", false)) or bool(drill_manifest.get("ui_sets_gameplay_truth", true)):
		findings.append(_finding("drill_manifest_not_readonly", "blocker", "TASK_726-Manifest verletzt read-only/UI-Truth-Regel.", "TASK_726 verifier rerun"))


static func _build_required_checks(existing_notes: Dictionary) -> Array:
	return [
		_check("playtest_done", "Playtest bewusst abgeschlossen und exportiert", existing_notes),
		_check("real_f6_window_reviewed", "Echtes F6-Fenster gestartet und angesehen", existing_notes),
		_check("host_client_two_window_reviewed", "Host/Client-Zwei-Fenster-Lauf angesehen", existing_notes),
		_check("aa_door_com_cargo_route_readable", "AA -> Door -> Computer -> Cargo ist ohne Debugwissen lesbar", existing_notes),
		_check("door_computer_cargo_cues_obvious", "Door-, Computer- und Cargo-Cues sind offensichtlich genug", existing_notes),
		_check("fireteam_orders_feel_fast", "Fireteam-Orders fuehlen sich zuegig an", existing_notes),
		_check("performance_feels_fast", "Fensterlauf wirkt performant genug", existing_notes),
		_check("no_hud_overlap_blocks_map", "HUD verdeckt keine wichtige Kartenentscheidung", existing_notes),
		_check("wrong_team_or_bravo_context_clear", "Wrong-Team-/Bravo-Kontext ist verstaendlich", existing_notes),
	]


static func _build_issue_flags(existing_notes: Dictionary) -> Array:
	return [
		_flag("needs_route_readability_polish", "Route/Objective-Lesbarkeit braucht Polish", existing_notes),
		_flag("needs_hud_overlap_polish", "HUD/Panel-Ueberdeckung braucht Polish", existing_notes),
		_flag("needs_performance_pass", "Performance/Gefuehl braucht eigenen Pass", existing_notes),
		_flag("needs_host_client_sync_fix", "Host/Client-Sync oder Authority-Cues brauchen Fix", existing_notes),
		_flag("needs_command_feedback_polish", "Command-/GO-/Door-Feedback braucht Polish", existing_notes),
		_flag("needs_old_harness_modernization", "Alte Pre-Boot-Harnesses sollen modernisiert werden", existing_notes),
	]


static func _check(id: String, label: String, existing_notes: Dictionary) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"checked": _read_bool(existing_notes, "station_scenario_playtest.%s" % id),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _flag(id: String, label: String, existing_notes: Dictionary) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"active": _read_bool(existing_notes, "station_scenario_playtest.issues.%s" % id),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _read_bool(notes: Dictionary, dotted_key: String) -> bool:
	var direct_value: Variant = _get_path(notes, dotted_key)
	if typeof(direct_value) == TYPE_BOOL:
		return bool(direct_value)
	var controls: Dictionary = Dictionary(notes.get("controls", {}))
	var control_value: Variant = _get_path(controls, dotted_key)
	return bool(control_value) if typeof(control_value) == TYPE_BOOL else false


static func _read_choice(notes: Dictionary, dotted_key: String, fallback: String) -> String:
	var active_choices: Dictionary = Dictionary(notes.get("active_choices", {}))
	var choice_value: Variant = _get_path(active_choices, dotted_key)
	if typeof(choice_value) == TYPE_STRING and not String(choice_value).is_empty():
		return String(choice_value)
	var direct_value: Variant = _get_path(notes, dotted_key)
	if typeof(direct_value) == TYPE_STRING and not String(direct_value).is_empty():
		return String(direct_value)
	return fallback


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


static func _build_status(blocker_count: int, playtest_done: bool, active_issue_count: int, rating: String) -> String:
	if blocker_count > 0:
		return "blocked"
	if not playtest_done:
		return "needs_visible_playtest"
	if active_issue_count > 0 or rating == "needs_polish" or rating == "blocked":
		return "needs_followup_polish"
	return "ready_for_findings"


static func _build_summary(status: String, completed_check_count: int, required_check_count: int, active_issue_count: int) -> String:
	if status == "blocked":
		return "Station-Szenario-Playtestnotizen blockiert: TASK_726-Drillmanifest fehlt oder ist ungueltig"
	if status == "needs_visible_playtest":
		return "Sichtbarer F6/Host-Client-Playtest offen, %d/%d Checks gesetzt" % [completed_check_count, required_check_count]
	if status == "needs_followup_polish":
		return "Playtestnotizen enthalten %d Follow-up-Flag(s)" % active_issue_count
	return "Playtestnotizen sind bereit fuer Findings-Verdichtung"


static func _recommended_next_task(status: String) -> String:
	if status == "blocked":
		return "TASK_726 - rerun Station Scenario runtime drill"
	if status == "needs_visible_playtest":
		return "TASK_727 - run visible F6/Host Client station playtest"
	return "TASK_728 - Station Scenario Playtest Findings"


static func _finding(id: String, severity: String, message: String, suggested_next: String) -> Dictionary:
	return {
		"id": id,
		"severity": severity,
		"message": message,
		"suggested_next": suggested_next,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _count_completed_checks(required_checks: Array) -> int:
	var count: int = 0
	for check_variant in required_checks:
		if typeof(check_variant) == TYPE_DICTIONARY and bool(Dictionary(check_variant).get("checked", false)):
			count += 1
	return count


static func _count_active_flags(issue_flags: Array) -> int:
	var count: int = 0
	for flag_variant in issue_flags:
		if typeof(flag_variant) == TYPE_DICTIONARY and bool(Dictionary(flag_variant).get("active", false)):
			count += 1
	return count


static func _count_findings_by_severity(findings: Array, severity: String) -> int:
	var count: int = 0
	for finding_variant in findings:
		if typeof(finding_variant) == TYPE_DICTIONARY and String(Dictionary(finding_variant).get("severity", "")) == severity:
			count += 1
	return count
