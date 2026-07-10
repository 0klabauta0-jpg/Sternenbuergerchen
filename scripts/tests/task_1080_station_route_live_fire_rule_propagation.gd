extends SceneTree

const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const STATION_MISSION_ID: String = "station_route_one_screen_multiplayer_drill"
const APPROACH_MOVE_TARGET := Vector2(2432.0, 5056.0)
const CONTACT_WAIT_FRAMES: int = 12

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1080 Station Route Live Fire-Rule Propagation ===")
	await _test_live_fire_rule_reissues_real_bravo_commands()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_live_fire_rule_reissues_real_bravo_commands() -> void:
	root.size = Vector2i(1920, 1080)
	var flow: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(flow)
	await _wait_frames(8)
	var homebase := flow.get_node_or_null("HomebaseScreen") as Control
	_assert(homebase != null, "Live ROE trace exposes Homebase")
	if homebase == null:
		await _cleanup(flow)
		return
	flow.call("_on_homebase_mission_selection_changed", STATION_MISSION_ID)
	homebase.call("request_mission_start")
	await _wait_frames(12)

	var mission: Node = flow.call("get_active_mission")
	var controller: Node = mission.get_node_or_null("TacticalController") if mission != null else null
	var primary_view: Node = mission.get_node_or_null("Primary3DView") if mission != null else null
	var combat_driver: Node = mission.get_node_or_null("CombatLoopDriver") if mission != null else null
	var simulation_root: Node = mission.get_node_or_null("SimulationRoot") if mission != null else null
	_assert(controller != null and primary_view != null and combat_driver != null and simulation_root != null, "Live ROE trace exposes Station runtime")
	if controller == null or primary_view == null or combat_driver == null or simulation_root == null:
		await _cleanup(flow)
		return
	var craft_id: String = _get_mission_drop_craft_id(flow)
	_assert(not craft_id.is_empty(), "Live ROE trace receives a dropship")
	if craft_id.is_empty():
		await _cleanup(flow)
		return
	_complete_mission_craft_arrival(flow, craft_id)
	await _wait_frames(8)
	controller.call("_on_mission_dropship_card_set_lz_pressed", craft_id)
	_assert(bool(controller.call("_place_lz_from_screen_position", primary_view.call("world_to_screen_position", Vector2(384.0, 224.0)))), "Live ROE trace places the normal LZ")
	controller.call("_on_mission_dropship_card_drop_pressed", craft_id)
	await _wait_frames(4)
	controller.call("_complete_drop_sequence_deployment")
	controller.call("_advance_primary_drop_sequence_unloading", 999.0)
	controller.call("_flush_pending_drop_runtime_phase_starts")
	controller.call("_update_ui")
	await _wait_frames(8)

	_assert(bool(controller.call("issue_right_click_command_for_test", APPROACH_MOVE_TARGET, "move", false)), "Live ROE trace plans the existing approach Move")
	_assert(bool(controller.call("execute_selected_fireteam_orders")), "Live ROE trace commits GO")
	await _wait_frames(CONTACT_WAIT_FRAMES)
	_update_contact_tracking(combat_driver)
	controller.call("refresh_contact_overlay")
	controller.call("refresh_fireteam_security_state")
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	await _wait_frames(2)

	var engagement: Dictionary = Dictionary(controller.call("get_mission_first_engagement_feedback_snapshot"))
	var selected_fireteam_ids: Array = Array(engagement.get("selected_fireteam_ids", []))
	_assert(int(engagement.get("selected_contact_count", 0)) > 0 and not selected_fireteam_ids.is_empty(), "Live ROE trace reaches selected Bravo contact")
	if selected_fireteam_ids.is_empty():
		await _cleanup(flow)
		return
	var fireteam_id: String = String(selected_fireteam_ids[0]).strip_edges().to_lower()
	var before_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", fireteam_id))
	_assert(not before_state.is_empty(), "Live ROE trace keeps a running Fireteam movement state")

	_assert(bool(controller.call("set_selected_fireteams_fire_rule", "return")), "Return Fire can be selected during the real Guard contact")
	_assert(_fireteam_commands_match_rule(simulation_root, fireteam_id, "return", "hold_fire"), "Return Fire reaches all live Bravo UnitCommands")
	var return_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", fireteam_id))
	_assert(String(return_state.get("fire_rule", "")).strip_edges().to_lower() == "return", "Return Fire reaches the live movement state")
	_assert(int(return_state.get("command_revision", 0)) > int(before_state.get("command_revision", 0)), "Return Fire invalidates the previous stage token")
	var return_consequence: Dictionary = Dictionary(controller.call("get_fire_rule_consequence_readability_snapshot"))
	_assert(String(return_consequence.get("fire_rule", "")) == "return" and bool(return_consequence.get("runtime_consistent", false)), "Return Fire HUD consequence matches the real UnitCommands")
	var return_density: Dictionary = Dictionary(controller.call("_build_mission_hud_interaction_density_snapshot"))
	_assert(String(return_density.get("mission_control_line", "")).contains("ROE %s" % String(return_consequence.get("hud_token", ""))), "Return Fire consequence is visible in the real Guard ACT line")

	_assert(bool(controller.call("set_selected_fireteams_fire_rule", "free")), "Fire at Will can be selected during the real Guard contact")
	_assert(_fireteam_commands_match_rule(simulation_root, fireteam_id, "free", "fire_at_will"), "Fire at Will reaches all live Bravo UnitCommands")
	var free_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", fireteam_id))
	_assert(String(free_state.get("fire_rule", "")).strip_edges().to_lower() == "free", "Fire at Will reaches the live movement state")
	_assert(int(free_state.get("command_revision", 0)) > int(return_state.get("command_revision", 0)), "Fire at Will creates a newer command revision")
	var free_consequence: Dictionary = Dictionary(controller.call("get_fire_rule_consequence_readability_snapshot"))
	_assert(String(free_consequence.get("fire_rule", "")) == "free" and bool(free_consequence.get("runtime_consistent", false)), "Fire at Will HUD consequence matches the real UnitCommands")
	var free_density: Dictionary = Dictionary(controller.call("_build_mission_hud_interaction_density_snapshot"))
	_assert(String(free_density.get("mission_control_line", "")).contains("ROE %s" % String(free_consequence.get("hud_token", ""))), "Fire at Will consequence is visible in the real Guard ACT line")
	_assert(bool(free_density.get("line_within_limit", false)), "Real Guard ACT line keeps the ROE consequence inside the HUD budget")
	_assert(_read_only_snapshot(engagement), "Live ROE feedback snapshot remains read-only")
	await _cleanup(flow)


func _fireteam_commands_match_rule(simulation_root: Node, fireteam_id: String, expected_rule: String, expected_status: String) -> bool:
	if simulation_root == null or not simulation_root.has_method("get_unit_registry"):
		return false
	var unit_registry = simulation_root.call("get_unit_registry")
	if unit_registry == null or not unit_registry.has_method("get_all_units"):
		return false
	var matched_count: int = 0
	for unit in Array(unit_registry.call("get_all_units")):
		if unit == null or not unit.has_method("get_fireteam_id") or not unit.has_method("get_current_unit_command"):
			continue
		if String(unit.call("get_fireteam_id")).strip_edges().to_lower() != fireteam_id:
			continue
		var command = unit.call("get_current_unit_command")
		if command == null or not command.has_method("get"):
			return false
		matched_count += 1
		if String(command.get("fire_rule")).strip_edges().to_lower() != expected_rule:
			return false
		if String(command.get("fire_status")).strip_edges().to_lower() != expected_status:
			return false
	return matched_count > 0


func _get_mission_drop_craft_id(flow: Node) -> String:
	var handoff: Dictionary = Dictionary(flow.call("get_homebase_to_mission_handoff_snapshot"))
	return String(Dictionary(handoff.get("planning", {})).get("mission_drop_craft_id", "")).strip_edges()


func _complete_mission_craft_arrival(flow: Node, craft_id: String) -> void:
	flow.call("_remove_pending_mission_craft_transfer", craft_id)
	flow.call("_complete_mission_craft_transfer", {"craft_id": craft_id, "phase": "to_mission"})
	flow.call("_sync_homebase_direct_mission_drop_transport_fields")
	flow.call("_start_or_update_active_mission")


func _update_contact_tracking(combat_driver: Node) -> void:
	for _index in range(4):
		combat_driver.call("_update_contact_tracking")
		combat_driver.call("_advance_detection_timers")
	combat_driver.call("_update_contact_tracking")


func _read_only_snapshot(snapshot: Dictionary) -> bool:
	if not bool(snapshot.get("read_only", false)) or bool(snapshot.get("ui_sets_gameplay_truth", true)):
		return false
	for mutation_key in ["creates_command", "creates_movement", "creates_fire_event", "creates_damage_event", "sets_multiplayer_truth"]:
		if snapshot.has(mutation_key) and bool(snapshot.get(mutation_key, false)):
			return false
	return true


func _cleanup(flow: Node) -> void:
	if is_instance_valid(flow):
		flow.queue_free()
	await _wait_frames(2)


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
