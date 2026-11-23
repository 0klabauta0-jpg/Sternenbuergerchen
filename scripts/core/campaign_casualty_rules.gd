extends RefCounted
## Pure casualty resolver for the campaign. No scene, no state.
## All balance values come from data/singleplayer/casualty_rules.json.

const RULES_PATH := "res://data/singleplayer/casualty_rules.json"
## Used when the rules file has no "respawn" block. The only place for these defaults.
const DEFAULT_RESPAWN := {"outage_base_seconds": 3600, "outage_step_seconds": 1800, "pickup_location_id": "polisa"}
## Upper bound of the respawn limit. A copy of GameSettingsContract.MAX_CAMPAIGN_RESPAWN_LIMIT (scripts/ui must not be
## imported from scripts/core); campaign_respawn_rules_verifier checks that both are equal.
const MAX_RESPAWN_LIMIT := 9
## Cap for a stored respawns_used counter.
const MAX_RESPAWNS_USED := 1000

static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT

static func rules_are_valid(rules: Dictionary) -> bool:
	if not _is_number(rules.get("down_revive_window_seconds")) or float(rules["down_revive_window_seconds"]) <= 0.0:
		return false
	if not _is_number(rules.get("recovery_radius_world")) or float(rules["recovery_radius_world"]) <= 0.0:
		return false
	var seconds: Variant = rules.get("recovery_seconds")
	if not seconds is Dictionary:
		return false
	for key in ["light", "medium", "severe"]:
		if not _is_number(seconds.get(key)):
			return false
	var total_loss: Variant = rules.get("total_loss")
	if not total_loss is Dictionary:
		return false
	for key in ["rescue_fee_fraction", "rescue_fee_minimum", "morale_delta"]:
		if not _is_number(total_loss.get(key)):
			return false
	if not total_loss.get("wound_severity") is String:
		return false
	return _respawn_block_is_valid(rules)

static func _is_positive_whole(value: Variant) -> bool:
	if not _is_number(value):
		return false
	return float(value) > 0.0 and is_equal_approx(float(value), roundf(float(value)))

## The respawn block is optional; a missing block means the defaults above.
static func _respawn_block_is_valid(rules: Dictionary) -> bool:
	if not rules.has("respawn"):
		return true
	var block: Variant = rules["respawn"]
	if not block is Dictionary:
		return false
	if not _is_positive_whole(block.get("outage_base_seconds")) or not _is_positive_whole(block.get("outage_step_seconds")):
		return false
	var place: Variant = block.get("pickup_location_id")
	return place is String and place != ""

static func _respawn_config(rules: Dictionary) -> Dictionary:
	var block: Variant = rules.get("respawn", DEFAULT_RESPAWN)
	return block if block is Dictionary else DEFAULT_RESPAWN

static func respawn_outage_seconds(death_number: int, rules: Dictionary) -> int:
	var cfg: Dictionary = _respawn_config(rules)
	return int(cfg["outage_base_seconds"]) + int(cfg["outage_step_seconds"]) * (maxi(death_number, 1) - 1)

## Reads "respawns_used" from a team state or roster entry. Never raises: anything that is not a
## Dictionary, or whose value is not a finite number, counts as 0. Floats are truncated, negatives are 0.
## Huge values are capped at MAX_RESPAWNS_USED (not reset to 0): a broken big counter must never give a free life.
static func respawns_used_of(entry: Variant) -> int:
	if not entry is Dictionary:
		return 0
	var value: Variant = entry.get("respawns_used", 0)
	if typeof(value) == TYPE_INT:
		return clampi(int(value), 0, MAX_RESPAWNS_USED)
	if typeof(value) == TYPE_FLOAT and is_finite(float(value)):
		return int(clampf(float(value), 0.0, float(MAX_RESPAWNS_USED)))
	return 0

## Reads the respawn limit from the settings (a file the player can edit by hand). Never raises.
## int stays, finite float is truncated, everything else (null, text, array, bool, dictionary, INF, NAN) is 0; result 0..MAX_RESPAWN_LIMIT.
static func respawn_limit_of(value: Variant) -> int:
	if typeof(value) == TYPE_INT:
		return clampi(int(value), 0, MAX_RESPAWN_LIMIT)
	if typeof(value) == TYPE_FLOAT and is_finite(float(value)):
		return int(clampf(float(value), 0.0, float(MAX_RESPAWN_LIMIT)))
	return 0

## Ist der Wert eine Zaehlerzahl (ganze Zahl oder endliche Kommazahl)? Alles andere (null, Text, bool, Liste, ...) ist keine.
static func _is_counter_value(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or (typeof(value) == TYPE_FLOAT and is_finite(float(value)))

static func is_final_death(respawns_used: int, respawn_limit: int) -> bool:
	return maxi(respawns_used, 0) >= maxi(respawn_limit, 0)

static func build_respawn_state(death_number: int, source: String, rules: Dictionary) -> Dictionary:
	var seconds := respawn_outage_seconds(death_number, rules)
	return {"state": "respawning", "death_number": maxi(death_number, 1), "seconds_total": seconds, "seconds_remaining": seconds, "pickup_location_id": str(_respawn_config(rules)["pickup_location_id"]), "source": source}

static func load_rules(path: String = RULES_PATH) -> Dictionary:
	var parsed: Variant = null
	if FileAccess.file_exists(path):
		parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or not rules_are_valid(parsed):
		push_error("campaign_casualty_rules: Regeldatei fehlt oder ist ungültig: %s" % path)
		return {}
	return parsed

static func _is_fit(team_state: Dictionary) -> bool:
	return str(team_state.get("vital_state", "fit")) == "fit" and float(team_state.get("health_points", 1.0)) > 0.0

static func classify_unit(team_state: Dictionary, mission_outcome: String) -> Dictionary:
	var unit_id := str(team_state.get("unit_id", ""))
	var was_downed := bool(team_state.get("was_downed", false))
	# LC2b: Wer beim Absturz eines Schiffs gestorben ist (Merkmal killed_in_crash, Quelle der Absturz), ist tot - zuerst gewertet,
	# sonst rettet "an Bord", "nahe am Schiff" oder ein gewonnener Einsatz ihn. Danach gelten die Respawn-Regeln unveraendert.
	if bool(team_state.get("killed_in_crash", false)):
		return {"unit_id": unit_id, "outcome": "dead", "severity": ""}
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

static func resolve_mission(team_states: Array, mission_outcome: String, roster_units: Array, pilot_unit_id: String, rules: Dictionary, context: Dictionary = {}) -> Dictionary:
	var respawn_limit: int = respawn_limit_of(context.get("respawn_limit", 0))
	# The roster is only searched for respawns_used when a limit is set; without a limit it is untouched.
	var roster_used := {}
	if respawn_limit > 0:
		for raw_roster in roster_units:
			if raw_roster is Dictionary:
				roster_used[str(raw_roster.get("unit_id", ""))] = respawns_used_of(raw_roster)
	var classified: Array = []
	var dead_ids := PackedStringArray()
	var respawn_ids := PackedStringArray()
	var pilot_fit := true
	var other_fit := false
	# LC2c: Ist das Schiff verloren (context.craft_lost), holt die Notrettung alle Lebenden ab: Liegende gelten als gerettet
	# (aboard), ausser wer beim Absturz gestorben ist. Fuer dieses Schiff gibt es die Kette pilot_down nicht mehr (nichts mehr zu fliegen).
	var craft_lost: bool = bool(context.get("craft_lost", false))
	var rescued_unit_ids: Array = Array(context.get("rescued_unit_ids", [])) if typeof(context.get("rescued_unit_ids", [])) == TYPE_ARRAY else []
	for raw in team_states:
		var state: Dictionary = raw
		# LC2d A1: nur wer noch lebt (fit oder am Boden, "down") wird gerettet; wer verblutet ist oder auf den Respawn wartet, bleibt nach den vorhandenen Regeln.
		# LC2k K2: Insassen eines anderen verlorenen Schiffs, die nicht an Bord eines heimkehrenden Schiffs sind (context.rescued_unit_ids), holt die Notrettung ebenso.
		if (craft_lost or rescued_unit_ids.has(str(state.get("unit_id", "")))) and not bool(state.get("killed_in_crash", false)) and (_is_fit(state) or str(state.get("vital_state", "down")) == "down"):
			state = state.duplicate()
			state["aboard"] = true
		var unit_id := str(state.get("unit_id", ""))
		var fit := _is_fit(state)
		if unit_id == pilot_unit_id:
			pilot_fit = fit or craft_lost
		elif fit:
			other_fit = true
		var result: Dictionary = classify_unit(state, mission_outcome)
		classified.append(result)
		if result.outcome == "dead":
			# Der Zaehler des Einsatzstands gilt nur, wenn er eine Zahl ist; sonst (fehlt oder falscher Typ) zaehlt der Kader.
			var used: int = respawns_used_of(state) if _is_counter_value(state.get("respawns_used")) else int(roster_used.get(unit_id, 0))
			var final_death := is_final_death(used, respawn_limit)
			result["final"] = final_death
			result["death_number"] = maxi(used, 0) + 1
			if final_death:
				dead_ids.append(unit_id)
			else:
				result["respawn_state"] = build_respawn_state(int(result["death_number"]), "crash" if bool(state.get("killed_in_crash", false)) else "left_behind", rules)
				respawn_ids.append(unit_id)
	var reason := ""
	if craft_lost:
		# LC2d A2: Nach einem Schiffsverlust ist es nur dann ein Totalverlust, wenn niemand mehr lebt. Lebt mindestens eine Person,
		# bringt die Notrettung die Lebenden heim, das Schiff ist verloren, die Toten sind tot - auch wenn Anfuehrer oder Pilot fehlen.
		var anyone_alive := false
		for entry in classified:
			if str(entry.outcome) != "dead":
				anyone_alive = true
		if not anyone_alive:
			reason = "ground_team_down"
	elif not pilot_fit:
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
		return {"total_loss": true, "total_loss_reason": reason, "casualties": [], "fatality_unit_ids": PackedStringArray(), "respawn_unit_ids": PackedStringArray()}
	var casualties: Array = []
	for entry in classified:
		if entry.outcome != "unharmed":
			casualties.append(entry)
	return {"total_loss": false, "total_loss_reason": "", "casualties": casualties, "fatality_unit_ids": dead_ids, "respawn_unit_ids": respawn_ids}

static func build_recovery_state(severity: String, rules: Dictionary) -> Dictionary:
	var seconds := float(rules.get("recovery_seconds", {}).get(severity, 0.0))
	return {"state": "wounded", "severity": severity, "seconds_total": seconds, "seconds_remaining": seconds, "source": "campaign_casualty"}

static func build_total_loss_penalty(team_states: Array, credits: int, rules: Dictionary) -> Dictionary:
	var cfg: Dictionary = rules.get("total_loss", {})
	var fee := maxi(roundi(float(credits) * float(cfg.get("rescue_fee_fraction", 0.0))), int(cfg.get("rescue_fee_minimum", 0)))
	# Abschnitt K (E4): die Gebuehr wird nicht mehr auf das Guthaben gedeckelt; sie ist die Notrettung als letzter Ausweg und darf
	# das Konto ins Minus fuehren. Bei Credits <= 0 gilt die Mindestgebuehr (negatives Guthaben ergibt keinen negativen Anteil).
	var wounded: Array = []
	var morale_ids := PackedStringArray()
	for raw in team_states:
		var state: Dictionary = raw
		var unit_id := str(state.get("unit_id", ""))
		morale_ids.append(unit_id)
		if not _is_fit(state) or bool(state.get("was_downed", false)):
			wounded.append({"unit_id": unit_id, "severity": str(cfg.get("wound_severity", "light"))})
	return {"rescue_fee": fee, "wounded": wounded, "morale_delta": float(cfg.get("morale_delta", 0.0)), "morale_unit_ids": morale_ids}
