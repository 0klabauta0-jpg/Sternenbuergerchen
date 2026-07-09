class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioPlayerFeelPolish
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_player_feel_polish.v1"
const TASK_ID: String = "TASK_1016"
const SOURCE_TASK_ID: String = "TASK_1015"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_player_feel_findings.v1"
const NEXT_TASK: String = "TASK_1017 - Release First Decision Loop Two Player Loop Scenario Playability Slice"


static func build_snapshot(source_findings: Dictionary) -> Dictionary:
	var source: Dictionary = source_findings.duplicate(true)
	var blockers: Array = _build_blockers(source)
	var active: bool = blockers.is_empty()
	var surfaces: Array = _build_surface_specs(source) if active else []
	var accepted_source: bool = String(source.get("status", "")) == "accepted_for_scenario_playability_slice"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source.get("schema", "")),
		"source_status": String(source.get("status", "")),
		"source_gate": String(source.get("gate", "")),
		"source_issue_count": int(source.get("issue_count", 0)),
		"source_issues": Array(source.get("issues", [])).duplicate(true),
		"source_positive_findings": Array(source.get("positive_findings", [])).duplicate(true),
		"source_scenario_player_feel_summary_line": String(source.get("scenario_player_feel_summary_line", "")),
		"source_smoke_line": String(source.get("source_smoke_line", "")),
		"active": active,
		"scenario_player_feel_surface_specs": surfaces,
		"scenario_player_feel_surface_spec_count": surfaces.size(),
		"entry_surface": Dictionary(surfaces[0]) if surfaces.size() > 0 else {},
		"objective_surface": Dictionary(surfaces[1]) if surfaces.size() > 1 else {},
		"roles_surface": Dictionary(surfaces[2]) if surfaces.size() > 2 else {},
		"flow_surface": Dictionary(surfaces[3]) if surfaces.size() > 3 else {},
		"feedback_surface": Dictionary(surfaces[4]) if surfaces.size() > 4 else {},
		"go_boundary_surface": Dictionary(surfaces[5]) if surfaces.size() > 5 else {},
		"multiplayer_surface": Dictionary(surfaces[6]) if surfaces.size() > 6 else {},
		"scenario_player_feel_polish_line": _build_polish_line(source, accepted_source) if active else "",
		"scenario_next_grip_line": _build_next_grip_line(source) if active else "",
		"scenario_go_boundary_microcopy": _build_go_boundary_microcopy(source) if active else "",
		"scenario_calm_hud_guidance": _build_calm_hud_guidance(source) if active else "",
		"scenario_performance_feedback_hint": _build_performance_feedback_hint(source) if active else "",
		"ready_for_scenario_playability_review": active,
		"status": "scenario_player_feel_polish_ready" if active else "blocked",
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else "",
		"recommended_next_task": NEXT_TASK if active else "TASK_1016 - Release First Decision Loop Two Player Loop Scenario Player Feel Polish",
		"recommended_direction": "build_scenario_playability_slice" if active else "fix_scenario_player_feel_polish_source",
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
		blockers.append(_issue("source_schema_mismatch", "TASK_1015-Source-Schema fehlt oder passt nicht."))
	if String(source.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1015."))
	if String(source.get("status", "")) not in ["scenario_player_feel_rework_needed", "accepted_for_scenario_playability_slice"]:
		blockers.append(_issue("source_not_polishable", "TASK_1015-Source ist nicht fuer TASK_1016 polishbar."))
	if String(source.get("scenario_player_feel_summary_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_scenario_player_feel_summary_missing", "TASK_1015-Scenario-Player-Feel-Summary fehlt."))
	if not _snapshot_is_read_only(source):
		blockers.append(_issue("source_not_read_only", "TASK_1015-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_surface_specs(source: Dictionary) -> Array:
	return [
		_surface_spec("entry_surface", "scenario_entry", "FOB", _entry_text(source), "scenario_feel_entry_calm", "mint", 32.0, 72),
		_surface_spec("objective_surface", "fob_objective", "OBJ", _objective_text(source), "scenario_feel_objective_primary", "gold", 32.0, 76),
		_surface_spec("roles_surface", "two_player_roles", "ROLES", _roles_text(source), "scenario_feel_roles", "sky", 30.0, 78),
		_surface_spec("flow_surface", "next_confirm_go_flow", "NEXT", _flow_text(source), "scenario_feel_flow_primary", "gold", 34.0, 82),
		_surface_spec("feedback_surface", "scenario_feedback", "FEEDBACK", _feedback_text(source), "scenario_feel_feedback_next", "sky", 30.0, 78),
		_surface_spec("go_boundary_surface", "go_boundary", "GO", _build_go_boundary_microcopy(source), "scenario_feel_go_boundary", "amber", 30.0, 72),
		_surface_spec("multiplayer_surface", "multiplayer_boundary", "MP", _multiplayer_text(source), "scenario_feel_multiplayer_boundary", "steel", 28.0, 78),
	]


static func _surface_spec(surface_id: String, role: String, label: String, text: String, style_id: String, accent: String, min_height: float, line_budget: int) -> Dictionary:
	return {
		"surface_id": surface_id,
		"role": role,
		"label": label,
		"text": _compact_text(text, line_budget),
		"display_text": "%s: %s" % [label, _compact_text(text, line_budget)],
		"style_id": style_id,
		"accent": accent,
		"min_height": min_height,
		"max_lines": 2,
		"line_budget": line_budget,
		"line_within_budget": text.length() <= line_budget,
		"autowrap": true,
		"clip_text": true,
		"priority": "primary" if role in ["fob_objective", "next_confirm_go_flow", "scenario_feedback", "go_boundary"] else "support",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
	}


static func _entry_text(source: Dictionary) -> String:
	if _has_issue(source, "scenario_entry_feels_unclear"):
		return "FOB-Start sichtbar: Ort, Rolle und erster NEXT-Griff in einer ruhigen Zeile."
	return "FOB-Start klar: sofort sehen, wo der kleine Szenario-Griff beginnt."


static func _objective_text(source: Dictionary) -> String:
	if _has_issue(source, "fob_objective_feels_unclear"):
		return "Objective konkret: Relais sichern, Druck halten, danach NEXT anbieten."
	return "Objective bleibt konkret: sichern, Druck nehmen, naechsten Griff sehen."


static func _roles_text(source: Dictionary) -> String:
	if _has_issue(source, "two_player_roles_feel_unclear"):
		return "Alpha sichert den Griff, Bravo haelt Druck; beide Rollen kurz lesbar."
	return "Alpha/Bravo lesbar: ein Team sichert, eins haelt Druck."


static func _flow_text(source: Dictionary) -> String:
	if _has_issue(source, "scenario_go_boundary_not_felt"):
		return "NEXT waehlen -> CONFIRM lesen -> GO bewusst getrennt ausfuehren."
	return "NEXT/CONFIRM/GO bleibt ein ruhiger Ablauf mit sichtbarer Grenze."


static func _feedback_text(source: Dictionary) -> String:
	if _has_issue(source, "scenario_feedback_feels_dry"):
		return "Feedback nennt Ergebnis und fuehrt direkt zum naechsten Szenario-Griff."
	return "Feedback bestaetigt den Griff und macht den naechsten NEXT-Zustand sichtbar."


static func _build_go_boundary_microcopy(source: Dictionary) -> String:
	if _has_issue(source, "scenario_go_boundary_not_felt"):
		return "GO separat: bestaetigt ist noch nicht ausgefuehrt."
	return "GO separat: kein Auto-Ausfuehren nach NEXT oder CONFIRM."


static func _build_calm_hud_guidance(source: Dictionary) -> String:
	if _has_issue(source, "scenario_hud_feels_noisy"):
		return "HUD ruhig halten: nur FOB, OBJ, NEXT, GO und Feedback akzentuieren."
	return "HUD ruhig: starke Tokens, wenig Flaechenwechsel, keine Tutorialwand."


static func _build_performance_feedback_hint(source: Dictionary) -> String:
	if _has_issue(source, "scenario_performance_feels_sluggish"):
		return "Polish bleibt Snapshot-basiert; keine UI-Baeume pro Frame neu bauen."
	return "Responsiveness bleibt schnell: Snapshot lesen, UI gezielt refreshen."


static func _multiplayer_text(source: Dictionary) -> String:
	if _has_issue(source, "scenario_multiplayer_boundary_feels_unclear"):
		return "MP-Grenze sichtbar: HUD liest nur, Runtime/Simulation entscheidet."
	return "MP-Grenze klar: Preview und Feedback setzen keine Gameplay-Wahrheit."


static func _build_polish_line(source: Dictionary, accepted_source: bool) -> String:
	if accepted_source:
		return "FOB rund | Rollen klar | NEXT bereit | GO separat"
	return "FOB ruhiger | Objective klarer | NEXT lesbar | GO separat"


static func _build_next_grip_line(source: Dictionary) -> String:
	if _has_issue(source, "scenario_feedback_feels_dry"):
		return "NEXT: Nach Feedback wieder einen klaren Szenario-Griff anbieten."
	return "NEXT: Naechste Szenario-Entscheidung bleibt direkt sichtbar."


static func _has_issue(source: Dictionary, issue_id: String) -> bool:
	for issue_variant in Array(source.get("issues", [])):
		if typeof(issue_variant) == TYPE_DICTIONARY and String(Dictionary(issue_variant).get("id", "")) == issue_id:
			return true
	return false


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
