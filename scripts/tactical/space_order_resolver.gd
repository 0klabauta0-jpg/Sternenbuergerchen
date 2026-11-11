extends RefCounted
## Pure navigation intent only. No movement or world state is committed here.
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const AREA = preload("res://scripts/core/space_area_grid.gd")
const ARRIVAL_SPEED := 0.05

static func resolve(order: Dictionary, world: Dictionary, dt: float) -> Dictionary:
	if not is_finite(dt) or dt < 0.0: return _reject("invalid_delta")
	var members: Variant = world.get("members")
	if typeof(members) != TYPE_DICTIONARY or members.is_empty(): return _reject("no_members")
	var verb: String = String(order.get("verb", ""))
	if verb not in ["move", "patrol", "secure", "withdraw"]: return _reject("unsupported_order")
	var target: Variant = order.get("target_hex")
	var area := {"coordinate_frame":world.get("coordinate_frame", "strategic"), "space_area_id":world.get("space_area_id", "")}
	var index: int = 0
	var waypoints: Array = []
	if verb == "patrol":
		if typeof(order.get("waypoints")) != TYPE_ARRAY or order.waypoints.is_empty(): return _reject("invalid_target")
		waypoints = order.waypoints
		if typeof(order.get("waypoint_index", 0)) != TYPE_INT: return _reject("invalid_target")
		index = int(order.get("waypoint_index", 0))
		if index < 0 or index >= waypoints.size(): return _reject("invalid_target")
		for waypoint in waypoints:
			if typeof(waypoint) != TYPE_VECTOR2I or not AREA.contains(waypoint, area): return _reject("invalid_target")
		target = waypoints[index]
	if typeof(target) != TYPE_VECTOR2I or not AREA.contains(target, area): return _reject("invalid_target")
	var radius_value: Variant = order.get("arrival_radius", 0.25)
	if typeof(radius_value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(radius_value)) or float(radius_value) <= 0.0:
		return _reject("invalid_radius")
	var target_plane: Vector2 = GRID.HEX.axial_to_plane(Vector2(target))
	var ids: Array = members.keys()
	for id in ids:
		if typeof(id) != TYPE_STRING or String(id).is_empty() or typeof(members[id]) != TYPE_DICTIONARY: return _reject("invalid_member")
		var member: Dictionary = members[id]
		if typeof(member.get("position_plane")) != TYPE_VECTOR2 or typeof(member.get("velocity_plane")) != TYPE_VECTOR2: return _reject("invalid_member")
		if not member.position_plane.is_finite() or not member.velocity_plane.is_finite(): return _reject("invalid_member")
		if typeof(member.get("blocked", false)) != TYPE_BOOL: return _reject("invalid_member")
	ids.sort()
	for id in ids:
		if members[id].get("blocked", false):
			return {"ok":true, "status":"blocked", "intents":{}, "next_waypoint_index":index}
	var intents := {}
	var all_at_position := true
	var all_stopped := true
	for id in ids:
		var member: Dictionary = members[id]
		if member.position_plane.distance_to(target_plane) > float(radius_value): all_at_position = false
		if member.velocity_plane.length() > ARRIVAL_SPEED: all_stopped = false
		intents[id] = {"target_plane":target_plane, "arrival_radius":float(radius_value)}
	var status := "en_route"
	if all_at_position and not all_stopped:
		status = "arriving"
	elif all_at_position and all_stopped:
		match verb:
			"patrol":
				index = (index + 1) % waypoints.size()
				status = "patrolling"
				intents.clear()
			"secure": status = "holding"
			_:
				status = "complete"
				intents.clear()
	return {"ok":true, "status":status, "intents":intents, "next_waypoint_index":index}

static func _reject(reason: String) -> Dictionary:
	return {"ok":false, "reason":reason, "intents":{}}
