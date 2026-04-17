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
const DEFAULT_SURFACE_TYPE: String = SURFACE_GROUND

var tile_id: String = ""
var type_id: String = ""
var grid_position: Vector2i = Vector2i.ZERO
var world_position: Vector2 = Vector2.ZERO
var walkable: bool = DEFAULT_WALKABLE
var blocks_los: bool = DEFAULT_BLOCKS_LOS
var cover_value: int = DEFAULT_COVER_VALUE
var height_level: int = DEFAULT_HEIGHT_LEVEL
var surface_type: String = DEFAULT_SURFACE_TYPE


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
		"grid_position": grid_position,
		"world_position": world_position,
		"walkable": walkable,
		"blocks_los": blocks_los,
		"cover_value": cover_value,
		"height_level": height_level,
		"surface_type": surface_type,
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
	grid_position = _coerce_grid_position(data.get("grid_position", Vector2i.ZERO))
	world_position = _coerce_world_position(data.get("world_position", Vector2.ZERO))
	walkable = bool(data.get("walkable", DEFAULT_WALKABLE))
	blocks_los = bool(data.get("blocks_los", DEFAULT_BLOCKS_LOS))
	cover_value = clampi(int(data.get("cover_value", DEFAULT_COVER_VALUE)), 0, 100)
	height_level = clampi(int(data.get("height_level", DEFAULT_HEIGHT_LEVEL)), 0, 2)
	surface_type = _normalize_surface_type(String(data.get("surface_type", DEFAULT_SURFACE_TYPE)))


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
