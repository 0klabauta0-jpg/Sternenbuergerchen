class_name ContactDensityOverlay
extends RefCounted

const DEFAULT_CELL_SIZE_WORLD: float = 128.0
const DEFAULT_MAX_SOURCE_CONTACTS: int = 96
const DEFAULT_MAX_HEAT_CELLS: int = 48
const DEFAULT_DENSITY_FOR_FULL_INTENSITY: int = 4

const VISUAL_ONLY: bool = true
const UI_SETS_GAMEPLAY_TRUTH: bool = false


static func build_heat_cells(contact_entries: Array, options: Dictionary = {}) -> Dictionary:
	var cell_size_world: float = maxf(float(options.get("cell_size_world", DEFAULT_CELL_SIZE_WORLD)), 1.0)
	var max_source_contacts: int = maxi(int(options.get("max_source_contacts", DEFAULT_MAX_SOURCE_CONTACTS)), 0)
	var max_heat_cells: int = maxi(int(options.get("max_heat_cells", DEFAULT_MAX_HEAT_CELLS)), 0)
	var full_intensity_count: int = maxi(int(options.get("density_for_full_intensity", DEFAULT_DENSITY_FOR_FULL_INTENSITY)), 1)
	var deduped_contacts: Array = _dedupe_contacts(contact_entries)
	var source_contacts: Array = deduped_contacts
	var bounded_source_count: int = 0
	if max_source_contacts > 0 and source_contacts.size() > max_source_contacts:
		bounded_source_count = source_contacts.size() - max_source_contacts
		source_contacts = source_contacts.slice(0, max_source_contacts)

	var cells_by_key: Dictionary = {}
	for contact_variant in source_contacts:
		if typeof(contact_variant) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = Dictionary(contact_variant)
		var position_variant = contact.get("last_known_position", contact.get("position", null))
		if typeof(position_variant) != TYPE_VECTOR2:
			continue
		var position: Vector2 = Vector2(position_variant)
		var cell_position: Vector2i = Vector2i(floori(position.x / cell_size_world), floori(position.y / cell_size_world))
		var cell_key: String = "%d,%d" % [cell_position.x, cell_position.y]
		var cell: Dictionary = Dictionary(cells_by_key.get(cell_key, {
			"cell_key": cell_key,
			"cell_position": cell_position,
			"contact_count": 0,
			"weighted_contact_score": 0.0,
			"source_target_ids": PackedStringArray(),
			"source_fireteam_ids": PackedStringArray(),
			"detection_state_counts": {},
			"last_seen_tick": 0,
			"last_known_source_count": 0,
			"current_source_count": 0,
			"_sum_position": Vector2.ZERO,
		}))
		var contact_count: int = int(cell.get("contact_count", 0)) + 1
		cell["contact_count"] = contact_count
		cell["_sum_position"] = Vector2(cell.get("_sum_position", Vector2.ZERO)) + position
		cell["weighted_contact_score"] = float(cell.get("weighted_contact_score", 0.0)) + _contact_weight(contact)
		cell["last_seen_tick"] = maxi(int(cell.get("last_seen_tick", 0)), int(contact.get("last_seen_tick", contact.get("last_updated_tick", 0))))
		if bool(contact.get("fow_last_known", false)):
			cell["last_known_source_count"] = int(cell.get("last_known_source_count", 0)) + 1
		else:
			cell["current_source_count"] = int(cell.get("current_source_count", 0)) + 1
		var target_id: String = String(contact.get("target_id", contact.get("unit_id", ""))).strip_edges()
		_add_unique_string(cell, "source_target_ids", target_id)
		_add_unique_string(cell, "source_fireteam_ids", String(contact.get("fireteam_id", "")).strip_edges().to_lower())
		var detection_state: String = _normalize_detection_state(String(contact.get("detection_state", "unknown")))
		var state_counts: Dictionary = Dictionary(cell.get("detection_state_counts", {}))
		state_counts[detection_state] = int(state_counts.get(detection_state, 0)) + 1
		cell["detection_state_counts"] = state_counts
		cells_by_key[cell_key] = cell

	var cells: Array = []
	for cell_variant in cells_by_key.values():
		var cell: Dictionary = Dictionary(cell_variant).duplicate(true)
		var count: int = maxi(int(cell.get("contact_count", 0)), 1)
		var center: Vector2 = Vector2(cell.get("_sum_position", Vector2.ZERO)) / float(count)
		cell.erase("_sum_position")
		cell["center_position"] = center
		cell["intensity"] = clampf(float(count) / float(full_intensity_count), 0.0, 1.0)
		cell["heat_score"] = float(cell.get("weighted_contact_score", 0.0)) / float(count)
		cell["visual_only"] = VISUAL_ONLY
		cell["ui_sets_gameplay_truth"] = UI_SETS_GAMEPLAY_TRUTH
		cells.append(cell)
	cells.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _sort_cells_desc(a, b)
	)
	var bounded_cell_count: int = 0
	if max_heat_cells > 0 and cells.size() > max_heat_cells:
		bounded_cell_count = cells.size() - max_heat_cells
		cells = cells.slice(0, max_heat_cells)
	return {
		"enabled": bool(options.get("enabled", true)),
		"cell_size_world": cell_size_world,
		"source_contact_count": source_contacts.size(),
		"deduped_contact_count": deduped_contacts.size(),
		"bounded_source_count": bounded_source_count,
		"heat_cell_count": cells.size(),
		"bounded_heat_cell_count": bounded_cell_count,
		"heat_cells": cells,
		"visual_only": VISUAL_ONLY,
		"ui_sets_gameplay_truth": UI_SETS_GAMEPLAY_TRUTH,
		"aggregation_policy": "dedupe_target_then_bucket_world_cell",
	}


static func _dedupe_contacts(contact_entries: Array) -> Array:
	var contacts_by_target_id: Dictionary = {}
	var fallback_index: int = 0
	for entry_variant in contact_entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant).duplicate(true)
		var target_id: String = String(entry.get("target_id", entry.get("unit_id", ""))).strip_edges()
		if target_id.is_empty():
			target_id = "position:%s:%d" % [String(entry.get("last_known_position", entry.get("position", Vector2.ZERO))), fallback_index]
			fallback_index += 1
		var current: Dictionary = Dictionary(contacts_by_target_id.get(target_id, {}))
		if current.is_empty() or _contact_rank(entry) > _contact_rank(current):
			contacts_by_target_id[target_id] = entry
			continue
		if _contact_rank(entry) == _contact_rank(current) and int(entry.get("last_seen_tick", entry.get("last_updated_tick", -1))) > int(current.get("last_seen_tick", current.get("last_updated_tick", -1))):
			contacts_by_target_id[target_id] = entry
	var result: Array = contacts_by_target_id.values()
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var rank_a: int = _contact_rank(a)
		var rank_b: int = _contact_rank(b)
		if rank_a != rank_b:
			return rank_a > rank_b
		var tick_a: int = int(a.get("last_seen_tick", a.get("last_updated_tick", 0)))
		var tick_b: int = int(b.get("last_seen_tick", b.get("last_updated_tick", 0)))
		if tick_a != tick_b:
			return tick_a > tick_b
		return String(a.get("target_id", a.get("unit_id", ""))) < String(b.get("target_id", b.get("unit_id", "")))
	)
	return result


static func _contact_weight(contact: Dictionary) -> float:
	match _normalize_detection_state(String(contact.get("detection_state", "unknown"))):
		"confirmed":
			return 1.0
		"spotted":
			return 0.82
		"suspected":
			return 0.58
		"lost":
			return 0.42
		_:
			return 0.25


static func _contact_rank(contact: Dictionary) -> int:
	match _normalize_detection_state(String(contact.get("detection_state", ""))):
		"confirmed":
			return 4
		"spotted":
			return 3
		"suspected":
			return 2
		"lost":
			return 1
		_:
			return 0


static func _normalize_detection_state(value: String) -> String:
	var state: String = value.strip_edges().to_lower()
	match state:
		"confirmed", "spotted", "suspected", "lost":
			return state
		_:
			return "unknown"


static func _add_unique_string(target: Dictionary, key: String, value: String) -> void:
	var normalized: String = value.strip_edges()
	if normalized.is_empty():
		return
	var values: PackedStringArray = PackedStringArray(target.get(key, PackedStringArray()))
	if not values.has(normalized):
		values.append(normalized)
		values.sort()
	target[key] = values


static func _sort_cells_desc(a: Dictionary, b: Dictionary) -> bool:
	var count_a: int = int(a.get("contact_count", 0))
	var count_b: int = int(b.get("contact_count", 0))
	if count_a != count_b:
		return count_a > count_b
	var score_a: float = float(a.get("heat_score", 0.0))
	var score_b: float = float(b.get("heat_score", 0.0))
	if not is_equal_approx(score_a, score_b):
		return score_a > score_b
	return String(a.get("cell_key", "")) < String(b.get("cell_key", ""))
