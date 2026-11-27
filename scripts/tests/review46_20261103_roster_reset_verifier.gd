extends SceneTree

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const STORE = preload("res://scripts/meta/player_roster_store.gd")
const GENERATOR = preload("res://scripts/meta/start_roster_generator.gd")
const MAIN_MENU = preload("res://scenes/ui/main_menu.tscn")

var _passed: int = 0
var _failed: int = 0
var _fixture_root: String = ""


func _init() -> void:
	if not GUARD.require_isolated_user_data():
		return
	call_deferred("_run")


func _run() -> void:
	_fixture_root = "user://review46_roster_reset_%d" % Time.get_ticks_usec()
	_test_archive_failure_preserves_active_roster()
	_test_successful_reset_archives_exact_original()
	_test_missing_roster_does_not_require_archive()
	_test_explicit_no_archive_remains_supported()
	await _test_main_menu_preserves_loaded_team_on_archive_failure()
	await _test_real_new_roster_button_preserves_failure_state()
	print("REVIEW46_ROSTER_RESET_RESULT passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_archive_failure_preserves_active_roster() -> void:
	var path: String = _path("blocked")
	var profile_id: String = "review46_blocked"
	if not _save_initial(path, profile_id, "review46_blocked_original"):
		return
	var before: PackedByteArray = FileAccess.get_file_as_bytes(path)
	var archive_blocker: String = "%s/archive" % path.get_base_dir()
	if not _write_text(archive_blocker, "review46 owned archive blocker"):
		return
	var result: Dictionary = STORE.reset_roster("review46_blocked_replacement", 20, profile_id, path, true)
	_print_result_diagnostics("blocked_reset", result)
	_check(not bool(result.get("ok", true)), "Required archive failure rejects the reset")
	_check(not bool(result.get("created", true)), "Rejected archive reset does not report a new roster")
	_check(not bool(result.get("archive_ok", true)), "Reset reports the failed archive")
	_check(_has_diagnostic(result, "archive_dir_failed:") or _has_diagnostic(result, "archive_write_failed:"), "Reset preserves the real owned archive-path failure diagnostic")
	_check(FileAccess.get_file_as_bytes(path) == before, "Failed archive leaves every original active-save byte unchanged")
	var loaded: Dictionary = STORE.load_roster(profile_id, path)
	_check(bool(loaded.get("ok", false)), "Original roster remains loadable after failed reset")
	_check(String(Dictionary(loaded.get("roster", {})).get("seed", "")) == "review46_blocked_original", "Failed reset retains the original persisted roster identity")
	_check(String(Dictionary(result.get("roster", {})).get("seed", "")) == "review46_blocked_original", "Failed reset returns the retained original roster to its consumer")
	_check(FileAccess.get_file_as_string(archive_blocker) == "review46 owned archive blocker", "Failed reset leaves the archive blocker unchanged")


func _test_successful_reset_archives_exact_original() -> void:
	var path: String = _path("success")
	var profile_id: String = "review46_success"
	if not _save_initial(path, profile_id, "review46_success_original"):
		return
	var before: PackedByteArray = FileAccess.get_file_as_bytes(path)
	var result: Dictionary = STORE.reset_roster("review46_success_replacement", 20, profile_id, path, true)
	_print_result_diagnostics("successful_reset", result)
	_check(bool(result.get("ok", false)), "Reset succeeds when its required archive can be written")
	_check(bool(result.get("created", false)), "Successful reset reports its new roster")
	_check(bool(result.get("archive_ok", false)), "Successful reset reports its completed archive")
	var archive_path: String = String(result.get("archive_path", ""))
	_check(not archive_path.is_empty() and FileAccess.file_exists(archive_path), "Successful reset exposes an existing archive")
	if not archive_path.is_empty() and FileAccess.file_exists(archive_path):
		_check(FileAccess.get_file_as_bytes(archive_path) == before, "Required archive preserves the complete original save bytes")
		var archived: Dictionary = STORE.load_roster(profile_id, archive_path)
		_check(bool(archived.get("ok", false)) and String(Dictionary(archived.get("roster", {})).get("seed", "")) == "review46_success_original", "Archived original roster remains loadable with its original identity")
	var loaded: Dictionary = STORE.load_roster(profile_id, path)
	_check(bool(loaded.get("ok", false)) and String(Dictionary(loaded.get("roster", {})).get("seed", "")) == "review46_success_replacement", "Successful reset persists the requested replacement roster")


func _test_missing_roster_does_not_require_archive() -> void:
	var path: String = _path("missing")
	var profile_id: String = "review46_missing"
	_check(not FileAccess.file_exists(path), "Missing-roster fixture starts without an active save")
	var result: Dictionary = STORE.reset_roster("review46_missing_created", 20, profile_id, path, true)
	_print_result_diagnostics("missing_reset", result)
	_check(bool(result.get("ok", false)) and bool(result.get("created", false)), "First roster creation succeeds without a previous save to archive")
	var loaded: Dictionary = STORE.load_roster(profile_id, path)
	_check(bool(loaded.get("ok", false)) and String(Dictionary(loaded.get("roster", {})).get("seed", "")) == "review46_missing_created", "First reset roster is valid and persisted at the explicit fixture path")


func _test_explicit_no_archive_remains_supported() -> void:
	var path: String = _path("no_archive")
	var profile_id: String = "review46_no_archive"
	if not _save_initial(path, profile_id, "review46_no_archive_original"):
		return
	var archive_blocker: String = "%s/archive" % path.get_base_dir()
	if not _write_text(archive_blocker, "explicit no archive fixture"):
		return
	var result: Dictionary = STORE.reset_roster("review46_no_archive_replacement", 20, profile_id, path, false)
	_print_result_diagnostics("no_archive_reset", result)
	_check(bool(result.get("ok", false)), "Explicit archive opt-out remains compatible even when archive directory is blocked")
	var loaded: Dictionary = STORE.load_roster(profile_id, path)
	_check(bool(loaded.get("ok", false)) and String(Dictionary(loaded.get("roster", {})).get("seed", "")) == "review46_no_archive_replacement", "Explicit archive opt-out still persists its requested replacement")
	_check(FileAccess.get_file_as_string(archive_blocker) == "explicit no archive fixture", "Archive opt-out never touches the unused archive path")


func _test_main_menu_preserves_loaded_team_on_archive_failure() -> void:
	var path: String = _path("menu")
	var profile_id: String = "review46_menu"
	var original_seed: String = "review46_menu_original"
	if not _save_initial(path, profile_id, original_seed):
		return
	var menu = MAIN_MENU.instantiate()
	# Configure before _ready(), so the real menu never visits its default profile.
	menu.set_start_roster_store_path_for_tests(path, profile_id, false)
	root.add_child(menu)
	await process_frame
	await process_frame
	menu.ensure_start_roster_exists(original_seed, 20)
	var before_snapshot: Dictionary = menu.get_start_roster_snapshot()
	var before_bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	_check(bool(before_snapshot.get("loaded_from_save", false)) and String(before_snapshot.get("seed", "")) == original_seed, "Real menu loads the explicit fixture roster before reset")
	var prompt: Dictionary = menu.request_new_start_roster()
	_check(bool(prompt.get("requires_confirmation", false)), "Real menu requires confirmation before replacing its loaded roster")
	var archive_blocker: String = "%s/archive" % path.get_base_dir()
	if not _write_text(archive_blocker, "review46 owned menu archive blocker"):
		menu.queue_free()
		await process_frame
		return
	var result: Dictionary = menu.confirm_new_start_roster()
	var after_snapshot: Dictionary = menu.get_start_roster_snapshot()
	_check(not bool(Dictionary(result.get("store", {})).get("ok", true)), "Real menu receives the required archive failure")
	_check(not bool(result.get("created", true)), "Real menu does not report a new team after archive failure")
	_check(String(after_snapshot.get("seed", "")) == original_seed, "Real menu keeps displaying the loaded team's original identity after archive failure")
	_check(String(Dictionary(result.get("roster", {})).get("seed", "")) == original_seed, "Failed menu reset returns its unchanged displayed roster")
	_check(bool(after_snapshot.get("loaded_from_save", false)) == bool(before_snapshot.get("loaded_from_save", false)), "Failed menu reset retains its loaded-roster status")
	_check(bool(after_snapshot.get("created_on_first_start", false)) == bool(before_snapshot.get("created_on_first_start", false)), "Failed menu reset does not mark the existing roster as newly created")
	_check(not bool(after_snapshot.get("last_store_ok", true)), "Menu exposes the failed reset in its normal status snapshot")
	_check(FileAccess.get_file_as_bytes(path) == before_bytes, "Confirmed menu reset with failed archive preserves every active-save byte")
	var remove_error: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(archive_blocker))
	_check(remove_error == OK, "Only the test-owned menu archive blocker can be removed for the retry")
	if remove_error == OK:
		menu.request_new_start_roster()
		var retry: Dictionary = menu.confirm_new_start_roster()
		var retry_store: Dictionary = Dictionary(retry.get("store", {}))
		_check(bool(retry.get("created", false)) and bool(retry_store.get("ok", false)), "Real menu successfully resets after its archive obstruction is removed")
		_check(String(Dictionary(retry.get("roster", {})).get("seed", "")) == "%s_reset_01" % original_seed, "Failed menu reset does not consume a successful reset generation")
		var archive_path: String = String(retry_store.get("archive_path", ""))
		_check(not archive_path.is_empty() and FileAccess.file_exists(archive_path), "Successful menu retry creates its required archive")
		if not archive_path.is_empty() and FileAccess.file_exists(archive_path):
			_check(FileAccess.get_file_as_bytes(archive_path) == before_bytes, "Menu retry archives the original team rather than a failed replacement")
	menu.queue_free()
	await process_frame


func _test_real_new_roster_button_preserves_failure_state() -> void:
	var path: String = _path("menu_button")
	var profile_id: String = "review46_button"
	var original_seed: String = "review46_button_original"
	if not _save_initial(path, profile_id, original_seed):
		return
	var menu = MAIN_MENU.instantiate()
	menu.set_start_roster_store_path_for_tests(path, profile_id, false)
	root.add_child(menu)
	await process_frame
	await process_frame
	menu.ensure_start_roster_exists(original_seed, 20)
	var button := menu.get_node("TeamsScreen/TeamsMargin/TeamsVBox/TeamsActionRow/NewRosterButton") as Button
	var status_label := menu.get_node("MenuRail/MenuMargin/MenuVBox/StatusLabel") as Label
	var archive_blocker: String = "%s/archive" % path.get_base_dir()
	if not _write_text(archive_blocker, "review46 owned button archive blocker"):
		menu.queue_free()
		await process_frame
		return
	var before_bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	button.pressed.emit()
	await process_frame
	var prompt_snapshot: Dictionary = menu.get_start_roster_snapshot()
	var before_editor: Dictionary = menu.get_team_editor_snapshot()
	_check(bool(prompt_snapshot.get("reset_confirmation_pending", false)), "First real NewRosterButton click requests confirmation")
	_check(not bool(before_editor.get("visible", true)), "Confirmation starts with the existing team editor closed")
	_check(FileAccess.get_file_as_bytes(path) == before_bytes, "First real NewRosterButton click preserves the active save")
	button.pressed.emit()
	await process_frame
	var failed_snapshot: Dictionary = menu.get_start_roster_snapshot()
	var failed_editor: Dictionary = menu.get_team_editor_snapshot()
	_check(not bool(failed_snapshot.get("last_store_ok", true)), "Second real NewRosterButton click reports the failed archive")
	_check(String(failed_snapshot.get("seed", "")) == original_seed, "Failed actual button reset retains the original displayed roster")
	_check(FileAccess.get_file_as_bytes(path) == before_bytes, "Failed actual button reset preserves every original save byte")
	_check(failed_editor == before_editor, "Failed actual button reset leaves the complete existing editor snapshot unchanged")
	_check(status_label.text == "Team konnte nicht gespeichert werden.", "Actual button caller keeps the reset failure visible in the normal status label")
	_check(bool(failed_snapshot.get("reset_confirmation_pending", false)), "Actual button caller keeps the failed confirmation available for retry")
	var remove_error: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(archive_blocker))
	_check(remove_error == OK, "Only the actual-button fixture's owned blocker is removed for retry")
	if remove_error == OK:
		button.pressed.emit()
		await process_frame
		var retry_snapshot: Dictionary = menu.get_start_roster_snapshot()
		var retry_editor: Dictionary = menu.get_team_editor_snapshot()
		_check(bool(retry_snapshot.get("last_store_ok", false)) and String(retry_snapshot.get("seed", "")) == "%s_reset_01" % original_seed, "Actual button retry succeeds without consuming a failed generation")
		_check(bool(retry_editor.get("visible", false)), "Successful actual button retry still opens the team editor")
		var library: Dictionary = STORE.list_roster_entries(profile_id, path)
		var archives: Array = []
		for entry_variant in Array(library.get("entries", [])):
			var entry: Dictionary = Dictionary(entry_variant)
			if bool(entry.get("archived", false)):
				archives.append(entry)
		_check(archives.size() == 1, "Successful actual button retry creates exactly one original-team archive")
		if archives.size() == 1:
			var archive_path: String = String(Dictionary(archives[0]).get("path", ""))
			_check(not archive_path.is_empty() and FileAccess.file_exists(archive_path), "Store lists an existing archive after the successful actual button retry")
			if not archive_path.is_empty() and FileAccess.file_exists(archive_path):
				_check(FileAccess.get_file_as_bytes(archive_path) == before_bytes, "Actual button retry archives the original failed-reset roster")
	menu.queue_free()
	await process_frame


func _path(case_name: String) -> String:
	return "%s/%s/roster_v1.json" % [_fixture_root, case_name]


func _save_initial(path: String, profile_id: String, seed: String) -> bool:
	var roster: Dictionary = GENERATOR.generate_start_roster(seed, 20, profile_id)
	var result: Dictionary = STORE.save_roster(roster, profile_id, path)
	_print_result_diagnostics("initial_" + profile_id, result)
	var saved: bool = bool(result.get("ok", false)) and FileAccess.file_exists(path)
	_check(saved, "Initial real roster is persisted at explicit test path: %s" % path)
	return saved


func _write_text(path: String, content: String) -> bool:
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	_check(directory_error == OK, "Owned fixture parent directory is available")
	if directory_error != OK:
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	_check(file != null, "Owned archive blocker file can be created")
	if file == null:
		return false
	file.store_string(content)
	file.close()
	return true


func _has_diagnostic(result: Dictionary, prefix: String) -> bool:
	for diagnostic in PackedStringArray(result.get("diagnostics", PackedStringArray())):
		if String(diagnostic).begins_with(prefix):
			return true
	return false


func _print_result_diagnostics(case_name: String, result: Dictionary) -> void:
	print("REVIEW46_ROSTER_FIXTURE_DIAGNOSTICS ", JSON.stringify({
		"case": case_name,
		"ok": result.get("ok", false),
		"diagnostics": result.get("diagnostics", []),
	}))


func _check(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: " + message)
	else:
		_failed += 1
		print("FAIL: " + message)
