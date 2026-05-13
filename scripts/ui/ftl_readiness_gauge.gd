class_name FTLReadinessGauge
extends Control

const DEFAULT_SIZE: Vector2 = Vector2(42.0, 38.0)
const MIN_REACTION_DELAY_SECONDS: float = 0.05
const MAX_REACTION_DELAY_SECONDS: float = 0.85

var _snapshot: Dictionary = {}
var _diagnostic: Dictionary = {}


func _ready() -> void:
	custom_minimum_size = DEFAULT_SIZE
	size = DEFAULT_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refresh_diagnostic()


func set_snapshot(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	_refresh_diagnostic()
	queue_redraw()


func get_gauge_snapshot() -> Dictionary:
	return _diagnostic.duplicate(true)


func _draw() -> void:
	var center := Vector2(16.0, 19.0)
	var plan_available: bool = bool(_diagnostic.get("plan_quality_available", false))
	var morale_available: bool = bool(_diagnostic.get("morale_available", false))
	var reaction_available: bool = bool(_diagnostic.get("reaction_delay_seconds_available", false))
	var plan_quality: float = float(_diagnostic.get("plan_quality", 0.0))
	var morale: float = float(_diagnostic.get("morale", 0.0))
	var reaction_ratio: float = float(_diagnostic.get("reaction_ratio", 0.0))

	draw_circle(center, 17.0, Color(0.04, 0.07, 0.08, 0.72))
	draw_arc(center, 15.0, -PI * 0.5, PI * 1.5, 32, Color(0.19, 0.23, 0.25, 0.95), 3.0, true)
	if plan_available:
		draw_arc(center, 15.0, -PI * 0.5, -PI * 0.5 + TAU * plan_quality, 32, _plan_color(plan_quality), 3.0, true)
	else:
		draw_arc(center, 15.0, -PI * 0.5, PI * 1.5, 20, Color(0.34, 0.36, 0.38, 0.72), 2.0, true)

	draw_arc(center, 9.0, -PI * 0.5, PI * 1.5, 24, Color(0.17, 0.19, 0.20, 0.88), 2.0, true)
	if morale_available:
		draw_arc(center, 9.0, -PI * 0.5, -PI * 0.5 + TAU * morale, 24, _morale_color(morale), 2.0, true)
	else:
		draw_arc(center, 9.0, -PI * 0.5, PI * 1.5, 16, Color(0.34, 0.36, 0.38, 0.70), 1.5, true)

	for index in range(3):
		var x: float = 32.0 + float(index) * 3.2
		var bar_height: float = 8.0 + float(index) * 4.0
		var bar_rect := Rect2(Vector2(x, 28.0 - bar_height), Vector2(2.4, bar_height))
		var fill_threshold: float = (float(index) + 1.0) / 3.0
		var color: Color = Color(0.24, 0.28, 0.30, 0.95)
		if reaction_available and reaction_ratio >= fill_threshold - 0.001:
			color = _reaction_color(reaction_ratio)
		draw_rect(bar_rect, color, true)

	if not plan_available and not morale_available and not reaction_available:
		draw_line(center + Vector2(-6.0, 0.0), center + Vector2(6.0, 0.0), Color(0.62, 0.66, 0.68, 0.90), 1.5)


func _refresh_diagnostic() -> void:
	var plan_available: bool = bool(_snapshot.get("plan_quality_available", _snapshot.has("plan_quality") and _snapshot.get("plan_quality") != null))
	var morale_available: bool = bool(_snapshot.get("morale_available", _snapshot.has("morale") and _snapshot.get("morale") != null))
	var reaction_available: bool = bool(_snapshot.get("reaction_delay_seconds_available", _snapshot.has("reaction_delay_seconds") and _snapshot.get("reaction_delay_seconds") != null))
	var plan_quality: float = clampf(float(_snapshot.get("plan_quality", 0.0)) if plan_available else 0.0, 0.0, 1.0)
	var morale: float = clampf(float(_snapshot.get("morale", 0.0)) if morale_available else 0.0, 0.0, 1.0)
	var reaction_delay: float = clampf(float(_snapshot.get("reaction_delay_seconds", MAX_REACTION_DELAY_SECONDS)) if reaction_available else MAX_REACTION_DELAY_SECONDS, MIN_REACTION_DELAY_SECONDS, MAX_REACTION_DELAY_SECONDS)
	var reaction_ratio: float = 1.0 - clampf((reaction_delay - MIN_REACTION_DELAY_SECONDS) / (MAX_REACTION_DELAY_SECONDS - MIN_REACTION_DELAY_SECONDS), 0.0, 1.0)
	var readiness_score: float = _calculate_readiness_score(plan_quality, morale, reaction_ratio, plan_available, morale_available, reaction_available)
	_diagnostic = {
		"fireteam_id": String(_snapshot.get("fireteam_id", "")).strip_edges().to_lower(),
		"leader_name": String(_snapshot.get("leader_name", "FTL")).strip_edges(),
		"plan_quality": plan_quality,
		"plan_quality_available": plan_available,
		"morale": morale,
		"morale_available": morale_available,
		"reaction_delay_seconds": reaction_delay if reaction_available else null,
		"reaction_delay_seconds_available": reaction_available,
		"reaction_ratio": reaction_ratio if reaction_available else 0.0,
		"readiness_score": readiness_score,
		"display_state": _display_state(readiness_score, plan_available, morale_available, reaction_available),
		"fixed_size": DEFAULT_SIZE,
		"read_only": true,
	}
	tooltip_text = _build_tooltip_text()


func _calculate_readiness_score(plan_quality: float, morale: float, reaction_ratio: float, plan_available: bool, morale_available: bool, reaction_available: bool) -> float:
	var total: float = 0.0
	var weight: float = 0.0
	if plan_available:
		total += plan_quality * 0.42
		weight += 0.42
	if morale_available:
		total += morale * 0.28
		weight += 0.28
	if reaction_available:
		total += reaction_ratio * 0.30
		weight += 0.30
	if weight <= 0.0:
		return -1.0
	return clampf(total / weight, 0.0, 1.0)


func _display_state(score: float, plan_available: bool, morale_available: bool, reaction_available: bool) -> String:
	if not plan_available and not morale_available and not reaction_available:
		return "unavailable"
	if score >= 0.70:
		return "high"
	if score <= 0.38:
		return "low"
	return "medium"


func _build_tooltip_text() -> String:
	var state: String = String(_diagnostic.get("display_state", "unavailable")).to_upper()
	var leader_name: String = String(_diagnostic.get("leader_name", "FTL")).strip_edges()
	if leader_name.is_empty():
		leader_name = "FTL"
	return "%s | %s" % [leader_name, state]


func _plan_color(value: float) -> Color:
	return Color(0.95, 0.42, 0.30, 0.95).lerp(Color(0.38, 0.92, 0.68, 0.95), clampf(value, 0.0, 1.0))


func _morale_color(value: float) -> Color:
	return Color(0.88, 0.36, 0.46, 0.92).lerp(Color(0.52, 0.78, 1.0, 0.92), clampf(value, 0.0, 1.0))


func _reaction_color(value: float) -> Color:
	return Color(0.68, 0.74, 0.78, 0.92).lerp(Color(0.88, 0.94, 1.0, 0.96), clampf(value, 0.0, 1.0))
