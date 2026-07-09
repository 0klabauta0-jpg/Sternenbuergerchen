class_name ReleaseFirstDecisionPlaytestFindings
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_playtest_findings.v1"
const TASK_ID: String = "TASK_962"
const SOURCE_TASK_ID: String = "TASK_961"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_integrated_playtest.v1"
const NEXT_REVIEW_TASK: String = "TASK_962 - Release First Decision Playtest Findings"
const NEXT_POLISH_TASK: String = "TASK_963 - Release First Decision Integrated Polish Followup"
const NEXT_LOOP_TASK: String = "TASK_963 - Release First Decision Next Playable Loop"


static func build_snapshot(source_snapshot: Dictionary, review_notes: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_snapshot)
	var manual_review_done: bool = bool(review_notes.get("manual_playtest_review_done", false))
	var issues: Array = []
	var positive_findings: Array = []
	if blockers.is_empty():
		if manual_review_done:
			issues = _build_source_issues(source_snapshot)
			issues.append_array(_build_review_issues(review_notes))
			positive_findings = _build_positive_findings(review_notes)
		else:
			issues.append(_issue("manual_playtest_review_open", "Der integrierte First-Decision-Playtest ist noch nicht als Spielerbefund bewertet."))
	var accepted: bool = blockers.is_empty() and manual_review_done and issues.is_empty()
	var status: String = "blocked"
	var recommended_next_task: String = NEXT_REVIEW_TASK
	var recommended_direction: String = "complete_release_first_decision_playtest_review"
	if blockers.is_empty():
		if accepted:
			status = "accepted_for_release_first_decision_next_loop"
			recommended_next_task = NEXT_LOOP_TASK
			recommended_direction = "build_next_small_playable_loop"
		elif manual_review_done:
			status = "ready_for_release_first_decision_polish"
			recommended_next_task = NEXT_POLISH_TASK
			recommended_direction = "tighten_release_first_decision_integrated_playtest"
		else:
			status = "needs_manual_review"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_snapshot.get("schema", "")),
		"source_gate": String(source_snapshot.get("gate", "")),
		"source_integrated_playtest_passed": bool(source_snapshot.get("integrated_playtest_passed", false)),
		"source_manifest_available": bool(source_snapshot.get("manifest_available", false)),
		"source_missing_playtest_check_count": int(source_snapshot.get("missing_playtest_check_count", 0)),
		"source_issue_count": int(source_snapshot.get("issue_count", 0)),
		"observed_release_stages": Array(source_snapshot.get("observed_release_stages", [])).duplicate(true),
		"review_notes": review_notes.duplicate(true),
		"manual_review_required": true,
		"manual_review_done": manual_review_done,
		"positive_findings": positive_findings,
		"positive_finding_count": positive_findings.size(),
		"issues": issues,
		"issue_count": issues.size(),
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else (String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else ""),
		"accepted": accepted,
		"status": status,
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


static func _build_blockers(source_snapshot: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_snapshot.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_961-Source-Schema fehlt oder passt nicht."))
	if String(source_snapshot.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_961."))
	var source_gate: String = String(source_snapshot.get("gate", ""))
	if source_gate not in ["integrated_playtest_passed", "integrated_playtest_regression_found"]:
		blockers.append(_issue("source_playtest_not_reviewable", "TASK_961-Source ist weder passed noch als Regression reviewbar."))
	if not bool(source_snapshot.get("manifest_available", false)):
		blockers.append(_issue("source_manifest_missing", "TASK_961-Source hat kein integriertes Playtest-Manifest."))
	if not bool(source_snapshot.get("read_only", false)):
		blockers.append(_issue("source_not_read_only", "TASK_961-Source ist nicht read-only."))
	if bool(source_snapshot.get("ui_sets_gameplay_truth", true)):
		blockers.append(_issue("source_sets_ui_gameplay_truth", "TASK_961-Source darf keine UI-Gameplay-Wahrheit setzen."))
	return blockers


static func _build_source_issues(source_snapshot: Dictionary) -> Array:
	var issues: Array = []
	if String(source_snapshot.get("gate", "")) == "integrated_playtest_regression_found" or not bool(source_snapshot.get("integrated_playtest_passed", false)):
		issues.append(_issue("source_integrated_playtest_regression", "TASK_961 meldet noch eine integrierte Playtest-Regression."))
	for issue_variant in Array(source_snapshot.get("issues", [])):
		if typeof(issue_variant) != TYPE_DICTIONARY:
			continue
		var issue: Dictionary = Dictionary(issue_variant)
		var issue_id: String = String(issue.get("id", ""))
		if issue_id.is_empty():
			continue
		issues.append(_issue(issue_id, String(issue.get("text", "TASK_961-Source-Issue."))))
	return issues


static func _build_review_issues(review_notes: Dictionary) -> Array:
	var issues: Array = []
	if not bool(review_notes.get("correct_window_content_confirmed", false)):
		issues.append(_issue("correct_window_content_not_confirmed", "Der Spielerbefund bestaetigt nicht das korrekte Sternenbuergerchen-Fenster."))
	if not bool(review_notes.get("homebase_to_mission_readable", false)):
		issues.append(_issue("homebase_to_mission_not_readable", "Homebase-bis-Mission ist noch nicht gut lesbar."))
	if not bool(review_notes.get("dropship_lz_drop_readable", false)):
		issues.append(_issue("dropship_lz_drop_not_readable", "Dropship, LZ und Drop sind noch nicht gut lesbar."))
	if not bool(review_notes.get("first_decision_preview_readable", false)):
		issues.append(_issue("first_decision_preview_not_readable", "Die erste Decision-Preview ist noch nicht gut lesbar."))
	if not bool(review_notes.get("go_and_post_go_feedback_readable", false)):
		issues.append(_issue("post_go_feedback_not_readable", "GO und Post-GO-Feedback sind noch nicht gut lesbar."))
	if not bool(review_notes.get("performance_ok", false)):
		issues.append(_issue("performance_not_ok", "Performance/Hotpath wirkt im integrierten Playtest noch nicht ok."))
	if not bool(review_notes.get("no_new_hud_gameplay_truth", false)):
		issues.append(_issue("hud_gameplay_truth_risk", "Read-only-HUD-Grenze ist im Befund nicht bestaetigt."))
	if not bool(review_notes.get("multiplayer_boundary_ok", false)):
		issues.append(_issue("multiplayer_boundary_risk", "Multiplayer-Snapshot-Grenze ist im Befund nicht bestaetigt."))
	if not bool(review_notes.get("player_readability_ok", false)):
		issues.append(_issue("player_readability_not_ok", "Der erste Release-Decision-Griff fuehlt sich noch nicht rund genug an."))
	return issues


static func _build_positive_findings(review_notes: Dictionary) -> Array:
	var positive: Array = []
	_append_positive(positive, review_notes, "correct_window_content_confirmed", "Korrektes Release-Fenster bestaetigt.")
	_append_positive(positive, review_notes, "homebase_to_mission_readable", "Homebase-bis-Mission ist lesbar.")
	_append_positive(positive, review_notes, "dropship_lz_drop_readable", "Dropship/LZ/Drop ist lesbar.")
	_append_positive(positive, review_notes, "first_decision_preview_readable", "Erste Decision-Preview ist lesbar.")
	_append_positive(positive, review_notes, "go_and_post_go_feedback_readable", "GO und Post-GO-Feedback sind lesbar.")
	_append_positive(positive, review_notes, "performance_ok", "Performance/Hotpath wirkt ok.")
	_append_positive(positive, review_notes, "no_new_hud_gameplay_truth", "Read-only-HUD-Grenze bleibt bestaetigt.")
	_append_positive(positive, review_notes, "multiplayer_boundary_ok", "Multiplayer-Snapshot-Grenze bleibt bestaetigt.")
	_append_positive(positive, review_notes, "player_readability_ok", "Spielerblick ist rund genug fuer den naechsten kleinen Loop.")
	return positive


static func _append_positive(positive: Array, review_notes: Dictionary, note_id: String, text: String) -> void:
	if bool(review_notes.get(note_id, false)):
		positive.append({
			"id": note_id,
			"text": text,
		})


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
