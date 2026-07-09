class_name ReleaseFirstDecisionLoopTwoPlayerLoopExtension
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_extension.v1"
const TASK_ID: String = "TASK_976"
const SOURCE_TASK_ID: String = "TASK_975"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_acceptance_slice.v1"
const NEXT_TASK: String = "TASK_977 - Release First Decision Loop Two Player Loop HUD Wiring"
const REVIEW_TASK: String = "TASK_976 - Release First Decision Loop Two Player Loop Extension"


static func build_snapshot(source_acceptance: Dictionary, tactical_context: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_acceptance)
	var active: bool = blockers.is_empty()
	var choices: Array = _build_next_player_choices(tactical_context) if active else []
	var recommended_choice_id: String = _recommend_choice(tactical_context)
	var primary_line: String = _build_primary_line(active, recommended_choice_id)
	var why_line: String = _build_why_line(active, tactical_context, recommended_choice_id)
	var visible_loop_line: String = _build_visible_loop_line(primary_line, choices) if active else ""
	var status: String = "ready_for_player_loop_extension" if active else "blocked"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_acceptance.get("schema", "")),
		"source_status": String(source_acceptance.get("status", "")),
		"source_gate": String(source_acceptance.get("gate", "")),
		"source_acceptance_slice_passed": bool(source_acceptance.get("acceptance_slice_passed", false)),
		"source_acceptance_line": String(source_acceptance.get("acceptance_line", "")),
		"source_answered_player_question_count": int(source_acceptance.get("answered_player_question_count", 0)),
		"tactical_context": tactical_context.duplicate(true),
		"active": active,
		"status": status,
		"primary_line": primary_line,
		"why_line": why_line,
		"visible_loop_line": visible_loop_line,
		"next_player_choices": choices,
		"next_choice_count": choices.size(),
		"recommended_choice_id": recommended_choice_id if active else "",
		"recommended_next_task": NEXT_TASK if active else REVIEW_TASK,
		"recommended_direction": "wire_loop_two_player_extension_to_hud" if active else "complete_loop_two_acceptance_slice",
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else "",
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


static func _build_blockers(source_acceptance: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_acceptance.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_975-Source-Schema fehlt oder passt nicht."))
	if String(source_acceptance.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_975."))
	if String(source_acceptance.get("gate", "")) != "loop_two_acceptance_slice_passed" or String(source_acceptance.get("status", "")) != "loop_two_acceptance_slice_passed":
		blockers.append(_issue("source_acceptance_not_passed", "TASK_975-Acceptance-Slice ist nicht bestanden."))
	if not bool(source_acceptance.get("acceptance_slice_passed", false)):
		blockers.append(_issue("source_acceptance_flag_missing", "TASK_975-Source setzt acceptance_slice_passed nicht."))
	if int(source_acceptance.get("answered_player_question_count", 0)) < 5:
		blockers.append(_issue("source_question_coverage_too_low", "TASK_975-Source beantwortet zu wenige Spielerfragen."))
	if not String(source_acceptance.get("acceptance_line", "")).contains("2ND"):
		blockers.append(_issue("source_acceptance_line_missing_2nd", "TASK_975-Acceptance-Zeile nennt 2ND nicht."))
	if not String(source_acceptance.get("acceptance_line", "")).contains("GO"):
		blockers.append(_issue("source_acceptance_line_missing_go", "TASK_975-Acceptance-Zeile nennt GO nicht."))
	if not _snapshot_is_read_only(source_acceptance):
		blockers.append(_issue("source_not_read_only", "TASK_975-Source verletzt die read-only-Grenze."))
	return blockers


static func _build_next_player_choices(tactical_context: Dictionary) -> Array:
	var objective_pressure: String = String(tactical_context.get("objective_pressure", "medium"))
	var contact_pressure: String = String(tactical_context.get("known_contact_pressure", "medium"))
	var team_condition: String = String(tactical_context.get("team_condition", "stable"))
	var ammo_pressure: String = String(tactical_context.get("ammo_pressure", "low"))
	return [
		{
			"choice_id": "secure_area",
			"label": "SECURE Bereich sichern",
			"player_text": "Winkel halten, Kontakte lesen, naechsten sicheren Schritt vorbereiten.",
			"command_hint": "Defend",
			"risk_label": "stabil",
			"why": "Team %s, Kontakt %s" % [team_condition, contact_pressure],
			"priority": 1,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"creates_command": false,
			"creates_movement": false,
		},
		{
			"choice_id": "push_objective",
			"label": "PUSH Ziel druecken",
			"player_text": "Gedeckt Richtung Ziel nachsetzen, Preview pruefen, dann GO.",
			"command_hint": "Move/Take",
			"risk_label": "riskant",
			"why": "OBJ %s, Kontakt %s" % [objective_pressure, contact_pressure],
			"priority": 2,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"creates_command": false,
			"creates_movement": false,
		},
		{
			"choice_id": "flank_pressure",
			"label": "FLANK Druck drehen",
			"player_text": "Seitlichen Winkel vorbereiten, Friendly-Fire- und LOS-Risiko lesen.",
			"command_hint": "Flank",
			"risk_label": "hoch",
			"why": "Kontakt %s, braucht klare Linie" % contact_pressure,
			"priority": 3,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"creates_command": false,
			"creates_movement": false,
		},
		{
			"choice_id": "reset_spacing",
			"label": "RESET neu sammeln",
			"player_text": "Spacing beruhigen, Munition/Status lesen, dann neuen Griff waehlen.",
			"command_hint": "Move/Defend",
			"risk_label": "vorsichtig",
			"why": "Munition %s, Team %s" % [ammo_pressure, team_condition],
			"priority": 4,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"creates_command": false,
			"creates_movement": false,
		},
	]


static func _recommend_choice(tactical_context: Dictionary) -> String:
	var objective_pressure: String = String(tactical_context.get("objective_pressure", "medium"))
	var contact_pressure: String = String(tactical_context.get("known_contact_pressure", "medium"))
	var team_condition: String = String(tactical_context.get("team_condition", "stable"))
	if team_condition in ["wounded", "shaken", "panic"]:
		return "reset_spacing"
	if objective_pressure == "high" and contact_pressure != "high":
		return "push_objective"
	if contact_pressure == "high":
		return "secure_area"
	return "secure_area"


static func _build_primary_line(active: bool, recommended_choice_id: String) -> String:
	if not active:
		return ""
	var token: String = _choice_token(recommended_choice_id)
	return "NEXT %s -> SECURE / PUSH / FLANK / RESET" % token


static func _build_why_line(active: bool, tactical_context: Dictionary, recommended_choice_id: String) -> String:
	if not active:
		return ""
	var objective_pressure: String = String(tactical_context.get("objective_pressure", "medium")).to_upper()
	var contact_pressure: String = String(tactical_context.get("known_contact_pressure", "medium")).to_upper()
	var token: String = _choice_token(recommended_choice_id)
	return "WHY %s | OBJ %s | CONTACT %s | nach 2ND wieder echte Wahl" % [token, objective_pressure, contact_pressure]


static func _build_visible_loop_line(primary_line: String, choices: Array) -> String:
	var tokens: PackedStringArray = PackedStringArray()
	for choice_variant in choices:
		var label: String = String(Dictionary(choice_variant).get("label", "")).strip_edges()
		if not label.is_empty():
			tokens.append(label.split(" ")[0])
	return "%s | %s" % [primary_line, " / ".join(tokens)]


static func _choice_token(choice_id: String) -> String:
	match choice_id:
		"push_objective":
			return "PUSH"
		"flank_pressure":
			return "FLANK"
		"reset_spacing":
			return "RESET"
		_:
			return "SECURE"


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
