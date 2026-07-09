class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioStitch
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_stitch.v1"
const TASK_ID: String = "TASK_1012"
const SOURCE_TASK_ID: String = "TASK_1011"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice.v1"
const REVIEW_TASK: String = "TASK_1012 - Release First Decision Loop Two Player Loop Scenario Stitch"
const ACCEPTANCE_TASK: String = "TASK_1011 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Acceptance Slice"
const NEXT_TASK: String = "TASK_1013 - Release First Decision Loop Two Player Loop Scenario Runtime Hook"

const REQUIRED_STITCH_CHECKS: PackedStringArray = [
	"scenario_beats_present",
	"entry_and_exit_present",
	"mission_objective_present",
	"two_player_roles_present",
	"npc_pressure_present",
	"feel_next_go_loop_embedded",
	"feedback_next_hook_present",
	"multiplayer_boundary_preserved",
	"no_new_gameplay_truth",
]


static func build_snapshot(source_acceptance: Dictionary, stitch_trace: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_source_blockers(source_acceptance)
	var trace_available: bool = bool(stitch_trace.get("trace_available", false)) or not stitch_trace.is_empty()
	var issues: Array = []
	if blockers.is_empty():
		if not trace_available:
			issues.append(_issue("scenario_stitch_trace_missing", "TASK_1012-Szenario-Stitch-Trace fehlt."))
		else:
			issues = _build_trace_issues(stitch_trace)

	var passed: bool = blockers.is_empty() and trace_available and issues.is_empty()
	var status: String = "blocked"
	var gate: String = "blocked"
	var recommended_next_task: String = ACCEPTANCE_TASK
	var recommended_direction: String = "fix_round_loop_acceptance_source"
	if blockers.is_empty():
		if passed:
			status = "scenario_stitch_ready"
			gate = "scenario_stitch_ready"
			recommended_next_task = NEXT_TASK
			recommended_direction = "build_scenario_runtime_hook"
		elif trace_available:
			status = "scenario_stitch_regression_found"
			gate = "scenario_stitch_regression_found"
			recommended_next_task = ACCEPTANCE_TASK
			recommended_direction = "repair_scenario_stitch_trace"
		else:
			status = "needs_scenario_stitch_trace"
			gate = "needs_scenario_stitch_trace"
			recommended_next_task = REVIEW_TASK
			recommended_direction = "run_scenario_stitch_trace"

	var scenario_beats: Array = Array(stitch_trace.get("scenario_beats", [])).duplicate(true)
	var two_player_roles: Array = Array(stitch_trace.get("two_player_roles", [])).duplicate(true)
	var completed_checks: Array = Array(stitch_trace.get("completed_checks", [])).duplicate(true)
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_acceptance.get("schema", "")),
		"source_status": String(source_acceptance.get("status", "")),
		"source_gate": String(source_acceptance.get("gate", "")),
		"source_round_loop_acceptance_line": String(source_acceptance.get("round_loop_acceptance_line", "")),
		"source_round_loop_acceptance_slice_passed": bool(source_acceptance.get("round_loop_acceptance_slice_passed", false)),
		"trace_available": trace_available,
		"required_stitch_checks": Array(REQUIRED_STITCH_CHECKS),
		"completed_checks": completed_checks,
		"missing_stitch_checks": _missing_checks(completed_checks),
		"scenario_id": String(stitch_trace.get("scenario_id", "")),
		"scenario_title": String(stitch_trace.get("scenario_title", "")),
		"mission_objective_line": String(stitch_trace.get("mission_objective_line", "")),
		"scenario_beats": scenario_beats,
		"scenario_beat_count": scenario_beats.size(),
		"two_player_roles": two_player_roles,
		"two_player_role_count": two_player_roles.size(),
		"npc_pressure_line": String(stitch_trace.get("npc_pressure_line", "")),
		"feel_next_go_loop_embedded": bool(stitch_trace.get("feel_next_go_loop_embedded", false)),
		"feedback_next_hook_present": bool(stitch_trace.get("feedback_next_hook_present", false)),
		"multiplayer_boundary_preserved": bool(stitch_trace.get("multiplayer_boundary_preserved", false)),
		"no_new_gameplay_truth": bool(stitch_trace.get("no_new_gameplay_truth", false)),
		"scenario_stitch_line": _build_scenario_stitch_line(stitch_trace, passed, trace_available),
		"scenario_stitch_ready": passed,
		"status": status,
		"gate": gate,
		"issues": issues,
		"issue_count": issues.size(),
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else (String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else ""),
		"recommended_next_task": recommended_next_task,
		"recommended_direction": recommended_direction,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
	}


static func _build_source_blockers(source_acceptance: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_acceptance.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_1011-Source-Schema fehlt oder passt nicht."))
	if String(source_acceptance.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1011."))
	if String(source_acceptance.get("status", "")) != "round_loop_acceptance_slice_passed":
		blockers.append(_issue("source_not_accepted", "TASK_1011-Source ist nicht akzeptiert."))
	if not bool(source_acceptance.get("round_loop_acceptance_slice_passed", false)):
		blockers.append(_issue("source_pass_flag_missing", "TASK_1011 setzt round_loop_acceptance_slice_passed nicht."))
	var acceptance_line: String = String(source_acceptance.get("round_loop_acceptance_line", ""))
	if not acceptance_line.contains("FEEL"):
		blockers.append(_issue("source_feel_line_missing", "TASK_1011-Acceptance-Zeile nennt FEEL nicht."))
	if not acceptance_line.contains("NEXT"):
		blockers.append(_issue("source_next_line_missing", "TASK_1011-Acceptance-Zeile nennt NEXT nicht."))
	if not acceptance_line.contains("GO"):
		blockers.append(_issue("source_go_boundary_missing", "TASK_1011-Acceptance-Zeile nennt GO nicht."))
	if int(source_acceptance.get("answered_player_question_count", Array(source_acceptance.get("answered_player_questions", [])).size())) < 6:
		blockers.append(_issue("source_player_question_coverage_too_low", "TASK_1011 beantwortet zu wenige Spielerfragen."))
	if not _snapshot_is_read_only(source_acceptance):
		blockers.append(_issue("source_not_read_only", "TASK_1011-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_trace_issues(trace: Dictionary) -> Array:
	var issues: Array = []
	var completed_checks: Array = Array(trace.get("completed_checks", []))
	var missing_checks: Array = _missing_checks(completed_checks)
	for check_id in missing_checks:
		match String(check_id):
			"scenario_beats_present":
				issues.append(_issue("scenario_beats_missing", "Szenario-Beats fehlen."))
			"entry_and_exit_present":
				issues.append(_issue("entry_exit_missing", "Entry-/Exit-Beats fehlen."))
			"mission_objective_present":
				issues.append(_issue("mission_objective_missing", "Mission-Objective-Zeile fehlt."))
			"two_player_roles_present":
				issues.append(_issue("two_player_roles_missing", "Zwei-Spieler-Rollen fehlen."))
			"npc_pressure_present":
				issues.append(_issue("npc_pressure_missing", "NPC-Druck ist nicht beschrieben."))
			"feel_next_go_loop_embedded":
				issues.append(_issue("feel_next_go_loop_missing", "FEEL/NEXT/GO ist nicht in den Szenario-Stitch eingebettet."))
			"feedback_next_hook_present":
				issues.append(_issue("feedback_next_hook_missing", "Feedback-zurueck-zu-NEXT fehlt."))
			"multiplayer_boundary_preserved":
				issues.append(_issue("multiplayer_boundary_risk", "Multiplayer-Grenze ist nicht belegt."))
			"no_new_gameplay_truth":
				issues.append(_issue("gameplay_truth_risk", "Gameplay-Wahrheit-Grenze ist nicht belegt."))

	var beats: Array = Array(trace.get("scenario_beats", []))
	if beats.size() < 5 and not _has_issue(issues, "scenario_beats_missing"):
		issues.append(_issue("scenario_beats_missing", "Szenario braucht mindestens fuenf Beats."))
	if not _entry_exit_present(beats) and not _has_issue(issues, "entry_exit_missing"):
		issues.append(_issue("entry_exit_missing", "Szenario braucht Entry und Exit."))
	if String(trace.get("mission_objective_line", "")).strip_edges().is_empty() and not _has_issue(issues, "mission_objective_missing"):
		issues.append(_issue("mission_objective_missing", "Mission-Objective-Zeile fehlt."))
	if Array(trace.get("two_player_roles", [])).size() != 2 and not _has_issue(issues, "two_player_roles_missing"):
		issues.append(_issue("two_player_roles_missing", "Genau zwei Spielerrollen muessen sichtbar sein."))
	if String(trace.get("npc_pressure_line", "")).strip_edges().is_empty() and not _has_issue(issues, "npc_pressure_missing"):
		issues.append(_issue("npc_pressure_missing", "NPC-Druck-Zeile fehlt."))
	if bool(trace.get("ui_sets_gameplay_truth", false)):
		issues.append(_issue("ui_sets_gameplay_truth", "Trace meldet UI-Gameplay-Wahrheit."))
	if bool(trace.get("creates_command", false)):
		issues.append(_issue("trace_creates_command", "Trace darf keinen Command erzeugen."))
	if bool(trace.get("creates_movement", false)):
		issues.append(_issue("trace_creates_movement", "Trace darf kein Movement erzeugen."))
	if bool(trace.get("creates_fire_event", false)):
		issues.append(_issue("trace_creates_fire_event", "Trace darf kein Fire-Event erzeugen."))
	if bool(trace.get("creates_damage_event", false)):
		issues.append(_issue("trace_creates_damage_event", "Trace darf kein Damage-Event erzeugen."))
	if bool(trace.get("sets_multiplayer_truth", false)):
		issues.append(_issue("trace_sets_multiplayer_truth", "Trace darf keine Multiplayer-Wahrheit setzen."))
	return issues


static func _missing_checks(completed_checks: Array) -> Array:
	var completed := {}
	for check_variant in completed_checks:
		completed[String(check_variant)] = true
	var missing: Array = []
	for check_id in REQUIRED_STITCH_CHECKS:
		if not completed.has(String(check_id)):
			missing.append(String(check_id))
	return missing


static func _entry_exit_present(beats: Array) -> bool:
	if beats.size() < 2:
		return false
	var first: Dictionary = Dictionary(beats[0])
	var last: Dictionary = Dictionary(beats[beats.size() - 1])
	return String(first.get("beat_id", "")) == "entry" and String(last.get("beat_id", "")) == "exit"


static func _build_scenario_stitch_line(trace: Dictionary, passed: bool, trace_available: bool) -> String:
	if not trace_available:
		return "FOB-Szenario offen | FEEL/NEXT/GO Trace fehlt | GO separat"
	var title: String = String(trace.get("scenario_title", "")).strip_edges()
	if title.is_empty():
		title = "FOB Relay Probe"
	var next_text: String = "NEXT: Runtime Hook" if passed else "NEXT: Stitch reparieren"
	return "%s | FOB | FEEL/NEXT/GO | GO separat | %s" % [title, next_text]


static func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", false)) \
		and not bool(snapshot.get("creates_command", false)) \
		and not bool(snapshot.get("creates_movement", false)) \
		and not bool(snapshot.get("creates_fire_event", false)) \
		and not bool(snapshot.get("creates_damage_event", false)) \
		and not bool(snapshot.get("sets_multiplayer_truth", false))


static func _has_issue(issues: Array, issue_id: String) -> bool:
	for issue_variant in issues:
		if typeof(issue_variant) == TYPE_DICTIONARY and String(Dictionary(issue_variant).get("id", "")) == issue_id:
			return true
	return false


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
