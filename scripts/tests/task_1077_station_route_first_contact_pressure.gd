extends SceneTree

const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")
const STATION_MISSION_ID: String = "station_route_one_screen_multiplayer_drill"
const STATION_SCENARIO_PATH: String = "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1077 Station Route First Contact Pressure ===")
	_test_station_scenario_group_patrol_authoring()
	await _test_scenario_authored_first_contact()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_station_scenario_group_patrol_authoring() -> void:
	var scenario = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", STATION_SCENARIO_PATH)
	var validation: Dictionary = Dictionary(scenario.call("validate")) if scenario != null else {}
	_assert(bool(validation.get("valid", false)), "Station guard patrol can target its authored enemy group")


func _test_scenario_authored_first_contact() -> void:
	root.size = Vector2i(1920, 1080)
	var flow: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(flow)
	await _wait_frames(8)
	var homebase := flow.get_node_or_null("HomebaseScreen") as Control
	_assert(homebase != null, "Station contact trace exposes Homebase")
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
	_assert(controller != null and primary_view != null and combat_driver != null, "Station contact trace exposes tactical runtime")
	if controller == null or primary_view == null or combat_driver == null:
		await _cleanup(flow)
		return
	var planning: Dictionary = Dictionary(Dictionary(flow.call("get_homebase_to_mission_handoff_snapshot")).get("planning", {}))
	var craft_id: String = String(planning.get("mission_drop_craft_id", "")).strip_edges()
	_assert(not craft_id.is_empty(), "Station contact trace receives a dropship")
	if craft_id.is_empty():
		await _cleanup(flow)
		return
	_complete_mission_craft_arrival(flow, craft_id)
	await _wait_frames(8)
	controller.call("_on_mission_dropship_card_set_lz_pressed", craft_id)
	_assert(bool(controller.call("_place_lz_from_screen_position", primary_view.call("world_to_screen_position", Vector2(384.0, 224.0)))), "Station contact trace places the normal approach LZ")
	controller.call("_on_mission_dropship_card_drop_pressed", craft_id)
	await _wait_frames(4)
	controller.call("_complete_drop_sequence_deployment")
	controller.call("_advance_primary_drop_sequence_unloading", 999.0)
	controller.call("_flush_pending_drop_runtime_phase_starts")
	controller.call("_update_ui")
	await _wait_frames(8)

	var fireteam_id: String = _first_displayable_fireteam(controller)
	_update_contact_tracking(combat_driver)
	controller.call("refresh_contact_overlay")
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	await _wait_frames(3)
	var contact: Dictionary = Dictionary(controller.call("get_mission_first_contact_readability_snapshot"))
	if int(contact.get("selected_contact_count", 0)) <= 0:
		_print_position_diagnostic(controller, combat_driver, fireteam_id)
	_assert(int(contact.get("selected_contact_count", 0)) > 0, "Scenario-authored Bravo guard creates contact after normal deboard")

	var planned: bool = bool(controller.call("issue_right_click_command_for_test", Vector2(544.0, 288.0), "move", false))
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	await _wait_frames(3)
	var previews: Array = Array(controller.call("get_waypoint_intent_preview_snapshot"))
	var evac: Dictionary = Dictionary(controller.call("get_mission_evacuation_snapshot"))
	_assert(planned and _has_readable_preview(previews, fireteam_id), "Contact pressure keeps the first move as a readable pre-GO preview")
	_assert(bool(evac.get("eligible", false)), "Contact pressure keeps the LZ Evac alternative available")
	_assert(not bool(Dictionary(controller.call("get_fireteam_movement_state", fireteam_id)).get("is_executing", false)), "First-contact preview does not commit movement")
	_assert(_read_only_snapshot(contact), "Contact pressure snapshot remains read-only")
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


func _update_contact_tracking(combat_driver: Node) -> void:
	for _index in range(4):
		combat_driver.call("_update_contact_tracking")
		combat_driver.call("_advance_detection_timers")
	combat_driver.call("_update_contact_tracking")


func _has_readable_preview(previews: Array, fireteam_id: String) -> bool:
	for preview_variant in previews:
		if typeof(preview_variant) != TYPE_DICTIONARY:
			continue
		var preview: Dictionary = Dictionary(preview_variant)
		if String(preview.get("fireteam_id", "")).strip_edges().to_lower() != fireteam_id:
			continue
		return typeof(preview.get("ghost_ftl_position", null)) == TYPE_VECTOR2 \
			and Array(preview.get("ghost_path_points", [])).size() >= 2 \
			and not String(preview.get("risk_state", "")).strip_edges().is_empty() \
			and bool(preview.get("read_only", false))
	return false


func _print_position_diagnostic(controller: Node, combat_driver: Node, fireteam_id: String) -> void:
	var friendlies: Array = Array(controller.call("_get_fireteam_units", fireteam_id, true))
	var enemies: Array = Array(combat_driver.call("_get_enemy_combat_units"))
	var friendly_position: Vector2 = (friendlies[0] as Node2D).global_position if not friendlies.is_empty() and friendlies[0] is Node2D else Vector2.ZERO
	var enemy_positions: Array = []
	for enemy_variant in enemies:
		var enemy := enemy_variant as Node2D
		if enemy != null:
			enemy_positions.append({"id": String(enemy.call("get_unit_id")), "position": enemy.global_position})
	print("TASK_1077 contact diagnostic: %s" % JSON.stringify({"friendly_position": friendly_position, "enemy_positions": enemy_positions}))


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
