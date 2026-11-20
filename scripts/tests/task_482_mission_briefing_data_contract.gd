extends SceneTree

const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")
const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")
const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")

const MAP_PATH: String = "res://maps/Ground_Mission01_32x32.json"
const BACKGROUND_IMAGE_PATH: String = "res://Assets/used/npc/weapon_pack/previews/sniper.png"
const ROUNDTRIP_PATH: String = "user://task_482_mission_briefing_roundtrip.json"
const EDITOR_SAVE_PATH: String = "user://task_482_editor_briefing_roundtrip.json"
const TASK_PATH: String = "res://docs/tasks/TASK_482_mission_briefing_data_contract.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_briefing_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_482 Mission Briefing Data Contract ===")
	_test_briefing_roundtrip_and_validation()
	_test_invalid_briefing_reports_contract_errors()
	await _test_editor_authoring_api_preserves_briefing()
	_test_task_docs()
	_cleanup_user_file(ROUNDTRIP_PATH)
	_cleanup_user_file(EDITOR_SAVE_PATH)
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_482: FAILED")
		quit(1)
		return
	print("TASK_482: ALL PASSED")
	quit(0)


func _test_briefing_roundtrip_and_validation() -> void:
	var scenario = MISSION_SCENARIO_DATA_SCRIPT.new(_valid_scenario_data("task_482_roundtrip"))
	var validation: Dictionary = Dictionary(scenario.call("validate"))
	if not bool(validation.get("valid", false)):
		print("TASK_482 validation errors: %s" % "; ".join(PackedStringArray(validation.get("errors", PackedStringArray()))))
	_assert(bool(validation.get("valid", false)), "Scenario with mission briefing validates")
	var data: Dictionary = Dictionary(scenario.call("to_dict"))
	_assert(data.has("briefing"), "Scenario serializes briefing only as scenario data")
	_assert(not _has_key_recursive(Dictionary(data.get("briefing", {})), "tiles"), "Briefing does not duplicate terrain tiles")
	_assert(not _has_key_recursive(Dictionary(data.get("briefing", {})), "markers"), "Briefing does not duplicate map markers")
	_assert(not _has_key_recursive(Dictionary(data.get("briefing", {})), "patrol_paths"), "Briefing does not duplicate patrol paths")
	var briefing: Dictionary = Dictionary(data.get("briefing", {}))
	_assert(String(briefing.get("title", "")) == "Operation Speerspitze", "Briefing title roundtrips")
	_assert(String(briefing.get("background_image_path", "")) == BACKGROUND_IMAGE_PATH, "Briefing background image path roundtrips")
	_assert(ResourceLoader.exists(String(briefing.get("background_image_path", ""))), "Briefing background image asset exists")
	_assert(String(briefing.get("minimap_mode", "")) == "terrain_only", "Briefing minimap is terrain-only by contract")
	var recommended: Array = Array(briefing.get("recommended_loadout", []))
	_assert(recommended.size() == 2, "Briefing preserves recommended loadout entries")
	var first_recommendation: Dictionary = Dictionary(recommended[0])
	var weapon_ids: Array = Array(first_recommendation.get("weapon_ids", []))
	_assert(weapon_ids.has("sniper") and weapon_ids.has("rocket_launcher") and weapon_ids.has("medictool"), "Briefing loadout recommendation normalizes weapon aliases")
	var all_recommended_weapons: PackedStringArray = _collect_recommended_weapon_ids(recommended)
	_assert(not all_recommended_weapons.has("heavy_blaster"), "Briefing recommendations do not store visual loadout IDs as weapons")
	_assert(not all_recommended_weapons.has("rifle"), "Invalid briefing weapon IDs do not silently fall back to rifle")
	_assert(bool(scenario.call("references_terrain_without_duplication")), "Scenario still references terrain without copying it")
	_assert(scenario.call("save_to_file", ROUNDTRIP_PATH) == OK, "Scenario saves briefing to JSON")
	var loaded = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", ROUNDTRIP_PATH)
	var loaded_briefing: Dictionary = Dictionary(loaded.call("get_briefing"))
	_assert(String(loaded_briefing.get("title", "")) == "Operation Speerspitze", "Loaded scenario exposes briefing title")
	_assert(Array(Dictionary(Array(loaded_briefing.get("recommended_loadout", []))[0]).get("weapon_ids", [])).has("rocket_launcher"), "Loaded briefing preserves normalized rocket launcher recommendation")


func _test_invalid_briefing_reports_contract_errors() -> void:
	var invalid_data: Dictionary = _valid_scenario_data("task_482_invalid")
	invalid_data["briefing"] = {
		"title": "Bad Briefing",
		"background_image_path": "C:/tmp/not_project_local.png",
		"minimap_mode": "full_runtime_map",
	}
	var invalid = MISSION_SCENARIO_DATA_SCRIPT.new(invalid_data)
	var validation: Dictionary = Dictionary(invalid.call("validate"))
	var errors: PackedStringArray = PackedStringArray(validation.get("errors", PackedStringArray()))
	_assert(not bool(validation.get("valid", true)), "Invalid briefing fails validation")
	_assert(_errors_contain(errors, "briefing.background_image_path must use res://"), "Validation rejects non-project briefing images")
	_assert(_errors_contain(errors, "briefing.minimap_mode is not allowed"), "Validation rejects unsupported minimap mode")


func _test_editor_authoring_api_preserves_briefing() -> void:
	var editor := MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(5)
	editor.call("set_mission_briefing_authoring_fields", _briefing_payload())
	var snapshot: Dictionary = Dictionary(editor.call("get_mission_briefing_authoring_snapshot"))
	_assert(String(snapshot.get("title", "")) == "Operation Speerspitze", "Editor briefing snapshot reads scenario contract")
	_assert(Array(Dictionary(Array(snapshot.get("recommended_loadout", []))[0]).get("weapon_ids", [])).has("sniper"), "Editor snapshot keeps normalized briefing recommendations")
	var scenario_dict: Dictionary = Dictionary(editor.call("get_current_mission_scenario_dict"))
	_assert(Dictionary(scenario_dict.get("briefing", {})).has("background_image_path"), "Editor scenario dict contains briefing image path")
	_assert(editor.call("save_mission_scenario_from_editor", EDITOR_SAVE_PATH) == OK, "Editor saves mission briefing with scenario")
	var loaded = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", EDITOR_SAVE_PATH)
	var loaded_briefing: Dictionary = Dictionary(loaded.call("get_briefing"))
	_assert(String(loaded_briefing.get("minimap_mode", "")) == "terrain_only", "Editor save/load preserves briefing minimap mode")
	editor.queue_free()
	await _wait_frames(2)


func _test_task_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "Task file marks TASK_482 implemented")
	_assert(contract_text.contains("MissionBriefing"), "Mission briefing contract exists")
	_assert(status_text.contains("### TASK_482 - Mission Briefing Data Contract"), "Implementation status has TASK_482 section")
	_assert(roadmap_text.contains("TASK_482 - Mission Briefing Data Contract"), "Roadmap lists TASK_482")


func _valid_scenario_data(scenario_id: String) -> Dictionary:
	return {
		"version": 1,
		"scenario_id": scenario_id,
		"display_name": "TASK 482 Mission Briefing",
		"map_file_path": MAP_PATH,
		"time_limit_seconds": 600.0,
		"objective": {
			"marker_id": "objective_point",
			"capture_radius": 96.0,
		},
		"enemy_groups": [
			{
				"group_id": "red_briefing_test",
				"display_name": "Briefing Test Contacts",
				"team_id": "team_bravo",
				"spawn_marker_id": "spawn_bravo",
				"enemy_ids": ["enemy_delta"],
			},
		],
		"wave_config": {
			"wave_count": 1,
			"units_per_wave": 1,
			"first_wave_delay_seconds": 0.0,
			"wave_delay_seconds": 30.0,
		},
		"briefing": _briefing_payload(),
	}


func _briefing_payload() -> Dictionary:
	return {
		"title": "Operation Speerspitze",
		"summary": "Schalte die Luftabwehr aus, besetze den Aussenposten und sichere den Frachtanflug.",
		"background_image_path": BACKGROUND_IMAGE_PATH,
		"minimap_mode": "terrain_only",
		"objectives": [
			"Luftabwehr ausschalten",
			{"text": "Gebaeude besetzen", "target_id": "objective_point"},
		],
		"threats": [
			"NPC-Wache im Aussenposten",
			{"text": "Raketenwerfer am Hof"},
		],
		"recommended_loadout": [
			{
				"label": "Solo-Infiltration",
				"weapon_ids": ["sniper_rifle", "panzerfaust", "medic_tool"],
				"armor_id": "medium",
				"count": 1,
				"reason": "Reichweite, Anti-Armor und Support fuer den ersten Kontakt.",
			},
			{
				"role_id": "visual-id-guard",
				"weapon_ids": ["heavy_blaster", "unknown_weapon"],
				"reason": "Visual IDs duerfen keine Gameplay-Waffen werden.",
			},
		],
		"annotations": [
			{
				"kind": "note",
				"text": "AA",
				"position": {"x": 512.0, "y": 221.0},
				"radius": 64.0,
			},
		],
	}


func _collect_recommended_weapon_ids(recommended: Array) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for entry_variant in recommended:
		var entry: Dictionary = Dictionary(entry_variant)
		for weapon_id_variant in Array(entry.get("weapon_ids", [])):
			var weapon_id: String = String(weapon_id_variant).strip_edges()
			if not weapon_id.is_empty() and not result.has(weapon_id):
				result.append(weapon_id)
	return result


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


func _errors_contain(errors: PackedStringArray, needle: String) -> bool:
	for error_variant in errors:
		if String(error_variant).contains(needle):
			return true
	return false


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _cleanup_user_file(path: String) -> void:
	if path.is_empty():
		return
	var absolute_path: String = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute_path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
