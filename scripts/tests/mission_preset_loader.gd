class_name MissionPresetLoader
extends RefCounted

const PRESET_DIR: String = "res://data/mission_presets"
const REQUIRED_PRESET_IDS: PackedStringArray = [
	"attack_area_two_contacts",
	"defend_area_contact_relay",
	"patrol_contact_transition",
	"dropship_insertion_first_contact",
	"take_area_objective",
]
const FORBIDDEN_LZ_KEYS: PackedStringArray = [
	"lz",
	"lz_position",
	"has_lz_position",
	"drop_lz",
	"dropship_lz",
	"landing_zone",
	"landing_zone_position",
]


static func get_required_preset_ids() -> PackedStringArray:
	return REQUIRED_PRESET_IDS.duplicate()


static func get_preset_path(preset_id: String) -> String:
	var normalized_id: String = preset_id.strip_edges()
	if normalized_id.begins_with("res://") or normalized_id.begins_with("user://"):
		return normalized_id
	if normalized_id.ends_with(".json"):
		return "%s/%s" % [PRESET_DIR, normalized_id]
	return "%s/%s.json" % [PRESET_DIR, normalized_id]


static func load_preset(preset_id_or_path: String) -> Dictionary:
	var path: String = get_preset_path(preset_id_or_path)
	if path.is_empty() or not FileAccess.file_exists(path):
		return {
			"_load_error": "Preset file not found: %s" % path,
			"_preset_path": path,
		}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {
			"_load_error": "Preset file could not be opened: %s" % path,
			"_preset_path": path,
		}

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {
			"_load_error": "Preset file is not a JSON object: %s" % path,
			"_preset_path": path,
		}

	var preset: Dictionary = Dictionary(parsed).duplicate(true)
	preset["_preset_path"] = path
	return preset


static func load_required_presets() -> Array:
	var presets: Array = []
	for preset_id in REQUIRED_PRESET_IDS:
		presets.append(load_preset(String(preset_id)))
	return presets


static func validate_preset(preset: Dictionary) -> Dictionary:
	var errors: PackedStringArray = []
	if preset.has("_load_error"):
		errors.append(String(preset.get("_load_error", "")))
		return _validation_result(errors)

	_collect_forbidden_lz_keys(preset, "preset", errors)
	var preset_id: String = String(preset.get("preset_id", "")).strip_edges()
	if preset_id.is_empty():
		errors.append("preset_id is required")

	var map_file_path: String = String(preset.get("map_file_path", "")).strip_edges()
	if map_file_path.is_empty():
		errors.append("map_file_path is required")
	elif not FileAccess.file_exists(map_file_path):
		errors.append("map_file_path does not exist: %s" % map_file_path)

	var objective: Dictionary = Dictionary(preset.get("objective", {}))
	if objective.is_empty():
		errors.append("objective is required")
	elif String(objective.get("marker_id", "")).strip_edges().is_empty() and not _is_vector2_payload(objective.get("position", null)):
		errors.append("objective needs marker_id or position")

	var enemy_setup: Array = Array(preset.get("enemy_setup", []))
	if enemy_setup.is_empty():
		errors.append("enemy_setup needs at least one existing test unit")
	else:
		for index in range(enemy_setup.size()):
			var enemy_entry: Dictionary = Dictionary(enemy_setup[index])
			var unit_id: String = String(enemy_entry.get("unit_id", "")).strip_edges()
			var node_path: String = String(enemy_entry.get("node_path", "")).strip_edges()
			if unit_id.is_empty():
				errors.append("enemy_setup[%d].unit_id is required" % index)
			if node_path.is_empty():
				errors.append("enemy_setup[%d].node_path is required" % index)
			if enemy_entry.has("world_position") and not _is_vector2_payload(enemy_entry.get("world_position", null)):
				errors.append("enemy_setup[%d].world_position must contain x/y" % index)

	var wave_config: Dictionary = Dictionary(preset.get("wave_config", {}))
	if wave_config.is_empty():
		errors.append("wave_config is required")
	else:
		if int(wave_config.get("wave_count", 0)) < 0:
			errors.append("wave_config.wave_count must be >= 0")
		if int(wave_config.get("units_per_wave", 0)) <= 0:
			errors.append("wave_config.units_per_wave must be > 0")
		if float(wave_config.get("first_wave_delay_seconds", 0.0)) < 0.0:
			errors.append("wave_config.first_wave_delay_seconds must be >= 0")
		if float(wave_config.get("wave_delay_seconds", 0.0)) < 0.0:
			errors.append("wave_config.wave_delay_seconds must be >= 0")

	var patrol_paths: Dictionary = Dictionary(preset.get("patrol_paths", {}))
	for unit_id_variant in patrol_paths.keys():
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty():
			errors.append("patrol_paths contains an empty unit id")
			continue
		var points: Array = Array(patrol_paths.get(unit_id_variant, []))
		if points.is_empty():
			errors.append("patrol_paths.%s needs at least one point" % unit_id)
		for point_index in range(points.size()):
			if not _is_vector2_payload(points[point_index]):
				errors.append("patrol_paths.%s[%d] must contain x/y" % [unit_id, point_index])

	return _validation_result(errors)


static func prepare_scene(scene: Node, preset: Dictionary) -> Dictionary:
	var errors: PackedStringArray = []
	if scene == null:
		errors.append("scene is null")
		return _validation_result(errors)

	var validation: Dictionary = validate_preset(preset)
	if not bool(validation.get("valid", false)):
		return validation

	scene.set_meta("mission_preset_id", String(preset.get("preset_id", "")))
	scene.set_meta("mission_preset_has_lz", false)

	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup == null:
		errors.append("MissionSetup node missing")
	else:
		_set_property_if_present(mission_setup, "map_file_path", String(preset.get("map_file_path", "")))

	var wave_controller := scene.get_node_or_null("EnemyWaveController")
	if wave_controller == null:
		errors.append("EnemyWaveController node missing")
	else:
		_apply_wave_config(wave_controller, Dictionary(preset.get("wave_config", {})))

	var combat_loop := scene.get_node_or_null("CombatLoopDriver")
	if combat_loop != null:
		_apply_combat_config(combat_loop, Dictionary(preset.get("combat", {})))

	return _validation_result(errors)


static func apply_runtime(scene: Node, preset: Dictionary) -> Dictionary:
	var errors: PackedStringArray = []
	if scene == null:
		errors.append("scene is null")
		return _validation_result(errors)

	var validation: Dictionary = validate_preset(preset)
	if not bool(validation.get("valid", false)):
		return validation

	var wave_controller := scene.get_node_or_null("EnemyWaveController")
	if wave_controller == null:
		errors.append("EnemyWaveController node missing")
	else:
		var patrol_paths: Dictionary = _build_patrol_path_dictionary(Dictionary(preset.get("patrol_paths", {})))
		if wave_controller.has_method("set_patrol_paths"):
			wave_controller.call("set_patrol_paths", patrol_paths)

	var enemy_setup: Array = Array(preset.get("enemy_setup", []))
	for enemy_variant in enemy_setup:
		var enemy_entry: Dictionary = Dictionary(enemy_variant)
		var enemy_node := scene.get_node_or_null(NodePath(String(enemy_entry.get("node_path", ""))))
		if enemy_node == null:
			errors.append("enemy node missing: %s" % String(enemy_entry.get("node_path", "")))
			continue
		if enemy_entry.has("world_position") and enemy_node is Node2D:
			(enemy_node as Node2D).global_position = _coerce_vector2(enemy_entry.get("world_position", {}), (enemy_node as Node2D).global_position)
		if enemy_node is CanvasItem:
			(enemy_node as CanvasItem).visible = true

	var combat_loop := scene.get_node_or_null("CombatLoopDriver")
	if combat_loop != null and combat_loop.has_method("_initialize_enemy_patrol_paths"):
		combat_loop.call("_initialize_enemy_patrol_paths")

	return _validation_result(errors)


static func _apply_wave_config(wave_controller: Node, wave_config: Dictionary) -> void:
	_set_property_if_present(wave_controller, "wave_count", int(wave_config.get("wave_count", wave_controller.get("wave_count"))))
	_set_property_if_present(wave_controller, "units_per_wave", int(wave_config.get("units_per_wave", wave_controller.get("units_per_wave"))))
	_set_property_if_present(wave_controller, "first_wave_delay_seconds", float(wave_config.get("first_wave_delay_seconds", wave_controller.get("first_wave_delay_seconds"))))
	_set_property_if_present(wave_controller, "wave_delay_seconds", float(wave_config.get("wave_delay_seconds", wave_controller.get("wave_delay_seconds"))))


static func _apply_combat_config(combat_loop: Node, combat_config: Dictionary) -> void:
	if combat_config.has("contact_range"):
		_set_property_if_present(combat_loop, "contact_range", float(combat_config.get("contact_range", 0.0)))
	if combat_config.has("win_condition"):
		_set_property_if_present(combat_loop, "win_condition", String(combat_config.get("win_condition", "")))


static func _set_property_if_present(node: Object, property_name: String, value: Variant) -> void:
	if node == null or property_name.is_empty():
		return
	for property_info in node.get_property_list():
		var info: Dictionary = Dictionary(property_info)
		if String(info.get("name", "")) == property_name:
			node.set(property_name, value)
			return


static func _build_patrol_path_dictionary(raw_patrol_paths: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for unit_id_variant in raw_patrol_paths.keys():
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty():
			continue
		var points: Array = []
		for point_variant in Array(raw_patrol_paths.get(unit_id_variant, [])):
			points.append(_coerce_vector2(point_variant, Vector2.ZERO))
		if not points.is_empty():
			result[unit_id] = points
	return result


static func _validation_result(errors: PackedStringArray) -> Dictionary:
	return {
		"valid": errors.is_empty(),
		"errors": errors,
	}


static func _collect_forbidden_lz_keys(value: Variant, path: String, errors: PackedStringArray) -> void:
	if typeof(value) == TYPE_DICTIONARY:
		var value_dict: Dictionary = value
		for key_variant in value_dict.keys():
			var key_text: String = String(key_variant).strip_edges().to_lower()
			var child_path: String = "%s.%s" % [path, key_text]
			if FORBIDDEN_LZ_KEYS.has(key_text):
				errors.append("LZ must not be stored in presets: %s" % child_path)
			_collect_forbidden_lz_keys(value_dict.get(key_variant), child_path, errors)
	elif typeof(value) == TYPE_ARRAY:
		var value_array: Array = value
		for index in range(value_array.size()):
			_collect_forbidden_lz_keys(value_array[index], "%s[%d]" % [path, index], errors)


static func _is_vector2_payload(value: Variant) -> bool:
	if value is Vector2 or value is Vector2i:
		return true
	if typeof(value) != TYPE_DICTIONARY:
		return false
	var value_dict: Dictionary = value
	return value_dict.has("x") and value_dict.has("y")


static func _coerce_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Vector2i:
		return Vector2(value.x, value.y)
	if typeof(value) == TYPE_DICTIONARY:
		var value_dict: Dictionary = value
		return Vector2(float(value_dict.get("x", fallback.x)), float(value_dict.get("y", fallback.y)))
	return fallback
