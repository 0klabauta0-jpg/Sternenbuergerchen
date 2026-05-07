class_name RosterRelationshipModel
extends RefCounted

const MIN_AFFINITY: float = -1.0
const MAX_AFFINITY: float = 1.0
const RELATIONSHIP_TAGS: PackedStringArray = [
	"friend",
	"rival",
	"trusts",
	"avoids",
	"mentor",
	"tension",
]


static func make_pair(source_unit_id: String, target_unit_id: String, affinity: float, tags: Variant = [], reason: String = "", symmetric: bool = true) -> Dictionary:
	return {
		"source_unit_id": normalize_unit_id(source_unit_id),
		"target_unit_id": normalize_unit_id(target_unit_id),
		"affinity": normalize_affinity(affinity),
		"affinity_score": int(round(normalize_affinity(affinity) * 100.0)),
		"tags": _normalize_tags(tags),
		"reason": reason.strip_edges(),
		"symmetric": symmetric,
	}


static func build_deterministic_start_relationships(units: Array, seed: String) -> Array:
	var normalized_units: Array = _normalize_unit_array(units)
	var relationships: Array = []
	if normalized_units.size() < 2:
		return relationships

	var rng := RandomNumberGenerator.new()
	rng.seed = _seed_to_int("relationships:%s:%d" % [seed, normalized_units.size()])
	var seen_pair_keys: Dictionary = {}
	var groups: Dictionary = _group_units_by_fireteam(normalized_units)
	var fireteam_ids: Array = groups.keys()
	fireteam_ids.sort()

	for fireteam_id_variant in fireteam_ids:
		var fireteam_units: Array = Array(groups.get(fireteam_id_variant, []))
		if fireteam_units.size() < 2:
			continue
		for index in range(fireteam_units.size() - 1):
			if index % 2 != 0 and rng.randf() > 0.65:
				continue
			var source: Dictionary = Dictionary(fireteam_units[index])
			var target: Dictionary = Dictionary(fireteam_units[index + 1])
			_add_pair_if_new(
				relationships,
				seen_pair_keys,
				source,
				target,
				rng.randf_range(0.16, 0.34),
				["trusts", "friend"] if rng.randf() > 0.45 else ["trusts"],
				"start_roster_same_fireteam"
			)
		var leader: Dictionary = _pick_group_leader(fireteam_units)
		for member_variant in fireteam_units:
			var member: Dictionary = Dictionary(member_variant)
			if normalize_unit_id(String(member.get("unit_id", ""))) == normalize_unit_id(String(leader.get("unit_id", ""))):
				continue
			if rng.randf() > 0.45:
				continue
			_add_pair_if_new(
				relationships,
				seen_pair_keys,
				leader,
				member,
				rng.randf_range(0.10, 0.24),
				["mentor", "trusts"],
				"start_roster_leadership_routine"
			)

	var tension_stride: int = 5
	for index in range(0, normalized_units.size(), tension_stride):
		var source_index: int = index
		var target_index: int = (index + 3) % normalized_units.size()
		if source_index == target_index:
			continue
		var source: Dictionary = Dictionary(normalized_units[source_index])
		var target: Dictionary = Dictionary(normalized_units[target_index])
		if String(source.get("fireteam_id", "")) == String(target.get("fireteam_id", "")) and normalized_units.size() > 6:
			target = Dictionary(normalized_units[(target_index + 2) % normalized_units.size()])
		_add_pair_if_new(
			relationships,
			seen_pair_keys,
			source,
			target,
			-rng.randf_range(0.10, 0.24),
			["tension"] if rng.randf() > 0.35 else ["rival", "tension"],
			"start_roster_personality_friction"
		)

	return relationships


static func apply_relationships_to_units(units: Array, relationship_pairs: Array, clear_existing: bool = true) -> Array:
	var ordered_unit_ids: PackedStringArray = PackedStringArray()
	var units_by_id: Dictionary = {}
	var display_names_by_id: Dictionary = {}
	for unit_variant in units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(unit_variant).duplicate(true)
		var unit_id: String = normalize_unit_id(String(unit.get("unit_id", "")))
		if unit_id.is_empty():
			continue
		if clear_existing:
			unit["relationship_links"] = []
		else:
			unit["relationship_links"] = normalize_links_for_unit(unit)
		ordered_unit_ids.append(unit_id)
		units_by_id[unit_id] = unit
		display_names_by_id[unit_id] = String(unit.get("display_name", unit_id)).strip_edges()

	for pair_variant in relationship_pairs:
		if typeof(pair_variant) != TYPE_DICTIONARY:
			continue
		var pair: Dictionary = Dictionary(pair_variant)
		var source_id: String = normalize_unit_id(String(pair.get("source_unit_id", "")))
		var target_id: String = normalize_unit_id(String(pair.get("target_unit_id", "")))
		if source_id.is_empty() or target_id.is_empty() or source_id == target_id:
			continue
		if not units_by_id.has(source_id) or not units_by_id.has(target_id):
			continue
		_append_link_to_unit(units_by_id, source_id, target_id, String(display_names_by_id.get(target_id, target_id)), pair)
		if bool(pair.get("symmetric", true)):
			_append_link_to_unit(units_by_id, target_id, source_id, String(display_names_by_id.get(source_id, source_id)), pair)

	var result: Array = []
	for unit_id in ordered_unit_ids:
		var unit: Dictionary = Dictionary(units_by_id.get(unit_id, {})).duplicate(true)
		var links: Array = normalize_links_for_unit(unit)
		unit["relationship_links"] = links
		if not links.is_empty():
			unit["relationship_summary_text"] = build_unit_relationship_summary_text(unit)
		result.append(unit)
	return result


static func normalize_links_for_unit(unit_data: Dictionary) -> Array:
	var links: Array = []
	var seen_targets: Dictionary = {}
	for link_variant in Array(unit_data.get("relationship_links", [])):
		if typeof(link_variant) != TYPE_DICTIONARY:
			continue
		var normalized_link: Dictionary = normalize_link(Dictionary(link_variant))
		var target_unit_id: String = String(normalized_link.get("target_unit_id", "")).strip_edges()
		if target_unit_id.is_empty() or target_unit_id == normalize_unit_id(String(unit_data.get("unit_id", ""))):
			continue
		if seen_targets.has(target_unit_id):
			continue
		seen_targets[target_unit_id] = true
		links.append(normalized_link)
	links.sort_custom(func(a, b):
		return absf(float(Dictionary(a).get("affinity", 0.0))) > absf(float(Dictionary(b).get("affinity", 0.0)))
	)
	return links


static func normalize_link(link: Dictionary) -> Dictionary:
	var target_unit_id: String = normalize_unit_id(String(link.get("target_unit_id", link.get("unit_id", ""))))
	var affinity: float = normalize_affinity(float(link.get("affinity", link.get("affinity_score", 0.0))))
	return {
		"target_unit_id": target_unit_id,
		"target_name": String(link.get("target_name", target_unit_id)).strip_edges(),
		"affinity": affinity,
		"affinity_score": int(round(affinity * 100.0)),
		"tags": _normalize_tags(link.get("tags", [])),
		"reason": String(link.get("reason", "")).strip_edges(),
	}


static func normalize_affinity(value: float) -> float:
	var normalized: float = value
	if absf(normalized) > 1.0:
		normalized /= 100.0
	return clampf(normalized, MIN_AFFINITY, MAX_AFFINITY)


static func get_affinity_between(units: Array, source_unit_id: String, target_unit_id: String, symmetric_fallback: bool = true) -> Dictionary:
	var source_id: String = normalize_unit_id(source_unit_id)
	var target_id: String = normalize_unit_id(target_unit_id)
	if source_id.is_empty() or target_id.is_empty() or source_id == target_id:
		return {"known": false, "affinity": 0.0, "tags": PackedStringArray()}
	var units_by_id: Dictionary = _build_units_by_id(units)
	var source_link: Dictionary = _find_link(Dictionary(units_by_id.get(source_id, {})), target_id)
	if not source_link.is_empty():
		return {
			"known": true,
			"affinity": float(source_link.get("affinity", 0.0)),
			"tags": PackedStringArray(source_link.get("tags", PackedStringArray())),
			"source": "source",
		}
	if not symmetric_fallback:
		return {"known": false, "affinity": 0.0, "tags": PackedStringArray()}
	var reverse_link: Dictionary = _find_link(Dictionary(units_by_id.get(target_id, {})), source_id)
	if reverse_link.is_empty():
		return {"known": false, "affinity": 0.0, "tags": PackedStringArray()}
	return {
		"known": true,
		"affinity": float(reverse_link.get("affinity", 0.0)),
		"tags": PackedStringArray(reverse_link.get("tags", PackedStringArray())),
		"source": "reverse",
	}


static func summarize_unit_relationships(unit_data: Dictionary) -> Dictionary:
	var links: Array = normalize_links_for_unit(unit_data)
	var best_link: Dictionary = {}
	var worst_link: Dictionary = {}
	for link_variant in links:
		var link: Dictionary = Dictionary(link_variant)
		var affinity: float = float(link.get("affinity", 0.0))
		if affinity > 0.0 and (best_link.is_empty() or affinity > float(best_link.get("affinity", -1.0))):
			best_link = link.duplicate(true)
		if affinity < 0.0 and (worst_link.is_empty() or affinity < float(worst_link.get("affinity", 1.0))):
			worst_link = link.duplicate(true)
	return {
		"relationship_count": links.size(),
		"best_link": best_link,
		"worst_link": worst_link,
		"summary_text": build_unit_relationship_summary_text(unit_data),
	}


static func build_unit_relationship_summary_text(unit_data: Dictionary) -> String:
	var summary: Dictionary = summarize_unit_relationships_without_text(unit_data)
	var best_link: Dictionary = Dictionary(summary.get("best_link", {}))
	var worst_link: Dictionary = Dictionary(summary.get("worst_link", {}))
	if best_link.is_empty() and worst_link.is_empty():
		return "Teamfit noch offen."
	var parts: PackedStringArray = PackedStringArray()
	if not best_link.is_empty():
		parts.append("Best %s %+.2f" % [_link_target_name(best_link), float(best_link.get("affinity", 0.0))])
	if not worst_link.is_empty():
		parts.append("Tension %s %+.2f" % [_link_target_name(worst_link), float(worst_link.get("affinity", 0.0))])
	return " | ".join(parts)


static func summarize_unit_relationships_without_text(unit_data: Dictionary) -> Dictionary:
	var links: Array = normalize_links_for_unit(unit_data)
	var best_link: Dictionary = {}
	var worst_link: Dictionary = {}
	for link_variant in links:
		var link: Dictionary = Dictionary(link_variant)
		var affinity: float = float(link.get("affinity", 0.0))
		if affinity > 0.0 and (best_link.is_empty() or affinity > float(best_link.get("affinity", -1.0))):
			best_link = link.duplicate(true)
		if affinity < 0.0 and (worst_link.is_empty() or affinity < float(worst_link.get("affinity", 1.0))):
			worst_link = link.duplicate(true)
	return {
		"relationship_count": links.size(),
		"best_link": best_link,
		"worst_link": worst_link,
	}


static func validate_roster_relationships(units: Array, relationship_pairs: Array = []) -> Dictionary:
	var errors: PackedStringArray = PackedStringArray()
	var warnings: PackedStringArray = PackedStringArray()
	var known_unit_ids: Dictionary = {}
	for unit_variant in units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit_id: String = normalize_unit_id(String(Dictionary(unit_variant).get("unit_id", "")))
		if not unit_id.is_empty():
			known_unit_ids[unit_id] = true
	for unit_variant in units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(unit_variant)
		var unit_id: String = normalize_unit_id(String(unit.get("unit_id", "")))
		for link_variant in Array(unit.get("relationship_links", [])):
			if typeof(link_variant) != TYPE_DICTIONARY:
				errors.append("relationship_link_not_dictionary:%s" % unit_id)
				continue
			var link: Dictionary = normalize_link(Dictionary(link_variant))
			var target_unit_id: String = String(link.get("target_unit_id", ""))
			if target_unit_id.is_empty():
				errors.append("relationship_target_missing:%s" % unit_id)
			elif target_unit_id == unit_id:
				errors.append("relationship_self_link:%s" % unit_id)
			elif not known_unit_ids.has(target_unit_id):
				errors.append("relationship_unknown_target:%s:%s" % [unit_id, target_unit_id])
			var raw_affinity: float = float(Dictionary(link_variant).get("affinity", Dictionary(link_variant).get("affinity_score", 0.0)))
			if absf(raw_affinity) > 100.0:
				errors.append("relationship_affinity_out_of_range:%s:%s" % [unit_id, target_unit_id])
			var tags: PackedStringArray = PackedStringArray(link.get("tags", PackedStringArray()))
			if tags.is_empty():
				warnings.append("relationship_tags_empty:%s:%s" % [unit_id, target_unit_id])
	for pair_variant in relationship_pairs:
		if typeof(pair_variant) != TYPE_DICTIONARY:
			errors.append("relationship_pair_not_dictionary")
			continue
		var pair: Dictionary = Dictionary(pair_variant)
		var source_id: String = normalize_unit_id(String(pair.get("source_unit_id", "")))
		var target_id: String = normalize_unit_id(String(pair.get("target_unit_id", "")))
		if source_id.is_empty() or not known_unit_ids.has(source_id):
			errors.append("relationship_pair_unknown_source:%s" % source_id)
		if target_id.is_empty() or not known_unit_ids.has(target_id):
			errors.append("relationship_pair_unknown_target:%s" % target_id)
		if source_id == target_id:
			errors.append("relationship_pair_self_link:%s" % source_id)
	return {
		"valid": errors.is_empty(),
		"errors": errors,
		"warnings": warnings,
	}


static func normalize_unit_id(unit_id: String) -> String:
	return unit_id.strip_edges().to_lower()


static func _append_link_to_unit(units_by_id: Dictionary, source_id: String, target_id: String, target_name: String, pair: Dictionary) -> void:
	var unit: Dictionary = Dictionary(units_by_id.get(source_id, {})).duplicate(true)
	if unit.is_empty():
		return
	var links: Array = Array(unit.get("relationship_links", [])).duplicate(true)
	var link: Dictionary = normalize_link(
		{
			"target_unit_id": target_id,
			"target_name": target_name,
			"affinity": float(pair.get("affinity", 0.0)),
			"tags": pair.get("tags", []),
			"reason": String(pair.get("reason", "")),
		}
	)
	var replaced: bool = false
	for index in range(links.size()):
		if typeof(links[index]) != TYPE_DICTIONARY:
			continue
		if String(Dictionary(links[index]).get("target_unit_id", "")).strip_edges().to_lower() != target_id:
			continue
		links[index] = link
		replaced = true
		break
	if not replaced:
		links.append(link)
	unit["relationship_links"] = links
	units_by_id[source_id] = unit


static func _find_link(unit_data: Dictionary, target_unit_id: String) -> Dictionary:
	if unit_data.is_empty():
		return {}
	var normalized_target_id: String = normalize_unit_id(target_unit_id)
	for link_variant in normalize_links_for_unit(unit_data):
		var link: Dictionary = Dictionary(link_variant)
		if normalize_unit_id(String(link.get("target_unit_id", ""))) == normalized_target_id:
			return link
	return {}


static func _build_units_by_id(units: Array) -> Dictionary:
	var result: Dictionary = {}
	for unit_variant in units:
		var unit: Dictionary = _unit_to_dict(unit_variant)
		var unit_id: String = normalize_unit_id(String(unit.get("unit_id", "")))
		if not unit_id.is_empty():
			result[unit_id] = unit
	return result


static func _normalize_unit_array(units: Array) -> Array:
	var result: Array = []
	for unit_variant in units:
		var unit: Dictionary = _unit_to_dict(unit_variant)
		if normalize_unit_id(String(unit.get("unit_id", ""))).is_empty():
			continue
		result.append(unit)
	return result


static func _unit_to_dict(unit_variant: Variant) -> Dictionary:
	if typeof(unit_variant) == TYPE_DICTIONARY:
		return Dictionary(unit_variant).duplicate(true)
	if unit_variant != null and unit_variant.has_method("to_dict"):
		return Dictionary(unit_variant.call("to_dict")).duplicate(true)
	return {}


static func _group_units_by_fireteam(units: Array) -> Dictionary:
	var groups: Dictionary = {}
	for unit_variant in units:
		var unit: Dictionary = Dictionary(unit_variant)
		var fireteam_id: String = String(unit.get("fireteam_id", "")).strip_edges().to_lower()
		if fireteam_id.is_empty():
			fireteam_id = "unassigned"
		var group: Array = Array(groups.get(fireteam_id, []))
		group.append(unit)
		groups[fireteam_id] = group
	return groups


static func _pick_group_leader(units: Array) -> Dictionary:
	var best_unit: Dictionary = Dictionary(units[0]) if not units.is_empty() else {}
	var best_score: float = -1.0
	for unit_variant in units:
		var unit: Dictionary = Dictionary(unit_variant)
		var skill_values: Dictionary = Dictionary(unit.get("skill_values", {}))
		var score: float = float(skill_values.get("leadership", 0.0))
		if bool(unit.get("is_fireteam_lead", false)):
			score += 0.25
		if score > best_score:
			best_score = score
			best_unit = unit
	return best_unit


static func _add_pair_if_new(relationships: Array, seen_pair_keys: Dictionary, source: Dictionary, target: Dictionary, affinity: float, tags: Variant, reason: String) -> void:
	var source_id: String = normalize_unit_id(String(source.get("unit_id", "")))
	var target_id: String = normalize_unit_id(String(target.get("unit_id", "")))
	if source_id.is_empty() or target_id.is_empty() or source_id == target_id:
		return
	var pair_key: String = _pair_key(source_id, target_id)
	if seen_pair_keys.has(pair_key):
		return
	seen_pair_keys[pair_key] = true
	relationships.append(make_pair(source_id, target_id, affinity, tags, reason, true))


static func _pair_key(first_unit_id: String, second_unit_id: String) -> String:
	var first: String = normalize_unit_id(first_unit_id)
	var second: String = normalize_unit_id(second_unit_id)
	if first < second:
		return "%s|%s" % [first, second]
	return "%s|%s" % [second, first]


static func _normalize_tags(tags: Variant) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for tag_variant in Array(tags):
		var tag: String = String(tag_variant).strip_edges().to_lower()
		if tag.is_empty() or result.has(tag):
			continue
		if not RELATIONSHIP_TAGS.has(tag):
			continue
		result.append(tag)
	return result


static func _link_target_name(link: Dictionary) -> String:
	var target_name: String = String(link.get("target_name", "")).strip_edges()
	if not target_name.is_empty():
		return target_name
	return String(link.get("target_unit_id", "unknown")).strip_edges()


static func _seed_to_int(seed_text: String) -> int:
	var value: int = 2166136261
	for index in range(seed_text.length()):
		value = int((value ^ seed_text.unicode_at(index)) * 16777619) & 0x7fffffff
	return maxi(value, 1)
