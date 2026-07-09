class_name ReleaseFirstDecisionLoopTwoPolish
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_polish.v1"
const TASK_ID: String = "TASK_965"
const SOURCE_TASK_ID: String = "TASK_964"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_playtest.v1"
const NEXT_LOOP_TASK_ID: String = "TASK_963"
const NEXT_LOOP_SCHEMA: String = "sternenbuergerchen.release_first_decision_next_playable_loop.v1"
const NEXT_TASK: String = "TASK_966 - Release First Decision Loop Two Execution Hook"


static func build_snapshot(loop_two_playtest: Dictionary, next_loop: Dictionary, context: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_source_blockers(loop_two_playtest, next_loop)
	var choices: Array = Array(next_loop.get("second_decision_choices", []))
	var intents: Array = _build_second_decision_intents(choices)
	blockers.append_array(_build_intent_blockers(intents))
	var active: bool = blockers.is_empty()
	var compact_line: String = _build_compact_line(intents) if active else ""
	var gate: String = "loop_two_polish_passed" if active else "loop_two_polish_review"
	if _source_identity_blocked(loop_two_playtest):
		gate = "blocked"
	var status: String = "ready_for_second_decision_execution_hook" if active else "needs_loop_two_polish"
	if gate == "blocked":
		status = "blocked"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(loop_two_playtest.get("schema", "")),
		"source_gate": String(loop_two_playtest.get("gate", "")),
		"source_status": String(loop_two_playtest.get("status", "")),
		"next_loop_task_id": NEXT_LOOP_TASK_ID,
		"next_loop_schema": String(next_loop.get("schema", "")),
		"next_loop_status": String(next_loop.get("status", "")),
		"active": active,
		"status": status,
		"gate": gate,
		"recommended_choice_id": _recommended_choice_id(next_loop),
		"second_decision_intents": intents,
		"second_decision_intent_count": intents.size(),
		"compact_line": compact_line,
		"selected_fireteam_line": compact_line,
		"mission_control_line": compact_line,
		"line_within_limit": compact_line.length() > 0 and compact_line.length() <= int(context.get("line_char_limit", 96)),
		"execution_boundary": "requires_go",
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else "",
		"recommended_next_task": NEXT_TASK if active else "TASK_965 - Release First Decision Loop Two Polish",
		"recommended_direction": "wire_second_decision_execution_hook" if active else "polish_second_decision_intents",
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


static func _build_source_blockers(loop_two_playtest: Dictionary, next_loop: Dictionary) -> Array:
	var blockers: Array = []
	if String(loop_two_playtest.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_964-Source-Schema fehlt oder passt nicht."))
	if String(loop_two_playtest.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_964."))
	if String(loop_two_playtest.get("gate", "")) != "loop_two_playtest_passed":
		blockers.append(_issue("source_gate_not_passed", "TASK_964-Playtest ist nicht bestanden."))
	if not bool(loop_two_playtest.get("active", false)):
		blockers.append(_issue("source_not_active", "TASK_964-Playtest ist nicht aktiv."))
	if not _snapshot_is_read_only(loop_two_playtest):
		blockers.append(_issue("source_not_read_only", "TASK_964-Source verletzt die read-only-Grenze."))
	if String(next_loop.get("schema", "")) != NEXT_LOOP_SCHEMA:
		blockers.append(_issue("next_loop_schema_mismatch", "TASK_963-Next-Loop-Schema fehlt oder passt nicht."))
	if String(next_loop.get("task_id", "")) != NEXT_LOOP_TASK_ID:
		blockers.append(_issue("next_loop_task_mismatch", "Next-Loop-Quelle nennt nicht TASK_963."))
	if not bool(next_loop.get("active", false)):
		blockers.append(_issue("next_loop_not_active", "TASK_963-Next-Loop ist nicht aktiv."))
	if not _snapshot_is_read_only(next_loop):
		blockers.append(_issue("next_loop_not_read_only", "TASK_963-Next-Loop verletzt die read-only-Grenze."))
	return blockers


static func _build_second_decision_intents(choices: Array) -> Array:
	var by_id: Dictionary = {}
	for choice_variant in choices:
		if typeof(choice_variant) == TYPE_DICTIONARY:
			var choice: Dictionary = Dictionary(choice_variant)
			by_id[String(choice.get("choice_id", ""))] = choice
	var intents: Array = []
	for spec in _intent_specs():
		var choice_id: String = String(spec.get("choice_id", ""))
		if not by_id.has(choice_id):
			continue
		var choice: Dictionary = Dictionary(by_id.get(choice_id, {}))
		intents.append({
			"choice_id": choice_id,
			"label": String(spec.get("label", "")),
			"command_type": String(spec.get("command_type", "")),
			"command_label": String(spec.get("command_label", "")),
			"player_text": String(spec.get("player_text", "")),
			"source_choice_label": String(choice.get("label", "")),
			"source_command_hint": String(choice.get("command_hint", "")),
			"execution_boundary": "requires_go",
			"requires_go": true,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"creates_command": false,
			"creates_movement": false,
			"creates_fire_event": false,
			"creates_damage_event": false,
			"sets_multiplayer_truth": false,
		})
	return intents


static func _build_intent_blockers(intents: Array) -> Array:
	var blockers: Array = []
	var ids: Array = []
	for intent_variant in intents:
		ids.append(String(Dictionary(intent_variant).get("choice_id", "")))
	if not ids.has("hold_angle"):
		blockers.append(_issue("missing_hold_angle_choice", "HOLD-Wahl fehlt im zweiten Loop."))
	if not ids.has("advance_cover"):
		blockers.append(_issue("missing_advance_cover_choice", "ADV-Wahl fehlt im zweiten Loop."))
	if not ids.has("fallback_regroup"):
		blockers.append(_issue("missing_fallback_regroup_choice", "BACK-Wahl fehlt im zweiten Loop."))
	for intent_variant in intents:
		var intent: Dictionary = Dictionary(intent_variant)
		if String(intent.get("execution_boundary", "")) != "requires_go":
			blockers.append(_issue("intent_missing_go_boundary", "Ein zweiter Intent umgeht die GO-Grenze."))
		if not _snapshot_is_read_only(intent):
			blockers.append(_issue("intent_not_read_only", "Ein zweiter Intent verletzt die read-only-Grenze."))
	return blockers


static func _build_compact_line(intents: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for intent_variant in intents:
		var intent: Dictionary = Dictionary(intent_variant)
		var label: String = String(intent.get("label", "")).strip_edges()
		var command_label: String = String(intent.get("command_label", "")).strip_edges()
		if not label.is_empty() and not command_label.is_empty():
			parts.append("%s %s" % [label, command_label])
	return "2ND %s | GO bestaetigt" % " | ".join(parts)


static func _recommended_choice_id(next_loop: Dictionary) -> String:
	var recommended: String = String(next_loop.get("recommended_choice_id", "")).strip_edges()
	return recommended if not recommended.is_empty() else "hold_angle"


static func _intent_specs() -> Array:
	return [
		{
			"choice_id": "hold_angle",
			"label": "HOLD",
			"command_type": "defend",
			"command_label": "Defend",
			"player_text": "Winkel halten und Feuerkontakt lesen.",
		},
		{
			"choice_id": "advance_cover",
			"label": "ADV",
			"command_type": "move",
			"command_label": "Move",
			"player_text": "Kurzen gedeckten Move zur naechsten Deckung planen.",
		},
		{
			"choice_id": "fallback_regroup",
			"label": "BACK",
			"command_type": "return",
			"command_label": "Return",
			"player_text": "Aus Feuerlinie loesen und neu sammeln.",
		},
	]


static func _source_identity_blocked(loop_two_playtest: Dictionary) -> bool:
	return String(loop_two_playtest.get("schema", "")) != SOURCE_SCHEMA or String(loop_two_playtest.get("task_id", "")) != SOURCE_TASK_ID


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
