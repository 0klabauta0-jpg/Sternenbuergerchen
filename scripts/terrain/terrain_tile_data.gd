class_name TerrainTileData
extends RefCounted

const HEX_GRID_SCRIPT = preload("res://scripts/terrain/hex_grid.gd")
const EXPLICIT_HEIGHT_RULES := "explicit_hex_ramps_v1"

const SURFACE_GROUND: String = "ground"
const SURFACE_ROAD: String = "road"
const SURFACE_SAND: String = "sand"
const SURFACE_ROCK: String = "rock"
const SURFACE_WATER: String = "water"

const DEFAULT_WALKABLE: bool = true
const DEFAULT_BLOCKS_LOS: bool = false
const DEFAULT_COVER_VALUE: int = 0
const DEFAULT_HEIGHT_LEVEL: int = 0
const MAX_HEIGHT_LEVEL: int = 8
const DEFAULT_OBJECT_HEIGHT: int = 0
const DEFAULT_OBJECT_SCALE: float = 1.0
const MIN_OBJECT_SCALE: float = 0.25
const MAX_OBJECT_SCALE: float = 2.5
const DEFAULT_SURFACE_TYPE: String = SURFACE_GROUND

const EDGE_CLIFF: String = "cliff"
const EDGE_SLOPE: String = "slope"
const EDGE_NONE: String = "none"

var tile_id: String = ""
var type_id: String = ""
var object_type_id: String = ""
var grid_position: Vector2i = Vector2i.ZERO
var world_position: Vector2 = Vector2.ZERO
var walkable: bool = DEFAULT_WALKABLE
var blocks_los: bool = DEFAULT_BLOCKS_LOS
var cover_value: int = DEFAULT_COVER_VALUE
var height_level: int = DEFAULT_HEIGHT_LEVEL
var object_height: int = DEFAULT_OBJECT_HEIGHT
var object_rotation_degrees: float = 0.0
var object_scale: float = DEFAULT_OBJECT_SCALE
var surface_type: String = DEFAULT_SURFACE_TYPE
var edge_type: String = EDGE_CLIFF
var regional_grade: bool = false
var explicit_hex_ramps: bool = false
var ramp_direction: int = -1


func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		_apply_dict(data)


static func from_dict(data: Dictionary):
	return TerrainTileData.new(data)


func is_valid() -> bool:
	return not tile_id.is_empty() and _is_surface_type_valid(surface_type) \
		and (not explicit_hex_ramps or (ramp_direction >= -1 and ramp_direction < 6 \
		and (ramp_direction == -1 or height_level < MAX_HEIGHT_LEVEL)))


func to_dict() -> Dictionary:
	return {
		"tile_id": tile_id,
		"type_id": type_id,
		"object_type_id": object_type_id,
		"grid_position": grid_position,
		"world_position": world_position,
		"walkable": walkable,
		"blocks_los": blocks_los,
		"cover_value": cover_value,
		"height_level": height_level,
		"object_height": object_height,
		"object_rotation_degrees": object_rotation_degrees,
		"object_scale": object_scale,
		"surface_type": surface_type,
		"edge_type": edge_type,
		"regional_grade": regional_grade,
		"explicit_hex_ramps": explicit_hex_ramps,
		"ramp_direction": ramp_direction,
	}


static func is_explicit_ramp(tile) -> bool:
	return tile != null and tile.explicit_hex_ramps and tile.ramp_direction >= 0 \
		and tile.ramp_direction < 6 and tile.height_level < MAX_HEIGHT_LEVEL


static func stand_height(tile) -> float:
	if tile == null: return 0.0
	return float(tile.height_level) + (0.5 if is_explicit_ramp(tile) else 0.0)


static func endpoint_height(tile, neighbor_grid: Vector2i) -> float:
	return _endpoint_height(tile, neighbor_grid, false)


static func _endpoint_height(tile, neighbor_grid: Vector2i, registry_passable: bool) -> float:
	if tile == null or (not registry_passable and not tile.walkable): return INF
	if not tile.explicit_hex_ramps or tile.ramp_direction == -1:
		return float(tile.height_level)
	if not is_explicit_ramp(tile): return INF
	var delta: Vector2i = neighbor_grid - Vector2i(tile.grid_position)
	var uphill: Vector2i = HEX_GRID_SCRIPT.DIRECTIONS[tile.ramp_direction]
	if delta == uphill: return float(tile.height_level + 1)
	if delta == -uphill: return float(tile.height_level)
	# Lateral seams connect only to another ramp with the same midpoint height.
	# Integer-height plateaus never match this half-level.
	return stand_height(tile)


static func allows_step(from_tile, to_tile) -> bool:
	return _allows_step(from_tile, to_tile, false)


## Runtime callers must supply BOTH authoritative Registry passability results.
## Only the raw walkable flag is superseded; endpoint geometry stays canonical.
static func allows_registry_step(from_tile, to_tile, from_walkable: bool, to_walkable: bool) -> bool:
	return from_walkable and to_walkable and _allows_step(from_tile, to_tile, true)


static func _allows_step(from_tile, to_tile, registry_passable: bool) -> bool:
	if from_tile == null or to_tile == null: return false
	if from_tile.explicit_hex_ramps or to_tile.explicit_hex_ramps:
		if not from_tile.explicit_hex_ramps or not to_tile.explicit_hex_ramps: return false
		if not HEX_GRID_SCRIPT.are_neighbors(from_tile.grid_position, to_tile.grid_position): return false
		var from_height := _endpoint_height(from_tile, to_tile.grid_position, registry_passable)
		var to_height := _endpoint_height(to_tile, from_tile.grid_position, registry_passable)
		return is_finite(from_height) and is_finite(to_height) and is_equal_approx(from_height, to_height)
	if int(from_tile.height_level) == int(to_tile.height_level): return true
	var higher = from_tile if int(from_tile.height_level) > int(to_tile.height_level) else to_tile
	return _allows_height_transition(higher, to_tile if higher == from_tile else from_tile, registry_passable)


static func allows_height_transition(higher, lower) -> bool:
	return _allows_height_transition(higher, lower, false)


static func _allows_height_transition(higher, lower, registry_passable: bool) -> bool:
	if higher.explicit_hex_ramps or lower.explicit_hex_ramps:
		return _allows_step(higher, lower, registry_passable)
	var difference := int(higher.height_level) - int(lower.height_level)
	if higher.regional_grade and lower.regional_grade:
		return difference == 1 and (registry_passable or (higher.walkable and lower.walkable)) \
			and String(higher.object_type_id) != "glut_bridge_deck" \
			and String(lower.object_type_id) != "glut_bridge_deck"
	return String(higher.edge_type) == EDGE_SLOPE


static func get_surface_speed_factor(next_surface_type: String) -> float:
	match _normalize_surface_type(next_surface_type):
		SURFACE_ROAD:
			return 1.4
		SURFACE_SAND:
			return 0.6
		SURFACE_ROCK:
			return 0.8
		SURFACE_WATER:
			return 0.35
		_:
			return 1.0


static func get_surface_path_cost(next_surface_type: String) -> float:
	match _normalize_surface_type(next_surface_type):
		SURFACE_ROAD:
			return 0.7
		SURFACE_SAND:
			return 1.5
		SURFACE_ROCK:
			return 1.3
		SURFACE_WATER:
			return 4.0
		_:
			return 1.0


static func get_surface_short_code(next_surface_type: String) -> String:
	match _normalize_surface_type(next_surface_type):
		SURFACE_ROAD:
			return "RD"
		SURFACE_SAND:
			return "SND"
		SURFACE_ROCK:
			return "RCK"
		SURFACE_WATER:
			return "WTR"
		_:
			return "GND"


static func _normalize_edge_type(value: String) -> String:
	var normalized: String = value.strip_edges().to_lower()
	match normalized:
		EDGE_CLIFF, EDGE_SLOPE, EDGE_NONE:
			return normalized
		_:
			return EDGE_CLIFF


static func _normalize_surface_type(next_surface_type: String) -> String:
	var normalized_surface_type: String = next_surface_type.strip_edges().to_lower()
	if normalized_surface_type.is_empty():
		return DEFAULT_SURFACE_TYPE

	return normalized_surface_type


static func _is_surface_type_valid(next_surface_type: String) -> bool:
	match _normalize_surface_type(next_surface_type):
		SURFACE_GROUND, SURFACE_ROAD, SURFACE_SAND, SURFACE_ROCK, SURFACE_WATER:
			return true
		_:
			return false


func _apply_dict(data: Dictionary) -> void:
	tile_id = String(data.get("tile_id", ""))
	type_id = String(data.get("type_id", ""))
	object_type_id = String(data.get("object_type_id", ""))
	grid_position = _coerce_grid_position(data.get("grid_position", Vector2i.ZERO))
	world_position = _coerce_world_position(data.get("world_position", Vector2.ZERO))
	walkable = bool(data.get("walkable", DEFAULT_WALKABLE))
	blocks_los = bool(data.get("blocks_los", DEFAULT_BLOCKS_LOS))
	cover_value = clampi(int(data.get("cover_value", DEFAULT_COVER_VALUE)), 0, 100)
	height_level = clampi(int(data.get("height_level", DEFAULT_HEIGHT_LEVEL)), 0, MAX_HEIGHT_LEVEL)
	object_height = clampi(int(data.get("object_height", DEFAULT_OBJECT_HEIGHT)), 0, 3)
	object_rotation_degrees = _normalize_object_rotation_degrees(float(data.get("object_rotation_degrees", 0.0)))
	object_scale = _normalize_object_scale(float(data.get("object_scale", DEFAULT_OBJECT_SCALE)))
	surface_type = _normalize_surface_type(String(data.get("surface_type", DEFAULT_SURFACE_TYPE)))
	edge_type = _normalize_edge_type(String(data.get("edge_type", EDGE_CLIFF)))
	regional_grade = bool(data.get("regional_grade", false))
	explicit_hex_ramps = bool(data.get("explicit_hex_ramps", false))
	ramp_direction = int(data.get("ramp_direction", -1))


static func _normalize_object_rotation_degrees(value: float) -> float:
	var normalized: float = fposmod(value, 360.0)
	if absf(normalized - 360.0) < 0.001:
		return 0.0
	return snappedf(normalized, 0.001)


static func _normalize_object_scale(value: float) -> float:
	if is_nan(value) or is_inf(value):
		return DEFAULT_OBJECT_SCALE
	return snappedf(clampf(value, MIN_OBJECT_SCALE, MAX_OBJECT_SCALE), 0.001)


func _coerce_grid_position(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value

	if value is Vector2:
		return Vector2i(roundi((value as Vector2).x), roundi((value as Vector2).y))

	return Vector2i.ZERO


func _coerce_world_position(value: Variant) -> Vector2:
	if value is Vector2:
		return value

	if value is Vector2i:
		return Vector2(value.x, value.y)

	return Vector2.ZERO
