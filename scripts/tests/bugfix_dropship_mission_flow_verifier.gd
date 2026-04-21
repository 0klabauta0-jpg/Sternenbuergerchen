extends SceneTree

const FOB_TEST_SCENE: PackedScene = preload("res://scenes/meta/fob_test_screen.tscn")
const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")
const UI_BLOCK_LABELS_SCRIPT: GDScript = preload("res://scripts/meta/ui_block_labels.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Dropship Mission Bugfix Verifier ===")
	await _test_fob_refresh_preserves_boarded_units()
	await _test_shipcard_start_dispatches_boarded_craft_without_full_team_boarded()
	await _test_fob_header_start_is_hidden()
	await _test_homebase_start_button_lives_in_header()
	await _test_preview_mission_only_exists_in_map_view()
	await _test_meta_map_shows_mission_craft_card_during_transfer_and_waiting()
	await _test_preview_drop_button_stays_drop_without_live_sequence()
	await _test_preview_drop_request_bootstraps_live_mission_inbound()
	await _test_fob_assignments_and_boarding_survive_send_and_nav_refresh()
	await _test_mission_slot_labels_stay_aligned_with_pilots()
	await _test_mission_start_requires_boarded_team()
	await _test_homebase_timer_label_switches_from_idle_to_countdown()
	await _test_preview_mission_timer_stays_idle_before_homebase_start()
	await _test_mission_timer_uses_explicit_start_timestamp()
	await _test_homebase_inbound_craft_is_visible_in_fob()
	await _test_block_labels_use_unique_prefixed_ids()
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


func _test_homebase_start_button_lives_in_header() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(2):
		await process_frame
	var start_button := scene.get_node("HomebaseScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/StartMissionButton") as Button
	var old_start_button := scene.get_node_or_null("HomebaseScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/StartMissionButton") as Button
	_assert(start_button != null, "Homebase start button sits in the header row")
	_assert(old_start_button == null, "Homebase mission info row no longer owns a duplicate start button")
	scene.queue_free()
	await process_frame


func _test_preview_mission_only_exists_in_map_view() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(4):
		await process_frame

	var mission_host: Node = scene.get_node("MissionHost")
	_assert(mission_host.get_child_count() == 0, "Meta layer keeps no preview mission alive while Homebase is active")

	scene.call("_show_map")
	for _frame in range(2):
		await process_frame
	_assert(mission_host.get_child_count() == 1, "Map view instantiates exactly one preview mission")

	scene.call("_show_fob")
	for _frame in range(2):
		await process_frame
	_assert(mission_host.get_child_count() == 0, "Leaving the map releases the preview mission instead of carrying it through FOB")

	scene.call("_show_homebase")
	for _frame in range(2):
		await process_frame
	_assert(mission_host.get_child_count() == 0, "Homebase does not resurrect a hidden preview mission after the cleanup")
	scene.queue_free()
	await process_frame


func _test_meta_map_shows_mission_craft_card_during_transfer_and_waiting() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(4):
		await process_frame

	var fob_screen: Control = scene.get_node("FOBScreen")
	var homebase_screen: Control = scene.get_node("HomebaseScreen")
	var map_screen: Control = scene.get_node_or_null("MapScreen") as Control
	var mission_host: Node = scene.get_node("MissionHost")
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
	scene.call("_refresh_homebase_screen")
	scene.call("_refresh_fob_screen")
	scene.call("_show_map")
	for _frame in range(2):
		await process_frame

	var preview_mission := mission_host.get_child(0) if mission_host.get_child_count() > 0 else null
	var tactical_controller: Node = preview_mission.get_node("TacticalController") if preview_mission != null else null
	var preview_planning_state: Dictionary = Dictionary(tactical_controller.call("get_planning_state")) if tactical_controller != null else {}
	preview_planning_state["has_lz_position"] = true
	preview_planning_state["lz_position"] = Vector2(320.0, 180.0)
	if tactical_controller != null:
		tactical_controller.call("set_planning_state", preview_planning_state)
	for _frame in range(6):
		await process_frame
	var mission_identity_panel := preview_mission.get_node("TacticalUI/MissionIdentityPanel") as PanelContainer if preview_mission != null else null
	var mission_craft_card := preview_mission.get_node("TacticalUI/MissionDropshipPanel") as PanelContainer if preview_mission != null else null
	var title_label := mission_craft_card.get_node("MarginContainer/VBox/HeaderRow/TitleLabel") as Label if mission_craft_card != null else null
	var pilot_card := mission_craft_card.get_node("MarginContainer/VBox/ContentRow/InfoVBox/PilotCardHost/PilotCard") if mission_craft_card != null and mission_craft_card.has_node("MarginContainer/VBox/ContentRow/InfoVBox/PilotCardHost/PilotCard") else null
	var pilot_secondary_label := pilot_card.get_node("Margin/HBox/TextVBox/DataBLabel") as Label if pilot_card != null else null
	var info_lines_host := mission_craft_card.get_node("MarginContainer/VBox/ContentRow/InfoVBox/InfoLinesHost") as VBoxContainer if mission_craft_card != null else null
	var status_label := info_lines_host.get_child(1) as Label if info_lines_host != null and info_lines_host.get_child_count() > 1 else null
	var ship_texture := mission_craft_card.get_node("MarginContainer/VBox/ContentRow/ShipTexture") as TextureRect if mission_craft_card != null else null
	var dropship_marker := preview_mission.get_node("DropshipPlanMarker") as Node2D if preview_mission != null else null
	var expected_drop_state: Dictionary = Dictionary(fob_screen.call("build_mission_drop_state"))
	var shared_fob_state: Dictionary = Dictionary(fob_screen.call("_get_transport_craft_state", String(expected_drop_state.get("mission_drop_craft_id", ""))))
	var shared_fob_card: PanelContainer = fob_screen.call("_build_transport_craft_card", shared_fob_state)
	var shared_card_paths := [
		"MarginContainer/VBox/HeaderRow/TitleLabel",
		"MarginContainer/VBox/HeaderRow/PrimaryActionButton",
		"MarginContainer/VBox/HeaderRow/SecondaryActionButton",
		"MarginContainer/VBox/ContentRow/ShipTexture",
		"MarginContainer/VBox/ContentRow/InfoVBox/PilotCardHost",
		"MarginContainer/VBox/ContentRow/InfoVBox/PilotLabelFallback",
		"MarginContainer/VBox/ContentRow/InfoVBox/InfoLinesHost",
		"MarginContainer/VBox/ProgressBar",
		"MarginContainer/VBox/ExtraContentHost",
	]
	_assert(map_screen == null, "Mission nav no longer keeps the old legacy MapScreen in the meta scene")
	_assert(preview_mission != null, "Mission nav keeps the preview mission host active as the visible map surface")
	_assert(mission_craft_card != null and mission_craft_card.visible, "Preview mission shows the mini shipcard while the dropship is en route")
	_assert(mission_craft_card != null and mission_craft_card.modulate.a < 1.0, "Mini shipcard stays greyed out during mission transit")
	_assert(mission_craft_card != null and mission_craft_card.clip_contents, "Mission mini shipcard clips its content so the panel cannot spill over other HUD windows")
	_assert(mission_craft_card != null and is_equal_approx(mission_craft_card.size.x, 312.0) and is_equal_approx(mission_craft_card.size.y, 104.0), "Mission mini shipcard keeps its smaller fixed tactical HUD size")
	_assert(mission_craft_card != null and mission_craft_card.top_level, "Mission mini shipcard stays on an absolute HUD layer instead of stretching with the tactical layout")
	_assert(title_label != null and title_label.text == String(expected_drop_state.get("mission_drop_title_text", "")), "Mission mini shipcard reuses the FOB ship title text")
	_assert(title_label != null and title_label.text.begins_with(UI_BLOCK_LABELS_SCRIPT.SHARED_TRANSPORT_CARD_PREFIX), "Shared shipcard numbering reuses the same # id in FOB and mission views")
	for node_path_variant in shared_card_paths:
		var node_path: String = String(node_path_variant)
		_assert(shared_fob_card != null and shared_fob_card.has_node(node_path), "Shared FOB card keeps the shared transport-card node %s" % node_path)
		_assert(mission_craft_card != null and mission_craft_card.has_node(node_path), "Mission mini shipcard reuses the shared transport-card node %s" % node_path)
	_assert(pilot_card != null, "Mission mini shipcard reuses the shared compact pilot card layout")
	_assert(pilot_card != null and pilot_card.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Mission mini shipcard is display-only and does not block Mission Control clicks")
	_assert(pilot_secondary_label != null and pilot_secondary_label.text == String(expected_drop_state.get("mission_drop_pilot_text", "")), "Mission mini shipcard reuses the FOB pilot text")
	_assert(status_label != null and status_label.text.contains("ETA mission map"), "Mini shipcard reports the live transfer status during mission transit")
	_assert(ship_texture != null and ship_texture.texture != null and ship_texture.texture.resource_path == "res://Assets/kenney_space-kit/Side/craft_speederB.png", "Mission mini shipcard reuses the same dropship texture as the FOB shipcard")
	_assert(not (mission_craft_card.get_node("MarginContainer/VBox/HeaderRow/PrimaryActionButton") as Button).visible, "Mission mini shipcard hides the shared primary action button")
	_assert(not (mission_craft_card.get_node("MarginContainer/VBox/HeaderRow/SecondaryActionButton") as Button).visible, "Mission mini shipcard hides the shared secondary action button")
	_assert(dropship_marker != null and dropship_marker.visible, "Preview mission renders the dropship marker once the craft is actually on the mission-map route")
	_assert(mission_identity_panel != null and mission_craft_card.offset_top >= mission_identity_panel.offset_bottom, "Mini shipcard sits below the LIVE TACTICAL GRID header panel")
	_assert(is_equal_approx(mission_craft_card.anchor_left, 0.0) and is_equal_approx(mission_craft_card.anchor_right, 0.0), "Mini shipcard uses absolute HUD anchors and no longer stretches with the right edge layout")
	_assert(Array(fob_screen.call("_get_visible_transport_craft_states")).is_empty(), "FOB stops rendering the sent dropship while it is on the mission-map transfer")
	_assert(Array(homebase_screen.call("_get_visible_homebase_aircraft_definitions")).is_empty(), "Homebase does not resurrect the sent dropship while it transfers to the mission map")
	if shared_fob_card != null:
		shared_fob_card.queue_free()

	for _step in range(18):
		scene.call("_on_homebase_transport_timer_timeout")
	scene.call("_show_map")
	for _frame in range(2):
		await process_frame

	preview_mission = mission_host.get_child(0) if mission_host.get_child_count() > 0 else null
	mission_craft_card = preview_mission.get_node("TacticalUI/MissionDropshipPanel") as PanelContainer if preview_mission != null else null
	title_label = mission_craft_card.get_node("MarginContainer/VBox/HeaderRow/TitleLabel") as Label if mission_craft_card != null else null
	info_lines_host = mission_craft_card.get_node("MarginContainer/VBox/ContentRow/InfoVBox/InfoLinesHost") as VBoxContainer if mission_craft_card != null else null
	status_label = info_lines_host.get_child(1) as Label if info_lines_host != null and info_lines_host.get_child_count() > 1 else null
	dropship_marker = preview_mission.get_node("DropshipPlanMarker") as Node2D if preview_mission != null else null
	expected_drop_state = Dictionary(fob_screen.call("build_mission_drop_state"))
	_assert(mission_craft_card != null and mission_craft_card.visible and mission_craft_card.modulate.a < 1.0, "Mini shipcard stays visible once the dropship is waiting on the mission map")
	_assert(title_label != null and title_label.text == String(expected_drop_state.get("mission_drop_title_text", "")), "Mission mini shipcard keeps the FOB title text once the craft is waiting on the map")
	_assert(status_label != null and status_label.text.contains("Holding on mission map"), "Mini shipcard switches to waiting status after the transfer completes")
	_assert(dropship_marker != null and dropship_marker.visible, "Preview mission keeps the dropship marker visible while the craft is waiting on the mission map")
	_assert(Array(fob_screen.call("_get_visible_transport_craft_states")).is_empty(), "FOB keeps the sent dropship hidden while it waits on the mission map")
	_assert(Array(homebase_screen.call("_get_visible_homebase_aircraft_definitions")).is_empty(), "Homebase keeps mission-side dropships out of the flight deck while they wait on the mission map")

	scene.call("_show_fob")
	for _frame in range(2):
		await process_frame
	preview_mission = mission_host.get_child(0) if mission_host.get_child_count() > 0 else null
	mission_craft_card = preview_mission.get_node("TacticalUI/MissionDropshipPanel") as PanelContainer if preview_mission != null else null
	_assert(mission_craft_card != null and not mission_craft_card.visible, "Preview mission shipcard stays hidden while the FOB screen is active")

	scene.call("_show_homebase")
	for _frame in range(2):
		await process_frame
	preview_mission = mission_host.get_child(0) if mission_host.get_child_count() > 0 else null
	mission_craft_card = preview_mission.get_node("TacticalUI/MissionDropshipPanel") as PanelContainer if preview_mission != null else null
	_assert(mission_craft_card != null and not mission_craft_card.visible, "Preview mission shipcard stays hidden while the Homebase screen is active")
	scene.queue_free()
	await process_frame


func _test_preview_drop_button_stays_drop_without_live_sequence() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(4):
		await process_frame

	var fob_screen: Control = scene.get_node("FOBScreen")
	var mission_host: Node = scene.get_node("MissionHost")
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
	scene.call("_show_map")
	for _frame in range(2):
		await process_frame

	var preview_mission := mission_host.get_child(0) if mission_host.get_child_count() > 0 else null
	var tactical_controller: Node = preview_mission.get_node("TacticalController") if preview_mission != null else null
	var call_button := preview_mission.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/CallDropshipButton") as Button if preview_mission != null else null
	var dropship_marker := preview_mission.get_node("DropshipPlanMarker") as Node2D if preview_mission != null else null
	var planning_state: Dictionary = Dictionary(tactical_controller.call("get_planning_state")) if tactical_controller != null else {}
	planning_state["has_lz_position"] = true
	planning_state["lz_position"] = Vector2(320.0, 180.0)
	tactical_controller.call("set_planning_state", planning_state)
	tactical_controller.call("_on_call_dropship_pressed")
	var start_position: Vector2 = Vector2(tactical_controller.get("_drop_sequence_position")) if tactical_controller != null else Vector2.ZERO
	tactical_controller.call("_update_drop_sequence", 0.5)
	await process_frame

	_assert(tactical_controller != null and bool(tactical_controller.get("preview_mode")), "Mission nav still uses the preview mission controller before the actual mission start")
	_assert(bool(tactical_controller.get("_drop_sequence_visual_only")), "Preview drop uses a visual-only dropship sequence instead of live runtime insertion")
	_assert(String(tactical_controller.get("_drop_sequence_phase")) == "inbound", "Preview drop starts a visible inbound dropship pass on the mission map")
	_assert(start_position.distance_to(Vector2(tactical_controller.get("_drop_sequence_position"))) > 0.1, "Preview dropship visibly advances toward the LZ after pressing Drop")
	_assert(call_button != null and call_button.text == "Inbound", "Preview drop button reflects the visible inbound drop sequence")
	_assert(dropship_marker != null and dropship_marker.visible, "Preview mission shows the dropship marker while the visual drop run is active")
	_assert(Array(Dictionary(tactical_controller.call("get_planning_state")).get("deployed_unit_ids", [])).is_empty(), "Preview drop stays visual-only and does not deploy friendlies before mission start")
	scene.queue_free()
	await process_frame


func _test_preview_drop_request_bootstraps_live_mission_inbound() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(4):
		await process_frame

	var homebase_screen: Control = scene.get_node("HomebaseScreen")
	var fob_screen: Control = scene.get_node("FOBScreen")
	var mission_host: Node = scene.get_node("MissionHost")
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

	scene.call("_show_map")
	for _frame in range(2):
		await process_frame
	var preview_mission := mission_host.get_child(0) if mission_host.get_child_count() > 0 else null
	var preview_tactical_controller: Node = preview_mission.get_node("TacticalController") if preview_mission != null else null
	var preview_state: Dictionary = Dictionary(preview_tactical_controller.call("get_planning_state")) if preview_tactical_controller != null else {}
	preview_state["has_lz_position"] = true
	preview_state["lz_position"] = Vector2(320.0, 180.0)
	preview_tactical_controller.call("set_planning_state", preview_state)
	preview_tactical_controller.call("_on_call_dropship_pressed")
	for _frame in range(2):
		await process_frame

	var meta_planning_state: Dictionary = Dictionary(scene.get("_mission_planning_state"))
	_assert(bool(meta_planning_state.get("drop_ship_requested", false)), "Preview drop request is stored in the shared mission planning state before mission start")

	scene.call("_show_homebase")
	for _frame in range(2):
		await process_frame
	homebase_screen.call("request_mission_start")
	for _frame in range(8):
		await process_frame

	var active_mission: Node = scene.call("get_active_mission")
	var active_tactical_controller: Node = active_mission.get_node("TacticalController") if active_mission != null else null
	_assert(active_mission != null, "Homebase start still launches the active mission after a preview drop request")
	_assert(active_tactical_controller != null and not bool(active_tactical_controller.get("preview_mode")), "The live mission controller replaces the preview controller after mission start")
	_assert(String(active_tactical_controller.get("_drop_sequence_phase")) == "inbound", "A preview drop request bootstraps the live mission directly into inbound dropship movement")
	var initial_drop_position: Vector2 = active_tactical_controller.get("_drop_sequence_position")
	for _frame in range(6):
		await process_frame
	var updated_drop_position: Vector2 = active_tactical_controller.get("_drop_sequence_position")
	_assert(initial_drop_position.distance_to(updated_drop_position) > 0.1, "Bootstrapped live dropship sequence advances visibly after mission start")
	scene.queue_free()
	await process_frame


func _test_fob_assignments_and_boarding_survive_send_and_nav_refresh() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(4):
		await process_frame

	var fob_screen: Control = scene.get_node("FOBScreen")
	var selected_unit_ids := PackedStringArray(["unit_alpha", "unit_bravo", "unit_delta"])
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
	scene.set("_selected_fireteam_ids", PackedStringArray(["", "", ""]))
	scene.call("_refresh_fob_screen")

	fob_screen.call("_set_selected_fireteam_for_unit", "unit_alpha", "ft1")
	fob_screen.call("_set_selected_fireteam_for_unit", "unit_bravo", "ft1")
	fob_screen.call("_set_selected_fireteam_for_unit", "unit_delta", "ft1")
	fob_screen.call("_queue_fireteam_for_dropship", "ft1", "dropship_test")
	fob_screen.set("_dropship_transport_craft_id", "dropship_test")
	fob_screen.set("_dropship_phase", "boarded")
	fob_screen.set("_boarded_unit_ids", selected_unit_ids)
	fob_screen.set("_boarded_fireteam_ids", PackedStringArray(["ft1"]))

	fob_screen.call("_on_transport_craft_mission_stage_requested", "dropship_test")
	for _frame in range(2):
		await process_frame

	_assert(PackedStringArray(fob_screen.call("get_selected_fireteam_ids")) == PackedStringArray(["ft1", "ft1", "ft1"]), "FOB send keeps the locally assigned fireteam membership instead of resetting operators to available")
	_assert(PackedStringArray(fob_screen.get("_boarded_unit_ids")) == selected_unit_ids, "FOB send no longer wipes boarded operators on the immediate refresh")

	scene.call("_show_homebase")
	for _frame in range(2):
		await process_frame
	scene.call("_show_fob")
	for _frame in range(2):
		await process_frame
	_assert(PackedStringArray(fob_screen.call("get_selected_fireteam_ids")) == PackedStringArray(["ft1", "ft1", "ft1"]), "Returning from Homebase keeps FOB fireteam assignments intact")

	scene.call("_show_map")
	for _frame in range(2):
		await process_frame
	scene.call("_show_fob")
	for _frame in range(2):
		await process_frame
	_assert(PackedStringArray(fob_screen.call("get_selected_fireteam_ids")) == PackedStringArray(["ft1", "ft1", "ft1"]), "Returning from Mission Map keeps FOB fireteam assignments intact")
	scene.queue_free()
	await process_frame


func _test_mission_slot_labels_stay_aligned_with_pilots() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(4):
		await process_frame

	var homebase_screen: Control = scene.get_node("HomebaseScreen")
	var fob_screen: Control = scene.get_node("FOBScreen")
	var homebase_label := scene.get_node("HomebaseScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/MissionTeamLimitLabel") as Label
	var fob_label := scene.get_node("FOBScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/TeamStatusLabel") as Label
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
	scene.call("_refresh_homebase_screen")

	_assert(homebase_label != null and homebase_label.text == "Mission slots: 4 / 8", "Homebase mission slots count operators plus the assigned pilot")
	_assert(fob_label != null and fob_label.text == homebase_label.text, "FOB mission slots match Homebase before the craft is sent")

	fob_screen.call("configure_transfer", selected_unit_ids, selected_fireteam_ids, fireteam_definitions)
	fob_screen.set("_dropship_transport_craft_id", "dropship_test")
	fob_screen.set("_dropship_phase", "boarded")
	fob_screen.set("_boarded_unit_ids", selected_unit_ids)
	fob_screen.set("_boarded_fireteam_ids", PackedStringArray(["blue"]))
	fob_screen.call("_on_transport_craft_mission_stage_requested", "dropship_test")
	for _step in range(18):
		scene.call("_on_homebase_transport_timer_timeout")
	scene.call("_refresh_fob_screen")
	scene.call("_refresh_homebase_screen")

	_assert(homebase_label != null and homebase_label.text == "Mission slots: 4 / 8", "Homebase keeps counting the pilot after the dropship reaches the mission map")
	_assert(fob_label != null and fob_label.text == homebase_label.text, "FOB mission slots stay aligned with Homebase even while the dropship is off-map")
	_assert(int(Dictionary(fob_screen.call("build_meta_overview")).get("slot_usage_count", 0)) == 4, "Meta overview exports the same mission slot usage including the pilot")
	scene.queue_free()
	await process_frame


func _test_mission_start_requires_boarded_team() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(4):
		await process_frame

	var homebase_screen: Control = scene.get_node("HomebaseScreen")
	var fob_screen: Control = scene.get_node("FOBScreen")
	var start_button := scene.get_node("HomebaseScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/StartMissionButton") as Button
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


func _test_preview_mission_timer_stays_idle_before_homebase_start() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(4):
		await process_frame

	scene.call("_show_map")
	for _frame in range(4):
		await process_frame

	var preview_mission: Node = scene.get_node("MissionHost").get_child(0) if scene.get_node("MissionHost").get_child_count() > 0 else null
	var timer_label := preview_mission.get_node("TacticalUI/TopNavPanel/NavMargin/NavRow/MissionTimerLabel") as Label if preview_mission != null else null
	var tactical_controller: Node = preview_mission.get_node("TacticalController") if preview_mission != null else null
	var strategic_status_label := preview_mission.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicStatusLabel") as Label if preview_mission != null else null
	_assert(timer_label != null and timer_label.text == "--:--", "Preview mission timer stays idle until Homebase starts the live mission")
	_assert(strategic_status_label != null and strategic_status_label.text.contains("Time --:--"), "Preview mission HUD keeps the time limit idle before Homebase start")
	_assert(tactical_controller != null and tactical_controller.get("_drop_sequence_phase") == "", "Preview mission does not auto-start the drop sequence just by opening the mission map")
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


func _test_homebase_inbound_craft_is_visible_in_fob() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(4):
		await process_frame

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
	scene.set("_aircraft_location_by_craft", {"dropship_test": "transit"})
	scene.set(
		"_pending_homebase_pilot_transfers",
		[
			{
				"craft_id": "dropship_test",
				"pilot_unit_id": "unit_hotel",
				"cargo_id": "",
				"duration_seconds": 10.0,
				"elapsed_seconds": 3.0,
			}
		]
	)
	scene.call("_refresh_fob_screen")
	for _frame in range(2):
		await process_frame

	var fob_screen: Control = scene.get_node("FOBScreen")
	var visible_states: Array = Array(fob_screen.call("_get_visible_transport_craft_states"))
	var inbound_state: Dictionary = visible_states[0] if not visible_states.is_empty() else {}
	_assert(visible_states.size() == 1, "FOB renders the inbound homebase dropship instead of letting it pop in at arrival")
	_assert(bool(inbound_state.get("is_in_transit", false)), "Inbound homebase dropship stays greyed-out in FOB while it is still in transit")
	_assert(not bool(inbound_state.get("is_boardable", false)), "Inbound homebase dropship is not boardable before it actually reaches the FOB")
	_assert(int(inbound_state.get("transfer_eta_seconds", 0)) > 0, "Inbound homebase dropship exposes a live ETA in the FOB transit card")
	scene.queue_free()
	await process_frame


func _test_block_labels_use_unique_prefixed_ids() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(4):
		await process_frame

	scene.call("_show_map")
	for _frame in range(4):
		await process_frame

	var preview_mission: Node = scene.get_node("MissionHost").get_child(0) if scene.get_node("MissionHost").get_child_count() > 0 else null
	var homebase_available_label := scene.get_node("HomebaseScreen/Panel/Margin/VBox/ContentRow/RosterPanel/RosterMargin/RosterVBox/RosterHeaderLabel") as Label
	var fob_available_label := scene.get_node("FOBScreen/Panel/Margin/VBox/ContentRow/AvailablePanel/AvailableMargin/AvailableVBox/AvailableHeaderLabel") as Label
	var mission_command_label := preview_mission.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandHeaderLabel") as Label if preview_mission != null else null
	var mission_control_label := preview_mission.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicHeaderLabel") as Label if preview_mission != null else null

	_assert(homebase_available_label != null and homebase_available_label.text == UI_BLOCK_LABELS_SCRIPT.HOMEBASE_AVAILABLE_OPERATORS, "Homebase block labels use the shared unique # ids")
	_assert(fob_available_label != null and fob_available_label.text == UI_BLOCK_LABELS_SCRIPT.FOB_AVAILABLE_OPERATORS, "FOB block labels use the shared unique # ids")
	_assert(mission_command_label != null and mission_command_label.text == UI_BLOCK_LABELS_SCRIPT.MISSION_COMMAND_MATRIX, "Mission command panel uses its unique shared # id")
	_assert(mission_control_label != null and mission_control_label.text == UI_BLOCK_LABELS_SCRIPT.MISSION_CONTROL, "Mission control panel uses its unique shared # id")
	_assert(homebase_available_label != null and fob_available_label != null and homebase_available_label.text != fob_available_label.text, "Different windows no longer repeat the same block number")

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
	_assert(String(tactical_controller.get("_drop_sequence_phase")) == "inbound", "Live mission drop button immediately starts the inbound dropship sequence")
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
