extends RefCounted
## Cross-check the independent base owner captured while the entire crew is away.
## The live Root still prepares/validates the full checkpoint before publication.
const HEX = preload("res://scripts/core/hex_checkpoint_transaction.gd")

static func validate(state: Variant, base: Variant, craft: String) -> Dictionary:
	var checked: Dictionary = HEX.validate_shape(state)
	if not checked.get("ok",false): return checked
	if not base is Dictionary or not base.get("units") is Dictionary or not state.base_personnel.get("units") is Dictionary: return _bad()
	var people: Dictionary = state.base_personnel.units
	if people.size() != base.units.size() or not state.ground.get("units") is Array or not state.ground.units.is_empty() or not state.ground.get("active_segments") is Array or not state.ground.active_segments.is_empty() or not state.ground.get("centering") is Array or not state.ground.centering.is_empty(): return _bad()
	for id in people:
		var person: Variant = people[id]
		var legacy: Variant = base.units.get(id)
		if not person is Dictionary or not legacy is Dictionary or person.get("status") != "aboard" or person.get("craft_id") != craft or not person.get("action") is Dictionary or not person.action.is_empty(): return _bad()
		for field in ["status","craft_id","bed_id","auto_rest_enabled","rest_automatic"]:
			if person.get(field) != legacy.get(field): return _bad()
	if state.transport.size() != 1 or not state.transport.get(craft) is Dictionary or state.transport[craft].get("home") != false: return _bad()
	return {"ok":true}

static func _bad() -> Dictionary:
	return {"ok":false,"reason":"active_home_hex_mismatch"}
