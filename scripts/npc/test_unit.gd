class_name TestUnit
extends Node2D

const UNIT_RUNTIME_STATUS_SCRIPT: GDScript = preload("res://scripts/npc/unit_runtime_status.gd")
const UNIT_VITAL_STATUS_SCRIPT: GDScript = preload("res://scripts/npc/unit_vital_status.gd")
const STATUS_LABEL_NAME: String = "DebugStatusLabel"
const EVENT_LABEL_NAME: String = "DebugEventLabel"
const STATUS_LABEL_OFFSET: Vector2 = Vector2(-54.0, -48.0)
const EVENT_LABEL_OFFSET: Vector2 = Vector2(-42.0, -70.0)
const EVENT_DURATION_SECONDS: float = 1.2

signal runtime_status_changed(runtime_status)
signal unit_command_assigned(command)
signal damage_applied(amount, health_points, hit_context)
signal vital_status_changed(vital_status)

@export var unit_id: String = "unit_test_001"
@export var display_name: String = "Test Unit"
@export var team_id: String = "team_test"
@export var team_display_name: String = ""
@export var role_name: String = ""
@export var max_health_points: int = 100

var _runtime_status: RefCounted = UNIT_RUNTIME_STATUS_SCRIPT.new()
var _current_unit_command: RefCounted = null
var _vital_status: RefCounted = UNIT_VITAL_STATUS_SCRIPT.new()
var _last_damage_context: Dictionary = {}
var _status_label: Label = null
var _event_label: Label = null
var _current_event_text: String = ""
var _current_event_color: Color = Color(1.0, 0.95, 0.5, 1.0)
var _event_time_remaining: float = 0.0
var _contact_active: bool = false
var _contact_target_id: String = ""


func _ready() -> void:
	_ensure_readability_labels()
	_runtime_status = _build_runtime_status("idle")
	_vital_status = _build_vital_status("fit", max_health_points, 0)
	_apply_vital_visual()
	_refresh_readability()


func _process(delta: float) -> void:
	_sync_readability_positions()
	if _event_time_remaining > 0.0:
		_event_time_remaining = maxf(_event_time_remaining - delta, 0.0)
		if _event_time_remaining == 0.0:
			_current_event_text = ""
			_refresh_event_label()


func get_unit_id() -> String:
	return unit_id


func get_runtime_status():
	return _runtime_status


func get_current_unit_command():
	return _current_unit_command


func get_health() -> int:
	return int(_vital_status.health_points)


func get_team_id() -> String:
	return team_id


func get_team_display_name() -> String:
	if not team_display_name.is_empty():
		return team_display_name

	var compact_team_id: String = team_id
	if compact_team_id.begins_with("team_"):
		compact_team_id = compact_team_id.substr(5)

	return compact_team_id.to_upper()


func get_role_name() -> String:
	return role_name


func get_vital_status():
	return _vital_status


func get_vital_state() -> String:
	return String(_vital_status.state)


func get_fire_status() -> String:
	return String(_runtime_status.fire_status)


func get_source_command_type() -> String:
	return String(_runtime_status.source_command_type)


func get_cover_score() -> float:
	return float(_runtime_status.cover_score)


func get_attack_bonus() -> float:
	return float(_runtime_status.attack_bonus)


func get_last_damage_context() -> Dictionary:
	return _last_damage_context.duplicate(true)


func get_target_position():
	return _runtime_status.target_position


func apply_damage(amount: int, hit_context: Dictionary = {}) -> bool:
	if amount <= 0:
		return false

	var next_health: int = maxi(get_health() - amount, 0)
	var next_state: String = String(_vital_status.state)
	if next_health == 0 and next_state == "fit":
		next_state = "down"

	_set_vital_status(next_state, next_health, int(_vital_status.bleedout_ticks))
	_last_damage_context = hit_context.duplicate(true)
	show_event_text("HIT -%d" % amount, Color(1.0, 0.8, 0.35, 1.0))
	damage_applied.emit(amount, next_health, _last_damage_context)
	return true


func advance_bleedout() -> bool:
	if String(_vital_status.state) != "down":
		return false

	_set_vital_status("bleedout", get_health(), int(_vital_status.bleedout_ticks) + 1)
	show_event_text("BLEEDOUT", Color(0.95, 0.55, 0.55, 1.0))
	return true


func set_target_position(target_position: Variant) -> bool:
	return set_runtime_status(
		String(_runtime_status.status),
		String(_runtime_status.active_command_type),
		int(_runtime_status.priority),
		String(_runtime_status.fire_status),
		String(_runtime_status.source_command_type),
		float(_runtime_status.cover_score),
		float(_runtime_status.attack_bonus),
		int(_runtime_status.phase),
		target_position
	)


func assign_unit_command(command) -> bool:
	if command == null or not command.has_method("is_valid") or not bool(command.call("is_valid")):
		push_warning("TestUnit.assign_unit_command expects a valid UnitCommand-like object.")
		return false

	_current_unit_command = command

	var status_name: String = _map_unit_command_to_status(String(command.get("command_type")))
	if not set_runtime_status(
		status_name,
		String(command.get("command_type")),
		int(command.get("priority")),
		String(command.get("fire_status")),
		String(command.get("source_command_type")),
		float(command.get("cover_score")),
		float(command.get("attack_bonus")),
		int(command.get("phase")),
		command.get("target_position")
	):
		return false

	unit_command_assigned.emit(command)
	_refresh_readability()
	return true


func set_runtime_status(
	status_name: String,
	active_command_type: String = "",
	priority: int = 0,
	fire_status: String = "fire_at_will",
	source_command_type: String = "",
	cover_score: float = 0.0,
	attack_bonus: float = 0.0,
	phase: int = -1,
	target_position: Variant = null
) -> bool:
	var runtime_status = _build_runtime_status(
		status_name,
		active_command_type,
		priority,
		fire_status,
		source_command_type,
		cover_score,
		attack_bonus,
		phase,
		target_position
	)
	if not bool(runtime_status.call("is_valid")):
		push_warning("TestUnit.set_runtime_status expects a valid UnitRuntimeStatus-compatible value.")
		return false

	_runtime_status = runtime_status
	runtime_status_changed.emit(_runtime_status)
	_refresh_readability()
	return true


func set_contact_state(is_active: bool, target_unit_id: String = "") -> void:
	_contact_active = is_active
	_contact_target_id = target_unit_id
	_refresh_status_label()


func show_event_text(event_text: String, event_color: Color = Color(1.0, 0.95, 0.5, 1.0), duration_seconds: float = EVENT_DURATION_SECONDS) -> void:
	_current_event_text = event_text
	_current_event_color = event_color
	_event_time_remaining = duration_seconds
	_refresh_event_label()


func _build_runtime_status(
	status_name: String,
	active_command_type: String = "",
	priority: int = 0,
	fire_status: String = "fire_at_will",
	source_command_type: String = "",
	cover_score: float = 0.0,
	attack_bonus: float = 0.0,
	phase: int = -1,
	target_position: Variant = null
):
	var runtime_status = UNIT_RUNTIME_STATUS_SCRIPT.new()
	runtime_status.status = status_name
	runtime_status.active_command_type = active_command_type
	runtime_status.priority = priority
	runtime_status.unit_id = unit_id
	runtime_status.team_id = team_id
	runtime_status.fire_status = fire_status
	runtime_status.source_command_type = source_command_type
	runtime_status.cover_score = cover_score
	runtime_status.attack_bonus = attack_bonus
	runtime_status.target_position = target_position
	runtime_status.phase = phase
	return runtime_status


func _build_vital_status(state: String, health_points: int, bleedout_ticks: int):
	var vital_status = UNIT_VITAL_STATUS_SCRIPT.new()
	vital_status.state = state
	vital_status.health_points = health_points
	vital_status.bleedout_ticks = bleedout_ticks
	return vital_status


func _set_vital_status(state: String, health_points: int, bleedout_ticks: int) -> void:
	var vital_status = _build_vital_status(state, health_points, bleedout_ticks)
	if not bool(vital_status.call("is_valid")):
		return

	_vital_status = vital_status
	_apply_vital_visual()
	vital_status_changed.emit(_vital_status)
	_refresh_readability()


func _map_unit_command_to_status(command_type: String) -> String:
	match command_type:
		"move_to_position":
			return "pending_move"
		"engage_area":
			return "engaging"
		"hold_position":
			return "holding"
		_:
			return "assigned"


func _apply_vital_visual() -> void:
	match String(_vital_status.state):
		"down":
			modulate = Color(1.0, 0.55, 0.55, 0.85)
			rotation_degrees = 28.0
		"bleedout":
			modulate = Color(0.45, 0.45, 0.45, 0.7)
			rotation_degrees = 45.0
		_:
			modulate = Color(1.0, 1.0, 1.0, 1.0)
			rotation_degrees = 0.0


func _ensure_readability_labels() -> void:
	_status_label = get_node_or_null(STATUS_LABEL_NAME) as Label
	if _status_label == null:
		_status_label = Label.new()
		_status_label.name = STATUS_LABEL_NAME
		_status_label.top_level = true
		add_child(_status_label)

	_event_label = get_node_or_null(EVENT_LABEL_NAME) as Label
	if _event_label == null:
		_event_label = Label.new()
		_event_label.name = EVENT_LABEL_NAME
		_event_label.top_level = true
		add_child(_event_label)

	_status_label.add_theme_font_size_override("font_size", 11)
	_event_label.add_theme_font_size_override("font_size", 12)
	_status_label.add_theme_constant_override("outline_size", 2)
	_event_label.add_theme_constant_override("outline_size", 2)
	_status_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	_event_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	_sync_readability_positions()


func _sync_readability_positions() -> void:
	if _status_label != null:
		_status_label.visible = is_visible_in_tree()
		_status_label.global_position = global_position + STATUS_LABEL_OFFSET

	if _event_label != null:
		_event_label.visible = is_visible_in_tree() and not _current_event_text.is_empty()
		_event_label.global_position = global_position + EVENT_LABEL_OFFSET


func _refresh_readability() -> void:
	_refresh_status_label()
	_refresh_event_label()
	_sync_readability_positions()


func _refresh_status_label() -> void:
	if _status_label == null:
		return

	var lines: PackedStringArray = []
	var identity_label: String = _build_identity_label()
	if not identity_label.is_empty():
		lines.append(identity_label)

	lines.append(_build_unit_name_label())
	lines.append(_build_primary_status_label())
	var secondary_label: String = _build_secondary_status_label()
	if not secondary_label.is_empty():
		lines.append(secondary_label)

	_status_label.text = "\n".join(lines)
	_status_label.modulate = _build_status_label_color()


func _refresh_event_label() -> void:
	if _event_label == null:
		return

	_event_label.text = _current_event_text
	_event_label.modulate = _current_event_color
	_event_label.visible = not _current_event_text.is_empty()


func _build_unit_name_label() -> String:
	if not display_name.is_empty():
		return display_name

	return unit_id


func _build_identity_label() -> String:
	var team_label: String = get_team_display_name()
	if team_label.is_empty() and role_name.is_empty():
		return ""

	if role_name.is_empty():
		return team_label

	if team_label.is_empty():
		return role_name

	return "%s / %s" % [team_label, role_name]


func _build_primary_status_label() -> String:
	var vital_state: String = String(_vital_status.state)
	match vital_state:
		"down":
			return "DOWN"
		"bleedout":
			return "BLEEDOUT"

	var source_command_type: String = String(_runtime_status.source_command_type)
	match source_command_type:
		"move":
			return "MOVE"
		"defend":
			return "DEFEND"
		"flank":
			return "FLANK"
		"take":
			return "ENGAGE"

	match String(_runtime_status.status):
		"engaging":
			return "ENGAGE"
		"holding":
			return "HOLD"
		"pending_move":
			return "MOVE"
		"assigned":
			return "ASSIGNED"
		_:
			return "IDLE"


func _build_secondary_status_label() -> String:
	var parts: PackedStringArray = []
	var fire_status: String = String(_runtime_status.fire_status)
	if fire_status == "hold_fire":
		parts.append("HF")
	elif fire_status == "fire_at_will":
		parts.append("FAW")

	if _contact_active:
		parts.append("LOS")

	if get_health() < max_health_points and String(_vital_status.state) == "fit":
		parts.append("HP %d" % get_health())

	return " ".join(parts)


func _build_status_label_color() -> Color:
	if String(_vital_status.state) == "down":
		return Color(1.0, 0.78, 0.78, 1.0)

	if String(_vital_status.state) == "bleedout":
		return Color(0.82, 0.82, 0.82, 1.0)

	if team_id == "team_alpha":
		return Color(0.85, 0.95, 1.0, 1.0)

	return Color(1.0, 0.88, 0.88, 1.0)
