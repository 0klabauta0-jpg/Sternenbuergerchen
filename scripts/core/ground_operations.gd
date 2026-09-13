extends RefCounted
const Catalog=preload("res://scripts/core/catalog.gd")
const GroundCatalog=preload("res://scripts/core/ground_catalog.gd")
const State=preload("res://scripts/core/ground_state.gd")
const Nav=preload("res://scripts/core/ground_navigation.gd")
var s: Dictionary
var log_event: Callable
var cancel_tasks: Callable
func bind(state: Dictionary,logger: Callable,cancel: Callable) -> void:s=state;log_event=logger;cancel_tasks=cancel
func busy() -> bool:
	if s.ground.activity.active:return true
	for unit: Dictionary in s.crew.values():
		if unit.health<=0:return true
	return false
func dispatch(c: Dictionary,sender: int) -> String:
	if s.travel.active:return "Crew befindet sich auf Reise."
	match c.type:
		"gather":return _gather(c,sender)
		"cancel_gather":
			if not s.ground.activity.active:return "Keine Gewinnung aktiv."
			stop_activity()
		"attack":return _attack(c,sender)
		"use_elevator":return _elevator(sender)
		"rent_ship":
			if c.get("ship_id")!="vulture":return "Dieses Schiff wird nicht vermietet."
			if s.region!="station" or s.ship.mode!="landed":return "Geier am Stationsdock mieten."
			if s.rental.active:return "Geier ist bereits gemietet."
			if s.credits<900:return "Geier-Miete kostet 900 Credits."
			if busy():return "Crew ist gebunden oder verwundet."
			for unit: Dictionary in s.crew.values():
				if unit.assignment=="boarding":return "Einstieg zuerst abschließen oder abbrechen."
			s.credits-=900;s.rental={"active":true,"remaining":1200.0,"expired":false}
			s.ship.model="vulture";s.ship.name="Geier";s.ship.capacity=40
			log_event.call("Geier gemietet: 20 Simulationsminuten, 40 Frachtplätze und dreifache Wrackausbeute.")
		"return_rental":
			if not s.rental.active:return "Kein Mietschiff aktiv."
			if not s.region in ["base","station"] or s.ship.mode!="landed":return "Geier an Basis oder Station zurückgeben."
			if busy():return "Laufende Arbeit zuerst beenden."
			for unit: Dictionary in s.crew.values():
				if unit.assignment=="boarding":return "Einstieg zuerst abschließen oder abbrechen."
			var replacement: Dictionary=s.ship.duplicate(true)
			replacement.model="cutlass"
			if not Nav.landing_clear(s.region,replacement):return "Größeres Ersatzschiff passt nicht an diese Landestelle."
			for unit: Dictionary in s.crew.values():
				if unit.assignment!="aboard" and not Nav.walkable(s.region,_v(unit.position),replacement):return "Crew steht im Bereich des Ersatzschiffs."
			return_rental()
		_:return "Unbekannter Bodenauftrag."
	return ""
func _unit_error(id: Variant,sender: int) -> String:
	if not id is String or not s.crew.has(id):return "Person nicht gefunden."
	if s.crew[id].assignment!="idle" or s.crew[id].health<=0:return "Person ist gebunden oder verwundet."
	return ""
func _gather(c: Dictionary,sender: int) -> String:
	var error: String=_unit_error(c.get("unit_id"),sender)
	if not error.is_empty():return error
	if s.ship.mode!="landed":return "Vor der Gewinnung landen."
	if s.ground.activity.active:return "Eine Gewinnung läuft bereits."
	var id: Variant=c.get("site_id")
	if not id is String or not Catalog.resource_sites().has(id):return "Fundstelle unbekannt."
	var site: Dictionary=Catalog.resource_sites()[id]
	if site.region!=s.region:return "Fundstelle liegt auf einer anderen Karte."
	if id in ["mining_site","derelict"]:
		var signal_id: String="signal_02" if id=="mining_site" else "signal_03"
		var identified: bool=false
		for contact: Dictionary in s.discovery.signals:
			if contact.id==signal_id and contact.identified:identified=true
		if not identified:return "Fundstelle zuerst per Radar identifizieren."
	if s.resources[id].remaining<=0:return "Fundstelle ist erschöpft."
	if s.region!="bunker_depths" and cargo_count()>=s.ship.capacity:return "Frachtraum ist voll."
	var point: Array=Catalog.interaction_point(s.region,id)
	var unit: Dictionary=s.crew[c.unit_id]
	if Nav.path(s.region,_v(unit.position),_v(point),s.ship).is_empty():return "Fundstelle ist nicht erreichbar."
	if id=="mining_site" and not (unit.equipment.tool=="multitool" and unit.equipment.attachment=="mining_attachment"):return "Mining braucht Multi-Tool und Mining-Aufsatz."
	if id in ["derelict","distribution_wreck"] and not (unit.equipment.tool=="cutter" or (unit.equipment.tool=="multitool" and unit.equipment.attachment=="salvage_attachment")):return "Salvage braucht Schneidwerkzeug oder Multi-Tool mit Salvage-Aufsatz."
	var duration: float=site.duration/Catalog.skill_effects(unit).gather_multiplier
	unit.assignment="gather";unit.attack_target="";unit.target=point
	s.ground.activity={"active":true,"unit_id":c.unit_id,"site_id":id,"remaining":duration,"total":duration,"phase":"walking"}
	log_event.call(unit.name+" geht zur Fundstelle.")
	return ""
func _attack(c: Dictionary,sender: int) -> String:
	var error: String=_unit_error(c.get("unit_id"),sender)
	if not error.is_empty():return error
	var target: Variant=c.get("target_id")
	if not target is String:return "Ziel fehlt."
	var unit: Dictionary=s.crew[c.unit_id]
	if target.is_empty():unit.attack_target="";unit.target=unit.position.duplicate();return ""
	if s.ship.mode!="landed" or not s.ground.enemies[s.region].has(target):return "Kein Bodenziel auf dieser Karte."
	var enemy: Dictionary=s.ground.enemies[s.region][target]
	if enemy.defeated:return "Ziel ist bereits ausgeschaltet."
	if Nav.path(s.region,_v(unit.position),Nav.safe_near(s.region,_v(enemy.position),s.ship),s.ship).is_empty():return "Ziel ist nicht erreichbar."
	unit.attack_target=target;var approach: Vector2=Nav.safe_near(s.region,_v(enemy.position),s.ship)
	unit.target=[approach.x,approach.y]
	return ""
func _elevator(sender: int) -> String:
	if not s.region in ["bunker_surface","bunker_depths"] or s.ship.mode!="landed":return "Kein nutzbarer Aufzug hier."
	if busy() or s.work.active or s.salvage.active:return "Crew ist gebunden oder verwundet."
	var entry: String="bunker_entry" if s.region=="bunker_surface" else "elevator"
	var point: Vector2=_v(Catalog.landmarks(s.region)[entry])
	for unit: Dictionary in s.crew.values():
		if unit.assignment!="idle" or _v(unit.position).distance_to(point)>8.0:return "Beide Crewmitglieder zum Aufzug bringen (8 m)."
	s.region="bunker_depths" if s.region=="bunker_surface" else "bunker_surface"
	var destination: Array=Catalog.landmarks(s.region)["elevator" if s.region=="bunker_depths" else "bunker_entry"]
	var offset: float=-1.5
	for unit: Dictionary in s.crew.values():
		unit.position=[destination[0]+offset,destination[1]];unit.target=unit.position.duplicate();unit.attack_target="";offset+=3.0
	log_event.call("Aufzug: "+("Untergrund" if s.region=="bunker_depths" else "Oberfläche")+" erreicht.")
	return ""
func cargo_count() -> int:
	var result: int=0
	for count: Variant in s.cargo.values():result+=int(count)
	return result
func stop_activity() -> void:
	if s.ground.activity.active:
		var unit: Dictionary=s.crew[s.ground.activity.unit_id]
		unit.assignment="idle";unit.target=unit.position.duplicate()
	s.ground.activity=State.empty_activity()
func return_rental() -> void:
	# A safe handover preserves every item, even when the smaller ship cannot fit it.
	for item: String in s.cargo:s.inventory[item]+=s.cargo[item];s.cargo[item]=0
	s.rental={"active":false,"remaining":0.0,"expired":false}
	s.ship.model="cutlass";s.ship.name="Entersäbel";s.ship.capacity=12
	log_event.call("Geier zurückgegeben. Fracht im Basislager, Entersäbel bereit.")
func tick(delta: float) -> void:
	if s.rental.active:
		s.rental.remaining=maxf(0,s.rental.remaining-delta)
		if s.rental.remaining<=0:s.rental.expired=true

	for unit: Dictionary in s.crew.values():
		unit.attack_cooldown=maxf(0,unit.attack_cooldown-delta)
		if unit.health<=0:
			unit.respawn_remaining=maxf(0,unit.respawn_remaining-delta)
			if unit.respawn_remaining<=0:
				var at: Array=Catalog.landmarks(s.region).get("elevator",s.ship.position)
				var safe: Vector2=Nav.safe_near(s.region,Vector2(at[0],at[1]+8.0),s.ship)
				unit.health=100.0;unit.assignment="idle";unit.position=[safe.x,safe.y];unit.target=unit.position.duplicate()
				log_event.call(unit.name+" nach Notversorgung wieder einsatzbereit.")
		elif s.region=="base":unit.health=minf(100,unit.health+5.0*delta)
	if s.travel.active:return
	_tick_activity(delta)
	_tick_combat(delta)
func _tick_activity(delta: float) -> void:
	var activity: Dictionary=s.ground.activity
	if not activity.active:return
	var unit: Dictionary=s.crew[activity.unit_id]
	if _v(unit.position).distance_to(_v(unit.target))>0.03:return
	activity.phase="working";activity.remaining=maxf(0,activity.remaining-delta)
	if activity.remaining>0:return
	var site: Dictionary=Catalog.resource_sites()[activity.site_id]
	var multiplier: int=3 if s.rental.active and not s.rental.expired and activity.site_id in ["derelict","distribution_wreck"] else 1
	var room: int=10000000 if s.region=="bunker_depths" else int(s.ship.capacity)-cargo_count()
	var amount: int=mini(room,mini(int(s.resources[activity.site_id].remaining),int(site["yield"])*multiplier))
	var destination: Dictionary=s.inventory if s.region=="bunker_depths" else s.cargo
	destination[site.item]+=amount;s.resources[activity.site_id].remaining-=amount
	log_event.call("Fund geborgen: %d × %s."%[amount,Catalog.item_name(site.item)])
	stop_activity()
func _tick_combat(delta: float) -> void:
	var enemies: Dictionary=s.ground.enemies[s.region]
	for unit: Dictionary in s.crew.values():
		if unit.health<=0 or unit.attack_target.is_empty():continue
		if not enemies.has(unit.attack_target) or enemies[unit.attack_target].defeated:unit.attack_target="";unit.target=unit.position.duplicate();continue
		var enemy: Dictionary=enemies[unit.attack_target]
		if _v(unit.position).distance_to(_v(enemy.position))>24.0 or not Nav.clear(s.region,_v(unit.position),_v(enemy.position),s.ship,"object_"+str(enemy.id)):
			var approach: Vector2=Nav.safe_near(s.region,_v(enemy.position),s.ship)
			unit.target=[approach.x,approach.y];continue
		unit.target=unit.position.duplicate()
		if unit.attack_cooldown<=0:
			enemy.health=maxf(0,enemy.health-Catalog.skill_effects(unit).ground_damage);unit.attack_cooldown=1.0
			if enemy.health<=0:
				enemy.defeated=true;s.credits+=75 if enemy.kind=="aa" else 25
				log_event.call(enemy.name+" ausgeschaltet. Bergungsprämie erhalten.")
	for enemy: Dictionary in enemies.values():
		if enemy.defeated:continue
		enemy.cooldown=maxf(0,enemy.cooldown-delta)
		if enemy.cooldown>0:continue
		if s.ship.mode=="flying":
			if enemy.kind=="aa" and _v(enemy.position).distance_to(_v(s.ship.position))<=100.0:
				s.ship.condition=maxf(0,s.ship.condition-12.0);enemy.cooldown=3.0
			continue
		var closest: Dictionary={};var distance: float=30.0 if enemy.kind=="aa" else 22.0
		for unit: Dictionary in s.crew.values():
			var separation: float=_v(unit.position).distance_to(_v(enemy.position))
			if unit.health>0 and unit.assignment!="aboard" and separation<=distance and Nav.clear(s.region,_v(enemy.position),_v(unit.position),s.ship,"object_"+str(enemy.id)):closest=unit;distance=separation
		if closest.is_empty():continue
		var damage: float=(12.0 if enemy.kind=="aa" else 8.0)*(1.0-Catalog.skill_effects(closest).armor_reduction)
		closest.health=maxf(0,closest.health-damage);enemy.cooldown=3.0 if enemy.kind=="aa" else 2.0
		if closest.health<=0:
			cancel_tasks.call(closest.id)
			if s.ground.activity.active and s.ground.activity.unit_id==closest.id:stop_activity()
			closest.assignment="downed";closest.respawn_remaining=20.0;closest.attack_target="";closest.target=closest.position.duplicate()
			log_event.call(closest.name+" verwundet. Notversorgung: 20 Sekunden.")
func _v(point: Array) -> Vector2:return Vector2(point[0],point[1])
