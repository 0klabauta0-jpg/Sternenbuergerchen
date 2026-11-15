extends RefCounted
## Pure casualty resolver for the campaign. No scene, no state.
## All balance values come from data/singleplayer/casualty_rules.json.

const RULES_PATH := "res://data/singleplayer/casualty_rules.json"

static func load_rules(path: String = RULES_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

static func _is_fit(team_state: Dictionary) -> bool:
	return str(team_state.get("vital_state", "fit")) == "fit" and float(team_state.get("health_points", 1.0)) > 0.0

static func classify_unit(team_state: Dictionary, mission_outcome: String) -> Dictionary:
	var unit_id := str(team_state.get("unit_id", ""))
	var was_downed := bool(team_state.get("was_downed", false))
	if _is_fit(team_state):
		if was_downed:
			return {"unit_id": unit_id, "outcome": "wounded", "severity": "light"}
		return {"unit_id": unit_id, "outcome": "unharmed", "severity": ""}
	var recovered: bool = mission_outcome == "won" or bool(team_state.get("near_ship", false)) or bool(team_state.get("aboard", false))
	if not recovered:
		return {"unit_id": unit_id, "outcome": "dead", "severity": ""}
	var vital := str(team_state.get("vital_state", "down"))
	var severity := "severe" if vital == "bleedout" or vital == "respawning" else "medium"
	return {"unit_id": unit_id, "outcome": "wounded", "severity": severity}

static func _leadership(unit: Dictionary) -> float:
	if unit.has("skill_leadership"):
		return float(unit.get("skill_leadership", 0.0))
	var skills: Variant = unit.get("skill_values", {})
	return float(skills.get("leadership", 0.0)) if skills is Dictionary else 0.0

static func resolve_mission(team_states: Array, mission_outcome: String, roster_units: Array, pilot_unit_id: String, rules: Dictionary) -> Dictionary:
	var classified: Array = []
	var dead_ids := PackedStringArray()
	var pilot_fit := true
	var other_fit := false
	for raw in team_states:
		var state: Dictionary = raw
		var unit_id := str(state.get("unit_id", ""))
		var fit := _is_fit(state)
		if unit_id == pilot_unit_id:
			pilot_fit = fit
		elif fit:
			other_fit = true
		var result: Dictionary = classify_unit(state, mission_outcome)
		classified.append(result)
		if result.outcome == "dead":
			dead_ids.append(unit_id)
	var reason := ""
	if not pilot_fit:
		reason = "pilot_down"
	elif not other_fit:
		reason = "ground_team_down"
	else:
		var survivors: Array = []
		for raw_unit in roster_units:
			var unit: Dictionary = raw_unit
			if not dead_ids.has(str(unit.get("unit_id", ""))):
				survivors.append(unit)
		var has_leader := false
		var has_pilot := false
		for unit in survivors:
			if str(unit.get("roster_role_category", "")) == "operator" and _leadership(unit) > 0.0:
				has_leader = true
			if float(unit.get("dropship_piloting", 0.0)) > 0.0:
				has_pilot = true
		if not has_leader:
			reason = "no_leader_left"
		elif not has_pilot:
			reason = "no_pilot_left"
		elif survivors.size() < 2:
			reason = "roster_too_small"
	if reason != "":
		return {"total_loss": true, "total_loss_reason": reason, "casualties": [], "fatality_unit_ids": PackedStringArray()}
	var casualties: Array = []
	for entry in classified:
		if entry.outcome != "unharmed":
			casualties.append(entry)
	return {"total_loss": false, "total_loss_reason": "", "casualties": casualties, "fatality_unit_ids": dead_ids}

static func build_recovery_state(severity: String, rules: Dictionary) -> Dictionary:
	var seconds := float(rules.get("recovery_seconds", {}).get(severity, 0.0))
	return {"state": "wounded", "severity": severity, "seconds_total": seconds, "seconds_remaining": seconds, "source": "campaign_casualty"}

static func build_total_loss_penalty(team_states: Array, credits: int, rules: Dictionary) -> Dictionary:
	var cfg: Dictionary = rules.get("total_loss", {})
	var fee := maxi(roundi(float(credits) * float(cfg.get("rescue_fee_fraction", 0.0))), int(cfg.get("rescue_fee_minimum", 0)))
	fee = mini(fee, maxi(credits, 0))
	var wounded: Array = []
	var morale_ids := PackedStringArray()
	for raw in team_states:
		var state: Dictionary = raw
		var unit_id := str(state.get("unit_id", ""))
		morale_ids.append(unit_id)
		if not _is_fit(state) or bool(state.get("was_downed", false)):
			wounded.append({"unit_id": unit_id, "severity": str(cfg.get("wound_severity", "light"))})
	return {"rescue_fee": fee, "wounded": wounded, "morale_delta": float(cfg.get("morale_delta", 0.0)), "morale_unit_ids": morale_ids}
