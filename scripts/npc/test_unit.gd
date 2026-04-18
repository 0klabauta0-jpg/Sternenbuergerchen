class_name TestUnit
extends Node2D

const COMMANDER_COMMAND_SCRIPT: GDScript = preload("res://scripts/command/commander_command.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const UNIT_SKILLS_SCRIPT: GDScript = preload("res://scripts/npc/unit_skills.gd")
const UNIT_TRAIT_SCRIPT: GDScript = preload("res://scripts/npc/unit_trait.gd")
const UNIT_RUNTIME_STATUS_SCRIPT: GDScript = preload("res://scripts/npc/unit_runtime_status.gd")
const UNIT_VITAL_STATUS_SCRIPT: GDScript = preload("res://scripts/npc/unit_vital_status.gd")
const STATUS_LABEL_NAME: String = "DebugStatusLabel"
const FIRETEAM_LABEL_NAME: String = "DebugFireteamLabel"
const PHASE_LABEL_NAME: String = "DebugPhaseLabel"
const EVENT_LABEL_NAME: String = "DebugEventLabel"
const STATUS_LABEL_OFFSET: Vector2 = Vector2(-54.0, -48.0)
const FIRETEAM_LABEL_SPACING: float = 8.0
const EVENT_LABEL_OFFSET: Vector2 = Vector2(-42.0, -70.0)
const EVENT_DURATION_SECONDS: float = 1.2
const REMOTE_POSITION_LERP_WEIGHT: float = 0.75

signal runtime_status_changed(runtime_status)
signal unit_command_assigned(command)
signal damage_applied(amount, health_points, hit_context)
signal vital_status_changed(vital_status)

@export var unit_id: String = "unit_test_001"
@export var display_name: String = "Test Unit"
@export var team_id: String = "team_test"
@export var fireteam_id: String = ""
@export var max_health_points: int = 100
@export_range(0.0, 1.0, 0.01) var skill_accuracy: float = 0.5
@export_range(0.0, 1.0, 0.01) var skill_speed: float = 0.5
@export_range(0.0, 1.0, 0.01) var skill_leadership: float = 0.3
@export_range(0.0, 1.0, 0.01) var skill_toughness: float = 0.5
@export var trait_ids: PackedStringArray = []

var _runtime_status: RefCounted = UNIT_RUNTIME_STATUS_SCRIPT.new()
var _current_unit_command: RefCounted = null
var _vital_status: RefCounted = UNIT_VITAL_STATUS_SCRIPT.new()
var _skills: RefCounted = UNIT_SKILLS_SCRIPT.new()
var _traits: Array = []
var _last_damage_context: Dictionary = {}
var _status_label: Label = null
var _fireteam_label: Label = null
var _phase_label: Label = null
var _event_label: Label = null
var _current_event_text: String = ""
var _current_event_color: Color = Color(1.0, 0.95, 0.5, 1.0)
var _event_time_remaining: float = 0.0
var _contact_active: bool = false
var _contact_target_id: String = ""
var _respawn_manager = null
var _terrain_registry = null


func _ready() -> void:
	fireteam_id = _normalize_fireteam_id(fireteam_id)
	_rebuild_identity_data()
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


func get_display_name() -> String:
	return display_name


func get_fireteam_id() -> String:
	return fireteam_id


func get_vital_status():
	return _vital_status


func get_vital_state() -> String:
	return String(_vital_status.state)


func get_fire_status() -> String:
	return String(_runtime_status.fire_status)


func get_phase() -> int:
	return int(_runtime_status.phase)


func get_source_command_type() -> String:
	return String(_runtime_status.source_command_type)


func get_move_speed_factor() -> float:
	return float(_runtime_status.move_speed_factor)


func get_cover_score() -> float:
	return float(_runtime_status.cover_score)


func get_attack_bonus() -> float:
	return float(_runtime_status.attack_bonus)


func get_last_damage_context() -> Dictionary:
	return _last_damage_context.duplicate(true)


func get_skills():
	return _skills


func get_accuracy_skill() -> float:
	return float(_skills.accuracy)


func get_speed_skill() -> float:
	return float(_skills.speed)


func get_leadership_skill() -> float:
	return float(_skills.leadership)


func get_toughness_skill() -> float:
	return float(_skills.toughness)


func get_effective_cover_score() -> int:
	return int(roundi(clampf(get_cover_score() + _get_terrain_cover_bonus(), 0.0, 80.0)))


func get_height_level() -> int:
	if _terrain_registry == null or not _terrain_registry.has_method("get_height_at_world"):
		return 0

	return int(_terrain_registry.call("get_height_at_world", global_position))


func get_surface_type() -> String:
	if _terrain_registry == null or not _terrain_registry.has_method("get_surface_type_at_world"):
		return TERRAIN_TILE_DATA_SCRIPT.DEFAULT_SURFACE_TYPE

	return String(_terrain_registry.call("get_surface_type_at_world", global_position))


func get_surface_speed_factor() -> float:
	if _terrain_registry == null or not _terrain_registry.has_method("get_surface_speed_factor_at_world"):
		return 1.0

	return float(_terrain_registry.call("get_surface_speed_factor_at_world", global_position))


func get_traits() -> Array:
	return _traits.duplicate()


func get_trait_ids() -> PackedStringArray:
	return trait_ids.duplicate()


func get_trait_tags() -> PackedStringArray:
	var tags: PackedStringArray = []
	for unit_trait in _traits:
		if unit_trait == null:
			continue

		tags.append("[%s]" % String(unit_trait.short_tag))

	return tags


func get_skill_summary_text() -> String:
	return "A:%.1f S:%.1f L:%.1f T:%.1f" % [
		get_accuracy_skill(),
		get_speed_skill(),
		get_leadership_skill(),
		get_toughness_skill(),
	]


func get_trait_summary_text() -> String:
	return " ".join(get_trait_tags())


func get_target_position():
	return _runtime_status.target_position


func apply_identity_config(identity_config: Dictionary) -> void:
	if identity_config.has("unit_id"):
		unit_id = String(identity_config["unit_id"]).strip_edges()

	if identity_config.has("display_name"):
		display_name = String(identity_config["display_name"])

	if identity_config.has("team_id"):
		team_id = String(identity_config["team_id"]).strip_edges()

	if identity_config.has("fireteam_id"):
		fireteam_id = _normalize_fireteam_id(String(identity_config["fireteam_id"]))

	if identity_config.has("skill_accuracy"):
		skill_accuracy = clampf(float(identity_config["skill_accuracy"]), 0.0, 1.0)

	if identity_config.has("skill_speed"):
		skill_speed = clampf(float(identity_config["skill_speed"]), 0.0, 1.0)

	if identity_config.has("skill_leadership"):
		skill_leadership = clampf(float(identity_config["skill_leadership"]), 0.0, 1.0)

	if identity_config.has("skill_toughness"):
		skill_toughness = clampf(float(identity_config["skill_toughness"]), 0.0, 1.0)

	if identity_config.has("trait_ids"):
		trait_ids = _coerce_trait_ids(identity_config["trait_ids"])

	_rebuild_identity_data()
	_refresh_readability()


func set_fireteam_id(next_fireteam_id: String) -> bool:
	fireteam_id = _normalize_fireteam_id(next_fireteam_id)

	if _runtime_status == null:
		_refresh_readability()
		return true

	var runtime_status = _build_runtime_status(
		String(_runtime_status.status),
		String(_runtime_status.active_command_type),
		int(_runtime_status.priority),
		String(_runtime_status.fire_status),
		String(_runtime_status.source_command_type),
		float(_runtime_status.move_speed_factor),
		float(_runtime_status.cover_score),
		float(_runtime_status.attack_bonus),
		int(_runtime_status.phase),
		_runtime_status.target_position
	)
	if not bool(runtime_status.call("is_valid")):
		return false

	_runtime_status = runtime_status
	runtime_status_changed.emit(_runtime_status)
	_refresh_readability()
	return true


func set_respawn_manager(respawn_manager) -> void:
	_respawn_manager = respawn_manager
	_refresh_readability()


func set_terrain_registry(terrain_registry) -> void:
	_terrain_registry = terrain_registry
	_refresh_readability()


func apply_remote_snapshot(snapshot: Dictionary, interpolation_alpha: float = REMOTE_POSITION_LERP_WEIGHT) -> void:
	if typeof(snapshot) != TYPE_DICTIONARY:
		return

	if self is CanvasItem and snapshot.has("visible"):
		visible = bool(snapshot["visible"])

	if snapshot.has("position"):
		var remote_position: Vector2 = snapshot["position"] if snapshot["position"] is Vector2 else global_position
		global_position = global_position.lerp(remote_position, clampf(interpolation_alpha, 0.0, 1.0))

	if snapshot.has("fireteam_id"):
		fireteam_id = _normalize_fireteam_id(String(snapshot["fireteam_id"]))

	_apply_remote_runtime_status(_build_remote_runtime_dict(snapshot))
	_apply_remote_vital_status(_build_remote_vital_dict(snapshot))

	_refresh_readability()


func apply_remote_vital_update(vital_update: Dictionary) -> void:
	if typeof(vital_update) != TYPE_DICTIONARY:
		return

	_apply_remote_vital_status(_build_remote_vital_dict(vital_update))
	_refresh_readability()


func refresh_terrain_readability() -> void:
	_refresh_readability()


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


func begin_respawn() -> bool:
	var vital_state: String = String(_vital_status.state)
	if vital_state != "down" and vital_state != "bleedout":
		return false

	_runtime_status = _build_runtime_status("idle")
	runtime_status_changed.emit(_runtime_status)
	_set_vital_status("respawning", get_health(), int(_vital_status.bleedout_ticks))
	_current_unit_command = null
	_contact_active = false
	_contact_target_id = ""
	_refresh_readability()
	show_event_text("RESPAWNING", Color(0.7, 0.9, 1.0, 1.0), 1.8)
	return true


func activate_for_wave(spawn_position: Vector2) -> void:
	position = spawn_position
	_current_unit_command = null
	_last_damage_context = {}
	_contact_active = false
	_contact_target_id = ""
	_current_event_text = ""
	_event_time_remaining = 0.0
	_runtime_status = _build_runtime_status("idle")
	runtime_status_changed.emit(_runtime_status)
	_set_vital_status("fit", max_health_points, 0)
	visible = true
	_refresh_event_label()
	_refresh_readability()


func deactivate_for_wave() -> void:
	_current_unit_command = null
	_last_damage_context = {}
	_contact_active = false
	_contact_target_id = ""
	_current_event_text = ""
	_event_time_remaining = 0.0
	_runtime_status = _build_runtime_status("idle")
	runtime_status_changed.emit(_runtime_status)
	_set_vital_status("fit", max_health_points, 0)
	visible = false
	_refresh_event_label()
	_refresh_readability()


func respawn(spawn_position: Vector2) -> bool:
	var vital_state: String = String(_vital_status.state)
	if vital_state != "down" and vital_state != "bleedout" and vital_state != "respawning":
		return false

	position = spawn_position
	_set_vital_status("fit", max_health_points, 0)
	_runtime_status = _build_runtime_status("idle")
	runtime_status_changed.emit(_runtime_status)
	_current_unit_command = null
	_last_damage_context = {}
	_contact_active = false
	_contact_target_id = ""
	_refresh_readability()
	show_event_text("RESPAWN", Color(0.5, 1.0, 0.7, 1.0), 2.0)
	return true


func set_target_position(target_position: Variant) -> bool:
	return set_runtime_status(
		String(_runtime_status.status),
		String(_runtime_status.active_command_type),
		int(_runtime_status.priority),
		String(_runtime_status.fire_status),
		String(_runtime_status.source_command_type),
		float(_runtime_status.move_speed_factor),
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
		float(command.get("move_speed_factor")),
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
	move_speed_factor: float = 1.0,
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
		move_speed_factor,
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
	move_speed_factor: float = 1.0,
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
	runtime_status.fireteam_id = fireteam_id
	runtime_status.fire_status = fire_status
	runtime_status.source_command_type = source_command_type
	runtime_status.move_speed_factor = move_speed_factor
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


func _apply_remote_runtime_status(runtime_dict: Dictionary) -> void:
	if runtime_dict.is_empty():
		return

	var merged_runtime_dict: Dictionary = runtime_dict.duplicate(true)
	if not merged_runtime_dict.has("unit_id"):
		merged_runtime_dict["unit_id"] = unit_id
	if not merged_runtime_dict.has("team_id"):
		merged_runtime_dict["team_id"] = team_id
	if not merged_runtime_dict.has("fireteam_id") and not fireteam_id.is_empty():
		merged_runtime_dict["fireteam_id"] = fireteam_id

	var runtime_status = UNIT_RUNTIME_STATUS_SCRIPT.call("from_dict", merged_runtime_dict)
	if runtime_status == null or not runtime_status.has_method("is_valid") or not bool(runtime_status.call("is_valid")):
		return

	_runtime_status = runtime_status
	runtime_status_changed.emit(_runtime_status)


func _apply_remote_vital_status(vital_dict: Dictionary) -> void:
	if vital_dict.is_empty():
		return

	var previous_state: String = String(_vital_status.state)
	var vital_status = UNIT_VITAL_STATUS_SCRIPT.call("from_dict", vital_dict)
	if vital_status == null or not vital_status.has_method("is_valid") or not bool(vital_status.call("is_valid")):
		return

	_vital_status = vital_status
	_apply_vital_visual()
	vital_status_changed.emit(_vital_status)
	if previous_state == "respawning" and String(_vital_status.state) == "fit":
		show_event_text("RESPAWN", Color(0.5, 1.0, 0.7, 1.0), 2.0)


func _build_remote_runtime_dict(snapshot: Dictionary) -> Dictionary:
	var runtime_variant: Variant = snapshot.get("runtime_status", {})
	if typeof(runtime_variant) == TYPE_DICTIONARY:
		return (runtime_variant as Dictionary).duplicate(true)

	var runtime_dict: Dictionary = {
		"status": String(snapshot.get("runtime_state", _runtime_status.status)),
		"active_command_type": String(snapshot.get("active_command_type", _runtime_status.active_command_type)),
		"priority": int(snapshot.get("priority", _runtime_status.priority)),
		"unit_id": String(snapshot.get("unit_id", unit_id)),
		"team_id": String(snapshot.get("team_id", team_id)),
		"fireteam_id": String(snapshot.get("fireteam_id", fireteam_id)),
		"fire_status": String(snapshot.get("fire_mode", _runtime_status.fire_status)),
		"source_command_type": String(snapshot.get("source_command_type", _runtime_status.source_command_type)),
		"move_speed_factor": float(snapshot.get("move_speed_factor", _runtime_status.move_speed_factor)),
		"cover_score": float(snapshot.get("cover_score", _runtime_status.cover_score)),
		"attack_bonus": float(snapshot.get("attack_bonus", _runtime_status.attack_bonus)),
		"phase": int(snapshot.get("phase", _runtime_status.phase)),
	}
	return runtime_dict


func _build_remote_vital_dict(snapshot: Dictionary) -> Dictionary:
	var vital_variant: Variant = snapshot.get("vital_status", {})
	if typeof(vital_variant) == TYPE_DICTIONARY:
		return (vital_variant as Dictionary).duplicate(true)

	return {
		"state": String(snapshot.get("vital_state", _vital_status.state)),
		"health_points": int(snapshot.get("health", _vital_status.health_points)),
		"bleedout_ticks": int(snapshot.get("bleedout_ticks", _vital_status.bleedout_ticks)),
	}


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
		"respawning":
			modulate = Color(0.7, 0.9, 1.0, 0.5)
			rotation_degrees = 0.0
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

	_fireteam_label = get_node_or_null(FIRETEAM_LABEL_NAME) as Label
	if _fireteam_label == null:
		_fireteam_label = Label.new()
		_fireteam_label.name = FIRETEAM_LABEL_NAME
		_fireteam_label.top_level = true
		add_child(_fireteam_label)

	_phase_label = get_node_or_null(PHASE_LABEL_NAME) as Label
	if _phase_label == null:
		_phase_label = Label.new()
		_phase_label.name = PHASE_LABEL_NAME
		_phase_label.top_level = true
		add_child(_phase_label)

	_event_label = get_node_or_null(EVENT_LABEL_NAME) as Label
	if _event_label == null:
		_event_label = Label.new()
		_event_label.name = EVENT_LABEL_NAME
		_event_label.top_level = true
		add_child(_event_label)

	_status_label.add_theme_font_size_override("font_size", 11)
	_fireteam_label.add_theme_font_size_override("font_size", 10)
	_phase_label.add_theme_font_size_override("font_size", 10)
	_event_label.add_theme_font_size_override("font_size", 12)
	_status_label.add_theme_constant_override("outline_size", 2)
	_fireteam_label.add_theme_constant_override("outline_size", 2)
	_phase_label.add_theme_constant_override("outline_size", 2)
	_event_label.add_theme_constant_override("outline_size", 2)
	_status_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	_fireteam_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	_phase_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	_event_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	_sync_readability_positions()


func _sync_readability_positions() -> void:
	if _status_label != null:
		_status_label.visible = is_visible_in_tree()
		_status_label.global_position = global_position + STATUS_LABEL_OFFSET
		if _fireteam_label != null:
			_fireteam_label.visible = is_visible_in_tree() and not fireteam_id.is_empty()
			_fireteam_label.global_position = _status_label.global_position + Vector2(_status_label.get_combined_minimum_size().x + FIRETEAM_LABEL_SPACING, 0.0)
		if _phase_label != null:
			var phase_offset_x: float = _status_label.get_combined_minimum_size().x + FIRETEAM_LABEL_SPACING
			if _fireteam_label != null and _fireteam_label.visible:
				phase_offset_x += _fireteam_label.get_combined_minimum_size().x + FIRETEAM_LABEL_SPACING
			_phase_label.visible = is_visible_in_tree() and not _build_phase_label_text().is_empty()
			_phase_label.global_position = _status_label.global_position + Vector2(phase_offset_x, 0.0)

	elif _fireteam_label != null:
		_fireteam_label.visible = is_visible_in_tree() and not fireteam_id.is_empty()
		_fireteam_label.global_position = global_position + STATUS_LABEL_OFFSET
		if _phase_label != null:
			_phase_label.visible = is_visible_in_tree() and not _build_phase_label_text().is_empty()
			_phase_label.global_position = global_position + STATUS_LABEL_OFFSET + Vector2(FIRETEAM_LABEL_SPACING, 0.0)

	if _event_label != null:
		_event_label.visible = is_visible_in_tree() and not _current_event_text.is_empty()
		_event_label.global_position = global_position + EVENT_LABEL_OFFSET


func _refresh_readability() -> void:
	_refresh_status_label()
	_refresh_fireteam_label()
	_refresh_phase_label()
	_refresh_event_label()
	_sync_readability_positions()


func _refresh_status_label() -> void:
	if _status_label == null:
		return

	var lines: PackedStringArray = []
	lines.append(_build_unit_name_label())
	var primary_status_label: String = _build_primary_status_label()
	if not primary_status_label.is_empty():
		lines.append(primary_status_label)

	var secondary_status_label: String = _build_secondary_status_label()
	if not secondary_status_label.is_empty():
		lines.append(secondary_status_label)

	var terrain_status_label: String = _build_terrain_status_label()
	if not terrain_status_label.is_empty():
		lines.append(terrain_status_label)

	lines.append(get_skill_summary_text())
	var trait_summary_text: String = get_trait_summary_text()
	if not trait_summary_text.is_empty():
		lines.append(trait_summary_text)

	_status_label.text = "\n".join(lines)
	_status_label.modulate = _build_status_label_color()


func _refresh_fireteam_label() -> void:
	if _fireteam_label == null:
		return

	if fireteam_id.is_empty():
		_fireteam_label.text = ""
		_fireteam_label.visible = false
		return

	_fireteam_label.text = fireteam_id.to_upper()
	_fireteam_label.modulate = _build_fireteam_label_color()
	_fireteam_label.visible = is_visible_in_tree()


func _refresh_phase_label() -> void:
	if _phase_label == null:
		return

	var phase_text: String = _build_phase_label_text()
	_phase_label.text = phase_text
	_phase_label.modulate = Color(0.88, 0.98, 0.88, 1.0)
	_phase_label.visible = is_visible_in_tree() and not phase_text.is_empty()


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


func _build_primary_status_label() -> String:
	var vital_state: String = String(_vital_status.state)
	match vital_state:
		"down":
			return "DOWN"
		"bleedout":
			return "BLEEDOUT"
		"respawning":
			var respawn_seconds: int = _get_respawn_remaining_seconds()
			if respawn_seconds > 0:
				return "RESPAWN %ds" % respawn_seconds
			return "RESPAWNING"

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
	if String(_vital_status.state) != "fit":
		return ""

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


func _build_terrain_status_label() -> String:
	var effective_cover: int = get_effective_cover_score()
	var height_level: int = get_height_level()
	var surface_type: String = get_surface_type()
	var surface_speed_factor: float = get_surface_speed_factor()
	if _terrain_registry == null and effective_cover <= 0 and height_level <= 0 and surface_type == TERRAIN_TILE_DATA_SCRIPT.DEFAULT_SURFACE_TYPE:
		return ""

	return "COV:%d H:%d %s:%.1f" % [
		effective_cover,
		height_level,
		TERRAIN_TILE_DATA_SCRIPT.get_surface_short_code(surface_type),
		surface_speed_factor,
	]


func _build_status_label_color() -> Color:
	if String(_vital_status.state) == "down":
		return Color(1.0, 0.78, 0.78, 1.0)

	if String(_vital_status.state) == "bleedout":
		return Color(0.82, 0.82, 0.82, 1.0)

	if String(_vital_status.state) == "respawning":
		return Color(0.7, 0.9, 1.0, 0.8)

	if team_id == "team_alpha":
		return Color(0.85, 0.95, 1.0, 1.0)

	return Color(1.0, 0.88, 0.88, 1.0)


func _build_fireteam_label_color() -> Color:
	match fireteam_id:
		"blue":
			return Color(0.45, 0.72, 1.0, 1.0)
		"gold":
			return Color(1.0, 0.88, 0.35, 1.0)
		_:
			return Color(0.9, 0.9, 0.9, 1.0)


func _build_phase_label_text() -> String:
	return COMMANDER_COMMAND_SCRIPT.get_phase_short_name(int(_runtime_status.phase))


func _normalize_fireteam_id(value: String) -> String:
	return value.strip_edges().to_lower()


func _get_respawn_remaining_seconds() -> int:
	if _respawn_manager == null or not _respawn_manager.has_method("get_remaining_time"):
		return 0

	return maxi(int(ceili(float(_respawn_manager.call("get_remaining_time", unit_id)))), 0)


func _get_terrain_cover_bonus() -> float:
	if _terrain_registry == null or not _terrain_registry.has_method("get_cover_at_world"):
		return 0.0

	return float(_terrain_registry.call("get_cover_at_world", global_position))


func _rebuild_identity_data() -> void:
	_skills = UNIT_SKILLS_SCRIPT.new(
		{
			"accuracy": skill_accuracy,
			"speed": skill_speed,
			"leadership": skill_leadership,
			"toughness": skill_toughness,
		}
	)
	_traits.clear()
	for trait_id in trait_ids:
		var unit_trait = UNIT_TRAIT_SCRIPT.from_id(String(trait_id))
		if unit_trait == null:
			continue

		unit_trait.apply_to_skills(_skills)
		_traits.append(unit_trait)


func _coerce_trait_ids(value: Variant) -> PackedStringArray:
	if value is PackedStringArray:
		return (value as PackedStringArray).duplicate()

	var result: PackedStringArray = []
	if value is Array:
		for entry in value:
			var trait_id: String = String(entry).strip_edges().to_lower()
			if trait_id.is_empty():
				continue

			result.append(trait_id)

	return result
