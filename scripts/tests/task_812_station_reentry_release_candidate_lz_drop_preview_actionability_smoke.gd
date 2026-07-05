extends SceneTree

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_812_station_reentry_release_candidate_lz_drop_preview_actionability_smoke.md"
const TASK_811_PATH: String = "res://docs/tasks/TASK_811_station_reentry_release_candidate_mission_launch_actionability_smoke.md"
const TASK_540_PATH: String = "res://docs/tasks/TASK_540_mission_first_move_decision_readability_pass.md"
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
	print("=== TASK_812 Station Reentry Release Candidate LZ Drop Preview Actionability Smoke ===")
	_test_docs_contract_and_report()
	await _test_singleplayer_lz_drop_preview_before_go()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_812: FAILED")
		quit(1)
		return
	print("TASK_812: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var meta_text: String = _read_text(META_LAYER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_812 task file exists")
	_assert(FileAccess.file_exists(TASK_811_PATH), "TASK_811 task remains available")
	_assert(FileAccess.file_exists(TASK_540_PATH), "TASK_540 first move task remains available")
	_assert(task_text.contains("LZ Drop Preview Actionability Smoke"), "TASK_812 task names LZ/drop/preview actionability")
	_assert(status_text.contains("TASK_812 - Station Reentry Release Candidate LZ Drop Preview Actionability Smoke"), "Implementation status tracks TASK_812")
	_assert(roadmap_text.contains("TASK_812 - Station Reentry Release Candidate LZ Drop Preview Actionability Smoke (implementiert)"), "Roadmap marks TASK_812 implemented")
	_assert(roadmap_text.contains("TASK_813 - Station Reentry Release Candidate First GO Firefight Actionability Smoke"), "Roadmap advances to TASK_813")
	_assert(contract_text.contains("Station-Reentry-Release-Candidate-LZ-Drop-Preview-Actionability-Smoke"), "Mission command feedback contract documents TASK_812")
	_assert(report_text.contains("TASK_812"), "Reentry handbook preserves TASK_812 context")
	_assert(report_text.contains('data-export-key="reentry_release_candidate_lz_drop_preview_actionability.status"'), "Reentry handbook exports TASK_812 status")
	_assert(meta_text.contains("get_release_candidate_lz_drop_preview_actionability_snapshot"), "MetaLayer exposes TASK_812 snapshot")


func _test_singleplayer_lz_drop_preview_before_go() -> void:
	root.size = Vector2i(1920, 1080)
	var menu: Control = MAIN_MENU_SCENE.instantiate()
	root.add_child(menu)
	current_scene = menu
	await _wait_frames(4)

	var singleplayer_button := menu.get_node_or_null("MenuRail/MenuMargin/MenuVBox/MenuButtons/SingleplayerButton") as Button
	_assert(singleplayer_button != null, "Main menu exposes Singleplayer button")
	if singleplayer_button == null:
		menu.queue_free()
		await _wait_frames(2)
		return

	singleplayer_button.pressed.emit()
	await _wait_frames(14)

	var scene: Node = current_scene
	_assert(scene != null and scene.name == "MetaLayerTest", "Singleplayer opens MetaLayer scene")
	if scene == null or scene.name != "MetaLayerTest":
		return

	var homebase := scene.get_node_or_null("HomebaseScreen") as Control
	_assert(homebase != null, "Singleplayer exposes HomebaseScreen")
	_assert(scene.has_method("get_release_candidate_lz_drop_preview_actionability_snapshot"), "MetaLayer exposes TASK_812 snapshot")
	if homebase == null or not scene.has_method("get_release_candidate_lz_drop_preview_actionability_snapshot"):
		scene.queue_free()
		current_scene = null
		await _wait_frames(2)
		return

	var start_button := homebase.get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/StartMissionButton") as Button
	_assert(start_button != null and start_button.text == "Start Mission" and not start_button.disabled, "Start Mission button is actionable before LZ/drop smoke")
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
	_assert(controller != null and primary_view != null, "Active Mission exposes TacticalController and Primary3DView")
	if controller == null or primary_view == null:
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
	_assert(bool(controller.call("_place_lz_from_screen_position", primary_view.call("world_to_screen_position", lz_world))), "LZ placement succeeds through existing card flow")
	controller.call("_on_mission_dropship_card_drop_pressed", craft_id)
	await _wait_frames(4)
	controller.call("_complete_drop_sequence_deployment")
	controller.call("_advance_primary_drop_sequence_unloading", 999.0)
	controller.call("_flush_pending_drop_runtime_phase_starts")
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	await _wait_frames(10)

	var move_target := Vector2(544.0, 288.0)
	_assert(bool(controller.call("issue_right_click_command_for_test", move_target, "move", false)), "Move preview can be planned through existing right-click command path")
	controller.call("_refresh_world_overlays")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_frames(10)

	var smoke: Dictionary = Dictionary(scene.call("get_release_candidate_lz_drop_preview_actionability_snapshot"))
	var first_move: Dictionary = Dictionary(smoke.get("first_move", {}))
	_assert(String(smoke.get("schema", "")) == "sternenbuergerchen.station_reentry_release_candidate_lz_drop_preview_actionability_smoke.v1", "TASK_812 schema is stable")
	_assert(String(smoke.get("status", "")) == "pass", "LZ/drop/preview actionability smoke passes")
	_assert(int(smoke.get("failed_count", -1)) == 0, "LZ/drop/preview smoke has no critical failures")
	_assert(_snapshot_is_read_only(smoke), "TASK_812 smoke snapshot remains read-only")
	_assert(String(smoke.get("singleplayer_path_expected", "")) == "MainMenu -> Einzelspieler -> Homebase -> Start Mission -> LZ -> Drop -> Move Preview", "Smoke documents the expected LZ/drop/preview path")
	_assert(String(smoke.get("current_meta_view", "")) == "mission", "LZ/drop/preview smoke remains in Mission view")
	_assert(bool(smoke.get("selected_card_has_lz", false)), "Snapshot records selected Dropship LZ")
	_assert(int(smoke.get("deployed_selected_unit_count", 0)) >= 2, "Drop deploys selected Fireteam operators")
	_assert(String(smoke.get("first_move_gate", "")) == "pass", "First move readability gate passes")
	_assert(int(smoke.get("planned_waypoint_count", 0)) > 0, "Planned waypoint exists before GO")
	_assert(int(smoke.get("waypoint_intent_preview_count", 0)) > 0, "Waypoint intent preview exists before GO")
	_assert(int(smoke.get("visualized_waypoint_count", 0)) > 0, "Waypoint visualization exists before GO")
	_assert(bool(smoke.get("go_ready", false)), "GO is ready but not executed")
	_assert(_check_passed(smoke, "preview_before_go_visible"), "Preview, path and waypoint are visible before GO")
	_assert(_check_passed(smoke, "go_ready_not_executed"), "GO-ready check keeps pre-GO state")
	_assert(_check_passed(smoke, "read_only_boundaries"), "TASK_812 boundaries stay read-only")
	_assert(Array(first_move.get("deployed_selected_unit_ids", [])).size() >= 2, "First-move snapshot lists deployed selected operators")

	scene.queue_free()
	current_scene = null
	await _wait_frames(2)


func _complete_mission_craft_arrival(scene: Node, craft_id: String) -> void:
	scene.call("_remove_pending_mission_craft_transfer", craft_id)
	scene.call("_complete_mission_craft_transfer", {"craft_id": craft_id, "phase": "to_mission"})
	scene.call("_sync_homebase_direct_mission_drop_transport_fields")
	scene.call("_start_or_update_active_mission")


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_navigation", true)) \
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
		return
	_failed += 1
	push_error("FAIL: %s" % message)
