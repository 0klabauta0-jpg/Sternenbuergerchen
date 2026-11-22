extends RefCounted
## Pure suppression rules, the same for both sides. No scene, no state, no randomness, no clock.
## All balance numbers come from data/combat/suppression_rules.json; DEFAULTS below only repeats them
## so that a missing file or field never crashes. Levels run 0..3 (0 = not suppressed).
## Level change: climb at value >= threshold of a level; a level already held is kept down to
## hysteresis x its threshold. The result is the highest level that is reached or held.
## FT-0a: nothing in the game calls this yet.

const RULES_PATH := "res://data/combat/suppression_rules.json"
const MAX_LEVEL := 3

const DEFAULTS := {
	"gain_hit_base": 0.4,
	"gain_hit_per_damage": 0.0333333,
	"gain_miss_factor": 0.5,
	"gain_per_shot_cap": 3.0,
	"decay_base": 0.30,
	"decay_leadership_weight": 0.5,
	"decay_stability_base": 0.7,
	"decay_stability_weight": 0.6,
	"value_cap": 6.0,
	"hysteresis": 0.8,
	"threshold_stability_base": 0.8,
	"threshold_stability_weight": 0.4,
	"levels": [
		{"threshold": 1.0, "fire_slot_divisor": 1.25, "hit_bonus": -0.05, "cover_floor": 0, "move_factor": 0.8, "move_toward_enemy_factor": 0.8, "interrupts_plan": false, "label": "Unter Feuer"},
		{"threshold": 2.5, "fire_slot_divisor": 1.75, "hit_bonus": -0.10, "cover_floor": 24, "move_factor": 0.6, "move_toward_enemy_factor": 0.0, "interrupts_plan": false, "label": "Niedergehalten"},
		{"threshold": 4.0, "fire_slot_divisor": 3.0, "hit_bonus": -0.15, "cover_floor": 24, "move_factor": 0.35, "move_toward_enemy_factor": 0.0, "interrupts_plan": true, "label": "Festgenagelt"},
	],
}

static func _is_number(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value))

## A rules number: the value in `rules` if it is a number, else the built-in default.
static func _num(rules: Dictionary, key: String) -> float:
	var v: Variant = rules.get(key)
	if _is_number(v):
		return float(v)
	return float(DEFAULTS[key])

## A field of one level (level 1..3), with the built-in default as fallback.
static func _level_field(rules: Dictionary, level: int, key: String) -> Variant:
	var index: int = clampi(level, 1, MAX_LEVEL) - 1
	var levels: Variant = rules.get("levels")
	if levels is Array and index < levels.size() and levels[index] is Dictionary and levels[index].has(key):
		var v: Variant = levels[index][key]
		var d: Variant = DEFAULTS["levels"][index][key]
		if typeof(d) == TYPE_BOOL:
			if typeof(v) == TYPE_BOOL:
				return v
		elif typeof(d) == TYPE_STRING:
			if typeof(v) == TYPE_STRING:
				return v
		elif _is_number(v):
			return v
	return DEFAULTS["levels"][index][key]

static func _level_number(rules: Dictionary, level: int, key: String) -> float:
	return float(_level_field(rules, level, key))

## Loads the rules file. A missing or broken file or field gives the built-in numbers, never a crash.
static func load_rules(path: String = RULES_PATH) -> Dictionary:
	var result: Dictionary = DEFAULTS.duplicate(true)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return result
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return result
	for key in DEFAULTS:
		if key == "levels":
			continue
		if _is_number(parsed.get(key)):
			result[key] = float(parsed[key])
	var levels: Array = []
	for i in MAX_LEVEL:
		var entry: Dictionary = {}
		for field in DEFAULTS["levels"][i]:
			entry[field] = _level_field(parsed, i + 1, field)
		levels.append(entry)
	result["levels"] = levels
	return result

static func shot_gain(rules: Dictionary, damage: float, hit: bool) -> float:
	var gain: float = _num(rules, "gain_hit_base") + maxf(0.0, damage) * _num(rules, "gain_hit_per_damage")
	if not hit:
		gain *= _num(rules, "gain_miss_factor")
	return minf(gain, _num(rules, "gain_per_shot_cap"))

static func decay_per_step(rules: Dictionary, leadership: float, contact_stability: float, decay_factor: float = 1.0) -> float:
	var decay: float = _num(rules, "decay_base") * (1.0 + _num(rules, "decay_leadership_weight") * leadership) \
		* (_num(rules, "decay_stability_base") + _num(rules, "decay_stability_weight") * contact_stability) * decay_factor
	return clampf(decay, 0.0, 1.0)

static func step_value(rules: Dictionary, value: float, gains: float, decay: float) -> float:
	return clampf(value + gains - decay, 0.0, _num(rules, "value_cap"))

static func level_threshold(rules: Dictionary, level: int, contact_stability: float, threshold_factor: float = 1.0) -> float:
	return _level_number(rules, level, "threshold") * (_num(rules, "threshold_stability_base") + _num(rules, "threshold_stability_weight") * contact_stability) * threshold_factor

static func level_for(rules: Dictionary, value: float, previous_level: int, contact_stability: float, threshold_factor: float = 1.0) -> int:
	var held: int = clampi(previous_level, 0, MAX_LEVEL)
	var hysteresis: float = _num(rules, "hysteresis")
	for level in range(MAX_LEVEL, 0, -1):
		var threshold: float = level_threshold(rules, level, contact_stability, threshold_factor)
		if value >= threshold:
			return level
		if level <= held and value >= hysteresis * threshold:
			return level
	return 0

## slot_index is the running number of a unit's due shot opportunity (1, 2, 3 ...). Integer arithmetic only.
@warning_ignore("integer_division")
static func fire_slot_allowed(rules: Dictionary, level: int, slot_index: int) -> bool:
	var lv: int = clampi(level, 0, MAX_LEVEL)
	if lv == 0 or slot_index < 1:
		return true
	var m100: int = maxi(100, roundi(_level_number(rules, lv, "fire_slot_divisor") * 100.0))
	return (slot_index * 100) / m100 > ((slot_index - 1) * 100) / m100

static func hit_bonus(rules: Dictionary, level: int) -> float:
	if clampi(level, 0, MAX_LEVEL) == 0:
		return 0.0
	return _level_number(rules, level, "hit_bonus")

static func cover_floor(rules: Dictionary, level: int) -> int:
	if clampi(level, 0, MAX_LEVEL) == 0:
		return 0
	return roundi(_level_number(rules, level, "cover_floor"))

static func move_factor(rules: Dictionary, level: int, toward_enemy: bool) -> float:
	if clampi(level, 0, MAX_LEVEL) == 0:
		return 1.0
	return _level_number(rules, level, "move_toward_enemy_factor" if toward_enemy else "move_factor")

static func interrupts_plan(rules: Dictionary, level: int) -> bool:
	if clampi(level, 0, MAX_LEVEL) == 0:
		return false
	return bool(_level_field(rules, level, "interrupts_plan"))

static func level_label(rules: Dictionary, level: int) -> String:
	if clampi(level, 0, MAX_LEVEL) == 0:
		return ""
	return String(_level_field(rules, level, "label"))
