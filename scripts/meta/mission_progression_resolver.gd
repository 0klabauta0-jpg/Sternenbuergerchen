class_name MissionProgressionResolver
extends RefCounted

const FIRETEAM_COHESION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/fireteam_cohesion_resolver.gd")
const ROSTER_RELATIONSHIP_MODEL_SCRIPT: GDScript = preload("res://scripts/meta/roster_relationship_model.gd")
const NPC_RANK_BADGE_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/npc_rank_badge_resolver.gd")
const FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_behavior_resolver.gd")

const PROGRESSION_SCHEMA_VERSION: int = 1
const MAX_MISSION_HISTORY_ENTRIES: int = 12
const MAX_CHARACTER_EVENTS: int = 5
const MIN_CHARACTER_EVENTS: int = 2
const MAX_XP_PER_MISSION: int = 8
const MAX_SKILL_VALUE: float = 0.95
const MAX_SKILL_GAIN_PER_MISSION: float = 0.018
const MAX_FTL_TACTICAL_GAIN_PER_MISSION: float = 0.014
const MAX_RELATIONSHIP_DRIFT_PER_MISSION: float = 0.035
const AWARD_SUMMARY_SCHEMA: String = "sternenbuergerchen.skill_progress_award_summary.v1"


static func apply_mission_result(roster: Dictionary, mission_result: Dictionary, options: Dictionary = {}) -> Dictionary:
	var updated_roster: Dictionary = roster.duplicate(true)
	var source_units: Array = Array(updated_roster.get("units", []))
	var units_by_id: Dictionary = {}
	var ordered_unit_ids: PackedStringArray = PackedStringArray()
	for unit_variant in source_units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(unit_variant).duplicate(true)
		var unit_id: String = _normalize_unit_id(String(unit.get("unit_id", "")))
		if unit_id.is_empty():
			continue
		ordered_unit_ids.append(unit_id)
		units_by_id[unit_id] = unit

	var selected_unit_ids: PackedStringArray = _build_selected_unit_ids(mission_result)
	var selected_fireteam_ids: PackedStringArray = _coerce_string_array(mission_result.get("selected_fireteam_ids", PackedStringArray()), false)
	var team_states_by_id: Dictionary = _build_team_states_by_id(mission_result)
	var unit_events_by_id: Dictionary = _build_unit_events_by_id(mission_result)
	var mission_context: Dictionary = _build_mission_context(mission_result, options)
	var fireteam_groups: Dictionary = _build_fireteam_groups(units_by_id, selected_unit_ids, selected_fireteam_ids, team_states_by_id)
	var cohesion_by_fireteam: Dictionary = _build_cohesion_by_fireteam(fireteam_groups)
	var unit_updates: Array = []
	var character_events: Array = []
	var updated_selected_ids: Dictionary = {}

	for unit_id in selected_unit_ids:
		var normalized_unit_id: String = _normalize_unit_id(unit_id)
		if normalized_unit_id.is_empty() or not units_by_id.has(normalized_unit_id):
			continue
		var unit: Dictionary = Dictionary(units_by_id.get(normalized_unit_id, {})).duplicate(true)
		var unit_event: Dictionary = Dictionary(unit_events_by_id.get(normalized_unit_id, {})).duplicate(true)
		var team_state: Dictionary = Dictionary(team_states_by_id.get(normalized_unit_id, {})).duplicate(true)
		var fireteam_id: String = _resolve_unit_fireteam_id(unit, normalized_unit_id, selected_unit_ids, selected_fireteam_ids, team_state)
		var cohesion_snapshot: Dictionary = Dictionary(cohesion_by_fireteam.get(fireteam_id, {})).duplicate(true)
		var update_result: Dictionary = _apply_deployed_unit_progression(unit, mission_context, unit_event, team_state, fireteam_id, cohesion_snapshot)
		var updated_unit: Dictionary = Dictionary(update_result.get("unit", unit)).duplicate(true)
		units_by_id[normalized_unit_id] = updated_unit
		updated_selected_ids[normalized_unit_id] = true
		unit_updates.append(Dictionary(update_result.get("update", {})).duplicate(true))
		character_events.append_array(Array(update_result.get("events", [])))

	if bool(options.get("include_reserve_tick", false)):
		for unit_id in ordered_unit_ids:
			if updated_selected_ids.has(unit_id):
				continue
			var reserve_update: Dictionary = _apply_reserve_progression(Dictionary(units_by_id.get(unit_id, {})).duplicate(true), mission_context)
			units_by_id[unit_id] = Dictionary(reserve_update.get("unit", units_by_id.get(unit_id, {}))).duplicate(true)
			if not Dictionary(reserve_update.get("update", {})).is_empty():
				unit_updates.append(Dictionary(reserve_update.get("update", {})).duplicate(true))
			character_events.append_array(Array(reserve_update.get("events", [])))

	_apply_relationship_drift(units_by_id, fireteam_groups, mission_context, team_states_by_id, cohesion_by_fireteam)

	var updated_units: Array = []
	for unit_id in ordered_unit_ids:
		var updated_unit: Dictionary = Dictionary(units_by_id.get(unit_id, {})).duplicate(true)
		updated_unit["rank_badges"] = NPC_RANK_BADGE_RESOLVER_SCRIPT.call("derive_badges", updated_unit)
		updated_units.append(updated_unit)

	updated_roster["units"] = updated_units
	updated_roster["progression_schema_version"] = PROGRESSION_SCHEMA_VERSION
	updated_roster["last_progression_result"] = {
		"mission_id": String(mission_context.get("mission_id", "")),
		"mission_outcome": String(mission_context.get("mission_outcome", "")),
		"unit_update_count": unit_updates.size(),
	}
	var relationship_validation: Dictionary = Dictionary(ROSTER_RELATIONSHIP_MODEL_SCRIPT.call("validate_roster_relationships", updated_units, Array(updated_roster.get("relationship_pairs", []))))
	updated_roster["relationship_validation"] = relationship_validation

	var debrief_events: Array = build_debrief_events(character_events, unit_updates)
	var progression_summary: Dictionary = {
		"mission_id": String(mission_context.get("mission_id", "")),
		"mission_outcome": String(mission_context.get("mission_outcome", "")),
		"updated_unit_count": unit_updates.size(),
		"character_event_count": debrief_events.size(),
		"progression_schema_version": PROGRESSION_SCHEMA_VERSION,
	}
	return {
		"updated_roster": updated_roster,
		"unit_updates": unit_updates,
		"character_events": debrief_events,
		"all_character_events": character_events,
		"fireteam_cohesion": cohesion_by_fireteam,
		"summary": progression_summary,
		"award_summary": build_award_summary(unit_updates, progression_summary),
	}


static func build_award_summary(unit_updates: Array, progression_summary: Dictionary = {}) -> Dictionary:
	var awards: Array = []
	var total_xp_delta: int = 0
	var skill_gain_count: int = 0
	var ftl_tactical_gain_count: int = 0
	var recovery_count: int = 0
	var objective_award_count: int = 0
	var morale_delta_total: float = 0.0
	var frustration_delta_total: float = 0.0
	for update_variant in unit_updates:
		if typeof(update_variant) != TYPE_DICTIONARY:
			continue
		var update: Dictionary = Dictionary(update_variant)
		var xp_delta: int = clampi(int(update.get("xp_delta", 0)), 0, MAX_XP_PER_MISSION)
		var skill_gains: Dictionary = Dictionary(update.get("skill_gains", {}))
		var skill_keys: PackedStringArray = PackedStringArray()
		for skill_key_variant in skill_gains.keys():
			var skill_key: String = String(skill_key_variant).strip_edges()
			if skill_key.is_empty() or float(skill_gains.get(skill_key_variant, 0.0)) <= 0.0:
				continue
			skill_keys.append(skill_key)
		var ftl_gain: float = clampf(float(update.get("ftl_tactical_gain", 0.0)), 0.0, MAX_FTL_TACTICAL_GAIN_PER_MISSION)
		total_xp_delta += xp_delta
		skill_gain_count += skill_keys.size()
		if ftl_gain > 0.0:
			ftl_tactical_gain_count += 1
		if bool(update.get("downed", false)):
			recovery_count += 1
		if bool(update.get("objective_participation", false)):
			objective_award_count += 1
		morale_delta_total += float(update.get("morale_delta", 0.0))
		frustration_delta_total += float(update.get("frustration_delta", 0.0))
		if awards.size() < MAX_CHARACTER_EVENTS:
			awards.append({
				"unit_id": String(update.get("unit_id", "")).strip_edges(),
				"display_name": String(update.get("display_name", update.get("unit_id", "Operator"))).strip_edges(),
				"fireteam_id": String(update.get("fireteam_id", "")).strip_edges(),
				"xp_delta": xp_delta,
				"skill_keys": skill_keys,
				"skill_gain_count": skill_keys.size(),
				"ftl_tactical_gain": ftl_gain,
				"downed": bool(update.get("downed", false)),
				"objective_participation": bool(update.get("objective_participation", false)),
				"read_only": true,
			})
	var award_text: String = "Awards: XP +%d | Skill %d | FTL %d | Recovery %d" % [
		total_xp_delta,
		skill_gain_count,
		ftl_tactical_gain_count,
		recovery_count,
	]
	return {
		"schema": AWARD_SUMMARY_SCHEMA,
		"authority": "MissionProgressionResolver",
		"source": "progression_unit_updates",
		"mission_id": String(progression_summary.get("mission_id", "")),
		"mission_outcome": String(progression_summary.get("mission_outcome", "")),
		"progression_schema_version": PROGRESSION_SCHEMA_VERSION,
		"unit_award_count": unit_updates.size(),
		"listed_awards": awards,
		"listed_award_count": awards.size(),
		"total_xp_delta": total_xp_delta,
		"skill_gain_count": skill_gain_count,
		"ftl_tactical_gain_count": ftl_tactical_gain_count,
		"recovery_count": recovery_count,
		"objective_award_count": objective_award_count,
		"morale_delta_total": snappedf(morale_delta_total, 0.001),
		"frustration_delta_total": snappedf(frustration_delta_total, 0.001),
		"max_xp_per_unit": MAX_XP_PER_MISSION,
		"max_skill_gain_per_mission": MAX_SKILL_GAIN_PER_MISSION,
		"max_ftl_tactical_gain_per_mission": MAX_FTL_TACTICAL_GAIN_PER_MISSION,
		"award_text": award_text,
		"award_applied": true,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func build_debrief_events(character_events: Array, unit_updates: Array = []) -> Array:
	var events: Array = []
	for event_variant in character_events:
		if typeof(event_variant) == TYPE_DICTIONARY:
			events.append(Dictionary(event_variant).duplicate(true))
	if events.size() < MIN_CHARACTER_EVENTS:
		var existing_ids: Dictionary = {}
		for event_variant in events:
			existing_ids[String(Dictionary(event_variant).get("unit_id", ""))] = true
		for update_variant in unit_updates:
			if typeof(update_variant) != TYPE_DICTIONARY:
				continue
			var update: Dictionary = Dictionary(update_variant)
			var unit_id: String = String(update.get("unit_id", "")).strip_edges()
			if unit_id.is_empty() or existing_ids.has(unit_id):
				continue
			events.append(_make_character_event(update, "progress", 20))
			existing_ids[unit_id] = true
			if events.size() >= MIN_CHARACTER_EVENTS:
				break
	events.sort_custom(func(a, b):
		var left: Dictionary = Dictionary(a)
		var right: Dictionary = Dictionary(b)
		if int(left.get("priority", 0)) == int(right.get("priority", 0)):
			return String(left.get("unit_id", "")) < String(right.get("unit_id", ""))
		return int(left.get("priority", 0)) > int(right.get("priority", 0))
	)
	var result: Array = []
	for index in range(mini(MAX_CHARACTER_EVENTS, events.size())):
		result.append(Dictionary(events[index]).duplicate(true))
	return result


static func _apply_deployed_unit_progression(unit: Dictionary, mission_context: Dictionary, unit_event: Dictionary, team_state: Dictionary, fireteam_id: String, cohesion_snapshot: Dictionary) -> Dictionary:
	var updated_unit: Dictionary = unit.duplicate(true)
	var progression: Dictionary = _normalize_progression(Dictionary(updated_unit.get("progression", {})))
	var skill_values: Dictionary = Dictionary(updated_unit.get("skill_values", {})).duplicate(true)
	var previous_morale: float = float(progression.get("morale", 0.50))
	var previous_frustration: float = float(progression.get("frustration", 0.0))
	var is_success: bool = bool(mission_context.get("success", false))
	var is_downed: bool = _is_unit_downed(unit_event, team_state)
	var was_healed: bool = bool(unit_event.get("healed", false)) or bool(unit_event.get("medic_action_received", false))
	var fired_weapon: bool = bool(unit_event.get("fired_weapon", false))
	var medic_action: bool = bool(unit_event.get("medic_action", false))
	var pilot_action: bool = bool(unit_event.get("pilot_action", false))
	var engineer_action: bool = bool(unit_event.get("engineer_action", false))
	var objective_participation: bool = bool(unit_event.get("objective_participation", false))
	var role_mismatch: bool = bool(unit_event.get("role_mismatch", false))

	var xp_delta: int = 2
	if not is_downed:
		xp_delta += 1
	if is_success:
		xp_delta += 1
	if objective_participation:
		xp_delta += 2
	if fired_weapon:
		xp_delta += 1
	if medic_action or pilot_action or engineer_action:
		xp_delta += 2
	if was_healed:
		xp_delta += 1
	if is_downed:
		xp_delta += 1
	xp_delta = clampi(xp_delta, 1, MAX_XP_PER_MISSION)

	var skill_gains: Dictionary = _build_skill_gains(unit, unit_event, xp_delta, is_success, is_downed)
	for skill_key in skill_gains.keys():
		skill_values[skill_key] = clampf(float(skill_values.get(skill_key, 0.50)) + float(skill_gains.get(skill_key, 0.0)), 0.0, MAX_SKILL_VALUE)

	var morale_delta: float = 0.010 if is_success else -0.012
	if objective_participation:
		morale_delta += 0.015
	if was_healed:
		morale_delta += 0.010
	if is_downed:
		morale_delta -= 0.040
	morale_delta += float(Dictionary(cohesion_snapshot.get("gameplay_modifiers", {})).get("morale_delta", 0.0))
	morale_delta = clampf(morale_delta, -0.060, 0.060)

	var frustration_delta: float = -0.012 if is_success else 0.012
	if role_mismatch:
		frustration_delta += 0.025
	if is_downed:
		frustration_delta += 0.040
	var coordination_modifier: float = float(Dictionary(cohesion_snapshot.get("gameplay_modifiers", {})).get("coordination_modifier", 0.0))
	if coordination_modifier < 0.0:
		frustration_delta += absf(coordination_modifier) * 0.60
	frustration_delta = clampf(frustration_delta, -0.035, 0.075)

	progression["xp"] = clampi(int(progression.get("xp", 0)) + xp_delta, 0, 999)
	progression["missions_completed"] = int(progression.get("missions_completed", 0)) + 1
	progression["morale"] = clampf(previous_morale + morale_delta, 0.0, 1.0)
	progression["frustration"] = clampf(previous_frustration + frustration_delta, 0.0, 1.0)
	progression["skill_progress"] = _merge_skill_progress(Dictionary(progression.get("skill_progress", {})), skill_gains)
	progression["role_progress"] = _merge_role_progress(Dictionary(progression.get("role_progress", {})), updated_unit, xp_delta)
	var fireteam_cohesion_by_id: Dictionary = Dictionary(progression.get("fireteam_cohesion_by_id", {})).duplicate(true)
	if not fireteam_id.is_empty():
		fireteam_cohesion_by_id[fireteam_id] = clampf(float(cohesion_snapshot.get("cohesion", fireteam_cohesion_by_id.get(fireteam_id, 0.50))) + morale_delta * 0.30 - maxf(frustration_delta, 0.0) * 0.20, 0.0, 1.0)
	progression["fireteam_cohesion_by_id"] = fireteam_cohesion_by_id
	var ftl_progression_result: Dictionary = _apply_ftl_tactical_progression(updated_unit, progression, skill_values, mission_context, unit_event, fireteam_id, cohesion_snapshot, morale_delta, frustration_delta, is_success, is_downed, role_mismatch)
	if not ftl_progression_result.is_empty():
		progression["ftl_tactical"] = Dictionary(ftl_progression_result.get("ftl_tactical", {})).duplicate(true)
		progression["ftl_tactical_snapshot"] = Dictionary(ftl_progression_result.get("snapshot", {})).duplicate(true)
		updated_unit["ftl_tactical_progression"] = Dictionary(ftl_progression_result.get("snapshot", {})).duplicate(true)
		updated_unit["ftl_tactical_effect_text"] = String(ftl_progression_result.get("effect_text", "")).strip_edges()

	var mission_entry: Dictionary = {
		"mission_id": String(mission_context.get("mission_id", "")),
		"result": String(mission_context.get("mission_outcome", "ended")),
		"fireteam_id": fireteam_id,
		"xp_delta": xp_delta,
		"morale_delta": morale_delta,
		"frustration_delta": frustration_delta,
		"downed": is_downed,
		"healed": was_healed,
		"objective_participation": objective_participation,
	}
	updated_unit["mission_history"] = _append_limited_history(Array(updated_unit.get("mission_history", [])), mission_entry)
	if not fireteam_id.is_empty():
		updated_unit["fireteam_history"] = _append_limited_history(Array(updated_unit.get("fireteam_history", [])), {
			"fireteam_id": fireteam_id,
			"mission_id": String(mission_context.get("mission_id", "")),
			"result": String(mission_context.get("mission_outcome", "ended")),
			"cohesion": float(cohesion_snapshot.get("cohesion", 0.0)),
		})
	updated_unit["progression"] = progression
	updated_unit["skill_values"] = skill_values
	updated_unit["availability_status"] = "recovering" if is_downed else String(updated_unit.get("availability_status", "active"))
	if is_downed:
		updated_unit["recovery_state"] = {"state": "recovering", "turns_remaining": 2, "source": "mission_progression"}
		updated_unit["status_text"] = "recovering"

	var update: Dictionary = {
		"unit_id": String(updated_unit.get("unit_id", "")),
		"display_name": String(updated_unit.get("display_name", updated_unit.get("unit_id", ""))),
		"fireteam_id": fireteam_id,
		"xp_delta": xp_delta,
		"morale_delta": morale_delta,
		"frustration_delta": frustration_delta,
		"skill_gains": skill_gains,
		"downed": is_downed,
		"healed": was_healed,
		"objective_participation": objective_participation,
		"role_mismatch": role_mismatch,
	}
	if not ftl_progression_result.is_empty():
		update["ftl_tactical_gain"] = float(ftl_progression_result.get("gain", 0.0))
		update["ftl_tactical_effect_text"] = String(ftl_progression_result.get("effect_text", "")).strip_edges()
	return {
		"unit": updated_unit,
		"update": update,
		"events": _build_character_events_for_update(update),
	}


static func _apply_ftl_tactical_progression(
	unit: Dictionary,
	progression: Dictionary,
	skill_values: Dictionary,
	mission_context: Dictionary,
	unit_event: Dictionary,
	fireteam_id: String,
	cohesion_snapshot: Dictionary,
	morale_delta: float,
	frustration_delta: float,
	is_success: bool,
	is_downed: bool,
	role_mismatch: bool
) -> Dictionary:
	var is_ftl_context: bool = (
		bool(unit.get("is_fireteam_lead", false))
		or bool(unit_event.get("issued_orders", false))
		or bool(unit_event.get("coordinated_plan", false))
		or bool(unit_event.get("contact_report", false))
		or bool(unit_event.get("breakout_decision", false))
	)
	if not is_ftl_context:
		return {}
	var ftl_progression: Dictionary = Dictionary(progression.get("ftl_tactical", {})).duplicate(true)
	var current_tactical_sense: float = clampf(float(ftl_progression.get("tactical_sense", (float(skill_values.get("leadership", 0.35)) * 0.45) + (float(skill_values.get("recognition", skill_values.get("awareness", 0.45))) * 0.30) + (float(skill_values.get("discipline", 0.45)) * 0.25))), 0.0, MAX_SKILL_VALUE)
	var current_communication: float = clampf(float(ftl_progression.get("communication", float(skill_values.get("leadership", 0.35)))), 0.0, MAX_SKILL_VALUE)
	var current_discipline: float = clampf(float(ftl_progression.get("discipline", float(skill_values.get("discipline", 0.45)))), 0.0, MAX_SKILL_VALUE)
	var current_initiative: float = clampf(float(ftl_progression.get("initiative", float(skill_values.get("speed", 0.45)))), 0.0, MAX_SKILL_VALUE)
	var current_team_cohesion: float = clampf(float(ftl_progression.get("team_cohesion", cohesion_snapshot.get("cohesion", 0.50))), 0.0, MAX_SKILL_VALUE)
	var base_gain: float = 0.0035
	if bool(unit_event.get("objective_participation", false)):
		base_gain += 0.0015
	if bool(unit_event.get("coordinated_plan", false)):
		base_gain += 0.0020
	if bool(unit_event.get("contact_report", false)):
		base_gain += 0.0013
	if bool(unit_event.get("breakout_decision", false)):
		base_gain += 0.0015
	if bool(unit_event.get("issued_orders", false)) or bool(unit.get("is_fireteam_lead", false)):
		base_gain += 0.0010
	if is_success:
		base_gain += 0.0010
	if is_downed:
		base_gain -= 0.0025
	if role_mismatch:
		base_gain -= 0.0018
	var cohesion_value: float = clampf(float(cohesion_snapshot.get("cohesion", 0.50)), 0.0, 1.0)
	base_gain += (cohesion_value - 0.50) * 0.004
	base_gain += morale_delta * 0.12
	base_gain -= maxf(frustration_delta, 0.0) * 0.14
	var gain: float = clampf(base_gain, 0.0, MAX_FTL_TACTICAL_GAIN_PER_MISSION)
	ftl_progression["schema_version"] = 1
	ftl_progression["missions_led"] = maxi(int(ftl_progression.get("missions_led", 0)), 0) + 1
	ftl_progression["tactical_sense"] = clampf(current_tactical_sense + (gain * 0.46), 0.0, MAX_SKILL_VALUE)
	ftl_progression["communication"] = clampf(current_communication + (gain * 0.36), 0.0, MAX_SKILL_VALUE)
	ftl_progression["discipline"] = clampf(current_discipline + (gain * 0.26), 0.0, MAX_SKILL_VALUE)
	ftl_progression["initiative"] = clampf(current_initiative + (gain * 0.22), 0.0, MAX_SKILL_VALUE)
	ftl_progression["team_cohesion"] = clampf(current_team_cohesion + (gain * 0.30) + (morale_delta * 0.12) - (maxf(frustration_delta, 0.0) * 0.08), 0.0, MAX_SKILL_VALUE)
	ftl_progression["last_gain"] = gain
	ftl_progression["last_mission_id"] = String(mission_context.get("mission_id", "")).strip_edges()
	ftl_progression["last_gain_sources"] = _build_ftl_gain_sources(unit_event, is_success, is_downed, role_mismatch)
	var leader_data: Dictionary = unit.duplicate(true)
	leader_data["skill_values"] = skill_values.duplicate(true)
	var leader_progression: Dictionary = progression.duplicate(true)
	leader_progression["ftl_tactical"] = ftl_progression.duplicate(true)
	leader_data["progression"] = leader_progression
	var snapshot: Dictionary = FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("build_leader_tactical_skill_snapshot", leader_data, {
		"fireteam_id": fireteam_id,
		"cohesion": cohesion_value,
		"morale": float(progression.get("morale", 0.50)),
		"frustration": float(progression.get("frustration", 0.0)),
	})
	return {
		"ftl_tactical": ftl_progression,
		"snapshot": snapshot,
		"effect_text": String(snapshot.get("effect_text", "")),
		"gain": gain,
	}


static func _build_ftl_gain_sources(unit_event: Dictionary, is_success: bool, is_downed: bool, role_mismatch: bool) -> PackedStringArray:
	var sources: PackedStringArray = PackedStringArray()
	if bool(unit_event.get("issued_orders", false)):
		sources.append("issued_orders")
	if bool(unit_event.get("coordinated_plan", false)):
		sources.append("coordinated_plan")
	if bool(unit_event.get("contact_report", false)):
		sources.append("contact_report")
	if bool(unit_event.get("breakout_decision", false)):
		sources.append("breakout_decision")
	if is_success:
		sources.append("success")
	if is_downed:
		sources.append("downed_penalty")
	if role_mismatch:
		sources.append("role_mismatch_penalty")
	return sources


static func _apply_reserve_progression(unit: Dictionary, mission_context: Dictionary) -> Dictionary:
	var updated_unit: Dictionary = unit.duplicate(true)
	var progression: Dictionary = _normalize_progression(Dictionary(updated_unit.get("progression", {})))
	var previous_frustration: float = float(progression.get("frustration", 0.0))
	var frustration_delta: float = 0.008
	progression["frustration"] = clampf(previous_frustration + frustration_delta, 0.0, 1.0)
	updated_unit["progression"] = progression
	var update: Dictionary = {
		"unit_id": String(updated_unit.get("unit_id", "")),
		"display_name": String(updated_unit.get("display_name", updated_unit.get("unit_id", ""))),
		"fireteam_id": String(updated_unit.get("fireteam_id", "")),
		"xp_delta": 0,
		"morale_delta": 0.0,
		"frustration_delta": frustration_delta,
		"skill_gains": {},
		"reserve": true,
	}
	return {
		"unit": updated_unit,
		"update": update,
		"events": [_make_character_event(update, "reserve", 10)] if bool(mission_context.get("report_reserve_events", false)) else [],
	}


static func _build_character_events_for_update(update: Dictionary) -> Array:
	var events: Array = []
	if bool(update.get("downed", false)):
		events.append(_make_character_event(update, "recovery", 100))
	if bool(update.get("objective_participation", false)):
		events.append(_make_character_event(update, "objective", 80))
	if float(update.get("frustration_delta", 0.0)) >= 0.025:
		events.append(_make_character_event(update, "frustration", 70))
	if int(update.get("xp_delta", 0)) >= 5:
		events.append(_make_character_event(update, "progress", 60))
	if float(update.get("ftl_tactical_gain", 0.0)) >= 0.003:
		events.append(_make_character_event(update, "ftl_tactical_progression", 65))
	if float(update.get("morale_delta", 0.0)) >= 0.020:
		events.append(_make_character_event(update, "morale", 50))
	return events


static func _make_character_event(update: Dictionary, event_type: String, priority: int) -> Dictionary:
	var display_name: String = String(update.get("display_name", update.get("unit_id", "Operator"))).strip_edges()
	var xp_delta: int = int(update.get("xp_delta", 0))
	var morale_delta: float = float(update.get("morale_delta", 0.0))
	var frustration_delta: float = float(update.get("frustration_delta", 0.0))
	var summary_text: String = "%s: +%d XP | morale %+.2f | frustration %+.2f" % [display_name, xp_delta, morale_delta, frustration_delta]
	match event_type:
		"recovery":
			summary_text = "%s is recovering after going down. +%d XP | frustration %+.2f" % [display_name, xp_delta, frustration_delta]
		"objective":
			summary_text = "%s helped the objective. +%d XP | morale %+.2f" % [display_name, xp_delta, morale_delta]
		"frustration":
			summary_text = "%s felt the strain. frustration %+.2f | morale %+.2f" % [display_name, frustration_delta, morale_delta]
		"morale":
			summary_text = "%s gained confidence. morale %+.2f | +%d XP" % [display_name, morale_delta, xp_delta]
		"reserve":
			summary_text = "%s stayed in reserve. frustration %+.2f" % [display_name, frustration_delta]
		"ftl_tactical_progression":
			summary_text = "%s sharpened fireteam leadership. %s | gain %.3f" % [display_name, String(update.get("ftl_tactical_effect_text", "FTL impact updated")), float(update.get("ftl_tactical_gain", 0.0))]
	return {
		"unit_id": String(update.get("unit_id", "")).strip_edges(),
		"display_name": display_name,
		"event_type": event_type,
		"priority": priority,
		"xp_delta": xp_delta,
		"morale_delta": morale_delta,
		"frustration_delta": frustration_delta,
		"summary_text": summary_text,
	}


static func _build_skill_gains(unit: Dictionary, unit_event: Dictionary, xp_delta: int, is_success: bool, is_downed: bool) -> Dictionary:
	var gains: Dictionary = {}
	var base_gain: float = minf(float(xp_delta) * 0.0015, MAX_SKILL_GAIN_PER_MISSION)
	if bool(unit_event.get("fired_weapon", false)):
		gains["accuracy"] = base_gain + 0.003
	if bool(unit_event.get("objective_participation", false)) or bool(unit.get("is_fireteam_lead", false)):
		gains["leadership"] = base_gain + (0.003 if is_success else 0.001)
	if bool(unit_event.get("medic_action", false)) or is_downed:
		gains["toughness"] = base_gain + 0.002
	if bool(unit_event.get("pilot_action", false)) or bool(unit_event.get("engineer_action", false)):
		gains["awareness"] = base_gain + 0.002
	for key in gains.keys():
		gains[key] = minf(float(gains.get(key, 0.0)), MAX_SKILL_GAIN_PER_MISSION)
	return gains


static func _apply_relationship_drift(units_by_id: Dictionary, fireteam_groups: Dictionary, mission_context: Dictionary, team_states_by_id: Dictionary, cohesion_by_fireteam: Dictionary) -> void:
	var is_success: bool = bool(mission_context.get("success", false))
	for fireteam_id_variant in fireteam_groups.keys():
		var fireteam_id: String = String(fireteam_id_variant)
		var member_ids: PackedStringArray = _as_packed_string_array(fireteam_groups.get(fireteam_id, PackedStringArray()))
		if member_ids.size() < 2:
			continue
		var cohesion_snapshot: Dictionary = Dictionary(cohesion_by_fireteam.get(fireteam_id, {}))
		var coordination_modifier: float = float(Dictionary(cohesion_snapshot.get("gameplay_modifiers", {})).get("coordination_modifier", 0.0))
		for first_index in range(member_ids.size()):
			for second_index in range(first_index + 1, member_ids.size()):
				var first_id: String = _normalize_unit_id(String(member_ids[first_index]))
				var second_id: String = _normalize_unit_id(String(member_ids[second_index]))
				var drift: float = 0.014 if is_success else -0.010
				if coordination_modifier < 0.0:
					drift += coordination_modifier * 0.40
				if _is_unit_downed({}, Dictionary(team_states_by_id.get(first_id, {}))) or _is_unit_downed({}, Dictionary(team_states_by_id.get(second_id, {}))):
					drift -= 0.010
				drift = clampf(drift, -MAX_RELATIONSHIP_DRIFT_PER_MISSION, MAX_RELATIONSHIP_DRIFT_PER_MISSION)
				_adjust_relationship_link(units_by_id, first_id, second_id, drift, fireteam_id)
				_adjust_relationship_link(units_by_id, second_id, first_id, drift, fireteam_id)


static func _adjust_relationship_link(units_by_id: Dictionary, source_id: String, target_id: String, drift: float, fireteam_id: String) -> void:
	if not units_by_id.has(source_id) or not units_by_id.has(target_id):
		return
	var source: Dictionary = Dictionary(units_by_id.get(source_id, {})).duplicate(true)
	var target: Dictionary = Dictionary(units_by_id.get(target_id, {}))
	var links: Array = Array(source.get("relationship_links", [])).duplicate(true)
	var found: bool = false
	for index in range(links.size()):
		if typeof(links[index]) != TYPE_DICTIONARY:
			continue
		var link: Dictionary = Dictionary(links[index]).duplicate(true)
		if _normalize_unit_id(String(link.get("target_unit_id", ""))) != target_id:
			continue
		var next_affinity: float = clampf(float(link.get("affinity", 0.0)) + drift, -1.0, 1.0)
		link["affinity"] = next_affinity
		link["affinity_score"] = int(round(next_affinity * 100.0))
		link["reason"] = "mission_progression:%s" % fireteam_id
		links[index] = link
		found = true
		break
	if not found:
		var tags: Array = ["trusts"] if drift >= 0.0 else ["tension"]
		links.append(ROSTER_RELATIONSHIP_MODEL_SCRIPT.call("normalize_link", {
			"target_unit_id": target_id,
			"target_name": String(target.get("display_name", target_id)),
			"affinity": drift,
			"tags": tags,
			"reason": "mission_progression:%s" % fireteam_id,
		}))
	source["relationship_links"] = ROSTER_RELATIONSHIP_MODEL_SCRIPT.call("normalize_links_for_unit", source)
	source["relationship_summary_text"] = ROSTER_RELATIONSHIP_MODEL_SCRIPT.call("build_unit_relationship_summary_text", source)
	units_by_id[source_id] = source


static func _build_cohesion_by_fireteam(fireteam_groups: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for fireteam_id_variant in fireteam_groups.keys():
		var fireteam_id: String = String(fireteam_id_variant)
		if fireteam_id.contains(":data:"):
			continue
		var member_units: Array = []
		var member_ids: PackedStringArray = _as_packed_string_array(fireteam_groups.get(fireteam_id, PackedStringArray()))
		for member_id in member_ids:
			var member_data: Dictionary = Dictionary(fireteam_groups.get("%s:data:%s" % [fireteam_id, member_id], {}))
			if not member_data.is_empty():
				member_units.append(member_data)
		result[fireteam_id] = FIRETEAM_COHESION_RESOLVER_SCRIPT.call("build_fireteam_snapshot", fireteam_id, member_units)
	return result


static func _build_fireteam_groups(units_by_id: Dictionary, selected_unit_ids: PackedStringArray, selected_fireteam_ids: PackedStringArray, team_states_by_id: Dictionary) -> Dictionary:
	var groups: Dictionary = {}
	for index in range(selected_unit_ids.size()):
		var unit_id: String = _normalize_unit_id(String(selected_unit_ids[index]))
		if unit_id.is_empty() or not units_by_id.has(unit_id):
			continue
		var unit: Dictionary = Dictionary(units_by_id.get(unit_id, {})).duplicate(true)
		var fireteam_id: String = ""
		if index < selected_fireteam_ids.size():
			fireteam_id = String(selected_fireteam_ids[index]).strip_edges().to_lower()
		if fireteam_id.is_empty():
			fireteam_id = String(Dictionary(team_states_by_id.get(unit_id, {})).get("fireteam_id", unit.get("fireteam_id", "unassigned"))).strip_edges().to_lower()
		if fireteam_id.is_empty():
			fireteam_id = "unassigned"
		unit["fireteam_id"] = fireteam_id
		var member_ids: PackedStringArray = _as_packed_string_array(groups.get(fireteam_id, PackedStringArray()))
		member_ids.append(unit_id)
		groups[fireteam_id] = member_ids
		groups["%s:data:%s" % [fireteam_id, unit_id]] = unit
	return groups


static func _build_mission_context(mission_result: Dictionary, options: Dictionary) -> Dictionary:
	var mission_outcome: String = String(mission_result.get("mission_outcome", mission_result.get("result", "ended"))).strip_edges().to_lower()
	var result_text: String = String(mission_result.get("result", "")).strip_edges().to_lower()
	var success: bool = bool(mission_result.get("objective_captured", false))
	if ["success", "victory", "won", "complete", "completed"].has(mission_outcome) or ["success", "victory", "won"].has(result_text):
		success = true
	return {
		"mission_id": String(mission_result.get("mission_id", options.get("mission_id", "mission"))).strip_edges(),
		"mission_outcome": mission_outcome if not mission_outcome.is_empty() else "ended",
		"success": success,
		"report_reserve_events": bool(options.get("report_reserve_events", false)),
	}


static func _build_selected_unit_ids(mission_result: Dictionary) -> PackedStringArray:
	var selected: PackedStringArray = _coerce_string_array(mission_result.get("selected_unit_ids", PackedStringArray()))
	if not selected.is_empty():
		return selected
	for team_state_variant in Array(mission_result.get("team_states", [])):
		if typeof(team_state_variant) != TYPE_DICTIONARY:
			continue
		var unit_id: String = _normalize_unit_id(String(Dictionary(team_state_variant).get("unit_id", "")))
		if not unit_id.is_empty() and not selected.has(unit_id):
			selected.append(unit_id)
	return selected


static func _build_team_states_by_id(mission_result: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for team_state_variant in Array(mission_result.get("team_states", [])):
		if typeof(team_state_variant) != TYPE_DICTIONARY:
			continue
		var team_state: Dictionary = Dictionary(team_state_variant).duplicate(true)
		var unit_id: String = _normalize_unit_id(String(team_state.get("unit_id", "")))
		if not unit_id.is_empty():
			result[unit_id] = team_state
	return result


static func _build_unit_events_by_id(mission_result: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var raw_events: Variant = mission_result.get("unit_events", [])
	if typeof(raw_events) == TYPE_DICTIONARY:
		for unit_id_variant in Dictionary(raw_events).keys():
			var unit_id: String = _normalize_unit_id(String(unit_id_variant))
			if unit_id.is_empty():
				continue
			if typeof(Dictionary(raw_events).get(unit_id_variant, {})) == TYPE_DICTIONARY:
				result[unit_id] = Dictionary(Dictionary(raw_events).get(unit_id_variant, {})).duplicate(true)
		return result
	for event_variant in Array(raw_events):
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = Dictionary(event_variant).duplicate(true)
		var unit_id: String = _normalize_unit_id(String(event.get("unit_id", "")))
		if not unit_id.is_empty():
			result[unit_id] = event
	return result


static func _resolve_unit_fireteam_id(unit: Dictionary, unit_id: String, selected_unit_ids: PackedStringArray, selected_fireteam_ids: PackedStringArray, team_state: Dictionary) -> String:
	var selected_index: int = selected_unit_ids.find(unit_id)
	if selected_index >= 0 and selected_index < selected_fireteam_ids.size():
		var selected_fireteam_id: String = String(selected_fireteam_ids[selected_index]).strip_edges().to_lower()
		if not selected_fireteam_id.is_empty():
			return selected_fireteam_id
	var state_fireteam_id: String = String(team_state.get("fireteam_id", "")).strip_edges().to_lower()
	if not state_fireteam_id.is_empty():
		return state_fireteam_id
	return String(unit.get("fireteam_id", "")).strip_edges().to_lower()


static func _is_unit_downed(unit_event: Dictionary, team_state: Dictionary) -> bool:
	if bool(unit_event.get("downed", false)):
		return true
	var vital_state: String = String(team_state.get("vital_state", "")).strip_edges().to_lower()
	if ["downed", "dead", "incapacitated", "bleeding"].has(vital_state):
		return true
	return int(team_state.get("health_points", 1)) <= 0


static func _normalize_progression(progression: Dictionary) -> Dictionary:
	var result: Dictionary = progression.duplicate(true)
	result["xp"] = int(result.get("xp", 0))
	result["missions_completed"] = int(result.get("missions_completed", 0))
	result["morale"] = clampf(float(result.get("morale", 0.50)), 0.0, 1.0)
	result["frustration"] = clampf(float(result.get("frustration", 0.0)), 0.0, 1.0)
	result["skill_progress"] = Dictionary(result.get("skill_progress", {})).duplicate(true)
	result["role_progress"] = Dictionary(result.get("role_progress", {})).duplicate(true)
	result["fireteam_cohesion_by_id"] = Dictionary(result.get("fireteam_cohesion_by_id", {})).duplicate(true)
	result["ftl_tactical"] = Dictionary(result.get("ftl_tactical", {})).duplicate(true)
	result["ftl_tactical_snapshot"] = Dictionary(result.get("ftl_tactical_snapshot", {})).duplicate(true)
	return result


static func _merge_skill_progress(existing: Dictionary, skill_gains: Dictionary) -> Dictionary:
	var result: Dictionary = existing.duplicate(true)
	for skill_key in skill_gains.keys():
		result[skill_key] = clampf(float(result.get(skill_key, 0.0)) + float(skill_gains.get(skill_key, 0.0)), 0.0, 1.0)
	return result


static func _merge_role_progress(existing: Dictionary, unit: Dictionary, xp_delta: int) -> Dictionary:
	var result: Dictionary = existing.duplicate(true)
	var role_id: String = String(unit.get("roster_role_category", unit.get("role_id", "operator"))).strip_edges().to_lower()
	if role_id.is_empty():
		role_id = "operator"
	result[role_id] = clampf(float(result.get(role_id, 0.0)) + minf(float(xp_delta) * 0.006, 0.040), 0.0, 1.0)
	return result


static func _append_limited_history(history: Array, entry: Dictionary) -> Array:
	var result: Array = []
	for history_variant in history:
		if typeof(history_variant) == TYPE_DICTIONARY:
			result.append(Dictionary(history_variant).duplicate(true))
	result.append(entry.duplicate(true))
	while result.size() > MAX_MISSION_HISTORY_ENTRIES:
		result.remove_at(0)
	return result


static func _coerce_string_array(value: Variant, unique: bool = true) -> PackedStringArray:
	if value is PackedStringArray:
		return (value as PackedStringArray).duplicate()
	var result: PackedStringArray = PackedStringArray()
	for entry in Array(value):
		var text: String = _normalize_unit_id(String(entry))
		if text.is_empty() or (unique and result.has(text)):
			continue
		result.append(text)
	return result


static func _as_packed_string_array(value: Variant) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if typeof(value) == TYPE_PACKED_STRING_ARRAY:
		for entry in value:
			result.append(String(entry))
		return result
	if typeof(value) == TYPE_ARRAY:
		for entry in Array(value):
			result.append(String(entry))
	return result


static func _normalize_unit_id(unit_id: String) -> String:
	return unit_id.strip_edges().to_lower()
