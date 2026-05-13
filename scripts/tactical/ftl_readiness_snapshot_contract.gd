class_name FTLReadinessSnapshotContract
extends RefCounted

const SCHEMA_VERSION: int = 1
const MIN_REACTION_DELAY_SECONDS: float = 0.05
const MAX_REACTION_DELAY_SECONDS: float = 0.85


static func build_snapshot(
	fireteam_id: String,
	leader = null,
	profile_dict: Dictionary = {},
	assignment_dict: Dictionary = {}
) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	var leader_data: Dictionary = _coerce_leader_data(leader)
	var public_snapshot: Dictionary = _resolve_public_snapshot(profile_dict, assignment_dict)
	var result: Dictionary = {
		"schema_version": SCHEMA_VERSION,
		"fireteam_id": normalized_fireteam_id,
		"leader_unit_id": String(leader_data.get("unit_id", public_snapshot.get("unit_id", ""))).strip_edges(),
		"leader_name": String(leader_data.get("display_name", leader_data.get("callsign", ""))).strip_edges(),
		"leader_available": not leader_data.is_empty(),
		"ftl_data_available": not public_snapshot.is_empty(),
		"reaction_delay_seconds": null,
		"reaction_delay_seconds_available": false,
		"morale": null,
		"morale_available": false,
		"plan_quality": null,
		"plan_quality_available": false,
		"execution_label": "UNAVAILABLE",
		"execution_label_available": false,
		"effect_label": "",
		"source": _resolve_source(public_snapshot, profile_dict, assignment_dict, leader_data),
		"read_only": true,
		"contains_node_reference": false,
		"value_ranges": get_value_ranges(),
		"unavailable_reason": "",
	}
	if String(result.get("leader_name", "")).is_empty():
		result["leader_name"] = String(result.get("leader_unit_id", "")).strip_edges()
	if String(result.get("leader_name", "")).is_empty():
		result["leader_name"] = "UNKNOWN FTL"

	_apply_metric_value(result, public_snapshot, profile_dict, "reaction_delay_seconds", "reaction_delay_seconds", MIN_REACTION_DELAY_SECONDS, MAX_REACTION_DELAY_SECONDS)
	_apply_metric_value(result, public_snapshot, profile_dict, "morale", "morale", 0.0, 1.0)
	_apply_metric_value(result, public_snapshot, profile_dict, "plan_quality", "plan_quality", 0.0, 1.0)
	var execution_label: String = String(profile_dict.get("execution_label", public_snapshot.get("execution_label", ""))).strip_edges().to_upper()
	if execution_label.is_empty():
		execution_label = String(public_snapshot.get("effect_label", "")).strip_edges().replace("_", " ").to_upper()
	if not execution_label.is_empty():
		result["execution_label"] = execution_label
		result["execution_label_available"] = true
	result["effect_label"] = String(public_snapshot.get("effect_label", profile_dict.get("effect_label", ""))).strip_edges().to_lower()

	var missing: PackedStringArray = PackedStringArray()
	if not bool(result.get("leader_available", false)):
		missing.append("leader")
	if not bool(result.get("ftl_data_available", false)):
		missing.append("ftl_data")
	for metric in [
		{"available_key": "reaction_delay_seconds_available", "label": "reaction_delay"},
		{"available_key": "morale_available", "label": "morale"},
		{"available_key": "plan_quality_available", "label": "plan_quality"},
	]:
		if not bool(result.get(String(metric.get("available_key", "")), false)):
			missing.append(String(metric.get("label", "")))
	result["is_available"] = missing.is_empty()
	result["unavailable_reason"] = "available" if missing.is_empty() else "missing_%s" % "_".join(missing)
	return result


static func get_value_ranges() -> Dictionary:
	return {
		"reaction_delay_seconds": {"min": MIN_REACTION_DELAY_SECONDS, "max": MAX_REACTION_DELAY_SECONDS, "lower_is_better": true},
		"morale": {"min": 0.0, "max": 1.0, "higher_is_better": true},
		"plan_quality": {"min": 0.0, "max": 1.0, "higher_is_better": true},
	}


static func _resolve_public_snapshot(profile_dict: Dictionary, assignment_dict: Dictionary) -> Dictionary:
	var profile_metadata: Dictionary = Dictionary(profile_dict.get("metadata", {}))
	var profile_public: Dictionary = Dictionary(profile_metadata.get("ftl_public_snapshot", {})).duplicate(true)
	if not profile_public.is_empty():
		return profile_public
	var assignment_public: Dictionary = Dictionary(assignment_dict.get("ftl_public_snapshot", assignment_dict.get("ftl_skill_snapshot", {}))).duplicate(true)
	if not assignment_public.is_empty():
		return assignment_public
	var fallback: Dictionary = {}
	for key in ["unit_id", "fireteam_id", "reaction_delay_seconds", "morale", "plan_quality", "effect_label", "execution_label"]:
		if profile_dict.has(key):
			fallback[key] = profile_dict.get(key)
	return fallback


static func _apply_metric_value(result: Dictionary, public_snapshot: Dictionary, profile_dict: Dictionary, source_key: String, result_key: String, min_value: float, max_value: float) -> void:
	var value_variant = public_snapshot.get(source_key, profile_dict.get(source_key, null))
	if value_variant == null:
		return
	result[result_key] = clampf(float(value_variant), min_value, max_value)
	result["%s_available" % result_key] = true


static func _coerce_leader_data(leader) -> Dictionary:
	if typeof(leader) == TYPE_DICTIONARY:
		return Dictionary(leader).duplicate(true)
	if leader == null:
		return {}
	var data: Dictionary = {}
	if leader is Object:
		if leader.has_method("get_unit_id"):
			data["unit_id"] = String(leader.call("get_unit_id")).strip_edges()
		if leader.has_method("get_display_name"):
			data["display_name"] = String(leader.call("get_display_name")).strip_edges()
		if leader.has_method("get_fireteam_id"):
			data["fireteam_id"] = String(leader.call("get_fireteam_id")).strip_edges().to_lower()
		if leader.has_method("get_callsign"):
			data["callsign"] = String(leader.call("get_callsign")).strip_edges()
	return data


static func _resolve_source(public_snapshot: Dictionary, profile_dict: Dictionary, assignment_dict: Dictionary, leader_data: Dictionary) -> String:
	if not Dictionary(Dictionary(profile_dict.get("metadata", {})).get("ftl_public_snapshot", {})).is_empty():
		return "behavior_profile_public_snapshot"
	if not Dictionary(assignment_dict.get("ftl_public_snapshot", assignment_dict.get("ftl_skill_snapshot", {}))).is_empty():
		return "plan_assignment_public_snapshot"
	if not public_snapshot.is_empty():
		return "profile_fallback"
	if not leader_data.is_empty():
		return "leader_only"
	return "unavailable"
