extends SceneTree

const CATALOG_HELPER := preload("res://scripts/assets/curated_asset_catalog.gd")
const CENTRAL_CATALOG_PATH: String = "res://data/curated_asset_catalog.json"
const MANUAL_CHECK_PATH: String = "res://docs/manual_checks/asset_expansion_visual_smoke.md"
const MODULAR_MODELS_ROOT: String = "res://Assets/curated/kenney/modular_space/models"
const STATION_MODELS_ROOT: String = "res://Assets/curated/kenney/space_station/models"
const RANK_ROOT: String = "res://Assets/curated/kenney/ranks"
const PARTICLE_ROOT: String = "res://Assets/curated/kenney/particles"
const MAX_MODULAR_GLB: int = 10
const MAX_STATION_GLB: int = 12
const MAX_RANK_PNG: int = 12
const MAX_PARTICLE_PNG: int = 12
const REQUIRED_SAMPLE_IDS: PackedStringArray = [
	"ui_panel_frame_blue",
	"ui_button_square_blue",
	"ui_tactical_crosshair",
	"prompt_lmb",
	"prompt_shift",
	"cursor_select",
	"cursor_attack",
	"badge_role_ftl",
	"badge_role_medic",
	"badge_state_suppressed",
	"particle_lz_drop",
	"particle_contact_ping",
	"particle_heal_pulse",
	"modular_floor",
	"station_wall_door",
	"station_bed_single",
	"weapon_visual_sniper_model",
	"weapon_preview_rocket_launcher",
	"terrain_existing_ground_flat",
	"terrain_existing_wall_straight",
]
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
	print("=== TASK_198 Asset Import Gate Visual Smoke ===")
	_test_catalog_gate()
	_test_import_files_and_caps()
	_test_required_sample_assets()
	_test_visual_geometry_smoke()
	_test_missing_asset_diagnostics()
	_test_path_gate()
	_test_manual_checklist_documented()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_catalog_gate() -> void:
	_assert(FileAccess.file_exists(CENTRAL_CATALOG_PATH), "Central curated catalog exists")
	var loaded: Dictionary = CATALOG_HELPER.load_catalog()
	var diagnostics: PackedStringArray = PackedStringArray(loaded.get("diagnostics", PackedStringArray()))
	var entries: Dictionary = Dictionary(loaded.get("entries", {}))
	_assert(diagnostics.is_empty(), "Central catalog helper loads without diagnostics")
	_assert(entries.size() >= 70, "Central catalog has the expected asset expansion breadth")
	for category in REQUIRED_CATEGORIES:
		_assert(CATALOG_HELPER.get_entries_by_category(category).size() > 0, "Catalog category '%s' is available" % category)


func _test_import_files_and_caps() -> void:
	var modular_glbs: PackedStringArray = _list_files_by_extension(MODULAR_MODELS_ROOT, "glb", false)
	var station_glbs: PackedStringArray = _list_files_by_extension(STATION_MODELS_ROOT, "glb", false)
	var rank_pngs: PackedStringArray = _list_files_by_extension(RANK_ROOT, "png", false)
	var particle_pngs: PackedStringArray = _list_files_by_extension(PARTICLE_ROOT, "png", false)
	_assert(modular_glbs.size() > 0 and modular_glbs.size() <= MAX_MODULAR_GLB, "Modular Space GLB cap is respected")
	_assert(station_glbs.size() > 0 and station_glbs.size() <= MAX_STATION_GLB, "Space Station GLB cap is respected")
	_assert(rank_pngs.size() > 0 and rank_pngs.size() <= MAX_RANK_PNG, "Rank PNG cap is respected")
	_assert(particle_pngs.size() > 0 and particle_pngs.size() <= MAX_PARTICLE_PNG, "Particle PNG cap is respected")
	for imported_path in _curated_import_paths():
		_assert(FileAccess.file_exists(imported_path + ".import"), "Godot import metadata exists for '%s'" % imported_path)


func _test_required_sample_assets() -> void:
	for asset_id in REQUIRED_SAMPLE_IDS:
		var resolved: Dictionary = CATALOG_HELPER.resolve_asset(asset_id)
		_assert(bool(resolved.get("ok", false)), "Resolver loads sample asset '%s'" % asset_id)
		var path: String = String(resolved.get("path", "")).strip_edges()
		_assert(ResourceLoader.exists(path), "ResourceLoader sees sample asset '%s'" % asset_id)
		_assert(ResourceLoader.load(path) != null, "ResourceLoader loads sample asset '%s'" % asset_id)
	for asset_id in ["ui_panel_frame_blue", "prompt_lmb", "cursor_attack", "badge_role_ftl", "particle_lz_drop", "weapon_preview_rocket_launcher"]:
		var texture := ResourceLoader.load(CATALOG_HELPER.get_asset_path(asset_id))
		_assert(texture is Texture2D, "Sample '%s' loads as Texture2D" % asset_id)


func _test_visual_geometry_smoke() -> void:
	for asset_id in ["modular_floor", "station_wall_door", "station_bed_single", "weapon_visual_sniper_model", "weapon_visual_rocket_launcher_model", "terrain_existing_ground_flat", "terrain_existing_wall_straight"]:
		var path: String = CATALOG_HELPER.get_asset_path(asset_id)
		var resource := ResourceLoader.load(path)
		_assert(resource is PackedScene, "Sample '%s' loads as PackedScene" % asset_id)
		_assert(_packed_scene_has_mesh_geometry(resource as PackedScene), "Sample '%s' has visible mesh geometry" % asset_id)


func _test_missing_asset_diagnostics() -> void:
	var missing: Dictionary = CATALOG_HELPER.resolve_asset("task_198_missing_visual_probe")
	_assert(not bool(missing.get("ok", true)), "Resolver rejects missing smoke-test asset")
	_assert(String(missing.get("diagnostic", "")).begins_with("missing_catalog_asset_id:"), "Resolver returns missing-ID diagnostic")


func _test_path_gate() -> void:
	var text_files: Array = []
	text_files.append_array(_collect_text_files("res://data"))
	text_files.append_array(_collect_text_files("res://scripts"))
	text_files.append(MANUAL_CHECK_PATH)
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
	_assert(offenders.is_empty(), "Runtime data, scripts, tests and TASK_198 checklist contain no absolute local user paths")
	for data_file in _collect_text_files("res://data"):
		var text: String = _read_text_file(String(data_file))
		_assert(not text.contains("Pictures/Sternenbuerger"), "Data file avoids direct local Pictures source: %s" % String(data_file))


func _test_manual_checklist_documented() -> void:
	var checklist: String = _read_text_file(MANUAL_CHECK_PATH)
	_assert(not checklist.is_empty(), "Manual visual smoke checklist exists")
	for required_text in ["FOB / Homebase / Mission-HUD Icons", "Input / Cursor / Editor-Hints", "Rank-/Role-Badges", "Particle-Visuals", "Setpiece-/Weapon-/Terrain-Visuals"]:
		_assert(checklist.contains(required_text), "Manual checklist covers '%s'" % required_text)


func _curated_import_paths() -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	result.append_array(_list_files_by_extension(MODULAR_MODELS_ROOT, "glb", false))
	result.append_array(_list_files_by_extension(STATION_MODELS_ROOT, "glb", false))
	result.append_array(_list_files_by_extension(RANK_ROOT, "png", false))
	result.append_array(_list_files_by_extension(PARTICLE_ROOT, "png", false))
	result.sort()
	return result


func _packed_scene_has_mesh_geometry(scene: PackedScene) -> bool:
	if scene == null:
		return false
	var instance := scene.instantiate()
	var has_geometry: bool = _node_has_mesh_geometry(instance)
	instance.free()
	return has_geometry


func _node_has_mesh_geometry(node: Node) -> bool:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null and mesh_instance.mesh.get_aabb().size.length() > 0.001:
			return true
	for child in node.get_children():
		if _node_has_mesh_geometry(child):
			return true
	return false


func _list_files_by_extension(root_path: String, extension: String, recursive: bool) -> PackedStringArray:
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
				result.append_array(_list_files_by_extension(entry_path, extension, true))
		elif entry_name.get_extension().to_lower() == extension:
			result.append(entry_path)
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
