class_name MissionScenarioVerticalSliceContract
extends RefCounted

const SLICE_KEY: String = "vertical_slice"
const CONTRACT_VERSION: int = 1
const REQUIRED_PLAY_MODES: PackedStringArray = [
	"singleplayer",
	"multiplayer_pvp",
]
const REQUIRED_OBJECTIVE_TYPES: PackedStringArray = [
	"air_defense_shutdown",
	"computer_hold",
	"cargo_touchdown_extract",
]


static func load_slice_from_file(path: String) -> Dictionary:
	if path.strip_edges().is_empty() or not FileAccess.file_exists(path):
		return {}
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return normalize_slice(Dictionary(parsed).get(SLICE_KEY, {}))


static func normalize_slice(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var raw: Dictionary = Dictionary(value)
	var result: Dictionary = {
		"contract_version": maxi(int(raw.get("contract_version", CONTRACT_VERSION)), CONTRACT_VERSION),
		"play_modes": _normalize_string_array(raw.get("play_modes", [])),
		"team_slots": _normalize_team_slots(raw.get("team_slots", [])),
		"flow_steps": _normalize_flow_steps(raw.get("flow_steps", [])),
		"runtime_gate_notes": _normalize_string_array(raw.get("runtime_gate_notes", [])),
	}
	return result


static func validate_slice(slice: Dictionary, terrain_map_data = null) -> Dictionary:
	var errors: PackedStringArray = PackedStringArray()
	if slice.is_empty():
		errors.append("vertical_slice is required")
		return {"valid": false, "errors": errors}

	var play_modes: PackedStringArray = PackedStringArray(slice.get("play_modes", PackedStringArray()))
	for required_mode in REQUIRED_PLAY_MODES:
		if not play_modes.has(required_mode):
			errors.append("vertical_slice.play_modes missing %s" % required_mode)

	var team_ids: PackedStringArray = PackedStringArray()
	for team_slot_variant in Array(slice.get("team_slots", [])):
		var team_slot: Dictionary = Dictionary(team_slot_variant)
		var team_id: String = String(team_slot.get("team_id", "")).strip_edges()
		if team_id.is_empty():
			errors.append("vertical_slice.team_slots has empty team_id")
		elif not team_ids.has(team_id):
			team_ids.append(team_id)
		_validate_marker_reference("vertical_slice.team_slots[%s].spawn_marker_id" % team_id, String(team_slot.get("spawn_marker_id", "")), terrain_map_data, errors)
	if not team_ids.has("team_alpha"):
		errors.append("vertical_slice.team_slots missing team_alpha")
	if not team_ids.has("team_bravo"):
		errors.append("vertical_slice.team_slots missing team_bravo")

	var objective_types: PackedStringArray = PackedStringArray()
	for step_variant in Array(slice.get("flow_steps", [])):
		var step: Dictionary = Dictionary(step_variant)
		var step_id: String = String(step.get("step_id", "")).strip_edges()
		var objective_type: String = String(step.get("objective_type", "")).strip_edges()
		if step_id.is_empty():
			errors.append("vertical_slice.flow_steps has empty step_id")
		if objective_type.is_empty():
			errors.append("vertical_slice.flow_steps[%s] has empty objective_type" % step_id)
		elif not objective_types.has(objective_type):
			objective_types.append(objective_type)
		_validate_marker_reference("vertical_slice.flow_steps[%s].target_marker_id" % step_id, String(step.get("target_marker_id", "")), terrain_map_data, errors)
		if float(step.get("min_hold_seconds", 0.0)) < 0.0:
			errors.append("vertical_slice.flow_steps[%s].min_hold_seconds must be >= 0" % step_id)
	for required_type in REQUIRED_OBJECTIVE_TYPES:
		if not objective_types.has(required_type):
			errors.append("vertical_slice.flow_steps missing %s" % required_type)

	return {
		"valid": errors.is_empty(),
		"errors": errors,
	}


static func get_step_by_type(slice: Dictionary, objective_type: String) -> Dictionary:
	var normalized_type: String = objective_type.strip_edges()
	if normalized_type.is_empty():
		return {}
	for step_variant in Array(slice.get("flow_steps", [])):
		var step: Dictionary = Dictionary(step_variant)
		if String(step.get("objective_type", "")).strip_edges() == normalized_type:
			return step.duplicate(true)
	return {}


static func _normalize_team_slots(value: Variant) -> Array:
	var result: Array = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for slot_variant in Array(value):
		if typeof(slot_variant) != TYPE_DICTIONARY:
			continue
		var slot: Dictionary = Dictionary(slot_variant)
		var team_id: String = String(slot.get("team_id", "")).strip_edges()
		if team_id.is_empty():
			continue
		result.append({
			"team_id": team_id,
			"role": String(slot.get("role", "")).strip_edges(),
			"spawn_marker_id": String(slot.get("spawn_marker_id", "")).strip_edges(),
			"npc_owned": bool(slot.get("npc_owned", false)),
		})
	return result


static func _normalize_flow_steps(value: Variant) -> Array:
	var result: Array = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for step_variant in Array(value):
		if typeof(step_variant) != TYPE_DICTIONARY:
			continue
		var step: Dictionary = Dictionary(step_variant)
		var step_id: String = String(step.get("step_id", "")).strip_edges()
		if step_id.is_empty():
			continue
		var normalized: Dictionary = {
			"step_id": step_id,
			"objective_type": String(step.get("objective_type", "")).strip_edges(),
			"target_marker_id": String(step.get("target_marker_id", "")).strip_edges(),
			"required_state": String(step.get("required_state", "")).strip_edges(),
			"min_hold_seconds": maxf(float(step.get("min_hold_seconds", 0.0)), 0.0),
		}
		for optional_key in ["blocks_cargo_until_complete", "operator_team_id", "requires_step_id"]:
			if step.has(optional_key):
				normalized[optional_key] = step.get(optional_key)
		result.append(normalized)
	return result


static func _normalize_string_array(value: Variant) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if typeof(value) != TYPE_ARRAY:
		return result
	for item_variant in Array(value):
		var text: String = String(item_variant).strip_edges()
		if not text.is_empty() and not result.has(text):
			result.append(text)
	return result


static func _validate_marker_reference(label: String, marker_id: String, terrain_map_data, errors: PackedStringArray) -> void:
	var normalized_marker_id: String = marker_id.strip_edges()
	if normalized_marker_id.is_empty():
		errors.append("%s is required" % label)
		return
	if terrain_map_data == null or not terrain_map_data.has_method("has_marker"):
		return
	if not bool(terrain_map_data.call("has_marker", normalized_marker_id)):
		errors.append("%s does not exist in map: %s" % [label, normalized_marker_id])
