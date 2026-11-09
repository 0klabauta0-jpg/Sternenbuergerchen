extends SceneTree
## Actual two-sortie campaign loop. Only boarding fixture time is advanced;
## mission movement, Use progress, flight phases and completion run normally.

const FLOW: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const MAP: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const SERVICES: GDScript = preload("res://scripts/meta/singleplayer_services_presenter.gd")
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
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	if not _check(_runtime != null, "Actual Flow has long-lived campaign runtime"):
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
	_check(not bool(driver.call("_is_victory_condition_met")), "Actual satellite scene cannot win on load")
	controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
	if not await _move_and_use(mission, "satellite_data", "secure_satellite", "res://maps/satellite_crash_site.json"):
		await _finish()
		return
	_check(not bool(driver.call("_is_victory_condition_met")), "Recovered data still requires physical ship return")
	if not await _move_and_use(mission, "ship_return", "return_to_ship", "res://maps/satellite_crash_site.json"):
		await _finish()
		return
	if not await _wait(func(): return String(Dictionary(_campaign().get("jobs", {})).get("satellite_recovery", {}).get("status", "")) == "completed", 10000, "Real mission result completes accepted campaign job"):
		_dump("campaign_completion")
		await _finish()
		return
	var rewarded: Dictionary = _flow.call("get_singleplayer_snapshot")
	_check(int(rewarded.supply.credits) == int(initial.supply.credits) + 150, "Runtime reward credits exactly one data-defined payment")
	_check(Dictionary(rewarded.campaign.get("completion_receipts", {})).size() == 1, "Exactly one campaign completion receipt")
	if not await _wait_homebase():
		await _finish()
		return
	_flow.call("request_debrief_return_homebase_for_test")
	var returned: Dictionary = _flow.call("get_singleplayer_snapshot")
	_check(float(returned.supply.fuel_by_craft_id[_craft_id]) == float(initial.supply.fuel_by_craft_id[_craft_id]) - 24.0, "First actual round trip consumes outbound and reverse route fuel once")
	_check(int(returned.supply.credits) == int(rewarded.supply.credits), "Viewing result/homebase again cannot duplicate reward")
	_check(_identity(_screen.call("get_operations_snapshot")) == _identity_before, "First return preserves all original identities and portraits")
	_check(_screen.call("request_operation", "select_destination", {"location_id": "trade_outpost", "job_id": "", "request_id": "loop:trade"}).get("ok", false), "Second sortie selects trade location without combat job")
	if not await _launch_and_land("trade_outpost_visit", "res://maps/trade_outpost.json"):
		await _finish()
		return
	mission = _flow.get("_active_mission")
	controller = mission.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
	var before_service: Dictionary = _flow.call("get_singleplayer_snapshot")
	_check(not Dictionary(before_service.get("service_contexts_by_craft_id", {})).has(_craft_id), "Landing alone cannot grant trader use proof")
	if not await _move_and_use(mission, "trade_service", "service_visit", "res://maps/trade_outpost.json"):
		await _finish()
		return
	if not await _wait(func(): return Dictionary(_flow.call("get_singleplayer_snapshot").get("service_contexts_by_craft_id", {})).has(_craft_id), 3000, "Actual landed craft and completed trader Use enable service"):
		_dump("service_context_after_use")
		await _finish()
		return
	var services: Control = SERVICES.new()
	root.add_child(services)
	services.call("configure", Callable(_runtime, "get_snapshot"), Callable(_screen, "request_operation"))
	services.call("set_selected_craft", _craft_id)
	var buy: Button = services.find_child("BuySupply", true, false)
	var fuel: Button = services.find_child("RefuelCraft", true, false)
	var service_supply: Dictionary = _supply()
	if not _check(buy != null and not buy.disabled and fuel != null and not fuel.disabled, "Real bound service UI offers purchase and refuel after Use"):
		_dump("service_ui")
		services.queue_free()
		await _finish()
		return
	buy.pressed.emit()
	buy.pressed.emit()
	fuel.pressed.emit()
	fuel.pressed.emit()
	var paid: Dictionary = _supply()
	_check(int(paid.credits) == int(service_supply.credits) - 70, "Real service double-clicks debit one purchase and one ten-unit refuel")
	_check(int(Dictionary(paid.item_quantities).get("medictool", 0)) == int(Dictionary(service_supply.item_quantities).get("medictool", 0)) + 1, "Second sortie grants one real purchased item")
	_check(float(paid.fuel_by_craft_id[_craft_id]) == float(service_supply.fuel_by_craft_id[_craft_id]) + 10.0, "Confirmed actual craft gains exactly ten fuel")
	services.queue_free()
	var return_result: Dictionary = _screen.call("request_operation", "return_homebase", {"craft_id": _craft_id, "request_id": "loop:trade-return"})
	if not _check(bool(return_result.get("ok", false)), "Real visit return command accepts after service"):
		print("RETURN_RESULT:", return_result)
		_dump("trade_return")
		await _finish()
		return
	if not await _wait_homebase():
		await _finish()
		return
	_flow.call("_show_homebase")
	var final: Dictionary = _flow.call("get_singleplayer_snapshot")
	_check(float(final.supply.fuel_by_craft_id[_craft_id]) == float(initial.supply.fuel_by_craft_id[_craft_id]) - 24.0 - 16.0 + 10.0, "Two true round trips plus refuel preserve authored fuel accounting")
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
	await _finish()

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
	_screen.call("_debug_advance_homebase_direct_boarding", 30.0)
	var launch: Dictionary = _screen.call("request_operation", "start", {"craft_id": _craft_id})
	if not _check(bool(launch.get("ok", false)), scenario_id + " launches actual boarded craft"):
		print("LAUNCH_RESULT:", launch)
		_dump("launch")
		return false
	if not await _wait(func(): return _flow.get("_active_mission") != null, 12000, scenario_id + " actual mission instance exists"):
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
	var lz: Vector2 = map.get_marker_position("spawn_alpha")
	view.call("focus_world_position", lz)
	controller.call("_on_mission_dropship_card_set_lz_pressed", _craft_id)
	var placed: bool = bool(controller.call("_place_lz_from_screen_position", view.call("world_to_screen_position", lz)))
	if not _check(placed, scenario_id + " actual map click places LZ on saved reachable pad"):
		_dump("lz_pick")
		return false
	controller.call("_on_mission_dropship_card_drop_pressed", _craft_id)
	if not await _wait(func(): return _all_crew_deployed(controller) and int(mission.get_node("SimulationRoot").call("get_tick")) > 0, 30000, scenario_id + " real landing unloads all original crew into authoritative simulation"):
		_dump("actual_landing")
		return false
	_check(String(mission.get_node("MissionSetup").get("scenario_file_path")).get_file().get_basename() == scenario_id, "Selected location loads exact intended scenario " + scenario_id)
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
	controller.call("_create_waypoints_for_selected_fireteams", map.get_marker_position(interaction), true)
	if not _check(bool(controller.call("execute_selected_fireteam_orders")), interaction + " actual move GO accepts"):
		_dump("move_go")
		return false
	if not await _wait(func():
		if not is_instance_valid(controller):
			return false
		var entry: Dictionary = _find_interaction(controller.call("get_mission_interaction_runtime_use_state_snapshot"), interaction)
		return String(entry.get("runtime_use_status", "")) == "usable", 45000, interaction + " becomes usable after real simulated approach"):
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
			return PackedStringArray(driver.call("get_mission_scenario_runtime_gate_snapshot").get("completed_step_ids", [])).has(step)
		return step == "return_to_ship" and String(Dictionary(_campaign().get("jobs", {})).get("satellite_recovery", {}).get("status", "")) == "completed", 45000, interaction + " actual timed Use commits required runtime step"):
		_dump("use_execution_" + interaction)
		return false
	return true

func _wait_homebase() -> bool:
	var ready: bool = await _wait(func():
		var current: Dictionary = _flow.call("get_singleplayer_snapshot")
		var craft: Dictionary = _craft(current)
		return String(craft.get("location_id", "")) == "homebase" and not bool(craft.get("busy", true)), 35000, "Actual reverse transit restores original craft to homebase")
	if not ready:
		_dump("homebase_return")
	return ready

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
