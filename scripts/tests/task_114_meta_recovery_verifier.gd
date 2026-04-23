extends SceneTree

const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_114 Meta-Recovery Verifier ===")
	await _test_preview_map_fireteam_cards_show_member_loadouts()
	await _test_preview_map_renders_homebase_transfer_route_overlay()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	print("ALL TESTS PASSED")
	quit()


func _test_preview_map_fireteam_cards_show_member_loadouts() -> void:
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

	var preview_mission: Node = mission_host.get_child(0) if mission_host.get_child_count() > 0 else null
	var mission_setup := preview_mission.get_node("MissionSetup") as Node if preview_mission != null else null
	var member_loadouts: Dictionary = mission_setup.get("member_loadouts") if mission_setup != null and typeof(mission_setup.get("member_loadouts")) == TYPE_DICTIONARY else {}
	var cards_row := preview_mission.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll/FireteamCardsBody/FireteamCardsRow") as HBoxContainer if preview_mission != null else null
	var alpha_card: Control = _find_card_for_unit(cards_row, "unit_alpha")
	var bravo_card: Control = _find_card_for_unit(cards_row, "unit_bravo")
	var alpha_loadout := alpha_card.get_node("Margin/HBox/TextVBox/DataALabel") as Label if alpha_card != null else null
	var bravo_loadout := bravo_card.get_node("Margin/HBox/TextVBox/DataALabel") as Label if bravo_card != null else null

	_assert(preview_mission != null, "Meta map keeps a preview mission instance alive for the route/loadout checks")
	_assert(member_loadouts.has("unit_alpha"), "Preview mission receives the per-member loadout dictionary from the FOB bridge")
	_assert(alpha_card != null and bravo_card != null, "Preview mission renders compact cards for the configured fireteam members")
	_assert(alpha_loadout != null and alpha_loadout.text == "Heavy | Rail | SMG", "Preview mission card mirrors the per-member heavy rail loadout for the lead operator")
	_assert(bravo_loadout != null and bravo_loadout.text == "Light | SMG | SMG", "Preview mission card mirrors the per-member light SMG loadout for a second operator")
	_assert(alpha_card != null and alpha_card.custom_minimum_size.x >= 180.0, "Preview mission widens the compact fireteam cards so the member loadout line stays readable")

	scene.queue_free()
	await process_frame


func _test_preview_map_renders_homebase_transfer_route_overlay() -> void:
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

	var preview_mission: Node = mission_host.get_child(0) if mission_host.get_child_count() > 0 else null
	var overlay := preview_mission.get_node("MetaTransferRouteOverlay") as Node2D if preview_mission != null else null
	var route_line := overlay.get_node("RouteLine") as Line2D if overlay != null else null
	var marker_host := overlay.get_node("RouteMarkerHost") as Node2D if overlay != null else null
	var strategic_status := preview_mission.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicStatusLabel") as Label if preview_mission != null else null
	var marker_types: Array = []
	if marker_host != null:
		for child in marker_host.get_children():
			marker_types.append(String((child as Node).get_meta("entry_type", "")))

	_assert(preview_mission != null, "Meta map preview mission exists while transfer routes are active")
	_assert(overlay != null and overlay.visible, "Preview mission renders the dedicated Homebase-to-FOB transfer overlay")
	_assert(route_line != null and route_line.points.size() == 3, "Transfer overlay exposes a distinct three-point route path on the preview map")
	_assert(marker_host != null and marker_host.get_child_count() == 2, "Transfer overlay renders one moving marker per active Homebase transfer entry")
	_assert(marker_types.has("team") and marker_types.has("pilot"), "Transfer overlay keeps separate markers for team and pilot/craft transfers")
	_assert(strategic_status != null and strategic_status.text.contains("HB->FOB"), "Mission control text calls out the active Homebase transfer route while the preview map is open")

	scene.queue_free()
	await process_frame


func _find_card_for_unit(cards_row: HBoxContainer, unit_id: String) -> Control:
	if cards_row == null:
		return null
	for child in cards_row.get_children():
		if child == null or not child.has_method("get_unit_id"):
			continue
		if String(child.call("get_unit_id")).strip_edges() == unit_id:
			return child as Control
	return null


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
