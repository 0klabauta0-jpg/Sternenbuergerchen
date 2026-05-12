extends SceneTree

const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")
const TERRAIN_TEXTURE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_texture_catalog.gd")
const TERRAIN_MAP_RENDERER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_renderer.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

const MISSING_TEXTURE_PATH := "res://Assets/does_not_exist/task_356_missing_texture.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_356 MapEditor Lazy Terrain Texture Catalog Verifier ===")
	_test_catalog_loads_metadata_without_textures()
	_test_first_texture_use_loads_once_and_reuses_cache()
	_test_missing_texture_path_uses_safe_fallback()
	_test_renderer_uses_shared_lazy_cache()
	_test_editor_renderer_sources_do_not_preload_terrain_textures()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_356: FAILED")
		quit(1)
	else:
		print("TASK_356: ALL PASSED")
		quit(0)


func _test_catalog_loads_metadata_without_textures() -> void:
	TERRAIN_TEXTURE_CATALOG_SCRIPT.call("reset_cache_for_tests")
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	_assert(catalog != null, "TerrainTileCatalog loads")
	_assert(catalog.get_type_ids().size() > 20, "TerrainTileCatalog keeps the tile metadata catalog")
	_assert(String(catalog.call("get_texture_path", "ground_flat")).begins_with("res://"), "Catalog exposes texture paths without resolving them")
	_assert(int(TERRAIN_TEXTURE_CATALOG_SCRIPT.call("get_cached_path_count")) == 0, "Loading the catalog does not load terrain textures")
	_assert(not bool(catalog.call("is_texture_cached", "ground_flat")), "Ground tile texture starts uncached")


func _test_first_texture_use_loads_once_and_reuses_cache() -> void:
	TERRAIN_TEXTURE_CATALOG_SCRIPT.call("reset_cache_for_tests")
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	var texture_path: String = String(catalog.call("get_texture_path", "ground_flat"))
	var first_texture: Texture2D = catalog.get_texture("ground_flat")
	var second_texture: Texture2D = catalog.get_texture("ground_flat")
	_assert(first_texture != null, "First tile texture use returns a Texture2D")
	_assert(second_texture == first_texture, "Second tile texture use returns the cached Texture2D")
	_assert(bool(catalog.call("is_texture_cached", "ground_flat")), "TileCatalog reports the texture as cached after first use")
	_assert(int(TERRAIN_TEXTURE_CATALOG_SCRIPT.call("get_cached_path_count")) == 1, "Only the requested texture path is cached")
	_assert(int(TERRAIN_TEXTURE_CATALOG_SCRIPT.call("get_load_count", texture_path)) == 1, "Requested texture path is loaded once")


func _test_missing_texture_path_uses_safe_fallback() -> void:
	TERRAIN_TEXTURE_CATALOG_SCRIPT.call("reset_cache_for_tests")
	var fallback_texture: Texture2D = TERRAIN_TEXTURE_CATALOG_SCRIPT.call("get_texture", MISSING_TEXTURE_PATH) as Texture2D
	var default_texture_path: String = String(TERRAIN_TEXTURE_CATALOG_SCRIPT.call("get_default_tile_texture_path"))
	_assert(fallback_texture != null, "Missing texture path returns a safe fallback texture")
	_assert(int(TERRAIN_TEXTURE_CATALOG_SCRIPT.call("get_missing_path_count")) == 1, "Missing texture path is tracked")
	_assert(bool(TERRAIN_TEXTURE_CATALOG_SCRIPT.call("is_cached", default_texture_path)), "Fallback texture is cached instead of the missing path")
	_assert(not bool(TERRAIN_TEXTURE_CATALOG_SCRIPT.call("is_cached", MISSING_TEXTURE_PATH)), "Missing texture path is not cached as a Texture2D")


func _test_renderer_uses_shared_lazy_cache() -> void:
	TERRAIN_TEXTURE_CATALOG_SCRIPT.call("reset_cache_for_tests")
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	var renderer = TERRAIN_MAP_RENDERER_SCRIPT.new(catalog)
	var tile_data = TERRAIN_TILE_DATA_SCRIPT.new({
		"tile_id": "task_356_ground",
		"type_id": "ground_flat",
		"grid_position": Vector2i.ZERO,
		"world_position": Vector2.ZERO,
	})
	var texture_path: String = String(catalog.call("get_texture_path", "ground_flat"))
	var renderer_texture: Texture2D = renderer.resolve_tile_texture(tile_data)
	_assert(renderer_texture != null, "TerrainMapRenderer resolves tile texture lazily")
	_assert(bool(TERRAIN_TEXTURE_CATALOG_SCRIPT.call("is_cached", texture_path)), "Renderer texture access populates the shared cache")
	_assert(int(TERRAIN_TEXTURE_CATALOG_SCRIPT.call("get_load_count", texture_path)) == 1, "Renderer uses the same one-load cache")


func _test_editor_renderer_sources_do_not_preload_terrain_textures() -> void:
	var map_editor_source: String = _read_text_file("res://scripts/editor/map_editor.gd")
	var renderer_source: String = _read_text_file("res://scripts/terrain/terrain_map_renderer.gd")
	_assert(not map_editor_source.contains("Texture2D = preload(\"res://Assets/kenney_space-kit/Isometric/terrain"), "MapEditor no longer preloads terrain textures")
	_assert(not map_editor_source.contains("Texture2D = preload(\"res://Assets/kenney_space-kit/Isometric/corridor"), "MapEditor no longer preloads corridor textures")
	_assert(not renderer_source.contains("Texture2D = preload(\"res://Assets/kenney_space-kit/Isometric/terrain"), "TerrainMapRenderer no longer preloads terrain textures")
	_assert(not renderer_source.contains("Texture2D = preload(\"res://Assets/kenney_space-kit/Isometric/corridor"), "TerrainMapRenderer no longer preloads corridor textures")


func _read_text_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		print("  FAIL: %s" % message)
