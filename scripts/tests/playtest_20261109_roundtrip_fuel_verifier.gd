extends SceneTree

var passed: int = 0
var failed: int = 0

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		printerr("FAIL: ", message)

func _run() -> void:
	var flow = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var runtime = flow.get("_singleplayer_runtime")
	var supply = runtime.get("_supply")
	var screen = flow.get_node("HomebaseScreen")
	var crafts: Array = flow.get("_homebase_aircraft_definitions")
	var craft_id: String = String(crafts[0].craft_id)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/trade_offers.json"))
	data.initial_fuel = 12.0
	supply.configure(crafts, data)
	screen.request_operation("accept_job", {"job_id": "satellite_recovery"})
	screen.request_operation("select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"})
	var result: Dictionary = screen.request_operation("start", {"craft_id": craft_id})
	_check(not result.get("ok", true), "Real start rejects fuel sufficient only for outbound flight")
	_check(float(supply.get_supply_snapshot().fuel_by_craft_id[craft_id]) == 12.0, "Rejected flight consumes no fuel")
	_check(flow.get("_active_mission") == null and Array(flow.get("_pending_mission_craft_transfers")).is_empty(), "Rejected roundtrip leaves no mission or half-started transfer")
	_check(String(runtime.get_snapshot().campaign.jobs.satellite_recovery.status) == "accepted", "Rejected flight leaves job accepted")
	var route := {"craft_id": craft_id, "origin_location_id": "homebase", "destination_location_id": "satellite_crash"}
	var context := {"departure_authorized": true, "require_return_reserve": true}
	supply.configure(crafts, data)
	var gate: Dictionary = supply.preview_route_fuel(route, context)
	_check(not gate.get("ok", true) and gate.get("reason", "") == "insufficient_return_fuel", "Supply owner checks return reserve, not just UI")
	data.initial_fuel = 24.0
	supply.configure(crafts, data)
	gate = supply.preview_route_fuel(route, context)
	_check(gate.get("ok", false), "Exact data-defined roundtrip fuel is sufficient")
	_check(float(supply.get_supply_snapshot().fuel_by_craft_id[craft_id]) == 24.0, "Roundtrip preflight stays read-only")
	var debit: Dictionary = supply.apply_command({"contract_category": "singleplayer_supply", "operation": "consume_route_fuel", "payload": route, "request_id": "reserve:out"}, context)
	_check(debit.get("ok", false) and float(supply.get_supply_snapshot().fuel_by_craft_id[craft_id]) == 12.0, "Actual outward flight debits only its own leg")
	var reverse := {"craft_id": craft_id, "origin_location_id": "satellite_crash", "destination_location_id": "homebase"}
	var back: Dictionary = supply.apply_command({"contract_category": "singleplayer_supply", "operation": "consume_route_fuel", "payload": reverse, "request_id": "reserve:back"}, {"departure_authorized": true})
	_check(back.get("ok", false) and float(supply.get_supply_snapshot().fuel_by_craft_id[craft_id]) == 0.0, "Reserved reverse leg remains affordable and reaches zero safely at home")
	flow.queue_free()
	await process_frame
	print("ROUNDTRIP_FUEL_RESULTS passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)
