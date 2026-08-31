extends SceneTree

const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const HPA_NAVIGATION_GRAPH_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_navigation_graph.gd")
const HPA_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_pathfinder.gd")
const GROUND_MAP_PATH: String = "res://maps/Ground_Mission01_32x32.json"
const GROUND_MISSION_ID: String = "grid_sweep"
const CENTRAL_ADVANCE_FROM_GRID: Vector2i = Vector2i(18, 20)
const CENTRAL_ADVANCE_BRIDGE_GRID: Vector2i = Vector2i(19, 20)
const CENTRAL_ADVANCE_TO_GRID: Vector2i = Vector2i(20, 20)
const SIMULATED_TICK_DELTA: float = 60.0
const MAX_OBJECTIVE_TICKS: int = 384
const MAX_DEBRIEF_FRAMES: int = 120

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1179 Ground Mission Objective Playthrough ===")
	_test_ground_map_connects_spawn_to_objective()
	await _test_homebase_to_ground_objective_result()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_ground_map_connects_spawn_to_objective() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", GROUND_MAP_PATH)
	_assert(map_data != null and not bool(map_data.call("has_load_issue")), "Ground map loads without TerrainMapData issues")
	if map_data == null:
		return
	var registry: Node = TERRAIN_REGISTRY_SCRIPT.new()
	var tile_size: Dictionary = Dictionary(map_data.call("get_tile_size"))
	registry.call(
		"configure_iso_grid",
		Vector2(map_data.call("get_grid_origin")),
		float(tile_size.get("half_width", 64.0)),
		float(tile_size.get("half_height", 32.0))
	)
	for tile_data in Array(map_data.call("get_tiles")):
		registry.call("register_tile", tile_data)
	var spawn_position: Vector2 = Vector2(map_data.call("get_marker_position", "spawn_alpha", Vector2.ZERO))
	var objective_position: Vector2 = Vector2(map_data.call("get_marker_position", "objective_point", Vector2.ZERO))
	var authored_spawn_grid: Vector2i = Vector2i(registry.call("world_to_grid", spawn_position))
	_assert(bool(registry.call("is_walkable", authored_spawn_grid)), "Ground map keeps the authored Alpha marker on walkable terrain")
	var spawn_grid: Variant = registry.call("get_nearest_walkable_grid", spawn_position)
	var objective_grid: Variant = registry.call("get_nearest_walkable_grid", objective_position)
	_assert(typeof(spawn_grid) == TYPE_VECTOR2I, "Ground map resolves Spawn Alpha to a walkable grid")
	_assert(typeof(objective_grid) == TYPE_VECTOR2I, "Ground map resolves Objective to a walkable grid")
	if typeof(spawn_grid) != TYPE_VECTOR2I or typeof(objective_grid) != TYPE_VECTOR2I:
		registry.free()
		return
	var pathfinder: RefCounted = TERRAIN_PATHFINDER_SCRIPT.new()
	var path: Array = Array(pathfinder.call("find_path", Vector2i(spawn_grid), Vector2i(objective_grid), registry))
	_assert(not path.is_empty(), "Ground map has a traversable Alpha-to-Objective route")
	var hpa_graph: RefCounted = HPA_NAVIGATION_GRAPH_SCRIPT.new()
	_assert(bool(hpa_graph.call("build_from_registry", registry, 8)), "Ground map builds an HPA navigation graph")
	var hpa_pathfinder: RefCounted = HPA_PATHFINDER_SCRIPT.new()
	var hpa_path: Array = Array(hpa_pathfinder.call("find_path", Vector2i(spawn_grid), Vector2i(objective_grid), registry, hpa_graph))
	_assert(not hpa_path.is_empty(), "Ground map has an HPA route from Alpha to Objective")
	var route_probe_result: Dictionary = Dictionary(hpa_pathfinder.call("find_path_with_status", CENTRAL_ADVANCE_FROM_GRID, CENTRAL_ADVANCE_TO_GRID, registry, hpa_graph))
	var route_probe_path: Array = Array(route_probe_result.get("path", []))
	if route_probe_path.is_empty():
		print("GROUND_MAP_HPA_CORRIDOR_PROBE from=%s bridge=%s to=%s bridge_walkable=%s from_to_legal=%s from_bridge_legal=%s bridge_to_legal=%s result=%s" % [
			String(hpa_graph.call("get_component_key_for_grid", CENTRAL_ADVANCE_FROM_GRID)),
			String(hpa_graph.call("get_component_key_for_grid", CENTRAL_ADVANCE_BRIDGE_GRID)),
			String(hpa_graph.call("get_component_key_for_grid", CENTRAL_ADVANCE_TO_GRID)),
			bool(registry.call("is_walkable", CENTRAL_ADVANCE_BRIDGE_GRID)),
			bool(pathfinder.call("can_traverse_step", CENTRAL_ADVANCE_FROM_GRID, CENTRAL_ADVANCE_TO_GRID, registry)),
			bool(pathfinder.call("can_traverse_step", CENTRAL_ADVANCE_FROM_GRID, CENTRAL_ADVANCE_BRIDGE_GRID, registry)),
			bool(pathfinder.call("can_traverse_step", CENTRAL_ADVANCE_BRIDGE_GRID, CENTRAL_ADVANCE_TO_GRID, registry)),
			JSON.stringify(route_probe_result),
		])
	_assert(not route_probe_path.is_empty(), "Ground map HPA crosses the central advance corridor")
	registry.free()


func _test_homebase_to_ground_objective_result() -> void:
	root.size = Vector2i(1920, 1080)
	var flow: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(flow)
	await _wait_frames(8)
	var homebase := flow.get_node_or_null("HomebaseScreen") as Control
	_assert(homebase != null, "Ground trace exposes Homebase")
	if homebase == null:
		await _cleanup(flow)
		return
	flow.call("_on_homebase_mission_selection_changed", GROUND_MISSION_ID)
	homebase.call("request_mission_start")
	await _wait_frames(12)

	var mission: Node = flow.call("get_active_mission")
	var controller: Node = mission.get_node_or_null("TacticalController") if mission != null else null
	var primary_view: Node = mission.get_node_or_null("Primary3DView") if mission != null else null
	var combat_driver: Node = mission.get_node_or_null("CombatLoopDriver") if mission != null else null
	var simulation_root: Node = mission.get_node_or_null("SimulationRoot") if mission != null else null
	_assert(controller != null and primary_view != null and combat_driver != null and simulation_root != null, "Ground trace exposes mission runtime")
	if controller == null or primary_view == null or combat_driver == null or simulation_root == null:
		await _cleanup(flow)
		return
	simulation_root.set("terrain_move_debug_enabled", true)
	simulation_root.call("set_local_avoidance_debug_enabled", true)

	var handoff: Dictionary = Dictionary(flow.call("get_homebase_to_mission_handoff_snapshot"))
	_assert(String(handoff.get("selected_mission_id", "")) == GROUND_MISSION_ID, "Homebase handoff preserves grid_sweep selection")
	var craft_id: String = String(Dictionary(handoff.get("planning", {})).get("mission_drop_craft_id", "")).strip_edges()
	_assert(not craft_id.is_empty(), "Ground trace receives a dropship")
	if craft_id.is_empty():
		await _cleanup(flow)
		return
	_complete_mission_craft_arrival(flow, craft_id)
	await _wait_frames(8)
	var spawn_alpha: Vector2 = Vector2(controller.call("get_mission_marker_world_position", "spawn_alpha", Vector2.ZERO))
	_assert(spawn_alpha != Vector2.ZERO, "Ground trace resolves the authored Alpha spawn")
	controller.call("_on_mission_dropship_card_set_lz_pressed", craft_id)
	_assert(bool(controller.call("_place_lz_from_screen_position", primary_view.call("world_to_screen_position", spawn_alpha))), "Ground trace places the LZ through the existing map command")
	controller.call("_on_mission_dropship_card_drop_pressed", craft_id)
	await _wait_frames(4)
	controller.call("_complete_drop_sequence_deployment")
	controller.call("_advance_primary_drop_sequence_unloading", 999.0)
	controller.call("_flush_pending_drop_runtime_phase_starts")
	await _wait_frames(8)

	var fireteam_id: String = _first_displayable_fireteam(controller)
	var objective_status = simulation_root.call("get_objective_status")
	var objective_position: Vector2 = objective_status.position if objective_status != null else Vector2.ZERO
	_assert(not fireteam_id.is_empty(), "Ground trace has a deboarded Fireteam")
	_assert(objective_position != Vector2.ZERO, "Ground trace exposes the authoritative objective position")
	if fireteam_id.is_empty() or objective_position == Vector2.ZERO:
		await _cleanup(flow)
		return
	_assert(bool(controller.call("issue_right_click_command_for_test", objective_position, "take", false)), "Ground trace plans a normal Take order")
	_assert(bool(controller.call("execute_selected_fireteam_orders")), "Ground trace commits Take through GO")

	var reached_objective: bool = false
	var objective_tick_count: int = 0
	for tick_index in range(MAX_OBJECTIVE_TICKS):
		objective_tick_count = tick_index + 1
		simulation_root.call("_physics_process", SIMULATED_TICK_DELTA)
		controller.call("_update_fireteam_suppression", SIMULATED_TICK_DELTA)
		controller.call("_update_active_phase_execution", SIMULATED_TICK_DELTA)
		combat_driver.call("_update_contact_tracking")
		combat_driver.call("_advance_detection_timers")
		await process_frame
		if not is_instance_valid(simulation_root) or not is_instance_valid(combat_driver):
			reached_objective = true
			break
		objective_status = simulation_root.call("get_objective_status")
		reached_objective = objective_status != null and String(objective_status.owning_team_id) == "team_alpha" and float(objective_status.capture_progress) >= 1.0
		if reached_objective:
			break

	var mission_runtime_valid := is_instance_valid(controller) and is_instance_valid(simulation_root) and is_instance_valid(combat_driver)
	var movement_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", fireteam_id)) if mission_runtime_valid else {}
	var movement_trace: Dictionary = Dictionary(controller.call("get_recent_fireteam_movement_trace", fireteam_id)) if mission_runtime_valid else {}
	var execution_path: Dictionary = Dictionary(controller.call("get_fireteam_runtime_execution_path_snapshot")) if mission_runtime_valid else {}
	var phase_executions: Dictionary = Dictionary(controller.get("_phase_execution_by_fireteam")).duplicate(true) if mission_runtime_valid else {}
	var order_plans: Dictionary = Dictionary(controller.get("_order_plans_by_key")).duplicate(true) if mission_runtime_valid else {}
	var member_states: Array = []
	var fireteam_units: Array = Array(controller.call("_get_fireteam_units", fireteam_id, true)) if mission_runtime_valid else []
	for unit_variant in fireteam_units:
		var unit = unit_variant as Node2D
		if unit == null:
			continue
		member_states.append({
			"unit_id": String(unit.call("get_unit_id")) if unit.has_method("get_unit_id") else unit.name,
			"vital_state": String(unit.call("get_vital_state")) if unit.has_method("get_vital_state") else "unknown",
			"position": unit.global_position,
			"command": _unit_command_snapshot(unit),
		})
	var contact_snapshot: Dictionary = Dictionary(controller.call("get_mission_first_contact_readability_snapshot")) if mission_runtime_valid else {}
	var command_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot")) if mission_runtime_valid else {}
	var mission_result: Dictionary = Dictionary(combat_driver.call("get_mission_result")) if mission_runtime_valid else {}
	var final_objective: Dictionary = Dictionary(objective_status.call("to_dict")) if objective_status != null else {}
	if not reached_objective or String(mission_result.get("result", "")) != "victory":
		print("GROUND_OBJECTIVE_TRACE ticks=%d reached=%s result=%s" % [objective_tick_count, reached_objective, String(mission_result.get("result", ""))])
		print("GROUND_OBJECTIVE_DIAGNOSTIC owner=%s progress=%.2f result=%s fireteam=%s executing=%s stage=%s anchor=%s final=%s" % [String(final_objective.get("owning_team_id", "")), float(final_objective.get("capture_progress", 0.0)), String(mission_result.get("result", "")), fireteam_id, bool(movement_state.get("is_executing", false)), int(movement_state.get("stage_index", -1)), Vector2(movement_state.get("current_anchor_target_position", Vector2.ZERO)), Vector2(movement_state.get("final_target_position", Vector2.ZERO))])
		print("GROUND_OBJECTIVE_MOVEMENT_TRACE %s" % JSON.stringify(movement_trace))
		print("GROUND_OBJECTIVE_EXECUTION_PATH %s" % JSON.stringify(execution_path))
		print("GROUND_OBJECTIVE_INTERNAL execution=%s plans=%s" % [JSON.stringify(phase_executions), JSON.stringify(order_plans)])
		print("GROUND_OBJECTIVE_MEMBER_STATES %s" % JSON.stringify(member_states))
		print("GROUND_OBJECTIVE_MOVE_DISCARDS %s" % JSON.stringify(simulation_root.call("get_discarded_move_command_debug_snapshot")) if mission_runtime_valid and simulation_root.has_method("get_discarded_move_command_debug_snapshot") else "GROUND_OBJECTIVE_MOVE_DISCARDS unavailable")
		print("GROUND_OBJECTIVE_NAVIGATION %s" % JSON.stringify(simulation_root.call("get_navigation_debug_snapshot")) if mission_runtime_valid and simulation_root.has_method("get_navigation_debug_snapshot") else "GROUND_OBJECTIVE_NAVIGATION unavailable")
		print("GROUND_OBJECTIVE_AVOIDANCE %s" % JSON.stringify(simulation_root.call("get_local_avoidance_debug_snapshot")) if mission_runtime_valid and simulation_root.has_method("get_local_avoidance_debug_snapshot") else "GROUND_OBJECTIVE_AVOIDANCE unavailable")
		print("GROUND_OBJECTIVE_CONTACT selected=%d feedback=%s" % [int(contact_snapshot.get("selected_contact_count", 0)), String(command_feedback.get("execution_feedback_text", ""))])
	_assert(reached_objective, "Ground trace reaches the objective through existing movement and capture")
	await _wait_until(func() -> bool:
		return bool(flow.call("get_debrief_return_homebase_handoff_snapshot").get("mission_result_preserved", false)), MAX_DEBRIEF_FRAMES)
	var debrief_snapshot: Dictionary = Dictionary(flow.call("get_debrief_return_homebase_handoff_snapshot"))
	var last_result: Dictionary = Dictionary(debrief_snapshot.get("last_mission_result", {}))
	var debrief_result: Dictionary = Dictionary(debrief_snapshot.get("debrief_mission_result", {}))
	_assert(debrief_result == last_result, "Debrief and retained mission result stay identical")
	_assert(String(debrief_result.get("result", "")) == "victory" and bool(debrief_result.get("objective_captured", false)), "Ground trace preserves the authoritative objective victory")
	_assert(bool(debrief_snapshot.get("mission_result_preserved", false)) and bool(debrief_snapshot.get("active_mission_released", false)) and bool(debrief_snapshot.get("debrief_visible", false)), "Ground trace releases into visible debrief with result preserved")
	await _cleanup(flow)


func _complete_mission_craft_arrival(flow: Node, craft_id: String) -> void:
	flow.call("_remove_pending_mission_craft_transfer", craft_id)
	flow.call("_complete_mission_craft_transfer", {"craft_id": craft_id, "phase": "to_mission"})
	flow.call("_sync_homebase_direct_mission_drop_transport_fields")
	flow.call("_start_or_update_active_mission")


func _first_displayable_fireteam(controller: Node) -> String:
	for fireteam_id_variant in Array(controller.call("_get_displayable_fireteam_ids")):
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if not fireteam_id.is_empty():
			return fireteam_id
	return ""


func _cleanup(flow: Node) -> void:
	if is_instance_valid(flow):
		flow.queue_free()
	await _wait_frames(2)


func _unit_command_snapshot(unit: Node) -> Dictionary:
	if unit == null or not unit.has_method("get_current_unit_command"):
		return {}
	var command = unit.call("get_current_unit_command")
	if command == null:
		return {}
	if command.has_method("to_dict"):
		return Dictionary(command.call("to_dict")).duplicate(true)
	if typeof(command) == TYPE_DICTIONARY:
		return Dictionary(command).duplicate(true)
	return {}


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _wait_until(predicate: Callable, max_frames: int) -> bool:
	for _index in range(maxi(max_frames, 0)):
		if bool(predicate.call()):
			return true
		await process_frame
	return bool(predicate.call())


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
