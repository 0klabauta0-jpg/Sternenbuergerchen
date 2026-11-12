extends "res://scripts/tests/orbit_quantum_flow_verifier.gd"
## Real campaign route; no injected map, ship, pilot, cargo or travel state.

func _run() -> void:
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
	if not _check(int(goods.get("pistol", 0)) == int(old_goods.get("pistol", 0)) + 1, "Station purchase reaches actual ship cargo"):
		print("STATION STATUS: ", station.get("_status").text); await _finish(); return
	_check(view.get("_world_root").get_node_or_null(NodePath("PolisaCargoLift_" + _craft_id.validate_node_name())) != null, "Purchase starts visible 3D cargo lift")
	var fuel_before: float = float(after.fuel_by_craft_id[_craft_id])
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
	_check(int(Dictionary(Dictionary(final.inventory).get("craft:" + _craft_id, {})).get("items", {}).get("pistol", 0)) == int(goods.get("pistol", 0)), "Purchased cargo persists on return")
	await _finish()
