extends RefCounted
## Pure recovery clock for wounded campaign personnel. No scene, no state.
## Entries are never modified in place; callers receive copies.

const SEVERITY_NAMES := {"light": "leicht", "medium": "mittel", "severe": "schwer"}

static func _remaining(unit: Dictionary) -> float:
	var state: Variant = unit.get("recovery_state", {})
	if not state is Dictionary:
		return 0.0
	var value: Variant = state.get("seconds_remaining", 0.0)
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return 0.0
	return maxf(0.0, float(value))

static func is_wounded(unit: Dictionary) -> bool:
	return str(unit.get("availability_status", "")) == "wounded" and _remaining(unit) > 0.0

static func advance(units: Array, delta_seconds: float) -> Dictionary:
	var result_units: Array = []
	var changed := false
	var recovered := PackedStringArray()
	for entry in units:
		if not entry is Dictionary or str(entry.get("availability_status", "")) != "wounded":
			result_units.append(entry)
			continue
		var unit: Dictionary = (entry as Dictionary).duplicate(true)
		var remaining := _remaining(unit)
		if remaining <= 0.0:
			# Legacy or broken wound data counts as healed.
			unit["availability_status"] = "active"
			unit["recovery_state"] = {}
			unit["status_text"] = ""
			recovered.append(str(unit.get("unit_id", "")))
			changed = true
		elif delta_seconds > 0.0:
			remaining = maxf(0.0, remaining - delta_seconds)
			changed = true
			if remaining <= 0.0:
				unit["availability_status"] = "active"
				unit["recovery_state"] = {}
				unit["status_text"] = ""
				recovered.append(str(unit.get("unit_id", "")))
			else:
				var state: Dictionary = unit["recovery_state"]
				state["seconds_remaining"] = remaining
				unit["recovery_state"] = state
		result_units.append(unit)
	if delta_seconds <= 0.0:
		return {"units": units.duplicate(), "changed": false, "recovered_unit_ids": PackedStringArray()}
	return {"units": result_units, "changed": changed, "recovered_unit_ids": recovered}

static func describe(unit: Dictionary) -> String:
	if not is_wounded(unit):
		return ""
	var severity := str(Dictionary(unit.get("recovery_state", {})).get("severity", ""))
	var label := str(SEVERITY_NAMES.get(severity, severity))
	var whole := int(floor(_remaining(unit)))
	return "Verwundet (%s), noch %d:%02d" % [label, floori(whole / 60.0), whole % 60]
