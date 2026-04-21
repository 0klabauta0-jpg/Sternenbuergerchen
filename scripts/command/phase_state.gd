class_name PhaseState
extends RefCounted

const STATUS_PENDING: String = "pending"
const STATUS_ACTIVE: String = "active"
const STATUS_COMPLETED: String = "completed"
const STATUS_LOCKED: String = "locked"
const ALLOWED_STATUSES: PackedStringArray = [
	STATUS_PENDING,
	STATUS_ACTIVE,
	STATUS_COMPLETED,
	STATUS_LOCKED,
]

var phase_index: int = 0
var display_name: String = ""
var status: String = STATUS_PENDING
var is_editable: bool = true
var started_tick: int = -1
var completed_tick: int = -1
var metadata: Dictionary = {}


func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		_apply_dict(data)


static func from_dict(data: Dictionary) -> PhaseState:
	var script_ref: GDScript = load("res://scripts/command/phase_state.gd")
	return script_ref.new(data)


static func is_allowed_status(value: String) -> bool:
	return ALLOWED_STATUSES.has(value)


func is_valid() -> bool:
	if phase_index < 0:
		return false

	if not is_allowed_status(status):
		return false

	if started_tick < -1 or completed_tick < -1:
		return false

	if completed_tick >= 0 and started_tick > completed_tick and started_tick >= 0:
		return false

	return true


func to_dict() -> Dictionary:
	var data: Dictionary = {
		"phase_index": phase_index,
		"status": status,
		"is_editable": is_editable,
		"metadata": metadata.duplicate(true),
	}

	if not display_name.is_empty():
		data["display_name"] = display_name

	if started_tick >= 0:
		data["started_tick"] = started_tick

	if completed_tick >= 0:
		data["completed_tick"] = completed_tick

	return data


func _apply_dict(data: Dictionary) -> void:
	phase_index = maxi(int(data.get("phase_index", 0)), 0)
	display_name = String(data.get("display_name", "")).strip_edges()
	status = String(data.get("status", STATUS_PENDING)).strip_edges().to_lower()
	is_editable = bool(data.get("is_editable", true))
	started_tick = int(data.get("started_tick", -1))
	completed_tick = int(data.get("completed_tick", -1))
	metadata = Dictionary(data.get("metadata", {})).duplicate(true)