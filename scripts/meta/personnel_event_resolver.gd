class_name PersonnelEventResolver
extends RefCounted

const PERSONNEL_EVENT_MODEL_SCRIPT: GDScript = preload("res://scripts/meta/personnel_event_model.gd")
const START_ROSTER_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/start_roster_generator.gd")
const ROSTER_RELATIONSHIP_MODEL_SCRIPT: GDScript = preload("res://scripts/meta/roster_relationship_model.gd")
const FIRETEAM_COHESION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/fireteam_cohesion_resolver.gd")

const DEFAULT_RECRUIT_AFTER_MISSIONS: int = 3
const FRUSTRATION_REQUEST_THRESHOLD: float = 0.70
const MAX_PERSONNEL_EVENTS: int = 32


static func evaluate_roster(roster: Dictionary, options: Dictionary = {}) -> Dictionary:
	var updated_roster: Dictionary = roster.duplicate(true)
	var existing_events: Array = _normalize_event_array(updated_roster.get("personnel_events", []))
	var new_events: Array = []
	var units: Array = _normalize_units(updated_roster.get("units", []))
	var recruit_after_missions: int = maxi(int(options.get("recruit_after_missions", DEFAULT_RECRUIT_AFTER_MISSIONS)), 1)
	var max_missions_completed: int = _max_missions_completed(units)
	if max_missions_completed >= recruit_after_missions:
		var milestone: String = "missions_completed_%d" % recruit_after_missions
		if not _event_exists(existing_events, PERSONNEL_EVENT_MODEL_SCRIPT.EVENT_RECRUIT_AVAILABLE, "", milestone):
			var candidate: Dictionary = build_recruit_candidate(updated_roster, "%s_%s" % [String(updated_roster.get("seed", "roster")), milestone])
			if not candidate.is_empty():
				var candidate_name: String = String(candidate.get("display_name", candidate.get("unit_id", "Recruit"))).strip_edges()
				new_events.append(PERSONNEL_EVENT_MODEL_SCRIPT.call("make_event",
					PERSONNEL_EVENT_MODEL_SCRIPT.EVENT_RECRUIT_AVAILABLE,
					"",
					candidate_name,
					"%s ist nach %d Einsaetzen als Kandidat verfuegbar." % [candidate_name, recruit_after_missions],
					{
						"trigger": milestone,
						"milestone": milestone,
						"candidate_unit_id": String(candidate.get("unit_id", "")).strip_edges(),
						"candidate_display_name": candidate_name,
						"candidate": candidate,
					},
					false
				))
	for unit_variant in units:
		var unit: Dictionary = Dictionary(unit_variant)
		var unit_id: String = String(unit.get("unit_id", "")).strip_edges().to_lower()
		if unit_id.is_empty():
			continue
		var display_name: String = String(unit.get("display_name", unit_id)).strip_edges()
		var progression: Dictionary = Dictionary(unit.get("progression", {}))
		var frustration: float = clampf(float(progression.get("frustration", 0.0)), 0.0, 1.0)
		if frustration >= FRUSTRATION_REQUEST_THRESHOLD and not _event_exists(existing_events, PERSONNEL_EVENT_MODEL_SCRIPT.EVENT_REQUESTS_CHANGE, unit_id, "high_frustration"):
			new_events.append(PERSONNEL_EVENT_MODEL_SCRIPT.call("make_event",
				PERSONNEL_EVENT_MODEL_SCRIPT.EVENT_REQUESTS_CHANGE,
				unit_id,
				display_name,
				"%s bittet um Versetzung oder eine ruhigere Teamrolle." % display_name,
				{
					"trigger": "high_frustration",
					"frustration": frustration,
					"fireteam_id": String(unit.get("fireteam_id", "")).strip_edges().to_lower(),
				},
				false
			))
		var availability_status: String = String(unit.get("availability_status", "active")).strip_edges().to_lower()
		if _is_unavailable_status(availability_status) and not _event_exists(existing_events, PERSONNEL_EVENT_MODEL_SCRIPT.EVENT_UNAVAILABLE, unit_id, availability_status):
			new_events.append(PERSONNEL_EVENT_MODEL_SCRIPT.call("make_event",
				PERSONNEL_EVENT_MODEL_SCRIPT.EVENT_UNAVAILABLE,
				unit_id,
				display_name,
				"%s ist wegen %s voruebergehend nicht verfuegbar." % [display_name, availability_status],
				{
					"trigger": availability_status,
					"recovery_state": Dictionary(unit.get("recovery_state", {})).duplicate(true),
				},
				false
			))
		if availability_status == "active" and _event_exists(existing_events, PERSONNEL_EVENT_MODEL_SCRIPT.EVENT_UNAVAILABLE, unit_id, "") and not _event_exists(existing_events, PERSONNEL_EVENT_MODEL_SCRIPT.EVENT_RETURNS, unit_id, "recovered"):
			new_events.append(PERSONNEL_EVENT_MODEL_SCRIPT.call("make_event",
				PERSONNEL_EVENT_MODEL_SCRIPT.EVENT_RETURNS,
				unit_id,
				display_name,
				"%s meldet sich wieder einsatzbereit." % display_name,
				{"trigger": "recovered"},
				false
			))
	for debug_event_variant in _normalize_event_array(options.get("debug_events", [])):
		var debug_event: Dictionary = Dictionary(debug_event_variant)
		new_events.append(debug_event)
	var merged_events: Array = _append_events(existing_events, new_events)
	updated_roster["personnel_events"] = merged_events
	return {
		"updated_roster": updated_roster,
		"events": new_events,
		"notifications": _build_notifications(new_events),
	}


static func build_recruit_candidate(roster: Dictionary, seed: String = "recruit") -> Dictionary:
	var existing_unit_ids: Dictionary = _build_unit_id_lookup(_normalize_units(roster.get("units", [])))
	var existing_callsigns: Dictionary = _build_callsign_lookup(_normalize_units(roster.get("units", [])))
	var generated: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", "recruit_%s" % _sanitize_id(seed), 20, String(roster.get("player_profile_id", "local_player"))))
	for unit_variant in _normalize_units(generated.get("units", [])):
		var candidate: Dictionary = Dictionary(unit_variant).duplicate(true)
		var original_id: String = String(candidate.get("unit_id", "")).strip_edges().to_lower()
		var candidate_id: String = "recruit_%s_%s" % [_sanitize_id(seed), _sanitize_id(original_id)]
		candidate_id = _make_unique_id(candidate_id, existing_unit_ids)
		candidate["unit_id"] = candidate_id
		candidate["personnel_source"] = "recruit_candidate"
		candidate["availability_status"] = "active"
		candidate["status_text"] = "recruit candidate"
		candidate["relationship_links"] = []
		candidate["relationship_summary_text"] = "Neuer Kandidat; Teamfit noch offen."
		candidate["mission_history"] = []
		candidate["fireteam_history"] = []
		candidate["progression"] = {
			"xp": 0,
			"missions_completed": 0,
			"morale": 0.50,
			"frustration": 0.0,
		}
		_ensure_unique_callsign(candidate, existing_callsigns)
		return candidate
	return {}


static func apply_join(roster: Dictionary, candidate: Dictionary) -> Dictionary:
	var updated_roster: Dictionary = roster.duplicate(true)
	var units: Array = _normalize_units(updated_roster.get("units", []))
	var candidate_unit: Dictionary = candidate.duplicate(true)
	var unit_id: String = String(candidate_unit.get("unit_id", "")).strip_edges().to_lower()
	if unit_id.is_empty() or _build_unit_id_lookup(units).has(unit_id):
		return {"ok": false, "reason": "candidate_invalid_or_duplicate", "updated_roster": updated_roster, "event": {}}
	units.append(candidate_unit)
	updated_roster["units"] = units
	updated_roster = _normalize_roster_after_personnel_change(updated_roster)
	var display_name: String = String(candidate_unit.get("display_name", unit_id)).strip_edges()
	var event: Dictionary = PERSONNEL_EVENT_MODEL_SCRIPT.call("make_event",
		PERSONNEL_EVENT_MODEL_SCRIPT.EVENT_JOINS_ROSTER,
		unit_id,
		display_name,
		"%s tritt dem Roster bei." % display_name,
		{"trigger": "recruit_accepted"},
		false
	)
	updated_roster["personnel_events"] = _append_events(_normalize_event_array(updated_roster.get("personnel_events", [])), [event])
	return {"ok": true, "updated_roster": updated_roster, "event": event}


static func request_dismiss(roster: Dictionary, unit_id: String, reason: String = "dismissed_by_player") -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges().to_lower()
	var unit: Dictionary = _find_unit(_normalize_units(roster.get("units", [])), normalized_unit_id)
	if unit.is_empty():
		return {"ok": false, "reason": "unit_missing", "updated_roster": roster.duplicate(true), "event": {}}
	var display_name: String = String(unit.get("display_name", normalized_unit_id)).strip_edges()
	var event: Dictionary = PERSONNEL_EVENT_MODEL_SCRIPT.call("make_event",
		PERSONNEL_EVENT_MODEL_SCRIPT.EVENT_DISMISSED,
		normalized_unit_id,
		display_name,
		"%s wirklich aus dem Roster entlassen?" % display_name,
		{"trigger": "dismiss_requested", "reason": reason, "target_unit_id": normalized_unit_id},
		true
	)
	return {"ok": true, "updated_roster": roster.duplicate(true), "event": event}


static func confirm_dismiss(roster: Dictionary, dismiss_request_or_unit_id: Variant) -> Dictionary:
	var normalized_unit_id: String = ""
	var reason: String = "dismiss_confirmed"
	if typeof(dismiss_request_or_unit_id) == TYPE_DICTIONARY:
		var request: Dictionary = Dictionary(dismiss_request_or_unit_id)
		normalized_unit_id = String(request.get("unit_id", request.get("target_unit_id", ""))).strip_edges().to_lower()
		var payload: Dictionary = Dictionary(request.get("payload", {}))
		if normalized_unit_id.is_empty():
			normalized_unit_id = String(payload.get("target_unit_id", "")).strip_edges().to_lower()
		reason = String(payload.get("reason", reason)).strip_edges()
	else:
		normalized_unit_id = String(dismiss_request_or_unit_id).strip_edges().to_lower()
	var updated_roster: Dictionary = roster.duplicate(true)
	var units: Array = _normalize_units(updated_roster.get("units", []))
	var removed_unit: Dictionary = _find_unit(units, normalized_unit_id)
	if removed_unit.is_empty():
		return {"ok": false, "reason": "unit_missing", "updated_roster": updated_roster, "event": {}, "removed_unit": {}}
	var remaining_units: Array = []
	for unit_variant in units:
		var unit: Dictionary = Dictionary(unit_variant)
		if String(unit.get("unit_id", "")).strip_edges().to_lower() == normalized_unit_id:
			continue
		remaining_units.append(unit.duplicate(true))
	updated_roster["units"] = remaining_units
	updated_roster = _normalize_roster_after_personnel_change(updated_roster)
	var display_name: String = String(removed_unit.get("display_name", normalized_unit_id)).strip_edges()
	var event: Dictionary = PERSONNEL_EVENT_MODEL_SCRIPT.call("make_event",
		PERSONNEL_EVENT_MODEL_SCRIPT.EVENT_DISMISSED,
		normalized_unit_id,
		display_name,
		"%s wurde aus dem Roster entlassen." % display_name,
		{"trigger": "dismiss_confirmed", "reason": reason},
		false
	)
	updated_roster["personnel_events"] = _append_events(_normalize_event_array(updated_roster.get("personnel_events", [])), [event])
	return {"ok": true, "updated_roster": updated_roster, "event": event, "removed_unit": removed_unit}


static func _normalize_roster_after_personnel_change(roster: Dictionary) -> Dictionary:
	var updated_roster: Dictionary = roster.duplicate(true)
	var units: Array = _normalize_units(updated_roster.get("units", []))
	var known_unit_ids: Dictionary = _build_unit_id_lookup(units)
	var cleaned_pairs: Array = []
	for pair_variant in _to_array(updated_roster.get("relationship_pairs", [])):
		if typeof(pair_variant) != TYPE_DICTIONARY:
			continue
		var pair: Dictionary = Dictionary(pair_variant).duplicate(true)
		var source_id: String = String(pair.get("source_unit_id", "")).strip_edges().to_lower()
		var target_id: String = String(pair.get("target_unit_id", "")).strip_edges().to_lower()
		if source_id.is_empty() or target_id.is_empty() or not known_unit_ids.has(source_id) or not known_unit_ids.has(target_id):
			continue
		cleaned_pairs.append(pair)
	units = ROSTER_RELATIONSHIP_MODEL_SCRIPT.call("apply_relationships_to_units", units, cleaned_pairs, true)
	var fireteams: Array = _build_fireteam_suggestions(units)
	fireteams = FIRETEAM_COHESION_RESOLVER_SCRIPT.call("annotate_fireteams", fireteams, units)
	updated_roster["units"] = units
	updated_roster["relationship_pairs"] = cleaned_pairs
	updated_roster["fireteam_suggestions"] = fireteams
	updated_roster["roster_size"] = units.size()
	updated_roster["role_mix"] = _build_role_mix(units)
	if not Dictionary(updated_roster.get("multiplayer_boundary", {})).has("ownership_scope"):
		updated_roster["multiplayer_boundary"] = {"ownership_scope": "player_profile_local"}
	return updated_roster


static func _build_fireteam_suggestions(units: Array) -> Array:
	var groups: Dictionary = {}
	for unit_variant in units:
		var unit: Dictionary = Dictionary(unit_variant)
		var fireteam_id: String = String(unit.get("fireteam_id", "")).strip_edges().to_lower()
		if fireteam_id.is_empty():
			fireteam_id = "reserve"
		var member_ids: PackedStringArray = PackedStringArray(_to_string_array(groups.get(fireteam_id, PackedStringArray())))
		var unit_id: String = String(unit.get("unit_id", "")).strip_edges().to_lower()
		if not unit_id.is_empty():
			member_ids.append(unit_id)
		groups[fireteam_id] = member_ids
	var fireteam_ids: Array = groups.keys()
	fireteam_ids.sort()
	var suggestions: Array = []
	for fireteam_id_variant in fireteam_ids:
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		var member_ids: PackedStringArray = PackedStringArray(_to_string_array(groups.get(fireteam_id, PackedStringArray())))
		if member_ids.is_empty():
			continue
		suggestions.append({
			"fireteam_id": fireteam_id,
			"display_name": "%s Team" % fireteam_id.capitalize(),
			"unit_ids": member_ids,
			"leader_unit_id": _pick_fireteam_leader_id(units, member_ids),
			"suggestion_policy": "personnel_change_preserve_fireteams",
		})
	return suggestions


static func _pick_fireteam_leader_id(units: Array, member_ids: PackedStringArray) -> String:
	var best_unit_id: String = String(member_ids[0]) if not member_ids.is_empty() else ""
	var best_score: float = -1.0
	for unit_variant in units:
		var unit: Dictionary = Dictionary(unit_variant)
		var unit_id: String = String(unit.get("unit_id", "")).strip_edges().to_lower()
		if not member_ids.has(unit_id):
			continue
		var skill_values: Dictionary = Dictionary(unit.get("skill_values", {}))
		var score: float = float(skill_values.get("leadership", 0.0))
		if bool(unit.get("is_fireteam_lead", false)):
			score += 0.25
		if score > best_score:
			best_score = score
			best_unit_id = unit_id
	return best_unit_id


static func _append_events(existing_events: Array, new_events: Array) -> Array:
	var result: Array = []
	var seen_ids: Dictionary = {}
	for event_variant in existing_events:
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = Dictionary(event_variant).duplicate(true)
		var event_id: String = String(event.get("event_id", "")).strip_edges()
		if event_id.is_empty() or seen_ids.has(event_id):
			continue
		seen_ids[event_id] = true
		result.append(event)
	for event_variant in new_events:
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = Dictionary(event_variant).duplicate(true)
		var event_id: String = String(event.get("event_id", "")).strip_edges()
		if event_id.is_empty() or seen_ids.has(event_id):
			continue
		seen_ids[event_id] = true
		result.append(event)
	while result.size() > MAX_PERSONNEL_EVENTS:
		result.remove_at(0)
	return result


static func _event_exists(events: Array, event_type: String, unit_id: String = "", trigger_or_reason: String = "") -> bool:
	var normalized_type: String = event_type.strip_edges().to_lower()
	var normalized_unit_id: String = unit_id.strip_edges().to_lower()
	var normalized_trigger: String = trigger_or_reason.strip_edges().to_lower()
	for event_variant in events:
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = Dictionary(event_variant)
		if String(event.get("event_type", "")).strip_edges().to_lower() != normalized_type:
			continue
		if not normalized_unit_id.is_empty() and String(event.get("unit_id", "")).strip_edges().to_lower() != normalized_unit_id:
			continue
		if normalized_trigger.is_empty():
			return true
		var payload: Dictionary = Dictionary(event.get("payload", {}))
		var trigger: String = String(payload.get("trigger", payload.get("reason", payload.get("milestone", "")))).strip_edges().to_lower()
		if trigger == normalized_trigger:
			return true
	return false


static func _build_notifications(events: Array) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for event_variant in events:
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		var message: String = String(PERSONNEL_EVENT_MODEL_SCRIPT.call("format_event_message", Dictionary(event_variant))).strip_edges()
		if not message.is_empty():
			result.append(message)
	return result


static func _normalize_event_array(value: Variant) -> Array:
	var result: Array = []
	for event_variant in _to_array(value):
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		result.append(Dictionary(event_variant).duplicate(true))
	return result


static func _normalize_units(value: Variant) -> Array:
	var result: Array = []
	for unit_variant in _to_array(value):
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(unit_variant).duplicate(true)
		var unit_id: String = String(unit.get("unit_id", "")).strip_edges().to_lower()
		if unit_id.is_empty():
			continue
		unit["unit_id"] = unit_id
		result.append(unit)
	return result


static func _to_array(value: Variant) -> Array:
	match typeof(value):
		TYPE_ARRAY:
			return Array(value)
		TYPE_PACKED_STRING_ARRAY:
			var result: Array = []
			for entry in PackedStringArray(value):
				result.append(String(entry))
			return result
		_:
			return []


static func _to_string_array(value: Variant) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for entry_variant in _to_array(value):
		var entry: String = String(entry_variant).strip_edges().to_lower()
		if not entry.is_empty():
			result.append(entry)
	return result


static func _max_missions_completed(units: Array) -> int:
	var result: int = 0
	for unit_variant in units:
		var progression: Dictionary = Dictionary(Dictionary(unit_variant).get("progression", {}))
		result = maxi(result, int(progression.get("missions_completed", 0)))
	return result


static func _is_unavailable_status(status: String) -> bool:
	return status == "recovering" or status == "unavailable" or status == "injured"


static func _find_unit(units: Array, unit_id: String) -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges().to_lower()
	for unit_variant in units:
		var unit: Dictionary = Dictionary(unit_variant)
		if String(unit.get("unit_id", "")).strip_edges().to_lower() == normalized_unit_id:
			return unit.duplicate(true)
	return {}


static func _build_unit_id_lookup(units: Array) -> Dictionary:
	var result: Dictionary = {}
	for unit_variant in units:
		var unit_id: String = String(Dictionary(unit_variant).get("unit_id", "")).strip_edges().to_lower()
		if not unit_id.is_empty():
			result[unit_id] = true
	return result


static func _build_callsign_lookup(units: Array) -> Dictionary:
	var result: Dictionary = {}
	for unit_variant in units:
		var callsign: String = String(Dictionary(unit_variant).get("callsign", "")).strip_edges()
		if not callsign.is_empty():
			result[callsign] = true
	return result


static func _ensure_unique_callsign(unit: Dictionary, existing_callsigns: Dictionary) -> void:
	var base_callsign: String = String(unit.get("callsign", "Recruit")).strip_edges()
	if base_callsign.is_empty():
		base_callsign = "Recruit"
	var callsign: String = base_callsign
	var index: int = 2
	while existing_callsigns.has(callsign):
		callsign = "%s%d" % [base_callsign, index]
		index += 1
	unit["callsign"] = callsign
	existing_callsigns[callsign] = true


static func _make_unique_id(base_id: String, existing_ids: Dictionary) -> String:
	var candidate_id: String = _sanitize_id(base_id)
	var index: int = 2
	while existing_ids.has(candidate_id):
		candidate_id = "%s_%02d" % [_sanitize_id(base_id), index]
		index += 1
	existing_ids[candidate_id] = true
	return candidate_id


static func _build_role_mix(units: Array) -> Dictionary:
	var result: Dictionary = {}
	for unit_variant in units:
		var role_category: String = String(Dictionary(unit_variant).get("roster_role_category", "")).strip_edges().to_lower()
		if role_category.is_empty():
			role_category = "unknown"
		result[role_category] = int(result.get(role_category, 0)) + 1
	return result


static func _sanitize_id(value: String) -> String:
	var normalized: String = value.strip_edges().to_lower()
	var result: String = ""
	for index in range(normalized.length()):
		var character: String = normalized.substr(index, 1)
		if (character >= "a" and character <= "z") or (character >= "0" and character <= "9"):
			result += character
		elif character == "_" or character == "-":
			result += character
		else:
			result += "_"
	while result.contains("__"):
		result = result.replace("__", "_")
	result = result.trim_prefix("_").trim_suffix("_")
	if result.is_empty():
		return "entry"
	return result.substr(0, 48)
