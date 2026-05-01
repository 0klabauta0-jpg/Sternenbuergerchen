class_name TerrainTileCatalog
extends RefCounted

const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const DEFAULT_CATALOG_PATH: String = "res://data/terrain_tile_catalog.json"
const OBJECT_LAYER_GROUPS: PackedStringArray = [
	"deko",
	"technik",
	"gebaeude",
	"plattformen",
	"pipes",
	"rails",
	"crater",
	"fahrzeuge",
]

var _tile_types: Dictionary = {}
var _type_order: Array[String] = []
var _type_textures: Dictionary = {}
var _palette_groups: Array[Dictionary] = []


static func load_from_file(path: String = DEFAULT_CATALOG_PATH, load_textures: bool = true) -> TerrainTileCatalog:
	var catalog := TerrainTileCatalog.new()
	if path.is_empty() or not FileAccess.file_exists(path):
		push_warning("TerrainTileCatalog file not found: %s" % path)
		return catalog

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("TerrainTileCatalog could not open: %s" % path)
		return catalog

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("TerrainTileCatalog expected a Dictionary root in: %s" % path)
		return catalog

	var root_dict: Dictionary = parsed
	var palette_groups_array: Variant = root_dict.get("palette_groups", [])
	if palette_groups_array is Array:
		for group_entry in palette_groups_array:
			if typeof(group_entry) != TYPE_DICTIONARY:
				continue
			var group_id: String = _normalize_palette_group_id(String(group_entry.get("group_id", "")))
			if group_id.is_empty():
				continue
			catalog._append_palette_group_if_missing(
				group_id,
				String(group_entry.get("display_name", _build_default_palette_group_label(group_id))),
				bool(group_entry.get("collapsed", false))
			)

	var tile_types_array: Variant = root_dict.get("tile_types", [])
	if not tile_types_array is Array:
		return catalog

	for entry in tile_types_array:
		if typeof(entry) != TYPE_DICTIONARY:
			continue

		var type_id: String = String(entry.get("type_id", "")).strip_edges()
		if type_id.is_empty():
			continue

		var palette_group: String = _normalize_palette_group_id(String(entry.get("palette_group", "default")))
		if palette_group.is_empty():
			palette_group = "default"
		catalog._append_palette_group_if_missing(palette_group)
		var walkable: bool = bool(entry.get("walkable", true))
		var blocks_los: bool = bool(entry.get("blocks_los", false))
		var cover_value: int = clampi(int(entry.get("cover_value", 0)), 0, 100)
		var height_level: int = clampi(int(entry.get("height_level", 0)), 0, TERRAIN_TILE_DATA_SCRIPT.MAX_HEIGHT_LEVEL)
		var object_height: int = clampi(int(entry.get("object_height", 0)), 0, TERRAIN_TILE_DATA_SCRIPT.MAX_OBJECT_HEIGHT)
		var floor_height: float = _coerce_height_float(entry.get("floor_height", float(height_level)))
		var cover_height: float = _coerce_height_float(entry.get("cover_height", _derive_cover_height(cover_value, object_height)))
		var blocks_los_height: float = _coerce_height_float(entry.get("blocks_los_height", _derive_blocks_los_height(blocks_los, height_level, object_height, cover_height)))
		var is_elevated_surface: bool = bool(entry.get("is_elevated_surface", floor_height > 0.0 or height_level > 0))
		var edge_type: String = String(entry.get("edge_type", "cliff"))
		var height_transition_type: String = TERRAIN_TILE_DATA_SCRIPT.normalize_height_transition_type(String(entry.get("height_transition_type", "")), edge_type)

		catalog._tile_types[type_id] = {
			"type_id": type_id,
			"display_name": String(entry.get("display_name", type_id)),
			"palette_group": palette_group,
			"placement_layer": String(entry.get("placement_layer", "object" if OBJECT_LAYER_GROUPS.has(palette_group) else "terrain")),
			"texture_path": String(entry.get("texture_path", "")),
			"surface_type": String(entry.get("surface_type", "ground")),
			"walkable": walkable,
			"blocks_los": blocks_los,
			"cover_value": cover_value,
			"height_level": height_level,
			"object_height": object_height,
			"floor_height": floor_height,
			"unit_eye_height_bonus": _coerce_height_float(entry.get("unit_eye_height_bonus", TERRAIN_TILE_DATA_SCRIPT.DEFAULT_UNIT_EYE_HEIGHT_BONUS)),
			"cover_height": cover_height,
			"blocks_los_height": blocks_los_height,
			"is_elevated_surface": is_elevated_surface,
			"edge_type": edge_type,
			"height_transition_type": height_transition_type,
		}
		catalog._type_order.append(type_id)

		var texture_path: String = String(entry.get("texture_path", ""))
		if load_textures and not texture_path.is_empty() and ResourceLoader.exists(texture_path):
			catalog._type_textures[type_id] = load(texture_path) as Texture2D

	return catalog


static func load_type_metadata_from_file(path: String = DEFAULT_CATALOG_PATH) -> TerrainTileCatalog:
	return load_from_file(path, false)


static func _normalize_palette_group_id(value: String) -> String:
	return value.strip_edges().to_lower()


static func _build_default_palette_group_label(group_id: String) -> String:
	if group_id.is_empty():
		return "Weitere"
	return group_id.capitalize()


static func _derive_cover_height(cover_value: int, object_height: int) -> float:
	if cover_value <= 0:
		return TERRAIN_TILE_DATA_SCRIPT.DEFAULT_COVER_HEIGHT
	return maxf(float(object_height), 0.5)


static func _derive_blocks_los_height(blocks_los: bool, height_level: int, object_height: int, cover_height: float) -> float:
	if not blocks_los:
		return TERRAIN_TILE_DATA_SCRIPT.DEFAULT_BLOCKS_LOS_HEIGHT
	return maxf(maxf(float(height_level), float(object_height)), cover_height)


static func _coerce_height_float(value: Variant) -> float:
	if value == null:
		return 0.0
	return clampf(float(value), 0.0, TERRAIN_TILE_DATA_SCRIPT.MAX_WORLD_HEIGHT)


func _append_palette_group_if_missing(group_id: String, display_name: String = "", collapsed: bool = false) -> void:
	for existing_group in _palette_groups:
		if String(existing_group.get("group_id", "")) == group_id:
			return
	_palette_groups.append({
		"group_id": group_id,
		"display_name": display_name if not display_name.is_empty() else _build_default_palette_group_label(group_id),
		"collapsed": collapsed,
	})


func get_type_ids() -> Array[String]:
	return _type_order.duplicate()


func get_type(type_id: String) -> Dictionary:
	return _tile_types.get(type_id, {})


func get_display_name(type_id: String) -> String:
	var entry: Dictionary = _tile_types.get(type_id, {})
	return String(entry.get("display_name", type_id))


func get_all_types() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for type_id in _type_order:
		result.append(_tile_types[type_id])

	return result


func get_palette_groups() -> Array[Dictionary]:
	return _palette_groups.duplicate(true)


func has_type(type_id: String) -> bool:
	return _tile_types.has(type_id)


func get_texture(type_id: String) -> Texture2D:
	return _type_textures.get(type_id, null) as Texture2D


func is_object_layer_type(type_id: String) -> bool:
	var entry: Dictionary = _tile_types.get(type_id, {})
	return String(entry.get("placement_layer", "terrain")).strip_edges().to_lower() == "object"


func apply_type_to_tile(tile_data, type_id: String) -> bool:
	if tile_data == null or not has_type(type_id):
		return false

	var entry: Dictionary = _tile_types[type_id]
	if is_object_layer_type(type_id):
		tile_data.object_type_id = type_id
		tile_data.walkable = bool(entry.get("walkable", true))
		tile_data.blocks_los = bool(entry.get("blocks_los", false))
		tile_data.cover_value = int(entry.get("cover_value", 0))
		tile_data.object_height = int(entry.get("object_height", 0))
		tile_data.unit_eye_height_bonus = float(entry.get("unit_eye_height_bonus", TERRAIN_TILE_DATA_SCRIPT.DEFAULT_UNIT_EYE_HEIGHT_BONUS))
		tile_data.cover_height = _offset_object_height_for_floor(tile_data, float(entry.get("cover_height", TERRAIN_TILE_DATA_SCRIPT.DEFAULT_COVER_HEIGHT)))
		tile_data.blocks_los_height = _offset_object_height_for_floor(tile_data, float(entry.get("blocks_los_height", TERRAIN_TILE_DATA_SCRIPT.DEFAULT_BLOCKS_LOS_HEIGHT)))
		return true

	tile_data.type_id = type_id
	tile_data.object_type_id = ""
	tile_data.walkable = bool(entry.get("walkable", true))
	tile_data.blocks_los = bool(entry.get("blocks_los", false))
	tile_data.cover_value = int(entry.get("cover_value", 0))
	tile_data.height_level = int(entry.get("height_level", 0))
	tile_data.object_height = int(entry.get("object_height", 0))
	tile_data.floor_height = float(entry.get("floor_height", TERRAIN_TILE_DATA_SCRIPT.DEFAULT_FLOOR_HEIGHT))
	tile_data.unit_eye_height_bonus = float(entry.get("unit_eye_height_bonus", TERRAIN_TILE_DATA_SCRIPT.DEFAULT_UNIT_EYE_HEIGHT_BONUS))
	tile_data.cover_height = float(entry.get("cover_height", TERRAIN_TILE_DATA_SCRIPT.DEFAULT_COVER_HEIGHT))
	tile_data.blocks_los_height = float(entry.get("blocks_los_height", TERRAIN_TILE_DATA_SCRIPT.DEFAULT_BLOCKS_LOS_HEIGHT))
	tile_data.is_elevated_surface = bool(entry.get("is_elevated_surface", TERRAIN_TILE_DATA_SCRIPT.DEFAULT_IS_ELEVATED_SURFACE))
	tile_data.surface_type = String(entry.get("surface_type", "ground"))
	tile_data.edge_type = String(entry.get("edge_type", "cliff"))
	tile_data.height_transition_type = String(entry.get("height_transition_type", TERRAIN_TILE_DATA_SCRIPT.DEFAULT_HEIGHT_TRANSITION_TYPE))
	return true


func _offset_object_height_for_floor(tile_data, object_relative_height: float) -> float:
	if object_relative_height <= 0.0:
		return 0.0
	return float(tile_data.floor_height) + object_relative_height
