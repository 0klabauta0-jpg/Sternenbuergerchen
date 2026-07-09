class_name ReleaseFirstDecisionLoopTwoPlayerLoopOutcomeVisualPolish
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_outcome_visual_polish.v1"
const TASK_ID: String = "TASK_988"
const SOURCE_TASK_ID: String = "TASK_987"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_outcome_visual_findings.v1"
const CAPTURE_TASK_ID: String = "TASK_986"
const CAPTURE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_outcome_real_window_capture.v1"
const NEXT_TASK: String = "TASK_989 - Release First Decision Loop Two Player Loop Outcome Playability Slice"


static func build_snapshot(source_findings: Dictionary, outcome_capture: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_findings, outcome_capture)
	var active: bool = blockers.is_empty()
	var surfaces: Array = _build_surface_specs(source_findings, outcome_capture) if active else []
	var outcome_line_surface: Dictionary = Dictionary(surfaces[0]) if surfaces.size() > 0 else {}
	var mini_objective_surface: Dictionary = Dictionary(surfaces[1]) if surfaces.size() > 1 else {}
	var next_step_surface: Dictionary = Dictionary(surfaces[2]) if surfaces.size() > 2 else {}
	var outcome_polish_line: String = _build_outcome_polish_line(outcome_line_surface, mini_objective_surface, next_step_surface) if active else ""
	var status: String = "outcome_visual_polish_ready" if active else "blocked"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_findings.get("schema", "")),
		"source_status": String(source_findings.get("status", "")),
		"source_issue_count": int(source_findings.get("issue_count", 0)),
		"capture_task_id": CAPTURE_TASK_ID,
		"capture_schema": String(outcome_capture.get("schema", "")),
		"capture_status": String(outcome_capture.get("status", "")),
		"capture_gate": String(outcome_capture.get("gate", "")),
		"source_outcome_line": _resolve_text(source_findings, outcome_capture, "source_outcome_line"),
		"source_mini_objective_state": _resolve_text(source_findings, outcome_capture, "source_mini_objective_state"),
		"source_next_step_line": _resolve_text(source_findings, outcome_capture, "source_next_step_line"),
		"window_screenshot_path": String(outcome_capture.get("window_screenshot_path", "")),
		"desktop_screenshot_path": String(outcome_capture.get("desktop_screenshot_path", "")),
		"active": active,
		"outcome_surface_specs": surfaces,
		"outcome_surface_spec_count": surfaces.size(),
		"outcome_line_surface": outcome_line_surface,
		"mini_objective_surface": mini_objective_surface,
		"next_step_surface": next_step_surface,
		"outcome_polish_line": outcome_polish_line,
		"visual_priority": "outcome_readability",
		"status": status,
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else "",
		"recommended_next_task": NEXT_TASK if active else "TASK_988 - Release First Decision Loop Two Player Loop Outcome Visual Polish",
		"recommended_direction": "build_outcome_playability_slice" if active else "fix_outcome_visual_polish_source",
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


static func _build_blockers(source_findings: Dictionary, outcome_capture: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_findings.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_987-Source-Schema fehlt oder passt nicht."))
	if String(source_findings.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_987."))
	if String(source_findings.get("status", "")) not in ["ready_for_outcome_visual_polish", "accepted_for_outcome_playability_slice"]:
		blockers.append(_issue("source_not_polishable", "TASK_987-Source ist nicht fuer TASK_988 polishbar."))
	if not _snapshot_is_read_only(source_findings):
		blockers.append(_issue("source_not_read_only", "TASK_987-Source verletzt die read-only-Grenze."))
	if String(outcome_capture.get("schema", "")) != CAPTURE_SCHEMA:
		blockers.append(_issue("capture_schema_mismatch", "TASK_986-Capture-Schema fehlt oder passt nicht."))
	if String(outcome_capture.get("task_id", "")) != CAPTURE_TASK_ID:
		blockers.append(_issue("capture_task_mismatch", "Outcome-Capture nennt nicht TASK_986."))
	if String(outcome_capture.get("source_task_id", "")) != "TASK_985":
		blockers.append(_issue("capture_source_task_mismatch", "TASK_986-Capture nennt nicht TASK_985 als Outcome-Quelle."))
	if _resolve_text(source_findings, outcome_capture, "source_outcome_line").is_empty():
		blockers.append(_issue("outcome_line_missing", "Outcome-Zeile fehlt fuer TASK_988."))
	if _resolve_text(source_findings, outcome_capture, "source_mini_objective_state").is_empty():
		blockers.append(_issue("mini_objective_missing", "Mini-Zielzustand fehlt fuer TASK_988."))
	if _resolve_text(source_findings, outcome_capture, "source_next_step_line").is_empty():
		blockers.append(_issue("next_step_missing", "Next-Step-Zeile fehlt fuer TASK_988."))
	if not _snapshot_is_read_only(outcome_capture):
		blockers.append(_issue("capture_not_read_only", "TASK_986-Capture verletzt die read-only-Grenze."))
	return blockers


static func _build_surface_specs(source_findings: Dictionary, outcome_capture: Dictionary) -> Array:
	return [
		_surface_spec(
			"outcome_line_surface",
			"result",
			"RESULT",
			_resolve_text(source_findings, outcome_capture, "source_outcome_line"),
			"outcome_result_primary",
			"gold",
			34.0,
			2
		),
		_surface_spec(
			"mini_objective_surface",
			"objective_state",
			"OBJ",
			_resolve_text(source_findings, outcome_capture, "source_mini_objective_state"),
			"outcome_objective_state",
			"mint",
			28.0,
			1
		),
		_surface_spec(
			"next_step_surface",
			"next_action",
			"NEXT",
			_resolve_text(source_findings, outcome_capture, "source_next_step_line"),
			"outcome_next_step",
			"sky",
			30.0,
			2
		),
	]


static func _surface_spec(surface_id: String, role: String, label: String, text: String, style_id: String, accent: String, min_height: float, max_lines: int) -> Dictionary:
	return {
		"surface_id": surface_id,
		"role": role,
		"label": label,
		"text": text,
		"display_text": "%s: %s" % [label, text],
		"style_id": style_id,
		"accent": accent,
		"min_height": min_height,
		"max_lines": max_lines,
		"autowrap": true,
		"clip_text": true,
		"priority": "primary" if role == "result" else "support",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
	}


static func _build_outcome_polish_line(outcome_line_surface: Dictionary, mini_objective_surface: Dictionary, next_step_surface: Dictionary) -> String:
	return "RESULT %s | OBJ %s | NEXT %s" % [
		_compact_text(String(outcome_line_surface.get("text", "")), 44),
		_compact_text(String(mini_objective_surface.get("text", "")), 28),
		_compact_text(String(next_step_surface.get("text", "")), 42),
	]


static func _compact_text(text: String, max_length: int) -> String:
	var normalized: String = text.strip_edges()
	if normalized.length() <= max_length:
		return normalized
	return normalized.substr(0, maxi(max_length - 3, 0)).strip_edges() + "..."


static func _resolve_text(primary: Dictionary, fallback: Dictionary, key: String) -> String:
	var value: String = String(primary.get(key, "")).strip_edges()
	if not value.is_empty():
		return value
	return String(fallback.get(key, "")).strip_edges()


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
