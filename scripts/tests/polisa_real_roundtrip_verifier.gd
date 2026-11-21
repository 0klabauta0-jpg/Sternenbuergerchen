extends "res://scripts/tests/orbit_quantum_flow_verifier.gd"
## Real campaign route; no injected map, ship, pilot, cargo or travel state.

func _run() -> void:
	var isolated_root := OS.get_environment("POLISA_TEST_PROFILE").simplify_path().replace("\\", "/").to_lower()
	var user_dir := OS.get_user_data_dir().simplify_path().replace("\\", "/").to_lower()
	if isolated_root.is_empty() or not user_dir.begins_with(isolated_root + "/"):
		printerr("FAIL: Test requires an isolated POLISA_TEST_PROFILE")
		quit(1); return
	load("res://scripts/meta/game_start_contract.gd").request_start(self, "campaign", "new")
	_flow = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(_flow)
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	_craft_id = String(Dictionary(_screen.call("get_operations_snapshot").get("selected_craft", {})).get("id", ""))
	if not _check(not _craft_id.is_empty(), "Campaign supplies an actual ship"):
		await _finish(); return
	if not _board_real_crew(_runtime.call("get_base_personnel_runtime")):
		await _finish(); return
	var result: Dictionary = _op("select_destination", {"location_id":"polisa", "job_id":""})
	if not _check(result.get("ok", false), "Select Polisa as a free visit"):
		print("SELECT: ", result); await _finish(); return
	var fuel_start: float = float(_runtime.call("get_snapshot").supply.fuel_by_craft_id[_craft_id])
	result = _op("start")
	if not _check(result.get("ok", false), "Real crew departs homebase"):
		print("START: ", result); await _finish(); return
	result = _op("space_start_quantum", {"target_orbit_id":"polisa_orbit"})
	if not _check(result.get("ok", false), "Start quantum to Polisa"):
		print("OUTWARD: ", result); await _finish(); return
	if not _check(await _wait(func(): return _space().get("orbit_id", "") == "polisa_orbit", 10000), "Arrive at Polisa orbit"):
		print("TRAVEL: ", _space()); await _finish(); return
	result = _op("space_begin_approach", {"location_id":"polisa"})
	if not _check(result.get("ok", false), "Start Polisa approach"):
		print("APPROACH: ", result); await _finish(); return
	if not _check(await _wait(func(): return is_instance_valid(_flow.get("_active_mission")), 30000), "Actual Polisa scene loads"):
		await _finish(); return
	_flow.call("_show_mission")
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	if not _check(await _wait(func(): return controller.call("_find_mission_dropship_card_entry", _craft_id).get("state", "") == "waiting", 45000), "Inbound ship reaches landing selection"):
		print("CARD: ", controller.call("_find_mission_dropship_card_entry", _craft_id)); await _finish(); return
	var map = load("res://scripts/terrain/terrain_map_data.gd").load_from_file("res://maps/polisa_station.json")
	var view: Node = mission.get_node("Primary3DView")
	var pad: Vector2 = map.get_marker_position("polisa_pad_01")
	view.call("focus_world_position", pad)
	controller.call("_on_mission_dropship_card_set_lz_pressed", _craft_id)
	if not _check(controller.call("_place_lz_from_screen_position", view.call("world_to_screen_position", pad)), "Choose real station pad"):
		await _finish(); return
	controller.call("_on_mission_dropship_card_drop_pressed", _craft_id)
	if not _check(await _wait(func(): return controller.call("_is_parked_campaign_dropship", _craft_id), 45000), "Ship physically lands at Polisa"):
		print("LANDING CARD: ", controller.call("_find_mission_dropship_card_entry", _craft_id)); await _finish(); return
	var crew: PackedStringArray = controller.call("_campaign_craft_crew_ids", _craft_id)
	if not _check(not crew.is_empty() and await _wait(func():
		var deployed: Dictionary = controller.get("_deployed_unit_ids")
		for id in crew:
			if not deployed.has(id): return false
		return true, 30000), "Entire crew exits to ground"):
		await _finish(); return
	var setup: Node = mission.get_node("MissionSetup")
	var sim: Node = mission.get_node("SimulationRoot")
	if not _check(bool(setup.call("get_hex_setup_status").get("required", false)) and sim.call("is_hex_ground_runtime_active"), "Actual station starts its tactical ground owner"):
		await _finish(); return
	var spawn: Dictionary = controller.call("get_polisa_resident_spawn_grid")
	if not _check(spawn.get("ok", false), "Actual globe has a free walkable recruitment position"):
		print("RECRUIT SPAWN: ", spawn); await _finish(); return
	var pilot_id := "station_shuttle_pilot_roundtrip_probe"
	var admitted: Dictionary = setup.call("request_polisa_recruit_admission", {"unit_id":pilot_id,"display_name":"Station probe"}, spawn.spawn_grid)
	if not _check(admitted.get("ok", false) and await _wait(func(): return bool(setup.call("get_polisa_recruit_admission", pilot_id).get("ok", false)), 15000), "Actual station admits service actor through recruitment path"):
		print("RECRUIT ADMISSION: ", admitted); await _finish(); return
	if not _check(bool(setup.call("retire_polisa_service_actors", PackedStringArray([pilot_id])).get("ok", false)), "Actual station retires service actor without affecting crew"):
		await _finish(); return
	_flow.call("select_location_view_craft", "polisa", _craft_id)
	_flow.call("_refresh_singleplayer_services")
	var station: Node = _flow.get("_polisa_station_screen")
	if not _check(is_instance_valid(station), "Real station service screen is available"):
		await _finish(); return
	var before: Dictionary = _runtime.call("get_snapshot").supply
	station.call("_request", "buy", {"offer_id":"polisa_pistol", "quantity":1})
	var after: Dictionary = _runtime.call("get_snapshot").supply
	var goods: Dictionary = Dictionary(Dictionary(after.inventory).get("craft:" + _craft_id, {})).get("items", {})
	var old_goods: Dictionary = Dictionary(Dictionary(before.inventory).get("craft:" + _craft_id, {})).get("items", {})
	var lift:Dictionary=Dictionary(after.inventory.get("station:polisa:lift",{})).get("items",{})
	if not _check(int(goods.get("pistol", 0)) == int(old_goods.get("pistol", 0)) and int(lift.get("pistol",0))>=1, "Station purchase reaches real lift, not ship"):
		print("STATION STATUS: ", station.get("_status").text); await _finish(); return
	result=_runtime.call("request_operation","cargo_transfer_all",{"source_container_id":"station:polisa:lift","destination_container_id":"craft:"+_craft_id,"request_id":"roundtrip-cargo"})
	if not _check(result.get("ok",false),"Real autonomous cargo transfer starts"):
		print("CARGO START: ",result);await _finish();return
	_check(not _runtime.call("get_world_checkpoint_guard").get("ok",false),"Active transfer blocks checkpoint")
	_check(not _runtime.call("get_surface_departure_retirement_guard",_craft_id).get("ok",true) if _runtime.has_method("get_surface_departure_retirement_guard") else not _flow.call("get_surface_departure_retirement_guard",_craft_id).get("ok",true),"Active transfer blocks ship departure")
	if not _check(await _wait(func():return String(_runtime.get("_cargo_transfer").get_snapshot().get("phase",""))=="complete",15000),"Timed cargo transfer completes"):
		print("CARGO: ",_runtime.get("_cargo_transfer").get_snapshot());await _finish();return
	after=_runtime.call("get_snapshot").supply
	goods=Dictionary(Dictionary(after.inventory).get("craft:"+_craft_id,{})).get("items",{})
	_check(int(goods.get("pistol",0))==int(old_goods.get("pistol",0))+1,"Actual ship inventory receives purchased item")
	var fuel_before: float = float(after.fuel_by_craft_id[_craft_id])
	# Tanker T1 (Regel 8 / Auftrag 21.11.): Hinweg Heimat -> Polisa = Abheben 2 + Sprung 4 + Anflug 4 = 10 (alter Wert homebase>polisa).
	_check(is_equal_approx(fuel_start - fuel_before, 10.0), "T1: der Hinweg nach Polisa bucht in den echten Etappen genau 10 (%.1f -> %.1f)" % [fuel_start, fuel_before])
	# Fix-Runde 1, Klein 3 (echter Stationsdienst): Tankservice da und Credits reichen -> nicht liegen geblieben; Tankservice da, aber 0 Credits -> liegen geblieben.
	var supply_owner: Object = _runtime.get("_supply")
	var credits_keep: int = int(supply_owner.get_credits())
	supply_owner.get("_fuel_by_craft_id")[_craft_id] = 1.0
	supply_owner.set("_credits", 100000)
	var rich_status: Dictionary = _runtime.call("get_fuel_status", _craft_id)
	_check(bool(rich_status.get("refuel_here", false)) and bool(rich_status.get("refuel_affordable", false)) and not bool(rich_status.get("stranded", true)), "Klein 3: an der Station mit Tankservice und Credits: refuel_affordable=true, nicht liegen geblieben: %s" % [rich_status])
	supply_owner.set("_credits", 0)
	var broke_status: Dictionary = _runtime.call("get_fuel_status", _craft_id)
	_check(bool(broke_status.get("refuel_here", false)) and not bool(broke_status.get("refuel_affordable", true)) and bool(broke_status.get("stranded", false)), "Klein 3: an der Station mit Tankservice, aber 0 Credits: refuel_affordable=false, liegen geblieben: %s" % [broke_status])
	supply_owner.get("_fuel_by_craft_id")[_craft_id] = fuel_before
	supply_owner.set("_credits", credits_keep)
	station.call("_request_refuel")
	var refueled: Dictionary = _runtime.call("get_snapshot").supply
	_check(float(refueled.fuel_by_craft_id[_craft_id]) > fuel_before, "Station refuels the landed ship")
	result = _runtime.call("request_operation", "station_board_crew", {"craft_id":_craft_id, "service_location_id":"polisa"})
	print("BOARD REQUEST: ", result)
	if not _check(await _wait(func(): return bool(controller.call("get_campaign_pilot_flight_guard", _craft_id).get("ok", false)), 60000), "Real pilot boards before departure"):
		print("GUARD: ", controller.call("get_campaign_pilot_flight_guard", _craft_id)); await _finish(); return
	result = _runtime.call("request_operation", "return_homebase", {"craft_id":_craft_id, "service_location_id":"polisa"})
	if not _check(result.get("ok", false), "Station return starts"):
		print("RETURN: ", result); await _finish(); return
	print("DEPARTURE INITIAL: ", {"phase":controller.get("_drop_sequence_phase"), "card":controller.call("_find_mission_dropship_card_entry", _craft_id), "message":controller.get("_last_command_text")})
	if not _check(await _wait(func(): return _space().get("phase", "") == "orbit" and _space().get("orbit_id", "") == "polisa_orbit", 45000), "Depart station to Polisa orbit"):
		print("DEPARTURE FINAL: ", {"phase":controller.get("_drop_sequence_phase"), "card":controller.call("_find_mission_dropship_card_entry", _craft_id), "message":controller.get("_last_command_text"), "pending":_flow.get("_pending_mission_craft_transfers"), "retire":_flow.get("_pending_surface_departures")}); await _finish(); return
	result = _op("space_start_quantum", {"target_orbit_id":"moon_orbit"})
	if not _check(result.get("ok", false), "Start quantum home"):
		print("HOME WARP: ", result); await _finish(); return
	if not _check(await _wait(func(): return _space().get("orbit_id", "") == "moon_orbit", 10000), "Reach home orbit"):
		await _finish(); return
	result = _op("space_land_homebase")
	if not _check(result.get("ok", false), "Request landing at homebase"):
		print("HOME LAND: ", result); await _finish(); return
	_check(await _wait(func():
		for craft: Dictionary in _runtime.call("get_snapshot").crafts:
			if craft.get("craft_id", "") == _craft_id: return craft.get("location_id", "") == "homebase" and not craft.get("busy", true)
		return false, 45000), "Original ship and purchased cargo arrive home")
	var final: Dictionary = _runtime.call("get_snapshot").supply
	# Rueckweg vom Stationsorbit: Ortsabflug 6 + Sprung 4 + Landung 0 = 10 (alter Wert polisa>homebase), kein Doppelbuchen.
	_check(is_equal_approx(float(refueled.fuel_by_craft_id[_craft_id]) - float(final.fuel_by_craft_id[_craft_id]), 10.0), "T1: der Rueckweg von Polisa nach Hause bucht in den echten Etappen genau 10 (%.1f -> %.1f)" % [float(refueled.fuel_by_craft_id[_craft_id]), float(final.fuel_by_craft_id[_craft_id])])
	_check(int(Dictionary(Dictionary(final.inventory).get("craft:" + _craft_id, {})).get("items", {}).get("pistol", 0)) == int(goods.get("pistol", 0)), "Purchased cargo persists on return")
	await _finish()
