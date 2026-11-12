extends RefCounted
## Pure axial-hex dispersion. The authoritative caller supplies the pilot
## skill, seed, and target; this resolver neither selects nor damages units.
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const MIN_RADIUS := 1
const MAX_RADIUS := 10

static func preview(target: Vector2i, pilot_skill: float) -> Dictionary:
	if not is_finite(pilot_skill) or pilot_skill < 0.0 or pilot_skill > 1.0:
		return {"ok":false, "reason":"invalid_pilot_skill"}
	var radius := clampi(roundi(lerpf(float(MAX_RADIUS), float(MIN_RADIUS), pilot_skill)), MIN_RADIUS, MAX_RADIUS)
	var cells: Array[Vector2i] = []
	for q in range(-radius, radius + 1):
		for r in range(-radius, radius + 1):
			var cell := target + Vector2i(q, r)
			if HEX.distance(target, cell) <= radius: cells.append(cell)
	return {"ok":true, "radius":radius, "cells":cells}

static func resolve(target: Vector2i, pilot_skill: float, seed_value: int) -> Dictionary:
	var area := preview(target, pilot_skill)
	if not area.ok: return area
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var index := rng.randi_range(0, area.cells.size() - 1)
	return {"ok":true, "radius":area.radius, "impact_hex":area.cells[index]}
