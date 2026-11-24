extends RefCounted
## Value set per flight environment (space / atmosphere). Pure data lookup:
## the file is read once and cached, nothing is read per tick.

const CATALOG_PATH := "res://data/space/flight_environments.json"
const FACTOR_KEYS := ["speed_factor", "acceleration_factor", "weapon_range_factor"]

static var _catalog: Dictionary = {}
static var _catalog_loaded := false
static var _warned: Dictionary = {}

static func environment_for_area(area_id: String) -> String:
	return "atmosphere" if area_id.begins_with("atmosphere:") else "space"

static func factors(environment: String) -> Dictionary:
	if not _catalog_loaded:
		_load_catalog()
	var entry: Variant = _catalog.get(environment)
	if typeof(entry) == TYPE_DICTIONARY:
		var result := {}
		for key in FACTOR_KEYS:
			var value: Variant = entry.get(key)
			if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)) or float(value) <= 0.0:
				return _fallback("invalid %s for environment '%s'" % [key, environment], environment)
			result[key] = float(value)
		return result
	return _fallback("unknown environment '%s'" % environment, environment)

static func weapon_range(base_range: float, area_id: String) -> float:
	if environment_for_area(area_id) == "space":
		return base_range
	return base_range * float(factors("atmosphere").weapon_range_factor)

static func _fallback(reason: String, environment: String) -> Dictionary:
	if not _warned.has(environment):
		_warned[environment] = true
		push_warning("flight_environment: %s, using factors 1.0" % reason)
	return {"speed_factor": 1.0, "acceleration_factor": 1.0, "weapon_range_factor": 1.0}

static func _load_catalog() -> void:
	_catalog_loaded = true
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		_catalog = parsed
