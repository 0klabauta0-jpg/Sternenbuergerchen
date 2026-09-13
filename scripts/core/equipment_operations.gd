extends RefCounted
const Regions=preload("res://scripts/core/regions.gd")
const Catalog=preload("res://scripts/core/catalog.gd")
const Gear=preload("res://scripts/core/equipment_catalog.gd")
const Numbers=preload("res://scripts/core/legacy_validator_v2.gd")
const Nav=preload("res://scripts/core/ground_navigation.gd")
var s: Dictionary
var log_event: Callable
func bind(state: Dictionary,logger: Callable) -> void:s=state;log_event=logger
func dispatch(c: Dictionary) -> String:
	if s.travel.active:return "Ausrüstung erst nach dem Reiseübergang ändern."
	var id: Variant=c.get("unit_id")
	if not id is String or not s.crew.has(id):return "Person nicht gefunden."
	var unit: Dictionary=s.crew[id]
	if unit.health<=0 or not unit.assignment in ["idle","aboard"]:return "Person ist gebunden oder verwundet."
	match c.type:
		"equip_item":return _equip(unit,c)
		"unequip_item":return _unequip(unit,c)
		"backpack_transfer":return _transfer(unit,c)
		"use_medgun":return _heal(unit,c)
		"field_repair":return _field_repair(unit)
		"equip":
			if not c.get("item") is String:return "Gegenstand fehlt."
			return _equip(unit,{"slot":Gear.slot_for(c.item),"item":c.item,"source":"inventory"})
	return "Unbekannter Ausrüstungsauftrag."
func container_error(unit: Dictionary,name: Variant) -> String:
	if not name is String or not name in ["inventory","cargo","backpack"]:return "Unbekannte Herkunft oder Ablage."
	if name=="backpack":
		if unit.backpack.capacity<=0:return "Zuerst einen Rucksack anlegen."
		return ""
	if name=="inventory":
		if s.region!="base" or _v(unit.position).distance_to(_v(Catalog.landmarks("base").storage))>8.0 or unit.assignment=="aboard":return "Basislager aufsuchen (8 m)."
	elif unit.assignment!="aboard" and ((s.region in ["orbit","space"] or Regions.underground(s.region)) or s.ship.mode!="landed" or _v(unit.position).distance_to(_v(Catalog.ship_access(s.ship)))>8.0):return "Frachtzugang aufsuchen (8 m) oder einsteigen."
	return ""
func _container(unit: Dictionary,name: String) -> Dictionary:return unit.backpack.items if name=="backpack" else s[name]
func _capacity(unit: Dictionary,name: String) -> int:return int(unit.backpack.capacity) if name=="backpack" else (int(s.ship.capacity) if name=="cargo" else 10000000)
func _count(container: Dictionary) -> int:
	var total: int=0
	for count: Variant in container.values():total+=int(count)
	return total
func _equip(unit: Dictionary,c: Dictionary) -> String:
	var slot: Variant=c.get("slot");var item: Variant=c.get("item")
	if not slot is String or not Gear.SLOTS.has(slot) or not item is String or Gear.slot_for(item)!=slot:return "Gegenstand passt nicht in diesen Ausrüstungsplatz."
	var error: String=container_error(unit,c.get("source"))
	if not error.is_empty():return error
	if slot=="attachment" and unit.equipment.tool!="multitool":return "Ein angelegtes Multi-Tool wird benötigt."
	if slot=="tool" and not unit.equipment.attachment.is_empty():return "Zuerst den Multi-Tool-Aufsatz abnehmen."
	if slot=="backpack" and _count(unit.backpack.items)>0:return "Rucksack vor dem Wechsel leeren."
	var source: Dictionary=_container(unit,c.source)
	if source.get(item,0)<=0:return "Gegenstand fehlt in der angegebenen Quelle."
	var previous: String=unit.equipment[slot]
	if previous==item:return "Gegenstand ist bereits angelegt."
	var returns_item: bool=Catalog.ITEMS.has(previous)
	if _count(source)-1+(1 if returns_item else 0)>_capacity(unit,c.source):return "Ablage hat keinen freien Platz."
	source[item]-=1
	if returns_item:source[previous]+=1
	unit.equipment[slot]=item
	if slot=="backpack":unit.backpack.capacity=8
	log_event.call(unit.name+" legt "+Catalog.item_name(item)+" an.")
	return ""
func _unequip(unit: Dictionary,c: Dictionary) -> String:
	var slot: Variant=c.get("slot")
	if not slot is String or not Gear.SLOTS.has(slot):return "Unbekannter Ausrüstungsplatz."
	var item: String=unit.equipment[slot]
	if item.is_empty():return "Ausrüstungsplatz ist leer."
	if item=="basic_helmet":return "Der Basishelm ist kein handelbarer Gegenstand."
	var error: String=container_error(unit,c.get("destination"))
	if not error.is_empty():return error
	if slot=="tool" and not unit.equipment.attachment.is_empty():return "Zuerst den Multi-Tool-Aufsatz abnehmen."
	if slot=="backpack" and (_count(unit.backpack.items)>0 or c.destination=="backpack"):return "Rucksack leeren und extern ablegen."
	var destination: Dictionary=_container(unit,c.destination)
	if _count(destination)>=_capacity(unit,c.destination):return "Ablage ist voll."
	destination[item]+=1;unit.equipment[slot]=""
	if slot=="backpack":unit.backpack.capacity=0
	return ""
func _transfer(unit: Dictionary,c: Dictionary) -> String:
	if not c.get("item") is String or not Catalog.ITEMS.has(c.item) or not Numbers.whole(c.get("amount"),1,10000000):return "Ungültiger Gegenstand oder Menge."
	if c.get("source")==c.get("destination") or not (c.get("source")=="backpack" or c.get("destination")=="backpack"):return "Transfer muss zwischen Rucksack und anderer Ablage erfolgen."
	for name: Variant in [c.get("source"),c.get("destination")]:
		var error: String=container_error(unit,name)
		if not error.is_empty():return error
	var source: Dictionary=_container(unit,c.source);var destination: Dictionary=_container(unit,c.destination)
	if source[c.item]<c.amount:return "Gegenstände fehlen in der Quelle."
	if _count(destination)+int(c.amount)>_capacity(unit,c.destination):return "Zielbehälter ist voll."
	source[c.item]-=int(c.amount);destination[c.item]+=int(c.amount)
	return ""
func _heal(unit: Dictionary,c: Dictionary) -> String:
	if unit.assignment!="idle" or unit.equipment.tool!="medgun":return "Medgun anlegen und an Land benutzen."
	var id: Variant=c.get("target_id")
	if not id is String or not s.crew.has(id):return "Zielperson fehlt."
	var target: Dictionary=s.crew[id]
	if target.assignment in ["aboard","boarding"]:return "Zielperson muss aussteigen."
	if target.health>=100:return "Zielperson ist gesund."
	if _v(unit.position).distance_to(_v(target.position))>6 or not Nav.clear(s.region,_v(unit.position),_v(target.position),s.ship):return "Zielperson muss innerhalb6m und erreichbar sein."
	if unit.backpack.items.med_charge<1:return "Keine Med-Ladung im eigenen Rucksack."
	unit.backpack.items.med_charge-=1
	target.health=minf(100,target.health+35.0)
	if target.assignment=="downed":target.assignment="idle";target.respawn_remaining=0.0;target.target=target.position.duplicate()
	log_event.call(unit.name+" behandelt "+target.name+" mit der Medgun.")
	return ""
func _field_repair(unit: Dictionary) -> String:
	if unit.assignment!="idle" or unit.equipment.tool!="multitool" or unit.equipment.attachment!="repair_attachment":return "Freie Person mit Multi-Tool und Reparatur-Aufsatz auswählen."
	if s.ship.mode!="landed" or Regions.underground(s.region):return "Reparatur braucht ein gelandetes, zugängliches Schiff."
	var access:=_v(Catalog.ship_access(s.ship))
	if _v(unit.position).distance_to(access)>6.0 or not Nav.clear(s.region,_v(unit.position),access,s.ship):return "Zum Schiffszugang gehen (6 m)."
	if s.ship.condition>=70.0:return "Feldreparatur reicht bis 70 %. Für mehr die Basiswerkstatt benutzen."
	if unit.backpack.items.parts<1:return "Ein Bauteil im eigenen Rucksack wird benötigt."
	unit.backpack.items.parts-=1
	s.ship.condition=minf(70.0,s.ship.condition+10.0+unit.skills.tech)
	log_event.call(unit.name+" repariert kleine Rumpfschäden; ein Bauteil verbraucht.")
	return ""
func _v(point: Array) -> Vector2:return Vector2(point[0],point[1])
