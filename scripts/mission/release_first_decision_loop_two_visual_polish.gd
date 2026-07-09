class_name ReleaseFirstDecisionLoopTwoVisualPolish
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_visual_polish.v1"
const TASK_ID: String = "TASK_971"
const SOURCE_TASK_ID: String = "TASK_970"
const SOURCE_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_visual_findings.v1"
const RUNTIME_TASK_ID: String = "TASK_968"
const RUNTIME_SCHEMA: String = "sternenbuergerchen.release_first_decision_loop_two_runtime_button.v1"
const NEXT_TASK: String = "TASK_972 - Release First Decision Loop Two Playability Smoke"


static func build_snapshot(source_findings: Dictionary, runtime_button: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_findings, runtime_button)
	var active: bool = blockers.is_empty()
	var selected_choice_id: String = String(runtime_button.get("selected_choice_id", "hold_angle")).strip_edges()
	var selected_command_type: String = String(runtime_button.get("selected_command_type", "defend")).strip_edges().to_lower()
	var choice_label: String = _choice_label(selected_choice_id)
	var command_label: String = _command_label(selected_command_type)
	var button_enabled: bool = active and bool(runtime_button.get("button_enabled", true))
	var hud_line: String = "2ND %s -> %s vorbereiten | danach GO separat" % [choice_label, command_label]
	var post_confirm_line: String = "Nach 2ND: %s ist vorbereitet, danach GO druecken." % command_label
	var tooltip: String = "2ND: zweiten Griff bestaetigen. Bereitet %s vor; GO separat druecken." % command_label
	var status: String = "visual_polish_ready" if active else "blocked"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_findings.get("schema", "")),
		"source_status": String(source_findings.get("status", "")),
		"source_issue_count": int(source_findings.get("issue_count", 0)),
		"runtime_task_id": RUNTIME_TASK_ID,
		"runtime_schema": String(runtime_button.get("schema", "")),
		"runtime_status": String(runtime_button.get("status", "")),
		"runtime_gate": String(runtime_button.get("gate", "")),
		"selected_choice_id": selected_choice_id,
		"selected_command_type": selected_command_type,
		"active": active,
		"button_enabled": button_enabled,
		"button_text": "2ND",
		"button_badge": "2ND",
		"button_role": "second_decision_confirm",
		"button_min_width": 54.0,
		"button_min_height": 44.0,
		"button_tooltip": tooltip,
		"hud_line": hud_line,
		"go_separation_line": "GO bleibt separat: 2ND bestaetigt nur den zweiten Griff.",
		"post_confirm_line": post_confirm_line,
		"visual_priority": "command_matrix_accent",
		"status": status,
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else "",
		"recommended_next_task": NEXT_TASK if active else "TASK_971 - Release First Decision Loop Two Visual Polish",
		"recommended_direction": "run_loop_two_playability_smoke" if active else "fix_loop_two_visual_polish_source",
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


static func _build_blockers(source_findings: Dictionary, runtime_button: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_findings.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_970-Source-Schema fehlt oder passt nicht."))
	if String(source_findings.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_970."))
	if String(source_findings.get("status", "")) not in ["ready_for_loop_two_visual_polish", "accepted_for_loop_two_playability_smoke"]:
		blockers.append(_issue("source_not_polishable", "TASK_970-Source ist nicht fuer TASK_971 polishbar."))
	if not _snapshot_is_read_only(source_findings):
		blockers.append(_issue("source_not_read_only", "TASK_970-Source verletzt die read-only-Grenze."))
	if not runtime_button.is_empty():
		if String(runtime_button.get("schema", "")) != RUNTIME_SCHEMA:
			blockers.append(_issue("runtime_schema_mismatch", "TASK_968-Runtime-Button-Schema fehlt oder passt nicht."))
		if String(runtime_button.get("task_id", "")) != RUNTIME_TASK_ID:
			blockers.append(_issue("runtime_task_mismatch", "Runtime-Button nennt nicht TASK_968."))
		if not _snapshot_is_read_only(runtime_button):
			blockers.append(_issue("runtime_not_read_only", "TASK_968-Runtime-Button verletzt die read-only-Grenze."))
	return blockers


static func _choice_label(choice_id: String) -> String:
	match choice_id:
		"hold_angle":
			return "HOLD"
		"advance_cover":
			return "ADV"
		"fallback_regroup":
			return "BACK"
		_:
			return choice_id.strip_edges().to_upper()


static func _command_label(command_type: String) -> String:
	match command_type:
		"defend":
			return "Defend"
		"move":
			return "Move"
		"return":
			return "Return"
		_:
			return command_type.strip_edges().capitalize() if not command_type.strip_edges().is_empty() else "Befehl"


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
