class_name TerrainTextureCatalog
extends RefCounted

const DEFAULT_TILE_TEXTURE_PATH: String = "res://Assets/kenney_space-kit/Isometric/terrain_SW.png"

const COMMON_TEXTURE_PATHS: Dictionary = {
	"tile_default": DEFAULT_TILE_TEXTURE_PATH,
	"cliff_se": "res://Assets/kenney_space-kit/Isometric/terrain_sideCliff_SE.png",
	"cliff_sw": "res://Assets/kenney_space-kit/Isometric/terrain_sideCliff_SW.png",
	"cliff_ne": "res://Assets/kenney_space-kit/Isometric/terrain_sideCliff_NE.png",
	"cliff_nw": "res://Assets/kenney_space-kit/Isometric/terrain_sideCliff_NW.png",
	"cliff_corner_se": "res://Assets/kenney_space-kit/Isometric/terrain_sideCorner_SE.png",
	"cliff_corner_sw": "res://Assets/kenney_space-kit/Isometric/terrain_sideCorner_SW.png",
	"cliff_corner_ne": "res://Assets/kenney_space-kit/Isometric/terrain_sideCorner_NE.png",
	"cliff_corner_nw": "res://Assets/kenney_space-kit/Isometric/terrain_sideCorner_NW.png",
	"ramp_se": "res://Assets/kenney_space-kit/Isometric/terrain_rampLarge_SE.png",
	"ramp_sw": "res://Assets/kenney_space-kit/Isometric/terrain_rampLarge_SW.png",
	"ramp_ne": "res://Assets/kenney_space-kit/Isometric/terrain_rampLarge_NE.png",
	"ramp_nw": "res://Assets/kenney_space-kit/Isometric/terrain_rampLarge_NW.png",
	"slope_se": "res://Assets/kenney_space-kit/Isometric/terrain_side_SE.png",
	"slope_sw": "res://Assets/kenney_space-kit/Isometric/terrain_side_SW.png",
	"slope_ne": "res://Assets/kenney_space-kit/Isometric/terrain_side_NE.png",
	"slope_nw": "res://Assets/kenney_space-kit/Isometric/terrain_side_NW.png",
	"wall_se": "res://Assets/kenney_space-kit/Isometric/corridor_wall_SE.png",
	"wall_sw": "res://Assets/kenney_space-kit/Isometric/corridor_wall_SW.png",
	"wall_ne": "res://Assets/kenney_space-kit/Isometric/corridor_wall_NE.png",
	"wall_nw": "res://Assets/kenney_space-kit/Isometric/corridor_wall_NW.png",
	"wall_corner_se": "res://Assets/kenney_space-kit/Isometric/corridor_wallCorner_SE.png",
	"wall_corner_sw": "res://Assets/kenney_space-kit/Isometric/corridor_wallCorner_SW.png",
	"wall_corner_ne": "res://Assets/kenney_space-kit/Isometric/corridor_wallCorner_NE.png",
	"wall_corner_nw": "res://Assets/kenney_space-kit/Isometric/corridor_wallCorner_NW.png",
	"rock_small": "res://Assets/kenney_space-kit/Isometric/rock_SW.png",
	"rock_large": "res://Assets/kenney_space-kit/Isometric/rock_largeB_SW.png",
}

static var _textures_by_path: Dictionary = {}
static var _load_count_by_path: Dictionary = {}
static var _missing_paths: Dictionary = {}


static func get_common_texture(texture_key: String) -> Texture2D:
	var normalized_key: String = texture_key.strip_edges().to_lower()
	var texture_path: String = String(COMMON_TEXTURE_PATHS.get(normalized_key, "")).strip_edges()
	return get_texture(texture_path)


static func get_default_tile_texture_path() -> String:
	return DEFAULT_TILE_TEXTURE_PATH


static func get_texture(texture_path: String, fallback_path: String = DEFAULT_TILE_TEXTURE_PATH) -> Texture2D:
	var normalized_path: String = texture_path.strip_edges()
	if normalized_path.is_empty():
		normalized_path = fallback_path.strip_edges()
	if normalized_path.is_empty():
		return null
	if _textures_by_path.has(normalized_path):
		return _textures_by_path[normalized_path] as Texture2D
	if not ResourceLoader.exists(normalized_path):
		_missing_paths[normalized_path] = true
		if normalized_path != fallback_path:
			return get_texture(fallback_path, "")
		return null
	var loaded: Resource = ResourceLoader.load(normalized_path)
	if loaded is Texture2D:
		_textures_by_path[normalized_path] = loaded as Texture2D
		_load_count_by_path[normalized_path] = int(_load_count_by_path.get(normalized_path, 0)) + 1
		return loaded as Texture2D
	_missing_paths[normalized_path] = true
	if normalized_path != fallback_path:
		return get_texture(fallback_path, "")
	return null


static func is_cached(texture_path: String) -> bool:
	return _textures_by_path.has(texture_path.strip_edges())


static func get_cached_path_count() -> int:
	return _textures_by_path.size()


static func get_load_count(texture_path: String) -> int:
	return int(_load_count_by_path.get(texture_path.strip_edges(), 0))


static func get_missing_path_count() -> int:
	return _missing_paths.size()


static func reset_cache_for_tests() -> void:
	_textures_by_path.clear()
	_load_count_by_path.clear()
	_missing_paths.clear()
