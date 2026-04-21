extends Node

const LOS_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/los_system.gd")
const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")
const OVERWATCH_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tests/overwatch_controller.gd")
const CONTACT_LINE_NAME: String = "CombatContactLine"
const EVENT_LABEL_NAME: String = "CombatEventLabel"
const WINNER_LABEL_NAME: String = "CombatWinnerLabel"
const WIN_CONDITION_ELIMINATION: String = "elimination"
const WIN_CONDITION_OBJECTIVE_CAPTURE: String = "objective_capture"
const WIN_CONDITION_OBJECTIVE_DEFENSE: String = "objective_defense"
const DEFAULT_EVENT_COLOR: Color = Color(1.0, 0.95, 0.5, 1.0)
const HIT_EVENT_COLOR: Color = Color(1.0, 0.78, 0.35, 1.0)
const DOWN_EVENT_COLOR: Color = Color(1.0, 0.55, 0.55, 1.0)
const BLEEDOUT_EVENT_COLOR: Color = Color(0.92, 0.6, 0.6, 1.0)
const RESPAWN_EVENT_COLOR: Color = Color(0.72, 0.9, 1.0, 1.0)
const EVENT_DEFAULT_DURATION: float = 1.2
const LEADERSHIP_BONUS_FACTOR: float = 0.15
const LEADERSHIP_EVENT_COLOR: Color = Color(0.6, 0.85, 1.0, 1.0)
const MAX_DETECTION_DELAY_TICKS: int = 15
const DETECTION_EVENT_COLOR: Color = Color(0.85, 0.85, 0.55, 1.0)
const STEALTH_RANGE_REDUCTION_FACTOR: float = 0.5
const DISCIPLINE_BREAK_BASE_CHANCE: float = 0.08
const DISCIPLINE_BREAK_COOLDOWN_TICKS: int = 10
const DISCIPLINE_BREAK_EVENT_COLOR: Color = Color(1.0, 0.65, 0.3, 1.0)
const MISIDENTIFICATION_BASE_CHANCE: float = 0.03
const MISIDENTIFICATION_COOLDOWN_TICKS: int = 15
const MISIDENTIFICATION_EVENT_COLOR: Color = Color(1.0, 0.4, 0.4, 1.0)
const MEDIC_SUPPORT_RANGE: float = 84.0
const MEDIC_SUPPORT_HEAL_AMOUNT: int = 35
const MEDIC_SUPPORT_COOLDOWN_TICKS: int = 12
const MEDIC_SUPPORT_PRIORITY: int = 25
const MEDIC_EVENT_COLOR: Color = Color(0.55, 1.0, 0.72, 1.0)
const FRIENDLY_STANDARD_COVER_RADIUS: float = 48.0
const FRIENDLY_STANDARD_COVER_MIN_DISTANCE: float = 10.0
const FRIENDLY_STANDARD_COVER_COOLDOWN_MSEC: int = 1600
const FRIENDLY_LOW_COVER_THRESHOLD: int = 16
const ENEMY_PATROL_WAYPOINT_REACHED_DISTANCE: float = 18.0

signal contact_established(attacker, target)
signal combat_resolved(mission_result: Dictionary)

@export var friendly_team_id: String = "team_alpha"
@export var contact_range: float = 180.0
@export var damage_per_hit: int = 40
@export var base_hit_chance: float = 0.45
@export var base_damage_multiplier: float = 1.0
@export var ticks_between_attacks: int = 10
@export var enemy_advance_enabled: bool = true
@export var enemy_advance_speed_factor: float = 0.3
@export var enemy_engage_distance: float = 200.0
@export var enemy_reposition_enabled: bool = true
@export var enemy_reposition_cooldown_seconds: float = 4.0
@export var enemy_reposition_min_distance: float = 30.0
@export var enemy_reposition_max_distance: float = 60.0
@export var enemy_reposition_move_speed_factor: float = 0.45
@export var win_condition: String = WIN_CONDITION_ELIMINATION
@export var objective_defense_hold_seconds: float = 8.0
@export var simulation_root_path: NodePath
@export var status_label_path: NodePath
@export var friendly_unit_paths: Array[NodePath] = []
@export var enemy_unit_paths: Array[NodePath] = []
@export var respawn_manager_path: NodePath
@export var enemy_wave_controller_path: NodePath
@export var terrain_registry_path: NodePath
@export var tactical_controller_path: NodePath
@export var preview_mode: bool = false

var _los_system = LOS_SYSTEM_SCRIPT.new()
var _queued_bleedout_by_unit_id: Dictionary = {}
var _enemy_reposition_ready_at_msec: Dictionary = {}
var _combat_finished: bool = false
var _winning_team_id: String = ""
var _last_contact: Dictionary = {}
var _current_tick: int = 0
var _next_attack_tick: int = 1
var _last_event_text: String = "Combat waiting"
var _contact_line: Line2D = null
var _event_label: Label = null
var _winner_label: Label = null
var _mission_started_at_msec: int = 0
var _objective_owned_since_msec: int = -1
var _mission_result: Dictionary = {}
var _runs_local_authority: bool = true
var _fireteam_original_leads: Dictionary = {}
var _fireteam_acting_leads: Dictionary = {}
var _fireteam_members: Dictionary = {}
var _detection_progress: Dictionary = {}
var _discipline_break_cooldown: Dictionary = {}
var _misidentification_cooldown: Dictionary = {}
var _medic_support_cooldown: Dictionary = {}
var _friendly_cover_ready_at_msec: Dictionary = {}
var _overlays_visible: bool = true
var _enemy_patrol_paths_by_unit_id: Dictionary = {}
var _enemy_patrol_waypoint_index_by_unit_id: Dictionary = {}
var _enemy_patrol_contact_locked: Dictionary = {}
var _overwatch_controller = OVERWATCH_CONTROLLER_SCRIPT.new()


func _ready() -> void:
	var simulation_root = get_node_or_null(simulation_root_path)
	if simulation_root == null:
		push_warning("MissionCombatLoopDriver requires a direct SimulationRoot reference.")
		return

	_runs_local_authority = _should_run_local_combat(simulation_root)
	if _runs_local_authority:
		_connect_unit_signals()
		_connect_respawn_signals()
		_connect_wave_controller_signals()
		_init_fireteam_leadership()
		_initialize_enemy_patrol_paths()
	if preview_mode:
		_apply_overlay_visibility()
	else:
		call_deferred("_finish_readability_setup")
	_mission_started_at_msec = Time.get_ticks_msec()

	if _runs_local_authority and not simulation_root.tick_processed.is_connected(_on_tick_processed):
		simulation_root.tick_processed.connect(_on_tick_processed)

	_update_status_label("waiting" if _runs_local_authority else "observing")


func is_combat_finished() -> bool:
	return _combat_finished


func get_winning_team_id() -> String:
	return _winning_team_id


func get_last_contact() -> Dictionary:
	return _last_contact.duplicate(true)


func get_mission_result() -> Dictionary:
	return _mission_result.duplicate(true)


@rpc("authority", "reliable")
func _receive_mission_result(mission_result: Dictionary) -> void:
	if _runs_local_authority:
		return

	_combat_finished = true
	_mission_result = mission_result.duplicate(true)
	_winning_team_id = String(_mission_result.get("winning_team_id", ""))
	_set_event_text("MISSION %s" % String(_mission_result.get("result", "ended")).to_upper())
	_clear_contact_visuals()
	_update_status_label("resolved")
	_update_winner_label()
	combat_resolved.emit(get_mission_result())


@rpc("authority", "reliable")
func _receive_remote_event(
	event_text: String,
	unit_id: String = "",
	event_color: Color = DEFAULT_EVENT_COLOR,
	duration_seconds: float = EVENT_DEFAULT_DURATION,
	unit_event_text: String = ""
) -> void:
	if _runs_local_authority:
		return

	_set_event_text(event_text)
	if unit_id.is_empty():
		return

	var unit = _resolve_unit_by_id(unit_id)
	if unit == null or not unit.has_method("show_event_text"):
		return

	var resolved_unit_event_text: String = unit_event_text if not unit_event_text.is_empty() else event_text
	unit.call("show_event_text", resolved_unit_event_text, event_color, duration_seconds)


func _on_tick_processed(tick: int) -> void:
	_current_tick = tick
	if _combat_finished:
		_update_status_label("resolved")
		return

	var simulation_root = get_node_or_null(simulation_root_path)
	if simulation_root == null:
		return

	_queue_bleedout_for_downed_enemy(simulation_root)
	_queue_bleedout_for_downed_friendly(simulation_root)
	_update_fireteam_leadership()
	_advance_detection_timers()
	_advance_discipline_cooldowns()
	_advance_misidentification_cooldowns()
	_advance_medic_support_cooldowns()
	_try_enqueue_medic_support(simulation_root)
	_advance_enemy_units(simulation_root)
	_apply_friendly_standard_behavior(simulation_root)
	var overwatch_shots: Array = _try_enqueue_overwatch(simulation_root)
	if overwatch_shots.is_empty():
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


func _queue_bleedout_for_downed_friendly(simulation_root: Node) -> void:
	for friendly in _get_units(friendly_unit_paths):
		if friendly == null or not friendly.has_method("get_vital_state") or not friendly.has_method("get_unit_id"):
			continue

		var unit_id: String = String(friendly.call("get_unit_id"))
		if unit_id.is_empty() or _queued_bleedout_by_unit_id.get(unit_id, false):
			continue

		if String(friendly.call("get_vital_state")) != "down":
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


func _request_respawn_for_unit(unit, unit_id: String) -> void:
	var respawn_manager = get_node_or_null(respawn_manager_path)
	if respawn_manager == null or not respawn_manager.has_method("request_respawn"):
		return

	var unit_team_id: String = ""
	if unit.has_method("get_team_id"):
		unit_team_id = String(unit.call("get_team_id"))

	if unit_team_id.is_empty():
		return

	respawn_manager.call("request_respawn", unit_id, unit_team_id)


func _try_enqueue_attacks(simulation_root: Node) -> void:
	var contact_pair: Dictionary = _find_first_contact_pair()
	if contact_pair.is_empty():
		_clear_contact_visuals()
		return

	var attacker = contact_pair["attacker"]
	var target = contact_pair["target"]
	var attacker_id: String = String(contact_pair["attacker_id"])
	var target_id: String = String(contact_pair["target_id"])
	if attacker_id.is_empty() or target_id.is_empty():
		_clear_contact_visuals()
		return

	_last_contact = {
		"attacker_id": attacker_id,
		"target_id": target_id,
	}
	_set_contact_visuals(attacker, target)
	_update_status_label("contact")
	if _current_tick < _next_attack_tick:
		return

	var misid_result: Dictionary = _check_misidentification(attacker, attacker_id)
	var actual_target = target
	var actual_target_id: String = target_id
	var is_friendly_fire: bool = false
	if not misid_result.is_empty():
		actual_target = misid_result["target"]
		actual_target_id = misid_result["target_id"]
		is_friendly_fire = true

	contact_established.emit(attacker, actual_target)
	if is_friendly_fire:
		_set_event_text("%s verwechselt Ziel! -> %s" % [attacker_id, actual_target_id])
	else:
		_set_event_text("%s ENGAGE %s" % [attacker_id, actual_target_id])
	var active_weapon_id: String = _get_unit_active_weapon_id(attacker)
	var weapon_damage: int = WEAPON_DATA_SCRIPT.get_damage_per_hit(active_weapon_id)
	var weapon_hit_chance: float = WEAPON_DATA_SCRIPT.get_base_hit_chance(active_weapon_id)
	var weapon_ticks: int = WEAPON_DATA_SCRIPT.get_ticks_between_attacks(active_weapon_id)
	simulation_root.call(
		"enqueue_effect",
		{
			"effect_type": "damage",
			"priority": 30,
			"unit_id": actual_target_id,
			"attacker_unit_id": attacker_id,
			"attacker_team_id": String(attacker.call("get_team_id")),
			"allow_friendly_fire": is_friendly_fire,
			"damage": weapon_damage,
			"hit_chance": weapon_hit_chance,
			"damage_multiplier": base_damage_multiplier,
			"roll_override": 0.4,
		}
	)
	if is_friendly_fire and attacker.has_method("show_event_text"):
		attacker.call("show_event_text", "FRIENDLY FIRE!", MISIDENTIFICATION_EVENT_COLOR, 1.6)
		_broadcast_remote_event("%s verwechselt Ziel! -> %s" % [attacker_id, actual_target_id], attacker_id, MISIDENTIFICATION_EVENT_COLOR, 1.6, "FRIENDLY FIRE!")
	_next_attack_tick = _current_tick + max(weapon_ticks, 1)


func _update_combat_resolution() -> void:
	if _combat_finished:
		return

	if _is_victory_condition_met():
		_resolve_combat("victory", friendly_team_id)
		return

	if _count_fit_units(friendly_unit_paths) > 0:
		return

	_resolve_combat("defeat", _get_enemy_team_id())


func _get_units(paths: Array[NodePath]) -> Array:
	var units: Array = []
	var unit_registry = get_node_or_null("../UnitRegistry")
	for path in paths:
		var unit = get_node_or_null(path)
		if unit != null and unit is Node2D:
			if unit_registry != null and unit.has_method("get_unit_id") and unit_registry.has_method("has_unit"):
				var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
				if unit_id.is_empty() or not bool(unit_registry.call("has_unit", unit_id)):
					continue
			units.append(unit)

	return units


func _init_fireteam_leadership() -> void:
	_fireteam_original_leads.clear()
	_fireteam_acting_leads.clear()
	_fireteam_members.clear()
	for unit in _get_units(friendly_unit_paths):
		if unit == null or not unit.has_method("get_fireteam_id") or not unit.has_method("get_unit_id"):
			continue

		var ft_id: String = String(unit.call("get_fireteam_id"))
		if ft_id.is_empty():
			continue

		var uid: String = String(unit.call("get_unit_id"))
		if not _fireteam_members.has(ft_id):
			_fireteam_members[ft_id] = []

		_fireteam_members[ft_id].append(uid)
		if unit.has_method("get") and unit.get("is_fireteam_lead"):
			_fireteam_original_leads[ft_id] = uid
			_fireteam_acting_leads[ft_id] = uid

	_apply_all_leadership_bonuses()


func _update_fireteam_leadership() -> void:
	var changed: bool = false
	for ft_id in _fireteam_original_leads.keys():
		var original_lead_id: String = String(_fireteam_original_leads[ft_id])
		var current_acting_id: String = String(_fireteam_acting_leads.get(ft_id, ""))
		var original_lead = _resolve_unit_by_id(original_lead_id)
		var original_is_fit: bool = original_lead != null and original_lead.has_method("get_vital_state") and String(original_lead.call("get_vital_state")) == "fit"

		if original_is_fit:
			if current_acting_id != original_lead_id:
				_fireteam_acting_leads[ft_id] = original_lead_id
				changed = true
				_show_leadership_event(original_lead_id, "LEAD BACK")
		else:
			if current_acting_id == original_lead_id or not _is_acting_lead_fit(current_acting_id):
				var successor_id: String = _find_best_successor(ft_id, original_lead_id)
				if successor_id != current_acting_id:
					_fireteam_acting_leads[ft_id] = successor_id
					changed = true
					if not successor_id.is_empty():
						_show_leadership_event(successor_id, "ACTING LEAD")

	if changed:
		_apply_all_leadership_bonuses()


func _is_acting_lead_fit(uid: String) -> bool:
	if uid.is_empty():
		return false

	var unit = _resolve_unit_by_id(uid)
	if unit == null or not unit.has_method("get_vital_state"):
		return false

	return String(unit.call("get_vital_state")) == "fit"


func _find_best_successor(ft_id: String, exclude_id: String) -> String:
	var best_id: String = ""
	var best_leadership: float = -1.0
	var best_toughness: float = -1.0
	var members: Array = _fireteam_members.get(ft_id, [])
	for uid in members:
		if String(uid) == exclude_id:
			continue

		var unit = _resolve_unit_by_id(String(uid))
		if unit == null or not unit.has_method("get_vital_state"):
			continue

		if String(unit.call("get_vital_state")) != "fit":
			continue

		var leadership: float = 0.0
		if unit.has_method("get_leadership_skill"):
			leadership = float(unit.call("get_leadership_skill"))
		var toughness: float = 0.0
		if unit.has_method("get_toughness_skill"):
			toughness = float(unit.call("get_toughness_skill"))

		if leadership > best_leadership:
			best_leadership = leadership
			best_toughness = toughness
			best_id = String(uid)
			continue
		if is_equal_approx(leadership, best_leadership) and toughness > best_toughness:
			best_toughness = toughness
			best_id = String(uid)

	return best_id


func _try_enqueue_medic_support(simulation_root: Node) -> void:
	var reserved_target_ids: Dictionary = {}
	_try_enqueue_medic_support_for_units(simulation_root, _get_units(friendly_unit_paths), _get_units(friendly_unit_paths), reserved_target_ids)
	_try_enqueue_medic_support_for_units(simulation_root, _get_active_enemy_units(), _get_active_enemy_units(), reserved_target_ids)


func _try_enqueue_medic_support_for_units(simulation_root: Node, medics: Array, allies: Array, reserved_target_ids: Dictionary) -> void:
	for medic in medics:
		if not _can_medic_support(medic):
			continue

		var medic_id: String = String(medic.call("get_unit_id"))
		var target = _pick_medic_target(medic, allies, reserved_target_ids)
		if target == null or not target.has_method("get_unit_id"):
			continue

		var target_id: String = String(target.call("get_unit_id"))
		if target_id.is_empty():
			continue

		reserved_target_ids[target_id] = true
		simulation_root.call(
			"enqueue_effect",
			{
				"effect_type": "heal",
				"priority": MEDIC_SUPPORT_PRIORITY,
				"unit_id": target_id,
				"healer_unit_id": medic_id,
				"healer_team_id": String(medic.call("get_team_id")),
				"amount": MEDIC_SUPPORT_HEAL_AMOUNT,
			}
		)
		_medic_support_cooldown[medic_id] = MEDIC_SUPPORT_COOLDOWN_TICKS
		_set_event_text("%s PATCH %s" % [medic_id, target_id])
		if medic.has_method("show_event_text"):
			medic.call("show_event_text", "PATCH", MEDIC_EVENT_COLOR, 1.2)


func _can_medic_support(unit) -> bool:
	if unit == null or not unit.has_method("get_unit_id") or not unit.has_method("get_vital_state"):
		return false

	if String(unit.call("get_vital_state")) != "fit":
		return false

	if not _is_medic_unit(unit):
		return false

	return int(_medic_support_cooldown.get(String(unit.call("get_unit_id")), 0)) <= 0


func _is_medic_unit(unit) -> bool:
	if unit == null:
		return false

	var role_id: String = String(unit.call("get_role_id")).to_lower() if unit.has_method("get_role_id") else ""
	if role_id == "combat_medic":
		return true

	var role_name: String = String(unit.call("get_role_name")).to_lower() if unit.has_method("get_role_name") else ""
	return role_name.contains("medic") or role_name.contains("sanitaeter")


func _pick_medic_target(medic, allies: Array, reserved_target_ids: Dictionary):
	if medic == null or not (medic is Node2D):
		return null

	var downed_target = _pick_medic_target_by_state(medic, allies, reserved_target_ids, "down")
	if downed_target != null:
		return downed_target

	return _pick_medic_wounded_target(medic, allies, reserved_target_ids)


func _pick_medic_target_by_state(medic, allies: Array, reserved_target_ids: Dictionary, expected_state: String):
	var best_target = null
	var best_distance: float = INF
	for ally in allies:
		if not _is_valid_medic_target(medic, ally, reserved_target_ids):
			continue
		if String(ally.call("get_vital_state")) != expected_state:
			continue

		var distance: float = (medic as Node2D).global_position.distance_to((ally as Node2D).global_position)
		if distance < best_distance:
			best_distance = distance
			best_target = ally

	return best_target


func _pick_medic_wounded_target(medic, allies: Array, reserved_target_ids: Dictionary):
	var best_target = null
	var best_health_ratio: float = 1.1
	for ally in allies:
		if not _is_valid_medic_target(medic, ally, reserved_target_ids):
			continue
		if String(ally.call("get_vital_state")) != "fit":
			continue
		if not ally.has_method("get_health") or not ally.has_method("get_max_health_points"):
			continue

		var max_health: int = int(ally.call("get_max_health_points"))
		if max_health <= 0:
			continue

		var health_ratio: float = float(ally.call("get_health")) / float(max_health)
		if health_ratio >= 0.65:
			continue

		if health_ratio < best_health_ratio:
			best_health_ratio = health_ratio
			best_target = ally

	return best_target


func _is_valid_medic_target(medic, ally, reserved_target_ids: Dictionary) -> bool:
	if ally == null or ally == medic or not (ally is Node2D):
		return false
	if not ally.has_method("get_unit_id") or not ally.has_method("get_vital_state"):
		return false

	var target_id: String = String(ally.call("get_unit_id"))
	if target_id.is_empty() or reserved_target_ids.has(target_id):
		return false

	return (medic as Node2D).global_position.distance_to((ally as Node2D).global_position) <= MEDIC_SUPPORT_RANGE


func _apply_all_leadership_bonuses() -> void:
	for unit in _get_units(friendly_unit_paths):
		if unit == null or not unit.has_method("clear_leadership_bonus"):
			continue

		unit.call("clear_leadership_bonus")

	for ft_id in _fireteam_acting_leads.keys():
		var acting_lead_id: String = String(_fireteam_acting_leads[ft_id])
		if acting_lead_id.is_empty():
			continue

		var lead_unit = _resolve_unit_by_id(acting_lead_id)
		if lead_unit == null or not lead_unit.has_method("get_vital_state"):
			continue

		if String(lead_unit.call("get_vital_state")) != "fit":
			continue

		var leadership_value: float = 0.0
		if lead_unit.has_method("get_leadership_skill"):
			leadership_value = float(lead_unit.call("get_leadership_skill"))

		var bonus: float = leadership_value * LEADERSHIP_BONUS_FACTOR
		if bonus <= 0.0:
			continue

		var members: Array = _fireteam_members.get(ft_id, [])
		for uid in members:
			if String(uid) == acting_lead_id:
				continue

			var member = _resolve_unit_by_id(String(uid))
			if member == null or not member.has_method("apply_leadership_bonus"):
				continue

			member.call("apply_leadership_bonus", bonus)


func _show_leadership_event(uid: String, text: String) -> void:
	var unit = _resolve_unit_by_id(uid)
	if unit != null and unit.has_method("show_event_text"):
		unit.call("show_event_text", text, LEADERSHIP_EVENT_COLOR, EVENT_DEFAULT_DURATION)

	_set_event_text("%s %s" % [uid, text])


func _pick_target_for_attacker(attacker, target_paths: Array[NodePath]):
	for target in _get_units(target_paths):
		if not _is_target_attackable(attacker, target):
			continue

		return target

	return null


func _can_enemy_attack(unit) -> bool:
	if unit == null:
		return false

	if not unit.has_method("get_vital_state"):
		return false

	if String(unit.call("get_vital_state")) != "fit":
		return false

	return true


func _can_unit_attack(unit) -> bool:
	if unit == null:
		return false

	if not unit.has_method("get_vital_state"):
		return false

	if String(unit.call("get_vital_state")) != "fit":
		return false

	if unit.has_method("get_fire_status") and String(unit.call("get_fire_status")) != "fire_at_will":
		if not _check_discipline_break(unit):
			return false

	return _is_engage_ready(unit)


func _check_discipline_break(unit) -> bool:
	if unit == null:
		return false
	var unit_id: String = ""
	if unit.has_method("get_unit_id"):
		unit_id = String(unit.call("get_unit_id"))
	if unit_id.is_empty():
		return false

	var cooldown_remaining: int = _discipline_break_cooldown.get(unit_id, 0) as int
	if cooldown_remaining > 0:
		return false

	var unit_discipline: float = 0.5
	if unit.has_method("get_discipline"):
		unit_discipline = clampf(float(unit.call("get_discipline")), 0.0, 1.0)

	var break_chance: float = DISCIPLINE_BREAK_BASE_CHANCE * (1.0 - unit_discipline)
	if break_chance <= 0.0:
		return false

	if randf() >= break_chance:
		return false

	_discipline_break_cooldown[unit_id] = DISCIPLINE_BREAK_COOLDOWN_TICKS
	var event_msg: String = "%s bricht Hold-Fire!" % unit_id
	_set_event_text(event_msg)
	if unit.has_method("show_event_text"):
		unit.call("show_event_text", "HOLD-FIRE BREAK!", DISCIPLINE_BREAK_EVENT_COLOR, 1.4)
	_broadcast_remote_event(event_msg, unit_id, DISCIPLINE_BREAK_EVENT_COLOR, 1.4, "HOLD-FIRE BREAK!")
	return true


func _get_detection_delay_ticks(unit) -> int:
	var unit_awareness: float = 0.5
	if unit != null and unit.has_method("get_awareness"):
		unit_awareness = clampf(float(unit.call("get_awareness")), 0.0, 1.0)

	return int(round((1.0 - unit_awareness) * float(MAX_DETECTION_DELAY_TICKS)))


func _make_detection_key(attacker_id: String, target_id: String) -> String:
	return "%s:%s" % [attacker_id, target_id]


func _is_detection_complete(attacker_id: String, target_id: String) -> bool:
	var key: String = _make_detection_key(attacker_id, target_id)
	return _detection_progress.has(key) and int(_detection_progress[key]) <= 0


func _start_or_continue_detection(attacker, attacker_id: String, target_id: String) -> void:
	var key: String = _make_detection_key(attacker_id, target_id)
	if _detection_progress.has(key):
		return

	var delay: int = _get_detection_delay_ticks(attacker)
	_detection_progress[key] = delay
	if delay > 0 and attacker != null and attacker.has_method("show_event_text"):
		attacker.call("show_event_text", "DETECTING...", DETECTION_EVENT_COLOR, 0.8)


func _advance_detection_timers() -> void:
	var keys_to_remove: Array = []
	for key in _detection_progress.keys():
		var remaining: int = int(_detection_progress[key])
		if remaining > 0:
			_detection_progress[key] = remaining - 1
		else:
			# Already detected, keep entry
			pass

	# Prune pairs that lost LOS
	for key in _detection_progress.keys():
		var parts: PackedStringArray = String(key).split(":")
		if parts.size() != 2:
			keys_to_remove.append(key)
			continue

		var attacker = _resolve_unit_by_id(parts[0])
		var target = _resolve_unit_by_id(parts[1])
		if attacker == null or target == null:
			keys_to_remove.append(key)
			continue

		if not _has_valid_los(attacker, target):
			keys_to_remove.append(key)

	for key in keys_to_remove:
		_detection_progress.erase(key)


func _advance_discipline_cooldowns() -> void:
	var keys_to_remove: Array = []
	for key in _discipline_break_cooldown.keys():
		var remaining: int = int(_discipline_break_cooldown[key])
		if remaining > 1:
			_discipline_break_cooldown[key] = remaining - 1
		else:
			keys_to_remove.append(key)
	for key in keys_to_remove:
		_discipline_break_cooldown.erase(key)


func get_discipline_break_cooldown() -> Dictionary:
	return _discipline_break_cooldown


func _advance_misidentification_cooldowns() -> void:
	var keys_to_remove: Array = []
	for key in _misidentification_cooldown.keys():
		var remaining: int = int(_misidentification_cooldown[key])
		if remaining > 1:
			_misidentification_cooldown[key] = remaining - 1
		else:
			keys_to_remove.append(key)
	for key in keys_to_remove:
		_misidentification_cooldown.erase(key)


func get_misidentification_cooldown() -> Dictionary:
	return _misidentification_cooldown


func get_medic_support_cooldown() -> Dictionary:
	return _medic_support_cooldown.duplicate(true)


func _advance_medic_support_cooldowns() -> void:
	var keys_to_remove: Array = []
	for key in _medic_support_cooldown.keys():
		var remaining: int = int(_medic_support_cooldown[key])
		if remaining > 1:
			_medic_support_cooldown[key] = remaining - 1
		else:
			keys_to_remove.append(key)
	for key in keys_to_remove:
		_medic_support_cooldown.erase(key)


func _check_misidentification(attacker, attacker_id: String) -> Dictionary:
	if attacker == null or attacker_id.is_empty():
		return {}

	var cooldown_remaining: int = _misidentification_cooldown.get(attacker_id, 0) as int
	if cooldown_remaining > 0:
		return {}

	# Only friendlies can misidentify (not enemies)
	var attacker_team: String = ""
	if attacker.has_method("get_team_id"):
		attacker_team = String(attacker.call("get_team_id"))
	if attacker_team != friendly_team_id:
		return {}

	var unit_recognition: float = 0.5
	if attacker.has_method("get_recognition"):
		unit_recognition = clampf(float(attacker.call("get_recognition")), 0.0, 1.0)

	var misid_chance: float = MISIDENTIFICATION_BASE_CHANCE * (1.0 - unit_recognition)
	if misid_chance <= 0.0:
		return {}

	if randf() >= misid_chance:
		return {}

	# Find nearest friendly unit (not self) as misidentified target
	var nearest_friendly = null
	var nearest_dist: float = INF
	for friendly in _get_units(friendly_unit_paths):
		if friendly == attacker:
			continue
		if not friendly.has_method("get_vital_state"):
			continue
		if String(friendly.call("get_vital_state")) != "fit":
			continue
		var dist: float = attacker.global_position.distance_to(friendly.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_friendly = friendly

	if nearest_friendly == null:
		return {}

	_misidentification_cooldown[attacker_id] = MISIDENTIFICATION_COOLDOWN_TICKS
	var friendly_id: String = String(nearest_friendly.call("get_unit_id"))
	return {
		"target": nearest_friendly,
		"target_id": friendly_id,
	}


func _has_valid_los(attacker, target) -> bool:
	if attacker == null or target == null:
		return false

	if not attacker.has_method("get_vital_state") or String(attacker.call("get_vital_state")) != "fit":
		return false

	if not target.has_method("get_vital_state") or String(target.call("get_vital_state")) != "fit":
		return false

	return _los_system.has_line_of_sight_between_nodes(attacker, target, _get_effective_range(target), _get_terrain_registry())


func get_detection_progress() -> Dictionary:
	return _detection_progress.duplicate(true)


func _get_effective_range(target) -> float:
	var target_stealth: float = 0.0
	if target != null and target.has_method("get_stealth"):
		target_stealth = clampf(float(target.call("get_stealth")), 0.0, 1.0)

	return contact_range * (1.0 - target_stealth * STEALTH_RANGE_REDUCTION_FACTOR)


func _is_target_attackable(attacker, target) -> bool:
	if target == null or not _can_target_receive_attack(target):
		return false

	if attacker == null:
		return false

	if String(attacker.call("get_team_id")) == String(target.call("get_team_id")):
		return false

	return _los_system.has_line_of_sight_between_nodes(attacker, target, _get_effective_range(target), _get_terrain_registry())


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
	if preview_mode:
		status_label.set("visible", false)
		return

	status_label.set("visible", _overlays_visible)
	status_label.set("text", _build_status_text(state_name))


func _build_status_text(state_name: String) -> String:
	var lines: PackedStringArray = []
	lines.append("Combat: %s" % state_name)
	lines.append("Win condition: %s" % win_condition)

	if _combat_finished and not _winning_team_id.is_empty():
		lines.append("Winner: %s" % _winning_team_id)

	lines.append("Enemies fit: %d" % _count_fit_enemy_units())
	lines.append("Friendlies fit: %d" % _count_fit_units(friendly_unit_paths))
	lines.append("Duration: %.1fs" % _get_duration_seconds())
	lines.append(_build_objective_status_text())
	lines.append(_build_wave_status_text())

	if win_condition == WIN_CONDITION_OBJECTIVE_DEFENSE and _objective_owned_since_msec >= 0 and not _combat_finished:
		lines.append("Hold timer: %.1fs / %.1fs" % [_get_objective_defense_elapsed_seconds(), objective_defense_hold_seconds])

	lines.append("Next shot: %s" % _build_attack_readiness_text())
	lines.append("Last event: %s" % _last_event_text)

	if not _last_contact.is_empty():
		lines.append("Last contact: %s -> %s" % [String(_last_contact.get("attacker_id", "")), String(_last_contact.get("target_id", ""))])

	return "\n".join(lines)


func _build_team_states(paths: Array[NodePath]) -> Array:
	var team_states: Array = []
	for unit in _get_units(paths):
		if unit == null or not unit.has_method("get_unit_id"):
			continue

		var health_points: int = 0
		if unit.has_method("get_health"):
			health_points = int(unit.call("get_health"))

		var vital_state: String = ""
		if unit.has_method("get_vital_state"):
			vital_state = String(unit.call("get_vital_state"))

		var display_name: String = String(unit.call("get_display_name")) if unit.has_method("get_display_name") else String(unit.call("get_unit_id"))
		team_states.append(
			{
				"unit_id": String(unit.call("get_unit_id")),
				"display_name": display_name,
				"vital_state": vital_state,
				"health_points": health_points,
			}
		)

	return team_states


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


func _get_unit_active_weapon_id(unit) -> String:
	if unit != null and unit.has_method("get_active_weapon_id"):
		var weapon_id: String = String(unit.call("get_active_weapon_id")).strip_edges()
		if WEAPON_DATA_SCRIPT.is_valid_weapon_id(weapon_id):
			return weapon_id
	return WEAPON_DATA_SCRIPT.DEFAULT_WEAPON_ID


func _find_first_contact_pair() -> Dictionary:
	for friendly in _get_units(friendly_unit_paths):
		if not _can_unit_attack(friendly):
			continue

		var enemy = _pick_target_from_units(friendly, _get_active_enemy_units())
		if enemy == null:
			continue

		var f_id: String = String(friendly.call("get_unit_id"))
		var e_id: String = String(enemy.call("get_unit_id"))
		_start_or_continue_detection(friendly, f_id, e_id)
		if not _is_detection_complete(f_id, e_id):
			continue

		return {
			"attacker": friendly,
			"target": enemy,
			"attacker_id": f_id,
			"target_id": e_id,
		}

	for enemy in _get_active_enemy_units():
		if not _can_enemy_attack(enemy):
			continue

		var friendly = _pick_target_from_units(enemy, _get_units(friendly_unit_paths))
		if friendly == null:
			continue

		var en_id: String = String(enemy.call("get_unit_id"))
		var fr_id: String = String(friendly.call("get_unit_id"))
		_start_or_continue_detection(enemy, en_id, fr_id)
		if not _is_detection_complete(en_id, fr_id):
			continue

		return {
			"attacker": enemy,
			"target": friendly,
			"attacker_id": en_id,
			"target_id": fr_id,
		}

	return {}


func _ensure_readability_nodes() -> void:
	if preview_mode:
		return
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

		if unit.has_signal("healed_applied"):
			var healed_callable := Callable(self, "_on_unit_healed_applied").bind(unit)
			if not unit.is_connected("healed_applied", healed_callable):
				unit.connect("healed_applied", healed_callable)

		if unit.has_signal("vital_status_changed"):
			var vital_callable := Callable(self, "_on_unit_vital_status_changed").bind(unit)
			if not unit.is_connected("vital_status_changed", vital_callable):
				unit.connect("vital_status_changed", vital_callable)


func _connect_respawn_signals() -> void:
	var respawn_manager = get_node_or_null(respawn_manager_path)
	if respawn_manager == null:
		return

	if respawn_manager.has_signal("unit_respawn_completed"):
		if not respawn_manager.is_connected("unit_respawn_completed", Callable(self, "_on_unit_respawn_completed")):
			respawn_manager.connect("unit_respawn_completed", Callable(self, "_on_unit_respawn_completed"))


func _connect_wave_controller_signals() -> void:
	var enemy_wave_controller = _get_enemy_wave_controller()
	if enemy_wave_controller == null:
		return

	if enemy_wave_controller.has_signal("wave_started"):
		if not enemy_wave_controller.is_connected("wave_started", Callable(self, "_on_enemy_wave_started")):
			enemy_wave_controller.connect("wave_started", Callable(self, "_on_enemy_wave_started"))


func _on_unit_respawn_completed(unit_id: String) -> void:
	_queued_bleedout_by_unit_id.erase(unit_id)
	_set_event_text("%s RESPAWN READY" % unit_id)
	_broadcast_remote_event("%s RESPAWN READY" % unit_id, unit_id, RESPAWN_EVENT_COLOR, 1.6, "RESPAWN READY")


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
		unit.call("show_event_text", "HIT -%d" % amount, HIT_EVENT_COLOR)
	_broadcast_remote_event("%s HIT -%d" % [unit_id, amount], unit_id, HIT_EVENT_COLOR, EVENT_DEFAULT_DURATION, "HIT -%d" % amount)
	_try_reposition_enemy_on_damage(unit, _hit_context)
	_update_status_label("contact")


func _on_unit_healed_applied(amount: int, _health_points: int, heal_context: Dictionary, unit) -> void:
	if unit == null or not unit.has_method("get_unit_id"):
		return

	var unit_id: String = String(unit.call("get_unit_id"))
	var healer_unit_id: String = String(heal_context.get("healer_unit_id", ""))
	var event_text: String = "%s PATCH %s +%d" % [healer_unit_id if not healer_unit_id.is_empty() else "MEDIC", unit_id, amount]
	_set_event_text(event_text)
	if unit.has_method("show_event_text"):
		unit.call("show_event_text", "PATCH +%d" % amount, MEDIC_EVENT_COLOR, 1.4)
	if not healer_unit_id.is_empty():
		var healer = _resolve_unit_by_id(healer_unit_id)
		if healer != null and healer.has_method("show_event_text"):
			healer.call("show_event_text", "PATCH", MEDIC_EVENT_COLOR, 1.2)
	_broadcast_remote_event(event_text, unit_id, MEDIC_EVENT_COLOR, 1.4, "PATCH +%d" % amount)
	_update_status_label("active")


func _on_unit_vital_status_changed(vital_status, unit) -> void:
	if vital_status == null or not vital_status.has_method("get"):
		return

	var unit_id: String = String(unit.call("get_unit_id"))
	var vital_state: String = String(vital_status.get("state"))
	if vital_state == "fit":
		_queued_bleedout_by_unit_id.erase(unit_id)
	match vital_state:
		"down":
			_set_event_text("%s DOWN" % unit_id)
			if unit.has_method("show_event_text"):
				unit.call("show_event_text", "DOWN", DOWN_EVENT_COLOR, 1.5)
			_broadcast_remote_event("%s DOWN" % unit_id, unit_id, DOWN_EVENT_COLOR, 1.5, "DOWN")
		"bleedout":
			_set_event_text("%s BLEEDOUT" % unit_id)
			if unit.has_method("show_event_text"):
				unit.call("show_event_text", "BLEEDOUT", BLEEDOUT_EVENT_COLOR, 1.6)
			_broadcast_remote_event("%s BLEEDOUT" % unit_id, unit_id, BLEEDOUT_EVENT_COLOR, 1.6, "BLEEDOUT")
			_request_respawn_for_unit(unit, unit_id)
		"respawning":
			_set_event_text("%s RESPAWNING" % unit_id)
			if unit.has_method("show_event_text"):
				unit.call("show_event_text", "RESPAWNING", RESPAWN_EVENT_COLOR, 1.6)
			_broadcast_remote_event("%s RESPAWNING" % unit_id, unit_id, RESPAWN_EVENT_COLOR, 1.6, "RESPAWNING")
	_update_status_label("active")


func _set_event_text(event_text: String) -> void:
	_last_event_text = event_text
	_update_event_label()


func _broadcast_remote_event(
	event_text: String,
	unit_id: String = "",
	event_color: Color = DEFAULT_EVENT_COLOR,
	duration_seconds: float = EVENT_DEFAULT_DURATION,
	unit_event_text: String = ""
) -> void:
	if not _can_broadcast_to_clients():
		return

	_receive_remote_event.rpc(event_text, unit_id, event_color, duration_seconds, unit_event_text)


func _update_event_label() -> void:
	if _event_label == null:
		return

	_event_label.text = "Event: %s" % _last_event_text


func _should_run_local_combat(simulation_root: Node) -> bool:
	if simulation_root == null:
		return true

	if not _variant_to_bool(simulation_root.get("is_server_authoritative")):
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


func _can_broadcast_to_clients() -> bool:
	if not _runs_local_authority:
		return false

	var peer: MultiplayerPeer = multiplayer.multiplayer_peer
	if peer == null or peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		return false

	return multiplayer.is_server()


func _update_winner_label() -> void:
	if _winner_label == null:
		return

	if _combat_finished and not _winning_team_id.is_empty():
		var result_text: String = String(_mission_result.get("result", "")).to_upper()
		var condition_text: String = String(_mission_result.get("win_condition_type", ""))
		_winner_label.text = "%s\nWinner: %s\nCondition: %s" % [result_text, _winning_team_id, condition_text]
		return

	_winner_label.text = ""


func _count_fit_units(paths: Array[NodePath]) -> int:
	var fit_count: int = 0
	for unit in _get_units(paths):
		if unit != null and unit.has_method("get_vital_state") and String(unit.call("get_vital_state")) == "fit":
			fit_count += 1

	return fit_count


func _count_fit_enemy_units() -> int:
	var fit_count: int = 0
	for enemy in _get_active_enemy_units():
		if enemy != null and enemy.has_method("get_vital_state") and String(enemy.call("get_vital_state")) == "fit":
			fit_count += 1

	return fit_count


func _build_attack_readiness_text() -> String:
	if _current_tick >= _next_attack_tick:
		return "ready"

	return "tick %d" % (_next_attack_tick - _current_tick)


func _finish_readability_setup() -> void:
	if preview_mode:
		_remove_readability_nodes()
		_apply_overlay_visibility()
		return
	_ensure_readability_nodes()
	_apply_overlay_visibility()
	_update_event_label()
	_update_winner_label()
	_update_status_label("waiting")


func set_preview_mode(is_preview: bool) -> void:
	preview_mode = is_preview
	if preview_mode:
		_remove_readability_nodes()
		_apply_overlay_visibility()
		return
	if is_inside_tree():
		_finish_readability_setup()


func set_overlay_visible(is_visible: bool) -> void:
	_overlays_visible = is_visible
	_apply_overlay_visibility()


func _apply_overlay_visibility() -> void:
	var status_label = get_node_or_null(status_label_path)
	if status_label != null:
		status_label.set("visible", _overlays_visible and not preview_mode)
	if _contact_line != null:
		_contact_line.visible = _overlays_visible and not preview_mode
	if _event_label != null:
		_event_label.visible = _overlays_visible and not preview_mode
	if _winner_label != null:
		_winner_label.visible = _overlays_visible and not preview_mode


func _remove_readability_nodes() -> void:
	if _contact_line != null:
		_contact_line.queue_free()
		_contact_line = null
	if _event_label != null:
		_event_label.queue_free()
		_event_label = null
	if _winner_label != null:
		_winner_label.queue_free()
		_winner_label = null


func _is_victory_condition_met() -> bool:
	match win_condition:
		WIN_CONDITION_OBJECTIVE_CAPTURE:
			_update_objective_hold_tracking()
			return _is_objective_captured_by_friendly()
		WIN_CONDITION_OBJECTIVE_DEFENSE:
			_update_objective_hold_tracking()
			return _is_objective_captured_by_friendly() and _get_objective_defense_elapsed_seconds() >= objective_defense_hold_seconds
		_:
			return _is_enemy_team_eliminated()


func _is_enemy_team_eliminated() -> bool:
	var active_enemy_units: Array = _get_active_enemy_units()
	if active_enemy_units.is_empty():
		if _has_pending_enemy_waves():
			return false

		return false

	if _has_pending_enemy_waves():
		return false

	if _has_pending_enemy_respawns():
		return false

	return _count_fit_enemy_units() == 0


func _resolve_combat(result: String, winning_team_id: String) -> void:
	if _combat_finished:
		return

	_combat_finished = true
	_winning_team_id = winning_team_id
	_mission_result = _build_mission_result(result, winning_team_id)
	_set_event_text("MISSION %s" % result.to_upper())
	_clear_contact_visuals()
	_update_status_label("resolved")
	_update_winner_label()
	if _can_broadcast_to_clients():
		_receive_mission_result.rpc(_mission_result)
	combat_resolved.emit(get_mission_result())


func _build_mission_result(result: String, winning_team_id: String) -> Dictionary:
	return {
		"winning_team_id": winning_team_id,
		"friendly_team_id": friendly_team_id,
		"mission_outcome": "won" if result == "victory" else "lost",
		"result": result,
		"win_condition_type": win_condition,
		"objective_captured": _is_objective_captured_by_friendly(),
		"duration_seconds": _get_duration_seconds(),
		"team_states": _build_team_states(friendly_unit_paths),
	}


func _get_enemy_team_id() -> String:
	for enemy in _get_units(enemy_unit_paths):
		if enemy != null and enemy.has_method("get_team_id"):
			var team_id: String = String(enemy.call("get_team_id"))
			if not team_id.is_empty():
				return team_id

	return ""


func _get_duration_seconds() -> float:
	if _mission_started_at_msec <= 0:
		return 0.0

	return maxf(float(Time.get_ticks_msec() - _mission_started_at_msec) / 1000.0, 0.0)


func _get_objective_status():
	var simulation_root = get_node_or_null(simulation_root_path)
	if simulation_root == null or not simulation_root.has_method("get_objective_status"):
		return null

	return simulation_root.call("get_objective_status")


func _is_objective_captured_by_friendly() -> bool:
	var objective_status = _get_objective_status()
	if objective_status == null:
		return false

	return String(objective_status.owning_team_id) == friendly_team_id and float(objective_status.capture_progress) >= 1.0


func _update_objective_hold_tracking() -> void:
	if win_condition != WIN_CONDITION_OBJECTIVE_DEFENSE:
		return

	if _is_objective_captured_by_friendly():
		if _objective_owned_since_msec < 0:
			_objective_owned_since_msec = Time.get_ticks_msec()
		return

	_objective_owned_since_msec = -1


func _get_objective_defense_elapsed_seconds() -> float:
	if _objective_owned_since_msec < 0:
		return 0.0

	return maxf(float(Time.get_ticks_msec() - _objective_owned_since_msec) / 1000.0, 0.0)


func _build_objective_status_text() -> String:
	var objective_status = _get_objective_status()
	if objective_status == null:
		return "Objective: unavailable"

	var owner_text: String = String(objective_status.owning_team_id)
	if owner_text.is_empty():
		owner_text = "neutral"

	var progress_percent: int = int(round(clampf(float(objective_status.capture_progress), 0.0, 1.0) * 100.0))
	var status_text: String = "Objective: %s %d%%" % [owner_text, progress_percent]
	if bool(objective_status.call("is_contested")):
		status_text += " contested"

	return status_text


func _advance_enemy_units(simulation_root: Node) -> void:
	if not enemy_advance_enabled:
		return

	var objective_position: Vector2 = _get_objective_position()
	for enemy in _get_active_enemy_units():
		if enemy == null or not enemy.has_method("get_vital_state"):
			continue

		if String(enemy.call("get_vital_state")) != "fit":
			continue

		if _try_enqueue_enemy_patrol_move(simulation_root, enemy):
			continue

		if _enemy_should_hold_position(enemy):
			continue

		simulation_root.call(
			"enqueue_command",
			{
				"command_type": "move_to_position",
				"priority": 8,
				"unit_id": String(enemy.call("get_unit_id")),
				"target_position": objective_position,
				"move_speed_factor": enemy_advance_speed_factor,
				"requeue_until_target": false,
			}
		)


func _initialize_enemy_patrol_paths() -> void:
	_enemy_patrol_paths_by_unit_id.clear()
	_enemy_patrol_waypoint_index_by_unit_id.clear()
	_enemy_patrol_contact_locked.clear()
	var enemy_wave_controller = _get_enemy_wave_controller()
	if enemy_wave_controller == null or not enemy_wave_controller.has_method("get_patrol_path_for_unit"):
		return
	for enemy in _get_units(enemy_unit_paths):
		if enemy == null or not enemy.has_method("get_unit_id"):
			continue
		var unit_id: String = String(enemy.call("get_unit_id")).strip_edges()
		if unit_id.is_empty():
			continue
		var patrol_path: Array = Array(enemy_wave_controller.call("get_patrol_path_for_unit", unit_id)).duplicate(true)
		if patrol_path.is_empty():
			continue
		_enemy_patrol_paths_by_unit_id[unit_id] = patrol_path
		_enemy_patrol_waypoint_index_by_unit_id[unit_id] = 0
		_enemy_patrol_contact_locked[unit_id] = false


func _try_enqueue_enemy_patrol_move(simulation_root: Node, enemy) -> bool:
	if enemy == null or not (enemy is Node2D) or not enemy.has_method("get_unit_id"):
		return false
	var unit_id: String = String(enemy.call("get_unit_id")).strip_edges()
	if unit_id.is_empty() or not _enemy_patrol_paths_by_unit_id.has(unit_id):
		return false
	if bool(_enemy_patrol_contact_locked.get(unit_id, false)):
		return false
	if _enemy_should_hold_position(enemy):
		_enemy_patrol_contact_locked[unit_id] = true
		return false
	var patrol_path: Array = Array(_enemy_patrol_paths_by_unit_id.get(unit_id, []))
	if patrol_path.is_empty():
		return false
	var waypoint_index: int = int(_enemy_patrol_waypoint_index_by_unit_id.get(unit_id, 0))
	if waypoint_index < 0:
		waypoint_index = 0
	if waypoint_index >= patrol_path.size():
		waypoint_index = 0
	var target_position: Vector2 = _coerce_vector2(patrol_path[waypoint_index], (enemy as Node2D).global_position)
	if (enemy as Node2D).global_position.distance_to(target_position) <= ENEMY_PATROL_WAYPOINT_REACHED_DISTANCE:
		waypoint_index = (waypoint_index + 1) % patrol_path.size()
		_enemy_patrol_waypoint_index_by_unit_id[unit_id] = waypoint_index
		target_position = _coerce_vector2(patrol_path[waypoint_index], target_position)
	simulation_root.call(
		"enqueue_command",
		{
			"command_type": "move_to_position",
			"priority": 7,
			"unit_id": unit_id,
			"target_position": target_position,
			"move_speed_factor": enemy_advance_speed_factor,
			"requeue_until_target": false,
		}
	)
	return true


func _enemy_should_hold_position(enemy) -> bool:
	if enemy == null or not (enemy is Node2D):
		return true

	for friendly in _get_units(friendly_unit_paths):
		if friendly == null or not _can_target_receive_attack(friendly):
			continue

		if not _los_system.has_line_of_sight_between_nodes(enemy, friendly, _get_effective_range(friendly), _get_terrain_registry()):
			continue

		if (enemy as Node2D).global_position.distance_to((friendly as Node2D).global_position) <= enemy_engage_distance:
			return true

	return false


func _pick_target_from_units(attacker, targets: Array):
	for target in targets:
		if not _is_target_attackable(attacker, target):
			continue

		return target

	return null


func _get_active_enemy_units() -> Array:
	var active_units: Array = []
	var unit_registry = _get_unit_registry()
	for enemy in _get_units(enemy_unit_paths):
		if enemy == null or not enemy.has_method("get_unit_id"):
			continue

		if unit_registry != null and unit_registry.has_method("has_unit"):
			if not bool(unit_registry.call("has_unit", String(enemy.call("get_unit_id")))):
				continue

		if enemy is CanvasItem and not (enemy as CanvasItem).visible:
			continue

		active_units.append(enemy)

	return active_units


func _get_unit_registry():
	var simulation_root = get_node_or_null(simulation_root_path)
	if simulation_root == null or not simulation_root.has_method("_get_unit_registry"):
		return null

	return simulation_root.call("_get_unit_registry")


func _get_objective_position() -> Vector2:
	var objective_status = _get_objective_status()
	if objective_status != null:
		return objective_status.position

	return Vector2.ZERO


func _try_reposition_enemy_on_damage(unit, hit_context: Dictionary) -> void:
	if not enemy_reposition_enabled:
		return

	if unit == null or not unit.has_method("get_unit_id") or not unit.has_method("get_team_id"):
		return

	if String(unit.call("get_team_id")) == friendly_team_id:
		return

	if not _get_active_enemy_units().has(unit):
		return

	if String(unit.call("get_vital_state")) != "fit":
		return

	var unit_id: String = String(unit.call("get_unit_id"))
	var now_msec: int = Time.get_ticks_msec()
	if int(_enemy_reposition_ready_at_msec.get(unit_id, 0)) > now_msec:
		return

	var simulation_root = get_node_or_null(simulation_root_path)
	if simulation_root == null:
		return

	var reposition_target: Vector2 = _build_enemy_reposition_target(unit, hit_context)
	simulation_root.call(
		"enqueue_command",
		{
			"command_type": "move_to_position",
			"priority": 12,
			"unit_id": unit_id,
			"target_position": reposition_target,
			"move_speed_factor": enemy_reposition_move_speed_factor,
			"requeue_until_target": true,
		}
	)
	_enemy_reposition_ready_at_msec[unit_id] = now_msec + int(round(enemy_reposition_cooldown_seconds * 1000.0))


func _build_enemy_reposition_target(unit, hit_context: Dictionary) -> Vector2:
	var unit_node: Node2D = unit
	var attacker_direction: Vector2 = Vector2.ZERO
	var attacker_unit_id: String = String(hit_context.get("attacker_unit_id", ""))
	var attacker = _resolve_unit_by_id(attacker_unit_id)
	if attacker != null and attacker is Node2D:
		attacker_direction = unit_node.global_position - (attacker as Node2D).global_position

	if attacker_direction.is_zero_approx():
		attacker_direction = Vector2.RIGHT.rotated(randf() * TAU)

	# Try cover-seeking: find walkable cover tiles in reposition radius
	var terrain_registry = _get_terrain_registry()
	if terrain_registry != null and terrain_registry.has_method("get_walkable_cover_tiles_in_radius"):
		var cover_tiles: Array = terrain_registry.call("get_walkable_cover_tiles_in_radius", unit_node.global_position, enemy_reposition_max_distance)
		if cover_tiles.size() > 0:
			# Filter tiles that are at least min_distance away
			var min_dist_sq: float = enemy_reposition_min_distance * enemy_reposition_min_distance
			var candidates: Array = []
			for tile in cover_tiles:
				if unit_node.global_position.distance_squared_to(tile.world_position) >= min_dist_sq:
					candidates.append(tile)
			if candidates.size() > 0:
				# Sort by cover_value descending, pick best
				candidates.sort_custom(func(a, b): return int(a.cover_value) > int(b.cover_value))
				return Vector2(candidates[0].world_position)

	# Fallback: random reposition away from attacker
	var reposition_distance: float = randf_range(enemy_reposition_min_distance, enemy_reposition_max_distance)
	return unit_node.global_position + attacker_direction.normalized() * reposition_distance


func _resolve_unit_by_id(unit_id: String):
	if unit_id.is_empty():
		return null

	var unit_registry = _get_unit_registry()
	if unit_registry == null or not unit_registry.has_method("get_unit"):
		return null

	return unit_registry.call("get_unit", unit_id)


func _get_enemy_wave_controller():
	if enemy_wave_controller_path.is_empty():
		return null

	return get_node_or_null(enemy_wave_controller_path)


func _get_terrain_registry():
	if not terrain_registry_path.is_empty():
		return get_node_or_null(terrain_registry_path)

	var simulation_root = get_node_or_null(simulation_root_path)
	if simulation_root == null or not simulation_root.has_method("_get_terrain_registry"):
		return null

	return simulation_root.call("_get_terrain_registry")


func _get_tactical_controller():
	if not tactical_controller_path.is_empty():
		return get_node_or_null(tactical_controller_path)
	return get_node_or_null("../TacticalController")


func _apply_friendly_standard_behavior(simulation_root: Node) -> void:
	if simulation_root == null:
		return
	var tactical_controller = _get_tactical_controller()
	if tactical_controller == null or not tactical_controller.has_method("get_active_behavior_profile"):
		return
	for friendly in _get_units(friendly_unit_paths):
		if friendly == null or not (friendly is Node2D) or not friendly.has_method("get_vital_state"):
			continue
		if String(friendly.call("get_vital_state")) != "fit":
			continue
		if not (friendly.has_method("is_in_contact") and bool(friendly.call("is_in_contact"))):
			continue
		if not friendly.has_method("get_fireteam_id") or not friendly.has_method("get_unit_id"):
			continue
		var fireteam_id: String = String(friendly.call("get_fireteam_id")).strip_edges().to_lower()
		var profile_dict: Dictionary = Dictionary(tactical_controller.call("get_active_behavior_profile", fireteam_id))
		if profile_dict.is_empty():
			continue
		var metadata: Dictionary = Dictionary(profile_dict.get("metadata", {}))
		if String(metadata.get("origin", "")) != "standard_behavior":
			continue
		if not bool(metadata.get("prefer_cover_seek", false)):
			continue
		if _extract_current_command_type(friendly) != "hold_position":
			continue
		if friendly.has_method("get_effective_cover_score") and int(friendly.call("get_effective_cover_score")) >= FRIENDLY_LOW_COVER_THRESHOLD:
			continue
		var unit_id: String = String(friendly.call("get_unit_id"))
		var now_msec: int = Time.get_ticks_msec()
		if int(_friendly_cover_ready_at_msec.get(unit_id, 0)) > now_msec:
			continue
		var cover_target: Vector2 = _build_friendly_cover_target(friendly, profile_dict)
		if cover_target == Vector2.INF:
			continue
		simulation_root.call(
			"enqueue_command",
			{
				"command_type": "move_to_position",
				"priority": 11,
				"unit_id": unit_id,
				"target_position": cover_target,
				"move_speed_factor": 0.35,
				"requeue_until_target": true,
			}
		)
		_friendly_cover_ready_at_msec[unit_id] = now_msec + FRIENDLY_STANDARD_COVER_COOLDOWN_MSEC
		if friendly.has_method("show_event_text"):
			friendly.call("show_event_text", "SEEK COVER", DEFAULT_EVENT_COLOR, 0.9)


func _try_enqueue_overwatch(simulation_root: Node) -> Array:
	if simulation_root == null or _overwatch_controller == null:
		return []
	var tactical_controller = _get_tactical_controller()
	if tactical_controller == null or not tactical_controller.has_method("refresh_fireteam_security_state") or not tactical_controller.has_method("get_fireteam_security_snapshot"):
		_overwatch_controller.call("reset_all")
		return []
	tactical_controller.call("refresh_fireteam_security_state")
	var friendly_units_by_fireteam: Dictionary = {}
	for friendly in _get_units(friendly_unit_paths):
		if friendly == null or not friendly.has_method("get_fireteam_id"):
			continue
		var fireteam_id: String = String(friendly.call("get_fireteam_id")).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		if not friendly_units_by_fireteam.has(fireteam_id):
			friendly_units_by_fireteam[fireteam_id] = []
		var fireteam_units: Array = Array(friendly_units_by_fireteam.get(fireteam_id, []))
		fireteam_units.append(friendly)
		friendly_units_by_fireteam[fireteam_id] = fireteam_units
	var shots: Array = Array(
		_overwatch_controller.call(
			"update",
			simulation_root,
			Array(tactical_controller.call("get_fireteam_security_snapshot")),
			friendly_units_by_fireteam,
			_get_active_enemy_units(),
			_get_terrain_registry(),
			contact_range,
			_current_tick
		)
	)
	for shot_variant in shots:
		if typeof(shot_variant) != TYPE_DICTIONARY:
			continue
		var shot: Dictionary = Dictionary(shot_variant)
		var attacker = _resolve_unit_by_id(String(shot.get("attacker_unit_id", "")))
		var target = _resolve_unit_by_id(String(shot.get("target_unit_id", "")))
		if attacker != null and target != null:
			_set_contact_visuals(attacker, target)
		var event_text: String = "OVERWATCH %s -> %s" % [String(shot.get("attacker_unit_id", "")), String(shot.get("target_unit_id", ""))]
		_set_event_text(event_text)
		if attacker != null and attacker.has_method("show_event_text"):
			attacker.call("show_event_text", "OVERWATCH", DEFAULT_EVENT_COLOR, 1.1)
		_broadcast_remote_event(event_text, String(shot.get("attacker_unit_id", "")), DEFAULT_EVENT_COLOR, 1.1, "OVERWATCH")
	return shots


func _extract_current_command_type(unit) -> String:
	if unit == null:
		return ""
	if unit.has_method("get_current_unit_command"):
		var command = unit.call("get_current_unit_command")
		if command != null and command.has_method("get"):
			return String(command.get("command_type"))
	if unit.has_method("get_runtime_status"):
		var runtime_status = unit.call("get_runtime_status")
		if runtime_status != null and runtime_status.has_method("get"):
			return String(runtime_status.get("active_command_type"))
	return ""


func _build_friendly_cover_target(unit, profile_dict: Dictionary) -> Vector2:
	var terrain_registry = _get_terrain_registry()
	if terrain_registry == null or not terrain_registry.has_method("get_walkable_cover_tiles_in_radius"):
		return Vector2.INF
	if unit == null or not (unit is Node2D):
		return Vector2.INF
	var unit_node: Node2D = unit
	var min_dist_sq: float = FRIENDLY_STANDARD_COVER_MIN_DISTANCE * FRIENDLY_STANDARD_COVER_MIN_DISTANCE
	var best_position: Vector2 = Vector2.INF
	var best_score: float = -INF
	var cover_priority: float = clampf(float(profile_dict.get("cover_priority", 0.5)), 0.0, 1.0)
	for tile in terrain_registry.call("get_walkable_cover_tiles_in_radius", unit_node.global_position, FRIENDLY_STANDARD_COVER_RADIUS):
		if tile == null:
			continue
		var tile_position: Vector2 = Vector2(tile.world_position)
		var distance_sq: float = unit_node.global_position.distance_squared_to(tile_position)
		if distance_sq < min_dist_sq:
			continue
		var cover_score: float = clampf(float(tile.cover_value) / 100.0, 0.0, 1.0)
		var score: float = (cover_score * (0.6 + cover_priority)) - (sqrt(distance_sq) * 0.02)
		if score <= best_score:
			continue
		best_score = score
		best_position = tile_position
	return best_position


func get_current_fireteam_lead_unit(fireteam_id: String):
	var normalized_fireteam_id: String = fireteam_id.strip_edges()
	if normalized_fireteam_id.is_empty():
		return null
	var acting_lead_id: String = String(_fireteam_acting_leads.get(normalized_fireteam_id, ""))
	if not acting_lead_id.is_empty():
		return _resolve_unit_by_id(acting_lead_id)
	return null


func _has_pending_enemy_waves() -> bool:
	var enemy_wave_controller = _get_enemy_wave_controller()
	if enemy_wave_controller == null or not enemy_wave_controller.has_method("are_all_waves_started"):
		return false

	return not bool(enemy_wave_controller.call("are_all_waves_started"))


func _has_pending_enemy_respawns() -> bool:
	var respawn_manager = get_node_or_null(respawn_manager_path)
	if respawn_manager == null or not respawn_manager.has_method("has_pending_respawn"):
		return false

	for enemy in _get_units(enemy_unit_paths):
		if enemy == null or not enemy.has_method("get_unit_id"):
			continue

		var unit_id: String = String(enemy.call("get_unit_id"))
		if unit_id.is_empty():
			continue

		if bool(respawn_manager.call("has_pending_respawn", unit_id)):
			return true

	return false


func _build_wave_status_text() -> String:
	var enemy_wave_controller = _get_enemy_wave_controller()
	if enemy_wave_controller == null:
		return "Wave: none"

	if not enemy_wave_controller.has_method("get_current_wave_number") or not enemy_wave_controller.has_method("get_total_wave_count"):
		return "Wave: unavailable"

	return "Wave: %d/%d" % [
		int(enemy_wave_controller.call("get_current_wave_number")),
		int(enemy_wave_controller.call("get_total_wave_count")),
	]


func _on_enemy_wave_started(wave_number: int) -> void:
	if wave_number <= 1:
		_set_event_text("ENEMY WAVE %d" % wave_number)
		_broadcast_remote_event("ENEMY WAVE %d" % wave_number)
		return

	_set_event_text("ENEMY REINFORCEMENTS")
	_broadcast_remote_event("ENEMY REINFORCEMENTS")


func _coerce_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Vector2i:
		return Vector2(value.x, value.y)
	if typeof(value) == TYPE_DICTIONARY:
		var value_dict: Dictionary = value
		return Vector2(float(value_dict.get("x", fallback.x)), float(value_dict.get("y", fallback.y)))
	return fallback
