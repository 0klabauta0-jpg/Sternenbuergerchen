class_name ReleaseFirstDecisionLoopTwoPlayerLoopVisualPolish
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_visual_polish.v1"
const TASK_ID: String = "TASK_983"
const SOURCE_TASK_ID: String = "TASK_982"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_visual_findings.v1"
const RUNTIME_TASK_ID: String = "TASK_979"
const RUNTIME_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_player_loop_runtime_choice_buttons.v1"
const NEXT_TASK: String = "TASK_984 - Release First Decision Loop Two Player Loop Acceptance Slice"


static func build_snapshot(source_findings: Dictionary, runtime_buttons: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_findings, runtime_buttons)
	var active: bool = blockers.is_empty()
	var runtime_specs: Array = Array(runtime_buttons.get("button_specs", []))
	var visual_specs: Array = _build_visual_specs(runtime_specs) if active else []
	var choice_group_line: String = _build_choice_group_line(visual_specs) if active else ""
	var choice_feedback_line: String = "Choice Confirm: Befehl vorbereitet | danach GO druecken" if active else ""
	var status: String = "player_loop_visual_polish_ready" if active else "blocked"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_findings.get("schema", "")),
		"source_status": String(source_findings.get("status", "")),
		"source_issue_count": int(source_findings.get("issue_count", 0)),
		"runtime_task_id": RUNTIME_TASK_ID,
		"runtime_schema": String(runtime_buttons.get("schema", "")),
		"runtime_status": String(runtime_buttons.get("status", "")),
		"runtime_gate": String(runtime_buttons.get("gate", "")),
		"active": active,
		"button_visual_specs": visual_specs,
		"button_visual_spec_count": visual_specs.size(),
		"choice_group_line": choice_group_line,
		"choice_feedback_line": choice_feedback_line,
		"go_separation_line": "GO bleibt separat: Choice bestaetigt nur die naechste Order.",
		"visual_priority": "choice_matrix_readability",
		"status": status,
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else "",
		"recommended_next_task": NEXT_TASK if active else "TASK_983 - Release First Decision Loop Two Player Loop Visual Polish",
		"recommended_direction": "build_player_loop_acceptance_slice" if active else "fix_player_loop_visual_polish_source",
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


static func _build_blockers(source_findings: Dictionary, runtime_buttons: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_findings.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_982-Source-Schema fehlt oder passt nicht."))
	if String(source_findings.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_982."))
	if String(source_findings.get("status", "")) not in ["ready_for_player_loop_visual_polish", "accepted_for_player_loop_acceptance_slice"]:
		blockers.append(_issue("source_not_polishable", "TASK_982-Source ist nicht fuer TASK_983 polishbar."))
	if not _snapshot_is_read_only(source_findings):
		blockers.append(_issue("source_not_read_only", "TASK_982-Source verletzt die read-only-Grenze."))
	if String(runtime_buttons.get("schema", "")) != RUNTIME_SCHEMA:
		blockers.append(_issue("runtime_schema_mismatch", "TASK_979-Runtime-Buttons-Schema fehlt oder passt nicht."))
	if String(runtime_buttons.get("task_id", "")) != RUNTIME_TASK_ID:
		blockers.append(_issue("runtime_task_mismatch", "Runtime-Buttons nennen nicht TASK_979."))
	if int(runtime_buttons.get("button_count", 0)) < 4 or Array(runtime_buttons.get("button_specs", [])).size() < 4:
		blockers.append(_issue("runtime_buttons_missing", "TASK_979 liefert nicht alle vier Runtime-Choice-Buttons."))
	if not _snapshot_is_read_only(runtime_buttons):
		blockers.append(_issue("runtime_not_read_only", "TASK_979-Runtime-Buttons verletzen die read-only-Grenze."))
	return blockers


static func _build_visual_specs(runtime_specs: Array) -> Array:
	var specs: Array = []
	for spec_variant in runtime_specs:
		var runtime_spec := Dictionary(spec_variant)
		var button_text: String = String(runtime_spec.get("button_text", "")).strip_edges()
		var command_type: String = String(runtime_spec.get("command_type", "")).strip_edges().to_lower()
		specs.append({
			"choice_id": String(runtime_spec.get("choice_id", "")),
			"button_text": button_text,
			"button_label": String(runtime_spec.get("button_label", button_text)),
			"slot_name": String(runtime_spec.get("slot_name", "")),
			"slot_path": String(runtime_spec.get("slot_path", "")),
			"command_type": command_type,
			"button_min_width": 78.0,
			"button_min_height": 46.0,
			"button_tooltip": "%s: %s vorbereiten. Confirm setzt nur die Order; GO separat druecken." % [button_text, _command_label(command_type)],
			"visual_style_id": _style_id_for_choice(String(runtime_spec.get("choice_id", ""))),
			"visual_accent": _accent_for_choice(String(runtime_spec.get("choice_id", ""))),
			"feedback_token": "%s READY" % button_text,
			"separate_go_required": true,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"creates_command": false,
			"creates_movement": false,
		})
	return specs


static func _build_choice_group_line(visual_specs: Array) -> String:
	var tokens: PackedStringArray = PackedStringArray()
	for spec_variant in visual_specs:
		var token: String = String(Dictionary(spec_variant).get("button_text", "")).strip_edges()
		if not token.is_empty():
			tokens.append(token)
	return "CHOICE BUTTONS %s | Confirm -> GO separat" % " / ".join(tokens)


static func _command_label(command_type: String) -> String:
	match command_type:
		"defend":
			return "Defend"
		"move":
			return "Move"
		"flank":
			return "Flank"
		_:
			return command_type.capitalize() if not command_type.is_empty() else "Befehl"


static func _style_id_for_choice(choice_id: String) -> String:
	match choice_id:
		"secure_area":
			return "choice_secure"
		"push_objective":
			return "choice_push"
		"flank_pressure":
			return "choice_flank"
		"reset_spacing":
			return "choice_reset"
		_:
			return "choice_default"


static func _accent_for_choice(choice_id: String) -> String:
	match choice_id:
		"secure_area":
			return "mint"
		"push_objective":
			return "gold"
		"flank_pressure":
			return "sky"
		"reset_spacing":
			return "steel"
		_:
			return "neutral"


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
