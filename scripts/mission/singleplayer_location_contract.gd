extends RefCounted
## Pure authored-place validation; places never imply active missions.

static func normalize_location(raw: Dictionary) -> Dictionary:
	var id: String = String(raw.get("id", raw.get("location_id", ""))).strip_edges()
	var position: Variant = raw.get("region_position", [])
	if id.is_empty() or String(raw.get("name", "")).strip_edges().is_empty() or typeof(position) != TYPE_ARRAY or position.size() != 2:
		return {}
	for coordinate in position:
		if not typeof(coordinate) in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(coordinate)):
			return {}
	var map_path: String = String(raw.get("map_file_path", ""))
	var scenario_path: String = String(raw.get("scenario_file_path", ""))
	if not map_path.begins_with("res://maps/") or not map_path.ends_with(".json") or (not scenario_path.is_empty() and (not scenario_path.begins_with("res://data/mission_scenarios/") or not scenario_path.ends_with(".json"))):
		return {}
	if typeof(raw.get("landing_pad_ids")) != TYPE_ARRAY or typeof(raw.get("services")) != TYPE_ARRAY:
		return {}
	var pads: Array = []
	for pad in raw.landing_pad_ids:
		if typeof(pad) != TYPE_STRING or String(pad).strip_edges().is_empty() or pads.has(pad):
			return {}
		pads.append(pad)
	if pads.is_empty():
		return {}
	var services: Array = []
	for service in raw.services:
		if typeof(service) != TYPE_STRING or String(service).strip_edges().is_empty():
			return {}
		if not services.has(service):
			services.append(service)
	return {"id": id, "name": String(raw.name), "region_position": position.duplicate(), "map_file_path": map_path, "scenario_file_path": scenario_path, "landing_pad_ids": pads, "services": services}
