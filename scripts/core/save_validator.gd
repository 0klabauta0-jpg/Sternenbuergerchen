extends RefCounted

const Catalog = preload("res://scripts/core/catalog.gd")

static func whole(value: Variant, lower: int, upper: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and value >= lower and value <= upper

static func number(value: Variant, lower: float, upper: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= lower and value <= upper

static func position_valid(value: Variant, boundary: float) -> bool:
	return value is Array and value.size() == 2 and number(value[0], -boundary, boundary) and number(value[1], -boundary, boundary)

static func _items(value: Variant) -> bool:
	if not value is Dictionary or value.size() != Catalog.ITEMS.size(): return false
	for item: String in Catalog.ITEMS:
		if not whole(value.get(item),0,10000000): return false
	return true

static func validate(payload: Variant) -> String:
	if not payload is Dictionary or payload.get("schema_version") != 2: return "Unbekanntes Speicherformat."
	var value: Variant = payload.get("state")
	if not value is Dictionary: return "Zustand fehlt."
	var s: Dictionary = value
	if s.get("schema_version") != 2 or not whole(s.get("revision"),0,1000000000000): return "Version oder Revision ungültig."
	if not number(s.get("time"),0.0,1000000000000.0) or not s.get("paused") is bool: return "Zeit ungültig."
	if not s.get("region") in ["base","rust","station","space"]: return "Region ungültig."
	if not whole(s.get("credits"),0,1000000000) or not _items(s.get("inventory")) or not _items(s.get("cargo")): return "Bestand ungültig."
	if not s.get("ship") is Dictionary or not number(s.ship.get("condition"),0,100) or not whole(s.ship.get("capacity"),1,1000): return "Shuttle ungültig."
	var cargo_count: int = 0
	for item: String in s.cargo: cargo_count += int(s.cargo[item])
	if cargo_count > s.ship.capacity: return "Frachtraum überfüllt."
	if not s.get("blueprints") is Array: return "Baupläne ungültig."
	var unique: Dictionary = {}
	for blueprint: Variant in s.blueprints:
		if not blueprint is String or not Catalog.recipes().has(blueprint) or unique.has(blueprint): return "Bauplan ungültig."
		unique[blueprint] = true
	if not unique.has("toolkit") or not unique.has("repair"): return "Grundrezepte fehlen."
	if not whole(s.get("wreck_remaining"),0,8): return "Wrackbestand ungültig."
	if not s.get("crew") is Dictionary or s.crew.size() != 2: return "Crew ungültig."
	for unit_id: String in ["ida","jaro"]:
		if not s.crew.get(unit_id) is Dictionary: return "Person fehlt."
		var unit: Dictionary = s.crew[unit_id]
		if unit.get("id") != unit_id or not unit.get("name") is String or not whole(unit.get("skill"),0,10) or not whole(unit.get("owner"),1,2147483647): return "Personendaten ungültig."
		if not position_valid(unit.get("position"),Catalog.bounds(s.region)) or not position_valid(unit.get("target"),Catalog.bounds(s.region)): return "Personenposition ungültig."
		if not unit.get("assignment") in ["idle","work","salvage","boarding","aboard"]: return "Zuweisung ungültig."
	if not s.get("contract") is Dictionary or not s.contract.get("status") in ["available","active","recovered","claimed"] or s.contract.get("reward") != 260: return "Auftrag ungültig."
	var blackboxes: int = int(s.inventory.blackbox) + int(s.cargo.blackbox)
	if blackboxes != (1 if s.contract.status == "recovered" else 0): return "Blackbox und Auftrag widersprechen sich."
	if unique.has("cutter") != (s.contract.status == "claimed"): return "Bauplan und Auszahlung widersprechen sich."
	for key: String in ["work","salvage","travel"]:
		if not s.get(key) is Dictionary: return "Vorgang fehlt."
		var task: Dictionary = s[key]
		if not task.get("active") is bool or not number(task.get("remaining"),0,1000) or not number(task.get("total"),0,1000) or task.remaining > task.total or not task.get("phase") is String: return "Vorgangszeit ungültig."
	var work: Dictionary = s.work
	var salvage: Dictionary = s.salvage
	var travel: Dictionary = s.travel
	if not work.get("unit_id") is String or not work.get("recipe_id") is String or not work.get("reserved") is Dictionary or not salvage.get("unit_id") is String: return "Arbeitsdaten fehlen."
	if not travel.get("from") is String or not travel.get("to") is String: return "Reisedaten fehlen."
	if work.active:
		if s.region != "base" or not s.crew.has(work.unit_id) or not Catalog.recipes().has(work.recipe_id) or not s.blueprints.has(work.recipe_id): return "Arbeit ungültig."
		var recipe: Dictionary = Catalog.recipes()[work.recipe_id]
		if s.crew[work.unit_id].skill < recipe.min_skill or s.crew[work.unit_id].assignment != "work" or not _materials_equal(work.reserved, recipe.materials) or work.total != recipe.duration or not work.phase in ["walking","working"]: return "Arbeitsreservierung ungültig."
		if not _same_position(s.crew[work.unit_id].target,Catalog.interaction_point("base", "workbench")): return "Werkbankziel ungültig."
	elif work.unit_id != "" or work.recipe_id != "" or not work.reserved.is_empty() or work.phase != "idle" or work.remaining != 0 or work.total != 0: return "Inaktive Arbeit inkonsistent."
	if salvage.active:
		if s.region != "rust" or s.contract.status == "available" or s.wreck_remaining <= 0 or not s.crew.has(salvage.unit_id) or s.crew[salvage.unit_id].assignment != "salvage" or salvage.total != 8 or not salvage.phase in ["walking","working"]: return "Bergung ungültig."
		if not _same_position(s.crew[salvage.unit_id].target,Catalog.interaction_point("rust", "satellite")): return "Bergungsziel ungültig."
	elif salvage.unit_id != "" or salvage.phase != "idle" or salvage.remaining != 0 or salvage.total != 0: return "Inaktive Bergung inkonsistent."
	var stage_error: String=_stage_valid(s)
	if not stage_error.is_empty():return stage_error
	if travel.active:
		if work.active or salvage.active or travel.from!=s.region or not travel.to in ["base","rust","station"] or not travel.phase in ["boarding","flying"]:return "Reise ungültig."
		if travel.kind=="launch":
			if s.region!="rust" or travel.to!="rust" or travel.total!=0 or travel.phase!="boarding":return "Start ungültig."
		elif travel.from==travel.to or travel.total!=5:return "Reisezeit ungültig."
		for unit_id: String in s.crew:
			if s.crew[unit_id].assignment != "boarding" or not _same_position(s.crew[unit_id].target,s.ship.position): return "Crew fehlt am Shuttle."
	elif travel.phase != "idle" or travel.from != "" or travel.to != "" or travel.remaining != 0 or travel.total != 0: return "Inaktive Reise inkonsistent."
	for unit_id: String in s.crew:
		var assignment: String = s.crew[unit_id].assignment
		if assignment == "work" and (not work.active or work.unit_id != unit_id): return "Verwaiste Arbeitsbindung."
		if assignment == "salvage" and (not salvage.active or salvage.unit_id != unit_id): return "Verwaiste Bergungsbindung."
		if assignment == "boarding" and not travel.active: return "Verwaiste Reisebindung."
		if assignment=="aboard" and (s.ship.mode!="flying" or travel.active):return "Verwaiste Bordrolle."
	if not s.get("log") is Array or s.log.size() > 30: return "Log ungültig."
	for entry: Variant in s.log:
		if not entry is String or entry.length() > 500: return "Logeintrag ungültig."
	if not payload.get("receipts") is Dictionary or payload.receipts.size() > 100000: return "Anfragehistorie ungültig."
	for key: Variant in payload.receipts:
		var receipt: Variant = payload.receipts[key]
		if not key is String or not receipt is Dictionary or not receipt.get("ok") is bool or not receipt.get("reason") is String or not receipt.get("request_id") is String or receipt.request_id.is_empty(): return "Anfragebeleg ungültig."
	return ""

static func _same_position(first: Array, second: Array) -> bool:
	return is_equal_approx(float(first[0]),float(second[0])) and is_equal_approx(float(first[1]),float(second[1]))

static func _materials_equal(first: Dictionary, second: Dictionary) -> bool:
	if first.size() != second.size(): return false
	for key: String in second:
		if not whole(first.get(key),0,10000000) or int(first[key]) != int(second[key]): return false
	return true

static func _stage_valid(s: Dictionary) -> String:
	if not whole(s.get("random_seed"),1,2147483646):return "Zufallszustand ungültig."
	if not s.get("base") is Dictionary or not whole(s.base.get("workbench_tier"),1,2):return "Werkbankstufe ungültig."
	if not s.ship.get("mode") in ["landed","flying"] or not position_valid(s.ship.get("position"),Catalog.bounds(s.region)) or not position_valid(s.ship.get("target"),Catalog.bounds(s.region)):return "Flugzustand ungültig."
	if not s.ship.get("roles") is Dictionary or s.ship.roles.get("pilot")!="ida" or s.ship.roles.get("gunner")!="jaro":return "Bordrollen ungültig."
	if not s.travel.get("kind") in ["intermap","launch"] or not s.travel.get("encounter_decided") is bool or not whole(s.travel.get("encounter_roll"),-1,99):return "Reisewurf ungültig."
	if s.travel.active and (not s.travel.encounter_decided or s.travel.encounter_roll<0):return "Reisewurf fehlt."
	if s.work.active and s.base.workbench_tier<Catalog.recipes()[s.work.recipe_id].tier:return "Rezeptstufe ungültig."
	for id: String in s.crew:
		var unit: Dictionary=s.crew[id]
		if not unit.get("skills") is Dictionary or not unit.get("equipment") is Dictionary:return "Profil fehlt."
		for skill: String in ["pilot","gunnery","tech"]:
			if not whole(unit.skills.get(skill),0,10):return "Fähigkeit ungültig."
		if unit.skill!=unit.skills.tech:return "Technikprofil widersprüchlich."
		if not unit.equipment.get("helmet") in ["","basic_helmet","helmet"] or not unit.equipment.get("tool") in ["","toolkit","cutter"]:return "Ausrüstung ungültig."
		if s.ship.mode=="flying" and not s.travel.active and (unit.assignment!="aboard" or not _same_position(unit.position,s.ship.position)):return "Bordposition ungültig."
	if not s.get("discovery") is Dictionary:return "Erkundung fehlt."
	var d: Dictionary=s.discovery
	if not d.get("radar_scanned") is bool or not d.get("satellite_found") is bool or not d.get("signals") is Array:return "Radar ungültig."
	if d.signals.size()!=(3 if d.radar_scanned else 0):return "Radarkontakte ungültig."
	var seen: Dictionary={}
	var found: bool=false
	for contact: Variant in d.signals:
		if not contact is Dictionary or not contact.get("id") in ["signal_01","signal_02","signal_03"] or seen.has(contact.id):return "Kontakt ungültig."
		seen[contact.id]=true
		if not position_valid(contact.get("position"),320) or not contact.get("identified") is bool or not contact.get("label") is String:return "Kontaktdaten ungültig."
		var index: int=int(str(contact.id).right(2))-1
		if not _same_position(contact.position,Catalog.radar_contacts()[index].position):return "Kontaktposition ungültig."
		var kind: String="unknown" if not contact.identified else ("satellite" if contact.id=="signal_01" else "debris")
		if contact.get("kind")!=kind:return "Kontaktidentität ungültig."
		if kind=="satellite":found=true
	if found!=d.satellite_found:return "Satellitenentdeckung widersprüchlich."
	if s.salvage.active and (not d.satellite_found or s.ship.mode!="landed"):return "Bergung ohne Landung/Entdeckung."
	if not s.get("encounter") is Dictionary:return "Raumkontakt fehlt."
	var e: Dictionary=s.encounter
	if not e.get("active") is bool or not e.get("status") in ["none","active","won","escaped","rescued"] or not e.get("pending_destination") in ["","station"] or not e.get("enemy") is Dictionary or not e.get("turret_target") in ["","pirate"]:return "Raumkontakt ungültig."
	for timer: String in ["fire_cooldown","enemy_cooldown","escape_remaining"]:
		if not number(e.get(timer),0,20):return "Kampfzeit ungültig."
	if e.active!=(e.status=="active") or e.active!=(s.region=="space"):return "Raumkontaktstatus widersprüchlich."
	if e.active and (s.ship.mode!="flying" or s.travel.active or e.pending_destination!="station"):return "Raumflug inkonsistent."
	if e.status!="none":
		if e.enemy.get("id")!="pirate" or e.enemy.get("name")!="Freibeuter" or e.enemy.get("model")!="buccaneer" or not position_valid(e.enemy.get("position"),240) or not position_valid(e.enemy.get("target"),240) or not number(e.enemy.get("hull"),0,40) or e.enemy.get("max_hull")!=40:return "Gegner ungültig."
	elif not e.enemy.is_empty():return "Gegner ohne Kontakt."
	return ""
