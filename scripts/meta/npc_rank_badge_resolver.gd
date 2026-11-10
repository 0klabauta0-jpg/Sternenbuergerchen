class_name NPCRankBadgeResolver
extends RefCounted

const RANK_PARTICLE_CATALOG_PATH: String = "res://data/rank_particle_asset_catalog.json"
const MAX_PRIMARY_BADGES: int = 3
const START_PROFILE_BADGE_CAP: int = 1
const MIN_SCORE: float = 0.52

const BADGE_DEFINITIONS: Dictionary = {
	"medic": {"badge_id": "badge_role_medic", "label": "Sanität", "priority": 10},
	"leader": {"badge_id": "badge_role_ftl", "label": "Führung", "priority": 20},
	"heavy": {"badge_id": "badge_role_heavy", "label": "Schwere Waffen", "priority": 30},
	"pilot": {"badge_id": "badge_role_pilot", "label": "Pilot", "priority": 40},
	"engineer": {"badge_id": "badge_role_engineer", "label": "Technik", "priority": 50},
	"shooter": {"badge_id": "badge_role_rifle", "label": "Schütze", "priority": 60},
	"enemy": {"badge_id": "badge_role_enemy", "label": "Gegner", "priority": 90},
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
	"medic": "Schwelle 0,52. Disziplin, Wahrnehmung, Erkennen, Meldequalität, Befehlstreue, Ruhe im Kontakt und kleiner Sanitätskontext.",
	"leader": "Schwelle 0,52. Führung, Meldequalität, Erkennen, Disziplin, Befehlstreue, Selbstständigkeit und kleiner Führungskontext.",
	"heavy": "Schwelle 0,52. Belastbarkeit, Ruhe im Kontakt, Disziplin, Treffsicherheit, Befehlstreue und schwerer Ausrüstungs-/Rollenkontext.",
	"pilot": "Schwelle 0,52. Bester Fahrzeugwert, Wahrnehmung, Erkennen, Disziplin, Meldequalität, Initiative, Ruhe im Kontakt und Pilotenkontext.",
	"engineer": "Schwelle 0,52. Disziplin, Erkennen, Wahrnehmung, Meldequalität, Befehlstreue, Selbstständigkeit, Ruhe im Kontakt und Technikkontext.",
	"shooter": "Schwelle 0,52. Treffsicherheit, Wahrnehmung, Erkennen, Disziplin, Befehlstreue, Ruhe im Kontakt, Tempo und Waffenkontext.",
	"enemy": "Die Team- oder Fraktionszugehörigkeit kennzeichnet diese Person als Gegner.",
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

	var limit: int = clampi(max_count, 0, MAX_PRIMARY_BADGES)
	if _is_start_profile(data):
		limit = mini(limit, START_PROFILE_BADGE_CAP)
	var result: Array = []
	for index in range(mini(limit, ordered.size())):
		result.append(_hydrate_badge(Dictionary(ordered[index])))
	return result


static func get_badges_for_profile(profile_or_data: Variant, max_count: int = MAX_PRIMARY_BADGES) -> Array:
	var data: Dictionary = _profile_to_dictionary(profile_or_data)
	var existing: Array = Array(data.get("rank_badges", []))
	if not existing.is_empty() and not _has_dynamic_score_source(data):
		var result: Array = []
		var limit: int = clampi(max_count, 0, MAX_PRIMARY_BADGES)
		for index in range(mini(limit, existing.size())):
			if typeof(existing[index]) == TYPE_DICTIONARY:
				result.append(_hydrate_badge(Dictionary(existing[index])))
		return result
	return derive_badges(data, max_count)


static func get_badge_progress_for_profile(profile_or_data: Variant, max_count: int = 0, include_enemy: bool = false) -> Array:
	var data: Dictionary = _profile_to_dictionary(profile_or_data)
	var result: Array = []
	for badge_key_variant in BADGE_DEFINITIONS.keys():
		var badge_key: String = String(badge_key_variant).strip_edges().to_lower()
		if badge_key == "enemy" and not include_enemy and _score_enemy(data) <= 0.0:
			continue
		var score: float = _score_for_badge(badge_key, data)
		var candidate: Dictionary = _build_badge_candidate(badge_key, score, _reason_for(badge_key, data))
		if candidate.is_empty():
			continue
		candidate["achieved"] = score >= MIN_SCORE
		candidate["requirement_text"] = _requirement_for(badge_key, data, score)
		result.append(_hydrate_badge(candidate))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if bool(a.get("achieved", false)) != bool(b.get("achieved", false)):
			return bool(a.get("achieved", false))
		if is_equal_approx(float(a.get("score", 0.0)), float(b.get("score", 0.0))):
			return int(a.get("priority", 999)) < int(b.get("priority", 999))
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)
	_apply_start_profile_badge_cap(result, data)
	if max_count <= 0 or result.size() <= max_count:
		return result
	return result.slice(0, max_count)


static func get_next_badge_requirements(profile_or_data: Variant, max_count: int = MAX_PRIMARY_BADGES) -> Array:
	var result: Array = []
	for candidate_variant in get_badge_progress_for_profile(profile_or_data):
		if typeof(candidate_variant) != TYPE_DICTIONARY:
			continue
		var candidate: Dictionary = Dictionary(candidate_variant)
		if bool(candidate.get("achieved", false)):
			continue
		result.append(candidate)
		if result.size() >= max_count:
			break
	return result


static func get_badge_help_id(badge_key: String) -> String:
	var normalized_key: String = badge_key.strip_edges().to_lower()
	return String(BADGE_HELP_IDS.get(normalized_key, "character_sheet.rank_badges"))


static func format_badge_tooltip(badge: Dictionary) -> String:
	var label: String = String(badge.get("label", "Badge")).strip_edges()
	var reason: String = String(badge.get("reason", "")).strip_edges()
	var detail: String = String(badge.get("detail_text", badge.get("formula_text", ""))).strip_edges()
	var requirement: String = String(badge.get("requirement_text", "")).strip_edges()
	var score_text: String = "Eignung %.2f" % float(badge.get("score", 0.0))
	var lines: PackedStringArray = PackedStringArray()
	lines.append("%s: %s" % [_optional_text(label, "Badge"), score_text])
	if not reason.is_empty():
		lines.append(_vertical_factors(reason))
	if not requirement.is_empty() and requirement != reason:
		lines.append(requirement)
	if not detail.is_empty():
		lines.append(_vertical_factors(detail))
	return "\n".join(lines)


static func _vertical_factors(value:String)->String:
	# Generated factor prose only; decimal commas do not contain a space.
	var separators:=RegEx.new()
	separators.compile(", (?=[A-Za-zÄÖÜäöü])| und (?=[A-Za-zÄÖÜäöü])")
	return separators.sub(value.replace(": ",":\n"),"\n",true)


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
	var candidate: Dictionary = _build_badge_candidate(badge_key, score, reason)
	if candidate.is_empty():
		return
	candidates[badge_key] = candidate


static func _build_badge_candidate(badge_key: String, score: float, reason: String) -> Dictionary:
	var definition: Dictionary = Dictionary(BADGE_DEFINITIONS.get(badge_key, {}))
	if definition.is_empty():
		return {}
	return {
		"badge_key": badge_key,
		"badge_id": String(definition.get("badge_id", "")),
		"label": String(definition.get("label", badge_key.capitalize())),
		"score": clampf(score, 0.0, 1.0),
		"priority": int(definition.get("priority", 999)),
		"reason": reason,
		"help_id": get_badge_help_id(badge_key),
		"detail_text": String(BADGE_FORMULAS.get(badge_key, "")),
	}


static func _score_for_badge(badge_key: String, data: Dictionary) -> float:
	match badge_key:
		"medic":
			return _score_medic(data)
		"leader":
			return _score_leader(data)
		"heavy":
			return _score_heavy(data)
		"pilot":
			return _score_pilot(data)
		"engineer":
			return _score_engineer(data)
		"shooter":
			return _score_shooter(data)
		"enemy":
			return _score_enemy(data)
		_:
			return 0.0


static func _apply_start_profile_badge_cap(result: Array, data: Dictionary) -> void:
	if not _is_start_profile(data):
		return
	var achieved_count: int = 0
	for index in range(result.size()):
		if typeof(result[index]) != TYPE_DICTIONARY:
			continue
		var badge: Dictionary = Dictionary(result[index])
		if not bool(badge.get("achieved", false)):
			continue
		achieved_count += 1
		if achieved_count <= START_PROFILE_BADGE_CAP:
			continue
		badge["achieved"] = false
		badge["requirement_text"] = "Startbegrenzung: Zu Beginn ist nur die stärkste Eignung aktiv; weitere brauchen klareren Fokus oder Entwicklung."
		badge["reason"] = "%s: Eignung %.2f; wegen der Startbegrenzung noch offen." % [String(badge.get("label", "Badge")), float(badge.get("score", 0.0))]
		result[index] = _hydrate_badge(badge)


static func _requirement_for(badge_key: String, data: Dictionary, score: float) -> String:
	if score >= MIN_SCORE:
		return "Erreicht: %s" % _reason_for(badge_key, data)
	match badge_key:
		"leader":
			return "Nötig: Eignung %.2f/%.2f; Führung %.2f, Meldequalität %.2f, Befehlstreue %.2f, Selbstständigkeit %.2f." % [score, MIN_SCORE, _score_value(data, "leadership"), _communication_value(data, "speech_quality"), _behavior_value(data, "order_fidelity"), _behavior_value(data, "autonomy")]
		"pilot":
			return "Nötig: Eignung %.2f/%.2f; Fahrzeugwert %.2f, Wahrnehmung %.2f, Disziplin %.2f, Meldequalität %.2f." % [score, MIN_SCORE, _best_platform_value(data), _score_value(data, "awareness"), _score_value(data, "discipline"), _communication_value(data, "speech_quality")]
		"shooter":
			return "Nötig: Eignung %.2f/%.2f; Treffsicherheit %.2f, Wahrnehmung %.2f, Erkennen %.2f, Befehlstreue %.2f." % [score, MIN_SCORE, _score_value(data, "accuracy"), _score_value(data, "awareness"), _score_value(data, "recognition"), _behavior_value(data, "order_fidelity")]
		"medic":
			return "Nötig: Eignung %.2f/%.2f; Disziplin %.2f, Erkennen %.2f, Meldequalität %.2f, Ruhe im Kontakt %.2f." % [score, MIN_SCORE, _score_value(data, "discipline"), _score_value(data, "recognition"), _communication_value(data, "speech_quality"), _behavior_value(data, "contact_stability")]
		"heavy":
			return "Nötig: Eignung %.2f/%.2f; Belastbarkeit %.2f, Ruhe im Kontakt %.2f, Treffsicherheit %.2f, Disziplin %.2f." % [score, MIN_SCORE, _score_value(data, "toughness"), _behavior_value(data, "contact_stability"), _score_value(data, "accuracy"), _score_value(data, "discipline")]
		"engineer":
			return "Nötig: Eignung %.2f/%.2f; Erkennen %.2f, Disziplin %.2f, Wahrnehmung %.2f, Befehlstreue %.2f." % [score, MIN_SCORE, _score_value(data, "recognition"), _score_value(data, "discipline"), _score_value(data, "awareness"), _behavior_value(data, "order_fidelity")]
		"enemy":
			return "Nötig: Gegnerzugehörigkeit."
		_:
			return "Nötig: passende Rollen, Eigenschaften oder Werte."


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
	var score: float = clampf(
		(_score_value(data, "discipline") * 0.20)
		+ (_score_value(data, "awareness") * 0.15)
		+ (_score_value(data, "recognition") * 0.15)
		+ (_communication_value(data, "speech_quality") * 0.20)
		+ (_behavior_value(data, "contact_stability") * 0.15)
		+ (_behavior_value(data, "order_fidelity") * 0.15),
		0.0,
		1.0
	)
	if role_text.contains("medic") or role_text.contains("sanitaet") or role_text.contains("heal"):
		score += 0.10
	if weapons.has("medictool"):
		score += 0.14
	if _string_array_has_fragment(_string_array(data.get("trait_ids", [])), "medic"):
		score += 0.10
	return clampf(score, 0.0, 1.0)


static func _score_leader(data: Dictionary) -> float:
	var role_text: String = _role_text(data)
	var score: float = clampf(
		(_score_value(data, "leadership") * 0.40)
		+ (_communication_value(data, "speech_quality") * 0.22)
		+ (_score_value(data, "recognition") * 0.10)
		+ (_score_value(data, "discipline") * 0.08)
		+ (_behavior_value(data, "order_fidelity") * 0.08)
		+ (_behavior_value(data, "autonomy") * 0.12),
		0.0,
		1.0
	)
	if bool(data.get("is_fireteam_lead", false)):
		score += 0.12
	if role_text.contains("lead") or role_text.contains("leader") or role_text.contains("captain") or role_text.contains("commander"):
		score += 0.08
	return clampf(score, 0.0, 1.0)


static func _score_heavy(data: Dictionary) -> float:
	var role_text: String = _role_text(data)
	var weapons: PackedStringArray = _weapon_ids(data)
	var score: float = clampf(
		(_score_value(data, "toughness") * 0.28)
		+ (_behavior_value(data, "contact_stability") * 0.22)
		+ (_score_value(data, "discipline") * 0.14)
		+ (_score_value(data, "accuracy") * 0.14)
		+ (_behavior_value(data, "order_fidelity") * 0.10)
		+ (_behavior_value(data, "autonomy") * 0.06)
		+ (_communication_value(data, "speech_quality") * 0.06),
		0.0,
		1.0
	)
	for weapon_id in weapons:
		if HEAVY_WEAPONS.has(weapon_id):
			score += 0.24
	if role_text.contains("heavy") or role_text.contains("support"):
		score += 0.10
	if String(data.get("armor_id", data.get("armor", ""))).strip_edges().to_lower() == "heavy":
		score += 0.06
	return clampf(score, 0.0, 1.0)


static func _score_pilot(data: Dictionary) -> float:
	return float(_pilot_score_breakdown(data).score)


## Read-only explanation from the same factors used by the live badge score.
## A suitability score does not assign a pilot or explain a person's career.
static func get_pilot_score_breakdown(profile_or_data: Variant) -> Dictionary:
	return _pilot_score_breakdown(_profile_to_dictionary(profile_or_data))


static func _pilot_score_breakdown(data: Dictionary) -> Dictionary:
	var factors: Array = [
		{"value_key": "best_platform", "value": _best_platform_value(data), "weight": 0.35},
		{"value_key": "awareness", "value": _score_value(data, "awareness"), "weight": 0.14},
		{"value_key": "recognition", "value": _score_value(data, "recognition"), "weight": 0.12},
		{"value_key": "discipline", "value": _score_value(data, "discipline"), "weight": 0.12},
		{"value_key": "speech_quality", "value": _communication_value(data, "speech_quality"), "weight": 0.12},
		{"value_key": "contact_stability", "value": _behavior_value(data, "contact_stability"), "weight": 0.08},
		{"value_key": "initiative", "value": _behavior_value(data, "initiative"), "weight": 0.07},
	]
	var sum: float = 0.0
	for factor: Dictionary in factors:
		factor["contribution"] = float(factor.value) * float(factor.weight)
		sum += float(factor.contribution)
	var role_bonus: float = 0.08 if _role_text(data).contains("pilot") else 0.0
	return {"score": clampf(clampf(sum, 0.0, 1.0) + role_bonus, 0.0, 1.0), "threshold": MIN_SCORE, "factors": factors, "role_bonus": role_bonus}


static func _score_engineer(data: Dictionary) -> float:
	var role_text: String = _role_text(data)
	var function_scores: Dictionary = Dictionary(data.get("function_scores", {}))
	var score: float = clampf(
		(_score_value(data, "discipline") * 0.20)
		+ (_score_value(data, "recognition") * 0.18)
		+ (_score_value(data, "awareness") * 0.15)
		+ (_communication_value(data, "speech_quality") * 0.12)
		+ (_behavior_value(data, "order_fidelity") * 0.15)
		+ (_behavior_value(data, "autonomy") * 0.10)
		+ (_behavior_value(data, "contact_stability") * 0.10),
		0.0,
		1.0
	)
	if role_text.contains("engineer") or role_text.contains("tech") or role_text.contains("repair"):
		score += 0.20
	if float(function_scores.get("engineer", 0.0)) >= 0.60:
		score += 0.12
	if _string_array_has_fragment(_string_array(data.get("trait_ids", [])), "engineer"):
		score += 0.12
	return clampf(score, 0.0, 1.0)


static func _score_shooter(data: Dictionary) -> float:
	var role_text: String = _role_text(data)
	var weapons: PackedStringArray = _weapon_ids(data)
	var score: float = clampf(
		(_score_value(data, "accuracy") * 0.34)
		+ (_score_value(data, "awareness") * 0.18)
		+ (_score_value(data, "recognition") * 0.14)
		+ (_score_value(data, "discipline") * 0.12)
		+ (_behavior_value(data, "order_fidelity") * 0.10)
		+ (_behavior_value(data, "contact_stability") * 0.06)
		+ (_score_value(data, "speed") * 0.06),
		0.0,
		1.0
	)
	for weapon_id in weapons:
		if SHOOTER_WEAPONS.has(weapon_id):
			score += 0.18
			if weapon_id == "sniper":
				score += 0.04
	if role_text.contains("rifle") or role_text.contains("shooter") or role_text.contains("marksman") or role_text.contains("overwatch"):
		score += 0.12
	return clampf(score, 0.0, 1.0)


static func _score_enemy(data: Dictionary) -> float:
	var team_id: String = String(data.get("team_id", "")).strip_edges().to_lower()
	if team_id == "team_bravo" or team_id == "enemy":
		return 0.72
	return 0.0


static func _reason_for(badge_key: String, data: Dictionary) -> String:
	match badge_key:
		"medic":
			return "Sanitätseignung: Disziplin %.2f, Erkennen %.2f, Meldequalität %.2f und Ruhe im Kontakt %.2f." % [_score_value(data, "discipline"), _score_value(data, "recognition"), _communication_value(data, "speech_quality"), _behavior_value(data, "contact_stability")]
		"leader":
			return "Führungseignung: Führung %.2f, Meldequalität %.2f, Befehlstreue %.2f und Selbstständigkeit %.2f." % [_score_value(data, "leadership"), _communication_value(data, "speech_quality"), _behavior_value(data, "order_fidelity"), _behavior_value(data, "autonomy")]
		"heavy":
			return "Eignung für schwere Waffen: Belastbarkeit %.2f, Ruhe im Kontakt %.2f, Treffsicherheit %.2f und Disziplin %.2f." % [_score_value(data, "toughness"), _behavior_value(data, "contact_stability"), _score_value(data, "accuracy"), _score_value(data, "discipline")]
		"pilot":
			return "Piloteneignung: bester Fahrzeugwert %.2f, Wahrnehmung %.2f, Disziplin %.2f und Meldequalität %.2f." % [_best_platform_value(data), _score_value(data, "awareness"), _score_value(data, "discipline"), _communication_value(data, "speech_quality")]
		"engineer":
			return "Technikeignung: Erkennen %.2f, Disziplin %.2f, Wahrnehmung %.2f und Befehlstreue %.2f." % [_score_value(data, "recognition"), _score_value(data, "discipline"), _score_value(data, "awareness"), _behavior_value(data, "order_fidelity")]
		"shooter":
			return "Schützeneignung: Treffsicherheit %.2f, Wahrnehmung %.2f, Erkennen %.2f und Befehlstreue %.2f." % [_score_value(data, "accuracy"), _score_value(data, "awareness"), _score_value(data, "recognition"), _behavior_value(data, "order_fidelity")]
		"enemy":
			return "Gegnerkennzeichnung aus Team- oder Fraktionszugehörigkeit."
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


static func _communication_value(data: Dictionary, key: String) -> float:
	var communication_values: Dictionary = Dictionary(data.get("communication_values", {}))
	return clampf(float(communication_values.get(key, data.get(key, 0.0))), 0.0, 1.0)


static func _behavior_value(data: Dictionary, key: String) -> float:
	var behavior_axes: Dictionary = Dictionary(data.get("behavior_axes", {}))
	return clampf(float(behavior_axes.get(key, data.get(key, 0.0))), 0.0, 1.0)


static func _best_platform_value(data: Dictionary) -> float:
	var platform_values: Dictionary = Dictionary(data.get("platform_values", {}))
	var best_platform: float = -1.0
	for key in PILOT_KEYS:
		best_platform = maxf(best_platform, float(platform_values.get(key, data.get(key, -1.0))))
	return maxf(best_platform, 0.0)


static func _has_dynamic_score_source(data: Dictionary) -> bool:
	for key in ["skill_values", "core_values", "communication_values", "platform_values", "behavior_axes", "function_scores"]:
		if data.has(key) and typeof(data.get(key)) == TYPE_DICTIONARY and not Dictionary(data.get(key)).is_empty():
			return true
	for key in ["skill_accuracy", "skill_speed", "skill_leadership", "skill_toughness", "accuracy", "speed", "leadership", "toughness", "dropship_piloting", "freighter_piloting", "fighter_piloting"]:
		if data.has(key):
			return true
	return false


static func _is_start_profile(data: Dictionary) -> bool:
	if not data.has("roster_seed_index"):
		return false
	if int(data.get("roster_seed_index", -1)) < 0:
		return false
	var progression: Dictionary = Dictionary(data.get("progression", {}))
	var xp: int = int(progression.get("xp", progression.get("experience", data.get("xp", 0))))
	var missions_completed: int = int(progression.get("missions_completed", progression.get("mission_count", data.get("missions_completed", 0))))
	return xp <= 0 and missions_completed <= 0


static func _badge_compact_lines(badge: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	var label: String = String(badge.get("label", "Badge")).strip_edges()
	lines.append("%s: Eignung %.2f." % [_optional_text(label, "Badge"), float(badge.get("score", 0.0))])
	var reason: String = String(badge.get("reason", "")).strip_edges()
	if not reason.is_empty():
		lines.append(_vertical_factors(reason))
	var requirement: String = String(badge.get("requirement_text", "")).strip_edges()
	if not requirement.is_empty() and requirement != reason:
		lines.append(requirement)
	return lines


static func _badge_detail_lines(badge: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	var detail: String = String(badge.get("detail_text", badge.get("formula_text", ""))).strip_edges()
	if not detail.is_empty():
		lines.append(_vertical_factors(detail))
	var requirement: String = String(badge.get("requirement_text", "")).strip_edges()
	if not requirement.is_empty():
		lines.append(requirement)
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
