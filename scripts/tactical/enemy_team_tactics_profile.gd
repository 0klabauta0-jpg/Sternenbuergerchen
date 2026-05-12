class_name EnemyTeamTacticsProfile
extends RefCounted

const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")

const PROFILE_GUARD_HOLD: String = "guard_hold"
const PROFILE_PATROL_PROBE: String = "patrol_probe"
const PROFILE_AGGRESSIVE_PUSH: String = "aggressive_push"
const PROFILE_DEFENSIVE_COVER: String = "defensive_cover"
const PROFILE_SNIPER_WATCH: String = "sniper_watch"

const DEFAULT_PROFILE_ID: String = PROFILE_GUARD_HOLD
const DEFAULT_SECURITY_MODE: String = "directional"
const DEFAULT_FACING: String = "auto"
const ADVANCE_STYLE_HOLD: String = "hold"
const ADVANCE_STYLE_PROBE: String = "probe"
const ADVANCE_STYLE_PUSH: String = "push"
const ADVANCE_STYLE_BOUNDING: String = "bounding"
const MOVEMENT_POSTURE_POLICY_TRAVEL_UNTIL_THREAT: String = "travel_until_threat"
const MOVEMENT_POSTURE_POLICY_ALWAYS_READY: String = "always_ready"
const MOVEMENT_POSTURE_POLICY_HOLD_READY: String = "hold_ready"
const MOVEMENT_POSTURE_POLICY_AGGRESSIVE_READY: String = "aggressive_ready"
const MOVEMENT_POSTURE_POLICY_OVERWATCH: String = "overwatch"
const HEAVY_WEAPON_NONE: String = "none"
const HEAVY_WEAPON_ANTI_ARMOR: String = "anti_armor"
const AIR_ASSET_RISK_NONE: String = "none"
const AIR_ASSET_RISK_WATCH: String = "watch_warning"
const AIR_ASSET_RISK_STRIKE: String = "strike_capable"
const AIR_ASSET_RISK_LOSS: String = "loss_capable"
const COMMUNICATION_NORMAL: String = "normal"

const PROFILE_IDS: PackedStringArray = [
	PROFILE_GUARD_HOLD,
	PROFILE_PATROL_PROBE,
	PROFILE_AGGRESSIVE_PUSH,
	PROFILE_DEFENSIVE_COVER,
	PROFILE_SNIPER_WATCH,
]
const SECURITY_MODES: PackedStringArray = [
	"directional",
	"360",
	"patrol",
	"cover_arc",
	"overwatch",
]
const FACING_OPTIONS: PackedStringArray = [
	"auto",
	"north",
	"north_east",
	"east",
	"south_east",
	"south",
	"south_west",
	"west",
	"north_west",
]
const ADVANCE_STYLES: PackedStringArray = [
	ADVANCE_STYLE_HOLD,
	ADVANCE_STYLE_PROBE,
	ADVANCE_STYLE_PUSH,
	ADVANCE_STYLE_BOUNDING,
]
const MOVEMENT_POSTURE_POLICIES: PackedStringArray = [
	MOVEMENT_POSTURE_POLICY_TRAVEL_UNTIL_THREAT,
	MOVEMENT_POSTURE_POLICY_ALWAYS_READY,
	MOVEMENT_POSTURE_POLICY_HOLD_READY,
	MOVEMENT_POSTURE_POLICY_AGGRESSIVE_READY,
	MOVEMENT_POSTURE_POLICY_OVERWATCH,
]
const HEAVY_WEAPON_ROLES: PackedStringArray = [
	HEAVY_WEAPON_NONE,
	HEAVY_WEAPON_ANTI_ARMOR,
	"support",
	"marksman",
]
const AIR_ASSET_RISK_PROFILES: PackedStringArray = [
	AIR_ASSET_RISK_NONE,
	AIR_ASSET_RISK_WATCH,
	AIR_ASSET_RISK_STRIKE,
	AIR_ASSET_RISK_LOSS,
]
const COMMUNICATION_INTENSITIES: PackedStringArray = [
	"low",
	COMMUNICATION_NORMAL,
	"high",
]

const PROFILE_DATA: Dictionary = {
	"guard_hold": {
		"display_name": "Guard Hold",
		"stance": "hold",
		"cover_behavior": "prefer_near_cover",
		"security_mode": "directional",
		"facing": "auto",
		"advance_style": "hold",
		"allowed_weapon_roles": ["rifle", "smg", "sidearm"],
		"sight_behavior": "watch_lane",
		"contact_behavior": "return_fire_hold",
		"weapon_profile": "standard_close",
		"visual_archetype": "enemy_space_suit_orange",
		"movement_posture_policy": "hold_ready",
		"ready_distance_world": 640.0,
		"travel_speed_factor": 0.35,
		"ready_speed_factor": 0.24,
		"aim_move_speed_factor": 0.18,
		"description": "Default holding team for small mission maps.",
	},
	"patrol_probe": {
		"display_name": "Patrol Probe",
		"stance": "patrol",
		"cover_behavior": "break_to_cover_on_contact",
		"security_mode": "patrol",
		"facing": "auto",
		"advance_style": "probe",
		"allowed_weapon_roles": ["rifle", "smg", "shotgun"],
		"sight_behavior": "scan_waypoints",
		"contact_behavior": "pin_then_report",
		"weapon_profile": "standard_close",
		"visual_archetype": "enemy_space_suit_orange",
		"movement_posture_policy": "travel_until_threat",
		"ready_distance_world": 640.0,
		"travel_speed_factor": 0.55,
		"ready_speed_factor": 0.30,
		"aim_move_speed_factor": 0.18,
		"description": "Default moving contact team for larger mission maps.",
	},
	"aggressive_push": {
		"display_name": "Aggressive Push",
		"stance": "assault",
		"cover_behavior": "cover_between_bounds",
		"security_mode": "directional",
		"facing": "auto",
		"advance_style": "rush",
		"allowed_weapon_roles": ["rifle", "smg", "shotgun", "heavy"],
		"sight_behavior": "short_arc",
		"contact_behavior": "close_distance",
		"weapon_profile": "assault_close",
		"visual_archetype": "enemy_space_suit_orange",
		"movement_posture_policy": "aggressive_ready",
		"ready_distance_world": 760.0,
		"travel_speed_factor": 0.45,
		"ready_speed_factor": 0.36,
		"aim_move_speed_factor": 0.20,
		"description": "Pressure team for planned pushes.",
	},
	"defensive_cover": {
		"display_name": "Defensive Cover",
		"stance": "defend",
		"cover_behavior": "hold_best_cover",
		"security_mode": "cover_arc",
		"facing": "auto",
		"advance_style": "bound_to_cover",
		"allowed_weapon_roles": ["rifle", "smg", "heavy"],
		"sight_behavior": "cover_arc",
		"contact_behavior": "suppress_from_cover",
		"weapon_profile": "defensive_mid",
		"visual_archetype": "enemy_space_suit_orange",
		"movement_posture_policy": "hold_ready",
		"ready_distance_world": 640.0,
		"travel_speed_factor": 0.35,
		"ready_speed_factor": 0.24,
		"aim_move_speed_factor": 0.18,
		"description": "Cover-oriented team for choke points and objectives.",
	},
	"sniper_watch": {
		"display_name": "Sniper Watch",
		"stance": "overwatch",
		"cover_behavior": "hold_high_cover",
		"security_mode": "overwatch",
		"facing": "auto",
		"advance_style": "hold",
		"allowed_weapon_roles": ["marksman", "rifle"],
		"sight_behavior": "long_lane",
		"contact_behavior": "prioritize_exposed_targets",
		"weapon_profile": "marksman_long",
		"visual_archetype": "enemy_space_suit_orange",
		"movement_posture_policy": "overwatch",
		"ready_distance_world": 900.0,
		"travel_speed_factor": 0.20,
		"ready_speed_factor": 0.18,
		"aim_move_speed_factor": 0.12,
		"description": "Long-lane watcher for later LOS and range work.",
	},
}


static func get_profile_ids() -> PackedStringArray:
	return PROFILE_IDS.duplicate()


static func get_security_modes() -> PackedStringArray:
	return SECURITY_MODES.duplicate()


static func get_facing_options() -> PackedStringArray:
	return FACING_OPTIONS.duplicate()


static func get_advance_styles() -> PackedStringArray:
	return ADVANCE_STYLES.duplicate()


static func get_movement_posture_policies() -> PackedStringArray:
	return MOVEMENT_POSTURE_POLICIES.duplicate()


static func get_heavy_weapon_roles() -> PackedStringArray:
	return HEAVY_WEAPON_ROLES.duplicate()


static func get_air_asset_risk_profiles() -> PackedStringArray:
	return AIR_ASSET_RISK_PROFILES.duplicate()


static func get_communication_intensities() -> PackedStringArray:
	return COMMUNICATION_INTENSITIES.duplicate()


static func get_anti_armor_weapon_ids() -> PackedStringArray:
	return WEAPON_DATA_SCRIPT.call("get_anti_armor_weapon_ids")


static func has_profile(profile_id: String) -> bool:
	return PROFILE_DATA.has(_normalize_key(profile_id))


static func get_profile(profile_id: String) -> Dictionary:
	var normalized_profile_id: String = _normalize_key(profile_id)
	if not PROFILE_DATA.has(normalized_profile_id):
		normalized_profile_id = DEFAULT_PROFILE_ID
	var profile: Dictionary = Dictionary(PROFILE_DATA.get(normalized_profile_id, {})).duplicate(true)
	profile["profile_id"] = normalized_profile_id
	return profile


static func get_default_profile_id_for_map_size(grid_size: Vector2i) -> String:
	var largest_dimension: int = maxi(grid_size.x, grid_size.y)
	if largest_dimension >= 64:
		return PROFILE_PATROL_PROBE
	return PROFILE_GUARD_HOLD


static func get_default_config_for_map_size(grid_size: Vector2i = Vector2i.ZERO, overrides: Dictionary = {}) -> Dictionary:
	var default_profile_id: String = get_default_profile_id_for_map_size(grid_size)
	if overrides.has("profile_id"):
		default_profile_id = String(overrides.get("profile_id", default_profile_id))
	return normalize_config(
		{
			"profile_id": default_profile_id,
			"security_mode": overrides.get("security_mode", ""),
			"facing": overrides.get("facing", DEFAULT_FACING),
			"patrol_area_id": overrides.get("patrol_area_id", ""),
			"hold_area_id": overrides.get("hold_area_id", ""),
			"weapon_profile": overrides.get("weapon_profile", ""),
			"visual_archetype": overrides.get("visual_archetype", ""),
		},
		grid_size
	)


static func normalize_advance_style(value: Variant, fallback: String = ADVANCE_STYLE_HOLD) -> String:
	var normalized_value: String = _normalize_key(value)
	match normalized_value:
		"", "guard", "watch", "overwatch":
			return fallback if ADVANCE_STYLES.has(fallback) else ADVANCE_STYLE_HOLD
		"rush", "aggressive", "aggressive_push", "assault":
			return ADVANCE_STYLE_PUSH
		"bound", "bounding", "bound_to_cover", "cover_between_bounds", "cover_arc":
			return ADVANCE_STYLE_BOUNDING
		"patrol", "patrol_probe", "probe", "creep":
			return ADVANCE_STYLE_PROBE
		"hold", "defend", "defensive", "sniper_watch":
			return ADVANCE_STYLE_HOLD
		_:
			return fallback if ADVANCE_STYLES.has(fallback) else ADVANCE_STYLE_HOLD


static func normalize_movement_posture_policy(value: Variant, fallback: String = MOVEMENT_POSTURE_POLICY_TRAVEL_UNTIL_THREAT) -> String:
	var normalized_value: String = _normalize_key(value)
	match normalized_value:
		"", "default":
			return fallback if MOVEMENT_POSTURE_POLICIES.has(fallback) else MOVEMENT_POSTURE_POLICY_TRAVEL_UNTIL_THREAT
		"travel", "patrol", "patrol_ready", "travel_until_contact", "travel_until_threat":
			return MOVEMENT_POSTURE_POLICY_TRAVEL_UNTIL_THREAT
		"ready", "always_ready", "tactical", "tactical_ready":
			return MOVEMENT_POSTURE_POLICY_ALWAYS_READY
		"hold", "hold_ready", "defend", "defensive", "defensive_ready":
			return MOVEMENT_POSTURE_POLICY_HOLD_READY
		"push", "aggressive", "aggressive_ready", "assault":
			return MOVEMENT_POSTURE_POLICY_AGGRESSIVE_READY
		"watch", "overwatch", "sniper_watch":
			return MOVEMENT_POSTURE_POLICY_OVERWATCH
		_:
			return fallback if MOVEMENT_POSTURE_POLICIES.has(fallback) else MOVEMENT_POSTURE_POLICY_TRAVEL_UNTIL_THREAT


static func normalize_config(raw_config: Variant, grid_size: Vector2i = Vector2i.ZERO) -> Dictionary:
	var source: Dictionary = Dictionary(raw_config) if typeof(raw_config) == TYPE_DICTIONARY else {}
	var diagnostics: PackedStringArray = PackedStringArray()
	for existing_diagnostic in PackedStringArray(source.get("diagnostics", PackedStringArray())):
		var diagnostic_text: String = String(existing_diagnostic)
		if not diagnostic_text.is_empty() and not diagnostics.has(diagnostic_text):
			diagnostics.append(diagnostic_text)

	var profile_id: String = _normalize_key(source.get("profile_id", source.get("profile", "")))
	if profile_id.is_empty():
		profile_id = get_default_profile_id_for_map_size(grid_size)
		diagnostics.append("missing_profile_id:%s" % profile_id)
	elif not PROFILE_DATA.has(profile_id):
		diagnostics.append("unknown_profile_id:%s" % profile_id)
		profile_id = get_default_profile_id_for_map_size(grid_size)

	var profile: Dictionary = get_profile(profile_id)
	var security_mode: String = _normalize_key(source.get("security_mode", profile.get("security_mode", DEFAULT_SECURITY_MODE)))
	if security_mode.is_empty():
		security_mode = String(profile.get("security_mode", DEFAULT_SECURITY_MODE))
		diagnostics.append("missing_security_mode:%s" % security_mode)
	elif not SECURITY_MODES.has(security_mode):
		diagnostics.append("unknown_security_mode:%s" % security_mode)
		security_mode = String(profile.get("security_mode", DEFAULT_SECURITY_MODE))

	var facing: String = _normalize_key(source.get("facing", profile.get("facing", DEFAULT_FACING)))
	if facing.is_empty():
		facing = String(profile.get("facing", DEFAULT_FACING))
		diagnostics.append("missing_facing:%s" % facing)
	elif not FACING_OPTIONS.has(facing):
		diagnostics.append("unknown_facing:%s" % facing)
		facing = String(profile.get("facing", DEFAULT_FACING))

	var advance_style: String = normalize_advance_style(source.get("advance_style", profile.get("advance_style", ADVANCE_STYLE_HOLD)), normalize_advance_style(profile.get("advance_style", ADVANCE_STYLE_HOLD)))
	var heavy_weapon_role: String = _normalize_list_value(source.get("heavy_weapon_role", HEAVY_WEAPON_NONE), HEAVY_WEAPON_ROLES, HEAVY_WEAPON_NONE)
	var weapon_id: String = _normalize_key(source.get("weapon_id", source.get("heavy_weapon_id", "")))
	if weapon_id.is_empty() and heavy_weapon_role == HEAVY_WEAPON_ANTI_ARMOR:
		weapon_id = "rocket_launcher"
		diagnostics.append("missing_anti_armor_weapon:rocket_launcher")
	elif not weapon_id.is_empty() and not bool(WEAPON_DATA_SCRIPT.call("is_valid_weapon_id", weapon_id)):
		diagnostics.append("unknown_weapon_id:%s" % weapon_id)
		weapon_id = ""
	var anti_armor_threat: bool = bool(source.get("anti_armor_threat", heavy_weapon_role == HEAVY_WEAPON_ANTI_ARMOR or bool(WEAPON_DATA_SCRIPT.call("is_anti_armor_weapon_id", weapon_id))))
	if anti_armor_threat and not bool(WEAPON_DATA_SCRIPT.call("is_anti_armor_weapon_id", weapon_id)):
		diagnostics.append("weapon_not_anti_armor:%s" % (weapon_id if not weapon_id.is_empty() else "none"))
	var air_asset_risk_profile: String = _normalize_list_value(source.get("air_asset_risk_profile", source.get("air_asset_risk", AIR_ASSET_RISK_NONE)), AIR_ASSET_RISK_PROFILES, AIR_ASSET_RISK_NONE)
	var communication_intensity: String = _normalize_list_value(source.get("communication_intensity", COMMUNICATION_NORMAL), COMMUNICATION_INTENSITIES, COMMUNICATION_NORMAL)
	var default_posture_policy: String = normalize_movement_posture_policy(profile.get("movement_posture_policy", MOVEMENT_POSTURE_POLICY_TRAVEL_UNTIL_THREAT))
	var movement_posture_policy: String = normalize_movement_posture_policy(source.get("movement_posture_policy", source.get("posture_policy_id", default_posture_policy)), default_posture_policy)
	var ready_distance_world: float = _normalize_float(source.get("ready_distance_world", profile.get("ready_distance_world", 640.0)), float(profile.get("ready_distance_world", 640.0)), 0.0)
	var travel_speed_factor: float = _normalize_float(source.get("travel_speed_factor", profile.get("travel_speed_factor", 0.55)), float(profile.get("travel_speed_factor", 0.55)), 0.0)
	var ready_speed_factor: float = _normalize_float(source.get("ready_speed_factor", profile.get("ready_speed_factor", 0.30)), float(profile.get("ready_speed_factor", 0.30)), 0.0)
	var aim_move_speed_factor: float = _normalize_float(source.get("aim_move_speed_factor", profile.get("aim_move_speed_factor", 0.18)), float(profile.get("aim_move_speed_factor", 0.18)), 0.0)

	var result: Dictionary = {
		"profile_id": profile_id,
		"security_mode": security_mode,
		"facing": facing,
		"stance": String(profile.get("stance", "")),
		"cover_behavior": String(profile.get("cover_behavior", "")),
		"advance_style": advance_style,
		"allowed_weapon_roles": Array(profile.get("allowed_weapon_roles", [])).duplicate(true),
		"sight_behavior": String(profile.get("sight_behavior", "")),
		"contact_behavior": String(profile.get("contact_behavior", "")),
		"weapon_profile": _normalize_key(source.get("weapon_profile", profile.get("weapon_profile", ""))),
		"visual_archetype": _normalize_key(source.get("visual_archetype", profile.get("visual_archetype", ""))),
		"heavy_weapon_role": heavy_weapon_role,
		"weapon_id": weapon_id,
		"anti_armor_threat": anti_armor_threat,
		"air_asset_risk_profile": air_asset_risk_profile,
		"lz_threat_zone_id": String(source.get("lz_threat_zone_id", source.get("lz_threat_marker_id", ""))).strip_edges(),
		"communication_intensity": communication_intensity,
		"movement_posture_policy": movement_posture_policy,
		"ready_distance_world": ready_distance_world,
		"travel_speed_factor": travel_speed_factor,
		"ready_speed_factor": ready_speed_factor,
		"aim_move_speed_factor": aim_move_speed_factor,
		"diagnostics": diagnostics,
	}
	for optional_key in ["patrol_area_id", "hold_area_id"]:
		var optional_value: String = String(source.get(optional_key, "")).strip_edges()
		if not optional_value.is_empty():
			result[optional_key] = optional_value
	return result


static func serialize_config(raw_config: Variant, grid_size: Vector2i = Vector2i.ZERO) -> Dictionary:
	var normalized: Dictionary = normalize_config(raw_config, grid_size)
	normalized.erase("diagnostics")
	return normalized


static func validate_config(raw_config: Variant, grid_size: Vector2i = Vector2i.ZERO) -> Dictionary:
	var normalized: Dictionary = normalize_config(raw_config, grid_size)
	var errors: PackedStringArray = PackedStringArray()
	for required_key in [
		"profile_id",
		"security_mode",
		"facing",
		"stance",
		"cover_behavior",
		"advance_style",
		"sight_behavior",
		"contact_behavior",
		"weapon_profile",
		"visual_archetype",
		"movement_posture_policy",
	]:
		if String(normalized.get(required_key, "")).strip_edges().is_empty():
			errors.append("missing_field:%s" % required_key)
	if Array(normalized.get("allowed_weapon_roles", [])).is_empty():
		errors.append("missing_field:allowed_weapon_roles")
	if bool(normalized.get("anti_armor_threat", false)) and not bool(WEAPON_DATA_SCRIPT.call("is_anti_armor_weapon_id", String(normalized.get("weapon_id", "")))):
		errors.append("weapon_not_anti_armor:%s" % String(normalized.get("weapon_id", "none")))
	return {
		"valid": errors.is_empty(),
		"errors": errors,
		"diagnostics": PackedStringArray(normalized.get("diagnostics", PackedStringArray())),
		"config": normalized,
	}


static func _normalize_key(value: Variant) -> String:
	return String(value).strip_edges().to_lower()


static func _normalize_list_value(value: Variant, allowed_values: PackedStringArray, fallback: String) -> String:
	var normalized: String = _normalize_key(value)
	if allowed_values.has(normalized):
		return normalized
	return fallback


static func _normalize_float(value: Variant, fallback: float, minimum: float = 0.0) -> float:
	var result: float = fallback
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		result = float(value)
	elif typeof(value) == TYPE_STRING or typeof(value) == TYPE_STRING_NAME:
		var text: String = String(value).strip_edges()
		if text.is_valid_float():
			result = text.to_float()
	return maxf(result, minimum)
