extends SceneTree
## Verifies the pure suppression rules scripts/tactical/suppression_math.gd against data/combat/suppression_rules.json.
## No scene, no user data. FT-0a: nothing in the game uses these rules yet.
const S = preload("res://scripts/tactical/suppression_math.gd")
const EPS := 0.0001
var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS: " if ok else "FAIL: ", label)

func near(a: float, b: float) -> bool:
	return absf(a - b) < EPS

## One simulated step: gains and decay, then the level. Returns [value, level].
func _step(rules: Dictionary, value: float, level: int, gains: float, decay: float, stability: float) -> Array:
	var v: float = S.step_value(rules, value, gains, decay)
	return [v, S.level_for(rules, v, level, stability)]

func _allowed_count(rules: Dictionary, level: int, n: int) -> int:
	var c := 0
	for i in range(1, n + 1):
		if S.fire_slot_allowed(rules, level, i):
			c += 1
	return c

func _run() -> void:
	var rules: Dictionary = S.load_rules()
	check(not rules.is_empty() and rules.has("levels") and Array(rules.levels).size() == 3, "shipped rules file loads with three levels")

	# --- 1. shot_gain ---
	check(near(S.shot_gain(rules, 18.0, true), 1.0), "pistol hit (18) gains 1.0")
	check(near(S.shot_gain(rules, 40.0, true), 1.7333), "rifle hit (40) gains about 1.733")
	check(near(S.shot_gain(rules, 18.0, false), 0.5), "pistol miss gains 0.5")
	check(near(S.shot_gain(rules, 200.0, true), 3.0), "damage 200 is capped at 3.0")
	check(near(S.shot_gain(rules, 200.0, false), 3.0), "a heavy miss (3.53 before the cap) is capped at 3.0")
	check(near(S.shot_gain(rules, -5.0, true), 0.4), "negative damage counts as 0 (gain 0.4)")

	# --- 2. decay_per_step ---
	check(near(S.decay_per_step(rules, 0.5, 0.5), 0.375), "decay at leadership 0.5, stability 0.5 is 0.375")
	check(near(S.decay_per_step(rules, 0.0, 0.0), 0.21), "decay with everything 0 is 0.21")
	check(near(S.decay_per_step(rules, 1.0, 1.0), 0.585), "decay with everything 1 is 0.585")
	check(near(S.decay_per_step(rules, 0.5, 0.5, 2.0), 0.75), "decay_factor 2 doubles the decay")
	check(near(S.decay_per_step(rules, 1.0, 1.0, 10.0), 1.0), "decay is limited to 1.0")
	check(near(S.decay_per_step(rules, 0.5, 0.5, -1.0), 0.0), "decay is limited to 0.0")

	# --- step_value ---
	check(near(S.step_value(rules, 1.0, 0.5, 0.25), 1.25), "step_value adds gains and subtracts decay")
	check(near(S.step_value(rules, 0.1, 0.0, 0.5), 0.0), "step_value does not go below 0")
	check(near(S.step_value(rules, 5.5, 3.0, 0.0), 6.0), "step_value does not go above the cap 6.0")

	# --- 3. level_for (stability 0.5, factor 1 -> thresholds 1.0 / 2.5 / 4.0) ---
	check(S.level_for(rules, 0.99, 0, 0.5) == 0, "0.99 is level 0")
	check(S.level_for(rules, 1.0, 0, 0.5) == 1, "1.0 is level 1")
	check(S.level_for(rules, 2.5, 0, 0.5) == 2, "2.5 is level 2")
	check(S.level_for(rules, 4.0, 0, 0.5) == 3, "4.0 is level 3")
	check(S.level_for(rules, 6.0, 0, 0.5) == 3, "6.0 is level 3")
	check(S.level_for(rules, 2.1, 2, 0.5) == 2, "level 2 holds at 2.1 (hold threshold 2.0)")
	check(S.level_for(rules, 1.99, 2, 0.5) == 1, "level 2 falls to 1 at 1.99")
	check(S.level_for(rules, 0.85, 1, 0.5) == 1, "level 1 holds at 0.85 (hold threshold 0.8)")
	check(S.level_for(rules, 0.79, 1, 0.5) == 0, "level 1 falls to 0 at 0.79")
	check(S.level_for(rules, 3.3, 3, 0.5) == 3, "level 3 holds at 3.3 (hold threshold 3.2)")
	check(S.level_for(rules, 3.1, 3, 0.5) == 2, "level 3 falls to 2 at 3.1 (still above the level 2 hold threshold)")
	check(S.level_for(rules, 2.1, 0, 0.5) == 1, "from level 0 the hold threshold does not apply: 2.1 is only level 1")
	check(S.level_for(rules, 3.0, 1, 0.5) == 2, "a lower previous level does not stop climbing")
	check(S.level_for(rules, 0.0, 3, 0.5) == 0, "value 0 is level 0 whatever came before")
	check(S.level_for(rules, 1.0, 0, 0.55) == 0, "stability 0.55 raises threshold 1 to 1.02: value 1.0 is level 0")
	check(S.level_for(rules, 1.03, 0, 0.55) == 1, "stability 0.55: value 1.03 is level 1")
	check(S.level_for(rules, S.shot_gain(rules, 18.0, true), 0, 0.55) == 0, "stability 0.55: one pistol hit is level 0")
	check(S.level_for(rules, 1.79, 0, 0.5, 1.8) == 0 and S.level_for(rules, 1.9, 0, 0.5, 1.8) == 1, "threshold_factor 1.8 moves threshold 1 to 1.8")
	check(S.level_for(rules, 4.4, 0, 0.5, 1.8) == 1 and S.level_for(rules, 4.6, 0, 0.5, 1.8) == 2, "threshold_factor 1.8 moves threshold 2 to 4.5")
	check(S.level_for(rules, 7.0, 0, 0.5, 1.8) < 3 and S.level_for(rules, 7.3, 0, 0.5, 1.8) == 3, "threshold_factor 1.8 moves threshold 3 to 7.2")

	# --- 4. the principal's requirements as a run (stability 0.5, leadership 0.5, start 0) ---
	var decay: float = S.decay_per_step(rules, 0.5, 0.5)
	# (a) ONE pistol hit, then nothing
	var value := 0.0
	var level := 0
	var max_a := 0
	var zero_at := -1
	for step in range(1, 21):
		var gains: float = S.shot_gain(rules, 18.0, true) if step == 1 else 0.0
		var r: Array = _step(rules, value, level, gains, decay, 0.5)
		value = r[0]
		level = r[1]
		max_a = maxi(max_a, level)
		if zero_at < 0 and level == 0 and value == 0.0:
			zero_at = step
	check(max_a <= 1, "4a: one pistol hit gives at most level 1")
	check(zero_at > 0 and zero_at <= 4 and level == 0, "4a: after one pistol hit the value is back to 0 within 4 steps (step %d)" % zero_at)
	# (b) one pistol shooter: hit and miss alternating, one shot every 3 steps, 60 steps
	value = 0.0
	level = 0
	var max_b := 0
	var shots := 0
	for step in range(1, 61):
		var gains: float = 0.0
		if step % 3 == 0:
			shots += 1
			gains = S.shot_gain(rules, 18.0, shots % 2 == 1)
		var r: Array = _step(rules, value, level, gains, decay, 0.5)
		value = r[0]
		level = r[1]
		max_b = maxi(max_b, level)
	check(max_b < 2, "4b: a single pistol shooter never reaches level 2 in 60 steps (max level %d)" % max_b)
	# (c) three such shooters, shots in steps 1, 2, 3, 4 ... (one shooter per step, each alternating hit/miss)
	value = 0.0
	level = 0
	var first_l1 := -1
	var first_l2 := -1
	var first_l3 := -1
	var count := [0, 0, 0]
	for step in range(1, 61):
		var who: int = (step - 1) % 3
		count[who] += 1
		var gains: float = S.shot_gain(rules, 18.0, count[who] % 2 == 1)
		var r: Array = _step(rules, value, level, gains, decay, 0.5)
		value = r[0]
		level = r[1]
		if level >= 1 and first_l1 < 0: first_l1 = step
		if level >= 2 and first_l2 < 0: first_l2 = step
		if level >= 3 and first_l3 < 0: first_l3 = step
	check(first_l1 == 2, "4c: three pistol shooters reach level 1 in step 2 (step %d)" % first_l1)
	check(first_l2 == 7, "4c: three pistol shooters reach level 2 in step 7 (step %d)" % first_l2)
	check(first_l3 == 9, "4c: three pistol shooters reach level 3 in step 9 (step %d)" % first_l3)
	check(level == 3, "4c: and they stay at level 3 while the fire goes on")
	# (d) the fire stops: from the cap the value falls to 0 in finitely many steps
	value = 6.0
	level = 3
	var steps_to_zero := 0
	while value > 0.0 and steps_to_zero < 100:
		var r: Array = _step(rules, value, level, 0.0, decay, 0.5)
		value = r[0]
		level = r[1]
		steps_to_zero += 1
	check(value == 0.0 and level == 0 and steps_to_zero == 16, "4d: after the fire stops the value is 0 and the level 0 in 16 steps (%d)" % steps_to_zero)

	# --- 5. fire_slot_allowed ---
	check(_allowed_count(rules, 0, 100) == 100, "level 0: 100 of 100 slots are allowed")
	check(_allowed_count(rules, 1, 100) == 80, "level 1: 80 of 100 slots are allowed")
	check(_allowed_count(rules, 2, 100) == 57, "level 2: 57 of 100 slots are allowed")
	check(_allowed_count(rules, 3, 100) == 33, "level 3: 33 of 100 slots are allowed")
	var two_in_a_row := false
	for i in range(1, 400):
		if not S.fire_slot_allowed(rules, 1, i) and not S.fire_slot_allowed(rules, 1, i + 1):
			two_in_a_row = true
	check(not two_in_a_row, "level 1 never blocks two slots in a row")
	var never_zero := true
	for lv in range(0, 4):
		for start in range(1, 200):
			var any := false
			for i in range(start, start + 4):
				if S.fire_slot_allowed(rules, lv, i):
					any = true
			if not any:
				never_zero = false
	check(never_zero, "no level blocks four slots in a row (fire is never shut off)")
	check(S.fire_slot_allowed(rules, 3, 3) and not S.fire_slot_allowed(rules, 3, 1) and not S.fire_slot_allowed(rules, 3, 2), "level 3 allows every third slot (3, 6, 9)")
	check(_allowed_count(rules, 3, 400) == 133 and _allowed_count(rules, 2, 700) == 400, "the slot pattern repeats exactly (level 3: 133 of 400, level 2: 400 of 700)")

	# --- 6. move_factor ---
	check(near(S.move_factor(rules, 0, true), 1.0) and near(S.move_factor(rules, 0, false), 1.0), "level 0 moves freely")
	check(near(S.move_factor(rules, 1, true), 0.8) and near(S.move_factor(rules, 1, false), 0.8), "level 1: 0.8 in both directions")
	check(near(S.move_factor(rules, 2, true), 0.0) and near(S.move_factor(rules, 2, false), 0.6), "level 2: no advance, retreat at 0.6")
	check(near(S.move_factor(rules, 3, true), 0.0) and near(S.move_factor(rules, 3, false), 0.35), "level 3: no advance, retreat at 0.35 (retreat stays possible)")

	# --- 7. the rest ---
	check(not S.interrupts_plan(rules, 0) and not S.interrupts_plan(rules, 1) and not S.interrupts_plan(rules, 2) and S.interrupts_plan(rules, 3), "only level 3 interrupts the plan")
	check(S.cover_floor(rules, 0) == 0 and S.cover_floor(rules, 1) == 0 and S.cover_floor(rules, 2) == 24 and S.cover_floor(rules, 3) == 24, "cover floor 0 / 0 / 24 / 24")
	check(near(S.hit_bonus(rules, 0), 0.0) and near(S.hit_bonus(rules, 1), -0.05) and near(S.hit_bonus(rules, 2), -0.10) and near(S.hit_bonus(rules, 3), -0.15), "hit bonus 0 / -0.05 / -0.10 / -0.15")
	check(S.level_label(rules, 0) == "" and S.level_label(rules, 1) == "Unter Feuer" and S.level_label(rules, 2) == "Niedergehalten" and S.level_label(rules, 3) == "Festgenagelt", "level labels")
	check(S.level_label(rules, 7) == "Festgenagelt" and S.level_label(rules, -1) == "", "levels outside 0..3 are limited (7 -> 3, -1 -> 0)")
	check(S.cover_floor(rules, 7) == 24 and S.cover_floor(rules, -1) == 0 and S.interrupts_plan(rules, 7) and not S.interrupts_plan(rules, -1), "level limits for cover floor and interrupt")
	check(near(S.move_factor(rules, 9, false), 0.35) and near(S.move_factor(rules, -3, true), 1.0), "level limits for move factor")
	check(_allowed_count(rules, 9, 100) == 33 and _allowed_count(rules, -2, 100) == 100, "level limits for fire slots")
	var fallback: Dictionary = S.load_rules("res://data/combat/does_not_exist.json")
	check(not fallback.is_empty() and near(S.shot_gain(fallback, 18.0, true), 1.0) and Array(fallback.levels).size() == 3, "a missing file gives the built-in defaults")
	check(near(S.decay_per_step(fallback, 0.5, 0.5), 0.375) and S.level_for(fallback, 2.5, 0, 0.5) == 2 and _allowed_count(fallback, 2, 100) == 57, "the defaults equal the shipped numbers")
	check(near(S.shot_gain({}, 18.0, true), 1.0) and S.level_for({}, 4.0, 0, 0.5) == 3 and S.level_label({}, 2) == "Niedergehalten", "an empty rules dictionary still works with the defaults")
	print("suppression_math_verifier passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)
