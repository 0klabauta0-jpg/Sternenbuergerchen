extends RefCounted
## Conservative swept-hex proposal validation. No runtime binding yet.
## Temporal reservations and deadlock recovery remain AP03 work.
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const AREA = preload("res://scripts/core/space_area_grid.gd")
const MAX_SAMPLES := 128

static func preview_swept_cells(flight: Dictionary, proposal: Dictionary) -> Dictionary:
	return _sweep(flight, proposal)

static func resolve_motion(flights: Array[Dictionary], proposals: Array[Dictionary], world: Dictionary) -> Dictionary:
	var actors := {}
	var initial := {}
	var requested := {}
	var blocked := {}
	var area := {"coordinate_frame":world.get("coordinate_frame", "strategic"), "space_area_id":world.get("space_area_id", "")}
	if not AREA.contains(Vector2i.ZERO, area): return {"ok":false, "reason":"invalid_area"}
	if typeof(world.get("blocked_cells", [])) != TYPE_ARRAY:
		return {"ok":false, "reason":"invalid_world"}
	for cell in world.get("blocked_cells", []):
		if typeof(cell) != TYPE_VECTOR2I or not AREA.contains(cell, area): return {"ok":false, "reason":"invalid_world"}
		blocked[cell] = true
	for flight in flights:
		if flight.get("coordinate_frame", "strategic") != area.coordinate_frame or flight.get("space_area_id", "") != area.space_area_id:
			return {"ok":false, "reason":"area_mismatch"}
		var id: Variant = flight.get("craft_id")
		if typeof(id) != TYPE_STRING or String(id).is_empty() or actors.has(id):
			return {"ok":false, "reason":"invalid_actor"}
		var cells: Dictionary = _sweep(flight, flight)
		if not cells.ok: return {"ok":false, "reason":cells.reason}
		for cell in cells.cells:
			if blocked.has(cell) or initial.has(cell): return {"ok":false, "reason":"invalid_initial_occupancy"}
			initial[cell] = id
		actors[id] = flight
	for proposal in proposals:
		var id: Variant = proposal.get("craft_id")
		if typeof(id) != TYPE_STRING or not actors.has(id) or requested.has(id):
			return {"ok":false, "reason":"invalid_proposal"}
		requested[id] = proposal
	var reservations := initial.duplicate()
	var ids: Array = requested.keys()
	ids.sort()
	var accepted := {}
	var rejected := {}
	for id in ids:
		var sweep: Dictionary = _sweep(actors[id], requested[id])
		if not sweep.ok:
			rejected[id] = sweep.reason
			continue
		var reason := ""
		for cell in sweep.cells:
			if blocked.has(cell):
				reason = "blocked"
				break
			if reservations.has(cell) and reservations[cell] != id:
				reason = "occupied"
				break
		if not reason.is_empty():
			rejected[id] = reason
			continue
		accepted[id] = requested[id].duplicate(true)
		for cell in sweep.cells: reservations[cell] = id
	return {"ok":true, "accepted":accepted, "rejected":rejected}

static func _sweep(flight: Dictionary, proposal: Dictionary) -> Dictionary:
	if typeof(flight.get("position_plane")) != TYPE_VECTOR2 or typeof(proposal.get("position_plane")) != TYPE_VECTOR2:
		return {"ok":false, "reason":"invalid_pose"}
	var start: Vector2 = flight.position_plane
	var finish: Vector2 = proposal.position_plane
	var a: Variant = flight.get("heading_rad", 0.0)
	var b: Variant = proposal.get("heading_rad", a)
	if not start.is_finite() or not finish.is_finite() or typeof(a) not in [TYPE_INT, TYPE_FLOAT] or typeof(b) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(a)) or not is_finite(float(b)):
		return {"ok":false, "reason":"invalid_pose"}
	var footprint: Variant = flight.get("footprint_hexes", [Vector2i.ZERO])
	if typeof(footprint) != TYPE_ARRAY or footprint.is_empty():
		return {"ok":false, "reason":"invalid_footprint"}
	for offset in footprint:
		if typeof(offset) != TYPE_VECTOR2I: return {"ok":false, "reason":"invalid_footprint"}
	var angle := angle_difference(float(a), float(b))
	var max_radius := 0.0
	for offset in footprint:
		max_radius = maxf(max_radius, GRID.HEX.axial_to_plane(Vector2(offset)).length())
	var sample_count := maxi(1, maxi(ceili((start.distance_to(finish) + max_radius * absf(angle)) * 4.0), ceili(absf(angle) * 18.0 / PI)))
	if sample_count > MAX_SAMPLES:
		return {"ok":false, "reason":"sweep_limit"}
	var result := {}
	var previous: Dictionary = {}
	var margin := (max_radius + GRID.HEX.DEFAULT_RADIUS) * (1.0 - cos(absf(angle) / sample_count * 0.5))
	var single_cell: bool = footprint.size() == 1 and footprint[0] == Vector2i.ZERO
	for index in range(sample_count + 1):
		var t := float(index) / sample_count
		var position := start.lerp(finish, t)
		var heading := float(a) + angle * t
		for offset in footprint:
			var local: Vector2 = GRID.HEX.axial_to_plane(Vector2(offset)).rotated(heading)
			var current: Vector2 = position + local
			var from: Vector2 = previous.get(offset, current)
			var visited_cells: Array[Vector2i]
			if single_cell:
				visited_cells = _supercover(from, current, 0.00001)
			else:
				var previous_heading := float(a) + angle * maxf(0.0, float(index - 1) / sample_count)
				visited_cells = _hull_supercover(from, current, previous_heading, heading, margin if index > 0 else 0.0)
			for visited in visited_cells:
				if not AREA.contains(visited, flight): return {"ok":false, "reason":"map_edge"}
				result[visited] = true
			previous[offset] = current
	return {"ok":true, "cells":result.keys()}

static func _hull_supercover(from: Vector2, to: Vector2, from_angle: float, to_angle: float, margin: float) -> Array[Vector2i]:
	var points := PackedVector2Array()
	for corner in 6:
		var offset := PI / 6.0 + corner * PI / 3.0
		points.append(from + Vector2.from_angle(from_angle + offset) * (GRID.HEX.DEFAULT_RADIUS + margin))
		points.append(to + Vector2.from_angle(to_angle + offset) * (GRID.HEX.DEFAULT_RADIUS + margin))
	var hull: PackedVector2Array = Geometry2D.convex_hull(points)
	var first: Vector2i = GRID.HEX.round_axial(GRID.HEX.plane_to_axial(from))
	var last: Vector2i = GRID.HEX.round_axial(GRID.HEX.plane_to_axial(to))
	var candidates := {}
	for base in GRID.HEX.line(first, last):
		candidates[base] = true
		for direction in GRID.HEX.DIRECTIONS:
			candidates[base + direction] = true
			for second in GRID.HEX.DIRECTIONS:
				candidates[base + direction + second] = true
	var result: Array[Vector2i] = []
	for cell in candidates:
		var center: Vector2 = GRID.HEX.axial_to_plane(Vector2(cell))
		var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(center, from, to)
		var bound: float = 2.0 * GRID.HEX.DEFAULT_RADIUS + margin + 0.00001
		if center.distance_squared_to(nearest) > bound * bound:
			continue
		var polygon := PackedVector2Array()
		for corner in 6:
			polygon.append(center + Vector2.from_angle(PI / 6.0 + corner * PI / 3.0) * GRID.HEX.DEFAULT_RADIUS)
		for intersection in Geometry2D.intersect_polygons(hull, polygon):
			if intersection.size() >= 3 and absf(_polygon_area(intersection)) > 0.00000001:
				result.append(cell)
				break
	return result

static func _polygon_area(polygon: PackedVector2Array) -> float:
	var area := 0.0
	var origin := polygon[0]
	for index in polygon.size():
		area += (polygon[index] - origin).cross(polygon[(index + 1) % polygon.size()] - origin)
	return area * 0.5

static func _supercover(from: Vector2, to: Vector2, margin: float) -> Array[Vector2i]:
	var first: Vector2i = GRID.HEX.round_axial(GRID.HEX.plane_to_axial(from))
	var last: Vector2i = GRID.HEX.round_axial(GRID.HEX.plane_to_axial(to))
	var candidates := {}
	for base in GRID.HEX.line(first, last):
		candidates[base] = true
		for direction in GRID.HEX.DIRECTIONS:
			candidates[base + direction] = true
	var result: Array[Vector2i] = []
	for cell in candidates:
		var center: Vector2 = GRID.HEX.axial_to_plane(Vector2(cell))
		var polygon := PackedVector2Array()
		var radius: float = GRID.HEX.DEFAULT_RADIUS * (1.0 + 2.0 * margin)
		for corner in 6:
			polygon.append(center + Vector2.from_angle(PI / 6.0 + corner * PI / 3.0) * radius)
		var hit := Geometry2D.is_point_in_polygon(from, polygon) or Geometry2D.is_point_in_polygon(to, polygon)
		if not hit:
			for corner in 6:
				if Geometry2D.segment_intersects_segment(from, to, polygon[corner], polygon[(corner + 1) % 6]) != null:
					hit = true
					break
		if hit: result.append(cell)
	return result
