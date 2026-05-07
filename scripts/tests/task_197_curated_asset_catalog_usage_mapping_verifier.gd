extends SceneTree

const CATALOG_PATH: String = "res://data/curated_asset_catalog.json"
const USAGE_DOC_PATH: String = "res://docs/assets/asset_usage_mapping.md"
const CATALOG_HELPER := preload("res://scripts/assets/curated_asset_catalog.gd")
const REQUIRED_CATEGORIES: PackedStringArray = [
	"ui",
	"input_prompt",
	"cursor",
	"rank_badge",
	"particle",
	"setpiece",
	"weapon_visual",
	"terrain_existing",
]
const REQUIRED_IDS: PackedStringArray = [
	"ui_panel_frame_blue",
	"prompt_lmb",
	"cursor_attack",
	"badge_role_ftl",
	"badge_state_suppressed",
	"particle_lz_drop",
	"particle_heal_pulse",
	"modular_floor",
	"station_wall_door",
	"weapon_visual_sniper_model",
	"weapon_preview_rocket_launcher",
	"terrain_existing_ground_flat",
	"terrain_existing_wall_straight",
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
	print("=== TASK_197 Curated Asset Catalog Usage Mapping Verifier ===")
	_test_central_catalog_rules()
	_test_helper_builds_flat_catalog()
	_test_required_categories_and_ids()
	_test_entries_are_loadable_or_diagnostic()
	_test_resolver_missing_asset_diagnostics()
	_test_no_absolute_local_paths()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_central_catalog_rules() -> void:
	var catalog: Dictionary = _load_json(CATALOG_PATH)
	var usage_doc: String = _read_text_file(USAGE_DOC_PATH)
	_assert(not catalog.is_empty(), "Central curated asset catalog is valid JSON")
	_assert(not usage_doc.is_empty(), "Asset usage mapping doc exists")
	var rules: Dictionary = Dictionary(catalog.get("rules", {}))
	_assert(String(rules.get("runtime_contract", "")) == "read_only_asset_paths_no_gameplay_truth", "Catalog documents read-only visual path contract")
	_assert(String(rules.get("load_policy", "")) == "explicit_res_paths_no_project_scanning", "Catalog forbids project-folder scanning")
	_assert(String(rules.get("missing_asset_policy", "")) == "diagnostic_no_silent_fallback", "Catalog documents diagnostic missing-asset policy")
	for source_variant in Array(catalog.get("source_catalogs", [])):
		var source: Dictionary = Dictionary(source_variant)
		var path: String = String(source.get("path", "")).strip_edges()
		_assert(path.begins_with("res://data/"), "Source catalog '%s' uses a project data path" % String(source.get("id", "")))
		_assert(FileAccess.file_exists(path), "Source catalog '%s' exists" % String(source.get("id", "")))


func _test_helper_builds_flat_catalog() -> void:
	var loaded: Dictionary = CATALOG_HELPER.load_catalog()
	var diagnostics: PackedStringArray = PackedStringArray(loaded.get("diagnostics", PackedStringArray()))
	var entries: Dictionary = Dictionary(loaded.get("entries", {}))
	_assert(diagnostics.is_empty(), "CuratedAssetCatalog loads without diagnostics")
	_assert(entries.size() >= 70, "Flat catalog contains UI, cursor, prompts, badges, particles, setpieces, weapons and terrain entries")
	_assert(CATALOG_HELPER.get_diagnostics().is_empty(), "Helper diagnostics accessor stays clean")


func _test_required_categories_and_ids() -> void:
	var entries: Dictionary = Dictionary(CATALOG_HELPER.load_catalog().get("entries", {}))
	for category in REQUIRED_CATEGORIES:
		_assert(CATALOG_HELPER.get_entries_by_category(category).size() > 0, "Catalog exposes category '%s'" % category)
		_assert(_read_text_file(USAGE_DOC_PATH).contains("`%s`" % category), "Usage mapping documents category '%s'" % category)
	for required_id in REQUIRED_IDS:
		_assert(entries.has(required_id), "Flat catalog exposes required ID '%s'" % required_id)
		_assert(_read_text_file(USAGE_DOC_PATH).contains(required_id), "Usage mapping documents required ID '%s'" % required_id)


func _test_entries_are_loadable_or_diagnostic() -> void:
	var entries: Dictionary = Dictionary(CATALOG_HELPER.load_catalog().get("entries", {}))
	var seen_paths: Dictionary = {}
	for id_variant in entries.keys():
		var id: String = String(id_variant)
		var entry: Dictionary = Dictionary(entries.get(id, {}))
		var path: String = String(entry.get("path", "")).strip_edges()
		_assert(id.strip_edges() != "", "Catalog entry has stable ID")
		_assert(String(entry.get("category", "")).strip_edges() != "", "Catalog entry '%s' has a category" % id)
		_assert(path.begins_with("res://Assets/"), "Catalog entry '%s' uses a project asset path" % id)
		_assert(not path.contains("%USERPROFILE%"), "Catalog entry '%s' does not use a local placeholder path" % id)
		_assert(not seen_paths.has("%s:%s" % [id, path]), "Catalog path check is deterministic for '%s'" % id)
		seen_paths["%s:%s" % [id, path]] = true
		var resolved: Dictionary = CATALOG_HELPER.resolve_asset(id)
		_assert(bool(resolved.get("ok", false)), "Resolver returns ok for '%s'" % id)
		_assert(String(resolved.get("path", "")) == path, "Resolver returns the catalog path for '%s'" % id)
		if String(entry.get("load_mode", "resource")) == "resource":
			_assert(ResourceLoader.exists(path), "ResourceLoader sees '%s'" % id)
			_assert(ResourceLoader.load(path) != null, "ResourceLoader loads '%s'" % id)


func _test_resolver_missing_asset_diagnostics() -> void:
	var missing: Dictionary = CATALOG_HELPER.resolve_asset("task_197_missing_probe")
	_assert(not bool(missing.get("ok", true)), "Resolver rejects unknown asset ID")
	_assert(String(missing.get("diagnostic", "")).begins_with("missing_catalog_asset_id:"), "Resolver reports missing ID diagnostic instead of fallback")
	_assert(CATALOG_HELPER.get_asset_path("task_197_missing_probe") == "", "Missing asset path resolves to empty string")
	_assert(CATALOG_HELPER.get_entry("task_197_missing_probe").is_empty(), "Missing asset entry resolves to empty dictionary")


func _test_no_absolute_local_paths() -> void:
	var files_to_scan: Array = [
		CATALOG_PATH,
		USAGE_DOC_PATH,
		"res://scripts/assets/curated_asset_catalog.gd",
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
	_assert(offenders.is_empty(), "Central catalog, data and scripts contain no absolute local user paths")


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
