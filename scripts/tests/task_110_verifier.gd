extends SceneTree

const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const FIRETEAM_BEHAVIOR_PROFILE_SCRIPT: GDScript = preload("res://scripts/command/fireteam_behavior_profile.gd")
const FIRETEAM_WAYPOINT_SCRIPT: GDScript = preload("res://scripts/command/fireteam_waypoint.gd")
const FIRETEAM_ORDER_VISUALIZER_SCRIPT: GDScript = preload("res://scripts/tactical/visuals/fireteam_order_visualizer.gd")
const EVENT_ROUTER_SCRIPT: GDScript = preload("res://scripts/core/event_router.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0
var _bound_events: Array = []


class SimulationStub:
	extends RefCounted
	var commands: Array = []

	func enqueue_command(command_dict: Dictionary) -> void:
		var command_token: String = String(command_dict.get("command_token", "")).strip_edges()
		if not command_token.is_empty():
			for index in range(commands.size()):
				if String(Dictionary(commands[index]).get("command_token", "")).strip_edges() == command_token:
					commands[index] = command_dict.duplicate(true)
					return
		commands.append(command_dict.duplicate(true))


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_110 Fireteam Movement Controller Verifier ===")
	_test_rush_moves_all_fit_members_with_cohesion_clamp()
	_test_unreached_stage_relies_on_simulation_requeue()
	_test_move_travel_uses_compact_intermediate_formation()
	_test_bounding_rotates_cover_and_movement_groups()
	_test_bounding_keeps_bound_anchor_until_lead_moves()
	_test_caterpillar_moves_one_member_at_a_time()
	_test_losses_simplify_coordinated_patterns_to_rush()
	_test_bound_complete_event_router_contract()
	_test_order_visualizer_uses_command_line_colors()
	await _test_scene_exposes_runtime_movement_snapshot()
	await _test_go_button_starts_planned_fireteam_execution()
	await _test_e_key_starts_planned_fireteam_execution()
	await _test_go_button_does_not_restart_active_defend_execution()
	await _test_go_button_continues_from_defend_to_next_waypoint()
	await _test_fireteam_panel_runs_in_direct_order_mode()
	await _test_selected_fireteam_panel_shows_current_waypoint_details()
	await _test_go_button_moves_meta_fireteam_id()
	await _test_go_button_moves_all_selected_meta_fireteam_ids()
	await _test_live_fireteam_go_moves_lead_and_members_without_snapback()
	await _test_live_move_continues_after_initial_go_without_repress()
	await _test_live_move_waits_for_members_after_lead_reaches_target()
	await _test_live_planning_echo_keeps_go_execution_running()
	await _test_planning_state_echo_does_not_redeploy_moving_fireteam()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_rush_moves_all_fit_members_with_cohesion_clamp() -> void:
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var leader = _make_unit("rush_lead", "blue", true, Vector2(0.0, 0.0), 0.72, 0.55, 0.6, 0.6, ["aggressive"])
	var wing_a = _make_unit("rush_a", "blue", false, Vector2(-96.0, 0.0), 0.95, 0.35, 0.35, 0.5, [])
	var wing_b = _make_unit("rush_b", "blue", false, Vector2(112.0, 0.0), 0.25, 0.82, 0.25, 0.45, [])
	var profile = _make_profile("blue", "rush", 32.0)
	var result: Dictionary = controller.start_execution("blue", "move", 1, Vector2(260.0, 120.0), profile, [leader, wing_a, wing_b], leader, simulation)
	_assert(bool(result.get("started", false)), "Rush execution starts successfully")
	var movement_state: Dictionary = Dictionary(result.get("movement_state", {}))
	_assert(PackedStringArray(movement_state.get("current_moving_unit_ids", PackedStringArray())).size() == 3, "Rush moves all fit members at the same time")
	var move_speed_factors: Array = []
	for command_dict in simulation.commands:
		var command: Dictionary = Dictionary(command_dict)
		move_speed_factors.append(float(command.get("move_speed_factor", -1.0)))
		_assert(bool(command.get("requeue_until_target", false)), "Rush move command is requeued by SimulationRoot until target")
		_assert(not String(command.get("command_token", "")).is_empty(), "Rush move command carries a FireteamMovement token")
	_assert(_all_close(move_speed_factors), "Rush clamps movers to a shared speed when cohesion is already broken")
	_cleanup_units([leader, wing_a, wing_b])


func _test_unreached_stage_relies_on_simulation_requeue() -> void:
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var leader = _make_unit("requeue_lead", "blue", true, Vector2(0.0, 0.0), 0.72, 0.55, 0.6, 0.6, ["steady"])
	var wing_a = _make_unit("requeue_a", "blue", false, Vector2(-20.0, 10.0), 0.68, 0.55, 0.35, 0.5, [])
	var wing_b = _make_unit("requeue_b", "blue", false, Vector2(20.0, 10.0), 0.68, 0.55, 0.35, 0.5, [])
	var profile = _make_profile("blue", "rush", 96.0)
	controller.start_execution("blue", "move", 1, Vector2(420.0, 0.0), profile, [leader, wing_a, wing_b], leader, simulation)
	var initial_command_count: int = simulation.commands.size()
	controller.update_execution("blue", [leader, wing_a, wing_b], leader, simulation)
	_assert(initial_command_count > 0, "Fireteam movement issues commands when a stage starts")
	_assert(simulation.commands.size() == initial_command_count, "Unreached Fireteam stage does not pulse duplicate commands every update")
	_cleanup_units([leader, wing_a, wing_b])


func _test_move_travel_uses_compact_intermediate_formation() -> void:
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var leader = _make_unit("compact_lead", "blue", true, Vector2(0.0, 0.0), 0.72, 0.55, 0.6, 0.6, ["steady"])
	var wing_a = _make_unit("compact_a", "blue", false, Vector2(-28.0, 12.0), 0.68, 0.55, 0.35, 0.5, [])
	var wing_b = _make_unit("compact_b", "blue", false, Vector2(28.0, 12.0), 0.68, 0.55, 0.35, 0.5, [])
	var profile = _make_profile("blue", "rush", 96.0)
	var result: Dictionary = controller.start_execution("blue", "move", 1, Vector2(520.0, 0.0), profile, [leader, wing_a, wing_b], leader, simulation)
	var movement_state: Dictionary = Dictionary(result.get("movement_state", {}))
	var target_spread: float = _compute_target_spread(Dictionary(movement_state.get("current_target_positions", {})))
	var min_speed: float = 999.0
	for command_dict in simulation.commands:
		min_speed = minf(min_speed, float(Dictionary(command_dict).get("move_speed_factor", 0.0)))
	_assert(target_spread <= 35.0, "Move travel keeps intermediate formation compact around the shared route anchor")
	_assert(min_speed >= 0.9, "Move travel uses a brisk movement speed after area release")
	_cleanup_units([leader, wing_a, wing_b])


func _test_bounding_rotates_cover_and_movement_groups() -> void:
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var leader = _make_unit("bound_lead", "blue", true, Vector2(0.0, 0.0), 0.5, 0.45, 0.82, 0.55, ["steady"])
	var scout = _make_unit("bound_scout", "blue", false, Vector2(-24.0, 10.0), 0.94, 0.3, 0.35, 0.42, [])
	var marksman = _make_unit("bound_marksman", "blue", false, Vector2(20.0, 12.0), 0.42, 0.96, 0.3, 0.44, [])
	var rifleman = _make_unit("bound_rifleman", "blue", false, Vector2(8.0, 30.0), 0.58, 0.46, 0.28, 0.48, [])
	var profile = _make_profile("blue", "bounding", 96.0)
	var result: Dictionary = controller.start_execution("blue", "move", 1, Vector2(460.0, 120.0), profile, [leader, scout, marksman, rifleman], leader, simulation)
	var movement_state: Dictionary = Dictionary(result.get("movement_state", {}))
	var moving_ids: PackedStringArray = PackedStringArray(movement_state.get("current_moving_unit_ids", PackedStringArray()))
	var covering_ids: PackedStringArray = PackedStringArray(movement_state.get("current_covering_unit_ids", PackedStringArray()))
	_assert(moving_ids.has("bound_scout"), "Bounding sends the fastest member in the first movement group")
	_assert(covering_ids.has("bound_lead"), "Bounding keeps the lead in the covering group until the final bound")
	_assert(covering_ids.has("bound_marksman"), "Bounding prefers the most accurate member for the covering group")
	_move_units_to_targets([leader, scout, marksman, rifleman], Dictionary(movement_state.get("current_target_positions", {})), moving_ids)
	var update_result: Dictionary = controller.update_execution("blue", [leader, scout, marksman, rifleman], leader, simulation)
	_assert(not Dictionary(update_result.get("bound_complete", {})).is_empty(), "Bounding emits an explicit bound_complete payload after the movement group reaches its bound")
	var next_state: Dictionary = Dictionary(update_result.get("movement_state", {}))
	var next_moving_ids: PackedStringArray = PackedStringArray(next_state.get("current_moving_unit_ids", PackedStringArray()))
	_assert(next_moving_ids.has("bound_lead"), "Bounding rotates to the next group after a completed bound")
	_cleanup_units([leader, scout, marksman, rifleman])


func _test_bounding_keeps_bound_anchor_until_lead_moves() -> void:
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var leader = _make_unit("anchor_lead", "blue", true, Vector2(0.0, 0.0), 0.5, 0.45, 0.82, 0.55, ["steady"])
	var scout = _make_unit("anchor_scout", "blue", false, Vector2(-24.0, 10.0), 0.94, 0.3, 0.35, 0.42, [])
	var marksman = _make_unit("anchor_marksman", "blue", false, Vector2(20.0, 12.0), 0.42, 0.96, 0.3, 0.44, [])
	var rifleman = _make_unit("anchor_rifleman", "blue", false, Vector2(8.0, 30.0), 0.58, 0.46, 0.28, 0.48, [])
	var profile = _make_profile("blue", "bounding", 96.0)
	var result: Dictionary = controller.start_execution("blue", "move", 1, Vector2(460.0, 120.0), profile, [leader, scout, marksman, rifleman], leader, simulation)
	var movement_state: Dictionary = Dictionary(result.get("movement_state", {}))
	var first_anchor: Vector2 = Vector2(movement_state.get("current_anchor_target_position", Vector2.ZERO))
	var first_moving_ids: PackedStringArray = PackedStringArray(movement_state.get("current_moving_unit_ids", PackedStringArray()))
	_move_units_to_targets([leader, scout, marksman, rifleman], Dictionary(movement_state.get("current_target_positions", {})), first_moving_ids)
	var update_result: Dictionary = controller.update_execution("blue", [leader, scout, marksman, rifleman], leader, simulation)
	var next_state: Dictionary = Dictionary(update_result.get("movement_state", {}))
	var next_moving_ids: PackedStringArray = PackedStringArray(next_state.get("current_moving_unit_ids", PackedStringArray()))
	var next_anchor: Vector2 = Vector2(next_state.get("current_anchor_target_position", Vector2.ZERO))
	var next_targets: Dictionary = Dictionary(next_state.get("current_target_positions", {}))
	_assert(next_moving_ids.has("anchor_lead"), "Bounding moves the FTL on the second group of the same bound")
	_assert(next_anchor.distance_to(first_anchor) <= 0.1, "Bounding keeps the same bound anchor until the FTL group catches up")
	_assert(Vector2(next_targets.get("anchor_lead", Vector2.ZERO)).distance_to(first_anchor) <= 0.1, "FTL target is the current bound anchor, not a later virtual anchor")
	_move_units_to_targets([leader, scout, marksman, rifleman], next_targets, next_moving_ids)
	var next_update_result: Dictionary = controller.update_execution("blue", [leader, scout, marksman, rifleman], leader, simulation)
	var third_state: Dictionary = Dictionary(next_update_result.get("movement_state", {}))
	var third_anchor: Vector2 = Vector2(third_state.get("current_anchor_target_position", first_anchor))
	_assert(third_anchor.distance_to(first_anchor) > 1.0, "Bounding advances to the next anchor only after both groups completed the bound")
	_cleanup_units([leader, scout, marksman, rifleman])


func _test_caterpillar_moves_one_member_at_a_time() -> void:
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var leader = _make_unit("cat_lead", "gold", true, Vector2(0.0, 0.0), 0.46, 0.45, 0.75, 0.42, ["cautious"])
	var scout = _make_unit("cat_scout", "gold", false, Vector2(-20.0, 8.0), 0.91, 0.38, 0.34, 0.38, [])
	var support = _make_unit("cat_support", "gold", false, Vector2(18.0, 14.0), 0.54, 0.81, 0.3, 0.4, [])
	var profile = _make_profile("gold", "creep", 88.0)
	var result: Dictionary = controller.start_execution("gold", "move", 1, Vector2(320.0, 220.0), profile, [leader, scout, support], leader, simulation)
	var movement_state: Dictionary = Dictionary(result.get("movement_state", {}))
	var moving_ids: PackedStringArray = PackedStringArray(movement_state.get("current_moving_unit_ids", PackedStringArray()))
	_assert(String(movement_state.get("effective_style", "")) == "caterpillar", "Creep-style profiles execute as the caterpillar movement pattern")
	_assert(moving_ids.size() == 1, "Caterpillar advances only one member at a time")
	_assert(String(moving_ids[0]) == "cat_scout", "Caterpillar starts with the fastest moving member")
	_move_units_to_targets([leader, scout, support], Dictionary(movement_state.get("current_target_positions", {})), moving_ids)
	var update_result: Dictionary = controller.update_execution("gold", [leader, scout, support], leader, simulation)
	var next_state: Dictionary = Dictionary(update_result.get("movement_state", {}))
	var next_moving_ids: PackedStringArray = PackedStringArray(next_state.get("current_moving_unit_ids", PackedStringArray()))
	_assert(next_moving_ids.size() == 1 and String(next_moving_ids[0]) != "cat_scout", "Caterpillar advances to the next member only after a bound is completed")
	_cleanup_units([leader, scout, support])


func _test_losses_simplify_coordinated_patterns_to_rush() -> void:
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var leader = _make_unit("loss_lead", "blue", true, Vector2(0.0, 0.0), 0.52, 0.5, 0.7, 0.55, ["steady"])
	var mover = _make_unit("loss_mover", "blue", false, Vector2(-16.0, 0.0), 0.84, 0.42, 0.35, 0.44, [])
	var casualty_a = _make_unit("loss_a", "blue", false, Vector2(12.0, 18.0), 0.44, 0.73, 0.28, 0.4, [])
	var casualty_b = _make_unit("loss_b", "blue", false, Vector2(26.0, 26.0), 0.38, 0.65, 0.25, 0.39, [])
	casualty_a.call("apply_damage", casualty_a.call("get_max_health_points"))
	casualty_b.call("apply_damage", casualty_b.call("get_max_health_points"))
	var profile = _make_profile("blue", "bounding", 100.0)
	var result: Dictionary = controller.start_execution("blue", "move", 1, Vector2(220.0, 120.0), profile, [leader, mover, casualty_a, casualty_b], leader, simulation)
	var movement_state: Dictionary = Dictionary(result.get("movement_state", {}))
	_assert(String(movement_state.get("effective_style", "")) == "rush", "Heavy casualties simplify coordinated patterns back to rush")
	_assert(bool(movement_state.get("simplified_due_to_losses", false)), "Simplified movement state is flagged for UI and debugging")
	_cleanup_units([leader, mover, casualty_a, casualty_b])


func _test_bound_complete_event_router_contract() -> void:
	_bound_events.clear()
	var event_router = EVENT_ROUTER_SCRIPT.new()
	root.add_child(event_router)
	if event_router.has_signal("fireteam_bound_complete") and not event_router.is_connected("fireteam_bound_complete", Callable(self, "_on_fireteam_bound_complete")):
		event_router.connect("fireteam_bound_complete", Callable(self, "_on_fireteam_bound_complete"))
	event_router.call("notify_fireteam_bound_complete", "blue", {"stage_index": 1, "reason": "stage_complete"})
	_assert(_bound_events.size() == 1, "EventRouter exposes the fireteam_bound_complete signal contract")
	if _bound_events.size() == 1:
		_assert(String(Dictionary(_bound_events[0]).get("fireteam_id", "")) == "blue", "Bound complete events preserve the fireteam id")
	event_router.queue_free()


func _test_order_visualizer_uses_command_line_colors() -> void:
	var visualizer = FIRETEAM_ORDER_VISUALIZER_SCRIPT.new()
	var move_color: Color = Color(visualizer.call("_get_command_line_color", FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_MOVE))
	var defend_color: Color = Color(visualizer.call("_get_command_line_color", FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_DEFEND))
	var flank_color: Color = Color(visualizer.call("_get_command_line_color", FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_FLANK))
	_assert(move_color.b > move_color.r and move_color.b >= move_color.g, "Neutral move waypoints draw blue route lines")
	_assert(defend_color.g > defend_color.r and defend_color.g > defend_color.b, "Defensive waypoints draw green route lines")
	_assert(flank_color.r > flank_color.g and flank_color.r > flank_color.b, "Offensive waypoints draw red route lines")
	visualizer.queue_free()


func _test_scene_exposes_runtime_movement_snapshot() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("_create_waypoints_for_selected_fireteams", Vector2(260.0, 160.0))
	var started: bool = controller.call("advance_to_next_phase")
	await process_frame
	var snapshot: Array = Array(controller.call("get_fireteam_movement_snapshot"))
	_assert(started, "Scene phase start succeeds for movement controller integration")
	_assert(snapshot.size() >= 1, "Mission tactical controller exposes active fireteam movement state")
	var has_blue_entry: bool = false
	for entry_variant in snapshot:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("fireteam_id", "")) == "blue":
			has_blue_entry = true
			break
	_assert(has_blue_entry, "Movement snapshot identifies the executing fireteam")
	scene.queue_free()
	await process_frame


func _test_go_button_starts_planned_fireteam_execution() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("_create_waypoints_for_selected_fireteams", Vector2(280.0, 180.0))
	controller.call("_refresh_fireteam_phase_panel")
	var blue_units: Array = Array(controller.call("_get_fireteam_units", "blue", true))
	var positions_before: Dictionary = {}
	for unit in blue_units:
		if unit is Node2D and unit.has_method("get_unit_id"):
			positions_before[String(unit.call("get_unit_id"))] = (unit as Node2D).global_position
	var go_button := scene.find_child("GoPhaseButton", true, false) as Button
	_assert(go_button != null, "Mission tactical controller exposes a GO button in the fireteam phase panel")
	if go_button != null:
		_assert(not go_button.disabled, "GO button is enabled when a planned phase can start")
		go_button.emit_signal("pressed")
	await process_frame
	for _index in range(6):
		await physics_frame
	var snapshot: Array = Array(controller.call("get_fireteam_movement_snapshot"))
	var has_blue_execution := false
	for entry_variant in snapshot:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("fireteam_id", "")) == "blue":
			has_blue_execution = true
			break
	_assert(has_blue_execution, "GO button starts the planned fireteam execution")
	var did_move := false
	for unit in blue_units:
		if not (unit is Node2D) or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id"))
		if positions_before.has(unit_id) and (unit as Node2D).global_position.distance_to(Vector2(positions_before[unit_id])) > 0.5:
			did_move = true
			break
	_assert(did_move, "GO button moves the selected fireteam through SimulationRoot")
	scene.queue_free()
	await process_frame


func _test_e_key_starts_planned_fireteam_execution() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("_create_waypoints_for_selected_fireteams", Vector2(300.0, 190.0))
	controller.call("_refresh_fireteam_phase_panel")
	var key_event := InputEventKey.new()
	key_event.pressed = true
	key_event.physical_keycode = KEY_E
	controller.call("_unhandled_input", key_event)
	await process_frame
	await physics_frame
	var snapshot: Array = Array(controller.call("get_fireteam_movement_snapshot"))
	var has_blue_execution: bool = false
	for entry_variant in snapshot:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("fireteam_id", "")) == "blue":
			has_blue_execution = true
			break
	_assert(has_blue_execution, "E key starts the selected fireteam GO order")
	scene.queue_free()
	await process_frame


func _test_go_button_does_not_restart_active_defend_execution() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	var waypoint_targets: Array = Array(controller.call("_create_waypoints_for_selected_fireteams", Vector2(300.0, 190.0)))
	controller.call("_set_waypoint_command_for_targets", waypoint_targets, FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_DEFEND)
	controller.call("_refresh_fireteam_phase_panel")
	var go_button := scene.find_child("GoPhaseButton", true, false) as Button
	_assert(go_button != null, "Mission tactical controller exposes GO for a defend order")
	if go_button != null:
		go_button.emit_signal("pressed")
	await process_frame
	await physics_frame
	var execution_before: Dictionary = Dictionary(Dictionary(controller.get("_phase_execution_by_fireteam")).get("blue", {}))
	if go_button != null:
		go_button.emit_signal("pressed")
	await process_frame
	await physics_frame
	var execution_after: Dictionary = Dictionary(Dictionary(controller.get("_phase_execution_by_fireteam")).get("blue", {}))
	_assert(not execution_before.is_empty(), "First GO starts the defend waypoint execution")
	_assert(int(execution_after.get("waypoint_index", -1)) == int(execution_before.get("waypoint_index", -2)), "Second GO keeps active defend execution on the current waypoint")
	_assert(String(controller.get("_last_command_text")).contains("ACTIVE"), "Second GO reports an already active fireteam instead of reissuing from the start")
	scene.queue_free()
	await process_frame


func _test_go_button_continues_from_defend_to_next_waypoint() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	var defend_targets: Array = Array(controller.call("_create_waypoints_for_selected_fireteams", Vector2(300.0, 190.0)))
	controller.call("_set_waypoint_command_for_targets", defend_targets, FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_DEFEND)
	controller.call("_create_waypoints_for_selected_fireteams", Vector2(380.0, 220.0))
	controller.call("_refresh_fireteam_phase_panel")
	var go_button := scene.find_child("GoPhaseButton", true, false) as Button
	if go_button != null:
		go_button.emit_signal("pressed")
	await process_frame
	await physics_frame
	_move_scene_fireteam_to_current_targets(controller, "blue")
	for _index in range(3):
		controller.call("_update_active_phase_execution", 0.2)
		await process_frame
	var waiting_text: String = String(controller.call("_build_selected_waypoint_info_text"))
	_assert(waiting_text.contains("WARTET AUF GO"), "Reached defend waypoint waits for explicit GO before continuing")
	if go_button != null:
		go_button.emit_signal("pressed")
	await process_frame
	await physics_frame
	var execution_after: Dictionary = Dictionary(Dictionary(controller.get("_phase_execution_by_fireteam")).get("blue", {}))
	_assert(int(execution_after.get("waypoint_index", -1)) == 1, "GO from a waiting defend waypoint advances to the next target")
	_assert(String(controller.get("_last_command_text")).contains("NEXT"), "GO reports continuation to the next waypoint")
	scene.queue_free()
	await process_frame


func _test_fireteam_panel_runs_in_direct_order_mode() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	controller.call("_refresh_fireteam_phase_panel")
	var panel := controller.get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamInfoScroll/FireteamInfoVBox/FireteamPhasePanel")
	var status_label: Label = null
	var phase_next_button: Button = null
	var edit_button: Button = null
	if panel != null:
		status_label = panel.find_child("PhaseStatusLabel", true, false) as Label
		phase_next_button = panel.find_child("NextPhaseButton", true, false) as Button
		edit_button = panel.find_child("PrevEditPhaseButton", true, false) as Button
	_assert(String(controller.call("_build_phase_status_text")).contains("Direktmodus"), "Fireteam panel shows direct order mode while phases are parked")
	_assert(phase_next_button == null or not phase_next_button.visible, "Global phase advance button is hidden in direct order mode")
	_assert(edit_button == null or not edit_button.visible, "Phase edit buttons are hidden in direct order mode")
	scene.queue_free()
	await process_frame


func _test_selected_fireteam_panel_shows_current_waypoint_details() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("_create_waypoints_for_selected_fireteams", Vector2(280.0, 180.0))
	controller.call("_refresh_fireteam_phase_panel")
	var planned_text: String = String(controller.call("_build_selected_waypoint_info_text"))
	_assert(planned_text.contains("WP 1/1") and planned_text.contains("MOVE"), "Selected fireteam panel summarizes the next planned waypoint")
	var go_button := scene.find_child("GoPhaseButton", true, false) as Button
	if go_button != null:
		go_button.emit_signal("pressed")
	await process_frame
	await physics_frame
	var active_text: String = String(controller.call("_build_selected_waypoint_info_text"))
	_assert(active_text.contains("ACTIVE") and active_text.contains("Bewegung:"), "Selected fireteam panel shows current waypoint status and movement style")
	scene.queue_free()
	await process_frame


func _test_go_button_moves_meta_fireteam_id() -> void:
	var scene = await _load_scene(PackedStringArray(["ft1", "ft1", "ft1"]))
	var controller = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["ft1"]), false)
	controller.call("_create_waypoints_for_selected_fireteams", Vector2(300.0, 190.0))
	controller.call("_refresh_fireteam_phase_panel")
	var ft1_units: Array = Array(controller.call("_get_fireteam_units", "ft1", true))
	var positions_before: Dictionary = {}
	for unit in ft1_units:
		if unit is Node2D and unit.has_method("get_unit_id"):
			positions_before[String(unit.call("get_unit_id"))] = (unit as Node2D).global_position
	var go_button := scene.find_child("GoPhaseButton", true, false) as Button
	_assert(go_button != null, "Mission tactical controller exposes GO for meta fireteam ids")
	if go_button != null:
		_assert(not go_button.disabled, "GO button is enabled for FT1 planned orders")
		go_button.emit_signal("pressed")
	await process_frame
	for _index in range(6):
		await physics_frame
	var did_move := false
	for unit in ft1_units:
		if not (unit is Node2D) or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id"))
		if positions_before.has(unit_id) and (unit as Node2D).global_position.distance_to(Vector2(positions_before[unit_id])) > 0.5:
			did_move = true
			break
	_assert(did_move, "GO button moves FT1 fireteams configured through the meta layer")
	scene.queue_free()
	await process_frame


func _test_go_button_moves_all_selected_meta_fireteam_ids() -> void:
	var scene = await _load_scene(PackedStringArray(["ft1", "ft1", "ft1"]))
	var controller = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["ft1"]), false)
	controller.call("_create_waypoints_for_selected_fireteams", Vector2(300.0, 190.0))
	controller.call("_create_waypoints_for_selected_fireteams", Vector2(360.0, 160.0))
	controller.call("_create_waypoints_for_selected_fireteams", Vector2(420.0, 130.0))
	controller.call("_set_selected_fireteams", PackedStringArray(["ft1"]), false)
	controller.call("_refresh_fireteam_phase_panel")
	var ft1_units: Array = Array(controller.call("_get_fireteam_units", "ft1", true))
	var positions_before: Dictionary = {}
	for unit in ft1_units:
		if unit is Node2D and unit.has_method("get_unit_id"):
			positions_before[String(unit.call("get_unit_id"))] = (unit as Node2D).global_position
	var go_button := scene.find_child("GoPhaseButton", true, false) as Button
	_assert(go_button != null, "Mission tactical controller exposes GO for the ALL-style fireteam selection")
	if go_button != null:
		_assert(not go_button.disabled, "GO button is enabled for ALL-style selected FT1 orders")
		go_button.emit_signal("pressed")
	await process_frame
	for _index in range(6):
		await physics_frame
	var did_move := false
	for unit in ft1_units:
		if not (unit is Node2D) or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id"))
		if positions_before.has(unit_id) and (unit as Node2D).global_position.distance_to(Vector2(positions_before[unit_id])) > 0.5:
			did_move = true
			break
	_assert(did_move, "GO button moves a multi-waypoint FT1 plan from the ALL-style selection")
	scene.queue_free()
	await process_frame


func _test_live_fireteam_go_moves_lead_and_members_without_snapback() -> void:
	var scene = await _load_scene(PackedStringArray(["ft1", "ft1", "ft1"]))
	var controller = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["ft1"]), false)
	controller.call("_create_waypoints_for_selected_fireteams", Vector2(460.0, 150.0))
	controller.call("_refresh_fireteam_phase_panel")
	var ft1_units: Array = Array(controller.call("_get_fireteam_units", "ft1", true))
	var positions_before: Dictionary = {}
	for unit in ft1_units:
		if not (unit is Node2D) or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id"))
		positions_before[unit_id] = (unit as Node2D).global_position
	var lead: Node2D = controller.call("_resolve_fireteam_leader_for_behavior", "ft1") as Node2D
	var lead_start: Vector2 = lead.global_position if lead != null else Vector2.ZERO
	var max_member_progress: Dictionary = {}
	var go_button := scene.find_child("GoPhaseButton", true, false) as Button
	if go_button != null:
		go_button.emit_signal("pressed")
	await process_frame
	await physics_frame
	var initial_movement_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", "ft1"))
	_assert(String(initial_movement_state.get("effective_style", "")) == "rush", "Live GO treats a normal Move order as group travel")
	for _frame in range(260):
		await process_frame
		await physics_frame
		for unit in ft1_units:
			if not (unit is Node2D) or not unit.has_method("get_unit_id"):
				continue
			var unit_id: String = String(unit.call("get_unit_id"))
			var moved_distance: float = (unit as Node2D).global_position.distance_to(Vector2(positions_before.get(unit_id, (unit as Node2D).global_position)))
			max_member_progress[unit_id] = maxf(float(max_member_progress.get(unit_id, 0.0)), moved_distance)
	var lead_moved_distance: float = lead.global_position.distance_to(lead_start) if lead != null else 0.0
	var moved_member_count: int = 0
	for unit_id_variant in max_member_progress.keys():
		if float(max_member_progress.get(unit_id_variant, 0.0)) > 8.0:
			moved_member_count += 1
	var all_members_kept_most_progress: bool = true
	for unit in ft1_units:
		if not (unit is Node2D) or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id"))
		var max_progress: float = float(max_member_progress.get(unit_id, 0.0))
		var final_progress: float = (unit as Node2D).global_position.distance_to(Vector2(positions_before.get(unit_id, (unit as Node2D).global_position)))
		if max_progress > 8.0 and final_progress + 48.0 < max_progress:
			all_members_kept_most_progress = false
			break
	_assert(lead != null and lead_moved_distance > 8.0, "Live GO eventually moves the fireteam lead instead of leaving the FTL behind")
	_assert(moved_member_count == ft1_units.size(), "Live GO moves every active fireteam member, not just one scout")
	_assert(all_members_kept_most_progress, "Live GO members keep their movement progress instead of snapping back to the FTL")
	scene.queue_free()
	await process_frame


func _test_live_move_waits_for_members_after_lead_reaches_target() -> void:
	var scene = await _load_scene(PackedStringArray(["ft1", "ft1", "ft1"]))
	var controller = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["ft1"]), false)
	controller.call("_create_waypoints_for_selected_fireteams", Vector2(460.0, 150.0))
	controller.call("_refresh_fireteam_phase_panel")
	var go_button := scene.find_child("GoPhaseButton", true, false) as Button
	if go_button != null:
		go_button.emit_signal("pressed")
	await process_frame
	await physics_frame
	var execution_before: Dictionary = Dictionary(Dictionary(controller.get("_phase_execution_by_fireteam")).get("ft1", {}))
	var target_position: Vector2 = Vector2(execution_before.get("resolved_target_position", Vector2.ZERO))
	var lead := controller.call("_resolve_fireteam_leader_for_behavior", "ft1") as Node2D
	if lead != null:
		lead.global_position = target_position
	controller.call("_update_active_phase_execution", 0.2)
	await process_frame
	var execution_after: Dictionary = Dictionary(Dictionary(controller.get("_phase_execution_by_fireteam")).get("ft1", {}))
	_assert(not execution_before.is_empty(), "Live move execution starts before lead-only arrival check")
	_assert(not execution_after.is_empty(), "Live move waits for trailing members after the FTL reaches the target")
	scene.queue_free()
	await process_frame


func _test_live_move_continues_after_initial_go_without_repress() -> void:
	var scene = await _load_scene(PackedStringArray(["ft1", "ft1", "ft1"]))
	var controller = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["ft1"]), false)
	controller.call("_create_waypoints_for_selected_fireteams", Vector2(560.0, 160.0))
	controller.call("_refresh_fireteam_phase_panel")
	var ft1_units: Array = Array(controller.call("_get_fireteam_units", "ft1", true))
	var start_positions: Dictionary = {}
	for unit in ft1_units:
		if unit is Node2D and unit.has_method("get_unit_id"):
			start_positions[String(unit.call("get_unit_id"))] = (unit as Node2D).global_position
	var go_button := scene.find_child("GoPhaseButton", true, false) as Button
	if go_button != null:
		go_button.emit_signal("pressed")
	await process_frame
	for _frame in range(8):
		await physics_frame
	var early_progress: Dictionary = {}
	for unit in ft1_units:
		if unit is Node2D and unit.has_method("get_unit_id"):
			var unit_id: String = String(unit.call("get_unit_id"))
			early_progress[unit_id] = (unit as Node2D).global_position.distance_to(Vector2(start_positions.get(unit_id, (unit as Node2D).global_position)))
	for _frame in range(100):
		await process_frame
		await physics_frame
	var continued_member_count: int = 0
	for unit in ft1_units:
		if not (unit is Node2D) or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id"))
		var later_progress: float = (unit as Node2D).global_position.distance_to(Vector2(start_positions.get(unit_id, (unit as Node2D).global_position)))
		if later_progress > float(early_progress.get(unit_id, 0.0)) + 6.0:
			continued_member_count += 1
	_assert(continued_member_count == ft1_units.size(), "Live Move keeps progressing after the initial GO pulse without pressing GO again")
	scene.queue_free()
	await process_frame


func _test_live_planning_echo_keeps_go_execution_running() -> void:
	var scene = await _load_scene(PackedStringArray(["ft1", "ft1", "ft1"]))
	var controller = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["ft1"]), false)
	controller.call("_create_waypoints_for_selected_fireteams", Vector2(500.0, 150.0))
	controller.call("_refresh_fireteam_phase_panel")
	var ft1_units: Array = Array(controller.call("_get_fireteam_units", "ft1", true))
	var positions_before: Dictionary = {}
	for unit in ft1_units:
		if unit is Node2D and unit.has_method("get_unit_id"):
			positions_before[String(unit.call("get_unit_id"))] = (unit as Node2D).global_position
	var go_button := scene.find_child("GoPhaseButton", true, false) as Button
	if go_button != null:
		go_button.emit_signal("pressed")
	controller.call("set_planning_state", Dictionary(controller.call("get_planning_state")))
	for _frame in range(180):
		await process_frame
		await physics_frame
	var moved_member_count: int = 0
	for unit in ft1_units:
		if not (unit is Node2D) or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id"))
		if (unit as Node2D).global_position.distance_to(Vector2(positions_before.get(unit_id, (unit as Node2D).global_position))) > 14.0:
			moved_member_count += 1
	_assert(moved_member_count == ft1_units.size(), "Live planning-state echo keeps GO execution running for every fireteam member")
	scene.queue_free()
	await process_frame


func _test_planning_state_echo_does_not_redeploy_moving_fireteam() -> void:
	var scene = await _load_scene(PackedStringArray(["ft1", "ft1", "ft1"]))
	var controller = scene.get_node("TacticalController")
	var ft1_units: Array = Array(controller.call("_get_fireteam_units", "ft1", true))
	var deployed_unit_ids: Array = []
	for index in range(ft1_units.size()):
		var unit = ft1_units[index]
		if not (unit is Node2D) or not unit.has_method("get_unit_id"):
			continue
		deployed_unit_ids.append(String(unit.call("get_unit_id")))
		(unit as Node2D).global_position = Vector2(420.0 + (index * 24.0), 180.0 + (index * 16.0))
	var positions_before_echo: Dictionary = {}
	for unit in ft1_units:
		if unit is Node2D and unit.has_method("get_unit_id"):
			positions_before_echo[String(unit.call("get_unit_id"))] = (unit as Node2D).global_position
	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	planning_state["has_lz_position"] = true
	planning_state["lz_position"] = Vector2(96.0, 96.0)
	planning_state["deployed_unit_ids"] = deployed_unit_ids
	controller.call("set_planning_state", planning_state)
	for _frame in range(4):
		await process_frame
		await physics_frame
	var positions_preserved: bool = true
	for unit in ft1_units:
		if not (unit is Node2D) or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id"))
		if (unit as Node2D).global_position.distance_to(Vector2(positions_before_echo.get(unit_id, (unit as Node2D).global_position))) > 1.0:
			positions_preserved = false
			break
	_assert(positions_preserved, "Planning-state echo keeps already deployed moving fireteams at their live positions")
	scene.queue_free()
	await process_frame


func _make_profile(fireteam_id: String, advance_style: String, cohesion_threshold: float):
	var profile = FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.new()
	profile.fireteam_id = fireteam_id
	profile.advance_style = advance_style
	profile.cover_priority = 0.45
	profile.fire_discipline = "hold_fire"
	profile.cohesion_threshold = cohesion_threshold
	profile.suppression_threshold = 2
	return profile


func _make_unit(
	unit_id: String,
	fireteam_id: String,
	is_lead: bool,
	position_value: Vector2,
	speed: float,
	accuracy: float,
	leadership: float,
	toughness: float,
	traits: Array
) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.display_name = unit_id
	unit.team_id = "team_alpha"
	unit.fireteam_id = fireteam_id
	unit.is_fireteam_lead = is_lead
	unit.skill_speed = speed
	unit.skill_accuracy = accuracy
	unit.skill_leadership = leadership
	unit.skill_toughness = toughness
	unit.trait_ids = PackedStringArray(traits)
	unit.position = position_value
	unit._ready()
	return unit


func _move_units_to_targets(units: Array, current_target_positions: Dictionary, moving_ids: PackedStringArray) -> void:
	for unit in units:
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id"))
		if not moving_ids.has(unit_id):
			continue
		if not current_target_positions.has(unit_id):
			continue
		unit.global_position = Vector2(current_target_positions.get(unit_id))


func _move_scene_fireteam_to_current_targets(controller: Node, fireteam_id: String) -> void:
	var movement_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", fireteam_id))
	var target_positions: Dictionary = Dictionary(movement_state.get("current_target_positions", {}))
	var units: Array = Array(controller.call("_get_fireteam_units", fireteam_id, true))
	for unit in units:
		if not (unit is Node2D) or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id"))
		if target_positions.has(unit_id):
			(unit as Node2D).global_position = Vector2(target_positions.get(unit_id))


func _compute_target_spread(target_positions: Dictionary) -> float:
	var positions: Array = []
	for target_variant in target_positions.values():
		if typeof(target_variant) == TYPE_VECTOR2:
			positions.append(Vector2(target_variant))
	var max_distance: float = 0.0
	for position_a in positions:
		for position_b in positions:
			max_distance = maxf(max_distance, Vector2(position_a).distance_to(Vector2(position_b)))
	return max_distance


func _cleanup_units(units: Array) -> void:
	for unit in units:
		if unit != null:
			unit.queue_free()


func _load_scene(selected_fireteam_ids: PackedStringArray = PackedStringArray()) -> Node:
	var scene = load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
	if not selected_fireteam_ids.is_empty():
		var mission_setup: Node = scene.get_node_or_null("MissionSetup")
		if mission_setup != null:
			mission_setup.set("selected_team_fireteam_ids", selected_fireteam_ids)
	root.add_child(scene)
	for _index in range(10):
		await process_frame
	return scene


func _on_fireteam_bound_complete(fireteam_id: String, bound_data: Dictionary) -> void:
	var payload: Dictionary = bound_data.duplicate(true)
	payload["fireteam_id"] = fireteam_id
	_bound_events.append(payload)


func _all_close(values: Array) -> bool:
	if values.size() < 2:
		return true
	var first_value: float = float(values[0])
	for value in values:
		if absf(float(value) - first_value) > 0.0001:
			return false
	return true


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
