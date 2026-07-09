class_name DecisionOverlayPlayabilitySmoke
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.decision_overlay_playability_smoke.v1"
const TASK_ID: String = "TASK_955"
const SOURCE_TASK_ID: String = "TASK_954"
const SOURCE_SCHEMA: String = "sternenbuergerchen.decision_overlay_real_window_visual_findings.v1"
const SOURCE_ACCEPTED_STATUS: String = "accepted_for_decision_overlay_playability_smoke"
const NEXT_REVIEW_TASK: String = "TASK_955 - Decision Overlay Playability Smoke"
const NEXT_TASK: String = "TASK_956 - First Decision Micro Scenario Polish"

const REQUIRED_SMOKE_CHECKS: PackedStringArray = [
	"destination_preview_visible",
	"path_preview_visible",
	"risk_levels_visible",
	"safe_risky_suicidal_order_visible",
	"line_of_fire_reasons_visible",
	"best_choice_readable",
	"go_boundary_preserved",
	"no_command_before_go",
	"command_surfaces_usable",
	"go_can_be_confirmed",
	"post_go_feedback_visible",
	"performance_hotpath_ok",
	"no_new_hud_gameplay_truth",
]


static func build_snapshot(source_findings: Dictionary, playthrough_trace: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_findings)
	var trace_available: bool = bool(playthrough_trace.get("trace_available", false))
	var missing_checks: Array = _missing_smoke_checks(playthrough_trace)
	var issues: Array = []
	if blockers.is_empty():
		if not trace_available:
			issues.append(_issue("smoke_trace_missing", "Der Decision-Overlay-Playability-Smoke wurde noch nicht als Trace belegt."))
		else:
			issues = _build_trace_issues(playthrough_trace, missing_checks)
	var smoke_passed: bool = blockers.is_empty() and trace_available and issues.is_empty() and missing_checks.is_empty()
	var gate: String = "blocked"
	var recommended_next_task: String = NEXT_REVIEW_TASK
	var recommended_direction: String = "run_decision_overlay_playability_smoke_trace"
	if blockers.is_empty():
		if smoke_passed:
			gate = "smoke_passed"
			recommended_next_task = NEXT_TASK
			recommended_direction = "polish_first_decision_micro_scenario_from_smoke_evidence"
		elif trace_available:
			gate = "smoke_regression_found"
			recommended_next_task = NEXT_TASK
			recommended_direction = "fix_first_decision_micro_scenario_regressions"
		else:
			gate = "needs_smoke_run"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_findings.get("schema", "")),
		"source_status": String(source_findings.get("status", "")),
		"source_accepted": bool(source_findings.get("accepted", false)),
		"source_window_screenshot_path": String(source_findings.get("window_screenshot_path", "")),
		"decision_surface": String(playthrough_trace.get("decision_surface", "")),
		"fireteam_id": String(playthrough_trace.get("fireteam_id", "")),
		"choice_count": int(playthrough_trace.get("choice_count", 0)),
		"recommended_choice_id": String(playthrough_trace.get("recommended_choice_id", "")),
		"trace_available": trace_available,
		"required_smoke_checks": Array(REQUIRED_SMOKE_CHECKS),
		"missing_smoke_checks": missing_checks,
		"missing_smoke_check_count": missing_checks.size(),
		"answered_player_questions": _answered_player_questions(playthrough_trace) if trace_available else [],
		"smoke_passed": smoke_passed,
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


static func _build_blockers(source_findings: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_findings.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_954-Findings-Schema fehlt oder passt nicht."))
	if String(source_findings.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_954."))
	if String(source_findings.get("status", "")) != SOURCE_ACCEPTED_STATUS or not bool(source_findings.get("accepted", false)):
		blockers.append(_issue("source_not_accepted_for_smoke", "TASK_954-Source ist nicht fuer den Playability-Smoke akzeptiert."))
	if not bool(source_findings.get("read_only", false)):
		blockers.append(_issue("source_not_read_only", "TASK_954-Source ist nicht read-only."))
	if bool(source_findings.get("ui_sets_gameplay_truth", true)):
		blockers.append(_issue("source_sets_ui_gameplay_truth", "TASK_954-Source darf keine UI-Gameplay-Wahrheit setzen."))
	return blockers


static func _build_trace_issues(playthrough_trace: Dictionary, missing_checks: Array) -> Array:
	var issues: Array = []
	for check_id_variant in missing_checks:
		var check_id: String = String(check_id_variant)
		issues.append(_issue(_issue_id_for_missing_check(check_id), _text_for_missing_check(check_id)))
	if int(playthrough_trace.get("choice_count", 0)) < 3:
		issues.append(_issue("choice_count_too_low", "Der Smoke sieht weniger als drei Decision-Choices."))
	if String(playthrough_trace.get("recommended_choice_id", "")).strip_edges().is_empty():
		issues.append(_issue("recommended_choice_missing", "Der Smoke kann keine empfohlene Wahl lesen."))
	return issues


static func _missing_smoke_checks(playthrough_trace: Dictionary) -> Array:
	var missing: Array = []
	for check_id in REQUIRED_SMOKE_CHECKS:
		if not bool(playthrough_trace.get(String(check_id), false)):
			missing.append(String(check_id))
	return missing


static func _answered_player_questions(playthrough_trace: Dictionary) -> Array:
	var questions: Array = []
	if bool(playthrough_trace.get("destination_preview_visible", false)) and bool(playthrough_trace.get("path_preview_visible", false)):
		questions.append("where_will_the_fireteam_go")
	if bool(playthrough_trace.get("risk_levels_visible", false)) and bool(playthrough_trace.get("line_of_fire_reasons_visible", false)):
		questions.append("why_is_this_move_risky")
	if bool(playthrough_trace.get("best_choice_readable", false)) and not String(playthrough_trace.get("recommended_choice_id", "")).strip_edges().is_empty():
		questions.append("which_choice_is_best")
	if bool(playthrough_trace.get("go_boundary_preserved", false)) and bool(playthrough_trace.get("no_command_before_go", false)):
		questions.append("what_changes_only_after_go")
	return questions


static func _issue_id_for_missing_check(check_id: String) -> String:
	match check_id:
		"go_boundary_preserved":
			return "go_boundary_not_preserved"
		"post_go_feedback_visible":
			return "post_go_feedback_missing"
		"no_command_before_go":
			return "pre_go_command_created"
		"no_new_hud_gameplay_truth":
			return "hud_gameplay_truth_risk"
		_:
			return "%s_missing" % check_id


static func _text_for_missing_check(check_id: String) -> String:
	match check_id:
		"destination_preview_visible":
			return "Das Ziel ist vor GO nicht klar sichtbar."
		"path_preview_visible":
			return "Der geplante Pfad ist vor GO nicht klar sichtbar."
		"risk_levels_visible":
			return "Safe/Risky/Suicidal ist vor GO nicht klar lesbar."
		"safe_risky_suicidal_order_visible":
			return "Die Risikoreihenfolge ist nicht stabil lesbar."
		"line_of_fire_reasons_visible":
			return "Die Line-of-Fire-Gruende sind nicht lesbar."
		"best_choice_readable":
			return "Die beste Wahl ist nicht ausreichend erkennbar."
		"go_boundary_preserved":
			return "Die Grenze zwischen Preview und GO ist nicht belegt."
		"no_command_before_go":
			return "Der Trace bestaetigt nicht, dass vor GO kein Command erzeugt wird."
		"command_surfaces_usable":
			return "Die Command-Surfaces sind im Smoke nicht ausreichend bedienbar."
		"go_can_be_confirmed":
			return "GO kann im Smoke nicht sauber bestaetigt werden."
		"post_go_feedback_visible":
			return "Nach GO fehlt sichtbares Feedback."
		"performance_hotpath_ok":
			return "Der Smoke bestaetigt keine Hotpath-Ruhe."
		"no_new_hud_gameplay_truth":
			return "Der Smoke bestaetigt die read-only HUD-Grenze nicht."
		_:
			return "Ein Pflichtcheck fehlt: %s." % check_id


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
