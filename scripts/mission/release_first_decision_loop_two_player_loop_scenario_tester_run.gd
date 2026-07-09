class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioTesterRun
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_tester_run.v1"
const TASK_ID: String = "TASK_1030"
const SOURCE_TASK_ID: String = "TASK_1029"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_handoff_packet.v1"
const REVIEW_TASK: String = "TASK_1030 - Release First Decision Loop Two Player Loop Scenario Tester Run"
const POLISH_TASK: String = "TASK_1030 - Release First Decision Loop Two Player Loop Scenario Tester Run Polish"
const NEXT_TASK: String = "TASK_1031 - Release First Decision Loop Two Player Loop Scenario Tester Run Acceptance"

const REQUIRED_TESTER_RUN_CHECKS: Array[String] = [
	"handoff_packet_used",
	"fresh_release_exe_started",
	"singleplayer_homebase_actionable",
	"fob_next_go_feedback_seen",
	"first_loop_reacts",
	"no_input_dead_end",
	"performance_feels_fast",
	"hud_does_not_block",
	"multiplayer_boundary_preserved",
	"tester_notes_exported",
]

const ISSUE_FLAG_IDS: Array[String] = [
	"stale_handoff_or_exe",
	"singleplayer_homebase_blocked",
	"fob_next_go_feedback_missing",
	"first_loop_not_reacting",
	"input_dead_end",
	"performance_slow",
	"hud_blocks_action",
	"multiplayer_boundary_broken",
]


static func build_snapshot(source_handoff_packet: Dictionary, tester_run_notes: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_source_blockers(source_handoff_packet)
	var notes_available: bool = bool(tester_run_notes.get("tester_run_available", false)) or not tester_run_notes.is_empty()
	var tester_run_done: bool = bool(tester_run_notes.get("tester_run_done", false))
	var completed_checks: Array = Array(tester_run_notes.get("completed_tester_run_checks", [])).duplicate(true)
	var missing_checks: Array = _missing_checks(completed_checks)
	var active_issue_flags: Array = _active_issue_flags(tester_run_notes)
	var issues: Array = []
	var status: String = "blocked_until_handoff_packet"
	var gate: String = "blocked_until_handoff_packet"
	var tester_run_ready: bool = false
	var ready_for_acceptance_review: bool = false
	var recommended_next_task: String = REVIEW_TASK
	var recommended_direction: String = "fix_handoff_packet_source"

	if blockers.is_empty():
		if not notes_available:
			status = "needs_tester_run"
			gate = "needs_tester_run"
			issues.append(_issue("tester_run_notes_missing", "Tester-Run-Notizen fuer TASK_1030 fehlen."))
			recommended_direction = "run_tester_pass"
		else:
			issues = _build_tester_run_issues(tester_run_done, missing_checks, active_issue_flags, tester_run_notes)
			if not active_issue_flags.is_empty():
				status = "tester_run_regression_found"
				gate = "tester_run_regression_found"
				recommended_next_task = POLISH_TASK
				recommended_direction = "polish_tester_run_regressions"
			elif not issues.is_empty():
				status = "needs_tester_run_completion"
				gate = "needs_tester_run_completion"
				recommended_direction = "complete_tester_run_checks"
			else:
				status = "tester_run_ready"
				gate = "tester_run_ready"
				tester_run_ready = true
				ready_for_acceptance_review = true
				recommended_next_task = NEXT_TASK
				recommended_direction = "cut_tester_run_acceptance"

	var all_issues: Array = blockers + issues
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_handoff_packet.get("schema", "")),
		"source_status": String(source_handoff_packet.get("status", "")),
		"source_gate": String(source_handoff_packet.get("gate", "")),
		"source_handoff_packet_line": String(source_handoff_packet.get("handoff_packet_line", "")),
		"source_handoff_packet_ready": bool(source_handoff_packet.get("handoff_packet_ready", false)),
		"source_ready_for_tester_run": bool(source_handoff_packet.get("ready_for_tester_run", false)),
		"release_build_path": String(source_handoff_packet.get("release_build_path", "")),
		"pck_path": String(source_handoff_packet.get("pck_path", "")),
		"scenario_id": String(source_handoff_packet.get("scenario_id", "")),
		"tester_instructions": String(source_handoff_packet.get("tester_instructions", "")),
		"operator_goal": String(source_handoff_packet.get("operator_goal", "")),
		"known_risks": Array(source_handoff_packet.get("known_risks", [])).duplicate(true),
		"handoff_notes": Dictionary(source_handoff_packet.get("handoff_notes", {})).duplicate(true),
		"test_steps": Array(source_handoff_packet.get("test_steps", [])).duplicate(true),
		"tester_run_available": notes_available,
		"tester_run_done": tester_run_done,
		"tester_notes": _tester_notes(tester_run_notes),
		"test_result_summary": _test_result_summary(status, tester_run_notes),
		"required_tester_run_checks": REQUIRED_TESTER_RUN_CHECKS.duplicate(),
		"completed_tester_run_checks": completed_checks,
		"missing_tester_run_checks": missing_checks,
		"missing_tester_run_check_count": missing_checks.size(),
		"issue_flags": active_issue_flags,
		"active_issue_count": active_issue_flags.size(),
		"tester_run_line": _build_tester_run_line(status, source_handoff_packet, tester_run_notes),
		"tester_run_ready": tester_run_ready,
		"ready_for_acceptance_review": ready_for_acceptance_review,
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
		blockers.append(_issue("source_schema_mismatch", "TASK_1029-Source-Schema fehlt oder passt nicht."))
	if String(source.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1029."))
	if String(source.get("status", "")) != "handoff_packet_ready":
		blockers.append(_issue("source_handoff_packet_not_ready", "TASK_1029-Source ist nicht handoff_packet_ready."))
	if not bool(source.get("handoff_packet_ready", false)):
		blockers.append(_issue("source_handoff_packet_not_ready", "TASK_1029-Handoff-Ready-Flag fehlt."))
	if not bool(source.get("ready_for_tester_run", false)):
		blockers.append(_issue("source_not_ready_for_tester_run", "TASK_1029 gibt den Tester-Run noch nicht frei."))
	var line: String = String(source.get("handoff_packet_line", "")).strip_edges()
	if line.is_empty():
		blockers.append(_issue("source_handoff_packet_line_missing", "TASK_1029-Handoff-Line fehlt."))
	elif not (line.contains("FOB") and line.contains("NEXT") and line.contains("GO") and line.contains("FEEDBACK")):
		blockers.append(_issue("source_handoff_packet_line_incomplete", "TASK_1029-Line nennt FOB/NEXT/GO/FEEDBACK nicht gemeinsam."))
	if not _snapshot_is_read_only(source):
		blockers.append(_issue("source_not_read_only", "TASK_1029-Source verletzt die read-only-Grenze."))
	return _dedupe_issues(blockers)


static func _build_tester_run_issues(tester_run_done: bool, missing_checks: Array, issue_flags: Array, tester_run_notes: Dictionary) -> Array:
	var issues: Array = []
	var ids := {}
	if not tester_run_done:
		_append_issue_once(issues, ids, "manual_tester_run_open", "Tester Run ist noch nicht bewusst abgeschlossen.")
	if not missing_checks.is_empty():
		_append_issue_once(issues, ids, "tester_run_checks_missing", "Tester-Run-Checks fehlen: %s." % ", ".join(PackedStringArray(missing_checks)))
	for issue_id in issue_flags:
		_append_issue_once(issues, ids, "tester_run_issue_%s" % String(issue_id), _issue_text(String(issue_id)))
	if bool(tester_run_notes.get("ui_sets_gameplay_truth", false)):
		_append_issue_once(issues, ids, "tester_ui_gameplay_truth_risk", "Tester Run darf keine UI-Gameplay-Wahrheit setzen.")
	if bool(tester_run_notes.get("creates_command", false)):
		_append_issue_once(issues, ids, "tester_create_command", "Tester Run darf keinen Command erzeugen.")
	if bool(tester_run_notes.get("creates_movement", false)):
		_append_issue_once(issues, ids, "tester_create_movement", "Tester Run darf keine Bewegung erzeugen.")
	if bool(tester_run_notes.get("sets_multiplayer_truth", false)):
		_append_issue_once(issues, ids, "tester_set_multiplayer_truth", "Tester Run darf keine Multiplayer-Wahrheit setzen.")
	return issues


static func _active_issue_flags(tester_run_notes: Dictionary) -> Array:
	var active: Array = []
	for issue_id in Array(tester_run_notes.get("issue_flags", [])):
		var normalized: String = String(issue_id)
		if ISSUE_FLAG_IDS.has(normalized):
			active.append(normalized)
	return active


static func _missing_checks(completed_checks: Array) -> Array:
	var completed := {}
	for check_variant in completed_checks:
		completed[String(check_variant)] = true
	var missing: Array = []
	for check_id in REQUIRED_TESTER_RUN_CHECKS:
		if not completed.has(check_id):
			missing.append(check_id)
	return missing


static func _tester_notes(notes: Dictionary) -> Dictionary:
	return {
		"tester_summary": String(notes.get("tester_summary", "")),
		"singleplayer_note": String(notes.get("singleplayer_note", "")),
		"mission_note": String(notes.get("mission_note", "")),
		"performance_note": String(notes.get("performance_note", "")),
		"next_note": String(notes.get("next_note", "")),
	}


static func _test_result_summary(status: String, notes: Dictionary) -> String:
	if status == "tester_run_ready":
		return String(notes.get("tester_summary", "Tester Run abgeschlossen."))
	if status == "needs_tester_run":
		return "Tester Run steht noch aus."
	if status == "tester_run_regression_found":
		return "Tester Run hat konkrete Reibung gemeldet."
	return "Tester Run ist unvollstaendig."


static func _build_tester_run_line(status: String, source: Dictionary, notes: Dictionary) -> String:
	if status == "tester_run_ready":
		var summary: String = String(notes.get("tester_summary", "FOB/NEXT/GO/FEEDBACK geprueft.")).strip_edges()
		return "TESTER RUN READY: EXE | FOB | NEXT | GO | FEEDBACK | %s" % _compact_text(summary, 104)
	if status == "needs_tester_run":
		return "TESTER RUN OFFEN: EXE | FOB | NEXT | GO | FEEDBACK muessen frisch geprueft werden."
	if status == "tester_run_regression_found":
		return "TESTER RUN BLOCKIERT: EXE | FOB | NEXT | GO | FEEDBACK brauchen gezielte Politur."
	var source_line: String = String(source.get("handoff_packet_line", "")).strip_edges()
	if source_line.is_empty():
		source_line = "EXE, FOB, NEXT, GO und FEEDBACK brauchen Tester Run."
	return "TESTER RUN CHECK: EXE | FOB | NEXT | GO | FEEDBACK | %s" % _compact_text(source_line, 104)


static func _compact_text(text: String, max_length: int) -> String:
	var normalized: String = text.strip_edges()
	if normalized.length() <= max_length:
		return normalized
	return normalized.substr(0, maxi(max_length - 3, 0)).strip_edges() + "..."


static func _append_issue_once(issues: Array, ids: Dictionary, issue_id: String, text: String) -> void:
	if ids.has(issue_id):
		return
	ids[issue_id] = true
	issues.append(_issue(issue_id, text))


static func _dedupe_issues(issues: Array) -> Array:
	var result: Array = []
	var ids := {}
	for issue_variant in issues:
		if typeof(issue_variant) != TYPE_DICTIONARY:
			continue
		var issue: Dictionary = Dictionary(issue_variant)
		var issue_id: String = String(issue.get("id", ""))
		if ids.has(issue_id):
			continue
		ids[issue_id] = true
		result.append(issue)
	return result


static func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", false)) \
		and not bool(snapshot.get("creates_command", false)) \
		and not bool(snapshot.get("creates_movement", false)) \
		and not bool(snapshot.get("creates_fire_event", false)) \
		and not bool(snapshot.get("creates_damage_event", false)) \
		and not bool(snapshot.get("sets_multiplayer_truth", false))


static func _issue_text(issue_id: String) -> String:
	match issue_id:
		"stale_handoff_or_exe":
			return "Handoff oder EXE wirkt stale."
		"singleplayer_homebase_blocked":
			return "Einzelspieler/Homebase ist blockiert."
		"fob_next_go_feedback_missing":
			return "FOB/NEXT/GO/FEEDBACK ist nicht gemeinsam sichtbar."
		"first_loop_not_reacting":
			return "Der erste kleine Loop reagiert nicht belastbar."
		"input_dead_end":
			return "Tester Run endet in einer Input-Sackgasse."
		"performance_slow":
			return "Performance fuehlt sich zu langsam an."
		"hud_blocks_action":
			return "HUD blockiert eine Pflichtaktion."
		"multiplayer_boundary_broken":
			return "Multiplayer-Grenze wurde verletzt."
	return issue_id


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
