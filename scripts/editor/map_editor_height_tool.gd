class_name MapEditorHeightTool
extends RefCounted

const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")

const MODE_RAISE: String = "raise"
const MODE_LOWER: String = "lower"
const MODE_SET_1: String = "set_1"
const MODE_SET_2: String = "set_2"


static func build_height_patch(current_height: int, mode: String, edge_type: String, edge_none: String) -> Dictionary:
	var next_height: int = get_next_height_level(current_height, mode)
	return {
		"height_level": next_height,
		"edge_type": edge_type if next_height > 0 else edge_none,
	}


static func get_next_height_level(current_height: int, mode: String) -> int:
	match mode:
		MODE_RAISE:
			return clampi(current_height + 1, 0, TILE.MAX_HEIGHT_LEVEL)
		MODE_LOWER:
			return clampi(current_height - 1, 0, TILE.MAX_HEIGHT_LEVEL)
		MODE_SET_1:
			return 1
		MODE_SET_2:
			return 2
	if mode.begins_with("set_"):
		var level := mode.trim_prefix("set_")
		if level.is_valid_int(): return clampi(int(level), 0, TILE.MAX_HEIGHT_LEVEL)
	return 0


static func build_tile_height_patch(tile, mode: String, edge_type: String, shape_chosen: bool, ramp_enabled: bool, direction: int) -> Dictionary:
	var patch := build_height_patch(int(tile.height_level), mode, edge_type, TILE.EDGE_NONE)
	if tile.explicit_hex_ramps:
		var ramp := direction if shape_chosen and ramp_enabled else (-1 if shape_chosen else int(tile.ramp_direction))
		patch["ramp_direction"] = ramp
		if ramp >= 0: patch.height_level = mini(int(patch.height_level), TILE.MAX_HEIGHT_LEVEL - 1)
		patch.edge_type = TILE.EDGE_SLOPE if ramp >= 0 else TILE.EDGE_CLIFF
	return patch
