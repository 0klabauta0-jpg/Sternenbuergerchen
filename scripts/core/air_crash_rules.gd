extends RefCounted
## Pure shootdown rules for ships hit by ground fire. No scene, no state.
## All balance values come from data/combat/air_crash_rules.json.
## Random numbers: caller passes an int state and gets the next state back. The step is the 31-bit LCG of
## SimulationRoot.draw_air_ground_roll (scripts/core/simulation_root.gd:8455-8456), rebuilt statically here.

const RULES_PATH := "res://data/combat/air_crash_rules.json"
const REQUIRED_KEYS := ["explosion_base", "explosion_pilot_factor", "emergency_landing_base", "emergency_landing_pilot_factor", "emergency_landing_hull_percent", "crash_dead_chance", "crash_max_dead", "crash_injured_chance", "crash_severe_share", "crash_light_health_loss_fraction", "explosion_dead_chance", "explosion_salvage_fraction"]
const CHANCE_KEYS := ["explosion_base", "emergency_landing_base", "crash_dead_chance", "crash_injured_chance", "crash_severe_share", "crash_light_health_loss_fraction", "explosion_dead_chance", "explosion_salvage_fraction"]

static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT

static func validate_rules(d: Dictionary) -> bool:
	for key in REQUIRED_KEYS:
		if not _is_number(d.get(key)) or is_nan(float(d[key])):
			return false
	for key in CHANCE_KEYS:
		var v := float(d[key])
		if v < 0.0 or v > 1.0:
			return false
	for key in ["explosion_pilot_factor", "emergency_landing_pilot_factor", "emergency_landing_hull_percent", "crash_max_dead"]:
		if float(d[key]) < 0.0:
			return false
	return true

static func load_rules(path: String = RULES_PATH) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("air_crash_rules: cannot open " + path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or not validate_rules(parsed):
		push_error("air_crash_rules: invalid rules in " + path)
		return {}
	return parsed

## One step of the shared air/ground stream. Returns {"roll": 0..<1, "rng_state": next state}.
static func _step(rng_state: int) -> Dictionary:
	var next := (rng_state * 1103515245 + 12345) & 0x7fffffff
	return {"roll": float(next) / 2147483648.0, "rng_state": next}

static func outcome_chances(pilot_skill: float, rules: Dictionary) -> Dictionary:
	var p := 0.0 if is_nan(pilot_skill) else clampf(pilot_skill, 0.0, 1.0)
	var explosion := clampf(float(rules.explosion_base) - float(rules.explosion_pilot_factor) * p, 0.0, 1.0)
	var landing := clampf(float(rules.emergency_landing_base) + float(rules.emergency_landing_pilot_factor) * p, 0.0, 1.0)
	var crash := maxf(1.0 - explosion - landing, 0.0)
	return {"explosion": explosion, "emergency_landing": landing, "crash": crash}

static func outcome_for_roll(roll: float, chances: Dictionary) -> String:
	if roll < float(chances.explosion):
		return "explosion"
	if roll < float(chances.explosion) + float(chances.emergency_landing):
		return "emergency_landing"
	return "crash"

static func resolve_shootdown(pilot_skill: float, rules: Dictionary, rng_state: int) -> Dictionary:
	var chances := outcome_chances(pilot_skill, rules)
	var step := _step(rng_state)
	return {"outcome": outcome_for_roll(float(step.roll), chances), "roll": step.roll, "chances": chances, "rng_state": step.rng_state}

static func _entry(state: String, loss: float) -> Dictionary:
	return {"state": state, "health_loss_fraction": loss}

static func resolve_occupants(outcome: String, occupant_ids: Array, rules: Dictionary, rng_state: int) -> Dictionary:
	if outcome != "explosion" and outcome != "emergency_landing" and outcome != "crash":
		push_error("air_crash_rules: unknown outcome " + outcome)
		return {}
	var results := {}
	var dead_ids: Array = []
	var state := rng_state
	for id in occupant_ids:
		if outcome == "emergency_landing":
			results[id] = _entry("unhurt", 0.0)
			continue
		var step := _step(state)
		state = int(step.rng_state)
		var roll := float(step.roll)
		if outcome == "explosion":
			if roll < float(rules.explosion_dead_chance):
				results[id] = _entry("dead", 1.0)
				dead_ids.append(id)
			else:
				results[id] = _entry("severe", 1.0)
			continue
		var dead_chance := float(rules.crash_dead_chance)
		if roll < dead_chance and dead_ids.size() < int(rules.crash_max_dead):
			results[id] = _entry("dead", 1.0)
			dead_ids.append(id)
			continue
		# Survivor path (also for a person who would die above the limit): one more draw.
		var step2 := _step(state)
		state = int(step2.rng_state)
		var injured := float(step2.roll) < float(rules.crash_injured_chance)
		if not injured:
			results[id] = _entry("unhurt", 0.0)
			continue
		var step3 := _step(state)
		state = int(step3.rng_state)
		if float(step3.roll) < float(rules.crash_severe_share):
			results[id] = _entry("severe", 1.0)
		else:
			results[id] = _entry("light", float(rules.crash_light_health_loss_fraction))
	return {"results": results, "dead_ids": dead_ids, "rng_state": state}
