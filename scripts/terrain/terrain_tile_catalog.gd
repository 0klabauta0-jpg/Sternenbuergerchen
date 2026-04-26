class_name TerrainTileCatalog
extends RefCounted

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

		catalog._tile_types[type_id] = {
			"type_id": type_id,
			"display_name": String(entry.get("display_name", type_id)),
			"palette_group": palette_group,
			"placement_layer": String(entry.get("placement_layer", "object" if OBJECT_LAYER_GROUPS.has(palette_group) else "terrain")),
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


static func _normalize_palette_group_id(value: String) -> String:
	return value.strip_edges().to_lower()


static func _build_default_palette_group_label(group_id: String) -> String:
	if group_id.is_empty():
		return "Weitere"
	return group_id.capitalize()


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
		return true

	tile_data.type_id = type_id
	tile_data.object_type_id = ""
	tile_data.walkable = bool(entry.get("walkable", true))
	tile_data.blocks_los = bool(entry.get("blocks_los", false))
	tile_data.cover_value = int(entry.get("cover_value", 0))
	tile_data.height_level = int(entry.get("height_level", 0))
	tile_data.object_height = int(entry.get("object_height", 0))
	tile_data.surface_type = String(entry.get("surface_type", "ground"))
	tile_data.edge_type = String(entry.get("edge_type", "cliff"))
	return true
