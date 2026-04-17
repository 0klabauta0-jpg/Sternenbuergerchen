class_name TerrainRegistry
extends RefCounted

const TERRAIN_DEFINITION_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_definition.gd")
const REFERENCE_TERRAIN_SW_ASSET_PATH: String = "res://Assets/kenney_space-kit/Isometric/terrain_SW.png"
const V0_DEFINITIONS: Array[Dictionary] = [
	{
		"terrain_id": "flat_ground_sw",
		"source_asset_path": REFERENCE_TERRAIN_SW_ASSET_PATH,
		"orientation": "SW",
		"walkable": true,
		"blocks_los": false,
		"cover_value": 0.0,
		"speed_multiplier": 1.0,
	},
	{
		"terrain_id": "flat_ground_se",
		"source_asset_path": "res://Assets/kenney_space-kit/Isometric/terrain_SE.png",
		"orientation": "SE",
		"walkable": true,
		"blocks_los": false,
		"cover_value": 0.0,
		"speed_multiplier": 1.0,
	},
	{
		"terrain_id": "flat_ground_ne",
		"source_asset_path": "res://Assets/kenney_space-kit/Isometric/terrain_NE.png",
		"orientation": "NE",
		"walkable": true,
		"blocks_los": false,
		"cover_value": 0.0,
		"speed_multiplier": 1.0,
	},
	{
		"terrain_id": "flat_ground_nw",
		"source_asset_path": "res://Assets/kenney_space-kit/Isometric/terrain_NW.png",
		"orientation": "NW",
		"walkable": true,
		"blocks_los": false,
		"cover_value": 0.0,
		"speed_multiplier": 1.0,
	},
]

var _terrain_by_id: Dictionary = {}
var _terrain_id_by_asset_path: Dictionary = {}


static func create_with_v0_defaults():
	var script_ref: GDScript = load("res://scripts/terrain/terrain_registry.gd")
	var registry = script_ref.new()
	registry.load_v0_definitions()
	return registry


func register_definition(definition) -> bool:
	if not _is_valid_definition(definition):
		push_warning("TerrainRegistry.register_definition expects a valid TerrainDefinition-like object.")
		return false

	var terrain_id: String = String(definition.get("terrain_id"))
	var source_asset_path: String = String(definition.get("source_asset_path"))
	if _terrain_by_id.has(terrain_id):
		push_warning("TerrainRegistry.register_definition does not overwrite an existing terrain_id.")
		return false

	if _terrain_id_by_asset_path.has(source_asset_path):
		push_warning("TerrainRegistry.register_definition does not overwrite an existing source_asset_path.")
		return false

	_terrain_by_id[terrain_id] = definition
	_terrain_id_by_asset_path[source_asset_path] = terrain_id
	return true


func unregister_definition(terrain_id: String) -> void:
	if terrain_id.is_empty():
		return

	var definition = _terrain_by_id.get(terrain_id, null)
	if definition != null:
		_terrain_id_by_asset_path.erase(String(definition.get("source_asset_path")))

	_terrain_by_id.erase(terrain_id)


func get_definition(terrain_id: String):
	if terrain_id.is_empty():
		return null

	return _terrain_by_id.get(terrain_id, null)


func get_definition_by_source_asset_path(source_asset_path: String):
	if source_asset_path.is_empty():
		return null

	var terrain_id: String = String(_terrain_id_by_asset_path.get(source_asset_path, ""))
	if terrain_id.is_empty():
		return null

	return get_definition(terrain_id)


func has_definition(terrain_id: String) -> bool:
	if terrain_id.is_empty():
		return false

	return _terrain_by_id.has(terrain_id)


func has_source_asset_path(source_asset_path: String) -> bool:
	if source_asset_path.is_empty():
		return false

	return _terrain_id_by_asset_path.has(source_asset_path)


func get_all_definitions() -> Array:
	return _terrain_by_id.values()


func clear() -> void:
	_terrain_by_id.clear()
	_terrain_id_by_asset_path.clear()


func load_v0_definitions() -> int:
	clear()

	var registered_count: int = 0
	for definition_data in V0_DEFINITIONS:
		var definition = TERRAIN_DEFINITION_SCRIPT.new(definition_data)
		if register_definition(definition):
			registered_count += 1

	return registered_count


func _is_valid_definition(definition) -> bool:
	return definition != null and definition.has_method("is_valid") and bool(definition.call("is_valid"))
