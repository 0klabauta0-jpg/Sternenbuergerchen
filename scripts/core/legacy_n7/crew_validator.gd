extends RefCounted
const Catalog=preload("res://scripts/core/legacy_n7/catalog.gd")
const Gear=preload("res://scripts/core/legacy_n7/equipment_catalog.gd")
const Numbers=preload("res://scripts/core/legacy_n7/legacy_validator_v2.gd")
const SEATS=["pilot","gunner","passenger_1","passenger_2"]
static func validate(s: Dictionary) -> String:
	if not s.ship.get("seats") is Dictionary or s.ship.seats.size()!=4 or not s.ship.get("roles") is Dictionary:return "Sitzplan fehlt."
	for axis: String in ["yaw","turret_yaw"]:
		if not Numbers.number(s.ship.get(axis),-PI,PI):return "Schiffswinkel ungültig."
	if s.ship.mode=="landed" and s.ship.yaw!=0:return "Gelandetes Schiff falsch ausgerichtet."
	var occupied: Dictionary={}
	for seat: String in SEATS:
		var id: Variant=s.ship.seats.get(seat)
		if not id is String:return "Sitzbelegung ungültig."
		if id.is_empty():continue
		if not s.crew.has(id) or occupied.has(id) or s.crew[id].get("seat")!=seat or not s.crew[id].assignment in ["boarding","aboard"]:return "Sitzbindung widersprüchlich."
		occupied[id]=true
	for role: String in ["pilot","gunner"]:
		if s.ship.roles.get(role)!=s.ship.seats[role]:return "Rollen widersprechen den Sitzen."
	if s.ship.mode=="flying" and s.ship.seats.pilot.is_empty():return "Flug ohne Pilot."
	for id: String in s.crew:
		var unit: Dictionary=s.crew[id]
		if not unit.get("seat") is String or (not occupied.has(id) and unit.seat!=""):return "Verwaister Sitz."
		if unit.assignment in ["boarding","aboard"] and not occupied.has(id):return "Bordfigur ohne Sitz."
		if unit.assignment=="boarding" and (s.ship.mode!="landed" or s.travel.active or unit.target!=Catalog.ship_access(s.ship)):return "Einstiegsziel ungültig."
		if unit.assignment=="aboard" and unit.position!=s.ship.position:return "Bordposition ungültig."
		var equipment: Variant=unit.get("equipment")
		if not equipment is Dictionary or equipment.size()!=5:return "Ausrüstungsslots ungültig."
		for slot: String in Gear.SLOTS:
			var item: Variant=equipment.get(slot)
			if not item is String:return "Ausrüstung fehlt."
			if not item.is_empty() and not (slot=="helmet" and item=="basic_helmet") and Gear.slot_for(item)!=slot:return "Gegenstand im falschen Slot."
		if not equipment.attachment.is_empty() and equipment.tool!="multitool":return "Aufsatz ohne Multi-Tool."
		if not unit.get("backpack") is Dictionary:return "Rucksack fehlt."
		if unit.backpack.get("capacity")!=(8 if equipment.backpack=="backpack" else 0):return "Rucksackgröße ungültig."
		var count: int=0
		for item: String in unit.backpack.items:count+=int(unit.backpack.items[item])
		if count>unit.backpack.capacity:return "Rucksack überfüllt."
	return ""
