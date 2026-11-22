extends RefCounted
## Item identities and pure bounded-container validation; no gameplay mutation.
const SHIP_COMPONENTS = preload("res://scripts/mission/ship_equipment_catalog.gd")
const SPACE_COMPONENTS = preload("res://scripts/mission/space_component_catalog.gd")
const LOADOUT = preload("res://scripts/command/loadout_contract.gd")
const DATA_CHIP_ITEMS := ["satellite_chip", "outpost_chip"]
const RESERVED_QUEST_ITEMS := ["satellite_chip","outpost_chip","c_benit_crate"]
const ARMOR_CHIP_CAPACITY := 1
const BACKPACK_CAPACITY := 12
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

static func backpack_slots_used(data: Dictionary) -> int:
	var items: Dictionary = data.get("items", {})
	var armor_slots := int(data.get("armor_chip_capacity", 0))
	var used_slots := used(items)
	if armor_slots > 0:
		used_slots += maxi(0, count_chips(items) - armor_slots) + int(items.get("c_benit_crate", 0))
	return used_slots

static func has_space(data: Dictionary, item: String, amount: int) -> bool:
	var used_slots := backpack_slots_used(data)
	var armor_slots := int(data.get("armor_chip_capacity", 0))
	if armor_slots > 0 and DATA_CHIP_ITEMS.has(item):
		var free_armor_slots := maxi(0, armor_slots - count_chips(data.items))
		used_slots += maxi(0, amount - free_armor_slots)
	elif armor_slots > 0 or not RESERVED_QUEST_ITEMS.has(item):
		used_slots += amount
	return used_slots <= int(data.capacity)

static func positive_integer(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value)) and float(value)>0 and float(value)==floor(float(value)) and float(value)<=2147483647
static func valid_container(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or typeof(data.get("items")) != TYPE_DICTIONARY:
		return false
	var capacity: Variant = data.get("capacity")
	if data.has("armor_chip_capacity") and data.armor_chip_capacity != ARMOR_CHIP_CAPACITY:
		return false
	if not positive_integer(capacity) and not (data.has("armor_chip_capacity") and typeof(capacity) in [TYPE_INT, TYPE_FLOAT] and capacity == 0):
		return false
	for item in data.items:
		if not known(String(item)) or not positive_integer(data.items[item]): return false
		if RESERVED_QUEST_ITEMS.has(String(item)) and int(data.items[item])>1: return false
	return backpack_slots_used(data) <= int(data.capacity)
