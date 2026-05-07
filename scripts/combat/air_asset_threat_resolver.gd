class_name AirAssetThreatResolver
extends RefCounted

const AIR_ASSET_STATUS_SCRIPT: GDScript = preload("res://scripts/mission/air_asset_status.gd")
const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")

const SOURCE_ID: String = "air_asset_threat_resolver"
const BLOCKED_WEAPON_NOT_ANTI_ARMOR: String = "weapon_not_anti_armor"
const BLOCKED_OUT_OF_RANGE: String = "out_of_range"
const BLOCKED_NO_LINE_OF_SIGHT: String = "no_line_of_sight"
const BLOCKED_NOT_VISIBLE_IN_FOW: String = "not_visible_in_fow"
const BLOCKED_ALTITUDE_NOT_VULNERABLE: String = "altitude_not_vulnerable"
const BLOCKED_TERMINAL_STATE: String = "air_asset_terminal_state"


func evaluate_threat(status_variant, context: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var status = _coerce_status(status_variant)
	var weapon_id: String = WEAPON_DATA_SCRIPT.call("sanitize_weapon_id", str(context.get("weapon_id", "")), "none")
	var attacker_unit_id: String = str(context.get("attacker_unit_id", context.get("unit_id", ""))).strip_edges()
	var asset_id: String = str(context.get("asset_id", status.asset_id)).strip_edges()
	if asset_id.is_empty():
		asset_id = status.asset_id
	var event_id: String = _build_event_id(asset_id, weapon_id, attacker_unit_id, context)
	var gate_result: Dictionary = _evaluate_gates(status, weapon_id, context, options)
	if not bool(gate_result.get("eligible", false)):
		return _build_blocked_result(status, weapon_id, attacker_unit_id, event_id, gate_result, context)

	var previous_state: String = AIR_ASSET_STATUS_SCRIPT.call("normalize_state", status.state)
	var warning_seen: bool = bool(context.get("warning_seen", status.warning_visible or AIR_ASSET_STATUS_SCRIPT.call("is_warning_state", previous_state)))
	var risk: float = _compute_risk(weapon_id, context)
	var damage: int = _compute_damage(weapon_id, risk, context)
	var next_state: String = str(AIR_ASSET_STATUS_SCRIPT.get("STATE_LOCKED"))
	var warning_required: bool = false
	var hit_allowed: bool = false
	var destroy_allowed: bool = false
	var tactical_trigger: String = "air_asset_threatened"

	if not warning_seen or previous_state == str(AIR_ASSET_STATUS_SCRIPT.get("STATE_INTACT")):
		warning_required = true
		damage = 0
		next_state = str(AIR_ASSET_STATUS_SCRIPT.get("STATE_LOCKED")) if risk >= 0.45 else str(AIR_ASSET_STATUS_SCRIPT.get("STATE_THREATENED"))
	else:
		hit_allowed = true
		var projected_integrity: int = maxi(int(status.integrity) - damage, 0)
		if projected_integrity <= 0 and bool(context.get("allow_destroy", true)):
			destroy_allowed = true
			tactical_trigger = "air_asset_destroyed"
			next_state = str(AIR_ASSET_STATUS_SCRIPT.get("STATE_CRASHED"))
		elif projected_integrity <= int(ceil(float(status.max_integrity) * 0.55)):
			next_state = str(AIR_ASSET_STATUS_SCRIPT.get("STATE_DAMAGED"))
		else:
			next_state = str(AIR_ASSET_STATUS_SCRIPT.get("STATE_HIT"))

	var vfx_events: Array = _build_vfx_events(next_state, context)
	var sfx_events: Array = _build_sfx_events(next_state, context)
	var threat_shell: Dictionary = {
		"event_id": event_id,
		"next_state": next_state,
		"weapon_id": weapon_id,
		"attacker_unit_id": attacker_unit_id,
		"risk": risk,
		"lz_secure_level": _get_lz_secure_level(context),
		"enemy_at_pressure": _get_enemy_at_pressure(context),
		"warning_visible": true,
		"reason": _build_reason(weapon_id, risk, context),
		"vfx_events": vfx_events,
		"sfx_events": sfx_events,
		"asset_position": context.get("asset_position", context.get("position", status.position)),
		"metadata": {
			"source": SOURCE_ID,
			"visual_only": false,
			"range_tiles": float(context.get("range_tiles", context.get("distance_tiles", 0.0))),
			"line_of_sight": bool(context.get("has_line_of_sight", context.get("los", true))),
			"visible_in_fow": bool(context.get("visible_in_fow", context.get("fow_visible", true))),
			"altitude_layer": str(context.get("altitude_layer", context.get("height_layer", "low"))).strip_edges().to_lower(),
		},
	}
	status.apply_threat(threat_shell)
	if hit_allowed:
		status.apply_damage(damage, {"terminal_state": next_state})
		status.apply_threat(threat_shell)

	var next_status: Dictionary = Dictionary(status.to_snapshot()).duplicate(true)
	var result: Dictionary = {
		"threat_id": event_id,
		"event_id": event_id,
		"eligible": true,
		"blocked_reason": "",
		"asset_id": asset_id,
		"asset_type": str(status.asset_type),
		"previous_state": previous_state,
		"next_state": next_state,
		"next_status": next_status,
		"risk": risk,
		"damage": damage,
		"weapon_id": weapon_id,
		"attacker_unit_id": attacker_unit_id,
		"warning_required": warning_required,
		"warning_visible": true,
		"hit_allowed": hit_allowed,
		"destroy_allowed": destroy_allowed,
		"lz_secure_level": _get_lz_secure_level(context),
		"enemy_at_pressure": _get_enemy_at_pressure(context),
		"tactical_breakout_trigger": tactical_trigger,
		"vfx_events": vfx_events,
		"sfx_events": sfx_events,
		"runtime_authority": str(AIR_ASSET_STATUS_SCRIPT.get("RUNTIME_AUTHORITY")),
		"ui_sets_gameplay_truth": false,
	}
	result["simulation_effect"] = build_simulation_effect(result)
	return result


func build_simulation_effect(threat_result: Dictionary) -> Dictionary:
	var status_snapshot: Dictionary = Dictionary(threat_result.get("next_status", {})).duplicate(true)
	if status_snapshot.is_empty():
		return {}
	return {
		"effect_type": "air_asset_status_update",
		"asset_id": str(threat_result.get("asset_id", status_snapshot.get("asset_id", ""))).strip_edges(),
		"asset_type": str(threat_result.get("asset_type", status_snapshot.get("asset_type", ""))).strip_edges(),
		"state": str(threat_result.get("next_state", status_snapshot.get("state", ""))).strip_edges(),
		"status_snapshot": status_snapshot,
		"event_id": str(threat_result.get("event_id", "")).strip_edges(),
		"vfx_events": Array(threat_result.get("vfx_events", [])).duplicate(true),
		"sfx_events": Array(threat_result.get("sfx_events", [])).duplicate(true),
		"source": SOURCE_ID,
		"runtime_authority": str(AIR_ASSET_STATUS_SCRIPT.get("RUNTIME_AUTHORITY")),
		"ui_sets_gameplay_truth": false,
		"priority": 80,
	}


func is_air_asset_threat_weapon(weapon_id: String) -> bool:
	return bool(WEAPON_DATA_SCRIPT.call("is_anti_armor_weapon_id", weapon_id))


func _evaluate_gates(status, weapon_id: String, context: Dictionary, options: Dictionary) -> Dictionary:
	if bool(AIR_ASSET_STATUS_SCRIPT.call("is_terminal_state", status.state)):
		return {"eligible": false, "blocked_reason": BLOCKED_TERMINAL_STATE}
	if not is_air_asset_threat_weapon(weapon_id):
		return {"eligible": false, "blocked_reason": BLOCKED_WEAPON_NOT_ANTI_ARMOR}
	var range_tiles: float = maxf(float(context.get("range_tiles", context.get("distance_tiles", 0.0))), 0.0)
	var effective_range_tiles: float = float(WEAPON_DATA_SCRIPT.call("get_effective_tile_range", weapon_id))
	if range_tiles > effective_range_tiles + float(options.get("range_slack_tiles", 0.001)):
		return {"eligible": false, "blocked_reason": BLOCKED_OUT_OF_RANGE, "range_tiles": range_tiles, "effective_range_tiles": effective_range_tiles}
	if not bool(context.get("has_line_of_sight", context.get("los", true))):
		return {"eligible": false, "blocked_reason": BLOCKED_NO_LINE_OF_SIGHT}
	if not bool(context.get("visible_in_fow", context.get("fow_visible", true))):
		return {"eligible": false, "blocked_reason": BLOCKED_NOT_VISIBLE_IN_FOW}
	var altitude_layer: String = str(context.get("altitude_layer", context.get("height_layer", "low"))).strip_edges().to_lower()
	if ["safe", "high", "orbit", "offmap"].has(altitude_layer) and not bool(options.get("ignore_altitude_gate", false)):
		return {"eligible": false, "blocked_reason": BLOCKED_ALTITUDE_NOT_VULNERABLE, "altitude_layer": altitude_layer}
	return {"eligible": true, "blocked_reason": ""}


func _build_blocked_result(status, weapon_id: String, attacker_unit_id: String, event_id: String, gate_result: Dictionary, context: Dictionary) -> Dictionary:
	var status_snapshot: Dictionary = Dictionary(status.to_snapshot()).duplicate(true)
	return {
		"threat_id": event_id,
		"event_id": event_id,
		"eligible": false,
		"blocked_reason": str(gate_result.get("blocked_reason", "")),
		"asset_id": str(status.asset_id),
		"asset_type": str(status.asset_type),
		"previous_state": str(status.state),
		"next_state": str(status.state),
		"next_status": status_snapshot,
		"risk": 0.0,
		"damage": 0,
		"weapon_id": weapon_id,
		"attacker_unit_id": attacker_unit_id,
		"warning_required": false,
		"warning_visible": bool(status_snapshot.get("warning_visible", false)),
		"hit_allowed": false,
		"destroy_allowed": false,
		"lz_secure_level": _get_lz_secure_level(context),
		"enemy_at_pressure": _get_enemy_at_pressure(context),
		"tactical_breakout_trigger": "",
		"vfx_events": [],
		"sfx_events": [],
		"simulation_effect": {},
		"runtime_authority": str(AIR_ASSET_STATUS_SCRIPT.get("RUNTIME_AUTHORITY")),
		"ui_sets_gameplay_truth": false,
	}


func _compute_risk(weapon_id: String, context: Dictionary) -> float:
	var damage: float = float(WEAPON_DATA_SCRIPT.call("get_damage_per_hit", weapon_id))
	var effective_range: float = maxf(float(WEAPON_DATA_SCRIPT.call("get_effective_tile_range", weapon_id)), 1.0)
	var range_tiles: float = clampf(float(context.get("range_tiles", context.get("distance_tiles", effective_range * 0.65))), 0.0, effective_range)
	var range_pressure: float = 1.0 - (range_tiles / effective_range)
	var risk: float = 0.28 + clampf(damage / 180.0, 0.0, 0.5)
	risk += range_pressure * 0.18
	risk += _get_enemy_at_pressure(context) * 0.22
	risk += clampf(float(context.get("enemy_security_pressure", context.get("enemy_security", 0.0))), 0.0, 1.0) * 0.12
	risk -= _get_lz_secure_level(context) * 0.30
	return clampf(risk, 0.05, 0.95)


func _compute_damage(weapon_id: String, risk: float, context: Dictionary) -> int:
	if context.has("damage"):
		return maxi(int(context.get("damage", 0)), 0)
	var base_damage: float = float(WEAPON_DATA_SCRIPT.call("get_damage_per_hit", weapon_id))
	return maxi(int(round(base_damage * lerpf(0.65, 1.25, risk))), 1)


func _get_lz_secure_level(context: Dictionary) -> float:
	return clampf(float(context.get("lz_secure_level", context.get("lz_security", 0.0))), 0.0, 1.0)


func _get_enemy_at_pressure(context: Dictionary) -> float:
	return clampf(float(context.get("enemy_at_pressure", context.get("anti_armor_pressure", context.get("enemy_at_team_pressure", 0.0)))), 0.0, 1.0)


func _build_reason(weapon_id: String, risk: float, context: Dictionary) -> String:
	var attacker: String = str(context.get("attacker_label", context.get("attacker_unit_id", "AT contact"))).strip_edges()
	if attacker.is_empty():
		attacker = "AT contact"
	return "%s has %s lock | risk %d%%" % [attacker, weapon_id, int(round(risk * 100.0))]


func _build_vfx_events(next_state: String, context: Dictionary) -> Array:
	var events: Array = [
		{"event_type": "rocket_muzzle_trail", "asset_position": context.get("asset_position", context.get("position", null))},
	]
	if bool(AIR_ASSET_STATUS_SCRIPT.call("is_terminal_state", next_state)):
		events.append({"event_type": "air_asset_explosion", "asset_position": context.get("asset_position", context.get("position", null))})
		events.append({"event_type": "smoke_debris_marker", "asset_position": context.get("asset_position", context.get("position", null))})
	elif bool(AIR_ASSET_STATUS_SCRIPT.call("is_damage_state", next_state)):
		events.append({"event_type": "air_asset_hit", "asset_position": context.get("asset_position", context.get("position", null))})
		events.append({"event_type": "smoke_debris_marker", "asset_position": context.get("asset_position", context.get("position", null))})
	else:
		events.append({"event_type": "air_asset_lock_warning", "asset_position": context.get("asset_position", context.get("position", null))})
	return events


func _build_sfx_events(next_state: String, _context: Dictionary) -> Array:
	var events: Array = ["rocket_launch"]
	if bool(AIR_ASSET_STATUS_SCRIPT.call("is_terminal_state", next_state)):
		events.append("air_asset_explosion")
	elif bool(AIR_ASSET_STATUS_SCRIPT.call("is_damage_state", next_state)):
		events.append("air_asset_hit")
	else:
		events.append("air_asset_warning")
	return events


func _coerce_status(status_variant):
	if status_variant != null and status_variant is Object and status_variant.has_method("to_snapshot"):
		return AIR_ASSET_STATUS_SCRIPT.call("from_dict", Dictionary(status_variant.call("to_snapshot")))
	if typeof(status_variant) == TYPE_DICTIONARY:
		return AIR_ASSET_STATUS_SCRIPT.call("from_dict", Dictionary(status_variant))
	return AIR_ASSET_STATUS_SCRIPT.call("from_dict", {})


func _build_event_id(asset_id: String, weapon_id: String, attacker_unit_id: String, context: Dictionary) -> String:
	var explicit_id: String = str(context.get("event_id", context.get("threat_id", ""))).strip_edges()
	if not explicit_id.is_empty():
		return explicit_id
	var tokens: PackedStringArray = PackedStringArray(["air", _sanitize_token(asset_id), _sanitize_token(weapon_id)])
	if not attacker_unit_id.is_empty():
		tokens.append(_sanitize_token(attacker_unit_id))
	var sequence: String = str(context.get("sequence", context.get("now_msec", ""))).strip_edges()
	if not sequence.is_empty():
		tokens.append(_sanitize_token(sequence))
	return ":".join(tokens)


func _sanitize_token(value: String) -> String:
	var result: String = value.strip_edges().to_lower()
	for token in [" ", "/", "\\", ":", ".", "|", "#"]:
		result = result.replace(token, "_")
	return "x" if result.is_empty() else result
