extends RefCounted
## Item identities and pure bounded-container validation; no gameplay mutation.
const LOADOUT = preload("res://scripts/command/loadout_contract.gd")
const START_STOCK := {"armor_light":2,"armor_medium":2,"armor_heavy":2,"smg":2,"rifle":2,"medictool":1,"mining_tool":1,"salvage_tool":1}
static func known(item: String) -> bool:
	return item in ["armor_light","armor_medium","armor_heavy","ore","salvage","mining_tool","salvage_tool"] or LOADOUT.HOMEBASE_PRIMARY_WEAPON_IDS.has(item)
static func compatible(item: String, slot: String) -> bool:
	return item in ["armor_light","armor_medium","armor_heavy"] if slot=="armor" else (slot in ["weapon_1","weapon_2"] and LOADOUT.HOMEBASE_PRIMARY_WEAPON_IDS.has(item))
static func item_from_slot(slot: String, value: String) -> String:
	return "armor_"+value if slot=="armor" else value
static func used(items: Dictionary) -> int:
	var count := 0
	for amount in items.values(): count += int(amount)
	return count
static func positive_integer(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value)) and float(value)>0 and float(value)==floor(float(value)) and float(value)<=2147483647
static func valid_container(data: Variant) -> bool:
	if typeof(data)!=TYPE_DICTIONARY or typeof(data.get("items"))!=TYPE_DICTIONARY or not positive_integer(data.get("capacity")): return false
	for item in data.items:
		if not known(String(item)) or not positive_integer(data.items[item]): return false
	return used(data.items)<=int(data.capacity)
