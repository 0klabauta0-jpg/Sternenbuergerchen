class_name TerrainDefinition
extends RefCounted

const ORIENTATION_NONE: String = ""
const ORIENTATION_N: String = "N"
const ORIENTATION_NE: String = "NE"
const ORIENTATION_E: String = "E"
const ORIENTATION_SE: String = "SE"
const ORIENTATION_S: String = "S"
const ORIENTATION_SW: String = "SW"
const ORIENTATION_W: String = "W"
const ORIENTATION_NW: String = "NW"
const ALLOWED_ORIENTATIONS: PackedStringArray = [
	ORIENTATION_NONE,
	ORIENTATION_N,
	ORIENTATION_NE,
	ORIENTATION_E,
	ORIENTATION_SE,
	ORIENTATION_S,
	ORIENTATION_SW,
	ORIENTATION_W,
	ORIENTATION_NW,
]

var terrain_id: String = ""
var source_asset_path: String = ""
var orientation: String = ORIENTATION_NONE
var walkable: bool = false
var blocks_los: bool = false
var cover_value: float = 0.0
var speed_multiplier: float = 1.0


func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		_apply_dict(data)


static func from_dict(data: Dictionary) -> TerrainDefinition:
	var script_ref: GDScript = load("res://scripts/terrain/terrain_definition.gd")
	return script_ref.new(data)


static func is_allowed_orientation(value: String) -> bool:
	return ALLOWED_ORIENTATIONS.has(value)


func is_valid() -> bool:
	if terrain_id.is_empty():
		return false

	if source_asset_path.is_empty():
		return false

	if not is_allowed_orientation(orientation):
		return false

	return speed_multiplier > 0.0


func to_dict() -> Dictionary:
	return {
		"terrain_id": terrain_id,
		"source_asset_path": source_asset_path,
		"orientation": orientation,
		"walkable": walkable,
		"blocks_los": blocks_los,
		"cover_value": cover_value,
		"speed_multiplier": speed_multiplier,
	}


func _apply_dict(data: Dictionary) -> void:
	if data.has("terrain_id"):
		terrain_id = String(data["terrain_id"])

	if data.has("source_asset_path"):
		source_asset_path = String(data["source_asset_path"])

	if data.has("orientation"):
		orientation = String(data["orientation"])

	if data.has("walkable"):
		walkable = bool(data["walkable"])

	if data.has("blocks_los"):
		blocks_los = bool(data["blocks_los"])

	if data.has("cover_value"):
		var raw_cover_value: Variant = data["cover_value"]
		if typeof(raw_cover_value) == TYPE_INT or typeof(raw_cover_value) == TYPE_FLOAT:
			cover_value = float(raw_cover_value)

	if data.has("speed_multiplier"):
		var raw_speed_multiplier: Variant = data["speed_multiplier"]
		if typeof(raw_speed_multiplier) == TYPE_INT or typeof(raw_speed_multiplier) == TYPE_FLOAT:
			speed_multiplier = float(raw_speed_multiplier)
