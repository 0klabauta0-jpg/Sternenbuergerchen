extends Node

const LOS_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/los_system.gd")

signal contact_established(attacker, target)
signal combat_resolved(winning_team_id, neutralized_enemy_count)

@export var friendly_team_id: String = "team_alpha"
@export var contact_range: float = 180.0
@export var damage_per_hit: int = 100
@export var simulation_root_path: NodePath
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
	_try_enqueue_attack(simulation_root)
	_update_combat_resolution()


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


func _try_enqueue_attack(simulation_root: Node) -> void:
	for friendly in _get_units(friendly_unit_paths):
		if not _is_attack_ready_unit(friendly):
			continue

		for enemy in _get_units(enemy_unit_paths):
			if not _is_attack_ready_unit(enemy):
				continue

			if String(friendly.call("get_team_id")) == String(enemy.call("get_team_id")):
				continue

			if not _los_system.has_line_of_sight_between_nodes(friendly, enemy, contact_range):
				continue

			var attacker_id: String = String(friendly.call("get_unit_id"))
			var target_id: String = String(enemy.call("get_unit_id"))
			if attacker_id.is_empty() or target_id.is_empty():
				continue

			_last_contact = {
				"attacker_id": attacker_id,
				"target_id": target_id,
			}
			contact_established.emit(friendly, enemy)
			simulation_root.call(
				"enqueue_effect",
				{
					"effect_type": "damage",
					"priority": 30,
					"unit_id": target_id,
					"attacker_team_id": String(friendly.call("get_team_id")),
					"allow_friendly_fire": false,
					"damage": damage_per_hit,
					"hit_chance": 1.0,
					"roll_override": 0.0,
				}
			)
			return


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
	combat_resolved.emit(_winning_team_id, enemy_units.size())


func _get_units(paths: Array[NodePath]) -> Array:
	var units: Array = []
	for path in paths:
		var unit = get_node_or_null(path)
		if unit != null and unit is Node2D:
			units.append(unit)

	return units


func _is_attack_ready_unit(unit) -> bool:
	if unit == null:
		return false

	if not unit.has_method("get_vital_state"):
		return false

	return String(unit.call("get_vital_state")) == "fit"
