extends SceneTree

const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const STATION_MISSION_ID: String = "station_route_one_screen_multiplayer_drill"
const AA_TARGET := Vector2(5376.0, 7008.0)
const SIMULATED_TICK_DELTA: float = 60.0
const MAX_ROUTE_TICKS: int = 96
const AA_INTERACTION_ID: String = "aa_shutdown_zone"
const COMMAND_GRID_PATH: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1175 Station Route Live AA Pressure ===")
	await _test_live_route_reaches_and_completes_aa_without_position_override()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_live_route_reaches_and_completes_aa_without_position_override() -> void:
	root.size = Vector2i(1920, 1080)
	var flow: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(flow)
	await _wait_frames(8)
	var homebase := flow.get_node_or_null("HomebaseScreen") as Control
	_assert(homebase != null, "Live AA trace exposes Homebase")
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
	_assert(controller != null and primary_view != null and combat_driver != null and simulation_root != null, "Live AA trace exposes Station runtime")
	if controller == null or primary_view == null or combat_driver == null or simulation_root == null:
		await _cleanup(flow)
		return
	var craft_id: String = _get_mission_drop_craft_id(flow)
	_assert(not craft_id.is_empty(), "Live AA trace receives a dropship")
	if craft_id.is_empty():
		await _cleanup(flow)
		return
	_complete_mission_craft_arrival(flow, craft_id)
	await _wait_frames(8)
	controller.call("_on_mission_dropship_card_set_lz_pressed", craft_id)
	_assert(bool(controller.call("_place_lz_from_screen_position", primary_view.call("world_to_screen_position", Vector2(384.0, 224.0)))), "Live AA trace places the normal LZ")
	controller.call("_on_mission_dropship_card_drop_pressed", craft_id)
	await _wait_frames(4)
	controller.call("_complete_drop_sequence_deployment")
	controller.call("_advance_primary_drop_sequence_unloading", 999.0)
	controller.call("_flush_pending_drop_runtime_phase_starts")
	await _wait_frames(8)

	var fireteam_id: String = _first_displayable_fireteam(controller)
	var initial_center: Vector2 = _fireteam_center(controller, fireteam_id)
	_assert(not fireteam_id.is_empty() and initial_center != Vector2.ZERO, "Live AA trace has a deboarded fireteam")
	_assert(bool(controller.call("issue_right_click_command_for_test", AA_TARGET, "move", false)), "Live AA trace plans a normal Move to AA")
	_assert(bool(controller.call("execute_selected_fireteam_orders")), "Live AA trace commits the normal Move through GO")

	var observed_contact: bool = false
	var reached_aa_range: bool = false
	for _tick in range(MAX_ROUTE_TICKS):
		simulation_root.call("_physics_process", SIMULATED_TICK_DELTA)
		controller.call("_update_active_phase_execution", SIMULATED_TICK_DELTA)
		combat_driver.call("_update_contact_tracking")
		combat_driver.call("_advance_detection_timers")
		var center: Vector2 = _fireteam_center(controller, fireteam_id)
		var contact: Dictionary = Dictionary(controller.call("get_mission_first_contact_readability_snapshot"))
		observed_contact = observed_contact or int(contact.get("selected_contact_count", 0)) > 0
		reached_aa_range = center.distance_to(AA_TARGET) <= 160.0
		if reached_aa_range:
			break

	var final_center: Vector2 = _fireteam_center(controller, fireteam_id)
	var movement_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", fireteam_id))
	print("LIVE_AA_ROUTE_DIAGNOSTIC center=%s distance_to_aa=%.1f executing=%s stage=%s contact=%s" % [final_center, final_center.distance_to(AA_TARGET), bool(movement_state.get("is_executing", false)), int(movement_state.get("stage_index", -1)), observed_contact])
	_assert(final_center.distance_to(initial_center) > 512.0, "Live AA trace moves the formation materially from the LZ")
	_assert(observed_contact, "Live AA trace observes the authored Bravo contact during the route")
	_assert(reached_aa_range, "Live AA trace reaches the authored AA interaction range without a position override")
	if not reached_aa_range:
		await _cleanup(flow)
		return

	controller.call("_update_ui")
	var action: Dictionary = Dictionary(controller.call("get_primary_mission_interaction_button_snapshot"))
	_assert(String(action.get("interaction_id", "")) == AA_INTERACTION_ID and not bool(action.get("disabled", true)), "AA contextual action becomes available only after live arrival")
	var grid_button := controller.get_node_or_null("%s/DoorBreachButton" % COMMAND_GRID_PATH) as Button
	_assert(grid_button != null and not grid_button.disabled, "AA action uses the existing visible command-grid slot")
	if grid_button == null or grid_button.disabled:
		await _cleanup(flow)
		return
	grid_button.emit_signal("pressed")
	await _wait_frames(1)
	var intent: Dictionary = Dictionary(controller.call("get_mission_interaction_use_intent_snapshot"))
	_assert(bool(intent.get("accepted", false)) and String(intent.get("interaction_id", "")) == AA_INTERACTION_ID, "AA click creates only the existing interaction intent")
	_assert(bool(intent.get("requires_go", false)), "AA intent keeps GO separate")
	_assert(bool(controller.call("execute_selected_fireteam_orders")), "AA GO starts existing interaction execution")
	var aa_state: Dictionary = {}
	for _tick in range(16):
		simulation_root.call("_physics_process", SIMULATED_TICK_DELTA)
		controller.call("_update_active_phase_execution", SIMULATED_TICK_DELTA)
		var states: Dictionary = Dictionary(combat_driver.call("get_mission_interaction_runtime_states"))
		aa_state = Dictionary(states.get(AA_INTERACTION_ID, {}))
		if bool(aa_state.get("complete", false)):
			break
	var aa_movement_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", fireteam_id))
	var aa_feedback: Dictionary = Dictionary(controller.call("get_mission_interaction_use_feedback_snapshot"))
	print("LIVE_AA_INTERACTION_DIAGNOSTIC complete=%s required_state=%s executing=%s stage=%s feedback=%s" % [bool(aa_state.get("complete", false)), String(aa_state.get("required_state", "")), bool(aa_movement_state.get("is_executing", false)), int(aa_movement_state.get("stage_index", -1)), String(aa_feedback.get("feedback_line", ""))])
	_assert(bool(aa_state.get("complete", false)) and String(aa_state.get("required_state", "")) == "aa_disabled", "AA completion remains on the existing runtime interaction path")
	await _cleanup(flow)


func _get_mission_drop_craft_id(flow: Node) -> String:
	var handoff: Dictionary = Dictionary(flow.call("get_homebase_to_mission_handoff_snapshot"))
	return String(Dictionary(handoff.get("planning", {})).get("mission_drop_craft_id", "")).strip_edges()


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


func _fireteam_center(controller: Node, fireteam_id: String) -> Vector2:
	var total := Vector2.ZERO
	var count: int = 0
	for unit_variant in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		var unit := unit_variant as Node2D
		if unit == null:
			continue
		total += unit.global_position
		count += 1
	return total / float(count) if count > 0 else Vector2.ZERO


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
		return
	_failed += 1
	push_error("FAIL: %s" % message)
