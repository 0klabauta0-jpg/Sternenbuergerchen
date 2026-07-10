extends SceneTree

const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const STATION_MISSION_ID: String = "station_route_one_screen_multiplayer_drill"
const COMMAND_BUTTON_PATH: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/DoorBreachButton"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1072 Contextual Interaction HUD Semantics ===")
	await _test_station_route_contextual_slot_semantics()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_station_route_contextual_slot_semantics() -> void:
	root.size = Vector2i(1920, 1080)
	var flow: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(flow)
	await _wait_frames(8)
	var homebase := flow.get_node_or_null("HomebaseScreen") as Control
	_assert(homebase != null, "HUD semantics trace exposes Homebase")
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
	_assert(controller != null and primary_view != null and combat_driver != null, "HUD semantics trace exposes mission runtime")
	if controller == null or primary_view == null or combat_driver == null:
		await _cleanup(flow)
		return
	var craft_id: String = _get_mission_drop_craft_id(flow)
	_assert(not craft_id.is_empty(), "HUD semantics trace receives dropship")
	if craft_id.is_empty():
		await _cleanup(flow)
		return
	_complete_mission_craft_arrival(flow, craft_id)
	await _wait_frames(8)
	controller.call("_on_mission_dropship_card_set_lz_pressed", craft_id)
	_assert(bool(controller.call("_place_lz_from_screen_position", primary_view.call("world_to_screen_position", Vector2(384.0, 224.0)))), "HUD semantics trace places LZ")
	controller.call("_on_mission_dropship_card_drop_pressed", craft_id)
	await _wait_frames(4)
	controller.call("_complete_drop_sequence_deployment")
	controller.call("_advance_primary_drop_sequence_unloading", 999.0)
	controller.call("_flush_pending_drop_runtime_phase_starts")
	controller.call("_update_ui")
	await _wait_frames(8)
	var fireteam_id: String = _first_displayable_fireteam(controller)
	_assert(not fireteam_id.is_empty(), "HUD semantics trace deboards Ground-Fireteam")
	if fireteam_id.is_empty():
		await _cleanup(flow)
		return
	controller.call("_on_fireteam_group_pressed", fireteam_id)

	await _assert_slot_semantics(controller, fireteam_id, "aa_shutdown_zone", "AA", "AA", "mission.command.take", false)
	combat_driver.call("set_mission_scenario_runtime_step_state", "disable_air_defense", "aa_disabled")
	await _wait_frames(2)
	await _assert_slot_semantics(controller, fireteam_id, "station_route_drill_door", "B->GO", "Breach", "mission.command.breach_door", true)
	await _cleanup(flow)


func _assert_slot_semantics(controller: Node, fireteam_id: String, interaction_id: String, text_fragment: String, tooltip_fragment: String, expected_help_id: String, expects_door_shortcut: bool) -> void:
	var feedback: Dictionary = Dictionary(controller.call("get_mission_interaction_use_feedback_snapshot"))
	var marker_position: Vector2 = _interaction_marker_position(feedback, interaction_id)
	_assert(marker_position != Vector2.ZERO, "%s resolves interaction marker" % interaction_id)
	_move_fireteam_units(controller, fireteam_id, marker_position)
	controller.call("_update_ui")
	controller.call("_apply_command_hierarchy_metadata")
	await _wait_frames(2)
	var button := controller.get_node_or_null(COMMAND_BUTTON_PATH) as Button
	_assert(button != null and not button.disabled, "%s slot is enabled in range" % interaction_id)
	if button == null:
		return
	_assert(String(button.text).contains(text_fragment), "%s slot text matches active interaction" % interaction_id)
	_assert(String(button.tooltip_text).contains(tooltip_fragment), "%s tooltip matches active interaction" % interaction_id)
	_assert(String(button.get_meta("help_id", "")) == expected_help_id, "%s help id matches active interaction" % interaction_id)
	_assert(bool(button.get_meta("mission_interaction_requires_go", false)), "%s metadata keeps GO separate" % interaction_id)
	_assert(bool(button.get_meta("mission_interaction_type", "").strip_edges() == "door") == expects_door_shortcut, "%s metadata identifies Door-only shortcut context" % interaction_id)
	if expects_door_shortcut:
		_assert(String(button.get_meta("command_hierarchy_action_id", "")) == "breach_door", "Door retains breach hierarchy action")
		_assert(String(button.tooltip_text).contains("B") and String(button.get_meta("door_interaction_shortcut", "")) == "B", "Door retains B shortcut affordance")
	else:
		_assert(String(button.get_meta("command_hierarchy_action_id", "")) == "mission_interaction" and String(button.get_meta("command_hierarchy_group_help_id", "")) == expected_help_id, "Non-Door metadata uses active interaction semantics")
		_assert(not String(button.tooltip_text).contains("Breach") and String(button.get_meta("door_interaction_shortcut", "")).is_empty(), "Non-Door interaction does not advertise Breach or B")


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
