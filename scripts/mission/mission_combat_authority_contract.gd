class_name MissionCombatAuthorityContract
extends RefCounted

const PLAYABILITY_SNAPSHOT_KEYS: PackedStringArray = [
	"combat_state",
	"win_condition_type",
	"mission_resolved",
	"result",
	"winning_team_id",
	"enemy_fit_count",
	"friendly_fit_count",
	"duration_seconds",
	"remaining_time_limit_seconds",
	"last_event_text",
	"objective_position",
	"objective_capture_radius",
	"objective_owner_team_id",
	"objective_capturing_team_id",
	"objective_capture_progress",
	"objective_contested",
	"objective_captured",
]

const OBJECTIVE_STATE_KEYS: PackedStringArray = [
	"objective_position",
	"objective_capture_radius",
	"objective_owner_team_id",
	"objective_capturing_team_id",
	"objective_capture_progress",
	"objective_contested",
]

const CONTACT_STATE_KEYS: PackedStringArray = [
	"fireteam_id",
	"unit_id",
	"team_id",
	"detection_state",
	"last_known_position",
	"last_seen_tick",
	"shared_by_leadership",
]

const MISSION_RESULT_KEYS: PackedStringArray = [
	"winning_team_id",
	"friendly_team_id",
	"mission_outcome",
	"result",
	"win_condition_type",
	"objective_captured",
	"duration_seconds",
	"team_states",
	"fireteam_tactical_debrief",
]

const READ_ONLY_UI_EVENT_KEYS: PackedStringArray = [
	"event_type",
	"read_only",
	"event_text",
	"unit_id",
	"event_color",
	"duration_seconds",
	"unit_event_text",
]

const AUTHORITATIVE_EFFECT_TYPES: PackedStringArray = [
	"damage",
	"heal",
	"bleedout",
	"respawn",
	"dropship_embark_unit",
	"dropship_deploy_unit",
	"apply_loadout_modifiers",
]


static func get_contract_snapshot() -> Dictionary:
	return {
		"playability_snapshot_keys": Array(PLAYABILITY_SNAPSHOT_KEYS),
		"objective_state_keys": Array(OBJECTIVE_STATE_KEYS),
		"contact_state_keys": Array(CONTACT_STATE_KEYS),
		"mission_result_keys": Array(MISSION_RESULT_KEYS),
		"read_only_ui_event_keys": Array(READ_ONLY_UI_EVENT_KEYS),
		"authoritative_effect_types": Array(AUTHORITATIVE_EFFECT_TYPES),
	}


static func is_authoritative_effect_type(effect_type: String) -> bool:
	return AUTHORITATIVE_EFFECT_TYPES.has(effect_type.strip_edges())


static func build_objective_state(objective_status) -> Dictionary:
	if objective_status == null:
		return {}
	return {
		"objective_position": objective_status.position,
		"objective_capture_radius": float(objective_status.capture_radius),
		"objective_owner_team_id": String(objective_status.owning_team_id),
		"objective_capturing_team_id": String(objective_status.capturing_team_id),
		"objective_capture_progress": clampf(float(objective_status.capture_progress), 0.0, 1.0),
		"objective_contested": bool(objective_status.call("is_contested")) if objective_status.has_method("is_contested") else false,
	}


static func build_playability_snapshot(base_snapshot: Dictionary, objective_status, mission_result: Dictionary) -> Dictionary:
	var snapshot: Dictionary = base_snapshot.duplicate(true)
	var objective_state: Dictionary = build_objective_state(objective_status)
	for key in objective_state.keys():
		snapshot[key] = objective_state[key]
	if not mission_result.is_empty():
		snapshot["result"] = String(mission_result.get("result", ""))
		snapshot["win_condition_type"] = String(mission_result.get("win_condition_type", String(base_snapshot.get("win_condition_type", ""))))
		snapshot["objective_captured"] = bool(mission_result.get("objective_captured", false))
	return snapshot


static func build_mission_result(
	result: String,
	winning_team_id: String,
	friendly_team_id: String,
	win_condition_type: String,
	objective_captured: bool,
	duration_seconds: float,
	team_states: Array
) -> Dictionary:
	return {
		"winning_team_id": winning_team_id,
		"friendly_team_id": friendly_team_id,
		"mission_outcome": "won" if result == "victory" else "lost",
		"result": result,
		"win_condition_type": win_condition_type,
		"objective_captured": objective_captured,
		"duration_seconds": duration_seconds,
		"team_states": team_states.duplicate(true),
	}
