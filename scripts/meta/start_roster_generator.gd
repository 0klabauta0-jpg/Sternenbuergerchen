class_name StartRosterGenerator
extends RefCounted

const META_UNIT_PROFILE_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile.gd")
const META_UNIT_PROFILE_BUILDER_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile_builder.gd")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")
const NPC_RANK_BADGE_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/npc_rank_badge_resolver.gd")
const PORTRAIT_IDENTITY_CATALOG_SCRIPT: GDScript = preload("res://scripts/meta/portrait_identity_catalog.gd")
const ROSTER_RELATIONSHIP_MODEL_SCRIPT: GDScript = preload("res://scripts/meta/roster_relationship_model.gd")
const FIRETEAM_COHESION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/fireteam_cohesion_resolver.gd")

const SCHEMA_VERSION: int = 1
const DEFAULT_SEED: String = "sternenbuergerchen_start_roster_v1"
const DEFAULT_PLAYER_PROFILE_ID: String = "local_player"
const DEFAULT_ROSTER_SIZE: int = 24
const MIN_ROSTER_SIZE: int = 20
const MAX_ROSTER_SIZE: int = 30
const MIN_SKILL_VALUE: float = 0.22
const MAX_SKILL_VALUE: float = 0.86
const VALID_ROLE_CATEGORIES: PackedStringArray = [
	"medic",
	"shooter",
	"leader",
	"engineer",
	"pilot",
	"heavy_support",
	"scout_sniper",
]
const FIRETEAM_IDS: PackedStringArray = ["blue", "gold", "reserve", "med", "flight"]

const ROLE_TEMPLATES: Dictionary = {
	"leader": {
		"role_id": "field_captain",
		"role_name": "Fireteam Leader",
		"weapon_1": "rifle",
		"weapon_2": "smg",
		"armor": "medium",
		"loadout_summary": "Command rifle, uplink slate, signal kit",
		"specialty_text": "Small-unit command",
		"skill_accuracy": 0.56,
		"skill_speed": 0.48,
		"skill_leadership": 0.74,
		"skill_toughness": 0.54,
		"trait_ids": ["calm", "steady"],
	},
	"medic": {
		"role_id": "combat_medic",
		"role_name": "Combat Medic",
		"weapon_1": "smg",
		"weapon_2": "medictool",
		"armor": "light",
		"loadout_summary": "Medical rig, injector pack, compact SMG",
		"specialty_text": "Trauma support",
		"skill_accuracy": 0.42,
		"skill_speed": 0.58,
		"skill_leadership": 0.38,
		"skill_toughness": 0.60,
		"trait_ids": ["cautious", "steady"],
	},
	"shooter": {
		"role_id": "security_guard",
		"role_name": "Rifle Operator",
		"weapon_1": "rifle",
		"weapon_2": "smg",
		"armor": "medium",
		"loadout_summary": "Rifle, compact sidearm, field kit",
		"specialty_text": "Line fire",
		"skill_accuracy": 0.62,
		"skill_speed": 0.50,
		"skill_leadership": 0.34,
		"skill_toughness": 0.52,
		"trait_ids": ["steady"],
	},
	"engineer": {
		"role_id": "combat_engineer",
		"role_name": "Combat Engineer",
		"weapon_1": "smg",
		"weapon_2": "rifle",
		"armor": "medium",
		"loadout_summary": "Tool harness, cutter, compact repeater",
		"specialty_text": "Repair and breach routing",
		"skill_accuracy": 0.44,
		"skill_speed": 0.48,
		"skill_leadership": 0.44,
		"skill_toughness": 0.66,
		"trait_ids": ["steady", "calm"],
	},
	"pilot": {
		"role_id": "dropship_pilot",
		"role_name": "Dropship Pilot",
		"weapon_1": "smg",
		"weapon_2": "smg",
		"armor": "light",
		"loadout_summary": "Flight harness, machine pistol, nav slate",
		"specialty_text": "Insertion piloting",
		"skill_accuracy": 0.38,
		"skill_speed": 0.66,
		"skill_leadership": 0.48,
		"skill_toughness": 0.46,
		"dropship_piloting": 0.78,
		"trait_ids": ["calm", "reckless"],
	},
	"heavy_support": {
		"role_id": "heavy_gunner",
		"role_name": "Heavy Support",
		"weapon_1": "rail_gun",
		"weapon_2": "smg",
		"armor": "heavy",
		"loadout_summary": "Heavy weapon, ammo sled, brace rig",
		"specialty_text": "Suppression and anchor fire",
		"skill_accuracy": 0.54,
		"skill_speed": 0.34,
		"skill_leadership": 0.34,
		"skill_toughness": 0.76,
		"trait_ids": ["aggressive", "steady"],
	},
	"scout_sniper": {
		"role_id": "recon_scout",
		"role_name": "Scout Sniper",
		"weapon_1": "sniper",
		"weapon_2": "smg",
		"armor": "light",
		"loadout_summary": "Long rifle, sensor darts, recon kit",
		"specialty_text": "Route scouting and overwatch",
		"skill_accuracy": 0.72,
		"skill_speed": 0.66,
		"skill_leadership": 0.36,
		"skill_toughness": 0.42,
		"trait_ids": ["calm", "cautious"],
	},
}

const TEAM_ROLE_PATTERN: PackedStringArray = [
	"leader",
	"medic",
	"shooter",
	"engineer",
	"pilot",
	"heavy_support",
	"leader",
	"scout_sniper",
	"shooter",
	"medic",
	"heavy_support",
	"engineer",
	"leader",
	"pilot",
	"scout_sniper",
	"shooter",
	"engineer",
	"heavy_support",
	"leader",
	"medic",
	"shooter",
	"engineer",
	"pilot",
	"scout_sniper",
	"leader",
	"heavy_support",
	"shooter",
	"medic",
	"pilot",
	"scout_sniper",
]
const FIRST_NAMES: PackedStringArray = [
	"Anja", "Milo", "Leona", "Darius", "Talia", "Kenzo", "Sabine", "Idris", "Nika", "Pavel",
	"Yasmin", "Tomas", "Rhea", "Jaro", "Mina", "Orin", "Vera", "Elias", "Kira", "Nolan",
	"Seren", "Marek", "Ilya", "Rina", "Anton", "Livia", "Noor", "Bela", "Sena", "Arun",
]
const LAST_NAMES: PackedStringArray = [
	"Voss", "Saren", "Rhee", "Holt", "Mercer", "Vale", "Orlov", "Kane", "Sol", "Dorn",
	"Arendt", "Ibarra", "Novak", "Kade", "Wren", "Kovac", "Moss", "Rask", "Lenn", "Brix",
	"Vega", "Sato", "Mira", "Pike", "Havel", "Quinn", "Bora", "Hale", "Tarek", "Moro",
]
const CALLSIGNS: PackedStringArray = [
	"ROOK", "PATCH", "QUILL", "RAM", "VOX", "NEEDLE", "TORCH", "MASTIFF", "GLINT", "LATCH",
	"CIPHER", "WAKE", "FUSE", "VAULT", "MOTH", "BRACE", "SPAR", "HUSH", "KEEL", "RIFT",
	"EMBER", "COIL", "HALO", "VANE", "AXIS", "MICA", "NORTH", "WICK", "DOVE", "MINT",
]
const HOMEWORLDS: PackedStringArray = [
	"Bastion-7", "Iona Station", "Khepri Belt", "Nadir Colony", "Meridian Array",
	"Rimehold", "Volkov Reach", "Cinder Basin", "Solaris Verge", "Anchor Nine",
]
const EXTRA_TRAITS: PackedStringArray = ["calm", "steady", "cautious", "aggressive", "reckless"]


static func generate_start_roster(seed: String = DEFAULT_SEED, roster_size: int = DEFAULT_ROSTER_SIZE, player_profile_id: String = DEFAULT_PLAYER_PROFILE_ID) -> Dictionary:
	var normalized_seed: String = seed.strip_edges()
	if normalized_seed.is_empty():
		normalized_seed = DEFAULT_SEED
	var normalized_size: int = clampi(roster_size, MIN_ROSTER_SIZE, MAX_ROSTER_SIZE)
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed_to_int("%s:%d:%s" % [normalized_seed, normalized_size, player_profile_id])
	var role_plan: PackedStringArray = _build_role_plan(normalized_size)
	var portrait_entries: Array = _build_portrait_assignment_pool(normalized_seed, normalized_size, role_plan)
	var used_names: Dictionary = {}
	var used_callsigns: Dictionary = {}
	var units: Array = []
	for index in range(normalized_size):
		var role_category: String = String(role_plan[index])
		var fireteam_id: String = _fireteam_for_index(index, normalized_size)
		var identity: Dictionary = _build_identity(index, role_category, fireteam_id, normalized_seed, rng, portrait_entries, used_names, used_callsigns)
		var profile = META_UNIT_PROFILE_BUILDER_SCRIPT.call("build_from_identity_config", identity)
		var profile_data: Dictionary = Dictionary(profile.call("to_dict")) if profile != null and profile.has_method("to_dict") else identity.duplicate(true)
		profile_data["roster_role_category"] = role_category
		profile_data["roster_seed_index"] = index
		profile_data["player_profile_id"] = player_profile_id
		profile_data["rank_badges"] = NPC_RANK_BADGE_RESOLVER_SCRIPT.call("get_badges_for_profile", profile_data)
		units.append(profile_data)
	var relationship_pairs: Array = ROSTER_RELATIONSHIP_MODEL_SCRIPT.call("build_deterministic_start_relationships", units, normalized_seed)
	units = ROSTER_RELATIONSHIP_MODEL_SCRIPT.call("apply_relationships_to_units", units, relationship_pairs, true)
	var fireteam_suggestions: Array = FIRETEAM_COHESION_RESOLVER_SCRIPT.call("annotate_fireteams", _build_fireteam_suggestions(units), units)
	var roster: Dictionary = {
		"schema_version": SCHEMA_VERSION,
		"generator_id": "start_roster_generator_v1",
		"seed": normalized_seed,
		"player_profile_id": player_profile_id.strip_edges() if not player_profile_id.strip_edges().is_empty() else DEFAULT_PLAYER_PROFILE_ID,
		"roster_size": units.size(),
		"min_roster_size": MIN_ROSTER_SIZE,
		"max_roster_size": MAX_ROSTER_SIZE,
		"units": units,
		"role_mix": _build_role_mix(units),
		"relationship_pairs": relationship_pairs,
		"fireteam_suggestions": fireteam_suggestions,
		"multiplayer_boundary": {
			"ownership_scope": "player_profile_local",
			"host_roster_scope": "host_player_profile",
			"join_roster_scope": "joining_player_profile",
			"snapshot_policy": "do_not_publish_full_private_roster_without_mode_consent",
		},
	}
	var validation: Dictionary = validate_roster(roster)
	roster["valid"] = bool(validation.get("valid", false))
	roster["validation"] = validation
	return roster


static func build_first_start_snapshot(existing_roster: Dictionary = {}, seed: String = DEFAULT_SEED, roster_size: int = DEFAULT_ROSTER_SIZE, player_profile_id: String = DEFAULT_PLAYER_PROFILE_ID) -> Dictionary:
	var existing_validation: Dictionary = validate_roster(existing_roster)
	if bool(existing_validation.get("valid", false)):
		return {
			"created": false,
			"reason": "existing_roster",
			"roster": existing_roster.duplicate(true),
			"summary": build_summary_snapshot(existing_roster),
		}
	var generated: Dictionary = generate_start_roster(seed, roster_size, player_profile_id)
	return {
		"created": true,
		"reason": "missing_or_invalid_roster",
		"roster": generated,
		"summary": build_summary_snapshot(generated),
	}


static func build_generation_prompt(has_existing_roster: bool) -> Dictionary:
	return {
		"action_id": "new_start_roster",
		"label": "Neues Team generieren",
		"requires_confirmation": has_existing_roster,
		"message": "Bestehendes Startteam wird erst nach Bestaetigung ersetzt." if has_existing_roster else "Startteam wird erzeugt.",
	}


static func build_summary_snapshot(roster: Dictionary) -> Dictionary:
	var validation: Dictionary = validate_roster(roster)
	return {
		"valid": bool(validation.get("valid", false)),
		"seed": String(roster.get("seed", "")),
		"player_profile_id": String(roster.get("player_profile_id", "")),
		"roster_size": Array(roster.get("units", [])).size(),
		"role_mix": _build_role_mix(Array(roster.get("units", []))),
		"relationship_pair_count": Array(roster.get("relationship_pairs", [])).size(),
		"fireteam_count": Array(roster.get("fireteam_suggestions", [])).size(),
		"multiplayer_boundary": Dictionary(roster.get("multiplayer_boundary", {})).duplicate(true),
		"errors": PackedStringArray(validation.get("errors", PackedStringArray())),
		"warnings": PackedStringArray(validation.get("warnings", PackedStringArray())),
	}


static func validate_roster(roster: Dictionary) -> Dictionary:
	var errors: PackedStringArray = PackedStringArray()
	var warnings: PackedStringArray = PackedStringArray()
	if int(roster.get("schema_version", 0)) != SCHEMA_VERSION:
		errors.append("schema_version_invalid")
	var units: Array = Array(roster.get("units", []))
	if units.size() < MIN_ROSTER_SIZE or units.size() > MAX_ROSTER_SIZE:
		errors.append("roster_size_out_of_range")
	var unit_ids: Dictionary = {}
	var callsigns: Dictionary = {}
	var role_mix: Dictionary = {}
	for unit_variant in units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			errors.append("unit_not_dictionary")
			continue
		var unit: Dictionary = Dictionary(unit_variant)
		var profile = META_UNIT_PROFILE_SCRIPT.new(unit)
		var unit_id: String = String(unit.get("unit_id", "")).strip_edges()
		var callsign: String = String(unit.get("callsign", "")).strip_edges()
		var role_category: String = String(unit.get("roster_role_category", "")).strip_edges().to_lower()
		if not profile.call("is_valid"):
			errors.append("unit_invalid_profile")
		if unit_id.is_empty():
			errors.append("unit_id_missing")
		elif unit_ids.has(unit_id):
			errors.append("unit_id_duplicate:%s" % unit_id)
		unit_ids[unit_id] = true
		if callsign.is_empty():
			errors.append("callsign_missing:%s" % unit_id)
		elif callsigns.has(callsign):
			errors.append("callsign_duplicate:%s" % callsign)
		callsigns[callsign] = true
		if not VALID_ROLE_CATEGORIES.has(role_category):
			errors.append("role_category_invalid:%s" % unit_id)
		role_mix[role_category] = int(role_mix.get(role_category, 0)) + 1
		_validate_unit_skills(unit, unit_id, errors)
		if String(unit.get("portrait_path", "")).strip_edges().is_empty():
			errors.append("portrait_path_missing:%s" % unit_id)
		if not String(unit.get("portrait_path", "")).strip_edges().begins_with("res://"):
			errors.append("portrait_path_not_res:%s" % unit_id)
		if PackedStringArray(unit.get("trait_ids", PackedStringArray())).is_empty():
			warnings.append("unit_traits_empty:%s" % unit_id)
		if Array(unit.get("rank_badges", [])).is_empty():
			errors.append("rank_badges_missing:%s" % unit_id)
	for category in VALID_ROLE_CATEGORIES:
		if int(role_mix.get(category, 0)) <= 0:
			errors.append("role_category_missing:%s" % category)
	_validate_fireteams(Array(roster.get("fireteam_suggestions", [])), unit_ids, errors)
	var relationship_validation: Dictionary = Dictionary(ROSTER_RELATIONSHIP_MODEL_SCRIPT.call("validate_roster_relationships", units, Array(roster.get("relationship_pairs", []))))
	if not bool(relationship_validation.get("valid", false)):
		for relationship_error in PackedStringArray(relationship_validation.get("errors", PackedStringArray())):
			errors.append(relationship_error)
	for relationship_warning in PackedStringArray(relationship_validation.get("warnings", PackedStringArray())):
		warnings.append(relationship_warning)
	var boundary: Dictionary = Dictionary(roster.get("multiplayer_boundary", {}))
	if String(boundary.get("ownership_scope", "")) != "player_profile_local":
		errors.append("multiplayer_boundary_missing_player_profile_scope")
	return {
		"valid": errors.is_empty(),
		"errors": errors,
		"warnings": warnings,
		"role_mix": role_mix,
		"unit_count": units.size(),
	}


static func _build_identity(index: int, role_category: String, fireteam_id: String, seed: String, rng: RandomNumberGenerator, portrait_entries: Array, used_names: Dictionary, used_callsigns: Dictionary) -> Dictionary:
	var template: Dictionary = Dictionary(ROLE_TEMPLATES.get(role_category, ROLE_TEMPLATES.get("shooter", {})))
	var first_name: String = String(FIRST_NAMES[int(rng.randi_range(0, FIRST_NAMES.size() - 1))])
	var last_name: String = String(LAST_NAMES[int(rng.randi_range(0, LAST_NAMES.size() - 1))])
	var base_display_name: String = "%s %s" % [first_name, last_name]
	var display_name: String = base_display_name
	var name_guard: int = 2
	while used_names.has(display_name):
		display_name = "%s %02d" % [base_display_name, name_guard]
		name_guard += 1
	used_names[display_name] = true
	var base_callsign: String = String(CALLSIGNS[int(rng.randi_range(0, CALLSIGNS.size() - 1))])
	var callsign: String = base_callsign
	var callsign_guard: int = 2
	while used_callsigns.has(callsign):
		callsign = "%s%02d" % [base_callsign, callsign_guard]
		callsign_guard += 1
	used_callsigns[callsign] = true
	var identity: Dictionary = template.duplicate(true)
	identity["unit_id"] = "player_%s_%02d" % [_sanitize_seed_id(seed), index + 1]
	identity["display_name"] = display_name
	identity["callsign"] = callsign
	identity["roster_role_category"] = role_category
	identity["team_id"] = "team_alpha"
	identity["fireteam_id"] = fireteam_id
	identity["is_fireteam_lead"] = role_category == "leader"
	var portrait_entry: Dictionary = Dictionary(portrait_entries[index]) if index < portrait_entries.size() else {}
	identity["portrait_id"] = String(portrait_entry.get("id", "")).strip_edges()
	identity["portrait_path"] = String(portrait_entry.get("path", "")).strip_edges()
	identity["homeworld"] = String(HOMEWORLDS[int(rng.randi_range(0, HOMEWORLDS.size() - 1))])
	identity["age_years"] = int(rng.randi_range(23, 43))
	identity["biography_text"] = _build_biography(display_name, callsign, role_category)
	identity["availability_status"] = "active"
	identity["status_text"] = "active"
	identity["relationship_summary_text"] = "Teamfit wird nach gemeinsamen Einsaetzen bewertet."
	identity["relationship_links"] = []
	identity["fireteam_history"] = [{"fireteam_id": fireteam_id, "mission_id": "start_roster", "result": "suggested"}]
	identity["mission_history"] = []
	identity["progression"] = {
		"xp": 0,
		"missions_completed": 0,
		"morale": 0.50,
		"frustration": 0.0,
	}
	for key in ["skill_accuracy", "skill_speed", "skill_leadership", "skill_toughness", "dropship_piloting", "freighter_piloting", "fighter_piloting", "ground_vehicle_handling"]:
		if identity.has(key):
			identity[key] = _jitter_skill(float(identity.get(key, 0.5)), rng)
	var traits: PackedStringArray = _merge_traits(PackedStringArray(identity.get("trait_ids", PackedStringArray())), rng)
	identity["trait_ids"] = traits
	return identity


static func _build_role_plan(roster_size: int) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for index in range(roster_size):
		result.append(String(TEAM_ROLE_PATTERN[index % TEAM_ROLE_PATTERN.size()]))
	return result


static func _build_portrait_assignment_pool(seed: String, roster_size: int, role_plan: PackedStringArray) -> Array:
	var catalog_entries: Array = Array(PORTRAIT_IDENTITY_CATALOG_SCRIPT.call("build_deterministic_assignment", seed, roster_size, role_plan))
	if catalog_entries.size() >= roster_size:
		return catalog_entries
	var result: Array = []
	for unit_variant in UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster"):
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var path: String = String(Dictionary(unit_variant).get("portrait_path", "")).strip_edges()
		if path.is_empty():
			continue
		result.append({
			"id": "",
			"path": path,
			"fallback_source": "unit_roster_presets",
		})
	return result


static func _fireteam_for_index(index: int, roster_size: int) -> String:
	var target_team_count: int = clampi(ceili(float(roster_size) / 6.0), 3, FIRETEAM_IDS.size())
	var group_size: int = maxi(ceili(float(roster_size) / float(target_team_count)), 1)
	var team_index: int = clampi(floori(float(index) / float(group_size)), 0, target_team_count - 1)
	return String(FIRETEAM_IDS[team_index])


static func _build_fireteam_suggestions(units: Array) -> Array:
	var groups: Dictionary = {}
	for unit_variant in units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(unit_variant)
		var fireteam_id: String = String(unit.get("fireteam_id", "")).strip_edges().to_lower()
		if fireteam_id.is_empty():
			fireteam_id = "reserve"
		var list: Array = Array(groups.get(fireteam_id, []))
		list.append(String(unit.get("unit_id", "")))
		groups[fireteam_id] = list
	var suggestions: Array = []
	for fireteam_id in FIRETEAM_IDS:
		var unit_ids: Array = Array(groups.get(fireteam_id, []))
		if unit_ids.is_empty():
			continue
		suggestions.append({
			"fireteam_id": fireteam_id,
			"display_name": "%s Team" % String(fireteam_id).capitalize(),
			"unit_ids": PackedStringArray(unit_ids),
			"leader_unit_id": _pick_fireteam_leader_id(units, PackedStringArray(unit_ids)),
			"suggestion_policy": "balanced_not_optimal",
		})
	return suggestions


static func _pick_fireteam_leader_id(units: Array, unit_ids: PackedStringArray) -> String:
	var best_unit_id: String = ""
	var best_score: float = -1.0
	for unit_variant in units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(unit_variant)
		var unit_id: String = String(unit.get("unit_id", "")).strip_edges()
		if not unit_ids.has(unit_id):
			continue
		var score: float = float(Dictionary(unit.get("skill_values", {})).get("leadership", 0.0))
		if bool(unit.get("is_fireteam_lead", false)):
			score += 0.25
		if score > best_score:
			best_score = score
			best_unit_id = unit_id
	return best_unit_id


static func _build_role_mix(units: Variant) -> Dictionary:
	var result: Dictionary = {}
	for unit_variant in Array(units):
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var role_category: String = String(Dictionary(unit_variant).get("roster_role_category", "")).strip_edges().to_lower()
		if role_category.is_empty():
			role_category = "unknown"
		result[role_category] = int(result.get(role_category, 0)) + 1
	return result


static func _validate_unit_skills(unit: Dictionary, unit_id: String, errors: PackedStringArray) -> void:
	var skill_values: Dictionary = Dictionary(unit.get("skill_values", {}))
	for key in ["accuracy", "speed", "leadership", "toughness", "awareness", "discipline"]:
		if not skill_values.has(key):
			errors.append("skill_missing:%s:%s" % [unit_id, key])
			continue
		var value: float = float(skill_values.get(key, -1.0))
		if value < MIN_SKILL_VALUE or value > 1.0:
			errors.append("skill_out_of_range:%s:%s" % [unit_id, key])


static func _validate_fireteams(fireteams: Array, unit_ids: Dictionary, errors: PackedStringArray) -> void:
	if fireteams.is_empty():
		errors.append("fireteam_suggestions_missing")
	var seen_units: Dictionary = {}
	for fireteam_variant in fireteams:
		if typeof(fireteam_variant) != TYPE_DICTIONARY:
			errors.append("fireteam_not_dictionary")
			continue
		var fireteam: Dictionary = Dictionary(fireteam_variant)
		var member_ids: PackedStringArray = PackedStringArray(fireteam.get("unit_ids", PackedStringArray()))
		if member_ids.is_empty():
			errors.append("fireteam_empty:%s" % String(fireteam.get("fireteam_id", "")))
		var leader_id: String = String(fireteam.get("leader_unit_id", "")).strip_edges()
		if leader_id.is_empty() or not member_ids.has(leader_id):
			errors.append("fireteam_leader_invalid:%s" % String(fireteam.get("fireteam_id", "")))
		for unit_id in member_ids:
			if not unit_ids.has(unit_id):
				errors.append("fireteam_unknown_unit:%s" % unit_id)
			if seen_units.has(unit_id):
				errors.append("fireteam_duplicate_unit:%s" % unit_id)
			seen_units[unit_id] = true
	for unit_id in unit_ids.keys():
		if not seen_units.has(String(unit_id)):
			errors.append("fireteam_missing_unit:%s" % String(unit_id))


static func _jitter_skill(base_value: float, rng: RandomNumberGenerator) -> float:
	return clampf(base_value + rng.randf_range(-0.10, 0.10), MIN_SKILL_VALUE, MAX_SKILL_VALUE)


static func _merge_traits(base_traits: PackedStringArray, rng: RandomNumberGenerator) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for trait_id in base_traits:
		var normalized_trait: String = String(trait_id).strip_edges().to_lower()
		if not normalized_trait.is_empty() and not result.has(normalized_trait):
			result.append(normalized_trait)
	var extra_trait: String = String(EXTRA_TRAITS[int(rng.randi_range(0, EXTRA_TRAITS.size() - 1))])
	if not result.has(extra_trait):
		result.append(extra_trait)
	while result.size() > 2:
		result.remove_at(result.size() - 1)
	return result


static func _build_biography(display_name: String, callsign: String, role_category: String) -> String:
	return "%s, callsign %s, joins the starting roster as %s with useful strengths and visible gaps." % [
		display_name,
		callsign,
		role_category.replace("_", " "),
	]


static func _seed_to_int(seed_text: String) -> int:
	var value: int = 2166136261
	for index in range(seed_text.length()):
		value = int((value ^ seed_text.unicode_at(index)) * 16777619) & 0x7fffffff
	return maxi(value, 1)


static func _sanitize_seed_id(seed_text: String) -> String:
	var normalized: String = seed_text.strip_edges().to_lower()
	var result: String = ""
	for index in range(normalized.length()):
		var character: String = normalized.substr(index, 1)
		if (character >= "a" and character <= "z") or (character >= "0" and character <= "9"):
			result += character
		elif character == "_" or character == "-":
			result += "_"
	if result.is_empty():
		result = "seed"
	return result.substr(0, 18)
