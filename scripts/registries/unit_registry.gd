class_name UnitRegistry
extends Node

var _units_by_id: Dictionary = {}


func register_unit(unit_id: String, unit: Node) -> bool:
	if not _is_valid_id(unit_id):
		push_warning("UnitRegistry.register_unit expects a non-empty unit_id.")
		return false

	if not _is_valid_node(unit):
		push_warning("UnitRegistry.register_unit expects a valid unit Node.")
		return false

	if _units_by_id.has(unit_id):
		push_warning("UnitRegistry already contains unit_id '%s'." % unit_id)
		return false

	_units_by_id[unit_id] = unit
	return true


func unregister_unit(unit_id: String) -> void:
	if not _is_valid_id(unit_id):
		push_warning("UnitRegistry.unregister_unit expects a non-empty unit_id.")
		return

	_units_by_id.erase(unit_id)


func get_unit(unit_id: String) -> Node:
	if not _is_valid_id(unit_id):
		return null

	return _units_by_id.get(unit_id, null)


func has_unit(unit_id: String) -> bool:
	if not _is_valid_id(unit_id):
		return false

	return _units_by_id.has(unit_id)


func get_all_units() -> Array:
	var ordered_ids: Array = _units_by_id.keys()
	ordered_ids.sort()

	var units: Array = []
	for unit_id in ordered_ids:
		units.append(_units_by_id[unit_id])

	return units


func clear() -> void:
	_units_by_id.clear()


func _is_valid_id(value: String) -> bool:
	return not value.strip_edges().is_empty()


func _is_valid_node(value: Node) -> bool:
	return value != null and is_instance_valid(value)
