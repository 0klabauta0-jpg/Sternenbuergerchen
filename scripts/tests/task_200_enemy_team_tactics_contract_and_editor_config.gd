extends SceneTree

const PROFILE_SCRIPT: GDScript = preload("res://scripts/tactical/enemy_team_tactics_profile.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")
const ENEMY_WAVE_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/mission/enemy_wave_controller.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")
const CONTRACT_DOC_PATH: String = "res://docs/dev/enemy_team_tactics_contract.md"

const REQUIRED_PROFILES: PackedStringArray = [
	"guard_hold",
	"patrol_probe",
	"aggressive_push",
	"defensive_cover",
	"sniper_watch",
]
const REQUIRED_CONFIG_FIELDS: PackedStringArray = [
	"profile_id",
	"security_mode",
	"facing",
	"stance",
	"cover_behavior",
	"advance_style",
	"allowed_weapon_roles",
	"sight_behavior",
	"contact_behavior",
	"weapon_profile",
	"visual_archetype",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_200 Enemy Team Tactics Contract and Editor Config ===")
	_test_contract_doc_exists()
	_test_profile_catalog_is_stable()
	_test_defaults_and_diagnostics()
	_test_map_save_load_roundtrip()
	_test_mission_save_load_roundtrip()
	await _test_editor_authoring_roundtrip()
	_test_enemy_wave_controller_runtime_glue()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_contract_doc_exists() -> void:
	_assert(FileAccess.file_exists(CONTRACT_DOC_PATH), "Enemy team tactics dev contract exists")
	var text: String = _read_text_file(CONTRACT_DOC_PATH)
	for profile_id in REQUIRED_PROFILES:
		_assert(text.contains(profile_id), "Dev contract documents profile '%s'" % profile_id)


func _test_profile_catalog_is_stable() -> void:
	var profile_ids: PackedStringArray = PROFILE_SCRIPT.call("get_profile_ids")
	for profile_id in REQUIRED_PROFILES:
		_assert(profile_ids.has(profile_id), "Profile catalog exposes '%s'" % profile_id)
		var profile: Dictionary = PROFILE_SCRIPT.call("get_profile", profile_id)
		_assert(String(profile.get("profile_id", "")) == profile_id, "Profile '%s' resolves by stable ID" % profile_id)
		var validation: Dictionary = PROFILE_SCRIPT.call("validate_config", {"profile_id": profile_id})
		_assert(bool(validation.get("valid", false)), "Profile '%s' normalizes into a valid tactics config" % profile_id)
		var config: Dictionary = Dictionary(validation.get("config", {}))
		for field_name in REQUIRED_CONFIG_FIELDS:
			_assert(config.has(field_name), "Profile '%s' normalized config contains '%s'" % [profile_id, field_name])
		_assert(not Array(config.get("allowed_weapon_roles", [])).is_empty(), "Profile '%s' has allowed weapon roles" % profile_id)


func _test_defaults_and_diagnostics() -> void:
	var small_default: Dictionary = PROFILE_SCRIPT.call("get_default_config_for_map_size", Vector2i(32, 32))
	var large_default: Dictionary = PROFILE_SCRIPT.call("get_default_config_for_map_size", Vector2i(64, 64))
	_assert(String(small_default.get("profile_id", "")) == "guard_hold", "32x32 maps default to guard_hold")
	_assert(String(large_default.get("profile_id", "")) == "patrol_probe", "64x64 maps default to patrol_probe")
	var unknown: Dictionary = PROFILE_SCRIPT.call(
		"normalize_config",
		{
			"profile_id": "not_a_profile",
			"security_mode": "bad_security",
			"facing": "bad_facing",
		},
		Vector2i(64, 64)
	)
	_assert(String(unknown.get("profile_id", "")) == "patrol_probe", "Unknown profile falls back to the 64x64 default")
	var diagnostics: PackedStringArray = PackedStringArray(unknown.get("diagnostics", PackedStringArray()))
	_assert(_diagnostics_contain(diagnostics, "unknown_profile_id:not_a_profile"), "Unknown profile is diagnosed")
	_assert(_diagnostics_contain(diagnostics, "unknown_security_mode:bad_security"), "Unknown security mode is diagnosed")
	_assert(_diagnostics_contain(diagnostics, "unknown_facing:bad_facing"), "Unknown facing is diagnosed")


func _test_map_save_load_roundtrip() -> void:
	var map_path: String = "user://task_200_enemy_tactics_map.json"
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_200_map", Vector2i(64, 64), Vector2.ZERO)
	map_data.call(
		"set_enemy_team_config",
		"red_test_group",
		{
			"profile_id": "defensive_cover",
			"security_mode": "cover_arc",
			"facing": "east",
		}
	)
	var save_error: Error = map_data.call("save_to_file", map_path)
	_assert(save_error == OK, "Terrain map with enemy_team_configs saves")
	var loaded_map = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", map_path)
	var configs: Dictionary = Dictionary(loaded_map.call("get_enemy_team_configs"))
	_assert(configs.has("default"), "Loaded map retains a default enemy team config")
	_assert(configs.has("red_test_group"), "Loaded map retains authored enemy team config")
	var loaded_config: Dictionary = loaded_map.call("get_enemy_team_config", "red_test_group")
	_assert(String(loaded_config.get("profile_id", "")) == "defensive_cover", "Loaded map preserves profile")
	_assert(String(loaded_config.get("security_mode", "")) == "cover_arc", "Loaded map preserves security mode")
	_assert(String(loaded_config.get("facing", "")) == "east", "Loaded map preserves facing")


func _test_mission_save_load_roundtrip() -> void:
	var map_path: String = "user://task_200_mission_map.json"
	var scenario_path: String = "user://task_200_mission_scenario.json"
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_200_scenario_map", Vector2i(32, 32), Vector2.ZERO)
	map_data.call("set_marker_position", "spawn_bravo", Vector2(128.0, 128.0))
	map_data.call("set_marker_position", "objective_point", Vector2(256.0, 256.0))
	var map_save_error: Error = map_data.call("save_to_file", map_path)
	_assert(map_save_error == OK, "Scenario support map saves")

	var scenario = MISSION_SCENARIO_DATA_SCRIPT.new(
		{
			"version": 1,
			"scenario_id": "task_200_scenario",
			"display_name": "TASK 200 Scenario",
			"map_file_path": map_path,
			"time_limit_seconds": 120.0,
			"objective": {"marker_id": "objective_point", "capture_radius": 64.0},
			"enemy_groups": [
				{
					"group_id": "red_test_group",
					"team_id": "team_bravo",
					"enemy_ids": ["enemy_task_200"],
					"spawn_marker_id": "spawn_bravo",
					"tactics": {
						"profile_id": "aggressive_push",
						"security_mode": "directional",
						"facing": "south_east",
					},
				}
			],
			"wave_config": {"wave_count": 1, "units_per_wave": 1, "first_wave_delay_seconds": 0.0, "wave_delay_seconds": 30.0},
		}
	)
	var validation: Dictionary = Dictionary(scenario.call("validate"))
	_assert(bool(validation.get("valid", false)), "Mission scenario with tactics validates")
	var save_error: Error = scenario.call("save_to_file", scenario_path)
	_assert(save_error == OK, "Mission scenario with tactics saves")
	var loaded_scenario = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", scenario_path)
	var loaded_group: Dictionary = Dictionary(Array(loaded_scenario.get("enemy_groups"))[0])
	var loaded_tactics: Dictionary = Dictionary(loaded_group.get("tactics", {}))
	_assert(String(loaded_tactics.get("profile_id", "")) == "aggressive_push", "Mission load preserves tactic profile")
	_assert(String(loaded_tactics.get("security_mode", "")) == "directional", "Mission load preserves security mode")
	_assert(String(loaded_tactics.get("facing", "")) == "south_east", "Mission load preserves facing")
	var unit_tactics: Dictionary = loaded_scenario.call("get_enemy_tactics_for_unit", "enemy_task_200", map_data)
	_assert(String(unit_tactics.get("profile_id", "")) == "aggressive_push", "Mission exposes per-unit tactics")


func _test_editor_authoring_roundtrip() -> void:
	var editor := MAP_EDITOR_SCENE.instantiate()
	_assert(editor != null, "Map editor scene instantiates")
	if editor == null:
		return
	root.add_child(editor)
	await process_frame
	await process_frame
	editor.call(
		"set_enemy_tactics_authoring_fields",
		{
			"profile_id": "sniper_watch",
			"security_mode": "overwatch",
			"facing": "north_west",
		}
	)
	var snapshot: Dictionary = Dictionary(editor.call("get_enemy_tactics_authoring_snapshot"))
	_assert(String(snapshot.get("profile_id", "")) == "sniper_watch", "Editor authoring snapshot preserves profile")
	_assert(String(snapshot.get("security_mode", "")) == "overwatch", "Editor authoring snapshot preserves security mode")
	_assert(String(snapshot.get("facing", "")) == "north_west", "Editor authoring snapshot preserves facing")
	var scenario_dict: Dictionary = Dictionary(editor.call("get_current_mission_scenario_dict"))
	var group: Dictionary = Dictionary(Array(scenario_dict.get("enemy_groups", []))[0])
	var tactics: Dictionary = Dictionary(group.get("tactics", {}))
	_assert(String(tactics.get("profile_id", "")) == "sniper_watch", "Editor scenario dict stores profile")
	_assert(String(tactics.get("security_mode", "")) == "overwatch", "Editor scenario dict stores security mode")
	_assert(String(tactics.get("facing", "")) == "north_west", "Editor scenario dict stores facing")
	var save_path: String = "user://task_200_editor_scenario.json"
	var save_error: Error = editor.call("save_mission_scenario_from_editor", save_path)
	_assert(save_error == OK, "Editor saves scenario containing enemy tactics")
	var loaded_scenario = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", save_path)
	var loaded_group: Dictionary = Dictionary(Array(loaded_scenario.get("enemy_groups"))[0])
	var loaded_tactics: Dictionary = Dictionary(loaded_group.get("tactics", {}))
	_assert(String(loaded_tactics.get("profile_id", "")) == "sniper_watch", "Editor save/load preserves profile")
	_assert(String(loaded_tactics.get("security_mode", "")) == "overwatch", "Editor save/load preserves security mode")
	_assert(String(loaded_tactics.get("facing", "")) == "north_west", "Editor save/load preserves facing")
	editor.queue_free()
	await process_frame


func _test_enemy_wave_controller_runtime_glue() -> void:
	var controller = ENEMY_WAVE_CONTROLLER_SCRIPT.new()
	var unit = TEST_UNIT_SCRIPT.new()
	unit.set("unit_id", "enemy_task_200_runtime")
	controller.call(
		"set_enemy_tactics",
		{
			"enemy_task_200_runtime": {
				"profile_id": "defensive_cover",
				"security_mode": "cover_arc",
				"facing": "west",
			}
		}
	)
	controller.call("initialize_enemy_units", [unit])
	var controller_config: Dictionary = Dictionary(controller.call("get_tactic_config_for_unit", "enemy_task_200_runtime"))
	_assert(String(controller_config.get("profile_id", "")) == "defensive_cover", "Wave controller reads authored tactic profile")
	_assert(unit.has_meta("enemy_tactics_config"), "Wave controller applies tactic metadata to enemy unit")
	_assert(String(unit.get_meta("enemy_tactics_profile_id", "")) == "defensive_cover", "Enemy unit metadata exposes profile ID")
	_assert(String(unit.get_meta("enemy_security_mode", "")) == "cover_arc", "Enemy unit metadata exposes security mode")
	_assert(String(unit.get_meta("enemy_facing", "")) == "west", "Enemy unit metadata exposes facing")


func _diagnostics_contain(diagnostics: PackedStringArray, expected: String) -> bool:
	for diagnostic in diagnostics:
		if String(diagnostic).contains(expected):
			return true
	return false


func _read_text_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
