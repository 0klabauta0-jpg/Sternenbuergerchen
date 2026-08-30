extends SceneTree

const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const SAMPLE_SCENARIO_IDS: PackedStringArray = [
	"attack_area_two_contacts",
	"defend_area_contact_relay",
	"patrol_contact_transition",
	"dropship_insertion_first_contact",
	"take_area_objective",
]
const SAMPLE_SCENARIO_DIR: String = "res://data/mission_scenarios"
const VALID_MAP_PATH: String = "res://maps/task_156_contract_map.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_156 Mission Scenario Data Contract Verifier ===")
	_test_roundtrip_load_save()
	_test_validation_reports_required_authoring_errors()
	_test_patrol_binding_validation()
	_test_lz_fields_are_rejected_and_not_serialized()
	_test_sample_scenario_files_reference_terrain_without_duplication()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit(1 if _failed > 0 else 0)
func _test_roundtrip_load_save() -> void:
	var scenario = MISSION_SCENARIO_DATA_SCRIPT.new(_valid_scenario_dict("roundtrip_contract"))
	var validation: Dictionary = Dictionary(scenario.call("validate"))
	_assert(bool(validation.get("valid", false)), "MissionScenarioData accepts the TASK_156 data contract")
	var save_path: String = "user://task_156_roundtrip_contract.json"
	var save_error: Error = scenario.call("save_to_file", save_path)
	_assert(save_error == OK, "MissionScenarioData saves scenario JSON")
	var loaded = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", save_path)
	var loaded_validation: Dictionary = Dictionary(loaded.call("validate"))
	if not bool(loaded_validation.get("valid", false)):
		print("TASK_156 roundtrip validation errors: %s" % [", ".join(PackedStringArray(loaded_validation.get("errors", PackedStringArray())))])
	_assert(bool(loaded_validation.get("valid", false)), "MissionScenarioData loads saved scenario JSON")
	_assert(JSON.stringify(loaded.call("to_dict")) == JSON.stringify(scenario.call("to_dict")), "MissionScenarioData roundtrips without contract data loss")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


func _test_validation_reports_required_authoring_errors() -> void:
	var missing_map_data: Dictionary = _valid_scenario_dict("missing_map")
	missing_map_data["map_file_path"] = "res://maps/does_not_exist_task_156.json"
	var missing_map = MISSION_SCENARIO_DATA_SCRIPT.new(missing_map_data)
	_assert(_validation_has_error(missing_map, "map_file_path does not exist"), "Validation reports missing referenced map")

	var missing_objective_data: Dictionary = _valid_scenario_dict("missing_objective")
	missing_objective_data["objective"] = {}
	var missing_objective = MISSION_SCENARIO_DATA_SCRIPT.new(missing_objective_data)
	_assert(_validation_has_error(missing_objective, "objective needs marker_id or position"), "Validation reports missing objective marker or position")

	var missing_marker_data: Dictionary = _valid_scenario_dict("missing_marker")
	missing_marker_data["objective"] = {
		"marker_id": "does_not_exist_objective",
		"capture_radius": 80.0,
	}
	var missing_marker = MISSION_SCENARIO_DATA_SCRIPT.new(missing_marker_data)
	_assert(_validation_has_error(missing_marker, "objective marker does not exist"), "Validation reports objective markers absent from TerrainMapData")

	var duplicate_enemy_data: Dictionary = _valid_scenario_dict("duplicate_enemy")
	duplicate_enemy_data["enemy_groups"] = [
		{
			"group_id": "red_a",
			"team_id": "team_bravo",
			"spawn_marker_id": "spawn_bravo",
			"enemy_ids": ["enemy_delta"],
		},
		{
			"group_id": "red_b",
			"team_id": "team_bravo",
			"spawn_marker_id": "spawn_bravo",
			"enemy_ids": ["enemy_delta"],
		},
	]
	var duplicate_enemy = MISSION_SCENARIO_DATA_SCRIPT.new(duplicate_enemy_data)
	_assert(_validation_has_error(duplicate_enemy, "enemy id is used more than once"), "Validation reports duplicate enemy ids")


func _test_patrol_binding_validation() -> void:
	var valid_spawn_binding_data: Dictionary = _valid_scenario_dict("spawn_binding")
	valid_spawn_binding_data["patrol_bindings"] = [
		{
			"target_id": "spawn_bravo",
			"patrol_path_id": "enemy_delta",
			"mode": "pre_contact",
		},
	]
	var valid_spawn_binding = MISSION_SCENARIO_DATA_SCRIPT.new(valid_spawn_binding_data)
	_assert(bool(Dictionary(valid_spawn_binding.call("validate")).get("valid", false)), "Patrol bindings may target map spawn ids")

	var invalid_binding_data: Dictionary = _valid_scenario_dict("invalid_patrol_binding")
	invalid_binding_data["patrol_bindings"] = [
		{
			"target_id": "unknown_enemy_or_spawn",
			"patrol_path_id": "enemy_delta",
			"mode": "pre_contact",
		},
	]
	var invalid_binding = MISSION_SCENARIO_DATA_SCRIPT.new(invalid_binding_data)
	_assert(_validation_has_error(invalid_binding, "target_id is not an enemy id or map spawn/patrol id"), "Validation reports patrol bindings that target no known enemy or spawn id")


func _test_lz_fields_are_rejected_and_not_serialized() -> void:
	var lz_data: Dictionary = _valid_scenario_dict("reject_lz")
	lz_data["lz_position"] = {"x": 1.0, "y": 2.0}
	lz_data["dropship"] = {
		"landing_zone": {"x": 3.0, "y": 4.0},
	}
	var scenario = MISSION_SCENARIO_DATA_SCRIPT.new(lz_data)
	_assert(_validation_has_error(scenario, "LZ must not be stored in mission scenarios"), "Validation rejects LZ fields anywhere in scenario JSON")
	var serialized: Dictionary = Dictionary(scenario.call("to_dict"))
	_assert(not _has_key_recursive(serialized, "lz_position") and not _has_key_recursive(serialized, "landing_zone"), "MissionScenarioData does not serialize rejected LZ fields")


func _test_sample_scenario_files_reference_terrain_without_duplication() -> void:
	for scenario_id in SAMPLE_SCENARIO_IDS:
		var path: String = "%s/%s.json" % [SAMPLE_SCENARIO_DIR, String(scenario_id)]
		var scenario = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", path)
		var validation: Dictionary = Dictionary(scenario.call("validate"))
		_assert(bool(validation.get("valid", false)), "Sample scenario %s validates" % String(scenario_id))
		_assert(bool(scenario.call("references_terrain_without_duplication")), "Sample scenario %s references TerrainMapData without duplicating terrain fields" % String(scenario_id))
		var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", String(scenario.get("map_file_path")))
		var objective_position: Vector2 = scenario.call("get_objective_position", terrain_map_data, Vector2.ZERO)
		_assert(objective_position.distance_to(Vector2.ZERO) > 0.5, "Sample scenario %s resolves objective position from the referenced map" % String(scenario_id))


func _valid_scenario_dict(scenario_id: String) -> Dictionary:
	return {
		"version": 1,
		"scenario_id": scenario_id,
		"display_name": "TASK_156 Contract Test",
		"map_file_path": VALID_MAP_PATH,
		"time_limit_seconds": 600.0,
		"mission_slot_count_override": 8,
		"objective": {
			"marker_id": "objective_point",
			"capture_radius": 80.0,
		},
		"enemy_groups": [
			{
				"group_id": "red_test_group",
				"team_id": "team_bravo",
				"spawn_marker_id": "spawn_bravo",
				"enemy_ids": ["enemy_delta", "enemy_echo"],
			},
		],
		"wave_config": {
			"wave_count": 1,
			"units_per_wave": 2,
			"first_wave_delay_seconds": 0.0,
			"wave_delay_seconds": 90.0,
		},
		"patrol_bindings": [
			{
				"target_id": "enemy_delta",
				"patrol_path_id": "enemy_delta",
				"mode": "pre_contact",
			},
			{
				"target_id": "enemy_echo",
				"patrol_path_id": "enemy_echo",
				"mode": "pre_contact",
			},
		],
		"notes": ["TASK_156 verifier fixture"],
	}


func _validation_has_error(scenario, needle: String) -> bool:
	var validation: Dictionary = Dictionary(scenario.call("validate"))
	for error_variant in PackedStringArray(validation.get("errors", PackedStringArray())):
		if String(error_variant).contains(needle):
			return true
	return false


func _has_key_recursive(value: Variant, key: String) -> bool:
	if typeof(value) == TYPE_DICTIONARY:
		var value_dict: Dictionary = Dictionary(value)
		for key_variant in value_dict.keys():
			if String(key_variant) == key:
				return true
			if _has_key_recursive(value_dict.get(key_variant), key):
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
