extends SceneTree
## Verifies the respawn arithmetic in scripts/core/campaign_casualty_rules.gd (R1).
## Pure calculation: no scene, no user data. Without a respawn limit nothing changes.
const R = preload("res://scripts/core/campaign_casualty_rules.gd")
var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS: " if ok else "FAIL: ", label)

func ts(id: String, vital: String, was_downed := false, near := false, aboard := false, used := -1) -> Dictionary:
	var d := {"unit_id": id, "vital_state": vital, "health_points": 0 if vital != "fit" else 100, "was_downed": was_downed, "near_ship": near, "aboard": aboard}
	if used >= 0:
		d["respawns_used"] = used
	return d

func unit(id: String, role: String, leadership := 0.0, piloting := 0.0) -> Dictionary:
	return {"unit_id": id, "roster_role_category": role, "skill_values": {"leadership": leadership}, "dropship_piloting": piloting}

func _base_rules() -> Dictionary:
	return {
		"down_revive_window_seconds": 60.0, "recovery_radius_world": 180.0,
		"recovery_seconds": {"light": 180.0, "medium": 900.0, "severe": 2400.0},
		"total_loss": {"rescue_fee_fraction": 0.25, "rescue_fee_minimum": 50, "wound_severity": "light", "morale_delta": -0.08},
	}

func _run() -> void:
	var rules: Dictionary = R.load_rules()
	# Times
	check(R.respawn_outage_seconds(1, rules) == 3600 and R.respawn_outage_seconds(2, rules) == 5400, "outage death 1 and 2")
	check(R.respawn_outage_seconds(3, rules) == 7200 and R.respawn_outage_seconds(4, rules) == 9000, "outage death 3 and 4")
	check(R.respawn_outage_seconds(0, rules) == 3600 and R.respawn_outage_seconds(-1, rules) == 3600, "outage death 0 and -1 count as 1")
	# Final death
	check(not R.is_final_death(0, 3) and not R.is_final_death(2, 3), "not final below the limit")
	check(R.is_final_death(3, 3) and R.is_final_death(4, 3), "final at and above the limit")
	check(R.is_final_death(0, 0) and not R.is_final_death(-1, 1), "limit 0 is always final, negatives count as 0")
	# State
	var st: Dictionary = R.build_respawn_state(2, "left_behind", rules)
	check(st.size() == 6 and st.has("state") and st.has("death_number") and st.has("seconds_total") and st.has("seconds_remaining") and st.has("pickup_location_id") and st.has("source"), "respawn state has the six keys")
	check(st.state == "respawning" and int(st.death_number) == 2 and int(st.seconds_total) == 5400 and int(st.seconds_remaining) == 5400, "respawn state values")
	check(st.pickup_location_id == "polisa" and st.source == "left_behind", "respawn state place and source")
	# Rules file
	var block: Dictionary = rules.get("respawn", {})
	check(int(block.get("outage_base_seconds", 0)) == 3600 and int(block.get("outage_step_seconds", 0)) == 1800 and block.get("pickup_location_id") == "polisa" and block.get("balance_status") == "initial_values_not_final", "shipped rules carry the respawn block")
	var old_rules: Dictionary = _base_rules()
	check(R.rules_are_valid(old_rules), "rules without respawn block stay valid")
	check(R.respawn_outage_seconds(2, old_rules) == 5400 and R.build_respawn_state(1, "x", old_rules).pickup_location_id == "polisa", "rules without block use the defaults")
	var bad_base: Dictionary = _base_rules()
	bad_base["respawn"] = {"outage_base_seconds": 0, "outage_step_seconds": 1800, "pickup_location_id": "polisa"}
	check(not R.rules_are_valid(bad_base), "base seconds 0 is invalid")
	var bad_place: Dictionary = _base_rules()
	bad_place["respawn"] = {"outage_base_seconds": 3600, "outage_step_seconds": 1800, "pickup_location_id": ""}
	check(not R.rules_are_valid(bad_place), "empty pickup place is invalid")
	var bad_step: Dictionary = _base_rules()
	bad_step["respawn"] = {"outage_base_seconds": 3600, "outage_step_seconds": 1.5, "pickup_location_id": "polisa"}
	check(not R.rules_are_valid(bad_step), "non-integer step is invalid")
	var ok_block: Dictionary = _base_rules()
	ok_block["respawn"] = {"outage_base_seconds": 600, "outage_step_seconds": 60, "pickup_location_id": "x"}
	check(R.rules_are_valid(ok_block) and R.respawn_outage_seconds(3, ok_block) == 720, "custom block is valid and used")
	# resolve_mission with limit 3
	var roster: Array = [unit("lead", "operator", 0.6), unit("pilot", "pilot", 0.0, 0.7), unit("a", "operator"), unit("b", "operator"), unit("c", "operator"), unit("d", "operator")]
	var team: Array = [ts("lead", "fit"), ts("pilot", "fit", false, true, true), ts("a", "down", true, false, false, 0), ts("b", "down", true, false, false, 2), ts("c", "bleedout", true, false, false, 3), ts("d", "down", true, false, false, 5)]
	var ctx := {"respawn_limit": 3}
	var res: Dictionary = R.resolve_mission(team, "aborted", roster, "pilot", rules, ctx)
	check(not res.total_loss, "limit 3 case is no total loss")
	check(Array(res.respawn_unit_ids) == ["a", "b"], "respawn ids a, b")
	check(Array(res.fatality_unit_ids) == ["c", "d"], "fatality ids c, d")
	var by_id := {}
	for entry in res.casualties:
		by_id[entry.unit_id] = entry
	check(int(by_id["a"].death_number) == 1 and by_id["a"].final == false and by_id["a"].respawn_state.state == "respawning" and int(by_id["a"].respawn_state.seconds_total) == 3600, "a: death 1, 3600 s")
	check(int(by_id["b"].death_number) == 3 and by_id["b"].final == false and int(by_id["b"].respawn_state.seconds_remaining) == 7200 and by_id["b"].respawn_state.source == "left_behind", "b: death 3, 7200 s, source left_behind")
	check(by_id["c"].final == true and by_id["d"].final == true and not by_id["c"].has("respawn_state") and not by_id["d"].has("respawn_state"), "c, d final without respawn state")
	check(int(by_id["c"].death_number) == 4 and int(by_id["d"].death_number) == 6, "final death numbers")
	# Used count may also come from the roster entry
	var roster_used: Array = [unit("lead", "operator", 0.6), unit("pilot", "pilot", 0.0, 0.7), unit("a", "operator")]
	roster_used[2]["respawns_used"] = 1
	var from_roster: Dictionary = R.resolve_mission([ts("lead", "fit"), ts("pilot", "fit", false, true, true), ts("a", "down")], "aborted", roster_used, "pilot", rules, ctx)
	check(Array(from_roster.respawn_unit_ids) == ["a"] and int(from_roster.casualties[0].death_number) == 2, "respawns_used falls back to the roster entry")
	# Wounded and unharmed carry no respawn fields
	var mixed: Dictionary = R.resolve_mission([ts("lead", "fit"), ts("pilot", "fit", false, true, true), ts("a", "down", true, true), ts("b", "fit", true)], "aborted", roster, "pilot", rules, ctx)
	var no_extra := true
	for entry in mixed.casualties:
		if entry.has("final") or entry.has("respawn_state") or entry.has("death_number"):
			no_extra = false
	check(mixed.casualties.size() == 2 and no_extra and mixed.respawn_unit_ids.is_empty(), "rescued units get neither final nor respawn_state")
	# Total loss reasons count only final deaths
	var small_roster: Array = [unit("lead", "operator", 0.6, 0.7), unit("two", "operator")]
	var small_team: Array = [ts("lead", "fit", false, true, true), ts("three", "fit"), ts("two", "down", true, false, false, 0)]
	var tl0: Dictionary = R.resolve_mission(small_team, "aborted", small_roster, "lead", rules)
	check(tl0.total_loss and tl0.total_loss_reason == "roster_too_small", "without limit: roster_too_small")
	var tl3: Dictionary = R.resolve_mission(small_team, "aborted", small_roster, "lead", rules, ctx)
	check(not tl3.total_loss and Array(tl3.respawn_unit_ids) == ["two"] and tl3.fatality_unit_ids.is_empty(), "limit 3: no roster_too_small, two respawns")
	var tl_used: Dictionary = R.resolve_mission([ts("lead", "fit", false, true, true), ts("three", "fit"), ts("two", "down", true, false, false, 3)], "aborted", small_roster, "lead", rules, ctx)
	check(tl_used.total_loss and tl_used.total_loss_reason == "roster_too_small", "limit 3 but used 3: still roster_too_small")
	var leader_team: Array = [ts("lead", "down", true, false, false, 0), ts("two", "down", true, false, false, 0), ts("three", "fit"), ts("pilot", "fit", false, true, true)]
	var leader_roster: Array = [unit("lead", "operator", 0.6), unit("two", "operator", 0.4), unit("three", "operator"), unit("pilot", "pilot", 0.0, 0.7)]
	check(R.resolve_mission(leader_team, "aborted", leader_roster, "pilot", rules).total_loss_reason == "no_leader_left", "without limit: no_leader_left")
	check(not R.resolve_mission(leader_team, "aborted", leader_roster, "pilot", rules, ctx).total_loss, "limit 3: no_leader_left not triggered")
	var no_pilot_roster: Array = [unit("lead", "operator", 0.6), unit("p2", "pilot", 0.0, 0.7), unit("three", "operator")]
	var no_pilot_team: Array = [ts("lead", "fit"), ts("three", "fit"), ts("p2", "down", true, false, false, 0)]
	check(R.resolve_mission(no_pilot_team, "aborted", no_pilot_roster, "lead", rules).total_loss_reason == "no_pilot_left", "without limit: no_pilot_left")
	check(not R.resolve_mission(no_pilot_team, "aborted", no_pilot_roster, "lead", rules, ctx).total_loss, "limit 3: no_pilot_left not triggered")
	# pilot_down and ground_team_down unchanged
	check(R.resolve_mission([ts("lead", "fit"), ts("pilot", "down")], "won", roster, "pilot", rules, ctx).total_loss_reason == "pilot_down", "pilot_down unchanged with limit")
	check(R.resolve_mission([ts("lead", "down"), ts("a", "bleedout"), ts("pilot", "fit", false, true, true)], "lost", roster, "pilot", rules, ctx).total_loss_reason == "ground_team_down", "ground_team_down unchanged with limit")
	# Backward equality: no limit vs limit 0
	var plain: Dictionary = R.resolve_mission(team, "aborted", roster, "pilot", rules)
	var zero: Dictionary = R.resolve_mission(team, "aborted", roster, "pilot", rules, {"respawn_limit": 0})
	check(Array(plain.fatality_unit_ids) == Array(zero.fatality_unit_ids) and Array(plain.fatality_unit_ids) == ["a", "b", "c", "d"], "limit absent and 0 give the same fatalities")
	check(plain.total_loss == zero.total_loss and plain.total_loss_reason == zero.total_loss_reason and plain.respawn_unit_ids.is_empty() and zero.respawn_unit_ids.is_empty(), "limit absent and 0 give the same total loss fields")
	var same: bool = plain.casualties.size() == zero.casualties.size()
	for i in range(mini(plain.casualties.size(), zero.casualties.size())):
		var p: Dictionary = plain.casualties[i]
		var z: Dictionary = zero.casualties[i]
		if p.unit_id != z.unit_id or p.outcome != z.outcome or p.severity != z.severity:
			same = false
		if p.outcome == "dead" and (p.final != true or z.final != true or p.has("respawn_state")):
			same = false
	check(same, "outcome and severity per unit equal, dead units final")
	print("CAMPAIGN_RESPAWN_RULES passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)
