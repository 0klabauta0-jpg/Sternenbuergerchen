extends RefCounted
const Catalog=preload("res://scripts/core/catalog.gd")
const GroundCatalog=preload("res://scripts/core/ground_catalog.gd")
const Nav=preload("res://scripts/core/ground_navigation.gd")
static func empty_activity() -> Dictionary:
	return {"active":false,"unit_id":"","site_id":"","remaining":0.0,"total":0.0,"phase":"idle"}
static func extend(s: Dictionary) -> void:
	s.schema_version=3
	for item in ["armor","ore","alloy"]:s.inventory[item]=0;s.cargo[item]=0
	if not s.blueprints.has("armor"):s.blueprints.append("armor")
	s.ship.model="cutlass";s.ship.name="Entersäbel"
	s.rental={"active":false,"remaining":0.0,"expired":false}
	s.resources={}
	for id: String in Catalog.resource_sites():s.resources[id]={"remaining":Catalog.resource_sites()[id].stock}
	s.ground={"enemies":{},"activity":empty_activity()}
	for region: String in GroundCatalog.REGIONS:s.ground.enemies[region]=Catalog.ground_enemies(region)
	for unit: Dictionary in s.crew.values():
		unit.health=100.0;unit.respawn_remaining=0.0;unit.attack_target="";unit.attack_cooldown=0.0;unit.equipment.armor=""
	# Preserve known v2 contacts while relocating only the new resource contacts.
	for contact: Dictionary in s.discovery.signals:
		var index: int=int(str(contact.id).right(2))-1
		contact.position=Catalog.radar_contacts()[index].position.duplicate()
		if contact.identified and index>0:
			contact.kind="mining_site" if index==1 else "derelict"
			contact.label="Erzvorkommen" if index==1 else "Verlassenes Schiffswrack"
static func migrate(payload: Dictionary) -> Dictionary:
	var result: Dictionary=payload.duplicate(true)
	extend(result.state);result.schema_version=3
	var state: Dictionary=result.state
	if state.ship.mode=="landed":
		# New blockers cannot strand a validated older career inside solid geometry.
		for unit: Dictionary in state.crew.values():
			if not Nav.walkable(state.region,Vector2(unit.position[0],unit.position[1])):unit.position=Catalog.landmarks(state.region).shuttle.duplicate()
			if not Nav.walkable(state.region,Vector2(unit.target[0],unit.target[1])):unit.target=unit.position.duplicate()
	return result
