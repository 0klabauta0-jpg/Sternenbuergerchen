class_name ObjectiveStatus
extends RefCounted

var objective_id: String = ""
var position: Vector2 = Vector2.ZERO
var capture_radius: float = 80.0
var owning_team_id: String = ""
var capture_progress: float = 0.0
var capturing_team_id: String = ""
var countdown_seconds: float = -1.0
var countdown_total_seconds: float = -1.0
var timer_state: String = "none"
var timer_source: String = ""
var timer_label: String = ""

var _contested: bool = false


func is_captured() -> bool:
	return not owning_team_id.is_empty() and capture_progress >= 1.0


func is_contested() -> bool:
	return _contested


func set_contested(value: bool) -> void:
	_contested = value


func has_countdown() -> bool:
	var normalized_state: String = timer_state.strip_edges().to_lower()
	return not timer_source.strip_edges().is_empty() and (normalized_state == "active" or normalized_state == "paused" or normalized_state == "expired")


func set_countdown(seconds: float, state: String, source: String, total_seconds: float = -1.0, label: String = "") -> void:
	countdown_seconds = maxf(seconds, 0.0)
	countdown_total_seconds = maxf(total_seconds, countdown_seconds)
	timer_state = _normalize_timer_state(state)
	timer_source = source.strip_edges()
	timer_label = label.strip_edges()
	if timer_source.is_empty():
		clear_countdown()


func clear_countdown() -> void:
	countdown_seconds = -1.0
	countdown_total_seconds = -1.0
	timer_state = "none"
	timer_source = ""
	timer_label = ""


func get_countdown_snapshot() -> Dictionary:
	if not has_countdown():
		return {}
	return {
		"objective_id": objective_id,
		"countdown_seconds": maxf(countdown_seconds, 0.0),
		"countdown_total_seconds": maxf(countdown_total_seconds, maxf(countdown_seconds, 0.0)),
		"timer_state": timer_state,
		"timer_source": timer_source,
		"source": timer_source,
		"timer_label": timer_label,
		"urgency": _resolve_timer_urgency(),
		"visible": true,
	}


func to_dict() -> Dictionary:
	var result: Dictionary = {
		"objective_id": objective_id,
		"position": position,
		"capture_radius": capture_radius,
		"owning_team_id": owning_team_id,
		"capture_progress": capture_progress,
		"capturing_team_id": capturing_team_id,
		"contested": _contested,
	}
	var countdown: Dictionary = get_countdown_snapshot()
	for key in countdown.keys():
		result[key] = countdown[key]
	return result


func _normalize_timer_state(state: String) -> String:
	match state.strip_edges().to_lower():
		"active", "paused", "expired":
			return state.strip_edges().to_lower()
		_:
			return "none"


func _resolve_timer_urgency() -> String:
	if timer_state == "expired" or countdown_seconds <= 0.0:
		return "expired"
	var total_seconds: float = maxf(countdown_total_seconds, countdown_seconds)
	if countdown_seconds <= 10.0:
		return "critical"
	if countdown_seconds <= 30.0 or (total_seconds > 0.0 and countdown_seconds / total_seconds <= 0.25):
		return "warning"
	return "normal"
