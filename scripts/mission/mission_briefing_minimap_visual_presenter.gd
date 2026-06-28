class_name MissionBriefingMinimapVisualPresenter
extends RefCounted

const MAX_SAMPLE_AXIS: int = 48
const MIN_SAMPLE_STRIDE: int = 1
const MAX_RENDER_ENTRIES: int = 24


func build_snapshot(terrain_map_data, minimap_overlay_snapshot: Dictionary = {}) -> Dictionary:
	if terrain_map_data == null or not terrain_map_data.has_method("get_grid_size"):
		return _empty_snapshot("No terrain map data.")
	var grid_size: Vector2i = terrain_map_data.call("get_grid_size")
	var stride: int = _build_sample_stride(grid_size)
	var map_bounds: Dictionary = Dictionary(minimap_overlay_snapshot.get("map_bounds", _build_map_bounds(terrain_map_data)))
	var terrain_samples: Array = _build_terrain_samples(terrain_map_data, map_bounds, stride)
	var overlay_entries: Array = _build_overlay_entries(Array(minimap_overlay_snapshot.get("entries", [])))
	return {
		"configured": grid_size.x > 0 and grid_size.y > 0,
		"valid": not terrain_samples.is_empty(),
		"runtime_authority": "MissionBriefingMinimapVisualPresenter",
		"ui_sets_gameplay_truth": false,
		"terrain_source": "TerrainMapData",
		"overlay_source": "MissionBriefingMinimapOverlayPresenter",
		"draw_mode": "coarse_terrain_samples",
		"grid_size": {"x": grid_size.x, "y": grid_size.y},
		"sample_stride": stride,
		"sample_count": terrain_samples.size(),
		"entry_count": overlay_entries.size(),
		"terrain_samples": terrain_samples,
		"overlay_entries": overlay_entries,
		"map_bounds": map_bounds.duplicate(true),
		"legend_entries": _build_legend_entries(overlay_entries),
	}


func _empty_snapshot(reason: String) -> Dictionary:
	return {
		"configured": false,
		"valid": false,
		"runtime_authority": "MissionBriefingMinimapVisualPresenter",
		"ui_sets_gameplay_truth": false,
		"reason": reason,
		"draw_mode": "none",
		"grid_size": {"x": 0, "y": 0},
		"sample_stride": 1,
		"sample_count": 0,
		"entry_count": 0,
		"terrain_samples": [],
		"overlay_entries": [],
		"legend_entries": [],
	}


func _build_sample_stride(grid_size: Vector2i) -> int:
	var max_axis: int = maxi(grid_size.x, grid_size.y)
	if max_axis <= 0:
		return MIN_SAMPLE_STRIDE
	return maxi(MIN_SAMPLE_STRIDE, ceili(float(max_axis) / float(MAX_SAMPLE_AXIS)))


func _build_terrain_samples(terrain_map_data, map_bounds: Dictionary, stride: int) -> Array:
	var result: Array = []
	for tile_variant in Array(terrain_map_data.call("get_tiles")):
		if tile_variant == null or not tile_variant.has_method("to_dict"):
			continue
		var tile: Dictionary = Dictionary(tile_variant.call("to_dict"))
		var grid_position: Vector2i = tile.get("grid_position", Vector2i.ZERO)
		if grid_position.x % stride != 0 or grid_position.y % stride != 0:
			continue
		var world_position: Vector2 = tile.get("world_position", Vector2.ZERO)
		result.append({
			"grid": {"x": grid_position.x, "y": grid_position.y},
			"uv": _serialize_vector2(_world_to_uv(world_position, map_bounds)),
			"surface_type": String(tile.get("surface_type", "ground")).strip_edges().to_lower(),
			"height_level": int(tile.get("height_level", 0)),
			"cover_value": int(tile.get("cover_value", 0)),
			"blocks_los": bool(tile.get("blocks_los", false)),
			"walkable": bool(tile.get("walkable", true)),
			"color_hex": _build_tile_color_hex(tile),
		})
	return result


func _build_overlay_entries(entries: Array) -> Array:
	var result: Array = []
	for entry_variant in entries:
		if result.size() >= MAX_RENDER_ENTRIES:
			break
		var entry: Dictionary = Dictionary(entry_variant)
		if not bool(entry.get("has_position", false)):
			continue
		var uv: Dictionary = Dictionary(entry.get("minimap_position_uv", {}))
		if not uv.has("x") or not uv.has("y"):
			continue
		var kind: String = String(entry.get("kind", "note")).strip_edges().to_lower()
		result.append({
			"kind": kind,
			"text": String(entry.get("compact_label", entry.get("text", kind))).strip_edges(),
			"target_id": String(entry.get("target_id", "")).strip_edges(),
			"team_id": String(entry.get("team_id", "")).strip_edges(),
			"uv": {"x": clampf(float(uv.get("x", 0.0)), 0.0, 1.0), "y": clampf(float(uv.get("y", 0.0)), 0.0, 1.0)},
			"color_hex": _build_entry_color_hex(entry),
			"radius": maxf(float(entry.get("radius", 0.0)), 0.0),
			"symbol": String(entry.get("symbol", _symbol_for_kind(kind))).strip_edges().to_lower(),
			"ui_sets_gameplay_truth": false,
		})
	return result


func _build_legend_entries(entries: Array) -> Array:
	var seen: Dictionary = {}
	var result: Array = []
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var kind: String = String(entry.get("kind", "note")).strip_edges().to_lower()
		if seen.has(kind):
			continue
		seen[kind] = true
		result.append({
			"kind": kind,
			"label": _legend_label_for_kind(kind),
			"color_hex": String(entry.get("color_hex", "#9aa3ad")),
		})
	return result


func _build_tile_color_hex(tile: Dictionary) -> String:
	if bool(tile.get("blocks_los", false)):
		return "#4a5661"
	if int(tile.get("cover_value", 0)) >= 50:
		return "#7a6d48"
	match String(tile.get("surface_type", "ground")).strip_edges().to_lower():
		"water":
			return "#2d638f"
		"road":
			return "#6d737a"
		"sand":
			return "#917a4c"
		"rock":
			return "#565c62"
		_:
			if int(tile.get("height_level", 0)) > 0:
				return "#506f52"
			return "#344f3f"


func _build_entry_color_hex(entry: Dictionary) -> String:
	var team_color: String = String(entry.get("team_color_hex", "")).strip_edges()
	if not team_color.is_empty():
		return team_color
	match String(entry.get("kind", "note")).strip_edges().to_lower():
		"danger":
			return "#ff6d5e"
		"objective":
			return "#f2d45c"
		"route":
			return "#63d6ff"
		"team_spawn":
			return "#9ee37d"
		_:
			return "#d7e2e8"


func _symbol_for_kind(kind: String) -> String:
	match kind:
		"danger":
			return "ring"
		"objective":
			return "square"
		"route":
			return "line"
		"team_spawn":
			return "diamond"
		_:
			return "dot"


func _legend_label_for_kind(kind: String) -> String:
	match kind:
		"danger":
			return "Danger"
		"objective":
			return "Objective"
		"route":
			return "Route"
		"team_spawn":
			return "Team Spawn"
		_:
			return "Marker"


func _build_map_bounds(terrain_map_data) -> Dictionary:
	var grid_size: Vector2i = terrain_map_data.call("get_grid_size")
	return {
		"min": _serialize_vector2(Vector2.ZERO),
		"max": _serialize_vector2(Vector2(maxf(float(grid_size.x), 1.0), maxf(float(grid_size.y), 1.0))),
		"grid_size": {"x": grid_size.x, "y": grid_size.y},
	}


func _world_to_uv(world_position: Vector2, map_bounds: Dictionary) -> Vector2:
	var min_position: Vector2 = _deserialize_vector2(Dictionary(map_bounds.get("min", {})))
	var max_position: Vector2 = _deserialize_vector2(Dictionary(map_bounds.get("max", {})))
	var width: float = maxf(max_position.x - min_position.x, 0.001)
	var height: float = maxf(max_position.y - min_position.y, 0.001)
	return Vector2(
		clampf((world_position.x - min_position.x) / width, 0.0, 1.0),
		clampf((world_position.y - min_position.y) / height, 0.0, 1.0)
	)


func _serialize_vector2(value: Vector2) -> Dictionary:
	return {"x": snappedf(value.x, 0.001), "y": snappedf(value.y, 0.001)}


func _deserialize_vector2(value: Dictionary) -> Vector2:
	return Vector2(float(value.get("x", 0.0)), float(value.get("y", 0.0)))
