extends RefCounted
## Pure command construction; this contract never changes a balance.

const CATEGORY := "singleplayer_supply"
const OPERATIONS := ["buy", "refuel", "repair", "consume_route_fuel", "apply_reward", "inventory_transfer", "inventory_equip", "cargo_transfer_start", "campaign_cargo", "campaign_fabricate", "campaign_research", "campaign_build", "campaign_build_bed", "campaign_build_housing", "campaign_build_room", "campaign_place_room_bed", "campaign_set_room_door", "sell", "collect_resource", "station_buy_ship", "station_build_home_pad", "station_install_ship_component", "station_recruit_reserve", "station_recruit_finalize", "station_recruit_cancel"]

static func build_buy_command(offer_id: String, quantity: int, request_id: String) -> Dictionary:
	return build_command("buy", {"offer_id": offer_id, "quantity": quantity}, request_id)

static func build_refuel_command(craft_id: String, amount: float, request_id: String) -> Dictionary:
	return build_command("refuel", {"craft_id": craft_id, "amount": amount}, request_id)

static func build_command(operation: String, payload: Dictionary, request_id: String) -> Dictionary:
	if not OPERATIONS.has(operation) or request_id.strip_edges().is_empty():
		return {}
	return {"contract_category": CATEGORY, "operation": operation, "payload": payload.duplicate(true), "request_id": request_id.strip_edges()}

static func validate_command(command: Dictionary) -> bool:
	return String(command.get("contract_category", "")) == CATEGORY and OPERATIONS.has(String(command.get("operation", ""))) and typeof(command.get("payload")) == TYPE_DICTIONARY and _finite_payload(command.payload) and typeof(command.get("request_id")) == TYPE_STRING and not String(command.get("request_id", "")).strip_edges().is_empty()

static func _finite_payload(value: Variant) -> bool:
	if typeof(value) == TYPE_FLOAT:
		return is_finite(float(value))
	if typeof(value) == TYPE_DICTIONARY:
		for key in value:
			if typeof(key) != TYPE_STRING or not _finite_payload(value[key]):
				return false
	elif typeof(value) == TYPE_ARRAY:
		for item in value:
			if not _finite_payload(item):
				return false
	elif not typeof(value) in [TYPE_NIL, TYPE_STRING, TYPE_BOOL, TYPE_INT]:
		return false
	return true
