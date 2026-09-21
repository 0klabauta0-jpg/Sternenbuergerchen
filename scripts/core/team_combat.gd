extends RefCounted
## Cross-team combat owns no UI state and never awards NPC farming credits.
const Catalog=preload("res://scripts/core/catalog.gd")
const Nav=preload("res://scripts/core/ground_navigation.gd")
var orders:Dictionary={}
static func same_area(cores:Array[Node],planets:Array[String]) -> bool:
	var a:Dictionary=cores[0]._state;var b:Dictionary=cores[1]._state
	if a.travel.active or b.travel.active or a.region!=b.region or a.region in ["base","space"]:return false
	return a.region=="station" or planets[0]==planets[1]
func attack(cores:Array[Node],planets:Array[String],team:int,unit_id:String,target:String) -> String:
	var state:Dictionary=cores[team]._state
	if not state.crew.has(unit_id):return "Eigene Person nicht gefunden."
	var key:=str(team)+":"+unit_id
	if target.is_empty():orders.erase(key);state.crew[unit_id].target=state.crew[unit_id].position.duplicate();return ""
	var bits:=target.split(":")
	if bits.size()!=2 or bits[0]!="team%d"%(1-team) or not cores[1-team]._state.crew.has(bits[1]):return "Nur gegnerische Einheiten sind gültige Ziele."
	if not same_area(cores,planets):return "Gegner befindet sich nicht auf dieser Karte."
	var actor:Dictionary=state.crew[unit_id];var enemy:Dictionary=cores[1-team]._state.crew[bits[1]]
	if actor.get("level_region",state.region)!=enemy.get("level_region",state.region):return "Gegner auf anderer Ebene."
	if actor.health<=0 or actor.assignment!="idle" or enemy.health<=0 or enemy.assignment=="aboard" or state.ship.mode!="landed":return "Kein verfügbarer Bodenkämpfer oder Gegner."
	orders[key]={"team":team,"unit":unit_id,"target":str(bits[1])}
	return ""
func cancel(team:int,unit:String) -> void:orders.erase(str(team)+":"+unit)
func tick(cores:Array[Node],planets:Array[String],_delta:float) -> void:
	for key:String in orders.keys():
		var order:Dictionary=orders[key];var team:=int(order.team)
		var state:Dictionary=cores[team]._state;var other:Dictionary=cores[1-team]._state
		var actor:Dictionary=state.crew[order.unit];var enemy:Dictionary=other.crew[order.target]
		if actor.get("level_region",state.region)!=enemy.get("level_region",other.region) or not same_area(cores,planets) or actor.health<=0 or enemy.health<=0 or actor.assignment!="idle" or enemy.assignment=="aboard" or state.ship.mode!="landed":orders.erase(key);continue
		var from:=Vector2(actor.position[0],actor.position[1]);var to:=Vector2(enemy.position[0],enemy.position[1])
		var level:String=actor.get("level_region",state.region)
		if from.distance_to(to)>24 or not Nav.clear(level,from,to,state.ship):
			var approach:=Nav.safe_near(level,to,state.ship)
			actor.target=[approach.x,approach.y];continue
		actor.target=actor.position.duplicate()
		if float(actor.attack_cooldown)>0:continue
		actor.attack_cooldown=1.0
		var damage:float=Catalog.skill_effects(actor).ground_damage*(1.0-Catalog.skill_effects(enemy).armor_reduction)
		enemy.health=maxf(0,enemy.health-damage)
		if enemy.health<=0:
			cores[1-team]._cancel_unit_tasks(str(order.target))
			if other.ground.activity.active and other.ground.activity.unit_id==order.target:cores[1-team]._ground.stop_activity()
			enemy.assignment="downed";enemy.respawn_remaining=20.0;enemy.attack_target="";enemy.target=enemy.position.duplicate()
			orders.erase(key);cancel(1-team,str(order.target))
func project(state:Dictionary,cores:Array[Node],planets:Array[String],team:int) -> void:
	if not same_area(cores,planets):return
	for id:String in cores[1-team]._state.crew:
		var unit:Dictionary=cores[1-team]._state.crew[id]
		if unit.assignment=="aboard":continue
		var key:="team%d:%s"%[1-team,id]
		state.ground.enemies[unit.get("level_region",state.region)][key]={"id":key,"kind":"guard","name":"Team %d · %s"%[2-team,unit.name],"health":unit.health,"max_health":100,"position":unit.position.duplicate(),"target":unit.target.duplicate(),"defeated":unit.health<=0,"cooldown":unit.attack_cooldown,"team":1-team}
	for j:Dictionary in cores[1-team]._state.get("hauling",{"jobs":[]}).jobs:
		if int(j.held)>0 and not str(j.unit).is_empty():
			var unit:Dictionary=cores[1-team]._state.crew[j.unit]
			var key:String="team%d:%s"%[1-team,j.unit]
			state.ground.enemies[unit.get("level_region",state.region)][key].carrying=j.item
	for id:String in state.crew:
		var key:=str(team)+":"+id
		if orders.has(key):state.crew[id].attack_target="team%d:%s"%[1-team,orders[key].target]
func validate(value:Variant,cores:Array[Node]) -> bool:
	if not value is Dictionary or value.size()>4:return false
	for key:Variant in value:
		var order:Variant=value[key]
		if not order is Dictionary or not preload("res://scripts/core/save_validator.gd").whole(order.get("team"),0,1) or not order.get("unit") in ["ida","jaro"] or not order.get("target") in ["ida","jaro"]:return false
		if key!=str(int(order.team))+":"+str(order.unit) or not cores[int(order.team)]._state.crew.has(order.unit):return false
	return true
