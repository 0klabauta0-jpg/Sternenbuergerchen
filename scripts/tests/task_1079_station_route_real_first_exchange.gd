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
	print("=== TASK_1079 Station Route Real First Exchange ===")
	await _test_real_approach_contact_exposes_existing_engagement_feedback()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_real_approach_contact_exposes_existing_engagement_feedback() -> void:
	root.size = Vector2i(1920, 1080)
	var flow: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(flow)
	await _wait_frames(8)
	var homebase := flow.get_node_or_null("HomebaseScreen") as Control
	_assert(homebase != null, "Real first-exchange trace exposes Homebase")
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
	_assert(controller != null and primary_view != null and combat_driver != null and simulation_root != null, "Real first-exchange trace exposes Station runtime")
	if controller == null or primary_view == null or combat_driver == null or simulation_root == null:
		await _cleanup(flow)
		return
	var craft_id: String = _get_mission_drop_craft_id(flow)
	_assert(not craft_id.is_empty(), "Real first-exchange trace receives a dropship")
	if craft_id.is_empty():
		await _cleanup(flow)
		return
	_complete_mission_craft_arrival(flow, craft_id)
	await _wait_frames(8)
	controller.call("_on_mission_dropship_card_set_lz_pressed", craft_id)
	_assert(bool(controller.call("_place_lz_from_screen_position", primary_view.call("world_to_screen_position", Vector2(384.0, 224.0)))), "Real first-exchange trace places the normal LZ")
	controller.call("_on_mission_dropship_card_drop_pressed", craft_id)
	await _wait_frames(4)
	controller.call("_complete_drop_sequence_deployment")
	controller.call("_advance_primary_drop_sequence_unloading", 999.0)
	controller.call("_flush_pending_drop_runtime_phase_starts")
	controller.call("_update_ui")
	await _wait_frames(8)

	_assert(bool(controller.call("issue_right_click_command_for_test", APPROACH_MOVE_TARGET, "move", false)), "Real first-exchange trace plans the existing approach Move")
	_assert(bool(controller.call("execute_selected_fireteam_orders")), "Real first-exchange trace commits GO")
	await _wait_frames(CONTACT_WAIT_FRAMES)
	_update_contact_tracking(combat_driver)
	controller.call("refresh_contact_overlay")
	controller.call("refresh_fireteam_security_state")
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	await _wait_frames(2)

	var contact: Dictionary = Dictionary(controller.call("get_mission_first_contact_readability_snapshot"))
	var engagement: Dictionary = Dictionary(controller.call("get_mission_first_engagement_feedback_snapshot"))
	_assert(int(contact.get("selected_contact_count", 0)) > 0, "Real approach produces a selected Bravo contact")
	_assert(not String(engagement.get("engagement_status", "")).strip_edges().is_empty(), "Real contact exposes a Fire/Wait/No-Fire decision")
	_assert(not String(engagement.get("engagement_reason", "")).strip_edges().is_empty(), "Real engagement decision names its reason")
	_assert(_has_passed_check(engagement, "cover_range_los_context_visible"), "Real engagement keeps cover, range or LOS context visible")
	var fire_events_before_hold: int = int(engagement.get("fire_event_count", 0))
	_assert(bool(controller.call("set_selected_fireteams_fire_rule", "hold")), "Hold Fire can be selected during the real Guard contact")
	combat_driver.call("_try_enqueue_attacks", simulation_root)
	var held_engagement: Dictionary = Dictionary(controller.call("get_mission_first_engagement_feedback_snapshot"))
	_assert(int(held_engagement.get("fire_event_count", 0)) == fire_events_before_hold, "Hold Fire adds no voluntary fire event during the real Guard contact")
	var evac: Dictionary = Dictionary(controller.call("get_mission_evacuation_snapshot"))
	_assert(bool(evac.get("eligible", false)), "Real first exchange keeps LZ Evac available")
	_assert(_read_only_snapshot(contact) and _read_only_snapshot(engagement), "Real first-exchange snapshots remain read-only")
	await _cleanup(flow)


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


func _has_passed_check(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


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
