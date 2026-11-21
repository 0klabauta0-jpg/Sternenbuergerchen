extends SceneTree
## Actual two-sortie loop. Campaign base walks and boarding run at real 1x;
## only the separate Skirmish boarding convenience fixture advances its clock.

const FLOW: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const MAP: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
var _flow: Node
var _screen: Control
var _runtime: Node
var _craft_id: String = ""
var _team_id: String = ""
var _pilot_id: String = ""
var _crew_ids: Array[String] = []
var _identity_before: Dictionary = {}
var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_configure_entry()
	print("SINGLEPLAYER_LOOP_BEGIN time_scale=", Engine.time_scale, " user_data=", OS.get_user_data_dir())
	_check(is_equal_approx(Engine.time_scale, 1.0), "Full travel and mission loop runs at real 1x simulation speed")
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	if not _check(_runtime != null, "Actual Flow has long-lived campaign runtime"):
		await _finish()
		return
	if not await _prepare_initial_base():
		await _finish()
		return
	var initial: Dictionary = _flow.call("get_singleplayer_snapshot")
	var operations: Dictionary = _screen.call("get_operations_snapshot")
	var craft: Dictionary = Dictionary(operations.get("selected_craft", {}))
	_craft_id = String(craft.get("id", ""))
	_pilot_id = String(craft.get("pilot_id", ""))
	var payload_teams: Array = Array(craft.get("payload_fireteam_ids", []))
	if not _check(not _craft_id.is_empty() and not payload_teams.is_empty(), "Normal bootstrap has actual craft and team payload"):
		_dump("bootstrap")
		await _finish()
		return
	_team_id = String(payload_teams[0])
	for team: Dictionary in Array(operations.get("fireteams", [])):
		if String(team.id) == _team_id:
			for member: Dictionary in Array(team.get("members", [])):
				_crew_ids.append(String(member.id))
	_identity_before = _identity(operations)
	_check(_crew_ids.size() == _expected_crew_count(), "Initial payload contains the expected real crew identities")
	_check(_screen.call("request_operation", "accept_job", {"job_id": "satellite_recovery", "request_id": "loop:accept"}).get("ok", false), "Accept job through real operation bridge")
	_check(_flow.get("_active_mission") == null, "Acceptance alone starts no mission")
	_check(_screen.call("request_operation", "select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery", "request_id": "loop:satellite"}).get("ok", false), "Select the distinct satellite location")
	if not await _launch_and_land("satellite_recovery", "res://maps/satellite_crash_site.json"):
		await _finish()
		return
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	var driver: Node = mission.get_node("CombatLoopDriver")
	var victory_on_load: bool = bool(driver.call("_is_victory_condition_met"))
	_check(not victory_on_load, "Actual satellite scene cannot win on load")
	controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
	if not await _move_and_use(mission, "satellite_data", "secure_satellite", "res://maps/satellite_crash_site.json"):
		await _finish()
		return
	_check(not bool(driver.call("_is_victory_condition_met")), "Recovered data still requires physical ship return")
	if not await _move_and_use(mission, "ship_return", "return_to_ship", "res://maps/satellite_crash_site.json"):
		await _finish()
		return
	if not await _wait(func(): return String(Dictionary(_campaign().get("jobs", {})).get("satellite_recovery", {}).get("status", "")) == "pending_upload", 10000, "Real mission result secures the chip and awaits home upload"):
		_dump("campaign_completion")
		await _finish()
		return
	_check(int(_flow.call("get_singleplayer_snapshot").supply.credits) == int(initial.supply.credits), "No reward before physical home upload")
	if not await _wait_homebase():
		await _finish()
		return
	_check(String(Dictionary(_campaign().get("jobs", {})).get("satellite_recovery", {}).get("status", "")) == "completed", "Home upload completes the accepted campaign job")
	var rewarded: Dictionary = _flow.call("get_singleplayer_snapshot")
	_check(int(rewarded.supply.credits) == int(initial.supply.credits) + 150, "Runtime reward credits exactly one data-defined payment")
	_check(Dictionary(rewarded.campaign.get("completion_receipts", {})).size() == 1, "Exactly one campaign completion receipt")
	_flow.call("request_debrief_return_homebase_for_test")
	var returned: Dictionary = _flow.call("get_singleplayer_snapshot")
	_check(float(returned.supply.fuel_by_craft_id[_craft_id]) == float(initial.supply.fuel_by_craft_id[_craft_id]) - 24.0, "First actual round trip consumes outbound and reverse route fuel once")
	_check(int(returned.supply.credits) == int(rewarded.supply.credits), "Viewing result/homebase again cannot duplicate reward")
	_check(_identity(_screen.call("get_operations_snapshot")) == _identity_before, "First return preserves all original identities and portraits")
	_check(_screen.call("request_operation", "select_destination", {"location_id": "trade_outpost", "job_id": "", "request_id": "loop:trade"}).get("ok", false), "Second sortie selects trade location without combat job")
	# Seit e4b407fe0 (10.11.) laedt der Handelsaussenposten (locations.json: trade_outpost) das Szenario outpost_recovery (Wache, Kiste, Rueckkehr; trade_service ist dort ein Haendlerpunkt ohne Vorstufe), nicht mehr trade_outpost_visit.
	if not await _launch_and_land("outpost_recovery", "res://maps/trade_outpost.json"):
		await _finish()
		return
	mission = _flow.get("_active_mission")
	controller = mission.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
	var before_service: Dictionary = _flow.call("get_singleplayer_snapshot")
	_check(not Dictionary(before_service.get("service_contexts_by_craft_id", {})).has(_craft_id), "Landing alone cannot grant trader use proof")
	if not await _move_and_use(mission, "trade_service", "trade_service", "res://maps/trade_outpost.json"):
		await _finish()
		return
	if not await _wait(func(): return Dictionary(_flow.call("get_singleplayer_snapshot").get("service_contexts_by_craft_id", {})).has(_craft_id), 3000, "Actual landed craft and completed trader Use enable service"):
		_dump("service_context_after_use")
		await _finish()
		return
	var services: Control = _flow.get("_singleplayer_services")
	if not _check(services != null and services == _flow.get_node_or_null("SingleplayerServiceLayer/MissionServices"), "Trade uses the actual Flow-owned service panel"):
		await _finish()
		return
	# Seit a4d5948c5 (12.11.) ist die Versorgung ein eingeklapptes Bedienelement (ServicePanelToggle, "Versorgung oeffnen"); der Spieler klappt sie auf (Vertrag: campaign_service_toggle_verifier). Vorher stand das Panel von selbst offen.
	var service_toggle: Button = _flow.get("_singleplayer_services_toggle")
	if not await _wait(func(): return service_toggle != null and service_toggle.is_visible_in_tree(), 3000, "Compact Versorgung control is offered after the completed trader Use"):
		_dump("service_toggle")
		await _finish()
		return
	service_toggle.pressed.emit()
	services.call("set_selected_craft", _craft_id)
	var buy: Button = services.find_child("BuySupply", true, false)
	var fuel: Button = services.find_child("RefuelCraft", true, false)
	var orbital_return: Button = services.find_child("ServiceReturnHomebase", true, false)
	var service_supply: Dictionary = _supply()
	if not await _wait(func(): return services.is_visible_in_tree() and buy != null and buy.is_visible_in_tree() and not buy.disabled and fuel != null and fuel.is_visible_in_tree() and not fuel.disabled, 2000, "Flow-owned service UI offers purchase and refuel after Use"):
		print("SERVICE_UI_STATE: panel_visible=", services.is_visible_in_tree(), " buy=", buy != null and buy.is_visible_in_tree(), "/", buy != null and buy.disabled, " (", buy.tooltip_text if buy != null else "-", ") fuel=", fuel != null and fuel.is_visible_in_tree(), "/", fuel != null and fuel.disabled, " (", fuel.tooltip_text if fuel != null else "-", ")")
		_dump("service_ui")
		await _finish()
		return
	buy.pressed.emit()
	buy.pressed.emit()
	fuel.pressed.emit()
	fuel.pressed.emit()
	var paid: Dictionary = _supply()
	_check(int(paid.credits) == int(service_supply.credits) - 70, "Real service double-clicks debit one purchase and one ten-unit refuel")
	# Seit 8571be32c liefert der Handelsaussenposten Gekauftes in den lokalen Frachtaufzug (station:trade_outpost:lift), nicht mehr direkt ins Schiff; gezaehlt wird, was im Schiff UND im Aufzug liegt.
	var medictools_here := func(supply: Dictionary) -> int:
		var inventory: Dictionary = Dictionary(supply.get("inventory", {}))
		var total := 0
		for container: String in ["craft:" + _craft_id, "station:trade_outpost:lift"]:
			total += int(Dictionary(Dictionary(inventory.get(container, {})).get("items", {})).get("medictool", 0))
		return total
	_check(int(medictools_here.call(paid)) == int(medictools_here.call(service_supply)) + 1, "Second sortie grants one real purchased item (ship or local cargo lift)")
	_check(float(paid.fuel_by_craft_id[_craft_id]) == float(service_supply.fuel_by_craft_id[_craft_id]) + 10.0, "Confirmed actual craft gains exactly ten fuel")
	if not await _prepare_visit_return(mission):
		await _finish()
		return
	print("SERVICE_RETURN_PRESENTATION_BEFORE_WAIT:", var_to_str({
		"panel_path": services.get_path(), "meta_view": _flow.get("_current_meta_view"),
		"panel_visible": services.is_visible_in_tree(),
		"button_visible": orbital_return.is_visible_in_tree() if orbital_return != null else false,
		"button_disabled": orbital_return.disabled if orbital_return != null else true,
	}))
	# The actual panel follows Flow's normal 0.25 s refresh after the embark commit.
	if not await _wait(func(): return orbital_return != null and orbital_return.is_visible_in_tree() and not orbital_return.disabled, 2000, "Actual parked trade ship has a usable service return button"):
		print("SERVICE_RETURN_DIAGNOSTIC:", var_to_str({
			"visible": orbital_return.is_visible_in_tree() if orbital_return != null else false,
			"disabled": orbital_return.disabled if orbital_return != null else true,
			"tooltip": orbital_return.tooltip_text if orbital_return != null else "missing",
			"service_presentation": services.call("get_presentation_snapshot"),
			"service_context": _runtime.call("_service_context", _craft_id),
			"craft": _craft(_flow.call("get_singleplayer_snapshot")),
			"flow_card": _flow.call("_find_mission_drop_card_in_planning_state", _craft_id),
			"controller_card": controller.call("_find_mission_dropship_card_entry", _craft_id),
			"pilot_guard": controller.call("get_campaign_pilot_flight_guard", _craft_id),
			"parked": controller.call("_is_parked_campaign_dropship", _craft_id),
			"space": _space(),
		}))
		await _finish()
		return
	orbital_return.pressed.emit()
	var return_result: Dictionary = Dictionary(Dictionary(services.get("_pending")).get("return_homebase", {})).get("result", {})
	if not _check(bool(return_result.get("ok", false)), "Real visit return command accepts after service"):
		print("RETURN_RESULT:", return_result)
		_dump("trade_return")
		await _finish()
		return
	if not await _wait_homebase():
		await _finish()
		return
	_verify_final_state(initial)
	await _finish()

func _verify_final_state(initial: Dictionary) -> void:
	_flow.call("_show_homebase")
	var final: Dictionary = _flow.call("get_singleplayer_snapshot")
	var final_fuel_balanced: bool = float(final.supply.fuel_by_craft_id[_craft_id]) == float(initial.supply.fuel_by_craft_id[_craft_id]) - 24.0 - 16.0 + 10.0
	_check(final_fuel_balanced, "Two true round trips plus refuel preserve authored fuel accounting")
	_check(Dictionary(final.campaign.completion_receipts).size() == 1 and int(final.supply.credits) == int(initial.supply.credits) + 150 - 70, "Trade sortie cannot repeat satellite receipt or reward")
	_check(_identity(_screen.call("get_operations_snapshot")) == _identity_before, "Second return loses no original crew or identity")
	var final_operations: Dictionary = _screen.call("get_operations_snapshot")
	for id: String in _crew_ids:
		var membership_count: int = 0
		for team: Dictionary in Array(final_operations.get("fireteams", [])):
			for member: Dictionary in Array(team.get("members", [])):
				if String(member.get("id", "")) == id:
					membership_count += 1
		_check(membership_count == 1, "Second return retains exactly one membership for " + id)
	_check(String(Dictionary(final_operations.get("selected_craft", {})).get("pilot_id", "")) == _pilot_id, "Second return preserves actual assigned pilot")
	_check(String(final.campaign.get("selected_job_id", "")) == "", "Peaceful second sortie leaves no stale selected combat job")
	_check(Array(final.crafts).size() == Array(initial.crafts).size() and String(_craft(final).get("landing_pad_id", "")) == String(_craft(initial).get("landing_pad_id", "")), "Both sorties reuse original craft and original pad without clone")

func _launch_and_land(scenario_id: String, map_path: String) -> bool:
	_screen.call("request_operation", "craft", {"craft_id": _craft_id})
	_screen.call("request_operation", "focus_fireteam", {"fireteam_id": _team_id})
	var craft: Dictionary = Dictionary(_screen.call("get_operations_snapshot").get("selected_craft", {}))
	if String(craft.get("pilot_id", "")).is_empty():
		_screen.call("request_operation", "pilot", {"craft_id": _craft_id, "unit_id": _pilot_id})
	if not Array(craft.get("payload_fireteam_ids", [])).has(_team_id):
		var board: Dictionary = _screen.call("request_operation", "board", {"craft_id": _craft_id, "fireteam_id": _team_id})
		if not _check(bool(board.get("ok", false)), scenario_id + " real boarding accepts"):
			print("BOARD_RESULT:", board)
			_dump("boarding")
			return false
	if _screen.call("get_base_personnel_runtime") != null:
		if not await _prepare_sortie_base():
			return false
	else:
		_screen.call("_debug_advance_homebase_direct_boarding", 30.0)
	var before_launch_job_status: String = String(Dictionary(_campaign().get("jobs", {})).get("satellite_recovery", {}).get("status", ""))
	var before_launch_fuel: Dictionary = Dictionary(_supply().get("fuel_by_craft_id", {})).duplicate(true)
	var launch: Dictionary = _screen.call("request_operation", "start", {"craft_id": _craft_id})
	if not _check(bool(launch.get("ok", false)), scenario_id + " launches actual boarded craft"):
		print("LAUNCH_RESULT:", launch)
		_dump("launch")
		return false
	if not _check(_flow.get("_active_mission") == null and int(_flow.get("_active_mission_started_at_msec")) == 0, scenario_id + " takeoff loads no mission and starts no mission timer"):
		return false
	_check(String(Dictionary(_campaign().get("jobs", {})).get("satellite_recovery", {}).get("status", "")) == before_launch_job_status, "Takeoff alone activates no campaign job")
	# Regel 8 / Auftrag 21.11.: das Abheben bucht seinen eigenen Etappenanteil (2), aber keinen Zielanteil.
	_check(is_equal_approx(float(Dictionary(_supply().get("fuel_by_craft_id", {})).get(_craft_id, -1.0)), float(before_launch_fuel.get(_craft_id, 0.0)) - 2.0), "Takeoff alone debits only its own leg share (2), no destination fuel")
	if not _check(String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == "moon_orbit", scenario_id + " actual takeoff reaches moon orbit"):
		_dump("moon_orbit")
		return false
	if String(_runtime.call("get_snapshot").get("mode", "")) == "campaign":
		var away_save: Dictionary = _flow.get("_campaign_start").call("save_home_checkpoint", _flow, _runtime)
		_check(not bool(away_save.get("ok", false)), "Moon orbit cannot be saved as a home checkpoint")
	var destination := String(_campaign().get("selected_location_id", ""))
	var destination_orbit := String(Dictionary(_space().get("location_orbits", {})).get(destination, ""))
	if not _check(not destination_orbit.is_empty(), "Selected destination has an orbit"): return false
	var premature: Dictionary = _screen.call("request_operation", "space_begin_approach", {"craft_id": _craft_id, "location_id": destination})
	_check(not bool(premature.get("ok", false)) and _flow.get("_active_mission") == null, "Planet map approach is blocked from moon orbit")
	var jump: Dictionary = _screen.call("request_operation", "space_start_quantum", {"craft_id": _craft_id, "target_orbit_id": destination_orbit, "request_id": "loop:jump:" + scenario_id})
	if not _check(bool(jump.get("ok", false)), scenario_id + " actual target click begins quantum"):
		print("JUMP_RESULT:", jump)
		_dump("quantum_start")
		return false
	if not await _wait(func(): return float(_space().get("progress", 0.0)) > 0.05, 1500, "Quantum visibly progresses through normal runtime ticks"):
		return false
	var moving_position: Array = Array(_space().get("position", [])).duplicate()
	var abort: Dictionary = _screen.call("request_operation", "space_abort_quantum", {"craft_id": _craft_id, "request_id": "loop:abort:" + scenario_id})
	_check(bool(abort.get("ok", false)) and String(_space().get("phase", "")) == "stopped" and Array(_space().get("position", [])) == moving_position, "Actual abort holds the reached midpoint without teleport")
	var stopped_position: Array = Array(_space().get("position", [])).duplicate()
	await physics_frame
	_check(Array(_space().get("position", [])) == stopped_position, "Aborted runtime trip remains still on subsequent tick")
	var restart: Dictionary = _screen.call("request_operation", "space_start_quantum", {"craft_id": _craft_id, "target_orbit_id": destination_orbit, "request_id": "loop:restart:" + scenario_id})
	if not _check(bool(restart.get("ok", false)) and Array(_space().get("origin_position", [])) == stopped_position, "Restart begins at the actual stopped position"):
		return false
	if not await _wait(func(): return String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == destination_orbit, 5000, scenario_id + " short real quantum reaches destination orbit"):
		_dump("planet_orbit")
		return false
	_check(_flow.get("_active_mission") == null and int(_flow.get("_active_mission_started_at_msec")) == 0, "Quantum arrival still loads no mission and starts no timer")
	_check(String(Dictionary(_campaign().get("jobs", {})).get("satellite_recovery", {}).get("status", "")) == before_launch_job_status, "Quantum, abort and restart activate no job")
	# Regel 8 / Auftrag 21.11.: Abheben (2) und der eine Sprung dieser Strecke sind bezahlt; Abbruch und Neustart aus "stopped" kosten nichts dazu.
	var paid_so_far: float = 2.0 + float(_runtime.get("_supply").call("get_leg_fuel_cost", "homebase", destination, "jump"))
	_check(is_equal_approx(float(Dictionary(_supply().get("fuel_by_craft_id", {})).get(_craft_id, -1.0)), float(before_launch_fuel.get(_craft_id, 0.0)) - paid_so_far), "Quantum, abort and restart debit exactly the takeoff and one jump leg (%s), no approach fuel" % str(paid_so_far))
	var approach: Dictionary = _screen.call("request_operation", "space_begin_approach", {"craft_id": _craft_id, "location_id": destination, "request_id": "loop:approach:" + scenario_id})
	if not _check(bool(approach.get("ok", false)), scenario_id + " explicit approach accepts from planet orbit"):
		print("APPROACH_RESULT:", approach)
		_dump("approach")
		return false
	var approach_phase := String(_space().get("phase", ""))
	var transit: Dictionary = Dictionary(_space().get("orbit_transit", {}))
	_check(_flow.get("_active_mission") == null and (approach_phase == "approach" or (approach.get("pending", false) and approach_phase == "orbit" and transit.get("status") == "flying")), "Explicit approach waits for orbit transit or begins before map instantiation")
	# 180 s: the newly built crash site needs terrain preparation; measured 16-20 s headless (below normal priority, other Godot runs in parallel), the old 12 s was too tight.
	if not await _wait(func(): return _flow.get("_active_mission") != null, 180000, scenario_id + " actual mission instance exists"):
		_dump("mission_creation")
		return false
	_flow.call("_show_mission")
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	if not await _wait(func(): return String(Dictionary(controller.call("_find_mission_dropship_card_entry", _craft_id)).get("state", "")) == "waiting", 30000, scenario_id + " actual outbound transit reaches waiting craft"):
		_dump("outbound_transit")
		return false
	var map = MAP.load_from_file(map_path)
	var view: Node = mission.get_node("Primary3DView")
	var lz: Vector2 = _landing_target(map)
	view.call("focus_world_position", lz)
	controller.call("_on_mission_dropship_card_set_lz_pressed", _craft_id)
	var placed: bool = bool(controller.call("_place_lz_from_screen_position", view.call("world_to_screen_position", lz)))
	if not _check(placed, scenario_id + " actual map click places selected safe LZ"):
		_dump("lz_pick")
		return false
	controller.call("_on_mission_dropship_card_drop_pressed", _craft_id)
	if not await _wait(func(): return _all_crew_deployed(controller) and int(mission.get_node("SimulationRoot").call("get_tick")) > 0, 30000, scenario_id + " real landing unloads all original crew into authoritative simulation"):
		_dump("actual_landing")
		return false
	_on_actual_landed(controller)
	_check(String(mission.get_node("MissionSetup").get("scenario_file_path")).get_file().get_basename() == scenario_id, "Selected location loads exact intended scenario " + scenario_id)
	return true

func _on_actual_landed(_controller: Node) -> void:
	pass

func _prepare_initial_base() -> bool:
	return true

func _prepare_sortie_base() -> bool:
	return true

func _prepare_visit_return(_mission: Node) -> bool:
	return true

func _configure_entry() -> void:
	pass

func _expected_crew_count() -> int:
	return 3

func _move_and_use(mission: Node, interaction: String, step: String, map_path: String) -> bool:
	if not is_instance_valid(mission):
		return _check(false, interaction + " mission still exists before command")
	var controller: Node = mission.get_node("TacticalController")
	var driver: Node = mission.get_node("CombatLoopDriver")
	var map = MAP.load_from_file(map_path)
	var target: Vector2 = map.get_marker_position(interaction)
	if interaction == "ship_return" and controller.has_method("_campaign_landed_craft_position"):
		target = controller.call("_campaign_landed_craft_position", _craft_id)
	controller.call("_create_waypoints_for_selected_fireteams", target, true)
	if not _check(bool(controller.call("execute_selected_fireteam_orders")), interaction + " actual move GO accepts"):
		_dump("move_go")
		return false
	# 180 s: the real approach over the 512x256 map measured 48 s (satellite_data and ship_return, headless, parallel Godot runs); the old 45 s limit was exceeded.
	if not await _wait(func():
		if not is_instance_valid(controller):
			return false
		var entry: Dictionary = _find_interaction(controller.call("get_mission_interaction_runtime_use_state_snapshot"), interaction)
		return String(entry.get("runtime_use_status", "")) == "usable", 180000, interaction + " becomes usable after real simulated approach"):
		_dump("approach_" + interaction)
		return false
	var intent: Dictionary = controller.call("create_selected_mission_interaction_use_intent", interaction)
	if not _check(bool(intent.get("accepted", false)), interaction + " real Use intent accepts"):
		print("USE_INTENT:", intent)
		_dump("use_intent")
		return false
	if not _check(bool(controller.call("execute_selected_fireteam_orders")), interaction + " Use GO accepts"):
		_dump("use_go")
		return false
	if not await _wait(func():
		if is_instance_valid(driver):
			# Der Haendlerpunkt (trade_service) ist in outpost_recovery kein Ablaufschritt (flow_steps), also nie in completed_step_ids; sein Abschluss steht im Laufzeitstand der Interaktion (derselbe Stand, aus dem der Adapter den Service-Kontext bildet).
			return PackedStringArray(driver.call("get_mission_scenario_runtime_gate_snapshot").get("completed_step_ids", [])).has(step) or bool(Dictionary(driver.call("get_mission_interaction_runtime_states").get(interaction, {})).get("complete", false))
		return step == "return_to_ship" and String(Dictionary(_campaign().get("jobs", {})).get("satellite_recovery", {}).get("status", "")) == "completed", 45000, interaction + " actual timed Use commits required runtime step"):
		_dump("use_execution_" + interaction)
		return false
	return true

func _wait_homebase() -> bool:
	var destination := String(_campaign().get("selected_location_id", ""))
	var destination_orbit := String(Dictionary(_space().get("location_orbits", {})).get(destination, ""))
	if not await _wait(func(): return String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == destination_orbit, 35000, "Actual surface exit returns original craft to destination orbit"):
		_dump("return_to_planet_orbit")
		return false
	_check(String(_craft(_flow.call("get_singleplayer_snapshot")).get("location_id", "")) != "homebase", "Planet orbit is not physical home arrival")
	var home_jump: Dictionary = _screen.call("request_operation", "space_start_quantum", {"craft_id": _craft_id, "target_orbit_id": "moon_orbit"})
	if not _check(bool(home_jump.get("ok", false)), "Real homeward target click begins moon quantum"):
		print("HOME_JUMP_RESULT:", home_jump)
		return false
	if not await _wait(func(): return String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == "moon_orbit", 5000, "Real homeward quantum reaches moon orbit"):
		return false
	_check(String(_craft(_flow.call("get_singleplayer_snapshot")).get("location_id", "")) != "homebase", "Moon orbit still requires an explicit home landing")
	var home_land: Dictionary = _screen.call("request_operation", "space_land_homebase", {"craft_id": _craft_id})
	if not _check(bool(home_land.get("ok", false)), "Explicit moonbase landing accepts after actual homeward travel"):
		print("HOME_LAND_RESULT:", home_land)
		_dump("moonbase_land")
		return false
	var ready: bool = await _wait(func():
		var current: Dictionary = _flow.call("get_singleplayer_snapshot")
		var craft: Dictionary = _craft(current)
		return String(craft.get("location_id", "")) == "homebase" and not bool(craft.get("busy", true)), 35000, "Actual reverse transit restores original craft to homebase")
	if not ready:
		_dump("homebase_return")
		return false
	return await _upload_pending_chip()

## Contract (campaign_introduction_contract.md): a recovered chip is uploaded at the home terminal; request_operation("campaign_upload") is the operation the home UI calls, through the screen's gate (homebase_screen.gd _request_operation_from_base -> base_runtime.validate_operation).
## Runs at the end of the home arrival, before subclasses check the tutorial milestone and save/continue the home checkpoint.
func _upload_pending_chip() -> bool:
	if String(Dictionary(_campaign().get("jobs", {})).get("satellite_recovery", {}).get("status", "")) != "pending_upload":
		return true
	_flow.call("_show_homebase")
	var uploaded: Dictionary = _screen.call("request_operation", "campaign_upload", {"job_id": "satellite_recovery"})
	if not _check(bool(uploaded.get("ok", false)), "Real home upload accepted"):
		print("UPLOAD_RESULT ", uploaded)
		print("UPLOAD_JOB ", Dictionary(_campaign().get("jobs", {})).get("satellite_recovery", {}))
		return false
	return true

func _space() -> Dictionary:
	return Dictionary(_flow.call("get_singleplayer_snapshot").get("space_travel", {}))

func _wait(predicate: Callable, milliseconds: int, label: String) -> bool:
	var deadline: int = Time.get_ticks_msec() + milliseconds
	while Time.get_ticks_msec() < deadline:
		if bool(predicate.call()):
			return _check(true, label)
		await physics_frame
	return _check(false, "TIMEOUT " + label)

func _craft(snapshot: Dictionary) -> Dictionary:
	for craft: Dictionary in Array(snapshot.get("crafts", [])):
		if String(craft.get("craft_id", "")) == _craft_id:
			return craft
	return {}

func _all_crew_deployed(controller: Node) -> bool:
	var deployed: Dictionary = Dictionary(controller.get("_deployed_unit_ids"))
	for id: String in _crew_ids:
		if not deployed.has(id):
			return false
	return not _crew_ids.is_empty() and bool(controller.call("_fireteam_deploy_effects_are_applied", _team_id)) and not Dictionary(controller.get("_runtime_activation_pending_fireteam_ids")).has(_team_id) and not Dictionary(controller.get("_post_drop_security_pending_fireteam_ids")).has(_team_id)

func _campaign() -> Dictionary:
	return Dictionary(_flow.call("get_singleplayer_snapshot").get("campaign", {}))

func _supply() -> Dictionary:
	return Dictionary(_flow.call("get_singleplayer_snapshot").get("supply", {}))

func _identity(snapshot: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for person: Dictionary in Array(snapshot.get("roster", [])):
		result[String(person.get("id", ""))] = [String(person.get("portrait_id", "")), String(person.get("portrait_path", ""))]
	return result

func _find_interaction(snapshot: Dictionary, id: String) -> Dictionary:
	for entry: Dictionary in Array(snapshot.get("interactions", [])):
		if String(entry.get("interaction_id", "")) == id:
			return entry
	return {}

func _dump(label: String) -> void:
	var data: Dictionary = {"stage": label, "flow_view": _flow.get("_current_meta_view"), "runtime": _flow.call("get_singleplayer_snapshot"), "operations": _screen.call("get_operations_snapshot").get("selected_craft", {})}
	var mission: Node = _flow.get("_active_mission")
	if is_instance_valid(mission):
		var controller: Node = mission.get_node("TacticalController")
		data["planning"] = controller.call("get_planning_state")
		data["movement"] = controller.call("get_fireteam_movement_snapshot")
		data["execution"] = controller.get("_phase_execution_by_fireteam")
		data["simulation_tick"] = mission.get_node("SimulationRoot").call("get_tick")
		data["scene_tree_paused"] = paused
		data["plans"] = controller.call("_serialize_order_plans")
		data["deployed_ids"] = controller.get("_deployed_unit_ids")
		data["last_command"] = controller.get("_last_command_text")
		data["interactions"] = mission.get_node("CombatLoopDriver").call("get_mission_interaction_runtime_state_snapshot")
	print("SINGLEPLAYER_LOOP_DIAGNOSTIC:", var_to_str(data))

func _check(value: bool, label: String) -> bool:
	if value:
		_passed += 1
		print("PASS: " + label)
	else:
		_failed += 1
		printerr("FAIL: " + label)
	return value

func _finish() -> void:
	if is_instance_valid(_flow):
		_flow.queue_free()
	await process_frame
	print("SINGLEPLAYER_LOOP_RESULTS passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _landing_target(map) -> Vector2:
	return map.get_marker_position("spawn_alpha")
