class_name ObjectiveStatus
extends RefCounted

var objective_id: String = ""
var position: Vector2 = Vector2.ZERO
var capture_radius: float = 80.0
var owning_team_id: String = ""
var capture_progress: float = 0.0
var capturing_team_id: String = ""

var _contested: bool = false


func is_captured() -> bool:
	return not owning_team_id.is_empty() and capture_progress >= 1.0


func is_contested() -> bool:
	return _contested


func set_contested(value: bool) -> void:
	_contested = value


func to_dict() -> Dictionary:
	return {
		"objective_id": objective_id,
		"position": position,
		"capture_radius": capture_radius,
		"owning_team_id": owning_team_id,
		"capture_progress": capture_progress,
		"capturing_team_id": capturing_team_id,
		"contested": _contested,
	}
