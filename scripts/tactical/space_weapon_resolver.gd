extends RefCounted
## Stateless shot proposal. Ammo, cooldown, damage and replay are owner duties.
const TARGETING = preload("res://scripts/tactical/space_targeting_resolver.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")

static func resolve_shot(shooter: Dictionary, target: Dictionary, weapon: Dictionary, order: Dictionary, world: Dictionary, event_id: String, rng_state: int) -> Dictionary:
	if event_id.strip_edges().is_empty() or rng_state < 0 or rng_state > 2147483647: return {"ok":false, "reason":"invalid_event"}
	var allowed := TARGETING.evaluate_target(shooter, target, weapon, order, world)
	if not allowed.ok: return allowed
	if typeof(weapon.get("slot_id")) != TYPE_STRING or String(weapon.slot_id).is_empty() or typeof(weapon.get("damage")) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(weapon.damage)) or float(weapon.damage) <= 0.0 or typeof(weapon.get("accuracy")) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(weapon.accuracy)) or float(weapon.accuracy) < 0.0 or float(weapon.accuracy) > 1.0: return {"ok":false,"reason":"invalid_weapon"}
	var indexed: Variant = world.get("occupants_by_cell")
	if typeof(indexed) != TYPE_DICTIONARY or typeof(shooter.get("id")) != TYPE_STRING: return {"ok":false,"reason":"invalid_index"}
	var line: Array = HEX.line(HEX.round_axial(HEX.plane_to_axial(shooter.position)), HEX.round_axial(HEX.plane_to_axial(target.position)))
	var first := ""
	var found_target := false
	var impact_position: Vector2 = target.position
	for i in range(1, line.size()):
		var occupants: Variant = indexed.get(line[i], [])
		if typeof(occupants) != TYPE_ARRAY: return {"ok":false,"reason":"invalid_index"}
		for id in occupants:
			if typeof(id) != TYPE_STRING or String(id).is_empty(): return {"ok":false,"reason":"invalid_index"}
		var ordered: Array = occupants.duplicate(); ordered.sort()
		for id in ordered:
			if typeof(id) != TYPE_STRING or String(id).is_empty(): return {"ok":false,"reason":"invalid_index"}
			if id == target.id: found_target = true
			if first.is_empty() and id != shooter.id:
				first = id
				if id != target.id: impact_position = HEX.axial_to_plane(Vector2(line[i]))
	if first.is_empty() or not found_target: return {"ok":false,"reason":"target_not_indexed"}
	var next_rng: int = (rng_state * 1103515245 + 12345) & 0x7fffffff
	var hit := float(next_rng) / 2147483648.0 < float(weapon.accuracy)
	return {"ok":true, "event":{"id":event_id, "shooter_id":shooter.id, "weapon_slot":weapon.slot_id, "aimed_target_id":target.id, "hit_craft_id":first if hit else "", "damage":float(weapon.damage) if hit else 0.0, "origin":shooter.position, "destination":impact_position if hit else target.position}, "rng_state":next_rng}
