class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioReleaseCandidatePlaytest
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest.v1"
const TASK_ID: String = "TASK_1024"
const SOURCE_TASK_ID: String = "TASK_1023"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice.v1"
const REVIEW_TASK: String = "TASK_1024 - Release First Decision Loop Two Player Loop Scenario Release Candidate Playtest"
const POLISH_TASK: String = "TASK_1025 - Release First Decision Loop Two Player Loop Scenario Targeted RC Polish"
const NEXT_TASK: String = "TASK_1025 - Release First Decision Loop Two Player Loop Scenario Release Candidate Acceptance"

const REQUIRED_PLAYTEST_CHECKS: Array[String] = [
	"release_exe_started",
	"singleplayer_entry_opened",
	"fob_screen_loaded",
	"alpha_bravo_context_visible",
	"next_confirm_go_flow_used",
	"go_executed_once",
	"post_go_feedback_visible",
	"loop_returns_to_next",
	"no_input_dead_end",
	"performance_responsive",
	"no_hud_gameplay_truth",
	"multiplayer_boundary_preserved",
]


static func build_snapshot(source_acceptance: Dictionary, playtest_manifest: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_acceptance)
	var manifest_available: bool = bool(playtest_manifest.get("manifest_available", false)) or not playtest_manifest.is_empty()
	var completed_checks: Array = Array(playtest_manifest.get("completed_playtest_checks", []))
	var missing_checks: Array = _missing_checks(completed_checks)
	var manual_done: bool = bool(playtest_manifest.get("manual_playtest_done", false))
	var issues: Array = []
	var status: String = "blocked"
	var gate: String = "blocked"
	var recommended_next_task: String = POLISH_TASK
	var recommended_direction: String = "fix_small_game_acceptance_source"
	var passed: bool = false
	var ready_for_acceptance: bool = false
	if blockers.is_empty():
		if not manifest_available:
			status = "needs_release_candidate_playtest_manifest"
			gate = "needs_release_candidate_playtest_manifest"
			issues.append(_issue("release_candidate_playtest_manifest_missing", "Release-Candidate-Playtest-Manifest fuer TASK_1024 fehlt."))
			recommended_next_task = REVIEW_TASK
			recommended_direction = "run_release_candidate_playtest"
		else:
			issues = _build_manifest_issues(playtest_manifest, missing_checks, manual_done)
			if not manual_done:
				status = "needs_release_candidate_playtest_completion"
				gate = "needs_release_candidate_playtest_completion"
				recommended_next_task = REVIEW_TASK
				recommended_direction = "complete_release_candidate_playtest"
			elif issues.is_empty():
				status = "release_candidate_playtest_passed"
				gate = "release_candidate_playtest_passed"
				passed = true
				ready_for_acceptance = true
				recommended_next_task = NEXT_TASK
				recommended_direction = "cut_release_candidate_acceptance"
			else:
				status = "release_candidate_playtest_regression_found"
				gate = "release_candidate_playtest_regression_found"
				recommended_next_task = POLISH_TASK
				recommended_direction = "polish_release_candidate_regressions"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_acceptance.get("schema", "")),
		"source_status": String(source_acceptance.get("status", "")),
		"source_gate": String(source_acceptance.get("gate", "")),
		"source_small_game_acceptance_line": String(source_acceptance.get("small_game_acceptance_line", "")),
		"source_small_game_acceptance_slice_passed": bool(source_acceptance.get("small_game_acceptance_slice_passed", false)),
		"source_ready_for_release_candidate_playtest": bool(source_acceptance.get("ready_for_release_candidate_playtest", false)),
		"manifest_available": manifest_available,
		"manual_playtest_done": manual_done,
		"release_exe_started": bool(playtest_manifest.get("release_exe_started", false)),
		"release_build_path": String(playtest_manifest.get("release_build_path", "")),
		"playtest_window": String(playtest_manifest.get("playtest_window", "")),
		"required_playtest_checks": REQUIRED_PLAYTEST_CHECKS.duplicate(),
		"completed_playtest_checks": completed_checks,
		"completed_playtest_check_count": completed_checks.size(),
		"missing_playtest_checks": missing_checks,
		"missing_playtest_check_count": missing_checks.size(),
		"post_go_feedback_visible": bool(playtest_manifest.get("post_go_feedback_visible", false)),
		"loop_returns_to_next": bool(playtest_manifest.get("loop_returns_to_next", false)),
		"performance_responsive": bool(playtest_manifest.get("performance_responsive", false)),
		"multiplayer_boundary_preserved": bool(playtest_manifest.get("multiplayer_boundary_preserved", false)),
		"no_hud_gameplay_truth": bool(playtest_manifest.get("no_hud_gameplay_truth", false)),
		"issue_flags": Dictionary(playtest_manifest.get("issue_flags", {})).duplicate(true),
		"release_candidate_playtest_line": _build_playtest_line(source_acceptance, passed, manifest_available),
		"release_candidate_playtest_passed": passed,
		"ready_for_release_candidate_acceptance": ready_for_acceptance,
		"status": status,
		"gate": gate,
		"issues": issues,
		"issue_count": issues.size(),
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
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


static func _build_blockers(source_acceptance: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_acceptance.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_1023-Source-Schema fehlt oder passt nicht."))
	if String(source_acceptance.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1023."))
	if String(source_acceptance.get("status", "")) != "small_game_acceptance_slice_passed":
		blockers.append(_issue("source_not_small_game_accepted", "TASK_1023-Source ist nicht small_game_acceptance_slice_passed."))
	if not bool(source_acceptance.get("small_game_acceptance_slice_passed", false)):
		blockers.append(_issue("source_pass_flag_missing", "TASK_1023-Pass-Flag fehlt."))
	if not bool(source_acceptance.get("ready_for_release_candidate_playtest", false)):
		blockers.append(_issue("source_not_ready_for_release_candidate_playtest", "TASK_1023 ist nicht fuer Release-Candidate-Playtest freigegeben."))
	var line: String = String(source_acceptance.get("small_game_acceptance_line", "")).strip_edges()
	if line.is_empty():
		blockers.append(_issue("source_small_game_acceptance_line_missing", "TASK_1023-Acceptance-Line fehlt."))
	elif not (line.contains("FOB") and line.contains("NEXT") and line.contains("GO") and line.contains("FEEDBACK")):
		blockers.append(_issue("source_small_game_acceptance_line_incomplete", "TASK_1023-Acceptance-Line nennt FOB/NEXT/GO/FEEDBACK nicht gemeinsam."))
	if not _snapshot_is_read_only(source_acceptance):
		blockers.append(_issue("source_not_read_only", "TASK_1023-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_manifest_issues(manifest: Dictionary, missing_checks: Array, manual_done: bool) -> Array:
	var issues: Array = []
	var issue_ids := {}
	if not manual_done:
		_append_issue_once(issues, issue_ids, "manual_release_candidate_playtest_open", "Der Release-Candidate-Playtest ist noch nicht abgeschlossen.")
	if not missing_checks.is_empty():
		_append_issue_once(issues, issue_ids, "release_candidate_checks_missing", "Nicht alle Release-Candidate-Playtest-Checks sind abgeschlossen.")
	if not bool(manifest.get("release_exe_started", false)):
		_append_issue_once(issues, issue_ids, "release_exe_not_started", "Die Release-Exe wurde im Playtest nicht gestartet.")
	if missing_checks.has("post_go_feedback_visible") or not bool(manifest.get("post_go_feedback_visible", false)):
		_append_issue_once(issues, issue_ids, "post_go_feedback_missing_in_release_candidate", "Post-GO-Feedback ist im Release-Candidate-Playtest nicht sichtbar.")
	if missing_checks.has("loop_returns_to_next") or not bool(manifest.get("loop_returns_to_next", false)):
		_append_issue_once(issues, issue_ids, "release_candidate_loop_does_not_return_to_next", "Der Release-Candidate-Loop kehrt nicht klar zu NEXT zurueck.")
	if missing_checks.has("performance_responsive") or not bool(manifest.get("performance_responsive", false)):
		_append_issue_once(issues, issue_ids, "release_candidate_performance_sluggish", "Der Release-Candidate-Playtest fuehlt sich nicht responsiv genug an.")
	if missing_checks.has("multiplayer_boundary_preserved") or not bool(manifest.get("multiplayer_boundary_preserved", false)):
		_append_issue_once(issues, issue_ids, "release_candidate_multiplayer_boundary_risk", "Die Multiplayer-/Wahrheitsgrenze ist im RC-Playtest nicht klar erhalten.")
	if missing_checks.has("no_hud_gameplay_truth") or not bool(manifest.get("no_hud_gameplay_truth", false)):
		_append_issue_once(issues, issue_ids, "release_candidate_hud_gameplay_truth_risk", "HUD-Gameplay-Wahrheit ist im RC-Playtest nicht ausgeschlossen.")
	var flags: Dictionary = Dictionary(manifest.get("issue_flags", {}))
	for flag_id in flags.keys():
		if bool(flags.get(flag_id, false)):
			_append_issue_once(issues, issue_ids, String(flag_id), "Release-Candidate-Playtest-Flag `%s` ist aktiv." % String(flag_id))
	if bool(manifest.get("ui_sets_gameplay_truth", false)):
		_append_issue_once(issues, issue_ids, "trace_ui_gameplay_truth_risk", "Manifest deutet UI-Gameplay-Wahrheit an.")
	if bool(manifest.get("creates_command", false)):
		_append_issue_once(issues, issue_ids, "trace_creates_command", "Playtest-Manifest darf keinen Command erzeugen.")
	if bool(manifest.get("creates_movement", false)):
		_append_issue_once(issues, issue_ids, "trace_creates_movement", "Playtest-Manifest darf keine Bewegung erzeugen.")
	if bool(manifest.get("sets_multiplayer_truth", false)):
		_append_issue_once(issues, issue_ids, "trace_sets_multiplayer_truth", "Playtest-Manifest darf keine Multiplayer-Wahrheit setzen.")
	return issues


static func _append_issue_once(issues: Array, ids: Dictionary, issue_id: String, text: String) -> void:
	if ids.has(issue_id):
		return
	ids[issue_id] = true
	issues.append(_issue(issue_id, text))


static func _missing_checks(completed_checks: Array) -> Array:
	var missing: Array = []
	for check_id in REQUIRED_PLAYTEST_CHECKS:
		if not completed_checks.has(check_id):
			missing.append(check_id)
	return missing


static func _build_playtest_line(source_acceptance: Dictionary, passed: bool, manifest_available: bool) -> String:
	var source_line: String = String(source_acceptance.get("small_game_acceptance_line", "")).strip_edges()
	var state: String = "PASS" if passed else "CHECK" if manifest_available else "Manifest offen"
	if source_line.is_empty():
		source_line = "FOB, NEXT, GO und FEEDBACK brauchen RC-Playtest."
	return "RC PLAYTEST %s: FOB | NEXT | GO | FEEDBACK | %s" % [state, _compact_text(source_line, 104)]


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
