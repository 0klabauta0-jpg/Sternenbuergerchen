class_name ReleaseFirstDecisionLoopTwoPlayerLoopMicroObjectiveRoundLoopVisualPolish
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish.v1"
const TASK_ID: String = "TASK_1006"
const SOURCE_TASK_ID: String = "TASK_1005"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_findings.v1"
const NEXT_TASK: String = "TASK_1007 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Playability Slice"


static func build_snapshot(source_findings: Dictionary) -> Dictionary:
	var source: Dictionary = source_findings.duplicate(true)
	var blockers: Array = _build_blockers(source)
	var active: bool = blockers.is_empty()
	var surfaces: Array = _build_surface_specs(source) if active else []
	var round_surface: Dictionary = Dictionary(surfaces[0]) if surfaces.size() > 0 else {}
	var next_surface: Dictionary = Dictionary(surfaces[1]) if surfaces.size() > 1 else {}
	var go_surface: Dictionary = Dictionary(surfaces[2]) if surfaces.size() > 2 else {}
	var selected_surface: Dictionary = Dictionary(surfaces[3]) if surfaces.size() > 3 else {}
	var mission_surface: Dictionary = Dictionary(surfaces[4]) if surfaces.size() > 4 else {}
	var feedback_surface: Dictionary = Dictionary(surfaces[5]) if surfaces.size() > 5 else {}
	var polish_line: String = _build_polish_line(round_surface, next_surface, go_surface) if active else ""
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source.get("schema", "")),
		"source_status": String(source.get("status", "")),
		"source_issue_count": int(source.get("issue_count", 0)),
		"source_issues": Array(source.get("issues", [])).duplicate(true),
		"source_runtime_surface_specs": Array(source.get("source_runtime_surface_specs", [])).duplicate(true),
		"source_selected_fireteam_runtime_line": _resolve_text(source, "source_selected_fireteam_runtime_line"),
		"source_mission_control_runtime_line": _resolve_text(source, "source_mission_control_runtime_line"),
		"source_command_feedback_runtime_line": _resolve_text(source, "source_command_feedback_runtime_line"),
		"active": active,
		"round_loop_surface_specs": surfaces,
		"round_loop_surface_spec_count": surfaces.size(),
		"round_surface": round_surface,
		"next_surface": next_surface,
		"go_surface": go_surface,
		"selected_fireteam_runtime_surface": selected_surface,
		"mission_control_runtime_surface": mission_surface,
		"command_feedback_runtime_surface": feedback_surface,
		"round_loop_polish_line": polish_line,
		"visual_priority": "round_loop_readability",
		"status": "round_loop_visual_polish_ready" if active else "blocked",
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else "",
		"recommended_next_task": NEXT_TASK if active else "TASK_1006 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Polish",
		"recommended_direction": "build_round_loop_playability_slice" if active else "fix_round_loop_visual_polish_source",
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


static func _build_blockers(source: Dictionary) -> Array:
	var blockers: Array = []
	if String(source.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_1005-Source-Schema fehlt oder passt nicht."))
	if String(source.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1005."))
	if String(source.get("status", "")) not in ["ready_for_round_loop_visual_polish", "accepted_for_round_loop_playability_slice"]:
		blockers.append(_issue("source_not_polishable", "TASK_1005-Source ist nicht fuer TASK_1006 polishbar."))
	if not _snapshot_is_read_only(source):
		blockers.append(_issue("source_not_read_only", "TASK_1005-Source verletzt die read-only-Grenze."))
	if Array(source.get("source_runtime_surface_specs", [])).size() < 3:
		blockers.append(_issue("round_loop_surfaces_missing", "ROUND/NEXT/GO-Surfaces fehlen fuer TASK_1006."))
	if _resolve_text(source, "source_selected_fireteam_runtime_line").is_empty():
		blockers.append(_issue("selected_fireteam_runtime_line_missing", "Selected-Fireteam-Runtime-Zeile fehlt fuer TASK_1006."))
	if _resolve_text(source, "source_mission_control_runtime_line").is_empty():
		blockers.append(_issue("mission_control_runtime_line_missing", "Mission-Control-Runtime-Zeile fehlt fuer TASK_1006."))
	if _resolve_text(source, "source_command_feedback_runtime_line").is_empty():
		blockers.append(_issue("command_feedback_runtime_line_missing", "Command-Feedback-Runtime-Zeile fehlt fuer TASK_1006."))
	return blockers


static func _build_surface_specs(source: Dictionary) -> Array:
	var base_surfaces: Array = Array(source.get("source_runtime_surface_specs", []))
	return [
		_surface_spec("round_surface", "round_status", "ROUND", _surface_text(base_surfaces, 0, "ROUND bereit"), "round_loop_round_primary", "gold", 34.0, 1, 56),
		_surface_spec("next_surface", "next_decision", "NEXT", _surface_text(base_surfaces, 1, "NEXT Micro-Ziel waehlen"), "round_loop_next_primary", "mint", 34.0, 1, 64),
		_surface_spec("go_surface", "go_boundary", "GO", _surface_text(base_surfaces, 2, "GO separat bestaetigen"), "round_loop_go_boundary", "sky", 34.0, 1, 56),
		_surface_spec("selected_fireteam_runtime_surface", "selected_fireteam_runtime", "FT", _resolve_text(source, "source_selected_fireteam_runtime_line"), "round_loop_selected_runtime", "steel", 28.0, 1, 72),
		_surface_spec("mission_control_runtime_surface", "mission_control_runtime", "MC", _resolve_text(source, "source_mission_control_runtime_line"), "round_loop_mission_runtime", "steel", 30.0, 1, 72),
		_surface_spec("command_feedback_runtime_surface", "command_feedback_runtime", "CF", _resolve_text(source, "source_command_feedback_runtime_line"), "round_loop_feedback_runtime", "steel", 28.0, 1, 72),
	]


static func _surface_spec(surface_id: String, role: String, label: String, text: String, style_id: String, accent: String, min_height: float, max_lines: int, line_budget: int) -> Dictionary:
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
		"line_budget": line_budget,
		"line_within_budget": text.length() <= line_budget,
		"autowrap": true,
		"clip_text": true,
		"priority": "primary" if role in ["round_status", "next_decision", "go_boundary"] else "support",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
	}


static func _surface_text(base_surfaces: Array, index: int, fallback: String) -> String:
	if index < 0 or index >= base_surfaces.size():
		return fallback
	var surface: Dictionary = Dictionary(base_surfaces[index])
	var token: String = String(surface.get("token", "")).strip_edges()
	var text: String = String(surface.get("text", "")).strip_edges()
	if token.is_empty():
		return text if not text.is_empty() else fallback
	if text.begins_with(token):
		return text
	return "%s %s" % [token, text]


static func _build_polish_line(round_surface: Dictionary, next_surface: Dictionary, go_surface: Dictionary) -> String:
	return "ROUND %s | NEXT %s | GO %s" % [
		_compact_text(String(round_surface.get("text", "")), 32),
		_compact_text(String(next_surface.get("text", "")), 34),
		_compact_text(String(go_surface.get("text", "")), 30),
	]


static func _compact_text(text: String, max_length: int) -> String:
	var normalized: String = text.strip_edges()
	if normalized.length() <= max_length:
		return normalized
	return normalized.substr(0, maxi(max_length - 3, 0)).strip_edges() + "..."


static func _resolve_text(source: Dictionary, key: String) -> String:
	return String(source.get(key, "")).strip_edges()


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
