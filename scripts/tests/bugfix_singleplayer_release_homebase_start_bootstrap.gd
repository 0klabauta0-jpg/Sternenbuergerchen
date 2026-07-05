extends SceneTree

const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")
const TASK_PATH := "res://docs/tasks/BUGFIX_singleplayer_release_homebase_start_bootstrap.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== BUGFIX Singleplayer Release Homebase Start Bootstrap ===")
	_test_task_doc_exists()
	await _test_singleplayer_homebase_starts_with_playable_payload()
	await _test_main_menu_singleplayer_route_starts_with_playable_payload()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("BUGFIX_singleplayer_release_homebase_start_bootstrap: FAILED")
		quit(1)
		return
	print("BUGFIX_singleplayer_release_homebase_start_bootstrap: ALL PASSED")
	quit(0)


func _test_task_doc_exists() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "Bugfix task file exists")


func _test_singleplayer_homebase_starts_with_playable_payload() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(8)

	var homebase_screen := scene.get_node_or_null("HomebaseScreen") as Control
	_assert(homebase_screen != null, "Meta layer exposes HomebaseScreen")
	_assert(scene.has_method("get_singleplayer_start_bootstrap_snapshot"), "Meta layer exposes bootstrap snapshot")

	var bootstrap: Dictionary = Dictionary(scene.call("get_singleplayer_start_bootstrap_snapshot"))
	var craft_id: String = String(bootstrap.get("craft_id", "")).strip_edges()
	_assert(bool(bootstrap.get("enabled", false)), "Singleplayer bootstrap is enabled")
	_assert(bool(bootstrap.get("payload_seeded", false)), "Singleplayer bootstrap seeds Homebase payload")
	_assert(Array(bootstrap.get("selected_unit_ids", [])).size() >= 2, "Bootstrap selects a playable fireteam")
	_assert(Array(bootstrap.get("selected_fireteam_ids", [])).size() == Array(bootstrap.get("selected_unit_ids", [])).size(), "Bootstrap preserves one Fireteam id per selected operator")
	_assert(not craft_id.is_empty(), "Bootstrap creates or reuses a Dropship")
	_assert(not String(bootstrap.get("pilot_unit_id", "")).strip_edges().is_empty(), "Bootstrap assigns a pilot")
	_assert(String(bootstrap.get("craft_location", "")).strip_edges() == "homebase", "Bootstrap craft starts at Homebase")

	var readiness: Dictionary = Dictionary(homebase_screen.call("get_pre_mission_readiness_snapshot"))
	_assert(String(readiness.get("overall_state", "")) == "ready", "Homebase readiness is ready on first Singleplayer screen")
	_assert(bool(homebase_screen.call("can_request_mission_start", craft_id)), "Homebase can request mission start for bootstrap Dropship")

	homebase_screen.call("request_mission_start", craft_id)
	await _wait_frames(8)
	var handoff: Dictionary = Dictionary(scene.call("get_homebase_to_mission_handoff_snapshot"))
	_assert(String(handoff.get("handoff_gate", "")) == "pass", "Bootstrap launch passes Homebase-to-Mission handoff")
	_assert(int(handoff.get("failed_count", -1)) == 0, "Bootstrap launch has no critical handoff failures")

	scene.queue_free()
	await _wait_frames(2)


func _test_main_menu_singleplayer_route_starts_with_playable_payload() -> void:
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
	await _wait_frames(12)

	var scene: Node = current_scene
	_assert(scene != null and scene.name == "MetaLayerTest", "Singleplayer button routes to MetaLayer scene")
	if scene == null or scene.name != "MetaLayerTest":
		return

	var homebase_screen := scene.get_node_or_null("HomebaseScreen") as Control
	_assert(homebase_screen != null, "Menu-launched MetaLayer exposes HomebaseScreen")
	_assert(scene.has_method("get_singleplayer_start_bootstrap_snapshot"), "Menu-launched MetaLayer exposes bootstrap snapshot")
	if homebase_screen == null or not scene.has_method("get_singleplayer_start_bootstrap_snapshot"):
		scene.queue_free()
		await _wait_frames(2)
		return

	var bootstrap: Dictionary = Dictionary(scene.call("get_singleplayer_start_bootstrap_snapshot"))
	var staging: Dictionary = Dictionary(homebase_screen.call("get_homebase_direct_staging_snapshot"))
	var readiness: Dictionary = Dictionary(homebase_screen.call("get_pre_mission_readiness_snapshot"))
	var startflow: Dictionary = Dictionary(homebase_screen.call("get_pre_mission_startflow_visual_snapshot"))
	var aircraft: Dictionary = Dictionary(homebase_screen.call("get_aircraft_panel_snapshot"))
	var craft_id: String = String(bootstrap.get("craft_id", "")).strip_edges()
	_assert(bool(bootstrap.get("enabled", false)), "Menu-launched bootstrap is enabled")
	_assert(bool(bootstrap.get("payload_seeded", false)), "Menu-launched bootstrap seeds payload")
	_assert(Array(bootstrap.get("selected_unit_ids", [])).size() >= 2, "Menu-launched bootstrap selects operators")
	_assert(Array(staging.get("payload_fireteam_ids", [])).size() >= 1, "Menu-launched Homebase has payload Fireteam")
	_assert(int(staging.get("payload_operator_count", 0)) >= 2, "Menu-launched Homebase payload has operators")
	_assert(int(staging.get("boarded_operator_count", 0)) >= int(staging.get("payload_operator_count", 0)), "Menu-launched payload starts boarded")
	_assert(String(readiness.get("overall_state", "")) == "ready", "Menu-launched Homebase readiness is ready")
	_assert(String(readiness.get("rendered_item_text", "")).find("STOP Team") < 0, "Menu-launched visible readiness no longer shows STOP Team")
	_assert(String(readiness.get("rendered_item_text", "")).find("STOP Dropship") < 0, "Menu-launched visible readiness no longer shows STOP Dropship")
	_assert(String(readiness.get("rendered_item_text", "")).find("STOP Pilot") < 0, "Menu-launched visible readiness no longer shows STOP Pilot")
	_assert(String(readiness.get("rendered_item_text", "")).find("STOP Boarding") < 0, "Menu-launched visible readiness no longer shows STOP Boarding")
	_assert(String(startflow.get("start_button_text", "")) == "Start Mission", "Menu-launched visible start button is actionable")
	_assert(not bool(startflow.get("start_button_disabled", true)), "Menu-launched visible start button is enabled")
	_assert(Array(aircraft.get("visible_aircraft_definitions", [])).size() >= 1, "Menu-launched visible Flightdeck has a shipcard")
	_assert(not String(aircraft.get("selected_status_text", "")).contains("Flight deck empty"), "Menu-launched Flightdeck does not render the empty blocker")
	_assert(bool(homebase_screen.call("can_request_mission_start", craft_id)), "Menu-launched Homebase can request mission start")

	scene.queue_free()
	current_scene = null
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
