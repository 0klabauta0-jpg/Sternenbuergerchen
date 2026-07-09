class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioTesterRunAcceptance
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance.v1"
const TASK_ID: String = "TASK_1031"
const SOURCE_TASK_ID: String = "TASK_1030"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_tester_run.v1"
const REVIEW_TASK: String = "TASK_1031 - Release First Decision Loop Two Player Loop Scenario Tester Run Acceptance"
const POLISH_TASK: String = "TASK_1031 - Release First Decision Loop Two Player Loop Scenario Acceptance Polish"
const NEXT_TASK: String = "TASK_1032 - Release First Decision Loop Two Player Loop Scenario Next Playable Slice Plan"

const REQUIRED_ACCEPTANCE_CHECKS: Array[String] = [
	"tester_run_ready",
	"release_files_accepted",
	"singleplayer_path_accepted",
	"fob_next_go_feedback_accepted",
	"performance_accepted",
	"hud_boundary_accepted",
	"multiplayer_boundary_accepted",
	"known_risks_accepted",
	"next_slice_chosen",
]

const ISSUE_FLAG_IDS: Array[String] = [
	"stale_tester_run",
	"singleplayer_blocker",
	"fob_next_go_feedback_blocker",
	"performance_not_accepted",
	"hud_boundary_risk",
	"multiplayer_boundary_risk",
	"needs_visible_polish",
	"next_slice_unclear",
]


static func build_snapshot(source_tester_run: Dictionary, acceptance_review: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_source_blockers(source_tester_run)
	var review_available: bool = bool(acceptance_review.get("acceptance_review_available", false)) or not acceptance_review.is_empty()
	var review_done: bool = bool(acceptance_review.get("acceptance_review_done", false))
	var completed_checks: Array = Array(acceptance_review.get("completed_acceptance_checks", [])).duplicate(true)
	var missing_checks: Array = _missing_checks(completed_checks)
	var active_issue_flags: Array = _active_issue_flags(acceptance_review)
	var issues: Array = []
	var status: String = "blocked_until_tester_run"
	var gate: String = "blocked_until_tester_run"
	var tester_run_accepted: bool = false
	var ready_for_next_playable_slice: bool = false
	var recommended_next_task: String = REVIEW_TASK
	var recommended_direction: String = "fix_tester_run_source"

	if blockers.is_empty():
		if not review_available:
			status = "needs_acceptance_review"
			gate = "needs_acceptance_review"
			issues.append(_issue("acceptance_review_missing", "Acceptance-Review fuer TASK_1031 fehlt."))
			recommended_direction = "run_acceptance_review"
		else:
			issues = _build_acceptance_issues(review_done, missing_checks, active_issue_flags, acceptance_review)
			if not active_issue_flags.is_empty():
				status = "tester_run_acceptance_regression_found"
				gate = "tester_run_acceptance_regression_found"
				recommended_next_task = POLISH_TASK
				recommended_direction = "polish_acceptance_regressions"
			elif not issues.is_empty():
				status = "needs_acceptance_review_completion"
				gate = "needs_acceptance_review_completion"
				recommended_direction = "complete_acceptance_review"
			else:
				status = "tester_run_accepted"
				gate = "tester_run_accepted"
				tester_run_accepted = true
				ready_for_next_playable_slice = true
				recommended_next_task = NEXT_TASK
				recommended_direction = "plan_next_playable_slice"

	var all_issues: Array = blockers + issues
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_tester_run.get("schema", "")),
		"source_status": String(source_tester_run.get("status", "")),
		"source_gate": String(source_tester_run.get("gate", "")),
		"source_tester_run_line": String(source_tester_run.get("tester_run_line", "")),
		"source_tester_run_ready": bool(source_tester_run.get("tester_run_ready", false)),
		"source_ready_for_acceptance_review": bool(source_tester_run.get("ready_for_acceptance_review", false)),
		"source_missing_tester_run_checks": Array(source_tester_run.get("missing_tester_run_checks", [])).duplicate(true),
		"source_issue_flags": Array(source_tester_run.get("issue_flags", [])).duplicate(true),
		"release_build_path": String(source_tester_run.get("release_build_path", "")),
		"pck_path": String(source_tester_run.get("pck_path", "")),
		"scenario_id": String(source_tester_run.get("scenario_id", "")),
		"tester_instructions": String(source_tester_run.get("tester_instructions", "")),
		"operator_goal": String(source_tester_run.get("operator_goal", "")),
		"known_risks": Array(source_tester_run.get("known_risks", [])).duplicate(true),
		"tester_notes": Dictionary(source_tester_run.get("tester_notes", {})).duplicate(true),
		"test_result_summary": String(source_tester_run.get("test_result_summary", "")),
		"acceptance_review_available": review_available,
		"acceptance_review_done": review_done,
		"acceptance_notes": _acceptance_notes(acceptance_review),
		"required_acceptance_checks": REQUIRED_ACCEPTANCE_CHECKS.duplicate(),
		"completed_acceptance_checks": completed_checks,
		"missing_acceptance_checks": missing_checks,
		"missing_acceptance_check_count": missing_checks.size(),
		"issue_flags": active_issue_flags,
		"active_issue_count": active_issue_flags.size(),
		"acceptance_line": _build_acceptance_line(status, acceptance_review),
		"tester_run_accepted": tester_run_accepted,
		"ready_for_next_playable_slice": ready_for_next_playable_slice,
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
		blockers.append(_issue("source_schema_mismatch", "TASK_1030-Source-Schema fehlt oder passt nicht."))
	if String(source.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1030."))
	if String(source.get("status", "")) != "tester_run_ready":
		blockers.append(_issue("source_tester_run_not_ready", "TASK_1030-Source ist nicht tester_run_ready."))
	if not bool(source.get("tester_run_ready", false)):
		blockers.append(_issue("source_tester_run_not_ready", "TASK_1030-Tester-Run-Ready-Flag fehlt."))
	if not bool(source.get("ready_for_acceptance_review", false)):
		blockers.append(_issue("source_not_ready_for_acceptance_review", "TASK_1030 gibt die Acceptance noch nicht frei."))
	var line: String = String(source.get("tester_run_line", "")).strip_edges()
	if line.is_empty():
		blockers.append(_issue("source_tester_run_line_missing", "TASK_1030-Tester-Run-Line fehlt."))
	elif not (line.contains("EXE") and line.contains("FOB") and line.contains("NEXT") and line.contains("GO") and line.contains("FEEDBACK")):
		blockers.append(_issue("source_tester_run_line_incomplete", "TASK_1030-Line nennt EXE/FOB/NEXT/GO/FEEDBACK nicht gemeinsam."))
	if not Array(source.get("missing_tester_run_checks", [])).is_empty():
		blockers.append(_issue("source_tester_run_checks_missing", "TASK_1030 meldet noch fehlende Tester-Run-Checks."))
	if not Array(source.get("issue_flags", [])).is_empty():
		blockers.append(_issue("source_tester_run_has_issues", "TASK_1030 meldet noch Tester-Run-Issue-Flags."))
	if not _snapshot_is_read_only(source):
		blockers.append(_issue("source_not_read_only", "TASK_1030-Source verletzt die read-only-Grenze."))
	return _dedupe_issues(blockers)


static func _build_acceptance_issues(review_done: bool, missing_checks: Array, issue_flags: Array, acceptance_review: Dictionary) -> Array:
	var issues: Array = []
	var ids := {}
	if not review_done:
		_append_issue_once(issues, ids, "acceptance_review_open", "Acceptance-Review ist noch nicht bewusst abgeschlossen.")
	if not missing_checks.is_empty():
		_append_issue_once(issues, ids, "acceptance_checks_missing", "Acceptance-Checks fehlen: %s." % ", ".join(PackedStringArray(missing_checks)))
	for issue_id in issue_flags:
		_append_issue_once(issues, ids, "acceptance_issue_%s" % String(issue_id), _issue_text(String(issue_id)))
	if bool(acceptance_review.get("ui_sets_gameplay_truth", false)):
		_append_issue_once(issues, ids, "acceptance_ui_gameplay_truth_risk", "Acceptance darf keine UI-Gameplay-Wahrheit setzen.")
	if bool(acceptance_review.get("creates_command", false)):
		_append_issue_once(issues, ids, "acceptance_create_command", "Acceptance darf keinen Command erzeugen.")
	if bool(acceptance_review.get("creates_movement", false)):
		_append_issue_once(issues, ids, "acceptance_create_movement", "Acceptance darf keine Bewegung erzeugen.")
	if bool(acceptance_review.get("sets_multiplayer_truth", false)):
		_append_issue_once(issues, ids, "acceptance_set_multiplayer_truth", "Acceptance darf keine Multiplayer-Wahrheit setzen.")
	return issues


static func _active_issue_flags(acceptance_review: Dictionary) -> Array:
	var active: Array = []
	for issue_id in Array(acceptance_review.get("issue_flags", [])):
		var normalized: String = String(issue_id)
		if ISSUE_FLAG_IDS.has(normalized):
			active.append(normalized)
	return active


static func _missing_checks(completed_checks: Array) -> Array:
	var completed := {}
	for check_variant in completed_checks:
		completed[String(check_variant)] = true
	var missing: Array = []
	for check_id in REQUIRED_ACCEPTANCE_CHECKS:
		if not completed.has(check_id):
			missing.append(check_id)
	return missing


static func _acceptance_notes(notes: Dictionary) -> Dictionary:
	return {
		"acceptance_summary": String(notes.get("acceptance_summary", "")),
		"risk_note": String(notes.get("risk_note", "")),
		"polish_note": String(notes.get("polish_note", "")),
		"next_slice": String(notes.get("next_slice", "")),
	}


static func _build_acceptance_line(status: String, notes: Dictionary) -> String:
	if status == "tester_run_accepted":
		var next_slice: String = String(notes.get("next_slice", "naechster spielbarer Slice planen.")).strip_edges()
		return "ACCEPTED: EXE | FOB | NEXT | GO | FEEDBACK | %s" % _compact_text(next_slice, 104)
	if status == "needs_acceptance_review":
		return "ACCEPTANCE OFFEN: EXE | FOB | NEXT | GO | FEEDBACK bewusst abnehmen."
	if status == "tester_run_acceptance_regression_found":
		return "ACCEPTANCE BLOCKIERT: EXE | FOB | NEXT | GO | FEEDBACK brauchen gezielte Politur."
	return "ACCEPTANCE CHECK: EXE | FOB | NEXT | GO | FEEDBACK | Review vervollstaendigen."


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
		"stale_tester_run":
			return "Tester-Run oder Build wirkt stale."
		"singleplayer_blocker":
			return "Singleplayer-Pfad bleibt blockernd."
		"fob_next_go_feedback_blocker":
			return "FOB/NEXT/GO/FEEDBACK ist noch nicht akzeptierbar."
		"performance_not_accepted":
			return "Performance wurde fuer diesen Slice nicht akzeptiert."
		"hud_boundary_risk":
			return "HUD-/Gameplay-Wahrheitsgrenze ist riskant."
		"multiplayer_boundary_risk":
			return "Multiplayer-Grenze ist riskant."
		"needs_visible_polish":
			return "Sichtbare Politur ist vor dem naechsten Slice noetig."
		"next_slice_unclear":
			return "Naechster spielbarer Slice ist noch unklar."
	return issue_id


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
