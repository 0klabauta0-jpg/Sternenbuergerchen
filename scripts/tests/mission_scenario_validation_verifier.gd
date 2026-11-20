extends SceneTree
## Replaces the scenario-validation rules of the removed task_156_verifier on the Hex map
## Ground_Mission01_32x32. Scenario data is built in memory; the only file written is a
## roundtrip scratch file under user://, removed at the end.

const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")
const VALID_MAP_PATH: String = "res://maps/Ground_Mission01_32x32.json"
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const ROUNDTRIP_PATH: String = "user://mission_scenario_validation_roundtrip.json"
const REQUIRED_LZ_KEYS: Array = ["lz", "player_lz", "requires_player_lz", "lz_position", "has_lz_position", "drop_lz", "dropship_lz", "landing_zone", "landing_zone_position"]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Mission Scenario Validation Verifier (Hex map) ===")
	_test_valid_scenario_on_hex_map()
	_test_missing_map()
	_test_missing_objective()
	_test_duplicate_enemy_ids()
	_test_patrol_binding_validation()
	_test_lz_fields_rejected()
	_test_objective_position_from_map()
	_test_roundtrip()
	_remove_roundtrip_file()
	print("MISSION_SCENARIO_VALIDATION passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_valid_scenario_on_hex_map() -> void:
	var scenario = MISSION_SCENARIO_DATA_SCRIPT.new(_valid_scenario_dict("valid_hex"))
	var errors: PackedStringArray = _errors(scenario)
	_assert(errors.is_empty(), "Valid scenario on the Hex map validates (errors: %s)" % [", ".join(errors)])
	_assert(bool(scenario.call("references_terrain_without_duplication")), "Valid scenario references the map without duplicating terrain fields")


func _test_missing_map() -> void:
	var data: Dictionary = _valid_scenario_dict("missing_map")
	data["map_file_path"] = "res://maps/does_not_exist_scenario_validation.json"
	_assert(_has_error(MISSION_SCENARIO_DATA_SCRIPT.new(data), "map_file_path does not exist"), "Missing map reports 'map_file_path does not exist'")


func _test_missing_objective() -> void:
	var empty_data: Dictionary = _valid_scenario_dict("missing_objective")
	empty_data["objective"] = {}
	_assert(_has_error(MISSION_SCENARIO_DATA_SCRIPT.new(empty_data), "objective needs marker_id or position"), "Empty objective reports 'objective needs marker_id or position'")
	var marker_data: Dictionary = _valid_scenario_dict("missing_marker")
	marker_data["objective"] = {"marker_id": "does_not_exist_objective", "capture_radius": 80.0}
	_assert(_has_error(MISSION_SCENARIO_DATA_SCRIPT.new(marker_data), "objective marker does not exist"), "Objective marker absent from the Hex map reports 'objective marker does not exist'")


func _test_duplicate_enemy_ids() -> void:
	var data: Dictionary = _valid_scenario_dict("duplicate_enemy")
	data["enemy_groups"] = [
		{"group_id": "red_a", "team_id": "team_bravo", "spawn_marker_id": "spawn_bravo", "enemy_ids": ["enemy_delta"]},
		{"group_id": "red_b", "team_id": "team_bravo", "spawn_marker_id": "spawn_bravo", "enemy_ids": ["enemy_delta"]},
	]
	_assert(_has_error(MISSION_SCENARIO_DATA_SCRIPT.new(data), "enemy id is used more than once"), "Duplicate enemy ids report 'enemy id is used more than once'")


func _test_patrol_binding_validation() -> void:
	var spawn_data: Dictionary = _valid_scenario_dict("spawn_binding")
	spawn_data["patrol_bindings"] = [{"target_id": "spawn_bravo", "patrol_path_id": "enemy_delta", "mode": "pre_contact"}]
	var spawn_errors: PackedStringArray = _errors(MISSION_SCENARIO_DATA_SCRIPT.new(spawn_data))
	_assert(spawn_errors.is_empty(), "Patrol binding may target a map spawn id (errors: %s)" % [", ".join(spawn_errors)])
	var bad_data: Dictionary = _valid_scenario_dict("invalid_patrol_binding")
	bad_data["patrol_bindings"] = [{"target_id": "unknown_enemy_or_spawn", "patrol_path_id": "enemy_delta", "mode": "pre_contact"}]
	_assert(_has_error(MISSION_SCENARIO_DATA_SCRIPT.new(bad_data), "target_id is not an enemy"), "Patrol binding to an unknown target reports 'target_id is not an enemy'")


func _test_lz_fields_rejected() -> void:
	# Fixed minimum list: an accidentally emptied or shrunk FORBIDDEN_LZ_KEYS must show up here.
	var game_keys: PackedStringArray = MISSION_SCENARIO_DATA_SCRIPT.FORBIDDEN_LZ_KEYS
	for key: String in REQUIRED_LZ_KEYS:
		_assert(game_keys.has(key), "FORBIDDEN_LZ_KEYS contains '%s'" % key)
	var keys: PackedStringArray = PackedStringArray(REQUIRED_LZ_KEYS)
	for key: String in game_keys:
		if not keys.has(key):
			keys.append(key)
	# One scenario per forbidden key, exactly that one field, exact path in the message.
	for key: String in keys:
		var data: Dictionary = _valid_scenario_dict("reject_lz_" + key)
		data[key] = {"x": 1.0, "y": 2.0}
		var errors: PackedStringArray = _lz_errors(MISSION_SCENARIO_DATA_SCRIPT.new(data))
		_assert(errors.size() == 1 and errors[0] == "LZ must not be stored in mission scenarios: scenario.%s" % key, "Top-level '%s' reports exactly 'LZ must not be stored in mission scenarios: scenario.%s' (got %s)" % [key, key, errors])
	# Nested in a dictionary and inside an array: the path names the location.
	var nested: Dictionary = _valid_scenario_dict("reject_lz_nested")
	nested["dropship"] = {"player_lz": {"x": 3.0, "y": 4.0}}
	var nested_errors: PackedStringArray = _lz_errors(MISSION_SCENARIO_DATA_SCRIPT.new(nested))
	_assert(nested_errors.size() == 1 and nested_errors[0] == "LZ must not be stored in mission scenarios: scenario.dropship.player_lz", "Nested dropship.player_lz reports its path (got %s)" % [nested_errors])
	var in_array: Dictionary = _valid_scenario_dict("reject_lz_array")
	in_array["waves"] = [{"id": "w1"}, {"lz": {"x": 5.0, "y": 6.0}}]
	var array_errors: PackedStringArray = _lz_errors(MISSION_SCENARIO_DATA_SCRIPT.new(in_array))
	_assert(array_errors.size() == 1 and array_errors[0] == "LZ must not be stored in mission scenarios: scenario.waves[1].lz", "Array entry waves[1].lz reports its path (got %s)" % [array_errors])
	var serial_data: Dictionary = _valid_scenario_dict("reject_lz_serialize")
	serial_data["lz_position"] = {"x": 1.0, "y": 2.0}
	serial_data["dropship"] = {"landing_zone": {"x": 3.0, "y": 4.0}}
	var serialized: Dictionary = Dictionary(MISSION_SCENARIO_DATA_SCRIPT.new(serial_data).call("to_dict"))
	_assert(not _has_key_recursive(serialized, "lz_position") and not _has_key_recursive(serialized, "landing_zone"), "Rejected LZ fields are not serialized")


func _test_objective_position_from_map() -> void:
	var map = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", VALID_MAP_PATH)
	var scenario = MISSION_SCENARIO_DATA_SCRIPT.new(_valid_scenario_dict("objective_position"))
	var marker_position: Vector2 = map.call("get_marker_position", "objective_point")
	var resolved: Vector2 = scenario.call("get_objective_position", map, Vector2(-7.0, -9.0))
	_assert(marker_position.distance_to(Vector2.ZERO) > 0.5, "Map marker objective_point sits away from the origin")
	_assert(resolved.distance_to(marker_position) < 0.001, "get_objective_position resolves the marker position from the Hex map (%s vs %s)" % [resolved, marker_position])
	var unknown_data: Dictionary = _valid_scenario_dict("objective_unknown_marker")
	unknown_data["objective"] = {"marker_id": "does_not_exist_objective", "capture_radius": 80.0}
	var unknown_scenario = MISSION_SCENARIO_DATA_SCRIPT.new(unknown_data)
	_assert(unknown_scenario.call("get_objective_position", map, Vector2(-7.0, -9.0)) == Vector2(-7.0, -9.0), "Unknown objective marker resolves to the fallback position")
	_assert(scenario.call("get_objective_position", null, Vector2(-7.0, -9.0)) == Vector2(-7.0, -9.0), "Without map data the objective position is the fallback")
	var position_data: Dictionary = _valid_scenario_dict("objective_explicit_position")
	position_data["objective"] = {"position": {"x": 123.0, "y": 45.0}, "capture_radius": 80.0}
	var position_scenario = MISSION_SCENARIO_DATA_SCRIPT.new(position_data)
	_assert(position_scenario.call("get_objective_position", map, Vector2(-7.0, -9.0)) == Vector2(123.0, 45.0), "Explicit objective position wins over the map")


func _test_roundtrip() -> void:
	var scenario = MISSION_SCENARIO_DATA_SCRIPT.new(_valid_scenario_dict("roundtrip"))
	_assert(scenario.call("save_to_file", ROUNDTRIP_PATH) == OK, "Scenario saves to user:// JSON")
	var loaded = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", ROUNDTRIP_PATH)
	_remove_roundtrip_file()
	var loaded_errors: PackedStringArray = _errors(loaded)
	_assert(loaded_errors.is_empty(), "Saved scenario loads and validates (errors: %s)" % [", ".join(loaded_errors)])
	_assert(JSON.stringify(loaded.call("to_dict")) == JSON.stringify(scenario.call("to_dict")), "Save/load roundtrip keeps the full scenario dictionary")


func _valid_scenario_dict(scenario_id: String) -> Dictionary:
	return {
		"version": 1,
		"scenario_id": scenario_id,
		"display_name": "Scenario Validation Test",
		"map_file_path": VALID_MAP_PATH,
		"time_limit_seconds": 600.0,
		"mission_slot_count_override": 8,
		"objective": {"marker_id": "objective_point", "capture_radius": 80.0},
		"enemy_groups": [
			{"group_id": "red_test_group", "team_id": "team_bravo", "spawn_marker_id": "spawn_bravo", "enemy_ids": ["enemy_delta", "enemy_echo"]},
		],
		"wave_config": {"wave_count": 1, "units_per_wave": 2, "first_wave_delay_seconds": 0.0, "wave_delay_seconds": 90.0},
		"patrol_bindings": [
			{"target_id": "enemy_delta", "patrol_path_id": "enemy_delta", "mode": "pre_contact"},
			{"target_id": "enemy_echo", "patrol_path_id": "enemy_echo", "mode": "pre_contact"},
		],
		"notes": ["scenario validation verifier fixture"],
	}


func _remove_roundtrip_file() -> void:
	if FileAccess.file_exists(ROUNDTRIP_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ROUNDTRIP_PATH))


func _lz_errors(scenario) -> PackedStringArray:
	var result := PackedStringArray()
	for error_variant in _errors(scenario):
		if String(error_variant).begins_with("LZ must not be stored"):
			result.append(String(error_variant))
	return result


func _errors(scenario) -> PackedStringArray:
	return PackedStringArray(Dictionary(scenario.call("validate")).get("errors", PackedStringArray()))


func _has_error(scenario, needle: String) -> bool:
	for error_variant in _errors(scenario):
		if String(error_variant).contains(needle):
			return true
	return false


func _has_key_recursive(value: Variant, key: String) -> bool:
	if typeof(value) == TYPE_DICTIONARY:
		for key_variant in Dictionary(value).keys():
			if String(key_variant) == key or _has_key_recursive(Dictionary(value).get(key_variant), key):
				return true
	elif typeof(value) == TYPE_ARRAY:
		for item_variant in Array(value):
			if _has_key_recursive(item_variant, key):
				return true
	return false


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
