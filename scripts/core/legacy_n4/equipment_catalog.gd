extends RefCounted
const ITEMS: Array[String]=["backpack","multitool","mining_attachment","salvage_attachment","medgun","med_charge"]
const SLOTS: Array[String]=["helmet","armor","tool","backpack","attachment"]
static func names() -> Dictionary:
	return {"backpack":"Rucksack","multitool":"Multi-Tool","mining_attachment":"Mining-Aufsatz","salvage_attachment":"Berge-Aufsatz","medgun":"Medgun","med_charge":"Med-Ladung"}
static func slot_for(item: String) -> String:
	if item in ["helmet","armor","backpack"]:return item
	if item in ["toolkit","cutter","multitool","medgun"]:return "tool"
	if item in ["mining_attachment","salvage_attachment"]:return "attachment"
	return ""
static func prices() -> Dictionary:
	return {"backpack":{"buy":70,"sell":35},"multitool":{"buy":90,"sell":45},"mining_attachment":{"buy":35,"sell":17},"salvage_attachment":{"buy":35,"sell":17},"medgun":{"buy":150,"sell":75},"med_charge":{"buy":12,"sell":6}}
static func recipes() -> Dictionary:
	return {"backpack":_recipe("Rucksack",2,1,6,1,{"backpack":1}),"multitool":_recipe("Multi-Tool",2,1,8,2,{"multitool":1}),"mining_attachment":_recipe("Mining-Aufsatz",1,1,5,1,{"mining_attachment":1}),"salvage_attachment":_recipe("Berge-Aufsatz",1,1,5,1,{"salvage_attachment":1}),"medgun":_recipe("Medgun",2,2,10,2,{"medgun":1}),"med_charge":_recipe("Med-Ladungen",0,1,5,1,{"med_charge":3})}
static func _recipe(label: String,scrap: int,parts: int,duration: float,skill: int,output: Dictionary) -> Dictionary:
	var materials: Dictionary={"parts":parts}
	if scrap>0:materials.scrap=scrap
	return {"label":label,"materials":materials,"duration":duration,"min_skill":skill,"tier":1,"output":output}
