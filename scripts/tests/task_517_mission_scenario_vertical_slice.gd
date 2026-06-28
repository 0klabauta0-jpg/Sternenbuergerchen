extends SceneTree

const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const VERTICAL_SLICE_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_vertical_slice_contract.gd")
const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const META_FLOW_PATH: String = "res://scripts/meta/meta_layer_flow.gd"
const TASK_PATH: String = "res://docs/tasks/TASK_517_mission_scenario_vertical_slice.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_517 Mission Scenario Vertical Slice ===")
	_test_docs_and_catalog_entry()
	_test_scenario_contract()
	_test_vertical_slice_payload()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_517: FAILED")
		quit(1)
		return
	print("TASK_517: ALL PASSED")
	quit(0)


func _test_docs_and_catalog_entry() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_517 task file exists")
	_assert(_read_text(TASK_PATH).contains("## Status: IMPLEMENTIERT"), "TASK_517 task file marks implementation")
	_assert(_read_text(STATUS_PATH).contains("TASK_517 - Mission Scenario Vertical Slice"), "Implementation status tracks TASK_517")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_517 - Mission Scenario Vertical Slice"), "Roadmap lists TASK_517")
	var meta_source: String = _read_text(META_FLOW_PATH)
	_assert(meta_source.contains("FRONTIER_VERTICAL_SLICE_SCENARIO_PATH"), "Meta flow defines the vertical slice scenario path")
	_assert(meta_source.contains('"mission_id": "frontier_probe_vertical_slice"'), "Homebase catalog exposes the vertical slice mission")
	_assert(meta_source.contains('"scenario_file_path": FRONTIER_VERTICAL_SLICE_SCENARIO_PATH'), "Homebase catalog routes the slice through scenario data")
	_assert(_mission_entry_contains(meta_source, "frontier_probe", '"scenario_file_path": NO_SCENARIO_FILE_PATH'), "Original frontier_probe stays map-only for existing contracts")


func _test_scenario_contract() -> void:
	_assert(FileAccess.file_exists(SCENARIO_PATH), "Vertical slice scenario file exists")
	var scenario = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", SCENARIO_PATH)
	var validation: Dictionary = Dictionary(scenario.call("validate"))
	if not bool(validation.get("valid", false)):
		print("TASK_517 scenario validation errors: %s" % "; ".join(PackedStringArray(validation.get("errors", PackedStringArray()))))
	_assert(bool(validation.get("valid", false)), "Vertical slice scenario validates through MissionScenarioData")
	_assert(String(scenario.get("scenario_id")) == "frontier_probe_vertical_slice", "Scenario id is stable")
	_assert(String(scenario.get("map_file_path")) == MAP_PATH, "Scenario references the expanded frontier map")
	_assert(bool(scenario.call("references_terrain_without_duplication")), "Scenario references terrain instead of duplicating tiles")
	_assert(not _has_key_recursive(Dictionary(scenario.call("to_dict")), "landing_zone"), "Scenario serialization does not store a player landing zone")
	_assert(not _has_key_recursive(Dictionary(scenario.call("to_dict")), "lz_position"), "Scenario serialization does not store a player LZ position")

	var briefing: Dictionary = Dictionary(scenario.call("get_briefing"))
	_assert(String(briefing.get("minimap_mode", "")) == "terrain_only", "Briefing uses terrain-only minimap")
	_assert(ResourceLoader.exists(String(briefing.get("background_image_path", ""))), "Briefing background asset exists")
	_assert(Array(briefing.get("objectives", [])).size() >= 3, "Briefing names AA, computer and cargo objectives")
	var recommended: Array = Array(briefing.get("recommended_loadout", []))
	_assert(recommended.size() >= 2, "Briefing contains solo and fireteam loadout recommendations")
	var weapon_ids: PackedStringArray = _collect_recommended_weapon_ids(recommended)
	for weapon_id in ["sniper", "rocket_launcher", "rail_gun", "medictool"]:
		_assert(weapon_ids.has(weapon_id), "Briefing recommends %s where useful" % weapon_id)
		_assert(bool(WEAPON_DATA_SCRIPT.call("is_valid_weapon_id", weapon_id)), "%s is a valid gameplay weapon id" % weapon_id)

	var air_risk: Dictionary = Dictionary(scenario.call("get_air_asset_risk_config"))
	_assert(String(air_risk.get("profile_id", "")) == "watch_warning", "Scenario marks air-asset risk as a warning gate")
	_assert(String(air_risk.get("enemy_group_id", "")) == "bravo_air_defense", "Air-risk gate points at the AA enemy group")
	_assert(String(air_risk.get("lz_threat_zone_id", "")) == "factory_danger_zone", "Air-risk zone references an existing map marker")


func _test_vertical_slice_payload() -> void:
	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	_assert(terrain_map_data != null and not bool(terrain_map_data.call("has_load_issue")), "Expanded frontier map loads for slice validation")
	if terrain_map_data == null:
		return
	var slice: Dictionary = Dictionary(VERTICAL_SLICE_CONTRACT_SCRIPT.call("load_slice_from_file", SCENARIO_PATH))
	var validation: Dictionary = Dictionary(VERTICAL_SLICE_CONTRACT_SCRIPT.call("validate_slice", slice, terrain_map_data))
	if not bool(validation.get("valid", false)):
		print("TASK_517 slice validation errors: %s" % "; ".join(PackedStringArray(validation.get("errors", PackedStringArray()))))
	_assert(bool(validation.get("valid", false)), "Vertical slice payload validates against map markers")
	var play_modes: PackedStringArray = PackedStringArray(slice.get("play_modes", PackedStringArray()))
	_assert(play_modes.has("singleplayer") and play_modes.has("multiplayer_pvp"), "Slice is ready for solo and PvP/MP authoring")
	_assert(_team_slot_has_spawn(slice, "team_alpha", "spawn_alpha"), "Alpha team uses the alpha map spawn")
	_assert(_team_slot_has_spawn(slice, "team_bravo", "spawn_bravo"), "Bravo team uses the bravo map spawn")

	var aa_step: Dictionary = Dictionary(VERTICAL_SLICE_CONTRACT_SCRIPT.call("get_step_by_type", slice, "air_defense_shutdown"))
	var computer_step: Dictionary = Dictionary(VERTICAL_SLICE_CONTRACT_SCRIPT.call("get_step_by_type", slice, "computer_hold"))
	var cargo_step: Dictionary = Dictionary(VERTICAL_SLICE_CONTRACT_SCRIPT.call("get_step_by_type", slice, "cargo_touchdown_extract"))
	_assert(String(aa_step.get("target_marker_id", "")) == "factory_danger_zone", "AA step targets the danger-zone marker")
	_assert(float(computer_step.get("min_hold_seconds", 0.0)) >= 18.0, "Computer step requires a timed hold")
	_assert(String(cargo_step.get("requires_step_id", "")) == "disable_air_defense", "Cargo step depends on AA shutdown")


func _collect_recommended_weapon_ids(recommended: Array) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for entry_variant in recommended:
		var entry: Dictionary = Dictionary(entry_variant)
		for weapon_id_variant in Array(entry.get("weapon_ids", [])):
			var weapon_id: String = String(weapon_id_variant).strip_edges()
			if not weapon_id.is_empty() and not result.has(weapon_id):
				result.append(weapon_id)
	return result


func _team_slot_has_spawn(slice: Dictionary, team_id: String, spawn_marker_id: String) -> bool:
	for slot_variant in Array(slice.get("team_slots", [])):
		var slot: Dictionary = Dictionary(slot_variant)
		if String(slot.get("team_id", "")) == team_id and String(slot.get("spawn_marker_id", "")) == spawn_marker_id:
			return true
	return false


func _mission_entry_contains(source_text: String, mission_id: String, needle: String) -> bool:
	var mission_index: int = source_text.find('"mission_id": "%s"' % mission_id)
	if mission_index < 0:
		return false
	var next_mission_index: int = source_text.find('"mission_id":', mission_index + 1)
	var end_index: int = next_mission_index if next_mission_index >= 0 else source_text.length()
	return source_text.substr(mission_index, end_index - mission_index).contains(needle)


func _has_key_recursive(value: Variant, key_needle: String) -> bool:
	var normalized_needle: String = key_needle.strip_edges().to_lower()
	if typeof(value) == TYPE_DICTIONARY:
		var value_dict: Dictionary = Dictionary(value)
		for key_variant in value_dict.keys():
			var key_text: String = String(key_variant).strip_edges().to_lower()
			if key_text == normalized_needle:
				return true
			if _has_key_recursive(value_dict.get(key_variant), normalized_needle):
				return true
	elif typeof(value) == TYPE_ARRAY:
		for item_variant in Array(value):
			if _has_key_recursive(item_variant, normalized_needle):
				return true
	return false


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
