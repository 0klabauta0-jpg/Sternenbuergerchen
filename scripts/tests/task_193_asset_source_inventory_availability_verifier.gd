extends SceneTree

const MATRIX_PATH: String = "res://docs/assets/asset_source_availability_matrix.md"
const REQUIRED_COLUMNS: PackedStringArray = [
	"Source ID",
	"Local source",
	"Project path",
	"License",
	"File types / size",
	"Import status",
	"Max subset",
	"Planned usage",
	"Follow task",
]
const REQUIRED_SOURCES: Dictionary = {
	"modular_space_kit": {"status": "planned curated subset", "follow": "TASK_194"},
	"space_station_kit": {"status": "planned curated subset", "follow": "TASK_194"},
	"kenney_ui_pack_space_expansion": {"status": "reuse existing project copy", "follow": "TASK_195"},
	"kenney_ui_pack": {"status": "reuse existing project copy", "follow": "TASK_195"},
	"kenney_space_kit": {"status": "reuse existing project copy", "follow": "TASK_194"},
	"kenney_ranks_pack": {"status": "planned curated subset", "follow": "TASK_196"},
	"kenney_particle_pack": {"status": "planned curated subset", "follow": "TASK_196"},
	"kenney_input_keyboard_mouse": {"status": "reuse existing project copy", "follow": "TASK_195"},
	"kenney_cursor_pixel_pack": {"status": "reuse existing project copy", "follow": "TASK_195"},
}
const TEXT_EXTENSIONS: PackedStringArray = [
	"gd",
	"json",
	"tscn",
	"tres",
	"cfg",
	"toml",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_193 Asset Source Inventory Availability Verifier ===")
	_test_matrix_has_required_columns()
	_test_matrix_lists_all_required_sources()
	_test_existing_project_copies_are_marked_for_reuse()
	_test_missing_subsets_are_assigned_to_follow_tasks()
	_test_runtime_files_do_not_reference_local_user_paths()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_matrix_has_required_columns() -> void:
	var matrix_text: String = _read_text_file(MATRIX_PATH)
	_assert(not matrix_text.is_empty(), "Availability matrix exists and is readable")
	var header: String = _find_table_header(matrix_text)
	_assert(not header.is_empty(), "Availability matrix exposes a markdown table header")
	for column_name in REQUIRED_COLUMNS:
		_assert(header.contains(column_name), "Availability matrix contains required column '%s'" % column_name)


func _test_matrix_lists_all_required_sources() -> void:
	var matrix_text: String = _read_text_file(MATRIX_PATH)
	for source_id in REQUIRED_SOURCES.keys():
		var row: String = _find_source_row(matrix_text, String(source_id))
		_assert(not row.is_empty(), "Availability matrix lists source '%s'" % String(source_id))
		_assert(row.contains("Creative Commons Zero") and row.contains("CC0"), "Source '%s' documents CC0 license state" % String(source_id))
		_assert(row.contains("Assets/"), "Source '%s' documents a project path" % String(source_id))


func _test_existing_project_copies_are_marked_for_reuse() -> void:
	var matrix_text: String = _read_text_file(MATRIX_PATH)
	for source_id in [
		"kenney_ui_pack_space_expansion",
		"kenney_ui_pack",
		"kenney_space_kit",
		"kenney_input_keyboard_mouse",
		"kenney_cursor_pixel_pack",
	]:
		var row: String = _find_source_row(matrix_text, source_id)
		_assert(row.contains("reuse existing project copy"), "Existing project copy '%s' is marked reuse existing" % source_id)
		_assert(row.contains("| 0 |"), "Existing project copy '%s' has max subset 0" % source_id)


func _test_missing_subsets_are_assigned_to_follow_tasks() -> void:
	var matrix_text: String = _read_text_file(MATRIX_PATH)
	for source_id in REQUIRED_SOURCES.keys():
		var row: String = _find_source_row(matrix_text, String(source_id))
		var expectation: Dictionary = Dictionary(REQUIRED_SOURCES[source_id])
		_assert(row.contains(String(expectation.get("status", ""))), "Source '%s' has the expected import status" % String(source_id))
		_assert(row.contains(String(expectation.get("follow", ""))), "Source '%s' is assigned to the expected follow task" % String(source_id))
	for source_id in ["modular_space_kit", "space_station_kit", "kenney_ranks_pack", "kenney_particle_pack"]:
		var row: String = _find_source_row(matrix_text, source_id)
		_assert(not row.contains("| 0 |"), "Planned subset '%s' has a non-zero max subset cap" % source_id)


func _test_runtime_files_do_not_reference_local_user_paths() -> void:
	var text_files: Array = []
	for root_path in ["res://scripts", "res://data", "res://scenes"]:
		text_files.append_array(_collect_text_files(root_path))
	var forbidden_patterns: PackedStringArray = [
		"C:" + "\\" + "Users" + "\\",
		"C:" + "/" + "Users" + "/",
		"file:///" + "C:" + "/" + "Users" + "/",
	]
	var offenders: PackedStringArray = PackedStringArray()
	for file_path_variant in text_files:
		var file_path: String = String(file_path_variant)
		var text: String = _read_text_file(file_path)
		for pattern in forbidden_patterns:
			if text.contains(pattern):
				offenders.append(file_path)
				break
	_assert(offenders.is_empty(), "Runtime, data, scene and test files do not reference absolute local user paths")


func _find_table_header(text: String) -> String:
	for line in text.split("\n"):
		var stripped: String = String(line).strip_edges()
		if stripped.begins_with("| Source ID |"):
			return stripped
	return ""


func _find_source_row(text: String, source_id: String) -> String:
	var marker: String = "| `%s` |" % source_id
	for line in text.split("\n"):
		var stripped: String = String(line).strip_edges()
		if stripped.begins_with(marker):
			return stripped
	return ""


func _collect_text_files(root_path: String) -> Array:
	var result: Array = []
	var dir := DirAccess.open(root_path)
	if dir == null:
		return result
	dir.list_dir_begin()
	var entry_name: String = dir.get_next()
	while not entry_name.is_empty():
		if entry_name.begins_with("."):
			entry_name = dir.get_next()
			continue
		var entry_path: String = "%s/%s" % [root_path, entry_name]
		if dir.current_is_dir():
			result.append_array(_collect_text_files(entry_path))
		elif TEXT_EXTENSIONS.has(entry_name.get_extension().to_lower()):
			result.append(entry_path)
		entry_name = dir.get_next()
	dir.list_dir_end()
	return result


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
