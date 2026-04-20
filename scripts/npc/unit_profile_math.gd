class_name UnitProfileMath
extends RefCounted

const NOT_APPLICABLE: float = -1.0
const GENERALIST_SPECIALTY: String = "Generalist"
const SECONDARY_SPECIALTY_MIN_SCORE: float = 0.65
const SECONDARY_SPECIALTY_MAX_DISTANCE: float = 0.05
const SPECIALTY_MIN_SCORE: float = 0.55

const ROLE_ALIASES := {
	"field_captain": "section_lead",
	"combat_medic": "security_guard",
	"recon_scout": "atv_recon_scout",
	"breacher": "security_guard",
	"comms_specialist": "section_lead",
	"marksman": "security_guard",
	"combat_engineer": "security_guard",
	"heavy_gunner": "security_guard",
	"drone_handler": "atv_recon_scout",
	"quartermaster": "section_lead",
	"signals_analyst": "section_lead",
	"rover_pilot": "atv_recon_scout",
}

const ROLE_ALLOWED_FUNCTIONS := {
	"atv_recon_scout": ["pathfinder", "scout", "overwatch", "infiltrator"],
	"security_guard": ["sentinel", "overwatch", "scout"],
	"section_lead": ["coordinator", "sentinel", "overwatch", "pathfinder"],
	"dropship_pilot": ["insertion_pilot", "transport_pilot", "escort_pilot"],
	"freighter_pilot": ["cargo_runner", "route_master"],
	"fighter_pilot": ["interceptor", "strike_pilot", "escort_pilot"],
}

const SPECIALTY_NAME_MAP := {
	"pathfinder:watchful": "Roadscouting",
	"pathfinder:silent": "Silent Routefinding",
	"overwatch:silent": "Silent Overwatch",
	"overwatch:steady": "Precision Overwatch",
	"scout:rapid": "Advance Recon",
	"sentinel:steady": "Line Sentinel",
	"coordinator:command": "Field Coordinator",
	"infiltrator:silent": "Silent Infiltration",
	"insertion_pilot:rapid": "Hot Drop Pilot",
	"insertion_pilot:silent": "Low-Signature Drop",
	"transport_pilot:steady": "Stable Lift Pilot",
	"cargo_runner:silent": "Blockade Runner",
	"route_master:watchful": "Route Master",
	"interceptor:rapid": "Interceptor",
	"strike_pilot:steady": "Precision Strike Pilot",
	"escort_pilot:command": "Flight Lead",
}

const BEHAVIOR_LABELS := {
	"initiative": "Initiative",
	"order_fidelity": "Order Fidelity",
	"signature_control": "Signature Control",
	"contact_stability": "Contact Stability",
	"autonomy": "Autonomy",
}

const METHOD_LABELS := {
	"silent": "Silent",
	"rapid": "Rapid",
	"steady": "Steady",
	"watchful": "Watchful",
	"command": "Command",
}

const FUNCTION_LABELS := {
	"pathfinder": "Pathfinder",
	"scout": "Scout",
	"overwatch": "Overwatch",
	"sentinel": "Sentinel",
	"coordinator": "Coordinator",
	"infiltrator": "Infiltrator",
	"insertion_pilot": "Insertion Pilot",
	"transport_pilot": "Transport Pilot",
	"cargo_runner": "Cargo Runner",
	"route_master": "Route Master",
	"interceptor": "Interceptor",
	"strike_pilot": "Strike Pilot",
	"escort_pilot": "Escort Pilot",
}


static func build_character_bundle(data: Dictionary) -> Dictionary:
	var role_id: String = normalize_role_id(String(data.get("role_id", data.get("role_name", "security_guard"))))
	var core_values: Dictionary = _build_core_values(data, role_id)
	var communication_values: Dictionary = _build_communication_values(data, core_values, role_id)
	var platform_values: Dictionary = _build_platform_values(data, core_values, role_id)
	var mobility: float = _compute_mobility(core_values, platform_values, role_id)
	var behavior_axes := {
		"initiative": clampf((float(core_values.get("speed", 0.0)) * 0.40) + (float(core_values.get("awareness", 0.0)) * 0.30) + (float(core_values.get("leadership", 0.0)) * 0.30), 0.0, 1.0),
		"order_fidelity": clampf((float(core_values.get("discipline", 0.0)) * 0.50) + (float(core_values.get("recognition", 0.0)) * 0.30) + (float(communication_values.get("speech_quality", 0.0)) * 0.20), 0.0, 1.0),
		"signature_control": clampf((float(core_values.get("stealth", 0.0)) * 0.45) + (float(core_values.get("discipline", 0.0)) * 0.35) + ((1.0 - float(communication_values.get("speech_quantity", 0.0))) * 0.20), 0.0, 1.0),
		"contact_stability": clampf((float(core_values.get("toughness", 0.0)) * 0.40) + (float(core_values.get("discipline", 0.0)) * 0.35) + (float(core_values.get("awareness", 0.0)) * 0.25), 0.0, 1.0),
		"autonomy": clampf((float(core_values.get("recognition", 0.0)) * 0.35) + (float(core_values.get("leadership", 0.0)) * 0.35) + (float(core_values.get("discipline", 0.0)) * 0.30), 0.0, 1.0),
	}
	var method_scores := {
		"silent": clampf((float(core_values.get("stealth", 0.0)) * 0.40) + (float(core_values.get("discipline", 0.0)) * 0.30) + (float(core_values.get("awareness", 0.0)) * 0.20) + ((1.0 - float(communication_values.get("speech_quantity", 0.0))) * 0.10), 0.0, 1.0),
		"rapid": clampf((float(core_values.get("speed", 0.0)) * 0.45) + (float(core_values.get("awareness", 0.0)) * 0.25) + (float(core_values.get("toughness", 0.0)) * 0.20) + (float(communication_values.get("speech_quality", 0.0)) * 0.10), 0.0, 1.0),
		"steady": clampf((float(core_values.get("discipline", 0.0)) * 0.35) + (float(core_values.get("toughness", 0.0)) * 0.30) + (float(core_values.get("accuracy", 0.0)) * 0.20) + (float(communication_values.get("speech_quality", 0.0)) * 0.15), 0.0, 1.0),
		"watchful": clampf((float(core_values.get("awareness", 0.0)) * 0.40) + (float(core_values.get("recognition", 0.0)) * 0.30) + (float(core_values.get("discipline", 0.0)) * 0.20) + (float(core_values.get("accuracy", 0.0)) * 0.10), 0.0, 1.0),
		"command": clampf((float(core_values.get("leadership", 0.0)) * 0.40) + (float(communication_values.get("speech_quality", 0.0)) * 0.30) + (float(core_values.get("discipline", 0.0)) * 0.20) + (float(core_values.get("recognition", 0.0)) * 0.10), 0.0, 1.0),
	}
	var function_scores: Dictionary = _build_function_scores(role_id, core_values, communication_values, platform_values, mobility)
	var specialty_info: Dictionary = _build_specialties(role_id, method_scores, function_scores)
	var combat_effects: Dictionary = {
		"speed_multiplier": initiative_to_speed_multiplier(float(behavior_axes.get("initiative", 0.0))),
		"hit_modifier": order_fidelity_to_hit_modifier(float(behavior_axes.get("order_fidelity", 0.0))) + autonomy_to_hit_modifier(float(behavior_axes.get("autonomy", 0.0))),
		"evasion_modifier": signature_control_to_evasion_modifier(float(behavior_axes.get("signature_control", 0.0))),
		"damage_taken_multiplier": contact_stability_to_damage_taken_multiplier(float(behavior_axes.get("contact_stability", 0.0))),
	}
	return {
		"role_id": role_id,
		"core_values": core_values,
		"communication_values": communication_values,
		"platform_values": platform_values,
		"behavior_axes": behavior_axes,
		"method_scores": method_scores,
		"function_scores": function_scores,
		"primary_method_tag": _get_top_key(method_scores),
		"secondary_method_tag": _get_secondary_key(method_scores),
		"primary_function": specialty_info.get("primary_function", ""),
		"secondary_function": specialty_info.get("secondary_function", ""),
		"primary_specialty": specialty_info.get("primary_specialty", GENERALIST_SPECIALTY),
		"secondary_specialty": specialty_info.get("secondary_specialty", ""),
		"specialty_score": float(specialty_info.get("specialty_score", 0.0)),
		"combat_effects": combat_effects,
		"combat_effect_summary": _build_combat_effect_summary(combat_effects),
		"method_summary": _build_top_summary(method_scores, METHOD_LABELS, 2),
		"function_summary": _build_top_summary(function_scores, FUNCTION_LABELS, 2),
	}


static func normalize_role_id(value: String) -> String:
	var normalized: String = value.strip_edges().to_lower().replace("-", "_").replace("/", "_").replace(" ", "_")
	if ROLE_ALIASES.has(normalized):
		return String(ROLE_ALIASES.get(normalized, normalized))
	if ROLE_ALLOWED_FUNCTIONS.has(normalized):
		return normalized
	return "security_guard"


static func initiative_to_speed_multiplier(score: float) -> float:
	return clampf(0.85 + (clampf(score, 0.0, 1.0) * 0.30), 0.85, 1.15)


static func order_fidelity_to_hit_modifier(score: float) -> float:
	return (clampf(score, 0.0, 1.0) - 0.50) * 0.18


static func autonomy_to_hit_modifier(score: float) -> float:
	return (clampf(score, 0.0, 1.0) - 0.50) * 0.10


static func signature_control_to_evasion_modifier(score: float) -> float:
	return (clampf(score, 0.0, 1.0) - 0.50) * 0.18


static func contact_stability_to_damage_taken_multiplier(score: float) -> float:
	return clampf(1.0 - ((clampf(score, 0.0, 1.0) - 0.50) * 0.30), 0.85, 1.15)


static func describe_value(score: float) -> String:
	var normalized: float = clampf(score, 0.0, 1.0)
	if normalized <= 0.24:
		return "schwach"
	if normalized <= 0.44:
		return "begrenzt"
	if normalized <= 0.64:
		return "solide"
	if normalized <= 0.84:
		return "stark"
	return "praegend"


static func get_label_for_method(method_id: String) -> String:
	return String(METHOD_LABELS.get(method_id, method_id.capitalize()))


static func get_label_for_function(function_id: String) -> String:
	return String(FUNCTION_LABELS.get(function_id, function_id.capitalize()))


static func _build_core_values(data: Dictionary, role_id: String) -> Dictionary:
	var accuracy: float = _resolve_value(data, "accuracy", float(data.get("skill_accuracy", 0.5)))
	var speed: float = _resolve_value(data, "speed", float(data.get("skill_speed", 0.5)))
	var toughness: float = _resolve_value(data, "toughness", float(data.get("skill_toughness", 0.5)))
	var leadership: float = _resolve_value(data, "leadership", float(data.get("skill_leadership", 0.3)))
	var awareness: float = _resolve_value(data, "awareness", clampf((accuracy * 0.35) + (speed * 0.35) + (leadership * 0.20) + _role_bias(role_id, "awareness"), 0.0, 1.0))
	var recognition: float = _resolve_value(data, "recognition", clampf((accuracy * 0.20) + (leadership * 0.40) + (awareness * 0.25) + _role_bias(role_id, "recognition"), 0.0, 1.0))
	var discipline: float = _resolve_value(data, "discipline", clampf((leadership * 0.35) + (toughness * 0.25) + (recognition * 0.25) + _role_bias(role_id, "discipline") + _trait_bias(data, "discipline"), 0.0, 1.0))
	var stealth: float = _resolve_value(data, "stealth", clampf((speed * 0.35) + (discipline * 0.20) + (awareness * 0.20) + _role_bias(role_id, "stealth") + _trait_bias(data, "stealth"), 0.0, 1.0))
	return {
		"accuracy": accuracy,
		"speed": speed,
		"toughness": toughness,
		"awareness": awareness,
		"recognition": recognition,
		"stealth": stealth,
		"discipline": discipline,
		"leadership": leadership,
	}


static func _build_communication_values(data: Dictionary, core_values: Dictionary, role_id: String) -> Dictionary:
	var speech_quality: float = _resolve_value(data, "speech_quality", clampf((float(core_values.get("leadership", 0.0)) * 0.45) + (float(core_values.get("recognition", 0.0)) * 0.35) + _role_bias(role_id, "speech_quality"), 0.0, 1.0))
	var speech_quantity: float = _resolve_value(data, "speech_quantity", clampf(0.42 + _role_bias(role_id, "speech_quantity") + _trait_bias(data, "speech_quantity"), 0.0, 1.0))
	return {
		"speech_quality": speech_quality,
		"speech_quantity": speech_quantity,
	}


static func _build_platform_values(data: Dictionary, core_values: Dictionary, role_id: String) -> Dictionary:
	var base_ground: float = clampf((float(core_values.get("speed", 0.0)) * 0.35) + (float(core_values.get("recognition", 0.0)) * 0.25) + (float(core_values.get("awareness", 0.0)) * 0.20) + _role_bias(role_id, "ground_vehicle_handling"), 0.0, 1.0)
	return {
		"ground_vehicle_handling": _resolve_platform_value(data, "ground_vehicle_handling", base_ground if role_id == "atv_recon_scout" else NOT_APPLICABLE),
		"dropship_piloting": _resolve_platform_value(data, "dropship_piloting", 0.70 if role_id == "dropship_pilot" else NOT_APPLICABLE),
		"freighter_piloting": _resolve_platform_value(data, "freighter_piloting", 0.70 if role_id == "freighter_pilot" else NOT_APPLICABLE),
		"fighter_piloting": _resolve_platform_value(data, "fighter_piloting", 0.72 if role_id == "fighter_pilot" else NOT_APPLICABLE),
	}


static func _compute_mobility(core_values: Dictionary, platform_values: Dictionary, role_id: String) -> float:
	var speed: float = float(core_values.get("speed", 0.0))
	if role_id == "atv_recon_scout" and float(platform_values.get("ground_vehicle_handling", NOT_APPLICABLE)) >= 0.0:
		return clampf((speed + float(platform_values.get("ground_vehicle_handling", 0.0))) * 0.5, 0.0, 1.0)
	return speed


static func _build_function_scores(role_id: String, core_values: Dictionary, communication_values: Dictionary, platform_values: Dictionary, mobility: float) -> Dictionary:
	var all_scores := {
		"pathfinder": clampf((float(core_values.get("awareness", 0.0)) * 0.30) + (float(core_values.get("recognition", 0.0)) * 0.30) + (mobility * 0.20) + (float(core_values.get("discipline", 0.0)) * 0.20), 0.0, 1.0),
		"scout": clampf((float(core_values.get("awareness", 0.0)) * 0.30) + (float(core_values.get("speed", 0.0)) * 0.25) + (float(core_values.get("stealth", 0.0)) * 0.25) + (float(core_values.get("recognition", 0.0)) * 0.20), 0.0, 1.0),
		"overwatch": clampf((float(core_values.get("accuracy", 0.0)) * 0.35) + (float(core_values.get("awareness", 0.0)) * 0.25) + (float(core_values.get("discipline", 0.0)) * 0.20) + (float(core_values.get("recognition", 0.0)) * 0.20), 0.0, 1.0),
		"sentinel": clampf((float(core_values.get("toughness", 0.0)) * 0.30) + (float(core_values.get("awareness", 0.0)) * 0.25) + (float(core_values.get("discipline", 0.0)) * 0.25) + (float(core_values.get("accuracy", 0.0)) * 0.20), 0.0, 1.0),
		"coordinator": clampf((float(core_values.get("leadership", 0.0)) * 0.35) + (float(communication_values.get("speech_quality", 0.0)) * 0.30) + (float(core_values.get("recognition", 0.0)) * 0.20) + (float(core_values.get("discipline", 0.0)) * 0.15), 0.0, 1.0),
		"infiltrator": clampf((float(core_values.get("stealth", 0.0)) * 0.35) + (float(core_values.get("speed", 0.0)) * 0.25) + (float(core_values.get("awareness", 0.0)) * 0.20) + (float(core_values.get("discipline", 0.0)) * 0.20), 0.0, 1.0),
		"insertion_pilot": clampf((maxf(float(platform_values.get("dropship_piloting", NOT_APPLICABLE)), 0.0) * 0.35) + (float(core_values.get("awareness", 0.0)) * 0.20) + (float(core_values.get("discipline", 0.0)) * 0.20) + (float(core_values.get("recognition", 0.0)) * 0.15) + (float(communication_values.get("speech_quality", 0.0)) * 0.10), 0.0, 1.0),
		"transport_pilot": clampf((maxf(float(platform_values.get("dropship_piloting", NOT_APPLICABLE)), 0.0) * 0.35) + (float(core_values.get("toughness", 0.0)) * 0.25) + (float(core_values.get("recognition", 0.0)) * 0.20) + (float(communication_values.get("speech_quality", 0.0)) * 0.20), 0.0, 1.0),
		"cargo_runner": clampf((maxf(float(platform_values.get("freighter_piloting", NOT_APPLICABLE)), 0.0) * 0.35) + (float(core_values.get("recognition", 0.0)) * 0.25) + (float(core_values.get("discipline", 0.0)) * 0.20) + (float(core_values.get("toughness", 0.0)) * 0.20), 0.0, 1.0),
		"route_master": clampf((maxf(float(platform_values.get("freighter_piloting", NOT_APPLICABLE)), 0.0) * 0.35) + (float(core_values.get("awareness", 0.0)) * 0.25) + (float(core_values.get("recognition", 0.0)) * 0.20) + (float(communication_values.get("speech_quality", 0.0)) * 0.20), 0.0, 1.0),
		"interceptor": clampf((maxf(float(platform_values.get("fighter_piloting", NOT_APPLICABLE)), 0.0) * 0.35) + (float(core_values.get("awareness", 0.0)) * 0.25) + (float(core_values.get("speed", 0.0)) * 0.20) + (float(core_values.get("accuracy", 0.0)) * 0.20), 0.0, 1.0),
		"strike_pilot": clampf((maxf(float(platform_values.get("fighter_piloting", NOT_APPLICABLE)), 0.0) * 0.35) + (float(core_values.get("accuracy", 0.0)) * 0.25) + (float(core_values.get("recognition", 0.0)) * 0.20) + (float(core_values.get("discipline", 0.0)) * 0.20), 0.0, 1.0),
		"escort_pilot": clampf((maxf(_resolve_air_role_value(platform_values, role_id), 0.0) * 0.30) + (float(core_values.get("awareness", 0.0)) * 0.20) + (float(core_values.get("discipline", 0.0)) * 0.20) + (float(core_values.get("leadership", 0.0)) * 0.15) + (float(communication_values.get("speech_quality", 0.0)) * 0.15), 0.0, 1.0),
	}
	var filtered: Dictionary = {}
	for function_id_variant in ROLE_ALLOWED_FUNCTIONS.get(role_id, ["sentinel", "overwatch", "scout"]):
		var function_id: String = String(function_id_variant)
		filtered[function_id] = float(all_scores.get(function_id, 0.0))
	return filtered


static func _build_specialties(role_id: String, method_scores: Dictionary, function_scores: Dictionary) -> Dictionary:
	var best_combo := {
		"score": -1.0,
		"function_id": "",
		"method_id": "",
		"specialty": GENERALIST_SPECIALTY,
	}
	var second_combo := best_combo.duplicate(true)
	for function_id in function_scores.keys():
		for method_id in method_scores.keys():
			var combo_score: float = (float(function_scores.get(function_id, 0.0)) * 0.60) + (float(method_scores.get(method_id, 0.0)) * 0.40)
			var specialty_name: String = String(SPECIALTY_NAME_MAP.get("%s:%s" % [function_id, method_id], "%s %s" % [get_label_for_method(String(method_id)), get_label_for_function(String(function_id))]))
			var candidate := {
				"score": combo_score,
				"function_id": String(function_id),
				"method_id": String(method_id),
				"specialty": specialty_name,
			}
			if combo_score > float(best_combo.get("score", -1.0)):
				second_combo = best_combo.duplicate(true)
				best_combo = candidate
			elif combo_score > float(second_combo.get("score", -1.0)):
				second_combo = candidate
	var primary_specialty: String = GENERALIST_SPECIALTY
	if float(best_combo.get("score", -1.0)) >= SPECIALTY_MIN_SCORE:
		primary_specialty = String(best_combo.get("specialty", GENERALIST_SPECIALTY))
	var secondary_specialty: String = ""
	if float(second_combo.get("score", -1.0)) >= SECONDARY_SPECIALTY_MIN_SCORE and absf(float(best_combo.get("score", -1.0)) - float(second_combo.get("score", -1.0))) <= SECONDARY_SPECIALTY_MAX_DISTANCE and float(best_combo.get("score", -1.0)) >= SECONDARY_SPECIALTY_MIN_SCORE:
		secondary_specialty = String(second_combo.get("specialty", ""))
	return {
		"role_id": role_id,
		"specialty_score": float(best_combo.get("score", 0.0)),
		"primary_function": String(best_combo.get("function_id", "")),
		"secondary_function": String(second_combo.get("function_id", "")),
		"primary_specialty": primary_specialty,
		"secondary_specialty": secondary_specialty,
	}


static func _resolve_value(data: Dictionary, key: String, fallback: float) -> float:
	var raw_value: Variant = data.get(key, null)
	if typeof(raw_value) == TYPE_INT or typeof(raw_value) == TYPE_FLOAT:
		return clampf(float(raw_value), 0.0, 1.0)
	return clampf(fallback, 0.0, 1.0)


static func _resolve_platform_value(data: Dictionary, key: String, fallback: float) -> float:
	var raw_value: Variant = data.get(key, null)
	if typeof(raw_value) == TYPE_INT or typeof(raw_value) == TYPE_FLOAT:
		return clampf(float(raw_value), NOT_APPLICABLE, 1.0)
	return fallback


static func _role_bias(role_id: String, key: String) -> float:
	match role_id:
		"atv_recon_scout":
			match key:
				"awareness":
					return 0.10
				"recognition":
					return 0.08
				"stealth":
					return 0.10
				"discipline":
					return 0.04
				"speech_quantity":
					return -0.10
				"ground_vehicle_handling":
					return 0.20
		"section_lead":
			match key:
				"recognition":
					return 0.08
				"discipline":
					return 0.08
				"speech_quality":
					return 0.10
				"speech_quantity":
					return 0.08
		"security_guard":
			match key:
				"awareness":
					return 0.04
				"discipline":
					return 0.08
				"stealth":
					return -0.02
		"dropship_pilot":
			match key:
				"awareness":
					return 0.06
				"recognition":
					return 0.04
				"discipline":
					return 0.08
				"speech_quality":
					return 0.08
		"freighter_pilot":
			match key:
				"recognition":
					return 0.08
				"discipline":
					return 0.08
		"fighter_pilot":
			match key:
				"awareness":
					return 0.08
				"speech_quantity":
					return 0.04
	return 0.0


static func _trait_bias(data: Dictionary, key: String) -> float:
	var bias: float = 0.0
	for trait_id_variant in data.get("trait_ids", []):
		var trait_id: String = String(trait_id_variant).strip_edges().to_lower()
		match trait_id:
			"calm":
				if key == "discipline" or key == "stealth":
					bias += 0.03
				elif key == "speech_quantity":
					bias -= 0.04
			"steady":
				if key == "discipline":
					bias += 0.04
			"cautious":
				if key == "recognition" or key == "discipline":
					bias += 0.03
				elif key == "speech_quantity":
					bias -= 0.02
			"aggressive":
				if key == "speech_quantity":
					bias += 0.04
				elif key == "stealth":
					bias -= 0.04
			"reckless":
				if key == "speech_quantity":
					bias += 0.06
				elif key == "discipline":
					bias -= 0.06
	return bias


static func _resolve_air_role_value(platform_values: Dictionary, role_id: String) -> float:
	if role_id == "dropship_pilot":
		return float(platform_values.get("dropship_piloting", NOT_APPLICABLE))
	if role_id == "freighter_pilot":
		return float(platform_values.get("freighter_piloting", NOT_APPLICABLE))
	return float(platform_values.get("fighter_piloting", NOT_APPLICABLE))


static func _build_combat_effect_summary(combat_effects: Dictionary) -> String:
	var speed_delta: int = int(round((float(combat_effects.get("speed_multiplier", 1.0)) - 1.0) * 100.0))
	var hit_delta: int = int(round(float(combat_effects.get("hit_modifier", 0.0)) * 100.0))
	var evasion_delta: int = int(round(float(combat_effects.get("evasion_modifier", 0.0)) * 100.0))
	var stability_delta: int = int(round((1.0 - float(combat_effects.get("damage_taken_multiplier", 1.0))) * 100.0))
	return "Move %+d%% | Aim %+d%% | Conceal %+d%% | Stability %+d%%" % [speed_delta, hit_delta, evasion_delta, stability_delta]


static func _build_top_summary(scores: Dictionary, labels: Dictionary, count: int) -> String:
	var ordered_keys: Array = _sort_keys_by_score(scores)
	var parts: PackedStringArray = []
	for index in range(mini(count, ordered_keys.size())):
		var key: String = String(ordered_keys[index])
		parts.append("%s %.2f" % [String(labels.get(key, key.capitalize())), float(scores.get(key, 0.0))])
	return " | ".join(parts)


static func _get_top_key(scores: Dictionary) -> String:
	var ordered_keys: Array = _sort_keys_by_score(scores)
	if ordered_keys.is_empty():
		return ""
	return String(ordered_keys[0])


static func _get_secondary_key(scores: Dictionary) -> String:
	var ordered_keys: Array = _sort_keys_by_score(scores)
	if ordered_keys.size() < 2:
		return ""
	return String(ordered_keys[1])


static func _sort_keys_by_score(scores: Dictionary) -> Array:
	var entries: Array = []
	for key in scores.keys():
		entries.append({"key": key, "score": float(scores.get(key, 0.0))})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if is_equal_approx(float(a.get("score", 0.0)), float(b.get("score", 0.0))):
			return String(a.get("key", "")) < String(b.get("key", ""))
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)
	var ordered_keys: Array = []
	for entry in entries:
		ordered_keys.append(entry.get("key", ""))
	return ordered_keys