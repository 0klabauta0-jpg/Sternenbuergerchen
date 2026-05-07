extends SceneTree

const REPORT_PATH: String = "res://docs/reviews/used_asset_project_locality_audit.md"
const TASK_PATH: String = "res://docs/tasks/TASK_247_used_asset_project_locality_audit_gate.md"

const CATALOG_PATHS: PackedStringArray = [
	"res://data/audio_sfx_catalog.json",
	"res://data/background_image_catalog.json",
	"res://data/comic_bubble_asset_catalog.json",
	"res://data/curated_asset_catalog.json",
	"res://data/npc_unit_visual_mapping.json",
	"res://data/portrait_identity_catalog.json",
	"res://data/rank_particle_asset_catalog.json",
	"res://data/space_setpiece_catalog.json",
	"res://data/terrain_3d_asset_mapping.json",
	"res://data/ui_asset_catalog.json",
	"res://data/weapon_fire_vfx_catalog.json",
]

const RUNTIME_TEXT_ROOTS: PackedStringArray = [
	"res://scenes",
	"res://scripts",
	"res://data",
	"res://maps",
]
const RUNTIME_SINGLE_FILES: PackedStringArray = [
	"res://project.godot",
]
const DOCUMENTATION_SOURCE_ROOTS: PackedStringArray = [
	"res://docs",
	"res://Assets",
]
const TEXT_EXTENSIONS: PackedStringArray = [
	"cfg",
	"gd",
	"godot",
	"import",
	"json",
	"md",
	"tres",
	"tscn",
	"txt",
]
const RESOURCE_EXTENSIONS: PackedStringArray = [
	"fbx",
	"glb",
	"jpeg",
	"jpg",
	"ogg",
	"png",
	"tscn",
	"tres",
	"wav",
]
const IMPORT_METADATA_EXTENSIONS: PackedStringArray = [
	"fbx",
	"glb",
	"jpeg",
	"jpg",
	"ogg",
	"png",
	"wav",
]

var _passed: int = 0
var _failed: int = 0
var _catalog_count: int = 0
var _catalog_res_path_count: int = 0
var _runtime_res_path_count: int = 0
var _import_metadata_checked_count: int = 0
var _allowed_doc_source_note_count: int = 0
var _guard_literal_count: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_247 Used Asset Project Locality Audit Gate ===")
	_test_runtime_text_has_no_local_user_paths()
	_test_catalog_paths_are_project_local_and_importable()
	_test_runtime_res_paths_are_project_local()
	_test_documentation_source_notes_are_separated()
	_test_report_documents_audit_scope()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_runtime_text_has_no_local_user_paths() -> void:
	var offenders: PackedStringArray = PackedStringArray()
	var files: PackedStringArray = PackedStringArray()
	for root_path in RUNTIME_TEXT_ROOTS:
		files.append_array(_collect_text_files(root_path, true))
	for file_path in RUNTIME_SINGLE_FILES:
		files.append(file_path)
	for file_path in files:
		if _is_test_harness_path(file_path):
			continue
		var lines: PackedStringArray = _read_text(file_path).split("\n")
		for index in range(lines.size()):
			var line: String = String(lines[index])
			if not _line_has_local_path_marker(line):
				continue
			if _is_allowed_guard_literal(file_path, line):
				_guard_literal_count += 1
				continue
			offenders.append("%s:%d:%s" % [file_path, index + 1, line.strip_edges()])
	_assert(offenders.is_empty(), "Runtime text files have no local user/source paths")
	_assert(_guard_literal_count >= 1, "Runtime path-guard literals are separated from real path references")


func _test_catalog_paths_are_project_local_and_importable() -> void:
	var failures: PackedStringArray = PackedStringArray()
	var seen: Dictionary = {}
	for catalog_path in CATALOG_PATHS:
		_catalog_count += 1
		_assert(FileAccess.file_exists(catalog_path), "Catalog exists: %s" % catalog_path)
		var parsed: Variant = JSON.parse_string(_read_text(catalog_path))
		if typeof(parsed) != TYPE_DICTIONARY:
			failures.append("%s:invalid_json" % catalog_path)
			continue
		var res_paths: PackedStringArray = PackedStringArray()
		_collect_res_paths_from_variant(parsed, res_paths)
		for res_path in res_paths:
			if _is_dynamic_res_path(res_path):
				continue
			var key: String = "%s|%s" % [catalog_path, res_path]
			if seen.has(key):
				continue
			seen[key] = true
			_catalog_res_path_count += 1
			var result: Dictionary = _check_project_res_path(res_path)
			if not bool(result.get("ok", false)):
				failures.append("%s:%s:%s" % [catalog_path, res_path, String(result.get("reason", ""))])
	_assert(failures.is_empty(), "Catalog res:// paths are project-local and ResourceLoader/FileAccess valid")
	_assert(_catalog_count == CATALOG_PATHS.size(), "All expected asset catalogs were checked")
	_assert(_catalog_res_path_count >= 120, "Catalog gate covers the imported audio, background, model, particle, UI and portrait path set")


func _test_runtime_res_paths_are_project_local() -> void:
	var failures: PackedStringArray = PackedStringArray()
	var files: PackedStringArray = PackedStringArray()
	files.append_array(_collect_text_files("res://scenes", true))
	files.append_array(_collect_text_files("res://scripts", true))
	files.append_array(_collect_text_files("res://maps", true))
	for file_path in RUNTIME_SINGLE_FILES:
		files.append(file_path)
	var seen: Dictionary = {}
	for file_path in files:
		if _is_test_harness_path(file_path):
			continue
		for res_path in _extract_quoted_res_paths(_read_text(file_path)):
			if _is_dynamic_res_path(res_path) or _is_writable_runtime_data_path(res_path) or _is_runtime_resource_prefix(res_path):
				continue
			var key: String = "%s|%s" % [file_path, res_path]
			if seen.has(key):
				continue
			seen[key] = true
			_runtime_res_path_count += 1
			var result: Dictionary = _check_project_res_path(res_path)
			if not bool(result.get("ok", false)):
				failures.append("%s:%s:%s" % [file_path, res_path, String(result.get("reason", ""))])
	if not failures.is_empty():
		for index in range(mini(failures.size(), 12)):
			print("  RUNTIME PATH FAILURE: %s" % String(failures[index]))
	_assert(failures.is_empty(), "Runtime scene/script/map res:// paths resolve inside the project")
	_assert(_runtime_res_path_count >= 150, "Runtime path scan covers broad scene/script references")


func _test_documentation_source_notes_are_separated() -> void:
	var source_notes: PackedStringArray = PackedStringArray()
	for root_path in DOCUMENTATION_SOURCE_ROOTS:
		for file_path in _collect_text_files(root_path, true):
			if not _is_documentation_or_manifest_path(file_path):
				continue
			var lines: PackedStringArray = _read_text(file_path).split("\n")
			for index in range(lines.size()):
				var line: String = String(lines[index])
				if _line_has_local_path_marker(line):
					source_notes.append("%s:%d" % [file_path, index + 1])
	_allowed_doc_source_note_count = source_notes.size()
	_assert(_allowed_doc_source_note_count >= 1, "Documentation/source-note local path mentions are detected separately")
	_assert(_read_text(REPORT_PATH).contains("Allowed documentation/source notes"), "Report documents allowed source-note exceptions")


func _test_report_documents_audit_scope() -> void:
	_assert(FileAccess.file_exists(REPORT_PATH), "Used asset locality audit report exists")
	var report: String = _read_text(REPORT_PATH)
	for required_text in [
		"Runtime local user path violations: 0",
		"Catalogs checked",
		"ResourceLoader gate",
		"Allowed documentation/source notes",
		"TASK_248",
	]:
		_assert(report.contains(required_text), "Report includes '%s'" % required_text)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_247 task document exists")


func _check_project_res_path(path: String) -> Dictionary:
	var normalized_path: String = path.strip_edges()
	if normalized_path.is_empty():
		return {"ok": false, "reason": "empty_path"}
	if _string_has_local_path_marker(normalized_path):
		return {"ok": false, "reason": "local_user_path"}
	if not normalized_path.begins_with("res://"):
		return {"ok": false, "reason": "not_res_path"}
	if normalized_path.ends_with("/"):
		return {"ok": DirAccess.open(normalized_path) != null, "reason": "missing_directory"}
	var extension: String = normalized_path.get_extension().to_lower()
	if extension.is_empty():
		return {"ok": DirAccess.open(normalized_path) != null, "reason": "missing_directory"}
	if not FileAccess.file_exists(normalized_path):
		return {"ok": false, "reason": "missing_file"}
	if RESOURCE_EXTENSIONS.has(extension) and not ResourceLoader.exists(normalized_path):
		return {"ok": false, "reason": "resource_loader_missing"}
	if IMPORT_METADATA_EXTENSIONS.has(extension):
		_import_metadata_checked_count += 1
		if not FileAccess.file_exists(normalized_path + ".import"):
			return {"ok": false, "reason": "missing_import_metadata"}
	return {"ok": true, "reason": "ok"}


func _collect_res_paths_from_variant(value: Variant, result: PackedStringArray) -> void:
	match typeof(value):
		TYPE_DICTIONARY:
			for nested_value in Dictionary(value).values():
				_collect_res_paths_from_variant(nested_value, result)
		TYPE_ARRAY:
			for nested_value in Array(value):
				_collect_res_paths_from_variant(nested_value, result)
		TYPE_STRING:
			var text: String = String(value).strip_edges()
			if text.begins_with("res://"):
				result.append(text)


func _extract_quoted_res_paths(text: String) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	var regex := RegEx.new()
	var compile_error: int = regex.compile("[\"'](res://[^\"']+)[\"']")
	if compile_error != OK:
		return result
	for match_result in regex.search_all(text):
		result.append(String(match_result.get_string(1)).strip_edges())
	return result


func _is_dynamic_res_path(path: String) -> bool:
	return path.contains("%") or path.contains("{") or path.contains("}") or path.contains("*") or path.contains("+")


func _is_writable_runtime_data_path(path: String) -> bool:
	return path.begins_with("res://data/mission_scenarios")


func _is_runtime_resource_prefix(path: String) -> bool:
	if not path.get_extension().is_empty():
		return false
	if DirAccess.open(path) != null or FileAccess.file_exists(path):
		return false
	return path.begins_with("res://Assets/")


func _is_test_harness_path(path: String) -> bool:
	return path.begins_with("res://scripts/tests/")


func _is_documentation_or_manifest_path(path: String) -> bool:
	var extension: String = path.get_extension().to_lower()
	if not ["md", "txt"].has(extension):
		return false
	return path.begins_with("res://docs/") or path.begins_with("res://Assets/")


func _is_allowed_guard_literal(path: String, line: String) -> bool:
	if not path.begins_with("res://scripts/"):
		return false
	if _is_test_harness_path(path):
		return true
	var stripped: String = line.strip_edges()
	var guard_words: PackedStringArray = ["contains(", "begins_with(", "forbidden_patterns", "_contains_local_path", "_string_has_local_path_marker"]
	for guard_word in guard_words:
		if stripped.contains(guard_word):
			return true
	return false


func _line_has_local_path_marker(line: String) -> bool:
	return _string_has_local_path_marker(line)


func _string_has_local_path_marker(value: String) -> bool:
	for marker in _local_path_markers():
		if value.contains(marker):
			return true
	return false


func _local_path_markers() -> PackedStringArray:
	return PackedStringArray([
		"C:" + "\\" + "Users" + "\\",
		"C:" + "/" + "Users" + "/",
		"%USERPROFILE%",
		"file://",
		"Pictures" + "\\" + "Sternen",
		"Pictures/Sternen",
	])


func _collect_text_files(root_path: String, recursive: bool) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
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
			if recursive:
				result.append_array(_collect_text_files(entry_path, true))
		elif TEXT_EXTENSIONS.has(entry_name.get_extension().to_lower()):
			result.append(entry_path)
		entry_name = dir.get_next()
	dir.list_dir_end()
	result.sort()
	return result


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
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
