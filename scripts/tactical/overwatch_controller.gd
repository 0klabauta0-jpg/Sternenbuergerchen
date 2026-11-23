class_name OverwatchController
extends RefCounted

const LOS_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/los_system.gd")
const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")
const COMBAT_CADENCE_SCRIPT: GDScript = preload("res://scripts/combat/combat_cadence.gd")

const OVERWATCH_MOVE_THRESHOLD: float = 5.0
const OVERWATCH_ACCURACY_BONUS: float = 0.1

var _los_system = LOS_SYSTEM_SCRIPT.new()
var _last_enemy_positions_by_unit_id: Dictionary = {}
var _member_ready_tick_by_unit_id: Dictionary = {}
## Gefechtstakt: Ein Normalschuss sperrt dasselbe Mitglied fuer die Ueberwachung (eine Waffenperiode), damit es
## nicht im Schritt danach ein zweites Mal schiesst. Getrennt von der Ueberwachungssperre, damit der Normaltakt
## (get_member_ready_snapshot) durch diese Sperre nie ausgebremst wird.
var _normal_fire_ready_tick_by_unit_id: Dictionary = {}


func reset_all() -> void:
	_last_enemy_positions_by_unit_id.clear()
	_member_ready_tick_by_unit_id.clear()
	_normal_fire_ready_tick_by_unit_id.clear()


func note_member_fired(unit_id: String, ready_tick: int) -> void:
	var key: String = unit_id.strip_edges()
	if key.is_empty():
		return
	_normal_fire_ready_tick_by_unit_id[key] = maxi(int(_normal_fire_ready_tick_by_unit_id.get(key, 0)), ready_tick)


func get_member_ready_snapshot(current_tick: int = -1) -> Dictionary:
	var result: Dictionary = {}
	for unit_id_variant in _member_ready_tick_by_unit_id.keys():
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty():
			continue
		var ready_tick: int = int(_member_ready_tick_by_unit_id.get(unit_id_variant, 0))
		result[unit_id] = {
			"unit_id": unit_id,
			"ready_tick": ready_tick,
			"ready": current_tick < 0 or ready_tick <= current_tick,
			"cooldown_remaining_ticks": maxi(ready_tick - current_tick, 0) if current_tick >= 0 else 0,
		}
	return result


func update(
	simulation_root,
	security_snapshot: Array,
	friendly_units_by_fireteam: Dictionary,
	enemy_units: Array,
	terrain_registry,
	base_contact_range: float,
	current_tick: int
) -> Array:
	var triggered_shots: Array = []
	if simulation_root == null:
		_prime_enemy_positions(enemy_units)
		return triggered_shots
	for security_state_variant in security_snapshot:
		if typeof(security_state_variant) != TYPE_DICTIONARY:
			continue
		var security_state: Dictionary = Dictionary(security_state_variant)
		if not bool(security_state.get("overwatch_ready", false)):
			continue
		var fireteam_id: String = String(security_state.get("fireteam_id", "")).strip_edges().to_lower()
		var friendly_units: Array = Array(friendly_units_by_fireteam.get(fireteam_id, []))
		if friendly_units.is_empty():
			continue
		var unit_lookup: Dictionary = _build_unit_lookup(friendly_units)
		var anchor_position: Vector2 = Vector2(security_state.get("anchor_position", Vector2.ZERO))
		var enemy_candidates: Array = _filter_enemy_units_for_overwatch(anchor_position, enemy_units, base_contact_range)
		if enemy_candidates.is_empty():
			continue
		for assignment_variant in Array(security_state.get("member_assignments", [])):
			if typeof(assignment_variant) != TYPE_DICTIONARY:
				continue
			var assignment: Dictionary = Dictionary(assignment_variant)
			var member_unit_id: String = String(assignment.get("unit_id", "")).strip_edges()
			if member_unit_id.is_empty():
				continue
			if int(_member_ready_tick_by_unit_id.get(member_unit_id, 0)) > current_tick:
				continue
			if int(_normal_fire_ready_tick_by_unit_id.get(member_unit_id, 0)) > current_tick:
				continue
			var member = unit_lookup.get(member_unit_id, null)
			if not _can_member_overwatch(member):
				continue
			for enemy in enemy_candidates:
				var shot_dict: Dictionary = _try_build_overwatch_shot(member, enemy, assignment, anchor_position, terrain_registry, base_contact_range)
				if shot_dict.is_empty():
					continue
				var weapon_ticks: int = int(shot_dict.get("weapon_ticks", 1))
				_member_ready_tick_by_unit_id[member_unit_id] = current_tick + _get_lock_ticks(member, weapon_ticks)
				simulation_root.call(
					"enqueue_effect",
					{
						"effect_type": "damage",
						"priority": 35,
						"unit_id": String(shot_dict.get("target_unit_id", "")),
						"attacker_unit_id": member_unit_id,
						"attacker_team_id": String(shot_dict.get("attacker_team_id", "")),
						"allow_friendly_fire": false,
						"damage": int(shot_dict.get("damage", 0)),
						"hit_chance": float(shot_dict.get("hit_chance", 0.0)),
						"damage_multiplier": 1.0,
					}
				)
				triggered_shots.append(shot_dict)
				break
			if not triggered_shots.is_empty():
				break
		if not triggered_shots.is_empty():
			break
	_prime_enemy_positions(enemy_units)
	return triggered_shots


## Gefechtstakt: Die Sperre nach einem Ueberwachungsschuss ist eine Periode des Mitglieds (aufgerundete Schritte
## in Ticks), mit demselben Takt wie der Normalschuss (CombatCadence), nicht der rohe Waffenwert.
func _get_lock_ticks(member, weapon_ticks: int) -> int:
	var initiative: float = -1.0
	if member != null and member.has_method("get_character_profile_bundle"):
		var axes: Dictionary = Dictionary(Dictionary(member.call("get_character_profile_bundle")).get("behavior_axes", {}))
		initiative = float(axes.get("initiative", -1.0))
	return maxi(COMBAT_CADENCE_SCRIPT.period_steps(weapon_ticks, initiative) * COMBAT_CADENCE_SCRIPT.DECISION_INTERVAL_TICKS, 1)


func _try_build_overwatch_shot(member, enemy, assignment: Dictionary, anchor_position: Vector2, terrain_registry, base_contact_range: float) -> Dictionary:
	if member == null or enemy == null or not (enemy is Node2D):
		return {}
	if not enemy.has_method("get_unit_id") or not enemy.has_method("get_vital_state") or String(enemy.call("get_vital_state")) != "fit":
		return {}
	var enemy_unit_id: String = String(enemy.call("get_unit_id")).strip_edges()
	if enemy_unit_id.is_empty():
		return {}
	var enemy_position: Vector2 = (enemy as Node2D).global_position
	var previous_position: Vector2 = Vector2(_last_enemy_positions_by_unit_id.get(enemy_unit_id, enemy_position))
	if previous_position.distance_to(enemy_position) < OVERWATCH_MOVE_THRESHOLD:
		return {}
	var center_angle: float = float(assignment.get("center_angle", 0.0))
	var arc_width: float = float(assignment.get("arc_width", TAU))
	if not _angle_within_sector((enemy_position - anchor_position).angle(), center_angle, arc_width):
		return {}
	var active_weapon_id: String = _get_active_weapon_id(member)
	var weapon_range_world: float = WEAPON_DATA_SCRIPT.get_effective_world_range(active_weapon_id, terrain_registry)
	if not _los_system.has_line_of_sight_between_nodes(member, enemy, weapon_range_world, terrain_registry):
		return {}
	return {
		"attacker_unit_id": String(member.call("get_unit_id")) if member.has_method("get_unit_id") else "",
		"attacker_team_id": String(member.call("get_team_id")) if member.has_method("get_team_id") else "",
		"target_unit_id": enemy_unit_id,
		"weapon_id": active_weapon_id,
		"weapon_tile_range": WEAPON_DATA_SCRIPT.get_effective_tile_range(active_weapon_id),
		"weapon_range_world": weapon_range_world,
		"damage": WEAPON_DATA_SCRIPT.get_damage_per_hit(active_weapon_id),
		"hit_chance": minf(WEAPON_DATA_SCRIPT.get_base_hit_chance(active_weapon_id) + OVERWATCH_ACCURACY_BONUS, 0.98),
		"weapon_ticks": WEAPON_DATA_SCRIPT.get_ticks_between_attacks(active_weapon_id),
	}


func _build_unit_lookup(units: Array) -> Dictionary:
	var lookup: Dictionary = {}
	for unit in units:
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		lookup[String(unit.call("get_unit_id"))] = unit
	return lookup


func _filter_enemy_units_for_overwatch(anchor_position: Vector2, enemy_units: Array, base_contact_range: float) -> Array:
	var max_distance: float = maxf(base_contact_range, 0.0)
	if max_distance <= 0.0:
		return enemy_units.duplicate()
	var max_distance_sq: float = max_distance * max_distance
	var result: Array = []
	for enemy in enemy_units:
		if enemy == null or not (enemy is Node2D):
			continue
		if anchor_position.distance_squared_to((enemy as Node2D).global_position) > max_distance_sq:
			continue
		result.append(enemy)
	return result


func _can_member_overwatch(unit) -> bool:
	if unit == null or not unit.has_method("get_vital_state"):
		return false
	if String(unit.call("get_vital_state")) != "fit":
		return false
	return unit is Node2D and not _get_active_weapon_id(unit).is_empty()


func _get_active_weapon_id(unit) -> String:
	if unit != null and unit.has_method("get_active_weapon_id"):
		var weapon_id: String = String(unit.call("get_active_weapon_id")).strip_edges()
		if WEAPON_DATA_SCRIPT.is_attack_weapon_id(weapon_id):
			return weapon_id
	return ""


func _prime_enemy_positions(enemy_units: Array) -> void:
	for enemy in enemy_units:
		if enemy == null or not (enemy is Node2D) or not enemy.has_method("get_unit_id"):
			continue
		_last_enemy_positions_by_unit_id[String(enemy.call("get_unit_id"))] = (enemy as Node2D).global_position


func _angle_within_sector(target_angle: float, center_angle: float, arc_width: float) -> bool:
	return absf(wrapf(target_angle - center_angle, -PI, PI)) <= arc_width * 0.5
