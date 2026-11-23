extends RefCounted
## Item identities and pure bounded-container validation; no gameplay mutation.
const SHIP_COMPONENTS = preload("res://scripts/mission/ship_equipment_catalog.gd")
const SPACE_COMPONENTS = preload("res://scripts/mission/space_component_catalog.gd")
const LOADOUT = preload("res://scripts/command/loadout_contract.gd")
const DATA_CHIP_ITEMS := ["satellite_chip", "outpost_chip"]
const RESERVED_QUEST_ITEMS := ["satellite_chip","outpost_chip","c_benit_crate"]
const AMMO_RULES = preload("res://scripts/core/ammo_rules.gd")
## Fachgroesse eines neuen persoenlichen Behaelters (Anzug); die wirkliche Groesse folgt der getragenen Ruestung (ammo_rules.json).
const ARMOR_CHIP_CAPACITY := 1
## Obergrenze fuer eine GESPEICHERTE Fachgroesse (nur Formpruefung; die Groessen selbst stehen in ammo_rules.json).
const MAX_COMPARTMENT_CAPACITY := 32
const BACKPACK_CAPACITY := 12
static var _ammo_rules: Dictionary = {}
const START_STOCK := {"armor_light":2,"armor_medium":2,"armor_heavy":2,"smg":2,"rifle":2,"medictool":1,"mining_tool":1,"salvage_tool":1}
static func known(item: String) -> bool:
	return SHIP_COMPONENTS.known(item) or SPACE_COMPONENTS.known(item) or item in ["armor_light","armor_medium","armor_heavy","ore","salvage","a_benit","b_benit","c_benit","satellite_chip","outpost_chip","c_benit_crate","mining_tool","salvage_tool","backpack","ammo_light","ammo_rifle","ammo_rail","ammo_rocket"] or LOADOUT.HOMEBASE_PRIMARY_WEAPON_IDS.has(item)
static func compatible(item: String, slot: String) -> bool:
	return item in ["armor_light","armor_medium","armor_heavy"] if slot=="armor" else (slot in ["weapon_1","weapon_2"] and LOADOUT.HOMEBASE_PRIMARY_WEAPON_IDS.has(item))
static func item_from_slot(slot: String, value: String) -> String:
	if slot == "armor" and value == "suit": return "suit"
	return "armor_"+value if slot=="armor" else value
static func used(items: Dictionary) -> int:
	var count := 0
	for item in items:
		if not RESERVED_QUEST_ITEMS.has(String(item)): count += int(items[item])
	return count
static func count_chips(items: Dictionary) -> int:
	var count := 0
	for item in DATA_CHIP_ITEMS:
		count += int(items.get(item, 0))
	return count

static func ammo_rules() -> Dictionary:
	if _ammo_rules.is_empty():
		_ammo_rules = AMMO_RULES.load_rules()
	return _ammo_rules

static func count_ammo(items: Dictionary) -> int:
	var count := 0
	var rules := ammo_rules()
	for item in items:
		if AMMO_RULES.is_ammo_item(String(item), rules): count += int(items[item])
	return count

## Belegte Magazinplaetze im Ruestungsfach (nie mehr als die Fachgroesse). Chips zaehlen NICHT mit (M2-5): fuer sie gilt
## unveraendert die Regel von vor M2 (der erste Chip ist frei vom Rucksack, jeder weitere belegt einen Rucksackplatz).
static func compartment_used(data: Dictionary) -> int:
	return mini(int(data.get("armor_chip_capacity", 0)), count_ammo(data.get("items", {})))

static func backpack_slots_used(data: Dictionary) -> int:
	var items: Dictionary = data.get("items", {})
	var armor_slots := int(data.get("armor_chip_capacity", 0))
	var used_slots := used(items)
	if armor_slots > 0:
		# Chips: wie vor M2 (ein freier Chip, jeder weitere zaehlt gegen den Rucksack) - unabhaengig von den Magazinen.
		used_slots += maxi(0, count_chips(items) - ARMOR_CHIP_CAPACITY) + int(items.get("c_benit_crate", 0))
		# Magazine: die ersten `armor_slots` liegen im Fach; nur der Rest zaehlt gegen den Rucksack.
		used_slots -= mini(count_ammo(items), armor_slots)
	return used_slots

static func has_space(data: Dictionary, item: String, amount: int) -> bool:
	var items: Dictionary = Dictionary(data.get("items", {})).duplicate()
	items[item] = int(items.get(item, 0)) + amount
	var probe: Dictionary = data.duplicate()
	probe["items"] = items
	return backpack_slots_used(probe) <= int(data.capacity)

static func positive_integer(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value)) and float(value)>0 and float(value)==floor(float(value)) and float(value)<=2147483647
static func valid_container(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or typeof(data.get("items")) != TYPE_DICTIONARY:
		return false
	var capacity: Variant = data.get("capacity")
	# Alte Staende tragen 1; neue die Groesse der Ruestung. Beim Laden wird sie aus der Ruestung neu bestimmt.
	if data.has("armor_chip_capacity") and not (positive_integer(data.armor_chip_capacity) and float(data.armor_chip_capacity) <= MAX_COMPARTMENT_CAPACITY):
		return false
	if not positive_integer(capacity) and not (data.has("armor_chip_capacity") and typeof(capacity) in [TYPE_INT, TYPE_FLOAT] and capacity == 0):
		return false
	for item in data.items:
		if not known(String(item)) or not positive_integer(data.items[item]): return false
		if RESERVED_QUEST_ITEMS.has(String(item)) and int(data.items[item])>1: return false
	return backpack_slots_used(data) <= int(data.capacity)
