class_name ReleaseFirstDecisionLoopTwoPlayerLoopMicroObjectiveRoundLoopPlayerFeelPolish
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_polish.v1"
const TASK_ID: String = "TASK_1010"
const SOURCE_TASK_ID: String = "TASK_1009"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings.v1"
const NEXT_TASK: String = "TASK_1011 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Acceptance Slice"


static func build_snapshot(source_findings: Dictionary) -> Dictionary:
	var source: Dictionary = source_findings.duplicate(true)
	var blockers: Array = _build_blockers(source)
	var active: bool = blockers.is_empty()
	var surfaces: Array = _build_surface_specs(source) if active else []
	var entry_surface: Dictionary = Dictionary(surfaces[0]) if surfaces.size() > 0 else {}
	var rhythm_surface: Dictionary = Dictionary(surfaces[1]) if surfaces.size() > 1 else {}
	var feedback_surface: Dictionary = Dictionary(surfaces[2]) if surfaces.size() > 2 else {}
	var go_boundary_surface: Dictionary = Dictionary(surfaces[3]) if surfaces.size() > 3 else {}
	var hud_surface: Dictionary = Dictionary(surfaces[4]) if surfaces.size() > 4 else {}
	var multiplayer_surface: Dictionary = Dictionary(surfaces[5]) if surfaces.size() > 5 else {}
	var accepted_source: bool = String(source.get("status", "")) == "accepted_for_round_loop_acceptance_slice"
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
		"source_player_feel_summary_line": String(source.get("player_feel_summary_line", "")),
		"source_integrated_playtest_line": String(source.get("source_integrated_playtest_line", "")),
		"active": active,
		"player_feel_surface_specs": surfaces,
		"player_feel_surface_spec_count": surfaces.size(),
		"entry_surface": entry_surface,
		"rhythm_surface": rhythm_surface,
		"feedback_surface": feedback_surface,
		"go_boundary_surface": go_boundary_surface,
		"hud_surface": hud_surface,
		"multiplayer_surface": multiplayer_surface,
		"player_feel_polish_line": _build_polish_line(source, accepted_source) if active else "",
		"next_grip_line": _build_next_grip_line(source) if active else "",
		"go_boundary_microcopy": _build_go_boundary_microcopy(source) if active else "",
		"calm_hud_guidance": _build_calm_hud_guidance(source) if active else "",
		"performance_feedback_hint": _build_performance_feedback_hint(source) if active else "",
		"ready_for_acceptance_review": active,
		"status": "round_loop_player_feel_polish_ready" if active else "blocked",
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else "",
		"recommended_next_task": NEXT_TASK if active else "TASK_1010 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Polish",
		"recommended_direction": "build_round_loop_acceptance_slice" if active else "fix_round_loop_player_feel_polish_source",
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
		blockers.append(_issue("source_schema_mismatch", "TASK_1009-Source-Schema fehlt oder passt nicht."))
	if String(source.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1009."))
	if String(source.get("status", "")) not in ["round_loop_player_feel_rework_needed", "accepted_for_round_loop_acceptance_slice"]:
		blockers.append(_issue("source_not_polishable", "TASK_1009-Source ist nicht fuer TASK_1010 polishbar."))
	if String(source.get("player_feel_summary_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_player_feel_summary_missing", "TASK_1009-Player-Feel-Summary fehlt."))
	if not _snapshot_is_read_only(source):
		blockers.append(_issue("source_not_read_only", "TASK_1009-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_surface_specs(source: Dictionary) -> Array:
	return [
		_surface_spec("entry_surface", "entry_clarity", "START", _entry_text(source), "player_feel_entry_calm", "mint", 30.0, 56),
		_surface_spec("rhythm_surface", "round_next_go_rhythm", "RHYTHM", _rhythm_text(source), "player_feel_rhythm_primary", "gold", 32.0, 72),
		_surface_spec("feedback_surface", "feedback_next_grip", "FEEDBACK", _feedback_text(source), "player_feel_feedback_next", "sky", 30.0, 72),
		_surface_spec("go_boundary_surface", "go_boundary", "GO", _build_go_boundary_microcopy(source), "player_feel_go_boundary", "amber", 30.0, 64),
		_surface_spec("hud_surface", "hud_calm", "HUD", _build_calm_hud_guidance(source), "player_feel_hud_calm", "steel", 28.0, 76),
		_surface_spec("multiplayer_surface", "multiplayer_boundary", "MP", _multiplayer_text(source), "player_feel_multiplayer_boundary", "steel", 28.0, 76),
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
		"priority": "primary" if role in ["round_next_go_rhythm", "feedback_next_grip", "go_boundary"] else "support",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
	}


static func _entry_text(source: Dictionary) -> String:
	if _has_issue(source, "entry_feels_unclear"):
		return "Start klar: Mission, ROUND und erster NEXT-Griff in einer ruhigen Zeile."
	return "Start klar: direkt sehen, was die Runde ist und welcher Griff als naechstes kommt."


static func _rhythm_text(source: Dictionary) -> String:
	if _has_issue(source, "round_next_go_rhythm_not_clear"):
		return "ROUND gelesen -> NEXT waehlen -> GO separat; der Ablauf bleibt sichtbar."
	return "ROUND/NEXT/GO wirkt als ruhiger Ablauf mit getrennter Ausfuehrung."


static func _feedback_text(source: Dictionary) -> String:
	if _has_issue(source, "feedback_feels_dry"):
		return "Feedback nennt Ergebnis und sofort den naechsten Griff statt nur Status."
	return "Feedback bestaetigt die Runde und fuehrt lesbar zurueck zu NEXT."


static func _build_go_boundary_microcopy(source: Dictionary) -> String:
	if _has_issue(source, "go_boundary_not_felt"):
		return "GO bleibt bewusst separat: erst planen, dann ausfuehren."
	return "GO separat: kein Auto-Ausfuehren nach Auswahl oder Confirm."


static func _build_calm_hud_guidance(source: Dictionary) -> String:
	if _has_issue(source, "hud_feels_noisy"):
		return "HUD ruhig halten: nur ROUND, NEXT, GO und Feedback akzentuieren."
	return "HUD ruhig: wenige starke Tokens, keine laute Nebenflaeche."


static func _build_performance_feedback_hint(source: Dictionary) -> String:
	if _has_issue(source, "performance_feels_sluggish"):
		return "Feedback getaktet halten; keine UI-Baeume pro Frame neu bauen."
	return "Performance-Gefuehl bleibt schnell: Snapshot lesen, UI nur gezielt refreshen."


static func _multiplayer_text(source: Dictionary) -> String:
	if _has_issue(source, "multiplayer_boundary_feels_unclear"):
		return "MP-Grenze klar: HUD zeigt nur Preview, Ausfuehrung bleibt autoritativ."
	return "MP-Grenze sichtbar: Preview liest, Gameplay-Wahrheit bleibt Runtime/Simulation."


static func _build_polish_line(source: Dictionary, accepted_source: bool) -> String:
	if accepted_source:
		return "FEEL rund | NEXT klar | GO separat | HUD ruhig"
	return "FEEL ruhiger | NEXT klarer | GO separat | Feedback fuehrt weiter"


static func _build_next_grip_line(source: Dictionary) -> String:
	if _has_issue(source, "feedback_feels_dry"):
		return "NEXT: Nach Feedback wieder einen klaren Griff anbieten."
	return "NEXT: Naechste Entscheidung bleibt direkt nach Feedback sichtbar."


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
