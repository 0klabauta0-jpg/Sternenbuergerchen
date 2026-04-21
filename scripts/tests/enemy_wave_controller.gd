extends Node

signal wave_started(wave_number: int)
signal all_waves_complete()

const STATUS_LABEL_NAME: String = "WaveStatusLabel"
const STATUS_LABEL_POSITION: Vector2 = Vector2(542.0, 176.0)

@export var wave_count: int = 3
@export var units_per_wave: int = 2
@export var wave_delay_seconds: float = 45.0
@export var first_wave_delay_seconds: float = 5.0
@export var unit_registry_path: NodePath
@export var simulation_root_path: NodePath
@export var preview_mode: bool = false

var _enemy_units: Array = []
var _spawn_positions_by_unit_id: Dictionary = {}
var _patrol_paths_by_unit_id: Dictionary = {}
var _current_wave_number: int = 0
var _time_until_next_wave: float = 0.0
var _status_label: Label = null
var _all_waves_complete_emitted: bool = false
var _overlay_visible: bool = true


func _ready() -> void:
	call_deferred("_finish_ready")


func initialize_enemy_units(enemy_units: Array) -> void:
	_enemy_units.clear()
	_spawn_positions_by_unit_id.clear()
	_current_wave_number = 0
	_all_waves_complete_emitted = false
	for enemy_unit in enemy_units:
		if enemy_unit == null or not enemy_unit.has_method("get_unit_id"):
			continue

		_enemy_units.append(enemy_unit)
		var unit_id: String = String(enemy_unit.call("get_unit_id"))
		if enemy_unit is Node2D:
			_spawn_positions_by_unit_id[unit_id] = (enemy_unit as Node2D).global_position

		_deactivate_enemy_unit(enemy_unit)
		if _patrol_paths_by_unit_id.has(unit_id) and enemy_unit.has_method("set_patrol_path"):
			enemy_unit.call("set_patrol_path", Array(_patrol_paths_by_unit_id.get(unit_id, [])).duplicate(true))

	_time_until_next_wave = maxf(first_wave_delay_seconds, 0.0)
	if _enemy_units.is_empty():
		_refresh_status_label()
		return

	if _time_until_next_wave <= 0.0 and _should_process_locally():
		_start_next_wave()
		if not are_all_waves_started():
			_time_until_next_wave = maxf(wave_delay_seconds, 0.0)

	_refresh_status_label()


func set_patrol_paths(patrol_paths_by_unit_id: Dictionary) -> void:
	_patrol_paths_by_unit_id.clear()
	for unit_id_variant in patrol_paths_by_unit_id.keys():
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty():
			continue
		_patrol_paths_by_unit_id[unit_id] = Array(patrol_paths_by_unit_id.get(unit_id_variant, [])).duplicate(true)


func get_patrol_path_for_unit(unit_id: String) -> Array:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return []
	return Array(_patrol_paths_by_unit_id.get(normalized_unit_id, [])).duplicate(true)


func get_current_wave_number() -> int:
	return _current_wave_number


func get_total_wave_count() -> int:
	if units_per_wave <= 0:
		return 0

	var configured_wave_count: int = max(wave_count, 0)
	var required_wave_count: int = int(ceili(float(_enemy_units.size()) / float(units_per_wave)))
	if configured_wave_count == 0:
		return required_wave_count

	return mini(configured_wave_count, required_wave_count)


func are_all_waves_started() -> bool:
	var total_wave_count: int = get_total_wave_count()
	return total_wave_count > 0 and _current_wave_number >= total_wave_count


func _process(delta: float) -> void:
	if preview_mode:
		return
	if not _should_process_locally():
		_refresh_status_label()
		return

	if _enemy_units.is_empty() or are_all_waves_started():
		_refresh_status_label()
		return

	_time_until_next_wave = maxf(_time_until_next_wave - delta, 0.0)
	if _time_until_next_wave > 0.0:
		_refresh_status_label()
		return

	_start_next_wave()
	if not are_all_waves_started():
		_time_until_next_wave = maxf(wave_delay_seconds, 0.0)

	_refresh_status_label()


func _start_next_wave() -> void:
	var total_wave_count: int = get_total_wave_count()
	if total_wave_count <= 0 or _current_wave_number >= total_wave_count:
		return

	_current_wave_number += 1
	var wave_start_index: int = (_current_wave_number - 1) * max(units_per_wave, 1)
	var wave_end_index: int = mini(wave_start_index + max(units_per_wave, 1), _enemy_units.size())
	for index in range(wave_start_index, wave_end_index):
		var enemy_unit = _enemy_units[index]
		_activate_enemy_unit(enemy_unit)

	wave_started.emit(_current_wave_number)
	if are_all_waves_started() and not _all_waves_complete_emitted:
		_all_waves_complete_emitted = true
		all_waves_complete.emit()


func _activate_enemy_unit(enemy_unit) -> void:
	if enemy_unit == null or not enemy_unit.has_method("get_unit_id"):
		return

	var unit_id: String = String(enemy_unit.call("get_unit_id"))
	var spawn_position: Vector2 = Vector2.ZERO
	if _spawn_positions_by_unit_id.has(unit_id):
		spawn_position = _spawn_positions_by_unit_id[unit_id]
	elif enemy_unit is Node2D:
		spawn_position = (enemy_unit as Node2D).global_position

	if enemy_unit.has_method("activate_for_wave"):
		enemy_unit.call("activate_for_wave", spawn_position)
	elif enemy_unit is CanvasItem:
		enemy_unit.visible = true

	var unit_registry = _get_unit_registry()
	if unit_registry == null or not unit_registry.has_method("register_unit"):
		return

	if unit_registry.call("has_unit", unit_id):
		return

	unit_registry.call("register_unit", unit_id, enemy_unit)


func _deactivate_enemy_unit(enemy_unit) -> void:
	if enemy_unit == null or not enemy_unit.has_method("get_unit_id"):
		return

	var unit_id: String = String(enemy_unit.call("get_unit_id"))
	var unit_registry = _get_unit_registry()
	if unit_registry != null and unit_registry.has_method("unregister_unit"):
		unit_registry.call("unregister_unit", unit_id)

	if enemy_unit.has_method("deactivate_for_wave"):
		enemy_unit.call("deactivate_for_wave")
	elif enemy_unit is CanvasItem:
		enemy_unit.visible = false


func _get_unit_registry():
	if unit_registry_path.is_empty():
		return null

	return get_node_or_null(unit_registry_path)


func _ensure_status_label() -> void:
	var scene_root = get_parent()
	if scene_root == null:
		return

	_status_label = scene_root.get_node_or_null(STATUS_LABEL_NAME) as Label
	if _status_label == null:
		_status_label = Label.new()
		_status_label.name = STATUS_LABEL_NAME
		_status_label.top_level = true
		_status_label.position = STATUS_LABEL_POSITION
		_status_label.add_theme_font_size_override("font_size", 12)
		_status_label.add_theme_constant_override("outline_size", 2)
		_status_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
		scene_root.add_child(_status_label)


func _refresh_status_label() -> void:
	if _status_label == null or preview_mode:
		return

	var total_wave_count: int = get_total_wave_count()
	if total_wave_count <= 0:
		_status_label.text = "WAVE -/-"
		return

	var lines: PackedStringArray = []
	lines.append("WAVE %d/%d" % [_current_wave_number, total_wave_count])
	if not are_all_waves_started():
		lines.append("NEXT %.0fs" % ceil(_time_until_next_wave))

	_status_label.text = "\n".join(lines)


func _finish_ready() -> void:
	if preview_mode:
		_remove_status_label()
		return
	_ensure_status_label()
	_apply_overlay_visibility()
	_refresh_status_label()


func set_preview_mode(is_preview: bool) -> void:
	preview_mode = is_preview
	if preview_mode:
		_remove_status_label()
		return
	if is_inside_tree():
		_ensure_status_label()
		_apply_overlay_visibility()
		_refresh_status_label()


func set_overlay_visible(is_visible: bool) -> void:
	_overlay_visible = is_visible
	_apply_overlay_visibility()


func _apply_overlay_visibility() -> void:
	if _status_label == null:
		return
	_status_label.visible = _overlay_visible and not preview_mode


func _remove_status_label() -> void:
	if _status_label != null:
		_status_label.queue_free()
		_status_label = null


func _should_process_locally() -> bool:
	var simulation_root = null
	if not simulation_root_path.is_empty():
		simulation_root = get_node_or_null(simulation_root_path)
	elif get_parent() != null:
		simulation_root = get_parent().get_node_or_null("SimulationRoot")

	if simulation_root == null:
		return true

	var is_server_authoritative: Variant = simulation_root.get("is_server_authoritative")
	if not _variant_to_bool(is_server_authoritative):
		return true

	var peer: MultiplayerPeer = multiplayer.multiplayer_peer
	if peer == null or peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		return true

	return multiplayer.is_server()


func _variant_to_bool(value: Variant) -> bool:
	match typeof(value):
		TYPE_BOOL:
			return value
		TYPE_INT, TYPE_FLOAT:
			return value != 0
		TYPE_STRING:
			var normalized := String(value).strip_edges().to_lower()
			return normalized == "true" or normalized == "1"
		_:
			return value != null
