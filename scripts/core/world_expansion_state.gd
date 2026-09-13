extends RefCounted
const Catalog=preload("res://scripts/core/catalog.gd")
const Regions=preload("res://scripts/core/regions.gd")
const Nav=preload("res://scripts/core/ground_navigation.gd")
static func extend(s: Dictionary) -> void:
	s.schema_version=5
	for item: String in Catalog.ITEMS:
		if not s.inventory.has(item):s.inventory[item]=0
		if not s.cargo.has(item):s.cargo[item]=0
		for unit: Dictionary in s.crew.values():
			if not unit.backpack.items.has(item):unit.backpack.items[item]=0
	if not s.blueprints.has("repair_attachment"):s.blueprints.append("repair_attachment")
	for region: String in Regions.ALL:
		if not s.ground.enemies.has(region):s.ground.enemies[region]=Catalog.ground_enemies(region)
	for id: String in Catalog.resource_sites():
		if not s.resources.has(id):s.resources[id]={"remaining":Catalog.resource_sites()[id].stock}
static func migrate(payload: Dictionary) -> Dictionary:
	var result: Dictionary=payload.duplicate(true);var s: Dictionary=result.state
	extend(s);result.schema_version=5
	# N4's underground geometry doubles, preserving relative crew/enemy positions.
	for enemy: Dictionary in s.ground.enemies.bunker_depths.values():
		for field: String in ["position","target"]:enemy[field]=[enemy[field][0]*2.0,enemy[field][1]*2.0]
	if s.region=="bunker_depths":
		for unit: Dictionary in s.crew.values():
			for field: String in ["position","target"]:unit[field]=[unit[field][0]*2.0,unit[field][1]*2.0]
	# New terrain may cover old free-flight landing points: relocate only as needed.
	if s.ship.mode=="landed":
		var ship_region: String=Regions.surface(s.region)
		if not Nav.landing_clear(ship_region,s.ship):
			var origin:=Vector2(s.ship.position[0],s.ship.position[1]);var found:=false
			for radius in range(1,180):
				if found:break
				for step in 32:
					var at:=origin+Vector2.from_angle(step*TAU/32.0)*radius
					var candidate: Dictionary=s.ship.duplicate(true);candidate.position=[at.x,at.y]
					if Nav.landing_clear(ship_region,candidate):s.ship.position=candidate.position;s.ship.target=candidate.position.duplicate();found=true;break
		for unit: Dictionary in s.crew.values():
			if unit.assignment=="aboard":unit.position=s.ship.position.duplicate();unit.target=unit.position.duplicate();continue
			var safe:=Nav.safe_near(s.region,Vector2(unit.position[0],unit.position[1]),s.ship)
			unit.position=[safe.x,safe.y]
			if unit.assignment=="boarding":unit.target=Catalog.ship_access(s.ship)
			elif unit.assignment=="gather":unit.target=Catalog.interaction_point(s.region,s.ground.activity.site_id)
			elif unit.assignment=="downed" or not Nav.walkable(s.region,Vector2(unit.target[0],unit.target[1]),s.ship):unit.target=unit.position.duplicate()
	s.log.append("N5: Routen und Einsatzorte ergänzt; Bestände, Besatzung und Arbeit erhalten. Positionen an neue Geometrie angepasst.")
	while s.log.size()>30:s.log.pop_front()
	return result
