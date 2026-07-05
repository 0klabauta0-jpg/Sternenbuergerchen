extends SceneTree

const PLAYER_ROSTER_STORE_SCRIPT: GDScript = preload("res://scripts/meta/player_roster_store.gd")
const TASK_PATH: String = "res://docs/tasks/BUGFIX_player_roster_corrupt_save_quiet_recovery.md"
const STORE_PATH: String = "res://scripts/meta/player_roster_store.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== BUGFIX Player Roster Corrupt Save Quiet Recovery ===")
	_test_docs_and_source()
	_test_empty_save_is_diagnosed_without_parse_path()
	_test_corrupt_save_is_diagnosed_and_recoverable()
	_test_roster_entry_marks_corrupt_active_save_invalid()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("BUGFIX_PLAYER_ROSTER_CORRUPT_SAVE_QUIET_RECOVERY: FAILED")
		quit(1)
		return
	print("BUGFIX_PLAYER_ROSTER_CORRUPT_SAVE_QUIET_RECOVERY: ALL PASSED")
	quit(0)


func _test_docs_and_source() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var store_text: String = _read_text(STORE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "Bugfix task file exists")
	_assert(task_text.contains("Corrupt Save Quiet Recovery"), "Bugfix task names corrupt save recovery")
	_assert(store_text.contains("load_parse_failed"), "Roster store reports parse failures as diagnostics")
	_assert(store_text.contains("load_empty"), "Roster store reports empty files as diagnostics")
	_assert(store_text.contains("JSON.new()"), "Roster store uses non-throwing JSON parser object")


func _test_empty_save_is_diagnosed_without_parse_path() -> void:
	var path: String = "user://codex_empty_roster_v1.json"
	_write_text(path, "")
	var result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("load_roster", "codex_empty", path))
	_assert(not bool(result.get("ok", true)), "Empty roster save is rejected")
	_assert(bool(result.get("exists", false)), "Empty roster save is reported as existing")
	_assert(_diagnostics_contain(result, "load_empty"), "Empty roster save reports load_empty")
	_cleanup(path)


func _test_corrupt_save_is_diagnosed_and_recoverable() -> void:
	var path: String = "user://codex_corrupt_roster_v1.json"
	_write_text(path, "{broken")
	var load_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("load_roster", "codex_corrupt", path))
	_assert(not bool(load_result.get("ok", true)), "Corrupt roster save is rejected")
	_assert(_diagnostics_contain(load_result, "load_parse_failed"), "Corrupt roster save reports load_parse_failed")

	var ensure_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("ensure_roster", "codex-corrupt-recovery", 8, "codex_corrupt", path))
	_assert(bool(ensure_result.get("ok", false)), "ensure_roster regenerates after corrupt save")
	_assert(bool(ensure_result.get("created", false)), "ensure_roster marks regenerated roster as created")
	_assert(Array(Dictionary(ensure_result.get("roster", {})).get("units", [])).size() >= 4, "Regenerated roster contains units")
	_cleanup(path)


func _test_roster_entry_marks_corrupt_active_save_invalid() -> void:
	var path: String = "user://codex_entry_corrupt_roster_v1.json"
	_write_text(path, "{broken")
	var list_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("list_roster_entries", "codex_entry_corrupt", path))
	var entries: Array = Array(list_result.get("entries", []))
	_assert(bool(list_result.get("ok", false)), "Roster entry list survives corrupt active save")
	_assert(entries.size() == 1, "Roster entry list contains corrupt active save")
	if not entries.is_empty():
		var entry: Dictionary = Dictionary(entries[0])
		_assert(not bool(entry.get("valid", true)), "Corrupt active save entry is marked invalid")
		_assert(String(entry.get("team_name", "")) == "Ungueltiger Team-Save", "Corrupt active save entry gets readable fallback name")
		_assert(_diagnostics_contain(entry, "load_parse_failed"), "Corrupt active save entry exposes parse diagnostic")
	_cleanup(path)


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open test file for writing: %s" % path)
		return
	file.store_string(text)
	file.close()


func _cleanup(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _diagnostics_contain(source: Dictionary, needle: String) -> bool:
	for entry in PackedStringArray(source.get("diagnostics", PackedStringArray())):
		if String(entry).contains(needle):
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
		return
	_failed += 1
	push_error("FAIL: %s" % message)
