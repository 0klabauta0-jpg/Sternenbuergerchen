extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_287_editor_save_multiplayer_contract_regression_review.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reviews/editor_save_multiplayer_contract_regression_review.md"

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")
const MULTIPLAYER_COMMAND_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_command_contract.gd")
const MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_snapshot_contract.gd")
const MULTIPLAYER_ROSTER_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_roster_contract.gd")
const MULTIPLAYER_MAP_MANIFEST_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_map_manifest.gd")
const PLAYER_ROSTER_STORE_SCRIPT: GDScript = preload("res://scripts/meta/player_roster_store.gd")
const START_ROSTER_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/start_roster_generator.gd")
const AIR_ASSET_RECOVERY_STATE_SCRIPT: GDScript = preload("res://scripts/meta/air_asset_recovery_state.gd")
const GAME_SETTINGS_CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/game_settings_contract.gd")

const CACHE_ROOT: String = "user://task_287_downloaded_maps"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_287 Editor Save Multiplayer Contract Regression Review ===")
	_test_docs_report_and_status()
	_test_scenario_authoring_rejects_runtime_bleed()
	_test_save_load_boundaries()
	_test_multiplayer_command_and_snapshot_boundaries()
	_test_downloaded_map_manifest_and_payload_boundaries()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_docs_report_and_status() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "Task file marks TASK_287 implemented")
	_assert(not task_text.contains("- [ ]"), "Task checklist is complete")
	_assert(status_text.contains("### TASK_287 - Editor Save Multiplayer Contract Regression Review") and status_text.contains("- Status: implementiert"), "Implementation status marks TASK_287 implemented")
	_assert(roadmap_text.contains("TASK_287 - Editor Save Multiplayer Contract Regression Review (implementiert)"), "Roadmap marks TASK_287 implemented")
	for token in [
		"## Findings",
		"Blocker",
		"Important",
		"Settings",
		"Downloaded-Map",
		"MissionScenarioData",
		"Multiplayer",
		"Snapshot",
		"Roster",
		"AirAsset",
		"runtime_authority",
	]:
		_assert(report_text.to_lower().contains(String(token).to_lower()), "Review report contains %s" % token)


func _test_scenario_authoring_rejects_runtime_bleed() -> void:
	var map_path: String = _build_support_map("task_287_scenario_boundary_map")
	var valid_scenario = MISSION_SCENARIO_DATA_SCRIPT.new(_valid_scenario("task_287_valid_scenario", map_path))
	var valid_result: Dictionary = Dictionary(valid_scenario.call("validate"))
	_assert(bool(valid_result.get("valid", false)), "Valid tactical scenario validates")
	var threats: Array = Array(valid_scenario.call("get_enemy_air_asset_threats"))
	_assert(threats.size() == 1, "Scenario exposes one AirAsset threat context")
	if threats.size() == 1:
		var threat: Dictionary = Dictionary(threats[0])
		_assert(String(threat.get("runtime_authority", "")) == "SimulationRoot", "Scenario threat names SimulationRoot authority")
		_assert(not bool(threat.get("ui_sets_gameplay_truth", true)), "Scenario threat does not grant UI truth")

	var dirty_data: Dictionary = _valid_scenario("task_287_dirty_scenario", map_path)
	dirty_data["lz_position"] = {"x": 64, "y": 64}
	dirty_data["runtime_state"] = {"mission_drop_state": "requested"}
	dirty_data["air_asset_status"] = {"state": "crashed"}
	dirty_data["tiles"] = [{"x": 0, "y": 0}]
	dirty_data["markers"] = {"spawn_bravo": {"x": 1, "y": 1}}
	var dirty_group: Dictionary = Dictionary(Array(dirty_data.get("enemy_groups", []))[0])
	var dirty_tactics: Dictionary = Dictionary(dirty_group.get("tactics", {}))
	dirty_tactics["landing_zone"] = {"x": 128, "y": 128}
	dirty_group["tactics"] = dirty_tactics
	dirty_data["enemy_groups"] = [dirty_group]
	var dirty_scenario = MISSION_SCENARIO_DATA_SCRIPT.new(dirty_data)
	var dirty_validation: Dictionary = Dictionary(dirty_scenario.call("validate"))
	var dirty_errors: PackedStringArray = PackedStringArray(dirty_validation.get("errors", PackedStringArray()))
	var serialized: Dictionary = Dictionary(dirty_scenario.call("to_dict"))
	_assert(not bool(dirty_validation.get("valid", true)), "Scenario validation rejects forbidden LZ runtime keys")
	_assert(_errors_contain(dirty_errors, "lz_position") and _errors_contain(dirty_errors, "landing_zone"), "Scenario validation names top-level and nested LZ bleed")
	_assert(not serialized.has("runtime_state") and not serialized.has("air_asset_status"), "Scenario serialization drops runtime status fields")
	_assert(not serialized.has("tiles") and not serialized.has("markers"), "Scenario serialization does not duplicate terrain map data")
	_assert(bool(dirty_scenario.call("references_terrain_without_duplication")), "Scenario references terrain without storing tiles/markers/patrol paths")


func _test_save_load_boundaries() -> void:
	var profile_id: String = "task_287_player"
	var roster_path: String = "user://task_287_profiles/%s/roster_v1.json" % profile_id
	PLAYER_ROSTER_STORE_SCRIPT.call("delete_roster_for_tests", profile_id, roster_path)
	var roster: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", "task_287_roster_seed", 12, profile_id))
	var save_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("save_roster", roster, profile_id, roster_path))
	_assert(bool(save_result.get("ok", false)), "PlayerRosterStore saves a local player roster")
	var load_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("load_roster", profile_id, roster_path))
	_assert(bool(load_result.get("ok", false)), "PlayerRosterStore loads the local player roster")
	var payload: Dictionary = Dictionary(load_result.get("payload", {}))
	var boundary: Dictionary = Dictionary(payload.get("multiplayer_boundary", {}))
	_assert(String(boundary.get("scope", "")) == "local_player_profile", "Roster save declares local-player profile scope")
	_assert(bool(MULTIPLAYER_ROSTER_CONTRACT_SCRIPT.call("has_private_roster_fields", payload)), "Local roster save may contain private profile fields")
	var public_preview: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("build_public_roster_preview", Dictionary(load_result.get("roster", {})), 2, "player", "player_rosters"))
	_assert(bool(public_preview.get("valid", false)), "Public roster preview validates")
	_assert(not bool(MULTIPLAYER_ROSTER_CONTRACT_SCRIPT.call("has_private_roster_fields", public_preview)), "Public roster preview strips private profile fields")

	var settings_path: String = "user://task_287_settings.cfg"
	var save_settings_error: Error = GAME_SETTINGS_CONTRACT_SCRIPT.call("save_settings", {
		"resolution_preset": "1920x1080",
		"master_volume": 37.0,
		"roster": roster,
		"map_file_path": "user://task_287_should_not_persist.json",
		"air_asset_status": {"state": "crashed"},
	}, settings_path)
	_assert(save_settings_error == OK, "GameSettingsContract saves known settings")
	var settings_text: String = _read_text(settings_path)
	_assert(settings_text.contains("master_volume") and settings_text.contains("resolution_preset"), "Settings file contains expected settings keys")
	_assert(not settings_text.contains("roster") and not settings_text.contains("map_file_path") and not settings_text.contains("air_asset_status"), "Settings file excludes roster/map/runtime keys")

	var recovery: Dictionary = Dictionary(AIR_ASSET_RECOVERY_STATE_SCRIPT.call("from_air_asset_status", {
		"asset_id": "dropship_task_287",
		"asset_type": "dropship",
		"state": "crashed",
		"integrity": 0,
		"max_integrity": 100,
	}, {"craft_id": "dropship_task_287", "pilot_unit_id": "pilot_one"}, {"replacement_seconds": 45.0}))
	var transport_patch: Dictionary = Dictionary(AIR_ASSET_RECOVERY_STATE_SCRIPT.call("build_transport_patch", recovery))
	_assert(String(recovery.get("runtime_authority", "")) == "MetaLayerFlow", "AirAssetRecoveryState is owned by the meta layer")
	_assert(not bool(recovery.get("ui_sets_gameplay_truth", true)), "AirAssetRecoveryState does not grant UI truth")
	_assert(String(transport_patch.get("air_asset_meta_status", "")) == "destroyed_replacement_pending" and bool(transport_patch.get("air_asset_unavailable", false)), "Meta recovery patch gates transport availability")
	_assert(not transport_patch.has("map_file_path") and not transport_patch.has("scenario_id"), "Meta recovery patch does not write map/scenario authoring")


func _test_multiplayer_command_and_snapshot_boundaries() -> void:
	var command_contract = MULTIPLAYER_COMMAND_CONTRACT_SCRIPT.new()
	var commander_context: Dictionary = {"peer_role": "commander", "peer_team_id": "team_bravo"}
	var allowed_air: Dictionary = Dictionary(command_contract.call("validate", {
		"command_type": "air_asset_request_status",
		"team_id": "team_bravo",
	}, commander_context))
	var forbidden_state: Dictionary = Dictionary(command_contract.call("validate", {
		"command_type": "air_asset_request_status",
		"team_id": "team_bravo",
		"air_asset_status": {"state": "destroyed"},
	}, commander_context))
	var forbidden_lz: Dictionary = Dictionary(command_contract.call("validate", {
		"command_type": "air_asset_guard_lz",
		"team_id": "team_bravo",
		"fireteam_id": "red",
		"lz_position": Vector2(128.0, 96.0),
		"source_context": "editor",
	}, commander_context))
	var role_client: Dictionary = Dictionary(command_contract.call("validate", {
		"command_type": "role_override",
		"target_peer_id": 2,
		"role_id": "fireteam",
	}, commander_context))
	var role_host: Dictionary = Dictionary(command_contract.call("validate", {
		"command_type": "role_override",
		"target_peer_id": 2,
		"role_id": "fireteam",
	}, {"peer_role": "host"}))
	_assert(bool(allowed_air.get("accepted", false)), "AirAsset status request is whitelisted as command intent")
	_assert(String(forbidden_state.get("reason", "")).begins_with("state_mutation_key:air_asset_status"), "Client cannot submit AirAssetStatus as command state")
	_assert(String(forbidden_lz.get("reason", "")) == "lz_from_forbidden_source", "Editor/scenario LZ source is rejected for runtime air command")
	_assert(String(role_client.get("reason", "")) == "host_required", "Role override is host-only")
	_assert(bool(role_host.get("accepted", false)), "Host can validate role override command")

	var snapshot_contract = MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT.new()
	var snapshot: Dictionary = Dictionary(snapshot_contract.call("build_state_snapshot", {
		"tick": 87,
		"units": [
			{
				"unit_id": "task_287_unit",
				"position": Vector2(10.0, 12.0),
				"owner_peer_id": 2,
				"roster_source": "player",
				"roster_mode": "player_rosters",
				"fireteam_id": "red",
				"health": 75,
				"skill_values": {"leadership": 0.99},
				"progression": {"xp": 123},
				"relationship_links": [{"unit_id": "other"}],
				"portrait_path": "res://private/operator.png",
			},
		],
		"character_gameplay": [
			{
				"fireteam_id": "red",
				"cohesion_label": "steady",
				"cohesion_percent": 72,
				"morale_state": "ok",
				"frustration_state": "low",
				"communication_label": "clear",
				"member_count": 4,
				"skill_values": {"discipline": 0.88},
				"progression": {"xp": 77},
			},
		],
		"feedback_bubbles": [
			{"bubble_id": "bubble_task_287", "unit_id": "task_287_unit", "text_key": "copy", "text": "raw localized text", "texture_path": "res://private/icon.png"},
		],
		"communication_events": [
			{"event_id": "comm_task_287", "event_type": "order_received", "fireteam_id": "red", "text_key": "copy", "raw_payload": {"huge": true}},
		],
		"air_asset_status": [
			{"asset_id": "dropship_task_287", "asset_type": "dropship", "state": "locked", "integrity": 40, "vfx_events": [{"event_id": "vfx_1", "resource_path": "res://private/vfx.tres"}]},
		],
	}))
	var unit_snapshot: Dictionary = Dictionary(Array(snapshot.get("units", []))[0])
	var character_entry: Dictionary = Dictionary(Array(snapshot.get("character_gameplay", []))[0])
	var bubble_entry: Dictionary = Dictionary(Array(snapshot.get("feedback_bubbles", []))[0])
	var communication_entry: Dictionary = Dictionary(Array(snapshot.get("communication_events", []))[0])
	var air_status: Dictionary = Dictionary(Array(snapshot.get("air_asset_status", []))[0])
	var metrics: Dictionary = Dictionary(snapshot_contract.call("build_serialization_metrics", snapshot))
	_assert(int(unit_snapshot.get("owner_peer_id", 0)) == 2 and String(unit_snapshot.get("roster_source", "")) == "player", "Snapshot unit keeps ownership fields")
	_assert(not unit_snapshot.has("skill_values") and not unit_snapshot.has("progression") and not unit_snapshot.has("portrait_path"), "Snapshot unit strips private roster/profile fields")
	_assert(not character_entry.has("skill_values") and not character_entry.has("progression"), "Character gameplay snapshot strips private skill/progression fields")
	_assert(bubble_entry.has("text_key") and not bubble_entry.has("text") and not bubble_entry.has("texture_path"), "Feedback bubble snapshot keeps keys, not raw text/assets")
	_assert(communication_entry.has("text_key") and not communication_entry.has("raw_payload"), "Communication event snapshot strips raw payload")
	_assert(String(air_status.get("runtime_authority", "")) == "SimulationRoot" and not bool(air_status.get("ui_sets_gameplay_truth", true)), "AirAsset snapshot remains SimulationRoot-authoritative")
	_assert(Array(metrics.get("large_payload_offenders", [])).is_empty(), "Snapshot metrics find no raw asset/path/text payload offenders")
	_assert(not bool(MULTIPLAYER_ROSTER_CONTRACT_SCRIPT.call("has_private_roster_fields", snapshot)), "Full snapshot contains no private roster fields")


func _test_downloaded_map_manifest_and_payload_boundaries() -> void:
	var valid_text: String = _build_download_map_text("task_287_download_map", true)
	var manifest: Dictionary = _build_manifest_for_text("task_287_download_map", "TASK 287 Download Map", valid_text)
	var manifest_check: Dictionary = Dictionary(MULTIPLAYER_MAP_MANIFEST_SCRIPT.call("verify_manifest", manifest))
	_assert(bool(manifest_check.get("valid", false)), "Downloaded map manifest verifies safe map metadata")
	var accept_result: Dictionary = Dictionary(MULTIPLAYER_MAP_MANIFEST_SCRIPT.call("accept_download", manifest, valid_text, CACHE_ROOT))
	_assert(bool(accept_result.get("accepted", false)) and String(accept_result.get("cache_path", "")).begins_with(CACHE_ROOT), "Downloaded map with valid tactics is accepted into user cache")

	var unsafe_scenario_manifest: Dictionary = manifest.duplicate(true)
	unsafe_scenario_manifest["scenario_file_path"] = "C:\\temp\\scenario.json"
	var unsafe_scenario_check: Dictionary = Dictionary(MULTIPLAYER_MAP_MANIFEST_SCRIPT.call("verify_manifest", unsafe_scenario_manifest))
	_assert(not bool(unsafe_scenario_check.get("valid", true)) and _errors_contain(PackedStringArray(unsafe_scenario_check.get("errors", PackedStringArray())), "scenario_path_unsafe"), "Unsafe scenario path is rejected")

	var nested_script_text: String = _build_download_map_text("task_287_nested_script", false)
	var nested_data: Dictionary = _json_to_dict(nested_script_text)
	nested_data["markers"] = {"unsafe_marker": {"x": 4, "y": 4, "script": "res://evil.gd"}}
	var nested_validation: Dictionary = Dictionary(MULTIPLAYER_MAP_MANIFEST_SCRIPT.call("validate_map_json_text", JSON.stringify(nested_data)))
	_assert(not bool(nested_validation.get("valid", true)) and _errors_contain(PackedStringArray(nested_validation.get("errors", PackedStringArray())), "forbidden_key_script"), "Downloaded map payload rejects nested script keys")

	var bad_tactics_text: String = _build_download_map_text("task_287_bad_tactics", true)
	var bad_tactics_data: Dictionary = _json_to_dict(bad_tactics_text)
	var configs: Dictionary = Dictionary(bad_tactics_data.get("enemy_team_configs", {}))
	configs["bad_at"] = {
		"profile_id": "defensive_cover",
		"heavy_weapon_role": "anti_armor",
		"weapon_id": "rifle",
		"anti_armor_threat": true,
	}
	bad_tactics_data["enemy_team_configs"] = configs
	var bad_tactics_validation: Dictionary = Dictionary(MULTIPLAYER_MAP_MANIFEST_SCRIPT.call("validate_map_json_text", JSON.stringify(bad_tactics_data)))
	_assert(not bool(bad_tactics_validation.get("valid", true)) and _errors_contain(PackedStringArray(bad_tactics_validation.get("errors", PackedStringArray())), "weapon_not_anti_armor"), "Downloaded map payload validates enemy team tactics")

	var bad_cache_result: Dictionary = Dictionary(MULTIPLAYER_MAP_MANIFEST_SCRIPT.call("accept_download", manifest, valid_text, "res://not_allowed_cache"))
	_assert(not bool(bad_cache_result.get("accepted", true)) and String(bad_cache_result.get("state", "")) == "unsafe_cache_root", "Downloaded map cache root must stay under user://")


func _valid_scenario(scenario_id: String, map_path: String) -> Dictionary:
	return {
		"version": 1,
		"scenario_id": scenario_id,
		"display_name": "TASK 287 Scenario",
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
					"heavy_weapon_role": "anti_armor",
					"weapon_id": "rocket_launcher",
					"anti_armor_threat": true,
					"air_asset_risk_profile": "loss_capable",
					"lz_threat_zone_id": "lz_threat",
					"communication_intensity": "high",
				},
			},
		],
		"wave_config": {"wave_count": 1, "units_per_wave": 1, "first_wave_delay_seconds": 0.0, "wave_delay_seconds": 30.0},
		"tactical_authoring": {
			"communication_intensity": "high",
			"air_asset_risk": {
				"profile_id": "loss_capable",
				"enemy_group_id": "red_at",
				"lz_threat_zone_id": "lz_threat",
				"warning_required_before_damage": true,
				"loss_consequence": "replacement_recovery",
			},
		},
	}


func _build_support_map(map_name: String) -> String:
	var map_path: String = "user://%s.json" % map_name
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", map_name, Vector2i(32, 32), Vector2.ZERO)
	map_data.call("set_marker_position", "spawn_bravo", Vector2(256.0, 256.0))
	map_data.call("set_marker_position", "objective_point", Vector2(512.0, 512.0))
	map_data.call("set_marker_position", "lz_threat", Vector2(640.0, 512.0))
	map_data.call("save_to_file", map_path)
	return map_path


func _build_download_map_text(map_name: String, include_valid_tactics: bool) -> String:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", map_name, Vector2i(5, 5), Vector2.ZERO, 64.0, 32.0, 3)
	var map_path: String = "user://%s.json" % map_name
	map_data.call("save_to_file", map_path)
	var data: Dictionary = _json_to_dict(_read_text(map_path))
	if include_valid_tactics:
		var configs: Dictionary = Dictionary(data.get("enemy_team_configs", {}))
		configs["task_287_at"] = {
			"profile_id": "defensive_cover",
			"heavy_weapon_role": "anti_armor",
			"weapon_id": "rocket_launcher",
			"anti_armor_threat": true,
			"air_asset_risk_profile": "loss_capable",
			"communication_intensity": "high",
		}
		data["enemy_team_configs"] = configs
	return JSON.stringify(data)


func _build_manifest_for_text(map_id: String, map_name: String, map_text: String) -> Dictionary:
	return {
		"schema_version": 1,
		"format_version": 1,
		"map_id": map_id,
		"map_name": map_name,
		"author": "task_287",
		"source": "host_editor_map",
		"map_hash": map_text.sha256_text(),
		"map_size_bytes": map_text.to_utf8_buffer().size(),
		"download_required_policy": "client_consent_before_cache_write",
	}


func _json_to_dict(text: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(text)
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _errors_contain(errors: PackedStringArray, needle: String) -> bool:
	for error in errors:
		if String(error).contains(needle):
			return true
	return false


func _read_text(path: String) -> String:
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
