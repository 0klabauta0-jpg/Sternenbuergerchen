class_name FTLRegistry
extends Node

var _ftl_by_team_id: Dictionary = {}


func register_ftl(team_id: String, ftl: Node) -> bool:
	if team_id.is_empty():
		push_warning("FTLRegistry.register_ftl expects a non-empty team_id.")
		return false

	if ftl == null:
		push_warning("FTLRegistry.register_ftl expects an FTL Node.")
		return false

	if _ftl_by_team_id.has(team_id):
		push_warning("FTLRegistry.register_ftl does not overwrite an existing team_id.")
		return false

	_ftl_by_team_id[team_id] = ftl
	return true


func unregister_ftl(team_id: String) -> void:
	if team_id.is_empty():
		push_warning("FTLRegistry.unregister_ftl expects a non-empty team_id.")
		return

	_ftl_by_team_id.erase(team_id)


func get_ftl(team_id: String) -> Node:
	if team_id.is_empty():
		return null

	return _ftl_by_team_id.get(team_id, null)


func has_ftl(team_id: String) -> bool:
	if team_id.is_empty():
		return false

	return _ftl_by_team_id.has(team_id)


func get_all_ftls() -> Array:
	return _ftl_by_team_id.values()


func clear() -> void:
	_ftl_by_team_id.clear()
