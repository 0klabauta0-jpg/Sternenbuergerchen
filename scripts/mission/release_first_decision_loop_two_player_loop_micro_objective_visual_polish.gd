class_name ReleaseFirstDecisionLoopTwoPlayerLoopMicroObjectiveVisualPolish
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_visual_polish.v1"
const TASK_ID: String = "TASK_999"
const SOURCE_TASK_ID: String = "TASK_998"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_visual_findings.v1"
const NEXT_TASK: String = "TASK_1000 - Release First Decision Loop Two Player Loop Micro Objective Playability Slice"


static func build_snapshot(source_findings: Dictionary) -> Dictionary:
	var blockers: Array = _build_blockers(source_findings)
	var active: bool = blockers.is_empty()
	var surfaces: Array = _build_surface_specs(source_findings) if active else []
	var micro_objective_outcome_surface: Dictionary = Dictionary(surfaces[0]) if surfaces.size() > 0 else {}
	var mini_objective_surface: Dictionary = Dictionary(surfaces[1]) if surfaces.size() > 1 else {}
	var next_step_surface: Dictionary = Dictionary(surfaces[2]) if surfaces.size() > 2 else {}
	var micro_objective_polish_line: String = _build_micro_objective_polish_line(micro_objective_outcome_surface, mini_objective_surface, next_step_surface) if active else ""
	var status: String = "micro_objective_visual_polish_ready" if active else "blocked"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_findings.get("schema", "")),
		"source_status": String(source_findings.get("status", "")),
		"source_issue_count": int(source_findings.get("issue_count", 0)),
		"source_selected_micro_objective_id": String(source_findings.get("source_selected_micro_objective_id", "")),
		"source_selected_micro_objective_label": String(source_findings.get("source_selected_micro_objective_label", "")),
		"source_outcome_line": _resolve_text(source_findings, "source_outcome_line"),
		"source_mini_objective_state": _resolve_text(source_findings, "source_mini_objective_state"),
		"source_next_step_line": _resolve_text(source_findings, "source_next_step_line"),
		"window_screenshot_path": String(source_findings.get("window_screenshot_path", "")),
		"desktop_screenshot_path": String(source_findings.get("desktop_screenshot_path", "")),
		"active": active,
		"micro_objective_surface_specs": surfaces,
		"micro_objective_surface_spec_count": surfaces.size(),
		"micro_objective_outcome_surface": micro_objective_outcome_surface,
		"mini_objective_surface": mini_objective_surface,
		"next_step_surface": next_step_surface,
		"micro_objective_polish_line": micro_objective_polish_line,
		"visual_priority": "micro_objective_readability",
		"status": status,
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else "",
		"recommended_next_task": NEXT_TASK if active else "TASK_999 - Release First Decision Loop Two Player Loop Micro Objective Visual Polish",
		"recommended_direction": "build_micro_objective_playability_slice" if active else "fix_micro_objective_visual_polish_source",
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
		blockers.append(_issue("source_schema_mismatch", "TASK_998-Source-Schema fehlt oder passt nicht."))
	if String(source_findings.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_998."))
	if String(source_findings.get("status", "")) not in ["ready_for_micro_objective_visual_polish", "accepted_for_micro_objective_playability_slice"]:
		blockers.append(_issue("source_not_polishable", "TASK_998-Source ist nicht fuer TASK_999 polishbar."))
	if not _snapshot_is_read_only(source_findings):
		blockers.append(_issue("source_not_read_only", "TASK_998-Source verletzt die read-only-Grenze."))
	if _resolve_text(source_findings, "source_outcome_line").is_empty():
		blockers.append(_issue("micro_objective_outcome_line_missing", "Micro-Objective-Outcome-Zeile fehlt fuer TASK_999."))
	if _resolve_text(source_findings, "source_mini_objective_state").is_empty():
		blockers.append(_issue("mini_objective_missing", "Mini-Zielzustand fehlt fuer TASK_999."))
	if _resolve_text(source_findings, "source_next_step_line").is_empty():
		blockers.append(_issue("next_step_missing", "Next-Step-Zeile fehlt fuer TASK_999."))
	return blockers


static func _build_surface_specs(source_findings: Dictionary) -> Array:
	return [
		_surface_spec(
			"micro_objective_outcome_surface",
			"micro_objective_result",
			"OUTCOME",
			_resolve_text(source_findings, "source_outcome_line"),
			"micro_objective_outcome_primary",
			"gold",
			34.0,
			2
		),
		_surface_spec(
			"mini_objective_surface",
			"objective_state",
			"OBJ",
			_resolve_text(source_findings, "source_mini_objective_state"),
			"micro_objective_state",
			"mint",
			28.0,
			1
		),
		_surface_spec(
			"next_step_surface",
			"next_action",
			"NEXT",
			_resolve_text(source_findings, "source_next_step_line"),
			"micro_objective_next_step",
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
		"priority": "primary" if role == "micro_objective_result" else "support",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
	}


static func _build_micro_objective_polish_line(micro_objective_outcome_surface: Dictionary, mini_objective_surface: Dictionary, next_step_surface: Dictionary) -> String:
	return "OUTCOME %s | OBJ %s | NEXT %s" % [
		_compact_text(String(micro_objective_outcome_surface.get("text", "")), 44),
		_compact_text(String(mini_objective_surface.get("text", "")), 28),
		_compact_text(String(next_step_surface.get("text", "")), 42),
	]


static func _compact_text(text: String, max_length: int) -> String:
	var normalized: String = text.strip_edges()
	if normalized.length() <= max_length:
		return normalized
	return normalized.substr(0, maxi(max_length - 3, 0)).strip_edges() + "..."


static func _resolve_text(source_findings: Dictionary, key: String) -> String:
	return String(source_findings.get(key, "")).strip_edges()


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
