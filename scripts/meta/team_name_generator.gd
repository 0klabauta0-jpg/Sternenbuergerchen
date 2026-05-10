class_name TeamNameGenerator
extends RefCounted

const CATALOG_PATH: String = "res://data/team_name_generator_catalog.json"
const FALLBACK_NAME: String = "Sternenwache Sieben"
const MAX_NAME_LENGTH: int = 42


static func generate_team_name(seed: String, profile_id: String = "local_player", generation_index: int = 0) -> Dictionary:
	var catalog: Dictionary = _load_catalog()
	var prefixes: PackedStringArray = _to_string_array(catalog.get("prefixes", []))
	var cores: PackedStringArray = _to_string_array(catalog.get("cores", []))
	var suffixes: PackedStringArray = _to_string_array(catalog.get("suffixes", []))
	if prefixes.is_empty() or cores.is_empty() or suffixes.is_empty():
		return _build_result(String(catalog.get("fallback_name", FALLBACK_NAME)), seed, profile_id, generation_index, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed_to_int("%s:%s:%d:team_name" % [seed.strip_edges(), profile_id.strip_edges(), generation_index])
	var prefix: String = String(prefixes[int(rng.randi_range(0, prefixes.size() - 1))])
	var core: String = String(cores[int(rng.randi_range(0, cores.size() - 1))])
	var suffix: String = String(suffixes[int(rng.randi_range(0, suffixes.size() - 1))])
	var use_suffix: bool = rng.randf() >= 0.22
	var name: String = "%s%s %s" % [prefix, core, suffix] if use_suffix else "%s%s" % [prefix, core]
	return _build_result(normalize_team_name(name, String(catalog.get("fallback_name", FALLBACK_NAME))), seed, profile_id, generation_index, false)


static func normalize_team_name(value: String, fallback: String = FALLBACK_NAME) -> String:
	var normalized: String = value.strip_edges()
	if normalized.is_empty():
		normalized = fallback.strip_edges()
	if normalized.is_empty():
		normalized = FALLBACK_NAME
	if normalized.length() > MAX_NAME_LENGTH:
		normalized = normalized.substr(0, MAX_NAME_LENGTH).strip_edges()
	return normalized


static func apply_team_name(roster: Dictionary, requested_name: String = "", seed: String = "", generation_index: int = 0) -> Dictionary:
	var next_roster: Dictionary = roster.duplicate(true)
	var profile_id: String = String(next_roster.get("player_profile_id", "local_player")).strip_edges()
	var resolved_seed: String = seed.strip_edges()
	if resolved_seed.is_empty():
		resolved_seed = String(next_roster.get("seed", "team")).strip_edges()
	var generated: Dictionary = generate_team_name(resolved_seed, profile_id, generation_index)
	var team_name: String = normalize_team_name(requested_name, String(generated.get("team_name", FALLBACK_NAME)))
	var identity: Dictionary = Dictionary(next_roster.get("team_identity", {})).duplicate(true)
	identity["team_name"] = team_name
	identity["suggested_team_name"] = String(generated.get("team_name", team_name))
	identity["name_seed"] = resolved_seed
	identity["name_generation_index"] = generation_index
	identity["owner_profile_id"] = profile_id
	identity["ownership_scope"] = "player_roster_profile"
	identity["multiplayer_authority_note"] = "display_identity_only_not_gameplay_truth"
	next_roster["team_identity"] = identity
	next_roster["team_name"] = team_name
	return next_roster


static func build_team_identity_snapshot(roster: Dictionary) -> Dictionary:
	var identity: Dictionary = Dictionary(roster.get("team_identity", {})).duplicate(true)
	var team_name: String = normalize_team_name(String(roster.get("team_name", identity.get("team_name", ""))))
	return {
		"team_name": team_name,
		"has_team_name": not team_name.strip_edges().is_empty(),
		"editable": true,
		"suggestion_available": true,
		"owner_profile_id": String(identity.get("owner_profile_id", roster.get("player_profile_id", ""))).strip_edges(),
		"ownership_scope": String(identity.get("ownership_scope", "player_roster_profile")),
		"multiplayer_authority_note": String(identity.get("multiplayer_authority_note", "display_identity_only_not_gameplay_truth")),
		"name_generation_index": int(identity.get("name_generation_index", 0)),
	}


static func validate_team_identity(roster: Dictionary) -> Dictionary:
	var errors: PackedStringArray = PackedStringArray()
	var snapshot: Dictionary = build_team_identity_snapshot(roster)
	if String(snapshot.get("team_name", "")).strip_edges().is_empty():
		errors.append("team_name_missing")
	if String(snapshot.get("ownership_scope", "")) != "player_roster_profile":
		errors.append("team_name_wrong_ownership_scope")
	if String(snapshot.get("multiplayer_authority_note", "")).strip_edges() != "display_identity_only_not_gameplay_truth":
		errors.append("team_name_authority_note_missing")
	return {
		"valid": errors.is_empty(),
		"errors": errors,
		"snapshot": snapshot,
	}


static func _build_result(team_name: String, seed: String, profile_id: String, generation_index: int, used_fallback: bool) -> Dictionary:
	return {
		"team_name": normalize_team_name(team_name),
		"seed": seed.strip_edges(),
		"profile_id": profile_id.strip_edges(),
		"generation_index": generation_index,
		"used_fallback": used_fallback,
	}


static func _load_catalog() -> Dictionary:
	if not FileAccess.file_exists(CATALOG_PATH):
		return {"fallback_name": FALLBACK_NAME}
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		return {"fallback_name": FALLBACK_NAME}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {"fallback_name": FALLBACK_NAME}


static func _to_string_array(value: Variant) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for item_variant in Array(value):
		var text: String = String(item_variant).strip_edges()
		if not text.is_empty():
			result.append(text)
	return result


static func _seed_to_int(value: String) -> int:
	var hash_value: int = 146959810
	for index in range(value.length()):
		hash_value = int((hash_value ^ value.unicode_at(index)) * 16777619) & 0x7fffffff
	return maxi(hash_value, 1)
