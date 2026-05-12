extends SceneTree

const CATALOG_PATH: String = "res://data/portrait_identity_catalog.json"
const INVENTORY_DOC_PATH: String = "res://docs/assets/portrait_identity_inventory.md"
const CHAR_DIR: String = "res://Assets/Char"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_338 Portrait Asset Intake Catalog Sync ===")
	_test_asset_imports_and_inventory_count()
	_test_task338_portraits_are_cataloged()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_asset_imports_and_inventory_count() -> void:
	var png_paths: PackedStringArray = _list_char_pngs()
	var import_paths: PackedStringArray = _list_char_png_imports()
	var catalog: Dictionary = _load_json(CATALOG_PATH)
	var inventory: Dictionary = Dictionary(catalog.get("source_inventory", {}))
	var entries: Array = Array(catalog.get("entries", []))
	var doc: String = _read_text(INVENTORY_DOC_PATH)
	_assert(png_paths.size() > 0, "Portrait PNG sources exist under Assets/Char")
	_assert(import_paths.size() == png_paths.size(), "Every Portrait PNG has one Godot .png.import sidecar")
	for png_path in png_paths:
		_assert(FileAccess.file_exists("%s.import" % png_path), "Portrait import sidecar exists: %s" % png_path.get_file())
	_assert(int(inventory.get("scanned_png_count", 0)) == png_paths.size(), "Catalog source inventory count matches Assets/Char PNG count")
	_assert(doc.contains("PNG-Dateien gesamt: %d" % png_paths.size()), "Inventory doc records current PNG count")
	_assert(doc.contains("Runtime-Katalog fuer Start-Roster: %d Kandidaten" % entries.size()), "Inventory doc records expanded runtime catalog size")


func _test_task338_portraits_are_cataloged() -> void:
	var png_paths: PackedStringArray = _list_char_pngs()
	var catalog: Dictionary = _load_json(CATALOG_PATH)
	var entries: Array = Array(catalog.get("entries", []))
	var entries_by_path: Dictionary = {}
	var task338_entry_count: int = 0
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var path: String = String(entry.get("path", ""))
		entries_by_path[path] = entry
		if _is_task338_portrait_name(String(entry.get("file_name", ""))):
			task338_entry_count += 1
			_assert(String(entry.get("id", "")).begins_with("char_portrait_"), "TASK_338 catalog entry has stable id: %s" % String(entry.get("id", "")))
			_assert(bool(entry.get("candidate", false)), "TASK_338 catalog entry is a roster candidate: %s" % String(entry.get("id", "")))
			_assert(path.begins_with("res://Assets/Char/"), "TASK_338 catalog entry stays in Assets/Char: %s" % String(entry.get("id", "")))
			_assert(ResourceLoader.exists(path), "TASK_338 catalog texture is loadable: %s" % String(entry.get("id", "")))
			_assert(FileAccess.file_exists("%s.import" % path), "TASK_338 catalog texture has import sidecar: %s" % String(entry.get("id", "")))
			if int(entry.get("width", 0)) >= 1254 and int(entry.get("height", 0)) >= 1254:
				_assert(Array(entry.get("diagnostics", [])).has("square_source_use_scaled_texture_rect"), "Square TASK_338 source keeps fixed-UI diagnostic: %s" % String(entry.get("id", "")))
	var task338_source_count: int = 0
	for png_path in png_paths:
		if _is_task338_portrait_name(png_path.get_file()):
			task338_source_count += 1
			_assert(entries_by_path.has(png_path), "New May-12 portrait source is cataloged: %s" % png_path.get_file())
	_assert(task338_source_count >= 25, "TASK_338 sees the imported May-12 portrait batch")
	_assert(task338_entry_count == task338_source_count, "TASK_338 catalog covers the full May-12 portrait batch")


func _list_char_pngs() -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	var dir := DirAccess.open(CHAR_DIR)
	if dir == null:
		return result
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.get_extension().to_lower() == "png":
			result.append("%s/%s" % [CHAR_DIR, file_name])
		file_name = dir.get_next()
	dir.list_dir_end()
	result.sort()
	return result


func _list_char_png_imports() -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	var dir := DirAccess.open(CHAR_DIR)
	if dir == null:
		return result
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".png.import"):
			result.append("%s/%s" % [CHAR_DIR, file_name])
		file_name = dir.get_next()
	dir.list_dir_end()
	result.sort()
	return result


func _is_task338_portrait_name(file_name: String) -> bool:
	return file_name.contains("May 12, 2026") or file_name.contains("12. Mai 2026")


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


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
