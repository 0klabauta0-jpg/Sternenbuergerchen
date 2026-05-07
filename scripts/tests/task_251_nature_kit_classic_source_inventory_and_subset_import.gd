extends SceneTree

const CATALOG_PATH: String = "res://data/nature_kit_asset_catalog.json"
const INVENTORY_DOC_PATH: String = "res://docs/assets/nature_kit_classic_inventory.md"
const TASK_DOC_PATH: String = "res://docs/tasks/TASK_251_nature_kit_classic_source_inventory_and_subset_import.md"
const PROJECT_ROOT: String = "res://Assets/used/terrain/nature_kit_classic/"
const LICENSE_PATH: String = "res://Assets/used/terrain/nature_kit_classic/License.txt"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_251 Nature Kit Classic Source Inventory and Subset Import ===")
	var catalog: Dictionary = _load_json(CATALOG_PATH)
	_test_inventory_documentation()
	_test_catalog_contract(catalog)
	_test_project_files_and_gltf_bins(catalog)
	_test_no_runtime_duplicates_or_archives()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_inventory_documentation() -> void:
	_assert(FileAccess.file_exists(INVENTORY_DOC_PATH), "Nature Kit inventory document exists")
	_assert(FileAccess.file_exists(TASK_DOC_PATH), "TASK_251 task document exists")
	_assert(FileAccess.file_exists(LICENSE_PATH), "Nature Kit license copied into project")
	var inventory_text: String = _read_text(INVENTORY_DOC_PATH)
	var license_text: String = _read_text(LICENSE_PATH)
	for required_text in ["Kenney Nature Kit", "CC0", "glTF", "232", "25 Modelle", "cliffBrown_steps", "No complete"]:
		_assert(inventory_text.contains(required_text), "Inventory document includes %s" % required_text)
	_assert(license_text.contains("Creative Commons Zero") and license_text.contains("CC0"), "Copied license documents CC0")


func _test_catalog_contract(catalog: Dictionary) -> void:
	_assert(not catalog.is_empty(), "Nature Kit catalog JSON exists and parses")
	_assert(int(catalog.get("schema_version", 0)) == 1, "Nature Kit catalog schema is versioned")
	_assert(String(catalog.get("catalog_id", "")) == "nature_kit_classic_subset_v1", "Catalog has stable ID")
	_assert(String(catalog.get("license", "")) == "CC0", "Catalog documents CC0 license")
	_assert(String(catalog.get("project_root", "")) == PROJECT_ROOT, "Catalog project root is stable")
	var runtime_contract: Dictionary = Dictionary(catalog.get("runtime_contract", {}))
	_assert(String(runtime_contract.get("paths", "")) == "res_only_no_local_user_paths", "Catalog enforces res-only paths")
	_assert(String(runtime_contract.get("format_preference", "")) == "gltf_with_adjacent_bin", "Catalog prefers glTF with adjacent bin")
	_assert(bool(runtime_contract.get("visual_only", false)) and bool(runtime_contract.get("no_gameplay_state", false)), "Catalog declares visual-only use")
	_assert(bool(runtime_contract.get("no_zip_runtime_dependency", false)), "Catalog rejects ZIP runtime dependencies")
	_assert(bool(runtime_contract.get("no_fbx_obj_runtime_duplicates", false)), "Catalog rejects FBX/OBJ runtime duplicates")
	var source_audit: Dictionary = Dictionary(catalog.get("source_audit", {}))
	_assert(int(source_audit.get("gltf_model_count", 0)) == 232, "Source audit records glTF model count")
	_assert(int(source_audit.get("gltf_bin_count", 0)) == 232, "Source audit records glTF bin count")
	_assert(int(source_audit.get("selected_model_count", 0)) == 25, "Source audit records curated model count")
	var assets: Array = Array(catalog.get("assets", []))
	_assert(assets.size() == 25, "Catalog contains the curated 25-model subset")
	_assert(assets.size() <= int(runtime_contract.get("max_curated_model_count", 0)), "Catalog stays below max curated model count")
	var categories: Dictionary = _count_categories(assets)
	for category in ["cliffs", "ground", "rocks", "vegetation", "props"]:
		_assert(int(categories.get(category, 0)) > 0, "Catalog includes category: %s" % category)
	_assert(int(categories.get("cliffs", 0)) == 10, "Catalog includes ten cliff/slope candidates")


func _test_project_files_and_gltf_bins(catalog: Dictionary) -> void:
	var assets: Array = Array(catalog.get("assets", []))
	var seen_ids: Dictionary = {}
	for asset_variant in assets:
		if typeof(asset_variant) != TYPE_DICTIONARY:
			_assert(false, "Catalog asset entry is a dictionary")
			continue
		var asset: Dictionary = Dictionary(asset_variant)
		var asset_id: String = String(asset.get("asset_id", "")).strip_edges()
		var project_path: String = String(asset.get("project_path", "")).strip_edges()
		var bin_path: String = String(asset.get("bin_path", "")).strip_edges()
		_assert(not asset_id.is_empty() and not seen_ids.has(asset_id), "Asset ID is stable and unique: %s" % asset_id)
		seen_ids[asset_id] = true
		_assert(_is_project_runtime_path(project_path), "Asset path is project-local: %s" % asset_id)
		_assert(_is_project_runtime_path(bin_path), "Bin path is project-local: %s" % asset_id)
		_assert(project_path.ends_with(".gltf"), "Asset uses glTF runtime source: %s" % asset_id)
		_assert(bin_path.ends_with(".bin"), "Asset has bin dependency path: %s" % asset_id)
		_assert(_same_directory(project_path, bin_path), "glTF and bin are adjacent: %s" % asset_id)
		_assert(FileAccess.file_exists(project_path), "glTF file exists: %s" % asset_id)
		_assert(FileAccess.file_exists(bin_path), "Bin file exists: %s" % asset_id)
		_assert(ResourceLoader.exists(project_path), "ResourceLoader sees glTF asset: %s" % asset_id)
		_assert(float(asset.get("scale_hint", 0.0)) > 0.0, "Asset has scale hint: %s" % asset_id)
		_assert(not String(asset.get("gameplay_role", "")).is_empty(), "Asset has gameplay role note: %s" % asset_id)
	for doc_path in Array(catalog.get("documentation_assets", [])):
		_assert(_is_project_runtime_path(String(doc_path)) and FileAccess.file_exists(String(doc_path)), "Documentation asset exists: %s" % String(doc_path))


func _test_no_runtime_duplicates_or_archives() -> void:
	var extensions: Dictionary = _collect_extension_counts(PROJECT_ROOT)
	_assert(int(extensions.get("gltf", 0)) == 25, "Project subset has 25 glTF files")
	_assert(int(extensions.get("bin", 0)) == 25, "Project subset has 25 adjacent bin files")
	_assert(int(extensions.get("fbx", 0)) == 0, "Project subset has no FBX duplicates")
	_assert(int(extensions.get("obj", 0)) == 0 and int(extensions.get("mtl", 0)) == 0, "Project subset has no OBJ/MTL duplicates")
	_assert(int(extensions.get("zip", 0)) == 0, "Project subset has no ZIP runtime archives")
	var catalog_text: String = _read_text(CATALOG_PATH)
	_assert(not _contains_forbidden_local_path(catalog_text), "Nature Kit catalog has no local user paths")


func _count_categories(assets: Array) -> Dictionary:
	var counts: Dictionary = {}
	for asset_variant in assets:
		if typeof(asset_variant) != TYPE_DICTIONARY:
			continue
		var category: String = String(Dictionary(asset_variant).get("category", "")).strip_edges()
		if category.is_empty():
			continue
		counts[category] = int(counts.get(category, 0)) + 1
	return counts


func _collect_extension_counts(root_path: String) -> Dictionary:
	var counts: Dictionary = {}
	_collect_extension_counts_recursive(root_path, counts)
	return counts


func _collect_extension_counts_recursive(path: String, counts: Dictionary) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for file_name in dir.get_files():
		var extension: String = file_name.get_extension().to_lower()
		if extension.is_empty():
			continue
		counts[extension] = int(counts.get(extension, 0)) + 1
	for subdir_name in dir.get_directories():
		if subdir_name.begins_with("."):
			continue
		_collect_extension_counts_recursive("%s/%s" % [path.trim_suffix("/"), subdir_name], counts)


func _is_project_runtime_path(path: String) -> bool:
	var normalized_path: String = path.strip_edges()
	return normalized_path.begins_with(PROJECT_ROOT) \
		and not normalized_path.contains("C:/") \
		and not normalized_path.contains("C:" + "\\") \
		and not normalized_path.contains("%USERPROFILE%")


func _same_directory(left_path: String, right_path: String) -> bool:
	return left_path.get_base_dir() == right_path.get_base_dir()


func _contains_forbidden_local_path(text: String) -> bool:
	for pattern in ["C:/Users/", "C:" + "\\Users" + "\\", "file:///C:/Users/", "%USERPROFILE%"]:
		if text.contains(pattern):
			return true
	return false


func _load_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


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
