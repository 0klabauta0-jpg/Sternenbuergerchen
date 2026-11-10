class_name TerrainTileCatalog
extends RefCounted

const DEFAULT_CATALOG_PATH: String = "res://data/terrain_tile_catalog.json"
const TERRAIN_TEXTURE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_texture_catalog.gd")
const OBJECT_LAYER_GROUPS: PackedStringArray = [
	"nature_props",
	"deko",
	"technik_deko",
	"technik",
	"gebaeude",
	"space_station",
	"plattformen",
	"pipes",
	"rails",
	"crater",
	"fahrzeuge",
	"space_kit_full",
	"space_station_full",
	"modular_space",
	"factory",
]
const IMPORTED_KIT_GROUPS: PackedStringArray = [
	"space_kit_full",
	"space_station_full",
	"modular_space",
	"factory",
]
const STRUCTURE_LAYER_NAMES: PackedStringArray = [
	"structure",
	"terrain_object",
]
const HILL_PRESERVING_TYPE_PREFIXES: PackedStringArray = [
	"wall_",
	"rock_",
	"cliff_",
	"slope_",
]
const SURFACE_BRUSH_TYPE_IDS: PackedStringArray = [
	"ground_flat",
]

var _tile_types: Dictionary = {}
var _type_order: Array[String] = []
var _texture_paths_by_type: Dictionary = {}
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

		var palette_group: String = _resolve_palette_group_for_entry(entry)
		if palette_group.is_empty():
			palette_group = "default"
		catalog._append_palette_group_if_missing(palette_group)

		catalog._tile_types[type_id] = {
			"type_id": type_id,
			"palette_visible": bool(entry.get("palette_visible", true)),
			"display_name": String(entry.get("display_name", type_id)),
			"palette_group": palette_group,
			"placement_layer": String(entry.get("placement_layer", "object" if OBJECT_LAYER_GROUPS.has(palette_group) else "terrain")).strip_edges().to_lower(),
			"texture_path": String(entry.get("texture_path", "")),
			"surface_type": String(entry.get("surface_type", "ground")),
			"walkable": bool(entry.get("walkable", true)),
			"blocks_los": bool(entry.get("blocks_los", false)),
			"cover_value": clampi(int(entry.get("cover_value", 0)), 0, 100),
			"height_level": clampi(int(entry.get("height_level", 0)), 0, 2),
			"object_height": clampi(int(entry.get("object_height", 0)), 0, 3),
			"edge_type": String(entry.get("edge_type", "cliff")),
			"preserve_hill_fields": bool(entry.get("preserve_hill_fields", false)),
			"visual_surface_variant": bool(entry.get("visual_surface_variant", false)),
			"prop_role": String(entry.get("prop_role", "")),
		}
		catalog._type_order.append(type_id)

		var texture_path: String = String(entry.get("texture_path", "")).strip_edges()
		if not texture_path.is_empty():
			catalog._texture_paths_by_type[type_id] = texture_path

	return catalog


static func _normalize_palette_group_id(value: String) -> String:
	return value.strip_edges().to_lower()


static func _build_default_palette_group_label(group_id: String) -> String:
	if group_id.is_empty():
		return "Weitere"
	return group_id.capitalize()


static func _resolve_palette_group_for_entry(entry: Dictionary) -> String:
	var raw_group: String = _normalize_palette_group_id(String(entry.get("palette_group", "default")))
	if not IMPORTED_KIT_GROUPS.has(raw_group):
		return raw_group
	var type_id: String = String(entry.get("type_id", "")).strip_edges().to_lower()
	var display_name: String = String(entry.get("display_name", "")).strip_edges().to_lower()
	var searchable: String = "%s %s" % [type_id, display_name]
	if searchable.contains("crater"):
		return "crater"
	if searchable.contains("meteor") or searchable.contains("asteroid") or searchable.contains("rock"):
		return "felsen"
	if searchable.contains("cliff") or searchable.contains("sidecliff"):
		return "cliffs"
	if searchable.contains("ramp") or searchable.contains("slope"):
		return "rampen"
	if searchable.contains("terrain") or searchable.contains("ground"):
		return "terrain"
	if searchable.contains("wall") or searchable.contains("door") or searchable.contains("gate"):
		return "waende"
	if searchable.contains("pipe"):
		return "pipes"
	if searchable.contains("rail") or searchable.contains("monorail"):
		return "rails"
	if searchable.contains("craft") or searchable.contains("vehicle") or searchable.contains("rover") or searchable.contains("speeder"):
		return "fahrzeuge"
	if raw_group == "factory" and searchable.contains("floor"):
		return "plattformen"
	if searchable.contains("floor") or searchable.contains("corridor") or searchable.contains("room"):
		return "space_station"
	if searchable.contains("platform") or searchable.contains("catwalk") or searchable.contains("conveyor"):
		return "plattformen"
	if searchable.contains("computer") or searchable.contains("console") or searchable.contains("display") or searchable.contains("generator") or searchable.contains("chimney") or searchable.contains("crane") or searchable.contains("tank"):
		return "technik"
	if searchable.contains("structure"):
		return "space_station" # Modular kit parts are not complete current buildings.
	if searchable.contains("building") or searchable.contains("hangar"):
		return "gebaeude"
	if searchable.contains("barrel") or searchable.contains("box") or searchable.contains("crate") or searchable.contains("container") or searchable.contains("bed") or searchable.contains("chair") or searchable.contains("table") or searchable.contains("banner"):
		return "deko"
	return "deko"


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
	var texture_path: String = get_texture_path(type_id)
	if texture_path.is_empty():
		return null
	return TERRAIN_TEXTURE_CATALOG_SCRIPT.call("get_texture", texture_path) as Texture2D


func get_texture_path(type_id: String) -> String:
	var normalized_type_id: String = type_id.strip_edges().to_lower()
	return String(_texture_paths_by_type.get(normalized_type_id, "")).strip_edges()


func is_texture_cached(type_id: String) -> bool:
	var texture_path: String = get_texture_path(type_id)
	if texture_path.is_empty():
		return false
	return bool(TERRAIN_TEXTURE_CATALOG_SCRIPT.call("is_cached", texture_path))


func is_object_layer_type(type_id: String) -> bool:
	var entry: Dictionary = _tile_types.get(type_id, {})
	return String(entry.get("placement_layer", "terrain")).strip_edges().to_lower() == "object"


func is_structure_layer_type(type_id: String) -> bool:
	var normalized_type_id: String = type_id.strip_edges().to_lower()
	if normalized_type_id.is_empty():
		return false
	var entry: Dictionary = _tile_types.get(normalized_type_id, {})
	var placement_layer: String = String(entry.get("placement_layer", "terrain")).strip_edges().to_lower()
	if STRUCTURE_LAYER_NAMES.has(placement_layer):
		return true
	for prefix in HILL_PRESERVING_TYPE_PREFIXES:
		if normalized_type_id.begins_with(prefix):
			return true
	return false


func preserves_hill_fields_when_applied(type_id: String) -> bool:
	var normalized_type_id: String = type_id.strip_edges().to_lower()
	if normalized_type_id.is_empty():
		return false
	if SURFACE_BRUSH_TYPE_IDS.has(normalized_type_id):
		return true
	var entry: Dictionary = _tile_types.get(normalized_type_id, {})
	if bool(entry.get("preserve_hill_fields", false)) or bool(entry.get("visual_surface_variant", false)):
		return true
	if is_structure_layer_type(normalized_type_id):
		return true
	if is_object_layer_type(normalized_type_id):
		return true
	for prefix in HILL_PRESERVING_TYPE_PREFIXES:
		if normalized_type_id.begins_with(prefix):
			return true
	return false


func apply_type_to_tile(tile_data, type_id: String) -> bool:
	if tile_data == null or not has_type(type_id):
		return false

	var entry: Dictionary = _tile_types[type_id]
	if SURFACE_BRUSH_TYPE_IDS.has(type_id):
		_apply_surface_brush_to_tile(tile_data, type_id, entry)
		return true

	if bool(entry.get("visual_surface_variant", false)):
		_apply_surface_brush_to_tile(tile_data, type_id, entry)
		return true

	if is_object_layer_type(type_id):
		_apply_object_layer_to_tile(tile_data, type_id)
		return true

	if is_structure_layer_type(type_id):
		_apply_structure_layer_to_tile(tile_data, type_id)
		return true

	if preserves_hill_fields_when_applied(type_id):
		tile_data.type_id = type_id
		tile_data.object_type_id = ""
		_apply_combined_gameplay_fields(tile_data)
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


func _apply_surface_brush_to_tile(tile_data, type_id: String, entry: Dictionary) -> void:
	tile_data.surface_type = String(entry.get("surface_type", tile_data.surface_type))
	var current_type_id: String = String(tile_data.type_id).strip_edges().to_lower() if tile_data.type_id is String else ""
	if _is_legacy_object_type_id(current_type_id):
		return
	tile_data.type_id = type_id


func _apply_object_layer_to_tile(tile_data, type_id: String) -> void:
	tile_data.object_type_id = type_id
	_apply_combined_gameplay_fields(tile_data)


func _apply_structure_layer_to_tile(tile_data, type_id: String) -> void:
	tile_data.type_id = type_id
	_apply_combined_gameplay_fields(tile_data)


func apply_base_gameplay_fields_to_tile(tile_data) -> void:
	if tile_data == null:
		return
	_apply_combined_gameplay_fields(tile_data)


func _apply_combined_gameplay_fields(tile_data) -> void:
	if tile_data == null:
		return
	var base_entry: Dictionary = _get_gameplay_entry_for_type(String(tile_data.type_id) if tile_data.type_id is String else "")
	var object_entry: Dictionary = _get_gameplay_entry_for_type(String(tile_data.object_type_id) if tile_data.object_type_id is String else "")
	var has_object_entry: bool = not object_entry.is_empty()
	var object_walkable: bool = bool(object_entry.get("walkable", true)) if has_object_entry else true
	var object_blocks_los: bool = bool(object_entry.get("blocks_los", false)) if has_object_entry else false
	var object_cover_value: int = int(object_entry.get("cover_value", 0)) if has_object_entry else 0
	var object_height: int = int(object_entry.get("object_height", 0)) if has_object_entry else 0
	tile_data.walkable = bool(base_entry.get("walkable", true)) and object_walkable
	tile_data.blocks_los = bool(base_entry.get("blocks_los", false)) or object_blocks_los
	tile_data.cover_value = maxi(int(base_entry.get("cover_value", 0)), object_cover_value)
	tile_data.object_height = maxi(int(base_entry.get("object_height", 0)), object_height)


func _get_gameplay_entry_for_type(type_id: String) -> Dictionary:
	var normalized_type_id: String = type_id.strip_edges().to_lower()
	if normalized_type_id.is_empty():
		return {}
	return Dictionary(_tile_types.get(normalized_type_id, {}))


func _is_legacy_object_type_id(type_id: String) -> bool:
	var normalized_type_id: String = type_id.strip_edges().to_lower()
	if normalized_type_id.is_empty():
		return false
	if is_structure_layer_type(normalized_type_id):
		return true
	for prefix in HILL_PRESERVING_TYPE_PREFIXES:
		if normalized_type_id.begins_with(prefix):
			return true
	return false
