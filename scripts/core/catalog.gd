extends RefCounted
class_name RestartCatalog

const ITEMS: Array[String] = ["scrap", "parts", "toolkit", "cutter", "blackbox"]
const WALK_SPEED: float = 6.0

static func item_name(id: String) -> String:
	return {"scrap":"Metall","parts":"Bauteile","toolkit":"Werkzeugkit","cutter":"Schneider","blackbox":"Blackbox"}.get(id,id)

static func recipes() -> Dictionary:
	return {
		"toolkit": {"label":"Werkzeugkoffer", "materials":{"scrap":2,"parts":1}, "duration":6.0, "min_skill":2, "output":{"toolkit":1}},
		"repair": {"label":"Shuttle reparieren", "materials":{"scrap":2,"parts":1}, "duration":8.0, "min_skill":2, "output":{}},
		"cutter": {"label":"Schneidwerkzeug", "materials":{"scrap":3,"parts":2}, "duration":10.0, "min_skill":3, "output":{"cutter":1}}
	}

static func prices() -> Dictionary:
	return {"scrap":{"buy":12,"sell":6},"parts":{"buy":35,"sell":18},"toolkit":{"buy":90,"sell":50},"cutter":{"buy":150,"sell":85}}

static func landmarks(region: String) -> Dictionary:
	match region:
		"base": return {"workbench":[3.0,-1.0],"storage":[-4.0,-1.0],"contracts":[-2.0,-5.0],"shuttle":[13.0,8.0],"bed_ida":[-5.0,-7.0],"bed_jaro":[-2.0,-7.0]}
		"rust": return {"shuttle":[-45.0,32.0],"satellite":[22.0,-15.0]}
		"station": return {"shuttle":[0.0,8.0],"market":[0.0,-3.0]}
	return {}

static func bounds(region: String) -> float:
	return 140.0 if region == "rust" else 50.0

static func interaction_point(region: String, object_id: String) -> Array:
	var points: Dictionary = landmarks(region)
	if not points.has(object_id): return []
	var point: Array = points[object_id].duplicate()
	if object_id == "workbench": point[1] += 1.3
	elif object_id == "satellite": point[1] += 3.8
	return point
