extends RefCounted
const Catalog=preload("res://scripts/core/catalog.gd")
const GroundCatalog=preload("res://scripts/core/ground_catalog.gd")
const Numbers=preload("res://scripts/core/legacy_validator_v2.gd")
const Nav=preload("res://scripts/core/ground_navigation.gd")
static func validate(s: Dictionary) -> String:
	if not s.get("rental") is Dictionary:return "Mietstatus fehlt."
	var rental: Dictionary=s.rental
	if not rental.get("active") is bool or not rental.get("expired") is bool or not Numbers.number(rental.get("remaining"),0,1200):return "Mietstatus ungültig."
	if rental.expired!=(rental.active and rental.remaining==0) or (not rental.active and rental.remaining!=0):return "Mietzeit widersprüchlich."
	if s.ship.get("model")!=("vulture" if rental.active else "cutlass") or s.ship.get("name")!=("Geier" if rental.active else "Entersäbel") or s.ship.capacity!=(40 if rental.active else 12):return "Mietschiff widersprüchlich."
	if s.ship.mode=="flying" and not s.region in ["base","station","orbit","rust","space","bunker_surface","distribution","tradepost"]:return "Flug auf dieser Karte ungültig."
	if s.ship.mode=="landed" and not Nav.landing_clear("bunker_surface" if s.region=="bunker_depths" else s.region,s.ship):return "Gelandeter Rumpf in Weltgeometrie."
	if not s.get("resources") is Dictionary or s.resources.size()!=Catalog.resource_sites().size():return "Fundstellen fehlen."
	for id: String in Catalog.resource_sites():
		if not s.resources.get(id) is Dictionary or not Numbers.whole(s.resources[id].get("remaining"),0,Catalog.resource_sites()[id].stock):return "Fundbestand ungültig."
	if not s.get("ground") is Dictionary or not s.ground.get("enemies") is Dictionary or not s.ground.get("activity") is Dictionary:return "Bodenzustand fehlt."
	if s.ground.enemies.size()!=GroundCatalog.REGIONS.size():return "Feindregionen ungültig."
	for region: String in GroundCatalog.REGIONS:
		if not s.ground.enemies.get(region) is Dictionary:return "Feindregion fehlt."
		var enemies: Dictionary=s.ground.enemies[region]
		var expected: Dictionary=Catalog.ground_enemies(region)
		if enemies.size()!=expected.size():return "Feindbestand ungültig."
		for id: String in expected:
			if not enemies.get(id) is Dictionary:return "Feind fehlt."
			var enemy: Dictionary=enemies[id]
			for field: String in ["id","name","kind","max_health"]:
				if enemy.get(field)!=expected[id][field]:return "Feindtyp ungültig."
			if not Numbers.position_valid(enemy.get("position"),Catalog.bounds(region)) or not Numbers.position_valid(enemy.get("target"),Catalog.bounds(region)):return "Feindposition ungültig."
			if not _same(enemy.position,expected[id].position) or not _same(enemy.target,expected[id].target):return "Feindanker ungültig."
			if not Numbers.number(enemy.get("health"),0,enemy.max_health) or not Numbers.number(enemy.get("cooldown"),0,3) or not enemy.get("defeated") is bool or enemy.defeated!=(enemy.health==0):return "Feindgesundheit ungültig."
	var activity: Dictionary=s.ground.activity
	if not activity.get("active") is bool or not activity.get("unit_id") is String or not activity.get("site_id") is String or not activity.get("phase") in ["idle","walking","working"]:return "Gewinnung ungültig."
	if not Numbers.number(activity.get("total"),0,100) or not Numbers.number(activity.get("remaining"),0,100) or activity.remaining>activity.total:return "Gewinnungszeit ungültig."
	if activity.active:
		if not s.crew.has(activity.unit_id) or not Catalog.resource_sites().has(activity.site_id):return "Gewinnungsbindung ungültig."
		var site: Dictionary=Catalog.resource_sites()[activity.site_id]
		var worker: Dictionary=s.crew[activity.unit_id]
		if site.region!=s.region or worker.assignment!="gather" or s.travel.active or s.ship.mode!="landed" or s.resources[activity.site_id].remaining<=0 or activity.phase=="idle":return "Gewinnung widersprüchlich."
		if not is_equal_approx(activity.total,site.duration/Catalog.skill_effects(worker).gather_multiplier) or not _same(worker.target,Catalog.interaction_point(s.region,activity.site_id)):return "Gewinnungsziel/-zeit ungültig."
	elif activity.unit_id!="" or activity.site_id!="" or activity.total!=0 or activity.remaining!=0 or activity.phase!="idle":return "Inaktive Gewinnung inkonsistent."
	for id: String in s.crew:
		var unit: Dictionary=s.crew[id]
		if s.ship.mode=="landed" and unit.assignment!="aboard":
			if not Nav.walkable(s.region,Vector2(unit.position[0],unit.position[1]),s.ship) or not Nav.walkable(s.region,Vector2(unit.target[0],unit.target[1]),s.ship):return "Person innerhalb eines Hindernisses."
		if not unit.equipment.get("armor") in ["","armor"] or not Numbers.number(unit.get("health"),0,100) or not Numbers.number(unit.get("respawn_remaining"),0,20) or not Numbers.number(unit.get("attack_cooldown"),0,1) or not unit.get("attack_target") is String:return "Gesundheit/Ausrüstung ungültig."
		if (unit.health==0)!=(unit.assignment=="downed") or (unit.health>0 and unit.respawn_remaining!=0) or (unit.health==0 and unit.respawn_remaining<=0):return "Verwundung widersprüchlich."
		if unit.assignment=="downed" and (s.travel.active or s.ship.mode!="landed" or not _same(unit.position,unit.target)):return "Verwundete Person im Flug."
		if unit.assignment=="gather" and (not activity.active or activity.unit_id!=id):return "Verwaiste Gewinnungsbindung."
		if not unit.attack_target.is_empty() and (unit.assignment!="idle" or not s.ground.enemies[s.region].has(unit.attack_target)):return "Angriffsziel ungültig."
	return ""
static func _same(a: Array,b: Array) -> bool:
	return is_equal_approx(float(a[0]),float(b[0])) and is_equal_approx(float(a[1]),float(b[1]))
