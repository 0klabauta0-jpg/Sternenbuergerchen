extends RefCounted
## Explicit physical surface locations. Orbit encounters and stations are not
## inferred from their map path or merely from sharing a planetary orbit.
const PATH := "res://data/singleplayer/orbital_surface_locations.json"
static var _catalog: Dictionary = {}

static func contains(body: Dictionary, location_id: String) -> bool:
	var body_id := String(body.get("id", ""))
	if body_id.is_empty() or location_id.is_empty() or String(body.get("kind", "")) == "station": return false
	if _catalog.is_empty():
		var loaded: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		var definitions: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/locations.json"))
		if typeof(loaded) != TYPE_DICTIONARY or typeof(definitions) != TYPE_DICTIONARY: return false
		var seen := {}
		for key in loaded:
			if typeof(key) != TYPE_STRING or String(key).is_empty() or typeof(loaded[key]) != TYPE_ARRAY: return false
			for id in loaded[key]:
				if typeof(id) != TYPE_STRING or String(id).is_empty() or seen.has(id) or typeof(definitions.get(id)) != TYPE_DICTIONARY: return false
				var location: Dictionary = definitions[id]
				var map_path := String(location.get("map_file_path", ""))
				var scenario_path := String(location.get("scenario_file_path", ""))
				if location.get("id") != id or not map_path.begins_with("res://maps/") or not FileAccess.file_exists(map_path): return false
				if not scenario_path.is_empty() and (not scenario_path.begins_with("res://data/mission_scenarios/") or not FileAccess.file_exists(scenario_path)): return false
				if not scenario_path.is_empty():
					var scenario: Variant = JSON.parse_string(FileAccess.get_file_as_string(scenario_path))
					if typeof(scenario) != TYPE_DICTIONARY or scenario.get("map_file_path") != map_path: return false
				seen[id] = true
		_catalog = loaded
	var locations: Variant = _catalog.get(body_id)
	if typeof(locations) != TYPE_ARRAY: return false
	for value in locations:
		if typeof(value) != TYPE_STRING or String(value).is_empty(): return false
	return locations.has(location_id)
