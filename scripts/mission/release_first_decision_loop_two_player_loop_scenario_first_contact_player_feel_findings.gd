class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioFirstContactPlayerFeelFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings.v1"
const TASK_ID: String = "TASK_1035"
const SOURCE_TASK_ID: String = "TASK_1034"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke.v1"
const REVIEW_TASK: String = "TASK_1035 - Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Findings"
const POLISH_TASK: String = "TASK_1036 - Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Polish"
const PLAYABILITY_TASK: String = "TASK_1036 - Release First Decision Loop Two Player Loop Scenario First Contact Playability Slice"

const PLAYER_FEEL_CHECK_KEYS: Array[String] = [
	"contact_line_feels_clear",
	"why_feels_actionable",
	"next_grip_feels_clear",
	"go_boundary_feels_safe",
	"feedback_invites_next_grip",
	"hud_feels_calm",
	"performance_feels_responsive",
	"multiplayer_boundary_feels_clear",
	"first_contact_feels_tactical",
]


static func build_snapshot(source_runtime_smoke: Dictionary, player_feel_notes: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_runtime_smoke)
	var source_ready: bool = blockers.is_empty()
	var review_available: bool = bool(player_feel_notes.get("review_available", false))
	var issues: Array = []
	var positive_findings: Array = []
	var status: String = "blocked"
	var gate: String = "first_contact_player_feel_blocked"
	var recommended_next_task: String = POLISH_TASK
	var recommended_direction: String = "fix_first_contact_runtime_smoke"
	var ready_for_playability: bool = false

	if source_ready:
		positive_findings.append("first_contact_runtime_smoke_passed")
		if not review_available:
			status = "needs_first_contact_player_feel_review"
			gate = "needs_first_contact_player_feel_review"
			issues.append(_issue("first_contact_player_feel_review_missing", "Player-Feel-Notizen fuer TASK_1035 fehlen."))
			recommended_next_task = REVIEW_TASK
			recommended_direction = "collect_first_contact_player_feel_review"
		else:
			positive_findings.append_array(_positive_findings(player_feel_notes))
			issues = _issues_for_notes(player_feel_notes)
			if issues.is_empty():
				status = "accepted_for_first_contact_playability_slice"
				gate = "first_contact_player_feel_accepted"
				ready_for_playability = true
				recommended_next_task = PLAYABILITY_TASK
				recommended_direction = "build_first_contact_playability_slice"
			else:
				status = "first_contact_player_feel_rework_needed"
				gate = "first_contact_player_feel_rework_needed"
				recommended_next_task = POLISH_TASK
				recommended_direction = "polish_first_contact_player_feel"

	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_runtime_smoke.get("schema", "")),
		"source_status": String(source_runtime_smoke.get("status", "")),
		"source_gate": String(source_runtime_smoke.get("gate", "")),
		"source_smoke_line": String(source_runtime_smoke.get("first_contact_runtime_smoke_line", "")),
		"source_post_smoke_feedback_line": String(source_runtime_smoke.get("post_smoke_feedback_line", "")),
		"source_first_contact_runtime_smoke_passed": bool(source_runtime_smoke.get("first_contact_runtime_smoke_passed", false)),
		"source_ready_for_first_contact_player_feel_findings": bool(source_runtime_smoke.get("ready_for_first_contact_player_feel_findings", false)),
		"review_available": review_available,
		"player_feel_check_keys": PLAYER_FEEL_CHECK_KEYS.duplicate(),
		"positive_findings": positive_findings,
		"positive_finding_count": positive_findings.size(),
		"issues": issues,
		"issue_count": issues.size(),
		"primary_issue_id": String(Dictionary((blockers + issues)[0]).get("id", "")) if not (blockers + issues).is_empty() else "",
		"first_contact_player_feel_summary_line": _build_summary_line(source_runtime_smoke, player_feel_notes, ready_for_playability, issues),
		"ready_for_first_contact_playability_slice": ready_for_playability,
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


static func _build_blockers(source_runtime_smoke: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_runtime_smoke.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_1034-Source-Schema fehlt oder passt nicht."))
	if String(source_runtime_smoke.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1034."))
	if String(source_runtime_smoke.get("status", "")) != "first_contact_runtime_smoke_passed":
		blockers.append(_issue("source_not_passed", "TASK_1034-Source ist nicht first_contact_runtime_smoke_passed."))
	if not bool(source_runtime_smoke.get("first_contact_runtime_smoke_passed", false)):
		blockers.append(_issue("source_pass_flag_missing", "TASK_1034-Pass-Flag fehlt."))
	if not bool(source_runtime_smoke.get("ready_for_first_contact_player_feel_findings", false)):
		blockers.append(_issue("source_not_ready_for_player_feel_findings", "TASK_1034 ist nicht fuer First-Contact-Player-Feel-Findings freigegeben."))
	if String(source_runtime_smoke.get("first_contact_runtime_smoke_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_smoke_line_missing", "TASK_1034-Smoke-Zeile fehlt."))
	if not _snapshot_is_read_only(source_runtime_smoke):
		blockers.append(_issue("source_not_read_only", "TASK_1034-Source verletzt die read-only-Grenze."))
	return blockers


static func _positive_findings(notes: Dictionary) -> Array:
	var findings: Array = []
	for check_id in PLAYER_FEEL_CHECK_KEYS:
		if bool(notes.get(check_id, false)):
			findings.append(check_id)
	return findings


static func _issues_for_notes(notes: Dictionary) -> Array:
	var issues: Array = []
	if not bool(notes.get("contact_line_feels_clear", false)):
		issues.append(_issue("contact_line_feels_unclear", "CONTACT-Line liest sich im Spielerblick noch nicht klar genug."))
	if not bool(notes.get("why_feels_actionable", false)):
		issues.append(_issue("why_not_actionable", "WHY erklaert noch nicht handlungsfaehig, warum der Kontakt wichtig ist."))
	if not bool(notes.get("next_grip_feels_clear", false)):
		issues.append(_issue("next_grip_feels_unclear", "NEXT fuehlt sich nach dem Kontakt noch nicht als klarer naechster Griff an."))
	if not bool(notes.get("go_boundary_feels_safe", false)):
		issues.append(_issue("go_boundary_not_felt", "GO-Grenze fuehlt sich im ersten Kontakt noch nicht sicher getrennt an."))
	if not bool(notes.get("feedback_invites_next_grip", false)):
		issues.append(_issue("first_contact_feedback_feels_dry", "Feedback fuehrt noch nicht angenehm zum naechsten Kontaktgriff zurueck."))
	if not bool(notes.get("hud_feels_calm", false)):
		issues.append(_issue("first_contact_hud_feels_noisy", "HUD fuehlt sich beim ersten Kontakt noch zu laut oder instabil an."))
	if not bool(notes.get("performance_feels_responsive", false)):
		issues.append(_issue("first_contact_performance_feels_sluggish", "Erster Kontakt fuehlt sich nicht responsiv genug an."))
	if not bool(notes.get("multiplayer_boundary_feels_clear", false)):
		issues.append(_issue("first_contact_multiplayer_boundary_feels_unclear", "Multiplayer-/Wahrheitsgrenze wirkt im ersten Kontakt unklar."))
	if not bool(notes.get("first_contact_feels_tactical", false)):
		issues.append(_issue("first_contact_not_tactical_yet", "Der erste Kontakt fuehlt sich noch nicht wie eine taktische Entscheidung an."))
	return issues


static func _build_summary_line(source_runtime_smoke: Dictionary, notes: Dictionary, accepted: bool, issues: Array) -> String:
	if accepted:
		var summary: String = String(notes.get("summary", "")).strip_edges()
		if summary.is_empty():
			summary = "CONTACT/WHY/NEXT/GO/FEEDBACK fuehlt sich als erster taktischer Kontaktgriff rund an."
		return "FIRST CONTACT FEEL PASS: %s" % _compact_text(summary, 116)
	if not issues.is_empty():
		return "FIRST CONTACT FEEL REWORK: %s" % _compact_text(String(Dictionary(issues[0]).get("text", "")), 104)
	var source_line: String = String(source_runtime_smoke.get("first_contact_runtime_smoke_line", "")).strip_edges()
	if source_line.is_empty():
		return ""
	return "FIRST CONTACT FEEL REVIEW: %s" % _compact_text(source_line, 104)


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
