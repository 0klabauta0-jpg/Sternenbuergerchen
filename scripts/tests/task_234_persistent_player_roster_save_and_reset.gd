extends SceneTree

const PLAYER_ROSTER_STORE_SCRIPT: GDScript = preload("res://scripts/meta/player_roster_store.gd")
const START_ROSTER_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/start_roster_generator.gd")
const META_UNIT_PROFILE_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile.gd")
const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")
const CONTRACT_DOC_PATH: String = "res://docs/dev/player_roster_save_contract.md"
const ROUNDTRIP_PATH: String = "user://profiles/task_234_roundtrip/roster_v1.json"
const RECOVERY_PATH: String = "user://profiles/task_234_recovery/roster_v1.json"
const RESET_PATH: String = "user://profiles/task_234_reset/roster_v1.json"
const MENU_PATH: String = "user://profiles/task_234_menu/roster_v1.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_234 Persistent Player Roster Save and Reset ===")
	_test_contract_doc()
	_test_save_load_roundtrip()
	_test_missing_and_bad_version_fallback()
	_test_reset_archives_existing_save()
	await _test_main_menu_uses_persistent_store_and_confirmation()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_contract_doc() -> void:
	var text: String = _read_text(CONTRACT_DOC_PATH)
	_assert(not text.is_empty(), "Player roster save contract doc exists")
	for required_text in ["user://profiles", "schema_version", "generator_seed", "portrait_id", "trait_ids", "archive", "local_player_profile", "SimulationRoot"]:
		_assert(text.contains(required_text), "Save contract documents %s" % required_text)


func _test_save_load_roundtrip() -> void:
	PLAYER_ROSTER_STORE_SCRIPT.call("delete_roster_for_tests", "task_234_roundtrip", ROUNDTRIP_PATH)
	var roster: Dictionary = _build_roster_with_progress_fields("task234_roundtrip", "task_234_roundtrip")
	var save_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("save_roster", roster, "task_234_roundtrip", ROUNDTRIP_PATH))
	_assert(bool(save_result.get("ok", false)), "Roster save writes user profile file")
	_assert(FileAccess.file_exists(ROUNDTRIP_PATH), "Roster save exists under user://profiles")
	var payload: Dictionary = Dictionary(save_result.get("payload", {}))
	_assert(int(payload.get("schema_version", 0)) == PLAYER_ROSTER_STORE_SCRIPT.SCHEMA_VERSION, "Save payload contains format version")
	_assert(String(payload.get("generator_seed", "")) == "task234_roundtrip", "Save payload contains generator seed")
	_assert(String(payload.get("profile_id", "")) == "task_234_roundtrip", "Save payload contains sanitized profile id")
	var load_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("load_roster", "task_234_roundtrip", ROUNDTRIP_PATH))
	_assert(bool(load_result.get("ok", false)), "Roster load accepts saved payload")
	var loaded_roster: Dictionary = Dictionary(load_result.get("roster", {}))
	_assert(String(loaded_roster.get("seed", "")) == "task234_roundtrip", "Loaded roster preserves seed")
	var loaded_unit: Dictionary = Dictionary(Array(loaded_roster.get("units", []))[0])
	var profile = META_UNIT_PROFILE_SCRIPT.new(loaded_unit)
	_assert(not String(profile.portrait_id).is_empty() and not String(profile.portrait_path).is_empty(), "MetaUnitProfile roundtrips portrait id and path")
	_assert(not PackedStringArray(profile.trait_ids).is_empty(), "MetaUnitProfile roundtrips traits")
	_assert(String(loaded_unit.get("status_text", "")) == "recovering", "Save roundtrips recovery/status field")
	_assert(not Array(loaded_unit.get("fireteam_history", [])).is_empty(), "Save roundtrips fireteam history field")


func _test_missing_and_bad_version_fallback() -> void:
	PLAYER_ROSTER_STORE_SCRIPT.call("delete_roster_for_tests", "task_234_recovery", RECOVERY_PATH)
	var missing_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("ensure_roster", "task234_missing", 24, "task_234_recovery", RECOVERY_PATH))
	_assert(bool(missing_result.get("ok", false)) and bool(missing_result.get("created", false)), "Missing save generates and persists a new roster")
	_assert(FileAccess.file_exists(RECOVERY_PATH), "Generated fallback save is written")
	_write_text(RECOVERY_PATH, JSON.stringify({"schema_version": 0, "store_id": "player_roster_store_v1", "profile_id": "task_234_recovery", "generator_seed": "old"}))
	var bad_load: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("load_roster", "task_234_recovery", RECOVERY_PATH))
	_assert(not bool(bad_load.get("ok", true)), "Bad version save is rejected")
	_assert(",".join(PackedStringArray(bad_load.get("diagnostics", PackedStringArray()))).contains("schema_version_invalid"), "Bad version reports schema diagnostic")
	var recovered: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("ensure_roster", "task234_recovered", 24, "task_234_recovery", RECOVERY_PATH))
	_assert(bool(recovered.get("ok", false)) and bool(recovered.get("created", false)), "Invalid save falls back to generated roster")
	_assert(String(Dictionary(recovered.get("roster", {})).get("seed", "")) == "task234_recovered", "Fallback uses requested recovery seed")


func _test_reset_archives_existing_save() -> void:
	PLAYER_ROSTER_STORE_SCRIPT.call("delete_roster_for_tests", "task_234_reset", RESET_PATH)
	var initial_roster: Dictionary = _build_roster_with_progress_fields("task234_reset_a", "task_234_reset")
	var initial_save: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("save_roster", initial_roster, "task_234_reset", RESET_PATH))
	_assert(bool(initial_save.get("ok", false)), "Initial reset fixture save succeeds")
	var reset_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("reset_roster", "task234_reset_b", 24, "task_234_reset", RESET_PATH, true))
	_assert(bool(reset_result.get("ok", false)), "Reset writes replacement roster")
	var archive_path: String = String(reset_result.get("archive_path", ""))
	_assert(not archive_path.is_empty() and FileAccess.file_exists(archive_path), "Reset archives the previous save")
	var archive_payload: Dictionary = _load_json(archive_path)
	_assert(String(archive_payload.get("generator_seed", "")) == "task234_reset_a", "Archive keeps old roster seed")
	var current_load: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("load_roster", "task_234_reset", RESET_PATH))
	_assert(String(Dictionary(current_load.get("roster", {})).get("seed", "")) == "task234_reset_b", "Current save uses reset seed")


func _test_main_menu_uses_persistent_store_and_confirmation() -> void:
	var main_menu := MAIN_MENU_SCENE.instantiate()
	main_menu.set("_start_roster_profile_id", "task_234_menu")
	main_menu.set("_start_roster_save_path", MENU_PATH)
	main_menu.set("_settings_config_path", "user://ui_native_r2_verifier/task234/settings.cfg")
	root.add_child(main_menu)
	await _wait_frames(3)
	main_menu.call("set_start_roster_store_path_for_tests", MENU_PATH, "task_234_menu", true)
	var first: Dictionary = Dictionary(main_menu.call("ensure_start_roster_exists", "task234_menu_seed", 24))
	var first_summary: Dictionary = Dictionary(first.get("summary", {}))
	_assert(bool(first.get("created", false)) and bool(first_summary.get("valid", false)), "Main menu creates and saves missing roster")
	var first_snapshot: Dictionary = Dictionary(main_menu.call("get_start_roster_snapshot"))
	_assert(bool(first_snapshot.get("save_exists", false)), "Main menu snapshot reports persisted roster save")
	_assert(String(first_snapshot.get("store_path", "")) == MENU_PATH, "Main menu snapshot exposes roster store path")
	main_menu.queue_free()
	await _wait_frames(2)

	var second_menu := MAIN_MENU_SCENE.instantiate()
	second_menu.set("_start_roster_profile_id", "task_234_menu")
	second_menu.set("_start_roster_save_path", MENU_PATH)
	second_menu.set("_settings_config_path", "user://ui_native_r2_verifier/task234/settings.cfg")
	root.add_child(second_menu)
	await _wait_frames(3)
	second_menu.call("set_start_roster_store_path_for_tests", MENU_PATH, "task_234_menu", false)
	var loaded: Dictionary = Dictionary(second_menu.call("ensure_start_roster_exists", "different_seed_should_not_replace", 24))
	_assert(bool(loaded.get("loaded", false)) and not bool(loaded.get("created", true)), "Main menu loads existing roster instead of replacing it")
	_assert(String(Dictionary(loaded.get("roster", {})).get("seed", "")) == "task234_menu_seed", "Loaded menu roster keeps saved seed")
	var prompt: Dictionary = Dictionary(second_menu.call("request_new_start_roster"))
	var pending_snapshot: Dictionary = Dictionary(second_menu.call("get_start_roster_snapshot"))
	_assert(bool(prompt.get("requires_confirmation", false)), "New-Team request requires confirmation")
	_assert(bool(pending_snapshot.get("reset_confirmation_pending", false)), "New-Team request only marks pending reset")
	_assert(String(_load_json(MENU_PATH).get("generator_seed", "")) == "task234_menu_seed", "Pending reset does not overwrite save")
	var confirmed: Dictionary = Dictionary(second_menu.call("confirm_new_start_roster"))
	var store_result: Dictionary = Dictionary(confirmed.get("store", {}))
	_assert(bool(store_result.get("ok", false)), "Confirmed reset writes new menu roster save")
	_assert(FileAccess.file_exists(String(store_result.get("archive_path", ""))), "Confirmed reset archives old menu save")
	_assert(String(Dictionary(store_result.get("roster", {})).get("seed", "")).contains("reset"), "Confirmed reset uses explicit reset seed")
	second_menu.queue_free()
	await _wait_frames(2)


func _build_roster_with_progress_fields(seed: String, profile_id: String) -> Dictionary:
	var roster: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", seed, 24, profile_id))
	var units: Array = Array(roster.get("units", []))
	if not units.is_empty():
		var first_unit: Dictionary = Dictionary(units[0]).duplicate(true)
		first_unit["status_text"] = "recovering"
		first_unit["recovery_state"] = {"state": "recovering", "turns_remaining": 2}
		first_unit["fireteam_history"] = [{"fireteam_id": "blue", "mission_id": "task_234_fixture"}]
		units[0] = first_unit
		roster["units"] = units
	return roster


func _write_text(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(text)
	file.close()


func _load_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return Dictionary(parsed)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
