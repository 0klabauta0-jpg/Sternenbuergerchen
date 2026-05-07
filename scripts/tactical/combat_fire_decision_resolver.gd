class_name CombatFireDecisionResolver
extends RefCounted

const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")
const AREA_ORDER_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/area_order_resolver.gd")


static func find_first_contact_pair(context: Dictionary) -> Dictionary:
	var friendly_units: Array = Array(context.get("friendly_units", []))
	var enemy_units: Array = Array(context.get("enemy_units", []))
	var friendly_team_id: String = String(context.get("friendly_team_id", ""))
	for friendly in friendly_units:
		if not _can_unit_seek_target(friendly):
			continue
		var enemy = pick_target_from_units(friendly, enemy_units, context)
		if enemy == null:
			continue
		var f_id: String = String(friendly.call("get_unit_id"))
		var e_id: String = String(enemy.call("get_unit_id"))
		var start_detection: Callable = context.get("start_detection", Callable())
		if start_detection.is_valid():
			start_detection.call(friendly, f_id, e_id)
		var is_detection_complete: Callable = context.get("is_detection_complete", Callable())
		if is_detection_complete.is_valid() and not bool(is_detection_complete.call(f_id, e_id)):
			continue
		var fireteam_id: String = ""
		if friendly.has_method("get_fireteam_id"):
			fireteam_id = String(friendly.call("get_fireteam_id")).strip_edges().to_lower()
		var contact_entry: Dictionary = _call_contact_state(context, fireteam_id, e_id)
		var detection_state: String = String(contact_entry.get("detection_state", "confirmed")).strip_edges().to_lower()
		if detection_state != "spotted" and detection_state != "confirmed":
			continue
		if not can_unit_attack(friendly, context):
			continue
		return {
			"attacker": friendly,
			"target": enemy,
			"attacker_id": f_id,
			"target_id": e_id,
			"contact_state": detection_state,
		}

	for enemy in enemy_units:
		if not can_enemy_attack(enemy):
			continue
		var friendly = pick_target_from_units(enemy, friendly_units, context)
		if friendly == null:
			continue
		var en_id: String = String(enemy.call("get_unit_id"))
		var fr_id: String = String(friendly.call("get_unit_id"))
		var start_detection_enemy: Callable = context.get("start_detection", Callable())
		if start_detection_enemy.is_valid():
			start_detection_enemy.call(enemy, en_id, fr_id)
		var is_detection_complete_enemy: Callable = context.get("is_detection_complete", Callable())
		if is_detection_complete_enemy.is_valid() and not bool(is_detection_complete_enemy.call(en_id, fr_id)):
			continue
		return {
			"attacker": enemy,
			"target": friendly,
			"attacker_id": en_id,
			"target_id": fr_id,
			"contact_state": _resolve_enemy_contact_state_text(friendly_team_id),
		}

	return {}


static func build_damage_effect(contact_pair: Dictionary, context: Dictionary) -> Dictionary:
	if contact_pair.is_empty():
		return {}
	var attacker = contact_pair.get("attacker", null)
	var target = contact_pair.get("target", null)
	if attacker == null or target == null:
		return {}
	var attacker_id: String = String(contact_pair.get("attacker_id", "")).strip_edges()
	var target_id: String = String(contact_pair.get("target_id", "")).strip_edges()
	if attacker_id.is_empty() or target_id.is_empty():
		return {}
	var actual_target = target
	var actual_target_id: String = target_id
	var is_friendly_fire: bool = false
	var misid_result: Dictionary = _call_misidentification(context, attacker, attacker_id)
	if not misid_result.is_empty():
		actual_target = misid_result.get("target", target)
		actual_target_id = String(misid_result.get("target_id", target_id)).strip_edges()
		is_friendly_fire = true
	var active_weapon_id: String = get_unit_active_weapon_id(attacker)
	var weapon_tile_range: int = WEAPON_DATA_SCRIPT.get_effective_tile_range(active_weapon_id)
	var weapon_range_world: float = _get_weapon_attack_range(attacker, actual_target, context)
	var weapon_hit_chance: float = WEAPON_DATA_SCRIPT.get_base_hit_chance(active_weapon_id)
	var friendly_team_id: String = String(context.get("friendly_team_id", ""))
	var contact_state: String = String(contact_pair.get("contact_state", "")).strip_edges().to_lower()
	if _get_team_id(attacker) == friendly_team_id and contact_state == "spotted":
		weapon_hit_chance = clampf(weapon_hit_chance + float(context.get("spotted_contact_hit_chance_malus", 0.0)), 0.02, 0.98)
	var flank_modifiers: Dictionary = _call_flank_resolver(context, attacker, actual_target)
	if bool(flank_modifiers.get("is_flank", false)):
		weapon_hit_chance = clampf(weapon_hit_chance + float(flank_modifiers.get("hit_chance_bonus", 0.0)), 0.02, 0.98)
	return {
		"effect": {
			"effect_type": "damage",
			"priority": 30,
			"unit_id": actual_target_id,
			"attacker_unit_id": attacker_id,
			"attacker_team_id": _get_team_id(attacker),
			"allow_friendly_fire": is_friendly_fire,
			"weapon_id": active_weapon_id,
			"weapon_tile_range": weapon_tile_range,
			"weapon_range_world": weapon_range_world,
			"damage": WEAPON_DATA_SCRIPT.get_damage_per_hit(active_weapon_id),
			"hit_chance": weapon_hit_chance,
			"damage_multiplier": float(context.get("base_damage_multiplier", 1.0)) * float(flank_modifiers.get("damage_multiplier", 1.0)),
			"target_cover_override": flank_modifiers.get("target_cover_override", null),
			"is_flank": bool(flank_modifiers.get("is_flank", false)),
			"flank_fireteam_id": String(flank_modifiers.get("fireteam_id", "")),
			"flank_source_angle": float(flank_modifiers.get("source_angle", 0.0)),
			"flank_direction_label": String(flank_modifiers.get("direction_label", "")),
			"flank_morale_state": String(flank_modifiers.get("morale_state", "")),
		},
		"attacker": attacker,
		"target": actual_target,
		"attacker_id": attacker_id,
		"target_id": actual_target_id,
		"is_friendly_fire": is_friendly_fire,
		"weapon_ticks": WEAPON_DATA_SCRIPT.get_ticks_between_attacks(active_weapon_id),
		"flank_modifiers": flank_modifiers,
	}


static func can_enemy_attack(unit) -> bool:
	if unit == null:
		return false
	if not unit.has_method("get_vital_state"):
		return false
	if String(unit.call("get_vital_state")) != "fit":
		return false
	return not get_unit_active_weapon_id(unit).is_empty()


static func can_unit_attack(unit, context: Dictionary = {}) -> bool:
	if not _can_unit_seek_target(unit):
		return false
	if unit.has_method("get_fire_status") and String(unit.call("get_fire_status")) != "fire_at_will":
		var discipline_break: Callable = context.get("check_discipline_break", Callable())
		if not discipline_break.is_valid() or not bool(discipline_break.call(unit)):
			return false
	return true


static func _can_unit_seek_target(unit) -> bool:
	if unit == null:
		return false
	if not unit.has_method("get_vital_state"):
		return false
	if String(unit.call("get_vital_state")) != "fit":
		return false
	if get_unit_active_weapon_id(unit).is_empty():
		return false
	return is_engage_ready(unit)


static func pick_target_from_units(attacker, targets: Array, context: Dictionary):
	var best_target = null
	var best_score: float = -INF
	for target in targets:
		if not is_target_attackable(attacker, target, context):
			continue
		var score: float = _score_attack_target(attacker, target, context)
		if best_target != null and score <= best_score:
			continue
		best_target = target
		best_score = score
	return best_target


static func is_target_attackable(attacker, target, context: Dictionary) -> bool:
	if target == null or not can_target_receive_attack(target):
		return false
	if attacker == null:
		return false
	if _get_team_id(attacker) == _get_team_id(target):
		return false
	var los_system = context.get("los_system", null)
	if los_system == null or not los_system.has_method("has_line_of_sight_between_nodes"):
		return false
	var effective_attack_range: float = _get_weapon_attack_range(attacker, target, context)
	return bool(los_system.call("has_line_of_sight_between_nodes", attacker, target, effective_attack_range, context.get("terrain_registry", null)))


static func can_target_receive_attack(unit) -> bool:
	if unit == null or not unit.has_method("get_vital_state"):
		return false
	return String(unit.call("get_vital_state")) == "fit"


static func is_engage_ready(unit) -> bool:
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


static func get_unit_active_weapon_id(unit) -> String:
	if unit != null and unit.has_method("get_active_weapon_id"):
		var weapon_id: String = String(unit.call("get_active_weapon_id")).strip_edges()
		if WEAPON_DATA_SCRIPT.is_attack_weapon_id(weapon_id):
			return weapon_id
	return ""


static func _get_weapon_attack_range(attacker, target, context: Dictionary) -> float:
	var get_weapon_attack_range: Callable = context.get("get_weapon_attack_range", Callable())
	if get_weapon_attack_range.is_valid():
		return maxf(float(get_weapon_attack_range.call(attacker, target)), 0.0)
	var active_weapon_id: String = get_unit_active_weapon_id(attacker)
	if not active_weapon_id.is_empty():
		return WEAPON_DATA_SCRIPT.get_effective_world_range(active_weapon_id, context.get("terrain_registry", null))
	var effective_range: Callable = context.get("get_effective_range", Callable())
	if effective_range.is_valid():
		return maxf(float(effective_range.call(target)), 0.0)
	return maxf(float(context.get("contact_range", 0.0)), 0.0)


static func _get_team_id(unit) -> String:
	if unit != null and unit.has_method("get_team_id"):
		return String(unit.call("get_team_id"))
	return ""


static func _resolve_enemy_contact_state_text(friendly_team_id: String) -> String:
	if friendly_team_id.is_empty():
		return "confirmed"
	return ""


static func _call_contact_state(context: Dictionary, fireteam_id: String, enemy_unit_id: String) -> Dictionary:
	var get_contact_state: Callable = context.get("get_contact_state", Callable())
	if not get_contact_state.is_valid():
		return {}
	return Dictionary(get_contact_state.call(fireteam_id, enemy_unit_id)).duplicate(true)


static func _score_attack_target(attacker, target, context: Dictionary) -> float:
	var score: float = 0.0
	var attack_area_context: Dictionary = _resolve_attack_area_context(attacker, context)
	if not attack_area_context.is_empty() and target is Node2D:
		if bool(AREA_ORDER_RESOLVER_SCRIPT.call("is_position_in_area_context", attack_area_context, (target as Node2D).global_position)):
			score += 10000.0
	if attacker is Node2D and target is Node2D:
		score -= (attacker as Node2D).global_position.distance_to((target as Node2D).global_position) * 0.01
	if target != null and target.has_method("get_unit_id"):
		score -= float(String(target.call("get_unit_id")).hash() & 0xffff) * 0.000001
	return score


static func _resolve_attack_area_context(attacker, context: Dictionary) -> Dictionary:
	if attacker == null:
		return {}
	var friendly_team_id: String = String(context.get("friendly_team_id", "")).strip_edges()
	if not friendly_team_id.is_empty() and _get_team_id(attacker) != friendly_team_id:
		return {}
	var fireteam_id: String = ""
	if attacker.has_method("get_fireteam_id"):
		fireteam_id = String(attacker.call("get_fireteam_id")).strip_edges().to_lower()
	if fireteam_id.is_empty():
		return {}
	var get_attack_area_context: Callable = context.get("get_attack_area_context", Callable())
	if get_attack_area_context.is_valid():
		return Dictionary(get_attack_area_context.call(fireteam_id)).duplicate(true)
	var attack_area_by_fireteam: Dictionary = Dictionary(context.get("attack_area_by_fireteam", {}))
	return Dictionary(attack_area_by_fireteam.get(fireteam_id, {})).duplicate(true)


static func _call_misidentification(context: Dictionary, attacker, attacker_id: String) -> Dictionary:
	var check_misidentification: Callable = context.get("check_misidentification", Callable())
	if not check_misidentification.is_valid():
		return {}
	return Dictionary(check_misidentification.call(attacker, attacker_id)).duplicate(true)


static func _call_flank_resolver(context: Dictionary, attacker, target) -> Dictionary:
	var resolve_flank_attack: Callable = context.get("resolve_flank_attack", Callable())
	if not resolve_flank_attack.is_valid():
		return {}
	return Dictionary(resolve_flank_attack.call(attacker, target)).duplicate(true)
