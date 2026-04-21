class_name FireteamOrderPlan
extends RefCounted

const FIRETEAM_WAYPOINT_SCRIPT: GDScript = preload("res://scripts/command/fireteam_waypoint.gd")
const STATUS_DRAFT: String = "draft"
const STATUS_PENDING: String = "pending"
const STATUS_ACTIVE: String = "active"
const STATUS_COMPLETED: String = "completed"
const STATUS_INTERRUPTED: String = "interrupted"
const STATUS_CANCELLED: String = "cancelled"
const ALLOWED_STATUSES: PackedStringArray = [
	STATUS_DRAFT,
	STATUS_PENDING,
	STATUS_ACTIVE,
	STATUS_COMPLETED,
	STATUS_INTERRUPTED,
	STATUS_CANCELLED,
]

var plan_id: String = ""
var fireteam_id: String = ""
var phase: int = 0
var status: String = STATUS_DRAFT
var waypoints: Array = []
var active_waypoint_index: int = -1
var metadata: Dictionary = {}


func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		_apply_dict(data)


static func from_dict(data: Dictionary) -> FireteamOrderPlan:
	var script_ref: GDScript = load("res://scripts/command/fireteam_order_plan.gd")
	return script_ref.new(data)


static func is_allowed_status(value: String) -> bool:
	return ALLOWED_STATUSES.has(value)


func is_valid() -> bool:
	if fireteam_id.is_empty():
		return false

	if phase < 0:
		return false

	if not is_allowed_status(status):
		return false

	if active_waypoint_index < -1:
		return false

	if active_waypoint_index >= waypoints.size() and active_waypoint_index != -1:
		return false

	for waypoint_variant in waypoints:
		var waypoint = _coerce_waypoint(waypoint_variant)
		if waypoint == null or not bool(waypoint.call("is_valid")):
			return false

	return true


func to_dict() -> Dictionary:
	var waypoint_dicts: Array = []
	for waypoint_variant in waypoints:
		var waypoint = _coerce_waypoint(waypoint_variant)
		if waypoint == null:
			continue
		waypoint_dicts.append(waypoint.call("to_dict"))

	var data: Dictionary = {
		"fireteam_id": fireteam_id,
		"phase": phase,
		"status": status,
		"waypoints": waypoint_dicts,
		"active_waypoint_index": active_waypoint_index,
		"metadata": metadata.duplicate(true),
	}

	if not plan_id.is_empty():
		data["plan_id"] = plan_id

	return data


func _apply_dict(data: Dictionary) -> void:
	if data.has("plan_id"):
		plan_id = String(data["plan_id"]).strip_edges()

	if data.has("fireteam_id"):
		fireteam_id = String(data["fireteam_id"]).strip_edges().to_lower()

	if data.has("phase"):
		var raw_phase: Variant = data["phase"]
		if typeof(raw_phase) == TYPE_INT or typeof(raw_phase) == TYPE_FLOAT:
			phase = int(raw_phase)

	if data.has("status"):
		status = String(data["status"]).strip_edges().to_lower()

	if data.has("active_waypoint_index"):
		var raw_waypoint_index: Variant = data["active_waypoint_index"]
		if typeof(raw_waypoint_index) == TYPE_INT or typeof(raw_waypoint_index) == TYPE_FLOAT:
			active_waypoint_index = int(raw_waypoint_index)

	waypoints.clear()
	for waypoint_variant in Array(data.get("waypoints", [])):
		var waypoint = _coerce_waypoint(waypoint_variant)
		if waypoint != null:
			waypoints.append(waypoint)

	metadata = Dictionary(data.get("metadata", {})).duplicate(true)


func _coerce_waypoint(value: Variant):
	if value == null:
		return null
	if value is RefCounted and value.has_method("is_valid") and value.has_method("to_dict"):
		return value
	if typeof(value) == TYPE_DICTIONARY:
		return FIRETEAM_WAYPOINT_SCRIPT.call("from_dict", value)
	return null