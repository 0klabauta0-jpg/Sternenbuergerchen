extends SceneTree

const CATALOG_PATH: String = "res://data/rank_particle_asset_catalog.json"
const INVENTORY_PATH: String = "res://docs/assets/rank_particle_inventory.md"
const RANK_ROOT: String = "res://Assets/curated/kenney/ranks"
const PARTICLE_ROOT: String = "res://Assets/curated/kenney/particles"
const MAX_RANK_PNG: int = 12
const MAX_PARTICLE_PNG: int = 12
const REQUIRED_BADGE_IDS: PackedStringArray = [
	"badge_role_ftl",
	"badge_role_medic",
	"badge_role_rifle",
	"badge_role_heavy",
	"badge_role_pilot",
	"badge_role_engineer",
	"badge_role_enemy",
	"badge_state_down",
	"badge_state_ready",
	"badge_state_suppressed",
]
const REQUIRED_PARTICLE_IDS: PackedStringArray = [
	"particle_lz_drop",
	"particle_contact_ping",
	"particle_suppression_smoke",
	"particle_objective_marker",
	"particle_hit_flash",
	"particle_heal_pulse",
	"particle_warning_glow",
	"particle_trace_line",
	"particle_fire_burst",
	"particle_dust_kick",
	"particle_scorch_mark",
	"particle_command_ping",
]
const REQUIRED_PARTICLE_CATEGORIES: PackedStringArray = [
	"lz_drop",
	"contact",
	"suppression",
	"objective",
	"hit",
	"heal",
	"warning",
]
const DISALLOWED_EXTENSIONS: PackedStringArray = [
	"svg",
	"swf",
	"unitypackage",
	"fbx",
	"obj",
	"mtl",
	"glb",
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
	print("=== TASK_196 Rank Particle Asset Subset Import Verifier ===")
	_test_curated_folders_and_caps()
	_test_catalog_inventory_and_rules()
	_test_required_ids_and_categories()
	_test_assets_are_loadable_textures()
	_test_no_disallowed_formats()
	_test_no_absolute_local_paths()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_curated_folders_and_caps() -> void:
	_assert(DirAccess.dir_exists_absolute(RANK_ROOT), "Curated rank root exists")
	_assert(DirAccess.dir_exists_absolute(PARTICLE_ROOT), "Curated particle root exists")
	_assert(FileAccess.file_exists(RANK_ROOT + "/License.txt"), "Rank license is copied")
	_assert(FileAccess.file_exists(PARTICLE_ROOT + "/License.txt"), "Particle license is copied")
	_assert(FileAccess.file_exists(RANK_ROOT + "/README.md"), "Rank README exists")
	_assert(FileAccess.file_exists(PARTICLE_ROOT + "/README.md"), "Particle README exists")
	var rank_pngs: PackedStringArray = _list_png_files(RANK_ROOT)
	var particle_pngs: PackedStringArray = _list_png_files(PARTICLE_ROOT)
	_assert(rank_pngs.size() > 0 and rank_pngs.size() <= MAX_RANK_PNG, "Rank PNG subset stays within the 12-file cap")
	_assert(particle_pngs.size() > 0 and particle_pngs.size() <= MAX_PARTICLE_PNG, "Particle PNG subset stays within the 12-file cap")


func _test_catalog_inventory_and_rules() -> void:
	var catalog: Dictionary = _load_json(CATALOG_PATH)
	var inventory: String = _read_text_file(INVENTORY_PATH)
	_assert(not catalog.is_empty(), "Rank/particle catalog is valid JSON")
	_assert(not inventory.is_empty(), "Rank/particle inventory exists")
	var rules: Dictionary = Dictionary(catalog.get("rules", {}))
	_assert(String(rules.get("runtime_contract", "")) == "visual_only_no_gameplay_truth", "Catalog documents visual-only runtime contract")
	_assert(String(rules.get("format", "")) == "png_only", "Catalog documents PNG-only import")
	_assert(int(rules.get("rank_png_cap", 0)) == MAX_RANK_PNG, "Catalog documents rank PNG cap")
	_assert(int(rules.get("particle_png_cap", 0)) == MAX_PARTICLE_PNG, "Catalog documents particle PNG cap")
	_assert(bool(rules.get("no_particle_logic", false)), "Catalog forbids particle gameplay logic")
	_assert(bool(rules.get("no_status_truth", false)), "Catalog forbids badge status truth")


func _test_required_ids_and_categories() -> void:
	var catalog: Dictionary = _load_json(CATALOG_PATH)
	var badges: Array = Array(catalog.get("badges", []))
	var particles: Array = Array(catalog.get("particles", []))
	var inventory: String = _read_text_file(INVENTORY_PATH)
	_assert(badges.size() == REQUIRED_BADGE_IDS.size(), "Catalog contains exactly the required badge subset")
	_assert(particles.size() == REQUIRED_PARTICLE_IDS.size(), "Catalog contains exactly the required particle subset")
	var badge_by_id: Dictionary = _entries_by_id(badges)
	var particle_by_id: Dictionary = _entries_by_id(particles)
	for required_id in REQUIRED_BADGE_IDS:
		_assert(badge_by_id.has(required_id), "Catalog exposes required badge ID '%s'" % required_id)
		_assert(inventory.contains(required_id), "Inventory documents badge ID '%s'" % required_id)
	for required_id in REQUIRED_PARTICLE_IDS:
		_assert(particle_by_id.has(required_id), "Catalog exposes required particle ID '%s'" % required_id)
		_assert(inventory.contains(required_id), "Inventory documents particle ID '%s'" % required_id)
	for category in REQUIRED_PARTICLE_CATEGORIES:
		_assert(_catalog_has_category(particles, category), "Catalog covers particle category '%s'" % category)


func _test_assets_are_loadable_textures() -> void:
	var catalog: Dictionary = _load_json(CATALOG_PATH)
	var entries: Array = []
	entries.append_array(Array(catalog.get("badges", [])))
	entries.append_array(Array(catalog.get("particles", [])))
	var seen_ids: Dictionary = {}
	var seen_paths: Dictionary = {}
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var id: String = String(entry.get("id", "")).strip_edges()
		var path: String = String(entry.get("path", "")).strip_edges()
		_assert(not id.is_empty(), "Catalog entry has a stable ID")
		_assert(not seen_ids.has(id), "Catalog ID is unique: %s" % id)
		seen_ids[id] = true
		_assert(path.begins_with("res://Assets/curated/kenney/"), "Asset '%s' uses curated project path" % id)
		_assert(path.get_extension().to_lower() == "png", "Asset '%s' is PNG" % id)
		_assert(not seen_paths.has(path), "Catalog path is unique: %s" % path)
		seen_paths[path] = true
		_assert(ResourceLoader.exists(path), "ResourceLoader sees asset '%s'" % id)
		_assert(ResourceLoader.load(path) is Texture2D, "Asset '%s' loads as Texture2D" % id)


func _test_no_disallowed_formats() -> void:
	var disallowed_files: PackedStringArray = PackedStringArray()
	for root_path in [RANK_ROOT, PARTICLE_ROOT]:
		for file_path_variant in _collect_files(root_path):
			var file_path: String = String(file_path_variant)
			if DISALLOWED_EXTENSIONS.has(file_path.get_extension().to_lower()):
				disallowed_files.append(file_path)
	_assert(disallowed_files.is_empty(), "Curated rank/particle folders contain no SVG/SWF/Unity/3D duplicates")


func _test_no_absolute_local_paths() -> void:
	var files_to_scan: Array = [
		CATALOG_PATH,
		INVENTORY_PATH,
		RANK_ROOT + "/README.md",
		PARTICLE_ROOT + "/README.md",
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


func _list_png_files(root_path: String) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	var dir := DirAccess.open(root_path)
	if dir == null:
		return result
	dir.list_dir_begin()
	var entry_name: String = dir.get_next()
	while not entry_name.is_empty():
		if not dir.current_is_dir() and entry_name.get_extension().to_lower() == "png":
			result.append("%s/%s" % [root_path, entry_name])
		entry_name = dir.get_next()
	dir.list_dir_end()
	result.sort()
	return result


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
