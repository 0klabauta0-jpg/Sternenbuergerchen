class_name MapEditorAdjacencyDebugOverlay
extends RefCounted

const ROLE_SEED: String = "seed"
const ROLE_NEIGHBOR: String = "neighbor"
const ROLE_OBJECT: String = "object"

const COLOR_SEED: Color = Color(1.0, 0.86, 0.18, 0.44)
const COLOR_NEIGHBOR: Color = Color(0.16, 0.86, 1.0, 0.28)
const COLOR_OBJECT: Color = Color(1.0, 0.42, 0.16, 0.36)


static func build_entries_from_snapshot(snapshot: Dictionary) -> Array:
	var entries: Array = []
	var seen: Dictionary = {}
	var seed_lookup: Dictionary = {}
	for grid_variant in Array(snapshot.get("seed_grids", [])):
		var grid := Vector2i(grid_variant)
		seed_lookup[grid] = true
		seen[grid] = true
		entries.append({
			"grid_position": grid,
			"role": ROLE_SEED,
			"label": "S",
			"color": COLOR_SEED,
		})
	for grid_variant in Array(snapshot.get("neighborhood_grids", [])):
		var grid := Vector2i(grid_variant)
		if seen.has(grid):
			continue
		seen[grid] = true
		entries.append({
			"grid_position": grid,
			"role": ROLE_NEIGHBOR,
			"label": "N",
			"color": COLOR_NEIGHBOR,
		})
	for grid_variant in Array(snapshot.get("object_grids", [])):
		var grid := Vector2i(grid_variant)
		if seed_lookup.has(grid):
			continue
		entries.append({
			"grid_position": grid,
			"role": ROLE_OBJECT,
			"label": "O",
			"color": COLOR_OBJECT,
		})
	return entries


static func build_overlay_snapshot(snapshot: Dictionary, enabled: bool, drawn_entry_count: int = 0) -> Dictionary:
	var entries: Array = build_entries_from_snapshot(snapshot) if enabled else []
	var role_counts: Dictionary = {}
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var role: String = String(entry.get("role", ""))
		role_counts[role] = int(role_counts.get(role, 0)) + 1
	return {
		"enabled": enabled,
		"active": enabled and not entries.is_empty(),
		"visual_only": true,
		"ui_sets_gameplay_truth": false,
		"drawn_entry_count": drawn_entry_count,
		"entry_count": entries.size(),
		"role_counts": role_counts,
		"seed_count": int(snapshot.get("seed_count", 0)),
		"raw_neighborhood_candidate_count": int(snapshot.get("raw_neighborhood_candidate_count", 0)),
		"cliff_wall_candidate_count": int(snapshot.get("cliff_wall_candidate_count", 0)),
		"object_candidate_count": int(snapshot.get("object_candidate_count", 0)),
		"duplicate_neighborhood_candidate_count": int(snapshot.get("duplicate_neighborhood_candidate_count", 0)),
		"cliff_refresh_count": int(snapshot.get("cliff_refresh_count", 0)),
		"wall_refresh_count": int(snapshot.get("wall_refresh_count", 0)),
		"object_refresh_count": int(snapshot.get("object_refresh_count", 0)),
	}
