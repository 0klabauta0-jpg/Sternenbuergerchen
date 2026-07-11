class_name MissionInteractionMultiplayerCommand
extends RefCounted

const SOURCE_CONTEXT := "mission_interaction_use_intent_command"


static func build_network_command(intent: Dictionary, unit_id: String, team_id: String, target_position_override: Variant = null) -> Dictionary:
	if not bool(intent.get("accepted", false)):
		return {}
	var interaction_id := String(intent.get("interaction_id", "")).strip_edges()
	var fireteam_id := String(intent.get("fireteam_id", "")).strip_edges().to_lower()
	var command_type := String(intent.get("command_type", "")).strip_edges().to_lower()
	var target_position: Variant = target_position_override if target_position_override != null else intent.get("target_position", null)
	if interaction_id.is_empty() or unit_id.strip_edges().is_empty() or team_id.strip_edges().is_empty() or fireteam_id.is_empty() or command_type.is_empty() or typeof(target_position) != TYPE_VECTOR2:
		return {}
	return {
		"contract_category": "commander_command",
		"command_type": command_type,
		"unit_id": unit_id.strip_edges(),
		"team_id": team_id.strip_edges().to_lower(),
		"fireteam_id": fireteam_id,
		"target_position": Vector2(target_position),
		"priority": 5,
		"source_context": SOURCE_CONTEXT,
		"interaction_id": interaction_id,
		"interaction_type": String(intent.get("interaction_type", "")).strip_edges().to_lower(),
		"required_order": String(intent.get("required_order", "")).strip_edges().to_lower(),
		"duration_seconds": maxf(float(intent.get("duration_seconds", 0.0)), 0.0),
		"interaction_radius_world": maxf(float(intent.get("interaction_radius_world", 72.0)), 1.0),
		"step_id": String(intent.get("step_id", "")).strip_edges(),
		"gate_id": String(intent.get("gate_id", intent.get("step_id", ""))).strip_edges(),
		"required_state": String(intent.get("required_state", "")).strip_edges(),
		"requires_go": true,
	}
