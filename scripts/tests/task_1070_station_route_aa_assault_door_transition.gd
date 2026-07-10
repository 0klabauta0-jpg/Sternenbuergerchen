extends SceneTree

const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const STATION_MISSION_ID: String = "station_route_one_screen_multiplayer_drill"
const STATION_SCENARIO_PATH: String = "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json"
const AA_INTERACTION_ID: String = "aa_shutdown_zone"
const COMMAND_GRID_PATH: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1070 Station Route AA Assault and Door Transition ===")
	await _test_station_route_aa_interaction_to_door_transition()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_station_route_aa_interaction_to_door_transition() -> void:
	root.size = Vector2i(1920, 1080)
	var flow: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(flow)
	await _wait_frames(8)
	var homebase := flow.get_node_or_null("HomebaseScreen") as Control
	_assert(homebase != null, "AA trace exposes the real Homebase screen")
	if homebase == null:
		await _cleanup(flow)
		return
	flow.call("_on_homebase_mission_selection_changed", STATION_MISSION_ID)
	homebase.call("request_mission_start")
	await _wait_frames(12)

	var mission: Node = flow.call("get_active_mission")
	var mission_setup: Node = mission.get_node_or_null("MissionSetup") if mission != null else null
	var controller: Node = mission.get_node_or_null("TacticalController") if mission != null else null
	var primary_view: Node = mission.get_node_or_null("Primary3DView") if mission != null else null
	var combat_driver: Node = mission.get_node_or_null("CombatLoopDriver") if mission != null else null
	_assert(mission_setup != null and controller != null and primary_view != null and combat_driver != null, "AA trace exposes Station mission runtime")
	if mission_setup == null or controller == null or primary_view == null or combat_driver == null:
		await _cleanup(flow)
		return
	_assert(String(mission_setup.get("scenario_file_path")) == STATION_SCENARIO_PATH, "AA trace keeps Station scenario")
	_assert(controller.has_method("issue_primary_mission_interaction"), "Controller exposes contextual interaction action")
	_assert(controller.has_method("get_primary_mission_interaction_button_snapshot"), "Controller exports contextual interaction button snapshot")
	if not controller.has_method("issue_primary_mission_interaction") or not controller.has_method("get_primary_mission_interaction_button_snapshot"):
		await _cleanup(flow)
		return

	var craft_id: String = _get_mission_drop_craft_id(flow)
	_assert(not craft_id.is_empty(), "AA trace receives mission dropship")
	if craft_id.is_empty():
		await _cleanup(flow)
		return
	_complete_mission_craft_arrival(flow, craft_id)
	await _wait_frames(8)
	controller.call("_on_mission_dropship_card_set_lz_pressed", craft_id)
	_assert(bool(controller.call("_place_lz_from_screen_position", primary_view.call("world_to_screen_position", Vector2(384.0, 224.0)))), "AA trace places LZ")
	controller.call("_on_mission_dropship_card_drop_pressed", craft_id)
	await _wait_frames(4)
	controller.call("_complete_drop_sequence_deployment")
	controller.call("_advance_primary_drop_sequence_unloading", 999.0)
	controller.call("_flush_pending_drop_runtime_phase_starts")
	controller.call("_update_ui")
	await _wait_frames(8)

	var fireteam_id: String = _first_displayable_fireteam(controller)
	_assert(not fireteam_id.is_empty(), "AA trace deboards a Ground-Fireteam")
	if fireteam_id.is_empty():
		await _cleanup(flow)
		return
	controller.call("_on_fireteam_group_pressed", fireteam_id)
	controller.call("_update_ui")
	var before_range: Dictionary = Dictionary(controller.call("get_primary_mission_interaction_button_snapshot"))
	_assert(String(before_range.get("interaction_id", "")) == AA_INTERACTION_ID, "First contextual action names AA")
	_assert(bool(before_range.get("visible", false)) and bool(before_range.get("disabled", false)), "AA action remains visible but blocked out of range")

	var interaction_feedback: Dictionary = Dictionary(controller.call("get_mission_interaction_use_feedback_snapshot"))
	var aa_position: Vector2 = _interaction_marker_position(interaction_feedback, AA_INTERACTION_ID)
	_assert(aa_position != Vector2.ZERO, "AA interaction resolves a marker position")
	_move_fireteam_units(controller, fireteam_id, aa_position)
	controller.call("_update_ui")
	await _wait_frames(4)
	var ready_button: Dictionary = Dictionary(controller.call("get_primary_mission_interaction_button_snapshot"))
	_assert(not bool(ready_button.get("disabled", true)), "AA action becomes enabled inside the shutdown zone")
	_assert(String(ready_button.get("text", "")).contains("AA"), "AA action has a readable AA label")
	var grid_button := controller.get_node_or_null("%s/DoorBreachButton" % COMMAND_GRID_PATH) as Button
	_assert(grid_button != null and not grid_button.disabled, "Existing command-grid slot drives the AA action")

	var intent: Dictionary = Dictionary(controller.call("issue_primary_mission_interaction"))
	_assert(bool(intent.get("accepted", false)), "AA interaction action creates an intent")
	_assert(String(intent.get("interaction_id", "")) == AA_INTERACTION_ID and String(intent.get("command_type", "")) == "take", "AA intent uses the existing TAKE command")
	_assert(bool(intent.get("requires_go", false)), "AA intent keeps GO separate")
	_assert(not bool(Dictionary(controller.call("get_fireteam_movement_state", fireteam_id)).get("is_executing", false)), "AA intent does not move before GO")

	var go_accepted: bool = bool(controller.call("execute_selected_fireteam_orders"))
	_assert(go_accepted, "GO starts the planned AA interaction path")
	await _fast_forward_fireteam_movement_to_interaction(controller, fireteam_id)
	var runtime_states: Dictionary = Dictionary(combat_driver.call("get_mission_interaction_runtime_states"))
	var aa_state: Dictionary = Dictionary(runtime_states.get(AA_INTERACTION_ID, {}))
	var objective_gate: Dictionary = Dictionary(controller.call("get_mission_interaction_objective_gate_snapshot"))
	_assert(bool(aa_state.get("complete", false)), "GO reaches the existing AA runtime-progress completion")
	_assert(String(aa_state.get("required_state", "")) == "aa_disabled", "AA runtime state retains the scenario target")
	_assert(String(objective_gate.get("next_step_id", "")) == "open_station_door", "AA completion advances the route to the Door")
	_assert(not bool(Dictionary(combat_driver.call("get_playability_snapshot")).get("mission_resolved", true)), "AA completion does not prematurely resolve the mission")
	await _cleanup(flow)


func _get_mission_drop_craft_id(flow: Node) -> String:
	var handoff: Dictionary = Dictionary(flow.call("get_homebase_to_mission_handoff_snapshot"))
	var planning: Dictionary = Dictionary(handoff.get("planning", {}))
	return String(planning.get("mission_drop_craft_id", "")).strip_edges()


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


func _interaction_marker_position(feedback: Dictionary, interaction_id: String) -> Vector2:
	for entry_variant in Array(feedback.get("feedback_entries", [])):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("interaction_id", "")).strip_edges() == interaction_id:
			return Vector2(entry.get("marker_position", Vector2.ZERO))
	return Vector2.ZERO


func _move_fireteam_units(controller: Node, fireteam_id: String, center_position: Vector2) -> void:
	var offset_index: int = 0
	for unit_variant in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		var unit := unit_variant as Node2D
		if unit != null:
			unit.global_position = center_position + Vector2(float(offset_index % 2) * 8.0, float(int(offset_index / 2)) * 8.0)
			offset_index += 1


func _fast_forward_fireteam_movement_to_interaction(controller: Node, fireteam_id: String) -> void:
	for _iteration in range(12):
		var movement_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", fireteam_id))
		var target_positions: Dictionary = Dictionary(movement_state.get("current_target_positions", {}))
		if target_positions.is_empty():
			return
		for unit_variant in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
			var unit := unit_variant as Node2D
			if unit == null or not unit.has_method("get_unit_id"):
				continue
			var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
			if target_positions.has(unit_id):
				unit.global_position = Vector2(target_positions.get(unit_id, unit.global_position))
		controller.call("_update_active_phase_execution", 1.0)
		await _wait_frames(1)
	var remaining_targets: Dictionary = Dictionary(Dictionary(controller.call("get_fireteam_movement_state", fireteam_id)).get("current_target_positions", {}))
	_assert(remaining_targets.is_empty(), "AA movement acceleration reaches completion within bounded steps")


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
