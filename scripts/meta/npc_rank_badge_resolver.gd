class_name NPCRankBadgeResolver
extends RefCounted

const RANK_PARTICLE_CATALOG_PATH: String = "res://data/rank_particle_asset_catalog.json"
const MAX_PRIMARY_BADGES: int = 3
const MIN_SCORE: float = 0.52

const BADGE_DEFINITIONS: Dictionary = {
	"medic": {"badge_id": "badge_role_medic", "label": "Medic", "priority": 10},
	"leader": {"badge_id": "badge_role_ftl", "label": "Leader", "priority": 20},
	"heavy": {"badge_id": "badge_role_heavy", "label": "Heavy", "priority": 30},
	"pilot": {"badge_id": "badge_role_pilot", "label": "Pilot", "priority": 40},
	"engineer": {"badge_id": "badge_role_engineer", "label": "Engineer", "priority": 50},
	"shooter": {"badge_id": "badge_role_rifle", "label": "Shooter", "priority": 60},
	"enemy": {"badge_id": "badge_role_enemy", "label": "Enemy", "priority": 90},
}

const HEAVY_WEAPONS: PackedStringArray = ["rail_gun", "rocket_launcher", "panzerfaust"]
const SHOOTER_WEAPONS: PackedStringArray = ["rifle", "smg", "sniper"]
const PILOT_KEYS: PackedStringArray = ["dropship_piloting", "freighter_piloting", "fighter_piloting", "ground_vehicle_handling"]

const BADGE_HELP_IDS: Dictionary = {
	"medic": "character_sheet.rank_badge.medic",
	"leader": "character_sheet.rank_badge.leader",
	"heavy": "character_sheet.rank_badge.heavy",
	"pilot": "character_sheet.rank_badge.pilot",
	"engineer": "character_sheet.rank_badge.engineer",
	"shooter": "character_sheet.rank_badge.shooter",
	"enemy": "character_sheet.rank_badge.enemy",
}

const BADGE_FORMULAS: Dictionary = {
	"medic": "Sources: medic role text, medictool loadout or medic trait tag. Highest matching source wins the badge score.",
	"leader": "Sources: fireteam lead flag, leader role text or Leadership. Leadership 0.68+ contributes 0.62 plus Leadership times 0.30.",
	"heavy": "Sources: heavy weapon loadout or heavy/support role text. Heavy weapons are rail gun, rocket launcher and panzerfaust.",
	"pilot": "Sources: pilot role text or best platform skill. Dropship, freighter, fighter and ground vehicle handling are checked.",
	"engineer": "Sources: engineer/tech/repair role text, engineer function score or engineer trait tag.",
	"shooter": "Sources: weapon loadout, shooter role text or Accuracy. Accuracy 0.68+ contributes 0.56 plus Accuracy times 0.34.",
	"enemy": "Source: profile team_id marks the unit as Team Bravo or enemy.",
}


static func derive_badges(profile_or_data: Variant, max_count: int = MAX_PRIMARY_BADGES) -> Array:
	var data: Dictionary = _profile_to_dictionary(profile_or_data)
	var candidates: Dictionary = {}
	_add_candidate(candidates, "medic", _score_medic(data), _reason_for("medic", data))
	_add_candidate(candidates, "leader", _score_leader(data), _reason_for("leader", data))
	_add_candidate(candidates, "heavy", _score_heavy(data), _reason_for("heavy", data))
	_add_candidate(candidates, "pilot", _score_pilot(data), _reason_for("pilot", data))
	_add_candidate(candidates, "engineer", _score_engineer(data), _reason_for("engineer", data))
	_add_candidate(candidates, "shooter", _score_shooter(data), _reason_for("shooter", data))
	_add_candidate(candidates, "enemy", _score_enemy(data), _reason_for("enemy", data))

	var ordered: Array = []
	for candidate_variant in candidates.values():
		var candidate: Dictionary = Dictionary(candidate_variant)
		if float(candidate.get("score", 0.0)) >= MIN_SCORE:
			ordered.append(candidate)
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if is_equal_approx(float(a.get("score", 0.0)), float(b.get("score", 0.0))):
			return int(a.get("priority", 999)) < int(b.get("priority", 999))
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)

	var result: Array = []
	var limit: int = clampi(max_count, 0, MAX_PRIMARY_BADGES)
	for index in range(mini(limit, ordered.size())):
		result.append(_hydrate_badge(Dictionary(ordered[index])))
	return result


static func get_badges_for_profile(profile_or_data: Variant, max_count: int = MAX_PRIMARY_BADGES) -> Array:
	var data: Dictionary = _profile_to_dictionary(profile_or_data)
	var existing: Array = Array(data.get("rank_badges", []))
	if not existing.is_empty():
		var result: Array = []
		var limit: int = clampi(max_count, 0, MAX_PRIMARY_BADGES)
		for index in range(mini(limit, existing.size())):
			if typeof(existing[index]) == TYPE_DICTIONARY:
				result.append(_hydrate_badge(Dictionary(existing[index])))
		return result
	return derive_badges(data, max_count)


static func get_badge_help_id(badge_key: String) -> String:
	var normalized_key: String = badge_key.strip_edges().to_lower()
	return String(BADGE_HELP_IDS.get(normalized_key, "character_sheet.rank_badges"))


static func format_badge_tooltip(badge: Dictionary) -> String:
	var label: String = String(badge.get("label", "Badge")).strip_edges()
	var reason: String = String(badge.get("reason", "")).strip_edges()
	var detail: String = String(badge.get("detail_text", badge.get("formula_text", ""))).strip_edges()
	var score_text: String = "Score %.2f" % float(badge.get("score", 0.0))
	var lines: PackedStringArray = PackedStringArray()
	lines.append("%s: %s" % [_optional_text(label, "Badge"), score_text])
	if not reason.is_empty():
		lines.append(reason)
	if not detail.is_empty():
		lines.append(detail)
	return "\n".join(lines)


static func apply_badge_help_metadata(control: Control, badge: Dictionary) -> void:
	if control == null:
		return
	var help_id: String = String(badge.get("help_id", get_badge_help_id(String(badge.get("badge_key", ""))))).strip_edges()
	control.set_meta("help_id", help_id)
	control.set_meta("help_dynamic_title", String(badge.get("label", "Badge")).strip_edges())
	control.set_meta("help_compact_lines", _badge_compact_lines(badge))
	control.set_meta("help_detail_lines", _badge_detail_lines(badge))
	control.tooltip_text = format_badge_tooltip(badge)


static func get_badge_asset_path(badge_id: String) -> String:
	var catalog_entry: Dictionary = _get_catalog_badge_entry(badge_id)
	return String(catalog_entry.get("path", "")).strip_edges()


static func _add_candidate(candidates: Dictionary, badge_key: String, score: float, reason: String) -> void:
	var definition: Dictionary = Dictionary(BADGE_DEFINITIONS.get(badge_key, {}))
	if definition.is_empty():
		return
	candidates[badge_key] = {
		"badge_key": badge_key,
		"badge_id": String(definition.get("badge_id", "")),
		"label": String(definition.get("label", badge_key.capitalize())),
		"score": clampf(score, 0.0, 1.0),
		"priority": int(definition.get("priority", 999)),
		"reason": reason,
		"help_id": get_badge_help_id(badge_key),
		"detail_text": String(BADGE_FORMULAS.get(badge_key, "")),
	}


static func _hydrate_badge(candidate: Dictionary) -> Dictionary:
	var badge_id: String = String(candidate.get("badge_id", "")).strip_edges()
	var catalog_entry: Dictionary = _get_catalog_badge_entry(badge_id)
	if not catalog_entry.is_empty():
		candidate["path"] = String(catalog_entry.get("path", "")).strip_edges()
		candidate["category"] = String(catalog_entry.get("category", "")).strip_edges()
		candidate["target_screen"] = String(catalog_entry.get("target_screen", "")).strip_edges()
	candidate["asset_missing"] = candidate.get("path", "") == "" or not ResourceLoader.exists(String(candidate.get("path", "")))
	return candidate


static func _score_medic(data: Dictionary) -> float:
	var role_text: String = _role_text(data)
	var weapons: PackedStringArray = _weapon_ids(data)
	var score: float = 0.0
	if role_text.contains("medic") or role_text.contains("sanitaet") or role_text.contains("heal"):
		score = maxf(score, 0.96)
	if weapons.has("medictool"):
		score = maxf(score, 0.94)
	if _string_array_has_fragment(_string_array(data.get("trait_ids", [])), "medic"):
		score = maxf(score, 0.86)
	return score


static func _score_leader(data: Dictionary) -> float:
	var role_text: String = _role_text(data)
	var leadership: float = _score_value(data, "leadership")
	var score: float = 0.0
	if bool(data.get("is_fireteam_lead", false)):
		score = maxf(score, 0.98)
	if role_text.contains("lead") or role_text.contains("leader") or role_text.contains("captain") or role_text.contains("commander"):
		score = maxf(score, 0.92)
	if leadership >= 0.68:
		score = maxf(score, 0.62 + leadership * 0.30)
	return score


static func _score_heavy(data: Dictionary) -> float:
	var role_text: String = _role_text(data)
	var weapons: PackedStringArray = _weapon_ids(data)
	var score: float = 0.0
	for weapon_id in weapons:
		if HEAVY_WEAPONS.has(weapon_id):
			score = maxf(score, 0.95)
	if role_text.contains("heavy") or role_text.contains("support"):
		score = maxf(score, 0.88)
	return score


static func _score_pilot(data: Dictionary) -> float:
	var role_text: String = _role_text(data)
	var platform_values: Dictionary = Dictionary(data.get("platform_values", {}))
	var best_platform: float = -1.0
	for key in PILOT_KEYS:
		best_platform = maxf(best_platform, float(platform_values.get(key, -1.0)))
	var score: float = 0.0
	if role_text.contains("pilot"):
		score = maxf(score, 0.94)
	if best_platform >= 0.65:
		score = maxf(score, 0.55 + best_platform * 0.38)
	return score


static func _score_engineer(data: Dictionary) -> float:
	var role_text: String = _role_text(data)
	var function_scores: Dictionary = Dictionary(data.get("function_scores", {}))
	var score: float = 0.0
	if role_text.contains("engineer") or role_text.contains("tech") or role_text.contains("repair"):
		score = maxf(score, 0.94)
	if float(function_scores.get("engineer", 0.0)) >= 0.60:
		score = maxf(score, 0.84)
	if _string_array_has_fragment(_string_array(data.get("trait_ids", [])), "engineer"):
		score = maxf(score, 0.84)
	return score


static func _score_shooter(data: Dictionary) -> float:
	var role_text: String = _role_text(data)
	var weapons: PackedStringArray = _weapon_ids(data)
	var accuracy: float = _score_value(data, "accuracy")
	var score: float = 0.0
	for weapon_id in weapons:
		if SHOOTER_WEAPONS.has(weapon_id):
			score = maxf(score, 0.76)
			if weapon_id == "sniper":
				score = maxf(score, 0.90)
	if role_text.contains("rifle") or role_text.contains("shooter") or role_text.contains("marksman") or role_text.contains("overwatch"):
		score = maxf(score, 0.84)
	if accuracy >= 0.68:
		score = maxf(score, 0.56 + accuracy * 0.34)
	return score


static func _score_enemy(data: Dictionary) -> float:
	var team_id: String = String(data.get("team_id", "")).strip_edges().to_lower()
	if team_id == "team_bravo" or team_id == "enemy":
		return 0.72
	return 0.0


static func _reason_for(badge_key: String, data: Dictionary) -> String:
	match badge_key:
		"medic":
			return "Medic score reads role/loadout text and medic trait tags."
		"leader":
			return "Leader score reads fireteam lead flag, role text and Leadership %.2f." % _score_value(data, "leadership")
		"heavy":
			return "Heavy score reads heavy weapon loadout and support role text."
		"pilot":
			return "Pilot score reads pilot role text and best platform skill %.2f." % _best_platform_value(data)
		"engineer":
			return "Engineer score reads engineer role, function score and trait tags."
		"shooter":
			return "Shooter score reads weapon loadout, role text and Accuracy %.2f." % _score_value(data, "accuracy")
		"enemy":
			return "Enemy badge is set by team_id or faction context."
		_:
			return String(data.get("unit_id", "npc"))


static func _role_text(data: Dictionary) -> String:
	var parts: PackedStringArray = []
	for key in ["source_role_id", "role_id", "role_name", "specialty_text", "primary_specialty", "secondary_specialty", "loadout_summary"]:
		var text: String = String(data.get(key, "")).strip_edges().to_lower()
		if not text.is_empty():
			parts.append(text)
	return " ".join(parts)


static func _weapon_ids(data: Dictionary) -> PackedStringArray:
	var result: PackedStringArray = []
	for key in ["weapon_1_id", "weapon_1", "weapon_2_id", "weapon_2"]:
		var weapon_id: String = String(data.get(key, "")).strip_edges().to_lower()
		if weapon_id.is_empty() or result.has(weapon_id):
			continue
		result.append(weapon_id)
	return result


static func _score_value(data: Dictionary, key: String) -> float:
	var skill_values: Dictionary = Dictionary(data.get("skill_values", data.get("core_values", {})))
	return clampf(float(skill_values.get(key, data.get("skill_%s" % key, 0.0))), 0.0, 1.0)


static func _best_platform_value(data: Dictionary) -> float:
	var platform_values: Dictionary = Dictionary(data.get("platform_values", {}))
	var best_platform: float = -1.0
	for key in PILOT_KEYS:
		best_platform = maxf(best_platform, float(platform_values.get(key, -1.0)))
	return maxf(best_platform, 0.0)


static func _badge_compact_lines(badge: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	var label: String = String(badge.get("label", "Badge")).strip_edges()
	lines.append("%s badge score %.2f." % [_optional_text(label, "Badge"), float(badge.get("score", 0.0))])
	var reason: String = String(badge.get("reason", "")).strip_edges()
	if not reason.is_empty():
		lines.append(reason)
	return lines


static func _badge_detail_lines(badge: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	var detail: String = String(badge.get("detail_text", badge.get("formula_text", ""))).strip_edges()
	if not detail.is_empty():
		lines.append(detail)
	return lines


static func _profile_to_dictionary(profile_or_data: Variant) -> Dictionary:
	if typeof(profile_or_data) == TYPE_DICTIONARY:
		return Dictionary(profile_or_data).duplicate(true)
	if profile_or_data != null and profile_or_data.has_method("to_dict"):
		return Dictionary(profile_or_data.call("to_dict")).duplicate(true)
	return {}


static func _get_catalog_badge_entry(badge_id: String) -> Dictionary:
	var normalized_id: String = badge_id.strip_edges()
	if normalized_id.is_empty():
		return {}
	var catalog: Dictionary = _load_catalog()
	for badge_variant in Array(catalog.get("badges", [])):
		if typeof(badge_variant) != TYPE_DICTIONARY:
			continue
		var badge: Dictionary = Dictionary(badge_variant)
		if String(badge.get("id", "")) == normalized_id:
			return badge
	return {}


static func _load_catalog() -> Dictionary:
	if not FileAccess.file_exists(RANK_PARTICLE_CATALOG_PATH):
		return {}
	var file := FileAccess.open(RANK_PARTICLE_CATALOG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


static func _string_array(value: Variant) -> PackedStringArray:
	if value is PackedStringArray:
		return value
	var result: PackedStringArray = []
	if value is Array:
		for entry in Array(value):
			var text: String = String(entry).strip_edges().to_lower()
			if not text.is_empty():
				result.append(text)
	return result


static func _string_array_has_fragment(values: PackedStringArray, fragment: String) -> bool:
	for value in values:
		if String(value).contains(fragment):
			return true
	return false


static func _optional_text(value: String, fallback: String) -> String:
	var normalized: String = value.strip_edges()
	return fallback if normalized.is_empty() else normalized
