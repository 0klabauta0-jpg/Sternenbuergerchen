class_name FirstDecisionPlayabilitySmoke
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.first_decision_playability_smoke.v1"
const TASK_ID: String = "TASK_959"
const SOURCE_TASK_ID: String = "TASK_958"
const SOURCE_SCHEMA: String = "sternenbuergerchen.first_decision_real_playthrough_visual_findings.v1"
const SOURCE_ACCEPTED_STATUS: String = "accepted_for_first_decision_playability_smoke"
const NEXT_REVIEW_TASK: String = "TASK_959 - First Decision Playability Smoke"
const NEXT_TASK: String = "TASK_960 - First Decision Release Playable Slice"

const REQUIRED_SMOKE_CHECKS: PackedStringArray = [
	"next_line_visible",
	"why_line_visible",
	"choice_rows_visible",
	"recommendation_obvious",
	"destination_preview_visible",
	"path_preview_visible",
	"risk_levels_visible",
	"line_of_fire_reasons_visible",
	"preview_boundary_clear",
	"no_command_before_go",
	"go_surface_usable",
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
			issues.append(_issue("smoke_trace_missing", "Der First-Decision-Playability-Smoke wurde noch nicht als Trace belegt."))
		else:
			issues = _build_trace_issues(playthrough_trace, missing_checks)
	var smoke_passed: bool = blockers.is_empty() and trace_available and issues.is_empty() and missing_checks.is_empty()
	var gate: String = "blocked"
	var recommended_next_task: String = NEXT_REVIEW_TASK
	var recommended_direction: String = "run_first_decision_playability_smoke_trace"
	if blockers.is_empty():
		if smoke_passed:
			gate = "smoke_passed"
			recommended_next_task = NEXT_TASK
			recommended_direction = "stitch_first_decision_into_release_playable_slice"
		elif trace_available:
			gate = "smoke_regression_found"
			recommended_next_task = NEXT_TASK
			recommended_direction = "fix_first_decision_release_playable_slice_regressions"
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
		blockers.append(_issue("source_schema_mismatch", "TASK_958-Findings-Schema fehlt oder passt nicht."))
	if String(source_findings.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_958."))
	if String(source_findings.get("status", "")) != SOURCE_ACCEPTED_STATUS or not bool(source_findings.get("accepted", false)):
		blockers.append(_issue("source_not_accepted_for_smoke", "TASK_958-Source ist nicht fuer den First-Decision-Smoke akzeptiert."))
	if not bool(source_findings.get("read_only", false)):
		blockers.append(_issue("source_not_read_only", "TASK_958-Source ist nicht read-only."))
	if bool(source_findings.get("ui_sets_gameplay_truth", true)):
		blockers.append(_issue("source_sets_ui_gameplay_truth", "TASK_958-Source darf keine UI-Gameplay-Wahrheit setzen."))
	return blockers


static func _build_trace_issues(playthrough_trace: Dictionary, missing_checks: Array) -> Array:
	var issues: Array = []
	for check_id_variant in missing_checks:
		var check_id: String = String(check_id_variant)
		issues.append(_issue(_issue_id_for_missing_check(check_id), _text_for_missing_check(check_id)))
	if int(playthrough_trace.get("choice_count", 0)) < 3:
		issues.append(_issue("choice_count_too_low", "Der Smoke sieht weniger als drei First-Decision-Choices."))
	if String(playthrough_trace.get("recommended_choice_id", "")).strip_edges().is_empty():
		issues.append(_issue("recommended_choice_missing", "Der Smoke kann keine empfohlene erste Wahl lesen."))
	return issues


static func _missing_smoke_checks(playthrough_trace: Dictionary) -> Array:
	var missing: Array = []
	for check_id in REQUIRED_SMOKE_CHECKS:
		if not bool(playthrough_trace.get(String(check_id), false)):
			missing.append(String(check_id))
	return missing


static func _answered_player_questions(playthrough_trace: Dictionary) -> Array:
	var questions: Array = []
	if bool(playthrough_trace.get("next_line_visible", false)) and bool(playthrough_trace.get("recommendation_obvious", false)):
		questions.append("what_should_i_do_next")
	if bool(playthrough_trace.get("why_line_visible", false)) and bool(playthrough_trace.get("risk_levels_visible", false)):
		questions.append("why_is_that_choice_good")
	if bool(playthrough_trace.get("destination_preview_visible", false)) and bool(playthrough_trace.get("path_preview_visible", false)):
		questions.append("where_will_the_fireteam_go")
	if bool(playthrough_trace.get("preview_boundary_clear", false)) and bool(playthrough_trace.get("no_command_before_go", false)):
		questions.append("what_changes_only_after_go")
	return questions


static func _issue_id_for_missing_check(check_id: String) -> String:
	match check_id:
		"preview_boundary_clear":
			return "preview_boundary_unclear"
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
		"next_line_visible":
			return "Die NEXT-Zeile ist im Smoke nicht sichtbar."
		"why_line_visible":
			return "Die WHY-Zeile ist im Smoke nicht sichtbar."
		"choice_rows_visible":
			return "Die Choice-Zeilen sind im Smoke nicht sichtbar."
		"recommendation_obvious":
			return "Die empfohlene erste Wahl ist im Smoke nicht offensichtlich."
		"destination_preview_visible":
			return "Das Ziel ist vor GO nicht klar sichtbar."
		"path_preview_visible":
			return "Der geplante Pfad ist vor GO nicht klar sichtbar."
		"risk_levels_visible":
			return "Safe/Risky/Suicidal ist vor GO nicht klar lesbar."
		"line_of_fire_reasons_visible":
			return "Die Line-of-Fire-Gruende sind nicht lesbar."
		"preview_boundary_clear":
			return "Die Grenze zwischen Preview und GO ist nicht klar genug."
		"no_command_before_go":
			return "Der Trace bestaetigt nicht, dass vor GO kein Command erzeugt wird."
		"go_surface_usable":
			return "GO oder die passende Command-Flaeche ist nicht gut bedienbar."
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
