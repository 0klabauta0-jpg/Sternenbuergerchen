class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioIntegratedPlayerFeelFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings.v1"
const TASK_ID: String = "TASK_1022"
const SOURCE_TASK_ID: String = "TASK_1021"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_integrated_playtest.v1"
const REVIEW_TASK: String = "TASK_1022 - Release First Decision Loop Two Player Loop Scenario Player Feel Findings"
const POLISH_TASK: String = "TASK_1023 - Release First Decision Loop Two Player Loop Scenario Player Feel Polish"
const ACCEPTANCE_TASK: String = "TASK_1023 - Release First Decision Loop Two Player Loop Scenario Small Game Acceptance Slice"

const PLAYER_FEEL_CHECK_KEYS: Array[String] = [
	"integrated_entry_feels_clear",
	"fob_grip_feels_round",
	"next_confirm_go_feels_clear",
	"post_go_feedback_invites_next_grip",
	"loop_returns_without_confusion",
	"hud_feels_calm",
	"performance_feels_responsive",
	"multiplayer_boundary_feels_clear",
	"two_player_context_feels_clear",
	"small_game_feels_round",
]


static func build_snapshot(source_integrated_playtest: Dictionary, player_feel_notes: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_integrated_playtest)
	var source_ready: bool = blockers.is_empty()
	var review_available: bool = bool(player_feel_notes.get("review_available", false))
	var issues: Array = []
	var positive_findings: Array = []
	var status: String = "blocked"
	var gate: String = "scenario_integrated_player_feel_blocked"
	var recommended_next_task: String = POLISH_TASK
	var recommended_direction: String = "fix_scenario_integrated_playtest"
	var ready_for_acceptance: bool = false
	if source_ready:
		positive_findings.append("scenario_integrated_playtest_passed")
		if not review_available:
			status = "needs_scenario_integrated_player_feel_review"
			gate = "needs_scenario_integrated_player_feel_review"
			issues.append(_issue("scenario_integrated_player_feel_review_missing", "Player-Feel-Notizen fuer TASK_1022 fehlen."))
			recommended_next_task = REVIEW_TASK
			recommended_direction = "collect_scenario_integrated_player_feel_review"
		else:
			positive_findings.append_array(_positive_findings(player_feel_notes))
			issues = _issues_for_notes(player_feel_notes)
			if issues.is_empty():
				status = "accepted_for_small_game_acceptance_slice"
				gate = "scenario_integrated_player_feel_accepted"
				ready_for_acceptance = true
				recommended_next_task = ACCEPTANCE_TASK
				recommended_direction = "build_small_game_acceptance_slice"
			else:
				status = "scenario_integrated_player_feel_rework_needed"
				gate = "scenario_integrated_player_feel_rework_needed"
				recommended_next_task = POLISH_TASK
				recommended_direction = "polish_scenario_integrated_player_feel"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_integrated_playtest.get("schema", "")),
		"source_status": String(source_integrated_playtest.get("status", "")),
		"source_gate": String(source_integrated_playtest.get("gate", "")),
		"source_integrated_playtest_line": String(source_integrated_playtest.get("integrated_playtest_line", "")),
		"source_entry_line": String(source_integrated_playtest.get("entry_line", "")),
		"source_post_go_line": String(source_integrated_playtest.get("post_go_line", "")),
		"source_ready_for_player_feel_findings": bool(source_integrated_playtest.get("ready_for_player_feel_findings", false)),
		"review_available": review_available,
		"player_feel_check_keys": PLAYER_FEEL_CHECK_KEYS.duplicate(),
		"positive_findings": positive_findings,
		"positive_finding_count": positive_findings.size(),
		"issues": issues,
		"issue_count": issues.size(),
		"primary_issue_id": String(Dictionary((blockers + issues)[0]).get("id", "")) if not (blockers + issues).is_empty() else "",
		"scenario_integrated_player_feel_summary_line": _build_summary_line(source_integrated_playtest, player_feel_notes, ready_for_acceptance, issues),
		"ready_for_small_game_acceptance_slice": ready_for_acceptance,
		"status": status,
		"gate": gate,
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
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


static func _build_blockers(source_integrated_playtest: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_integrated_playtest.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_1021-Source-Schema fehlt oder passt nicht."))
	if String(source_integrated_playtest.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1021."))
	if String(source_integrated_playtest.get("status", "")) != "scenario_integrated_playtest_passed":
		blockers.append(_issue("source_not_passed", "TASK_1021-Source ist nicht scenario_integrated_playtest_passed."))
	if not bool(source_integrated_playtest.get("scenario_integrated_playtest_passed", false)):
		blockers.append(_issue("source_pass_flag_missing", "TASK_1021-Pass-Flag fehlt."))
	if not bool(source_integrated_playtest.get("ready_for_player_feel_findings", false)):
		blockers.append(_issue("source_not_ready_for_player_feel_findings", "TASK_1021 ist nicht fuer Player-Feel-Findings freigegeben."))
	if String(source_integrated_playtest.get("integrated_playtest_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_integrated_playtest_line_missing", "TASK_1021-Integrated-Playtest-Zeile fehlt."))
	if not _snapshot_is_read_only(source_integrated_playtest):
		blockers.append(_issue("source_not_read_only", "TASK_1021-Source verletzt die read-only-Grenze."))
	return blockers


static func _positive_findings(notes: Dictionary) -> Array:
	var findings: Array = []
	for check_id in PLAYER_FEEL_CHECK_KEYS:
		if bool(notes.get(check_id, false)):
			findings.append(check_id)
	return findings


static func _issues_for_notes(notes: Dictionary) -> Array:
	var issues: Array = []
	if not bool(notes.get("integrated_entry_feels_clear", false)):
		issues.append(_issue("integrated_entry_feels_unclear", "Release-/Mission-Entry fuehlt sich noch nicht klar genug an."))
	if not bool(notes.get("fob_grip_feels_round", false)):
		issues.append(_issue("fob_grip_not_round", "FOB-Griff liest sich noch nicht als runder kleiner Startmoment."))
	if not bool(notes.get("next_confirm_go_feels_clear", false)):
		issues.append(_issue("next_confirm_go_boundary_not_felt", "NEXT/CONFIRM/GO-Grenze ist im Spielgefuehl noch nicht klar genug."))
	if not bool(notes.get("post_go_feedback_invites_next_grip", false)):
		issues.append(_issue("post_go_feedback_feels_dry", "Post-GO-Feedback erklaert den naechsten Griff noch nicht angenehm genug."))
	if not bool(notes.get("loop_returns_without_confusion", false)):
		issues.append(_issue("loop_return_feels_confusing", "Rueckkehr zu NEXT fuehlt sich noch unklar oder hakelig an."))
	if not bool(notes.get("hud_feels_calm", false)):
		issues.append(_issue("integrated_hud_feels_noisy", "HUD fuehlt sich im integrierten Griff noch zu laut oder instabil an."))
	if not bool(notes.get("performance_feels_responsive", false)):
		issues.append(_issue("integrated_performance_feels_sluggish", "Integrierter Szenario-Griff fuehlt sich nicht responsiv genug an."))
	if not bool(notes.get("multiplayer_boundary_feels_clear", false)):
		issues.append(_issue("integrated_multiplayer_boundary_feels_unclear", "Multiplayer-/Wahrheitsgrenze wirkt im Spielerblick unklar."))
	if not bool(notes.get("two_player_context_feels_clear", false)):
		issues.append(_issue("two_player_context_feels_unclear", "Zwei-Spieler-Kontext und Rollen bleiben im integrierten Griff nicht klar genug."))
	if not bool(notes.get("small_game_feels_round", false)):
		issues.append(_issue("small_game_not_round_yet", "Der Ablauf fuehlt sich noch nicht wie ein kleines rundes Spiel an."))
	return issues


static func _build_summary_line(source_integrated_playtest: Dictionary, notes: Dictionary, accepted: bool, issues: Array) -> String:
	if accepted:
		var summary: String = String(notes.get("summary", "")).strip_edges()
		if summary.is_empty():
			summary = "FOB/NEXT/GO/FEEDBACK fuehlt sich im integrierten Griff rund an."
		return "SCENARIO INTEGRATED FEEL PASS: %s" % _compact_text(summary, 116)
	if not issues.is_empty():
		return "SCENARIO INTEGRATED FEEL REWORK: %s" % _compact_text(String(Dictionary(issues[0]).get("text", "")), 104)
	var source_line: String = String(source_integrated_playtest.get("integrated_playtest_line", "")).strip_edges()
	if source_line.is_empty():
		return ""
	return "SCENARIO INTEGRATED FEEL REVIEW: %s" % _compact_text(source_line, 104)


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
