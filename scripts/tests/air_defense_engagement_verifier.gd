extends SceneTree
## Verifies docs/dev/ground_air_defense_engagement_contract.md against the pure
## resolver scripts/combat/air_defense_engagement.gd. No scene, no user data.
const AD = preload("res://scripts/combat/air_defense_engagement.gd")
const CATALOG = preload("res://scripts/mission/space_component_catalog.gd")
const SYSTEMS = preload("res://scripts/tactical/space_component_systems.gd")
var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS: " if ok else "FAIL: ", label)

func ship(model_id: String) -> Dictionary:
	var slots: Dictionary = CATALOG.definition().models[model_id].default_slots
	var stats: Dictionary = CATALOG.effective_stats(model_id, slots)
	return {"stats": stats, "state": SYSTEMS.initial(stats, 100.0).get("state", {})}

func volleys(unit_id: String, ranges: Array, delta: int = 3, line_of_sight: bool = true, crew_ready: bool = true) -> Array:
	var out: Array = []
	for distance in ranges:
		out.append({"contacts": {"aa_1": {"unit_id": unit_id, "range_hex": distance, "height_delta_levels": delta,
			"has_line_of_sight": line_of_sight, "crew_ready": crew_ready}}})
	return out

func run_pass(model_id: String, unit_id: String, ranges: Array, skill: float, decision: String, seed_text: String, extra: Dictionary = {}) -> Dictionary:
	var craft: Dictionary = ship(model_id)
	var context := {"seed": seed_text, "pilot_skill": skill, "ship_model": model_id, "ship_stats": craft.stats,
		"ship_state": craft.state, "decision": decision, "volleys": volleys(unit_id, ranges, int(extra.get("delta", 3)),
		bool(extra.get("los", true)), bool(extra.get("crew", true)))}
	if extra.has("flares"): context["flares"] = extra.flares
	return AD.resolve_approach(context)

func lost(result: Dictionary, craft: Dictionary) -> float:
	return (float(craft.state.hull) - float(result.ship_state.hull)) + (float(craft.state.shield) - float(result.ship_state.shield))

func types(result: Dictionary) -> Array:
	var out: Array = []
	for event in result.events: out.append(String(event.type))
	return out

func _run() -> void:
	var data: Dictionary = AD.definition()
	var items: Dictionary = CATALOG.definition().items
	check(data.units.has("hagel") and data.units.has("donnerkeil"), "both vehicles are defined")
	for id in ["hagel", "donnerkeil"]:
		var u: Dictionary = AD.unit(id)
		check(int(u.size) == 1 and String(u.grade) == "D" and items.has(u.shield_item) and items.has(u.power_item), id + " carries size 1 grade D shield and power plant that exist as ship components")
		check(float(u.min_elevation_degrees) == 0.0 and u.crew.size() == 2 and int(u.skirmish_points) > 0, id + " has a crew of two, a price and cannot depress below the horizon")
		check(ResourceLoader.exists(String(u.model)), id + " points at its model")
	check(float(AD.unit("donnerkeil").weapon_range_hex) > float(AD.unit("hagel").weapon_range_hex) and float(AD.unit("donnerkeil").radar_range_hex) > float(AD.unit("hagel").radar_range_hex), "missile truck out-ranges the flak truck")

	var novice: Dictionary = AD.pilot_profile(0.0)
	var expert: Dictionary = AD.pilot_profile(1.0)
	check(int(novice.reaction_delay_volleys) == 3 and int(expert.reaction_delay_volleys) == 0, "poor pilot reacts three volleys late, expert at once")
	check(int(novice.break_off_volleys) == 2 and int(expert.break_off_volleys) == 0, "poor pilot needs two more volleys to turn away, expert none")
	check(float(expert.evasion) > float(novice.evasion) and float(expert.flare_reaction_chance) > float(novice.flare_reaction_chance), "skill raises evasion and flare reaction")

	var hagel: Dictionary = AD.unit("hagel")
	var donner: Dictionary = AD.unit("donnerkeil")
	check(AD.envelope(hagel, {"range_hex": 8, "height_delta_levels": 2, "has_line_of_sight": true}).can_fire, "flak fires at a ship above its horizon in range")
	var below: Dictionary = AD.envelope(hagel, {"range_hex": 8, "height_delta_levels": -1, "has_line_of_sight": true})
	check(not below.can_fire and String(below.reason) == "below_horizon" and not below.radar_contact, "nothing below the 0 degree horizon is detected by radar or fired at")
	check(String(AD.envelope(hagel, {"range_hex": 8, "height_delta_levels": 2, "has_line_of_sight": false}).reason) == "masked", "terrain between ship and vehicle masks the ship")
	check(String(AD.envelope(hagel, {"range_hex": 20, "height_delta_levels": 2, "has_line_of_sight": true}).reason) == "out_of_range", "flak detects beyond its gun range but does not fire")
	check(String(AD.envelope(donner, {"range_hex": 3, "height_delta_levels": 2, "has_line_of_sight": true}).reason) == "out_of_range", "missile truck has a minimum range")
	check(String(AD.envelope(hagel, {"range_hex": 8, "height_delta_levels": 2, "has_line_of_sight": true, "crew_ready": false}).reason) == "no_crew", "a vehicle without its gunner does not fire")
	check(String(AD.envelope(donner, {"range_hex": 30, "height_delta_levels": 2, "has_line_of_sight": true, "missiles_left": 0}).reason) == "no_ammunition", "missile truck runs out of missiles")
	check(AD.height_delta_levels(0, "low", 2) < 0 and AD.height_delta_levels(0, "normal", 2) > 0, "low approach over lower ground stays under a ridge battery's horizon, normal approach does not")
	check(AD.height_delta_levels(2, "low", 2) == 0, "low approach at the battery's own level is still on its horizon")

	var close: Array = [12, 10, 8, 6, 5, 4, 4, 4]
	var a: Dictionary = run_pass("cutlass", "hagel", close, 0.5, "press_on", "seed-a")
	var b: Dictionary = run_pass("cutlass", "hagel", close, 0.5, "press_on", "seed-a")
	check(a.ok and JSON.stringify(a) == JSON.stringify(b), "same seed gives the same result")
	check(String(a.events[0].type) == "radar_contact" and int(a.decision_point_volley) == 1, "first contact is a warning, the first volley falls one step later and opens the decision")
	var refused: Dictionary = AD.resolve_approach({"seed": "x", "volleys": close, "ship_stats": {}, "ship_state": {}})
	check(not refused.ok and String(refused.reason) == "invalid_ship_systems", "invalid ship systems are refused")

	var worst_hull := 1.0
	var novice_loss := 0.0
	var expert_loss := 0.0
	var novice_fire := 0
	var expert_fire := 0
	var destroyed_by_one_pass := 0
	var destroyed_while_breaking_off := 0
	for i in range(300):
		var pressed: Dictionary = run_pass("cutlass", "hagel", close, 0.1, "press_on", "p%d" % i)
		worst_hull = minf(worst_hull, float(pressed.hull_fraction))
		if pressed.destroyed: destroyed_by_one_pass += 1
		var craft: Dictionary = ship("cutlass")
		var slow: Dictionary = run_pass("cutlass", "hagel", close, 0.1, "break_off", "s%d" % i)
		var quick: Dictionary = run_pass("cutlass", "hagel", close, 0.9, "break_off", "s%d" % i)
		if slow.destroyed: destroyed_while_breaking_off += 1
		novice_loss += lost(slow, craft)
		expert_loss += lost(quick, craft)
		novice_fire += int(slow.under_fire_volleys)
		expert_fire += int(quick.under_fire_volleys)
	check(destroyed_while_breaking_off == 0, "one flak truck never destroys a fresh Cutlass whose pilot breaks off, however poor (300 seeds)")
	check(destroyed_by_one_pass < 30 and worst_hull < 0.35, "pressing on through seven close volleys with a poor pilot hurts badly and can rarely cost the ship (under 10 percent of 300 seeds)")
	check(expert_loss < novice_loss * 0.5, "a skilled pilot who breaks off takes less than half the damage of a poor one (300 seeds)")
	check(expert_fire == 300 and novice_fire == 300 * 5, "expert leaves after the first volley, poor pilot sits through five")
	var quick_one: Dictionary = run_pass("cutlass", "hagel", close, 0.9, "break_off", "one")
	check(quick_one.broke_off and types(quick_one).has("break_off_started") and int(quick_one.under_fire_volleys) == 1, "break-off ends the approach")

	var far: Array = [50, 44, 40, 36, 32, 28, 24, 20, 16, 12]
	var m: Dictionary = run_pass("cutlass", "donnerkeil", far, 0.5, "press_on", "m1")
	var order: Array = types(m)
	check(order.find("radar_contact") < order.find("locked") and order.find("locked") < order.find("missile_launch"), "missile truck: radar contact, then lock, then launch")
	check(int(m.missiles_fired) == 2, "missile truck fires its two missiles and no more")
	var with_flares := 0
	var without_flares := 0
	var single_hit_kills := 0
	var forced := 0
	for i in range(300):
		var f2: Dictionary = run_pass("buccaneer", "donnerkeil", far, 0.6, "press_on", "f%d" % i, {"flares": 2})
		var f0: Dictionary = run_pass("buccaneer", "donnerkeil", far, 0.6, "press_on", "f%d" % i, {"flares": 0})
		with_flares += int(f2.hits)
		without_flares += int(f0.hits)
		if int(f0.hits) == 1 and f0.destroyed: single_hit_kills += 1
		if types(f0).has("break_off_started"): forced += 1
	check(with_flares < without_flares, "flares reduce missile hits (300 seeds)")
	check(single_hit_kills == 0, "one missile never destroys even the small fighter")
	check(forced > 0, "a badly hit ship breaks off on its own even when ordered to press on")

	var low: Dictionary = run_pass("cutlass", "hagel", close, 0.1, "press_on", "low", {"delta": -1})
	check(int(low.hits) == 0 and float(low.hull_fraction) == 1.0 and types(low).has("below_horizon"), "a ship below the horizon is not hit and the player is told why")
	var masked: Dictionary = run_pass("cutlass", "donnerkeil", far, 0.1, "press_on", "mask", {"los": false})
	check(int(masked.missiles_fired) == 0 and int(masked.decision_point_volley) == -1, "a masked ship is never locked")
	var uncrewed: Dictionary = run_pass("cutlass", "hagel", close, 0.1, "press_on", "crew", {"crew": false})
	check(int(uncrewed.hits) == 0 and uncrewed.events.is_empty(), "a vehicle whose gunner is out does nothing")
	check(a.runtime_authority == "SimulationRoot" and not a.ui_sets_gameplay_truth, "result is a proposal for SimulationRoot")
	print("AIR_DEFENSE_ENGAGEMENT passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)
