extends RefCounted
## Bounded, read-only targeting proposals. The caller supplies already indexed
## candidates and authoritative hostility/visibility; no UI data is authority.
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const MAX_ACTORS := 256

static func collect_contacts(world: Dictionary, faction_id: String) -> Dictionary:
	var actors: Variant = world.get("actors")
	var opaque: Variant = world.get("opaque_cells", [])
	if faction_id.is_empty() or typeof(actors) != TYPE_DICTIONARY or actors.size() > MAX_ACTORS or typeof(opaque) != TYPE_ARRAY or opaque.size() > 4096: return _reject("invalid_world")
	for id in actors:
		if typeof(id) != TYPE_STRING or String(id).is_empty(): return _reject("invalid_actor")
	for cell in opaque:
		if typeof(cell) != TYPE_VECTOR2I: return _reject("invalid_world")
	var ids: Array = actors.keys(); ids.sort()
	var contacts: Array[String] = []
	for observer_id: Variant in ids:
		var observer: Variant = actors[observer_id]
		if typeof(observer_id) != TYPE_STRING or typeof(observer) != TYPE_DICTIONARY: return _reject("invalid_actor")
		if observer.get("faction_id") != faction_id: continue
		if not _valid_actor(observer) or not _positive(observer.get("sensor_range")): return _reject("invalid_actor")
		for target_id: Variant in ids:
			if target_id == observer_id or contacts.has(target_id): continue
			var target: Variant = actors[target_id]
			if typeof(target) != TYPE_DICTIONARY or not _valid_actor(target): return _reject("invalid_actor")
			if target.get("area_id", "") != observer.get("area_id", ""): continue
			if observer.position.distance_to(target.position) > float(observer.sensor_range): continue
			if _blocked(observer.position, target.position, opaque): continue
			contacts.append(target_id)
	contacts.sort()
	return {"ok":true, "contacts":contacts}

static func evaluate_target(shooter: Dictionary, target: Dictionary, weapon: Dictionary, order: Dictionary, world: Dictionary) -> Dictionary:
	if not _valid_actor(shooter) or not _valid_actor(target) or typeof(target.get("id")) != TYPE_STRING or String(target.id).is_empty(): return _reject("invalid_actor")
	if shooter.get("area_id", "") != target.get("area_id", ""): return _reject("different_area")
	if typeof(world.get("known_targets")) != TYPE_ARRAY or not world.known_targets.has(target.id): return _reject("unknown_target")
	if typeof(world.get("hostile_factions")) != TYPE_ARRAY or not world.hostile_factions.has(target.get("faction_id")): return _reject("not_hostile")
	if order.get("fire_rule") == "hold": return _reject("fire_hold")
	if order.get("fire_rule") not in ["return", "free"]: return _reject("invalid_fire_rule")
	if order.fire_rule == "return" and world.get("return_fire_authorized") != true: return _reject("return_fire_not_authorized")
	if not _positive(weapon.get("range")) or not _positive(weapon.get("arc_degrees")) or float(weapon.arc_degrees) > 360.0 or not _finite_number(shooter.get("heading_rad")): return _reject("invalid_weapon")
	var delta: Vector2 = target.position - shooter.position
	if delta.length_squared() <= 0.000001 or delta.length() > float(weapon.range): return _reject("out_of_range")
	if absf(wrapf(delta.angle() - float(shooter.heading_rad), -PI, PI)) > deg_to_rad(float(weapon.arc_degrees) * 0.5): return _reject("outside_fire_arc")
	var opaque: Variant = world.get("opaque_cells", [])
	if typeof(opaque) != TYPE_ARRAY or opaque.size() > 4096: return _reject("invalid_world")
	for cell in opaque:
		if typeof(cell) != TYPE_VECTOR2I: return _reject("invalid_world")
	if _blocked(shooter.position, target.position, opaque): return _reject("line_blocked")
	return {"ok":true}

static func _blocked(origin: Vector2, destination: Vector2, opaque: Array) -> bool:
	var line: Array = HEX.line(HEX.round_axial(HEX.plane_to_axial(origin)), HEX.round_axial(HEX.plane_to_axial(destination)))
	for i in range(1, line.size()):
		if opaque.has(line[i]): return true
	return false

static func _valid_actor(actor: Dictionary) -> bool:
	return typeof(actor.get("position")) == TYPE_VECTOR2 and actor.position.is_finite() and typeof(actor.get("faction_id")) == TYPE_STRING and not String(actor.faction_id).is_empty() and typeof(actor.get("area_id", "")) == TYPE_STRING

static func _finite_number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value))

static func _positive(value: Variant) -> bool: return _finite_number(value) and float(value) > 0.0
static func _reject(reason: String) -> Dictionary: return {"ok":false, "reason":reason}
