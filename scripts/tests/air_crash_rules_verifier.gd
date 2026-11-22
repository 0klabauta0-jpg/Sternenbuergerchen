extends SceneTree
## Verifies the pure shootdown rules scripts/core/air_crash_rules.gd
## against data/combat/air_crash_rules.json. No scene, no user data.
const R = preload("res://scripts/core/air_crash_rules.gd")
const KEYS := ["explosion_base", "explosion_pilot_factor", "emergency_landing_base", "emergency_landing_pilot_factor", "emergency_landing_hull_percent", "crash_dead_chance", "crash_max_dead", "crash_injured_chance", "crash_severe_share", "crash_light_health_loss_fraction", "explosion_dead_chance", "explosion_salvage_fraction"]
var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS: " if ok else "FAIL: ", label)

func near(a: float, b: float, eps := 1e-6) -> bool:
	return absf(a - b) <= eps

func chances_ok(pilot: float, rules: Dictionary, e: float, l: float, c: float, label: String) -> void:
	var ch: Dictionary = R.outcome_chances(pilot, rules)
	check(near(ch.explosion, e) and near(ch.emergency_landing, l) and near(ch.crash, c), label)
	check(near(float(ch.explosion) + float(ch.emergency_landing) + float(ch.crash), 1.0), label + " (sum is 1)")

func _run() -> void:
	var rules: Dictionary = R.load_rules()
	var all_keys := true
	for k in KEYS:
		if not rules.has(k): all_keys = false
	check(all_keys and rules.size() >= KEYS.size(), "real file loads all twelve keys")
	check(R.validate_rules(rules), "shipped rules are valid")
	var missing: Dictionary = rules.duplicate()
	missing.erase("crash_dead_chance")
	var bad: Dictionary = rules.duplicate()
	bad["explosion_dead_chance"] = 1.5
	check(not R.validate_rules(missing) and not R.validate_rules(bad) and not R.validate_rules({}), "missing key, chance 1.5 and empty dict are rejected")
	check(R.load_rules("res://data/combat/does_not_exist.json").is_empty(), "a missing file yields empty rules")

	chances_ok(0.78, rules, 0.0708, 0.451, 0.4782, "pilot 0.78")
	chances_ok(0.3, rules, 0.138, 0.235, 0.627, "pilot 0.3")
	chances_ok(0.0, rules, 0.18, 0.10, 0.72, "pilot 0.0")
	chances_ok(1.0, rules, 0.04, 0.55, 0.41, "pilot 1.0")
	chances_ok(-1.0, rules, 0.18, 0.10, 0.72, "pilot -1 counts as 0")
	chances_ok(NAN, rules, 0.18, 0.10, 0.72, "pilot NaN counts as 0")
	chances_ok(5.0, rules, 0.04, 0.55, 0.41, "pilot 5 counts as 1")

	var ch: Dictionary = R.outcome_chances(0.5, rules)
	var e: float = ch.explosion
	var l: float = ch.emergency_landing
	var eps := 1e-9
	check(R.outcome_for_roll(0.0, ch) == "explosion", "roll 0 is explosion")
	check(R.outcome_for_roll(e - eps, ch) == "explosion", "just below explosion threshold")
	check(R.outcome_for_roll(e, ch) == "emergency_landing", "exactly on explosion threshold is emergency landing")
	check(R.outcome_for_roll(e + l - eps, ch) == "emergency_landing", "just below second threshold")
	check(R.outcome_for_roll(e + l, ch) == "crash", "exactly on second threshold is crash")
	check(R.outcome_for_roll(e + l + eps, ch) == "crash", "just above second threshold")

	var a: Dictionary = R.resolve_shootdown(0.5, rules, 12345)
	var b: Dictionary = R.resolve_shootdown(0.5, rules, 12345)
	check(a.outcome == b.outcome and a.roll == b.roll and a.rng_state == b.rng_state, "same state gives the same result")
	check(int(a.rng_state) != 12345 and float(a.roll) >= 0.0 and float(a.roll) < 1.0, "rng_state advances, roll in 0..1")
	check(a.outcome == R.outcome_for_roll(float(a.roll), a.chances), "outcome follows the roll")
	var counts := {"explosion": 0, "emergency_landing": 0, "crash": 0}
	var st := 1
	for i in 20000:
		var r: Dictionary = R.resolve_shootdown(0.5, rules, st)
		st = int(r.rng_state)
		counts[r.outcome] += 1
	check(absf(counts.crash / 20000.0 - float(R.outcome_chances(0.5, rules).crash)) < 0.02, "crash share over 20000 draws matches the chance")

	var ids: Array = ["a", "b", "c", "d", "e", "f"]
	var runs := 20000
	var max_dead := 0
	var with_dead := 0
	var surv := 0
	var inj := 0
	var sev := 0
	var ok_loss := true
	st = 7
	for i in runs:
		var r: Dictionary = R.resolve_occupants("crash", ids, rules, st)
		st = int(r.rng_state)
		var dead: int = Array(r.dead_ids).size()
		max_dead = maxi(max_dead, dead)
		if dead > 0: with_dead += 1
		for id in ids:
			var o: Dictionary = r.results[id]
			if o.state == "dead": continue
			surv += 1
			if o.state == "light" or o.state == "severe": inj += 1
			if o.state == "severe": sev += 1
			if o.state == "light" and not near(o.health_loss_fraction, float(rules.crash_light_health_loss_fraction)): ok_loss = false
			if o.state == "unhurt" and float(o.health_loss_fraction) != 0.0: ok_loss = false
			if o.state == "severe" and float(o.health_loss_fraction) != 1.0: ok_loss = false
	check(max_dead <= int(rules.crash_max_dead), "crash: never more than crash_max_dead dead")
	var share_dead := with_dead / float(runs)
	check(share_dead >= 0.22 and share_dead <= 0.30, "crash: share of runs with a dead person %.3f" % share_dead)
	var share_inj := inj / float(surv)
	var share_sev := sev / float(maxi(inj, 1))
	check(share_inj >= 0.68 and share_inj <= 0.72, "crash: injured share among survivors %.3f" % share_inj)
	check(share_sev >= 0.18 and share_sev <= 0.22, "crash: severe share among injured %.3f" % share_sev)
	check(ok_loss, "crash: health_loss_fraction per state")

	var dead_n := 0
	var total := 0
	var bad_state := false
	st = 11
	for i in runs:
		var r: Dictionary = R.resolve_occupants("explosion", ids, rules, st)
		st = int(r.rng_state)
		for id in ids:
			var o: Dictionary = r.results[id]
			total += 1
			if o.state == "dead": dead_n += 1
			elif o.state != "severe": bad_state = true
			if float(o.health_loss_fraction) != 1.0: bad_state = true
	var share_exp := dead_n / float(total)
	check(share_exp >= 0.58 and share_exp <= 0.62, "explosion: dead share %.3f" % share_exp)
	check(not bad_state, "explosion: only dead or severe, loss fraction 1.0")

	var n: Dictionary = R.resolve_occupants("emergency_landing", ids, rules, 4242)
	var all_unhurt := true
	for id in ids:
		if n.results[id].state != "unhurt" or float(n.results[id].health_loss_fraction) != 0.0: all_unhurt = false
	check(all_unhurt and int(n.rng_state) == 4242 and Array(n.dead_ids).is_empty(), "emergency landing: all unhurt, rng_state unchanged")

	var empty: Dictionary = R.resolve_occupants("crash", [], rules, 99)
	check(Dictionary(empty.results).is_empty() and Array(empty.dead_ids).is_empty() and int(empty.rng_state) == 99, "empty occupant list gives an empty result")
	var unknown: Dictionary = R.resolve_occupants("sinking", ids, rules, 99)
	check(unknown.is_empty() or (Dictionary(unknown.get("results", {})).is_empty() and Array(unknown.get("dead_ids", [])).is_empty()), "unknown outcome gives an empty result")
	var d1: Dictionary = R.resolve_occupants("crash", ids, rules, 555)
	var d2: Dictionary = R.resolve_occupants("crash", ids, rules, 555)
	check(d1 == d2, "occupants: same state gives the same result")

	# Fixed values for the LCG step, computed by hand: (s * 1103515245 + 12345) & 0x7fffffff, roll = next / 2147483648.0.
	# Same calculation as SimulationRoot.draw_air_ground_roll (simulation_root.gd:8455-8456); that is an instance method
	# on a scene node, so it is not called here.
	var fixed := [[1, 1103527590, 0.51387007813900709], [12345, 1406932606, 0.65515404846519232], [2147483647, 1043980748, 0.48614141903817654]]
	for f in fixed:
		var s: Dictionary = R._step(int(f[0]))
		check(int(s.rng_state) == int(f[1]) and near(float(s.roll), float(f[2]), 1e-12), "LCG step from state %d gives %d" % [int(f[0]), int(f[1])])
		var sd: Dictionary = R.resolve_shootdown(0.5, rules, int(f[0]))
		check(int(sd.rng_state) == int(f[1]) and near(float(sd.roll), float(f[2]), 1e-12), "resolve_shootdown uses that step from state %d" % int(f[0]))

	var forced: Dictionary = rules.duplicate()
	forced["crash_dead_chance"] = 1.0
	forced["crash_max_dead"] = 1
	var one: Dictionary = R.resolve_occupants("crash", ids, forced, 77)
	var others_alive := true
	for i in range(1, ids.size()):
		if one.results[ids[i]].state == "dead": others_alive = false
	check(one.results["a"].state == "dead" and Array(one.dead_ids) == ["a"] and others_alive, "crash_dead_chance 1.0, max 1: exactly the first is dead")
	forced["crash_max_dead"] = 2
	var two: Dictionary = R.resolve_occupants("crash", ids, forced, 77)
	var rest_alive := true
	for i in range(2, ids.size()):
		if two.results[ids[i]].state == "dead": rest_alive = false
	check(Array(two.dead_ids) == ["a", "b"] and rest_alive, "crash_dead_chance 1.0, max 2: exactly two dead")

	check(R.outcome_chances(0.5, {}).is_empty(), "outcome_chances with empty rules gives {}")
	check(R.resolve_shootdown(0.5, {}, 1).is_empty(), "resolve_shootdown with empty rules gives {}")
	check(R.resolve_occupants("crash", ids, {}, 1).is_empty(), "resolve_occupants with empty rules gives {}")
	check(R.resolve_occupants("crash", ids, bad, 1).is_empty(), "resolve_occupants with invalid rules gives {}")

	print("AIR_CRASH_RULES passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)
