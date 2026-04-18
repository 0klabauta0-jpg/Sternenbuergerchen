class_name TerrainTileCatalog
extends RefCounted

const DEFAULT_CATALOG_PATH: String = "res://data/terrain_tile_catalog.json"

var _tile_types: Dictionary = {}
var _type_order: Array[String] = []
var _type_textures: Dictionary = {}


static func load_from_file(path: String = DEFAULT_CATALOG_PATH) -> TerrainTileCatalog:
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
	var tile_types_array: Variant = root_dict.get("tile_types", [])
	if not tile_types_array is Array:
		return catalog

	for entry in tile_types_array:
		if typeof(entry) != TYPE_DICTIONARY:
			continue

		var type_id: String = String(entry.get("type_id", "")).strip_edges()
		if type_id.is_empty():
			continue

		catalog._tile_types[type_id] = {
			"type_id": type_id,
			"display_name": String(entry.get("display_name", type_id)),
			"texture_path": String(entry.get("texture_path", "")),
			"surface_type": String(entry.get("surface_type", "ground")),
			"walkable": bool(entry.get("walkable", true)),
			"blocks_los": bool(entry.get("blocks_los", false)),
			"cover_value": clampi(int(entry.get("cover_value", 0)), 0, 100),
			"height_level": clampi(int(entry.get("height_level", 0)), 0, 3),
			"object_height": clampi(int(entry.get("object_height", 0)), 0, 3),
			"edge_type": String(entry.get("edge_type", "cliff")),
		}
		catalog._type_order.append(type_id)

		var texture_path: String = String(entry.get("texture_path", ""))
		if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
			catalog._type_textures[type_id] = load(texture_path) as Texture2D

	return catalog


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


func has_type(type_id: String) -> bool:
	return _tile_types.has(type_id)


func get_texture(type_id: String) -> Texture2D:
	return _type_textures.get(type_id, null) as Texture2D


func apply_type_to_tile(tile_data, type_id: String) -> bool:
	if tile_data == null or not has_type(type_id):
		return false

	var entry: Dictionary = _tile_types[type_id]
	tile_data.type_id = type_id
	tile_data.walkable = bool(entry.get("walkable", true))
	tile_data.blocks_los = bool(entry.get("blocks_los", false))
	tile_data.cover_value = int(entry.get("cover_value", 0))
	tile_data.height_level = int(entry.get("height_level", 0))
	tile_data.object_height = int(entry.get("object_height", 0))
	tile_data.surface_type = String(entry.get("surface_type", "ground"))
	tile_data.edge_type = String(entry.get("edge_type", "cliff"))
	return true
