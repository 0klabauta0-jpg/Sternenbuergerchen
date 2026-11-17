extends SceneTree

var passed: int = 0
var failed: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var campaign = load("res://scripts/core/singleplayer_campaign_state.gd").new()
	var supply = load("res://scripts/core/singleplayer_supply_state.gd").new()
	campaign.configure()
	supply.configure(["craft1"])
	campaign.apply_command({"contract_category": "singleplayer_campaign", "operation": "accept_job", "payload": {"job_id": "satellite_recovery"}, "request_id": "accept"})
	var before_campaign: Dictionary = campaign.get_campaign_snapshot()
	var before_supply: Dictionary = supply.get_supply_snapshot()
	var departure := {"craft_id": "craft1", "origin_location_id": "homebase", "destination_location_id": "satellite_crash", "landing_pad_id": "homebase_pad_01", "job_id": "satellite_recovery"}
	var authority := {"departure_authorized": true}
	_check(campaign.has_method("validate_departure"), "Campaign exposes read-only departure validation")
	if campaign.has_method("validate_departure"):
		_check(campaign.validate_departure(departure, authority).ok, "Valid departure preflights")
		_check(campaign.get_campaign_snapshot() == before_campaign, "Campaign preview never binds craft or changes revision")
		var invalid: Dictionary = departure.duplicate()
		invalid.landing_pad_id = "invented"
		_check(not campaign.validate_departure(invalid, authority).ok, "Unknown origin pad rejects before fuel debit")
		invalid = departure.duplicate()
		invalid.destination_location_id = "trade_outpost"
		_check(not campaign.validate_departure(invalid, authority).ok, "Job/destination mismatch rejects before debit")
		_check(not campaign.validate_departure(departure, {}).ok, "Read-only validation preserves authorization requirement")
		_check(campaign.get_campaign_snapshot() == before_campaign, "Rejected previews also preserve exact campaign snapshot")
	_check(supply.has_method("preview_route_fuel"), "Supply exposes read-only route fuel validation")
	if supply.has_method("preview_route_fuel"):
		var preview: Dictionary = supply.preview_route_fuel(departure, authority)
		_check(preview.ok and preview.fuel_cost == 12.0, "Preview reports authored route cost")
		_check(supply.get_supply_snapshot() == before_supply, "Fuel preview never changes credits, balances or revision")
		var invalid: Dictionary = departure.duplicate()
		invalid.destination_location_id = "invented"
		_check(not supply.preview_route_fuel(invalid, authority).ok, "Unknown route rejects in preview")
		_check(not supply.preview_route_fuel(departure, {}).ok, "Fuel preview requires authorized departure")
		supply.register_craft("empty", 0.0)
		var empty: Dictionary = departure.duplicate()
		empty.craft_id = "empty"
		_check(not supply.preview_route_fuel(empty, authority).ok, "Insufficient fuel rejects before any command")
		var empty_reply: Dictionary = supply.preview_route_fuel(empty, authority)
		_check(String(empty_reply.get("reason", "")) == "insufficient_fuel", "Empty tank without reserve check keeps the reason insufficient_fuel")
		_check(String(empty_reply.get("message", "")).contains("zuerst auftanken"), "Insufficient fuel message tells the player to refuel first: " + String(empty_reply.get("message", "")))
	var busy_purchase: Dictionary = supply.apply_command({"contract_category": "singleplayer_supply", "operation": "buy", "payload": {"offer_id": "medictool_supply", "quantity": 1}, "request_id": "busy"}, {"location_id": "trade_outpost", "craft_busy": true})
	_check(not busy_purchase.ok, "Busy craft cannot purchase through service owner")
	_check(supply.get_supply_snapshot().credits == before_supply.credits and supply.get_supply_snapshot().item_quantities == before_supply.item_quantities, "Rejected busy purchase changes no balance")
	print("DEPARTURE_VALIDATION_RESULTS passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS: " + label)
	else:
		failed += 1
		printerr("FAIL: " + label)
