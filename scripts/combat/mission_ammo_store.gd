extends RefCounted
## M6a: Einsatz-Vorrat an Reservemagazinen fuer Einheiten OHNE Kampagnen-Vorrat (Gegner, NPCs, Skirmish, Mehrspieler-Host).
## Reine Daten, keine Szene: je Einheit die Zahl der Reservemagazine je Magazinsorte. Beim ersten Bedarf (ensure) bekommt die
## Einheit so viele Magazine, wie das Fach ihrer Ruestung fasst (data/combat/ammo_rules.json, unbekannte Ruestung wie "medium"),
## in der Sorte ihrer ersten Waffe mit Munition. Das geladene Magazin kommt zusaetzlich aus combat_ammo.gd (voll zu Beginn).
## Der Vorrat gehoert zum Einsatz: reset() leert ihn (Start, Neustart); er steht nur im Einsatz-Checkpoint (snapshot/restore).

const AMMO_RULES = preload("res://scripts/core/ammo_rules.gd")
const FALLBACK_ARMOR := "medium"

var _rules: Dictionary = {}
## unit_id -> {ammo_class: Anzahl}
var _units: Dictionary = {}


func _init() -> void:
	_rules = AMMO_RULES.load_rules()


func reset() -> void:
	_units.clear()


## Startmenge nach Fach der Ruestung; unbekannte oder leere Ruestung zaehlt wie "medium".
func start_count(armor_id: String) -> int:
	var by_armor: Dictionary = Dictionary(_rules.get("compartment_capacity_by_armor", {}))
	var armor: String = armor_id if by_armor.has(armor_id) else FALLBACK_ARMOR
	return AMMO_RULES.compartment_capacity(armor, _rules)


func has_unit(unit_id: String) -> bool:
	return _units.has(unit_id)


## Legt die Einheit beim ersten Bedarf an (ein zweiter Aufruf aendert nichts). Sorte "" oder unbekannt: angelegt, aber ohne Magazine.
func ensure(unit_id: String, armor_id: String, ammo_class: String) -> bool:
	if unit_id == "":
		return false
	if _units.has(unit_id):
		return true
	var stock: Dictionary = {}
	if AMMO_RULES.is_ammo_item(ammo_class, _rules):
		stock[ammo_class] = start_count(armor_id)
	_units[unit_id] = stock
	return true


func count(unit_id: String, ammo_class: String) -> int:
	if not _units.has(unit_id):
		return 0
	return maxi(0, int(Dictionary(_units[unit_id]).get(ammo_class, 0)))


## Zieht ein Reservemagazin ab; nie ins Minus.
func take(unit_id: String, ammo_class: String) -> bool:
	if count(unit_id, ammo_class) <= 0:
		return false
	var stock: Dictionary = _units[unit_id]
	stock[ammo_class] = int(stock[ammo_class]) - 1
	return true


## Fuer den Einsatz-Checkpoint: {"units": {unit_id: {ammo_class: n}}} (Kopie).
func snapshot() -> Dictionary:
	return {"units": _units.duplicate(true)}


## Stellt einen Stand wieder her; leerer Schnappschuss = leer (volle Startmenge beim ersten Bedarf). Kaputtes wird abgelehnt, der Stand bleibt.
func restore(data: Dictionary) -> bool:
	var units: Variant = data.get("units", {})
	if not units is Dictionary:
		return false
	var clean: Dictionary = {}
	for unit_id in units:
		var stock: Variant = units[unit_id]
		if String(unit_id) == "" or not stock is Dictionary:
			return false
		var row: Dictionary = {}
		for ammo_class in stock:
			var n: Variant = stock[ammo_class]
			if not (typeof(n) == TYPE_INT or typeof(n) == TYPE_FLOAT) or float(n) < 0.0:
				return false
			row[String(ammo_class)] = int(n)
		clean[String(unit_id)] = row
	_units = clean
	return true
