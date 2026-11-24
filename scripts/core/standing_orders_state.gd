extends RefCounted
## Dauerauftraege (Handel H3): Auftraege, die an einem Ort immer dastehen (Fracht, Mining, Bergung). Reine Regeln, keine Szene.
## Eigener Besitzer mit eigener durchgehender Uhr (Sekunden Spielzeit). Ist ein Auftrag zu Ende (Abgabe oder Aufgabe), beginnt fuer genau
## diesen Auftrag (Schluessel = id, also je Ort UND Ware) die Sperrzeit `lock_seconds`. Preise stehen nur in standing_orders.json.
## Kein class_name: Einbinden ueber preload("res://scripts/core/standing_orders_state.gd").
##
## VERBINDLICHE REIHENFOLGE fuer den Einbau (Aufgabe B), jeweils in EINER Buchung des Versorgungsstands:
##  - Uebernehmen: 1. can_accept(id, owned) pruefen, 2. Kisten buchen, 3. accept(id, owned). Scheitert Schritt 2, ist noch nichts am
##    Auftrag geaendert. accept vergibt die Nummer (get_active(kind).number, ueberlebt Speichern/Laden) und zaehlt standing_counter hoch.
##  - Abliefern/Aufgeben: 1. finish(id, delivered) ZUERST; es lehnt einen zweiten Aufruf ab (false) und verlaengert die Sperre nicht.
##    Erst bei true: 2. Kisten entfernen und Lohn buchen. So wird der Lohn genau einmal gebucht.
##  - Im Versorgungsstand aendern standing_accept_state / standing_finish_state Zustand und _revision zusammen; B ruft nur diese.
##  - Die Uhr (advance_clock) erhoeht die _revision bewusst nicht (sie tickt je Bild).
const KINDS: Array = ["freight", "mining", "salvage"]
const MAX_CLOCK := 1.0e9
const MAX_LOCK_SECONDS := 86400
const MAX_CRATES := 48
const MAX_PAY := 1000000
const TEXT_NOT_PLAYABLE := "Noch nicht spielbar – kommt mit einem späteren Ausbau."

var _lock_seconds: int = 0
var _orders: Dictionary = {}
var _order_ids: Array = []
var _clock: float = 0.0
var _locks: Dictionary = {}
var _active: Dictionary = {}
var _counter: int = 0
var _location_names: Dictionary = {}
var _item_names: Dictionary = {}

## definitions = Inhalt von standing_orders.json. Bei einer Fehlform false und der Besitzer bleibt unveraendert.
func configure(definitions: Dictionary) -> bool:
	if not _is_whole(definitions.get("lock_seconds")) or int(definitions.lock_seconds) < 1 or int(definitions.lock_seconds) > MAX_LOCK_SECONDS:
		return false
	if typeof(definitions.get("orders")) != TYPE_ARRAY or Array(definitions.orders).is_empty():
		return false
	var orders: Dictionary = {}
	var ids: Array = []
	for raw: Variant in definitions.orders:
		var order: Dictionary = _normalized(raw)
		if order.is_empty() or orders.has(order.id):
			return false
		orders[order.id] = order
		ids.append(order.id)
	_lock_seconds = int(definitions.lock_seconds)
	_orders = orders
	_order_ids = ids
	_clock = 0.0
	_locks = {}
	_active = {}
	_counter = 0
	return true

## Anzeigenamen (nur Darstellung): Ort-Kennung -> Name, Gegenstand-Kennung -> Name. Fehlt ein Name, steht die Rohkennung im Text.
func set_names(location_names: Dictionary, item_names: Dictionary) -> void:
	_location_names = location_names.duplicate()
	_item_names = item_names.duplicate()

func advance_clock(delta_seconds: float) -> void:
	if typeof(delta_seconds) not in [TYPE_FLOAT, TYPE_INT] or not is_finite(delta_seconds) or delta_seconds <= 0.0:
		return
	_clock = minf(_clock + delta_seconds, MAX_CLOCK)

func get_counter() -> int:
	return _counter

func lock_seconds() -> int:
	return _lock_seconds

## Ein Eintrag je Auftrag in Datenreihenfolge. owned_items = Stueckzahlen je Gegenstand ueber Basislager, Schiffe und Rucksaecke.
func get_snapshot(owned_items: Dictionary) -> Array:
	var result: Array = []
	for id: String in _order_ids:
		result.append(_entry(_orders[id], owned_items))
	return result

## ok/reason/message. owned_items nur angeben, wenn die Besitzpruefung (requires_item) mitlaufen soll.
func can_accept(id: String, owned_items: Variant = null) -> Dictionary:
	if not _orders.has(id):
		return {"ok": false, "reason": "unknown_order", "message": "Unbekannter Auftrag."}
	var entry: Dictionary = _entry(_orders[id], owned_items)
	var status: String = String(entry.status)
	if status == "open":
		return {"ok": true, "reason": "", "message": String(entry.message)}
	var reason: String = String(entry.reason)
	return {"ok": false, "reason": "already_active" if status == "active" else reason, "message": String(entry.message)}

func accept(id: String, owned_items: Variant = null) -> bool:
	if not bool(can_accept(id, owned_items).ok):
		return false
	_counter += 1
	_active[String(_orders[id].kind)] = {"id": id, "number": _counter}
	return true

## Namen der Gegenstaende, die ein Auftrag zur Annahme verlangt (requires_item). Nur diese muss der Besitzer zaehlen.
func required_items() -> Array:
	var items: Array = []
	for id: String in _order_ids:
		var item: String = String(_orders[id].get("requires_item", ""))
		if not item.is_empty() and not items.has(item):
			items.append(item)
	return items

## Beendet den laufenden Auftrag (delivered: Abgabe oder Aufgabe) und startet seine Sperrzeit. Lohn bucht der Aufrufer.
func finish(id: String, _delivered: bool) -> bool:
	if not _orders.has(id):
		return false
	var kind: String = String(_orders[id].kind)
	if String(Dictionary(_active.get(kind, {})).get("id", "")) != id:
		return false
	_active.erase(kind)
	_locks[id] = _clock + float(_lock_seconds)
	return true

## Der laufende Auftrag der Art (Definition samt id und number = laufende Nummer seiner Annahme) oder {}.
func get_active(kind: String) -> Dictionary:
	var active: Dictionary = Dictionary(_active.get(kind, {}))
	var id: String = String(active.get("id", ""))
	if not _orders.has(id): return {}
	var result: Dictionary = Dictionary(_orders[id]).duplicate(true)
	result["number"] = int(active.get("number", _counter))
	return result

func export_state() -> Dictionary:
	var locks: Dictionary = {}
	for id: String in _locks:
		if float(_locks[id]) > _clock:
			locks[id] = float(_locks[id])
	return {"standing_clock": _clock, "standing_locks": locks, "standing_active": _active.duplicate(true), "standing_counter": _counter}

## Fehlende Schluessel (alter Stand) = Uhr 0, keine Sperren, nichts aktiv. Fehlform -> false und nichts geaendert;
## Unbekanntes wird still verworfen, Werte werden gekappt (wie market_stock).
func restore_state(data: Dictionary) -> bool:
	var plan: Dictionary = _restore_plan(data)
	if plan.is_empty():
		return false
	_clock = float(plan.clock)
	_locks = plan.locks
	_active = plan.active
	_counter = int(plan.counter)
	return true

func validate_state(data: Dictionary) -> bool:
	return not _restore_plan(data).is_empty()

func _restore_plan(data: Dictionary) -> Dictionary:
	if _orders.is_empty():
		return {}
	var clock: Variant = data.get("standing_clock", 0.0)
	if typeof(clock) not in [TYPE_FLOAT, TYPE_INT] or not is_finite(float(clock)) or float(clock) < 0.0:
		return {}
	var now: float = minf(float(clock), MAX_CLOCK)
	var counter: Variant = data.get("standing_counter", 0)
	if not _is_whole(counter) or int(counter) < 0:
		return {}
	var saved_locks: Variant = data.get("standing_locks", {})
	var saved_active: Variant = data.get("standing_active", {})
	if typeof(saved_locks) != TYPE_DICTIONARY or typeof(saved_active) != TYPE_DICTIONARY:
		return {}
	var locks: Dictionary = {}
	for id: Variant in saved_locks:
		if typeof(id) != TYPE_STRING or not _orders.has(id):
			continue
		var end: Variant = saved_locks[id]
		if typeof(end) not in [TYPE_FLOAT, TYPE_INT] or not is_finite(float(end)):
			return {}
		if float(end) > now:
			locks[id] = minf(float(end), now + float(_lock_seconds))
	var active: Dictionary = {}
	for kind: Variant in saved_active:
		if typeof(kind) != TYPE_STRING or not KINDS.has(kind):
			continue
		var entry: Variant = saved_active[kind]
		if typeof(entry) != TYPE_DICTIONARY:
			return {}
		var id: Variant = Dictionary(entry).get("id")
		if typeof(id) == TYPE_STRING and _orders.has(id) and String(_orders[id].kind) == kind:
			# Nummer der Annahme; fehlt sie (Stand ohne Nummer), gilt der Zaehler.
			var number: Variant = Dictionary(entry).get("number", counter)
			if not _is_whole(number) or int(number) < 1 or int(number) > int(counter):
				return {}
			active[kind] = {"id": id, "number": int(number)}
	return {"clock": now, "locks": locks, "active": active, "counter": int(counter)}

func _entry(order: Dictionary, owned_items: Variant) -> Dictionary:
	var id: String = String(order.id)
	var entry: Dictionary = {"id": id, "kind": order.kind, "origin": order.origin, "destination": String(order.get("destination", "")), "item": order.item,
		"crates": int(order.get("crates", 0)), "pay": int(order.get("pay", 0)), "pay_per_unit": int(order.get("pay_per_unit", 0)),
		"status": "open", "lock_remaining_seconds": 0, "reason": "", "message": "", "title": _title(order)}
	var kind: String = String(order.kind)
	var required: String = String(order.get("requires_item", ""))
	# Fehlt owned_items (null), gilt nichts als im Besitz: die Werkzeugpflicht laesst sich nicht umgehen.
	var owned: Dictionary = owned_items if typeof(owned_items) == TYPE_DICTIONARY else {}
	var missing: bool = not required.is_empty() and int(owned.get(required, 0)) < 1
	if not bool(order.get("playable", true)):
		entry.status = "unavailable"
		entry.reason = "item_missing" if missing else "not_playable"
		entry.message = _missing_text(order) if missing else TEXT_NOT_PLAYABLE
	elif String(Dictionary(_active.get(kind, {})).get("id", "")) == id:
		entry.status = "active"
		entry.reason = "active"
		entry.message = "Unterwegs: %s nach %s." % [_crates_text(int(order.get("crates", 0))), _place(String(order.get("destination", "")))]
	elif _locks.has(id) and float(_locks[id]) > _clock:
		var remaining: int = ceili(float(_locks[id]) - _clock)
		entry.status = "locked"
		entry.reason = "locked"
		entry.lock_remaining_seconds = remaining
		entry.message = "Wieder verfügbar in %d:%02d." % [remaining / 60, remaining % 60]
	elif missing:
		entry.status = "unavailable"
		entry.reason = "item_missing"
		entry.message = _missing_text(order)
	elif _active.has(kind):
		entry.status = "unavailable"
		entry.reason = "kind_busy"
		entry.message = "Es läuft bereits ein Auftrag dieser Art."
	else:
		entry.message = "Annahme beim Händler in %s." % _place(String(order.origin))
	return entry

func _missing_text(order: Dictionary) -> String:
	var text: String = "Braucht: %s." % _item(String(order.get("requires_item", "")))
	if String(order.kind) == "mining":
		text += " Ein Mining-Schiff gibt es noch nicht."
	return text

func _title(order: Dictionary) -> String:
	var where: String = _place(String(order.origin))
	match String(order.kind):
		"freight":
			return "Fracht: %s %s nach %s · %d Cr" % [_crates_text(int(order.crates)), _item(String(order.item)), _place(String(order.destination)), int(order.pay)]
		"mining":
			return "Mining: %s (%s) · %d Cr je Stück" % [_item(String(order.item)), where, int(order.pay_per_unit)]
	return "Bergung: %s (%s) · %d Cr je Stück" % [_item(String(order.item)), where, int(order.pay_per_unit)]

func _crates_text(crates: int) -> String:
	return "%d Kiste" % crates if crates == 1 else "%d Kisten" % crates

func _place(id: String) -> String:
	return String(_location_names.get(id, id))

func _item(id: String) -> String:
	return String(_item_names.get(id, id))

func _normalized(raw: Variant) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	var order: Dictionary = raw
	for field: String in ["id", "kind", "origin", "item"]:
		if typeof(order.get(field)) != TYPE_STRING or String(order[field]).strip_edges().is_empty():
			return {}
	if not KINDS.has(order.kind) or typeof(order.get("playable", true)) != TYPE_BOOL:
		return {}
	if order.has("requires_item") and (typeof(order.requires_item) != TYPE_STRING or String(order.requires_item).strip_edges().is_empty()):
		return {}
	if order.kind == "freight":
		if typeof(order.get("destination")) != TYPE_STRING or String(order.destination).strip_edges().is_empty():
			return {}
		if not _is_whole(order.get("crates")) or int(order.crates) < 1 or int(order.crates) > MAX_CRATES:
			return {}
		if not _is_whole(order.get("pay")) or int(order.pay) < 0 or int(order.pay) > MAX_PAY:
			return {}
	elif not _is_whole(order.get("pay_per_unit")) or int(order.pay_per_unit) < 0 or int(order.pay_per_unit) > MAX_PAY:
		return {}
	return order.duplicate(true)

func _is_whole(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) == floorf(float(value)) and absf(float(value)) <= 2147483647.0
