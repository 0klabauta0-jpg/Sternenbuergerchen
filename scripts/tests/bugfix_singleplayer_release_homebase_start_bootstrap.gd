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
	await _test_visible_homebase_deadend_is_repaired()
	await _test_post_show_visible_homebase_deadend_is_repaired()
	await _test_partial_saved_start_state_is_repaired()
	await _test_stale_payload_seed_uses_visible_fireteam_fallback()
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
	var planning: Dictionary = Dictionary(handoff.get("planning", {}))
	_assert(String(handoff.get("handoff_gate", "")) == "pass", "Bootstrap launch passes Homebase-to-Mission handoff")
	_assert(int(handoff.get("failed_count", -1)) == 0, "Bootstrap launch has no critical handoff failures")
	_assert(String(handoff.get("selected_mission_id", "")) == "grid_sweep", "Bootstrap launch keeps the small playable default mission")
	_assert(String(planning.get("mission_drop_source", "")) == "homebase_direct", "Bootstrap launch records Homebase Direct as mission drop source")

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
	_assert(bool(bootstrap.get("visible_homebase_post_show_guard_ran", false)), "Menu-launched post-show guard runs after Homebase becomes visible")
	_assert(bool(bootstrap.get("visible_homebase_post_show_guard_after_actionable", false)), "Menu-launched post-show guard leaves Homebase actionable")
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


func _test_visible_homebase_deadend_is_repaired() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(8)

	var homebase_screen := scene.get_node_or_null("HomebaseScreen") as Control
	_assert(homebase_screen != null, "Visible dead-end repair exposes HomebaseScreen")
	_assert(scene.has_method("_ensure_singleplayer_visible_homebase_actionability"), "Meta layer exposes visible Homebase actionability guard")
	if homebase_screen == null or not scene.has_method("_ensure_singleplayer_visible_homebase_actionability"):
		scene.queue_free()
		await _wait_frames(2)
		return

	scene.set("_homebase_staged_unit_ids", PackedStringArray())
	scene.set("_homebase_staged_fireteam_ids", PackedStringArray())
	scene.set("_selected_unit_ids", PackedStringArray())
	scene.set("_selected_fireteam_ids", PackedStringArray())
	scene.set("_homebase_aircraft_definitions", [])
	scene.set("_assigned_aircraft_pilot_by_craft", {})
	scene.set("_aircraft_location_by_craft", {})
	scene.set_meta("singleplayer_visible_homebase_deadend_repaired", false)
	scene.set_meta("singleplayer_visible_homebase_deadend_repair_mode", "")
	homebase_screen.set("_homebase_dropship_staged_fireteam_ids_by_craft", {})
	homebase_screen.set("_homebase_dropship_staged_fireteam_ids", PackedStringArray())
	homebase_screen.set("_homebase_dropship_payload_craft_id", "")
	homebase_screen.set("_homebase_direct_boarding_state_by_fireteam_id", {})
	scene.call("_refresh_homebase_screen")
	await _wait_frames(4)

	var blocked_staging: Dictionary = Dictionary(homebase_screen.call("get_homebase_direct_staging_snapshot"))
	var blocked_readiness: Dictionary = Dictionary(homebase_screen.call("get_pre_mission_readiness_snapshot"))
	_assert(int(blocked_staging.get("payload_operator_count", 0)) == 0, "Visible dead-end fixture starts with empty payload")
	_assert(String(blocked_readiness.get("overall_state", "")) != "ready", "Visible dead-end fixture starts blocked")

	scene.call("_ensure_singleplayer_visible_homebase_actionability")
	await _wait_frames(8)

	var bootstrap: Dictionary = Dictionary(scene.call("get_singleplayer_start_bootstrap_snapshot"))
	var staging: Dictionary = Dictionary(homebase_screen.call("get_homebase_direct_staging_snapshot"))
	var readiness: Dictionary = Dictionary(homebase_screen.call("get_pre_mission_readiness_snapshot"))
	var startflow: Dictionary = Dictionary(homebase_screen.call("get_pre_mission_startflow_visual_snapshot"))
	var aircraft: Dictionary = Dictionary(homebase_screen.call("get_aircraft_panel_snapshot"))
	var craft_id: String = String(bootstrap.get("craft_id", "")).strip_edges()
	_assert(bool(bootstrap.get("visible_homebase_deadend_repaired", false)), "Visible Homebase dead-end guard records repair")
	_assert(String(bootstrap.get("visible_homebase_deadend_repair_mode", "")) == "preserve_existing" or String(bootstrap.get("visible_homebase_deadend_repair_mode", "")) == "force_default", "Visible Homebase dead-end repair mode is named")
	_assert(not craft_id.is_empty(), "Visible dead-end repair creates a Dropship")
	_assert(not String(bootstrap.get("pilot_unit_id", "")).strip_edges().is_empty(), "Visible dead-end repair assigns a pilot")
	_assert(Array(aircraft.get("visible_aircraft_definitions", [])).size() >= 1, "Visible dead-end repair shows a Flightdeck shipcard")
	_assert(int(staging.get("payload_operator_count", 0)) >= 2, "Visible dead-end repair restores payload operators")
	_assert(int(staging.get("boarded_operator_count", 0)) >= int(staging.get("payload_operator_count", 0)), "Visible dead-end repair boards payload")
	_assert(String(readiness.get("overall_state", "")) == "ready", "Visible dead-end repair makes readiness ready")
	_assert(String(startflow.get("start_button_text", "")) == "Start Mission", "Visible dead-end repair restores Start Mission text")
	_assert(not bool(startflow.get("start_button_disabled", true)), "Visible dead-end repair enables Start Mission")
	_assert(bool(homebase_screen.call("can_request_mission_start", craft_id)), "Visible dead-end repair can request mission start")

	scene.queue_free()
	await _wait_frames(2)


func _test_post_show_visible_homebase_deadend_is_repaired() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(8)

	var homebase_screen := scene.get_node_or_null("HomebaseScreen") as Control
	_assert(homebase_screen != null, "Post-show dead-end repair exposes HomebaseScreen")
	_assert(scene.has_method("_show_homebase"), "Meta layer exposes Homebase show route for regression")
	if homebase_screen == null or not scene.has_method("_show_homebase"):
		scene.queue_free()
		await _wait_frames(2)
		return

	scene.set("_homebase_staged_unit_ids", PackedStringArray())
	scene.set("_homebase_staged_fireteam_ids", PackedStringArray())
	scene.set("_selected_unit_ids", PackedStringArray())
	scene.set("_selected_fireteam_ids", PackedStringArray())
	scene.set("_homebase_aircraft_definitions", [])
	scene.set("_assigned_aircraft_pilot_by_craft", {})
	scene.set("_aircraft_location_by_craft", {})
	scene.set_meta("singleplayer_visible_homebase_deadend_repaired", false)
	scene.set_meta("singleplayer_visible_homebase_deadend_repair_mode", "")
	scene.set_meta("singleplayer_visible_homebase_post_show_guard_ran", false)
	scene.set_meta("singleplayer_visible_homebase_post_show_guard_before_actionable", true)
	scene.set_meta("singleplayer_visible_homebase_post_show_guard_after_actionable", false)
	scene.set_meta("singleplayer_visible_homebase_post_show_guard_repaired", false)
	homebase_screen.set("_homebase_dropship_staged_fireteam_ids_by_craft", {})
	homebase_screen.set("_homebase_dropship_staged_fireteam_ids", PackedStringArray())
	homebase_screen.set("_homebase_dropship_payload_craft_id", "")
	homebase_screen.set("_homebase_direct_boarding_state_by_fireteam_id", {})
	scene.call("_show_homebase")
	await _wait_frames(12)

	var bootstrap: Dictionary = Dictionary(scene.call("get_singleplayer_start_bootstrap_snapshot"))
	var staging: Dictionary = Dictionary(homebase_screen.call("get_homebase_direct_staging_snapshot"))
	var readiness: Dictionary = Dictionary(homebase_screen.call("get_pre_mission_readiness_snapshot"))
	var startflow: Dictionary = Dictionary(homebase_screen.call("get_pre_mission_startflow_visual_snapshot"))
	var aircraft: Dictionary = Dictionary(homebase_screen.call("get_aircraft_panel_snapshot"))
	var craft_id: String = String(bootstrap.get("craft_id", "")).strip_edges()
	_assert(bool(bootstrap.get("visible_homebase_post_show_guard_ran", false)), "Post-show guard records that it ran")
	_assert(not bool(bootstrap.get("visible_homebase_post_show_guard_before_actionable", true)), "Post-show guard sees the visible Homebase dead-end before repair")
	_assert(bool(bootstrap.get("visible_homebase_post_show_guard_after_actionable", false)), "Post-show guard records actionable Homebase after repair")
	_assert(bool(bootstrap.get("visible_homebase_post_show_guard_repaired", false)), "Post-show guard records a real repair")
	_assert(not craft_id.is_empty(), "Post-show repair creates a Dropship")
	_assert(Array(aircraft.get("visible_aircraft_definitions", [])).size() >= 1, "Post-show repair shows a Flightdeck shipcard")
	_assert(int(staging.get("payload_operator_count", 0)) >= 2, "Post-show repair restores payload operators")
	_assert(int(staging.get("boarded_operator_count", 0)) >= int(staging.get("payload_operator_count", 0)), "Post-show repair boards payload")
	_assert(String(readiness.get("overall_state", "")) == "ready", "Post-show repair makes readiness ready")
	_assert(String(startflow.get("start_button_text", "")) == "Start Mission", "Post-show repair restores Start Mission text")
	_assert(not bool(startflow.get("start_button_disabled", true)), "Post-show repair enables Start Mission")
	_assert(bool(homebase_screen.call("can_request_mission_start", craft_id)), "Post-show repair can request mission start")

	scene.queue_free()
	await _wait_frames(2)


func _test_partial_saved_start_state_is_repaired() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(8)

	var homebase_screen := scene.get_node_or_null("HomebaseScreen") as Control
	_assert(homebase_screen != null, "Partial saved state exposes HomebaseScreen")
	_assert(scene.has_method("get_singleplayer_start_bootstrap_snapshot"), "Partial saved state exposes bootstrap snapshot")
	if homebase_screen == null or not scene.has_method("get_singleplayer_start_bootstrap_snapshot"):
		scene.queue_free()
		await _wait_frames(2)
		return

	var partial_roster: Array = [
		{
			"unit_id": "partial_rifle_1",
			"display_name": "Partial Rifle 1",
			"role_name": "Rifleman",
			"callsign": "P1",
		},
		{
			"unit_id": "partial_rifle_2",
			"display_name": "Partial Rifle 2",
			"role_name": "Rifleman",
			"callsign": "P2",
		},
	]
	scene.set("_all_team_units", partial_roster.duplicate(true))
	scene.set("_available_team_units", partial_roster.duplicate(true))
	scene.set("_homebase_staged_unit_ids", PackedStringArray(["partial_rifle_1", "partial_rifle_2"]))
	scene.set("_homebase_staged_fireteam_ids", PackedStringArray(["custom_ft", "custom_ft"]))
	scene.set("_selected_unit_ids", PackedStringArray(["partial_rifle_1", "partial_rifle_2"]))
	scene.set("_selected_fireteam_ids", PackedStringArray(["custom_ft", "custom_ft"]))
	scene.set("_homebase_aircraft_definitions", [])
	scene.set("_assigned_aircraft_pilot_by_craft", {})
	scene.set("_aircraft_location_by_craft", {})
	scene.set_meta("singleplayer_bootstrap_roster_repaired", false)
	scene.set_meta("singleplayer_bootstrap_selection_repaired", false)
	scene.set_meta("singleplayer_bootstrap_pilot_repaired", false)
	homebase_screen.set("_homebase_dropship_staged_fireteam_ids_by_craft", {})
	homebase_screen.set("_homebase_dropship_staged_fireteam_ids", PackedStringArray())
	homebase_screen.set("_homebase_dropship_payload_craft_id", "")
	homebase_screen.set("_homebase_direct_boarding_state_by_fireteam_id", {})
	scene.call("_ensure_singleplayer_release_start_bootstrap")
	scene.call("_refresh_homebase_screen")
	scene.call("_seed_singleplayer_bootstrap_homebase_payload")
	scene.call("_refresh_homebase_screen")
	await _wait_frames(8)

	var bootstrap: Dictionary = Dictionary(scene.call("get_singleplayer_start_bootstrap_snapshot"))
	var staging: Dictionary = Dictionary(homebase_screen.call("get_homebase_direct_staging_snapshot"))
	var readiness: Dictionary = Dictionary(homebase_screen.call("get_pre_mission_readiness_snapshot"))
	var startflow: Dictionary = Dictionary(homebase_screen.call("get_pre_mission_startflow_visual_snapshot"))
	var aircraft: Dictionary = Dictionary(homebase_screen.call("get_aircraft_panel_snapshot"))
	var craft_id: String = String(bootstrap.get("craft_id", "")).strip_edges()
	_assert(bool(bootstrap.get("enabled", false)), "Partial saved state keeps bootstrap enabled")
	_assert(bool(bootstrap.get("roster_repaired", false)), "Partial saved state repairs missing roster floor")
	_assert(bool(bootstrap.get("pilot_repaired", false)), "Partial saved state assigns a repaired pilot")
	_assert(bool(bootstrap.get("has_pilot_candidate", false)), "Partial saved state has a pilot candidate after repair")
	_assert(bool(bootstrap.get("payload_seeded", false)), "Partial saved state seeds payload")
	_assert(String(bootstrap.get("pilot_unit_id", "")).strip_edges() != "", "Partial saved state exposes pilot id")
	_assert(String(bootstrap.get("craft_location", "")) == "homebase", "Partial saved state craft is parked at Homebase")
	_assert(Array(staging.get("payload_fireteam_ids", [])).has("custom_ft"), "Partial saved state seeds actual staged Fireteam id")
	_assert(int(staging.get("payload_operator_count", 0)) >= 2, "Partial saved state has payload operators")
	_assert(int(staging.get("boarded_operator_count", 0)) >= int(staging.get("payload_operator_count", 0)), "Partial saved state starts boarded")
	_assert(String(readiness.get("overall_state", "")) == "ready", "Partial saved state readiness is ready")
	_assert(String(startflow.get("start_button_text", "")) == "Start Mission", "Partial saved state keeps Start Mission button")
	_assert(not bool(startflow.get("start_button_disabled", true)), "Partial saved state start button is enabled")
	_assert(Array(aircraft.get("visible_aircraft_definitions", [])).size() >= 1, "Partial saved state visible Flightdeck has a shipcard")
	_assert(not String(aircraft.get("selected_status_text", "")).contains("Flight deck empty"), "Partial saved state Flightdeck does not render empty blocker")
	_assert(bool(homebase_screen.call("can_request_mission_start", craft_id)), "Partial saved state can request mission start")

	scene.queue_free()
	await _wait_frames(2)


func _test_stale_payload_seed_uses_visible_fireteam_fallback() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(8)

	var homebase_screen := scene.get_node_or_null("HomebaseScreen") as Control
	_assert(homebase_screen != null, "Stale payload seed exposes HomebaseScreen")
	_assert(scene.has_method("get_singleplayer_start_bootstrap_snapshot"), "Stale payload seed exposes bootstrap snapshot")
	if homebase_screen == null or not scene.has_method("get_singleplayer_start_bootstrap_snapshot"):
		scene.queue_free()
		await _wait_frames(2)
		return

	var bootstrap: Dictionary = Dictionary(scene.call("get_singleplayer_start_bootstrap_snapshot"))
	var craft_id: String = String(bootstrap.get("craft_id", "")).strip_edges()
	_assert(not craft_id.is_empty(), "Stale payload seed has bootstrap craft")
	homebase_screen.set("_homebase_dropship_staged_fireteam_ids_by_craft", {})
	homebase_screen.set("_homebase_dropship_staged_fireteam_ids", PackedStringArray())
	homebase_screen.set("_homebase_dropship_payload_craft_id", "")
	homebase_screen.set("_homebase_direct_boarding_state_by_fireteam_id", {})
	homebase_screen.call("seed_homebase_direct_launch_payload", craft_id, PackedStringArray(["stale_removed_fireteam"]), true)
	await _wait_frames(4)

	var staging: Dictionary = Dictionary(homebase_screen.call("get_homebase_direct_staging_snapshot"))
	var readiness: Dictionary = Dictionary(homebase_screen.call("get_pre_mission_readiness_snapshot"))
	var startflow: Dictionary = Dictionary(homebase_screen.call("get_pre_mission_startflow_visual_snapshot"))
	_assert(bool(staging.get("payload_fallback_seeded", false)), "Stale payload seed records visible fireteam fallback")
	_assert(Array(staging.get("payload_fireteam_ids", [])).size() >= 1, "Stale payload seed restores a visible payload Fireteam")
	_assert(int(staging.get("payload_operator_count", 0)) >= 2, "Stale payload seed restores payload operators")
	_assert(int(staging.get("boarded_operator_count", 0)) >= int(staging.get("payload_operator_count", 0)), "Stale payload seed boards restored payload")
	_assert(String(readiness.get("overall_state", "")) == "ready", "Stale payload seed readiness becomes ready")
	_assert(String(startflow.get("start_button_text", "")) == "Start Mission", "Stale payload seed keeps Start Mission visible")
	_assert(not bool(startflow.get("start_button_disabled", true)), "Stale payload seed enables Start Mission")

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
