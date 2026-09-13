extends RefCounted
class_name RestartCatalog
const ITEMS: Array[String] = ["scrap","parts","toolkit","cutter","blackbox","helmet"]
const WALK_SPEED: float = 6.0
static func item_name(id: String) -> String:
	return {"scrap":"Metall","parts":"Bauteile","toolkit":"Werkzeugkit","cutter":"Schneider","blackbox":"Blackbox","helmet":"Schutzhelm"}.get(id,id)
static func recipes() -> Dictionary:
	return {
		"toolkit":{"label":"Werkzeugkoffer","materials":{"scrap":2,"parts":1},"duration":6.0,"min_skill":2,"tier":1,"output":{"toolkit":1}},
		"repair":{"label":"Shuttle reparieren","materials":{"scrap":2,"parts":1},"duration":8.0,"min_skill":2,"tier":1,"output":{}},
		"helmet":{"label":"Helm aufarbeiten","materials":{"scrap":1,"parts":1},"duration":5.0,"min_skill":2,"tier":1,"output":{"helmet":1}},
		"cutter":{"label":"Schneidwerkzeug","materials":{"scrap":3,"parts":2},"duration":10.0,"min_skill":3,"tier":2,"output":{"cutter":1}},
		"upgrade_workbench":{"label":"Werkbank Stufe 2","materials":{"scrap":3,"parts":1},"duration":12.0,"min_skill":3,"tier":1,"output":{}}
	}
static func prices() -> Dictionary:
	return {"scrap":{"buy":12,"sell":6},"parts":{"buy":35,"sell":18},"toolkit":{"buy":90,"sell":50},"cutter":{"buy":150,"sell":85},"helmet":{"buy":60,"sell":30}}
static func profiles() -> Dictionary:
	return {"ida":{"name":"Ida","skills":{"pilot":3,"gunnery":1,"tech":3},"equipment":{"helmet":"basic_helmet","tool":""}},"jaro":{"name":"Jaro","skills":{"pilot":1,"gunnery":3,"tech":1},"equipment":{"helmet":"basic_helmet","tool":""}}}
static func rooms() -> Dictionary:
	return {"quarters":{"label":"Unterkunft","center":[-10.0,-12.0],"size":[12.0,12.0],"door":[-4.0,-10.0]},"storage":{"label":"Lager","center":[-10.0,3.0],"size":[12.0,12.0],"door":[-4.0,3.0]},"workshop":{"label":"Werkstatt","center":[10.0,3.0],"size":[12.0,12.0],"door":[4.0,3.0]},"lounge":{"label":"Aufenthalt","center":[8.0,-12.0],"size":[12.0,12.0],"door":[2.0,-10.0]}}
static func landmarks(region: String) -> Dictionary:
	match region:
		"base":return {"workbench":[10.0,3.0],"storage":[-10.0,3.0],"contracts":[10.0,-14.0],"shuttle":[25.0,22.0],"bed_ida":[-12.0,-14.0],"bed_jaro":[-8.0,-14.0],"kitchen":[5.0,-12.0],"expansion_a":[27.0,-12.0],"expansion_b":[27.0,3.0]}
		"rust":return {"shuttle":[-210.0,180.0],"satellite":[145.0,-125.0]}
		"station":return {"shuttle":[0.0,28.0],"market":[-12.0,-8.0]}
		"space":return {}
	return {}
static func bounds(region: String) -> float:
	return {"base":160.0,"rust":320.0,"station":80.0,"space":240.0}.get(region,50.0)
static func interaction_point(region: String,object_id: String) -> Array:
	var points: Dictionary=landmarks(region)
	if not points.has(object_id):return []
	var point: Array=points[object_id].duplicate()
	if object_id=="workbench":point[1]+=1.3
	elif object_id=="satellite":point[1]+=3.8
	return point
static func radar_contacts() -> Array:
	return [{"id":"signal_01","position":[145.0,-125.0],"identified":false,"label":"Unbekanntes Signal","kind":"unknown"},{"id":"signal_02","position":[-55.0,-175.0],"identified":false,"label":"Unbekanntes Signal","kind":"unknown"},{"id":"signal_03","position":[90.0,155.0],"identified":false,"label":"Unbekanntes Signal","kind":"unknown"}]
