class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioReleaseCandidateAcceptance
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance.v1"
const TASK_ID: String = "TASK_1025"
const SOURCE_TASK_ID: String = "TASK_1024"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest.v1"
const REVIEW_TASK: String = "TASK_1025 - Release First Decision Loop Two Player Loop Scenario Release Candidate Acceptance"
const POLISH_TASK: String = "TASK_1025 - Release First Decision Loop Two Player Loop Scenario Targeted RC Polish"
const NEXT_TASK: String = "TASK_1026 - Release First Decision Loop Two Player Loop Scenario Ship Readiness Review"

const REQUIRED_ACCEPTANCE_GATES: Array[String] = [
	"rc_playtest_passed",
	"release_build_present",
	"no_visible_player_blockers",
	"no_regression_issues",
	"no_input_dead_end",
	"performance_acceptable",
	"multiplayer_boundary_preserved",
	"no_hud_gameplay_truth",
	"ship_readiness_notes_written",
]


static func build_snapshot(source_playtest: Dictionary, acceptance_review: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_playtest)
	var review_available: bool = bool(acceptance_review.get("review_available", false)) or not acceptance_review.is_empty()
	var manual_done: bool = bool(acceptance_review.get("manual_acceptance_done", false))
	var passed_gates: Array = []
	var failed_gates: Array = []
	var issues: Array = []
	var status: String = "blocked"
	var gate: String = "blocked"
	var accepted: bool = false
	var ready_for_ship_readiness: bool = false
	var recommended_next_task: String = POLISH_TASK
	var recommended_direction: String = "fix_release_candidate_playtest_source"
	if blockers.is_empty():
		if not review_available:
			status = "needs_release_candidate_acceptance_review"
			gate = "needs_release_candidate_acceptance_review"
			issues.append(_issue("release_candidate_acceptance_review_missing", "Release-Candidate-Acceptance-Review fuer TASK_1025 fehlt."))
			recommended_next_task = REVIEW_TASK
			recommended_direction = "collect_release_candidate_acceptance_review"
		else:
			var gate_result: Dictionary = _evaluate_acceptance_gates(acceptance_review)
			passed_gates = Array(gate_result.get("passed", []))
			failed_gates = Array(gate_result.get("failed", []))
			issues = _build_review_issues(acceptance_review, failed_gates, manual_done)
			if not manual_done:
				status = "needs_release_candidate_acceptance_review"
				gate = "needs_release_candidate_acceptance_review"
				recommended_next_task = REVIEW_TASK
				recommended_direction = "complete_release_candidate_acceptance_review"
			elif issues.is_empty():
				status = "release_candidate_accepted"
				gate = "release_candidate_accepted"
				accepted = true
				ready_for_ship_readiness = true
				recommended_next_task = NEXT_TASK
				recommended_direction = "prepare_ship_readiness_review"
			else:
				status = "release_candidate_acceptance_regression_found"
				gate = "release_candidate_acceptance_regression_found"
				recommended_next_task = POLISH_TASK
				recommended_direction = "polish_release_candidate_acceptance_blockers"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_playtest.get("schema", "")),
		"source_status": String(source_playtest.get("status", "")),
		"source_gate": String(source_playtest.get("gate", "")),
		"source_release_candidate_playtest_line": String(source_playtest.get("release_candidate_playtest_line", "")),
		"source_release_candidate_playtest_passed": bool(source_playtest.get("release_candidate_playtest_passed", false)),
		"source_ready_for_release_candidate_acceptance": bool(source_playtest.get("ready_for_release_candidate_acceptance", false)),
		"source_release_build_path": String(source_playtest.get("release_build_path", "")),
		"review_available": review_available,
		"manual_acceptance_done": manual_done,
		"accepted_by": String(acceptance_review.get("accepted_by", "")),
		"acceptance_notes": String(acceptance_review.get("acceptance_notes", "")),
		"ship_readiness_notes": String(acceptance_review.get("ship_readiness_notes", "")),
		"required_acceptance_gates": REQUIRED_ACCEPTANCE_GATES.duplicate(),
		"passed_acceptance_gates": passed_gates,
		"failed_acceptance_gates": failed_gates,
		"failed_acceptance_gate_count": failed_gates.size(),
		"release_candidate_acceptance_line": _build_acceptance_line(source_playtest, accepted, review_available),
		"release_candidate_accepted": accepted,
		"ready_for_ship_readiness_review": ready_for_ship_readiness,
		"status": status,
		"gate": gate,
		"issues": issues,
		"issue_count": issues.size(),
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary((blockers + issues)[0]).get("id", "")) if not (blockers + issues).is_empty() else "",
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


static func _build_blockers(source_playtest: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_playtest.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_1024-Source-Schema fehlt oder passt nicht."))
	if String(source_playtest.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1024."))
	if String(source_playtest.get("status", "")) != "release_candidate_playtest_passed":
		blockers.append(_issue("source_rc_playtest_not_passed", "TASK_1024-Source ist nicht release_candidate_playtest_passed."))
	if not bool(source_playtest.get("release_candidate_playtest_passed", false)):
		blockers.append(_issue("source_pass_flag_missing", "TASK_1024-Pass-Flag fehlt."))
	if not bool(source_playtest.get("ready_for_release_candidate_acceptance", false)):
		blockers.append(_issue("source_not_ready_for_release_candidate_acceptance", "TASK_1024 ist nicht fuer Release-Candidate-Acceptance freigegeben."))
	var line: String = String(source_playtest.get("release_candidate_playtest_line", "")).strip_edges()
	if line.is_empty():
		blockers.append(_issue("source_release_candidate_playtest_line_missing", "TASK_1024-Playtest-Line fehlt."))
	elif not (line.contains("FOB") and line.contains("NEXT") and line.contains("GO") and line.contains("FEEDBACK")):
		blockers.append(_issue("source_release_candidate_playtest_line_incomplete", "TASK_1024-Playtest-Line nennt FOB/NEXT/GO/FEEDBACK nicht gemeinsam."))
	if int(source_playtest.get("issue_count", 0)) > 0:
		blockers.append(_issue("source_issues_present", "TASK_1024-Source enthaelt noch Issues."))
	if not _snapshot_is_read_only(source_playtest):
		blockers.append(_issue("source_not_read_only", "TASK_1024-Source verletzt die read-only-Grenze."))
	return blockers


static func _evaluate_acceptance_gates(review: Dictionary) -> Dictionary:
	var passed: Array = []
	var failed: Array = []
	for gate_id in REQUIRED_ACCEPTANCE_GATES:
		if bool(review.get(gate_id, false)):
			passed.append(gate_id)
		else:
			failed.append(gate_id)
	return {
		"passed": passed,
		"failed": failed,
	}


static func _build_review_issues(review: Dictionary, failed_gates: Array, manual_done: bool) -> Array:
	var issues: Array = []
	var ids := {}
	if not manual_done:
		_append_issue_once(issues, ids, "manual_acceptance_review_open", "Release-Candidate-Acceptance-Review ist noch nicht abgeschlossen.")
	if failed_gates.has("rc_playtest_passed"):
		_append_issue_once(issues, ids, "rc_playtest_pass_gate_missing", "Acceptance-Review bestaetigt den RC-Playtest-Pass nicht.")
	if failed_gates.has("release_build_present"):
		_append_issue_once(issues, ids, "release_build_not_confirmed", "Release-Build wurde fuer Acceptance nicht bestaetigt.")
	if failed_gates.has("no_visible_player_blockers"):
		_append_issue_once(issues, ids, "visible_player_blockers_remain", "Es bleiben sichtbare Spielerblocker im RC.")
	if failed_gates.has("no_regression_issues"):
		_append_issue_once(issues, ids, "regression_issues_remain", "Acceptance-Review meldet offene Regressionen.")
	if failed_gates.has("no_input_dead_end"):
		_append_issue_once(issues, ids, "input_dead_end_remains", "Acceptance-Review meldet eine Input-Sackgasse.")
	if failed_gates.has("performance_acceptable"):
		_append_issue_once(issues, ids, "performance_not_acceptable", "Performance ist fuer Acceptance nicht akzeptabel.")
	if failed_gates.has("multiplayer_boundary_preserved"):
		_append_issue_once(issues, ids, "multiplayer_boundary_not_preserved", "Multiplayer-/Wahrheitsgrenze ist fuer Acceptance nicht erhalten.")
	if failed_gates.has("no_hud_gameplay_truth"):
		_append_issue_once(issues, ids, "hud_gameplay_truth_risk", "HUD-Gameplay-Wahrheit ist fuer Acceptance nicht ausgeschlossen.")
	if failed_gates.has("ship_readiness_notes_written"):
		_append_issue_once(issues, ids, "ship_readiness_notes_missing", "Ship-Readiness-Notizen fuer den naechsten Schritt fehlen.")
	if String(review.get("acceptance_notes", "")).strip_edges().is_empty():
		_append_issue_once(issues, ids, "acceptance_notes_missing", "Acceptance-Notizen fehlen.")
	if bool(review.get("ui_sets_gameplay_truth", false)):
		_append_issue_once(issues, ids, "review_ui_gameplay_truth_risk", "Review deutet UI-Gameplay-Wahrheit an.")
	if bool(review.get("creates_command", false)):
		_append_issue_once(issues, ids, "review_creates_command", "Acceptance-Review darf keinen Command erzeugen.")
	if bool(review.get("creates_movement", false)):
		_append_issue_once(issues, ids, "review_creates_movement", "Acceptance-Review darf keine Bewegung erzeugen.")
	if bool(review.get("sets_multiplayer_truth", false)):
		_append_issue_once(issues, ids, "review_sets_multiplayer_truth", "Acceptance-Review darf keine Multiplayer-Wahrheit setzen.")
	return issues


static func _append_issue_once(issues: Array, ids: Dictionary, issue_id: String, text: String) -> void:
	if ids.has(issue_id):
		return
	ids[issue_id] = true
	issues.append(_issue(issue_id, text))


static func _build_acceptance_line(source_playtest: Dictionary, accepted: bool, review_available: bool) -> String:
	var source_line: String = String(source_playtest.get("release_candidate_playtest_line", "")).strip_edges()
	var state: String = "ACCEPTED" if accepted else "CHECK" if review_available else "Review offen"
	if source_line.is_empty():
		source_line = "FOB, NEXT, GO und FEEDBACK brauchen RC-Acceptance."
	return "RC ACCEPTANCE %s: FOB | NEXT | GO | FEEDBACK | %s" % [state, _compact_text(source_line, 104)]


static func _compact_text(text: String, max_length: int) -> String:
	var normalized: String = text.strip_edges()
	if normalized.length() <= max_length:
		return normalized
	return normalized.substr(0, maxi(max_length - 3, 0)).strip_edges() + "..."


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
