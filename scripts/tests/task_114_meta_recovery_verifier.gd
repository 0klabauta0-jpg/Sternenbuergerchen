extends SceneTree

const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_114 Meta-Recovery Verifier ===")
	await _test_mission_nav_starts_live_mission_with_fireteam_cards()
	await _test_mission_nav_without_fob_team_keeps_no_legacy_preview_fireteams()
	await _test_live_mission_nav_disables_preview_transfer_route_overlay()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	print("ALL TESTS PASSED")
	quit(1 if _failed > 0 else 0)
func _test_mission_nav_starts_live_mission_with_fireteam_cards() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(4)

	var fob_screen: Control = scene.get_node("FOBScreen")
	var mission_host: Node = scene.get_node("MissionHost")
	var selected_unit_ids := PackedStringArray(["unit_alpha", "unit_bravo", "unit_delta"])
	var selected_fireteam_ids := PackedStringArray(["ft1", "ft1", "ft1"])
	var fireteam_definitions := [
		{
			"id": "ft1",
			"label": "FT1",
			"lead_unit_id": "unit_alpha",
			"respawn_enabled": false,
			"loadout": "medium",
			"member_loadouts": {
				"unit_alpha": {"armor": "heavy", "weapon_1": "rail_gun", "weapon_2": "smg"},
				"unit_bravo": {"armor": "light", "weapon_1": "smg", "weapon_2": "smg"},
				"unit_delta": {"armor": "medium", "weapon_1": "rifle", "weapon_2": "rail_gun"},
			},
		}
	]

	scene.set("_selected_unit_ids", selected_unit_ids)
	scene.set("_selected_fireteam_ids", selected_fireteam_ids)
	scene.call("_refresh_fob_screen")
	fob_screen.call("configure_transfer", selected_unit_ids, selected_fireteam_ids, fireteam_definitions)
	scene.call("_refresh_map_screen")
	scene.call("_show_map")
	await _wait_frames(6)

	var active_mission: Node = scene.call("get_active_mission")
	var mission_host_child: Node = mission_host.get_child(0) if mission_host.get_child_count() > 0 else null
	var mission_setup := active_mission.get_node("MissionSetup") as Node if active_mission != null else null
	var tactical_controller := active_mission.get_node("TacticalController") as Node if active_mission != null else null
	var member_loadouts: Dictionary = mission_setup.get("member_loadouts") if mission_setup != null and typeof(mission_setup.get("member_loadouts")) == TYPE_DICTIONARY else {}
	var cards_host := active_mission.get_node("TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox") as Control if active_mission != null else null
	var fireteam_panel := active_mission.get_node("TacticalUI/FireteamMiniPanel") as Control if active_mission != null else null
	var available_fireteams: PackedStringArray = PackedStringArray(tactical_controller.call("_get_available_fireteam_ids")) if tactical_controller != null else PackedStringArray()
	var displayable_fireteams: PackedStringArray = PackedStringArray(tactical_controller.call("_get_displayable_fireteam_ids")) if tactical_controller != null else PackedStringArray()

	_assert(active_mission != null and mission_host_child == active_mission, "Mission nav now starts a live mission instance instead of a preview")
	_assert(tactical_controller != null and not bool(tactical_controller.get("preview_mode")), "Mission nav live instance is not in preview mode")
	_assert(member_loadouts.has("unit_alpha"), "Live mission receives the per-member loadout dictionary from the FOB bridge")
	_assert(available_fireteams == PackedStringArray(["ft1"]), "Live mission knows the configured FOB fireteam")
	_assert(displayable_fireteams == PackedStringArray(["ft1"]), "Live mission exposes the configured fireteam immediately for movement testing")
	_assert(cards_host != null and cards_host.get_child_count() == 1, "Live mission shows the configured fireteam mini-card immediately")
	_assert(fireteam_panel != null and fireteam_panel.visible, "Live mission keeps the fireteam mini-card panel visible for command testing")

	scene.queue_free()
	await process_frame


func _test_mission_nav_without_fob_team_keeps_no_legacy_preview_fireteams() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(4)

	scene.set("_selected_unit_ids", PackedStringArray())
	scene.set("_selected_fireteam_ids", PackedStringArray())
	scene.call("_refresh_fob_screen")
	scene.call("_refresh_map_screen")
	scene.call("_show_map")
	await _wait_frames(6)

	var mission_host: Node = scene.get_node("MissionHost")
	var active_mission: Node = scene.call("get_active_mission")
	var tactical_controller := active_mission.get_node("TacticalController") as Node if active_mission != null else null
	var cards_host := active_mission.get_node("TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox") as Control if active_mission != null else null
	var fireteam_panel := active_mission.get_node("TacticalUI/FireteamMiniPanel") as Control if active_mission != null else null
	var available_fireteams: PackedStringArray = PackedStringArray(tactical_controller.call("_get_available_fireteam_ids")) if tactical_controller != null else PackedStringArray()

	_assert(scene.get("_preview_mission") == null, "Mission nav does not keep a preview mission around without a staged FOB team")
	_assert(active_mission == null or available_fireteams.is_empty(), "Live mission no longer invents legacy BLUE/GOLD fireteams when no FOB team was assembled")
	_assert(active_mission == null or (cards_host != null and cards_host.get_child_count() == 0), "Live mission shows no fireteam mini-cards when nothing was staged in the FOB")
	_assert(active_mission == null or (fireteam_panel != null and not fireteam_panel.visible), "Live mission keeps the mini fireteam panel hidden when there is no staged team")

	scene.queue_free()
	await process_frame


func _test_live_mission_nav_disables_preview_transfer_route_overlay() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(4)

	var fob_screen: Control = scene.get_node("FOBScreen")
	var mission_host: Node = scene.get_node("MissionHost")
	var selected_unit_ids := PackedStringArray(["unit_alpha", "unit_bravo"])
	var selected_fireteam_ids := PackedStringArray(["ft1", "ft1"])
	var fireteam_definitions := [
		{
			"id": "ft1",
			"label": "FT1",
			"lead_unit_id": "unit_alpha",
			"respawn_enabled": false,
			"loadout": "medium",
			"member_loadouts": {
				"unit_alpha": {"armor": "medium", "weapon_1": "rifle", "weapon_2": "smg"},
				"unit_bravo": {"armor": "light", "weapon_1": "smg", "weapon_2": "smg"},
			},
		}
	]

	scene.set("_selected_unit_ids", selected_unit_ids)
	scene.set("_selected_fireteam_ids", selected_fireteam_ids)
	scene.set(
		"_homebase_aircraft_definitions",
		[
			{
				"craft_id": "dropship_transfer",
				"display_name": "Dropship Transfer",
				"craft_type": "dropship",
				"texture_path": "res://Assets/kenney_space-kit/Side/craft_speederB.png",
			}
		]
	)
	scene.set(
		"_pending_homebase_team_transfers",
		[
			{
				"transfer_id": "team_1",
				"unit_ids": PackedStringArray(["unit_echo", "unit_foxtrot"]),
				"elapsed_seconds": 6.0,
				"duration_seconds": 14.0,
			}
		]
	)
	scene.set(
		"_pending_homebase_pilot_transfers",
		[
			{
				"transfer_id": "pilot_2",
				"craft_id": "dropship_transfer",
				"pilot_unit_id": "unit_hotel",
				"elapsed_seconds": 4.0,
				"duration_seconds": 10.0,
			}
		]
	)
	scene.call("_refresh_fob_screen")
	fob_screen.call("configure_transfer", selected_unit_ids, selected_fireteam_ids, fireteam_definitions)
	scene.call("_refresh_map_screen")
	scene.call("_show_map")
	await _wait_frames(6)

	var active_mission: Node = scene.call("get_active_mission")
	var mission_host_child: Node = mission_host.get_child(0) if mission_host.get_child_count() > 0 else null
	var tactical_controller := active_mission.get_node("TacticalController") as Node if active_mission != null else null
	var overlay := active_mission.get_node("MetaTransferRouteOverlay") as Node2D if active_mission != null else null
	var route_line := overlay.get_node("RouteLine") as Line2D if overlay != null else null
	var marker_host := overlay.get_node("RouteMarkerHost") as Node2D if overlay != null else null
	var strategic_status := active_mission.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicStatusLabel") as Label if active_mission != null else null
	var marker_types: Array = []
	if marker_host != null:
		for child in marker_host.get_children():
			marker_types.append(String((child as Node).get_meta("entry_type", "")))

	_assert(active_mission != null and mission_host_child == active_mission, "Mission nav starts a live mission while Homebase transfers are active")
	_assert(tactical_controller != null and not bool(tactical_controller.get("preview_mode")), "Homebase transfer route check uses a live mission instance")
	_assert(scene.get("_preview_mission") == null, "Preview mission stays disabled while Homebase transfers are active")
	_assert(overlay == null or not overlay.visible, "Preview-only Homebase transfer route overlay stays hidden in live mission mode")
	_assert(route_line == null or route_line.points.is_empty(), "Live mission mode does not draw the preview transfer route line")
	_assert(marker_host == null or marker_host.get_child_count() == 0, "Live mission mode does not draw preview transfer route markers")
	_assert(marker_types.is_empty(), "Live mission mode keeps preview transfer marker types empty")
	_assert(strategic_status == null or not strategic_status.text.contains("HB->FOB"), "Mission control no longer advertises the preview transfer route in live mission mode")

	scene.queue_free()
	await process_frame


func _wait_frames(frame_count: int) -> void:
	for _frame in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
