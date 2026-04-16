extends Node

const LOS_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/los_system.gd")
const CONTACT_LINE_NAME: String = "CombatContactLine"
const EVENT_LABEL_NAME: String = "CombatEventLabel"
const WINNER_LABEL_NAME: String = "CombatWinnerLabel"
const PHASE_APPROACH: int = 0
const PHASE_ASSAULT: int = 1
const PHASE_HOLD: int = 2
const OBJECTIVE_STATE_INACTIVE: String = "inactive"
const OBJECTIVE_STATE_NEUTRAL: String = "neutral"
const OBJECTIVE_STATE_CONTESTED: String = "contested"
const OBJECTIVE_STATE_SECURED: String = "secured"

signal contact_established(attacker, target)
signal combat_resolved(winning_team_id, neutralized_enemy_count)

@export var friendly_team_id: String = "team_alpha"
@export var contact_range: float = 180.0
@export var damage_per_hit: int = 40
@export var base_hit_chance: float = 0.45
@export var base_damage_multiplier: float = 1.0
@export var ticks_between_attacks: int = 10
@export var mission_goal: String = "secure_target"
@export var event_router_path: NodePath
@export var simulation_root_path: NodePath
@export var status_label_path: NodePath
@export var target_marker_path: NodePath
@export var objective_state_label_path: NodePath
@export var objective_capture_radius: float = 42.0
@export var objective_hold_ticks_required: int = 10
@export var friendly_unit_paths: Array[NodePath] = []
@export var enemy_unit_paths: Array[NodePath] = []

var _los_system = LOS_SYSTEM_SCRIPT.new()
var _queued_bleedout_by_unit_id: Dictionary = {}
var _queued_respawn_request_by_unit_id: Dictionary = {}
var _combat_finished: bool = false
var _winning_team_id: String = ""
var _resolution_reason: String = ""
var _last_contact: Dictionary = {}
var _current_tick: int = 0
var _next_attack_tick: int = 1
var _next_enemy_attack_tick: int = 1
var _last_event_text: String = "Combat waiting"
var _objective_progress_ticks: int = 0
var _objective_state: String = OBJECTIVE_STATE_NEUTRAL
var _objective_owner_team_id: String = ""
var _contact_line: Line2D = null
var _event_label: Label = null
var _winner_label: Label = null


func _ready() -> void:
	var simulation_root = get_node_or_null(simulation_root_path)
	if simulation_root == null:
		push_warning("MissionCombatLoopDriver requires a direct SimulationRoot reference.")
		return

	_connect_unit_signals()
	call_deferred("_finish_readability_setup")

	if not simulation_root.tick_processed.is_connected(_on_tick_processed):
		simulation_root.tick_processed.connect(_on_tick_processed)

	_update_status_label("waiting")


func is_combat_finished() -> bool:
	return _combat_finished


func get_winning_team_id() -> String:
	return _winning_team_id


func get_resolution_reason() -> String:
	return _resolution_reason


func get_objective_state() -> String:
	return _objective_state


func get_objective_progress_ticks() -> int:
	return _objective_progress_ticks


func get_objective_owner_team_id() -> String:
	return _objective_owner_team_id


func get_last_contact() -> Dictionary:
	return _last_contact.duplicate(true)


func _on_tick_processed(tick: int) -> void:
	_current_tick = tick
	if _combat_finished:
		_update_status_label("resolved")
		return

	var simulation_root = get_node_or_null(simulation_root_path)
	if simulation_root == null:
		return

	_queue_bleedout_for_downed_units(simulation_root, enemy_unit_paths)
	_queue_bleedout_for_downed_units(simulation_root, friendly_unit_paths)
	_try_enqueue_friendly_attacks(simulation_root)
	_try_enqueue_enemy_attacks(simulation_root)
	_update_objective_control()
	if _combat_finished:
		_update_status_label("resolved")
		return
	_update_combat_resolution()
	if not _combat_finished:
		_update_status_label("active")


func _queue_bleedout_for_downed_units(simulation_root: Node, unit_paths: Array[NodePath]) -> void:
	for unit in _get_units(unit_paths):
		if unit == null or not unit.has_method("get_vital_state") or not unit.has_method("get_unit_id"):
			continue

		var unit_id: String = String(unit.call("get_unit_id"))
		if unit_id.is_empty() or _queued_bleedout_by_unit_id.get(unit_id, false):
			continue

		if String(unit.call("get_vital_state")) != "down":
			continue

		simulation_root.call(
			"enqueue_effect",
			{
				"effect_type": "bleedout",
				"priority": 20,
				"unit_id": unit_id,
			}
		)
		_queued_bleedout_by_unit_id[unit_id] = true
		_set_event_text("%s BLEEDOUT" % unit_id)
		return


func _try_enqueue_friendly_attacks(simulation_root: Node) -> void:
	var contact_pair: Dictionary = _find_first_contact_pair_for_paths(friendly_unit_paths, enemy_unit_paths)
	if contact_pair.is_empty():
		_clear_contact_visuals()
		return

	var friendly = contact_pair["attacker"]
	var enemy = contact_pair["target"]
	var attacker_id: String = String(contact_pair["attacker_id"])
	var target_id: String = String(contact_pair["target_id"])
	if attacker_id.is_empty() or target_id.is_empty():
		_clear_contact_visuals()
		return

	_last_contact = {
		"attacker_id": attacker_id,
		"target_id": target_id,
	}
	_set_contact_visuals(friendly, enemy)
	_update_status_label("contact")
	if _current_tick < _next_attack_tick:
		return

	contact_established.emit(friendly, enemy)
	_set_event_text("%s ENGAGE %s" % [attacker_id, target_id])
	simulation_root.call(
		"enqueue_effect",
		{
			"effect_type": "damage",
			"priority": 30,
			"unit_id": target_id,
			"attacker_unit_id": attacker_id,
			"attacker_team_id": String(friendly.call("get_team_id")),
			"allow_friendly_fire": false,
			"damage": damage_per_hit,
			"hit_chance": base_hit_chance,
			"damage_multiplier": base_damage_multiplier,
			"roll_override": 0.4,
		}
	)
	_next_attack_tick = _current_tick + max(ticks_between_attacks, 1)


func _try_enqueue_enemy_attacks(simulation_root: Node) -> void:
	if not _has_active_friendly_orders():
		return

	var contact_pair: Dictionary = _find_first_contact_pair_for_paths(enemy_unit_paths, friendly_unit_paths, true)
	if contact_pair.is_empty():
		return

	var attacker = contact_pair["attacker"]
	var target = contact_pair["target"]
	var attacker_id: String = String(contact_pair["attacker_id"])
	var target_id: String = String(contact_pair["target_id"])
	if attacker_id.is_empty() or target_id.is_empty():
		return

	_last_contact = {
		"attacker_id": attacker_id,
		"target_id": target_id,
	}
	_set_contact_visuals(attacker, target)
	_update_status_label("contact")
	if _current_tick < _next_enemy_attack_tick:
		return

	contact_established.emit(attacker, target)
	_set_event_text("%s ENGAGE %s" % [attacker_id, target_id])
	simulation_root.call(
		"enqueue_effect",
		{
			"effect_type": "damage",
			"priority": 30,
			"unit_id": target_id,
			"attacker_unit_id": attacker_id,
			"attacker_team_id": String(attacker.call("get_team_id")),
			"allow_friendly_fire": false,
			"damage": damage_per_hit,
			"hit_chance": base_hit_chance,
			"damage_multiplier": base_damage_multiplier,
			"roll_override": 0.4,
		}
	)
	_next_enemy_attack_tick = _current_tick + max(ticks_between_attacks, 1)


func _update_combat_resolution() -> void:
	var enemy_units: Array = _get_units(enemy_unit_paths)
	var friendly_units: Array = _get_units(friendly_unit_paths)
	if enemy_units.is_empty() or friendly_units.is_empty():
		return

	var enemy_fit_count: int = 0
	for enemy in enemy_units:
		if enemy == null or not enemy.has_method("get_vital_state"):
			continue

		if String(enemy.call("get_vital_state")) == "fit":
			enemy_fit_count += 1

	if enemy_fit_count <= 0:
		_combat_finished = true
		_winning_team_id = friendly_team_id
		_resolution_reason = "enemy_neutralized"
		_set_event_text("ENEMY FORCE NEUTRALIZED")
		_clear_contact_visuals()
		_update_status_label("resolved")
		_update_winner_label()
		combat_resolved.emit(_winning_team_id, _count_neutralized_units(enemy_unit_paths))
		return

	var friendly_fit_count: int = 0
	for friendly in friendly_units:
		if friendly == null or not friendly.has_method("get_vital_state"):
			continue

		if String(friendly.call("get_vital_state")) == "fit":
			friendly_fit_count += 1

	if friendly_fit_count > 0:
		return

	_combat_finished = true
	_winning_team_id = _get_enemy_team_id()
	_resolution_reason = "friendly_force_neutralized"
	_set_event_text("FRIENDLY FORCE NEUTRALIZED")
	_clear_contact_visuals()
	_update_status_label("resolved")
	_update_winner_label()
	combat_resolved.emit(_winning_team_id, _count_neutralized_units(enemy_unit_paths))


func _update_objective_control() -> void:
	if mission_goal != "secure_target":
		_objective_progress_ticks = 0
		_objective_owner_team_id = ""
		_set_objective_state(OBJECTIVE_STATE_INACTIVE)
		return

	var target_marker = get_node_or_null(target_marker_path)
	if not (target_marker is Node2D):
		_objective_progress_ticks = 0
		_objective_owner_team_id = ""
		_set_objective_state(OBJECTIVE_STATE_INACTIVE)
		return

	var objective_position: Vector2 = target_marker.position
	if _is_objective_contested(objective_position):
		_objective_progress_ticks = 0
		_objective_owner_team_id = ""
		_set_objective_state(OBJECTIVE_STATE_CONTESTED)
		return

	var objective_holders: Array = _get_objective_holders(objective_position)
	if objective_holders.is_empty():
		_objective_progress_ticks = 0
		_objective_owner_team_id = ""
		_set_objective_state(OBJECTIVE_STATE_NEUTRAL)
		return

	var required_ticks: int = maxi(objective_hold_ticks_required, 1)
	_objective_progress_ticks = mini(_objective_progress_ticks + 1, required_ticks)
	_objective_owner_team_id = ""
	_set_objective_state(OBJECTIVE_STATE_NEUTRAL)
	if _objective_progress_ticks < required_ticks:
		return

	_resolve_objective_victory()


func _resolve_objective_victory() -> void:
	_combat_finished = true
	_winning_team_id = friendly_team_id
	_resolution_reason = "objective_secured"
	_objective_owner_team_id = friendly_team_id
	_set_objective_state(OBJECTIVE_STATE_SECURED)
	_set_event_text("OBJECTIVE SECURED")
	_clear_contact_visuals()
	_update_status_label("resolved")
	_update_winner_label()
	combat_resolved.emit(_winning_team_id, _count_neutralized_units(enemy_unit_paths))


func _get_objective_holders(objective_position: Vector2) -> Array:
	var holders: Array = []
	for unit in _get_units(friendly_unit_paths):
		if not _can_hold_objective(unit, objective_position):
			continue

		holders.append(unit)

	return holders


func _can_hold_objective(unit, objective_position: Vector2) -> bool:
	if unit == null or not _can_target_receive_attack(unit):
		return false

	if _get_unit_phase(unit) != PHASE_HOLD:
		return false

	if not _is_objective_ready(unit):
		return false

	if not (unit is Node2D):
		return false

	return (unit as Node2D).position.distance_to(objective_position) <= objective_capture_radius


func _is_objective_contested(objective_position: Vector2) -> bool:
	for enemy in _get_units(enemy_unit_paths):
		if enemy == null or not _can_target_receive_attack(enemy):
			continue

		if not (enemy is Node2D):
			continue

		if (enemy as Node2D).position.distance_to(objective_position) <= objective_capture_radius:
			return true

	return false


func _get_units(paths: Array[NodePath]) -> Array:
	var units: Array = []
	for path in paths:
		var unit = get_node_or_null(path)
		if unit != null and unit is Node2D:
			units.append(unit)

	return units


func _pick_target_for_attacker(attacker, target_paths: Array[NodePath]):
	for target in _get_units(target_paths):
		if not _is_target_attackable(attacker, target):
			continue

		return target

	return null


func _can_unit_attack(unit, allow_passive_engage: bool = false) -> bool:
	if unit == null:
		return false

	if not unit.has_method("get_vital_state"):
		return false

	if String(unit.call("get_vital_state")) != "fit":
		return false

	if unit.has_method("get_fire_status") and String(unit.call("get_fire_status")) != "fire_at_will":
		return false

	if not _is_phase_attack_allowed(unit):
		return false

	if allow_passive_engage:
		return true

	return _is_engage_ready(unit)


func _is_target_attackable(attacker, target) -> bool:
	if target == null or not _can_target_receive_attack(target):
		return false

	if attacker == null:
		return false

	if String(attacker.call("get_team_id")) == String(target.call("get_team_id")):
		return false

	return _los_system.has_line_of_sight_between_nodes(attacker, target, contact_range)


func _can_target_receive_attack(unit) -> bool:
	if unit == null or not unit.has_method("get_vital_state"):
		return false

	return String(unit.call("get_vital_state")) == "fit"


func _is_engage_ready(unit) -> bool:
	if unit == null:
		return false

	if unit.has_method("get_current_unit_command"):
		var command = unit.call("get_current_unit_command")
		if command != null and command.has_method("get"):
			var command_type: String = String(command.get("command_type"))
			if command_type == "engage_area" or command_type == "hold_position":
				return true

			return command_type == "move_to_position" and _is_mobile_engage_source(String(command.get("source_command_type")))

	if unit.has_method("get_runtime_status"):
		var runtime_status = unit.call("get_runtime_status")
		if runtime_status != null and runtime_status.has_method("get"):
			var status_name: String = String(runtime_status.get("status"))
			if status_name == "engaging" or status_name == "holding":
				return true

			return status_name == "pending_move" and _is_mobile_engage_source(String(runtime_status.get("source_command_type")))

	return false


func _is_mobile_engage_source(source_command_type: String) -> bool:
	return source_command_type == "flank" or source_command_type == "take"


func _is_phase_attack_allowed(unit) -> bool:
	var phase: int = _get_unit_phase(unit)
	if phase < 0:
		return true

	match phase:
		PHASE_APPROACH:
			return false
		PHASE_HOLD:
			return _is_hold_phase_ready(unit)
		_:
			return true


func _is_hold_phase_ready(unit) -> bool:
	if unit == null:
		return false

	if unit.has_method("get_current_unit_command"):
		var command = unit.call("get_current_unit_command")
		if command != null and command.has_method("get"):
			var command_type: String = String(command.get("command_type"))
			if command_type == "engage_area" or command_type == "hold_position":
				return true

	if unit.has_method("get_runtime_status"):
		var runtime_status = unit.call("get_runtime_status")
		if runtime_status != null and runtime_status.has_method("get"):
			var status_name: String = String(runtime_status.get("status"))
			if status_name == "engaging" or status_name == "holding":
				return true

	return false


func _is_objective_ready(unit) -> bool:
	if _is_hold_phase_ready(unit):
		return true

	if unit == null:
		return false

	if unit.has_method("get_current_unit_command"):
		var command = unit.call("get_current_unit_command")
		if command != null and command.has_method("get"):
			return String(command.get("command_type")) == "move_to_position" and String(command.get("source_command_type")) == "take"

	if unit.has_method("get_runtime_status"):
		var runtime_status = unit.call("get_runtime_status")
		if runtime_status != null and runtime_status.has_method("get"):
			return String(runtime_status.get("status")) == "pending_move" and String(runtime_status.get("source_command_type")) == "take"

	return false


func _get_unit_phase(unit) -> int:
	if unit == null:
		return -1

	if unit.has_method("get_current_unit_command"):
		var command = unit.call("get_current_unit_command")
		if command != null and command.has_method("get"):
			var raw_phase: Variant = command.get("phase")
			if typeof(raw_phase) == TYPE_INT or typeof(raw_phase) == TYPE_FLOAT:
				return int(raw_phase)

	if unit.has_method("get_runtime_status"):
		var runtime_status = unit.call("get_runtime_status")
		if runtime_status != null and runtime_status.has_method("get"):
			var raw_phase: Variant = runtime_status.get("phase")
			if typeof(raw_phase) == TYPE_INT or typeof(raw_phase) == TYPE_FLOAT:
				return int(raw_phase)

	return -1


func _update_status_label(state_name: String) -> void:
	var status_label = get_node_or_null(status_label_path)
	if status_label == null:
		return

	status_label.set("text", _build_status_text(state_name))


func _build_status_text(state_name: String) -> String:
	var lines: PackedStringArray = []
	lines.append("Combat: %s" % state_name)

	if _combat_finished and not _winning_team_id.is_empty():
		lines.append("Winner: %s" % _winning_team_id)

	lines.append("Enemies fit: %d" % _count_fit_units(enemy_unit_paths))
	lines.append("Friendlies fit: %d" % _count_fit_units(friendly_unit_paths))
	lines.append("Objective: %s" % _build_objective_state_text())
	if mission_goal == "secure_target" and _objective_state == OBJECTIVE_STATE_NEUTRAL and not _combat_finished:
		lines.append("Objective progress: %d/%d" % [_objective_progress_ticks, maxi(objective_hold_ticks_required, 1)])
	lines.append("Next shot: %s" % _build_attack_readiness_text())
	lines.append("Last event: %s" % _last_event_text)

	if not _last_contact.is_empty():
		lines.append("Last contact: %s -> %s" % [String(_last_contact.get("attacker_id", "")), String(_last_contact.get("target_id", ""))])

	return "\n".join(lines)


func _describe_friendly_unit(unit) -> String:
	if unit == null:
		return "- missing"

	var runtime_status = null
	var status_name: String = ""
	if unit.has_method("get_runtime_status"):
		runtime_status = unit.call("get_runtime_status")
		if runtime_status != null and runtime_status.has_method("get"):
			status_name = String(runtime_status.get("status"))

	var unit_command = null
	var command_type: String = ""
	if unit.has_method("get_current_unit_command"):
		unit_command = unit.call("get_current_unit_command")
		if unit_command != null and unit_command.has_method("get"):
			command_type = String(unit_command.get("command_type"))

	return "%s %s %s %s c%.2f a%.2f" % [
		String(unit.call("get_unit_id")),
		status_name,
		command_type,
		String(unit.call("get_fire_status")),
		float(unit.call("get_cover_score")),
		float(unit.call("get_attack_bonus")),
	]


func _describe_enemy_unit(unit) -> String:
	if unit == null:
		return "- missing"

	var health: int = 0
	if unit.has_method("get_health"):
		health = int(unit.call("get_health"))

	return "%s %s hp=%d" % [
		String(unit.call("get_unit_id")),
		String(unit.call("get_vital_state")),
		health,
	]


func _find_first_contact_pair_for_paths(attacker_paths: Array[NodePath], target_paths: Array[NodePath], allow_passive_engage: bool = false) -> Dictionary:
	for attacker in _get_units(attacker_paths):
		if not _can_unit_attack(attacker, allow_passive_engage):
			continue

		var target = _pick_target_for_attacker(attacker, target_paths)
		if target == null:
			continue

		return {
			"attacker": attacker,
			"target": target,
			"attacker_id": String(attacker.call("get_unit_id")),
			"target_id": String(target.call("get_unit_id")),
		}

	return {}


func _has_active_friendly_orders() -> bool:
	for unit in _get_units(friendly_unit_paths):
		if unit == null or not unit.has_method("get_runtime_status"):
			continue

		var runtime_status = unit.call("get_runtime_status")
		if runtime_status == null or not runtime_status.has_method("get"):
			continue

		if String(runtime_status.get("status")) != "idle":
			return true

	return false


func _get_enemy_team_id() -> String:
	for enemy in _get_units(enemy_unit_paths):
		if enemy == null or not enemy.has_method("get_team_id"):
			continue

		var enemy_team_id: String = String(enemy.call("get_team_id"))
		if not enemy_team_id.is_empty():
			return enemy_team_id

	return "team_bravo"


func _ensure_readability_nodes() -> void:
	var scene_root = get_parent()
	if scene_root == null:
		return

	_contact_line = scene_root.get_node_or_null(CONTACT_LINE_NAME) as Line2D
	if _contact_line == null:
		_contact_line = Line2D.new()
		_contact_line.name = CONTACT_LINE_NAME
		_contact_line.default_color = Color(1.0, 0.92, 0.35, 0.9)
		_contact_line.width = 2.0
		_contact_line.z_index = 20
		scene_root.add_child(_contact_line)

	_event_label = scene_root.get_node_or_null(EVENT_LABEL_NAME) as Label
	if _event_label == null:
		_event_label = Label.new()
		_event_label.name = EVENT_LABEL_NAME
		_event_label.top_level = true
		_event_label.position = Vector2(16.0, 220.0)
		_event_label.add_theme_font_size_override("font_size", 14)
		_event_label.add_theme_constant_override("outline_size", 2)
		_event_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
		scene_root.add_child(_event_label)

	_winner_label = scene_root.get_node_or_null(WINNER_LABEL_NAME) as Label
	if _winner_label == null:
		_winner_label = Label.new()
		_winner_label.name = WINNER_LABEL_NAME
		_winner_label.top_level = true
		_winner_label.position = Vector2(280.0, 16.0)
		_winner_label.add_theme_font_size_override("font_size", 20)
		_winner_label.add_theme_constant_override("outline_size", 3)
		_winner_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
		scene_root.add_child(_winner_label)


func _connect_unit_signals() -> void:
	for unit in _get_units(friendly_unit_paths) + _get_units(enemy_unit_paths):
		if unit == null:
			continue

		if unit.has_signal("damage_applied"):
			var damage_callable := Callable(self, "_on_unit_damage_applied").bind(unit)
			if not unit.is_connected("damage_applied", damage_callable):
				unit.connect("damage_applied", damage_callable)

		if unit.has_signal("vital_status_changed"):
			var vital_callable := Callable(self, "_on_unit_vital_status_changed").bind(unit)
			if not unit.is_connected("vital_status_changed", vital_callable):
				unit.connect("vital_status_changed", vital_callable)


func _set_contact_visuals(attacker, target) -> void:
	_clear_unit_contact_states()
	if attacker == null or target == null:
		if _contact_line != null:
			_contact_line.clear_points()
		return

	if _contact_line != null:
		_contact_line.clear_points()
		_contact_line.add_point(attacker.position)
		_contact_line.add_point(target.position)

	if attacker.has_method("set_contact_state"):
		attacker.call("set_contact_state", true, String(target.call("get_unit_id")))

	if target.has_method("set_contact_state"):
		target.call("set_contact_state", true, String(attacker.call("get_unit_id")))


func _clear_contact_visuals() -> void:
	_clear_unit_contact_states()
	if _contact_line != null:
		_contact_line.clear_points()


func _clear_unit_contact_states() -> void:
	for unit in _get_units(friendly_unit_paths) + _get_units(enemy_unit_paths):
		if unit != null and unit.has_method("set_contact_state"):
			unit.call("set_contact_state", false, "")


func _on_unit_damage_applied(amount: int, _health_points: int, _hit_context: Dictionary, unit) -> void:
	var unit_id: String = String(unit.call("get_unit_id"))
	_set_event_text("%s HIT -%d" % [unit_id, amount])
	if unit.has_method("show_event_text"):
		unit.call("show_event_text", "HIT -%d" % amount, Color(1.0, 0.78, 0.35, 1.0))
	_update_status_label("contact")


func _on_unit_vital_status_changed(vital_status, unit) -> void:
	if vital_status == null or not vital_status.has_method("get"):
		return

	var unit_id: String = String(unit.call("get_unit_id"))
	var vital_state: String = String(vital_status.get("state"))
	match vital_state:
		"down":
			_set_event_text("%s DOWN" % unit_id)
			if unit.has_method("show_event_text"):
				unit.call("show_event_text", "DOWN", Color(1.0, 0.55, 0.55, 1.0), 1.5)
		"bleedout":
			_queue_respawn_request(unit, unit_id)
			_set_event_text("%s BLEEDOUT" % unit_id)
			if unit.has_method("show_event_text"):
				unit.call("show_event_text", "BLEEDOUT", Color(0.92, 0.6, 0.6, 1.0), 1.6)
		"fit":
			_queued_bleedout_by_unit_id.erase(unit_id)
			_queued_respawn_request_by_unit_id.erase(unit_id)
	_update_status_label("active")


func _queue_respawn_request(unit, unit_id: String) -> void:
	if unit == null or unit_id.is_empty():
		return

	if not unit.has_method("get_team_id"):
		return

	if String(unit.call("get_team_id")) != friendly_team_id:
		return

	if _queued_respawn_request_by_unit_id.get(unit_id, false):
		return

	var event_router = get_node_or_null(event_router_path)
	if event_router == null or not event_router.has_method("request_respawn"):
		return

	event_router.call("request_respawn", unit, "fob")
	_queued_respawn_request_by_unit_id[unit_id] = true
	if unit.has_method("show_event_text"):
		unit.call("show_event_text", "RESPAWN FOB", Color(0.72, 0.95, 1.0, 1.0), 1.4)


func _set_event_text(event_text: String) -> void:
	_last_event_text = event_text
	_update_event_label()


func _update_event_label() -> void:
	if _event_label == null:
		return

	_event_label.text = "Event: %s" % _last_event_text


func _update_winner_label() -> void:
	if _winner_label == null:
		return

	if _combat_finished and not _winning_team_id.is_empty():
		if _resolution_reason == "objective_secured":
			_winner_label.text = "OBJECTIVE SECURED\nWinner: %s" % _winning_team_id
		elif _winning_team_id == friendly_team_id:
			_winner_label.text = "COMBAT FINISHED\nWinner: %s" % _winning_team_id
		else:
			_winner_label.text = "MISSION FAILED\nWinner: %s" % _winning_team_id
		return

	_winner_label.text = ""


func _set_objective_state(state_name: String) -> void:
	if _objective_state == state_name:
		_update_objective_state_label()
		return

	_objective_state = state_name
	_update_objective_state_label()


func _update_objective_state_label() -> void:
	var objective_state_label = get_node_or_null(objective_state_label_path) as Label
	if objective_state_label == null:
		return

	objective_state_label.text = _build_objective_marker_text()
	objective_state_label.modulate = _build_objective_state_color()


func _build_objective_marker_text() -> String:
	match _objective_state:
		OBJECTIVE_STATE_INACTIVE:
			return "OBJECTIVE\nINACTIVE"
		OBJECTIVE_STATE_CONTESTED:
			return "OBJECTIVE\nCONTESTED"
		OBJECTIVE_STATE_SECURED:
			return "OBJECTIVE\nSECURED"
		_:
			if mission_goal == "secure_target" and _objective_progress_ticks > 0:
				return "OBJECTIVE\nNEUTRAL %d/%d" % [_objective_progress_ticks, maxi(objective_hold_ticks_required, 1)]

			return "OBJECTIVE\nNEUTRAL"


func _build_objective_state_color() -> Color:
	match _objective_state:
		OBJECTIVE_STATE_INACTIVE:
			return Color(0.75, 0.75, 0.75, 1.0)
		OBJECTIVE_STATE_CONTESTED:
			return Color(1.0, 0.55, 0.35, 1.0)
		OBJECTIVE_STATE_SECURED:
			return Color(0.45, 1.0, 0.55, 1.0)
		_:
			return Color(1.0, 0.95, 0.5, 1.0)


func _build_objective_state_text() -> String:
	match _objective_state:
		OBJECTIVE_STATE_INACTIVE:
			return "INACTIVE"
		OBJECTIVE_STATE_CONTESTED:
			return "CONTESTED"
		OBJECTIVE_STATE_SECURED:
			return "SECURED"
		_:
			return "NEUTRAL"


func _count_fit_units(paths: Array[NodePath]) -> int:
	var fit_count: int = 0
	for unit in _get_units(paths):
		if unit != null and unit.has_method("get_vital_state") and String(unit.call("get_vital_state")) == "fit":
			fit_count += 1

	return fit_count


func _count_neutralized_units(paths: Array[NodePath]) -> int:
	var neutralized_count: int = 0
	for unit in _get_units(paths):
		if unit == null or not unit.has_method("get_vital_state"):
			continue

		if String(unit.call("get_vital_state")) != "fit":
			neutralized_count += 1

	return neutralized_count


func _build_attack_readiness_text() -> String:
	if _current_tick >= _next_attack_tick:
		return "ready"

	return "tick %d" % (_next_attack_tick - _current_tick)


func _finish_readability_setup() -> void:
	_ensure_readability_nodes()
	_update_event_label()
	_update_winner_label()
	_update_objective_state_label()
	_update_status_label("waiting")
