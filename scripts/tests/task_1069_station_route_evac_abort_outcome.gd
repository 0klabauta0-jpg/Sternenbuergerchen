extends SceneTree

const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const MISSION_AUTHORITY_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/mission_combat_authority_contract.gd")

const STATION_MISSION_ID: String = "station_route_one_screen_multiplayer_drill"
const STATION_SCENARIO_PATH: String = "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json"
const TEST_LZ_POSITION := Vector2(384.0, 224.0)

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1069 Station Route LZ Evacuation Abort Outcome ===")
	_test_abort_result_contract()
	await _test_station_route_evacuation_outcome()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_abort_result_contract() -> void:
	var result: Dictionary = Dictionary(MISSION_AUTHORITY_CONTRACT_SCRIPT.call(
		"build_mission_result",
		"aborted",
		"",
		"team_alpha",
		"evacuation",
		false,
		12.0,
		[]
	))
	_assert(String(result.get("result", "")) == "aborted", "Authority contract preserves aborted result")
	_assert(String(result.get("mission_outcome", "")) == "aborted", "Authority contract exposes aborted mission outcome")
	_assert(String(result.get("win_condition_type", "")) == "evacuation", "Authority contract preserves evacuation condition")


func _test_station_route_evacuation_outcome() -> void:
	root.size = Vector2i(1920, 1080)
	var flow: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(flow)
	await _wait_frames(8)
	var homebase := flow.get_node_or_null("HomebaseScreen") as Control
	_assert(homebase != null, "Evac trace exposes Homebase")
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
	_assert(mission_setup != null and controller != null and primary_view != null and combat_driver != null, "Evac trace exposes Station mission runtime")
	if mission_setup == null or controller == null or primary_view == null or combat_driver == null:
		await _cleanup(flow)
		return
	_assert(String(mission_setup.get("scenario_file_path")) == STATION_SCENARIO_PATH, "Evac trace keeps Station scenario")
	_assert(controller.has_method("get_mission_evacuation_snapshot"), "Tactical Controller exposes read-only evacuation eligibility")
	_assert(controller.has_method("request_selected_fireteam_evacuation"), "Tactical Controller exposes evacuation request")
	_assert(combat_driver.has_method("request_mission_evacuation"), "Combat Driver exposes authoritative evacuation request")
	if not controller.has_method("get_mission_evacuation_snapshot") or not controller.has_method("request_selected_fireteam_evacuation"):
		await _cleanup(flow)
		return
	if not combat_driver.has_method("request_mission_evacuation"):
		await _cleanup(flow)
		return
	combat_driver.set("_runs_local_authority", false)
	var client_request: Dictionary = Dictionary(combat_driver.call("request_mission_evacuation"))
	_assert(not bool(client_request.get("accepted", true)) and String(client_request.get("reason", "")) == "not_authority", "Non-authority evacuation request is rejected")
	_assert(Dictionary(combat_driver.call("get_mission_result")).is_empty(), "Rejected client evacuation leaves mission active")
	combat_driver.set("_runs_local_authority", true)

	var craft_id: String = _get_mission_drop_craft_id(flow)
	_assert(not craft_id.is_empty(), "Evac trace receives mission dropship")
	if craft_id.is_empty():
		await _cleanup(flow)
		return
	_complete_mission_craft_arrival(flow, craft_id)
	await _wait_frames(8)
	var before_lz: Dictionary = Dictionary(controller.call("get_mission_evacuation_snapshot"))
	_assert(not bool(before_lz.get("eligible", true)), "Evac stays blocked before LZ placement")
	_assert(String(before_lz.get("reason", "")) == "lz_missing", "Evac names missing LZ")

	controller.call("_on_mission_dropship_card_set_lz_pressed", craft_id)
	_assert(bool(controller.call("_place_lz_from_screen_position", primary_view.call("world_to_screen_position", TEST_LZ_POSITION))), "Evac trace places LZ")
	controller.call("_on_mission_dropship_card_drop_pressed", craft_id)
	await _wait_frames(4)
	controller.call("_complete_drop_sequence_deployment")
	controller.call("_advance_primary_drop_sequence_unloading", 999.0)
	controller.call("_flush_pending_drop_runtime_phase_starts")
	controller.call("_update_ui")
	await _wait_frames(8)

	var fireteam_id: String = _first_displayable_fireteam(controller)
	_assert(not fireteam_id.is_empty(), "Evac trace deboards a Ground-Fireteam")
	if fireteam_id.is_empty():
		await _cleanup(flow)
		return
	controller.call("_on_fireteam_group_pressed", fireteam_id)
	var selected_snapshot: Dictionary = Dictionary(controller.call("get_mission_evacuation_snapshot"))
	var resolved_lz_position: Vector2 = Vector2(selected_snapshot.get("lz_position", TEST_LZ_POSITION))
	_move_fireteam_to_lz(controller, fireteam_id, resolved_lz_position + Vector2(144.0, 0.0))
	controller.call("_update_ui")
	await _wait_frames(2)
	var outside_lz: Dictionary = Dictionary(controller.call("get_mission_evacuation_snapshot"))
	_assert(not bool(outside_lz.get("eligible", true)), "Evac stays blocked while Fireteam is outside LZ")
	_assert(String(outside_lz.get("reason", "")) == "fireteam_outside_lz", "Evac names regroup requirement")
	var evac_button := controller.get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/MissionEvacuationButton") as Button
	_assert(evac_button != null and evac_button.visible and evac_button.disabled, "Visible EVAC button is disabled outside LZ")
	_move_fireteam_to_lz(controller, fireteam_id, resolved_lz_position)
	controller.call("_update_ui")
	await _wait_frames(3)
	var eligible: Dictionary = Dictionary(controller.call("get_mission_evacuation_snapshot"))
	_assert(bool(eligible.get("eligible", false)), "Evac becomes available with selected Ground-Fireteam in LZ")
	_assert(bool(eligible.get("read_only", false)) and not bool(eligible.get("ui_sets_gameplay_truth", true)), "Evac eligibility remains read-only")
	_assert(evac_button != null and not evac_button.disabled, "Visible EVAC button becomes actionable in LZ")

	var evacuation: Dictionary = Dictionary(controller.call("request_selected_fireteam_evacuation"))
	_assert(bool(evacuation.get("accepted", false)), "Host evacuation request is accepted in LZ")
	var mission_result: Dictionary = Dictionary(evacuation.get("mission_result", {}))
	_assert(String(mission_result.get("result", "")) == "aborted", "Evacuation resolves aborted mission result")
	_assert(String(mission_result.get("mission_outcome", "")) == "aborted", "Evacuation result uses aborted outcome")
	_assert(String(mission_result.get("win_condition_type", "")) == "evacuation", "Evacuation result keeps evacuation condition")
	await _wait_frames(8)
	var debrief: Node = flow.get_node_or_null("DebriefScreen")
	var debrief_result: Dictionary = Dictionary(debrief.call("get_mission_result")) if debrief != null and debrief.has_method("get_mission_result") else {}
	_assert(String(flow.get("_current_meta_view")) == "debrief", "Evacuation reaches existing Debrief view")
	_assert(String(debrief_result.get("result", "")) == "aborted" and String(debrief_result.get("win_condition_type", "")) == "evacuation", "Debrief preserves evacuation result")
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


func _move_fireteam_to_lz(controller: Node, fireteam_id: String, lz_position: Vector2) -> void:
	for unit_variant in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		var unit := unit_variant as Node2D
		if unit != null:
			unit.global_position = lz_position


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
