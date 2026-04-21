class_name FireteamOrderVisualizer
extends Node2D

const FIRETEAM_ORDER_PLAN_SCRIPT: GDScript = preload("res://scripts/command/fireteam_order_plan.gd")
const FIRETEAM_WAYPOINT_SCRIPT: GDScript = preload("res://scripts/command/fireteam_waypoint.gd")
const MARKER_RADIUS: float = 12.0
const HIT_RADIUS: float = 16.0
const WAYPOINT_OFFSET_STEP: float = 7.0

var _phase_index: int = 0
var _selected_fireteam_ids: PackedStringArray = []
var _plan_dicts: Array = []
var _visible_waypoints: Array = []


func set_phase_index(phase_index: int) -> void:
	_phase_index = maxi(phase_index, 0)
	_rebuild_cache()


func set_selected_fireteam_ids(selected_fireteam_ids: PackedStringArray) -> void:
	_selected_fireteam_ids = selected_fireteam_ids.duplicate()
	queue_redraw()


func set_plan_dicts(plan_dicts: Array) -> void:
	_plan_dicts = []
	for plan_variant in plan_dicts:
		if typeof(plan_variant) == TYPE_DICTIONARY:
			_plan_dicts.append(Dictionary(plan_variant).duplicate(true))
	_rebuild_cache()


func get_visible_waypoints() -> Array:
	var result: Array = []
	for waypoint_data in _visible_waypoints:
		result.append(Dictionary(waypoint_data).duplicate(true))
	return result


func get_waypoint_hit(screen_position: Vector2, canvas_transform: Transform2D) -> Dictionary:
	for waypoint_data in _visible_waypoints:
		var marker_screen_position: Vector2 = canvas_transform * Vector2(waypoint_data.get("position", Vector2.ZERO))
		if marker_screen_position.distance_to(screen_position) <= HIT_RADIUS:
			return Dictionary(waypoint_data).duplicate(true)
	return {}


func _draw() -> void:
	for plan_dict in _plan_dicts:
		var plan = FIRETEAM_ORDER_PLAN_SCRIPT.call("from_dict", plan_dict)
		if plan == null or not plan.is_valid() or int(plan.phase) != _phase_index:
			continue
		_draw_plan(plan)


func _draw_plan(plan) -> void:
	var fireteam_id: String = String(plan.fireteam_id).strip_edges().to_lower()
	var marker_offset: Vector2 = _get_marker_offset(fireteam_id)
	var base_color: Color = _get_fireteam_color(fireteam_id)
	var draw_color: Color = base_color if _selected_fireteam_ids.is_empty() or _selected_fireteam_ids.has(fireteam_id) else base_color.darkened(0.45)
	if not _selected_fireteam_ids.is_empty() and not _selected_fireteam_ids.has(fireteam_id):
		draw_color.a = 0.55

	var points: PackedVector2Array = []
	for waypoint_variant in plan.waypoints:
		var waypoint = _coerce_waypoint(waypoint_variant)
		if waypoint == null or waypoint.target_position == null:
			continue
		var point := Vector2(waypoint.target_position) + marker_offset
		points.append(point)

	if points.size() >= 2:
		draw_polyline(points, draw_color, 3.0, true)

	for index in range(points.size()):
		var waypoint = _coerce_waypoint(plan.waypoints[index])
		if waypoint == null:
			continue
		_draw_waypoint_symbol(points[index], String(waypoint.command_type), draw_color, index)


func _draw_waypoint_symbol(position: Vector2, command_type: String, marker_color: Color, index: int) -> void:
	match command_type:
		"defend":
			draw_rect(Rect2(position - Vector2(10.0, 10.0), Vector2(20.0, 20.0)), marker_color, true)
		"engage":
			draw_circle(position, MARKER_RADIUS, marker_color)
			draw_line(position + Vector2(-8.0, 0.0), position + Vector2(8.0, 0.0), Color(0.05, 0.07, 0.08, 0.9), 2.0)
			draw_line(position + Vector2(0.0, -8.0), position + Vector2(0.0, 8.0), Color(0.05, 0.07, 0.08, 0.9), 2.0)
		"flank":
			draw_colored_polygon(PackedVector2Array([
				position + Vector2(0.0, -12.0),
				position + Vector2(11.0, 0.0),
				position + Vector2(0.0, 12.0),
				position + Vector2(-11.0, 0.0),
			]), marker_color)
		"take":
			draw_line(position + Vector2(-10.0, 10.0), position + Vector2(10.0, -10.0), marker_color, 4.0)
			draw_line(position + Vector2(-10.0, -10.0), position + Vector2(10.0, 10.0), marker_color, 4.0)
		_:
			draw_circle(position, MARKER_RADIUS, marker_color)
	var index_color := Color(0.03, 0.05, 0.06, 0.92)
	draw_circle(position, 4.0, index_color)
	if index > 0:
		draw_circle(position + Vector2(8.0, -8.0), 3.0, index_color)


func _rebuild_cache() -> void:
	_visible_waypoints.clear()
	for plan_dict in _plan_dicts:
		var plan = FIRETEAM_ORDER_PLAN_SCRIPT.call("from_dict", plan_dict)
		if plan == null or not plan.is_valid() or int(plan.phase) != _phase_index:
			continue
		var fireteam_id: String = String(plan.fireteam_id).strip_edges().to_lower()
		var marker_offset: Vector2 = _get_marker_offset(fireteam_id)
		for waypoint_index in range(plan.waypoints.size()):
			var waypoint = _coerce_waypoint(plan.waypoints[waypoint_index])
			if waypoint == null or waypoint.target_position == null:
				continue
			_visible_waypoints.append({
				"fireteam_id": fireteam_id,
				"phase": int(plan.phase),
				"waypoint_id": String(waypoint.waypoint_id),
				"position": Vector2(waypoint.target_position) + marker_offset,
				"raw_position": Vector2(waypoint.target_position),
				"command_type": String(waypoint.command_type),
				"index": waypoint_index,
			})
	queue_redraw()


func _coerce_waypoint(waypoint_variant):
	if waypoint_variant == null:
		return null
	if waypoint_variant is RefCounted and waypoint_variant.has_method("is_valid"):
		return waypoint_variant
	if typeof(waypoint_variant) == TYPE_DICTIONARY:
		return FIRETEAM_WAYPOINT_SCRIPT.call("from_dict", waypoint_variant)
	return null


func _get_fireteam_color(fireteam_id: String) -> Color:
	match fireteam_id:
		"blue":
			return Color(0.42, 0.76, 1.0, 0.95)
		"gold":
			return Color(1.0, 0.86, 0.3, 0.95)
		_:
			return Color(0.88, 0.88, 0.88, 0.85)


func _get_marker_offset(fireteam_id: String) -> Vector2:
	match fireteam_id:
		"blue":
			return Vector2(-WAYPOINT_OFFSET_STEP, -WAYPOINT_OFFSET_STEP)
		"gold":
			return Vector2(WAYPOINT_OFFSET_STEP, WAYPOINT_OFFSET_STEP)
		_:
			return Vector2.ZERO
