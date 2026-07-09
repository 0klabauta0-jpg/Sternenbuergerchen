class_name ReleaseFirstDecisionLoopTwoPlayerLoopMicroObjectiveRoundLoopRuntimePolish
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish.v1"
const TASK_ID: String = "TASK_1003"
const SOURCE_TASK_ID: String = "TASK_1002"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice.v1"
const NEXT_TASK: String = "TASK_1004 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Real Window Capture"


static func build_snapshot(source_round_loop: Dictionary) -> Dictionary:
	var blockers: Array = _build_blockers(source_round_loop)
	var active: bool = blockers.is_empty()
	var completed_round_count: int = int(source_round_loop.get("completed_round_count", 0))
	var surfaces: Array = _build_surface_specs(completed_round_count) if active else []
	var selected_line: String = "ROUND %d stabil | NEXT bereit" % completed_round_count if active else ""
	var mission_line: String = "NEXT Micro-Ziel waehlen | GO separat" if active else ""
	var feedback_line: String = "ROUND LOOP: Feedback gelesen | GO separat bleibt" if active else ""
	var lines_within_limit: bool = active and selected_line.length() <= 72 and mission_line.length() <= 72 and feedback_line.length() <= 72
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_round_loop.get("schema", "")),
		"source_status": String(source_round_loop.get("status", "")),
		"source_gate": String(source_round_loop.get("gate", "")),
		"source_passed": bool(source_round_loop.get("micro_objective_round_loop_playtest_slice_passed", false)),
		"source_round_loop_line": String(source_round_loop.get("round_loop_line", "")),
		"completed_round_count": completed_round_count,
		"active": active,
		"round_loop_runtime_surface_specs": surfaces,
		"round_loop_runtime_surface_spec_count": surfaces.size(),
		"selected_fireteam_runtime_line": selected_line,
		"mission_control_runtime_line": mission_line,
		"command_feedback_runtime_line": feedback_line,
		"runtime_lines_within_limit": lines_within_limit,
		"go_separation_visible": active,
		"next_decision_visible": active,
		"status": "micro_objective_round_loop_runtime_polish_ready" if active else "blocked",
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else "",
		"recommended_next_task": NEXT_TASK if active else "TASK_1003 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Runtime Polish",
		"recommended_direction": "capture_round_loop_real_window" if active else "fix_round_loop_runtime_polish_source",
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


static func _build_blockers(source_round_loop: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_round_loop.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_1002-Source-Schema fehlt oder passt nicht."))
	if String(source_round_loop.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1002."))
	if String(source_round_loop.get("status", "")) != "micro_objective_round_loop_playtest_slice_passed":
		blockers.append(_issue("source_not_passed", "TASK_1002-Source ist nicht bestanden."))
	if not bool(source_round_loop.get("micro_objective_round_loop_playtest_slice_passed", false)):
		blockers.append(_issue("source_pass_flag_missing", "TASK_1002-Source setzt den Pass-Flag nicht."))
	if int(source_round_loop.get("completed_round_count", 0)) < 2:
		blockers.append(_issue("source_round_count_too_low", "TASK_1002 bestaetigt nicht zwei Micro-Objective-Runden."))
	if not bool(source_round_loop.get("no_feedback_dead_end", false)):
		blockers.append(_issue("source_feedback_dead_end", "TASK_1002 meldet noch ein Feedback-Dead-End."))
	if not bool(source_round_loop.get("hud_surfaces_stable", false)):
		blockers.append(_issue("source_hud_surfaces_unstable", "TASK_1002 meldet instabile HUD-Surfaces."))
	if not _snapshot_is_read_only(source_round_loop):
		blockers.append(_issue("source_not_read_only", "TASK_1002-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_surface_specs(completed_round_count: int) -> Array:
	return [
		_surface("round_loop_status_surface", "ROUND", "ROUND %d abgeschlossen" % completed_round_count, "round_loop_status_ready"),
		_surface("next_decision_surface", "NEXT", "Naechstes Micro-Ziel waehlen", "round_loop_next_ready"),
		_surface("go_boundary_surface", "GO", "GO separat bestaetigen", "round_loop_go_separate"),
	]


static func _surface(surface_id: String, token: String, text: String, style_id: String) -> Dictionary:
	return {
		"surface_id": surface_id,
		"token": token,
		"text": text,
		"style_id": style_id,
		"min_width": 96.0,
		"min_height": 32.0,
		"line_budget": 72,
		"line_within_limit": text.length() <= 72,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
	}


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
