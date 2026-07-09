class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioVisibleShipSmoke
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke.v1"
const TASK_ID: String = "TASK_1027"
const SOURCE_TASK_ID: String = "TASK_1026"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_ship_readiness_review.v1"
const REVIEW_TASK: String = "TASK_1027 - Release First Decision Loop Two Player Loop Scenario Visible Ship Smoke"
const POLISH_TASK: String = "TASK_1027 - Release First Decision Loop Two Player Loop Scenario Visible Ship Smoke Polish"
const NEXT_TASK: String = "TASK_1028 - Release First Decision Loop Two Player Loop Scenario Delivery Review"

const REQUIRED_VISIBLE_SHIP_SMOKE_CHECKS: Array[String] = [
	"fresh_release_folder_used",
	"release_exe_started",
	"singleplayer_clicked",
	"fob_visible",
	"next_visible",
	"go_visible",
	"feedback_visible",
	"no_input_dead_end",
	"performance_feels_responsive",
	"no_stale_taskbar_link",
	"smoke_notes_exported",
]

const ISSUE_FLAG_IDS: Array[String] = [
	"stale_export_or_link",
	"singleplayer_homebase_blocked",
	"fob_not_visible",
	"next_go_feedback_missing",
	"input_dead_end",
	"performance_regression",
	"hud_gameplay_truth_risk",
	"multiplayer_boundary_broken",
	"runtime_error_on_start",
]


static func build_snapshot(source_ship_readiness: Dictionary, smoke_notes: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_source_blockers(source_ship_readiness)
	var notes_available: bool = bool(smoke_notes.get("notes_available", false)) or not smoke_notes.is_empty()
	var manual_done: bool = bool(smoke_notes.get("manual_smoke_done", false))
	var completed_checks: Array = Array(smoke_notes.get("completed_visible_ship_smoke_checks", [])).duplicate(true)
	var missing_checks: Array = _missing_checks(completed_checks)
	var active_issue_flags: Array = _active_issue_flags(smoke_notes)
	var issues: Array = []
	var status: String = "blocked_until_ship_readiness"
	var gate: String = "blocked_until_ship_readiness"
	var passed: bool = false
	var ready_for_delivery_review: bool = false
	var recommended_next_task: String = REVIEW_TASK
	var recommended_direction: String = "fix_ship_readiness_source"

	if blockers.is_empty():
		if not notes_available:
			status = "needs_visible_ship_smoke"
			gate = "needs_visible_ship_smoke"
			issues.append(_issue("visible_ship_smoke_notes_missing", "Sichtbare Smoke-Notizen fuer TASK_1027 fehlen."))
			recommended_direction = "run_visible_ship_smoke"
		else:
			issues = _build_smoke_issues(manual_done, missing_checks, active_issue_flags, smoke_notes)
			if not active_issue_flags.is_empty():
				status = "visible_ship_smoke_regression_found"
				gate = "visible_ship_smoke_regression_found"
				recommended_next_task = POLISH_TASK
				recommended_direction = "polish_visible_ship_smoke_regressions"
			elif not issues.is_empty():
				status = "needs_visible_ship_smoke_completion"
				gate = "needs_visible_ship_smoke_completion"
				recommended_next_task = REVIEW_TASK
				recommended_direction = "complete_visible_ship_smoke_checks"
			else:
				status = "visible_ship_smoke_passed"
				gate = "visible_ship_smoke_passed"
				passed = true
				ready_for_delivery_review = true
				recommended_next_task = NEXT_TASK
				recommended_direction = "cut_delivery_review"

	var all_issues: Array = blockers + issues
	var source_items: Dictionary = Dictionary(source_ship_readiness.get("ship_readiness_items", {}))
	var release_build_path: String = _item_string(source_items, "release_build_path", String(source_ship_readiness.get("source_release_build_path", "")))
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_ship_readiness.get("schema", "")),
		"source_status": String(source_ship_readiness.get("status", "")),
		"source_gate": String(source_ship_readiness.get("gate", "")),
		"source_ship_readiness_line": String(source_ship_readiness.get("ship_readiness_line", "")),
		"source_ship_readiness_ready": bool(source_ship_readiness.get("ship_readiness_ready", false)),
		"source_ready_for_visible_ship_smoke": bool(source_ship_readiness.get("ready_for_visible_ship_smoke", false)),
		"release_build_path": release_build_path,
		"pck_path": _item_string(source_items, "pck_path"),
		"scenario_id": _item_string(source_items, "scenario_id"),
		"tester_instructions": _item_string(source_items, "tester_instructions"),
		"operator_goal": _item_string(source_items, "operator_goal"),
		"known_risks": _item_array(source_items, "known_risks"),
		"notes_available": notes_available,
		"manual_smoke_required": true,
		"manual_smoke_done": manual_done,
		"visible_smoke_notes": String(smoke_notes.get("visible_smoke_notes", "")),
		"required_visible_ship_smoke_checks": REQUIRED_VISIBLE_SHIP_SMOKE_CHECKS.duplicate(),
		"completed_visible_ship_smoke_checks": completed_checks,
		"missing_visible_ship_smoke_checks": missing_checks,
		"missing_visible_ship_smoke_check_count": missing_checks.size(),
		"issue_flags": active_issue_flags,
		"active_issue_count": active_issue_flags.size(),
		"visible_ship_smoke_line": _build_visible_smoke_line(status, source_ship_readiness, smoke_notes),
		"visible_ship_smoke_passed": passed,
		"ready_for_delivery_review": ready_for_delivery_review,
		"status": status,
		"gate": gate,
		"issues": issues,
		"issue_count": issues.size(),
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(all_issues[0]).get("id", "")) if not all_issues.is_empty() else "",
		"recommended_next_task": recommended_next_task,
		"recommended_direction": recommended_direction,
		"read_only": true,
		"read_only_capture": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
	}


static func _build_source_blockers(source: Dictionary) -> Array:
	var blockers: Array = []
	if String(source.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_1026-Source-Schema fehlt oder passt nicht."))
	if String(source.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1026."))
	if String(source.get("status", "")) != "ship_readiness_ready":
		blockers.append(_issue("source_ship_readiness_not_ready", "TASK_1026-Source ist nicht ship_readiness_ready."))
	if not bool(source.get("ship_readiness_ready", false)):
		blockers.append(_issue("source_ship_readiness_flag_missing", "TASK_1026-Ship-Readiness-Flag fehlt."))
	if not bool(source.get("ready_for_visible_ship_smoke", false)):
		blockers.append(_issue("source_not_ready_for_visible_smoke", "TASK_1026 ist nicht fuer den sichtbaren Smoke freigegeben."))
	var line: String = String(source.get("ship_readiness_line", "")).strip_edges()
	if line.is_empty():
		blockers.append(_issue("source_ship_readiness_line_missing", "TASK_1026-Ship-Readiness-Line fehlt."))
	elif not (line.contains("FOB") and line.contains("NEXT") and line.contains("GO") and line.contains("FEEDBACK")):
		blockers.append(_issue("source_ship_readiness_line_incomplete", "TASK_1026-Line nennt FOB/NEXT/GO/FEEDBACK nicht gemeinsam."))
	if not _snapshot_is_read_only(source):
		blockers.append(_issue("source_not_read_only", "TASK_1026-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_smoke_issues(manual_done: bool, missing_checks: Array, issue_flags: Array, smoke_notes: Dictionary) -> Array:
	var issues: Array = []
	var ids := {}
	if not manual_done:
		_append_issue_once(issues, ids, "manual_visible_ship_smoke_open", "Sichtbarer Smoke ist noch nicht manuell abgeschlossen.")
	if not missing_checks.is_empty():
		_append_issue_once(issues, ids, "visible_ship_smoke_checks_missing", "Sichtbare Smoke-Checks fehlen: %s." % ", ".join(PackedStringArray(missing_checks)))
	for issue_id in issue_flags:
		_append_issue_once(issues, ids, "visible_smoke_issue_%s" % String(issue_id), _issue_text(String(issue_id)))
	if bool(smoke_notes.get("ui_sets_gameplay_truth", false)):
		_append_issue_once(issues, ids, "notes_ui_gameplay_truth_risk", "Smoke-Notizen duerfen keine UI-Gameplay-Wahrheit setzen.")
	if bool(smoke_notes.get("creates_command", false)):
		_append_issue_once(issues, ids, "notes_create_command", "Smoke-Notizen duerfen keinen Command erzeugen.")
	if bool(smoke_notes.get("creates_movement", false)):
		_append_issue_once(issues, ids, "notes_create_movement", "Smoke-Notizen duerfen keine Bewegung erzeugen.")
	if bool(smoke_notes.get("sets_multiplayer_truth", false)):
		_append_issue_once(issues, ids, "notes_set_multiplayer_truth", "Smoke-Notizen duerfen keine Multiplayer-Wahrheit setzen.")
	return issues


static func _active_issue_flags(smoke_notes: Dictionary) -> Array:
	var active: Array = []
	for issue_id in Array(smoke_notes.get("issue_flags", [])):
		var normalized: String = String(issue_id)
		if ISSUE_FLAG_IDS.has(normalized):
			active.append(normalized)
	return active


static func _missing_checks(completed_checks: Array) -> Array:
	var completed := {}
	for check_variant in completed_checks:
		completed[String(check_variant)] = true
	var missing: Array = []
	for check_id in REQUIRED_VISIBLE_SHIP_SMOKE_CHECKS:
		if not completed.has(check_id):
			missing.append(check_id)
	return missing


static func _append_issue_once(issues: Array, ids: Dictionary, issue_id: String, text: String) -> void:
	if ids.has(issue_id):
		return
	ids[issue_id] = true
	issues.append(_issue(issue_id, text))


static func _item_string(items: Dictionary, key: String, fallback: String = "") -> String:
	var value: Variant = items.get(key)
	if value == null:
		return fallback
	return String(value)


static func _item_array(items: Dictionary, key: String) -> Array:
	var value: Variant = items.get(key)
	if typeof(value) == TYPE_ARRAY:
		return Array(value).duplicate(true)
	return []


static func _build_visible_smoke_line(status: String, source: Dictionary, smoke_notes: Dictionary) -> String:
	if status == "visible_ship_smoke_passed":
		var note: String = String(smoke_notes.get("visible_smoke_notes", "FOB/NEXT/GO/FEEDBACK sichtbar gespielt.")).strip_edges()
		return "VISIBLE SHIP EXE: FOB | NEXT | GO | FEEDBACK | %s" % _compact_text(note, 104)
	if status == "needs_visible_ship_smoke":
		return "VISIBLE SHIP OFFEN: EXE | FOB | NEXT | GO | FEEDBACK muessen sichtbar geprueft werden."
	var source_line: String = String(source.get("ship_readiness_line", "")).strip_edges()
	if source_line.is_empty():
		source_line = "EXE, FOB, NEXT, GO und FEEDBACK brauchen Sichtsmoke."
	return "VISIBLE SHIP CHECK: EXE | FOB | NEXT | GO | FEEDBACK | %s" % _compact_text(source_line, 104)


static func _compact_text(text: String, max_length: int) -> String:
	var normalized: String = text.strip_edges()
	if normalized.length() <= max_length:
		return normalized
	return normalized.substr(0, maxi(max_length - 3, 0)).strip_edges() + "..."


static func _issue_text(issue_id: String) -> String:
	match issue_id:
		"stale_export_or_link":
			return "Alter Export oder alte Verknuepfung wurde benutzt."
		"singleplayer_homebase_blocked":
			return "Einzelspieler/Homebase ist im Release blockiert."
		"fob_not_visible":
			return "FOB ist im sichtbaren Smoke nicht lesbar."
		"next_go_feedback_missing":
			return "NEXT/GO/FEEDBACK ist im sichtbaren Smoke nicht gemeinsam lesbar."
		"input_dead_end":
			return "Der sichtbare Smoke endet in einer Input-Sackgasse."
		"performance_regression":
			return "Der sichtbare Smoke fuehlt sich nicht reaktionsschnell an."
		"hud_gameplay_truth_risk":
			return "HUD-Gameplay-Wahrheit ist im Smoke nicht ausgeschlossen."
		"multiplayer_boundary_broken":
			return "Multiplayer-Grenze ist im Smoke nicht erhalten."
		"runtime_error_on_start":
			return "Runtime-Start erzeugt einen Fehler."
	return issue_id


static func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", false)) \
		and not bool(snapshot.get("creates_command", false)) \
		and not bool(snapshot.get("creates_movement", false)) \
		and not bool(snapshot.get("creates_fire_event", false)) \
		and not bool(snapshot.get("creates_damage_event", false)) \
		and not bool(snapshot.get("sets_multiplayer_truth", false))


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
