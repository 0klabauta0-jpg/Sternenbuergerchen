extends SceneTree

const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const SCENARIO = preload("res://scripts/mission/mission_scenario_data.gd")
const SLICE = preload("res://scripts/mission/mission_scenario_vertical_slice_contract.gd")
const BINDINGS = preload("res://scripts/mission/mission_interaction_point_binding.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const PATHFINDER = preload("res://scripts/terrain/terrain_pathfinder.gd")
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const SIM = preload("res://scripts/core/simulation_root.gd")
const OBJECTIVE = preload("res://scripts/core/objective_status.gd")
const DRIVER = preload("res://scripts/tests/mission_combat_loop_driver.gd")
const MISSION = preload("res://scenes/tests/mission_reactivity_test.tscn")
const SATELLITE = "res://data/mission_scenarios/satellite_recovery.json"
const TRADE = "res://data/mission_scenarios/trade_outpost_visit.json"
var passed: int = 0
var failed: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_opt_in_validation()
	_expect(FileAccess.file_exists(SATELLITE), "Satellite scenario is real authored content")
	_expect(FileAccess.file_exists(TRADE), "Trading visit is a separate authored scenario")
	if FileAccess.file_exists(SATELLITE) and FileAccess.file_exists(TRADE):
		_test_content(SATELLITE, "satellite_crash_site", ["satellite_data", "ship_return"])
		_test_content(TRADE, "trade_outpost", ["trade_service"])
		await _test_runtime_gate_sequence()
		if not OS.get_cmdline_user_args().has("--content-only"):
			await _test_mission_setup_no_fake_enemies()
	print("SATELLITE_RECOVERY: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _test_opt_in_validation() -> void:
	var raw: Dictionary = {"scenario_kind": "singleplayer_job", "play_modes": ["singleplayer"], "team_slots": [{"team_id": "team_alpha", "spawn_marker_id": "spawn_alpha"}], "flow_steps": [{"step_id": "secure_satellite", "objective_type": "interaction_use", "target_marker_id": "objective_point", "required_state": "satellite_secured"}], "interaction_points": [{"interaction_id": "satellite_data", "interaction_type": "computer", "marker_id": "objective_point", "required_order": "take", "radius_world": 96.0, "step_id": "secure_satellite"}]}
	var map = MAP.load_from_file("res://maps/fireteam_command_drill_24x24.json")
	var normalized: Dictionary = SLICE.normalize_slice(raw)
	_expect(bool(SLICE.validate_slice(normalized, map).valid), "Explicit singleplayer Use slice validates without unrelated AA/cargo/PvP objectives")
	var scenario_raw: Dictionary = {"scenario_id": "fixture", "display_name": "Fixture", "map_file_path": "res://maps/fireteam_command_drill_24x24.json", "objective": {"marker_id": "objective_point", "capture_radius": 80.0}, "enemy_groups": [], "wave_config": {"wave_count": 0, "units_per_wave": 1}, "vertical_slice": raw.duplicate(true)}
	_expect(bool(SCENARIO.from_dict(scenario_raw).validate().valid), "Explicit enemy-free Use scenario validates through real scenario loader")
	scenario_raw.wave_config.wave_count = 1
	_expect(not bool(SCENARIO.from_dict(scenario_raw).validate().valid), "Enemy-free opt-in cannot hide configured combat waves")
	scenario_raw.wave_config.wave_count = 0
	scenario_raw.vertical_slice.erase("scenario_kind")
	_expect(not bool(SCENARIO.from_dict(scenario_raw).validate().valid), "Historical scenario still rejects an absent enemy roster")
	raw.erase("scenario_kind")
	_expect(not bool(SLICE.validate_slice(SLICE.normalize_slice(raw), map).valid), "Historical slice requirements remain enforced without explicit opt-in")

func _test_content(path: String, map_name: String, interaction_ids: Array) -> void:
	var scenario = SCENARIO.load_from_file(path)
	var validation: Dictionary = scenario.validate()
	_expect(bool(validation.valid), "%s loader validates: %s" % [map_name, validation.errors])
	_expect(scenario.get_enemy_ids().is_empty(), "%s needs no invented enemy roster" % map_name)
	var map = MAP.load_from_file(scenario.map_file_path)
	_expect(map.get_grid_topology() == "hex_axial_v1" and not map.has_load_issue(), "%s is a native authored hex map" % map_name)
	var slice: Dictionary = SLICE.load_slice_from_file(path)
	_expect(bool(SLICE.validate_slice(slice, map).valid), "%s slice references actual markers and explicit Use gates" % map_name)
	var view: CanvasLayer = VIEW.new()
	root.add_child(view)
	view.call("configure_from_map", map)
	var render: Dictionary = view.call("get_render_snapshot")
	_expect(int(render.get("missing_map_asset_mapping_count", -1)) == 0, "%s native catalog visuals have no missing map mappings" % map_name)
	view.queue_free()
	var registry = REGISTRY.new()
	root.add_child(registry)
	var sizes: Dictionary = map.get_tile_size()
	registry.configure_iso_grid(map.get_grid_origin(), sizes.half_width, sizes.half_height, map.get_grid_topology())
	for tile in map.get_tiles():
		registry.register_tile(tile)
	var start: Vector2i = registry.world_to_grid(map.get_marker_position("spawn_alpha"))
	var bindings: Dictionary = BINDINGS.load_snapshot_from_file(path, map)
	_expect(bool(bindings.valid), "%s interaction bindings validate" % map_name)
	for id in interaction_ids:
		var binding: Dictionary = _find(bindings.bindings, "interaction_id", id)
		_expect(not binding.is_empty(), "%s contains real %s interaction" % [map_name, id])
		if not binding.is_empty():
			var target: Vector2i = registry.world_to_grid(map.get_marker_position(binding.marker_id))
			_expect(not PATHFINDER.new().find_path(start, target, registry).is_empty(), "%s %s has a reachable use point from LZ" % [map_name, id])
	registry.queue_free()

func _test_runtime_gate_sequence() -> void:
	var sim: Node = SIM.new()
	sim.name = "SatelliteSimulation"
	root.add_child(sim)
	var objective = OBJECTIVE.new()
	objective.owning_team_id = "team_alpha"
	objective.capture_progress = 1.0
	sim.call("set_objective_status", objective)
	var driver: Node = DRIVER.new()
	driver.name = "SatelliteDriver"
	driver.set("simulation_root_path", NodePath("../SatelliteSimulation"))
	root.add_child(driver)
	await process_frame
	_expect(bool(driver.call("configure_scenario_runtime_gates_from_file", SATELLITE)), "Real combat driver loads satellite runtime gates")
	_expect(not bool(driver.call("_is_victory_condition_met")), "Captured objective and no enemies cannot win on load")
	var initial: Dictionary = driver.call("get_mission_scenario_runtime_gate_snapshot")
	var bindings: Dictionary = BINDINGS.load_snapshot_from_file(SATELLITE, null, {"scenario_gate_snapshot": initial})
	_expect(bool(_find(bindings.bindings, "interaction_id", "ship_return").blocked), "Ship-return Use is blocked until satellite recovery")
	driver.call("update_mission_interaction_runtime_progress", _progress("satellite_data", "secure_satellite", "satellite_secured", 1.0, 3.0))
	_expect(not bool(driver.call("_is_victory_condition_met")), "Partial recovery Use cannot complete the job")
	driver.call("update_mission_interaction_runtime_progress", _progress("satellite_data", "secure_satellite", "satellite_secured", 3.0, 3.0))
	_expect(not bool(driver.call("_is_victory_condition_met")), "Recovered data still requires return to ship")
	var recovered: Dictionary = driver.call("get_mission_scenario_runtime_gate_snapshot")
	_expect(PackedStringArray(recovered.completed_step_ids).has("secure_satellite") and not PackedStringArray(recovered.completed_step_ids).has("return_to_ship"), "Recovery confirms only the matching real step")
	driver.call("update_mission_interaction_runtime_progress", _progress("ship_return", "return_to_ship", "crew_returned", 2.0, 2.0))
	_expect(bool(driver.call("_is_victory_condition_met")), "Completed recovery and ship-return Uses satisfy real victory gate")
	var final_gates: Dictionary = driver.call("get_mission_scenario_runtime_gate_snapshot")
	_expect(bool(final_gates.all_gates_complete) and PackedStringArray(final_gates.completed_step_ids).size() == 2, "Campaign proof exposes exactly the two completed required steps")
	driver.call("configure_scenario_runtime_gates_from_file", SATELLITE)
	_expect(not bool(driver.call("_is_victory_condition_met")), "A fresh sortie resets previous objective completion")
	driver.call("configure_scenario_runtime_gates_from_file", TRADE)
	_expect(not bool(driver.call("_is_victory_condition_met")), "Trade visit does not become an elimination auto-win")
	driver.call("update_mission_interaction_runtime_progress", _progress("trade_service", "service_visit", "service_visited", 1.0, 1.0))
	_expect(not bool(driver.call("_is_victory_condition_met")), "Using trader service cannot debrief before actual return")
	driver.queue_free()
	sim.queue_free()
	await process_frame

func _test_mission_setup_no_fake_enemies() -> void:
	var scene: Node = MISSION.instantiate()
	var setup: Node = scene.get_node("MissionSetup")
	setup.set("map_file_path", "res://maps/satellite_crash_site.json")
	setup.set("scenario_file_path", SATELLITE)
	setup.set("defer_friendly_runtime_activation", false)
	setup.set("selected_team_unit_ids", PackedStringArray(["unit_alpha", "unit_bravo", "unit_charlie"]))
	setup.set("selected_team_fireteam_ids", PackedStringArray(["ft1", "ft1", "ft1"]))
	root.add_child(scene)
	await process_frame
	await physics_frame
	var enemy_ids: PackedStringArray = PackedStringArray()
	for unit in scene.get_node("UnitRegistry").call("get_all_units"):
		if unit.has_method("get_team_id") and String(unit.call("get_team_id")) == "team_bravo":
			enemy_ids.append(String(unit.call("get_unit_id")))
	_expect(enemy_ids.is_empty(), "Actual scenario setup disables fallback enemy slots for explicit peaceful recovery")
	var expected_presence: Dictionary = setup.call("get_expected_unit_presence_snapshot")
	_expect(Array(expected_presence.get("enemy_unit_ids", [])).is_empty(), "Readiness expects no disabled fallback enemies in the peaceful scenario")
	if not Array(expected_presence.get("enemy_unit_ids", [])).is_empty():
		scene.queue_free()
		await process_frame
		return
	_expect(not bool(scene.get_node("CombatLoopDriver").call("_is_victory_condition_met")), "Actual mission scene remains unresolved before real Use")
	var render: Dictionary = scene.get_node("Primary3DView").call("get_render_snapshot")
	_expect(int(render.get("missing_map_asset_mapping_count", -1)) == 0, "Authored terrain and salvage use mapped native assets without magenta fallback blockers")
	if int(render.get("missing_map_asset_mapping_count", -1)) != 0:
		scene.queue_free()
		await process_frame
		return
	var controller: Node = scene.get_node("TacticalController")
	var ids: PackedStringArray = controller.call("_get_available_fireteam_ids")
	_expect(not ids.is_empty(), "Actual scenario activates a selectable recovery fireteam")
	if not ids.is_empty():
		controller.call("_set_selected_fireteams", PackedStringArray([ids[0]]), false)
		_expect(not bool(controller.call("create_selected_mission_interaction_use_intent", "ship_return").get("accepted", true)), "Real controller rejects return Use before recovery")
		var map = MAP.load_from_file("res://maps/satellite_crash_site.json")
		var data_position: Vector2 = map.get_marker_position("satellite_data")
		controller.call("_create_waypoints_for_selected_fireteams", data_position, true)
		_expect(bool(controller.call("execute_selected_fireteam_orders")), "Real move/GO starts the recovery approach")
		await _wait_usable(controller, "satellite_data", 60000)
		var intent: Dictionary = controller.call("create_selected_mission_interaction_use_intent", "satellite_data")
		_expect(bool(intent.get("accepted", false)), "Use becomes available after actual simulated approach")
		if bool(intent.get("accepted", false)):
			_expect(bool(controller.call("execute_selected_fireteam_orders")), "Real GO accepts the timed recovery Use")
			await _wait_step(scene.get_node("CombatLoopDriver"), "secure_satellite", 60000)
			var gates: Dictionary = scene.get_node("CombatLoopDriver").call("get_mission_scenario_runtime_gate_snapshot")
			if not PackedStringArray(gates.get("completed_step_ids", [])).has("secure_satellite"):
				print("USE_DIAGNOSTIC:", var_to_str({"positions": _positions(scene), "intent": intent, "plans": controller.call("_serialize_order_plans"), "execution": controller.get("_phase_execution_by_fireteam"), "movement": controller.call("get_fireteam_movement_snapshot"), "interactions": scene.get_node("CombatLoopDriver").call("get_mission_interaction_runtime_state_snapshot")}))
			_expect(PackedStringArray(gates.get("completed_step_ids", [])).has("secure_satellite"), "Actual timed Use execution produces verified recovery state")
			_expect(not bool(gates.get("all_gates_complete", true)), "Actual recovery still requires physical ship return")
			if PackedStringArray(gates.get("completed_step_ids", [])).has("secure_satellite"):
				controller.call("_create_waypoints_for_selected_fireteams", map.get_marker_position("ship_return"), true)
				controller.call("execute_selected_fireteam_orders")
				await _wait_usable(controller, "ship_return", 60000)
				var return_intent: Dictionary = controller.call("create_selected_mission_interaction_use_intent", "ship_return")
				_expect(bool(return_intent.get("accepted", false)), "Physical return makes ship-return Use available")
				if bool(return_intent.get("accepted", false)):
					_expect(bool(controller.call("execute_selected_fireteam_orders")), "Real GO accepts the return console Use")
					await _wait_step(scene.get_node("CombatLoopDriver"), "return_to_ship", 60000)
					gates = scene.get_node("CombatLoopDriver").call("get_mission_scenario_runtime_gate_snapshot")
					if not bool(gates.get("all_gates_complete", false)):
						print("RETURN_DIAGNOSTIC:", var_to_str({"positions": _positions(scene), "intent": return_intent, "plans": controller.call("_serialize_order_plans"), "execution": controller.get("_phase_execution_by_fireteam"), "movement": controller.call("get_fireteam_movement_snapshot"), "interactions": scene.get_node("CombatLoopDriver").call("get_mission_interaction_runtime_state_snapshot")}))
					_expect(bool(gates.get("all_gates_complete", false)), "Actual simulated round trip plus timed ship-return Use completes both objectives")
	scene.queue_free()
	await process_frame

func _wait_usable(controller: Node, interaction: String, milliseconds: int) -> void:
	var deadline: int = Time.get_ticks_msec() + milliseconds
	while Time.get_ticks_msec() < deadline:
		var snapshot: Dictionary = controller.call("get_mission_interaction_runtime_use_state_snapshot")
		var entry: Dictionary = _find(snapshot.get("interactions", []), "interaction_id", interaction)
		if String(entry.get("runtime_use_status", "")) == "usable":
			return
		await process_frame

func _wait_step(driver: Node, step: String, milliseconds: int) -> void:
	var deadline: int = Time.get_ticks_msec() + milliseconds
	while Time.get_ticks_msec() < deadline:
		var gates: Dictionary = driver.call("get_mission_scenario_runtime_gate_snapshot")
		if PackedStringArray(gates.get("completed_step_ids", [])).has(step):
			return
		await process_frame

func _progress(id: String, step: String, required: String, seconds: float, duration: float) -> Dictionary:
	return {"interaction_id": id, "state": "operating", "hold_seconds": seconds, "duration_seconds": duration, "fireteam_id": "ft1", "team_id": "team_alpha", "step_id": step, "required_state": required, "interaction_type": "computer", "command_type": "take"}

func _positions(scene: Node) -> Dictionary:
	var positions: Dictionary = {}
	for unit in scene.get_node("UnitRegistry").call("get_all_units"):
		if unit is Node2D and unit.has_method("get_unit_id"):
			positions[String(unit.call("get_unit_id"))] = unit.global_position
	return positions

func _find(entries: Array, key: String, value: String) -> Dictionary:
	for entry in entries:
		if String(entry.get(key, "")) == value:
			return entry
	return {}

func _expect(ok: bool, message: String) -> void:
	if ok:
		passed += 1
		print("PASS: " + message)
	else:
		failed += 1
		push_error("FAIL: " + message)
