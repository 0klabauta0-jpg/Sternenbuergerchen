class_name FTLRegistry
extends Node

var _ftl_by_team_id: Dictionary = {}


func register_ftl(team_id: String, ftl: Node) -> bool:
	if not _is_valid_id(team_id):
		push_warning("FTLRegistry.register_ftl expects a non-empty team_id.")
		return false

	if not _is_valid_node(ftl):
		push_warning("FTLRegistry.register_ftl expects a valid FTL Node.")
		return false

	if _ftl_by_team_id.has(team_id):
		push_warning("FTLRegistry already contains team_id '%s'." % team_id)
		return false

	_ftl_by_team_id[team_id] = ftl
	return true


func unregister_ftl(team_id: String) -> void:
	if not _is_valid_id(team_id):
		push_warning("FTLRegistry.unregister_ftl expects a non-empty team_id.")
		return

	_ftl_by_team_id.erase(team_id)


func get_ftl(team_id: String) -> Node:
	if not _is_valid_id(team_id):
		return null

	return _ftl_by_team_id.get(team_id, null)


func has_ftl(team_id: String) -> bool:
	if not _is_valid_id(team_id):
		return false

	return _ftl_by_team_id.has(team_id)


func get_all_ftls() -> Array:
	var ordered_ids: Array = _ftl_by_team_id.keys()
	ordered_ids.sort()

	var ftls: Array = []
	for team_id in ordered_ids:
		ftls.append(_ftl_by_team_id[team_id])

	return ftls


func clear() -> void:
	_ftl_by_team_id.clear()


func _is_valid_id(value: String) -> bool:
	return not value.strip_edges().is_empty()


func _is_valid_node(value: Node) -> bool:
	return value != null and is_instance_valid(value)
