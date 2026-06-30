class_name MissionInteractionDoorMultiplayerAuthority
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.mission_interaction_door_multiplayer_authority.v1"
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
