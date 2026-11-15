extends SceneTree
## Verifies the pure casualty resolver scripts/core/campaign_casualty_rules.gd
## against data/singleplayer/casualty_rules.json. No scene, no user data.
const R = preload("res://scripts/core/campaign_casualty_rules.gd")
var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS: " if ok else "FAIL: ", label)

func ts(id: String, vital: String, was_downed := false, near := false, aboard := false) -> Dictionary:
	return {"unit_id": id, "vital_state": vital, "health_points": 0 if vital != "fit" else 100, "was_downed": was_downed, "near_ship": near, "aboard": aboard}

func unit(id: String, role: String, leadership := 0.0, piloting := 0.0) -> Dictionary:
	return {"unit_id": id, "roster_role_category": role, "skill_values": {"leadership": leadership}, "dropship_piloting": piloting}

func _run() -> void:
	var rules: Dictionary = R.load_rules()
	check(float(rules.down_revive_window_seconds) == 60.0 and float(rules.recovery_seconds.medium) == 900.0, "rules load from data file")
	check(R.classify_unit(ts("a", "fit"), "won").outcome == "unharmed", "fit and never down is unharmed")
	var light: Dictionary = R.classify_unit(ts("a", "fit", true), "aborted")
	check(light.outcome == "wounded" and light.severity == "light", "revived in the field is lightly wounded")
	var medium: Dictionary = R.classify_unit(ts("a", "down"), "won")
	check(medium.outcome == "wounded" and medium.severity == "medium", "down at a won mission is recovered, medium")
	var severe: Dictionary = R.classify_unit(ts("a", "bleedout", true, true), "aborted")
	check(severe.outcome == "wounded" and severe.severity == "severe", "critical near the ship on retreat is recovered, severe")
	check(R.classify_unit(ts("a", "down", true, false, true), "lost").severity == "medium", "aboard counts as recovered")
	check(R.classify_unit(ts("a", "down"), "aborted").outcome == "dead", "down and left behind on retreat is dead")
	check(R.classify_unit(ts("a", "bleedout"), "lost").outcome == "dead", "critical and left behind on defeat is dead")
	var roster: Array = [unit("lead", "operator", 0.6), unit("pilot", "pilot", 0.0, 0.7), unit("two", "operator", 0.4), unit("three", "operator", 0.0)]
	var normal: Dictionary = R.resolve_mission([ts("lead", "fit"), ts("two", "down"), ts("pilot", "fit", false, true, true)], "aborted", roster, "pilot", rules)
	check(not normal.total_loss and Array(normal.fatality_unit_ids) == ["two"], "one left behind dies, mission is no total loss")
	var pilot_down: Dictionary = R.resolve_mission([ts("lead", "fit"), ts("pilot", "down")], "won", roster, "pilot", rules)
	check(pilot_down.total_loss and pilot_down.total_loss_reason == "pilot_down" and pilot_down.fatality_unit_ids.is_empty(), "pilot down is a total loss without deaths")
	var all_down: Dictionary = R.resolve_mission([ts("lead", "down"), ts("two", "bleedout"), ts("pilot", "fit", false, true, true)], "lost", roster, "pilot", rules)
	check(all_down.total_loss and all_down.total_loss_reason == "ground_team_down", "whole ground team down is a total loss")
	var no_leader: Dictionary = R.resolve_mission([ts("lead", "down"), ts("two", "down"), ts("three", "fit"), ts("pilot", "fit", false, true, true)], "aborted", roster, "pilot", rules)
	check(no_leader.total_loss and no_leader.total_loss_reason == "no_leader_left", "deaths that leave no leader are a total loss")
	var state: Dictionary = R.build_recovery_state("severe", rules)
	check(state.state == "wounded" and float(state.seconds_remaining) == 2400.0 and float(state.seconds_total) == 2400.0, "recovery state carries the configured time")
	var lost_team: Array = [ts("lead", "down"), ts("two", "fit", true), ts("three", "fit"), ts("pilot", "fit", false, true, true)]
	var penalty: Dictionary = R.build_total_loss_penalty(lost_team, 500, rules)
	check(int(penalty.rescue_fee) == 125 and is_equal_approx(float(penalty.morale_delta), -0.08), "total loss costs a quarter of the credits and morale")
	check(penalty.wounded.size() == 2 and penalty.wounded[0].severity == "light" and Array(penalty.morale_unit_ids).size() == 4, "everyone who was down is lightly wounded, everyone loses morale")
	check(int(R.build_total_loss_penalty(lost_team, 120, rules).rescue_fee) == 50, "the rescue fee has a minimum")
	check(int(R.build_total_loss_penalty(lost_team, 30, rules).rescue_fee) == 30, "the rescue fee never exceeds the credits")
	check(R.rules_are_valid(rules), "shipped rules file is valid")
	check(not R.rules_are_valid({}) and not R.rules_are_valid({"down_revive_window_seconds": 60.0}), "empty or partial rules are invalid")
	check(R.load_rules("res://data/singleplayer/does_not_exist.json").is_empty(), "a missing rules file yields empty rules and reports an error")
	print("CAMPAIGN_CASUALTY_RULES passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)
