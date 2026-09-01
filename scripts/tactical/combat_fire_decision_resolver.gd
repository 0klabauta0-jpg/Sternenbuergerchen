class_name CombatFireDecisionResolver
extends RefCounted

const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")
const AREA_ORDER_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/area_order_resolver.gd")


static func find_first_contact_pair(context: Dictionary) -> Dictionary:
	var friendly_units: Array = Array(context.get("friendly_units", []))
	var enemy_units: Array = Array(context.get("enemy_units", []))
	var friendly_team_id: String = String(context.get("friendly_team_id", ""))
	var decision_context: Dictionary = context
	# Only the authoritative driver enables this: its range callback depends on
	# the attacker and terrain scale, not on the candidate target. Other resolver
	# users retain their original target-sensitive callback semantics.
	if bool(context.get("cache_effective_attack_range_by_attacker", false)):
		decision_context = context.duplicate()
		decision_context["precomputed_effective_attack_ranges"] = {}
	for friendly in friendly_units:
		if not _can_unit_seek_target(friendly):
			continue
		var enemy = pick_target_from_units(friendly, _filter_targets_for_attacker(friendly, enemy_units, decision_context), decision_context)
		if enemy == null:
			continue
		var f_id: String = String(friendly.call("get_unit_id"))
		var e_id: String = String(enemy.call("get_unit_id"))
		var start_detection: Callable = decision_context.get("start_detection", Callable())
		if start_detection.is_valid():
			start_detection.call(friendly, f_id, e_id)
		var is_detection_complete: Callable = decision_context.get("is_detection_complete", Callable())
		if is_detection_complete.is_valid() and not bool(is_detection_complete.call(f_id, e_id)):
			continue
		var fireteam_id: String = ""
		if friendly.has_method("get_fireteam_id"):
			fireteam_id = String(friendly.call("get_fireteam_id")).strip_edges().to_lower()
		var contact_entry: Dictionary = _call_contact_state(decision_context, fireteam_id, e_id)
		var detection_state: String = String(contact_entry.get("detection_state", "confirmed")).strip_edges().to_lower()
		if detection_state != "spotted" and detection_state != "confirmed":
			continue
		if not can_unit_attack(friendly, decision_context):
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
		var friendly = pick_target_from_units(enemy, _filter_targets_for_attacker(enemy, friendly_units, decision_context), decision_context)
		if friendly == null:
			continue
		var en_id: String = String(enemy.call("get_unit_id"))
		var fr_id: String = String(friendly.call("get_unit_id"))
		var start_detection_enemy: Callable = decision_context.get("start_detection", Callable())
		if start_detection_enemy.is_valid():
			start_detection_enemy.call(enemy, en_id, fr_id)
		var is_detection_complete_enemy: Callable = decision_context.get("is_detection_complete", Callable())
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
	var team_target_support_percent: float = _get_team_target_support_percent(attacker)
	if absf(team_target_support_percent) > 0.001:
		weapon_hit_chance = clampf(weapon_hit_chance + (team_target_support_percent / 100.0), 0.02, 0.98)
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
			"team_target_support_percent": team_target_support_percent,
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


static func build_cover_effectiveness_readout(attacker, target, context: Dictionary = {}) -> Dictionary:
	var contact_state: String = String(context.get("contact_state", "")).strip_edges().to_lower()
	if bool(context.get("respect_contact_state", not contact_state.is_empty())) and not _contact_state_allows_detail(contact_state):
		return _build_unknown_cover_readout("contact_not_visible", contact_state)
	if attacker == null:
		return _build_unknown_cover_readout("missing_attacker", contact_state)
	if target == null:
		return _build_unknown_cover_readout("missing_target", contact_state)
	var active_weapon_id: String = get_unit_active_weapon_id(attacker)
	if active_weapon_id.is_empty():
		return _build_unknown_cover_readout("no_attack_weapon", contact_state)

	var weapon_range_world: float = _get_weapon_attack_range(attacker, target, context)
	var distance_world: float = _get_node_distance(attacker, target)
	var range_state: String = _resolve_range_state(distance_world, weapon_range_world)
	var los_state: String = _resolve_los_state(attacker, target, context)
	var raw_cover_score: int = _get_target_cover_score(target, context)
	var raw_cover_state: String = _resolve_cover_state(raw_cover_score)
	var flank_preview: Dictionary = _call_flank_preview(context, attacker, target)
	var has_flank_preview: bool = context.get("resolve_flank_attack_preview", Callable()).is_valid()
	var is_flank: bool = bool(flank_preview.get("is_flank", false))
	var effective_cover_score: int = raw_cover_score
	if is_flank and flank_preview.has("target_cover_override"):
		effective_cover_score = int(round(float(flank_preview.get("target_cover_override", raw_cover_score))))
	var effective_cover_state: String = _resolve_cover_state(effective_cover_score)
	var combat_attackable: bool = is_target_attackable(attacker, target, context)
	return {
		"readout_state": "known",
		"source": "CombatFireDecisionResolver",
		"combat_truth_source": "weapon_data_los_system_terrain_registry_flank_preview",
		"read_only": true,
		"ui_may_execute_commands": false,
		"attacker_unit_id": _get_unit_id(attacker),
		"target_unit_id": _get_unit_id(target),
		"contact_state": contact_state,
		"weapon_id": active_weapon_id,
		"weapon_range_world": weapon_range_world,
		"distance_world": distance_world,
		"range_state": range_state,
		"los_state": los_state,
		"raw_cover_score": raw_cover_score,
		"raw_cover_state": raw_cover_state,
		"effective_cover_score": effective_cover_score,
		"effective_cover_state": effective_cover_state,
		"cover_state": effective_cover_state,
		"flank_state": "flank" if is_flank else ("not_flank" if has_flank_preview else "unknown"),
		"flank_relevant": is_flank,
		"flank_direction_label": String(flank_preview.get("direction_label", "")),
		"flank_hit_chance_bonus": float(flank_preview.get("hit_chance_bonus", 0.0)) if is_flank else 0.0,
		"target_cover_override": flank_preview.get("target_cover_override", null) if is_flank else null,
		"combat_attackable": combat_attackable,
		"attack_quality_label": _resolve_attack_quality_label(combat_attackable, range_state, los_state, effective_cover_state, is_flank),
	}


static func build_fire_rule_outcome_diagnostic(unit, context: Dictionary = {}) -> Dictionary:
	var fire_rule: String = _get_unit_fire_rule(unit)
	var fire_status: String = ""
	if unit != null and unit.has_method("get_fire_status"):
		fire_status = String(unit.call("get_fire_status")).strip_edges().to_lower()
	var is_suppress: bool = fire_rule == "suppress"
	var can_attack: bool = bool(context.get("can_attack", false))
	if not context.has("can_attack") and unit != null:
		can_attack = can_unit_attack(unit, context)
	return {
		"schema": "sternenbuergerchen.fire_rule_outcome.v1",
		"source": "CombatFireDecisionResolver",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"fire_rule": fire_rule,
		"fire_status": fire_status,
		"can_attack": can_attack,
		"outcome_scope": "diagnostic_only",
		"outcome_label": "suppress_pressure_intent" if is_suppress else _resolve_fire_rule_outcome_label(fire_rule, fire_status, can_attack),
		"suppress_intent_active": is_suppress,
		"suppress_pressure_intent_visible": is_suppress,
		"suppress_effect_applied": false,
		"suppression_effect_payload_enqueued": false,
		"ammo_consumed": false,
		"suppress_damage_modifier_applied": false,
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
		var fire_rule: String = _get_unit_fire_rule(unit)
		if fire_rule == "return":
			var can_return_fire: Callable = context.get("can_return_fire", Callable())
			if can_return_fire.is_valid() and bool(can_return_fire.call(unit)):
				return true
		if fire_rule == "hold":
			return false
		var discipline_break: Callable = context.get("check_discipline_break", Callable())
		if not discipline_break.is_valid() or not bool(discipline_break.call(unit)):
			return false
	return true


static func _resolve_fire_rule_outcome_label(fire_rule: String, fire_status: String, can_attack: bool) -> String:
	if fire_rule == "hold":
		return "hold_fire"
	if fire_rule == "return":
		return "return_fire_window" if can_attack else "return_fire_wait"
	if fire_rule == "free":
		return "free_fire"
	if fire_status == "fire_at_will":
		return "fire_ready"
	if fire_status == "hold_fire":
		return "fire_held"
	return "unknown"


static func _get_unit_fire_rule(unit) -> String:
	if unit == null or not unit.has_method("get_current_unit_command"):
		return ""
	var command = unit.call("get_current_unit_command")
	if command == null or not command.has_method("get"):
		return ""
	return String(command.get("fire_rule")).strip_edges().to_lower()


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
	var record_target_evaluation: Callable = context.get("record_target_evaluation", Callable())
	for target in targets:
		if record_target_evaluation.is_valid():
			record_target_evaluation.call(attacker, target)
		if not is_target_attackable(attacker, target, context):
			continue
		var score: float = _score_attack_target(attacker, target, context)
		if best_target != null and score <= best_score:
			continue
		best_target = target
		best_score = score
	return best_target

static func _filter_targets_for_attacker(attacker, targets: Array, context: Dictionary) -> Array:
	var debug_enabled: bool = bool(context.get("combat_hotspot_debug_enabled", false))
	var filter_started_usec: int = Time.get_ticks_usec() if debug_enabled else 0
	if not bool(context.get("use_observed_fire_candidate_index", false)):
		if debug_enabled: _record_hotspot(context, "candidate_filter", filter_started_usec)
		return targets
	var attacker_id: String = _get_unit_id(attacker)
	var by_attacker: Dictionary = Dictionary(context.get("observed_target_ids_by_attacker_id", {}))
	if attacker_id.is_empty() or not by_attacker.has(attacker_id):
		if debug_enabled: _record_hotspot(context, "candidate_filter", filter_started_usec)
		return targets
	var allowed_ids := PackedStringArray(by_attacker.get(attacker_id, PackedStringArray()))
	var filtered: Array = []
	for target in targets:
		if allowed_ids.has(_get_unit_id(target)):
			filtered.append(target)
	if debug_enabled:
		_record_hotspot(context, "candidate_filter", filter_started_usec)
	return filtered


static func is_target_attackable(attacker, target, context: Dictionary) -> bool:
	var debug_enabled: bool = bool(context.get("combat_hotspot_debug_enabled", false))
	var started_usec: int = Time.get_ticks_usec() if debug_enabled else 0
	if target == null or not can_target_receive_attack(target):
		if debug_enabled: _record_hotspot(context, "range_attackability", started_usec)
		return false
	if attacker == null:
		if debug_enabled: _record_hotspot(context, "range_attackability", started_usec)
		return false
	if _get_team_id(attacker) == _get_team_id(target):
		if debug_enabled: _record_hotspot(context, "range_attackability", started_usec)
		return false
	var los_system = context.get("los_system", null)
	if los_system == null or not los_system.has_method("has_line_of_sight_between_nodes"):
		if debug_enabled: _record_hotspot(context, "range_attackability", started_usec)
		return false
	var effective_attack_range: float = _get_effective_attack_range(attacker, target, context)
	if debug_enabled:
		_record_hotspot(context, "range_attackability", started_usec)
	var result := _has_tagged_visibility_nodes(los_system, attacker, target, effective_attack_range, context.get("terrain_registry", null), "fire_pair_search")
	return result

static func _record_hotspot(context: Dictionary, name: String, started_usec: int) -> void:
	if not bool(context.get("combat_hotspot_debug_enabled", false)):
		return
	var callback: Callable = context.get("record_combat_hotspot", Callable())
	if callback.is_valid():
		callback.call(name, maxi(0, Time.get_ticks_usec() - started_usec))


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
			return command_type == "move_to_position" and _move_command_can_engage(command)
	if unit.has_method("get_runtime_status"):
		var runtime_status = unit.call("get_runtime_status")
		if runtime_status != null and runtime_status.has_method("get"):
			var status_name: String = String(runtime_status.get("status"))
			if status_name == "engaging" or status_name == "holding":
				return true
			return status_name == "pending_move" and _move_command_can_engage(runtime_status)
	return false


static func _move_command_can_engage(command_state) -> bool:
	if command_state == null or not command_state.has_method("get"):
		return false
	if String(command_state.get("fire_rule")).strip_edges().to_lower() == "return":
		return true
	if String(command_state.get("fire_status")) != "fire_at_will":
		return false
	var source_command_type: String = String(command_state.get("source_command_type")).strip_edges().to_lower()
	return ["move", "engage", "take", "defend", "flank"].has(source_command_type)


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


static func _get_effective_attack_range(attacker, target, context: Dictionary) -> float:
	var attacker_id: String = _get_unit_id(attacker)
	var precomputed_ranges: Dictionary = Dictionary(context.get("precomputed_effective_attack_ranges", {}))
	if not attacker_id.is_empty() and precomputed_ranges.has(attacker_id):
		return maxf(float(precomputed_ranges.get(attacker_id, 0.0)), 0.0)
	var weapon_range: float = _get_weapon_attack_range(attacker, target, context)
	var range_factor: float = _get_engagement_range_factor(attacker)
	var effective_range: float = weapon_range if range_factor <= 0.0 else weapon_range * range_factor
	if bool(context.get("cache_effective_attack_range_by_attacker", false)) and not attacker_id.is_empty():
		precomputed_ranges[attacker_id] = effective_range
	return effective_range


static func _get_engagement_range_factor(unit) -> float:
	if unit == null or not unit.has_method("get_current_unit_command"):
		return 1.0
	var command = unit.call("get_current_unit_command")
	if command == null or not command.has_method("get"):
		return 1.0
	var raw_factor: Variant = command.get("engagement_range_factor")
	if typeof(raw_factor) != TYPE_INT and typeof(raw_factor) != TYPE_FLOAT:
		return 1.0
	return clampf(float(raw_factor), 0.0, 1.0)


static func _get_team_target_support_percent(unit) -> float:
	if unit == null or not unit.has_method("get_current_unit_command"):
		return 0.0
	var command = unit.call("get_current_unit_command")
	if command == null or not command.has_method("get"):
		return 0.0
	var raw_support: Variant = command.get("team_target_support_percent")
	if typeof(raw_support) != TYPE_INT and typeof(raw_support) != TYPE_FLOAT:
		return 0.0
	return clampf(float(raw_support), -12.0, 22.0)


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


static func _call_flank_preview(context: Dictionary, attacker, target) -> Dictionary:
	var resolve_flank_attack_preview: Callable = context.get("resolve_flank_attack_preview", Callable())
	if not resolve_flank_attack_preview.is_valid():
		return {}
	return Dictionary(resolve_flank_attack_preview.call(attacker, target)).duplicate(true)


static func _contact_state_allows_detail(contact_state: String) -> bool:
	var normalized_state: String = contact_state.strip_edges().to_lower()
	return normalized_state.is_empty() or normalized_state == "spotted" or normalized_state == "confirmed"


static func _build_unknown_cover_readout(reason: String, contact_state: String = "") -> Dictionary:
	return {
		"readout_state": "unknown",
		"reason": reason,
		"source": "CombatFireDecisionResolver",
		"combat_truth_source": "hidden_or_missing_input",
		"read_only": true,
		"ui_may_execute_commands": false,
		"contact_state": contact_state,
		"range_state": "unknown",
		"los_state": "unknown",
		"cover_state": "unknown",
		"raw_cover_state": "unknown",
		"effective_cover_state": "unknown",
		"flank_state": "unknown",
		"flank_relevant": false,
		"combat_attackable": false,
		"attack_quality_label": "unknown",
	}


static func _get_node_distance(attacker, target) -> float:
	if attacker is Node2D and target is Node2D:
		return (attacker as Node2D).global_position.distance_to((target as Node2D).global_position)
	return -1.0


static func _resolve_range_state(distance_world: float, weapon_range_world: float) -> String:
	if distance_world < 0.0 or weapon_range_world <= 0.0:
		return "unknown"
	return "in_range" if distance_world <= weapon_range_world else "out_of_range"


static func _resolve_los_state(attacker, target, context: Dictionary) -> String:
	if not (attacker is Node2D) or not (target is Node2D):
		return "unknown"
	var los_system = context.get("los_system", null)
	if los_system == null or not los_system.has_method("has_line_of_sight_between_nodes"):
		return "unknown"
	var terrain_registry = context.get("terrain_registry", null)
	return "clear" if _has_tagged_visibility_nodes(los_system, attacker, target, -1.0, terrain_registry, "other_combat") else "blocked"

static func _has_tagged_visibility_nodes(los_system, attacker, target, max_range: float, terrain_registry, consumer_tag: String) -> bool:
	if los_system.has_method("get_task1206_analysis_snapshot"):
		return bool(los_system.call("has_line_of_sight_between_nodes", attacker, target, max_range, terrain_registry, Callable(), consumer_tag))
	return bool(los_system.call("has_line_of_sight_between_nodes", attacker, target, max_range, terrain_registry))


static func _get_target_cover_score(target, context: Dictionary) -> int:
	if target != null and target.has_method("get_effective_cover_score"):
		return clampi(int(target.call("get_effective_cover_score")), 0, 100)
	if target is Node2D:
		var terrain_registry = context.get("terrain_registry", null)
		if terrain_registry != null and terrain_registry.has_method("get_cover_at_world"):
			return clampi(int(terrain_registry.call("get_cover_at_world", (target as Node2D).global_position)), 0, 100)
	return -1


static func _resolve_cover_state(cover_score: int) -> String:
	if cover_score < 0:
		return "unknown"
	if cover_score >= 70:
		return "full_cover"
	if cover_score >= 35:
		return "partial_cover"
	if cover_score > 0:
		return "light_cover"
	return "no_cover"


static func _resolve_attack_quality_label(combat_attackable: bool, range_state: String, los_state: String, cover_state: String, is_flank: bool) -> String:
	if range_state == "out_of_range":
		return "out_of_range"
	if los_state == "blocked":
		return "no_los"
	if not combat_attackable:
		return "not_attackable"
	if is_flank:
		return "flank_opportunity"
	if cover_state == "full_cover":
		return "hard_cover"
	if cover_state == "partial_cover" or cover_state == "light_cover":
		return "covered"
	return "open"


static func _get_unit_id(unit) -> String:
	if unit != null and unit.has_method("get_unit_id"):
		return String(unit.call("get_unit_id")).strip_edges()
	return ""
