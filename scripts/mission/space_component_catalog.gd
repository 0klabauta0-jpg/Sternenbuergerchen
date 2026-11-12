extends RefCounted
## Pure provisional AP09 catalog. It owns no installed equipment or inventory.
const PATH := "res://data/space/ship_components.json"
const WARP_CATALOG = preload("res://scripts/mission/ship_equipment_catalog.gd")

static func definition() -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return raw if typeof(raw) == TYPE_DICTIONARY and raw.get("schema_version") == 1 else {}

static func default_loadout(model_id: String) -> Dictionary:
	var model: Dictionary = Dictionary(definition().get("models", {})).get(model_id, {})
	return Dictionary(model.get("default_slots", {})).duplicate(true)

static func validate_loadout(model_id: String, slots: Dictionary) -> Dictionary:
	var data := definition()
	var models: Dictionary = data.get("models", {})
	var items: Dictionary = data.get("items", {})
	var model: Dictionary = models.get(model_id, {})
	if model.is_empty() or typeof(model.get("slots")) != TYPE_DICTIONARY: return _reject("unknown_model")
	var specs: Dictionary = model.slots
	if slots.size() != specs.size(): return _reject("slot_set_mismatch")
	for slot_id: Variant in slots:
		if typeof(slot_id) != TYPE_STRING or not specs.has(slot_id) or typeof(slots[slot_id]) != TYPE_STRING: return _reject("invalid_slot")
		var spec: Variant = specs[slot_id]
		var item: Variant = items.get(slots[slot_id])
		if typeof(spec) != TYPE_DICTIONARY or typeof(item) != TYPE_DICTIONARY: return _reject("unknown_component")
		if spec.get("class") not in ["repeater", "shield", "power"] or item.get("class") != spec.get("class"): return _reject("wrong_component_class")
		if not _positive_integer(spec.get("max_size")) or not _positive_integer(item.get("size")) or int(item["size"]) > int(spec.max_size): return _reject("wrong_component_size")
		if not _positive(item.get("mass")): return _reject("invalid_component_data")
		var fields: Array = ["output"] if item["class"] == "power" else (["power_demand", "capacity", "recharge_rate", "recovery_delay"] if item["class"] == "shield" else ["power_demand", "range", "damage", "shots_per_second"])
		for field: String in fields:
			if not _positive(item.get(field)): return _reject("invalid_component_data")
		if item["class"] == "repeater" and (not _positive(spec.get("arc_degrees")) or float(spec.arc_degrees) > 360.0): return _reject("invalid_slot_data")
	if not _positive(model.get("flight_demand")): return _reject("invalid_model_data")
	return {"ok":true}

static func effective_stats(model_id: String, slots: Dictionary) -> Dictionary:
	var valid := validate_loadout(model_id, slots)
	if not valid.ok: return valid
	var data := definition()
	var model: Dictionary = data.models[model_id]
	var base := WARP_CATALOG.flight_profile(model_id)
	if not _positive(base.get("mass")): return _reject("flight_profile_unavailable")
	var mass := float(base.mass)
	var output := 0.0
	var weapon_demand := 0.0
	var shield_demand := 0.0
	var shield := {}
	var weapons: Array[Dictionary] = []
	var ordered: Array = slots.keys(); ordered.sort()
	for slot_id: String in ordered:
		var component: Dictionary = data.items[slots[slot_id]]
		mass += float(component.mass)
		match component["class"]:
			"power": output += float(component.output)
			"shield":
				shield_demand += float(component.power_demand)
				shield = {"capacity":float(component.capacity), "recharge_rate":float(component.recharge_rate), "recovery_delay":float(component.recovery_delay)}
			"repeater":
				weapon_demand += float(component.power_demand)
				weapons.append({"slot_id":slot_id, "item_id":slots[slot_id], "arc_degrees":float(model.slots[slot_id].arc_degrees), "range":float(component.range), "damage":float(component.damage), "shots_per_second":float(component.shots_per_second)})
	var flight_allocation := minf(output, float(model.flight_demand))
	var available := maxf(0.0, output - flight_allocation)
	var weapon_allocation := minf(available, weapon_demand)
	var shield_allocation := minf(maxf(0.0, available - weapon_allocation), shield_demand)
	# Reserve values are provisional game balance, not claims about any ship.
	return {"ok":true, "model_id":model_id, "mass":mass, "weapons":weapons, "shield":shield, "weapon_reserve":{"capacity":20.0, "recharge_rate":4.0}, "power":{"output":output, "flight_fraction":flight_allocation / float(model.flight_demand), "weapon_fraction":weapon_allocation / weapon_demand if weapon_demand > 0.0 else 0.0, "shield_fraction":shield_allocation / shield_demand if shield_demand > 0.0 else 0.0}}

static func flight_inputs(model_id: String, slots: Dictionary) -> Dictionary:
	# Projection only; the equipment owner must select installed IDs and bind
	# its revision before SimulationRoot uses these values for actual flight.
	var stats := effective_stats(model_id, slots)
	if not stats.ok: return stats
	var base := WARP_CATALOG.flight_profile(model_id)
	for field in ["main_thrust", "reverse_thrust", "side_thrust", "turn_acceleration"]:
		if not _positive(base.get(field)): return _reject("flight_profile_unavailable")
	return {"ok":true, "mass":float(stats.mass), "hull":{"main_thrust":float(base.main_thrust), "reverse_thrust":float(base.reverse_thrust), "side_thrust":float(base.side_thrust), "turn_acceleration":float(base.turn_acceleration)}, "power":{"thrust_fraction":float(stats.power.flight_fraction)}}

static func _positive(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) > 0.0

static func _positive_integer(value: Variant) -> bool:
	return _positive(value) and float(value) == floorf(float(value))

static func _reject(reason: String) -> Dictionary:
	return {"ok":false, "reason":reason}
