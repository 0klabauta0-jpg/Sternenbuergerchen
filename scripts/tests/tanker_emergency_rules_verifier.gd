extends SceneTree
## T2 des Tanker-Auftrags (21.11.2026): Regeln des Nottankdienstes auf der Ebene der Besitzer.
## Echte Befehle am echten Versorgungsbesitzer (apply_command mit dem Kontext, den der Adapter liefert) und der echte
## Dienstbesitzer (emergency_tanker_service.gd). Die Verdrahtung beider (Bestellen -> Dienst anlegen, Tick -> Lieferung buchen)
## macht hier ein kleiner Treiber nach dem Muster des Adapters; die echte Verdrahtung im laufenden Spiel prueft
## tanker_emergency_flow_verifier.gd. Alle Zahlen stammen aus dem Datenblock emergency_fuel (Abschnitt J aendert ihn).

const SUPPLY: GDScript = preload("res://scripts/core/singleplayer_supply_state.gd")
const SERVICE: GDScript = preload("res://scripts/core/emergency_tanker_service.gd")
const DATA_PATH: String = "res://data/singleplayer/trade_offers.json"

var _passed := 0
var _failed := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, text: String) -> void:
	if condition:
		_passed += 1
		print("PASS: " + text)
	else:
		_failed += 1
		print("FAIL: " + text)

func _data() -> Dictionary:
	return Dictionary(JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)))

## Versorgungsbesitzer mit zwei Schiffen; fuel = Starttreibstoff (Standard 5: die naechste Etappe ist nicht gedeckt).
func _supply(fuel: float = 5.0, edit: Callable = Callable()) -> RefCounted:
	# Die Definitionen bleiben die der Datei (restore_state vergleicht sie streng mit den aktuellen); nur der Tank der Schiffe wird gesetzt.
	var data: Dictionary = _data()
	if edit.is_valid(): edit.call(data)
	var supply: RefCounted = SUPPLY.new()
	var configured: Dictionary = supply.configure([{"craft_id": "ship"}, {"craft_id": "ship2"}], data)
	if not configured.get("ok", false): print("FAIL: Versorgungsbesitzer konnte nicht konfiguriert werden: " + str(configured))
	var tanks: Dictionary = supply.get("_fuel_by_craft_id")
	for craft_id: String in tanks.keys(): tanks[craft_id] = fuel
	return supply

## Kontext wie ihn der Adapter aus get_fuel_status baut.
func _ctx(over: Dictionary = {}) -> Dictionary:
	var context := {"emergency_tanker_authorized": true, "craft_available": true, "at_service_point": false, "fuel_problem": true}
	context.merge(over, true)
	return context

func _cmd(operation: String, payload: Dictionary, request_id: String) -> Dictionary:
	return {"contract_category": "singleplayer_supply", "operation": operation, "payload": payload, "request_id": request_id}

func _leg(craft_id: String, leg: String, origin: String, destination: String, request_id: String) -> Dictionary:
	return _cmd("consume_leg_fuel", {"craft_id": craft_id, "leg": leg, "origin_location_id": origin, "destination_location_id": destination}, request_id)

# --- Treiber nach dem Muster des Adapters -------------------------------------------------------------

class Driver extends RefCounted:
	var supply: RefCounted
	var service: RefCounted
	var states: Array = []

	func _init(owner_supply: RefCounted, owner_service: RefCounted) -> void:
		supply = owner_supply
		service = owner_service

	func _cmd(operation: String, payload: Dictionary, request_id: String) -> Dictionary:
		return {"contract_category": "singleplayer_supply", "operation": operation, "payload": payload, "request_id": request_id}

	func order(craft_id: String, request_id: String, context: Dictionary) -> Dictionary:
		var result: Dictionary = supply.apply_command(_cmd("emergency_tanker_order", {"craft_id": craft_id}, request_id), context)
		if bool(result.get("ok", false)) and not bool(result.get("replayed", false)): service.open_order(result)
		return result

	var authorized := true
	var last_delivery: Dictionary = {}

	func tick(delta: float) -> void:
		for due: Dictionary in service.advance(delta):
			var delivered: Dictionary = supply.apply_command(_cmd("emergency_tanker_deliver", {"order_id": String(due.order_id)}, String(due.order_id) + ":deliver"), {"emergency_tanker_authorized": authorized})
			last_delivery = delivered
			if bool(delivered.get("ok", false)): service.complete(String(due.order_id), int(delivered.get("amount", 0)))
			elif String(delivered.get("reason", "")) in ["craft_unavailable", "unknown_order", "order_closed"]: expire(String(due.craft_id))
			elif service.note_delivery_failure(String(due.order_id), String(delivered.get("reason", "")), delta): expire(String(due.craft_id), String(delivered.get("reason", "")))
		var order_state := String(service.get_order("ship").get("state", ""))
		if order_state != "" and (states.is_empty() or states.back() != order_state): states.append(order_state)

	func cancel(craft_id: String) -> Dictionary:
		var order: Dictionary = service.get_order(craft_id)
		if order.is_empty(): return {"ok": false, "reason": "no_open_order"}
		var result: Dictionary = supply.apply_command(_cmd("emergency_tanker_cancel", {"order_id": String(order.order_id), "reason": "player"}, String(order.order_id) + ":cancel"), {"emergency_tanker_authorized": true, "emergency_tanker_state": String(order.state)})
		if bool(result.get("ok", false)) and not bool(result.get("replayed", false)): service.close_order(String(order.order_id), "cancelled", int(result.get("refund", 0)))
		return result

	func expire(craft_id: String, why: String = "") -> Dictionary:
		var order: Dictionary = service.get_order(craft_id)
		if order.is_empty(): return {"ok": false, "reason": "no_open_order"}
		var result: Dictionary = supply.apply_command(_cmd("emergency_tanker_cancel", {"order_id": String(order.order_id), "reason": "expired"}, String(order.order_id) + ":cancel"), {"emergency_tanker_authorized": true, "emergency_tanker_state": String(order.state)})
		if bool(result.get("ok", false)) and not bool(result.get("replayed", false)): service.close_order(String(order.order_id), "expired", int(result.get("refund", 0)), why)
		return result

func _driver(fuel: float = 5.0, edit: Callable = Callable()) -> Driver:
	return Driver.new(_supply(fuel, edit), SERVICE.new())

func _unchanged(supply: RefCounted, credits: int, fuel: float, revision: int) -> bool:
	return supply.get_credits() == credits and is_equal_approx(supply.get_fuel("ship"), fuel) and supply.get_revision() == revision

# --- Lauf -----------------------------------------------------------------------------------------------

func _run() -> void:
	_scenario_data_block()
	_scenario_rejections()
	_scenario_preview_and_quantity()
	_scenario_order_and_replay()
	_scenario_state_sequence()
	_scenario_delivery_once()
	_scenario_cancel()
	_scenario_expire()
	_scenario_ship_stays()
	_scenario_partial_delivery()
	_scenario_delivery_failure()
	_scenario_save_and_load()
	_scenario_data_driven()
	_scenario_texts()
	print("TANKER_EMERGENCY_RULES passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)

# --- A. Datenblock ---------------------------------------------------------------------------------------

func _scenario_data_block() -> void:
	var block: Dictionary = Dictionary(_data().get("emergency_fuel", {}))
	_check(not block.is_empty(), "A: trade_offers.json hat den Block emergency_fuel")
	_check(int(block.get("callout_fee", -1)) == 100 and int(block.get("price_per_unit", -1)) == 6 and int(block.get("quantity", -1)) == 30 and int(block.get("min_quantity", -1)) == 10, "A: Anfahrtsgebuehr 100, Mengenpreis 6, Menge 30, Mindestmenge 10")
	_check(is_equal_approx(float(block.get("dispatch_seconds", -1)), 5.0) and is_equal_approx(float(block.get("response_seconds", -1)), 60.0) and is_equal_approx(float(block.get("refuel_seconds", -1)), 10.0) and String(block.get("status", "")) == "vorlaeufig", "A: 5 s Abruf, 60 s Anfahrt, 10 s Betankung, Status vorlaeufig")
	_check(is_equal_approx(float(block.get("delivery_retry_seconds", -1)), 30.0), "A: delivery_retry_seconds 30 (Frist fuer eine nicht buchbare Lieferung)")
	var supply: RefCounted = _supply()
	_check(Dictionary(supply.get_supply_snapshot().get("emergency_fuel", {})) == block, "A: der Versorgungsstand zeigt den Block unveraendert")
	var bad_blocks: Array = [
		{"callout_fee": -1}, {"callout_fee": 1.5}, {"price_per_unit": 0}, {"quantity": 0}, {"min_quantity": 31}, {"min_quantity": 0},
		{"delivery_retry_seconds": -1}, {"delivery_retry_seconds": "x"}, {"dispatch_seconds": -1}, {"response_seconds": "x"}, {"refuel_seconds": -0.5}, {"status": 3},
	]
	var rejected := 0
	for patch: Dictionary in bad_blocks:
		var data: Dictionary = _data()
		data.emergency_fuel.merge(patch, true)
		if not bool(SUPPLY.new().configure([{"craft_id": "ship"}], data).get("ok", true)): rejected += 1
	_check(rejected == bad_blocks.size(), "A: configure lehnt jeden ungueltigen Wert des Blocks ab (%d von %d)" % [rejected, bad_blocks.size()])
	var without: Dictionary = _data()
	without.erase("emergency_fuel")
	var plain: RefCounted = SUPPLY.new()
	_check(plain.configure([{"craft_id": "ship"}], without).get("ok", false), "A: ohne den Block konfiguriert der Besitzer weiter (alte Daten)")
	var no_service: Dictionary = plain.preview_emergency_tanker({"craft_id": "ship"}, _ctx())
	_check(not no_service.get("ok", true) and String(no_service.get("reason", "")) == "emergency_fuel_unavailable", "A: ohne den Block gibt es keinen Dienst (emergency_fuel_unavailable)")

# --- B. Ablehnungen: nichts gebucht ------------------------------------------------------------------------

func _scenario_rejections() -> void:
	var supply: RefCounted = _supply()
	var credits: int = supply.get_credits()
	var revision: int = supply.get_revision()
	var cases: Array = [
		["craft_unavailable", "ship_unknown", _ctx()],
		["craft_unavailable", "ship", _ctx({"craft_available": false})],
		["at_service_point", "ship", _ctx({"at_service_point": true})],
		["no_fuel_problem", "ship", _ctx({"fuel_problem": false})],
	]
	for entry: Array in cases:
		var result: Dictionary = supply.apply_command(_cmd("emergency_tanker_order", {"craft_id": String(entry[1])}, "b:" + String(entry[0]) + ":" + String(entry[1])), entry[2])
		_check(not result.get("ok", true) and String(result.get("reason", "")) == String(entry[0]), "B: %s (%s) wird abgelehnt: %s" % [entry[0], entry[1], str(result.get("reason", ""))])
		_check(String(result.get("message", "")) == SERVICE.message_for(String(entry[0])), "B: %s traegt den deutschen Satz: %s" % [entry[0], str(result.get("message", ""))])
		_check(_unchanged(supply, credits, 5.0, revision) and supply.get_open_tanker_orders().is_empty(), "B: %s: Guthaben, Tank und Revision unveraendert, kein Auftrag" % entry[0])
	var untrusted: Dictionary = supply.apply_command(_cmd("emergency_tanker_order", {"craft_id": "ship"}, "b:untrusted"), {})
	_check(not untrusted.get("ok", true) and String(untrusted.get("reason", "")) == "tanker_not_authorized" and _unchanged(supply, credits, 5.0, revision), "B: ohne vertrauten Kontext (UI-Anfrage) wird nichts gebucht (tanker_not_authorized)")
	var nearly: RefCounted = _supply(95.0)
	var nearly_credits: int = nearly.get_credits()
	var nearly_revision: int = nearly.get_revision()
	var near_result: Dictionary = nearly.apply_command(_cmd("emergency_tanker_order", {"craft_id": "ship"}, "b:full"), _ctx())
	_check(not near_result.get("ok", true) and String(near_result.get("reason", "")) == "tank_nearly_full" and int(near_result.get("quantity", -1)) == 5, "B: tank_nearly_full bei 95 von 100 (frei 5 < Mindestmenge 10): " + str(near_result))
	_check(_unchanged(nearly, nearly_credits, 95.0, nearly_revision) and String(near_result.get("message", "")) == SERVICE.message_for("tank_nearly_full"), "B: tank_nearly_full bucht nichts und traegt seinen Satz")
	var ten: RefCounted = _supply(90.0)
	_check(bool(ten.preview_emergency_tanker({"craft_id": "ship"}, _ctx()).get("ok", false)), "B: genau die Mindestmenge (frei 10) ist bestellbar")
	var poor: RefCounted = _supply()
	# Abschnitt K (22.11.2026): zu wenig Credits ist kein Grund mehr (der Dienst liefert auf Kredit, siehe campaign_debt_verifier); abgelehnt wird
	# erst, wenn die Credits danach unter -debt_limit (1500) laegen. Hier: -1221 - 280 = -1501.
	poor.charge_rescue_fee(poor.get_credits() + 1221)
	var poor_result: Dictionary = poor.apply_command(_cmd("emergency_tanker_order", {"craft_id": "ship"}, "b:poor"), _ctx())
	_check(not poor_result.get("ok", true) and String(poor_result.get("reason", "")) == "debt_limit_reached" and int(poor_result.get("price", -1)) == 280 and int(poor_result.get("credits", 0)) == -1221, "B: debt_limit_reached mit -1221 Cr (Preis 280) traegt price und credits: " + str(poor_result))
	_check(_unchanged(poor, -1221, 5.0, poor.get_revision()) and poor.get_open_tanker_orders().is_empty(), "B: debt_limit_reached bucht nichts, keine Teilmenge, kein Auftrag")
	_check(String(poor_result.get("message", "")) == SERVICE.message_for("debt_limit_reached") and String(poor_result.get("message", "")).begins_with("Kreditrahmen"), "B: der Satz nennt den Kreditrahmen: " + String(poor_result.get("message", "")))
	var on_credit: RefCounted = _supply()
	on_credit.charge_credits_capped(on_credit.get_credits() - 279)
	_check(bool(on_credit.apply_command(_cmd("emergency_tanker_order", {"craft_id": "ship"}, "b:credit"), _ctx()).get("ok", false)) and on_credit.get_credits() == -1, "B: mit 279 Cr (Preis 280) geht die Bestellung jetzt auf Kredit durch: Guthaben -1")
	var exact: RefCounted = _supply()
	exact.charge_credits_capped(exact.get_credits() - 280)
	_check(bool(exact.apply_command(_cmd("emergency_tanker_order", {"craft_id": "ship"}, "b:exact"), _ctx()).get("ok", false)) and exact.get_credits() == 0, "B: mit genau 280 Cr geht die Bestellung durch (Guthaben danach 0)")

# --- C./D. Angebot, Menge, Preis -----------------------------------------------------------------------------

func _scenario_preview_and_quantity() -> void:
	var supply: RefCounted = _supply()
	var credits: int = supply.get_credits()
	var revision: int = supply.get_revision()
	var offer: Dictionary = supply.preview_emergency_tanker({"craft_id": "ship"}, _ctx())
	_check(bool(offer.get("ok", false)) and int(offer.get("quantity", 0)) == 30 and int(offer.get("price", 0)) == 280 and int(offer.get("callout_fee", 0)) == 100, "C: das Angebot nennt 30 Einheiten fuer 280 Cr (100 + 6 x 30)")
	_check(is_equal_approx(float(offer.get("wait_seconds", 0.0)), 65.0) and is_equal_approx(float(offer.get("refuel_seconds", 0.0)), 10.0) and is_equal_approx(float(offer.get("total_seconds", 0.0)), 75.0), "C: das Angebot nennt die Wartezeit (5 + 60 = 65 s, dazu 10 s Betankung)")
	_check(_unchanged(supply, credits, 5.0, revision) and supply.get_open_tanker_orders().is_empty(), "C: das Angebot bucht nichts und aendert die Revision nicht")
	var partial: RefCounted = _supply(85.0)
	var partial_offer: Dictionary = partial.preview_emergency_tanker({"craft_id": "ship"}, _ctx())
	_check(int(partial_offer.get("quantity", 0)) == 15 and int(partial_offer.get("price", 0)) == 190, "D: Tank 85 von 100 -> 15 Einheiten, Preis 100 + 90 = 190: " + str(partial_offer))
	var booked: Dictionary = partial.apply_command(_cmd("emergency_tanker_order", {"craft_id": "ship"}, "d:partial"), _ctx())
	_check(bool(booked.get("ok", false)) and partial.get_credits() == 500 - 190 and int(booked.get("quantity", 0)) == 15, "D: die Bestellung bucht genau 190 und merkt sich 15 Einheiten")
	var fractional: RefCounted = _supply(85.5)
	_check(int(fractional.preview_emergency_tanker({"craft_id": "ship"}, _ctx()).get("quantity", 0)) == 14, "D: bei 85,5 Treibstoff werden nur ganze Einheiten geliefert (14)")

func _scenario_order_and_replay() -> void:
	var driver: Driver = _driver()
	var supply: RefCounted = driver.supply
	var first: Dictionary = driver.order("ship", "t2:order:1", _ctx())
	_check(bool(first.get("ok", false)) and not bool(first.get("replayed", false)) and String(first.get("order_id", "")) == "t2:order:1", "D: die Bestellung ist angenommen, die Auftragskennung ist die Anfrage-ID")
	_check(supply.get_credits() == 220 and is_equal_approx(supply.get_fuel("ship"), 5.0), "D: gebucht sind genau 280 (500 -> 220), der Tank ist noch unveraendert")
	_check(supply.has_request("t2:order:1") and supply.get_open_tanker_orders().size() == 1 and driver.service.get_order("ship").get("state") == "requested", "D: ein Beleg, ein offener Auftrag im Zustand requested")
	var again: Dictionary = driver.order("ship", "t2:order:1", _ctx())
	_check(bool(again.get("replayed", false)) and bool(again.get("ok", false)), "D: dieselbe Anfrage-ID noch einmal liefert replayed: true")
	_check(supply.get_credits() == 220 and supply.get_open_tanker_orders().size() == 1 and driver.service.open_orders().size() == 1, "D: die Wiederholung bucht nicht noch einmal und legt keinen zweiten Auftrag an")
	var conflict: Dictionary = driver.order("ship2", "t2:order:1", _ctx())
	_check(not conflict.get("ok", true) and String(conflict.get("reason", "")) == "request_id_conflict" and supply.get_credits() == 220, "D: dieselbe Anfrage-ID mit anderem Schiff ist ein Konflikt und bucht nichts")
	var second: Dictionary = driver.order("ship", "t2:order:2", _ctx())
	_check(not second.get("ok", true) and String(second.get("reason", "")) == "tanker_order_open" and String(second.get("order_id", "")) == "t2:order:1", "D: eine zweite Bestellung fuer dasselbe Schiff -> tanker_order_open")
	_check(supply.get_credits() == 220 and supply.get_open_tanker_orders().size() == 1 and not supply.has_request("t2:order:2"), "D: die abgelehnte zweite Bestellung bucht nichts und hinterlaesst keinen Beleg")
	var rich: Driver = _driver(5.0, func(data: Dictionary) -> void: data["initial_credits"] = 2000)
	rich.order("ship", "t2:order:r1", _ctx())
	var other: Dictionary = rich.order("ship2", "t2:order:r2", _ctx())
	_check(bool(other.get("ok", false)) and rich.supply.get_credits() == 2000 - 560 and rich.supply.get_open_tanker_orders().size() == 2, "D: ein anderes Schiff darf eigene Hilfe bestellen (zwei offene Auftraege, 560 gebucht)")

# --- E. Zustaende und Zeit -------------------------------------------------------------------------------------

func _scenario_state_sequence() -> void:
	var driver: Driver = _driver()
	var supply: RefCounted = driver.supply
	driver.order("ship", "t2:seq", _ctx())
	var order: Dictionary = driver.service.get_order("ship")
	_check(order.state == "requested" and is_equal_approx(float(order.remaining), 5.0), "E: nach der Bestellung: requested, Restzeit 5 s (dispatch_seconds)")
	var revision: int = supply.get_revision()
	driver.tick(4.9)
	_check(driver.service.get_order("ship").state == "requested", "E: nach 4,9 s noch requested")
	driver.tick(0.1)
	var en_route: Dictionary = driver.service.get_order("ship")
	_check(en_route.state == "en_route" and is_equal_approx(float(en_route.remaining), 60.0), "E: nach 5 s: en_route mit 60 s (response_seconds)")
	driver.tick(59.9)
	_check(driver.service.get_order("ship").state == "en_route", "E: nach 59,9 s noch en_route")
	driver.tick(0.1)
	_check(driver.service.get_order("ship").state == "at_ship", "E: nach 60 s: at_ship")
	_check(is_equal_approx(supply.get_fuel("ship"), 5.0), "E: am Schiff ist noch nichts geliefert")
	driver.tick(0.0)
	var refuelling: Dictionary = driver.service.get_order("ship")
	_check(refuelling.state == "refuelling" and is_equal_approx(float(refuelling.remaining), 10.0), "E: der naechste Tick: refuelling mit 10 s (refuel_seconds)")
	driver.tick(9.9)
	_check(driver.service.get_order("ship").state == "refuelling" and is_equal_approx(supply.get_fuel("ship"), 5.0), "E: nach 9,9 s Betankung noch nichts gutgeschrieben")
	_check(supply.get_revision() == revision, "E: der Zeitablauf allein aendert die Revision des Versorgungsstands nicht")
	driver.tick(0.1)
	_check(driver.service.get_order("ship").is_empty() and String(driver.service.get_finished("ship").get("state", "")) == "completed", "E: nach 10 s: completed, der Auftrag ist geschlossen")
	_check(is_equal_approx(supply.get_fuel("ship"), 35.0) and supply.get_credits() == 220, "E: Tank +30 (5 -> 35), Guthaben -280 (500 -> 220)")
	_check(supply.get_revision() == revision + 1, "E: erst die Lieferung hebt die Revision (genau um 1)")
	_check(driver.states == ["requested", "en_route", "at_ship", "refuelling"] or driver.states == ["en_route", "at_ship", "refuelling"], "E: die Zustaende kamen in der festen Reihenfolge: " + str(driver.states))
	var snapshot: Dictionary = driver.service.get_snapshot()
	_check(snapshot.orders.is_empty() and String(Dictionary(snapshot.finished.get("ship", {})).get("state_label", "")) == "Betankt, abgeschlossen", "E: die Anzeige-Auskunft kennt den beendeten Auftrag mit deutschem Zustandstext")

# --- F. Lieferung genau einmal -----------------------------------------------------------------------------------

func _scenario_delivery_once() -> void:
	var driver: Driver = _driver()
	var supply: RefCounted = driver.supply
	driver.order("ship", "t2:once", _ctx())
	driver.tick(1000.0)
	driver.tick(1000.0)
	driver.tick(1000.0)
	_check(is_equal_approx(supply.get_fuel("ship"), 35.0) and supply.get_credits() == 220, "F: drei Ticks weit ueber das Ende liefern genau +30 (Tank 35)")
	for index in range(5): driver.tick(1000.0)
	_check(is_equal_approx(supply.get_fuel("ship"), 35.0) and driver.service.open_orders().is_empty(), "F: weitere Ticks aendern nichts mehr")
	var replay: Dictionary = supply.apply_command(_cmd("emergency_tanker_deliver", {"order_id": "t2:once"}, "t2:once:deliver"), {"emergency_tanker_authorized": true})
	_check(bool(replay.get("replayed", false)) and is_equal_approx(supply.get_fuel("ship"), 35.0), "F: derselbe Lieferbefehl noch einmal liefert replayed und schreibt nichts gut")
	var other_id: Dictionary = supply.apply_command(_cmd("emergency_tanker_deliver", {"order_id": "t2:once"}, "t2:once:deliver:again"), {"emergency_tanker_authorized": true})
	_check(not other_id.get("ok", true) and String(other_id.get("reason", "")) == "invalid_request_id" and is_equal_approx(supply.get_fuel("ship"), 35.0), "F: ein Lieferbefehl mit anderer Anfrage-ID wird abgelehnt (invalid_request_id)")
	var untrusted: Dictionary = supply.apply_command(_cmd("emergency_tanker_deliver", {"order_id": "t2:once"}, "t2:once:deliver"), {})
	_check(bool(untrusted.get("replayed", false)) and is_equal_approx(supply.get_fuel("ship"), 35.0), "F: auch ohne Kontext gibt es keine zweite Gutschrift")
	var unknown: Dictionary = supply.apply_command(_cmd("emergency_tanker_deliver", {"order_id": "t2:none"}, "t2:none:deliver"), {"emergency_tanker_authorized": true})
	_check(not unknown.get("ok", true) and String(unknown.get("reason", "")) == "unknown_order", "F: ein unbekannter Auftrag wird nicht beliefert (unknown_order)")
	var fresh: Driver = _driver(70.0)
	fresh.order("ship", "t2:full", _ctx())
	var refueled: Dictionary = fresh.supply.apply_command(_cmd("refuel", {"craft_id": "ship", "amount": 25.0}, "t2:full:refuel"), {"location_id": "homebase", "craft_busy": false})
	var topped: float = fresh.supply.get_fuel("ship")
	fresh.tick(1000.0)
	fresh.tick(1000.0)
	fresh.tick(1000.0)
	_check(bool(refueled.get("ok", false)) and is_equal_approx(topped, 95.0) and is_equal_approx(fresh.supply.get_fuel("ship"), 100.0), "F: die Lieferung wird von der Tankkapazitaet begrenzt (95 + 30 -> 100, nie darueber): " + str(refueled.get("reason", "")))

# --- G. Stornieren ------------------------------------------------------------------------------------------------

func _scenario_cancel() -> void:
	var early: Driver = _driver()
	early.order("ship", "t2:c1", _ctx())
	early.tick(2.0)
	var refund_early: Dictionary = early.cancel("ship")
	_check(bool(refund_early.get("ok", false)) and int(refund_early.get("refund", -1)) == 280 and early.supply.get_credits() == 500, "G: Storno in requested erstattet alles (280), Guthaben wieder 500")
	_check(is_equal_approx(early.supply.get_fuel("ship"), 5.0) and early.supply.get_open_tanker_orders().is_empty() and early.service.open_orders().is_empty(), "G: nach dem Storno ist der Auftrag zu, der Tank unveraendert")
	early.tick(1000.0)
	_check(is_equal_approx(early.supply.get_fuel("ship"), 5.0) and early.supply.get_credits() == 500, "G: nach dem Storno liefert kein Tick mehr")
	var twice: Dictionary = early.supply.apply_command(_cmd("emergency_tanker_cancel", {"order_id": "t2:c1", "reason": "player"}, "t2:c1:cancel"), {"emergency_tanker_authorized": true, "emergency_tanker_state": "requested"})
	_check(bool(twice.get("replayed", false)) and early.supply.get_credits() == 500, "G: derselbe Stornobefehl noch einmal erstattet nicht noch einmal (replayed)")
	var late_deliver: Dictionary = early.supply.apply_command(_cmd("emergency_tanker_deliver", {"order_id": "t2:c1"}, "t2:c1:deliver"), {"emergency_tanker_authorized": true})
	_check(not late_deliver.get("ok", true) and String(late_deliver.get("reason", "")) == "order_closed" and is_equal_approx(early.supply.get_fuel("ship"), 5.0), "G: ein stornierter Auftrag wird nicht mehr beliefert (order_closed)")
	var again: Dictionary = early.order("ship", "t2:c1b", _ctx())
	_check(bool(again.get("ok", false)) and early.supply.get_credits() == 220, "G: nach dem Storno ist eine neue Bestellung wieder moeglich")
	var mid: Driver = _driver()
	mid.order("ship", "t2:c2", _ctx())
	mid.tick(5.0)
	_check(mid.service.get_order("ship").state == "en_route", "G: Vorbereitung: der Auftrag ist unterwegs")
	var refund_mid: Dictionary = mid.cancel("ship")
	_check(bool(refund_mid.get("ok", false)) and int(refund_mid.get("refund", -1)) == 180 and int(refund_mid.get("kept", -1)) == 100, "G: Storno in en_route erstattet den Mengenpreis (180), die Anfahrtsgebuehr (100) ist verloren")
	_check(mid.supply.get_credits() == 500 - 100 and is_equal_approx(mid.supply.get_fuel("ship"), 5.0), "G: Guthaben 400, Tank unveraendert")
	var arrived: Driver = _driver()
	arrived.order("ship", "t2:c3", _ctx())
	arrived.tick(5.0)
	arrived.tick(60.0)
	_check(arrived.service.get_order("ship").state == "at_ship", "G: Vorbereitung: der Tanker ist am Schiff")
	var credits: int = arrived.supply.get_credits()
	var revision: int = arrived.supply.get_revision()
	var denied: Dictionary = arrived.supply.apply_command(_cmd("emergency_tanker_cancel", {"order_id": "t2:c3", "reason": "player"}, "t2:c3:cancel"), {"emergency_tanker_authorized": true, "emergency_tanker_state": "at_ship"})
	_check(not denied.get("ok", true) and String(denied.get("reason", "")) == "tanker_already_arrived" and _unchanged(arrived.supply, credits, 5.0, revision), "G: ab at_ship ist kein Storno mehr moeglich (tanker_already_arrived), nichts gebucht")
	arrived.tick(0.0)
	var denied_refuel: Dictionary = arrived.supply.apply_command(_cmd("emergency_tanker_cancel", {"order_id": "t2:c3", "reason": "player"}, "t2:c3:cancel"), {"emergency_tanker_authorized": true, "emergency_tanker_state": "refuelling"})
	_check(not denied_refuel.get("ok", true) and String(denied_refuel.get("reason", "")) == "tanker_already_arrived" and arrived.supply.get_open_tanker_orders().size() == 1, "G: auch waehrend der Betankung (refuelling) geht kein Storno")
	var after_delivery: Driver = _driver()
	after_delivery.order("ship", "t2:c4", _ctx())
	after_delivery.tick(1000.0)
	after_delivery.tick(1000.0)
	after_delivery.tick(1000.0)
	var late_cancel: Dictionary = after_delivery.supply.apply_command(_cmd("emergency_tanker_cancel", {"order_id": "t2:c4", "reason": "player"}, "t2:c4:cancel"), {"emergency_tanker_authorized": true, "emergency_tanker_state": "requested"})
	_check(not late_cancel.get("ok", true) and String(late_cancel.get("reason", "")) == "order_closed" and after_delivery.supply.get_credits() == 220, "G: ein belieferter Auftrag laesst sich nicht mehr erstatten (order_closed)")
	var forged: Dictionary = after_delivery.supply.apply_command(_cmd("emergency_tanker_cancel", {"order_id": "t2:c4", "reason": "player"}, "t2:c4:cancel"), {})
	_check(not forged.get("ok", true) and after_delivery.supply.get_credits() == 220, "G: ein Storno ohne vertrauten Kontext erstattet nichts")

# --- H. Verfall bei Zerstoerung ---------------------------------------------------------------------------------

func _scenario_expire() -> void:
	for state_case: Array in [["requested", 0.0], ["en_route", 5.0], ["refuelling", 65.0]]:
		var driver: Driver = _driver()
		driver.order("ship", "t2:x:" + String(state_case[0]), _ctx())
		driver.tick(float(state_case[1]))
		if state_case[0] == "refuelling": driver.tick(0.0)
		_check(String(driver.service.get_order("ship").get("state", "")) == String(state_case[0]), "H: Vorbereitung: Zustand " + String(state_case[0]))
		var result: Dictionary = driver.expire("ship")
		_check(bool(result.get("ok", false)) and int(result.get("refund", -1)) == 280 and driver.supply.get_credits() == 500, "H: Verfall in %s erstattet alles (280), Guthaben 500" % state_case[0])
		_check(String(driver.service.get_finished("ship").get("state", "")) == "expired" and driver.service.open_orders().is_empty() and driver.supply.get_open_tanker_orders().is_empty(), "H: der Auftrag steht danach als expired, nichts bleibt offen")
		driver.tick(1000.0)
		driver.tick(1000.0)
		_check(is_equal_approx(driver.supply.get_fuel("ship"), 5.0) and driver.supply.get_credits() == 500, "H: ein verfallener Auftrag liefert nicht mehr und erstattet nicht zweimal")
		var late: Dictionary = driver.supply.apply_command(_cmd("emergency_tanker_deliver", {"order_id": "t2:x:" + String(state_case[0])}, "t2:x:" + String(state_case[0]) + ":deliver"), {"emergency_tanker_authorized": true})
		_check(not late.get("ok", true) and String(late.get("reason", "")) == "order_closed", "H: eine Lieferung an ein verfallenes Auftrag wird abgelehnt (%s)" % state_case[0])
	var replay_driver: Driver = _driver()
	replay_driver.order("ship", "t2:x:r", _ctx())
	replay_driver.expire("ship")
	var replay: Dictionary = replay_driver.supply.apply_command(_cmd("emergency_tanker_cancel", {"order_id": "t2:x:r", "reason": "expired"}, "t2:x:r:cancel"), {"emergency_tanker_authorized": true})
	_check(bool(replay.get("replayed", false)) and replay_driver.supply.get_credits() == 500, "H: auch der Verfall erstattet genau einmal (replayed)")

# --- I. Das Schiff bleibt stehen ---------------------------------------------------------------------------------

func _scenario_ship_stays() -> void:
	var driver: Driver = _driver()
	var supply: RefCounted = driver.supply
	var context := {"departure_authorized": true}
	var free_before: Dictionary = supply.apply_command(_leg("ship", "landing", "", "homebase", "i:free:before"), context)
	_check(bool(free_before.get("ok", false)), "I: ohne Auftrag laeuft die kostenlose Heimlandung")
	driver.order("ship", "t2:stay", _ctx())
	var fuel: float = supply.get_fuel("ship")
	var credits: int = supply.get_credits()
	var revision: int = supply.get_revision()
	var jump: Dictionary = supply.apply_command(_leg("ship", "jump", "homebase", "trade_outpost", "i:jump"), context)
	_check(not jump.get("ok", true) and String(jump.get("reason", "")) == "tanker_order_open", "I: mit offenem Auftrag startet keine Sprungetappe (tanker_order_open): " + str(jump.get("reason", "")))
	var landing: Dictionary = supply.apply_command(_leg("ship", "landing", "", "homebase", "i:landing"), context)
	_check(not landing.get("ok", true) and String(landing.get("reason", "")) == "tanker_order_open", "I: auch keine kostenlose Etappe (Heimlandung) startet")
	var exit_leg: Dictionary = supply.preview_leg_fuel({"craft_id": "ship", "leg": "surface_exit", "origin_location_id": "satellite_crash", "destination_location_id": "homebase"}, context)
	_check(not exit_leg.get("ok", true) and String(exit_leg.get("reason", "")) == "tanker_order_open" and String(exit_leg.get("message", "")) == SERVICE.message_for("tanker_order_open"), "I: die Vorpruefung (dasselbe Tor wie leg_fuel_insufficient) meldet tanker_order_open mit deutschem Satz")
	var route: Dictionary = supply.preview_route_fuel({"craft_id": "ship", "origin_location_id": "homebase", "destination_location_id": "trade_outpost"}, context)
	_check(not route.get("ok", true) and String(route.get("reason", "")) == "tanker_order_open", "I: auch die alte Gesamtstrecke bleibt gesperrt")
	_check(is_equal_approx(supply.get_fuel("ship"), fuel) and supply.get_credits() == credits and supply.get_revision() == revision, "I: die abgelehnten Etappen buchen nichts")
	var other: Dictionary = supply.apply_command(_leg("ship2", "landing", "", "homebase", "i:other"), context)
	_check(bool(other.get("ok", false)), "I: ein anderes Schiff ist nicht betroffen")
	driver.tick(1000.0)
	driver.tick(1000.0)
	driver.tick(1000.0)
	var jump_after: Dictionary = supply.apply_command(_leg("ship", "jump", "homebase", "trade_outpost", "i:jump:after"), context)
	_check(bool(jump_after.get("ok", false)) and is_equal_approx(supply.get_fuel("ship"), 35.0 - 6.0), "I: nach der Lieferung startet die Etappe (35 - 6 = 29)")

# --- I2. Tank wird zwischen Bestellung und Lieferung voller (Fix-Runde 1, W-T2-2) -----------------------------------
## Herstellung: der echte Tankbefehl "refuel" am Besitzer mit Dienstkontext. Im Spiel ist das erreichbar, weil der Adapter die Dienste
## des Orts live liest (_service_context); wird ein Dienst waehrend der 65-75 s erreichbar, steht refuel zur Verfuegung (kein Sperrgrund).

func _refuel(driver: Driver, amount: float, request_id: String) -> Dictionary:
	return driver.supply.apply_command(_cmd("refuel", {"craft_id": "ship", "amount": amount}, request_id), {"location_id": "homebase", "craft_busy": false})

func _scenario_partial_delivery() -> void:
	# Tank 70, Bestellung 30 Einheiten = 100 + 6 x 30 = 280 (Mengenpreis 180). Danach 25 Einheiten getankt (2 Cr je Einheit = 50 Cr): Tank 95.
	var driver: Driver = _driver(70.0)
	var supply: RefCounted = driver.supply
	_check(bool(driver.order("ship", "w2:partial", _ctx()).get("ok", false)) and supply.get_credits() == 220, "W2/a: Bestellung bei Tank 70 (30 Einheiten, 280 Cr, Guthaben 220)")
	_check(bool(_refuel(driver, 25.0, "w2:partial:refuel").get("ok", false)) and supply.get_credits() == 170 and is_equal_approx(supply.get_fuel("ship"), 95.0), "W2/a: normales Tanken bleibt bei offenem Auftrag moeglich (Tank 95, Guthaben 170)")
	var revision: int = supply.get_revision()
	driver.tick(1000.0)
	driver.tick(1000.0)
	var delivery: Dictionary = driver.last_delivery
	_check(bool(delivery.get("ok", false)) and int(delivery.get("amount", -1)) == 5 and int(delivery.get("ordered", -1)) == 30, "W2/a: geliefert werden nur 5 von 30 Einheiten: " + str(delivery))
	_check(int(delivery.get("refund", -1)) == 150 and int(delivery.get("callout_kept", -1)) == 100, "W2/a: Erstattung = 180 - ceil(5 x 6) = 150, die Anfahrt (100) bleibt beim Dienst: " + str(delivery))
	_check(is_equal_approx(supply.get_fuel("ship"), 100.0) and supply.get_credits() == 320, "W2/a: Tank 100, Guthaben 320 (500 - 50 Tanken - 100 Anfahrt - 30 fuer 5 Einheiten)")
	_check(supply.get_credits() == 500 - 50 - 100 - 5 * 6, "W2/a: die Summe geht auf den Credit auf")
	_check(supply.get_revision() == revision + 1 and driver.service.get_order("ship").is_empty() and String(driver.service.get_finished("ship").get("state", "")) == "completed", "W2/a: eine Buchung (Revision +1), Auftrag completed")
	# c) Wiederholung der Lieferung und weitere Ticks erstatten nicht noch einmal.
	var again: Dictionary = supply.apply_command(_cmd("emergency_tanker_deliver", {"order_id": "w2:partial"}, "w2:partial:deliver"), {"emergency_tanker_authorized": true})
	driver.tick(1000.0)
	driver.tick(1000.0)
	_check(bool(again.get("replayed", false)) and supply.get_credits() == 320 and is_equal_approx(supply.get_fuel("ship"), 100.0), "W2/c: derselbe Lieferbefehl und weitere Ticks erstatten nicht noch einmal (320, Tank 100)")
	# b) 0 Einheiten: Tank wird ganz voll, nur die Anfahrt bleibt bezahlt.
	var zero: Driver = _driver(70.0)
	zero.order("ship", "w2:zero", _ctx())
	_refuel(zero, 30.0, "w2:zero:refuel")
	zero.tick(1000.0)
	zero.tick(1000.0)
	_check(is_equal_approx(zero.supply.get_fuel("ship"), 100.0) and int(zero.last_delivery.get("amount", -1)) == 0 and int(zero.last_delivery.get("refund", -1)) == 180, "W2/b: bei vollem Tank werden 0 Einheiten geliefert, der ganze Mengenpreis (180) wird erstattet: " + str(zero.last_delivery))
	_check(zero.supply.get_credits() == 500 - 280 - 60 + 180 and 500 - zero.supply.get_credits() == 60 + 100, "W2/b: bezahlt bleiben nur Tanken (60) und Anfahrt (100)")
	_check(String(zero.service.get_finished("ship").get("state", "")) == "completed" and zero.supply.get_open_tanker_orders().is_empty(), "W2/b: der Auftrag ist abgeschlossen, das Schiff frei")
	# Teilerstattung bei Nachkommastellen im Satz: 2,5 Cr je Einheit, 13 bestellt, 5 geliefert -> 7 + ceil(13 x 2,5) = 40; Erstattung 33 - ceil(5 x 2,5) = 33 - 13 = 20.
	var odd: Driver = _driver(95.0, func(data: Dictionary) -> void: data.emergency_fuel = {"callout_fee": 7, "price_per_unit": 2.5, "quantity": 13, "min_quantity": 4, "dispatch_seconds": 1.0, "response_seconds": 2.0, "refuel_seconds": 3.0, "delivery_retry_seconds": 4.0, "status": "test"})
	odd.order("ship", "w2:odd", _ctx())
	odd.tick(1000.0)
	odd.tick(1000.0)
	_check(int(odd.last_delivery.get("amount", -1)) == 5 and int(odd.last_delivery.get("refund", -1)) == 0 and odd.supply.get_credits() == 500 - 20, "W2: bestellt bei Tank 95 sind nur 5 Einheiten frei (7 + ceil(12,5) = 20 Cr), voll geliefert, keine Erstattung")
	var odd2: Driver = _driver(80.0, func(data: Dictionary) -> void: data.emergency_fuel = {"callout_fee": 7, "price_per_unit": 2.5, "quantity": 13, "min_quantity": 4, "dispatch_seconds": 1.0, "response_seconds": 2.0, "refuel_seconds": 3.0, "delivery_retry_seconds": 4.0, "status": "test"})
	odd2.order("ship", "w2:odd2", _ctx())
	_refuel(odd2, 15.0, "w2:odd2:refuel")
	odd2.tick(1000.0)
	odd2.tick(1000.0)
	_check(int(odd2.last_delivery.get("amount", -1)) == 5 and int(odd2.last_delivery.get("refund", -1)) == 20, "W2: Satz 2,5: 13 bestellt, 5 geliefert -> Erstattung 33 - ceil(12,5) = 20: " + str(odd2.last_delivery))

# --- I3. Nicht buchbare Lieferung: Frist, dann expired (Fix-Runde 1, K-T2-2) ------------------------------------------

func _scenario_delivery_failure() -> void:
	var driver: Driver = _driver()
	var supply: RefCounted = driver.supply
	driver.authorized = false
	driver.order("ship", "k2:fail", _ctx())
	driver.tick(1000.0)
	driver.tick(1000.0)
	var revision: int = supply.get_revision()
	_check(String(driver.service.get_order("ship").get("state", "")) == "refuelling" and String(driver.last_delivery.get("reason", "")) == "tanker_not_authorized", "K2/d: die Lieferung scheitert (tanker_not_authorized), der Auftrag bleibt offen")
	driver.tick(10.0)
	driver.tick(10.0)
	driver.tick(9.9)
	_check(not driver.service.get_order("ship").is_empty() and supply.get_credits() == 220, "K2/d: nach 29,9 s Wiederholung ist der Auftrag noch offen, nichts erstattet")
	_check(supply.get_revision() == revision, "K2/d: das stille Wiederholen aendert die Revision nicht")
	driver.tick(0.1)
	var finished: Dictionary = driver.service.get_finished("ship")
	_check(driver.service.get_order("ship").is_empty() and String(finished.get("state", "")) == "expired", "K2/d: nach 30 s (delivery_retry_seconds) verfaellt der Auftrag: " + str(finished))
	_check(String(finished.get("reason", "")) == "tanker_not_authorized" and int(finished.get("refund", -1)) == 280, "K2/d: der Grund des Scheiterns steht im Ergebnis, volle Erstattung 280")
	_check(supply.get_credits() == 500 and is_equal_approx(supply.get_fuel("ship"), 5.0) and supply.get_open_tanker_orders().is_empty() and supply.get_revision() == revision + 1, "K2/d: Guthaben 500, kein offener Beleg, nur der Verfall hat die Revision gehoben")
	var landing: Dictionary = supply.apply_command(_leg("ship", "landing", "", "homebase", "k2:landing"), {"departure_authorized": true})
	_check(bool(landing.get("ok", false)), "K2/d: das Schiff startet wieder eine Etappe (Heimlandung): " + str(landing.get("reason", "")))
	driver.authorized = true
	driver.tick(1000.0)
	_check(supply.get_credits() == 500 and is_equal_approx(supply.get_fuel("ship"), 5.0), "K2/c: nach dem Verfall erstattet und liefert kein Tick mehr")
	var late: Dictionary = supply.apply_command(_cmd("emergency_tanker_deliver", {"order_id": "k2:fail"}, "k2:fail:deliver"), {"emergency_tanker_authorized": true})
	_check(not late.get("ok", true) and String(late.get("reason", "")) == "order_closed", "K2: eine spaete Lieferung an den verfallenen Auftrag wird abgelehnt (order_closed)")
	# e) Die Frist kommt aus den Daten.
	var short: Driver = _driver(5.0, func(data: Dictionary) -> void: data.emergency_fuel.delivery_retry_seconds = 2.0)
	short.authorized = false
	short.order("ship", "k2:short", _ctx())
	short.tick(1000.0)
	short.tick(1000.0)
	short.tick(1.9)
	_check(not short.service.get_order("ship").is_empty(), "K2/e: mit delivery_retry_seconds 2 ist der Auftrag nach 1,9 s noch offen")
	short.tick(0.1)
	_check(short.service.get_order("ship").is_empty() and String(short.service.get_finished("ship").get("state", "")) == "expired" and short.supply.get_credits() == 500, "K2/e: nach 2 s verfaellt er mit voller Erstattung (Frist aus den Daten)")
	var long_run: Driver = _driver(5.0, func(data: Dictionary) -> void: data.emergency_fuel.delivery_retry_seconds = 100.0)
	long_run.authorized = false
	long_run.order("ship", "k2:long", _ctx())
	long_run.tick(1000.0)
	long_run.tick(1000.0)
	long_run.tick(50.0)
	long_run.tick(49.0)
	_check(not long_run.service.get_order("ship").is_empty(), "K2/e: mit delivery_retry_seconds 100 ist er nach 99 s noch offen")
	long_run.authorized = true
	long_run.tick(1.0)
	_check(String(long_run.service.get_finished("ship").get("state", "")) == "completed" and is_equal_approx(long_run.supply.get_fuel("ship"), 35.0), "K2/e: gelingt die Buchung innerhalb der Frist, wird normal geliefert (Tank 35)")

# --- J. Speichern und Laden ----------------------------------------------------------------------------------------

func _scenario_save_and_load() -> void:
	var driver: Driver = _driver()
	driver.order("ship", "t2:save", _ctx())
	driver.tick(5.0)
	driver.tick(30.0)
	var supply_state: Dictionary = Dictionary(JSON.parse_string(JSON.stringify(driver.supply.export_state())))
	var service_state: Dictionary = Dictionary(JSON.parse_string(JSON.stringify(driver.service.export_state())))
	var restored: RefCounted = _supply()
	var loaded: Dictionary = restored.restore_state(supply_state)
	_check(loaded.get("ok", false), "J: der Versorgungsstand mit offenem Tankerauftrag laedt: " + str(loaded))
	_check(restored.get_credits() == 220 and restored.has_request("t2:save") and restored.get_open_tanker_orders().has("t2:save"), "J: Guthaben, Bestellbeleg und offener Auftrag sind nach dem Laden da")
	var ok_pair: Dictionary = SERVICE.validate_against_receipts(service_state, restored.get_open_tanker_orders())
	_check(ok_pair.get("ok", false), "J: Dienstzustand und Belege stimmen ueberein: " + str(ok_pair))
	var service: RefCounted = SERVICE.new()
	_check(service.restore_state(service_state).get("ok", false), "J: der Dienstzustand laedt")
	var order: Dictionary = service.get_order("ship")
	_check(order.state == "en_route" and is_equal_approx(float(order.remaining), 30.0), "J: der Auftrag steht nach dem Laden im Zustand en_route mit 30 s Restzeit")
	var resumed: Driver = Driver.new(restored, service)
	resumed.tick(29.9)
	_check(is_equal_approx(restored.get_fuel("ship"), 5.0) and service.get_order("ship").state == "en_route", "J: nach dem Laden laeuft die Restzeit weiter, noch keine Lieferung")
	resumed.tick(0.1)
	resumed.tick(0.0)
	resumed.tick(1000.0)
	resumed.tick(1000.0)
	_check(is_equal_approx(restored.get_fuel("ship"), 35.0) and restored.get_credits() == 220 and service.open_orders().is_empty(), "J: nach dem Laden wird genau einmal geliefert (Tank 35, Guthaben 220)")
	var json_roundtrip: Dictionary = Dictionary(JSON.parse_string(JSON.stringify(restored.export_state())))
	var third: RefCounted = _supply()
	_check(third.restore_state(json_roundtrip).get("ok", false) and third.get_open_tanker_orders().is_empty() and is_equal_approx(third.get_fuel("ship"), 35.0), "J: der Stand nach der Lieferung laedt, kein Auftrag ist mehr offen")
	# Abgleich: nie stillschweigend reparieren.
	var open_receipts: Dictionary = driver.supply.get_open_tanker_orders()
	var no_order: Dictionary = SERVICE.validate_against_receipts({}, open_receipts)
	_check(not no_order.get("ok", true) and String(no_order.get("reason", "")) == "tanker_receipt_without_order", "J: offener Beleg ohne Dienstauftrag -> abgelehnt (tanker_receipt_without_order)")
	var no_receipt: Dictionary = SERVICE.validate_against_receipts(service_state, {})
	_check(not no_receipt.get("ok", true) and String(no_receipt.get("reason", "")) == "tanker_order_without_receipt", "J: Dienstauftrag ohne Beleg -> abgelehnt (tanker_order_without_receipt)")
	var altered: Dictionary = service_state.duplicate(true)
	altered.orders[0]["quantity"] = 29
	_check(String(SERVICE.validate_against_receipts(altered, open_receipts).get("reason", "")) == "tanker_order_mismatch", "J: abweichende Menge -> abgelehnt (tanker_order_mismatch)")
	var other_craft: Dictionary = service_state.duplicate(true)
	other_craft.orders[0]["craft_id"] = "ship2"
	_check(String(SERVICE.validate_against_receipts(other_craft, open_receipts).get("reason", "")) == "tanker_order_mismatch", "J: anderes Schiff -> abgelehnt (tanker_order_mismatch)")
	var broken: Dictionary = service_state.duplicate(true)
	broken.orders[0]["state"] = "completed"
	_check(String(SERVICE.validate_against_receipts(broken, open_receipts).get("reason", "")) == "invalid_tanker_state", "J: ein Endzustand im gespeicherten Dienst -> abgelehnt (invalid_tanker_state)")
	var too_long: Dictionary = service_state.duplicate(true)
	too_long.orders[0]["remaining"] = 999.0
	_check(String(SERVICE.validate_against_receipts(too_long, open_receipts).get("reason", "")) == "invalid_tanker_state", "J: eine Restzeit ueber der Dauer des Zustands -> abgelehnt")
	var twin: Dictionary = service_state.duplicate(true)
	twin.orders.append(twin.orders[0].duplicate(true))
	_check(String(SERVICE.validate_against_receipts(twin, open_receipts).get("reason", "")) == "invalid_tanker_state", "J: zwei Auftraege fuer ein Schiff -> abgelehnt")
	_check(SERVICE.validate_against_receipts({}, {}).get("ok", false), "J: ein alter Stand ohne Schluessel und ohne offenen Beleg laedt als 'kein Auftrag'")
	var empty_service: RefCounted = SERVICE.new()
	_check(empty_service.get_snapshot().orders.is_empty() and empty_service.open_orders().is_empty() and not empty_service.has_open_orders(), "J: ein frischer Dienst hat keinen Auftrag")
	# Belege im Versorgungsstand werden beim Laden geprueft.
	var cancel_driver: Driver = _driver()
	cancel_driver.order("ship", "t2:forge", _ctx())
	cancel_driver.tick(5.0)
	cancel_driver.cancel("ship")
	var cancel_state: Dictionary = Dictionary(JSON.parse_string(JSON.stringify(cancel_driver.supply.export_state())))
	_check(_supply().restore_state(cancel_state).get("ok", false), "J: ein Stand mit erstattetem Auftrag laedt")
	var forged_refund: Dictionary = cancel_state.duplicate(true)
	forged_refund.requests["t2:forge:cancel"].result["refund"] = 200
	_check(String(_supply().restore_state(forged_refund).get("reason", "")) == "invalid_tanker_receipts", "J: ein gefaelschter Stornobeleg (Erstattung, die es nicht gibt) wird beim Laden abgelehnt")
	var delivered_driver: Driver = _driver()
	delivered_driver.order("ship", "t2:forge", _ctx())
	delivered_driver.tick(1000.0)
	delivered_driver.tick(1000.0)
	var delivered_state: Dictionary = Dictionary(JSON.parse_string(JSON.stringify(delivered_driver.supply.export_state())))
	_check(delivered_state.requests.has("t2:forge:deliver") and _supply().restore_state(delivered_state).get("ok", false), "J: ein Stand mit gelieferten Auftrag laedt")
	var both: Dictionary = delivered_state.duplicate(true)
	both.requests["t2:forge:cancel"] = cancel_state.requests["t2:forge:cancel"].duplicate(true)
	_check(String(_supply().restore_state(both).get("reason", "")) == "invalid_tanker_receipts", "J: Liefer- und Stornobeleg zum selben Auftrag -> abgelehnt")
	var orphan: Dictionary = cancel_state.duplicate(true)
	orphan.requests.erase("t2:forge")
	_check(String(_supply().restore_state(orphan).get("reason", "")) == "invalid_tanker_receipts", "J: ein Stornobeleg ohne Bestellbeleg -> abgelehnt")
	# Altstaende: ohne den Datenblock (vor T2 gespeichert) laedt weiter, mit abweichendem Block auch.
	var legacy: Dictionary = cancel_state.duplicate(true)
	legacy.definitions.erase("emergency_fuel")
	_check(_supply().restore_state(legacy).get("ok", false), "J: ein Versorgungsstand ohne emergency_fuel (vor T2 gespeichert) laedt weiter")
	var retuned: Dictionary = cancel_state.duplicate(true)
	retuned.definitions.emergency_fuel["price_per_unit"] = 9
	_check(_supply().restore_state(retuned).get("ok", false), "J: bei spaeter neu abgestimmten Zahlen laedt ein Stand mit dem alten Block weiter")
	var fixtures: Array = ["res://scripts/tests/fixtures/main_639a49d65_checkpoint.json", "res://docs/qa/review_completion_20261113/post_benit_source/checkpoint_v1.json", "res://docs/qa/review_completion_20261113/legacy_source_pair/checkpoint_v1.json"]
	for path: String in fixtures:
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not parsed is Dictionary or not Dictionary(parsed).has("supply"):
			_check(false, "J: Altstand lesbar: " + path)
			continue
		var old_target: RefCounted = SUPPLY.new()
		old_target.configure([{"craft_id": "ship"}], _data())
		var old_result: Dictionary = old_target.restore_state(Dictionary(Dictionary(parsed).supply))
		_check(old_result.get("ok", false), "J: echter Altstand laedt weiter: " + path + " -> " + str(old_result.get("reason", "")))

# --- K. Zahlen aus den Daten -----------------------------------------------------------------------------------------

func _scenario_data_driven() -> void:
	var edit := func(data: Dictionary) -> void:
		data.emergency_fuel = {"callout_fee": 7, "price_per_unit": 2.5, "quantity": 13, "min_quantity": 4, "dispatch_seconds": 1.0, "response_seconds": 2.0, "refuel_seconds": 3.0, "delivery_retry_seconds": 4.0, "status": "test"}
	var driver: Driver = _driver(5.0, edit)
	var offer: Dictionary = driver.supply.preview_emergency_tanker({"craft_id": "ship"}, _ctx())
	_check(int(offer.get("quantity", 0)) == 13 and int(offer.get("price", 0)) == 7 + 33 and int(offer.get("callout_fee", 0)) == 7, "K: mit geaenderten Daten: 13 Einheiten, Preis 7 + ceil(13 x 2,5) = 40")
	_check(is_equal_approx(float(offer.get("wait_seconds", 0.0)), 3.0) and is_equal_approx(float(offer.get("refuel_seconds", 0.0)), 3.0), "K: die Wartezeit folgt den Daten (1 + 2 = 3 s, Betankung 3 s)")
	driver.order("ship", "t2:data", _ctx())
	_check(driver.supply.get_credits() == 500 - 40, "K: gebucht werden die Zahlen der Daten (460)")
	driver.tick(1.0)
	_check(driver.service.get_order("ship").state == "en_route" and is_equal_approx(float(driver.service.get_order("ship").remaining), 2.0), "K: Abruf 1 s und Anfahrt 2 s folgen den Daten")
	driver.tick(2.0)
	driver.tick(0.0)
	driver.tick(3.0)
	_check(is_equal_approx(driver.supply.get_fuel("ship"), 18.0), "K: geliefert werden 13 Einheiten (5 -> 18)")
	var small: Driver = _driver(95.0, edit)
	_check(bool(small.supply.preview_emergency_tanker({"craft_id": "ship"}, _ctx()).get("ok", false)), "K: mit Mindestmenge 4 ist bei 95 von 100 (frei 5) bestellbar")
	var minimum := func(data: Dictionary) -> void:
		data.emergency_fuel.min_quantity = 30
	var strict: Driver = _driver(80.0, minimum)
	_check(String(strict.supply.preview_emergency_tanker({"craft_id": "ship"}, _ctx()).get("reason", "")) == "tank_nearly_full", "K: mit Mindestmenge 30 ist bei 80 von 100 (frei 20) tank_nearly_full")

# --- L. Texte ---------------------------------------------------------------------------------------------------------

func _scenario_texts() -> void:
	for reason: String in ["insufficient_credits", "tank_nearly_full", "at_service_point", "tanker_order_open", "craft_unavailable", "no_fuel_problem", "tanker_already_arrived"]:
		var text: String = SERVICE.message_for(reason, {"price": 280})
		_check(not text.is_empty() and text != SERVICE.message_for("unbekannt"), "L: %s hat einen eigenen deutschen Satz: %s" % [reason, text])
	_check(SERVICE.message_for("no_fuel_problem") == "Der Treibstoff reicht für die nächste Etappe." and SERVICE.message_for("tanker_already_arrived") == "Der Tanker ist schon am Schiff." and SERVICE.message_for("craft_unavailable") == "Schiff nicht erreichbar.", "L: die drei neuen Saetze lauten wie im Auftrag")
	_check(SERVICE.message_for("insufficient_credits", {"price": 280}) == "Zu wenig Credits für den Tankerruf (280 Cr nötig).", "L: der Geldmangel-Satz nennt den Preis")
