class_name MapEditorTilePropertyOverlay
extends RefCounted

const ROLE_WALKABLE: String = "walkable"
const ROLE_BLOCKED: String = "blocked"
const ROLE_LOS_BLOCK: String = "los_block"
const ROLE_COVER: String = "cover"
const ROLE_HEIGHT: String = "height"

const COLOR_WALKABLE: Color = Color(0.18, 0.62, 1.0, 0.16)
const COLOR_BLOCKED: Color = Color(1.0, 0.20, 0.16, 0.34)
const COLOR_LOS_BLOCK: Color = Color(0.66, 0.24, 1.0, 0.34)
const COLOR_COVER: Color = Color(0.18, 0.90, 0.42, 0.28)
const COLOR_HEIGHT: Color = Color(1.0, 0.72, 0.18, 0.30)


static func build_tile_entry(tile_data) -> Dictionary:
	if tile_data == null:
		return {}
	var role: String = get_tile_color_role(tile_data)
	var color: Color = get_tile_color(tile_data)
	return {
		"grid_position": tile_data.grid_position,
		"world_position": tile_data.world_position,
		"walkable": bool(tile_data.walkable),
		"blocks_los": bool(tile_data.blocks_los),
		"cover_value": int(tile_data.cover_value),
		"height_level": int(tile_data.height_level),
		"object_height": int(tile_data.object_height),
		"surface_type": String(tile_data.surface_type),
		"edge_type": String(tile_data.edge_type),
		"color_role": role,
		"color": color,
		"label": build_tile_label(tile_data),
	}


static func get_tile_color_role(tile_data) -> String:
	if tile_data == null:
		return ROLE_WALKABLE
	if not bool(tile_data.walkable):
		return ROLE_BLOCKED
	if bool(tile_data.blocks_los) or int(tile_data.object_height) > 0:
		return ROLE_LOS_BLOCK
	if int(tile_data.cover_value) > 0:
		return ROLE_COVER
	if int(tile_data.height_level) > 0:
		return ROLE_HEIGHT
	return ROLE_WALKABLE


static func get_tile_color(tile_data) -> Color:
	var role: String = get_tile_color_role(tile_data)
	match role:
		ROLE_BLOCKED:
			return COLOR_BLOCKED
		ROLE_LOS_BLOCK:
			return COLOR_LOS_BLOCK
		ROLE_COVER:
			var cover_ratio: float = clampf(float(tile_data.cover_value) / 100.0, 0.0, 1.0)
			return Color(COLOR_COVER.r, COLOR_COVER.g, COLOR_COVER.b, lerpf(0.24, 0.44, cover_ratio))
		ROLE_HEIGHT:
			var height_ratio: float = clampf(float(tile_data.height_level) / 2.0, 0.0, 1.0)
			return Color(COLOR_HEIGHT.r, COLOR_HEIGHT.g, COLOR_HEIGHT.b, lerpf(0.24, 0.42, height_ratio))
		_:
			return COLOR_WALKABLE


static func build_tile_label(tile_data) -> String:
	if tile_data == null:
		return ""
	var parts: PackedStringArray = PackedStringArray()
	if not bool(tile_data.walkable):
		parts.append("BLK")
	if bool(tile_data.blocks_los) or int(tile_data.object_height) > 0:
		parts.append("LOS")
	if int(tile_data.cover_value) > 0:
		parts.append("C%d" % int(tile_data.cover_value))
	if int(tile_data.height_level) > 0:
		parts.append("H%d" % int(tile_data.height_level))
	return " ".join(parts)


static func build_legend() -> Dictionary:
	return {
		ROLE_WALKABLE: {"label": "Walkable", "color": COLOR_WALKABLE},
		ROLE_BLOCKED: {"label": "Blocked", "color": COLOR_BLOCKED},
		ROLE_LOS_BLOCK: {"label": "LOS Block", "color": COLOR_LOS_BLOCK},
		ROLE_COVER: {"label": "Cover", "color": COLOR_COVER},
		ROLE_HEIGHT: {"label": "Height", "color": COLOR_HEIGHT},
	}


static func build_overlay_snapshot(terrain_map_data, enabled: bool) -> Dictionary:
	if not enabled:
		return {
			"enabled": false,
			"active": false,
			"visual_only": true,
			"ui_sets_gameplay_truth": false,
			"cell_count": 0,
			"color_roles": {},
			"legend": build_legend(),
		}
	var color_roles: Dictionary = {}
	var cell_count: int = 0
	if terrain_map_data != null and terrain_map_data.has_method("get_tiles"):
		for tile_data in Array(terrain_map_data.call("get_tiles")):
			if tile_data == null:
				continue
			cell_count += 1
			var role: String = get_tile_color_role(tile_data)
			color_roles[role] = int(color_roles.get(role, 0)) + 1
	return {
		"enabled": true,
		"active": true,
		"visual_only": true,
		"ui_sets_gameplay_truth": false,
		"cell_count": cell_count,
		"color_roles": color_roles,
		"legend": build_legend(),
	}
