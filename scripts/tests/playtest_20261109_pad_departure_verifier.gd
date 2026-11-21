extends SceneTree

var passed: int = 0
var failed: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var flow = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var runtime = flow.get("_singleplayer_runtime")
	var screen = flow.get_node("HomebaseScreen")
	var explorer = load("res://scenes/meta/explorable_homebase.tscn").instantiate()
	root.add_child(explorer)
	_check(runtime.has_method("sync_crafts"), "Actual craft lifecycle has stable pad assignment")
	_check(runtime.has_method("authorize_return"), "Runtime owns fixed return route fuel authorization")
	_check(explorer.has_method("set_transport_snapshot"), "Exploration accepts read-only transport projection")
	_check(explorer.has_method("focus_craft_pad"), "Existing viewport can focus actual craft pad")
	if not runtime.has_method("sync_crafts") or not runtime.has_method("authorize_return") or not explorer.has_method("set_transport_snapshot"):
		explorer.queue_free()
		flow.queue_free()
		await process_frame
		_finish()
		return
	runtime.sync_crafts()
	var initial: Dictionary = runtime.get_snapshot()
	var first_id: String = String(initial.crafts[0].craft_id)
	var first_pad: String = String(initial.crafts[0].landing_pad_id)
	_check(first_pad == "homebase_pad_01", "First real craft occupies actual first pad")
	flow.call("_on_homebase_aircraft_add_requested", "dropship")
	runtime.sync_crafts()
	var second_id: String = ""
	for craft in runtime.get_snapshot().crafts:
		if String(craft.craft_id) != first_id:
			second_id = String(craft.craft_id)
	_check(not second_id.is_empty() and _craft(runtime.get_snapshot(), second_id).landing_pad_id == "homebase_pad_02", "Second real craft owns second pad")
	var definitions: Array = flow.get("_homebase_aircraft_definitions").duplicate(true)
	definitions.reverse()
	flow.set("_homebase_aircraft_definitions", definitions)
	runtime.sync_crafts()
	_check(_craft(runtime.get_snapshot(), first_id).landing_pad_id == first_pad and _craft(runtime.get_snapshot(), second_id).landing_pad_id == "homebase_pad_02", "Reordering actual craft catalog cannot move pads")
	flow.call("_on_homebase_aircraft_add_requested", "dropship")
	runtime.sync_crafts()
	var third_id: String = ""
	for craft in runtime.get_snapshot().crafts:
		if not String(craft.craft_id) in [first_id, second_id]:
			third_id = String(craft.craft_id)
	_check(not third_id.is_empty() and String(_craft(runtime.get_snapshot(), third_id).landing_pad_id).is_empty(), "Third craft cannot invent a third physical pad")
	flow.call("_on_homebase_aircraft_remove_requested", third_id)
	runtime.sync_crafts()
	_check(_craft(runtime.get_snapshot(), third_id).is_empty() and _craft(runtime.get_snapshot(), second_id).landing_pad_id == "homebase_pad_02", "Actual craft removal preserves all surviving pad assignments")
	var supply_before: Dictionary = runtime.get_snapshot().supply
	runtime.get_snapshot()
	runtime.get_snapshot()
	_check(runtime.get_snapshot().supply == supply_before, "Repeated projection reads cannot create fuel or stock")
	explorer.set_transport_snapshot(runtime.get_snapshot())
	explorer.set_active(true)
	await process_frame
	var explore: Dictionary = explorer.get_exploration_snapshot()
	_check(explore.get("projected_crafts", []).size() == 2, "Both actual homebase craft models projected")
	_check(explorer.focus_craft_pad(first_id), "Camera can focus actual occupied pad")
	_check(not explorer.focus_craft_pad("invented"), "Camera rejects nonexistent craft")
	var unknown: Dictionary = screen.request_operation("start", {"craft_id": "invented"})
	_check(not unknown.ok and runtime.get_snapshot().supply == supply_before, "Wrong craft cannot launch or debit fuel")
	screen.request_operation("accept_job", {"job_id": "satellite_recovery", "request_id": "pad-accept"})
	screen.request_operation("select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery", "request_id": "pad-destination"})
	var empty: Dictionary = screen.request_operation("start", {"craft_id": second_id})
	_check(not empty.ok and runtime.get_snapshot().supply == supply_before, "Empty unpiloted craft cannot launch or debit")
	_check(not runtime.authorize_departure(second_id).ok and runtime.get_snapshot().supply == supply_before, "Runtime also enforces payload and pilot before debit")
	screen.call("_debug_advance_homebase_direct_boarding", 30.0)
	var launch: Dictionary = screen.request_operation("start", {"craft_id": first_id})
	_check(launch.ok, "Real boarded craft launch request accepts")
	var deadline: int = Time.get_ticks_msec() + 12000
	while flow.get("_active_mission") == null and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(flow.get("_active_mission") != null, "Accepted real launch hands off to mission")
	var departed: Dictionary = runtime.get_snapshot()
	var bound: Dictionary = departed.campaign.departures_by_craft_id.get(first_id, {})
	_check(bound.get("destination_location_id") == "satellite_crash" and bound.get("job_id") == "satellite_recovery" and bound.get("landing_pad_id") == first_pad, "Actual craft keeps destination, job and origin pad")
	_check(departed.supply.fuel_by_craft_id[first_id] == supply_before.fuel_by_craft_id[first_id] - 12.0, "Exactly one outbound route debit")
	var forged_proof := {"result": "victory", "mission_scenario_runtime_gates": {"all_gates_complete": true, "completed_step_ids": ["secure_satellite", "return_to_ship"]}}
	runtime.record_mission_result(forged_proof, {"craft_id": first_id, "job_id": "satellite_recovery", "scenario_id": "trade_outpost_visit"})
	runtime.record_mission_result(forged_proof)
	_check(runtime.get_snapshot().campaign.jobs.satellite_recovery.status == "active" and runtime.get_snapshot().campaign.completion_receipts.is_empty(), "Missing or foreign immutable mission identity cannot complete active job")
	var repeated: Dictionary = screen.request_operation("start", {"craft_id": first_id})
	_check(not repeated.ok and runtime.get_snapshot().supply == departed.supply, "Repeated in-flight start consumes no more fuel")
	_check(not screen.request_operation("select_destination", {"location_id": "trade_outpost", "request_id": "pad-switch"}).ok, "Destination change during actual transit is blocked")
	explorer.set_transport_snapshot(departed)
	_check(explorer.get_exploration_snapshot().projected_crafts.size() == 1, "Departed craft visual disappears while other craft remains")
	flow.call("_remove_pending_mission_craft_transfer", first_id)
	flow.call("_complete_mission_craft_transfer", {"craft_id": first_id, "phase": "to_mission"})
	_check(not screen.request_operation("select_destination", {"location_id": "trade_outpost", "request_id": "pad-cross-world"}).ok, "Arrived active mission cannot be repurposed as a different location")
	_check(screen.request_operation("select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery", "request_id": "pad-same-world"}).ok, "Same-location selection remains available for reinforcement")
	var return_auth: Dictionary = runtime.authorize_return(first_id, "pad-return")
	_check(return_auth.ok, "Return flight authorizes real remote craft")
	var returning_supply: Dictionary = runtime.get_snapshot().supply
	# Regel 8 / Auftrag 21.11.: authorize_return bucht nur den Ortsabflug (surface_exit 2); Sprung (10) und Heimlandung (0) buchen beim Sprung bzw. bei der Landung. Hinweg 12 + Ortsabflug 2 = 14; die Endsumme 24 steht in tanker_result_fuel_verifier.
	_check(returning_supply.fuel_by_craft_id[first_id] == supply_before.fuel_by_craft_id[first_id] - 14.0, "Return charges only the surface exit leg once (Regel 8)")
	_check(runtime.authorize_return(first_id, "pad-return").ok and runtime.get_snapshot().supply == returning_supply, "Return request replay never debits twice")
	_check(runtime.authorize_return(first_id, "different-ui-event").ok and runtime.get_snapshot().supply == returning_supply, "Transport and UI return requests share one outward-trip receipt")
	flow.call("_begin_mission_craft_transfer", first_id, "to_homebase", 18.0, "homebase_direct")
	flow.call("_remove_pending_mission_craft_transfer", first_id)
	flow.call("_complete_mission_craft_transfer", {"craft_id": first_id, "phase": "to_homebase"})
	explorer.set_transport_snapshot(runtime.get_snapshot())
	_check(_craft(runtime.get_snapshot(), first_id).landing_pad_id == first_pad and _craft(runtime.get_snapshot(), first_id).location_id == "homebase", "Return retains exact original craft pad")
	_check(explorer.get_exploration_snapshot().projected_crafts.size() == 2, "Returned actual craft model restores without clone")
	explorer.set_active(false)
	_check(explorer.get_exploration_snapshot().active == false, "Hidden projection disables existing viewport branch")
	explorer.queue_free()
	flow.queue_free()
	await process_frame
	_finish()

func _craft(snapshot: Dictionary, craft_id: String) -> Dictionary:
	for craft in snapshot.crafts:
		if String(craft.craft_id) == craft_id:
			return craft
	return {}

func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS: " + label)
	else:
		failed += 1
		printerr("FAIL: " + label)

func _finish() -> void:
	print("PAD_DEPARTURE_RESULTS passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)
