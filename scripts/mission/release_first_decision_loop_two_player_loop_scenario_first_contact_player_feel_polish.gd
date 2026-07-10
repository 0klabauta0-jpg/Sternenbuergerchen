class_name ReleaseFirstDecisionLoopTwoPlayerLoopScenarioFirstContactPlayerFeelPolish
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish.v1"
const TASK_ID: String = "TASK_1036"
const SOURCE_TASK_ID: String = "TASK_1035"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings.v1"
const NEXT_TASK: String = "TASK_1037 - Release First Decision Loop Two Player Loop Scenario First Contact Playability Slice"


static func build_snapshot(source_findings: Dictionary) -> Dictionary:
	var source: Dictionary = source_findings.duplicate(true)
	var blockers: Array = _build_blockers(source)
	var active: bool = blockers.is_empty()
	var surfaces: Array = _build_surface_specs(source) if active else []
	var accepted_source: bool = String(source.get("status", "")) == "accepted_for_first_contact_playability_slice"
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
		"source_first_contact_player_feel_summary_line": String(source.get("first_contact_player_feel_summary_line", "")),
		"source_smoke_line": String(source.get("source_smoke_line", "")),
		"active": active,
		"first_contact_player_feel_surface_specs": surfaces,
		"first_contact_player_feel_surface_spec_count": surfaces.size(),
		"contact_surface": Dictionary(surfaces[0]) if surfaces.size() > 0 else {},
		"why_surface": Dictionary(surfaces[1]) if surfaces.size() > 1 else {},
		"next_surface": Dictionary(surfaces[2]) if surfaces.size() > 2 else {},
		"feedback_surface": Dictionary(surfaces[3]) if surfaces.size() > 3 else {},
		"go_boundary_surface": Dictionary(surfaces[4]) if surfaces.size() > 4 else {},
		"hud_multiplayer_surface": Dictionary(surfaces[5]) if surfaces.size() > 5 else {},
		"first_contact_player_feel_polish_line": _build_polish_line(source, accepted_source) if active else "",
		"first_contact_next_grip_line": _build_next_grip_line(source) if active else "",
		"first_contact_go_boundary_microcopy": _build_go_boundary_microcopy(source) if active else "",
		"first_contact_calm_hud_guidance": _build_calm_hud_guidance(source) if active else "",
		"first_contact_performance_feedback_hint": _build_performance_feedback_hint(source) if active else "",
		"ready_for_first_contact_playability_review": active,
		"status": "first_contact_player_feel_polish_ready" if active else "blocked",
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else "",
		"recommended_next_task": NEXT_TASK if active else "TASK_1036 - Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Polish",
		"recommended_direction": "build_first_contact_playability_slice" if active else "fix_first_contact_player_feel_polish_source",
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
		blockers.append(_issue("source_schema_mismatch", "TASK_1035-Source-Schema fehlt oder passt nicht."))
	if String(source.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_1035."))
	if String(source.get("status", "")) not in ["first_contact_player_feel_rework_needed", "accepted_for_first_contact_playability_slice"]:
		blockers.append(_issue("source_not_polishable", "TASK_1035-Source ist nicht fuer TASK_1036 polishbar."))
	if String(source.get("first_contact_player_feel_summary_line", "")).strip_edges().is_empty():
		blockers.append(_issue("source_first_contact_player_feel_summary_missing", "TASK_1035-First-Contact-Player-Feel-Summary fehlt."))
	if not _snapshot_is_read_only(source):
		blockers.append(_issue("source_not_read_only", "TASK_1035-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_surface_specs(source: Dictionary) -> Array:
	return [
		_surface_spec("contact_surface", "contact_line", "CONTACT", _contact_text(source), "first_contact_contact_primary", "mint", 32.0, 78),
		_surface_spec("why_surface", "why_actionable", "WHY", _why_text(source), "first_contact_why_primary", "gold", 34.0, 82),
		_surface_spec("next_surface", "next_grip", "NEXT", _next_text(source), "first_contact_next_primary", "sky", 32.0, 78),
		_surface_spec("feedback_surface", "feedback_next", "FEEDBACK", _feedback_text(source), "first_contact_feedback_next", "sky", 30.0, 82),
		_surface_spec("go_boundary_surface", "go_boundary", "GO", _build_go_boundary_microcopy(source), "first_contact_go_boundary", "amber", 30.0, 74),
		_surface_spec("hud_multiplayer_surface", "hud_multiplayer_boundary", "HUD/MP", _hud_multiplayer_text(source), "first_contact_hud_mp_boundary", "steel", 30.0, 82),
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
		"priority": "primary" if role in ["contact_line", "why_actionable", "next_grip", "go_boundary"] else "support",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
	}


static func _contact_text(source: Dictionary) -> String:
	if _has_issue(source, "contact_line_feels_unclear"):
		return "CONTACT klar: wer sieht wen, Entfernung und Risiko in einer ruhigen Zeile."
	return "CONTACT rund: Kontakt, Distanz und Gefahr sofort lesbar."


static func _why_text(source: Dictionary) -> String:
	if _has_issue(source, "why_not_actionable"):
		return "WHY handlungsfaehig: Sicht, Deckung und Gefahr kurz begruenden."
	return "WHY klar: die Lage erklaert, warum der naechste Griff sinnvoll ist."


static func _next_text(source: Dictionary) -> String:
	if _has_issue(source, "next_grip_feels_unclear"):
		return "NEXT sichtbar: naechster Griff nach dem Kontakt bleibt angeboten."
	return "NEXT bereit: nach Kontakt bleibt der naechste taktische Griff sichtbar."


static func _feedback_text(source: Dictionary) -> String:
	if _has_issue(source, "first_contact_feedback_feels_dry"):
		return "Feedback nennt Ergebnis und fuehrt direkt zum naechsten Kontaktgriff."
	return "Feedback bestaetigt Wirkung und fuehrt ruhig zur naechsten Entscheidung."


static func _build_go_boundary_microcopy(source: Dictionary) -> String:
	if _has_issue(source, "go_boundary_not_felt"):
		return "GO separat: bestaetigt ist noch nicht ausgefuehrt."
	return "GO separat: Preview bleibt Preview, Ausfuehrung erst mit GO."


static func _build_calm_hud_guidance(source: Dictionary) -> String:
	if _has_issue(source, "first_contact_hud_feels_noisy"):
		return "HUD ruhig halten: CONTACT, WHY, NEXT, GO und Feedback gezielt akzentuieren."
	return "HUD ruhig: wenige starke Tokens, keine wandernde Wahrheit."


static func _build_performance_feedback_hint(source: Dictionary) -> String:
	if _has_issue(source, "first_contact_performance_feels_sluggish"):
		return "Polish bleibt Snapshot-basiert; keine UI-Baeume pro Frame neu bauen."
	return "Responsiveness bleibt schnell: Snapshot lesen, gezielt refreshen."


static func _hud_multiplayer_text(source: Dictionary) -> String:
	if _has_issue(source, "first_contact_multiplayer_boundary_feels_unclear"):
		return "HUD/MP-Grenze sichtbar: HUD liest nur, Runtime/Simulation entscheidet."
	return "HUD/MP klar: Preview und Feedback setzen keine Gameplay-Wahrheit."


static func _build_polish_line(source: Dictionary, accepted_source: bool) -> String:
	if accepted_source:
		return "CONTACT rund | WHY klar | NEXT bereit | GO separat"
	return "CONTACT ruhiger | WHY handlungsfaehig | NEXT lesbar | GO separat"


static func _build_next_grip_line(source: Dictionary) -> String:
	if _has_issue(source, "next_grip_feels_unclear") or _has_issue(source, "first_contact_feedback_feels_dry"):
		return "NEXT: Nach CONTACT und Feedback wieder einen klaren Kontaktgriff anbieten."
	return "NEXT: Naechste First-Contact-Entscheidung bleibt direkt sichtbar."


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
