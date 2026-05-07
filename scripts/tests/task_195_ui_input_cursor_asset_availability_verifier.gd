extends SceneTree

const CATALOG_PATH: String = "res://data/ui_asset_catalog.json"
const INVENTORY_PATH: String = "res://docs/assets/ui_input_cursor_availability.md"
const REQUIRED_SOURCE_ROOTS: PackedStringArray = [
	"res://Assets/kenney_ui-pack-space-expansion/",
	"res://Assets/kenney_ui-pack/",
	"res://Assets/kenney_input-prompts_1.4.1/Keyboard & Mouse/",
	"res://Assets/kenney_cursor-pixel-pack/",
]
const REQUIRED_IDS: PackedStringArray = [
	"ui_panel_frame_blue",
	"ui_progress_bar_blue",
	"ui_button_square_blue",
	"ui_button_rect_blue",
	"ui_button_sci_square_header",
	"ui_icon_check",
	"ui_icon_cross",
	"ui_icon_square",
	"ui_tactical_crosshair",
	"prompt_lmb",
	"prompt_rmb",
	"prompt_shift",
	"prompt_ctrl",
	"prompt_q",
	"prompt_e",
	"prompt_r",
	"prompt_f",
	"prompt_g",
	"prompt_space",
	"prompt_escape",
	"cursor_select",
	"cursor_move",
	"cursor_attack",
	"cursor_defend",
	"cursor_take",
	"cursor_area_drag",
	"cursor_editor_brush",
	"cursor_height",
	"cursor_marker",
	"cursor_patrol",
]
const REQUIRED_CATEGORIES: PackedStringArray = [
	"panel_frame",
	"button",
	"icon",
	"command_prompt",
	"cursor",
	"editor_tool",
	"tactical_marker",
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
	print("=== TASK_195 UI Input Cursor Asset Availability Verifier ===")
	_test_catalog_and_sources()
	_test_required_ids_and_categories()
	_test_assets_are_project_textures()
	_test_no_duplicate_curated_imports()
	_test_no_absolute_local_paths()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_catalog_and_sources() -> void:
	var catalog: Dictionary = _load_json(CATALOG_PATH)
	var inventory: String = _read_text_file(INVENTORY_PATH)
	_assert(not catalog.is_empty(), "UI asset catalog is valid JSON")
	_assert(not inventory.is_empty(), "UI/input/cursor availability doc exists")
	var rules: Dictionary = Dictionary(catalog.get("rules", {}))
	_assert(String(rules.get("import_status", "")) == "reuse_existing_project_copies", "Catalog documents reuse-only import status")
	_assert(String(rules.get("runtime_contract", "")) == "visual_only_no_input_logic", "Catalog documents visual-only input contract")
	_assert(bool(rules.get("no_curated_duplicate_import", false)), "Catalog forbids duplicate curated imports")
	for root_path in REQUIRED_SOURCE_ROOTS:
		_assert(DirAccess.dir_exists_absolute(root_path), "Existing source root is present: %s" % root_path)


func _test_required_ids_and_categories() -> void:
	var entries: Array = Array(_load_json(CATALOG_PATH).get("assets", []))
	var by_id: Dictionary = _entries_by_id(entries)
	for required_id in REQUIRED_IDS:
		_assert(by_id.has(required_id), "Catalog exposes required ID '%s'" % required_id)
		_assert(_read_text_file(INVENTORY_PATH).contains(required_id), "Availability doc lists required ID '%s'" % required_id)
	for category in REQUIRED_CATEGORIES:
		_assert(_catalog_has_category(entries, category), "Catalog covers category '%s'" % category)


func _test_assets_are_project_textures() -> void:
	for entry_variant in Array(_load_json(CATALOG_PATH).get("assets", [])):
		var entry: Dictionary = Dictionary(entry_variant)
		var path: String = String(entry.get("path", "")).strip_edges()
		_assert(path.begins_with("res://Assets/"), "Asset '%s' uses a project path" % String(entry.get("id", "")))
		_assert(ResourceLoader.exists(path), "ResourceLoader sees asset '%s'" % String(entry.get("id", "")))
		_assert(ResourceLoader.load(path) is Texture2D, "Asset '%s' loads as Texture2D" % String(entry.get("id", "")))


func _test_no_duplicate_curated_imports() -> void:
	for duplicate_path in [
		"res://Assets/curated/kenney/ui",
		"res://Assets/curated/kenney/input_prompts",
		"res://Assets/curated/kenney/cursor",
		"res://Assets/curated/kenney/cursors",
	]:
		_assert(not DirAccess.dir_exists_absolute(duplicate_path), "TASK_195 did not create duplicate curated folder '%s'" % duplicate_path)


func _test_no_absolute_local_paths() -> void:
	var files_to_scan: Array = [
		CATALOG_PATH,
		INVENTORY_PATH,
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
	_assert(offenders.is_empty(), "UI catalog, data and tests contain no absolute local user paths")


func _entries_by_id(entries: Array) -> Dictionary:
	var result: Dictionary = {}
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var id: String = String(entry.get("id", "")).strip_edges()
		if not id.is_empty():
			result[id] = entry
	return result


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
