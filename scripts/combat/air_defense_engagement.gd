extends RefCounted
## Ground air defence against a ship on its landing approach.
## Contract: docs/dev/ground_air_defense_engagement_contract.md
## Pure proposal: reads data/combat/air_defense_units.json, rolls seeded dice,
## returns the next ship state and an event list. It owns no state. Caller:
## scripts/mission/air_defense_approach_plan.gd at the landing commit point;
## the mission controller commits the result through SimulationRoot.

const SYSTEMS = preload("res://scripts/tactical/space_component_systems.gd")
const DATA_PATH := "res://data/combat/air_defense_units.json"
## Height of a weapon mount above its ground cell, in terrain height levels.
const MOUNT_LEVELS := 1
const VOLLEY_SECONDS := 2.0
const DECISION_PRESS_ON := "press_on"
const DECISION_BREAK_OFF := "break_off"

static var _definition: Dictionary = {}


static func definition() -> Dictionary:
	if _definition.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		if typeof(parsed) == TYPE_DICTIONARY:
			_definition = parsed
	return _definition


static func unit(unit_id: String) -> Dictionary:
	return Dictionary(Dictionary(definition().get("units", {})).get(unit_id, {}))


## What a pilot of the given skill (0..1) does under fire.
static func pilot_profile(pilot_skill: float) -> Dictionary:
	var rules: Dictionary = definition().get("pilot", {})
	var skill: float = clampf(pilot_skill, 0.0, 1.0)
	return {
		"pilot_skill": skill,
		"reaction_delay_volleys": roundi(lerpf(float(rules.get("reaction_delay_volleys_unskilled", 3)), float(rules.get("reaction_delay_volleys_expert", 0)), skill)),
		"evasion": clampf(float(rules.get("evasion_base", 0.15)) + float(rules.get("evasion_per_skill", 0.45)) * skill, 0.0, 0.9),
		"break_off_volleys": roundi(lerpf(float(rules.get("break_off_volleys_unskilled", 2)), float(rules.get("break_off_volleys_expert", 0)), skill)),
		"flare_reaction_chance": clampf(float(rules.get("flare_reaction_base", 0.35)) + float(rules.get("flare_reaction_per_skill", 0.6)) * skill, 0.0, 1.0),
		"auto_break_off_hull_fraction": float(rules.get("auto_break_off_hull_fraction", 0.35)),
	}


## Remaining hull fraction at which a ship breaks off (landing approach AND ground-fire attack), per approach style
## ("vorsichtig" 0.65, "normal" 0.50, "aggressiv" 0.10; data block break_off_hull_fraction_by_style). An empty or unknown
## style counts as "normal"; "cautious"/"aggressive" are accepted as spellings. Without the data block the old single
## value pilot.auto_break_off_hull_fraction (0.35) is used.
static func break_off_hull_fraction(approach_style: String = "") -> float:
	var fallback: float = float(Dictionary(definition().get("pilot", {})).get("auto_break_off_hull_fraction", 0.35))
	var table: Variant = definition().get("break_off_hull_fraction_by_style")
	if typeof(table) != TYPE_DICTIONARY or table.is_empty():
		return fallback
	var style: String = approach_style.strip_edges().to_lower()
	style = {"cautious": "vorsichtig", "aggressive": "aggressiv"}.get(style, style)
	if not style in ["vorsichtig", "normal", "aggressiv"]:
		style = "normal"
	return float(table.get(style, table.get("normal", fallback)))


## Ship height minus weapon mount height, in terrain height levels.
## Negative means the ship is below the weapon's horizon.
static func height_delta_levels(ship_ground_level: int, profile_id: String, unit_ground_level: int) -> int:
	var profiles: Dictionary = definition().get("approach_profiles", {})
	var profile: Dictionary = profiles.get(profile_id, profiles.get("normal", {}))
	return ship_ground_level + int(profile.get("clearance_levels", 6)) - (unit_ground_level + MOUNT_LEVELS)


## Can this unit see and engage the ship at this moment?
## contact: range_hex, height_delta_levels, has_line_of_sight, crew_ready, missiles_left
static func envelope(unit_data: Dictionary, contact: Dictionary) -> Dictionary:
	var distance: float = float(contact.get("range_hex", INF))
	var line_of_sight: bool = bool(contact.get("has_line_of_sight", false))
	var above_horizon: bool = int(contact.get("height_delta_levels", 0)) >= 0
	var radar_contact: bool = line_of_sight and above_horizon and distance <= float(unit_data.get("radar_range_hex", 0))
	var visual_contact: bool = line_of_sight and distance <= float(unit_data.get("sight_range_hex", 0))
	var tracked: bool = radar_contact or (visual_contact and above_horizon and not bool(unit_data.get("needs_radar_lock", false)))
	var in_range: bool = distance >= float(unit_data.get("weapon_min_range_hex", 0)) and distance <= float(unit_data.get("weapon_range_hex", 0))
	var crew_ready: bool = bool(contact.get("crew_ready", true))
	var has_ammunition: bool = not unit_data.has("missiles") or int(contact.get("missiles_left", unit_data.get("missiles", 0))) > 0
	var reason := ""
	if not crew_ready: reason = "no_crew"
	elif not line_of_sight: reason = "masked"
	elif not above_horizon: reason = "below_horizon"
	elif not tracked: reason = "not_detected"
	elif not in_range: reason = "out_of_range"
	elif not has_ammunition: reason = "no_ammunition"
	return {"radar_contact": radar_contact, "visual_contact": visual_contact, "tracked": tracked and crew_ready,
		"in_range": in_range, "above_horizon": above_horizon, "can_fire": reason.is_empty(), "reason": reason}


static func range_factor(unit_data: Dictionary, distance: float) -> float:
	var falloff: Dictionary = definition().get("range_falloff", {})
	var reach: float = maxf(float(unit_data.get("weapon_range_hex", 1)), 1.0)
	var full: float = float(falloff.get("full_until_fraction", 0.5))
	var share: float = clampf(distance / reach, 0.0, 1.0)
	if share <= full:
		return 1.0
	return lerpf(1.0, float(falloff.get("factor_at_max_range", 0.5)), (share - full) / maxf(1.0 - full, 0.001))


## context:
##   seed            String, same seed gives the same result
##   pilot_skill     0..1 (the character's dropship_piloting)
##   ship_model      "cutlass" / "buccaneer" (for the flare count)
##   ship_stats      effective stats as space_component_catalog.effective_stats returns them
##   ship_state      state as space_component_systems.initial returns it
##   flares          optional, overrides the ship's flare count
##   decision        "press_on" or "break_off": what the player ordered at the decision point
##   volleys         Array; one entry per volley: {"contacts": {instance_id: {unit_id, range_hex,
##                   height_delta_levels, has_line_of_sight, crew_ready}}}
static func resolve_approach(context: Dictionary) -> Dictionary:
	var stats: Dictionary = context.get("ship_stats", {})
	var state: Dictionary = Dictionary(context.get("ship_state", {})).duplicate(true)
	if not SYSTEMS.apply_hit(stats, state, 0.0).get("ok", false):
		return {"ok": false, "reason": "invalid_ship_systems"}
	var volleys: Array = context.get("volleys", [])
	var rules: Dictionary = definition()
	var counter: Dictionary = rules.get("countermeasures", {})
	var pilot: Dictionary = pilot_profile(float(context.get("pilot_skill", 0.5)))
	var ship_model: String = String(context.get("ship_model", "cutlass"))
	var flares: int = int(context.get("flares", Dictionary(Dictionary(counter.get("ships", {})).get(ship_model, {})).get("flares", 0)))
	var decision: String = String(context.get("decision", DECISION_PRESS_ON))
	# The break-off limit follows the chosen approach style (context approach_style; missing = normal).
	var break_off_limit: float = break_off_hull_fraction(String(context.get("approach_style", "")))
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed_to_int("%s:%.2f:air_defense" % [String(context.get("seed", "")), float(pilot.pilot_skill)])

	var events: Array = []
	var tracking: Dictionary = {}       # instance id -> volleys the unit has tracked the ship
	var reload: Dictionary = {}         # instance id -> volleys until it may fire again
	var missiles: Dictionary = {}       # instance id -> missiles left
	var reported: Dictionary = {}       # instance id -> last reported hindrance
	var under_fire_volleys := 0
	var decision_point_volley := -1
	var break_off_started_volley := -1
	var broke_off := false
	var destroyed := false
	var hits := 0
	var missiles_fired := 0
	var resolved := 0

	for index in range(volleys.size()):
		if break_off_started_volley >= 0 and index - break_off_started_volley > int(pilot.break_off_volleys):
			broke_off = true
			events.append({"volley": index, "type": "broke_off"})
			break
		resolved = index + 1
		var evading: bool = under_fire_volleys >= int(pilot.reaction_delay_volleys)
		var evasion: float = float(pilot.evasion) if evading else 0.0
		var fired_at := false
		var contacts: Dictionary = Dictionary(volleys[index]).get("contacts", {})
		var ids: Array = contacts.keys()
		ids.sort()
		for instance_id in ids:
			var contact: Dictionary = contacts[instance_id]
			var unit_data: Dictionary = unit(String(contact.get("unit_id", "")))
			if unit_data.is_empty():
				continue
			if not missiles.has(instance_id) and unit_data.has("missiles"):
				missiles[instance_id] = int(unit_data.missiles)
			var probe: Dictionary = contact.duplicate()
			if missiles.has(instance_id):
				probe["missiles_left"] = int(missiles[instance_id])
			var seen: Dictionary = envelope(unit_data, probe)
			var tracked_before: int = int(tracking.get(instance_id, 0))
			if not bool(seen.tracked):
				tracking[instance_id] = 0
				if String(seen.reason) in ["below_horizon", "masked"] and bool(seen.in_range) and String(reported.get(instance_id, "")) != String(seen.reason):
					reported[instance_id] = String(seen.reason)
					events.append({"volley": index, "unit": instance_id, "type": String(seen.reason)})
				continue
			tracking[instance_id] = tracked_before + 1
			if tracked_before == 0:
				# First contact is a warning only (air_asset_threat_damage_contract: warning before damage).
				events.append({"volley": index, "unit": instance_id, "type": "radar_contact" if bool(seen.radar_contact) else "visual_contact"})
				continue
			var needs_lock: bool = bool(unit_data.get("needs_radar_lock", false))
			if needs_lock and tracked_before == 1:
				events.append({"volley": index, "unit": instance_id, "type": "locked"})
				continue
			reload[instance_id] = maxi(int(reload.get(instance_id, 0)) - 1, 0)
			if not bool(seen.can_fire) or int(reload[instance_id]) > 0:
				continue
			reload[instance_id] = int(unit_data.get("reload_volleys", 1))
			fired_at = true
			var distance: float = float(contact.get("range_hex", 0.0))
			if String(unit_data.get("kind", "")) == "missile":
				missiles[instance_id] = int(missiles[instance_id]) - 1
				missiles_fired += 1
				events.append({"volley": index, "unit": instance_id, "type": "missile_launch"})
				var decoyed := false
				if flares > 0 and rng.randf() < float(pilot.flare_reaction_chance):
					flares -= 1
					decoyed = rng.randf() < float(counter.get("flare_decoy_chance", 0.75))
					events.append({"volley": index, "unit": instance_id, "type": "flare", "decoyed": decoyed, "flares_left": flares})
				var chance: float = float(unit_data.get("base_hit_chance", 0.7)) * (1.0 - evasion * float(counter.get("missile_evasion_weight", 0.6)))
				if not decoyed and rng.randf() < chance:
					var impact: Dictionary = SYSTEMS.apply_hit(stats, state, float(unit_data.get("damage_per_hit", 0.0)))
					state = impact.state
					hits += 1
					events.append({"volley": index, "unit": instance_id, "type": "missile_hit", "shield_damage": impact.shield_damage, "hull_damage": impact.hull_damage})
				else:
					events.append({"volley": index, "unit": instance_id, "type": "missile_miss"})
			else:
				var shots: int = int(unit_data.get("shots_per_volley", 1))
				var shell_chance: float = float(unit_data.get("base_hit_chance", 0.3)) * range_factor(unit_data, distance) * (1.0 - evasion)
				var volley_hits := 0
				var shield_damage := 0.0
				var hull_damage := 0.0
				for _shot in range(shots):
					if rng.randf() < shell_chance:
						var impact: Dictionary = SYSTEMS.apply_hit(stats, state, float(unit_data.get("damage_per_hit", 0.0)))
						state = impact.state
						volley_hits += 1
						shield_damage += float(impact.shield_damage)
						hull_damage += float(impact.hull_damage)
				hits += volley_hits
				events.append({"volley": index, "unit": instance_id, "type": "flak_volley", "shots": shots, "hits": volley_hits,
					"shield_damage": shield_damage, "hull_damage": hull_damage, "evading": evading})
			if float(state.hull) <= 0.0:
				destroyed = true
				events.append({"volley": index, "type": "destroyed"})
				break
		if destroyed:
			break
		if fired_at:
			under_fire_volleys += 1
			if decision_point_volley < 0:
				decision_point_volley = index
		else:
			state = SYSTEMS.advance(stats, state, VOLLEY_SECONDS).state
		var reacted: bool = under_fire_volleys >= maxi(int(pilot.reaction_delay_volleys), 1)
		var hull_low: bool = float(state.hull) / float(state.hull_capacity) < break_off_limit
		if break_off_started_volley < 0 and reacted and (decision == DECISION_BREAK_OFF or hull_low):
			break_off_started_volley = index
			events.append({"volley": index, "type": "break_off_started", "forced": hull_low and decision != DECISION_BREAK_OFF})
	if break_off_started_volley >= 0 and not destroyed and not broke_off:
		broke_off = true
		events.append({"volley": resolved, "type": "broke_off"})
	return {
		"ok": true, "runtime_authority": "SimulationRoot", "ui_sets_gameplay_truth": false,
		"ship_state": state, "hull_fraction": float(state.hull) / float(state.hull_capacity), "destroyed": destroyed,
		"broke_off": broke_off, "break_off_started_volley": break_off_started_volley,
		"decision_point_volley": decision_point_volley, "volleys_resolved": resolved, "under_fire_volleys": under_fire_volleys,
		"hits": hits, "missiles_fired": missiles_fired, "flares_left": flares, "pilot": pilot, "events": events,
	}


## Same seed text hash the volley dice use; LA's accident roll shares it (approach_paths).
static func seed_to_int(value: String) -> int:
	return _seed_to_int(value)


static func _seed_to_int(value: String) -> int:
	var hash_value: int = 216613626
	for index in range(value.length()):
		hash_value = int((hash_value ^ value.unicode_at(index)) * 16777619) & 0x7fffffff
	return maxi(hash_value, 1)
