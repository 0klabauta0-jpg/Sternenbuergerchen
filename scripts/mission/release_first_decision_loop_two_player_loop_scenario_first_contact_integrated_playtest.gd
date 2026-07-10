class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioFirstContactIntegratedPlaytest
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest.v1"
const TASK_ID: String = "TASK_1042"
const SOURCE_TASK_ID: String = "TASK_1041"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice.v1"
const REVIEW_TASK: String = "TASK_1042 - Release First Decision Loop Two Player Loop Scenario First Contact Integrated Playtest"
const ACCEPTANCE_TASK: String = "TASK_1041 - Release First Decision Loop Two Player Loop Scenario First Contact Acceptance Slice"
const NEXT_TASK: String = "TASK_1043 - Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Findings"

const REQUIRED_INTEGRATED_CHECKS: PackedStringArray = [
	"release_mission_context_reached",
	"command_feedback_embeds_acceptance_slice",
	"first_contact_surface_read_in_context",
	"why_surface_read_in_context",
	"next_decision_visible_in_context",
	"fire_wait_choice_run_in_context",
	"go_path_reused",
	"go_separation_observed",
	"post_go_feedback_observed",
	"feedback_returns_to_next",
	"no_command_before_go",
	"no_auto_go",
	"hud_read_only_boundary_ok",
	"multiplayer_boundary_preserved",
	"performance_budget_ok",
	"no_new_hud_gameplay_truth",
]

const REQUIRED_PLAYER_QUESTIONS: PackedStringArray = [
	"where_did_player_start",
	"who_has_contact",
	"why_is_it_risky",
	"what_is_fire_wait_choice",
	"what_happened_after_go",
	"did_it_return_to_next",
	"were_boundaries_preserved",
]


static func build_snapshot(source_acceptance_slice: Dictionary, trace: Dictionary = {}) -> Dictionary:
	var source: Dictionary = source_acceptance_slice.duplicate(true)
	var integrated_trace: Dictionary = trace.duplicate(true)
	var blockers: Array = _build_source_blockers(source)
	var trace_available: bool = false
	if integrated_trace.has("trace_available"):
		trace_available = bool(integrated_trace.get("trace_available", false))
	else:
		trace_available = not integrated_trace.is_empty()
	var completed_checks: Array = _completed_integrated_checks(integrated_trace) if trace_available else []
	var missing_checks: Array = _missing_integrated_checks(completed_checks) if trace_available else []
	var issues: Array = []
	var status: String = "blocked"
	var gate: String = "blocked"
	var passed: bool = false
	var recommended_next_task: String = ACCEPTANCE_TASK
	var recommended_direction: String = "fix_first_contact_integrated_playtest_source"
	if blockers.is_empty():
		if not trace_available:
			status = "needs_first_contact_integrated_playtest_trace"
			gate = "needs_first_contact_integrated_playtest_trace"
			issues.append(_issue("first_contact_integrated_playtest_trace_missing", "TASK_1042 braucht einen Integrated-Playtest-Trace fuer Release-/Mission-Kontext, CONTACT/WHY/FIRE-WAIT, GO und FEEDBACK."))
			recommended_next_task = REVIEW_TASK
			recommended_direction = "run_first_contact_integrated_playtest_trace"
		else:
			issues = _build_trace_issues(integrated_trace, missing_checks)
			if issues.is_empty():
				status = "first_contact_integrated_playtest_passed"
				gate = "first_contact_integrated_playtest_passed"
				passed = true
				recommended_next_task = NEXT_TASK
				recommended_direction = "collect_first_contact_player_feel_findings"
			else:
				status = "first_contact_integrated_playtest_regression_found"
				gate = "first_contact_integrated_playtest_regression"
				recommended_next_task = ACCEPTANCE_TASK
				recommended_direction = "tighten_first_contact_acceptance_slice"
	var answered_questions: Array = Array(integrated_trace.get("answered_player_questions", [])).duplicate(true)
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source.get("schema", "")),
		"source_status": String(source.get("status", "")),
		"source_gate": String(source.get("gate", "")),
		"source_first_contact_acceptance_line": String(source.get("first_contact_acceptance_line", "")),
		"source_ready_for_first_contact_integrated_playtest": bool(source.get("ready_for_first_contact_integrated_playtest", false)),
		"trace_available": trace_available,
		"trace_id": String(integrated_trace.get("trace_id", "")),
		"required_integrated_checks": Array(REQUIRED_INTEGRATED_CHECKS),
		"completed_checks": completed_checks,
		"missing_integrated_checks": missing_checks,
		"required_player_questions": Array(REQUIRED_PLAYER_QUESTIONS),
		"answered_player_questions": answered_questions,
		"answered_player_question_count": answered_questions.size(),
		"entry_line": String(integrated_trace.get("entry_line", "")),
		"post_go_line": String(integrated_trace.get("post_go_line", "")),
		"observed_frame_budget_ms": float(integrated_trace.get("observed_frame_budget_ms", 0.0)),
		"integrated_playtest_line": _build_integrated_line(source, integrated_trace, trace_available),
		"first_contact_integrated_playtest_passed": passed,
		"ready_for_first_contact_player_feel_findings": passed,
		"status": status,
		"gate": gate,
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"issues": issues,
		"issue_count": issues.size(),
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


static func _build_source_blockers(source: Dictionary) -> Array:
	var blockers: Array = []
	if String(source.get("schema", "")).strip_edges() != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_1041-Source-Schema fehlt oder passt nicht."))
	if String(source.get("task_id", "")).strip_edges() != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1041."))
	if String(source.get("status", "")).strip_edges() != "first_contact_acceptance_slice_passed":
		blockers.append(_issue("source_not_passed", "TASK_1041-Source ist nicht first_contact_acceptance_slice_passed."))
	if not bool(source.get("first_contact_acceptance_slice_passed", false)):
		blockers.append(_issue("source_pass_flag_missing", "TASK_1041-Pass-Flag fehlt."))
	if not bool(source.get("ready_for_first_contact_integrated_playtest", false)):
		blockers.append(_issue("source_not_ready_for_first_contact_integrated_playtest", "TASK_1041 ist nicht fuer den First-Contact-Integrated-Playtest freigegeben."))
	var first_contact_line: String = String(source.get("first_contact_acceptance_line", "")).strip_edges()
	if first_contact_line.is_empty():
		blockers.append(_issue("source_first_contact_line_missing", "TASK_1041-First-Contact-Line fehlt."))
	if not _snapshot_is_read_only(source):
		blockers.append(_issue("source_not_read_only", "TASK_1041-Source verletzt die read-only-Grenze."))
	return blockers


static func _completed_integrated_checks(trace: Dictionary) -> Array:
	var completed: Array = []
	for check_id in REQUIRED_INTEGRATED_CHECKS:
		if bool(trace.get(String(check_id), false)):
			completed.append(String(check_id))
	return completed


static func _missing_integrated_checks(completed_checks: Array) -> Array:
	var completed := {}
	for check_variant in completed_checks:
		completed[String(check_variant)] = true
	var missing: Array = []
	for check_id in REQUIRED_INTEGRATED_CHECKS:
		if not completed.has(String(check_id)):
			missing.append(String(check_id))
	return missing


static func _build_trace_issues(trace: Dictionary, missing_checks: Array) -> Array:
	var issues: Array = []
	for check_variant in missing_checks:
		var check_id: String = String(check_variant)
		issues.append(_issue(_issue_id_for_missing_check(check_id), "First-Contact-Integrated-Playtest-Check fehlt: %s" % check_id))
	if Array(trace.get("answered_player_questions", [])).size() < REQUIRED_PLAYER_QUESTIONS.size():
		issues.append(_issue("answered_player_questions_incomplete", "Answered-Player-Questions decken Start, Kontakt, WHY, FIRE/WAIT, GO-Ergebnis, Rueckkehr und Grenzen noch nicht vollstaendig ab."))
	if not _has_required_player_questions(Array(trace.get("answered_player_questions", []))):
		issues.append(_issue("required_player_questions_missing", "Mindestens eine erforderliche First-Contact-Spielerfrage fehlt im Integrated-Trace."))
	if String(trace.get("entry_line", "")).strip_edges().is_empty():
		issues.append(_issue("entry_line_missing", "Integrated-Trace muss eine entry_line fuer den Release-/Mission-Start liefern."))
	if String(trace.get("post_go_line", "")).strip_edges().is_empty():
		issues.append(_issue("post_go_line_missing", "Integrated-Trace muss eine post_go_line fuer FEEDBACK und NEXT liefern."))
	if float(trace.get("observed_frame_budget_ms", 0.0)) <= 0.0:
		issues.append(_issue("observed_frame_budget_missing", "Integrated-Trace muss ein beobachtetes Frame-Budget ausgeben."))
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


static func _has_required_player_questions(answered_questions: Array) -> bool:
	var answered := {}
	for question_variant in answered_questions:
		answered[String(question_variant)] = true
	for question_id in REQUIRED_PLAYER_QUESTIONS:
		if not answered.has(String(question_id)):
			return false
	return true


static func _issue_id_for_missing_check(check_id: String) -> String:
	match check_id:
		"release_mission_context_reached":
			return "release_mission_context_missing"
		"performance_budget_ok":
			return "performance_budget_exceeded"
		_:
			return "%s_missing" % check_id


static func _build_integrated_line(source: Dictionary, trace: Dictionary, trace_available: bool) -> String:
	var source_line: String = String(source.get("first_contact_acceptance_line", "")).strip_edges()
	var base: String = source_line if not source_line.is_empty() else "CONTACT | WHY | NEXT | FIRE/WAIT | GO separat"
	if not base.contains("CONTACT"):
		base = "CONTACT | %s" % base
	if not base.contains("WHY"):
		base = "%s | WHY" % base
	if not base.contains("NEXT"):
		base = "%s | NEXT" % base
	if not base.contains("FIRE/WAIT"):
		base = "%s | FIRE/WAIT" % base
	if not base.contains("GO"):
		base = "%s | GO separat" % base
	var entry_line: String = String(trace.get("entry_line", "")).strip_edges()
	if entry_line.is_empty():
		entry_line = "Release Mission erreicht"
	var feedback_line: String = String(trace.get("post_go_line", "")).strip_edges()
	if feedback_line.is_empty():
		feedback_line = "FEEDBACK sichtbar, NEXT wieder bereit"
	if not feedback_line.contains("FEEDBACK"):
		feedback_line = "FEEDBACK %s" % feedback_line
	if not feedback_line.contains("NEXT"):
		feedback_line = "%s | NEXT" % feedback_line
	if not trace_available:
		return "ENTRY %s | %s | Integrated Playtest offen" % [
			_compact_text(entry_line, 44),
			_compact_text(base, 112),
		]
	return "ENTRY %s | %s | %s" % [
		_compact_text(entry_line, 44),
		_compact_text(base, 112),
		_compact_text(feedback_line, 52),
	]


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
