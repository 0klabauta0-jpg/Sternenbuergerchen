class_name MissionBriefingMinimapOverlayPresenter
extends RefCounted

const TEAM_OWNERSHIP_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/mission_multiplayer_team_ownership_contract.gd")
const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")
const VERTICAL_SLICE_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_vertical_slice_contract.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")


func build_snapshot_from_files(scenario_path: String, map_path: String = "", play_mode: String = TEAM_OWNERSHIP_CONTRACT_SCRIPT.PLAY_MODE_MULTIPLAYER_PVP) -> Dictionary:
	var scenario = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", scenario_path)
	var resolved_map_path: String = map_path.strip_edges()
	if resolved_map_path.is_empty() and scenario != null:
		resolved_map_path = String(scenario.get("map_file_path")).strip_edges()
	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", resolved_map_path) if not resolved_map_path.is_empty() else null
	var vertical_slice: Dictionary = Dictionary(VERTICAL_SLICE_CONTRACT_SCRIPT.call("load_slice_from_file", scenario_path))
	return build_snapshot(scenario, terrain_map_data, vertical_slice, play_mode)


func build_snapshot(scenario, terrain_map_data, vertical_slice: Dictionary = {}, play_mode: String = TEAM_OWNERSHIP_CONTRACT_SCRIPT.PLAY_MODE_MULTIPLAYER_PVP) -> Dictionary:
	var briefing: Dictionary = Dictionary(scenario.call("get_briefing")) if scenario != null and scenario.has_method("get_briefing") else {}
	var minimap_mode: String = String(briefing.get("minimap_mode", "terrain_only")).strip_edges().to_lower()
	var map_bounds: Dictionary = _build_map_bounds(terrain_map_data)
	var briefing_annotations: Array = _build_briefing_annotation_entries(Array(briefing.get("annotations", [])), terrain_map_data, map_bounds)
	var team_spawn_overlays: Array = _build_team_spawn_entries(vertical_slice, terrain_map_data, map_bounds, play_mode)
	var entries: Array = []
	entries.append_array(briefing_annotations)
	entries.append_array(team_spawn_overlays)
	return {
		"configured": minimap_mode != "none" and terrain_map_data != null,
		"valid": _entries_have_positions(team_spawn_overlays),
		"runtime_authority": "MissionBriefingMinimapOverlayPresenter",
		"ui_sets_gameplay_truth": false,
		"minimap_mode": minimap_mode,
		"terrain_source": "TerrainMapData",
		"briefing_source": "MissionScenarioData.briefing",
		"team_source": "vertical_slice.team_slots",
		"entry_count": entries.size(),
		"entries": entries,
		"briefing_annotation_count": briefing_annotations.size(),
		"team_spawn_overlay_count": team_spawn_overlays.size(),
		"team_spawn_overlays": team_spawn_overlays,
		"map_bounds": map_bounds,
	}


func _build_team_spawn_entries(vertical_slice: Dictionary, terrain_map_data, map_bounds: Dictionary, play_mode: String) -> Array:
	var normalized_slice: Dictionary = Dictionary(VERTICAL_SLICE_CONTRACT_SCRIPT.call("normalize_slice", vertical_slice))
	var ownership_snapshot: Dictionary = Dictionary(TEAM_OWNERSHIP_CONTRACT_SCRIPT.call(
		"build_team_ownership_snapshot",
		normalized_slice,
		{},
		play_mode
	))
	var readability_by_team: Dictionary = {}
	for entry_variant in Array(ownership_snapshot.get("team_readability", [])):
		var entry: Dictionary = Dictionary(entry_variant)
		readability_by_team[String(entry.get("team_id", "")).strip_edges()] = entry
	var result: Array = []
	for slot_variant in Array(normalized_slice.get("team_slots", [])):
		var slot: Dictionary = Dictionary(slot_variant)
		var marker_id: String = String(slot.get("spawn_marker_id", "")).strip_edges()
		var team_id: String = String(slot.get("team_id", "")).strip_edges()
		if team_id.is_empty() or marker_id.is_empty():
			continue
		var marker_snapshot: Dictionary = _build_marker_position_snapshot(marker_id, terrain_map_data, map_bounds)
		var readability: Dictionary = Dictionary(readability_by_team.get(team_id, {}))
		var short_label: String = String(readability.get("short_label", team_id.capitalize())).strip_edges()
		var icon_text: String = _team_icon_text(team_id)
		var spawn_icon_text: String = _spawn_icon_text(marker_id)
		result.append({
			"kind": "team_spawn",
			"team_id": team_id,
			"team_label": short_label,
			"icon_text": icon_text,
			"spawn_icon_text": spawn_icon_text,
			"compact_label": "%s %s" % [icon_text, short_label],
			"compact_text": "%s %s @ %s" % [icon_text, short_label, spawn_icon_text],
			"icon_tooltip": "%s | %s | %s" % [short_label, String(readability.get("ownership_label", "")).strip_edges(), marker_id],
			"visual_priority": _team_visual_priority(team_id),
			"role": String(slot.get("role", "")).strip_edges(),
			"target_id": marker_id,
			"text": "%s SPAWN" % short_label.to_upper(),
			"marker_name": String(marker_snapshot.get("marker_name", marker_id)),
			"world_position": marker_snapshot.get("world_position", {}),
			"minimap_position_uv": marker_snapshot.get("minimap_position_uv", {}),
			"has_position": bool(marker_snapshot.get("has_position", false)),
			"team_color_hex": String(readability.get("team_color_hex", _team_color_hex(team_id))),
			"ownership_label": String(readability.get("ownership_label", "")),
			"control_label": String(readability.get("control_label", "")),
			"symbol": "diamond",
			"ui_sets_gameplay_truth": false,
		})
	return result


func _build_briefing_annotation_entries(annotations: Array, terrain_map_data, map_bounds: Dictionary) -> Array:
	var result: Array = []
	for annotation_variant in annotations:
		var annotation: Dictionary = Dictionary(annotation_variant)
		var target_id: String = String(annotation.get("target_id", "")).strip_edges()
		var entry: Dictionary = annotation.duplicate(true)
		entry["kind"] = String(entry.get("kind", "note")).strip_edges().to_lower()
		entry["source"] = "briefing.annotations"
		entry["ui_sets_gameplay_truth"] = false
		if not target_id.is_empty():
			var marker_snapshot: Dictionary = _build_marker_position_snapshot(target_id, terrain_map_data, map_bounds)
			entry["world_position"] = marker_snapshot.get("world_position", {})
			entry["minimap_position_uv"] = marker_snapshot.get("minimap_position_uv", {})
			entry["has_position"] = bool(marker_snapshot.get("has_position", false))
			entry["marker_name"] = String(marker_snapshot.get("marker_name", target_id))
		result.append(entry)
	return result


func _build_marker_position_snapshot(marker_id: String, terrain_map_data, map_bounds: Dictionary) -> Dictionary:
	if terrain_map_data == null or not terrain_map_data.has_method("has_marker") or not bool(terrain_map_data.call("has_marker", marker_id)):
		return {
			"has_position": false,
			"marker_name": marker_id,
			"world_position": {},
			"minimap_position_uv": {},
		}
	var world_position: Vector2 = terrain_map_data.call("get_marker_position", marker_id, Vector2.ZERO)
	var uv: Vector2 = _world_to_uv(world_position, map_bounds)
	return {
		"has_position": true,
		"marker_name": String(terrain_map_data.call("get_marker_display_name", marker_id)),
		"world_position": _serialize_vector2(world_position),
		"minimap_position_uv": _serialize_vector2(uv),
	}


func _build_map_bounds(terrain_map_data) -> Dictionary:
	if terrain_map_data == null or not terrain_map_data.has_method("get_grid_size"):
		return {"min": _serialize_vector2(Vector2.ZERO), "max": _serialize_vector2(Vector2.ONE)}
	var grid_size: Vector2i = terrain_map_data.call("get_grid_size")
	var corners: Array[Vector2] = [
		_grid_to_world(terrain_map_data, Vector2i(0, 0)),
		_grid_to_world(terrain_map_data, Vector2i(maxi(grid_size.x - 1, 0), 0)),
		_grid_to_world(terrain_map_data, Vector2i(0, maxi(grid_size.y - 1, 0))),
		_grid_to_world(terrain_map_data, Vector2i(maxi(grid_size.x - 1, 0), maxi(grid_size.y - 1, 0))),
	]
	var min_position: Vector2 = corners[0]
	var max_position: Vector2 = corners[0]
	for corner in corners:
		min_position.x = minf(min_position.x, corner.x)
		min_position.y = minf(min_position.y, corner.y)
		max_position.x = maxf(max_position.x, corner.x)
		max_position.y = maxf(max_position.y, corner.y)
	return {
		"min": _serialize_vector2(min_position),
		"max": _serialize_vector2(max_position),
		"grid_size": {"x": grid_size.x, "y": grid_size.y},
	}


func _grid_to_world(terrain_map_data, grid_position: Vector2i) -> Vector2:
	var tile_size: Dictionary = Dictionary(terrain_map_data.call("get_tile_size"))
	var origin: Vector2 = terrain_map_data.call("get_grid_origin")
	return Vector2(
		origin.x + (float(grid_position.x - grid_position.y) * float(tile_size.get("half_width", 64.0))),
		origin.y + (float(grid_position.x + grid_position.y) * float(tile_size.get("half_height", 32.0)))
	)


func _world_to_uv(world_position: Vector2, map_bounds: Dictionary) -> Vector2:
	var min_position: Vector2 = _deserialize_vector2(Dictionary(map_bounds.get("min", {})))
	var max_position: Vector2 = _deserialize_vector2(Dictionary(map_bounds.get("max", {})))
	var width: float = maxf(max_position.x - min_position.x, 0.001)
	var height: float = maxf(max_position.y - min_position.y, 0.001)
	return Vector2(
		clampf((world_position.x - min_position.x) / width, 0.0, 1.0),
		clampf((world_position.y - min_position.y) / height, 0.0, 1.0)
	)


func _entries_have_positions(entries: Array) -> bool:
	if entries.is_empty():
		return false
	for entry_variant in entries:
		if not bool(Dictionary(entry_variant).get("has_position", false)):
			return false
	return true


func _team_color_hex(team_id: String) -> String:
	match team_id.strip_edges().to_lower():
		"team_alpha":
			return "#5fb7ff"
		"team_bravo":
			return "#ff9b5e"
		_:
			return "#9aa3ad"


func _team_icon_text(team_id: String) -> String:
	match team_id.strip_edges().to_lower():
		"team_alpha":
			return "[A]"
		"team_bravo":
			return "[B]"
		_:
			return "[T]"


func _spawn_icon_text(spawn_marker_id: String) -> String:
	match spawn_marker_id.strip_edges().to_lower():
		"spawn_alpha":
			return "A-LZ"
		"spawn_bravo":
			return "B-LZ"
		"":
			return "LZ?"
		_:
			return spawn_marker_id.strip_edges()


func _team_visual_priority(team_id: String) -> int:
	match team_id.strip_edges().to_lower():
		"team_alpha":
			return 10
		"team_bravo":
			return 20
		_:
			return 90


func _serialize_vector2(value: Vector2) -> Dictionary:
	return {
		"x": snappedf(value.x, 0.001),
		"y": snappedf(value.y, 0.001),
	}


func _deserialize_vector2(value: Dictionary) -> Vector2:
	return Vector2(float(value.get("x", 0.0)), float(value.get("y", 0.0)))
