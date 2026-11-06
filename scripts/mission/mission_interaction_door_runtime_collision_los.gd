class_name MissionInteractionDoorRuntimeCollisionLOS
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.mission_interaction_door_runtime_collision_los.v1"
const OPEN_PROGRESS_THRESHOLD: float = 0.85


static func resolve_door_state(state: String, progress: float) -> String:
	match state.strip_edges().to_lower():
		"complete", "open":
			return "open"
		"active", "holding", "operating", "in_progress":
			return "open" if progress >= OPEN_PROGRESS_THRESHOLD else "half"
		_:
			return "closed"


static func build_runtime_snapshot(bindings: Array, interaction_states: Dictionary, terrain_map_data = null, terrain_registry = null) -> Dictionary:
	# Runtime bindings and the existing Interaction owner are the physical source.
	# Local selection, visual anchors, range labels and render availability are not.
	var entries: Array = []
	var unresolved_marker_ids: PackedStringArray = PackedStringArray()
	for binding_variant in bindings:
		if typeof(binding_variant) != TYPE_DICTIONARY:
			continue
		var binding: Dictionary = Dictionary(binding_variant)
		if String(binding.get("interaction_type", "")).strip_edges().to_lower() != "door":
			continue
		var interaction_id: String = String(binding.get("interaction_id", "")).strip_edges()
		var marker_id: String = String(binding.get("marker_id", "")).strip_edges()
		if interaction_id.is_empty():
			continue
		if terrain_map_data == null or marker_id.is_empty() or not terrain_map_data.has_method("has_marker") or not bool(terrain_map_data.call("has_marker", marker_id)):
			unresolved_marker_ids.append(marker_id)
			continue
		var state: Dictionary = Dictionary(interaction_states.get(interaction_id, {}))
		var state_name: String = "complete" if bool(state.get("complete", false)) else String(state.get("state", ""))
		entries.append({
			"interaction_id": interaction_id,
			"marker_id": marker_id,
			"object_kind": "door",
			"world_position": Vector2(terrain_map_data.call("get_marker_position", marker_id, Vector2.ZERO)),
			"runtime_visual_state": resolve_door_state(state_name, clampf(float(state.get("progress", 0.0)), 0.0, 1.0)),
		})
	var snapshot: Dictionary = build_snapshot({"schema": "sternenbuergerchen.mission_interaction_door_runtime_projection.v1", "entries": entries}, terrain_registry)
	snapshot["runtime_authority"] = "MissionCombatLoopDriver interaction state"
	snapshot["unresolved_marker_ids"] = unresolved_marker_ids
	snapshot["unresolved_marker_count"] = unresolved_marker_ids.size()
	return snapshot


static func build_snapshot(object_reaction_snapshot: Dictionary, terrain_registry = null) -> Dictionary:
	var entries: Array = Array(object_reaction_snapshot.get("entries", []))
	var overrides: Array = []
	var door_entries: Array = []
	var state_counts: Dictionary = {}
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("object_kind", "")).strip_edges().to_lower() != "door":
			continue
		var door_entry: Dictionary = _build_door_entry(entry, terrain_registry)
		if door_entry.is_empty():
			continue
		state_counts[String(door_entry.get("runtime_visual_state", "closed"))] = int(state_counts.get(String(door_entry.get("runtime_visual_state", "closed")), 0)) + 1
		door_entries.append(door_entry)
		if door_entry.has("grid_position"):
			overrides.append(_build_override(door_entry))
	return {
		"schema": SNAPSHOT_SCHEMA,
		"source_object_reaction_schema": String(object_reaction_snapshot.get("schema", "")).strip_edges(),
		"runtime_authority": "SimulationRoot door state via MissionInteractionObjectReaction",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"terrain_map_data_mutated": false,
		"door_count": door_entries.size(),
		"override_count": overrides.size(),
		"state_counts": state_counts,
		"entries": door_entries,
		"overrides": overrides,
		"summary": _build_summary(door_entries, overrides),
	}


static func _build_door_entry(entry: Dictionary, terrain_registry) -> Dictionary:
	var runtime_visual_state: String = _normalize_door_state(String(entry.get("runtime_visual_state", "")))
	var grid_position: Variant = _resolve_grid_position(entry, terrain_registry)
	var result: Dictionary = {
		"interaction_id": String(entry.get("interaction_id", "")).strip_edges(),
		"marker_id": String(entry.get("marker_id", "")).strip_edges(),
		"runtime_visual_state": runtime_visual_state,
		"collision_state": _collision_state_for_door_state(runtime_visual_state),
		"los_state": _los_state_for_door_state(runtime_visual_state),
		"walkable_override": runtime_visual_state == "open",
		"blocks_los_override": runtime_visual_state != "open",
		"object_height_override": 0 if runtime_visual_state == "open" else 1,
		"cover_value_override": 0 if runtime_visual_state == "open" else 20,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"terrain_map_data_mutated": false,
	}
	if grid_position is Vector2i:
		result["grid_position"] = Vector2i(grid_position)
	return result


static func _build_override(door_entry: Dictionary) -> Dictionary:
	return {
		"grid_position": Vector2i(door_entry.get("grid_position", Vector2i.ZERO)),
		"walkable_override": bool(door_entry.get("walkable_override", false)),
		"blocks_los_override": bool(door_entry.get("blocks_los_override", true)),
		"object_height_override": int(door_entry.get("object_height_override", 1)),
		"cover_value_override": int(door_entry.get("cover_value_override", 0)),
		"source_interaction_id": String(door_entry.get("interaction_id", "")).strip_edges(),
		"source_runtime_visual_state": String(door_entry.get("runtime_visual_state", "")).strip_edges().to_lower(),
	}


static func _resolve_grid_position(entry: Dictionary, terrain_registry) -> Variant:
	var grid_variant: Variant = entry.get("grid_position", null)
	if grid_variant is Vector2i:
		return Vector2i(grid_variant)
	if grid_variant is Vector2:
		return Vector2i(grid_variant)
	var world_variant: Variant = entry.get("world_position", null)
	if world_variant is Vector2 and terrain_registry != null and terrain_registry.has_method("world_to_grid"):
		return Vector2i(terrain_registry.call("world_to_grid", Vector2(world_variant)))
	return null


static func _normalize_door_state(value: String) -> String:
	match value.strip_edges().to_lower():
		"open":
			return "open"
		"half":
			return "half"
		_:
			return "closed"


static func _collision_state_for_door_state(runtime_visual_state: String) -> String:
	return "open" if runtime_visual_state == "open" else "blocked"


static func _los_state_for_door_state(runtime_visual_state: String) -> String:
	return "clear" if runtime_visual_state == "open" else "blocked"


static func _build_summary(door_entries: Array, overrides: Array) -> String:
	if door_entries.is_empty():
		return "No door runtime collision/LOS overrides."
	return "%d door entries, %d effective terrain overrides; TerrainMapData remains unchanged." % [door_entries.size(), overrides.size()]
