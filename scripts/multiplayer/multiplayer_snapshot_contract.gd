class_name MultiplayerSnapshotContract
extends RefCounted

const SCHEMA_VERSION: int = 1
const SNAPSHOT_TYPE_STATE: String = "state"
const TRANSFER_STATE_SNAPSHOT: String = "unreliable"
const TRANSFER_VITAL_DELTA: String = "reliable"
const TRANSFER_MISSION_RESULT: String = "reliable"
const TRANSFER_START_LOAD: String = "reliable"
const MULTIPLAYER_ROSTER_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_roster_contract.gd")


func build_state_snapshot(data: Dictionary) -> Dictionary:
	var snapshot: Dictionary = {
		"schema_version": SCHEMA_VERSION,
		"snapshot_type": SNAPSHOT_TYPE_STATE,
		"transfer_mode": TRANSFER_STATE_SNAPSHOT,
		"tick": maxi(int(data.get("tick", 0)), 0),
		"units": _normalize_unit_snapshots(data.get("units", [])),
		"vital_updates": _normalize_vital_updates(data.get("vital_updates", [])),
		"objective": _normalize_objective(data.get("objective", {})),
		"dropship": _normalize_dropship(data.get("dropship", {})),
		"contacts": _normalize_contacts(data.get("contacts", [])),
		"enemy_security": _normalize_enemy_security(data.get("enemy_security", [])),
		"enemy_team_tactics": _normalize_enemy_team_tactics(data.get("enemy_team_tactics", [])),
		"character_gameplay": _normalize_character_gameplay(data.get("character_gameplay", [])),
		"fire_events": _normalize_fire_events(data.get("fire_events", [])),
		"feedback_bubbles": _normalize_feedback_bubbles(data.get("feedback_bubbles", [])),
		"fireteam_tactical": _normalize_fireteam_tactical(data.get("fireteam_tactical", [])),
		"commander_intents": _normalize_commander_intents(data.get("commander_intents", [])),
		"fireteam_plan_status": _normalize_fireteam_plan_status(data.get("fireteam_plan_status", [])),
		"communication_events": _normalize_communication_events(data.get("communication_events", [])),
		"tactical_rules": _normalize_tactical_rules(data.get("tactical_rules", [])),
		"breakout_states": _normalize_breakout_states(data.get("breakout_states", [])),
		"air_asset_status": _normalize_air_asset_statuses(data.get("air_asset_status", data.get("air_asset_statuses", []))),
		"mission_result": _normalize_mission_result(data.get("mission_result", {})),
	}
	return snapshot


func validate_for_apply(snapshot: Dictionary, last_applied_tick: int) -> Dictionary:
	if typeof(snapshot) != TYPE_DICTIONARY:
		return _reject("snapshot_not_dictionary")

	var normalized_snapshot: Dictionary = build_state_snapshot(snapshot)
	var tick: int = int(normalized_snapshot.get("tick", 0))
	if tick <= last_applied_tick:
		return {
			"accepted": false,
			"reason": "out_of_order_snapshot",
			"tick": tick,
			"last_applied_tick": last_applied_tick,
		}

	return {
		"accepted": true,
		"reason": "",
		"tick": tick,
		"snapshot": normalized_snapshot,
	}


func normalize_display_context(context: Dictionary) -> Dictionary:
	return {
		"dropship": _normalize_dropship(context.get("dropship", {})),
		"contacts": _normalize_contacts(context.get("contacts", [])),
		"enemy_security": _normalize_enemy_security(context.get("enemy_security", [])),
		"enemy_team_tactics": _normalize_enemy_team_tactics(context.get("enemy_team_tactics", [])),
		"character_gameplay": _normalize_character_gameplay(context.get("character_gameplay", [])),
		"fire_events": _normalize_fire_events(context.get("fire_events", [])),
		"feedback_bubbles": _normalize_feedback_bubbles(context.get("feedback_bubbles", [])),
		"fireteam_tactical": _normalize_fireteam_tactical(context.get("fireteam_tactical", [])),
		"commander_intents": _normalize_commander_intents(context.get("commander_intents", [])),
		"fireteam_plan_status": _normalize_fireteam_plan_status(context.get("fireteam_plan_status", [])),
		"communication_events": _normalize_communication_events(context.get("communication_events", [])),
		"tactical_rules": _normalize_tactical_rules(context.get("tactical_rules", [])),
		"breakout_states": _normalize_breakout_states(context.get("breakout_states", [])),
		"air_asset_status": _normalize_air_asset_statuses(context.get("air_asset_status", context.get("air_asset_statuses", []))),
		"mission_result": _normalize_mission_result(context.get("mission_result", {})),
	}


func get_transfer_contract() -> Dictionary:
	return {
		"state_snapshot": {
			"rpc": "_receive_tick_state_chunk",
			"mode": TRANSFER_STATE_SNAPSHOT,
			"purpose": "compressed packetized unit/runtime/objective/tactical display state",
			"chunk_payload_budget_bytes": 1000,
			"reassembly_tick_guard": true,
		},
		"vital_delta": {
			"rpc": "_receive_vital_state_updates",
			"mode": TRANSFER_VITAL_DELTA,
			"purpose": "reliable vital special cases",
		},
		"mission_result": {
			"mode": TRANSFER_MISSION_RESULT,
			"purpose": "mission end/debrief state",
		},
		"start_load": {
			"mode": TRANSFER_START_LOAD,
			"purpose": "mission start and load handoff",
		},
	}


func build_serialization_metrics(snapshot: Dictionary) -> Dictionary:
	var json_safe: Variant = _to_json_safe(snapshot)
	var canonical_json: String = JSON.stringify(json_safe)
	var field_counts: Dictionary = _build_field_counts(snapshot)
	var large_payload_offenders: PackedStringArray = _find_large_payload_offenders(snapshot)
	return {
		"json_bytes": canonical_json.to_utf8_buffer().size(),
		"dictionary_count": _count_variant_type(json_safe, TYPE_DICTIONARY),
		"array_count": _count_variant_type(json_safe, TYPE_ARRAY),
		"scalar_count": _count_scalars(json_safe),
		"field_counts": field_counts,
		"large_payload_offenders": large_payload_offenders,
		"asset_reference_policy": "ids_only_no_texture_paths_or_raw_payloads",
		"event_delta_candidate_count": int(field_counts.get("vital_update_count", 0)) + int(field_counts.get("fire_event_count", 0)) + int(field_counts.get("feedback_bubble_count", 0)) + int(field_counts.get("communication_event_count", 0)),
		"canonical_json": canonical_json,
	}


func build_canonical_payload_string(snapshot: Dictionary) -> String:
	return JSON.stringify(_to_json_safe(snapshot))


func _normalize_unit_snapshots(value: Variant) -> Array:
	var result: Array = []
	for entry_variant in _variant_to_array(value):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var unit_id: String = String(entry.get("unit_id", "")).strip_edges()
		if unit_id.is_empty():
			continue
		var unit_snapshot: Dictionary = {
			"unit_id": unit_id,
			"visible": bool(entry.get("visible", true)),
		}
		var ownership: Dictionary = Dictionary(MULTIPLAYER_ROSTER_CONTRACT_SCRIPT.call("normalize_snapshot_unit_ownership", entry))
		for ownership_key in ownership.keys():
			unit_snapshot[ownership_key] = ownership[ownership_key]
		var position: Variant = _coerce_position(entry.get("position", null))
		if position != null:
			unit_snapshot["position"] = position
		_copy_string_if_present(entry, unit_snapshot, "runtime_state")
		_copy_string_if_present(entry, unit_snapshot, "fire_mode")
		_copy_string_if_present(entry, unit_snapshot, "vital_state")
		_copy_string_if_present(entry, unit_snapshot, "team_id")
		_copy_string_if_present(entry, unit_snapshot, "tactical_stance")
		_copy_string_if_present(entry, unit_snapshot, "fireteam_id")
		_copy_string_if_present(entry, unit_snapshot, "active_weapon_id")
		_copy_string_if_present(entry, unit_snapshot, "active_command_type")
		_copy_string_if_present(entry, unit_snapshot, "source_command_type")
		_copy_string_if_present(entry, unit_snapshot, "movement_posture")
		_copy_string_if_present(entry, unit_snapshot, "weapon_posture")
		_copy_string_if_present(entry, unit_snapshot, "posture_policy_id")
		_copy_string_if_present(entry, unit_snapshot, "enemy_security_group_id")
		_copy_string_if_present(entry, unit_snapshot, "enemy_security_mode")
		_copy_string_if_present(entry, unit_snapshot, "enemy_tactics_group_id")
		_copy_string_if_present(entry, unit_snapshot, "enemy_tactic_profile_id")
		_copy_string_if_present(entry, unit_snapshot, "enemy_visual_archetype_id")
		_copy_string_if_present(entry, unit_snapshot, "enemy_advance_style")
		_copy_string_if_present(entry, unit_snapshot, "enemy_role")
		_copy_string_if_present(entry, unit_snapshot, "enemy_tactic_label")
		_copy_string_if_present(entry, unit_snapshot, "enemy_movement_posture")
		_copy_string_if_present(entry, unit_snapshot, "enemy_weapon_posture")
		_copy_string_if_present(entry, unit_snapshot, "enemy_posture_policy_id")
		_copy_int_if_present(entry, unit_snapshot, "health")
		_copy_int_if_present(entry, unit_snapshot, "bleedout_ticks")
		_copy_int_if_present(entry, unit_snapshot, "tactical_stance_revision")
		_copy_int_if_present(entry, unit_snapshot, "weapon_tile_range")
		_copy_float_if_present(entry, unit_snapshot, "weapon_range_world")
		_copy_float_if_present(entry, unit_snapshot, "move_speed_factor")
		_copy_float_if_present(entry, unit_snapshot, "facing_angle")
		_copy_float_if_present(entry, unit_snapshot, "enemy_facing_angle")
		_copy_position_if_present(entry, unit_snapshot, "target_position")
		result.append(unit_snapshot)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("unit_id", "")) < String(b.get("unit_id", ""))
	)
	return result


func _normalize_vital_updates(value: Variant) -> Array:
	var result: Array = []
	for entry_variant in _variant_to_array(value):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var unit_id: String = String(entry.get("unit_id", "")).strip_edges()
		if unit_id.is_empty():
			continue
		var vital_update: Dictionary = {
			"unit_id": unit_id,
			"vital_state": String(entry.get("vital_state", "")).strip_edges(),
			"health": maxi(int(entry.get("health", 0)), 0),
			"bleedout_ticks": maxi(int(entry.get("bleedout_ticks", 0)), 0),
		}
		result.append(vital_update)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("unit_id", "")) < String(b.get("unit_id", ""))
	)
	return result


func _normalize_objective(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var source: Dictionary = Dictionary(value)
	if source.is_empty():
		return {}
	var objective: Dictionary = {
		"owning_team_id": String(source.get("owning_team_id", "")).strip_edges(),
		"capture_progress": clampf(float(source.get("capture_progress", 0.0)), 0.0, 1.0),
		"capturing_team_id": String(source.get("capturing_team_id", "")).strip_edges(),
		"contested": bool(source.get("contested", false)),
	}
	_copy_string_if_present(source, objective, "objective_id")
	var position: Variant = _coerce_position(source.get("position", null))
	if position != null:
		objective["position"] = position
	if source.has("capture_radius"):
		objective["capture_radius"] = maxf(float(source.get("capture_radius", 0.0)), 0.0)
	if source.has("timer_state") or source.has("countdown_seconds"):
		var timer_source: String = String(source.get("timer_source", source.get("source", ""))).strip_edges()
		var timer_state: String = _normalize_timer_state(String(source.get("timer_state", "none")))
		if not timer_source.is_empty() and timer_state != "none":
			var countdown_seconds: float = maxf(float(source.get("countdown_seconds", 0.0)), 0.0)
			objective["countdown_seconds"] = countdown_seconds
			objective["countdown_total_seconds"] = maxf(float(source.get("countdown_total_seconds", countdown_seconds)), countdown_seconds)
			objective["timer_state"] = timer_state
			objective["timer_source"] = timer_source
			objective["source"] = timer_source
			objective["timer_label"] = String(source.get("timer_label", "")).strip_edges()
			objective["urgency"] = _normalize_timer_urgency(String(source.get("urgency", "")), countdown_seconds, float(objective.get("countdown_total_seconds", countdown_seconds)), timer_state)
			objective["visible"] = true
	return objective


func _normalize_timer_state(value: String) -> String:
	match value.strip_edges().to_lower():
		"active", "paused", "expired":
			return value.strip_edges().to_lower()
		_:
			return "none"


func _normalize_timer_urgency(value: String, countdown_seconds: float, total_seconds: float, timer_state: String) -> String:
	match value.strip_edges().to_lower():
		"normal", "warning", "critical", "expired":
			return value.strip_edges().to_lower()
		_:
			if timer_state == "expired" or countdown_seconds <= 0.0:
				return "expired"
			if countdown_seconds <= 10.0:
				return "critical"
			if countdown_seconds <= 30.0 or (total_seconds > 0.0 and countdown_seconds / total_seconds <= 0.25):
				return "warning"
			return "normal"


func _normalize_dropship(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var source: Dictionary = Dictionary(value)
	if source.is_empty():
		return {}
	var dropship: Dictionary = {
		"visible": bool(source.get("visible", source.get("dropship_visible", false))),
		"state": String(source.get("state", source.get("deploy_state", ""))).strip_edges().to_lower(),
		"has_lz": bool(source.get("has_lz", source.get("has_lz_position", false))),
		"air_layer": String(source.get("air_layer", "mission_air")).strip_edges().to_lower(),
		"flight_altitude_clearance": maxf(float(source.get("flight_altitude_clearance", 1.28)), 0.72),
		"terrain_height_independent": true,
		"reveals_unknown_terrain": false,
	}
	var position: Variant = _coerce_position(source.get("position", source.get("dropship_position", null)))
	if position != null:
		dropship["position"] = position
	var target_position: Variant = _coerce_position(source.get("target_position", source.get("dropship_target_position", null)))
	if target_position != null:
		dropship["target_position"] = target_position
	var lz_position: Variant = _coerce_position(source.get("lz_position", null))
	if lz_position != null:
		dropship["lz_position"] = lz_position
	_copy_float_if_present(source, dropship, "progress")
	_copy_string_if_present(source, dropship, "team_id")
	return dropship


func _normalize_contacts(value: Variant) -> Array:
	var result: Array = []
	for entry_variant in _variant_to_array(value):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = Dictionary(entry_variant)
		var contact: Dictionary = {}
		_copy_string_if_present(source, contact, "fireteam_id")
		_copy_string_if_present(source, contact, "unit_id")
		_copy_string_if_present(source, contact, "team_id")
		_copy_string_if_present(source, contact, "detection_state")
		_copy_int_if_present(source, contact, "last_seen_tick")
		var last_known_position: Variant = _coerce_position(source.get("last_known_position", null))
		if last_known_position != null:
			contact["last_known_position"] = last_known_position
		if not contact.is_empty():
			result.append(contact)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _sort_key(a, ["fireteam_id", "unit_id", "team_id"]) < _sort_key(b, ["fireteam_id", "unit_id", "team_id"])
	)
	return result


func _normalize_enemy_security(value: Variant) -> Array:
	var result: Array = []
	for entry_variant in _variant_to_array(value):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = Dictionary(entry_variant)
		var entry: Dictionary = {}
		_copy_string_if_present(source, entry, "security_group_id")
		_copy_string_if_present(source, entry, "fireteam_id")
		_copy_string_if_present(source, entry, "team_id")
		_copy_string_if_present(source, entry, "profile_id")
		_copy_string_if_present(source, entry, "security_mode")
		_copy_string_if_present(source, entry, "facing")
		_copy_string_if_present(source, entry, "watch_label")
		_copy_float_if_present(source, entry, "facing_angle")
		_copy_float_if_present(source, entry, "direction_angle")
		_copy_float_if_present(source, entry, "sector_width")
		_copy_position_if_present(source, entry, "anchor_position")
		_copy_position_if_present(source, entry, "focus_position")
		entry["unit_ids"] = _normalize_string_array(source.get("unit_ids", []))
		entry["watched_unit_ids"] = _normalize_string_array(source.get("watched_unit_ids", []))
		entry["member_assignments"] = _normalize_enemy_security_assignments(source.get("member_assignments", []))
		if not String(entry.get("security_group_id", "")).is_empty():
			result.append(entry)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _sort_key(a, ["security_group_id", "fireteam_id", "team_id", "profile_id"]) < _sort_key(b, ["security_group_id", "fireteam_id", "team_id", "profile_id"])
	)
	return result


func _normalize_enemy_security_assignments(value: Variant) -> Array:
	var result: Array = []
	for assignment_variant in _variant_to_array(value):
		if typeof(assignment_variant) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = Dictionary(assignment_variant)
		var assignment: Dictionary = {}
		_copy_string_if_present(source, assignment, "unit_id")
		_copy_string_if_present(source, assignment, "weapon_id")
		_copy_float_if_present(source, assignment, "center_angle")
		_copy_float_if_present(source, assignment, "arc_width")
		_copy_int_if_present(source, assignment, "weapon_tile_range")
		_copy_float_if_present(source, assignment, "weapon_range_world")
		if not String(assignment.get("unit_id", "")).is_empty():
			result.append(assignment)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _sort_key(a, ["unit_id", "weapon_id"]) < _sort_key(b, ["unit_id", "weapon_id"])
	)
	return result


func _normalize_enemy_team_tactics(value: Variant) -> Array:
	var result: Array = []
	for entry_variant in _variant_to_array(value):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = Dictionary(entry_variant)
		var entry: Dictionary = {}
		_copy_string_if_present(source, entry, "security_group_id")
		_copy_string_if_present(source, entry, "team_id")
		_copy_string_if_present(source, entry, "profile_id")
		_copy_string_if_present(source, entry, "visual_archetype")
		_copy_string_if_present(source, entry, "advance_style")
		_copy_string_if_present(source, entry, "cover_behavior")
		_copy_string_if_present(source, entry, "tactic_label")
		_copy_string_if_present(source, entry, "movement_posture_policy")
		_copy_position_if_present(source, entry, "anchor_position")
		_copy_position_if_present(source, entry, "focus_position")
		_copy_position_if_present(source, entry, "advance_direction")
		_copy_int_if_present(source, entry, "priority")
		_copy_float_if_present(source, entry, "move_speed_factor")
		_copy_float_if_present(source, entry, "ready_distance_world")
		_copy_float_if_present(source, entry, "travel_speed_factor")
		_copy_float_if_present(source, entry, "ready_speed_factor")
		_copy_float_if_present(source, entry, "aim_move_speed_factor")
		entry["unit_ids"] = _normalize_string_array(source.get("unit_ids", []))
		entry["moving_unit_ids"] = _normalize_string_array(source.get("moving_unit_ids", []))
		entry["covering_unit_ids"] = _normalize_string_array(source.get("covering_unit_ids", []))
		entry["role_by_unit_id"] = _normalize_string_dictionary(source.get("role_by_unit_id", {}))
		entry["movement_posture_by_unit_id"] = _normalize_string_dictionary(source.get("movement_posture_by_unit_id", {}))
		entry["weapon_posture_by_unit_id"] = _normalize_string_dictionary(source.get("weapon_posture_by_unit_id", {}))
		entry["posture_policy_by_unit_id"] = _normalize_string_dictionary(source.get("posture_policy_by_unit_id", {}))
		entry["move_speed_factor_by_unit_id"] = _normalize_float_dictionary(source.get("move_speed_factor_by_unit_id", {}))
		entry["target_positions_by_unit_id"] = _normalize_position_dictionary(source.get("target_positions_by_unit_id", {}))
		if not String(entry.get("security_group_id", "")).is_empty():
			result.append(entry)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _sort_key(a, ["security_group_id", "team_id", "profile_id"]) < _sort_key(b, ["security_group_id", "team_id", "profile_id"])
	)
	return result


func _normalize_fire_events(value: Variant) -> Array:
	var by_event_id: Dictionary = {}
	for entry_variant in _variant_to_array(value):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = Dictionary(entry_variant)
		var event: Dictionary = {}
		_copy_string_if_present(source, event, "event_id")
		_copy_string_if_present(source, event, "event_type")
		_copy_string_if_present(source, event, "source")
		_copy_string_if_present(source, event, "attacker_unit_id")
		_copy_string_if_present(source, event, "attacker_team_id")
		_copy_string_if_present(source, event, "target_unit_id")
		_copy_string_if_present(source, event, "target_team_id")
		_copy_string_if_present(source, event, "weapon_id")
		_copy_string_if_present(source, event, "muzzle_id")
		_copy_string_if_present(source, event, "visibility_context")
		_copy_int_if_present(source, event, "tick")
		_copy_int_if_present(source, event, "sequence")
		_copy_int_if_present(source, event, "weapon_tile_range")
		_copy_float_if_present(source, event, "weapon_range_world")
		_copy_bool_if_present(source, event, "visible_to_local")
		_copy_position_if_present(source, event, "attacker_position")
		_copy_position_if_present(source, event, "target_position")
		_copy_position_if_present(source, event, "muzzle_position")
		var event_id: String = String(event.get("event_id", "")).strip_edges()
		if not event_id.is_empty():
			_store_deterministic_by_id(by_event_id, event_id, event)
	var result: Array = []
	for event_id_variant in by_event_id.keys():
		result.append(by_event_id[event_id_variant])
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _event_sort_key(a) < _event_sort_key(b)
	)
	return result


func _normalize_character_gameplay(value: Variant) -> Array:
	var result: Array = []
	for entry_variant in _variant_to_array(value):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = Dictionary(entry_variant)
		var fireteam_id: String = String(source.get("fireteam_id", "")).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		var entry: Dictionary = {
			"source": String(source.get("source", "character_gameplay_resolver")).strip_edges(),
			"fireteam_id": fireteam_id,
			"cohesion_label": String(source.get("cohesion_label", "")).strip_edges(),
			"cohesion_percent": clampi(int(source.get("cohesion_percent", 0)), 0, 100),
			"morale_state": String(source.get("morale_state", "")).strip_edges(),
			"frustration_state": String(source.get("frustration_state", "")).strip_edges(),
			"communication_label": String(source.get("communication_label", "")).strip_edges(),
			"member_count": maxi(int(source.get("member_count", 0)), 0),
		}
		result.append(entry)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("fireteam_id", "")) < String(b.get("fireteam_id", ""))
	)
	return result


func _normalize_feedback_bubbles(value: Variant) -> Array:
	var result: Array = []
	for entry_variant in _variant_to_array(value):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = Dictionary(entry_variant)
		var bubble: Dictionary = {}
		_copy_string_if_present(source, bubble, "event_id")
		_copy_string_if_present(source, bubble, "bubble_id")
		_copy_string_if_present(source, bubble, "unit_id")
		_copy_string_if_present(source, bubble, "fireteam_id")
		_copy_string_if_present(source, bubble, "team_id")
		_copy_string_if_present(source, bubble, "category")
		_copy_string_if_present(source, bubble, "source")
		_copy_string_if_present(source, bubble, "text_key")
		_copy_string_if_present(source, bubble, "role_text_key")
		_copy_string_if_present(source, bubble, "situation_key")
		_copy_string_if_present(source, bubble, "thought_kind")
		_copy_string_if_present(source, bubble, "skill_tier")
		_copy_position_if_present(source, bubble, "anchor_position")
		_copy_int_if_present(source, bubble, "tick")
		_copy_int_if_present(source, bubble, "sequence")
		_copy_float_if_present(source, bubble, "duration_seconds")
		if not String(bubble.get("bubble_id", "")).is_empty():
			result.append(bubble)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _bubble_sort_key(a) < _bubble_sort_key(b)
	)
	return result


func _normalize_fireteam_tactical(value: Variant) -> Array:
	var result: Array = []
	for entry_variant in _variant_to_array(value):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = Dictionary(entry_variant)
		var fireteam_id: String = String(source.get("fireteam_id", "")).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		var entry: Dictionary = {
			"schema_version": maxi(int(source.get("schema_version", 1)), 1),
			"fireteam_id": fireteam_id,
			"unit_id": String(source.get("unit_id", source.get("leader_unit_id", ""))).strip_edges(),
			"plan_quality": clampf(float(source.get("plan_quality", 0.5)), 0.0, 1.0),
			"communication_clarity": clampf(float(source.get("communication_clarity", 0.5)), 0.0, 1.0),
			"breakout_judgement": clampf(float(source.get("breakout_judgement", 0.5)), 0.0, 1.0),
			"spacing_quality": clampf(float(source.get("spacing_quality", 0.5)), 0.0, 1.0),
			"contact_report_quality": clampf(float(source.get("contact_report_quality", 0.5)), 0.0, 1.0),
			"reaction_delay_seconds": clampf(float(source.get("reaction_delay_seconds", 0.35)), 0.05, 0.85),
			"tempo_modifier": clampf(float(source.get("tempo_modifier", 1.0)), 0.86, 1.14),
			"effect_label": String(source.get("effect_label", "developing_ftl")).strip_edges().to_lower(),
		}
		result.append(entry)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _sort_key(a, ["fireteam_id", "unit_id"]) < _sort_key(b, ["fireteam_id", "unit_id"])
	)
	return result


func _normalize_commander_intents(value: Variant) -> Array:
	var result: Array = []
	for entry_variant in _variant_to_array(value):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = Dictionary(entry_variant)
		var command_id: String = String(source.get("command_id", source.get("intent_id", ""))).strip_edges()
		if command_id.is_empty():
			continue
		var entry: Dictionary = {
			"command_id": command_id,
			"team_id": String(source.get("team_id", "")).strip_edges(),
			"fireteam_id": String(source.get("fireteam_id", "")).strip_edges().to_lower(),
			"verb": String(source.get("verb", source.get("command_type", ""))).strip_edges().to_lower(),
			"priority": int(source.get("priority", 0)),
			"tempo": String(source.get("tempo", "normal")).strip_edges().to_lower(),
			"fire_rule": String(source.get("fire_rule", source.get("fire_status", "return"))).strip_edges().to_lower(),
			"contact_response": String(source.get("contact_response", "report")).strip_edges().to_lower(),
			"risk": String(source.get("risk", "normal")).strip_edges().to_lower(),
			"cover_priority": String(source.get("cover_priority", "normal")).strip_edges().to_lower(),
			"security_mode": String(source.get("security_mode", "facing")).strip_edges().to_lower(),
			"phase": int(source.get("phase", -1)),
			"ui_sets_gameplay_truth": false,
		}
		var intent_warnings: PackedStringArray = _normalize_string_array(source.get("normalization_warnings", Dictionary(source.get("metadata", {})).get("normalization_warnings", [])))
		if not intent_warnings.is_empty():
			entry["normalization_warnings"] = intent_warnings
		_copy_string_if_present(source, entry, "target_area_id")
		_copy_string_if_present(source, entry, "sync_group_id")
		_copy_position_if_present(source, entry, "target_position")
		entry["coordinated_fireteam_ids"] = _normalize_string_array(source.get("coordinated_fireteam_ids", source.get("fireteam_ids", [])))
		result.append(entry)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _sort_key(a, ["command_id", "fireteam_id", "team_id"]) < _sort_key(b, ["command_id", "fireteam_id", "team_id"])
	)
	return result


func _normalize_fireteam_plan_status(value: Variant) -> Array:
	var result: Array = []
	for entry_variant in _variant_to_array(value):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = Dictionary(entry_variant)
		var plan_id: String = String(source.get("plan_id", "")).strip_edges()
		var fireteam_id: String = String(source.get("fireteam_id", "")).strip_edges().to_lower()
		if plan_id.is_empty() or fireteam_id.is_empty():
			continue
		var entry: Dictionary = {
			"plan_id": plan_id,
			"command_id": String(source.get("command_id", "")).strip_edges(),
			"fireteam_id": fireteam_id,
			"team_id": String(source.get("team_id", "")).strip_edges(),
			"phase": int(source.get("phase", -1)),
			"ftl_response": String(source.get("ftl_response", source.get("status_response", ""))).strip_edges().to_lower(),
			"movement_style": String(source.get("movement_style", "")).strip_edges().to_lower(),
			"security_mode": String(source.get("security_mode", "")).strip_edges().to_lower(),
			"route_bias": String(source.get("route_bias", "")).strip_edges().to_lower(),
			"communication_state": String(source.get("communication_state", "")).strip_edges().to_lower(),
			"planning_quality": clampf(float(source.get("planning_quality", source.get("plan_quality", 0.5))), 0.0, 1.0),
			"communication_clarity": clampf(float(source.get("communication_clarity", 0.5)), 0.0, 1.0),
			"breakout_judgement": clampf(float(source.get("breakout_judgement", 0.5)), 0.0, 1.0),
			"runtime_authority": "SimulationRoot",
			"ui_sets_gameplay_truth": false,
		}
		_copy_string_if_present(source, entry, "coordination_plan_id")
		_copy_string_if_present(source, entry, "coordination_role")
		_copy_string_if_present(source, entry, "target_area_id")
		_copy_float_if_present(source, entry, "expected_duration_seconds")
		_copy_position_if_present(source, entry, "target_position")
		entry["allowed_breakout_classes"] = _normalize_string_array(source.get("allowed_breakout_classes", []))
		result.append(entry)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _sort_key(a, ["plan_id", "fireteam_id", "command_id"]) < _sort_key(b, ["plan_id", "fireteam_id", "command_id"])
	)
	return result


func _normalize_communication_events(value: Variant) -> Array:
	var by_event_id: Dictionary = {}
	for entry_variant in _variant_to_array(value):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = Dictionary(entry_variant)
		var event_id: String = String(source.get("event_id", "")).strip_edges()
		if event_id.is_empty():
			continue
		var event: Dictionary = {
			"event_id": event_id,
			"event_type": String(source.get("event_type", source.get("type", ""))).strip_edges().to_lower(),
			"source": String(source.get("source", "tactical_communication_feedback")).strip_edges(),
			"priority": int(source.get("priority", 0)),
			"phase": int(source.get("phase", 0)),
			"is_critical": bool(source.get("is_critical", false)),
			"has_map_marker": bool(source.get("has_map_marker", false)),
			"has_bubble": bool(source.get("has_bubble", false)),
			"ui_sets_gameplay_truth": false,
		}
		for string_key in ["plan_id", "fireteam_id", "unit_id", "team_id", "feedback_action", "feedback_state", "short_label", "text_key"]:
			_copy_string_if_present(source, event, string_key)
		_copy_int_if_present(source, event, "tick")
		_copy_int_if_present(source, event, "sequence")
		_copy_float_if_present(source, event, "duration_seconds")
		_copy_position_if_present(source, event, "anchor_position")
		event["channels"] = _normalize_string_array(source.get("channels", []))
		event["metadata_keys"] = _normalize_string_array(source.get("metadata_keys", []))
		_store_deterministic_by_id(by_event_id, event_id, event)
	var keys: Array = by_event_id.keys()
	keys.sort()
	var result: Array = []
	for key_variant in keys:
		result.append(by_event_id[key_variant])
	return result


func _normalize_tactical_rules(value: Variant) -> Array:
	var entries: Array = []
	if typeof(value) == TYPE_DICTIONARY:
		var source_dict: Dictionary = Dictionary(value)
		if _looks_like_rule_entry(source_dict):
			entries.append(source_dict)
		else:
			var keys: Array = source_dict.keys()
			keys.sort()
			for key_variant in keys:
				var nested: Variant = source_dict.get(key_variant)
				if typeof(nested) != TYPE_DICTIONARY:
					continue
				var entry: Dictionary = Dictionary(nested).duplicate(true)
				entry["fireteam_id"] = String(entry.get("fireteam_id", key_variant)).strip_edges().to_lower()
				entries.append(entry)
	else:
		entries = _variant_to_array(value)
	var result: Array = []
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = Dictionary(entry_variant)
		var entry: Dictionary = {
			"fireteam_id": String(source.get("fireteam_id", "")).strip_edges().to_lower(),
			"team_id": String(source.get("team_id", "")).strip_edges(),
			"tempo": String(source.get("tempo", "normal")).strip_edges().to_lower(),
			"fire_rule": String(source.get("fire_rule", "return")).strip_edges().to_lower(),
			"contact_response": String(source.get("contact_response", "report")).strip_edges().to_lower(),
			"cover_priority": String(source.get("cover_priority", "normal")).strip_edges().to_lower(),
			"security_mode": String(source.get("security_mode", "facing")).strip_edges().to_lower(),
			"risk": String(source.get("risk", "normal")).strip_edges().to_lower(),
			"normalized_from_conflict": bool(source.get("normalized_from_conflict", false)),
			"ui_sets_gameplay_truth": false,
		}
		if source.has("revision"):
			entry["revision"] = maxi(int(source.get("revision", 0)), 0)
		if source.has("runtime_authority"):
			entry["runtime_authority"] = String(source.get("runtime_authority", "SimulationRoot")).strip_edges()
		if source.has("read_only"):
			entry["read_only"] = bool(source.get("read_only", true))
		_copy_string_if_present(source, entry, "command_id")
		_copy_string_if_present(source, entry, "sync_group_id")
		entry["warnings"] = _normalize_string_array(source.get("warnings", []))
		if not String(entry.get("fireteam_id", "")).is_empty() or not String(entry.get("command_id", "")).is_empty():
			result.append(entry)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _sort_key(a, ["fireteam_id", "command_id", "team_id"]) < _sort_key(b, ["fireteam_id", "command_id", "team_id"])
	)
	return result


func _normalize_breakout_states(value: Variant) -> Array:
	var by_breakout_id: Dictionary = {}
	for entry_variant in _variant_to_array(value):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = Dictionary(entry_variant)
		var breakout_id: String = String(source.get("breakout_id", "")).strip_edges()
		if breakout_id.is_empty():
			continue
		var entry: Dictionary = {
			"breakout_id": breakout_id,
			"event_id": String(source.get("event_id", "")).strip_edges(),
			"plan_id": String(source.get("plan_id", "")).strip_edges(),
			"command_id": String(source.get("command_id", "")).strip_edges(),
			"fireteam_id": String(source.get("fireteam_id", "")).strip_edges().to_lower(),
			"phase": int(source.get("phase", 0)),
			"trigger": String(source.get("trigger", "")).strip_edges().to_lower(),
			"breakout_class": String(source.get("breakout_class", "")).strip_edges().to_lower(),
			"status": String(source.get("status", "")).strip_edges().to_lower(),
			"communication_event_type": String(source.get("communication_event_type", "")).strip_edges().to_lower(),
			"priority": int(source.get("priority", 0)),
			"requires_player_response": bool(source.get("requires_player_response", false)),
			"return_to_plan_allowed": bool(source.get("return_to_plan_allowed", false)),
			"resolved": bool(source.get("resolved", false)),
			"runtime_authority": "SimulationRoot",
			"ui_sets_gameplay_truth": false,
		}
		for string_key in ["cause_label", "short_label", "commander_rule_resolution", "ftl_skill_tier"]:
			_copy_string_if_present(source, entry, string_key)
		_copy_float_if_present(source, entry, "breakout_judgement")
		_copy_float_if_present(source, entry, "communication_clarity")
		_copy_float_if_present(source, entry, "detection_delay_seconds")
		_copy_position_if_present(source, entry, "anchor_position")
		_copy_position_if_present(source, entry, "target_position")
		entry["player_options"] = _normalize_string_array(source.get("player_options", []))
		_store_deterministic_by_id(by_breakout_id, breakout_id, entry)
	var keys: Array = by_breakout_id.keys()
	keys.sort()
	var result: Array = []
	for key_variant in keys:
		result.append(by_breakout_id[key_variant])
	return result


func _normalize_air_asset_statuses(value: Variant) -> Array:
	var by_asset_id: Dictionary = {}
	for entry_variant in _variant_to_array(value):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = Dictionary(entry_variant)
		var asset_id: String = String(source.get("asset_id", "")).strip_edges()
		if asset_id.is_empty():
			continue
		var entry: Dictionary = {
			"asset_id": asset_id,
			"asset_type": String(source.get("asset_type", "dropship")).strip_edges().to_lower(),
			"display_name": String(source.get("display_name", "")).strip_edges(),
			"state": String(source.get("state", "intact")).strip_edges().to_lower(),
			"integrity": clampi(int(source.get("integrity", 100)), 0, maxi(int(source.get("max_integrity", 100)), 1)),
			"max_integrity": maxi(int(source.get("max_integrity", 100)), 1),
			"risk": clampf(float(source.get("risk", 0.0)), 0.0, 1.0),
			"lz_secure_level": clampf(float(source.get("lz_secure_level", 0.0)), 0.0, 1.0),
			"enemy_at_pressure": clampf(float(source.get("enemy_at_pressure", 0.0)), 0.0, 1.0),
			"warning_visible": bool(source.get("warning_visible", false)),
			"destroyed": bool(source.get("destroyed", false)),
			"crashed": bool(source.get("crashed", false)),
			"recovering": bool(source.get("recovering", false)),
			"unavailable": bool(source.get("unavailable", false)),
			"warning_state": bool(source.get("warning_state", false)),
			"damage_state": bool(source.get("damage_state", false)),
			"terminal_state": bool(source.get("terminal_state", false)),
			"runtime_authority": "SimulationRoot",
			"ui_sets_gameplay_truth": false,
		}
		for string_key in ["locked_by_unit_id", "threat_weapon_id", "last_event_id", "last_reason"]:
			_copy_string_if_present(source, entry, string_key)
		var status_warnings: PackedStringArray = _normalize_string_array(source.get("normalization_warnings", Dictionary(source.get("metadata", {})).get("normalization_warnings", [])))
		if not status_warnings.is_empty():
			entry["normalization_warnings"] = status_warnings
		_copy_float_if_present(source, entry, "integrity_ratio")
		_copy_position_if_present(source, entry, "position")
		entry["vfx_events"] = _normalize_status_event_list(source.get("vfx_events", []), asset_id, "vfx")
		entry["sfx_events"] = _normalize_status_event_list(source.get("sfx_events", []), asset_id, "sfx")
		_store_deterministic_by_id(by_asset_id, asset_id, entry)
	var keys: Array = by_asset_id.keys()
	keys.sort()
	var result: Array = []
	for key_variant in keys:
		result.append(by_asset_id[key_variant])
	return result


func _normalize_mission_result(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var source: Dictionary = Dictionary(value)
	if source.is_empty():
		return {}
	var mission_result: Dictionary = {}
	_copy_string_if_present(source, mission_result, "result")
	_copy_string_if_present(source, mission_result, "winning_team_id")
	_copy_string_if_present(source, mission_result, "friendly_team_id")
	_copy_string_if_present(source, mission_result, "win_condition_type")
	_copy_string_if_present(source, mission_result, "result_condition")
	_copy_float_if_present(source, mission_result, "duration_seconds")
	if source.has("objective_captured"):
		mission_result["objective_captured"] = bool(source.get("objective_captured", false))
	if source.has("team_states"):
		mission_result["team_states"] = _variant_to_array(source.get("team_states", [])).duplicate(true)
	return mission_result


func _looks_like_rule_entry(source: Dictionary) -> bool:
	for key in ["tempo", "fire_rule", "contact_response", "cover_priority", "security_mode", "risk", "command_id"]:
		if source.has(key):
			return true
	return false


func _store_deterministic_by_id(target: Dictionary, stable_id: String, entry: Dictionary) -> void:
	if not target.has(stable_id):
		target[stable_id] = entry
		return
	var existing: Dictionary = Dictionary(target.get(stable_id, {}))
	var existing_json: String = JSON.stringify(_to_json_safe(existing))
	var next_json: String = JSON.stringify(_to_json_safe(entry))
	if next_json < existing_json:
		target[stable_id] = entry


func _normalize_status_event_list(value: Variant, asset_id: String, event_kind: String) -> Array:
	var by_event_id: Dictionary = {}
	var sequence: int = 0
	for event_variant in _variant_to_array(value):
		var event: Dictionary = {}
		if typeof(event_variant) == TYPE_DICTIONARY:
			var source: Dictionary = Dictionary(event_variant)
			var event_id: String = String(source.get("event_id", source.get("%s_id" % event_kind, ""))).strip_edges()
			if event_id.is_empty():
				event_id = "%s:%s:%d" % [asset_id, event_kind, sequence]
			event = {
				"event_id": event_id,
				"event_type": String(source.get("event_type", event_kind)).strip_edges().to_lower(),
				"asset_id": String(source.get("asset_id", asset_id)).strip_edges(),
				"source": String(source.get("source", "air_asset_status")).strip_edges(),
			}
			_copy_string_if_present(source, event, "resource_id")
			_copy_string_if_present(source, event, "cue_id")
			_copy_string_if_present(source, event, "visibility_context")
			_copy_int_if_present(source, event, "tick")
			_copy_int_if_present(source, event, "sequence")
			_copy_position_if_present(source, event, "position")
			_store_deterministic_by_id(by_event_id, event_id, event)
		else:
			var token: String = String(event_variant).strip_edges()
			if token.is_empty():
				sequence += 1
				continue
			var event_id: String = "%s:%s:%s" % [asset_id, event_kind, token]
			_store_deterministic_by_id(by_event_id, event_id, {
				"event_id": event_id,
				"event_type": event_kind,
				"asset_id": asset_id,
				"resource_id": token,
				"source": "air_asset_status",
			})
		sequence += 1
	var keys: Array = by_event_id.keys()
	keys.sort()
	var result: Array = []
	for key_variant in keys:
		result.append(by_event_id[key_variant])
	return result


func _variant_to_array(value: Variant) -> Array:
	if value is Array:
		return Array(value)
	if value is PackedStringArray:
		var result: Array = []
		for entry in PackedStringArray(value):
			result.append(String(entry))
		return result
	return []


func _normalize_string_array(value: Variant) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for entry_variant in _variant_to_array(value):
		var entry: String = String(entry_variant).strip_edges()
		if not entry.is_empty() and not result.has(entry):
			result.append(entry)
	result.sort()
	return result


func _normalize_string_dictionary(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var result: Dictionary = {}
	var source: Dictionary = Dictionary(value)
	var keys: Array = source.keys()
	keys.sort()
	for key_variant in keys:
		var key: String = String(key_variant).strip_edges()
		if key.is_empty():
			continue
		result[key] = String(source.get(key_variant, "")).strip_edges()
	return result


func _normalize_float_dictionary(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var result: Dictionary = {}
	var source: Dictionary = Dictionary(value)
	var keys: Array = source.keys()
	keys.sort()
	for key_variant in keys:
		var key: String = String(key_variant).strip_edges()
		if key.is_empty():
			continue
		result[key] = float(source.get(key_variant, 0.0))
	return result


func _normalize_position_dictionary(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var result: Dictionary = {}
	var source: Dictionary = Dictionary(value)
	var keys: Array = source.keys()
	keys.sort()
	for key_variant in keys:
		var key: String = String(key_variant).strip_edges()
		if key.is_empty():
			continue
		var position: Variant = _coerce_position(source.get(key_variant, null))
		if position != null:
			result[key] = position
	return result


func _coerce_position(value: Variant) -> Variant:
	var value_type: int = typeof(value)
	if value_type == TYPE_VECTOR2 or value_type == TYPE_VECTOR3:
		return value
	if value_type == TYPE_VECTOR2I:
		return Vector2(value.x, value.y)
	if value_type == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(value)
		if dict.has("z"):
			return Vector3(float(dict.get("x", 0.0)), float(dict.get("y", 0.0)), float(dict.get("z", 0.0)))
		return Vector2(float(dict.get("x", 0.0)), float(dict.get("y", 0.0)))
	return null


func _copy_string_if_present(source: Dictionary, target: Dictionary, key: String) -> void:
	if not source.has(key):
		return
	target[key] = String(source.get(key, "")).strip_edges()


func _copy_int_if_present(source: Dictionary, target: Dictionary, key: String) -> void:
	if not source.has(key):
		return
	target[key] = int(source.get(key, 0))


func _copy_float_if_present(source: Dictionary, target: Dictionary, key: String) -> void:
	if not source.has(key):
		return
	target[key] = float(source.get(key, 0.0))


func _copy_bool_if_present(source: Dictionary, target: Dictionary, key: String) -> void:
	if not source.has(key):
		return
	target[key] = bool(source.get(key, false))


func _copy_position_if_present(source: Dictionary, target: Dictionary, key: String) -> void:
	if not source.has(key):
		return
	var position: Variant = _coerce_position(source.get(key, null))
	if position != null:
		target[key] = position


func _reject(reason: String) -> Dictionary:
	return {
		"accepted": false,
		"reason": reason,
	}


func _sort_key(entry: Dictionary, keys: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for key_variant in keys:
		parts.append(String(entry.get(String(key_variant), "")).strip_edges())
	return "|".join(parts)


func _event_sort_key(entry: Dictionary) -> String:
	return "%010d|%010d|%s" % [
		int(entry.get("tick", 0)),
		int(entry.get("sequence", 0)),
		String(entry.get("event_id", "")),
	]


func _bubble_sort_key(entry: Dictionary) -> String:
	return "%010d|%010d|%s|%s|%s" % [
		int(entry.get("tick", 0)),
		int(entry.get("sequence", 0)),
		String(entry.get("bubble_id", "")),
		String(entry.get("unit_id", "")),
		String(entry.get("event_id", "")),
	]


func _build_field_counts(snapshot: Dictionary) -> Dictionary:
	return {
		"unit_count": Array(snapshot.get("units", [])).size(),
		"vital_update_count": Array(snapshot.get("vital_updates", [])).size(),
		"contact_count": Array(snapshot.get("contacts", [])).size(),
		"enemy_security_count": Array(snapshot.get("enemy_security", [])).size(),
		"enemy_team_tactics_count": Array(snapshot.get("enemy_team_tactics", [])).size(),
		"character_gameplay_count": Array(snapshot.get("character_gameplay", [])).size(),
		"fire_event_count": Array(snapshot.get("fire_events", [])).size(),
		"feedback_bubble_count": Array(snapshot.get("feedback_bubbles", [])).size(),
		"fireteam_tactical_count": Array(snapshot.get("fireteam_tactical", [])).size(),
		"commander_intent_count": Array(snapshot.get("commander_intents", [])).size(),
		"fireteam_plan_status_count": Array(snapshot.get("fireteam_plan_status", [])).size(),
		"communication_event_count": Array(snapshot.get("communication_events", [])).size(),
		"tactical_rules_count": Array(snapshot.get("tactical_rules", [])).size(),
		"breakout_state_count": Array(snapshot.get("breakout_states", [])).size(),
		"air_asset_status_count": Array(snapshot.get("air_asset_status", [])).size(),
		"has_objective": not Dictionary(snapshot.get("objective", {})).is_empty(),
		"has_dropship": not Dictionary(snapshot.get("dropship", {})).is_empty(),
		"has_mission_result": not Dictionary(snapshot.get("mission_result", {})).is_empty(),
	}


func _find_large_payload_offenders(value: Variant, path: String = "$") -> PackedStringArray:
	var offenders: PackedStringArray = PackedStringArray()
	if typeof(value) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(value)
		for key_variant in dict.keys():
			var key: String = String(key_variant)
			var lower_key: String = key.to_lower()
			var child_path: String = "%s.%s" % [path, key]
			if ["path", "asset_path", "texture", "texture_path", "image", "image_path", "raw_payload", "bytes", "text"].has(lower_key):
				offenders.append(child_path)
			offenders.append_array(_find_large_payload_offenders(dict.get(key_variant), child_path))
	elif value is Array:
		var array_value: Array = Array(value)
		for index in range(array_value.size()):
			offenders.append_array(_find_large_payload_offenders(array_value[index], "%s[%d]" % [path, index]))
	return offenders


func _to_json_safe(value: Variant) -> Variant:
	var value_type: int = typeof(value)
	if value_type == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(value)
		var result: Dictionary = {}
		var keys: Array = dict.keys()
		keys.sort_custom(func(a, b) -> bool:
			return String(a) < String(b)
		)
		for key_variant in keys:
			result[String(key_variant)] = _to_json_safe(dict.get(key_variant))
		return result
	if value is Array:
		var array_result: Array = []
		for entry_variant in Array(value):
			array_result.append(_to_json_safe(entry_variant))
		return array_result
	if value is PackedStringArray:
		var string_array: Array = []
		for entry in PackedStringArray(value):
			string_array.append(String(entry))
		return string_array
	if value_type == TYPE_VECTOR2:
		return {"x": snappedf(value.x, 0.001), "y": snappedf(value.y, 0.001)}
	if value_type == TYPE_VECTOR2I:
		return {"x": int(value.x), "y": int(value.y)}
	if value_type == TYPE_VECTOR3:
		return {"x": snappedf(value.x, 0.001), "y": snappedf(value.y, 0.001), "z": snappedf(value.z, 0.001)}
	return value


func _count_variant_type(value: Variant, target_type: int) -> int:
	var count: int = 1 if typeof(value) == target_type else 0
	if typeof(value) == TYPE_DICTIONARY:
		for child_variant in Dictionary(value).values():
			count += _count_variant_type(child_variant, target_type)
	elif value is Array:
		for child_variant in Array(value):
			count += _count_variant_type(child_variant, target_type)
	return count


func _count_scalars(value: Variant) -> int:
	if typeof(value) == TYPE_DICTIONARY:
		var total: int = 0
		for child_variant in Dictionary(value).values():
			total += _count_scalars(child_variant)
		return total
	if value is Array:
		var total: int = 0
		for child_variant in Array(value):
			total += _count_scalars(child_variant)
		return total
	return 1
