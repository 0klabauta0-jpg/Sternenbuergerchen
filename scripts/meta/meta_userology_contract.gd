class_name MetaUserologyContract
extends RefCounted

const DRAG_PREVIEW_Z_INDEX: int = 4096
const MIN_BADGE_SIZE: Vector2 = Vector2(22.0, 22.0)
const COMPACT_SLOT_SIZE: Vector2 = Vector2(148.0, 58.0)


static func build_drag_badge_contract() -> Dictionary:
	return {
		"drag_preview_z_index": DRAG_PREVIEW_Z_INDEX,
		"drag_preview_above_windows": true,
		"badge_minimum_size": MIN_BADGE_SIZE,
		"badge_layout": "right_of_main_text",
		"tooltip_policy": "badge_hover_only_no_active_drag",
		"character_sheet_uses_same_badge_help": true,
	}


static func build_transit_entry(entity_id: String, entity_type: String, source: String, destination: String, transport_id: String, progress: float, eta_seconds: int, status: String = "in_transit") -> Dictionary:
	return {
		"entity_id": entity_id.strip_edges(),
		"entity_type": entity_type.strip_edges().to_lower(),
		"source": source.strip_edges().to_lower(),
		"destination": destination.strip_edges().to_lower(),
		"transport_id": transport_id.strip_edges(),
		"progress": clampf(progress, 0.0, 100.0),
		"eta_seconds": maxi(eta_seconds, 0),
		"status": status.strip_edges().to_lower() if not status.strip_edges().is_empty() else "in_transit",
		"ghost_on_source": true,
		"ghost_on_destination": true,
		"normal_drag_enabled": false,
	}


static func build_transit_snapshot(entries: Array) -> Dictionary:
	var normalized_entries: Array = []
	var source_ghosts: Dictionary = {}
	var destination_ghosts: Dictionary = {}
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var normalized: Dictionary = build_transit_entry(
			String(entry.get("entity_id", "")),
			String(entry.get("entity_type", "operator")),
			String(entry.get("source", "")),
			String(entry.get("destination", "")),
			String(entry.get("transport_id", "")),
			float(entry.get("progress", 0.0)),
			int(entry.get("eta_seconds", 0)),
			String(entry.get("status", "in_transit"))
		)
		normalized_entries.append(normalized)
		source_ghosts[String(normalized.get("source", ""))] = int(source_ghosts.get(String(normalized.get("source", "")), 0)) + 1
		destination_ghosts[String(normalized.get("destination", ""))] = int(destination_ghosts.get(String(normalized.get("destination", "")), 0)) + 1
	return {
		"entries": normalized_entries,
		"entry_count": normalized_entries.size(),
		"source_ghosts": source_ghosts,
		"destination_ghosts": destination_ghosts,
		"single_progress_truth": true,
	}


static func complete_transit(entries: Array, entity_id: String) -> Dictionary:
	var remaining: Array = []
	var completed: Dictionary = {}
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("entity_id", "")) == entity_id:
			completed = build_transit_entry(
				String(entry.get("entity_id", "")),
				String(entry.get("entity_type", "operator")),
				String(entry.get("source", "")),
				String(entry.get("destination", "")),
				String(entry.get("transport_id", "")),
				100.0,
				0,
				"arrived"
			)
			continue
		remaining.append(entry.duplicate(true))
	return {
		"completed": completed,
		"remaining": remaining,
		"stale_ghost_removed": not completed.is_empty(),
	}


static func build_unassigned_pool(units: Array, fireteam_assignments: Dictionary, loadout_assignments: Dictionary = {}, respawn_assignments: Dictionary = {}, transit_entries: Array = []) -> Dictionary:
	var transit_lookup: Dictionary = {}
	for entry_variant in transit_entries:
		if typeof(entry_variant) == TYPE_DICTIONARY:
			transit_lookup[String(Dictionary(entry_variant).get("entity_id", ""))] = true
	var cards: Array = []
	for unit_variant in units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(unit_variant)
		var unit_id: String = String(unit.get("unit_id", "")).strip_edges()
		if unit_id.is_empty() or transit_lookup.has(unit_id):
			continue
		if not String(fireteam_assignments.get(unit_id, "")).strip_edges().is_empty():
			continue
		if loadout_assignments.has(unit_id) or respawn_assignments.has(unit_id):
			continue
		cards.append(_build_compact_operator_card(unit, "fob_unassigned"))
	return {
		"pool_id": "fob_unassigned",
		"card_count": cards.size(),
		"cards": cards,
		"drop_targets": PackedStringArray(["fireteam", "loadout", "fob_reserve"]),
		"prevents_duplicate_active_cards": true,
	}


static func build_fireteam_board(fireteam_definitions: Array, units: Array, assignments: Dictionary) -> Dictionary:
	var units_by_id: Dictionary = {}
	for unit_variant in units:
		if typeof(unit_variant) == TYPE_DICTIONARY:
			units_by_id[String(Dictionary(unit_variant).get("unit_id", ""))] = Dictionary(unit_variant)
	var frames: Array = []
	var assigned_lookup: Dictionary = {}
	for definition_variant in fireteam_definitions:
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = Dictionary(definition_variant)
		var fireteam_id: String = String(definition.get("id", "")).strip_edges().to_lower()
		var members: Array = []
		for unit_id_variant in assignments.keys():
			var unit_id: String = String(unit_id_variant)
			if String(assignments.get(unit_id, "")).strip_edges().to_lower() != fireteam_id:
				continue
			assigned_lookup[unit_id] = true
			var card: Dictionary = _build_compact_operator_card(Dictionary(units_by_id.get(unit_id, {"unit_id": unit_id})), "fireteam")
			card["is_leader"] = unit_id == String(definition.get("lead_unit_id", ""))
			members.append(card)
		frames.append({
			"fireteam_id": fireteam_id,
			"label": String(definition.get("label", fireteam_id.to_upper())),
			"rename_enabled": true,
			"member_cards": members,
			"missing_leader_warning": String(definition.get("lead_unit_id", "")).strip_edges().is_empty(),
			"remove_target": "fob_unassigned",
		})
	var unassigned_cards: Array = []
	for unit_variant in units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(unit_variant)
		var unit_id: String = String(unit.get("unit_id", "")).strip_edges()
		if not unit_id.is_empty() and not assigned_lookup.has(unit_id):
			unassigned_cards.append(_build_compact_operator_card(unit, "fob_unassigned"))
	return {
		"frames": frames,
		"unassigned": {"cards": unassigned_cards, "pool_id": "fob_unassigned"},
		"compact_card_size": COMPACT_SLOT_SIZE,
		"dragdrop_semantics": PackedStringArray(["unassigned_to_fireteam", "fireteam_to_unassigned", "fireteam_to_fireteam"]),
	}


static func build_compact_flightdeck_card(craft_state: Dictionary, passenger_units: Array) -> Dictionary:
	var occupants: Array = []
	for unit_variant in passenger_units:
		if typeof(unit_variant) == TYPE_DICTIONARY:
			occupants.append(_build_compact_operator_card(Dictionary(unit_variant), "dropship_occupant"))
	return {
		"craft_id": String(craft_state.get("craft_id", "")).strip_edges(),
		"display_name": String(craft_state.get("display_name", "Dropship")).strip_edges(),
		"rename_enabled": true,
		"compact_header": true,
		"pilot_status": "assigned" if not String(craft_state.get("pilot_unit_id", "")).strip_edges().is_empty() else "missing",
		"pilot_text_dominance": "badge",
		"occupant_cards": occupants,
		"empty_slot_count": maxi(int(craft_state.get("capacity", 6)) - occupants.size(), 0),
		"remove_action": {"label": "X", "requires_confirmation": true, "target_after_remove": "fob_unassigned"},
	}


static func _build_compact_operator_card(unit: Dictionary, source_context: String) -> Dictionary:
	return {
		"unit_id": String(unit.get("unit_id", "")).strip_edges(),
		"display_name": String(unit.get("display_name", unit.get("unit_id", ""))).strip_edges(),
		"role": String(unit.get("role_name", unit.get("roster_role_category", ""))).strip_edges(),
		"portrait_path": String(unit.get("portrait_path", "")).strip_edges(),
		"badge_count": Array(unit.get("rank_badges", [])).size(),
		"source_context": source_context,
		"compact": true,
	}
