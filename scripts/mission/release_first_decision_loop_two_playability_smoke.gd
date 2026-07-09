class_name ReleaseFirstDecisionLoopTwoPlayabilitySmoke
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_playability_smoke.v1"
const TASK_ID: String = "TASK_972"
const SOURCE_TASK_ID: String = "TASK_971"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_visual_polish.v1"
const NEXT_TASK: String = "TASK_973 - Release First Decision Loop Two Real Window Recapture"
const POLISH_TASK: String = "TASK_971 - Release First Decision Loop Two Visual Polish"

const REQUIRED_SMOKE_CHECKS: PackedStringArray = [
	"second_decision_button_visible",
	"second_decision_confirmed",
	"go_button_still_separate",
	"go_executed_after_confirm",
	"post_go_feedback_visible",
	"no_go_before_second_confirm",
	"no_new_hud_gameplay_truth",
	"multiplayer_boundary_preserved",
]


static func build_snapshot(visual_polish: Dictionary, playability_trace: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_source_blockers(visual_polish)
	var trace_available: bool = bool(playability_trace.get("trace_available", false)) or not playability_trace.is_empty()
	var issues: Array = []
	if blockers.is_empty():
		if not trace_available:
			issues.append(_issue("playability_trace_missing", "TASK_972-Trace fuer 2ND -> GO -> Feedback fehlt."))
		else:
			issues = _build_trace_issues(playability_trace)
	var passed: bool = blockers.is_empty() and trace_available and issues.is_empty()
	var status: String = "blocked"
	var gate: String = "blocked"
	var recommended_next_task: String = POLISH_TASK
	var recommended_direction: String = "fix_loop_two_playability_source"
	if blockers.is_empty():
		if passed:
			status = "loop_two_playability_smoke_passed"
			gate = "loop_two_playability_smoke_passed"
			recommended_next_task = NEXT_TASK
			recommended_direction = "recapture_loop_two_real_window"
		elif trace_available:
			status = "loop_two_playability_regression_found"
			gate = "loop_two_playability_regression_found"
			recommended_next_task = POLISH_TASK
			recommended_direction = "tighten_loop_two_visual_polish"
		else:
			status = "needs_playability_smoke_run"
			gate = "needs_loop_two_playability_smoke_run"
			recommended_next_task = "TASK_972 - Release First Decision Loop Two Playability Smoke"
			recommended_direction = "run_loop_two_playability_smoke"
	var smoke_line: String = _build_smoke_line(visual_polish, playability_trace, passed, trace_available)
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(visual_polish.get("schema", "")),
		"source_status": String(visual_polish.get("status", "")),
		"source_button_text": String(visual_polish.get("button_text", "")),
		"source_hud_line": String(visual_polish.get("hud_line", "")),
		"source_go_separation_line": String(visual_polish.get("go_separation_line", "")),
		"trace_available": trace_available,
		"required_smoke_checks": Array(REQUIRED_SMOKE_CHECKS),
		"completed_checks": Array(playability_trace.get("completed_checks", [])).duplicate(true),
		"missing_smoke_checks": _missing_checks(Array(playability_trace.get("completed_checks", []))),
		"second_decision_button_visible": bool(playability_trace.get("second_decision_button_visible", false)),
		"second_decision_confirmed": bool(playability_trace.get("second_decision_confirmed", false)),
		"go_button_still_separate": bool(playability_trace.get("go_button_still_separate", false)),
		"go_executed_after_confirm": bool(playability_trace.get("go_executed_after_confirm", false)),
		"post_go_feedback_visible": bool(playability_trace.get("post_go_feedback_visible", false)),
		"post_go_feedback_line": String(playability_trace.get("post_go_feedback_line", "")),
		"no_go_before_second_confirm": bool(playability_trace.get("no_go_before_second_confirm", false)),
		"no_new_hud_gameplay_truth": bool(playability_trace.get("no_new_hud_gameplay_truth", false)),
		"multiplayer_boundary_preserved": bool(playability_trace.get("multiplayer_boundary_preserved", false)),
		"smoke_line": smoke_line,
		"playability_smoke_passed": passed,
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


static func _build_source_blockers(visual_polish: Dictionary) -> Array:
	var blockers: Array = []
	if String(visual_polish.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_971-Source-Schema fehlt oder passt nicht."))
	if String(visual_polish.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_971."))
	if String(visual_polish.get("status", "")) != "visual_polish_ready":
		blockers.append(_issue("source_not_ready", "TASK_971-Visual-Polish ist nicht bereit."))
	if not bool(visual_polish.get("active", false)):
		blockers.append(_issue("source_not_active", "TASK_971-Visual-Polish ist nicht aktiv."))
	if not bool(visual_polish.get("button_enabled", false)):
		blockers.append(_issue("source_button_disabled", "TASK_971-2ND-Button ist nicht aktiv."))
	if String(visual_polish.get("button_text", "")) != "2ND":
		blockers.append(_issue("source_button_text_mismatch", "TASK_971-Buttontext ist nicht 2ND."))
	if not _snapshot_is_read_only(visual_polish):
		blockers.append(_issue("source_not_read_only", "TASK_971-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_trace_issues(playability_trace: Dictionary) -> Array:
	var issues: Array = []
	if not bool(playability_trace.get("second_decision_button_visible", false)):
		issues.append(_issue("second_decision_button_not_visible", "2ND war im Smoke nicht sichtbar."))
	if not bool(playability_trace.get("second_decision_confirmed", false)):
		issues.append(_issue("second_decision_not_confirmed", "2ND wurde im Smoke nicht bestaetigt."))
	if not bool(playability_trace.get("go_button_still_separate", false)):
		issues.append(_issue("go_button_not_separate", "GO blieb im Smoke nicht klar separat."))
	if not bool(playability_trace.get("go_executed_after_confirm", false)):
		issues.append(_issue("go_not_executed", "GO wurde nach 2ND nicht ausgefuehrt."))
	if not bool(playability_trace.get("post_go_feedback_visible", false)):
		issues.append(_issue("post_go_feedback_missing", "Nach GO war kein Feedback sichtbar."))
	if not bool(playability_trace.get("no_go_before_second_confirm", false)):
		issues.append(_issue("go_before_second_confirm_risk", "Der Smoke bestaetigt die Pre-GO-Grenze nicht."))
	if not bool(playability_trace.get("no_new_hud_gameplay_truth", false)):
		issues.append(_issue("hud_gameplay_truth_risk", "Der Smoke bestaetigt die HUD-read-only-Grenze nicht."))
	if not bool(playability_trace.get("multiplayer_boundary_preserved", false)):
		issues.append(_issue("multiplayer_boundary_risk", "Der Smoke bestaetigt die Multiplayer-Grenze nicht."))
	if bool(playability_trace.get("ui_sets_gameplay_truth", false)):
		issues.append(_issue("ui_sets_gameplay_truth", "Trace meldet UI-Gameplay-Wahrheit."))
	if bool(playability_trace.get("creates_command", false)):
		issues.append(_issue("trace_creates_command", "Trace selbst darf keinen Command erzeugen."))
	if bool(playability_trace.get("creates_movement", false)):
		issues.append(_issue("trace_creates_movement", "Trace selbst darf kein Movement erzeugen."))
	if bool(playability_trace.get("sets_multiplayer_truth", false)):
		issues.append(_issue("trace_sets_multiplayer_truth", "Trace selbst darf keine Multiplayer-Wahrheit setzen."))
	return issues


static func _missing_checks(completed_checks: Array) -> Array:
	var completed := {}
	for check_variant in completed_checks:
		completed[String(check_variant)] = true
	var missing: Array = []
	for check_id in REQUIRED_SMOKE_CHECKS:
		if not completed.has(String(check_id)):
			missing.append(String(check_id))
	return missing


static func _build_smoke_line(visual_polish: Dictionary, playability_trace: Dictionary, passed: bool, trace_available: bool) -> String:
	if not trace_available:
		return "2ND -> GO -> Feedback | Smoke offen"
	var result_text: String = "PASS" if passed else "CHECK"
	var feedback_line: String = String(playability_trace.get("post_go_feedback_line", "")).strip_edges()
	var source_line: String = String(visual_polish.get("hud_line", "2ND | GO separat")).strip_edges()
	var line: String = "2ND -> GO -> Feedback %s | %s" % [result_text, source_line]
	if not feedback_line.is_empty():
		line += " | %s" % feedback_line
	return line


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
