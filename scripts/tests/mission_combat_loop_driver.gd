extends Node

const LOS_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/los_system.gd")
const CONTACT_LINE_NAME: String = "CombatContactLine"
const EVENT_LABEL_NAME: String = "CombatEventLabel"
const WINNER_LABEL_NAME: String = "CombatWinnerLabel"
const PHASE_APPROACH: int = 0
const PHASE_ASSAULT: int = 1
const PHASE_HOLD: int = 2

signal contact_established(attacker, target)
signal combat_resolved(winning_team_id, neutralized_enemy_count)

@export var friendly_team_id: String = "team_alpha"
@export var contact_range: float = 180.0
@export var damage_per_hit: int = 40
@export var base_hit_chance: float = 0.45
@export var base_damage_multiplier: float = 1.0
@export var ticks_between_attacks: int = 10
@export var simulation_root_path: NodePath
@export var status_label_path: NodePath
@export var friendly_unit_paths: Array[NodePath] = []
@export var enemy_unit_paths: Array[NodePath] = []

var _los_system = LOS_SYSTEM_SCRIPT.new()
var _queued_bleedout_by_unit_id: Dictionary = {}
var _combat_finished: bool = false
var _winning_team_id: String = ""
var _last_contact: Dictionary = {}
var _current_tick: int = 0
var _next_attack_tick: int = 1
var _last_event_text: String = "Combat waiting"
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
		_set_event_text("%s BLEEDOUT" % unit_id)
		return


func _try_enqueue_attacks(simulation_root: Node) -> void:
	var contact_pair: Dictionary = _find_first_contact_pair()
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
	_set_event_text("COMBAT FINISHED")
	_clear_contact_visuals()
	_update_status_label("resolved")
	_update_winner_label()
	combat_resolved.emit(_winning_team_id, enemy_units.size())


func _get_units(paths: Array[NodePath]) -> Array:
	var units: Array = []
	for path in paths:
		var unit = get_node_or_null(path)
		if unit != null and unit is Node2D:
			units.append(unit)

	return units


func _pick_target_for_attacker(attacker):
	for enemy in _get_units(enemy_unit_paths):
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

	if not _is_phase_attack_allowed(unit):
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


func _find_first_contact_pair() -> Dictionary:
	for friendly in _get_units(friendly_unit_paths):
		if not _can_unit_attack(friendly):
			continue

		var enemy = _pick_target_for_attacker(friendly)
		if enemy == null:
			continue

		return {
			"attacker": friendly,
			"target": enemy,
			"attacker_id": String(friendly.call("get_unit_id")),
			"target_id": String(enemy.call("get_unit_id")),
		}

	return {}


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
			_set_event_text("%s BLEEDOUT" % unit_id)
			if unit.has_method("show_event_text"):
				unit.call("show_event_text", "BLEEDOUT", Color(0.92, 0.6, 0.6, 1.0), 1.6)
	_update_status_label("active")


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
		_winner_label.text = "COMBAT FINISHED\nWinner: %s" % _winning_team_id
		return

	_winner_label.text = ""


func _count_fit_units(paths: Array[NodePath]) -> int:
	var fit_count: int = 0
	for unit in _get_units(paths):
		if unit != null and unit.has_method("get_vital_state") and String(unit.call("get_vital_state")) == "fit":
			fit_count += 1

	return fit_count


func _build_attack_readiness_text() -> String:
	if _current_tick >= _next_attack_tick:
		return "ready"

	return "tick %d" % (_next_attack_tick - _current_tick)


func _finish_readability_setup() -> void:
	_ensure_readability_nodes()
	_update_event_label()
	_update_winner_label()
	_update_status_label("waiting")
