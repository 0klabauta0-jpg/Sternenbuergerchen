class_name ReleaseFirstDecisionLoopTwoPlayerLoopMicroObjectiveRoundLoopPlayerFeelFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings.v1"
const TASK_ID: String = "TASK_1009"
const SOURCE_TASK_ID: String = "TASK_1008"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_integrated_playtest.v1"
const POLISH_TASK: String = "TASK_1010 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Polish"
const ACCEPTANCE_TASK: String = "TASK_1010 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Acceptance Slice"

const PLAYER_FEEL_CHECK_KEYS: Array[String] = [
	"entry_feels_clear",
	"round_next_go_rhythm_feels_clear",
	"feedback_invites_next_grip",
	"go_boundary_feels_clear",
	"hud_feels_calm",
	"performance_feels_responsive",
	"multiplayer_boundary_feels_clear",
]


static func build_snapshot(source_integrated_playtest: Dictionary, player_feel_notes: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_integrated_playtest)
	var source_ready: bool = blockers.is_empty()
	var review_available: bool = bool(player_feel_notes.get("review_available", false))
	var issues: Array = []
	var positive_findings: Array = []
	var status: String = "blocked"
	var gate: String = "round_loop_player_feel_blocked"
	var recommended_next_task: String = POLISH_TASK
	var ready_for_acceptance: bool = false
	if source_ready:
		positive_findings.append("round_loop_integrated_path_present")
		if not review_available:
			status = "needs_player_feel_review"
			gate = "needs_player_feel_review"
			issues.append(_issue("player_feel_review_missing", "Player-Feel-Notizen fuer TASK_1009 fehlen."))
			recommended_next_task = "TASK_1009 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Findings"
		else:
			positive_findings.append_array(_positive_findings(player_feel_notes))
			issues = _issues_for_notes(player_feel_notes)
			if issues.is_empty():
				status = "accepted_for_round_loop_acceptance_slice"
				gate = "round_loop_player_feel_accepted"
				ready_for_acceptance = true
				recommended_next_task = ACCEPTANCE_TASK
			else:
				status = "round_loop_player_feel_rework_needed"
				gate = "round_loop_player_feel_rework_needed"
				recommended_next_task = POLISH_TASK
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_integrated_playtest.get("schema", "")),
		"source_status": String(source_integrated_playtest.get("status", "")),
		"source_gate": String(source_integrated_playtest.get("gate", "")),
		"source_integrated_playtest_line": String(source_integrated_playtest.get("integrated_playtest_line", "")),
		"source_ready_for_player_feel_findings": bool(source_integrated_playtest.get("ready_for_player_feel_findings", false)),
		"review_available": review_available,
		"player_feel_check_keys": PLAYER_FEEL_CHECK_KEYS.duplicate(),
		"positive_findings": positive_findings,
		"positive_finding_count": positive_findings.size(),
		"issues": issues,
		"issue_count": issues.size(),
		"primary_issue_id": String(Dictionary((blockers + issues)[0]).get("id", "")) if not (blockers + issues).is_empty() else "",
		"player_feel_summary_line": _build_summary_line(source_integrated_playtest, player_feel_notes, ready_for_acceptance, issues),
		"ready_for_round_loop_acceptance_slice": ready_for_acceptance,
		"status": status,
		"gate": gate,
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"recommended_next_task": recommended_next_task,
		"recommended_direction": "build_round_loop_acceptance_slice" if ready_for_acceptance else ("collect_player_feel_review" if source_ready and not review_available else "polish_round_loop_player_feel"),
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


static func _build_blockers(source_integrated_playtest: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_integrated_playtest.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_1008-Source-Schema fehlt oder passt nicht."))
	if String(source_integrated_playtest.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1008."))
	if String(source_integrated_playtest.get("status", "")) != "round_loop_integrated_playtest_passed":
		blockers.append(_issue("source_not_passed", "TASK_1008-Source ist nicht round_loop_integrated_playtest_passed."))
	if not bool(source_integrated_playtest.get("round_loop_integrated_playtest_passed", false)):
		blockers.append(_issue("source_pass_flag_missing", "TASK_1008-Pass-Flag fehlt."))
	if not bool(source_integrated_playtest.get("ready_for_player_feel_findings", false)):
		blockers.append(_issue("source_not_ready_for_player_feel_findings", "TASK_1008 ist nicht fuer Player-Feel-Findings freigegeben."))
	if String(source_integrated_playtest.get("integrated_playtest_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_integrated_playtest_line_missing", "TASK_1008-Integrated-Playtest-Zeile fehlt."))
	if not _snapshot_is_read_only(source_integrated_playtest):
		blockers.append(_issue("source_not_read_only", "TASK_1008-Source verletzt die read-only-Grenze."))
	return blockers


static func _positive_findings(notes: Dictionary) -> Array:
	var findings: Array = []
	if bool(notes.get("entry_feels_clear", false)):
		findings.append("entry_feels_clear")
	if bool(notes.get("round_next_go_rhythm_feels_clear", false)):
		findings.append("round_next_go_rhythm_feels_clear")
	if bool(notes.get("feedback_invites_next_grip", false)):
		findings.append("feedback_invites_next_grip")
	if bool(notes.get("go_boundary_feels_clear", false)):
		findings.append("go_boundary_feels_clear")
	if bool(notes.get("hud_feels_calm", false)):
		findings.append("hud_feels_calm")
	if bool(notes.get("performance_feels_responsive", false)):
		findings.append("performance_feels_responsive")
	if bool(notes.get("multiplayer_boundary_feels_clear", false)):
		findings.append("multiplayer_boundary_feels_clear")
	return findings


static func _issues_for_notes(notes: Dictionary) -> Array:
	var issues: Array = []
	if not bool(notes.get("entry_feels_clear", false)):
		issues.append(_issue("entry_feels_unclear", "Entry/Start fuehlt sich noch unklar an."))
	if not bool(notes.get("round_next_go_rhythm_feels_clear", false)):
		issues.append(_issue("round_next_go_rhythm_not_clear", "ROUND/NEXT/GO liest sich noch nicht als Rhythmus."))
	if not bool(notes.get("feedback_invites_next_grip", false)):
		issues.append(_issue("feedback_feels_dry", "Feedback erklaert den naechsten Griff noch nicht angenehm genug."))
	if not bool(notes.get("go_boundary_feels_clear", false)):
		issues.append(_issue("go_boundary_not_felt", "Confirm-/GO-Grenze ist im Gefuehl nicht klar genug."))
	if not bool(notes.get("hud_feels_calm", false)):
		issues.append(_issue("hud_feels_noisy", "HUD fuehlt sich noch zu laut oder instabil an."))
	if not bool(notes.get("performance_feels_responsive", false)):
		issues.append(_issue("performance_feels_sluggish", "Round-Loop fuehlt sich nicht responsiv genug an."))
	if not bool(notes.get("multiplayer_boundary_feels_clear", false)):
		issues.append(_issue("multiplayer_boundary_feels_unclear", "Multiplayer-/Wahrheitsgrenze wirkt im Spielerblick unklar."))
	return issues


static func _build_summary_line(source_integrated_playtest: Dictionary, notes: Dictionary, accepted: bool, issues: Array) -> String:
	if accepted:
		var summary: String = String(notes.get("summary", "")).strip_edges()
		if summary.is_empty():
			summary = "ROUND/NEXT/GO/FEEDBACK fuehlt sich rund an."
		return "FEEL PASS: %s" % _compact_text(summary, 104)
	if not issues.is_empty():
		return "FEEL REWORK: %s" % _compact_text(String(Dictionary(issues[0]).get("text", "")), 96)
	var source_line: String = String(source_integrated_playtest.get("integrated_playtest_line", "")).strip_edges()
	if source_line.is_empty():
		return ""
	return "FEEL REVIEW: %s" % _compact_text(source_line, 96)


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
