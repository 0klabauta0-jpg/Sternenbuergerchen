extends SceneTree

const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")

const STATION_MISSION_ID: String = "station_route_one_screen_multiplayer_drill"
const STATION_SCENARIO_PATH: String = "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json"
const COMMAND_GRID_PATH: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid"

const ROUTE_STEPS: Array[Dictionary] = [
	{"interaction_id": "aa_shutdown_zone", "token": "AA", "required_state": "aa_disabled", "duration_seconds": 0.0, "next_step_id": "open_station_door"},
	{"interaction_id": "station_route_drill_door", "token": "DOOR", "button_text": "B->GO", "required_state": "door_open", "duration_seconds": 2.0, "next_step_id": "occupy_station_computer"},
	{"interaction_id": "station_computer", "token": "COM", "required_state": "computer_controlled", "duration_seconds": 18.0, "next_step_id": "cargo_touchdown_extract"},
	{"interaction_id": "cargo_landing_hold", "token": "CARGO", "required_state": "cargo_departed", "duration_seconds": 12.0, "next_step_id": ""},
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1071 Station Route Full Victory Debrief Trace ===")
	await _test_station_route_full_victory_debrief()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_station_route_full_victory_debrief() -> void:
	root.size = Vector2i(1920, 1080)
	var flow: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(flow)
	await _wait_frames(8)
	var homebase := flow.get_node_or_null("HomebaseScreen") as Control
	_assert(homebase != null, "Full victory trace exposes Homebase")
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
	_assert(mission_setup != null and controller != null and primary_view != null and combat_driver != null, "Full victory trace exposes Station runtime")
	if mission_setup == null or controller == null or primary_view == null or combat_driver == null:
		await _cleanup(flow)
		return
	_assert(String(mission_setup.get("scenario_file_path")) == STATION_SCENARIO_PATH, "Full victory trace keeps Station scenario")
	_assert(controller.has_method("issue_primary_mission_interaction"), "Full victory trace uses contextual interaction action")
	if not controller.has_method("issue_primary_mission_interaction"):
		await _cleanup(flow)
		return

	var craft_id: String = _get_mission_drop_craft_id(flow)
	_assert(not craft_id.is_empty(), "Full victory trace receives dropship")
	if craft_id.is_empty():
		await _cleanup(flow)
		return
	_complete_mission_craft_arrival(flow, craft_id)
	await _wait_frames(8)
	controller.call("_on_mission_dropship_card_set_lz_pressed", craft_id)
	_assert(bool(controller.call("_place_lz_from_screen_position", primary_view.call("world_to_screen_position", Vector2(384.0, 224.0)))), "Full victory trace places LZ")
	controller.call("_on_mission_dropship_card_drop_pressed", craft_id)
	await _wait_frames(4)
	controller.call("_complete_drop_sequence_deployment")
	controller.call("_advance_primary_drop_sequence_unloading", 999.0)
	controller.call("_flush_pending_drop_runtime_phase_starts")
	controller.call("_update_ui")
	await _wait_frames(8)

	var fireteam_id: String = _first_displayable_fireteam(controller)
	_assert(not fireteam_id.is_empty(), "Full victory trace deboards Ground-Fireteam")
	if fireteam_id.is_empty():
		await _cleanup(flow)
		return
	controller.call("_on_fireteam_group_pressed", fireteam_id)
	for step in ROUTE_STEPS:
		await _complete_route_step(controller, combat_driver, fireteam_id, step)

	await _wait_frames(10)
	var mission_result: Dictionary = Dictionary(flow.get("_last_mission_result"))
	_assert(String(mission_result.get("result", "")) == "victory", "Cargo completion resolves the mission as victory")
	_assert(String(mission_result.get("mission_outcome", "")) == "won", "Victory result exposes won mission outcome")
	_assert(String(mission_result.get("win_condition_type", "")) == "objective_capture", "Victory keeps scenario win condition")
	var debrief: Node = flow.get_node_or_null("DebriefScreen")
	var debrief_result: Dictionary = Dictionary(debrief.call("get_mission_result")) if debrief != null and debrief.has_method("get_mission_result") else {}
	_assert(String(flow.get("_current_meta_view")) == "debrief", "Full victory reaches existing Debrief view")
	_assert(String(debrief_result.get("result", "")) == "victory" and String(debrief_result.get("mission_outcome", "")) == "won", "Debrief preserves victory outcome")
	await _cleanup(flow)


func _complete_route_step(controller: Node, combat_driver: Node, fireteam_id: String, step: Dictionary) -> void:
	var interaction_id: String = String(step.get("interaction_id", "")).strip_edges()
	var expected_token: String = String(step.get("token", "")).strip_edges()
	var before: Dictionary = Dictionary(controller.call("get_primary_mission_interaction_button_snapshot"))
	_assert(String(before.get("interaction_id", "")) == interaction_id, "Route presents %s as the next contextual action" % expected_token)
	var feedback: Dictionary = Dictionary(controller.call("get_mission_interaction_use_feedback_snapshot"))
	var marker_position: Vector2 = _interaction_marker_position(feedback, interaction_id)
	_assert(marker_position != Vector2.ZERO, "%s interaction resolves a marker position" % expected_token)
	_move_fireteam_units(controller, fireteam_id, marker_position)
	controller.call("_update_ui")
	await _wait_frames(3)
	var ready: Dictionary = Dictionary(controller.call("get_primary_mission_interaction_button_snapshot"))
	var expected_button_text: String = String(step.get("button_text", expected_token)).strip_edges()
	_assert(not bool(ready.get("disabled", true)) and String(ready.get("text", "")).contains(expected_button_text), "%s contextual action is enabled in range" % expected_token)
	var grid_button := controller.get_node_or_null("%s/DoorBreachButton" % COMMAND_GRID_PATH) as Button
	_assert(grid_button != null and not grid_button.disabled, "%s uses the visible command-grid slot" % expected_token)
	if grid_button != null:
		grid_button.emit_signal("pressed")
	await _wait_frames(1)
	var intent: Dictionary = Dictionary(controller.call("get_mission_interaction_use_intent_snapshot"))
	_assert(bool(intent.get("accepted", false)) and String(intent.get("interaction_id", "")) == interaction_id, "%s click creates only its interaction intent" % expected_token)
	_assert(bool(intent.get("requires_go", false)), "%s intent keeps GO separate" % expected_token)
	_assert(bool(controller.call("execute_selected_fireteam_orders")), "%s GO starts existing runtime execution" % expected_token)
	await _fast_forward_fireteam_movement_to_interaction(controller, combat_driver, fireteam_id, interaction_id, maxf(float(step.get("duration_seconds", 0.0)), 1.0) + 1.0)
	var states: Dictionary = Dictionary(combat_driver.call("get_mission_interaction_runtime_states"))
	var state: Dictionary = Dictionary(states.get(interaction_id, {}))
	_assert(bool(state.get("complete", false)) and String(state.get("required_state", "")) == String(step.get("required_state", "")), "%s completion comes from existing runtime progress" % expected_token)
	var expected_next_step_id: String = String(step.get("next_step_id", "")).strip_edges()
	if not expected_next_step_id.is_empty():
		var objective_gate: Dictionary = Dictionary(controller.call("get_mission_interaction_objective_gate_snapshot"))
		_assert(String(objective_gate.get("next_step_id", "")) == expected_next_step_id, "%s completion advances the next route step" % expected_token)


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


func _fast_forward_fireteam_movement_to_interaction(controller: Node, combat_driver: Node, fireteam_id: String, interaction_id: String, hold_delta: float) -> void:
	for _iteration in range(16):
		if not is_instance_valid(controller) or not is_instance_valid(combat_driver):
			return
		var movement_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", fireteam_id))
		var target_positions: Dictionary = Dictionary(movement_state.get("current_target_positions", {}))
		if target_positions.is_empty():
			controller.call("_update_active_phase_execution", hold_delta)
			var idle_states: Dictionary = Dictionary(combat_driver.call("get_mission_interaction_runtime_states"))
			var idle_state: Dictionary = Dictionary(idle_states.get(interaction_id, {}))
			if bool(idle_state.get("complete", false)):
				return
			await _wait_frames(1)
			continue
		for unit_variant in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
			var unit := unit_variant as Node2D
			if unit == null or not unit.has_method("get_unit_id"):
				continue
			var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
			if target_positions.has(unit_id):
				unit.global_position = Vector2(target_positions.get(unit_id, unit.global_position))
		controller.call("_update_active_phase_execution", hold_delta)
		var active_states: Dictionary = Dictionary(combat_driver.call("get_mission_interaction_runtime_states"))
		var active_state: Dictionary = Dictionary(active_states.get(interaction_id, {}))
		if bool(active_state.get("complete", false)):
			return
		await _wait_frames(1)
	_assert(false, "Route interaction movement reaches bounded completion")


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
