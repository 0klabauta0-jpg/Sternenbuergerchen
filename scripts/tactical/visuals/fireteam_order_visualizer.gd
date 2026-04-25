class_name FireteamOrderVisualizer
extends Node2D

const FIRETEAM_ORDER_PLAN_SCRIPT: GDScript = preload("res://scripts/command/fireteam_order_plan.gd")
const FIRETEAM_WAYPOINT_SCRIPT: GDScript = preload("res://scripts/command/fireteam_waypoint.gd")
const TERRAIN_MARKER_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_marker_catalog.gd")
const MARKER_RADIUS: float = 12.0
const HIT_RADIUS: float = 16.0
const WAYPOINT_OFFSET_STEP: float = 7.0

var _phase_index: int = 0
var _selected_fireteam_ids: PackedStringArray = []
var _plan_dicts: Array = []
var _visible_waypoints: Array = []
var _ad_hoc_order_dicts: Array = []
var _security_dicts: Array = []
var _fireteam_anchor_positions: Dictionary = {}


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


func set_fireteam_anchor_dicts(anchor_dicts: Array) -> void:
	_fireteam_anchor_positions.clear()
	for anchor_variant in anchor_dicts:
		if typeof(anchor_variant) != TYPE_DICTIONARY:
			continue
		var anchor_dict: Dictionary = Dictionary(anchor_variant)
		var fireteam_id: String = String(anchor_dict.get("fireteam_id", "")).strip_edges().to_lower()
		if fireteam_id.is_empty() or typeof(anchor_dict.get("position", null)) != TYPE_VECTOR2:
			continue
		_fireteam_anchor_positions[fireteam_id] = Vector2(anchor_dict.get("position", Vector2.ZERO))
	queue_redraw()


func set_ad_hoc_order_dicts(ad_hoc_order_dicts: Array) -> void:
	_ad_hoc_order_dicts = []
	for order_variant in ad_hoc_order_dicts:
		if typeof(order_variant) != TYPE_DICTIONARY:
			continue
		_ad_hoc_order_dicts.append(Dictionary(order_variant).duplicate(true))
	queue_redraw()


func set_security_dicts(security_dicts: Array) -> void:
	_security_dicts = []
	for security_variant in security_dicts:
		if typeof(security_variant) != TYPE_DICTIONARY:
			continue
		_security_dicts.append(Dictionary(security_variant).duplicate(true))
	queue_redraw()


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
	_draw_ad_hoc_orders()
	_draw_security_states()


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
	var anchor_position: Vector2 = _get_fireteam_anchor_position(fireteam_id)
	if points.size() >= 1 and anchor_position.is_finite():
		var visual_anchor_position: Vector2 = anchor_position + marker_offset
		draw_line(visual_anchor_position, points[0], draw_color, 3.0, true)
		draw_circle(visual_anchor_position, 5.0, draw_color)

	for index in range(points.size()):
		var waypoint = _coerce_waypoint(plan.waypoints[index])
		if waypoint == null:
			continue
		var command_type: String = String(waypoint.command_type)
		var command_color: Color = Color(TERRAIN_MARKER_CATALOG_SCRIPT.call("get_color", command_type))
		_draw_waypoint_symbol(points[index], command_type, draw_color.lerp(command_color, 0.35), index)


func _draw_waypoint_symbol(position: Vector2, command_type: String, marker_color: Color, index: int) -> void:
	var marker_symbol: String = String(TERRAIN_MARKER_CATALOG_SCRIPT.call("get_symbol", command_type)).strip_edges().to_lower()
	match marker_symbol:
		TERRAIN_MARKER_CATALOG_SCRIPT.SYMBOL_SQUARE:
			draw_rect(Rect2(position - Vector2(10.0, 10.0), Vector2(20.0, 20.0)), marker_color, true)
		TERRAIN_MARKER_CATALOG_SCRIPT.SYMBOL_CROSS:
			draw_circle(position, MARKER_RADIUS, marker_color)
			draw_line(position + Vector2(-8.0, 0.0), position + Vector2(8.0, 0.0), Color(0.05, 0.07, 0.08, 0.9), 2.0)
			draw_line(position + Vector2(0.0, -8.0), position + Vector2(0.0, 8.0), Color(0.05, 0.07, 0.08, 0.9), 2.0)
		TERRAIN_MARKER_CATALOG_SCRIPT.SYMBOL_DIAMOND:
			draw_colored_polygon(PackedVector2Array([
				position + Vector2(0.0, -12.0),
				position + Vector2(11.0, 0.0),
				position + Vector2(0.0, 12.0),
				position + Vector2(-11.0, 0.0),
			]), marker_color)
		TERRAIN_MARKER_CATALOG_SCRIPT.SYMBOL_FLAG:
			draw_line(position + Vector2(-6.0, 10.0), position + Vector2(-6.0, -10.0), marker_color, 3.0)
			draw_colored_polygon(PackedVector2Array([
				position + Vector2(-6.0, -10.0),
				position + Vector2(8.0, -6.0),
				position + Vector2(-6.0, -1.0),
			]), marker_color)
		_:
			draw_circle(position, MARKER_RADIUS, marker_color)
	var index_color := Color(0.03, 0.05, 0.06, 0.92)
	draw_circle(position, 4.0, index_color)
	if index > 0:
		draw_circle(position + Vector2(8.0, -8.0), 3.0, index_color)


func _draw_ad_hoc_orders() -> void:
	for order_dict in _ad_hoc_order_dicts:
		var fireteam_id: String = String(order_dict.get("fireteam_id", "")).strip_edges().to_lower()
		var anchor_position: Vector2 = Vector2(order_dict.get("anchor_position", Vector2.ZERO))
		var target_position: Vector2 = Vector2(order_dict.get("target_position", anchor_position))
		var base_color: Color = _get_fireteam_color(fireteam_id)
		var edge_color: Color = base_color
		var ad_hoc_color := Color(0.96, 0.96, 0.96, 0.95)
		_draw_dashed_line(anchor_position, target_position, ad_hoc_color, 3.0)
		draw_circle(target_position, 10.0, ad_hoc_color)
		draw_arc(target_position, 11.5, 0.0, TAU, 24, edge_color, 2.0)
		draw_circle(anchor_position, 6.0, ad_hoc_color)
		draw_arc(anchor_position, 7.5, 0.0, TAU, 24, edge_color, 2.0)
		var label_text: String = String(order_dict.get("label", "AD-HOC")).strip_edges()
		var fallback_font: Font = ThemeDB.fallback_font
		if fallback_font != null and not label_text.is_empty():
			draw_string(fallback_font, target_position + Vector2(14.0, -8.0), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(0.95, 0.95, 0.95, 0.92))


func _draw_security_states() -> void:
	for security_dict in _security_dicts:
		var fireteam_id: String = String(security_dict.get("fireteam_id", "")).strip_edges().to_lower()
		if not _selected_fireteam_ids.is_empty() and not _selected_fireteam_ids.has(fireteam_id):
			continue
		if not bool(security_dict.get("is_active", false)):
			continue
		var anchor_position: Vector2 = Vector2(security_dict.get("anchor_position", Vector2.ZERO))
		var base_color: Color = _get_fireteam_color(fireteam_id)
		var overlay_color: Color = base_color.lightened(0.15)
		overlay_color.a = 0.32
		for assignment_variant in Array(security_dict.get("member_assignments", [])):
			if typeof(assignment_variant) != TYPE_DICTIONARY:
				continue
			var assignment: Dictionary = Dictionary(assignment_variant)
			var center_angle: float = float(assignment.get("center_angle", 0.0))
			var arc_width: float = float(assignment.get("arc_width", 0.0))
			_draw_sector(anchor_position, center_angle, arc_width, 74.0, overlay_color)
		if bool(security_dict.get("overwatch_ready", false)):
			draw_circle(anchor_position, 7.0, Color(0.95, 0.98, 1.0, 0.9))
			var fallback_font: Font = ThemeDB.fallback_font
			if fallback_font != null:
				draw_string(fallback_font, anchor_position + Vector2(12.0, -10.0), "OVW", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color(0.95, 0.98, 1.0, 0.95))


func _draw_sector(origin: Vector2, center_angle: float, arc_width: float, radius: float, fill_color: Color) -> void:
	var points: PackedVector2Array = [origin]
	var start_angle: float = center_angle - (arc_width * 0.5)
	var steps: int = maxi(int(ceil(arc_width / (PI / 12.0))), 2)
	for step in range(steps + 1):
		var t: float = float(step) / float(steps)
		var angle: float = lerpf(start_angle, start_angle + arc_width, t)
		points.append(origin + Vector2.RIGHT.rotated(angle) * radius)
	draw_colored_polygon(points, fill_color)
	draw_arc(origin, radius, start_angle, start_angle + arc_width, maxi(steps * 2, 12), fill_color.lightened(0.18), 2.0)


func _draw_dashed_line(from_point: Vector2, to_point: Vector2, line_color: Color, width: float) -> void:
	var delta: Vector2 = to_point - from_point
	var length: float = delta.length()
	if length <= 1.0:
		return
	var direction: Vector2 = delta / length
	var step: float = 16.0
	var dash: float = 9.0
	var cursor: float = 0.0
	while cursor < length:
		var start_point: Vector2 = from_point + direction * cursor
		var end_point: Vector2 = from_point + direction * minf(cursor + dash, length)
		draw_line(start_point, end_point, line_color, width, true)
		cursor += step


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
		"blue", "ft1":
			return Color(0.42, 0.76, 1.0, 0.95)
		"gold", "ft2":
			return Color(1.0, 0.86, 0.3, 0.95)
		_:
			return Color(0.88, 0.88, 0.88, 0.85)


func _get_marker_offset(fireteam_id: String) -> Vector2:
	match fireteam_id:
		"blue", "ft1":
			return Vector2(-WAYPOINT_OFFSET_STEP, -WAYPOINT_OFFSET_STEP)
		"gold", "ft2":
			return Vector2(WAYPOINT_OFFSET_STEP, WAYPOINT_OFFSET_STEP)
		_:
			return Vector2.ZERO


func _get_fireteam_anchor_position(fireteam_id: String) -> Vector2:
	if not _fireteam_anchor_positions.has(fireteam_id):
		return Vector2.INF
	return Vector2(_fireteam_anchor_positions.get(fireteam_id, Vector2.ZERO))
