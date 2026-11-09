extends SceneTree

var passed: int = 0
var failed: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var path := "res://scripts/core/singleplayer_supply_state.gd"
	_check(FileAccess.file_exists(path), "Persistent supply owner exists")
	if not FileAccess.file_exists(path):
		_finish()
		return
	var state = load(path).new()
	_check(state.configure(["craft1", "craft2"]).ok, "Supply definitions configure")
	var initial: Dictionary = state.get_supply_snapshot()
	_check(initial.credits > 0 and initial.fuel_by_craft_id.craft1 >= 40.0, "Starter values allow complete test round trip")
	var trade := {"location_id": "trade_outpost", "craft_busy": false}
	_check(not _apply(state, "buy", {"offer_id": "medictool_supply", "quantity": 0}, "zero", trade).ok, "Zero quantity rejected")
	_check(not _apply(state, "buy", {"offer_id": "medictool_supply", "quantity": 999999}, "rich", trade).ok, "Excess stock or insufficient funds rejected")
	_check(not _apply(state, "buy", {"offer_id": "invented", "quantity": 1}, "unknown", trade).ok, "Unknown offer rejected")
	_check(not _apply(state, "buy", {"offer_id": "medictool_supply", "quantity": 1}, "remote", {"location_id": "satellite_crash"}).ok, "Owner denies shop away from trading service")
	var buy: Dictionary = _apply(state, "buy", {"offer_id": "medictool_supply", "quantity": 1}, "buy", trade)
	_check(buy.ok, "One real item bought")
	var after: Dictionary = state.get_supply_snapshot()
	_check(after.item_quantities.medictool == 1 and after.credits < initial.credits, "Credits and actual item quantity atomically change")
	_check(_apply(state, "buy", {"offer_id": "medictool_supply", "quantity": 1}, "buy", trade).get("replayed", false), "Duplicate click replays receipt")
	_check(state.get_supply_snapshot() == after, "Replay changes no balances")
	_check(not _apply(state, "buy", {"offer_id": "medictool_supply", "quantity": 2}, "buy", trade).ok, "Same request ID cannot buy different quantity")
	_check(not _apply(state, "refuel", {"craft_id": "craft1", "amount": INF}, "infinite", trade).ok, "Infinite refuel rejected")
	_check(not _apply(state, "refuel", {"craft_id": "craft1", "amount": NAN}, "nan", trade).ok, "NaN refuel rejected")
	_check(not _apply(state, "refuel", {"craft_id": "missing", "amount": 1.0}, "unknowncraft", trade).ok, "Unknown craft rejected")
	_check(not _apply(state, "refuel", {"craft_id": "craft1", "amount": 1.0}, "busy", {"location_id": "homebase", "craft_busy": true}).ok, "In-flight craft cannot refuel")
	_check(not _apply(state, "consume_route_fuel", {"craft_id": "craft1", "origin_location_id": "homebase", "destination_location_id": "satellite_crash"}, "denied").ok, "Rejected departure consumes no fuel")
	var departure := {"departure_authorized": true}
	_check(_apply(state, "consume_route_fuel", {"craft_id": "craft1", "origin_location_id": "homebase", "destination_location_id": "satellite_crash"}, "depart", departure).ok, "Authorized flight charges fixed route cost")
	var flight_fuel: float = state.get_supply_snapshot().fuel_by_craft_id.craft1
	_check(flight_fuel < initial.fuel_by_craft_id.craft1, "Flight actually consumes fuel")
	_check(_apply(state, "consume_route_fuel", {"craft_id": "craft1", "origin_location_id": "homebase", "destination_location_id": "satellite_crash"}, "depart", departure).get("replayed", false), "Repeated departure charges once")
	_check(state.get_supply_snapshot().fuel_by_craft_id.craft1 == flight_fuel, "No second departure debit")
	_check(state.get_supply_snapshot().fuel_by_craft_id.craft2 == initial.fuel_by_craft_id.craft2, "Other craft fuel stays independent")
	_check(_apply(state, "refuel", {"craft_id": "craft1", "amount": 5.0}, "fuel", {"location_id": "homebase", "craft_busy": false}).ok, "Same supply supports homebase refuel")
	_check(not _apply(state, "refuel", {"craft_id": "craft1", "amount": 1000.0}, "overflow", trade).ok, "Overcapacity refuel rejects atomically")
	var before_reward: int = state.get_supply_snapshot().credits
	_check(not _apply(state, "apply_reward", {"completion_id": "fake", "credits": 9999}, "forged_reward").ok, "UI cannot invent reward")
	var receipt := {"completion_id": "satellite_recovery:completed", "job_id": "satellite_recovery", "reward": {"credits": 100}, "runtime_verified": true}
	_check(_apply(state, "apply_reward", {"completion_id": receipt.completion_id}, "reward", {"completion_receipt": receipt}).ok, "Verified campaign reward credits")
	_check(_apply(state, "apply_reward", {"completion_id": receipt.completion_id}, "reward2", {"completion_receipt": receipt}).ok, "Repeated completion receipt accepted idempotently")
	_check(state.get_supply_snapshot().credits == before_reward + 100, "Completion reward credits exactly once")
	var snapshot: Dictionary = state.get_supply_snapshot()
	snapshot.credits = -99
	_check(state.get_supply_snapshot().credits >= 0, "Returned snapshot cannot mutate owner")
	var full = load(path).new()
	full.configure(["craft1"])
	_check(full.register_craft("full", 100.0), "Full fuel craft registers")
	var unchanged: Dictionary = full.get_supply_snapshot()
	_check(not _apply(full, "refuel", {"craft_id": "full", "amount": 1.0}, "full", trade).ok and full.get_supply_snapshot() == unchanged, "Full fuel rejects without debit")
	for bad_quantity in [-1, 1.5, "1", true]:
		_check(not _apply(full, "buy", {"offer_id": "medictool_supply", "quantity": bad_quantity}, "bad_" + str(bad_quantity), trade).ok, "Invalid quantity type/value rejects: " + str(bad_quantity))
	_check(full.register_craft("empty", 0.0), "Empty craft registers")
	unchanged = full.get_supply_snapshot()
	_check(not _apply(full, "consume_route_fuel", {"craft_id": "empty", "origin_location_id": "homebase", "destination_location_id": "satellite_crash"}, "empty", departure).ok and full.get_supply_snapshot() == unchanged, "Insufficient flight fuel leaves all values unchanged")
	_check(_apply(full, "buy", {"offer_id": "medictool_supply", "quantity": 4}, "all_stock", trade).ok, "Finite stock can be purchased")
	unchanged = full.get_supply_snapshot()
	_check(not _apply(full, "buy", {"offer_id": "medictool_supply", "quantity": 1}, "soldout", trade).ok and full.get_supply_snapshot() == unchanged, "Sold-out offer cannot oversell")
	var poor = load(path).new()
	var definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/trade_offers.json"))
	definitions.initial_credits = 0
	poor.configure(["craft1"], definitions)
	unchanged = poor.get_supply_snapshot()
	_check(not _apply(poor, "buy", {"offer_id": "medictool_supply", "quantity": 1}, "poor", trade).ok and poor.get_supply_snapshot() == unchanged, "Insufficient credits never consume stock or mint items")
	_check(not _apply(poor, "refuel", {"craft_id": "craft1", "amount": 1.0}, "poor_fuel", trade).ok and poor.get_supply_snapshot() == unchanged, "Insufficient credits never add fuel")
	_finish()

func _apply(state, operation: String, payload: Dictionary, request_id: String, context: Dictionary = {}) -> Dictionary:
	return state.apply_command({"contract_category": "singleplayer_supply", "operation": operation, "payload": payload, "request_id": request_id}, context)

func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS: " + label)
	else:
		failed += 1
		printerr("FAIL: " + label)

func _finish() -> void:
	print("SUPPLY_RESULTS passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)
