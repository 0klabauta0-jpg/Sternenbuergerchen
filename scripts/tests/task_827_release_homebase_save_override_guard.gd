extends SceneTree

const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const TASK_PATH := "res://docs/tasks/TASK_827_release_homebase_save_override_guard.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_827 Release Homebase Save Override Guard ===")
	_test_task_doc_exists()
	await _test_stale_fob_transfer_save_cannot_block_release_homebase()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_827_release_homebase_save_override_guard: FAILED")
		quit(1)
		return
	print("TASK_827_release_homebase_save_override_guard: ALL PASSED")
	quit(0)


func _test_task_doc_exists() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "Task file exists")


func _test_stale_fob_transfer_save_cannot_block_release_homebase() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(8)

	var homebase_screen := scene.get_node_or_null("HomebaseScreen") as Control
	_assert(homebase_screen != null, "Fixture exposes HomebaseScreen")
	_assert(scene.has_method("_ensure_singleplayer_visible_homebase_actionability"), "Meta layer exposes visible actionability guard")
	_assert(scene.has_method("get_singleplayer_start_bootstrap_snapshot"), "Meta layer exposes bootstrap snapshot")
	if homebase_screen == null or not scene.has_method("_ensure_singleplayer_visible_homebase_actionability"):
		scene.queue_free()
		await _wait_frames(2)
		return

	var stale_planning: Dictionary = Dictionary(scene.get("_mission_planning_state")).duplicate(true)
	stale_planning["mission_drop_source"] = "fob"
	stale_planning["drop_ship_requested"] = true
	stale_planning["drop_ship_staged"] = true
	scene.set("_mission_planning_state", stale_planning)
	scene.set("_selected_mission_id", "fob_transfer")
	scene.set("_selected_mission_map_path", "res://maps/Ground_Mission01_32x32.json")
	scene.set_meta("singleplayer_bootstrap_mission_selection_repaired", false)
	scene.set_meta("singleplayer_bootstrap_drop_source_repaired", false)
	scene.set_meta("singleplayer_bootstrap_drop_source_previous", "")
	homebase_screen.set("_homebase_dropship_staged_fireteam_ids_by_craft", {})
	homebase_screen.set("_homebase_dropship_staged_fireteam_ids", PackedStringArray())
	homebase_screen.set("_homebase_dropship_payload_craft_id", "")
	homebase_screen.set("_homebase_direct_boarding_state_by_fireteam_id", {})
	scene.call("_refresh_homebase_screen")
	await _wait_frames(4)

	var blocked_bootstrap: Dictionary = Dictionary(scene.call("get_singleplayer_start_bootstrap_snapshot"))
	_assert(String(blocked_bootstrap.get("selected_mission_id", "")) == "fob_transfer", "Fixture starts with stale FOB-transfer mission")
	_assert(String(blocked_bootstrap.get("mission_drop_source", "")) == "fob", "Fixture starts with stale FOB drop source")

	scene.call("_ensure_singleplayer_visible_homebase_actionability")
	await _wait_frames(8)

	var bootstrap: Dictionary = Dictionary(scene.call("get_singleplayer_start_bootstrap_snapshot"))
	var staging: Dictionary = Dictionary(homebase_screen.call("get_homebase_direct_staging_snapshot"))
	var readiness: Dictionary = Dictionary(homebase_screen.call("get_pre_mission_readiness_snapshot"))
	var startflow: Dictionary = Dictionary(homebase_screen.call("get_pre_mission_startflow_visual_snapshot"))
	var aircraft: Dictionary = Dictionary(homebase_screen.call("get_aircraft_panel_snapshot"))
	var craft_id: String = String(bootstrap.get("craft_id", "")).strip_edges()
	var readiness_text: String = String(readiness.get("rendered_item_text", ""))
	_assert(String(bootstrap.get("selected_mission_id", "")) == "grid_sweep", "Guard restores release direct-sortie mission")
	_assert(String(bootstrap.get("mission_drop_source", "")) == "homebase_direct", "Guard restores Homebase Direct drop source")
	_assert(bool(bootstrap.get("mission_selection_repaired", false)), "Guard records mission-selection repair")
	_assert(bool(bootstrap.get("drop_source_repaired", false)), "Guard records drop-source repair")
	_assert(String(bootstrap.get("drop_source_previous", "")) == "fob", "Guard records previous stale drop source")
	_assert(not craft_id.is_empty(), "Guard keeps or creates bootstrap Dropship")
	_assert(Array(aircraft.get("visible_aircraft_definitions", [])).size() >= 1, "Visible Flightdeck has a shipcard")
	_assert(int(staging.get("payload_operator_count", 0)) >= 2, "Visible payload has operators")
	_assert(int(staging.get("boarded_operator_count", 0)) >= int(staging.get("payload_operator_count", 0)), "Visible payload starts boarded")
	_assert(String(readiness.get("overall_state", "")) == "ready", "Visible readiness is ready")
	_assert(readiness_text.find("STOP Team") < 0, "Readiness no longer shows STOP Team")
	_assert(readiness_text.find("STOP Dropship") < 0, "Readiness no longer shows STOP Dropship")
	_assert(readiness_text.find("STOP Pilot") < 0, "Readiness no longer shows STOP Pilot")
	_assert(readiness_text.find("STOP Boarding") < 0, "Readiness no longer shows STOP Boarding")
	_assert(String(startflow.get("start_button_text", "")) == "Start Mission", "Visible Start Mission text is restored")
	_assert(not bool(startflow.get("start_button_disabled", true)), "Visible Start Mission button is enabled")
	_assert(bool(homebase_screen.call("can_request_mission_start", craft_id)), "Homebase can request mission start after stale save repair")

	scene.queue_free()
	await _wait_frames(2)


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
