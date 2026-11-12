extends RefCounted
## Pure proposals only. A future SimulationRoot caller owns and commits state.

static func initial(stats: Dictionary, hull_capacity: float) -> Dictionary:
	if not _valid_stats(stats) or not _nonnegative(hull_capacity) or hull_capacity <= 0.0: return _reject("invalid_stats")
	return {"ok":true, "state":{"hull":hull_capacity, "hull_capacity":hull_capacity, "shield":float(stats.shield.capacity), "weapon_energy":float(stats.weapon_reserve.capacity), "shield_delay":0.0}}

static func apply_hit(stats: Dictionary, state: Dictionary, damage: float) -> Dictionary:
	if not _valid_state(stats, state) or not _nonnegative(damage): return _reject("invalid_hit")
	var next := state.duplicate(true)
	var absorbed := minf(float(next.shield), damage)
	next.shield = float(next.shield) - absorbed
	next.hull = maxf(0.0, float(next.hull) - (damage - absorbed))
	if damage > 0.0: next.shield_delay = float(stats.shield.recovery_delay)
	return {"ok":true, "state":next, "shield_damage":absorbed, "hull_damage":float(state.hull) - float(next.hull)}

static func consume_weapon(stats: Dictionary, state: Dictionary, energy: float) -> Dictionary:
	if not _valid_state(stats, state) or not _nonnegative(energy) or energy <= 0.0: return _reject("invalid_energy")
	if float(state.weapon_energy) < energy: return _reject("insufficient_weapon_energy")
	var next := state.duplicate(true)
	next.weapon_energy = float(next.weapon_energy) - energy
	return {"ok":true, "state":next}

static func advance(stats: Dictionary, state: Dictionary, dt: float) -> Dictionary:
	if not _valid_state(stats, state) or not _nonnegative(dt): return _reject("invalid_tick")
	var next := state.duplicate(true)
	var shield_time := maxf(0.0, dt - float(state.shield_delay))
	next.shield_delay = maxf(0.0, float(state.shield_delay) - dt)
	next.shield = minf(float(stats.shield.capacity), float(state.shield) + shield_time * float(stats.shield.recharge_rate) * float(stats.power.shield_fraction))
	next.weapon_energy = minf(float(stats.weapon_reserve.capacity), float(state.weapon_energy) + dt * float(stats.weapon_reserve.recharge_rate) * float(stats.power.weapon_fraction))
	return {"ok":true, "state":next}

static func _valid_stats(stats: Dictionary) -> bool:
	if not stats.get("ok", false) or typeof(stats.get("shield")) != TYPE_DICTIONARY or typeof(stats.get("weapon_reserve")) != TYPE_DICTIONARY or typeof(stats.get("power")) != TYPE_DICTIONARY: return false
	for field in ["capacity", "recharge_rate", "recovery_delay"]:
		if not _nonnegative(stats.shield.get(field)): return false
	for field in ["capacity", "recharge_rate"]:
		if not _nonnegative(stats.weapon_reserve.get(field)): return false
	for field in ["weapon_fraction", "shield_fraction"]:
		if not _nonnegative(stats.power.get(field)) or float(stats.power[field]) > 1.0: return false
	return true

static func _valid_state(stats: Dictionary, state: Dictionary) -> bool:
	if not _valid_stats(stats): return false
	for field in ["hull", "hull_capacity", "shield", "weapon_energy", "shield_delay"]:
		if not _nonnegative(state.get(field)): return false
	return float(state.hull_capacity) > 0.0 and float(state.hull) <= float(state.hull_capacity) and float(state.shield) <= float(stats.shield.capacity) and float(state.weapon_energy) <= float(stats.weapon_reserve.capacity)

static func _nonnegative(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) >= 0.0

static func _reject(reason: String) -> Dictionary:
	return {"ok":false, "reason":reason}
