class_name MapLoader
extends RefCounted

const MAP_DEFINITION_SCRIPT: GDScript = preload("res://scripts/maps/map_definition.gd")


static func instantiate_map(map_scene: PackedScene) -> Node:
	if map_scene == null:
		return null

	return map_scene.instantiate()


static func get_map_definition(map_root: Node, fallback_definition: Resource = null) -> Resource:
	if map_root != null and map_root.has_method("get_map_definition"):
		var map_definition = map_root.call("get_map_definition")
		if map_definition is Resource and map_definition.get_script() == MAP_DEFINITION_SCRIPT:
			return map_definition

	if fallback_definition is Resource and fallback_definition.get_script() == MAP_DEFINITION_SCRIPT:
		return fallback_definition

	return null
