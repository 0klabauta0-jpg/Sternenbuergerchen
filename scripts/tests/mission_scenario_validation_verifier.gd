extends SceneTree
## Replaces the scenario-validation rules of the removed task_156_verifier on the Hex map
## Ground_Mission01_32x32. Scenario data is built in memory; the only file written is a
## roundtrip scratch file under user://, removed at the end.

const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")
const VALID_MAP_PATH: String = "res://maps/Ground_Mission01_32x32.json"
const ROUNDTRIP_PATH: String = "user://mission_scenario_validation_roundtrip.json"

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
	_test_roundtrip()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ROUNDTRIP_PATH))
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
	var data: Dictionary = _valid_scenario_dict("reject_lz")
	data["lz_position"] = {"x": 1.0, "y": 2.0}
	data["dropship"] = {"landing_zone": {"x": 3.0, "y": 4.0}}
	var scenario = MISSION_SCENARIO_DATA_SCRIPT.new(data)
	_assert(_has_error(scenario, "LZ must not be stored in mission scenarios"), "LZ fields anywhere in the scenario report 'LZ must not be stored in mission scenarios'")
	var serialized: Dictionary = Dictionary(scenario.call("to_dict"))
	_assert(not _has_key_recursive(serialized, "lz_position") and not _has_key_recursive(serialized, "landing_zone"), "Rejected LZ fields are not serialized")


func _test_roundtrip() -> void:
	var scenario = MISSION_SCENARIO_DATA_SCRIPT.new(_valid_scenario_dict("roundtrip"))
	_assert(scenario.call("save_to_file", ROUNDTRIP_PATH) == OK, "Scenario saves to user:// JSON")
	var loaded = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", ROUNDTRIP_PATH)
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
