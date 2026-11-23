extends RefCounted
## Suppression state per group, the same code for both sides (FT-0b). A group key names one own fireteam or one enemy
## group_id; the tracker does not know which. It holds, per group, the value, the level and the gains collected since the last
## step. All rules and numbers come from suppression_math.gd (data/combat/suppression_rules.json). No scene, no random numbers,
## no clock: the caller decides when a step happens (every step_ticks game ticks).
## The state lives in the run only. It is not saved; reset() empties it (load of an intermediate state, mission restart).

const MATH = preload("res://scripts/tactical/suppression_math.gd")

var _rules: Dictionary = {}
## group_key -> {"value": float, "level": int, "gains": float, "stability": float, "threshold_factor": float}
var _groups: Dictionary = {}
var _active_count: int = 0


func _init(rules: Dictionary = {}) -> void:
	_rules = rules if not rules.is_empty() else MATH.load_rules()


func get_rules() -> Dictionary:
	return _rules


func _entry(group_key: String) -> Dictionary:
	if not _groups.has(group_key):
		_groups[group_key] = {"value": 0.0, "level": 0, "gains": 0.0, "stability": 0.5, "threshold_factor": 1.0}
	return _groups[group_key]


## A resolved shot at a unit of this group. Hit: with the damage done. Miss: with the damage the weapon would have done.
func note_shot(group_key: String, damage: float, hit: bool) -> void:
	if group_key.is_empty():
		return
	var entry: Dictionary = _entry(group_key)
	entry["gains"] = float(entry["gains"]) + MATH.shot_gain(_rules, damage, hit)


## One suppression step for the group, in this order: value (gains since the last step, decay), then level. Returns the new level.
func step(group_key: String, leadership: float, contact_stability: float, decay_factor: float = 1.0, threshold_factor: float = 1.0) -> int:
	if not _groups.has(group_key):
		return 0
	var entry: Dictionary = _groups[group_key]
	var decay: float = MATH.decay_per_step(_rules, leadership, contact_stability, decay_factor)
	var value: float = MATH.step_value(_rules, float(entry["value"]), float(entry["gains"]), decay)
	var previous_level: int = int(entry["level"])
	var level: int = MATH.level_for(_rules, value, previous_level, contact_stability, threshold_factor)
	entry["value"] = value
	entry["gains"] = 0.0
	entry["level"] = level
	entry["stability"] = contact_stability
	entry["threshold_factor"] = threshold_factor
	_count_active(previous_level, level)
	return level


func level_of(group_key: String) -> int:
	return int(_groups[group_key]["level"]) if _groups.has(group_key) else 0


func value_of(group_key: String) -> float:
	return float(_groups[group_key]["value"]) if _groups.has(group_key) else 0.0


func gains_of(group_key: String) -> float:
	return float(_groups[group_key]["gains"]) if _groups.has(group_key) else 0.0


## Threshold of the next level up (the highest level for level 3), with the stability and factor of the last step.
func next_threshold_of(group_key: String) -> float:
	var stability: float = 0.5
	var factor: float = 1.0
	var level: int = 0
	if _groups.has(group_key):
		stability = float(_groups[group_key]["stability"])
		factor = float(_groups[group_key]["threshold_factor"])
		level = int(_groups[group_key]["level"])
	return MATH.level_threshold(_rules, mini(level + 1, MATH.MAX_LEVEL), stability, factor)


func has_group(group_key: String) -> bool:
	return _groups.has(group_key)


func group_keys() -> Array:
	return _groups.keys()


## True while at least one group is at level 1 or higher (cheap test for the hot paths).
func any_active() -> bool:
	return _active_count > 0


## The group is gone (no living member): its state is dropped.
func forget(group_key: String) -> void:
	if _groups.has(group_key):
		if int(_groups[group_key]["level"]) > 0:
			_active_count = maxi(_active_count - 1, 0)
		_groups.erase(group_key)


## Sets value and level directly (loading, tests). Level 0..3.
func set_state(group_key: String, value: float, level: int) -> void:
	var entry: Dictionary = _entry(group_key)
	_count_active(int(entry["level"]), clampi(level, 0, MATH.MAX_LEVEL))
	entry["value"] = clampf(value, 0.0, float(_rules.get("value_cap", 6.0)))
	entry["level"] = clampi(level, 0, MATH.MAX_LEVEL)
	entry["gains"] = 0.0


func reset() -> void:
	_groups.clear()
	_active_count = 0


func _count_active(previous_level: int, level: int) -> void:
	if previous_level <= 0 and level > 0:
		_active_count += 1
	elif previous_level > 0 and level <= 0:
		_active_count = maxi(_active_count - 1, 0)
