extends SceneTree

const CATALOG_PATH: String = "res://data/space_setpiece_catalog.json"
const INVENTORY_PATH: String = "res://docs/assets/space_setpiece_inventory.md"
const MODULAR_ROOT: String = "res://Assets/curated/kenney/modular_space"
const STATION_ROOT: String = "res://Assets/curated/kenney/space_station"
const MODULAR_MODELS: String = MODULAR_ROOT + "/models"
const STATION_MODELS: String = STATION_ROOT + "/models"
const MODULAR_MAX_GLB: int = 10
const STATION_MAX_GLB: int = 12
const REQUIRED_CATEGORIES: PackedStringArray = [
	"hangar_floor",
	"wall_panel",
	"console",
	"door_airlock",
	"medbay",
	"storage_cargo",
	"docking_pad",
]
const DISALLOWED_EXTENSIONS: PackedStringArray = [
	"fbx",
	"obj",
	"mtl",
	"dae",
	"stl",
	"unitypackage",
	"skp",
]
const TEXT_EXTENSIONS: PackedStringArray = [
	"gd",
	"json",
	"tscn",
	"tres",
	"cfg",
	"toml",
	"md",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_194 Space Modular Station Setpiece Import Verifier ===")
	_test_curated_folders_and_caps()
	_test_catalog_and_inventory_contract()
	_test_imported_glbs_are_loadable()
	_test_no_disallowed_asset_formats()
	_test_no_absolute_local_paths()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_curated_folders_and_caps() -> void:
	_assert(DirAccess.dir_exists_absolute(MODULAR_ROOT), "Modular Space curated root exists")
	_assert(DirAccess.dir_exists_absolute(STATION_ROOT), "Space Station curated root exists")
	_assert(FileAccess.file_exists(MODULAR_ROOT + "/License.txt"), "Modular Space license is copied")
	_assert(FileAccess.file_exists(STATION_ROOT + "/License.txt"), "Space Station license is copied")
	_assert(FileAccess.file_exists(MODULAR_ROOT + "/README.md"), "Modular Space curated README exists")
	_assert(FileAccess.file_exists(STATION_ROOT + "/README.md"), "Space Station curated README exists")
	_assert(FileAccess.file_exists(MODULAR_MODELS + "/Textures/colormap.png"), "Modular Space shared GLB texture is copied")
	_assert(FileAccess.file_exists(STATION_MODELS + "/Textures/colormap.png"), "Space Station shared GLB texture is copied")
	var modular_glbs: PackedStringArray = _list_glb_files(MODULAR_MODELS)
	var station_glbs: PackedStringArray = _list_glb_files(STATION_MODELS)
	_assert(modular_glbs.size() > 0 and modular_glbs.size() <= MODULAR_MAX_GLB, "Modular Space GLB subset stays within the 10-file cap")
	_assert(station_glbs.size() > 0 and station_glbs.size() <= STATION_MAX_GLB, "Space Station GLB subset stays within the 12-file cap")


func _test_catalog_and_inventory_contract() -> void:
	var catalog: Dictionary = _load_json(CATALOG_PATH)
	var inventory: String = _read_text_file(INVENTORY_PATH)
	_assert(not catalog.is_empty(), "Space setpiece catalog is valid JSON")
	_assert(not inventory.is_empty(), "Space setpiece inventory exists")
	_assert(String(Dictionary(catalog.get("rules", {})).get("format", "")) == "glb_only", "Catalog documents GLB-only import rule")
	_assert(String(Dictionary(catalog.get("rules", {})).get("runtime_contract", "")) == "visual_only_no_gameplay_truth", "Catalog documents visual-only runtime contract")
	for source_id in ["modular_space_kit", "space_station_kit"]:
		var source_entry: Dictionary = Dictionary(Dictionary(catalog.get("sources", {})).get(source_id, {}))
		var texture_path: String = String(source_entry.get("shared_texture", "")).strip_edges()
		_assert(texture_path.ends_with("/Textures/colormap.png") and ResourceLoader.exists(texture_path), "Catalog documents loadable shared texture for '%s'" % source_id)
	var entries: Array = Array(catalog.get("setpieces", []))
	_assert(entries.size() == MODULAR_MAX_GLB + STATION_MAX_GLB, "Catalog contains exactly the curated setpiece entries")
	_assert(_source_count(entries, "modular_space_kit") == MODULAR_MAX_GLB, "Catalog contains 10 Modular Space entries")
	_assert(_source_count(entries, "space_station_kit") == STATION_MAX_GLB, "Catalog contains 12 Space Station entries")
	for category in REQUIRED_CATEGORIES:
		_assert(_catalog_has_category(entries, category), "Catalog covers required category '%s'" % category)
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		_assert(String(entry.get("id", "")).strip_edges() != "", "Catalog entry has a stable ID")
		_assert(String(entry.get("path", "")).begins_with("res://Assets/curated/kenney/"), "Catalog entry uses a project asset path")
		_assert(float(entry.get("scale_hint", 0.0)) > 0.0, "Catalog entry carries a positive scale hint")
		_assert(inventory.contains(String(entry.get("id", ""))), "Inventory documents catalog entry '%s'" % String(entry.get("id", "")))


func _test_imported_glbs_are_loadable() -> void:
	var entries: Array = Array(_load_json(CATALOG_PATH).get("setpieces", []))
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var path: String = String(entry.get("path", "")).strip_edges()
		_assert(ResourceLoader.exists(path), "ResourceLoader sees '%s'" % path)
		_assert(ResourceLoader.load(path) != null, "GLB resource loads for '%s'" % path)


func _test_no_disallowed_asset_formats() -> void:
	var disallowed_files: PackedStringArray = PackedStringArray()
	for root_path in [MODULAR_ROOT, STATION_ROOT]:
		for file_path_variant in _collect_files(root_path):
			var file_path: String = String(file_path_variant)
			if DISALLOWED_EXTENSIONS.has(file_path.get_extension().to_lower()):
				disallowed_files.append(file_path)
	_assert(disallowed_files.is_empty(), "Curated setpiece folders contain no FBX/OBJ/MTL/DAE/STL/Unity/SKP duplicates")


func _test_no_absolute_local_paths() -> void:
	var files_to_scan: Array = [
		CATALOG_PATH,
		INVENTORY_PATH,
		MODULAR_ROOT + "/README.md",
		STATION_ROOT + "/README.md",
	]
	files_to_scan.append_array(_collect_text_files("res://data"))
	files_to_scan.append_array(_collect_text_files("res://scripts"))
	var forbidden_patterns: PackedStringArray = [
		"C:" + "\\" + "Users" + "\\",
		"C:" + "/" + "Users" + "/",
		"file:///" + "C:" + "/" + "Users" + "/",
	]
	var offenders: PackedStringArray = PackedStringArray()
	for file_path_variant in files_to_scan:
		var file_path: String = String(file_path_variant)
		var text: String = _read_text_file(file_path)
		for pattern in forbidden_patterns:
			if text.contains(pattern):
				offenders.append(file_path)
				break
	_assert(offenders.is_empty(), "Catalog, inventory, runtime data and tests contain no absolute local user paths")


func _list_glb_files(root_path: String) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	var dir := DirAccess.open(root_path)
	if dir == null:
		return result
	dir.list_dir_begin()
	var entry_name: String = dir.get_next()
	while not entry_name.is_empty():
		if not dir.current_is_dir() and entry_name.get_extension().to_lower() == "glb":
			result.append("%s/%s" % [root_path, entry_name])
		entry_name = dir.get_next()
	dir.list_dir_end()
	result.sort()
	return result


func _source_count(entries: Array, source_id: String) -> int:
	var count: int = 0
	for entry_variant in entries:
		if String(Dictionary(entry_variant).get("source_id", "")) == source_id:
			count += 1
	return count


func _catalog_has_category(entries: Array, category: String) -> bool:
	for entry_variant in entries:
		if String(Dictionary(entry_variant).get("category", "")) == category:
			return true
	return false


func _collect_files(root_path: String) -> Array:
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
			result.append_array(_collect_files(entry_path))
		else:
			result.append(entry_path)
		entry_name = dir.get_next()
	dir.list_dir_end()
	return result


func _collect_text_files(root_path: String) -> Array:
	var result: Array = []
	for file_path_variant in _collect_files(root_path):
		var file_path: String = String(file_path_variant)
		if TEXT_EXTENSIONS.has(file_path.get_extension().to_lower()):
			result.append(file_path)
	return result


func _load_json(path: String) -> Dictionary:
	var text: String = _read_text_file(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return Dictionary(parsed)


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
