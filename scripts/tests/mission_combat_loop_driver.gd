extends Node

const LOS_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/los_system.gd")

signal contact_established(attacker, target)
signal combat_resolved(winning_team_id, neutralized_enemy_count)

@export var friendly_team_id: String = "team_alpha"
@export var contact_range: float = 180.0
@export var damage_per_hit: int = 40
@export var base_hit_chance: float = 0.45
@export var base_damage_multiplier: float = 1.0
@export var simulation_root_path: NodePath
@export var status_label_path: NodePath
@export var friendly_unit_paths: Array[NodePath] = []
@export var enemy_unit_paths: Array[NodePath] = []

var _los_system = LOS_SYSTEM_SCRIPT.new()
var _queued_bleedout_by_unit_id: Dictionary = {}
var _combat_finished: bool = false
var _winning_team_id: String = ""
var _last_contact: Dictionary = {}


func _ready() -> void:
	var simulation_root = get_node_or_null(simulation_root_path)
	if simulation_root == null:
		push_warning("MissionCombatLoopDriver requires a direct SimulationRoot reference.")
		return

	if not simulation_root.tick_processed.is_connected(_on_tick_processed):
		simulation_root.tick_processed.connect(_on_tick_processed)

	_update_status_label("waiting")


func is_combat_finished() -> bool:
	return _combat_finished


func get_winning_team_id() -> String:
	return _winning_team_id


func get_last_contact() -> Dictionary:
	return _last_contact.duplicate(true)


func _on_tick_processed(_tick: int) -> void:
	if _combat_finished:
		return

	var simulation_root = get_node_or_null(simulation_root_path)
	if simulation_root == null:
		return

	_queue_bleedout_for_downed_enemy(simulation_root)
	_try_enqueue_attacks(simulation_root)
	_update_combat_resolution()
	if not _combat_finished:
		_update_status_label("active")


func _queue_bleedout_for_downed_enemy(simulation_root: Node) -> void:
	for enemy in _get_units(enemy_unit_paths):
		if enemy == null or not enemy.has_method("get_vital_state") or not enemy.has_method("get_unit_id"):
			continue

		var unit_id: String = String(enemy.call("get_unit_id"))
		if unit_id.is_empty() or _queued_bleedout_by_unit_id.get(unit_id, false):
			continue

		if String(enemy.call("get_vital_state")) != "down":
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
		return


func _try_enqueue_attacks(simulation_root: Node) -> void:
	var reserved_target_ids: Dictionary = {}

	for friendly in _get_units(friendly_unit_paths):
		if not _can_unit_attack(friendly):
			continue

		var enemy = _pick_target_for_attacker(friendly, reserved_target_ids)
		if enemy == null:
			continue

		var attacker_id: String = String(friendly.call("get_unit_id"))
		var target_id: String = String(enemy.call("get_unit_id"))
		if attacker_id.is_empty() or target_id.is_empty():
			continue

		_last_contact = {
			"attacker_id": attacker_id,
			"target_id": target_id,
		}
		reserved_target_ids[target_id] = true
		contact_established.emit(friendly, enemy)
		_update_status_label("contact")
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


func _update_combat_resolution() -> void:
	var enemy_units: Array = _get_units(enemy_unit_paths)
	if enemy_units.is_empty():
		return

	var enemy_fit_count: int = 0
	for enemy in enemy_units:
		if enemy == null or not enemy.has_method("get_vital_state"):
			continue

		if String(enemy.call("get_vital_state")) == "fit":
			enemy_fit_count += 1

	if enemy_fit_count > 0:
		return

	_combat_finished = true
	_winning_team_id = friendly_team_id
	_update_status_label("resolved")
	combat_resolved.emit(_winning_team_id, enemy_units.size())


func _get_units(paths: Array[NodePath]) -> Array:
	var units: Array = []
	for path in paths:
		var unit = get_node_or_null(path)
		if unit != null and unit is Node2D:
			units.append(unit)

	return units


func _pick_target_for_attacker(attacker, reserved_target_ids: Dictionary):
	for enemy in _get_units(enemy_unit_paths):
		var enemy_id: String = ""
		if enemy != null and enemy.has_method("get_unit_id"):
			enemy_id = String(enemy.call("get_unit_id"))

		if reserved_target_ids.get(enemy_id, false):
			continue

		if not _is_target_attackable(attacker, enemy):
			continue

		return enemy

	return null


func _can_unit_attack(unit) -> bool:
	if unit == null:
		return false

	if not unit.has_method("get_vital_state"):
		return false

	if String(unit.call("get_vital_state")) != "fit":
		return false

	if unit.has_method("get_fire_status") and String(unit.call("get_fire_status")) != "fire_at_will":
		return false

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

			return command_type == "move_to_position" and String(command.get("source_command_type")) == "flank"

	if unit.has_method("get_runtime_status"):
		var runtime_status = unit.call("get_runtime_status")
		if runtime_status != null and runtime_status.has_method("get"):
			var status_name: String = String(runtime_status.get("status"))
			if status_name == "engaging" or status_name == "holding":
				return true

			return status_name == "pending_move" and String(runtime_status.get("source_command_type")) == "flank"

	return false


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

	lines.append("Friendlies:")
	for friendly in _get_units(friendly_unit_paths):
		lines.append(_describe_friendly_unit(friendly))

	lines.append("Enemies:")
	for enemy in _get_units(enemy_unit_paths):
		lines.append(_describe_enemy_unit(enemy))

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
