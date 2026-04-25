class_name AreaOrder
extends RefCounted

const COMMAND_TYPE_MOVE: String = "move"
const COMMAND_TYPE_DEFEND: String = "defend"
const COMMAND_TYPE_ENGAGE: String = "engage"
const COMMAND_TYPE_FLANK: String = "flank"
const COMMAND_TYPE_TAKE: String = "take"
const STATUS_PENDING: String = "pending"
const STATUS_ACTIVE: String = "active"
const STATUS_COMPLETED: String = "completed"
const STATUS_INTERRUPTED: String = "interrupted"
const STATUS_CANCELLED: String = "cancelled"
const ALLOWED_COMMAND_TYPES: PackedStringArray = [
	COMMAND_TYPE_MOVE,
	COMMAND_TYPE_DEFEND,
	COMMAND_TYPE_ENGAGE,
	COMMAND_TYPE_FLANK,
	COMMAND_TYPE_TAKE,
]
const ALLOWED_STATUSES: PackedStringArray = [
	STATUS_PENDING,
	STATUS_ACTIVE,
	STATUS_COMPLETED,
	STATUS_INTERRUPTED,
	STATUS_CANCELLED,
]

var area_order_id: String = ""
var fireteam_id: String = ""
var command_type: String = COMMAND_TYPE_DEFEND
var tile_positions: Array = []
var world_polygon: PackedVector2Array = PackedVector2Array()
var center_position: Vector2 = Vector2.ZERO
var created_at_order_index: int = 0
var status: String = STATUS_PENDING
var metadata: Dictionary = {}


func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		_apply_dict(data)


static func from_dict(data: Dictionary) -> AreaOrder:
	var script_ref: GDScript = load("res://scripts/command/area_order.gd")
	return script_ref.new(data)


static func is_allowed_command_type(value: String) -> bool:
	return ALLOWED_COMMAND_TYPES.has(value.strip_edges().to_lower())


static func is_allowed_status(value: String) -> bool:
	return ALLOWED_STATUSES.has(value.strip_edges().to_lower())


func is_valid() -> bool:
	if area_order_id.strip_edges().is_empty():
		return false
	if fireteam_id.strip_edges().is_empty():
		return false
	if not is_allowed_command_type(command_type):
		return false
	if not is_allowed_status(status):
		return false
	if created_at_order_index < 0:
		return false
	if not center_position.is_finite():
		return false
	return not tile_positions.is_empty() or world_polygon.size() >= 3


func to_dict() -> Dictionary:
	var serialized_tiles: Array = []
	for tile_position in tile_positions:
		var grid_position: Vector2i = _coerce_vector2i(tile_position)
		serialized_tiles.append({"x": grid_position.x, "y": grid_position.y})

	var serialized_polygon: Array = []
	for point in world_polygon:
		serialized_polygon.append({"x": point.x, "y": point.y})

	return {
		"area_order_id": area_order_id,
		"fireteam_id": fireteam_id,
		"command_type": command_type,
		"tile_positions": serialized_tiles,
		"world_polygon": serialized_polygon,
		"center_position": center_position,
		"tile_count": tile_positions.size(),
		"created_at_order_index": created_at_order_index,
		"status": status,
		"metadata": metadata.duplicate(true),
	}


func _apply_dict(data: Dictionary) -> void:
	area_order_id = String(data.get("area_order_id", area_order_id)).strip_edges()
	fireteam_id = String(data.get("fireteam_id", fireteam_id)).strip_edges().to_lower()
	command_type = String(data.get("command_type", command_type)).strip_edges().to_lower()
	status = String(data.get("status", status)).strip_edges().to_lower()
	center_position = _coerce_vector2(data.get("center_position", center_position), center_position)
	if data.has("created_at_order_index"):
		var raw_order_index: Variant = data.get("created_at_order_index")
		if typeof(raw_order_index) == TYPE_INT or typeof(raw_order_index) == TYPE_FLOAT:
			created_at_order_index = maxi(int(raw_order_index), 0)
	metadata = Dictionary(data.get("metadata", {})).duplicate(true)

	tile_positions.clear()
	for tile_variant in Array(data.get("tile_positions", [])):
		tile_positions.append(_coerce_vector2i(tile_variant))

	var polygon_points: Array = []
	for point_variant in Array(data.get("world_polygon", [])):
		polygon_points.append(_coerce_vector2(point_variant, Vector2.ZERO))
	world_polygon = PackedVector2Array(polygon_points)


static func _coerce_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Vector2i:
		return Vector2(value.x, value.y)
	if typeof(value) == TYPE_DICTIONARY:
		var value_dict: Dictionary = value
		return Vector2(float(value_dict.get("x", fallback.x)), float(value_dict.get("y", fallback.y)))
	return fallback


static func _coerce_vector2i(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		return Vector2i(roundi(value.x), roundi(value.y))
	if typeof(value) == TYPE_DICTIONARY:
		var value_dict: Dictionary = value
		return Vector2i(int(value_dict.get("x", 0)), int(value_dict.get("y", 0)))
	return Vector2i.ZERO
