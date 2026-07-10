class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioFirstContactVisualPolish
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish.v1"
const TASK_ID: String = "TASK_1040"
const SOURCE_TASK_ID: String = "TASK_1039"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_visual_findings.v1"
const NEXT_TASK: String = "TASK_1041 - Release First Decision Loop Two Player Loop Scenario First Contact Acceptance Slice"


static func build_snapshot(source_findings: Dictionary) -> Dictionary:
	var source: Dictionary = source_findings.duplicate(true)
	var blockers: Array = _build_blockers(source)
	var active: bool = blockers.is_empty()
	var surfaces: Array = _build_surface_specs(source) if active else []
	var contact_surface: Dictionary = Dictionary(surfaces[0]) if surfaces.size() > 0 else {}
	var why_surface: Dictionary = Dictionary(surfaces[1]) if surfaces.size() > 1 else {}
	var next_surface: Dictionary = Dictionary(surfaces[2]) if surfaces.size() > 2 else {}
	var fire_wait_surface: Dictionary = Dictionary(surfaces[3]) if surfaces.size() > 3 else {}
	var feedback_surface: Dictionary = Dictionary(surfaces[4]) if surfaces.size() > 4 else {}
	var go_surface: Dictionary = Dictionary(surfaces[5]) if surfaces.size() > 5 else {}
	var hud_surface: Dictionary = Dictionary(surfaces[6]) if surfaces.size() > 6 else {}
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source.get("schema", "")),
		"source_status": String(source.get("status", "")),
		"source_issue_count": int(source.get("issue_count", 0)),
		"source_issues": Array(source.get("issues", [])).duplicate(true),
		"source_positive_findings": Array(source.get("positive_findings", [])).duplicate(true),
		"source_first_contact_visual_findings_summary_line": String(source.get("first_contact_visual_findings_summary_line", "")),
		"source_first_contact_playability_line": String(source.get("source_first_contact_playability_line", "")),
		"active": active,
		"first_contact_visual_surface_specs": surfaces,
		"first_contact_visual_surface_spec_count": surfaces.size(),
		"contact_surface": contact_surface,
		"why_surface": why_surface,
		"next_surface": next_surface,
		"fire_wait_surface": fire_wait_surface,
		"feedback_surface": feedback_surface,
		"go_boundary_surface": go_surface,
		"hud_multiplayer_surface": hud_surface,
		"first_contact_visual_polish_line": _build_polish_line(source) if active else "",
		"first_contact_next_line": _build_next_line(source) if active else "",
		"first_contact_fire_wait_microcopy": _fire_wait_text(source) if active else "",
		"first_contact_go_boundary_microcopy": _go_text(source) if active else "",
		"visual_priority": "first_contact_decision_readability",
		"status": "first_contact_visual_polish_ready" if active else "blocked",
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else "",
		"recommended_next_task": NEXT_TASK if active else "TASK_1040 - Release First Decision Loop Two Player Loop Scenario First Contact Visual Polish",
		"recommended_direction": "build_first_contact_acceptance_slice" if active else "fix_first_contact_visual_polish_source",
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
		blockers.append(_issue("source_schema_mismatch", "TASK_1039-Source-Schema fehlt oder passt nicht."))
	if String(source.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1039."))
	if String(source.get("status", "")) not in ["ready_for_first_contact_visual_polish", "accepted_for_first_contact_acceptance_slice"]:
		blockers.append(_issue("source_not_polishable", "TASK_1039-Source ist nicht fuer TASK_1040 polishbar."))
	if String(source.get("first_contact_visual_findings_summary_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_visual_summary_missing", "TASK_1039-Visual-Findings-Summary fehlt."))
	if not _snapshot_is_read_only(source):
		blockers.append(_issue("source_not_read_only", "TASK_1039-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_surface_specs(source: Dictionary) -> Array:
	return [
		_surface_spec("contact_surface", "contact_line", "CONTACT", _contact_text(source), "first_contact_visual_contact_primary", "mint", 34.0, 2, 82),
		_surface_spec("why_surface", "why_actionable", "WHY", _why_text(source), "first_contact_visual_why_primary", "gold", 36.0, 2, 86),
		_surface_spec("next_surface", "next_grip", "NEXT", _next_text(source), "first_contact_visual_next_primary", "sky", 34.0, 2, 78),
		_surface_spec("fire_wait_surface", "fire_wait_choice", "FIRE/WAIT", _fire_wait_text(source), "first_contact_visual_fire_wait_choice", "amber", 34.0, 2, 82),
		_surface_spec("feedback_surface", "feedback_line", "FEEDBACK", _feedback_text(source), "first_contact_visual_feedback_line", "steel", 30.0, 2, 82),
		_surface_spec("go_boundary_surface", "go_boundary", "GO", _go_text(source), "first_contact_visual_go_boundary", "amber", 32.0, 2, 76),
		_surface_spec("hud_multiplayer_surface", "hud_multiplayer_boundary", "HUD/MP", _hud_text(source), "first_contact_visual_hud_mp_boundary", "steel", 30.0, 2, 82),
	]


static func _surface_spec(surface_id: String, role: String, label: String, text: String, style_id: String, accent: String, min_height: float, max_lines: int, line_budget: int) -> Dictionary:
	var compact: String = _compact_text(text, line_budget)
	return {
		"surface_id": surface_id,
		"role": role,
		"label": label,
		"text": compact,
		"display_text": "%s: %s" % [label, compact],
		"style_id": style_id,
		"accent": accent,
		"min_height": min_height,
		"max_lines": max_lines,
		"line_budget": line_budget,
		"line_within_budget": text.length() <= line_budget,
		"autowrap": true,
		"clip_text": true,
		"priority": "primary" if role in ["contact_line", "why_actionable", "next_grip", "fire_wait_choice", "go_boundary"] else "support",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
	}


static func _contact_text(source: Dictionary) -> String:
	if _has_issue(source, "contact_surface_not_visible"):
		return "CONTACT zuerst: wer sieht wen, Risiko und Reichweite ruhig markieren."
	return "CONTACT sichtbar: Kontakt, Risiko und Quelle in einer klaren Zeile."


static func _why_text(source: Dictionary) -> String:
	if _has_issue(source, "why_surface_not_actionable"):
		return "WHY handlungsfaehig: Gefahr, Deckung und Grund fuer die Wahl nennen."
	return "WHY klar: Lage erklaert, warum FIRE/WAIT oder Move sinnvoll ist."


static func _next_text(source: Dictionary) -> String:
	if _has_issue(source, "next_surface_not_visible"):
		return "NEXT sichtbar halten: naechsten taktischen Griff direkt anbieten."
	return "NEXT bereit: nach CONTACT bleibt die naechste Entscheidung sichtbar."


static func _fire_wait_text(source: Dictionary) -> String:
	if _has_issue(source, "fire_wait_choice_not_visible"):
		return "FIRE/WAIT sichtbar: Feuer eroeffnen oder Kontakt halten als echte Wahl."
	return "FIRE/WAIT lesbar: Spieler sieht Feuerwahl vor GO."


static func _feedback_text(source: Dictionary) -> String:
	if _has_issue(source, "feedback_line_not_visible"):
		return "Feedback sichtbar: Entscheidung bestaetigen und wieder zu NEXT fuehren."
	return "Feedback bestaetigt Wirkung und fuehrt ruhig zur naechsten Entscheidung."


static func _go_text(source: Dictionary) -> String:
	if _has_issue(source, "go_boundary_not_visible"):
		return "GO separat: Preview und Wahl sind noch keine Ausfuehrung."
	return "GO separat: Ausfuehrung erst nach bewusstem Commit."


static func _hud_text(source: Dictionary) -> String:
	if _has_issue(source, "hud_too_noisy") or _has_issue(source, "multiplayer_boundary_unclear"):
		return "HUD/MP klar: HUD liest nur, Runtime und Simulation entscheiden."
	return "HUD/MP ruhig: Anzeige bleibt read-only, Multiplayer-Wahrheit bleibt getrennt."


static func _build_polish_line(source: Dictionary) -> String:
	if String(source.get("status", "")) == "accepted_for_first_contact_acceptance_slice":
		return "CONTACT rund | WHY klar | NEXT bereit | FIRE/WAIT sichtbar | GO separat"
	return "CONTACT staerken | WHY handlungsfaehig | NEXT sichtbar | FIRE/WAIT klar | GO separat"


static func _build_next_line(source: Dictionary) -> String:
	if _has_issue(source, "next_surface_not_visible") or _has_issue(source, "feedback_line_not_visible"):
		return "NEXT: Nach CONTACT/Feedback wieder einen klaren Kontaktgriff anbieten."
	return "NEXT: Erste Kontaktentscheidung bleibt direkt anschlussfaehig."


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
