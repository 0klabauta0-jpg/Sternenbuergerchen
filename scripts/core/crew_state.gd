extends RefCounted
const Catalog=preload("res://scripts/core/catalog.gd")
const Nav=preload("res://scripts/core/ground_navigation.gd")
const Gear=preload("res://scripts/core/equipment_catalog.gd")
const Travel=preload("res://scripts/core/crew_travel.gd")
static func extend(s: Dictionary) -> void:
	s.schema_version=4
	for item: String in Catalog.ITEMS:
		if not s.inventory.has(item):s.inventory[item]=0
		if not s.cargo.has(item):s.cargo[item]=0
	for id: String in Gear.recipes():
		if not s.blueprints.has(id):s.blueprints.append(id)
	s.ship.seats={"pilot":"","gunner":"","passenger_1":"","passenger_2":""}
	s.ship.roles={"pilot":"","gunner":""};s.ship.yaw=0.0;s.ship.turret_yaw=0.0
	s.ground.enemies.orbit={}
	for unit: Dictionary in s.crew.values():
		unit.seat="";unit.equipment.backpack="";unit.equipment.attachment=""
		unit.backpack={"capacity":0,"items":{}}
		for item: String in Catalog.ITEMS:unit.backpack.items[item]=0
static func migrate(payload: Dictionary) -> Dictionary:
	var result: Dictionary=payload.duplicate(true)
	var s: Dictionary=result.state
	var old_roles: Dictionary=s.ship.roles.duplicate()
	extend(s);result.schema_version=4
	var airborne: bool=s.ship.mode=="flying" or s.travel.active
	if airborne:
		var index: int=0
		for id: String in s.crew:
			var seat: String="pilot" if old_roles.get("pilot")==id else ("gunner" if old_roles.get("gunner")==id else "passenger_"+str(index+1))
			s.ship.seats[seat]=id;s.crew[id].seat=seat;s.crew[id].assignment="aboard";s.crew[id].attack_target=""
			s.crew[id].position=s.ship.position.duplicate();s.crew[id].target=s.ship.position.duplicate();index+=1
		s.ship.roles={"pilot":s.ship.seats.pilot,"gunner":s.ship.seats.gunner};s.ship.mode="flying"
		if s.travel.active:
			if s.travel.kind=="launch":s.travel=Travel.empty_travel()
			else:s.travel.phase="flying";s.travel.kind="legacy";s.travel.encounter_roll=99 if s.travel.to!="station" else s.travel.encounter_roll
	var corrected: bool=false
	if not airborne:
		var ship_region: String="bunker_surface" if s.region=="bunker_depths" else s.region
		if not Nav.landing_clear(ship_region,s.ship):
			var origin: Vector2=_v(s.ship.position)
			var found: bool=false
			for radius in range(1,101):
				if found:break
				for step in 24:
					var at: Vector2=origin+Vector2.from_angle(step*TAU/24.0)*radius
					var candidate: Dictionary=s.ship.duplicate(true);candidate.position=[at.x,at.y]
					if Nav.landing_clear(ship_region,candidate):
						s.ship.position=candidate.position;s.ship.target=candidate.position.duplicate();found=true;corrected=true;break
		for unit: Dictionary in s.crew.values():
			var before: Vector2=_v(unit.position)
			var point: Vector2=Nav.safe_near(s.region,before,s.ship)
			if point.is_finite():unit.position=[point.x,point.y];corrected=corrected or point!=before
			var target: Array=unit.target
			if unit.assignment=="work":target=Catalog.interaction_point("base","workbench")
			elif unit.assignment=="salvage":target=Catalog.interaction_point("rust","satellite")
			elif unit.assignment=="gather":target=Catalog.interaction_point(s.region,s.ground.activity.site_id)
			elif unit.assignment=="downed":target=unit.position.duplicate()
			elif not Nav.walkable(s.region,_v(target),s.ship):target=unit.position.duplicate();corrected=true
			unit.target=target
	if corrected:s.log.append("N4-Migration: Positionen/Ziele an neue Hindernisse angepasst; Bestände und Arbeit erhalten.")
	while s.log.size()>30:s.log.pop_front()
	return result
static func _v(a: Array) -> Vector2:return Vector2(a[0],a[1])
