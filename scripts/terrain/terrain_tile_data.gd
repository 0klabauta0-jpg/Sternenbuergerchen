class_name TerrainTileData
extends RefCounted

const SURFACE_GROUND: String = "ground"
const SURFACE_ROAD: String = "road"
const SURFACE_SAND: String = "sand"
const SURFACE_ROCK: String = "rock"

const DEFAULT_WALKABLE: bool = true
const DEFAULT_BLOCKS_LOS: bool = false
const DEFAULT_COVER_VALUE: int = 0
const DEFAULT_HEIGHT_LEVEL: int = 0
const DEFAULT_OBJECT_HEIGHT: int = 0
const DEFAULT_FLOOR_HEIGHT: float = 0.0
const DEFAULT_UNIT_EYE_HEIGHT_BONUS: float = 0.0
const DEFAULT_COVER_HEIGHT: float = 0.0
const DEFAULT_BLOCKS_LOS_HEIGHT: float = 0.0
const DEFAULT_IS_ELEVATED_SURFACE: bool = false
const DEFAULT_SURFACE_TYPE: String = SURFACE_GROUND
const MAX_HEIGHT_LEVEL: int = 8
const MAX_OBJECT_HEIGHT: int = 8
const MAX_WORLD_HEIGHT: float = 64.0

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
var floor_height: float = DEFAULT_FLOOR_HEIGHT
var unit_eye_height_bonus: float = DEFAULT_UNIT_EYE_HEIGHT_BONUS
var cover_height: float = DEFAULT_COVER_HEIGHT
var blocks_los_height: float = DEFAULT_BLOCKS_LOS_HEIGHT
var is_elevated_surface: bool = DEFAULT_IS_ELEVATED_SURFACE
var surface_type: String = DEFAULT_SURFACE_TYPE
var edge_type: String = EDGE_CLIFF


func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		_apply_dict(data)


static func from_dict(data: Dictionary):
	var script_ref: GDScript = load("res://scripts/terrain/terrain_tile_data.gd")
	return script_ref.new(data)


func is_valid() -> bool:
	return not tile_id.is_empty() and _is_surface_type_valid(surface_type)


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
		"floor_height": floor_height,
		"unit_eye_height_bonus": unit_eye_height_bonus,
		"cover_height": cover_height,
		"blocks_los_height": blocks_los_height,
		"is_elevated_surface": is_elevated_surface,
		"surface_type": surface_type,
		"edge_type": edge_type,
	}


static func get_surface_speed_factor(next_surface_type: String) -> float:
	match _normalize_surface_type(next_surface_type):
		SURFACE_ROAD:
			return 1.4
		SURFACE_SAND:
			return 0.6
		SURFACE_ROCK:
			return 0.8
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
		SURFACE_GROUND, SURFACE_ROAD, SURFACE_SAND, SURFACE_ROCK:
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
	object_height = clampi(int(data.get("object_height", DEFAULT_OBJECT_HEIGHT)), 0, MAX_OBJECT_HEIGHT)
	floor_height = _coerce_height_float(data.get("floor_height", float(height_level)))
	unit_eye_height_bonus = _coerce_height_float(data.get("unit_eye_height_bonus", DEFAULT_UNIT_EYE_HEIGHT_BONUS))
	cover_height = _coerce_height_float(data.get("cover_height", _derive_cover_height()))
	blocks_los_height = _coerce_height_float(data.get("blocks_los_height", _derive_blocks_los_height()))
	is_elevated_surface = bool(data.get("is_elevated_surface", floor_height > 0.0 or height_level > 0))
	surface_type = _normalize_surface_type(String(data.get("surface_type", DEFAULT_SURFACE_TYPE)))
	edge_type = _normalize_edge_type(String(data.get("edge_type", EDGE_CLIFF)))


func _derive_cover_height() -> float:
	if cover_value <= 0:
		return DEFAULT_COVER_HEIGHT
	return maxf(float(object_height), 0.5)


func _derive_blocks_los_height() -> float:
	if not blocks_los:
		return DEFAULT_BLOCKS_LOS_HEIGHT
	return maxf(maxf(float(height_level), float(object_height)), cover_height)


func _coerce_height_float(value: Variant) -> float:
	if value == null:
		return 0.0
	return clampf(float(value), 0.0, MAX_WORLD_HEIGHT)


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
