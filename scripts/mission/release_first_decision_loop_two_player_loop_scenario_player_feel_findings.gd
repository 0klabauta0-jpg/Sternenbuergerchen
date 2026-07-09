class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioPlayerFeelFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_player_feel_findings.v1"
const TASK_ID: String = "TASK_1015"
const SOURCE_TASK_ID: String = "TASK_1014"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_runtime_smoke.v1"
const REVIEW_TASK: String = "TASK_1015 - Release First Decision Loop Two Player Loop Scenario Player Feel Findings"
const POLISH_TASK: String = "TASK_1016 - Release First Decision Loop Two Player Loop Scenario Player Feel Polish"
const PLAYABILITY_TASK: String = "TASK_1016 - Release First Decision Loop Two Player Loop Scenario Playability Slice"

const PLAYER_FEEL_CHECK_KEYS: Array[String] = [
	"scenario_entry_feels_clear",
	"fob_objective_feels_clear",
	"two_player_roles_feel_clear",
	"next_confirm_go_feels_clear",
	"scenario_feedback_invites_next_grip",
	"hud_feels_calm",
	"performance_feels_responsive",
	"multiplayer_boundary_feels_clear",
]


static func build_snapshot(source_runtime_smoke: Dictionary, player_feel_notes: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_runtime_smoke)
	var source_ready: bool = blockers.is_empty()
	var review_available: bool = bool(player_feel_notes.get("review_available", false))
	var issues: Array = []
	var positive_findings: Array = []
	var status: String = "blocked"
	var gate: String = "scenario_player_feel_blocked"
	var recommended_next_task: String = POLISH_TASK
	var recommended_direction: String = "fix_scenario_runtime_smoke"
	var ready_for_playability: bool = false
	if source_ready:
		positive_findings.append("scenario_runtime_smoke_passed")
		if not review_available:
			status = "needs_scenario_player_feel_review"
			gate = "needs_scenario_player_feel_review"
			issues.append(_issue("scenario_player_feel_review_missing", "Player-Feel-Notizen fuer TASK_1015 fehlen."))
			recommended_next_task = REVIEW_TASK
			recommended_direction = "collect_scenario_player_feel_review"
		else:
			positive_findings.append_array(_positive_findings(player_feel_notes))
			issues = _issues_for_notes(player_feel_notes)
			if issues.is_empty():
				status = "accepted_for_scenario_playability_slice"
				gate = "scenario_player_feel_accepted"
				ready_for_playability = true
				recommended_next_task = PLAYABILITY_TASK
				recommended_direction = "build_scenario_playability_slice"
			else:
				status = "scenario_player_feel_rework_needed"
				gate = "scenario_player_feel_rework_needed"
				recommended_next_task = POLISH_TASK
				recommended_direction = "polish_scenario_player_feel"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_runtime_smoke.get("schema", "")),
		"source_status": String(source_runtime_smoke.get("status", "")),
		"source_gate": String(source_runtime_smoke.get("gate", "")),
		"source_smoke_line": String(source_runtime_smoke.get("smoke_line", "")),
		"source_post_smoke_feedback_line": String(source_runtime_smoke.get("post_smoke_feedback_line", "")),
		"selected_runtime_choice_id": String(source_runtime_smoke.get("selected_runtime_choice_id", "")),
		"source_scenario_runtime_smoke_passed": bool(source_runtime_smoke.get("scenario_runtime_smoke_passed", false)),
		"review_available": review_available,
		"player_feel_check_keys": PLAYER_FEEL_CHECK_KEYS.duplicate(),
		"positive_findings": positive_findings,
		"positive_finding_count": positive_findings.size(),
		"issues": issues,
		"issue_count": issues.size(),
		"primary_issue_id": String(Dictionary((blockers + issues)[0]).get("id", "")) if not (blockers + issues).is_empty() else "",
		"scenario_player_feel_summary_line": _build_summary_line(source_runtime_smoke, player_feel_notes, ready_for_playability, issues),
		"ready_for_scenario_playability_slice": ready_for_playability,
		"status": status,
		"gate": gate,
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
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


static func _build_blockers(source_runtime_smoke: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_runtime_smoke.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_1014-Source-Schema fehlt oder passt nicht."))
	if String(source_runtime_smoke.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1014."))
	if String(source_runtime_smoke.get("status", "")) != "scenario_runtime_smoke_passed":
		blockers.append(_issue("source_not_passed", "TASK_1014-Source ist nicht scenario_runtime_smoke_passed."))
	if not bool(source_runtime_smoke.get("scenario_runtime_smoke_passed", false)):
		blockers.append(_issue("source_pass_flag_missing", "TASK_1014-Pass-Flag fehlt."))
	if String(source_runtime_smoke.get("smoke_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_smoke_line_missing", "TASK_1014-Smoke-Zeile fehlt."))
	if not _snapshot_is_read_only(source_runtime_smoke):
		blockers.append(_issue("source_not_read_only", "TASK_1014-Source verletzt die read-only-Grenze."))
	return blockers


static func _positive_findings(notes: Dictionary) -> Array:
	var findings: Array = []
	for check_id in PLAYER_FEEL_CHECK_KEYS:
		if bool(notes.get(check_id, false)):
			findings.append(check_id)
	return findings


static func _issues_for_notes(notes: Dictionary) -> Array:
	var issues: Array = []
	if not bool(notes.get("scenario_entry_feels_clear", false)):
		issues.append(_issue("scenario_entry_feels_unclear", "FOB-/Szenario-Einstieg fuehlt sich noch unklar an."))
	if not bool(notes.get("fob_objective_feels_clear", false)):
		issues.append(_issue("fob_objective_feels_unclear", "FOB-Ziel und Objective greifen im Spielerblick noch nicht sauber."))
	if not bool(notes.get("two_player_roles_feel_clear", false)):
		issues.append(_issue("two_player_roles_feel_unclear", "Alpha-/Bravo-Rollen lesen sich noch nicht klar genug."))
	if not bool(notes.get("next_confirm_go_feels_clear", false)):
		issues.append(_issue("scenario_go_boundary_not_felt", "NEXT/CONFIRM/GO-Grenze ist im Szenario-Gefuehl nicht klar genug."))
	if not bool(notes.get("scenario_feedback_invites_next_grip", false)):
		issues.append(_issue("scenario_feedback_feels_dry", "Feedback erklaert den naechsten Szenario-Griff noch nicht angenehm genug."))
	if not bool(notes.get("hud_feels_calm", false)):
		issues.append(_issue("scenario_hud_feels_noisy", "Szenario-HUD fuehlt sich noch zu laut oder instabil an."))
	if not bool(notes.get("performance_feels_responsive", false)):
		issues.append(_issue("scenario_performance_feels_sluggish", "Szenario-Loop fuehlt sich nicht responsiv genug an."))
	if not bool(notes.get("multiplayer_boundary_feels_clear", false)):
		issues.append(_issue("scenario_multiplayer_boundary_feels_unclear", "Multiplayer-/Wahrheitsgrenze wirkt im Szenario-Blick unklar."))
	return issues


static func _build_summary_line(source_runtime_smoke: Dictionary, notes: Dictionary, accepted: bool, issues: Array) -> String:
	if accepted:
		var summary: String = String(notes.get("summary", "")).strip_edges()
		if summary.is_empty():
			summary = "FOB/NEXT/GO/FEEDBACK fuehlt sich als kleiner Szenario-Griff rund an."
		return "SCENARIO FEEL PASS: %s" % _compact_text(summary, 112)
	if not issues.is_empty():
		return "SCENARIO FEEL REWORK: %s" % _compact_text(String(Dictionary(issues[0]).get("text", "")), 104)
	var source_line: String = String(source_runtime_smoke.get("smoke_line", "")).strip_edges()
	if source_line.is_empty():
		return ""
	return "SCENARIO FEEL REVIEW: %s" % _compact_text(source_line, 104)


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
