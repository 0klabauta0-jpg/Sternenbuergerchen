extends SceneTree

const PROFILE_SCRIPT: GDScript = preload("res://scripts/tactical/enemy_team_tactics_profile.gd")
const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")

const CATALOG_PATH: String = "res://data/tactical_profile_catalog.json"
const HELP_CATALOG_PATH: String = "res://data/contextual_help_catalog.json"
const TASK_PATH: String = "res://docs/tasks/TASK_280_tactical_profile_editor_scenario_authoring.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_280 Tactical Profile Editor Scenario Authoring ===")
	_test_catalog_and_help()
	_test_old_scenario_safe_defaults()
	_test_scenario_roundtrip_and_validation()
	await _test_editor_authoring_roundtrip()
	await _test_runtime_glue_reads_validated_profile()
	_test_task_status()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_catalog_and_help() -> void:
	var catalog: Dictionary = _read_json(CATALOG_PATH)
	_assert(not catalog.is_empty(), "Tactical profile authoring catalog exists")
	for token in ["anti_armor", "rocket_launcher", "rail_gun", "loss_capable", "normal"]:
		_assert(JSON.stringify(catalog).contains(token), "Catalog documents %s" % token)
	_assert(PROFILE_SCRIPT.call("get_heavy_weapon_roles").has("anti_armor"), "Profile script exposes heavy weapon roles")
	_assert(PROFILE_SCRIPT.call("get_air_asset_risk_profiles").has("loss_capable"), "Profile script exposes air asset risk profiles")
	_assert(PROFILE_SCRIPT.call("get_communication_intensities").has("high"), "Profile script exposes communication intensity options")
	var help_catalog: Dictionary = _read_json(HELP_CATALOG_PATH)
	_assert(JSON.stringify(help_catalog).contains("map_editor.tactical_profile"), "Contextual help catalog covers tactical profile authoring")


func _test_old_scenario_safe_defaults() -> void:
	var map_path: String = _build_support_map("task_280_old_defaults_map")
	var old_scenario = MISSION_SCENARIO_DATA_SCRIPT.new({
		"version": 1,
		"scenario_id": "task_280_old_defaults",
		"display_name": "TASK 280 Old Defaults",
		"map_file_path": map_path,
		"time_limit_seconds": 300.0,
		"objective": {"marker_id": "objective_point", "capture_radius": 80.0},
		"enemy_groups": [
			{
				"group_id": "red_old",
				"team_id": "team_bravo",
				"spawn_marker_id": "spawn_bravo",
				"enemy_ids": ["enemy_delta"],
			},
		],
		"wave_config": {"wave_count": 1, "units_per_wave": 1, "first_wave_delay_seconds": 0.0, "wave_delay_seconds": 30.0},
	})
	var validation: Dictionary = Dictionary(old_scenario.call("validate"))
	_assert(bool(validation.get("valid", false)), "Old scenario without new tactical fields still validates")
	var tactical: Dictionary = Dictionary(old_scenario.call("get_tactical_authoring_config"))
	var risk: Dictionary = Dictionary(old_scenario.call("get_air_asset_risk_config"))
	_assert(String(tactical.get("communication_intensity", "")) == "normal", "Old scenario receives normal communication default")
	_assert(String(risk.get("profile_id", "")) == "none", "Old scenario receives safe air asset risk default")
	_assert(Array(old_scenario.call("get_enemy_air_asset_threats")).is_empty(), "Old scenario creates no accidental Air Asset threat")


func _test_scenario_roundtrip_and_validation() -> void:
	var map_path: String = _build_support_map("task_280_roundtrip_map")
	var scenario = MISSION_SCENARIO_DATA_SCRIPT.new(_valid_authoring_scenario("task_280_roundtrip", map_path))
	var validation: Dictionary = Dictionary(scenario.call("validate"))
	_assert(bool(validation.get("valid", false)), "Scenario with tactical profile and Air Asset risk validates")
	var save_path: String = "user://task_280_tactical_profile_roundtrip.json"
	_assert(scenario.call("save_to_file", save_path) == OK, "Scenario saves tactical profile authoring")
	var loaded = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", save_path)
	var loaded_group: Dictionary = Dictionary(Array(loaded.get("enemy_groups"))[0])
	var loaded_tactics: Dictionary = Dictionary(loaded_group.get("tactics", {}))
	var loaded_risk: Dictionary = Dictionary(loaded.call("get_air_asset_risk_config"))
	_assert(String(loaded_tactics.get("profile_id", "")) == "defensive_cover", "Roundtrip preserves enemy tactic profile")
	_assert(String(loaded_tactics.get("heavy_weapon_role", "")) == "anti_armor", "Roundtrip preserves heavy/AT role")
	_assert(String(loaded_tactics.get("weapon_id", "")) == "rocket_launcher", "Roundtrip preserves AT weapon")
	_assert(String(loaded_tactics.get("air_asset_risk_profile", "")) == "loss_capable", "Roundtrip preserves group air risk")
	_assert(String(loaded_tactics.get("communication_intensity", "")) == "high", "Roundtrip preserves communication intensity")
	_assert(String(loaded_risk.get("profile_id", "")) == "loss_capable" and String(loaded_risk.get("lz_threat_zone_id", "")) == "lz_threat", "Roundtrip preserves scenario Air Asset risk profile")
	var threats: Array = Array(loaded.call("get_enemy_air_asset_threats"))
	_assert(threats.size() == 1 and not bool(Dictionary(threats[0]).get("ui_sets_gameplay_truth", true)), "Scenario exposes Air Asset threat context without UI truth")

	var invalid = MISSION_SCENARIO_DATA_SCRIPT.new(_invalid_authoring_scenario("task_280_invalid", map_path))
	var invalid_validation: Dictionary = Dictionary(invalid.call("validate"))
	_assert(not bool(invalid_validation.get("valid", true)), "Invalid anti-armor authoring is reported by validation")
	_assert(_errors_contain(PackedStringArray(invalid_validation.get("errors", PackedStringArray())), "weapon_not_anti_armor"), "Validation names non-AT weapon on anti-armor threat")
	_assert(_diagnostics_contain(invalid.call("get_tactical_authoring_diagnostics"), "unknown_profile_id:not_a_profile"), "Diagnostics name unknown profile fallback")


func _test_editor_authoring_roundtrip() -> void:
	var editor := MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(4)
	editor.call("set_tactical_profile_authoring_fields", {
		"profile_id": "sniper_watch",
		"security_mode": "overwatch",
		"facing": "north_west",
		"heavy_weapon_role": "anti_armor",
		"weapon_id": "rail_gun",
		"air_asset_risk_profile": "watch_warning",
		"lz_threat_zone_id": "objective_point",
		"communication_intensity": "high",
	})
	var snapshot: Dictionary = Dictionary(editor.call("get_tactical_profile_authoring_snapshot"))
	_assert(String(snapshot.get("profile_id", "")) == "sniper_watch", "Editor snapshot preserves profile")
	_assert(String(snapshot.get("heavy_weapon_role", "")) == "anti_armor", "Editor snapshot preserves heavy role")
	_assert(String(snapshot.get("weapon_id", "")) == "rail_gun", "Editor snapshot preserves AT weapon")
	_assert(String(snapshot.get("air_asset_risk_profile", "")) == "watch_warning", "Editor snapshot preserves air risk")
	_assert(String(snapshot.get("communication_intensity", "")) == "high", "Editor snapshot preserves communication intensity")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Editor tactical snapshot is not gameplay truth")
	_assert(_editor_help_id_is_present(editor), "Editor tactical profile controls expose help IDs")
	var scenario_dict: Dictionary = Dictionary(editor.call("get_current_mission_scenario_dict"))
	var group: Dictionary = Dictionary(Array(scenario_dict.get("enemy_groups", []))[0])
	var tactics: Dictionary = Dictionary(group.get("tactics", {}))
	_assert(String(tactics.get("weapon_id", "")) == "rail_gun" and bool(tactics.get("anti_armor_threat", false)), "Editor scenario dict stores AT threat fields")
	var save_path: String = "user://task_280_editor_tactical_profile.json"
	_assert(editor.call("save_mission_scenario_from_editor", save_path) == OK, "Editor saves tactical profile scenario")
	var loaded = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", save_path)
	var loaded_tactics: Dictionary = Dictionary(Dictionary(Array(loaded.get("enemy_groups"))[0]).get("tactics", {}))
	_assert(String(loaded_tactics.get("profile_id", "")) == "sniper_watch" and String(loaded_tactics.get("weapon_id", "")) == "rail_gun", "Editor save/load preserves tactical profile fields")
	editor.queue_free()
	await _wait_frames(2)


func _test_runtime_glue_reads_validated_profile() -> void:
	var map_path: String = _build_support_map("task_280_runtime_map")
	var scenario_path: String = "user://task_280_runtime_scenario.json"
	var scenario = MISSION_SCENARIO_DATA_SCRIPT.new(_valid_authoring_scenario("task_280_runtime", map_path))
	_assert(scenario.call("save_to_file", scenario_path) == OK, "Runtime scenario fixture saves")
	var scene := MISSION_TEST_SCENE.instantiate()
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("scenario_file_path", scenario_path)
	root.add_child(scene)
	await _wait_frames(18)
	var setup: Node = scene.get_node("MissionSetup")
	var enemy_waves: Node = scene.get_node("EnemyWaveController")
	var tactical_snapshot: Dictionary = Dictionary(setup.call("get_scenario_tactical_authoring_snapshot"))
	var threat_context: Dictionary = Dictionary(setup.call("get_scenario_air_asset_risk_context_for_unit", "enemy_at_task"))
	var unit_config: Dictionary = Dictionary(enemy_waves.call("get_tactic_config_for_unit", "enemy_at_task"))
	_assert(String(tactical_snapshot.get("communication_intensity", "")) == "high", "MissionTestSetup reads scenario tactical authoring")
	_assert(String(threat_context.get("weapon_id", "")) == "rocket_launcher" and not bool(threat_context.get("ui_sets_gameplay_truth", true)), "MissionTestSetup exposes validated Air Asset risk context")
	_assert(String(unit_config.get("profile_id", "")) == "defensive_cover", "Runtime enemy config reads authored profile")
	_assert(String(unit_config.get("heavy_weapon_role", "")) == "anti_armor" and bool(unit_config.get("anti_armor_threat", false)), "Runtime enemy config reads AT role")
	var enemy_node := scene.get_node_or_null("EnemyDelta")
	_assert(enemy_node != null and enemy_node.has_meta("enemy_tactics_config"), "Enemy unit receives tactic metadata")
	if enemy_node != null:
		var meta_config: Dictionary = Dictionary(enemy_node.get_meta("enemy_tactics_config", {}))
		_assert(String(meta_config.get("weapon_id", "")) == "rocket_launcher", "Enemy unit metadata includes AT weapon")
	scene.queue_free()
	await _wait_frames(2)


func _test_task_status() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "Task file marks TASK_280 implemented")
	_assert(not task_text.contains("- [ ]"), "Task checklist is complete")
	_assert(status_text.contains("### TASK_280 - Tactical Profile Editor Scenario Authoring"), "Implementation status has TASK_280 section")
	_assert(roadmap_text.contains("TASK_280 - Tactical Profile Editor Scenario Authoring (implementiert)"), "Roadmap marks TASK_280 implemented")


func _valid_authoring_scenario(scenario_id: String, map_path: String) -> Dictionary:
	return {
		"version": 1,
		"scenario_id": scenario_id,
		"display_name": "TASK 280 Tactical Profile",
		"map_file_path": map_path,
		"time_limit_seconds": 420.0,
		"objective": {"marker_id": "objective_point", "capture_radius": 80.0},
		"enemy_groups": [
			{
				"group_id": "red_at",
				"team_id": "team_bravo",
				"spawn_marker_id": "spawn_bravo",
				"enemy_ids": ["enemy_at_task"],
				"tactics": {
					"profile_id": "defensive_cover",
					"security_mode": "cover_arc",
					"facing": "west",
					"heavy_weapon_role": "anti_armor",
					"weapon_id": "rocket_launcher",
					"anti_armor_threat": true,
					"air_asset_risk_profile": "loss_capable",
					"lz_threat_zone_id": "lz_threat",
					"communication_intensity": "high",
				},
			}
		],
		"wave_config": {"wave_count": 1, "units_per_wave": 1, "first_wave_delay_seconds": 0.0, "wave_delay_seconds": 30.0},
		"tactical_authoring": {
			"communication_intensity": "high",
			"fireteam_defaults": {"advance_style": "bounding", "security_mode": "360"},
			"air_asset_risk": {
				"profile_id": "loss_capable",
				"enemy_group_id": "red_at",
				"lz_threat_zone_id": "lz_threat",
				"warning_required_before_damage": true,
				"loss_consequence": "replacement_recovery",
			},
		},
	}


func _invalid_authoring_scenario(scenario_id: String, map_path: String) -> Dictionary:
	var data: Dictionary = _valid_authoring_scenario(scenario_id, map_path)
	var group: Dictionary = Dictionary(Array(data.get("enemy_groups", []))[0])
	var tactics: Dictionary = Dictionary(group.get("tactics", {}))
	tactics["profile_id"] = "not_a_profile"
	tactics["weapon_id"] = "rifle"
	group["tactics"] = tactics
	data["enemy_groups"] = [group]
	return data


func _build_support_map(map_name: String) -> String:
	var map_path: String = "user://%s.json" % map_name
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", map_name, Vector2i(32, 32), Vector2.ZERO)
	map_data.call("set_marker_position", "spawn_bravo", Vector2(256.0, 256.0))
	map_data.call("set_marker_position", "objective_point", Vector2(512.0, 512.0))
	map_data.call("set_marker_position", "lz_threat", Vector2(640.0, 512.0))
	map_data.call("save_to_file", map_path)
	return map_path


func _editor_help_id_is_present(editor: Node) -> bool:
	var option := editor.find_child("ScenarioAirAssetRiskOption", true, false)
	return option != null and String(option.get_meta("help_id", "")) == "map_editor.tactical_profile"


func _errors_contain(errors: PackedStringArray, needle: String) -> bool:
	for error in errors:
		if String(error).contains(needle):
			return true
	return false


func _diagnostics_contain(diagnostics: PackedStringArray, needle: String) -> bool:
	for diagnostic in diagnostics:
		if String(diagnostic).contains(needle):
			return true
	return false


func _read_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	if text.is_empty():
		return {}
	var parsed = JSON.parse_string(text)
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _wait_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
