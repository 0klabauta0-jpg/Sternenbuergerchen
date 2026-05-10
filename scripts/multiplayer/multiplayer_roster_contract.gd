class_name MultiplayerRosterContract
extends RefCounted

const HOST_PEER_ID: int = 1

const ROSTER_MODE_HOST_ROSTER: String = "host_roster"
const ROSTER_MODE_PLAYER_ROSTERS: String = "player_rosters"
const ROSTER_MODE_SCENARIO_ROSTER: String = "scenario_roster"
const VALID_ROSTER_MODES: PackedStringArray = [
	ROSTER_MODE_PLAYER_ROSTERS,
	ROSTER_MODE_HOST_ROSTER,
	ROSTER_MODE_SCENARIO_ROSTER,
]

const ROSTER_SOURCE_HOST: String = "host"
const ROSTER_SOURCE_PLAYER: String = "player"
const ROSTER_SOURCE_SCENARIO: String = "scenario"
const CHARACTER_GAMEPLAY_AUTHORITY: String = "host_server"

const PUBLIC_UNIT_FIELDS: PackedStringArray = [
	"unit_id",
	"display_name",
	"callsign",
	"role_id",
	"role_name",
	"roster_role_category",
	"portrait_id",
	"fireteam_id",
	"rank_badges",
]
const SNAPSHOT_OWNERSHIP_FIELDS: PackedStringArray = [
	"unit_id",
	"owner_peer_id",
	"roster_source",
	"roster_mode",
	"roster_public_ref",
	"character_gameplay_authority",
]
const PRIVATE_ROSTER_FIELDS: PackedStringArray = [
	"age_years",
	"availability_status",
	"biography_text",
	"core_values",
	"fireteam_history",
	"function_scores",
	"generator_seed",
	"homeworld",
	"mission_history",
	"multiplayer_boundary",
	"personnel_events",
	"platform_values",
	"player_profile_id",
	"portrait_path",
	"progression",
	"recovery_state",
	"relationship_links",
	"relationship_pairs",
	"relationship_summary_text",
	"roster_seed_index",
	"save_seed",
	"seed",
	"skill_summary_text",
	"skill_values",
	"status_text",
	"trait_ids",
	"validation",
]


static func normalize_roster_mode(mode: Variant) -> String:
	var normalized: String = String(mode).strip_edges().to_lower()
	if VALID_ROSTER_MODES.has(normalized):
		return normalized
	return ROSTER_MODE_PLAYER_ROSTERS


static func is_valid_roster_mode(mode: Variant) -> bool:
	return VALID_ROSTER_MODES.has(String(mode).strip_edges().to_lower())


static func get_roster_mode_label(mode: Variant) -> String:
	match normalize_roster_mode(mode):
		ROSTER_MODE_PLAYER_ROSTERS:
			return "Local player rosters"
		ROSTER_MODE_SCENARIO_ROSTER:
			return "Scenario roster"
		_:
			return "Host roster"


static func build_lobby_roster_mode_snapshot(mode: Variant, local_peer_id: int = HOST_PEER_ID) -> Dictionary:
	var normalized_mode: String = normalize_roster_mode(mode)
	return {
		"roster_mode": normalized_mode,
		"roster_mode_label": get_roster_mode_label(normalized_mode),
		"valid_roster_modes": VALID_ROSTER_MODES,
		"host_selects_roster_mode": true,
		"uses_local_roster": _mode_uses_local_roster(normalized_mode, local_peer_id),
		"local_roster_owner_peer_id": _owner_peer_for_mode(normalized_mode, local_peer_id, local_peer_id == HOST_PEER_ID),
		"public_unit_fields": PUBLIC_UNIT_FIELDS,
		"private_unit_fields": PRIVATE_ROSTER_FIELDS,
		"snapshot_ownership_fields": SNAPSHOT_OWNERSHIP_FIELDS,
		"public_data_policy": "identity_role_portrait_fireteam_badges_only",
		"private_data_policy": "local_profile_save_progression_relationships_events_never_snapshot",
		"mission_authority": CHARACTER_GAMEPLAY_AUTHORITY,
	}


static func build_peer_roster_identity(peer_id: int, mode: Variant, is_host_peer: bool = false, profile_id: String = "", fireteam_ids: Variant = PackedStringArray()) -> Dictionary:
	var normalized_mode: String = normalize_roster_mode(mode)
	var owner_peer_id: int = _owner_peer_for_mode(normalized_mode, peer_id, is_host_peer)
	var roster_source: String = _source_for_mode(normalized_mode, is_host_peer)
	var normalized_fireteams: PackedStringArray = _normalize_string_array(fireteam_ids)
	return {
		"peer_id": peer_id,
		"owner_peer_id": owner_peer_id,
		"roster_source": roster_source,
		"roster_mode": normalized_mode,
		"roster_public_ref": _build_public_ref(owner_peer_id, roster_source),
		"profile_public_ref": _build_profile_public_ref(peer_id, roster_source, profile_id),
		"uses_local_roster": _mode_uses_local_roster(normalized_mode, peer_id),
		"can_manage_private_roster": owner_peer_id == peer_id and roster_source != ROSTER_SOURCE_SCENARIO,
		"fireteam_ids": normalized_fireteams,
		"character_gameplay_authority": CHARACTER_GAMEPLAY_AUTHORITY,
	}


static func build_unit_ownership_snapshot(unit: Dictionary, owner_peer_id: int = HOST_PEER_ID, roster_source: String = ROSTER_SOURCE_HOST, mode: Variant = ROSTER_MODE_HOST_ROSTER) -> Dictionary:
	var unit_id: String = String(unit.get("unit_id", "")).strip_edges()
	if unit_id.is_empty():
		return {}
	var normalized_source: String = _normalize_roster_source(roster_source)
	var normalized_mode: String = normalize_roster_mode(mode)
	return {
		"unit_id": unit_id,
		"owner_peer_id": maxi(owner_peer_id, 0),
		"roster_source": normalized_source,
		"roster_mode": normalized_mode,
		"roster_public_ref": _build_public_ref(maxi(owner_peer_id, 0), normalized_source),
		"fireteam_id": String(unit.get("fireteam_id", "")).strip_edges().to_lower(),
		"character_gameplay_authority": CHARACTER_GAMEPLAY_AUTHORITY,
	}


static func build_public_unit_profile(unit: Dictionary, owner_peer_id: int = HOST_PEER_ID, roster_source: String = ROSTER_SOURCE_HOST, mode: Variant = ROSTER_MODE_HOST_ROSTER) -> Dictionary:
	var profile: Dictionary = build_unit_ownership_snapshot(unit, owner_peer_id, roster_source, mode)
	if profile.is_empty():
		return {}
	for field in PUBLIC_UNIT_FIELDS:
		if field == "rank_badges":
			profile[field] = _normalize_public_badges(unit.get(field, []))
			continue
		if not unit.has(field):
			continue
		profile[field] = String(unit.get(field, "")).strip_edges()
	if String(profile.get("display_name", "")).strip_edges().is_empty():
		profile["display_name"] = String(profile.get("unit_id", "Unit"))
	if String(profile.get("portrait_id", "")).strip_edges().is_empty():
		profile["portrait_id"] = "portrait_missing"
		profile["portrait_missing"] = true
	else:
		profile["portrait_missing"] = false
	return profile


static func build_public_roster_preview(roster: Dictionary, owner_peer_id: int = HOST_PEER_ID, roster_source: String = ROSTER_SOURCE_PLAYER, mode: Variant = ROSTER_MODE_PLAYER_ROSTERS) -> Dictionary:
	var public_units: Array = []
	for unit_variant in Array(roster.get("units", [])):
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var public_profile: Dictionary = build_public_unit_profile(Dictionary(unit_variant), owner_peer_id, roster_source, mode)
		if not public_profile.is_empty():
			public_units.append(public_profile)
	return {
		"roster_mode": normalize_roster_mode(mode),
		"owner_peer_id": maxi(owner_peer_id, 0),
		"roster_source": _normalize_roster_source(roster_source),
		"roster_size": public_units.size(),
		"profile_public_ref": _build_profile_public_ref(owner_peer_id, roster_source, String(roster.get("player_profile_id", ""))),
		"public_units": public_units,
		"public_unit_fields": PUBLIC_UNIT_FIELDS,
		"privacy_policy": "preview_excludes_progression_relationships_seed_events_and_asset_paths",
	}


static func normalize_snapshot_unit_ownership(entry: Dictionary, default_owner_peer_id: int = HOST_PEER_ID, default_roster_source: String = ROSTER_SOURCE_HOST, default_mode: Variant = ROSTER_MODE_HOST_ROSTER) -> Dictionary:
	var owner_peer_id: int = maxi(int(entry.get("owner_peer_id", default_owner_peer_id)), 0)
	var roster_source: String = _normalize_roster_source(String(entry.get("roster_source", default_roster_source)))
	var roster_mode: String = normalize_roster_mode(entry.get("roster_mode", default_mode))
	var public_ref: String = String(entry.get("roster_public_ref", "")).strip_edges()
	if public_ref.is_empty():
		public_ref = _build_public_ref(owner_peer_id, roster_source)
	return {
		"owner_peer_id": owner_peer_id,
		"roster_source": roster_source,
		"roster_mode": roster_mode,
		"roster_public_ref": public_ref,
		"character_gameplay_authority": CHARACTER_GAMEPLAY_AUTHORITY,
	}


static func strip_private_roster_fields(value: Variant) -> Variant:
	if typeof(value) == TYPE_DICTIONARY:
		var result: Dictionary = {}
		var source: Dictionary = Dictionary(value)
		for key_variant in source.keys():
			var key: String = String(key_variant)
			if _is_private_roster_field(key):
				continue
			result[key] = strip_private_roster_fields(source.get(key_variant))
		return result
	if value is Array:
		var result_array: Array = []
		for entry_variant in Array(value):
			result_array.append(strip_private_roster_fields(entry_variant))
		return result_array
	if value is PackedStringArray:
		return PackedStringArray(value)
	return value


static func has_private_roster_fields(value: Variant) -> bool:
	if typeof(value) == TYPE_DICTIONARY:
		var source: Dictionary = Dictionary(value)
		for key_variant in source.keys():
			if _is_private_roster_field(String(key_variant)):
				return true
			if has_private_roster_fields(source.get(key_variant)):
				return true
		return false
	if value is Array:
		for entry_variant in Array(value):
			if has_private_roster_fields(entry_variant):
				return true
	return false


static func validate_public_roster_payload(payload: Variant) -> Dictionary:
	var errors: PackedStringArray = PackedStringArray()
	if has_private_roster_fields(payload):
		errors.append("private_roster_fields_present")
	if typeof(payload) == TYPE_DICTIONARY:
		for unit_variant in Array(Dictionary(payload).get("public_units", [])):
			if typeof(unit_variant) != TYPE_DICTIONARY:
				errors.append("public_unit_not_dictionary")
				continue
			var unit: Dictionary = Dictionary(unit_variant)
			if String(unit.get("unit_id", "")).strip_edges().is_empty():
				errors.append("public_unit_id_missing")
			if not unit.has("owner_peer_id") or not unit.has("roster_source"):
				errors.append("public_unit_ownership_missing")
	return {
		"valid": errors.is_empty(),
		"errors": errors,
	}


static func _mode_uses_local_roster(mode: String, peer_id: int) -> bool:
	if peer_id <= 0:
		return false
	if mode == ROSTER_MODE_PLAYER_ROSTERS:
		return true
	if mode == ROSTER_MODE_HOST_ROSTER:
		return peer_id == HOST_PEER_ID
	return false


static func _owner_peer_for_mode(mode: String, peer_id: int, is_host_peer: bool) -> int:
	if mode == ROSTER_MODE_SCENARIO_ROSTER:
		return 0
	if mode == ROSTER_MODE_PLAYER_ROSTERS:
		return maxi(peer_id, 0)
	if is_host_peer:
		return HOST_PEER_ID
	return HOST_PEER_ID


static func _source_for_mode(mode: String, is_host_peer: bool) -> String:
	if mode == ROSTER_MODE_SCENARIO_ROSTER:
		return ROSTER_SOURCE_SCENARIO
	if mode == ROSTER_MODE_PLAYER_ROSTERS:
		return ROSTER_SOURCE_PLAYER
	return ROSTER_SOURCE_HOST if is_host_peer else ROSTER_SOURCE_HOST


static func _normalize_roster_source(roster_source: String) -> String:
	var normalized: String = roster_source.strip_edges().to_lower()
	if normalized == ROSTER_SOURCE_PLAYER or normalized == ROSTER_SOURCE_SCENARIO or normalized == ROSTER_SOURCE_HOST:
		return normalized
	return ROSTER_SOURCE_HOST


static func _build_public_ref(owner_peer_id: int, roster_source: String) -> String:
	return "%s:%d" % [_normalize_roster_source(roster_source), maxi(owner_peer_id, 0)]


static func _build_profile_public_ref(peer_id: int, roster_source: String, profile_id: String) -> String:
	var source: String = _normalize_roster_source(roster_source)
	var suffix: String = "profile"
	if not profile_id.strip_edges().is_empty():
		suffix = "profile_%08x" % int(abs(hash(profile_id.strip_edges().to_lower())))
	return "%s:%d:%s" % [source, maxi(peer_id, 0), suffix]


static func _normalize_public_badges(value: Variant) -> Array:
	var result: Array = []
	for badge_variant in Array(value):
		if typeof(badge_variant) != TYPE_DICTIONARY:
			continue
		var badge: Dictionary = Dictionary(badge_variant)
		var badge_id: String = String(badge.get("badge_id", "")).strip_edges()
		if badge_id.is_empty():
			continue
		result.append({
			"badge_id": badge_id,
			"label": String(badge.get("label", "")).strip_edges(),
			"asset_missing": bool(badge.get("asset_missing", false)),
		})
	return result


static func _normalize_string_array(value: Variant) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	var source: Array = []
	if value is PackedStringArray:
		for entry in PackedStringArray(value):
			source.append(entry)
	elif value is Array:
		source = Array(value)
	for entry_variant in source:
		var entry: String = String(entry_variant).strip_edges().to_lower()
		if entry.is_empty() or result.has(entry):
			continue
		result.append(entry)
	return result


static func _is_private_roster_field(key: String) -> bool:
	var normalized: String = key.strip_edges().to_lower()
	if PRIVATE_ROSTER_FIELDS.has(normalized):
		return true
	if normalized.begins_with("skill_"):
		return true
	return false
