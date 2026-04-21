class_name AdHocOrder
extends RefCounted

const ORDER_TYPE_FLANK: String = "flank"
const ORDER_TYPE_DISENGAGE: String = "disengage"
const ORDER_TYPE_FALL_BACK: String = "fall_back"
const ORDER_TYPE_FOCUS_FIRE: String = "focus_fire"
const ORDER_TYPE_HOLD_TILL_LAST_MAN: String = "hold_till_last_man"
const STATUS_PENDING: String = "pending"
const STATUS_ACTIVE: String = "active"
const STATUS_COMPLETED: String = "completed"
const STATUS_CANCELLED: String = "cancelled"
const ALLOWED_ORDER_TYPES: PackedStringArray = [
	ORDER_TYPE_FLANK,
	ORDER_TYPE_DISENGAGE,
	ORDER_TYPE_FALL_BACK,
	ORDER_TYPE_FOCUS_FIRE,
	ORDER_TYPE_HOLD_TILL_LAST_MAN,
]
const ALLOWED_STATUSES: PackedStringArray = [
	STATUS_PENDING,
	STATUS_ACTIVE,
	STATUS_COMPLETED,
	STATUS_CANCELLED,
]

var order_id: String = ""
var fireteam_id: String = ""
var order_type: String = ORDER_TYPE_FLANK
var status: String = STATUS_PENDING
var target_position: Variant = null
var target_unit_id: String = ""
var resume_plan_after: bool = true
var source_phase: int = -1
var metadata: Dictionary = {}


func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		_apply_dict(data)


static func from_dict(data: Dictionary) -> AdHocOrder:
	var script_ref: GDScript = load("res://scripts/command/ad_hoc_order.gd")
	return script_ref.new(data)


static func is_allowed_order_type(value: String) -> bool:
	return ALLOWED_ORDER_TYPES.has(value)


static func is_allowed_status(value: String) -> bool:
	return ALLOWED_STATUSES.has(value)


func is_valid() -> bool:
	if fireteam_id.is_empty():
		return false

	if not is_allowed_order_type(order_type):
		return false

	if not is_allowed_status(status):
		return false

	if source_phase < -1:
		return false

	if not _has_valid_target_position():
		return false

	return target_position != null or not target_unit_id.is_empty() or order_type == ORDER_TYPE_HOLD_TILL_LAST_MAN


func to_dict() -> Dictionary:
	var data: Dictionary = {
		"fireteam_id": fireteam_id,
		"order_type": order_type,
		"status": status,
		"resume_plan_after": resume_plan_after,
		"metadata": metadata.duplicate(true),
	}

	if not order_id.is_empty():
		data["order_id"] = order_id

	if target_position != null:
		data["target_position"] = target_position

	if not target_unit_id.is_empty():
		data["target_unit_id"] = target_unit_id

	if source_phase >= 0:
		data["source_phase"] = source_phase

	return data


func _apply_dict(data: Dictionary) -> void:
	order_id = String(data.get("order_id", "")).strip_edges()
	fireteam_id = String(data.get("fireteam_id", "")).strip_edges().to_lower()
	order_type = String(data.get("order_type", ORDER_TYPE_FLANK)).strip_edges().to_lower()
	status = String(data.get("status", STATUS_PENDING)).strip_edges().to_lower()
	if data.has("target_position"):
		target_position = data["target_position"]
	target_unit_id = String(data.get("target_unit_id", "")).strip_edges()
	resume_plan_after = bool(data.get("resume_plan_after", true))
	source_phase = int(data.get("source_phase", -1))
	metadata = Dictionary(data.get("metadata", {})).duplicate(true)


func _has_valid_target_position() -> bool:
	if target_position == null:
		return true

	var value_type: int = typeof(target_position)
	return value_type == TYPE_VECTOR2 or value_type == TYPE_VECTOR2I or value_type == TYPE_VECTOR3