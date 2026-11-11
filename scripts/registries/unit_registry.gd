class_name UnitRegistry
extends Node

var _units_by_id: Dictionary = {}


func register_unit(unit_id: String, unit: Node) -> bool:
	if unit_id.is_empty():
		push_warning("UnitRegistry.register_unit expects a non-empty unit_id.")
		return false

	if unit == null:
		push_warning("UnitRegistry.register_unit expects a unit Node.")
		return false

	if _units_by_id.has(unit_id):
		push_warning("UnitRegistry.register_unit does not overwrite an existing unit_id.")
		return false

	_units_by_id[unit_id] = unit
	return true


func unregister_unit(unit_id: String) -> void:
	if unit_id.is_empty():
		push_warning("UnitRegistry.unregister_unit expects a non-empty unit_id.")
		return

	_units_by_id.erase(unit_id)


func get_unit(unit_id: String) -> Node:
	if unit_id.is_empty():
		return null

	var unit:Variant=_units_by_id.get(unit_id,null)
	return unit if is_instance_valid(unit) else null


func has_unit(unit_id: String) -> bool:
	if unit_id.is_empty():
		return false

	return _units_by_id.has(unit_id)


func get_all_units() -> Array:
	return _units_by_id.values()


func clear() -> void:
	_units_by_id.clear()
