class_name ReleaseFirstDecisionNextPlayableLoop
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_next_playable_loop.v1"
const TASK_ID: String = "TASK_963"
const SOURCE_TASK_ID: String = "TASK_962"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_playtest_findings.v1"
const FIRST_DECISION_SCHEMA: String = "sternenbuergerchen.first_decision_micro_scenario_polish.v1"
const NEXT_TASK: String = "TASK_964 - Release First Decision Loop Two Playtest"


static func build_snapshot(source_findings: Dictionary, first_decision: Dictionary, firefight_decision: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	var live_preview: bool = bool(context.get("allow_live_preview_without_task_962_acceptance", false))
	var source_accepted: bool = _source_findings_are_accepted(source_findings)
	var blockers: Array = _build_blockers(source_findings, first_decision, live_preview, source_accepted)
	var second_choices: Array = _build_second_decision_choices(firefight_decision)
	var active: bool = blockers.is_empty() and (source_accepted or live_preview) and not second_choices.is_empty()
	var primary_line: String = _build_primary_line(firefight_decision, active)
	var why_line: String = _build_why_line(firefight_decision, active)
	var visible_loop_line: String = _build_visible_loop_line(primary_line, second_choices) if active else ""
	var status: String = "blocked"
	if active and live_preview and not source_accepted:
		status = "preview_available_needs_task_962_acceptance"
	elif active:
		status = "ready_for_second_decision_loop"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_findings.get("schema", "")),
		"source_status": String(source_findings.get("status", "")),
		"source_accepted": source_accepted,
		"source_live_preview": live_preview and not source_accepted,
		"first_decision_schema": String(first_decision.get("schema", "")),
		"first_decision_gate": String(first_decision.get("gate", "")),
		"first_decision_line": String(first_decision.get("primary_cue_line", "")),
		"firefight_decision_active": bool(firefight_decision.get("active", false)),
		"firefight_decision_line": String(firefight_decision.get("decision_line", "")),
		"active": active,
		"status": status,
		"manual_acceptance_required": true,
		"accepted_for_next_loop": source_accepted and active,
		"primary_line": primary_line,
		"why_line": why_line,
		"visible_loop_line": visible_loop_line,
		"second_decision_choices": second_choices,
		"second_decision_choice_count": second_choices.size(),
		"recommended_choice_id": "hold_angle",
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else "",
		"recommended_next_task": NEXT_TASK if active else "TASK_963 - Release First Decision Next Playable Loop",
		"recommended_direction": "playtest_second_decision_loop" if active else "complete_first_decision_next_loop_prerequisites",
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


static func _build_blockers(source_findings: Dictionary, first_decision: Dictionary, live_preview: bool, source_accepted: bool) -> Array:
	var blockers: Array = []
	if not live_preview:
		if String(source_findings.get("schema", "")) != SOURCE_SCHEMA:
			blockers.append(_issue("source_schema_mismatch", "TASK_962-Source-Schema fehlt oder passt nicht."))
		if String(source_findings.get("task_id", "")) != SOURCE_TASK_ID:
			blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_962."))
		if not source_accepted:
			blockers.append(_issue("source_findings_not_accepted", "TASK_962-Findings sind nicht fuer den naechsten spielbaren Loop akzeptiert."))
		if not _snapshot_is_read_only(source_findings):
			blockers.append(_issue("source_not_read_only", "TASK_962-Source verletzt die read-only-Grenze."))
	if String(first_decision.get("schema", "")) != FIRST_DECISION_SCHEMA or String(first_decision.get("task_id", "")) != "TASK_956":
		blockers.append(_issue("first_decision_source_mismatch", "TASK_956-First-Decision-Quelle fehlt oder passt nicht."))
	if String(first_decision.get("gate", "")) != "pass":
		blockers.append(_issue("first_decision_not_passed", "TASK_956-First-Decision-Quelle ist nicht pass."))
	if not _snapshot_is_read_only(first_decision):
		blockers.append(_issue("first_decision_not_read_only", "TASK_956-First-Decision-Quelle verletzt die read-only-Grenze."))
	return blockers


static func _source_findings_are_accepted(source_findings: Dictionary) -> bool:
	return String(source_findings.get("schema", "")) == SOURCE_SCHEMA \
		and String(source_findings.get("task_id", "")) == SOURCE_TASK_ID \
		and String(source_findings.get("status", "")) == "accepted_for_release_first_decision_next_loop" \
		and bool(source_findings.get("accepted", false)) \
		and bool(source_findings.get("manual_review_done", false))


static func _build_second_decision_choices(firefight_decision: Dictionary) -> Array:
	var pressure_reason: String = _pressure_reason(firefight_decision)
	return [
		{
			"choice_id": "hold_angle",
			"label": "HOLD Winkel halten",
			"player_text": "Feuerkontakt lesen, Deckung halten, DEFEND bestaetigen.",
			"command_hint": "Defend",
			"risk_label": "stabil",
			"why": pressure_reason,
			"priority": 1,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		},
		{
			"choice_id": "advance_cover",
			"label": "ADV gedeckt vor",
			"player_text": "Kurzen Move zur naechsten Deckung planen, Preview pruefen, dann GO.",
			"command_hint": "Move",
			"risk_label": "riskant",
			"why": "nutzt Deckung, oeffnet neuen Winkel",
			"priority": 2,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		},
		{
			"choice_id": "fallback_regroup",
			"label": "BACK neu sammeln",
			"player_text": "Aus Feuerlinie loesen und Fireteam wieder ordnen.",
			"command_hint": "Return/Move",
			"risk_label": "vorsichtig",
			"why": "senkt Druck, kostet Tempo",
			"priority": 3,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		},
	]


static func _build_primary_line(firefight_decision: Dictionary, active: bool) -> String:
	if not active:
		return ""
	var next_token: String = String(firefight_decision.get("next_token", "")).strip_edges()
	if next_token.is_empty():
		next_token = "KONTAKT LESEN"
	return "NEXT %s -> HOLD / ADV / BACK" % next_token


static func _build_why_line(firefight_decision: Dictionary, active: bool) -> String:
	if not active:
		return ""
	var why_token: String = String(firefight_decision.get("why_token", "")).strip_edges()
	if why_token.is_empty():
		why_token = "KONTAKT"
	return "WHY %s | zweite Entscheidung statt Autopilot" % why_token


static func _build_visible_loop_line(primary_line: String, second_choices: Array) -> String:
	var tokens: PackedStringArray = PackedStringArray()
	for choice_variant in second_choices:
		var label: String = String(Dictionary(choice_variant).get("label", "")).strip_edges()
		if not label.is_empty():
			tokens.append(label.split(" ")[0])
	return "%s | %s" % [primary_line, " / ".join(tokens)]


static func _pressure_reason(firefight_decision: Dictionary) -> String:
	var why_token: String = String(firefight_decision.get("why_token", "")).strip_edges()
	if not why_token.is_empty():
		return why_token
	var decision_line: String = String(firefight_decision.get("decision_line", "")).strip_edges()
	if decision_line.contains("FEUER"):
		return "FEUER"
	return "Kontakt unklar"


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
