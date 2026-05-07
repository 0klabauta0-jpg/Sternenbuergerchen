class_name MissionScenarioData
extends RefCounted

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const ENEMY_TEAM_TACTICS_PROFILE_SCRIPT: GDScript = preload("res://scripts/tactical/enemy_team_tactics_profile.gd")
const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")

const CONTRACT_VERSION: int = 1
const DEFAULT_CAPTURE_RADIUS: float = 80.0
const DEFAULT_TEAM_ID: String = "team_bravo"
const DEFAULT_PATROL_MODE: String = "pre_contact"
const DEFAULT_TACTICAL_AUTHORING: Dictionary = {
	"communication_intensity": "normal",
	"fireteam_defaults": {
		"advance_style": "bounding",
		"security_mode": "360",
	},
	"air_asset_risk": {
		"profile_id": "none",
		"enemy_group_id": "",
		"lz_threat_zone_id": "",
		"warning_required_before_damage": true,
		"loss_consequence": "replacement_recovery",
	},
}
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
var tactical_authoring: Dictionary = {}
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
		"tactical_authoring": _serialize_tactical_authoring(),
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
	var enemy_ids: PackedStringArray = _validate_enemy_groups(terrain_map_data, errors)
	_validate_wave_config(errors)
	_validate_patrol_bindings(terrain_map_data, enemy_ids, errors)
	_validate_tactical_authoring(terrain_map_data, errors)

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


func get_enemy_tactics_for_unit(enemy_id: String, terrain_map_data = null) -> Dictionary:
	var normalized_enemy_id: String = enemy_id.strip_edges()
	if normalized_enemy_id.is_empty():
		return ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_default_config_for_map_size", _get_terrain_grid_size(terrain_map_data))
	for group_variant in enemy_groups:
		var group: Dictionary = Dictionary(group_variant)
		for group_enemy_id_variant in Array(group.get("enemy_ids", [])):
			if String(group_enemy_id_variant).strip_edges() == normalized_enemy_id:
				return ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("normalize_config", group.get("tactics", {}), _get_terrain_grid_size(terrain_map_data))
	return ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_default_config_for_map_size", _get_terrain_grid_size(terrain_map_data))


func get_enemy_tactics_diagnostics(terrain_map_data = null) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	var grid_size: Vector2i = _get_terrain_grid_size(terrain_map_data)
	for group_variant in enemy_groups:
		var group: Dictionary = Dictionary(group_variant)
		var group_id: String = String(group.get("group_id", "")).strip_edges()
		var normalized: Dictionary = ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("normalize_config", group.get("tactics", {}), grid_size)
		for diagnostic_variant in PackedStringArray(normalized.get("diagnostics", PackedStringArray())):
			var diagnostic: String = String(diagnostic_variant).strip_edges()
			if diagnostic.is_empty():
				continue
			result.append("%s:%s" % [group_id if not group_id.is_empty() else "enemy_group", diagnostic])
	for diagnostic_variant in get_tactical_authoring_diagnostics(terrain_map_data):
		result.append("scenario:%s" % String(diagnostic_variant))
	return result


func get_tactical_authoring_config() -> Dictionary:
	return _coerce_tactical_authoring(tactical_authoring)


func get_air_asset_risk_config() -> Dictionary:
	return Dictionary(get_tactical_authoring_config().get("air_asset_risk", {})).duplicate(true)


func get_enemy_air_asset_threats(terrain_map_data = null) -> Array:
	var result: Array = []
	var risk: Dictionary = get_air_asset_risk_config()
	for group_variant in enemy_groups:
		var group: Dictionary = Dictionary(group_variant)
		var tactics: Dictionary = ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("normalize_config", group.get("tactics", {}), _get_terrain_grid_size(terrain_map_data))
		if not bool(tactics.get("anti_armor_threat", false)) and String(tactics.get("air_asset_risk_profile", "none")) == "none":
			continue
		result.append({
			"group_id": String(group.get("group_id", "")),
			"enemy_ids": Array(group.get("enemy_ids", [])).duplicate(true),
			"weapon_id": String(tactics.get("weapon_id", "")),
			"heavy_weapon_role": String(tactics.get("heavy_weapon_role", "none")),
			"air_asset_risk_profile": String(tactics.get("air_asset_risk_profile", risk.get("profile_id", "none"))),
			"lz_threat_zone_id": String(tactics.get("lz_threat_zone_id", risk.get("lz_threat_zone_id", ""))),
			"communication_intensity": String(tactics.get("communication_intensity", tactical_authoring.get("communication_intensity", "normal"))),
			"runtime_authority": "SimulationRoot",
			"ui_sets_gameplay_truth": false,
		})
	return result


func get_tactical_authoring_diagnostics(terrain_map_data = null) -> PackedStringArray:
	var diagnostics: PackedStringArray = PackedStringArray()
	var grid_size: Vector2i = _get_terrain_grid_size(terrain_map_data)
	for group_variant in enemy_groups:
		var group: Dictionary = Dictionary(group_variant)
		var group_id: String = String(group.get("group_id", "enemy_group")).strip_edges()
		var tactics: Dictionary = ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("normalize_config", group.get("tactics", {}), grid_size)
		for diagnostic_variant in PackedStringArray(tactics.get("diagnostics", PackedStringArray())):
			diagnostics.append("%s:%s" % [group_id, String(diagnostic_variant)])
		if bool(tactics.get("anti_armor_threat", false)) and String(tactics.get("air_asset_risk_profile", "none")) == "none":
			diagnostics.append("%s:anti_armor_without_air_asset_risk_profile" % group_id)
	var risk: Dictionary = get_air_asset_risk_config()
	var risk_profile: String = String(risk.get("profile_id", "none"))
	if risk_profile != "none" and String(risk.get("lz_threat_zone_id", "")).strip_edges().is_empty():
		diagnostics.append("air_asset_risk_missing_lz_threat_zone:%s" % risk_profile)
	return diagnostics


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
	tactical_authoring = _coerce_tactical_authoring(Dictionary(data.get("tactical_authoring", data.get("tactical_profile", {}))))
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


func _validate_enemy_groups(terrain_map_data, errors: PackedStringArray) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	var seen: Dictionary = {}
	if enemy_groups.is_empty():
		errors.append("enemy_groups needs at least one group")
		return result

	for group_index in range(enemy_groups.size()):
		var group: Dictionary = Dictionary(enemy_groups[group_index])
		if String(group.get("group_id", "")).strip_edges().is_empty():
			errors.append("enemy_groups[%d].group_id is required" % group_index)
		var spawn_marker_id: String = String(group.get("spawn_marker_id", "")).strip_edges()
		var has_spawn_position: bool = group.has("spawn_position") and _is_vector2_payload(group.get("spawn_position", null))
		if spawn_marker_id.is_empty() and not has_spawn_position:
			errors.append("enemy_groups[%d] needs spawn_marker_id or spawn_position" % group_index)
		elif not spawn_marker_id.is_empty() and terrain_map_data != null and terrain_map_data.has_method("has_marker") and not bool(terrain_map_data.call("has_marker", spawn_marker_id)):
			errors.append("enemy_groups[%d].spawn_marker_id does not exist in map: %s" % [group_index, spawn_marker_id])
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
		var tactic_validation: Dictionary = ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("validate_config", group.get("tactics", {}), _get_terrain_grid_size(terrain_map_data))
		for error_variant in PackedStringArray(tactic_validation.get("errors", PackedStringArray())):
			errors.append("enemy_groups[%d].tactics.%s" % [group_index, String(error_variant)])
	return result


func _validate_tactical_authoring(terrain_map_data, errors: PackedStringArray) -> void:
	var risk: Dictionary = get_air_asset_risk_config()
	var risk_profile: String = String(risk.get("profile_id", "none")).strip_edges()
	var lz_threat_zone_id: String = String(risk.get("lz_threat_zone_id", "")).strip_edges()
	if not lz_threat_zone_id.is_empty() and terrain_map_data != null and terrain_map_data.has_method("has_marker") and not bool(terrain_map_data.call("has_marker", lz_threat_zone_id)):
		errors.append("tactical_authoring.air_asset_risk.lz_threat_zone_id does not exist in map: %s" % lz_threat_zone_id)
	if risk_profile == "loss_capable" and get_enemy_air_asset_threats(terrain_map_data).is_empty():
		errors.append("tactical_authoring.air_asset_risk loss_capable needs at least one anti-armor enemy group")


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
			"tactics": ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("normalize_config", group_dict.get("tactics", {}), Vector2i.ZERO),
		}
		var display_text: String = String(group_dict.get("display_name", "")).strip_edges()
		if not display_text.is_empty():
			group["display_name"] = display_text
		var spawn_marker_id: String = String(group_dict.get("spawn_marker_id", "")).strip_edges()
		if not spawn_marker_id.is_empty():
			group["spawn_marker_id"] = spawn_marker_id
		if group_dict.has("spawn_position") and _is_vector2_payload(group_dict.get("spawn_position", null)):
			group["spawn_position"] = _coerce_vector2(group_dict.get("spawn_position", Vector2.ZERO), Vector2.ZERO)
		var group_notes: PackedStringArray = _coerce_notes(group_dict.get("notes", []))
		if not group_notes.is_empty():
			group["notes"] = Array(group_notes)
		result.append(group)
	return result


func _coerce_tactical_authoring(raw_data: Dictionary) -> Dictionary:
	var result: Dictionary = DEFAULT_TACTICAL_AUTHORING.duplicate(true)
	var raw: Dictionary = raw_data.duplicate(true)
	var communication_intensity: String = _normalize_list_value(raw.get("communication_intensity", result.get("communication_intensity", "normal")), ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_communication_intensities"), "normal")
	result["communication_intensity"] = communication_intensity
	var fireteam_defaults: Dictionary = Dictionary(DEFAULT_TACTICAL_AUTHORING.get("fireteam_defaults", {})).duplicate(true)
	fireteam_defaults.merge(Dictionary(raw.get("fireteam_defaults", {})), true)
	fireteam_defaults["advance_style"] = ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("normalize_advance_style", fireteam_defaults.get("advance_style", "bounding"), "bounding")
	fireteam_defaults["security_mode"] = _normalize_list_value(fireteam_defaults.get("security_mode", "360"), ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_security_modes"), "360")
	result["fireteam_defaults"] = fireteam_defaults
	var risk_input: Dictionary = {}
	var raw_risk = raw.get("air_asset_risk", raw.get("air_asset_risk_profile", {}))
	if typeof(raw_risk) == TYPE_DICTIONARY:
		risk_input = Dictionary(raw_risk)
	elif not String(raw_risk).strip_edges().is_empty():
		risk_input["profile_id"] = String(raw_risk).strip_edges()
	var risk: Dictionary = Dictionary(DEFAULT_TACTICAL_AUTHORING.get("air_asset_risk", {})).duplicate(true)
	risk.merge(risk_input, true)
	risk["profile_id"] = _normalize_list_value(risk.get("profile_id", risk.get("risk_profile", "none")), ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_air_asset_risk_profiles"), "none")
	risk["enemy_group_id"] = String(risk.get("enemy_group_id", "")).strip_edges()
	risk["lz_threat_zone_id"] = String(risk.get("lz_threat_zone_id", risk.get("lz_threat_marker_id", ""))).strip_edges()
	risk["warning_required_before_damage"] = bool(risk.get("warning_required_before_damage", true))
	risk["loss_consequence"] = String(risk.get("loss_consequence", "replacement_recovery")).strip_edges()
	result["air_asset_risk"] = risk
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
		if group.has("spawn_position"):
			serialized_group["spawn_position"] = _serialize_vector2(_coerce_vector2(group.get("spawn_position", Vector2.ZERO), Vector2.ZERO))
		serialized_group["tactics"] = ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("serialize_config", group.get("tactics", {}), Vector2i.ZERO)
		result.append(serialized_group)
	return result


func _serialize_tactical_authoring() -> Dictionary:
	return _coerce_tactical_authoring(tactical_authoring)


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


static func _get_terrain_grid_size(terrain_map_data) -> Vector2i:
	if terrain_map_data != null and terrain_map_data.has_method("get_grid_size"):
		return terrain_map_data.call("get_grid_size")
	return Vector2i.ZERO


static func _normalize_list_value(value: Variant, allowed_values: PackedStringArray, fallback: String) -> String:
	var normalized: String = String(value).strip_edges().to_lower()
	if allowed_values.has(normalized):
		return normalized
	return fallback
