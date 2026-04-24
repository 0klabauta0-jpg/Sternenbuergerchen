class_name ContactMapOverlay
extends Node2D

const ICON_RADIUS: float = 10.0

var _contact_entries: Array = []
var _selected_fireteam_ids: PackedStringArray = []
var _visible_contacts: Array = []


func set_contact_entries(contact_entries: Array) -> void:
	_contact_entries = []
	for entry_variant in contact_entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		_contact_entries.append(Dictionary(entry_variant).duplicate(true))
	_rebuild_cache()


func set_selected_fireteam_ids(selected_fireteam_ids: PackedStringArray) -> void:
	_selected_fireteam_ids = selected_fireteam_ids.duplicate()
	_rebuild_cache()


func get_visible_contacts() -> Array:
	var result: Array = []
	for contact_variant in _visible_contacts:
		result.append(Dictionary(contact_variant).duplicate(true))
	return result


func _draw() -> void:
	for contact_variant in _visible_contacts:
		if typeof(contact_variant) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = Dictionary(contact_variant)
		var position: Vector2 = Vector2(contact.get("last_known_position", Vector2.ZERO))
		var detection_state: String = String(contact.get("detection_state", "unknown")).strip_edges().to_lower()
		var edge_color: Color = _get_fireteam_color(String(contact.get("fireteam_id", "")))
		var fill_color: Color = _get_contact_color(detection_state)
		match detection_state:
			"suspected":
				draw_circle(position, ICON_RADIUS, fill_color)
				draw_arc(position, ICON_RADIUS + 1.5, 0.0, TAU, 18, edge_color, 2.0)
				var fallback_font: Font = ThemeDB.fallback_font
				if fallback_font != null:
					draw_string(fallback_font, position + Vector2(-4.0, 4.0), "?", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color(0.96, 0.96, 0.96, 0.95))
			"lost":
				_draw_enemy_icon(position, fill_color)
				draw_line(position + Vector2(-6.0, -6.0), position + Vector2(6.0, 6.0), edge_color, 2.0)
			_:
				_draw_enemy_icon(position, fill_color)
				draw_arc(position, ICON_RADIUS + 1.5, 0.0, TAU, 18, edge_color, 2.0)


func _draw_enemy_icon(position: Vector2, fill_color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(0.0, -11.0),
		position + Vector2(11.0, 0.0),
		position + Vector2(0.0, 11.0),
		position + Vector2(-11.0, 0.0),
	]), fill_color)
	draw_circle(position, 3.0, Color(0.08, 0.09, 0.1, 0.92))


func _rebuild_cache() -> void:
	var relevant_fireteam_ids: Dictionary = {}
	for fireteam_id_variant in _selected_fireteam_ids:
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		relevant_fireteam_ids[fireteam_id] = true
	var aggregated_by_unit_id: Dictionary = {}
	for entry_variant in _contact_entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var fireteam_id: String = String(entry.get("fireteam_id", "")).strip_edges().to_lower()
		if not relevant_fireteam_ids.is_empty() and not relevant_fireteam_ids.has(fireteam_id):
			continue
		var unit_id: String = String(entry.get("unit_id", "")).strip_edges()
		if unit_id.is_empty():
			unit_id = "%s:%s" % [fireteam_id, String(entry.get("last_known_position", Vector2.ZERO))]
		var current: Dictionary = Dictionary(aggregated_by_unit_id.get(unit_id, {}))
		if current.is_empty() or _contact_state_rank(String(entry.get("detection_state", ""))) > _contact_state_rank(String(current.get("detection_state", ""))):
			aggregated_by_unit_id[unit_id] = entry.duplicate(true)
			continue
		if _contact_state_rank(String(entry.get("detection_state", ""))) == _contact_state_rank(String(current.get("detection_state", ""))) and int(entry.get("last_updated_tick", -1)) > int(current.get("last_updated_tick", -1)):
			aggregated_by_unit_id[unit_id] = entry.duplicate(true)
	var result: Array = aggregated_by_unit_id.values()
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var rank_a: int = _contact_state_rank(String(a.get("detection_state", "")))
		var rank_b: int = _contact_state_rank(String(b.get("detection_state", "")))
		if rank_a != rank_b:
			return rank_a > rank_b
		return String(a.get("unit_id", "")) < String(b.get("unit_id", ""))
	)
	_visible_contacts = []
	for contact_variant in result:
		_visible_contacts.append(Dictionary(contact_variant).duplicate(true))
	queue_redraw()


func _contact_state_rank(detection_state: String) -> int:
	match detection_state.strip_edges().to_lower():
		"confirmed":
			return 4
		"spotted":
			return 3
		"lost":
			return 2
		"suspected":
			return 1
		_:
			return 0


func _get_contact_color(detection_state: String) -> Color:
	match detection_state.strip_edges().to_lower():
		"suspected":
			return Color(0.95, 0.92, 0.45, 0.72)
		"spotted":
			return Color(1.0, 0.48, 0.4, 0.45)
		"lost":
			return Color(0.62, 0.65, 0.7, 0.42)
		_:
			return Color(1.0, 0.42, 0.34, 0.92)


func _get_fireteam_color(fireteam_id: String) -> Color:
	match fireteam_id.strip_edges().to_lower():
		"blue", "ft1":
			return Color(0.42, 0.76, 1.0, 0.95)
		"gold", "ft2":
			return Color(1.0, 0.86, 0.3, 0.95)
		_:
			return Color(0.95, 0.95, 0.95, 0.9)
