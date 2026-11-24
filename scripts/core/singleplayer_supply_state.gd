extends RefCounted
## Long-lived domain owner. SimulationRoot supplies trusted service/runtime context.

const COMMANDS: GDScript = preload("res://scripts/mission/singleplayer_supply_command_contract.gd")
const STATION_CRAFT = preload("res://scripts/mission/polisa_station_craft_runtime.gd")
const SHIP_COMPONENTS = preload("res://scripts/mission/ship_equipment_catalog.gd")
const SPACE_COMPONENTS = preload("res://scripts/mission/space_component_catalog.gd")
const RESEARCH = preload("res://scripts/mission/campaign_research_catalog.gd")
const INVENTORY = preload("res://scripts/mission/inventory_transfer_contract.gd")
const AMMO_WEAPONS = preload("res://scripts/core/weapon_data.gd")
const MODULAR = preload("res://scripts/core/campaign_modular_plan.gd")
const EMERGENCY_TANKER = preload("res://scripts/core/emergency_tanker_service.gd")
var _inventory: Dictionary = {}
## Liefert zu einer Person die getragene Ruestung ("" = unbekannt). Gesetzt vom Besitzer der Ausruestung (SimulationRoot);
## nichts davon wird gespeichert: die Fachgroesse im Behaelter wird daraus nur abgeleitet.
var _armor_provider: Callable = Callable()
var _location_resources: Dictionary = {}
var _modular_capacity_baseline := -1
var _modular_plan_cache: Dictionary = {}
var _modular_plan_cache_revision := -1

const DATA_PATH := "res://data/singleplayer/trade_offers.json"
const MARKET_PATH := "res://data/singleplayer/commodity_market.json"
const MARKET_OFFER_PREFIX := "market:"
const CAMPAIGN_RECIPES:Dictionary={"light_armor":{"item":"armor_light","cost":20},"mining_tool":{"item":"mining_tool","cost":30},"assault_rifle":{"item":"rifle","cost":60}}

static func get_campaign_recipe(blueprint_id:String)->Dictionary:
	return Dictionary(CAMPAIGN_RECIPES[blueprint_id]).duplicate(true) if CAMPAIGN_RECIPES.has(blueprint_id) else RESEARCH.fabrication(blueprint_id)

var _definitions: Dictionary = {}
var _credits: int = 0
## Schulden (K): Restzeit bis zur naechsten Zinsbuchung in Sekunden; -1 = Uhr steht (Credits >= 0) bzw. volle Periode beim naechsten Minus.
var _debt_remaining: float = -1.0
var _item_quantities: Dictionary = {}
var _fuel_by_craft_id: Dictionary = {}
var _stock_by_offer_id: Dictionary = {}
## Handel H2: Benit-Warenboerse (data/singleplayer/commodity_market.json). _market: Ort -> Ware -> {sell_price, stock, buy_price};
## _market_stock: "Ort:Ware" -> aktueller Bestand der Verkaufswaren. Eigener Block, nicht Teil von _definitions und _stock_by_offer_id
## (alte Staende ohne ihn laden mit vollem Bestand).
var _market: Dictionary = {}
var _market_stock: Dictionary = {}
var _requests: Dictionary = {}
var _reward_receipts: Dictionary = {}
var _research_receipts: Dictionary = {}
var _research_snapshot_cache: Dictionary = {}
var _research_snapshot_revision := -1
var _station_purchase_cache_revision := -1
var _station_purchase_cache: Dictionary = {}
var _open_tanker_cache_revision := -1
var _open_tanker_cache: Dictionary = {}
var _revision: int = 0
# Opt-in in-process capability for the UNWIRED prepared departure seam.
var _route_prepare_authority: WeakRef
var _route_prepare_bound := false
var _route_prepare_epoch := 0
var _route_prepare_seal_key := ""

func configure(crafts: Array = [], definitions: Dictionary = {}) -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)) if definitions.is_empty() else definitions
	if typeof(raw) != TYPE_DICTIONARY:
		return _reject("invalid_supply_data", "Versorgungsdaten fehlen")
	var data: Dictionary = Dictionary(raw).duplicate(true)
	# Handel H2: die Warenboerse kommt aus ihrer Datei; eine Testkopie darf sie unter "commodity_market" mitgeben (gehoert nicht in _definitions).
	var market_raw: Variant = data.get("commodity_market", null)
	data.erase("commodity_market")
	if market_raw == null: market_raw = JSON.parse_string(FileAccess.get_file_as_string(MARKET_PATH)) if FileAccess.file_exists(MARKET_PATH) else {"locations": {}}
	var parsed_market: Dictionary = _parse_market(market_raw)
	if not parsed_market.get("ok", false): return _reject("invalid_supply_data", String(parsed_market.get("message", "Warenboerse ungueltig")))
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
	# Etappenkosten: wenn vorhanden, muss jede Strecke aufgehen (Summe der Etappen == Routenwert).
	if data.has("leg_fuel_costs"):
		if typeof(data.leg_fuel_costs) != TYPE_DICTIONARY: return _reject("invalid_supply_data", "Etappenkosten ungueltig")
		var route_costs: Dictionary = Dictionary(data.get("route_fuel_costs", {}))
		for route: String in route_costs:
			var legs: Variant = data.leg_fuel_costs.get(route)
			if typeof(legs) != TYPE_DICTIONARY: return _reject("invalid_supply_data", "Etappenkosten fehlen fuer " + route)
			var leg_sum := 0.0
			for leg: String in legs:
				if leg not in FUEL_LEGS or not _valid_nonnegative_number(legs[leg]): return _reject("invalid_supply_data", "Etappenkosten ungueltig")
				leg_sum += float(legs[leg])
			if absf(leg_sum - float(route_costs[route])) > 0.00001: return _reject("invalid_supply_data", "Etappen ergeben nicht die Streckenkosten: " + route)
		var structure_error: String = _leg_structure_error(data.leg_fuel_costs)
		if not structure_error.is_empty(): return _reject("invalid_supply_data", structure_error)
	# Nottankdienst (T2): alle Zahlen kommen aus diesem Block; er darf fehlen (dann gibt es keinen Dienst).
	if data.has("emergency_fuel"):
		var emergency_error: String = _emergency_fuel_error(data.emergency_fuel)
		if not emergency_error.is_empty(): return _reject("invalid_supply_data", emergency_error)
	# Schulden (K): Kreditrahmen und Zinsen stehen im Block debt; er darf fehlen (dann gibt es keine Schulden).
	if data.has("debt"):
		var debt_error: String = _debt_error(data.debt)
		if not debt_error.is_empty(): return _reject("invalid_supply_data", debt_error)
	_reset_route_fuel_preparation()
	_station_purchase_cache_revision = -1
	_definitions = data
	_credits = int(data.initial_credits)
	_debt_remaining = -1.0
	_item_quantities.clear()
	_inventory.clear()
	_modular_capacity_baseline = -1
	_modular_plan_cache_revision = -1
	_location_resources.clear()
	var resources: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/location_resources.json"))
	for place in resources:
		var owner=load("res://scripts/core/location_runtime_state.gd").new()
		owner.configure(resources[place]); _location_resources[place]=owner
	_fuel_by_craft_id.clear()
	_stock_by_offer_id.clear()
	_requests.clear()
	_reward_receipts.clear()
	_research_receipts.clear()
	_research_snapshot_revision = -1
	_open_tanker_cache_revision = -1
	_revision = 0
	for offer_id in Dictionary(data.get("offers", {})):
		_stock_by_offer_id[String(offer_id)] = int(data.offers[offer_id].stock)
	_market = parsed_market.market
	_market_stock = _full_market_stock()
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
	return {"credits": _credits, "campaign_beds":get_campaign_bed_count(), "campaign_housing":get_campaign_housing_count(), "campaign_housing_beds":get_campaign_housing_beds(), "modular_base":get_modular_base(), "item_quantities": _item_quantities.duplicate(true), "fuel_by_craft_id": _fuel_by_craft_id.duplicate(true), "stock_by_offer_id": _stock_by_offer_id.duplicate(true), "offers": Dictionary(_definitions.get("offers", {})).duplicate(true), "fuel_capacity": float(_definitions.get("fuel_capacity", 0.0)), "fuel_price_per_unit": float(_definitions.get("fuel_price_per_unit", 0.0)), "route_fuel_costs": Dictionary(_definitions.get("route_fuel_costs", {})).duplicate(true), "leg_fuel_costs": Dictionary(_definitions.get("leg_fuel_costs", {})).duplicate(true), "emergency_fuel": Dictionary(_definitions.get("emergency_fuel", {})).duplicate(true), "debt": Dictionary(_definitions.get("debt", {})).duplicate(true), "reward_completion_ids": _reward_receipts.keys().duplicate(), "revision": _revision, "inventory": _inventory_view(), "blueprints": _blueprints(), "research": get_research_snapshot(), "commodity_buy_orders": _definitions.get("commodity_buy_orders", {}).duplicate(true), "market": get_market_snapshot(), "station_home_pads": get_station_home_pads()}

func get_research_snapshot() -> Dictionary:
	if _research_snapshot_revision != _revision:
		_research_snapshot_cache = RESEARCH.build_snapshot(_research_receipts, _reward_receipts, _requests, _credits)
		var fabrication := {}
		var recipes: Array = CAMPAIGN_RECIPES.keys()
		recipes.append_array(RESEARCH.definitions().get("fabrication", {}).keys())
		for id: String in recipes: fabrication[id] = preview_campaign_fabrication(id)
		_research_snapshot_cache["fabrication"] = fabrication
		_research_snapshot_revision = _revision
	return _research_snapshot_cache.duplicate(true)

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
		"collect_resource": result = _collect_resource(payload, authority_context)
		"station_install_ship_component": result = _install_ship_component(payload, authority_context, request_id)
		"inventory_transfer": result = _inventory_transfer(payload, authority_context)
		"cargo_transfer_start":
			result = {"ok":true} if authority_context.get("cargo_transfer_authorized",false) == true else _reject("cargo_transfer_untrusted","Frachtauftrag nicht bestätigt")
		"inventory_equip": result = _inventory_equip(payload, authority_context)
		"buy": result = _buy(payload, authority_context)
		"station_buy_ship": result = _station_buy_ship(payload, authority_context, request_id)
		"station_recruit_reserve": result = _reserve_station_recruit(payload, authority_context)
		"station_recruit_finalize": result = _finalize_station_recruit(payload, authority_context)
		"station_recruit_cancel": result = _cancel_station_recruit(payload, authority_context)
		"station_build_home_pad": result = _station_build_home_pad(authority_context)
		"refuel": result = _refuel(payload, authority_context)
		"repair": result = _repair(payload, authority_context)
		"consume_route_fuel": result = _consume_route(payload, authority_context)
		"consume_leg_fuel": result = _consume_leg(payload, authority_context)
		"emergency_tanker_order": result = _emergency_tanker_order(payload, authority_context, request_id)
		"emergency_tanker_deliver": result = _emergency_tanker_deliver(payload, authority_context, request_id)
		"emergency_tanker_cancel": result = _emergency_tanker_cancel(payload, authority_context, request_id)
		"apply_reward": result = _reward(payload, authority_context)
		"campaign_cargo": result = _campaign_cargo(payload, authority_context)
		"campaign_research": result = _campaign_research(payload, authority_context, request_id)
		"campaign_fabricate": result = _campaign_fabricate(payload, authority_context)
		"campaign_build": result = _campaign_build(payload, authority_context)
		"campaign_build_bed": result = _campaign_build_bed(payload, authority_context)
		"campaign_build_housing": result = _campaign_build_housing(payload, authority_context)
		"campaign_build_room": result = _campaign_build_modular(payload, authority_context, false)
		"campaign_place_room_bed": result = _campaign_build_modular(payload, authority_context, true)
		"campaign_set_room_door": result = _campaign_set_room_door(payload, authority_context)
		"sell": result = _sell(payload, authority_context)
		_: result = _reject("unknown_operation", "Aktion unbekannt")
	if bool(result.get("ok", false)):
		result["request_id"] = request_id
		result["operation"] = String(command.operation)
		_requests[request_id] = {"signature": signature, "result": result.duplicate(true)}
	return result

func get_purchase_receipt(request_id: String) -> Dictionary:
	# Visual clients may read only the confirmed result, never mutate inventory.
	var entry: Dictionary = _requests.get(request_id, {})
	var result: Dictionary = entry.get("result", {})
	if result.get("operation") != "buy" or result.get("request_id") != request_id: return {}
	return result.duplicate(true)

func _buy(payload: Dictionary, context: Dictionary) -> Dictionary:
	var location_id: String = String(context.get("location_id", ""))
	var offer_id: String = String(payload.get("offer_id", ""))
	if offer_id.begins_with(MARKET_OFFER_PREFIX): return _buy_market(offer_id, payload, context)
	var offer: Dictionary = Dictionary(Dictionary(_definitions.get("offers", {})).get(offer_id, {}))
	if offer.is_empty():
		return _reject("unknown_offer", "Angebot unbekannt")
	if String(offer.get("kind", "")) == "ship":
		return _reject("ship_service_required", "Schiffe beim Schiffshaendler kaufen")
	if SHIP_COMPONENTS.known(String(offer.get("item_id", ""))) and not SHIP_COMPONENTS.compatible(String(context.get("ship_component_model_id", "")), "quantum_drive", String(offer.item_id)):
		return _reject("incompatible_component", "Dieses Schiff hat keinen belegten Warp-Antriebsplatz")
	if SHIP_COMPONENTS.known(String(offer.get("item_id", ""))) or SPACE_COMPONENTS.known(String(offer.get("item_id", ""))):
		var component_craft := String(context.get("craft_id", ""))
		if not _fuel_by_craft_id.has(component_craft) or not _inventory.has("craft:"+component_craft): return _reject("inventory_access", "Schiffslager für den Antrieb fehlt")
	var blueprint := String(offer.get("required_blueprint", ""))
	if bool(context.get("require_blueprints", false)) and not blueprint.is_empty() and not _blueprints().has(blueprint):
		return _reject("blueprint_locked", "Zuerst die passende Erwerbserlaubnis freischalten")
	if bool(context.get("craft_busy", true)):
		return _reject("craft_busy", "Handel erst nach der Landung am Serviceort")
	if not _has_service(location_id, "trade") or not Array(offer.get("location_ids", [])).has(location_id):
		return _reject("trade_unavailable", "Handel nur am Handelsservice")
	if not _valid_positive_integer(payload.get("quantity")):
		return _reject("invalid_quantity", "Menge muss eine positive ganze Zahl sein")
	var quantity: int = int(payload.quantity)
	# Angebote mit "unlimited": true (Munition, M3) haben keinen Vorrat; die Bestandszahl bleibt unveraendert.
	var unlimited: bool = bool(offer.get("unlimited", false))
	if not unlimited and quantity > int(_stock_by_offer_id.get(offer_id, 0)):
		return _reject("insufficient_stock", "Angebotsmenge reicht nicht")
	var price: int = int(offer.get("unit_price", 0))
	if price <= 0 or quantity > _credits / price:
		return _reject("insufficient_credits", "Credits reichen nicht")
	var destination := String(context.get("cargo_lift_container_id","station:polisa:lift")) if location_id in ["polisa","trade_outpost"] and bool(context.get("cargo_lift_delivery",false)) else "craft:"+String(context.get("craft_id",""))
	var purchased_items: Dictionary = _item_quantities
	if not _inventory.is_empty():
		if not _inventory.has(destination): return _reject("inventory_access","Lieferziel fehlt")
		purchased_items=_inventory[destination].items
		if INVENTORY.used(purchased_items)+quantity>int(_inventory[destination].capacity): return _reject("container_full","Schiffsfracht ist voll")
	_credits -= quantity * price
	if not unlimited: _stock_by_offer_id[offer_id] = int(_stock_by_offer_id[offer_id]) - quantity
	var item_id: String = String(offer.item_id)
	purchased_items[item_id] = int(purchased_items.get(item_id, 0)) + quantity
	_revision += 1
	return {"ok": true, "item_id": item_id, "quantity": quantity, "cost": quantity * price, "container_id":destination if not _inventory.is_empty() else "base:homebase", "message": "Kauf bestaetigt"}

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
	var validation: Dictionary = preview_route_fuel(payload, context)
	if not bool(validation.get("ok", false)):
		return validation
	var craft_id: String = String(validation.craft_id)
	_fuel_by_craft_id[craft_id] = maxf(float(_fuel_by_craft_id[craft_id]) - float(validation.fuel_cost), 0.0)
	_revision += 1
	return validation

func preview_route_fuel(payload: Dictionary, context: Dictionary = {}) -> Dictionary:
	# Pure gate shared with the commit path, so later validation cannot differ.
	if not bool(context.get("departure_authorized", false)):
		return _reject("departure_not_authorized", "Abflug nicht bestaetigt")
	var craft_id: String = String(payload.get("craft_id", ""))
	if not _fuel_by_craft_id.has(craft_id):
		return _reject("unknown_craft", "Schiff unbekannt")
	var open_tanker: Dictionary = _open_tanker_for_craft(craft_id)
	if not open_tanker.is_empty(): return _tanker_order_open_rejection(open_tanker)
	var route: String = String(payload.get("origin_location_id", "")) + ">" + String(payload.get("destination_location_id", ""))
	var routes: Dictionary = _definitions.get("route_fuel_costs", {})
	if not routes.has(route):
		return _reject("unknown_route", "Ortsverbindung unbekannt")
	var cost: float = float(routes[route])
	var fuel: float = float(_fuel_by_craft_id[craft_id])
	if fuel + 0.00001 < cost:
		return _reject("insufficient_fuel", "Treibstoff reicht fuer diese Strecke nicht; zuerst auftanken")
	if bool(context.get("require_return_reserve", false)):
		var reverse: String = String(payload.get("destination_location_id", "")) + ">" + String(payload.get("origin_location_id", ""))
		if not routes.has(reverse):
			return _reject("return_route_unavailable", "Fuer dieses Ziel fehlt eine bestaetigte Rueckflugstrecke")
		if fuel + 0.00001 < cost + float(routes[reverse]):
			return _reject("insufficient_return_fuel", "Treibstoff muss fuer Hin- und Rueckflug reichen; zuerst auftanken")
	return {"ok": true, "craft_id": craft_id, "fuel_cost": cost, "message": "Routentreibstoff gebucht"}

# --- Treibstoff je Etappe (Regel 8 / Auftrag 21.11.) ---------------------------------
# Jede Etappe bucht ihren Anteil genau einmal, wenn sie beginnt. Es gibt keine Rueckflugreserve:
# Eine Etappe startet nur, wenn ihr eigener Anteil gedeckt ist. Die Summe der Etappen einer Strecke
# ist gleich dem Wert in route_fuel_costs (leg_fuel_costs in data/singleplayer/trade_offers.json).
const FUEL_LEGS: Array = ["launch", "jump", "approach", "surface_exit", "landing"]
const FUEL_LEG_LABELS: Dictionary = {"launch": "Abheben", "jump": "Quantensprung", "approach": "Ortsanflug", "surface_exit": "Ortsabflug", "landing": "Landung"}

## Fix fuel structure (Fix-Runde 2, W8): Die Etappenpreise bestehen aus ortsfesten Teilen (Abheben, Anflug, Ortsabflug, Heimlandung; je Teil
## ueberall gleich) und einem Sprungpreis je Orbit-Paar. Der Sprung ist in beide Richtungen gleich, kostet immer etwas und erfuellt die
## Dreiecksungleichung: Keine Kette echter Etappen ist je billiger als die direkte Strecke, und kein Sprung startet mit leerem Tank.
## Gibt "" zurueck, wenn die Daten stimmen, sonst den Grund.
static func _pair_key(a: String, b: String) -> String:
	return a + "|" + b if a <= b else b + "|" + a

static func _leg_structure_error(table: Dictionary) -> String:
	var fixed: Dictionary = {}
	var jumps: Dictionary = {}
	for route: String in table:
		var parts: PackedStringArray = route.split(">")
		if parts.size() != 2: return "Streckenname ungueltig: " + route
		var legs: Dictionary = table[route]
		for leg: String in legs:
			if leg == "jump": continue
			if fixed.has(leg) and absf(float(fixed[leg]) - float(legs[leg])) > 0.00001: return "Ortsfester Teil %s ist nicht ueberall gleich (%s)" % [leg, route]
			fixed[leg] = float(legs[leg])
		if not legs.has("jump") or float(legs["jump"]) <= 0.0: return "Sprung ohne Kosten oder fehlend: " + route
		var key: String = _pair_key(parts[0], parts[1])
		if jumps.has(key) and absf(float(jumps[key]) - float(legs["jump"])) > 0.00001: return "Sprung nicht in beide Richtungen gleich: " + key
		jumps[key] = float(legs["jump"])
	var places: Array = []
	for key: String in jumps:
		for place: String in key.split("|"):
			if not places.has(place): places.append(place)
	for a: String in places:
		for b: String in places:
			for c: String in places:
				if a == b or b == c or a == c: continue
				var ab: String = _pair_key(a, b)
				var bc: String = _pair_key(b, c)
				var ac: String = _pair_key(a, c)
				if jumps.has(ab) and jumps.has(bc) and jumps.has(ac) and float(jumps[ac]) > float(jumps[ab]) + float(jumps[bc]) + 0.00001:
					return "Dreiecksungleichung verletzt: %s > %s + %s" % [ac, ab, bc]
	return ""

func has_fuel_account(craft_id: String) -> bool:
	return _fuel_by_craft_id.has(craft_id)

func has_request(request_id: String) -> bool:
	return _requests.has(request_id)

func get_fuel(craft_id: String) -> float:
	return float(_fuel_by_craft_id.get(craft_id, 0.0))

func get_fuel_capacity() -> float:
	return float(_definitions.get("fuel_capacity", 0.0))

func get_fuel_price_per_unit() -> float:
	return float(_definitions.get("fuel_price_per_unit", 0.0))

## Kosten einer Etappe.
## Abheben ohne Ziel (destination leer) und Landung ohne Herkunft (origin leer) sind ziel-unabhaengig.
## Gibt -1.0 zurueck, wenn die Etappe nicht definiert ist.
func get_leg_fuel_cost(origin: String, destination: String, leg: String) -> float:
	var table: Dictionary = Dictionary(_definitions.get("leg_fuel_costs", {}))
	var route := origin + ">" + destination
	if leg not in FUEL_LEGS: return -1.0
	if table.has(route) and Dictionary(table[route]).has(leg): return float(table[route][leg])
	if leg == "launch" and origin == "homebase" and destination.is_empty():
		return _cheapest_leg(table, leg, "homebase>", "")
	if leg == "landing" and destination == "homebase" and origin.is_empty():
		return _cheapest_leg(table, leg, "", ">homebase")
	if leg == "jump" and not table.has(route) and origin != "homebase" and destination != "homebase" and not origin.is_empty() and not destination.is_empty():
		# Zwei Orte ohne eigene Strecke: Sprung ueber die Heimat (beide Haelften der Sprungkosten).
		var there := get_leg_fuel_cost(origin, "homebase", "jump")
		var back := get_leg_fuel_cost("homebase", destination, "jump")
		return there + back if there >= 0.0 and back >= 0.0 else -1.0
	return -1.0

func _cheapest_leg(table: Dictionary, leg: String, prefix: String, suffix: String) -> float:
	var best := -1.0
	for route: String in table:
		if (not prefix.is_empty() and not route.begins_with(prefix)) or (not suffix.is_empty() and not route.ends_with(suffix)): continue
		if not Dictionary(table[route]).has(leg): continue
		var value := float(table[route][leg])
		if best < 0.0 or value < best: best = value
	return best

static func _fuel_text(value: float) -> String:
	return "%d" % int(round(value)) if is_equal_approx(value, round(value)) else "%.1f" % value

## Lesende Vorpruefung, geteilt mit der Buchung. Aendert nichts (auch nicht _revision).
func preview_leg_fuel(payload: Dictionary, context: Dictionary = {}) -> Dictionary:
	if not bool(context.get("departure_authorized", false)):
		return _reject("departure_not_authorized", "Abflug nicht bestaetigt")
	var craft_id: String = String(payload.get("craft_id", ""))
	if not _fuel_by_craft_id.has(craft_id):
		return _reject("unknown_craft", "Schiff unbekannt")
	# Solange ein Tankerauftrag fuer dieses Schiff offen ist, startet keine Etappe (auch keine kostenlose): das Schiff bleibt stehen.
	var open_tanker: Dictionary = _open_tanker_for_craft(craft_id)
	if not open_tanker.is_empty(): return _tanker_order_open_rejection(open_tanker)
	var leg := String(payload.get("leg", ""))
	var origin := String(payload.get("origin_location_id", ""))
	var destination := String(payload.get("destination_location_id", ""))
	var cost := get_leg_fuel_cost(origin, destination, leg)
	if cost < 0.0:
		return _reject("unknown_leg", "Etappe unbekannt")
	# Anrechnung (nur intern, vom Simulationsbesitzer): ein schon bezahlter Teil derselben Etappe, zum Beispiel beim Neustart eines
	# abgebrochenen Sprungs zu einem teureren Ziel. Es wird nur die Differenz gebucht; nie mehr als die Etappe kostet, nie zurueck.
	if payload.has("already_paid"):
		var credit: Variant = payload.get("already_paid")
		if typeof(credit) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(credit)) or float(credit) < 0.0:
			return _reject("invalid_leg_credit", "Anrechnung ungueltig")
		cost = maxf(cost - float(credit), 0.0)
	var fuel: float = float(_fuel_by_craft_id[craft_id])
	if fuel + 0.00001 < cost:
		var message := "Treibstoff reicht nicht für den Rückflug" if leg == "surface_exit" else "Treibstoff reicht nicht für diese Etappe (%s). Benötigt %s, vorhanden %s." % [String(FUEL_LEG_LABELS.get(leg, leg)), _fuel_text(cost), _fuel_text(fuel)]
		var rejected := _reject("leg_fuel_insufficient", message)
		rejected.merge({"leg": leg, "needed": cost, "available": fuel}, true)
		return rejected
	return {"ok": true, "craft_id": craft_id, "leg": leg, "fuel_cost": cost, "message": "Etappentreibstoff gebucht"}

func _consume_leg(payload: Dictionary, context: Dictionary) -> Dictionary:
	var validation: Dictionary = preview_leg_fuel(payload, context)
	if not bool(validation.get("ok", false)):
		return validation
	var craft_id: String = String(validation.craft_id)
	_fuel_by_craft_id[craft_id] = maxf(float(_fuel_by_craft_id[craft_id]) - float(validation.fuel_cost), 0.0)
	_revision += 1
	return validation

# --- Nottankdienst (T2 des Tanker-Auftrags, 21.11.2026) ------------------------------------------------
# Geld, Treibstoff und Belege liegen hier. Zustaende und Restzeit fuehrt scripts/core/emergency_tanker_service.gd, getickt von der
# Laufzeit-Stelle (singleplayer_runtime_adapter.gd). Ein Auftrag ist "offen", solange sein Bestellbeleg weder einen Lieferbeleg
# (<order_id>:deliver) noch einen Stornobeleg (<order_id>:cancel) hat; das gilt auch nach dem Laden. Alle Zahlen stehen im Block
# emergency_fuel der Daten, nichts davon im Code.

static func _emergency_fuel_error(block: Variant) -> String:
	if typeof(block) != TYPE_DICTIONARY: return "Tankerdaten ungueltig"
	var number_ok := func(value: Variant) -> bool: return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) >= 0.0
	var integer_ok := func(value: Variant) -> bool: return number_ok.call(value) and float(value) == floorf(float(value)) and float(value) <= 2147483647.0
	if not integer_ok.call(block.get("callout_fee")): return "Tanker: Anfahrtsgebuehr ungueltig"
	if not number_ok.call(block.get("price_per_unit")) or float(block.price_per_unit) <= 0.0: return "Tanker: Mengenpreis ungueltig"
	if not integer_ok.call(block.get("quantity")) or float(block.quantity) <= 0.0: return "Tanker: Liefermenge ungueltig"
	if not integer_ok.call(block.get("min_quantity")) or float(block.min_quantity) <= 0.0 or float(block.min_quantity) > float(block.quantity): return "Tanker: Mindestmenge ungueltig"
	for key: String in ["dispatch_seconds", "response_seconds", "refuel_seconds", "delivery_retry_seconds"]:
		if not number_ok.call(block.get(key)): return "Tanker: Zeit ungueltig: " + key
	if typeof(block.get("status")) != TYPE_STRING: return "Tanker: Status fehlt"
	return ""

## Offene Auftraege, aus den Belegen abgeleitet: order_id -> Ergebnis des Bestellbefehls. Gilt auch nach dem Laden.
func get_open_tanker_orders() -> Dictionary:
	if _open_tanker_cache_revision != _revision:
		_open_tanker_cache = {}
		for request_id: String in _requests:
			var result: Dictionary = Dictionary(_requests[request_id].get("result", {}))
			if String(result.get("operation", "")) != "emergency_tanker_order": continue
			if _requests.has(request_id + ":deliver") or _requests.has(request_id + ":cancel"): continue
			_open_tanker_cache[request_id] = result.duplicate(true)
		_open_tanker_cache_revision = _revision
	return _open_tanker_cache.duplicate(true)

func _open_tanker_for_craft(craft_id: String) -> Dictionary:
	if _open_tanker_cache_revision != _revision: get_open_tanker_orders()
	for order: Dictionary in _open_tanker_cache.values():
		if String(order.get("craft_id", "")) == craft_id: return order
	return {}

func _tanker_reject(reason: String, extra: Dictionary = {}) -> Dictionary:
	var result := _reject(reason, EMERGENCY_TANKER.message_for(reason, extra))
	result.merge(extra, false)
	return result

func _tanker_order_open_rejection(order: Dictionary) -> Dictionary:
	return _tanker_reject("tanker_order_open", {"order_id": String(order.get("order_id", ""))})

## Reine Auskunft vor der Bestellung: Menge, Preis, Wartezeit oder der Grund der Sperre. Bucht nichts, aendert die Revision nicht.
## Der Kontext kommt vom Laufzeit-Besitzer (Adapter): craft_available, at_service_point, fuel_problem (aus get_fuel_status).
func preview_emergency_tanker(payload: Dictionary, context: Dictionary = {}) -> Dictionary:
	var data: Dictionary = Dictionary(_definitions.get("emergency_fuel", {}))
	if data.is_empty(): return _tanker_reject("emergency_fuel_unavailable")
	var craft_id: String = String(payload.get("craft_id", ""))
	if craft_id.is_empty() or not _fuel_by_craft_id.has(craft_id) or context.get("craft_available", false) != true:
		return _tanker_reject("craft_unavailable")
	var open_order: Dictionary = _open_tanker_for_craft(craft_id)
	if not open_order.is_empty(): return _tanker_order_open_rejection(open_order)
	if context.get("at_service_point", true) != false: return _tanker_reject("at_service_point")
	if context.get("fuel_problem", false) != true: return _tanker_reject("no_fuel_problem")
	var capacity: float = float(_definitions.fuel_capacity)
	var fuel: float = float(_fuel_by_craft_id[craft_id])
	var free: float = maxf(capacity - fuel, 0.0)
	var quantity: int = int(minf(float(data.quantity), floorf(free + 0.00001)))
	if quantity < int(data.min_quantity):
		return _tanker_reject("tank_nearly_full", {"quantity": quantity, "min_quantity": int(data.min_quantity)})
	var callout_fee: int = int(data.callout_fee)
	var price: int = callout_fee + int(ceil(float(quantity) * float(data.price_per_unit)))
	# Schulden (K, E2/E3): der Nottankdienst ist einer von zwei Wegen ins Minus; er liefert bis zum Kreditrahmen auf Kredit.
	# Abschnitt P: credits_override (nur vom Adapter gesetzt) fragt "wie wuerde die Bestellung mit diesem erreichbaren Kontostand ausgehen"
	# mit genau dieser Rechnung (Pleite-Pruefung); ohne den Schluessel gilt das echte Guthaben.
	var credits_after: int = int(context.get("credits_override", _credits)) - price
	var debt: Dictionary = Dictionary(_definitions.get("debt", {}))
	if credits_after < 0:
		if debt.is_empty():
			return _tanker_reject("insufficient_credits", {"price": price, "credits": _credits, "quantity": quantity})
		if credits_after < -int(debt.debt_limit):
			return _tanker_reject("debt_limit_reached", {"price": price, "credits": _credits, "credits_after": credits_after, "debt_limit": int(debt.debt_limit), "quantity": quantity})
	var dispatch_seconds: float = float(data.dispatch_seconds)
	var response_seconds: float = float(data.response_seconds)
	var refuel_seconds: float = float(data.refuel_seconds)
	return {"ok": true, "craft_id": craft_id, "quantity": quantity, "price": price, "callout_fee": callout_fee, "unit_price": float(data.price_per_unit),
		"credits": _credits, "credits_after": credits_after, "on_credit": credits_after < 0, "interest_rate": float(debt.get("interest_rate", 0.0)), "interest_period_seconds": float(debt.get("interest_period_seconds", 0.0)), "free_capacity": free, "dispatch_seconds": dispatch_seconds, "response_seconds": response_seconds, "refuel_seconds": refuel_seconds, "delivery_retry_seconds": float(data.delivery_retry_seconds),
		"wait_seconds": dispatch_seconds + response_seconds, "total_seconds": dispatch_seconds + response_seconds + refuel_seconds, "status": String(data.get("status", "")),
		"message": "Tanker rufen: %d Einheiten für %d Cr, Ankunft in etwa %d s." % [quantity, price, int(ceil(dispatch_seconds + response_seconds))]}

func _tanker_authorized(context: Dictionary) -> bool:
	return context.get("emergency_tanker_authorized", false) == true

## Bestellen: bucht den Preis sofort und genau einmal. order_id ist die Anfrage-ID (stabil); dieselbe Anfrage noch einmal liefert
## den Beleg mit replayed=true (apply_command), ohne zweite Buchung.
func _emergency_tanker_order(payload: Dictionary, context: Dictionary, request_id: String) -> Dictionary:
	if not _tanker_authorized(context): return _tanker_reject("tanker_not_authorized")
	var preview: Dictionary = preview_emergency_tanker(payload, context)
	if not bool(preview.get("ok", false)): return preview
	_debt_before_booking()
	_credits -= int(preview.price)
	_revision += 1
	var receipt: Dictionary = preview.duplicate(true)
	for key: String in ["credits", "credits_after", "on_credit", "interest_rate", "interest_period_seconds", "free_capacity", "wait_seconds", "total_seconds", "status"]: receipt.erase(key)
	receipt["order_id"] = request_id
	receipt["message"] = "Tanker bestellt"
	return receipt

func _tanker_order_receipt(order_id: String) -> Dictionary:
	var result: Dictionary = Dictionary(Dictionary(_requests.get(order_id, {})).get("result", {}))
	return result if String(result.get("operation", "")) == "emergency_tanker_order" else {}

## Lieferung: schreibt die bestellte Menge genau einmal gut (begrenzt durch die freie Tankkapazitaet). Der Lieferbeleg hat die feste
## Kennung <order_id>:deliver; ein bereits storniertes oder verfallenes Auftrag wird nicht beliefert.
func _emergency_tanker_deliver(payload: Dictionary, context: Dictionary, request_id: String) -> Dictionary:
	if not _tanker_authorized(context): return _tanker_reject("tanker_not_authorized")
	var order_id: String = String(payload.get("order_id", ""))
	if order_id.is_empty() or request_id != order_id + ":deliver": return _tanker_reject("invalid_request_id")
	var order: Dictionary = _tanker_order_receipt(order_id)
	if order.is_empty(): return _tanker_reject("unknown_order")
	if _requests.has(order_id + ":cancel"): return _tanker_reject("order_closed")
	var craft_id: String = String(order.craft_id)
	if not _fuel_by_craft_id.has(craft_id): return _tanker_reject("craft_unavailable")
	var capacity: float = float(_definitions.fuel_capacity)
	var fuel: float = float(_fuel_by_craft_id[craft_id])
	# Geliefert werden nur ganze Einheiten, die noch in den Tank passen (der Tank kann seit der Bestellung voller geworden sein).
	var delivered: int = int(minf(float(order.quantity), floorf(maxf(capacity - fuel, 0.0) + 0.00001)))
	# Fix-Runde 1 (W-T2-2): fuer jede bestellte, aber nicht gelieferte Einheit wird der Mengenpreis erstattet, mit dem Satz aus dem Beleg.
	# Erstattung = bezahlter Mengenpreis - ceil(gelieferte Menge x Satz); die Anfahrtsgebuehr bleibt beim Dienst. Im selben Schritt, genau einmal.
	var quantity_price: int = int(order.price) - int(order.callout_fee)
	var refund: int = maxi(quantity_price - int(ceil(float(delivered) * float(order.unit_price))), 0)
	_fuel_by_craft_id[craft_id] = minf(fuel + float(delivered), capacity)
	_credits += refund
	_revision += 1
	return {"ok": true, "order_id": order_id, "craft_id": craft_id, "quantity": int(order.quantity), "ordered": int(order.quantity), "amount": delivered, "refund": refund, "callout_kept": int(order.callout_fee), "fuel_after": float(_fuel_by_craft_id[craft_id]), "message": "Tanker hat betankt" if delivered == int(order.quantity) else "Tanker hat %d von %d Einheiten betankt, erstattet: %d Cr" % [delivered, int(order.quantity), refund]}

## Stornieren oder Verfall. reason "player": in requested volle Rueckerstattung, in en_route nur der Mengenpreis (die Anfahrtsgebuehr ist
## verloren), ab at_ship nicht mehr moeglich (tanker_already_arrived). reason "expired" (Schiff zerstoert oder aus der Flotte
## entfernt): volle Rueckerstattung in jedem Zustand. Den Zustand liefert der Dienstbesitzer ueber den Kontext (emergency_tanker_state).
## Jede Erstattung genau einmal: der Stornobeleg hat die feste Kennung <order_id>:cancel.
func _emergency_tanker_cancel(payload: Dictionary, context: Dictionary, request_id: String) -> Dictionary:
	if not _tanker_authorized(context): return _tanker_reject("tanker_not_authorized")
	var order_id: String = String(payload.get("order_id", ""))
	var reason: String = String(payload.get("reason", "player"))
	if order_id.is_empty() or request_id != order_id + ":cancel" or reason not in ["player", "expired"]: return _tanker_reject("invalid_request_id")
	var order: Dictionary = _tanker_order_receipt(order_id)
	if order.is_empty(): return _tanker_reject("unknown_order")
	if _requests.has(order_id + ":deliver"): return _tanker_reject("order_closed")
	var price: int = int(order.price)
	var state: String = String(context.get("emergency_tanker_state", ""))
	var refund: int = price
	if reason == "player":
		if state == "requested": refund = price
		elif state == "en_route": refund = price - int(order.callout_fee)
		else: return _tanker_reject("tanker_already_arrived")
	_credits += refund
	_revision += 1
	return {"ok": true, "order_id": order_id, "craft_id": String(order.craft_id), "reason": reason, "state": state if reason == "player" else "expired", "refund": refund, "kept": price - refund, "message": "Tankerauftrag beendet, erstattet: %d Cr" % refund}

## Belege der Tankerbefehle beim Laden pruefen: ein Lieferbeleg und ein Stornobeleg zum selben Auftrag schliessen sich aus, beide
## gehoeren zu einem vorhandenen Bestellbeleg, Preis und Erstattung folgen den Zahlen im Bestellbeleg selbst.
func _valid_tanker_requests(requests: Dictionary) -> bool:
	for request_id: String in requests:
		var entry: Dictionary = requests[request_id]
		var result: Dictionary = Dictionary(entry.get("result", {}))
		var operation: String = String(result.get("operation", ""))
		if operation not in ["emergency_tanker_order", "emergency_tanker_deliver", "emergency_tanker_cancel"]: continue
		var signature: Dictionary = Dictionary(JSON.parse_string(String(entry.get("signature", "{}"))))
		var payload: Dictionary = Dictionary(signature.get("payload", {}))
		if operation == "emergency_tanker_order":
			var craft_id: String = String(result.get("craft_id", ""))
			if craft_id.is_empty() or String(result.get("order_id", "")) != request_id or String(payload.get("craft_id", "")) != craft_id: return false
			if not _valid_positive_integer(result.get("quantity")) or not _valid_nonnegative_integer(result.get("callout_fee")) or not _valid_nonnegative_integer(result.get("price")) or int(result.price) < int(result.callout_fee): return false
			if not _valid_nonnegative_number(result.get("unit_price")) or int(result.price) != int(result.callout_fee) + int(ceil(float(result.quantity) * float(result.unit_price))): return false
			for key: String in ["dispatch_seconds", "response_seconds", "refuel_seconds", "delivery_retry_seconds"]:
				if not _valid_nonnegative_number(result.get(key)): return false
			continue
		var order_id: String = String(payload.get("order_id", ""))
		var order: Dictionary = Dictionary(Dictionary(requests.get(order_id, {})).get("result", {}))
		if order.is_empty() or String(order.get("operation", "")) != "emergency_tanker_order" or String(result.get("order_id", "")) != order_id or String(result.get("craft_id", "")) != String(order.get("craft_id", "")): return false
		if operation == "emergency_tanker_deliver":
			if request_id != order_id + ":deliver" or requests.has(order_id + ":cancel"): return false
			if not _valid_nonnegative_integer(result.get("amount")) or int(result.amount) > int(order.quantity): return false
			var expected_refund: int = maxi(int(order.price) - int(order.callout_fee) - int(ceil(float(result.amount) * float(order.unit_price))), 0)
			if not _valid_nonnegative_integer(result.get("refund")) or int(result.refund) != expected_refund: return false
		else:
			if request_id != order_id + ":cancel" or requests.has(order_id + ":deliver"): return false
			var reason: String = String(result.get("reason", ""))
			var refund: Variant = result.get("refund")
			if not _valid_nonnegative_integer(refund): return false
			var price: int = int(order.price)
			var allowed: Array = [price] if reason == "expired" else ([price, price - int(order.callout_fee)] if reason == "player" else [])
			if not allowed.has(int(refund)): return false
	return true

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

func _valid_integer(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) == floor(float(value)) and absf(float(value)) <= 2147483647.0

func _valid_positive_integer(value: Variant) -> bool:
	return _valid_nonnegative_integer(value) and int(value) > 0

func _reject(reason: String, message: String) -> Dictionary:
	return {"ok": false, "reason": reason, "message": message}

func export_state() -> Dictionary:
	var exported: Dictionary = _export_state_base()
	# Schulden (K): Restzeit bis zur naechsten Zinsbuchung, nur im Minus (additiver Schluessel; fehlt er, gilt die volle Periode).
	if _credits < 0 and _debt_remaining >= 0.0: exported["debt_interest_remaining"] = _debt_remaining
	# M4b: optionaler Merker (fehlt in alten Staenden: die Startausstattung mit Magazinen wird dann einmal nachgereicht).
	if _ammo_start_granted: exported["ammo_start_granted"] = true
	# Handel H2: Marktbestaende (additiver Schluessel; fehlt er, laedt der Stand mit vollem Bestand).
	if not _market_stock.is_empty(): exported["market_stock"] = _market_stock.duplicate()
	return exported

func _export_state_base() -> Dictionary:
	return {"schema_version":1,"definitions":_definitions.duplicate(true),"credits":_credits,"item_quantities":_item_quantities.duplicate(true),"fuel_by_craft_id":_fuel_by_craft_id.duplicate(true),"stock_by_offer_id":_stock_by_offer_id.duplicate(true),"requests":_requests.duplicate(true),"reward_receipts":_reward_receipts.duplicate(true),"revision":_revision,"inventory":_inventory_view(),"location_resources":_export_resources(),"research_receipts":_research_receipts.duplicate(true),"modular_capacity_baseline":_modular_capacity_baseline}

func restore_state(data: Dictionary) -> Dictionary:
	var fresh = get_script().new()
	if not fresh.configure().get("ok", false):
		return _reject("invalid_supply_data", "Aktuelle Versorgungsdaten fehlen")
	# Credits duerfen negativ sein (Schulden, K); ein Guthaben ueber der Grenze oder keine ganze Zahl bleibt ungueltig.
	if data.get("schema_version") != 1 or not _valid_integer(data.get("credits")) or not _valid_nonnegative_integer(data.get("revision")):
		return _reject("invalid_supply_state", "Versorgungsstand ungueltig")
	if data.has("debt_interest_remaining") and not _valid_nonnegative_number(data.debt_interest_remaining):
		return _reject("invalid_supply_state", "Zinsuhr ungueltig")
	for field in ["definitions", "item_quantities", "fuel_by_craft_id", "stock_by_offer_id", "requests", "reward_receipts"]:
		if typeof(data.get(field)) != TYPE_DICTIONARY:
			return _reject("invalid_supply_state", "Versorgungsfelder fehlen")
	if not _compatible_definitions(data.definitions, fresh._definitions):
		return _reject("stale_supply_definitions", "Versorgungsdefinition geaendert")
	var items: Array = []
	for offer in fresh._definitions.offers.values():
		items.append(String(offer.item_id))
	for item_id in data.item_quantities:
		if not (items.has(String(item_id)) or INVENTORY.known(String(item_id))) or not _valid_nonnegative_integer(data.item_quantities[item_id]):
			return _reject("invalid_inventory", "Inventar ungueltig")
	if data.stock_by_offer_id.size() != Dictionary(data.definitions.get("offers",{})).size():
		return _reject("invalid_stock", "Angebotsbestand ungueltig")
	for offer_id in data.stock_by_offer_id:
		if not Dictionary(data.definitions.get("offers",{})).has(offer_id) or not _valid_nonnegative_integer(data.stock_by_offer_id.get(offer_id)) or float(data.stock_by_offer_id[offer_id]) > float(fresh._stock_by_offer_id[offer_id]):
			return _reject("invalid_stock", "Angebotsbestand ungueltig")
	for craft_id in data.fuel_by_craft_id:
		if typeof(craft_id) != TYPE_STRING or String(craft_id).is_empty() or not _valid_nonnegative_number(data.fuel_by_craft_id[craft_id]) or float(data.fuel_by_craft_id[craft_id]) > float(fresh._definitions.fuel_capacity):
			return _reject("invalid_fuel", "Treibstoff ungueltig")
	var campaign = load("res://scripts/core/singleplayer_campaign_state.gd").new()
	campaign.configure()
	var jobs: Dictionary = campaign.get_campaign_snapshot().jobs
	for receipt_id in data.reward_receipts:
		var receipt: Variant = data.reward_receipts[receipt_id]
		if typeof(receipt) != TYPE_DICTIONARY or not jobs.has(receipt.get("job_id", "")):
			return _reject("invalid_reward_receipt", "Belohnungsbeleg ungueltig")
		var job: Dictionary = jobs[receipt.job_id]
		if receipt_id != String(receipt.job_id) + ":completed" or receipt.get("completion_id") != receipt_id or receipt.get("runtime_verified") != true or receipt.get("scenario_id") != job.scenario_id or JSON.stringify(JSON.parse_string(JSON.stringify(receipt.get("reward"))), "", true) != JSON.stringify(JSON.parse_string(JSON.stringify(job.reward)), "", true):
			return _reject("invalid_reward_receipt", "Belohnungsbeleg widerspricht Auftrag")
	for request_id in data.requests:
		var request: Variant = data.requests[request_id]
		if typeof(request_id) != TYPE_STRING or String(request_id).strip_edges().is_empty() or typeof(request) != TYPE_DICTIONARY or typeof(request.get("signature")) != TYPE_STRING or typeof(request.get("result")) != TYPE_DICTIONARY or request.result.get("ok") != true:
			return _reject("invalid_requests", "Anfragebelege ungueltig")
		var signature: Variant = JSON.parse_string(request.signature)
		if typeof(signature) != TYPE_DICTIONARY or typeof(signature.get("payload")) != TYPE_DICTIONARY or typeof(signature.get("operation")) != TYPE_STRING or not COMMANDS.validate_command(COMMANDS.build_command(signature.operation, signature.payload, request_id)) or request.result.get("request_id") != request_id or request.result.get("operation") != signature.operation:
			return _reject("invalid_requests", "Anfragebeleg widerspricht Signatur")
	if not _valid_component_requests(data.requests, data.stock_by_offer_id, fresh._definitions): return _reject("invalid_component_receipts", "Komponentenbelege ungültig")
	if not _valid_recruit_requests(data.requests): return _reject("invalid_recruit_receipts", "Anwerbungsbelege ungültig")
	if not _valid_campaign_bed_requests(data.requests): return _reject("invalid_bed_receipts", "Bettenbelege ungültig")
	if not fresh._valid_tanker_requests(data.requests): return _reject("invalid_tanker_receipts", "Tankerbelege ungültig")
	var modular_replay: Dictionary = MODULAR.replay(data.requests)
	if not modular_replay.get("ok", false): return modular_replay
	var station_receipts: Dictionary = fresh.validate_station_receipts(data.requests)
	if not station_receipts.get("ok", false): return station_receipts
	var research: Variant = data.get("research_receipts", {})
	if not _valid_campaign_fabrication_requests(data.requests):
		return _reject("invalid_fabrication_receipts", "Herstellungsbelege widersprechen dem Rezept")
	if not RESEARCH.validate_receipts(research, data.reward_receipts, data.requests):
		return _reject("invalid_research_receipts", "Entwicklungsbelege widersprechen ihren Voraussetzungen")
	var containers: Variant = data.get("inventory", {})
	if typeof(containers)!=TYPE_DICTIONARY:
		return _reject("invalid_inventory", "Container fehlen")
	for id in containers:
		var personal := String(id).begins_with("unit:") and String(id).ends_with(":backpack")
		var container: Variant = containers[id]
		if not (String(id) in ["base:homebase","station:polisa:lift","station:trade_outpost:lift"] or String(id).begins_with("craft:") or personal) or not INVENTORY.valid_container(container):
			return _reject("invalid_inventory", "Container ungueltig")
		if not personal and container.has("armor_chip_capacity"):
			return _reject("invalid_inventory", "Rüstungsplatz gehört zu einer Person")
	if containers.has("base:homebase") and Dictionary(containers["base:homebase"].items)!=Dictionary(data.item_quantities):
		return _reject("invalid_inventory", "Basislager widerspricht Kaufbestand")
	var modular_baseline: Variant = data.get("modular_capacity_baseline", -1)
	var storage_count := 0
	for room: Dictionary in modular_replay.plan.rooms:
		if room.type == "storage": storage_count += 1
	if storage_count > 0:
		if not _valid_nonnegative_integer(modular_baseline) or not containers.has("base:homebase") or int(containers["base:homebase"].capacity) != int(modular_baseline) + storage_count * MODULAR.STORAGE_CAPACITY:
			return _reject("invalid_modular_capacity", "Lagerkapazität widerspricht den Raumbelegen")
	elif modular_baseline != -1:
		return _reject("invalid_modular_capacity", "Unerwartete Lagerbasis")
	var resources: Variant=data.get("location_resources",{})
	if typeof(resources)!=TYPE_DICTIONARY: return _reject("invalid_resources","Ortsressourcen ungueltig")
	for place in resources:
		if not fresh._location_resources.has(place) or typeof(resources[place])!=TYPE_DICTIONARY or not fresh._location_resources[place].restore_state(resources[place]): return _reject("invalid_resources","Ortsressourcen ungueltig")
	# Handel H2: Marktbestaende sind optional (alter Stand: voller Bestand). Alte Staende muessen weiter laden: ein Bestand ueber dem
	# (spaeter gesenkten) Datenwert wird gekappt, ein negativer auf 0 gesetzt, unbekannte Orte/Waren werden still verworfen.
	var market_saved: Variant = data.get("market_stock", {})
	var market_full: Dictionary = fresh._full_market_stock()
	if typeof(market_saved) != TYPE_DICTIONARY: return _reject("invalid_stock", "Marktbestand ungueltig")
	for market_key: Variant in market_saved:
		if market_full.has(market_key) and not _valid_integer(market_saved[market_key]):
			return _reject("invalid_stock", "Marktbestand ungueltig")
	_reset_route_fuel_preparation()
	_market = fresh._market.duplicate(true)
	_market_stock = market_full.duplicate()
	for market_key: Variant in market_saved:
		if market_full.has(market_key): _market_stock[market_key] = clampi(int(market_saved[market_key]), 0, int(market_full[market_key]))
	_location_resources=fresh._location_resources
	_definitions = fresh._definitions.duplicate(true)
	_credits = int(data.credits)
	# Zinsuhr: nur im Minus und mit gueltigem Schluessel; sonst steht sie (volle Periode beim naechsten Zinslauf).
	_debt_remaining = -1.0
	if _credits < 0 and data.has("debt_interest_remaining"):
		var period: float = float(Dictionary(fresh._definitions.get("debt", {})).get("interest_period_seconds", 0.0))
		_debt_remaining = minf(float(data.debt_interest_remaining), period) if period > 0.0 else -1.0
	_item_quantities = data.item_quantities.duplicate(true)
	_inventory = containers.duplicate(true)
	_modular_capacity_baseline = int(modular_baseline)
	_modular_plan_cache_revision = -1
	if _inventory.has("base:homebase"): _inventory["base:homebase"].items = _item_quantities
	_fuel_by_craft_id = data.fuel_by_craft_id.duplicate(true)
	_stock_by_offer_id = fresh._stock_by_offer_id.duplicate(true)
	_stock_by_offer_id.merge(data.stock_by_offer_id,true)
	for item_id in _item_quantities:
		_item_quantities[item_id] = int(_item_quantities[item_id])
	for offer_id in _stock_by_offer_id:
		_stock_by_offer_id[offer_id] = int(_stock_by_offer_id[offer_id])
	_requests = data.requests.duplicate(true)
	_reward_receipts = data.reward_receipts.duplicate(true)
	_research_receipts = research.duplicate(true)
	_research_snapshot_revision = -1
	_open_tanker_cache_revision = -1
	_revision = int(data.revision)
	_ammo_start_granted = data.get("ammo_start_granted", false) == true
	_station_purchase_cache_revision = -1
	# Stand von vor M2 tragen Fachgroesse 1: aus der Ruestung neu bestimmen, solange nichts verschoben werden muss. Den Ueberschuss
	# ins Lager bucht erst `sync_compartments_after_load`, wenn der Loadout-Besitzer die Personen kennt (nie den Stand ablehnen).
	_sync_compartments(false)
	return {"ok":true}

## `bag_capacity` >= 0: Rucksackplaetze fuer neue Personen trotz Fach (Skirmish behaelt die 12); -1 = Kampagnenregel (0).
func configure_inventory(unit_ids: Array, craft_ids: Array, campaign_personnel: bool = false, bag_capacity: int = -1) -> void:
	if not _inventory.has("station:trade_outpost:lift"):
		_inventory["station:trade_outpost:lift"]={"capacity":256,"items":{}}
	if not _inventory.has("station:polisa:lift"):
		_inventory["station:polisa:lift"]={"capacity":256,"items":{}}
	if not _inventory.has("base:homebase"):
		_inventory["base:homebase"]={"capacity":200,"items":_item_quantities}
		for item in INVENTORY.START_STOCK:
			_item_quantities[item]=int(_item_quantities.get(item,0))+int(INVENTORY.START_STOCK[item])
	for id in craft_ids:
		var key := "craft:"+String(id)
		if not _inventory.has(key): _inventory[key]={"capacity":48,"items":{}}
	for id in unit_ids:
		var key := "unit:"+String(id)+":backpack"
		if not _inventory.has(key):
			_inventory[key] = {"capacity": bag_capacity if bag_capacity >= 0 else (0 if campaign_personnel else INVENTORY.BACKPACK_CAPACITY), "items": {}}
			if campaign_personnel:
				_inventory[key].armor_chip_capacity = INVENTORY.ARMOR_CHIP_CAPACITY
		elif campaign_personnel and not _inventory[key].has("armor_chip_capacity"):
			# Existing checkpoints already granted this bag. Keep every saved
			# item, including the previously capacity-exempt second chip.
			var bag: Dictionary = _inventory[key]
			bag.armor_chip_capacity = INVENTORY.ARMOR_CHIP_CAPACITY
			bag.capacity = maxi(int(bag.capacity), INVENTORY.backpack_slots_used(bag))
	# The fabrication projection also depends on this cold-initialized storage.
	_research_snapshot_revision = -1

func set_armor_provider(provider: Callable) -> void:
	_armor_provider = provider

## Fachgroesse zu einer Ruestung (ammo_rules.json); unbekannte oder leere Ruestung = Standardgroesse.
func _compartment_size_for(armor_id: String) -> int:
	return maxi(1, INVENTORY.AMMO_RULES.compartment_capacity(armor_id, INVENTORY.ammo_rules()))

## Was beim Verkleinern des Fachs auf `size` ins Lager muss: ueberzaehlige Magazine, nach Kennung geordnet.
## Ergebnis {item: Anzahl}; leer, wenn alles Platz hat. Veraendert nichts.
func _compartment_overflow(personal: String, size: int) -> Dictionary:
	var bag: Dictionary = _inventory[personal]
	var items: Dictionary = bag.items
	var rules: Dictionary = INVENTORY.ammo_rules()
	var left := maxi(0, INVENTORY.compartment_used(bag) - size)
	var moves: Dictionary = {}
	var order: Array = []
	var ammo_ids: Array = []
	for item in items:
		if INVENTORY.AMMO_RULES.is_ammo_item(String(item), rules): ammo_ids.append(String(item))
	ammo_ids.sort()
	order.append_array(ammo_ids)
	# Chips zaehlen nicht gegen die Fachgroesse (M2-5) und wandern nie.
	for item in order:
		if left <= 0: break
		var take := mini(left, int(items.get(item, 0)))
		if take > 0:
			moves[item] = take
			left -= take
	return moves

func _storage_accepts(storage: Dictionary, add: Dictionary, remove: Dictionary = {}) -> bool:
	var probe_items: Dictionary = Dictionary(storage.items).duplicate()
	for item in remove: probe_items[item] = int(probe_items.get(item, 0)) - int(remove[item])
	for item in add: probe_items[item] = int(probe_items.get(item, 0)) + int(add[item])
	for item in probe_items.keys():
		if int(probe_items[item]) <= 0: probe_items.erase(item)
	var probe := {"capacity": storage.capacity, "items": probe_items}
	if storage.has("armor_chip_capacity"): probe["armor_chip_capacity"] = storage.armor_chip_capacity
	return INVENTORY.valid_container(probe)

func _apply_compartment_size(personal: String, size: int, moves: Dictionary, storage: Dictionary) -> void:
	var bag: Dictionary = _inventory[personal]
	for item in moves:
		bag.items[item] = int(bag.items[item]) - int(moves[item])
		if int(bag.items[item]) <= 0: bag.items.erase(item)
		storage.items[item] = int(storage.items.get(item, 0)) + int(moves[item])
	bag["armor_chip_capacity"] = size

## Sollgroesse des Fachs einer Person laut Ruestung; 0 = keine Auskunft oder kein Fach.
func _target_compartment_size(id: String) -> int:
	if not _armor_provider.is_valid() or INVENTORY.ammo_rules().is_empty(): return 0
	if not (id.begins_with("unit:") and id.ends_with(":backpack")) or not Dictionary(_inventory.get(id, {})).has("armor_chip_capacity"): return 0
	var armor := String(_armor_provider.call(id.trim_prefix("unit:").trim_suffix(":backpack")))
	return 0 if armor.is_empty() else _compartment_size_for(armor)

## Nur lesen: die Behaelter so, wie sie nach einem Abgleich ohne Verschieben aussaehen (fuer Abfragen und Speichern).
func _inventory_view() -> Dictionary:
	var view: Dictionary = _inventory.duplicate(true)
	for key in view.keys():
		var size := _target_compartment_size(String(key))
		if size > 0 and _compartment_overflow(String(key), size).is_empty(): view[key]["armor_chip_capacity"] = size
	return view

## Einmal aufrufen, sobald der Loadout-Besitzer die geladenen Personen kennt: Ueberschuss ins Basislager (nur wenn es eines gibt).
func sync_compartments_after_load() -> void:
	_sync_compartments(true)

## Leitet die Fachgroesse jeder Person aus ihrer getragenen Ruestung ab (Alt-Staende tragen 1). Aendert Zustand: nur in Befehlen und beim Laden.
## Passt der Inhalt, wird die Groesse einfach gesetzt. Passt er nicht, wandert der Ueberschuss nur dann ins Basislager, wenn
## `move_overflow` gesetzt ist UND es dort Platz gibt; sonst (auch ohne Lager) bleibt alles stehen - nichts geht verloren.
func _sync_compartments(move_overflow: bool = false) -> void:
	for key in _inventory.keys():
		var id := String(key)
		var size := _target_compartment_size(id)
		if size == 0 or size == int(_inventory[id].armor_chip_capacity): continue
		var moves := _compartment_overflow(id, size)
		if moves.is_empty():
			_inventory[id]["armor_chip_capacity"] = size
		elif move_overflow and _inventory.has("base:homebase") and _storage_accepts(_inventory["base:homebase"], moves):
			_apply_compartment_size(id, size, moves, _inventory["base:homebase"])
			_revision += 1

func _inventory_access(id: String, context: Dictionary) -> bool:
	return _inventory.has(id) and Array(context.get("accessible_containers",[])).has(id)

func _inventory_transfer(payload: Dictionary, context: Dictionary) -> Dictionary:
	_sync_compartments()
	var source := String(payload.get("source_container_id",""))
	var target := String(payload.get("destination_container_id",""))
	var item := String(payload.get("item_id",""))
	if source==target or not _inventory_access(source,context) or not _inventory_access(target,context):
		return _reject("inventory_access", "Container ist hier nicht erreichbar")
	if not INVENTORY.known(item) or not INVENTORY.positive_integer(payload.get("amount")):
		return _reject("invalid_item_amount", "Gegenstand oder Menge ungueltig")
	var amount := int(payload.amount)
	var from: Dictionary = _inventory[source].items
	var to: Dictionary = _inventory[target].items
	if int(from.get(item,0))<amount: return _reject("insufficient_items", "Bestand reicht nicht")
	if INVENTORY.RESERVED_QUEST_ITEMS.has(item) and int(to.get(item, 0)) + amount > 1:
		return _reject("duplicate_quest_cargo", "Auftragsfracht bereits vorhanden")
	var destination: Dictionary = _inventory[target]
	var fits := INVENTORY.has_space(destination, item, amount) if destination.has("armor_chip_capacity") else INVENTORY.used(to) + amount <= int(destination.capacity)
	if not fits:
		# M6b (B5): Magazin, Fach voll, kein Rucksack getragen -> der Hinweis nennt den Ausweg.
		if destination.has("armor_chip_capacity") and int(destination.capacity) <= 0 and INVENTORY.AMMO_RULES.is_ammo_item(item, INVENTORY.ammo_rules()) and INVENTORY.compartment_used(destination) >= int(destination.armor_chip_capacity):
			return _reject("container_full", "Fach voll – mit einem Rucksack passen mehr Magazine hinein.")
		return _reject("container_full", "Kein freier Platz im Zielcontainer")
	from[item]=int(from[item])-amount
	if from[item]==0: from.erase(item)
	to[item]=int(to.get(item,0))+amount
	_revision+=1
	return {"ok":true,"message":"Gegenstand verschoben"}

func _inventory_equip(payload: Dictionary, context: Dictionary) -> Dictionary:
	if context.get("equipment_allowed",true)!=true: return _reject("equipment_in_field","Ausrüstung an der Basis wechseln")
	var source := String(payload.get("source_container_id",""))
	var slot := String(payload.get("slot",""))
	var item := String(payload.get("item_id",""))
	_sync_compartments()
	if String(payload.get("unit_id",""))!=String(context.get("unit_id","")) or not context.has("loadout") or not _inventory_access(source,context):
		return _reject("inventory_access", "Person und Ausruestung sind hier nicht erreichbar")
	if slot == "backpack":
		return _change_backpack(String(payload.unit_id), source, item, context)
	var unequip := (item == "none" and slot == "weapon_2") or (item == "suit" and slot == "armor")
	if not unequip and not INVENTORY.compatible(item,slot): return _reject("incompatible_slot", "Gegenstand passt nicht in diesen Slot")
	var from: Dictionary = _inventory[source].items
	if not unequip and int(from.get(item,0))<1: return _reject("insufficient_items", "Gegenstand nicht vorhanden")
	var loadout: Dictionary = Dictionary(context.loadout).duplicate(true)
	var previous: String = INVENTORY.item_from_slot(slot,String(loadout.get(slot,"none")))
	var returns_item := previous!="none" and INVENTORY.known(previous)
	if INVENTORY.backpack_slots_used(_inventory[source]) - (0 if unequip else 1) + (1 if returns_item else 0) > int(_inventory[source].capacity):
		return _reject("container_full", "Kein Platz fuer abgelegte Ausruestung")
	# Ruestungswechsel: Das Fach richtet sich nach der neuen Ruestung. ALLES wird geprueft, bevor irgendetwas gebucht wird.
	var personal := "unit:" + String(payload.unit_id) + ":backpack"
	var new_size := 0
	var overflow: Dictionary = {}
	if slot == "armor" and _inventory.has(personal) and Dictionary(_inventory[personal]).has("armor_chip_capacity") and not INVENTORY.ammo_rules().is_empty():
		new_size = _compartment_size_for("suit" if unequip else item.trim_prefix("armor_"))
		overflow = _compartment_overflow(personal, new_size)
		if not overflow.is_empty():
			var swap_remove: Dictionary = {} if unequip else {item: 1}
			var swap_add: Dictionary = {previous: 1} if returns_item else {}
			for moved in overflow: swap_add[moved] = int(swap_add.get(moved, 0)) + int(overflow[moved])
			if source == personal or not _storage_accepts(_inventory[source], swap_add, swap_remove):
				return _reject("compartment_overflow", "Erst das Rüstungsfach leeren: Die neue Rüstung hat weniger Plätze.")
	if not unequip:
		from[item]=int(from[item])-1
		if from[item]==0: from.erase(item)
	if returns_item: from[previous]=int(from.get(previous,0))+1
	if new_size > 0: _apply_compartment_size(personal, new_size, overflow, _inventory[source])
	loadout[slot]=item.trim_prefix("armor_") if slot=="armor" else item
	_revision+=1
	return {"ok":true,"loadout":loadout,"message":"Ausruestung angelegt"}

func _change_backpack(unit_id: String, source: String, item: String, context: Dictionary) -> Dictionary:
	var personal := "unit:" + unit_id + ":backpack"
	if not _inventory_access(personal, context) or not _inventory[personal].has("armor_chip_capacity"):
		return _reject("inventory_access", "Rucksackslot ist hier nicht verfügbar")
	if item not in ["backpack", "none"]:
		return _reject("incompatible_slot", "Gegenstand passt nicht in den Rucksackslot")
	var bag: Dictionary = _inventory[personal]
	var wearing := int(bag.capacity) > 0
	var removing := item == "none"
	if wearing != removing:
		return _reject("equipment_unchanged", "Kein Rucksack angelegt" if removing else "Ein Rucksack ist bereits angelegt")
	var storage: Dictionary = _inventory[source]
	var stock: Dictionary = storage.items
	if removing:
		if INVENTORY.backpack_slots_used(bag) > 0:
			return _reject("backpack_not_empty", "Rucksack vor dem Ablegen leeren")
		if source == personal or not INVENTORY.has_space(storage, "backpack", 1):
			return _reject("container_full", "Kein Platz für den abgelegten Rucksack")
		stock["backpack"] = int(stock.get("backpack", 0)) + 1
		bag.capacity = 0
	else:
		var count := int(stock.get("backpack", 0))
		if count < 1:
			return _reject("insufficient_items", "Rucksack nicht vorhanden")
		if count == 1:
			stock.erase("backpack")
		else:
			stock["backpack"] = count - 1
		bag.capacity = INVENTORY.BACKPACK_CAPACITY
	_revision += 1
	return {"ok": true, "loadout": Dictionary(context.loadout).duplicate(true), "message": "Rucksack abgelegt" if removing else "Rucksack angelegt"}

func get_location_resources(location_id: String) -> RefCounted:
	return _location_resources.get(location_id)
func _export_resources() -> Dictionary:
	var data: Dictionary={}
	for place in _location_resources: data[place]=_location_resources[place].export_state()
	return data
func preview_resource_collection(location_id: String,site_id: String,unit_id: String) -> Dictionary:
	var owner: RefCounted=get_location_resources(location_id)
	var site: Dictionary=owner.get_site_snapshot(site_id) if owner!=null else {}
	if site.is_empty() or not bool(site.get("discovered",false)): return _reject("undiscovered","Noch nicht entdeckt")
	if int(site.remaining)<=0: return _reject("depleted","Bereits geborgen")
	var bag: Dictionary=_inventory.get("unit:"+unit_id+":backpack",{})
	if int(Dictionary(bag.get("items",{})).get(site.required_tool,0))<1: return _reject("tool_missing","Miningwerkzeug fehlt" if site.required_tool=="mining_tool" else "Bergungswerkzeug fehlt")
	if not INVENTORY.has_space(bag, String(site.item_id), int(site.remaining)):
		return _reject("container_full", "Rucksack voll – am Schiff umladen")
	return {"ok":true}
func _collect_resource(payload: Dictionary,context: Dictionary) -> Dictionary:
	var place:=String(payload.get("location_id","")); var id:=String(payload.get("site_id","")); var unit:=String(payload.get("unit_id",""))
	if context.get("resource_authorized")!=true or context.get("unit_id")!=unit or context.get("location_id")!=place or context.get("use_complete")!=true or context.get("within_radius")!=true: return _reject("resource_authority","Entnahme muss lokal abgeschlossen werden")
	var gate:=preview_resource_collection(place,id,unit)
	if not gate.get("ok",false): return gate
	var owner: RefCounted=get_location_resources(place); var site: Dictionary=owner.get_site_snapshot(id)
	var bag: Dictionary=_inventory["unit:"+unit+":backpack"].items
	bag[site.item_id]=int(bag.get(site.item_id,0))+int(site.remaining)
	var quantity:=int(site.remaining); owner.consume(id); _revision+=1
	return {"ok":true,"item_id":site.item_id,"quantity":quantity,"message":"Geborgen: %d" % quantity}

func _compatible_definitions(saved: Dictionary,current: Dictionary) -> bool:
	var left := saved.duplicate(true)
	var right := current.duplicate(true)
	var old_offers: Variant = left.get("offers")
	if typeof(old_offers) != TYPE_DICTIONARY: return false
	for id: String in Dictionary(right.get("offers", {})):
		if not old_offers.has(id) and id not in ["mining_tool_supply","salvage_tool_supply","backpack_supply"] and not id.begins_with("polisa_"): return false
	for id in old_offers:
		if not Dictionary(right.get("offers", {})).has(id) or JSON.stringify(old_offers[id], "", true) != JSON.stringify(right.offers[id], "", true): return false
	left.erase("offers"); right.erase("offers")
	# Additive station data preserves the exact old economy and existing routes.
	if not Dictionary(left.get("service_locations", {})).has("polisa"):
		right.service_locations.erase("polisa")
	for route: String in Dictionary(right.get("route_fuel_costs", {})).keys():
		if route.contains("polisa") and not Dictionary(left.get("route_fuel_costs", {})).has(route): right.route_fuel_costs.erase(route)
	if not left.has("commodity_buy_orders"): right.erase("commodity_buy_orders")
	# Etappenkosten (T1 Tanker, 21.11.2026) sind rein hinzugekommen: Staende davor kennen den Block nicht und bleiben ladbar.
	# Ein gespeicherter Block muss dagegen exakt dem aktuellen entsprechen (der strenge Vergleich unten).
	if not left.has("leg_fuel_costs"): right.erase("leg_fuel_costs")
	# Nottankdienst (T2): die Zahlen des Blocks emergency_fuel gelten nur fuer kuenftige Bestellungen; jede offene Bestellung traegt ihre
	# eigenen Zahlen im Beleg. Darum wird der Block beim Vergleich ignoriert (ein Stand ohne ihn laedt, ein Stand mit ihm laedt auch,
	# wenn die Zahlen spaeter neu abgestimmt werden).
	left.erase("emergency_fuel"); right.erase("emergency_fuel")
	# Schulden (K): Kreditrahmen und Zinsen gelten nur fuer kuenftige Buchungen; ein Stand ohne den Block laedt (alter Stand).
	left.erase("debt"); right.erase("debt")
	return JSON.stringify(left, "", true) == JSON.stringify(right, "", true)


func configure_start_inventory(mode: String) -> void:
	if mode != "campaign": return
	_item_quantities.clear()
	# Neue Kampagne: Die Personen starten im Raumanzug ohne Waffen; zwei Pistolen und ein Sanitätsgerät liegen im Lager,
	# keine leichte Rüstung (die kommt mit der Erwerbserlaubnis nach dem Satellitenauftrag).
	_item_quantities.merge({"pistol":2,"medictool":1})
	if _inventory.has("base:homebase"): _inventory["base:homebase"].items = _item_quantities
	_revision += 1

func configure_preset_supply(preset: Dictionary) -> void:
	_credits = int(preset.get("credits", 10000))
	var stock: Dictionary = Dictionary(preset.get("stock", {"armor_heavy":16,"armor_medium":16,"rifle":32,"medictool":8,"mining_tool":8,"salvage_tool":8}))
	_item_quantities.clear()
	_item_quantities.merge(stock)
	_inventory["base:homebase"].capacity = maxi(200, INVENTORY.used(stock)+64)
	_inventory["base:homebase"].items = _item_quantities
	_revision += 1


func receive_skirmish_equipment(item: String) -> Dictionary:
	if not INVENTORY.known(item) or not _inventory.has("base:homebase"):
		return _reject("invalid_item", "Gegenstand fehlt")
	var storage: Dictionary = _inventory["base:homebase"]
	if not INVENTORY.has_space(storage, item, 1):
		return _reject("container_full", "Das Basislager ist voll")
	storage.items[item] = int(storage.items.get(item, 0)) + 1
	_revision += 1
	return {"ok": true, "message": "Ausrüstung ins Basislager geliefert"}


func remove_skirmish_craft(craft_id: String) -> void:
	_fuel_by_craft_id.erase(craft_id)
	_inventory.erase("craft:" + craft_id)
	_revision += 1


func return_skirmish_person_equipment(unit_id: String, loadout: Dictionary) -> Dictionary:
	var storage: Dictionary = _inventory["base:homebase"]
	var bag_key := "unit:" + unit_id + ":backpack"
	var bag: Dictionary = _inventory.get(bag_key, {"items": {}, "capacity": 0})
	var returned: Dictionary = Dictionary(bag.items).duplicate()
	if int(bag.capacity) > 0:
		returned["backpack"] = int(returned.get("backpack", 0)) + 1
	for slot: String in ["armor", "weapon_1", "weapon_2"]:
		var item := INVENTORY.item_from_slot(slot, String(loadout.get(slot, "none")))
		if INVENTORY.known(item): returned[item] = int(returned.get(item, 0)) + 1
	if INVENTORY.used(storage.items) + INVENTORY.used(returned) > int(storage.capacity):
		return _reject("container_full", "Für die abgegebene Ausrüstung fehlt Lagerplatz")
	for item: String in returned:
		if INVENTORY.RESERVED_QUEST_ITEMS.has(item) and int(storage.items.get(item, 0)) + int(returned[item]) > 1:
			return _reject("duplicate_quest_cargo", "Auftragsfracht bereits im Lager")
	for item: String in returned:
		storage.items[item] = int(storage.items.get(item, 0)) + int(returned[item])
	_inventory.erase(bag_key)
	_revision += 1
	return {"ok": true}


## Reservemagazine einer Person im Gefecht (M4a): Fach und Rucksack liegen im selben Behaelter (`items`), also zaehlt beides.
func person_magazine_count(unit_id: String, ammo_class: String) -> int:
	var bag: Dictionary = _inventory.get("unit:" + unit_id + ":backpack", {})
	return maxi(0, int(Dictionary(bag.get("items", {})).get(ammo_class, 0)))

## Hat die Person einen eigenen Behaelter (Fach und Rucksack)? Ohne ihn fuehrt das Spiel keinen Bestand fuer sie: im Gefecht
## gilt sie dann wie ein Gegner als unbegrenzt versorgt (M4a Nachbesserung).
func person_has_container(unit_id: String) -> bool:
	return _inventory.has("unit:" + unit_id + ":backpack")

## Magazinmodus der Munition (nicht gespeichert, vom Adapter je Lauf gesetzt): nur dort zaehlt der Magazinvorrat der Person.
## Er gilt in Kampagne UND Skirmish (Startausstattung, Auffuellen von Hand). Ausserhalb (Mehrspieler, Testlagen ohne Kampagnenstand)
## haben alle Einheiten unbegrenzte Reserve wie die Gegner (nachladen muessen sie weiter, die Magazingroesse gilt weiter).
var _campaign_magazine_mode: bool = false

func set_campaign_magazine_mode(active: bool) -> void:
	_campaign_magazine_mode = active

## Fuehrt das Spiel fuer die Person einen Magazinvorrat, der im Gefecht zaehlt? Nur im Kampagnenmodus und mit eigenem Behaelter.
func person_has_magazine_store(unit_id: String) -> bool:
	return _campaign_magazine_mode and person_has_container(unit_id)

## Zieht ein Reservemagazin der Sorte ab (Nachladen im Gefecht); false, wenn die Person keines traegt. Das Magazin ist verbraucht.
func take_person_magazine(unit_id: String, ammo_class: String) -> bool:
	var bag: Dictionary = _inventory.get("unit:" + unit_id + ":backpack", {})
	if not INVENTORY.AMMO_RULES.is_ammo_item(ammo_class, INVENTORY.ammo_rules()) or person_magazine_count(unit_id, ammo_class) <= 0:
		return false
	var left: int = int(bag.items[ammo_class]) - 1
	if left <= 0:
		bag.items.erase(ammo_class)
	else:
		bag.items[ammo_class] = left
	_revision += 1
	return true

## ---- Startausstattung und Auffuellen (M4b) ----
## Waffen der Person (Kennungen); gesetzt vom SimulationRoot aus dem Loadout-Besitzer, ohne Auskunft bekommt niemand Magazine.
var _weapon_provider: Callable = Callable()
## Optionaler Merker im Stand: die Startausstattung mit Magazinen wurde gewaehrt (fehlt er, wird sie einmal nachgereicht).
var _ammo_start_granted: bool = false

func set_weapon_provider(provider: Callable) -> void:
	_weapon_provider = provider

## Magazinsorte der Person: die ihrer ersten Waffe mit Munitionsbedarf, sonst "".
func _ammo_class_of_person(unit_id: String) -> String:
	if not _weapon_provider.is_valid(): return ""
	for weapon_id in Array(_weapon_provider.call(unit_id)):
		var id := String(weapon_id)
		if id.is_empty() or id == "none": continue
		var weapon: Dictionary = AMMO_WEAPONS.get_weapon(id)
		if String(weapon.get("ammo_class", "")) != "" and int(weapon.get("magazine_size", 0)) > 0: return String(weapon.ammo_class)
	return ""

## Fuellt das Ruestungsfach der Personen (feste Reihenfolge: nach Kennung sortiert) mit Magazinen der Sorte ihrer Waffe.
## from_base=false: Startausstattung (die Magazine entstehen); true: aus dem Basislager, soweit der Vorrat reicht.
## Ergebnis {"added": Magazine, "short": Personen, deren Fach nicht voll wurde, "message": Meldetext oder ""}.
func fill_person_compartments(unit_ids: Array, from_base: bool) -> Dictionary:
	_sync_compartments()
	var ids: Array = unit_ids.duplicate()
	ids.sort()
	var base: Dictionary = _inventory.get("base:homebase", {})
	var added := 0
	var short := 0
	for id in ids:
		var key := "unit:" + String(id) + ":backpack"
		if not _inventory.has(key) or not Dictionary(_inventory[key]).has("armor_chip_capacity"): continue
		var item := _ammo_class_of_person(String(id))
		if item.is_empty(): continue
		var bag: Dictionary = _inventory[key]
		var give := maxi(0, int(bag.armor_chip_capacity) - INVENTORY.count_ammo(bag.items))
		if give <= 0: continue
		if from_base: give = mini(give, int(Dictionary(base.get("items", {})).get(item, 0)))
		while give > 0 and not _storage_accepts(bag, {item: give}): give -= 1
		var wanted := maxi(0, int(bag.armor_chip_capacity) - INVENTORY.count_ammo(bag.items))
		if give > 0:
			bag.items[item] = int(bag.items.get(item, 0)) + give
			if from_base:
				base.items[item] = int(base.items[item]) - give
				if int(base.items[item]) <= 0: base.items.erase(item)
			added += give
		if from_base and give < wanted: short += 1
	if added > 0: _revision += 1
	var parts: PackedStringArray = []
	if from_base and added > 0: parts.append("Munition aufgefüllt: %d %s." % [added, "Magazin" if added == 1 else "Magazine"])
	var short_text := ("Munition knapp: %d %s." % [short, "Fach blieb leer" if short == 1 else "Fächer blieben leer"]) if from_base and short > 0 else ""
	if not short_text.is_empty(): parts.append(short_text)
	return {"added": added, "short": short, "message": " ".join(parts), "short_message": short_text}

## M6b (B1): Wie viele der Personen haben ein LEERES Fach (gar kein Magazin, gleich welcher Sorte, in Fach oder Rucksack)? Nur lesen, nichts bewegen.
## Personen ohne Behaelter, ohne Fach oder ohne Waffe mit Munitionsbedarf zaehlen nicht.
func count_empty_compartments(unit_ids: Array) -> int:
	_sync_compartments()
	var empty := 0
	for id in unit_ids:
		var key := "unit:" + String(id) + ":backpack"
		if not _inventory.has(key) or not Dictionary(_inventory[key]).has("armor_chip_capacity"): continue
		if int(Dictionary(_inventory[key]).armor_chip_capacity) <= 0: continue
		var item := _ammo_class_of_person(String(id))
		if item.is_empty(): continue
		if INVENTORY.count_ammo(Dictionary(_inventory[key]).items) <= 0: empty += 1
	return empty

## Einmal je Spielstand: 16 leichte und 8 Gewehr-Magazine ins Basislager (Zahlen: ammo_rules.json start_base_stock, soweit sie
## ins Lager passen) und volle Faecher fuer die Personen. Gibt true zurueck, wenn jetzt gewaehrt wurde; mit dem Merker nie wieder.
func grant_ammo_start_if_missing(unit_ids: Array) -> bool:
	if _ammo_start_granted or not _inventory.has("base:homebase"): return false
	var base: Dictionary = _inventory["base:homebase"]
	var stock: Dictionary = INVENTORY.AMMO_RULES.start_base_stock(INVENTORY.ammo_rules())
	for item in stock:
		var amount := int(stock[item])
		while amount > 0 and not _storage_accepts(base, {item: amount}): amount -= 1
		if amount > 0: base.items[item] = int(base.items.get(item, 0)) + amount
	fill_person_compartments(unit_ids, false)
	_ammo_start_granted = true
	_revision += 1
	return true

## Neue (angeworbene) Person: volles Fach, aber nur wenn die Startausstattung dieses Standes schon gewaehrt ist.
func provision_new_person(unit_id: String) -> bool:
	if not _ammo_start_granted: return false
	return int(fill_person_compartments([unit_id], false).added) > 0

## Rucksack einer gefallenen Person: alles darin geht verloren (bleibt am Ort zurueck), ausser der Auftragsfracht
## (RESERVED_QUEST_ITEMS). Die kommt wie bei return_skirmish_person_equipment ins Basislager, damit kein Auftrag unloesbar wird;
## ist dort schon ein Stueck derselben Auftragsfracht, ist das Duplikat eines und wird verworfen (mehr als eines darf es nie geben).
func discard_person_equipment(unit_id: String) -> Dictionary:
	var bag_key := "unit:" + unit_id + ":backpack"
	if not _inventory.has(bag_key):
		return {"ok": true, "discarded": 0, "kept_quest_items": []}
	var storage: Dictionary = _inventory.get("base:homebase", {})
	var bag: Dictionary = _inventory[bag_key]
	var discarded := 0
	var kept: Array = []
	for item: String in Dictionary(bag.get("items", {})):
		var amount := int(bag.items[item])
		if INVENTORY.RESERVED_QUEST_ITEMS.has(item) and not storage.is_empty():
			var stored := int(storage.items.get(item, 0))
			var moved := maxi(0, mini(amount, 1 - stored))
			if moved > 0:
				storage.items[item] = stored + moved
				kept.append(item)
			discarded += amount - moved
		else:
			discarded += amount
	_inventory.erase(bag_key)
	_revision += 1
	return {"ok": true, "discarded": discarded, "kept_quest_items": kept}

func _blueprints() -> Array:
	var result: Array = []
	for receipt: Dictionary in _reward_receipts.values():
		var id := String(Dictionary(receipt.get("reward",{})).get("blueprint_id",""))
		if not id.is_empty() and not result.has(id): result.append(id)
	for id: String in _research_receipts:
		var node: Dictionary = RESEARCH.definitions().get("nodes", {}).get(id, {})
		var blueprint := String(node.get("blueprint_id", ""))
		if not blueprint.is_empty() and not result.has(blueprint): result.append(blueprint)
	return result

func _campaign_research(payload: Dictionary, context: Dictionary, request_id: String) -> Dictionary:
	if not bool(context.get("campaign_authorized", false)):
		return _reject("campaign_only", "Entwicklung gehört zur Kampagne")
	if not bool(context.get("at_home", false)):
		return _reject("home_required", "Entwicklung nur an der Heimatbasis")
	var id := String(payload.get("research_id", ""))
	var node: Dictionary = get_research_snapshot().nodes.get(id, {})
	if node.is_empty(): return _reject("unknown_research", "Entwicklung unbekannt")
	if bool(node.developed):
		return {"ok": true, "changed": false, "cost": 0, "research_id": id, "message": "Bereits entwickelt; keine weiteren Kosten"}
	if not bool(node.available): return _reject("research_locked", String(node.message))
	var receipt := {"schema_version": 1, "research_id": id, "request_id": request_id, "cost": int(node.cost)}
	_credits -= int(node.cost)
	_research_receipts[id] = receipt
	_revision += 1
	return {"ok": true, "changed": true, "cost": int(node.cost), "research_id": id,
		"development_receipt": receipt.duplicate(true), "message": "Entwicklung abgeschlossen. Einzelstücke jetzt in der Werkstatt herstellen."}

func _campaign_cargo(payload: Dictionary, context: Dictionary) -> Dictionary:
	if not bool(context.get("campaign_authorized",false)): return _reject("untrusted_cargo","Kein bestaetigter Bergungs-/Lieferbeleg")
	_sync_compartments()
	var container := String(payload.get("container_id",""))
	var item := String(payload.get("item_id",""))
	var raw: Variant = payload.get("amount",0)
	if not _inventory.has(container) or not INVENTORY.known(item) or typeof(raw) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(raw)) or float(raw)!=floor(float(raw)) or abs(float(raw))<1 or abs(float(raw))>1000000: return _reject("invalid_cargo","Fracht oder Container ungueltig")
	var amount := int(raw)
	var items: Dictionary = _inventory[container].items
	if int(items.get(item,0))+amount<0: return _reject("missing_cargo","Benoetigte Fracht fehlt")
	if INVENTORY.RESERVED_QUEST_ITEMS.has(item) and int(items.get(item, 0)) + amount > 1:
		return _reject("duplicate_quest_cargo", "Auftragsfracht bereits vorhanden")
	if amount > 0 and not INVENTORY.has_space(_inventory[container], item, amount):
		return _reject("container_full", "Kein freier Platz für Fracht")
	items[item]=int(items.get(item,0))+amount
	if items[item]==0: items.erase(item)
	_revision+=1
	return {"ok":true,"message":"Fracht bestaetigt","item_id":item,"amount":amount}

## Rezepte mit "free": true brauchen keine Erwerbserlaubnis (Munition, M3).
static func is_free_recipe(blueprint_id: String) -> bool:
	return bool(get_campaign_recipe(blueprint_id).get("free", false))

## Stueck je Herstellung; fehlt das Feld, gilt 1 (alle bisherigen Rezepte).
static func recipe_output_count(recipe: Dictionary) -> int:
	return int(recipe.get("output_count", 1))

func preview_campaign_fabrication(blueprint: String) -> Dictionary:
	# Inventory/credit projection only. The command still checks runtime home access.
	var recipe := get_campaign_recipe(blueprint)
	if recipe.is_empty() or not (_blueprints().has(blueprint) or is_free_recipe(blueprint)): return _reject("blueprint_locked","Erwerbserlaubnis noch nicht freigeschaltet")
	if not _inventory.has("base:homebase"): return _reject("inventory_access", "Basislager nicht verfügbar")
	if not INVENTORY.known(String(recipe.get("item", ""))) or not INVENTORY.positive_integer(recipe.get("cost", 0)) or not recipe.get("inputs", {}) is Dictionary or not INVENTORY.positive_integer(recipe.get("output_count", 1)):
		return _reject("invalid_recipe", "Herstellungsrezept ungültig")
	var count := recipe_output_count(recipe)
	var inputs: Dictionary = recipe.get("inputs", {})
	var after := INVENTORY.used(_item_quantities)
	for item: String in inputs:
		if not INVENTORY.known(item) or INVENTORY.RESERVED_QUEST_ITEMS.has(item) or not INVENTORY.positive_integer(inputs[item]): return _reject("invalid_recipe", "Materialrezept ungültig")
		if int(_item_quantities.get(item, 0)) < int(inputs[item]):
			return _reject("missing_materials", "Im Basislager fehlen: %d × %s" % [int(inputs[item]), RESEARCH.item_label(item)])
		after -= int(inputs[item])
	if _credits < int(recipe.cost): return _reject("insufficient_credits", "Credits reichen nicht")
	if after + count > int(_inventory["base:homebase"].capacity): return _reject("container_full", "Basislager voll")
	return {"ok":true, "recipe_id":blueprint, "item_id":recipe.item, "cost":int(recipe.cost), "inputs":inputs.duplicate(true), "output_count":count}

func _campaign_fabricate(payload: Dictionary, context: Dictionary) -> Dictionary:
	if not bool(context.get("at_home",false)): return _reject("home_required","Herstellung nur an der Heimatbasis")
	var blueprint := String(payload.get("blueprint_id",""))
	var quote := preview_campaign_fabrication(blueprint)
	if not quote.ok: return quote
	# All checks precede the first mutation. The one Supply owner commits everything.
	for item: String in quote.inputs:
		_item_quantities[item] -= int(quote.inputs[item])
		if _item_quantities[item] == 0: _item_quantities.erase(item)
	_credits -= int(quote.cost)
	_item_quantities[quote.item_id] = int(_item_quantities.get(quote.item_id,0)) + int(quote.output_count)
	_revision += 1
	var result := {"ok":true,"message":"Gegenstand hergestellt","item_id":quote.item_id}
	# Preserve legacy receipt shape; only material recipes need the new exact ledger.
	if not Dictionary(quote.inputs).is_empty():
		result.merge({"recipe_id":blueprint,"cost":quote.cost,"materials_consumed":quote.inputs.duplicate(true)})
	# Stueckzahl (M3): nur Rezepte mit mehr als einem Stueck schreiben sie in den Beleg; alte Belege bleiben gleich.
	if int(quote.output_count) > 1:
		result["output_count"] = int(quote.output_count)
	return result

func _valid_campaign_fabrication_requests(requests: Dictionary) -> bool:
	for request: Dictionary in requests.values():
		var signature: Variant = JSON.parse_string(String(request.get("signature", "{}")))
		if not signature is Dictionary or signature.get("operation") != "campaign_fabricate": continue
		var id := String(Dictionary(signature.get("payload", {})).get("blueprint_id", ""))
		var recipe := get_campaign_recipe(id)
		var receipt: Dictionary = request.get("result", {})
		if recipe.is_empty() or receipt.get("item_id") != recipe.get("item"): return false
		# Stueckzahl (M3): ein Rezept mit mehr als einem Stueck verlangt sie im Beleg; sonst darf der Beleg keine andere als 1 tragen.
		var count := recipe_output_count(recipe)
		if (count > 1 and int(receipt.get("output_count", 0)) != count) or (count == 1 and receipt.has("output_count")): return false
		var inputs: Dictionary = recipe.get("inputs", {})
		if not inputs.is_empty():
			if receipt.get("recipe_id") != id or receipt.get("cost") != recipe.cost or receipt.get("materials_consumed") != inputs: return false
		elif receipt.has("recipe_id") or receipt.has("materials_consumed"):
			return false # New material fields cannot be relabelled as a legacy recipe.
	return true

func _campaign_build(_payload: Dictionary, context: Dictionary) -> Dictionary:
	if not bool(context.get("campaign_authorized",false)) or not bool(context.get("at_home",false)): return _reject("home_required","Ausbau nur an der Heimatbasis")
	if _credits<100: return _reject("insufficient_credits","Landepad kostet 100 Credits")
	_credits-=100; _revision+=1
	return {"ok":true,"message":"Landepad gebaut"}

func get_credits() -> int:
	return _credits

## Notrettung nach einem Totalverlust: bucht hoechstens das vorhandene Guthaben ab, das Guthaben wird nie negativ.
## Gibt die tatsaechlich abgezogene Summe zurueck.
func charge_credits_capped(amount: int) -> Dictionary:
	if amount < 0:
		return _reject("invalid_amount", "Betrag darf nicht negativ sein")
	var charged: int = mini(amount, maxi(_credits, 0))
	if charged > 0:
		_credits -= charged
		_revision += 1
	return {"ok": true, "charged": charged, "credits": _credits}

# --- Schulden (Abschnitt K, 22.11.2026) -------------------------------------------------------------------------------
# Credits duerfen negativ sein. Nur zwei Wege fuehren unter null: der Nottankdienst (_emergency_tanker_order, bis zum Kreditrahmen
# debt_limit) und die Rettungsgebuehr der Notrettung (charge_rescue_fee, ohne Rahmen). Jeder andere Kauf behaelt "Preis <= Credits".
# Solange die Credits negativ sind, laeuft die Zinsuhr (advance_debt_clock); alle Zahlen stehen im Block debt der Daten.

static func _debt_error(block: Variant) -> String:
	if typeof(block) != TYPE_DICTIONARY: return "Schulden: Block ungueltig"
	var number_ok := func(value: Variant) -> bool: return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) >= 0.0
	for key: String in ["debt_limit", "interest_min"]:
		var value: Variant = block.get(key)
		if not number_ok.call(value) or float(value) != floorf(float(value)) or float(value) > 2147483647.0: return "Schulden: Wert ungueltig: " + key
	if not number_ok.call(block.get("interest_period_seconds")) or float(block.interest_period_seconds) <= 0.0: return "Schulden: Zinsperiode ungueltig"
	if not number_ok.call(block.get("interest_rate")) or float(block.interest_rate) <= 0.0 or float(block.interest_rate) > 1.0: return "Schulden: Zinssatz ungueltig"
	if typeof(block.get("balance_status")) != TYPE_STRING: return "Schulden: balance_status fehlt"
	return ""

## Vor einer Buchung, die unter null fuehren kann: stand das Konto im Plus, beginnt die Zinsuhr beim naechsten Minus von vorn.
func _debt_before_booking() -> void:
	if _credits >= 0: _debt_remaining = -1.0

## Rettungsgebuehr der Notrettung (E4): wird voll gebucht, auch wenn das Konto dadurch ins Minus faellt oder tiefer als der
## Kreditrahmen. Gibt die gebuchte Summe zurueck.
func charge_rescue_fee(amount: int) -> Dictionary:
	if amount < 0:
		return _reject("invalid_amount", "Betrag darf nicht negativ sein")
	if amount > 0:
		_debt_before_booking()
		_credits -= amount
		_revision += 1
	return {"ok": true, "charged": amount, "credits": _credits}

## Zinsen fuer einen Betrag im Minus: max(ceil(|Credits| x Satz), Mindestzins).
func debt_interest_for(credits: int) -> int:
	var debt: Dictionary = Dictionary(_definitions.get("debt", {}))
	if debt.is_empty() or credits >= 0: return 0
	# Das kleine Abziehen faengt Fliesskomma-Reste ab (3000 x 0,05 darf nie 151 geben).
	return maxi(int(ceil(float(-credits) * float(debt.interest_rate) - 0.000001)), int(debt.interest_min))

## Die Zinsuhr. delta in Sekunden (der Aufrufer deckelt je Frame). Steht das Konto im Plus, steht die Uhr (volle Periode beim naechsten
## Minus). Je volle Periode im Minus wird eine Zinsbuchung abgezogen; Zinsen duerfen ueber den Kreditrahmen hinausfuehren; Zins auf Zins.
## Gibt die Buchungen dieses Aufrufs zurueck: charges = [{amount, credits}] (credits = Stand nach der Buchung).
func advance_debt_clock(delta: float) -> Dictionary:
	var charges: Array = []
	var debt: Dictionary = Dictionary(_definitions.get("debt", {}))
	if debt.is_empty() or not is_finite(delta) or delta < 0.0: return {"ok": true, "charges": charges, "credits": _credits}
	if _credits >= 0:
		_debt_remaining = -1.0
		return {"ok": true, "charges": charges, "credits": _credits}
	var period: float = float(debt.interest_period_seconds)
	if _debt_remaining < 0.0: _debt_remaining = period
	_debt_remaining -= delta
	while _debt_remaining <= 0.000001 and _credits < 0:
		var interest: int = debt_interest_for(_credits)
		_credits -= interest
		_revision += 1
		_debt_remaining += period
		charges.append({"amount": interest, "credits": _credits})
	return {"ok": true, "charges": charges, "credits": _credits}

## Restzeit bis zur naechsten Zinsbuchung (Sekunden) oder -1, wenn die Uhr steht (Konto im Plus).
func get_debt_interest_remaining() -> float:
	return _debt_remaining if _credits < 0 else -1.0

## Kreditrahmen aus dem Block debt (Abschnitt P, Pleite) oder 0, wenn die Daten keinen Block haben (dann gibt es keine Pleite).
func get_debt_limit() -> int:
	return int(Dictionary(_definitions.get("debt", {})).get("debt_limit", 0))

func get_modular_base() -> Dictionary:
	if _modular_plan_cache_revision != _revision:
		var replay: Dictionary = MODULAR.replay(_requests)
		_modular_plan_cache = Dictionary(replay.get("plan", MODULAR.empty())).duplicate(true)
		_modular_plan_cache_revision = _revision
	return _modular_plan_cache.duplicate(true)

func _campaign_build_modular(payload: Dictionary, context: Dictionary, is_bed: bool) -> Dictionary:
	if context.get("at_home") != true or context.get("campaign_authorized") != true:
		return _reject("modular_build_unavailable", "Bau nur in der Heimatbasis verfügbar")
	var replay: Dictionary = MODULAR.replay(_requests)
	if not replay.get("ok", false): return replay
	var plan: Dictionary = replay.plan
	var valid: Dictionary = MODULAR.validate_bed(plan, payload) if is_bed else MODULAR.validate_room(plan, payload)
	if not valid.get("ok", false): return valid
	var cost := MODULAR.BED_COST if is_bed else int(MODULAR.ROOM_COST[payload.type])
	if _credits < cost: return _reject("insufficient_credits", "Nicht genug Credits")
	var candidate: Dictionary = plan.duplicate(true)
	var result: Dictionary = {"ok":true,"sequence":int(replay.sequence)+1,"cost":cost}
	if is_bed:
		result["bed_id"] = "modular_bed_%04d" % (candidate.beds.size()+1)
		candidate.beds.append({"id":result.bed_id,"room_id":payload.room_id,"slot":int(payload.slot)})
	else:
		result["room_id"] = "room_%04d" % (candidate.rooms.size()+1)
		result["door_schema"] = 1
		MODULAR.append_room(candidate, {"id":result.room_id,"type":payload.type,"x":int(payload.x),"y":int(payload.y),"rotation":int(payload.rotation)}, true)
	var key := "modular_bed_validator" if is_bed else "modular_room_validator"
	var validator: Callable = context.get(key, Callable())
	if not validator.is_valid(): return _reject("modular_validator_unavailable", "Bauplatzprüfung nicht verfügbar")
	var placement: Variant = validator.call(candidate.duplicate(true))
	if typeof(placement) != TYPE_DICTIONARY or not bool(placement.get("ok", false)):
		return placement if typeof(placement) == TYPE_DICTIONARY else _reject("modular_site_invalid", "Bauplatz nicht verfügbar")
	if not is_bed and payload.type == "storage":
		if not _inventory.has("base:homebase"): return _reject("inventory_access", "Basislager nicht verfügbar")
		if _modular_capacity_baseline < 0: _modular_capacity_baseline = int(_inventory["base:homebase"].capacity)
		_inventory["base:homebase"].capacity = int(_inventory["base:homebase"].capacity) + MODULAR.STORAGE_CAPACITY
	_credits -= cost
	_revision += 1
	result["message"] = "Bett gebaut" if is_bed else "Raum gebaut"
	return result

func _campaign_set_room_door(payload: Dictionary, context: Dictionary) -> Dictionary:
	if context.get("at_home") != true or context.get("campaign_authorized") != true:
		return _reject("modular_build_unavailable", "Türbau nur in der Heimatbasis verfügbar")
	var replay: Dictionary = MODULAR.replay(_requests)
	if not replay.get("ok", false): return replay
	var plan: Dictionary = replay.plan
	var valid: Dictionary = MODULAR.validate_door(plan, payload)
	if not valid.get("ok", false): return valid
	var candidate := plan.duplicate(true)
	MODULAR.apply_door(candidate, payload)
	var validator: Callable = context.get("modular_room_validator", Callable())
	if not validator.is_valid(): return _reject("modular_validator_unavailable", "Türprüfung nicht verfügbar")
	var placement: Variant = validator.call(candidate.duplicate(true))
	if typeof(placement) != TYPE_DICTIONARY or not placement.get("ok", false):
		return placement if typeof(placement) == TYPE_DICTIONARY else _reject("modular_site_invalid", "Tür kann nicht geändert werden")
	_revision += 1
	return {"ok":true, "sequence":int(replay.sequence)+1, "cost":0, "room_id":payload.room_id, "side":int(payload.side), "open":bool(payload.open), "message":"Türöffnung gebaut" if payload.open else "Türöffnung entfernt"}

## Wohncontainer auf Hex-Boden: ein Kauf, vier Betten. Der Preis ist vorlaeufig.
const CONTAINER_HOUSING_COST := 1000
const CONTAINER_HOUSING_BEDS := 4
## Alte Unterkunft (verschobene Habitat-Kopie): 500 Credits, zwei Betten, Beleg ohne Bettenangabe.
const LEGACY_HOUSING_COST := 500
const LEGACY_HOUSING_BEDS := 2

## Betten je Gebaeude in der Reihenfolge der Gebaeudenummer. Beleg ohne Angabe = alte Unterkunft = 2.
func get_campaign_housing_beds() -> Array:
	var count := get_campaign_housing_count()
	var result: Array = []
	for index in range(count): result.append(LEGACY_HOUSING_BEDS)
	for entry: Dictionary in _requests.values():
		var receipt: Dictionary = entry.get("result", {})
		if receipt.get("operation") != "campaign_build_housing": continue
		var number := int(receipt.get("housing_count", 0))
		if number >= 1 and number <= count: result[number - 1] = int(receipt.get("beds", LEGACY_HOUSING_BEDS))
	# Hex-Basis: nur so viele Gebaeude, wie Stellplaetze existieren (Belege darueber bleiben gueltig, zaehlen aber nicht).
	if _housing_site_limit >= 0 and result.size() > _housing_site_limit: result = result.slice(0, _housing_site_limit)
	return result

## Laufzeit-Grenze (nicht gespeichert): Zahl der Gebaeude-Stellplaetze der Heimatbasis; -1 = unbegrenzt.
var _housing_site_limit := -1
func set_housing_site_limit(limit: int) -> void: _housing_site_limit = limit

func get_campaign_housing_count() -> int:
	var count := 0
	var legacy_beds := 2
	for entry: Dictionary in _requests.values():
		var result: Dictionary = entry.get("result", {})
		if result.get("operation") == "campaign_build_housing": count = maxi(count, int(result.get("housing_count", 0)))
		if result.get("operation") == "campaign_build_bed" and not result.has("housing_version"): legacy_beds = maxi(legacy_beds, int(result.get("bed_count", 2)))
	return maxi(count, ceili(float(legacy_beds - 2) / 2.0))

func _campaign_build_housing(payload: Dictionary, context: Dictionary) -> Dictionary:
	if not payload.is_empty(): return _reject("invalid_housing_request", "Ungültiger Bauauftrag")
	if context.get("campaign_authorized") != true or context.get("at_home") != true: return _reject("home_required", "Unterkunftsbau nur an der Heimatbasis")
	var count := get_campaign_housing_count()
	var container: bool = context.get("campaign_housing_container") == true
	if container:
		if count >= int(context.get("campaign_housing_limit", 0)): return _reject("housing_limit", "Kein freier Stellplatz für einen weiteren Wohncontainer")
		if _credits < CONTAINER_HOUSING_COST: return _reject("insufficient_credits", "Ein Wohncontainer kostet %d Credits" % CONTAINER_HOUSING_COST)
	else:
		if count >= 9: return _reject("housing_limit", "Alle Unterkunftsbauplätze sind belegt")
		if _credits < LEGACY_HOUSING_COST: return _reject("insufficient_credits", "Eine Unterkunft kostet 500 Credits")
	var builder: Callable = context.get("campaign_housing_builder", Callable())
	if not builder.is_valid(): return _reject("base_unavailable", "Bauplatz ist nicht verfügbar")
	var result: Dictionary = builder.call(count + 1)
	if not result.get("ok", false): return result
	if result.get("housing_count") != count + 1: return _reject("housing_build_mismatch", "Unterkunftsbau konnte nicht bestätigt werden")
	if container:
		_credits -= CONTAINER_HOUSING_COST; _revision += 1
		return {"ok":true,"housing_count":count + 1,"cost":CONTAINER_HOUSING_COST,"beds":CONTAINER_HOUSING_BEDS,"message":"Wohncontainer mit vier Betten gebaut"}
	_credits -= LEGACY_HOUSING_COST; _revision += 1
	return {"ok":true,"housing_count":count + 1,"cost":LEGACY_HOUSING_COST,"message":"Unterkunft gebaut"}

func get_campaign_bed_count() -> int:
	var count := 2
	for housing_beds in get_campaign_housing_beds(): count += int(housing_beds)
	var buildable := count
	for entry: Dictionary in _requests.values():
		var result: Dictionary = entry.get("result", {})
		if result.get("operation") == "campaign_build_bed": count = maxi(count, int(result.get("bed_count", 2)))
	# Nie mehr Betten melden, als auf den Stellplaetzen wirklich gebaut werden koennen.
	return mini(count, buildable) if _housing_site_limit >= 0 else count

func _campaign_build_bed(payload: Dictionary, context: Dictionary) -> Dictionary:
	if not payload.is_empty(): return _reject("invalid_bed_request", "Ungültiger Bauauftrag")
	if context.get("campaign_authorized") != true or context.get("at_home") != true: return _reject("home_required", "Bettbau nur an der Heimatbasis")
	var count := get_campaign_bed_count()
	if count >= 20: return _reject("bed_limit", "Die Bettenkapazität ist vollständig ausgebaut")
	if count >= 2 + 2 * get_campaign_housing_count(): return _reject("housing_required", "Zuerst eine weitere Unterkunft bauen")
	if _credits < 100: return _reject("insufficient_credits", "Ein weiteres Bett kostet 100 Credits")
	var builder: Callable = context.get("campaign_bed_builder", Callable())
	if not builder.is_valid(): return _reject("base_unavailable", "Bauplatz ist nicht verfügbar")
	var result: Dictionary = builder.call(count + 1)
	if not result.get("ok", false): return result
	if result.get("bed_count") != count + 1: return _reject("bed_build_mismatch", "Bettbau konnte nicht bestätigt werden")
	_credits -= 100
	_revision += 1
	return {"ok":true,"bed_count":count + 1,"cost":100,"housing_version":1,"message":"Zusätzliches Bett gebaut"}

func _valid_campaign_bed_requests(requests: Dictionary) -> bool:
	var counts: Array[int] = []
	var houses: Array[int] = []
	for entry: Dictionary in requests.values():
		var result: Dictionary = entry.get("result", {})
		if result.get("operation") == "campaign_build_housing":
			var housing_signature: Variant = JSON.parse_string(String(entry.get("signature", "")))
			if typeof(housing_signature) != TYPE_DICTIONARY or not Dictionary(housing_signature.get("payload", {})).is_empty(): return false
			if not _valid_nonnegative_integer(result.get("housing_count")): return false
			# Alter Beleg: 500 Credits ohne Bettenangabe. Neuer Beleg: 1000 Credits und genau vier Betten.
			var legacy_receipt: bool = result.get("cost") == LEGACY_HOUSING_COST and not result.has("beds")
			var container_receipt: bool = result.get("cost") == CONTAINER_HOUSING_COST and result.get("beds") == CONTAINER_HOUSING_BEDS
			if not legacy_receipt and not container_receipt: return false
			var house := int(result.housing_count)
			if house < 1 or house > 9 or houses.has(house): return false
			houses.append(house)
		if result.get("operation") != "campaign_build_bed": continue
		var signature: Variant = JSON.parse_string(String(entry.get("signature", "")))
		if typeof(signature) != TYPE_DICTIONARY or not Dictionary(signature.get("payload", {})).is_empty(): return false
		if not _valid_nonnegative_integer(result.get("bed_count")) or result.get("cost") != 100: return false
		var count := int(result.bed_count)
		if count < 3 or count > 20 or counts.has(count): return false
		counts.append(count)
	counts.sort()
	for i in range(counts.size()):
		if counts[i] != i + 3: return false
	return true

## Ankaufpreis des Haendlers am Ort (0 = kauft nicht). Die eine Preisquelle fuer _sell und get_sellable_proceeds.
## Handel H2: Preise stehen in data/singleplayer/commodity_market.json (buy_price); danach gilt der Block commodity_buy_orders
## der Handelsdaten (Polisa: Erz, Bergungsgut). Kein Preis steht fest im Code. Was ein Haendler selbst verkauft, kauft er nie.
func _commodity_price(location: String, item: String) -> int:
	var entry: Dictionary = Dictionary(Dictionary(_market.get(location, {})).get(item, {}))
	if entry.has("sell_price"): return 0
	if entry.has("buy_price"): return int(entry.buy_price)
	var orders: Dictionary = Dictionary(Dictionary(_definitions.get("commodity_buy_orders", {})).get(location, {}))
	return int(orders.get(item, 0))

## Prueft die Warenboerse und liefert {ok, market} mit ganzzahligen Preisen/Bestaenden; Fehler -> {ok:false, message}.
func _parse_market(raw: Variant) -> Dictionary:
	var out: Dictionary = {}
	if typeof(raw) != TYPE_DICTIONARY: return {"ok": false, "message": "Warenboerse fehlt"}
	var locations: Variant = Dictionary(raw).get("locations", {})
	if typeof(locations) != TYPE_DICTIONARY: return {"ok": false, "message": "Warenboerse: Orte fehlen"}
	for loc: Variant in locations:
		if typeof(locations[loc]) != TYPE_DICTIONARY: return {"ok": false, "message": "Warenboerse: Ort ungueltig"}
		var items: Dictionary = {}
		for item: Variant in locations[loc]:
			var e: Variant = locations[loc][item]
			if typeof(e) != TYPE_DICTIONARY or String(item).is_empty(): return {"ok": false, "message": "Warenboerse: Ware ungueltig"}
			var clean: Dictionary = {}
			if e.has("sell_price"):
				if not _valid_positive_integer(e.sell_price) or not _valid_nonnegative_integer(e.get("stock")): return {"ok": false, "message": "Warenboerse: Verkaufspreis oder Bestand ungueltig"}
				clean["sell_price"] = int(e.sell_price)
				clean["stock"] = int(e.stock)
			if e.has("buy_price"):
				if e.has("sell_price") or not _valid_positive_integer(e.buy_price): return {"ok": false, "message": "Warenboerse: Ankaufspreis ungueltig oder Ware wird zugleich verkauft"}
				clean["buy_price"] = int(e.buy_price)
			items[String(item)] = clean
		out[String(loc)] = items
	return {"ok": true, "market": out}

func _market_key(location: String, item: String) -> String:
	return location + ":" + item

## Voller Bestand aller Verkaufswaren laut Daten.
func _full_market_stock() -> Dictionary:
	var stock: Dictionary = {}
	for loc: String in _market:
		for item: String in Dictionary(_market[loc]):
			if Dictionary(_market[loc][item]).has("sell_price"): stock[_market_key(loc, item)] = int(_market[loc][item].stock)
	return stock

## Warenboerse fuer Anzeige und Tests: Ort -> Ware -> {sell_price, stock, buy_price} (nur die vorhandenen Schluessel).
func get_market_snapshot() -> Dictionary:
	var out: Dictionary = {}
	for loc: String in _market:
		var items: Dictionary = {}
		for item: String in Dictionary(_market[loc]):
			var e: Dictionary = Dictionary(_market[loc][item]).duplicate()
			if e.has("sell_price"): e["stock"] = int(_market_stock.get(_market_key(loc, item), 0))
			items[item] = e
		out[loc] = items
	return out

## Handel H2 (D4): sobald ein Schiff des Spielers an der Heimatbasis gelandet ist, steht jeder Marktbestand wieder auf dem Datenwert.
## Nur die Warenboerse; andere Angebote (stock_by_offer_id) bleiben. Liefert die Zahl nachgefuellter Stuecke.
func replenish_market_stock() -> int:
	var full: Dictionary = _full_market_stock()
	var added := 0
	for key: String in full:
		var missing: int = int(full[key]) - int(_market_stock.get(key, 0))
		if missing > 0: added += missing
	if added > 0:
		_market_stock = full
		_revision += 1
	return added

## Kauf bei der Warenboerse (Angebotskennung "market:<Ort>:<Ware>"): gleicher Warenweg wie _buy (Frachtaufzug oder Schiffslager).
func _buy_market(offer_id: String, payload: Dictionary, context: Dictionary) -> Dictionary:
	var parts: PackedStringArray = offer_id.split(":")
	if parts.size() != 3: return _reject("unknown_offer", "Angebot unbekannt")
	var location_id: String = String(context.get("location_id", ""))
	var item_id: String = parts[2]
	var entry: Dictionary = Dictionary(Dictionary(_market.get(parts[1], {})).get(item_id, {}))
	if not entry.has("sell_price"): return _reject("unknown_offer", "Angebot unbekannt")
	if bool(context.get("craft_busy", true)): return _reject("craft_busy", "Handel erst nach der Landung am Serviceort")
	if parts[1] != location_id or not _has_service(location_id, "trade"): return _reject("trade_unavailable", "Handel nur am Handelsservice")
	if not _valid_positive_integer(payload.get("quantity")): return _reject("invalid_quantity", "Menge muss eine positive ganze Zahl sein")
	var quantity: int = int(payload.quantity)
	var key: String = _market_key(location_id, item_id)
	if quantity > int(_market_stock.get(key, 0)): return _reject("insufficient_stock", "Angebotsmenge reicht nicht")
	var price: int = int(entry.sell_price)
	if quantity > _credits / price: return _reject("insufficient_credits", "Credits reichen nicht")
	var destination := String(context.get("cargo_lift_container_id", "station:polisa:lift")) if location_id in ["polisa", "trade_outpost"] and bool(context.get("cargo_lift_delivery", false)) else "craft:" + String(context.get("craft_id", ""))
	var purchased_items: Dictionary = _item_quantities
	if not _inventory.is_empty():
		if not _inventory.has(destination): return _reject("inventory_access", "Lieferziel fehlt")
		purchased_items = _inventory[destination].items
		if INVENTORY.used(purchased_items) + quantity > int(_inventory[destination].capacity): return _reject("container_full", "Schiffsfracht ist voll")
	_credits -= quantity * price
	_market_stock[key] = int(_market_stock[key]) - quantity
	purchased_items[item_id] = int(purchased_items.get(item_id, 0)) + quantity
	_revision += 1
	return {"ok": true, "item_id": item_id, "quantity": quantity, "cost": quantity * price, "container_id": destination if not _inventory.is_empty() else "base:homebase", "message": "Kauf bestaetigt"}

## Abschnitt P (Pleite, W1): was die Waren in den genannten Lagern (Schiffslager "craft:<id>", Frachtaufzug) beim Haendler am Ort
## zusammen braechten, mit den Regeln von _sell (Handelsdienst am Ort, Preis > 0, keine Auftragsgegenstaende). Nur lesend.
func get_sellable_proceeds(location_id: String, container_ids: Array) -> int:
	if not _has_service(location_id, "trade"): return 0
	var total := 0
	var seen: Dictionary = {}
	for raw_id: Variant in container_ids:
		var container := String(raw_id)
		if seen.has(container) or not _inventory.has(container): continue
		seen[container] = true
		var items: Dictionary = Dictionary(_inventory[container]).get("items", {})
		for item_id: Variant in items.keys():
			var item := String(item_id)
			var price := _commodity_price(location_id, item)
			if price > 0 and not INVENTORY.RESERVED_QUEST_ITEMS.has(item): total += int(items[item_id]) * price
	return total

func _sell(payload: Dictionary, context: Dictionary) -> Dictionary:
	var location := String(context.get("location_id",""))
	if not _has_service(location,"trade") or bool(context.get("craft_busy",true)): return _reject("trade_unavailable","Handel nicht erreichbar")
	var item := String(payload.get("item_id",""))
	var price := _commodity_price(location, item)
	var container := String(payload.get("source_container_id","craft:"+String(context.get("craft_id",""))))
	if container != "craft:"+String(context.get("craft_id","")) and container != String(context.get("cargo_lift_container_id","")): return _reject("inventory_access","Verkauf nur aus lokalem Schiff oder Frachtaufzug")
	if price <= 0 or INVENTORY.RESERVED_QUEST_ITEMS.has(item) or not _inventory.has(container) or not INVENTORY.positive_integer(payload.get("quantity",0)): return _reject("not_purchased","Dieser Haendler kauft diesen Rohstoff nicht")
	var quantity := int(payload.quantity)
	var items: Dictionary = _inventory[container].items
	if int(items.get(item,0))<quantity: return _reject("insufficient_items","Bestand reicht nicht")
	items[item]-=quantity
	if items[item]==0: items.erase(item)
	_credits+=quantity*price; _revision+=1
	return {"ok":true,"message":"Waren verkauft","item_id":item,"quantity":quantity,"proceeds":quantity*price}


func _reserve_station_recruit(payload: Dictionary, context: Dictionary) -> Dictionary:
	if context.get("station_service_verified", false) != true or context.get("location_id") != "polisa": return _reject("station_service_required", "Anwerbung nur auf Polisa")
	var quote_callback: Callable = context.get("recruit_quote", Callable())
	if not quote_callback.is_valid(): return _reject("recruit_unavailable", "Anwerbung nicht bereit")
	var offer_id := String(payload.get("offer_id", ""))
	var quote: Dictionary = quote_callback.call(offer_id)
	if not quote.get("ok", false): return quote
	var unit_id := String(quote.get("unit_id", ""))
	var profile: Variant = quote.get("profile")
	if offer_id.is_empty() or quote.get("offer_id") != offer_id or not unit_id.begins_with("polisa_recruit_") or typeof(profile) != TYPE_DICTIONARY or String(profile.get("unit_id", "")) != unit_id or not _valid_nonnegative_integer(quote.get("price")) or int(quote.price) < 1: return _reject("invalid_recruit_quote", "Angebot ungültig")
	for entry: Dictionary in _requests.values():
		var previous: Dictionary = entry.get("result", {})
		if previous.get("operation") == "station_recruit_reserve" and (previous.get("unit_id") == unit_id or previous.get("offer_id") == offer_id): return _reject("recruit_already_hired", "Person bereits angefragt")
	if _credits < int(quote.price): return _reject("insufficient_credits", "Credits reichen nicht")
	_credits -= int(quote.price)
	_revision += 1
	return {"ok":true,"state":"pending","unit_id":unit_id,"offer_id":offer_id,"cost":int(quote.price),"location_id":"polisa","profile":profile.duplicate(true)}

func get_recruit_reservation(request_id: String) -> Dictionary:
	var entry: Dictionary = _requests.get(request_id, {})
	var result: Dictionary = entry.get("result", {})
	return result.duplicate(true) if result.get("operation") == "station_recruit_reserve" else {}

func get_recruitment_records() -> Dictionary:
	var result := {}
	for entry: Dictionary in _requests.values():
		var receipt: Dictionary = entry.get("result", {})
		if receipt.get("operation") == "station_recruit_reserve": result[String(receipt.get("offer_id", ""))] = {"state":"pending","reservation_id":String(receipt.get("request_id", ""))}
	for entry: Dictionary in _requests.values():
		var receipt: Dictionary = entry.get("result", {})
		if receipt.get("operation") in ["station_recruit_finalize", "station_recruit_cancel"]:
			result[String(receipt.get("offer_id", ""))] = {"state":"hired" if receipt.get("operation") == "station_recruit_finalize" else "cancelled","reservation_id":String(receipt.get("reservation_id", ""))}
	return result

func has_pending_recruitments() -> bool:
	for record: Dictionary in get_recruitment_records().values():
		if record.get("state") == "pending": return true
	return false

func _finalize_station_recruit(payload: Dictionary, context: Dictionary) -> Dictionary:
	var reservation_id := String(payload.get("reservation_id", ""))
	var reserve: Dictionary = Dictionary(_requests.get(reservation_id, {})).get("result", {})
	if reserve.get("operation") != "station_recruit_reserve" or reserve.get("state") != "pending": return _reject("reservation_missing", "Anwerbung nicht vorgemerkt")
	for entry: Dictionary in _requests.values():
		var previous: Dictionary = entry.get("result", {})
		if previous.get("operation") in ["station_recruit_finalize", "station_recruit_cancel"] and previous.get("reservation_id") == reservation_id: return _reject("recruit_already_hired", "Anwerbung bereits abgeschlossen")
	var verify: Callable = context.get("recruit_verify", Callable())
	if not verify.is_valid(): return _reject("recruit_unavailable", "Personenaufnahme nicht verfügbar")
	var evidence: Dictionary = verify.call(String(reserve.unit_id), reservation_id)
	if not evidence.get("ok", false): return _reject("admission_pending", "Personenaufnahme noch nicht bestätigt")
	_revision += 1
	return {"ok":true,"reservation_id":reservation_id,"unit_id":reserve.unit_id,"offer_id":reserve.offer_id,"cost":reserve.cost,"location_id":"polisa"}

func _cancel_station_recruit(payload: Dictionary, context: Dictionary) -> Dictionary:
	var reservation_id := String(payload.get("reservation_id", ""))
	var reserve: Dictionary = Dictionary(_requests.get(reservation_id, {})).get("result", {})
	if reserve.get("operation") != "station_recruit_reserve": return _reject("reservation_missing", "Anwerbung nicht vorgemerkt")
	for entry: Dictionary in _requests.values():
		var previous: Dictionary = entry.get("result", {})
		if previous.get("operation") in ["station_recruit_finalize", "station_recruit_cancel"] and previous.get("reservation_id") == reservation_id: return _reject("recruit_already_hired", "Anwerbung bereits abgeschlossen")
	var verify: Callable = context.get("recruit_cancel_verify", Callable())
	if not verify.is_valid() or not Dictionary(verify.call(String(reserve.unit_id), reservation_id)).get("ok", false): return _reject("admission_pending", "Aufnahme muss zuerst sicher beendet werden")
	_credits += int(reserve.cost)
	_revision += 1
	return {"ok":true,"reservation_id":reservation_id,"unit_id":reserve.unit_id,"offer_id":reserve.offer_id,"cost":reserve.cost,"location_id":"polisa"}

func _valid_recruit_requests(requests: Dictionary) -> bool:
	var seen_units := {}
	var seen_offers := {}
	var reservations := {}
	var finalizations := {}
	for request_id: String in requests:
		var entry: Dictionary = requests[request_id]
		var result: Dictionary = entry.get("result", {})
		var operation := String(result.get("operation", ""))
		if operation in ["station_recruit_finalize", "station_recruit_cancel"]:
			var reservation_id := String(result.get("reservation_id", ""))
			var final_signature: Variant = JSON.parse_string(String(entry.get("signature", "")))
			if reservation_id.is_empty() or finalizations.has(reservation_id) or typeof(final_signature) != TYPE_DICTIONARY or String(final_signature.get("payload", {}).get("reservation_id", "")) != reservation_id: return false
			finalizations[reservation_id] = result
			continue
		if operation != "station_recruit_reserve": continue
		var signature: Variant = JSON.parse_string(String(entry.get("signature", "")))
		var unit_id := String(result.get("unit_id", ""))
		var offer_id := String(result.get("offer_id", ""))
		if typeof(signature) != TYPE_DICTIONARY or String(signature.get("payload", {}).get("offer_id", "")) != offer_id or unit_id.is_empty() or offer_id.is_empty() or seen_units.has(unit_id) or seen_offers.has(offer_id) or result.get("location_id") != "polisa" or not _valid_nonnegative_integer(result.get("cost")) or int(result.cost) < 1: return false
		seen_units[unit_id] = true
		seen_offers[offer_id] = true
		if operation == "station_recruit_reserve":
			if result.get("state") != "pending" or typeof(result.get("profile")) != TYPE_DICTIONARY or String(result.profile.get("unit_id", "")) != unit_id: return false
			reservations[request_id] = result
	for reservation_id: String in finalizations:
		if not reservations.has(reservation_id): return false
		var reserve: Dictionary = reservations[reservation_id]
		var completed: Dictionary = finalizations[reservation_id]
		for field in ["unit_id", "offer_id", "cost", "location_id"]:
			if completed.get(field) != reserve.get(field): return false
	return true

func _station_buy_ship(payload: Dictionary, context: Dictionary, request_id: String) -> Dictionary:
	if String(context.get("location_id", "")) != "polisa" or bool(context.get("craft_busy", true)) or context.get("station_service_verified", false) != true:
		return _reject("station_service_required", "Schiffskauf erst nach dem Andocken in Polisa")
	var offer_id := String(payload.get("offer_id", ""))
	var offer: Dictionary = Dictionary(_definitions.get("offers", {})).get(offer_id, {})
	if String(offer.get("kind", "")) != "ship" or not Array(offer.get("location_ids", [])).has("polisa"):
		return _reject("unknown_offer", "Dieses Schiff wird hier nicht verkauft")
	var price := int(offer.get("unit_price", 0))
	if price <= 0 or _credits < price: return _reject("insufficient_credits", "Credits reichen nicht")
	if int(_stock_by_offer_id.get(offer_id, 0)) < 1: return _reject("insufficient_stock", "Schiff derzeit ausverkauft")
	var delivery_mode := String(payload.get("delivery_mode", "homebase"))
	if delivery_mode not in ["homebase", "local"]: return _reject("invalid_delivery_mode", "Lieferart ungültig")
	var fulfillment: Callable = context.get("station_local_ship_fulfillment" if delivery_mode == "local" else "station_ship_fulfillment", Callable())
	if not fulfillment.is_valid(): return _reject("fleet_unavailable", "Flottenübergabe nicht verfügbar")
	# All failure gates precede the callback's publication tail and wallet debit.
	var result: Dictionary = fulfillment.call(offer.duplicate(true), request_id, String(payload.get("requested_station_pad_id", ""))) if delivery_mode == "local" else fulfillment.call(offer.duplicate(true), request_id)
	if not bool(result.get("ok", false)): return result
	_credits -= price
	_stock_by_offer_id[offer_id] = int(_stock_by_offer_id[offer_id]) - 1
	_revision += 1
	result["cost"] = price
	result["offer_id"] = offer_id
	result["message"] = "Schiff gekauft / unbemannt auf Polisa bereit" if delivery_mode == "local" else "Schiff gekauft / Lieferung zur Heimatbasis bestaetigt"
	return result


func get_station_home_pads() -> int:
	var count := 2
	for receipt: Dictionary in _requests.values():
		var result: Dictionary = receipt.get("result", {})
		if result.get("operation", "") == "station_build_home_pad": count = maxi(count, int(result.get("home_pad_count", 2)))
	return mini(count, 6)


func _station_build_home_pad(context: Dictionary) -> Dictionary:
	if context.get("station_service_verified", false) != true or String(context.get("location_id", "")) != "polisa": return _reject("station_service_required", "Zuerst in Polisa andocken")
	if context.get("second_pad_built", false) != true: return _reject("base_progress_required", "Zuerst den zweiten Heimatlandeplatz in der Kampagne fertigstellen")
	var count := get_station_home_pads()
	if count >= 6: return _reject("pad_limit", "Alle sechs Heimatbauplaetze sind ausgebaut")
	if _credits < 200: return _reject("insufficient_credits", "Landeplatzbau kostet 200 Credits")
	var builder: Callable = context.get("station_pad_builder", Callable())
	if not builder.is_valid(): return _reject("base_unavailable", "Heimatbauplatz nicht verfuegbar")
	var result: Dictionary = builder.call(count + 1)
	if not result.get("ok", false): return result
	_credits -= 200
	_revision += 1
	return {"ok":true,"home_pad_count":count + 1,"cost":200,"message":"Heimatlandeplatz gebaut"}


func validate_station_receipts(requests: Dictionary) -> Dictionary:
	var pads: Array = []
	var ships := {}
	var used_pads: Array = []
	for request_id: String in requests:
		var receipt: Dictionary = requests[request_id]
		var result: Dictionary = receipt.get("result", {})
		var signature: Dictionary = JSON.parse_string(String(receipt.get("signature", "{}")))
		if result.get("operation", "") == "station_build_home_pad":
			if not _valid_nonnegative_integer(result.get("home_pad_count")): return _reject("invalid_station_pad_receipt", "Landeplatzanzahl ungueltig")
			var count := int(result.home_pad_count)
			if count < 3 or count > 6 or pads.has(count) or result.get("cost") != 200: return _reject("invalid_station_pad_receipt", "Landeplatzbeleg ungueltig")
			pads.append(count)
		elif result.get("operation", "") == "station_buy_ship":
			var offer_id := String(signature.get("payload", {}).get("offer_id", ""))
			var offer: Dictionary = Dictionary(_definitions.get("offers", {})).get(offer_id, {})
			var model := String(offer.get("model_id", ""))
			var id := "polisa_"+model+"_"+request_id.sha256_text().substr(0,12)
			var pad := String(result.get("landing_pad_id", ""))
			if offer.get("kind", "") != "ship" or model not in ["cutlass", "buccaneer"] or result.get("craft_id") != id or result.get("offer_id") != offer_id or result.get("cost") != offer.get("unit_price") or used_pads.has(pad) or pad not in ["homebase_pad_01", "homebase_pad_02", "homebase_pad_03", "homebase_pad_04", "homebase_pad_05", "homebase_pad_06"]: return _reject("invalid_station_ship_receipt", "Schiffskaufbeleg ungueltig")
			var mode := String(signature.get("payload", {}).get("delivery_mode", "homebase"))
			if mode not in ["homebase", "local"]: return _reject("invalid_station_ship_receipt", "Lieferart ungültig")
			var local_pad := String(result.get("acquisition_pad_id", ""))
			if mode == "local":
				if result.get("receipt_schema_version") != 2 or result.get("delivery_location_id") != "polisa" or result.get("origin_kind") != "local_station_purchase" or result.get("origin_location_id") != "polisa" or result.get("origin_receipt_id") != request_id or result.get("pad_fit_revision") != 1 or not STATION_CRAFT.receipt_pad_compatible(model, local_pad) or local_pad not in ["polisa_pad_01", "polisa_pad_02", "polisa_pad_03", "polisa_pad_04", "polisa_pad_05", "polisa_pad_06", "polisa_pad_07"]: return _reject("invalid_local_purchase_receipt", "Lokaler Erwerbsbeleg ungültig")
				var requested_pad := String(signature.get("payload", {}).get("requested_station_pad_id", ""))
				if not requested_pad.is_empty() and requested_pad != local_pad: return _reject("invalid_local_purchase_receipt", "Erwerbspad widerspricht Kaufauftrag")
			elif result.get("delivery_location_id") != "homebase" or result.has("origin_kind") or result.has("acquisition_pad_id") or result.has("receipt_schema_version"):
				return _reject("invalid_station_ship_receipt", "Heimatlieferbeleg ungültig")
			ships[id] = {"craft_id":id,"model_id":model,"craft_type":String(offer.craft_type),"pad":pad,"landing_pad_id":pad,"delivery_mode":mode,"delivery_location_id":"polisa" if mode == "local" else "homebase","acquisition_pad_id":local_pad,"origin_kind":"local_station_purchase" if mode == "local" else "home_delivery","origin_location_id":"polisa" if mode == "local" else "homebase","origin_receipt_id":request_id}
			used_pads.append(pad)
	pads.sort()
	for index in range(pads.size()):
		if pads[index] != index + 3: return _reject("invalid_station_pad_sequence", "Landeplatzbaubelege unvollstaendig")
	var capacity := 2 + pads.size()
	for ship: Dictionary in ships.values():
		if int(String(ship.pad).trim_prefix("homebase_pad_")) > capacity: return _reject("unbuilt_station_delivery_pad", "Lieferlandeplatz nicht gebaut")
	return {"ok":true,"capacity":capacity,"ships":ships}


func _install_ship_component(payload: Dictionary, context: Dictionary, request_id: String) -> Dictionary:
	if String(context.get("location_id", "")) != "polisa" or context.get("station_service_verified") != true or bool(context.get("craft_busy", true)): return _reject("station_service_required", "Warp-Einbau erst nach dem Andocken in Polisa")
	var craft_id := String(payload.get("craft_id", ""))
	var source := String(payload.get("source_container_id", ""))
	var item_id := String(payload.get("item_id", ""))
	var revision: Variant = payload.get("expected_equipment_revision")
	if not _fuel_by_craft_id.has(craft_id) or source != "craft:"+craft_id or not _inventory.has(source) or (not SHIP_COMPONENTS.known(item_id) and not SPACE_COMPONENTS.known(item_id)) or not _valid_nonnegative_integer(revision): return _reject("invalid_component_install", "Schiff, Komponente oder Lager ungültig")
	var prepare: Callable = context.get("prepare_ship_component_install", Callable())
	var commit: Callable = context.get("commit_ship_component_install", Callable())
	if not prepare.is_valid() or not commit.is_valid(): return _reject("equipment_unavailable", "Antriebswerkstatt nicht verbunden")
	var prepared: Dictionary = prepare.call(craft_id, String(payload.get("slot_id", "")), item_id, int(revision))
	if not prepared.get("ok", false): return prepared
	var previous := String(prepared.get("previous_item_id", ""))
	if not SHIP_COMPONENTS.known(previous) and not SPACE_COMPONENTS.known(previous): return _reject("invalid_component_install", "Ausgebaute Komponente unbekannt")
	var candidate: Dictionary = _inventory[source].duplicate(true)
	if int(candidate.items.get(item_id, 0)) < 1: return _reject("insufficient_items", "Gekaufter Antrieb fehlt im Schiffslager")
	candidate.items[item_id] -= 1
	if int(candidate.items[item_id]) == 0: candidate.items.erase(item_id)
	candidate.items[previous] = int(candidate.items.get(previous, 0)) + 1
	if not INVENTORY.valid_container(candidate): return _reject("container_full", "Ausgebauter Antrieb passt nicht ins Schiffslager")
	# Bound owner callback may reject without writing. After success only no-fail
	# candidate assignments follow, without signals, awaits or UI callbacks.
	var installed: Dictionary = commit.call(prepared, request_id)
	if not installed.get("ok", false): return installed
	_inventory[source] = candidate
	_revision += 1
	installed["source_container_id"] = source
	installed["cost"] = 0
	installed["message"] = "Komponente eingebaut / bisherige Komponente im Schiffslager verstaut"
	return installed

func _valid_component_requests(requests: Dictionary, stock: Dictionary = {}, definitions: Dictionary = {}) -> bool:
	var purchased := {}
	for id: String in requests:
		var entry: Dictionary = requests[id]
		var result: Dictionary = entry.get("result", {})
		var item_id := String(result.get("item_id", ""))
		if String(result.get("operation", "")) == "buy" and (SHIP_COMPONENTS.known(item_id) or SPACE_COMPONENTS.known(item_id)):
			var purchase: Variant = JSON.parse_string(String(entry.get("signature", "")))
			if typeof(purchase) != TYPE_DICTIONARY: return false
			var args: Dictionary = purchase.get("payload", {})
			var offer_id := String(args.get("offer_id", ""))
			var offer: Dictionary = Dictionary(definitions.get("offers", {})).get(offer_id, {})
			if offer.is_empty() or offer.get("item_id") != item_id or (offer_id != "polisa_warp_hemera" and offer_id != "polisa_component_" + item_id) or not _valid_positive_integer(args.get("quantity")) or result.get("quantity") != args.quantity or result.get("cost") != int(args.quantity)*int(offer.get("unit_price", 0)) or result.get("container_id") not in ["craft:"+String(args.get("craft_id", "")),"station:polisa:lift"]: return false
			purchased[offer_id] = int(purchased.get(offer_id, 0)) + int(args.quantity)
		if String(result.get("operation", "")) != "station_install_ship_component": continue
		var parsed: Variant = JSON.parse_string(String(entry.get("signature", "")))
		if typeof(parsed) != TYPE_DICTIONARY: return false
		var args: Dictionary = parsed.get("payload", {})
		for key in ["craft_id", "slot_id", "item_id", "source_container_id"]:
			if typeof(args.get(key)) != TYPE_STRING or result.get(key) != args[key]: return false
		var old_id := String(result.get("previous_item_id", ""))
		var known_pair: bool = (SHIP_COMPONENTS.known(args.item_id) and SHIP_COMPONENTS.known(old_id) and args.slot_id == "quantum_drive") or (SPACE_COMPONENTS.known(args.item_id) and SPACE_COMPONENTS.known(old_id) and args.slot_id != "quantum_drive")
		if not known_pair or args.source_container_id != "craft:"+String(args.craft_id) or args.item_id == old_id or not _valid_nonnegative_integer(args.get("expected_equipment_revision")) or result.get("previous_equipment_revision") != args.expected_equipment_revision or result.get("equipment_revision") != int(args.expected_equipment_revision)+1 or result.get("cost") != 0: return false
	for offer_id: String in purchased:
		if not stock.has(offer_id) or int(stock[offer_id]) != int(definitions.offers[offer_id].stock) - int(purchased[offer_id]): return false
	for offer_id: String in stock:
		if (offer_id == "polisa_warp_hemera" or offer_id.begins_with("polisa_component_")) and int(stock[offer_id]) != int(definitions.offers[offer_id].stock) - int(purchased.get(offer_id, 0)): return false
	return true


func get_station_ship_purchase(craft_id: String) -> Dictionary:
	# Derived immutable receipt projection; no second location/occupancy truth.
	if _station_purchase_cache_revision != _revision:
		var validated := validate_station_receipts(_requests)
		_station_purchase_cache = validated.get("ships", {}) if validated.get("ok", false) else {}
		_station_purchase_cache_revision = _revision
	return Dictionary(_station_purchase_cache.get(craft_id, {})).duplicate(true)


func _reset_route_fuel_preparation() -> void:
	_route_prepare_authority = null
	_route_prepare_bound = false
	_route_prepare_epoch += 1
	_route_prepare_seal_key = ""

func bind_route_fuel_preparation_authority(authority: Object) -> bool:
	if not is_instance_valid(authority): return false
	if _route_prepare_bound:
		return _route_prepare_authority != null and _route_prepare_authority.get_ref() == authority
	_route_prepare_authority = weakref(authority)
	_route_prepare_bound = true
	# No global RNG use: authority object identity is the access capability;
	# this private per-binding seal only protects prepared data from alteration.
	_route_prepare_seal_key = "%s:%s:%s" % [get_instance_id(), _route_prepare_epoch, Time.get_ticks_usec()]
	return true

func _has_route_fuel_authority(authority: Variant) -> bool:
	return typeof(authority) == TYPE_OBJECT and is_instance_valid(authority) and _route_prepare_bound and _route_prepare_authority != null and _route_prepare_authority.get_ref() == authority

func _route_fuel_input_fingerprint(command: Dictionary, flags: Dictionary) -> String:
	var payload: Dictionary = command.payload
	var craft_id := String(payload.get("craft_id", ""))
	var route := String(payload.get("origin_location_id", "")) + ">" + String(payload.get("destination_location_id", ""))
	var reverse := String(payload.get("destination_location_id", "")) + ">" + String(payload.get("origin_location_id", ""))
	var routes: Dictionary = _definitions.get("route_fuel_costs", {})
	var request_id := String(command.request_id).strip_edges()
	if String(command.get("operation", "")) == "consume_leg_fuel":
		var leg := String(payload.get("leg", ""))
		var leg_origin := String(payload.get("origin_location_id", ""))
		var leg_destination := String(payload.get("destination_location_id", ""))
		var leg_inputs := {"revision":_revision,"bind_epoch":_route_prepare_epoch,
			"craft_id":craft_id,"fuel_present":_fuel_by_craft_id.has(craft_id),"fuel":_fuel_by_craft_id.get(craft_id),
			"leg":leg,"route":route,"leg_cost":get_leg_fuel_cost(leg_origin, leg_destination, leg),
			"request_id":request_id,"receipt_present":_requests.has(request_id),"receipt":_requests.get(request_id)}
		return JSON.stringify(leg_inputs, "", true).sha256_text()
	var inputs := {"revision":_revision,"bind_epoch":_route_prepare_epoch,
		"craft_id":craft_id,"fuel_present":_fuel_by_craft_id.has(craft_id),"fuel":_fuel_by_craft_id.get(craft_id),
		"route":route,"route_present":routes.has(route),"route_cost":routes.get(route),
		"reserve_required":bool(flags.require_return_reserve),
		"request_id":request_id,"receipt_present":_requests.has(request_id),"receipt":_requests.get(request_id)}
	if bool(flags.require_return_reserve):
		inputs.merge({"reverse_route":reverse,"reverse_present":routes.has(reverse),"reverse_cost":routes.get(reverse)})
	# O(1) selected inputs: unrelated receipts, craft registrations, offers and
	# inventory configuration are not consumed by preview_route_fuel.
	return JSON.stringify(inputs, "", true).sha256_text()

func _sign_prepared_route_fuel(candidate: Dictionary) -> String:
	var content := candidate.duplicate(true)
	content.erase("seal")
	return (_route_prepare_seal_key + JSON.stringify(content, "", true)).sha256_text()

func prepare_route_fuel(command: Dictionary, trusted_context: Dictionary = {}) -> Dictionary:
	if not _has_route_fuel_authority(trusted_context.get("route_fuel_authority")):
		return _reject("route_preparation_authority_required", "Routenvorbereitung benötigt gebundene Laufzeitberechtigung")
	if not COMMANDS.validate_command(command) or _definitions.is_empty() or String(command.get("operation", "")) not in ["consume_route_fuel", "consume_leg_fuel"]: return _reject("invalid_command", "Nur Routen- oder Etappentreibstoff kann vorbereitet werden")
	var leg_command := String(command.operation) == "consume_leg_fuel"
	var request_id := String(command.request_id).strip_edges()
	var signature := JSON.stringify({"operation":command.operation,"payload":command.payload}, "", true)
	var mode := "apply"
	var result := {}
	if _requests.has(request_id):
		if String(_requests[request_id].signature) != signature: return _reject("request_id_conflict", "Anfrage-ID bereits anders verwendet")
		mode = "replay"
		result = Dictionary(_requests[request_id].result).duplicate(true)
		result["replayed"] = true
	var flags := {"departure_authorized":typeof(trusted_context.get("departure_authorized")) == TYPE_BOOL and trusted_context.get("departure_authorized") == true, "require_return_reserve":typeof(trusted_context.get("require_return_reserve", false)) == TYPE_BOOL and trusted_context.get("require_return_reserve", false) == true}
	if mode == "apply":
		if typeof(trusted_context.get("departure_authorized")) != TYPE_BOOL or typeof(trusted_context.get("require_return_reserve", false)) != TYPE_BOOL: return _reject("invalid_route_context", "Routenberechtigung ungültig")
		result = preview_leg_fuel(command.payload, flags) if leg_command else preview_route_fuel(command.payload, flags)
		if not result.get("ok", false): return result
		result["request_id"] = request_id
		result["operation"] = String(command.operation)
	var candidate := {"ok":true,"candidate_schema":1,"owner_id":get_instance_id(),"bind_epoch":_route_prepare_epoch,"expected_revision":_revision,"input_fingerprint":_route_fuel_input_fingerprint(command, flags),"command":command.duplicate(true),"flags":flags,"mode":mode,"result":result.duplicate(true)}
	if mode == "apply": candidate["fuel_after"] = maxf(float(_fuel_by_craft_id[String(command.payload.get("craft_id", ""))]) - float(result.fuel_cost), 0.0)
	candidate["seal"] = _sign_prepared_route_fuel(candidate)
	return candidate

func validate_prepared_route_fuel(candidate: Dictionary, authority: Object) -> Dictionary:
	if not _has_route_fuel_authority(authority): return _reject("route_preparation_authority_required", "Routenvorbereitung benötigt gebundene Laufzeitberechtigung")
	if candidate.get("ok") != true or candidate.get("candidate_schema") != 1 or candidate.get("owner_id") != get_instance_id() or candidate.get("bind_epoch") != _route_prepare_epoch or String(candidate.get("seal", "")) != _sign_prepared_route_fuel(candidate): return _reject("invalid_prepared_route", "Routenvorbereitung ungültig")
	if candidate.get("expected_revision") != _revision or String(candidate.get("input_fingerprint", "")) != _route_fuel_input_fingerprint(candidate.command, candidate.flags): return _reject("stale_prepared_route", "Versorgungsstand hat sich geändert")
	var cmd: Dictionary = candidate.command
	var result: Dictionary = Dictionary(candidate.result).duplicate(true)
	var patch := {"mode":String(candidate.mode),"result":result}
	if String(candidate.mode) == "apply":
		patch.merge({"craft_id":String(cmd.payload.get("craft_id", "")),"fuel_after":float(candidate.fuel_after),"request_id":String(cmd.request_id).strip_edges(),"receipt":{"signature":JSON.stringify({"operation":cmd.operation,"payload":cmd.payload}, "", true),"result":result.duplicate(true)}})
	# Detached validation output is the immutable-by-contract tail input. The
	# publisher never dereferences caller-mutatable candidate dictionaries.
	return {"ok":true,"patch":patch}

func commit_prepared_route_fuel(candidate: Dictionary, authority: Object) -> Dictionary:
	var validation := validate_prepared_route_fuel(candidate, authority)
	if not validation.get("ok", false): return validation
	return _publish_prepared_route_fuel(candidate, validation)

func _publish_prepared_route_fuel(_candidate: Dictionary, validation: Dictionary) -> Dictionary:
	# INTERNAL no-fail tail. Only a synchronous owning coordinator may pass a
	# fresh successful validation after checking ALL participating owners. No
	# intervening writes/reentry/await are permitted. Public callers use commit.
	var patch: Dictionary = validation.patch
	if String(patch.mode) == "apply":
		_fuel_by_craft_id[String(patch.craft_id)] = float(patch.fuel_after)
		_revision += 1
		_requests[String(patch.request_id)] = Dictionary(patch.receipt).duplicate(true)
	return Dictionary(patch.result).duplicate(true)

func _repair(payload:Dictionary,context:Dictionary)->Dictionary:
	var id:=String(payload.get("craft_id",""))
	var callback:Callable=context.get("repair_callback",Callable())
	if not _fuel_by_craft_id.has(id) or context.get("ground_service_verified",false)!=true or not Array(context.get("services",[])).has("repair") or not callback.is_valid():return _reject("repair_service_required","Lokaler Reparaturservice nicht bestätigt")
	var result:Dictionary=callback.call(id)
	if result.get("ok",false):_revision+=1
	return result

func get_revision()->int:
	return _revision
