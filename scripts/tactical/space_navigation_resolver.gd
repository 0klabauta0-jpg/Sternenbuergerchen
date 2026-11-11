extends RefCounted
## Provisional sampled swept-hex proposal validation. No runtime binding yet.
## Exact edge-grazing coverage and temporal reservations remain AP03 work.
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const MAX_SAMPLES := 128

static func resolve_motion(flights: Array[Dictionary], proposals: Array[Dictionary], world: Dictionary) -> Dictionary:
	var actors := {}
	var initial := {}
	var requested := {}
	var blocked := {}
	if typeof(world.get("blocked_cells", [])) != TYPE_ARRAY:
		return {"ok":false, "reason":"invalid_world"}
	for cell in world.get("blocked_cells", []):
		if typeof(cell) != TYPE_VECTOR2I or not GRID.contains(cell): return {"ok":false, "reason":"invalid_world"}
		blocked[cell] = true
	for flight in flights:
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
	var sample_count := maxi(1, maxi(ceili(start.distance_to(finish) * 4.0), ceili(absf(angle) * 18.0 / PI)))
	if sample_count > MAX_SAMPLES:
		return {"ok":false, "reason":"sweep_limit"}
	var result := {}
	var previous: Dictionary = {}
	for index in range(sample_count + 1):
		var t := float(index) / sample_count
		var position := start.lerp(finish, t)
		var heading := float(a) + angle * t
		for offset in footprint:
			var local: Vector2 = GRID.HEX.axial_to_plane(Vector2(offset)).rotated(heading)
			var cell: Vector2i = GRID.HEX.round_axial(GRID.HEX.plane_to_axial(position + local))
			var traversed: Array[Vector2i] = [cell]
			if previous.has(offset): traversed = GRID.HEX.line(previous[offset], cell)
			for visited in traversed:
				if not GRID.contains(visited): return {"ok":false, "reason":"map_edge"}
				result[visited] = true
			previous[offset] = cell
	return {"ok":true, "cells":result.keys()}
