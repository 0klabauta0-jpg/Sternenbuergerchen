extends RefCounted
## Projection of existing selected, deployed actors and authoritative hex state.
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const ADMISSION = preload("res://scripts/mission/hex_ground_admission.gd")
const INTERACTION_RADIUS := 6
const SPAWN_RADIUS := 5

static func resolve(location_id: String, globe: Vector2i, actors: Array, terrain: Node, ground: Dictionary) -> Dictionary:
	if location_id != "polisa": return {"ok":false,"reason":"wrong_location"}
	var recruiter := ""
	for entry in actors:
		if typeof(entry) != TYPE_DICTIONARY or typeof(entry.get("grid")) != TYPE_VECTOR2I: continue
		if entry.get("fit") != true or String(entry.get("unit_id", "")).is_empty(): continue
		if HEX.distance(entry.grid, globe) <= INTERACTION_RADIUS:
			recruiter = String(entry.unit_id)
			break
	if recruiter.is_empty(): return {"ok":false,"reason":"recruiter_not_near_globe"}
	var placement := find_spawn(globe, terrain, ground)
	if not placement.get("ok", false): return placement
	placement["unit_id"] = recruiter
	return placement

static func find_spawn(globe: Vector2i, terrain: Node, ground: Dictionary) -> Dictionary:
	var planner = ADMISSION.new()
	for radius in range(3, SPAWN_RADIUS + 1):
		for x in range(-radius, radius + 1):
			for y in range(-radius, radius + 1):
				var grid := globe + Vector2i(x, y)
				if HEX.distance(grid, globe) != radius: continue
				var plan: Dictionary = planner.plan_group(PackedStringArray(["polisa_recruitment_probe"]), grid, terrain, ground, 1)
				if plan.get("ok", false):
					return {"ok":true,"spawn_grid":grid}
	return {"ok":false,"reason":"no_spawn_space"}
