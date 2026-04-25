extends SceneTree

const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const FIRETEAM_BEHAVIOR_PROFILE_SCRIPT: GDScript = preload("res://scripts/command/fireteam_behavior_profile.gd")
const EVENT_ROUTER_SCRIPT: GDScript = preload("res://scripts/core/event_router.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0
var _bound_events: Array = []


class SimulationStub:
	extends RefCounted
	var commands: Array = []

	func enqueue_command(command_dict: Dictionary) -> void:
		commands.append(command_dict.duplicate(true))


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_110 Fireteam Movement Controller Verifier ===")
	_test_rush_moves_all_fit_members_with_cohesion_clamp()
	_test_bounding_rotates_cover_and_movement_groups()
	_test_bounding_keeps_bound_anchor_until_lead_moves()
	_test_caterpillar_moves_one_member_at_a_time()
	_test_losses_simplify_coordinated_patterns_to_rush()
	_test_bound_complete_event_router_contract()
	await _test_scene_exposes_runtime_movement_snapshot()
	await _test_go_button_starts_planned_fireteam_execution()
	await _test_go_button_moves_meta_fireteam_id()
	await _test_go_button_moves_all_selected_meta_fireteam_ids()
	await _test_live_fireteam_go_moves_lead_and_members_without_snapback()
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
		move_speed_factors.append(float(Dictionary(command_dict).get("move_speed_factor", -1.0)))
	_assert(_all_close(move_speed_factors), "Rush clamps movers to a shared speed when cohesion is already broken")
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
		if max_progress > 8.0 and final_progress + 12.0 < max_progress:
			all_members_kept_most_progress = false
			break
	_assert(lead != null and lead_moved_distance > 8.0, "Live GO eventually moves the fireteam lead instead of leaving the FTL behind")
	_assert(moved_member_count == ft1_units.size(), "Live GO moves every active fireteam member, not just one scout")
	_assert(all_members_kept_most_progress, "Live GO members keep their movement progress instead of snapping back to the FTL")
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
