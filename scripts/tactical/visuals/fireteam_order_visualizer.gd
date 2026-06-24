class_name FireteamOrderVisualizer
extends Node2D

const FIRETEAM_ORDER_PLAN_SCRIPT: GDScript = preload("res://scripts/command/fireteam_order_plan.gd")
const FIRETEAM_WAYPOINT_SCRIPT: GDScript = preload("res://scripts/command/fireteam_waypoint.gd")
const AREA_ORDER_SCRIPT: GDScript = preload("res://scripts/command/area_order.gd")
const TERRAIN_MARKER_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_marker_catalog.gd")
const HIT_RADIUS: float = 16.0
const AREA_HIT_RADIUS: float = 28.0
const WAYPOINT_OFFSET_STEP: float = 7.0
const ISO_TILE_HALF_WIDTH: float = 64.0
const ISO_TILE_HALF_HEIGHT: float = 32.0
const ISO_MARKER_HALF_WIDTH: float = 18.0
const ISO_MARKER_HALF_HEIGHT: float = 10.0
const NEUTRAL_ORDER_LINE_COLOR: Color = Color(0.24, 0.72, 1.0, 0.95)
const DEFENSIVE_ORDER_LINE_COLOR: Color = Color(0.28, 0.9, 0.48, 0.95)
const OFFENSIVE_ORDER_LINE_COLOR: Color = Color(1.0, 0.28, 0.22, 0.95)
const MOVEMENT_RUSH_COLOR: Color = Color(0.32, 0.72, 1.0, 0.9)
const MOVEMENT_BOUNDING_COLOR: Color = Color(1.0, 0.78, 0.24, 0.92)
const MOVEMENT_CATERPILLAR_COLOR: Color = Color(0.48, 0.96, 0.62, 0.92)
const PREVIEW_SAFE_COLOR: Color = Color(0.38, 1.0, 0.64, 0.82)
const PREVIEW_RISKY_COLOR: Color = Color(1.0, 0.82, 0.24, 0.84)
const PREVIEW_SUICIDAL_COLOR: Color = Color(1.0, 0.24, 0.18, 0.88)
const PREVIEW_UNKNOWN_COLOR: Color = Color(0.62, 0.76, 1.0, 0.64)
const PREVIEW_BLOCKED_LINE_COLOR: Color = Color(0.62, 0.66, 0.7, 0.48)
const PREVIEW_FRIENDLY_FIRE_LINE_COLOR: Color = Color(1.0, 0.55, 0.08, 0.84)
const FIRETEAM_ORIENTATION_ARROW_LENGTH: float = 28.0
const FIRETEAM_ORIENTATION_ARROW_HEAD_LENGTH: float = 8.0
const FIRETEAM_ORIENTATION_ARROW_HEAD_WIDTH: float = 5.0

var _phase_index: int = 0
var _selected_fireteam_ids: PackedStringArray = []
var _plan_dicts: Array = []
var _area_order_dicts: Array = []
var _visible_waypoints: Array = []
var _visible_area_orders: Array = []
var _ad_hoc_order_dicts: Array = []
var _security_dicts: Array = []
var _security_overlay_enabled: bool = false
var _movement_state_dicts: Array = []
var _fireteam_anchor_positions: Dictionary = {}
var _fireteam_orientation_entries: Array = []
var _area_order_preview_payload: Dictionary = {}
var _waypoint_intent_preview_entries: Array = []


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


func set_area_order_dicts(area_order_dicts: Array) -> void:
	_area_order_dicts = []
	for area_order_variant in area_order_dicts:
		if typeof(area_order_variant) == TYPE_DICTIONARY:
			_area_order_dicts.append(Dictionary(area_order_variant).duplicate(true))
	_rebuild_cache()


func set_area_order_preview_payload(preview_payload: Dictionary) -> void:
	_area_order_preview_payload = preview_payload.duplicate(true)
	queue_redraw()


func set_waypoint_intent_preview_entries(entries: Array) -> void:
	_waypoint_intent_preview_entries = []
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		_waypoint_intent_preview_entries.append(Dictionary(entry_variant).duplicate(true))
	queue_redraw()


func set_fireteam_anchor_dicts(anchor_dicts: Array) -> void:
	_fireteam_anchor_positions.clear()
	_fireteam_orientation_entries.clear()
	for anchor_variant in anchor_dicts:
		if typeof(anchor_variant) != TYPE_DICTIONARY:
			continue
		var anchor_dict: Dictionary = Dictionary(anchor_variant)
		var fireteam_id: String = String(anchor_dict.get("fireteam_id", "")).strip_edges().to_lower()
		if fireteam_id.is_empty() or typeof(anchor_dict.get("position", null)) != TYPE_VECTOR2:
			continue
		var position: Vector2 = Vector2(anchor_dict.get("position", Vector2.ZERO))
		_fireteam_anchor_positions[fireteam_id] = position
		var heading_direction: Variant = anchor_dict.get("heading_direction", null)
		if typeof(heading_direction) == TYPE_VECTOR2 and Vector2(heading_direction).length_squared() > 0.0001:
			_fireteam_orientation_entries.append({
				"fireteam_id": fireteam_id,
				"position": position,
				"heading_direction": Vector2(heading_direction).normalized(),
				"heading_angle": float(anchor_dict.get("heading_angle", Vector2(heading_direction).angle())),
				"heading_source": String(anchor_dict.get("heading_source", "")),
			})
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


func set_security_overlay_enabled(enabled: bool) -> void:
	if _security_overlay_enabled == enabled:
		return
	_security_overlay_enabled = enabled
	queue_redraw()


func is_security_overlay_enabled() -> bool:
	return _security_overlay_enabled


func set_movement_state_dicts(movement_state_dicts: Array) -> void:
	_movement_state_dicts = []
	for movement_variant in movement_state_dicts:
		if typeof(movement_variant) != TYPE_DICTIONARY:
			continue
		_movement_state_dicts.append(Dictionary(movement_variant).duplicate(true))
	queue_redraw()


func get_visible_waypoints() -> Array:
	var result: Array = []
	for waypoint_data in _visible_waypoints:
		result.append(Dictionary(waypoint_data).duplicate(true))
	return result


func get_visible_area_orders() -> Array:
	var result: Array = []
	for area_order_data in _visible_area_orders:
		result.append(Dictionary(area_order_data).duplicate(true))
	return result


func get_fireteam_orientation_entries() -> Array:
	var result: Array = []
	for entry in _fireteam_orientation_entries:
		result.append(Dictionary(entry).duplicate(true))
	return result


func get_waypoint_intent_preview_snapshot() -> Array:
	var result: Array = []
	for entry in _waypoint_intent_preview_entries:
		result.append(Dictionary(entry).duplicate(true))
	return result


func get_security_overlay_snapshot() -> Dictionary:
	var entries: Array = _build_security_overlay_entries()
	var visible_entries: Array = []
	var hidden_by_selection_count: int = 0
	var mode_counts: Dictionary = {
		"360": 0,
		"sector": 0,
		"overwatch_ready": 0,
	}
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if bool(entry.get("visible", false)):
			visible_entries.append(entry.duplicate(true))
			var mode: String = String(entry.get("security_mode", "")).strip_edges().to_lower()
			if mode == "360":
				mode_counts["360"] = int(mode_counts.get("360", 0)) + 1
			else:
				mode_counts["sector"] = int(mode_counts.get("sector", 0)) + 1
			if bool(entry.get("overwatch_ready", false)):
				mode_counts["overwatch_ready"] = int(mode_counts.get("overwatch_ready", 0)) + 1
		elif bool(entry.get("hidden_by_selection", false)):
			hidden_by_selection_count += 1
	return {
		"enabled": _security_overlay_enabled,
		"selected_fireteam_ids": Array(_selected_fireteam_ids),
		"source_security_count": _security_dicts.size(),
		"visible_security_count": visible_entries.size(),
		"hidden_by_selection_count": hidden_by_selection_count,
		"mode_counts": mode_counts,
		"entries": visible_entries,
		"contact_visibility_policy": "enemy_highlights_require_contact_or_fow_visibility",
		"read_only": true,
	}


func get_waypoint_hit(screen_position: Vector2, canvas_transform: Transform2D) -> Dictionary:
	for waypoint_data in _visible_waypoints:
		var marker_screen_position: Vector2 = canvas_transform * Vector2(waypoint_data.get("position", Vector2.ZERO))
		if marker_screen_position.distance_to(screen_position) <= HIT_RADIUS:
			return Dictionary(waypoint_data).duplicate(true)
	return {}


func get_area_order_hit(screen_position: Vector2, canvas_transform: Transform2D) -> Dictionary:
	for area_order_data in _visible_area_orders:
		var center_screen_position: Vector2 = canvas_transform * Vector2(area_order_data.get("center_position", Vector2.ZERO))
		if center_screen_position.distance_to(screen_position) <= AREA_HIT_RADIUS:
			return Dictionary(area_order_data).duplicate(true)
		for tile_world_position_variant in Array(area_order_data.get("tile_world_positions", [])):
			var tile_polygon: PackedVector2Array = _build_iso_tile_polygon(Vector2(tile_world_position_variant))
			if _screen_polygon_contains_point(tile_polygon, screen_position, canvas_transform):
				return Dictionary(area_order_data).duplicate(true)
		var polygon: PackedVector2Array = PackedVector2Array(area_order_data.get("world_polygon", PackedVector2Array()))
		if _screen_polygon_contains_point(polygon, screen_position, canvas_transform):
			return Dictionary(area_order_data).duplicate(true)
	return {}


func _draw() -> void:
	_draw_area_orders()
	_draw_area_order_preview()
	_draw_fireteam_orientation_indicators()
	_draw_waypoint_intent_previews()
	for plan_dict in _plan_dicts:
		var plan = FIRETEAM_ORDER_PLAN_SCRIPT.call("from_dict", plan_dict)
		if plan == null or not plan.is_valid() or int(plan.phase) != _phase_index:
			continue
		_draw_plan(plan)
	_draw_movement_states()
	_draw_ad_hoc_orders()
	if _security_overlay_enabled:
		_draw_security_states()


func _draw_plan(plan) -> void:
	var fireteam_id: String = String(plan.fireteam_id).strip_edges().to_lower()
	var marker_offset: Vector2 = _get_marker_offset(fireteam_id)
	var base_color: Color = _get_fireteam_color(fireteam_id)
	var draw_color: Color = base_color if _selected_fireteam_ids.is_empty() or _selected_fireteam_ids.has(fireteam_id) else base_color.darkened(0.45)
	if not _selected_fireteam_ids.is_empty() and not _selected_fireteam_ids.has(fireteam_id):
		draw_color.a = 0.55

	var points: PackedVector2Array = []
	var drawable_waypoints: Array = []
	for waypoint_variant in plan.waypoints:
		var waypoint = _coerce_waypoint(waypoint_variant)
		if not _is_waypoint_visible(waypoint):
			continue
		var point := Vector2(waypoint.target_position) + marker_offset
		points.append(point)
		drawable_waypoints.append(waypoint)

	if points.size() >= 2:
		for index in range(1, points.size()):
			var segment_waypoint = _coerce_waypoint(drawable_waypoints[index])
			var segment_color: Color = _get_command_line_color(String(segment_waypoint.command_type) if segment_waypoint != null else "")
			draw_line(points[index - 1], points[index], _apply_selection_alpha(segment_color, draw_color.a), 3.0, true)
	var anchor_position: Vector2 = _get_fireteam_anchor_position(fireteam_id)
	if points.size() >= 1 and anchor_position.is_finite():
		var visual_anchor_position: Vector2 = anchor_position + marker_offset
		var first_waypoint = _coerce_waypoint(drawable_waypoints[0])
		var anchor_line_color: Color = _get_command_line_color(String(first_waypoint.command_type) if first_waypoint != null else "")
		draw_line(visual_anchor_position, points[0], _apply_selection_alpha(anchor_line_color, draw_color.a), 3.0, true)
		_draw_iso_marker_base(visual_anchor_position, draw_color, draw_color.darkened(0.35), 0.55)

	for index in range(points.size()):
		var waypoint = _coerce_waypoint(drawable_waypoints[index])
		if waypoint == null:
			continue
		var command_type: String = String(waypoint.command_type)
		var command_color: Color = Color(TERRAIN_MARKER_CATALOG_SCRIPT.call("get_color", command_type))
		_draw_waypoint_symbol(points[index], command_type, draw_color.lerp(command_color, 0.35), index)


func _draw_area_orders() -> void:
	for area_order_data in _visible_area_orders:
		var fireteam_id: String = String(area_order_data.get("fireteam_id", "")).strip_edges().to_lower()
		var command_type: String = String(area_order_data.get("command_type", "")).strip_edges().to_lower()
		var base_color: Color = _get_fireteam_color(fireteam_id)
		var command_color: Color = _get_command_line_color(command_type)
		var center_position: Vector2 = Vector2(area_order_data.get("center_position", Vector2.ZERO))
		var draw_alpha: float = 1.0
		if not _selected_fireteam_ids.is_empty() and not _selected_fireteam_ids.has(fireteam_id):
			draw_alpha = 0.45
		var fill_color: Color = base_color.lerp(command_color, 0.38)
		fill_color.a = 0.18 * draw_alpha
		var edge_color: Color = command_color
		edge_color.a = 0.86 * draw_alpha
		var anchor_position: Vector2 = _get_fireteam_anchor_position(fireteam_id)
		if anchor_position.is_finite():
			draw_line(anchor_position, center_position, _apply_selection_alpha(command_color, draw_alpha), 3.0, true)
			_draw_iso_marker_base(anchor_position, Color(base_color.r, base_color.g, base_color.b, 0.16 * draw_alpha), base_color, 0.55)
		var tile_world_positions: Array = Array(area_order_data.get("tile_world_positions", []))
		if not tile_world_positions.is_empty():
			for tile_world_position_variant in tile_world_positions:
				_draw_iso_tile(Vector2(tile_world_position_variant), fill_color, edge_color)
		else:
			var polygon: PackedVector2Array = PackedVector2Array(area_order_data.get("world_polygon", PackedVector2Array()))
			if polygon.size() < 3:
				continue
			draw_colored_polygon(polygon, fill_color)
			for index in range(polygon.size()):
				draw_line(polygon[index], polygon[(index + 1) % polygon.size()], edge_color, 2.0, true)
		_draw_iso_marker_base(center_position, Color(edge_color.r, edge_color.g, edge_color.b, 0.18 * draw_alpha), edge_color, 0.8)
		_draw_area_order_label(center_position, command_type, edge_color)


func _draw_fireteam_orientation_indicators() -> void:
	for entry_variant in _fireteam_orientation_entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var fireteam_id: String = String(entry.get("fireteam_id", "")).strip_edges().to_lower()
		if not _selected_fireteam_ids.is_empty() and not _selected_fireteam_ids.has(fireteam_id):
			continue
		var position: Vector2 = Vector2(entry.get("position", Vector2.ZERO))
		var direction: Vector2 = Vector2(entry.get("heading_direction", Vector2.ZERO))
		if direction.length_squared() <= 0.0001:
			continue
		direction = direction.normalized()
		var base_color: Color = _get_fireteam_color(fireteam_id)
		var arrow_color: Color = Color(0.96, 0.98, 1.0, 0.96).lerp(base_color, 0.28)
		var arrow_tip: Vector2 = position + direction * FIRETEAM_ORIENTATION_ARROW_LENGTH
		var arrow_base: Vector2 = arrow_tip - direction * FIRETEAM_ORIENTATION_ARROW_HEAD_LENGTH
		var lateral: Vector2 = direction.orthogonal() * FIRETEAM_ORIENTATION_ARROW_HEAD_WIDTH
		draw_line(position, arrow_tip, arrow_color, 2.4, true)
		draw_colored_polygon(PackedVector2Array([arrow_tip, arrow_base + lateral, arrow_base - lateral]), arrow_color)
		_draw_iso_marker_base(position, Color(base_color.r, base_color.g, base_color.b, 0.18), base_color, 0.46)


func _draw_area_order_preview() -> void:
	if _area_order_preview_payload.is_empty():
		return
	var tile_world_positions: Array = Array(_area_order_preview_payload.get("tile_world_positions", []))
	if tile_world_positions.is_empty():
		return
	var preview_fill := Color(0.84, 0.94, 1.0, 0.16)
	var preview_edge := Color(0.84, 0.94, 1.0, 0.72)
	for tile_world_position_variant in tile_world_positions:
		_draw_iso_tile(Vector2(tile_world_position_variant), preview_fill, preview_edge)


func _draw_waypoint_intent_previews() -> void:
	for entry_variant in _waypoint_intent_preview_entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var points: Array = Array(entry.get("ghost_path_points", []))
		if points.size() < 2:
			continue
		var fireteam_id: String = String(entry.get("fireteam_id", "")).strip_edges().to_lower()
		var preview_color: Color = _get_preview_risk_color(String(entry.get("risk_state", "unknown")))
		for index in range(1, points.size()):
			_draw_dashed_line(Vector2(points[index - 1]), Vector2(points[index]), preview_color, 2.0)
		var ghost_position: Vector2 = Vector2(entry.get("ghost_ftl_position", points[points.size() - 1]))
		_draw_iso_marker_base(ghost_position, Color(preview_color.r, preview_color.g, preview_color.b, 0.18), preview_color.lightened(0.18), 0.58)
		for line_variant in Array(entry.get("line_of_fire_entries", [])):
			if typeof(line_variant) != TYPE_DICTIONARY:
				continue
			var line_entry: Dictionary = Dictionary(line_variant)
			var line_color: Color = _get_preview_line_color(String(line_entry.get("visual_role", "")), bool(line_entry.get("blocked", false)))
			_draw_dashed_line(Vector2(line_entry.get("from_position", ghost_position)), Vector2(line_entry.get("to_position", ghost_position)), line_color, 1.35)
		var heading_direction: Vector2 = Vector2(entry.get("heading_direction", Vector2.ZERO))
		if heading_direction.length_squared() > 0.0001:
			var arrow_start: Vector2 = Vector2(points[0])
			var arrow_tip: Vector2 = arrow_start + heading_direction.normalized() * 24.0
			draw_line(arrow_start, arrow_tip, preview_color.lightened(0.25), 2.0, true)
		var fallback_font: Font = ThemeDB.fallback_font
		if fallback_font == null:
			continue
		var eta_seconds: int = maxi(int(ceil(float(entry.get("eta_seconds_estimate", 0.0)))), 0)
		var distance_text: String = "%dm" % int(round(float(entry.get("distance_world", 0.0))))
		var risk_text: String = String(entry.get("risk_state", "unknown")).strip_edges().to_upper()
		var label_text: String = "%s ETA~%ds %s" % [risk_text, eta_seconds, distance_text]
		draw_string(fallback_font, ghost_position + Vector2(14.0, -16.0), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, preview_color.lightened(0.32))


func _draw_area_order_label(center_position: Vector2, command_type: String, label_color: Color) -> void:
	var fallback_font: Font = ThemeDB.fallback_font
	if fallback_font == null:
		return
	var label_text: String = command_type.substr(0, mini(command_type.length(), 3)).to_upper()
	if label_text.is_empty():
		label_text = "AO"
	draw_string(fallback_font, center_position + Vector2(16.0, 4.0), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, label_color)


func _draw_waypoint_symbol(position: Vector2, command_type: String, marker_color: Color, index: int) -> void:
	var marker_symbol: String = String(TERRAIN_MARKER_CATALOG_SCRIPT.call("get_symbol", command_type)).strip_edges().to_lower()
	_draw_iso_marker_base(position, marker_color, marker_color.darkened(0.35), 1.0)
	match marker_symbol:
		TERRAIN_MARKER_CATALOG_SCRIPT.SYMBOL_SQUARE:
			_draw_iso_marker_base(position, marker_color.lightened(0.12), marker_color.darkened(0.35), 0.82)
		TERRAIN_MARKER_CATALOG_SCRIPT.SYMBOL_CROSS:
			draw_line(position + Vector2(-9.0, -5.0), position + Vector2(9.0, 5.0), Color(0.05, 0.07, 0.08, 0.9), 2.0)
			draw_line(position + Vector2(-9.0, 5.0), position + Vector2(9.0, -5.0), Color(0.05, 0.07, 0.08, 0.9), 2.0)
		TERRAIN_MARKER_CATALOG_SCRIPT.SYMBOL_DIAMOND:
			draw_line(position + Vector2(0.0, -ISO_MARKER_HALF_HEIGHT), position + Vector2(ISO_MARKER_HALF_WIDTH, 0.0), marker_color.lightened(0.18), 2.0, true)
			draw_line(position + Vector2(ISO_MARKER_HALF_WIDTH, 0.0), position + Vector2(0.0, ISO_MARKER_HALF_HEIGHT), marker_color.lightened(0.18), 2.0, true)
			draw_line(position + Vector2(0.0, ISO_MARKER_HALF_HEIGHT), position + Vector2(-ISO_MARKER_HALF_WIDTH, 0.0), marker_color.lightened(0.18), 2.0, true)
			draw_line(position + Vector2(-ISO_MARKER_HALF_WIDTH, 0.0), position + Vector2(0.0, -ISO_MARKER_HALF_HEIGHT), marker_color.lightened(0.18), 2.0, true)
		TERRAIN_MARKER_CATALOG_SCRIPT.SYMBOL_FLAG:
			draw_line(position + Vector2(-6.0, 10.0), position + Vector2(-6.0, -10.0), marker_color, 3.0)
			draw_colored_polygon(PackedVector2Array([
				position + Vector2(-6.0, -10.0),
				position + Vector2(8.0, -6.0),
				position + Vector2(-6.0, -1.0),
			]), marker_color)
		_:
			draw_line(position + Vector2(-8.0, 0.0), position + Vector2(8.0, 0.0), marker_color.lightened(0.2), 2.0, true)
	var index_color := Color(0.03, 0.05, 0.06, 0.92)
	draw_circle(position, 4.0, index_color)
	if index > 0:
		draw_circle(position + Vector2(8.0, -8.0), 3.0, index_color)


func _get_command_line_color(command_type: String) -> Color:
	match command_type.strip_edges().to_lower():
		FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_DEFEND:
			return DEFENSIVE_ORDER_LINE_COLOR
		FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_ENGAGE, FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_FLANK, FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_TAKE:
			return OFFENSIVE_ORDER_LINE_COLOR
		_:
			return NEUTRAL_ORDER_LINE_COLOR


func _apply_selection_alpha(line_color: Color, alpha: float) -> Color:
	var result := line_color
	result.a *= clampf(alpha, 0.0, 1.0)
	return result


func _draw_ad_hoc_orders() -> void:
	for order_dict in _ad_hoc_order_dicts:
		var fireteam_id: String = String(order_dict.get("fireteam_id", "")).strip_edges().to_lower()
		var anchor_position: Vector2 = Vector2(order_dict.get("anchor_position", Vector2.ZERO))
		var target_position: Vector2 = Vector2(order_dict.get("target_position", anchor_position))
		var base_color: Color = _get_fireteam_color(fireteam_id)
		var edge_color: Color = base_color
		var ad_hoc_color := Color(0.96, 0.96, 0.96, 0.95)
		_draw_dashed_line(anchor_position, target_position, ad_hoc_color, 3.0)
		_draw_iso_marker_base(target_position, ad_hoc_color, edge_color, 0.86)
		_draw_iso_marker_base(anchor_position, ad_hoc_color, edge_color, 0.52)
		var label_text: String = String(order_dict.get("label", "AD-HOC")).strip_edges()
		var fallback_font: Font = ThemeDB.fallback_font
		if fallback_font != null and not label_text.is_empty():
			draw_string(fallback_font, target_position + Vector2(14.0, -8.0), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(0.95, 0.95, 0.95, 0.92))


func _build_security_overlay_entries() -> Array:
	var result: Array = []
	for security_variant in _security_dicts:
		if typeof(security_variant) != TYPE_DICTIONARY:
			continue
		var security_dict: Dictionary = Dictionary(security_variant)
		var fireteam_id: String = String(security_dict.get("fireteam_id", "")).strip_edges().to_lower()
		if fireteam_id.is_empty() or not bool(security_dict.get("is_active", false)):
			continue
		var selected: bool = _selected_fireteam_ids.is_empty() or _selected_fireteam_ids.has(fireteam_id)
		var assignments: Array = Array(security_dict.get("member_assignments", []))
		var security_mode: String = String(security_dict.get("security_mode", "")).strip_edges().to_lower()
		if security_mode.is_empty():
			security_mode = "sector" if not assignments.is_empty() else "unknown"
		result.append({
			"fireteam_id": fireteam_id,
			"security_mode": security_mode,
			"anchor_position": Vector2(security_dict.get("anchor_position", Vector2.ZERO)),
			"assignment_count": assignments.size(),
			"overwatch_ready": bool(security_dict.get("overwatch_ready", false)),
			"overwatch_unit_ids": PackedStringArray(security_dict.get("overwatch_unit_ids", PackedStringArray())),
			"visible": _security_overlay_enabled and selected,
			"hidden_by_selection": _security_overlay_enabled and not selected,
			"reduced_by_selection": false,
			"contact_visibility_policy": "friendly_sector_only_enemy_highlight_requires_contact",
		})
	return result


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
		var security_mode: String = String(security_dict.get("security_mode", "")).strip_edges().to_lower()
		var radius_hint: float = float(security_dict.get("security_radius_world", 74.0))
		var visual_radius: float = clampf(radius_hint if radius_hint > 0.0 else 74.0, 74.0, 256.0)
		if security_mode == "360":
			overlay_color.a = 0.22
		for assignment_variant in Array(security_dict.get("member_assignments", [])):
			if typeof(assignment_variant) != TYPE_DICTIONARY:
				continue
			var assignment: Dictionary = Dictionary(assignment_variant)
			var center_angle: float = float(assignment.get("center_angle", 0.0))
			var arc_width: float = float(assignment.get("arc_width", 0.0))
			_draw_sector(anchor_position, center_angle, arc_width, visual_radius, overlay_color)
		var fallback_font: Font = ThemeDB.fallback_font
		if fallback_font != null and security_mode == "360":
			var radius_tiles: int = int(security_dict.get("security_radius_tiles", 0))
			var radius_text: String = " R%d" % radius_tiles if radius_tiles > 0 else ""
			draw_string(fallback_font, anchor_position + Vector2(12.0, -10.0), "DEF 360%s" % radius_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color(0.95, 0.98, 1.0, 0.95))
		elif fallback_font != null:
			var direction := Vector2.RIGHT.rotated(float(security_dict.get("direction_angle", 0.0)))
			draw_string(fallback_font, anchor_position + Vector2(12.0, -10.0), "DEF %s" % _format_compass_direction_label(direction), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color(0.95, 0.98, 1.0, 0.95))


func _format_compass_direction_label(direction: Vector2) -> String:
	if direction.length_squared() <= 0.0001:
		return "HERE"
	var abs_x: float = absf(direction.x)
	var abs_y: float = absf(direction.y)
	var horizontal: String = "E" if direction.x >= 0.0 else "W"
	var vertical: String = "S" if direction.y >= 0.0 else "N"
	var dominant_threshold: float = 0.42
	if abs_x <= abs_y * dominant_threshold:
		return vertical
	if abs_y <= abs_x * dominant_threshold:
		return horizontal
	return "%s%s" % [vertical, horizontal]


func _draw_movement_states() -> void:
	for movement_state_variant in _movement_state_dicts:
		if typeof(movement_state_variant) != TYPE_DICTIONARY:
			continue
		var movement_state: Dictionary = Dictionary(movement_state_variant)
		var fireteam_id: String = String(movement_state.get("fireteam_id", "")).strip_edges().to_lower()
		if not _selected_fireteam_ids.is_empty() and not _selected_fireteam_ids.has(fireteam_id):
			continue
		var style: String = String(movement_state.get("advance_style", movement_state.get("effective_style", ""))).strip_edges().to_lower()
		var origin_position: Vector2 = Vector2(movement_state.get("bound_origin_position", movement_state.get("progress_anchor_position", Vector2.ZERO)))
		var target_position: Vector2 = Vector2(movement_state.get("bound_target_position", movement_state.get("current_anchor_target_position", origin_position)))
		var draw_color: Color = _get_movement_style_color(style)
		draw_line(origin_position, target_position, draw_color, 3.0, true)
		_draw_iso_marker_base(target_position, Color(draw_color.r, draw_color.g, draw_color.b, 0.26), draw_color, 0.86)
		_draw_movement_member_marks(movement_state, target_position, draw_color)
		var fallback_font: Font = ThemeDB.fallback_font
		if fallback_font == null:
			continue
		var label_text: String = _build_movement_map_label(movement_state)
		if label_text.is_empty():
			continue
		draw_string(fallback_font, target_position + Vector2(14.0, -14.0), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, draw_color.lightened(0.08))


func _draw_movement_member_marks(movement_state: Dictionary, bound_target_position: Vector2, draw_color: Color) -> void:
	var target_positions: Dictionary = Dictionary(movement_state.get("current_target_positions", {}))
	var moving_unit_ids: PackedStringArray = PackedStringArray(movement_state.get("moving_unit_ids", movement_state.get("current_moving_unit_ids", PackedStringArray())))
	var covering_unit_ids: PackedStringArray = PackedStringArray(movement_state.get("covering_unit_ids", movement_state.get("current_covering_unit_ids", PackedStringArray())))
	for unit_id in moving_unit_ids:
		var marker_position: Vector2 = Vector2(target_positions.get(String(unit_id), bound_target_position))
		draw_circle(marker_position, 5.0, draw_color.lightened(0.16))
	for cover_index in range(covering_unit_ids.size()):
		var cover_position: Vector2 = Vector2(movement_state.get("bound_origin_position", bound_target_position)) + Vector2(float(cover_index) * 7.0, 10.0)
		draw_circle(cover_position, 3.5, Color(draw_color.r, draw_color.g, draw_color.b, 0.42))


func _get_movement_style_color(style: String) -> Color:
	match style.strip_edges().to_lower():
		"bounding":
			return MOVEMENT_BOUNDING_COLOR
		"caterpillar", "creep":
			return MOVEMENT_CATERPILLAR_COLOR
		"rush":
			return MOVEMENT_RUSH_COLOR
		_:
			return Color(0.88, 0.88, 0.88, 0.82)


func _get_preview_risk_color(risk_state: String) -> Color:
	match risk_state.strip_edges().to_lower():
		"safe":
			return PREVIEW_SAFE_COLOR
		"risky":
			return PREVIEW_RISKY_COLOR
		"suicidal":
			return PREVIEW_SUICIDAL_COLOR
		_:
			return PREVIEW_UNKNOWN_COLOR


func _get_preview_line_color(visual_role: String, blocked: bool) -> Color:
	if blocked or visual_role == "blocked":
		return PREVIEW_BLOCKED_LINE_COLOR
	match visual_role.strip_edges().to_lower():
		"friendly_fire_risk":
			return PREVIEW_FRIENDLY_FIRE_LINE_COLOR
		"enemy_overwatch":
			return PREVIEW_SUICIDAL_COLOR
		"clear_friendly_shot":
			return PREVIEW_SAFE_COLOR
		_:
			return PREVIEW_RISKY_COLOR


func _build_movement_map_label(movement_state: Dictionary) -> String:
	var style_code: String = String(movement_state.get("style_code", "")).strip_edges().to_upper()
	if style_code.is_empty():
		style_code = String(Dictionary(movement_state.get("map_readability", {})).get("style_code", "")).strip_edges().to_upper()
	if style_code.is_empty():
		style_code = "MOV"
	var bound_index: int = maxi(int(movement_state.get("bound_index", Dictionary(movement_state.get("map_readability", {})).get("bound_index", 1))), 1)
	var bound_count: int = maxi(int(movement_state.get("bound_count", Dictionary(movement_state.get("map_readability", {})).get("bound_count", 1))), 1)
	var group_index: int = maxi(int(movement_state.get("group_index", Dictionary(movement_state.get("map_readability", {})).get("group_index", 1))), 1)
	var group_count: int = maxi(int(movement_state.get("group_count", Dictionary(movement_state.get("map_readability", {})).get("group_count", 1))), 1)
	if group_count > 1:
		return "%s %d/%d G%d/%d" % [style_code, bound_index, bound_count, group_index, group_count]
	return "%s %d/%d" % [style_code, bound_index, bound_count]


func _draw_sector(origin: Vector2, center_angle: float, arc_width: float, radius: float, fill_color: Color) -> void:
	if arc_width >= TAU - 0.001:
		draw_circle(origin, radius, fill_color)
		draw_arc(origin, radius, 0.0, TAU, 48, fill_color.lightened(0.18), 2.0)
		return
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


func _draw_iso_tile(center_position: Vector2, fill_color: Color, edge_color: Color) -> void:
	var polygon: PackedVector2Array = _build_iso_tile_polygon(center_position)
	draw_colored_polygon(polygon, fill_color)
	for index in range(polygon.size()):
		draw_line(polygon[index], polygon[(index + 1) % polygon.size()], edge_color, 2.0, true)


func _draw_iso_marker_base(center_position: Vector2, fill_color: Color, edge_color: Color, scale: float = 1.0) -> void:
	var half_width: float = ISO_MARKER_HALF_WIDTH * scale
	var half_height: float = ISO_MARKER_HALF_HEIGHT * scale
	var polygon: PackedVector2Array = PackedVector2Array([
		center_position + Vector2(0.0, -half_height),
		center_position + Vector2(half_width, 0.0),
		center_position + Vector2(0.0, half_height),
		center_position + Vector2(-half_width, 0.0),
	])
	draw_colored_polygon(polygon, fill_color)
	for index in range(polygon.size()):
		draw_line(polygon[index], polygon[(index + 1) % polygon.size()], edge_color, 2.0, true)


func _build_iso_tile_polygon(center_position: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		center_position + Vector2(0.0, -ISO_TILE_HALF_HEIGHT),
		center_position + Vector2(ISO_TILE_HALF_WIDTH, 0.0),
		center_position + Vector2(0.0, ISO_TILE_HALF_HEIGHT),
		center_position + Vector2(-ISO_TILE_HALF_WIDTH, 0.0),
	])


func _rebuild_cache() -> void:
	_visible_waypoints.clear()
	_visible_area_orders.clear()
	for area_order_dict in _area_order_dicts:
		var area_order = AREA_ORDER_SCRIPT.call("from_dict", area_order_dict)
		if area_order == null or not area_order.is_valid() or not _is_area_order_visible(area_order):
			continue
		var fireteam_id: String = String(area_order.fireteam_id).strip_edges().to_lower()
		var area_entry: Dictionary = {
			"area_order_id": String(area_order.area_order_id),
			"fireteam_id": fireteam_id,
			"command_type": String(area_order.command_type),
			"center_position": Vector2(area_order.center_position),
			"tile_positions": Array(area_order.tile_positions).duplicate(true),
			"tile_world_positions": Array(area_order.tile_world_positions).duplicate(true),
			"world_polygon": PackedVector2Array(area_order.world_polygon),
			"created_at_order_index": int(area_order.created_at_order_index),
			"status": String(area_order.status),
		}
		var anchor_position: Vector2 = _get_fireteam_anchor_position(fireteam_id)
		if anchor_position.is_finite():
			area_entry["anchor_position"] = anchor_position
		_visible_area_orders.append(area_entry)
	for plan_dict in _plan_dicts:
		var plan = FIRETEAM_ORDER_PLAN_SCRIPT.call("from_dict", plan_dict)
		if plan == null or not plan.is_valid() or int(plan.phase) != _phase_index:
			continue
		var fireteam_id: String = String(plan.fireteam_id).strip_edges().to_lower()
		var marker_offset: Vector2 = _get_marker_offset(fireteam_id)
		for waypoint_index in range(plan.waypoints.size()):
			var waypoint = _coerce_waypoint(plan.waypoints[waypoint_index])
			if not _is_waypoint_visible(waypoint):
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


func _is_waypoint_visible(waypoint) -> bool:
	if waypoint == null or waypoint.target_position == null:
		return false
	return String(waypoint.status) != FIRETEAM_WAYPOINT_SCRIPT.STATUS_COMPLETED


func _is_area_order_visible(area_order) -> bool:
	if area_order == null:
		return false
	var status: String = String(area_order.status)
	return status != AREA_ORDER_SCRIPT.STATUS_COMPLETED and status != AREA_ORDER_SCRIPT.STATUS_CANCELLED


func _screen_polygon_contains_point(polygon: PackedVector2Array, screen_position: Vector2, canvas_transform: Transform2D) -> bool:
	if polygon.size() < 3:
		return false
	var inside: bool = false
	var previous_index: int = polygon.size() - 1
	for index in range(polygon.size()):
		var current_point: Vector2 = canvas_transform * polygon[index]
		var previous_point: Vector2 = canvas_transform * polygon[previous_index]
		var crosses_y: bool = (current_point.y > screen_position.y) != (previous_point.y > screen_position.y)
		if crosses_y:
			var denominator: float = previous_point.y - current_point.y
			if absf(denominator) < 0.001:
				previous_index = index
				continue
			var slope_x: float = (previous_point.x - current_point.x) * (screen_position.y - current_point.y) / denominator + current_point.x
			if screen_position.x < slope_x:
				inside = not inside
		previous_index = index
	return inside


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
