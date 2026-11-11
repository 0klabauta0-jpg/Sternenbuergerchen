class_name HexSightRuntimeAdapter
extends RefCounted

## Read-only bridge. It stores dependencies, never an alternate unit state.
const QUERY = preload("res://scripts/core/hex_visibility_query.gd")
var _owner: Node
var _cache: Object
var _arc_degrees := 120.0

func configure(owner: Node, cache: Object, arc_degrees: float = 120.0) -> void:
	_owner = owner
	_cache = cache
	_arc_degrees = arc_degrees

func is_active() -> bool:
	return is_instance_valid(_owner) and _owner.has_method("is_hex_ground_runtime_active") and bool(_owner.call("is_hex_ground_runtime_active"))

func get_visibility_cache() -> Object:
	return _cache if is_instance_valid(_cache) else null

func get_context_key() -> String:
	if not is_active() or not is_instance_valid(_registry()):
		return ""
	return "%d:%d:%d" % [_owner.get_instance_id(),_owner.call("get_hex_ground_context_revision"),_registry().get_instance_id()]

func build_observer_signature(unit, range_world: float, include_position: bool = true) -> String:
	var state := build_observer_state(unit,range_world)
	var logical: Dictionary = state.get("hex_state",{})
	var signature := {"context":get_context_key(),"profile":state.get("hex_profile",{}),
		"facing":logical.get("facing_dir",-1)}
	if include_position:
		signature["grid"] = logical.get("grid")
		signature["height"] = logical.get("stand_height_steps2")
	return JSON.stringify(signature)

func query_units(observer, target, range_world: float) -> Dictionary:
	if not is_active():
		return {"handled":false,"visible":false}
	var source := build_observer_state(observer, range_world)
	var destination := build_observer_state(target, -1.0)
	if source.is_empty() or destination.is_empty():
		return {"handled":true,"visible":false,"reason":"missing_logical_state"}
	var result := query_snapshot(source, destination["hex_state"], _registry(), _cache)
	result["handled"] = true
	return result

func build_observer_state(unit, range_world: float) -> Dictionary:
	if not is_active() or not is_instance_valid(unit) or not unit.has_method("get_unit_id"):
		return {}
	var state: Dictionary = _owner.call("get_hex_unit_state", String(unit.call("get_unit_id")))
	var registry := _registry()
	if state.is_empty() or not is_instance_valid(registry):
		return {}
	for method in ["grid_to_world","get_movement_distance"]:
		if not registry.has_method(method):
			return {}
	var range_hex := _range_hex(range_world, registry)
	if range_hex < -1:
		return {}
	# Freeze exactly the inputs a bounded FoW job consumes, not render motion.
	return {"position":registry.call("grid_to_world", state["grid"]),
		"grid_position":state["grid"],"sight_range_world":range_world,
		"hex_context_key":get_context_key(),"hex_registry_id":registry.get_instance_id(),
		"hex_state":{"grid":state["grid"],"facing_dir":state["facing_dir"],
			"stand_height_steps2":state["stand_height_steps2"]},
		"hex_profile":{"range_hex":range_hex,"arc_degrees":_arc_degrees}}

static func query_snapshot(source: Dictionary, target: Dictionary, registry: Node, cache) -> Dictionary:
	if not is_instance_valid(registry) or int(source.get("hex_registry_id",0)) != registry.get_instance_id():
		return {"visible":false,"reason":"mismatched_hex_registry"}
	if is_instance_valid(cache) and cache.has_method("query_hex_visibility"):
		return cache.call("query_hex_visibility", source["hex_state"], target, registry, source["hex_profile"])
	return QUERY.evaluate(source["hex_state"], target, registry, source["hex_profile"])

func _registry() -> Node:
	return _owner.call("get_hex_ground_terrain_registry") if is_active() else null

static func _range_hex(range_world: float, registry: Node) -> int:
	if not is_finite(range_world):
		return -2
	if range_world < 0.0:
		return -1
	var origin: Vector2 = registry.call("grid_to_world", Vector2i.ZERO)
	var neighbor: Vector2 = registry.call("grid_to_world", Vector2i(1,0))
	var spacing: float = float(registry.call("get_movement_distance", origin, neighbor))
	if not is_finite(spacing) or spacing <= 0.0:
		return -2
	return floori(range_world / spacing + 0.000001)
