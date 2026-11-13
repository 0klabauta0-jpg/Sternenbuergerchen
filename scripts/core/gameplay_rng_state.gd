extends RefCounted
## Portable states of SimulationRoot's existing independent gameplay streams.
## Combat uses PCG; space/air retain their existing 31-bit LCG domains.
static func capture(owner: Node) -> Dictionary:
	return {"version":1, "combat":str(owner._combat_rng.state), "space_fire":owner._space_fire_rng, "air_ground":owner._air_ground_rng_state}

static func validate(value: Variant) -> bool:
	if not value is Dictionary or value.size() != 4 or not value.has_all(["version", "combat", "space_fire", "air_ground"]) or value.version != 1: return false
	if not value.combat is String or value.combat.length() > 20 or not value.combat.is_valid_int() or str(int(value.combat)) != value.combat: return false
	for key in ["space_fire", "air_ground"]:
		var number: Variant = value[key]
		if typeof(number) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(number)) or float(number) != floorf(float(number)) or float(number) < 0 or float(number) > 2147483647: return false
	return true

static func publish(owner: Node, value: Dictionary) -> void:
	owner._combat_rng.state = int(value.combat)
	owner._space_fire_rng = int(value.space_fire)
	owner._air_ground_rng_state = int(value.air_ground)

static func from_legacy(combat: String) -> Dictionary:
	return {"version":1, "combat":combat, "space_fire":1, "air_ground":1}
