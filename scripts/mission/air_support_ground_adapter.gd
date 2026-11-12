extends RefCounted
## Bounded reads from the existing terrain and unit registries. No new owner.
const MAX_LEGACY_UNITS := 256

static func registry(hex_active: bool, hex_registry: Node, legacy_registry: Node) -> Node:
	var value: Node = hex_registry if hex_active else legacy_registry
	if not is_instance_valid(value) or not value.has_method("get_grid_topology") or value.call("get_grid_topology") != "hex_axial_v1": return null
	return value

static func unit_grid(unit: Node, terrain: Node) -> Variant:
	if not is_instance_valid(unit) or not unit is Node2D or not is_instance_valid(terrain) or bool(unit.get_meta("dropship_embarked", false)): return null
	if not (unit as Node2D).global_position.is_finite(): return null
	var grid: Vector2i = terrain.call("world_to_grid", (unit as Node2D).global_position)
	return grid if terrain.call("get_tile_at_grid", grid) != null else null

static func occupant(grid: Vector2i, terrain: Node, unit_registry: Node) -> Dictionary:
	if not is_instance_valid(terrain) or not is_instance_valid(unit_registry) or not unit_registry.has_method("get_all_units"): return {"ok":false, "reason":"ground_registry_unavailable"}
	var units: Array = unit_registry.call("get_all_units")
	if units.size() > MAX_LEGACY_UNITS: return {"ok":false, "reason":"ground_query_capacity"}
	var ids: Array[String] = []
	for unit in units:
		if not is_instance_valid(unit) or not unit.has_method("get_unit_id") or not unit.has_method("apply_damage"): continue
		if unit_grid(unit, terrain) == grid:
			var id := String(unit.call("get_unit_id"))
			if not id.is_empty(): ids.append(id)
	ids.sort()
	return {"ok":true, "unit_id":"" if ids.is_empty() else ids[0]}
