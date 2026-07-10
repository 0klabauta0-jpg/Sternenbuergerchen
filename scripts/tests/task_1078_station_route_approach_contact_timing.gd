extends SceneTree

const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const STATION_MISSION_ID: String = "station_route_one_screen_multiplayer_drill"
const APPROACH_MOVE_TARGET := Vector2(2432.0, 5056.0)
const APPROACH_CONTACT_WAIT_FRAMES: int = 12

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1078 Station Route Approach Contact Timing ===")
	await _test_contact_arrives_after_commander_advance()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_contact_arrives_after_commander_advance() -> void:
	root.size = Vector2i(1920, 1080)
	var flow: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(flow)
	await _wait_frames(8)
	var homebase := flow.get_node_or_null("HomebaseScreen") as Control
	_assert(homebase != null, "Approach timing trace exposes Homebase")
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
	_assert(controller != null and primary_view != null and combat_driver != null, "Approach timing trace exposes Station runtime")
	if controller == null or primary_view == null or combat_driver == null:
		await _cleanup(flow)
		return

	var craft_id: String = _get_mission_drop_craft_id(flow)
	_assert(not craft_id.is_empty(), "Approach timing trace receives a dropship")
	if craft_id.is_empty():
		await _cleanup(flow)
		return
	_complete_mission_craft_arrival(flow, craft_id)
	await _wait_frames(8)
	controller.call("_on_mission_dropship_card_set_lz_pressed", craft_id)
	_assert(bool(controller.call("_place_lz_from_screen_position", primary_view.call("world_to_screen_position", Vector2(384.0, 224.0)))), "Approach timing trace places the normal LZ")
	controller.call("_on_mission_dropship_card_drop_pressed", craft_id)
	await _wait_frames(4)
	controller.call("_complete_drop_sequence_deployment")
	controller.call("_advance_primary_drop_sequence_unloading", 999.0)
	controller.call("_flush_pending_drop_runtime_phase_starts")
	controller.call("_update_ui")
	await _wait_frames(8)

	_update_contact_tracking(combat_driver)
	controller.call("refresh_contact_overlay")
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	await _wait_frames(2)
	var before_advance: Dictionary = Dictionary(controller.call("get_mission_first_contact_readability_snapshot"))
	var starts_outside_contact_range: bool = int(before_advance.get("selected_contact_count", 0)) == 0
	_assert(starts_outside_contact_range, "Normal deboard starts outside Bravo contact range")
	if not starts_outside_contact_range:
		await _cleanup(flow)
		return

	var planned: bool = bool(controller.call("issue_right_click_command_for_test", APPROACH_MOVE_TARGET, "move", false))
	_assert(planned, "Approach move creates an existing Move intent")
	_assert(not bool(Dictionary(controller.call("get_fireteam_movement_state", _first_displayable_fireteam(controller))).get("is_executing", false)), "Approach move remains preview-only before GO")
	_assert(bool(controller.call("execute_selected_fireteam_orders")), "GO commits the existing approach Move")
	await _wait_frames(APPROACH_CONTACT_WAIT_FRAMES)
	_update_contact_tracking(combat_driver)
	controller.call("refresh_contact_overlay")
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	await _wait_frames(2)
	var after_advance: Dictionary = Dictionary(controller.call("get_mission_first_contact_readability_snapshot"))
	_assert(int(after_advance.get("selected_contact_count", 0)) > 0, "Scenario-authored Guard creates contact after the committed approach Move")
	var evac: Dictionary = Dictionary(controller.call("get_mission_evacuation_snapshot"))
	_assert(bool(evac.get("eligible", false)), "Approach contact keeps the LZ Evac alternative available")
	_assert(_read_only_snapshot(before_advance) and _read_only_snapshot(after_advance), "Contact timing snapshots remain read-only")
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
		return
	_failed += 1
	push_error("FAIL: %s" % message)
