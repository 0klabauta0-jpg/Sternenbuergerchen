extends RefCounted
## Long-lived domain owner. SimulationRoot supplies trusted service/runtime context.

const COMMANDS: GDScript = preload("res://scripts/mission/singleplayer_supply_command_contract.gd")
const RESEARCH = preload("res://scripts/mission/campaign_research_catalog.gd")
const INVENTORY = preload("res://scripts/mission/inventory_transfer_contract.gd")
var _inventory: Dictionary = {}
var _location_resources: Dictionary = {}

const DATA_PATH := "res://data/singleplayer/trade_offers.json"
const CAMPAIGN_RECIPES:Dictionary={"light_armor":{"item":"armor_light","cost":20},"mining_tool":{"item":"mining_tool","cost":30},"assault_rifle":{"item":"rifle","cost":60}}

static func get_campaign_recipe(blueprint_id:String)->Dictionary:
	return Dictionary(CAMPAIGN_RECIPES[blueprint_id]).duplicate(true) if CAMPAIGN_RECIPES.has(blueprint_id) else RESEARCH.fabrication(blueprint_id)

var _definitions: Dictionary = {}
var _credits: int = 0
var _item_quantities: Dictionary = {}
var _fuel_by_craft_id: Dictionary = {}
var _stock_by_offer_id: Dictionary = {}
var _requests: Dictionary = {}
var _reward_receipts: Dictionary = {}
var _research_receipts: Dictionary = {}
var _research_snapshot_cache: Dictionary = {}
var _research_snapshot_revision := -1
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
	_inventory.clear()
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
	return {"credits": _credits, "item_quantities": _item_quantities.duplicate(true), "fuel_by_craft_id": _fuel_by_craft_id.duplicate(true), "stock_by_offer_id": _stock_by_offer_id.duplicate(true), "offers": Dictionary(_definitions.get("offers", {})).duplicate(true), "fuel_capacity": float(_definitions.get("fuel_capacity", 0.0)), "fuel_price_per_unit": float(_definitions.get("fuel_price_per_unit", 0.0)), "route_fuel_costs": Dictionary(_definitions.get("route_fuel_costs", {})).duplicate(true), "reward_completion_ids": _reward_receipts.keys().duplicate(), "revision": _revision, "inventory": _inventory.duplicate(true), "blueprints": _blueprints(), "research": get_research_snapshot(), "commodity_buy_orders": _definitions.get("commodity_buy_orders", {}).duplicate(true), "station_home_pads": get_station_home_pads()}

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
		"inventory_transfer": result = _inventory_transfer(payload, authority_context)
		"inventory_equip": result = _inventory_equip(payload, authority_context)
		"buy": result = _buy(payload, authority_context)
		"station_buy_ship": result = _station_buy_ship(payload, authority_context, request_id)
		"station_build_home_pad": result = _station_build_home_pad(authority_context)
		"refuel": result = _refuel(payload, authority_context)
		"consume_route_fuel": result = _consume_route(payload, authority_context)
		"apply_reward": result = _reward(payload, authority_context)
		"campaign_cargo": result = _campaign_cargo(payload, authority_context)
		"campaign_research": result = _campaign_research(payload, authority_context, request_id)
		"campaign_fabricate": result = _campaign_fabricate(payload, authority_context)
		"campaign_build": result = _campaign_build(payload, authority_context)
		"sell": result = _sell(payload, authority_context)
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
	if String(offer.get("kind", "")) == "ship":
		return _reject("ship_service_required", "Schiffe beim Schiffshaendler kaufen")
	var blueprint := String(offer.get("required_blueprint", ""))
	if bool(context.get("require_blueprints", false)) and not blueprint.is_empty() and not _blueprints().has(blueprint):
		return _reject("blueprint_locked", "Zuerst den passenden Bauplan freischalten")
	if bool(context.get("craft_busy", true)):
		return _reject("craft_busy", "Handel erst nach der Landung am Serviceort")
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
	var destination := "craft:"+String(context.get("craft_id",""))
	var purchased_items: Dictionary = _item_quantities
	if not _inventory.is_empty():
		if not _inventory.has(destination): return _reject("inventory_access","Lieferziel fehlt")
		purchased_items=_inventory[destination].items
		if INVENTORY.used(purchased_items)+quantity>int(_inventory[destination].capacity): return _reject("container_full","Schiffsfracht ist voll")
	_credits -= quantity * price
	_stock_by_offer_id[offer_id] = int(_stock_by_offer_id[offer_id]) - quantity
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
	var route: String = String(payload.get("origin_location_id", "")) + ">" + String(payload.get("destination_location_id", ""))
	var routes: Dictionary = _definitions.get("route_fuel_costs", {})
	if not routes.has(route):
		return _reject("unknown_route", "Ortsverbindung unbekannt")
	var cost: float = float(routes[route])
	var fuel: float = float(_fuel_by_craft_id[craft_id])
	if fuel + 0.00001 < cost:
		return _reject("insufficient_fuel", "Treibstoff reicht fuer diese Strecke nicht")
	if bool(context.get("require_return_reserve", false)):
		var reverse: String = String(payload.get("destination_location_id", "")) + ">" + String(payload.get("origin_location_id", ""))
		if not routes.has(reverse):
			return _reject("return_route_unavailable", "Fuer dieses Ziel fehlt eine bestaetigte Rueckflugstrecke")
		if fuel + 0.00001 < cost + float(routes[reverse]):
			return _reject("insufficient_return_fuel", "Treibstoff muss fuer Hin- und Rueckflug reichen; zuerst auftanken")
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

func export_state() -> Dictionary:
	return {"schema_version":1,"definitions":_definitions.duplicate(true),"credits":_credits,"item_quantities":_item_quantities.duplicate(true),"fuel_by_craft_id":_fuel_by_craft_id.duplicate(true),"stock_by_offer_id":_stock_by_offer_id.duplicate(true),"requests":_requests.duplicate(true),"reward_receipts":_reward_receipts.duplicate(true),"revision":_revision,"inventory":_inventory.duplicate(true),"location_resources":_export_resources(),"research_receipts":_research_receipts.duplicate(true)}

func restore_state(data: Dictionary) -> Dictionary:
	var fresh = get_script().new()
	if not fresh.configure().get("ok", false):
		return _reject("invalid_supply_data", "Aktuelle Versorgungsdaten fehlen")
	if data.get("schema_version") != 1 or not _valid_nonnegative_integer(data.get("credits")) or not _valid_nonnegative_integer(data.get("revision")):
		return _reject("invalid_supply_state", "Versorgungsstand ungueltig")
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
		if not (String(id) == "base:homebase" or String(id).begins_with("craft:") or personal) or not INVENTORY.valid_container(container):
			return _reject("invalid_inventory", "Container ungueltig")
		if not personal and container.has("armor_chip_capacity"):
			return _reject("invalid_inventory", "Rüstungsplatz gehört zu einer Person")
	if containers.has("base:homebase") and Dictionary(containers["base:homebase"].items)!=Dictionary(data.item_quantities):
		return _reject("invalid_inventory", "Basislager widerspricht Kaufbestand")
	var resources: Variant=data.get("location_resources",{})
	if typeof(resources)!=TYPE_DICTIONARY: return _reject("invalid_resources","Ortsressourcen ungueltig")
	for place in resources:
		if not fresh._location_resources.has(place) or typeof(resources[place])!=TYPE_DICTIONARY or not fresh._location_resources[place].restore_state(resources[place]): return _reject("invalid_resources","Ortsressourcen ungueltig")
	_location_resources=fresh._location_resources
	_definitions = fresh._definitions.duplicate(true)
	_credits = int(data.credits)
	_item_quantities = data.item_quantities.duplicate(true)
	_inventory = containers.duplicate(true)
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
	_revision = int(data.revision)
	return {"ok":true}

func configure_inventory(unit_ids: Array, craft_ids: Array, campaign_personnel: bool = false) -> void:
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
			_inventory[key] = {"capacity": 0 if campaign_personnel else INVENTORY.BACKPACK_CAPACITY, "items": {}}
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

func _inventory_access(id: String, context: Dictionary) -> bool:
	return _inventory.has(id) and Array(context.get("accessible_containers",[])).has(id)

func _inventory_transfer(payload: Dictionary, context: Dictionary) -> Dictionary:
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
	if not unequip:
		from[item]=int(from[item])-1
		if from[item]==0: from.erase(item)
	if returns_item: from[previous]=int(from.get(previous,0))+1
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
	return JSON.stringify(left, "", true) == JSON.stringify(right, "", true)


func configure_start_inventory(mode: String) -> void:
	if mode != "campaign": return
	_item_quantities.clear()
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

func preview_campaign_fabrication(blueprint: String) -> Dictionary:
	# Inventory/credit projection only. The command still checks runtime home access.
	var recipe := get_campaign_recipe(blueprint)
	if not _blueprints().has(blueprint) or recipe.is_empty(): return _reject("blueprint_locked","Blueprint noch nicht freigeschaltet")
	if not _inventory.has("base:homebase"): return _reject("inventory_access", "Basislager nicht verfügbar")
	if not INVENTORY.known(String(recipe.get("item", ""))) or not INVENTORY.positive_integer(recipe.get("cost", 0)) or not recipe.get("inputs", {}) is Dictionary:
		return _reject("invalid_recipe", "Herstellungsrezept ungültig")
	var inputs: Dictionary = recipe.get("inputs", {})
	var after := INVENTORY.used(_item_quantities)
	for item: String in inputs:
		if not INVENTORY.known(item) or INVENTORY.RESERVED_QUEST_ITEMS.has(item) or not INVENTORY.positive_integer(inputs[item]): return _reject("invalid_recipe", "Materialrezept ungültig")
		if int(_item_quantities.get(item, 0)) < int(inputs[item]):
			return _reject("missing_materials", "Im Basislager fehlen: %d × %s" % [int(inputs[item]), RESEARCH.item_label(item)])
		after -= int(inputs[item])
	if _credits < int(recipe.cost): return _reject("insufficient_credits", "Credits reichen nicht")
	if after + 1 > int(_inventory["base:homebase"].capacity): return _reject("container_full", "Basislager voll")
	return {"ok":true, "recipe_id":blueprint, "item_id":recipe.item, "cost":int(recipe.cost), "inputs":inputs.duplicate(true)}

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
	_item_quantities[quote.item_id] = int(_item_quantities.get(quote.item_id,0)) + 1
	_revision += 1
	var result := {"ok":true,"message":"Gegenstand hergestellt","item_id":quote.item_id}
	# Preserve legacy receipt shape; only material recipes need the new exact ledger.
	if not Dictionary(quote.inputs).is_empty():
		result.merge({"recipe_id":blueprint,"cost":quote.cost,"materials_consumed":quote.inputs.duplicate(true)})
	return result

func _valid_campaign_fabrication_requests(requests: Dictionary) -> bool:
	for request: Dictionary in requests.values():
		var signature: Variant = JSON.parse_string(String(request.get("signature", "{}")))
		if not signature is Dictionary or signature.get("operation") != "campaign_fabricate": continue
		var id := String(Dictionary(signature.get("payload", {})).get("blueprint_id", ""))
		var recipe := get_campaign_recipe(id)
		var receipt: Dictionary = request.get("result", {})
		if recipe.is_empty() or receipt.get("item_id") != recipe.get("item"): return false
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

func _sell(payload: Dictionary, context: Dictionary) -> Dictionary:
	var location := String(context.get("location_id",""))
	if not _has_service(location,"trade") or bool(context.get("craft_busy",true)): return _reject("trade_unavailable","Handel nicht erreichbar")
	var wanted := "c_benit" if location=="satellite_crash" else "b_benit"
	var item := String(payload.get("item_id",""))
	var orders: Dictionary = Dictionary(_definitions.get("commodity_buy_orders", {})).get(location, {wanted:15})
	var price := int(orders.get(item, 0))
	var container := "craft:"+String(context.get("craft_id",""))
	if price <= 0 or INVENTORY.RESERVED_QUEST_ITEMS.has(item) or not _inventory.has(container) or not INVENTORY.positive_integer(payload.get("quantity",0)): return _reject("not_purchased","Dieser Haendler kauft diesen Rohstoff nicht")
	var quantity := int(payload.quantity)
	var items: Dictionary = _inventory[container].items
	if int(items.get(item,0))<quantity: return _reject("insufficient_items","Bestand reicht nicht")
	items[item]-=quantity
	if items[item]==0: items.erase(item)
	_credits+=quantity*price; _revision+=1
	return {"ok":true,"message":"Waren verkauft","item_id":item,"quantity":quantity,"proceeds":quantity*price}


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
	var fulfillment: Callable = context.get("station_ship_fulfillment", Callable())
	if not fulfillment.is_valid(): return _reject("fleet_unavailable", "Flottenuebergabe nicht verfuegbar")
	# The trusted runtime callback validates the free home pad before its first write.
	# No await or UI callback occurs between fulfillment and the wallet receipt.
	var result: Dictionary = fulfillment.call(offer.duplicate(true), request_id)
	if not bool(result.get("ok", false)): return result
	_credits -= price
	_stock_by_offer_id[offer_id] = int(_stock_by_offer_id[offer_id]) - 1
	_revision += 1
	result["cost"] = price
	result["offer_id"] = offer_id
	result["message"] = "Schiff gekauft / Lieferung zur Heimatbasis bestaetigt"
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
			if offer.get("kind", "") != "ship" or model not in ["cutlass", "buccaneer"] or result.get("craft_id") != id or result.get("offer_id") != offer_id or result.get("cost") != offer.get("unit_price") or result.get("delivery_location_id") != "homebase" or used_pads.has(pad) or pad not in ["homebase_pad_01", "homebase_pad_02", "homebase_pad_03", "homebase_pad_04", "homebase_pad_05", "homebase_pad_06"]: return _reject("invalid_station_ship_receipt", "Schiffskaufbeleg ungueltig")
			ships[id] = {"model_id":model,"craft_type":String(offer.craft_type),"pad":pad}
			used_pads.append(pad)
	pads.sort()
	for index in range(pads.size()):
		if pads[index] != index + 3: return _reject("invalid_station_pad_sequence", "Landeplatzbaubelege unvollstaendig")
	var capacity := 2 + pads.size()
	for ship: Dictionary in ships.values():
		if int(String(ship.pad).trim_prefix("homebase_pad_")) > capacity: return _reject("unbuilt_station_delivery_pad", "Lieferlandeplatz nicht gebaut")
	return {"ok":true,"capacity":capacity,"ships":ships}
