class_name MapFloorSlot
extends RefCounted

const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

var grid_position: Vector2i = Vector2i.ZERO
var floor_index: int = TERRAIN_TILE_DATA_SCRIPT.DEFAULT_FLOOR_INDEX
var tile_id: String = ""
var walkable: bool = TERRAIN_TILE_DATA_SCRIPT.DEFAULT_WALKABLE
var floor_height: float = TERRAIN_TILE_DATA_SCRIPT.DEFAULT_FLOOR_HEIGHT
var floor_links: Array = []


func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		_apply_dict(data)


static func from_tile_data(tile_data):
	if tile_data == null:
		return null
	var script_ref: GDScript = load("res://scripts/terrain/map_floor_slot.gd")
	return script_ref.new({
		"grid_position": Vector2i(tile_data.grid_position),
		"floor_index": int(tile_data.floor_index),
		"tile_id": String(tile_data.tile_id),
		"walkable": bool(tile_data.walkable),
		"floor_height": float(tile_data.floor_height),
		"floor_links": Array(tile_data.floor_links).duplicate(true),
	})


func is_valid() -> bool:
	return floor_index >= 0


func to_dict() -> Dictionary:
	return {
		"grid_position": grid_position,
		"floor_index": floor_index,
		"tile_id": tile_id,
		"walkable": walkable,
		"floor_height": floor_height,
		"floor_links": floor_links.duplicate(true),
	}


func _apply_dict(data: Dictionary) -> void:
	grid_position = _coerce_grid_position(data.get("grid_position", Vector2i.ZERO))
	floor_index = clampi(int(data.get("floor_index", TERRAIN_TILE_DATA_SCRIPT.DEFAULT_FLOOR_INDEX)), 0, TERRAIN_TILE_DATA_SCRIPT.MAX_FLOOR_INDEX)
	tile_id = String(data.get("tile_id", ""))
	walkable = bool(data.get("walkable", TERRAIN_TILE_DATA_SCRIPT.DEFAULT_WALKABLE))
	floor_height = clampf(float(data.get("floor_height", TERRAIN_TILE_DATA_SCRIPT.DEFAULT_FLOOR_HEIGHT)), 0.0, TERRAIN_TILE_DATA_SCRIPT.MAX_WORLD_HEIGHT)
	floor_links = _coerce_floor_links(data.get("floor_links", []))


func _coerce_floor_links(value: Variant) -> Array:
	var result: Array = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for link_variant in Array(value):
		var normalized_link: Dictionary = TERRAIN_TILE_DATA_SCRIPT.normalize_floor_link(link_variant)
		if normalized_link.is_empty():
			continue
		result.append(normalized_link)
	return result


func _coerce_grid_position(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		return Vector2i(roundi((value as Vector2).x), roundi((value as Vector2).y))
	if typeof(value) == TYPE_DICTIONARY:
		var value_dict: Dictionary = Dictionary(value)
		return Vector2i(int(value_dict.get("x", 0)), int(value_dict.get("y", 0)))
	return Vector2i.ZERO
