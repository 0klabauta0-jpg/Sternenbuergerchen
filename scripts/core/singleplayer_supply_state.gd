extends RefCounted
## Long-lived domain owner. SimulationRoot supplies trusted service/runtime context.

const COMMANDS: GDScript = preload("res://scripts/mission/singleplayer_supply_command_contract.gd")
const DATA_PATH := "res://data/singleplayer/trade_offers.json"

var _definitions: Dictionary = {}
var _credits: int = 0
var _item_quantities: Dictionary = {}
var _fuel_by_craft_id: Dictionary = {}
var _stock_by_offer_id: Dictionary = {}
var _requests: Dictionary = {}
var _reward_receipts: Dictionary = {}
var _revision: int = 0

func configure(crafts: Array = [], definitions: Dictionary = {}) -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)) if definitions.is_empty() else definitions
	if typeof(raw) != TYPE_DICTIONARY:
		return _reject("invalid_supply_data", "Versorgungsdaten fehlen")
	var data: Dictionary = Dictionary(raw).duplicate(true)
	if not _valid_nonnegative_number(data.get("initial_credits")) or not _valid_nonnegative_number(data.get("initial_fuel")) or not _valid_nonnegative_number(data.get("fuel_capacity")) or not _valid_nonnegative_number(data.get("fuel_price_per_unit")):
		return _reject("invalid_supply_data", "Ungueltige Versorgungswerte")
	if float(data.initial_fuel) > float(data.fuel_capacity) or float(data.fuel_capacity) <= 0.0 or float(data.fuel_price_per_unit) <= 0.0:
		return _reject("invalid_supply_data", "Fuelkapazitaet oder Preis ungueltig")
	for entry in Dictionary(data.get("offers", {})).values():
		if typeof(entry) != TYPE_DICTIONARY or String(entry.get("item_id", "")).is_empty() or not _valid_positive_integer(entry.get("unit_price")) or not _valid_nonnegative_integer(entry.get("stock")):
			return _reject("invalid_supply_data", "Kaufangebot ungueltig")
	for cost in Dictionary(data.get("route_fuel_costs", {})).values():
		if not _valid_nonnegative_number(cost):
			return _reject("invalid_supply_data", "Routenkosten ungueltig")
	_definitions = data
	_credits = int(data.initial_credits)
	_item_quantities.clear()
	_fuel_by_craft_id.clear()
	_stock_by_offer_id.clear()
	_requests.clear()
	_reward_receipts.clear()
	_revision = 0
	for offer_id in Dictionary(data.get("offers", {})):
		_stock_by_offer_id[String(offer_id)] = int(data.offers[offer_id].stock)
	for craft in crafts:
		register_craft(String(craft.get("craft_id", craft.get("id", ""))) if typeof(craft) == TYPE_DICTIONARY else String(craft))
	return {"ok": true}

func register_craft(craft_id: String, initial_fuel: float = -1.0) -> bool:
	if craft_id.strip_edges().is_empty() or _definitions.is_empty():
		return false
	if _fuel_by_craft_id.has(craft_id):
		return true
	var amount: float = float(_definitions.initial_fuel) if initial_fuel == -1.0 else initial_fuel
	if not is_finite(amount) or amount < 0.0 or amount > float(_definitions.fuel_capacity):
		return false
	_fuel_by_craft_id[craft_id] = amount
	return true

func get_supply_snapshot() -> Dictionary:
	return {"credits": _credits, "item_quantities": _item_quantities.duplicate(true), "fuel_by_craft_id": _fuel_by_craft_id.duplicate(true), "stock_by_offer_id": _stock_by_offer_id.duplicate(true), "offers": Dictionary(_definitions.get("offers", {})).duplicate(true), "fuel_capacity": float(_definitions.get("fuel_capacity", 0.0)), "fuel_price_per_unit": float(_definitions.get("fuel_price_per_unit", 0.0)), "route_fuel_costs": Dictionary(_definitions.get("route_fuel_costs", {})).duplicate(true), "reward_completion_ids": _reward_receipts.keys().duplicate(), "revision": _revision}

func apply_command(command: Dictionary, authority_context: Dictionary = {}) -> Dictionary:
	if not COMMANDS.validate_command(command) or _definitions.is_empty():
		return _reject("invalid_command", "Versorgungsauftrag ungueltig")
	var request_id: String = String(command.request_id).strip_edges()
	var signature: String = JSON.stringify({"operation": command.operation, "payload": command.payload}, "", true)
	if _requests.has(request_id):
		if String(_requests[request_id].signature) != signature:
			return _reject("request_id_conflict", "Anfrage-ID bereits anders verwendet")
		var replay: Dictionary = _requests[request_id].result.duplicate(true)
		replay["replayed"] = true
		return replay
	var payload: Dictionary = command.payload
	var result: Dictionary
	match String(command.operation):
		"buy": result = _buy(payload, authority_context)
		"refuel": result = _refuel(payload, authority_context)
		"consume_route_fuel": result = _consume_route(payload, authority_context)
		"apply_reward": result = _reward(payload, authority_context)
		_: result = _reject("unknown_operation", "Aktion unbekannt")
	if bool(result.get("ok", false)):
		result["request_id"] = request_id
		result["operation"] = String(command.operation)
		_requests[request_id] = {"signature": signature, "result": result.duplicate(true)}
	return result

func _buy(payload: Dictionary, context: Dictionary) -> Dictionary:
	var location_id: String = String(context.get("location_id", ""))
	var offer_id: String = String(payload.get("offer_id", ""))
	var offer: Dictionary = Dictionary(Dictionary(_definitions.get("offers", {})).get(offer_id, {}))
	if offer.is_empty():
		return _reject("unknown_offer", "Angebot unbekannt")
	if not _has_service(location_id, "trade") or not Array(offer.get("location_ids", [])).has(location_id):
		return _reject("trade_unavailable", "Handel nur am Handelsservice")
	if not _valid_positive_integer(payload.get("quantity")):
		return _reject("invalid_quantity", "Menge muss eine positive ganze Zahl sein")
	var quantity: int = int(payload.quantity)
	if quantity > int(_stock_by_offer_id.get(offer_id, 0)):
		return _reject("insufficient_stock", "Angebotsmenge reicht nicht")
	var price: int = int(offer.get("unit_price", 0))
	if price <= 0 or quantity > _credits / price:
		return _reject("insufficient_credits", "Credits reichen nicht")
	_credits -= quantity * price
	_stock_by_offer_id[offer_id] = int(_stock_by_offer_id[offer_id]) - quantity
	var item_id: String = String(offer.item_id)
	_item_quantities[item_id] = int(_item_quantities.get(item_id, 0)) + quantity
	_revision += 1
	return {"ok": true, "item_id": item_id, "quantity": quantity, "cost": quantity * price, "message": "Kauf bestaetigt"}

func _refuel(payload: Dictionary, context: Dictionary) -> Dictionary:
	var craft_id: String = String(payload.get("craft_id", ""))
	if not _fuel_by_craft_id.has(craft_id):
		return _reject("unknown_craft", "Schiff unbekannt")
	if not _has_service(String(context.get("location_id", "")), "refuel") or bool(context.get("craft_busy", true)):
		return _reject("refuel_unavailable", "Schiff muss am Tankservice verfuegbar sein")
	var raw: Variant = payload.get("amount")
	if not _valid_nonnegative_number(raw) or float(raw) <= 0.0:
		return _reject("invalid_amount", "Tankmenge muss endlich und positiv sein")
	var amount: float = float(raw)
	var fuel: float = float(_fuel_by_craft_id[craft_id])
	if amount > float(_definitions.fuel_capacity) - fuel + 0.00001:
		return _reject("fuel_capacity", "Tankkapazitaet reicht nicht")
	var cost: float = ceil(amount * float(_definitions.fuel_price_per_unit))
	if not is_finite(cost) or cost > float(_credits):
		return _reject("insufficient_credits", "Credits reichen nicht")
	_credits -= int(cost)
	_fuel_by_craft_id[craft_id] = minf(fuel + amount, float(_definitions.fuel_capacity))
	_revision += 1
	return {"ok": true, "craft_id": craft_id, "amount": amount, "cost": int(cost), "message": "Betankung bestaetigt"}

func _consume_route(payload: Dictionary, context: Dictionary) -> Dictionary:
	if not bool(context.get("departure_authorized", false)):
		return _reject("departure_not_authorized", "Abflug nicht bestaetigt")
	var craft_id: String = String(payload.get("craft_id", ""))
	if not _fuel_by_craft_id.has(craft_id):
		return _reject("unknown_craft", "Schiff unbekannt")
	var route: String = String(payload.get("origin_location_id", "")) + ">" + String(payload.get("destination_location_id", ""))
	var routes: Dictionary = _definitions.get("route_fuel_costs", {})
	if not routes.has(route):
		return _reject("unknown_route", "Ortsverbindung unbekannt")
	var cost: float = float(routes[route])
	var fuel: float = float(_fuel_by_craft_id[craft_id])
	if fuel + 0.00001 < cost:
		return _reject("insufficient_fuel", "Treibstoff reicht fuer diese Strecke nicht")
	_fuel_by_craft_id[craft_id] = maxf(fuel - cost, 0.0)
	_revision += 1
	return {"ok": true, "craft_id": craft_id, "fuel_cost": cost, "message": "Routentreibstoff gebucht"}

func _reward(payload: Dictionary, context: Dictionary) -> Dictionary:
	var receipt: Dictionary = Dictionary(context.get("completion_receipt", {}))
	var completion_id: String = String(payload.get("completion_id", ""))
	if completion_id.is_empty() or completion_id != String(receipt.get("completion_id", "")) or not bool(receipt.get("runtime_verified", false)) or String(receipt.get("job_id", "")).is_empty():
		return _reject("unverified_completion", "Kein bestaetigter Auftragsabschluss")
	if _reward_receipts.has(completion_id):
		return {"ok": true, "already_rewarded": true, "completion_id": completion_id}
	var reward: Dictionary = Dictionary(receipt.get("reward", {}))
	var amount: Variant = reward.get("credits", 0)
	if not _valid_nonnegative_integer(amount) or float(amount) > 1000000.0:
		return _reject("invalid_reward", "Belohnung ungueltig")
	_credits += int(amount)
	_reward_receipts[completion_id] = receipt.duplicate(true)
	_revision += 1
	return {"ok": true, "completion_id": completion_id, "credits_added": int(amount), "message": "Auftragsbelohnung gutgeschrieben"}

func _has_service(location_id: String, service: String) -> bool:
	return Array(Dictionary(_definitions.get("service_locations", {})).get(location_id, [])).has(service)

func _valid_nonnegative_number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) >= 0.0

func _valid_nonnegative_integer(value: Variant) -> bool:
	return _valid_nonnegative_number(value) and float(value) == floor(float(value)) and float(value) <= 2147483647.0

func _valid_positive_integer(value: Variant) -> bool:
	return _valid_nonnegative_integer(value) and int(value) > 0

func _reject(reason: String, message: String) -> Dictionary:
	return {"ok": false, "reason": reason, "message": message}
