class_name MissionInteractionDoorMultiplayerAuthority
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.mission_interaction_door_multiplayer_authority.v1"
const UI_FEEDBACK_SCHEMA: String = "sternenbuergerchen.mission_interaction_door_authority_ui_feedback.v1"
const COMMAND_SOURCE_CONTEXT: String = "mission_interaction_door_breach_command"


static func build_network_command_from_hook(hook_snapshot: Dictionary, unit_id: String, team_id: String, target_position: Variant = null) -> Dictionary:
	if not bool(hook_snapshot.get("accepted", false)):
		return {}
	var use_intent: Dictionary = Dictionary(hook_snapshot.get("use_intent", {}))
	var resolved_target: Variant = target_position
	if resolved_target == null:
		resolved_target = use_intent.get("target_position", null)
	if resolved_target == null:
		return {}
	var command_type: String = String(hook_snapshot.get("command_type", use_intent.get("command_type", "take"))).strip_edges().to_lower()
	if command_type.is_empty():
		command_type = "take"
	return {
		"contract_category": "commander_command",
		"command_type": command_type,
		"unit_id": unit_id.strip_edges(),
		"team_id": team_id.strip_edges(),
		"fireteam_id": String(hook_snapshot.get("fireteam_id", use_intent.get("fireteam_id", ""))).strip_edges().to_lower(),
		"target_position": resolved_target,
		"priority": 5,
		"phase": int(hook_snapshot.get("phase", use_intent.get("phase", -1))),
		"source_context": COMMAND_SOURCE_CONTEXT,
		"interaction_id": String(hook_snapshot.get("interaction_id", use_intent.get("interaction_id", ""))).strip_edges(),
		"interaction_type": String(hook_snapshot.get("interaction_type", use_intent.get("interaction_type", "door"))).strip_edges().to_lower(),
		"required_order": String(hook_snapshot.get("required_order", use_intent.get("required_order", "breach"))).strip_edges().to_lower(),
		"duration_seconds": maxf(float(hook_snapshot.get("duration_seconds", use_intent.get("duration_seconds", 0.0))), 0.0),
		"door_runtime_hook": true,
		"door_runtime_state_target": String(hook_snapshot.get("door_runtime_state_target", "door_open")).strip_edges(),
		"door_runtime_producer": String(hook_snapshot.get("door_runtime_producer", "MissionInteractionDoorRuntimeCollisionLOS")).strip_edges(),
		"requires_go": bool(hook_snapshot.get("requires_go", true)),
	}


static func build_snapshot(hook_snapshot: Dictionary, network_contract_snapshot: Dictionary = {}, door_runtime_snapshot: Dictionary = {}, authority_results: Dictionary = {}) -> Dictionary:
	var host_submission: Dictionary = Dictionary(authority_results.get("host_submission", {}))
	var foreign_submission: Dictionary = Dictionary(authority_results.get("foreign_submission", {}))
	var state_mutation_submission: Dictionary = Dictionary(authority_results.get("state_mutation_submission", {}))
	var projected_command: Dictionary = Dictionary(authority_results.get("projected_command", {}))
	var checks: Array = [
		_check("hook_accepted", bool(hook_snapshot.get("accepted", false)), "Door hook produced a GO-required command intent."),
		_check("projected_command_present", not projected_command.is_empty(), "Door hook can be projected into a network command."),
		_check("host_command_accepted", bool(host_submission.get("accepted", false)), "Authority accepts the own-team Door command."),
		_check("foreign_team_rejected", not bool(foreign_submission.get("accepted", true)) and _reason_is_one_of(String(foreign_submission.get("reason", "")), PackedStringArray(["peer_team_mismatch", "unit_team_mismatch"])), "Wrong-team peer cannot submit the Door command."),
		_check("state_mutation_rejected", not bool(state_mutation_submission.get("accepted", true)) and String(state_mutation_submission.get("reason", "")).begins_with("state_mutation_key:"), "Client payload cannot set Door runtime state directly."),
		_check("door_runtime_producer_open", _door_runtime_snapshot_has_open_override(door_runtime_snapshot), "Door opens only through Door Runtime Collision/LOS producer."),
		_check("snapshot_read_only", true, "Authority snapshot is read-only feedback."),
	]
	var failed_checks: PackedStringArray = PackedStringArray()
	for check_variant in checks:
		var check: Dictionary = Dictionary(check_variant)
		if not bool(check.get("passed", false)):
			failed_checks.append(String(check.get("id", "")))
	return {
		"schema": SNAPSHOT_SCHEMA,
		"runtime_authority": "SimulationRoot network command contract + MissionInteractionDoorRuntimeCollisionLOS",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"hook_accepted": bool(hook_snapshot.get("accepted", false)),
		"requires_go": bool(hook_snapshot.get("requires_go", false)),
		"interaction_id": String(hook_snapshot.get("interaction_id", "")).strip_edges(),
		"interaction_type": String(hook_snapshot.get("interaction_type", "")).strip_edges().to_lower(),
		"fireteam_id": String(hook_snapshot.get("fireteam_id", "")).strip_edges().to_lower(),
		"command_type": String(hook_snapshot.get("command_type", "")).strip_edges().to_lower(),
		"door_runtime_state_target": String(hook_snapshot.get("door_runtime_state_target", "")).strip_edges(),
		"door_runtime_producer": String(hook_snapshot.get("door_runtime_producer", "")).strip_edges(),
		"projected_command": projected_command.duplicate(true),
		"projected_command_category": String(projected_command.get("contract_category", "")).strip_edges(),
		"projected_command_source_context": String(projected_command.get("source_context", "")).strip_edges(),
		"host_command_accepted": bool(host_submission.get("accepted", false)),
		"host_command_reason": String(host_submission.get("reason", "")).strip_edges(),
		"foreign_team_rejected": not bool(foreign_submission.get("accepted", true)),
		"foreign_team_reject_reason": String(foreign_submission.get("reason", "")).strip_edges(),
		"state_mutation_rejected": not bool(state_mutation_submission.get("accepted", true)),
		"state_mutation_reject_reason": String(state_mutation_submission.get("reason", "")).strip_edges(),
		"network_accepted_count": int(network_contract_snapshot.get("accepted_count", 0)),
		"network_rejected_count": int(network_contract_snapshot.get("rejected_count", 0)),
		"door_runtime_override_count": int(door_runtime_snapshot.get("override_count", 0)),
		"door_runtime_open_override": _door_runtime_snapshot_has_open_override(door_runtime_snapshot),
		"checks": checks,
		"failed_checks": failed_checks,
		"gate": "pass" if failed_checks.is_empty() else "review",
		"summary": _build_summary(host_submission, foreign_submission, state_mutation_submission, door_runtime_snapshot),
	}


static func build_ui_feedback(authority_snapshot: Dictionary, button_context: Dictionary = {}) -> Dictionary:
	var gate: String = String(authority_snapshot.get("gate", "")).strip_edges().to_lower()
	var enabled: bool = bool(button_context.get("button_enabled", false))
	var has_usable_door: bool = bool(button_context.get("has_usable_door", false))
	var display_token: String = String(button_context.get("display_token", authority_snapshot.get("interaction_id", "DOOR"))).strip_edges().to_upper()
	if display_token.is_empty():
		display_token = "DOOR"
	var shortcut: String = String(button_context.get("shortcut", "B")).strip_edges().to_upper()
	if shortcut.is_empty():
		shortcut = "B"
	var status: String = _resolve_ui_status(authority_snapshot, enabled, has_usable_door)
	var reject_reason_label: String = _build_reject_reason_label(authority_snapshot)
	var summary_line: String = _build_ui_summary_line(status, display_token, shortcut, authority_snapshot)
	var next_action: String = _build_ui_next_action(status, shortcut, has_usable_door)
	var player_hint: String = _build_ui_player_hint(status, reject_reason_label)
	var compact_line: String = _build_ui_compact_line(status, display_token, shortcut, reject_reason_label)
	var severity: String = _build_ui_severity(status)
	var tooltip_lines: PackedStringArray = PackedStringArray([
		summary_line,
		next_action,
	])
	var detail_line: String = _build_ui_detail_line(status, authority_snapshot, has_usable_door, reject_reason_label)
	if not detail_line.is_empty():
		tooltip_lines.append(detail_line)
	tooltip_lines.append("Quelle: SimulationRoot / MultiplayerCommandContract.")
	return {
		"schema": UI_FEEDBACK_SCHEMA,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"status": status,
		"display_token": display_token,
		"shortcut": shortcut,
		"summary_line": summary_line,
		"compact_line": compact_line,
		"detail_line": detail_line,
		"player_hint": player_hint,
		"next_action": next_action,
		"severity": severity,
		"reject_reason_label": reject_reason_label,
		"tooltip_text": "\n".join(Array(tooltip_lines)),
		"button_enabled": enabled,
		"has_usable_door": has_usable_door,
		"requires_go": bool(authority_snapshot.get("requires_go", false)) or enabled,
		"authority_gate": gate,
		"authority_summary": String(authority_snapshot.get("summary", "")).strip_edges(),
		"host_command_accepted": bool(authority_snapshot.get("host_command_accepted", false)),
		"foreign_team_rejected": bool(authority_snapshot.get("foreign_team_rejected", false)),
		"state_mutation_rejected": bool(authority_snapshot.get("state_mutation_rejected", false)),
		"door_runtime_open_override": bool(authority_snapshot.get("door_runtime_open_override", false)),
	}


static func _door_runtime_snapshot_has_open_override(snapshot: Dictionary) -> bool:
	for entry_variant in Array(snapshot.get("entries", [])):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("runtime_visual_state", "")).strip_edges().to_lower() == "open":
			return true
	for override_variant in Array(snapshot.get("overrides", [])):
		if typeof(override_variant) != TYPE_DICTIONARY:
			continue
		var override: Dictionary = Dictionary(override_variant)
		if bool(override.get("walkable_override", false)) and not bool(override.get("blocks_los_override", true)):
			return true
	return false


static func _reason_is_one_of(reason: String, allowed_reasons: PackedStringArray) -> bool:
	return allowed_reasons.has(reason.strip_edges())


static func _check(id: String, passed: bool, detail: String) -> Dictionary:
	return {
		"id": id,
		"passed": passed,
		"detail": detail,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _build_summary(host_submission: Dictionary, foreign_submission: Dictionary, state_mutation_submission: Dictionary, door_runtime_snapshot: Dictionary) -> String:
	if bool(host_submission.get("accepted", false)) and not bool(foreign_submission.get("accepted", true)) and not bool(state_mutation_submission.get("accepted", true)) and _door_runtime_snapshot_has_open_override(door_runtime_snapshot):
		return "Door authority OK: host command accepted, wrong-team/state payloads rejected, producer opens Door."
	return "Door authority pending/review: check host accept, rejects and runtime producer."


static func _resolve_ui_status(authority_snapshot: Dictionary, enabled: bool, has_usable_door: bool) -> String:
	if bool(authority_snapshot.get("door_runtime_open_override", false)):
		return "open"
	if bool(authority_snapshot.get("host_command_accepted", false)):
		return "accepted"
	if bool(authority_snapshot.get("foreign_team_rejected", false)) or bool(authority_snapshot.get("state_mutation_rejected", false)):
		return "blocked"
	if enabled and has_usable_door:
		return "ready"
	return "pending"


static func _build_ui_summary_line(status: String, display_token: String, shortcut: String, authority_snapshot: Dictionary) -> String:
	var subject: String = _build_ui_subject(display_token)
	match status:
		"open":
			return "%s offen | Runtime frei" % subject
		"accepted":
			return "%s akzeptiert | GO laeuft ueber Host" % subject
		"blocked":
			return "%s blockiert | Authority pruefen" % subject
		"ready":
			return "%s bereit | %s dann GO" % [subject, shortcut]
		_:
			if not bool(authority_snapshot.get("hook_accepted", false)):
				return "%s wartet | keine nutzbare Door" % subject
			return "%s wartet | Authority offen" % subject


static func _build_ui_detail_line(status: String, authority_snapshot: Dictionary, has_usable_door: bool, reject_reason_label: String = "") -> String:
	match status:
		"open":
			return "Walkability/LOS kommen vom Door Runtime Producer."
		"accepted":
			return "Own-Team Command akzeptiert; Runtime-State wird nicht im UI gesetzt."
		"blocked":
			if not reject_reason_label.is_empty():
				return "Blockiert: %s." % reject_reason_label
			return "Blockiert durch MultiplayerCommandContract."
		"ready":
			return "Bereitet nur den Door-Breach-Command vor; GO bestaetigt."
		_:
			return "Door in Reichweite fehlt." if not has_usable_door else "Authority-Snapshot wartet auf Command-Ergebnis."


static func _build_reject_reason_label(authority_snapshot: Dictionary) -> String:
	var foreign_reason: String = String(authority_snapshot.get("foreign_team_reject_reason", "")).strip_edges()
	var mutation_reason: String = String(authority_snapshot.get("state_mutation_reject_reason", "")).strip_edges()
	if not foreign_reason.is_empty():
		match foreign_reason:
			"peer_team_mismatch":
				return "falsches Team / Peer darf diese Door nicht bedienen"
			"unit_team_mismatch":
				return "ausgewaehlte Einheit gehoert nicht zum erlaubten Team"
			_:
				return "Authority-Reject: %s" % foreign_reason
	if not mutation_reason.is_empty():
		if mutation_reason.begins_with("state_mutation_key:"):
			var key: String = mutation_reason.substr("state_mutation_key:".length())
			return "Client darf Runtime-State `%s` nicht direkt setzen" % key
		return "State-Mutation-Reject: %s" % mutation_reason
	return ""


static func _build_ui_next_action(status: String, shortcut: String, has_usable_door: bool) -> String:
	match status:
		"open":
			return "Naechster Schritt: Fireteam kann durch die Door."
		"accepted":
			return "Naechster Schritt: Runtime-Progress abwarten."
		"blocked":
			return "Naechster Schritt: Team/Peer oder Payload korrigieren."
		"ready":
			return "Naechster Schritt: %s druecken, dann GO bestaetigen." % shortcut
		_:
			return "Naechster Schritt: Door in Reichweite bringen." if not has_usable_door else "Naechster Schritt: Authority-Ergebnis abwarten."


static func _build_ui_player_hint(status: String, reject_reason_label: String) -> String:
	match status:
		"open":
			return "Door ist offen; Bewegung und Sichtlinie nutzen Runtime-Overrides."
		"accepted":
			return "Host hat den Door-Befehl akzeptiert; die Door oeffnet erst ueber Runtime-Progress."
		"blocked":
			return reject_reason_label if not reject_reason_label.is_empty() else "Door-Befehl wurde durch Authority blockiert."
		"ready":
			return "Door-Breach ist vorbereitet, aber noch nicht ausgefuehrt."
		_:
			return "Keine nutzbare Door fuer die aktuelle Auswahl."


static func _build_ui_compact_line(status: String, display_token: String, shortcut: String, reject_reason_label: String) -> String:
	var subject: String = _build_ui_subject(display_token)
	match status:
		"open":
			return "%s OPEN" % subject
		"accepted":
			return "%s HOST OK" % subject
		"blocked":
			return "%s BLOCKED %s" % [subject, reject_reason_label] if not reject_reason_label.is_empty() else "%s BLOCKED" % subject
		"ready":
			return "%s %s->GO" % [subject, shortcut]
		_:
			return "%s WAIT" % subject


static func _build_ui_subject(display_token: String) -> String:
	var token: String = display_token.strip_edges().to_upper()
	if token.is_empty() or token == "DOOR":
		return "DOOR"
	return "DOOR %s" % token


static func _build_ui_severity(status: String) -> String:
	match status:
		"open":
			return "success"
		"accepted":
			return "info"
		"blocked":
			return "warning"
		"ready":
			return "action"
		_:
			return "muted"
