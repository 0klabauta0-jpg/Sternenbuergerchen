extends SceneTree

const FOB_TEST_SCENE: PackedScene = preload("res://scenes/meta/fob_test_screen.tscn")
const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Dropship Mission Bugfix Verifier ===")
	await _test_fob_refresh_preserves_boarded_units()
	await _test_shipcard_start_dispatches_boarded_craft_without_full_team_boarded()
	await _test_fob_header_start_is_hidden()
	await _test_meta_map_shows_mission_craft_card_during_transfer_and_waiting()
	await _test_mission_start_requires_boarded_team()
	await _test_homebase_timer_label_switches_from_idle_to_countdown()
	await _test_mission_timer_uses_explicit_start_timestamp()
	await _test_dropship_returns_to_fob_after_drop()
	await _test_meta_mission_uses_deferred_drop_state()
	await _test_combat_loop_waits_for_pending_insertions()
	await _test_drop_ship_starts_far_outside_the_map()
	await _test_mission_time_limit_resolves_defeat()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_fob_refresh_preserves_boarded_units() -> void:
	var screen: Control = FOB_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame

	var selected_unit_ids := PackedStringArray(["unit_alpha", "unit_bravo", "unit_delta"])
	var selected_fireteam_ids := PackedStringArray(["blue", "blue", "blue"])
	var fireteam_definitions := [
		{
			"id": "blue",
			"label": "BLUE",
			"lead_unit_id": "unit_alpha",
			"respawn_enabled": false,
			"loadout": "medium",
		}
	]
	screen.call("set_available_units", UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster"))
	screen.call(
		"set_transport_craft_state",
		[
			{
				"craft_id": "dropship_test",
				"display_name": "Dropship Test",
				"visible_in_fob": true,
				"is_boardable": true,
			}
		]
	)
	screen.call("configure_transfer", selected_unit_ids, selected_fireteam_ids, fireteam_definitions)
	screen.call("_queue_fireteam_for_dropship", "blue", "dropship_test")
	screen.set("_dropship_phase", "boarded")
	screen.set("_boarded_unit_ids", selected_unit_ids)
	screen.set("_boarded_fireteam_ids", PackedStringArray(["blue"]))

	var drop_state_before_refresh: Dictionary = Dictionary(screen.call("build_mission_drop_state"))
	screen.call("configure_transfer", selected_unit_ids, selected_fireteam_ids, fireteam_definitions)
	var drop_state_after_refresh: Dictionary = Dictionary(screen.call("build_mission_drop_state"))
	_assert(String(screen.get("_dropship_phase")) == "boarded", "FOB keeps boarded phase after a same-state refresh")
	_assert(Array(drop_state_before_refresh.get("embarked_unit_ids", [])).size() == 3, "FOB boards all queued members before the refresh check")
	_assert(Array(drop_state_after_refresh.get("embarked_unit_ids", [])).size() == 3, "FOB refresh no longer wipes boarded unit progress")
	screen.queue_free()
	await process_frame


func _test_meta_mission_uses_deferred_drop_state() -> void:
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	var mission_setup: Node = scene.get_node("MissionSetup")
	mission_setup.set("defer_friendly_runtime_activation", true)
	var tactical_controller: Node = scene.get_node("TacticalController")
	tactical_controller.call(
		"set_planning_state",
		{
			"has_lz_position": true,
			"lz_position": Vector2(320.0, 180.0),
			"selected_fireteam": "BLUE",
			"selected_fireteams": ["blue"],
			"embarked_unit_ids": ["unit_alpha", "unit_bravo", "unit_delta"],
			"deployed_unit_ids": [],
		}
	)
	root.add_child(scene)
	for _frame in range(8):
		await process_frame

	var unit_registry: Node = scene.get_node("UnitRegistry")
	var blue_drop_units: Array = Array(tactical_controller.call("_get_units_for_drop_operation"))
	var blue_units: Array = Array(tactical_controller.call("_get_fireteam_units", "blue", true))
	var gold_units: Array = Array(tactical_controller.call("_get_fireteam_units", "gold", true))
	var all_blue_hidden: bool = true
	for unit in blue_units:
		if unit is CanvasItem and (unit as CanvasItem).visible:
			all_blue_hidden = false
			break
	var all_gold_hidden: bool = true
	for unit in gold_units:
		if unit is CanvasItem and (unit as CanvasItem).visible:
			all_gold_hidden = false
			break

	tactical_controller.call("_on_call_dropship_pressed")

	_assert(unit_registry.has_method("has_unit") and not bool(unit_registry.call("has_unit", "unit_alpha")), "Deferred mission start keeps embarked units out of UnitRegistry")
	_assert(all_blue_hidden, "Embarked blue units stay hidden before the dropship is called")
	_assert(all_gold_hidden, "Non-dropped friendly units stay hidden on the mission map")
	_assert(blue_drop_units.size() == 3, "Drop operation prefers the already embarked fireteam members")
	_assert(String(tactical_controller.get("_drop_sequence_phase")) == "inbound", "Calling the dropship starts the live inbound sequence for embarked units")
	scene.queue_free()
	await process_frame


func _test_shipcard_start_dispatches_boarded_craft_without_full_team_boarded() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(4):
		await process_frame

	var fob_screen: Control = scene.get_node("FOBScreen")
	var selected_unit_ids := PackedStringArray(["unit_alpha", "unit_bravo", "unit_delta", "unit_echo"])
	var selected_fireteam_ids := PackedStringArray(["blue", "blue", "blue", "gold"])
	var fireteam_definitions := [
		{
			"id": "blue",
			"label": "BLUE",
			"lead_unit_id": "unit_alpha",
			"respawn_enabled": false,
			"loadout": "medium",
		},
		{
			"id": "gold",
			"label": "GOLD",
			"lead_unit_id": "unit_echo",
			"respawn_enabled": false,
			"loadout": "medium",
		}
	]
	scene.set(
		"_homebase_aircraft_definitions",
		[
			{
				"craft_id": "dropship_test",
				"display_name": "Dropship Test",
				"craft_type": "dropship",
				"texture_path": "res://Assets/kenney_space-kit/Side/craft_speederB.png",
			}
		]
	)
	scene.set("_assigned_aircraft_pilot_by_craft", {"dropship_test": "unit_hotel"})
	scene.set("_aircraft_location_by_craft", {"dropship_test": "fob"})
	scene.set("_selected_unit_ids", selected_unit_ids)
	scene.set("_selected_fireteam_ids", selected_fireteam_ids)
	scene.call("_refresh_fob_screen")
	fob_screen.call("configure_transfer", selected_unit_ids, selected_fireteam_ids, fireteam_definitions)
	fob_screen.set("_dropship_transport_craft_id", "dropship_test")
	fob_screen.set("_dropship_phase", "boarded")
	fob_screen.set("_boarded_unit_ids", PackedStringArray(["unit_alpha", "unit_bravo", "unit_delta"]))
	fob_screen.set("_boarded_fireteam_ids", PackedStringArray(["blue"]))

	var craft_state: Dictionary = Dictionary(fob_screen.call("_get_transport_craft_state", "dropship_test"))
	_assert(bool(fob_screen.call("_can_mark_transport_craft_launch_ready", craft_state)), "Shipcard start becomes available once this craft has boarded passengers")
	fob_screen.call("_on_transport_craft_mission_stage_requested", "dropship_test")
	var pending_transfers: Array = Array(scene.get("_pending_mission_craft_transfers"))
	_assert(pending_transfers.size() == 1, "Shipcard start dispatches the boarded craft even when other selected operators stay behind")
	scene.queue_free()
	await process_frame


func _test_fob_header_start_is_hidden() -> void:
	var screen: Control = FOB_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	var start_button := screen.get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/StartMissionButton") as Button
	_assert(start_button != null and not start_button.visible, "FOB header start button stays hidden because mission launch belongs to Homebase")
	screen.queue_free()
	await process_frame


func _test_meta_map_shows_mission_craft_card_during_transfer_and_waiting() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(4):
		await process_frame

	var fob_screen: Control = scene.get_node("FOBScreen")
	var map_screen: Control = scene.get_node("MapScreen")
	var selected_unit_ids := PackedStringArray(["unit_alpha", "unit_bravo", "unit_delta"])
	var selected_fireteam_ids := PackedStringArray(["blue", "blue", "blue"])
	var fireteam_definitions := [
		{
			"id": "blue",
			"label": "BLUE",
			"lead_unit_id": "unit_alpha",
			"respawn_enabled": false,
			"loadout": "medium",
		}
	]
	scene.set(
		"_homebase_aircraft_definitions",
		[
			{
				"craft_id": "dropship_test",
				"display_name": "Dropship Test",
				"craft_type": "dropship",
				"texture_path": "res://Assets/kenney_space-kit/Side/craft_speederB.png",
			}
		]
	)
	scene.set("_assigned_aircraft_pilot_by_craft", {"dropship_test": "unit_hotel"})
	scene.set("_aircraft_location_by_craft", {"dropship_test": "fob"})
	scene.set("_selected_unit_ids", selected_unit_ids)
	scene.set("_selected_fireteam_ids", selected_fireteam_ids)
	scene.call("_refresh_fob_screen")
	fob_screen.call("configure_transfer", selected_unit_ids, selected_fireteam_ids, fireteam_definitions)
	fob_screen.set("_dropship_transport_craft_id", "dropship_test")
	fob_screen.set("_dropship_phase", "boarded")
	fob_screen.set("_boarded_unit_ids", selected_unit_ids)
	fob_screen.set("_boarded_fireteam_ids", PackedStringArray(["blue"]))
	fob_screen.call("_on_transport_craft_mission_stage_requested", "dropship_test")
	scene.call("_refresh_map_screen")
	for _frame in range(2):
		await process_frame

	var mission_craft_card := map_screen.get_node("Panel/Margin/VBox/ContentRow/MapPanel/MapMargin/MapVBox/MissionCraftCard") as PanelContainer
	var status_label := mission_craft_card.get_node("CardMargin/CardRow/TextVBox/StatusLabel") as Label
	_assert(mission_craft_card != null and mission_craft_card.visible, "Map screen shows the mini shipcard while the dropship is en route")
	_assert(mission_craft_card.get_index() == 2, "Mini shipcard is inserted directly under the map preview panel")
	_assert(mission_craft_card.modulate.a < 1.0, "Mini shipcard is greyed out while the dropship is still in transit")
	_assert(status_label != null and status_label.text.contains("En route to mission map"), "Mini shipcard reports the live transfer status during mission transit")

	for _step in range(18):
		scene.call("_on_homebase_transport_timer_timeout")
	scene.call("_refresh_map_screen")
	for _frame in range(2):
		await process_frame

	_assert(mission_craft_card.visible and mission_craft_card.modulate.a < 1.0, "Mini shipcard stays visible and greyed out once the dropship is waiting on the mission map")
	_assert(status_label != null and status_label.text.contains("Holding on mission map"), "Mini shipcard switches to waiting status after the transfer completes")
	scene.queue_free()
	await process_frame


func _test_mission_start_requires_boarded_team() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(4):
		await process_frame

	var homebase_screen: Control = scene.get_node("HomebaseScreen")
	var fob_screen: Control = scene.get_node("FOBScreen")
	var start_button := scene.get_node("HomebaseScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/StartMissionButton") as Button
	var selected_unit_ids := PackedStringArray(["unit_alpha", "unit_bravo", "unit_delta"])
	var selected_fireteam_ids := PackedStringArray(["blue", "blue", "blue"])
	var fireteam_definitions := [
		{
			"id": "blue",
			"label": "BLUE",
			"lead_unit_id": "unit_alpha",
			"respawn_enabled": false,
			"loadout": "medium",
		}
	]
	scene.set(
		"_homebase_aircraft_definitions",
		[
			{
				"craft_id": "dropship_test",
				"display_name": "Dropship Test",
				"craft_type": "dropship",
				"texture_path": "res://Assets/kenney_space-kit/Side/craft_speederB.png",
			}
		]
	)
	scene.set("_assigned_aircraft_pilot_by_craft", {"dropship_test": "unit_hotel"})
	scene.set("_aircraft_location_by_craft", {"dropship_test": "fob"})
	scene.set("_selected_unit_ids", selected_unit_ids)
	scene.set("_selected_fireteam_ids", selected_fireteam_ids)
	scene.call("_refresh_fob_screen")
	fob_screen.call("configure_transfer", selected_unit_ids, selected_fireteam_ids, fireteam_definitions)
	fob_screen.call("_queue_fireteam_for_dropship", "blue", "dropship_test")
	fob_screen.call("_refresh_ui_state")
	scene.call("_refresh_homebase_screen")

	_assert(start_button != null and start_button.disabled, "Homebase start button stays locked until the dropship is launch-ready")
	homebase_screen.call("request_mission_start")
	for _frame in range(2):
		await process_frame
	_assert(scene.call("get_active_mission") == null, "Homebase mission start does not launch a mission before boarding is complete")

	fob_screen.set("_dropship_phase", "boarded")
	fob_screen.set("_boarded_unit_ids", selected_unit_ids)
	fob_screen.set("_boarded_fireteam_ids", PackedStringArray(["blue"]))
	fob_screen.call("_on_transport_craft_mission_stage_requested", "dropship_test")
	fob_screen.call("_refresh_ui_state")
	scene.call("_refresh_homebase_screen")
	_assert(start_button != null and start_button.disabled, "Homebase start waits until the boarded dropship has reached the mission map")
	for _step in range(18):
		scene.call("_on_homebase_transport_timer_timeout")
	scene.call("_refresh_homebase_screen")
	scene.call("_refresh_fob_screen")
	_assert(start_button != null and not start_button.disabled, "Homebase start button unlocks once the boarded dropship is waiting on the mission map")
	homebase_screen.call("request_mission_start")
	for _frame in range(4):
		await process_frame
	_assert(scene.call("get_active_mission") != null, "Homebase mission start launches once a boarded dropship is launch-ready")
	_assert(int(scene.get("_active_mission_started_at_msec")) > 0, "Homebase start seeds the mission countdown timestamp at launch")
	scene.queue_free()
	await process_frame


func _test_homebase_timer_label_switches_from_idle_to_countdown() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(4):
		await process_frame

	var homebase_screen: Control = scene.get_node("HomebaseScreen")
	var fob_screen: Control = scene.get_node("FOBScreen")
	var timer_label := scene.get_node("HomebaseScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow/MissionTimerLabel") as Label
	var selected_unit_ids := PackedStringArray(["unit_alpha", "unit_bravo", "unit_delta"])
	var selected_fireteam_ids := PackedStringArray(["blue", "blue", "blue"])
	var fireteam_definitions := [
		{
			"id": "blue",
			"label": "BLUE",
			"lead_unit_id": "unit_alpha",
			"respawn_enabled": false,
			"loadout": "medium",
		}
	]
	scene.set(
		"_homebase_aircraft_definitions",
		[
			{
				"craft_id": "dropship_test",
				"display_name": "Dropship Test",
				"craft_type": "dropship",
				"texture_path": "res://Assets/kenney_space-kit/Side/craft_speederB.png",
			}
		]
	)
	scene.set("_assigned_aircraft_pilot_by_craft", {"dropship_test": "unit_hotel"})
	scene.set("_aircraft_location_by_craft", {"dropship_test": "fob"})
	scene.set("_selected_unit_ids", selected_unit_ids)
	scene.set("_selected_fireteam_ids", selected_fireteam_ids)
	scene.call("_refresh_fob_screen")
	fob_screen.call("configure_transfer", selected_unit_ids, selected_fireteam_ids, fireteam_definitions)
	fob_screen.set("_dropship_transport_craft_id", "dropship_test")
	fob_screen.set("_dropship_phase", "boarded")
	fob_screen.set("_boarded_unit_ids", selected_unit_ids)
	fob_screen.set("_boarded_fireteam_ids", PackedStringArray(["blue"]))
	fob_screen.call("_on_transport_craft_mission_stage_requested", "dropship_test")
	for _step in range(18):
		scene.call("_on_homebase_transport_timer_timeout")
	scene.call("_refresh_homebase_screen")
	for _frame in range(2):
		await process_frame

	_assert(timer_label != null and timer_label.text == "--:--", "Homebase timer stays idle until the mission start button is pressed")
	homebase_screen.call("request_mission_start")
	for _frame in range(4):
		await process_frame
	_assert(timer_label != null and timer_label.text != "--:--", "Homebase timer switches to a live countdown after mission start")
	scene.queue_free()
	await process_frame


func _test_mission_timer_uses_explicit_start_timestamp() -> void:
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	var combat_driver: Node = scene.get_node("CombatLoopDriver")
	combat_driver.set("mission_time_limit_seconds", 1200.0)
	combat_driver.set("mission_timer_started_at_msec", Time.get_ticks_msec() - 65000)
	root.add_child(scene)
	for _frame in range(4):
		await process_frame
	var remaining_seconds: float = float(combat_driver.call("get_remaining_time_limit_seconds"))
	_assert(remaining_seconds <= 1136.0 and remaining_seconds >= 1133.0, "Mission timer counts down from the explicit Homebase start timestamp")
	scene.queue_free()
	await process_frame


func _test_dropship_returns_to_fob_after_drop() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(4):
		await process_frame

	var homebase_screen: Control = scene.get_node("HomebaseScreen")
	var fob_screen: Control = scene.get_node("FOBScreen")
	var selected_unit_ids := PackedStringArray(["unit_alpha", "unit_bravo", "unit_delta"])
	var selected_fireteam_ids := PackedStringArray(["blue", "blue", "blue"])
	var fireteam_definitions := [
		{
			"id": "blue",
			"label": "BLUE",
			"lead_unit_id": "unit_alpha",
			"respawn_enabled": false,
			"loadout": "medium",
		}
	]
	scene.set(
		"_homebase_aircraft_definitions",
		[
			{
				"craft_id": "dropship_test",
				"display_name": "Dropship Test",
				"craft_type": "dropship",
				"texture_path": "res://Assets/kenney_space-kit/Side/craft_speederB.png",
			}
		]
	)
	scene.set("_assigned_aircraft_pilot_by_craft", {"dropship_test": "unit_hotel"})
	scene.set("_aircraft_location_by_craft", {"dropship_test": "fob"})
	scene.set("_selected_unit_ids", selected_unit_ids)
	scene.set("_selected_fireteam_ids", selected_fireteam_ids)
	scene.call("_refresh_fob_screen")
	fob_screen.call("configure_transfer", selected_unit_ids, selected_fireteam_ids, fireteam_definitions)
	fob_screen.set("_dropship_transport_craft_id", "dropship_test")
	fob_screen.set("_dropship_phase", "boarded")
	fob_screen.set("_boarded_unit_ids", selected_unit_ids)
	fob_screen.set("_boarded_fireteam_ids", PackedStringArray(["blue"]))
	fob_screen.call("_on_transport_craft_mission_stage_requested", "dropship_test")
	for _step in range(18):
		scene.call("_on_homebase_transport_timer_timeout")
	homebase_screen.call("request_mission_start")
	for _frame in range(8):
		await process_frame

	var active_mission: Node = scene.call("get_active_mission")
	var tactical_controller: Node = active_mission.get_node("TacticalController")
	var mission_state: Dictionary = Dictionary(tactical_controller.call("get_planning_state"))
	mission_state["has_lz_position"] = true
	mission_state["lz_position"] = Vector2(320.0, 180.0)
	tactical_controller.call("set_planning_state", mission_state)
	tactical_controller.call("_on_call_dropship_pressed")
	for _step in range(600):
		tactical_controller.call("_update_drop_sequence", 0.2)
		if String(tactical_controller.get("_drop_sequence_phase")).is_empty():
			break
	for _frame in range(4):
		await process_frame

	var returning_craft_state: Dictionary = Dictionary(fob_screen.call("_get_transport_craft_state", "dropship_test"))
	_assert(bool(returning_craft_state.get("mission_transit_to_fob", false)), "FOB shows the dropship greyed-out and returning after the mission drop")
	for _step in range(18):
		scene.call("_on_homebase_transport_timer_timeout")
	var returned_craft_state: Dictionary = Dictionary(fob_screen.call("_get_transport_craft_state", "dropship_test"))
	_assert(bool(returned_craft_state.get("visible_in_fob", false)) and bool(returned_craft_state.get("is_boardable", false)), "Dropship becomes boardable in FOB again after the return flight")
	scene.queue_free()
	await process_frame


func _test_combat_loop_waits_for_pending_insertions() -> void:
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	var mission_setup: Node = scene.get_node("MissionSetup")
	mission_setup.set("defer_friendly_runtime_activation", true)
	var tactical_controller: Node = scene.get_node("TacticalController")
	var combat_driver: Node = scene.get_node("CombatLoopDriver")
	tactical_controller.call(
		"set_planning_state",
		{
			"has_lz_position": true,
			"lz_position": Vector2(320.0, 180.0),
			"selected_fireteam": "BLUE",
			"selected_fireteams": ["blue"],
			"embarked_unit_ids": ["unit_alpha", "unit_bravo", "unit_delta"],
			"deployed_unit_ids": [],
		}
	)
	root.add_child(scene)
	for _frame in range(24):
		await process_frame

	var mission_result: Dictionary = Dictionary(combat_driver.call("get_mission_result"))
	_assert(mission_result.is_empty(), "Combat loop does not resolve defeat while friendly insertions are still pending")
	scene.queue_free()
	await process_frame


func _test_drop_ship_starts_far_outside_the_map() -> void:
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	var mission_setup: Node = scene.get_node("MissionSetup")
	mission_setup.set("defer_friendly_runtime_activation", true)
	var tactical_controller: Node = scene.get_node("TacticalController")
	tactical_controller.call(
		"set_planning_state",
		{
			"has_lz_position": true,
			"lz_position": Vector2(448.0, 413.0),
			"selected_fireteam": "BLUE",
			"selected_fireteams": ["blue"],
			"drop_ship_staged": true,
			"embarked_unit_ids": ["unit_alpha", "unit_bravo", "unit_delta"],
			"deployed_unit_ids": [],
		}
	)
	root.add_child(scene)
	for _frame in range(8):
		await process_frame

	var start_position: Vector2 = Vector2(tactical_controller.call("_get_drop_staging_position"))
	var lz_position: Vector2 = Vector2(tactical_controller.get("_lz_position"))
	var map_bounds: Rect2 = Rect2(tactical_controller.call("_get_map_world_bounds"))
	var required_distance: float = maxf(maxf(map_bounds.size.x, map_bounds.size.y) * 2.0, 720.0)
	_assert(start_position.distance_to(lz_position) >= required_distance - 1.0, "Dropship staging starts at least two map-widths away from the LZ")
	scene.queue_free()
	await process_frame


func _test_mission_time_limit_resolves_defeat() -> void:
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	var mission_setup: Node = scene.get_node("MissionSetup")
	mission_setup.set("defer_friendly_runtime_activation", false)
	var combat_driver: Node = scene.get_node("CombatLoopDriver")
	combat_driver.set("mission_time_limit_seconds", 1.0)
	root.add_child(scene)
	for _frame in range(8):
		await process_frame
	combat_driver.set("_mission_started_at_msec", Time.get_ticks_msec() - 2500)
	combat_driver.call("_update_combat_resolution")
	var mission_result: Dictionary = Dictionary(combat_driver.call("get_mission_result"))
	_assert(String(mission_result.get("result", "")) == "defeat", "Mission time limit resolves the mission as a defeat once the timer expires")
	_assert(String(mission_result.get("win_condition_type", "")) == "time_limit", "Mission result records the time limit as the resolution condition")
	scene.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
