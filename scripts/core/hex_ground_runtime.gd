class_name HexGroundRuntime
extends RefCounted

## SimulationRoot-owned logical ground state. Registries and views only read it.
## No unit transforms, commands or terrain data are mutated by this helper.
const TOPOLOGY := "hex_axial_v1"

var _registry: Node
var _map_id := ""
var _tick := 0
var _revision := 0
var _units_by_id: Dictionary = {}
var _occupant_by_grid: Dictionary = {}


func configure(registry: Node, map_id: String, tick: int) -> void:
	clear()
	if not is_instance_valid(registry) or map_id.strip_edges().is_empty() or tick < 0:
		return
	if not registry.has_method("get_grid_topology") or String(registry.call("get_grid_topology")) != TOPOLOGY:
		return
	if not registry.has_method("is_walkable") or not registry.has_method("get_stand_height_at"):
		return
	_registry = registry
	_map_id = map_id
	_tick = tick


func admit_units(placements: Array[Dictionary]) -> Dictionary:
	if not _is_configured():
		return _reject("not_configured")
	var staged_units: Dictionary = {}
	var staged_cells: Dictionary = {}
	for placement in placements:
		var raw_id: Variant = placement.get("unit_id", null)
		if typeof(raw_id) != TYPE_STRING or String(raw_id).is_empty() or String(raw_id) != String(raw_id).strip_edges():
			return _reject("invalid_unit_id")
		var unit_id: String = raw_id
		if _units_by_id.has(unit_id) or staged_units.has(unit_id):
			return _reject("unit_already_admitted", unit_id)
		var grid: Variant = placement.get("grid", null)
		if typeof(grid) != TYPE_VECTOR2I:
			return _reject("invalid_grid", unit_id)
		var facing: Variant = placement.get("facing_dir", 0)
		if typeof(facing) != TYPE_INT or int(facing) < 0 or int(facing) > 5:
			return _reject("invalid_facing", unit_id)
		var posture: Variant = placement.get("posture_key", "standing")
		if typeof(posture) != TYPE_STRING or String(posture).strip_edges().is_empty():
			return _reject("invalid_posture", unit_id)
		if _occupant_by_grid.has(grid) or staged_cells.has(grid):
			return _reject("cell_occupied", unit_id)
		if not bool(_registry.call("is_walkable", grid)):
			return _reject("cell_unwalkable", unit_id)
		var stand_height: float = float(_registry.call("get_stand_height_at", grid))
		if not is_finite(stand_height):
			return _reject("invalid_stand_height", unit_id)
		staged_units[unit_id] = {
			"unit_id": unit_id, "grid": grid, "facing_dir": int(facing),
			"posture_key": String(posture), "state_revision": _revision + 1,
			"movement_state": {"moving": false},
		}
		staged_cells[grid] = unit_id
	if not staged_units.is_empty():
		_units_by_id.merge(staged_units)
		_occupant_by_grid.merge(staged_cells)
		_revision += 1
	return {"ok": true, "admitted_unit_ids": staged_units.keys()}


func read_unit(unit_id: String) -> Dictionary:
	if not _is_configured() or not _units_by_id.has(unit_id):
		return {}
	var result: Dictionary = Dictionary(_units_by_id[unit_id]).duplicate(true)
	# Read current terrain revision/height without turning a getter into a mutation.
	result["stand_height_steps2"] = roundi(2.0 * float(_registry.call("get_stand_height_at", result["grid"])))
	result["terrain_revision"] = _terrain_revision()
	return result


func build_planning_snapshot() -> Dictionary:
	var units: Dictionary = {}
	for unit_id in _units_by_id:
		units[unit_id] = read_unit(String(unit_id))
	return {
		"map_id": _map_id, "revision": _revision, "current_tick": _tick,
		"terrain_revision": _terrain_revision(), "units_by_id": units,
		"occupant_by_grid": _occupant_by_grid.duplicate(true),
	}


func release_unit(unit_id: String, _reason: String) -> void:
	if not _units_by_id.has(unit_id):
		return
	var grid: Vector2i = _units_by_id[unit_id]["grid"]
	_occupant_by_grid.erase(grid)
	_units_by_id.erase(unit_id)
	_revision += 1


## Only the owning SimulationRoot commits accepted runtime intents here.
func commit_facing(unit_id: String, direction: int) -> bool:
	if not _is_configured() or not _units_by_id.has(unit_id) or direction < 0 or direction > 5:
		return false
	if int(_units_by_id[unit_id]["facing_dir"]) == direction:
		return true
	_revision += 1
	_units_by_id[unit_id]["facing_dir"] = direction
	_units_by_id[unit_id]["state_revision"] = _revision
	return true


func clear() -> void:
	_registry = null
	_map_id = ""
	_tick = 0
	_units_by_id.clear()
	_occupant_by_grid.clear()
	_revision += 1


func _is_configured() -> bool:
	return is_instance_valid(_registry) and not _map_id.is_empty()


func _terrain_revision() -> int:
	if is_instance_valid(_registry) and _registry.has_method("get_revision"):
		return int(_registry.call("get_revision"))
	return -1


func _reject(reason: String, unit_id: String = "") -> Dictionary:
	return {"ok": false, "reason": reason, "unit_id": unit_id}
