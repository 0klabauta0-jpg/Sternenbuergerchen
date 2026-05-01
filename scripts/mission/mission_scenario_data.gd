class_name MissionScenarioData
extends RefCounted

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")

const CONTRACT_VERSION: int = 1
const DEFAULT_CAPTURE_RADIUS: float = 80.0
const DEFAULT_TEAM_ID: String = "team_bravo"
const DEFAULT_PATROL_MODE: String = "pre_contact"
const FORBIDDEN_LZ_KEYS: PackedStringArray = [
	"lz",
	"player_lz",
	"requires_player_lz",
	"lz_position",
	"has_lz_position",
	"drop_lz",
	"dropship_lz",
	"landing_zone",
	"landing_zone_position",
]

var version: int = CONTRACT_VERSION
var scenario_id: String = ""
var display_name: String = ""
var map_file_path: String = ""
var time_limit_seconds: float = 0.0
var mission_slot_count_override: int = -1
var objective: Dictionary = {}
var enemy_groups: Array = []
var wave_config: Dictionary = {}
var patrol_bindings: Array = []
var notes: PackedStringArray = PackedStringArray()

var _load_issues: PackedStringArray = PackedStringArray()
var _source_path: String = ""


func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		_collect_forbidden_lz_keys(data, "scenario", _load_issues)
		_apply_dict(data)


static func from_dict(data: Dictionary):
	var script_ref: GDScript = load("res://scripts/mission/mission_scenario_data.gd")
	return script_ref.new(data)


static func load_from_file(path: String):
	var script_ref: GDScript = load("res://scripts/mission/mission_scenario_data.gd")
	var scenario = script_ref.new()
	scenario._source_path = path
	if path.is_empty() or not FileAccess.file_exists(path):
		scenario._load_issues.append("Scenario file not found: %s" % path)
		return scenario

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		scenario._load_issues.append("Scenario file could not be opened: %s" % path)
		return scenario

	var parsed_json: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed_json) != TYPE_DICTIONARY:
		scenario._load_issues.append("Scenario file is not a JSON object: %s" % path)
		return scenario

	scenario = from_dict(Dictionary(parsed_json))
	scenario._source_path = path
	return scenario


func save_to_file(path: String) -> Error:
	if path.is_empty():
		return ERR_INVALID_PARAMETER

	var directory_path: String = path.get_base_dir()
	if not directory_path.is_empty():
		var make_dir_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory_path))
		if make_dir_error != OK:
			return make_dir_error

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()

	file.store_string(JSON.stringify(to_dict(), "\t") + "\n")
	return OK


func to_dict() -> Dictionary:
	var data: Dictionary = {
		"version": CONTRACT_VERSION,
		"scenario_id": scenario_id,
		"display_name": display_name,
		"map_file_path": map_file_path,
		"time_limit_seconds": time_limit_seconds,
		"objective": _serialize_objective(),
		"enemy_groups": _serialize_enemy_groups(),
		"wave_config": _serialize_wave_config(),
		"patrol_bindings": _serialize_patrol_bindings(),
	}
	if mission_slot_count_override > 0:
		data["mission_slot_count_override"] = mission_slot_count_override
	if not notes.is_empty():
		data["notes"] = Array(notes)
	return data


func is_valid() -> bool:
	return bool(validate().get("valid", false))


func validate() -> Dictionary:
	var errors: PackedStringArray = _load_issues.duplicate()
	if scenario_id.is_empty():
		errors.append("scenario_id is required")
	if display_name.is_empty():
		errors.append("display_name is required")
	if map_file_path.is_empty():
		errors.append("map_file_path is required")
	elif not FileAccess.file_exists(map_file_path):
		errors.append("map_file_path does not exist: %s" % map_file_path)
	if time_limit_seconds < 0.0:
		errors.append("time_limit_seconds must be >= 0")
	if mission_slot_count_override != -1 and mission_slot_count_override < 1:
		errors.append("mission_slot_count_override must be unset or >= 1")

	var terrain_map_data = _load_referenced_map(errors)
	_validate_objective(terrain_map_data, errors)
	var enemy_ids: PackedStringArray = _validate_enemy_groups(errors)
	_validate_wave_config(errors)
	_validate_patrol_bindings(terrain_map_data, enemy_ids, errors)

	return {
		"valid": errors.is_empty(),
		"errors": errors,
	}


func get_source_path() -> String:
	return _source_path


func get_enemy_ids() -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for group_variant in enemy_groups:
		var group: Dictionary = Dictionary(group_variant)
		for enemy_id_variant in Array(group.get("enemy_ids", [])):
			var enemy_id: String = String(enemy_id_variant).strip_edges()
			if not enemy_id.is_empty() and not result.has(enemy_id):
				result.append(enemy_id)
	return result


func get_objective_position(terrain_map_data = null, fallback: Vector2 = Vector2.ZERO) -> Vector2:
	if objective.has("position"):
		return _coerce_vector2(objective.get("position", fallback), fallback)
	var marker_id: String = String(objective.get("marker_id", "")).strip_edges()
	if terrain_map_data != null and not marker_id.is_empty() and terrain_map_data.has_method("get_marker_position"):
		return terrain_map_data.call("get_marker_position", marker_id, fallback)
	return fallback


func references_terrain_without_duplication() -> bool:
	var data: Dictionary = to_dict()
	return not data.has("tiles") and not data.has("markers") and not data.has("patrol_paths")


func _apply_dict(data: Dictionary) -> void:
	version = maxi(int(data.get("version", CONTRACT_VERSION)), 1)
	scenario_id = String(data.get("scenario_id", "")).strip_edges()
	display_name = String(data.get("display_name", scenario_id)).strip_edges()
	map_file_path = String(data.get("map_file_path", "")).strip_edges()
	time_limit_seconds = maxf(float(data.get("time_limit_seconds", 0.0)), -1.0)
	mission_slot_count_override = int(data.get("mission_slot_count_override", -1))
	objective = _coerce_objective(Dictionary(data.get("objective", {})))
	enemy_groups = _coerce_enemy_groups(data.get("enemy_groups", []))
	wave_config = _coerce_wave_config(Dictionary(data.get("wave_config", {})))
	patrol_bindings = _coerce_patrol_bindings(data.get("patrol_bindings", []))
	notes = _coerce_notes(data.get("notes", []))


func _load_referenced_map(errors: PackedStringArray):
	if map_file_path.is_empty() or not FileAccess.file_exists(map_file_path):
		return null
	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", map_file_path)
	if terrain_map_data == null:
		errors.append("map_file_path could not be loaded: %s" % map_file_path)
		return null
	if terrain_map_data.has_method("has_load_issue") and bool(terrain_map_data.call("has_load_issue")):
		errors.append(String(terrain_map_data.call("get_load_issue_message")))
	if terrain_map_data.has_method("get_tiles") and Array(terrain_map_data.call("get_tiles")).is_empty():
		errors.append("map_file_path has no terrain tiles: %s" % map_file_path)
	return terrain_map_data


func _validate_objective(terrain_map_data, errors: PackedStringArray) -> void:
	if objective.is_empty():
		errors.append("objective is required")
		return

	var marker_id: String = String(objective.get("marker_id", "")).strip_edges()
	var has_position: bool = objective.has("position") and _is_vector2_payload(objective.get("position", null))
	if marker_id.is_empty() and not has_position:
		errors.append("objective needs marker_id or position")
	if not marker_id.is_empty() and terrain_map_data != null and terrain_map_data.has_method("has_marker") and not bool(terrain_map_data.call("has_marker", marker_id)):
		errors.append("objective marker does not exist in map: %s" % marker_id)
	if float(objective.get("capture_radius", DEFAULT_CAPTURE_RADIUS)) <= 0.0:
		errors.append("objective.capture_radius must be > 0")


func _validate_enemy_groups(errors: PackedStringArray) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	var seen: Dictionary = {}
	if enemy_groups.is_empty():
		errors.append("enemy_groups needs at least one group")
		return result

	for group_index in range(enemy_groups.size()):
		var group: Dictionary = Dictionary(enemy_groups[group_index])
		if String(group.get("group_id", "")).strip_edges().is_empty():
			errors.append("enemy_groups[%d].group_id is required" % group_index)
		var enemy_ids: Array = Array(group.get("enemy_ids", []))
		if enemy_ids.is_empty():
			errors.append("enemy_groups[%d].enemy_ids needs at least one enemy id" % group_index)
		for enemy_id_variant in enemy_ids:
			var enemy_id: String = String(enemy_id_variant).strip_edges()
			if enemy_id.is_empty():
				errors.append("enemy_groups[%d] contains an empty enemy id" % group_index)
				continue
			if seen.has(enemy_id):
				errors.append("enemy id is used more than once: %s" % enemy_id)
				continue
			seen[enemy_id] = true
			result.append(enemy_id)
	return result


func _validate_wave_config(errors: PackedStringArray) -> void:
	if wave_config.is_empty():
		errors.append("wave_config is required")
		return
	if int(wave_config.get("wave_count", 0)) < 0:
		errors.append("wave_config.wave_count must be >= 0")
	if int(wave_config.get("units_per_wave", 0)) <= 0:
		errors.append("wave_config.units_per_wave must be > 0")
	if float(wave_config.get("first_wave_delay_seconds", 0.0)) < 0.0:
		errors.append("wave_config.first_wave_delay_seconds must be >= 0")
	if float(wave_config.get("wave_delay_seconds", 0.0)) < 0.0:
		errors.append("wave_config.wave_delay_seconds must be >= 0")


func _validate_patrol_bindings(terrain_map_data, enemy_ids: PackedStringArray, errors: PackedStringArray) -> void:
	var valid_targets: Dictionary = {}
	for enemy_id in enemy_ids:
		valid_targets[String(enemy_id)] = true
	if terrain_map_data != null:
		if terrain_map_data.has_method("get_marker_ids"):
			for marker_id in PackedStringArray(terrain_map_data.call("get_marker_ids")):
				valid_targets[String(marker_id)] = true
		if terrain_map_data.has_method("get_patrol_paths"):
			var patrol_paths: Dictionary = Dictionary(terrain_map_data.call("get_patrol_paths"))
			for patrol_id_variant in patrol_paths.keys():
				valid_targets[String(patrol_id_variant)] = true

	for binding_index in range(patrol_bindings.size()):
		var binding: Dictionary = Dictionary(patrol_bindings[binding_index])
		var target_id: String = String(binding.get("target_id", "")).strip_edges()
		if target_id.is_empty():
			errors.append("patrol_bindings[%d].target_id is required" % binding_index)
		elif not valid_targets.has(target_id):
			errors.append("patrol_bindings[%d].target_id is not an enemy id or map spawn/patrol id: %s" % [binding_index, target_id])
		if String(binding.get("patrol_path_id", "")).strip_edges().is_empty():
			errors.append("patrol_bindings[%d].patrol_path_id is required" % binding_index)


func _coerce_objective(raw_objective: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var marker_id: String = String(raw_objective.get("marker_id", "")).strip_edges()
	if not marker_id.is_empty():
		result["marker_id"] = marker_id
	if raw_objective.has("position") and _is_vector2_payload(raw_objective.get("position", null)):
		result["position"] = _coerce_vector2(raw_objective.get("position", Vector2.ZERO), Vector2.ZERO)
	result["capture_radius"] = maxf(float(raw_objective.get("capture_radius", DEFAULT_CAPTURE_RADIUS)), 0.0)
	return result


func _coerce_enemy_groups(value: Variant) -> Array:
	var result: Array = []
	if not (value is Array):
		return result
	for group_variant in Array(value):
		if typeof(group_variant) != TYPE_DICTIONARY:
			continue
		var group_dict: Dictionary = Dictionary(group_variant)
		var group: Dictionary = {
			"group_id": String(group_dict.get("group_id", "")).strip_edges(),
			"team_id": String(group_dict.get("team_id", DEFAULT_TEAM_ID)).strip_edges(),
			"enemy_ids": _coerce_string_array(group_dict.get("enemy_ids", [])),
		}
		var display_text: String = String(group_dict.get("display_name", "")).strip_edges()
		if not display_text.is_empty():
			group["display_name"] = display_text
		var spawn_marker_id: String = String(group_dict.get("spawn_marker_id", "")).strip_edges()
		if not spawn_marker_id.is_empty():
			group["spawn_marker_id"] = spawn_marker_id
		var group_notes: PackedStringArray = _coerce_notes(group_dict.get("notes", []))
		if not group_notes.is_empty():
			group["notes"] = Array(group_notes)
		result.append(group)
	return result


func _coerce_wave_config(raw_wave_config: Dictionary) -> Dictionary:
	if raw_wave_config.is_empty():
		return {}
	return {
		"wave_count": maxi(int(raw_wave_config.get("wave_count", 0)), 0),
		"units_per_wave": int(raw_wave_config.get("units_per_wave", 1)),
		"first_wave_delay_seconds": maxf(float(raw_wave_config.get("first_wave_delay_seconds", 0.0)), 0.0),
		"wave_delay_seconds": maxf(float(raw_wave_config.get("wave_delay_seconds", 0.0)), 0.0),
	}


func _coerce_patrol_bindings(value: Variant) -> Array:
	var result: Array = []
	if typeof(value) == TYPE_DICTIONARY:
		var binding_dict: Dictionary = Dictionary(value)
		for target_id_variant in binding_dict.keys():
			var target_id: String = String(target_id_variant).strip_edges()
			var patrol_path_id: String = String(binding_dict.get(target_id_variant, target_id)).strip_edges()
			if not target_id.is_empty():
				result.append({
					"target_id": target_id,
					"patrol_path_id": patrol_path_id,
					"mode": DEFAULT_PATROL_MODE,
				})
		return result
	if not (value is Array):
		return result
	for binding_variant in Array(value):
		if typeof(binding_variant) != TYPE_DICTIONARY:
			continue
		var binding_dict: Dictionary = Dictionary(binding_variant)
		var binding: Dictionary = {
			"target_id": String(binding_dict.get("target_id", "")).strip_edges(),
			"patrol_path_id": String(binding_dict.get("patrol_path_id", "")).strip_edges(),
			"mode": String(binding_dict.get("mode", DEFAULT_PATROL_MODE)).strip_edges(),
		}
		var binding_id: String = String(binding_dict.get("binding_id", "")).strip_edges()
		if not binding_id.is_empty():
			binding["binding_id"] = binding_id
		result.append(binding)
	return result


func _serialize_objective() -> Dictionary:
	var result: Dictionary = {
		"capture_radius": float(objective.get("capture_radius", DEFAULT_CAPTURE_RADIUS)),
	}
	var marker_id: String = String(objective.get("marker_id", "")).strip_edges()
	if not marker_id.is_empty():
		result["marker_id"] = marker_id
	if objective.has("position"):
		result["position"] = _serialize_vector2(_coerce_vector2(objective.get("position", Vector2.ZERO), Vector2.ZERO))
	return result


func _serialize_enemy_groups() -> Array:
	var result: Array = []
	for group_variant in enemy_groups:
		var group: Dictionary = Dictionary(group_variant)
		var serialized_group: Dictionary = {
			"group_id": String(group.get("group_id", "")),
			"team_id": String(group.get("team_id", DEFAULT_TEAM_ID)),
			"enemy_ids": Array(_coerce_string_array(group.get("enemy_ids", []))),
		}
		for optional_key in ["display_name", "spawn_marker_id", "notes"]:
			if group.has(optional_key):
				serialized_group[optional_key] = group.get(optional_key)
		result.append(serialized_group)
	return result


func _serialize_wave_config() -> Dictionary:
	return _coerce_wave_config(wave_config)


func _serialize_patrol_bindings() -> Array:
	var result: Array = []
	for binding_variant in patrol_bindings:
		var binding: Dictionary = Dictionary(binding_variant)
		var serialized_binding: Dictionary = {
			"target_id": String(binding.get("target_id", "")),
			"patrol_path_id": String(binding.get("patrol_path_id", "")),
			"mode": String(binding.get("mode", DEFAULT_PATROL_MODE)),
		}
		if binding.has("binding_id"):
			serialized_binding["binding_id"] = String(binding.get("binding_id", ""))
		result.append(serialized_binding)
	return result


func _coerce_string_array(value: Variant) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if value is PackedStringArray:
		for item_variant in PackedStringArray(value):
			var item_from_packed: String = String(item_variant).strip_edges()
			if not item_from_packed.is_empty() and not result.has(item_from_packed):
				result.append(item_from_packed)
		return result
	if not (value is Array):
		return result
	for item_variant in Array(value):
		var item: String = String(item_variant).strip_edges()
		if not item.is_empty() and not result.has(item):
			result.append(item)
	return result


func _coerce_notes(value: Variant) -> PackedStringArray:
	return _coerce_string_array(value)


static func _collect_forbidden_lz_keys(value: Variant, path: String, errors: PackedStringArray) -> void:
	if typeof(value) == TYPE_DICTIONARY:
		var value_dict: Dictionary = Dictionary(value)
		for key_variant in value_dict.keys():
			var key_text: String = String(key_variant).strip_edges().to_lower()
			var child_path: String = "%s.%s" % [path, key_text]
			if FORBIDDEN_LZ_KEYS.has(key_text):
				errors.append("LZ must not be stored in mission scenarios: %s" % child_path)
			_collect_forbidden_lz_keys(value_dict.get(key_variant), child_path, errors)
	elif typeof(value) == TYPE_ARRAY:
		var value_array: Array = Array(value)
		for index in range(value_array.size()):
			_collect_forbidden_lz_keys(value_array[index], "%s[%d]" % [path, index], errors)


static func _is_vector2_payload(value: Variant) -> bool:
	if value is Vector2 or value is Vector2i:
		return true
	if typeof(value) != TYPE_DICTIONARY:
		return false
	var value_dict: Dictionary = Dictionary(value)
	return value_dict.has("x") and value_dict.has("y")


static func _coerce_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Vector2i:
		return Vector2(value.x, value.y)
	if typeof(value) == TYPE_DICTIONARY:
		var value_dict: Dictionary = Dictionary(value)
		return Vector2(float(value_dict.get("x", fallback.x)), float(value_dict.get("y", fallback.y)))
	return fallback


static func _serialize_vector2(value: Vector2) -> Dictionary:
	return {
		"x": value.x,
		"y": value.y,
	}
