extends RefCounted
## Pure ammunition rules. No scene, no state, nothing here changes its input.
## All balance values come from data/combat/ammo_rules.json (compartment sizes, item ids and names)
## and from the weapon data (ammo_class, magazine_size, reload_ticks per weapon).
## A weapon state is {"rounds": int, "reload_ticks_left": int}; the caller owns the reserve magazines.

const RULES_PATH := "res://data/combat/ammo_rules.json"

static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT

static func _is_count(value: Variant) -> bool:
	return _is_number(value) and is_finite(float(value)) and float(value) >= 0.0 and float(value) == floor(float(value))

static func validate_rules(d: Dictionary) -> bool:
	if not _is_count(d.get("default_compartment_capacity")):
		return false
	var by_armor: Variant = d.get("compartment_capacity_by_armor")
	if not by_armor is Dictionary or not by_armor.has("suit"):
		return false
	for armor in by_armor:
		if not _is_count(by_armor[armor]):
			return false
	var items: Variant = d.get("ammo_items")
	if not items is Dictionary or items.is_empty():
		return false
	for item in items:
		if String(item) == "" or not items[item] is String or String(items[item]) == "":
			return false
	return true

static func load_rules(path: String = RULES_PATH) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("ammo_rules: cannot open %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or not validate_rules(parsed):
		push_error("ammo_rules: invalid rules in %s" % path)
		return {}
	return parsed

static func compartment_capacity(armor_id: String, rules: Dictionary) -> int:
	var by_armor: Dictionary = rules.get("compartment_capacity_by_armor", {})
	if armor_id != "" and by_armor.has(armor_id):
		return int(by_armor[armor_id])
	return int(rules.get("default_compartment_capacity", 0))

## Faktor auf reload_ticks der Waffe fuer die Nachladezeit im Gefecht (M4a); ohne Eintrag 6, nie unter 1.
const DEFAULT_RELOAD_SCALE := 6

static func reload_scale(rules: Dictionary) -> int:
	var value: Variant = rules.get("reload_scale", DEFAULT_RELOAD_SCALE)
	return maxi(1, int(value)) if _is_number(value) else DEFAULT_RELOAD_SCALE

## Faktor auf magazine_size der Waffe fuer die wirksame Magazingroesse im Gefecht (M4b); ohne Eintrag 2.0, nie unter 0.1.
const DEFAULT_MAGAZINE_SCALE := 2.0

static func magazine_scale(rules: Dictionary) -> float:
	var value: Variant = rules.get("magazine_scale", DEFAULT_MAGAZINE_SCALE)
	return maxf(0.1, float(value)) if _is_number(value) else DEFAULT_MAGAZINE_SCALE

## Wirksame Magazingroesse: magazine_size x magazine_scale, gerundet, mindestens 1 (0 bleibt 0 = kein Munitionsbedarf).
static func effective_magazine_size(magazine_size: int, rules: Dictionary) -> int:
	if magazine_size <= 0:
		return 0
	return maxi(1, roundi(float(magazine_size) * magazine_scale(rules)))

## Magazine, die zu Beginn einer Kampagne im Basislager liegen (M4b): {Gegenstand: Anzahl}, nur bekannte Magazinsorten.
static func start_base_stock(rules: Dictionary) -> Dictionary:
	var stock: Dictionary = {}
	var configured: Variant = rules.get("start_base_stock", {})
	if configured is Dictionary:
		for item in configured:
			if is_ammo_item(String(item), rules) and _is_count(configured[item]) and int(configured[item]) > 0:
				stock[String(item)] = int(configured[item])
	return stock

static func is_ammo_item(item_id: String, rules: Dictionary) -> bool:
	return Dictionary(rules.get("ammo_items", {})).has(item_id)

static func new_weapon_state(magazine_size: int) -> Dictionary:
	return {"rounds": maxi(0, magazine_size), "reload_ticks_left": 0}

static func can_fire(state: Dictionary, needs_ammo: bool) -> bool:
	if not needs_ammo:
		return true
	return int(state.get("rounds", 0)) > 0 and int(state.get("reload_ticks_left", 0)) <= 0

static func after_shot(state: Dictionary) -> Dictionary:
	var result: Dictionary = state.duplicate(true)
	result["rounds"] = maxi(0, int(state.get("rounds", 0)) - 1)
	return result

static func needs_reload(state: Dictionary) -> bool:
	return int(state.get("rounds", 0)) == 0 and int(state.get("reload_ticks_left", 0)) <= 0

static func begin_reload(state: Dictionary, reload_ticks: int) -> Dictionary:
	var result: Dictionary = state.duplicate(true)
	result["reload_ticks_left"] = maxi(1, reload_ticks)
	return result

static func advance_reload(state: Dictionary, ticks: int, magazine_size: int) -> Dictionary:
	var result: Dictionary = state.duplicate(true)
	var left: int = int(state.get("reload_ticks_left", 0))
	if left <= 0:
		return result
	left = maxi(0, left - maxi(0, ticks))
	result["reload_ticks_left"] = left
	if left == 0:
		result["rounds"] = maxi(0, magazine_size)
	return result
