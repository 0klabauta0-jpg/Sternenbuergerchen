class_name MissionScenarioData
extends RefCounted

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const ENEMY_TEAM_TACTICS_PROFILE_SCRIPT: GDScript = preload("res://scripts/tactical/enemy_team_tactics_profile.gd")
const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")

const CONTRACT_VERSION: int = 1
const DEFAULT_CAPTURE_RADIUS: float = 80.0
const DEFAULT_TEAM_ID: String = "team_bravo"
const DEFAULT_PATROL_MODE: String = "pre_contact"
const WIN_CONDITION_ELIMINATION: String = "elimination"
const WIN_CONDITION_OBJECTIVE_CAPTURE: String = "objective_capture"
const WIN_CONDITION_OBJECTIVE_DEFENSE: String = "objective_defense"
const ALLOWED_WIN_CONDITIONS: PackedStringArray = [
	WIN_CONDITION_ELIMINATION,
	WIN_CONDITION_OBJECTIVE_CAPTURE,
	WIN_CONDITION_OBJECTIVE_DEFENSE,
]
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
const BRIEFING_MINIMAP_MODE_NONE: String = "none"
const BRIEFING_MINIMAP_MODE_TERRAIN_ONLY: String = "terrain_only"
const ALLOWED_BRIEFING_MINIMAP_MODES: PackedStringArray = [
	BRIEFING_MINIMAP_MODE_NONE,
	BRIEFING_MINIMAP_MODE_TERRAIN_ONLY,
]
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
var win_condition: String = ""
var mission_slot_count_override: int = -1
var objective: Dictionary = {}
var enemy_groups: Array = []
var wave_config: Dictionary = {}
var patrol_bindings: Array = []
var tactical_authoring: Dictionary = {}
var briefing: Dictionary = {}
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

	var file_text: String = file.get_as_text()
	if file_text.strip_edges().is_empty():
		scenario._load_issues.append("Scenario file is empty: %s" % path)
		return scenario
	if _contains_nul_codepoint(file_text):
		scenario._load_issues.append("Scenario file contains NUL bytes and was not parsed: %s" % path)
		return scenario

	var parsed_json: Variant = JSON.parse_string(file_text)
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

	var json_text: String = JSON.stringify(to_dict(), "\t") + "\n"
	file.store_string(json_text)
	file.flush()
	return OK


static func _contains_nul_codepoint(text: String) -> bool:
	for index in range(text.length()):
		if text.unicode_at(index) == 0:
			return true
	return false


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
	if not win_condition.is_empty():
		data["win_condition"] = win_condition
	if mission_slot_count_override > 0:
		data["mission_slot_count_override"] = mission_slot_count_override
	var serialized_briefing: Dictionary = _serialize_briefing()
	if _briefing_has_content(serialized_briefing):
		data["briefing"] = serialized_briefing
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
	if not win_condition.is_empty() and not ALLOWED_WIN_CONDITIONS.has(win_condition):
		errors.append("win_condition is not allowed: %s" % win_condition)
	if mission_slot_count_override != -1 and mission_slot_count_override < 1:
		errors.append("mission_slot_count_override must be unset or >= 1")

	var terrain_map_data = _load_referenced_map(errors)
	_validate_objective(terrain_map_data, errors)
	var enemy_ids: PackedStringArray = _validate_enemy_groups(terrain_map_data, errors)
	_validate_wave_config(errors)
	_validate_patrol_bindings(terrain_map_data, enemy_ids, errors)
	_validate_tactical_authoring(terrain_map_data, errors)
	_validate_briefing(errors)

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


func get_briefing() -> Dictionary:
	return _coerce_briefing(briefing).duplicate(true)


func get_briefing_recommended_loadout() -> Array:
	return Array(get_briefing().get("recommended_loadout", [])).duplicate(true)


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
	win_condition = _coerce_win_condition(data.get("win_condition", ""))
	mission_slot_count_override = int(data.get("mission_slot_count_override", -1))
	objective = _coerce_objective(Dictionary(data.get("objective", {})))
	enemy_groups = _coerce_enemy_groups(data.get("enemy_groups", []))
	wave_config = _coerce_wave_config(Dictionary(data.get("wave_config", {})))
	patrol_bindings = _coerce_patrol_bindings(data.get("patrol_bindings", []))
	tactical_authoring = _coerce_tactical_authoring(Dictionary(data.get("tactical_authoring", data.get("tactical_profile", {}))))
	briefing = _coerce_briefing(data.get("briefing", data.get("mission_briefing", {})))
	notes = _coerce_notes(data.get("notes", []))


func _coerce_win_condition(value: Variant) -> String:
	return String(value).strip_edges().to_lower()


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


func _validate_briefing(errors: PackedStringArray) -> void:
	var normalized_briefing: Dictionary = get_briefing()
	if normalized_briefing.is_empty():
		return
	var minimap_mode: String = String(normalized_briefing.get("minimap_mode", BRIEFING_MINIMAP_MODE_TERRAIN_ONLY)).strip_edges().to_lower()
	if not ALLOWED_BRIEFING_MINIMAP_MODES.has(minimap_mode):
		errors.append("briefing.minimap_mode is not allowed: %s" % minimap_mode)
	var background_image_path: String = String(normalized_briefing.get("background_image_path", "")).strip_edges()
	if not background_image_path.is_empty():
		if not background_image_path.begins_with("res://"):
			errors.append("briefing.background_image_path must use res://: %s" % background_image_path)
		elif not ResourceLoader.exists(background_image_path) and not FileAccess.file_exists(background_image_path):
			errors.append("briefing.background_image_path does not exist: %s" % background_image_path)
	for loadout_index in range(Array(normalized_briefing.get("recommended_loadout", [])).size()):
		var entry: Dictionary = Dictionary(Array(normalized_briefing.get("recommended_loadout", []))[loadout_index])
		for weapon_id_variant in Array(entry.get("weapon_ids", [])):
			var weapon_id: String = String(weapon_id_variant).strip_edges()
			if not bool(WEAPON_DATA_SCRIPT.call("is_valid_weapon_id", weapon_id)):
				errors.append("briefing.recommended_loadout[%d].weapon_ids contains unknown weapon id: %s" % [loadout_index, weapon_id])


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


func _coerce_briefing(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var raw: Dictionary = Dictionary(value)
	var result: Dictionary = {}
	var title: String = String(raw.get("title", raw.get("headline", ""))).strip_edges()
	if not title.is_empty():
		result["title"] = title
	var summary: String = String(raw.get("summary", raw.get("body", ""))).strip_edges()
	if not summary.is_empty():
		result["summary"] = summary
	var background_image_path: String = String(raw.get("background_image_path", raw.get("background_path", raw.get("image_path", "")))).strip_edges()
	if not background_image_path.is_empty():
		result["background_image_path"] = background_image_path
	var objectives: Array = _coerce_briefing_text_entries(raw.get("objectives", raw.get("objective_lines", [])))
	if not objectives.is_empty():
		result["objectives"] = objectives
	var threats: Array = _coerce_briefing_text_entries(raw.get("threats", raw.get("threat_lines", [])))
	if not threats.is_empty():
		result["threats"] = threats
	var recommended_loadout: Array = _coerce_briefing_loadout_entries(raw.get("recommended_loadout", raw.get("loadout_recommendations", [])))
	if not recommended_loadout.is_empty():
		result["recommended_loadout"] = recommended_loadout
	var annotations: Array = _coerce_briefing_annotations(raw.get("annotations", []))
	if not annotations.is_empty():
		result["annotations"] = annotations
	var minimap_mode_value = raw.get("minimap_mode", BRIEFING_MINIMAP_MODE_TERRAIN_ONLY)
	if typeof(raw.get("minimap", null)) == TYPE_DICTIONARY:
		minimap_mode_value = Dictionary(raw.get("minimap", {})).get("mode", minimap_mode_value)
	var minimap_mode: String = String(minimap_mode_value).strip_edges().to_lower()
	if minimap_mode.is_empty():
		minimap_mode = BRIEFING_MINIMAP_MODE_TERRAIN_ONLY
	if _briefing_has_content(result) or _briefing_has_minimap_authoring(raw):
		result["minimap_mode"] = minimap_mode
	return result


func _coerce_briefing_text_entries(value: Variant) -> Array:
	var result: Array = []
	if value is PackedStringArray:
		value = Array(PackedStringArray(value))
	elif typeof(value) == TYPE_STRING:
		value = [String(value)]
	if not (value is Array):
		return result
	for item_variant in Array(value):
		if typeof(item_variant) == TYPE_DICTIONARY:
			var item_dict: Dictionary = Dictionary(item_variant)
			var text: String = String(item_dict.get("text", item_dict.get("label", ""))).strip_edges()
			if text.is_empty():
				continue
			var entry: Dictionary = {"text": text}
			var target_id: String = String(item_dict.get("target_id", "")).strip_edges()
			if not target_id.is_empty():
				entry["target_id"] = target_id
			result.append(entry)
			continue
		var item_text: String = String(item_variant).strip_edges()
		if not item_text.is_empty() and not result.has(item_text):
			result.append(item_text)
	return result


func _coerce_briefing_loadout_entries(value: Variant) -> Array:
	var result: Array = []
	if typeof(value) == TYPE_DICTIONARY:
		value = [value]
	elif typeof(value) == TYPE_STRING:
		value = [{"weapon_ids": [String(value)]}]
	if not (value is Array):
		return result
	for entry_variant in Array(value):
		var raw_entry: Dictionary = {}
		if typeof(entry_variant) == TYPE_DICTIONARY:
			raw_entry = Dictionary(entry_variant)
		elif typeof(entry_variant) == TYPE_STRING:
			raw_entry = {"weapon_ids": [String(entry_variant)]}
		else:
			continue
		var entry: Dictionary = {}
		var role_id: String = String(raw_entry.get("role_id", raw_entry.get("role", ""))).strip_edges().to_lower()
		if not role_id.is_empty():
			entry["role_id"] = role_id
		var label: String = String(raw_entry.get("label", "")).strip_edges()
		if not label.is_empty():
			entry["label"] = label
		var armor_id: String = String(raw_entry.get("armor_id", raw_entry.get("armor", ""))).strip_edges().to_lower()
		if not armor_id.is_empty():
			entry["armor_id"] = armor_id
		var count: int = int(raw_entry.get("count", 0))
		if count > 0:
			entry["count"] = count
		var weapon_ids: PackedStringArray = _coerce_briefing_weapon_ids(raw_entry.get("weapon_ids", raw_entry.get("weapons", raw_entry.get("weapon_id", []))))
		if not weapon_ids.is_empty():
			entry["weapon_ids"] = Array(weapon_ids)
		var reason: String = String(raw_entry.get("reason", "")).strip_edges()
		if not reason.is_empty():
			entry["reason"] = reason
		if not entry.is_empty():
			result.append(entry)
	return result


func _coerce_briefing_weapon_ids(value: Variant) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if value is PackedStringArray:
		value = Array(PackedStringArray(value))
	elif typeof(value) == TYPE_STRING:
		value = [String(value)]
	if not (value is Array):
		return result
	for weapon_variant in Array(value):
		var normalized_weapon_id: String = String(WEAPON_DATA_SCRIPT.call("normalize_weapon_id", String(weapon_variant))).strip_edges()
		if normalized_weapon_id.is_empty():
			continue
		if not bool(WEAPON_DATA_SCRIPT.call("is_valid_weapon_id", normalized_weapon_id)):
			continue
		if not result.has(normalized_weapon_id):
			result.append(normalized_weapon_id)
	return result


func _coerce_briefing_annotations(value: Variant) -> Array:
	var result: Array = []
	if typeof(value) == TYPE_DICTIONARY:
		value = [value]
	elif typeof(value) == TYPE_STRING:
		value = [{"kind": "note", "text": String(value)}]
	if not (value is Array):
		return result
	for annotation_variant in Array(value):
		var raw_annotation: Dictionary = {}
		if typeof(annotation_variant) == TYPE_DICTIONARY:
			raw_annotation = Dictionary(annotation_variant)
		elif typeof(annotation_variant) == TYPE_STRING:
			raw_annotation = {"kind": "note", "text": String(annotation_variant)}
		else:
			continue
		var annotation: Dictionary = {}
		var kind: String = String(raw_annotation.get("kind", "note")).strip_edges().to_lower()
		annotation["kind"] = kind if not kind.is_empty() else "note"
		var text: String = String(raw_annotation.get("text", raw_annotation.get("label", ""))).strip_edges()
		if not text.is_empty():
			annotation["text"] = text
		var target_id: String = String(raw_annotation.get("target_id", "")).strip_edges()
		if not target_id.is_empty():
			annotation["target_id"] = target_id
		if raw_annotation.has("position") and _is_vector2_payload(raw_annotation.get("position", null)):
			annotation["position"] = _serialize_vector2(_coerce_vector2(raw_annotation.get("position", Vector2.ZERO), Vector2.ZERO))
		var radius: float = float(raw_annotation.get("radius", 0.0))
		if radius > 0.0:
			annotation["radius"] = radius
		if annotation.size() > 1:
			result.append(annotation)
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
	var result: Dictionary = _coerce_tactical_authoring(tactical_authoring)
	var risk: Dictionary = Dictionary(result.get("air_asset_risk", {})).duplicate(true)
	for optional_key in ["enemy_group_id", "lz_threat_zone_id"]:
		if String(risk.get(optional_key, "")).strip_edges().is_empty():
			risk.erase(optional_key)
	result["air_asset_risk"] = risk
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


func _serialize_briefing() -> Dictionary:
	return _coerce_briefing(briefing)


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


func _briefing_has_content(data: Dictionary) -> bool:
	if data.is_empty():
		return false
	for text_key in ["title", "summary", "background_image_path"]:
		if not String(data.get(text_key, "")).strip_edges().is_empty():
			return true
	for array_key in ["objectives", "threats", "recommended_loadout", "annotations"]:
		if Array(data.get(array_key, [])).size() > 0:
			return true
	var minimap_mode: String = String(data.get("minimap_mode", "")).strip_edges().to_lower()
	return not minimap_mode.is_empty() and minimap_mode != BRIEFING_MINIMAP_MODE_TERRAIN_ONLY


func _briefing_has_minimap_authoring(data: Dictionary) -> bool:
	return data.has("minimap_mode") or data.has("minimap")


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
