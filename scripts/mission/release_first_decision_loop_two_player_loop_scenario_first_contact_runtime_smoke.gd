class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioFirstContactRuntimeSmoke
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke.v1"
const TASK_ID: String = "TASK_1034"
const SOURCE_TASK_ID: String = "TASK_1033"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook.v1"
const REVIEW_TASK: String = "TASK_1034 - Release First Decision Loop Two Player Loop Scenario First Contact Runtime Smoke"
const POLISH_TASK: String = "TASK_1034 - Release First Decision Loop Two Player Loop Scenario First Contact Runtime Smoke Polish"
const NEXT_TASK: String = "TASK_1035 - Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Findings"

const REQUIRED_SMOKE_CHECKS: Array[String] = [
	"runtime_hook_ready",
	"contact_line_visible",
	"player_questions_answered",
	"contact_hook_visible",
	"why_hook_visible",
	"next_hook_visible",
	"go_still_separate",
	"no_auto_go",
	"real_snapshot_context_used",
	"first_contact_gate_pass",
	"first_engagement_gate_pass",
	"combat_hud_gate_pass",
	"feedback_returns_to_next",
	"hud_read_only_boundary_ok",
	"multiplayer_boundary_preserved",
	"performance_budget_ok",
]

const ISSUE_FLAG_IDS: Array[String] = [
	"contact_line_overwritten",
	"hud_truth_boundary_risk",
	"go_auto_executed",
	"snapshot_context_stale",
	"performance_budget_unclear",
	"multiplayer_boundary_unclear",
]


static func build_snapshot(source_hook: Dictionary, smoke_trace: Dictionary = {}) -> Dictionary:
	var source_blockers: Array = _build_source_blockers(source_hook)
	var completed_checks: Array = _normalize_string_array(smoke_trace.get("completed_smoke_checks", []))
	var issue_flags: Array = _normalize_string_array(smoke_trace.get("issue_flags", []))
	var trace_available: bool = source_blockers.is_empty() and _trace_is_available(smoke_trace)
	var missing_checks: Array = _missing_checks(completed_checks) if trace_available else []
	var issues: Array = []
	var status: String = "blocked_until_first_contact_runtime_hook"
	var gate: String = "blocked_until_first_contact_runtime_hook"
	var passed: bool = false
	var recommended_next_task: String = REVIEW_TASK
	var recommended_direction: String = "run_first_contact_runtime_smoke"

	if not source_blockers.is_empty():
		recommended_direction = "fix_first_contact_runtime_hook"
	elif not trace_available:
		status = "needs_first_contact_runtime_smoke_trace"
		gate = "needs_first_contact_runtime_smoke_trace"
		issues.append(_issue("first_contact_runtime_smoke_trace_missing", "TASK_1034 braucht einen sichtbaren First-Contact-Runtime-Smoke-Trace."))
	elif not issue_flags.is_empty() or not _trace_is_read_only(smoke_trace):
		status = "first_contact_runtime_smoke_regression_found"
		gate = "first_contact_runtime_smoke_regression_found"
		issues = _build_issue_flag_issues(issue_flags)
		if not _trace_is_read_only(smoke_trace):
			issues.append(_issue("first_contact_runtime_smoke_issue_hud_truth_boundary_risk", "Smoke-Trace verletzt die read-only HUD-/Gameplay-Grenze."))
		recommended_next_task = POLISH_TASK
		recommended_direction = "fix_first_contact_runtime_smoke_regression"
	elif not bool(smoke_trace.get("smoke_done", false)) or not missing_checks.is_empty():
		status = "needs_first_contact_runtime_smoke_completion"
		gate = "needs_first_contact_runtime_smoke_completion"
		issues.append(_issue("first_contact_runtime_smoke_checks_missing", "First-Contact-Runtime-Smoke ist noch nicht komplett belegt."))
		recommended_direction = "complete_first_contact_runtime_smoke"
	else:
		status = "first_contact_runtime_smoke_passed"
		gate = "first_contact_runtime_smoke_passed"
		passed = true
		recommended_next_task = NEXT_TASK
		recommended_direction = "capture_first_contact_player_feel_findings"

	issues = _dedupe_issues(issues)
	var all_issues: Array = source_blockers + issues
	var smoke_line: String = _build_smoke_line(status, source_hook, smoke_trace)
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_hook.get("schema", "")),
		"source_status": String(source_hook.get("status", "")),
		"source_gate": String(source_hook.get("gate", "")),
		"source_runtime_line": String(source_hook.get("first_contact_runtime_line", "")),
		"status": status,
		"gate": gate,
		"active": passed,
		"first_contact_runtime_smoke_passed": passed,
		"ready_for_first_contact_player_feel_findings": passed,
		"first_contact_runtime_smoke_line": smoke_line,
		"mission_control_runtime_smoke_line": smoke_line,
		"selected_fireteam_runtime_smoke_line": _build_selected_fireteam_line(status, source_hook),
		"required_smoke_checks": REQUIRED_SMOKE_CHECKS.duplicate(),
		"completed_smoke_checks": completed_checks,
		"missing_smoke_checks": missing_checks,
		"trace_available": trace_available,
		"smoke_done": bool(smoke_trace.get("smoke_done", false)),
		"issue_flags": issue_flags,
		"post_smoke_feedback_line": String(smoke_trace.get("post_smoke_feedback_line", "")),
		"player_question_answers": Dictionary(source_hook.get("player_question_answers", {})).duplicate(true),
		"command_matrix_runtime_hooks": Array(source_hook.get("command_matrix_runtime_hooks", [])).duplicate(true),
		"first_contact_readability": Dictionary(source_hook.get("first_contact_readability", {})).duplicate(true),
		"first_engagement_feedback": Dictionary(source_hook.get("first_engagement_feedback", {})).duplicate(true),
		"combat_hud_density": Dictionary(source_hook.get("combat_hud_density", {})).duplicate(true),
		"checks_real_snapshot_context": completed_checks.has("real_snapshot_context_used"),
		"requires_real_snapshot_context": true,
		"requires_existing_go_path": true,
		"separate_go_required": true,
		"auto_confirms": false,
		"auto_executes_go": false,
		"issues": issues,
		"issue_count": issues.size(),
		"blocking_issues": source_blockers,
		"blocking_issue_count": source_blockers.size(),
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


static func _build_source_blockers(source_hook: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_hook.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_1033-Source-Schema fehlt oder passt nicht."))
	if String(source_hook.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1033."))
	if String(source_hook.get("status", "")) != "first_contact_runtime_hook_ready":
		blockers.append(_issue("source_hook_not_ready", "TASK_1033 First-Contact-Runtime-Hook ist nicht bereit."))
	if not bool(source_hook.get("first_contact_runtime_hook_ready", false)):
		blockers.append(_issue("source_hook_not_ready", "TASK_1033 Ready-Flag fehlt."))
	if not String(source_hook.get("first_contact_runtime_line", "")).contains("CONTACT"):
		blockers.append(_issue("source_hook_not_ready", "TASK_1033 Runtime-Line nennt CONTACT nicht."))
	if not String(source_hook.get("first_contact_runtime_line", "")).contains("GO separat"):
		blockers.append(_issue("source_hook_not_ready", "TASK_1033 Runtime-Line haelt GO nicht separat."))
	if not _has_required_hooks(source_hook):
		blockers.append(_issue("source_hook_not_ready", "TASK_1033 Command-Matrix-Hooks sind nicht vollstaendig."))
	if not _source_has_player_answers(source_hook):
		blockers.append(_issue("source_hook_not_ready", "TASK_1033 beantwortet die Spielerfragen nicht vollstaendig."))
	if not _source_reused_gates_pass(source_hook):
		blockers.append(_issue("source_hook_not_ready", "TASK_1033 Runtime-Kontext ist nicht durchgaengig gruen."))
	if not _snapshot_is_read_only(source_hook):
		blockers.append(_issue("source_hook_not_ready", "TASK_1033 verletzt die read-only-Grenze."))
	return _dedupe_issues(blockers)


static func _trace_is_available(smoke_trace: Dictionary) -> bool:
	if bool(smoke_trace.get("trace_available", false)):
		return true
	return not smoke_trace.is_empty()


static func _trace_is_read_only(smoke_trace: Dictionary) -> bool:
	return not bool(smoke_trace.get("ui_sets_gameplay_truth", false)) \
		and not bool(smoke_trace.get("creates_command", false)) \
		and not bool(smoke_trace.get("creates_movement", false)) \
		and not bool(smoke_trace.get("creates_fire_event", false)) \
		and not bool(smoke_trace.get("creates_damage_event", false)) \
		and not bool(smoke_trace.get("sets_multiplayer_truth", false))


static func _missing_checks(completed_checks: Array) -> Array:
	var missing: Array = []
	for check_id in REQUIRED_SMOKE_CHECKS:
		if not completed_checks.has(check_id):
			missing.append(check_id)
	return missing


static func _build_issue_flag_issues(issue_flags: Array) -> Array:
	var issues: Array = []
	for flag_variant in issue_flags:
		var flag_id: String = String(flag_variant)
		match flag_id:
			"contact_line_overwritten":
				issues.append(_issue("first_contact_runtime_smoke_issue_contact_line_overwritten", "CONTACT-Line wurde im Smoke sichtbar ueberschrieben."))
			"hud_truth_boundary_risk":
				issues.append(_issue("first_contact_runtime_smoke_issue_hud_truth_boundary_risk", "HUD-/Gameplay-Wahrheitsgrenze wirkt im Smoke riskant."))
			"go_auto_executed":
				issues.append(_issue("first_contact_runtime_smoke_issue_go_auto_executed", "GO wurde im Smoke nicht separat gehalten."))
			"snapshot_context_stale":
				issues.append(_issue("first_contact_runtime_smoke_issue_snapshot_context_stale", "Smoke nutzt keinen frischen Snapshot-Kontext."))
			"performance_budget_unclear":
				issues.append(_issue("first_contact_runtime_smoke_issue_performance_budget_unclear", "Performance-Budget ist im Smoke nicht belegt."))
			"multiplayer_boundary_unclear":
				issues.append(_issue("first_contact_runtime_smoke_issue_multiplayer_boundary_unclear", "Multiplayer-Grenze bleibt im Smoke unklar."))
			_:
				issues.append(_issue("first_contact_runtime_smoke_issue_%s" % flag_id, "First-Contact-Runtime-Smoke meldet %s." % flag_id))
	return _dedupe_issues(issues)


static func _has_required_hooks(source_hook: Dictionary) -> bool:
	var hook_ids := {}
	for hook_variant in Array(source_hook.get("command_matrix_runtime_hooks", [])):
		if typeof(hook_variant) != TYPE_DICTIONARY:
			continue
		var hook: Dictionary = Dictionary(hook_variant)
		if bool(hook.get("enabled", false)) and bool(hook.get("read_only", false)):
			hook_ids[String(hook.get("hook_id", ""))] = true
	return hook_ids.has("contact") and hook_ids.has("why") and hook_ids.has("next") and hook_ids.has("go")


static func _source_has_player_answers(source_hook: Dictionary) -> bool:
	var answers: Dictionary = Dictionary(source_hook.get("player_question_answers", {}))
	return answers.size() >= 4


static func _source_reused_gates_pass(source_hook: Dictionary) -> bool:
	return String(Dictionary(source_hook.get("first_contact_readability", {})).get("gate", "")) == "pass" \
		and String(Dictionary(source_hook.get("first_engagement_feedback", {})).get("gate", "")) == "pass" \
		and String(Dictionary(source_hook.get("combat_hud_density", {})).get("gate", "")) == "pass"


static func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", false)) \
		and not bool(snapshot.get("creates_command", false)) \
		and not bool(snapshot.get("creates_movement", false)) \
		and not bool(snapshot.get("creates_fire_event", false)) \
		and not bool(snapshot.get("creates_damage_event", false)) \
		and not bool(snapshot.get("sets_multiplayer_truth", false))


static func _build_smoke_line(status: String, source_hook: Dictionary, smoke_trace: Dictionary) -> String:
	if status == "first_contact_runtime_smoke_passed":
		var feedback: String = String(smoke_trace.get("post_smoke_feedback_line", "")).strip_edges()
		if feedback.is_empty():
			feedback = "FEEDBACK sichtbar"
		return "CONTACT SMOKE PASS: CONTACT | WHY | NEXT | GO separat | %s" % feedback
	if status == "blocked_until_first_contact_runtime_hook":
		return "CONTACT SMOKE BLOCKED: TASK_1033 First-Contact-Runtime-Hook fehlt."
	if status == "needs_first_contact_runtime_smoke_trace":
		return "CONTACT SMOKE OFFEN: CONTACT | WHY | NEXT | GO separat | FEEDBACK im echten Snapshot pruefen."
	if status == "needs_first_contact_runtime_smoke_completion":
		return "CONTACT SMOKE CHECK: CONTACT | WHY | NEXT | GO separat | FEEDBACK noch nicht vollstaendig belegt."
	return "CONTACT SMOKE REVIEW: CONTACT | WHY | NEXT | GO separat | FEEDBACK auffaellig."


static func _build_selected_fireteam_line(status: String, source_hook: Dictionary) -> String:
	var source_line: String = String(source_hook.get("selected_fireteam_runtime_line", "")).strip_edges()
	if source_line.is_empty():
		source_line = "FT | CONTACT/WHY/NEXT lesen | GO separat"
	return "%s | SMOKE %s" % [source_line, status]


static func _normalize_string_array(value: Variant) -> Array:
	var result: Array = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for entry_variant in Array(value):
		var entry: String = String(entry_variant)
		if entry.is_empty() or result.has(entry):
			continue
		result.append(entry)
	return result


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


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
