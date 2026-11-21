extends RefCounted
## Pure recovery clock for wounded and respawning campaign personnel. No scene, no state.
## Entries are never modified in place; callers receive copies.
## States: "wounded" (heals to "active"), "respawning" (counts down to "awaiting_pickup"),
## "awaiting_pickup" (does not count; a respawned person never becomes "active" by itself).

const SEVERITY_NAMES := {"light": "leicht", "medium": "mittel", "severe": "schwer"}
const STATE_RESPAWNING := "respawning"
const STATE_AWAITING_PICKUP := "awaiting_pickup"
const DEFAULT_PICKUP_LOCATION := "polisa"

static func _remaining(unit: Dictionary) -> float:
	var state: Variant = unit.get("recovery_state", {})
	if not state is Dictionary:
		return 0.0
	var value: Variant = state.get("seconds_remaining", 0.0)
	if typeof(value) == TYPE_STRING and (value as String).is_valid_float():
		value = (value as String).to_float()
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return 0.0
	return maxf(0.0, float(value))

static func is_wounded(unit: Dictionary) -> bool:
	return str(unit.get("availability_status", "")) == "wounded" and _remaining(unit) > 0.0

## Died and waiting out the outage (the clock runs).
static func is_respawning(unit: Dictionary) -> bool:
	return str(unit.get("availability_status", "")) == STATE_RESPAWNING

## Outage over, waits at the pickup location. Not usable until picked up.
static func is_awaiting_pickup(unit: Dictionary) -> bool:
	return str(unit.get("availability_status", "")) == STATE_AWAITING_PICKUP

## Not usable for a mission: wounded with time left, respawning or awaiting pickup.
static func is_blocked(unit: Dictionary) -> bool:
	return is_wounded(unit) or is_respawning(unit) or is_awaiting_pickup(unit)

static func _pickup_location(unit: Dictionary) -> String:
	var state: Variant = unit.get("recovery_state", {})
	if state is Dictionary:
		var value: Variant = (state as Dictionary).get("pickup_location_id", DEFAULT_PICKUP_LOCATION)
		if typeof(value) == TYPE_STRING and not (value as String).strip_edges().is_empty():
			return (value as String).strip_edges()
	return DEFAULT_PICKUP_LOCATION

static func _to_awaiting_pickup(unit: Dictionary) -> void:
	unit["recovery_state"] = {"state": STATE_AWAITING_PICKUP, "pickup_location_id": _pickup_location(unit)}
	unit["availability_status"] = STATE_AWAITING_PICKUP
	unit["status_text"] = STATE_AWAITING_PICKUP

## "matured_unit_ids": respawning -> awaiting_pickup in this call (not a recovery, no full view rebuild needed).
static func advance(units: Array, delta_seconds: float) -> Dictionary:
	var result_units: Array = []
	var changed := false
	var recovered := PackedStringArray()
	var matured := PackedStringArray()
	for entry in units:
		var status: String = str(entry.get("availability_status", "")) if entry is Dictionary else ""
		if status == STATE_RESPAWNING:
			var respawner: Dictionary = (entry as Dictionary).duplicate(true)
			var left := _remaining(respawner)
			if left <= 0.0:
				# Broken or legacy respawn data counts as over (never as active).
				_to_awaiting_pickup(respawner)
				matured.append(str(respawner.get("unit_id", "")))
				changed = true
			elif delta_seconds > 0.0:
				left = maxf(0.0, left - delta_seconds)
				changed = true
				if left <= 0.0:
					_to_awaiting_pickup(respawner)
					matured.append(str(respawner.get("unit_id", "")))
				else:
					var respawn_state: Dictionary = respawner["recovery_state"]
					respawn_state["seconds_remaining"] = left
					respawner["recovery_state"] = respawn_state
			result_units.append(respawner)
			continue
		if status != "wounded":
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
		return {"units": units.duplicate(), "changed": false, "recovered_unit_ids": PackedStringArray(), "matured_unit_ids": PackedStringArray()}
	return {"units": result_units, "changed": changed, "recovered_unit_ids": recovered, "matured_unit_ids": matured}

## m:ss, from one hour on h:mm:ss.
static func format_clock(seconds: float) -> String:
	var whole := int(floor(maxf(0.0, seconds)))
	if whole >= 3600:
		return "%d:%02d:%02d" % [floori(whole / 3600.0), floori((whole % 3600) / 60.0), whole % 60]
	return "%d:%02d" % [floori(whole / 60.0), whole % 60]

static func describe(unit: Dictionary) -> String:
	if is_respawning(unit):
		return "gestorben, Respawn in %s" % format_clock(_remaining(unit))
	if is_awaiting_pickup(unit):
		return "wartet auf %s" % _pickup_location(unit).capitalize()
	if not is_wounded(unit):
		return ""
	var severity := str(Dictionary(unit.get("recovery_state", {})).get("severity", ""))
	var label := str(SEVERITY_NAMES.get(severity, severity))
	var whole := int(floor(_remaining(unit)))
	return "Verwundet (%s), noch %d:%02d" % [label, floori(whole / 60.0), whole % 60]
