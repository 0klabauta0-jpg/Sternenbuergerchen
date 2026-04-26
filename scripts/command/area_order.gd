class_name AreaOrder
extends RefCounted

const COMMAND_TYPE_DEFEND: String = "defend"
const COMMAND_TYPE_ENGAGE: String = "engage"
const COMMAND_TYPE_TAKE: String = "take"
const COMMAND_TYPE_FLANK: String = "flank"
const STATUS_PENDING: String = "pending"
const STATUS_ACTIVE: String = "active"
const STATUS_COMPLETED: String = "completed"
const STATUS_CANCELLED: String = "cancelled"
const ALLOWED_COMMAND_TYPES: PackedStringArray = [
	COMMAND_TYPE_DEFEND,
	COMMAND_TYPE_ENGAGE,
	COMMAND_TYPE_TAKE,
	COMMAND_TYPE_FLANK,
]
const ALLOWED_STATUSES: PackedStringArray = [
	STATUS_PENDING,
	STATUS_ACTIVE,
	STATUS_COMPLETED,
	STATUS_CANCELLED,
]

var area_order_id: String = ""
var fireteam_id: String = ""
var command_type: String = COMMAND_TYPE_DEFEND
var tile_positions: Array = []
var tile_world_positions: Array = []
var world_polygon: PackedVector2Array = PackedVector2Array()
var center_position: Variant = null
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
	return ALLOWED_COMMAND_TYPES.has(value)


static func is_allowed_status(value: String) -> bool:
	return ALLOWED_STATUSES.has(value)


func is_valid() -> bool:
	if area_order_id.is_empty() or fireteam_id.is_empty():
		return false
	if not is_allowed_command_type(command_type):
		return false
	if not is_allowed_status(status):
		return false
	if created_at_order_index < 0:
		return false
	if typeof(center_position) != TYPE_VECTOR2:
		return false
	return not tile_positions.is_empty() or not world_polygon.is_empty()


func to_dict() -> Dictionary:
	var data: Dictionary = {
		"area_order_id": area_order_id,
		"fireteam_id": fireteam_id,
		"command_type": command_type,
		"center_position": center_position,
		"created_at_order_index": created_at_order_index,
		"status": status,
		"metadata": metadata.duplicate(true),
	}
	if not tile_positions.is_empty():
		data["tile_positions"] = tile_positions.duplicate(true)
	if not tile_world_positions.is_empty():
		data["tile_world_positions"] = tile_world_positions.duplicate(true)
	if not world_polygon.is_empty():
		data["world_polygon"] = world_polygon
	return data


func _apply_dict(data: Dictionary) -> void:
	area_order_id = String(data.get("area_order_id", "")).strip_edges()
	fireteam_id = String(data.get("fireteam_id", "")).strip_edges().to_lower()
	command_type = String(data.get("command_type", COMMAND_TYPE_DEFEND)).strip_edges().to_lower()
	status = String(data.get("status", STATUS_PENDING)).strip_edges().to_lower()
	created_at_order_index = maxi(int(data.get("created_at_order_index", 0)), 0)
	center_position = _coerce_world_position(data.get("center_position", null))
	metadata = Dictionary(data.get("metadata", {})).duplicate(true)

	tile_positions.clear()
	for tile_position_variant in Array(data.get("tile_positions", [])):
		tile_positions.append(_coerce_tile_position(tile_position_variant))

	tile_world_positions.clear()
	for world_position_variant in Array(data.get("tile_world_positions", [])):
		var world_position: Variant = _coerce_world_position(world_position_variant)
		if typeof(world_position) == TYPE_VECTOR2:
			tile_world_positions.append(world_position)

	world_polygon = PackedVector2Array()
	var polygon_variant: Variant = data.get("world_polygon", PackedVector2Array())
	for polygon_point_variant in Array(polygon_variant):
		var polygon_point: Variant = _coerce_world_position(polygon_point_variant)
		if typeof(polygon_point) == TYPE_VECTOR2:
			world_polygon.append(polygon_point)


func _coerce_tile_position(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		return Vector2i(roundi((value as Vector2).x), roundi((value as Vector2).y))
	if typeof(value) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(value)
		return Vector2i(int(dict.get("x", 0)), int(dict.get("y", 0)))
	return Vector2i.ZERO


func _coerce_world_position(value: Variant) -> Variant:
	if value is Vector2:
		return value
	if value is Vector2i:
		return Vector2(value.x, value.y)
	if typeof(value) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(value)
		return Vector2(float(dict.get("x", 0.0)), float(dict.get("y", 0.0)))
	return null
