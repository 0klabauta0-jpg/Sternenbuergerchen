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

var _enemy_units: Array = []
var _spawn_positions_by_unit_id: Dictionary = {}
var _current_wave_number: int = 0
var _time_until_next_wave: float = 0.0
var _status_label: Label = null
var _all_waves_complete_emitted: bool = false


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
		if enemy_unit is Node2D:
			_spawn_positions_by_unit_id[String(enemy_unit.call("get_unit_id"))] = (enemy_unit as Node2D).global_position

		_deactivate_enemy_unit(enemy_unit)

	_time_until_next_wave = maxf(first_wave_delay_seconds, 0.0)
	if _enemy_units.is_empty():
		_refresh_status_label()
		return

	if _time_until_next_wave <= 0.0:
		_start_next_wave()
		if not are_all_waves_started():
			_time_until_next_wave = maxf(wave_delay_seconds, 0.0)

	_refresh_status_label()


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
	if _status_label == null:
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
	_ensure_status_label()
	_refresh_status_label()
