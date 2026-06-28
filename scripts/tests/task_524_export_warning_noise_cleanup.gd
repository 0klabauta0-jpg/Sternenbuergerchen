extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_524_export_warning_noise_cleanup.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const EXPORT_CONTRACT_PATH: String = "res://data/export_runtime_package_contract.json"
const REFERENCE_ROOT: String = "res://addons/godot_open_rts_reference"
const REFERENCE_NOTE_PATH: String = "res://addons/godot_open_rts_reference/INSTALL_NOTE.md"
const OLD_FACTORY_COLORMAP_UID: String = "uid://dsxohkhemn17r"
const FACTORY_TEXTURE_URI: String = "Textures/colormap.png"
const FACTORY_MODEL_PATHS: Array[String] = [
	"res://Assets/curated/kenney/factory/models/building-a.glb",
	"res://Assets/curated/kenney/factory/models/building-d.glb",
	"res://Assets/curated/kenney/factory/models/chimney-medium.glb",
	"res://Assets/curated/kenney/factory/models/detail-tank.glb",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_524 Export Warning Noise Cleanup ===")
	_test_docs_and_wiring()
	_test_open_rts_reference_is_not_detected_as_nested_project()
	_test_factory_colormap_sources_are_stable()
	_test_local_godot_cache_has_no_old_factory_uid()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_524: FAILED")
		quit(1)
		return
	print("TASK_524: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_524 task file exists")
	_assert(_read_text(TASK_PATH).contains("## Status: IMPLEMENTIERT"), "TASK_524 task file marks implementation")
	_assert(_read_text(STATUS_PATH).contains("TASK_524 - Export Warning Noise Cleanup"), "Implementation status tracks TASK_524")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_524 - Export Warning Noise Cleanup (implementiert)"), "Roadmap marks TASK_524 implemented")
	_assert(_read_text(REPORT_PATH).contains("TASK_524 - Export Warning Noise Cleanup"), "Review workbench tracks TASK_524")
	_assert(_read_text(EXPORT_CONTRACT_PATH).contains("addons/godot_open_rts_reference/**"), "Runtime export contract still excludes reference project")


func _test_open_rts_reference_is_not_detected_as_nested_project() -> void:
	_assert(FileAccess.file_exists("%s/.gdignore" % REFERENCE_ROOT), "Reference package keeps .gdignore")
	_assert(not FileAccess.file_exists("%s/project.godot" % REFERENCE_ROOT), "Reference package has no active nested project.godot")
	_assert(FileAccess.file_exists("%s/project.godot.reference" % REFERENCE_ROOT), "Reference package keeps project.godot.reference")
	var note: String = _read_text(REFERENCE_NOTE_PATH)
	_assert(note.contains("project.godot.reference"), "Reference install note documents renamed project file")
	_assert(note.contains("Do not rename it back"), "Reference install note warns against re-enabling nested project")


func _test_factory_colormap_sources_are_stable() -> void:
	_assert(FileAccess.file_exists("res://Assets/curated/kenney/factory/models/Textures/colormap.png"), "Factory shared colormap texture exists")
	_assert(not _read_text("res://Assets/curated/kenney/factory/models/Textures/colormap.png.import").contains(OLD_FACTORY_COLORMAP_UID), "Factory colormap import does not reference old UID")
	for model_path in FACTORY_MODEL_PATHS:
		var model_bytes: PackedByteArray = FileAccess.get_file_as_bytes(model_path)
		_assert(_bytes_contain_ascii(model_bytes, FACTORY_TEXTURE_URI), "%s keeps relative colormap URI" % model_path.get_file())
		_assert(not _bytes_contain_ascii(model_bytes, OLD_FACTORY_COLORMAP_UID), "%s does not contain old colormap UID" % model_path.get_file())
		_assert(not _read_text("%s.import" % model_path).contains(OLD_FACTORY_COLORMAP_UID), "%s import does not contain old colormap UID" % model_path.get_file())


func _test_local_godot_cache_has_no_old_factory_uid() -> void:
	var cache_root: String = ProjectSettings.globalize_path("res://.godot/editor")
	if not DirAccess.dir_exists_absolute(cache_root):
		_assert(true, "No local Godot editor cache exists to inspect")
		return
	var offenders: PackedStringArray = _find_files_containing(cache_root, "filesystem_cache", OLD_FACTORY_COLORMAP_UID)
	_assert(offenders.is_empty(), "Local Godot filesystem cache has no old Factory colormap UID")


func _find_files_containing(root_path: String, name_prefix: String, needle: String) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	var dir := DirAccess.open(root_path)
	if dir == null:
		return result
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		if file_name == "." or file_name == "..":
			file_name = dir.get_next()
			continue
		var full_path: String = root_path.path_join(file_name)
		if dir.current_is_dir():
			result.append_array(_find_files_containing(full_path, name_prefix, needle))
		elif file_name.begins_with(name_prefix) and _read_absolute_text(full_path).contains(needle):
			result.append(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()
	return result


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _read_absolute_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _bytes_contain_ascii(bytes: PackedByteArray, needle: String) -> bool:
	var needle_bytes: PackedByteArray = needle.to_ascii_buffer()
	if needle_bytes.is_empty() or bytes.size() < needle_bytes.size():
		return false
	for index in range(0, bytes.size() - needle_bytes.size() + 1):
		var matches: bool = true
		for offset in range(needle_bytes.size()):
			if bytes[index + offset] != needle_bytes[offset]:
				matches = false
				break
		if matches:
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
