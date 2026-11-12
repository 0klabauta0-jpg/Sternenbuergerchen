class_name HexSightRuntimeAdapter
extends RefCounted

## Read/command adapter. It stores dependencies and command IDs, never an
## alternate unit state; only SimulationRoot commits accepted facing intents.
const QUERY = preload("res://scripts/core/hex_visibility_query.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
var _owner: Node
var _cache: Object
var _arc_degrees := 120.0
var _security_intent_serial := 0

func configure(owner: Node, cache: Object, arc_degrees: float = 120.0) -> void:
	_owner = owner
	_cache = cache
	_arc_degrees = arc_degrees

func is_active() -> bool:
	return is_instance_valid(_owner) and _owner.has_method("is_hex_ground_runtime_active") and bool(_owner.call("is_hex_ground_runtime_active"))

func has_runtime_dependencies() -> bool:
	return is_instance_valid(_owner) and is_instance_valid(_cache)

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


func read_position(unit) -> Dictionary:
	if not is_active():
		return {"valid":unit is Node2D,"position":unit.global_position if unit is Node2D else Vector2.ZERO}
	var state := build_observer_state(unit,-1.0)
	return {"valid":not state.is_empty(),"position":state.get("position",Vector2.ZERO)}

func read_position_for_id(unit_id: String) -> Dictionary:
	if not is_active():
		return {"valid":false}
	var state: Dictionary = _owner.call("get_hex_unit_state",unit_id)
	return {"valid":not state.is_empty(),"position":_registry().call("grid_to_world",state.grid) if not state.is_empty() else Vector2.ZERO,
		"facing_dir":int(state.get("facing_dir",-1))}

func get_current_tick() -> int:
	return int(_owner.get("tick_counter")) if is_active() else -1

func get_arc_radians() -> float:
	return deg_to_rad(_arc_degrees)

func snap_world_position(position: Vector2) -> Vector2:
	return Vector2(_registry().call("grid_to_world",_registry().call("world_to_grid",position))) if is_active() else position

func world_angle_to_plane(angle: float) -> float:
	if not is_active():
		return angle
	var registry := _registry()
	var origin: Vector2 = registry.call("grid_to_world",Vector2i.ZERO)
	var delta: Vector2 = Vector2(registry.call("world_to_grid_float",origin+Vector2.from_angle(angle))) - Vector2(registry.call("world_to_grid_float",origin))
	return HEX.axial_to_plane(delta).angle()

func plane_angle_to_world(angle: float) -> float:
	if not is_active():
		return angle
	var axial: Vector2 = HEX.plane_to_axial(Vector2.from_angle(angle))
	var registry := _registry()
	var origin: Vector2 = registry.call("grid_to_world",Vector2i.ZERO)
	var axis_q: Vector2 = Vector2(registry.call("grid_to_world",Vector2i(1,0)))-origin
	var axis_r: Vector2 = Vector2(registry.call("grid_to_world",Vector2i(0,1)))-origin
	return (axis_q*axial.x+axis_r*axial.y).angle()

func bearing(from_position: Vector2, to_position: Vector2) -> float:
	if not is_active():
		return (to_position-from_position).angle()
	var registry := _registry()
	var delta: Vector2 = Vector2(registry.call("world_to_grid_float",to_position))-Vector2(registry.call("world_to_grid_float",from_position))
	return HEX.axial_to_plane(delta).angle()

func distance(from_position: Vector2, to_position: Vector2) -> float:
	return float(_registry().call("get_movement_distance",from_position,to_position)) if is_active() else from_position.distance_to(to_position)

func world_angle_to_facing(angle: float) -> int:
	if not is_active() or not is_finite(angle):
		return -1
	var plane_angle := world_angle_to_plane(angle)
	var best := 0
	var best_dot := -INF
	for direction in range(6):
		var axis: Vector2 = HEX.axial_to_plane(Vector2(HEX.DIRECTIONS[direction])).normalized()
		var score := axis.dot(Vector2.from_angle(plane_angle))
		if score > best_dot:
			best_dot = score
			best = direction
	return best

func facing_to_world_angle(direction: int) -> float:
	if not is_active() or direction < 0 or direction > 5:
		return 0.0
	var registry := _registry()
	return (Vector2(registry.call("grid_to_world",HEX.DIRECTIONS[direction]))-Vector2(registry.call("grid_to_world",Vector2i.ZERO))).angle()

## Runtime command bridge; only SimulationRoot commits the resulting direction.
func apply_security_assignments(assignments: Array, command_id: String, mode: String = "directional", direction_angle: float = 0.0) -> Array:
	if not is_active():
		return assignments.duplicate(true)
	_security_intent_serial += 1
	var result: Array = []
	var available: Array[Dictionary] = []
	for original in assignments:
		if not original is Dictionary:
			continue
		var unit_id := String(original.get("unit_id",""))
		var state: Dictionary = _owner.call("get_hex_unit_state",unit_id)
		if state.is_empty():
			continue
		available.append({"assignment":original.duplicate(true),"state":state})
	var base_direction := world_angle_to_facing(direction_angle)
	if mode == "360" and base_direction < 0:
		return result
	for index in range(available.size()):
		var assignment: Dictionary = available[index].assignment
		var state: Dictionary = available[index].state
		var unit_id := String(assignment.get("unit_id",""))
		var desired_angle: float = float(assignment.get("center_angle",0.0))
		var desired := world_angle_to_facing(desired_angle)
		if mode == "360":
			# Quantize the common base once: independent half-sector ties can
			# otherwise leave a 180-degree gap in a three-member ring.
			desired = posmod(base_direction-roundi(6.0*float(index)/float(available.size())),6)
			desired_angle = facing_to_world_angle(desired)
			assignment["base_angle"] = desired_angle
			assignment["scan_offset_angle"] = 0.0
		_owner.call("queue_hex_facing_intent",unit_id,desired,"%s:%d:%s"%[command_id,_security_intent_serial,unit_id],"security_assignment")
		assignment["center_angle"] = facing_to_world_angle(int(state["facing_dir"]))
		assignment["facing_dir"] = state["facing_dir"]
		assignment["arc_width"] = deg_to_rad(_arc_degrees) if mode == "360" else minf(float(assignment.get("arc_width",TAU)),deg_to_rad(_arc_degrees))
		result.append(assignment)
	return result
