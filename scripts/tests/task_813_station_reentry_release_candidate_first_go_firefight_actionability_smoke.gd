extends SceneTree

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_813_station_reentry_release_candidate_first_go_firefight_actionability_smoke.md"
const TASK_812_PATH: String = "res://docs/tasks/TASK_812_station_reentry_release_candidate_lz_drop_preview_actionability_smoke.md"
const TASK_541_PATH: String = "res://docs/tasks/TASK_541_mission_first_move_execution_feedback_pass.md"
const TASK_542_PATH: String = "res://docs/tasks/TASK_542_mission_first_contact_readability_pass.md"
const TASK_543_PATH: String = "res://docs/tasks/TASK_543_mission_first_engagement_feedback_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const META_LAYER_PATH: String = "res://scripts/meta/meta_layer_flow.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_813 Station Reentry Release Candidate First GO Firefight Actionability Smoke ===")
	_test_docs_contract_and_report()
	await _test_singleplayer_first_go_firefight_actionability()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_813: FAILED")
		quit(1)
		return
	print("TASK_813: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var meta_text: String = _read_text(META_LAYER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_813 task file exists")
	_assert(FileAccess.file_exists(TASK_812_PATH), "TASK_812 task remains available")
	_assert(FileAccess.file_exists(TASK_541_PATH), "TASK_541 execution task remains available")
	_assert(FileAccess.file_exists(TASK_542_PATH), "TASK_542 contact task remains available")
	_assert(FileAccess.file_exists(TASK_543_PATH), "TASK_543 engagement task remains available")
	_assert(task_text.contains("First GO Firefight Actionability Smoke"), "TASK_813 task names first GO/firefight actionability")
	_assert(status_text.contains("TASK_813 - Station Reentry Release Candidate First GO Firefight Actionability Smoke"), "Implementation status tracks TASK_813")
	_assert(roadmap_text.contains("TASK_813 - Station Reentry Release Candidate First GO Firefight Actionability Smoke (implementiert)"), "Roadmap marks TASK_813 implemented")
	_assert(roadmap_text.contains("TASK_814 - Station Reentry Release Candidate Firefight Feel And HUD Polish Review"), "Roadmap advances to TASK_814")
	_assert(contract_text.contains("Station-Reentry-Release-Candidate-First-GO-Firefight-Actionability-Smoke"), "Mission command feedback contract documents TASK_813")
	_assert(report_text.contains("TASK_813"), "Reentry handbook preserves TASK_813 context")
	_assert(report_text.contains('data-export-key="reentry_release_candidate_first_go_firefight_actionability.status"'), "Reentry handbook exports TASK_813 status")
	_assert(meta_text.contains("get_release_candidate_first_go_firefight_actionability_snapshot"), "MetaLayer exposes TASK_813 snapshot")


func _test_singleplayer_first_go_firefight_actionability() -> void:
	root.size = Vector2i(1920, 1080)
	var menu: Control = MAIN_MENU_SCENE.instantiate()
	root.add_child(menu)
	current_scene = menu
	await _wait_frames(4)

	var singleplayer_button := menu.get_node_or_null("MenuRail/MenuMargin/MenuVBox/MenuButtons/SingleplayerButton") as Button
	_assert(singleplayer_button != null, "Main menu exposes Singleplayer button")
	if singleplayer_button == null:
		menu.queue_free()
		current_scene = null
		await _wait_frames(2)
		return

	singleplayer_button.pressed.emit()
	await _wait_frames(12)

	var scene: Node = current_scene
	_assert(scene != null and scene.name == "MetaLayerTest", "Singleplayer opens MetaLayer scene")
	if scene == null or scene.name != "MetaLayerTest":
		return

	var homebase := scene.get_node_or_null("HomebaseScreen") as Control
	_assert(homebase != null, "Singleplayer exposes HomebaseScreen")
	_assert(scene.has_method("get_release_candidate_first_go_firefight_actionability_snapshot"), "MetaLayer exposes TASK_813 snapshot")
	if homebase == null or not scene.has_method("get_release_candidate_first_go_firefight_actionability_snapshot"):
		scene.queue_free()
		current_scene = null
		await _wait_frames(2)
		return

	var start_button := homebase.get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/StartMissionButton") as Button
	_assert(start_button != null and start_button.text == "Start Mission" and not start_button.disabled, "Start Mission button is actionable before first GO/firefight smoke")
	if start_button == null or start_button.disabled:
		scene.queue_free()
		current_scene = null
		await _wait_frames(2)
		return

	start_button.pressed.emit()
	await _wait_frames(18)

	var active_mission: Node = scene.call("get_active_mission")
	var controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var primary_view: Node = active_mission.get_node_or_null("Primary3DView") if active_mission != null else null
	var combat_driver: Node = active_mission.get_node_or_null("CombatLoopDriver") if active_mission != null else null
	var simulation_root: Node = active_mission.get_node_or_null("SimulationRoot") if active_mission != null else null
	_assert(controller != null and primary_view != null and combat_driver != null and simulation_root != null, "Active Mission exposes TacticalController, Primary3DView, CombatLoopDriver and SimulationRoot")
	if controller == null or primary_view == null or combat_driver == null or simulation_root == null:
		scene.queue_free()
		current_scene = null
		await _wait_frames(2)
		return

	var handoff: Dictionary = Dictionary(scene.call("get_homebase_to_mission_handoff_snapshot"))
	var planning: Dictionary = Dictionary(handoff.get("planning", {}))
	var craft_id: String = String(planning.get("mission_drop_craft_id", "")).strip_edges()
	_complete_mission_craft_arrival(scene, craft_id)
	await _wait_frames(8)

	var lz_world := Vector2(384.0, 224.0)
	controller.call("_on_mission_dropship_card_set_lz_pressed", craft_id)
	_assert(bool(controller.call("_place_lz_from_screen_position", primary_view.call("world_to_screen_position", lz_world))), "LZ placement succeeds before first GO/firefight smoke")
	controller.call("_on_mission_dropship_card_drop_pressed", craft_id)
	await _wait_frames(4)
	controller.call("_complete_drop_sequence_deployment")
	controller.call("_advance_primary_drop_sequence_unloading", 999.0)
	controller.call("_flush_pending_drop_runtime_phase_starts")
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	await _wait_frames(10)

	var move_target := Vector2(544.0, 288.0)
	_assert(bool(controller.call("issue_right_click_command_for_test", move_target, "move", false)), "Move preview can be planned before GO")
	controller.call("_refresh_world_overlays")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_frames(4)

	var pre_go: Dictionary = Dictionary(scene.call("get_release_candidate_lz_drop_preview_actionability_snapshot"))
	var first_move: Dictionary = Dictionary(pre_go.get("first_move", {}))
	var selected_fireteam_id: String = _first_fireteam_id(first_move)
	_assert(String(pre_go.get("status", "")) == "pass", "TASK_812 pre-GO chain remains actionable")
	_assert(not selected_fireteam_id.is_empty(), "Pre-GO snapshot exposes selected Fireteam")
	_assert(bool(controller.call("execute_selected_fireteam_orders")), "GO executes the planned first move order")
	controller.call("_refresh_world_overlays")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_frames(3)

	var contact_setup: Dictionary = _position_first_enemy_near_fireteam(controller, selected_fireteam_id)
	_assert(not contact_setup.is_empty(), "First enemy can be positioned near selected Fireteam for reproducible contact")
	_prepare_fireteam_for_first_engagement(controller, selected_fireteam_id, Vector2(contact_setup.get("enemy_position", Vector2.ZERO)))
	_update_contact_tracking(combat_driver)
	_force_first_engagement_decision(controller, combat_driver, simulation_root, selected_fireteam_id, contact_setup)
	controller.call("refresh_contact_overlay")
	controller.call("refresh_fireteam_security_state")
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	await _wait_frames(10)

	var smoke: Dictionary = Dictionary(scene.call("get_release_candidate_first_go_firefight_actionability_snapshot"))
	var execution: Dictionary = Dictionary(smoke.get("execution", {}))
	var contact: Dictionary = Dictionary(smoke.get("contact", {}))
	var engagement: Dictionary = Dictionary(smoke.get("engagement", {}))
	var execution_movement_state: Dictionary = Dictionary(execution.get("movement_state", {}))
	_assert(String(smoke.get("schema", "")) == "sternenbuergerchen.station_reentry_release_candidate_first_go_firefight_actionability_smoke.v1", "TASK_813 schema is stable")
	_assert(String(smoke.get("status", "")) == "pass", "First GO/firefight actionability smoke passes")
	_assert(int(smoke.get("failed_count", -1)) == 0, "First GO/firefight smoke has no critical failures")
	_assert(_snapshot_is_read_only(smoke), "TASK_813 smoke snapshot remains read-only")
	_assert(String(smoke.get("singleplayer_path_expected", "")) == "MainMenu -> Einzelspieler -> Homebase -> Start Mission -> LZ -> Drop -> Move Preview -> GO -> First Contact -> First Engagement", "Smoke documents the expected first GO/firefight path")
	_assert(String(smoke.get("current_meta_view", "")) == "mission", "First GO/firefight smoke remains in Mission view")
	_assert(bool(smoke.get("go_executed", false)), "Snapshot reports GO execution feedback")
	_assert(int(smoke.get("movement_state_count", 0)) > 0, "Movement state is visible after GO")
	_assert(not execution_movement_state.is_empty() and (not bool(execution_movement_state.get("recent_trace", false)) or not String(execution_movement_state.get("recent_trace_reason", "")).strip_edges().is_empty()), "Completed first move remains readable as active state or recent trace")
	_assert(int(smoke.get("selected_contact_count", 0)) > 0, "First contact is visible after GO")
	_assert(not String(smoke.get("engagement_status", "")).strip_edges().is_empty(), "Engagement status is visible")
	_assert(String(execution.get("gate", "")) == "pass", "Execution feedback gate passes")
	_assert(String(contact.get("gate", "")) == "pass", "First contact gate passes")
	_assert(String(engagement.get("gate", "")) == "pass", "First engagement gate passes")
	_assert(_check_passed(smoke, "go_execution_visible"), "GO execution check passes")
	_assert(_check_passed(smoke, "first_contact_visible"), "First contact check passes")
	_assert(_check_passed(smoke, "first_engagement_feedback_visible"), "First engagement feedback check passes")
	_assert(_check_passed(smoke, "read_only_boundaries"), "TASK_813 boundaries stay read-only")

	scene.queue_free()
	current_scene = null
	await _wait_frames(2)


func _complete_mission_craft_arrival(scene: Node, craft_id: String) -> void:
	scene.call("_remove_pending_mission_craft_transfer", craft_id)
	scene.call("_complete_mission_craft_transfer", {"craft_id": craft_id, "phase": "to_mission"})
	scene.call("_sync_homebase_direct_mission_drop_transport_fields")
	scene.call("_start_or_update_active_mission")


func _first_fireteam_id(first_move: Dictionary) -> String:
	for fireteam_id_variant in Array(first_move.get("selected_fireteam_ids", [])):
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if not fireteam_id.is_empty():
			return fireteam_id
	return ""


func _position_first_enemy_near_fireteam(controller: Node, fireteam_id: String) -> Dictionary:
	var friendly_units: Array = Array(controller.call("_get_fireteam_units", fireteam_id, true))
	var enemy_units: Array = Array(controller.call("_get_all_enemy_units", false))
	if enemy_units.is_empty():
		enemy_units = Array(controller.call("_get_all_enemy_units", true))
	if friendly_units.is_empty() or enemy_units.is_empty():
		return {}
	var friendly := friendly_units[0] as Node2D
	var enemy := enemy_units[0] as Node2D
	if friendly == null or enemy == null:
		return {}
	enemy.global_position = friendly.global_position + Vector2(58.0, 0.0)
	if enemy is CanvasItem:
		(enemy as CanvasItem).visible = true
	return {
		"fireteam_id": fireteam_id,
		"friendly_unit_id": _get_unit_id(friendly),
		"enemy_unit_id": _get_unit_id(enemy),
		"friendly_position": friendly.global_position,
		"enemy_position": enemy.global_position,
	}


func _prepare_fireteam_for_first_engagement(controller: Node, fireteam_id: String, enemy_position: Vector2) -> void:
	for unit_variant in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		var unit := unit_variant as Node2D
		if unit == null:
			continue
		if unit.has_method("set"):
			unit.set("skill_accuracy", 1.0)
		if unit.has_method("set_runtime_status"):
			unit.call(
				"set_runtime_status",
				"holding",
				"hold_position",
				30,
				"fire_at_will",
				"defend",
				1.0,
				0.0,
				0.0,
				1,
				enemy_position,
				"engage",
				"aimed",
				"task813_first_go_firefight",
				1.0,
				75.0
			)


func _force_first_engagement_decision(controller: Node, combat_driver: Node, simulation_root: Node, fireteam_id: String, contact_setup: Dictionary) -> void:
	var enemy_id: String = String(contact_setup.get("enemy_unit_id", "")).strip_edges()
	var detection_progress: Dictionary = Dictionary(combat_driver.get("_detection_progress")).duplicate(true)
	for unit_variant in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		var unit := unit_variant as Node2D
		if unit == null:
			continue
		var friendly_id: String = _get_unit_id(unit)
		if friendly_id.is_empty() or enemy_id.is_empty():
			continue
		detection_progress["%s:%s" % [friendly_id, enemy_id]] = 0
		detection_progress["%s:%s" % [enemy_id, friendly_id]] = 0
	combat_driver.set("_detection_progress", detection_progress)
	combat_driver.set("_current_tick", 120)
	combat_driver.call("align_to_common_decision_step_for_test")
	if combat_driver.has_method("_try_enqueue_attacks"):
		combat_driver.call("_try_enqueue_attacks", simulation_root)


func _update_contact_tracking(combat_driver: Node) -> void:
	if combat_driver.has_method("_update_contact_tracking"):
		combat_driver.call("_update_contact_tracking")
	if combat_driver.has_method("_advance_detection_timers"):
		combat_driver.call("_advance_detection_timers")
	if combat_driver.has_method("_update_contact_tracking"):
		combat_driver.call("_update_contact_tracking")


func _get_unit_id(unit: Node) -> String:
	if unit != null and unit.has_method("get_unit_id"):
		return String(unit.call("get_unit_id"))
	return unit.name if unit != null else ""


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_navigation", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true)) \
		and not bool(snapshot.get("sets_multiplayer_truth", true))


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
