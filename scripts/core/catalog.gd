extends RefCounted
class_name RestartCatalog
const Regions=preload("res://scripts/core/regions.gd")
const TradeRoutes=preload("res://scripts/core/trade_routes.gd")
const Layout=preload("res://scripts/core/world_layout.gd")
const Gear=preload("res://scripts/core/equipment_catalog.gd")
const Ground=preload("res://scripts/core/ground_catalog.gd")
const ITEMS: Array[String] = ["scrap","parts","toolkit","cutter","blackbox","helmet","armor","ore","alloy","backpack","multitool","mining_attachment","salvage_attachment","medgun","med_charge","repair_attachment"]
const WALK_SPEED: float = 6.0
static func item_name(id: String) -> String:
	return {"scrap":"Metall","parts":"Bauteile","toolkit":"Werkzeugkit","cutter":"Schneider","blackbox":"Blackbox","helmet":"Schutzhelm","armor":"Schutzrüstung","ore":"Erz","alloy":"Schiffslegierung"}.get(id,Gear.names().get(id,id))
static func recipes() -> Dictionary:
	var result: Dictionary={
		"armor":{"label":"Schutzrüstung","materials":{"scrap":3,"parts":2},"duration":10.0,"min_skill":2,"tier":1,"output":{"armor":1}},
		"toolkit":{"label":"Werkzeugkoffer","materials":{"scrap":2,"parts":1},"duration":6.0,"min_skill":2,"tier":1,"output":{"toolkit":1}},
		"repair":{"label":"Shuttle reparieren","materials":{"scrap":2,"parts":1},"duration":8.0,"min_skill":2,"tier":1,"output":{}},
		"helmet":{"label":"Helm aufarbeiten","materials":{"scrap":1,"parts":1},"duration":5.0,"min_skill":2,"tier":1,"output":{"helmet":1}},
		"cutter":{"label":"Schneidwerkzeug","materials":{"scrap":3,"parts":2},"duration":10.0,"min_skill":3,"tier":2,"output":{"cutter":1}},
		"upgrade_workbench":{"label":"Werkbank Stufe 2","materials":{"scrap":3,"parts":1},"duration":12.0,"min_skill":3,"tier":1,"output":{}}
	}
	result.merge(Gear.recipes());return result
static func prices(region: String="") -> Dictionary:
	var result: Dictionary={"scrap":{"buy":12,"sell":6},"parts":{"buy":35,"sell":18},"toolkit":{"buy":90,"sell":50},"cutter":{"buy":150,"sell":85},"helmet":{"buy":60,"sell":30},"armor":{"buy":220,"sell":110},"ore":{"buy":55,"sell":35},"alloy":{"buy":160,"sell":120}}
	result.merge(Gear.prices());result.merge(TradeRoutes.overrides(region),true);return result
static func profiles() -> Dictionary:
	return {"ida":{"name":"Ida","skills":{"pilot":3,"gunnery":1,"tech":3},"equipment":{"helmet":"basic_helmet","tool":""}},"jaro":{"name":"Jaro","skills":{"pilot":1,"gunnery":3,"tech":1},"equipment":{"helmet":"basic_helmet","tool":""}}}
static func rooms() -> Dictionary:return Layout.rooms()
static func landmarks(region: String) -> Dictionary:return Layout.landmarks(region)
static func bounds(region: String) -> float:return Layout.bounds(region)
static func interaction_point(region: String,object_id: String) -> Array:
	var points: Dictionary=landmarks(region)
	if not points.has(object_id):return []
	var point: Array=points[object_id].duplicate()
	var resource_id: String=object_id
	object_id=Regions.object_base(object_id)
	if object_id=="workbench":point[1]+=1.3
	elif object_id=="storage":point[1]+=2.0
	elif object_id=="satellite":point[1]+=4.8
	elif object_id in ["mining_site","derelict","distribution_wreck"]:point[1]+=8.5
	elif Ground.sites().has(resource_id):point[1]+=3.2
	elif object_id in ["contracts","office"]:point[1]+=1.8
	elif object_id=="market":point[1]+=2.7
	elif object_id.begins_with("bed_"):point[1]+=2.1
	return point
static func radar_contacts() -> Array:
	return [{"id":"signal_01","position":[145.0,-125.0],"identified":false,"label":"Unbekanntes Signal","kind":"unknown"},{"id":"signal_02","position":[-300.0,-210.0],"identified":false,"label":"Unbekanntes Signal","kind":"unknown"},{"id":"signal_03","position":[310.0,250.0],"identified":false,"label":"Unbekanntes Signal","kind":"unknown"}]

static func obstacles(region: String) -> Dictionary:return Layout.obstacles(region)
static func ground_enemies(region: String) -> Dictionary:return Ground.enemies(region)
static func resource_sites() -> Dictionary:return Ground.sites()
static func skill_effects(unit: Dictionary) -> Dictionary:return Ground.skill_effects(unit)

static func ship_profile(model: String) -> Dictionary:return Layout.ship_profile(model)
static func ship_access(ship: Dictionary) -> Array:
	var offset: Array=ship_profile(ship.model).access
	return [ship.position[0]+offset[0],ship.position[1]+offset[1]]
static func navigation_obstacles(region: String,ship: Dictionary={}) -> Dictionary:
	var result: Dictionary=obstacles(region).duplicate(true)
	if not ship.is_empty() and ship.get("mode")=="landed" and not region in ["orbit","space"] and not Regions.underground(region):
		result["_ship"]={"center":ship.position.duplicate(),"size":ship_profile(ship.model).size.duplicate()}
	return result
static func arrival_point(region: String) -> Array:return [-bounds(region)+25.0,bounds(region)-25.0]
static func travel_risk(destination: String) -> int:return Regions.risk(destination)
static func destination_info() -> Dictionary:
	var result: Dictionary={}
	for id: String in Regions.DESTINATIONS:
		result[id]={"label":Regions.LABELS[id],"risk":travel_risk(id)}
	return result
