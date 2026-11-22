extends RefCounted
## Nottankdienst, Zeitablauf und Auftragszustand (T2 des Tanker-Auftrags, 21.11.2026).
##
## Dieser Besitzer fuehrt NUR die Zustaende und die Restzeit der offenen Auftraege. Geld, Treibstoff und Belege
## gehoeren dem Versorgungsbesitzer (SingleplayerSupplyState: Befehle emergency_tanker_order / _deliver / _cancel).
## Die Laufzeit-Stelle (singleplayer_runtime_adapter.gd) tickt diesen Besitzer, bucht die Lieferung und schliesst den Auftrag.
##
## Zustaende in dieser Reihenfolge: requested (dispatch_seconds) -> en_route (response_seconds) -> at_ship -> refuelling
## (refuel_seconds) -> completed. Endzustaende daneben: cancelled, expired. at_ship hat keine eigene Dauer in den Daten: der
## Zustand dauert bis zum naechsten Tick (die Restzeit des Ankunfts-Ticks verfaellt).
##
## Der Tick aendert die Revision des Versorgungsstands NICHT (dieser Besitzer kennt sie nicht); nur die Befehle bestellen,
## liefern und stornieren dort und heben die Revision.

const SCHEMA_VERSION := 1
const OPEN_STATES: Array = ["requested", "en_route", "at_ship", "refuelling"]
const END_STATES: Array = ["completed", "cancelled", "expired"]
const STATE_LABELS: Dictionary = {
	"requested": "Tanker angefordert",
	"en_route": "Tanker unterwegs",
	"at_ship": "Tanker am Schiff",
	"refuelling": "Betankung läuft",
	"completed": "Betankt, abgeschlossen",
	"cancelled": "Tankerruf storniert",
	"expired": "Tankerruf verfallen",
}
## Deutsche Saetze je Ablehnungsgrund (tanker-phase1-report.md e6, dazu die Gruende aus T2).
const REASON_TEXTS: Dictionary = {
	"insufficient_credits": "Zu wenig Credits für den Tankerruf (%d Cr nötig).",
	"tank_nearly_full": "Tank fast voll, Notlieferung lohnt nicht.",
	"at_service_point": "Hier kann normal getankt werden.",
	"tanker_order_open": "Ein Tanker ist bereits unterwegs.",
	"craft_unavailable": "Schiff nicht erreichbar.",
	"no_fuel_problem": "Der Treibstoff reicht für die nächste Etappe.",
	"tanker_already_arrived": "Der Tanker ist schon am Schiff.",
	"no_open_order": "Es gibt keinen offenen Tankerauftrag.",
	"emergency_fuel_unavailable": "Der Tankerdienst ist nicht verfügbar.",
	"tanker_not_authorized": "Tankerauftrag nicht bestätigt.",
	"unknown_order": "Tankerauftrag unbekannt.",
	"order_closed": "Der Tankerauftrag ist schon abgeschlossen.",
	"invalid_request_id": "Anfrage-ID passt nicht zum Tankerauftrag.",
	"invalid_command": "Tankerauftrag ungültig.",
}

var _orders: Dictionary = {}
var _finished: Dictionary = {}

## Satz zu einem Ablehnungsgrund. details darf price (insufficient_credits) tragen.
static func message_for(reason: String, details: Dictionary = {}) -> String:
	var text: String = String(REASON_TEXTS.get(reason, "Tankerruf nicht möglich."))
	if reason == "insufficient_credits": return text % int(details.get("price", 0))
	return text

static func state_label(state: String) -> String:
	return String(STATE_LABELS.get(state, state))

static func _is_number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value))

static func _reject(reason: String, extra: Dictionary = {}) -> Dictionary:
	var result := {"ok": false, "reason": reason, "message": message_for(reason, extra)}
	result.merge(extra, false)
	return result

## Legt einen offenen Auftrag aus dem Beleg des Versorgungsbesitzers an (Ergebnis von emergency_tanker_order).
func open_order(receipt: Dictionary) -> Dictionary:
	var craft_id := String(receipt.get("craft_id", ""))
	var order_id := String(receipt.get("order_id", ""))
	if craft_id.is_empty() or order_id.is_empty(): return _reject("invalid_command")
	if _orders.has(craft_id): return _reject("tanker_order_open")
	var order := {
		"order_id": order_id, "craft_id": craft_id, "state": "requested",
		"quantity": int(receipt.get("quantity", 0)), "price": int(receipt.get("price", 0)),
		"callout_fee": int(receipt.get("callout_fee", 0)),
		"dispatch_seconds": float(receipt.get("dispatch_seconds", 0.0)),
		"response_seconds": float(receipt.get("response_seconds", 0.0)),
		"refuel_seconds": float(receipt.get("refuel_seconds", 0.0)),
		"delivery_retry_seconds": float(receipt.get("delivery_retry_seconds", 0.0)),
		"retry_elapsed": 0.0, "failure_reason": "",
		"remaining": float(receipt.get("dispatch_seconds", 0.0)),
	}
	if int(order.quantity) <= 0 or int(order.price) < int(order.callout_fee): return _reject("invalid_command")
	_orders[craft_id] = order
	_finished.erase(craft_id)
	return {"ok": true, "order": order.duplicate(true)}

func has_open_orders() -> bool:
	return not _orders.is_empty()

func get_order(craft_id: String) -> Dictionary:
	return Dictionary(_orders.get(craft_id, {})).duplicate(true)

## Zuletzt beendeter Auftrag je Schiff ({order_id, craft_id, state, ...}); nur Laufzeit, wird nicht gespeichert.
func get_finished(craft_id: String) -> Dictionary:
	return Dictionary(_finished.get(craft_id, {})).duplicate(true)

func open_orders() -> Array:
	var result: Array = []
	var ids: Array = _orders.keys()
	ids.sort()
	for craft_id: String in ids: result.append(Dictionary(_orders[craft_id]).duplicate(true))
	return result

## Schreibt die Zeit fort. Gibt die Auftraege zurueck, deren Betankung fertig ist und deren Lieferung noch gebucht werden muss
## (Zustand bleibt refuelling mit Restzeit 0, bis complete() gerufen wird; ein Tick danach meldet sie erneut, falls die Buchung scheiterte).
func advance(delta: float) -> Array:
	var due: Array = []
	var ids: Array = _orders.keys()
	ids.sort()
	for craft_id: String in ids:
		var order: Dictionary = _orders[craft_id]
		var left: float = maxf(delta if is_finite(delta) else 0.0, 0.0)
		while true:
			var state := String(order.state)
			if state == "requested" or state == "en_route":
				if left + 0.000001 < float(order.remaining):
					order.remaining = float(order.remaining) - left
					break
				left = maxf(left - float(order.remaining), 0.0)
				if state == "requested":
					order.state = "en_route"
					order.remaining = float(order.response_seconds)
					continue
				order.state = "at_ship"
				order.remaining = 0.0
				break
			if state == "at_ship":
				order.state = "refuelling"
				order.remaining = float(order.refuel_seconds)
				continue
			# refuelling
			if left + 0.000001 < float(order.remaining):
				order.remaining = float(order.remaining) - left
			else:
				order.remaining = 0.0
				due.append(order.duplicate(true))
			break
	return due

## Die Lieferung ist gebucht: der Auftrag ist abgeschlossen.
## refund: die Teilerstattung aus dem Lieferergebnis (0 bei voller Menge); T3 zeigt sie an.
func complete(order_id: String, delivered: int, refund: int = 0) -> bool:
	return _finish(order_id, "completed", {"delivered": delivered, "refund": refund})

## Die faellige Lieferung konnte nicht gebucht werden (der Versorgungsbesitzer lehnte mit reason ab). Merkt den Grund und zaehlt die
## Wiederholzeit; gibt true zurueck, sobald die Frist delivery_retry_seconds (aus den Daten, im Auftrag mitgefuehrt) abgelaufen ist.
## Der Tick, der den Fehler zum ersten Mal sieht, zaehlt nicht mit (darin steckt noch die Betankungszeit). Aendert keinen Versorgungsstand.
func note_delivery_failure(order_id: String, reason: String, delta: float) -> bool:
	for craft_id: String in _orders:
		var order: Dictionary = _orders[craft_id]
		if String(order.order_id) != order_id: continue
		if String(order.get("failure_reason", "")).is_empty():
			order["retry_elapsed"] = 0.0
		else:
			order["retry_elapsed"] = float(order.get("retry_elapsed", 0.0)) + (maxf(delta, 0.0) if is_finite(delta) else 0.0)
		order["failure_reason"] = reason if not reason.is_empty() else "unknown"
		return float(order.retry_elapsed) + 0.000001 >= float(order.delivery_retry_seconds)
	return false

## Storno oder Verfall (end_state cancelled / expired), nachdem der Versorgungsbesitzer erstattet hat. why: Grund des Verfalls (Anzeige/Protokoll).
func close_order(order_id: String, end_state: String, refund: int = 0, why: String = "") -> bool:
	if end_state not in ["cancelled", "expired"]: return false
	var extra := {"refund": refund}
	if not why.is_empty(): extra["reason"] = why
	return _finish(order_id, end_state, extra)

func _finish(order_id: String, end_state: String, extra: Dictionary) -> bool:
	for craft_id: String in _orders.keys():
		var order: Dictionary = _orders[craft_id]
		if String(order.order_id) != order_id: continue
		var done: Dictionary = order.duplicate(true)
		done["state"] = end_state
		done["remaining"] = 0.0
		done["closed_msec"] = Time.get_ticks_msec()
		done.merge(extra, true)
		_finished[craft_id] = done
		_orders.erase(craft_id)
		return true
	return false

## Lesesicht fuer die Anzeige: je Schiff der offene Auftrag mit Restzeiten, dazu der zuletzt beendete.
func get_snapshot() -> Dictionary:
	var orders := {}
	for craft_id: String in _orders:
		orders[craft_id] = _project(_orders[craft_id])
	var finished := {}
	for craft_id: String in _finished:
		var done: Dictionary = Dictionary(_finished[craft_id]).duplicate(true)
		done["state_label"] = state_label(String(done.get("state", "")))
		done["age_seconds"] = float(Time.get_ticks_msec() - int(done.get("closed_msec", 0))) / 1000.0
		finished[craft_id] = done
	return {"orders": orders, "finished": finished}

func _project(order: Dictionary) -> Dictionary:
	var view: Dictionary = order.duplicate(true)
	var state := String(order.state)
	var eta := 0.0
	if state == "requested": eta = float(order.remaining) + float(order.response_seconds)
	elif state == "en_route": eta = float(order.remaining)
	view["state_label"] = state_label(state)
	view["eta_seconds"] = eta
	view["can_cancel"] = state in ["requested", "en_route"]
	view["refund_if_cancelled"] = int(order.price) if state == "requested" else (int(order.price) - int(order.callout_fee) if state == "en_route" else 0)
	return view

# --- Spielstand -----------------------------------------------------------------------------------

func export_state() -> Dictionary:
	return {"schema_version": SCHEMA_VERSION, "orders": open_orders()}

## Prueft und uebernimmt einen gespeicherten Dienstzustand. Bei Fehler bleibt dieser Besitzer unveraendert.
## Fehlt der Stand ganz (alter Spielstand), gilt "kein Auftrag" (clear()).
func restore_state(data: Dictionary) -> Dictionary:
	if data.get("schema_version") != SCHEMA_VERSION or typeof(data.get("orders")) != TYPE_ARRAY: return _reject("invalid_tanker_state")
	var restored := {}
	for entry: Variant in data.orders:
		if typeof(entry) != TYPE_DICTIONARY: return _reject("invalid_tanker_state")
		var checked: Dictionary = _checked_order(entry)
		if not checked.get("ok", false): return checked
		var order: Dictionary = checked.order
		if restored.has(order.craft_id): return _reject("invalid_tanker_state")
		restored[order.craft_id] = order
	_orders = restored
	_finished.clear()
	return {"ok": true}

func clear() -> void:
	_orders.clear()
	_finished.clear()

func _checked_order(entry: Dictionary) -> Dictionary:
	for key: String in ["order_id", "craft_id", "state"]:
		if typeof(entry.get(key)) != TYPE_STRING or String(entry[key]).is_empty(): return _reject("invalid_tanker_state")
	for key: String in ["quantity", "price", "callout_fee", "dispatch_seconds", "response_seconds", "refuel_seconds", "delivery_retry_seconds", "remaining"]:
		if not _is_number(entry.get(key)) or float(entry[key]) < 0.0: return _reject("invalid_tanker_state")
	if entry.has("retry_elapsed") and (not _is_number(entry.retry_elapsed) or float(entry.retry_elapsed) < 0.0): return _reject("invalid_tanker_state")
	if entry.has("failure_reason") and typeof(entry.failure_reason) != TYPE_STRING: return _reject("invalid_tanker_state")
	var state := String(entry.state)
	if state not in OPEN_STATES: return _reject("invalid_tanker_state")
	var quantity := float(entry.quantity)
	if quantity <= 0.0 or quantity != floorf(quantity) or float(entry.price) != floorf(float(entry.price)) or float(entry.callout_fee) != floorf(float(entry.callout_fee)) or float(entry.price) < float(entry.callout_fee): return _reject("invalid_tanker_state")
	var cap := {"requested": float(entry.dispatch_seconds), "en_route": float(entry.response_seconds), "at_ship": 0.0, "refuelling": float(entry.refuel_seconds)}
	if float(entry.remaining) > float(cap[state]) + 0.000001: return _reject("invalid_tanker_state")
	return {"ok": true, "order": {
		"order_id": String(entry.order_id), "craft_id": String(entry.craft_id), "state": state,
		"quantity": int(quantity), "price": int(entry.price), "callout_fee": int(entry.callout_fee),
		"dispatch_seconds": float(entry.dispatch_seconds), "response_seconds": float(entry.response_seconds),
		"refuel_seconds": float(entry.refuel_seconds), "delivery_retry_seconds": float(entry.delivery_retry_seconds),
		"retry_elapsed": float(entry.get("retry_elapsed", 0.0)), "failure_reason": String(entry.get("failure_reason", "")),
		"remaining": float(entry.remaining),
	}}

## Gleicht einen Dienstzustand (export_state) mit den offenen Bestellbelegen des Versorgungsbesitzers ab
## (SingleplayerSupplyState.get_open_tanker_orders(): order_id -> Ergebnis des Bestellbefehls).
## Auftrag ohne Beleg, Beleg ohne Auftrag oder abweichende Werte: der Stand ist abzulehnen, nie stillschweigend zu reparieren.
## Ein fehlender Dienstzustand (alter Stand) zaehlt als "kein Auftrag".
static func validate_against_receipts(service_state: Dictionary, open_receipts: Dictionary) -> Dictionary:
	var probe = load("res://scripts/core/emergency_tanker_service.gd").new()
	if not service_state.is_empty():
		var restored: Dictionary = probe.restore_state(service_state)
		if not restored.get("ok", false): return restored
	var seen := {}
	for order: Dictionary in probe.open_orders():
		var receipt: Dictionary = Dictionary(open_receipts.get(order.order_id, {}))
		if receipt.is_empty(): return _reject("tanker_order_without_receipt")
		for key: String in ["craft_id", "quantity", "price", "callout_fee", "dispatch_seconds", "response_seconds", "refuel_seconds", "delivery_retry_seconds"]:
			var same: bool = String(order[key]) == String(receipt.get(key, "")) if key == "craft_id" else is_equal_approx(float(order[key]), float(receipt.get(key, -1.0)))
			if not same: return _reject("tanker_order_mismatch")
		seen[order.order_id] = true
	for order_id: String in open_receipts:
		if not seen.has(order_id): return _reject("tanker_receipt_without_order")
	return {"ok": true}
