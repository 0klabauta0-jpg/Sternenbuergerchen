extends RefCounted
const Regions=preload("res://scripts/core/regions.gd")
const REGIONS=Regions.ALL
const DESTINATIONS=Regions.DESTINATIONS
static func landmarks(region: String) -> Dictionary:
	match region:
		"bunker_surface":return {"shuttle":[-65.0,70.0],"bunker_entry":[0.0,12.0],"aa_turret":[28.0,-12.0],"surface_cache":[-34.0,-15.0]}
		"bunker_depths":return {"elevator":[0.0,36.0],"bunker_cache":[-26.0,-8.0],"bunker_terminal":[26.0,-8.0]}
		"distribution":return {"shuttle":[-110.0,120.0],"market":[-25.0,20.0],"distribution_cache":[45.0,-35.0],"distribution_wreck":[90.0,15.0]}
		"tradepost":return {"shuttle":[-45.0,50.0],"market":[0.0,0.0],"tradepost_cache":[150.0,-120.0]}
	return {}
static func sites() -> Dictionary:
	var result:=_sites()
	for region: String in Regions.ALL:
		if region==Regions.archetype(region):continue
		for id: String in _sites():
			var site: Dictionary=_sites()[id]
			if site.region!=Regions.archetype(region):continue
			site.region=region;site.stock*=Regions.difficulty(region)
			result[Regions.object_id(region,id)]=site
	return result
static func _sites() -> Dictionary:
	return {
		"mining_site":{"region":"rust","item":"ore","stock":24,"duration":8.0,"yield":3},
		"derelict":{"region":"rust","item":"alloy","stock":18,"duration":10.0,"yield":2},
		"surface_cache":{"region":"bunker_surface","item":"parts","stock":4,"duration":5.0,"yield":2},
		"bunker_cache":{"region":"bunker_depths","item":"alloy","stock":8,"duration":5.0,"yield":2},
		"bunker_terminal":{"region":"bunker_depths","item":"parts","stock":6,"duration":5.0,"yield":2},
		"distribution_cache":{"region":"distribution","item":"alloy","stock":12,"duration":6.0,"yield":3},
		"distribution_wreck":{"region":"distribution","item":"scrap","stock":24,"duration":8.0,"yield":4},
		"tradepost_cache":{"region":"tradepost","item":"parts","stock":6,"duration":5.0,"yield":2}}
static func enemies(region: String) -> Dictionary:
	if Regions.family(region)=="distribution_friendly":return {}
	var result:=_enemies(Regions.archetype(region))
	var level:=Regions.difficulty(region)
	if Regions.bunker(region):
		if level>=2:result["reserve_guard"]=_enemy("reserve_guard","Reservewache","guard",[-26.0,-12.0] if Regions.underground(region) else [-36.0,20.0])
		if level>=3:
			result["veteran_guard"]=_enemy("veteran_guard","Veteranenwache","guard",[26.0,15.0] if Regions.underground(region) else [42.0,25.0])
			result["rear_guard"]=_enemy("rear_guard","Rückraumwache","guard",[0.0,-36.0] if Regions.underground(region) else [-10.0,-18.0])
		for enemy: Dictionary in result.values():
			enemy.max_health+=15.0*(level-1);enemy.health=enemy.max_health
			for field: String in ["position","target"]:enemy[field]=[enemy[field][0]*Regions.depth_scale(region),enemy[field][1]*Regions.depth_scale(region)]
	return result
static func _enemies(region: String) -> Dictionary:
	match region:
		"bunker_surface":return {"aa_turret":_enemy("aa_turret","Flakgeschütz","aa",[28.0,-12.0]),"surface_guard":_enemy("surface_guard","Bunkerwache","guard",[-12.0,-5.0])}
		"bunker_depths":return {"depth_guard":_enemy("depth_guard","Sicherheitswache","guard",[24.0,0.0])}
		"distribution":return {"depot_guard":_enemy("depot_guard","Depotwache","guard",[35.0,-20.0]),"dock_guard":_enemy("dock_guard","Dockwache","guard",[78.0,5.0])}
	return {}
static func _enemy(id: String,label: String,kind: String,at: Array) -> Dictionary:
	return {"id":id,"name":label,"kind":kind,"position":at.duplicate(),"target":at.duplicate(),"health":90.0 if kind=="aa" else 45.0,"max_health":90.0 if kind=="aa" else 45.0,"cooldown":2.0,"defeated":false}
static func obstacles(region: String) -> Dictionary:
	match region:
		"rust":return {"rust_ridge":{"center":[122.0,-92.0],"size":[16.0,8.0]}}
		"bunker_surface":return {"bunker_back":{"center":[0.0,-29.0],"size":[48.0,2.0]},"bunker_left":{"center":[-24.0,-9.0],"size":[2.0,38.0]},"bunker_right":{"center":[24.0,4.0],"size":[2.0,12.0]}}
		"bunker_depths":return {"west_south":{"center":[-8.0,13.5],"size":[1.0,21.0]},"west_north":{"center":[-8.0,-13.5],"size":[1.0,21.0]},"east_south":{"center":[8.0,13.5],"size":[1.0,21.0]},"east_north":{"center":[8.0,-13.5],"size":[1.0,21.0]}}
		"distribution":return {"depot_stack_a":{"center":[10.0,0.0],"size":[16.0,24.0]},"depot_stack_b":{"center":[60.0,25.0],"size":[18.0,12.0]},"depot_stack_c":{"center":[-55.0,-35.0],"size":[24.0,16.0]},"security_back":{"center":[50.0,-56.0],"size":[36.0,1.0]},"security_side":{"center":[68.0,-44.0],"size":[1.0,24.0]},"market_back":{"center":[-27.0,15.0],"size":[26.0,1.0]}}
		"tradepost":return {"outpost_store":{"center":[14.0,-8.0],"size":[8.0,10.0]},"market_back":{"center":[-3.0,-12.5],"size":[23.0,1.0]}}
	return {}
static func skill_effects(unit: Dictionary) -> Dictionary:
	var tool: String=unit.equipment.tool
	return {"ground_damage":10.0+2.0*unit.skills.gunnery,"turret_damage":7.0+unit.skills.gunnery,"flight_multiplier":1.0+0.04*unit.skills.pilot,"gather_multiplier":(1.0+0.1*unit.skills.tech)*(1.35 if tool=="cutter" else (1.2 if tool=="toolkit" else (1.25 if tool=="multitool" and not unit.equipment.get("attachment","").is_empty() else 1.0))),"armor_reduction":(0.35 if unit.equipment.get("armor","")=="armor" else 0.0)+(0.05 if unit.equipment.helmet=="helmet" else 0.0),"tech_level":unit.skills.tech}
